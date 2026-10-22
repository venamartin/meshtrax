"""Draws the map symbols and packs them into one sprite sheet per palette:
assets/sprites/light@2x.png/.json and dark@2x.png/.json (MapLibre sprite
format). Rerun after editing a symbol or a palette:

    python3 tool/make_sprites.py assets/sprites

Needs rsvg-convert (librsvg2-bin). Light styles use the light
sheet and dark styles the dark one; both hold the same names.

Symbols follow US Chart No. 1 (buoys lean, a small circle marks the
position), simplified to read on a phone. Each family shares one box and
one position point, so a layer can pick any name in the family with an
expression and still sit on the feature: see layout() for the style side.
"""
import json
import math
import os
import subprocess
import sys

RATIO = 2
GUTTER = 2  # logical px between symbols, so filtering never reaches a neighbour
SHEET_WIDTH = 256  # logical px

# OSM peak colours (make_styles.py MODERN and DARK "peak").
PEAK = {"light": "#7a5a3a", "dark": "#d8b98a"}
# Wrecks and other hazards keep the colours the circles had.
HAZARD = {"light": {"ink": "#222222", "wreck": "#7a1f5c"},
          "dark": {"ink": "#e0e0e0", "wreck": "#e05aa8"}}

# Buoy, beacon and daymark fills: S-57 colours (top to bottom for bands) and
# pattern. The style maps a feature's `colours` and `colour_pattern` to one
# of these, and anything else to its first colour.
SOLID = ["red", "green", "yellow", "white", "black", "orange", "other"]
SCHEMES = {
    "grg": (["green", "red", "green"], "horizontal_stripes"),
    "rgr": (["red", "green", "red"], "horizontal_stripes"),
    "brb": (["black", "red", "black"], "horizontal_stripes"),
    "by": (["black", "yellow"], "horizontal_stripes"),
    "yb": (["yellow", "black"], "horizontal_stripes"),
    "byb": (["black", "yellow", "black"], "horizontal_stripes"),
    "yby": (["yellow", "black", "yellow"], "horizontal_stripes"),
    "wo": (["white", "orange"], "horizontal_stripes"),
    "wow": (["white", "orange", "white"], "horizontal_stripes"),
    "rw": (["red", "white"], "horizontal_stripes"),
    "wr": (["white", "red"], "horizontal_stripes"),
    "rwv": (["red", "white"], "vertical_stripes"),
}
SCHEMES.update({c: ([c], None) for c in SOLID})

BUOY_SHAPES = ["conical", "can", "spherical", "pillar", "spar", "barrel"]
DAY_SHAPES = ["square", "triangle", "rhombus"]
TOPMARKS = ["cone_point_up", "cone_point_down", "two_cones_up", "two_cones_down",
            "two_cones_point_to_point", "two_cones_base_to_base", "sphere", "two_spheres",
            "x_shape", "upright_cross", "cylinder", "square", "rhombus",
            "triangle_point_up", "triangle_point_down", "flag"]
LANDMARKS = ["generic", "tower", "windmotor", "chimney", "mast", "church", "flagstaff", "dome"]

# (box width, box height, x, y of the point drawn around) in logical px.
FAMILIES = {
    "buoy": (16, 18, 7, 15),
    "day": (12, 12, 6, 6),
    "beacon": (12, 17, 6, 14),
    "top": (10, 12, 5, 12),
    "light": (15, 15, 1.5, 13.5),
    "hazard": (18, 18, 9, 9),
    "anchor": (18, 18, 9, 9),
    "arrow": (12, 26, 6, 13),
    "landmark": (14, 18, 7, 15),
    "peak": (11, 10, 5.5, 5),
}
# Where that point goes relative to the feature, when it isn't on it:
# topmarks sit above the buoy or beacon they belong to.
SHIFT = {"top": (3, -14)}
LEAN = 15  # degrees, as on US charts


def layout(family):
    """The style's icon-anchor and icon-offset that put a family's point on
    the feature (or SHIFT from it), at any icon-size and rotation."""
    _, _, x, y = FAMILIES[family]
    dx, dy = SHIFT.get(family, (0, 0))
    return {"icon-anchor": "top-left", "icon-offset": [dx - x, dy - y]}


