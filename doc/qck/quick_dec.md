![](./res/logo_elecnor_deimos.png)

Pre-requisites
==============

-	A recent version of ruby interpreter 2.X (tested with ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux] & ruby 2.4.2p198 (2017-09-14 revision 59899) [x86_64-darwin16])
-	Bundler gem Installation`sudo gem install bundler`
-	Installation of gem dependencies (from location where Gemfile is placed)`bundle install --clean`

Installation Procedure
======================

From the command line execute:

`gem install dec.gem --local`

Uninstallation Procedure
========================

From the command line execute:

`gem uninstall dec`

Execution Environment
=====================

The execution environment of DEC is ruled by the following environment variables:  
- DEC_CONFIG: directory for the configuration files  
- DEC_DB_ADAPTER: database adapter for persistence of the circulations ; sqlite3 is used for the unit tests.  
- DEC_DATABASE_NAME: name of database used for the persistence layer  
- DEC_DATABASE_USER: username of the database used for persistence  
- DEC_DATABASE_PASSWORD: credentials for the database used for persistence  
- HOSTNAME: used for the mail transactions

Inventory
=========

DEC relies on a database to record every data circulation performed inbound /
outbound.


Unit Tests
==========

DEC unit tests are shipped with the SW bundle. They can be used to verify the correctness of the installation and adequacy of the execution environment.

The configuration used is based on the localhost protocols . Please refer to the docker file Dockerfile_dec_test for the definition of the execution environment.

Unit tests as well verify circulations from external providers, IERS, to fetch the UT1-UTC correlation data. Therefore network connectivity towards Internet is a pre-requisite for their successful execution.

Execute the following command:  
`decUnitTests`

Container Support
=================

Containers are used to define and provision the environment used for the tests of DEC.

-	build the image:  
	`docker image build -t app_dec:latest . -f Dockerfile_dec_test`

-	manual testing, override the ENTRYPOINT by execution of a console:  
	`docker container run --name dec -i -t app_dec /bin/bash`

*Gotchas*: the environment for execution of the tests is currently root, which is a bad practice. However no mount points are shared with the host, so the risk compromise is limited.
