// ---------------------------------------------------------
// BRIGHTNESS  — the kernel gives no change events for the backlight,
// so the brightness keys tell the bar after changing it
// (qs ipc call osd brightness, see Osd.qml and hypr/dots/keybindings.lua).
// refresh() reads the level back as a plain linear percentage.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real level: 0          // 0..1
    signal touched()

    function refresh() { read.running = true; }

    // output looks like:  amdgpu_bl1,backlight,32768,50%,65535
    Process {
        id: read
        command: ["brightnessctl", "-m"]
        stdout: StdioCollector {
            onStreamFinished: {
                const f = this.text.split(",");
                const cur = parseInt(f[2]), max = parseInt(f[4]);
                if (!(max > 0)) return;
                root.level = cur / max;
                root.touched();
            }
        }
    }
}
