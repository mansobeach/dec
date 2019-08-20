#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #EntityContentWriter class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component 
# 
# CVS:
#
# = This class writes an XML file with the content of an Entity Download
# = directory
#
#########################################################################

require 'dec/ReadConfigDEC'

module DEC

class EntityContentWriter

   ## -----------------------------------------------------------
   
   ## Class contructor
   def initialize(directory)
	   @targetDirectory = directory
      @realname        = ""
      checkModuleIntegrity
      @isDebugMode     = false
      @satPrefix = DCC::ReadConfigDCC.instance.getSatPrefix
      @prjName   = DCC::ReadConfigDCC.instance.getProjectName
      @prjID     = DCC::ReadConfigDCC.instance.getProjectID
      @mission   = DCC::ReadConfigDCC.instance.getMission
   end
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   ## -----------------------------------------------------------
   
   def writeData(entity, pollingTime, arrHashData)
	   @entity       = entity
      @pollingTime  = pollingTime.strftime("%Y%m%dT%H%M%S")
		@validityTime = pollingTime.strftime("UTC=%Y-%m-%dT%H:%M:%S")
		createFile
		@theFile.puts(%Q{  <Earth_Explorer_Header>})
      writeFixedHeader
      writeVariableHeader
		@theFile.puts(%Q{  </Earth_Explorer_Header>})
      writeDataBlock(arrHashData)
		@theFile.puts(%Q{</Earth_Explorer_File>})
		@theFile.flush
      @theFile.close
   end
   ## -----------------------------------------------------------
   
   def getFilename
      return @realname
   end
   ## -----------------------------------------------------------
private
      
	## -----------------------------------------------------------
   
   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      return true
   end
   ## -----------------------------------------------------------
   
   def createFile
	   prevDir = Dir.pwd
      
      fileType  = ""      
      entity    = @entity.rjust(5,"_")      
   	@filename = %Q{#{@satPrefix}_OPER_DEC_L#{entity.slice(0,5)}_#{@pollingTime}_#{@pollingTime}_0001}
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
   
   def writeFixedHeader
      @theFile.puts("    <Fixed_Header>")
      @theFile.puts("      <File_Name>#{@filename}</File_Name>")
      @theFile.puts("      <File_Description>Data Collector Component File List from #{@entity}</File_Description>")
      @theFile.puts("      <Notes></Notes>")
		@theFile.puts("      <Mission>#{@mission}</Mission>")
		@theFile.puts("      <File_Class>OPER</File_Class>")
		@theFile.puts("      <File_Type>DCC_LFILES</File_Type>")
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
      @theFile.puts("      <Source>#{@entity}</Source>")
		@theFile.puts("      <PollingDate>#{@validityTime}</PollingDate>")
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
