// ---------------------------------------------------------
// BRIDGE  — fills the gap between two neighbouring pills on an empty
// workspace, so the pills read as one full-width bar.
//
// Short gaps (the 8 px between neighbours): a plain join — the filler grows
// out of / shrinks into the middle of the gap (200 ms).
//
// Long gaps (either side of the clock): symbiote-inspired goo.
//   split (a window opens, `gooTime`: ~1.3 ms per px of gap, 300–700 ms;
//          `progress` 1 -> 0; tau = 1 - progress):
//     0.00–0.36  tear      the body sags and rips open in the middle
//     0.36–1.00  whip      the two stubs whip back into the pills (OutBack)
//                          while the pills' facing corners round
//   merge (the last window closes, `gooTime`, OutBack): the same played back —
//     stubs lash out, meet, and the body floods in and swells a little.
// Nothing animates while the bar is still.
//
// Fully joined it is a plain Rectangle (+ top / bottom border) on whole
// pixels, so it meets the pills with no seam. Each bridge drives the facing
// pills' joinLeft / joinRight.
// ---------------------------------------------------------

import QtQuick
import QtQuick.Shapes
import qs

Item {
    id: bridge

    property Item leftPill: null
    property Item rightPill: null
    property bool on: false
    property int delay: 0                 // ms before this gap moves (centre first)
    property Item backdrop: null          // the bar's shared fill layer: fills go there, solid

    property real progress: 0             // 1 = full bar, 0 = gone
    Component.onCompleted: progress = on ? 1 : 0

    // the gap, on whole pixels
    readonly property int a: leftPill ? Math.round(leftPill.x + leftPill.width) : 0
    readonly property int b: rightPill ? Math.round(rightPill.x) : 0
    readonly property bool longGap: width > 40
    readonly property bool shortGap: !longGap
    // long gaps play slower the longer they are: ~1.3 ms per px, 300–700 ms
    readonly property int gooTime: Math.round(Math.max(300, Math.min(700, width * 1.3)))

    x: a
    y: leftPill ? leftPill.y : Theme.gap
    width: Math.max(0, b - a)
    height: Theme.idleHeight
    opacity: leftPill ? leftPill.opacity : 1
    visible: width > 0 && progress > 0.001

    onOnChanged: {
        if (on) { split.stop(); merge.restart(); }
        else    { merge.stop(); split.restart(); }
    }
    SequentialAnimation {
        id: split
        PauseAnimation { duration: bridge.delay }
        NumberAnimation {
            target: bridge; property: "progress"; to: 0
            duration: bridge.longGap ? bridge.gooTime : 200
            easing.type: bridge.longGap ? Easing.Linear : Easing.OutCubic
        }
    }
    SequentialAnimation {
        id: merge
        PauseAnimation { duration: bridge.delay }
        NumberAnimation {
            target: bridge; property: "progress"; to: 1
            duration: bridge.longGap ? bridge.gooTime : 200
            easing.type: bridge.longGap ? Easing.OutBack : Easing.OutCubic
            easing.overshoot: 1.2
        }
    }

    // ---- timeline (long gaps) ----
    readonly property real tau: 1 - progress
    readonly property real whip: Math.max(0, Math.min(1, (tau - 0.36) / 0.64))   // stubs pull back

    // how joined the facing pill corners are
    readonly property real attach: shortGap ? Math.max(0, Math.min(1, progress)) : 1 - whip
    Binding { target: bridge.leftPill;  property: "joinRight"; value: bridge.attach; when: bridge.leftPill !== null }
    Binding { target: bridge.rightPill; property: "joinLeft";  value: bridge.attach; when: bridge.rightPill !== null }

    readonly property bool full: Math.abs(progress - 1) < 0.001

    // ---- full bar, and the short gaps' plain join: rectangles ----
    // the fill sits in the bar's backdrop layer (solid; the layer fades as a
    // whole), 1 px into each pill when full so the joins overlap with no seam
    readonly property real flatX: longGap ? 0 : Math.round(width * (1 - progress) / 2)
    readonly property real flatW: longGap ? width : width - 2 * flatX
    readonly property bool flatShown: full || shortGap
    Rectangle {
        parent: bridge.backdrop ?? bridge
        visible: bridge.visible && bridge.flatShown
        opacity: bridge.opacity
        readonly property real pad: bridge.full ? 1 : 0
        x: (bridge.backdrop ? bridge.x : 0) + bridge.flatX - pad
        y: bridge.backdrop ? bridge.y : 0
        width: bridge.flatW + 2 * pad
        height: bridge.height
        color: bridge.backdrop ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 1) : Theme.bg
    }
    Item {
        visible: bridge.flatShown
        x: bridge.flatX
        width: bridge.flatW
        height: bridge.height
        Rectangle { width: parent.width; height: Theme.border; color: Theme.line }
        Rectangle { y: parent.height - Theme.border; width: parent.width; height: Theme.border; color: Theme.line }
    }

    // ---- moving (long gaps): the goo body ----
    // the goo body's fill, in the backdrop layer like the rest
    Shape {
        parent: bridge.backdrop ?? bridge
        visible: bridge.visible && bridge.longGap && !bridge.full
        opacity: bridge.opacity
        x: bridge.backdrop ? bridge.x : 0
        y: bridge.backdrop ? bridge.y : 0
        width: bridge.width
        height: bridge.height
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillColor: bridge.backdrop ? Qt.rgba(Theme.bg.r, Theme.bg.g, Theme.bg.b, 1) : Theme.bg
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg { path: bridge.body(true) }
        }
    }
    Shape {
        visible: bridge.longGap && !bridge.full
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            fillColor: "transparent"
            strokeColor: Theme.line
            strokeWidth: Theme.border
            capStyle: ShapePath.FlatCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: bridge.body(false) }
        }
    }

    function outBack(u) {
        const c1 = 1.70158, c3 = c1 + 1;
        return 1 + c3 * Math.pow(u - 1, 3) + c1 * Math.pow(u - 1, 2);
    }

    // the body: a tearing waist, then two stubs hanging off the pills
    function body(fill) {
        const G = width, H = height, h = Theme.border / 2;
        if (G < 1) return "";
        const cy = H / 2, full = cy - h, t = tau;

        if (t < 0.36) {
            const k = Math.max(-0.08, t / 0.36);          // < 0: merge overshoot swells
            const half = full * (1 - k) * (1 - k), f = 0.3;
            const m = G / 2, yt = cy - half, yb = cy + half;
            const top = ` C ${G * f} ${h} ${m - G * f} ${yt} ${m} ${yt}`
                      + ` C ${m + G * f} ${yt} ${G - G * f} ${h} ${G} ${h}`;
            const bot = ` C ${G - G * f} ${H - h} ${m + G * f} ${yb} ${m} ${yb}`
                      + ` C ${m - G * f} ${yb} ${G * f} ${H - h} 0 ${H - h}`;
            return fill ? `M 0 ${h}` + top + ` L ${G} ${H - h}` + bot + " Z"
                        : `M 0 ${h}` + top + ` M ${G} ${H - h}` + bot;
        }
        // stubs: G/2 long when the tear opens, then whipped back in
        const L = Math.max(0, (G / 2) * (1 - outBack(whip)));
        const rc = Math.max(0, Theme.rounding - h) * (1 - attach);   // the pill's corner as it rounds
        const root = Math.max(0.5, full - rc);
        return stub(0, L, cy, root, fill) + stub(G, -L, cy, root, fill);
    }
    // a tapered stub from x0 (a pill edge) reaching L (negative = leftwards)
    function stub(x0, L, cy, root, fill) {
        if (Math.abs(L) < 0.5) return "";
        const tip = x0 + L;
        return `M ${x0} ${cy - root}`
             + ` C ${x0 + L * 0.5} ${cy - root} ${tip} ${cy - root * 0.45} ${tip} ${cy}`
             + ` C ${tip} ${cy + root * 0.45} ${x0 + L * 0.5} ${cy + root} ${x0} ${cy + root}`
             + (fill ? " Z" : "");
    }
}
