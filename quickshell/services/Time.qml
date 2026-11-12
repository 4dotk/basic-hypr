// Time formatting shared by the timer and stopwatch.
pragma Singleton

import QtQuick
import Quickshell

Singleton {
    function pad(n) { return (n < 10 ? "0" : "") + n; }

    // 65000 -> "01:05", 3725000 -> "1:02:05"; tenths=true adds ".3"
    function clock(ms, tenths) {
        const s = Math.floor(ms / 1000);
        const h = Math.floor(s / 3600), m = Math.floor(s % 3600 / 60), sec = s % 60;
        let out = h > 0 ? h + ":" + pad(m) + ":" + pad(sec) : pad(m) + ":" + pad(sec);
        if (tenths) out += "." + Math.floor(ms % 1000 / 100);
        return out;
    }
}
