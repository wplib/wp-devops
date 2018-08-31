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

#
# Produces no output
#
function git_set_user() {
    local _
    export GIT_USER_NAME="$(try  "Get git commit name" \
        "$(git log -1 --format=format:"%an")" 2>&1)"
    export GIT_USER_EMAIL="$(try "Get git commit email" \
        "$(git log -1 --format=format:"%ae")" 2>&1)"
    _=$(try "Set git user.name: ${GIT_USER_NAME}" \
        "$(git config --global --replace-all user.name  "${GIT_USER_NAME}")" 2>&1)
    _=$(try "Set git user.email: ${GIT_USER_EMAIL}" \
        "$(git config --global --replace-all user.email "${GIT_USER_EMAIL}")" 2>&1)
}

#
# Outputs current branch like `master`
#
function git_get_current_branch() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    echo "$(try "Get current git branch" "$(git branch | grep '*' | awk '{print $2}')")"
    catch
    pop_dir
    return $(last_error)
}

#
# Outputs username like `Mike Schinkel <mike@newclarity.net>`
#
function git_get_user() {
    try "Get git user" "$(echo "${GIT_USER_NAME} <${GIT_USER_EMAIL}>")"
    return $(catch)
}

#
# Produces no output
#
function git_checkout_branch() {
    local branch="$1"
    local repo_dir="$2"
    push_dir "${repo_dir}"
    local output
    if ! git_branch_exists "${branch}" "${repo_dir}" ; then
        output="$(try "Checking out new branch '${branch}'" \
            "$(git checkout -b "${branch}" "origin/${branch}" 2>&1)")"
    elif [ "${branch}" != "$(git_get_current_branch)" ]; then
        output="$(try "Checking out existing branch '${branch}'" \
            "$(git checkout "${branch}" 2>&1)")"
    fi
    catch
    exit_if_contains "${output}" "fatal"
    pop_dir
}

function git_pull_branch() {
    local branch="$1"
    local repo_dir="$2"
    push_dir "${repo_dir}"
    local output=$(try "Pull ${branch} from origin" \
            "$(git pull origin "${branch}" 2>&1)")
    catch
    exit_if_contains "${output}" "fatal"
    pop_dir
}

function git_fetch_all() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    local output=$(try "Fetching all" \
            "$(git fetch --all 2>&1)")
    catch
    exit_if_contains "${output}" "fatal"
    pop_dir
}

function git_reset_branch_hard() {
    local branch="$1"
    local repo_dir="$2"
    push_dir "${repo_dir}"
    trace "Git repo dir provided: ${repo_dir}"
    trace "Git reset branch hard for directory: $(pwd)"
    if [ "$(pwd)" == "/projects/wplib.box/.circleci" ] ; then
        dump_stack "VERY BAD HAPPENING!!!"
    fi

    local output=$(try "Resetting ${branch} to state of origin" \
            "$(git reset --hard "origin/${branch}" 2>&1)")
    catch
    exit_if_contains "${output}" "fatal"
    pop_dir
}

function git_delete_untracked_files() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    local output=$(try "Delete all untracked files and directories" \
            "$(git clean -d --force 2>&1)")
    catch
    exit_if_contains "${output}" "fatal"
    pop_dir
}

function git_clone_repo() {
    local repo_url="$1"
    local clone_dir="$2"
    local parent_dir="$(dirname "${clone_dir}")"
    local repo_name="$(basename "${clone_dir}")"
    push_dir "${parent_dir}"
    set +e
    output=$(try "Cloning ${repo_url} to ${repo_name}" \
        "$(git clone "${repo_url}" "${repo_name}" 2>&1)")
    catch
    set -e
    pop_dir
    exit_if_contains "${output}" "fatal"
}

function git_disable_strict() {
    #
    # See https://stackoverflow.com/a/38474400/102699
    #
    local _=$(try "Disabling SSH StrictHostKeyChecking" \
        "$(git config --global core.sshCommand 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no')")
    return $(catch)
}

function git_add() {
    local repo_dir="$1"
    local filename="$2"
    push_dir "${repo_dir}"
    local _=$(try "Git add for file(s): '${filename}'" "$(git add "${filename}" 2>&1)")
    catch
    pop_dir
    return $(last_error)
}

function git_commit() {
    local repo_dir="$1"
    local message="$2"
    trace "Committing to ${repo_dir}: ${message}"
    push_dir "${repo_dir}"
    local output=$(try "Git commit for: '${message}'" "$(git commit -m "${message}" 2>&1)")
    catch
    echo "${output}"
    pop_dir
    return $(last_error)
}

