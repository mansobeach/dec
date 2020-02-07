#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #InterfaceListWriter class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component -> Data Collector Component
# 
# CVS:
#
# = This class writes an XML file with the content of an Interface Download
# = directory or the polled directories
#
#########################################################################

module CTC

class ListWriterDelivery

   ## -----------------------------------------------------------
   
   # Class contructor
   def initialize(directory, bIsOutgoingDelivery=false, fileClass ="", fileType = "")
	   @targetDirectory = directory
      @realname        = ""
      @bIsOutgoing     = bIsOutgoingDelivery
      checkModuleIntegrity
      @isDebugMode     = false
      @bSetup          = false
      @fileType        = fileType
      @fileClass       = fileClass
   end
   ## -----------------------------------------------------------
   
   def setup(satPrefix, prjName, prjID, mission)
      @bSetup = true
      @satPrefix = satPrefix
      @prjName   = prjName
      @prjID     = prjID
      @mission   = mission
   end
   ## -----------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   # -------------------------------------------------------------   
   
   def writeData(entity, pollingTime, arrHashData, bIsEmergencyMode=false)
      if @bSetup == false then
         puts "Error in DeliveryListWriter::writeData !  :-O"
         puts "method DeliveryListWriter::setup has not been called !"
         puts
         exit(99)
      end
	   @entity       = entity
      @pollingTime  = pollingTime.strftime("%Y%m%dT%H%M%S")
		@validityTime = pollingTime.strftime("UTC=%Y-%m-%dT%H:%M:%S")
		createFile(bIsEmergencyMode)
		@theFile.puts(%Q{  <Earth_Explorer_Header>})
      writeFixedHeader(bIsEmergencyMode)
      writeVariableHeader
		@theFile.puts(%Q{  </Earth_Explorer_Header>})
      writeDataBlock(arrHashData)
		@theFile.puts(%Q{</Earth_Explorer_File>})
		@theFile.flush
      @theFile.close
   end
   #-------------------------------------------------------------
   
   def getFilename
      return @realname
   end
   #-------------------------------------------------------------
private
      
	## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      return true
   end
   ## -----------------------------------------------------------
   
   def createFile(bIsEmergencyMode)
	   prevDir = Dir.pwd
      
      fileType  = ""      
      
      if bIsEmergencyMode == true then
         fileType = "MMPF_FT_EM"
      else
         if @bIsOutgoing == true then
            if @fileType != "" then
               fileType = @fileType
            else
               fileType = "MMPF_FTOUT"
            end
         else
            if @fileType != "" then
               fileType = @fileType
            else
               fileType = "MMPF_FT_IN"
            end
         end
      end
      
      centre = "2BOA"
      
   	@filename = %Q{#{@satPrefix}_OPER_#{fileType}_#{centre}_#{@pollingTime}_V#{@pollingTime}_#{@pollingTime}_#{@entity}}
      @realname = %Q{#{@filename}.xml}
      @theFile  = nil
      
      if @isDebugMode == true then
         puts "--- EntityContentWriter -> Realfilename ---"
         puts @realname
         puts "-------------------------------------------"
      end
      
		Dir.chdir(@targetDirectory)
      begin
         @theFile = File.new(@realname, File::CREAT|File::WRONLY)
      rescue Exception
         puts
         puts "Fatal Error in EntityContentWriter::createFile"
         puts "Could not create file #{@realname} in #{Dir.pwd}"
         exit(99)
      end
      Dir.chdir(prevDir)
      @theFile.puts(%Q{<?xml version=\"1.0\"?>})
		@theFile.puts(%Q{<Earth_Explorer_File>})
      @theFile.flush
   end
   
   ## -----------------------------------------------------------
   
   def writeFixedHeader(bIsEmergencyMode=false)
      @theFile.puts("    <Fixed_Header>")
      @theFile.puts("      <File_Name>#{@filename}</File_Name>")
      if @bIsOutgoing == true then
         @theFile.puts("      <File_Description>List of files sent to #{@entity}</File_Description>")
      else
         @theFile.puts("      <File_Description>List of files received from #{@entity}</File_Description>")
      end
      @theFile.puts("      <Notes></Notes>")
		@theFile.puts("      <Mission>#{@mission}</Mission>")
		@theFile.puts("      <File_Class>Routine Operations</File_Class>")
      
      if bIsEmergencyMode == true then
         @theFile.puts("      <File_Type>MMPF_FT_EM</File_Type>")
      else
         if @bIsOutgoing == true then
            if @fileType == "" then
               @theFile.puts("      <File_Type>MMPF_FTOUT</File_Type>")
            else
               @theFile.puts("      <File_Type>#{@fileType}</File_Type>")
            end
         else
            if @fileType == "" then
               @theFile.puts("      <File_Type>MMPF_FT_IN</File_Type>")
            else
               @theFile.puts("      <File_Type>#{@fileType}</File_Type>")
            end
         end
      end
		@theFile.puts("      <Validity_Period>")
      @theFile.puts("        <Validity_Start>#{@validityTime}</Validity_Start>")
      @theFile.puts("        <Validity_Stop>#{@validityTime}</Validity_Stop>")
      @theFile.puts("      </Validity_Period>")
		@theFile.puts("      <File_Version>0001</File_Version>")
		@theFile.puts("      <Source>")
		@theFile.puts("        <System>#{@prjID}</System>")
		@theFile.puts("        <Creator>#{@prjID}</Creator>")
		@theFile.puts("        <Creator_Version>1.0</Creator_Version>")
		@theFile.puts("        <Creation_Date>#{@validityTime}</Creation_Date>")
		@theFile.puts("      </Source>")
      @theFile.puts("    </Fixed_Header>")
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeVariableHeader
      @theFile.puts("    <Variable_Header>")
      if @bIsOutgoing == true then
         @theFile.puts("      <Destination>#{@entity}</Destination>")
		else
         @theFile.puts("      <Source>#{@entity}</Source>")
      end
      @theFile.puts("      <Date>#{@validityTime}</Date>")
      @theFile.puts("    </Variable_Header>")
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeDataBlock(arrHashData)
      @theFile.puts(%Q{  <Data_Block type="xml">})
      
      # Write the Data Block
      @theFile.puts(%Q{    <List_of_Files>})
      writeElement(arrHashData)
      @theFile.puts(%Q{    </List_of_Files>})
       
      @theFile.puts(%Q{  </Data_Block>})
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeElement(arrFiles)
	   arrFiles.each{|file|
		   @theFile.puts(%Q{        <Filename>#{File.basename(file)}</Filename>})
		}
   end
   #-------------------------------------------------------------

end # class

end # module
