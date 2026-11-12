#!/usr/bin/env bash
# theme.sh — switch the basic-hypr colour theme (quickshell bar + rofi)
#
#   theme.sh            pick from a rofi menu
#   theme.sh <name>     switch directly: vague (default), basic
#   theme.sh list       show the themes (* = current)
#
# The choice is saved in ~/.local/state/basic-hypr/ (outside the repo):
#   theme                 the name, read by the quickshell bar at start
#   rofi-theme.rasinc     link to rofi/dots/themes/<name>.rasinc
# The running bar is told directly, so it recolours straight away.
# Themes = the files in rofi/dots/themes/ (each needs a palette in quickshell/Theme.qml).

set -euo pipefail

REPO="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/.." && pwd)"
THEMES="$REPO/rofi/dots/themes"
STATE="${XDG_STATE_HOME:-$HOME/.local/state}/basic-hypr"

mapfile -t themes < <(find "$THEMES" -name '*.rasinc' -printf '%f\n' | sed 's/\.rasinc$//' | sort)
current="$(cat "$STATE/theme" 2>/dev/null || echo vague)"

case "${1:-}" in
    list)
        for t in "${themes[@]}"; do
            [ "$t" = "$current" ] && echo "* $t" || echo "  $t"
        done
        exit 0
        ;;
    "")
        name="$(printf '%s\n' "${themes[@]}" | rofi -dmenu -p Theme -select "$current")" || exit 0
        ;;
    *)
        name="$1"
        ;;
esac

if [ ! -f "$THEMES/$name.rasinc" ]; then
    echo "theme.sh: no theme '$name' (have: ${themes[*]})" >&2
    exit 1
fi

mkdir -p "$STATE"
echo "$name" > "$STATE/theme"
ln -sfn "$THEMES/$name.rasinc" "$STATE/rofi-theme.rasinc"

# recolour the running bar (fine if quickshell isn't running)
qs ipc call theme set "$name" >/dev/null 2>&1 || true

echo "theme: $name"
