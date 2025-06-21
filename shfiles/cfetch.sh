#!/bin/bash

# Colors
cyan="\e[36m"
yellow="\e[33m"
reset="\e[0m"

# System Info
user=$(whoami)
distro=$(awk -F= '/^NAME/{print $2}' /etc/os-release | tr -d '"')
kernel=$(uname -r)
packages=$(xbps-query -l | wc -l)
init="runit"
wm="sxwm"

# Stats
cpu=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $8}' | awk -F. '{print $1}')
ram=$(free | awk '/Mem/ { printf("%.0f"), $3/$2 * 100 }')
hd=$(df / | awk 'END{ print $5 }' | tr -d '%')
temp_raw=$(sensors | grep -m 1 'temp1' | awk '{print $2}' | tr -d '+°C')
temp=${temp_raw:-0}

# Thin ASCII bar function
bar() {
  local value=$1
  local width=20
  local filled=$((value * width / 100))
  local empty=$((width - filled))
  local bar_filled=""
  local bar_empty=""

  for ((i=0; i<filled; i++)); do
    bar_filled+="|"
  done
  for ((i=0; i<empty; i++)); do
    bar_empty+="."
  done
  printf "%s%s" "$bar_filled" "$bar_empty"
}

clear
echo -e "${cyan}hello r/unixporn${reset}"
echo
printf " ${yellow}%-10s${reset} %s\n" "Distro:"   "$distro"
printf " ${yellow}%-10s${reset} %s\n" "Kernel:"   "$kernel"
printf " ${yellow}%-10s${reset} %s\n" "Packages:" "$packages"
printf " ${yellow}%-10s${reset} %s\n" "Init:"     "$init"
printf " ${yellow}%-10s${reset} %s\n" "WM:"       "$wm"
echo
printf " %-10s %3s%%   %s\n" "cpu:" "$cpu" "$(bar $cpu)"
printf " %-10s %3s%%   %s\n" "ram:" "$ram" "$(bar $ram)"
printf " %-10s %3s%%   %s\n" "hd:"  "$hd"  "$(bar $hd)"
printf " %-10s         %s\n" "temp:"        "$(bar $temp)"
