#!/usr/bin/env bash
#
# devops/core/includes/deployment.sh
#
# Generic prepare for deployment.
#
#   Assumes code is already committed and on proper branch
#

#
# "Declarations" of the variables this script assumes
#
declare=${DOCUMENT_ROOT:=}
declare=${SHARED_SCRIPTS:=}
declare=${TEST_INDEX:=}
declare=${TARGET_GIT_URL:=}
declare=${CIRCLE_BUILD_NUM:=}
declare=${CIRCLE_PROJECT_REPONAME:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${CIRCLE_BRANCH:=}
declare=${DEPLOY_BRANCH:=}
declare=${PANTHEON_SITE:=}

#
# Load the shared scripts
#
source "${SHARED_SCRIPTS}"

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/deploy.log"

#
# Load the shared scripts
#
DO_DEPLOY_SCRIPT="$(get_provider_specific_script "do-deploy.sh")"
if [ -f "${DO_DEPLOY_SCRIPT}" ] ; then
    announce "Testing to see if environment ${CIRCLE_BRANCH} exists for Pantheon site ${PANTHEON_SITE}."
    if [ "yes" == "$(source "${DO_DEPLOY_SCRIPT}")" ] ; then
        announce "...Yes, deploy ${CIRCLE_BRANCH}.${PANTHEON_SITE}"
    else
        announce "Bypassing deployment for branch ${CIRCLE_BRANCH}"
        exit
    fi
fi

#
# Preparing deployment
#
announce "...Preparing deployment"

#
# Ensure current user can use git w/o sudo
#
# @see: https://help.github.com/articles/error-permission-denied-publickey/
#
announce "...Chowning ${TEST_INDEX}/* to 'ubuntu:ubuntu', recursively"
sudo chown -R ubuntu:ubuntu "${TEST_INDEX}"

#
# Changing directory to document root
#
announce "...Changing to directory ${DOCUMENT_ROOT}"
cd "${DOCUMENT_ROOT}"

#
# Add git remote origin
#
announce "...Adding git remote origin at ${TARGET_GIT_URL}"
git remote add origin "${TARGET_GIT_URL}" 2>&1 >> $ARTIFACTS_FILE

#
# Fetching git remote information
#
announce "...Fetching all git remote info"
git fetch --all --quiet 2>&1 >> $ARTIFACTS_FILE

#
# Checking out branch master
#
announce "...Checking out the branch '${DEPLOY_BRANCH}'"
git checkout -B "${DEPLOY_BRANCH}" --quiet 2>&1 >> $ARTIFACTS_FILE

#
# Set remote tracking information
#
announce "...Setting upstream to origin/${DEPLOY_BRANCH} for the branch '${DEPLOY_BRANCH}'"
git branch --set-upstream-to=origin/$DEPLOY_BRANCH "${DEPLOY_BRANCH}" >> $ARTIFACTS_FILE

#
# Remove .git subdirectories
#
announce "...Removing .git subdirectories not in the test root"
find "${TEST_INDEX}" -mindepth 2 -type d -name ".git" | xargs rm -rf  >> $ARTIFACTS_FILE

#
# Remove .gitignore files
#
announce "...Removing .gitignore files not in the test root"
find "${TEST_INDEX}" -mindepth 2 -name ".gitignore"   | xargs rm -rf >> $ARTIFACTS_FILE

#
# Remove .gitmodules files
#
announce "...Removing .gitmodules files not in the test root"
find "${TEST_INDEX}" -mindepth 2 -name ".gitmodules"  | xargs rm -rf >> $ARTIFACTS_FILE

#
# Adding all newly exposed files to Git stage
#
announce "...Adding all newly exposed files to Git stage"
git add . >> $ARTIFACTS_FILE

#
# Committing files for this build
#
commitMsg="prior to deploy; build #${CIRCLE_BUILD_NUM}"
announce "...Committing ${commitMsg}"
git commit -m "Commit ${commitMsg}" >> $ARTIFACTS_FILE

#
# Pushing to origin
#
announce "...Pushing to origin/${DEPLOY_BRANCH} at ${TARGET_GIT_URL}"
git push -f origin "${DEPLOY_BRANCH}" --quiet  2>&1 >> $ARTIFACTS_FILE

announce "Deployment complete."
