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

module DEC
   
   include CUC::DirUtils
   
   @@version = "1.0.12dev"
   
   ## -----------------------------------------------------------------
   
   @@change_record = { \
      "1.0.12" =>    "Support of WebDAV / HTTP(S) protocol using verbs PROPFIND,GET & DELETE\n\
          for pull mode (dec_incoming_files.xml)\n\
          satisfy https://jira.elecnor-deimos.com/browse/S2MPASUP-278\n\
          dec_interfaces.xml replaces \"FTPServer\" with \"Server\" configuration item",
      "1.0.11" =>    "Migration to ActiveRecord 6", \
      "1.0.10" =>    "new dec_config.xml deprecates dcc_config.xml & ddc_config.xml\n\
          new dec_incoming_files.xml deprecates files2Intrays.xml & ft_incoming_files.xml\n\
          new dec_outgoing_files.xml deprecates ft_outgoing_files.xml\n\
          Earth Explorer / Earth Observation file-types are deprecated\n\
          support to multiple log4r outputters\n\
          unit tests updated to verify the PUSH mode to send files",
      "1.0.9"  =>    "decUnitTests support batchmode to avoid prompting for confirmation", \
      "1.0.8"  =>    "decListener command line flags fixed", \
      "1.0.7"  =>    "decManageDB creates an index by filename for all tables", \
      "1.0.6"  =>    "decCheckConfig write checks for UploadDir/UploadDir for non secure FTP", \
      "1.0.5"  =>    "notify2Interface.rb fix sending mail to first address only \n         decCheckConfig shipped in the gem", \
      "1.0.4"  =>    "decValidateConfig shipped with the required xsd schemas", \
      "1.0.3"  =>    "upgrade of rpf module to support ruby 2.x series", \
      "1.0.2"  =>    "commands triggered by reception events are now logged", \
      "1.0.1"  =>    "decStats -H <hours> has been integrated", \
      "1.0.0"  =>    "first version of the dec installer created" \
   }
   ## -----------------------------------------------------------------
   
   def load_config_development
      ENV['DEC_VERSION']                  = DEC.class_variable_get(:@@version)
      ENV['DEC_DB_ADAPTER']               = "sqlite3"
      ENV['DEC_DATABASE_NAME']            = "/tmp/dec_inventory"
      ENV['DEC_DATABASE_USER']            = "root"
      ENV['DEC_DATABASE_PASSWORD']        = "1mysql"
      ENV['DEC_TMP']                      = "/tmp/dec_tmp"
      ENV['DEC_DELIVERY_ROOT']            = "/tmp/dec_delivery_root"
      ENV['DEC_CONFIG']                   = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      ENV['HOSTNAME']                     = `hostname`
      ENV.delete('DCC_CONFIG')
      ENV.delete('DCC_TMP')
   end
   
   ## -----------------------------------------------------------------

   ## extract DEC configuration from installation directory 
   def copy_installed_config(destination, nodename = "")
      
      checkDirectory(destination)
      ## -----------------------------
      ## DEC Config files
   
      arrConfigFiles = [\
         "dec_interfaces.xml",\
         "dec_incoming_files.xml",\
         "dec_outgoing_files.xml",\
         "ft_mail_config.xml",\
         "dec_log_config.xml",\
         "dec_config.xml"]
      ## -----------------------------

      path = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      
      arrConfigFiles.each{|config|
         if File.exist?("#{path}/#{config}") == true then
            FileUtils.cp("#{path}/#{config}", "#{destination}/#{nodename}##{config}")
            FileUtils.ln_s("#{destination}/#{nodename}##{config}","#{destination}/#{config}")
         end
      }
      
   end
   
   ## -----------------------------------------------------------------

   def load_config_developmentRPF
      ENV['RPF_ARCHIVE_ROOT']             = "#{ENV['HOME']}/Sandbox/dec/rpf_archive_root"
      ENV['FTPROOT']                      = "#{ENV['HOME']}/Sandbox/dec/delivery_root"
      ENV['RPFBIN']                       = File.dirname(File.expand_path(__FILE__))
   end

   ## -----------------------------------------------------------------

   def unset_config
      ENV.delete('DEC_VERSION')
      ENV.delete('DEC_DB_ADAPTER')
      ENV.delete('DEC_DATABASE_NAME')
      ENV.delete('DEC_DATABASE_USER')
      ENV.delete('DEC_DATABASE_PASSWORD')
      ENV.delete('DEC_TMP')
      ENV.delete('DEC_DELIVERY_ROOT')
   end

   ## -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "DEC_CONFIG                    => #{ENV['DEC_CONFIG']}"
      puts "DEC_DB_ADAPTER                => #{ENV['DEC_DB_ADAPTER']}"
      puts "DEC_TMP                       => #{ENV['DEC_TMP']}"
      puts "DEC_DELIVERY_ROOT             => #{ENV['DEC_DELIVERY_ROOT']}"
      puts "DEC_DATABASE_NAME             => #{ENV['DEC_DATABASE_NAME']}"
      puts "DEC_DATABASE_USER             => #{ENV['DEC_DATABASE_USER']}"
      puts "DEC_DATABASE_PASSWORD         => #{ENV['DEC_DATABASE_PASSWORD']}"
      puts "HOSTNAME                      => #{ENV['HOSTNAME']}"
   end
   ## -----------------------------------------------------------------
   
   def print_environmentRPF
      puts "RPFBIN                        => #{ENV['RPFBIN']}"
      puts "RPF_ARCHIVE_ROOT              => #{ENV['RPF_ARCHIVE_ROOT']}"
      puts "FTPROOT                       => #{ENV['FTPROOT']}"
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

class DEC_Environment
   
   include DEC
   
   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_load_config_developmentRPF
      load_config_developmentRPF
   end

   def wrapper_check_environment
      return check_environment
   end

   def wrapper_unset_config
      unset_config
   end

   def wrapper_check_config_files_incoming
      return checkConfigFilesIncoming
   end

   def wrapper_check_config_files_outgoing
      return checkConfigFilesOutgoing
   end

   def wrapper_print_environment
      print_environment
   end

   def wrapper_print_environmentRPF
      print_environmentRPF
   end
   
end

## ==============================================================================
