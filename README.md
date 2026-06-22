# :rocket: dotfiles

> **Disclaimer:** This is very much a "works for me" project. It's opinionated, occasionally held together with duct tape, and makes no guarantees about working on your machine. Use at your own risk — and if you build something cool with it, let me know!

## Screenshots

![Floating windows](/.github/assets/floats.png)

| | |
|---|---|
| ![Main menu](/.github/assets/menu-main.png) | ![Power menu](/.github/assets/menu-power.png) |
| ![Applications menu](/.github/assets/menu-applications.png) | ![Hyprlock](/.github/assets/hyprlock.png) |
| ![Indicators](/.github/assets/indicators.png) | ![Notifications](/.github/assets/notification.png) |
| ![Plymouth](/.github/assets/plymouth.png) | |

## Installation

This is an Arch Linux setup. The initial system is bootstrapped with [archinstall](https://wiki.archlinux.org/title/Archinstall), then the dotfiles `install.sh` handles the rest.

### Initial setup (archinstall)

1. **Mirror select** — choose `us`
2. **Disk** → Partitioning → `best_effort`
3. **Encryption** → LUKS → set a password → select your drive/partition
4. **Bootloader** → `limine`
5. **UKI** → confirm (ok)
6. **Additional packages** → add `pipewire`
7. **Timezone** → select your region

After archinstall finishes and the system reboots, log in and continue below.

### Post-reboot

1. **Install git and a downloader**:

   ```bash
   sudo pacman -S --noconfirm git curl
   ```

2. **Run the bootstrap script**:

   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/viacoffee/dotfiles/master/bootstrap.sh)
   ```

   To install a specific branch, pass `-b`:
   ```bash
   bash <(curl -sL https://raw.githubusercontent.com/viacoffee/dotfiles/master/bootstrap.sh) -b back_to_arch
   ```

## Keyboard Shortcuts

`Mod` is the Super/Windows key.

### System

| Shortcut | Action |
|---|---|
| `Mod+Return` | Open terminal in current working directory |
| `Mod+Shift+Q` | Lock screen |
| `Mod+Escape` | Power menu |
| `Mod+Space` | Application launcher |
| `Mod+Alt+Space` | General menu |
| `Mod+Shift+Space` | Quick AI prompt (Claude) |
| `Mod+V` | Clipboard history |
| `Mod+Shift+F` | File browser (Nautilus) |
| `Mod+Shift+T` | System monitor (btop) in floating terminal |
| `Mod+Alt+D` | Toggle do-not-disturb |
| `Mod+Alt+I` | Toggle idle/screen lock |
| `Mod+Alt+N` | Notification history |

### Window Management

| Shortcut | Action |
|---|---|
| `Mod+H/J/K/L` | Focus window left/down/up/right |
| `Mod+Tab` | Window switcher |
| `Mod+Shift+H/L` | Move column left/right |
| `Mod+Shift+J/K` | Move window down/up |
| `Mod+Alt+H/L` | Consume or expel window left/right |
| `Mod+Ctrl+H/L` | Resize column narrower/wider |
| `Mod+Ctrl+J/K` | Resize window taller/shorter |
| `Mod+W` | Close window |
| `Mod+Shift+W` | Close all unfocused windows on workspace |
| `Mod+F` | Maximize window to edges |
| `Mod+T` | Toggle floating |
| `Mod+M` | Center column |
| `Mod+Shift+M` | Center all visible columns |
| `Mod+O` | Cycle preset column widths |

### Workspaces

| Shortcut | Action |
|---|---|
| `Mod+D` | Focus workspace down |
| `Mod+U` | Focus workspace up |
| `Mod+1`–`9` | Switch to workspace 1–9 |
| `Mod+Shift+1`–`9` | Move window to workspace 1–9 |

### Screenshots

| Shortcut | Action |
|---|---|
| `Mod+P` | Screenshot region (no pointer) |
| `Mod+Shift+P` | Screenshot focused window |
| `Mod+Alt+P` | Screenshot entire screen |

### Audio

| Shortcut | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume up |
| `XF86AudioLowerVolume` | Volume down |
| `XF86AudioMute` | Mute/unmute output |
| `XF86AudioMicMute` | Mute/unmute microphone |

### Brightness

| Shortcut | Action |
|---|---|
| `XF86MonBrightnessUp` | Brightness up |
| `XF86MonBrightnessDown` | Brightness down |

### Terminal (Capslock layer)

| Shortcut | Action |
|---|---|
| `Capslock+C` | Copy (terminal-compatible) |
| `Capslock+V` | Paste (terminal-compatible) |

## Commands

Scripts with no keyboard shortcut or menu entry — invoke these manually from a terminal.

| Command | Description |
|---|---|
| `coffee-theme-background` | Set desktop wallpaper from a file path or URL |
| `coffee-theme-refresh` | Rebuild themed configs from `palette.toml` + templates |

## Aliases

| Alias | Expands to |
|---|---|
| `top`, `htop` | `btop` |
| `ping` | `prettyping --nolegend` |
| `vim` | `nvim` |
| `l` | `lsd -a1` |
| `la` | `lsd -la` |
| `lr` | `lsd -R` |
| `lra` | `lsd -RA` |
| `lt` | `lsd --tree` |
| `gs` | `git status` |
| `gl` | `git log --oneline --graph --decorate` |
| `gp` | `git pull` |
| `gd` | `git diff` |
| `gc` | `git commit` |
| `c` | `clear` |
| `...` | `cd ../..` |
| `....` | `cd ../../..` |
| `cc` | `claude` |
| `oc` | `opencode` |

## Stack

| Category | Tools |
|---|---|
| **Compositor** | [niri](https://github.com/YaLTeR/niri) — scrollable-tiling Wayland compositor |
| **Session manager** | [uwsm](https://github.com/Vladimir-csp/uwsm) — Universal Wayland Session Manager |
| **Login manager** | [greetd](https://sr.ht/~kennylevinsen/greetd/) |
| **Terminal** | [Alacritty](https://alacritty.org/) |
| **Shell** | [Zsh](https://www.zsh.org/) + [Starship](https://starship.rs/) prompt |
| **Editor** | [Neovim](https://neovim.io/) via [NvChad](https://nvchad.com/) (lazy.nvim, nvim-lspconfig, nvim-treesitter, conform.nvim) |
| **Bar** | [Waybar](https://github.com/Alexays/Waybar) |
| **Launcher** | [fuzzel](https://codeberg.org/dnkl/fuzzel) |
| **Notifications** | [mako](https://github.com/emersion/mako) |
| **Lock screen** | [hyprlock](https://github.com/hyprwm/hyprlock) |
| **Wallpaper** | [swaybg](https://github.com/swaywm/swaybg) |
| **Idle management** | [swayidle](https://github.com/swaywm/swayidle) |
| **OSD overlays** | [swayosd](https://github.com/ErikReider/SwayOSD) |
| **Boot splash** | [plymouth](https://gitlab.freedesktop.org/plymouth/plymouth) |
| **Clipboard** | [cliphist](https://github.com/sentriz/cliphist) + wl-clipboard |
| **Screenshots** | [grim](https://sr.ht/~emersion/grim/) + [slurp](https://github.com/emersion/slurp) |
| **Screen recording** | [gpu-screen-recorder](https://git.dec05eba.com/gpu-screen-recorder/) |
| **File manager** | [Nautilus](https://apps.gnome.org/Nautilus/) |
| **Media** | [mpv](https://mpv.io/) · [imv](https://sr.ht/~exec64/imv/) · [playerctl](https://github.com/altdesktop/playerctl) |
| **Audio mixer** | [wiremix](https://github.com/nicholasgasior/wiremix) |
| **Bluetooth** | [bluetui](https://github.com/pythops/bluetui) |
| **Wi-Fi** | [impala](https://github.com/pythops/impala) + [iwd](https://iwd.wiki.kernel.org/) |
| **System monitor** | [btop](https://github.com/aristocratos/btop) |
| **File listing** | [lsd](https://github.com/lsd-rs/lsd) |
| **Snapshots** | [snapper](https://github.com/openSUSE/snapper) + limine-snapper-sync |
| **Bootloader** | [limine](https://limine-bootloader.org/) |
| **Disk encryption** | LUKS via cryptsetup |
| **Firewall** | [ufw](https://wiki.archlinux.org/title/Uncomplicated_Firewall) |
| **AUR helper** | [yay](https://github.com/Jguer/yay) |
| **Dotfiles management** | [GNU stow](https://www.gnu.org/software/stow/) |
