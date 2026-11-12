// ---------------------------------------------------------
// COUNTDOWN  — the timer. (Not called Timer: that name is QML's own.)
// Counts against the wall clock, so it stays right across suspend.
// At zero: an urgent notification that stays until clicked, and the alarm
// sound every 4 s until it is clicked (at most 1 minute).
//
//   qs ipc call timer start 25     start 25 minutes
//   qs ipc call timer toggle       pause / resume
//   qs ipc call timer reset
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int  total: 0          // seconds it was set to
    property int  left: 0           // seconds remaining
    property bool running: false
    property real endsAt: 0         // ms since epoch, while running

    readonly property bool active: left > 0          // running or paused
    readonly property real progress: total > 0 ? left / total : 0

    readonly property string sound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"

    function start(seconds) {
        ringing = false;                // a new timer silences the old alarm
        total = seconds;
        left = seconds;
        resume();
    }
    function resume() {
        if (left <= 0) return;
        endsAt = Date.now() + left * 1000;
        running = true;
    }
    function pause() {
        tick();
        running = false;
    }
    function toggle() { running ? pause() : resume(); }
    function reset() {
        running = false;
        left = 0;
        total = 0;
    }
    function add(seconds) {
        if (!active) { start(seconds); return; }
        total += seconds;
        left += seconds;
        if (running) endsAt += seconds * 1000;
    }

    function tick() {
        if (!running) return;
        left = Math.max(0, Math.ceil((endsAt - Date.now()) / 1000));
        if (left === 0) finish();
    }

    // ---- alarm: rings every 4 s until the notification is clicked, max 1 min ----
    property bool ringing: false

    function finish() {
        running = false;
        alert.command = ["notify-send", "--wait", "-u", "critical", "-a", "Timer",
                         "Time's up", Time.clock(total * 1000) + " timer finished"];
        alert.running = true;
        ringing = true;
        total = 0;
    }

    // --wait: notify-send only exits once the notification is closed (clicked)
    Process {
        id: alert
        onExited: root.ringing = false
    }

    // one ring = this process; tracked (not detached) so a click can cut it off
    Process {
        id: ring
        command: ["pw-play", root.sound]
    }
    onRingingChanged: if (!ringing) ring.running = false   // stop the sound instantly

    Timer {
        interval: 4000
        repeat: true
        triggeredOnStart: true
        running: root.ringing
        onTriggered: ring.running = true
    }

    Timer {                         // the 1-minute cap; the notification stays
        interval: 60000
        running: root.ringing
        onTriggered: root.ringing = false
    }

    Timer {
        interval: 250
        repeat: true
        running: root.running
        onTriggered: root.tick()
    }

    IpcHandler {
        target: "timer"
        function start(minutes: real): void { root.start(Math.round(minutes * 60)); }
        function toggle(): void { root.toggle(); }
        function reset(): void { root.reset(); }
    }
}
