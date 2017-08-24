#!/usr/bin/env bash
#
# devops/core/providers/wpengine/generate-vars.sh
#
# Generate Variables for WPEngine

#
# "Declarations" of the variables this script assumes
#
declare=${SHARED_ROOT:=}

#
# Preparing deployment
#
announce "Generating WPEngine's vars"

#
# Preparing deployment
#
announce "...Generating WPEngine's vars"

cat << BASH >> $SHARED_ROOT/generated.sh
DEPLOY_WEBSERVER="apache"
DEPLOY_DBSERVER="mysql"

FIX_MYSQL56_COMPATIBILITY="yes"

TARGET_BRANCH="master"

DEPLOY_METHOD="git-repo"
BASH


