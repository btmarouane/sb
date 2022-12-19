#!/bin/bash
#########################################################################
# Title:         Bizbox Repo Cloner Script                              #
# Author(s):     GrecoTechnology                                        #
# URL:           https://github.com/GrecoTechnology/bb                  #
# --                                                                    #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

################################
# Variables
################################

VERBOSE=false
BRANCH='master'
BIZBOX_PATH="/srv/git/bizbox"
BIZBOX_REPO="https://github.com/GrecoTechnology/bizbox.git"

################################
# Functions
################################

usage () {
    echo "Usage:"
    echo "    bb_repo -b <branch>    Repo branch to use. Default is 'master'."
    echo "    bb_repo -v             Enable Verbose Mode."
    echo "    bb_repo -h             Display this help message."
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
if [ -d "$BIZBOX_PATH" ]; then
    if [ -d "$BIZBOX_PATH/.git" ]; then
        cd "$BIZBOX_PATH" || exit
        git fetch --all --prune
        # shellcheck disable=SC2086
        git checkout -f $BRANCH
        # shellcheck disable=SC2086
        git reset --hard origin/$BRANCH
        git submodule update --init --recursive
        $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
    else
        cd "$BIZBOX_PATH" || exit
        rm -rf library/
        git init
        git remote add origin "$BIZBOX_REPO"
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
    git clone -b $BRANCH "$BIZBOX_REPO" "$BIZBOX_PATH"
    cd "$BIZBOX_PATH" || exit
    git submodule update --init --recursive
    $VERBOSE && echo "git branch: $(git rev-parse --abbrev-ref HEAD)"
fi

## Copy settings and config files into Bizbox folder
shopt -s nullglob
for i in "$BIZBOX_PATH"/defaults/*.default; do
    if [ ! -f "$BIZBOX_PATH/$(basename "${i%.*}")" ]; then
        cp -n "${i}" "$BIZBOX_PATH/$(basename "${i%.*}")"
    fi
done
shopt -u nullglob

## Activate Git Hooks
cd "$BIZBOX_PATH" || exit
bash "$BIZBOX_PATH"/bin/git/init-hooks
