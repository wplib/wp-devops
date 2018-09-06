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
declare="${CI_EXCLUDE_FILES_FILE:=}"
declare="${CI_BACKUP_DIR:=}"
declare="${CI_BUILD_NUM:=}"
declare="${CI_TMP_DIR:=}"
declare="${CI_NEWLINE:=}"
declare="${CI_BRANCH:=}"


function build_clone_repo() {
    local repo_url="$(project_get_deploy_repo_url "${CI_PROJECT_DIR}")"
    local clone_dir="${CI_DEPLOY_REPO_DIR}"
    local branch="${CI_BRANCH}"
    if [ "yes" == "$(git_is_repo "${clone_dir}")" ]; then
        trace "Working with ${repo_url}"
    else
        if ! [ -d "${clone_dir}" ]; then
            trace "Clone does not yet exist: ${clone_dir}"
        else
            trace "Deleting non-Git directory to allow cloning: ${clone_dir}"
            rm -rf  "${clone_dir}"
        fi
        trace "Cloning ${repo_url}"
        git_clone_repo "${repo_url}" "${clone_dir}"
    fi
    push_dir "${clone_dir}"

    trace "Checking out branch ${branch} to ${clone_dir}"
    git_checkout_branch "${branch}" "${clone_dir}"

    trace "Fetch all for ${clone_dir}"
    git_fetch_all "${clone_dir}"

#    trace "Pull for branch ${branch} into ${clone_dir}"
#    git_pull_branch "${branch}" "${clone_dir}"
#
    trace "Resetting Git branch ${branch} HARD: ${clone_dir}"
    git_reset_branch_hard "${branch}" "${clone_dir}"

    trace "Deleting untracked files for ${clone_dir}"
    git_delete_untracked_files "${clone_dir}"
    pop_dir

}

function build_process_files() {
    local source_dir="${CI_PROJECT_DIR}"
    local deploy_dir="${CI_DEPLOY_REPO_DIR}"
    local source_web_root="$(project_get_source_web_root)"
    local deploy_web_root="$(project_get_deploy_web_root)"
    local source_core_path="${source_web_root}$(project_get_source_wordpress_core_path)"
    local deploy_core_path="${deploy_web_root}$(project_get_deploy_wordpress_core_path)"
    local output

    trace "Copy files from ${source_dir} to ${deploy_dir}"

    #
    # Sync core root files
    # Copy *just* the files in www/blog/ and not subdirectories
    # See: https://askubuntu.com/a/632102/486620
    #

    output=$(try "Copy root files" \
        "$(build_sync_files shallow root \
            "${source_dir}" "${source_core_path}" \
            "${deploy_dir}" "${deploy_core_path}" 2>&1
          )"
    )
    if is_error ; then
        announce "${output}"
        return 1
    fi

    output=$(try "Copy core wp-admin files" \
        "$(build_sync_files deep core \
            "${source_dir}" "${source_core_path}/wp-admin" \
            "${deploy_dir}" "${deploy_core_path}/wp-admin" 2>&1
          )"
      )
    if is_error ; then
        announce "${output}"
        return 2
    fi

    output=$(try "Copy core wp-includes files" \
        "$(build_sync_files deep core \
            "${source_dir}" "${source_core_path}/wp-includes" \
            "${deploy_dir}" "${deploy_core_path}/wp-includes" 2>&1
          )"
      )
    if is_error ; then
        announce "${output}"
        return 3
    fi

    ls -al "${source_web_root}$(project_get_source_wordpress_content_path)/mu-plugins"
    ls -al "${deploy_web_root}$(project_get_deploy_wordpress_content_path)/mu-plugins"
    output=$(try "Copy wp-content files" \
        "$(build_sync_files deep content \
            "${source_dir}" "${source_web_root}$(project_get_source_wordpress_content_path)" \
            "${deploy_dir}" "${deploy_web_root}$(project_get_deploy_wordpress_content_path)" 2>&1
          )"
    )
    if is_error ; then
        announce "${output}"
        return 4
    fi
    ls -al "${source_web_root}$(project_get_source_wordpress_content_path)/mu-plugins"
    ls -al "${deploy_web_root}$(project_get_deploy_wordpress_content_path)/mu-plugins"

    output=$(try "Copy vendor files" \
        "$(build_sync_files deep vendor \
            "${source_dir}" "${source_web_root}$(project_get_source_wordpress_vendor_path)" \
            "${deploy_dir}" "${deploy_web_root}$(project_get_deploy_wordpress_vendor_path)" 2>&1
          )"
    )
    if is_error ; then
        announce "${output}"
        return 5
    fi

    output=$(try "Fixup Composer Autoloader files" \
        "$(composer_autoloader_fixup "${CI_BRANCH}" "${deploy_dir}")")

    if is_error ; then
        announce "${output}"
        return 6
    fi

    output=$(try "Copy whitelisted files" \
        "$(build_keep_files "${source_dir}" "${deploy_dir}" 2>&1)"
    )
    if is_error ; then
        announce "${output}"
        return 7
    fi

    output=$(try "Copy 'copy' files" \
        "$(build_copy_files "${source_dir}" "${deploy_dir}" 2>&1)"
    )
    if is_error ; then
        announce "${output}"
        return 8
    fi
    return 0

}

