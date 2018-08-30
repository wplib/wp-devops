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

declare=${CI_PROJECT_DIR:=}

function project_get_json() {
    try "Get project json: { ... }"
    cat "${CI_PROJECT_DIR}/project.json"
    return $?
}

function project_get_deploy_host() {
    local repo_dir="$1"
    local query="[.deploy.hosts|to_entries[]|select(.value.branch==\""$(git_get_current_branch "${repo_dir}")"\")]|first|.key"
    echo "$(try "Get deploy hostname" "$(project_get_json | jqr "${query}")" 1)"
    return $(catch)
}

function project_get_deploy_repo_url() {
    local repo_dir="$1"
    echo "$(try "Get deploy host repository URL" \
         "$(project_get_json | jqr ".hosts.$(project_get_deploy_host "${repo_dir}").repository.url")" 1)"
    return $(catch)
}

function project_get_source_core_path() {
    echo "/$(trim_slashes "$(try "Get source's WordPress core path" \
            "$(project_get_source_wordpress_paths_json | jqr ".core_path")" 1)")"
    return $(catch)
}

function project_get_deploy_core_path() {
    echo "/$(trim_slashes "$(try "Get deploy's WordPress core path" \
            "$(project_get_deploy_wordpress_paths_json | jqr ".core_path")" 1)")"
    return $(catch)
}

function project_get_source_vendor_path() {
    echo "/$(trim_slashes "$(try "Get source's WordPress vendor path" \
            "$(project_get_source_wordpress_paths_json | jqr ".vendor_path")" 1)")"
    return $(catch)
}

function project_get_deploy_vendor_path() {
    echo "/$(trim_slashes "$(try "Get deploy's WordPress vendor path" \
            "$(project_get_deploy_wordpress_paths_json | jqr ".vendor_path")" 1)")"
    return $(catch)
}

function project_get_source_root_path() {
    echo "/$(trim_slashes "$(try "Get source's WordPress root path" \
            "$(project_get_source_wordpress_paths_json | jqr ".root_path")" 1)")"
    return $(catch)
}

function project_get_deploy_root_path() {
    echo "/$(trim_slashes "$(try "Get deploy's WordPress root path" \
            "$(project_get_deploy_wordpress_paths_json | jqr ".root_path")" 1)")"
    return $(catch)
}

function project_get_source_content_path() {
    echo "/$(trim_slashes "$(try "Get source's WordPress content path" \
            "$(project_get_source_wordpress_paths_json | jqr ".content_path")" 1)")"
    return $(catch)
}

function project_get_deploy_content_path() {
    echo "/$(trim_slashes "$(try "Get deploy's WordPress content path" \
            "$(project_get_deploy_wordpress_paths_json | jqr ".content_path")" 1)")"
    return $(catch)
}

function project_get_source_wordpress_paths_json() {
    echo "$(try "Get source's WordPress paths" \
            "$(project_get_json | jqr ".source.frameworks.wordpress")" 1)"
    return $(catch)
}

function project_get_deploy_wordpress_paths_json() {
    echo "$(try "Get deploy's WordPress paths" \
            "$(project_get_json | jqr ".deploy.frameworks.wordpress")" 1)"
    return $(catch)
}

function project_get_deploy_exclude_files() {
    echo "$(try "Get deploy files to EXCLUDE"\
        "$(project_get_deploy_json | jqr ".files.exclude[]")")"
    return $(catch)
}

function project_get_deploy_delete_files() {
    echo "$(try "Get deploy files to DELETE"\
        "$(project_get_deploy_json | jqr ".files.delete[]")")"
    return $(catch)
}

function project_get_deploy_keep_files() {
    echo "$(try "Get deploy files to KEEP"\
        "$(project_get_deploy_json | jqr ".files.keep[]")")"
    return $(catch)
}

function project_get_deploy_json() {
    echo "$(try "Get deploy JSON"\
        "$(project_get_json | jqr ".deploy")")"
    return $(catch)
}


