#!/usr/bin/env bash

set -uo pipefail

theme_dir=${1:?usage: apply-gtk.sh THEME_DIR}

base=""
for candidate in \
	"/etc/profiles/per-user/$USER/share/themes/adw-gtk3-dark" \
	"$HOME/.nix-profile/share/themes/adw-gtk3-dark" \
	"/run/current-system/sw/share/themes/adw-gtk3-dark"; do
	if [ -f "$candidate/gtk-3.0/gtk.css" ]; then
		base=$candidate
		break
	fi
done
[ -n "$base" ] || exit 1

themes_root="${XDG_DATA_HOME:-$HOME/.local/share}/themes"

if [ "$(dconf read /org/gnome/desktop/interface/gtk-theme 2>/dev/null)" = "'nyxcraft-a'" ]; then
	slot=nyxcraft-b
else
	slot=nyxcraft-a
fi

derived='@define-color dialog_bg_color @popover_bg_color;
@define-color dialog_fg_color @popover_fg_color;
@define-color headerbar_backdrop_color @headerbar_bg_color;
@define-color secondary_sidebar_bg_color @sidebar_bg_color;
@define-color secondary_sidebar_fg_color @sidebar_fg_color;
@define-color secondary_sidebar_backdrop_color @sidebar_backdrop_color;
@define-color secondary_sidebar_border_color @sidebar_border_color;
@define-color thumbnail_bg_color @card_bg_color;
@define-color thumbnail_fg_color @card_fg_color;'

write_atomic() {
	local dest=$1
	mkdir -p "$(dirname "$dest")"
	cat >"$dest.tmp" && mv "$dest.tmp" "$dest"
}

for ver in 3 4; do
	colors="$theme_dir/gtk-$ver.css"
	[ -f "$colors" ] || continue
	{
		printf '@import url("file://%s/gtk-%s.0/gtk.css");\n' "$base" "$ver"
		printf '%s\n' "$derived"
		cat "$colors"
	} | write_atomic "$themes_root/$slot/gtk-$ver.0/gtk.css"
done

if [ -f "$theme_dir/gtk-4.css" ]; then
	{
		printf '%s\n' "$derived"
		cat "$theme_dir/gtk-4.css"
	} | write_atomic "$HOME/.config/gtk-4.0/gtk.css"
fi

rm -f "$HOME/.config/gtk-3.0/gtk.css"

dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/gtk-theme "'$slot'"
