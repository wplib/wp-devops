#!/usr/bin/env bash
#
# devops/core/providers/pantheon/pantheon-do-deploy.sh
#

#
# "Declarations" of the variables this script assumes
#
declare=${CIRCLE_BRANCH:=}
declare=${PANTHEON_SITE:=}

#
# Check to see if environment exists.
# Echo "yes" is so, "no" if not.
#
ENVIRONMENT_INFO="$(terminus env:list wabe | grep "${CIRCLE_BRANCH}.${PANTHEON_SITE}.pantheon")"
[[ "" = "${ENVIRONMENT_INFO}" ]] && echo "no" || echo "yes"
