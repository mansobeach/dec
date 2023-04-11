#!/usr/bin/env ruby

require 'rake'

require_relative 'IVV_Environment_NAOS_MOC'
require_relative 'IVV_Logger'

# https://gist.github.com/ntamvl/7a6658b4cd82d6fbd15434f0a9953411
# https://stackoverflow.com/questions/17811260/rake-tasks-inside-gem-not-being-found
# https://www.rubydoc.info/gems/rake/Rake/Application
# https://stackoverflow.com/questions/6063725/how-to-use-hooks-in-ruby-gems


###############################################################################
## Namespace for MOC: grouped tasks
## 

namespace :moc do

    include IVV

    ## --------------------------------------------------------------------

    desc "MOC hosts set date #> date -s '2022-07-08T00:00:00' "

    task :set_date, [:date, :environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        @logger.info("Setting MOC hosts to date #{args[:date]}")
        
        @logger.info("Setting AIV to date #{args[:date]}")
        Rake::Task['naos:sys:set_date'].invoke(args[:date], 'aiv', args[:environment] )
        Rake::Task['naos:sys:set_date'].reenable

        @logger.info("Setting FDS to date #{args[:date]}")
        Rake::Task['naos:sys:set_date'].invoke(args[:date], 'fds', args[:environment] )
        Rake::Task['naos:sys:set_date'].reenable

        @logger.info("Setting MCS to date #{args[:date]}")
        Rake::Task['naos:sys:set_date'].invoke( args[:date], 'mcs', args[:environment] )
        Rake::Task['naos:sys:set_date'].reenable
    end
    ## --------------------------------------------------------------------

    ## --------------------------------------------------------------------

    # TP-GS-SUP-0240
    desc "MOC hosts status of NTP/chrony service"

    task :status_ntp, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        @logger.info("Checking MOC hosts NTP/chrony services")

        @logger.info("Checking FDS NTP/chrony service")
        Rake::Task['sys:status_ntp'].invoke( 'fds', args[:environment] )
        Rake::Task['sys:status_ntp'].reenable

        @logger.info("Checking MCS NTP/chrony service")
        Rake::Task['sys:status_ntp'].invoke( 'mcs', args[:environment] )
        Rake::Task['sys:status_ntp'].reenable        
    end

    ## --------------------------------------------------------------------

    # TP-GS-SUP-0240
    desc "MOC hosts activate NTP/chrony service"

    task :set_ntp, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        @logger.info("MOC hosts activate NTP/chrony services")
  
        @logger.info("Activating FDS NTP/chrony service")
        Rake::Task['sys:set_ntp'].invoke( 'fds', args[:environment] )
        Rake::Task['sys:set_ntp'].reenable
  
        @logger.info("Activating MCS NTP/chrony service")
        Rake::Task['sys:set_ntp'].invoke( 'mcs', args[:environment] )
        Rake::Task['sys:set_ntp'].reenable
    end
  
    ## --------------------------------------------------------------------

    # TP-GS-SUP-0240
    desc "MOC hosts deactivate NTP/chrony service"

    task :unset_ntp, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        @logger.info("MOC hosts deactivate NTP/chrony services")

        @logger.info("Deactivating FDS NTP/chrony service")
        Rake::Task['sys:unset_ntp'].invoke( 'fds', args[:environment] )
        Rake::Task['sys:unset_ntp'].reenable

        @logger.info("Deactivating MCS NTP/chrony service")
        Rake::Task['sys:unset_ntp'].invoke( 'mcs', args[:environment] )
        Rake::Task['sys:unset_ntp'].reenable        
    end

    ## --------------------------------------------------------------------

end

###############################################################################


