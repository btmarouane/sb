#!/bin/bash
#########################################################################
# Title:         Saltbox Install Script                                 #
# Author(s):     desimaniac, salty                                      #
# URL:           https://github.com/saltyorg/sb                         #
# --                                                                    #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

################################
# Variables
################################

VERBOSE=false
VERBOSE_OPT=""
SB_REPO="https://github.com/saltyorg/sb.git"
SB_PATH="/srv/git/sb"
SB_INSTALL_SCRIPT="$SB_PATH/sb_install.sh"
SCRIPT_PATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")"

################################
# Functions
################################

run_cmd () {
  if $VERBOSE; then
      printf '%s\n' "+ $*" >&2;
      "$@"
  else
      "$@" > /dev/null 2>&1
  fi
}

################################
# Argument Parser
################################

while getopts 'v' f; do
  case $f in
  v)  VERBOSE=true
      VERBOSE_OPT="-v"
  ;;
  esac
done

################################
# Main
################################

release=$(lsb_release -cs)
 
# Add more releases like (focal|jammy)$
if [[ $release =~ (focal)$ ]]; then
    echo "$release is currently supported."
else
    echo "$release is currently not supported."
    exit 1
fi

$VERBOSE || exec &>/dev/null

$VERBOSE && echo "Script Path: $SCRIPT_PATH"

# Update apt cache
run_cmd apt-get update

# Install git
run_cmd apt-get install -y git

# Remove existing repo folder
if [ -d "$SB_PATH" ]; then
    run_cmd rm -rf $SB_PATH;
fi

# Clone SB repo
run_cmd mkdir -p /srv/git
run_cmd git clone --branch master "${SB_REPO}" "$SB_PATH"

# Set chmod +x on script files
run_cmd chmod +x $SB_PATH/*.sh

$VERBOSE && echo "Script Path: $SCRIPT_PATH"
$VERBOSE && echo "SB Install Path: "$SB_INSTALL_SCRIPT

## Create script symlinks in /usr/local/bin
shopt -s nullglob
for i in "$SB_PATH"/*.sh; do
    if [ ! -f "/usr/local/bin/$(basename "${i%.*}")" ]; then
        run_cmd ln -s "${i}" "/usr/local/bin/$(basename "${i%.*}")"
    fi
done
shopt -u nullglob

# Relaunch script from new location
if [ "$SCRIPT_PATH" != "$SB_INSTALL_SCRIPT" ]; then
    bash -H "$SB_INSTALL_SCRIPT" "$@"
    exit $?
fi

# Install Saltbox Dependencies
run_cmd bash -H $SB_PATH/sb_dep.sh $VERBOSE_OPT

# Clone Saltbox Repo
run_cmd bash -H $SB_PATH/sb_repo.sh -b master $VERBOSE_OPT
