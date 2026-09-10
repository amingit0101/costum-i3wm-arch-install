#!/bin/bash
[ -f /etc/profile ] && . /etc/profile
[ -f ~/.profile ] && . ~/.profile

# PipeWire needs a writable runtime dir
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  mkdir -p -m 700 "$XDG_RUNTIME_DIR"
  chown "$(id -u):$(id -g)" "$XDG_RUNTIME_DIR"
fi

# Provide a session bus for the services started by i3 (nm-applet, blueman, ...)
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(/usr/bin/dbus-launch --sh-syntax --exit-with-session)"
fi

pipewire &
pipewire-pulse &
wireplumber &

exec i3