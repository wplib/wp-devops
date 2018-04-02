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

declare=${SERVERS_ROOT:=}
declare=${TEST_WEBSERVER:=}

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/configure-apache.log"

announce "Configuring Apache"

PHP_SHORT_VERSION="${PHP_VERSION:0:3}"

case "${PHP_SHORT_VERSION}" in
5.6)
    #
    # CircleCI configures libphp5.so incorrectly when you specify PHP version
    #   See: https://discuss.circleci.com/t/apache2-and-php-missing-libphp5-so/3300/6
    #
    libphp_so="/usr/lib/apache2/modules/libphp5.so"
    actual_libphp_so="${PHPENV_ROOT}/versions/${PHP_VERSION}${libphp_so}"
    announce "...Symlinking ${actual_libphp_so} to ${libphp_so}"
    sudo ln -sf "${actual_libphp_so}" "${libphp_so}"
    ;;
7.0|7.1)
    #
    # CircleCI does not configure Apache correctly when you use PHP 7.x
    #
    announce "...Disable PHP5 on Apache"
    sudo a2dismod php5 >> $ARTIFACTS_FILE 2>&1

    announce "...Attaching Personal Package Archives (PPA) for PHP"
    sudo add-apt-repository ppa:ondrej/php --yes >> $ARTIFACTS_FILE 2>&1

    announce "...Attaching Personal Package Archives (PPA) for Apache"
    sudo add-apt-repository ppa:ondrej/apache2 --yes >> $ARTIFACTS_FILE 2>&1

    announce "...Updating apt-get after attaching PPAs"
    sudo apt-get update >> $ARTIFACTS_FILE 2>&1

    announce "...Installing Apache module for PHP ${PHP_SHORT_VERSION}"
    sudo apt-get install libapache2-mod-php"${PHP_SHORT_VERSION}" >> $ARTIFACTS_FILE 2>&1

    announce "...Enabling Apache module for PHP ${PHP_SHORT_VERSION}"
    sudo a2enmod php"${PHP_SHORT_VERSION}" >> $ARTIFACTS_FILE 2>&1
    ;;
esac


#
# Create a document-root.conf into /etc/apache2/conf-available containing Define for $DOCUMENT_ROOT
#   See: https://stackoverflow.com/a/550808/102699  (for `echo <text> |sudo tee <file>`)
#
test_vars_conf="test-vars.conf"
test_vars_path="/etc/apache2/conf-available/${test_vars_conf}"

announce "...Creating ${test_vars_path}"
echo Define DOCUMENT_ROOT "${DOCUMENT_ROOT}" | sudo tee    "${test_vars_path}" >> $ARTIFACTS_FILE 2>&1
echo Define LOGS_ROOT     "${LOGS_ROOT}"     | sudo tee -a "${test_vars_path}" >> $ARTIFACTS_FILE 2>&1
echo Define SERVER_NAME   "${SERVER_NAME}"   | sudo tee -a "${test_vars_path}" >> $ARTIFACTS_FILE 2>&1
echo Define SERVER_ALIAS  "${SERVER_ALIAS}"  | sudo tee -a "${test_vars_path}" >> $ARTIFACTS_FILE 2>&1

#
# Enabling the variables defined in the lines above.
#
announce "...Enabling ${test_vars_path}"
sudo a2enconf "${test_vars_conf}" >> $ARTIFACTS_FILE 2>&1

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
sudo service apache2 restart >> $ARTIFACTS_FILE 2>&1

announce "Apache configuration complete."
