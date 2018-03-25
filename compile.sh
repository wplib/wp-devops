#!/usr/bin/env bash
#
# devops/core/compile.sh
#
#   Restructure from the GitHub repo to a form that webhost wants.
#
#   At the end of this script we should have a complete testable site
#   running in /var/www/html/blog and it should have all code committed
#   to its git repository.
#

#
# "Declarations" of the variables this script assumes
#
declare=${SHARED_SCRIPTS:=}
declare=${REPO_ROOT:=}
declare=${SOURCE_ROOT:=}
declare=${SOURCE_INDEX:=}
declare=${SOURCE_CONTENT:=}
declare=${SOURCE_CORE:=}
declare=${DOCUMENT_ROOT:=}
declare=${TEST_INDEX:=}
declare=${TEST_CORE:=}
declare=${TEST_CONTENT:=}
declare=${TARGET_GIT_URL:=}
declare=${HOSTS_ROOT:=}
declare=${CIRCLE_BRANCH:=}
declare=${CIRCLE_BUILD_NUM:=}
declare=${CIRCLE_PROJECT_REPONAME:=}
declare=${GIT_USER_EMAIL:=}
declare=${CIRCLE_USERNAME:=}
declare=${CIRCLE_ARTIFACTS:=}
declare=${GITIGNORE_SOURCE:=}
declare=${GITIGNORE_FILEPATH:=}
declare=${UNNECESSARY_FILES:=}
declare=${DEPLOY_CORE_PATH:=}
declare=${DEPLOY_CONTENT_PATH:=}
declare=${DEPLOY_PORT:=}
declare=${DEPLOY_PROVIDER:=}
declare=${PROVIDERS_ROOT:=}
declare=${DEVOPS_ROOT:=}
declare=${SOURCE_VENDOR:=}
declare=${TEST_VENDOR:=}
declare=${COMPOSER_ROOT:=}
declare=${SOURCE_CONTENT_PATH:=}
declare=${TEST_CONTENT_PATH:=}
declare=${SOURCE_VENDOR_PATH:=}
declare=${DEPLOY_VENDOR_PATH:=}

#
# Set artifacts file for this script
#
ARTIFACTS_FILE="${CIRCLE_ARTIFACTS}/compile.log"

#
# Load the shared scripts
#
source "${SHARED_SCRIPTS}"

#
# "Compiling" general process
#
announce "Compiling deployable website into directory ${TEST_INDEX}"

#
# Get the .git directory from the source root
#
# So we don't overwrite the deploy repo.
#
announce "...Removing ${SOURCE_INDEX}/.git"
sudo rm -rf "${SOURCE_INDEX}/.git"

#
# Get the .git directory from the source core
#
# So we don't overwrite the deploy repo.
#
announce "...Removing ${SOURCE_CORE}/.git"
sudo rm -rf "${SOURCE_CORE}/.git"

#
# Get the .gitignore file from the source root
#
# So when we don't overwrite the deploy .gitignore.
#
announce "...Removing ${SOURCE_INDEX}/.gitignore"
sudo rm -rf "${SOURCE_INDEX}/.gitignore"

#
# Get the .gitignore file from the source core
#
# So when we don't overwrite the deploy .gitignore.
#
announce "...Removing ${SOURCE_CORE}/.gitignore"
sudo rm -rf "${SOURCE_CORE}/.gitignore"

#
# Get rid of the root file
#
announce "...Removing ${DOCUMENT_ROOT}/index.html"
sudo rm -f "${DOCUMENT_ROOT}/index.html"

#
# Get rid of the root file, if exists
#
announce "...Removing ${TEST_INDEX}"
sudo rm -rf "${TEST_INDEX}"

#
# Create a temp directory to clone into
#
announce "...Creating temp directory to clone ${TARGET_SITE}@${DEPLOY_PROVIDER} into"
cloneDir="$(mktemp -d /tmp/gitclone-XXXX)"

#
# Clone deployment Git repo into the temp directory
#
announce "...Cloning ${TARGET_SITE}@${DEPLOY_PROVIDER} into ${cloneDir}"
git clone --quiet "${TARGET_GIT_URL}" "${cloneDir}" >> $ARTIFACTS_FILE 2>&1

#
# Move the deployment repo into /var/www/html
#
announce "...Moving ${cloneDir} into ${TEST_INDEX}"
sudo mv "${cloneDir}" "${TEST_INDEX}"

