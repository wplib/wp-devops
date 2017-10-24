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
    # Installing Terminus for Pantheon
    #
    announce "...Installing Terminus for Pantheon"
    cd ~/cache
    rm -f terminus.tar.gz
    rm -rf terminus
    wget -O terminus.tar.gz https://github.com/pantheon-systems/terminus/archive/1.6.0.tar.gz
    tar -xzf terminus.tar.gz
    rm terminus.tar.gz
    mv terminus-1.6.0 terminus
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

