#!/bin/bash

MUSIC_DIR="/home/env/Music"
shuffle=false
loop=false
current_song=""
player_pid=""
auto_play_pid=""

SONG_LIST=()

toggle_bool() {
  if $1; then echo false; else echo true; fi
}

build_song_list() {
  mapfile -t SONG_LIST < <(find "$MUSIC_DIR" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" \))

  if $shuffle; then
    mapfile -t SONG_LIST < <(printf '%s\n' "${SONG_LIST[@]}" | shuf)
  else
    IFS=$'\n' mapfile -t SONG_LIST < <(printf '%s\n' "${SONG_LIST[@]}" | sort)
  fi
}

kill_process_group() {
  local pid=$1
  if [[ -n $pid ]] && kill -0 "$pid" 2>/dev/null; then
    kill -- -"$pid" 2>/dev/null
    while kill -0 "$pid" 2>/dev/null; do
      sleep 0.1
    done
  fi
}

kill_player() {
  if [[ -n $player_pid ]]; then
    kill_process_group "$player_pid"
    player_pid=""
  fi
}

kill_autoplay() {
  if [[ -n $auto_play_pid ]]; then
    kill_process_group "$auto_play_pid"
    auto_play_pid=""
  fi
}

play_song() {
  local track=$1
  local loop_mode=$2

  kill_player
  setsid mpv --no-video --really-quiet --force-window=no --player-operation-mode=pseudo-gui \
    --idle=no --loop-file=$([[ "$loop_mode" == "yes" ]] && echo inf || echo no) \
    --no-terminal "$track" >/dev/null 2>&1 &
  player_pid=$!
}

wait_for_player() {
  if [[ -n $player_pid ]]; then
    while kill -0 "$player_pid" 2>/dev/null; do
      sleep 0.5
    done
  fi
}

start_autoplay() {
  kill_autoplay

  setsid bash -c '
    while true; do
      mapfile -t SONG_LIST < <(find "'"$MUSIC_DIR"'" -type f \( -iname "*.mp3" -o -iname "*.flac" -o -iname "*.wav" -o -iname "*.ogg" \))
      if [[ ${#SONG_LIST[@]} -eq 0 ]]; then
        echo "No music files found in '"$MUSIC_DIR"'" >&2
        sleep 5
        continue
      fi
      mapfile -t SONG_LIST < <(printf "%s\n" "${SONG_LIST[@]}" | shuf)
      next_song="${SONG_LIST[RANDOM % ${#SONG_LIST[@]}]}"
      echo "Autoplay playing: '$next_song'" >&2
      mpv --no-video --really-quiet --force-window=no --player-operation-mode=pseudo-gui --idle=no --loop-file=no --no-terminal "$next_song"
    done
  ' &
  auto_play_pid=$!
}

toggle_pause() {
  playerctl play-pause >/dev/null 2>&1 || echo "No playerctl running or mpv IPC socket found."
}

while true; do
  build_song_list

  loop_status="Loop: $( $loop && echo 'ON' || echo 'OFF' )"
  shuffle_status="Shuffle: $( $shuffle && echo 'ON' || echo 'OFF' )"
  SONG_LIST_WITH_CONTROLS=("${SONG_LIST[@]}" ":pause" ":loop ($loop_status)" ":shuffle ($shuffle_status)" ":stop" ":quit")

  selection=$(printf "%s\n" "${SONG_LIST_WITH_CONTROLS[@]}" | sed 's|.*/||; s|\.[^.]*$||' | fzf --height 40% --border --prompt="♪ ")

  [[ -z $selection ]] && kill_player && kill_autoplay && exit 0

  case "$selection" in
    ":pause")
      toggle_pause
      ;;
    ":loop "*)
      loop=$(toggle_bool $loop)
      if $loop; then
        kill_autoplay
        if [[ -n $current_song ]]; then
          play_song "$current_song" yes
        fi
      else
        if $shuffle; then
          (
            wait_for_player
            start_autoplay
          ) &
        fi
      fi
      ;;
    ":shuffle "*)
      shuffle=$(toggle_bool $shuffle)
      build_song_list
      if $shuffle; then
        kill_autoplay
        kill_player
        current_song=""
        start_autoplay
      else
        kill_autoplay
        kill_player
      fi
      ;;
    ":stop")
      kill_player
      kill_autoplay
      ;;
    ":quit")
      kill_player
      kill_autoplay
      exit 0
      ;;
    *)
      for path in "${SONG_LIST[@]}"; do
        name=$(basename "${path%.*}")
        if [[ "$name" == "$selection" ]]; then
          current_song="$path"
          break
        fi
      done

      kill_autoplay

      if $shuffle && ! $loop; then
        play_song "$current_song" no
        (
          wait_for_player
          start_autoplay
        ) &
      else
        play_song "$current_song" $([[ "$loop" == true ]] && echo "yes" || echo "no")
      fi
      ;;
  esac
done
