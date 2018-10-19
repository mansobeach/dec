#!/usr/bin/env ruby
#
# == Synopsis
#
# This is a RPF command line tool that delivers within a ROP or in Emergency Mode
# the FILE_IDs provided.
#
# -R <nROP> flag:
#
# With this option all files sent are marked as sent with that ROP ID.
# This flag does not allow set up the Emergency flag "-E".
#
# -E flag:
#
# With this option all files sent are not registered in the Inventory.
# This delivery is set as Emergency Mode hence out of the nominal loop flow.
# This flag does not allow set up ROP delivery flag "-R <nROP>".
#
# == Usage
# sendROPFiles.rb -i "FILE_ID_1 .. FILE_ID_n"  -R <nROP> | -E
#   --ROP <nROP> Registers delivered files as delivered within such ROP
#   --E          Emergency Flag transfer
#   --help       shows this help
#   --usage      shows the usage
#   --Debug      shows Debug info during the execution
#   --version    shows version number
#
#
# == Author
# Deimos-Space S.L. (bolf)
#
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Ruby script sendROPFiles for sending specified files
# 
# === Written by DEIMOS Space S.L.   (bolf)
#
# === Data Exchange Component -> Mission Management & Planning Facility
# 
# CVS: $Id: sendROPFiles.rb,v 1.15 2018/09/10 13:32:36 rolp Exp $
#
#########################################################################

require 'getoptlong'

require 'cuc/Log4rLoggerFactory'
require 'cuc/DirUtils'
require 'cuc/CommandLauncher'
require 'cuc/CheckerProcessUniqueness'
require 'rpf/ROPSender'
require 'dec/DEC_DatabaseModel'
require 'dec/DEC_Environment'

@isDebugMode      = false

