#!/bin/bash

# Config file to store user preference
PICOM_CONFIG="/root/.config/picom/enabled"
PICOM_PID_FILE="/tmp/picom.pid"

# Function to start picom
start_picom() {
  if ! pgrep -x "picom" >/dev/null; then
    picom --config /root/.config/i3/picom.conf &
    echo $! >"$PICOM_PID_FILE"
    echo "enabled" >"$PICOM_CONFIG"
  fi
}

# Function to stop picom
stop_picom() {
  if pgrep -x "picom" >/dev/null; then
    pkill picom
    rm -f "$PICOM_PID_FILE"
    echo "disabled" >"$PICOM_CONFIG"
  fi
}

# Function to show the dialog
show_dialog() {
  local choice

  choice=$(zenity --question \
    --title="Picom Compositor" \
    --width=500 \
    --height=200 \
    --text="<b>🎨 Enable Picom Compositor?</b>\n\n\
Picom provides:\n\
    • Window shadows and rounded corners\n\
    • Transparency effects\n\
    • Smooth animations\n\
    • Reduced screen tearing\n\n\
<b>⚠️ Note:</b> Picom uses GPU resources.\n\
Disable it for better performance on older hardware.\n\n\
You can toggle it anytime with:\n\
    • Super+Shift+P (toggle on/off)" \
    --ok-label="Enable Picom" \
    --cancel-label="Disable Picom")

  return $?
}

# Check if zenity is available
if ! command -v zenity &>/dev/null; then
  echo "zenity not found. Starting picom by default."
  start_picom
  exit 0
fi

# Check if user already made a choice
if [ -f "$PICOM_CONFIG" ]; then
  if grep -q "enabled" "$PICOM_CONFIG"; then
    start_picom
  else
    stop_picom
  fi
  exit 0
fi

# Show the dialog
if show_dialog; then
  # User chose to enable
  start_picom
  zenity --info \
    --title="Picom Enabled" \
    --text="Picom compositor has been enabled.\n\nYou can toggle it anytime with:\nSuper+Shift+P" \
    --width=400
else
  # User chose to disable
  stop_picom
  zenity --info \
    --title="Picom Disabled" \
    --text="Picom compositor has been disabled for better performance.\n\nYou can re-enable it anytime with:\nSuper+Shift+P" \
    --width=400
fi
