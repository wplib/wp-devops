#!/usr/bin/env bash
#
# devops/core/providers/pantheon/pantheon-set-vars.sh
#
# Set Variables for Pantheon
#

#
# "Declarations" of the variables this script assumes
#
declare=${CIRCLE_BRANCH:=}

#
# Preparing deployment
#
announce "Setting Pantheon's vars"

DEPLOY_WEBSERVER="nginx"
DEPLOY_DBSERVER="mysql"
DEPLOY_METHOD="git-branch"

#
# If the test server is MySQL version >= 5.7 and the
# sql/provision.sql is <= 5.6 this needs to be "yes"
# We had this with WPEngine (5.6) and CircleCI (5.7)
#
FIX_MYSQL56_COMPATIBILITY="no"
DEPLOY_BRANCH="${CIRCLE_BRANCH}"

DEPLOY_CORE_PATH:     ""
DEPLOY_CONTENT_PATH:  "wp-content"
DEPLOY_PORT:          ""

