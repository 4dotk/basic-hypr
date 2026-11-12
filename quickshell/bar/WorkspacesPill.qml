// ---------------------------------------------------------
// WORKSPACES  — numbers of the workspaces that exist on this monitor.
// Active one is highlighted. Click to switch, scroll to cycle.
// ---------------------------------------------------------

import QtQuick
import Quickshell.Hyprland
import qs

Pill {
    id: root

    property HyprlandMonitor monitor

    view: content
    padX: 5                 // same 5px gap around the active block as above/below it

    View {
        id: content
        shown: true
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            spacing: 4

            Repeater {
                model: Hyprland.workspaces

                Rectangle {
                    id: ws
                    required property HyprlandWorkspace modelData

                    // active one is a small pill: same proportions as the bar pills
                    visible: modelData.id > 0 && modelData.monitor === root.monitor
                    width: Math.max(modelData.active ? 34 : 24, num.implicitWidth + 12)
                    height: 24
                    radius: 10
                    color: modelData.active ? Theme.accent
                         : mouse.containsMouse ? Theme.bgAlt
                         : "transparent"
                    Behavior on color { ColorAnimation { duration: Theme.fade } }
                    Behavior on width { NumberAnimation { duration: Theme.morph; easing.type: Easing.OutCubic } }

                    Label {
                        id: num
                        anchors.centerIn: parent
                        text: ws.modelData.id
                        font.bold: ws.modelData.active
                        color: ws.modelData.active ? Theme.bg
                             : ws.modelData.urgent ? Theme.urgent
                             : Theme.fgDim
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: ws.modelData.activate()
                    }
                }
            }
        }
    }

    // same as SUPER + scroll in keybindings.lua
    WheelHandler {
        onWheel: e => Hyprland.dispatch(e.angleDelta.y > 0
            ? 'hl.dsp.focus({ workspace = "e-1" })'
            : 'hl.dsp.focus({ workspace = "e+1" })')
    }
}
