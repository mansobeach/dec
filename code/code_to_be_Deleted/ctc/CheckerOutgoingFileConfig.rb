#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #CheckerOutgoingFileConfig class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# == Data Exchange Component -> Common Transfer Component
# 
# CVS:$Id: CheckerOutgoingFileConfig.rb,v 1.7 2007/12/19 06:08:03 decdev Exp $
#
# === module Common Transfer Component (CTC)
# This class is in charge of verify that the Configuration
# for a given Outgoing File-type in ft_outgoing_file.xml is correct.
#
# ==== This class is in charge of verify that the Configuration
# ==== for a given Outgoing file-type in ft_outgoing_files.xml is correct.
#
# ==== It checks that defined Interface(s) for such file-type exist in
# ==== the configuration file interfaces.xml
#
#########################################################################

require 'ctc/ReadInterfaceConfig'
require 'ctc/ReadFileSource'
require 'cuc/PackageUtils'

module CTC

class CheckerOutgoingFileConfig
   
   include CTC
   include CUC::PackageUtils
   #--------------------------------------------------------------

   # Class constructor.
   # IN (string) configuration outgoing file-type to be checked.
   def initialize(filetype)
#     puts "initialize CheckerOutgoingFileConfig ..."
      checkModuleIntegrity
      @ftReadConf = ReadInterfaceConfig.instance
      @ftReadFile = ReadFileDestination.instance
      @filetype   = filetype
   end
   #-------------------------------------------------------------
   
   # ==== Main method of the class
   # ==== It returns a boolean True whether checks are OK. False otherwise.
   def check
      bRet = checkTargetEntities
      if bRet == true then
         bRet = checkCompressMethod
      else
         checkCompressMethod
      end
      return bRet
   end
   #-------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerOutgoingFileConfig debug mode is on"
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
   
   def checkTargetEntities      
     bReturn          = true     
     arrClients       = @ftReadConf.getAllExternalMnemonics
     arrDissEntities  = @ftReadFile.getEntitiesReceivingOutgoingFile(@filetype)
          
     arrDissEntities.each{|x|
         if arrClients.include?(x) == false then
            puts "Outgoing Type #{@filetype} is Sent to #{x}"
            puts "#{x} is not a configured I/F ! :-("
            puts
            bReturn = false
            return bReturn
         end
         # Check whether there is a proper mail account configured
         arrDelMethods = @ftReadFile.getDeliveryMethods(x, @filetype)
         
         arrAllowedMethods = @ftReadFile.getAllowedDeliveryMethods
       
         arrDelMethods.each{|method|
            
            if arrAllowedMethods.include?(method) == false then
               puts "Delivery method #{method} for #{@filetype} is not recognized ! :-("
               bReturn = false
            end

            if method == "email" or method == "mailbody" then
               listMail = @ftReadConf.getMailList(x)
               if listMail == nil then
                  puts "Missing Email address(es) for #{x} I/F."
                  puts "Email delivery of #{@filetype} WILL FAIL ! :-("
                  puts
                  bReturn = false
               else
                  if listMail.length == 0 then
                     puts "Missing Email address(es) for #{x} I/F."
                     puts "Email delivery of #{@filetype} WILL FAIL ! :-("
                     puts
                     bReturn = false
                  end               
               end
            end
         }
     }     
     return bReturn
   end
   #-------------------------------------------------------------   

   def checkCompressMethod
      arrDissEntities = @ftReadFile.getEntitiesReceivingOutgoingFile(@filetype)
      
      arrDissEntities.each{|x|
         compressMethod = @ftReadFile.getCompressMethod(x, @filetype)
        
         if CompressMethods.include?(compressMethod) == false then
            puts
            puts "Compress Method #{compressMethod} for #{@filetype} when sending to #{x} is not recognized ! :-("
            puts
            bReturn = false
         end
      }
      return true
   end
   #-------------------------------------------------------------

end # class

end # module
