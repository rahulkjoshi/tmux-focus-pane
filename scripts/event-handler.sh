#! /usr/bin/env bash
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
focus_window_name="focus"

function defocus() {
    if [[ "$( tmux list-window -f '#{window_active}' -F "#{==:#W,${focus_window_name}}" )" -eq 1 ]]; then
        if [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_dead}' ) -eq 0 ]]; then
            # Active window and active pane are the focus pane
            exit
        fi
    fi

    local move_flag=''

    if [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_left}' ) -eq 1 ]]; then
        move_flag='-L'
    elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_right}' ) -eq 1 ]]; then
        move_flag='-R'
    elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_top}' ) -eq 1 ]]; then
        move_flag='-U'
    elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_bottom}' ) -eq 1 ]]; then
        move_flag='-D'
    fi

    "${CURRENT_DIR}/main.sh" toggle "${move_flag}"
}

function refocus() {
    local pane_list
    pane_list="$( tmux show -gqv @focus-tagged-panes )"
    local focus_pane
    focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"

    if [[ "${pane_list}" =~ $focus_pane(,|$) ]]; then
        "${CURRENT_DIR}/main.sh" toggle
    fi
}

function main() {
    if [[ -z $( tmux show -gqv @focus-restore-command ) ]]; then
        refocus
    else
        defocus
    fi
}

main
