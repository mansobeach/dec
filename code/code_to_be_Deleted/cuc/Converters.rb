#!/usr/bin/env ruby

require 'rubygems'
require 'active_record'

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

module CUC

module Converters

   # String format shall be: 20120325T154814
   def str2date(str)
      return DateTime.new(str.slice(0,4).to_i, str.slice(4,2).to_i, str.slice(6,2).to_i,
                          str.slice(9,2).to_i,  str.slice(11,2).to_i, str.slice(13,2).to_i)
   end

end # module

end # module
