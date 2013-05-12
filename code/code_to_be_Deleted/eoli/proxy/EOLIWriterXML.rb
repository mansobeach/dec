#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EOLIWriterXML class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> EOLI Client Component
# 
# CVS: $Id: EOLIWriterXML.rb,v 1.3 2006/09/29 07:16:01 decdev Exp $
#
# = This class writes the XML file result of an Inventory_Retrieve req
#
#########################################################################

require 'eoli/EOLICommon'


class EOLIWriterXML

   #-------------------------------------------------------------
   
   # Class contructor
   def initialize(strGIPCollection, start, stop, baseline = "", keep = true)
      @gipCollection = strGIPCollection
      @dateStart     = start
      @dateStop      = stop
      @start         = EOLICommon::getStrUTCTime(@dateStart)
      @stop          = EOLICommon::getStrUTCTime(@dateStop)
      @baseline      = baseline
      checkModuleIntegrity
      @currentTime   = Time.now
      @currentTime.utc
      @keep          = keep
      @now           = @currentTime.strftime("%Y-%m-%dT%H:%M:%S")
   end
   #-------------------------------------------------------------
   
   def writeData(arrHashData)
      createFile
      writeHeader
      writeDataBlock(arrHashData)
      @theFile.puts(%Q{</Earth_Explorer_File>})
      @theFile.flush
      @theFile.close
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
      start     = EOLICommon::getStrUTCEETime(@dateStart)
      stop      = EOLICommon::getStrUTCEETime(@dateStop)
      query     = EOLICommon::getStrUTCEETime(@currentTime)
      @filename = %Q{MUS_#{@gipCollection}_#{query}_#{start}_#{stop}}
      @realname = %Q{#{@filename}.xml}
      @theFile  = nil
     
      if @keep == true then
         begin
            @theFile = File.new(@realname, File::CREAT|File::WRONLY)
         rescue Exception
            STDERR.puts
            STDERR.puts "Fatal Error in EOLIWriterXML::createFile"
            STDERR.puts "Could not create file #{@realname} in #{Dir.pwd}"
            exit(99)
         end
      else
         @theFile = STDOUT
      end      

      @theFile.puts(%Q{<?xml version=\"1.0\"?>})
      @theFile.puts(%Q{<Earth_Explorer_File>})
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeHeader
      @theFile.puts(%Q{  <Earth_Explorer_Header>})
      writeFixedHeader
      writeVariableHeader
      @theFile.puts(%Q{  </Earth_Explorer_Header>})
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeFixedHeader
      @theFile.puts("    <Fixed_Header>")
      @theFile.puts("      <File_Name>#{@filename}</File_Name>")
      @theFile.puts("      <File_Description>PMF-DCC EOLI Client Retrieve Result</File_Description>")
      @theFile.puts("      <Validity_Period>")
      @theFile.puts("        <Validity_Start>UTC=#{@start}</Validity_Start>")
      @theFile.puts("        <Validity_Stop>UTC=#{@stop}</Validity_Stop>")
      @theFile.puts("      </Validity_Period>")
      @theFile.puts("      <Creation_Date>UTC=#{@now}</Creation_Date>")
      @theFile.puts("    </Fixed_Header>")
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeVariableHeader
      @theFile.puts("    <Variable_Header>")
      @theFile.puts("      <GIPValue>#{@gipCollection}</GIPValue>")
      if @baseline != "" then
         @theFile.puts("      <Baseline>#{@baseline}</Baseline>")
      end
      @theFile.puts("      <CompleteFlag></CompleteFlag>")
      @theFile.puts("    </Variable_Header>")
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeDataBlock(arrHashData)
      @theFile.puts(%Q{  <Data_Block type="xml">})
      
      # Write the Data Block
      @theFile.puts(%Q{    <List_of_Products>})
      writeProducts(arrHashData)
      @theFile.puts(%Q{    </List_of_Products>})
       
      @theFile.puts(%Q{  </Data_Block>})
      @theFile.flush
   end
   #-------------------------------------------------------------
   
   def writeProducts(arrHashData)
      arrHashData = arrHashData.flatten
      arrHashData.each{|rows|
         @theFile.puts(%Q{      <Product>})
         rows.each{|key, value|
            @theFile.puts(%Q{        <#{key}>#{value}</#{key}>})
         }
         @theFile.puts(%Q{      </Product>})
      }
   end
   #-------------------------------------------------------------
end
