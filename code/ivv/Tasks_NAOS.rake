#!/usr/bin/env ruby

require 'rake'

require 'DEC_Environment'
require_relative 'IVV_Environment_NAOS_MOC'

# https://gist.github.com/ntamvl/7a6658b4cd82d6fbd15434f0a9953411
# https://stackoverflow.com/questions/17811260/rake-tasks-inside-gem-not-being-found
# https://www.rubydoc.info/gems/rake/Rake/Application
# https://stackoverflow.com/questions/6063725/how-to-use-hooks-in-ruby-gems

###############################################################################
## Namespace for NAOS IVV: general tasks
## 

namespace :naos do

    include IVV

    load( File.expand_path( 'NAOS_SYS.rake', IVV.getGemLocation ) )
    load( File.expand_path( 'NAOS_MOC.rake', IVV.getGemLocation ) )
    load( File.expand_path( 'NAOS_FDS.rake', IVV.getGemLocation ) )
    load( File.expand_path( 'NAOS_MCS.rake', IVV.getGemLocation ) )
    load( File.expand_path( 'NAOS_GTA.rake', IVV.getGemLocation ) )
    load( File.expand_path( 'NAOS_DEC.rake', IVV.getGemLocation ) )

    ## --------------------------------------------------------------------

    desc "Information about the NAOS IVV task handler"

    task :about do
        puts "NAOS IVV task management version #{IVV.class_variable_get(:@@version_ivv)} using DEC version #{DEC.class_variable_get(:@@version)}"
    end
    ## --------------------------------------------------------------------

end

###############################################################################

task :default do
    puts "NAOS IVV task management version #{IVV.class_variable_get(:@@version_ivv)} using DEC version #{DEC.class_variable_get(:@@version)}"
end

