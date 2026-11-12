#!/usr/bin/env bash
# logout.sh — leave Hyprland cleanly (SUPER + M)
#
# Exiting Hyprland straight away makes the background programs that are
# still connected to it (portals, polkit agent, hyprpaper) crash with a
# segfault when the display disappears. So, in order:
#   1. ask app windows to close   (hyprshutdown, while portals still run)
#   2. stop hyprpaper + quickshell (normal SIGTERM)
#   3. stop the session services   (portals, polkit agent: part of graphical-session.target)
#   4. exit Hyprland
# Without hyprshutdown, step 1 is skipped (Hyprland closes the windows itself).

set -uo pipefail

if command -v hyprshutdown >/dev/null; then
    # --no-fork: wait here until the apps are closed · --no-exit: we exit below
    hyprshutdown --no-fork --no-exit -t "Logging out..."
fi

pkill -TERM -x hyprpaper
pkill -TERM -x qs

systemctl --user stop graphical-session.target

hyprctl dispatch 'hl.dsp.exit()'
