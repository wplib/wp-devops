#!/usr/bin/env bash
#
# build/dependencies.sh
#
#   Configure Ubuntu, Fixup Git Source repo, Configure Web Server, Install WP CLI and run Composer.
#

declare=${ARTIFACTS_FILE:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${INCLUDES_ROOT:=}
declare=${SERVERS_ROOT:=}
declare=${TEST_WEBSERVER:=}
declare=${DEPLOY_PROVIDER:=}
declare=${DEPLOY_PROVIDER_ROOT:=}

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/dependencies.log"

announce "Configuring Dependencies"

#
# Ensure shared scripts are executable
#
announce "...Make shared source executable"
sudo chmod +x devops/core/shared.sh

#
# Load the shared scripts
#
source devops/core/shared.sh

#
# Make changes to the Linux environment
#
announce "Running ${INCLUDES_ROOT}/configure-env.sh"
source "${INCLUDES_ROOT}/configure-env.sh"

#
# Fixup anything that needs to be done to
# source files.
#
announce "Running ${INCLUDES_ROOT}/fixup-source.sh"
source "${INCLUDES_ROOT}/fixup-source.sh"

#
# Configure Apache & PHP to operate correctly
#
announce "Running ${SERVERS_ROOT}/${TEST_WEBSERVER}/configure-apache.sh"
source "${SERVERS_ROOT}/${TEST_WEBSERVER}/configure-apache.sh"

#
# Install any apt-get packages
#
announce "Running ${INCLUDES_ROOT}/install-apt-get.sh"
source "${INCLUDES_ROOT}/install-apt-get.sh"

#
# Install WP-CLI
#
announce "Running ${INCLUDES_ROOT}/install-wp-cli.sh"
source "${INCLUDES_ROOT}/install-wp-cli.sh"

#
# Run composer install to bring in WordPresss core, plugins and extra themes
#
announce "Running ${INCLUDES_ROOT}/compose.sh"
source "${INCLUDES_ROOT}/compose.sh"

#
# Run deploy provider's dependencies
#
DEPLOY_PROVIDER_DEPENDENCIES="$(get_provider_specific_script "dependencies.sh")"
if [ -f "${DEPLOY_PROVIDER_DEPENDENCIES}" ] ; then
    announce "Running deploy provider's dependencies: ${DEPLOY_PROVIDER_DEPENDENCIES}"
    source "${DEPLOY_PROVIDER_DEPENDENCIES}"
fi
