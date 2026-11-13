// ---------------------------------------------------------
// NOTIF CARD  — one notification: app icon, app name · age, summary,
// up to 3 lines of body, and the app's action buttons.
// Used by the popup (bar/NotifView.qml) and the center list (bar/NotifCenter.qml).
// Left click: run its default action and remove it · Right click: remove it.
// `boxed`: draw its own rounded background (in the center's list).
// ---------------------------------------------------------

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs
import qs.services

Item {
    id: root

    property Notification n
    property bool boxed: false
    readonly property int inset: boxed ? 12 : 0

    readonly property bool critical: n?.urgency === NotificationUrgency.Critical
    readonly property string iconSource: {
        if (!n) return "";
        if (n.image) return n.image;
        if (n.appIcon) return n.appIcon.includes("/") ? n.appIcon : Quickshell.iconPath(n.appIcon, true);
        return "";
    }

    implicitWidth: 380
    implicitHeight: col.implicitHeight + inset * 2

    // re-read the age every minute
    SystemClock { id: clock; precision: SystemClock.Minutes }

    Rectangle {
        anchors.fill: parent
        visible: root.boxed
        radius: 12
        color: mouse.containsMouse ? Theme.selected : Theme.bgAlt
        border.width: root.critical ? 1 : 0
        border.color: Theme.urgent
        Behavior on color { ColorAnimation { duration: Theme.fade } }
    }

    // whole card is clickable; buttons sit above this and win
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => e.button === Qt.RightButton ? Notifs.dismiss(root.n) : Notifs.activate(root.n)
    }

    Column {
        id: col
        x: root.inset
        y: root.inset
        width: parent.width - root.inset * 2
        spacing: 10

        Row {
            width: parent.width
            spacing: 12

            ClippingRectangle {
                id: iconBox
                width: 40
                height: 40
                radius: 10
                color: root.boxed ? Theme.bg : Theme.bgAlt

                Label {
                    anchors.centerIn: parent
                    visible: img.status !== Image.Ready
                    text: Theme.glyph.bell
                    color: Theme.accent
                    font.pixelSize: Theme.iconSize + 4
                }
                Image {
                    id: img
                    anchors.fill: parent
                    source: root.iconSource
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 80
                    sourceSize.height: 80
                }
            }

            Column {
                width: parent.width - iconBox.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                // app · age
                Label {
                    width: parent.width
                    text: {
                        clock.date;                     // re-evaluate each minute
                        const a = root.n?.appName ?? "";
                        const t = Notifs.age(root.n);
                        return a && t ? a + " · " + t : a || t;
                    }
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize - 1
                }
                Label {
                    width: parent.width
                    text: root.n?.summary ?? ""
                    font.bold: true
                }
                Label {
                    width: parent.width
                    text: root.n?.body ?? ""
                    visible: text !== ""
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                }
            }
        }

        // action buttons (the hidden "default" one is the left click)
        Row {
            anchors.right: parent.right
            spacing: 6
            visible: repeater.count > 0

            Repeater {
                id: repeater
                model: {
                    const out = [];
                    const acts = root.n?.actions ?? [];
                    for (let i = 0; i < acts.length; i++)
                        if (acts[i].identifier !== "default") out.push(acts[i]);
                    return out;
                }

                Rectangle {
                    required property NotificationAction modelData
                    implicitWidth: actLabel.implicitWidth + 20
                    implicitHeight: actLabel.implicitHeight + 10
                    radius: height / 2
                    color: actMouse.containsMouse ? Theme.selected : (root.boxed ? Theme.bg : Theme.bgAlt)

                    Label {
                        id: actLabel
                        anchors.centerIn: parent
                        text: parent.modelData.text
                        font.pixelSize: Theme.smallSize
                    }
                    MouseArea {
                        id: actMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Notifs.invoke(parent.modelData, root.n)
                    }
                }
            }
        }
    }
}
