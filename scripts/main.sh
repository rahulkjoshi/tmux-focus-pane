#! /usr/bin/env bash
#! vi: ft=bash

FOCUS_WINDOW_NAME="focus"

INACTIVE_PANE_BORDER_FMT="fg=color0"
ACTIVE_PANE_BORDER_FMT="fg=color250"

# Set by parsing flags
HOOK_NAME=''
PANE_DIRECTION=''

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function toggle_focus() {
    local restore_command
    restore_command="$( tmux show -gqv @tmux-focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        open_focus
    else
        reset_focus
    fi
}

function toggle_pane_tag {
    local focus_pane
    focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    local pane_list
    pane_list="$( tmux show -gqv @tmux-focus-tagged-panes )"

    if [[ ! "${pane_list}" =~ $focus_pane(,|$) ]]; then
        if [[ -n "${pane_list}" ]]; then
            pane_list="${pane_list},${focus_pane}"
        else
            pane_list="${focus_pane}"
        fi
    else
        pane_list="$( echo "${pane_list}" | sed -E "s/^${focus_pane},?|,?${focus_pane}//" )"
    fi
    tmux set -g '@tmux-focus-tagged-panes' "${pane_list}"
}

function list_pane_tags() {
    local pane_list
    pane_list="$( tmux show -gqv @tmux-focus-tagged-panes | sed -e 's/\%/%%/g' | sed -e 's/,/ /g')"

    tmux display-message "Auto-focus panes: [${pane_list}]"
}

function open_focus() {
    local focus_pane
    focus_pane="$( tmux list-panes -F '#D' -f '#{pane_active}' )"
    tmux set -g @tmux-focus-pane "${focus_pane}"
    # Create new window named focus
    tmux new-window -n ${FOCUS_WINDOW_NAME} >> /tmp/tmux-focus-pane-debug 2>&1
    draw_focus_window

    local temp_pane
    temp_pane="$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -F '#{pane_id}' -f '#{pane_active}' )"
    local restore_command="tmux swapp -s '${focus_pane}' -t '${temp_pane}'; tmux killw -t ${FOCUS_WINDOW_NAME}"
    tmux set -g @tmux-focus-restore-command "${restore_command}" >> /tmp/tmux-focus-pane-debug 2>&1
    tmux swapp -s "${focus_pane}" -t "${temp_pane}" >> /tmp/tmux-focus-pane-debug 2>&1
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
        {
            tmux splitw -t ${FOCUS_WINDOW_NAME} -h -d -l "${h_gutter}" ''
            tmux splitw -t ${FOCUS_WINDOW_NAME} -h -bd -l "${h_gutter}" ''
        } >> /tmp/tmux-focus-pane-debug 2>&1
    fi
    # Top and bottom
    if [[ "${v_gutter}" -ne 0 ]]; then
        {
            tmux splitw -t ${FOCUS_WINDOW_NAME} -v -d -l "${v_gutter}" ''
            tmux splitw -t ${FOCUS_WINDOW_NAME} -v -bd -l "${v_gutter}" ''
        } >> /tmp/tmux-focus-pane-debug 2>&1
    fi

    {
        # Floating pane with grey border
        tmux set-window-option -t ${FOCUS_WINDOW_NAME} pane-border-style "${INACTIVE_PANE_BORDER_FMT}"
        tmux set-window-option -t ${FOCUS_WINDOW_NAME} pane-active-border-style "${ACTIVE_PANE_BORDER_FMT}"
    } >> /tmp/tmux-focus-pane-debug 2>&1
}

function reset_focus() {
    local restore_command
    restore_command="$( tmux show -gqv @tmux-focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        echo "found no saved restore command" >> /tmp/tmux-focus-pane-debug
        tmux display "tmux-focus-pane/main.sh:reset_focus: found no saved restore command"
    fi

    local focus_pane
    focus_pane=$( tmux show -gqv @tmux-focus-pane )
    tmux set -ug @tmux-focus-restore-command
    tmux set -ug @tmux-focus-pane

    local curr_focus
    curr_focus=$( tmux list-pane -f '#{pane_active}' -F '#D' )
    if [[ "$curr_focus" = "$focus_pane" ]]; then
        eval "${restore_command}"
        return
    elif [[ -n "${PANE_DIRECTION}" ]]; then
        {
            eval "${restore_command}"
            tmux select-pane -t "${focus_pane}" "${PANE_DIRECTION}"
        } >> /tmp/tmux-focus-pane-debug 2>&1
        return
    else
        # if it's not a hook, then we should swap for the temp
        eval "${restore_command}" >> /tmp/tmux-focus-pane-debug 2>&1
        return
    fi
    # local restore_command="tmux swapp -s '${focus_pane}' -t '${temp_pane}'; tmux killw -t ${FOCUS_WINDOW_NAME}"
}

function install_hooks() {
    tmux set -g 'window-pane-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh #{hook}'" >> /tmp/tmux-focus-pane-debug 2>&1
    tmux set -g 'session-window-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh #{hook}'" >> /tmp/tmux-focus-pane-debug 2>&1
}

function remove_hooks() {
    tmux set -ug 'window-pane-changed[13]'
    tmux set -ug 'session-window-changed[13]'
}

function usage() {
    tmux display "available commands: [toggle | install-hooks | remove-hooks | pane-tag | list-pane-tags | usage]"
}

cmd=''
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
        list-pane-tags )
            cmd='list_pane_tags'
            ;;
        list|usage )
            cmd='usage'
            ;;
        --hook_name=* )
            if [[ -z "${HOOK_NAME}" ]]; then
                HOOK_NAME="${1/--hook_name=/}"
            else
                message="--hook_name specified more than once"
                echo "${message}" >> /tmp/tmux-focus-pane-debug
                tmux display "tmux-focus-pane/main.sh: ${message}"
                exit 2
            fi
            ;;
        --pane_direction=* )
            if [[ -z "${PANE_DIRECTION}" ]]; then
                PANE_DIRECTION="${1/--pane_direction=/}"
            else
                message="--pane_direction specified more than once"
                echo "${message}" >> /tmp/tmux-focus-pane-debug
                tmux display "tmux-focus-pane/main.sh: ${message}"
                exit 2
            fi
            if [[ ! "${PANE_DIRECTION}" =~ -L|-R|-U|-D ]]; then
                message="--pane_direction='${PANE_DIRECTION}'. Expected one of [-L | -R | -U | -D ]."
                echo "${message}" >> /tmp/tmux-focus-pane-debug
                tmux display "tmux-focus-pane/main.sh: ${message}"
                exit 2
            fi
            ;;
        * )
            message="Unknown argument $1"
            echo  "${message}" >> /tmp/tmux-focus-pane-debug
            tmux display "tmux-focus-pane/main.sh: ${message}"
            exit 2
            ;;
    esac
    shift
done

if [[ -z "${cmd}" ]]; then
    tmux display "tmux-focus-pane/main.sh: Missing command"
    exit 2
fi

"${cmd}"