# MAIN script function
def main

   #=======================================================================

   def SIGTERMHandler
      puts "\n[#{File.basename($0)}] SIGTERM signal received ... sayonara, baby !\n"
      puts
      cmd = %Q{decDeliverFiles -K}
      puts cmd
      bRet = system(cmd)
      if @bUnblock == true
         @ropSender.unlockFTActions
      end
      @locker.release
      exit(0)
   end
   #=======================================================================

   include           CUC::DirUtils
   include           CUC::CommandLauncher
   include           DEC

   @isDebugMode        = false
   @isVerboseMode      = false
   @bJustList          = false
   @nROP               = 0
   # Flag for updating the database for Transfer purposes.
   # This flag is disabled in Transfers in Emergency mode.
   @bROPChecks          = true
   @listIDs             = nil
   @bUnblock            = true 
   @bUsage              = false
   @bShowVersion        = false

   
   opts = GetoptLong.new(
     ["--ROP", "-R",            GetoptLong::REQUIRED_ARGUMENT],
     ["--ids", "-i",            GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--list", "-l",           GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--Emergency", "-E",      GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt      
            when "--Debug"       then     @isDebugMode      = true
            when "--version"     then     @bShowVersion     = true
            when "--list"        then     @bJustList        = true
            when "--help"        then     @bUsage           = true
            when "--usage"       then     @bUsage           = true
            when "--ROP"         then     @nROP             = arg.to_s
            when "--Emergency"   then     @bROPChecks       = false
            when "--Verbose"     then     @isVerboseMode    = true
	         when "--ids"         then     @listIDs          = arg         
         end
      end
   rescue Exception
      exit(99)
   end

   if @bShowVersion == true then
      print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " Version: [#{DEC.class_variable_get(:@@version)}]", "\n\n")
      hRecord = DEC.class_variable_get(:@@change_record)
      hRecord.each_pair{|key, value|
         puts "#{key} => #{value}"
      }      
      exit(0)
   end
   
   if @bUsage then
      usage
      exit(0)
   end

   if @listIDs == nil and @nROP == 0 then
      usage
      exit(99)
   end

   if self.checkEnvironmentEssential == false then
      self.printEnvironmentError
      puts
      exit(99)
   end

   if self.checkEnvironmentEssential == false then
      self.printEnvironmentError
      puts
      exit(99)
   end

   if self.checkEnvironmentRPF == false then
      puts
      self.printEnvironmentError
      puts
      puts
      self.print_environmentRPF
      puts      
      exit(99)   
   end

    
   old_stdout = $stdout
   
   t = Time.now
   ms = t.to_f.to_s.split(".").last[0..2]
   stdoutFile ="/tmp/sendRopLog_" + t.strftime("%Y%m%dT%H%M%S.#{ms}")

   File.open("#{stdoutFile}", 'w') do |fo|
   $stdout = fo
  
   if @nROP == 0 and @bROPChecks == true then
      usage
      exit(99)
   end

   if @nROP != 0 and @bROPChecks == false then
      usage
      exit(99)
   end

   checkModuleIntegrity

   # Register a handler for SIGTERM
   trap 15,proc{ self.SIGTERMHandler }   
   
#   # Set sendROP running. This assures there is only one sendROP / sendROPFiles running  
#    @locker = CUC::CheckerProcessUniqueness.new("sendROP.rb", nil, true)
#       
#    if @locker.isRunning == true then
#       puts "\n#{File.basename($0)} / sendROP.rb is already running !\n\n"
#       exit(99)
#    end
#   
#    # Register in lock file the process
#    @locker.setRunning

   # If it is a set of files within the ROP to be transferred
   # Check whether the ROP is transferable

   @ropSender = RPF::ROPSender.instance

#   @ropSender.unlockFTActions

   if @bROPChecks == true then

      ret = @ropSender.isTransferableROP?(@nROP)
      
      if ret == false then
         puts "\nROP #{@nROP} is not Transferable  !    :-O\n\n"
         exit(99)
      end

      # Check whether the files belong to such specified ROP     
      if @listIDs != nil then
         arrIDs = @listIDs.split(" ")
         bFound = true

         arrIDs.each{|element|
                  
            aROPFile = InventoryROPFile.where(ROP_ID: @nROP, FILE_ID: element)
            if aROPFile == nil or aROPFile.empty? == true then
               puts "File with FILE_ID #{element} does not belong to ROP #{@nROP}"
               bFound = false
            end
         }

         if bFound == false then
            puts
            puts "All files to be sent within ROP #{@nROP} must belong to it !"
            puts
            exit(99)
         end
      end
   end

   puts "\nsendROPFiles.rb lock actions"

   @bUnblock = true 
   ret = @ropSender.lockFTActions
   # For EMERGENCY File Transfer we cannot allow concurrent requests to File Transfer
   if @bROPChecks == false then
      if ret == false then
         puts "FileTransfer is currently locked by other request :-|"
         puts
         puts "Emergency Mode requests are blocked !"
         puts
         exit(99)
      end
   else
      if ret == false then
         @bUnblock = false
      end
   end

   puts "\nsendROPFiles.rb get files"
   # Retrieve Files to be delivered
   if @listIDs != nil then
   
      cmd = %Q{getRPFFilesToBeTransferred.rb -E -i "#{@listIDs}" -V}

      if @nROP != 0 then
         cmd = %Q{#{cmd} -R #{@nROP}}
      end

      if @isDebugMode == true then
         cmd = %Q{#{cmd} -D}
         puts cmd
      end
   
      puts "\nsendROPFiles.rb send ROP files"
      bRet = execute(cmd, "sendROPFiles", false, @isDebugMode)

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("sendROPFiles", "#{ENV['DEC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in sendROPFiles::main"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DEC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

      if bRet == false then
         @logger.error("Error in getRPFFilesToBeTransferred")
         @logger.error("Could not retrieve files to be transferred from Archive")
         exit(99)
      end
   end


   # Prior to File(s) delivery via DDC, perform File Transfer process uniqueness blocking.
   puts "\nsendROPFiles.rb send ROP check"
   # Set sendROP running. This assures there is only one sendROP / sendROPFiles running  
   @locker = CUC::CheckerProcessUniqueness.new("sendROP.rb", nil, true)
      
   if @locker.isRunning == true then
      puts "\n#{File.basename($0)} / sendROP.rb is already running !\n\n"
      exit(99)
   end
  
   # Register in lock file the process
   @locker.setRunning


   #----------------------------------------------
   # Deliver files via DDC
   puts "\nsendROPFiles.rb ddc deliver"
   cmd = %Q{decDeliverFiles -N}
   
   if @nROP != 0 then
      cmd = %Q{#{cmd} -O -p "ROP_ID:#{@nROP}"}
   end
      
   if @isDebugMode == true then
      cmd = %Q{#{cmd} -D}
      puts cmd
   end
      
   bRet = system(cmd)
   #bRet = execute(cmd, "sendROP", false, @isDebugMode)
   
   if bRet == false then
      msg = "Error in sendROPFiles.rb deliverying files"
      @logger.error("Error in decDeliverFiles")
      @logger.error("Could not deliver files to the Interface")
      exit(99)
   end

   puts "\nsendROPFiles.rb end"
   if @bUnblock == true
      @ropSender.unlockFTActions
   end

   end

   # Remove stdout file
   if File.file?("#{stdoutFile}") == true then
      File.delete("#{stdoutFile}")
   end

   $stdout = old_stdout
end
#---------------------------------------------------------------------

# Check that everything needed by the class is present.
def checkModuleIntegrity
   return
end
#-------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = File.expand_path(__FILE__)   
   
   value = `#{"head -36 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
end
#-------------------------------------------------------------

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
