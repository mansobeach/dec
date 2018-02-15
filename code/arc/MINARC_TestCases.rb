#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MINARC_TestCases class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# module MINARC
#
#########################################################################

require 'rubygems'
require 'test/unit'

require 'cuc/DirUtils'
require 'arc/MINARC_ConfigDevelopment'
require 'arc/MINARC_Client'

class TestCaseStore < Test::Unit::TestCase

   include CUC::DirUtils
   include ARC
   
   # Order of the test cases execution according to defintion within code
   self.test_order = :defined
   
   #--------------------------------------------------------

   def setup
      
      load_config_development
      
      checkDirectory(ENV['MINARC_ARCHIVE_ROOT'])
      checkDirectory(ENV['MINARC_ARCHIVE_ERROR'])
      checkDirectory("#{ENV['HOME']}/Sandbox/minarc/inv")
      
      cmd = "manageDB.rb -c"
      ret = system(cmd)
      
      if ret == false then
         puts "Error when creating the minarc inventory ! :-("
         puts
         exit(99)
      end
      
      @file = "/Users/borja/Projects/dec/code/arc/plugins/test/S2A_OPER_REP_OPDPC__SGS__20170214T113527_V20170214T080018_20170214T080336.zip"
   end
   #--------------------------------------------------------

   def teardown

      cmd = "minArcPurge.rb -Y"
      ret = system(cmd)

      if ret == false then
         puts "Error when cleaning the minarc root directory ! :-("
         puts
         exit(99)
      end

      cmd = "manageDB.rb -d"
      ret = system(cmd)
      
      if ret == false then
         puts "Error when dropping the minarc inventory ! :-("
         puts
         exit(99)
      end


   end
   #--------------------------------------------------------


   #-------------------------------------------------------------

   def test_store
      cmd = "minArcStore -t S2PDGS -f #{@file}"
      puts cmd
      assert(system(cmd), "minArcStore")
   end
   #--------------------------------------------------------

   def test_delete
   
      test_store
   
      cmd = "minArcDelete -f #{File.basename(@file)}"
      puts cmd
      assert(system(cmd), "minArcDelete")
   end

   #-------------------------------------------------------------

   def test_remote_api_store
      
      arc = ARC::MINARC_Client.new
      # arc.setDebugMode

      type     = "S2PDGS"
      bDelete  = true
      assert( arc.storeFile(@file, type, bDelete) , "Verification remote API_URL_STORE: #{API_URL_STORE}")
   end
   #-------------------------------------------------------------

end


#=====================================================================


#-----------------------------------------------------------


