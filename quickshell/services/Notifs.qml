// ---------------------------------------------------------
// NOTIFICATIONS  — this IS the notification daemon (org.freedesktop.Notifications).
// Don't run mako/dunst/swaync alongside it; only one can own the name.
//
// Every notification stays in `list` (newest first, the notification center)
// until it's clicked, removed (right click / Clear) or the sender closes it.
// Popups go one at a time from the bell pill: `current` is on screen, the rest
// wait in `queue`. A popup timing out only hides the popup; it stays in the list.
// Critical ones stay until clicked. While the center is open, new ones go
// straight into the list (no popup).
//
// Do not disturb (`dnd`): no popups, except critical ones (the sending app
// marks a notification critical — low battery and the like).
// `unread`: arrived since the center was last opened (the bell's dot).
// History lives in memory: gone when quickshell restarts.
//
// Sound: each new notification plays one (pw-play), unless do not disturb is
// on (no sounds at all then, critical included) or the app asks for silence
// (hint suppress-sound). The app's own sound-file / sound-name hint wins
// (names looked up in KDE's Ocean theme, then freedesktop); otherwise Ocean's
// message-attention.oga, dialog-warning.oga for critical ones.
// At most one sound per 400 ms, so a burst doesn't stack up.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

Singleton {
    id: root

    property Notification current: null
    property var queue: []          // entries turn null if the sender closes them

    property bool dnd: false
    property bool centerOpen: false // set by the bell pill while its center is open
    property int unread: 0
    onCenterOpenChanged: if (centerOpen) { unread = 0; current = null; queue = []; timer.stop(); }

    // newest first
    readonly property var list: [...server.trackedNotifications.values].reverse()
    readonly property int maxKept: 50

    // arrival time per notification id (Notification has no timestamp of its own)
    property var arrived: ({})
    function age(n) {
        const t = n ? arrived[n.id] : undefined;
        if (!t) return "";
        const m = Math.floor((Date.now() - t) / 60000);
        if (m < 1) return "now";
        if (m < 60) return m + "m";
        if (m < 1440) return Math.floor(m / 60) + "h";
        return Math.floor(m / 1440) + "d";
    }

    readonly property int shortest: 3000   // ms
    readonly property int longest:  8000

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported:   true
        keepOnReload:     false     // don't replay old popups when quickshell reloads

        onNotification: n => {
            n.tracked = true;       // otherwise it is dropped straight away
            const a = Object.assign({}, root.arrived);
            a[n.id] = Date.now();
            root.arrived = a;

            // keep the list bounded: drop the oldest beyond maxKept
            const all = server.trackedNotifications.values;
            for (let i = 0; i < all.length - root.maxKept; i++) all[i].dismiss();

            root.chime(n);
            if (root.centerOpen) return;            // it's in the list already
            root.unread++;
            if (root.dnd && n.urgency !== NotificationUrgency.Critical) return;
            root.queue = [...root.queue, n];
            if (!root.current) root.next();
        }
    }

    // ---- sound ----
    readonly property string ocean: "/usr/share/sounds/ocean/stereo/"
    readonly property string freedesktop: "/usr/share/sounds/freedesktop/stereo/"
    property real lastChime: 0
    function chime(n) {
        if (dnd) return;
        const h = n.hints ?? ({});
        if (h["suppress-sound"] === true) return;
        const now = Date.now();
        if (now - lastChime < 400) return;
        lastChime = now;
        const fallback = ocean + (n.urgency === NotificationUrgency.Critical ? "dialog-warning.oga" : "message-attention.oga");
        const file = String(h["sound-file"] ?? "");
        const name = h["sound-name"] ? String(h["sound-name"]) + ".oga" : "";
        const p = player.createObject(root, { command: ["sh", "-c",
            "for f in \"$1\" \"$2\" \"$3\" \"$4\"; do [ -f \"$f\" ] && exec pw-play \"$f\"; done",
            "sh", file, name ? ocean + name : "", name ? freedesktop + name : "", fallback] });
        p.running = true;
    }
    Component {
        id: player
        Process { onExited: destroy() }
    }

    // left click: run the default action (if any), then remove it
    function activate(n) {
        n = n ?? current;
        if (!n) return;
        const acts = n.actions;
        let def = null;
        for (let i = 0; i < acts.length; i++)
            if (acts[i].identifier === "default") def = acts[i];
        invoke(def, n);
    }

    // run an action button (or none), then remove it
    function invoke(action, n) {
        n = n ?? current;
        if (!n) return;
        if (n === current) { current = null; next(); }   // before closing, so onClosed doesn't skip one
        if (action) action.invoke();
        if (n.tracked) n.dismiss();                       // invoke() may already have closed it
    }

    // right click: remove it
    function dismiss(n) {
        n = n ?? current;
        if (!n) return;
        if (n === current) { current = null; next(); }
        n.dismiss();
    }

    function clearAll() {
        current = null;
        queue = [];
        timer.stop();
        const all = [...server.trackedNotifications.values];
        for (const n of all) n.dismiss();
        arrived = ({});
    }

    // popup timed out: hide it, keep it in the list
    function hidePopup() { current = null; next(); }

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

    Timer { id: timer; onTriggered: root.hidePopup() }

    // sender closed the one on screen (e.g. chat read elsewhere)
    Connections {
        target: root.current
        function onClosed() { root.current = null; root.next(); }
    }
}
