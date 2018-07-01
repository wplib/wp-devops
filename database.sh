#!/usr/bin/env bash
#
# devops/core/database.sh
#
# Configure DB server, create database, add user and permissions then import provision.sql database.
#

declare=${SHARED_SCRIPTS:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${REPO_ROOT:=}
declare=${DB_HOST:=}
declare=${DB_NAME:=}
declare=${DB_USER:=}
declare=${DB_PASSWORD:=}
declare=${FIX_MYSQL56_COMPATIBILITY:=}

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/database.log"

#
# Load the shared scripts
#
source "${SHARED_SCRIPTS}"

#
# Drop and create DB, create user, import provision database
#
announce "Preparing and importing database"


if [ "yes" == "${FIX_MYSQL56_COMPATIBILITY}" ] ; then
    # REF: https://dev.mysql.com/doc/refman/5.7/en/signal.html
    # REF: https://dev.mysql.com/doc/refman/5.7/en/declare-handler.html
    # REF: http://www.mysqltutorial.org/mysql-signal-resignal/
    # REF: http://www.mysqltutorial.org/mysql-error-handling-in-stored-procedures/
    # REF: http://www.dbrnd.com/2015/05/mysql-error-handling/
    #
    #   WPEngine using MySQL 5.6 and `SELECT @@GLOBAL.sql_mode` => 'NO_ENGINE_SUBSTITUTION'
    #       Thus to import their mysql.sql we need to set SQL mode to match.
    #       See: https://dev.mysql.com/doc/refman/5.6/en/sql-mode.html#sql-mode-setting
    #
    #       MySQL 5.7, used by CircleCI, added NO_ZERO_DATE and NO_ZERO_IN_DATE which
    #       broke importing MySQL 5.6 date fields with DEFAULT '0000-00-00 00:00:00'
    #       See: https://dev.mysql.com/doc/refman/5.7/en/sql-mode.html#sql-mode-changes
    #
    announce "...Setting MySQL 5.6 compatibility"
    mysql -u ubuntu <<___MYSQL___
SET GLOBAL sql_mode='NO_ENGINE_SUBSTITUTION';
SET SESSION sql_mode='NO_ENGINE_SUBSTITUTION';
___MYSQL___
fi


#
# Ensure we don't have the database.
#
announce "...Dropping ${DB_NAME} database if exists"
mysql -u ubuntu <<___MYSQL___ 
DROP DATABASE IF EXISTS ${DB_NAME};
___MYSQL___

#
# Create the `wordpress` database
#
announce "...Create (new) ${DB_NAME} database"
mysql -u ubuntu <<___MYSQL___ 
CREATE DATABASE ${DB_NAME};
___MYSQL___

#
# Create user `wordpress` with password `wordpress`
#
announce "...Create user '${DB_USER}'@'${DB_HOST}' with password '${DB_PASSWORD}'"
mysql -u ubuntu <<___MYSQL___
USE ${DB_NAME};
CREATE USER '${DB_USER}'@'${DB_HOST}' IDENTIFIED BY '${DB_PASSWORD}';
___MYSQL___

#
# Grant all privledges on `wordpress` to user 'wordpress'@'127.0.0.1"
#
announce "...Grant all privledges on ${DB_NAME} database to user '${DB_USER}'@'${DB_HOST}'"
mysql -u ubuntu <<___MYSQL___
USE ${DB_NAME};
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'${DB_HOST}';
___MYSQL___

#
# Flush the privledges
#
announce "...Flush privledges"
mysql -u ubuntu <<___MYSQL___
USE ${DB_NAME};
FLUSH PRIVILEGES;
___MYSQL___

#
# Import the `provision.sql` database
#
PROVISION_SQL="${REPO_ROOT}/sql/provision.sql"
if [ -d "${PROVISION_SQL}" ] ; then
    announce "...Unchunking ${PROVISION_SQL}/provision-???.sql.chunk"
    mv "${PROVISION_SQL}" "${PROVISION_SQL}.bak"
    cat "${PROVISION_SQL}".bak/provision-???.sql.chunk > $PROVISION_SQL
fi

#
# Check to see if we have a post-install-apt-get.sh "hook"
#
PRE_PROCESS_PROVISION_SQL="${DEVOPS_ROOT}/pre-process-provision.sql.sh"
if [ -f "${PRE_PROCESS_PROVISION_SQL}" ] ; then
    announce "...Running ${PRE_PROCESS_PROVISION_SQL}"
    source "${PRE_PROCESS_PROVISION_SQL}"
fi


announce "...Import ${PROVISION_SQL} database"
mysql -u ubuntu <<___MYSQL___
USE ${DB_NAME};
SOURCE ${PROVISION_SQL};
___MYSQL___

announce "Database complete."
