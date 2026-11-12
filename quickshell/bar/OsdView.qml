// ---------------------------------------------------------
// OSD  — volume or brightness level after a media key.
// ---------------------------------------------------------

import QtQuick
import qs
import qs.services

View {
    id: root

    readonly property bool isVolume: Osd.kind === "volume"
    readonly property real level: isVolume ? Audio.volume : Brightness.level
    readonly property bool muted: isVolume && Audio.muted

    readonly property string icon: {
        if (!isVolume) return Theme.glyph.brightness;
        if (muted || level <= 0) return Theme.glyph.volOff;
        if (level < 0.34) return Theme.glyph.volLow;
        if (level < 0.67) return Theme.glyph.volMedium;
        return Theme.glyph.volHigh;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    Row {
        id: row
        spacing: 12

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.iconSize + 6
            horizontalAlignment: Text.AlignHCenter
            text: root.icon
            color: root.muted ? Theme.fgDim : Theme.accent
            font.pixelSize: Theme.iconSize + 2
        }

        // bar
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: 200
            height: 6
            radius: 3
            color: Theme.bgAlt

            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * Math.max(0, Math.min(1, root.level))
                color: root.muted ? Theme.fgDim : Theme.accent
                Behavior on width { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: 40                       // fixed so the pill doesn't wobble 9% -> 10%
            horizontalAlignment: Text.AlignRight
            text: Math.round(root.level * 100) + "%"
            color: root.muted ? Theme.fgDim : Theme.fg
            font.pixelSize: Theme.smallSize
        }
    }
}
