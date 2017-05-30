#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to parse Sentinel-2 binary data

# == Usage
#  CADU   -file <>
#     --help                shows this help
#     --check               it checks existence of product organisation files 
#     --excel               it creates an excel file with some checks
#     --Debug               shows Debug info during the execution
#     --Force               force mode
#     --version             shows version number      
# 

# == Author
# Sentinel-2 PDGS Team (BL)
#
# == Copyleft
# ESA / ESRIN


# ------------------------------------------------------------------------------

require 'rubygems'
require 'getoptlong'
require 'date'

require 'cuc/Converters'

# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------
# ------------------------------------------------------------------------------

class S2_CADU # 
   
   
   attr_accessor :offset
   # ------------------------------------------------------------  
   
   # class constructor
   
   def initialize(filename)
      @filename                  = filename
      @stream                    = File.open(@filename)
      @stream.binmode
      @cadu_sync_marker          = "1acffc1d"
      @cadu_length_sync_marker   = 4
      @cadu_length_data          = 1912
      @cadu_length_rs_check      = 128
      @frame_header              = 8
      @offset                    = 0
      setDebugMode  
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "S2_CADU debug mode is on"
   end
   #-------------------------------------------------------------


   # ------------------------------------------------------------
   
   def readCADU
      
      data = @stream.read(@cadu_length_sync_marker)
      
      if data.unpack('H*')[0] == @cadu_sync_marker then
         puts "ASM  => #{@offset.to_s.rjust(4,'0')} #{data.unpack('H*')[0]}"
         @offset = @offset + @cadu_length_sync_marker
      else
         puts "sync not found / resync ..."
         @offset = @offset - 3
         @stream.seek(-3, IO::SEEK_CUR)
         
         prev_offset = @offset
         
         if lookUpSync == true then
            puts "discarded #{@offset - prev_offset} bytes"
            readCADU
         end
         return
      end
      data = @stream.read(@cadu_length_data)
      data = @stream.read(@cadu_length_rs_check)
      @offset = @offset + @cadu_length_sync_marker + @cadu_length_data + @cadu_length_rs_check
   end
   
   # ------------------------------------------------------------
   # Skip data until finding the CADU  Attached Sync Marker 32 bit
   # 1A CF FC 1D
      
   def lookUpSync
      loop do 
         data = @stream.read(@cadu_length_sync_marker)
         if data == nil then
            return false
         end
         
#          if @isDebugMode == true then
#             puts "#{@offset.to_s.rjust(4,'0')} #{data.unpack('H*')[0]}"
#          end
   
         if data.unpack('H*')[0] == @cadu_sync_marker then
            @stream.seek(-4, IO::SEEK_CUR)
            break
         end
         @stream.seek(-3, IO::SEEK_CUR)
         @offset = @offset + 1
      end
      return true
   end
   # ------------------------------------------------------------
   
   # ------------------------------------------------------------
   
end


# ------------------------------------------------------------------------------