#
# Changing directory to test root
#
announce "...Changing to directory ${TEST_INDEX}"
cd "${TEST_INDEX}"

#
# Remove any files all files from the Git index
#
announce "...Removing all files from the deployment Git index"
sudo git rm -r -f  --ignore-unmatch . >> $ARTIFACTS_FILE 2>&1

#
# Adding a BUILD file containing CIRCLE_BUILD_NUM
#
announce "...Adding a BUILD file containing build# ${CIRCLE_BUILD_NUM}"
echo "${CIRCLE_BUILD_NUM}" > ${TEST_INDEX}/BUILD

#
# Checking out current branch
#
announce "...Checking out ${CIRCLE_BRANCH}"
cd "${SOURCE_INDEX}"
git checkout --quiet ${CIRCLE_BRANCH} >> $ARTIFACTS_FILE 2>&1

#
# Now make other directories expected by WordPress
#
announce "...Making directory ${TEST_CORE}"
sudo mkdir -p "${TEST_CORE}"
announce "...Making directory ${TEST_CONTENT}"
sudo mkdir -p "${TEST_CONTENT}"

#
# Copy content from repo and plugins from Composer to test content dir.
#
# @see https://stackoverflow.com/a/9046793/102699 for reason to `cd "${SOURCE_CONTENT}"`
#
announce "...Rsyncing files in ${SOURCE_CONTENT}/ to ${TEST_CONTENT}"
cd "${SOURCE_CONTENT}"
sudo rsync -a . "${TEST_CONTENT}"

#
# Copy WordPress installed by Composer to test core dir.
#
announce "...Rsyncing files in ${SOURCE_CORE} to ${TEST_CORE}"
cd "${SOURCE_CORE}"
sudo rsync -a . "${TEST_CORE}"

#
# Copy vendor files installed by Composer to test vendor dir.
#
announce "...Rsyncing files in ${SOURCE_VENDOR} to ${TEST_VENDOR}"
cd "${SOURCE_VENDOR}"
sudo rsync -a . "${TEST_VENDOR}"


if [ "${SOURCE_CONTENT_PATH}" != "${DEPLOY_CONTENT_PATH}" ] ; then

    #
    # Appending a change directory to test root to .bash_profile
    #
    announce "...Fixing up Composer Autoloader files"
    for filepath in ${COMPOSER_ROOT}/*.php; do
        announce "......Fixing up ${filepath}"
        find="'${SOURCE_CONTENT_PATH}"
        replace="'${DEPLOY_CONTENT_PATH}"
        sed -i  "s#${find}#${replace}#g" "${filepath}"
        find="'/${SOURCE_CONTENT_PATH}"
        replace="'/${DEPLOY_CONTENT_PATH}"
        sed -i "s#${find}#${replace}#g" "${filepath}"
        find="'${SOURCE_VENDOR_PATH}"
        replace="'${DEPLOY_VENDOR_PATH}"
        sed -i  "s#${find}#${replace}#g" "${filepath}"
        find="'/${SOURCE_VENDOR_PATH}"
        replace="'/${DEPLOY_VENDOR_PATH}"
        sed -i "s#${find}#${replace}#g" "${filepath}"
    done

fi

#
# Copy *just* the files in www/blog/ and not subdirectories
# See: https://askubuntu.com/a/632102/486620
#
announce "...Rsyncing files in ${SOURCE_INDEX}/ to ${TEST_CORE}"
cd "${SOURCE_INDEX}"
sudo rsync -a -f"- */" -f"+ *" . "${TEST_CORE}"

#
# We probably WP core in a subdirectory.
# If we have a core path for deployment, we need a slash
# If we had a core path in local, remove it then if there is a core path for deploy, add it
#
announce "...Modifying ${SOURCE_ROOT}/index.php to include core path ${DEPLOY_CORE_PATH}"
SLASH="$([ ! -z "${DEPLOY_CORE_PATH}" ] && echo "/" || echo "")"
sudo sed -i -e "s|'.*/wp-blog-header|'${SLASH}${DEPLOY_CORE_PATH}/wp-blog-header|" "${DOCUMENT_ROOT}/index.php"

#
# Removing unnecessary test root files: license.txt and readme.html
#
for file in $UNNECESSARY_FILES; do
    [ '---' == "${file}" ] && continue
    announce "...Removing ${file}"
    sudo rm -rf "${file}"
done

#
# Copy the project's wp-config.php file
#
SOURCE_CONFIG="${DEVOPS_ROOT}/wp-config.php"

