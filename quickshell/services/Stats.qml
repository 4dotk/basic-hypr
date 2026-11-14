// ---------------------------------------------------------
// STATS  — CPU %, used RAM, CPU temperature for the stats pill.
// Every 2 s it re-reads three small files through FileView, no processes
// (the way end-4's ResourceUsage does it):
//   /proc/stat (the cpu line) · /proc/meminfo · the CPU sensor's temp input
// CPU usage is the busy share since the previous read.
// The sensor is found once at start (hwmon numbers can change between
// boots): AMD k10temp "Tctl", else Intel coretemp "Package id 0".
// No sensor: temp stays NaN and the pill hides it.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property real cpu: 0            // 0..1
    property real memory: 0         // 0..1 (used / total)
    property real memUsed: 0        // kB
    property real temp: NaN         // CPU °C, NaN if no sensor found

    property var last: null         // previous cpu counters: idle, total
    property string tempPath: ""    // e.g. /sys/class/hwmon/hwmon6/temp1_input

    FileView { id: stat;    path: "/proc/stat";    blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: sensor;  path: root.tempPath;   blockLoading: true }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.read()
    }

    function read() {
        // cpu  user nice system idle iowait irq softirq steal ...
        stat.reload();
        const line = stat.text().split("\n")[0] ?? "";
        if (line.startsWith("cpu ")) {
            const n = line.trim().split(/\s+/).slice(1).map(Number);
            const idle = n[3] + n[4];
            const total = n.reduce((a, b) => a + b, 0);
            if (last && total > last.total)
                cpu = 1 - (idle - last.idle) / (total - last.total);
            last = { idle: idle, total: total };
        }

        // MemTotal / MemAvailable in kB
        meminfo.reload();
        const total = Number(meminfo.text().match(/MemTotal:\s*(\d+)/)?.[1] ?? 0);
        const avail = Number(meminfo.text().match(/MemAvailable:\s*(\d+)/)?.[1] ?? 0);
        if (total > 0) {
            memUsed = total - avail;
            memory = memUsed / total;
        }

        // millidegrees
        if (tempPath !== "") {
            sensor.reload();
            const t = parseInt(sensor.text());
            temp = isNaN(t) ? NaN : t / 1000;
        }
    }

    // once: the hwmon temp input whose chip + label match the CPU package
    Process {
        running: true
        command: ["sh", "-c",
            "for h in /sys/class/hwmon/hwmon*; do n=$(cat \"$h/name\" 2>/dev/null); "
          + "for l in \"$h\"/temp*_label; do [ -f \"$l\" ] || continue; "
          + "case \"$n:$(cat \"$l\")\" in k10temp:Tctl|\"coretemp:Package id 0\") echo \"${l%_label}_input\"; exit 0;; esac; "
          + "done; done"]
        stdout: StdioCollector { onStreamFinished: root.tempPath = this.text.trim() }
    }
}
