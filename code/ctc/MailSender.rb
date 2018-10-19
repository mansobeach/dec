#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #MailSender class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: MailSender.rb,v 1.9 2013/03/14 14:03:24 algs Exp $
#
# Module Common Transfer Component
# This class delivers text mails.
#
# This class creates and sends text mails.
#
#########################################################################

require 'net/smtp'
require 'cuc/DirUtils'


module CTC


class MailSender
    
   #--------------------------------------------------------------

   # Class constructor.
   # address (IN) : string with the from address mail.
   # host (IN) : string with the IP address or hostname
   # port (IN) : integer with port number
   def initialize(host, port, user, pass, isSecure, name="", subject="", body="")
#      puts "initialize MailSender ..."
      @isModuleOK        = false
      @isModuleChecked   = false
      @isDebugMode       = false
      @bConfigured       = false      
      checkModuleIntegrity
      @arrToAddress      = Array.new
      @arrContent     #   = Array.new
      @subject           = ""
      @host              = host
      @port              = port
      @user              = user
      @pass              = pass
      @isSecure          = isSecure
      @name              = name
      @subject           = subject
      @body              = body
      @optMail           = Hash.new
      @optMail[:server]       ||= host
      @optMail[:from]         ||= user
      @optMail[:from_alias]   ||= 'DEC/RPF Mailer'
      @optMail[:subject]      ||= "DEC/RPF Notification"
   end
   #-------------------------------------------------------------

   # Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "MailSender Debug Mode is on"
   end
   #-------------------------------------------------------------

   # Set Mail Subject
   def setMailSubject(subject)
      puts "MailSender::setMailSubject(#{subject})"
      @optMail[:subject]      = subject
#      smtpSubject = %Q{Subject: #{subject}}
#      @arrContent.unshift(smtpSubject)
      if @isDebugMode == true then
         puts "Mail Subject is : #{subject}"
      end
   end
   # -------------------------------------------------------------

   def buildMessage
      destination = @arrToAddress[0]
      
      @msg = <<END_OF_MESSAGE
From: #{@optMail[:from_alias]} <#{@optMail[:from]}>
To: <#{destination}>
Subject: #{@optMail[:subject]}

#{@arrContent}
END_OF_MESSAGE

   end
   # -------------------------------------------------------------

   # #{@optMail[:body]}
   
   def init
      @bConfigured = true
   end
   
   # -------------------------------------------------------------

   def addLineToContent(line)
      # line = %Q{#{line}\n}
      # line = %Q{#{line}}
      # @arrContent << line
      @arrContent = %Q{#{@arrContent}\n#{line}}
   end

   # -------------------------------------------------------------
   
   
   # Sends a mail with 
   def sendMail
   
      # @optMail[:body]        ||= @arrContent
      
      if @bConfigured == false then
         puts "MailSender::sendMail Internal Error : init method must be invoked first !! :-O \n\n"
         exit(99)
      end      

      if @isDebugMode == true then
         puts "MailSender::sendMail debug"
         puts "--------------------"
         puts @optMail[:server]
         puts "--------------------"
         puts @optMail[:from]
         puts "--------------------"
         puts @msg
         puts "--------------------"
         puts @arrToAddress
         puts "--------------------"           
      end


      Net::SMTP.start(@optMail[:server]) do |smtp|
         smtp.send_message @msg, @optMail[:from], @arrToAddress[0]
      end

      return true
   end
   #-------------------------------------------------------------
   
   def init_old
      begin
         
         puts
         puts @isSecure
         puts @isSecure.class
         puts
         
         if @isSecure == true #ssl/tls active 
            @smtpClient        = Net::SMTP.new(@host, @port)
            #@smtpClient.enable_starttls_auto
            @smtpClient.enable_starttls
            @smtpClient.start(@domain, @user, @pass, :plain)
         else
            @smtpClient        = Net::SMTP.start(@host, @port, @domain)
         end
      rescue Exception => e
          if @isDebugMode == true
            puts
            puts "SMTP Connection Refused ! =-("
 	         puts "Host   -> #{@host}"
 	         puts "Port   -> #{@port}"
 	         puts "Domain -> #{@domain}"
             puts
          else
             puts
             puts "MailSender::init could not connect to #{@host}:#{@port}"
          end
          puts
          puts e.backtrace
          puts
          return false
       end
      @bConfigured = true
      return true
   end
   # -------------------------------------------------------------
   
   # Add an address to @toAddress array
   def addToAddress(address)
      @arrToAddress << address
      if @isDebugMode == true then
         puts "Address #{address} added to Destinations"
      end
   end
   # -------------------------------------------------------------



   def attachedMail(subject, filename)

      # Read a file and encode it into base64 format
         filecontent = File.read(filename)
         encodedcontent = [filecontent].pack("m")   # base64
         if @subject != '' and @subject != nil and FileTest.exists?(CUC::DirUtils.expandPathValue(@subject)) then
            subject=`#{@subject}`
         end
         marker = "MARKER"

         if @body != '' and @body != nil and FileTest.exists?(CUC::DirUtils.expandPathValue(@body)) then
               bdy=`#{@body}`
body =<<EOF
#{bdy}
File #{File.basename(filename)} attached
EOF
else
body =<<EOF
File #{File.basename(filename)} attached
EOF
end
      # Define the main headers.
part1 =<<EOF
From: #{@name}
To: #{@arrToAddress}
Subject: #{subject}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

      # Define the message action
part2 =<<EOF
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}
--#{marker}
EOF

      # Define the attachment section
