#!/bin/bash
# Xorg and i3 are started by the xorg.service systemd unit (see
# /etc/systemd/system/xorg.service). Do not start X here or you will get two
# X servers racing for :0/vt1.