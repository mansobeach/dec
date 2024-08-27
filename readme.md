# OS dependencies

## Ubuntu / Debian
```
sudo apt-get install curl libcurl4-openssl-dev jq libssl-dev sshpass libsqlite3-dev sqlite3 libpq-dev libxml2-utils ncftp p7zip-full
```

## Red Hat / CentOS
```
sudo dnf groupinstall "Development Tools"
sudo dnf install sqlite
yum install perl-IPC-Cmd curl curl-devel sqlite-devel libxml2 openssl-devel
```


# Auxiliary data converter

## Introduction
Install the aux gem before the dec gem. 

## Dependencies

```
gem install dotenv
```


## Build

```
rake -f build_aux.rake aux:build
```


## Install

```
rake -f build_aux.rake aux:install
```


## Execute unit tests

```
auxUnitTests
```

# Data exchange component

## Build

```
rake -f build_dec.rake dec:build
```


## Install

```
rake -f build_aux.dec dec:install
```


## Commands

[DEC reference commands](doc/md/dec_reference_commands.md).


## Log messages

[DEC reference log messages](doc/md/dec_reference_log_messages.md).





