// Open/close a panel on the focused monitor:
//   qs ipc call panel toggle   calendar + timer panel
//   qs ipc call panel open sound   a quick-pill dropdown: network, bluetooth,
//                                  sound, battery or power
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    signal toggle()
    signal openPanel(string name)

    IpcHandler {
        target: "panel"
        function toggle(): void { root.toggle(); }
        function open(name: string): void { root.openPanel(name); }
    }
}
