#!/usr/bin/env python3
"""Rasterize resources/icons/masame.svg into the icon files used by the builds:

- resources/icons/icon.inl  64x64 RGBA for the window icon (Linux)
- resources/icons/icon.ico  Windows executable and installer icon
- resources/icons/icon.icns macOS application icon

Only <rect> elements (with rx and fill) are supported, which is all the icon uses.
"""
import os
import struct
import xml.etree.ElementTree as ET
import zlib

ROOT = os.path.join(os.path.dirname(__file__), "..", "resources", "icons")

tree = ET.parse(os.path.join(ROOT, "masame.svg"))
VIEWBOX = float(tree.getroot().get("viewBox").split()[2])
RECTS = []
for el in tree.getroot():
    if el.tag.endswith("rect"):
        color = el.get("fill").lstrip("#")
        RECTS.append(tuple(float(el.get(k, 0)) for k in ("x", "y", "width", "height", "rx"))
                     + (tuple(int(color[i:i + 2], 16) for i in (0, 2, 4)),))


def inside(px, py, x, y, w, h, r):
    if px < x or py < y or px > x + w or py > y + h:
        return False
    cx = min(max(px, x + r), x + w - r)
    cy = min(max(py, y + r), y + h - r)
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r


def render(size):
    """Returns RGBA bytes (not premultiplied) for a size x size image."""
    ss = 4 if size <= 64 else 2
    scale = VIEWBOX / size
    out = bytearray()
    for j in range(size):
        for i in range(size):
            r = g = b = n = 0
            for sj in range(ss):
                for si in range(ss):
                    px = (i + (si + 0.5) / ss) * scale
                    py = (j + (sj + 0.5) / ss) * scale
                    col = None
                    for (x, y, w, h, rx, c) in RECTS:
                        if inside(px, py, x, y, w, h, rx):
                            col = c
                    if col:
                        r += col[0]; g += col[1]; b += col[2]; n += 1
            if n:
                out += bytes((round(r / n), round(g / n), round(b / n), round(n * 255 / (ss * ss))))
            else:
                out += b"\0\0\0\0"
    return bytes(out)


def png(size, rgba):
    raw = b"".join(b"\0" + rgba[y * size * 4:(y + 1) * size * 4] for y in range(size))
    def chunk(t, d):
        return struct.pack(">I", len(d)) + t + d + struct.pack(">I", zlib.crc32(t + d) & 0xffffffff)
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


cache = {}
def image(size):
    if size not in cache:
        cache[size] = render(size)
    return cache[size]


# Window icon
data = image(64)
lines = ["static unsigned char icon_rgba[] = {"]
for k in range(0, len(data), 12):
    lines.append("  " + ", ".join("0x%02x" % v for v in data[k:k + 12]) + ",")
lines[-1] = lines[-1].rstrip(",")
lines += ["};", "static unsigned int icon_rgba_len = %d;" % len(data)]
with open(os.path.join(ROOT, "icon.inl"), "w") as fp:
    fp.write("\n".join(lines) + "\n")

# Windows .ico with PNG entries
sizes = [16, 24, 32, 48, 64, 128, 256]
pngs = [png(s, image(s)) for s in sizes]
ico = struct.pack("<HHH", 0, 1, len(sizes))
offset = 6 + 16 * len(sizes)
for s, p in zip(sizes, pngs):
    ico += struct.pack("<BBBBHHII", s % 256, s % 256, 0, 0, 1, 32, len(p), offset)
    offset += len(p)
with open(os.path.join(ROOT, "icon.ico"), "wb") as fp:
    fp.write(ico + b"".join(pngs))

# macOS .icns with PNG entries
types = [(b"icp4", 16), (b"icp5", 32), (b"icp6", 64), (b"ic07", 128), (b"ic08", 256),
         (b"ic09", 512), (b"ic10", 1024), (b"ic11", 32), (b"ic12", 64), (b"ic13", 256), (b"ic14", 512)]
body = b""
for t, s in types:
    p = png(s, image(s))
    body += t + struct.pack(">I", len(p) + 8) + p
with open(os.path.join(ROOT, "icon.icns"), "wb") as fp:
    fp.write(b"icns" + struct.pack(">I", len(body) + 8) + body)
