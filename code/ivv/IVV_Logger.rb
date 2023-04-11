#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #IVV_Environment_NAOS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (DEC)
### 
### Git: IVV_Environment_NAOS,v $Id$ $Date$
###
### module IVV
###
#########################################################################

require 'rubygems'
require 'cuc/Log4rLoggerFactory'

module IVV
   
   include CUC::DirUtils
   include DEC
   
   ## -----------------------------------------------------------------

   def load_logger

      if DEC::checkEnvironmentEssential == false then
         DEC.printEnvironmentError
         raise "DEC Environment not met"
      end

      @@configDirectory = nil
         
      if ENV['DEC_CONFIG'] then
         @@configDirectory         = %Q{#{ENV['DEC_CONFIG']}}
      else
         raise "Fatal ERROR IVV_Environment::load_logger DEC_CONFIG not defined"
      end        
            
      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("ivv ", "#{@@configDirectory}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      
      @logger = loggerFactory.getLogger
  
      if @logger == nil then
         puts
         puts "Error in IVV_Environment::initialize"
         puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{@@configDirectory}/dec_log_config.xml\"" 
         puts
         puts
         exit(99)
      end

      return @logger
   end
   ## -----------------------------------------------------------------
   
   def logTaskResult(logger, taskSuccess, messageInfo, messageError)
      if taskSuccess != false then
         logger.info(messageInfo)
      else
         logger.error(messageError)
      end
   end
   ## -----------------------------------------------------------------

end # module

## ==============================================================================

## Wrapper to make use within unit tests since it is not possible inherit mixins

class IVV_Logger
   
   include IVV
   
   def wrapper_createRemoteCmd(cmd, environment)
      createRemoteCmd(cmd, environment)
   end
end

## ==============================================================================
