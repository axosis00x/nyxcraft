#!/usr/bin/env bash

set -uo pipefail

shader_name=${1:?usage: apply-shader.sh SHADER_NAME|none}
shaders_dir="$HOME/.config/hypr/shaders"

case "$shader_name" in
"" | */* | .*) exit 2 ;;
esac

if [ "$shader_name" = "none" ]; then
	shader_path=""
	printf 'return ""\n' >"$HOME/.config/hypr/shader.lua"
else
	shader_path="$shaders_dir/$shader_name.glsl"
	[ -f "$shader_path" ] || exit 2

	printf 'return os.getenv("HOME") .. "/.config/hypr/shaders/%s.glsl"\n' "$shader_name" >"$HOME/.config/hypr/shader.lua"
fi

lua_escaped=$(printf '%s' "$shader_path" | sed 's/\\/\\\\/g; s/"/\\"/g')
hyprctl eval "hl.config({decoration={screen_shader=\"$lua_escaped\"}})" >/dev/null

notify-send "Shader" "${shader_name}"