def palette(name):
    # Here, not at the top: make_chart_layers imports this module's tables.
    from make_chart_layers import DARK, LIGHT
    P = LIGHT if name == "light" else DARK
    day = dict(P["day"])
    return {
        "name": name, "day": day, "magenta": P["magenta"], "ink": P["ink"], "halo": P["halo"],
        "water": P["water_text"], "edge": "#222222" if name == "light" else "#0c1e30",
        # The position circle: hollow on light charts, ringed in ink on dark ones.
        "pos_fill": "#ffffff" if name == "light" else "#0c1e30",
        "pos_stroke": "#222222" if name == "light" else P["ink"],
        "peak": PEAK[name], **HAZARD[name],
    }


# --- buoys, beacons and daymarks -------------------------------------------

def buoy_body(shape):
    """Upright outline with its base centred on the origin (y up is
    negative), and its width and height, which the stripes and bands divide."""
    return {
        "conical": ("M-4.5,0 L0,-13 L4.5,0 Z", 9, 13),
        "can": ("M-4,0 L-4,-10 L4,-10 L4,0 Z", 8, 10),
        "spherical": ("M-5,0 A5,5 0 0 1 5,0 Z", 10, 5),
        "pillar": ("M-4,0 L-1.6,-14 L1.6,-14 L4,0 Z", 8, 14),
        "spar": ("M-1.4,0 L-1.4,-14 L1.4,-14 L1.4,0 Z", 2.8, 14),
        "barrel": ("M-5,0 C-6.6,-1 -6.6,-5.5 -5,-6.5 L5,-6.5 C6.6,-5.5 6.6,-1 5,0 Z", 13, 6.5),
    }[shape]


def day_body(shape):
    return {
        "square": "M-3.8,-3.8 L3.8,-3.8 L3.8,3.8 L-3.8,3.8 Z",
        "triangle": "M-4.6,3.6 L0,-4.4 L4.6,3.6 Z",
        "rhombus": "M0,-5 L4,0 L0,5 L-4,0 Z",
    }[shape]


def filled(d, scheme, P, box, clip_id):
    """Path d filled with a scheme's colours, outlined. box = (x0, y0, x1, y1)
    of the shape in its own frame, for the bands."""
    colours, pattern = SCHEMES[scheme]
    fills = [P["day"][c] if c in P["day"] else P["day"]["other"] for c in colours]
    x0, y0, x1, y1 = box
    out = [f'<clipPath id="{clip_id}"><path d="{d}"/></clipPath>']
    if pattern == "horizontal_stripes":
        h = (y1 - y0) / len(fills)
        for i, f in enumerate(fills):
            out.append(f'<rect x="{x0}" y="{y0 + i * h:.3f}" width="{x1 - x0}" height="{h + 0.05:.3f}" '
                       f'fill="{f}" clip-path="url(#{clip_id})"/>')
    elif pattern == "vertical_stripes":
        stripes = fills * 2 if len(fills) == 2 else fills
        w = (x1 - x0) / len(stripes)
        for i, f in enumerate(stripes):
            out.append(f'<rect x="{x0 + i * w:.3f}" y="{y0}" width="{w + 0.05:.3f}" height="{y1 - y0}" '
                       f'fill="{f}" clip-path="url(#{clip_id})"/>')
    else:
        out.append(f'<path d="{d}" fill="{fills[0]}"/>')
    out.append(f'<path d="{d}" fill="none" stroke="{P["edge"]}" stroke-width="1" stroke-linejoin="round"/>')
    return "".join(out)


def position_circle(P, r=1.8):
    return (f'<circle r="{r}" fill="{P["pos_fill"]}" stroke="{P["pos_stroke"]}" '
            f'stroke-width="0.9"/>')


def buoy(shape, scheme, P, lean=LEAN, uid=""):
    d, width, height = buoy_body(shape)
    body = filled(d, scheme, P, (-width / 2, -height, width / 2, 0), f"b{uid}")
    return f'<g transform="rotate({lean})">{body}</g>{position_circle(P)}'


