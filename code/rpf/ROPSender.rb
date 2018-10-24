#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #ROPSender class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Exchange Component -> Mission Management & Planning Facility
# 
# CVS:
#  $Id: ROPSender.rb,v 1.7 2008/07/03 11:34:58 decdev Exp $
#
#########################################################################

require 'singleton'

require 'cuc/DirUtils'
require 'cuc/CommandLauncher'
require 'cuc/Log4rLoggerFactory'


#require 'FT_ReportHandler'

module RPF


# Main class for ROP transfer
class ROPSender

   include Singleton
   include CUC::DirUtils
   include CUC::CommandLauncher
   #-------------------------------------------------------------
   
   # Class constructor. It is called only once as this is a singleton class
   def initialize
   
      require 'dec/DEC_DatabaseModel'
   
      @@isModuleOK        = false
      @@isModuleChecked   = false
      @isDebugMode        = false
      @@nROP              = nil
      @@reportName        = nil
      checkModuleIntegrity

      # initialize logger
      loggerFactory = CUC::Log4rLoggerFactory.new("ROPSender", "#{ENV['DEC_CONFIG']}/dec_log_config.xml")
      if @isDebugMode then
         loggerFactory.setDebugMode
      end
      @logger = loggerFactory.getLogger
      if @logger == nil then
         puts
			puts "Error in ROPSender::initialize"
			puts "Could not set up logging system !  :-("
         puts "Check DEC logs configuration under \"#{ENV['DEC_CONFIG']}/dec_log_config.xml\"" 
			puts
			puts
			exit(99)
      end

   end   
   #-------------------------------------------------------------
   
   # Send the ROP 
   # - nROP (IN): ROP version to be sent
   # Return value
   # * true if successful.
   # * false if for any reason the ROP has not been sent.   
   def sendROP(nROP)     
      
      # Check ROP existence
      aROP = InventoryROP.where(ROP_ID: nROP)
      
      if aROP == nil or aROP.empty? == true then
         puts "\nROP #{nROP} does not exist  !    :-(\n\n"
         return false
      end     
          
      # Check ROP Transferability         
      if aROP.to_a[0].TRANSFERABILITY != InventoryROP::TRANSFERABLE then
         puts "\nROP #{nROP} is not Transferable  !\n" 
         return false
      end
     
      # Check ROP Status
      if aROP.to_a[0].STATUS != InventoryROP::STATUS_CONSOLIDATED then
         puts "\nROP #{nROP} is not Consolidated  !\n" 
         return false
      end

      # start the transfer
      @@nROP = nROP

      # Retrieve Files to be delivered in the ROP
      cmd = %Q{getRPFFilesToBeTransferred.rb -R #{@@nROP} -V}
      if @isDebugMode == true then
         cmd = %Q{#{cmd} -D}
         puts cmd
      end
      bRet = execute(cmd, "sendROP", false, @isDebugMode)

      if bRet == false then
         @logger.error("Error in getRPFFilesToBeTransferred")
         @logger.error("Could not retrieve files to be transferred from Archive")
         exit(99)
      end

      # Deliver files via DDC
      cmd = %Q{decDeliverFiles -O -N -p "ROP_ID:#{nROP}"}
      if @isDebugMode == true then
         cmd = %Q{#{cmd} -D}
         puts cmd
      end
      bRet = system(cmd)
      #bRet = execute(cmd, "sendROP", false, @isDebugMode)

      if bRet == false then
         @logger.error("Error in decDeliverFiles")
         @logger.error("Could not deliver files to the Interface")
         return false
      end

      # Set ROP Status to Transferred & Update Transferable Flag
      InventoryROP.setTransferred(nROP)

      return true

   end
   #-------------------------------------------------------------
   
   def isTransferableROP?(nROP)
      # Check ROP existence
      aROP = InventoryROP.where(ROP_ID: nROP)
      
      if aROP == nil or aROP.empty? == true then
         puts "\nROP #{nROP} does not exist  !    :-(\n\n"
         return false
      end     
          
      # Check ROP Transferability         
      if aROP.to_a[0].TRANSFERABILITY != InventoryROP::TRANSFERABLE then
         # puts "\nROP #{nROP} is not Transferable  ! :-(\n" 
         return false
      end
      return true
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ROPSender debug mode is on"
   end
   #-------------------------------------------------------------

   # Lock File Transfer
   def lockFTActions
      lock = InventoryParams.all.where(KEYWORD: "FILE_TRANSFER_LOCK")
      if lock == nil then
         puts "Error in ROPSender::lockFTActions ! =:-0"
         puts "FILE_TRANSFER_LOCK must exists in PARAMETERS_TB"
         exit(99)
      end

      puts
      puts lock.empty?
      puts

      # if lock.VALUE == "0" then
      
      if lock.empty? == false then         
         InventoryParams.where(KEYWORD: "FILE_TRANSFER_LOCK").update_all(VALUE: '1')
         return true
      else
         return false
      end
   end
   #-------------------------------------------------------------

   def unlockFTActions
      lock = InventoryParams.all.where(KEYWORD: "FILE_TRANSFER_LOCK")
      if lock == nil then
         puts "Error in ROPSender::lockFTActions ! =:-0"
         puts "FILE_TRANSFER_LOCK must exists in PARAMETERS_TB"
         exit(99)
      end

      puts
      puts lock.empty?
      puts

      # if lock.VALUE == "0" then
      
      if lock.empty? == false then         
         InventoryParams.where(KEYWORD: "FILE_TRANSFER_LOCK").update_all(VALUE: '0')
         return true
      else
         return false
      end
   end
   #-------------------------------------------------------------

private

   @@nROP              = nil
   #-------------------------------------------------------------
   
   # Check that everything needed is present.
   def checkModuleIntegrity
      return
   end
   #------------------------------------------------------------- 
   
   #Open Logger if this file has been created
   def createLog
      report=FT_ReportHandler.new(@@nROP)
      report.headerReport
      reportName=report.getOutReportName
      @logger = Logger.new(reportName,true,@entity)
   end
   #------------------------------------------------------------- 
   
end

end # module
