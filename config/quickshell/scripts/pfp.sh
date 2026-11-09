#!/usr/bin/env bash

set -euo pipefail

face="$HOME/.face"

set_image() {
	local src=$1 tmp="$HOME/.face.new.png"
	[[ -f $src ]] || {
		echo "No such file: $src" >&2
		exit 1
	}

	if ! vips thumbnail "$src" "$tmp" 512 --height 512 --crop centre 2>/dev/null; then
		cp -f "$src" "$tmp"
	fi

	mv -f "$tmp" "$face"
}

case "${1:-}" in
pick)
	file=$(zenity --file-selection --title="Choose a profile picture" \
		--filename="$HOME/Pictures/" \
		--file-filter="Images | *.png *.jpg *.jpeg *.webp *.gif *.bmp *.PNG *.JPG *.JPEG *.WEBP" \
		2>/dev/null) || exit 0
	set_image "$file"
	;;
set)
	set_image "${2:?usage: pfp.sh set IMAGE}"
	;;
reset)
	rm -f "$face"
	;;
*)
	sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'
	exit 2
	;;
esac
