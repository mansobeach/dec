#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that connects to Internet to obtain
# the public IP address of the host it is running
# 
#
# == Usage
# getPublicIP.rb

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

require 'rubygems'
require 'optparse'



require 'e2e/ReadConfigE2ESPM'





# MAIN script function
def main
   cmdParser      = nil
   @filename      = ""
   @isDebugMode   = false
      
   # parser = E2E::ReadConfigE2ESPM.new("/Users/borja/Projects/dec/code/e2e/data.cfg")
   # parser = E2E::ReadConfigE2ESPM.new("/Users/borja/Projects/dec/code/e2e/ESRIN.DFEP_Report.SDM.cfg")                
   parser = E2E::ReadConfigE2ESPM.new("/Users/borja/Projects/dec/code/e2e/ESRIN.DPC_Report.SDM.cfg")                    
                                       
   exit
   

   # ---------------------------------------------


   # ---------------------------------------------


   exit(0)
end
#-------------------------------------------------------------


#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