function build_sync_files() {
    local depth="$(default "$1" shallow)"
    local path_type="$2"
    local source_dir="$3"
    local source_path="$(echo "$4" | stdin_dedup_slashes)"
    local deploy_dir="$5"
    local deploy_path="$(echo "$6" | stdin_dedup_slashes)"

    trace "Rsyncing source path '${source_path}/' to deploy path '${deploy_path}'."

    build_exclude_files_file "${deploy_path}" "${path_type}_path"

    trace "Command: rsync --archive --exclude-from=${CI_EXCLUDE_FILES_FILE} ${source_dir}${source_path} ${deploy_dir}${deploy_path}"
    trace "Exclude files from ${CI_EXCLUDE_FILES_FILE}: $(cat "${CI_EXCLUDE_FILES_FILE}")"

    if [ "deep" == "${depth}" ] ; then
        rsync --archive --delete-after \
              --exclude ".git" --exclude ".git*" \
              --exclude-from="${CI_EXCLUDE_FILES_FILE}" \
            "${source_dir}${source_path}/" \
            "${deploy_dir}${deploy_path}" >> $CI_LOG 2>&1
    else
        rsync --archive \
              --filter="- */" --filter="+ *" \
              --exclude-from="${CI_EXCLUDE_FILES_FILE}" \
            "${source_dir}${source_path}/" \
            "${deploy_dir}${deploy_path}" >> $CI_LOG 2>&1
    fi
    return $?
}

function build_exclude_files_file() {
    local path="$1"
    local path_type="$2"
    rm -rf "${CI_EXCLUDE_FILES_FILE}"
    touch "${CI_EXCLUDE_FILES_FILE}"
    local exclude_files="$(apply_path_templates relative \
        "${path_type}" \
        "$(project_get_deploy_web_root)"
        "$(project_get_deploy_wordpress_paths_json)" \
        "$(project_get_deploy_exclude_files) $(project_get_deploy_delete_files) $(project_get_deploy_keep_files)")"
    trace "Generating list of files for 'rsync --exclude-from' from ${exclude_files}"
    for file in $exclude_files ; do
        echo -e "${file}" >> $CI_EXCLUDE_FILES_FILE
    done
    trace "Exclude files list:"
    cat $CI_EXCLUDE_FILES_FILE >> $CI_LOG 2>&1
}


#
# NOTE: THIS DOES NOT WORK WITH FILES WITH SPACES
#
function build_keep_files() {
    local source_dir="$1"
    local deploy_dir="$2"
    _build_files keep "${source_dir}" "${deploy_dir}" "$(project_get_deploy_keep_files)"
}

#
# NOTE: THIS DOES NOT WORK WITH FILES WITH SPACES
#
function build_copy_files() {
    local source_dir="$1"
    local deploy_dir="$2"
    _build_files copy "${source_dir}" "${deploy_dir}" "$(project_get_deploy_copy_files)"
    return $?
}

