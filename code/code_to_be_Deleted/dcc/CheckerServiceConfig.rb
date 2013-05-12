#!/usr/bin/ruby

#########################################################################
#
# = Ruby source for #CheckerServiceConfig class
#
# = Written by DEIMOS Space S.L. (bolf)
#
# = Data Exchange Component -> Data Collector Component
# 
# CVS:
#  $Id: CheckerServiceConfig.rb,v 1.1 2006/09/12 07:59:26 decdev Exp $
#
#########################################################################

require 'dcc/ReadServiceConfig'

 # This class is in charge of verify that the Entities defined in the 
 # dcc_service.xml config file are present in the DCC Service
 #

module DCC

class CheckerServiceConfig
    
   #--------------------------------------------------------------

   # Class constructor.
   def initialize
      checkModuleIntegrity
      @dccReadConf    = DCC_ReadService.instance
   end
   #-------------------------------------------------------------
   
   # Main method of the class which performs the check.
   def check     
      retVal       = true      
      arrServices  = @dccReadConf.services

      arrServices.each{|x|
         ret  = true
         name = x[:name]
         cmd  = x[:command]
         freq = x[:interval]
         cmd  = cmd.split(" ")[0]
         checker = %Q{which #{cmd}}
         ret     = `#{checker}`
         if ret.slice(0,1) != '/' then
            puts "Command #{cmd} could not be found in $PATH"
            ret    = false
            retVal = false
         end
         if freq.to_i == 0 then
            ret    = false
            retVal = false
            puts
            puts "Interval field has not a numeric Value, #{freq} !"
         end
         if ret == false then
           puts "Service #{name} is not correctly configured ! :-("
           puts
         end
      }
      return retVal
   end
   #-------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "DCC_CheckerServiceConfig debug mode is on"
   end
   #-------------------------------------------------------------

private

   @isDebugMode       = false      

   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------

end # class

end # module
