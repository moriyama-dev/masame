#!/usr/bin/env python3
"""Rasterize resources/icons/masame.svg into resources/icons/icon.inl (64x64 RGBA).

Only <rect> elements (with rx and fill) are supported, which is all the icon uses.
"""
import os
import re
import xml.etree.ElementTree as ET

SIZE = 64
SS = 4  # supersampling per axis

root = os.path.join(os.path.dirname(__file__), "..", "resources", "icons")
tree = ET.parse(os.path.join(root, "masame.svg"))
vb = [float(v) for v in tree.getroot().get("viewBox").split()]
scale = SIZE / vb[2]

rects = []
for el in tree.getroot():
    if not el.tag.endswith("rect"):
        continue
    f = lambda k: float(el.get(k, 0)) * scale
    color = el.get("fill").lstrip("#")
    rects.append((f("x"), f("y"), f("width"), f("height"), f("rx"),
                  tuple(int(color[i:i + 2], 16) for i in (0, 2, 4))))

def inside(px, py, x, y, w, h, r):
    if px < x or py < y or px > x + w or py > y + h:
        return False
    cx = min(max(px, x + r), x + w - r)
    cy = min(max(py, y + r), y + h - r)
    return (px - cx) ** 2 + (py - cy) ** 2 <= r * r

data = []
for j in range(SIZE):
    for i in range(SIZE):
        acc = [0.0, 0.0, 0.0, 0.0]  # premultiplied rgb + alpha
        for sj in range(SS):
            for si in range(SS):
                px, py = i + (si + 0.5) / SS, j + (sj + 0.5) / SS
                col = None
                for (x, y, w, h, r, c) in rects:
                    if inside(px, py, x, y, w, h, r):
                        col = c
                if col:
                    acc[0] += col[0]; acc[1] += col[1]; acc[2] += col[2]; acc[3] += 1
        n = SS * SS
        a = acc[3] / n
        if acc[3]:
            data += [round(acc[0] / acc[3]), round(acc[1] / acc[3]), round(acc[2] / acc[3]), round(a * 255)]
        else:
            data += [0, 0, 0, 0]

lines = ["static unsigned char icon_rgba[] = {"]
for k in range(0, len(data), 12):
    lines.append("  " + ", ".join("0x%02x" % b for b in data[k:k + 12]) + ",")
lines[-1] = lines[-1].rstrip(",")
lines.append("};")
lines.append("static unsigned int icon_rgba_len = %d;" % len(data))
with open(os.path.join(root, "icon.inl"), "w") as fp:
    fp.write("\n".join(lines) + "\n")
