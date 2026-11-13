// ---------------------------------------------------------
// NOTIFICATION CENTER  — the bell pill's drawer.
//   Notifications  3 ………… [do not disturb] [Clear]
//   cards, newest first (bar/NotifCard.qml); scrolls past ~400 px
//   "No notifications" when empty
// Do not disturb: no popups (critical ones still pop up); everything
// still lands here. See services/Notifs.qml.
// ---------------------------------------------------------

import QtQuick
import qs
import qs.services

Column {
    id: root

    width: 380
    spacing: 12

    // ---- header ----
    Item {
        width: root.width
        height: Math.max(title.implicitHeight, dnd.height, clear.height)

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8
            Label {
                id: title
                text: "Notifications"
                font.bold: true
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                visible: Notifs.list.length > 0
                text: Notifs.list.length
                color: Theme.fgDim
                font.pixelSize: Theme.smallSize
            }
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // do not disturb: bell-off icon, accent while on
            Rectangle {
                id: dnd
                width: 30
                height: 26
                radius: height / 2
                color: Notifs.dnd ? Theme.accent : dndMouse.containsMouse ? Theme.selected : "transparent"
                Behavior on color { ColorAnimation { duration: Theme.fade } }
                Label {
                    anchors.centerIn: parent
                    text: Theme.glyph.bellOff
                    color: Notifs.dnd ? Theme.bg : Theme.fgDim
                    font.pixelSize: Theme.iconSize - 2
                }
                MouseArea {
                    id: dndMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.dnd = !Notifs.dnd
                }
            }
            // clear all
            Rectangle {
                id: clear
                visible: Notifs.list.length > 0
                width: clearLabel.implicitWidth + 20
                height: 26
                radius: height / 2
                color: clearMouse.containsMouse ? Theme.selected : "transparent"
                Label {
                    id: clearLabel
                    anchors.centerIn: parent
                    text: "Clear"
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                }
                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Notifs.clearAll()
                }
            }
        }
    }

    // ---- the list ----
    ListView {
        id: list
        width: root.width
        height: Math.min(contentHeight, 400)
        visible: count > 0
        clip: true
        spacing: 8
        boundsBehavior: Flickable.StopAtBounds
        model: Notifs.list

        delegate: NotifCard {
            required property var modelData
            width: list.width
            n: modelData
            boxed: true
        }

        // cards slide in / out instead of jumping
        add: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.fade } }
        displaced: Transition { NumberAnimation { property: "y"; duration: Theme.morph; easing.type: Easing.OutCubic } }
    }

    Label {
        visible: Notifs.list.length === 0
        width: root.width
        horizontalAlignment: Text.AlignHCenter
        topPadding: 18
        bottomPadding: 18
        text: "No notifications"
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }
}
