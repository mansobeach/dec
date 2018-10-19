#!/usr/bin/env ruby
      
require 'dec/DEC_Environment'


conf = DEC_Environment.new
      
conf.wrapper_load_config_development

conf.load_config_developmentRPF

conf.print_environment

conf.print_environmentRPF

require 'ddc/DDC_Notifier2Interface'



# notifier = DDC::DDC_Notifier2Interface.new("AS")
notifier = DDC::DDC_Notifier2Interface.new("LOCALHOST_NOT_SECURE")

notifier.setListFilesSent(["file1.txt", "file2.txt"])
notifier.notifyFilesSent
