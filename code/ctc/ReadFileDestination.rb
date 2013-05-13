#!/usr/bin/env ruby

#########################################################################
#
# ===Ruby source for #ReadFileDestination class          
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: ReadFileDestination.rb,v 1.17 2007/07/24 17:21:50 decdev Exp $
#
# This class processes ft_incoming_files.xml and ft_outgoing_files.xml.
# which contain all the information about the destination and address
# of all files registered in the DCC.
#
#########################################################################

require 'singleton'
require 'rexml/document'

module CTC

class ReadFileDestination

   include Singleton
   include REXML
   include CTC

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      @@handlerXmlFile    = nil          
      checkModuleIntegrity
      defineStructs
      @@deliveryMethods = ["ftp", "email", "mailbody"]
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadFileDestination debug mode is on"
   end
   #-------------------------------------------------------------
   
   # Reload data from files
   #
   # This is the method called when the config files are modified
   def update
      if @isDebugMode then 
         print("\nReceived Notification that the config files have changed\n")
      end   
      loadData
   end
   #-------------------------------------------------------------
   
   def getAllowedDeliveryMethods
      return @@deliveryMethods
   end
   #-------------------------------------------------------------

   # Get all files that are sent by an Internal Entity, i.e. DCC
   # - mnemonic (IN): Entity name
   def getFromListOutgoingFiles(mnemonic)
      if @isDebugMode then 
         print("\nGet Outgoing files FROM  ", mnemonic, " facility \n")
      end   
      return getFiles(@@FT_OUTGOING, @@FT_FROM, mnemonic)
   end
   #-------------------------------------------------------------
   
   # Get all files that are received by an External Entity, i.e. PDS
   # - mnemonic (IN): Entity name
   def getToListOutgoingFiles(mnemonic)
      if @isDebugMode then 
         print("\nGet Outgoing files To ", mnemonic, " facility \n")
      end            
      return getFiles(@@FT_OUTGOING, @@FT_TO, mnemonic)
   end   
   #-------------------------------------------------------------
   
   # Get all files that are received by an Internal Entity, i.e. DCC
   # - mnemonic (IN): Entity name
   def getToListIncomingFiles(mnemonic)
      if @isDebugMode then 
         print("\nGet Incoming files TO  ", mnemonic, " facility \n")
      end   
      return getFiles(@@FT_INCOMING, @@FT_TO, mnemonic)
   end   
   #-------------------------------------------------------------
   
   # Get all files that are sent by an External Entity, i.e. PDS
   # - mnemonic (IN): Entity name
   def getFromListIncomingFiles(mnemonic)
      if @isDebugMode then 
         print("\nGet Incoming files FROM  ", mnemonic, " facility \n")
      end   
      return getFiles(@@FT_INCOMING, @@FT_FROM, mnemonic)
   end 
   #-------------------------------------------------------------
   
   # Get all Entities (internal and external Entities) Receiving
   # an outgoing file of a given FileType
   # - filetype (IN): File type
   def getEntitiesReceivingOutgoingFile(filetype)
      if @isDebugMode then 
         print("\nGet External Entities which Receive the ", filetype, " file type \n")
      end
      return getMnemonics(@@FT_OUTGOING, @@FT_TO, filetype)
   end
   #-------------------------------------------------------------   
   
   # Get all Internal Entities Receiving
   # an incoming file of a given FileType
   # - filetype (IN): File type
   def getEntitiesReceivingIncomingFile(filetype)
      if @isDebugMode then 
         print("\nGet Internal Entities which Receive the ", filetype, " file type \n")
      end   
      return getMnemonics(@@FT_INCOMING, @@FT_TO, filetype)
   end
   #-------------------------------------------------------------
   
   #
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
   #-------------------------------------------------------------

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
   #-------------------------------------------------------------

   def getCleanUpAge(entity, filetype)
      @@arrOutgoingFiles.each{|element|
         if element[:fileType] == filetype then
            element[:toList].each{|anEntity|
               if anEntity[:mnemonic] == entity then
                  return anEntity[:cleanUpAge]
               end
            }
         end
      }
      return 0
   end
   #-------------------------------------------------------------

   #
   def isCompressed?(entity, filetype)   
      @@arrOutgoingFiles.each{|element|
         if element[:fileType] == filetype then
            element[:toList].each{|anEntity|
               if anEntity[:mnemonic] == entity then
                  return true
               end
            }
         end
      }
      return false
   end
   #-------------------------------------------------------------
   
   # Get all Interfaces which have available 
   # an incoming file of a given FileType
   # - filetype (IN): File type
   def getEntitiesSendingIncomingFile(filetype)
      if @isDebugMode then 
         print("\nGet Interfaces which have available files of ", filetype, " file type \n")
      end
      if filetype.include?("*") == true or filetype.include?("?") == true then
         return getMnemonics(@@FT_INCOMING, @@FT_FROM, filetype, false)
      else
         return getMnemonics(@@FT_INCOMING, @@FT_FROM, filetype)
      end
   end
   #-------------------------------------------------------------

   # Get all Interfaces which have available 
   # an incoming file of a given FileType
   # - filetype (IN): File type
   def getEntitiesSendingIncomingFileType(filetype)
      if @isDebugMode then 
         print("\nGet Interfaces which have available files of ", filetype, " file type \n")
      end   
      return getMnemonics(@@FT_INCOMING, @@FT_FROM, filetype)
   end
   #-------------------------------------------------------------

   # Get all External Entities which Send 
   # an incoming file of a given FileType
   # - filetype (IN): File type
   def getEntitiesSendingIncomingFileName(filename)
      if @isDebugMode then 
         print("\nGet Interfaces which have available files with name ", filename, "  \n")
      end   
      return getMnemonics(@@FT_INCOMING, @@FT_FROM, filename, false)
   end
   #-------------------------------------------------------------

   
   # Get All Internal Entities which Send
   # an outgoing file of a given FileType    
   # - filetype (IN): File type
   def getEntitiesSendingOutgoingFile(filetype)
      if @isDebugMode then 
         print("\nGet Internal Entities which Send the ", filetype, " file type \n")
      end   
      return getMnemonics(@@FT_OUTGOING, @@FT_FROM, filetype)
   end
   #-------------------------------------------------------------

   # Get All Internal Entities which Send
   # an outgoing file of a given FileType    
   # - filetype (IN): File type
   def getEntitiesSendingOutgoingFile(filetype)
      if @isDebugMode then 
         print("\nGet Internal Entities which Send the ", filetype, " file type \n")
      end   
      return getMnemonics(@@FT_OUTGOING, @@FT_FROM, filetype)
   end
   #-------------------------------------------------------------
   
   # Get an Array of all FileTypes registered in ft_outgoing_files.xml
   def getAllOutgoingTypes
      return getFiles(@@FT_OUTGOING, @@FT_TO, nil)
   end
   #-------------------------------------------------------------
   
   # DEPRECATED, please use getAllOutgoingTypes
   # Get an Array of all FileTypes registered in ft_outgoing_files.xml
   def getAllOutgoingFiles
      return getAllOutgoingTypes
   end
   #-------------------------------------------------------------
   
   # Get an Array of all FileTypes registered in ft_incoming_files.xml
   def getAllIncomingFiles
      return getFiles(@@FT_INCOMING, @@FT_FROM, nil)
   end
   #-------------------------------------------------------------

   # Get an Array of all FileTypes registered in ft_incoming_files.xml
   def getAllIncomingFileNames
      return getFiles(@@FT_INCOMING, @@FT_FROM, nil, false)
   end
   #-------------------------------------------------------------

   
