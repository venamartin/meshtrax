"""Generates the OSM styles: assets/styles/osm-light.json and osm-dark.json.

One layer design (OSM streets + USGS hillshade + DEM contours pack), several
palettes. Edit a palette below and rerun:

    python3 tool/make_styles.py assets/styles

Style families: the bundled family is "standard" (osm-light = the Modern
palette, osm-dark = the Dark palette). OUTDOOR below is kept for a future
"outdoor" family and isn't generated yet. usgs-*.json and charts-*.json are
separate (usgs-light and charts-light hand-written, dark variants from
tool/make_dark_variants.py).
"""
import json, sys
OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/styles"
REG, MED, ITA = ["Noto Sans Regular"], ["Noto Sans Medium"], ["Noto Sans Italic"]
SOURCES = {
    "osm": {"type": "vector", "url": "pmtiles://{pack:osm}", "attribution": "© OpenMapTiles © OpenStreetMap contributors"},
    "base": {"type": "vector", "url": "pmtiles://{pack:base}", "attribution": "USGS The National Map"},
    "contours": {"type": "vector", "url": "pmtiles://{pack:contours}", "attribution": "USGS 3DEP"},
}
ROADS = ["motorway", "trunk", "primary", "secondary", "tertiary", "minor", "service"]
# Real trails only. OSM class=path also holds sidewalks (footway), cycleways,
# steps and pedestrian areas; only these subclasses are trails.
TRAIL = ["all", ["==", ["get", "class"], "path"],
         ["match", ["get", "subclass"], ["path", "bridleway"], True, False]]
# OSM parks at sea (sanctuaries, marine reserves) would outline the ocean.
NOT_MARINE = ["!", ["match", ["get", "class"], ["national_marine_sanctuary", "state_marine_conservation_area",
              "state_marine_reserve", "state_marine_park", "marine_protected_area"], True, False]]

def O(id, type, sl, **kw): return {"id": id, "type": type, "source": "osm", "source-layer": sl, **kw}

def units_twins(layer, metric_field):
    imp = {**layer, "metadata": {"ovm:units": "imperial"}}
    met = json.loads(json.dumps(imp)); met["id"] += "-m"; met["metadata"]["ovm:units"] = "metric"
    met["layout"]["text-field"] = metric_field
    return [imp, met]

