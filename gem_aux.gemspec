require_relative 'code/cuc/DirUtils'
require_relative 'code/aux/AUX_Environment'
include AUX

Gem::Specification.new do |s|
  s.name        = 'aux'
  s.version     = "#{AUX::VERSION}"
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/AUX component"
  s.description = "Auxiliary Data Gathering"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  
  s.required_ruby_version = '>= 2.5'
  
  s.files       = Dir['code/aux/*.rb'] + \
                  Dir['code/cuc/DirUtils.rb'] + \
                  Dir['code/cuc/Converters.rb'] + \
                  Dir['code/cuc/CryptHelper.rb'] + \
                  Dir['code/cuc/FT_PackageUtils.rb'] + \
                  Dir['code/cuc/Log4rLoggerFactory.rb'] + \
#                  Dir['code/dec/DEC_Environment.rb'] + \
                  Dir['code/dec/ReadConfigDEC.rb'] + \
                  Dir['config/dec_config.xml'] + \
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
  s.add_dependency('filesize', '~> 0.1')
  s.add_dependency('roman-numerals', '~> 0.3')

  ## ----------------------------------------------
  
  ## ----------------------------------------------  
  
  s.post_install_message = "Elecnor Deimos-Space #{'1F47E'.hex.chr('UTF-8')} Auxiliary Data Management installed #{AUX::VERSION} \360\237\215\200 \360\237\215\200 \360\237\215\200"
  
end
