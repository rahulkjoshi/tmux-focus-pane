#! /usr/bin/env bash
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "executing command: ${1}" >>/tmp/tmux-focus-pane-debug

if [[ -z "${1}" ]]; then
    exit
fi

"${CURRENT_DIR}/main.sh" "$@"

if [[ $? -eq 2 ]]; then
    tmux display-message '(focus-pane) unknown command'
fi
