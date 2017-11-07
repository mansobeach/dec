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
require 'e2e/SDM_DatabaseModel'

arrDim = DimSignatureTB.all

puts "-------------------------------------------"
puts "dim_signature_tb"


arrDim.each{|dim|
	puts "--------------------------------------"
	puts "DIM Signature : #{dim.dim_signature}"
	puts "DIM Exec Name : #{dim.dim_exec_name}"
	puts "Active Flag   : #{dim.active_flag}"
	puts "--------------------------------------"

}

puts
puts

arrErCnf = ExplicitReferenceConfTB.all

puts "-------------------------------------------"
puts "explicit_ref_cnf_tb"


arrErCnf.each{|anErCnf|
	puts "--------------------------------------"
	puts "ER Config ID  : #{anErCnf.expl_ref_cnf_id}"
	puts "ER Name       : #{anErCnf.name}"
	puts "DIM Signature : #{anErCnf.dim_signature}"
	puts "--------------------------------------"
}

puts
puts


puts "-------------------------------------------"
puts "annot_group_cnf_tb"

arrGroupAnnotationsCnf = AnnotGroupConfTB.all
puts arrGroupAnnotationsCnf.length

puts "-------------------------------------------"


puts "-------------------------------------------"
puts "annot_group_cnf_tb"

annotConfTB = AnnotConfTB.all
puts annotConfTB.length
   
annotConfTB.each{|cnfAnnotation|
   puts "---------------------"
   puts "Annotation ID   : #{cnfAnnotation.annotation_id}"
   puts "Annotation Name : #{cnfAnnotation.name}"
   puts "DIM Signature   : #{cnfAnnotation.dim_signature}"
   puts "ER Conf ID      : #{cnfAnnotation.expl_ref_cnf_id}"
   puts "Group ID        : #{cnfAnnotation.group_id}"
   puts "---------------------"
}


puts "-------------------------------------------"


