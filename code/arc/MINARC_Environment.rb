#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #FileArchiver class
###
### === Written by DEIMOS Space S.L.
###
### === Mini Archive Component (MinArc)
###
### Git: $Id: MINARC_Environment.rb $Date$
###
### module MINARC
###
#########################################################################

require 'dotenv'
require 'cuc/DirUtils'
begin
   require 'arc/ReadMinarcConfig'
rescue Exception
   require_relative 'ReadMinarcConfig'
end

module ARC

   include CUC::DirUtils

   VERSION   = "1.3.3.0"
   ## ----------------------------------------------------------------

   CHANGE_RECORD = { \
      "1.3.3"  =>      "Server to generate OData reports:\n\
         > auxip_query_report\n\
         > auxip_download_report",\
      "1.3.2"  =>      "Fixed Handler_DUMMY to decode any filename\n\
         MINARC_PLUGIN environment variable is required\n\
         Handler_NAOS updated for TLE\n\
         Fixed the gem installation warning regarding ASCII-8BIT to UTF-8 encoding\n\
         exiftool dependency constrained with version 1.2.4 for compatibility with ruby 2\n", \
      "1.3.1"  =>      "Handler_NAOS created for NAOS mission\n\
         Handler_DUMMY created for generic testing\n\
         Increased log messages",\
      "1.3.0"  =>      "Model updated to record ServedFiles\n\
         migration to ruby 2.7 for activesupport\n\
         gems addressable added as a dependency\n\
         log message ARC_600 to trace authentication failures\n\
         Handler_AUXIP handles EDR_OPER_SER_SR1_OA with validity dates not separated:\n\
         https://jira.elecnor-deimos.com/browse/S2MPASUP-481", \
      "1.2.2"  =>      "OData fix for simple $count queries\n\
         OData server refactoring for composed queries\n\
         public API now kept under ctc module", \
      "1.2.1"  =>      "CUC::CheckerProcessUniqueness rework for minArcServer", \
      "1.2.0"  =>      "filename_original added to the model\n\
         curl --connect-timeout raised to 60 to absorb low performance scenarii",\
      "1.1.5"  =>      "Handler_AUXIP created to support multi-mission", \
      "1.1.4"  =>      "Handler_S2PDGS updated to support OData JSON by DEC", \
      "1.1.3"  =>      "minArcStatus --filename supplies the URL\n\
         Fixed supply of correct JSON for minArcStatus --filename:\n\
         https://jira.elecnor-deimos.com/browse/S2MPASUP-441",\
      "1.1.2"  =>      "minArcServer support of SSL over HTTP\n\
         gems rack-ssl, rack-ssl-enforcer added as a dependency at installation time\n\
         VerifyPeerSSL configuration item added to bypass self-signed certificates",\
      "1.1.1"  =>      "OData fix ($count not limited to return results)", \
      "1.1.0"  =>      "uuid, md5 & Users has been added to the model for postgresql database\n\
         Client credentials configuration items added into minarc_config.xml
         Server API protected with HTTP Basic Authentication\n\
         Basic OData support for AUXIP\n\
         gems bcrypt, byebug added as a dependency at installation time\n\
         FOSS tools: jq, md5sum added as a dependency at execution time\n\
         minArcStatus CLI information supplied as JSON",\
      "1.0.38"  =>   "minArcServer robustification\n\
          Node identification configuration item added to minarc_config.xml\n\
          minArcReallocate support to change location of previously archived files",\
      "1.0.37"  =>   "Ghost version", \
      "1.0.36"  =>   "minArcServer fix to avoid uncontrolled children upon archive request:\n\
          https://jira.elecnor-deimos.com/browse/S2MPASUP-393",\
      "1.0.35"  =>   "New Server API primitive API_URL_RETRIEVE_CONTENT", \
      "1.0.34"  =>   "minarc_config.xml Inventory item added for database configuration\n\
          Support to remote inventory / db different than localhost\n\
          Inventory config now includes Database_Host & Database_Port items:\n\
          https://jira.elecnor-deimos.com/browse/S2MPASUP-384\n\
          minarc_config.xml includes configuration item Workflow ArchiveIntray for server\n\
          log messages formalisation\n\
          Containerised support:\n\
          https://jira.elecnor-deimos.com/browse/S2MPASUP-287",\
      "1.0.33" =>    "Fix of https://jira.elecnor-deimos.com/browse/S2MPASUP-290\n\
          DEC RetrievedFiles report is now supported by Handler_S2PDGS:\n\
          https://jira.elecnor-deimos.com/browse/S2MPASUP-308\n\
          exiftool added as dependency tool for the unit tests to verify plug-in Handler_VIDEO\n", \
      "1.0.32" =>    "Migration to ActiveRecord 6", \
      "1.0.31" =>    "Check of tool dependencies done in the unit tests\n\
          Environment variables for tests defined in minarc_test.env\n\
          Dotenv gem has been added to the Gemfile\n\
          Handler_VIDEO new supports largefiles > 4 GBs\n", \
      "1.0.30" =>    "Integration version with DEC / generic Orchestrator", \
      "1.0.29" =>    "minArcFile new tool to decode filename is included supported by Handler_S2PDGS\n", \
      "1.0.28" =>    "Handler_VIDEO updated to handle mkv (matrioska) files\n", \
      "1.0.27" =>    "Handler_VIDEO replaces M2TS & updated to handle wmv files\n", \
      "1.0.26" =>    "minArcStore --delete fix in remote mode\n          Fix to minArcRetrieve list with wildcards in remote mode", \
      "1.0.25" =>    "Server invokes minArcStore with --move flag to avoid copy", \
      "1.0.24" =>    "curl time-outs tailored to send big files in remote mode", \
      "1.0.23" =>    "Database model updated to replace Integer types by BigInt", \
      "1.0.22" =>    "Connection pool limit with ActiveRecord/thin fixed\n          new API function API_URL_STAT_FILENAME implemented", \
      "1.0.21" =>    "Handler_M2TS updated to handle mp4 files too\n          minArcStore supports deletion of local file upon remote archive", \
      "1.0.20" =>    "inventory updated to keep filename without extension\n          time-out updated when posting files", \
      "1.0.19" =>    "minArcDB creates an index by filename", \
      "1.0.18" =>    "minArcStore remote -L (location directory) used by m2ts/mp4", \
      "1.0.17" =>    "minArcRetrieve remote mode supports -t <filetype> retrieval", \
      "1.0.16" =>    "minArcRetrieve local mode supports to filter --New files by archive date", \
      "1.0.15" =>    "Server mode restarts the connection to avoid pool limit :-( | ConnectionPool pending", \
      "1.0.14" =>    "minArcStatus supports server mode for global and filetype", \
      "1.0.13" =>    "minArcStore supports bulk mode with wildcards in local mode", \
      "1.0.12" =>    "minArcStore supports -d (delete source file) with plug-in S2PDGS", \
      "1.0.11" =>    "minArcRetrieve support for wildcards and multiple files retrieval from server", \
      "1.0.10" =>    "Listing files from server fixed when more than one is found", \
      "1.0.9"  =>    "Handler_S2PDGS updated to support S2 REP_ARC__A index of auxiliary files", \
      "1.0.8"  =>    "minArcSmokeTestRemote working successfully with MINARC_SERVER variable only", \
      "1.0.7"  =>    "Client mode to retrieve files using obsolete curl older than 7.21.2", \
      "1.0.6"  =>    "minArcServer activation at execution time of selected environment", \
      "1.0.5"  =>    "minArcRetrieve -T now supports remote mode using server", \
      "1.0.4"  =>    "minArcStatus bundled with -V to retrieve version from server", \
      "1.0.3"  =>    "minArcRetrieve remote requests to replace * wildcards with http compliant %2A character", \
      "1.0.2"  =>    "minArcServer management of production and development environments", \
      "1.0.1"  =>    "Handler for m2ts files of Sony Camcorders", \
      "1.0.0"  =>    "First version of the minarc installer created" \
   }

   ## ----------------------------------------------------------------

   @@arrENV = [ \
                  "MINARC_TMP", \
                  "MINARC_ARCHIVE_ROOT", \
                  "MINARC_DB_ADAPTER", \
                  "MINARC_PLUGIN", \
                  "MINARC_ARCHIVE_ERROR", \
                  "MINARC_DATABASE_HOST", \
                  "MINARC_DATABASE_PORT", \
                  "MINARC_DATABASE_NAME", \
                  "MINARC_DATABASE_USER", \
                  "MINARC_DATABASE_PASSWORD" \
                  ]

   ## ----------------------------------------------------------------

   @@arrTools = [ \
                  "curl", \
                  "jq", \
                  "md5sum", \
                  "7za", \
                  "exiftool", \
                  "gzip", \
                  "tar", \
                  "zip", \
                  "unzip" \
                  ]

   ## -----------------------------------------------------------------

   def load_config

      # --------------------------------
      if !ENV['MINARC_CONFIG'] then
         ENV['MINARC_CONFIG'] = File.join(File.dirname(File.expand_path(__FILE__)), "../../config")
      end
      # --------------------------------

      minArcConfig   = ARC::ReadMinarcConfig.instance
      inventory      = minArcConfig.getInventory

      if !ENV['MINARC_DB_ADAPTER'] then
         ENV['MINARC_DB_ADAPTER'] = inventory[:db_adapter]
      end

      if !ENV['MINARC_DATABASE_HOST'] then
         ENV['MINARC_DATABASE_HOST'] = inventory[:db_host]
      end

      if !ENV['MINARC_DATABASE_PORT'] then
         ENV['MINARC_DATABASE_PORT'] = inventory[:db_port]
      end

      if !ENV['MINARC_DATABASE_NAME'] then
         ENV['MINARC_DATABASE_NAME'] = inventory[:db_name]
      end

      if !ENV['MINARC_DATABASE_USER'] then
         ENV['MINARC_DATABASE_USER'] = inventory[:db_username]
      end

      if !ENV['MINARC_DATABASE_PASSWORD'] then
         ENV['MINARC_DATABASE_PASSWORD'] = inventory[:db_password]
      end

      if !ENV['MINARC_SERVER'] and minArcConfig.getArchiveServer != "" then
         ENV['MINARC_SERVER'] = minArcConfig.getArchiveServer
      end

      if !ENV['MINARC_PLUGIN'] then
         raise "MINARC_PLUGIN env variable is missing"
      end

      if !ENV['MINARC_ARCHIVE_ROOT'] then
         ENV['MINARC_ARCHIVE_ROOT'] = minArcConfig.getArchiveRoot
      end

      if !ENV['MINARC_ARCHIVE_ERROR'] then
         ENV['MINARC_ARCHIVE_ERROR'] = minArcConfig.getArchiveError
      end

      if !ENV['MINARC_TMP'] then
         ENV['MINARC_TMP'] = minArcConfig.getTempDir
      end

   end

   ## -----------------------------------------------------------------
   def load_config_development
      ENV['MINARC_DB_ADAPTER']            = "sqlite3"
      ENV['MINARC_SERVER']                = "http://localhost:4567"
      ENV['MINARC_PLUGIN']                = "S2PDGS"
      ENV['MINARC_ARCHIVE_ROOT']          = "/tmp/minarc/archive_root"
      ENV['MINARC_ARCHIVE_ERROR']         = "/tmp/minarc/error"
      ENV['MINARC_TMP']                   = "/tmp/minarc/tmp"
      ENV['MINARC_DATABASE_HOST']         = "localhost"
      ENV['MINARC_DATABASE_PORT']         = ""
      ENV['MINARC_DATABASE_NAME']         = "#{ENV['HOME']}/Sandbox/inventory/minarc_inventory"
      ENV['MINARC_DATABASE_USER']         = "root"
      ENV['MINARC_DATABASE_PASSWORD']     = "1mysql"
      ENV['RACK_ENV']                     = "production"
   end

   ## ----------------------------------------------------------------

   ## ----------------------------------------------------------------

   def unset_config
      ENV.delete('MINARC_DB_ADAPTER')
      ENV.delete('MINARC_SERVER')
      ENV.delete('MINARC_PLUGIN')
      ENV.delete('MINARC_ARCHIVE_ROOT')
      ENV.delete('MINARC_ARCHIVE_ERROR')
      ENV.delete('MINARC_DATABASE_HOST')
      ENV.delete('MINARC_DATABASE_PORT')
      ENV.delete('MINARC_DATABASE_NAME')
      ENV.delete('MINARC_DATABASE_USER')
      ENV.delete('MINARC_DATABASE_PASSWORD')
      ENV.delete('MINARC_DEBUG')
   end
   ## ----------------------------------------------------------------

   def load_config_production
      ENV['RACK_ENV']                     = "production"
   end
   ## ----------------------------------------------------------------

   def print_environment
      puts "HOME                          => #{ENV['HOME']}"
      puts "RACK_ENV                      => #{ENV['RACK_ENV']}"
      puts "MINARC_DB_ADAPTER             => #{ENV['MINARC_DB_ADAPTER']}"
      puts "MINARC_SERVER                 => #{ENV['MINARC_SERVER']}"
      puts "MINARC_PLUGIN                 => #{ENV['MINARC_PLUGIN']}"
      puts "MINARC_TMP                    => #{ENV['MINARC_TMP']}"
      puts "MINARC_DATABASE_NAME          => #{ENV['MINARC_DATABASE_NAME']}"
      puts "MINARC_DATABASE_HOST          => #{ENV['MINARC_DATABASE_HOST']}"
      puts "MINARC_DATABASE_PORT          => #{ENV['MINARC_DATABASE_PORT']}"
      puts "MINARC_DATABASE_USER          => #{ENV['MINARC_DATABASE_USER']}"
      puts "MINARC_DATABASE_PASSWORD      => #{ENV['MINARC_DATABASE_PASSWORD']}"
      puts "MINARC_ARCHIVE_ROOT           => #{ENV['MINARC_ARCHIVE_ROOT']}"
      puts "MINARC_ARCHIVE_ERROR          => #{ENV['MINARC_ARCHIVE_ERROR']}"
      puts "MINARC_DEBUG                  => #{ENV['MINARC_DEBUG']}"
      puts "Workflow/ArchiveIntray        => #{ARC::ReadMinarcConfig.instance.getArchiveIntray}"
   end
   ## ----------------------------------------------------------------

   def log_environment(logger)
      logger.info("MINARC_DB_ADAPTER          => #{ENV['MINARC_DB_ADAPTER']}")
      logger.info("MINARC_SERVER              => #{ENV['MINARC_SERVER']}")
      logger.info("MINARC_PLUGIN              => #{ENV['MINARC_PLUGIN']}")
      logger.info("MINARC_DATABASE_NAME       => #{ENV['MINARC_DATABASE_NAME']}")
      logger.info("MINARC_DATABASE_HOST       => #{ENV['MINARC_DATABASE_HOST']}")
      logger.info("MINARC_DATABASE_PORT       => #{ENV['MINARC_DATABASE_PORT']}")
      logger.info("MINARC_DATABASE_USER       => #{ENV['MINARC_DATABASE_USER']}")
      logger.info("MINARC_DATABASE_PASSWORD   => #{ENV['MINARC_DATABASE_PASSWORD']}")
      logger.info("MINARC_ARCHIVE_ROOT        => #{ENV['MINARC_ARCHIVE_ROOT']}")
      logger.info("MINARC_ARCHIVE_ERROR       => #{ENV['MINARC_ARCHIVE_ERROR']}")
      logger.info("MINARC_DEBUG               => #{ENV['MINARC_DEBUG']}")
   end
   ## ----------------------------------------------------------------

   def check_environment_dirs
      checkDirectory(ENV['MINARC_TMP'])
      checkDirectory(ENV['MINARC_ARCHIVE_ROOT'])
      checkDirectory(ENV['MINARC_ARCHIVE_ERROR'])
      checkDirectory(ARC::ReadMinarcConfig.instance.getArchiveIntray)
   end
   ## ----------------------------------------------------------------

   def setRemoteModeOnly
      ENV.delete('MINARC_TMP')
      ENV.delete('MINARC_DB_ADAPTER')
      ENV.delete('MINARC_ARCHIVE_ROOT')
      ENV.delete('MINARC_ARCHIVE_ERROR')
      ENV.delete('MINARC_DATABASE_NAME')
      ENV.delete('MINARC_DATABASE_USER')
      ENV.delete('MINARC_DATABASE_PASSWORD')
   end
   ## ----------------------------------------------------------------

   def setLocalModeOnly
      ENV.delete('MINARC_SERVER')
   end
   ## ----------------------------------------------------------------

   def load_environment_test
      env_file = File.join(File.dirname(File.expand_path(__FILE__)), '../../install', 'minarc_test.env')
      Dotenv.overload(env_file)
   end

   ## ----------------------------------------------------------------

   def check_environment
      load_config
      check_environment_dirs
      retVal = checkEnvironmentEssential
      if retVal == true then
         return checkToolDependencies
      else
         return false
      end
   end
   ## ----------------------------------------------------------------

   def checkEnvironmentEssential
      load_config

      bCheck = true

      @@arrENV.each{|vble|
         if !ENV.include?(vble) then
            bCheck = false
            puts "MINARC environment variable #{vble} is not defined !\n"
            puts
         end
      }

      if bCheck == false then
         puts "MINARC environment / configuration not complete"
         puts
         return false
      end
      return true

   end
   ## ----------------------------------------------------------------

   def checkToolDependencies

      bCheck = true
      bCheckOK = true

      @@arrTools.each{|tool|
         isToolPresent = `which #{tool}`

         if isToolPresent[0,1] != '/' then
            puts "\n\nMINARC_Environment::checkToolDependencies\n"
            puts
            puts "Fatal Error: #{tool} not present in PATH   #{'1F480'.hex.chr('UTF-8')}#{'1F480'.hex.chr('UTF-8')}#{'1F480'.hex.chr('UTF-8')}\n"
            bCheckOK = false
         end

      }

      if bCheckOK == false then
         puts "minArc environment configuration is not complete"
         puts
         return false
      end

      return true

   end

   ## ----------------------------------------------------------------

   def printEnvironmentError
      puts "Execution environment not suited for  minARC"
   end
   ## ----------------------------------------------------------------


end # module

## ==============================================================================
##
## Wrapper to make use within unit tests since it is not possible inherit mixins
##

class MINARC_Environment

   include ARC

   def wrapper_load_config
      load_config
   end

   def wrapper_load_environment_test
      load_environment_test
   end

   def wrapper_load_config_development
      load_config_development
   end

   def wrapper_print_environment
      print_environment
   end

   def wrapper_check_environment
      return check_environment
   end

   def wrapper_unset_config
      unset_config
   end

   def wrapper_setRemoteModeOnly
      setRemoteModeOnly
   end

   def wrapper_setLocalModeOnly
      setLocalModeOnly
   end

   def wrapper_createEnvironmentDirs
      check_environment_dirs
   end

end

## ==============================================================================
