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
        timer:      String.fromCodePoint(0xf051f),  // md-timer_sand
        stopwatch:  String.fromCodePoint(0xf006b),  // md-av_timer
        lap:        String.fromCodePoint(0xf023d),  // md-flag_outline
        left:       String.fromCodePoint(0xf0141),  // md-chevron_left
        right:      String.fromCodePoint(0xf0142),  // md-chevron_right
        reset:      String.fromCodePoint(0xf099b),  // md-restore
        plus:       String.fromCodePoint(0xf0415),  // md-plus
        cpu:        String.fromCodePoint(0xf0ee0),  // md-cpu_64_bit
        memory:     String.fromCodePoint(0xf035b),  // md-memory
        temp:       String.fromCodePoint(0xf050f)   // md-thermometer
    })
}
