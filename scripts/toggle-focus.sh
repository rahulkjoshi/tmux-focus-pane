#! /usr/bin/env bash
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function toggle_focus() {
    local restore_command="$( tmux show -gqv @focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        /usr/bin/env bash ${CURRENT_DIR}/open-focus.sh
    else
        /usr/bin/env bash ${CURRENT_DIR}/reset-focus.sh
    fi
}

# tmux display-message "${CURRENT_DIR}"

toggle_focus
