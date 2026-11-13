// ---------------------------------------------------------
// POWER PILL  — left edge of the bar: one power icon. Click: the power menu
// (lock, log out, suspend, reboot, shut down) slides out underneath as a
// drawer, flush left. The bar's `open` value is "power".
// ---------------------------------------------------------

import QtQuick
import qs

Pill {
    id: root

    property string open: ""                // the bar's open panel
    signal request(string panel)            // ask the bar to open (or toggle) a panel

    readonly property bool expanded: open === "power"

    view: idleView
    padX: 8                                 // 17 px icon + 2 × 8 -> a 34 × 34 square, as tall as the other pills
    drawer: expanded ? powerView : null
    drawerAlign: "left"

    View {
        id: idleView
        shown: true
        implicitWidth: icon.implicitWidth
        implicitHeight: icon.implicitHeight

        SvgIcon {
            id: icon
            name: "power"
            color: root.expanded ? Theme.accent : Theme.fg
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -Theme.pad             // the whole pill is the button
            cursorShape: Qt.PointingHandCursor
            onClicked: root.request("power")
        }
    }

    drawers: [
        View {
            id: powerView
            shown: root.expanded
            implicitWidth: power.implicitWidth + 12
            implicitHeight: power.implicitHeight + 12
            PowerPanel { id: power; anchors.centerIn: parent; onDone: root.request("power") }
        }
    ]
}
