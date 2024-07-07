#!/usr/bin/env ruby

# This class allows minarc to handle video mp4 files:
# .mp4


require 'rubygems'
require 'mini_exiftool'
require 'exiftool'

require 'cuc/Converters'
require 'cuc/WrapperExifTool'
require 'arc/MINARC_DatabaseModel'

include CUC::Converters

class Handler_MP4
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
   def initialize (full_path_name, destination = nil, args = {})
      full_path   = File.dirname(full_path_name)
      @filename   = File.basename(full_path_name)
      basename    = File.basename(full_path_name, ".*")
      extension   = File.extname(full_path_name).to_s.downcase
      duration    = nil
      tStart      = nil
      
      if extension == ".mp4" then            
         begin
                        
            mdata    = MiniExiftool.new full_path_name
                        
            parser   = CUC::WrapperExifTool.new(full_path_name, false)
            tStart   = parser.date_time_original
            duration = mdata.duration
            # puts mdata.mime_type
         rescue MiniExiftool::Error => e
            puts "Error in MINARC::Handler_MP4"
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
         @filename   = "#{arr[0]}T#{arr[1]}_#{duration}#{extension}" # 
         year        = arr[0].slice(0, 4)
         month       = arr[0].slice(4, 2)
         day         = arr[0].slice(6, 2)
         
         @full_path_filename = "#{full_path}/#{@filename}"

         # ------------------------------------------
         # Rename File      
         cmd         = "mv #{full_path_name} #{@full_path_filename}" 
         ret         = system(cmd)
         
         # ------------------------------------------
      
         tEnd        = tStart + duration.to_i      
         @start      = tStart
         @stop       = tEnd
         @generation_date  = @start
         @type       = "mp4"
         @validated  = true

      else
         @validated           = false
      end
      
      archRoot       = ENV['MINARC_ARCHIVE_ROOT']
      @archive_path  = "#{archRoot}/#{@type}/#{year}"
      
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
