#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #DCC_MailParser class
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#   $Id: MailParser.rb,v 1.4 2007/06/01 10:34:57 decdev Exp $
#
#########################################################################

   #- This class processes all the incoming mails to the DCC email account.
	#- It extracts the notification mails

@@CONTENT_TYPE_TEXT_PLAIN   = "TEXT/PLAIN"
@@CONTENT_TYPE_TEXT_XML     = "TEXT/XML"
@@CONTENT_TYPE_MPART_MIXED  = "MULTIPART/MIXED"
@@CONTENT_TYPE_BINARY_PDF   = "APPLICATION/PDF"
@@CONTENT_TYPE_BINARY       = "APPLICATION/OCTET-STREAM"
@@CONTENT_TYPE_TEXT         = "TEXT/PLAIN"

module CTC

class MailParser


   attr_reader :returnPath, :date, :to, :subject, :body, :contentType, :contentTransferEncoding
	attr_reader :isFile, :isBinary, :filename
   #-------------------------------------------------------------
   
   # Class constructor.
   # IN String: mail - the content of the mail to be processed 
   def initialize(debugMode = false)
      @isDebugMode = debugMode
		checkModuleIntegrity
      defineStructs
   end   
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "DCC_MailParser debug mode is on"
   end
   #-------------------------------------------------------------
   
	# This method parses the string containing the mail
	def parse(amail)
      @bMixedMultiPart  = false
	   @eContentType     = false
		bStartBody        = false
      bEndBody          = false
      bExtractFilename  = false
      bFirstLine        = true
      bFirstContent     = true
      bIsBinary         = false
      @arrContent       = Array.new
	   @body             = Array.new
		
		amail.each_line{|line|
				   		         
         if @isDebugMode == true then
			   puts line
         end

         #---------------------------------------------
         # Start Processing Mail Body

		   if bStartBody == true then
            if bFirstLine == true then
#                if line.chop == "" then
#                   puts line
#                else
#                   bFirstLine = false
#                end       
               bFirstLine = false
               next
            end

            if @bMixedMultiPart == true then
              
               if @boundary == nil then
                  @body << line
                  next
               end

               if line.include?(@boundary) == false then
#                   puts "========================================================"
#                   puts "busco pero no encuentro boundary"
#                   puts "#{@boundary}    <- BOUNDARY "
#                   puts line
#                   puts "========================================================"
                  @body << line
                  next
               else
                  if @isDebugMode == true then
                     puts "Boundary detected -> end of body"
                  end
                  #@body.delete_at(-1)
                  bStartBody = false
                  @arrContent << fillContentStruct(@body, true, @isBinary, @filename)
               end
            else
               @body << line
               if @isDebugMode == true then
                  # puts line
               end
            end
			end

			if line.slice(0,12) == "Return-Path:" then
			   @returnPath = line.slice(12, line.length).lstrip
			end
		   
			if line.slice(0,5) == "Date:" then
			   @date = line.slice(5, line.length).lstrip
			end
			
			if line.slice(0,3) == "To:" then
			   @to = line.slice(3, line.length).lstrip
			end

		   if line.slice(0,8) == "Subject:" then
			   @subject = line.slice(8, line.length).lstrip
			end

			bContentFile = false

		 	if line.slice(0,13).upcase == "CONTENT-TYPE:" then
		 	   @contentType = line.slice(13, line.length).lstrip
			   
            ret = processContentType
            
            if ret == true then
               bContentFile = true
               # bExtractFilename = true
               next
            end
			end
         
			# process the boundary
			if @eContentType != false or @bMixedMultiPart == true then
#                           if line.slice(0,14) == "--------------" then
#                              @boundary = line.chop
#                              if @isDebugMode == true then
#                                 puts "Boundary detected #{@boundary}"
#                              end
#                              next
#                           end        
            		   if line.include?("boundary=") then
 #                             arrLines  = line.split("\"")
                              arrLines = line.split("boundary=")
                              @boundary = arrLines[1].chop
                              @boundary = @boundary.gsub("-", "")
                              @boundary = @boundary.gsub("\"", "")
                              if @isDebugMode == true then
                                 puts "Boundary detected XXXX #{@boundary}"
			                     end
                     end
         end         

			if line.slice(0,20) == "Content-Disposition:" then
            @contentDisposition = line.slice(20, line.length).lstrip
                           
            processContentDisposition
                           
            if @contentDisposition.chop != "inline" then
			      
               # puts "File Attachment"               
               
               if line.include?("filename")== true then
				      arrTemp = line.split("=")
				      aStr    = arrTemp[1]
				      aStr    = aStr.delete("\"")
				      @filename  = aStr.to_s.chop
				      bStartBody = true
				      @isFile    = true
			      end
			      bExtractFilename = true
               @bIsFile = true
               
               next
            else
               if bContentFile == true then
                  bExtractFilename = true
                  @bIsFile = true
                  next
               else
               end
            end
			end	
         
         if bExtractFilename == true then # or @bIsFile == true then
            @bIsFile = false
            bExtractFilename = false            
            
            if line.include?("name") == true then
               strTemp = line.split("name")[1]
               # Patch 26/07/2006 ESRIN On-Site System Tests
               arrLines   = strTemp.split("\"")
               @isFile    = true
               if arrLines.length > 1 then
                  @filename = arrLines[1]
               else
                  arrLines = strTemp.split("=")
                  arrLines = arrLines[1]
                  arrLines = arrLines.split(";")
                  @filename = arrLines[0]
               end
               bStartBody = true
               if @isDebugMode == true then
                  puts "Filename extracted -> #{@filename}"
                  puts "Begin of mail body"
               end

            end

         end
         
		
			
			if line.slice(0,26) == "Content-Transfer-Encoding:" then
			   @contentTransferEncoding = line.slice(26, line.length).lstrip
# 				if @eContentType == @@CONTENT_TYPE_TEXT_PLAIN and bFirstContent == true
#                puts "comienza el cuerpo"
#                bStartBody = true
#                bFirstContent = false
#             end
			end
		}      
      @mail = fillMailStruct(@arrContent, @subject, @to, @date, @returnPath)
      
   end
	
