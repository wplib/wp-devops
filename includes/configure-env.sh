#!/usr/bin/env bash
#
# devops/core/includes/configure-env.sh
#
#   Make changes to the Linux environment
#

#
# "Declarations" of the variables this script assumes
#

declare=${CIRCLE_ARTIFACTS:=}
declare=${GIT_USER_EMAIL:=}
declare=${CIRCLE_USERNAME:=}
declare=${CIRCLE_BRANCH:=}
declare=${DEVOPS_ROOT:=}
declare=${DEVOPS_ARTIFACTS:=}

#
# Configure environment
#
#
# Ensure all devops scripts are executable
#
announce "......Ensure all devops scripts in ${DEVOPS_ROOT} are executable"
find "${DEVOPS_ROOT}" | grep "\.sh$" | xargs chmod +x

#
# Copying devops/core into artifacts
#
announce "......Copying devops into artifacts"
mkdir -p "${DEVOPS_ARTIFACTS}"
cp -R "${DEVOPS_ROOT}/." "${DEVOPS_ARTIFACTS}"

#
# Disabling this annoying SSH warning:
#
#       "Warning: Permanently added to the list of known hosts"
#
# @see https://stackoverflow.com/a/19733924/102699
#
announce "......Disabling annoying SSH warnings"
sudo sed -i '1s/^/LogLevel ERROR\n\n/' ~/.ssh/config

#
# Grab user name and email from `git log -1`
#
announce "......Grabbing the author of the latest Disabling annoying SSH warnings"
GIT_USER_NAME="$(git log -1 --format=format:"%an")"
announce "......Author name:  ${GIT_USER_NAME}"
GIT_USER_EMAIL="$(git log -1 --format=format:"%ae")"
announce "...Author email: ${GIT_USER_EMAIL}"

#
# Setting git user.email
#
announce "......Setting global Git user.name to ${GIT_USER_NAME}"
git config --global user.name "${GIT_USER_NAME}"

#
# Setting git user.email
#
announce "......Setting global Git user.email to ${GIT_USER_EMAIL}"
git config --global user.email "${GIT_USER_EMAIL}"

#
# Set merge rename limit to a large number
#
# @see https://stackoverflow.com/a/4722641/102699
#
announce "......Disable merge.renamelimit to a large number (999999)"
git config merge.renameLimit 999999
