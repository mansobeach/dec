#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #DEC_ConfigDevelopment class
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

require 'cuc/DirUtils'

module DEC
   
   include CUC::DirUtils
   
   @@version = "1.0.5"
   
   # -----------------------------------------------------------------
   
   @@change_record = { \
      "1.0.5"  =>    "notify2Interface.rb fix sending mail to first address only \n         decCheckConfig shipped in the gem", \
      "1.0.4"  =>    "decValidateConfig shipped with the required xsd schemas", \
      "1.0.3"  =>    "upgrade of rpf module to support ruby 2.x series", \
      "1.0.2"  =>    "commands triggered by reception events are now logged", \
      "1.0.1"  =>    "decStats -H <hours> has been integrated", \
      "1.0.0"  =>    "first version of the dec installer created" \
   }
   # -----------------------------------------------------------------
   
   def load_config_development
      ENV['DEC_VERSION']                  = DEC.class_variable_get(:@@version)
      ENV['DEC_DB_ADAPTER']               = "sqlite3"
      ENV['DEC_DATABASE_NAME']            = "#{ENV['HOME']}/Sandbox/dec/dec_inventory"
      ENV['DEC_DATABASE_USER']            = "root"
      ENV['DEC_DATABASE_PASSWORD']        = "1mysql"
      ENV['DEC_TMP']                      = "#{ENV['HOME']}/Sandbox/dec/tmp"
      ENV['DEC_DELIVERY_ROOT']            = "#{ENV['HOME']}/Sandbox/dec/delivery_root"
      # ENV['DEC_CONFIG']                   = "#{ENV['HOME']}/Projects/dec/config"
      ENV['DEC_CONFIG']                   = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      ENV['HOSTNAME']                     = `hostname`
      ENV.delete('DCC_CONFIG')
      ENV.delete('DCC_TMP')
   end
   
   # -----------------------------------------------------------------

   def load_config_developmentRPF
      ENV['RPF_ARCHIVE_ROOT']             = "#{ENV['HOME']}/Sandbox/dec/rpf_archive_root"
      ENV['FTPROOT']                      = "#{ENV['HOME']}/Sandbox/dec/delivery_root"
      ENV['RPFBIN']                       = File.dirname(File.expand_path(__FILE__))
   end

   # -----------------------------------------------------------------
   
   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "DEC_DB_ADAPTER                => #{ENV['DEC_DB_ADAPTER']}"
      puts "DEC_TMP                       => #{ENV['DEC_TMP']}"
      puts "DEC_DATABASE_NAME             => #{ENV['DEC_DATABASE_NAME']}"
      puts "DEC_DATABASE_USER             => #{ENV['DEC_DATABASE_USER']}"
      puts "DEC_DATABASE_PASSWORD         => #{ENV['DEC_DATABASE_PASSWORD']}"
      puts "DEC_CONFIG                    => #{ENV['DEC_CONFIG']}"
      puts "HOSTNAME                      => #{ENV['HOSTNAME']}"
   end
   # -----------------------------------------------------------------
   
   def print_environmentRPF
      puts "RPFBIN                        => #{ENV['RPFBIN']}"
      puts "RPF_ARCHIVE_ROOT              => #{ENV['RPF_ARCHIVE_ROOT']}"
      puts "FTPROOT                       => #{ENV['FTPROOT']}"
   end
   # -----------------------------------------------------------------

   def checkEnvironmentEssential
      bCheck = true
      if !ENV['DEC_CONFIG'] then
         bCheck = false
         puts "DEC_CONFIG environment variable is not defined !\n"
         puts
      end

      if !ENV['DEC_TMP'] then
         bCheck = false
         puts "DEC_TMP environment variable is not defined !\n"
         puts
      end
      
      if bCheck == false then
         puts "DEC environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   # -----------------------------------------------------------------

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
   # -----------------------------------------------------------------

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

      if bCheck == false then
         puts "DEC environment variables configuration not complete"
         puts
         return false
      end
      return true
   end
   # -----------------------------------------------------------------

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

      if bCheck == false then
         puts "DEC environment variables configuration not complete"
         puts
         return false
      end
      return true
   
   end
   # -----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for DEC"
   end
   # -----------------------------------------------------------------
   
   def createEnvironmentDirs
      checkDirectory(ENV['DEC_TMP'])
      
      checkDirectory(ENV['DEC_DELIVERY_ROOT'])
      
      if ENV['DEC_DATABASE_NAME'][0,1] == '/' then
         checkDirectory(File.dirname(ENV['DEC_DATABASE_NAME']))
      end

      # cf. $DEC_CONFIG/dec_log_config.xml
      checkDirectory("/tmp/dec/log")
     
   end
   # -----------------------------------------------------------------

   def createEnvironmentDirsRPF
      checkDirectory(ENV['RPF_ARCHIVE_ROOT'])      
      checkDirectory(ENV['FTPROOT'])
   end
   # -----------------------------------------------------------------
   
   def checkToolDependencies

      bDefined = true
      bCheckOK = true
      
      arrTools = [ \
                  "xmllint", \
                  "ncftp", \
                  "ncftpput", \
                  "sftp" \
                  ]
      
      arrTools.each{|tool|
         isToolPresent = `which #{tool}`
               
         if isToolPresent[0,1] != '/' then
            puts "\n\nDEC_Environment::checkToolDependencies\n"
            puts "Fatal Error: #{tool} not present in PATH !!   :-(\n\n\n"
            bCheckOK = false
         end

      }
      
      #check the commands needed
                   
      if bCheckOK == false then
         puts "\nnDEC_Environment::checkToolDependencies FAILED !\n\n"
      end      
   
      return bCheckOK
   end
   # -----------------------------------------------------------------
   
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
   # -----------------------------------------------------------------
   
end # module

# ==============================================================================

# Wrapper to make use within unit tests since it is not possible inherit mixins

class DEC_Environment
   
   include DEC
   
   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_load_config_developmentRPF
      load_config_developmentRPF
   end

   def wrapper_print_environment
      print_environment
   end

   def wrapper_print_environmentRPF
      print_environmentRPF
   end
   
end

# ==============================================================================
