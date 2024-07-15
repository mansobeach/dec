#!/usr/bin/env ruby

# This class allows minarc to handle ADGS files:

=begin
> S1B_AUX_CAL_V20190514T090000_G20210104T140612.SAFE
> S2__OPER_AUX_UT1UTC_PDMC_20240513T000000_V20170101T000000_21000101T000000.txt
> NOAA Ice Mapping System => ims2024133_4km_v1.3.nc.gz
=end

require 'json'
require 'filesize'
require 'date'
require 'rexml/document'

require 'cuc/Converters'

include REXML
include CUC::Converters

class Handler_ADGS
   @type                = ""
   @filename            = ""
   @filename_original   = nil
   @validated           = false
   @start               = nil
   @stop                = nil
   @generation_date     = nil
   @full_path_filename  = ""
   @size                = 0
   @size_in_disk        = 0

   attr_reader :archive_path, :size, :size_in_disk, :size_original, :type, :filename, :filename_original, :start, :stop, :str_start, :str_stop, :json_metadata

   ## -----------------------------------------------------------

   ## Class constructor

   ## Name now must be a full_path one
   def initialize (name, destination = nil, args = {})

      @logger      = args[:logger]
      @isDebugMode = args[:isDebugMode]

      if @isDebugMode == true then
         @logger.debug("Handler_ADGS::#{name}")
      end

      if name[0,1] != '/' then
         @bDecodeNameOnly = true
      else
         @bDecodeNameOnly = false
      end

      updated_name         = false
      archRoot             = ENV['MINARC_ARCHIVE_ROOT']
      @size_original       = File.size(name)
      @full_path_filename  = name
      @filename            = File.basename(name, ".*")
      @filename_original   = File.basename(name)
      @archive_path        = ""
      @validated           = false
      @hmetadata           = Hash.new
      mission              = @filename.slice(0,3)

      # ----------------------------------------------------
      # beware it is a directory
      if name.include?(".SAFE") == true then
         @hmetadata        = decodeSAFE(name)
         # @json_metadata    = JSON.generate(@hmetadata)
         @json_metadata    = @hmetadata
         @start            = self.str2date( @hmetadata["beginningDateTime"] )
         @stop             = Date.new(2100)
         @generation_date  = self.str2date( @hmetadata["processingDate"] )
         @type             = @hmetadata["productType"]
         @validated        = true

         if File.directory?(name) == true then
            @logger.debug(filename_original)
            prevDir              = Dir.pwd
            Dir.chdir("#{name}/..")
            @filename            = "#{File.basename(name)}.zip"
            @filename_original   = "#{File.basename(name)}.zip"
            cmd                  = "zip #{@filename_original} -m -r #{File.basename(name)}"
            if @isDebugMode == true then
               @logger.debug(cmd)
            end
            ret = system(cmd)

            Dir.chdir(prevDir)
            if ret == false then
               raise "Fatal Error Handler_ADGS::exec #{cmd}"
            end
            # name                 = "#{name.dup}.zip"
            updated_name         = true
            @full_path_filename  = "#{name}.zip"
            @size_original       = File.size(@full_path_filename)
         end
      end

      # ----------------------------------------------------
      #
      # ims2024133_4km_v1.3.nc

      if @validated == false and @filename.length == 22 or @filename.length == 25 then
         @start            = DateTime.strptime(@filename.slice(3,7),"%Y%j")
         @stop             = DateTime.strptime(@filename.slice(3,7),"%Y%j")
         @type             = "NOAAIMS4KM"
         @generation_date  = @start
         @validated        = true
      end
      # ----------------------------------------------------

      # ----------------------------------------------------
      # S2__OPER_AUX_UT1UTC_PDMC_20240513T000000_V20170101T000000_21000101T000000.txt

      if @validated == false and @filename.length >= 73 and @filename.slice(3,1) == "_" and @filename.slice(8,1) == "_" &&
         @filename.slice(19,1) == "_" and @filename.slice(24,1) == "_" and @filename.slice(40,1) == "_" &&
         @filename.slice(41,1) == "V"
      then
         @str_start        = @filename.slice(42, 15)
         @str_stop         = @filename.slice(58, 15)
         @type             = @filename.slice(9,10)
         @generation_date  = self.str2date(@filename.slice(25, 15))
         @start            = self.str2date(@filename.slice(42, 15))
         @stop             = self.str2date(@filename.slice(58, 15))
         @validated        = true
      end

      # ----------------------------------------------------

      if @validated == false then
         puts @filename.length
         puts "#{@filename} not supported by Handler_ADGS"
         puts
         exit(99)
      end

      # ----------------------------------------------------

      if @bDecodeNameOnly == true then
         return
      end

      # ----------------------------------------------------

      @archive_path  = "#{archRoot}/#{mission}/#{@type}/#{Date.today.strftime("%Y")}/#{Date.today.strftime("%m")}/#{Date.today.strftime("%d")}"
      
      if updated_name == false and
         File.extname(name).downcase != ".zip" and
         File.extname(name).downcase != ".tgz" and
         File.extname(name).downcase != ".gz" and
         File.extname(name).downcase != ".7z" then
         compressFile(name)
      else
         if updated_name == false then
            @full_path_filename  = name
         end
      end

      @size          = File.size(@full_path_filename)
      result         = `du -hs #{@full_path_filename}`

      begin
         @size_in_disk  = Filesize.from("#{result.split(" ")[0]}iB").to_int
      rescue Exception => e
         @size_in_disk  = 0
      end

