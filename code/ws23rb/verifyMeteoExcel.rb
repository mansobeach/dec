#!/usr/bin/env ruby


# == Synopsis
#
# This is the command line tool to extract data from the wsStation
#
# == Usage
#  verifyMeteoExcel.rb   -s <meteo-excel> [-t <newMeteoExcel>]
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


require 'getoptlong'
require 'rdoc/usage'

require 'cuc/CheckerProcessUniqueness'
require 'ws23rb/WSExcelFileVerifier'

# MAIN script function
def main
   @locker        = nil
   @isDebugMode   = false
   @bForce        = false
   @filename      = ""
   @targetname    = ""

   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",          GetoptLong::NO_ARGUMENT],
     ["--source", "-s",           GetoptLong::REQUIRED_ARGUMENT],
     ["--target", "-t",           GetoptLong::REQUIRED_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt     
            when "--Debug"   then @isDebugMode = true
            when "--Force"   then @bForce    = true
            when "--source"  then @filename  = arg.to_s
            when "--target"  then @targetname  = arg.to_s
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

   if @filename == "" then
      RDoc::usage("usage")
   end

   init

   handler = WS23RB::WSExcelFileVerifier.new(@filename, @targetname, @isDebugMode)

   hErrors = handler.verify

   if @targetname != "" then
      handler.createFlaggedExcel
   end

   if hErrors.empty? == true then
      exit(0)
   else
      exit(99)
   end

end
#---------------------------------------------------------------------

# It sets up the process.
# The process is registered and checked with #CheckerProcessUniqueness
# class.
def init  
#    @locker = CUC::CheckerProcessUniqueness.new(File.basename($0), "", true) 
#    if @locker.isRunning == true and @bForce == false then
#       puts "\n#{File.basename($0)} is already running !\n\n"
#       exit(99)
#    end
# 
#    if @locker.isRunning == true and @bForce == true then
#       puts "\nRe-starting #{File.basename($0)}\n"
#       sleep(2)
#    end
#    
#    registerSignals
# 
#    @locker.setRunning
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

