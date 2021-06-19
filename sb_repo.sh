#!/bin/bash
#########################################################################
# Title:         Saltbox Repo Cloner Script                             #
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
BRANCH='master'
SALTBOX_PATH="/srv/git/saltbox"
SALTBOX_REPO="https://github.com/saltyorg/saltbox.git"

################################
# Functions
################################

usage () {
    echo "Usage:"
    echo "    sb_repo -b <branch>    Repo branch to use. Default is 'master'."
    echo "    sb_repo -v             Enable Verbose Mode."
    echo "    sb_repo -h             Display this help message."
}

################################
# Argument Parser
################################

while getopts ':b:vh' f; do
    case $f in
    b)  BRANCH=$OPTARG;;
    v)  VERBOSE=true;;
    h)
        usage
        exit 0
        ;;
    \?)
        echo "Invalid Option: -$OPTARG" 1>&2
        echo ""
        usage
        exit 1
        ;;
    esac
done

################################
# Main
################################

$VERBOSE || exec &>/dev/null

$VERBOSE && echo "git branch selected: "$BRANCH

## Clone Saltbox and pull latest commit
if [ -d "$SALTBOX_PATH" ]; then
    if [ -d "$SALTBOX_PATH/.git" ]; then
        cd "$SALTBOX_PATH"
        git fetch --all --prune
        git checkout -f $BRANCH
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: "$(git rev-parse --abbrev-ref HEAD)
    else
        cd "$SALTBOX_PATH"
        rm -rf library/
        git init
        git remote add origin "$SALTBOX_REPO"
        git fetch --all --prune
        git branch $BRANCH origin/$BRANCH
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: "$(git rev-parse --abbrev-ref HEAD)
    fi
else
    git clone -b $BRANCH "$SALTBOX_REPO" "$SALTBOX_PATH"
    cd "$SALTBOX_PATH"
    git submodule update --init --recursive
    $VERBOSE && echo "git branch: "$(git rev-parse --abbrev-ref HEAD)
fi

## Copy settings and config files into Saltbox folder
shopt -s nullglob
for i in "$SALTBOX_PATH"/defaults/*.default; do
    if [ ! -f "$SALTBOX_PATH/$(basename "${i%.*}")" ]; then
        cp -n "${i}" "$SALTBOX_PATH/$(basename "${i%.*}")"
    fi
done
shopt -u nullglob
