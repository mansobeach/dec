#!/usr/bin/env ruby

require 'rake'

require 'SSHClientCommands'

require_relative 'IVV_Environment_NAOS_MOC'
require_relative 'IVV_Logger'

# https://gist.github.com/ntamvl/7a6658b4cd82d6fbd15434f0a9953411
# https://stackoverflow.com/questions/17811260/rake-tasks-inside-gem-not-being-found
# https://www.rubydoc.info/gems/rake/Rake/Application
# https://stackoverflow.com/questions/6063725/how-to-use-hooks-in-ruby-gems


# =========================================================================
    
namespace :dec do

    include CTC::SSHClientCommands
    include IVV

    ## --------------------------------------------------------------------
    #
    desc "DEC start listeners to the configured interfaces"

    task :start, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{t.name} - missing host parameter")
            next
        end
        user    = 'gsc4eo' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = nil
        
        if args[:host].downcase == 'mds-uap' then
            cmd     = ssh_command("podman run --userns keep-id --env 'USER' --add-host=nl2-s-aut-srv-01:10.23.20.50 --network=host --tz=Europe/London --name dec -d --mount type=bind,source=/data,destination=/data localhost/dec_naos-test_gsc4eo_nl2-u-moc-srv-01:latest", user, host)
        end

        if cmd == nil then
            @logger.error('Host #{args[:host].downcase} not supported yet')
            next
        end

        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC@#{host} has been started", "GTA@#{host} start failed")
    end
    ## --------------------------------------------------------------------

    ## --------------------------------------------------------------------
    #        
    desc "DEC shutdown listeners to the configured interfaces"

    task :shutdown, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{t.name} - missing host parameter")
            next
        end
        user    = 'gsc4eo' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('podman container stop dec', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC@#{host} has been shutdown", "DEC@#{host} shutdown failed")
    end
    ## --------------------------------------------------------------------

    desc "DEC status @ host"

    task :status, [:host, :environment] do |t, args|
        @logger = load_logger
        args.with_defaults(:environment => 'ndc')
        if args[:host] == nil then
            @logger.error("rake #{t.name} - missing host parameter")
            next
        end
        user    = 'gsc4eo' 
        host    = getHostname( args[:host], args[:environment] )
        cmd     = ssh_command('podman container ls -a', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC container status is successful", "DEC container status failed")
    end
        
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP list IERS BULA available"

    task :list_iers_bula, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m IERS_BULA -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC IERS BULA list is successful", "DEC IERS BULA list failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP list IERS BULC available"

    task :list_iers_bulc, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m IERS_BULC -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC IERS BULA list is successful", "DEC IERS BULA list failed")
    end    

    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP list NASA NBULA available"

    task :list_nasa_nbula, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m NASA_NBULA -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC NASA NBULA list is successful", "DEC NASA NBULA list failed")
    end
       
    ## --------------------------------------------------------------------
    
    desc "DEC @MDS-UAP list NASA NBULC available"

    task :list_nasa_nbulc, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m NASA_NBULC -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC IERS BULC list is successful", "DEC NASA NBULC list failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP list NASA SFL available"

    task :list_nasa_sfl, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m NASA_SFL -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC NASA SFL list is successful", "DEC NASA SFL list failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP list Celestrak TLE available"

    task :list_celestrak_tle, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m CELESTRAK_TLE -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC Celestrak TLE list is successful", "DEC Celestrak TLE list failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP list Celestrak TCA available"

    task :list_celestrak_tca, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m CELESTRAK_TCA -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC Celestrak TCA list is successful", "DEC Celestrak TCA list failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP list Celestrak SFS available"

    task :list_celestrak_sfs, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m CELESTRAK_SFS -l', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC Celestrak SFS list is successful", "DEC Celestrak SFS list failed")
    end
       
    ## --------------------------------------------------------------------

    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP get current IERS BULA available"

    task :get_iers_bula, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m IERS_BULA', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC IERS BULA download is successful", "DEC IERS BULA download failed")
    end
      
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP get current IERS BULC available"

    task :get_iers_bulc, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m IERS_BULC', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC IERS BULA download is successful", "DEC IERS BULA download failed")
    end    

    ## --------------------------------------------------------------------

    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP get current NASA NBULA available"

    task :get_nasa_nbula, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m NASA_NBULA', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC NASA NBULA download is successful", "DEC NASA NBULA download failed")
    end
       
    ## --------------------------------------------------------------------
    
    desc "DEC @MDS-UAP get current NASA NBULC available"

    task :get_nasa_nbulc, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m NASA_NBULC', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC IERS BULC download is successful", "DEC NASA NBULC download failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP get current Celestrak TLE available"

    task :get_celestrak_tle, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m CELESTRAK_TLE', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC Celestrak TLE download is successful", "DEC Celestrak TLE download failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP get currrent Celestrak TCA available"

    task :get_celestrak_tca, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m CELESTRAK_TCA', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC Celestrak TCA download is successful", "DEC Celestrak TCA download failed")
    end
       
    ## --------------------------------------------------------------------

    desc "DEC @MDS-UAP get current Celestrak SFS available"

    task :get_celestrak_sfs, [:environment] do |t, args|
        args.with_defaults(:environment => 'ndc')
        @logger = load_logger
        user    = 'gsc4eo' 
        host    = getHostname( 'mds-uap', args[:environment] )
        cmd     = ssh_command('podman exec dec decGetFromInterface -m CELESTRAK_SFS', user, host)
        @logger.debug(cmd)
        ret     = system(cmd)
        logTaskResult(@logger, ret, "DEC Celestrak SFS download is successful", "DEC Celestrak SFS download failed")
    end
       
    ## --------------------------------------------------------------------





end
# =========================================================================

