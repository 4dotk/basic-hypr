// ---------------------------------------------------------
// SVG ICON  — one of quickshell/icons/<name>.svg, tinted to `color`.
// The files are white; MultiEffect recolours them, so they follow the theme.
//   SvgIcon { name: "wifi-3"; color: Theme.fg }
// ---------------------------------------------------------

import QtQuick
import QtQuick.Effects
import qs

Item {
    id: root

    property string name
    property color color: Theme.fg
    property int size: Theme.iconSize

    implicitWidth: size
    implicitHeight: size

    Image {
        id: img
        anchors.fill: parent
        source: root.name ? Qt.resolvedUrl("../icons/" + root.name + ".svg") : ""
        sourceSize: Qt.size(root.size * 2, root.size * 2)   // crisp on scaled screens
        smooth: true
        visible: false
    }
    MultiEffect {
        anchors.fill: img
        source: img
        colorization: 1.0
        colorizationColor: root.color
        Behavior on colorizationColor { ColorAnimation { duration: Theme.fade } }
    }
}
