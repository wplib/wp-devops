#!/usr/bin/env bash
#
# devops/core/includes/configure-env.sh
#
#   Make changes to the Linux environment
#

#
# "Declarations" of the variables this script assumes
#
declare=${SHARED_SCRIPTS:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${GIT_USER_EMAIL:=}
declare=${CIRCLE_USERNAME:=}
declare=${CIRCLE_BRANCH:=}
declare=${WORKFLOW_ROOT:=}

#
# Configure environment
#
announce "Configuring environment"

#
# Ensure all devops scripts are executable
#
announce "...Ensure all scripts in ${WORKFLOW_ROOT} are executable"
find "${WORKFLOW_ROOT}" | grep "\.sh$" | xargs chmod +x

#
# Disabling this annoying SSH warning:
#
#       "Warning: Permanently added to the list of known hosts"
#
# @see https://stackoverflow.com/a/19733924/102699
#
announce "...Disabling annoying SSH warnings"
sudo sed -i '1s/^/LogLevel ERROR\n\n/' ~/.ssh/config

#
# Setting git user.email
#
announce "...Setting global Git user.email to ${GIT_USER_EMAIL}"
git config --global user.email "${GIT_USER_EMAIL}"

#
# Setting git user.email
#
announce "...Setting global Git user.name to ${CIRCLE_USERNAME}"
git config --global user.name "${CIRCLE_USERNAME}"

#
# Set merge rename limit to a large number
#
# @see https://stackoverflow.com/a/4722641/102699
#
announce "...Disable merge.renamelimit to a large number (999999)"
git config merge.renameLimit 999999

announce "Envionment configuration complete"
