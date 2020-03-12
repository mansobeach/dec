#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC_Environment class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component (DEC)
# 
# Git: DEC_Environment,v $Id$ $Date$
#
# module DEC
#
#########################################################################

require 'rubygems'
require 'fileutils'

require 'cuc/DirUtils'

module AUX
   
   include CUC::DirUtils
   
   @@version = "0.0.0"
   
   ## -----------------------------------------------------------------
   
   @@change_record = { \
      "0.0.1"  =>    "decStats -H <hours> has been integrated", \
      "0.0.0"  =>    "first version of the dec installer created" \
   }
   ## -----------------------------------------------------------------
   
   def load_config_development
   
   end
   
   ## -----------------------------------------------------------------

   
   ## -----------------------------------------------------------------


   ## -----------------------------------------------------------------

   def unset_config
   end

   ## -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "HOSTNAME                      => #{ENV['HOSTNAME']}"
   end
   ## -----------------------------------------------------------------
   

   def check_environment_dirs
      checkDirectory(ENV['DEC_TMP'])
   end

   ## -----------------------------------------------------------------

   def check_environment_dirs_push
      checkDirectory(ENV['DEC_DELIVERY_ROOT'])
   end

   ## -----------------------------------------------------------------

   def check_environment
      retVal = checkEnvironmentEssential
      if retVal == true then
         check_environment_dirs
         return checkToolDependencies
      else
         return false
      end
   end
   ## -----------------------------------------------------------------

   def checkEnvironmentEssential
      bCheck = true
      
      # --------------------------------
      # DEC_CONFIG can be defined by the customer to override 
      # the configuration shipped with the gem
      if !ENV['DEC_CONFIG'] then
         ENV['DEC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
      # --------------------------------
      
      if !ENV['DEC_TMP'] then
         bCheck = false
         puts "DEC_TMP environment variable is not defined !\n"
         puts
      else
         checkDirectory(ENV['DEC_TMP'])
      end
      
      if bCheck == false then
         puts "DEC Essential environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   ## -----------------------------------------------------------------

   def checkEnvironmentPUSH
      bCheck = true
      if !ENV['DEC_DELIVERY_ROOT'] then
         bCheck = false
         puts "DEC_DELIVERY_ROOT environment variable is not defined !\n"
         puts
      end
      
      if bCheck == false then
         puts "DEC PUSH environment variables configuration not complete"
         puts
         return false
      end
      return true      
   end
   ## -----------------------------------------------------------------

   def checkEnvironmentMail
      bCheck = true
      
      if !ENV['HOSTNAME'] then
         bCheck = false
         puts
         puts "HOSTNAME environment variable is not defined !\n"
         puts
      end
      
      if bCheck == false then
         puts "DEC environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   ## -----------------------------------------------------------------

   def checkEnvironmentDB
      bCheck = true
      if !ENV['DEC_DB_ADAPTER'] then
         bCheck = false
         puts
         puts "DEC_DB_ADAPTER environment variable is not defined !\n"
         puts
      end

      if !ENV['DEC_DATABASE_NAME'] then
         bCheck = false
         puts
         puts "DEC_DATABASE_NAME environment variable is not defined !\n"
         puts
      end

      if !ENV['DEC_DATABASE_USER'] then
         bCheck = false
         puts
         puts "DEC_DATABASE_USER environment variable is not defined !\n"
         puts
      end

      if !ENV['DEC_DATABASE_PASSWORD'] then
         bCheck = false
         puts
         puts "DEC_DATABASE_PASSWORD environment variable is not defined !\n"
         puts
      end

      if bCheck == false then
         puts "DEC database environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   ## -----------------------------------------------------------------

   def checkEnvironmentRPF
      bCheck = true
      if !ENV['RPFBIN'] then
         bCheck = false
         puts
         puts "RPFBIN environment variable is not defined !\n"
         puts
      end

      if !ENV['RPF_ARCHIVE_ROOT'] then
         bCheck = false
         puts
         puts "RPF_ARCHIVE_ROOT environment variable is not defined !\n"
         puts
      end

      if !ENV['FTPROOT'] then
         bCheck = false
         puts
         puts "FTPROOT environment variable is not defined !\n"
         puts
      end

      if bCheck == false then
         puts "DEC RPF environment variables configuration not complete"
         puts
         return false
      end
      return true
   
   end
   ## -----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for DEC"
   end
   ## -----------------------------------------------------------------
   
   def createEnvironmentDirs
      checkDirectory(ENV['DEC_TMP'])
      
      checkDirectory(ENV['DEC_DELIVERY_ROOT'])
      
      if ENV['DEC_DATABASE_NAME'][0,1] == '/' then
         checkDirectory(File.dirname(ENV['DEC_DATABASE_NAME']))
      end

      # cf. $DEC_CONFIG/dec_log_config.xml
      checkDirectory("/tmp/dec/log")
     
   end
   ## -----------------------------------------------------------------

   def createEnvironmentDirsRPF
      checkDirectory(ENV['RPF_ARCHIVE_ROOT'])      
      checkDirectory(ENV['FTPROOT'])
   end
   ## -----------------------------------------------------------------
   
   def checkConfigFilesIncoming
      arrFiles = [ \
                  "dec_interfaces.xml", \
                  "dec_incoming_files.xml"
                  ]
      bRet = true
      arrFiles.each{|file|
         if File.exist?("#{ENV['DEC_CONFIG']}/#{file}") == false then
            bRet = false
            puts "#{ENV['DEC_CONFIG']}/#{file} not found !"
         end
      }
      return bRet
   end

   ## -----------------------------------------------------------------  

   def checkConfigFilesOutgoing
      arrFiles = [ \
                  "dec_interfaces.xml", \
                  "dec_outgoing_files.xml"
                  ]
      bRet = true
      arrFiles.each{|file|
         if File.exist?("#{ENV['DEC_CONFIG']}/#{file}") == false then
            bRet = false
            puts "#{ENV['DEC_CONFIG']}/#{file} not found !"
         end
      }
      return bRet   
   end
   
   ## -----------------------------------------------------------------   
   ##
   ## check command line tool dependencies
   ##
   def checkToolDependencies

      bDefined = true
      bCheckOK = true
      
      arrTools = [ \
                  "7za", \
                  "xmllint", \
                  "curl", \
                  "ncftp", \
                  "ncftpput", \
                  "sftp" \
                  ]
      
      arrTools.each{|tool|
         isToolPresent = `which #{tool}`
               
         if isToolPresent[0,1] != '/' then
            puts "\n\nDEC_Environment::checkToolDependencies\n"
            puts "Fatal Error: #{tool} not present in PATH   :-(\n\n\n"
            bCheckOK = false
         end

      }
                         
      if bCheckOK == false then
         puts "\nDEC_Environment::checkToolDependencies FAILED !\n\n"
      end      
   
      return bCheckOK
   end
   ## -----------------------------------------------------------------
   
   def checkToolDependenciesRPF
      bCheckOK = true
      
      arrTools = [ \
                  "removeSchema.bin", \
                  "write2Log.bin", \
                  "put_report.bin" \
                  ]
   
      rootDir = ENV['RPFBIN']
      
      arrTools.each{|tool|
                     
         if File.exist?("#{rootDir}/#{tool}") == false then
            puts "\n\nDEC_Environment::checkToolDependenciesRPF\n"
            puts "Fatal Error: #{tool} not present in RPFBIN #{rootDir}   :-(\n\n\n"
            bCheckOK = false
         end

      }
      
      #check the commands needed
                   
      if bCheckOK == false then
         puts "\nnDEC_Environment::checkToolDependencies for RPF FAILED !\n\n"
      end      
   
      return bCheckOK
   end
   ## -----------------------------------------------------------------
   
end # module

## ==============================================================================

## Wrapper to make use within unit tests since it is not possible inherit mixins

class AUX_Environment
   
   include AUX
   
   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_check_environment
      return check_environment
   end

   def wrapper_unset_config
      unset_config
   end

   def wrapper_print_environment
      print_environment
   end
   
end

## ==============================================================================
