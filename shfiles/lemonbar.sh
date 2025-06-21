#!/bin/bash
BAR_FONT="JetBrainsMono Nerd Font:style=Bold:pixelsize=11"
FG="#98971a"
BG="#282828"
HL="#98971a"

PLAYER_BG="#79740e"
PLAYER_FG="#fbf1c7"

BAR_HEIGHT=25
Y_OFFSET=8
BAR_WIDTH=470
SCREEN_WIDTH=$(xdpyinfo | awk '/dimensions/{print $2}' | cut -d'x' -f1)
X_OFFSET=$(( (SCREEN_WIDTH - BAR_WIDTH) / 2 ))

get_volume() {
    sink=$(pactl get-default-sink)
    vol=$(pactl get-sink-volume "$sink" | awk -F '/' 'NR==1{gsub(/ /, "", $2); print $2}')
    muted=$(pactl get-sink-mute "$sink" | awk '{print $2}')
    icon=""
    [ "$muted" = "yes" ] && icon=""
    echo "${icon} ${vol}"
}

while :; do
    current_ws=$(xprop -root _NET_CURRENT_DESKTOP | awk '{print $3}')
    current_ws_num=$((current_ws + 1))
    workspaces="%{F$HL}[${current_ws_num}]%{F-}"

    # Use system time, assuming /etc/localtime is set to Asia/Manila
    datetime=$(date "+%a %d %b %I:%M %p")

    vol_text=$(get_volume)
    volume_block="%{A1:pactl set-sink-mute @DEFAULT_SINK@ toggle:}%{A4:pactl set-sink-volume @DEFAULT_SINK@ +5%:}%{A5:pactl set-sink-volume @DEFAULT_SINK@ -5%:}$vol_text%{A}%{A}%{A}"

    raw_info=$(/home/env/shfiles/player.sh)
    max_len=25
    if [ ${#raw_info} -gt $max_len ]; then
        player_info="${raw_info:0:$((max_len - 1))}…"
    else
        player_info="$raw_info"
    fi

    # Boxed music module with 2 spaces padding inside
    player_block="%{A1:playerctl play-pause:}%{B$PLAYER_BG}%{F$PLAYER_FG}  $player_info  %{B-}%{F-}%{A}"

    echo "%{c}$workspaces   $volume_block   $player_block   $datetime"

    sleep 0.3
done | lemonbar -p -g "${BAR_WIDTH}x${BAR_HEIGHT}+${X_OFFSET}+${Y_OFFSET}" \
    -f "$BAR_FONT" -B "$BG" -F "$FG" | sh
