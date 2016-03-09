#!/usr/bin/env ruby

#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#
#
#########################################################################

require 'cuc/Converters'

module E2E

class CSWExecuteQuery

   include CUC::Converters

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(queryFile, query, resultFile, bCorrectUTC, debug = false)
      @queryFile           = queryFile
      @query               = query
      @resultFile          = resultFile
      @auxResult           = "result_aux.xml"
      @bCorrectUTC         = bCorrectUTC
      @queryDir            = "/home/e2espm/query/"
      @isDebugMode         = debug
      
      if @isDebugMode == true then
         self.setDebugMode
#          puts "xxxxxxxxxxxxxxxxxxxxxxxxxx"
#          puts @query
#          puts @resultFile
#          puts "xxxxxxxxxxxxxxxxxxxxxxxxxx"
      end
     
      checkModuleIntegrity
      
      if @bCorrectUTC == true then
         performQueryCorrected
      else
         performQuery
      end   
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "CSWExecuteQuery debug mode is on"
   end
   #-------------------------------------------------------------
      
private

   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
         puts "CSWExecuteQuery::checkModuleIntegrity FAILED !\n\n"
         exit(99)
      end
   end
   #-------------------------------------------------------------
  
   # ------------------------------------
      
   # if correctUTC flag is enabled

   
   def performQueryCorrected

      # ------------------------------------
      cmd = "mv -f #{@queryFile} /tmp/#{@queryFile}"
      
      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end
      
      system(cmd)


      cmd = "sudo -u e2espm -i e2espm_sdm_query -f /tmp/#{@queryFile} -o /tmp/#{@auxResult}"
      
      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end      
      
      retVal = system(cmd)

      cmd = "sudo -u e2espm -i libxrep_xslt -I SAXON_8 -s /opt/facilities/common-function/application/libxrep/shared/e2espm/repositories/DataTransforms/e2espm/correct_plan_events.xsl"

      cmd = "#{cmd} -i /tmp/#{@auxResult}"

      cmd = "#{cmd} -p \"SCRIPT_INPUT=CSWquery\" "
      
      cmd = "#{cmd} -p \"OBJECT_INPUT=@e2espm/#{@query}\" "

      cmd = "#{cmd} -p \"SCRIPT_ORBIT=CSWquery\" "
      
      cmd = "#{cmd} -p \"OBJECT_ORBIT=@e2espm/get_predicted_orbit\" "

      cmd = "#{cmd} -o #{@resultFile}"

      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end
 
      retVal = system(cmd)
      
      # system("rm -f #{@queryFile}")
      
#       puts "xxxxxxxxxxxxx"
#       puts @auxResult
#       puts "xxxxxxxxxxxxx"
      
      system("sudo -u e2espm -i rm -f /tmp/#{@auxResult}")   
         
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   def performQuery
   
      # ------------------------------------
      cmd = "mv -f #{@queryFile} /tmp/#{@queryFile}"
      
      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end
      
      system(cmd)
      
      # ------------------------------------   
   
      cmd = "sudo -u e2espm -i sdm_process_query_file -m sdm_db_e2espm -f /tmp/#{@queryFile} -o /tmp/#{@auxResult}"
 
      # cmd = "sudo -u e2espm -i e2espm_sdm_query -f /tmp/#{@queryFile} -o /tmp/#{@auxResult}"
      
      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end      
      
      retVal = system(cmd)
      
      cmd = "sudo -u e2espm -i libxrep_xslt -I SAXON_8 -i /tmp/#{@auxResult} -s /opt/facilities/common-function/application/libxrep/local/e2espm/code/Report_Tool/XSL/sdmData.xsl -o #{@resultFile}"
      
      if @isDebugMode == true then
         puts
         puts cmd
         puts
         puts #{@resultFile}
         puts
      end      
      retVal = system(cmd)
      
      system("sudo -u e2espm -i rm -f /tmp/#{@auxResult}")      
      
#      system("rm -f #{@queryFile}")
      
   end   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
end # class

end # module
