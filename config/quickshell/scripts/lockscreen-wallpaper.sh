#!/usr/bin/env bash

set -uo pipefail

dir="$HOME/Pictures/wallpapers/lockscreen"
state="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell/lockscreen-shown"
mkdir -p "$(dirname "$state")"
touch "$state"

mapfile -t all < <(find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | sort)
[ "${#all[@]}" -gt 0 ] || exit 0

last=$(tail -n 1 "$state")

mapfile -t left < <(printf '%s\n' "${all[@]}" | grep -vxF -f "$state")

if [ "${#left[@]}" -eq 0 ]; then

	: >"$state"
	mapfile -t left < <(printf '%s\n' "${all[@]}" | grep -vxF -- "$last")
	[ "${#left[@]}" -gt 0 ] || left=("${all[@]}")
fi

pick=$(printf '%s\n' "${left[@]}" | shuf -n 1)
printf '%s\n' "$pick" >>"$state"
printf '%s' "$pick"
