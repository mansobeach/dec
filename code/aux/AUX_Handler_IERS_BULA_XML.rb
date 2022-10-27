#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #AUX_Handler_IERS_BULA_XML class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component
### 
### Git: $Id: AUX_Handler_IERS_BULA_XML.rb
###
### Module AUX management
### 
###
#########################################################################

### IERS Bulletin A
### https://datacenter.iers.org/data/xml/bulletina-xxxv-040.xml
### https://datacenter.iers.org/data/latestVersion/bulletinA.txt

require 'rexml/document'
require 'roman-numerals'

require 'aux/AUX_Handler_Generic'


module AUX

AUX_Pattern_IERS_BULA_XML = "bulletina-*-*.xml"

class AUX_Handler_IERS_BULA_XML < AUX_Handler_Generic
   
   include REXML

   ## -------------------------------------------------------------
      
   ## Class constructor.
   ## * entity (IN):  full_path_filename
   def initialize(full_path, target, dir = "", logger = nil, isDebug = false)
      @target = target
      
      super(full_path, dir, logger, isDebug)
      
      case @target.upcase
         when "NAOS" then convert_NAOS
         when "S3"   then convert_S3
         when "POD"  then convert_POD
         else raise "#{@target.upcase} not supported"
      end

   end   
   ## -------------------------------------------------------------
   
   ## Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      @logger.debug("AUX_Handler_IERS_BULA_XML debug mode is on")
   end
   ## -------------------------------------------------------------
   
   # NS1_TEST_AUX_BULA___20220707T000000_20230706T000000_0001.xml
   def rename
      @newName          = "#{@mission}_#{@fileClass}_#{@fileType}_#{@strValidityStart}_#{@strValidityStop}_#{@fileVersion}.#{@extension}"
      super(@newName)
      return @full_path_new
   end
   ## -------------------------------------------------------------

   def convert
      @strCreation = self.getCreationDate 
      parse
      return rename
   end
   ## -------------------------------------------------------------

private
   
   ## -----------------------------------------------------------
   
   def convert_NAOS
      @mission    = "NS1"
      @fileType   = "AUX_BULA__"
      @extension  = "xml"
   end
   ## -----------------------------------------------------------

   def convert_S3
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

   def convert_POD
      raise "not implemented for #{@target}"
   end
   ## -------------------------------------------------------------

   def parse
      if @isDebugMode == true then
         @logger.debug("AUX_Handler_IERS_BULA_XML::parse")
      end

      fileBULA          = File.new(@full_path)
      xmlFile           = REXML::Document.new(fileBULA)
      path              = "/EOP/data/timeSeries/time"
      
      bFirst = true

      aDay, aMonth, aYear              = nil
      firstDay, firstMonth, firstYear  = nil
      lastDay, lastMonth, lastYear     = nil

      XPath.each(xmlFile, path){
         |time|

         XPath.each(time, "dateYear"){
            |year|
            aYear = year.text
         }

         XPath.each(time, "dateMonth"){
            |month|
            aMonth = month.text
         }

         XPath.each(time, "dateDay"){
            |day|
            aDay = day.text
         }

         if bFirst == true then
            bFirst      = false
            firstDay    = aDay
            firstMonth  = aMonth
            firstYear   = aYear
            next
         end

         lastDay     = aDay
         lastMonth   = aMonth
         lastYear    = aYear

      }

      @strValidityStart  = "#{firstYear}#{firstMonth}#{firstDay}T000000"
      @strValidityStop   = "#{lastYear}#{lastMonth}#{lastDay}T000000"
   end
   ## -------------------------------------------------------------
      
end # class

end # module

