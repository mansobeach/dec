#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #EOLIReadAppConfiguration class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component -> EOLI Client Component
#  
# CVS: $Id: EOLIReadAppConfiguration.rb,v 1.3 2006/09/29 07:16:01 decdev Exp $
#
# This class decodes the ApplicationConfiguration.xml
# configuration file.
#
#########################################################################


require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


class EOLIReadAppConfiguration

   include Singleton
   include REXML
   include CUC::DirUtils
   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      checkModuleIntegrity
      defineStructs
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      STDERR.puts "EOLIReadAppConfiguration debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Get EOLI Hostname
   def getHostName
      return @hostName
   end
   #-------------------------------------------------------------

   # Get EOLI Port for HTTP Transactions
   def getPortNumber
      return @portNumber
   end
   #-------------------------------------------------------------
   
   # Get Version of EOLI
   def getVersionNumber
      return @versionNumber
   end
   #-------------------------------------------------------------
   
   # Get Date of EOLI Release
   def getLastUpdate
      return @lastUpdated
   end
   #-------------------------------------------------------------  
   
   # Get Servlet Address by Service
   def getServletAddress(serviceName)
      ret = searchService(serviceName) 
      if ret == false then
         return false
      end
      return ret[:servletAddress]
   end   
   #-------------------------------------------------------------  

   # Get SuccessMessage for a Service
   def getSuccessMessage(serviceName)
      ret = searchService(serviceName) 
      if ret == false then
         return false
      end
      return ret[:successMessage]
   end
   #-------------------------------------------------------------   
   
   # Get HTTP Method for the requests to a service
   def getHTTPMethod(serviceName)
      ret = searchService(serviceName) 
      if ret == false then
         return false
      end
      return ret[:httpMethod] 
   end   
   #-------------------------------------------------------------
   
   # Retrieve the complete Service Info
   def getServiceInfo(serviceName)
      return searchService(serviceName)
   end
   #-------------------------------------------------------------
   
   # Use this method when the file has been changed
   def reload
      loadData
   end
   #-------------------------------------------------------------
   
private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   @@configDirectory   = ""
   @@configFile        = ""  
   @@monitorCfgFiles   = nil
   @@arrExtEntities    = nil

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['EOLI_CLIENT_CONFIG'] then
         STDERR.puts "EOLI_CLIENT_CONFIG environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end
           
      if bDefined == true then      
         configDir         = %Q{#{ENV['EOLI_CLIENT_CONFIG']}}        
         @@configDirectory = configDir
        
         @@configFile = %Q{#{@@configDirectory}/ApplicationConfiguration.xml}        
         if !FileTest.exist?(@@configFile) then
            bCheckOK = false
            print("\n\n", @@configFile, " does not exist !  :-(\n\n" )
         end           
      end
         
      if bCheckOK == false then
        STDERR.puts "EOLIReadAppConfiguration::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
   
   # In this method all the structs required are defined
   def defineStructs
      Struct.new("ServletServiceStruct", :servletMapping, :servletAddress,
                       :httpMethod, :successMessage)
   end
   #-------------------------------------------------------------
   
   # Load the file into the an internal struct.
   #
   # The struct is defined in the class Constructor. See #initialize.
   def loadData
      externalFilename = @@configFile
      fileExternal     = File.new(externalFilename)
      xmlFile          = REXML::Document.new(fileExternal)

      @@arrServletsServices = Array.new
     
      if @isDebugMode == true then
         STDERR.puts "\nProcessing #{@@configFile}"
      end
      process(xmlFile)     
   end   
   #-------------------------------------------------------------
   
   # Process the xml file decoding all the file
   # - xmlFile (IN): XML configuration file
   def process(xmlFile)
#      setDebugMode
      @lastUpdated         = ""
      @versionNumber       = ""
      @hostName            = ""
      @portNumber          = ""
      servletMapping       = ""
      servletAddress       = ""
      httpMethod           = ""
      successMessage       = ""
 
      # LastUpdated
      path    = "/ApplicationConfiguration/LastUpdated"
      config  = XPath.each(xmlFile, path){
          |date|
	      @lastUpdated = date.text
      }
      
      # VersionNumber
      path    = "/ApplicationConfiguration/VersionNumber"
      config  = XPath.each(xmlFile, path){
          |version|
	      @versionNumber = version.text
      }   	        
      
      # HostName
      path    = "/ApplicationConfiguration/HostName"
      config  = XPath.each(xmlFile, path){
          |host|
	      @hostName = host.text
      }   	      
      
      
      # PortNumber
      path    = "/ApplicationConfiguration/PortNumber"
      config  = XPath.each(xmlFile, path){
          |port|
	       @portNumber= port.text
      }   
      
      if @isDebugMode == true then
         STDERR.puts "================================="
         STDERR.puts "Last Updated   = #{@lastUpdated}"
         STDERR.puts "Version Number = #{@versionNumber}"
         STDERR.puts "Hostname       = #{@hostName}"
         STDERR.puts "PortNumber     = #{@portNumber}"
	      STDERR.puts "================================="
      end
     
      # Servlets
      path    = "ApplicationConfiguration/servlet"
      serv = XPath.each(xmlFile, path){
          |servlet|
          XPath.each(servlet, "ServletMapping"){
             |mapping|
             servletMapping = mapping.text
          }
  
          XPath.each(servlet,"ServletAddress"){
             |address|
             servletAddress = address.text
          }
	  
          XPath.each(servlet,"HTTPMethod"){
             |http|
	          httpMethod = http.text
          }
	  
	       XPath.each(servlet,"SuccessMessage"){
             |succ|
             successMessage = succ.text
          }
	  
	       @@arrServletsServices << fillServletServiceStruct(servletMapping, servletAddress, httpMethod, successMessage)
      }
  
   end
   #-------------------------------------------------------------   
   

   #-------------------------------------------------------------

   # Fill an External entity struct
   # - mapping (IN):  servlet mapping
   # - address (IN):  servlet address
   # - method  (IN):  HTTP method
   # - success (IN):  success message
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillServletServiceStruct(mapping, address, method, success)
   
#       if @isDebugMode == true then
#          STDERR.puts "-----------------------"
#          STDERR.puts mapping
#          STDERR.puts address
#          STDERR.puts method
#          STDERR.puts success
# 	        STDERR.puts "-----------------------"
#       end
   
                      
      tmpStruct = Struct::ServletServiceStruct.new(mapping,
                                  address,
                                  method,
		                            success)
   		
      return tmpStruct         
   end
   #-------------------------------------------------------------
   

   #-------------------------------------------------------------
   
   # Search in the array of Servlets Services one service by its name
   def searchService(serviceName)
   
      @@arrServletsServices.each{|x|
         if x[:servletMapping] == serviceName then
	         return x
	      end
      }
      return false
   end
   #-------------------------------------------------------------
   
 
   
end
