Gem::Specification.new do |s|
  s.name        = 'aux'
  s.version     = '0.0.0'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/AUX component"
  s.description = "Auxiliary Data Gathering"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  
  s.required_ruby_version = '>= 2.5'
  
  s.files       = Dir['code/aux/*.rb'] + \
                  Dir['install/orc_test.bash']


  s.require_paths = ['code', 'code/aux']

  s.bindir        = ['code/aux']


  s.executables   = [ 
#                     'auxUnitTests', \
                     'auxUnitTests'
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
  

  ## ----------------------------------------------
  
  ## ----------------------------------------------  
  
    
  s.post_install_message = "Elecnor Deimos Auxiliary Data Management installed :-)"
  
end
