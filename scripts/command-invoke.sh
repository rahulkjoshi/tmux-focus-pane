#! /usr/bin/env bash
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "found ${1}" >>/tmp/focus-pane-debug

if [[ -z "${1}" ]]; then
    exit
fi

"${CURRENT_DIR}/main.sh" "$1"

if [[ $? -eq 2 ]]; then
    tmux display-message '(focus-pane) unknown command'
fi
