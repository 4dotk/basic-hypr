// ---------------------------------------------------------
// BATTERY  — dropdown of the quick pill's battery icon.
//   level, state and time left / to full · battery health
//   Power mode: Saver / Balanced / Performance (accent on the active one)
// ---------------------------------------------------------

import QtQuick
import Quickshell.Services.UPower
import qs
import qs.services

Column {
    id: root

    width: Math.max(300, modes.implicitWidth + 20)   // wide enough for the mode chips
    spacing: 12

    // ---- level ----
    Row {
        x: 10
        spacing: 12
        BatteryIcon {
            anchors.verticalCenter: parent.verticalCenter
            level: Battery.level
            charging: Battery.charging
            color: Battery.low ? Theme.urgent : Theme.fg
            size: 30
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            Label {
                text: Math.round(Battery.level * 100) + "%"
                color: Battery.low ? Theme.urgent : Theme.fg
                font.pixelSize: 22
            }
            Label {
                text: Battery.stateText + (Battery.timeText !== "" ? " · " + Battery.timeText : "")
                color: Theme.fgDim
                font.pixelSize: Theme.smallSize
            }
        }
    }
    Label {
        x: 10
        visible: Battery.health >= 0
        text: Theme.glyph.health + "  Health " + Math.round(Battery.health) + "%"
        color: Theme.fgDim
        font.pixelSize: Theme.smallSize
    }

    // ---- power mode ----
    Heading { text: "Power mode"; width: root.width; topGap: true }
    Row {
        id: modes
        x: 10
        spacing: 6
        Chip {
            text: Theme.glyph.saver + "  Saver"
            on: Battery.profile === PowerProfile.PowerSaver
            onClicked: Battery.setProfile(PowerProfile.PowerSaver)
        }
        Chip {
            text: Theme.glyph.balanced + "  Balanced"
            on: Battery.profile === PowerProfile.Balanced
            onClicked: Battery.setProfile(PowerProfile.Balanced)
        }
        Chip {
            visible: Battery.hasPerformance
            text: Theme.glyph.perf + "  Performance"
            on: Battery.profile === PowerProfile.Performance
            onClicked: Battery.setProfile(PowerProfile.Performance)
        }
    }
}
