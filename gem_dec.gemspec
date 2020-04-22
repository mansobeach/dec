#########################################################################
#
# === Ruby source for #Gem Specification
#
# === Written by DEIMOS Space S.L. (bolf)
#
# === Data Exchange Component (DEC)
# 
# Git: gem_dec.gemspec,v $Id$ $Date$
#
# System Component DEC
#
#########################################################################

Gem::Specification.new do |s|
  s.name        = 'dec'
  s.version     = '1.0.14'
  s.licenses    = ['Nonstandard']
  s.summary     = "DEC/MINARC component"
  s.description = "Data Exchange Component"
  s.authors     = ["Elecnor Deimos"]
  s.email       = 'borja.lopez@deimos-space.com'
 
  s.files       = Dir['code/ddc/*.rb'] + \
                  Dir['code/dcc/*.rb'] + \
                  Dir['code/cuc/*.rb'] + \
                  Dir['code/dbm/*.rb'] + \
                  Dir['code/ctc/*.rb'] + \
                  Dir['code/dec/*.rb'] + \
                  Dir['schemas/*.xsd'] + \
                  Dir['config/dec_interfaces.xml'] + \
                  Dir['config/dec_outgoing_files.xml'] + \
                  Dir['config/ft_mail_config.xml'] + \
                  Dir['config/dec_log_config.xml'] + \
                  Dir['config/dec_config.xml'] + \
                  Dir['config/dec_incoming_files.xml'] + \
                  Dir['config/oper/*.xml'] + \
                  Dir['config/profile_dec'] # + \

  s.require_paths = [ 'code', 'code/dcc', 'code/ddc', 'code/ctc', 'code/dec' ]

  s.bindir        = [ 'code/dec' ]

  s.executables   = [ 
                     'decValidateConfig', \
                     'decCheckConfig', \
                     'decListDirUpload', \
                     'decConfigInterface2DB', \
                     'decDeliverFiles', \
                     'decGetFiles4Transfer', \
                     'decGetFromInterface', \
                     'decListener', \
                     'decManageDB', \
                     'decNotify2Interface', \
                     'decSend2Interface', \
                     'decSmokeTests', \
                     'decStats', \
                     'decUnitTests', \
                     'decUnitTests_ADP', \
                     'decUnitTests_IERS', \
                     'decUnitTests_ncftpput', \
                     'decUnitTests_WEBDAV_SECURE', \
                     'decUnitTests_mail' \
                     ]

  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
    
  ## ----------------------------------------------
  
  s.required_ruby_version = '> 2.6.0.preview2'
  
  s.add_dependency('activerecord', '~> 6.0')
  s.add_dependency('curb', '~> 0.9')
  s.add_dependency('dotenv', '~> 2')
  s.add_dependency('filesize', '~> 0.1')
  s.add_dependency('ftools', '~> 0.0')
  s.add_dependency('ftpfxp', '~> 0.0')
  s.add_dependency('log4r', '~> 1.0')
  s.add_dependency('net_dav', '~> 0.5')
  s.add_dependency('net-sftp', '~> 2.1')
  s.add_dependency('net-ssh', '~> 4.2')
  s.add_dependency('pg', '~> 1')
  s.add_dependency('sqlite3', '~> 1.4')
  s.add_dependency('sys-filesystem', '~> 1.3')
  
  ## ----------------------------------------------
  
  s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('test-unit', '~> 3.0')
  
  ## ----------------------------------------------

  s.post_install_message = "#{'1F4E1'.hex.chr('UTF-8')} ESA / Deimos-Space #{'1F47E'.hex.chr('UTF-8')} Data Exchange Component installed \360\237\215\200 \360\237\215\200 \360\237\215\200"
    
  ## ----------------------------------------------
     
end

### ============================================================================
