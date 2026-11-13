// ---------------------------------------------------------
// QUICK PILL  — right edge of the bar: a row of status icons.
//   network · bluetooth · sound · battery
// (power: CTRL + ALT + Delete opens the power screen, bar/PowerMenu.qml)
// Each icon opens its own dropdown (no shared panel, no tabs); the name is
// the bar's `open` value: "network", "bluetooth", "sound", "battery".
// Bluetooth / battery icons only show when the machine has them; the battery
// also shows its percentage (fixed width for two digits, right-aligned, like
// the stats; at 100 % it is one character wider).
// The mic only lives inside the sound mixer, never as an icon here.
// The icons always stay; a dropdown slides out underneath as a drawer
// (bar/Pill.qml), flush with the right edge, and its icon turns accent.
// Scroll on the icons: default output volume ±5 % (the clock pill shows the OSD).
// ---------------------------------------------------------

import QtQuick
import qs
import qs.services

Pill {
    id: root

    property string open: ""                // the bar's open panel
    signal request(string panel)            // ask the bar to open (or toggle) a panel

    // the dropdowns this pill owns; open === one of these means it's expanded
    readonly property var panels: ["network", "bluetooth", "sound", "battery"]
    readonly property bool expanded: panels.includes(open)
    readonly property int inset: 6           // extra room around a dropdown, on top of the pill's padding

    view: idleView
    drawer: !expanded ? null
          : open === "network" ? networkView
          : open === "bluetooth" ? bluetoothView
          : open === "sound" ? soundView
          : batteryView
    drawerAlign: "right"

    // scan for wifi only while its list is open; stop bluetooth discovery on close
    Binding { target: Net; property: "scanning"; value: true; when: root.open === "network" }
    onOpenChanged: if (open !== "bluetooth" && Bt.scanning) Bt.setScanning(false)

    // ---- resting: one icon per dropdown ----
    View {
        id: idleView
        shown: true
        implicitWidth: icons.implicitWidth
        implicitHeight: icons.implicitHeight

        Row {
            id: icons
            spacing: 16

            Icon { panel: "network";   SvgIcon { name: Net.icon; color: root.open === "network" ? Theme.accent : Net.online ? Theme.fg : Theme.fgDim } }
            Icon { panel: "bluetooth"; visible: Bt.present; SvgIcon { name: Bt.icon; color: root.open === "bluetooth" ? Theme.accent : Bt.on ? Theme.fg : Theme.fgDim } }
            Icon { panel: "sound";     SvgIcon { name: Theme.volumeIcon(Audio.volume, Audio.muted); color: root.open === "sound" ? Theme.accent : Audio.muted ? Theme.fgDim : Theme.fg } }
            Icon {
                panel: "battery"
                visible: Battery.present
                implicitWidth: percent.x + percent.width
                readonly property color tint: root.open === "battery" ? Theme.accent : Battery.low ? Theme.urgent : Theme.fg
                BatteryIcon {
                    id: bat
                    anchors.verticalCenter: parent.verticalCenter
                    level: Battery.level
                    charging: Battery.charging
                    color: parent.tint
                }
                // power mode badge on the battery's bottom-right corner (none while balanced),
                // on a pill-coloured disc so it stays readable over the glyph
                Rectangle {
                    visible: badge.visible
                    anchors.centerIn: badge
                    width: badge.size + 2
                    height: width
                    radius: width / 2
                    color: Theme.bg
                }
                SvgIcon {
                    id: badge
                    visible: Battery.modeIcon !== ""
                    name: Battery.modeIcon
                    size: 10
                    color: Theme.fg
                    x: bat.width - size / 2
                    y: bat.height - size + 2
                }
                // percentage, as wide as "99%" so the pill keeps its width
                Label {
                    id: percent
                    x: bat.width + (badge.visible ? badge.size / 2 : 0) + 6
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.ceil(Math.max(implicitWidth, widest.advanceWidth))
                    horizontalAlignment: Text.AlignRight
                    text: Math.round(Battery.level * 100) + "%"
                    color: parent.tint
                    font.pixelSize: Theme.smallSize
                    TextMetrics { id: widest; font: percent.font; text: "99%" }
                }
            }
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

    // ---- dropdowns: drawers under the icons ----
    drawers: [
        View {
            id: networkView
            shown: root.open === "network"
            implicitWidth: network.implicitWidth + root.inset * 2
            implicitHeight: network.implicitHeight + root.inset * 2
            NetworkPanel { id: network; anchors.centerIn: parent }
        },
        View {
            id: bluetoothView
            shown: root.open === "bluetooth"
            implicitWidth: bluetooth.implicitWidth + root.inset * 2
            implicitHeight: bluetooth.implicitHeight + root.inset * 2
            BluetoothPanel { id: bluetooth; anchors.centerIn: parent }
        },
        View {
            id: soundView
            shown: root.open === "sound"
            implicitWidth: sound.implicitWidth + root.inset * 2
            implicitHeight: sound.implicitHeight + root.inset * 2
            SoundPanel { id: sound; anchors.centerIn: parent }
        },
        View {
            id: batteryView
            shown: root.open === "battery"
            implicitWidth: battery.implicitWidth + root.inset * 2
            implicitHeight: battery.implicitHeight + root.inset * 2
            BatteryPanel { id: battery; anchors.centerIn: parent }
        }
    ]

    // scroll on the icons: volume ±5 % (the head only; a drawer has its own sliders)
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => {
            if (e.angleDelta.y === 0) return;
            Audio.setVolume(Audio.sink, Audio.volume + (e.angleDelta.y > 0 ? 0.05 : -0.05));
            Osd.show("volume");
        }
    }
}
