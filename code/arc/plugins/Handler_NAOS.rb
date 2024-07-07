#!/usr/bin/env ruby

# This class allows minarc to handle NAOS files:

=begin
"NAOS1_20220708T0047.tle"
"NS1_TEST_TM__GPS____20220706T000000_20220709T000000_0001.xml"
"NS1_OPER_CNF_CONT___20220706T000000_20220709T000000_0001.xml"
"NS1_OPER_ORB_OEM____20220709T000000_20220717T000000_0001.OEM"
"NS1_OPER_ORB_OPM____20220709T000000_20220709T000000_0001.OPM"
"NS1_OPER_ORB_SOERT__20220709T000000_20220717T000000_0001.OPM"
"NS1_OPER_PLA_GSP____20220709T000000_20220717T000000_0001.xml"
"NS1_OPER_PLA_MAINT__20220709T000000_20220717T000000_0001.xml"
"NS1_OPER_PLA_MAN____20220709T000000_20220717T000000_0001.xml"
"NS1_OPER_PLA_SBA____20220710T000000_20220717T000000_0001.xml"
"NS1_TEST_PLA_SBA____20220710T000000_20220717T000000_0001.tcl"
"NS1_TEST_CNF_OAT____20220709T004210_20220716T230832_0001.EEF"
"NS1_TEST_PLA_OSC____20220710T000000_20220715T000000_0001.xml"
"TRK_NAOS1_TG1_ANG_20221004000000.GEO" 
"TRK_NAOS1_TG1_RAN_20221004000000.GEO"
"TRK_NAOS1_TG2_ANG_20221004000000.GEO" 
"TRK_NAOS1_TG2_RAN_20221004000000.GEO"
"NS1_OPER_SCH_REQ____20220706T000000_20220709T000000_0001.XML"
=end

require 'filesize'
require 'cuc/Converters'

include CUC::Converters


class Handler_NAOS
   @type                = ""
   @filename            = ""
   @filename_original   = nil
   @validated           = false
   @start               = nil
   @stop                = nil 
   @generation_date     = nil
   @full_path_filename  = ""
   @size                = 0
   @size_in_disk        = 0

   attr_reader :archive_path, :size, :size_in_disk, :size_original, :type, :filename, :filename_original, :start, :stop, :str_start, :str_stop

   ## -----------------------------------------------------------

   ## Class constructor
   
   ## Name now must be a full_path one
   def initialize (name, destination = nil, args = {})
      
      @logger      = args[:logger]
      @isDebugMode = args[:isDebugMode]

      if @isDebugMode == true then
         @logger.debug("Handler_NAOS")
      end

      if name[0,1] != '/' then
         @bDecodeNameOnly = true
      else
         @bDecodeNameOnly = false
      end
      
      archRoot             = ENV['MINARC_ARCHIVE_ROOT']
      @filename            = File.basename(name, ".*")
      @filename_original   = File.basename(name)
      @archive_path        = ""
      @validated           = false

      # ----------------------------------------------------

      # NAOS1_20220708T0047.tle
      if File.extname(name) == ".tle" then
         begin
            @type             = "AUX_TLE___"
            @str_start        = "#{@filename.split('_')[1].slice(0, 13)}00"
            @str_stop         = @str_start
            @start            = self.str2date(@str_start)
            @stop             = @start
            @generation_date  = @start
            @validated        = true
         rescue Exception => e
            @logger.error(e.to_s)
            @logger.error(e.backtrace)
            @validated        = false
         end
      end

      # ----------------------------------------------------     
      
      # NS1_OPER_CNF_CONT___20220706T000000_20220709T000000_0001
      # NS1_OPER_PLA_SBA____20220710T000000_20220717T000000_0001.xml
      # NS1_TEST_PLA_SBA____20220710T000000_20220717T000000_0001.tcl

      if @filename.length == 56 then
         @str_start        = @filename.slice(20, 15)
         @str_stop         = @filename.slice(36, 15)      
         @type             = @filename.slice(9,10)         
         @start            = self.str2date(@filename.slice(20, 15))
         @generation_date  = @start
   
         if @filename.slice(36, 15) == "99999999T999999" then
            @stop = DateTime.new(2100,1,1)
         else
            @stop = self.str2date(@filename.slice(36, 15))
         end
         @validated        = true

         # TC sequences should have a different type than the source MTL plan
         if File.extname(name) == ".tcl" then
            @type             = @filename.slice(9,10).gsub("PLA", "TCL")
         end
      end

      # ----------------------------------------------------

      # TRK_NAOS1_TG1_ANG_20221004000000

      if @filename.length == 32 then
         
         if @filename.include?("ANG") == true then
            @type = "ADA_TDA___"
         end
         
         if @filename.include?("RAN") == true then
            @type = "ADA_DOP___"
         end
         @generation_date  = self.str2date(@filename.slice(18, 14))
         @start            = self.str2date(@filename.slice(18, 14))
         @stop             = self.str2date(@filename.slice(18, 14))
         @validated        = true
      end

      # ----------------------------------------------------
     
      # ----------------------------------------------------
      
      # S2__OPER_DEC_F_RECV_2BOA_20200205T183117_V20200205T183117_20200205T183117_SUPER_TCI.xml
      # S2__OPER_DEC_F_RECV_2BOA_20200205T183117_V20200205T183117_20200205T183117_S2PDGS.xml
      
      if @filename.length > 73 and @filename.slice(3,1) == "_" and @filename.slice(8,1) == "_" &&
         @filename.slice(19,1) == "_" and @filename.slice(24,1) == "_" and @filename.slice(40,1) == "_" &&
         @filename.slice(41,1) == "V" 
      then
         @str_start        = @filename.slice(42, 15)
         @str_stop         = @filename.slice(58, 15)      
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = self.str2date(@filename.slice(58, 15))         
         @validated        = true      
      end
      
      # ----------------------------------------------------
         
      if @validated == false then
         puts @filename.length
         puts "#{@filename} not supported by Handler_NAOS"
         puts
         exit(99)
      end

      # ----------------------------------------------------

      if @bDecodeNameOnly == true then
         return
      end

      # ----------------------------------------------------


      @archive_path  = "#{archRoot}/#{@type}/#{Date.today.strftime("%Y")}/#{Date.today.strftime("%m")}/#{Date.today.strftime("%d")}"

      @size_original = File.size(name)

      # TC sequences should have a different filename than the source MTL plan
      if File.extname(name) == ".tcl" then
         newname = name.gsub("_PLA_", "_TCL_")
         cmd = "mv -f #{name} #{newname}"
         if @isDebugMode == true then
            @logger.debug(cmd)
         end
         ret = system(cmd)
         
         if ret == false then
            @logger.error("Failed #{cmd}")
            raise "error renaming file: #{cmd}"
         end
         name = newname
      end

      if File.extname(name).downcase != ".zip" and 
         File.extname(name).downcase != ".tgz" and 
         File.extname(name).downcase != ".7z" then
         compressFile(name)
      else
         @full_path_filename  = name         
      end

      @size          = File.size(@full_path_filename)
      result         = `du -hs #{@full_path_filename}`
      
      begin
         @size_in_disk  = Filesize.from("#{result.split(" ")[0]}iB").to_int
      rescue Exception => e
         @size_in_disk  = 0
      end

