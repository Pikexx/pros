#!/bin/bash

win_id=$(xdotool getactivewindow)

if xprop -id "$win_id" | grep -q "_NET_WM_STATE_FULLSCREEN"; then
    echo "󰘱 Tiled"
elif xprop -id "$win_id" | grep -q "_FLOATING"; then
    echo "󰘳 Floating"
else
    echo "󰘱 Tiled"
fi

