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

## This class allows minarc to handle video files
##
## .mp4
## .m2ts
## .wmv
## .mkv

require 'rubygems'
require 'mini_exiftool'
require 'exiftool'

require 'filesize'
require 'cuc/Converters'
require 'cuc/WrapperExifTool'
require 'arc/MINARC_DatabaseModel'

include CUC::Converters

class Handler_VIDEO
   
   attr_reader :archive_path, :size, :size_in_disk, :size_original, :type, :filename
   
   @type                = ""
   @filename            = ""
   @validated           = false
   @start               = nil
   @stop                = nil
   @generation_date     = nil
   @full_path_filename  = ""
   
   ## --------------------------------------------

   ## destination is used as suffix to the filename and the directory
   def initialize (full_path_name, destination = nil, args = {})
      full_path   = File.dirname(full_path_name)
      @filename   = File.basename(full_path_name)
      basename    = File.basename(full_path_name, ".*")
      extension   = File.extname(full_path_name).to_s.downcase
      rev         = nil
      duration    = nil
      tStart      = nil
      width       = nil
      height      = nil
                 
      ## ------------------------------------------
      ## Handle revised videos name
      ## Rx_20130730T174343.m2ts

      if extension != ".m2ts" and extension != ".mp4" and extension != ".wmv" and extension != ".mkv" then         
         puts "File extension #{extension} is not handled by #{self.class}::#{__method__.to_s}"
         exit(99)
      end
      ## ------------------------------------------      
      
      begin                
         # Change to local directory to avoid full path names with spaces
         # that makes fail MiniExiftool wrapper
                        
         mdata    = MiniExiftool.new full_path_name
         width    = mdata.image_width
         height   = mdata.image_height
         duration = mdata.duration

         if duration == nil then
            duration = mdata.play_duration
         end

         ## puts mdata.to_hash

         parser   = CUC::WrapperExifTool.new("\"#{full_path_name}\"", false)

         if (width == nil) then
            width = parser.width
         end

         if (height == nil) then
            height = parser.height
         end

         if (duration == nil) then
            duration = parser.duration
         end


            if width >= 720 and height <= 576 then
               @type  = "m2ts_sd"
               tStart = Time.new(1980)
               
               if extension == ".mkv" then
                  @type    = "mkv_sd"
                  tStart   = parser.date_time_original
               end
               
               if extension == ".m2ts" then
                  @type    = "m2ts_sd"
                  tStart   = parser.date_time_original
               end
               
               if extension == ".mp4" then
                  @type    = "mp4_sd"
                  tStart   = parser.create_date
               end

               if extension == ".wmv" then
                  @type    = "wmv_sd"
                  tStart   = parser.creation_date
               end

               
            else
               tStart   = nil
               
               if extension == ".m2ts" then
                  @type    = "m2ts"
                  tStart   = parser.date_time_original
               end
               
               if extension == ".mp4" then
                  @type    = "mp4"
                  tStart   = parser.create_date
               end

               if extension == ".wmv" then
                  @type    = "wmv"
                  tStart   = parser.creation_date
               end
               
               if extension == ".mkv" then
                  @type    = "mkv"
                  tStart   = parser.creation_date
               end

               
            end
      rescue MiniExiftool::Error => e
         puts "Error in MINARC::Handler_M2TS"
         $stderr.puts e.message
         exit(99)
      end  
   
      # Compute duration
      if duration.include?(":") == true then
         arr      = duration.split(":")
         duration = (arr[0].to_i * 3600 + arr[1].to_i * 60 + arr[2].to_i).to_s.rjust(6, '0')
      else
         duration = mdata.duration.to_i.to_s.rjust(6, '0')
      end
      
      arr         = tStart.to_s.gsub!("-", "").gsub!(":", "").split(" ")                  
      year        = arr[0].slice(0, 4)
      month       = arr[0].slice(4, 2)
      day         = arr[0].slice(6, 2)
      
      if destination != nil then
         @filename            = "#{arr[0]}T#{arr[1]}_#{duration}_#{destination}#{extension}" # .m2ts"
      else
         @filename            = "#{arr[0]}T#{arr[1]}_#{duration}#{extension}" # .m2ts"
      end
      @full_path_filename  = "#{full_path}/#{@filename}"

      # cmd         = "mv \"#{full_path_name}\" \"#{@full_path_filename}\""
      cmd         = "cp \"#{full_path_name}\" \"#{@full_path_filename}\""
      ret         = system(cmd)
         
      # ------------------------------------------
      
      tEnd        = tStart + duration.to_i      
      @start      = tStart
      @stop       = tEnd
      @generation_date  = @start
      @validated  = true
      
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @archive_path  = "#{archRoot}/#{@type}/#{year}/#{year}#{month}#{day}"
            
      @size          = File.size(@full_path_filename)
      @size_original = File.size(@full_path_filename)
      result         = `du -hs #{@full_path_filename}`
      
      begin
         @size_in_disk  = Filesize.from("#{result.split(" ")[0]}iB").to_int
      rescue Exception => e
         @size_in_disk  = 0
      end
      
      if destination != nil then
         if destination.slice(0,1) == "/" then
            @archive_path = destination
         else
            @archive_path = "#{archRoot}/#{@type}/#{year}#{month}#{day}_#{destination}"
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
