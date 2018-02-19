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
   
   Test::Unit.at_start do      
      puts
      puts "======================================"
      puts "MINARC Test Cases"
      puts
      puts "init server"
      @serverPID = spawn("ruby MINARC_Server.rb")
      puts @serverPID
   end
   
   #--------------------------------------------------------
   
   Test::Unit.at_exit do
      puts "End of tests"
            
      puts "Killing MINARC_Server"
      cmd = "kill -9 #{@serverPID}"
      system(cmd)
   end
   
   #--------------------------------------------------------   
   
   # Setup before every test-case
   #
   def setup
      
      load_config_development
      
      cmd = "manageDB.rb -c"
      ret = system(cmd)
      
      if ret == false then
         puts "Error when creating the minarc inventory ! :-("
         puts
         # exit(99)
      end
      
      @file = "/Users/borja/Projects/dec/code/arc/plugins/test/S2A_OPER_REP_OPDPC__SGS__20170214T113527_V20170214T080018_20170214T080336.zip"
   end
   #--------------------------------------------------------
   # After every test case

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
      puts
      puts "================================================"
      puts "MINARC_TestCases::test_store"
      puts
      cmd = "minArcStore -t S2PDGS -f #{@file}"
      puts cmd
      assert(system(cmd), "minArcStore")
   end
   #--------------------------------------------------------

   def test_delete
      puts
      puts "================================================"
      puts "MINARC_TestCases::test_delete"
      puts
   
      test_store
   
      cmd = "minArcDelete -f #{File.basename(@file)}"
      puts cmd
      assert(system(cmd), "minArcDelete")
   end

   #-------------------------------------------------------------

   def test_remote_api_version
      arc = ARC::MINARC_Client.new
      # arc.setDebugMode

      version = arc.getVersion
      
      puts "MINARC Version #{version}"
      assert( (version != "") , "Verification remote API_URL_VERSION: #{API_URL_VERSION}")   
   end
   #-------------------------------------------------------------

   def test_remote_api_store
      
      arc = ARC::MINARC_Client.new
      # arc.setDebugMode

      type     = "S2PDGS"
      bDelete  = false
      assert( arc.storeFile(@file, type, bDelete) , "Verification remote API_URL_STORE: #{API_URL_STORE}")
   end
   #-------------------------------------------------------------

   def test_remote_api_retrieve
      
      arc = ARC::MINARC_Client.new
      arc.setDebugMode

      type     = "S2PDGS"
      bDelete  = false
      
      arc.storeFile(@file, type, bDelete)


      assert( arc.retrieveFile("S2A_OPER_REP_OPDPC__SGS__20170214T113527_V20170214T080018_20170214T080336"),
               "Verification remote API_URL_RETRIEVE: #{API_URL_RETRIEVE}")
   end
   #-------------------------------------------------------------


end


#=====================================================================


#-----------------------------------------------------------


