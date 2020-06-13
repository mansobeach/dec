#!/usr/bin/env ruby

#########################################################################
#
# == Ruby source for #ReadDimInTray class          
#
# == Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component
# 
# $Git: $Id: ReadConfigOutgoing.rb,v 1.6 2008/04/04 14:01:51 decdev Exp $
#
# This class processes dec_outgoing_files.xml config file
#
#########################################################################

require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


module DEC

class ReadConfigOutgoing

   include Singleton
   include REXML
   include CUC::DirUtils
   
   ## -----------------------------------------------------------
  
   ## Class constructor
   def initialize(isDebugMode = false)
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = isDebugMode
      @@handlerXmlFile    = nil   
      checkModuleIntegrity
		defineStructs
      loadData
   end
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadConfigOutgoing debug mode is on"
   end
   ## -----------------------------------------------------------

   ## Re-parse and re-load the structures
   def refresh
      loadData
   end
   ## -----------------------------------------------------------
   
   def getOutgoingDir(mnemonic)
      @@arrOutgoingInterfaces.each{|interface|
         if interface[:mnemonic] == mnemonic then
            return interface[:localOutbox]
         end
      }
      return nil
   end
   ## -----------------------------------------------------------

   def getAllowedDeliveryMethods
      return @@deliveryMethods
   end
   ## -----------------------------------------------------------

   def getDeliveryMethods(entity, filetype)
      @@arrOutgoingFiles.each{|element|
         if element[:fileType] == filetype then
            element[:toList].each{|anEntity|
               if anEntity[:mnemonic] == entity then
                  return anEntity[:deliveryMethods]
               end
            }
         end
      }
      return false
   end
   ## -----------------------------------------------------------

   def getUploadDir(entity)
      @@arrOutgoingInterfaces.each{|interface|
         if interface[:mnemonic] == entity then
            return interface[:uploadDir]
         end
      }
      return nil
   end
   ## -----------------------------------------------------------

   def getUploadTemp(entity)
      @@arrOutgoingInterfaces.each{|interface|
         if interface[:mnemonic] == entity then
            return interface[:uploadTemp]
         end
      }
      return nil
   end
   ## -----------------------------------------------------------

   def getAllOutgoingTypes
      arr = Array.new
      @@arrOutgoingFiles.each{|element|
         arr << element[:fileType]
      }
      return arr
   end
   ## -----------------------------------------------------------

   ## Get an Array of all FileTypes registered in dec_outgoing_files.xml
   def getAllOutgoingFileNames
      return getAllOutgoingTypes
   end
   ## -----------------------------------------------------------

   ##
   def getCompressMethod(entity, filetype)
      @@arrOutgoingFiles.each{|element|
         if element[:fileType] == filetype then
            element[:toList].each{|anEntity|
               if anEntity[:mnemonic] == entity then
                  return anEntity[:compressMethod]
               end
            }
         end
      }
      return false
   end
   ## -------------------------------------------------------------


   ## -------------------------------------------------------------
   
   def getEntitiesSendingIncomingFileType(fileType)
      return getEntitiesSendingIncomingFileName(fileType)
   end
   ## -------------------------------------------------------------
   
   def getEntitiesReceivingOutgoingFile(fileName)
      @@arrOutgoingFiles.each{|item|
         if item[:fileType].include?("*") or item[:fileType].include?("?") then
            if item[:fileType].include?("/") then
               if File.fnmatch(File.basename(item[:fileType]), fileName) == true then
                  return item[:toList]
               end
            end
            if File.fnmatch(item[:fileType], fileName) == true then
               return item[:toList]
            end
         else
            if item[:fileType].downcase == fileName.to_s.downcase then
               return item[:toList]
            end
         end
      }
   end
   ## -------------------------------------------------------------
   
   # It returns an Array of the target directories (the DIMs In-Trays)
   # for the given filetype.  
   def getTargetDirs4Filetype(filetype)
	   arrDirs = Array.new
      arrDims = getDIMs4Filetype(filetype)
      if arrDims == false then
		   if @isDebugMode == true then
			   puts "No target In-Tray(s) for #{filetype} filetype in dec_incoming_files.xml" 
			end
         return arrDirs
      end
      arrDims.each{|dim|
         intray = getDIMInTray(dim)
         if intray == false then
            puts "ERROR in #{@@configFile} file !"
            puts "#{dim} is not declared in the DIM_List"
            puts "Please check your configuration file"
            puts
            exit(99)
         end
         arrDirs << getDIMInTray(dim)
      }
      return arrDirs      
   end
   
   ## -------------------------------------------------------------
   
   ## It returns an Array of the target directories (the DIMs In-Trays)
   ## for the given filename.     
   def getTargetDirs4Filename(filename)
	   arrDirs = Array.new
      arrDims = getDIMs4Filename(filename)
      if arrDims == false then
		   if @isDebugMode == true then
			   puts "No target In-Tray(s) for #{filename} filename in dec_incoming_files.xml" 
			end
         return arrDirs
      end
      arrDims.each{|dim|
         intray = getDIMInTray(dim)
         if intray == false then
            puts "ERROR in #{@@configFile} file !"
            puts "#{dim} is not declared in the DIM_List"
            puts "Please check your configuration file"
            puts
            exit(99)
         end
         arrDirs << getDIMInTray(dim)
      }
      return arrDirs      
   end
   #-------------------------------------------------------------
   
   # It works for both files and filetypes
   def getDIMs(afile)
      return getDIMs4Filename(afile)
   end
   #-------------------------------------------------------------
   
   # It returns an Array of the target DIMs for the given filetype.
   # If the filetype does not exist, it returns false
   def getDIMs4Filetype(afiletype)
     return getFileField(afiletype, "arrIntrays") 
   end    
   #-------------------------------------------------------------

   # This method has been implemented in order to deal with
   # Non Earth Explorer Files
   def getDIMs4Filename(afilename)
      return getFileField(afilename, "arrIntrays")
   end    
   ## -----------------------------------------------------------
	
	# It retrieves all FileTpyes declared in the FileList
	def getAllFileTypes
	   arrFiles = Array.new
	   @@arrFiles2Dims.each{|file|
		   arrFiles << file[:fileType]
		}
		return arrFiles
	end
   #-------------------------------------------------------------

   # It returns true if the given filetype exists, otherwise false
   def existFileType?(afiletype)
      bExist = getFile(afiletype)
      if bExist != false then
         return true
      end
      return false   
   end
   ## -------------------------------------------------------------   
   
   # This method returns true if the given filename/filetype 
   # is disseminated as a hardlink to the DIMs In-Trays.
   # In case the given filetype does not exit it aborts
   def isHardLinked?(afile)
      return getFileField(afile, "hardlink")
   end
   ## -------------------------------------------------------------
   
   # Get a Parameter info for a given filename/filetype.
   # Filenames are recognized by the wildcard * at their end.
   def getFileField(afile, param)
      file = getFile(afile)
      if file == false then
         return false
      end
      return file[param]
   end
   ## -------------------------------------------------------------
   
   # Get the information for a given filename or filetype
   # Filenames are recognized by the wildcard * at their end.
   def getFile(afile)
      @@arrFile2Intrays.each{|file|
         bWildcard = false
         filetype  = file[:fileType]
         
         if filetype.include?("*") == true or filetype.include?("?") == true then
            bWildcard = true
         else
            bWildcard = false
         end
         
         if bWildcard == true then
            # Wildcard "*" can be placed not only at the end of the expresion
            # so all the elements must be included in the filename
            bRecognized = true
            arrWildCard = filetype.split("*")
            arrWildCard.each{|element|

               element = element.tr('\.', '$')
    
               tmp = element.sub!(/([$])/, "\\.")
               while tmp != nil do
   	          element = tmp
                  tmp = tmp.sub!(/([$])/, "\\.")
               end

               element = element.tr('?', '.')

               if afile.match("#{element}") == nil then
                  bRecognized = false
               end
            }   
            if bRecognized == true then
               return file
            end         
         
         else
            if afile == filetype then
               return file
            end
         end
      }
      return false
      puts "Error in ReadConfigIncoming::getFile"
      puts "#{afile} is not registered in dec_incoming_files.xml"
      exit(99)
   end
   #-------------------------------------------------------------
   
   # This method checks the coherency of the config file.
   # - It checks that a DIM Name present in the FileList is defined
   # - as well in the DIM_List
   def checkCoherency
      return
   end
   #-------------------------------------------------------------
   
   def getFileInfo(file, field)
   
      @@arrFile2Intrays.each{|file|
      
         bWildcard = false
         filetype  = file[:fileType]
         
         if filetype[-1] == "*" then
            bWildcard = true
            filetype.delete_at(-1)
         else
            bWildcard = false
         end
         
         if bWildcard == true then
            if filename.include?(filetype) then
               return file[field]
            end         
         else
            if file[:fileType] == filetype then
               puts file
               puts file[field]
               return file[field]
            end
         end
      }
      return false
      puts "Internal Error in DCC_ReadDimInTray::getFileInfo ! :-("
      puts
      exit(99)
  
   end 
   
   ## -------------------------------------------------------------

