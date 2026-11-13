// ---------------------------------------------------------
// BATTERY  — laptop battery + power profile (Quickshell.Services.UPower).
//   present            false on desktops: the pill hides the battery icon
//   level              0–1 · charging / full · low (< 20 %, amber)
//   timeText           "2 h 05 m left" / "40 m to full" / ""
//   health             0–100, or -1 when unknown
//   profile            PowerProfile.PowerSaver / Balanced / Performance (setProfile)
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev?.isLaptopBattery ?? false

    readonly property real level: dev?.percentage ?? 0
    readonly property bool charging: dev?.state === UPowerDeviceState.Charging
                                     || dev?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: dev?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: present && !charging && level < 0.2

    readonly property string stateText: full ? "Full"
        : charging ? "Charging"
        : !UPower.onBattery ? "Plugged in"
        : "On battery"

    readonly property string timeText: {
        const s = charging ? (dev?.timeToFull ?? 0) : (dev?.timeToEmpty ?? 0);
        if (full || s <= 0) return "";
        const h = Math.floor(s / 3600), m = Math.round((s % 3600) / 60);
        const t = h > 0 ? h + " h " + String(m).padStart(2, "0") + " m" : m + " m";
        return charging ? t + " to full" : t + " left";
    }

    // the display device has no health; read it from the real battery
    readonly property var cell: UPower.devices.values.find(d => d.isLaptopBattery) ?? null
    readonly property real health: cell && cell.healthPercentage > 0 ? cell.healthPercentage : -1

    readonly property int profile: PowerProfiles.profile
    readonly property bool hasPerformance: PowerProfiles.hasPerformanceProfile
    function setProfile(p) { PowerProfiles.profile = p; }
}
