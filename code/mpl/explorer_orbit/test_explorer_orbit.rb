#!/usr/bin/env ruby

#########################################################################
#
# === Wrapper for Ruby to EXPLORER EO CFI by DEIMOS Space S.L.U.      
#
# === Written by Borja Lopez Fernandez
# 
#
#########################################################################

require './ruby_explorer_orbit'

require 'test/unit'
require 'cuc/Converters'

class TestCase_ExplorerOrbit < Test::Unit::TestCase

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

      test0    = MPL::Explorer_Orbit.new
      val      = test0.check_library_version

      puts 
      puts val
      puts
   end
   ## ------------------------------------------------------

   ## Test to compute the date-time

   def test_DateTime2OrbitAbsolute

      puts
      puts "================================================"
      puts "DEC_UnitTests::#{__method__.to_s}"
      puts

      strDate = "20170422T120000"

      test    = MPL::Explorer_Orbit.new
    
      puts "-----------------------------------------"
      
      val   = test.DateTime2OrbitAbsolute(\
                           "data/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF", \
                           strDate \
                           )
      puts
      puts "Date => #{strDate} Orbit => #{val}"
      puts
      puts "-----------------------------------------"
   
      assert(val != -1, "Orbit Absolute obtained from date")
      
      
      puts "-----------------------------------------"
      
      
      ## error management for orbit ephemeris file not found
      
      val   = test.DateTime2OrbitAbsolute(\
                           "wrong_path/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF", \
                           strDate \
                           )   
      assert(val == -1, "Orbit Absolute failed due to wrong path to ROF")
      
   
   end
   ## ------------------------------------------------------

   ## Orbit and Angle to Time

   def test_PositionInOrbit

      puts
      puts "================================================"
      puts "DEC_UnitTests::#{__method__.to_s}"
      puts
   
      test     = MPL::Explorer_Orbit.new
   
      lOrbit      = 9572
      fAngleAnx   = 78.1299
      strROF      = "Predicted"

      val = test.PositionInOrbit("data/S2A_OPER_MPL_ORBPRE_20170420T072457_20170430T072457_0001.EOF", lOrbit, fAngleAnx)

      puts "-----------------------------------------"
      puts
      puts "PositionInOrbit (#{strROF}): Orbit => #{lOrbit} / Angle ANX => #{fAngleAnx} => #{val}"
      puts
      puts "-----------------------------------------"

      puts val
      puts self.str2date(val).to_time.usec

      timePRE = self.str2date(val).to_time

      lOrbit      = 9572
      fAngleAnx   = 78.1299
      strROF      = "Reference"

      val = test.PositionInOrbit("data/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF", lOrbit, fAngleAnx)

      puts "-----------------------------------------"
      puts
      puts "PositionInOrbit (#{strROF}): Orbit => #{lOrbit} / Angle ANX => #{fAngleAnx} => #{val}"
      puts
      puts "-----------------------------------------"
   
      assert(val != -1, "Orbit Angle converted to ANX Time")
            
      puts self.str2date(val).to_time.usec
      timeOSF = self.str2date(val).to_time

      puts
      puts
      puts "Difference between OSF and PRE #{(timeOSF - timePRE)} seconds"
      puts
      puts   


      ## error management for orbit ephemeris file not found 

      val = test.PositionInOrbit("wrong_path/S2A_OPER_MPL_ORBSCT_20150625T073255_99999999T999999_0006.EOF", lOrbit, fAngleAnx)
      assert(val == -1, "Orbit Angle to ANX failed due to wrong path to ROF")

  
      return
   end
   ## ------------------------------------------------------

end


