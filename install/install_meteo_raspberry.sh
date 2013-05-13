#!/bin/bash

#########################################################################
#
# === Create Package METEO      
#
# === Written by Borja Lopez Fernandez
#
# === Casale & Beach
# 
#########################################################################


INSTALL_USER=`whoami`
WORKING_DIR=`pwd`
LOGFILE=meteo_install_`date +%Y%m%d%H%M`.log

INSTALL_PACKAGES=0
INSTALL_GEMS=0

INSTALL_TABLES=1


DB_ADAPTER="postgresql"
MY_MINARC_CONFIG=""
MY_MINARC_DB_NAME=""
MY_MINARC_DB_USER=""
MY_MINARC_DB_PASSWORD=""

METEO_USER="meteo"



#Use environmental var if exists
if [ "$MINARC_BASE" = "" ]; then
    MINARC_BASE="/home/meteo/Projects/dec"
fi

PROFILE="$MINARC_BASE/etc/profile"

#Other needed paths and variables...

SETCOLOR_SUCCESS="echo -en \\033[0;32m"
SETCOLOR_FAILURE="echo -en \\033[0;31m"
SETCOLOR_WARNING="echo -en \\033[0;33m"
SETCOLOR_NORMAL="echo -en \\033[0;39m"

# -------------------------------------------------------------------------

dump ()
{
#  Dump to both stdout/stderr and LOG file, using 'tee'
    echo "$1" 2>&1 | tee -a $MINARC_BASE/$LOGFILE
}

# -------------------------------------------------------------------------

print_success ()
{
    dump ""
    $SETCOLOR_SUCCESS
    echo -n "      [done]"
    $SETCOLOR_NORMAL
    echo "$1"
    echo "      [done] $1" >> $MINARC_BASE/$LOGFILE
    dump ""
}

# -------------------------------------------------------------------------

print_failure ()
{
    dump ""
    $SETCOLOR_FAILURE
    echo -n "      [abort]"
    $SETCOLOR_NORMAL
    echo "$1"
    echo "      [abort] $1" >> $MINARC_BASE/$LOGFILE
    dump ""
}

# -------------------------------------------------------------------------

print_warning ()
{
    dump ""
    $SETCOLOR_WARNING
    echo -n "      [warning]"
    $SETCOLOR_NORMAL
    echo "$1"
    echo "      [warning] $1" >> $MINARC_BASE/$LOGFILE
    dump ""
}

# -------------------------------------------------------------------------

check_user ()
{
    dump ""
    dump "1. Checking user..."

    if [ "$INSTALL_USER" != "$METEO_USER" ]; then
        LOOP=1
        while [ $LOOP -eq 1 ]; do
            dump ""
            $SETCOLOR_WARNING
            echo "      [warning] You are not \"$METEO_USER\" user"
            echo -n "          Are you sure you want to continue? (y/n) [y]:  "
            $SETCOLOR_NORMAL
            read cont
            if [ "$cont" = "N" -o \
                 "$cont" = "Y" -o \
                 "$cont" = "n" -o \
                 "$cont" = "y" -o \
                 "$cont" = "" ]; then
                LOOP=0
            fi
            if [ "$cont" = "N" -o "$cont" = "n" ]; then
                dump ""
                print_failure " Execution aborted by user";
                exit
            fi
            if [ "$cont" = "Y" -o "$cont" = "y" -o "$cont" = "" ]; then
                print_success " User validated to install the utility"
            fi
        done
    fi

    print_success " User \"$METEO_USER\" is allowed to install"
}

# -------------------------------------------------------------------------

check_prerequisites_oracle ()
{
    dump ""
    dump "2. Checking prerequisites for oracle..."

    # Check whether Oracle Listener is running or not
    ORA=`ps -u oracle | grep tnslsnr`
    
    if [ "$ORA" == "" ];then
       print_failure "Error Oracle Listener is not running !"
       exit
    fi
    
    if [ "$ORACLE_HOME" == "" ];then
       print_failure "Error ORACLE_HOME must be defined !"
       exit
    fi

    if [ "$ORACLE_SID" == "" ];then
       print_failure "Error ORACLE_SID must be defined !"
       exit
    fi

    print_success " All needed prerequisites exist !"

}

# -------------------------------------------------------------------------

check_prerequisites_mysql ()
{
    dump ""
    dump "2. Checking prerequisites for mysql..."

    mysql_path=`which mysql`
    echo -n "         MySQL is : $mysql_path"

    print_success " All needed prerequisites exist !"

}

