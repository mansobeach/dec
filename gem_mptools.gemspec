#########################################################################
###
### === Ruby source for #Gem Specification
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === MPL module
### 
### Git: gem_dec.gemspec,v $Id$ $Date$
###
### System Component MPL
###
#########################################################################

Gem::Specification.new do |s|
  s.name        = 'mptools'
  s.version     = '0.0.2'
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ['Nonstandard']
  s.summary     = "MPTools component"
  s.description = "Data Exchange Component"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
 
  ## --------------------------------------------
  ##
  ## platform
  if ENV.include?("MPTOOLS_PLATFORM") == false then
     ENV['MPTOOLS_PLATFORM'] = "MACIN64"
  end
  ## --------------------------------------------
 
  s.files       = Dir['config/mptools_log_config.xml'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['code/mpl/data/*'] + \
                  Dir['code/mpl/*.c'] + \
                  Dir['code/mpl/include/*.h'] + \
                  Dir["code/mpl/lib/#{ENV['MPTOOLS_PLATFORM']}/*.a"] + \
#                  Dir['code/mpl/libearth_explorer_cfi.so'] + \
                  Dir['code/mpl/MPL_Environment.rb'] + \
                  Dir['code/mpl/MPL_Loader_Wrapper_Earth_Explorer.rb'] + \
                  Dir['code/mpl/mp_xvstation_vistime_compute'] + \
                  Dir['code/mpl/test_mptools'] + \
                  Dir['code/mpl/test_wrapper_earth_explorer_cfi'] + \
#                  Dir['code/mpl/ruby_earth_explorer_cfi.bundle'] + \
                  Dir['code/mpl/explorer_orbit/data/*']

  s.extensions  = %w[code/mpl/extconf_earth_explorer_cfi.rb]

  s.require_paths = [ 'code', 'code/mpl' ]

  s.bindir        = [ 'code/mpl' ]

  s.executables   = [ \
                     'test_mptools', \
                     'mp_xvstation_vistime_compute', \
                     'test_wrapper_earth_explorer_cfi' \
                     ]
  
  ## --------------------------------------------

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
    
  ## ----------------------------------------------
  
  s.required_ruby_version = '>= 2.7.0'
  
  ## ----------------------------------------------
  
  s.add_dependency('shell', '~> 0.8')
  
  s.add_development_dependency('rake-compiler', '~> 1') 
  s.add_development_dependency('coderay', '~> 1.1')
  s.add_development_dependency('rspec', '~> 3.9') 
  s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('test-unit', '~> 3.0')
   
  ## ----------------------------------------------

  s.post_install_message = "#{'1F4E1'.hex.chr('UTF-8')} Elecnor Deimos-Space #{'1F47E'.hex.chr('UTF-8')} mptools installed \360\237\215\200 \360\237\215\200 \360\237\215\200"
    
  ## ----------------------------------------------
     
end

### ============================================================================
