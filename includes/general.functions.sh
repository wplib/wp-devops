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

declare="${CI_CACHE_DIR:=}"
declare="${CI_LOG:=}"
declare="${CI_PUSHD_FILE:=}"
declare="${CI_CIRCLECI_DIR:=}"


function get_cache_dir() {
    mkdir -p ${CI_CACHE_DIR}
    echo "${CI_CACHE_DIR}"
}

function jqr() {
    echo "$(jq -r "$1")"
}

function minify_json() {
    local input="$1"
    set +e
    output="$(echo "${input}" | jq -c . 2>&1)"
    if [[ "${output}" = *"parse error: "* ]] ; then
        echo "${input}"
    else
        echo "${output}"
    fi
    set -e
}

function try_silent() {
    local bit_bucket=$(try "$2" "$3" "$4" "$?")
}

function try() {
    CI_ERR_RESULT="$?"
    local descr="$1"
    local output="$(minify_json "$2")"
    local offset="$3"
    local error="$4"
    if [[ "${descr}" != *":"* ]]; then
        descr="${descr}:"
    fi
    if [ "" == "${offset}" ] ; then
        offset=1
    fi
    if [ "" != "${error}" ] ; then
        CI_ERR_RESULT=$error
    fi
    trace "${descr} $(trim_space "${output}")" ${offset}
    echo "${output}"
}

function last_error() {
    echo $CI_ERR_RESULT
}

function if_was_error() {
    local message="$1"
    if [ 0 -ne $CI_ERR_RESULT ] ; then
        echo $message
    fi
}

function catch() {
    local err_no="$1"
    if [ "" == "${err_no}" ] ; then
        err_no=$CI_ERR_RESULT
    fi
    CI_ERR_RESULT=$err_no
    if [ "0" != "${CI_ERR_RESULT}" ] ; then
        trace "Result: ${CI_ERR_RESULT}" 1
        return $err_no
    fi
    return 0
}

