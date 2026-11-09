#!/usr/bin/env bash

set -uo pipefail

cutout_path() {
	local wallpaper=$1 name
	name=$(basename "$wallpaper")
	printf '%s/depth/%s.png' "$(dirname "$wallpaper")" "${name%.*}"
}

make_cutout() {
	local wallpaper=$1 out tmp
	out=$(cutout_path "$wallpaper")
	if [ -s "$out" ] && [ ! "$wallpaper" -nt "$out" ]; then
		printf '%s' "$out"
		return 0
	fi
	mkdir -p "$(dirname "$out")"

	exec 9>"$(dirname "$out")/.lock"
	flock 9
	if [ ! -s "$out" ] || [ "$wallpaper" -nt "$out" ]; then
		tmp="$out.tmp.png"
		if command -v rembg >/dev/null 2>&1; then
			rembg i -m isnet-general-use "$wallpaper" "$tmp" >/dev/null 2>&1
		else
			nix run nixpkgs#rembg -- i -m isnet-general-use "$wallpaper" "$tmp" >/dev/null 2>&1
		fi
		[ -s "$tmp" ] && mv "$tmp" "$out"
		rm -f "$tmp"
	fi
	exec 9>&-
	[ -s "$out" ] && printf '%s' "$out"
}

case "${1:-}" in
--cached)
	out=$(cutout_path "${2:?usage: depth-cutout.sh --cached WALLPAPER}")
	[ -s "$out" ] && [ ! "$2" -nt "$out" ] && printf '%s' "$out"
	;;
--all)
	dir=${2:?usage: depth-cutout.sh --all DIR}
	find "$dir" -maxdepth 1 -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) |
		while IFS= read -r f; do
			make_cutout "$f" >/dev/null
		done
	;;
"")
	echo "usage: depth-cutout.sh [--cached|--all] WALLPAPER|DIR" >&2
	exit 2
	;;
*)
	[ -f "$1" ] || exit 1
	make_cutout "$1"
	;;
esac
