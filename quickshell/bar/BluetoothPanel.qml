// ---------------------------------------------------------
// BLUETOOTH  — dropdown of the quick pill's bluetooth icon.
//   on/off switch
//   Devices   paired ones, connected first (battery % when the device reports it);
//             click to connect / disconnect
//   Nearby    scan button; new devices found while scanning, click to pair + connect
// No PIN agent: devices that ask for a PIN can't be paired from here.
// ---------------------------------------------------------

import QtQuick
import Quickshell.Bluetooth
import qs
import qs.services

Column {
    id: root

    width: 340
    spacing: 10

    Heading {
        text: "Bluetooth"
        width: root.width
        Toggle { on: Bt.on; onToggled: v => Bt.setOn(v) }
    }
    Label {
        x: 10
        visible: !Bt.on
        text: "Bluetooth is off"
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }

    // ---- paired ----
    Heading { text: "Devices"; width: root.width; topGap: true; visible: Bt.on }
    Label {
        x: 10
        visible: Bt.on && Bt.paired.length === 0
        text: "No paired devices"
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }
    Repeater {
        model: Bt.on ? Bt.paired : []
        ListRow {
            required property var modelData
            width: root.width
            icon: Bt.deviceIcon(modelData)
            text: modelData.name
            active: modelData.connected
            trailing: modelData.connected && modelData.batteryAvailable
                      ? Math.round(modelData.battery * 100) + "%" : ""
            sub: modelData.state === BluetoothDeviceState.Connecting ? "Connecting…"
                : modelData.state === BluetoothDeviceState.Disconnecting ? "Disconnecting…"
                : modelData.connected ? "Connected"
                : ""
            onClicked: Bt.toggle(modelData)
        }
    }

    // ---- nearby ----
    Heading {
        text: "Nearby"
        width: root.width
        topGap: true
        visible: Bt.on
        // bluetooth-searching icon: accent while scanning, click again to stop
        IconButton { icon: "bt-scan"; size: Theme.iconSize; on: Bt.scanning; tint: Theme.fgDim; onClicked: Bt.setScanning(!Bt.scanning) }
    }
    Label {
        x: 10
        visible: Bt.on && Bt.found.length === 0
        text: Bt.scanning ? "Looking for devices…" : "Scan to find new devices"
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }
    Repeater {
        model: Bt.on ? Bt.found.slice(0, 8) : []
        ListRow {
            id: found
            required property var modelData
            width: root.width
            icon: Bt.deviceIcon(modelData)
            text: modelData.name
            sub: modelData.pairing ? "Pairing…" : ""
            onClicked: if (!modelData.pairing) Bt.pair(modelData)

            // connect as soon as pairing finishes
            Connections {
                target: found.modelData
                function onPairedChanged() { if (found.modelData.paired) found.modelData.connect(); }
            }
        }
    }
}
