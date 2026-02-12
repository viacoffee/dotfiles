# :computer: dotfiles

customization:
- install/defaults.sh
- install/desktop.packages (see _Optional_ comment in file)

## Installation
_setfont -d_

1. archlinux install with LUKS, btrfs, lilime, snapper
2. sudo pacman -S git


Exec=env PATH=$HOME/.local/bin:$PATH systemd-run --user --scope niri-session
usr/local/share/wayland-sessions/niri.desktop

ps -eo pid,ppid,cmd | grep waybar | grep -v grep
systemctl --user show-environment | grep PATH

spawn-at-startup "systemctl --user import-environment PATH"
