// ---------------------------------------------------------
// BAR  — one per monitor: a full-width, invisible layer at the top that
// holds the pills.
//
//   [workspaces][stats]        [clock] [media]        [quick — phase 2]
//
// `mask` makes only the pills clickable; the empty rest of the strip
// lets clicks through to the windows below. Pills grow downward into
// panels inside this strip, so it is taller than the resting pills.
// Only one panel is open at a time (`open`); clicking anywhere outside
// the bar closes it.
//
// SUPER + F hides the bar (services/BarState.qml): the pills pop out left to
// right, the reserved strip goes away so tiled windows grow into it, and only
// the clock pill pops back in for the OSD / notifications.
// ---------------------------------------------------------

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs
import qs.services

PanelWindow {
    id: bar

    required property var modelData       // the screen, handed in by Variants
    screen: modelData

    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property bool focused: Hyprland.focusedMonitor === monitor

    property string open: ""              // "calendar", "clocks" or "" (later: quick tabs)
    readonly property bool hidden: BarState.hidden
    onHiddenChanged: if (hidden) open = ""

    // ---- the layer surface ----
    anchors { top: true; left: true; right: true }
    implicitHeight: 400                   // room for the tallest panel
    exclusiveZone: hidden ? 0 : Theme.gap + Theme.idleHeight   // tiled windows start below the resting pills
    color: "transparent"

    WlrLayershell.namespace: "quickshell-bar"   // used by the blur rule in hypr/dots/windows.lua
    WlrLayershell.layer: WlrLayer.Top
    // keyboard only while the timer panel is open (to type into hh:mm:ss)
    WlrLayershell.keyboardFocus: open === "clocks" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // only pills that are on screen are clickable
    mask: Region {
        Region { item: workspaces.visible ? workspaces : null }
        Region { item: stats.visible ? stats : null }
        Region { item: clock.visible ? clock : null }
        Region { item: media.visible ? media : null }
    }

    // while a panel is open, a click anywhere outside the bar closes it
    HyprlandFocusGrab {
        windows: [bar]
        active: bar.open !== ""
        onCleared: bar.open = ""
    }

    // qs ipc call panel toggle  -> timer / stopwatch on the focused monitor
    Connections {
        target: Panel
        function onToggle() { if (bar.focused && !bar.hidden) bar.open = bar.open ? "" : "clocks"; }
    }

    // ---- left ----
    WorkspacesPill {
        id: workspaces
        x: Theme.gutter
        monitor: bar.monitor
        shown: !bar.hidden
    }
    StatsPill {
        id: stats
        x: workspaces.x + workspaces.width + Theme.spacing
        shown: !bar.hidden
    }

    // ---- centre ----
    ClockPill {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        focused: bar.focused
        open: bar.open
        onRequest: panel => bar.open = (bar.open === panel ? "" : panel)
        // while hidden, only pops in for the OSD and notifications
        shown: !bar.hidden || mode === "osd" || mode === "notif"
    }

    // ---- right of the clock (moves next to the quick pill in phase 2) ----
    MediaPill {
        id: media
        x: bar.width - Theme.gutter - width
        hidden: bar.hidden
    }
}
