#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #CheckerIncomingFileConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: CheckerIncomingFileConfig.rb,v 1.7 2009/10/21 13:36:46 algs Exp $
#
# === module Common Transfer Component (CTC)
# This class is in charge of verify that the Configuration
# for a given Incoming File in ft_incoming_file.xml is correct.
#
# ==== It checks that Interface(s) defined for a given file-type | file wildcard 
# ==== in ft_incoming_files.xml exist in interfaces.xml config file.
#
#########################################################################

require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileSource'


module CTC

class CheckerIncomingFileConfig
       
   #--------------------------------------------------------------

   # Class constructor.
   # IN (string) Incoming file-type | wildcard to be checked.
   def initialize(filetype)
#     puts "initialize CheckerIncomingFileConfig ..."
      checkModuleIntegrity
      @ftReadConf = ReadInterfaceConfig.instance
      @ftReadFile = ReadFileSource.instance
      @filetype   = filetype
   end
   #-------------------------------------------------------------
   
   # ==== Main method of the class
   # ==== It returns a boolean True whether checks are OK. False otherwise.
   def check
      return checkDisseminationEntities
   end
   #-------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerIncomingFileConfig debug mode is on"
   end
   #-------------------------------------------------------------

private

   @isDebugMode       = false      
   @filetype          = nil

   #-------------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   #-------------------------------------------------------------

   # Method that perform check
   def checkDisseminationEntities      
      bReturn             = true
      arrSenderEntities   = Array.new
      if @filetype.include?("*") == true or @filetype.include?("?") == true
         arrSenderEntities   = @ftReadFile.getEntitiesSendingIncomingFile(@filetype) 
      else
         arrSenderEntities   = @ftReadFile.getEntitiesSendingIncomingFileName(@filetype)
      end

      arrSenderEntities   = @ftReadFile.getEntitiesSendingIncomingFile(@filetype)  
      arrExternalEntities = @ftReadConf.getAllExternalMnemonics  
      arrSenderEntities.each{|x|
         if arrExternalEntities.include?(x) == false then
            puts
            puts "Error: Incoming Type #{@filetype} Received from #{x}: #{x} is not a configured I/F ! :-("
            puts
            bReturn = false
        end
     }
     return bReturn
   end
   #-------------------------------------------------------------

end # class

end # module

