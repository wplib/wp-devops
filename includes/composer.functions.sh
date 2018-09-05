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
declare="${CI_SOURCED_FILE:=}"
declare="${CI_TMP_DIR:=}"

function composer_run() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    set e+
    local output=$(try "Running composer in ${repo_dir}" \
        "$(composer install --no-dev --no-ansi --no-interaction --prefer-dist --ignore-platform-reqs 2>&1)")
    catch $?
    set -e
    pop_dir
    if [ 0 -ne $(last_error) ] ;then
        announce "Composer had errors: $output"
        return  $(last_error)
    fi
    return 0
}

function composer_setup() {
    local setup_dir="${CI_TMP_DIR}/composer-setup"
    local _

    _=$(try "Making directory for the composer setup script" \
        "$(mkdir -p "${setup_dir}" 2>&1)")

    _=$(try "Changing into directory for the composer setup script" \
        "$(cd "${setup_dir}" 2>&1)")

    _=$(try "Changing into directory for the composer setup script" \
        "$(curl --silent -o composer-setup.php  https://getcomposer.org/installer 2>&1)")

    actual=$(try "Generating security signature of downloaded code" \
            "$(cat composer-setup.php | openssl dgst -sha384 2>&1)")

    expected=$(try "Downloading composer security signature" \
            "(stdin)= $(curl --silent -q https://composer.github.io/installer.sig 2>&1)")

    announce "Comparing security signatures"
    if [ "${expected}" != "${actual}" ]; then
        announce "Invalid installer signature; Expected: $expected vs Actual: $expected. Cannot deploy."
        sudo rm composer-setup.php
        sudo rm -rf "${setup_dir}"
        exit 1
    fi

    _=$(try "Running Composer setup" \
        "$(sudo php composer-setup.php --quiet --install-dir /usr/local/bin --filename composer 2>&1)")
    catch
    cd ..
    rm -rf "${setup_dir}"
    return $(last_error)
}

function composer_get_deploy_autoloader_path() {
    local branch="$1"
    local deploy_vendor_path="$(project_get_deploy_wordpress_vendor_path)"
    echo "${deploy_vendor_path}/composer"
}

function composer_autoloader_fixup() {
    local branch="$1"
    local repo_dir="$2"
    local deploy_autoloader_dir="${repo_dir}$(composer_get_deploy_autoloader_path "${branch}")"
    local source_json="$(project_get_source_wordpress_paths_json)"
    local deploy_json="$(project_get_deploy_wordpress_paths_json)"
    local deploy_host="$(project_get_deploy_host_by dir "${repo_dir}")"
    local source_root="$(project_get_source_web_root)"
    local deploy_root="$(project_get_deploy_web_root "${branch}")"
    local path_names="vendor_path content_path"
    local output
    local filepath

    push_dir "${repo_dir}"

    for path_name in ${path_names}; do

        local source_path="$(echo "${source_json}" | jqr ".${path_name}")"
        local deploy_path="$(echo "${deploy_json}" | jqr ".${path_name}")"

        if [ "${source_path}" == "${deploy_path}" ] ; then
            continue
        fi

        trace "Fixing up path name: ${path_name}"

        for filepath in ${deploy_autoloader_dir}/autoload_*.php; do

            trace "Fixing up ${filepath}; from ${source_root}${source_path} to ${deploy_root}${deploy_path}"

            find="'${source_root}${source_path}"
            replace="'${deploy_root}${deploy_path}"

            trace "Fixing up with FIND=[${find}], REPLACE=[${replace}]"

            sed -i "s#${find}#${replace}#g" "${filepath}"

        done

    done

    pop_dir

}