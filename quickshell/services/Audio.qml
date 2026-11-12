// ---------------------------------------------------------
// AUDIO  — volume + mute of the default output (PipeWire).
// Fires touched() when either changes, which drives the OSD.
// No keybinding changes needed: wpctl changes show up here by themselves.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted:  sink?.audio?.muted ?? false

    signal touched()

    // PipeWire nodes report nothing until they are bound
    PwObjectTracker { objects: [root.sink] }

    // Stay quiet while starting up or switching outputs (headphones in/out),
    // otherwise the OSD would pop up on its own.
    property bool armed: false
    onSinkChanged: { armed = false; settle.restart(); }
    Timer { id: settle; interval: 800; onTriggered: root.armed = true }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() { if (root.armed) root.touched(); }
        function onMutedChanged()  { if (root.armed) root.touched(); }
    }
}