#      if args[:bDeleteSource] == true then
#         File.delete(@full_path_filename)
#      end

   end

   # ------------------------------------------------------------

   def isValid
      return @validated
   end

   # ------------------------------------------------------------

   def fileType
      return @type
   end

   #-------------------------------------------------------------

   def start_as_dateTime
      return @start
   end

   #-------------------------------------------------------------

   def stop_as_dateTime
      return @stop
   end

   #-------------------------------------------------------------

   def generationDate
      return @generation_date
   end

   # ------------------------------------------------------------

   def fileName
      return @full_path_filename
   end
   # ------------------------------------------------------------


private

   ## -----------------------------------------------------------

   def compressFile(full_path_name)
      if @isDebugMode == true then
         @logger.info("START => Handler_ADGS::#{__method__.to_s} : #{full_path_name}")
      end

      filename       = File.basename(full_path_name, ".*")
      full_path      = File.dirname(full_path_name)

      # @logger.debug("[ARC_XXX] Handler_ADGS::compressFile full_path : #{full_path}")
      # @logger.debug("[ARC_XXX] Handler_ADGS::compressFile filename  : #{filename}")

      if File.exist?("#{full_path}/#{filename}.7z") == true then
         @full_path_filename  = "#{full_path}/#{filename}.7z"
         return
      end

      # Ubuntu
      cmd = "7z a #{full_path}/#{filename}.7z #{full_path_name} > /dev/null"

      # MacOS
      # cmd = "7za a #{full_path}/#{filename}.7z #{full_path_name} -sdel"

      ret = system(cmd)

      if ret == false then
         @logger.error("[ARC_XXX]] Fatal Error in Handler_ADGS::compressFile")
         @logger.error("#{cmd}")
         puts "Fatal Error in Handler_ADGS::compressFile"
         puts
         puts cmd
         puts
         puts "Deleting eventual previous compressed file #{full_path}/#{filename}.7z"
         puts
         File.delete("#{full_path}/#{filename}.7z")
         exit(99)
      else
         File.delete(full_path_name)
      end

      @full_path_filename  = "#{full_path}/#{filename}.7z"

      if @isDebugMode == true then
         @logger.info("END => Handler_ADGS::#{__method__.to_s}")
      end

   end

   ## -----------------------------------------------------------

   def decodeSAFE(name)
      if @isDebugMode == true then
         @logger.info("START => Handler_ADGS::#{__method__.to_s} : #{name}")
      end
      safe_metadata  = Hash.new

      safe_metadata["processorName"]      = "MISSING"
      safe_metadata["processorVersion"]   = "MISSING"

      manifest       = "#{name}/manifest.safe"

      if File.exist?(manifest) == false then
         raise "Handler_ADGS Error : #{manifest} not found"
      end

      manifest_file     = File.new(manifest)
      xml_file          = REXML::Document.new(manifest_file)

      XPath.each(xml_file, "xfdu:XFDU/metadataSection/metadataObject/metadataWrap/xmlData/safe:processing"){ |node|
         safe_metadata["processingDate"] = node.attributes["start"]

         XPath.each(node, "safe:facility"){|facility|
            safe_metadata["processingCenter"] = facility.attributes["site"]
         }
         
         XPath.each(node, "safe:software"){|software|
            safe_metadata["processorName"]      = software.attributes["name"]
            safe_metadata["processorVersion"]   = software.attributes["version"]
         }

      }

      XPath.each(xml_file, "xfdu:XFDU/metadataSection/metadataObject/metadataWrap/xmlData/safe:platform"){ |node|

         XPath.each(node, "safe:familyName"){|family|
            safe_metadata["platformShortName"] = family.text
         }

         XPath.each(node, "safe:number"){|number|
            safe_metadata["platformSerialIdentifier"] = number.text
         }

         XPath.each(node, "safe:instrument/safe:familyName"){|family|
            safe_metadata["instrumentShortName"] = family.attributes["abbreviation"]
         }

      }

      case safe_metadata["platformShortName"]
      when "SENTINEL-1" then
         XPath.each(xml_file, "xfdu:XFDU/metadataSection/metadataObject/metadataWrap/xmlData/s1auxsar:standAloneProductInformation"){ |node|
            
            XPath.each(node, "s1auxsar:auxProductType"){|auxProductType|
               safe_metadata["productType"] = auxProductType.text
            }

            XPath.each(node, "s1auxsar:validity"){|validity|
               safe_metadata["beginningDateTime"] = validity.text
               if @isDebugMode == true then
                  @logger.debug("SAFE beginningDateTime => #{safe_metadata["beginningDateTime"]}")
               end
            }

            XPath.each(node, "s1auxsar:generation"){|generation|
               safe_metadata["productGeneration"] = generation.text
            }

            XPath.each(node, "s1auxsar:instrumentConfigurationId"){|instrumentConfigurationId|
               safe_metadata["instrumentConfigurationID"] = instrumentConfigurationId.text
            }
         }
      else
         raise "Hander_ADGS::decodeSAFE platformShortName #{safe_metadata["platformShortName"]} not supported"
      end

      if @isDebugMode == true then
         @logger.info("END => Handler_ADGS::#{__method__.to_s}")
      end
      return safe_metadata
   end

   ## -----------------------------------------------------------


   ## -----------------------------------------------------------

end
