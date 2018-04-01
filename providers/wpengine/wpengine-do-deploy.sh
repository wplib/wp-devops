#!/usr/bin/env bash
#
# devops/core/providers/wpengine/wpengine-do-deploy.sh
#

#
# "Declarations" of the variables this script assumes
#
declare=${TARGET_SITE:=}
declare=${TARGET_GIT_PATH:=}

#
# This should assign "R W production/<branch>" to $GIT_INFO.
#
announce "...Ensuring Git repo ${TARGET_GIT_REPO} exists"
GIT_INFO="$(ssh git@git.wpengine.com info | grep "${TARGET_GIT_PATH}")"

#
# Get just the "production/<branch>" part of $GIT_INFO.
#
AVAILABLE_GIT_PATH="${GIT_INFO:5}"

#
# Check to see if environment exists.
#
# This check checks the extracted value from "ssh git@git.wpengine.com info"
# with the composed value from $CIRCLE_BRANCH
#
# Echo "yes" if exists, "no" if not.
#
[[ "${AVAILABLE_GIT_PATH}" == "${TARGET_GIT_PATH}" ]] && echo "yes" || echo "no"
