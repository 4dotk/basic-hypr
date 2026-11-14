// ---------------------------------------------------------
// BT  — BlueZ state for the quick pill (Quickshell.Bluetooth).
// (Named Bt, not Bluetooth, so it doesn't hide the Quickshell type.)
//   adapter / on       the default adapter and its power (setOn). Turning it
//                      on first clears an rfkill soft block (`rfkill unblock
//                      bluetooth`; the session user may do that): KDE's daemon
//                      re-applies a saved "off" that way, and BlueZ can't
//                      power an adapter while it is blocked.
//   paired             paired devices, connected first
//   found              unpaired devices seen while scanning (named ones only)
//   scanning           discovery on/off (the Scan chip)
// No PIN agent: devices that ask for a PIN can't be paired from the bar.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool present: adapter !== null
    readonly property bool on: adapter?.enabled ?? false
    readonly property bool scanning: adapter?.discovering ?? false

    readonly property var devices: adapter?.devices.values ?? []
    readonly property var paired: devices.filter(d => d.paired)
                                         .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name))
    readonly property var found: devices.filter(d => !d.paired && d.deviceName !== "")
    readonly property bool anyConnected: devices.some(d => d.connected)

    // off = the plain icon; the pill dims it
    readonly property string icon: on && anyConnected ? "bt-connected" : "bt"

    function setOn(v) {
        if (!adapter) return;
        if (!v) { adapter.enabled = false; return; }
        if (!unblock.running) unblock.running = true;   // powers on once the block is gone
    }
    Process {
        id: unblock
        command: ["rfkill", "unblock", "bluetooth"]
        onExited: if (root.adapter) root.adapter.enabled = true
    }
    function setScanning(v) { if (adapter && adapter.enabled) adapter.discovering = v; }

    function toggle(d) { if (d.connected) d.disconnect(); else d.connect(); }

    // trust first so it reconnects by itself later; connect once pairing is done
    function pair(d) { d.trusted = true; d.pair(); }

    // icon for a device from its BlueZ icon name: headphones for audio, else bluetooth
    function deviceIcon(d) {
        return (d?.icon ?? "").startsWith("audio") ? "headphones" : "bt";
    }

    // stop scanning when the adapter goes off
    onOnChanged: if (!on && adapter) adapter.discovering = false
}
