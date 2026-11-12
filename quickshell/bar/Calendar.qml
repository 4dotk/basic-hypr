// ---------------------------------------------------------
// CALENDAR  — month grid. Arrows or scroll change month,
// click the month name to jump back to today.
// Week starts on the system locale's first day.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import qs

Column {
    id: root

    property int year
    property int month               // 0-11, like JS Date
    // sizes: change these to scale the whole calendar
    readonly property int cell: 50          // day column width
    readonly property int row: 42           // day row height

    spacing: 16                             // header <-> grid

    SystemClock { id: clock; precision: SystemClock.Minutes }   // moves "today" at midnight

    function goToday() {
        year = clock.date.getFullYear();
        month = clock.date.getMonth();
    }
    function shift(by) {
        const d = new Date(year, month + by, 1);
        year = d.getFullYear();
        month = d.getMonth();
    }
    Component.onCompleted: goToday()

    // Qt: Monday=1 … Sunday=7.  JS Date: Sunday=0 … Saturday=6
    readonly property int firstDay: Qt.locale().firstDayOfWeek % 7

    // 6 weeks x 7 days, starting on the first-day-of-week before the 1st
    readonly property var days: {
        const first = new Date(year, month, 1);
        const offset = (first.getDay() - firstDay + 7) % 7;
        const now = clock.date;
        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(year, month, 1 - offset + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === month,
                today: d.toDateString() === now.toDateString()
            });
        }
        return out;
    }

    // ---- header: ‹ November 2026 › ----
    Item {
        width: grid.width
        height: 36

        IconButton {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.glyph.left
            onClicked: root.shift(-1)
        }
        Label {
            anchors.centerIn: parent
            text: Qt.locale().standaloneMonthName(root.month) + " " + root.year
            font.bold: true
            font.pixelSize: Theme.fontSize + 2
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.goToday()
            }
        }
        IconButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            glyph: Theme.glyph.right
            onClicked: root.shift(1)
        }
    }

    // ---- weekday letters + days ----
    Grid {
        id: grid
        columns: 7
        spacing: 4

        Repeater {
            model: 7
            Label {
                required property int index
                width: root.cell
                horizontalAlignment: Text.AlignHCenter
                text: Qt.locale().dayName((root.firstDay + index) % 7, Locale.ShortFormat).slice(0, 2)
                color: Theme.fgDim
                font.pixelSize: Theme.smallSize
            }
        }

        Repeater {
            model: root.days
            Rectangle {
                required property var modelData
                width: root.cell
                height: root.row
                radius: 10                  // rounded square, like the active workspace
                color: modelData.today ? Theme.accent : "transparent"

                Label {
                    anchors.centerIn: parent
                    text: parent.modelData.day
                    font.pixelSize: Theme.fontSize
                    font.bold: parent.modelData.today
                    color: parent.modelData.today ? Theme.bg
                         : parent.modelData.inMonth ? Theme.fg
                         : Theme.fgDim
                    opacity: parent.modelData.inMonth ? 1 : 0.5
                }
            }
        }
    }

    // scroll anywhere on the calendar to change month
    WheelHandler {
        onWheel: e => root.shift(e.angleDelta.y > 0 ? -1 : 1)
    }
}
