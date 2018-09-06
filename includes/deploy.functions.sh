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

declare="${CI_PROJECT_DIR:=}"
declare="${CI_LOG:=}"
declare="${CI_DEPLOY_LOCK_SLUG:=}"
declare="${CI_LOCAL_DEPLOY_LOCK_FILE:=}"
declare="${CI_DEPLOY_LOCKED:=}"
declare="${CI_DEPLOY_REPO_DIR:=}"
declare="${CI_NEWLINE:=}"
declare="${CI_BRANCH:=}"

function deploy_tag_remote() {
    local repo_dir="$1"
    local deploy_tag="$(deploy_get_current_tag)"

    local message="dding local '${deploy_tag}' tag"
    local output=$(try "A${message}" "$(git_tag "${repo_dir}" "${deploy_tag}" "Deploy #$(deploy_get_current_num)")")
    catch
    if [[ "${output}" =~ ^fatal ]]; then
        announce "Error a${message}"
        return $(last_error)
    fi

    local message="ushing '${deploy_tag}' tag to remote"
    local output=$(try "P${message}" "$(git_push_tags "${repo_dir}")")
    catch
    if [[ "${output}" =~ ^fatal ]]; then
        announce "Error p${message}"
        return $(last_error)
    fi
    return 0
}

function deploy_get_current_tag() {
    echo "deploy-$(deploy_get_current_num)"
}

function deploy_get_current_num() {
    push_dir "${CI_PROJECT_DIR}"
    cat "$(deploy_get_filename)"
    pop_dir
}

function deploy_get_filename() {
    local dir="$1"
    if [ "" == "${dir}" ] ; then
        dir="${CI_PROJECT_DIR}"
    fi
    echo "${dir}/DEPLOY"
}

function deploy_lock() {
    trace "Lock deploy. Repo dir: ${CI_PROJECT_DIR}"
    local user="$(git_get_user)"
    trace "User: $user"
    push_dir "${CI_PROJECT_DIR}"
    set +e

    local output="$(try "Request local deploy lock" \
        "$(git tag -a "${CI_DEPLOY_LOCK_SLUG}" -m "Deploy lock by ${user}" 2>&1)")"
    if [ "${output}" == "fatal: tag 'deploy-lock' already exists" ] ; then
        announce
        announce "Deploy currently locked with '${CI_DEPLOY_LOCK_SLUG}' tag. Cannot deploy."
        announce
        exit 1
    fi

    output="$(try "Push deploy lock to remote" "$(git push --tags 2>&1)")"
    if [[ "${output}" == *"Permission denied"* ]] ; then
        announce
        announce "Permission denied to remote repository. Cannot deploy."
        announce
        exit 2
    elif [[ "${output}" == *"ERROR"* ]] ; then
        announce
        announce "${output} Cannot deploy."
        announce
        exit 3
    fi

    set -e
    pop_dir

    deploy_lock_locally

    return $(last_error)
}

function deploy_unlock_locally() {
    export CI_DEPLOY_LOCKED=0
    sudo rm -rf $CI_LOCAL_DEPLOY_LOCK_FILE
}

function deploy_lock_locally() {
    export CI_DEPLOY_LOCKED=1
    sudo touch $CI_LOCAL_DEPLOY_LOCK_FILE
}

function deploy_is_locally_locked() {
    if [ 1 -eq $CI_DEPLOY_LOCKED ] ; then
        echo "yes"
    elif [ -f $CI_LOCAL_DEPLOY_LOCK_FILE ] ; then
        echo "yes"
    else
        echo "no"
    fi
}

function deploy_unlock() {
    if [ "yes" == "$(deploy_is_locally_locked)" ] ; then
        announce "Locked locally. Cannot unlock. Repo dir: ${CI_PROJECT_DIR}"
        return 0
    fi
    local _

    trace "Unlock deploy. Repo dir: ${CI_PROJECT_DIR}"
    push_dir "${CI_PROJECT_DIR}"

    #
    # Deleting an non-existence tag generates an error
    # so we have to disable exit on error
    #
    set +e

    #
    # This generates error 1 if tag does not exist
    #
    message="eleting local 'deploy-lock' tag"
    local output=$(try "D${message}" "$(git tag -d ${CI_DEPLOY_LOCK_SLUG} 2>&1)")
    catch
    if [[ "${output}" =~ ^fatal ]]; then
        announce "Error d${message}"
        return $(last_error)
    fi

    #
    # We can exit on error back on again now because Git
    # inconsistently returns 0 if you can't delete a
    # remote tag.
    #
    set -e

    #
    # This does not generate error on non-existent ref
    #
    message="eleting remote 'deploy-lock' tag"
    _="$(try "D${message}" "$(git push origin ":refs/tags/${CI_DEPLOY_LOCK_SLUG}" 2>&1)")"
    if is_error ; then
        announce "Error d${message}"
        return $(last_error)
    fi

    pop_dir
    deploy_unlock_locally
    return 0
}

function deploy_increment() {
    local source_dir="${CI_PROJECT_DIR}"
    local deploy_dir="${CI_DEPLOY_REPO_DIR}"
    local deploy_num="$(git_get_max_tag_prefix_num 'deploy' "${source_dir}")"
    local user_name="$(git_get_user)"
    push_dir "${source_dir}"
    deploy_num="$(( deploy_num + 1 ))"
    local filename="$(deploy_get_filename)"

    local message="riting deploy# ${deploy_num} to: ${filename}"
    local _=$(try "W${message}" "$(echo "${deploy_num}" > $filename)")
    if is_error ; then
        announce "Error w${message}"
        return $(last_error)
    fi 

    message="dding file(s) '${filename}' to ${source_dir}"
    _=$(try "A${message}" "$(git_add "${source_dir}" "${filename}")")
    if is_error ; then
        announce "Error a${message}"
        return $(last_error)
    fi

    message="ommitting DEPLOY file containing #${deploy_num}"
    _=$(try "C${message}" "$(git_commit "${source_dir}" "C${message} [skip ci]")")
    if is_error ; then
        announce "Error c${message}"
        return $(last_error)
    fi

    message="ulling branch ${CI_BRANCH} from ${source_dir}"
    _=$(try "P${message}" "$(git_pull "${CI_BRANCH}" "${source_dir}")")
    if is_error ; then
        announce "Error p${message}"
        return $(last_error)
    fi

    message="ushing branch ${CI_BRANCH} to ${source_dir}"
    _=$(try "P${message}" "$(git_push "${CI_BRANCH}" "${source_dir}")")
    if is_error ; then
        announce "Error p${message}"
        return $(last_error)
    fi

    message="opying DEPLOY file to: ${deploy_dir}"
    _=$(try "C${message}" "$(cp "${filename}" "${deploy_dir}")")
    if is_error ; then
        announce "Error c${message}"
        return $(last_error)
    fi 

    pop_dir

    #
    # Deploy locking is about deploy number.
    # We've just committed the deploy number
    # so we can unlock.
    #
    deploy_unlock_locally

    return 0
}

function deploy_push() {
    local deploy_dir="${CI_DEPLOY_REPO_DIR}"
    trace "Deploy dir: ${deploy_dir}"
    local build_num="$(build_get_current_num)"
    trace "Build#: ${build_num}"
    local output

    local message="enerating deploy log from Git"
    local commit_msg="$(try "G${message}" "$(build_generate_log "${CI_PROJECT_DIR}")")"
    if is_error ; then
        announce "Error g${message}"
        return $(last_error)
    fi
    trace "Commit log generated: ${commit_msg}"

    message="dding all deploy files to Git stage"
    output=$(try "A${message}" "$(git_add "${deploy_dir}" '.')")
    if is_error ; then
        announce "Error a${message}: $output"
        return $(last_error)
    fi

    message="ommitting staged files in ${deploy_dir}"
    output=$(try "C${message}" "$(git_commit "${deploy_dir}" "${commit_msg}")")
    if is_error ; then
        announce "Error c${message}: $output"
        return $(last_error)
    fi

    message="ulling recent changes for branch ${CI_BRANCH} to ${deploy_dir}"
    output=$(try "P${message}" "$(git_pull "${CI_BRANCH}" "${deploy_dir}")")
    if is_error ; then
        announce "Error p${message}: $output"
        return $(last_error)
    fi

    message="ushing commits for branch ${CI_BRANCH} to ${deploy_dir}"
    output=$(try "P${message}" "$(git_push "${CI_BRANCH}" "${deploy_dir}")")
    if is_error ; then
        announce "Error p${message}: $output"
        return $(last_error)
    fi
    return 0
}

