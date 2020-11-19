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

################################
# Privilege Escalation
################################

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

    local arguments="$@"

    echo "" > "${CLOUDBOX_LOGFILE_PATH}"

    cd "${CLOUDBOX_REPO_PATH}"

    "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
        "${CLOUDBOX_PLAYBOOK_PATH}" \
        --become \
        ${arguments}

    cd - >/dev/null

}

run_playbook_cm () {

    local arguments="$@"

    echo "" > "${COMMUNITY_LOGFILE_PATH}"

    cd "${COMMUNITY_REPO_PATH}"
    "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
        "${COMMUNITY_PLAYBOOK_PATH}" \
        --become \
        ${arguments}

    cd - >/dev/null

}

install () {

    local arg=("$@")

    # Remove space after comma
    arg_clean=$(sed -e 's/, /,/g' <<< "$arg")

    # Split tags from extra arguments
    # https://stackoverflow.com/a/10520842
    re="^(\S+)\s+(-.*)?$"
    if [[ "$arg_clean" =~ $re ]]; then
        tags_arg="${BASH_REMATCH[1]}"
        extra_arg="${BASH_REMATCH[2]}"
    else
        tags_arg="$arg_clean"
    fi

    # Save tags into 'tags' array
    tags_tmp=(${tags_arg//,/ })

    # Remove duplicate entries from array
    # https://stackoverflow.com/a/31736999
    readarray -t tags < <(printf '%s\n' "${tags_tmp[@]}" | awk '!x[$0]++')

    # Build CB/CM tag arrays
    local tags_cb
    local tags_cm
    local skip_settings_in_cb=false
    local skip_settings_in_cm=false

    for i in "${!tags[@]}"
    do
        if [[ ${tags[i]} == cm-* ]]; then
            tags_cm="${tags_cm}${tags_cm:+,}${tags[i]##cm-}"

            if [[ "${tags[i]##cm-}" =~ "settings" ]]; then
                skip_settings_in_cm=false
            fi
        else
            tags_cb="${tags_cb}${tags_cb:+,}${tags[i]}"

            if [[ "${tags[i]}" =~ "settings" ]]; then
                skip_settings_in_cb=false
            fi
        fi
    done

    # Cloudbox Ansible Playbook
    if [[ ! -z "$tags_cb" ]]; then

        # Build arguments
        local arguments_cb="--tags $tags_cb"

        if [ "$skip_settings_in_cb" = true ]; then
            arguments_cb="${arguments_cb} --skip-tags settings"
        fi

        if [[ ! -z "$extra_arg" ]]; then
            arguments_cb="${arguments_cb} ${extra_arg}"
        fi

        # Run playbook
        echo ""
        echo "Running Cloudbox Tags: "${tags_cb//,/,  }
        echo ""
        run_playbook_cb $arguments_cb
        echo ""

    fi

    # Community Ansible Playbook
    if [[ ! -z "$tags_cm" ]]; then

        # Build arguments
        local arguments_cm="--tags $tags_cm"

        if [ "$skip_settings_in_cm" = true ]; then
            arguments_cm="${arguments_cm} --skip-tags settings"
        fi

        if [[ ! -z "$extra_arg" ]]; then
            arguments_cm="${arguments_cm} ${extra_arg}"
        fi

        # Run playbook
        echo "========================="
        echo ""
        echo "Running Community Tags: "${tags_cm//,/,  }
        echo ""
        run_playbook_cm $arguments_cm
        echo ""
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

    $config_files_are_changed && run_playbook_cb "--tags settings" && echo -e '\n'

    echo -e "Updating Complete."

}

usage () {
    echo "Usage:"
    echo "    cb [-h]                Display this help message."
    echo "    cb install <package>   Install <package>."
    echo "    cb update              Update Cloudbox project folder."
}

################################
# Argument Parser
################################

# https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/

roles=""  # Default to empty role
target=""  # Default to empty target

# Parse options
while getopts ":h" opt; do
  case ${opt} in
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
shift $((OPTIND -1))

# Parse commands
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
    "") echo "A command is required."
        echo ""
        usage
        exit 1
        ;;
    *)
        echo "Invalid Command: ${@}" 1>&2
        echo ""
        usage
        exit 1
        ;;
esac
