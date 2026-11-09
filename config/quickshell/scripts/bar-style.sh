#!/usr/bin/env bash

set -uo pipefail

orientation=${1:?usage: bar-style.sh vertical|horizontal}

case "$orientation" in
vertical | horizontal) ;;
*) exit 2 ;;
esac

printf 'return "%s"\n' "$orientation" >"$HOME/.config/hypr/barorientation.lua"
hyprctl reload >/dev/null || true
