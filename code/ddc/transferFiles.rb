#!/usr/bin/env ruby

# == Synopsis
#
# This is a DDC command line tool that retrieves files to be transfer
# from a specified location.
# 
#
# == Usage
# transferFiles.rb -L <full_path_dir> -m <interfaces> -d <deliveryMethods>
#   --location    full_path_dir of the files to be transfered
#   --entities    interfaces to where transfer the files
#   --delivery    methods used to deliver the files to the entities
#   --compress    method for the file to be comrpessed
#   --help        shows this help
#   --usage       shows the usage
#   --Debug       shows Debug info during the execution
#   --version     shows version number
# 
# == Author
# Deimos-Space S.L. (algk)
#
# == Copyright
# Copyright (c) 2006 ESA - Deimos Space S.L.
#

#########################################################################
#
# === Ruby script transferFiles for sending all files to an Entity
# 
# === Written by DEIMOS Space S.L.   (algk)
#
# === Data Exchange Component -> Data Distributor Component
# 
# CVS: $Id: transferFiles.rb,v 1.1 2009/06/15 13:28:13 algs Exp $
#
#########################################################################

require 'getoptlong'

require 'cuc/DirUtils'
require 'cuc/FT_PackageUtils'
require 'ctc/ReadInterfaceConfig'
require 'ddc/ReadConfigDDC'


@isDebugMode      = false
@bList            = false

# MAIN script function
def main


   include           DDC
   include           CUC::DirUtils

   @directory   = ""
   @strEntities = ""
   @strMethods  = ""
   @compMethod    = ""
   
   opts = GetoptLong.new(
     ["--Debug", "-D",          GetoptLong::NO_ARGUMENT],
     ["--location", "-L",       GetoptLong::REQUIRED_ARGUMENT],
     ["--entities", "-m",       GetoptLong::REQUIRED_ARGUMENT],
     ["--delivery", "-d",       GetoptLong::REQUIRED_ARGUMENT],
     ["--compress", "-c",       GetoptLong::REQUIRED_ARGUMENT],
     ["--usage", "-u",          GetoptLong::NO_ARGUMENT],
     ["--version", "-v",        GetoptLong::NO_ARGUMENT],
     ["--help", "-h",           GetoptLong::NO_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt      
            when "--Debug"   then @isDebugMode = true
            when "--version" then
               ddcConfig = ReadConfigDDC.instance
               version = File.new("#{ENV["DECDIR"]}/version.txt").readline
               print("\nESA - DEIMOS-Space S.L.  DEC   ", version," \n[",ddcConfig.getProjectName,"]\n\n\n")
               exit (0)
            when "--location" then
               @directory = arg.to_s;
            when "--entities" then
               @strEntities = arg.to_s;
            when "--delivery" then
               @strMethods = arg.to_s;
            when "--methods" then
               @compMethod = arg.to_s;
            when "--help"    then usage
            when "--usage"   then usage
         end
      end
   rescue Exception
      exit(99)
   end   

   if @directory == "" or @strEntities == "" or @strMethods == "" then
      usage
   end

   ddcConfig      = DDC::ReadConfigDDC.instance
   @arrFilters    = ddcConfig.getOutgoingFilters

   puts
   deliver
   puts
   
end

#---------------------------------------------------------------------

private
def deliver

   listOfValidMethods = ["email", "ftp", "mailbody"]

   if !File.exists?(@directory) then
      puts "wrong location"
      return 99
   else
      Dir.chdir(@directory)
      arrFiles= Dir["*"];

       #Filtering of DDC_config.xml
         if !@arrFilters.empty? then
            arrFilesAux = Array.new

           @arrFilters.each{|filter|
               if @isDebugMode == true then
                  puts "Filtering outgoing files by #{filter}"
               end
         
               arrFiles.each{|file|        
            
                  if File.fnmatch(filter, file.gsub(/.*\//, '')) == true then
                     arrFilesAux << file
                  end
               }
            }
            arrFiles = arrFilesAux.clone
         end
      

      if arrFiles.empty? then
         puts "No files to be transfered"
      else

         #get the entities and the delivery methods in arrays
         arrEntities = @strEntities.split(",");
         arrMethods =    @strMethods.split(",");
      
         entityConfig = CTC::ReadInterfaceConfig.instance
         listOfValidEntities = entityConfig.getAllMnemonics
         
         #check the entities input
         aux = Array.new
         arrEntities.each{|anEntity|
         if !listOfValidEntities.include?(anEntity) then
            puts " WARNING!! #{anEntity} is not a valid I/F\n"            
         else
            aux << anEntity
         end 
         }
         arrEntities = aux.clone

         #check the delivery methods input
         aux = Array.new
         arrMethods.each{|aMethod|
         if !listOfValidMethods.include?(aMethod) then
            puts " WARNING!! #{aMethod} is not a valid delivery method\n"            
         else
            aux << aMethod
         end 
         }
         arrMethods = aux.clone


         #actual delivery
         puts
         arrFiles.each{|afile|

            arrEntities.each{|anEntity|
            
               dir = entityConfig.getOutgoingDir(anEntity)
               
               arrMethods.each{|aMethod|

                  aDir = %Q{#{dir}/#{aMethod}}
                  checkDirectory(aDir)
		               begin
                        #safe copy
                        cmd = "\\cp -Rf #{afile} #{aDir}/.#{afile}"
                        if @isDebugMode == true then
                           puts cmd
                        end
                        system(cmd)
			               puts "Copied to #{anEntity} #{aMethod} outbox (#{afile})"
			               cmd = "\\mv #{aDir}/.#{afile} #{aDir}/#{afile}"
                        system(cmd)
                        
                        # Apply Compress Method
                        if @compMethod != "" then                     
 			                  package = FT_PackageUtils.new(afile, aDir, @compMethod)
                           package.pack
			               end

                     rescue Exception => e
		     	            puts e.to_s
			               exit(99)
		               end

               }  #end of arrMethods.each block
               
            }  #end of arrEntities.each block
         
	      }  #end of arrFiles.each block
      end
   end
end   
#---------------------------------------------------------------------

#-------------------------------------------------------------

# Print command line help
def usage
   fullpathFile = `which #{File.basename($0)}`    
   
   value = `#{"head -26 #{fullpathFile}"}`
      
   value.lines.drop(1).each{
      |line|
      len = line.length - 1
      puts line[2, len]
   }
   exit   
end
#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
