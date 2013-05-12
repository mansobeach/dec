#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #EOLIConfigManager class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> EOLI Client Component
# 
# CVS: $Id: EOLIConfigManager.rb,v 1.3 2006/09/29 07:16:01 decdev Exp $
#
# === This class installs the EOLI configuration zip package.
# It manages both EOLI Configuration files ApplicationConfiguration.xml &
# ServiceDirectory.xml 
#
#########################################################################

require 'cuc/DirUtils'

require 'eoli/EOLIReadAppConfiguration'
require 'eoli/EOLIReadServiceDirectory'


@@EOLI_CONFIG_PACKAGE                 = "EoliConfig.zip"
@@EOLI_SERVICE_DIRECTORY_FILE         = "ServiceDirectory.xml"
@@EOLI_APPLICATION_CONFIGURATION_FILE = "ApplicationConfiguration.xml"


class EOLIConfigManager

   include CUC::DirUtils
   
   # Class contructor
   def initialize
      @isDebugMode = false
      checkModuleIntegrity
      @currentAppConfig     = EOLIReadAppConfiguration.instance
      @currentServDirectory = EOLIReadServiceDirectory.instance
      @currentVerApp        = @currentAppConfig.getVersionNumber
      @currentServDir       = @currentServDirectory.getVersionNumber
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on.
   def setDebugMode
      @isDebugMode = true
      STDERR.puts "EOLIConfigManager debug mode is on"
   end
   #-------------------------------------------------------------   
   
   # Install the new config files only if their version numbers are 
   # higher than previous ones
   # There should not be more than object running this method concurrently.
   def install
      if checkPackage == false then
         return false
      end
      
      extract2TempDir
      renameOperationalConfigFiles
      ret = loadNewVersions
      if ret == false then
         cleanTempDir
         return false
      end
      
      # Check ApplicationConfiguration.xml
      if @newVerApp.to_f > @currentVerApp.to_f then
         if @isDebugMode == true then
            STDERR.puts "New #{@@EOLI_APPLICATION_CONFIGURATION_FILE} has a higher Version Number" 
         end
         installAppConfFile
      else
         rollbackAppConfFile
      end
      
      # Check ServiceDirectory.xml
      if @newServDir.to_f > @currentServDir.to_f then
         if @isDebugMode == true then
            STDERR.puts "New #{@@EOLI_CONFIG_PACKAGE} has a higher Version Number" 
         end         
         installServDirFile
      else
         rollbackServDirFile
      end
      
      cleanTempDir
      
      @currentAppConfig.reload
      @currentServDirectory.reload
      
      unlockConfigFiles
      
   end
   #-------------------------------------------------------------
   
   # It checks whether a different instance of the class is in this moment
   # processing the configuration. At the end it is just checking whether it exists
   # the config Package EOLI_CONFIG_PACKAGE.
   # It returns true if the EOLI_CONFIG_PACKAGE exists and it has blocked the config files,
   # otherwise it returns false
   def isAbleToCheckConfig?
      if File.exist?(@packageFilename) == true then
         unlockConfigFiles
         cleanTempDir
         return false
      else
         return lockConfigFiles
      end
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      bCheckOK = true
      if !ENV['EOLI_CLIENT_CONFIG'] then
         STDERR.puts "EOLI_CLIENT_CONFIG environment variable not defined !  :-(\n"
         bCheckOK = false
      end
      
      isToolPresent = `which unzip`
   
      if isToolPresent[0,1] != '/' then
         STDERR.puts "Fatal Error: unzip not present in PATH !!   :-(\n"
         bCheckOK = false
      end     
                    
      if bCheckOK == false then
        STDERR.puts "EOLIConfigManager::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
      
      
      @configDir = ENV['EOLI_CLIENT_CONFIG']
      @packageFilename = %Q{#{@configDir}/#{@@EOLI_CONFIG_PACKAGE}}
      
      time = Time.new
      time.utc
      str  = time.strftime("%Y%m%d_%H%M%S")
      
      @localDir = %Q{#{@configDir}/.config_#{str}}
      checkDirectory(@localDir)           
   end
   #-------------------------------------------------------------
   
   # It makes a copy (if not present) to 
   def makeCurrentLinks
      appConfFilename = getFilenameWithoutExtension(@@EOLI_APPLICATION_CONFIGURATION_FILE)
      servDirFilename = getFilenameWithoutExtension(@@EOLI_SERVICE_DIRECTORY_FILE)
      appConfExt      = getFileExtension(@@EOLI_APPLICATION_CONFIGURATION_FILE)
      servDirExt      = getFileExtension(@@EOLI_SERVICE_DIRECTORY_FILE)   
   end
   #-------------------------------------------------------------
   
   # It Checks EOLI Zip Package
   # IN Parameters:
   # It returns true if the package exists and its size is greater than 0. 
   def checkPackage
      if FileTest.exist?(@packageFilename) == false then
         if @isDebugMode == true then
            STDERR.puts "EOLIConfigManager -> Package #{@packageFilename} does not exist"
         end
         return false
      end
      if FileTest.size(@packageFilename) <= 0 then
         if @isDebugMode == true then
            STDERR.puts "EOLIConfigManager -> Package #{@packageFilename} has size 0"
         end
         return false
      end
      cmd = "unzip -t #{@packageFilename}"
      `#{cmd} 2> /dev/null`
      
      if $? != 0 then
         return false
      end
      
      return true
   end 
   #-------------------------------------------------------------
   
   # it extracts the package to a "local" temp dir
   def extract2TempDir
      prevDir = Dir.pwd
      cmd = "cp #{@packageFilename} #{@localDir}"
      system(cmd)
      Dir.chdir(@localDir)
      cmd = "unzip #{@@EOLI_CONFIG_PACKAGE}"
      `#{cmd}`
#      system(cmd)
      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------
   
   def renameOperationalConfigFiles
      prevDir = Dir.pwd
      Dir.chdir(@configDir)
      if FileTest.exist?(%Q{#{@@EOLI_SERVICE_DIRECTORY_FILE}.operational}) == true then
         File.delete(%Q{#{@@EOLI_SERVICE_DIRECTORY_FILE}.operational})
      end
      if FileTest.exist?(%Q{#{@@EOLI_APPLICATION_CONFIGURATION_FILE}.operational}) == true then
         File.delete(%Q{#{@@EOLI_APPLICATION_CONFIGURATION_FILE}.operational})
      end
      
      # BOLF Instead of deleting, just copying 
      #cmd = "cp -f #{@@EOLI_SERVICE_DIRECTORY_FILE} #{@@EOLI_SERVICE_DIRECTORY_FILE}.operational"
      cmd = "mv -f #{@@EOLI_SERVICE_DIRECTORY_FILE} #{@@EOLI_SERVICE_DIRECTORY_FILE}.operational"
      ret = system(cmd)
      
      if ret == false then
         STDERR.puts "Error in EOLIConfigManager::renameOperationalConfigFiles ! :-("
         STDERR.puts cmd
         STDERR.puts
         exit(99)
      end      
      
      # BOLF Instead of deleting, just copying 
#      cmd = "cp -f #{@@EOLI_APPLICATION_CONFIGURATION_FILE} #{@@EOLI_APPLICATION_CONFIGURATION_FILE}.operational"
      cmd = "mv -f #{@@EOLI_APPLICATION_CONFIGURATION_FILE} #{@@EOLI_APPLICATION_CONFIGURATION_FILE}.operational"
      system(cmd)

      if ret == false then
         STDERR.puts "Error in EOLIConfigManager::renameOperationalConfigFiles ! :-("
         STDERR.puts cmd
         STDERR.puts
         exit(99)
      end
      
      cmd = "unzip #{@@EOLI_CONFIG_PACKAGE}"
      `#{cmd}`
      #system(cmd)      
      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------
  
   def loadNewVersions
      anAppConfig     = EOLIReadAppConfiguration.instance
      aServDirectory  = EOLIReadServiceDirectory.instance
      begin
         anAppConfig.reload
         aServDirectory.reload
      rescue => exception
         if @isDebugMode == true then
            STDERR.puts exception.backtrace
            STDERR.puts
         end
         return false
      end
      @newVerApp        = anAppConfig.getVersionNumber
      @newServDir       = aServDirectory.getVersionNumber
      return true
   end
   #-------------------------------------------------------------
   
   # This Method deletes the newer configuration and sets up the previous.
   # Usually this method should be invoked after verifying that the newer file
   # has a version number equal or lower to the old config file 
   def rollbackAppConfFile
      prevDir = Dir.pwd
      Dir.chdir(@configDir)
      cmd = "rm -f #{@@EOLI_APPLICATION_CONFIGURATION_FILE}"
      ret = system(cmd)
      if ret == false then
         STDERR.puts "Error in EOLIConfigManager::rollbackAppConfFile ! :-("
         STDERR.puts cmd
         STDERR.puts
         exit(99)
      end
      cmd = "mv -f #{@@EOLI_APPLICATION_CONFIGURATION_FILE}.operational #{@@EOLI_APPLICATION_CONFIGURATION_FILE}"
      ret = system(cmd)
            
      if ret == false then
         STDERR.puts "Error in EOLIConfigManager::rollbackAppConfFile ! :-("
         STDERR.puts cmd
         STDERR.puts
         exit(99)
      end
        
      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------
   
   def rollbackServDirFile
      prevDir = Dir.pwd
      Dir.chdir(@configDir)

      cmd = "rm -rf #{@@EOLI_SERVICE_DIRECTORY_FILE}"
      system(cmd)
      
      cmd = "mv #{@@EOLI_SERVICE_DIRECTORY_FILE}.operational #{@@EOLI_SERVICE_DIRECTORY_FILE}"
      ret = system(cmd)

      if ret == false then
         STDERR.puts "Error in EOLIConfigManager::rollbackServDirFile ! :-("
         STDERR.puts cmd
         STDERR.puts
         exit(99)
      end

      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------
   
   #
   def installServDirFile
      prevDir = Dir.pwd
      Dir.chdir(@configDir)

      filenameWithoutExt = getFilenameWithoutExtension(@@EOLI_SERVICE_DIRECTORY_FILE)
      extension          = getFileExtension(@@EOLI_SERVICE_DIRECTORY_FILE)
      cmd = "mv -f #{@@EOLI_SERVICE_DIRECTORY_FILE}.operational #{filenameWithoutExt}_#{@currentVerApp}.#{extension}"
      ret = system(cmd)
      
      if ret == false then
         STDERR.puts "Error in EOLIConfigManager::installServDirFile ! :-("
         STDERR.puts cmd
         STDERR.puts
         exit(99)
      end
      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------
   
   #
   def installAppConfFile
      prevDir = Dir.pwd
      Dir.chdir(@configDir)
      
      filenameWithoutExt = getFilenameWithoutExtension(@@EOLI_APPLICATION_CONFIGURATION_FILE)
      extension          = getFileExtension(@@EOLI_APPLICATION_CONFIGURATION_FILE)
      cmd = "mv -f #{@@EOLI_APPLICATION_CONFIGURATION_FILE}.operational #{filenameWithoutExt}_#{@currentVerApp}.#{extension}"
      ret = system(cmd)
      
      if ret == false then
         STDERR.puts "Error in EOLIConfigManager::installAppConfFile ! :-("
         STDERR.puts cmd
         STDERR.puts
         exit(99)
      end
      Dir.chdir(prevDir)
   end
   #-------------------------------------------------------------
   
   # It locks the config files
   def lockConfigFiles
      prevDir = Dir.pwd
      Dir.chdir(@configDir)
      
      ret = File.new(@@EOLI_SERVICE_DIRECTORY_FILE).flock(File::LOCK_EX || LOCK_NB)
      if ret == false then
         Dir.chdir(prevDir)
         return false
      end
      ret = File.new(@@EOLI_APPLICATION_CONFIGURATION_FILE).flock(File::LOCK_EX || LOCK_NB)
      if ret == false then
         Dir.chdir(prevDir)
         return false
      end
      Dir.chdir(prevDir)
      return true   
   end
   #-------------------------------------------------------------
   
   # It unlocks the config files
   def unlockConfigFiles
      prevDir = Dir.pwd
      Dir.chdir(@configDir)
      
      File.new(@@EOLI_SERVICE_DIRECTORY_FILE).flock(File::LOCK_UN)
      File.new(@@EOLI_APPLICATION_CONFIGURATION_FILE).flock(File::LOCK_UN)
      
      Dir.chdir(prevDir)   
   end
   #-------------------------------------------------------------
   
   def cleanTempDir
      cmd = "\\rm -rf #{@localDir}"
      system(cmd)
      
      # delete as well the package
      cmd = "\\rm -f #{@packageFilename}"
      system(cmd)
   end
   #-------------------------------------------------------------
end
