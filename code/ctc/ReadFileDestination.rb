#!/usr/bin/env ruby

#########################################################################
#
# ===Ruby source for #ReadFileDestination class          
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: ReadFileDestination.rb,v 1.19 2009/04/29 12:43:28 algs Exp $
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
   

   # Get all Entities (internal and external Entities) Receiving
   # an outgoing file of a given FileType
   # - filetype (IN): File type
   def getEntitiesReceivingOutgoingFile(filetype)
      if @isDebugMode then 
         print("\nGet External Entities which Receive the ", filetype, " file type \n")
      end
      if filetype.include?("*") == true or filetype.include?("?") == true then
         return getMnemonics(@@FT_OUTGOING, @@FT_TO, filetype, false)
      else
         return getMnemonics(@@FT_OUTGOING, @@FT_TO, filetype)
      end
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


   #
   def getCompressMethodForNames(entity, filename)
      @@arrOutgoingFilenames.each{|element|
         if element[:fileName] == filename then
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


   #
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

   
   #
   def getDeliveryMethodsForNames(entity, filename)
      @@arrOutgoingFilenames.each{|element|
         if element[:fileName] == filename then
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

   
   #
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
   
   
   # Get an Array of all FileTypes registered in ft_outgoing_files.xml
   def getAllOutgoingTypes
      return getFiles(@@FT_OUTGOING, @@FT_TO, nil)
   end
   #-------------------------------------------------------------


   # Get an Array of all FileTypes registered in ft_incoming_files.xml
   def getAllOutgoingFileNames
      return getFiles(@@FT_OUTGOING, @@FT_TO, nil, false)
   end
   #-------------------------------------------------------------
   

   # DEPRECATED, please use getAllOutgoingTypes
   # Get an Array of all FileTypes registered in ft_outgoing_files.xml
   def getAllOutgoingFiles
      return getAllOutgoingTypes
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
   
   @@dynStruct         = nil
   @@configDirectory   = ""
   
   @@xmlOutFiles       = nil

   @@monitorCfgFiles   = nil
   
   # Class constants
   @@FT_OUTGOING = 2
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
      Struct.new("OutgoingFilename", :fileName, :description, :toList)
      Struct.new("DeliveryInterface", :mnemonic, :compressMethod, :deliveryMethods, :cleanUpAge)
   end
   #-------------------------------------------------------------
   

   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
      outgoingFilename = %Q{#{@@configDirectory}/ft_outgoing_files.xml}
      fileOutgoing     = File.new(outgoingFilename)
      xmlOutgoing      = REXML::Document.new(fileOutgoing)
      @@arrOutgoingFiles      = Array.new
      @@arrOutgoingFilenames  = Array.new
      if @isDebugMode == true then
         puts "\nProcessing Outgoing Files"
      end
      processOutFileTypeLists(xmlOutgoing, @@arrOutgoingFiles)
   end   
   #-------------------------------------------------------------
   

   # Process File
   # - xmlFile (IN): XML file
   # - arrFile (OUT): 
   def processOutFileTypeLists(xmlFile, arrFiles)
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
         

         # Distinguish between Name or Type (if wildcard --> name else its a normal type)
         filetype = file.attributes["Type"]
            
         if filetype.include?("*") == true or filetype.include?("?") == true then
            fileName = filetype
            filetype = nil
         end

         #if there are not wildcards
         if filetype != nil then

            newFile = Struct::OutgoingFile.new(fileType, description, arrToList)

            # Check duplicated elements, in case of finding them, abort
            arrFiles.each{|element|
               if element[:fileType] == file.attributes["Name"] then
                  puts "Error in DCC Configuration !  :-("
                  print "#{element[:fileType]} type is duplicated in ft_outgoing_files.xml"
                  puts
                  puts
                  exit(99)
               end
            }

            arrFiles << newFile
             
            if @isDebugMode == true then
               puts newFile
            end
         end
         #--------------------------------------------------------

         #if the name has wildcards
         if fileName != nil then 

            newFilename = Struct::OutgoingFilename.new(fileName, description, arrToList)

            @@arrOutgoingFilenames.each{|element|
               if element[:fileName] == fileName then
                  puts "Error in DCC Configuration !  :-("
                  print "#{element[:fileName]} Name is duplicated in ft_outgoing_files.xml"
                  puts
                  puts
                  exit(99)               
               end
            }

            @@arrOutgoingFilenames << newFilename

            if @isDebugMode == true then
               puts newFilename
            end
        end
        #--------------------------------------------------------

      }

   end   #end of processOutFileTypeLists

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

      if bFileType == true then
         arrFiles = @@arrOutgoingFiles
      else
         arrFiles = @@arrOutgoingFilenames
      end

      arrFiles.each{|file|
         arrTo = file[:toList]
         arrTo.each{|anInterface|
            if anInterface[:mnemonic] == mnemonic or mnemonic == nil then
               if bFileType == true then
                  arrResult << file[:fileType]
               else
                  arrResult << file[:fileName]
               end
            end
         }
      }      
      return arrResult.uniq.sort
   end

   #-------------------------------------------------------------
   


   # Get the Mnemonics which receive a file (file-type)
   # - inout (IN): ???
   # - list (?): ???
   # - filetype (IN): ???
   def getMnemonics (inout, list, filetype, bFileType = true)

      arrResult = Array.new
      arrFiles  = Array.new
      
      if bFileType == true then
         arrFiles = @@arrOutgoingFiles
      else
         arrFiles = @@arrOutgoingFilenames
      end
      
      nFiles  = arrFiles.length   

      0.upto(nFiles-1) do |i|   
         if bFileType == true         
            if filetype == arrFiles[i][:fileType] then
               arrEnts = Array.new
               arrFiles[i][:toList].each{|anEntity|
                  arrEnts << anEntity[:mnemonic]
               }   
               return arrEnts          
            end
         else
            # Perform the matching of wildcards
            wildcard = arrFiles[i][:fileName]

            if File.fnmatch(wildcard, filetype) == true then
               arrEnts = Array.new
               arrFiles[i][:toList].each{|anEntity|
                  arrEnts << anEntity[:mnemonic]
                 }   
               return arrEnts          
            end
         end
      end   #end do
      return
   end
   #-------------------------------------------------------------


end # class


end # module
