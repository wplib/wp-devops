#!/usr/bin/env bash
#
#    Copyright 2018 NewClarity Consulting, LLC
#
#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at
#
#        http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.
#

declare="${CI_LOG:=}"
declare="${CI_BRANCH:=}"
declare="${CI_DEPLOY_REPO_DIR:=}"
declare="${CI_PROJECT_DIR:=}"
declare="${CI_SOURCED_FILE:=}"

source "${CI_SOURCED_FILE}"

announce "Setting the Git user"
git_set_user
if is_error ; then
    announce "$(last_output)"
    exit 1
fi

#announce "Locking the deploy"
#deploy_lock
#if is_error ; then
#    announce "$(last_output)"
#    exit 2
#fi

announce "Disabling SSH StrictHostKeyChecking"
git_disable_strict
if is_error ; then
    announce "$(last_output)"
    exit 3
fi

announce "Setting up Composer"
composer_setup
if is_error ; then
    announce "$(last_output)"
    exit 4
fi

announce "Checking out branch '${CI_BRANCH}'"
git_checkout_branch "${CI_BRANCH}" "${CI_PROJECT_DIR}"
if is_error ; then
    announce "$(last_output)"
    exit 5
fi

announce "Resetting branch '${CI_BRANCH}' hard"
git_reset_branch_hard "${CI_BRANCH}" "${CI_PROJECT_DIR}"
if is_error ; then
    announce "$(last_output)"
    exit 6
fi

announce "Deleting untracked files"
git_delete_untracked_files "${CI_PROJECT_DIR}"
if is_error ; then
    announce "$(last_output)"
    exit 7
fi

announce "Running 'composer install'"
composer_run "${CI_PROJECT_DIR}"
if is_error ; then
    announce "$(last_output)"
    exit 8
fi

announce "Cloning deploy repo"
build_clone_repo
if is_error ; then
    announce "$(last_output)"
    exit 9
fi

announce "Processing files"
build_process_files
if is_error ; then
    announce "$(last_output)"
    exit 10
fi

announce "Removing 'delete' files"
build_delete_files "${CI_DEPLOY_REPO_DIR}"
if is_error ; then
    announce "$(last_output)"
    exit 11
fi

#announce "Incrementing deploy"
#deploy_increment
#if is_error ; then
#    announce "$(last_output)"
#    exit 12
#fi

announce "Generating BUILD file"
build_generate_file
if is_error ; then
    announce "$(last_output)"
    exit 12
fi

announce "Pushing deploy to host"
deploy_push
if is_error ; then
    announce "$(last_output)"
    exit 13
fi

announce "Tagging build"
build_tag_remote "${CI_PROJECT_DIR}"
if is_error ; then
    announce "$(last_output)"
    exit 14
fi

build_tag_remote "${CI_DEPLOY_REPO_DIR}"
if is_error ; then
    announce "$(last_output)"
    exit 15
fi

announce "Deploy tagged as $(deploy_get_current_tag)"

announce "Unlocking the deploy"
deploy_unlock
if is_error ; then
    announce "$(last_output)"
    exit 16
fi

