#!/usr/bin/ruby

# This class allows minarc to handle MIRAS_L1C_BUFR files.
# Example name : miras_20091224_182959_20091225_122959_smos_001_o_20091224_010000_l1c.bufr
#                miras_20121119_200135_20121119_205805_smos_27176_t_20081024_112856_l1c.bufr

class Handler_MIRAS_L1C_BUFR

   @type = ""
   @filename = ""
   @validated = false
   @start = nil
   @stop  = nil
   @generation_date = nil

   # Class constructor
   def initialize (name)
      @filename = name
      @type = "MIRAS_L1C_BUFR"

      matches = @filename.match(/^miras_([0-9]{8})_([0-9]{6})_([0-9]{8})_([0-9]{6})_([a-zA-Z0-9]*)_([0-9]{5})_([a-z]{1})_([0-9]{8})_([0-9]{6})_l1c.bufr/)

      if matches != nil and matches[0] == @filename then
         tmp = @filename.split("_")
         @start           =  DateTime.new(tmp[1].slice(0,4).to_i, tmp[1].slice(4,2).to_i, tmp[1].slice(6,2).to_i, tmp[2].slice(0,2).to_i, tmp[2].slice(2,2).to_i, tmp[2].slice(4,2).to_i)
         @stop            =  DateTime.new(tmp[3].slice(0,4).to_i, tmp[3].slice(4,2).to_i, tmp[3].slice(6,2).to_i, tmp[4].slice(0,2).to_i, tmp[4].slice(2,2).to_i, tmp[4].slice(4,2).to_i)
         @generation_date =  DateTime.new(tmp[8].slice(0,4).to_i, tmp[8].slice(4,2).to_i, tmp[8].slice(6,2).to_i, tmp[9].slice(0,2).to_i, tmp[9].slice(2,2).to_i, tmp[9].slice(4,2).to_i)
 
         # this filename is valid
         @validated = true
      end
   end

   def isValid
      return @validated
   end

   def fileType
      return @type
   end

   def start_as_dateTime
      return @start
   end

   def stop_as_dateTime
      return @stop
   end

   def generationDate
      return @generation_date
   end
end
