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
    if [[ -z "$( tmux show -gqv @tmux-focus-restore-command )" ]]; then
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

    local temp_pane
    temp_pane=$( draw_focus_window )
    tmux set -g @tmux-focus-temp-pane "${temp_pane}"

    local restore_command="tmux swapp -s '${focus_pane}' -t '${temp_pane}'; tmux killw -t ${FOCUS_WINDOW_NAME}"
    tmux set -g @tmux-focus-restore-command "${restore_command}" >> /tmp/tmux-focus-pane-debug 2>&1
    tmux swapp -s "${focus_pane}" -t "${temp_pane}" >> /tmp/tmux-focus-pane-debug 2>&1

    local cow
    if ( cowsay >/dev/null 2>&1 ); then
        cow=";cowsay 'This is a temporary pane.'"
    fi
    tmux send -t "${temp_pane}" "clear${cow}" Enter >> /tmp/tmux-focus-pane-debug 2>&1
}

function calc_out() {
    local aspect_h
    aspect_h=$( tmux show -gqv @tmux-focus-horizontal-aspect )
    aspect_h=${aspect_h:-3}
    local aspect_v
    aspect_v=$( tmux show -gqv @tmux-focus-vertical-aspect )
    aspect_v=${aspect_v:-4}

    "${CURRENT_DIR}/calc.pl" --aspect_h="${aspect_h}" --aspect_v="${aspect_v}"
}

function draw_focus_window() {
    local temp_pane
    local live_panes
    live_panes=$( tmux list-panes -t ${FOCUS_WINDOW_NAME} -f '#{?pane_dead,0,1}' -F '#D' )
    if (( $( echo "${live_panes}" | wc -l ) != 1 )); then
        temp_pane=$( tmux splitw -t "${FOCUS_WINDOW_NAME}" -h -P -F '#D' )
    else
        temp_pane="$live_panes"
    fi
    tmux kill-pane -a -t "${temp_pane}"
    [[ -z "${HOOK_NAME}" ]] && echo "${temp_pane}"

    local h_gutter
    local v_gutter
    IFS=',' read -r h_gutter v_gutter <<< "$( calc_out )"

    # Partition space around focus
    # Left and right
    if [[ "${h_gutter}" -ne 0 ]]; then
        tmux splitw -t "${temp_pane}" -hd -l "${h_gutter}" '' >>/tmp/tmux-focus-pane-debug 2>&1
        tmux splitw -t "${temp_pane}" -hdb -l "${h_gutter}" '' >>/tmp/tmux-focus-pane-debug 2>&1
    fi
    # Top and bottom
    if [[ "${v_gutter}" -ne 0 ]]; then
        tmux splitw -t "${temp_pane}" -vd -l "${v_gutter}" '' >> /tmp/tmux-focus-pane-debug 2>&1
        tmux splitw -t "${temp_pane}" -vdb -l "${v_gutter}" '' >> /tmp/tmux-focus-pane-debug 2>&1
    fi

    # Floating pane with grey border
    tmux setw -t ${FOCUS_WINDOW_NAME} 'pane-border-style' "${INACTIVE_PANE_BORDER_FMT}" >> /tmp/tmux-focus-pane-debug 2>&1
    tmux setw -t ${FOCUS_WINDOW_NAME} 'pane-active-border-style' "${ACTIVE_PANE_BORDER_FMT}" >> /tmp/tmux-focus-pane-debug 2>&1
}

function reset_focus() {
    local restore_command
    restore_command="$( tmux show -gqv @tmux-focus-restore-command )"
    if [[ -z "${restore_command}" ]]; then
        echo "found no saved restore command" >> /tmp/tmux-focus-pane-debug
        tmux display "tmux-focus-pane/main.sh:reset_focus: found no saved restore command"
    fi
    tmux set -ug @tmux-focus-restore-command

    local focus_pane
    focus_pane=$( tmux show -gqv @tmux-focus-pane )
    local temp_pane
    temp_pane=$( tmux show -gqv @tmux-focus-temp-pane )
    tmux set -ug @tmux-focus-pane
    tmux set -ug @tmux-focus-temp-pane

    local curr_focus
    curr_focus=$( tmux list-pane -f '#{pane_active}' -F '#D' )

    if [[ "$curr_focus" = "$focus_pane" || "$curr_focus" = "$temp_pane" ]]; then
        eval "${restore_command}" >> /tmp/tmux-focus-pane-debug 2>&1
        return
    elif [[ -n "${PANE_DIRECTION}" ]]; then
        eval "${restore_command}" >> /tmp/tmux-focus-pane-debug 2>&1
        tmux select-pane -t "${focus_pane}" "${PANE_DIRECTION}" >> /tmp/tmux-focus-pane-debug 2>&1
        return
    elif [[ -n "${HOOK_NAME}" ]]; then
        eval "${restore_command}" >> /tmp/tmux-focus-pane-debug 2>&1
        return
    else
        tmux swapp -s "${focus_pane}" -t "${temp_pane}" -d >> /tmp/tmux-focus-pane-debug 2>&1
        tmux swapp -s "${temp_pane}" -t "${curr_focus}" >> /tmp/tmux-focus-pane-debug 2>&1
        tmux selectw -t "${FOCUS_WINDOW_NAME}"

        local restore_command="tmux swapp -s '${curr_focus}' -t '${temp_pane}'; tmux killw -t ${FOCUS_WINDOW_NAME}"
        tmux set -g @tmux-focus-restore-command "${restore_command}" >> /tmp/tmux-focus-pane-debug 2>&1
        tmux set -g @tmux-focus-pane "${curr_focus}"
        tmux set -g @tmux-focus-temp-pane "${temp_pane}"
        return
    fi
}

function install_resize_hooks() {
    tmux set -g 'window-resized[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh #{hook}'" >> /tmp/tmux-focus-pane-debug 2>&1
}

function remove_resize_hooks() {
    tmux set -ug 'window-resized[13]' >> /tmp/tmux-focus-pane-debug 2>&1
}

function install_hooks() {
    tmux set -g 'window-pane-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh #{hook}'" >> /tmp/tmux-focus-pane-debug 2>&1
    tmux set -g 'session-window-changed[13]' "run-shell '/usr/bin/env bash ${CURRENT_DIR}/event-handler.sh #{hook}'" >> /tmp/tmux-focus-pane-debug 2>&1
}

function remove_hooks() {
    tmux set -ug 'window-pane-changed[13]' >> /tmp/tmux-focus-pane-debug 2>&1
    tmux set -ug 'session-window-changed[13]' >> /tmp/tmux-focus-pane-debug 2>&1
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
        resize )
            cmd='draw_focus_window'
            ;;
        install-resize-hooks )
            cmd='install_resize_hooks'
            ;;
        remove-resize-hooks )
            cmd='remove_resize_hooks'
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
