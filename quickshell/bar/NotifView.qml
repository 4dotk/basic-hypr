// ---------------------------------------------------------
// NOTIFICATION POPUP  — one at a time, a separate card under the bell pill.
// The card itself is bar/NotifCard.qml (same as in the center's list).
// Left click: open it (default action) · Right click: remove it.
// ---------------------------------------------------------

import QtQuick
import Quickshell.Services.Notifications
import qs

View {
    id: root

    property Notification notification
    // keep showing the last one while it slides away, instead of going blank
    property Notification last
    onNotificationChanged: if (notification) last = notification

    implicitWidth: card.implicitWidth
    implicitHeight: card.implicitHeight

    NotifCard {
        id: card
        width: parent.width
        n: root.notification ?? root.last
    }
}
