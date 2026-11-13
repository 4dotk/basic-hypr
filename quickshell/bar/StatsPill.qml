// ---------------------------------------------------------
// STATS  — CPU %, used RAM, CPU temperature (services/Stats.qml), live.
// Calm by default (grey icons, white numbers); amber when high:
//   warning  CPU/RAM ≥ 70%, temp ≥ 70°   ·   critical (bold)  ≥ 90% / 85°
// Each stat (icon + value) sits in a fixed slot sized for its widest value
// ("100%", "00.0G", "100°"): the icon always stays 6 px from its number and
// the pill never changes width. The first stat hugs the left of its slot, the
// last one the right, middle ones are centred — spare room only goes between
// stats, so both ends of the pill have exactly the same padding.
// CPU below 10% gets a leading zero (03%), so it always takes two digits.
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
                    align: "left"
                    glyph: Theme.glyph.cpu
                    readonly property int pct: Math.round(Stats.cpu * 100)
                    value: (pct < 10 ? "0" : "") + pct + "%"
                    widest: "100%"
                    level: root.level(Stats.cpu, 0.7, 0.9)
                }
                Stat {
                    align: temp.visible ? "center" : "right"     // last when there's no sensor
                    glyph: Theme.glyph.memory
                    value: root.gib(Stats.memUsed) + "G"
                    widest: "00.0G"
                    level: root.level(Stats.memory, 0.7, 0.9)
                }
                Stat {
                    id: temp
                    align: "right"
                    visible: !isNaN(Stats.temp)
                    glyph: Theme.glyph.temp
                    value: Math.round(Stats.temp) + "°"
                    widest: "100°"
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

    // one stat: icon + value in a slot as wide as icon + widest value,
    // placed at the slot's left, centre or right (`align`).
    // level 0 calm, 1 amber, 2 amber + bold
    component Stat: Item {
        id: stat
        property string glyph
        property string value
        property string widest              // the widest value it can show; sets the slot width
        property int level: 0
        property string align: "center"

        anchors.verticalCenter: parent.verticalCenter
        implicitWidth: Math.ceil(Math.max(pair.implicitWidth,
                                          icon.implicitWidth + pair.spacing + widestText.advanceWidth))
        implicitHeight: pair.implicitHeight

        Row {
            id: pair
            anchors.verticalCenter: parent.verticalCenter
            x: stat.align === "left" ? 0
             : stat.align === "right" ? stat.width - width
             : Math.round((stat.width - width) / 2)
            spacing: 6

            Label {
                id: icon
                anchors.verticalCenter: parent.verticalCenter
                text: stat.glyph
                color: stat.level > 0 ? Theme.urgent : Theme.fgDim
                font.pixelSize: Theme.iconSize
                Behavior on color { ColorAnimation { duration: Theme.fade } }
            }
            Label {
                id: valueLabel
                anchors.verticalCenter: parent.verticalCenter
                text: stat.value
                color: stat.level > 0 ? Theme.urgent : Theme.fg
                font.bold: stat.level === 2
                font.pixelSize: Theme.smallSize
                Behavior on color { ColorAnimation { duration: Theme.fade } }
            }
        }

        TextMetrics { id: widestText; font: valueLabel.font; text: stat.widest }
    }
}
