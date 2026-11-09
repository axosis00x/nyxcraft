#!/usr/bin/env bash

old=$(qs list 2>/dev/null | awk '/Process ID:/ {print $3}')
qs kill >/dev/null 2>&1

for pid in $old; do
	for _ in $(seq 20); do
		kill -0 "$pid" 2>/dev/null || break
		sleep 0.25
	done
done

for _ in $(seq 8); do
	qs list 2>/dev/null | grep -q "^Instance" && exit 0
	sleep 0.25
done

QSG_RENDER_LOOP=basic setsid qs >/dev/null 2>&1 &
disown