# -------------------------------------------------------------------------

check_prerequisites_postgresql ()
{
    dump ""
    dump "2. Checking prerequisites for postgresql..."

    mysql_path=`which postgres`
    echo -n "         postgresql is : $mysql_path"

    print_success " Postgresql found !"

}


# -------------------------------------------------------------------------

request_variables ()
{
    dump ""
    dump "3. Requesting Variables..."
   
   echo -n "         --> Please specify the directory of MINARC Config files [MINARC_CONFIG]:  "
   read cont
   echo
   MY_MINARC_CONFIG="$cont"

   # Prepare a very simple connection test script
   # warning : mysql does not support oracle's ";"
   if [ $DB_ADAPTER == "oracle" ]; then
      echo "quit;" > /tmp/test_db_connection.sql
   elif [ $DB_ADAPTER == "mysql" ]; then
      echo "quit" > /tmp/test_db_connection.sql
   fi

   LOOP=1
   while [ $LOOP -eq 1 ]; do
      if [ $DB_ADAPTER == "mysql" ]; then
         echo -n "         --> Please specify the database NAME for this DEC installation:  "
         read cont
         MY_MINARC_DB_NAME="$cont"
      elif [ $DB_ADAPTER == "oracle" ]; then
         MY_MINARC_DB_NAME="$ORACLE_SID"
      fi

      echo
      echo -n "         --> Please specify the database USER for the MINARC Tables:  "
      read cont
      MY_MINARC_DB_USER="$cont"

      echo
      echo -n "         --> Please specify the database PASSWORD for the MINARC Tables:  "
      read cont
      MY_MINARC_DB_PASSWORD="$cont"
      
      if [ $DB_ADAPTER == "oracle" ]; then
         $ORACLE_HOME/bin/sqlplus -L $MY_MINARC_DB_USER/$MY_MINARC_DB_PASSWORD @ /tmp/test_db_connection.sql
      elif [ $DB_ADAPTER == "mysql" ]; then
         mysql $MY_MINARC_DB_NAME -u$MY_MINARC_DB_USER -p$MY_MINARC_DB_PASSWORD < /tmp/test_db_connection.sql
      fi

      if [ $? -ne 0 ]; then
         print_warning " Unable to connect to $MY_MINARC_DB_NAME ($MINARC_DB_ADAPTER) with $MY_MINARC_DB_USER/$MY_MINARC_DB_PASSWORD  :-("
      else
         print_success " All needed variables are set"
         LOOP=0
      fi
   done
   rm -f /tmp/test_db_connection.sql

}

# -------------------------------------------------------------------------

check_installation_package ()
{
    dump ""
    dump "4. Checking uncompressed directories..."
    for i in \
            "$WORKING_DIR/bin" \
            "$WORKING_DIR/dba" \
            "$WORKING_DIR/etc" \
            "$WORKING_DIR/cots" \
            "$WORKING_DIR/scripts" \
            "$WORKING_DIR/schemas" \
            "$WORKING_DIR/config" \
            "$WORKING_DIR/Licenses"; do
        if test -d $i; then
            dump "         --> Directory $i exists"
        else
           print_failure " Unable to find directory $i"
           exit
        fi
    done

    print_success " All needed uncompressed directories exist"

}

# -------------------------------------------------------------------------

