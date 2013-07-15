#!/usr/bin/env ruby

require "rubygems"
require "numru/netcdf"
require "spreadsheet"

include NumRu

book    = Spreadsheet.open("test.xls")
sheet   = book.worksheet 0

nValues = sheet.dimensions[1]
sVar    = sheet[0,2]
varType = ""

start   = "#{sheet[1,0]}T#{sheet[1,1]}"
start   = start.gsub("-","")
start   = start.gsub(":","")

stop    = "#{sheet[nValues-1,0]}T#{sheet[nValues-1,1]}"
stop    = stop.gsub("-","")
stop    = stop.gsub(":","")


if sheet[1,2].to_s.include?(".") == true then
   varType = "float"
else
   varType = "int"
end

# ------------------------------------------------

file = NetCDF.create("#{sVar}_#{start}_#{stop}.nc")

# ------------------------------------------------
# Dimensions

#dimDateTime = file.def_dim("DateTime", nValues)
# Unlimited size
dimTime = file.def_dim("Time", 0)

# ------------------------------------------------
# Global Attributes

file.put_att("Created", "Casale & Beach")
file.put_att("History", "created #{Time.now}")
file.put_att("First_Time", start)
file.put_att("Last_Time", stop)

# ------------------------------------------------

# Variables

varTime = file.def_var("Time","int",[dimTime])
varTime.put_att("long_name","Time since Epoch")
varTime.put_att("units", "seconds since Epoch 1970-01-01 00:00 UTC")

varMain = file.def_var(sVar,varType,[dimTime])

# ------------------------------------------------

# End netCDF Definition

file.enddef

# ------------------------------------------------
# Combine Date & Time from Excel 
# and fill-up netCDF variables

idx = 0

sheet.each{|row|
   if row[0].downcase == "date" then
      next
   end

   arr = row[0].split("-")
   arr.concat(row[1].split(":"))

   # Create UTC Time
   atime = Time.utc(arr[0], arr[1], arr[2], arr[3], arr[4], arr[5])
  
   varTime.put(atime.to_i, "index"=>[idx])
   varMain.put(row[2].to_f, "index"=>[idx])

   idx = idx + 1

}

# ------------------------------------------------


# ------------------------------------------------


file.close

exit


