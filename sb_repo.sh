#!/bin/bash
#########################################################################
# Title:         Bizbox Repo Cloner Script                             #
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
SALTBOX_PATH="/srv/git/bizbox"
SALTBOX_REPO="https://github.com/jeremiahg7/bizbox.git"

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

$VERBOSE && echo "git branch selected: $BRANCH"

## Clone Bizbox and pull latest commit
if [ -d "$SALTBOX_PATH" ]; then
    if [ -d "$SALTBOX_PATH/.git" ]; then
        cd "$SALTBOX_PATH" || exit
        git fetch --all --prune
        # shellcheck disable=SC2086
        git checkout -f $BRANCH
        # shellcheck disable=SC2086
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
    else
        cd "$SALTBOX_PATH" || exit
        rm -rf library/
        git init
        git remote add origin "$SALTBOX_REPO"
        git fetch --all --prune
        # shellcheck disable=SC2086
        git branch $BRANCH origin/$BRANCH
        # shellcheck disable=SC2086
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
    fi
else
    # shellcheck disable=SC2086
    git clone -b $BRANCH "$SALTBOX_REPO" "$SALTBOX_PATH"
    cd "$SALTBOX_PATH" || exit
    git submodule update --init --recursive
    $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
fi

## Copy settings and config files into Bizbox folder
shopt -s nullglob
for i in "$SALTBOX_PATH"/defaults/*.default; do
    if [ ! -f "$SALTBOX_PATH/$(basename "${i%.*}")" ]; then
        cp -n "${i}" "$SALTBOX_PATH/$(basename "${i%.*}")"
    fi
done
shopt -u nullglob

## Activate Git Hooks
cd "$SALTBOX_PATH" || exit
bash "$SALTBOX_PATH"/bin/git/init-hooks
