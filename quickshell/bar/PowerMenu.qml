// ---------------------------------------------------------
// POWER MENU  — full-screen power screen, one per monitor; only the one on
// the monitor it was opened from shows (services/Power.qml).
// Open: CTRL + ALT + Delete  (qs ipc call power toggle)
//
//   the desktop, dimmed + blurred (blur rule in hypr/dots/windows.lua)
// It fades in / out with Hyprland's layer fade (fadeLayersIn / fadeLayersOut
// in hypr/dots/animations.lua), so dim, blur and tiles move as one; no fade
// of its own here.
//   [Lock] [Log out] [Suspend] [Reboot] [Shut down]   selected = accent
//
// Keys: ←/→ or Tab move · Enter / Space choose · Esc closes.
// Mouse: hover selects, click chooses, click outside the tiles closes.
// Lock and Suspend run at once; log out / reboot / shut down first grow
// their tile to fill the screen ("Shutting down…") — Esc while it grows
// turns it back.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

PanelWindow {
    id: win

    required property var modelData        // the screen, handed in by Variants
    screen: modelData

    readonly property bool wanted: Power.open && modelData.name === Power.monitor   // screen name = monitor name (eDP-1, …)

    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: wanted

    WlrLayershell.namespace: "quickshell-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: wanted ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    property int current: 0                 // selected tile
    property int chosen: -1                 // tile growing to fill the screen (-1: none)

    onWantedChanged: {
        if (wanted) {
            current = 0;
            chosen = -1;
            grow.progress = 0;
            keys.forceActiveFocus();
        }
    }

    function choose(i) {
        const a = Power.actions[i];
        if (a.quick) { Power.run(a); return; }
        chosen = i;
        current = i;
        grow.start = tiles.itemAt(i).mapToItem(root, 0, 0);
        growIn.restart();
    }

    Item {
        id: root
        anchors.fill: parent

        // dim layer; a click on it (outside the tiles) closes
        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            MouseArea { anchors.fill: parent; onClicked: if (win.chosen < 0) Power.close() }
        }

        Column {
            anchors.centerIn: parent
            spacing: 44

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 20

                Repeater {
                    id: tiles
                    model: Power.actions

                    Column {
                        id: tile
                        required property var modelData
                        required property int index
                        readonly property bool selected: win.current === index
                        spacing: 12

                        Rectangle {
                            width: 104
                            height: 104
                            radius: 24
                            color: tile.selected ? Theme.accent : Theme.bg
                            border.width: Theme.border
                            border.color: tile.selected ? Theme.accent : Theme.line
                            scale: tile.selected ? 1.05 : 1
                            Behavior on color { ColorAnimation { duration: Theme.fade } }
                            Behavior on scale { NumberAnimation { duration: Theme.fade; easing.type: Easing.OutCubic } }

                            SvgIcon {
                                anchors.centerIn: parent
                                name: tile.modelData.icon
                                size: 36
                                color: tile.selected ? Theme.bg : Theme.fg
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: if (win.chosen < 0) win.current = tile.index
                                onClicked: if (win.chosen < 0) win.choose(tile.index)
                            }
                        }
                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.text
                            color: tile.selected ? Theme.fg : Theme.fgDim
                            font.pixelSize: Theme.smallSize
                        }
                    }
                }
            }
        }

        // the chosen tile, growing from its spot to the whole screen
        Rectangle {
            id: grow
            property real progress: 0           // 0 the tile .. 1 the screen
            property point start: Qt.point(0, 0)
            visible: progress > 0
            x: start.x * (1 - progress)
            y: start.y * (1 - progress)
            width: 104 + (root.width - 104) * progress
            height: 104 + (root.height - 104) * progress
            radius: 24 * (1 - progress)
            color: Theme.accent

            Column {
                anchors.centerIn: parent
                spacing: 18
                opacity: grow.progress
                SvgIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: win.chosen >= 0 ? Power.actions[win.chosen].icon : ""
                    size: 48
                    color: Theme.bg
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.chosen >= 0 ? Power.actions[win.chosen].doing : ""
                    color: Theme.bg
                    font.pixelSize: 22
                }
            }
        }

        NumberAnimation {
            id: growIn
            target: grow; property: "progress"; to: 1
            duration: 700; easing.type: Easing.InOutCubic
            onFinished: if (win.chosen >= 0) Power.run(Power.actions[win.chosen])
        }
        NumberAnimation {
            id: growBack
            target: grow; property: "progress"; to: 0
            duration: 300; easing.type: Easing.OutCubic
            onFinished: win.chosen = -1
        }
    }

    // keyboard
    Item {
        id: keys
        focus: true
        Keys.onPressed: e => {
            const n = Power.actions.length;
            if (e.key === Qt.Key_Escape) {
                if (win.chosen >= 0) { growIn.stop(); growBack.restart(); }
                else Power.close();
            } else if (win.chosen >= 0) {
                // while a tile grows, only Esc does anything
            } else if (e.key === Qt.Key_Left || e.key === Qt.Key_Backtab) {
                win.current = (win.current + n - 1) % n;
            } else if (e.key === Qt.Key_Right || e.key === Qt.Key_Tab) {
                win.current = (win.current + 1) % n;
            } else if (e.key === Qt.Key_Return || e.key === Qt.Key_Enter || e.key === Qt.Key_Space) {
                win.choose(win.current);
            } else return;
            e.accepted = true;
        }
    }
}
