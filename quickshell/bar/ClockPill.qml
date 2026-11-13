// ---------------------------------------------------------
// CLOCK PILL  — centre of the bar.
// The pill itself shows (highest wins):
//   osd       volume / brightness bar          (focused monitor only),
//             1.8 × the date + time's width, 1.2 × the pill's height
//   idle      date + time
// Below it, one at a time:
//   calendar  card, opened by clicking the date          (separate, a gap below)
//   clocks    card, timer / stopwatch, opened by the time (separate, a gap below)
//   notif     notification popup, a joined drawer        (moves top-right in phase 4)
// The date + time never go away while a card is open.
// ---------------------------------------------------------

import QtQuick
import Quickshell.Services.Notifications
import qs
import qs.services

Pill {
    id: root

    required property bool focused          // is this bar's monitor focused
    property string open: ""                // the bar's open panel ("calendar", "clocks", …)
    signal request(string panel)            // ask the bar to open a panel

    // the pill: "osd" or "idle"
    readonly property string mode: focused && Osd.shown ? "osd" : "idle"
    // below it: "calendar", "clocks", "notif" or ""
    readonly property string under: open === "calendar" || open === "clocks" ? open
                                  : focused && Notifs.current ? "notif"
                                  : ""

    view: mode === "osd" ? osdView : idleView
    drawer: under === "calendar" ? calendarView
          : under === "clocks" ? clocksView
          : under === "notif" ? notifView
          : null
    borderColor: under === "notif" && Notifs.current?.urgency === NotificationUrgency.Critical
                 ? Theme.urgent : Theme.line

    ClockView {
        id: idleView
        shown: root.mode === "idle"
        onTimeClicked: root.request("clocks")
        onDateClicked: root.request("calendar")
    }

    OsdView {
        id: osdView
        shown: root.mode === "osd"
        fitWidth: Math.round(idleView.implicitWidth * 1.8)
        fitHeight: Math.round(Theme.idleHeight * 1.2)
    }

    drawers: [
        View {
            id: calendarView
            detached: true
            shown: root.under === "calendar"
            implicitWidth: calendar.implicitWidth
            implicitHeight: calendar.implicitHeight
            onShownChanged: if (shown) calendar.goToday()
            Calendar { id: calendar }
        },
        View {
            id: clocksView
            detached: true
            shown: root.under === "clocks"
            implicitWidth: clocks.width
            implicitHeight: clocks.implicitHeight
            onShownChanged: if (shown) { clocks.pickTab(); clocks.focusKeys(); }
            Clocks { id: clocks }
        },
        NotifView {
            id: notifView
            notification: Notifs.current
            shown: root.under === "notif"
        }
    ]
}