def day(shape, scheme, P, uid=""):
    return filled(day_body(shape), scheme, P, (-5, -5, 5, 5), f"d{uid}")


# --- line symbols drawn twice: a halo, then the ink ----------------------------

def stroked(paths, colour, P, width=1.2, dots=(), fill_paths=()):
    """Line art with a halo underneath. paths: SVG path data stroked in colour;
    dots: (x, y, r) filled; fill_paths: path data filled in colour."""
    out = []
    for c, extra in ((P["halo"], 2), (colour, 0)):
        for d in fill_paths:
            out.append(f'<path d="{d}" fill="{c}" stroke="{c}" stroke-width="{extra or 0.01}" '
                       f'stroke-linejoin="round"/>')
        for d in paths:
            out.append(f'<path d="{d}" fill="none" stroke="{c}" stroke-width="{width + extra}" '
                       f'stroke-linecap="round" stroke-linejoin="round"/>')
        for x, y, r in dots:
            out.append(f'<circle cx="{x}" cy="{y}" r="{r + extra / 2}" fill="{c}"/>')
    return "".join(out)


def beacon(shape, P):
    if shape == "tower":
        parts = ["M-2.6,-1.6 L-1.3,-12 L1.3,-12 L2.6,-1.6"]
    else:  # lattice
        parts = ["M-3,-1.6 L-1.3,-12 L1.3,-12 L3,-1.6", "M-2.6,-4.6 L1.9,-8.6 M2.6,-4.6 L-1.9,-8.6",
                 "M-1.9,-8.6 L1.9,-8.6 M-2.6,-4.6 L2.6,-4.6"]
    return stroked(parts, P["ink"], P, width=1) + position_circle(P)


def topmark(shape, P):
    """Solid figures in ink, drawn upright with their base on the origin."""
    cone_up = lambda y: f"M-3,{y} L0,{y - 4} L3,{y} Z"
    cone_down = lambda y: f"M-3,{y - 4} L3,{y - 4} L0,{y} Z"
    sphere = lambda y: f"M-2.2,{y - 2.2} a2.2,2.2 0 1 0 4.4,0 a2.2,2.2 0 1 0 -4.4,0 Z"
    fills = {
        "cone_point_up": [cone_up(0)],
        "cone_point_down": [cone_down(0)],
        "two_cones_up": [cone_up(-5), cone_up(0)],
        "two_cones_down": [cone_down(-5), cone_down(0)],
        "two_cones_point_to_point": [cone_down(-5), cone_up(0)],
        "two_cones_base_to_base": [cone_up(-5), cone_down(0)],
        "sphere": [sphere(0)],
        "two_spheres": [sphere(-5), sphere(0)],
        "cylinder": ["M-2.4,0 L-2.4,-5 L2.4,-5 L2.4,0 Z"],
        "square": ["M-2.6,0 L-2.6,-5.2 L2.6,-5.2 L2.6,0 Z"],
        "rhombus": ["M0,0 L2.8,-3.2 L0,-6.4 L-2.8,-3.2 Z"],
        "triangle_point_up": [cone_up(0)],
        "triangle_point_down": [cone_down(0)],
        "flag": ["M-1.5,-3 L-1.5,-7 L2.8,-5.8 Z"],
    }
    strokes = {
        "x_shape": ["M-2.6,-5.2 L2.6,0 M2.6,-5.2 L-2.6,0"],
        "upright_cross": ["M0,-6 L0,0 M-2.8,-3.6 L2.8,-3.6"],
        "flag": ["M-1.5,0 L-1.5,-7"],
    }
    return stroked(strokes.get(shape, []), P["ink"], P, width=1.1, fill_paths=fills.get(shape, []))


# --- lights, hazards, regulated areas, routes, landmarks ---------------------

