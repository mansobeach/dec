#!/usr/bin/env ruby

# == Synopsis
#
# This is the command line tool to perform a sanity check of the
# Sentinel-2 End-User Product as per [PSD]

# == Usage
#  sanityCheck_S2Product.rb
#     --help                shows this help
#     --Debug               shows Debug info during the execution
#     --Force               force mode
#     --version             shows version number      
# 

# == Author
# Borja Lopez Fernandez
#
# == Copyleft
# ESA / ESRIN


#########################################################################
#
# ===       
#
# === Written by Borja Lopez Fernandez
#
# === ESA / ESRIN
# 
#
#
#########################################################################

require 'rubygems'
require 'getoptlong'
require 'spreadsheet'
require 'writeexcel'

require 'cuc/Converters'
require 'esa/S2ReadProductMetadataFile'


include CUC::Converters


# ------------------------------------------------------------------------------
#
# ------------------------------------------------------------------------------

@PRODUCT_L0             = "L0"
@PRODUCT_L1A            = "L1A"
@PRODUCT_L1B            = "L1B"
@PRODUCT_L1C            = "L1C"
@PRODUCT_TCI            = "TCI"
@PRODUCT_ERR            = "ERROR"

@FILETYPE_PRODUCT_L0    = "PRD_MSIL0P"
@FILETYPE_PRODUCT_L1A   = "PRD_MSIL1A"   
@FILETYPE_PRODUCT_L1B   = "PRD_MSIL1B"   
@FILETYPE_PRODUCT_L1C   = "PRD_MSIL1C"   

@FILETYPE_METADATA_L0   = "MTD_SAFL0P"
@FILETYPE_METADATA_L1A  = "MTD_SAFL1A"   
@FILETYPE_METADATA_L1B  = "MTD_SAFL1B"   
@FILETYPE_METADATA_L1C  = "MTD_SAFL1C"   

@SCHEMA_PRODUCT_METADATA_L0   = "S2_User_Product_Level-0_Metadata.xsd"
@SCHEMA_PRODUCT_METADATA_L1A  = "S2_User_Product_Level-1A_Metadata.xsd"
@SCHEMA_PRODUCT_METADATA_L1B  = "S2_User_Product_Level-1B_Metadata.xsd"
@SCHEMA_PRODUCT_METADATA_L1C  = "S2_User_Product_Level-1C_Metadata.xsd"

@SCHEMA_DIR_PRODUCT = "/Users/borja/Projects/dec/code/esa/PSD_schemas/schemas/"

# ------------------------------------------------------------------------------
#
# [GPP-DPM-IAS01]
# Repeat Cycle / Cycle Length = [1,143] orbits
# OrbCycle = [(OrbCounter - OrbOffset) modulo TotOrb] +1
#

@REL_ORBIT_MIN_VALUE = 1
@REL_ORBIT_MAX_VALUE = 143

# ------------------------------------------------------------------------------

# User_Product_Level-0.xsd

# ------------------------------------------------------------------------------


# MAIN script function
def main

   @locker        = nil
   @product       = nil
   @isDebugMode   = false
   @isForceMode   = false
   @reqST         = nil
   @isParseOnly   = false

   opts = GetoptLong.new(
     ["--Debug", "-D",           GetoptLong::NO_ARGUMENT],
     ["--Force", "-F",           GetoptLong::NO_ARGUMENT],
     ["--version", "-v",         GetoptLong::NO_ARGUMENT],
     ["--help", "-h",            GetoptLong::NO_ARGUMENT],
     ["--Parse", "-P",           GetoptLong::NO_ARGUMENT],
     ["--product", "-p",         GetoptLong::REQUIRED_ARGUMENT]
     )
   
   begin 
      opts.each do |opt, arg|
         case opt
            when "--product"  then @product     = arg.to_s
            when "--Debug"    then @isDebugMode = true
            when "--Parse"    then @isParseOnly = true
            when "--Force"    then @isForceMode = true
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

   if @product == nil then
      usage
   end

   checkDependencies

   init

   @product_name = @product

   checkProduct


   Dir.chdir(@prevDir)
   exit(0)

end

#---------------------------------------------------------------------

def checkDependencies
   return
end

#---------------------------------------------------------------------

def init
   @product_name        = nil
   @product_level       = nil
   @product_filetype    = nil
   @filename_metadata   = nil
   @rel_orbit           = nil
   @val_start           = nil
   @val_end             = nil
end
#-------------------------------------------------------------


#-------------------------------------------------------------

def checkProduct
   if @isDebugMode == true then
      puts "checkProduct"
   end

   puts @product

   # ---------------------------------------------
   # Check that product root element is a directory
   
   if File.directory?(@product) == false then
      puts "ERROR #{File.basename(@product)} is not a directory"
      exit(99)  
   end
   # ---------------------------------------------

   # ---------------------------------------------
   # Check product type either SAFE either DIMAP

   retVal = checkProductName

   if retVal == false then
      puts "ERROR checking product name"
   end

   # ---------------------------------------------


   @prevDir = Dir.pwd
   
   # Do check for the different product levels:PRD_MSIL0P
   
   
   Dir.chdir(File.basename(@product))

   puts Dir["*"]


   # ---------------------------------------------
   # Check product INSPIRE.xml

   retVal = checkInspire

   if retVal == false then
      puts "\nERROR in INSPIRE.xml checks :-(\n"
   end

   # ---------------------------------------------

   # ---------------------------------------------
   # Check product metadata file

   retVal = checkProductMetadataFile

   if retVal == false then
      puts "\nERROR in Product Metadata checks :-(\n"
   end

   # ---------------------------------------------



   Dir.chdir(@prevDir)


   # ---------------------------------------------

   exit

  
