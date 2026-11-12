// ---------------------------------------------------------
// CLOCK PILL  — centre of the bar. Morphs between:
//   osd       volume / brightness bar          (focused monitor only)
//   calendar  opened by clicking the date
//   clocks    timer / stopwatch, opened by clicking the time
//   notif     notification popup               (moves top-right in phase 4)
//   idle      the time
// Highest in that list wins.
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

    readonly property string mode: {
        if (focused && Osd.shown) return "osd";
        if (open === "calendar" || open === "clocks") return open;
        if (focused && Notifs.current) return "notif";
        return "idle";
    }

    view: mode === "osd" ? osdView
        : mode === "calendar" ? calendarView
        : mode === "clocks" ? clocksView
        : mode === "notif" ? notifView
        : idleView
    flat: mode === "idle"
    borderColor: mode === "notif" && Notifs.current?.urgency === NotificationUrgency.Critical
                 ? Theme.urgent : Theme.line

    ClockView {
        id: idleView
        shown: root.mode === "idle"
        onTimeClicked: root.request("clocks")
        onDateClicked: root.request("calendar")
    }

    View {
        id: calendarView
        shown: root.mode === "calendar"
        implicitWidth: calendar.implicitWidth
        implicitHeight: calendar.implicitHeight
        onShownChanged: if (shown) calendar.goToday()
        Calendar { id: calendar }
    }

    View {
        id: clocksView
        shown: root.mode === "clocks"
        implicitWidth: clocks.width
        implicitHeight: clocks.implicitHeight
        onShownChanged: if (shown) { clocks.pickTab(); clocks.focusKeys(); }
        Clocks { id: clocks }
    }

    OsdView {
        id: osdView
        shown: root.mode === "osd"
    }

    NotifView {
        id: notifView
        notification: Notifs.current
        shown: root.mode === "notif"
    }
}
