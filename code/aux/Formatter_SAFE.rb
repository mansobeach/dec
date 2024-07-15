#!/usr/bin/env ruby

### ESA SAFE Format
# https://earth.esa.int/eogateway/activities/safe-the-standard-archive-format-for-europe/safe-2.x-basic-information

require 'date'
require 'fileutils'
require 'rexml/document'

module AUX

class Formatter_SAFE
   
   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, new_name, target, dir = "", logger = nil, isDebug = false)
      @full_path     = full_path
      @target        = target
      @dir           = dir
      @logger        = logger
      @new_name      = new_name
      @isDebugMode   = isDebug

      if @isDebugMode == true then
         @logger.debug("Formatter_SAFE::initialize conversion start")
         @logger.debug(full_path)
         @logger.debug(new_name)
         @logger.debug(dir)
         @logger.debug(target)
      end

      if @target.length == 2 then
         @unit = "A"
      end
      
      if @target.length >= 3 then
         @unit = @target.slice(2,3)
      end

      createStructure

      copyData

      case @target
         when "S1"   then createManifestS1
         when "S1A"  then createManifestS1
         when "S1B"  then createManifestS1
         else
            raise "SAFE formatter not supported for target #{@target}"
      end

      closeSAFE

      @logger.info("[AUX_001] #{@new_name} generated from #{File.basename(full_path)}")

      if @isDebugMode == true then
         @logger.debug("Formatter_SAFE::initialize conversion completed")
      end
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("Formatter_SAFE debug mode is on")
   end
   ## -------------------------------------------------------------
   
   def createStructure
      Dir.chdir(@dir)
      # @logger.debug("Create structure: start #{@dir}")
      prevDir = Dir.pwd
      FileUtils.mkdir_p(".#{@new_name}")
      Dir.chdir(".#{@new_name}")
      FileUtils.mkdir_p("data")
      # FileUtils.mkdir_p("support")
      @safe_dir_root    = Dir.pwd
      @safe_dir_data    = "#{Dir.pwd}/data"
      @safe_dir_support = "#{Dir.pwd}/support"
      Dir.chdir(prevDir)
      # @logger.debug("Create structure: end")
   end
   ## -------------------------------------------------------------

   def closeSAFE
      Dir.chdir(@dir)
      # @logger.debug("Close SAFE dir structure: start #{Dir.pwd}")
      FileUtils.mv(".#{@new_name}", @new_name, force: true, verbose: false)
      FileUtils.chmod_R(0755, @new_name, force: true, verbose: false)
      # @logger.debug("Close SAFE dir structure: end")
   end
   ## -------------------------------------------------------------

   def copyData
      # @logger.debug("Copy data: start")
      FileUtils.cp_lr(@full_path, @safe_dir_data)
      # @logger.debug("Copy data: end")
   end
   ## -------------------------------------------------------------

   def createManifestS1
      if @isDebugMode == true then
         @logger.debug("createManifestS1: start #{Dir.pwd}")
      end
      type        = @new_name.slice(4,7)
      prevDir     = Dir.pwd
      str_now     = Time.now.strftime("%Y-%m-%dT%H:%M:%S.000000")
      @xmlFile    = REXML::Document.new
      declaration = REXML::XMLDecl.new
      declaration.encoding = "UTF-8"
      @xmlFile << declaration
     
      @xmlRoot = @xmlFile.add_element("xfdu:XFDU")
      @xmlRoot.add_namespace('xmlns:s1auxsar', 'http://www.esa.int/safe/sentinel-1.0/sentinel-1/auxiliary/sar')
      @xmlRoot.add_namespace('xmlns:safe', 'http://www.esa.int/safe/sentinel-1.0/sentinel-1/auxiliary/sar')
      @xmlRoot.add_namespace('xmlns:xfdu', 'urn:ccsds:schema:xfdu:1')
      @xmlRoot.add_attribute('version', 'esa/safe/sentinel-1.0/sentinel-1/auxiliary/sar')
      
      informationPackageMap = @xmlRoot.add_element("informationPackageMap")
      rootData = informationPackageMap.add_element("xfdu:contentUnit")
      rootData.add_attribute('dmdID', "platform generalProductInformation")
      rootData.add_attribute('pdiID', "Processing")
      
      case type
         when "AUX_TEC" then rootData.add_attribute('textinfo', "Sentinel-1 iononpheric model prediction")
         when "AUX_TRO" then rootData.add_attribute('textinfo', "Sentinel-1 troposheric model prediction")
         when "AUX_WND" then rootData.add_attribute('textinfo', "Sentinel-1 wind speed and direction prediction")
         when "AUX_WAV" then rootData.add_attribute('textinfo', "Sentinel-1 wavewatch III model stokes drift")
         when "AUX_ICE" then rootData.add_attribute('textinfo', "Sentinel-1 ice model prediction")
         else
            raise "#{type} not covered by Formatter_SAFE::createManifestS1 "
      end

      contentUnit = rootData.add_element("xfdu:contentUnit")
      contentUnit.add_attribute('repID', "auxSchema")
      contentUnit.add_attribute('unitType', "Measurement Data Unit")

      dataObjectPointer = contentUnit.add_element("dataObjectPointer")
      dataObjectPointer.add_attribute('dataObjectID', "auxData")

      metadataSection = @xmlRoot.add_element("metadataSection")
      metadataObject  = metadataSection.add_element("metadataObject")
      metadataObject.add_attribute('ID', "processing")
      metadataObject.add_attribute('category', "PDI")
      metadataObject.add_attribute('classification', "PROVENANCE")
 
      metadataWrap = metadataObject.add_element("metadataWrap")
      metadataWrap.add_attribute('mimeType', "text/xml")
      metadataWrap.add_attribute('textInfo', "Processing")
      metadataWrap.add_attribute('vocabularyName', "SAFE")

      metadata = metadataWrap.add_element("xmlData")
      data_safe_processing = metadata.add_element("safe:processing")
      data_safe_processing.add_attribute('name', "#{type} Processing")
      data_safe_processing.add_attribute('start', "#{str_now}")
      data_safe_processing.add_attribute('stop', "#{str_now}")

      data_safe_processing_facility = data_safe_processing.add_element("safe:facility")
      data_safe_processing_facility.add_attribute('name', "ADGS")
      data_safe_processing_facility.add_attribute('country', "Spain")
      data_safe_processing_facility.add_attribute('organisation', "ESA")
      data_safe_processing_facility.add_attribute('site', "ADGS")

      data_safe_processing_software = data_safe_processing.add_element("safe:software")
      data_safe_processing_software.add_attribute('name', "ADGS")
      data_safe_processing_software.add_attribute('version', AUX::VERSION)

      metadataObject  = metadataSection.add_element("metadataObject")
      metadataObject.add_attribute('ID', "platform")
      metadataObject.add_attribute('category', "DMD")
      metadataObject.add_attribute('classification', "DESCRIPTION")

      metadataWrap = metadataObject.add_element("metadataWrap")
      metadataWrap.add_attribute('mimeType', "text/xml")
      metadataWrap.add_attribute('textInfo', "Platform Description")
      metadataWrap.add_attribute('vocabularyName', "SAFE")

      metadata = metadataWrap.add_element("xmlData")
      data_safe_platform = metadata.add_element("safe:platform")
      data_safe_platform_nssdcIdentifier = data_safe_platform.add_element("safe:nssdcIdentifier")
      data_safe_platform_nssdcIdentifier.text = "#{ENV['AUX_SAFE_NSSDCIDENTIFIER']}"
      data_safe_platform_familyName = data_safe_platform.add_element("safe:familyName")
      data_safe_platform_familyName.text = "#{ENV['AUX_SAFE_FAMILYNAME']}"
      data_safe_platform_number = data_safe_platform.add_element("safe:number")
     
      data_safe_platform_number.text = "#{@unit}"
      data_safe_platform_instrument = data_safe_platform.add_element("safe:instrument")
      data_safe_platform_instrument_family = data_safe_platform_instrument.add_element("safe:familyName")
      data_safe_platform_instrument_family.add_attribute('abbreviation', "SAR")
      data_safe_platform_instrument_family.text = "Synthetic Aperture Radar"

