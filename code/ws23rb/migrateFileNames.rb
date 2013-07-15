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

   theFiles = ArchivedFile.find_all_by_filetype("METEO_DAILY_XML")

   theFiles.each{|aFile|
      puts aFile.filename
      Dir.chdir(aFile.path)
      newName = aFile.filename.gsub("METEO", "REALTIME")
      cmd = "cp -f #{aFile.filename} /tmp/#{newName}"
#      puts cmd
      system(cmd)

      cmd = "minArcStore2.rb -f /tmp/#{newName} -d -t REALTIME_XML"
      puts cmd
      system(cmd)

      cmd = "minArcDelete.rb -f #{aFile.filename}"
      puts cmd
      system(cmd)
      puts      

#       Dir.chdir(prevDir)
#       exit

   }

   Dir.chdir(prevDir)


end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
