#!/usr/bin/env ruby

require 'rake'

require 'SSHClientCommands'

require_relative 'IVV_Environment_NAOS_MOC'
require_relative 'IVV_Logger'


###############################################################################
## Namespace for MCS

namespace :mcs do

    include CTC::SSHClientCommands
    include IVV

    ## --------------------------------------------------------------------

    desc "MCS shutdown"

    task :shutdown, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'root'
        host    = getHostname('mcs', args[:environment] )
        cmd     = ssh_command('systemctl stop SESS', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS SESS service stopped", "Failed to stop MCS SESS service")
    end
    ## --------------------------------------------------------------------

    desc "MCS start"

    task :start, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'root'
        host    = getHostname('mcs', args[:environment] )
        cmd     = ssh_command('systemctl restart SESS', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS SESS service start", "Failed to start MCS SESS service")
    end
    ## --------------------------------------------------------------------

    desc "MCS status"

    task :status, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'root'
        host    = getHostname('mcs', args[:environment] )
        cmd     = ssh_command('systemctl --no-pager status SESS', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "request of status for service MCS SESS is successful", "failed to request status service MCS SESS")
    end

    ## --------------------------------------------------------------------

    desc "MCS file-system clean-up"

    task :cleanup, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'ccsexec'
        host    = getHostname('mcs', args[:environment] )

        cmd     = ssh_command('rm -f /CCS/VARIABLE/INPUTS/TMP/*', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS deleted MTL temp directory", "MCS Failed to delete MTL temp directory")
      
        cmd     = ssh_command('rm -f /CCS/VARIABLE/INPUTS/MTL/*', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS deleted MTL directory", "MCS Failed to delete MTL directory")
        
        cmd     = ssh_command('rm -f /CCS/VARIABLE/RESULTS/activity_stack_files/*', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS deleted TC sequence files", "MCS failed to delete TC sequence files")

        cmd     = ssh_command('rm -f rm -f /home/ccsexec/REPORTS/*', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS deleted TM/TC/EV reports", "MCS failed to delete TM/TC/EV reports")

        cmd     = ssh_command('find /data/mocExternalInterfaces/MCS/inTray/ -type f -delete', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS deleted incoming CADU files", "MCS failed to delete CADU files from in-tray")
    end

    ## --------------------------------------------------------------------

    desc "MCS NATS F0 - get session identifier"

    task :f0, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'aiv'
        host    = getHostname('aiv', args[:environment] )
        cmd     = ssh_command('decNATS -n NAOS_IVV_MCS_NATS -F0', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS NATS F0 successful", "MCS NATS F0 failed")
    end

    ## --------------------------------------------------------------------

    desc "MCS NATS F99 - get MCS NATS status"

    task :f99, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'aiv'
        host    = getHostname('aiv', args[:environment] )
        cmd     = ssh_command('decNATS -n NAOS_IVV_MCS_NATS -F99', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "MCS NATS F9 successful", "MCS NATS F9 failed")
    end

    ## --------------------------------------------------------------------


end

###############################################################################

