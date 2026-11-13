// ---------------------------------------------------------
// AUDIO  — PipeWire state for the bar.
//   sink / volume / muted   the default output; touched() drives the OSD
//   source / micMuted       the default mic (quick pill shows a muted-mic icon)
//   outputs / inputs / apps every device and every app playing sound
//                           (the Sound tab of the quick panel)
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

    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool micMuted: source?.audio?.muted ?? false

    // ---- lists (Pipewire.nodes is an ObjectModel; .values is the array) ----
    readonly property var outputs: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var inputs:  Pipewire.nodes.values.filter(n => n.audio && !n.isSink && !n.isStream)
    readonly property var apps:    Pipewire.nodes.values.filter(n => n.audio && n.isStream && !n.isSink)

    signal touched()

    // PipeWire nodes report nothing (no volume, no properties) until they are bound
    PwObjectTracker { objects: [root.sink, root.source, ...root.outputs, ...root.inputs, ...root.apps] }

    // ---- helpers ----
    // shown name of a device: description, then nickname, then name
    // (the nickname is often the codec, e.g. "ALC3204 Analog" for both speaker and headset mic)
    function label(node) {
        return node?.description || node?.nickname || node?.name || "";
    }

    // make a device the default (a hint: PipeWire may still pick another)
    function setDefault(node) {
        if (node.isSink) Pipewire.preferredDefaultAudioSink = node;
        else Pipewire.preferredDefaultAudioSource = node;
    }

    // set a node's volume, capped at 0–100 %
    function setVolume(node, v) {
        if (node?.audio) node.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute(node) {
        if (node?.audio) node.audio.muted = !node.audio.muted;
    }

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
