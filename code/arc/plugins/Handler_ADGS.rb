#!/usr/bin/env ruby

#########################################################################
###
### ===
###
### === Written by Elecnor Deimos
###
### === Elecnor Deimos
###
###
###
#########################################################################

# This class allows minarc to handle ADGS files:

=begin
> S2__OPER_AUX_UT1UTC_PDMC_20240513T000000_V20170101T000000_21000101T000000.txt
> NOAA Ice Mapping System => ims2024133_4km_v1.3.nc.gz
=end

require 'filesize'
require 'date'

require 'cuc/Converters'

include CUC::Converters

class Handler_ADGS
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
         @logger.debug("Handler_ADGS")
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

      # ----------------------------------------------------
      #
      # ims2024133_4km_v1.3.nc

      if @filename.length == 22 or @filename.length == 25 then
         @start            = DateTime.strptime(@filename.slice(3,7),"%Y%j")
         @stop             = DateTime.strptime(@filename.slice(3,7),"%Y%j")
         @type             = "NOAAIMS4KM"
         @generation_date  = @start
         @validated        = true
      end

      # ----------------------------------------------------


      # ----------------------------------------------------

      # S2__OPER_AUX_UT1UTC_PDMC_20240513T000000_V20170101T000000_21000101T000000.txt

      if @filename.length >= 73 and @filename.slice(3,1) == "_" and @filename.slice(8,1) == "_" &&
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
         puts "#{@filename} not supported by Handler_ADGS"
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


      if File.extname(name).downcase != ".zip" and
         File.extname(name).downcase != ".tgz" and
         File.extname(name).downcase != ".gz" and
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

      # @logger.debug("[ARC_XXX] Handler_ADGS::compressFile full_path : #{full_path}")
      # @logger.debug("[ARC_XXX] Handler_ADGS::compressFile filename  : #{filename}")

      if File.exist?("#{full_path}/#{filename}.7z") == true then
         @full_path_filename  = "#{full_path}/#{filename}.7z"
         return
      end

      # Ubuntu
      cmd = "7z a #{full_path}/#{filename}.7z #{full_path_name} > /dev/null"

      # MacOS
      # cmd = "7za a #{full_path}/#{filename}.7z #{full_path_name} -sdel"

      ret = system(cmd)

      if ret == false then
         @logger.error("[ARC_XXX]] Fatal Error in Handler_ADGS::compressFile")
         @logger.error("#{cmd}")
         puts "Fatal Error in Handler_ADGS::compressFile"
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


   ## -----------------------------------------------------------

end