part3 =<<EOF
Content-Type: multipart/mixed; name=\"#{File.basename(filename)}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{File.basename(filename)}"

#{encodedcontent}
--#{marker}--
EOF

      @arrContent = part1 + part2 + part3
   end
   #-------------------------------------------------------------




   def attachedMailSeveralFiles(subject, arrFiles)

      i=0
      marker = "MARKER"
      if @subject != '' and @subject != nil and FileTest.exists?(CUC::DirUtils.expandPathValue(@subject)) then
            subject=`#{@subject}`
      end
      if @body != '' and @body != nil and FileTest.exists?(CUC::DirUtils.expandPathValue(@body)) then
           bdy=`#{@body}`
           str="#{bdy}\n"
      else
         str=''
      end

      while i < arrFiles.length do
         str= str + "#{arrFiles[i]} File attached\n"
         i=i+1
      end

body =<<EOF
#{str}
EOF

      # Define the main headers.
part1 =<<EOF
From: #{@name}
To: #{@arrToAddress}
Subject: #{subject}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
EOF

      # Define the message action
part2 =<<EOF
Content-Type: text/plain
Content-Transfer-Encoding:8bit

#{body}
--#{marker}
EOF
 

# Define the attachment section
num= arrFiles.length
i=0
part3, aux=""
while i < num do

      # Read a file and encode it into base64 format
         filecontent = File.read(arrFiles[i])
         encodedcontent = [filecontent].pack("m")   # base64

if i == num-1 then
aux =<<EOF
Content-Type: multipart/mixed; name=\"#{arrFiles[i]}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{arrFiles[i]}"
#{encodedcontent}
--#{marker}--
EOF
else
aux =<<EOF
Content-Type: multipart/mixed; name=\"#{arrFiles[i]}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{arrFiles[i]}"
#{encodedcontent}
--#{marker}
EOF
end
i=i+1

part3= part3 + aux
end #while

      @arrContent = part1 + part2 + part3

   end #attachedMailSeveralFiles
   
   # Content of the outgoing mail is stored as an array of lines.
   
   #-------------------------------------------------------------
   
   
   # Sends a mail with 
   def sendMail_old
      if @bConfigured == false then
         puts "MailSender::sendMail Internal Error : init method must be invoked first !! :-O \n\n"
         exit(99)
      end      
      if @arrToAddress.empty? == true then
         puts "MailSender::sendMail Error : Destinations address is empty :-( \n\n"
         exit(99)
      end

      begin
      
      puts "CONTENET #{@arrContent}"
     
      arrKK = Array.new
     
      @arrContent.each{|kk| arrKK << kk.chop}
     
         #should use @user instead of @fromAddress
         # @smtpClient.send_mail(@arrContent, @fromAddress, @arrToAddress)
         @smtpClient.send_mail(arrKK, @fromAddress, @arrToAddress)
      rescue Exception => e
         #if @isDebugMode then 
         puts "Error NET::SMTP #{e}" 
         #end
         return false
      end

      return true
   end
   #-------------------------------------------------------------

   def newMail
      @arrContent=Array.new
#      @fromAddress=""
#      @arrToAddress=""
   end

private

   @isModuleOK        = false
   @isModuleChecked   = false
   @isDebugMode       = false      

   #-------------------------------------------------------------

   # Check that all needed to run is present
   def checkModuleIntegrity
      bDefined = true
      if !ENV['HOSTNAME'] then
         puts "\nHOSTNAME environment variable not defined !\n"
         bDefined = false
      end
      
      if bDefined == false then
        puts("MailSender::checkModuleIntegrity FAILED !\n\n")
        exit(99)
      end      
      @domain = ENV['HOSTNAME']
   end
   #-------------------------------------------------------------


   #=============================================================
end # class

end # module
