#!/usr/bin/env bash

set -uo pipefail

theme_dir=${1:?usage: apply-qt.sh THEME_DIR}
[ -f "$theme_dir/qt.conf" ] || exit 0

for ct in qt5ct qt6ct; do
	dir="$HOME/.config/$ct"
	mkdir -p "$dir/colors"

	cp "$theme_dir/qt.conf" "$dir/colors/nyxcraft.conf.tmp"
	mv "$dir/colors/nyxcraft.conf.tmp" "$dir/colors/nyxcraft.conf"

	cat >"$dir/$ct.conf.tmp" <<EOF
[Appearance]
color_scheme_path=$dir/colors/nyxcraft.conf
custom_palette=true
standard_dialogs=default
style=Fusion
EOF
	mv "$dir/$ct.conf.tmp" "$dir/$ct.conf"
done
