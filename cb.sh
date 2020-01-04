#!/bin/bash
#########################################################################
# Title:         Cloudbox Script                                        #
# Author(s):     desimaniac, chazlarson                                 #
# URL:           https://github.com/cloudbox/cb                         #
# --                                                                    #
#         Part of the Cloudbox project: https://cloudbox.works          #
#########################################################################
#                   GNU General Public License v3.0                     #
#########################################################################

# Restart script in SUDO
# https://unix.stackexchange.com/a/28793
if [ $EUID != 0 ]; then
    sudo "$0" "$@"
    exit $?
fi

# Variables
CLOUDBOX_REPO="/srv/git/cloudbox"

function git_fetch_and_reset () {
    git fetch --quiet >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard @{u} >/dev/null
    git checkout --quiet develop >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard @{u} >/dev/null
}

function ansible_playbook() {
  arg=("$@")

  if [[ $arg =~ "settings" ]]; then
     SETTINGS_SKIP_TAG=""
  else
     SETTINGS_SKIP_TAG="--skip-tags settings"
  fi

  cd "${CLOUDBOX_REPO}"

  '/usr/local/bin/ansible-playbook' \
    ${CLOUDBOX_REPO}/cloudbox.yml \
    --become \
    ${SETTINGS_SKIP_TAG} \
    --tags ${arg}

  cd - >/dev/null
}

function update () {
    local OLD_COMMIT
    local NEW_COMMIT

    echo -e "Updating Cloudbox...\n"

    cd "${CLOUDBOX_REPO}"

    OLD_COMMIT=$(git rev-parse --short HEAD)

    git_fetch_and_reset

    NEW_COMMIT=$(git rev-parse --short HEAD)

    if [ "$OLD_COMMIT" != "$NEW_COMMIT" ]; then
        ansible_playbook "settings"
    fi

    echo -e "\nUpdating Complete."
}

role=""  # Default to empty package
target=""  # Default to empty target

# Parse options to the `cb` command
while getopts ":h" opt; do
  case ${opt} in
    h )
      echo "Usage:"
      echo "    cb -h                  Display this help message."
      echo "    cb install <package>   Install <package>."
      echo "    cb update              Update Cloudbox project folder."

      exit 0
      ;;
   \? )
     echo "Invalid Option: -$OPTARG" 1>&2
     exit 1
     ;;
  esac
done
shift $((OPTIND -1))


subcommand=$1; shift  # Remove 'cb' from the argument list
case "$subcommand" in

  # Parse options to the various sub commands

  update)
    update
    ;;

  install)
    role=${1}
    ansible_playbook "${role}"
    ;;

  *)
    echo "hello"
    ;;
esac
