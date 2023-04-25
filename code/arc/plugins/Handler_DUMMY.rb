#!/usr/bin/env ruby

#########################################################################
###
### ===       
###
### === Written by Borja Lopez Fernandez
###
### === Elecnor Deimos
### 
###
###
#########################################################################

# This class allows minarc to test minARC with whatever files:

=begin
=end

require 'filesize'

require 'cuc/Converters'

include CUC::Converters


class Handler_DUMMY

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
         @logger.debug("Handler_DUMMY")
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

      @type             = "TYPE_DUMMY"
      @start            = DateTime.new(2100,1,1)
      @str_start        = "21000101T000000"
      @stop             = DateTime.new(2100,1,1)
      @str_stop         = "21000101T000000"
      @generation_date  = DateTime.new(2100,1,1)
      @validated        = true

 
      # ----------------------------------------------------
         
      if @validated == false then
         puts @filename.length
         puts "#{@filename} not supported by Handler_DUMMY"
         puts
         exit(99)
      end

      # ----------------------------------------------------

      # ----------------------------------------------------

      if @isDebugMode == true  then
         @logger.debug("name                 => #{name}")
         @logger.debug("type                 => #{@type}")
         @logger.debug("start                => #{@start}")
         @logger.debug("stop                 => #{@stop}")
         @logger.debug("generation_date      => #{@generation_date}")
      end

      if @bDecodeNameOnly == true then
         return
      end

      @archive_path  = "#{archRoot}/#{@type}/#{Date.today.strftime("%Y")}/#{Date.today.strftime("%m")}/#{Date.today.strftime("%d")}"
      @size_original = File.size(name)

      # ----------------------------------------------------

      if @isDebugMode == true  then
         @logger.debug("archive_path         => #{@archive_path}")
         @logger.debug("size_original        => #{@size_original}")
      end

      # ----------------------------------------------------

      

      # ----------------------------------------------------

      compressFile(name)

      @size          = File.size(@full_path_filename)
      result         = `du -hs #{@full_path_filename}`
      
      begin
         @size_in_disk  = Filesize.from("#{result.split(" ")[0]}iB").to_int
      rescue Exception => e
         @size_in_disk  = 0
      end

      # ----------------------------------------------------

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

   # ------------------------------------------------------------

   def stop_as_dateTime
      return @stop
   end

   # -------------------------------------------------------------

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
         @logger.error("Fatal Error in Handler_DUMMY::compressFile")
         puts "Fatal Error in Handler_DUMMY::compressFile"
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
 
end
