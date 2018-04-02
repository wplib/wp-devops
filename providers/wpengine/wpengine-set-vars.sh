#!/usr/bin/env bash
#
# devops/core/providers/wpengine/wpengine-set-vars.sh
#
# Set Variables for WPEngine
#

#
# "Declarations" of the variables this script assumes
#
declare=${CIRCLE_BRANCH:=}

#
# Preparing deployment
#
announce "Setting WPEngine's vars"

DEPLOY_WEBSERVER="apache"
DEPLOY_DBSERVER="mysql"
DEPLOY_METHOD="site-per-repo"

#
# If the test server is MySQL version >= 5.7 and the
# sql/provision.sql is <= 5.6 this needs to be "yes"
# We had this with WPEngine (5.6) and CircleCI (5.7)
#
FIX_MYSQL56_COMPATIBILITY="yes"
DEPLOY_BRANCH="master"

DEPLOY_CORE_PATH:     ""
DEPLOY_CONTENT_PATH:  "wp-content"
DEPLOY_PORT:          ""

#
# Define the production user and repo for cloning
#
TARGET_SITE:      "${CIRCLE_BRANCH}"
TARGET_GIT_USER:  "git"
TARGET_GIT_PORT:  ""
TARGET_GIT_PATH:  "production${TARGET_GIT_PORT}/${TARGET_SITE}"
TARGET_GIT_REPO:  "git.wpengine.com:${TARGET_GIT_PATH}.git"
TARGET_GIT_URL:   "${TARGET_GIT_USER}@${TARGET_GIT_REPO}"

#
# Define the files that are unncessary and will be deleted from deployment
#
#   WPEngine does not include these files in their repo.
#
define FILES_TO_DELETE <<'EOF'
wp-activate.php
wp-blog-header.php
wp-comments-post.php
wp-cron.php
wp-links-opml.php
wp-load.php
wp-login.php
wp-mail.php
wp-settings.php
wp-signup.php
wp-trackback.php
xmlrpc.php
{{content_path}}/index.php
{{content_path}}/advanced-cache.php
{{content_path}}/uploads
$FILES_TO_DELETE
EOF
