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

function ansible_playbook_command() {
  arg=("$@")
  cloudbox_repo="/srv/git/cloudbox"
  cd "${cloudbox_repo}"
    '/usr/local/bin/ansible-playbook' \
    "${cloudbox_repo}/cloudbox.yml" \
    --become \
    -vv \
    ${arg}
  cd - >/dev/null
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
    echo "Updating Cloudbox..."
    ./cb_repo.sh
    ansible_playbook_command "--tags settings"
    ;;

  install)
    role=${1}
    ansible_playbook_command "--skip-tags settings --tags ${role}"
    ;;

  *)
    echo "hello"
    ;;
esac
