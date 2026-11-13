// ---------------------------------------------------------
// LIST ROW  — one line in a quick-pill dropdown (a network, a device, an action).
//   icon · text (+ a dim second line) ………… trailing text / icon · ● when active
// `icon` = a quickshell/icons name (SvgIcon); `glyph` = a font glyph (used if no icon).
// `active`: accent colour + dot (the connected / default one).
// `subColor`: second line colour (amber for errors).
// Click anywhere on it -> clicked(); highlights on hover like the sound rows.
// ---------------------------------------------------------

import QtQuick
import qs

Rectangle {
    id: root

    property string icon: ""
    property string glyph: ""
    property string text
    property string sub: ""
    property color subColor: Theme.fgDim
    property string trailing: ""                // e.g. "55%"
    property string trailingIcon: ""            // e.g. "lock"
    property bool active: false
    property bool clickable: true
    default property alias extra: below.data    // optional content under the text (password field)
    signal clicked()

    implicitWidth: 340
    implicitHeight: content.implicitHeight + 16
    radius: Math.min(height / 2, 16)
    color: mouse.containsMouse && root.clickable ? Theme.selected : "transparent"

    Column {
        id: content
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Item {
            width: parent.width
            height: Math.max(iconBox.height, texts.implicitHeight)

            Item {
                id: iconBox
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.iconSize + 4
                height: Theme.iconSize
                SvgIcon {
                    visible: root.icon !== ""
                    anchors.verticalCenter: parent.verticalCenter
                    name: root.icon
                    color: root.active ? Theme.accent : Theme.fgDim
                }
                Label {
                    visible: root.icon === ""
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.glyph
                    color: root.active ? Theme.accent : Theme.fgDim
                    font.pixelSize: Theme.iconSize
                }
            }
            Column {
                id: texts
                anchors.left: iconBox.right
                anchors.leftMargin: 8
                anchors.right: tail.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                Label {
                    width: parent.width
                    text: root.text
                    color: root.active ? Theme.accent : Theme.fg
                }
                Label {
                    width: parent.width
                    visible: root.sub !== ""
                    text: root.sub
                    color: root.subColor
                    font.pixelSize: Theme.smallSize
                }
            }
            Row {
                id: tail
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: root.trailing
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                }
                SvgIcon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.trailingIcon !== ""
                    name: root.trailingIcon
                    size: Theme.smallSize - 1
                    color: Theme.fgDim
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.active
                    text: Theme.glyph.dot
                    color: Theme.accent
                    font.pixelSize: Theme.smallSize
                }
            }
        }

        Item {
            id: below
            width: parent.width
            implicitHeight: childrenRect.height
            visible: children.length > 0 && childrenRect.height > 0
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        z: -1                                   // under the extra content, so a text field still gets clicks
        hoverEnabled: true
        enabled: root.clickable
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
