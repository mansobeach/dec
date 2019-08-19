#!/usr/bin/env ruby

#########################################################################
#
# === Ruby source for #RetrieverFromArchive class
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component -> Data Distributor Component
# 
# Git: $Id: RetrieverFromArchive.rb,v 1.13 2008/07/03 11:38:26 decdev Exp $
#
## Module Data Distributor Component
## This class retrieves files to be transferred is pointed by 
## DEC_DELIVERY_ROOT Environment variable and files are placed into 
## dec_config.xml GlobalOutbox directory
#
#########################################################################

require 'fileutils'

require 'cuc/DirUtils'
require 'cuc/FT_PackageUtils'
require 'dec/ReadConfigDEC'
require 'dec/ReadInterfaceConfig'
require 'dec/ReadConfigOutgoing'


module DEC

class RetrieverFromArchive

   include CUC::DirUtils
   include FileUtils::NoWrite
   
   ## -----------------------------------------------------------
   ##
   ## catch SIGTERM signal and remove the temporary dir used
   trap 15,proc{  cmd = "\\rm -rf #{@targetDirectory}"
                     system(cmd) }
  
   
   ## -----------------------------------------------------------
      
   ## Class constructor.
   def initialize
      decConfig            = DEC::ReadConfigDEC.instance
      @confDest            = ReadConfigOutgoing.instance
      @arrFileTypes        = @confDest.getAllOutgoingTypes
      @arrFileNames        = @confDest.getAllOutgoingFileNames
      @arrFilters          = decConfig.getOutgoingFilters      
      @bDeleteSourceFiles  = decConfig.deleteSourceFiles?
      @globalOutbox        = decConfig.getGlobalOutbox
      @isDebugMode         = false
      @uploadDirs          = decConfig.getUploadDirs
      checkModuleIntegrity
   end   
   ## -----------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      puts "RetrieverFromArchive debug mode is on"
      @isDebugMode = true
   end
   ## -----------------------------------------------------------
   
   ## Public retrieve method that will call private method retrieveFilesOrNames two times:
   ## Once for the file-types files and another for the non-file types (wildcards)
   def retrieve(bJustList = false)
      puts
      puts "**** RETRIEVING ****"

      if bJustList == true then
         puts
         puts "==============================="
         puts "Source Directory of files to be pushed:" 
         puts "#{@sourceDirectory}"
         puts "==============================="
         puts
      end

      ## Strategy is two iterations which can be optimised

      @bNames = false
      @arrFileTypesOrNames = @arrFileTypes.clone
      retrieveFilesOrNames(bJustList)

      @bNames = true
      @arrFileTypesOrNames = @arrFileNames.clone
      retrieveFilesOrNames(bJustList)
   end
   ## -------------------------------------------------------------   
   
   ## This Method extracts all files to be delivered from the DCC Archive
   ## Optionally by a configuration flag it deletes them.
   
   def retrieve_bolf_old(bJustList = false)
      prevDir = Dir.pwd
      
      if bJustList == true then
         puts
         puts "==============================="
         puts "Source Directory:" 
         puts "#{@sourceDirectory}"
         puts "==============================="
         puts
      end

      if bJustList == true and @arrFileTypes.length == 0 then
         puts "No File-types are configured to be sent ?:-|"
         puts
      end

      @arrFileTypes.each{|filetype|

         Dir.chdir(@sourceDirectory)

         begin
            Dir.chdir(filetype)
            if bJustList == true then
               puts
               puts "[#{filetype}] - Searching files"
            end
         rescue Exception
            puts
            puts "Directory #{filetype} does not exist in DDC_ARCHIVE_ROOT"
            next
         end
         arrFiles = Dir["*#{filetype}*"]
         arrFiles.each{|afile|
             if bJustList == true then
                puts afile
             else
                # FileUtils.cp_r(afile, %Q{#{@targetDirectory}/#{afile}})
                
                cmd = "\\cp -Rf #{afile} #{@targetDirectory}/#{afile}"
                if @isDebugMode == true then
                  puts cmd
                end
                system(cmd)
                
                if @bDeleteSourceFiles == true and bJustList == false then
                   FileUtils.rm_rf(afile)
                end
             end
         }
      }
      Dir.chdir(prevDir)

   end
   
   ## -----------------------------------------------------------

   # Public deliver method that will call private method deliverFilesOrNames two times:
   # Once for the file-types files and another for the non-file types (wildcards)
   def deliver(bJustList = false, bDeliverOnce = false)
      puts
      if bJustList == false then
         puts "**** DELIVERING ****"
      end

      @bNames = false
      @arrFileTypesOrNames = @arrFileTypes.clone
      deliverFilesOrNames(bJustList, bDeliverOnce)

      @bNames = true
      @arrFileTypesOrNames = @arrFileNames.clone
      deliverFilesOrNames(bJustList, bDeliverOnce)

      #Delete global outbox folder unless we run in debug mode
      if @isDebugMode == false then
         cmd = "\\rm -rf #{@targetDirectory}"
         system(cmd)
      end
   end
   ## ----------------------------------------------------------- 

   # Public retrieve method that will call private method retrieveFilesOrNames two times:
   # Once for the file-types files and another for the non-file types (wildcards)
   def retrieve(bJustList = false)
      puts
      puts "**** RETRIEVING ****"

      if bJustList == true then
         puts
         puts "==============================="
         puts "Source Directory:" 
         puts "#{@sourceDirectory}"
         puts "==============================="
         puts
      end

      @bNames = false
      @arrFileTypesOrNames = @arrFileTypes.clone
      retrieveFilesOrNames(bJustList)

      @bNames = true
      @arrFileTypesOrNames = @arrFileNames.clone
      retrieveFilesOrNames(bJustList)
   end
   ## -----------------------------------------------------------
   
