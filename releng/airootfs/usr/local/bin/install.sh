#!/bin/bash

set -e
set -o pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() {
  echo -e "\n${BLUE}========================================${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}========================================${NC}\n"
}

# Logging
LOGFILE="/root/archinstall-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

on_error() {
  local exit_code=$?
  print_error "Script failed (exit code $exit_code) at line $LINENO: $BASH_COMMAND"
  print_error "Full log saved at: $LOGFILE"
  exit "$exit_code"
}
trap on_error ERR

print_info "Logging full output to $LOGFILE"

# ---------------------------------------------------------------------------
# Copy everything from live system
# ---------------------------------------------------------------------------

copy_all_configs() {
  print_info "Copying ALL configurations from live system..."

  # Copy .config directory (i3, polybar, picom, rofi, etc.)
  if [ -d "/root/.config" ]; then
    mkdir -p /mnt/root/.config
    cp -r /root/.config/* /mnt/root/.config/ 2>/dev/null || true
    print_info "Copied /root/.config"
  fi

  # Copy .local if it exists
  if [ -d "/root/.local" ]; then
    mkdir -p /mnt/root/.local
    cp -r /root/.local/* /mnt/root/.local/ 2>/dev/null || true
    print_info "Copied /root/.local"
  fi

  # Copy all root dotfiles
  for f in .bashrc .bash_profile .profile .xinitrc .xsession .gtkrc-2.0 .gnupg .ssh .zshrc .fehbg; do
    if [ -e "/root/$f" ]; then
      cp -r "/root/$f" "/mnt/root/" 2>/dev/null || true
      print_info "Copied /root/$f"
    fi
  done

  # Copy custom scripts from /usr/local/bin
  if [ -d "/usr/local/bin" ] && [ "$(ls -A /usr/local/bin 2>/dev/null)" ]; then
    mkdir -p /mnt/usr/local/bin
    cp -r /usr/local/bin/* /mnt/usr/local/bin/ 2>/dev/null || true
    chmod +x /mnt/usr/local/bin/* 2>/dev/null || true
    print_info "Copied /usr/local/bin scripts"
  fi

  # Copy wallpapers from /root
  if ls /root/*.jpg 2>/dev/null || ls /root/*.png 2>/dev/null; then
    mkdir -p /mnt/usr/share/wallpapers
    cp /root/*.jpg /root/*.png /mnt/usr/share/wallpapers/ 2>/dev/null || true
    cp /root/*.jpg /root/*.png /mnt/root 2>/dev/null || true
    print_info "Copied wallpapers from /root"
  fi

  # Copy fonts
  if [ -d "/usr/share/fonts" ]; then
    mkdir -p /mnt/usr/share/fonts
    cp -r /usr/share/fonts/* /mnt/usr/share/fonts/ 2>/dev/null || true
    print_info "Copied fonts"
  fi

  # Copy systemd services (skip live-only ones)
  if [ -d "/etc/systemd/system" ]; then
    mkdir -p /mnt/etc/systemd/system

    # Copy all service files
    for service in /etc/systemd/system/*.service; do
      if [ -f "$service" ]; then
        name=$(basename "$service")
        # Skip live-only services
        case "$name" in
        choose-mirror.service | fix-permissions.service | pacman-init.service | livecd-*.service | xorg.service)
          print_info "Skipping live-only service: $name"
          continue
          ;;
        esac
        cp "$service" /mnt/etc/systemd/system/ 2>/dev/null || true
        print_info "Copied service: $name"
      fi
    done

    # Copy service directories (like getty@tty1.service.d)
    for dir in /etc/systemd/system/*.d; do
      if [ -d "$dir" ]; then
        case "$dir" in
        */getty@tty1.service.d)
          print_info "Skipping live-only: $dir"
          continue
          ;;
        esac
        cp -r "$dir" /mnt/etc/systemd/system/ 2>/dev/null || true
        print_info "Copied service directory: $dir"
      fi
    done
  fi

  # Copy modprobe configs
  if [ -d "/etc/modprobe.d" ]; then
    mkdir -p /mnt/etc/modprobe.d
    cp -r /etc/modprobe.d/* /mnt/etc/modprobe.d/ 2>/dev/null || true
    print_info "Copied modprobe configs"
  fi

  # Copy pacman hooks
  if [ -d "/etc/pacman.d/hooks" ]; then
    mkdir -p /mnt/etc/pacman.d/hooks
    cp -r /etc/pacman.d/hooks/* /mnt/etc/pacman.d/hooks/ 2>/dev/null || true
    print_info "Copied pacman hooks"
  fi

  # Copy systemd network configs
  if [ -d "/etc/systemd/network" ]; then
    mkdir -p /mnt/etc/systemd/network
    cp -r /etc/systemd/network/* /mnt/etc/systemd/network/ 2>/dev/null || true
    print_info "Copied systemd network configs"
  fi

  # Copy systemd configs
  for conf in logind.conf resolved.conf journald.conf; do
    if [ -f "/etc/systemd/$conf" ]; then
      mkdir -p /mnt/etc/systemd
      cp "/etc/systemd/$conf" /mnt/etc/systemd/ 2>/dev/null || true
      print_info "Copied /etc/systemd/$conf"
    fi
  done

  # Copy misc system configs
  if [ -f "/etc/motd" ]; then
    cp /etc/motd /mnt/etc/ 2>/dev/null || true
    print_info "Copied motd"
  fi

  if [ -f "/etc/pacman.d/mirrorlist" ]; then
    cp /etc/pacman.d/mirrorlist /mnt/etc/pacman.d/ 2>/dev/null || true
    print_info "Copied mirrorlist"
  fi

  # Copy ssh configs
  if [ -d "/etc/ssh" ]; then
    mkdir -p /mnt/etc/ssh
    if [ -f "/etc/ssh/sshd_config" ]; then
      cp /etc/ssh/sshd_config /mnt/etc/ssh/ 2>/dev/null || true
    fi
    if [ -d "/etc/ssh/sshd_config.d" ]; then
      mkdir -p /mnt/etc/ssh/sshd_config.d
      cp -r /etc/ssh/sshd_config.d/* /mnt/etc/ssh/sshd_config.d/ 2>/dev/null || true
    fi
    print_info "Copied ssh configs"
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
  print_error "This script must be run as root"
  exit 1
fi

clear
print_header "Arch Linux Installer"
echo -e "${GREEN}This script installs Arch Linux and copies ALL configurations from the live system${NC}"

echo ""
read -r -p "Continue? (yes/no): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && print_info "Installation cancelled" && exit 0

# Check boot mode
if [ -d /sys/firmware/efi ]; then
  BOOT_FW="efi"
else
  BOOT_FW="bios"
fi
print_info "Boot firmware detected: $BOOT_FW"

# Disk selection
print_header "Disk Selection"
lsblk -d -o NAME,SIZE,TYPE,MODEL | grep -E "disk" | grep -v "loop"
echo ""
read -r -p "Enter target disk (e.g., /dev/sda): " DISK
[[ ! -b "$DISK" ]] && print_error "Disk $DISK does not exist" && exit 1

echo ""
print_warning "All data on $DISK will be destroyed!"
read -r -p "Are you sure? (yes/no): " CONFIRM
[[ "$CONFIRM" != "yes" ]] && print_info "Installation cancelled" && exit 0

# Unmount anything already mounted under /mnt
swapoff -a 2>/dev/null || true
if mountpoint -q /mnt; then
  umount -R /mnt || {
    print_error "Failed to unmount existing /mnt - resolve manually and re-run"
    exit 1
  }
fi

# Partition naming
if [[ "$DISK" =~ /dev/(nvme[0-9]+n[0-9]+|mmcblk[0-9]+|loop[0-9]+)$ ]]; then
  PART_PREFIX="${DISK}p"
else
  PART_PREFIX="${DISK}"
fi

# ---------------------------------------------------------------------------
# Installation options
# ---------------------------------------------------------------------------
print_header "Installation Options"

read -r -p "Enter hostname (default: archbox): " HOSTNAME
HOSTNAME=${HOSTNAME:-archbox}

read -r -p "Enter username: " USERNAME
[[ -z "$USERNAME" ]] && print_error "Username cannot be empty" && exit 1

while true; do
  read -r -s -p "Enter root password: " ROOT_PASS
  echo
  read -r -s -p "Repeat root password: " ROOT_PASS2
  echo
  if [[ -n "$ROOT_PASS" && "$ROOT_PASS" == "$ROOT_PASS2" ]]; then
    break
  fi
  print_warning "Root passwords do not match or are empty - try again"
done

while true; do
  read -r -s -p "Enter password for $USERNAME: " USER_PASS
  echo
  read -r -s -p "Repeat password for $USERNAME: " USER_PASS2
  echo
  if [[ -n "$USER_PASS" && "$USER_PASS" == "$USER_PASS2" ]]; then
    break
  fi
  print_warning "User passwords do not match or are empty - try again"
done

# ---------------------------------------------------------------------------
# Read packages list from /root/packages.x86_64
# ---------------------------------------------------------------------------
print_header "Loading Package List"

PACKAGES_FILE="/root/packages.x86_64"

if [ ! -f "$PACKAGES_FILE" ]; then
  print_error "Package list not found at $PACKAGES_FILE"
  print_error "Please ensure packages.x86_64 exists in /root/"
  exit 1
fi

# Read packages, remove comments and empty lines
PACKAGES=$(grep -v "^#" "$PACKAGES_FILE" | grep -v "^$" | tr -s ' \n' ' ')

if [ -z "$PACKAGES" ]; then
  print_error "No packages found in $PACKAGES_FILE"
  exit 1
fi

print_info "Found packages:"
echo "$PACKAGES" | fold -w 80
echo ""

# Add essential packages that might not be in the list
ESSENTIAL_PACKAGES="base base-devel linux linux-firmware grub $([[ "$BOOT_FW" == "efi" ]] && echo "efibootmgr") networkmanager sudo openssh"

# Combine essential + user packages, remove duplicates
ALL_PACKAGES=$(echo "$ESSENTIAL_PACKAGES $PACKAGES" | tr ' ' '\n' | sort -u | tr '\n' ' ')
print_info "Total packages to install: $(echo $ALL_PACKAGES | wc -w)"

# ---------------------------------------------------------------------------
# Partition the disk
# ---------------------------------------------------------------------------
print_header "Partitioning Disk"

print_info "Creating partition table..."
wipefs -a "$DISK"
sleep 1

if [[ "$BOOT_FW" == "efi" ]]; then
  # EFI partition layout
  parted -s "$DISK" mklabel gpt
  parted -s "$DISK" mkpart primary fat32 1MiB 513MiB
  parted -s "$DISK" set 1 esp on
  parted -s "$DISK" mkpart primary ext4 513MiB 100%

  print_info "Waiting for kernel..."
  partprobe "$DISK"
  udevadm settle 2>/dev/null || true

  # Format partitions
  mkfs.fat -F32 -n ESP "${PART_PREFIX}1"
  mkfs.ext4 -F -L ROOT "${PART_PREFIX}2"

  # Mount
  mount "${PART_PREFIX}2" /mnt
  mkdir -p /mnt/boot
  mount "${PART_PREFIX}1" /mnt/boot
else
  # BIOS partition layout
  parted -s "$DISK" mklabel msdos
  parted -s "$DISK" mkpart primary ext4 1MiB 100%
  parted -s "$DISK" set 1 boot on

  print_info "Waiting for kernel..."
  partprobe "$DISK"
  udevadm settle 2>/dev/null || true

  # Format partition
  mkfs.ext4 -F -L ROOT "${PART_PREFIX}1"

  # Mount
  mount "${PART_PREFIX}1" /mnt
fi

print_info "Mounts:"
findmnt /mnt

# ---------------------------------------------------------------------------
# Install base system with packages from packages.x86_64
# ---------------------------------------------------------------------------
print_header "Installing Base System"

print_info "Installing packages..."
pacstrap /mnt $ALL_PACKAGES

# Generate fstab
genfstab -U /mnt >>/mnt/etc/fstab

# ---------------------------------------------------------------------------
# Copy ALL configurations
# ---------------------------------------------------------------------------
print_header "Copying Configurations"
copy_all_configs

# ---------------------------------------------------------------------------
# CRITICAL: Chroot setup
# ---------------------------------------------------------------------------
print_header "System Configuration (Chroot)"

# Create a comprehensive chroot script
cat >/mnt/root/setup-chroot.sh <<'EOF'
#!/bin/bash

set -e
set -o pipefail

print_info() { echo "[INFO] $1"; }
print_error() { echo "[ERROR] $1"; }
print_header() {
  echo ""
  echo "========================================"
  echo "  $1"
  echo "========================================"
  echo ""
}

print_header "Starting chroot setup"

# 1. Time and locale
print_info "Setting timezone and locale..."
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
hwclock --systohc

sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "KEYMAP=us" > /etc/vconsole.conf

# 2. Hostname
print_info "Setting hostname..."
echo "$HOSTNAME" > /etc/hostname
cat > /etc/hosts << HOSTS
127.0.0.1 localhost
::1 localhost
127.0.1.1 $HOSTNAME.localdomain $HOSTNAME
HOSTS

# 3. Users and passwords
print_info "Setting up users..."
useradd -m -G wheel,audio,video,optical,input,storage,power -s /bin/bash "$USERNAME"
echo "$USERNAME:$USER_PASS" | chpasswd
echo "root:$ROOT_PASS" | chpasswd

echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

# 4. Copy configs to user home
print_info "Copying configs to user home..."
if [ -d "/root/.config" ]; then
  mkdir -p /home/$USERNAME/.config
  cp -r /root/.config/* /home/$USERNAME/.config/ 2>/dev/null || true
  chown -R $USERNAME:$USERNAME /home/$USERNAME/.config
fi

if [ -d "/root/.local" ]; then
  mkdir -p /home/$USERNAME/.local
  cp -r /root/.local/* /home/$USERNAME/.local/ 2>/dev/null || true
  chown -R $USERNAME:$USERNAME /home/$USERNAME/.local
fi
if [-f "/root/.xinitrc" ]; then
for f in .bashrc .bash_profile .profile .xinitrc .xsession .zshrc .fehbg; do
  if [ -f "/root/$f" ]; then
    cp "/root/$f" "/home/$USERNAME/" 2>/dev/null || true
    chown $USERNAME:$USERNAME "/home/$USERNAME/$f"
  fi
done

# 5. Make scripts executable
if [ -d "/usr/local/bin" ]; then
  chmod +x /usr/local/bin/* 2>/dev/null || true
fi

# 6. CRITICAL: Install GRUB
print_header "Installing GRUB"

if [[ "$BOOT_FW" == "efi" ]]; then
  print_info "Installing GRUB for UEFI..."
  
  # Verify EFI directory is mounted
  if ! mountpoint -q /boot; then
    print_error "ERROR: /boot is not mounted!"
    exit 1
  fi
  
  # Create EFI directory structure
  mkdir -p /boot/EFI
  
  # Install GRUB to EFI
  grub-install \
    --target=x86_64-efi \
    --efi-directory=/boot \
    --bootloader-id=GRUB \
    --removable \
    --recheck \
    --debug
  
  # For some systems, also install to the fallback location
  if [ -d "/boot/EFI/GRUB" ]; then
    mkdir -p /boot/EFI/BOOT
    cp /boot/EFI/GRUB/grubx64.efi /boot/EFI/BOOT/BOOTX64.EFI 2>/dev/null || true
  fi
  
else
  print_info "Installing GRUB for BIOS..."
  
  # Install GRUB to MBR
  grub-install \
    --target=i386-pc \
    --recheck \
    --debug \
    "$DISK"
fi

# 7. Generate GRUB config
print_info "Generating GRUB configuration..."
grub-mkconfig -o /boot/grub/grub.cfg

# Verify GRUB was installed correctly
print_header "Verifying GRUB Installation"

if [[ "$BOOT_FW" == "efi" ]]; then
  if [ -f "/boot/EFI/GRUB/grubx64.efi" ] || [ -f "/boot/EFI/BOOT/BOOTX64.EFI" ]; then
    print_info "✓ GRUB EFI installed successfully"
    ls -la /boot/EFI/GRUB/ 2>/dev/null || true
    ls -la /boot/EFI/BOOT/ 2>/dev/null || true
  else
    print_error "✗ GRUB EFI files NOT found!"
    find /boot -name "*.efi" 2>/dev/null || true
    exit 1
  fi
else
  print_info "✓ GRUB BIOS installed successfully"
fi

if [ -f "/boot/grub/grub.cfg" ]; then
  print_info "✓ GRUB config found"
else
  print_error "✗ GRUB config NOT found!"
  exit 1
fi

# 8. Enable services
print_info "Enabling services..."
systemctl enable NetworkManager
systemctl enable sshd

# Enable custom services
for service in /etc/systemd/system/*.service; do
  if [ -f "$service" ] && [ ! -L "$service" ]; then
    name=$(basename "$service" .service)
    case "$name" in
      choose-mirror|fix-permissions|pacman-init|livecd-*|xorg)
        continue
        ;;
    esac
    systemctl enable "$name" 2>/dev/null || true
  fi
done

print_header "Chroot setup complete"
print_info "All steps completed successfully!"
EOF

# Make the chroot script executable
chmod +x /mnt/root/setup-chroot.sh

# Run the chroot script with all variables
print_info "Running chroot setup..."
arch-chroot /mnt /bin/bash -c "
  export HOSTNAME='$HOSTNAME'
  export USERNAME='$USERNAME'
  export USER_PASS='$USER_PASS'
  export ROOT_PASS='$ROOT_PASS'
  export BOOT_FW='$BOOT_FW'
  export DISK='$DISK'
  /root/setup-chroot.sh
"

# Check if chroot succeeded
if [ $? -eq 0 ]; then
  print_info "Chroot setup completed successfully"
else
  print_error "Chroot setup failed!"
  exit 1
fi

# Clean up
rm /mnt/root/setup-chroot.sh

# Copy log
cp "$LOGFILE" "/mnt/var/log/$(basename "$LOGFILE")" 2>/dev/null || true

# ---------------------------------------------------------------------------
# Final verification before unmounting
# ---------------------------------------------------------------------------
print_header "Final Verification"

print_info "Checking boot files..."
if [[ "$BOOT_FW" == "efi" ]]; then
  if [ -f "/mnt/boot/EFI/GRUB/grubx64.efi" ] || [ -f "/mnt/boot/EFI/BOOT/BOOTX64.EFI" ]; then
    print_info "✓ GRUB EFI files found"
    ls -la /mnt/boot/EFI/ 2>/dev/null || true
  else
    print_error "✗ GRUB EFI files NOT found!"
    find /mnt/boot -name "*.efi" 2>/dev/null || true
  fi
else
  print_info "✓ BIOS GRUB should be installed"
fi

if [ -f "/mnt/boot/grub/grub.cfg" ]; then
  print_info "✓ GRUB config found"
else
  print_error "✗ GRUB config NOT found!"
fi

if [ -d "/mnt/home/$USERNAME/.config" ]; then
  print_info "✓ User configs found"
fi

if [ -d "/mnt/usr/local/bin" ] && [ "$(ls -A /mnt/usr/local/bin 2>/dev/null)" ]; then
  print_info "✓ Custom scripts found in /usr/local/bin"
fi

# Unmount
print_info "Unmounting..."
umount -R /mnt

print_header "Installation Complete!"
echo -e "${GREEN}✓ Your Arch Linux system is installed and ready to boot!${NC}"
echo -e ""
echo -e "${YELLOW}What was copied from the live system:${NC}"
echo -e "  • /root/.config → i3, polybar, picom, rofi configs"
echo -e "  • /usr/local/bin → custom scripts"
echo -e "  • /root/.* → all dotfiles"
echo -e "  • Wallpapers, fonts, and systemd services"
echo -e "  • Network and system configurations"
echo -e ""
echo -e "${YELLOW}Packages installed:${NC}"
echo -e "  • From /root/packages.x86_64: $(cat /root/packages.x86_64 | grep -v "^#" | grep -v "^$" | wc -l) packages"
echo -e "  • Plus essential system packages"
echo -e ""
echo -e "${YELLOW}Log file:${NC} $LOGFILE"
echo -e ""
echo -e "${YELLOW}GRUB Installation:${NC}"
if [[ "$BOOT_FW" == "efi" ]]; then
  echo -e "  • UEFI mode detected"
  echo -e "  • GRUB installed to /boot/EFI/GRUB/"
  echo -e "  • Fallback boot: /boot/EFI/BOOT/BOOTX64.EFI"
  echo -e ""
  echo -e "${RED}IMPORTANT UEFI REQUIREMENTS:${NC}"
  echo -e "  1. Disable Secure Boot in BIOS"
  echo -e "  2. Set boot mode to UEFI (not Legacy/CSM)"
  echo -e "  3. If GRUB doesn't appear, select 'UEFI Hard Disk'"
else
  echo -e "  • BIOS mode detected"
  echo -e "  • GRUB installed to MBR of $DISK"
  echo -e ""
  echo -e "${RED}IMPORTANT BIOS REQUIREMENTS:${NC}"
  echo -e "  1. Make sure disk is first in boot order"
fi
echo -e ""
echo -e "${GREEN}Next steps:${NC}"
echo -e "  1. Reboot system"
echo -e "  2. Login as ${YELLOW}$USERNAME${NC}"
echo -e "  3. Run ${YELLOW}startx${NC} to start i3"
echo -e "  4. Your i3 config will be exactly as it was on the live system"
echo -e ""
echo -e "${BLUE}Enjoy your new Arch Linux system!${NC}"
