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
declare="${CI_PROJECT_DIR:=}"
declare="${CI_DEPLOY_REPO_DIR:=}"
declare="${CI_TMP_DIR:=}"
declare="${CI_BRANCH:=}"

function build_clone_repo() {
    local repo_url="$(project_get_deploy_repo_url "${CI_PROJECT_DIR}")"
    local clone_dir="${CI_DEPLOY_REPO_DIR}"
    local branch="${CI_BRANCH}"
    if [ "no" == "$(git_is_repo "${clone_dir}")" ]; then
        if ! [ -d "${clone_dir}" ]; then
            trace "Clone does not yet exist: ${clone_dir}"
        else
            trace "Deleting non-Git directory to allow cloning: ${clone_dir}"
            rm -rf  "${clone_dir}"
        fi
        git_clone_repo "${repo_url}" "${clone_dir}"
    fi
    push_dir "${clone_dir}"
    git_checkout_branch "${branch}" "${clone_dir}"
    git_fetch_all "${clone_dir}"
    git_pull_branch "${branch}" "${clone_dir}"
    trace "Resetting Git branch ${branch} HARD: ${clone_dir}"
    git_reset_branch_hard "${branch}" "${clone_dir}"
    git_delete_untracked_files "${clone_dir}"
    pop_dir

}

function build_copy_files() {
    local source_dir="${CI_PROJECT_DIR}"
    local deploy_dir="${CI_DEPLOY_REPO_DIR}"
    local source_core_path="$(project_get_source_core_path)"
    local deploy_core_path="$(project_get_deploy_core_path)"
    local _

    trace "Copy files from ${source_dir} to ${deploy_dir}"

    #
    # Sync core root files
    # Copy *just* the files in www/blog/ and not subdirectories
    # See: https://askubuntu.com/a/632102/486620
    #

    _=$(try "Copy root files" \
        "$(build_sync_files_shallow \
            "${source_dir}" "${source_core_path}" \
            "${deploy_dir}" "${deploy_core_path}" 2>&1
          )"
    )
    catch

    _=$(try "Copy core wp-admin files" \
        "$(build_sync_files_deep \
            "${source_dir}" "${source_core_path}/wp-admin" \
            "${deploy_dir}" "${deploy_core_path}/wp-admin" 2>&1
          )"
      )
    catch

    _=$(try "Copy core wp-includes files" \
        "$(build_sync_files_deep \
            "${source_dir}" "${source_core_path}/wp-includes" \
            "${deploy_dir}" "${deploy_core_path}/wp-includes" 2>&1
          )"
      )
    catch

    _=$(try "Copy vendor files" \
        "$(build_sync_files_deep \
            "${source_dir}" "$(project_get_source_vendor_path)" \
            "${deploy_dir}" "$(project_get_deploy_vendor_path)" 2>&1
          )"
      )
    catch

    _=$(try "Copy wp-content files" \
        "$(build_sync_files_deep \
            "${source_dir}" "$(project_get_source_content_path)" \
            "${deploy_dir}" "$(project_get_deploy_content_path)" 2>&1
          )"
      )
    catch

    _=$(try "Copy whitelisted files" \
        "$(build_keep_files "${source_dir}" "${deploy_dir}" 2>&1)"
      )
    catch

}

#
# For `tr -s '/'` see https://unix.stackexchange.com/a/187055/144192
#
function build_sync_files_shallow() {
    local source_dir="$1"
    local source_path="$(echo "$2" | tr -s '/')"
    local deploy_dir="$3"
    local deploy_path="$(echo "$4" | tr -s '/')"

    local exclude_files_list="$(build_write_exclude_files "${deploy_path}")"

    announce "Rsyncing source path '${source_path}/' to deploy path '${deploy_path}'"
    rsync --archive --filter="- */" --filter="+ *" --exclude-from="${exclude_files_list}" \
        "$(rtrim_slashes "${source_dir}${source_path}")" \
        "$(rtrim_slashes "${deploy_dir}${deploy_path}")" >> $CI_LOG 2>&1
    catch $?
    cat "${exclude_files_list}"
    sudo rm -rf "${exclude_files_list}"
    return $(last_error)
}

