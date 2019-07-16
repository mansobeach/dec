Gem::Specification.new do |s|
  s.name        = 'orc'
  s.version     = '0.0.4'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/ORC component"
  s.description = "Generic Orchestrator"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  
  s.required_ruby_version = '>= 2.2'
  
  s.files       = Dir['code/orc/*.rb'] + \
                  Dir['code/orc/orcIngester'] + \
                  Dir['code/orc/orcUnitTests'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['config/orchestratorConfigFile.xml'] + \
                  Dir['config/orchestrator_log_config.xml'] + \
                  Dir['install/orc_test.env'] + \
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
                     'orcUnitTests'
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
  

  # ----------------------------------------------
  
  s.add_dependency('minarc', '>= 1.0.30a')
  #s.add_runtime_dependency('minarc', '>= 1.0.30')
  # ----------------------------------------------
    
  
  # you did document with RDoc, right?
  # s.has_rdoc = true  
  
  s.post_install_message = "Elecnor Deimos Generic Orchestrator installed :-)"
  
end
