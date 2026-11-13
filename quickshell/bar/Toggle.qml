// ---------------------------------------------------------
// TOGGLE  — on/off switch (Wi-Fi, Bluetooth). `on` is shown;
// toggled(v) asks the owner to apply it.
// On: accent track · Off: dim track.
// ---------------------------------------------------------

import QtQuick
import qs

Rectangle {
    id: root

    property bool on: false
    signal toggled(bool v)

    implicitWidth: 36
    implicitHeight: 20
    radius: height / 2
    color: on ? Theme.accent : Theme.bgAlt
    Behavior on color { ColorAnimation { duration: Theme.fade } }

    Rectangle {
        width: parent.height - 6
        height: width
        radius: width / 2
        y: 3
        x: root.on ? parent.width - width - 3 : 3
        color: root.on ? Theme.bg : Theme.fgDim
        Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled(!root.on)
    }
}
