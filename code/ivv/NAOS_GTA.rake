#!/usr/bin/env ruby

require 'rake'

require 'SSHClientCommands'
require 'WrapperCURL'

require_relative 'IVV_Environment_NAOS_MOC'
require_relative 'IVV_Logger'

# https://gist.github.com/ntamvl/7a6658b4cd82d6fbd15434f0a9953411
# https://stackoverflow.com/questions/17811260/rake-tasks-inside-gem-not-being-found
# https://www.rubydoc.info/gems/rake/Rake/Application
# https://stackoverflow.com/questions/6063725/how-to-use-hooks-in-ruby-gems


# =========================================================================
    
namespace :gta do

    include CTC::WrapperCURL
    include CTC::SSHClientCommands
    include IVV

    ## --------------------------------------------------------------------
    
    desc "GTA start"

    task :start, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{Rake.application.top_level_tasks[0]} - missing host parameter")
            next
        end
        user    = 'gsc4eoadmin' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('podman container start gta', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "GTA@#{host} has been started", "GTA@#{host} start failed")
    end
    ## --------------------------------------------------------------------

    ## --------------------------------------------------------------------
       
    desc "GTA shutdown"

    task :shutdown, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{Rake.application.top_level_tasks[0]} - missing host parameter")
            next
        end
        user    = 'gsc4eoadmin' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('podman container stop gta', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "GTA is shutdown", "GTA shutdown failed")
    end
    ## --------------------------------------------------------------------

    desc "GTA status"

    task :status, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{Rake.application.top_level_tasks[0]} - missing host parameter")
            next
        end
        user    = 'gsc4eoadmin' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('podman container ls -a', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "GTA status is successful", "GTA status failed")
    end
        
    ## --------------------------------------------------------------------

    desc "GTA updatenaosconfig"

    task :updatenaosconfig, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{Rake.application.top_level_tasks[0]} - missing host parameter")
            next
        end
        host    = getHostname( args[:host], args[:environment] )
        api     = '/api/gta/updatenaosconfig'
        url     = "#{host}:8080#{api}"
        ret     = getURL(url, false, nil, nil, true, @logger)
        logTaskResult(@logger, ret, "GTA updatenaosconfig is successful", "GTA updatenaosconfig failed")
    end        
    ## --------------------------------------------------------------------

    desc "GTA show logs"

    task :logs, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{Rake.application.top_level_tasks[0]} - missing host parameter")
            next
        end
        user    = 'gsc4eoadmin' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('podman logs gta', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "GTA request for logs is successful", "GTA request for logs failed")
    end
        
    ## --------------------------------------------------------------------

    desc "GTA list available EOP / bulletins"
    
    task :list_eop, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{Rake.application.top_level_tasks[0]} - missing host parameter")
            next
        end
        user    = 'gsc4eoadmin' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('ls -l ~/backend/data/GTA_home/lwd/eop/finals', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "GTA request for available EOP is successful", "GTA request for available EOP failed")
    end
    ## --------------------------------------------------------------------

    desc "GTA list available FDS OEM"
    
    task :list_oem, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{Rake.application.top_level_tasks[0]} - missing host parameter")
            next
        end
        user    = 'gsc4eoadmin' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('ls -l ~/backend/data/GTA_home/lwd/oem', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "GTA request for available FDS OEM is successful", "GTA request for available FDS OEM failed")
    end
    ## --------------------------------------------------------------------


end
# =========================================================================

