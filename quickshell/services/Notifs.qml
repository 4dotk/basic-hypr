// ---------------------------------------------------------
// NOTIFICATIONS  — this IS the notification daemon (org.freedesktop.Notifications).
// Don't run mako/dunst/swaync alongside it; only one can own the name.
//
// Popups go one at a time: `current` is on screen, the rest wait in `queue`.
// Critical ones stay until clicked; the rest time out.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    property Notification current: null
    property var queue: []          // entries turn null if the sender closes them

    readonly property int shortest: 3000   // ms
    readonly property int longest:  8000

    NotificationServer {
        actionsSupported: true
        imageSupported:   true
        keepOnReload:     false     // don't replay old popups when quickshell reloads

        onNotification: n => {
            n.tracked = true;       // otherwise it is dropped straight away
            root.queue = [...root.queue, n];
            if (!root.current) root.next();
        }
    }

    // left click = run the default action (if any), then close
    function activate() {
        if (!current) return;
        const acts = current.actions;
        let def = null;
        for (let i = 0; i < acts.length; i++)
            if (acts[i].identifier === "default") def = acts[i];
        invoke(def);
    }

    // run an action button (or none), then close
    function invoke(action) {
        const c = current;
        if (!c) return;
        current = null;                  // same reason as dismiss() below
        if (action) action.invoke();
        if (c && c.tracked) c.dismiss(); // invoke() may already have closed it
        next();
    }

    // right click / timeout. current is cleared first so our own close
    // doesn't also come back through onClosed below and skip one.
    function dismiss() { const c = current; current = null; if (c) c.dismiss(); next(); }
    function expire()  { const c = current; current = null; if (c) c.expire();  next(); }

    function next() {
        timer.stop();
        // skip any that the sender already closed while waiting
        let q = [...queue];
        let n = null;
        while (q.length > 0 && !n) {
            const c = q.shift();
            if (c && c.tracked) n = c;
        }
        queue = q;
        current = n;
        if (!n || n.urgency === NotificationUrgency.Critical) return;

        // expireTimeout: docs say seconds, the spec says ms — clamping covers both
        const t = n.expireTimeout > 0 ? n.expireTimeout * 1000 : 5000;
        timer.interval = Math.max(shortest, Math.min(longest, t));
        timer.start();
    }

    Timer { id: timer; onTriggered: root.expire() }

    // sender closed the one on screen (e.g. chat read elsewhere)
    Connections {
        target: root.current
        function onClosed() { root.next(); }
    }
}
