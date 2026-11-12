#!/usr/bin/env bash
# screenshot.sh — tiny Hyprland screenshot tool (grim + slurp + wl-copy)
#
#   screenshot.sh region   drag to select an area (screen freezes while you pick)
#   screenshot.sh window   the focused window
#   screenshot.sh screen   the focused monitor
#
# Every shot is saved AND copied to the clipboard.
# Save folder: $SCREENSHOT_DIR, or ~/Pictures/Screenshots by default.
# Notifications: TODO once the Quickshell bar can show them.

set -euo pipefail

mode="${1:-region}"
dir="${SCREENSHOT_DIR:-$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/Screenshots}"
file="$dir/Screenshot_$(date +%Y%m%d_%H%M%S).png"   # same naming as your old shots
mkdir -p "$dir"

# slurp look: -b dims everything outside the box, -s = inside the box
# (fully clear, so you see true colours), -c/-w = accent border (rofi @accent)
slurp_style=(-b '#00000066' -c '#11aabbff' -s '#00000000' -w 2)

case "$mode" in
    region)
        # Freeze the screen so menus/tooltips stay put while selecting.
        # hyprpicker -r = render a frozen frame, -z = no zoom lens.
        freeze_pid=""
        if command -v hyprpicker >/dev/null; then
            hyprpicker -r -z >/dev/null 2>&1 &
            freeze_pid=$!
            sleep 0.15                              # let the frozen frame appear
        fi
        unfreeze() { [ -n "$freeze_pid" ] && kill "$freeze_pid" 2>/dev/null && wait "$freeze_pid" 2>/dev/null || true; }
        trap unfreeze EXIT

        # Esc / right-click in slurp = cancel -> exit quietly, nothing saved
        geometry=$(slurp -d "${slurp_style[@]}") || exit 0
        unfreeze
        sleep 0.05                                  # let the freeze layer vanish before capturing
        grim -g "$geometry" "$file"
        ;;

    window)
        # "at" = top-left corner, "size" = width/height, in layout coordinates
        geometry=$(hyprctl activewindow -j | jq -r 'select(.at != null) | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')
        [ -n "$geometry" ] || { echo "no focused window" >&2; exit 1; }
        grim -g "$geometry" "$file"
        ;;

    screen)
        output=$(hyprctl monitors -j | jq -r '.[] | select(.focused) | .name')
        grim -o "$output" "$file"
        ;;

    *)
        echo "usage: ${0##*/} [region|window|screen]" >&2
        exit 2
        ;;
esac

wl-copy --type image/png < "$file"
echo "$file"
