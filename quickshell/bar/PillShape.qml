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
// drawerHeight 0 = a plain rounded pill, same as a Rectangle.
// drawerGap > 0: the drawer is a separate rounded card that far below the
// head, no join.
// neck: where the drawer sticks out past the head, the head's side runs on
// this far below the head before curving out, so the drawer's top edge
// clears the neighbouring pills. drawerHeight includes it.
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
    property color stroke

    // the shape covers head and drawer together
    readonly property real minX:  Math.min(0, drawerX)
    readonly property real maxX: Math.max(headWidth, drawerX + drawerWidth)
    readonly property real dh: Math.max(0, drawerHeight)   // the morph overshoots below 0 when closing

    x: minX
    width: maxX - minX
    height: headHeight + (dh > 0 ? drawerGap : 0) + dh

    preferredRendererType: Shape.CurveRenderer   // antialiased edges without a multisample layer

    ShapePath {
        fillColor: root.fill
        strokeColor: root.stroke
        strokeWidth: root.border
        joinStyle: ShapePath.RoundJoin
        PathSvg { path: root.outline() }
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
        if (drawerGap > 0)                                 // separate card below
            return headRect + " " + rect(dl, headHeight + drawerGap + h, dr, headHeight + drawerGap + dh - h);

        const bottom = headHeight + dh - h;
        const rb = Math.min(r, dh / 2, (dr - dl) / 2);                    // drawer's bottom corners
        // the neck grows in with the drawer; jo = the join line where the drawer sticks out
        const n = Math.min(neck, dh / 3), jo = hb + n;
        // radius of a join: half the step between the edges, no more than r,
        // and no taller than the drawer is so far
        const join = step => Math.min(r, step / 2, (dh - n) / 2);

        let p = `M ${hl + r} ${top}` + L(hr - r, top) + a(r, 1, hr, top + r);

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
        p += L(hl, top + r) + a(r, 1, hl + r, top) + " Z";
        return p;
    }
}
