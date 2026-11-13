// ---------------------------------------------------------
// NETWORK  — dropdown of the quick pill's network icon.
//   Wired    the ethernet link (only shown if there is an ethernet port)
//   Wi-Fi    on/off switch, then networks: connected first, then by signal
// Click a network: connected -> disconnect · saved/open -> connect ·
// new WPA/WPA3 personal -> password field (Enter connects, Esc cancels).
// Enterprise networks (e.g. 802.1x) need nm-connection-editor the first time.
// ---------------------------------------------------------

import QtQuick
import Quickshell.Networking
import qs
import qs.services

Column {
    id: root

    width: 340
    spacing: 10

    property var asking: null                   // network showing the password field

    // ---- wired ----
    Heading { text: "Wired"; width: root.width; visible: Net.wired !== null }
    ListRow {
        width: root.width
        visible: Net.wired !== null
        clickable: false
        icon: "wired"
        text: Net.wiredUp ? "Connected" : "Cable unplugged"
        active: Net.wiredUp
    }

    // ---- wifi ----
    Heading {
        text: "Wi-Fi"
        width: root.width
        topGap: Net.wired !== null
        visible: Net.wifi !== null
        Toggle { on: Net.wifiOn; onToggled: v => Net.setWifi(v) }
    }
    Label {
        x: 10
        visible: Net.wifi !== null && (!Net.wifiOn || Net.networks.length === 0)
        text: Net.wifiOn ? "Searching…" : "Wi-Fi is off"
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }
    Repeater {
        model: Net.wifiOn ? Net.networks.slice(0, 8) : []
        NetRow { required property var modelData; net: modelData; width: root.width }
    }

    component NetRow: ListRow {
        id: row
        property var net
        property string error: ""
        readonly property bool askingHere: root.asking === net
        readonly property bool busy: net.state === ConnectionState.Connecting

        icon: Theme.wifiIcon(net.signalStrength)
        text: net.name
        active: net.connected
        trailingIcon: Net.isOpen(net) ? "" : "lock"
        sub: error !== "" ? error
            : busy ? "Connecting…"
            : net.connected ? "Connected"
            : Net.unsupported(net) ? "Set up in nm-connection-editor"
            : net.known ? "Saved"
            : ""
        subColor: error !== "" ? Theme.urgent : Theme.fgDim

        onClicked: {
            error = "";
            if (net.connected) net.disconnect();
            else if (net.known || Net.isOpen(net)) net.connect();
            else if (Net.needsPassword(net)) root.asking = askingHere ? null : net;
        }

        Connections {
            target: row.net
            function onConnectionFailed(reason) {
                row.error = reason === ConnectionFailReason.NoSecrets ? "Wrong password" : "Couldn't connect";
                if (reason === ConnectionFailReason.NoSecrets && Net.needsPassword(row.net)) root.asking = row.net;
            }
            function onConnectedChanged() { if (row.net.connected) row.error = ""; }
        }

        // password field, only under the row being asked about
        Rectangle {
            visible: row.askingHere
            width: parent.width
            height: row.askingHere ? 30 : 0
            radius: height / 2
            color: Theme.bgAlt

            TextInput {
                id: psk
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.fg
                selectionColor: Theme.selected
                font.family: Theme.font
                font.pixelSize: Theme.smallSize
                clip: true

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: psk.text === ""
                    text: "Password, then Enter"
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                }

                onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                Keys.onReturnPressed: { if (text !== "") { row.net.connectWithPsk(text); root.asking = null; } }
                Keys.onEnterPressed:  { if (text !== "") { row.net.connectWithPsk(text); root.asking = null; } }
                Keys.onEscapePressed: root.asking = null
            }
        }
    }
}
