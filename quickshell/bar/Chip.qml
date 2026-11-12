// Small rounded text button (timer presets, tabs). `on` = selected look.
import QtQuick
import qs

Rectangle {
    id: root

    property string text
    property bool on: false
    signal clicked()

    implicitWidth: label.implicitWidth + 18
    implicitHeight: label.implicitHeight + 8
    radius: height / 2
    color: on || mouse.containsMouse ? Theme.selected : Theme.bgAlt

    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Theme.smallSize
        color: root.on ? Theme.accent : Theme.fg
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
