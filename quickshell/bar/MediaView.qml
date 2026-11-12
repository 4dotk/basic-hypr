// ---------------------------------------------------------
// MEDIA  — what's playing (MPRIS: spotify, firefox, mpv …).
// Small: cover + title + play/pause.  Hover: artist, progress, prev/next.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs

View {
    id: root

    property MprisPlayer player
    property bool expanded: false

    readonly property string title:  player?.trackTitle || player?.identity || "Unknown"
    readonly property string artist: player?.trackArtist ?? ""
    readonly property bool playing:  player?.isPlaying ?? false
    readonly property string artUrl: player?.trackArtUrl ?? ""

    implicitWidth:  expanded ? full.implicitWidth  : small.implicitWidth
    implicitHeight: expanded ? full.implicitHeight : small.implicitHeight

    // the player doesn't announce position changes; ask once a second while visible
    Timer {
        running: root.shown && root.expanded && root.playing
        interval: 1000
        repeat: true
        onTriggered: root.player.positionChanged()
    }

    // ---- small ----
    Row {
        id: small
        anchors.centerIn: parent
        spacing: 10
        visible: opacity > 0
        opacity: root.expanded ? 0 : 1
        Behavior on opacity { NumberAnimation { duration: Theme.fade } }

        Cover { size: 22; source: root.artUrl; anchors.verticalCenter: parent.verticalCenter }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, 220)
            text: root.title
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.playing ? Theme.glyph.pause : Theme.glyph.play
            color: Theme.accent
            font.pixelSize: Theme.iconSize
        }
    }

    // ---- expanded ----
    Column {
        id: full
        anchors.centerIn: parent
        spacing: 10
        visible: opacity > 0
        opacity: root.expanded ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Theme.fade } }

        Row {
            id: head
            spacing: 12

            Cover { size: 56; source: root.artUrl }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                Label { width: Math.min(implicitWidth, 300); text: root.title; font.bold: true }
                Label {
                    width: Math.min(implicitWidth, 300)
                    text: root.artist
                    visible: text !== ""
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                }
            }
        }

        // progress (hidden when the player doesn't report length)
        Rectangle {
            width: Math.max(260, head.implicitWidth)
            height: 4
            radius: 2
            color: Theme.bgAlt
            visible: (root.player?.lengthSupported ?? false) && root.player.length > 0

            Rectangle {
                height: parent.height
                radius: parent.radius
                color: Theme.accent
                width: root.player && root.player.length > 0
                       ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
                Behavior on width { NumberAnimation { duration: 900 } }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 6
            IconButton {
                glyph: Theme.glyph.prev
                opacity: root.player?.canGoPrevious ? 1 : 0.4
                onClicked: if (root.player?.canGoPrevious) root.player.previous()
            }
            IconButton {
                glyph: root.playing ? Theme.glyph.pause : Theme.glyph.play
                size: Theme.iconSize + 8
                onClicked: if (root.player?.canTogglePlaying) root.player.togglePlaying()
            }
            IconButton {
                glyph: Theme.glyph.next
                opacity: root.player?.canGoNext ? 1 : 0.4
                onClicked: if (root.player?.canGoNext) root.player.next()
            }
        }
    }

    // album art, or a music note when there is none
    // (inline components can't see `root`, so the art url is passed in)
    component Cover: ClippingRectangle {
        id: cover
        property int size: 22
        property string source
        implicitWidth: size
        implicitHeight: size
        radius: size > 30 ? 10 : 6
        color: Theme.bgAlt

        Label {
            anchors.centerIn: parent
            visible: art.status !== Image.Ready
            text: Theme.glyph.music
            color: Theme.accent
            font.pixelSize: cover.size * 0.6
        }
        Image {
            id: art
            anchors.fill: parent
            source: cover.source
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 128
            sourceSize.height: 128
        }
    }
}
