#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #EOCFI_Constants class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (EOCFI)
### 
### Git: EOCFI_MissionFiles,v $Id$ $Date$
###
### module EOCFI
###
#########################################################################

require 'rubygems'

module EOCFI
   
class EOCFI_MissionFiles

   attr_reader :file_MPL_ORBSCT,
               :file_MPL_GND_DB,
               :file_MPL_SWTVIS

   ## -----------------------------------------------------------

   ## Class constructor.
   def initialize(logger = nil)
      @logger = logger
      checkModuleIntegrity
      @file_MPL_ORBSCT = "#{File.dirname(File.expand_path(__FILE__))}/data/NS1_GSOV_MPL_ORBSCT"
      @file_MPL_GND_DB = "#{File.dirname(File.expand_path(__FILE__))}/data/NS1_GSOV_MPL_GND_DB"
      @file_MPL_SWTVIS = "#{File.dirname(File.expand_path(__FILE__))}/data/S2A_OPER_MPL_SWTVIS"
   end
   ## -----------------------------------------------------------

   ## Set debug mode on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("EOCFI_MissionFiles debug mode is on")
   end
   ## -----------------------------------------------------------

private

  ## -----------------------------------------------------------

   ## Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   ## -----------------------------------------------------------

end # class

end # module


## ==============================================================================
