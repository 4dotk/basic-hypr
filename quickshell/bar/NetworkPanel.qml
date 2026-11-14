// ---------------------------------------------------------
// NETWORK  — dropdown of the quick pill's network icon.
//   Hotspot  on/off switch; the first time it asks for a password (masked).
//            While on: its name (no password shown; QR sharing is in the
//            backlog); the Wi-Fi list folds away (same card, see services/Net.qml)
//   Wired    the ethernet link (only shown if there is an ethernet port)
//   Wi-Fi    on/off switch, then networks: connected first, then by signal;
//            the list scrolls past ~5 rows
// Click a network: connected -> disconnect · saved/open -> connect ·
// new WPA/WPA3 personal -> password field (Enter connects, Esc cancels).
// Enterprise networks (e.g. 802.1x) need nm-connection-editor the first time.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import qs
import qs.services

Column {
    id: root

    width: 340
    spacing: 10

    property string asking: ""                  // SSID showing the password field
    Connections { target: Net; function onNeedPassword(ssid) { root.asking = ssid; } }
    property bool askingHotspot: false          // first hotspot start: password field

    // ---- hotspot ----
    Heading {
        text: "Hotspot"
        width: root.width
        visible: Net.wifi !== null
        Toggle {
            on: Net.hotspotOn || root.askingHotspot
            onToggled: v => {
                if (v && !Net.hotspotSaved) root.askingHotspot = true;      // first time: ask
                else { root.askingHotspot = false; Net.setHotspot(v); }
            }
        }
    }
    ListRow {
        width: root.width
        visible: Net.wifi !== null
        clickable: false
        icon: "hotspot"
        active: Net.hotspotOn
        text: Net.hotspotBusy ? (Net.hotspotOn ? "Stopping…" : "Starting…")
            : Net.hotspotOn ? Net.hotspotName
            : Net.hotspotSsid
        sub: Net.hotspotError !== "" ? Net.hotspotError
            : Net.hotspotOn ? "On"
            : root.askingHotspot ? "Set a password (8–63 characters)"
            : ""
        subColor: Net.hotspotError !== "" ? Theme.urgent : Theme.fgDim

        // first start: the password, masked
        Rectangle {
            visible: root.askingHotspot
            width: parent.width
            height: root.askingHotspot ? 30 : 0
            radius: height / 2
            color: Theme.bgAlt

            TextInput {
                id: hsPsk
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
                    visible: hsPsk.text === ""
                    text: "Password, then Enter"
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                }

                function submit() {
                    if (text.length < 8 || text.length > 63) { Net.hotspotError = "Use 8–63 characters"; return; }
                    Net.setHotspot(true, text);
                    root.askingHotspot = false;
                }
                onVisibleChanged: if (visible) { text = ""; forceActiveFocus(); }
                Keys.onReturnPressed: submit()
                Keys.onEnterPressed: submit()
                Keys.onEscapePressed: root.askingHotspot = false
                Keys.onShortcutOverride: e => e.accepted = e.key === Qt.Key_Escape   // Esc cancels this, not the panel
            }
        }
    }

    // ---- wired ----
    Heading { text: "Wired"; width: root.width; topGap: Net.wifi !== null; visible: Net.wired !== null }
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
        topGap: true
        visible: Net.wifi !== null
        Toggle { on: Net.wifiOn; onToggled: v => Net.setWifi(v) }
    }
    // the list (or "Searching…" / "Wi-Fi is off"); folds away while the
    // hotspot has the card, and folds back out when it stops. Only that
    // toggle animates here: networks arriving just resize the drawer, which
    // has its own animation (two at once made opening jumpy).
    Item {
        id: wifiBody
        property bool folded: false
        property bool folding: false            // true only while a hotspot toggle plays
        Component.onCompleted: folded = Net.hotspotOn
        Connections {
            target: Net
            function onHotspotOnChanged() {
                wifiBody.folding = true;        // before `folded` changes, so the Behavior is on
                wifiBody.folded = Net.hotspotOn;
                unfold.restart();
            }
        }
        Timer { id: unfold; interval: Theme.morph + 50; onTriggered: wifiBody.folding = false }

        width: root.width
        height: folded ? 0 : wifiCol.height
        visible: height > 0.5
        opacity: folded ? 0 : 1
        clip: true
        Behavior on height  { enabled: wifiBody.folding; NumberAnimation { duration: Theme.morph; easing.type: Easing.OutCubic } }
        Behavior on opacity { enabled: wifiBody.folding; NumberAnimation { duration: Theme.fade } }
        Column {
            id: wifiCol
            width: parent.width
            spacing: root.spacing
            Label {
                x: 10
                visible: Net.wifi !== null && (!Net.wifiOn || Net.networks.length === 0)
                text: Net.wifiOn ? "Searching…" : "Wi-Fi is off"
                color: Theme.fgDim
                font.pixelSize: Theme.smallSize
            }
            // a Flickable, not a ListView: the network list is rebuilt whenever a
            // signal changes, and a ListView would jump back to the top each time
            Flickable {
                id: list
                width: wifiBody.width
                height: Math.min(rows.height, 240)
                visible: rows.height > 0
                contentHeight: rows.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: rows
                    width: list.width
                    spacing: 10
                    // ScriptModel: rows whose entry didn't change are kept (no
                    // rebuild on every refresh); at most 8 networks, like Caelestia
                    Repeater {
                        model: ScriptModel { values: Net.wifiOn ? Net.networks.slice(0, 8) : [] }
                        NetRow { required property var modelData; net: modelData; width: rows.width }
                    }
                }
            }
        }
    }

    component NetRow: ListRow {
        id: row
        property var net
        readonly property bool askingHere: root.asking === net.ssid
        readonly property bool busy: Net.connecting === net.ssid
        readonly property string error: Net.errorFor === net.ssid ? Net.connectError : ""

        icon: net.level
        text: net.ssid
        active: net.active
        trailingIcon: Net.isOpen(net) ? "" : "lock"
        sub: error !== "" ? error
            : busy ? "Connecting…"
            : net.active ? "Connected"
            : Net.unsupported(net) ? "Set up in nm-connection-editor"
            : net.known ? "Saved"
            : ""
        subColor: error !== "" ? Theme.urgent : Theme.fgDim

        onClicked: {
            if (net.active) Net.disconnect();
            else if (net.known || Net.isOpen(net)) Net.connect(net);
            else if (Net.needsPassword(net)) root.asking = askingHere ? "" : net.ssid;
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
                Keys.onReturnPressed: { if (text !== "") { Net.connect(row.net, text); root.asking = ""; } }
                Keys.onEnterPressed:  { if (text !== "") { Net.connect(row.net, text); root.asking = ""; } }
                Keys.onEscapePressed: root.asking = ""
                Keys.onShortcutOverride: e => e.accepted = e.key === Qt.Key_Escape   // Esc cancels this, not the panel
            }
        }
    }
}
