#! /usr/bin/env bash
#
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

YELLOW='\033[1;33m'

function open_focus() {
    local focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    # Create new window named focus
    tmux new-window -n focus 
    local temp_pane="$( tmux list-panes -t focus -F '#{pane_id}' )"

    # Partition space around focus
    tmux splitw -t focus -h -d -l '10%' ''
    tmux splitw -t focus -h -bd -l '10%' ''
    tmux splitw -t focus -v -bd -l '10%' ''
    tmux splitw -t focus -v -d -l '10%' ''

    # Floating pane with grey border
    tmux set-window-option -t focus pane-border-style 'fg=color0'
    tmux set-window-option -t focus pane-active-border-style 'fg=color250'

    local restore_command="tmux swapp -s '${focus_pane}' -t '${temp_pane}'; tmux killw -t focus"
    tmux set -g @focus-restore-command "${restore_command}"
    tmux swapp -s "${focus_pane}" -t "${temp_pane}"
    # tmux pipep -t "${temp_pane}" -I "echo 'clear'"

    # tmux set-option -og 'window-pane-changed[13]' "run_shell '/usr/bin/env bash ${CURRENT_DIR}/toggle-focus.sh'; set-option -ug 'window-pange-changed[13]'"
}

open_focus
