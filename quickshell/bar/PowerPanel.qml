// ---------------------------------------------------------
// POWER  — dropdown of the quick pill's power icon.
// Lock · Log out · Suspend · Reboot · Shut down
// Log out / reboot / shut down go through hyprshutdown (apps are asked to
// close first; its dialog has Cancel), falling back to a plain exit.
// The logout command matches SUPER + M in hypr/dots/keybindings.lua.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import qs

Column {
    id: root

    signal done()                               // an action ran: close the dropdown

    width: 220
    spacing: 6

    // hyprshutdown with a label and an optional command after Hyprland exits
    function leave(label, after) {
        const post = "systemctl --user stop graphical-session.target" + (after ? "; " + after : "");
        return "command -v hyprshutdown >/dev/null 2>&1 && "
             + "hyprshutdown -t '" + label + "' --post-cmd '" + post + "' "
             + "|| { hyprctl dispatch 'hl.dsp.exit()'; " + (after || "true") + "; }";
    }

    readonly property var actions: [
        { icon: "lock",   text: "Lock",      cmd: "loginctl lock-session" },
        { icon: "logout", text: "Log out",   cmd: leave("Logging out...", "") },
        { icon: "sleep",  text: "Suspend",   cmd: "systemctl suspend" },
        { icon: "reboot", text: "Reboot",    cmd: leave("Restarting...", "systemctl reboot") },
        { icon: "power",  text: "Shut down", cmd: leave("Shutting down...", "systemctl poweroff") }
    ]

    Repeater {
        model: root.actions
        ListRow {
            required property var modelData
            width: root.width
            icon: modelData.icon
            text: modelData.text
            onClicked: {
                root.done();
                Quickshell.execDetached(["sh", "-c", modelData.cmd]);
            }
        }
    }
}
