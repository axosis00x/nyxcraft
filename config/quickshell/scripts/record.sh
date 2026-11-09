#!/usr/bin/env bash

if pgrep -x wf-recorder >/dev/null; then
	pkill -x -INT wf-recorder
	notify-send 'Recording Stopped' 'Saved to ~/Videos/Recordings'
	exit 0
fi

mkdir -p ~/Videos/Recordings
filename=~/Videos/Recordings/$(date +%Y-%m-%d_%H-%M-%S).mp4
audio_source="$(pactl get-default-sink).monitor"

setsid wf-recorder -f "$filename" "--audio=$audio_source" \
	-r 60 -c libx264 -p crf=18 -p preset=veryfast \
	>/tmp/wf-recorder.log 2>&1 &
notify-send 'Recording Started' "$filename"
