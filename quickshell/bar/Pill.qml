// ---------------------------------------------------------
// PILL  — one rounded box on the bar that resizes (with a little overshoot)
// to fit whichever of its views is active. Put View items inside it and
// point `view` at the one to show.
//
// `flat`: resting look, exactly idleHeight tall with no vertical padding.
// `shown`: false slides the pill straight up off the screen (as if the
//          windows push it out); true drops it back down with a small bounce.
//          Used for SUPER + F and for media when nothing plays.
// ---------------------------------------------------------

import QtQuick
import qs

Rectangle {
    id: pill

    property Item view
    property bool flat: true
    property bool shown: true
    property color borderColor: Theme.line
    property int padX: Theme.pad                  // left/right padding (workspaces uses less)
    readonly property alias hovered: hover.hovered

    y: shown ? Theme.gap : -height - Theme.gap
    width:  Math.max(Theme.idleHeight, (view ? view.implicitWidth : 0) + padX * 2)
    height: Math.max(Theme.idleHeight, (view ? view.implicitHeight : 0) + (flat ? 0 : Theme.pad * 2))
    radius: Theme.rounding

    color: Theme.bg
    border.width: Theme.border
    border.color: borderColor
    clip: true

    opacity: shown ? 1 : 0
    visible: opacity > 0

    Behavior on width   { NumberAnimation { duration: Theme.morph; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
    Behavior on height  { NumberAnimation { duration: Theme.morph; easing.type: Easing.OutBack; easing.overshoot: 0.8 } }
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
    Behavior on border.color { ColorAnimation { duration: Theme.fade } }

    // passive, so buttons inside still get their clicks
    HoverHandler { id: hover }
}
