Pre-requisites
==============

-	A recent version of ruby interpreter 2.X (tested with ruby 2.5.1p57 (2018-03-29 revision 63029) [x86_64-linux] & ruby 2.4.2p198 (2017-09-14 revision 59899) [x86_64-darwin16])
-	Bundler gem Installation`sudo gem install bundler`
-	Installation of gem dependencies (from location where Gemfile is placed)`bundle install --clean`

Installation Procedure
======================

`gem install dec_rpf-1.0.3.gem --local`

Uninstallation Procedure
========================

`gem uninstall dec_rpf`

Execution Environment
=====================

This section defines the execution environment for the DEC/RPF. TBW

Integration Tests
=================

Configuration is FTP *non secure* to *localhost* with user and password *e2edctest*. Configuration to execute Integration Tests can be changed at the location of the gem deployment, such as /home/e2edctest/ruby/lib/ruby/gems/2.5.0/gems/dec_rpf-1.0.4/code/dec/../../config.

The integration tests make usage of a specific configuration defined at execution time which allows their execution in the production environment without collision.

To execute the integration tests:

`decUnitTests_RPF`

RPF Artifacts
=============

The following RPF artifacts are simulated and included in the DEC/RPF installation package for unit tests only > .bin

It has been assumed that RPF invokes them natively with full path specification driven by RPFBIN environment variable:

-	`put_report.bin`
-	`removeSchema.bin`
-	`write2Log.bin`

If RPF invokes them by call using $PATH, a different installation package would be needed which would remove unit tests.

RPF Simulation
==============

The DEC/RPF Unit Tests include the generation of a simulated RPF environment for integration verification purposes.

The following inventory tables are created with the columns / fields strictly used by DEC/RPF:

-	PARAMETERS_TB
-	ROP_TB
-	FILE_TB
-	FILE_ROP_TB
-	ROP_FILE_VW

ROP_FILE_VW is created as a table instead of a view where unit tests ensure that contents are aligned with the tables such view refers to within the RPF operational environment.

The ORM has been configured to use *sqlite3* instead of *postgresql* which is the RPF operational RDBMS.

RPF Integration tests
=====================

-	sendROP
-	sendROP Emergency
-	internal / intermediate tools used by previous
