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
declare="${CI_INCLUDES_FILE:=}"
declare="${CI_TMP_DIR:=}"

function composer_run() {
    local repo_dir="$1"
    push_dir "${repo_dir}"
    announce "Running Composer"
    composer install --no-ansi --no-interaction --prefer-dist >> $CI_LOG 2>&1
    catch $?
    pop_dir
    return $(last_error)
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

