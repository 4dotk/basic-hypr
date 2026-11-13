// ---------------------------------------------------------
// PILL  — one rounded box on the bar. Two parts:
//   head    the resting pill; resizes (with a little overshoot) to fit `view`
//   drawer  an optional panel that slides out underneath the head, joined
//           to it by one outline with curved joins (bar/PillShape.qml)
// Put resting View items inside the pill and point `view` at the one to show.
// Put panel View items in `drawers: [ … ]` and point `drawer` at the open one
// (null = closed).
//
// `flat`: resting look, exactly idleHeight tall with no vertical padding.
// `shown`: false slides the pill straight up off the screen (as if the
//          windows push it out); true drops it back down with a small bounce.
//          Used for SUPER + F and for media when nothing plays.
// `drawerAlign`: "center" (default), "left" or "right" (flush with that edge
//          of the head, growing the other way — for pills at a screen edge).
// A joined drawer starts a short neck below the head (`neck`), so its curved
// join and top edge clear the neighbouring pills.
// A drawer View with `detached: true` hangs as a separate card a small gap
// below the head instead (no join) — the clock's calendar and timer.
// The pill's own size is the head's; the drawer hangs outside it, so pills
// next to it don't move. `drawerBox` is the drawer's area (for the bar mask).
// ---------------------------------------------------------

import QtQuick
import qs

Item {
    id: pill

    property Item view
    property Item drawer: null
    // the last drawer opened: keeps its look (joined / detached) while it closes
    property Item lastDrawer: null
    onDrawerChanged: if (drawer) lastDrawer = drawer
    readonly property bool detached: lastDrawer?.detached ?? false
    property string drawerAlign: "center"
    property bool flat: true
    property bool shown: true
    property color borderColor: Theme.line
    property int padX: Theme.pad                  // left/right padding (workspaces uses less)
    readonly property alias hovered: hover.hovered
    readonly property alias drawerBox: box

    default property alias content: head.data     // resting views
    property alias drawers: box.data              // drawer views

    y: shown ? Theme.gap : -(box.y + box.height) - Theme.gap
    width:  Math.max(Theme.idleHeight, (view ? view.implicitWidth : 0) + padX * 2)
    height: Math.max(Theme.idleHeight, (view ? view.implicitHeight : 0) + (flat ? 0 : Theme.pad * 2))

    // a joined drawer's neck: the head's sides run on this far before curving out
    readonly property int neck: detached ? 0 : Theme.spacing

    // drawer size: the open panel plus padding (and the neck); closed = head-wide, no height
    property real drawerWidth:  drawer ? drawer.implicitWidth + Theme.pad * 2 : width
    property real drawerHeight: drawer ? drawer.implicitHeight + Theme.pad * 2 + neck : 0

    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on width        { NumberAnimation { duration: Theme.morph; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    Behavior on height       { NumberAnimation { duration: Theme.morph; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    Behavior on drawerWidth  { NumberAnimation { duration: Theme.morph; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    Behavior on drawerHeight { NumberAnimation { duration: Theme.morph; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    // all pills move together. out: starts moving at once and slows, like the
    // windows pushing up (OutCubic) · in: drops down past the spot and settles (OutBack)
    Behavior on y {
        NumberAnimation {
            duration: pill.shown ? 340 : 250
            easing.type: pill.shown ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 1.6
        }
    }
    // fade only at the very end of leaving; appear quickly when coming back
    Behavior on opacity {
        NumberAnimation { duration: pill.shown ? 120 : 250; easing.type: pill.shown ? Easing.OutCubic : Easing.InExpo }
    }

    // background + border of head and drawer together
    PillShape {
        headWidth: pill.width
        headHeight: pill.height
        drawerX: box.x
        drawerWidth: box.width
        drawerHeight: Math.max(0, pill.drawerHeight)
        drawerGap: pill.detached ? Theme.spacing : 0
        neck: pill.neck
        radius: Theme.rounding
        border: Theme.border
        fill: Theme.bg
        stroke: pill.borderColor
        Behavior on stroke { ColorAnimation { duration: Theme.fade } }
    }

    Item {
        id: head
        width: pill.width
        height: pill.height
        clip: true
    }

    Item {
        id: box
        x: pill.drawerAlign === "right" ? pill.width - width
         : pill.drawerAlign === "left" ? 0
         : (pill.width - width) / 2
        y: pill.height + (pill.detached ? Theme.spacing : pill.neck)
        width: Math.max(0, pill.drawerWidth)
        height: Math.max(0, pill.drawerHeight - pill.neck)
        clip: true
    }

    // passive, so buttons inside still get their clicks
    HoverHandler { id: hover }
}
