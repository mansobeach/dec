#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MINARC_TestCases class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Mini Archive Component (MinArc)
# 
# CVS: $Id: MINARC_DatabaseModel.rb,v 1.12 2008/10/10 16:18:30 decdev Exp $
#
# module MINARC
#
#########################################################################

require 'rubygems'
require 'test/unit'

require 'cuc/DirUtils'


class TestCaseStore < Test::Unit::TestCase

   include CUC::DirUtils
   
   #--------------------------------------------------------

   def setup
      ENV['MINARC_ARCHIVE_ROOT']    = "#{ENV['HOME']}/Sandbox/minarc/archive_root"
      ENV['MINARC_ARCHIVE_ERROR']   = "#{ENV['HOME']}/Sandbox/minarc/load"
      ENV['MINARC_DATABASE_NAME']   = "#{ENV['HOME']}/Sandbox/minarc/inv/minarc_inventory.db"
      
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
      cmd = "manageDB.rb -d"
      ret = system(cmd)
      
      if ret == false then
         puts "Error when dropping the minarc inventory ! :-("
         puts
         exit(99)
      end

   end
   #--------------------------------------------------------

   def test_store
      cmd = "minArcStore -t S2PDGS -f #{@file}"
      puts cmd
      assert(system(cmd), "minArcStore")
   end
   #--------------------------------------------------------


   #-------------------------------------------------------------



   #-------------------------------------------------------------

end


#=====================================================================


#-----------------------------------------------------------


