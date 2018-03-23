#!/usr/bin/env bash
#
# devops/core/includes/install-apt-get.sh
#
#   Install apt-get packages
#

#
# "Declarations" of the variables this script assumes
#
declare=${ARTIFACTS_FILE:=}
declare=${PACKAGES_TO_INSTALL:=}


if [ "" != "${PACKAGES_TO_INSTALL}" ] ; then

    announce "Installing apt-get packages"

    #
    # Adding PHP PPA
    #
    announce "...Adding PHP PPA"
    sudo add-apt-repository -y ppa:ondrej/php >> $ARTIFACTS_FILE 2>&1

    #
    # Updating apt-get
    #
    announce "...Updating apt-get"
    sudo apt-get update -y >> $ARTIFACTS_FILE 2>&1

    #
    # Install all the packages
    #
    for package in $PACKAGES_TO_INSTALL; do
        [ '---' == "${package}" ] && continue
        announce "...Installing apt-get package ${package}"
        sudo apt-get install -y ${package} >> $ARTIFACTS_FILE 2>&1
    done

    #
    # Check to see if we have a post-install-apt-get.sh "hook"
    #
    POST_INSTALL_APT_GET="${DEVOPS_ROOT}/post-install-apt-get.sh"
    if [ -f "${POST_INSTALL_APT_GET}" ] ; then
        announce "...Running ${POST_INSTALL_APT_GET}"
        source "${POST_INSTALL_APT_GET}"
    fi

    #
    # Restart the Apache server, just in case
    #
    announce "...Restarting Apache, just in case"
    sudo service apache2 restart >> $ARTIFACTS_FILE 2>&1

    #
    # Updating apt-get
    #

    announce "Apt-get packages installed"

fi