def flare(colour, P):
    """Light flare: a teardrop from the position towards the north-east,
    long enough to clear the buoy it is drawn under."""
    d = "M0,0 C0.7,-4 2.5,-10 2.5,-13.2 A2.5,2.5 0 0 0 -2.5,-13.2 C-2.5,-10 -0.7,-4 0,0 Z"
    return (f'<g transform="rotate(45)"><path d="{d}" fill="{colour}" stroke="{P["edge"]}" '
            f'stroke-width="0.6" stroke-opacity="0.7"/></g>')


DOTTED_CIRCLE = [(6.6 * math.cos(a * math.pi / 7), 6.6 * math.sin(a * math.pi / 7), 0.55)
                 for a in range(14)]
WRECK = ["M-5.5,0 L5.5,0", "M-2.6,-2.2 L-2.6,2.2 M0,-2.6 L0,2.6 M2.6,-2.2 L2.6,2.2"]


def hazard(kind, P):
    ink, wreck = P["ink"], P["wreck"]
    if kind == "rock":  # underwater, depth unknown
        return stroked(["M-3.6,0 L3.6,0 M0,-3.6 L0,3.6"], ink, P, width=1.3)
    if kind == "rock-awash":
        return stroked(["M-3.6,0 L3.6,0 M0,-3.6 L0,3.6"], ink, P, width=1.3,
                       dots=[(2.4, 2.4, 0.8), (-2.4, 2.4, 0.8), (2.4, -2.4, 0.8), (-2.4, -2.4, 0.8)])
    if kind == "rock-covers":
        arms = " ".join(f"M{-3.8 * math.cos(a):.2f},{-3.8 * math.sin(a):.2f} "
                        f"L{3.8 * math.cos(a):.2f},{3.8 * math.sin(a):.2f}"
                        for a in (math.pi / 2, math.pi / 6, -math.pi / 6))
        return stroked([arms], ink, P, width=1.2)
    if kind == "wreck-dangerous":
        return (stroked([], wreck, P, dots=DOTTED_CIRCLE) +
                f'<g transform="scale(0.8)">{stroked(WRECK, wreck, P, width=1.4)}</g>')
    if kind == "wreck":
        return stroked(WRECK, wreck, P, width=1.2)
    if kind == "wreck-hull":
        return stroked([], wreck, P, fill_paths=["M-6,-0.5 L6,-0.5 L4,2.6 L-4.5,2.6 Z",
                                                  "M-1,-0.5 L-1,-2.6 L2.4,-2.6 L2.4,-0.5 Z"])
    if kind == "obstruction":
        return stroked([], ink, P, dots=DOTTED_CIRCLE)
    if kind == "foul":
        return stroked(["M-1.6,-4 L-1.6,4 M1.6,-4 L1.6,4 M-4,-1.6 L4,-1.6 M-4,1.6 L4,1.6"], ink, P,
                       width=1)
    raise ValueError(kind)


ANCHOR = ["M0,-3.4 L0,4.6", "M-2.8,-2.4 L2.8,-2.4", "M-4.2,1.4 Q-3.4,4.8 0,4.8 Q3.4,4.8 4.2,1.4",
          "M-4.9,2.4 L-4.2,1.4 L-3.1,1.8 M4.9,2.4 L4.2,1.4 L3.1,1.8"]
ANCHOR_RING = "M-1.2,-4.6 a1.2,1.2 0 1 0 2.4,0 a1.2,1.2 0 1 0 -2.4,0"


def regulated(kind, P):
    m = P["magenta"]
    if kind == "anchor":
        return stroked([*ANCHOR, ANCHOR_RING], m, P, width=1.2)
    if kind == "no-anchoring":
        return stroked([*ANCHOR, ANCHOR_RING, "M-5.5,5.5 L5.5,-5.5"], m, P, width=1.2)
    if kind == "anchor-berth":
        circle = "M-7.5,0 a7.5,7.5 0 1 0 15,0 a7.5,7.5 0 1 0 -15,0"
        return (stroked([circle], m, P, width=1) +
                f'<g transform="scale(0.8)">{stroked([*ANCHOR, ANCHOR_RING], m, P, width=1.3)}</g>')
    if kind == "caution":
        return stroked(["M0,-6.5 L6.6,5 L-6.6,5 Z", "M0,-2.4 L0,1.2"], m, P, width=1.2,
                       dots=[(0, 3.1, 0.8)])
    raise ValueError(kind)