function git_pull() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    local _=$(try "Git pull" "$(git pull 2>&1)")
    catch
    pop_dir
    return $(last_error)
}

function git_push() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    local _=$(try "Git push" "$(git push 2>&1)")
    catch
    pop_dir
    return $(last_error)
}

function git_generate_log() {
    local prefix="$1"
    local repo_dir="$2"
    local deploy_num="$(git_get_max_tag_prefix_num "${prefix}" "${repo_dir}")"
    local tag="${prefix}-${deploy_num}"
    local hash="$(git_get_commit_hash "${tag}" "${repo_dir}")"
    local log="$(git_hash_log "${hash}" "${repo_dir}")"
    catch
    echo "${log}"
    return $(last_error)
}

#
# Sorting by length, then by value: https://stackoverflow.com/a/5917762/102699
#
function git_get_max_tag_prefix_num() {
    local prefix="$1"
    local repo_dir="$2"
    local num_no="$(default "$3" 1)"
    local remote_tags=$(try "Get sorted remote Git tags for '${prefix}'" \
        "$(git_get_sorted_remote_tags "${prefix}" "${repo_dir}")")
    catch
    tmp="print $"
    awk="{${tmp}${num_no}}"
    max_prefix_num="$(echo -e $remote_tags| awk "${awk}")"
    trace "Maximum prefix# is: $max_prefix_num"
    echo "${max_prefix_num}"
}

#
# Sort by https://stackoverflow.com/a/5917762/102699
#
function git_get_sorted_remote_tags() {
    local prefix="$1"
    local repo_dir="$2"
    local remote_tags=$(try "Get remote Git tags for '${prefix}'" \
        "$(git_get_remote_tags "${prefix}" "${repo_dir}")")
    catch
    local remote_tags=$(try "Sort tags in descending order by numeric suffix" \
        "$(echo -e $remote_tags | sed 's/ /\n/g' | awk '{ print substr($1,8) }' | sort -rn)")
    echo -e $remote_tags
}

function git_get_remote_tags() {
    local prefix="$1"
    local repo_dir="$2"
    push_dir "${repo_dir}"
    local remote_tags=$(try "Get remote Git tags prefixed with '${prefix}-' but omitting '${prefix}-lock'" \
        "$(git ls-remote --tags 2> /dev/null | awk '{print substr($2,11)}' | grep "^${prefix}-"  | grep -v "${prefix}-lock" | grep -vF "^{}")")
    catch
    pop_dir
    echo -e ${remote_tags}
    return $(last_error)
}

function git_get_commit_hash() {
    local tag="$1"
    local repo_dir="$2"
    push_dir "${repo_dir}"
    output=$(try "Get Git commit hash for tag ${tag}" \
        "$(git show-ref -s "${tag}")")
    catch
    echo "${output}"
    pop_dir
    return $(last_error)
}

function git_hash_log() {
    local hash="$1"
    local repo_dir="$2"
    push_dir "${repo_dir}"
    output=$(try "Get Git commit hash for tag ${hash}" \
        "$(git log "${hash}..HEAD" --oneline | cut -d' ' -f2-999)")
    catch
    echo "${output}"
    pop_dir
    return $(last_error)
}

function git_tag() {
    local repo_dir="$1"
    local tag="$2"
    local message="$(default "$3" "Tagged with ${tag}")"
    push_dir "${repo_dir}"
    local _=$(try "Git tag with ${tag}" "$(git tag -a -f "${tag}" -m "${message}" 2>&1)")
    catch
    pop_dir
    return $(last_error)
}

function git_push_tags() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    local _=$(try "Git push tags" "$(git push --tags 2>&1)")
    catch
    pop_dir
    return $(last_error)
}

function git_is_repo() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    set +e
    output="$(git branch 2>&1)"
    set -e
    if [ "fatal:" == "$(echo $output|awk '{print $1}')" ] ; then
        echo "no"
    else
        echo "yes"
    fi
    pop_dir
}

function git_branch_exists() {
    local branch="$1"
    local repo_dir="$2"
    push_dir "${repo_dir}"
    set +e
    local exists="$(git branch | grep "${branch}" 2>&1)"
    set -e
    pop_dir
    if [ "" == "${exists}" ]; then
        return 1
    fi
    return 0
}