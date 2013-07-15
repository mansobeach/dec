#!/usr/bin/env ruby

#########################################################################
#
# == Ruby source for #EOLIClient class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component -> EOLI Client Component
# 
# CVS: $Id: EOLIClient.rb,v 1.3 2006/09/29 07:16:01 decdev Exp $
#
# === This class is a Client of the Multi-Mission User Services Catalogue EOLI-SA.
# === It performs some requests of the services offered by EOLI-SA like:
# === - EOLI_CONFIG
# === - LOGIN 
# === - LOGOFF
# === - INVENTORY_SEARCH
# === - INVENTORY_RETRIEVE
# === - INVENTORY_DETAILS
# === - THUMBNAILS_RETRIEVE
# === - BROWSE_RETRIEVE
#
#########################################################################


@@EOLI_MAPPING_CONFIG           = "EOLI_CONFIG"
@@EOLI_MAPPING_LOGIN            = "LOGIN"
@@EOLI_MAPPING_LOGOUT           = "LOGOUT"
@@EOLI_MAPPING_INVENTORY_SEARCH = "INVENTORY_SEARCH"
@@EOLI_MAPPING_INVENTORY_RETRIEVE = "INVENTORY_RETRIEVE"
@@EOLI_MAPPING_DETAILS          = "DETAILS"
@@EOLI_MAPPING_THUMBNAIL        = "THUMBNAIL"
@@EOLI_MAPPING_BROWSE_IMAGE     = "BROWSE_IMAGE"
@@EOLI_MAPPING_GET_EOLI_VERSION = "GET_EOLI_VERSION_INFO"
@@EOLI_MAPPING_LIST_ESA_SETS    = "LIST_ESASETS"
@@EOLI_MAPPING_LOAD_ESA_SET     = "LOAD_ESASET"


require 'ctc/HTTPClient'

require 'eoli/EOLIReadAppConfiguration'
require 'eoli/EOLIReadServiceDirectory'