#      if args[:bDeleteSource] == true then
#         File.delete(@full_path_filename)
#      end

   end

   # ------------------------------------------------------------

   def isValid
      return @validated
   end

   # ------------------------------------------------------------

   def fileType
      return @type
   end

   #-------------------------------------------------------------

   def start_as_dateTime
      return @start
   end

   #-------------------------------------------------------------

   def stop_as_dateTime
      return @stop
   end

   #-------------------------------------------------------------

   def generationDate
      return @generation_date
   end
   
   # ------------------------------------------------------------
   
   def fileName
      return @full_path_filename
   end
   # ------------------------------------------------------------


private

   ## -----------------------------------------------------------

   def compressFile(full_path_name)
      filename       = File.basename(full_path_name, ".*")
      full_path      = File.dirname(full_path_name)
      
      if File.exist?("#{full_path}/#{filename}.7z") == true then
         @full_path_filename  = "#{full_path}/#{filename}.7z"
         return
      end
      
      # Ubuntu  
      cmd = "7za a #{full_path}/#{filename}.7z #{full_path_name} > /dev/null"
      
      # MacOS       
      # cmd = "7za a #{full_path}/#{filename}.7z #{full_path_name} -sdel"
     
      ret = system(cmd)
      
      if ret == false then
         @logger.error("Fatal Error in Handler_NAOS::compressFile")
         puts "Fatal Error in Handler_NAOS::compressFile"
         puts
         puts cmd
         puts
         puts "Deleting eventual previous compressed file #{full_path}/#{filename}.7z"
         puts
         File.delete("#{full_path}/#{filename}.7z")
         exit(99)
      else
         File.delete(full_path_name)
      end
            
      @full_path_filename  = "#{full_path}/#{filename}.7z"
            
   end

   ## -----------------------------------------------------------
 
   def handleTCL(full_path_name)
   end
   ## -----------------------------------------------------------
   
end
