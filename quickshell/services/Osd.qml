// ---------------------------------------------------------
// OSD  — which level to flash on the clock pill, and for how long.
// kind is "volume" or "brightness"; shown is true for a moment
// after the last change (holding a key keeps it up).
//
// Shown by the media keys:   qs ipc call osd volume | brightness
// and by any other volume change (pavucontrol, apps) via PipeWire.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string kind: "volume"
    property bool shown: false

    function show(k) {
        kind = k;
        shown = true;
        hide.restart();
    }

    Timer { id: hide; interval: 1500; onTriggered: root.shown = false }

    IpcHandler {
        target: "osd"
        function volume(): void { root.show("volume"); }
        function brightness(): void { Brightness.refresh(); }   // shows once the new level is read
    }

    Connections {
        target: Audio
        function onTouched() { root.show("volume"); }
    }
    Connections {
        target: Brightness
        function onTouched() { root.show("brightness"); }
    }
}
