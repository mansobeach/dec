#!/usr/bin/env ruby

#########################################################################
#
# = Ruby source for #TimeWindownListWriter class
#
# = Written by DEIMOS Space S.L. (algk)
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

require 'getoptlong'

require 'dbm/DatabaseModel'


class ListWriterByTimeWindow

   #-------------------------------------------------------------
   
   # Class contructor
   def initialize(directory, table, start, stop, fileClass = "", fileType = "")
	   @targetDirectory  = directory
      @realname         = ""
      @table            = table
      checkModuleIntegrity
      @isDebugMode     = false
      @bSetup          = false
      @fileClass       = fileClass
      @fileType        = fileType
      @start           = start
      @stop            = stop
      @currentTime = Time.now
      @currentTime.utc      
   end
   #-------------------------------------------------------------
   
   def setup(satPrefix, prjName, prjID, mission, namespace='', schema='')
      @bSetup = true
      @satPrefix  = satPrefix
      @prjName    = prjName
      @prjID      = prjID
      @mission    = mission
      @namespace  = namespace
      @schema     = schema
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
   end
   #------------------------------------------------------------- 

   def getFiles
      case @table      
         when 'track'    then
            result = TrackedFile.find(:all, :order => "interface_id", :conditions => { :tracking_date => @start..@stop})
         when 'send'       then
            result = SentFile.find(:all, :order => "interface_id", :conditions => { :delivery_date => @start..@stop})
         when 'receive'   then
            result = ReceivedFile.where(:reception_date => @start..@stop) # all # .find(:all) #, :conditions => { :reception_date => @start..@stop})
         when 'unknown'    then
            result = UnknownFile.find(:all, :order => "interface_id", :conditions => { :unknown_date => @start..@stop})
      end
      return result
   end

   
   def writeData()
      if @bSetup == false then
         puts "Error in TimeWindownListWriter::writeData !  :-O"
         puts "method TimeWindownListWriter::setup has not been called !"
         puts
         exit(99)
      end

      fileList=getFiles

		createFile
      
		@theFile.puts(%Q{  <Earth_Explorer_Header>})
      writeFixedHeader
	   @theFile.puts(%Q{  <Variable_Header/>})
		@theFile.puts(%Q{  </Earth_Explorer_Header>})
      if fileList.empty?
         @theFile.puts(%Q{ <Data_Block/>})
      else
         writeDataBlock(fileList)
      end
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
      
	#-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return true
   end
   #-------------------------------------------------------------
   
   def createFile
	   prevDir = Dir.pwd

      startStr = @start.strftime("%Y%m%dT%H%M%S")
      stopStr  = @stop.strftime("%Y%m%dT%H%M%S")
      nowStr   = DateTime.now.strftime("%Y%m%dT%H%M%S")

   	# @filename = %Q{#{@satPrefix}_#{@fileClass}_#{@fileType}_#{@prjID}_#{startStr}_#{stopStr}_0001}

      @filename = %Q{#{@satPrefix}_#{@fileClass}_#{@fileType}_#{@prjID}_#{nowStr}_V#{startStr}_#{stopStr}}

      @realname = %Q{#{@filename}.EOF}
      
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

      addon=''
      if !@namespace.empty? then
            addon="xmlns=\"#{@namespace}\" "
      end
      if !@schema.empty? then
            addon=addon+"xsi:schemaLocation=\"#{@schema}\""
      end
      @theFile.puts(%Q{<Earth_Explorer_File #{addon}>})

      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeFixedHeader
      @theFile.puts("    <Fixed_Header>")
      @theFile.puts("      <File_Name>#{@filename}</File_Name>")
      if @table == 'send' then
         @theFile.puts("      <File_Description>List of files delivered on time window</File_Description>")
      else
         if @table == 'receive' then
            @theFile.puts("      <File_Description>List of files received on time window</File_Description>")
         end
      end
      @theFile.puts("      <Notes></Notes>")
		@theFile.puts("      <Mission>#{@mission}</Mission>")
      if @fileClass ==  "" then
         @fileClass = "Routine Operations"
      end
		@theFile.puts("      <File_Class>#{@fileClass}</File_Class>")
      
      if @table == 'send' then
         if @fileType == "" then
            @theFile.puts("      <File_Type>REP_SSDLR_</File_Type>")
         else
            @theFile.puts("      <File_Type>#{@fileType}</File_Type>")
         end
      else
         if @table == 'receive' then
            if @fileType == "" then
               @theFile.puts("      <File_Type>REP_SSREC_</File_Type>")
            else
               @theFile.puts("      <File_Type>#{@fileType}</File_Type>")
            end
         end
      end
      startUTC = @start.strftime("UTC=%Y-%m-%dT%H:%M:%S")
      stopUTC = @stop.strftime("UTC=%Y-%m-%dT%H:%M:%S")
		creationTime = @currentTime.strftime("UTC=%Y-%m-%dT%H:%M:%S")

		@theFile.puts("      <Validity_Period>")
      @theFile.puts("        <Validity_Start>#{startUTC}</Validity_Start>")
      @theFile.puts("        <Validity_Stop>#{stopUTC}</Validity_Stop>")
      @theFile.puts("      </Validity_Period>")
		@theFile.puts("      <File_Version>0001</File_Version>")
		@theFile.puts("      <Source>")
		@theFile.puts("        <System>#{@prjID}</System>")
		@theFile.puts("        <Creator>#{@prjID}</Creator>")
		@theFile.puts("        <Creator_Version>1.0</Creator_Version>")
		@theFile.puts("        <Creation_Date>#{creationTime}</Creation_Date>")
		@theFile.puts("      </Source>")
      @theFile.puts("    </Fixed_Header>")
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   
   def writeDataBlock(data)

      interfaceArray = Hash.new
      data.each{|file|
         if !interfaceArray.include?(file.interface_id) then
            interfaceArray[file.interface_id] = Array.new
         end
         interfaceArray[file.interface_id] << file

      }

      case @table      
            when 'track'   then
               tag='track'
            when 'send'    then
               tag='Target'
            when 'receive' then
               tag='Source'
            when 'unknown' then
               tag='unknown'
      end

      # Write the Data Block
      @theFile.puts(%Q{  <Data_Block>})
      @theFile.puts(%Q{    <List_of_#{tag}s count="#{interfaceArray.length}">})

      interfaceArray.each {|interface, arrayOfFiles|
         @theFile.puts(%Q{       <#{tag}>})
         @theFile.puts(%Q{          <Name>#{Interface.find_by_id(interface).name}</Name>})
         @theFile.puts(%Q{             <List_of_Files count="#{arrayOfFiles.length}">})

         arrayOfFiles.each{|file|
            if file.interface_id == interface then
               @theFile.puts(%Q{             <File>})
               @theFile.puts(%Q{                <Name>#{file.filename}</Name>})
               case @table      
                  when 'send'    then
                     @theFile.puts(%Q{                <Date>#{file.delivery_date.strftime("UTC=%Y-%m-%dT%H:%M:%S")}</Date>})
                  when 'receive' then
                     @theFile.puts(%Q{                <Size>#{file.size}</Size>})
                     @theFile.puts(%Q{                <Date>#{file.reception_date.strftime("UTC=%Y-%m-%dT%H:%M:%S")}</Date>})
               end               
               @theFile.puts(%Q{             </File>})
            end
         }

         @theFile.puts(%Q{             </List_of_Files>})
         @theFile.puts(%Q{       </#{tag}>})
      }
      @theFile.puts(%Q{    </List_of_#{tag}s>})
      @theFile.puts(%Q{  </Data_Block>})
      @theFile.flush
   end
   #-------------------------------------------------------------
   
end # class

end # module
