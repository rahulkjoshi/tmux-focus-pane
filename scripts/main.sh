#! /usr/bin/env bash
#! vi: ft=bash

INSTALL_RESET_HOOK=true
FOCUS_WINDOW_NAME="focus"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function toggle_focus() {
    local restore_command="$( tmux show -gqv @focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        open_focus
    else
        reset_focus
    fi
}

function toggle_pane_tag {
    local focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    local pane_list="$( tmux show -gqv @focus-tagged-panes )"

    if [[ ! "${pane_list}" =~ $focus_pane(,|$) ]]; then
        if [[ -n "${pane_list}" ]]; then
            pane_list="${pane_list},${focus_pane}"
        else
            pane_list="${focus_pane}"
        fi
    else
        pane_list="$( echo ${pane_list} | sed -E "s/^${focus_pane},?|,?${focus_pane}//" )"
    fi
    tmux set -g '@focus-tagged-panes' "${pane_list}"
}

function open_focus() {
    local focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    # Create new window named focus
    tmux new-window -n ${FOCUS_WINDOW_NAME} >> /tmp/focus-pane-debug 2>&1
    draw_focus_window

    local temp_pane="$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -F '#{pane_id}' -f '#{pane_active}' )"
    local restore_command="tmux swapp -s '${focus_pane}' -t '${temp_pane}'; tmux killw -t ${FOCUS_WINDOW_NAME}"
    tmux set -g @focus-restore-command "${restore_command}" >> /tmp/focus-pane-debug 2>&1
    tmux swapp -s "${focus_pane}" -t "${temp_pane}" >> /tmp/focus-pane-debug 2>&1
    tmux pipep -t "${temp_pane}" -I "echo 'clear'"

    # Event hooks to invoke handler when window or pane is changed
    if [[ "${INSTALL_RESET_HOOK}" == "true" ]]; then
        tmux set-option -og 'window-pane-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh'"
        tmux set-option -og 'session-window-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh'"
    fi
}

INACTIVE_PANE_BORDER_FMT="fg=color0"
ACTIVE_PANE_BORDER_FMT="fg=color250"

function draw_focus_window() {
    if [[ "$( tmux list-panes -t ${FOCUS_WINDOW_NAME} | wc -l )" -ne 1 ]]; then
       tmux kill-pane -a -t "$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -F '#{pane_id}' -f '#{pane_active}' )"
    fi
    local temp_pane="$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -F '#{pane_id}' )"
    local h_gutter
    local v_gutter
    IFS=',' read h_gutter v_gutter <<< "$( $CURRENT_DIR/calc.pl )"

    # Partition space around focus
    # Left and right
    if [[ "${h_gutter}" -ne 0 ]]; then
        tmux splitw -t ${FOCUS_WINDOW_NAME} -h -d -l "${h_gutter}" '' >> /tmp/focus-pane-debug 2>&1
        tmux splitw -t ${FOCUS_WINDOW_NAME} -h -bd -l "${h_gutter}" '' >> /tmp/focus-pane-debug 2>&1
    fi
    # Top and bottom
    if [[ "${v_gutter}" -ne 0 ]]; then
        tmux splitw -t ${FOCUS_WINDOW_NAME} -v -d -l "${v_gutter}" '' >> /tmp/focus-pane-debug 2>&1
        tmux splitw -t ${FOCUS_WINDOW_NAME} -v -bd -l "${v_gutter}" '' >> /tmp/focus-pane-debug 2>&1
    fi

    # Floating pane with grey border
    tmux set-window-option -t ${FOCUS_WINDOW_NAME} pane-border-style "${INACTIVE_PANE_BORDER_FMT}" >> /tmp/focus-pane-debug 2>&1
    tmux set-window-option -t ${FOCUS_WINDOW_NAME} pane-active-border-style "${ACTIVE_PANE_BORDER_FMT}" >> /tmp/focus-pane-debug 2>&1
}

function reset_focus() {
    local restore_command="$( tmux show -gqv @focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        tmux display-message "found no saved restore command"
    fi
    remove_hooks
    tmux set -ug @focus-restore-command
    eval "${restore_command}"
}

function remove_hooks() {
    tmux set-option -ug 'window-pane-changed[13]'
    tmux set-option -ug 'session-window-changed[13]'
}

while [[ -n "$*" ]]; do 
    case $1 in
        toggle )
            toggle_focus
            ;;
        remove-hooks )
            remove_hooks
            ;;
        pane-tag )
            toggle_pane_tag
            ;;
    esac
    shift
done
