#!/bin/bash

APP_DIRS=(
  "$HOME/.local/share/applications"
  "/usr/share/applications"
  "/var/lib/flatpak/exports/share/applications"
  "$HOME/.local/share/flatpak/exports/share/applications"
)

# Filter only existing directories
EXISTING_APP_DIRS=()
for dir in "${APP_DIRS[@]}"; do
  [ -d "$dir" ] && EXISTING_APP_DIRS+=("$dir")
done

app_list=""

# Collect all .desktop apps
while IFS= read -r file; do
  if grep -q '^NoDisplay=true' "$file"; then
    continue
  fi

  name=$(grep -m1 '^Name=' "$file" | cut -d= -f2)
  desktop_id=$(basename "$file" .desktop)
  [ -z "$name" ] && name="$desktop_id"

  app_list+="$name|$desktop_id"$'\n'
done < <(find "${EXISTING_APP_DIRS[@]}" \( -type f -o -type l \) -name '*.desktop' 2>/dev/null)

# Manually add Spotify if it's installed but no .desktop file found
if ! echo "$app_list" | grep -q 'com.spotify.Client'; then
  if flatpak info com.spotify.Client >/dev/null 2>&1; then
    app_list="[Spotify] Spotify|com.spotify.Client"$'\n'"$app_list"
  fi
fi

# Show menu
choice=$(echo "$app_list" | cut -d'|' -f1 | sort -u | dmenu -i -p "Launch:")
[ -z "$choice" ] && exit 0

# Extract desktop ID
desktop_id=$(echo "$app_list" | grep "^$choice|" | cut -d'|' -f2 | head -n1)

# Set up environment
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"

# Ensure DBUS session is available
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(dbus-launch --sh-syntax)"
fi

# Fix PATH for Flatpak apps
export PATH="$PATH:/var/lib/flatpak/exports/bin:$HOME/.local/share/flatpak/exports/bin"

# Launch app
if [[ "$desktop_id" == *.*.* ]]; then
  flatpak run "$desktop_id" &
else
  gtk-launch "$desktop_id" &
fi

