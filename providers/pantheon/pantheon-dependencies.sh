#!/usr/bin/env bash
#
# devops/core/providers/pantheon/pantheon-dependencies.sh
#

#
# "Declarations" of the variables this script assumes
#
declare=${PANTHEON_TOKEN:=}

if ! [ -f ~/cache/terminus/bin/terminus ]; then
    #
    # Installing Terminus for Pantheon, latest version
    #
    announce "...Installing Terminus for Pantheon"
    mkdir -p ~/cache
    cd ~/cache
    rm -f terminus.tar.gz
    rm -rf terminus
    TERMINUS_TARBALL="$(curl -s https://api.github.com/repos/pantheon-systems/terminus/releases/latest | jq -r ".tarball_url")"
    wget -O terminus.tar.gz "${TERMINUS_TARBALL}"
    tar -xzf terminus.tar.gz
    rm terminus.tar.gz
    TERMINUS_DIRECTORY="$(ls -d *terminus*/)"
    mv "${TERMINUS_DIRECTORY}" terminus
    cd terminus
    composer update
fi

#
# Symlinking Terminus for Pantheon
#
announce "...Symlinking Terminus for Pantheon"
sudo ln -s ~/cache/terminus/bin/terminus /usr/local/bin/terminus

#
# Authenticating Terminus for Pantheon
#
announce "...Authenticating Terminus for Pantheon"
terminus auth:login --machine-token="${PANTHEON_TOKEN}"





apt-get update && apt-get install -y curl jq wget