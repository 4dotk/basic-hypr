// A clickable icon: a quickshell/icons name (`icon`) or a Nerd Font glyph (`glyph`).
// Highlights like a selected rofi row; `on` keeps it accent-coloured (e.g. while scanning).
import QtQuick
import qs

Rectangle {
    id: root

    property string glyph: ""
    property string icon: ""
    property bool on: false
    property color tint: Theme.fg               // colour when idle
    property int size: Theme.iconSize + 4
    signal clicked()

    implicitWidth: size + 12
    implicitHeight: size + 8
    radius: height / 2
    color: mouse.containsMouse ? Theme.selected : "transparent"

    Label {
        visible: root.icon === ""
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: root.size
        color: mouse.containsMouse || root.on ? Theme.accent : root.tint
    }
    SvgIcon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        name: root.icon
        size: root.size - 2
        color: mouse.containsMouse || root.on ? Theme.accent : root.tint
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
