Gem::Specification.new do |s|
  s.name        = 'minarc'
  s.version     = '1.0.16'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/MINARC component"
  s.description = "Minimum Archive"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
  
  s.required_ruby_version = '>= 2.2'
  
  s.files       = Dir['code/arc/File*.rb'] + \
                  Dir['code/arc/Inventory2Excel*.rb'] + \
                  Dir['code/arc/MINARC_*.rb'] + \
                  Dir['code/arc/ReadMinarcConfig.rb'] + \
                  Dir['code/arc/ReportEditor.rb'] + \
                  Dir['code/arc/plugins/*.rb'] + \
                  Dir['code/arc/plugins/test/S2A_OPER_REP_OPDPC__SGS__21000101T000000_V21000101T000000_21000101T000001.EOF'] + \
                  Dir['code/arc/plugins/test/example_1.m2ts'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['code/ctc/WrapperCURL.rb'] + \
                  Dir['config/profile_minarc_sqlite3'] + \
                  Dir['config/profile_gem_minarc_sqlite3'] # + \


  s.require_paths = ['code', 'code/arc']

  s.bindir        = ['code/arc']

  # s.datadir     #  = ['code/arc/plugins/test']

  s.executables   = [ 
                     'minArcStore', \
                     'minArcDB', \
                     'minArcDelete', \
                     'minArcPurge', \
                     'minArcRetrieve', \
                     'minArcServer', \
                     'minArcStatus', \
                     'minArcUnitTests', \
                     'minArcSmokeTestLocal', \
                     'minArcSmokeTestRemote'
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
  

  
  # ----------------------------------------------
  
  s.add_dependency('activerecord', '~> 5.1')
  s.add_dependency('filesize', '~> 0.1')
  s.add_dependency('ftools', '~> 0.0')
  s.add_dependency('json', '~> 2.0')
  s.add_dependency('log4r', '~> 1.0')
  s.add_dependency('sinatra', '~> 2.0')
  s.add_dependency('test-unit', '~> 3.2')
  s.add_dependency('thin', '~> 1.7')
  s.add_dependency('writeexcel', '~> 1.0')
  
  # ----------------------------------------------
  
  # database specific gems which can differ
  
  # s.add_dependency('pg', '~> 1.0')
  s.add_dependency('sqlite3', '~> 1.3')
  
  
  # you did document with RDoc, right?
  # s.has_rdoc = true  
  
  s.post_install_message = "Elecnor Deimos MINARC installed :-)"
  
end