def style(name, P, note):
    road_color = ["match", ["get", "class"], ["motorway", "trunk"], P["motorway"], "primary", P["primary"],
                  "secondary", P["secondary"], "tertiary", P["tertiary"], P["minor"]]
    w = P["road_scale"]
    road_width = ["interpolate", ["exponential", 1.6], ["zoom"],
        8, ["match", ["get", "class"], ["motorway", "trunk"], 1.2 * w, "primary", 0.8 * w, 0.3 * w],
        16, ["match", ["get", "class"], ["motorway", "trunk"], 12 * w, ["primary", "secondary"], 9 * w,
             "tertiary", 7 * w, "minor", 5 * w, 3 * w]]
    halo = {"text-color": P["label"], "text-halo-color": P["halo"], "text-halo-width": 1.5}
    shadow = P["shade"]
    contour_ft = ["concat", ["to-string", ["get", "ele_ft"]], " ft"]
    contour_m = ["concat", ["to-string", ["get", "ele_m"]], " m"]
    # No "▲" before the name: the renderer draws labels in the platform's
    # default font, which lacks it on Linux (a box showed). A peak icon
    # comes with sprites.
    peak = lambda ele, unit: ["concat", ["coalesce", ["get", "name"], ""], "\n",
                              ["case", ["has", ele], ["concat", ["to-string", ["get", ele]], unit], ""]]
    L = [
        {"id": "background", "type": "background", "paint": {"background-color": P["bg"]}},
        O("landcover", "fill", "landcover", paint={"fill-color": ["match", ["get", "class"],
            "wood", P["wood"], "grass", P["grass"], "farmland", P["farm"], "wetland", P["wetland"],
            "sand", P["sand"], "rock", P["rock"], "ice", P["ice"], P["grass"]], "fill-opacity": P["cover_op"]}),
        O("landuse", "fill", "landuse", paint={"fill-color": ["match", ["get", "class"],
            "residential", P["residential"], ["commercial", "retail", "industrial"], P["commercial"],
            "cemetery", P["grass"], ["school", "college", "university", "hospital"], P["civic"], P["residential"]],
            "fill-opacity": P["landuse_op"]}),
        O("park", "fill", "park", filter=NOT_MARINE,
          paint={"fill-color": P["park"], "fill-opacity": P["park_op"]}),
        {"id": "hillshade", "type": "fill", "source": "base", "source-layer": "hillshade",
         "paint": {"fill-color": ["case", ["<", ["get", "level"], 0], P["highlight"], shadow],
                   "fill-opacity": ["match", ["get", "level"], -1, P["hl_op"],
                                    1, P["shade_op"][0], 2, P["shade_op"][1], 3, P["shade_op"][2], 4, P["shade_op"][3], 0],
                   "fill-antialias": False}},
        O("water", "fill", "water", paint={"fill-color": P["water"]}),
        O("waterway", "line", "waterway", paint={"line-color": P["waterway"],
            "line-width": ["interpolate", ["linear"], ["zoom"], 10, ["match", ["get", "class"], "river", 1.2, 0.4],
                           16, ["match", ["get", "class"], "river", 4, 1.4]]}),
        {"id": "contour", "type": "line", "source": "contours", "source-layer": "contour",
         "paint": {"line-color": ["case", ["==", ["get", "idx"], 1], P["contour_idx"], P["contour"]],
                   "line-opacity": P["contour_op"],
                   "line-width": ["case", ["==", ["get", "idx"], 1], P["contour_w"][1], P["contour_w"][0]]}},
        O("park-outline", "line", "park", minzoom=9, filter=NOT_MARINE,
          paint={"line-color": P["park_line"], "line-width": P["park_line_w"], "line-opacity": 0.8,
                 "line-dasharray": [3, 2]}),
        O("aeroway", "line", "aeroway", filter=["match", ["get", "class"], ["runway", "taxiway"], True, False],
          paint={"line-color": P["aeroway"], "line-width": ["interpolate", ["linear"], ["zoom"], 10, 1, 16, 14]}),
        O("building", "fill", "building", minzoom=13, paint={"fill-color": P["building"],
            "fill-outline-color": P["building_line"], "fill-opacity": P["building_op"]}),
        O("road-casing", "line", "transportation", minzoom=11,
          filter=["match", ["get", "class"], ROADS, True, False],
          layout={"line-cap": "round", "line-join": "round"},
          paint={"line-color": P["casing"], "line-gap-width": road_width, "line-width": P["casing_w"]}),
        O("road", "line", "transportation", filter=["match", ["get", "class"], ROADS, True, False],
          layout={"line-cap": "round", "line-join": "round"},
          paint={"line-color": road_color, "line-width": road_width}),
        O("track", "line", "transportation", minzoom=11, filter=["==", ["get", "class"], "track"],
          paint={"line-color": P["track"], "line-width": ["interpolate", ["linear"], ["zoom"], 11, 0.8, 16, 2.2],
                 "line-dasharray": [3, 1.5]}),
        O("trail-halo", "line", "transportation", minzoom=11, filter=TRAIL,
          paint={"line-color": P["trail_halo"], "line-opacity": P["trail_halo_op"],
                 "line-width": ["interpolate", ["linear"], ["zoom"], 11, 3, 16, 6]}),
        O("trail", "line", "transportation", minzoom=11, filter=TRAIL,
          paint={"line-color": P["trail"], "line-width": ["interpolate", ["linear"], ["zoom"], 11, P["trail_w"][0], 16, P["trail_w"][1]],
                 "line-dasharray": [2, 1]}),
        O("rail", "line", "transportation", filter=["==", ["get", "class"], "rail"],
          paint={"line-color": P["rail"], "line-width": 1.2, "line-dasharray": [4, 2]}),
        O("boundary", "line", "boundary", filter=["<=", ["get", "admin_level"], 6],
          paint={"line-color": P["boundary"], "line-width": 1, "line-dasharray": [4, 2]}),
        *units_twins({"id": "contour-label", "type": "symbol", "source": "contours", "source-layer": "contour",
                      "minzoom": 12, "filter": ["==", ["get", "idx"], 1],
                      "layout": {"symbol-placement": "line", "text-field": contour_ft, "text-font": REG, "text-size": 10},
                      "paint": {"text-color": P["contour_label"], "text-halo-color": P["halo"], "text-halo-width": 1.5}},
                     contour_m),
        O("water-name", "symbol", "water_name", layout={"text-field": ["get", "name"], "text-font": ITA, "text-size": 12},
          paint={"text-color": P["water_label"], "text-halo-color": P["halo"], "text-halo-width": 1}),
        O("waterway-name", "symbol", "waterway", minzoom=13,
          layout={"symbol-placement": "line", "text-field": ["coalesce", ["get", "name"], ""], "text-font": ITA, "text-size": 10},
          paint={"text-color": P["water_label"], "text-halo-color": P["halo"], "text-halo-width": 1}),
        O("road-label", "symbol", "transportation_name", minzoom=12,
          layout={"symbol-placement": "line", "text-field": ["coalesce", ["get", "name"], ["get", "ref"]],
                  "text-font": REG, "text-size": 11}, paint=halo),
        O("trail-label", "symbol", "transportation_name", minzoom=13,
          filter=["all", ["==", ["get", "class"], "path"], ["!=", ["get", "subclass"], "footway"]],
          layout={"symbol-placement": "line", "text-field": ["coalesce", ["get", "name"], ""], "text-font": ITA, "text-size": 11},
          paint={"text-color": P["trail"], "text-halo-color": P["halo"], "text-halo-width": 1.5}),
        O("poi", "symbol", "poi", minzoom=P["poi_minzoom"], filter=["<=", ["get", "rank"], P["poi_rank"]],
          layout={"text-field": ["get", "name"], "text-font": REG, "text-size": 10, "text-max-width": 8},
          paint={"text-color": P["poi_label"], "text-halo-color": P["halo"], "text-halo-width": 1.5}),
        *units_twins(O("peak", "symbol", "mountain_peak", minzoom=P["peak_minzoom"],
                       layout={"text-field": peak("ele_ft", " ft"), "text-font": MED, "text-size": 11, "text-anchor": "top"},
                       paint={"text-color": P["peak"], "text-halo-color": P["halo"], "text-halo-width": 1.5}),
                     peak("ele", " m")),
        O("place", "symbol", "place", filter=["match", ["get", "class"], ["city", "town", "village", "hamlet", "suburb"], True, False],
          layout={"text-field": ["get", "name"], "text-font": MED,
                  "text-size": ["match", ["get", "class"], "city", 17, "town", 15, "village", 12.5, 11],
                  "text-transform": P["place_case"], "text-letter-spacing": P["place_spacing"]},
          paint={"text-color": P["place"], "text-halo-color": P["halo"], "text-halo-width": 2}),
    ]
    return {"version": 8, "name": name,
            "metadata": {"ovm:status": note},
            "glyphs": "{glyphs}", "sources": SOURCES, "layers": L}

