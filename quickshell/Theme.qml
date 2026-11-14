// ---------------------------------------------------------
// THEME  — colours, sizes, glyphs. Use anywhere as Theme.name (needs `import qs`).
// QML colours are #AARRGGBB — alpha comes FIRST (rofi puts it last).
//
// Colour themes: switch with  ~/.local/scripts/theme.sh [basic|vague]
// The choice lives in ~/.local/state/basic-hypr/theme (read at start);
// the script also tells the running bar (qs ipc call theme set <name>),
// so it recolours live. Keep the names in sync with rofi/dots/themes/.
// ---------------------------------------------------------
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var palettes: ({
        // Basic: the bar looks like an unfocused Hyprland window
        basic: {
            bg:       "#f2141415",   // pill background (kitty bg, 95%)
            bgAlt:    "#ff26262c",   // tracks, chips, surfaces
            selected: "#3311aaff",   // hover / highlight (accent, 20%)
            accent:   "#ff11aaff",   // active things (hypr active border)
            fg:       "#ffcdcdcd",   // main text (kitty fg)
            fgDim:    "#ff6a6a78",   // secondary text / icons
            line:     "#ff094f7c",   // pill borders (hypr inactive border)
            popup:    "#ff0b1a26",   // notification popups: solid, dark blue
            urgent:   "#ffe0a363"    // warnings (kitty amber)
        },
        // Vague: matches the kitty Vague colourscheme, very muted
        vague: {
            bg:       "#e6141415",
            bgAlt:    "#ff252530",
            selected: "#336e94b2",
            accent:   "#ff6e94b2",   // soft steel blue (kitty blue)
            fg:       "#ffcdcdcd",
            fgDim:    "#ff606079",
            line:     "#ff252530",
            popup:    "#ff131a20",   // notification popups: solid, dark slate
            urgent:   "#ffe0a363"
        }
    })

    // current theme name, from the state file (default: vague)
    property string name: (themeFile.text().trim() || "vague")
    readonly property var p: palettes[name] ?? palettes.vague

    FileView {
        id: themeFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/basic-hypr/theme"
        blockLoading: true
    }

    IpcHandler {
        target: "theme"
        function set(name: string): void { if (root.palettes[name]) root.name = name; }
        function get(): string { return root.name; }
    }

    // ---- colours (follow the current theme) ----
    readonly property color bg:       p.bg
    readonly property color bgAlt:    p.bgAlt
    readonly property color selected: p.selected
    readonly property color accent:   p.accent
    readonly property color fg:       p.fg
    readonly property color fgDim:    p.fgDim
    readonly property color line:     p.line
    readonly property color popup:    p.popup ?? Qt.rgba(p.bg.r, p.bg.g, p.bg.b, 1)   // solid surfaces over windows
    // Hyprland's window borders (hypr/dots/display.lua; keep in sync). Same in
    // every theme, like Hyprland's own. Used around notification popups.
    readonly property color windowBorder: "#eeaaddff"           // focused: light end of the gradient, rgba(aaddffee)
    readonly property color windowBorderInactive: "#ee094f7c"   // unfocused: rgba(094f7cee)
    readonly property color urgent:   p.urgent

    // ---- shape (matches hypr border_size / rounding) ----
    readonly property int border:   2
    readonly property int rounding: 14

    // ---- text ----
    readonly property string font:     "Hack Nerd Font"
    readonly property int    fontSize: 15          // pixels (~ rofi's 12pt)
    readonly property int    smallSize: 13
    readonly property int    iconSize: 17

    // ---- bar geometry ----
    readonly property int gap:        6            // space above the pills
    readonly property int gutter:     14           // space from the screen sides (= hypr gaps_out)
    readonly property int spacing:    8            // space between neighbouring pills
    readonly property int idleHeight: 34           // a resting pill; windows start below it
    readonly property int pad:        12           // inner padding

    // ---- motion ----
    readonly property int morph: 380               // ms for the size change
    readonly property int fade:  180               // ms for content cross-fades

    // ---- Nerd Font glyphs (codepoints checked against nerd-fonts glyphnames.json) ----
    readonly property var glyph: ({
        volHigh:    String.fromCodePoint(0xf057e),  // md-volume_high
        volMedium:  String.fromCodePoint(0xf0580),  // md-volume_medium
        volLow:     String.fromCodePoint(0xf057f),  // md-volume_low
        volOff:     String.fromCodePoint(0xf0581),  // md-volume_off
        brightness: String.fromCodePoint(0xf00e0),  // md-brightness_7
        play:       String.fromCodePoint(0xf040a),  // md-play
        pause:      String.fromCodePoint(0xf03e4),  // md-pause
        next:       String.fromCodePoint(0xf04ad),  // md-skip_next
        prev:       String.fromCodePoint(0xf04ae),  // md-skip_previous
        music:      String.fromCodePoint(0xf075a),  // md-music
        bell:       String.fromCodePoint(0xf009a),  // md-bell
        bellOff:    String.fromCodePoint(0xf009b),  // md-bell_off (do not disturb)
        timer:      String.fromCodePoint(0xf051f),  // md-timer_sand
        stopwatch:  String.fromCodePoint(0xf051b),  // md-timer_outline
        lap:        String.fromCodePoint(0xf023d),  // md-flag_outline
        left:       String.fromCodePoint(0xf0141),  // md-chevron_left
        right:      String.fromCodePoint(0xf0142),  // md-chevron_right
        reset:      String.fromCodePoint(0xf099b),  // md-restore
        plus:       String.fromCodePoint(0xf0415),  // md-plus
        cpu:        String.fromCodePoint(0xf0ee0),  // md-cpu_64_bit
        memory:     String.fromCodePoint(0xf035b),  // md-memory
        temp:       String.fromCodePoint(0xf050f),  // md-thermometer
        mic:        String.fromCodePoint(0xf036c),  // md-microphone
        micOff:     String.fromCodePoint(0xf036d),  // md-microphone_off
        speaker:    String.fromCodePoint(0xf04c3),  // md-speaker
        headphones: String.fromCodePoint(0xf02cb),  // md-headphones
        dot:        "\u25cf",                      // ● marks the default device
        app:        String.fromCodePoint(0xf08c6),  // md-application
        wifi1:      String.fromCodePoint(0xf091f),  // md-wifi_strength_1
        wifi2:      String.fromCodePoint(0xf0922),  // md-wifi_strength_2
        wifi3:      String.fromCodePoint(0xf0925),  // md-wifi_strength_3
        wifi4:      String.fromCodePoint(0xf0928),  // md-wifi_strength_4
        wifiNone:   String.fromCodePoint(0xf092f),  // md-wifi_strength_outline (on, not connected)
        wifiOff:    String.fromCodePoint(0xf092e),  // md-wifi_strength_off_outline
        ethernet:   String.fromCodePoint(0xf0200),  // md-ethernet
        lock:       String.fromCodePoint(0xf033e),  // md-lock (secured network)
        bt:         String.fromCodePoint(0xf00af),  // md-bluetooth
        btOff:      String.fromCodePoint(0xf00b2),  // md-bluetooth_off
        btOn:       String.fromCodePoint(0xf00b1),  // md-bluetooth_connect (a device is connected)
        mouse:      String.fromCodePoint(0xf037d),  // md-mouse
        keyboard:   String.fromCodePoint(0xf030c),  // md-keyboard
        phone:      String.fromCodePoint(0xf011c),  // md-cellphone
        device:     String.fromCodePoint(0xf0fb0),  // md-devices
        power:      String.fromCodePoint(0xf0425),  // md-power
        lockScreen: String.fromCodePoint(0xf0341),  // md-lock_outline
        logout:     String.fromCodePoint(0xf0343),  // md-logout
        sleep:      String.fromCodePoint(0xf04b2),  // md-sleep
        reboot:     String.fromCodePoint(0xf0709),  // md-restart
        saver:      String.fromCodePoint(0xf032a),  // md-leaf
        balanced:   String.fromCodePoint(0xf05d1),  // md-scale_balance
        perf:       String.fromCodePoint(0xf04c5),  // md-speedometer
        health:     String.fromCodePoint(0xf05f6),  // md-heart_pulse
        search:     String.fromCodePoint(0xf0349),  // md-magnify
        close:      String.fromCodePoint(0xf0156),  // md-close
        star:       String.fromCodePoint(0xf04ce),  // md-star
        starOff:    String.fromCodePoint(0xf04d2)   // md-star_outline
    })

    // battery glyphs, 0 % .. 100 % in steps of 10 (md-battery_outline, _10 … _90, md-battery)
    readonly property var batteryGlyphs: [0xf008e, 0xf007a, 0xf007b, 0xf007c, 0xf007d, 0xf007e,
                                          0xf007f, 0xf0080, 0xf0081, 0xf0082, 0xf0079]
    // charging: md-battery_charging_outline, _charging_10 … _charging_90, _charging_100
    readonly property var chargingGlyphs: [0xf089f, 0xf089c, 0xf0086, 0xf0087, 0xf0088, 0xf089d,
                                           0xf0089, 0xf089e, 0xf008a, 0xf008b, 0xf0085]

    // battery glyph for a level (0–1)
    function batteryGlyph(level, charging) {
        const i = Math.max(0, Math.min(10, Math.round(level * 10)));
        return String.fromCodePoint((charging ? chargingGlyphs : batteryGlyphs)[i]);
    }

    // ---- icon names (quickshell/icons/*.svg, shown with SvgIcon) ----
    function volumeIcon(level, muted) {
        if (muted || level <= 0) return "vol-off";
        if (level < 0.34) return "vol-low";
        if (level < 0.67) return "vol-medium";
        return "vol-high";
    }
    function wifiIcon(strength) {
        if (strength < 0.25) return "wifi-1";
        if (strength < 0.5)  return "wifi-2";
        if (strength < 0.75) return "wifi-3";
        return "wifi-4";
    }

    // wifi glyph for a signal strength (0–1)
    function wifiGlyph(strength) {
        if (strength < 0.25) return glyph.wifi1;
        if (strength < 0.5)  return glyph.wifi2;
        if (strength < 0.75) return glyph.wifi3;
        return glyph.wifi4;
    }

    // speaker glyph for a volume level (0–1): high / medium / low / off
    function volumeGlyph(level, muted) {
        if (muted || level <= 0) return glyph.volOff;
        if (level < 0.34) return glyph.volLow;
        if (level < 0.67) return glyph.volMedium;
        return glyph.volHigh;
    }
}
