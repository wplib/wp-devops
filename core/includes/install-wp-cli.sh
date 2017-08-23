#!/usr/bin/env bash
#
# devops/core/includes/install-wp-cli.sh
#
#   Install WP-CLI
#

#
# "Declarations" of the variables this script assumes
#
declare=${SHARED_SCRIPTS:=}
declare=${WP_CLI_SOURCE:=}
declare=${WP_CLI_FILEPATH:=}

announce "Installing WP-CLI"

#
# Add the executable flat
#
announce "...Make WP-CLI executable"
chmod +x "${WP_CLI_SOURCE}"

#
# Add the executable flat
#
announce "...Copying WP-CLI from ${WP_CLI_SOURCE} to ${WP_CLI_FILEPATH}"
sudo cp "${WP_CLI_SOURCE}" "${WP_CLI_FILEPATH}"

announce "WP-CLI installed"


