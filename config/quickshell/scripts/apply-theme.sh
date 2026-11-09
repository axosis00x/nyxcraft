#!/usr/bin/env bash

set -uo pipefail

init=false
if [ "${1:-}" = "--init" ]; then
	[ -f "$HOME/.config/hypr/theme.lua" ] && exit 0
	init=true
	set -- "${2:-ryo}"
fi

theme_name=${1:?usage: apply-theme.sh THEME [WALLPAPER]}
wallpaper_override=${2:-}
themes_dir="$HOME/.config/themes"

config_root=$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)
theme_dir="$themes_dir/$theme_name"

case "$theme_name" in
"" | */* | .*) exit 2 ;;
esac

wallpaper_base="$HOME/Pictures/wallpapers"
if $init; then
	wallpaper=""
elif [ -n "$wallpaper_override" ] && [ -f "$wallpaper_override" ]; then
	wallpaper="$wallpaper_override"
else
	wallpaper=$(find "$wallpaper_base/$theme_name" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) 2>/dev/null | shuf -n 1 || true)
fi

[ -z "$wallpaper" ] || (awww img "$wallpaper" --transition-type any --transition-duration 0.7 --transition-fps 60 || true) &

if [ "$theme_name" = "dynamic" ] && [ -n "$wallpaper" ]; then
	matugen_thumb=$(mktemp --suffix=.png)
	trap 'rm -f "$matugen_thumb"' EXIT
	if vipsthumbnail "$wallpaper" --size 256 -o "$matugen_thumb" 2>/dev/null; then
		matugen_source="$matugen_thumb"
	else
		matugen_source="$wallpaper"
	fi
	matugen --source-color-index 0 image "$matugen_source" \
		--config "$config_root/matugen/config.toml" \
		--type scheme-vibrant --mode dark -q || true
fi

[ -d "$theme_dir" ] && [ -f "$theme_dir/hyprland.lua" ] && [ -f "$theme_dir/kitty.conf" ] || exit 2

printf 'include ../themes/%s/kitty.conf\n' "$theme_name" >"$HOME/.config/kitty/theme.conf"
$init || pkill -USR1 -x kitty 2>/dev/null || true

install_if_present() {
	local source=$1 destination=$2
	[ -f "$source" ] || return 0
	mkdir -p "$(dirname "$destination")"
	cp "$source" "$destination"
}

if ! $init; then
	"$HOME/.config/quickshell/scripts/apply-gtk.sh" "$theme_dir" || true
	"$HOME/.config/quickshell/scripts/apply-qt.sh" "$theme_dir" || true
fi

install_if_present "$theme_dir/tmux.conf" "$HOME/.config/tmux/theme.conf"
install_if_present "$theme_dir/yazi-flavor.toml" "$HOME/.config/yazi/flavors/nyxcraft.yazi/flavor.toml"

if [ -f "$theme_dir/quickshell.js" ]; then
	pal() { sed -n "s/^const $1 = \"\(.*\)\"$/\1/p" "$theme_dir/quickshell.js" | grep -o '[0-9a-fA-F]\{6\}$' | sed 's/^/#/'; }
	bg=$(pal bg) fg=$(pal textPrimary) muted=$(pal textMuted) sub=$(pal textSecondary)
	accent=$(pal accent) high=$(pal surfaceContainerHigh) line=$(pal outlineVariant)
	blue=$(pal blue) green=$(pal green) yellow=$(pal yellow) purple=$(pal purple)
	aqua=$(pal aqua) orange=$(pal orange) red=$(pal error)
	mkdir -p "$HOME/.config/btop/themes"
	cat >"$HOME/.config/btop/themes/nyxcraft.theme" <<BTOP
theme[main_bg]="$bg"
theme[main_fg]="$fg"
theme[title]="$fg"
theme[hi_fg]="$accent"
theme[selected_bg]="$high"
theme[selected_fg]="$accent"
theme[inactive_fg]="$muted"
theme[graph_text]="$sub"
theme[meter_bg]="$high"
theme[proc_misc]="$aqua"
theme[cpu_box]="$blue"
theme[mem_box]="$green"
theme[net_box]="$purple"
theme[proc_box]="$accent"
theme[div_line]="$line"
theme[temp_start]="$green"
theme[temp_mid]="$yellow"
theme[temp_end]="$red"
theme[cpu_start]="$aqua"
theme[cpu_mid]="$blue"
theme[cpu_end]="$purple"
theme[free_start]="$green"
theme[free_mid]="$green"
theme[free_end]="$aqua"
theme[cached_start]="$blue"
theme[cached_mid]="$blue"
theme[cached_end]="$purple"
theme[available_start]="$aqua"
theme[available_mid]="$aqua"
theme[available_end]="$green"
theme[used_start]="$yellow"
theme[used_mid]="$orange"
theme[used_end]="$red"
theme[download_start]="$blue"
theme[download_mid]="$aqua"
theme[download_end]="$green"
theme[upload_start]="$purple"
theme[upload_mid]="$orange"
theme[upload_end]="$red"
theme[process_start]="$aqua"
theme[process_mid]="$blue"
theme[process_end]="$purple"
BTOP
	$init || pkill -USR2 -x btop 2>/dev/null || true
fi
if [ -f "$theme_dir/cava.ini" ]; then
	mkdir -p "$HOME/.config/cava/themes"
	ln -sfn "$theme_dir/cava.ini" "$HOME/.config/cava/themes/current"
	$init || pkill -USR2 -x cava 2>/dev/null || true
fi

printf 'return dofile(os.getenv("HOME") .. "/.config/themes/%s/hyprland.lua")\n' "$theme_name" >"$HOME/.config/hypr/theme.lua"

if [ -f "$theme_dir/neovim.lua" ]; then
	nvim_theme=$(sed -n 's/^return "\(.*\)"/\1/p' "$theme_dir/neovim.lua" | head -n1)
	[ -n "$nvim_theme" ] && printf '%s' "$nvim_theme" >"$HOME/.config/nvim/theme_name.txt"
fi

$init && exit 0

case "$theme_name" in
gruvbox) zed_theme="Gruvbox Dark" ;;
mocha) zed_theme="Catppuccin Mocha" ;;
tokyonight) zed_theme="Aura Dark" ;;
monochrome) zed_theme="Quasi Monochrome Dark" ;;
moonfly) zed_theme="One Dark Pro Max" ;;
ryo) zed_theme="One Dark Pro Max" ;;
dynamic) zed_theme="One Dark Pro Max" ;;
transparent) zed_theme="One Dark Pro Max" ;;
*) zed_theme="" ;;
esac
if [ -n "$zed_theme" ] && [ -f "$HOME/.config/zed/settings.json" ]; then
	sed -i '/"theme": {/,/}/{
        s/"light": *"[^"]*"/"light": "'"$zed_theme"'"/
        s/"dark": *"[^"]*"/"dark": "'"$zed_theme"'"/
    }' "$HOME/.config/zed/settings.json"
fi

hyprctl reload >/dev/null || true
pgrep tmux >/dev/null && tmux source-file "$HOME/.config/tmux/tmux.conf" 2>/dev/null || true
notify-send -i "$wallpaper" "Theme Activated" "Applied $theme_name"
