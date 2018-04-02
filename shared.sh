#!/usr/bin/env bash
#
# devops/core/shared.sh - Shared source for other scripts
#

declare=${SOURCE_REPO_ROOT:=}
declare=${CIRCLE_BRANCH:=}
declare=${PROD_GIT_USER:=}
declare=${PROD_GIT_REPO:=}
declare=${TARGET_GIT_USER:=}
declare=${TARGET_GIT_REPO:=}
declare=${TARGET_GIT_URL:=}
declare=${ARTIFACTS_FILE:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${DEPLOY_PROVIDER:=}
declare=${DEPLOY_PROVIDER_ROOT:=}
declare=${SITE_NAME:=}
declare=${LONG_SITE_NAME:=$SITE_NAME}

#
# Declare var for path to THIS file
#
SHARED_SOURCE="${HOME}/${CIRCLE_PROJECT_REPONAME}/shared.sh"

#
# Set default deployment options
#
DEPLOY_CORE_PATH="${DEPLOY_CORE_PATH:=}"
DEPLOY_CONTENT_PATH="${DEPLOY_CONTENT_PATH:=wp-content}"
DEPLOY_PORT="${DEPLOY_PORT:=80}"

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${ARTIFACTS_FILE:="${CIRCLE_ARTIFACTS}/shared-scripts.log"}"

#
# Set an error trap. Uses an $ACTION variable.
#
ACTION=""
announce () {
    ACTION="$1"
    printf "${ACTION}\n"
    printf "${ACTION}\n" >> $ARTIFACTS_FILE
}
onError() {
    if [ $? -ne 0 ] ; then
        printf "FAILED=${ACTION}.\n"
        echo -e "\n"
        echo -e "===========[ BEGIN OUTPUT LOG ]===========\n"
        echo -e "\n"
        cat "${ARTIFACTS_FILE}"
        echo -e "\n"
        echo -e "============[ END OUTPUT LOG ]============\n"
        echo -e "\n"
        exit 1
    fi
}
trap onError ERR

get_provider_specific_script() {
    echo "DEPRECATED: get_provider_specific_script(); use get_provider_script() instead."
    get_provider_script "$1"
}
get_provider_script() {
    echo "${DEPLOY_PROVIDER_ROOT}/${DEPLOY_PROVIDER}-$1"
}
exec_provider_script() {
    do_exec="$(get_provider_script "$1")"
    if [ -f "${do_exec}" ] ; then
        source "${do_exec}"
    fi
}

#
# Making artifact subdirectory
#
announce "...Creating artifact file ${ARTIFACTS_FILE}"
echo . > $ARTIFACTS_FILE

#
# Making artifact subdirectory
#
announce "...Ensure ~/cache directory"
mkdir -p ~/cache

#
# The version of PHP defined in circle.yml/.circleci/config.yml
#
PHP_VERSION="$(phpenv global)"

#
# Define the domain to use for testing
#
TEST_DOMAIN="${LONG_SITE_NAME}.test"
TEST_WEBSERVER=${TEST_WEBSERVER:=apache}
TEST_DBSERVER=${TEST_DBSERVER:=mysql}

#
# And this is for where where content and vendors are on deployment
#
DEPLOY_CONTENT_PATH=${DEPLOY_CONTENT_PATH:=wp-content}
DEPLOY_VENDOR_PATH=${DEPLOY_VENDOR_PATH:=vendor}

#
# The database credentials for WordPress on CircleCI
#
DB_HOST=${DB_HOST:=127.0.0.1}
DB_NAME=${DB_NAME:=wordpress}
DB_USER=${DB_USER:=wordpress}
DB_PASSWORD=${DB_PASSWORD:=wordpress}

#
# The place to store logs
#
LOGS_ROOT="/var/www/logs"

#
# The root of the web server on CircleCI
#
DOCUMENT_ROOT="/var/www/html"

#
# The roots for the various WordPress source on CircleCI server
#
TEST_CONTENT_PATH="wp-content"
TEST_VENDOR_PATH="vendor"

#
# The roots for the various WordPress source on CircleCI server
#
TEST_ROOT="${DOCUMENT_ROOT}"
TEST_CORE="${TEST_ROOT}"
TEST_CONTENT="${TEST_ROOT}/${TEST_CONTENT_PATH}"
TEST_VENDOR="${TEST_ROOT}/${TEST_VENDOR_PATH}"

#
# Composer directory, for autoload files
#
COMPOSER_ROOT="${TEST_VENDOR}/composer"

#
# File-related variables
#
USR_BIN_ROOT="/usr/local/bin"

#
# Apache ServerName and ServerAlias to configure
#
SERVER_NAME="${TEST_DOMAIN}"
SERVER_ALIAS="www.${TEST_DOMAIN}"

#
# Define the Git tag for Build #
#
BUILD_TAG="build-${CIRCLE_BUILD_NUM}"

#
# The root for GitHub repo as cloned by CircleCI
#
SOURCE_ROOT_PATH=${SOURCE_ROOT_PATH:=www}
SOURCE_CONTENT_PATH=${SOURCE_CONTENT_PATH:=content}
SOURCE_CORE_PATH=${SOURCE_CORE_PATH:=wp}
SOURCE_VENDOR_PATH=${SOURCE_VENDOR_PATH:=vendor}

SOURCE_REPO_ROOT="${HOME}/${CIRCLE_PROJECT_REPONAME}"
SOURCE_ROOT="${SOURCE_REPO_ROOT}/www"
SOURCE_CONTENT="${SOURCE_ROOT}/${SOURCE_CONTENT_PATH}"
SOURCE_CORE="${SOURCE_ROOT}/${SOURCE_CORE_PATH}"
SOURCE_VENDOR="${SOURCE_ROOT}/${SOURCE_VENDOR_PATH}"

#
# The roots for all the devops related files and code
#
DEVOPS_ROOT="${SOURCE_REPO_ROOT}/devops"
DEVOPS_CORE_ROOT="${DEVOPS_ROOT}/core"
INCLUDES_ROOT="${DEVOPS_CORE_ROOT}/includes"
FILES_ROOT="${DEVOPS_CORE_ROOT}/files"
HOSTS_ROOT="${DEVOPS_CORE_ROOT}/hosts"
PROVIDERS_ROOT="${DEVOPS_CORE_ROOT}/providers"
SERVERS_ROOT="${DEVOPS_CORE_ROOT}/servers"
DEPLOY_PROVIDER_ROOT="${DEVOPS_CORE_ROOT}/providers/${DEPLOY_PROVIDER}"

#
# Define WP-CLI constants
#
WP_CLI_SOURCE="${FILES_ROOT}/wp-cli-1.3.0.phar"
WP_CLI_FILEPATH="${USR_BIN_ROOT}/wp"

#
# Define .GITIGNORE constants
#
GITIGNORE_SOURCE="${PROVIDERS_ROOT}/${DEPLOY_PROVIDER}/gitignore.txt"
GITIGNORE_FILEPATH="${TEST_ROOT}/.gitignore"

#
# Define .GITIGNORE constants
#
GITIGNORE_SOURCE="${PROVIDERS_ROOT}/${DEPLOY_PROVIDER}/gitignore.txt"
GITIGNORE_FILEPATH="${TEST_ROOT}/.gitignore"

#
# Define a place for DevOps artifacts
#
DEVOPS_ARTIFACTS="${CIRCLE_ARTIFACTS}/devops"

#
# Define the files that are unncessary and will be deleted from deployment
#
# Values in {{CONTENT_PATH}}/mu-plugins/amp-wp/ are symlinks,
# and only needed development.
#
# @todo Deal with wp-config.php in a better way later
#
FILES_TO_DELETE=$(cat <<END
.idea
readme.html
license.txt
composer.json
wp-config.php
wp-config-sample.php
<(content_path)>/plugins/index.php
<(content_path)>/plugins/hello.php
<(content_path)>/themes/twentysixteen
${FILES_TO_DELETE}
END
)

#
# Load set-vars provider script, if applicable
#
announce "...Testing to see if a provider-specific set-vars exists."
SET_VARS_SCRIPT="$(get_provider_script "set-vars.sh")"
if [ -f "${SET_VARS_SCRIPT}" ] ; then
    announce "...Setting vars specific to ${DEPLOY_PROVIDER}"
    source "${SET_VARS_SCRIPT}"
fi

#
# Set the Git user and repo based on the branch
#
announce "...Git branch is ${CIRCLE_BRANCH}"
announce "...Git URL is ${TARGET_GIT_URL}"


