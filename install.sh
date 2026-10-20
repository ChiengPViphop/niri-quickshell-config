#!/usr/bin/env bash
# Install the niri + quickshell config from this bundle.
#
#   ./install.sh
#
# Existing ~/.config/niri and ~/.config/quickshell are moved aside, not deleted.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
conf="${XDG_CONFIG_HOME:-$HOME/.config}"
stamp=$(date +%Y%m%d-%H%M%S)

for d in niri quickshell; do
    src="$here/config/$d"
    dst="$conf/$d"
    [[ -d $src ]] || { printf 'missing %s\n' "$src" >&2; exit 1; }
    mkdir -p -- "$conf"
    if [[ -e $dst ]]; then
        printf 'backing up %s -> %s.bak-%s\n' "$dst" "$dst" "$stamp"
        mv -- "$dst" "$dst.bak-$stamp"
    fi
    cp -a -- "$src" "$dst"
    printf 'installed %s\n' "$dst"
done

# The original config hardcodes /home/chiengpviphop (the PATH in
# niri/startup.kdl). Rewrite it for whoever runs this installer.
while IFS= read -r f; do
    sed -i "s|/home/chiengpviphop|$HOME|g" -- "$f"
    printf 'rewrote home path in %s\n' "$f"
done < <(grep -rl -- '/home/chiengpviphop' "$conf/niri" "$conf/quickshell" 2>/dev/null || true)

# Runtime dependencies (warn only, install is your call).
missing=()
for c in niri qs wezterm brightnessctl cliphist wl-paste nmcli loginctl; do
    command -v -- "$c" >/dev/null 2>&1 || missing+=("$c")
done
if (( ${#missing[@]} )); then
    printf '\nWARNING: not found in PATH: %s\n' "${missing[*]}"
    printf '  sudo pacman -S --needed niri quickshell wezterm brightnessctl cliphist \\\n'
    printf '                        wl-clipboard networkmanager adwaita-icon-theme\n'
fi

if [[ ! -x "$HOME/.local/share/quickshell-lockscreen/lock.sh" ]]; then
    printf '\nNOTE: Super+L runs ~/.local/share/quickshell-lockscreen/lock.sh, which is\n'
    printf '      NOT part of this bundle (installed by the qylock repo).\n'
fi

printf '\nDone. Log out and pick the niri session, then check with: niri validate\n'
