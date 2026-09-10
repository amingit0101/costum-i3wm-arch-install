#!/bin/bash

# Toggle Picom on/off

PICOM_CONFIG="/root/.config/picom/enabled"
PICOM_PID_FILE="/tmp/picom.pid"

if pgrep -x "picom" >/dev/null; then
  # Picom is running - stop it
  pkill picom
  rm -f "$PICOM_PID_FILE"
  echo "disabled" >"$PICOM_CONFIG"

  if command -v notify-send &>/dev/null; then
    notify-send "Picom" "Disabled" --icon=video-display
  elif command -v zenity &>/dev/null; then
    zenity --info --text="Picom disabled" --timeout=2
  fi
else
  # Picom is not running - start it
  picom --config /root/.config/i3/picom.conf &
  echo $! >"$PICOM_PID_FILE"
  echo "enabled" >"$PICOM_CONFIG"

  if command -v notify-send &>/dev/null; then
    notify-send "Picom" "Enabled" --icon=video-display
  elif command -v zenity &>/dev/null; then
    zenity --info --text="Picom enabled" --timeout=2
  fi
fi
