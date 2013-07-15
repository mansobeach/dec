#!/usr/bin/env ruby

require 'dbm/DatabaseModel'
require 'getoptlong'
require 'rdoc/usage'

def main

   fileType  = ""
   startDate = ""

   opts = GetoptLong.new(
   ["--fileType", "-t",            GetoptLong::REQUIRED_ARGUMENT],
   ["--start", "-s",               GetoptLong::REQUIRED_ARGUMENT]   
   )

   begin
      opts.each do |opt, arg|
         case opt
            when "--fileType"      then fileType    = arg
            when "--start"         then startDate   = arg
         end
      end
   rescue Exception
      exit(99)
   end 

   date = DateTime.parse(startDate)
   date2 = date.strftime(fmt='%F %T')
   
   query = "select filename, reception_date from received_files where filename like '%#{fileType}%' and reception_date > '#{date2}'"

   files = ReceivedFile.find_by_sql(query)

   files.each{|file|
      puts "#{fileType},#{file.filename},#{file.reception_date.strftime(fmt='%FT%T')}"
   }

   exit(0)

end

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================
