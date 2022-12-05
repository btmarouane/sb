#!/bin/bash
#shellcheck disable=SC2220
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

VERBOSE=true
VERBOSE_OPT=""
SUPPORT=true
SB_REPO="https://github.com/btmarouane/sb.git"
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

while getopts 'v-:' f; do
    case "${f}" in
    v)  VERBOSE=true
        VERBOSE_OPT="-v"
        ;;
    -)
        case "${OPTARG}" in
            no-support)
                SUPPORT=false
                ;;
        esac;;
    esac
done

################################
# Main
################################

# Check if Cloudbox is installed
# develop
if [ -d "/srv/git/cloudbox" ]; then
    echo "==== Cloudbox Install Detected ===="
    echo "Cloudbox installed. Exiting..."
    echo "==== Cloudbox Install Detected ===="
    exit 1
fi

# master
for directory in /home/*/*/ ; do
    base=$(basename "$directory")
    if [ "$base" == "cloudbox" ]; then
        echo "==== Cloudbox Install Detected ===="
        echo "Cloudbox installed. Exiting..."
        echo "==== Cloudbox Install Detected ===="
        exit 1
    fi
done

# Check for supported Ubuntu Releases
release=$(lsb_release -cs)

# Add more releases like (focal|jammy)$
if [[ $release =~ (focal|jammy)$ ]]; then
    echo "$release is currently supported."
elif [[ $release =~ (placeholder)$ ]]; then
    echo "$release is currently in testing."
else
    echo "==== UNSUPPORTED OS ===="
    if $SUPPORT; then
        echo "Install cancelled: $release is not supported."
        echo "Supported OS: 20.04 (focal) and 22.04 (jammy)"
        echo "==== UNSUPPORTED OS ===="
        exit 1
    else
        echo "Forcing install on $release."
        echo "You have chosen to ignore support."
        echo "Do not ask for support on our discord."
        echo "==== UNSUPPORTED OS ===="
        sleep 10
  fi
fi

# Check if using valid arch
arch=$(uname -m)

if [[ $arch =~ (x86_64)$ ]]; then
    echo "$arch is currently supported."
else
    echo "==== UNSUPPORTED CPU Architecture ===="
    echo "Install cancelled: $arch is not supported."
    echo "Supported CPU Architecture(s): x86_64"
    echo "==== UNSUPPORTED CPU Architecture ===="
    exit 1
fi

echo "Installing Saltbox Dependencies."

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

# Install Saltbox Dependencies
run_cmd bash -H $SB_PATH/sb_dep.sh $VERBOSE_OPT

# Clone Saltbox Repo
run_cmd bash -H $SB_PATH/sb_repo.sh -b master $VERBOSE_OPT