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

module CUC

module Converters

   #-------------------------------------------------------------
   
   # String format shall be: 20120325T154814
   def str2date(str)
      if str.length == 6 then
         return DateTime.new(str.slice(0,4).to_i, str.slice(4,2).to_i)
      end

      if str.length == 8 then
         return DateTime.strptime(str,"%Y%m%d")
      end

      return DateTime.strptime(str,"%Y%m%dT%H%M%S")

      return DateTime.new(str.slice(0,4).to_i, str.slice(4,2).to_i, str.slice(6,2).to_i,
                          str.slice(9,2).to_i,  str.slice(11,2).to_i, str.slice(13,2).to_i)
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
