#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #SMTPClient module
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: SMTPClient.rb,v 1.2 2006/10/19 13:07:53 decdev Exp $
#
# Module Common Transfer Component
# This class is a wrapper of the email command line tool for sending emails.
# It is used email (www.cleancode.org) program instead of the ruby own built smtp module
# because of its easyness to add attachments.
#
#########################################################################


module CTC

class SMTPClient
      
   #--------------------------------------------------------------

   # Class constructor.
   # address (IN) : string with the from address mail.
   # host (IN) : string with the IP address or hostname
   # port (IN) : integer with port number
   def initialize(fromAddress,host, port, name="")
      @isDebugMode       = false
      @bAttached         = false
      @attachment        = Array.new
      @host              = host
      @port              = port
      checkModuleIntegrity
      @arrToAddress      = Array.new
      @arrContent        = Array.new
      @subject           = ""
      @fromAddress       = fromAddress
      @name              = ""
      if name != "" then
         @name = name
      else
         @name = "Data Exchange Component"
      end
   end
   #-------------------------------------------------------------
   
   # Add an address to @toAddress array
   def addToAddress(address)
      @arrToAddress << address
      if @isDebugMode == true then
         puts "Address #{address} added to Destinations"
      end
   end
   #-------------------------------------------------------------

   # Set Mail Subject
   def setMailSubject(subject)
      @subject = subject
      if @isDebugMode == true then
         puts "Mail Subject is : #{subject} added to Destinations"
      end
   end
   #-------------------------------------------------------------
   
   # Content of the outgoing mail is stored as an array of lines.
   def addLineToContent(line)
      line = %Q{#{line}\n}
      @arrContent << line
   end
   #-------------------------------------------------------------
   
   # Full path filename of the file to be attached in the mail
   def attach(filename_with_path)
      @bAttached = true
      @attachment << filename_with_path
   end
   #-------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "SMTPClient Debug Mode is on"
   end
   #-------------------------------------------------------------
   
   # Sends a mail with 
   def sendMail
      if @arrToAddress.empty? == true then
         puts "SMTPClient::sendMail Error : Destinations address is empty :-( \n\n"
         exit(99)
      end
      
      cmd = %Q{email -b -f #{@fromAddress} -n "#{@name}" -s "#{@subject}" -r #{@host} -p #{@port} -high-priority}
      
      # Set Quiet mode in the client
      if @isDebugMode == false then
         cmd = %Q{#{cmd} -q}
      end      
      
      # If there is any attachment
      if @bAttached == true then
         first = true
         @attachment.each{|x|
            if first == true then
               cmd   = %Q{#{cmd}  -a #{x}}
               first = false
            else
               cmd   = %Q{#{cmd},#{x}}
            end
         }
      end
      # Set Recipient(s)
      isFirst = true
      @arrToAddress.each{|x|
         if isFirst == true then
            cmd = %Q{#{cmd} #{x}}
            isFirst = false
         else
            cmd = %Q{#{cmd},#{x}}
         end
      }
      
      if @isDebugMode == true then
         puts cmd
      end    
      
      retVal = system(cmd)
      
      return retVal      
   end
   #-------------------------------------------------------------

private

   #-------------------------------------------------------------

   # Check that all needed to run is present
   def checkModuleIntegrity
      bDefined = true
      
      if !ENV['HOSTNAME'] then
         puts "\nHOSTNAME environment variable not defined !\n"
         bDefined = false
      end
      
      #check the commands needed
      
      isToolPresent = `which email`   
      
      if isToolPresent[0,1] != '/' then
        puts "\n\nSMTPClient::checkModuleIntegrity\n"
        puts "Fatal Error: email tool not present in PATH !!   :-(\n\n\n"
        bDefined = false
      end
      
      if bDefined == false then
        puts("SMTPClient::checkModuleIntegrity FAILED !\n\n")
        exit(99)
      end     
      
      @domain = ENV['HOSTNAME']
   end
   #-------------------------------------------------------------

end # class

end # module

