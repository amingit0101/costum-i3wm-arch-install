#!/bin/bash -p
set -e
set -o pipefail

# Values passed from install.sh (archinstall handles base, GRUB, users,
# passwords, hostname, timezone and locale - so none of that is done here).
if [ -f /root/install-env ]; then
  source /root/install-env
fi
NEW_USERNAME="${NEW_USERNAME:-}"

print_info() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
print_warning() { echo -e "\033[1;33m[WARNING]\033[0m $1"; }
print_error() { echo -e "\033[0;31m[ERROR]\033[0m $1"; }

CHROOT_LOGFILE="/var/log/archinstall-chroot.log"
mkdir -p /var/log
exec > >(tee -a "$CHROOT_LOGFILE") 2>&1

on_chroot_error() {
  local exit_code=$?
  print_error "Chroot setup failed (exit code $exit_code) at line $LINENO: $BASH_COMMAND"
  print_error "Full log saved at: $CHROOT_LOGFILE (readable after reboot too)"
  exit "$exit_code"
}
trap on_chroot_error ERR

print_info "Logging chroot setup to $CHROOT_LOGFILE"

# ---------------------------------------------------------------------------
# User: archinstall already created the account; only fall back to creating
# one if install-env didn't carry the username through.
# ---------------------------------------------------------------------------
USERNAME="$NEW_USERNAME"
if [ -z "$USERNAME" ]; then
  read -r -p "Enter username to configure the desktop for: " USERNAME
fi
USERNAME=${USERNAME:-arch}

if ! id "$USERNAME" >/dev/null 2>&1; then
  print_warning "User '$USERNAME' does not exist - creating it"
  useradd -m -G wheel,audio,video,optical -s /bin/bash "$USERNAME"
  passwd "$USERNAME"
fi
if ! grep -q "^$USERNAME " /etc/sudoers.d/* 2>/dev/null && ! grep -q "%wheel ALL" /etc/sudoers 2>/dev/null; then
  echo "%wheel ALL=(ALL) ALL" >>/etc/sudoers
fi

# ---------------------------------------------------------------------------
# Enable services
# ---------------------------------------------------------------------------
systemctl enable NetworkManager
systemctl enable iwd
systemctl enable bluetooth
systemctl enable sshd
systemctl enable reflector.timer
systemctl enable systemd-resolved || true
systemctl enable systemd-timesyncd
systemctl enable NetworkManager-wait-online
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

mkdir -p /etc/NetworkManager/conf.d
printf '[device]\nwifi.backend=iwd\n' >/etc/NetworkManager/conf.d/iwd.conf

for service in /etc/systemd/system/*.service; do
  [ -f "$service" ] || continue
  svc_name="$(basename "$service")"
  if systemctl enable "$svc_name"; then
    print_info "Enabled $svc_name"
  else
    print_warning "Failed to enable $svc_name (see error above) - continuing"
  fi
done

# ---------------------------------------------------------------------------
# Seed the user's home with preserved configs
# ---------------------------------------------------------------------------
print_info "Seeding user home with preserved configs..."
mkdir -p /home/$USERNAME/.config
if [ -d /root/.config ]; then
  if ! cp -a /root/.config/. /home/$USERNAME/.config/; then
    print_warning "Some files failed to copy from /root/.config (see error above) - continuing"
  fi
else
  print_warning "/root/.config not found - nothing to seed"
fi

for f in .bashrc .bash_profile .profile .xinitrc .gtkrc-2.0; do
  if [ -e "/root/$f" ]; then
    cp -a "/root/$f" "/home/$USERNAME/" || print_warning "Failed to copy $f - continuing"
  fi
done

WALLPAPER=$(ls /root/*.jpg 2>/dev/null | head -1 || true)
WALLNAME=${WALLPAPER##*/}
if [ -n "$WALLPAPER" ]; then
  cp -f "$WALLPAPER" "/home/$USERNAME/" || print_warning "Failed to copy wallpaper $WALLPAPER - continuing"
fi

I3CONF="/home/$USERNAME/.config/i3/config"
if [ -f "$I3CONF" ]; then
  if [ -n "$WALLNAME" ]; then
    sed -i "s|/root/$WALLNAME|/home/$USERNAME/$WALLNAME|g" "$I3CONF"
  fi
  sed -i '\|/usr/local/bin/install.sh|d' "$I3CONF"
  sed -i '\|welcome.sh|d' "$I3CONF"
  sed -i '\|picom-setup.sh|d' "$I3CONF"
  sed -i 's|^#\s*exec --no-startup-id picom --config ~/.config/i3/picom.conf|exec --no-startup-id picom --config ~/.config/i3/picom.conf|' "$I3CONF"
  sed -i 's|nvim /root/.config/i3/config|nvim ~/.config/i3/config|g' "$I3CONF"
  sed -i '\|/usr/local/bin/add_binding_i3|d' "$I3CONF"
else
  print_warning "$I3CONF not found - skipping i3 config tailoring"
fi

if [ -f "/home/$USERNAME/.bashrc" ]; then
  sed -i "s|/home/amine/|/home/$USERNAME/|g" "/home/$USERNAME/.bashrc" || print_warning "Failed to patch .bashrc paths"
fi
if compgen -G "/home/$USERNAME/.config/i3/scripts/*" >/dev/null; then
  sed -i "s|/home/amine/|/home/$USERNAME/|g" /home/$USERNAME/.config/i3/scripts/* || print_warning "Failed to patch i3 script paths"
fi

# Auto-start X/i3 on tty1
echo 'if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then' >>/home/$USERNAME/.bash_profile
echo '    startx' >>/home/$USERNAME/.bash_profile
echo 'fi' >>/home/$USERNAME/.bash_profile

cat >/home/$USERNAME/.xinitrc <<'XRC'
#!/bin/bash
[ -f /etc/profile ] && . /etc/profile
[ -f ~/.profile ] && . ~/.profile

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
if [ ! -d "$XDG_RUNTIME_DIR" ]; then
  mkdir -p -m 700 "$XDG_RUNTIME_DIR"
  chown "$(id -u):$(id -g)" "$XDG_RUNTIME_DIR"
fi

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
  eval "$(/usr/bin/dbus-launch --sh-syntax --exit-with-session)"
fi

pipewire &
pipewire-pulse &
wireplumber &

exec i3
XRC
chmod +x /home/$USERNAME/.xinitrc

# ---------------------------------------------------------------------------
# AUR helper (yay)
# ---------------------------------------------------------------------------
print_info "Installing yay (AUR helper)..."
cd /tmp
git clone https://aur.archlinux.org/yay.git
cd yay
chown -R "$USERNAME":"$USERNAME" /tmp/yay
sudo -u "$USERNAME" makepkg -si --noconfirm
cd /

print_info "========================================"
print_info "INSTALLATION COMPLETE!"
print_info "========================================"
