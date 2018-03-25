#!/usr/bin/env bash
#
# devops/core/includes/compose.sh
#
#   Prepare composer.json for a build and then run `composer install`
#

#
# "Declarations" of the variables this script assumes
#
declare=${REPO_ROOT:=}
declare=${ARTIFACTS_FILE:=}
declare=${DEVOPS_ROOT:=}

announce "Composing project"

#
# We need to get rid of files that are ignored by .gitignore
#
announce "...Get rid of files that are ignored by .gitignore"
cd ${REPO_ROOT} >> $ARTIFACTS_FILE 2>&1
rm .gitignore.bak >> $ARTIFACTS_FILE 2>&1
mv .gitignore .gitignore.bak >> $ARTIFACTS_FILE 2>&1
GITIGNORED_FILES="$(git status | grep "www/" | sed -e 's/^[[:space:]]*//')"
for file in $GITIGNORED_FILES; do
    announce "......Deleting ${file}"
    rm -rf "${file}" >> $ARTIFACTS_FILE 2>&1
done
mv .gitignore.bak .gitignore >> $ARTIFACTS_FILE 2>&1

#
# Running Composer to install plugins and extra themes
#
announce "...Running Composer in ${REPO_ROOT} to install plugins and extra themes."
composer install \
    --working-dir="${REPO_ROOT}" \
    --classmap-authoritative \
    --no-interaction \
    --prefer-dist \
    --no-progress \
    --no-suggest \
    --ansi \
    >> $ARTIFACTS_FILE 2>&1

#
# Ensure all devops scripts are executable
#
announce "...Again, ensure all scripts in ${DEVOPS_ROOT} are executable"
find "${DEVOPS_ROOT}" | grep "\.sh$" | xargs chmod +x


announce "Project composed"
