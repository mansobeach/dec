#!/usr/bin/env ruby

#########################################################################
#
# === Wrapper for Ruby to EXPLORER EO CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
# 
#
#########################################################################

require './ruby_explorer_visibility'

require 'test/unit'
require 'cuc/Converters'

class TestCase_ExplorerVisibility < Test::Unit::TestCase

   include CUC::Converters

   # Order of the test cases execution according to defintion within code
   self.test_order = :defined
   
   @my_argv = ARGV.dup
   
   ## ------------------------------------------------------
   
   Test::Unit.at_start do      
      puts
      puts "======================================"
      puts "MPL Explorer_Orbit Unit Test Cases"
      puts
      puts
      puts "DO NOT EXECUTE IN THE PRODUCTION ENVIRONMENT !!!!!"
      puts
      puts "or with operational data in the archive"
      puts
      puts "THINK CAREFULLY !!! "
      puts
      puts "do you want to continue Y/n" 
      puts
      puts
      
      bBatchmode = false
            
      @my_argv.each{|arg|
         if arg == "batchmode" then
            puts "batch mode execution on"
            bBatchmode = true
            break
         end
      }
       
      if bBatchmode == false then
         c = STDIN.getc
         if c != 'Y' then
            exit(99)
         end
      end   
   end

   ## ------------------------------------------------------
   
   Test::Unit.at_exit do
      puts "End of MPL Explorer_Orbit Unit Test Cases"
   end
   
   ## ------------------------------------------------------

   ## Setup before every test-case
   ##
   def setup
      puts __method__.to_s
      puts
      puts "================================================"
      puts "TestCase_ExplorerLib::#{__method__.to_s}"
      puts
   end
   ## ------------------------------------------------------

   ## --------------------------------------------------------
   ## After every test case

   def teardown
      puts __method__.to_s
      puts
      puts "================================================"
      puts "TestCase_ExplorerLib::#{__method__.to_s}"
      puts
   end
   ## ------------------------------------------------------

   ## Test to print out the library version

   def test_check_library_version

      puts
      puts "================================================"
      puts "DEC_UnitTests::#{__method__.to_s}"
      puts

      test0    = MPL::Explorer_Visibility.new
      val      = test0.check_library_version

      puts 
      puts val
      puts
   end
   ## ------------------------------------------------------

   def test_StationVisTimeCompute

      puts
      puts "================================================"
      puts "DEC_UnitTests::#{__method__.to_s}"
      puts

      statDB         = "../data/S2__OPER_MPL_GND_DB"
      roef           = "../data/S2A_OPER_MPL_ORBSCT"
      swath          = "../data/S2A_OPER_MPL_SWTVIS"

   
   end

   ## ------------------------------------------------------

end


