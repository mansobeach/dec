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

require 'minarc/MINARC_DatabaseModel'


# MAIN script function
def main

   prevDir = Dir.pwd

   path = "/tmp/import/2013"

   Dir.chdir(path)

   arrDirs = Dir["*"].sort

   arrDirs.each{|aDir|
      Dir.chdir(aDir)

      currDir = Dir.pwd

      arrFiles = Dir["*"].sort

      arrFiles.each{|aFile|
         # puts aFile.split("_")[4]
         newName = "DAILY_CORRECTED_CASALE_#{aFile.split("_")[4]}"
         cmd = "mv #{aFile} #{newName}"
         puts cmd
         system(cmd)

         cmd = "minArcStore2.rb -f #{currDir}/#{newName} -d -u -t DAILY_CORRECTED_XLS"   
         puts cmd
         system(cmd)


      }

      Dir.chdir("..")

   }

   Dir.chdir(prevDir)

end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
