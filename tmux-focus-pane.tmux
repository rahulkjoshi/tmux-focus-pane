#! /usr/bin/env bash
#! vi: ft=bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

tmux bind z run-shell "$CURRENT_DIR/scripts/toggle-focus.sh toggle"