private

   #-------------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity
      return
	end
   #-------------------------------------------------------------
	
   # This method defines all the structs used
	
   def defineStructs
	   Struct.new("Content", :arrBody, :isfile, :isbinary, :filename)
      Struct.new("Mail", :arrContent, :subject, :to, :date, :returnPath)
	end
	#-------------------------------------------------------------
	
	# This method processes the MIME Content-Disposition field
	def processContentDisposition
           arrDisposition = @contentDisposition.split(";")
           return arrDisposition
	end
	#-------------------------------------------------------------
	
	# This method processes the MIME Content-Type field
	def processContentType
	   arrContent = @contentType.split(";")
	   if arrContent[0].upcase == "TEXT/PLAIN" then
	      @eContentType = @@CONTENT_TYPE_TEXT_PLAIN
              @bIsFile   = false
              @bIsBinary = false
              return       
           end
		
           if arrContent[0].upcase == "TEXT/XML" then
              # puts "es FILE"
              @eContentType = @@CONTENT_TYPE_TEXT_XML
              @bIsFile   = true
              @bIsBinary = false
             return true
            end

		if arrContent[0].upcase == "MULTIPART/MIXED" then
                   # puts "bMultiPart !!"
                   @bMixedMultiPart = true
		   @eContentType    = @@CONTENT_TYPE_MPART_MIXED
                   @bIsFile   = false
                   @bIsBinary = false         
                   return         
		end
		
      if arrContent[0].upcase == "APPLICATION/PDF" then
		   @eContentType = @@CONTENT_TYPE_TEXT_XML
         @bIsFile   = true
         @bIsBinary = false
         return
      end
      
      if arrContent[0].upcase == "APPLICATION/OCTET-STREAM" then
		   @eContentType = @@CONTENT_TYPE_BINARY
         @bIsFile   = true
         @bIsBinary = true
         return
      end
      
      if arrContent[0].upcase.slice(0, 11) == "APPLICATION" then
		   @eContentType = @@CONTENT_TYPE_BINARY
         @bIsFile   = true
         @bIsBinary = true
         return
      end

      if arrContent[0].upcase.slice(0, 4) == "TEXT" then
		   @eContentType = @@CONTENT_TYPE_TEXT
         @bIsFile   = true
         @bIsBinary = true
         return
      end
      
      # message/rfc822
      @bIsFile   = false
      @bIsBinary = false

#       # Content Type not recognized
#       puts "DCC_MailParser::processContentType"
#       puts arrContent[0]
      
	end
   #-------------------------------------------------------------
	
	# This method processes the body
	def processBody
	end
	#-------------------------------------------------------------
	
   # Fill a Mail struct
   # - arrContent (IN): array of Contents
   # - subject (IN): mail subject
   # - to (IN): mail destinatary
   # - date (IN): date of reception
   # - returnPath (IN): path to sender
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.   
   def fillMailStruct(arrContent, subject, to, date, returnPath)
      mail = Struct::Mail.new(arrContent,
                              subject,
                              to,
                              date,
                              returnPath)
      return mail
   end
   #-------------------------------------------------------------

   # Fill a Content struct
   # - arrBody (IN): array of lines that conform the body of the language
   # - isFile (IN): boolean flag pointing that the body is a file or not
   # - isBinary (IN): boolean flag pointing that the body is binary
   # - filename (IN): string containing the filename
   # - returnPath (IN): path to sender
   # There is only one point in the class where all dynamic structs 
   # are filled so that it is easier to update/modify the I/F.      
   def fillContentStruct(body, isFile, isBinary, filename)
      content = Struct::Content.new(body,
                              isFile,
                              isBinary,
                              filename)
      return content  
   end
   #-------------------------------------------------------------
   
end

end
