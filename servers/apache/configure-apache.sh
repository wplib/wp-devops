#!/usr/bin/env bash
#
# devops/core/providers/circleci/configure-apache.sh
#
#   Run the required steps to configure Apache to work correctly
#

#
# "Declarations" of the variables this script assumes
#
declare=${DOCUMENT_ROOT:=}
declare=${LOGS_ROOT:=}
declare=${SERVER_NAME:=}
declare=${SERVER_ALIAS:=}
declare=${PHPENV_ROOT:=}
declare=${PHP_VERSION:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${SHARED_SCRIPTS:=}
declare=${SERVERS_ROOT:=}
declare=${TEST_WEBSERVER:=}

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/configure-apache.log"

#
# Load the shared scripts
#
source "${SHARED_SCRIPTS}"

announce "Configuring Apache"

#
# CircleCI configures libphp5.so incorrectly when you specify PHP version
#   See: https://discuss.circleci.com/t/apache2-and-php-missing-libphp5-so/3300/6
#
#libphp5_so="/usr/lib/apache2/modules/libphp5.so"
#actual_libphp5_so="${PHPENV_ROOT}/versions/${PHP_VERSION}${libphp5_so}"
#announce "...Symlinking ${actual_libphp5_so} to ${libphp5_so}"
#sudo ln -sf "${actual_libphp5_so}" "${libphp5_so}"
#onError

#
# Create a document-root.conf into /etc/apache2/conf-available containing Define for $DOCUMENT_ROOT
#   See: https://stackoverflow.com/a/550808/102699  (for `echo <text> |sudo tee <file>`)
#
test_vars_conf="test-vars.conf"
test_vars_path="/etc/apache2/conf-available/${test_vars_conf}"

announce "...Creating ${test_vars_path}"
echo Define DOCUMENT_ROOT "${DOCUMENT_ROOT}" | sudo tee    "${test_vars_path}" >> $ARTIFACTS_FILE
echo Define LOGS_ROOT     "${LOGS_ROOT}"     | sudo tee -a "${test_vars_path}" >> $ARTIFACTS_FILE
echo Define SERVER_NAME   "${SERVER_NAME}"   | sudo tee -a "${test_vars_path}" >> $ARTIFACTS_FILE
echo Define SERVER_ALIAS  "${SERVER_ALIAS}"  | sudo tee -a "${test_vars_path}" >> $ARTIFACTS_FILE

#
# Enabling the variables defined in the lines above.
#
announce "...Enabling ${test_vars_path}"
sudo a2enconf "${test_vars_conf}" >> $ARTIFACTS_FILE
onError

#
# Copy our desired Apache conf into /etc/apache2/site-available
# Use `a2ensite` to create a symlink for the site config in /etc/apache2/sites-enabled
#
apache_conf="${SERVER_NAME}.conf"
sites_available="/etc/apache2/sites-available"

#announce "...${SERVERS_ROOT}/${TEST_WEBSERVER}/apache-website.conf to ${sites_available}/${apache_conf}"
#sudo cp "${SERVERS_ROOT}/${TEST_WEBSERVER}/apache-website.conf" "${sites_available}/${apache_conf}"
#announce "...Enabling ${apache_conf}"
#sudo a2ensite "${apache_conf}"

#
# Copy our Apache conf to the default configuration
#
announce "...Copying ${SERVERS_ROOT}/${TEST_WEBSERVER}/apache-website.conf to ${sites_available}/000-default.conf"
sudo cp "${SERVERS_ROOT}/${TEST_WEBSERVER}/apache-website.conf" "${sites_available}/000-default.conf"

#
# Making directory for logs
#
announce "...Making logs directory ${LOGS_ROOT}"
sudo mkdir -p "${LOGS_ROOT}"

#
# Restart the Apache server
#
announce "...Restarting Apache"
sudo service apache2 restart >> $ARTIFACTS_FILE

announce "Apache configuration complete."
