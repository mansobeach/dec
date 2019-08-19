#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #CheckerOutgoingFileConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component
# 
# Git:$Id: CheckerOutgoingFileConfig.rb,v 1.9 2009/10/21 13:36:46 algs Exp $
#
# This class is in charge of verify that the Configuration
# for a given Outgoing File-type in dec_outgoing_file.xml is correct.
#
# ==== This class is in charge of verify that the Configuration
# ==== for a given Outgoing file-type in dec_outgoing_files.xml is correct.
#
# ==== It checks that defined Interface(s) for such file-type exist in
# ==== the configuration file dec_interfaces.xml
#
#########################################################################

require 'cuc/PackageUtils'

require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'

module DEC

class CheckerOutgoingFileConfig
   
   include CTC
   include CUC::PackageUtils
   
   ## -----------------------------------------------------------

   ## Class constructor.
   ## IN (string) configuration outgoing file-type to be checked.
   def initialize(filetype, wildcard = false)
#     puts "initialize CheckerOutgoingFileConfig ..."
      checkModuleIntegrity
      @ftReadConf = ReadInterfaceConfig.instance
      @ftReadFile = ReadConfigOutgoing.instance
      @filetype   = filetype
      @wildcard   = wildcard
   end
   ## -----------------------------------------------------------
   
   ## Main method of the class
   ## It returns a boolean True whether checks are OK. False otherwise.
   def check
      bRet = checkTargetEntities
      if bRet == true then
         bRet = checkCompressMethod
      else
         checkCompressMethod
      end
      return bRet
   end
   ## -----------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerOutgoingFileConfig debug mode is on"
   end
   ## -----------------------------------------------------------

private

   @isDebugMode       = false      
   @filetype          = nil

   ## -----------------------------------------------------------

   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
   end
   ## -----------------------------------------------------------
   
   def checkTargetEntities      
     bReturn          = true     
     arrClients       = @ftReadConf.getAllExternalMnemonics
     arrDissEntities  = @ftReadFile.getEntitiesReceivingOutgoingFile(@filetype)
          
     arrDissEntities.each{|x|
         if arrClients.include?(x[:mnemonic]) == false then
            puts "Error: Outgoing Type #{@filetype} is Sent to #{x[:mnemonic]}: #{x[:mnemonic]} is not a configured I/F ! :-("
            puts
            return false
         end

         arrDelMethods     = @ftReadFile.getDeliveryMethods(x[:mnemonic], @filetype)
         arrAllowedMethods = @ftReadFile.getAllowedDeliveryMethods

         arrDelMethods.each{|method|
            
            if arrAllowedMethods.include?(method) == false then
               puts "Delivery method #{method} for #{@filetype} is not recognized ! :-("
               bReturn = false
            end

            if method == "email" or method == "mailbody" then
               listMail = @ftReadConf.getMailList(x[:mnemonic])
               if listMail == nil then
                  puts "Error: Missing Email address(es) for #{x[:mnemonic]} I/F. Email delivery of #{@filetype} will fail ! :-("
                  puts
                  bReturn = false
               else
                  if listMail.length == 0 then
                     puts "Error: Missing Email address(es) for #{x[:mnemonic]} I/F. Email delivery of #{@filetype} will fail ! :-("
                     puts
                     bReturn = false
                  end               
               end
            end
         }
     }     
     return bReturn
   end
   ## -----------------------------------------------------------  

   def checkCompressMethod
      arrDissEntities = @ftReadFile.getEntitiesReceivingOutgoingFile(@filetype)
      
      arrDissEntities.each{|x|

         compressMethod = @ftReadFile.getCompressMethod(x[:mnemonic], @filetype)

         if CompressMethods.include?(compressMethod) == false then
            puts
            puts "Compress Method #{compressMethod} for #{@filetype} when sending to #{x[:mnemonic]} is not recognized ! :-("
            puts
            bReturn = false
         end
      }
      return true
   end
   ## -----------------------------------------------------------

end # class

end # module
