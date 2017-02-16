#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool driver to archive all files
#
# == Usage
#   driver_archiveVideo.rb -d <directory>
#     --directory             Directory to archive
#     --help                  shows this help
#     --Debug                 shows Debug info during the execution
#     --version               shows version number      
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale & Beach
#

require 'rubygems'
require 'mini_exiftool'
require 'getoptlong'
require 'rdoc'
require 'arc/MINARC_DatabaseModel'

# MAIN script function
def main

   #=======================================================================

   def SIGTERMHandler
      puts "\n[#{File.basename($0)} SIGTERM signal received ... sayonara, baby !\n"
      exit(0)
   end
   #=======================================================================

   
   @isDebugMode      = false 
   @directory        = ""
   @bIsSilent        = false
   @isMoveMode       = false
   
   opts = GetoptLong.new(
     ["--directory", "-d",      GetoptLong::REQUIRED_ARGUMENT],
     ["--excel", "-e",          GetoptLong::REQUIRED_ARGUMENT],
     ["--prefix", "-p",         GetoptLong::REQUIRED_ARGUMENT],
     ["--filename", "-f",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Move", "-M",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--silent", "-s",         GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode  = true
            when "--Move"    then @isMoveMode   = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--directory" then
                  @directory = arg
            when "--prefix" then
                  @prefixName = arg
            when "--filename" then
                  @outputFilename = arg
            when "--silent"    then 
                  @bIsSilent = true 
            when "--usage"   then usage
            when "--help"    then usage                         
         end
      end
   rescue Exception
      exit(99)
   end


   if @directory == "" then
      usage
   end
   
   puts @directory
      
   if File.exist?(@directory) == false then
      puts "#{@directory} not found !"
      exit(99)
   end

   if File.directory?(@directory) == false then
      puts "#{@directory} is not a directory !"
      exit(99)
   end


   prevDir = Dir.pwd

   Dir.chdir(@directory)

   @archiveRoot = ENV['MINARC_ARCHIVE_ROOT']
  
   processDirectory

   Dir.chdir(prevDir)
   
   exit(0)

end

#---------------------------------------------------------------------

#---------------------------------------------------------------------

def computeRootPath
  
   rootpath    = @directory.split("/").last  #.gsub!(" ", "_")
   prevpath    = rootpath
  
   rootpath    = rootpath.dup.gsub("---R", "REVISADO").downcase
   prevpath    = rootpath
   
   puts rootpath
   puts rootpath.dup
   
   rootpath    = rootpath.dup.gsub!(/\d+/, "")
   
   if rootpath == nil then
      rootpath = prevpath
   else
      prevpath    = rootpath
   end
   
   rootpath    = rootpath.dup.gsub!(/[()-]/, "")
 
   if rootpath == nil then
      rootpath = prevpath
   else
      prevpath    = rootpath
   end

   arr         = rootpath.split(" ")
   str         = ""
   arr.each{|x| 
      str = "#{str}_#{x}"
   }
   rootpath    = str.slice(1, str.length)
   return rootpath
end

#---------------------------------------------------------------------

def processDirectory
   arr = Dir['*']

   arr.each{|element|
   
      puts "========================================"
      puts element
   
      if element == "Thumbs.db" then
         puts "skipping file #{element}"
         next
      end
   
      if File.directory?(element) == true then
         puts "skipping directory #{element}"
         next
      end

      basename    = File.basename(element, ".*")
      extension   = File.extname(element).to_s.downcase
      ext         = File.extname(element).to_s.downcase.gsub!('.', '')
      rootpath    = computeRootPath
      newname     = nil
      

      # ----------------------------------------------------
      # Handle m2ts "revised" files with name such as:
      # 20130730174343 (1).m2ts
      #
      # It is verified that it is already archived the original file 
      # 20130730T174343_xxxxxx.m2ts

      if ext == "m2ts" and basename.include?("(") == true then
         originalName   = basename.split("(")[0]
         rev            = basename.split("(")[1].slice(0,1)
         searchKey      = "%#{originalName.slice(0,8)}T#{originalName.slice(8,6)}%"
         
#          aFile = ArchivedFile.where('filename LIKE ?', searchKey).load
#          
#          if aFile.first == nil then
#             puts "No m2ts file archived with name #{searchKey}"
#             next
#          end
         
         # Handle new name
         # Rx_20130730T174343.m2ts
         
         newname  = "R#{rev}_#{originalName.slice(0,8)}T#{originalName.slice(8,6)}.m2ts"
         basename = "R#{rev}_#{originalName.slice(0,8)}T#{originalName.slice(8,6)}"
         
         cmd = "mv \"#{element}\" #{newname}"
         puts cmd
         system(cmd)
                  
      end

      # ----------------------------------------------------

      # next

      # ------------------------------------------
      #
      # Rename to avoid evil characters in the filename
      kk          = basename.dup.gsub!(/\d+/, "")
            
      if kk.length > 0 and basename.include?("T") == false and newname == nil and ext.downcase != "jpg" then
         tmp         = "#{element.dup.match(/\d+/)}"
         newname     = "#{tmp.slice(0,8)}T#{tmp.slice(8,6)}#{extension}"
         cmd         = "mv \"#{element}\" #{newname}"
         puts cmd
         system(cmd)
      else
         newname = element
      end
      # ------------------------------------------   

      # next

      # ----------------------------------------------------
      # AVI files with name *.avi
      if ext == "avi" then
         cmd = "minArcStore2.rb -f \"#{@directory}/#{newname}\" -t AVI -L #{rootpath} -D -m"
         puts cmd
         system(cmd)
         next
      end
      # ----------------------------------------------------

   
      # ----------------------------------------------------
      # JPEG files with name DSC01256.JPG
      if ext == "jpg" or ext == "jpeg" then
         # cmd = "minArcStore2.rb -f #{@directory}/#{element} -t JPEG -L #{rootpath} -D -m"
         cmd = "minArcStore2.rb -f \"#{@directory}/#{newname}\" -t JPEG -L #{rootpath}"
         
         if @isMoveMode == true then
            cmd = "#{cmd} -m"
         end

         if @isDebugMode == true then
            cmd = "#{cmd} -D"
         end
         
         puts cmd
         system(cmd)
         next
      end
      # ----------------------------------------------------
      
      
   
      basename    = File.basename(newname, ".*")
         
        
      if ext != "m2ts" then
         m2tsname = nil
         if basename.include?("T")== false then
            # Query on hh:mm:sX
            m2tsname = "#{basename.slice(0,8)}T#{basename.slice(8,5)}"
         else
            m2tsname = basename.slice(0,14)
         end
         # aFile = ArchivedFile.find_by_filename("#{basename}.m2ts")
         
         puts "query: %#{m2tsname}%.m2ts"
         
         # aFile = ArchivedFile.where("filename LIKE :prefix", prefix: "%#{m2tsname}%").load
         
         aFile = ArchivedFile.where('filename LIKE ?', "%#{m2tsname}%m2ts").load 
         
         if aFile.first == nil then
            puts "No m2ts file archived with name #{m2tsname}"
            next
         end
         
         # -------------------------------------------------
         # Rename file to match m2ts name
         
         puts aFile.first.filename
         
         renewname = "#{File.basename(aFile.first.filename, ".*")}#{extension}"
         cmd = "mv #{newname} #{renewname}"
         puts cmd
         system(cmd)
         # -------------------------------------------------
         # ------------------------------------------
         # Finally archive @ MINARC
      
         rootpath = "#{@archiveRoot}/m2ts/#{renewname.slice(0, 4)}/#{renewname.slice(0, 8)}_#{rootpath}"
      
         cmd = "minArcStore2.rb -f \"#{@directory}/#{renewname}\" -t M2TS -L #{rootpath} -D -m"
         puts cmd
         system(cmd)
         # ------------------------------------------

         
      else
         # ---------------------------------------
         # Process m2ts metadata
         
         begin
            mdata = MiniExiftool.new element
            arr   = mdata.date_time_original.to_s.gsub!("-", "").gsub!(":", "").split(" ")      
            date  = arr[0].slice(0, 8)
            # puts date
            rootpath = "#{@archiveRoot}/#{ext}/#{arr[0].slice(0, 4)}/#{date}_#{rootpath}"
         
            # puts mdata.duration
            # puts mdata.mime_type
         rescue MiniExiftool::Error => e
            rootpath = "#{@archiveRoot}/#{ext}/#{arr[0].slice(0, 4)}/#{arr[0].slice(0, 8)}_#{rootpath}"
#          $stderr.puts e.message
#          next
         end
         # ---------------------------------------
      
         # ------------------------------------------
         # Finally archive @ MINARC
      
         cmd = "minArcStore2.rb -f \"#{@directory}/#{newname}\" -t M2TS -L #{rootpath} -D -m"
         puts cmd
         system(cmd)
         # ------------------------------------------
      
         exit
      
      end
      
   }

end
#-------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}` 
   system("head -19 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------

#---------------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