#
# For `tr -s '/'` see https://unix.stackexchange.com/a/187055/144192
#
function build_sync_files_deep() {
    local source_dir="$1"
    local source_path="$(echo "$2" | tr -s '/')"
    local deploy_dir="$3"
    local deploy_path="$(echo "$4" | tr -s '/')"

    local exclude_files_list="$(build_write_exclude_files "${deploy_path}")"

    announce "Rsyncing source path '${source_path}/' to deploy path '${deploy_path}'"
    rsync --archive --delete-after --verbose \
        --exclude ".git" --exclude ".git*" --exclude-from="${exclude_files_list}" \
        "${source_dir}${source_path}/" \
        "${deploy_dir}${deploy_path}" >> $CI_LOG 2>&1
    catch $?
    cat "${exclude_files_list}"
    sudo rm -rf "${exclude_files_list}"
    return $(last_error)
}

#
# TODO: Use try-catch for this method
#
function build_write_exclude_files() {
    local path="$1"

    local exclude_file_list="$(mktemp "${CI_TMP_DIR}/exclude-XXXX.txt")"
    touch "${exclude_file_list}"
    local exclude_files=$(build_get_rsync_exclude_from_files)
    trace "Generating list of files for RSync --exclude-from"
    for file in $exclude_files ; do
        if [ "/" != "${file:0:1}" ] ; then
            # if not an absolute reference, then file is to be excludes everywhere
            trace "Adding ${file}"
            echo -e "${file}" >> $exclude_file_list
            continue
        fi
        if ! [[ ${file} =~ ^${path}/(.+)$ ]] ; then
            trace "Skipping $file" >> $CI_LOG
            continue
        fi
        trace "Adding ${BASH_REMATCH[1]}"
        echo -e "${BASH_REMATCH[1]}" >> $exclude_file_list
    done
    echo "${exclude_file_list}"

}

function build_get_rsync_exclude_from_files() {
    echo -e "$(try "Get build files for RSync --exclude-from"\
        "$(project_get_deploy_exclude_files)\n$(project_get_deploy_delete_files)\n$(project_get_deploy_keep_files)")"
    return $(catch)

}

function build_keep_files() {
    local source_dir="$1"
    local deploy_dir="$2"
    local keep_files="$(project_get_deploy_keep_files)"
    local saveIFS="${IFS}"
    local _
    IFS=$'\n'
    for file in $keep_files ; do
        deploy_file="${deploy_dir}${file}"
        source_paths_json="$(project_get_source_wordpress_paths_json)"
        deploy_paths_json="$(project_get_deploy_wordpress_paths_json)"
        path_len="0"
        for path_name in $(project_get_deploy_wordpress_path_names); do
            deploy_path="$(echo $deploy_paths_json|jqr ".${path_name}")"
            if ! [[ ${file} =~ ^${deploy_path}/(.+)$ ]] ; then
                continue
            fi
            if [ "${path_len}" -lt "${#deploy_path}" ] ; then
                path_len="${#deploy_path}"
                source_path="$(echo $source_paths_json|jqr ".${path_name}")"
                source_file="${source_dir}${source_path}/${BASH_REMATCH[1]}"
            fi
        done
        if [ "" == "${source_file}" ]; then
            source_file=""${source_dir}${file}""
        fi
        if ! [ -f "${source_file}" ] ; then
            if [ -f "${deploy_file}" ] ; then
                # We have it. All is good
                continue
            fi
            announce "The 'keep' file [${source_file}] could not be found. Cannot deploy."
            exit 1
        fi
        _=$(try "Copying ${file} to ${deploy_dir}"
            "$(cp -R "${source_file}" "${deploy_dir}/${file}")")
    done
    IFS="${saveIFS}"
}

function build_delete_files() {
    local deploy_dir="$1"
    local delete_files=$(project_get_deploy_delete_files)
    local saveIFS="${IFS}"
    local _
    IFS=$'\n'
    for file in $delete_files ; do
        file="${deploy_dir}${file}"
        echo "[${file}]"
        if ! [ -f "${file}" ] ; then
            announce "Skipping deletion of ${file} [File not found.]"
            continue
        fi
        _=$(try "Deleting ${file}" "$(rm -rf "${file}" 2>&1)")
    done
    IFS="${saveIFS}"
}