private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false
   
   @@arrOutgoingFiles  = nil
   @@arrIncomingFiles  = nil
   
   @@dynStruct         = nil
   @@configDirectory   = ""
   
   @@xmlOutFiles       = nil
   @@xmlInFiles        = nil

   @@monitorCfgFiles   = nil
   

   ## -------------------------------------------------------------
   ##
   ## Check that everything needed by the class is present.
   ##
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['DEC_CONFIG'] then
         puts "DEC_CONFIG environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end
           
      if bDefined == true then      
         configDir = nil
         
         if ENV['DEC_CONFIG'] then
            configDir         = %Q{#{ENV['DEC_CONFIG']}}  
         end        
            
         @@configDirectory = configDir
        
         @@configFile = %Q{#{@@configDirectory}/dec_outgoing_files.xml}        
         if !FileTest.exist?(@@configFile) then
            bCheckOK = false
            print("\n\n", @@configFile, " does not exist !  :-(\n\n" )
         end           
      end
         
      if bCheckOK == false then
        puts "ReadConfigIncoming::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   
   ## -------------------------------------------------------------
	##
   ## This method creates all the structs used
	##
   def defineStructs
      @@deliveryMethods = ["ftp", "ftps", "ftpes", "sftp", "email", "mailbody", "http", "https", "local"]
      Struct.new("OutgoingInterface", :mnemonic, :localOutbox, :uploadDir, :uploadTemp)
      Struct.new("OutgoingFile", :fileType, :description, :toList)
      Struct.new("DeliveryInterface", :mnemonic, :compressMethod, :deliveryMethods, :cleanUpAge)      
	end
	## -------------------------------------------------------------

   ## Load the file into the an internal struct.
   ##
   ## The struct is defined in the class Constructor. See #initialize.
   def loadData
      hfileConfig                = File.new(@@configFile)
      xmlFile                    = REXML::Document.new(hfileConfig)
      @@arrOutgoingInterfaces    = Array.new
      @@arrOutgoingFiles         = Array.new
      if @isDebugMode == true then
         puts "\nProcessing #{@@configFile}"
      end
      process(xmlFile)     
   end   
   ## -------------------------------------------------------------
   
   ## Process the xml file decoding all the file
   ## - xmlFile (IN): XML configuration file
   def process(xmlFile)
#      setDebugMode
      dimName              = ""
      dimInTray            = ""
      filetype             = ""
      filename             = ""
      hardlink             = ""
      
      ## ----------------------------------------
      
      path    = "Config/ListInterfaces/Interface"
      
      XPath.each(xmlFile, path){
         |interface|

         if_name        = ""
         if_outbox      = ""
         if_uploadDir   = ""
         if_uploadTmp   = ""
         
         XPath.each(interface, "Name"){
             |name|
             if_name = name.text
         }

         XPath.each(interface, "LocalOutbox"){
             |outbox|
             if_outbox = expandPathValue(outbox.text)
         }

         XPath.each(interface, "UploadDir"){
             |upload|
             if_uploadDir = expandPathValue(upload.text)
         }

         XPath.each(interface, "UploadTemp"){
             |uploadTmp|
             if_uploadTmp = expandPathValue(uploadTmp.text)
         }
                  
         @@arrOutgoingInterfaces << Struct::OutgoingInterface.new(if_name, if_outbox, if_uploadDir, if_uploadTmp)

      }
            
      ## ----------------------------------------

      path    = "Config/ListFiles/File"

      XPath.each(xmlFile, path){
         |file|
         
         description = ""
         filetype    = file.attributes["Type"]
         arrToList = Array.new
            
         XPath.each(file, "Description"){
            |desc|
            description = desc.text
         }
           
         XPath.each(file, "ToList"){
            |list|
            XPath.each(list, "Interface/"){
               |entity|
               
               cleanUpAge = 0
               
               entity.attributes.each_attribute{|attr|
                  if attr.name == "CleanUpAge" then
                     cleanUpAge =  entity.attributes["CleanUpAge"].to_s.to_i
                  end   
               }

               fileType       = file.attributes["Type"]
               mnemonic       = entity.attributes["Name"]
               compressMethod = entity.attributes["Compress"]
               methods        = entity.attributes["DeliveryMethods"]               
               arrDisMethods  = Array.new
               arrDisMethods  = methods.split(";")
               arrTmp         = Array.new
               arrDisMethods.each{|item|
                  arrTmp << item.to_s.downcase
               }

               arrToList << Struct::DeliveryInterface.new(mnemonic, compressMethod, arrTmp, cleanUpAge)            
            }
         }

         @@arrOutgoingFiles << Struct::OutgoingFile.new(filetype, description, arrToList)
      }

     ## ----------------------------------------
      
        
   end
   ## -------------------------------------------------------------
      
   ## I can not understand why there is not a method in REXML that provides
   ## you the Key for a given Attribute
   def getKey(xpath)
      arrPath = xpath.split("@")
      return arrPath[1]
   end
   ## -------------------------------------------------------------

end # class

end # config
