#!/usr/bin/env bash
# install.sh — link basic-hypr into place (works from wherever you cloned it)
#
#   ./install.sh            create the symlinks
#   ./install.sh --dry-run  only show what would happen
#   ./install.sh --kwallet  also make KDE Wallet the password store (Secret
#                           Service) instead of gnome-keyring — opt-in, see
#                           dbus/org.freedesktop.secrets.service
#
# Anything already at a target is moved to <target>.bak.<timestamp>, never deleted.
# Running it again is safe: links that are already correct are skipped.

set -euo pipefail

# --- where things are ------------------------------------------------------
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"   # this repo, wherever it lives
CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
STAMP="$(date +%Y%m%d-%H%M%S)"
DRY=0
KWALLET=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) DRY=1 ;;
        --kwallet) KWALLET=1 ;;
        *) echo "unknown option: $arg" >&2; exit 1 ;;
    esac
done

run() { if [ "$DRY" = 1 ]; then echo "    would: $*"; else "$@"; fi; }

# link <file-or-folder in repo> <where it should appear>
link() {
    local src="$REPO/$1" dest="$2"
    if [ -L "$dest" ] && [ "$(readlink -f "$dest")" = "$(readlink -f "$src")" ]; then
        echo "  ok    ${dest/#$HOME/\~}"
        return
    fi
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        echo "  backup ${dest/#$HOME/\~} -> ${dest/#$HOME/\~}.bak.$STAMP"
        run mv "$dest" "$dest.bak.$STAMP"
    fi
    echo "  link  ${dest/#$HOME/\~} -> $src"
    run mkdir -p "$(dirname "$dest")"
    run ln -s "$src" "$dest"
}

echo "basic-hypr: $REPO"
[ "$DRY" = 1 ] && echo "(dry run — nothing will change)"

# --- the links ---------------------------------------------------------------
echo; echo "configs"
link hypr    "$CONFIG/hypr"
link rofi    "$CONFIG/rofi"
link kitty   "$CONFIG/kitty"
link quickshell "$CONFIG/quickshell"

echo; echo "scripts"
run chmod +x "$REPO/scripts/"*.sh
link scripts/screenshot.sh "$HOME/.local/scripts/screenshot.sh"
link scripts/theme.sh      "$HOME/.local/scripts/theme.sh"

if [ "$KWALLET" = 1 ]; then
    echo; echo "password store: KDE Wallet (--kwallet)"
    if command -v ksecretd >/dev/null; then
        link dbus/org.freedesktop.secrets.service "$DATA/dbus-1/services/org.freedesktop.secrets.service"
    else
        echo "  skipped: ksecretd not found (needs KDE Wallet / kf6-kwallet)"
    fi
fi

echo; echo "cursor theme"
link cursors/Robot "$DATA/icons/Robot"
link cursors/Robot "$HOME/.icons/Robot"      # Plasma's cursor settings only look in ~/.icons

# --- what's missing (warn only, installs nothing) -----------------------------
echo; echo "checking dependencies"
missing=()
for cmd in Hyprland hyprpaper hyprpicker rofi kitty qs brightnessctl grim slurp wl-copy jq xdg-user-dir dolphin; do
    command -v "$cmd" >/dev/null || missing+=("$cmd")
done
fonts="$(fc-list : family)"   # read once; piping into grep -q breaks under pipefail
for font in "Hack Nerd Font" "JetBrainsMono Nerd Font"; do
    grep -qi "$font" <<<"$fonts" || missing+=("font: $font")
done
icons_found=0
for d in "$DATA/icons" "$HOME/.icons" /usr/share/icons; do
    [ -d "$d/Papirus-Dark" ] && icons_found=1
done
[ "$icons_found" = 1 ] || missing+=("icon theme: Papirus-Dark")

if [ ${#missing[@]} -eq 0 ]; then
    echo "  all good"
else
    printf '  missing: %s\n' "${missing[@]}"
    echo "  (see README.md for what each is for)"
fi

# --- done --------------------------------------------------------------------
echo
echo "next:"
echo "  - set your wallpaper:   $REPO/hypr/hyprpaper.conf"
echo "  - check your monitor:   $REPO/hypr/dots/monitors.lua  (scale!)"
echo "  - then log out/in, or:  hyprctl reload"
