#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to extract data from the wsStation
#
# == Usage
#  getHttpMeteoFile.rb 
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --Force               forces a new execution
#     --version             shows version number      
# 
# == Author
# Borja Lopez Fernandez
#
# == Copyright
# Casale Beach


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


require 'getoptlong'
require 'rdoc/usage'

require 'cuc/CheckerProcessUniqueness'
require 'cuc/Log4rLoggerFactory'
require 'ws23rb/ReadWSXMLFile'

# MAIN script function
def main
   @locker        = nil
   @isDebugMode   = false
   @bForce        = false
   @bHistoric     = false

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--Historic", "-H",       GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"       then @isDebugMode = true
            when "--Historic"    then @bHistoric = true
            when "--Force"   then @bForce = true
            when "--version" then
               print("\nCasale & Beach ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then RDoc::usage("usage")
            when "--help"    then RDoc::usage                         
         end
      end
   rescue Exception
      exit(99)
   end

   init

   # initialize logger
   loggerFactory = CUC::Log4rLoggerFactory.new("getHttpMeteoFile", "#{ENV['METEO_CONFIG']}/meteo_log_config.xml")
   if @isDebugMode then
#      loggerFactory.setDebugMode
   end
   @logger = loggerFactory.getLogger
   if @logger == nil then
      puts
	   puts "Error in getHttpMeteoFile::main"
		puts "Could not set up logging system !  :-("
      puts "Check logs configuration under \"#{ENV['METEO_CONFIG']}/dec_log_config.xml\"" 
		puts
		puts
		exit(99)
   end

   time           = Time.now
   now            = time.strftime("%Y%m%dT%H%M%S")   
   meteoFilename  = %Q{METEO_CASALE_#{now}.xml}

   prevDir     = Dir.pwd
   toolsDir    = ENV['METEO_TOOLS']
   tmpDir      = ENV['METEO_TEMP']
   archiveDir  = ENV['METEO_ARCHIVE']
   
   Dir.chdir(tmpDir)

   if File.exist?("METEO_CASALE.xml") == true then
      cmd = "mv -f METEO_CASALE.xml METEO_CASALE.xml.old"
      system(cmd)
   end

   cmd = "curl http://meteomonteporzio.altervista.org/METEO_CASALE.xml > METEO_CASALE.xml"
   @logger.debug(cmd)
   system(cmd)

   if File.exist?("METEO_CASALE.xml.old") == true then
      cmd = "diff METEO_CASALE.xml.old METEO_CASALE.xml"
      ret = system(cmd)
      if ret == true then
         @logger.debug("Same METEO_CASALE.xml downloaded")
         exit(0)
      end
   end

   parser   = ReadWSXMLFile.new("METEO_CASALE.xml")
   theDate  = parser.date.gsub('-','')
   theTime  = parser.time.gsub(':','')

   newFile  = "REALTIME_CASALE_#{theDate}T#{theTime}.xml"
   cmd      = "cp -f METEO_CASALE.xml #{newFile}"

   if @isDebugMode == true then
      puts cmd
      puts
   end

   system(cmd)


   # -----------------------------------
   # Archive new file
   cmd = "minArcStore2.rb -f #{Dir.pwd}/#{newFile} -t REALTIME_XML -d"

   if @isDebugMode == true then
      puts cmd
      puts
   end

   ret = system(cmd)
   # -----------------------------------

   exit(0)

end
#---------------------------------------------------------------------

def init
   return
end
#-------------------------------------------------------------

#-------------------------------------------------------------

# Register Signals
def registerSignals
   
   trap("SIGHUP") {  
                     puts "Hello ... [#{File.basename($0)}]\n"
                     killEmAll
                  }
   
   trap("USR1")   {  
                     puts "\nSignal SIGUSR2 received ...\n"
                  }
      
   trap("USR2")   {  
                     puts "\nSignal SIGUSR2 received ...\n"
                  }
      
   trap("SIGTSTP"){  
                     puts "\nSignal SIGTSTP received ...\n"
                  }
      
   trap("CONT")   {  
                     puts "\nSignal SIGCONT received ...\n"
                        
                  }
    
#       trap("CLD")    {  
#                         puts "\nSignal SIGCHILD received :-)...\n"
#                         processSIGCHILD
#                      }
   
   trap("INT")    {  
                     puts "\nSayonara Baby ... [#{File.basename($0)}]\n"
                     killEmAll
                  }
      
end
   #-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

