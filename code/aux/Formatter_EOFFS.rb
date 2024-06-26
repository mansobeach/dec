#!/usr/bin/env ruby

### ESA EOFFS Format

require 'fileutils'
require 'rexml/document'

module AUX

class Formatter_EOFFS
   
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
         @logger.debug("Formatter_EOFFS::initialize conversion start")
         @logger.debug(full_path)
         @logger.debug(new_name)
         @logger.debug(dir)
         @logger.debug(target)
      end

      createStructure

      @logger.info("[AUX_001] #{@new_name}.TGZ generated from #{File.basename(full_path)}")

      if @isDebugMode == true then
         @logger.debug("Formatter_EOFFS::initialize conversion completed")
      end
   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("Formatter_EOFFS debug mode is on")
   end
   ## -------------------------------------------------------------
   
   def createStructure
      Dir.chdir(@dir)
      if @isDebugMode == true then
         @logger.debug("Create structure: start #{@dir}")
      end
      prevDir = Dir.pwd
      FileUtils.mkdir_p(".#{@new_name}")
      FileUtils.mv(@full_path, ".#{@new_name}/#{@new_name}.DBL")
      Dir.chdir(".#{@new_name}")
      
      createHeader

      cmd = "tar --remove-files -czf #{@new_name}.TGZ #{@new_name}.HDR #{@new_name}.DBL"
      if @isDebugMode == true then
         @logger.debug(cmd)
      end
      system(cmd)

      FileUtils.chmod(0644, "#{@new_name}.TGZ")
      FileUtils.mv("#{@new_name}.TGZ", ".." )
      Dir.chdir(prevDir)
      FileUtils.rmdir(".#{@new_name}")
      
      if @isDebugMode == true then
         @logger.debug("Create structure: end #{@dir}")
      end
   end
   ## -------------------------------------------------------------

   ## -------------------------------------------------------------

   def createHeader
      if @isDebugMode == true then
         @logger.debug("createHeader: start #{Dir.pwd}")
      end
      type        = @new_name.slice(4,7)
      prevDir     = Dir.pwd
      str_now     = Time.now.strftime("%Y-%m-%dT%H:%M:%S.000000")
      @xmlFile    = REXML::Document.new
      declaration = REXML::XMLDecl.new
      declaration.encoding = "UTF-8"
      @xmlFile << declaration
     
      @xmlRoot = @xmlFile.add_element("Earth_Explorer_Header")
      @xmlRoot.add_namespace('xmlns:xsi', 'http://www.w3.org/2001/XMLSchema-instance')
      @xmlRoot.add_namespace('xmlns', '"http://eop-cfi.esa.int')

      fixed_header      = @xmlRoot.add_element("Fixed_Header")
      file_name         = fixed_header.add_element("File_Name")
      file_name.text    = @new_name 
      file_description  = fixed_header.add_element("File_Description")
      file_description.text = "File AUX_UT1UTC"
      notes             = fixed_header.add_element("Notes")
      mission           = fixed_header.add_element("Mission")
      mission.text      = "#{ENV['AUX_EOFFS_MISSION']}"
      file_class        = fixed_header.add_element("File_Class")
      file_class.text   = "OPER"
      file_type         = fixed_header.add_element("File_Type")
      file_type.text    = "AUX_UT1UTC"
      file_version      = fixed_header.add_element("File_Version")
      file_version.text = "0001"
      validity_period   = fixed_header.add_element("Validity_Period")
      validity_start    = validity_period.add_element("Validity_Start")
      validity_start.text = "UTC=#{Date.strptime(@new_name.slice(42,15) ,"%Y%m%dT%H%M%S").strftime("%Y-%m-%dT%H:%M:%S")}"
      validity_stop     = validity_period.add_element("Validity_Stop")
      validity_stop.text = "UTC=#{Date.strptime(@new_name.slice(58,15) ,"%Y%m%dT%H%M%S").strftime("%Y-%m-%dT%H:%M:%S")}"
      source            = fixed_header.add_element("Source")
      system            = source.add_element("System")
      system.text       = "ADG_"
      creator           = source.add_element("Creator")
      creator.text      = "IERS"
      creator_version   = source.add_element("Creator_Version")
      creator_version.text = "1.0"
      creation_date     = source.add_element("Creation_Date")
      creation_date.text = "UTC=#{Date.strptime(@new_name.slice(25,15) ,"%Y%m%dT%H%M%S").strftime("%Y-%m-%dT%H:%M:%S")}"
      
      formatter = REXML::Formatters::Pretty.new(4)
      formatter.compact = true
      fh = File.new("#{@new_name}.HDR","w")
      fh.puts formatter.write(@xmlFile.root, "")
      fh.close

      if @isDebugMode == true then
         @logger.debug("createManifestS1: end")
      end
   end
   ## -------------------------------------------------------------

private

   ## -------------------------------------------------------------
      
end # class

end # module

