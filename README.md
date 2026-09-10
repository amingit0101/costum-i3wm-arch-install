<div align="center">

# 🐧 Custom Arch Linux ISO

**A personalized Arch Linux live ISO built with archiso, featuring a pre-configured i3wm desktop environment.**

![Arch Linux](https://img.shields.io/badge/Arch%20Linux-1793D1?style=for-the-badge&logo=arch-linux&logoColor=white)
![i3wm](https://img.shields.io/badge/i3wm-000000?style=for-the-badge&logo=i3&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-green?style=for-the-badge)

</div>

---

## ✨ Features

| Component | Tool | Description |
|---|---|---|
| 🪟 Window Manager | **i3wm** | Tiling window manager |
| 🎨 Compositor | **Picom** | Blur and transparency effects |
| 📊 Status Bar | **Polybar** | Customizable system status |
| 🚀 App Launcher | **Rofi** | App menu, window switcher, power menu |
| 😄 Emoji Picker | **rofi-emoji** | Quick emoji access |
| 💻 Terminal | **Alacritty** | GPU-accelerated terminal |
| 📝 Text Editor | **LazyVim** | Neovim-based IDE |
| 📁 File Manager | **Ranger** | Terminal file explorer with Vim keybindings |

---

## 📦 Included Packages

- 🖥️ **Desktop:** `i3-wm`, `i3status`, `i3lock`
- 🎬 **Display:** `picom`, `xorg-server`, `xorg-xinit`
- 🎛️ **UI:** `polybar`, `rofi`, `rofi-emoji`
- ⌨️ **Terminal:** `alacritty`
- 🛠️ **Development:** `neovim` (LazyVim configured)
- 📂 **File Management:** `ranger`, `feh`

> 📄 Full package list available in [`releng/package.x86_64`](releng/package.x86_64)

---

## 📁 Project Structure

```
archlive/
└── releng/
    ├── package.x86_64          # 📦 Packages to install
    ├── profiledef.sh           # ⚙️ ISO build profile
    └── airootfs/
        ├── root/
        │   ├── .config/               # ⚙️ Custom configs
        │   │   ├── i3/                # 🪟 Window manager config
        │   │   ├── polybar/           # 📊 Status bar config
        │   │   ├── rofi/              # 🚀 Launcher config
        │   │   ├── alacritty/         # 💻 Terminal config
        │   │   ├── nvim/              # 📝 LazyVim config
        │   │   └── ranger/            # 📁 File manager config
        │   └── wallpaper.jpg          # 🖼️ Custom wallpaper
        └── etc/systemd/system/        # 🔧 Service files
```

---

## 🚀 Build

**Prerequisites:**

```bash
sudo pacman -S archiso
```

**Build the ISO:**

```bash
cd /path/to/archlive
sudo mkarchiso -v -w /tmp/archiso-tmp -o ./ releng/
```

---

## 🧪 Testing

<details>
<summary><strong>⚡ run_archiso (Fastest)</strong></summary>

```bash
sudo run_archiso -i ./releng.iso
```
</details>

<details>
<summary><strong>🖥️ QEMU</strong></summary>

Basic:
```bash
qemu-system-x86_64 -cdrom ./releng.iso -m 2048
```

With KVM acceleration:
```bash
qemu-system-x86_64 -cdrom ./releng.iso -m 4096 -enable-kvm -vga virtio
```

With UEFI boot:
```bash
qemu-system-x86_64 -cdrom ./releng.iso -m 4096 -enable-kvm -bios /usr/share/ovmf/x64/OVMF.fd
```
</details>

<details>
<summary><strong>📦 VirtualBox</strong></summary>

1. Create VM: `Linux → Arch Linux (64-bit)`
2. Memory: 2048 MB or more
3. Storage: 20 GB (dynamic)
4. Mount ISO in Storage settings
5. Enable EFI: `Settings → System → Motherboard → Enable EFI`
6. Enable 3D Acceleration: `Settings → Display → Enable 3D Acceleration`
7. Start VM
</details>

<details>
<summary><strong>💼 VMware</strong></summary>

1. Create VM: `Custom → Linux → Other Linux 5.x kernel 64-bit`
2. Memory: 2048 MB
3. Storage: 20 GB
4. Select ISO image
5. Enable EFI: `Settings → Options → Advanced → Enable EFI`
6. Start VM
</details>

### 📊 Testing Comparison

| Method | Speed | Setup | Graphics | Best For |
|---|---|---|---|---|
| **run_archiso** | ⚡⚡⚡ Very Fast | Easy | Minimal | Quick validation |
| **QEMU** | ⚡⚡ Fast | Easy | Good | Fast testing & development |
| **VirtualBox** | ⚡ Medium | Moderate | Very Good | Comprehensive testing |
| **VMware** | ⚡⚡ Fast | Moderate | Excellent | Performance testing |

---

## 🎛️ Customization

### Add Packages

Edit `releng/package.x86_64` and add packages one per line.

### Add Config Files

Place configs in `releng/airootfs/root/.config/`

```
.config/
├── i3/config
├── polybar/config.ini
├── alacritty/alacritty.yml
└── rofi/config.rasi
```

### Enable Services

**Custom service:**

```bash
# 1. Create the service file
releng/airootfs/etc/systemd/system/my-service.service

# 2. Enable it
cd releng/airootfs/etc/systemd/system/multi-user.target.wants
ln -sf ../my-service.service ./my-service.service
```

**Package service:**

```bash
cd releng/airootfs/etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/service-name.service ./service-name.service
```

**Example (NetworkManager):**

```bash
cd releng/airootfs/etc/systemd/system/multi-user.target.wants
ln -sf /usr/lib/systemd/system/NetworkManager.service ./NetworkManager.service
```

---

## ⚡ Quick Commands

| Action | Command |
|---|---|
| 🔨 Build ISO | `sudo mkarchiso -v -w /tmp/archiso-tmp -o ./ releng/` |
| 🧪 Quick Test | `sudo run_archiso -i ./releng.iso` |
| 🖥️ QEMU Test | `qemu-system-x86_64 -cdrom ./releng.iso -m 2048` |
| 💾 Flash to USB | `sudo dd if=releng.iso of=/dev/sdX bs=4M status=progress` |

> ⚠️ **Warning:** Double-check `/dev/sdX` before flashing — this command will overwrite the target device.

---

## 📝 Notes

- 🖼️ Wallpaper path: `/root/wallpaper.jpg` (adjust in configs) — actual file: `/root/feh_023357_000001_679ef8d58ea071f0f6c5e92b7c4b7785.jpg`
- 👤 Default user is `root` (add a user for security)
- 🌐 Network is managed by NetworkManager (enable the service)
- 🔐 For UEFI support, configure in `profiledef.sh`

---

## 🙏 Credits

- [Arch Linux](https://archlinux.org) and [archiso](https://gitlab.archlinux.org/archlinux/archiso)
- All open-source projects included

## 📄 License

Distributed under the **MIT License**.
