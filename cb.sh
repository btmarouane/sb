#!/bin/bash
#########################################################################
# Title:         Cloudbox: CB Script                                    #
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

################################
# Variables
################################

#Ansible
ANSIBLE_PLAYBOOK_BINARY_PATH="/usr/local/bin/ansible-playbook"

# Cloudbox
CLOUDBOX_REPO_PATH="/srv/git/cloudbox"
CLOUDBOX_PLAYBOOK_PATH="$CLOUDBOX_REPO_PATH/cloudbox.yml"
CLOUDBOX_LOGFILE_PATH="$CLOUDBOX_REPO_PATH/cloudbox.log"

# Community
COMMUNITY_REPO_PATH="/opt/community"
COMMUNITY_PLAYBOOK_PATH="$COMMUNITY_REPO_PATH/community.yml"
COMMUNITY_LOGFILE_PATH="$COMMUNITY_REPO_PATH/community.log"

################################
# Functions
################################

git_fetch_and_reset () {

    git fetch --quiet >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard @{u} >/dev/null
    git checkout --quiet develop >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard @{u} >/dev/null
    git submodule update --init --recursive

}

run_playbook_cb () {

    local tags skip_tags

    tags="--tags $1"
    [[ ! -z "$2" ]] && skip_tags="--skip-tags $2"

    echo "" > "${CLOUDBOX_LOGFILE_PATH}"

    cd "${CLOUDBOX_REPO_PATH}"
    "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
      "${CLOUDBOX_PLAYBOOK_PATH}" \
      --become \
      ${skip_tags} \
      ${tags}

    cd - >/dev/null

}

run_playbook_cm () {

    local tags skip_tags

    tags="--tags $1"
    [[ ! -z "$2" ]] && skip_tags="--skip-tags $2"

    echo "" > "${COMMUNITY_LOGFILE_PATH}"

    cd "${COMMUNITY_REPO_PATH}"
    "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
      "${COMMUNITY_PLAYBOOK_PATH}" \
      --become \
      ${skip_tags} \
      ${tags}

    cd - >/dev/null

}

install () {

    # Variables
    local arg=("$@")
    declare tags
    local tags_cb
    local skip_tags_cb="settings"
    local tags_cm
    local skip_tags_cm="settings"

    # Build Tag Arrays
    tags=(${arg//,/ })
    for i in "${!tags[@]}"
    do
        if [[ ${tags[i]} == cm-* ]]; then
            tags_cm="${tags_cm}${tags_cm:+,}${tags[i]##cm-}"

            if [[ "${tags[i]##cm-}" =~ "settings" ]]; then
                skip_tags_cm=""
            fi
        else
            tags_cb="${tags_cb}${tags_cb:+,}${tags[i]}"

            if [[ "${tags[i]}" =~ "settings" ]]; then
                skip_tags_cb=""
            fi
        fi
    done

    # Run Cloudbox Ansible Playbook
    if [[ ! -z "$tags_cb" ]]; then
        echo "Running Cloudbox Tags: "$tags_cb
        echo ""
        run_playbook_cb $tags_cb $skip_tags_cb
    fi

    # Run Community Ansible Playbook
    if [[ ! -z "$tags_cm" ]]; then
        echo "Running Community Tags: "$tags_cm
        echo ""
        run_playbook_cm $tags_cm $skip_tags_cm
    fi

}

update () {

    declare -A old_object_ids
    declare -A new_object_ids
    config_files=('accounts' 'settings' 'adv_settings' 'backup_config')
    config_files_are_changed=false

    echo -e "Updating Cloudbox...\n"

    cd "${CLOUDBOX_REPO_PATH}"

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

    $config_files_are_changed && run_playbook_cb "settings" && echo -e '\n'

    echo -e "Updating Complete."

}

################################
# Argument Parser
################################

roles=""  # Default to empty role
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
    roles=${@}
    install "${roles}"
    ;;

  *)
    echo "hello"
    ;;
esac
