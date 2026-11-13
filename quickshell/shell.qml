// ==========================================================
// QUICKSHELL ENTRY POINT  (like hyprland.lua / config.rasi)
// Only wires things together; looks live in Theme.qml,
// data lives in services/, the pills live in bar/.
//
// Run by hand while editing (reloads on save):   qs
// Poke it from a shell:                          qs ipc show
// ==========================================================

//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import qs.bar

ShellRoot {
    // one bar per monitor; added/removed as screens come and go
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    // power screen (CTRL + ALT + Delete); shows only on the monitor it opened on
    Variants {
        model: Quickshell.screens

        PowerMenu {}
    }
}
