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

declare=${TEST_ROOT:=}
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
source includes/shared.sh

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/deploy.log"

#
# Load the shared scripts
#
announce "Testing to see if environment exists for ${CIRCLE_BRANCH} branch for site ${TARGET_SITE}."
if [ "yes" == "$(exec_provider_script "do-deploy.sh")" ] ; then
    announce "...Yes, deploy ${CIRCLE_BRANCH}.${PANTHEON_SITE}"
else
    announce "Bypassing deployment for branch ${CIRCLE_BRANCH}"
    exit
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
announce "...Chowning ${TEST_ROOT}/* to 'ubuntu:ubuntu', recursively"
sudo chown -R ubuntu:ubuntu "${TEST_ROOT}"

#
# Changing directory to document root
#
announce "...Changing to directory ${TEST_ROOT}"
cd "${TEST_ROOT}"

#
# Add git remote origin
#
announce "...Adding git remote origin at ${TARGET_GIT_URL}"
git remote add origin "${TARGET_GIT_URL}" >> $ARTIFACTS_FILE 2>&1

#
# Fetching git remote information
#
announce "...Fetching all git remote info"
git fetch --all --quiet >> $ARTIFACTS_FILE 2>&1

#
# Checking out branch master
#
announce "...Checking out the branch '${DEPLOY_BRANCH}'"
git checkout -B "${DEPLOY_BRANCH}" >> $ARTIFACTS_FILE 2>&1

#
# Set remote tracking information
#
announce "...Setting upstream to origin/${DEPLOY_BRANCH} for the branch '${DEPLOY_BRANCH}'"
git branch --set-upstream-to=origin/$DEPLOY_BRANCH "${DEPLOY_BRANCH}" >> $ARTIFACTS_FILE 2>&1

#
# Remove .git subdirectories
#
announce "...Removing .git subdirectories not in the test root"
find "${TEST_ROOT}" -mindepth 2 -type d -name ".git" | xargs rm -rf  >> $ARTIFACTS_FILE 2>&1

#
# Remove .gitignore files
#
announce "...Removing .gitignore files not in the test root"
find "${TEST_ROOT}" -mindepth 2 -name ".gitignore"   | xargs rm -rf >> $ARTIFACTS_FILE 2>&1

#
# Remove .gitmodules files
#
announce "...Removing .gitmodules files not in the test root"
find "${TEST_ROOT}" -mindepth 2 -name ".gitmodules"  | xargs rm -rf >> $ARTIFACTS_FILE 2>&1

#
# Adding all newly exposed files to Git stage
#
announce "...Adding all newly exposed files to Git stage"
git add . >> $ARTIFACTS_FILE 2>&1

#
# Find previous build number
#
announce "...Finding previous build number"
PREVIOUS_BUILD_NUM="${CIRCLE_PREVIOUS_BUILD_NUM}"
while true; do
    if [ "${PREVIOUS_BUILD_NUM}" == "${CIRCLE_BUILD_NUM}" ]; then
        PREVIOUS_BUILD_TAG=""
        break
    fi
    PREVIOUS_BUILD_TAG="build-${PREVIOUS_BUILD_NUM}"
    if [ "" != "$(cd "${SOURCE_INDEX}" && git tag | grep "${PREVIOUS_BUILD_TAG}")" ]; then
        break
    fi
    PREVIOUS_BUILD_NUM=$((PREVIOUS_BUILD_NUM+1))
done

#
# Generating commit message
#
announce "...Generating commit message"
if [ "" != "${PREVIOUS_BUILD_TAG}" ] ; then
    COMMIT_MSG="$(cd "${SOURCE_INDEX}" && git log "${PREVIOUS_BUILD_TAG}..HEAD" --oneline | cut -d' ' -f2-999)"
else
    COMMIT_MSG="..."
fi
echo "${COMMIT_MSG}" >> $ARTIFACTS_FILE 2>&1

#
# Committing files for this build
#
announce "...Committing build #${CIRCLE_BUILD_NUM}"
git commit -m "Build #${CIRCLE_BUILD_NUM}: ${COMMIT_MSG}" >> $ARTIFACTS_FILE 2>&1

#
# Pushing to origin
#
announce "...Pushing to origin/${DEPLOY_BRANCH} at ${TARGET_GIT_URL}"
git push -f origin "${DEPLOY_BRANCH}" --quiet >> $ARTIFACTS_FILE 2>&1

announce "Deployment complete."
