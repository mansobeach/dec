#!/usr/bin/env ruby

require 'rake'

require 'SSHClientCommands'

require_relative 'IVV_Environment_NAOS_MOC'
require_relative 'IVV_Logger'

###############################################################################
## Namespace for SYS: general tasks
## 

namespace :sys do

    include CTC::SSHClientCommands
    include IVV

    desc "Host set date #> date -s '2022-07-08T00:00:00' "

    task :set_date, [:date, :host, :environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command( "sudo date -s #{args[:date]}" , user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "#{args[:host].upcase} set host date to #{args[:date]}", "Failed to set #{args[:host].upcase} host date")      
    end

    ## --------------------------------------------------------------------
    # TP-GS-SUP-0240
    desc "Host enable NTP/chrony service"

    task :set_ntp, [:host, :environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command( 'sudo systemctl start chronyd.service', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "#{args[:host].upcase} started systemctl chronyd.service", "#{args[:host].upcase} Failed to start systemctl chronyd.service")
    end

    ## --------------------------------------------------------------------
    # TP-GS-SUP-0240
    desc "Host disable NTP/chrony service"

    task :unset_ntp, [:host, :environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname(args[:host], args[:environment] )
        cmd     = ssh_command( 'sudo systemctl stop chronyd.service', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "#{args[:host].upcase} stopped systemctl chronyd.service", "#{args[:host].upcase} Failed to stop systemctl chronyd.service")        
    end

    ## --------------------------------------------------------------------

    # TP-GS-SUP-0240
    desc "Host status of NTP/chrony service"

    task :status_ntp, [:host, :environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname(args[:host], args[:environment] )
        cmd     = ssh_command( 'sudo systemctl status chronyd.service', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "#{args[:host].upcase} Successful status request of systemctl chronyd.service", "#{args[:host].upcase} systemctl chronyd.service is not enabled")        
    end

    ## --------------------------------------------------------------------

end

