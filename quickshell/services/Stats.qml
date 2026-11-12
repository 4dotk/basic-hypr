// ---------------------------------------------------------
// STATS  — CPU %, used RAM, CPU temperature for the stats pill.
// Every 2 s one small shell call reads all three, in sections marked #name:
//   /proc/stat (cpu line) · /proc/meminfo · sensors -j (lm_sensors)
// CPU usage is the busy share since the previous read.
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

    property var last: null         // previous cpu counters { idle, total }

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: read.running = true
    }

    Process {
        id: read
        command: ["sh", "-c", [
            "echo '#stat'; head -1 /proc/stat",
            "echo '#mem'; grep -E '^(MemTotal|MemAvailable):' /proc/meminfo",
            "echo '#sensors'; sensors -j 2>/dev/null"
        ].join("; ")]
        stdout: StdioCollector {
            onStreamFinished: root.parse(this.text)
        }
    }

    function parse(text) {
        // split into { stat: [...lines], mem: [...], sensors: [...] }
        const sec = {};
        let cur = null;
        for (const line of text.split("\n")) {
            if (line.startsWith("#")) { cur = line.slice(1); sec[cur] = []; }
            else if (cur && line.trim() !== "") sec[cur].push(line);
        }

        // cpu  user nice system idle iowait irq softirq steal ...
        if (sec.stat?.length) {
            const n = sec.stat[0].trim().split(/\s+/).slice(1).map(Number);
            const idle = n[3] + n[4];
            const total = n.reduce((a, b) => a + b, 0);
            if (last && total > last.total)
                cpu = 1 - (idle - last.idle) / (total - last.total);
            last = { idle: idle, total: total };
        }

        // MemTotal / MemAvailable in kB
        const m = {};
        for (const line of sec.mem || []) {
            const p = line.split(/[:\s]+/);
            m[p[0]] = parseInt(p[1]);
        }
        if (m.MemTotal > 0) {
            memUsed = m.MemTotal - m.MemAvailable;
            memory = memUsed / m.MemTotal;
        }

        // AMD: k10temp Tctl · Intel: coretemp 'Package id 0'
        let s = null;
        try { s = JSON.parse((sec.sensors || []).join("\n")); } catch (e) {}
        temp = NaN;
        if (s) {
            temp = first(s, "k10temp", "Tctl");
            if (isNaN(temp)) temp = first(s, "coretemp", "Package id 0");
        }
    }

    // first *_input reading of the chip whose name starts with `chip`, under `label`
    function first(s, chip, label) {
        for (const k in s) {
            if (!k.startsWith(chip) || typeof s[k][label] !== "object") continue;
            for (const f in s[k][label])
                if (f.endsWith("_input")) return s[k][label][f];
        }
        return NaN;
    }
}
