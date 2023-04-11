#!/usr/bin/env ruby



def createCurlRequest(api, environment)
  if environment.downcase == "staging" then
    return "curl -v nl2-s-fds-srv-01:8080#{api}"
  end

  if environment.downcase == "ndc" then
    return "curl -v lundclfds01.lux-naos.local:8080#{api}"
  end
  raise "environment #{environment} not supported"
end


def createRemoteCmd(cmd, environment)
  if environment.downcase == "staging" then
    return "ssh -i ~/.ssh/naos-aiv.id_rsa -t -oBatchMode=no -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' -oConnectTimeout=10 -oPort=22 -oLogLevel=QUIET gsc4eoadmin@nl2-s-fds-srv-01 '#{cmd}'"
  end

  if environment.downcase == "ndc" then
    return "ssh -i ~/.ssh/naos-aiv.id_rsa -t -oBatchMode=no -o 'UserKnownHostsFile=/dev/null' -o 'StrictHostKeyChecking=no' -oConnectTimeout=10 -oPort=22 -oLogLevel=QUIET gsc4eoadmin@lundclfds01.lux-naos.local '#{cmd}'"
  end
  raise "environment #{environment} not supported"
end

def task_fds_shutdown(environment)
  cmd = createRemoteCmd('sudo systemctl --no-pager stop naos-fds4eo-app.service', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('pkill -f "fdsdaemon.daemon_main"', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('podman container stop gta', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts
end

def task_fds_cleanup(environment)
  cmd = createRemoteCmd('sudo systemctl restart postgresql.service', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('PGPASSWORD=postgres psql -h localhost -U postgres -c "drop database naos_fds4eo" ', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('PGPASSWORD=postgres psql -h localhost -U postgres -c "create database naos_fds4eo" ', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts
end 

def task_fds_basic_restore(environment)
  cmd = createRemoteCmd('cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB.sql -h localhost -U postgres naos_fds4eo ', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB_INSTALLER_VALUES.sql -h localhost -U postgres naos_fds4eo ', environment)
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB_REFERENCE_GROUND_TRACK.sql -h localhost -U postgres naos_fds4eo', environment)
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('cd ~/backend/data ; PGPASSWORD=postgres psql -f FDS_DB_ALLOWED_CORRIDOR.sql -h localhost -U postgres naos_fds4eo', environment)
  ret = system(cmd)
  puts ret
  puts
end

def task_fds_start(environment)
  cmd = createRemoteCmd('cd ~/backend; python3 -mfdsdaemon.daemon_main /home/gsc4eoadmin/backend/fdsdaemon/daemon_properties.txt', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('podman start gta', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('sudo systemctl --no-pager start naos-fds4eo-app.service', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  sleep(8)

  cmd = createCurlRequest('/api/gta/updatenaosconfig', environment)
  puts cmd
  ret = system(cmd)
  puts
  puts ret
  puts  
end

def task_fds_status(environment)
  cmd = createRemoteCmd('sudo systemctl --no-pager status naos-fds4eo-app.service', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('ps faux |grep fdsdaemon.daemon_main', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts

  cmd = createRemoteCmd('podman container ls -a', environment)
  puts cmd
  ret = system(cmd)
  puts ret
  puts
end


if ARGV[0] == nil or ARGV[0] == '' then
  raise "missing argument"
end

environment = ARGV[0].dup

task_fds_shutdown(environment)

task_fds_cleanup(environment)

task_fds_basic_restore(environment)

task_fds_start(environment)

task_fds_status(environment)