BASE = dict(cover_op=0.85, landuse_op=0.7, park_op=0.35, hl_op=0.2, road_scale=1.0, casing_w=0.8,
            contour_w=[0.45, 1.0], contour_op=0.75, park_line_w=1, building_op=1, trail_halo_op=0,
            trail_w=[0.9, 2.4], poi_minzoom=15, poi_rank=20, peak_minzoom=10, place_case="none", place_spacing=0)

DARK = {**BASE,
    "bg": "#1c2026", "wood": "#1f2b24", "grass": "#222a24", "farm": "#23262a", "wetland": "#1e2a2c",
    "sand": "#2b2a26", "rock": "#26282c", "ice": "#2c3238", "residential": "#23272d", "commercial": "#2a272d",
    "civic": "#29282a", "park": "#203024", "park_op": 0.6, "park_line": "#3f6b4a",
    "shade": "#000000", "shade_op": [0.12, 0.22, 0.32, 0.42], "highlight": "#ffffff", "hl_op": 0.05,
    "water": "#13283a", "waterway": "#2b5578", "contour": "#5b4e40", "contour_idx": "#7c6a55", "contour_op": 0.8,
    "aeroway": "#3a3f48", "building": "#2c3138", "building_line": "#363c44",
    "casing": "#14171b", "motorway": "#9a7440", "primary": "#6e6650", "secondary": "#585548",
    "tertiary": "#4a4c50", "minor": "#3b3f45", "track": "#7a6a55", "trail": "#d0705f", "trail_halo": "#000000",
    "rail": "#555b63", "boundary": "#6b5b80", "label": "#c9d0d8", "halo": "#1c2026",
    "contour_label": "#a08c72", "water_label": "#6f9cc7", "poi_label": "#9aa3ad", "peak": "#d8b98a", "place": "#e6eaef"}

