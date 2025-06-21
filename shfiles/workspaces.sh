#!/bin/sh

# Get active workspace number
ACTIVE=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')

# Get total number of workspaces
COUNT=$(xprop -root _NET_NUMBER_OF_DESKTOPS | awk '{print $3}')

output="%{T1}%{B#3c3836}%{F#bdae93} "

i=0
while [ "$i" -lt "$COUNT" ]; do
    if [ "$i" -eq "$ACTIVE" ]; then
        output="$output%{u#fabd2f +u}$(($i + 1))%{-u} "
    else
        output="$output$(($i + 1)) "
    fi
    i=$((i + 1))
done

output="$output%{F-}%{B-}%{T-}"

echo "$output"
