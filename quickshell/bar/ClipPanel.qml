// ---------------------------------------------------------
// CLIPBOARD  — dropdown of the quick pill's clipboard icon (SUPER + V).
//   [Recent] [Starred] ………………………………… [Clear]
//   entries, newest first, thin lines between them; scrolls past ~420 px
//     text    one line …………………………… −   (★ instead of − when starred)
//     image   the picture (full width, ≤ 160 px tall, rounded)
//             Screenshot_20261114_154207.png …… −
// Click: copy it back (the dropdown closes) · right click: star / unstar ·
// −: delete it. A starred entry can't be deleted (no −, Clear skips it)
// until it is unstarred.
// Starred: the starred entries (they stay after Clear); right click unstars.
// See services/ClipHist.qml (cliphist, where stars and captions come from).
// ---------------------------------------------------------

import QtQuick
import QtQuick.Effects
import qs
import qs.services

Column {
    id: root

    width: 340
    spacing: 10

    property string tab: "recent"               // "recent" | "starred"
    readonly property var model: tab === "recent" ? ClipHist.entries : ClipHist.starred

    signal picked()                             // an entry was copied: close the dropdown

    // round glyph button at the end of a row (−)
    component RowButton: Rectangle {
        id: btn
        property string text
        signal clicked()
        width: 24
        height: 24
        radius: 12
        color: btnMouse.containsMouse ? Theme.selected : "transparent"
        Label {
            anchors.centerIn: parent
            text: btn.text
            color: btnMouse.containsMouse ? Theme.fg : Theme.fgDim
            font.pixelSize: Theme.smallSize + 2
        }
        MouseArea {
            id: btnMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    // ---- tabs · Clear ----
    Item {
        width: root.width
        height: tabs.height
        Row {
            id: tabs
            x: 4
            spacing: 6
            Chip { text: "Recent"; on: root.tab === "recent"; onClicked: root.tab = "recent" }
            Chip { text: "Starred"; on: root.tab === "starred"; onClicked: root.tab = "starred" }
        }
        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            visible: root.tab === "recent" && ClipHist.entries.some(e => !ClipHist.isStarred(e))
            width: clearLabel.implicitWidth + 20
            height: 26
            radius: height / 2
            color: clearMouse.containsMouse ? Theme.selected : "transparent"
            Label {
                id: clearLabel
                anchors.centerIn: parent
                text: "Clear"
                color: Theme.fgDim
                font.pixelSize: Theme.smallSize
            }
            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ClipHist.wipe()
            }
        }
    }

    Label {
        x: 10
        visible: root.model.length === 0
        text: !ClipHist.present ? "cliphist is not installed"
            : "Clipboard is empty."
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }

    Flickable {
        id: list
        width: root.width
        height: Math.min(rows.height, 420)
        visible: rows.height > 0
        contentHeight: rows.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: rows
            width: list.width
            Repeater {
                model: root.model
                Column {
                    id: entry
                    required property var modelData
                    required property int index
                    readonly property bool starred: ClipHist.isStarred(modelData)
                    readonly property bool image: modelData.kind === "img"
                    function toggleStar() { starred ? ClipHist.unstar(modelData) : ClipHist.star(modelData); }
                    width: rows.width

                    // thin line between entries
                    Item {
                        visible: entry.index > 0
                        width: parent.width
                        height: 9
                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            x: 10
                            width: parent.width - 20
                            height: 1
                            color: Theme.bgAlt
                        }
                    }

                    // image: the picture, scaled to fit (never enlarged)
                    Item {
                        id: thumbBox
                        visible: entry.image
                        readonly property real k: entry.image && entry.modelData.w > 0
                            ? Math.min((parent.width - 20) / entry.modelData.w, 160 / entry.modelData.h, 1) : 0
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.round(entry.modelData.w * k)
                        height: entry.image ? Math.round(entry.modelData.h * k) : 0
                        Image {
                            id: thumb
                            anchors.fill: parent
                            visible: false
                            source: entry.image ? "file://" + entry.modelData.path : ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: thumbBox.width * 2
                        }
                        Rectangle {
                            id: thumbMask
                            anchors.fill: parent
                            radius: 10
                            visible: false
                            layer.enabled: true
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: thumb
                            maskEnabled: true
                            maskSource: thumbMask
                            maskThresholdMin: 0.5
                            maskSpreadAtMin: 1.0
                        }
                        MouseArea {
                            anchors.fill: parent
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            cursorShape: Qt.PointingHandCursor
                            onClicked: e => {
                                if (e.button === Qt.RightButton) entry.toggleStar();
                                else { ClipHist.copy(entry.modelData); root.picked(); }
                            }
                        }
                    }

                    // the text, or the image's caption, with − (★ when starred)
                    // (an Item around the row, so the right-click handler covers the whole row;
                    // children of a ListRow go under its text)
                    Item {
                        width: parent.width
                        height: row.height
                        ListRow {
                            id: row
                            width: parent.width
                            icon: "clipboard"
                            text: entry.modelData.text
                            trailing: minus.visible || mark.visible ? "    " : ""   // room for − / ★
                            onClicked: { ClipHist.copy(entry.modelData); root.picked(); }
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2
                            // ★ : starred marker (not a button; right click unstars)
                            Item {
                                id: mark
                                visible: entry.starred && root.tab === "recent"
                                width: 24
                                height: 24
                                Label {
                                    anchors.centerIn: parent
                                    text: Theme.glyph.star
                                    color: Theme.accent
                                    font.pixelSize: Theme.smallSize + 2
                                }
                            }
                            // − : delete (the dropdown stays open); not for starred entries
                            RowButton {
                                id: minus
                                visible: !entry.starred && root.tab === "recent"
                                text: "−"
                                onClicked: ClipHist.remove(entry.modelData)
                            }
                        }
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: entry.toggleStar()
                        }
                    }
                }
            }
        }
    }
}
