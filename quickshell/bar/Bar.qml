// ---------------------------------------------------------
// BAR  — one per monitor: a full-width, invisible layer at the top that
// holds the pills.
//
//   [workspaces][stats]        [clock]        [media][quick][bell]
//
// `mask` makes only the pills clickable; the empty rest of the strip
// lets clicks through to the windows below. Panels slide out under their
// pill as drawers (bar/Pill.qml) inside this strip, so it is taller than
// the resting pills.
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

    property string open: ""              // "calendar", "clocks", a quick-pill dropdown ("network", "sound", …) or ""
    readonly property bool hidden: BarState.hidden
    onHiddenChanged: if (hidden) open = ""

    // ---- the layer surface ----
    anchors { top: true; left: true; right: true }
    implicitHeight: 540                   // room for the tallest panel (6-week calendar)
    exclusiveZone: hidden ? 0 : Theme.gap + Theme.idleHeight   // tiled windows start below the resting pills
    color: "transparent"

    WlrLayershell.namespace: "quickshell-bar"   // used by the blur rule in hypr/dots/windows.lua
    WlrLayershell.layer: WlrLayer.Top
    // keyboard only while the timer panel (hh:mm:ss) or the network list (Wi-Fi password) is open
    WlrLayershell.keyboardFocus: open === "clocks" || open === "network" ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    // only pills that are on screen are clickable
    mask: Region {
        Region { item: workspaces.visible ? workspaces : null }
        Region { item: stats.visible ? stats : null }
        Region { item: clock.visible ? clock : null }
        Region { item: clock.visible ? clock.drawerBox : null }
        Region { item: media.visible ? media : null }
        Region { item: quick.visible ? quick : null }
        Region { item: quick.visible ? quick.drawerBox : null }
        Region { item: notif.visible ? notif : null }
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
        function onOpenPanel(name) { if (bar.focused && !bar.hidden) bar.open = bar.open === name ? "" : name; }
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
        shown: !bar.hidden || mode === "osd" || under === "notif"
    }

    // ---- right: media, quick settings, then the bell at the edge ----
    MediaPill {
        id: media
        x: quick.x - Theme.spacing - width
        hidden: bar.hidden
    }
    QuickPill {
        id: quick
        x: notif.x - Theme.spacing - width
        shown: !bar.hidden
        open: bar.open
        onRequest: panel => bar.open = (bar.open === panel ? "" : panel)
    }
    NotifPill {
        id: notif
        x: bar.width - Theme.gutter - width
        shown: !bar.hidden
    }
}
