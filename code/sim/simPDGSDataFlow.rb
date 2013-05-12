#!/usr/bin/env ruby

#########################################################################
#
# simPDGSDataFlow
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#
#########################################################################

# It simulates the data flow of all the different I/Fs

require 'fileutils'
require 'csv'
require 'getoptlong'

require 'dcc/ReadInTrayConfig'
require 'cuc/EE_ReadFileName'
require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileSource'
require 'cuc/DirUtils'

#===============================================================================

@@simTimeFactor = 1.0

def main
   
   include CUC::DirUtils
   include FileUtils
   
   @simTime = 0
   
   opts = GetoptLong.new(
      ["--simtime", "-s",          GetoptLong::REQUIRED_ARGUMENT]
      )

   begin
      opts.each do |opt, arg|
         case opt
	         when "--simtime"    then @simTime = arg.to_i
         end
      end
   rescue Exception
      exit(99)
   end
   
   if @simTime == 0 then
      puts "required argument -s [time] -> Simulation Time in seconds"
      exit(99)
   end
      
   init
   
   cmd = "rmInterfaceFile.rb"
   system(cmd)

   cmd = "rmInTrayFiles.rb"
   system(cmd)
   
   cmd = "initDCCInventory.rb"
   system(cmd)
   
   simDataFlow
   

end
#===============================================================================

def init
   
   bDefined = true
   
   if !ENV['FTPROOT'] then
      puts "\nFTPROOT environment variable not defined !  :-(\n\n"
      bCheckOK = false
      bDefined = false
   end

   if !ENV['DIMROOT'] then
      puts "\nDIMROOT environment variable not defined !  :-(\n\n"
      bCheckOK = false
      bDefined = false
   end

   if !ENV['DCC_TEST'] then
      puts "\nDCC_TEST environment variable not defined !  :-(\n\n"
      bCheckOK = false
      bDefined = false
   end

   if bDefined == false then
      exit(99)
   end

   if !ENV['DCC_CONFIG'] then
      puts "\DCC_CONFIG environment variable not defined !  :-(\n\n"
      exit(99)
   end
   

   @configDir = ENV['DCC_CONFIG']


   @dimRoot = ENV['DIMROOT']
   @ftpRoot = ENV['FTPROOT']
   @srcRoot = ENV['SRCROOT']
   @testDir = ENV['DCC_TEST']
   
   @configInTray     = DCC::ReadInTrayConfig.instance
   @entityConfig     = CTC::ReadInterfaceConfig.instance
   @configFileSource = CTC::ReadFileSource.instance
   
   cmd = "filesToBeProcessed.rb"   
   system(cmd)

   @ftReadConf = CTC::ReadInterfaceConfig.instance

	Struct.new("FileType2EntityTiming", :fileType, :entity, :deltaTime)
   Struct.new("FileToBeAvailable", :fileName, :srcDir, :targetDir, :deltaTime)

   @arrTypesTiming = Array.new
   @arrFiles2BeAvailable = Array.new

   # Crosscheck between files_to_be_ingested and filetypes_timing_simulation
   CSV.open("#{@configDir}/filetypes_timing_simulation.csv", "r") do |row|
      type   = row[0].to_s
