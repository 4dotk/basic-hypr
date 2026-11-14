// ---------------------------------------------------------
// NOTIF PILL  — right edge of the bar, beside the quick pill: a bell.
//   click        the notification center slides out underneath (drawer,
//                flush right); the bar's `open` value is "notifs"
//   popups       one at a time, a separate opaque card a small gap below the
//                bell (no curved join — that's only for the center; focused
//                monitor only); Theme.popup background (per theme), 1 px border:
//                Hyprland's light window-border blue on an empty workspace,
//                Hyprland's inactive window border over windows; amber border for critical ones
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
    property bool desktop: false            // no windows on this monitor's workspace
    property string open: ""                // the bar's open panel
    signal request(string panel)            // ask the bar to open (or toggle) a panel

    readonly property bool expanded: open === "notifs"
    readonly property bool popup: !expanded && focused && Notifs.current !== null

    view: idleView
    padX: 8                                 // a 34 × 34 square
    drawer: expanded ? centerView : popup ? popupView : null
    drawerAlign: "right"

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
            // the theme's popup colour, solid, with a 1 px border: on an empty
            // workspace the light blue of Hyprland's focused-window border (it
            // outlines the card on the wallpaper); over windows Hyprland's inactive
            // window border, so only the focused window says "active"; amber when critical
            cardColor: Theme.popup
            cardBorder: 1
            // 14 px below the bar (= Hyprland gaps_out): the card's top-right corner
            // lines up with a window's top-right corner
            cardGap: Theme.gutter
            cardStroke: Notifs.current?.urgency === NotificationUrgency.Critical ? Theme.urgent
                      : root.desktop ? Theme.windowBorder : Theme.windowBorderInactive
            notification: Notifs.current
            shown: root.popup
        }
    ]
}