class EOLIClient

   attr_reader :arrGIPValues, :arrCollections
   #-------------------------------------------------------------
   
   # Class constructor.
   def initialize(debugMode = false)
      checkModuleIntegrity
      @eoliConfig    = EOLIReadAppConfiguration.instance
      @eoliService   = EOLIReadServiceDirectory.instance
      @hostname      = @eoliConfig.getHostName
      @port          = @eoliConfig.getPortNumber.to_i
      @versionNumber = @eoliConfig.getVersionNumber
      @lastUpdate    = @eoliConfig.getLastUpdate
      @arrGIPValues  = @eoliService.getAllGIPValues
      @arrCollections= @eoliService.getAllCollections
      @bSearched     = false
      @msgSearchResponse = ""
      if @lastUpdate.length == 10 then
         @lastUpdate = %Q{#{@lastUpdate}+00:00:00}
      end
      @httpClient    = CTC::HTTPClient.new(@hostname, @port, debugMode)
      if debugMode == true then
         setDebugMode
      end
      @httpHeaderParams   = Hash.new
      @arrColumns         = Array.new
      defineStructs
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      STDERR.puts "EOLIClient debug mode is on"
#      @httpClient.setDebugMode
   end
   #-------------------------------------------------------------
   
   # Login Anonymous.
   # It calls #login method
   def loginAnonymous
      return login("anonymous", "guest")
   end
   #-------------------------------------------------------------
   
   # It logs into the EOLI System
   # IN Parameters:
   # * string user  : the EOLI username 
   # * string pass  : the EOLI user password
   # Login into the EOLI/SA system.
   def login(user, pass)
      data = %Q{Username=#{user}&Password=#{pass}&VersionNumber=#{@versionNumber}}
      return request(@@EOLI_MAPPING_LOGIN, data)
   end
   #-------------------------------------------------------------

   # Get EOLI Configuration. 
   def getEOLIConfig(dateAppConfig, dateServDirectory)
      data = %Q{ServiceDirectory.xml=#{dateAppConfig}&ApplicationConfiguration.xml=#{dateServDirectory}}
      return request(@@EOLI_MAPPING_CONFIG, data)
   end
   #-------------------------------------------------------------

   # It Logs out of EOLI.   
   def logout
      return request(@@EOLI_MAPPING_LOGOUT, "")
   end
   #-------------------------------------------------------------
   
   # Inventory Search Operation
   # IN Parameters:
   # * string CollectionID   : the ID of the Response-Collection Query
   # * string GIPCollection  : label 
   # * string startDate      : the num of elements Found
   # * string stopDate       : the num of groups Found
   # It returns a Struct with all the information if successful or nil.
   # See private method #fillInventorySearchStruct
   def inventorySearch(strCollection1, strGIPCollection, strDateStart, strDateStop)
      data               = ""
      @bSearched         = true
      @msgSearchResponse = ""
      
      if @versionNumber == "3.3" then
         data = %Q{Collection1=#{strCollection1}&GIPCollection1=#{strGIPCollection}&QueryMode=Standard&ITCs=#{strDateStart}&ITCe=#{strDateStop}&IREC=90.0+-180.0+-90.0+180.0}
      end

      if @versionNumber >= "4.0" then
         data = %Q{Collection1=#{strGIPCollection}&QueryMode=Standard&ITCs=#{strDateStart}&ITCe=#{strDateStop}&IREC=90.0+-180.0+-90.0+180.0}
      end
      
      if @isDebugMode == true then
         STDERR.puts "----------------------------------"
         STDERR.puts "EOLIClient::inventorySearch Request"
         STDERR.puts data
	      STDERR.puts "----------------------------------"
      end
      return request(@@EOLI_MAPPING_INVENTORY_SEARCH, data)
   end
   #-------------------------------------------------------------
   
   def getFieldNames
      return @arrColumns
   end
   #-------------------------------------------------------------
   
   # This method must be invoked after the inventorySearch method.
   # It returns true whether there are items to be processed after
   # the inventorySearch operation
   def hasAvailableItems?
      if @bSearched == false then
         STDERR.puts "This method must be invoked after inventorySearch method !\n"
         exit(99)
      end
      @bSearched = false
      
      # First at all check whether the msg contains the number of resulting groups
      # that means that the query has been successfull and the Items have been retrieved too.
      if @msgSearchResponse.to_i > 0 then
         return true
      end
      
      # Check whether there has been a query overflow
      if @msgSearchResponse.include?("Too many hits found") == true then
         return true
      end
      
      # In case the Collection requested exists in MUS EOLI but for the period
      # requested there are no really items
      # "No items found"
      if @msgSearchResponse.include?("No items found")
         return false
      end
      
      
      # If the collection is not available it returns the following message
      # "Request Status: failure"
      if @msgSearchResponse.include?("Request status:failure")
         return false
      end
      
      # If it is not clear ..., MAL ! ;-p
      return false
   end
   #-------------------------------------------------------------
   
   # Inventory Retrieve Operation.
   # It retrieves multiple Groups obtained from a previous 
   # Inventory Search Operation.
   #
   # It supports a request for multiple groups.
   # It seems EOLI 3.3 allows a request with multiple groups.
   #
   # EOLI 4.0 behaviour seems to return only the elements of
   # the first group requested, so multiple requests should be
   # performed with one group each.
   def inventoryRetrMGroups(searchID, arrGroupID, retrieveMode)
      data     = %Q{SEARCH_ID=#{searchID}}
      arrGroupID.each{|x|
         data = %Q{#{data}&GROUP_ID=#{x[:groupID]}}
      }
      data = %Q{#{data}&RETRIEVE_MODE=#{retrieveMode}}
      request(@@EOLI_MAPPING_INVENTORY_RETRIEVE, data, true)
   end
   #-------------------------------------------------------------
   
   # Inventory Retrieve Operation.
   # It retrieves ONLY ONE Group obtained from a previous 
   # Inventory Search Operation.   
   def inventoryRetrGroup(searchID, strGroupID, retrieveMode)
      data     = %Q{SEARCH_ID=#{searchID}}
      data     = %Q{#{data}&GROUP_ID=#{strGroupID}}
      data     = %Q{#{data}&RETRIEVE_MODE=#{retrieveMode}}
      request(@@EOLI_MAPPING_INVENTORY_RETRIEVE, data, true)
   end
   #-------------------------------------------------------------   
   
   # It returns the detailed inventory information for the result
   # of a previous #inventoryRetrieve operation. 
   def details(acqDescritor, collID)
      data     = %Q{ACQUISITIONDESCRIPTOR=#{acqDescritor}&Collection=#{collID}}
      request(@@EOLI_MAPPING_DETAILS, data)
   end
   #-------------------------------------------------------------
   
   # Inventory Thumbnails operation.
   # IN Parameters:
   # * string ACQUISITIONDESCRITOR: the ID of the Element
   # * string COLLECTION  : Collection 
   # * string MISSION  : Mission 
   # * string SENSOR   : Sensor
   # * string PRODUCT  : Product
   # * string Start    : string Start Date in EOLI format
   # * string Stop     : string Stop Date in EOLI format
   # It retrieves if available a Thumbnail for that Element.
   def thumbnail(strAcqDesc, strCollection, strMission, strSensor, strProduct, strDateStart, strDateStop)
      data = %Q{ACQUISITIONDESCRIPTOR=#{strAcqDesc}}
      data = %Q{#{data}&COLLECTION=#{strCollection}}
      data = %Q{#{data}&START=#{strDateStart}}
      data = %Q{#{data}&STOP=#{strDateStop}}
      data = %Q{#{data}&PLATFORM=#{strMission}}
      data = %Q{#{data}&SENSOR=#{strSensor}}
      data = %Q{#{data}&PRODUCT=#{strProduct}}
      return request(@@EOLI_MAPPING_THUMBNAIL, data)
   end
   #-------------------------------------------------------------
   
   # Inventory Thumbnails operation.
   # Compliant with EOLI-SA ICD.041 v 1.4
   # IN Parameters:
   # * string ACQUISITIONDESCRITOR: the ID of the Element
   # * string COLLECTION  : Collection 
   # It retrieves if available a Thumbnail for that Element.
   def thumbnail2(strAcqDesc, strCollection)
      data = %Q{ACQUISITIONDESCRIPTOR=#{strAcqDesc}}
      data = %Q{#{data}&Collection=#{strCollection}}
      @thumbFilename = "thumb_#{strAcqDesc}.jpg"
      return request(@@EOLI_MAPPING_THUMBNAIL, data)
   end
   #------------------------------------------------------------- 

   # Inventory Browse operation.
   # IN Parameters:
   # * string ACQUISITIONDESCRITOR: the ID of the Element
   # * string COLLECTION  : Collection 
   # * string MISSION  : Mission 
   # * string SENSOR   : Sensor
   # * string PRODUCT  : Product
   # * string Start    : string Start Date in EOLI format
   # * string Stop     : string Stop Date in EOLI format
   # It retrieves if available a Browse Product for that Element.
   def browseImage(strAcqDesc, strCollection, strBrowseName, strMission, strSensor, strProduct, strDateStart, strDateStop)
      data = %Q{ACQUISITIONDESCRIPTOR=#{strAcqDesc}}
      data = %Q{#{data}&COLLECTION=#{strCollection}}
      data = %Q{#{data}&BROWSENAME=#{strBrowseName}}
      data = %Q{#{data}&START=#{strDateStart}}
      data = %Q{#{data}&STOP=#{strDateStop}}
      data = %Q{#{data}&PLATFORM=#{strMission}}
      data = %Q{#{data}&SENSOR=#{strSensor}}
      data = %Q{#{data}&PRODUCT=#{strProduct}}
      @browseFilename = %Q{browse_#{strCollection}_#{strAcqDesc}.jpg}
      return request(@@EOLI_MAPPING_BROWSE_IMAGE, data)
   end
   #------------------------------------------------------------

   # Inventory Browse operation.
   # IN Parameters:
   # * string ACQUISITIONDESCRITOR: the ID of the Element
   # * string COLLECTION  : Collection 
   # * string BROWSEName  : Mission 
   # * string SENSOR   : Sensor
   # * string PRODUCT  : Product
   # * string Start    : string Start Date in EOLI format
   # * string Stop     : string Stop Date in EOLI format
   # It retrieves if available a Browse Image for that Element.
   def browseImage2(strAcqDesc, strCollection, strBrowseName="DEFAULT")
      data = %Q{ACQUISITIONDESCRIPTOR=#{strAcqDesc}}
      data = %Q{#{data}&Collection=#{strCollection}}
      data = %Q{#{data}&browseName=#{strBrowseName}}
      @browseFilename = %Q{browse_#{strCollection}_#{strAcqDesc}.jpg}
      return request(@@EOLI_MAPPING_BROWSE_IMAGE, data)
   end
   #------------------------------------------------------------ 
   
   # Inventory Load ESA SET operation.
   # IN Parameters:
   # * string ESA_Set name: the ID of the Element
   # 
   def loadESASet(strESASet)
      data = %Q{ESASetName=#{strESASet}}
      return request(@@EOLI_MAPPING_LOAD_ESA_SET, data)
   end
   #------------------------------------------------------------ 

   
   #
   def listESASets
      return request(@@EOLI_MAPPING_LIST_ESA_SETS, "")
   end
   #------------------------------------------------------------  
   
   # Inventory GET_USER_ORDERS
   def getUserOrders
   end
   #------------------------------------------------------------
   
   # Inventory GET_EOLI_VERSION_INFO
   def getEoliVersion
      return request(@@EOLI_MAPPING_GET_EOLI_VERSION, "")
   end
   #------------------------------------------------------------
     
   # Get Last Response Msg
   # It returns the last Msg returned from an EOLI request.
   def getResponseMsg
      return @response
   end
   #-------------------------------------------------------------
   
   

private

   @hostname = ""
   @version  = ""

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bCheckOK = true
      if !ENV['EOLI_CLIENT_CONFIG'] then
         STDERR.puts "EOLI_CLIENT_CONFIG environment variable not defined !  :-(\n"
         bCheckOK = false
      end

      if bCheckOK == false then
         STDERR.puts "EOLIClient::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
      @configDir = ENV['EOLI_CLIENT_CONFIG']
         
   end
   #-------------------------------------------------------------

   def defineStructs
      Struct.new("GROUP_Struct", :groupID, :numElements, :label)
      Struct.new("INV_SEARCH_Struct", :collectionID, :label, :numElements, :numGroups, :arrGroups)
   end
   #-------------------------------------------------------------
   
   # It requests an EOLI declared operation.
   # IN Parameters:
   # * string operation : operation.
   # * string data      : data required as argument of the operation.
   # It returns a struct associated to the request.
   def request(operation, data, addToPath=false)
      httpMethod     = "GET" #@eoliConfig.getHTTPMethod(operation)
      path           = @eoliConfig.getServletAddress(operation)
      if httpMethod.upcase == "GET" or addToPath == true then
         path = %Q{#{path}?#{data}}
	      data = nil
      end
          
      response = @httpClient.send_request(httpMethod, path, data, @httpHeaderParams)

      structResponse = processResponse(operation, response)
            
      if structResponse == nil then
         exit(99)
      else
         return structResponse
      end
      
      return structResponse
      
   end
   #-------------------------------------------------------------

   # Process the EOLI Response
   def processResponse(request, response)
      case request
         when @@EOLI_MAPPING_LOGIN              then return processLoginResponse(response)
         when @@EOLI_MAPPING_LOGOUT             then return processLogoutResponse(response)
         when @@EOLI_MAPPING_CONFIG             then return processConfigResponse(response)
         when @@EOLI_MAPPING_INVENTORY_SEARCH   then return processSearchResponse(response)
	      when @@EOLI_MAPPING_INVENTORY_RETRIEVE then return processRetrieveResponse(response)
         when @@EOLI_MAPPING_DETAILS            then return processDetailsResponse(response)
	      when @@EOLI_MAPPING_THUMBNAIL          then return processThumbnailResponse(response)
	      when @@EOLI_MAPPING_BROWSE_IMAGE       then return processBrowseImageResponse(response)
         when @@EOLI_MAPPING_GET_EOLI_VERSION   then return processGetEoliInfoResponse(response)
         when @@EOLI_MAPPING_LIST_ESA_SETS      then return processListESASets(response)
         when @@EOLI_MAPPING_LOAD_ESA_SET       then return processLoadESASet(response)
      end
   end
   #-------------------------------------------------------------

   # Process the Response to the Login Request
   def processLoginResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_LOGIN)
      arrResponse    = response.body.split("\n")
      @response      = arrResponse[1]
      if arrResponse[0] != successMessage then
	      if @isDebugMode == false then
	         STDERR.puts response
	      end
	      return false
      end
      @sessionID = arrResponse[2]
      if @isDebugMode == true then
         STDERR.puts arrResponse
	      STDERR.puts "SessionID -> #{@sessionID}"
      end
      @httpHeaderParams["Cookie"] = "JSESSIONID=#{@sessionID}"
      return true
   end  
   #-------------------------------------------------------------

   # Process the Response to the Logoff Request.
   def processLogoutResponse(response)
      arrResponse    = response.body.split("\n")
      @response      = arrResponse[0]
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_LOGOUT)
      if arrResponse[0] != successMessage then
	      if @isDebugMode == false then
	         STDERR.puts response
         end
	      return false
      end
      return true
   end  
   #-------------------------------------------------------------
   
   # process the response of the LIST_ESA_SETS
   def processListESASets(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_LIST_ESA_SETS)
      arrResponse    = response.body.split("\n")
      @response      = arrResponse[1]
      if arrResponse[0] != successMessage then
	      if @isDebugMode == false then
	         STDERR.puts response
         end
	      return false
      end
      return true
   end
   #-------------------------------------------------------------

   # process the response of the LOAD_ESA_SET
   def processLoadESASet(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_LOAD_ESA_SET)
      arrResponse    = response.body.split("\n")
      @response      = ""
      bFirst         = true
      arrResponse.each{|line|
         if bFirst == true then
            bFirst = false
            next
         end
         @response   = %Q{#{@response}#{line}\n}
      }
      if arrResponse[0] != successMessage then
	      if @isDebugMode == false then
	         STDERR.puts response
         end
	      return false
      end
      return true
   end
   #-------------------------------------------------------------
   
   # Process the Response to the Search Request
   def processSearchResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_INVENTORY_SEARCH)
      arrResponse    = response.body.split("\n")
      @response      = arrResponse[0]
      if response.body.include?("No items found") == true then
         @response = "No items found"
      end
      if arrResponse[0].split(" ")[0] != successMessage then
         STDERR.puts "Search Request Failed !"
	      if @isDebugMode == true then
            STDERR.puts
            STDERR.puts "---------------------"
            STDERR.puts arrResponse
            STDERR.puts "---------------------"
	      end
	      return false
      end
      if @isDebugMode == true then
         STDERR.puts
         STDERR.puts "---------------------"
         STDERR.puts arrResponse
         STDERR.puts "---------------------"
      end
      
      # Process the successful Query Response
      return processResponseSearch(arrResponse[1])
   end
   #-------------------------------------------------------------
   
   # Process the Response to the Details Request
   def processDetailsResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_INVENTORY_SEARCH)
      arrResponse    = response.body.split("\n")
      if arrResponse == nil then
         return false
      end
      if arrResponse[0] == nil then
         return false
      end
      if arrResponse[0].split(" ")[0] != successMessage then
	      if @isDebugMode == true then
	         STDERR.puts "Retrieve Details Failed !"
            STDERR.puts arrResponse
	      end
	      return false
      end
      
      # Success message
      arrResponse.shift
      # Title message
      arrResponse.shift
      # Subtitle message
      arrResponse.shift
      
      hField    = Hash.new
      
      arrResponse.each{|line|
         arrFields = line.split("|")
         # this is the hierarchy level
         # arrFields[0]
         hField[arrFields[1].upcase] = arrFields[2]
      }
      
      if @isDebugMode == true then
         STDERR.puts "Details Data received:"
         hField.each{|key, value|
            STDERR.print key, " -> ", value, "\n"
         }
      end
      return hField
   end
   #-------------------------------------------------------------
   
   # Process the Response to the Search Request.
   # IN Parameters:
   # * HTTPResponse response : the response object of the HTTP Request to EOLI
   # It returns an Array of Hash objects with a key per column assigned to its value.
   # hashObject[:column1] = "value1" ; hashObject[:column2] = "value2" and so on.
   # All values are returned as a string object.
   def processRetrieveResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_INVENTORY_RETRIEVE)
      arrResponse    = response.body.split("\n")
      @response      = arrResponse[0]
      if arrResponse[0].split(" ")[0] != successMessage then
         STDERR.puts "Retrieve Request Failed !"
	      STDERR.puts arrResponse
	      if @isDebugMode == true then
	         STDERR.puts arrResponse
	      end
	      return false
      end
      
      if @isDebugMode == true then
         STDERR.puts arrResponse[0]
      end
      
      arrResp     = Array.new
      @arrColumns = arrResponse[1].split("|")
      nEls        = arrResponse.length - 1  
      i           = 2
      
      while i <= nEls
         arrValues  = arrResponse[i].split("|")
	      j = 0
	      hashResp = Hash.new
	      @arrColumns.each{|col|
	         hashResp[col.upcase] = arrValues[j]
	         j = j + 1
         }
	      arrResp << hashResp
	      i = i + 1
      end
      return arrResp
   end   
   #-------------------------------------------------------------
   
   def processGetEoliInfoResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_GET_EOLI_VERSION)
      arrResponse    = response.body.split("\n")
      if arrResponse[0].split(" ")[0] != successMessage then
	      if @isDebugMode == true then
	         STDERR.puts "Get EOLI Info failed !"
            STDERR.puts arrResponse
	      end
	      return false
      end      
      return true
   end
   #-------------------------------------------------------------
   
   def processBrowseImageResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_BROWSE_IMAGE)
      
      if response.body.length == 0 then
         return false
      end
      
      aFile = nil     
      begin
         aFile = File.new(@browseFilename, File::CREAT|File::WRONLY)
      rescue Exception
         STDERR.puts
         STDERR.puts "Fatal Error in EOLIClient::processBrowseImageResponse"
         STDERR.puts "Could not create file #{@browseFilename} in #{Dir.pwd}"
         exit(99)
      end
      
      aFile.binmode
      aFile.print response.body
      aFile.flush
      aFile.close
      return true
   end
   #-------------------------------------------------------------
   
   def processThumbnailResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_THUMBNAIL)
      
      if response.body.length == 0 then
         return false
      end
      
      aFile = nil     
      begin
         aFile = File.new(@thumbFilename, File::CREAT|File::WRONLY)
      rescue Exception
         STDERR.puts
         STDERR.puts "Fatal Error in EOLIClient::processThumbnailResponse"
         STDERR.puts "Could not create thumbnail file in #{Dir.pwd}"
         exit(99)
      end
      
      aFile.binmode
      aFile.print response.body
      aFile.flush
      aFile.close
      return true
   end
   #------------------------------------------------------------- 
      
   # Process the Response to the Config Request.
   # Lastest available ICD 1.5 - draft tells three possible
   # responses:
   # * a bytestream with the configuration.
   # * string msg "All configuration files up to date".
   # * empty string in case of error.
   def processConfigResponse(response)
      successMessage = @eoliConfig.getSuccessMessage(@@EOLI_MAPPING_CONFIG)
      
      # At this point we have received the byte stream with the EOLI
      # File configurations in a zip.
      aFile = nil     
      begin
         aFile = File.new("#{@configDir}/EoliConfig.zip", File::CREAT|File::WRONLY)
      rescue Exception
         STDERR.puts
         STDERR.puts "Fatal Error in EOLIClient::processConfigResponse"
         STDERR.puts "Could not create file EoliConfig.zip in #{@configDir}"
         exit(99)
      end
      
      aFile.binmode
      aFile.print response.body
      aFile.flush
      aFile.close     
      
      return true
   end
   #-------------------------------------------------------------   
   
   # This Method processes the response of a successful search request.
   # NumOfResults | ResultSetID | CollResultGroup
   # CollResultGroup ::= CollLabel Sep NGroups Sep Group
   # Group ::= (GroupID Sep GroupLabel Sep NItems)+
   def processResponseSearch(strData)
      
      lastResponseINV_SEARCH = nil
      arrResponse  = strData.split("|")
      numElements  = arrResponse[0].to_i
      collectionID = arrResponse[1]
      groupLabel   = arrResponse[2]
      nGroups      = arrResponse[3].to_i
      
      if @isDebugMode == true then
         STDERR.puts "--------------------"
         STDERR.puts "#{numElements} element(s) found"
	      STDERR.puts collectionID
	      STDERR.puts "#{nGroups} groups - #{groupLabel}"
	      STDERR.puts "--------------------"
	      STDERR.puts
      end
            
      @msgSearchResponse = arrResponse[3]
      
      nEls = arrResponse.length - 1
      i    = 4 
      
      arrGroups = Array.new
      
      while i < nEls
         groupID    = arrResponse[i]
	      groupLabel = arrResponse[i+1]
	      nItems     = arrResponse[i+2].to_i
	      arrGroups << fillGroupStruct(groupID, nItems, groupLabel)
	      i = i + 3
	 
# 	 if @isDebugMode == true then
# 	    puts "++++++++"
# 	    puts groupID
# 	    puts groupLabel
# 	    puts nItems
# 	    puts "++++++++"
# 	 end      
      end
      
      @lastResponseINV_SEARCH = fillInventorySearchStruct(collectionID, groupLabel, numElements, nGroups, arrGroups)
      return @lastResponseINV_SEARCH
  end
   #-------------------------------------------------------------   
   
   # Fill the INV_SEARCH_Struct response Struct
   # IN Parameters:
   # * string CollectionID : the ID of the Response-Collection Query
   # * string label        : label 
   # * integer numElements : the num of elements Found
   # * integer numGroups   : the num of groups Found
   # * array of Groups     : array of the Group's struct. See #fillGroupStruct method.
   # It returns a struct INV_SEARCH_Struct
   def fillInventorySearchStruct(collectionID, label, numElements, numGroups, arrGroups)                      
      invSearchStruct = Struct::INV_SEARCH_Struct.new(
                         collectionID,
			                label,
                         numElements,
                         numGroups,
                         arrGroups
			                )
      return invSearchStruct
   end
   #-------------------------------------------------------------
   
   # Fill the GROUP Struct
   # IN Parameters:
   # * string groupID      : the group ID of the INVENTORY_SEARCH Query 
   # * integer numElements : the num of elements of the GROUP
   # * string label        : label of the group ID
   # It returns a struct GROUP_Struct.
   def fillGroupStruct(groupID, groupNumElements, groupLabel)
      groupStruct = Struct::GROUP_Struct.new(
                                             groupID,
                                             groupNumElements,
                                             groupLabel)
      return groupStruct   
   end
   #-------------------------------------------------------------
   
end
