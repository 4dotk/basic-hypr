// ---------------------------------------------------------
// PILL SHAPE  — the outline of a pill plus the drawer hanging from it,
// drawn as ONE path so fill and border have no seam.
//
//   head    the resting pill: (0, 0) to (headWidth, headHeight)
//   drawer  below it: x = drawerX, width = drawerWidth, height = drawerHeight
//
// Where the drawer is wider than the head the join curves inward (a fillet);
// narrower, the head's corner rounds and the drawer's top curves in;
// edges that line up run straight. Every radius shrinks to fit the room,
// so the shape stays clean while the drawer grows from nothing.
// drawerHeight 0 = a plain rounded pill (its fill is a Rectangle).
// drawerGap > 0: the drawer is a separate rounded card that far below the
// head, no join; it is drawn with its own fill (`cardFill`).
// neck: where the drawer sticks out past the head, the head's side runs on
// this far below the head before curving out, so the drawer's top edge
// clears the neighbouring pills. drawerHeight includes it.
// joinLeft / joinRight (0–1): that side is joined to a bridge (bar/Bridge.qml)
// on an empty workspace. At 1 its corners are square, its side border is gone
// and the fill and top / bottom border run to the edge, so the pill and the
// bridge read as one bar. With a drawer open only the head's top corners square.
// ---------------------------------------------------------

import QtQuick
import QtQuick.Shapes

