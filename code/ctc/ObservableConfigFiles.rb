#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #ObservableConfigFiles class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: ObservableConfigFiles.rb,v 1.3 2006/10/05 15:07:24 decdev Exp $
#
# Module Common Transfer Component
# This class monitors DEC Config files.
#
# This class implements the Observer and Singleton patterns.
#
# Its mission is to check if the DCC Config files have changed
# and notify it to the classes in charge of decoding these files so that
# they could reload their data.
#
#########################################################################

require 'observer'
require 'singleton'

require 'cuc/CommandLauncher'



module CTC

class ObservableConfigFiles

   include Observable
   include Singleton
   include CUC::CommandLauncher 
   #--------------------------------------------------------------
   
   # Class constructor
   #  It is called only once as this is a singleton class
   def initialize
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      # default timer value is 60 seconds
      @timer              = 60      
      checkModuleIntegrity
      copyConfigFiles          
   end
   #-------------------------------------------------------------
   
   # Set the debug flag on.
   def setDebugMode
      @isDebugMode = true
      puts "DCC_ObservableFileDestination Debug Mode is on !"
   end
   #-------------------------------------------------------------

   # Stops monitoring the DCC config files.
   def stop
      @running = false
   end
   #-------------------------------------------------------------
   
   # Sets the monitoring polling interval
   # - seconds (IN): Polling interval in seconds
   def setTimer(seconds)
      @timer = seconds
   end
   #-------------------------------------------------------------
   
   # Starts monitoring on the DCC config files.
   def start
      checkFiles = self.method("checkFiles")     
      @running   = true   
      Thread.new{
                  while true
                     if @running == false then
                       Thread.stop
                     else
                       checkFiles.call
                     end
                     sleep(@timer)                   
                  end
               }                  
   end
   #-------------------------------------------------------------
   
private

   @@isModuleOK        = false
   @@isModuleChecked   = false
   @isDebugMode        = false   
   @timer              = nil
   @running            = nil   
   @srcConfigDir       = nil
   @readFileDest       = nil
 
   #-------------------------------------------------------------

   # Checks that the required files and environment variables are present.
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true   
      if !ENV['DCC_CONFIG'] then
        puts "\nDCC_CONFIG environment variable not defined !  :-(\n\n"
        bCheckOK = false
        bDefined = false
      end
      
      configDir = %Q{#{ENV['DCC_CONFIG']}}        
        
      configFile = %Q{#{configDir}/interfaces.xml}        
      if !FileTest.exist?(configFile) then
         bCheckOK = false
         print("\n\n", configFile, " does not exist !  :-(\n\n" )
      end
        
      configFile = %Q{#{configDir}/ft_incoming_files.xml}        
      if !FileTest.exist?(configFile) then
         bCheckOK = false
         print("\n\n", configFile, " does not exist !  :-(\n\n" )
      end        

      configFile = %Q{#{configDir}/ft_outgoing_files.xml}        
      if !FileTest.exist?(configFile) then
         bCheckOK = false
         print("\n\n", configFile, " does not exist !  :-(\n\n" )
      end
      
      configFile = %Q{#{configDir}/ft_mail_config.xml}        
      if !FileTest.exist?(configFile) then
         bCheckOK = false
         print("\n\n", configFile, " does not exist !  :-(\n\n" )
      end        
      
      if bCheckOK == false then
        puts "DCC_ObserverConfigFiles::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end            
      @srcConfigDir = ENV['DCC_CONFIG']
   end
   #-------------------------------------------------------------
   
   # Copy all the config files to "shadow" files that are going
   # to be monitored against the original ones.
   def copyConfigFiles
     command = %Q{\\cp -f #{@srcConfigDir}/interfaces.xml #{@srcConfigDir}/.interfaces.xml}
     retVal  = execute(command, "loadConfig")
     if retVal == false then
	     puts(command)
        puts("\n\nError copying config files  DCC_ObserverConfigFiles::copyConfigFiles	:-(\n\n")
        exit(99)
     end
          
     command = %Q{\\cp -f #{@srcConfigDir}/ft_outgoing_files.xml #{@srcConfigDir}/.ft_outgoing_files.xml}     
     retVal  = execute(command, "loadConfig")
     if retVal == false then
	     puts(command) 
        print "\n\nError copying config files  DCC_ObserverConfigFiles::copyConfigFiles :-(\n\n\n"
        exit(99)
     end     
     
     command = %Q{\\cp -f #{@srcConfigDir}/ft_incoming_files.xml #{@srcConfigDir}/.ft_incoming_files.xml}
     retVal  = execute(command, "loadConfig")
     if retVal == false then 
        puts(command)
		  print "\n\nError copying config files  DCC_ObserverConfigFiles::copyConfigFiles :-(\n\n\n"
        exit(99)
     end     
     
     command = %Q{\\cp -f #{@srcConfigDir}/ft_mail_config.xml #{@srcConfigDir}/.ft_mail_config.xml}
     retVal  = execute(command, "loadConfig")
     if retVal == false then
	     puts(command)
        print "\n\nError copying config files  DCC_ObserverConfigFiles::copyConfigFiles :-(\n\n\n"
        exit(99)
     end         
          
   end
   #-------------------------------------------------------------
   
   # Check that DCC configuration files remain the same. If they don't,
   # a notification is generated for all observers
   def checkFiles
      
     dir     = %Q{#{@srcConfigDir}}
     bUpdate = false
     
     command = %Q{diff #{dir}/ft_outgoing_files.xml #{dir}/.ft_outgoing_files.xml}     
     if @isDebugMode == true then
        puts command
     end          
     res = `#{command}`          
     if res != "" then bUpdate = true end
     
     command = %Q{diff #{dir}/ft_incoming_files.xml #{dir}/.ft_incoming_files.xml}     
     if @isDebugMode == true then
        puts command
     end          
     res = `#{command}`          
     if res != "" then bUpdate = true end

     command = %Q{diff #{dir}/interfaces.xml #{dir}/.interfaces.xml}     
     if @isDebugMode == true then
        puts command
     end
     res = `#{command}`               
     if res != "" then bUpdate = true end
     
     command = %Q{diff #{dir}/ft_mail_config.xml #{dir}/.ft_mail_config.xml}     
     if @isDebugMode == true then
        puts command
     end
     res = `#{command}`               
     if res != "" then bUpdate = true end     
            
     if bUpdate == true then
        if @isDebugMode then
           puts "DCC Configuration has changed ..."
        end     
        # Change the State and Notify the observers
        changed
        notify_observers
        # Copy the new config files
        copyConfigFiles
     else
        if @isDebugMode then
           puts "DCC Configuration remains the same ..."
        end
     end               
   end
   #-------------------------------------------------------------
   
   #=============================================================
end # class

end # module
