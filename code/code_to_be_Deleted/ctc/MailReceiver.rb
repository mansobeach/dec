#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MailReceiver class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: MailReceiver.rb,v 1.2 2006/10/17 09:48:49 decdev Exp $
#
# Module Common Transfer Component
# Class for receiving mails.
#
#########################################################################

require 'net/pop'


module CTC

class MailReceiver
	 
   #--------------------------------------------------------------

   # Class constructor.
   # host (IN) : string with the IP address or hostname
   # port (IN) : integer with port number
	# user (IN) : string with the username
	# pass (IN) : string with the password
   def initialize(host, port, user, pass)
      @isDebugMode       = false
      @bConfigured       = false      
      @host              = host
      @port              = port
      @user              = user
		@pass              = pass
      checkModuleIntegrity
   end
   #-------------------------------------------------------------
   
	# This method starts the POP connection.
   def init
	   @popClient = Net::POP3.new(@host)
      begin
         @popClient.start(@user, @pass)
      rescue Exception
		   puts
         puts "POP3 Connection Refused ! =-("
	      puts "Host   -> #{@host}"
	      puts "Port   -> #{@port}"
	      puts "User   -> #{@user}"
			puts "Pass   -> XXXXX"
         return false
      end
      @bConfigured = true
      return true
   end
   #-------------------------------------------------------------
   
   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "MailReceiver Debug Mode is on"
   end
   #-------------------------------------------------------------
   
	# Is there mail ?
	# This method must be invoked after the init method
	def mail?
	   if @bConfigured == false then
		   puts "Error in MailReceiver::mail?"
			puts
			exit(99)
		end
		return @popClient.mails.empty?
	end
	#-------------------------------------------------------------
	
   # Retrieve & Delete all mails in the server 
   def getAllMails(bDelete = false)
	   arrMails = Array.new
	   @popClient.finish
		Net::POP3.start(@host, @port.to_i, @user, @pass) do |op|
         op.each_mail{|m|			
			arrMails << m.pop
			   if bDelete == true then
				   m.delete
				end
			}
      end		
		return arrMails
   end
   #-------------------------------------------------------------

private

   @isDebugMode       = false      

   #-------------------------------------------------------------

   # Check that all needed to run is present
   def checkModuleIntegrity
	   return
   end
   #-------------------------------------------------------------

end # class

end # module


