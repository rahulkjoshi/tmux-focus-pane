#! /usr/bin/env bash
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
focus_window_name="focus"

HOOK_NAME=''

# Triggers the de-focus because panes or windows were switched.
function defocus() {
    local focus_pane
    focus_pane=$(tmux show -gqv @tmux-focus-pane)

    local move_flag=''

    if [[ "$( tmux list-window -f '#{window_active}' -F "#{==:#W,${focus_window_name}}" )" -eq 1 ]]; then
        if [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F "#{==:#D,${focus_pane}}" ) -eq 1 ]]; then
            # Active window and active pane are the focus pane
            exit
        fi

        # Order matters. Check left and right first because they span the full
        # height.
        if [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_left}' ) -eq 1 ]]; then
            move_flag='--pane_direction=-L'
        elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_right}' ) -eq 1 ]]; then
            move_flag='--pane_direction=-R'
        elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_top}' ) -eq 1 ]]; then
            move_flag='--pane_direction=-U'
        elif [[ $( tmux list-pane -t "${focus_window_name}" -f '#{pane_active}' -F '#{pane_at_bottom}' ) -eq 1 ]]; then
            move_flag='--pane_direction=-D'
        fi
    fi

    local hook_name="--hook_name=$HOOK_NAME"

    echo "defocus: calling focus '${hook_name}' '${move_flag}'" >> /tmp/tmux-focus-pane-debug
    "${CURRENT_DIR}/main.sh" focus "${hook_name}" "${move_flag}"
}

# Triggers focus action if switched to a pane tagged for auto focus.
function auto_focus() {
    local hook_name="--hook_name=$HOOK_NAME"

    local pane_list
    pane_list="$( tmux show -gqv @tmux-focus-tagged-panes )"
    local curr_focus
    curr_focus="$( tmux list-panes -F '#D' -f '#{pane_active}' )"

    if [[ "${pane_list}" =~ $curr_focus(,|$) ]]; then
        echo "auto_focus: calling focus '${hook_name}'"  >> /tmp/tmux-focus-pane-debug
        "${CURRENT_DIR}/main.sh" focus "$hook_name"
    fi
}

# Triggers resize action on window resize.
function resize() {
    local hook_name="--hook_name=$HOOK_NAME"
    echo "resize: calling resize '${hook_name}'"  >> /tmp/tmux-focus-pane-debug
    "${CURRENT_DIR}/main.sh" resize "$hook_name"
}

if [[ -z "$1" ]]; then
    tmux display "tmux-focus-pane/event-handler.sh: unset arg0: hook_name"
    exit 2
else
    HOOK_NAME="$1"
fi

if [[ -z $( tmux show -gqv @tmux-focus-restore-command ) ]]; then
    auto_focus
else
    if [[ "${HOOK_NAME}" = "window-resized" ]]; then
        resize
    else
        defocus
    fi
fi
