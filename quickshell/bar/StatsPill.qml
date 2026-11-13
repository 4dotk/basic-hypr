// ---------------------------------------------------------
// STATS  — CPU %, used RAM, CPU temperature (services/Stats.qml), live.
// Calm by default (grey icons, white numbers); amber when high:
//   warning  CPU/RAM ≥ 70%, temp ≥ 70°   ·   critical (bold)  ≥ 90% / 85°
// Each value has a fixed width for two digits ("99%", "00.0G", "99°"),
// right-aligned: the pill doesn't change width when a number gains a digit,
// and the gaps between stats and at the pill's ends stay even. (100% CPU
// or 100° widen it for that moment.)
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
                    widest: "99%"
                    level: root.level(Stats.cpu, 0.7, 0.9)
                }
                Stat {
                    glyph: Theme.glyph.memory
                    value: root.gib(Stats.memUsed) + "G"
                    widest: "00.0G"
                    level: root.level(Stats.memory, 0.7, 0.9)
                }
                Stat {
                    visible: !isNaN(Stats.temp)
                    glyph: Theme.glyph.temp
                    value: Math.round(Stats.temp) + "°"
                    widest: "99°"
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
        property string widest              // the widest value it can show; sets the width
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
            id: valueLabel
            anchors.verticalCenter: parent.verticalCenter
            width: Math.ceil(Math.max(implicitWidth, widestText.advanceWidth))
            horizontalAlignment: Text.AlignRight
            text: stat.value
            color: stat.level > 0 ? Theme.urgent : Theme.fg
            font.bold: stat.level === 2
            font.pixelSize: Theme.smallSize
            Behavior on color { ColorAnimation { duration: Theme.fade } }

            TextMetrics { id: widestText; font: valueLabel.font; text: stat.widest }
        }
    }
}
