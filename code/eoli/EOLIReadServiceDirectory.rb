#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EOLIReadServiceDirectory class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> EOLI Client Component
# 
# CVS: $Id: EOLIReadServiceDirectory.rb,v 1.3 2006/09/29 07:16:01 decdev Exp $
#
# This class reads and decodes the EOLI-SA ServiceDirectory.xml
# configuration file.
#
#########################################################################

require 'singleton'
require 'rexml/document'

require 'cuc/DirUtils'


class EOLIReadServiceDirectory

   include Singleton
   include REXML
   include CUC::DirUtils
   #-------------------------------------------------------------   
   
   # Class contructor
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      @arrCollections     = Array.new
      checkModuleIntegrity
      defineStructs
      @nodeStruct         = Struct.new("Node", :collectionTreeNode)
      loadData
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      STDERR.puts "EOLIReadAppConfiguration debug mode is on"
   end
   #-------------------------------------------------------------
   
   def printCollectionTreeNodes
      path = "*/CollectionTreeNode"
      XPath.each(@xmlFile, path){|x|
         structure = processNode(x, "CollectionTreeNode", "", true)
      }
   end
   #-------------------------------------------------------------
   
   # Retrieve the complete Service Info
   def getServiceInfo(serviceName)
      return searchService(serviceName)
   end
   #-------------------------------------------------------------
   
   # Retrieve all the GIP Values
   def getAllGIPValues
      arrGips = Array.new
      @arrCollections.each{|collection|
         arrGips << collection[:gipValue]
      }
      return arrGips.uniq
   end
   #-------------------------------------------------------------
   
   # Retrieve all the Collections
   def getAllCollections
      return @arrCollections.uniq
   end
   #-------------------------------------------------------------
   
   # It returns the File Internal Version Number.
   def getVersionNumber
      return @versionNumber
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
        
         @@configFile = %Q{#{@@configDirectory}/ServiceDirectory.xml}        
         if !FileTest.exist?(@@configFile) then
            bCheckOK = false
            print("\n\n", @@configFile, " does not exist !  :-(\n\n" )
         end           
      end
         
      if bCheckOK == false then
        STDERR.puts "EOLIReadAppConfiguration::checkModuleIntegrity FAILED !\n\n"
        exit(255)
      end      
   end
   #-------------------------------------------------------------
   
	# This method defines all the structs used
	def defineStructs
	   Struct.new("Collection", :gipValue, :description)
	end
	#-------------------------------------------------------------   
   
   # Load the file into the an internal struct.
   #
   # The struct is defined in the class Constructor. See #initialize.
   def loadData
      externalFilename = @@configFile
      fileExternal     = File.new(externalFilename)
      @xmlFile         = REXML::Document.new(fileExternal)

      @@arrServletsServices = Array.new
     
      if @isDebugMode == true then
         STDERR.puts "\nProcessing #{@@configFile}"
      end
      process(@xmlFile)     
   end   
   #-------------------------------------------------------------
   
   # Process the xml file decoding all the file
   # - xmlFile (IN): XML configuration file
   def process(xmlFile)
      @arrCollections      = Array.new
#      setDebugMode
      @lastUpdated         = ""
      @versionNumber       = ""
      gipValue             = ""
      description          = ""
 
      # LastUpdated
      path    = "/ServiceDirectory/LastUpdated"
      config  = XPath.each(xmlFile, path){
          |date|
	       @lastUpdated = date.text
      }
      
      # VersionNumber
      path    = "/ServiceDirectory/VersionNumber"
      config  = XPath.each(xmlFile, path){
          |version|
	       @versionNumber = version.text
      }   	        
      
      if @isDebugMode == true then
         STDERR.puts "================================="
         STDERR.puts "Last Updated   = #{@lastUpdated}"
         STDERR.puts "Version Number = #{@versionNumber}"
	      STDERR.puts "================================="
      end
     
      path = "*/CollectionTreeNode"
      
      XPath.each(@xmlFile, path){|x|
         structure = processNode(x, "CollectionTreeNode", "", false)
      }


      path = "ServiceDirectory/Collection/"

      collection = XPath.each(@xmlFile, path){
         |aCollection|       
         XPath.each(aCollection, "Collection_ID/GIPValue"){
            |aGipValue|
            # Only if the GIPValue is not empty
            if aGipValue.text != nil then
               gipValue = aGipValue.text
               
               XPath.each(aCollection, "Collection_Desc"){
                  |aDesc|
                  description = aDesc.text
               }
               
            end  
         }
         @arrCollections << fillCollectionStruct(gipValue, description)
      }

   end
   #-------------------------------------------------------------   
   
   # processNode
   def processNode(element, path, sangria, printNode = false)      
      if printNode == true then
         print sangria, element.attributes["idref"], "\n"
      end
      checkElement = XPath.first(element, path)
      
      if checkElement == nil then
 	      return element
      else
       
      XPath.each(element,path){|x|
            tt = processNode(x, path,%{#{sangria}   }, printNode)
	   }
      end
   end
   #-------------------------------------------------------------

   
   # Collection Struct is filled in this method.
   #
   # There is only one point in the class where all Dynamic structs 
   # are filled so that it is easier to update/modify the I/Fs   
   def fillCollectionStruct(aGipValue, aDescription)
      aCollection = Struct::Collection.new(
                          aGipValue,
                          aDescription
                         )
   
      return aCollection
   end
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
