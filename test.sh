#!/usr/bin/env bash
set -eo pipefail

source "sourced.sh"

git_generate_log "deploy" "${CI_PROJECT_DIR}"