#!/usr/bin/env ruby

#########################################################################
#
# kakita
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#
#########################################################################


require 'csv'
require 'getoptlong'
require 'fileutils'

require 'cuc/DirUtils'
require 'cuc/EE_ReadFileName'
require 'ctc/ReadFileSource'
require 'ctc/ReadInterfaceConfig'
require 'dcc/ReadInTrayConfig'

#===============================================================================


def main
      
   include CUC::DirUtils
   

   @bCheck    = false

   opts = GetoptLong.new(
      ["--check", "-c",          GetoptLong::NO_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt
	         when "--check"    then @bCheck    = true
         end
      end
   rescue Exception
      exit(99)
   end    
   
   if !ENV['DCC_CONFIG'] then
      puts "\DCC_CONFIG environment variable not defined !  :-(\n\n"
      exit(99)
   end
   

   @configDir = ENV['DCC_CONFIG']

   @configInTray     = DCC::ReadInTrayConfig.instance
   @configFileSource = CTC::ReadFileSource.instance
   @configInterface  = CTC::ReadInterfaceConfig.instance

   arrDIMs = @configInTray.getAllDIMs

   arrSrcFiles = Array.new

   arrDIMs.each{|aDIM|
      puts "Processing InTray - #{aDIM}"
      aDir = @configInTray.getDIMInTray(aDIM)
      aDir = "#{aDir}/source"
      checkDirectory(aDir)
      puts aDir
      arr = Array.new
      arr = processDir(aDir)
      if arr != false then
         arrSrcFiles << arr
      end
   }

   puts arrSrcFiles

   if File.exist?("#{@configDir}/files_to_be_ingested") == true then
      File.delete("#{@configDir}/files_to_be_ingested")   
   end
   
   puts
   puts "Creating #{@configDir}/files_to_be_ingested list file"
   puts

   srcFile  = File.new("#{@configDir}/files_to_be_ingested", "w+")
   arrSrcFiles.each{|file|
      srcFile.puts(file)
      srcFile.flush
   }
   srcFile.close

   arrTypes    = Array.new

   arrSrcLines = IO.readlines("#{@configDir}/files_to_be_ingested")
   
   arrSrcLines.each{|line|
   
      if line.chop != "" then
         fileType = CUC::EE_ReadFileName.new(line.split(" ")[0]).fileType
         if arrTypes.include?(fileType) == false then
            if fileType != nil then
               arrTypes << fileType
            end
         end
      end      
   }
   
   fileSource  = CTC::ReadFileSource.instance
   
   arrTypes.each{|type|
      arrEntities = fileSource.getEntitiesSendingIncomingFile(type)
      if arrEntities == nil then
         puts "\n#{type} Type is not registered in ft_incoming_files.xml ! \n"
#         exit(99)
      end
#       arrEntities.each{|entity|
#          targetFile.print type, ",", entity, ",", "0", "\n"
#          targetFile.flush
#       }
   }

#   targetFile.close
   
   arrSimTypes = Array.new
   # Crosscheck between files_to_be_ingested and filetypes_timing_simulation
   CSV.open("#{@configDir}/filetypes_timing_simulation.csv", "r") do |row|
      type = row[0].to_s
      if type.slice(0,1) == "#" then
         type = type.slice(1, type.length)
      end
      arrSimTypes << type
   end
   arrSimTypes = arrSimTypes.uniq
   
   arrTypes.each{|type|
      if arrSimTypes.include?(type) == false then
         puts "#{type} was not included in filetypes_timing_simulation.csv"
         exit(99)
      end
   }


end
#===============================================================================

def processDir(aDirectory)
   prevDir = Dir.pwd

   begin
      Dir.chdir(aDirectory)
   rescue Exception => e
      puts "bye #{aDirectory}"
      return false
   end

#   `mv -f ../AE* .`
   cmd = "mv -f ../AE* ."
   system(cmd)

   arrSrcFiles = Array.new
   arrFiles = Dir["AE*"]

   arrFiles.each{|aFile|
      
      if File.directory?(aFile) == true then
         next
      end

      bFound = false

      arrSrcFiles.each{|element|
         if element.split(" ")[0] == aFile then
            bFound = true
            break
         end
      }
         
      if bFound == false then
         arrSrcFiles << "#{aFile} #{aDirectory}"
      end

   }

   Dir.chdir(prevDir)

   return arrSrcFiles
end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
