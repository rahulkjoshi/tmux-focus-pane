#! /usr/bin/env bash
#! vi: ft=bash

FOCUS_WINDOW_NAME="focus"

INACTIVE_PANE_BORDER_FMT="fg=color0"
ACTIVE_PANE_BORDER_FMT="fg=color250"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function toggle_focus() {
    local direction="${1}"
    local restore_command
    restore_command="$( tmux show -gqv @focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        open_focus
    else
        reset_focus "${direction}"
    fi
}

function toggle_pane_tag {
    local focus_pane
    focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    local pane_list
    pane_list="$( tmux show -gqv @focus-tagged-panes )"

    if [[ ! "${pane_list}" =~ $focus_pane(,|$) ]]; then
        if [[ -n "${pane_list}" ]]; then
            pane_list="${pane_list},${focus_pane}"
        else
            pane_list="${focus_pane}"
        fi
    else
        pane_list="$( echo "${pane_list}" | sed -E "s/^${focus_pane},?|,?${focus_pane}//" )"
    fi
    tmux set -g '@focus-tagged-panes' "${pane_list}"
}

function open_focus() {
    local focus_pane
    focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    tmux set -g @focus-pane "${focus_pane}"
    # Create new window named focus
    tmux new-window -n ${FOCUS_WINDOW_NAME} >> /tmp/focus-pane-debug 2>&1
    draw_focus_window

    local temp_pane
    temp_pane="$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -F '#{pane_id}' -f '#{pane_active}' )"
    local restore_command="tmux swapp -s '${focus_pane}' -t '${temp_pane}'; tmux killw -t ${FOCUS_WINDOW_NAME}"
    tmux set -g @focus-restore-command "${restore_command}" >> /tmp/focus-pane-debug 2>&1
    tmux swapp -s "${focus_pane}" -t "${temp_pane}" >> /tmp/focus-pane-debug 2>&1
    tmux pipep -t "${temp_pane}" -I "echo 'clear'"
}

function draw_focus_window() {
    if [[ "$( tmux list-panes -t ${FOCUS_WINDOW_NAME} | wc -l )" -ne 1 ]]; then
       tmux kill-pane -a -t "$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -F '#{pane_id}' -f '#{pane_active}' )"
    fi
    local temp_pane
    temp_pane="$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -F '#{pane_id}' )"
    local h_gutter
    local v_gutter
    IFS=',' read -r h_gutter v_gutter <<< "$( "${CURRENT_DIR}/calc.pl" )"

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
    local direction="${1}"
    if [[! "${direction}" =~ -L|-R|-U|-D ]]; then
        tmux display-message "unknown direction ${direction}"
        return 1
    fi
    local restore_command
    restore_command="$( tmux show -gqv @focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        tmux display-message "found no saved restore command"
    fi
    local focus_pane
    focus_pane=$( tmux show -gqv @focus-pane )
    tmux set -ug @focus-restore-command
    tmux set -ug @focus-pane
    eval "${restore_command}"
    if [[ -n "${direction}" ]]; then
        tmux select-pane -t "${focus_pane}" "${direction}"
    fi
}

function install_hooks() {
    tmux set-option -og 'window-pane-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh'" >> /tmp/focus-pane-debug 2>&1
    tmux set-option -og 'session-window-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh'" >> /tmp/focus-pane-debug 2>&1
}

function remove_hooks() {
    tmux set-option -ug 'window-pane-changed[13]'
    tmux set-option -ug 'session-window-changed[13]'
}

function usage() {
    tmux display-message "available commands: [toggle | install-hooks | remove-hooks | pane-tag | usage]"
}

cmd=''
arg1=''
while [[ -n "$*" ]]; do 
    case $1 in
        toggle )
            cmd='toggle_focus'
            ;;
        install-hooks )
            cmd='install_hooks'
            ;;
        remove-hooks )
            cmd='remove_hooks'
            ;;
        pane-tag )
            cmd='toggle_pane_tag'
            ;;
        list|usage )
            cmd='usage'
            ;;
        * )
            arg1="${1}"
            ;;
    esac
    shift
done

if [[ -z "${cmd}" ]]; then
    exit 2
fi

"${cmd}" "${arg1}"