#    def getCompressMethod(filetype)
#       @@arrOutgoingFiles.each{|x|
#          if x[:fileType] == filetype then
#             return x[:compressMethod].to_s
#          end
#       }
#       puts "\nDCC_ReadFileDestination::getCompressMethod INTERNAL Error"
#    end
#    #-------------------------------------------------------------   
   
   def getDescription(filetype)
      @@arrIncomingFiles.each{|x|
         if x[:fileType] == filetype then
            return x[:description].to_s
         end
      }
      puts "\nDCC_ReadFileDestination::getDescription INTERNAL Error"   
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
   
   # Class constants
   @@FT_INCOMING = 1
   @@FT_OUTGOING = 2
   @@FT_FROM     = 1
   @@FT_TO       = 2

   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['DCC_CONFIG'] then
        puts "\nDCC_CONFIG environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end
      
      if bDefined == true
      then      
        configDir         = %Q{#{ENV['DCC_CONFIG']}}        
        @@configDirectory = configDir
                        
        configFile = %Q{#{configDir}/ft_incoming_files.xml}        
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end        

        configFile = %Q{#{configDir}/ft_outgoing_files.xml}        
        if !FileTest.exist?(configFile) then
           bCheckOK = false
           print("\n\n", configFile, " does not exist !  :-(\n\n" )
        end
        
      end
      if bCheckOK == false then
        puts "DCC_ReadFileDestination::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
   
   def defineStructs
      Struct.new("OutgoingFile", :fileType, :description, :toList)
#      Struct.new("IncomingFilename", :fileName, :description, :fromList, :toList)
      @@dynStructIn  = Struct.new("StrctIncomingFile", :fileType, :description, :fromList, :toList)
      Struct.new("DeliveryInterface", :mnemonic, :compressMethod, :deliveryMethods, :cleanUpAge)
   end
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
      outgoingFilename = %Q{#{@@configDirectory}/ft_outgoing_files.xml}
      incomingFilename = %Q{#{@@configDirectory}/ft_incoming_files.xml}
      fileOutgoing     = File.new(outgoingFilename)
      fileIncoming     = File.new(incomingFilename)
      xmlOutgoing      = REXML::Document.new(fileOutgoing)
      xmlIncoming      = REXML::Document.new(fileIncoming)
      @@arrOutgoingFiles      = Array.new
      @@arrIncomingFiles      = Array.new
      @@arrIncomingFilenames  = Array.new
      if @isDebugMode == true then
         puts "\nProcessing Outgoing Files"
      end
      processOutFileTypeLists(xmlOutgoing, @@arrOutgoingFiles, true)
      if @isDebugMode == true then
         puts("\nProcessing Incoming Files")
      end     
#      processFileTypeLists(xmlIncoming, @@arrIncomingFiles, false)
   end   
   #-------------------------------------------------------------
   
   # Process File
   # - xmlFile (IN): XML file
   # - arrFile (OUT): 
   def processOutFileTypeLists(xmlFile, arrFiles, outgoing)
      fileType       = ""
      description    = ""
      newFile        = nil
      compressMethod = nil
      arrFromList    = Array.new
      arrToList      = Array.new
      arrDisMethods  = Array.new
      
      XPath.each(xmlFile, "FileList/File"){      
         |file|                  

         XPath.each(file, "Description"){
            |desc|
            description = desc.text
         }
               
         XPath.each(file, "ToList"){
            |list|
            arrToList = Array.new
               
            XPath.each(list, "Interface/"){
               |entity|

               bFound = false

               file.attributes.each_attribute{|attr|
                  if attr.name == "Type" then
                     bFound = true
                  end   
               }

               if bFound == false then
                  puts
                  puts file
                  puts
                  puts "Attribute Type for Element File has not been found in ft_outgoing_file.xml"
                  puts
                  puts "Majo, me temo que fatal error ! :-p"
                  puts
                  exit(99)
               end

               bFound = false

               entity.attributes.each_attribute{|attr|
                  if attr.name == "Name" then
                     bFound = true
                  end   
               }

               if bFound == false then
                  puts
                  puts file
                  puts
                  puts "Attribute Name for Element Interface has not been found in ft_outgoing_file.xml"
                  puts
                  puts "Majo, me temo que fatal error ! :-p"
                  puts
                  exit(99)
               end


               bFound = false

               entity.attributes.each_attribute{|attr|
                  if attr.name == "Compress" then
                     bFound = true
                  end   
               }

               if bFound == false then
                  puts
                  puts file
                  puts
                  puts "Attribute Compress for Element Interface has not been found in ft_outgoing_file.xml"
                  puts
                  puts "Majo, me temo que fatal error ! :-p"
                  puts
                  exit(99)
               end

               bFound = false

               entity.attributes.each_attribute{|attr|
                  if attr.name == "DeliveryMethods" then
                     bFound = true
                  end   
               }

               if bFound == false then
                  puts
                  puts file
                  puts
                  puts "Attribute DeliveryMethods for Element Interface has not been found in ft_outgoing_file.xml"
                  puts
                  puts "Majo, me temo que fatal error ! :-p"
                  puts
                  exit(99)
               end

               entity.attributes.each_attribute{|attr|
                  if attr.name == "CleanUpAge" then
                     bFound = true
                  end   
               }

               cleanUpAge = 0

               if bFound == true then
                   cleanUpAge =  entity.attributes["CleanUpAge"].to_s.to_i     
               end


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
#                puts "-----------------------------"               
#                puts fileType
#                puts description
#                puts mnemonic
#                puts compressMethod
#                puts arrDisMethods              
#                puts "-----------------------------"   

               arrToList << fillDeliveryInterfaceStruct(mnemonic, compressMethod, arrTmp, cleanUpAge)

            }
                
         }
         
             if outgoing == true
	             newFile = Struct::OutgoingFile.new(fileType, description, arrToList)
             else
	             newFile = @@dynStructIn.new(fileType, description, arrFromList, arrToList)
	          end
            	          
             #--------------------------------------------------------
             # Check duplicated elements, in case of finding them, abort
             arrFiles.each{|element|
                if element[:fileType] == file.attributes["Type"] then
                   puts "Error in DCC Configuration !  :-("
                   print "#{element[:fileType]} type is duplicated in "
                   if outgoing == true then
                      print "ft_outgoing_files.xml"
                   else
                      print "ft_incoming_files.xml" 
                   end
                   puts
                   puts
                   exit(99)
                end
             }
             #--------------------------------------------------------
             
	          arrFiles << newFile
             
             if @isDebugMode == true then
                puts newFile
             end
      }
            
   end
   #-------------------------------------------------------------
   # Process File
   # - xmlFile (IN): XML file
   # - arrFile (OUT): 
   def processFileTypeLists(xmlFile, arrFiles, outgoing)
      description    = ""
      newFile        = nil
      newFilename    = nil
      newFiletype    = nil  
      compressMethod = nil
      arrFromList    = Array.new
      arrToList      = Array.new
      
      file = XPath.each(xmlFile, "FileList/File"){      
             |file|                  

             # Distinguish between Name or Type
             filetype = file.attributes["Type"]
            
             if filetype.include?("*") == true or filetype.include?("?") == true then
                filename = filetype
                filetype = nil
             end

             if filetype == nil and filename == nil then
                puts
                file.attributes.each_attribute{|attr|
                   puts "File Attribute -> #{attr.name}"
                }
                puts
                puts file
                puts
                puts "XML element File must contain a Wildcard or Type Attribute"
                puts "Error in ReadFileDestination::processFileTypeLists ! :-("
                puts
                exit(99)
             end

             XPath.each(file, "Description"){
                 |desc|
                 description = desc.text
             }
           
             XPath.each(file, "FromList"){
                 |list|
                 arrFromList = Array.new
                 XPath.each(list, "EntityMnemonic/"){
                    |mnemonic|
                    arrFromList << mnemonic.text
                 }
             }

             # Read Compression Flag
             if outgoing == true then
	             XPath.each(file, "CompressMethod"){
		             |compress|
		             compressMethod = compress.text
		          }
	          end

             XPath.each(file, "ToList"){
                 |list|
                 arrToList = Array.new
                 XPath.each(list, "EntityMnemonic/"){
                    |mnemonic|
                    arrToList << mnemonic.text
                 }
             }

             if outgoing == true
	             newFile = Struct::OutgoingFile.new(file.attributes["Name"], compressMethod, arrFromList, arrToList)
             else
                if filename != nil then
                   newFilename = Struct::IncomingFilename.new(filename, description, arrFromList, arrToList)
                end
                if filetype != nil then
                   newFiletype = @@dynStructIn.new(filetype, description, arrFromList, arrToList)
	                newFile = @@dynStructIn.new(filetype, description, arrFromList, arrToList)
                
                end
	          end
	          
             #--------------------------------------------------------
             if filetype != nil then
                # Check duplicated elements, in case of finding them, abort
                arrFiles.each{|element|
                   if element[:fileType] == file.attributes["Name"] then
                      puts "Error in DCC Configuration !  :-("
                      print "#{element[:fileType]} type is duplicated in "
                      if outgoing == true then
                         print "ft_outgoing_files.xml"
                      else
                         print "ft_incoming_files.xml" 
                      end
                      puts
                      puts
                      exit(99)
                   end
                }

                arrFiles << newFiletype

                if @isDebugMode == true then
                   puts newFiletype
                end

             end
             #--------------------------------------------------------
             if filename != nil then
                @@arrIncomingFilenames.each{|element|
                   if element[:fileName] == filename then
                      puts "Error in DCC Configuration !  :-("
                      print "#{element[:fileName]} Name is duplicated in "
                      if outgoing == true then
                         print "ft_outgoing_files.xml"
                      else
                         print "ft_incoming_files.xml" 
                      end
                      puts
                      puts
                      exit(99)               
                   end
                }

                @@arrIncomingFilenames << newFilename

                if @isDebugMode == true then
                   puts newFilename
                end


             end
             #--------------------------------------------------------
	          

      }
            
   end
   #-------------------------------------------------------------
      
   def fillDeliveryInterfaceStruct(mnemonic, compress, arrDissMethods, cleanUpAge)
      return Struct::DeliveryInterface.new(mnemonic, compress, arrDissMethods, cleanUpAge)
   end
   #-------------------------------------------------------------
   
   # Get Files which are sent/received from/to an Entity
   # - inout (IN): Flag to get incoming or outgoing files
   # - list (?): ???
   # - mnemonic (IN): Entity name
   def getFiles(inout, list, mnemonic, bFileType = true)
      arrResult = Array.new
      arrFiles  = Array.new
      if inout == @@FT_INCOMING then
         if bFileType == true then
            arrFiles = @@arrIncomingFiles
         else
            arrFiles = @@arrIncomingFilenames
         end
      else
         arrFiles = @@arrOutgoingFiles
      end
      arrFiles.each{|file|
         arrTo = file[:toList]
         arrTo.each{|anInterface|
            if anInterface[:mnemonic] == mnemonic or mnemonic == nil then
               arrResult << file[:fileType]
            end
         }
      }      
      return arrResult.uniq.sort
   end
   #-------------------------------------------------------------
   
   # Get the Mnemonics which send/receive to/from a file
   # - inout (IN): ???
   # - list (?): ???
   # - filetype (IN): ???
   def getMnemonics (inout, list, filetype, bFileType = true)
      arrResult = Array.new
      arrFiles  = Array.new
      if inout == @@FT_INCOMING then
         if bFileType == true
            arrFiles = @@arrIncomingFiles
         else
            arrFiles = @@arrIncomingFilenames
         end
      else
         arrFiles = @@arrOutgoingFiles
      end
      nFiles  = arrFiles.length            
      0.upto(nFiles-1) do |i|
         if bFileType == true         
            if filetype == arrFiles[i][:fileType] then
               if list == @@FT_TO then
                  arrEnts = Array.new
                  arrFiles[i][:toList].each{|anEntity|
                     arrEnts << anEntity[:mnemonic]
                  }   
                  return arrEnts
               else
                  return arrFiles[i][:fromList]
               end            
            end
         else
            # Perform the matching of wildcards
            wildcard = arrFiles[i][:fileName]

            if File.fnmatch(wildcard, filetype) == true then
               if list == @@FT_TO then
                  arrEnts = Array.new
                  arrFiles[i][:toList].each{|anEntity|
                     arrEnts << anEntity[:mnemonic]
                  }   
                  return arrEnts
               else
                  return arrFiles[i][:fromList]
               end            
            end
         end

      end
      return
   end
   #-------------------------------------------------------------

end # class


end # module
