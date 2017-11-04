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
# For Pantheon, `master` branch maps to `dev` environment.
#
if [ "master" == "${CIRCLE_BRANCH}" ] ; then
    PANTHEON_ENVIRONMENT="dev"
else
    PANTHEON_ENVIRONMENT="${CIRCLE_BRANCH}"
fi

#
# Check to see if environment exists.
# Echo "yes" is so, "no" if not.
#
ENVIRONMENT_INFO="$(terminus env:list ${PANTHEON_SITE} --field=domain | grep "${PANTHEON_ENVIRONMENT}-${PANTHEON_SITE}.pantheon")"
[[ "" = "${ENVIRONMENT_INFO}" ]] && echo "no" || echo "yes"
