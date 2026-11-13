// ---------------------------------------------------------
// SLIDER  — a level bar you can set (same look as the OSD bar).
// Click or drag to set, scroll for ±5 %. Always 0–1 (capped at 100 %).
// `value` is shown; `moved(v)` asks the owner to apply a new value.
// ---------------------------------------------------------

import QtQuick
import qs

Item {
    id: root

    property real value: 0
    property bool muted: false                // dims the fill
    signal moved(real v)

    function set(v) { root.moved(Math.max(0, Math.min(1, v))); }

    implicitWidth: 200
    implicitHeight: 18                        // taller than the track: easier to hit

    Rectangle {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 6
        radius: 3
        color: Theme.bgAlt

        Rectangle {
            height: parent.height
            radius: parent.radius
            width: parent.width * Math.max(0, Math.min(1, root.value))
            color: root.muted ? Theme.fgDim : Theme.accent
            Behavior on width {
                enabled: !mouse.pressed           // follow the drag without lag
                NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
            }
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onPressed: e => root.set(e.x / width)
        onPositionChanged: e => { if (pressed) root.set(e.x / width); }
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: e => { if (e.angleDelta.y !== 0) root.set(root.value + (e.angleDelta.y > 0 ? 0.05 : -0.05)); }
    }
}
