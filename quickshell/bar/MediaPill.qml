// ---------------------------------------------------------
// MEDIA PILL  — only there while something plays (and a few seconds
// after pausing). Hover for artist, progress and controls.
// ---------------------------------------------------------

import QtQuick
import qs
import qs.services

Pill {
    id: root

    property bool hidden: false         // the whole bar is hidden (SUPER + F)

    // stay while the mouse is on it, even after pausing
    property bool held: false
    onHoveredChanged: held = hovered && shown

    shown: !hidden && (Media.shown || held) && Media.player !== null
    view: content
    flat: !hovered

    MediaView {
        id: content
        player: Media.player
        expanded: root.hovered
        shown: true
    }
}
