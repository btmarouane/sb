#!/bin/bash
#########################################################################
# Title:         Cloudbox Repo Cloner Script                            #
# Author(s):     desimaniac                                             #
# URL:           https://github.com/cloudbox/cb                         #
# --                                                                    #
#         Part of the Cloudbox project: https://cloudbox.works          #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

################################
# Variables
################################

VERBOSE=false
BRANCH='master'
CLOUDBOX_PATH="/srv/git/cloudbox"
CLOUDBOX_REPO="https://github.com/cloudbox2/cloudbox.git"

################################
# Functions
################################

usage () {
    echo "Usage:"
    echo "    cb_repo -b <branch>    Repo branch to use. Default is 'master'."
    echo "    cb_repo -v             Enable Verbose Mode."
    echo "    cb_repo -h             Display this help message."
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

## Clone Cloudbox and pull latest commit
if [ -d "$CLOUDBOX_PATH" ]; then
    if [ -d "$CLOUDBOX_PATH/.git" ]; then
        cd "$CLOUDBOX_PATH"
        git fetch --all --prune
        git checkout -f $BRANCH
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: "$(git rev-parse --abbrev-ref HEAD)
    else
        cd "$CLOUDBOX_PATH"
        rm -rf library/
        git init
        git remote add origin "$CLOUDBOX_REPO"
        git fetch --all --prune
        git branch $BRANCH origin/$BRANCH
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: "$(git rev-parse --abbrev-ref HEAD)
    fi
else
    git clone -b $BRANCH "$CLOUDBOX_REPO" "$CLOUDBOX_PATH"
    cd "$CLOUDBOX_PATH"
    git submodule update --init --recursive
    $VERBOSE && echo "git branch: "$(git rev-parse --abbrev-ref HEAD)
fi

## Copy settings and config files into Cloudbox folder
shopt -s nullglob
for i in "$CLOUDBOX_PATH"/defaults/*.default; do
    if [ ! -f "$CLOUDBOX_PATH/$(basename "${i%.*}")" ]; then
        cp -n "${i}" "$CLOUDBOX_PATH/$(basename "${i%.*}")"
    fi
done
shopt -u nullglob
