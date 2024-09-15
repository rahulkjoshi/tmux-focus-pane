#! /usr/bin/env bash
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

YELLOW='\033[1;33m'

function open_focus() {
    local focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    # Create new window named focus
    tmux new-window -n focus >> /tmp/focus-pane-debug 2>&1
    local temp_pane="$( tmux list-panes -t focus -F '#{pane_id}' )"

    local h_gutter
    local v_gutter
    IFS=',' read h_gutter v_gutter <<< "$( $CURRENT_DIR/calc.pl )"

    # Partition space around focus
    # Left and right
    if [[ "${h_gutter}" -ne 0 ]]; then
        tmux splitw -t focus -h -d -l "${h_gutter}" '' >> /tmp/focus-pane-debug 2>&1
        tmux splitw -t focus -h -bd -l "${h_gutter}" '' >> /tmp/focus-pane-debug 2>&1
    fi
    # Top and bottom
    if [[ "${v_gutter}" -ne 0 ]]; then
        tmux splitw -t focus -v -d -l "${v_gutter}" '' >> /tmp/focus-pane-debug 2>&1
        tmux splitw -t focus -v -bd -l "${v_gutter}" '' >> /tmp/focus-pane-debug 2>&1
    fi

    # Floating pane with grey border
    tmux set-window-option -t focus pane-border-style 'fg=color0' >> /tmp/focus-pane-debug 2>&1
    tmux set-window-option -t focus pane-active-border-style 'fg=color250' >> /tmp/focus-pane-debug 2>&1

    local restore_command="tmux swapp -s '${focus_pane}' -t '${temp_pane}'; tmux killw -t focus"
    tmux set -g @focus-restore-command "${restore_command}" >> /tmp/focus-pane-debug 2>&1
    tmux swapp -s "${focus_pane}" -t "${temp_pane}" >> /tmp/focus-pane-debug 2>&1
    # tmux pipep -t "${temp_pane}" -I "echo 'clear'"

    # tmux set-option -og 'window-pane-changed[13]' "run_shell '/usr/bin/env bash ${CURRENT_DIR}/toggle-focus.sh'; set-option -ug 'window-pange-changed[13]'"
}

open_focus
