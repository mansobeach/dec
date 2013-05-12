#!/usr/bin/env ruby

#########################################################################
#
# === Ruby script checkSent2Interface
# 
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: checkSent2Interface.rb,v 1.2 2007/06/26 15:53:35 decdev Exp $
#
# checkSent2Interface checks what it has been sent to a given entity.
# It checks in the UploadDir and UploadTemp directories 
#
#########################################################################

require 'getoptlong'

require 'dbm/DatabaseModel'
require 'ctc/ReadInterfaceConfig'
require 'ctc/FTPClientCommands'


# Global variables
@@dateLastModification = "$Date: 2007/06/26 15:53:35 $" 
                                    # to keep control of the last modification
                                    # of this script
@isDebugMode      = false               # execution showing Debug Info
@isVerboseMode    = false
@isSecure         = false
@checkUploadTmp   = false
@entity           = ""


# MAIN script function
def main
   
   include CTC::FTPClientCommands

   opts = GetoptLong.new(
     ["--mnemonic", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--temp", "-t",           GetoptLong::NO_ARGUMENT],
     
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--Verbose", "-V",        GetoptLong::NO_ARGUMENT],
     ["--Show", "-S",           GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
    

   begin
      opts.each do |opt, arg|
         case opt
      
            when "--Debug"   then @isDebugMode   = true
            when "--Verbose" then @isVerboseMode = true
            when "--version" then
               print("\nESA - Deimos-Space S.L.  Envisat ", File.basename($0), " $Revision: 1.2 $  [", @@dateLastModification, "]\n\n\n")
               exit (0)
            when "--temp" then
               @checkUploadTmp = true         
            when "--help"          then usage
            when "--mnemonic" then
                 @entity = arg
            when "--Show"          then @bShowMnemonics = true      
         end
      end
   rescue Exception
     exit(99)
   end
 
   if @bShowMnemonics == true then
      arrInterfaces = Interface.find(:all)
      if arrInterfaces == nil then
         puts
         puts "Sorry, there are no configured I/Fs :-|"
         puts
      else
         if arrInterfaces.length == 0 then
            puts
            puts "Sorry, there are no configured I/Fs :-|"
            puts
         else
            puts "=== Data Collector Component Registered I/Fs ==="
            arrInterfaces.each{|interface|
               print interface.name
               1.upto(25 - interface.name.length) do
                  print " "
               end
               print interface.description
               puts
            }         
         end
      end
      exit(0)
   end

   if @entity == "" then
     usage
   end
   
   # Check Module Integrity
   checkModuleIntegrity
   
   @configFile = CTC::ReadInterfaceConfig.instance

   if @configFile.exists?(@entity) == false then
     print("\n#{@entity} is not a registered I/F in the interfaces.xml config file !  :-(\n\n")
     exit(99)
   end

   entConf = @configFile.getFTPServer4Send(@entity)  
   
   if entConf[:isSecure] == true then
     @isSecure = true
   end 
   
   if @isVerboseMode == true then
      showInterfaceConfig(entConf)
   end
   
   if @isSecure == false then
      cmd = self.createNcFtpLs(entConf[:hostname],
                              entConf[:port],
                              entConf[:user],
                              entConf[:password],
                              entConf[:uploadDir],   
                              nil)
   else
      cmd = self.createSftpCommand(entConf[:hostname],
                                  entConf[:port],
                                  entConf[:user],
                                  @batchFile,
                                  "cd #{entConf[:uploadDir]}",
                                  nil,
                                  nil)
      cmd = self.createSftpCommand(entConf[:hostname],
                                  entConf[:port],
                                  entConf[:user],
                                  @batchFile,
                                  "ls",
                                  "-1",
                                  nil)
   end
   
   if @isDebugMode == true then
      puts cmd
   end
   
   puts
   puts "============================================================="
   puts "Checking #{@entity} I/F Upload Directory"
   puts
   system(cmd)
   puts "============================================================="
   puts
   if @isSecure == true and FileTest.exist?(@batchFile) then
     n = File.delete(@batchFile)
   end     

   # If check to uploadTemp has not been requested, we've finished!.
   if @checkUploadTmp == false then
     exit(0)
   end

   if @isSecure == false then
      cmd = self.createNcFtpLs(entConf[:hostname],
                              entConf[:port],
                              entConf[:user],
                              entConf[:password],
                              entConf[:uploadTemp],   
                              "CS*")
   else
      cmd = self.createSftpCommand(entConf[:hostname],
                                  entConf[:port],
                                  entConf[:user],
                                  @batchFile,
                                  "cd #{entConf[:uploadTemp]}",
                                  nil,
                                  nil)
      cmd = self.createSftpCommand(entConf[:hostname],
                                  entConf[:port],
                                  entConf[:user],
                                  @batchFile,
                                  "ls",
                                  "",
                                  nil)
   end

   if @isDebugMode == true then
     puts cmd
   end
   
   puts
   puts "============================================================="
   puts "Checking #{@entity} I/F Upload TEMP Directory"
   puts
   system(cmd)
   puts "============================================================="
   puts
   if @isSecure == true and FileTest.exist?(@batchFile) then
     n = File.delete(@batchFile)
   end     
   
end

#-------------------------------------------------------------

# Print command line help
def usage
   print "\nUsage: ", File.basename($0), " -m <MNEMONIC> [-t]\n\n"
   print "\t\t   -m     <MNEMONIC> (mnemonic is case sensitive)\n"
   print "\t\t   -t     shows content of UploadTemp directory\n"
   print "\t\t   -h     shows this help\n"
   print "\t\t   -S     it shows all available I/Fs registered in the DDC Inventory\n"
   print "\t\t   -D     shows Debug info during the execution\n"
   print "\t\t   -V     execution in Verbose mode\n"
   print "\t\t   -v     shows version number\n"
   print "\n\n"      
   exit
end
#-------------------------------------------------------------

#-------------------------------------------------------------

# Check whether the entity is registered in the config file or not

def showInterfaceConfig(entity)
   puts
   puts "============================================================="
   puts "Configuration of #{entity[:mnemonic]} I/F for sending data :"
   puts
   if @isSecure == true then 
     puts "Secure conection is used (sftp)"
   else
     puts "NON Secure conection is used (ftp)"
   end
   puts "hostname     -> #{entity[:hostname]}"
   puts "port         -> #{entity[:port]}"
   puts "user         -> #{entity[:user]}"
   puts "password     -> #{entity[:password]}"
   puts "upload dir   -> #{entity[:uploadDir]}"
   puts "upload tmp   -> #{entity[:uploadTemp]}"
   puts
end
#-------------------------------------------------------------

#-------------------------------------------------------------
   
# Check that everything needed by the class is present.
def checkModuleIntegrity
      
   bDefined = true
   bCheckOK = true
   
   if !ENV['DCC_TMP'] then
     puts "\nDCC_TMP environment variable not defined !  :-(\n\n"
     bCheckOK = false
     bDefined = false
   end
   
   if bCheckOK == false then
     puts "checkSent2Interface::checkModuleIntegrity FAILED !\n\n"
     exit(99)
   end     
   
   time    = Time.new   
   strTime = time.to_i.to_s
   @batchFile = %Q{#{ENV['DCC_TMP']}/.batchCheckSent2#{@entity}#{strTime}}

end 

#-------------------------------------------------------------
#==========================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
