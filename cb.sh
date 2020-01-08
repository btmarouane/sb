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
    git submodule update --init --recursive
}

function ansible_playbook() {
  arg=("$@")

  if [[ $arg =~ "settings" ]]; then
     SETTINGS_SKIP_TAG=""
  else
     SETTINGS_SKIP_TAG="--skip-tags settings"
  fi

  cd "${CLOUDBOX_REPO}"

  echo "" > cloudbox.log

  '/usr/local/bin/ansible-playbook' \
    ${CLOUDBOX_REPO}/cloudbox.yml \
    --become \
    ${SETTINGS_SKIP_TAG} \
    --tags ${arg}

  cd - >/dev/null
}

function update () {

    declare -A old_object_ids
    declare -A new_object_ids
    config_files=('accounts' 'settings' 'adv_settings' 'backup_config')
    config_files_are_changed=false

    echo -e "Updating Cloudbox...\n"

    cd "${CLOUDBOX_REPO}"

    # Get Git Object IDs for config files
    for file in "${config_files[@]}"; do
        old_object_ids["$file"]=$(git hash-object defaults/"$file".yml.default)
    done

    git_fetch_and_reset

    # Get Git Object IDs for config files
    for file in "${config_files[@]}"; do
        new_object_ids["$file"]=$(git hash-object defaults/"$file".yml.default)
    done

    # Compare Git Object IDs
    for file in "${config_files[@]}"; do
        if [ ${old_object_ids[$file]} != ${new_object_ids[$file]} ]; then
            config_files_are_changed=true
            break
        fi
    done

    $config_files_are_changed && ansible_playbook "settings" && echo -e '\n'

    echo -e "Updating Complete."

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
    role=${@}
    ansible_playbook "${role}"
    ;;

  *)
    echo "hello"
    ;;
esac
