#!/bin/sh

# Check if picom is running
PID=$(pidof picom)

if [ -n "$PID" ]; then
    kill "$PID"
    echo "picom stopped" > /tmp/picom-toggle.log
else
    nohup picom > /dev/null 2>&1 &
    echo "picom started" > /tmp/picom-toggle.log
fi
