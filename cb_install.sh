#!/bin/bash
#########################################################################
# Title:         Cloudbox Install Script                                #
# Author(s):     desimaniac                                             #
# URL:           https://github.com/cloudbox/cb                         #
# --                                                                    #
#         Part of the Cloudbox project: https://cloudbox.works          #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

## Variables
CB_REPO="https://github.com/Cloudbox/cb.git"
CB_PATH="/usr/local/bin/cloudbox"
CB_INSTALL_SCRIPT="$CB_PATH/cb_install.sh"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"
echo script path = $SCRIPT_PATH

# Install git
apt-get install -y --reinstall git

# Remove existing repo folder
if [ -d "$CB_PATH" ]; then rm -rf $CB_PATH; fi

## Clone CB repo
git clone "$CB_REPO" "$CB_PATH"

# Set chmod +x on script files
chmod +x $CB_PATH/*.sh

# Relaunch script from new location
if [ "$SCRIPT_PATH" != "$CB_INSTALL_SCRIPT" ]; then
    sudo bash "$CB_INSTALL_SCRIPT" "$@"
    exit $?
fi

# Install Cloudbox Dependencies
source $CB_PATH/cb_dep.sh


# Clone Cloudbox Repo
source $CB_PATH/cb_repo.sh
