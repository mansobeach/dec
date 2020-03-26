#!/usr/bin/env ruby

#########################################################################
#
# == Ruby source for #ReadConfigIncoming class          
#
# == Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component
# 
# CVS: $Id: ReadConfigIncoming.rb,v 1.6 2008/04/04 14:01:51 decdev Exp $
#
# This class processes dec_incoming_files.xml config file
# which contain the link between a file type and the DIMs that process it.
# Moreover, the DIM In-Tray in which the file will be placed for later processing.
#
#########################################################################

require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


module DEC

class ReadConfigIncoming

   include Singleton
   include REXML
   include CUC::DirUtils
   
   ## -----------------------------------------------------------
  
   # Class constructor
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
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadConfigIncoming debug mode is on"
   end
   ## -----------------------------------------------------------

   ## Re-parse and re-load the structures
   def refresh
      loadData
   end
   ## -----------------------------------------------------------
   
   def getAllIncomingFiles
      arr = Array.new
      @@arrIncomingFiles.each{|incoming|
         arr << incoming[:filetype]
      }
      return arr
   end
   ## -----------------------------------------------------------
   
   def getIncomingDir(mnemonic)
      @@arrIncomingInterfaces.each{|interface|
         if interface[:mnemonic] == mnemonic then
            return interface[:localInbox]
         end
      }
      return nil
   end
   ## -----------------------------------------------------------

   def getDownloadDirs(mnemonic)
      @@arrIncomingInterfaces.each{|interface|
         if interface[:mnemonic] == mnemonic then
            return interface[:arrDownloadDirs]
         end
      }
      return Array.new
   end
   
   ## -------------------------------------------------------------
   
   def getDIMCompress(name)
      puts
      puts "DEPRECATED METHOD: getDIMCompress !"
      puts
      return getInTrayCompress(name)
   end
   ## -------------------------------------------------------------
   
   def getInTrayExecution(name)
      @@arrIntrays.each{|dim|
         if name == dim[:name] then
            return dim[:execute]
         end
      }
      return false
   end 
   ## -------------------------------------------------------------
    
   def getInTrayCompress(name)
      @@arrIntrays.each{|dim|
         if name == dim[:name] then
            return dim[:compress]
         end
      }
      return false
   end
   ## -------------------------------------------------------------
   
   def getDIMInTray(name)
      puts
      puts "DEPRECATED METHOD: getDIMInTray !"
      puts
      return getInTrayDir(name)
   end
   
   ## -------------------------------------------------------------
     
   ## Get the In-Tray directory for a given DIM Name
   ## It returns the InTray Directory if present, otherwise false
   def getInTrayDir(name)
      
      # ------------------------------------------
      # 20170601 
      # Super - dirty patch to support compression
      # Depending on who is invoking this method, parameter can be a String
      # or a Hash which carries whether such DIM name is to be compressed
      
      dimName = ""
      
      if name.class.to_s == "Hash" then
         name.each_key{|key| dimName = key}
      else
         dimName = name
      end
      # ------------------------------------------
      
      @@arrIntrays.each{|dim|
         if dimName == dim[:name] then
            return expandPathValue(dim[:directory])
         end
      }
      return false
   end
   ## -------------------------------------------------------------
   
   # It returns true if the given name exists as a DIM
   def existDim?(name)
      @@arrIntrays.each{|dim|
         if dim[:name] == name then
            return true
         end
      }
      return false
   end
   ## -------------------------------------------------------------

   def getEntitiesSendingIncomingFile(fileType)
      return getEntitiesSendingIncomingFileName(fileType)
   end   
   ## -------------------------------------------------------------
   
   def getEntitiesSendingIncomingFileType(fileType)
      return getEntitiesSendingIncomingFileName(fileType)
   end
   ## -------------------------------------------------------------
   
   def getSourceOfFile(fileName, logger)
      arrEnt = Array.new
      @@arrIncomingFiles.each{|item|
         logger.debug("ReadConfigIncoming::getSourceOfFile(#{item[:filetype]} => #{fileName})")
         if File.fnmatch(item[:filetype], fileName) == true then
            return item[:fromList]
         end
      }   
   end
   ## -------------------------------------------------------------
   
   def getEntitiesSendingIncomingFileName(fileName)
      arrEnt = Array.new
      @@arrIncomingFiles.each{|item|
         if File.fnmatch(item[:filetype], fileName) == true then
            return item[:fromList]
         end
      }
   end
   ## -------------------------------------------------------------
   
   ## It returns an Array of the target directories (the In-Trays)
   ## for the given filetype.  
   def getTargetDirs4Filetype(filetype)
	   arrDirs = Array.new
      arrDims = getInTrays4Filetype(filetype)
      if arrDims == false then
		   if @isDebugMode == true then
			   puts "No target In-Tray(s) for #{filetype} filetype in dec_incoming_files.xml" 
			end
         return arrDirs
      end
      arrDims.each{|dim|
         intray = getInTrayDir(dim)
         if intray == false then
            puts "ERROR in #{@@configFile} file !"
            puts "#{dim} is not declared in the DIM_List"
            puts "Please check your configuration file"
            puts
            exit(99)
         end
         arrDirs << getInTrayDir(dim)
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
         intray = getInTrayDir(dim)
         if intray == false then
            puts "ERROR in #{@@configFile} file !"
            puts "#{dim} is not declared in the DIM_List"
            puts "Please check your configuration file"
            puts
            exit(99)
         end
         arrDirs << getInTrayDir(dim)
      }
      return arrDirs      
   end
   ## -----------------------------------------------------------
   
   ## It works for both files and filetypes
   def getDIMs(afile)
      return getDIMs4Filename(afile)
   end
   ## -----------------------------------------------------------
   def getDIMs4Filetype(afiletype)
      puts
      puts "DEPRECATED METHOD: getDIMs4Filetype !"
      puts
      return getInTrays4Filetype(afiletype)
   end
   ## -----------------------------------------------------------
   
   ## It returns an Array of the target DIMs for the given filetype.
   ## If the filetype does not exist, it returns false
   def getInTrays4Filetype(afiletype)
      return getFileField(afiletype, "arrIntrays") 
   end    
   ## -----------------------------------------------------------

   # This method has been implemented in order to deal with
   # Non Earth Explorer Files
   def getDIMs4Filename(afilename)
      return getFileField(afilename, "arrIntrays")
   end        
   ## -----------------------------------------------------------
      
   ## It retrieves all Intray methods
   def getIntrayNames
      arrDims = Array.new
      @@arrIntrays.each{|dim|
         arrDims << dim[:name]
      }
      return arrDims
   end
	## -----------------------------------------------------------
          
   # It retrieves all DIMs defined in the DIM_List
   def getAllDIMs
      puts
      puts "DEPRECATED METHOD: getAllDIMs !"
      puts
      return getIntrayNames
   end
	## -----------------------------------------------------------
	
	## It retrieves all FileTpyes declared in the ListFiles
	def getAllFileTypes
	   arrFiles = Array.new
	   @@arrFile2Intrays.each{|file|
		   arrFiles << file[:filetype]
		}
		return arrFiles
	end
   ## -----------------------------------------------------------

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
   
   ## Get the information for a given filename or filetype
   ## Filenames are recognized by the wildcard * at their end.
   def getFile(afile)
      @@arrFile2Intrays.each{|file|
         bWildcard = false
         filetype  = file[:filetype]
         
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
   ## -----------------------------------------------------------
   
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
         filetype  = file[:filetype]
         
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
            if file[:filetype] == filetype then
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
   #-------------------------------------------------------------

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
        
         @@configFile = %Q{#{@@configDirectory}/dec_incoming_files.xml}        
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
      Struct.new("IncomingInterface", :mnemonic, :localInbox, :arrDownloadDirs)
      Struct.new("IncomingFile", :filetype, :description, :fromList)
      Struct.new("Intray", :name, :directory, :compress, :execute)
      Struct.new("File2Intrays", :filetype, :hardlink, :arrIntrays)
      Struct.new("DownloadDir", :mnemonic, :directory, :depthSearch)
	end
	## -------------------------------------------------------------

   ## Load the file into the an internal struct.
   ##
   ## The struct is defined in the class Constructor. See #initialize.
   def loadData
      hfileConfig                = File.new(@@configFile)
      xmlFile                    = REXML::Document.new(hfileConfig)
      @@arrIncomingInterfaces    = Array.new
      @@arrIncomingFiles         = Array.new
      @@arrIntrays               = Array.new
      @@arrFile2Intrays          = Array.new
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

         if_name     = ""
         if_inbox    = ""
         

         XPath.each(interface, "Name"){
             |name|
             if_name = name.text
         }

         XPath.each(interface, "LocalInbox"){
             |inbox|
             if_inbox = expandPathValue(inbox.text)
         }

         arrDownloadDirs = Array.new

         XPath.each(interface, "DownloadDirs/Directory"){
             |directory|
             depth = directory.attributes["DepthSearch"].to_i
             dir   = expandPathValue(directory.text)
             arrDownloadDirs << Struct::DownloadDir.new(if_name, dir, depth)
         }
         
         @@arrIncomingInterfaces << Struct::IncomingInterface.new(if_name, if_inbox, arrDownloadDirs)

      }
      ## ----------------------------------------

      path    = "Config/DownloadRules/File"

      XPath.each(xmlFile, path){
         |file|
         
         description = ""
         filetype    = file.attributes["Type"]
         arrFromList = Array.new
            
         XPath.each(file, "Description"){
            |desc|
            description = desc.text
         }
           
         XPath.each(file, "FromList"){
            |list|
            XPath.each(list, "Interface/"){
               |mnemonic|
               arrFromList << mnemonic.text
            }
         }

         @@arrIncomingFiles << Struct::IncomingFile.new(filetype, description, arrFromList)

      }

      ## ----------------------------------------
     
      path    = "Config/DisseminationRules/ListIntrays/Intray"
      
      XPath.each(xmlFile, path){
          |dim|
             
          trayName   = ""   
          directory  = ""
          compress   = ""
          execute    = nil
                       
          XPath.each(dim, "Name"){
             |name|
             trayName = name.text
          }
  
          XPath.each(dim, "Directory"){
             |intray|
             directory = expandPathValue(intray.text)
          }	  

          compress = nil

          XPath.each(dim, "Compress"){
             |kompress|
             compress = kompress.text
          }	  

          XPath.each(dim, "Execute"){
             |exec|
             execute = exec.text
          }	  

            
          @@arrIntrays << Struct::Intray.new(trayName, directory, compress, execute)      
      
      }
 
      ## ----------------------------------------
      
      path    = "Config/DisseminationRules/ListFilesDisseminated/File"
      
      XPath.each(xmlFile, path){
         |file|
         
         filetype    = file.attributes["Type"]
         hardlink    = nil
         arrIntrays  = Array.new
         
         XPath.each(file, "HardLink"){
            |link|
            hardlink = (link.text.downcase == "true")
         }
                   
         XPath.each(file, "ToList"){
            |to|
            XPath.each(to, "Intray"){
               |dim|
               arrIntrays << dim.text
            } 
         }    
	      @@arrFile2Intrays << Struct::File2Intrays.new(filetype, hardlink, arrIntrays)
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
