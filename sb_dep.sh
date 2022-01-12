#!/bin/bash
#################################################################################
# Title:         Saltbox: Dependencies Installer                                #
# Author(s):     L3uddz, Desimaniac, EnorMOZ, salty                             #
# URL:           https://github.com/saltyorg/sb                                 #
# Description:   Installs dependencies needed for Saltbox.                      #
# --                                                                            #
#################################################################################
#                     GNU General Public License v3.0                           #
#################################################################################

################################
# Privilege Escalation
################################

# Restart script in SUDO
# https://unix.stackexchange.com/a/28793

if [ "$EUID" != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

################################
# Variables
################################

VERBOSE=true

readonly SYSCTL_PATH="/etc/sysctl.conf"
readonly PYTHON_CMD_SUFFIX="-m pip install \
                              --timeout=360 \
                              --no-cache-dir \
                              --disable-pip-version-check \
                              --upgrade"
readonly PYTHON3_CMD="python3 $PYTHON_CMD_SUFFIX"
readonly ANSIBLE=">=5.0.0,<6.0.0"

################################
# Argument Parser
################################

# shellcheck disable=SC2220
while getopts 'v' f; do
    case $f in
    v)	VERBOSE=true;;
    esac
done

################################
# Main
################################

$VERBOSE || exec &>/dev/null

## Disable IPv6
if [ -f "$SYSCTL_PATH" ]; then
    ## Remove 'Disable IPv6' entries from systctl
    sed -i -e '/^net.ipv6.conf.all.disable_ipv6/d' "$SYSCTL_PATH"
    sed -i -e '/^net.ipv6.conf.default.disable_ipv6/d' "$SYSCTL_PATH"
    sed -i -e '/^net.ipv6.conf.lo.disable_ipv6/d' "$SYSCTL_PATH"
    sysctl -p
fi

## Environmental Variables
export DEBIAN_FRONTEND=noninteractive

## Install Pre-Dependencies
apt-get install -y \
    software-properties-common \
    apt-transport-https
apt-get update

## Add apt repos
add-apt-repository main
add-apt-repository universe
add-apt-repository restricted
add-apt-repository multiverse
apt-get update

## Install apt Dependencies
apt-get install -y \
    nano \
    git \
    curl \
    gpg-agent \
    build-essential \
    libssl-dev \
    libffi-dev \
    python3-dev \
    python3-testresources \
    python3-apt \
    python3-virtualenv \
    python3-venv

## Check locale contains UTF-8 and if not change it to en_US.UTF-8
locale charmap | grep -qi 'utf-\+8' && echo "Uses UTF-8 encoding." || (update-locale LANG=en_US.UTF-8 && echo "Set locale to en_US.UTF-8")

## Uninstall setuptools as a workaround for https://github.com/pypa/pip/issues/10742
python3 -m pip uninstall -y setuptools

## Install pip3
cd /tmp || exit
curl -sLO https://bootstrap.pypa.io/get-pip.py
python3 get-pip.py

## Install pip3 Dependencies
$PYTHON3_CMD \
    pip setuptools wheel
$PYTHON3_CMD \
    pyOpenSSL \
    requests \
    netaddr \
    jmespath \
    ansible$ANSIBLE

## Copy /usr/local/bin/pip to /usr/bin/pip
[ -f /usr/local/bin/pip3 ] && cp /usr/local/bin/pip3 /usr/bin/pip3
