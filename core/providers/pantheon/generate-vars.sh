#!/usr/bin/env bash
#
# devops/core/providers/pantheon/generate-vars.sh
#
# Generate Variables for Pantheon

#
# "Declarations" of the variables this script assumes
#
declare=${SHARED_ROOT:=}
declare=${CIRCLE_BRANCH:=}

#
# Preparing deployment
#
announce "Generating Pantheon's vars"

#
# Preparing deployment
#
announce "...Generating Pantheon's vars"

cat << BASH >> $SHARED_ROOT/generated.sh
DEPLOY_WEBSERVER="nginx"
DEPLOY_DBSERVER="mysql"

FIX_MYSQL56_COMPATIBILITY="no"

TARGET_BRANCH="${CIRCLE_BRANCH}"

DEPLOY_METHOD="git-branch"  # vs. "git-repo"
BASH


