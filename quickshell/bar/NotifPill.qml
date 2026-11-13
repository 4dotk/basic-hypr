// ---------------------------------------------------------
// NOTIF PILL  — right edge of the bar, beside the quick pill: a bell.
//   click        the notification center slides out underneath (drawer,
//                flush right); the bar's `open` value is "notifs"
//   popups       one at a time, a separate opaque card a small gap below the
//                bell (no curved join — that's only for the center; focused
//                monitor only); amber border for critical ones
//   dot          something arrived since the center was last opened
//   bell-off     do not disturb is on
// See services/Notifs.qml, bar/NotifCenter.qml, bar/NotifView.qml.
// ---------------------------------------------------------

import QtQuick
import Quickshell.Services.Notifications
import qs
import qs.services

Pill {
    id: root

    required property bool focused          // is this bar's monitor focused
    property string open: ""                // the bar's open panel
    signal request(string panel)            // ask the bar to open (or toggle) a panel

    readonly property bool expanded: open === "notifs"
    readonly property bool popup: !expanded && focused && Notifs.current !== null

    view: idleView
    padX: 8                                 // a 34 × 34 square
    drawer: expanded ? centerView : popup ? popupView : null
    drawerAlign: "right"
    borderColor: popup && Notifs.current?.urgency === NotificationUrgency.Critical ? Theme.urgent : Theme.line

    Binding { target: Notifs; property: "centerOpen"; value: true; when: root.expanded }

    View {
        id: idleView
        shown: true
        implicitWidth: bell.width
        implicitHeight: bell.implicitHeight

        Label {
            id: bell
            width: Theme.iconSize
            horizontalAlignment: Text.AlignHCenter
            text: Notifs.dnd ? Theme.glyph.bellOff : Theme.glyph.bell
            color: root.expanded ? Theme.accent : Notifs.dnd ? Theme.fgDim : Theme.fg
            font.pixelSize: Theme.iconSize
            Behavior on color { ColorAnimation { duration: Theme.fade } }
        }
        // unread dot on the bell's top-right corner
        Rectangle {
            visible: Notifs.unread > 0 && !root.expanded
            width: 7
            height: 7
            radius: 3.5
            color: Theme.accent
            border.width: 1.5
            border.color: Theme.bg
            x: bell.width - width + 1
            y: 0
        }
        MouseArea {
            anchors.fill: parent
            anchors.margins: -8                     // the whole pill is the button
            cursorShape: Qt.PointingHandCursor
            onClicked: root.request("notifs")
        }
    }

    drawers: [
        View {
            id: centerView
            shown: root.expanded
            implicitWidth: center.implicitWidth
            implicitHeight: center.implicitHeight
            NotifCenter { id: center; anchors.centerIn: parent }
        },
        NotifView {
            id: popupView
            detached: true
            opaque: true                        // a popup sits over windows: no see-through
            notification: Notifs.current
            shown: root.popup
        }
    ]
}
