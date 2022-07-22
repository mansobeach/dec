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

require 'rexml/document'
require 'writeexcel'

module E2E

class ReadConfigE2ESPM

   include REXML

   #-------------------------------------------------------------
  
   # Class constructor
   def initialize(filename = "/Users/borja/Projects/dec/code/e2e/data.cfg", debug = false)
      @filename            = filename
      @isDebugMode         = debug
      if @isDebugMode == true then
         self.setDebugMode
      end
      @arrAttrNonReader    = ["filename", "isDebugMode", "arrAttrNonReader"]
      
      checkModuleIntegrity
      
      createNewExcel
      
      if filename != "" then
         ret = loadData
         @workbook.close
      end
   end
   #-------------------------------------------------------------
   
   # Set the flag for debugging on
   def setDebugMode
      @isDebugMode = true
      puts "ReadConfigE2ESPM debug mode is on"
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
private

   def initVariables
      return
   end
   #-------------------------------------------------------------

   # Check that everything needed is present
   def checkModuleIntegrity
      bDefined = true
      bCheckOK = true
      if bCheckOK == false then
        puts "ReadConfigE2ESPM::checkModuleIntegrity FAILED !\n\n"
        exit(99)
      end
   end
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------
   
   # Load the file into the internal struct File defined in the
   # class Constructor. See initialize.
   def loadData
      begin
         fileDecode        = File.new(@filename)
         xmlFile           = REXML::Document.new(fileDecode)
         if @isDebugMode == true then
            puts "\nParsing #{@filename}"
         end
      rescue Exception => e
         puts
         puts "ERROR XML Parsing #{@filename}"
         puts e
         puts
         return false
      end
      
      XPath.each(xmlFile, "configuration/gauge_configurations"){
         |gauges|
         
         createSheetGauges
         
         row = 1
         
         XPath.each(gauges, "gauge_configuration/"){
            |gauge|
            
            XPath.each(gauge, "name/"){
               |name|                
               # puts name.text              
               @sheetGauges.write(row, 0, name.text)
            }
            
            XPath.each(gauge, "system/"){
               |system|                
               # puts system.text
               @sheetGauges.write(row, 1, system.text)   
            }

            XPath.each(gauge, "explicit_reference/"){
               |explicit_reference|                
               # puts explicit_reference.text
               @sheetGauges.write(row, 2, explicit_reference.text)   
            }

            XPath.each(gauge, "DIM_signature/"){
               |signature|                
               # puts signature.text
               @sheetGauges.write(row, 3, signature.text)   
            }

            XPath.each(gauge, "update_type/"){
               |update_type|                
               # puts update_type.text
               @sheetGauges.write(row, 4, update_type.text)   
            }


            XPath.each(gauge, "overwrite/"){
               |overwrite|                
               # puts overwrite.text
               @sheetGauges.write(row, 5, overwrite.text)   
            }



            row = row + 1
            
             # puts gauge
         }
         
      }


      puts "creating sheet annotations"

      createSheetAnnotations

      row = 1

      XPath.each(xmlFile, "configuration/annotation_configurations"){
         |annotations|
         
         XPath.each(annotations, "annotation_configuration/"){
            |annotation|
            
            XPath.each(annotation, "name/"){
               |name|                
               # puts name.text              
               @sheetAnnotations.write(row, 0, name.text)
            }

            XPath.each(annotation, "DIM_signature/"){
               |signature|                
               # puts signature.text              
               @sheetAnnotations.write(row, 1, signature.text)
            }

            XPath.each(annotation, "explicit_reference/"){
               |explicit_reference|                
               # puts explicit_reference.text
               @sheetAnnotations.write(row, 2, explicit_reference.text)   
            } 
         
            row = row + 1
         
         }
         
         
         
      }


   end   
   #-------------------------------------------------------------
   
   #-------------------------------------------------------------

   def createNewExcel
      @workbook   = WriteExcel.new("e2e_config.xls")   
      return @workbook
   end
   #-------------------------------------------------------------

   def createSheetGauges
      @sheetGauges  = @workbook.add_worksheet
      @sheetGauges.freeze_panes(1, 0)
      format      = @workbook.add_format
      format.set_bold
      @sheetGauges.write(0, 0, "Gauge_Name", format)
      @sheetGauges.write(0, 1, "System", format)
      @sheetGauges.write(0, 2, "Explicit_Reference", format)
      @sheetGauges.write(0, 3, "DIM_signature", format)
      @sheetGauges.write(0, 4, "Update_Type", format)
      @sheetGauges.write(0, 5, "Overwrite", format)
   end
   #-------------------------------------------------------------
   
   def createSheetAnnotations
      @sheetAnnotations  = @workbook.add_worksheet
      @sheetAnnotations.freeze_panes(1, 0)
      format      = @workbook.add_format
      format.set_bold
      @sheetAnnotations.write(0, 0, "Annotation_Name", format)
      @sheetAnnotations.write(0, 1, "DIM_signature", format)
      @sheetAnnotations.write(0, 2, "Explicit_Reference", format)
   end
   #-------------------------------------------------------------




end # class

end # module