def arrow(kind, P):
    """Pointing north, centred on the position, so icon-rotate is the bearing."""
    if kind == "lane":
        d = "M0,-12 L4.8,-4.5 L1.9,-4.5 L1.9,12 L-1.9,12 L-1.9,-4.5 L-4.8,-4.5 Z"
        return (stroked([d], P["magenta"], P, width=1) +
                f'<path d="{d}" fill="{P["magenta"]}" fill-opacity="0.18"/>')
    head = "M-3,-6 L0,-10.5 L3,-6"
    w = P["water"]
    if kind == "flood":
        return stroked(["M0,-10 L0,10", head, "M0,4 L-2.6,7 M0,7 L-2.6,10"], w, P, width=1.1)
    if kind == "ebb":
        return stroked(["M0,-10 L0,10", head], w, P, width=1.1)
    if kind == "current":
        return stroked(["M0,-10 C2,-6 -2,-3 0,0 C2,3 -2,6 0,10", head], w, P, width=1.1)
    if kind == "turbulence":
        wave = lambda y: f"M-4.5,{y} q1.1,-1.6 2.25,0 t2.25,0 t2.25,0 t2.25,0"
        return stroked([wave(-3), wave(0), wave(3)], w, P, width=1)
    raise ValueError(kind)


def landmark(kind, P):
    ink = P["ink"]
    art = {
        "generic": ([], [(0, 0, 0.9)]),
        "tower": (["M-2.4,-2 L-1.2,-12 L1.2,-12 L2.4,-2 M-1.6,-8.5 L1.6,-8.5"], []),
        "windmotor": (["M0,-2 L0,-9.5", "M0,-9.5 L0,-14 M0,-9.5 L3.9,-7.2 M0,-9.5 L-3.9,-7.2"],
                      [(0, -9.5, 0.9)]),
        "chimney": (["M-1.5,-2 L-1.5,-10 L1.5,-10 L1.5,-2", "M0.4,-11.5 q1.8,-1.8 4.2,-1"], []),
        "mast": (["M0,-2 L0,-14", "M-2.4,-2 L0,-9 L2.4,-2"], []),
        "church": (["M0,-2 L0,-12 M-2.8,-8.5 L2.8,-8.5"], []),
        "flagstaff": (["M0,-2 L0,-13"], []),
        "dome": (["M-3.4,-2.6 A3.4,3.4 0 0 1 3.4,-2.6 Z M0,-6 L0,-8"], []),
    }
    paths, dots = art[kind]
    fills = ["M0,-13 L3.8,-11.6 L0,-10.2 Z"] if kind == "flagstaff" else []
    ring = "M-1.9,0 a1.9,1.9 0 1 0 3.8,0 a1.9,1.9 0 1 0 -3.8,0"
    return stroked([*paths, ring], ink, P, width=1, dots=dots, fill_paths=fills)


def peak(P):
    return stroked([], P["peak"], P, fill_paths=["M0,-3.4 L4,3.4 L-4,3.4 Z"])


# --- line patterns: stamped along a line, one sprite per repeat --------------
# MapLibre line-pattern scales the sprite's height to the line width, so the
# style sets line-width to the pattern's height.

PATTERNS = {"restricted": (16, 8), "cable": (12, 6)}


def pattern(kind, P):
    m = P["magenta"]
    if kind == "restricted":
        # A dash with a T-tick: the stem points to the line's right, which is
        # the inside of a polygon ring (MVT rings run clockwise on screen).
        return (f'<path d="M1,4 L11,4 M6,4 L6,7.5" stroke="{m}" stroke-width="1.2" '
                f'stroke-linecap="round" fill="none"/>')
    if kind == "cable":
        return (f'<path d="M0,3 q1.5,-2.4 3,0 t3,0 t3,0 t3,0" stroke="{m}" stroke-width="1" '
                f'fill="none"/>')
    raise ValueError(kind)


