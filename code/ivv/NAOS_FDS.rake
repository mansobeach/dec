#!/usr/bin/env ruby

require 'rake'

require 'SSHClientCommands'

require_relative 'IVV_Environment_NAOS_MOC'
require_relative 'IVV_Logger'

# https://gist.github.com/ntamvl/7a6658b4cd82d6fbd15434f0a9953411
# https://stackoverflow.com/questions/17811260/rake-tasks-inside-gem-not-being-found
# https://www.rubydoc.info/gems/rake/Rake/Application

# https://stackoverflow.com/questions/6063725/how-to-use-hooks-in-ruby-gems


###############################################################################
## Namespace for FDS

namespace :fds do

    include CTC::SSHClientCommands
    include IVV

    # import('NAOS_GTA.rake')

    ## --------------------------------------------------------------------

    desc "FDS init with database cleaning & basic restore"

    task :initvoid, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        
        Rake::Task['fds:shutdown'].invoke(args[:environment])

        # Rake::Task['fds:gta:shutdown'].invoke(args[:environment])

        Rake::Task['fds:dbcleanup'].invoke(args[:environment])

        Rake::Task['fds:dbbasicrestore'].invoke(args[:environment])

        Rake::Task['fds:start'].invoke(args[:environment])

        # Rake::Task['gta:start'].invoke('fds', args[:environment])
        
        Rake::Task['fds:status'].invoke(args[:environment])

        Rake::Task['gta:updatenaosconfig'].invoke('fds', args[:environment])

    end
    ## --------------------------------------------------------------------

    desc "FDS shutdown"

    task :shutdown, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname('fds', args[:environment] )
        
        cmd     = ssh_command('sudo systemctl --no-pager stop naos-fds4eo-app.service', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "systemctl service naos-fds4eo-app.service stopped", "Failed to stop service naos-fds4eo-app.service")

        cmd     = ssh_command('pkill -f "fdsdaemon.daemon_main"', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "FDS backend stopped", "Failed to stop FDS backend")
    end
    ## --------------------------------------------------------------------

    desc "FDS start"

    task :start, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname('fds', args[:environment] )
        
        cmd     = ssh_command('cd ~/backend; python3 -mfdsdaemon.daemon_main /home/gsc4eoadmin/backend/fdsdaemon/daemon_properties.txt', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "FDS backend daemon started", "Failed to start FDS backend daemon")
        
        Rake::Task['fds:gta:start'].invoke(args[:environment])
        
        cmd     = ssh_command('sudo systemctl --no-pager start naos-fds4eo-app.service', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "systemctl service naos-fds4eo-app.service started", "Failed to start service naos-fds4eo-app.service")
    end
    ## --------------------------------------------------------------------

    desc "FDS status"

    task :status, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname('fds', args[:environment] )
        
        # front-end
        cmd     = ssh_command('sudo systemctl --no-pager status naos-fds4eo-app.service', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "request of status for service naos-fds4eo-app.service is successful", "failed to request status service naos-fds4eo-app.service")
        
        # back-end
        cmd     = ssh_command('ps faux |grep fdsdaemon.daemon_main', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "request of FDS backend status is succesful", "failed to request FDS backend daemon")

        # gta
        load('NAOS_GTA.rake')
        Rake::Task['gta:status'].invoke('fds', args[:environment])
    end

    ## --------------------------------------------------------------------

    desc "FDS database clean-up"

    task :dbcleanup, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname('fds', args[:environment] )

        cmd     = ssh_command('sudo systemctl restart postgresql.service', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        @logger.info(ret)
      
        cmd     = ssh_command( 'PGPASSWORD=postgres psql -h localhost -U postgres -c "drop database naos_fds4eo" ', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        @logger.info(ret)
      
        cmd     = ssh_command( 'PGPASSWORD=postgres psql -h localhost -U postgres -c "create database naos_fds4eo" ', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        @logger.info(ret)
    end

    ## --------------------------------------------------------------------

    desc "FDS database basic restore"

    task :dbbasicrestore, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eoadmin'
        host    = getHostname('fds', args[:environment] )

        cmd     = ssh_command( 'cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB.sql -h localhost -U postgres naos_fds4eo ', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        @logger.info(ret)
      
        cmd     = ssh_command( 'cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB_INSTALLER_VALUES.sql -h localhost -U postgres naos_fds4eo ', user, host )
        @logger.debug(cmd)
        ret     = system(cmd)
        @logger.info(ret)
      
        cmd     = ssh_command( 'cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB_REFERENCE_GROUND_TRACK.sql -h localhost -U postgres naos_fds4eo', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        @logger.info(ret)

        cmd     = ssh_command( 'cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB_ALLOWED_CORRIDOR.sql -h localhost -U postgres naos_fds4eo', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        @logger.info(ret)
    end

    ## --------------------------------------------------------------------


end

###############################################################################

