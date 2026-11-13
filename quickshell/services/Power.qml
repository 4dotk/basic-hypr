// ---------------------------------------------------------
// POWER  — the power screen's state and actions (bar/PowerMenu.qml).
//   qs ipc call power toggle      open / close it on the focused monitor
//   (bound to CTRL + ALT + Delete in hypr/dots/keybindings.lua)
// Lock · Log out · Suspend · Reboot · Shut down.
// Log out / reboot / shut down go through hyprshutdown (apps are asked to
// close first; its dialog has Cancel), falling back to a plain exit.
// The logout command matches SUPER + M.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    property bool open: false
    property string monitor: ""             // the monitor it opened on

    // hyprshutdown with a label and an optional command after Hyprland exits
    function leave(label, after) {
        const post = "systemctl --user stop graphical-session.target" + (after ? "; " + after : "");
        return "command -v hyprshutdown >/dev/null 2>&1 && "
             + "hyprshutdown -t '" + label + "' --post-cmd '" + post + "' "
             + "|| { hyprctl dispatch 'hl.dsp.exit()'; " + (after || "true") + "; }";
    }

    // quick: runs at once · otherwise the tile first grows to fill the screen
    readonly property var actions: [
        { icon: "lock",   text: "Lock",      quick: true,  cmd: "loginctl lock-session" },
        { icon: "logout", text: "Log out",   quick: false, doing: "Logging out…",   cmd: leave("Logging out...", "") },
        { icon: "sleep",  text: "Suspend",   quick: true,  cmd: "systemctl suspend" },
        { icon: "reboot", text: "Reboot",    quick: false, doing: "Restarting…",    cmd: leave("Restarting...", "systemctl reboot") },
        { icon: "power",  text: "Shut down", quick: false, doing: "Shutting down…", cmd: leave("Shutting down...", "systemctl poweroff") }
    ]

    function show() {
        monitor = Hyprland.focusedMonitor?.name ?? "";
        open = true;
    }
    function close() { open = false; }
    function run(action) {
        open = false;
        Quickshell.execDetached(["sh", "-c", action.cmd]);
    }

    IpcHandler {
        target: "power"
        function toggle(): void { root.open ? root.close() : root.show(); }
        function open(): void { root.show(); }
        function close(): void { root.close(); }
    }
}
