// ---------------------------------------------------------
// QUICK PILL  — right edge of the bar: a row of status icons.
//   network · bluetooth · sound · battery · power
// Each icon opens its own dropdown (no shared panel, no tabs); the name is
// the bar's `open` value: "network", "bluetooth", "sound", "battery", "power".
// Bluetooth / battery icons only show when the machine has them.
// The mic only lives inside the sound mixer, never as an icon here.
// Scroll on the resting pill: default output volume ±5 % (the clock pill shows the OSD).
// ---------------------------------------------------------

import QtQuick
import qs
import qs.services

Pill {
    id: root

    property string open: ""                // the bar's open panel
    signal request(string panel)            // ask the bar to open (or toggle) a panel

    // the dropdowns this pill owns; open === one of these means it's expanded
    readonly property var panels: ["network", "bluetooth", "sound", "battery", "power"]
    readonly property bool expanded: panels.includes(open)
    readonly property int inset: 6           // extra room around a dropdown, on top of the pill's padding

    view: !expanded ? idleView
        : open === "network" ? networkView
        : open === "bluetooth" ? bluetoothView
        : open === "sound" ? soundView
        : open === "battery" ? batteryView
        : powerView
    flat: !expanded

    // scan for wifi only while its list is open; stop bluetooth discovery on close
    Binding { target: Net; property: "scanning"; value: true; when: root.open === "network" }
    onOpenChanged: if (open !== "bluetooth" && Bt.scanning) Bt.setScanning(false)

    // ---- resting: one icon per dropdown ----
    View {
        id: idleView
        shown: !root.expanded
        implicitWidth: icons.implicitWidth
        implicitHeight: icons.implicitHeight

        Row {
            id: icons
            spacing: 14

            Icon { panel: "network";   SvgIcon { name: Net.icon; color: Net.online ? Theme.fg : Theme.fgDim } }
            Icon { panel: "bluetooth"; visible: Bt.present; SvgIcon { name: Bt.icon; color: Bt.on ? Theme.fg : Theme.fgDim } }
            Icon { panel: "sound";     SvgIcon { name: Theme.volumeIcon(Audio.volume, Audio.muted); color: Audio.muted ? Theme.fgDim : Theme.fg } }
            Icon {
                panel: "battery"
                visible: Battery.present
                BatteryIcon { anchors.centerIn: parent; level: Battery.level; charging: Battery.charging; color: Battery.low ? Theme.urgent : Theme.fg }
            }
            Icon { panel: "power";     SvgIcon { name: "power" } }
        }
    }

    // one clickable icon on the resting pill (the icon goes inside it)
    component Icon: Item {
        property string panel
        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Theme.iconSize
        implicitHeight: Theme.iconSize

        MouseArea {
            anchors.fill: parent
            anchors.margins: -7                 // half the gap to the neighbours
            anchors.topMargin: -Theme.pad
            anchors.bottomMargin: -Theme.pad
            cursorShape: Qt.PointingHandCursor
            onClicked: root.request(parent.panel)
        }
    }

    // ---- dropdowns ----
    View {
        id: networkView
        shown: root.open === "network"
        implicitWidth: network.implicitWidth + root.inset * 2
        implicitHeight: network.implicitHeight + root.inset * 2
        NetworkPanel { id: network; anchors.centerIn: parent }
    }
    View {
        id: bluetoothView
        shown: root.open === "bluetooth"
        implicitWidth: bluetooth.implicitWidth + root.inset * 2
        implicitHeight: bluetooth.implicitHeight + root.inset * 2
        BluetoothPanel { id: bluetooth; anchors.centerIn: parent }
    }
    View {
        id: soundView
        shown: root.open === "sound"
        implicitWidth: sound.implicitWidth + root.inset * 2
        implicitHeight: sound.implicitHeight + root.inset * 2
        SoundPanel { id: sound; anchors.centerIn: parent }
    }
    View {
        id: batteryView
        shown: root.open === "battery"
        implicitWidth: battery.implicitWidth + root.inset * 2
        implicitHeight: battery.implicitHeight + root.inset * 2
        BatteryPanel { id: battery; anchors.centerIn: parent }
    }
    View {
        id: powerView
        shown: root.open === "power"
        implicitWidth: power.implicitWidth + root.inset * 2
        implicitHeight: power.implicitHeight + root.inset * 2
        PowerPanel { id: power; anchors.centerIn: parent; onDone: root.request("power") }
    }

    // scroll anywhere on the resting pill: volume ±5 %
    WheelHandler {
        enabled: !root.expanded
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            if (e.angleDelta.y === 0) return;
            Audio.setVolume(Audio.sink, Audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05));
            Osd.show("volume");
        }
    }
}