class S2_AISP

   include CUC::Converters

   attr_accessor :offset
   # ------------------------------------------------------------  
   
   # class constructor
   #
   # All the field lengths are expressed in bytes
   
   def initialize(filename)
      @filename                        = filename
      @stream                          = File.open(@filename)
      @stream.binmode
      @aisp_length_annotation          = 18
      @length_packet_header_total      = 6
         @length_packet_header_id         = 2
         @length_packet_header_psc        = 2
         @length_packet_header_data_len   = 2
      @length_data_pus_version         = 1
      @length_data_service_type        = 1
      @length_data_service_subtype     = 1
      @length_data_destination_id      = 1
      @length_data_cuc_coarse_time     = 4
      @length_data_cuc_fine_time       = 3
      @offset                          = 0
      
      @gps_epoch  = str2date("1980-01-06T00:00:00").to_time.to_i
      puts @gps_epoch
       #exit
      
      setDebugMode
   end

   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "S2_AISP debug mode is on"
   end
   #-------------------------------------------------------------

   #-------------------------------------------------------------

   def readAISP
      
      puts "============================"
      
      # --------------------------------
      # DFEP annotation => 18 Bytes
      
      data     = @stream.read(@aisp_length_annotation)
      @offset  = @offset + @aisp_length_annotation
      
      # --------------------------------
      # Packet ID => 2 Bytes
      # - version          = 000b
      # - type             = 0b
      # - sec header flag  = 1b
      # - apid             = 11(bits)
      
      data     = @stream.read(@length_packet_header_id)
      @offset  = @offset + @length_packet_header_id
      apid     = data.unpack('B*')[0].slice(5,11).to_i(2)      
      puts "[#{@offset.to_s.rjust(4,'0')}] APID          =>  #{data.unpack('H*')[0]}"
                                 
      # Packet Sequence Counter => 2 Bytes            
      data     = @stream.read(@length_packet_header_psc)
      @offset  = @offset + @length_packet_header_psc

      # Packet Data Field Length => 2 Bytes
      data     = @stream.read(@length_packet_header_data_len)
      @offset  = @offset + @length_packet_header_data_len
      length   = data.unpack('H*')[0].to_i(16)
      puts "[#{@offset.to_s.rjust(4,'0')}] Length        =>  #{data.unpack('H*')[0]}"      
      
      # Packet Data PUS version
      data     = @stream.read(@length_data_pus_version)
      @offset  = @offset + @length_data_pus_version
      length   = length - @length_data_pus_version     
      puts "[#{@offset.to_s.rjust(4,'0')}] PUS Version   =>  #{data.unpack('H*')[0]}"      

      # Packet Data Service Type
      data     = @stream.read(@length_data_service_type)
      @offset  = @offset + @length_data_service_type
      length   = length - @length_data_service_type     
      service  = data.unpack('H*')[0].to_i(16)
      puts "[#{@offset.to_s.rjust(4,'0')}] Service Type  =>  #{data.unpack('H*')[0]}"      
      
      # Packet Data Service Sub-type
      data     = @stream.read(@length_data_service_type)
      @offset  = @offset + @length_data_service_subtype
      length   = length - @length_data_service_subtype     
      subservice = data.unpack('H*')[0].to_i(16)
      puts "[#{@offset.to_s.rjust(4,'0')}] Serv  Subtype =>  #{data.unpack('H*')[0]}"      

      # Packet Data Destination Id
      data     = @stream.read(@length_data_destination_id)
      @offset  = @offset + @length_data_destination_id
      length   = length - @length_data_destination_id     
      puts "[#{@offset.to_s.rjust(4,'0')}] DestinationId =>  #{data.unpack('H*')[0]}"      

      # CUC Coarse Time
      cuc_coarse_time = readCUC
      
      puts "apid=#{apid} | service=#{service} | subservice=#{subservice} | cuc_coarse=#{cuc_coarse_time}"
      
      
      length   = length - @length_data_cuc_coarse_time
      
      data     = @stream.read(length+1)
      @offset  = @offset + length + 1
      
      
   end
   #-------------------------------------------------------------

   # CCSDS Unsegmented Time Code (CUC). 
   # The time from a defined epoch in seconds coded on 4 octets and
   # sub-seconds coded on 3 octets.
   # Time = C0 * 256^3 + C1 * 256^2 + C2 * 256 + C3 + F0 * 256-1 + F1 * 256-2 + F2 * 256-3
   def readCUC
      offset   = @offset +1
      
      data     = @stream.read(1)
      @offset  = @offset + 1      
      c0       = data.unpack('H*')[0].to_i(16)*(256**3)
      
      data     = @stream.read(1)
      @offset  = @offset + 1
      c1       = data.unpack('H*')[0].to_i(16)*(256**2)
      
      data     = @stream.read(1)
      @offset  = @offset + 1
      c2       = data.unpack('H*')[0].to_i(16)*(256**1)

      data     = @stream.read(1)
      @offset  = @offset + 1
      c3       = data.unpack('H*')[0].to_i(16)*(256**0)
      
      cuc_coarse_time = c0 + c1 + c2 + c3
      puts "[#{offset.to_s.rjust(4,'0')}] Coarse Time   =>  #{cuc_coarse_time}"
            
      new_time = (@gps_epoch+cuc_coarse_time)
            
      return Time.at(new_time).utc.to_datetime
   end
   #-------------------------------------------------------------


end

# ------------------------------------------------------------------------------


# MAIN script function
def main


   @locker              = nil
   @product             = nil
   @isDebugMode         = false
   @isForceMode         = false
   @isParseOnly         = false
   @filename            = ""
   @type                = ""

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT],
     ["--Parse", "-P",           GetoptLong::NO_ARGUMENT],
     ["--type", "-t",            GetoptLong::REQUIRED_ARGUMENT],
     ["--file", "-f",            GetoptLong::REQUIRED_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--file"     then @filename                   = arg.to_s
            when "--type"     then @type                       = arg.to_s.dup.downcase!
            when "--Debug"    then @isDebugMode                = true
            when "--check"    then @bChkOrganisation           = true
            when "--Parse"    then @isParseOnly                = true
            when "--Force"    then @isForceMode                = true
            when "--version"  then
               print("\nESA - ESRIN ", File.basename($0), " $Revision: 1.0 \n\n\n")
               exit (0)
            when "--usage"   then usage
            when "--help"    then usage                        
         end
      end
   rescue Exception
      exit(99)
   end

   if @filename == "" or @type == "" then
      usage
   end

   puts @filename
   puts @type

   if @type == "cadu" then
      parseCADU
   end

   if @type == "aisp" then
      parseAISP
   end

   exit

end

#---------------------------------------------------------------------

def parseAISP

   puts "parseAISP"

   aisp = S2_AISP.new(@filename)

   loop do
      aisp.readAISP
   end

end

#---------------------------------------------------------------------


def parseCADU
   cadu = S2_CADU.new(@filename)

   if cadu.lookUpSync == true then
      puts "ASM found at #{cadu.offset}"
   else
      puts "no ASM found"
      exit(99)
   end

   loop do
      cadu.readCADU
   end
end

#---------------------------------------------------------------------

def usage
   fullpathFile = `which #{File.basename($0)}`
   puts File.basename($0)
   puts fullpathFile
   system("head -22 #{fullpathFile}")
   exit
end

#-------------------------------------------------------------

#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

