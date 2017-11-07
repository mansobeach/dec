#!/usr/bin/ruby

#########################################################################
#
# driver_E2E_WriteXFBD
#
# Written by Borja Lopez Fernandez
#
#
#########################################################################

require 'cuc/Converters'
require 'e2e/WriteXFBD'
require 'e2e/QuarcModel'
require 'e2e/ReadInputRepMetDel'

signature      = "DIM_satan"
filename       = "kaka.EOF"
date_gen       = Time.now.strftime(CUC::Converters::QuarcDateFormat)
start          = Time.now.strftime(CUC::Converters::QuarcDateFormat)
stop           = Time.now.strftime(CUC::Converters::QuarcDateFormat)


parser = E2E::ReadInputRepMetDel.new(
                                       "../e2e/xml/S2B_OPER_REP_METDEL_PDMC_20171030T115000_V20171030T114712_20171030T114712.xml",
                                       false
                                       )


arrItems = parser.getItems


writer = E2E::WriteXFBD.new(
                              "../e2e/xml/S2B_OPER_REP_METDEL_PDMC_20171030T115000_V20171030T114712_20171030T114712.xfbd", 
                              false
                              )

writer.writeHeader(
                     signature,
                     filename,
                     date_gen,
                     start,
                     stop
                     )

writer.createBody()


explicit_ref      = "S2B_OPER_MSI_L1A_DS_MTI__20171023T084707_S20171023T050507_N02.06"
annotation_name   = "DAM-REMOVAL"
annotation_type   = "STRING"
annotation_value  = "S2B_OPER_REP_METDEL_PDMC_20171030T115000_V20171030T114712_20171030T114712"

arrItems.each{|item|
   if item.include?("MSI_L1A_DS") == true then
      annotation        = Struct::Annotation.new(item, annotation_name, annotation_type, annotation_value)
      writer.ingestAnnotation(annotation)
   end
}

writer.write()