#       if type.slice(0,1) == "#" then
#          type = type.slice(1, type.length)
#       end
      entity = row[1].to_s
      delta  = row[2].to_i
      strct  = Struct::FileType2EntityTiming.new(type, entity, delta)
      @arrTypesTiming << strct
   end

   #############################################################################
   #  Time considered as T0
   #
   t0 = Time.utc(2008,"aug",19)

   arrSrcLines = IO.readlines("#{@configDir}/files_to_be_ingested")
      
   # --------------------------------------
   
   # For each entry in "files_to_be_ingested", it is checked whether there is an entry in
   # "filetypes_timing_simulation", and in afirmative case an entry is added to the array
   # @arrFiles2BeAvailable
      
   arrSrcLines.each{|line|
      if line.chop != "" then
         fileName = line.split(" ")[0]
         fileType = CUC::EE_ReadFileName.new(fileName).fileType
         dStart   = CUC::EE_ReadFileName.new(fileName).dateStart
         dStop    = CUC::EE_ReadFileName.new(fileName).dateStop
                 
         srcDir   = line.split(" ")[1]
         
         puts fileName

         bIsEE    = true

         if CUC::EE_ReadFileName.new(fileName).isEarthExplorerFile? == false then
            bIsEE    = false
            sources  = @configFileSource.getEntitiesSendingIncomingFileName(fileName)
         end


         @arrTypesTiming.each{|element|
                        
            # Add an entry
            if element[:fileType] == fileType then
            
               if bIsEE == false then
                  bFound = false
                  sources.each{|interface|
                     if element[:entity] == interface then
                        bFound = true
                     end
                  }
                  if bFound == false then
                     next
                  end
               end

               puts "#{fileName} - #{element[:entity]}"
               
               arrKK     = @ftReadConf.getAllDownloadDirs(element[:entity])
               targetDir = arrKK[0][:directory]
               
               delta     = 0
               
               # If deltaTime is negative means that the mission-file should be available before its start time.
               # When deltaTime is positive, the mission-file (usually products) should be available after its end time.
               if element[:deltaTime] < 0 then
                  delta = dStart.to_i - t0.to_i
               else
                  delta = dStop.to_i - t0.to_i
               end
            
               deltaTime = element[:deltaTime] + delta
            
               strct = Struct::FileToBeAvailable.new(fileName,
                                                     srcDir,
                                                     targetDir,
                                                     deltaTime)
                                                     
               @arrFiles2BeAvailable << strct
            
            end

         }
         

      end
   }

   @arrFiles2BeAvailable = @arrFiles2BeAvailable.uniq
   
   # Sort by Delta Time
   @arrFiles2BeAvailable = @arrFiles2BeAvailable.sort{|x,y|
      x[:deltaTime] <=> y[:deltaTime]
   }
   

end

#===============================================================================

#===============================================================================

def simDataFlow

   totalInterval = @arrFiles2BeAvailable[0][:deltaTime].abs + @arrFiles2BeAvailable[-1][:deltaTime].abs
   
   @thresholdDelta = 100000
   
   # 3 days
   factorTime    = @simTime / 259200.0
   
   prevIncr      = @arrFiles2BeAvailable[0][:deltaTime] * factorTime
   incr          = @arrFiles2BeAvailable[0][:deltaTime] * factorTime
   prevIncr      = prevIncr.to_i
   incr          = incr.to_i
   
   #puts prevIncr
   
   if FileTest.exist?("#{@configDir}/simPDGS.cfg") == true then
      File.delete("#{@configDir}/simPDGS.cfg")
   end
   
   outFile = File.new("#{@configDir}/simPDGS.cfg", "w")
   
   
   bFirst = true


   currentDir = Dir.pwd

   Dir.chdir(ENV['HOME'])

   @arrFiles2BeAvailable.each{|element|
      checkDirectory(element[:targetDir])
      # Copy the file 
      src = "#{element[:srcDir]}/#{element[:fileName]}"
      cmd = "\\cp -f #{element[:srcDir]}/#{element[:fileName]} #{element[:targetDir]}"
      system(cmd) 
      puts "#{element[:fileName]} - to #{element[:targetDir]} - #{element[:deltaTime]}"
      
      outFile.puts "#{element[:fileName]} - to #{element[:targetDir]} - #{element[:deltaTime]}"
      outFile.flush
      
      if element[:deltaTime].abs < @thresholdDelta then
         incr = element[:deltaTime] * factorTime
         incr = incr.to_i
         
         realIncr = incr - prevIncr
         realIncr = realIncr.to_i.abs
         prevIncr = incr
         if bFirst == true then
            bFirst = false
         else
            puts "Waiting #{realIncr} sec"
            sleep(realIncr)
         end
      else
         prevIncr = 86400 * factorTime
      end
      
   }

   Dir.chdir(currentDir)

   outFile.close
end
#===============================================================================


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
