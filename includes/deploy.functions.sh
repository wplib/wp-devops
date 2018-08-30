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
declare="${CI_DEPLOY_REPO_DIR:=}"
declare="${CI_BRANCH:=}"

function deploy_tag() {
    local repo_dir="${CI_DEPLOY_REPO_DIR}"
    local deploy_tag="$(deploy_get_current_tag)"
    git_tag "${repo_dir}" "${deploy_tag}" "Deploy #$(deploy_get_current_num)"
    git_push_tags "${repo_dir}"
    return $(last_error)
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

    output="$(try "Request local deploy lock" \
        "$(git tag -a "${CI_DEPLOY_LOCK_SLUG}" -m "Deploy lock by ${user}" 2>&1)")"
    if [ "${output}" == "fatal: tag 'deploy-lock' already exists" ] ; then
        echo
        echo "Deploy currently locked with '${CI_DEPLOY_LOCK_SLUG}' tag. Cannot deploy."
        echo
        exit 1
    fi

    output="$(try "Push deploy lock to remote" "$(git push --tags 2>&1)")"
    if [[ "${output}" == *"Permission denied"* ]] ; then
        echo
        echo "Permission denied to remote repository. Cannot deploy."
        echo
        exit 2
    elif [[ "${output}" == *"ERROR"* ]] ; then
        echo
        echo "${output} Cannot deploy."
        echo
        exit 3
    fi

    set -e
    pop_dir

    CI_DEPLOY_LOCKED=1
    return $(last_error)
}

function deploy_unlock() {
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
    output="$(try "Git delete local 'deploy-lock' tag" \
        "$(git tag -d ${CI_DEPLOY_LOCK_SLUG} 2>&1)")"
    result=$(catch)
    if ! [[ "${output}" =~ ^Deleted ]]; then
        trace "Result: $result, Output does not contain the word 'deleted'"
        if [ "${output}" != "error: tag '${CI_DEPLOY_LOCK_SLUG}' not found." ]; then
            trace "Output does not contain '${CI_DEPLOY_LOCK_SLUG}'"
            exit 1
        fi
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
    output="$(try "Git delete remote 'deploy-lock' tag" \
        "$(git push origin ":refs/tags/${CI_DEPLOY_LOCK_SLUG}" 2>&1)")"
    catch
    result=$?
    if [ "0" != "${result}" ]; then
        echo
        trace "Result: $result"
        trace "Could not delete remote tag ${CI_DEPLOY_LOCK_SLUG}"
        exit $result
    fi

    pop_dir
    CI_DEPLOY_LOCKED=0
    return 0
}

function deploy_increment() {
    local repo_dir="${CI_PROJECT_DIR}"
    local deploy_dir="${CI_DEPLOY_REPO_DIR}"
    local deploy_num="$(git_get_max_tag_prefix_num 'deploy' "${repo_dir}")"
    local user_name="$(git_get_user)"
    push_dir "${repo_dir}"
    deploy_num="$(( deploy_num + 1 ))"
    filename="$(deploy_get_filename)"
    output=$(try "Writing deploy# ${deploy_num} to: ${filename}" \
        "$(echo "${deploy_num}" > $filename)")
    catch

    git_add "${repo_dir}" "${filename}"
    git_commit "${repo_dir}" "Deploy #${deploy_num} by ${user_name}"
    git_pull "${repo_dir}"
    git_push "${repo_dir}"

    output=$(try "Copying DEPLOY file to: ${deploy_dir}" \
        "$(cp "${filename}" "${deploy_dir}")")
    catch
    pop_dir
    return $(last_error)
}

function deploy_push() {
    local deploy_dir="${CI_DEPLOY_REPO_DIR}"
    local _
    local commit_log=$(try "Generate deploy log from Git"\
        "$(git_generate_log 'deploy' "${deploy_dir}")")
    catch
    _=$(try "Adding all deploy files to Git stage" "$(git_add "${deploy_dir}" '.')")
    catch
    _=$(try "Commit staged files" "$(git_commit "${deploy_dir}" "${commit_log}")")
    catch
    _=$(try "Pull any recent changes" "$(git_pull "${deploy_dir}")")
    catch
    _=$(try "Pull any recent changes" "$(git_push "${deploy_dir}")")

    return $(catch)
}

