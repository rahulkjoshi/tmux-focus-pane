#! /usr/bin/env bash
#! vi: ft=bash

function reset_focus() {
    local restore_command="$( tmux show -gqv @focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        tmux display-message "found no saved restore command"
    fi
    tmux set -ug @focus-restore-command
    eval "${restore_command}"
}

reset_focus
