#! /usr/bin/env bash
#! vi: ft=bash

FOCUS_WINDOW_NAME="focus"

if [[ "$( tmux list-window -f '#{==:#W,${FOCUS_WINDOW_NAME}}' | wc -l )" -eq 0 ]]; then
    exit
fi

if [[ "$( tmux list-window -f '#{window_active}' -F "#{==:#W,${FOCUS_WINDOW_NAME}}" )" -eq 1 ]]; then
    if [[ $( tmux list-pane -t ${FOCUS_WINDOW_NAME} -f '#{pane_active}' -F '#{pane_dead}' ) -eq 0 ]]; then 
        # Active window and active pane are the focus pane
        exit
    fi
fi

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

${CURRENT_DIR}/main.sh remove-hooks
${CURRENT_DIR}/main.sh toggle
