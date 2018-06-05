# require 'code/dec/DEC_Environment'

Gem::Specification.new do |s|
  s.name        = 'e2e_sdm'
  s.version     = '1.0.0'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/E2E SDM component"
  s.description = "E2E SDM"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
 
  s.files       = Dir['code/e2e/Analytic*.rb'] + \
                  Dir['code/e2e/CSW*.rb'] + \
                  Dir['code/e2e/E2E*.rb'] + \
                  Dir['code/e2e/FunctionEvents.rb'] + \
                  Dir['code/e2e/QuarcModel.rb'] + \
                  Dir['code/e2e/Read*.rb'] + \
                  Dir['code/e2e/SDM_DatabaseModel.rb'] + \
                  Dir['code/e2e/Write*.rb'] + \
                  Dir['code/e2e/test/S2B_OPER_GIP_TILPAR_MPC__20170206T103032_V20170101T000000_21000101T000000_B00.DBL.xml'] + \
                  Dir['code/e2e/test/S2A_OPER_REP_METARC_PDMC_20180317T233307_V20180317T202933_20180317T202958.xml'] + \
                  Dir['config/profile_dec'] # + \

  s.require_paths = [ 'code', 'code/e2e' ]

  s.bindir        = [ 'code/e2e' ]

  s.executables   = [ 
                     'analytic_E2E', \
                     'e2e_sdm_trace_er', \
                     'e2eUnitTests' #, \
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
    
  # ----------------------------------------------
  
  s.add_dependency('activerecord', '~> 5.1')
  s.add_dependency('geokit', '~> 1.1')
  s.add_dependency('test-unit', '~> 3.2')
  
  # ----------------------------------------------
  
  # database specific gems which can differ
  
  # s.add_dependency('pg', '~> 1.0')
  # s.add_dependency('sqlite3', '~> 1.3')
  
  
  # you did document with RDoc, right?
  # s.has_rdoc = true  
  
    
end
