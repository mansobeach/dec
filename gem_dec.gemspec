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
  s.name        = 'dec'
  s.version     = '1.0.18'
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
                  Dir['config/dec_log_config.xml'] + \
                  Dir['config/dec_config.xml']

   ## --------------------------------------------
   ##
   ## Tailored installer to avoid shipping un-necessary only the OData client
   if ENV.include?("DEC_ODATA") == false then
      s.files = s.files + Dir['config/dec_incoming_files.xml']
      s.files = s.files + Dir['config/dec_outgoing_files.xml']
      s.files = s.files + Dir['config/dec_interfaces.xml']
      s.files = s.files + Dir['config/ft_mail_config.xml']
   end
   ## --------------------------------------------



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
                     'decODataClient', \
                     'decSend2Interface', \
                     'decSmokeTests', \
                     'decStats', \
                     'decUnitTests', \
                     'decUnitTests_ADP', \
                     'decUnitTests_DHUS', \
                     'decUnitTests_FTPS', \
                     'decUnitTests_IERS', \
                     'decUnitTests_ncftpput', \
                     'decUnitTests_PRIP', \
                     'decUnitTests_SBOA', \
                     'decUnitTests_WEBDAV_SECURE', \
                     'decUnitTests_mail' \
                     ]
  
   ## --------------------------------------------
   ##
   ## Tailored installer to include only the OData client
   if ENV.include?("DEC_ODATA") == true then
      s.executables   = [ 'decODataClient' ]
   end
   ## --------------------------------------------

   ## --------------------------------------------
   ##
   ## Tailored installer to include only the OData client
   if ENV.include?("DEC_TEST") == true then

      if ENV.include?("DEC_ODATA") == false then
         s.executables   << 'decUnitTests'
         s.executables   << 'decUnitTests_ADP'
         s.executables   << 'decUnitTests_FTPS'
         s.executables   << 'decUnitTests_IERS'
         s.executables   << 'decUnitTests_ncftpput'
         s.executables   << 'decUnitTests_SBOA'
         s.executables   << 'decUnitTests_WEBDAV_SECURE'
         s.executables   << 'decUnitTests_mail'
      end

      s.executables   << 'decUnitTests_DHUS'
      s.executables   << 'decUnitTests_PRIP'
   end
   ## --------------------------------------------


  s.homepage    = 'http://www.deimos-space.com'
  s.metadata    = { "source_code_uri" => "https://github.com/example/example" }
    
  ## ----------------------------------------------
  
  s.required_ruby_version = '> 2.6.0.preview2'
  
  s.add_dependency('activerecord', '~> 6.0')
  s.add_dependency('dotenv', '~> 2')
  s.add_dependency('filesize', '~> 0.1')
  s.add_dependency('ftools', '~> 0.0')
  s.add_dependency('log4r', '~> 1.0')
  s.add_dependency('net_dav', '~> 0.5')
  s.add_dependency('net-sftp', '~> 2.1')
  s.add_dependency('net-ssh', '~> 6.1')
  s.add_dependency('nokogiri', '~> 1.1')
  s.add_dependency('shell', '~> 0.8')
  
  ## --------------------------------------------
  ##
  ## Tailored installer to avoid some gems only for the OData client
  if ENV.include?("DEC_ODATA") == false then
     s.add_dependency('curb', '~> 0.9')
  end
  ## --------------------------------------------

  ## --------------------------------------------
  ##
  ## Tailored installer to include Postgresql
  if ENV.include?("DEC_PG") == true then
     s.add_dependency('pg', '~> 1')
  end
  ## --------------------------------------------

  s.add_dependency('sqlite3', '~> 1.4')
  s.add_dependency('sys-filesystem', '~> 1.3')
  
  ## ----------------------------------------------
 
  s.add_development_dependency('coderay', '~> 1.1')
  s.add_development_dependency('rspec', '~> 3.9') 
  s.add_development_dependency('sqlite3', '~> 1.4')
  s.add_development_dependency('test-unit', '~> 3.0')
 
  
  ## ----------------------------------------------

  s.post_install_message = "#{'1F4E1'.hex.chr('UTF-8')} ESA / Deimos-Space #{'1F47E'.hex.chr('UTF-8')} Data Exchange Component installed \360\237\215\200 \360\237\215\200 \360\237\215\200"
    
  ## ----------------------------------------------
     
end

### ============================================================================
