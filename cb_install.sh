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
VERBOSE=false
CB_REPO="https://github.com/Cloudbox/cb.git"
CB_PATH="/usr/local/bin/cloudbox"
CB_INSTALL_SCRIPT="$CB_PATH/cb_install.sh"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

run_cmd () {
  if $VERBOSE; then
      printf '%s\n' "+ $*" >&2;
      "$@"
  else
      "$@" > /dev/null 2>&1
  fi
}

while getopts 'v' f; do
	case $f in
	v)	VERBOSE=true;;
	esac
done

$VERBOSE || exec >/dev/null

# Install git
run_cmd apt-get install -y git

# Remove existing repo folder
if [ -d "$CB_PATH" ]; then
    run_cmd rm -rf $CB_PATH;
fi

# ## Clone CB repo
run_cmd git clone "${CB_REPO}" "$CB_PATH"

# Set chmod +x on script files
run_cmd chmod +x $CB_PATH/*.sh

echo "$SCRIPT_PATH"
echo "$CB_INSTALL_SCRIPT"

cp /vagrant/*.sh $CB_PATH/

# Relaunch script from new location
if [ "$SCRIPT_PATH" != "$CB_INSTALL_SCRIPT" ]; then
    bash -H "$CB_INSTALL_SCRIPT" "$@"
    exit $?
fi

# Install Cloudbox Dependencies
run_cmd bash -H $CB_PATH/cb_dep.sh "$@"

# Clone Cloudbox Repo
run_cmd bash -H $CB_PATH/cb_repo.sh "$@"
