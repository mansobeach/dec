Gem::Specification.new do |s|
  s.name        = 'minarc_client'
  s.version     = '0.0.1'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/MINARC component"
  s.description = "Minimum Archive"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  s.files       = Dir['code/arc/*.rb'] + \
                  Dir['code/arc/plugins/*.rb'] + \
                  Dir['code/arc/plugins/test/*'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['code/ctc/WrapperCURL.rb'] + \
                  Dir['config/profile_minarc_sqlite3'] + \
                  Dir['config/profile_gem_minarc_sqlite3'] # + \


  s.require_paths = ['code', 'code/arc']

  s.bindir        = ['code/arc']

  # s.datadir     #  = ['code/arc/plugins/test']

  s.executables   = [ 
                     'minArcStore', \
                     'minArcDelete', \
                     'minArcRetrieve', \
                     'minArcSmokeTestRemote'
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
  

  
  # ----------------------------------------------
  
  s.add_dependency('test-unit', '~> 3.2')
  
  # ----------------------------------------------
    
  
  # you did document with RDoc, right?
  # s.has_rdoc = true  
  
  
  
end
