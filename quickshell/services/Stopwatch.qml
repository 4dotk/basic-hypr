// ---------------------------------------------------------
// STOPWATCH  — counts up, with laps. Wall-clock based like Countdown.
//
//   qs ipc call stopwatch toggle    start / pause
//   qs ipc call stopwatch lap
//   qs ipc call stopwatch reset
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool running: false
    property real elapsed: 0        // ms, updated while running
    property real banked: 0         // ms from earlier runs before the last pause
    property real startedAt: 0      // ms since epoch of the current run
    property var  laps: []          // ms totals, newest first

    readonly property bool active: running || elapsed > 0

    function toggle() {
        if (running) {
            tick();
            banked = elapsed;
            running = false;
        } else {
            startedAt = Date.now();
            running = true;
        }
    }
    function lap() {
        if (!running) return;
        tick();
        laps = [elapsed, ...laps].slice(0, 20);
    }
    function reset() {
        running = false;
        elapsed = 0;
        banked = 0;
        laps = [];
    }
    function tick() { elapsed = banked + Date.now() - startedAt; }

    Timer {
        interval: 100               // tenths are shown in the panel
        repeat: true
        running: root.running
        onTriggered: root.tick()
    }

    IpcHandler {
        target: "stopwatch"
        function toggle(): void { root.toggle(); }
        function lap(): void { root.lap(); }
        function reset(): void { root.reset(); }
    }
}