if ! [ -f "${SOURCE_CONFIG}" ] ; then
    #
    # Copy the providers's wp-config.php file
    #
    SOURCE_CONFIG="${PROVIDERS_ROOT}/${DEPLOY_PROVIDER}/wp-config.php"
fi

if [ -f "${SOURCE_CONFIG}" ] ; then
    CONFIG_FILEPATH="${TEST_INDEX}/wp-config.php"
    announce "...Copying ${SOURCE_CONFIG} to ${CONFIG_FILEPATH}"
    sudo cp "${SOURCE_CONFIG}" "${CONFIG_FILEPATH}"
fi

#
# Seems chattr does not work with symlinks exist in the path. Ugh!
# PHPUnit uses a symlink, so going to delete it and then restore it.
#
# @todo need to find a way to do this for any symlink in /var/www/html
#
announce "...Searching for PHPUnit"
PHPUNIT_EXEC_FILE="$(find "${DOCUMENT_ROOT}" | grep "/bin/phpunit" || true)"
if [ "" != "${PHPUNIT_EXEC_FILE}" ]; then
    announce "...PHPUnit found: ${PHPUNIT_EXEC_FILE}"
    PHPUNIT_DIR="${PHPUNIT_EXEC_FILE%%/bin/phpunit}/phpunit"

    announce "...Temporarily deleting symlink to PHPUnit"
    sudo rm "${PHPUNIT_EXEC_FILE}"
fi

#
# Removing immutable flag from files and directories
# See: https://askubuntu.com/a/675307/486620
#
announce "...Removing immutable flag from ${DOCUMENT_ROOT}"
sudo chattr -R -i "${DOCUMENT_ROOT}"

if [ "" != "${PHPUNIT_EXEC_FILE}" ]; then
    #
    # Now we need to set the symlink for PHPUnit back...
    #
    announce "...Restoring symlink for: ${PHPUNIT_EXEC_FILE}"
    sudo ln -sf "${PHPUNIT_DIR}/phpunit/phpunit" "${PHPUNIT_EXEC_FILE}"
fi

#
# Ensure document root has the right ownership for Apache
#
announce "...Chowning ${DOCUMENT_ROOT} to 'www-data:www-data'"
sudo chown -R www-data:www-data "${DOCUMENT_ROOT}"

#
# Setting directory permissions to 755
#
announce "...Setting directory permissions in ${DOCUMENT_ROOT} to 755"
sudo find "${DOCUMENT_ROOT}" -type d -exec chmod 755 {} \;

#
# Setting file permissions to 644
#
announce "...Setting file permissions in ${DOCUMENT_ROOT} to 644"
sudo find "${DOCUMENT_ROOT}" -type f -exec chmod 644 {} \;

#
# Changing directory to test root
#
announce "...Changing to directory ${TEST_INDEX}"
cd "${TEST_INDEX}"

#
# Downloading .gitignore
#
announce "...Copying ${GITIGNORE_SOURCE} to ${GITIGNORE_FILEPATH}"
sudo cp "${GITIGNORE_SOURCE}" "${GITIGNORE_FILEPATH}"

#
# Remove .git sub-subdirectories from the test website
#
announce "...Removing .git subdirectories not in the test index"
find "${TEST_INDEX}" -mindepth 2 -type d -name ".git" | sudo xargs rm -rf  >> $ARTIFACTS_FILE 2>&1

#
# Adding all files to Git stage
#
announce "...Staging all files except files excluded by .gitignore"
sudo git add .  >> $ARTIFACTS_FILE 2>&1

#
# Running a file list for debugging
#
announce "...Running a file list for debugging"
find "${TEST_INDEX}"  >> $ARTIFACTS_FILE 2>&1

#
# Committing files for this build
#
commitMsg="during build; build #${CIRCLE_BUILD_NUM}"
announce "...Committing ${commitMsg}"
sudo git commit -m "Commit ${commitMsg}" >> $ARTIFACTS_FILE 2>&1

#
# Removing git remotes
#
remotes="$(git remote)"
for remote in $remotes ; do
    announce "...Removing git remote ${remote}"
    sudo git remote remove "${remote}"
    done

#
# Appending a change directory to test root to .bash_profile
#
announce "...Adding 'cd ${TEST_INDEX}' to ~/.bash_profile"
sudo sed -i '$ a cd "${TEST_INDEX}"' ~/.bash_profile

#
# Announce completion
#
announce "Site build complete."
