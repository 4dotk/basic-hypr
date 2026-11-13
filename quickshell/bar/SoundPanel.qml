// ---------------------------------------------------------
// SOUND  — the mixer dropdown of the quick pill's sound icon.
// One list, three sections:
//   Output  every output device: click the name to make it the default
//           (accent + dot), slider, mute
//   Mic     every mic: same
//   Apps    every app playing sound: icon, name, what it plays; slider, mute
// Sliders: click/drag, scroll ±5 %, capped at 100 %.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Pipewire
import qs
import qs.services

Column {
    id: root

    width: 360
    spacing: 18

    // ---- Output ----
    Heading { text: "Output"; width: root.width }
    Repeater {
        model: Audio.outputs
        DeviceRow { required property PwNode modelData; node: modelData; width: root.width }
    }

    // ---- Mic ----
    Heading { text: "Mic"; width: root.width; topGap: true }
    Repeater {
        model: Audio.inputs
        DeviceRow { required property PwNode modelData; node: modelData; width: root.width }
    }

    // ---- Apps ----
    Heading { text: "Apps"; width: root.width; topGap: true }
    Label {
        visible: Audio.apps.length === 0
        x: 10
        text: "Nothing playing"
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }
    Repeater {
        model: Audio.apps
        AppRow { required property PwNode modelData; node: modelData; width: root.width }
    }

    // mute button + slider + percentage (shared by devices and apps)
    component Level: Row {
        id: level
        property PwNode node
        property string icon                      // quickshell/icons name when not muted
        property string mutedIcon
        readonly property real value: node?.audio?.volume ?? 0
        readonly property bool muted: node?.audio?.muted ?? false
        spacing: 6

        IconButton {
            id: mute
            anchors.verticalCenter: parent.verticalCenter
            icon: level.muted ? level.mutedIcon : level.icon
            size: Theme.iconSize
            onClicked: Audio.toggleMute(level.node)
        }
        Slider {
            anchors.verticalCenter: parent.verticalCenter
            width: level.width - mute.width - pct.width - level.spacing * 2
            value: level.value
            muted: level.muted
            onMoved: v => Audio.setVolume(level.node, v)
        }
        Label {
            id: pct
            anchors.verticalCenter: parent.verticalCenter
            width: 40                             // fixed so the slider doesn't wobble 9% -> 10%
            horizontalAlignment: Text.AlignRight
            text: Math.round(level.value * 100) + "%"
            color: level.muted ? Theme.fgDim : Theme.fg
            font.pixelSize: Theme.smallSize
        }
    }

    // one device: clickable name (makes it the default), then its level
    component DeviceRow: Column {
        id: dev
        property PwNode node
        readonly property bool isDefault: node !== null && node === (node.isSink ? Audio.sink : Audio.source)
        readonly property string icon: {
            if (!node?.isSink) return "mic";
            return /head(phone|set)|bluez/i.test((node?.name ?? "") + " " + (node?.description ?? ""))
                   ? "headphones" : "speaker";
        }
        spacing: 8

        Rectangle {
            width: parent.width
            height: name.implicitHeight + 10
            radius: height / 2
            color: pick.containsMouse && !dev.isDefault ? Theme.selected : "transparent"

            SvgIcon {
                id: glyph
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                name: dev.icon
                color: dev.isDefault ? Theme.accent : Theme.fgDim
            }
            Label {
                id: name
                anchors.left: glyph.right
                anchors.leftMargin: 10
                anchors.right: marker.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Audio.label(dev.node)
                color: dev.isDefault ? Theme.accent : Theme.fg
            }
            Label {
                id: marker
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: dev.isDefault ? Theme.glyph.dot : ""
                color: Theme.accent
                font.pixelSize: Theme.smallSize
            }
            MouseArea {
                id: pick
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: dev.isDefault ? Qt.ArrowCursor : Qt.PointingHandCursor
                onClicked: if (!dev.isDefault) Audio.setDefault(dev.node)
            }
        }

        Level {
            width: parent.width
            node: dev.node
            icon: dev.node?.isSink ? Theme.volumeIcon(value, false) : "mic"
            mutedIcon: dev.node?.isSink ? "vol-off" : "mic-off"
        }
    }

    // one app playing sound: icon, app name, what it plays, then its level
    component AppRow: Column {
        id: app
        property PwNode node
        readonly property var props: node?.properties ?? ({})
        readonly property string appName: props["application.name"] || Audio.label(node)
        readonly property string playing: props["media.title"] || props["media.name"] || ""
        readonly property string iconPath: Quickshell.iconPath(props["application.icon-name"]
                                                               || appName.toLowerCase(), true)
        spacing: 8

        Row {
            x: 10
            width: parent.width - 20
            spacing: 10

            Item {
                anchors.verticalCenter: parent.verticalCenter
                width: 24
                height: 24
                IconImage {
                    anchors.fill: parent
                    visible: app.iconPath !== ""
                    source: app.iconPath
                }
                Label {
                    anchors.centerIn: parent
                    visible: app.iconPath === ""
                    text: Theme.glyph.app
                    color: Theme.fgDim
                    font.pixelSize: Theme.iconSize
                }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 34
                Label { width: parent.width; text: app.appName }
                Label {
                    width: parent.width
                    visible: text !== "" && text !== app.appName
                    text: app.playing
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                }
            }
        }

        Level {
            width: parent.width
            node: app.node
            icon: Theme.volumeIcon(value, false)
            mutedIcon: "vol-off"
        }
    }
}
