// ---------------------------------------------------------
// STATS  — CPU %, used RAM, CPU temperature (services/Stats.qml), live.
// Calm by default (grey icons, white numbers); amber when high:
//   warning  CPU/RAM ≥ 70%, temp ≥ 70°   ·   critical (bold)  ≥ 90% / 85°
// ---------------------------------------------------------

import QtQuick
import qs
import qs.services

Pill {
    id: root

    view: content

    // 0 normal · 1 warning · 2 critical
    function level(v, warn, crit) { return v >= crit ? 2 : v >= warn ? 1 : 0; }

    View {
        id: content
        shown: true
        implicitWidth: col.implicitWidth
        implicitHeight: col.implicitHeight

        Column {
            id: col
            spacing: 10

            Row {
                id: row
                spacing: 14

                Stat {
                    glyph: Theme.glyph.cpu
                    value: Math.round(Stats.cpu * 100) + "%"
                    level: root.level(Stats.cpu, 0.7, 0.9)
                }
                Stat {
                    glyph: Theme.glyph.memory
                    value: root.gib(Stats.memUsed) + "G"
                    level: root.level(Stats.memory, 0.7, 0.9)
                }
                Stat {
                    visible: !isNaN(Stats.temp)
                    glyph: Theme.glyph.temp
                    value: Math.round(Stats.temp) + "°"
                    level: root.level(Stats.temp, 70, 85)
                }

            }
        }
    }

    // kB -> GiB with one decimal ("0" when empty)
    function gib(kb) {
        const g = kb / 1048576;
        return g < 0.05 ? "0" : g.toFixed(1);
    }

    // one stat: icon + value. level 0 calm, 1 amber, 2 amber + bold
    component Stat: Row {
        id: stat
        property string glyph
        property string value
        property int level: 0
        spacing: 6

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: stat.glyph
            color: stat.level > 0 ? Theme.urgent : Theme.fgDim
            font.pixelSize: Theme.iconSize
            Behavior on color { ColorAnimation { duration: Theme.fade } }
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: stat.value
            color: stat.level > 0 ? Theme.urgent : Theme.fg
            font.bold: stat.level === 2
            font.pixelSize: Theme.smallSize
            Behavior on color { ColorAnimation { duration: Theme.fade } }
        }
    }
}