install_directories ()
{
    dump ""
    dump "5. Installing MINARC directories..."
    for i in \
            "$WORKING_DIR/bin" \
            "$WORKING_DIR/config" \
            "$WORKING_DIR/dba" \
            "$WORKING_DIR/etc" \
            "$WORKING_DIR/cots" \
            "$WORKING_DIR/scripts" \
            "$WORKING_DIR/schemas" \
            "$WORKING_DIR/Licenses"; do
        dump "         --> cp -r $i $MINARC_BASE/"
        cp -r $i $MINARC_BASE/ 1>> $MINARC_BASE/$LOGFILE 2>> $MINARC_BASE/$LOGFILE
        if [ $? -ne 0 ]; then
           print_failure " Unable to install directory $i"
           exit
        fi
    done
    dump "         --> chmod -R o-rwx $MINARC_BASE/*"
    chmod -R o-rwx $MINARC_BASE/*

    dump "         --> chmod -R a-w $MINARC_BASE/bin/*"
    chmod -R a-w $MINARC_BASE/bin

    dump "         --> find $MINARC_BASE/bin/* -name '[a-z]*.rb' \! -type d -exec chmod 550 {} \;"
    find $MINARC_BASE/bin/* -name '[a-z]*.rb' \! -type d -exec chmod 550 {} \;

    dump "         --> find $MINARC_BASE/bin/* -name '[A-Z]*.rb' \! -type d -exec chmod 440 {} \;"
    find $MINARC_BASE/bin/* -name '[A-Z]*.rb' \! -type d -exec chmod 440 {} \;

    dump "         --> chmod -R a-w $MINARC_BASE/cots/*"
    chmod -R a-w $MINARC_BASE/cots 

#    if [ $? -ne 0 ]; then
#        print_warning " Unable to chmod COTS directory contents to avoid writing in it"
#    fi

    print_success " MINARC components correctly installed"
}

# -------------------------------------------------------------------------
patch_oci ()
{
    dump ""
    dump "6. Applying oci8 patch..."
    dump ""

    echo "puts $:.find {|dir| File.file? dir + \"/oci8.rb\"}" > /tmp/oci8_loc.rb

    oci_path=`ruby /tmp/oci8_loc.rb`

    if [ -f /tmp/oci8_loc.rb ]; then
      rm -f /tmp/oci8_loc.rb
    fi

    if [ ! -f $oci_path/oci8.rb ]; then
      print_failure " Unable to patch oci8.rb, the file was not found"
    else
      dump "         --> current oci8.rb is : $oci_path/oci8.rb"

      dump "         --> chmod u+w $oci_path/oci8.rb"
      chmod u+w $oci_path/oci8.rb

      dump "         --> cp $MINARC_BASE/bin/dbm/oci8.rb $oci_path/"
      cp $MINARC_BASE/bin/dbm/oci8.rb $oci_path/

      if [ $? -ne 0 ]; then
        print_failure " Unable to patch oci8.rb"
      else
        print_success " Patch applied successfully"
      fi
    fi
}
# -------------------------------------------------------------------------

set_profile ()
{
    dump ""
    dump "7. Setting user profile..."
    dump "         --> Setting standard environmental variables in $PROFILE..."
    
    # Create the profile
    echo "#!/bin/bash" > $PROFILE
    echo "" >> $PROFILE

    echo "# Start: Data Exchange Component environmental variables" >> $PROFILE
    echo "# ------------------------------------" >> $PROFILE

    dump "         --> Exporting MINARC_BASE"
    echo "export MINARC_BASE=$MINARC_BASE" >> $PROFILE

    dump "         --> Exporting MINARC_DB_ADAPTER"
    echo "export MINARC_DB_ADAPTER=$DB_ADAPTER" >> $PROFILE

    dump "         --> Exporting PATH"
    echo "export PATH=$MINARC_BASE/bin/minarc:$MINARC_BASE/cots:$MINARC_BASE/scripts:\$PATH" >> $PROFILE

    dump "         --> Exporting RUBYLIB"
    echo "export RUBYLIB=$MINARC_BASE/bin:$RUBYLIB" >> $PROFILE

    dump "         --> Exporting LD_LIBRARY_PATH"
    echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib:\$LD_LIBRARY_PATH" >> $PROFILE

    if [ $DB_ADAPTER == "oracle" ]; then
       dump "         --> Exporting MINARC_DATABASE_NAME"
       echo "export MINARC_DATABASE_NAME=$ORACLE_SID" >> $PROFILE
    elif [ $DB_ADAPTER == "mysql" ]; then
       dump "         --> Exporting MINARC_DATABASE_NAME"
       echo "export MINARC_DATABASE_NAME=$MY_MINARC_DB_NAME" >> $PROFILE
    fi

    dump "         --> Exporting MINARC_DATABASE_USER"
    echo "export MINARC_DATABASE_USER=$MY_MINARC_DB_USER" >> $PROFILE

    dump "         --> Exporting DCC_DATABASE_PASSWORD"
    echo "export MINARC_DATABASE_PASSWORD=$MY_MINARC_DB_PASSWORD" >> $PROFILE

    echo "" >> $PROFILE
    echo "" >> $PROFILE

    dump "         --> Exporting MINARC_CONFIG"
    
    if [ "$MY_MINARC_CONFIG" == "" ];then
       echo "export MINARC_CONFIG=$MINARC_BASE/config" >> $PROFILE
    else
       echo "export MINARC_CONFIG=$MY_MINARC_CONFIG" >> $PROFILE
    fi

    dump "         --> Exporting MINARC_TMP"
    echo "export MINARC_TMP=/tmp" >> $PROFILE

    echo "" >> $PROFILE
    echo "# This variable must point to the MINARC repositoy folder" >> $PROFILE
    echo "# export MINARC_ARCHIVE_ROOT=" >> $PROFILE

    echo "# ----------------------------------" >> $PROFILE



    echo "# End: Mini Archive Component environmental variables" >> $PROFILE
    echo "" >> $PROFILE
    echo "" >> $PROFILE

    print_success " Profile correctly created in $PROFILE"
}

# -------------------------------------------------------------------------

load_profile ()
{
    dump ""
    dump "8. Loading Profile ..."
    echo "" >> $HOME/.bash_profile
    echo "# DEIMOS Space - Mini Archive Component profile" >> $HOME/.bash_profile
    echo "source $MINARC_BASE/etc/profile" >> $HOME/.bash_profile
    echo "" >> $HOME/.bash_profile
    source $MINARC_BASE/etc/profile
}

# -------------------------------------------------------------------------

load_oracle_tables ()
{
    dump ""
    dump "   Loading Oracle Tables..."
    $ORACLE_HOME/bin/sqlplus $MY_MINARC_DB_USER/$MY_MINARC_DB_PASSWORD @ $MINARC_BASE/dba/creation/minarc/create_archived_files.sql
    $ORACLE_HOME/bin/sqlplus $MY_MINARC_DB_USER/$MY_MINARC_DB_PASSWORD @ $MINARC_BASE/dba/creation/minarc/create_archived_files_seq.sql

}

# -------------------------------------------------------------------------

load_mysql_tables ()
{
    dump ""
    dump "   Loading MySQL Tables..."
    mysql $MY_MINARC_DB_NAME -u$MY_MINARC_DB_USER -p$MY_MINARC_DB_PASSWORD < $MINARC_BASE/dba/creation/minarc/create_archived_files.sql

}

# -------------------------------------------------------------------------
drop_oracle_tables ()
{

    LOOP=1
    while [ $LOOP -eq 1 ]; do
       dump ""
       $SETCOLOR_WARNING
       echo "      [warning] You are about to DELETE MINARC Inventory data  !! ?:-| "
       echo "      By doing this you could loose coherency between the repository and the Database "
       echo
       echo "      Are you sure you want to continue? (y/n) [y]:  "
       $SETCOLOR_NORMAL
       read cont
       if [ "$cont" = "N" -o \
                 "$cont" = "Y" -o \
                 "$cont" = "n" -o \
                 "$cont" = "y" -o \
                 "$cont" = "" ]; then
                LOOP=0
            fi
            if [ "$cont" = "N" -o "$cont" = "n" ]; then
                dump ""
                print_failure " Execution aborted by user";
                exit
            fi
    done

    dump ""
    dump "9. Dropping Oracle Tables..."
    $ORACLE_HOME/bin/sqlplus $MY_MINARC_DB_USER/$MY_MINARC_DB_PASSWORD @ $MINARC_BASE/dba/deletion/minarc/delete_archived_files.sql
    $ORACLE_HOME/bin/sqlplus $MY_MINARC_DB_USER/$MY_MINARC_DB_PASSWORD @ $MINARC_BASE/dba/deletion/minarc/delete_archived_files_seq.sql

}

# -------------------------------------------------------------------------

drop_mysql_tables ()
{

    LOOP=1
    while [ $LOOP -eq 1 ]; do
       dump ""
       $SETCOLOR_WARNING
       echo "      [warning] You are about to DELETE DCC Inventory data  !! ?:-| "
       echo "      By doing this you could loose coherency between the repository and the Database "
       echo
       echo "      Are you sure you want to continue? (y/n) [y]:  "
       $SETCOLOR_NORMAL
       read cont
       if [ "$cont" = "N" -o \
                 "$cont" = "Y" -o \
                 "$cont" = "n" -o \
                 "$cont" = "y" -o \
                 "$cont" = "" ]; then
                LOOP=0
            fi
            if [ "$cont" = "N" -o "$cont" = "n" ]; then
                dump ""
                print_failure " Execution aborted by user";
                exit
            fi
    done

    dump ""
    dump "9. Dropping MySQL Tables..."
    mysql $MY_MINARC_DB_NAME -u$MY_MINARC_DB_USER -p$MY_MINARC_DB_PASSWORD < $MINARC_BASE/dba/deletion/minarc/delete_archived_files.sql

}

# -------------------------------------------------------------------------
load_gems ()
{
   for i in \
      "activerecord" \
      "net-ssh" \
      "net-sftp" \
      "postgresql" \
      "log4r"; do
        dump "         --> gem install $i --include-dependencies"
        gem install $i --include-dependencies
        if [ $? -ne 0 ]; then
           print_failure " Unable to install gem $i"
           # exit
        fi
    done
}

# -------------------------------------------------------------------------

load_apt_packages ()
{
   for i in \
      "chkconfig" \
      "makeself" \
      "ncftp" \
      "zip" \
      "compress" \
      "sqlite3" \
      "ruby1.8" \
      "rubygems" \
      "fortune"; do
        dump "         --> apt-get -y install $i "
        apt-get install $i
        if [ $? -ne 0 ]; then
           print_failure " Unable to install apt-package $i"
           # exit
        fi
    done
}

# -------------------------------------------------------------------------

print_usage ()
{
    echo ""
    echo "--------------------------------------------------------------------"
    echo "|                     MINI ARCHIVE COMPONENT                       |"
    echo "|               - Mission Data Systems DEIMOS Space -              |"
    echo "--------------------------------------------------------------------"
    echo ""
    echo ""
    echo "   Usage: ./install_minarc.sh -b oracle|mysql [-N]"
    echo ""
    echo "                           -N   No Database tables are installed"
    echo "                           -g   install required ruby gems"
    echo ""
    echo ""
    echo "      MINARC_BASE environmental variable:"
    echo "        \$> export MINARC_BASE=/new/path/to/install"
    echo ""
    echo ""
}

# -------------------------------------------------------------------------


# ==============================================================================
# INSTALL SCRIPT EXECUTION START POINT
# ==============================================================================


while getopts P:s:b:m:u:c:x:v:hkNg opt; do
  case "$opt" in
    P) SYSTEM_ARCH="$OPTARG";exit;;
    s) START_STEP="$OPTARG";;
    b) DB_ADAPTER="$OPTARG";;
    m) MAKESELF_DIR="$OPTARG";;
    u) CVSUSER="$OPTARG";;
    c) CVSSERVER="$OPTARG";;
    x) MYCOTS="$OPTARG";;
    t) TAGNAME="$OPTARG";;
    v) VERSION="$OPTARG";;
    N) INSTALL_TABLES=0;;
    g) INSTALL_GEMS=1;;
    k) KEEP_DIRS=1;;
    h) print_usage; exit;;
    \?) print_usage; exit;;
  esac
done


if test -d $MINARC_BASE; then
   echo "  Starting..."
else
   $SETCOLOR_FAILURE
   echo -n "       [abort]"
   $SETCOLOR_NORMAL
   echo " Installation directory must exist"
   echo "\$MINARC_BASE -> "$MINARC_BASE 
   exit;
fi


# Step 0. Print start information

dump ""
dump "-------------------------------------------------------------------------"
dump "|                    METEO package installer called                      |"
dump "|  The command line call was as follows:                                 |"
dump "|   \$> $0 $*"
dump "|                                                                        |"
dump "|  Will try to install the Meteo Casale in:                    |"
dump "|      $MINARC_BASE"
dump "-------------------------------------------------------------------------"
dump ""


# Step 1. Check user
check_user


# Step 2. Check prerequisites as needed directories
if [ $DB_ADAPTER == "oracle" ]; then
   check_prerequisites_oracle
elif [ $DB_ADAPTER == "mysql" ]; then
   check_prerequisites_mysql
elif [ $DB_ADAPTER == "postgresql" ]; then
   check_prerequisites_postgresql
fi


if [ $INSTALL_PACKAGES -eq 1 ]; then
   load_apt_packages
fi


if [ $INSTALL_GEMS -eq 1 ]; then
   load_gems
fi



exit


# Step 3. Request some environment variables
request_variables

exit

# Step 4. Check package
check_installation_package

# Step 5. Install directories
install_directories

# Step 6. Patch oci8
#patch_oci (no longer needed from activerecord 2)

# Step 7. Set profile in etc/profile
set_profile

# Step 8. Load profile in .bash_profile
#load_profile

# Step 9. Load oracle tables & sequences
if [ $INSTALL_TABLES -eq 1 ]; then
   if [ $DB_ADAPTER == "oracle" ]; then
      drop_oracle_tables
      load_oracle_tables
   elif [ $DB_ADAPTER == "mysql" ]; then
      drop_mysql_tables
      load_mysql_tables
   fi
fi


# Step 10. Print end information
dump ""
$SETCOLOR_SUCCESS
dump "      [done] DEIMOS-Space Mini Archive Component correctly installed !" #in $MINARC_BASE!"
$SETCOLOR_NORMAL
dump ""
