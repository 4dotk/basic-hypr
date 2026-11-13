// ---------------------------------------------------------
// NET  — NetworkManager state for the quick pill (Quickshell.Networking).
//   wired / wifi       the first ethernet and wifi device (null if none)
//   wifiOn             the Wi-Fi radio (writable through setWifi)
//   networks           wifi networks, connected first, then by signal
//   scanning           set true while the network dropdown is open
// (Named Net, not Network, so it doesn't hide the Quickshell.Networking type.)
// Enterprise (802.1x) networks can't be set up here; saved ones still connect.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking
import qs

Singleton {
    id: root

    readonly property var wired: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifi:  Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null

    readonly property bool wifiOn: Networking.wifiEnabled
    readonly property bool wiredUp: wired?.connected ?? false
    readonly property var  active: (wifi?.networks.values ?? []).find(n => n.connected) ?? null

    readonly property var networks: (wifi?.networks.values ?? [])
        .filter(n => n.name !== "")
        .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))

    // scan only while someone looks at the list
    property bool scanning: false
    Binding { target: root.wifi; property: "scannerEnabled"; value: root.scanning && root.wifiOn; when: root.wifi !== null }

    // the pill's icon: plug when wired, wifi strength when on wifi, else empty fan / off
    readonly property string icon: wiredUp ? "wired"
        : active ? Theme.wifiIcon(active.signalStrength)
        : wifiOn ? "wifi-none"
        : "wifi-off"
    readonly property bool online: wiredUp || active !== null

    function setWifi(on) { Networking.wifiEnabled = on; }

    // password networks the bar can ask for (WPA/WPA2 personal, WPA3 personal)
    function needsPassword(n) {
        return n.security === WifiSecurityType.WpaPsk
            || n.security === WifiSecurityType.Wpa2Psk
            || n.security === WifiSecurityType.Sae;
    }
    function isOpen(n) {
        return n.security === WifiSecurityType.Open || n.security === WifiSecurityType.Owe;
    }
    // enterprise / old types: needs nm-connection-editor the first time
    function unsupported(n) { return !n.known && !isOpen(n) && !needsPassword(n); }
}
