#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #DCC_CheckerInventoryConfig class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Common Transfer Component
# 
# CVS:  $Id: CheckerInventoryConfig.rb,v 1.3 2007/12/19 06:08:03 decdev Exp $
#
# === module Common Transfer Component (CTC)
# This class is in charge of verify that Interfaces defined in the 
# configuration file interfaces.xml are as well defined in the database.
#
# ==== This class is in charge of accessing DEC database and check whether 
# ==== all I/F mnemonics defined within interfaces.xml are loaded.
#
#########################################################################

require 'ctc/ReadInterfaceConfig'
require 'dbm/DatabaseModel'


module CTC


class CheckerInventoryConfig
    
   #--------------------------------------------------------------

   # Class constructor.
   def initialize
      checkModuleIntegrity
      @dccReadConf    = CTC::ReadInterfaceConfig.instance
   end
   #-------------------------------------------------------------
   
   # ==== Main method of the class
   # ==== It returns a boolean True whether checks are OK. False otherwise.
   def check     
      retVal   = true      
      arrEnts  = @dccReadConf.getAllMnemonics

      arrEnts.each{|x|
         if Interface.find_by_name(x) != nil then
            puts "\n#{x} I/F is declared in DDC/Inventory ! :-) \n"
            retVal = true
         else
            puts "\n#{x} I/F is Not declared in DDC/Inventory ! :-( \n"
            retVal = false
         end
      }
      return retVal
   end
   #-------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerInventoryConfig debug mode is on"
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

