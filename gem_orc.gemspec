Gem::Specification.new do |s|
  s.name        = 'orc'
  s.version     = '0.0.12'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/ORC component"
  s.description = "Generic Orchestrator"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  
  s.required_ruby_version = '>= 2.5'
  
  s.files       = Dir['code/orc/*.rb'] + \
                  Dir['code/orc/orcIngester'] + \
                  Dir['code/orc/orcUnitTests'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['schemas/common_types.xsd'] + \
                  Dir['schemas/orchestrator_log_config.xsd'] + \
                  Dir['schemas/orchestratorConfigFile.xsd'] + \
                  Dir['config/orchestratorConfigFile.xml'] + \
                  Dir['config/orchestrator_log_config.xml'] + \
                  Dir['config/orc_test.env'] + \
                  Dir['config/orc_test_postgresql.env'] + \
                  Dir['install/orc_test.bash']


  s.require_paths = ['code', 'code/orc']

  s.bindir        = ['code/orc']


  s.executables   = [ 
                     'orcBolg', \
                     'orcIngester', \
                     'orc_eboa_triggering', \
                     'orcManageDB', \
                     'orcQueueInput', \
                     'orcQueueUpdate', \
                     'orcResourceChecker', \
                     'orcScheduler', \
                     'orcUnitTests', \
                     'orcValidateConfig'
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
  

  ## ----------------------------------------------
  
  ### PENDING COMPLETION OF MINARC 1.1.0
  ### s.add_dependency('minarc', '> 1.0.34')

  s.add_dependency('activerecord-import', '~> 1.0')
  s.add_dependency('log4r', '~> 1.0')  
  s.add_dependency('pg', '~> 1')
  ## ----------------------------------------------
  
  s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('test-unit', '~> 3.0')
  
  ## ----------------------------------------------  
    
  s.post_install_message = "#{'1F4E1'.hex.chr('UTF-8')} ESA / Deimos-Space #{'1F47E'.hex.chr('UTF-8')} Elecnor Deimos Generic Orchestrator installed \360\237\215\200 \360\237\215\200 \360\237\215\200"
  
end
