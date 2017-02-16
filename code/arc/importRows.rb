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

require 'arc/MINARC_DatabaseModel'

handler = File.open("myExportDBMeteo", "r")

arrRows = handler.readlines

arrRows.each{|aRow|
   if aRow.to_str.slice(0,1) == "#" then
      puts "skipped - #{aRow}"
      next
   end

   arrFields = aRow.split(",")
   
   filename          = arrFields[1]
#    filetype          = arrFields[2]
#    path              = arrFields[3]
#    start             = arrFields[5]
#    stop              = arrFields[6]
#    archive_date      = arrFields[7]

#    puts filename
#    puts filetype
#    puts path
#    puts start
#    puts stop
#    puts archive_date

   # ArchivedFile.delete_all(:filename => filename)

   #ArchivedFile.commit

  # next


            require 'minarc/plugins/METEO_DAILY_XML_Handler'

            nameDecoder = METEO_DAILY_XML_Handler.new(filename)
            
               filetype = nameDecoder.fileType.upcase
               start    = nameDecoder.start_as_dateTime
               stop     = nameDecoder.stop_as_dateTime
               path     = nameDecoder.archive_path



   anEntry = ArchivedFile.new

   anEntry.filename        = filename
   anEntry.filetype        = filetype
   anEntry.path            = path
   anEntry.validity_start  = start
   anEntry.validity_stop   = stop
   anEntry.archive_date    = Time.now
 
   puts filename
  
   anEntry.save!

   # exit

}
