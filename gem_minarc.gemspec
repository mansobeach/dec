#########################################################################
###
### === Ruby source for #Gem Specification
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (DEC)
### 
### Git: gem_dec.gemspec,v $Id$ $Date$
###
### System Component DEC
###
#########################################################################

Gem::Specification.new do |s|
  s.name        = 'minarc'
  s.version     = '1.1.0'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/MINARC component"
  s.description = "Minimum Archive"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  
  s.required_ruby_version = '>= 2.5'
  
  s.files       = Dir['code/arc/File*.rb'] + \
                  Dir['code/arc/Inventory2Excel*.rb'] + \
                  Dir['code/arc/MINARC_*.rb'] + \
                  Dir['code/arc/ReadMinarcConfig.rb'] + \
                  Dir['code/arc/ReportEditor.rb'] + \
                  Dir['code/arc/plugins/*.rb'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['code/ctc/WrapperCURL.rb'] + \
                  Dir['config/minarc_config.xml'] + \
                  Dir['config/minarc_log_config.xml'] + \
                  Dir['install/minarc_test.env'] + \
                  Dir['install/minarc_test.bash']


  ## --------------------------------------------
  ## Tailored installer to include Postgresql
  if ENV.include?("MINARC_TEST") == true then
     s.files = s.files + Dir['code/arc/plugins/test/S2A_OPER_REP_OPDPC__SGS__21000101T000000_V21000101T000000_21000101T000001.EOF']
     s.files = s.files + Dir['code/arc/plugins/test/example_1.m2ts']
     s.files = s.files + Dir['code/arc/plugins/test/example_1.mp4']
  end
  ## --------------------------------------------

  s.require_paths = ['code', 'code/arc']

  s.bindir        = ['code/arc']

  # s.datadir       = ['code/arc/plugins/test']

  s.executables   = [ 
                     'minArcStore', \
                     'minArcDB', \
                     'minArcFile', \
                     'minArcDelete', \
                     'minArcPurge', \
                     'minArcReallocate', \
                     'minArcRetrieve', \
                     'minArcServer', \
                     'minArcStatus'
                      ]


  ## --------------------------------------------
  ##
  ## Include test executables
  if ENV.include?("MINARC_TEST") == true then
     s.executables   << 'minArcUnitTests'
     s.executables   << 'minArcSmokeTestLocal'
     s.executables   << 'minArcSmokeTestRemote'
     s.executables   << 'minArcTestHandler_VIDEO'
  end
  ## --------------------------------------------

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://bitbucket.org/borja_lopez_fernandez/dec.git" }
  
  ## ----------------------------------------------
  
  s.add_dependency('activerecord', '~> 6.0')
  s.add_dependency('activerecord-import', '~> 1.0')
  s.add_dependency('bcrypt', '~> 3.1')
  s.add_dependency('dotenv', '~> 2.7')
  s.add_dependency('exiftool', '~> 1.2')
  s.add_dependency('filesize', '~> 0.1')
  s.add_dependency('ftools', '~> 0.0')
  s.add_dependency('json', '~> 2.0')
  s.add_dependency('log4r', '~> 1.0')
  s.add_dependency('mini_exiftool', '~> 2.0')
  s.add_dependency('sinatra', '~> 2.0')
  s.add_dependency('sinatra-reloader', '~> 1.0')
  s.add_dependency('thin', '~> 1.7')
  s.add_dependency('writeexcel', '~> 1.0')
  
  ## --------------------------------------------
  ##
  ## Tailored installer to include Postgresql
  if ENV.include?("MINARC_PG") == true then
     s.add_dependency('pg', '~> 1')
  end
  ## --------------------------------------------

  ## --------------------------------------------
  ##
  ## Tailored installer to include sqlite3
  if ENV.include?("MINARC_SQLITE3") == true then
     s.add_dependency('sqlite3', '~> 1.4')
  end
  ## --------------------------------------------

  
  ## ----------------------------------------------
  
  # s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('test-unit', '~> 3.0')

  ## ----------------------------------------------
  
  ## ----------------------------------------------

  s.post_install_message = "#{'1F4E1'.hex.chr('UTF-8')} ESA / Deimos-Space #{'1F47E'.hex.chr('UTF-8')} minARC installed \360\237\215\200 \360\237\215\200 \360\237\215\200"
    
  ## ----------------------------------------------
  
end
