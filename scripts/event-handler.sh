#! /usr/bin/env bash
#! vi: ft=bash

focus_window_name="focus"

if [[ -z $( tmux show -gqv @focus-restore-command ) ]]; then
    exit
fi

if [[ "$( tmux list-window -f '#{window_active}' -F "#{==:#W,${focus_window_name}}" )" -eq 1 ]]; then
    if [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_dead}' ) -eq 0 ]]; then
        # Active window and active pane are the focus pane
        exit
    fi
fi

move_flag=''

if [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_left}' ) -eq 1 ]]; then
    move_flag='-L'
elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_right}' ) -eq 1 ]]; then
    move_flag='-R'
elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_top}' ) -eq 1 ]]; then
    move_flag='-U'
elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_bottom}' ) -eq 1 ]]; then
    move_flag='-D'
fi

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

"${CURRENT_DIR}/main.sh" toggle "${move_flag}"
