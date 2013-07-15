#!/usr/bin/env ruby

#########################################################################
#
# Ruby script moveFilesToRejectDirectory to move files of another
# entity to _Rejected_ directory, this way the files 
# will be rescued if required
# 
# Written by DEIMOS Space S.L.   (paat)
#
# RPF
# 
# CVS:
#   $Id: moveFilesToRejectDirectory.rb,v 1.3 2008/07/03 11:34:58 decdev Exp $
#
#########################################################################

require 'getoptlong'
require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'
require 'ctc/ReadInterfaceConfig'
require 'rpf/FT_ReportHandler'

def main  
include CUC::DirUtils
  @logger=nil
  opts = GetoptLong.new(   
  ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT], 
  ["--directory","-d",       GetoptLong::REQUIRED_ARGUMENT],  
  ["--help", "-h",           GetoptLong::NO_ARGUMENT]
  )
  opts.each do |opt, arg|
    case opt
       when "--mnemonic"  then @mnemonic  = arg
       when "--directory" then @directory = arg
       when "--help"      then usage 
    end
  end
  
  if (@mnemonic==nil) and (@directory==nil) then usage
  end

  #Directory incoming files of mnemonic 
  if @directory == nil then
     @directory=CTC::ReadInterfaceConfig.instance()::getIncomingDir(@mnemonic)
  end
  
  @_rejectDirectory=expandPathValue("$RPF_ARCHIVE_ROOT/Files/_discardedFiles")
  checkDirectory(@_rejectDirectory)

  if @mnemonic != nil then
     createLog(@mnemonic) 
  else
     createLog(@directory) 
  end


  files=false
  directory = Dir.open(@directory)

  directory.each {|x|
     if (!File::directory?(x)) then
       @logger.info("File: #{x} has been rejected")
       puts ("File: #{x} has been rejected")
       files=true
     end
  }
  
  if files==false then
    puts "Nothing to remove"
    return
  end
  

  #store old dir
  oldDir=Dir::pwd
  
  
  #change dir working
  fileList=Dir::chdir(@directory)
  
  command = %Q{mv #{@directory}/* #{@_rejectDirectory}/}


  if (system(command)==0) then
      smsLog= %Q{write2Log.bin --o #{File.basename($0)} --m "Move files from #{@directory} to #{@_rejectDirectory}"  --info --fileTx}
      system(smsLog)
   else
      smsLog= %Q{write2Log.bin --o #{File.basename($0)} --m "Can not move files from #{@directory} to #{@_rejectDirectory}"  --error --fileTx}
      system(smsLog)
   end
  #put report into archive.
  
  if (@mnemonic != nil) then
   report=FT_ReportHandler.new(9,@mnemonic)
  else
   report=FT_ReportHandler.new(9,"Automatic")
  end
  
  report.putInReport      

  
  #change old dir working
  Dir::chdir(oldDir)
end

# Function about to use this program
def usage
   print "\nUsage:\n\t", File.basename($0),    "  --mnemonic <MNEMONIC> [--report <directory>]\n\n"
   print "\t--mnemonic    <MNEMONIC>     mnemonic to validate\n"
   print "\t--directory   <DIRECTORY>    directory to validate\n"  
   print "\t--help                       shows this help\n"
   print "\n\n"      
   exit
end

def createLog(entity)
   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("moveFilesToRejectDirectory:#{entity}", "#{ENV['DCC_CONFIG']}/dec_log_config.xml")
   if @isDebugMode then
      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
		puts "Error in moveFilesToRejectDirectory::createLog"
		puts "Could not set up logging system !  :-("
      puts "Check DEC logs configuration under \"#{ENV['DCC_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end
end


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