end

#-------------------------------------------------------------

# S2A_OPER_PRD_MSIL0P_PDMC_20130424T120700_R054_V20091210T235100_20091210T235134.SAFE


def checkProductName
   
   rootname = File.basename(@product)
   
   puts rootname
   
   retVal = true
   
   if rootname.length != 83 then
      puts "ERROR length is not 83 characters #{rootname}"
      retVal = false
   end
   
   if rootname.slice(0,3) != "S2A" and rootname.slice(0,3) != "S2B" then
      puts "ERROR mission identifier not correct / #{slice(0,3)}"
      retVal = false
   end
   
   # ---------------------------------------------
   # Check product type in the filename:
   # - PRD_MSIL0P
   # - PRD_MSIL1A   
   # - PRD_MSIL1B
   # - PRD_MSIL1C
   # - PRD_MSIL1C   

   @product_filetype = rootname.slice(9,10)     
   
   case @product_filetype
      when @FILETYPE_PRODUCT_L0   then @product_level = @PRODUCT_L0
      when @FILETYPE_PRODUCT_L1A  then @product_level = @PRODUCT_L1A
      when @FILETYPE_PRODUCT_L1B  then @product_level = @PRODUCT_L1B
      when @FILETYPE_PRODUCT_L1C  then @product_level = @PRODUCT_L1C
      else  puts "ERROR in product type name #{@product_filetype}"
            @product_level = @PRODUCT_ERR                   
   end
   # ---------------------------------------------
   
   
   # ---------------------------------------------

   # ---------------------------------------------
   # Check Relative Orbit

   if rootname.slice(41,1) != "R" then
      puts "ERROR Relative Orbit marker \'R\' not found in the product name"
   end     

   @rel_orbit = rootname.slice(42,3).to_i
   
   if @rel_orbit < @REL_ORBIT_MIN_VALUE or @rel_orbit > @REL_ORBIT_MAX_VALUE then
      puts "ERROR relative orbit value #{@rel_orbit} is out of range"
   end
     
   # ---------------------------------------------

   @val_start  = self.str2date(rootname.slice(47,15))
   @val_end    = self.str2date(rootname.slice(63,15))

   if @val_start > @val_end then
      puts "ERROR validity start cannot be later than validity end"   
   end

   # ---------------------------------------------
   # Check product type either SAFE either DIMAP

   ext = File.extname(@product)
   
   @bIsSAFE = false
   
   if ext == ".SAFE" then
      puts "SAFE product detected"
      @bIsSAFE = true
   elsif ext == ".DIMAP" then
      puts "DIMAP product detected"
      @bIsSAFE = false
   else
      puts "ERROR in product extension"
      puts "#{@product}"
   end

   # ---------------------------------------------

   return retVal
end

#-------------------------------------------------------------


#-------------------------------------------------------------
#
# Check INSPIRE.xml metadata file
#
# RID to be raised to the [PSD] due to missing xsd schema
# for the INSPIRE.xml

def checkInspire
   retVal = true
   
   if File.exist?("INSPIRE.xml") == false then
      puts "ERROR INSPIRE.xml not found in #{Dir.pwd}"
      return false
   end
   
   cmd = "xmllint INSPIRE.xml"
   if @isDebugMode == true then
      puts cmd
   end
   retVal = system(cmd)
   
   return retVal

end
#-------------------------------------------------------------
#
#

# Check Product Metadata file
#
# RID to be raised to the [PSD] due to missing xsd schema
# for the INSPIRE.xml

def checkProductMetadataFile

   if @isDebugMode == true then
      puts "checkProductMetadataFile"
   end

   retVal = true
      
   case @product_filetype
      when @FILETYPE_PRODUCT_L0  then @filename_metadata = @product_name.gsub(@FILETYPE_PRODUCT_L0, @FILETYPE_METADATA_L0)
      when @FILETYPE_PRODUCT_L1A then @filename_metadata = @product_name.gsub(@FILETYPE_PRODUCT_L1A,@FILETYPE_METADATA_L1A)
      when @FILETYPE_PRODUCT_L1B then @filename_metadata = @product_name.gsub(@FILETYPE_PRODUCT_L1B,@FILETYPE_METADATA_L1B)
      when @FILETYPE_PRODUCT_L1C then @filename_metadata = @product_name.gsub(@FILETYPE_PRODUCT_L1C,@FILETYPE_METADATA_L1C)
   end

   @filename_metadata = @filename_metadata.gsub(".SAFE", ".xml")
   
   if File.exist?(@filename_metadata) == false then
      puts "ERROR #{@filename_metadata} not found in #{Dir.pwd}"
      return false
   end
   
   
   # -----------------------------------
   # check metadata file versus the schema
   
   cmd = "xmllint --nowrap --nowarning --schema #{@SCHEMA_DIR_PRODUCT}#{@SCHEMA_PRODUCT_METADATA_L0} #{@filename_metadata} > /tmp/xml_val_product_metadata"

   if @isDebugMode == true then
      puts cmd
   end
  
   retVal = system(cmd)
   
   if retVal == false then
      puts "\nERROR Failed to validate #{@filename_metadata} with schema\n"
   end
   # -----------------------------------
   
   
   parseEndProductMetadataFile
   
   exit
   
   return retVal

end


#-------------------------------------------------------------

def parseEndProductMetadataFile
   parser = S2ReadProductMetadataFile.new(@filename_metadata, @isDebugMode)
end
#-------------------------------------------------------------

#---------------------------------------------------------------------


#---------------------------------------------------------------------



#-------------------------------------------------------------


#===============================================================================
# Start of the main body
main
# End of the main body
#===============================================================================

