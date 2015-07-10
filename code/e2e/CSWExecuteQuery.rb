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
   def initialize(queryFile, resultFile, debug = false)
      @queryFile           = queryFile
      @resultFile          = resultFile
      @auxResult           = "result_aux.xml"
      @queryDir            = "/home/e2espm/query/"
      @isDebugMode         = debug
      if @isDebugMode == true then
         self.setDebugMode
      end
     
      checkModuleIntegrity
      
      performQuery
            
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
   
   #-------------------------------------------------------------
   
   def performQuery
   
      # ------------------------------------
      cmd = "cp #{@queryFile} /tmp/#{@queryFile}"
      
      if @isDebugMode == true then
         puts
         puts cmd
         puts
      end
      
      system(cmd)
      
      # ------------------------------------   
   
      cmd = "sudo -u e2espm -i sdm_process_query_file -m sdm_db_e2espm -f /tmp/#{@queryFile} -o /tmp/#{@auxResult}"
      
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
      
      system("rm -f #{@auxResult}")      
      
      system("rm -f #{@queryFile}")
      
   end   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
end # class

end # module
