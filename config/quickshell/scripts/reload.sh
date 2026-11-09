#!/usr/bin/env bash

hyprctl reload

if qs list 2>/dev/null | grep -q .; then
	qs ipc call shell reload
else

	QSG_RENDER_LOOP=basic qs &
	disown
fi
