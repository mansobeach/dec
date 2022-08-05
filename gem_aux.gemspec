require_relative 'code/aux/AUX_Environment'
include AUX

Gem::Specification.new do |s|
  s.name        = 'aux'
  s.version     = "#{AUX.class_variable_get(:@@version)}"
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/AUX component"
  s.description = "Auxiliary Data Gathering"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  
  s.required_ruby_version = '>= 2.5'
  
  s.files       = Dir['code/aux/*.rb'] + \
                  Dir['code/cuc/DirUtils.rb'] + \
                  Dir['code/cuc/Converters.rb'] + \
                  Dir['config/dec_log_config.xml']

  s.require_paths = ['code', 'code/aux']

  s.bindir        = ['code/aux']


  s.executables   = [ 
                     'auxConverter', \
                     'auxUnitTests'
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
  
  # s.add_dependency('dec', '> 1.0.30')

  ## ----------------------------------------------
  
  ## ----------------------------------------------  
  
  s.post_install_message = "Elecnor Deimos Auxiliary Data Management installed :-)"
  
end
