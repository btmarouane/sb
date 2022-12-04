#!/bin/bash
#########################################################################
# Title:         Saltbox: SB Script                                     #
# Author(s):     desimaniac, chazlarson, salty                          #
# URL:           https://github.com/saltyorg/sb                         #
# --                                                                    #
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
# Scripts
################################

#source /srv/git/sb/yaml.sh
#create_variables /srv/git/saltbox/accounts.yml

################################
# Variables
################################

# Ansible
ANSIBLE_PLAYBOOK_BINARY_PATH="/usr/local/bin/ansible-playbook"

# Saltbox
SALTBOX_REPO_PATH="/srv/git/saltbox"
SALTBOX_PLAYBOOK_PATH="$SALTBOX_REPO_PATH/saltbox.yml"

# Sandbox
SANDBOX_REPO_PATH="/opt/sandbox"
SANDBOX_PLAYBOOK_PATH="$SANDBOX_REPO_PATH/sandbox.yml"

# Saltbox_mod
SALTBOXMOD_REPO_PATH="/opt/saltbox_mod"
SALTBOXMOD_PLAYBOOK_PATH="$SALTBOXMOD_REPO_PATH/saltbox_mod.yml"

# SB
SB_REPO_PATH="/srv/git/sb"

################################
# Functions
################################

git_fetch_and_reset () {

    git fetch --quiet >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard "@{u}" >/dev/null
    git checkout --quiet "${SALTBOX_BRANCH:-master}" >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard "@{u}" >/dev/null
    git submodule update --init --recursive
    chmod 664 "${SALTBOX_REPO_PATH}/ansible.cfg"
    # shellcheck disable=SC2154
    chown -R "${user_name}":"${user_name}" "${SALTBOX_REPO_PATH}"
}

git_fetch_and_reset_sandbox () {

    git fetch --quiet >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard "@{u}" >/dev/null
    git checkout --quiet "${SANDBOX_BRANCH:-master}" >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard "@{u}" >/dev/null
    git submodule update --init --recursive

    if [[ ! -f "${SANDBOX_REPO_PATH}/ansible.cfg" ]]
    then
        cp "${SANDBOX_REPO_PATH}/defaults/ansible.cfg.default" "${SANDBOX_REPO_PATH}/ansible.cfg"
    fi

    chmod 664 "${SANDBOX_REPO_PATH}/ansible.cfg"
    chown -R "${user_name}":"${user_name}" "${SANDBOX_REPO_PATH}"
}

git_fetch_and_reset_sb () {

    git fetch --quiet >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard "@{u}" >/dev/null
    git checkout --quiet master >/dev/null
    git clean --quiet -df >/dev/null
    git reset --quiet --hard "@{u}" >/dev/null
    git submodule update --init --recursive
    chmod 775 "${SB_REPO_PATH}/sb.sh"
}

run_playbook_sb () {

    local arguments=$*

    cd "${SALTBOX_REPO_PATH}" || exit

    # shellcheck disable=SC2086
    "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
        "${SALTBOX_PLAYBOOK_PATH}" \
        --become \
        ${arguments}

    cd - >/dev/null || exit

}

run_playbook_sandbox () {

    local arguments=$*

    cd "${SANDBOX_REPO_PATH}" || exit

    # shellcheck disable=SC2086
    "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
        "${SANDBOX_PLAYBOOK_PATH}" \
        --become \
        ${arguments}

    cd - >/dev/null || exit

}

run_playbook_saltboxmod () {

    local arguments=$*

    cd "${SALTBOXMOD_REPO_PATH}" || exit

    # shellcheck disable=SC2086
    "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
        "${SALTBOXMOD_PLAYBOOK_PATH}" \
        --become \
        ${arguments}

    cd - >/dev/null || exit

}

