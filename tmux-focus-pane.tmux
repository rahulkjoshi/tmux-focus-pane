#! /usr/bin/env bash
#! vi: ft=bash

SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/scripts"

TOGGLE_NOTE="Toggle putting pane in focus mode"

tmux bind -N "${TOGGLE_NOTE}" z run-shell "${SCRIPTS_DIR}/main.sh toggle"
tmux bind Z run-shell "${SCRIPTS_DIR}/main.sh pane-tag"
