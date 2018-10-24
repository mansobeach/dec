# require 'code/dec/DEC_Environment'

Gem::Specification.new do |s|
  s.name        = 'dec_rpf'
  s.version     = '1.0.4'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/RPF component"
  s.description = "Data Exchange Component for Reference Planning"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
 
  s.files       = Dir['code/ddc/*.rb'] + \
                  Dir['code/dcc/*.rb'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['code/dbm/*.rb'] + \
                  Dir['code/ctc/*.rb'] + \
                  Dir['code/dec/*.rb'] + \
                  Dir['code/dec/*']    + \
                  Dir['code/rpf/*.rb'] + \
                  Dir['code/dec/*.bin'] + \
                  Dir['schemas/*.xsd'] + \
                  Dir['config/interfaces.xml'] + \
                  Dir['config/ft_incoming_files.xml'] + \
                  Dir['config/ft_outgoing_files.xml'] + \
                  Dir['config/ft_mail_config.xml'] + \
                  Dir['config/dec_log_config.xml'] + \
                  Dir['config/dcc_config.xml'] + \
                  Dir['config/ddc_config.xml'] + \
                  Dir['config/files2InTrays.xml'] + \
                  Dir['config/oper/*.xml'] + \
                  Dir['config/profile_dec'] # + \

  s.require_paths = [ 'code', 'code/dcc', 'code/ddc', 'code/ctc', 'code/dec', 'code/rpf' ]

  s.bindir        = [ 'code/dec' ]

  s.executables   = [ \
                     'put_report.bin', \
                     'sendROP.rb', \
                     'removeSchema.bin', \
                     'write2Log.bin', \
                     'sendROPFiles.rb', \
                     'setROPStatus.rb', \
                     'getRPFFilesToBeTransferred.rb', \
                     'moveFilesToRejectDirectory.rb', \
                     'notify2Interface.rb', \
                     'decUnitTests_RPF', \
                     'decValidateConfig', \
                     'decConfigInterface2DB', \
                     'decDeliverFiles', \
                     'decGetFromInterface', \
                     'decListener', \
                     'decManageDB', \
                     'decSend2Interface', \
                     'decSmokeTests', \
                     'decStats', \
                     'decUnitTests', \
                     'decUnitTests_ncftpput', \
                     'driver_MailSender.rb', \
                     'decUnitTests_mail' \
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
    
  # ----------------------------------------------
  
#
#  s.add_dependency('activerecord', '~> 5.1')
#  s.add_dependency('filesize', '~> 0.1')
#  s.add_dependency('ftools', '~> 0.0')
#  s.add_dependency('log4r', '~> 1.0')
#  s.add_dependency('net-sftp', '~> 2.1')
#  s.add_dependency('net-ssh', '~> 4.2')
#  s.add_dependency('test-unit', '~> 3.0')
#
  
  # ----------------------------------------------
  
  # database specific gems which can differ
  
  # s.add_dependency('pg', '~> 1.0')
  # s.add_dependency('sqlite3', '~> 1.3')
  
  
  # you did document with RDoc, right?
  # s.has_rdoc = true  
  
    
end
