#!/usr/bin/env ruby

# == Synopsis
#
# This is the setROPStatus command line tool that manually changes the ROP Status.
# To be used only for testing purposes.
# 
#
# == Usage
# setROPStatus.rb   -R <numROP>   -s <STATUS>
#              --ROP       <nROP>
#              --status    STATUS_NEW
#                          STATUS_VALIDATED
#                          STATUS_CONSOLIDATED
#                          STATUS_TRANSFERRED
#                          STATUS_BEING_TRANSFERRED
#              --help      shows this help
#              --usage     shows the usage
#              --Debug     shows Debug info during the execution
#              --version   shows version number
# 
# == Author
# Deimos-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#


#########################################################################
#
# Ruby script setROPStatus
# 
# Written by DEIMOS Space S.L.   (bolf)
#
# Data Exchange Component -> Mission Management & Planning Facility
# 
# CVS:
#   $Id: setROPStatus.rb,v 1.1 2007/01/09 15:27:30 decdev Exp $
#
#########################################################################

require 'getoptlong'


require 'cuc/DirUtils'
require 'dec/DEC_DatabaseModel'
require 'dec/DEC_Environment'



# MAIN script function
def main

   include           CUC::DirUtils
   include           DEC
   
   @debugMode           = 0 
   @nROP                = 0
   @bResult             = false
   @status              = ""

   @bUsage              = false
   @bShowVersion        = false

   
   opts = GetoptLong.new(
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT],
     ["--ROP", "-R",            GetoptLong::REQUIRED_ARGUMENT],
     ["--status", "-s",         GetoptLong::REQUIRED_ARGUMENT]
     )
    
   
   begin 
      opts.each do |opt, arg|  
         case opt      
            when "--Debug"    then @debugMode = 1
            when "--version"  then @bShowVersion         = true
            when "--help"     then @bUsage               = true
            when "--ROP"      then @nROP                 = arg.to_i
            when "--status"   then @status               = arg.to_s                         
         end
      end
   rescue Exception
      exit(99)
   end
 
   if @bShowVersion == true then
      print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " Version: [#{DEC.class_variable_get(:@@version)}]", "\n\n")
      hRecord = DEC.class_variable_get(:@@change_record)
      hRecord.each_pair{|key, value|
         puts "#{key} => #{value}"
      }      
      exit(0)
   end
   
   if @bUsage then
      usage
      exit(0)
   end

   if self.checkEnvironmentEssential == false then
      puts
      self.printEnvironmentError
      puts
      exit(99)
   end 
 
   if @status == "" or @nROP == 0 then
      usage
      exit(99)
   end
      
   ret = true
   
   case @status
      when "STATUS_NEW"                then ret = InventoryROP.setROPStatus(@nROP, InventoryROP::STATUS_NEW)
      when "STATUS_VALIDATED"          then ret = InventoryROP.setROPStatus(@nROP, InventoryROP::STATUS_VALIDATED)
      when "STATUS_CONSOLIDATED"       then ret = InventoryROP.setROPStatus(@nROP, InventoryROP::STATUS_CONSOLIDATED)
      when "STATUS_TRANSFERRED"        then ret = InventoryROP.setROPStatus(@nROP, InventoryROP::STATUS_TRANSFERRED)
      when "STATUS_BEING_TRANSFERRED"  then ret = InventoryROP.setROPStatus(@nROP, InventoryROP::STATUS_BEING_TRANSFERRED)
      else
         puts "Ilegal --status option : #{@status}\n\n"
         exit(99)
   end

   if ret == false then
      puts "Could not set Status #{@status} to ROP #{@nROP} ! :-(" 
      puts
      exit(99)
   end
   exit(0)
end
#---------------------------------------------------------------------
#---------------------------------------------------------------------


#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = File.expand_path(__FILE__)   
   
   value = `#{"head -27 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
end
#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
