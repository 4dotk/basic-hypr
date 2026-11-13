// ---------------------------------------------------------
// BATTERY ICON  — the upright Material battery glyph (Theme.batteryGlyph):
// level in steps of 10 %, charging variants while charging.
//   BatteryIcon { level: 0.53; charging: false; color: Theme.fg }
// ---------------------------------------------------------

import QtQuick
import qs

Item {
    id: root

    property real level: 0
    property bool charging: false
    property color color: Theme.fg
    property int size: Theme.iconSize

    implicitWidth: glyph.implicitWidth
    implicitHeight: size

    Label {
        id: glyph
        anchors.centerIn: parent
        text: Theme.batteryGlyph(root.level, root.charging)
        color: root.color
        font.pixelSize: root.size
        Behavior on color { ColorAnimation { duration: Theme.fade } }
    }
}
