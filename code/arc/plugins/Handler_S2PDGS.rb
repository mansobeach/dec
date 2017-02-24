#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

# This class allows minarc to handle S2PDGS files:
#
# S2A_OPER_REP_OPDPC__SGS__20170214T113527_V20170214T080018_20170214T080336.EOF
# S2__OPER_REP_ARC____SGS__20170214T105715_V20170214T030309_20170214T031438_A008609_T50RKS.EOF
# S2A_OPER_MPL__NPPF__20170217T110000_20170304T140000_0001.TGZ

# S2A_OPER_REP_SUCINV_MPC__20150625T235026_20150624T232135_20150625T232135.ZIP

require 'filesize'

require 'cuc/Converters'

include CUC::Converters


class Handler_S2PDGS

   @type                = ""
   @filename            = ""
   @validated           = false
   @start               = nil
   @stop                = nil 
   @generation_date     = nil
   @full_path_filename  = ""
   @size                = 0
   @size_in_disk        = 0

   attr_reader :archive_path, :size, :size_in_disk

   #-------------------------------------------------------------

   # Class constructor
   
   # Name now must be a full_path one
   def initialize (name, destination = nil)
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @filename      = File.basename(name, ".*")
      @archive_path  = ""
      @validated     = false

      if @filename.length == 72 then
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(41, 15))
         @stop             = self.str2date(@filename.slice(57, 15))
         @validated        = true
      end 

      if @filename.length == 73 or @filename.length == 88 then
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = self.str2date(@filename.slice(58, 15))
         
#          puts @generation_date
#          puts @start
#          puts @stop
#          exit
       
         @validated        = true
      end 
         
      if @filename.length == 56 then
         @type             = @filename.slice(9,10)         
         @start            = self.str2date(@filename.slice(20, 15))
         @generation_date  = @start
         @stop             = self.str2date(@filename.slice(36, 15))
#          puts @generation_date
#          puts @start
#          puts @stop
#          exit       
         @validated        = true
      end          
         
      if @validated == false then
         puts @filename.length
         puts "#{@filename} not supported by Handler_S2PDGS !"
         puts
         exit(99)
      end

      @archive_path     = "#{archRoot}/#{@type}/#{Date.today.strftime("%Y")}/#{Date.today.strftime("%m")}/#{Date.today.strftime("%d")}"

      if File.extname(name).downcase != ".zip" then
         compressFile(name)
      else
         @full_path_filename  = name         
      end

      @size          = File.size(@full_path_filename)
      result         = `du -hs #{@full_path_filename}`
      @size_in_disk  = Filesize.from("#{result.split(" ")[0]}iB").to_int

   end

   #-------------------------------------------------------------

   def isValid
      return @validated
   end

   #-------------------------------------------------------------

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
   
   #-------------------------------------------------------------
   
   def fileName
      return @full_path_filename
   end
   #-------------------------------------------------------------


private

   #-------------------------------------------------------------

   def compressFile(full_path_name)
      filename       = File.basename(full_path_name, ".*")
      full_path      = File.dirname(full_path_name)
             
      cmd = "7za a #{full_path}/#{filename}.7z #{full_path_name} -sdel"
      # puts cmd
      ret = system(cmd)
      
      if ret == false then
         puts "Fatal Error in Handler_S2PDGS::compressFile"
         puts
         puts cmd
         puts
         exit(99)
      end
      
      @full_path_filename  = "#{full_path}/#{filename}.7z"
      
   end

   #-------------------------------------------------------------

   
end
