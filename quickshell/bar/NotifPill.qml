// ---------------------------------------------------------
// NOTIF PILL  — right edge of the bar, beside the quick pill: a bell.
// Placeholder for the notification center (history, do not disturb);
// it does nothing yet. Popups still show under the clock for now.
// ---------------------------------------------------------

import QtQuick
import qs

Pill {
    id: root

    view: idleView
    padX: 8                                 // a 34 × 34 square, like the power pill

    View {
        id: idleView
        shown: true
        implicitWidth: bell.width
        implicitHeight: bell.implicitHeight

        Label {
            id: bell
            width: Theme.iconSize
            horizontalAlignment: Text.AlignHCenter
            text: Theme.glyph.bell
            font.pixelSize: Theme.iconSize
        }
    }
}
