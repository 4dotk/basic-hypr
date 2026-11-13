// ---------------------------------------------------------
// VIEW  — base for every view inside a pill: sits centred in the pill and
// fades in/out. Set implicitWidth/implicitHeight; the pill sizes to them.
// ---------------------------------------------------------

import QtQuick
import qs

Item {
    property bool shown: false
    property bool detached: false   // as a drawer: a separate card below the pill (bar/Pill.qml)
    property bool opaque: false     // as a detached card: fully opaque background (popups)

    anchors.centerIn: parent
    opacity: shown ? 1 : 0
    visible: opacity > 0
    enabled: shown                  // a fading-out view can't be clicked

    Behavior on opacity { NumberAnimation { duration: Theme.fade } }
}
