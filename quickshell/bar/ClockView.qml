// ---------------------------------------------------------
// CLOCK (resting)  — date + time, plus chips for a running timer / stopwatch.
// No hover effects on purpose.
//   click the date -> calendar
//   click the time -> timer / stopwatch panel
// ---------------------------------------------------------

import QtQuick
import Quickshell
import qs
import qs.services

View {
    id: root

    signal timeClicked()
    signal dateClicked()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    SystemClock { id: clock; precision: SystemClock.Minutes }

    Row {
        id: row
        spacing: 12

        Clickable {
            text: Qt.formatDateTime(clock.date, "ddd d MMM")
            onClicked: root.dateClicked()
        }
        Clickable {
            text: Qt.formatDateTime(clock.date, "HH:mm")
            font.bold: true
            onClicked: root.timeClicked()
        }

        Clickable {
            visible: Countdown.active
            text: "(" + Theme.glyph.timer + " " + Time.clock(Countdown.left * 1000) + ")"
            color: Countdown.running ? Theme.fg : Theme.fgDim   // running: text colour · paused: dim
            onClicked: root.timeClicked()
        }
        Clickable {
            visible: Stopwatch.active
            text: "(" + Theme.glyph.stopwatch + " " + Time.clock(Stopwatch.elapsed) + ")"
            color: Stopwatch.running ? Theme.fg : Theme.fgDim
            onClicked: root.timeClicked()
        }
    }

    // text with a hand cursor and a slightly taller hit area
    component Clickable: Label {
        id: c
        signal clicked()
        anchors.verticalCenter: parent.verticalCenter

        MouseArea {
            anchors.fill: parent
            anchors.margins: -6
            cursorShape: Qt.PointingHandCursor
            onClicked: c.clicked()
        }
    }
}
