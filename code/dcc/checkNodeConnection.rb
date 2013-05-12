#!/usr/bin/env ruby

# == Synopsis
#
# This is a command line tool that checks whether a given node
# is reachable via ssh. 
# 
# -l flag:
#
# With this option, only "List" of new availables files for Retrieving and Tracking is done.
# This flag overrides configuration flags RegisterContentFlag RetrieveContentFlag in interfaces.xml
# So Check ONLY of new Files is performed anyway.
#
# -R flag:
#
# With this option (Reporting), DCC Reports will be created (see dcc_config.xml). 
# Report files are initally placed in the Interface local inbox and
# if configured in files2InTrays.xml disseminated as nominal retrieved file.
#
#
# == Usage
# checkNodeConnectio.rb -n <username@hostname> [-p port]
#     --node    <username@hostname>
#     --port    <numport>  
#     --help      shows this help
#     --usage     shows the usage
#     --Debug     shows Debug info during the execution
#     --version   shows version number
# 
# == Author
# DEIMOS-Space S.L. (bolf)
#
# == Copyright
# Copyright (c) 2007 ESA - DEIMOS Space S.L.
#

#########################################################################
#
# === 
#
# CVS: $Id: checkNodeConnection.rb,v 1.13 2007/07/24 17:21:57 decdev Exp $
#
#########################################################################


require 'getoptlong'
require 'rdoc/usage'
require 'net/ssh'
require 'net/sftp'

# Global variables
@@dateLastModification = "$Date: 2007/07/24 17:21:57 $"   # to keep control of the last modification
                                       # of this script
                                       # execution showing Debug Info
@entity          = ""

# MAIN script function
def main

   @port          = 22
   @node          = ""
   @isDebugMode   = false
   
   opts = GetoptLong.new(
     ["--node", "-n",           GetoptLong::REQUIRED_ARGUMENT],
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
   )
    
   begin
      opts.each do |opt, arg|
         case opt      
            when "--Debug"     then @isDebugMode = true
            when "--version" then	    
               print("\nESA - DEIMOS-Space S.L. ", File.basename($0), " $Revision: 1.13 $  [", @@dateLastModification, "]\n\n\n")
               exit(0)
	         when "--node"          then @node = arg.to_s
            when "--port"          then @port = arg.to_i
			   when "--help"          then RDoc::usage
	         when "--usage"         then RDoc::usage("usage")
         end
      end
   rescue Exception
      exit(99)
   end
 

   if @node == "" then
      RDoc::usage("usage")
   end

   if @node.include?("@") == false then
      RDoc::usage("usage")
   end

   arrNode = @node.split("@")

   if arrNode.length != 2 then
      puts arrNode
      exit(99)
   end 

   @user    = arrNode[0]
   @host    = arrNode[1]

   begin
      @sshSession = Net::SSH.start(@host, @port, @user)
      @sshSession.close
   rescue Exception => e
      puts
      puts "Error connecting to node #{@node}"
      puts
      puts e.to_s
      puts
      exit(99)
   end

   exit(0)

end

#-------------------------------------------------------------

#-------------------------------------------------------------


#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
