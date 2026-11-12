// ---------------------------------------------------------
// NOTIFICATION  — one popup at a time.
// Left click: open it (default action) · Right click: dismiss.
// Extra action buttons show under the text when the app sends any.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import qs
import qs.services

View {
    id: root

    property Notification notification
    // keep showing the last one while fading out, instead of going blank
    property Notification last
    onNotificationChanged: if (notification) last = notification
    readonly property Notification n: notification ?? last

    readonly property string iconSource: {
        if (!n) return "";
        if (n.image) return n.image;
        if (n.appIcon) return n.appIcon.includes("/") ? n.appIcon : Quickshell.iconPath(n.appIcon, true);
        return "";
    }

    implicitWidth: 380
    implicitHeight: col.implicitHeight

    // whole popup is clickable; action buttons sit above this and win
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: e => e.button === Qt.RightButton ? Notifs.dismiss() : Notifs.activate()
    }

    Column {
        id: col
        width: parent.width
        spacing: 10

        Row {
            width: parent.width
            spacing: 12

            ClippingRectangle {
                id: iconBox
                width: 40
                height: 40
                radius: 10
                color: Theme.bgAlt

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

                Label {
                    width: parent.width
                    text: root.n?.appName ?? ""
                    visible: text !== ""
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
                    color: actMouse.containsMouse ? Theme.selected : Theme.bgAlt

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
                        onClicked: Notifs.invoke(parent.modelData)
                    }
                }
            }
        }
    }
}
