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
// `joinLeft` / `joinRight` (0–1): that side meets a bridge on an empty
// workspace; the bridge drives them while it animates (bar/Bridge.qml).
// Width is whole pixels, so joined edges line up exactly with the bridge.
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
    // extra padding on one side only (the bar's outer ends on a full bar)
    property real padLeftExtra: 0
    property real padRightExtra: 0
    // morphs only at rest: a pill sliding in arrives already in shape
    Behavior on padLeftExtra  { enabled: pill.atRest; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on padRightExtra { enabled: pill.atRest; NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    property Item backdrop: null                  // the bar's shared fill layer (Bar.qml)
    property real joinLeft: 0                     // set by the bridge next to it (bar/Bridge.qml)
    property real joinRight: 0
    readonly property alias hovered: hover.hovered
    readonly property alias drawerBox: box

    default property alias content: head.data     // resting views
    property alias drawers: box.data              // drawer views

    y: shown ? Theme.gap : -(box.y + box.height) - Theme.gap
    // sitting in its spot (not sliding in or out, not hidden). Joins and end
    // padding only animate at rest; otherwise they snap (here and bar/Bridge.qml)
    readonly property bool atRest: y === Theme.gap
    width:  Math.round(Math.max(Theme.idleHeight, (view ? view.implicitWidth : 0) + padX * 2)
                       + padLeftExtra + padRightExtra)
    height: Math.max(Theme.idleHeight, (view ? view.implicitHeight : 0) + (flat ? 0 : Theme.pad * 2))

    // a joined drawer's neck: the head's sides run on this far before curving out
    readonly property int neck: detached ? 0 : Theme.spacing
    // a detached card's gap below the head (its View may ask for its own)
    readonly property real cardGap: (lastDrawer?.cardGap ?? 0) > 0 ? lastDrawer.cardGap : Theme.spacing

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
    // fade only at the very end of leaving. Coming back there is no fade: the
    // pill is off screen (not atRest), so it is opaque at once and just slides
    // in. A fade-in would show lines on a full bar: pill and bridge fills
    // overlap 1 px at the joins, and part-transparent, the overlap draws darker.
    Behavior on opacity {
        enabled: pill.atRest
        NumberAnimation { duration: 250; easing.type: Easing.InExpo }
    }

    // background + border of head and drawer together
    PillShape {
        headWidth: pill.width
        headHeight: pill.height
        drawerX: box.x
        drawerWidth: box.width
        drawerHeight: Math.max(0, pill.drawerHeight)
        drawerGap: pill.detached ? pill.cardGap : 0
        neck: pill.neck
        radius: Theme.rounding
        border: Theme.border
        fill: Theme.bg
        cardFill: pill.lastDrawer && pill.lastDrawer.cardColor.a > 0 ? pill.lastDrawer.cardColor
                : pill.lastDrawer?.opaque ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 1) : Theme.bg
        stroke: pill.borderColor
        cardStroke: pill.lastDrawer && pill.lastDrawer.cardStroke.a > 0 ? pill.lastDrawer.cardStroke : pill.borderColor
        cardBorder: (pill.lastDrawer?.cardBorder ?? 0) > 0 ? pill.lastDrawer.cardBorder : Theme.border
        joinLeft: pill.joinLeft
        joinRight: pill.joinRight
        backdrop: pill.backdrop
        host: pill
        Behavior on stroke { ColorAnimation { duration: Theme.fade } }
    }

    Item {
        id: head
        // the resting views centre in here: the extra padding is kept out of it
        x: pill.padLeftExtra
        width: pill.width - pill.padLeftExtra - pill.padRightExtra
        height: pill.height
        clip: true
    }

    Item {
        id: box
        x: pill.drawerAlign === "right" ? pill.width - width
         : pill.drawerAlign === "left" ? 0
         : (pill.width - width) / 2
        y: pill.height + (pill.detached ? pill.cardGap : pill.neck)
        width: Math.max(0, pill.drawerWidth)
        height: Math.max(0, pill.drawerHeight - pill.neck)
        clip: true
    }

    // passive, so buttons inside still get their clicks
    HoverHandler { id: hover }
}
