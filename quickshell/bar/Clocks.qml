// ---------------------------------------------------------
// CLOCKS  — Timer | Stopwatch tabs, next to the calendar.
//
// Timer, not running: edit hh : mm : ss — click a field and type, scroll or
//                     ↑/↓ for ±1, ←/→/Tab to move, Enter or ▶ to start.
// Timer, running:     pause / +1 min / reset.
// Stopwatch:          ▶/pause, lap (while running), reset. Last 3 laps listed.
// Both keep running with the panel closed; the idle pill shows them.
// ---------------------------------------------------------

import QtQuick
import qs
import qs.services

Column {
    id: root

    property string tab: "timer"

    // ---- the timer's editable value: hours, minutes, seconds (kept between uses) ----
    property int hours: 0
    property int minutes: 5
    property int seconds: 0
    readonly property int total: hours * 3600 + minutes * 60 + seconds
    property int field: 1                  // selected: 0 hours, 1 minutes, 2 seconds
    property string typed: ""              // digits typed into the selected field so far

    function get(i) { return [hours, minutes, seconds][i]; }
    function set(i, v) {
        const max = i === 0 ? 99 : 59;     // typing past 59 clamps
        v = Math.max(0, Math.min(max, v));
        if (i === 0) hours = v; else if (i === 1) minutes = v; else seconds = v;
    }
    function select(i) { field = i; typed = ""; keys.forceActiveFocus(); }
    // ±1, wrapping minutes/seconds 59 <-> 0
    function step(d) {
        typed = "";
        const max = field === 0 ? 99 : 59;
        set(field, (get(field) + d + max + 1) % (max + 1));
    }
    // "2" then "5" -> 25; a third digit starts over from the last two
    function type(digit) {
        typed = (typed + digit).slice(-2);
        set(field, parseInt(typed));
    }
    function startTimer() { if (total > 0) Countdown.start(total); }
    function focusKeys() { keys.forceActiveFocus(); }

    // open on whichever one is in use
    function pickTab() {
        if (Stopwatch.active && !Countdown.active) tab = "stopwatch";
        else tab = "timer";
    }

    width: 300
    spacing: 12

    // ---- tabs ----
    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 6
        Chip { text: Theme.glyph.timer + "  Timer"; on: root.tab === "timer"; onClicked: root.tab = "timer" }
        Chip { text: Theme.glyph.stopwatch + "  Stopwatch"; on: root.tab === "stopwatch"; onClicked: root.tab = "stopwatch" }
    }

    // ================= TIMER =================
    Column {
        width: parent.width
        spacing: 12
        visible: root.tab === "timer"

        // ---- running / paused: plain countdown ----
        Label {
            visible: Countdown.active
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.clock(Countdown.left * 1000)
            font.pixelSize: 40
            font.bold: true
            color: Countdown.running ? Theme.fg : Theme.fgDim
        }

        // ---- not running: editable  hh : mm : ss ----
        Row {
            visible: !Countdown.active
            anchors.horizontalCenter: parent.horizontalCenter

            Repeater {
                model: 3

                Row {
                    id: part
                    required property int index

                    Label {
                        visible: part.index > 0
                        text: ":"
                        font.pixelSize: 40
                        font.bold: true
                        color: Theme.fgDim
                    }

                    Item {
                        width: digits.implicitWidth + 8
                        height: digits.implicitHeight + 6

                        Label {
                            id: digits
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Time.pad(root.get(part.index))
                            font.pixelSize: 40
                            font.bold: true
                            color: root.field === part.index ? Theme.accent : Theme.fg
                        }
                        // selected field
                        Rectangle {
                            anchors.bottom: parent.bottom
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: digits.implicitWidth
                            height: 3
                            radius: 1.5
                            color: Theme.accent
                            visible: root.field === part.index
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: root.select(part.index)
                        }
                        WheelHandler {
                            onWheel: e => {
                                root.select(part.index);
                                root.step(e.angleDelta.y > 0 ? 1 : -1);
                            }
                        }
                    }
                }
            }
        }

        // progress while counting
        Rectangle {
            visible: Countdown.active
            width: parent.width
            height: 4
            radius: 2
            color: Theme.bgAlt
            Rectangle {
                height: parent.height
                radius: parent.radius
                width: parent.width * Countdown.progress
                color: Theme.accent
                Behavior on width { NumberAnimation { duration: 250 } }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            IconButton {
                glyph: Countdown.running ? Theme.glyph.pause : Theme.glyph.play
                size: Theme.iconSize + 8
                opacity: Countdown.active || root.total > 0 ? 1 : 0.4
                onClicked: Countdown.active ? Countdown.toggle() : root.startTimer()
            }
            IconButton {
                visible: Countdown.active
                glyph: Theme.glyph.plus
                onClicked: Countdown.add(60)
            }
            IconButton {
                visible: Countdown.active
                glyph: Theme.glyph.reset
                onClicked: Countdown.reset()
            }
        }

        // keyboard for the fields (the bar takes keyboard input while this panel is open)
        Item {
            id: keys
            focus: true
            Keys.onPressed: e => {
                if (Countdown.active) return;
                const k = e.key;
                if (k >= Qt.Key_0 && k <= Qt.Key_9) root.type(k - Qt.Key_0);
                else if (k === Qt.Key_Backspace) { root.set(root.field, 0); root.typed = ""; }
                else if (k === Qt.Key_Up) root.step(1);
                else if (k === Qt.Key_Down) root.step(-1);
                else if (k === Qt.Key_Left || k === Qt.Key_Backtab) root.select(Math.max(0, root.field - 1));
                else if (k === Qt.Key_Right || k === Qt.Key_Tab) root.select(Math.min(2, root.field + 1));
                else if (k === Qt.Key_Return || k === Qt.Key_Enter) root.startTimer();
                else return;
                e.accepted = true;
            }
        }
    }

    // ================= STOPWATCH =================
    Column {
        width: parent.width
        spacing: 12
        visible: root.tab === "stopwatch"

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Time.clock(Stopwatch.elapsed, true)
            font.pixelSize: 40
            font.bold: true
            color: Stopwatch.active && !Stopwatch.running ? Theme.fgDim : Theme.fg
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8
            IconButton {
                glyph: Stopwatch.running ? Theme.glyph.pause : Theme.glyph.play
                size: Theme.iconSize + 8
                onClicked: Stopwatch.toggle()
            }
            IconButton {
                visible: Stopwatch.running
                glyph: Theme.glyph.lap
                onClicked: Stopwatch.lap()
            }
            IconButton {
                visible: Stopwatch.active && !Stopwatch.running
                glyph: Theme.glyph.reset
                onClicked: Stopwatch.reset()
            }
        }

        // last 3 laps: "#3   01:12.4"
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            Repeater {
                model: Stopwatch.laps.slice(0, 3)
                Label {
                    required property var modelData
                    required property int index
                    text: "#" + (Stopwatch.laps.length - index) + "   " + Time.clock(modelData, true)
                    color: Theme.fgDim
                    font.pixelSize: Theme.smallSize
                }
            }
        }
    }
}