function trace() {
    local info="$(trim_space "$1"|tr '\n' ' '|tr '\r' ' ')"
    local offset="$2"
    local line_no="$(caller|awk '{print $1}')"
    if [ "" == "${offset}" ] ; then
        offset=0
    else
        line_no="${BASH_LINENO[$offset]}"
    fi
    pos=$(( offset + 2 ))
    print="{print $"
    command="${print}${pos}}"
    local cur_file="$(echo ${BASH_SOURCE[@]}|awk "${command}")"
    cur_file="${cur_file#"${CI_CIRCLECI_DIR}/"}" # See https://stackoverflow.com/a/16623897/102699
    if [ "" != "${info}" ] ; then
        info=" => ${info}"
    fi
    message="${cur_file}:${line_no}${info}"
    if [ 120 -lt ${#message} ] ; then
        echo -e "\n" >> $CI_LOG
    fi
    echo "==>> [${message}]" >> $CI_LOG
    if [ 120 -lt ${#message} ] ; then
        echo -e "\n" >> $CI_LOG
    fi
}

#
# See: https://stackoverflow.com/a/1683850/102699
#
function trim_space() {
    local trimmed="$1"

    # Strip leading spaces.
    while [[ "${trimmed}" == ' '* ]]; do
       trimmed="${trimmed## }"
    done
    # Strip trailing spaces.
    while [[ "${trimmed}" == *' ' ]]; do
        trimmed="${trimmed%% }"
    done

    echo "${trimmed}"
}

#
# Usage:
#
#       $1 - Argument passing in that might be empty, e.g. "$1", "$3", etc.
#       $1 - Default value to echo if $1 is empty
#
# Example
#
#       username=$(default "$1", "Luke Skywalker")
#
function default() {
    trace "default( \"$1\", \"$2\" )" 1

    if [ "" == "$2" ]; then
        trace "Empty default with value: $1" 1
        echo
        echo "You must specify a default value as the 2nd paramater to default."
        echo
        return 1
    fi
    if [ "" == "$1" ]; then
       echo "$2"
    else
       echo "$1"
    fi
}

function push_dir {
    local dir="$1"
    if [ "" == "${dir}" ] ; then
        dir="$(pwd)"
    fi
    CI_PUSHD_COUNTER=$(( CI_PUSHD_COUNTER + 1 ))
    local filename="${CI_PUSHD_FILE}-${CI_PUSHD_COUNTER}.txt"
    #
    # CANNOT USE try-catch here because doing
    # so will result in no directory change
    #
    pushd "${dir}" > $filename 2>&1
    result=$?
    trace "Directory pushed: : ${dir}"
    return $result
}

function pop_dir {
    local filename="${CI_PUSHD_FILE}-${CI_PUSHD_COUNTER}.txt"
    trace "Directory popped: $(cat "${filename}"|awk '{print $1}')"
    CI_PUSHD_COUNTER=$(( CI_PUSHD_COUNTER - 1 ))
    #
    # CANNOT USE try-catch here because doing
    # so will result in no directory change
    #
    popd > $filename 2>&1
    result=$?
    sudo rm -rf "${filename}"
    return $result
}

function announce() {
    local message="$1"
    echo -e "${message}"
    trace "${message}" 1
}

function exit_if_contains() {
    local output="$1"
    local contains="$2"
    local code="$3"
    if [[ "${output}" == *"${contains}"* ]]; then
        if [ "" == "${code}" ] ; then
            code=1
        fi
        announce "${output} Cannot deploy."
        exit $code
    fi
}

#
# https://stackoverflow.com/a/6174447/102699
#
function parse_url() {
    local part="$1"
    local url="$2"

    # extract the protocol
    scheme="$(echo "${url}" | grep "://" | sed -e 's,^\(.*://\).*,\1,g')"

    # remove the protocol -- updated
    url="$(echo "${url}" | sed -e "s#^${scheme}##g")"

    # extract the user (if any)
    user="$(echo "${url}" | grep "@" | cut -d"@" -f1)"

    # extract the host -- updated
    host_port="$(echo "${url}" | sed -e "s#${user}@##g" | cut -d"/" -f1)"

    # extract the host -- updated
    host="$(echo "${host_port}" | cut -d":" -f1)"

    # by request - try to extract the port
    port="$(echo "${host_port}" | sed -e 's#^.*:#:#g' -e 's#.*:\([0-9]*\).*#\1#g' -e 's#[^0-9]##g')"

    # extract the path (if any)
    path="/$(echo "${url}" | grep "/" | cut -d"/" -f2-)"

    case "${part}" in
        scheme|proto)
            echo "${scheme}"
            ;;

        url)
            echo "${url}"
            ;;

        user)
            echo "${user}"
            ;;

        host|domain)
            echo "${host}"
            ;;

        port)
            echo "${port}"
            ;;

        path)
            echo "${path}"
            ;;

    esac

}

function rtrim_slashes() {
    local path="$1"
    if [[ "${path}" =~ ^(.*)/$ ]] ; then
        path="${BASH_REMATCH[1]}"
    fi
    echo "${path}"
}

function ltrim_slashes() {
    local path="$1"
    if [[ "${path}" =~ ^/(.*)$ ]] ; then
        path="${BASH_REMATCH[1]}"
    fi
    echo "${path}"
}

function trim_slashes() {
    echo "$(rtrim_slashes "$(ltrim_slashes "$1")" )"
}

function dump_stack () {
   local message="${1:-""}"
   local stack_size=${#FUNCNAME[@]}
   local i
   echo $message
   for (( i=1; i<$stack_size; i++ )); do
      local function="${FUNCNAME[$i]}"
      [ "" == "${function}" ] && function=MAIN
      local line_no="${BASH_LINENO[$(( i - 1 ))]}"
      local source_file="${BASH_SOURCE[$i]}"
      [ "" == "${source_file}" ] && source_file="n/a"

      echo "${function} ${source_file} ${line_no}"
   done
}
