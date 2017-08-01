#!/usr/bin/env ruby

#########################################################################
#
# == Ruby source for #ReadDimInTray class          
#
# == Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component -> Data Collector Component
# 
# CVS: $Id: ReadInTrayConfig.rb,v 1.6 2008/04/04 14:01:51 decdev Exp $
#
# This class processes files2InTrays.xml config file
# which contain the link between a file type and the DIMs that process it.
# Moreover, the DIM In-Tray in which the file will be placed for later processing.
#
#########################################################################

require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


module DCC

class ReadInTrayConfig

   include Singleton
   include REXML
   include CUC::DirUtils
   #-------------------------------------------------------------
  
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
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadInTrayConfig debug mode is on"
   end
   #-------------------------------------------------------------

   # Re-parse and re-load the structures
   def refresh
      loadData
   end
   #-------------------------------------------------------------
   
   def getDIMCompress(name)
      @@arrDims.each{|dim|
         if name == dim[:name] then
            return dim[:compress]
         end
      }
      return false

   end
   #-------------------------------------------------------------
   
   # Get the In-Tray directory for a given DIM Name
   # It returns the InTray Directory if present, otherwise false
   def getDIMInTray(name)
      
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
      
      @@arrDims.each{|dim|
         if dimName == dim[:name] then
            return expandPathValue(dim[:intray])
         end
      }
      return false
   end
   #-------------------------------------------------------------
   
   # It returns true if the given name exists as a DIM
   def existDim?(name)
      @@arrDims.each{|dim|
         if dim[:name] == name then
            return true
         end
      }
      return false
   end
   #-------------------------------------------------------------
   
   # It returns an Array of the target directories (the DIMs In-Trays)
   # for the given filetype.  
   def getTargetDirs4Filetype(filetype)
	   arrDirs = Array.new
      arrDims = getDIMs4Filetype(filetype)
      if arrDims == false then
		   if @isDebugMode == true then
			   puts "No target In-Tray(s) for #{filetype} filetype in files2InTrays.xml" 
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
   
   # It returns an Array of the target directories (the DIMs In-Trays)
   # for the given filename.     
   def getTargetDirs4Filename(filename)
	   arrDirs = Array.new
      arrDims = getDIMs4Filename(filename)
      if arrDims == false then
		   if @isDebugMode == true then
			   puts "No target In-Tray(s) for #{filename} filename in files2InTrays.xml" 
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
     return getFileField(afiletype, "arrDims") 
   end    
   #-------------------------------------------------------------

   # This method has been implemented in order to deal with
   # Non Earth Explorer Files
   def getDIMs4Filename(afilename)
      return getFileField(afilename, "arrDims")
   end    
   #-------------------------------------------------------------
      
   # It retrieves all DIMs defined in the DIM_List
   def getAllDIMs
      arrDims = Array.new
      @@arrDims.each{|dim|
         arrDims << dim[:name]
      }
      return arrDims
   end
	#-------------------------------------------------------------
	
	# It retrieves all FileTpyes declared in the FileList
	def getAllFileTypes
	   arrFiles = Array.new
	   @@arrFiles2Dims.each{|file|
		   arrFiles << file[:filetype]
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
   #-------------------------------------------------------------   
   
   # This method returns true if the given filename/filetype 
   # is disseminated as a hardlink to the DIMs In-Trays.
   # In case the given filetype does not exit it aborts
   def isHardLinked?(afile)
      return getFileField(afile, "hardlink")
   end
   #-------------------------------------------------------------
   
   # Get a Parameter info for a given filename/filetype.
   # Filenames are recognized by the wildcard * at their end.
   def getFileField(afile, param)
      file = getFile(afile)
      if file == false then
         return false
      end
      return file[param]
   end
   #-------------------------------------------------------------
   
   # Get the information for a given filename or filetype
   # Filenames are recognized by the wildcard * at their end.
   def getFile(afile)
      @@arrFiles2Dims.each{|file|
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
      puts "Error in DCC_ReadDimInTray::getFile"
      puts "#{afile} is not registered in files2InTrays.xml"
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
   
      @@arrFiles2Dims.each{|file|
      
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
   
   # Class constants
   @@FT_INCOMING = 1
   @@FT_OUTGOING = 2
   @@FT_FROM     = 1
   @@FT_TO       = 2

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      
      bDefined = true
      bCheckOK = true
   
      if !ENV['DCC_CONFIG'] then
         puts "DCC_CONFIG environment variable not defined !  :-(\n"
         bCheckOK = false
         bDefined = false
      end
           
      if bDefined == true then      
         configDir         = %Q{#{ENV['DCC_CONFIG']}}        
         @@configDirectory = configDir
        
         @@configFile = %Q{#{@@configDirectory}/files2InTrays.xml}        
         if !FileTest.exist?(@@configFile) then
            bCheckOK = false
            print("\n\n", @@configFile, " does not exist !  :-(\n\n" )
         end           
      end
         
      if bCheckOK == false then
        puts "ReadInTrayConfig::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end      
   end
   #-------------------------------------------------------------
	# This method creates all the structs used
	def defineStructs
	   Struct.new("DIMStruct", :name, :intray, :compress)		
		Struct.new("Files2DimsStruct", :filetype, :filename, :hardlink, :arrDims)
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
         puts "\nProcessing #{@@configFile}"
      end
      process(xmlFile)     
   end   
   #-------------------------------------------------------------
   
   # Process the xml file decoding all the file
   # - xmlFile (IN): XML configuration file
   def process(xmlFile)
#      setDebugMode
      dimName              = ""
      dimInTray            = ""
      @@arrDims            = Array.new
      filetype             = ""
      filename             = ""
      hardlink             = ""
      @@arrFiles2Dims      = Array.new
      #----------------------------------------
      # DIMs List Processing
      path    = "DisseminationParams/DIM_List/DIM"
      
      dims = XPath.each(xmlFile, path){
          |dim|
                         
          XPath.each(dim, "Name"){
             |name|
             dimName = name.text
          }
  
          XPath.each(dim, "IntrayDir"){
             |intray|
             dimInTray = intray.text
          }	  

          compress = nil

          XPath.each(dim, "Compress"){
             |kompress|
             compress = kompress.text
          }	  
      
          # Avoid DIMs duplication in DIM_List
          @@arrDims.each{|xdim|
             if xdim[:name] == dimName then
                puts "ERROR in #{@@configFile} file !"
                puts "#{dimName} is duplicated in the DIM_List"
                puts "Please check your configuration file"
                puts
                exit(99)
             end
          }
      
          @@arrDims << fillDimsStruct(dimName, dimInTray, compress)      
      
      }
            
      #----------------------------------------
      # File Type List Processing     
      # DIMs List Processing
      path    = "DisseminationParams/FileList/File"
      
      files = XPath.each(xmlFile, path){
         |file|
         
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
            puts "Attribute Type for Element File has not been found in files2InTrays.xml"
            puts
            puts "Fatal error, sorry ! :-p"
            puts
            exit(99)
         end


         file.attributes.each_attribute{|xattr|
            if @isDebugMode == true then
               puts "#{getKey(xattr.xpath)} -> #{xattr.value}"
            end
         }
         
         filetype = file.attributes["Type"]
         filename = file.attributes["Name"]
         
         if filetype == nil then
            filetype = ""
         end

         if filename == nil then
            filename = ""
         end         
                    
         # Avoid the duplication of the filetype
         @@arrFiles2Dims.each{|xfile|
            if filetype == xfile[:filetype] and filetype != "" then
               puts "ERROR in #{@@configFile} file !"
               puts "#{filetype} is duplicated in the FileList"
               puts "Please check your configuration file"
               puts
               exit(99)
            end
         } 
         
         XPath.each(file, "HardLink"){
            |link|
            hardlink = link.text
         }
          
         arrDims = Array.new
         
         XPath.each(file, "ToList"){
            |to|
            XPath.each(to, "DIM"){
               |dim|
               arrDims << dim.text # { dim.text => dim.attributes["Compress"] }
            } 
         }
          
	      @@arrFiles2Dims << fillFileTypeStruct(filetype, filename, hardlink, arrDims)
      }
      
      #----------------------------------------
        
   end
   #-------------------------------------------------------------
   
   # Fill an External entity struct
   # - name (IN)  :  DIM name
   # - intray (IN):  DIM Intray directory
   # - compress (IN):  DIM compress configuration
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillDimsStruct(name, intray, compress)
      tmpStruct     = Struct::DIMStruct.new(name, intray, compress)   		
      return tmpStruct         
   end
   #-------------------------------------------------------------    
   
   # Fill an External entity struct
   # - filetype (IN) :  filetype
   # - filename (IN) :  filename
   # - hardlink (IN) :
   # - arrDims (IN) : Array of strings containing the Dims names
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.
   def fillFileTypeStruct(filetype, filename, hardlink, arrDims)
      if hardlink.upcase == "TRUE" then
         hardlink = true
      else
         hardlink = false
      end     
      tmpStruct     = Struct::Files2DimsStruct.new(filetype,
                                 filename,
                                 hardlink,
                                 arrDims)   		
      return tmpStruct   
   end
   #-------------------------------------------------------------
   
   # I can not understand why there is not a method in REXML that provides
   # you the Key for a given Attribute
   def getKey(xpath)
      arrPath = xpath.split("@")
      return arrPath[1]
   end
   #-------------------------------------------------------------

end # class

end # config
