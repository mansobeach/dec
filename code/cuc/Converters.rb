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

require 'rubygems'
require 'date'

module CUC

module Converters

   #-------------------------------------------------------------
   
   # String formats supported: 
   # - 20120325                  => "%Y%m%d"
   # - 20120325T154814           => "%Y%m%dT%H%M%S"
   # - 21-MAY-2015 14:00:01.516  => "%e-%b-%Y %H:%M:%S.%L"  / Length 24
   # - 01-FEB-2016 02:20:40.59   => "%e-%b-%Y %H:%M:%S.%L"  / length 23
   # - 01-FEB-2016 02:20:40.5    => "%e-%b-%Y %H:%M:%S.%L"  / length 22
   # - 2015-11-16T00:30:27       => "%Y-%m-%dT%H:%M:%S"
   
   
   def str2date(str)
   
      if (str.length == 24 or str.length == 23 or str.length ==22) and str.slice(2,1) == "-" and str.slice(6,1) == "-" then
         return DateTime.strptime(str,"%e-%b-%Y %H:%M:%S.%L")
      end

      if str.length == 19 and str.include?("T") then
         return DateTime.strptime(str,"%Y-%m-%dT%H:%M:%S")
      end

      begin
         if str.length == 19 and str.include?("T") then
            return DateTime.strptime(str,"%Y%m%dT%H%M%S")
         end
      rescue Exception => e
         puts e.to_s
         puts
         puts str
         puts
         exit(99)
      end
       
      if str.length == 8 then
         return DateTime.strptime(str,"%Y%m%d")
      end
     
      if str.length == 6 then
         return DateTime.new(str.slice(0,4).to_i, str.slice(4,2).to_i)
      end

      puts
      puts "FATAL ERROR in CUC::Converters str2date(#{str}) / length #{str.length}"
      puts
      puts
      exit(99)

      return DateTime.new(str.slice(0,4).to_i, str.slice(4,2).to_i, str.slice(6,2).to_i,
                          str.slice(9,2).to_i,  str.slice(11,2).to_i, str.slice(13,2).to_i)
   end

   #-------------------------------------------------------------

   # output string shall follow this format 2015-06-18T12:23:27
   # - 2015-04-02T16:36:14.339
   # - 2015-06-27T14:24:34.000000
   # - 2015-06-19T21:14:10Z
   # - 2015-06-27T09:07:06Z;DET=123456789ABC       / More rubbish from E2ESPM
   # - 2015-06-27T14:24:34.000000;DET=123456789ABC / More rubbish from E2ESPM
   def str2strexceldate(str)
#       puts str
#       puts str.length
#       puts str.slice(19,1)
#       puts str.slice(7,1)
#       puts str.slice(19,1)


      # - 2015-06-27T14:24:34.000000
      if str.length == 26 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end


      # - 2015-06-27T14:24:34.000000;DET=123456789ABC
      if str.length > 26 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end

      
      # - 2015-04-02T16:36:14.339
      if str.length == 23 and str.slice(19,1) == "." and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end
      
      # - 2015-06-19T21:14:10Z
      
      if str.length == 20 and str.slice(19,1) == "Z" and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end

      # - 2015-06-19T21:14:10

      if str.length == 19 and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end


       # - 2015-06-27T09:07:06Z;DET=123456789ABC
      
      if str.length > 20 and str.slice(19,1) == "Z" and str.slice(4,1) == "-" and
          str.slice(7,1) == "-" and str.slice(10,1) == "T" then
         return str.slice(0, 19)
      end
     
      
      puts
      puts "FATAL ERROR in CUC::Converters str2strexceldate(#{str} / length #{str.length}  )"
      puts
      puts
      exit(99)
      
   end
   #-------------------------------------------------------------

   def str2time(str)
      return Time.local(str.slice(0,4).to_i, str.slice(4,2).to_i, str.slice(6,2).to_i,
                          str.slice(9,2).to_i,  str.slice(11,2).to_i, str.slice(13,2).to_i)

   end
   #-------------------------------------------------------------

   def str_to_bool(str)
      return true   if str == true   || str =~ (/(true|t|yes|y|1)$/i)
      return false  if str == false  || str.empty? || str =~ (/(false|f|no|n|0)$/i)
      raise ArgumentError.new("Converters::str_to_bool invalid value for Boolean: \"#{str}\"")
   end
   #-------------------------------------------------------------


end # module

end # module