Shape {
    id: root

    property real headWidth
    property real headHeight
    property real drawerX
    property real drawerWidth
    property real drawerHeight
    property real drawerGap: 0
    property real neck: 0
    property real radius
    property real border
    property color fill
    property color cardFill: fill           // a detached card's fill (popups: opaque)
    property color cardStroke: stroke       // a detached card's border colour …
    property real cardBorder: border        // … and width
    property color stroke
    property real joinLeft: 0
    property real joinRight: 0
    // the bar's shared fill layer (Bar.qml `backdrop`) and the pill this shape
    // belongs to; with both set, the plain fill is drawn solid in that layer
    property Item backdrop: null
    property Item host: null
    readonly property bool layered: backdrop !== null && host !== null

    // no drawer joined to the head: drawn as a fill plus separate border pieces,
    // so a joined side can drop its border
    readonly property bool plain: dh < 0.5 || drawerGap > 0

    // the shape covers head and drawer together
    readonly property real minX:  Math.min(0, drawerX)
    readonly property real maxX: Math.max(headWidth, drawerX + drawerWidth)
    readonly property real dh: Math.max(0, drawerHeight)   // the morph overshoots below 0 when closing

    x: minX
    width: maxX - minX
    height: headHeight + (dh > 0 ? drawerGap : 0) + dh

    preferredRendererType: Shape.CurveRenderer   // antialiased edges without a multisample layer

    // plain head's fill: a Rectangle. Layered (the bar passes its backdrop), it
    // is solid and reparented into the bar's shared fill layer, which fades as
    // a whole to the theme's opacity; a joined side reaches 1 px into its
    // bridge. Solid fills overlapping inside one layer leave no seam at any
    // display scale (two see-through edges meeting between screen pixels do).
    // Otherwise it sits under this shape's border (z -1).
    Rectangle {
        parent: root.layered ? root.backdrop : root
        visible: root.plain && (!root.layered || root.host.visible)
        opacity: root.layered ? root.host.opacity : 1
        z: -1
        readonly property real padL: root.layered && root.joinLeft > 0.999 ? 1 : 0
        readonly property real padR: root.layered && root.joinRight > 0.999 ? 1 : 0
        x: (root.layered ? root.host.x : -root.minX) - padL
        y: root.layered ? root.host.y : 0
        width: root.headWidth + padL + padR
        height: root.headHeight
        color: root.layered ? Qt.rgba(root.fill.r, root.fill.g, root.fill.b, 1) : root.fill
        antialiasing: true
        readonly property real cap: Math.min(root.headWidth, root.headHeight) / 2
        topLeftRadius:     Math.min(cap, root.radius * (1 - root.joinLeft))
        bottomLeftRadius:  Math.min(cap, root.radius * (1 - root.joinLeft))
        topRightRadius:    Math.min(cap, root.radius * (1 - root.joinRight))
        bottomRightRadius: Math.min(cap, root.radius * (1 - root.joinRight))
    }
    // head + drawer as one path (only while a drawer is joined)
    ShapePath {
        fillColor: root.plain ? "transparent" : root.fill
        strokeColor: root.plain ? "transparent" : root.stroke
        strokeWidth: root.plain ? -1 : root.border
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: root.plain ? "" : root.outline() }
    }
    // plain head's border: top + bottom with their corners, then each side on its own
    ShapePath {
        fillColor: "transparent"
        strokeColor: root.stroke
        strokeWidth: root.border
        capStyle: ShapePath.FlatCap
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: root.plain ? root.headEdges() : "" }
    }
    ShapePath {
        fillColor: "transparent"
        strokeColor: Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, root.stroke.a * (1 - root.joinRight))
        strokeWidth: root.border
        capStyle: ShapePath.FlatCap
        PathSvg { path: root.plain ? root.headSide(true) : "" }
    }
    ShapePath {
        fillColor: "transparent"
        strokeColor: Qt.rgba(root.stroke.r, root.stroke.g, root.stroke.b, root.stroke.a * (1 - root.joinLeft))
        strokeWidth: root.border
        capStyle: ShapePath.FlatCap
        PathSvg { path: root.plain ? root.headSide(false) : "" }
    }

    // ---- plain head pieces ----
    // corner radii per side (0 when fully joined), clamped to the head's size
    function headRadii() {
        const h = border / 2;
        const r = Math.max(0, radius - h);
        const cap = Math.max(0, Math.min((headHeight - border) / 2, (headWidth - border) / 2));
        return { h: h, o: -minX,
                 l: Math.min(cap, r * (1 - joinLeft)), r: Math.min(cap, r * (1 - joinRight)) };
    }
    // top edge (with its corners) and bottom edge (with its corners), sides left out;
    // on a joined side the edges run half a border further, to meet the bridge's
    function headEdges() {
        const k = headRadii(), h = k.h;
        const xl = k.o + h, xr = k.o + headWidth - h, y1 = h, y2 = headHeight - h;
        if (xr - xl < 0.5) return "";
        const a = (rad, x, y) => ` A ${rad} ${rad} 0 0 1 ${x} ${y}`;
        const el = h * joinLeft * (k.l < 0.5 ? 1 : 0), er = h * joinRight * (k.r < 0.5 ? 1 : 0);
        return (k.l > 0 ? `M ${xl} ${y1 + k.l}` : `M ${xl - el} ${y1}`)
             + (k.l > 0 ? a(k.l, xl + k.l, y1) : "")
             + ` L ${xr - k.r + er} ${y1}` + (k.r > 0 ? a(k.r, xr, y1 + k.r) : "")
             + (k.r > 0 ? ` M ${xr} ${y2 - k.r}` + a(k.r, xr - k.r, y2) : ` M ${xr + er} ${y2}`)
             + ` L ${xl + k.l - el} ${y2}` + (k.l > 0 ? a(k.l, xl, y2 - k.l) : "");
    }
    // one side's straight part, between its corners
    function headSide(right) {
        const k = headRadii(), h = k.h;
        const x = right ? k.o + headWidth - h : k.o + h, rr = right ? k.r : k.l;
        const y1 = h + rr, y2 = headHeight - h - rr;
        return y2 - y1 < 0.5 ? "" : `M ${x} ${y1} L ${x} ${y2}`;
    }
    // a detached drawer: its own card, its own fill
    ShapePath {
        fillColor: root.cardFill
        strokeColor: root.cardStroke
        strokeWidth: root.cardBorder
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: root.card() }
    }

    function card() {
        if (drawerGap <= 0 || dh < 0.5) return "";
        const h = cardBorder / 2, o = -minX, r = Math.max(0, radius - h);
        const x1 = o + drawerX + h, x2 = o + drawerX + drawerWidth - h;
        const y1 = headHeight + drawerGap + h, y2 = headHeight + drawerGap + dh - h;
        const rr = Math.max(0, Math.min(r, (y2 - y1) / 2, (x2 - x1) / 2));
        const a = (x, y) => ` A ${rr} ${rr} 0 0 1 ${x} ${y}`;
        return `M ${x1 + rr} ${y1} L ${x2 - rr} ${y1}` + a(x2, y1 + rr)
             + ` L ${x2} ${y2 - rr}` + a(x2 - rr, y2)
             + ` L ${x1 + rr} ${y2}` + a(x1, y2 - rr)
             + ` L ${x1} ${y1 + rr}` + a(x1 + rr, y1) + " Z";
    }

    // SVG path, clockwise. The stroke is centred on the path, so the path runs
    // half a border inside the edges (like a Rectangle's border).
    function outline() {
        const h = border / 2, o = -minX;          // o: head x inside the shape
        const r = Math.max(0, radius - h);
        const hl = o + h, hr = o + headWidth - h; // head left / right
        const top = h, hb = headHeight;           // head top / bottom (the join line)
        const a = (rad, sweep, x, y) => ` A ${rad} ${rad} 0 0 ${sweep} ${x} ${y}`;
        const L = (x, y) => ` L ${x} ${y}`;

        // a plain rounded rectangle
        const rect = (x1, y1, x2, y2) => {
            const rr = Math.max(0, Math.min(r, (y2 - y1) / 2, (x2 - x1) / 2));
            return `M ${x1 + rr} ${y1}` + L(x2 - rr, y1) + a(rr, 1, x2, y1 + rr)
                 + L(x2, y2 - rr) + a(rr, 1, x2 - rr, y2)
                 + L(x1 + rr, y2) + a(rr, 1, x1, y2 - rr)
                 + L(x1, y1 + rr) + a(rr, 1, x1 + rr, y1) + " Z";
        };
        const dl = o + drawerX + h, dr = o + drawerX + drawerWidth - h;   // drawer left / right
        const headRect = rect(hl, top, hr, headHeight - h);

        if (dh < 0.5) return headRect;                     // no drawer
        if (drawerGap > 0) return headRect;                // separate card: drawn by card()

        const bottom = headHeight + dh - h;
        const rb = Math.min(r, dh / 2, (dr - dl) / 2);                    // drawer's bottom corners
        // the neck grows in with the drawer; jo = the join line where the drawer sticks out
        const n = Math.min(neck, dh / 3), jo = hb + n;
        // radius of a join: half the step between the edges, no more than r,
        // and no taller than the drawer is so far
        const join = step => Math.min(r, step / 2, (dh - n) / 2);

        // the head's top corners square on a joined side
        const tl = r * (1 - joinLeft), tr = r * (1 - joinRight);
        let p = `M ${hl + tl} ${top}` + L(hr - tr, top) + a(tr, 1, hr, top + tr);

        // right side, going down
        const sr = dr - hr;
        if (sr >= 1) {              // drawer sticks out: fillet out, then the drawer's corner
            const k = join(sr);
            p += L(hr, jo - k) + a(k, 0, hr + k, jo) + L(dr - k, jo) + a(k, 1, dr, jo + k);
        } else if (sr <= -1) {      // drawer tucked in: head's corner, then fillet down
            const k = join(-sr);
            p += L(hr, hb - k) + a(k, 1, hr - k, hb) + L(dr + k, hb) + a(k, 0, dr, hb + k);
        }                           // else flush: straight down
        p += L(dr, bottom - rb) + a(rb, 1, dr - rb, bottom);

        // bottom, then left side going up
        p += L(dl + rb, bottom) + a(rb, 1, dl, bottom - rb);
        const sl = hl - dl;
        if (sl >= 1) {
            const k = join(sl);
            p += L(dl, jo + k) + a(k, 1, dl + k, jo) + L(hl - k, jo) + a(k, 0, hl, jo - k);
        } else if (sl <= -1) {
            const k = join(-sl);
            p += L(dl, hb + k) + a(k, 0, dl - k, hb) + L(hl + k, hb) + a(k, 1, hl, hb - k);
        }
        p += L(hl, top + tl) + a(tl, 1, hl + tl, top) + " Z";
        return p;
    }
}