#
# NOTE: THIS DOES NOT WORK WITH FILES WITH SPACES
#
function build_delete_files() {
    local deploy_dir="$1"
    local delete_files="$(apply_path_templates absolute \
        "$(project_get_wordpress_path_names)" \
        "$(project_get_deploy_web_root)" \
        "$(project_get_deploy_wordpress_paths_json)" \
        "$(project_get_deploy_delete_files)")"
    local _

    trace "Deleting the following files from '${deploy_dir}': ${delete_files}"

    for file in ${delete_files} ; do
        file="${deploy_dir}${file}"
        if ! [ -e "${file}" ] ; then
            trace "Skipping deletion of ${file} [File not found.]"
            continue
        fi
        _=$(try "Deleting ${file}" "$(rm -rf "${file}" 2>&1)")
    done
}

#
# NOTE: THIS DOES NOT WORK WITH FILES WITH SPACES
#
function _build_files() {
    local mode="$1"
    local source_dir="$2"
    local deploy_dir="$3"
    local files="$4"
    local path_names="$(project_get_wordpress_path_names)"
    local source_paths_json="$(project_get_source_wordpress_paths_json)"
    local deploy_paths_json="$(project_get_deploy_wordpress_paths_json)"
    local source_web_root="$(project_get_source_web_root)"
    local deploy_web_root="$(project_get_deploy_web_root)"
    trace "Preparing to ${mode} files using these path names ${path_names}: ${files}"
    for file in $files ; do
        relative_deploy_file="$(apply_path_templates absolute \
            "${path_names}" "${deploy_web_root}" "${deploy_paths_json}" "${file}")"
        deploy_file="${deploy_dir}${relative_deploy_file}"
        trace "Relative deploy file: $relative_deploy_file"
        trace "Deploy file: $deploy_file"
        trace "Preparing to ${mode} deploy file: ${deploy_file}"
        if [ "keep" == "${mode}" ] ; then
            if [ -e "${deploy_file}" ] ; then
                # We have it. All is good
                continue
            fi
        fi
        relative_source_file="$(apply_path_templates absolute \
            "${path_names}" "${source_web_root}" "${source_paths_json}" "${file}")"
        source_file="${source_dir}${relative_source_file}"
        trace "Relative source file: $relative_source_file"
        trace "Preparing to ${mode} source file: ${source_file}"
        if ! [ -e "${source_file}" ] ; then
            if [ "keep" == "${mode}" ] ; then
                announce "The file '${file}' not found in source as '${relative_source_file} or in deploy as '${relative_deploy_file}'. Cannot deploy."
            else
                announce "The file '${file}' not found as '${relative_source_file}'. Cannot deploy."
            fi
            return 1
        fi
        local output=$(try "Copying ${file} to ${deploy_dir}" "$(rsync -a "${source_file}" "${deploy_file}")")
        if is_error ; then
            announce "Failed copying ${file} to ${deploy_dir}: $output"
            return 2
        fi
    done
}

function build_get_filename() {
    local dir="$1"
    if [ "" == "${dir}" ] ; then
        dir="${CI_DEPLOY_REPO_DIR}"
    fi
    echo "${dir}/BUILD"
}

function build_get_current_tag() {
    echo "build-$(build_get_current_num)"
}

function build_get_current_num() {
    push_dir "${CI_PROJECT_DIR}"
    cat "$(build_get_filename)"
    pop_dir
}

function build_generate_file() {
    local deploy_dir="${CI_DEPLOY_REPO_DIR}"
    local build_num="${CI_BUILD_NUM}"
    local user_name="$(git_get_user)"

    push_dir "${deploy_dir}"
    local filename="$(build_get_filename)"

    local message="riting build# ${build_num} to: ${filename}"
    local _=$(try "W${message}" "$(echo "${build_num}" > $filename)")
    catch
    pop_dir
    if [ 0 -ne $(last_error) ] ; then
        announce "Error w${message}"
        return $(last_error)
    fi
    return 0
}

function build_tag_remote() {
    local repo_dir="$1"
    local build_tag="$(build_get_current_tag)"

    local message="dding local '${build_tag}' tag"
    local output=$(try "A${message}" "$(git_tag "${repo_dir}" "${build_tag}" "Build #$(build_get_current_num)")")
    catch
    if [[ "${output}" =~ ^fatal ]]; then
        announce "Error a${message}"
        return $(last_error)
    fi

    local message="ushing '${build_tag}' tag to remote"
    local output=$(try "P${message}" "$(git_push_tags "${repo_dir}")")
    catch
    if [[ "${output}" =~ ^fatal ]]; then
        announce "Error p${message}"
        return $(last_error)
    fi
    return 0
}
