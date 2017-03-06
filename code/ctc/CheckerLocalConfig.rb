#!/usr/bin/env ruby

#########################################################################
#
# Ruby source for #CheckerLocalConfig class
#
# Written by DEIMOS Space S.L. (algk)
#
# Data Exchange Component -> Common Transfer Component
# 
# CVS: $Id: CheckerLocalConfig.rb,v 1.4 2014/10/13 18:39:54 algs Exp $
#
#########################################################################


module CTC

class CheckerLocalConfig

   include CTC

# Class constructor.
   def initialize(localServerStruct, strInterfaceCaption = "")
      @isDebugMode = false
      @localElement  = localServerStruct
      if strInterfaceCaption != "" then
         @entity = strInterfaceCaption
      else
         @entity = "Generic"
      end
   end

# Method that checks both DCC and DDC
   def check
      if @isDebugMode == true then
         showLocalConfig(true, true)
      end
     
      retVal = checkLocalConfig(true, true)
     
      return retVal
   end
   #-------------------------------------------------------------

# Method that checks DCC  
   def checkLocal4Receive
      if @isDebugMode == true then
         showLocalConfig(true, false)
      end
   
      retVal = checkLocalConfig(true, false)
      return retVal   
   end
   #-------------------------------------------------------------

# Method that checks DDC   
   def checkLocal4Send
      if @isDebugMode == true then
         showLocalConfig(false, true)
      end
   
      retVal = checkLocalConfig(false, true)
      return retVal
   end
   #-------------------------------------------------------------

   
# Set debug mode on
   def setDebugMode
      @isDebugMode = true
      puts "CheckerLocalConfig debug mode is on"
   end
   #-------------------------------------------------------------

private
  
# It shows the Local Configuration.
   def showLocalConfig(b4Receive, b4Send)
      puts
      puts "============================================================="
      puts "Configuration of #{@entity} I/F"

      if b4Receive then         
         puts "Receiving from: "
         @localElement[:arrDownloadDirs].each { |x|
             puts x.directory
         }
      end

      if b4Send then
         puts "Sending to #{@localElement[:uploadDir]}"
         puts "With temp dir #{@localElement[:uploadTemp]}"
      end

      puts "============================================================="
      puts
   end      
   #-------------------------------------------------------------

# It returns true if the check is successful; otherwise it returns false.
   def checkLocalConfig(b4Receive, b4Send)
      ret = true

      # Check 4 Sending
      if b4Send then

         if @localElement[:uploadDir] == "" then
            puts "\nError: in #{@entity} I/F: UploadDir configuration element cannot be void :-(\n"
            ret = false         
         end

         if @localElement[:uploadTemp] == "" then
            puts "\nError: in #{@entity} I/F: UploadTemp configuration element cannot be void :-(\n"
            ret = false         
         end
   
      #dynamic directories
         dir=@localElement[:uploadDir]
         if dir.include?('[') then #it has dynamic uploadDirs
            puts "\nWarning: #{@entity} is using dynamic directories. Only checking directory before the expression !"
            dir= dir.slice(0,dir.index('['))
         end
      ###  
         retVal = checkLocalDirectory(dir, true) 
         if retVal == false then
            puts "\nError: in #{@entity} I/F: Unable to access to local dir #{@localElement[:uploadDir]} :-(\n"
            ret = false
         end

      #dynamic directories
         dir=@localElement[:uploadTemp]
         if dir.include?('[') then #it has dynamic uploadDirs
            puts "\nWarning: #{@entity} is using dynamic directories. Only checking directory before the expression !"
            dir= dir.slice(0,dir.index('['))
         end
      ###

         retVal = checkLocalDirectory(dir, true)
         if retVal == false then
            puts "\nError: in #{@entity} I/F: Unable to access to local dir #{@localElement[:uploadTemp]} :-(\n"
            ret = false
         end
         
#         if @localElement[:uploadTemp] == @localElement[:uploadDir] then
#            puts "\nError: in #{@entity} I/F: Upload directory and UploadTemp cannot be the same directory :-(\n"            
#            ret = false
#         end
      end

      # Check 4 Receive
      # We set as a configuration error when ALL download directories are un-reachable
      if b4Receive then
         arrDownDirs = @localElement[:arrDownloadDirs]
         bNoError = false
         bWarning = false
         arrDownDirs.each{|dirStruct|
            dir = dirStruct[:directory]
            retVal = checkLocalDirectory(dir, false)
            if retVal == false then
               puts "Error: #{@entity} I/F: Unable to access to local dir #{dirStruct[:directory]} :-(\n"
               bWarning = true
            else
               bNoError = true
            end
         }
         if bNoError == true and bWarning == true then
            puts
            puts "Warning: some of configured Download dirs are not reachable !  :-|"
         end
         if ret == true then
            ret = bNoError
         end
      end
      
      return ret
      
   end
   #-------------------------------------------------------------
   
# Check that the remote directories exists
      #b4SendOrRecieve = true if its for b4Send
      #b4SendOrRecieve = false if its for b4recieve
   def checkLocalDirectory(dir, b4SendOrRecieve)
      begin
         pwd = Dir.pwd 
         Dir.chdir(dir)
         if b4SendOrRecieve then
            File.new(".testWrite", "w+").close
            File.delete(".testWrite")
         end
         Dir.chdir(pwd)
      rescue Exception => e
        # puts "Error: #{e}" 
         return false
      end
   end
   #-------------------------------------------------------------

end # end class


end # module


