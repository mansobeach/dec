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

# This class allows minarc to handle picture jpeg files
# .jpg
# .jpeg


require 'rubygems'
require 'mini_exiftool'

require 'cuc/Converters'
require 'minarc/MINARC_DatabaseModel'

include CUC::Converters

class Handler_JPEG
   @type             = ""
   @filename         = ""
   @validated        = false
   @start            = nil
   @stop             = nil
   @generation_date  = nil
   @full_path_filename = ""
   
   attr_reader :archive_path

   #------------------------------------------------

   # Class constructor
   def initialize (full_path_name, destination = nil)
      full_path   = File.dirname(full_path_name)
      @filename   = File.basename(full_path_name)
      basename    = File.basename(full_path_name, ".*")
      extension   = File.extname(full_path_name).to_s.downcase
      tStart      = nil
      
      if extension != ".jpg" and extension != ".jpeg" then
         puts "Error in MINARC::Handler_JPEG"
         puts "@filename not supported by MINARC::Handler_JPEG"
         exit(99)
      end
      
      begin
         mdata    = MiniExiftool.new full_path_name
         tStart   = mdata.date_time_original
            # puts mdata.mime_type
      rescue MiniExiftool::Error => e
         puts "Error in MINARC::Handler_JPEG"
         $stderr.puts e.message
         exit(99)
      end  
            
      arr         = mdata.date_time_original.to_s.gsub!("-", "").gsub!(":", "").split(" ")
      year        = arr[0].slice(0, 4)
      prevName    = @filename
      @filename   = "#{arr[0]}T#{arr[1]}#{extension}"
      
      # ------------------------------------------
      # Check whether such file has been previously archived      
      
      aFile = ArchivedFile.find_by_filename(@filename)
      
      if aFile != nil then
         puts "File #{prevName} is already archived with name #{@filename}"
         puts
         exit(1)
      end
      
      # ------------------------------------------
      
      
      @full_path_filename = "#{full_path}/#{@filename}"

      # ------------------------------------------
      # Rename File      
      cmd         = "mv \"#{full_path_name}\" \"#{@full_path_filename}\""
      
      # or
      
      # Copy File    
      cmd         = "cp \"#{full_path_name}\" \"#{@full_path_filename}\""
      
#       puts
#       puts cmd
#       puts
      ret         = system(cmd)
      # ------------------------------------------
      
      @start            = tStart
      @stop             = @start
      @generation_date  = @start
      @type             = "jpeg"
      @validated        = true

      # ---------------------------------------

      
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @archive_path  = "#{archRoot}/#{@type}/#{year}"
      
      
      if destination != nil then
         if destination.slice(0,1) == "/" then
            @archive_path = destination
         else
            @archive_path = "#{@archive_path}/#{arr[0].slice(0,8)}_#{destination}"
         end
      end
            
   end

   #------------------------------------------------

   #------------------------------------------------

   def isValid
      return @validated
   end
   #------------------------------------------------

   def fileType
      return @type
   end
   #------------------------------------------------

   def start_as_dateTime
      return @start
   end
   #------------------------------------------------

   def stop_as_dateTime
      return @stop
   end
   #------------------------------------------------

   def generationDate
      return @generation_date
   end
   #------------------------------------------------
   
   def fileName
      return @full_path_filename
   end
   #------------------------------------------------
end
