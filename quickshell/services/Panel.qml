// Open/close the calendar + timer panel on the focused monitor:
//   qs ipc call panel toggle
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    signal toggle()

    IpcHandler {
        target: "panel"
        function toggle(): void { root.toggle(); }
    }
}