private

   ## -----------------------------------------------------------
   
   # Check that everything needed by the class is present.
   def checkModuleIntegrity 
      bDefined = true
      bCheckOK = true
   
      if !ENV['DEC_DELIVERY_ROOT'] then
         puts "\nDEC_DELIVERY_ROOT environment variable not defined !  :-(\n\n"
         bCheckOK = false
         bDefined = false
      end

      if bCheckOK == false then
         puts "RetrieverFromArchive::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
      
      @sourceDirectory = ""
      
      if ENV['DEC_DELIVERY_ROOT'] then
         @sourceDirectory = ENV['DEC_DELIVERY_ROOT']
      end
      
      @targetDirectory = @globalOutbox
      
      time             = Time.new
      tmpConfigFile    = time.to_i.to_s
      
      @targetDirectory = %Q{#{@targetDirectory}/_Delivery_/#{tmpConfigFile}}
    
      checkDirectory(@sourceDirectory)
      checkDirectory(@targetDirectory)
   end
   ## -----------------------------------------------------------
   
   ## 
   ##
   def packFile(file, srcPath, method, bUnPack = false)
      bRet = false
      if @isDebugMode == true then
         puts "#{file} is Packaged with #{method} method"
      end
      package        = FT_PackageUtils.new(file, srcPath, true)
      if @isDebugMode == true then
         package.setDebugMode
      end
      
      bMethod = package.setCompressMethod(method)
   
      if bMethod == false then
         puts "\nFATAL Error in RetrieverFromArchive"
         puts "\nError in Compression Method for #{file} - #{method} !! =:-O\n"
         puts
         exit(99)
      end
      
      # BOLF - 2007-04-10 We do not perform unpack directly anymore
      # Currently there is a Package method called "unpack" that performs
      # that operation when required.

      if bUnPack == false then
         bRet = package.pack
         arr  = Array.new
         arr << bRet
         bRet = arr
      else      
         bRet = package.unpack
      end
   
      if bRet == false then
         puts "\nError in RetrieverFromArchive::packFile"
         puts "\nFailed to Pack #{file} !! =:-O\n"
         exit(99)      
      end 
      return bRet
   end
   ## -------------------------------------------------------------

   ## This Method extracts all files to be delivered from the source directory
   ## Optionally by a configuration flag it deletes them.
   ##
   def retrieveFilesOrNames(bJustList = false)
      prevDir = Dir.pwd
          
      if bJustList == true and @arrFileTypesOrNames.length == 0 and @bNames == false then
         puts "No File-types are configured to be sent ?:-|"
         puts
      end

      @arrFileTypesOrNames.each{|filetype|

         Dir.chdir(@sourceDirectory)

         begin
            if filetype.include?("*") or filetype.include?("?") then
               puts
               puts "------------------------------------------------------"
               puts "Wildcard [#{filetype}] - Gathering files"
            else
               Dir.chdir(filetype)
               puts
               puts "------------------------------------------------------"
               puts "[#{filetype}] - Gathering files"
            end
         rescue Exception
            if @isDebugMode == true then
               puts
               puts "Directory #{filetype} does not exist in source directory (#{@sourceDirectory})"
            end
            next
         end

         ##
         ## If bNames is false we gather type-files; if its true we gather non-type files (recursively)
         ## or UploadDirs content
         
         if @bNames == false || @uploadDirs then
            arrFiles = Dir["*#{filetype}*"]
         else
            recursive = File.join("**","#{filetype}")
            arrFiles = Dir.glob(recursive)
         end

         # Filtering of dec_config.xml
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

         # Process matched files
         arrFiles.each{|afile|
   
            # We dont want to copy a full directory
            if File.directory?(afile) and !@uploadDirs then
               next
            end

            puts afile

            if bJustList == false then  
                        
               if filetype.include?("/") then
#                  toDir = filetype.sub(/\/.*/,"")
                  toDir = afile.slice(/.*\//)
                  if !File.exists?("#{@targetDirectory}/#{toDir}") then
#                     Dir.mkdir("#{@targetDirectory}/#{toDir}")
                     FileUtils.mkdir_p("#{@targetDirectory}/#{toDir}")
                  end
                  destFile = afile
               else
                  # to get wildcards NOT of the type INT/wildcard into the global outbox root dir
                  destFile = afile.sub(/.*\//,"")
               end
              # cmd = "\\cp -Rf #{afile} #{@targetDirectory}/#{destFile}"
               cmd = "\\ln #{afile} #{@targetDirectory}/#{destFile} >& /dev/null"

               if @isDebugMode == true then
                 puts cmd
               end
               
               #if the hard link does not work make a copy
               valRet = system(cmd)
               if !valRet then
                  cmd = "\\cp -Rf #{afile} #{@targetDirectory}/#{destFile}"
                  system(cmd)
               end
               
               if @bDeleteSourceFiles == true and bJustList == false then
                  FileUtils.rm_rf(afile)
               end
            end
         }  #end of arrFiles.each block
      }  #end of @arrFileTypesOrNames.each block

      Dir.chdir(prevDir)
   end
   
   ## -------------------------------------------------------------
   ##
   ## Copy the files from the target Directory to all outboxes
   ##
   ##
   def deliverFilesOrNames(bJustList = false, bDeliverOnce = false)
      
      @entityConfig  = ReadInterfaceConfig.instance
      arrEntity      = @entityConfig.getAllExternalMnemonics

      @outConfig     = ReadConfigOutgoing.instance

      prevDir = Dir.pwd
      Dir.chdir(@targetDirectory)

      @arrFileTypesOrNames.each{|filetype|

         if @isDebugMode == true then
            puts "xxxxxxxxx"      
            puts filetype
            puts "xxxxxxxxx" 
         end 

         # If bNames is false we get filetype-like files; if its true we get non-type files
         if @bNames == false then
            arrFiles = Dir["*#{filetype}*"]
         else
            arrFiles = Dir["#{filetype}"]
         end

         if @isDebugMode == true then
            puts "+++++++++"      
            puts arrFiles
            puts "+++++++++"             
         end
      
         arrEntities = @confDest.getEntitiesReceivingOutgoingFile(filetype)      
           
         arrFiles.each{|afile|
            
            if !arrEntities.empty? then
               puts
               puts afile
            end
            
            arrEntities.each{|anEntity|
               dir        = @outConfig.getOutgoingDir(anEntity[:mnemonic])
               arrMethods = anEntity[:deliveryMethods]
               if @isDebugMode == true then
                  puts
                  puts "outgoing dir for #{anEntity[:mnemonic]} is #{dir}"
                  puts
               end
               
               arrMethods.each{|aMethod|
                  aDir = %Q{#{dir}/#{aMethod}}
                  checkDirectory(aDir)

                  if bJustList == false then
		               begin
                        if filetype.include?("/") then
                        #   fromDir = filetype.sub(/\/.*/,"")
                           fromDir = afile.slice(/.*\//)
                           thefile = afile.sub(/.*\//,"")
                         #  cmd = "\\cp -Rf #{fromDir}/#{thefile} #{aDir}/"
                           cmd = "\\ln #{fromDir}/#{thefile} #{aDir}/#{thefile} >& /dev/null"
                           byInterface = true
                        else
                           thefile = afile
                         #  cmd = "\\cp -Rf #{thefile} #{aDir}/"
                           cmd = "\\ln #{thefile} #{aDir}/#{thefile} >& /dev/null"
                           byInterface = false
                        end

                        ## ---------------------------------
                        ## If delivery once has been selected, check whether the file
                        ## has already been delivered
                        if bDeliverOnce then
                           if SentFile.hasAlreadyBeenSent?(thefile, anEntity[:mnemonic], aMethod) == true then
                              puts "#{thefile} already sent to #{anEntity[:mnemonic]} via #{aMethod}"
                              next
                           end
                        end 
                        ## ---------------------------------
                        
                        if @isDebugMode == true then
                           puts cmd
                        end

                        ## ---------------------------------

                        # if the hard link does not work make a copy
                        valRet = system(cmd)			
                        if !valRet then
                           if byInterface then
                              cmd = "\\cp -Rf #{fromDir}/#{thefile} #{aDir}/"
                           else
                              cmd = "\\cp -Rf #{thefile} #{aDir}/"
                           end
                           if @isDebugMode == true then
                              puts
                              puts cmd
                              puts
                           end
                           system(cmd)
                        end

                        #FileUtils.cp_r(thefile, %Q{#{aDir}/#{thefile}})
			               puts "Copied to #{anEntity[:mnemonic]} outbox / Protocol: #{aMethod}"
			
                        if @isDebugMode == true then
                           puts
                           puts "#{aDir}"
                           puts
                        end
         
                        ## 
			               ## Apply Compress Method
                        
                        compMethod = @confDest.getCompressMethod(anEntity[:mnemonic], filetype)
                        
                        if @isDebugMode == true then
                           puts compMethod
                        end
                                                
                        extension = thefile.split('.').last
                           
                        if (compMethod != "NONE") and (compMethod.downcase != extension.downcase) then
                           ret = packFile(thefile, aDir, compMethod)
                           
                           if ret == false then
                              puts
                              puts "failed to pack #{thefile} into #{aDir} with compress method #{compMethod}"
                              puts
                           end
                        end
			
                     rescue Exception => e
		     	            puts e.to_s
                        if @isDebugMode == true then
                           puts e.backtrace
			               end
                        exit(99)
			               
		               end
		     
                  else
                     puts "Would be Copied to #{anEntity} #{aMethod} outbox"
                  end
                  
               }  #end of arrMethods.each block
               
            }  #end of arrEntities.each block
         
	      }  #end of arrFiles.each block
 
      }  #end of @arrFileTypesOrNames.each block
  
      Dir.chdir(prevDir)

   end
   ## ------------------------------------------------------------

      
end # class

end # module

