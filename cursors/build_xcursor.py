"""Rebuild the XCursor (+ Plasma scalable) part of the Robot theme.

Only needed if you change the spinner in Robot/hyprcursors - the repo already
ships the built files. Base = Breeze_Light (package: breeze-cursor-theme),
wait/progress = the Robot spinner frames from Robot/hyprcursors.

    python3 build_xcursor.py /tmp/Robot-new      # build into an empty folder
    # check it, then replace Robot/cursors, Robot/cursors_scalable, Robot/index.theme

Needs: python3-gobject (Rsvg), python3-cairo.
"""
import json, os, shutil, struct, sys, zipfile
import gi
gi.require_version("Rsvg", "2.0")
from gi.repository import Rsvg
import cairo

BASE = "/usr/share/icons/Breeze_Light"
ROBOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "Robot")  # next to this script
if len(sys.argv) != 2:
    sys.exit(__doc__)
OUT = sys.argv[1]
SIZES = range(16, 97, 8)  # same sizes Breeze ships
DELAY = 45                # ms, from hyprcursor meta.hl
SPIN = ("wait", "progress")


def frames(shape):
    with zipfile.ZipFile(os.path.join(ROBOT, "hyprcursors", f"{shape}.hlc")) as z:
        names = sorted(n for n in z.namelist() if n.endswith(".svg"))
        return [z.read(n) for n in names]


def render(svg, size):
    surf = cairo.ImageSurface(cairo.FORMAT_ARGB32, size, size)
    h = Rsvg.Handle.new_from_data(svg)
    vp = Rsvg.Rectangle(); vp.x = vp.y = 0; vp.width = vp.height = size
    h.render_document(cairo.Context(surf), vp)
    surf.flush()
    assert surf.get_stride() == size * 4
    return bytes(surf.get_data())  # premultiplied ARGB, native (LE) = xcursor format


def write_xcursor(path, svgs):
    imgs = []
    for size in SIZES:
        for svg in svgs:
            imgs.append((size, render(svg, size)))
    ntoc = len(imgs)
    pos = 16 + 12 * ntoc
    toc, chunks = b"", b""
    for size, px in imgs:
        toc += struct.pack("<III", 0xFFFD0002, size, pos)
        c = struct.pack("<IIIIIIIII", 36, 0xFFFD0002, size, 1, size, size,
                        size // 2, size // 2, DELAY) + px
        chunks += c
        pos += len(c)
    with open(path, "wb") as f:
        f.write(struct.pack("<4sIII", b"Xcur", 16, 0x10000, ntoc) + toc + chunks)


def write_scalable(dirpath, shape, svgs):
    os.makedirs(dirpath)
    meta = []
    for i, svg in enumerate(svgs, 1):
        # Breeze convention: 32px canvas at nominal 24 -> keep the same proportion
        text = svg.decode().replace('width="24" height="24"', 'width="32" height="32"', 1)
        name = f"{shape}-{i:02d}.svg"
        with open(os.path.join(dirpath, name), "w") as f:
            f.write(text)
        meta.append({"filename": name, "delay": DELAY, "hotspot_x": 16,
                     "hotspot_y": 16, "nominal_size": 24})
    with open(os.path.join(dirpath, "metadata.json"), "w") as f:
        json.dump(meta, f, indent=4)


if os.path.exists(OUT):
    sys.exit(f"{OUT} exists")
os.makedirs(OUT)
for sub in ("cursors", "cursors_scalable"):
    shutil.copytree(os.path.join(BASE, sub), os.path.join(OUT, sub), symlinks=True)
for shape in SPIN:
    svgs = frames(shape)
    os.remove(os.path.join(OUT, "cursors", shape))
    write_xcursor(os.path.join(OUT, "cursors", shape), svgs)
    shutil.rmtree(os.path.join(OUT, "cursors_scalable", shape))
    write_scalable(os.path.join(OUT, "cursors_scalable", shape), shape, svgs)
    print(f"{shape}: {len(svgs)} frames x {len(SIZES)} sizes")
with open(os.path.join(OUT, "index.theme"), "w") as f:
    f.write("[Icon Theme]\nName=Robot\n"
            "Comment=Breeze Light with the Robot steel-blue ring spinner\n"
            "Inherits=Breeze_Light\n")