=begin
    <metadataObject ID="platform" category="DMD" classification="DESCRIPTION">
      <metadataWrap mimeType="text/xml" textInfo="Platform Description" vocabularyName="SAFE">
        <xmlData>
          <safe:platform>
            <safe:nssdcIdentifier>2014-016A</safe:nssdcIdentifier>
            <safe:familyName>SENTINEL-1</safe:familyName>
            <safe:number>A</safe:number>
            <safe:instrument>
              <safe:familyName abbreviation="SAR">Synthetic Aperture Radar</safe:familyName>
            </safe:instrument>
          </safe:platform>
        </xmlData>
      </metadataWrap>
    </metadataObject>
=end

      metadataObject  = metadataSection.add_element("metadataObject")
      metadataObject.add_attribute('ID', "standAloneProductInformation")
      metadataObject.add_attribute('category', "DMD")
      metadataObject.add_attribute('classification', "DESCRIPTION")

      metadataWrap = metadataObject.add_element("metadataWrap")
      metadataWrap.add_attribute('mimeType', "text/xml")
      metadataWrap.add_attribute('textInfo', "Stand Alone Product Information")
      metadataWrap.add_attribute('vocabularyName', "SAFE")

      xml_data = metadataWrap.add_element("xmlData")
      xml_data_s1auxsar_standAloneProductInformation     = xml_data.add_element("s1auxsar:standAloneProductInformation")
      xml_data_s1auxsar_auxProductType                   = xml_data_s1auxsar_standAloneProductInformation.add_element("s1auxsar:auxProductType")               
      xml_data_s1auxsar_auxProductType.text = type
      xml_data_s1auxsar_validity                         = xml_data_s1auxsar_standAloneProductInformation.add_element("s1auxsar:validity") 
      xml_data_s1auxsar_validity.text = DateTime.strptime(@new_name.slice(13,15),"%Y%m%dT%H%M%S").strftime("%Y-%m-%dT%H:%M:%S.000000")
      xml_data_s1auxsar_generation                       = xml_data_s1auxsar_standAloneProductInformation.add_element("s1auxsar:generation")
      xml_data_s1auxsar_generation.text = "#{str_now}"
      xml_data_s1auxsar_instrumentConfigurationId        = xml_data_s1auxsar_standAloneProductInformation.add_element("s1auxsar:instrumentConfigurationId")
      xml_data_s1auxsar_instrumentConfigurationId.text   = "#{ENV['AUX_S1_INSTRUMENTCONFIGURATIONID']}"
      xml_data_s1auxsar_generation                       = xml_data_s1auxsar_standAloneProductInformation.add_element("s1auxsar:changeDescription")

      writeFileManifest

      if @isDebugMode == true then
         @logger.debug("createManifestS1: end")
      end
   end
   ## -------------------------------------------------------------

private

   def writeFileManifest
      Dir.chdir(@dir)
      Dir.chdir(".#{@new_name}")
      if @isDebugMode == true then
         @logger.debug("writeManifest: start #{Dir.pwd}")
      end
      formatter = REXML::Formatters::Pretty.new(4)
      formatter.compact = true
      fh = File.new("manifest.safe","w")
      fh.puts formatter.write(@xmlFile.root, "")
      fh.close
      
      if @isDebugMode == true then
         @logger.debug("writeManifest: end")
      end
   end
   ## -------------------------------------------------------------
      
end # class

end # module

