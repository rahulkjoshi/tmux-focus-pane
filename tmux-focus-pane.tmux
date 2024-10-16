#! /usr/bin/env bash
#! vi: ft=bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/scripts"

function install()  {
    TOGGLE_NOTE="Toggle putting pane in focus mode"
    TAG_NOTE="Tag the selected pane for auto-focus"
    COMMAND_NOTE="Enter focus-pane command"

    COMMAND_PROMPT="(focus-pane) Enter command ('usage' or <enter> to cancel):"

    local install_hooks
    install_hooks=$( tmux show -gqv @tmux-focus-install-hooks )
    install_hooks="${install_hooks:-false}"
    if [[ "${install_hooks}" == "true" ]]; then
        "${SCRIPTS_DIR}/main.sh" install-hooks
    fi

    local install_resize_hooks
    install_resize_hooks=$( tmux show -gqv @tmux-focus-install-resize-hooks )
    install_resize_hooks="${install_resize_hooks:-false}"
    if [[ "${install_resize_hooks}" == "true" ]]; then
        "${SCRIPTS_DIR}/main.sh" install-resize-hooks
    fi

    local toggle_key
    toggle_key=$( tmux show -gqv @tmux-focus-toggle )
    toggle_key=${toggle_key:-z}

    local toggle_tag_key
    toggle_tag_key=$( tmux show -gqv @tmux-focus-tag )
    toggle_tag_key=${toggle_tag_key:-Z}

    local command_key
    command_key=$( tmux show -gqv @tmux-focus-command-invoke )
    command_key=${command_key:-M-f}

    tmux bind -N "${TOGGLE_NOTE}" "${toggle_key}" run-shell "${SCRIPTS_DIR}/main.sh toggle"
    tmux bind -N "${TAG_NOTE}" "${toggle_tag_key}" run-shell "${SCRIPTS_DIR}/main.sh pane-tag"
    tmux bind -N "${COMMAND_NOTE}" "${command_key}" command-prompt -p "${COMMAND_PROMPT}" "run-shell \"${SCRIPTS_DIR}/command-invoke.sh %%\""
}

install