MODERN = {**BASE,
    "bg": "#f6f4f0", "wood": "#d9ead0", "grass": "#e4efdb", "farm": "#f2f0e6", "wetland": "#d8ebe6",
    "sand": "#f5ecd5", "rock": "#e9e6e1", "ice": "#f7fafc", "residential": "#efebe6", "commercial": "#f3e9e6",
    "civic": "#f2ecdf", "park": "#cfe8c4", "park_op": 0.5, "park_line": "#a9d19a", "cover_op": 0.75,
    "shade": "#2b3a4a", "shade_op": [0.03, 0.06, 0.1, 0.14], "highlight": "#ffffff", "hl_op": 0.25,
    "water": "#a9d4f5", "waterway": "#8cc3ee", "contour": "#d9c9b6", "contour_idx": "#c4ae96", "contour_op": 0.9,
    "contour_w": [0.4, 0.8], "aeroway": "#dcdbe6", "building": "#e8e3dc", "building_line": "#d8d1c8",
    "casing": "#dcd6cd", "casing_w": 1, "motorway": "#ffd58a", "primary": "#fff3c9", "secondary": "#ffffff",
    "tertiary": "#ffffff", "minor": "#ffffff", "road_scale": 1.15, "track": "#b89f7d", "trail": "#e07a5f",
    "trail_halo": "#ffffff", "trail_halo_op": 0.6, "rail": "#b3b0aa", "boundary": "#c3b3d6",
    "label": "#55595e", "halo": "#ffffff", "contour_label": "#b39a7e", "water_label": "#4a86b8",
    "poi_label": "#7a7f85", "poi_minzoom": 16, "poi_rank": 10, "peak": "#7a5a3a", "place": "#2f3337",
    "place_spacing": 0.02}

OUTDOOR = {**BASE,
    "bg": "#f3efe4", "wood": "#bfd9a8", "grass": "#d9e8c2", "farm": "#efe9d2", "wetland": "#c9e2d6",
    "sand": "#f0e2bd", "rock": "#ddd6cb", "ice": "#f2f7fa", "residential": "#ebe5dc", "commercial": "#ece0dc",
    "civic": "#ece3cf", "park": "#b8dca0", "park_op": 0.3, "park_line": "#3f8a3a", "park_line_w": 2,
    "cover_op": 0.9, "landuse_op": 0.5,
    "shade": "#2a2016", "shade_op": [0.08, 0.16, 0.25, 0.35], "highlight": "#fffbe8", "hl_op": 0.3,
    "water": "#93c4e8", "waterway": "#4f95cf", "contour": "#a87a50", "contour_idx": "#8a5a30", "contour_op": 0.85,
    "contour_w": [0.55, 1.3], "aeroway": "#cfcbd8", "building": "#d9d1c5", "building_line": "#c5bbac",
    "building_op": 0.8, "casing": "#a9a090", "casing_w": 0.6, "motorway": "#e8a75b", "primary": "#f2cf8a",
    "secondary": "#f7e6b5", "tertiary": "#ffffff", "minor": "#ffffff", "road_scale": 0.8,
    "track": "#8a6a3e", "trail": "#d1340f", "trail_halo": "#ffffff", "trail_halo_op": 0.7, "trail_w": [1.3, 3.2],
    "rail": "#8f8a84", "boundary": "#9d7fb6", "label": "#3d3a35", "halo": "#ffffff",
    "contour_label": "#7a4f26", "water_label": "#2f6fa8", "poi_label": "#6a655d", "poi_minzoom": 16,
    "poi_rank": 8, "peak": "#5a2e0e", "peak_minzoom": 9, "place": "#2c2a26",
    "place_case": "uppercase", "place_spacing": 0.08}

# (style id, name, palette, theme, family). Add future families here, e.g.
# ("osm-outdoor-light", "OSM Outdoor", OUTDOOR, "light", "outdoor").
STYLES = [
    ("osm-light", "OpenStreetMap", MODERN, "light", "standard"),
    ("osm-dark", "OpenStreetMap (dark)", DARK, "dark", "standard"),
]

for sid, name, P, theme, family in STYLES:
    s = style(name, P, "Generated by tool/make_styles.py.")
    # ovm:requires: the pack kinds the map can't be drawn without.
    s["metadata"].update({"ovm:map": "osm", "ovm:requires": ["osm"],
                          "ovm:theme": theme, "ovm:family": family})
    if theme == "dark":
        s["metadata"]["ovm:dark"] = True  # apps can match their own UI theme
    open(f"{OUT}/{sid}.json", "w").write(json.dumps(s, indent=2, ensure_ascii=False) + "\n")
    print(sid, len(s["layers"]), "layers")