install () {

    local arg=("$@")

    if [ -z "$arg" ]
    then
      echo -e "No install tag was provided.\n"
      usage
      exit 1
    fi

    echo "${arg[*]}"

    # Remove space after comma
    # shellcheck disable=SC2128,SC2001
    local arg_clean
    arg_clean=${arg//, /,}

    # Split tags from extra arguments
    # https://stackoverflow.com/a/10520842
    local re="^(\S+)\s+(-.*)?$"
    if [[ "$arg_clean" =~ $re ]]; then
        local tags_arg="${BASH_REMATCH[1]}"
        local extra_arg="${BASH_REMATCH[2]}"
    else
        tags_arg="$arg_clean"
    fi

    # Save tags into 'tags' array
    # shellcheck disable=SC2206
    local tags_tmp=(${tags_arg//,/ })

    # Remove duplicate entries from array
    # https://stackoverflow.com/a/31736999
    local tags=()
    readarray -t tags < <(printf '%s\n' "${tags_tmp[@]}" | awk '!x[$0]++')

    # Build SB/Sandbox/Saltbox-mod tag arrays
    local tags_sb
    local tags_sandbox
    local tags_saltboxmod

    for i in "${!tags[@]}"
    do
        if [[ ${tags[i]} == sandbox-* ]]; then
            tags_sandbox="${tags_sandbox}${tags_sandbox:+,}${tags[i]##sandbox-}"

        elif [[ ${tags[i]} == mod-* ]]; then
            tags_saltboxmod="${tags_saltboxmod}${tags_saltboxmod:+,}${tags[i]##mod-}"

        else
            tags_sb="${tags_sb}${tags_sb:+,}${tags[i]}"

        fi
    done
    echo $tags_sandbox
    echo $tags_sb
    exit 1
    # Saltbox Ansible Playbook
    if [[ -n "$tags_sb" ]]; then

        # Build arguments
        local arguments_sb="--tags $tags_sb"

        if [[ -n "$extra_arg" ]]; then
            arguments_sb="${arguments_sb} ${extra_arg}"
        fi

        # Run playbook
        echo ""
        echo "Running Saltbox Tags: ${tags_sb//,/,  }"
        echo ""
        run_playbook_sb "$arguments_sb"
        echo ""

    fi

    # Sandbox Ansible Playbook
    if [[ -n "$tags_sandbox" ]]; then

        # Build arguments
        local arguments_sandbox="--tags $tags_sandbox"

        if [[ -n "$extra_arg" ]]; then
            arguments_sandbox="${arguments_sandbox} ${extra_arg}"
        fi

        # Run playbook
        echo "========================="
        echo ""
        echo "Running Sandbox Tags: ${tags_sandbox//,/,  }"
        echo ""
        run_playbook_sandbox "$arguments_sandbox"
        echo ""
    fi

    # Saltbox_mod Ansible Playbook
    if [[ -n "$tags_saltboxmod" ]]; then

        # Build arguments
        local arguments_saltboxmod="--tags $tags_saltboxmod"

        if [[ -n "$extra_arg" ]]; then
            arguments_saltboxmod="${arguments_saltboxmod} ${extra_arg}"
        fi

        # Run playbook
        echo "========================="
        echo ""
        echo "Running Saltbox_mod Tags: ${tags_saltboxmod//,/,  }"
        echo ""
        run_playbook_saltboxmod "$arguments_saltboxmod"
        echo ""
    fi

}

update () {

    if [[ -d "${SALTBOX_REPO_PATH}" ]]
    then
        echo -e "Updating Saltbox...\n"

        cd "${SALTBOX_REPO_PATH}" || exit

        git_fetch_and_reset

        run_playbook_sb "--tags settings" && echo -e '\n'

        echo -e "Update Completed."
    else
        echo -e "Saltbox folder not present."
    fi

}

sandbox-update () {

    if [[ -d "${SANDBOX_REPO_PATH}" ]]
    then
        echo -e "Updating Sandbox...\n"

        cd "${SANDBOX_REPO_PATH}" || exit

        git_fetch_and_reset_sandbox

        run_playbook_sandbox "--tags settings" && echo -e '\n'

        echo -e "Update Completed."
    fi

}

sb-update () {

    echo -e "Updating sb...\n"

    cd "${SB_REPO_PATH}" || exit

    git_fetch_and_reset_sb

    echo -e "Update Completed."

}

sb-list ()  {

    if [[ -d "${SALTBOX_REPO_PATH}" ]]
    then
        echo -e "Saltbox tags:\n"

        cd "${SALTBOX_REPO_PATH}" || exit

        "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
            "${SALTBOX_PLAYBOOK_PATH}" \
            --become \
            --list-tags --skip-tags "always" 2>&1 | grep "TASK TAGS" | cut -d":" -f2 | awk '{sub(/\[/, "")sub(/\]/, "")}1' | cut -c2-

        echo -e "\n"

        cd - >/dev/null || exit
    else
        echo -e "Saltbox folder not present.\n"
    fi

}

sandbox-list () {

    if [[ -d "${SANDBOX_REPO_PATH}" ]]
    then
        echo -e "Sandbox tags (prepend sandbox-):\n"

        cd "${SANDBOX_REPO_PATH}" || exit
        "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
            "${SANDBOX_PLAYBOOK_PATH}" \
            --become \
            --list-tags --skip-tags "always,sanity_check" 2>&1 | grep "TASK TAGS" | cut -d":" -f2 | awk '{sub(/\[/, "")sub(/\]/, "")}1' | cut -c2-

        echo -e "\n"

        cd - >/dev/null || exit
    fi

}

saltboxmod-list () {

    if [[ -d "${SALTBOXMOD_REPO_PATH}" ]]
    then
        echo -e "Saltbox_mod tags (prepend mod-):\n"

        cd "${SALTBOXMOD_REPO_PATH}" || exit
        "${ANSIBLE_PLAYBOOK_BINARY_PATH}" \
            "${SALTBOXMOD_PLAYBOOK_PATH}" \
            --become \
            --list-tags --skip-tags "always,sanity_check" 2>&1 | grep "TASK TAGS" | cut -d":" -f2 | awk '{sub(/\[/, "")sub(/\]/, "")}1' | cut -c2-

        echo -e "\n"

        cd - >/dev/null || exit
    fi

}

saltbox-branch () {
    if [[ -d "${SALTBOX_REPO_PATH}" ]]
    then
        echo -e "Changing Saltbox branch to $1...\n"

        cd "${SALTBOX_REPO_PATH}" || exit

        SALTBOX_BRANCH=$1

        git_fetch_and_reset

        run_playbook_sb "--tags settings" && echo -e '\n'

        echo -e "Update Completed."
    else
        echo -e "Saltbox folder not present."
    fi
}

sandbox-branch () {

    if [[ -d "${SANDBOX_REPO_PATH}" ]]
    then
        echo -e "Changing Sandbox branch to $1...\n"

        cd "${SANDBOX_REPO_PATH}" || exit

        SANDBOX_BRANCH=$1

        git_fetch_and_reset_sandbox

        run_playbook_sandbox "--tags settings" && echo -e '\n'

        echo -e "Update Completed."
    fi

}

list () {
    sb-list
    sandbox-list
    saltboxmod-list
}

update-ansible () {
    bash "/srv/git/saltbox/scripts/update.sh"
}

usage () {
    echo "Usage:"
    echo "    sb update              Update Saltbox."
    echo "    sb list                List Saltbox tags."
    echo "    sb install <tag>       Install <tag>."
    echo "    sb update-ansible      Re-install Ansible."
}

################################
# Update check
################################

################################
# Argument Parser
################################

# https://sookocheff.com/post/bash/parsing-bash-script-arguments-with-shopts/

roles=""  # Default to empty role

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
subcommand=$1; shift  # Remove 'sb' from the argument list
case "$subcommand" in

  # Parse options to the various sub commands
    list)
        list
        ;;
    update)
        update
        sandbox-update
        ;;
    install)
        roles=${*}
        install "${roles}"
        ;;
    branch)
        saltbox-branch "${*}"
        ;;
    sandbox-branch)
        sandbox-branch "${*}"
        ;;
    update-ansible)
        update-ansible
        ;;
    "") echo "A command is required."
        echo ""
        usage
        exit 1
        ;;
    *)
        echo "Invalid Command: $subcommand"
        echo ""
        usage
        exit 1
        ;;
esac
