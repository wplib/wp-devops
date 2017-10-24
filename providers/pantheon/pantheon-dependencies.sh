#!/usr/bin/env bash
#
# devops/core/providers/pantheon/pantheon-dependencies.sh
#

#
# "Declarations" of the variables this script assumes
#
#declare=${VARNAME:=}

#
# Installing Terminus for Pantheon
#
announce "Installing Terminus for Pantheon"
cd /tmp
rm -f terminus.tar.gz
rm -rf terminus
wget -O terminus.tar.gz https://github.com/pantheon-systems/terminus/archive/1.6.0.tar.gz
tar -xzf terminus.tar.gz
mv terminus-1.6.0 terminus
exit



