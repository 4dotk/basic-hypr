// ---------------------------------------------------------
// BAR STATE  — whether the bar is hidden (SUPER + F).
// While hidden, only the centre pill pops in for the OSD and notifications.
//
//   qs ipc call bar toggle | show | hide
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool hidden: false

    IpcHandler {
        target: "bar"
        function toggle(): void { root.hidden = !root.hidden; }
        function show(): void { root.hidden = false; }
        function hide(): void { root.hidden = true; }
    }
}
