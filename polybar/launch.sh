#!/bin/bash

# Kill any existing Polybar instances
pkill polybar

# Wait until processes are fully closed
while pgrep -u $UID -x polybar >/dev/null; do sleep 0.2; done

# Launch all bars
polybar left &
polybar center &
polybar player &
polybar right &
