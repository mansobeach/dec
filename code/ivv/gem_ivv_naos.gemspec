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
### System Component IVV
###
#########################################################################

require_relative 'IVV_Environment_NAOS_MOC'

Gem::Specification.new do |s|
  s.name        = 'ivv_naos_moc'
  s.version     = "#{IVV.class_variable_get(:@@version_ivv)}"
  s.platform    = Gem::Platform::RUBY
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/IVV component"
  s.description = "Data Exchange Component"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
 
  s.files       = Dir['*.rake'] + \
                  Dir['IVV_Environment_NAOS_MOC.rb'] + \
                  Dir['IVV_Logger.rb'] + \
                  Dir['rakefile'] + \
                  Dir['ivv_update_rakefile'] + \
                  Dir['Tasks_NAOS.rake']


  ## --------------------------------------------
  
  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://confluence.elecnor-deimos.com/display/DEC" }
  
  s.bindir        = [ '.' ]

  s.executables   = [
    'ivv_update_rakefile'
  ]

  ## ----------------------------------------------
  s.required_ruby_version = '> 3.0'  
  ## ----------------------------------------------
  
  ## --------------------------------------------
  s.add_dependency('dec', '~> 1.0.39')
  ## ----------------------------------------------
 
  ## ----------------------------------------------
  s.post_install_message = "#{'1F4E1'.hex.chr('UTF-8')} Elecnor Deimos #{'1F47E'.hex.chr('UTF-8')} IVV Tasks for NAOS mission installed #{IVV.class_variable_get(:@@version_ivv)} \360\237\215\200 \360\237\215\200 \360\237\215\200"
  ## ----------------------------------------------
     
end

### ============================================================================
