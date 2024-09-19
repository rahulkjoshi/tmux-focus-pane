#! /usr/bin/env bash
#! vi: ft=bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/scripts"

TOGGLE_NOTE="Toggle putting pane in focus mode"
TAG_NOTE="Tag the selected pane for auto-focus"
COMMAND_NOTE="Enter focus-pane command"

COMMAND_PROMPT="(focus-pane) Enter command (or press enter to cancel):"

"${SCRIPTS_DIR}/main.sh" install-hooks

tmux bind -N "${TOGGLE_NOTE}" z run-shell "${SCRIPTS_DIR}/main.sh toggle"
tmux bind -N "${TAG_NOTE}" Z run-shell "${SCRIPTS_DIR}/main.sh pane-tag"
tmux bind -N "${COMMAND_NOTE}" M-f command-prompt -p "${COMMAND_PROMPT}" "run-shell \"${SCRIPTS_DIR}/command-invoke.sh %%\""