# --- the sheet ---------------------------------------------------------------

def symbols(P):
    """(name, family or None, width, height, svg drawn around the position)."""
    out = []

    def add(name, family, svg, size=None):
        w, h = size or FAMILIES[family][:2]
        out.append((name, family, w, h, svg))

    for shape in BUOY_SHAPES:
        for scheme in SCHEMES:
            add(f"buoy-{shape}-{scheme}", "buoy", buoy(shape, scheme, P, uid=f"{shape}{scheme}"))
    for shape in DAY_SHAPES:
        for scheme in SCHEMES:
            add(f"day-{shape}-{scheme}", "day", day(shape, scheme, P, uid=f"{shape}{scheme}"))
    for shape in ("tower", "lattice"):
        add(f"beacon-{shape}", "beacon", beacon(shape, P))
    for shape in TOPMARKS:
        add(f"top-{shape}", "top", topmark(shape, P))
    # Magenta whatever the light's colour, as on paper charts: it stands out
    # from the buoy it is on, and the label gives the colour (Martin).
    add("light", "light", flare(P["magenta"], P))
    for kind in ("rock", "rock-awash", "rock-covers", "wreck-dangerous", "wreck", "wreck-hull",
                 "obstruction", "foul"):
        add(f"hazard-{kind}", "hazard", hazard(kind, P))
    for kind in ("anchor", "no-anchoring", "anchor-berth", "caution"):
        add(kind, "anchor", regulated(kind, P))
    for kind in ("lane", "flood", "ebb", "current", "turbulence"):
        add(f"arrow-{kind}", "arrow", arrow(kind, P))
    for kind in LANDMARKS:
        add(f"landmark-{kind}", "landmark", landmark(kind, P))
    add("peak", "peak", peak(P))
    for kind, size in PATTERNS.items():
        add(f"pattern-{kind}", None, pattern(kind, P), size)
    return out


def pack(items):
    """Shelf packing, tallest first: {name: (x, y)} in logical px, and the sheet size."""
    order = sorted(items, key=lambda s: (-s[3], -s[2], s[0]))
    pos, x, y, row = {}, GUTTER, GUTTER, 0
    for name, _, w, h, _ in order:
        if x + w + GUTTER > SHEET_WIDTH:
            x, y, row = GUTTER, y + row + GUTTER, 0
        pos[name] = (x, y)
        x += w + GUTTER
        row = max(row, h)
    return pos, SHEET_WIDTH, y + row + GUTTER


def sheet_svg(items, pos, width, height):
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{width * RATIO}" '
             f'height="{height * RATIO}" viewBox="0 0 {width} {height}">']
    for name, family, w, h, svg in items:
        x, y = pos[name]
        px, py = (FAMILIES[family][2:] if family else (0, 0))
        # A nested <svg> clips each symbol to its own box.
        parts.append(f'<svg x="{x}" y="{y}" width="{w}" height="{h}" viewBox="0 0 {w} {h}" '
                     f'overflow="hidden"><g transform="translate({px},{py})">{svg}</g></svg>')
    parts.append("</svg>")
    return "".join(parts)


def build(name, out_dir):
    P = palette(name)
    items = symbols(P)
    pos, width, height = pack(items)
    png = os.path.join(out_dir, f"{name}@2x.png")
    subprocess.run(["rsvg-convert", "-o", png], input=sheet_svg(items, pos, width, height).encode(),
                   check=True)
    index = {n: {"x": pos[n][0] * RATIO, "y": pos[n][1] * RATIO, "width": w * RATIO,
                 "height": h * RATIO, "pixelRatio": RATIO}
             for n, _, w, h, _ in sorted(items)}
    with open(os.path.join(out_dir, f"{name}@2x.json"), "w") as f:
        json.dump(index, f, indent=1, sort_keys=True)
        f.write("\n")
    print(name, len(items), "symbols,", f"{width * RATIO}x{height * RATIO} px")


if __name__ == "__main__":
    out = sys.argv[1] if len(sys.argv) > 1 else "assets/sprites"
    for p in ("light", "dark"):
        build(p, out)
