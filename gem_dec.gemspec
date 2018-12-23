# require 'code/dec/DEC_Environment'

Gem::Specification.new do |s|
  s.name        = 'dec'
  s.version     = '1.0.8'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/MINARC component"
  s.description = "Data Exchange Component"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
 
  s.files       = Dir['code/ddc/*.rb'] + \
                  Dir['code/dcc/*.rb'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['code/dbm/*.rb'] + \
                  Dir['code/ctc/*.rb'] + \
                  Dir['code/dec/*.rb'] + \
                  Dir['schemas/*.xsd'] + \
                  Dir['config/interfaces.xml'] + \
                  Dir['config/ft_incoming_files.xml'] + \
                  Dir['config/ft_outgoing_files.xml'] + \
                  Dir['config/dec_log_config.xml'] + \
                  Dir['config/dcc_config.xml'] + \
                  Dir['config/ddc_config.xml'] + \
                  Dir['config/files2InTrays.xml'] + \
                  Dir['config/oper/*.xml'] + \
                  Dir['config/profile_dec'] # + \

  s.require_paths = [ 'code', 'code/dcc', 'code/ddc', 'code/ctc', 'code/dec' ]

  s.bindir        = [ 'code/dec' ]

  s.executables   = [ 
                     'decValidateConfig', \
                     'decCheckConfig', \
                     'decConfigInterface2DB', \
                     'decGetFromInterface', \
                     'decListener', \
                     'decManageDB', \
                     'decSend2Interface', \
                     'decSmokeTests', \
                     'decStats', \
                     'decUnitTests', \
                     'decUnitTests_ncftpput', \
                     'decUnitTests_mail' \
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
    
  # ----------------------------------------------
  
  s.add_dependency('activerecord', '~> 5.1')
  s.add_dependency('filesize', '~> 0.1')
  s.add_dependency('ftools', '~> 0.0')
  s.add_dependency('log4r', '~> 1.0')
  s.add_dependency('net-sftp', '~> 2.1')
  s.add_dependency('net-ssh', '~> 4.2')
  s.add_dependency('test-unit', '~> 3.0')
  
  # ----------------------------------------------
  
  # database specific gems which can differ
  
  # s.add_dependency('pg', '~> 1.0')
  # s.add_dependency('sqlite3', '~> 1.3')
  
  
  # you did document with RDoc, right?
  # s.has_rdoc = true  
  
    
end
