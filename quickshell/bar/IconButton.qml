// A Nerd Font glyph you can click. Highlights like a selected rofi row.
import QtQuick
import qs

Rectangle {
    id: root

    property string glyph
    property int size: Theme.iconSize + 4
    signal clicked()

    implicitWidth: size + 12
    implicitHeight: size + 8
    radius: height / 2
    color: mouse.containsMouse ? Theme.selected : "transparent"

    Label {
        anchors.centerIn: parent
        text: root.glyph
        font.pixelSize: root.size
        color: mouse.containsMouse ? Theme.accent : Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
