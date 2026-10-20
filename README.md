# niri + quickshell config bundle

Copied from `cachyos-x8664` on 2026-10-20. Contains **only** `~/.config/niri`
and `~/.config/quickshell`.

## Install

```sh
git clone git@github.com:ChiengPViphop/niri-quickshell-config.git
cd niri-quickshell-config
./install.sh
```

Existing configs are moved to `*.bak-<timestamp>` first. `install.sh` also
rewrites the hardcoded `/home/chiengpviphop` in `niri/startup.kdl`, so it works
under any username.

## Packages

```sh
sudo pacman -S --needed niri quickshell wezterm brightnessctl cliphist \
    wl-clipboard networkmanager bluez bluez-utils pipewire pipewire-pulse \
    wireplumber upower adwaita-icon-theme cachyos-wallpapers \
    noto-fonts noto-fonts-emoji ttf-jetbrains-mono-nerd
```

- `quickshell` 0.3.2+ is required (config uses `Quickshell.Services.*`,
  `Quickshell.Bluetooth`, `Quickshell.Networking`, `Quickshell.Wayland`).
- `fcitx5` is only needed if you keep the `us,kh` keyboard layout indicator in
  the bar.
- Optional but referenced by keybinds: `playerctl` (media keys), `strata`,
  `helium-browser`, `orca` (screen reader).

## What the config expects

| Item | Detail |
|---|---|
| Autostart | `startup.kdl` runs `qs -n` and `wl-paste --watch cliphist store` |
| Icons | `QS_ICON_THEME=Adwaita` — without it tray/fcitx icons fall back to placeholders |
| Terminal | `TERMINAL=wezterm` for niri-spawned apps; `Mod+Return` hardcodes `wezterm` |
| Wallpaper | `/usr/share/wallpapers/cachyos-wallpapers/BlueFeathers.png` (`cachyos-wallpapers`) |
| Fonts | bar picks the first installed of JetBrainsMono Nerd Font, MesloLGS NF, FantasqueSansM Nerd Font Mono |
| Layout | `input.kdl` sets `us,kh` with `grp:alt_shift_toggle`; touchpad tap/natural-scroll on |
| Monitor | `outputs.kdl` is fully commented out, so niri auto-detects mode/scale |
| Lockscreen | `Super+L` calls `~/.local/share/quickshell-lockscreen/lock.sh` — **not included** (qylock repo) |
| SDDM | Uses the `orbital` theme from qylock, installed system-wide, not in this bundle |

## Not included

`~/.local/bin`, `~/.local/opt` (Go/Node), nvim, fish, wezterm, fcitx5, qylock,
browser profiles, package lists, and SDDM/system configs.
