#!/usr/bin/env ruby

#########################################################################
###
### === Ruby source for #IVV_Environment_NAOS class
###
### === Written by DEIMOS Space S.L. (bolf)
###
### === Data Exchange Component (DEC)
### 
### Git: IVV_Environment_NAOS,v $Id$ $Date$
###
### module IVV
###
#########################################################################

require 'rubygems'

require 'cuc/DirUtils'
require 'cuc/Log4rLoggerFactory'

module IVV
   
   include CUC::DirUtils
   
   @@version_ivv = "0.0.0.11"
   
   @@host_ndc = {
                  'aiv'       => 'luuaplivv01.uap.local',
                  'fds'       => 'lundclfds01.lux-naos.local',
                  'gta'       => 'lundclfds01.lux-naos.local',
                  'mcs'       => 'lundclmcs01.lux-naos.local',
                  'mds-uap'   => 'luuaplmds01.uap.local'
               }

   @@port_ndc = {'gta' => 8080}

   ## -----------------------------------------------------------------
   
   @@change_record = { \
      "0.0.0"  =>    "first version of the IVV environment for NAOS GS" \
   }
   ## -----------------------------------------------------------------
   
   def getHostname(host, environment)
      if environment.downcase == 'ndc' then
         return @@host_ndc[host.downcase]
      end
      raise "#{host.downcase} not supported in environment #{environment.downcase}"
   end
   ## -----------------------------------------------------------------

   def getGemLocation
      return File.dirname(File.expand_path(__FILE__))
   end

   ## -----------------------------------------------------------------

end # module

## ==============================================================================



