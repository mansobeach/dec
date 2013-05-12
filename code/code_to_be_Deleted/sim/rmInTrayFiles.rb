#!/usr/bin/ruby

#########################################################################
#
# rmInTrayFiles.rb
#
# Written by DEIMOS Space S.L. (bolf)
#
# Data Collector Component
# 
# CVS:
#
#########################################################################

# It deletes all the files present in the In-Trays.


require 'fileutils'

require 'dcc/ReadInTrayConfig'

include FileUtils

puts "\nrmInTrayFiles ..."
print "\nAll files in the DIM IN-TRAYs will be DELETED !!!\n"

res = ""

while res.chop != "N" and res.chop != "Y"
   print "\nDo you want to continue? [Y/N]\n\n"
   res = STDIN.gets.upcase
end

if res.chop == "N" then
   puts "\n\nwise guy !! ;-p \n\n\n"
   exit(0)
end


pwd = Dir.pwd

confInTrays = DCC::ReadInTrayConfig.instance
arrDims     = confInTrays.getAllDIMs

arrDims.each{|dim|
   dir = confInTrays.getDIMInTray(dim)
   begin
      Dir.chdir(dir)
   rescue Exception => e
      next
   end
   puts "Deleting files in #{dir}"
   rm(Dir.glob("*"), :force => true)
}

Dir.chdir(pwd)
