"""The chart styles' layers grouped by role (charts_revision 2, traxmapmaker
SCHEMA.md "Charts pack"): routes, regulated areas, overhead clearances, cables
and pipelines, structures, harbour facilities, seabed, tide and current, extra
aids, landmarks and labels.

charts-light.json is hand-written; this replaces its generated layers (by id)
and the buoy-name text, so it can be rerun after editing either:

    python3 tool/make_chart_layers.py assets/styles
    python3 tool/make_dark_variants.py assets/styles

make_dark_variants.py takes the dark paint of these layers from dark_paint().

No sprites yet, so symbols are circles, lines, fills and text with INT-1
abbreviations. Lane and current arrows, anchors, restricted-area T-ticks,
topmarks and the cable wave wait for sprites. Checked on traxmapmaker's Puerto
Rico pilot (2026-10-21) by a conventions, phone-legibility and data review.
"""
import json
import sys

LIGHT = {
    "magenta": "#b5186e", "magenta_text": "#a0106a", "ink": "#333333", "grey": "#7d7d7d",
    "seabed": "#5d6b78", "halo": "#ffffff", "land_halo": "#f3ead0", "fairway": "#5d7d99",
    "swept": "#4f8a5b", "swept_text": "#3f6f4b", "water_text": "#3f6f96", "breakers": "#5b88b0",
    "weed": "#8fb27a", "weed_text": "#4f7a3f", "unsurveyed": "#cfd3d6", "dock": "#c9c3b4",
    "tank": "#b8ad97", "structure": "#a59f92", "bridge": "#8f8a80", "bridge_edge": "#3d3a35",
    "bridge_line": "#5c5852", "overhead": "#3d3a35", "region_text": "#6b5a3a",
    "harbour_text": "#1f5f99", "mooring": "#ffffff", "mooring_yellow": "#f2c200",
    "edge": "#222222",
    "day": {"red": "#d7263d", "green": "#2a9d4b", "yellow": "#f2c200", "white": "#ffffff",
            "black": "#222222", "orange": "#f28c28", "other": "#888888"},
}
DARK = {
    "magenta": "#ff6fc4", "magenta_text": "#ff7fc8", "ink": "#d8dde3", "grey": "#9aa0a6",
    "seabed": "#9fb0c0", "halo": "#161b20", "land_halo": "#22201b", "fairway": "#7fa3c4",
    "swept": "#6fbf80", "swept_text": "#8fd09f", "water_text": "#8fbde6", "breakers": "#7fb0e0",
    "weed": "#4f7a3f", "weed_text": "#8fc07a", "unsurveyed": "#3a3f44", "dock": "#3a362e",
    "tank": "#5a5246", "structure": "#5a564e", "bridge": "#6a655c", "bridge_edge": "#d0c8b8",
    "bridge_line": "#a39d92", "overhead": "#c8c0b0", "region_text": "#cbb894",
    "harbour_text": "#7fb0e0", "mooring": "#f2f2f2", "mooring_yellow": "#ffd23f",
    "edge": "#0c1e30",
    "day": {"red": "#ff4d5e", "green": "#3ccf6e", "yellow": "#ffd23f", "white": "#f2f2f2",
            "black": "#9aa0a6", "orange": "#ff9f43", "other": "#9aa0a6"},
}
FT = 3.28084
CLEAR = "rgba(0,0,0,0)"


def cls(*names):
    if len(names) == 1:
        return ["==", ["get", "class"], names[0]]
    return ["match", ["get", "class"], list(names), True, False]


def all_(*f):
    return ["all", *f]


def has_code(attr, slug):
    """Exact test on a comma list (`in` on a string is a substring test)."""
    return ["in", f",{slug},", ["concat", ",", ["get", attr], ","]]


POLY = ["==", ["geometry-type"], "Polygon"]
LINE = ["==", ["geometry-type"], "LineString"]
POINT = ["==", ["geometry-type"], "Point"]
ANCHOR = ["has", "anchor"]
NOT_ANCHOR = ["!", ["has", "anchor"]]
NAME = ["coalesce", ["get", "name"], ""]
RES = lambda slug: has_code("restrictions", slug)
CAT = lambda slug: has_code("categories", slug)


def layer(id_, type_, source_layer, filter_, minzoom, paint, layout=None, units=None):
    l = {"id": id_, "type": type_, "source": "charts", "source-layer": source_layer,
         "filter": filter_, "minzoom": minzoom}
    if layout:
        l["layout"] = layout
    l["paint"] = paint
    if units:
        l["metadata"] = {"ovm:units": units}
    return l


def text(P, id_, source_layer, filter_, field, minzoom, color=None, size=10, italic=False,
         halo=None, units=None, line=False, offset=None, anchor=None):
    lay = {"text-field": field, "text-size": size, "text-max-width": 8,
           "text-font": ["Noto Sans Italic" if italic else "Noto Sans Regular"]}
    if line:
        lay["symbol-placement"] = "line"
        lay["symbol-spacing"] = 300
    if offset:
        lay["text-offset"] = offset
    if anchor:
        lay["text-anchor"] = anchor
    return layer(id_, "symbol", source_layer, filter_, minzoom, layout=lay, units=units,
                 paint={"text-color": color or P["ink"], "text-halo-color": halo or P["halo"],
                        "text-halo-width": 1.2})


def ft_safe(attr):
    """Feet that never overstate a clearance or depth: NOAA charts feet and the
    cells store 0.1 m, so +0.2 ft recovers the charted figure before flooring."""
    return ["to-string", ["floor", ["+", ["*", ["get", attr], FT], 0.2]]]


def value(attr, units):
    if units == "imperial":
        return ["concat", ft_safe(attr), " ft"]
    return ["concat", ["to-string", ["get", attr]], " m"]


def clearance_text(units):
    V = lambda a: value(a, units)
    vc = ["case",
          ["has", "clearance_safe_m"], ["concat", "Safe VC ", V("clearance_safe_m")],
          ["has", "clearance_m"], ["concat", "VC ", V("clearance_m")],
          ["any", ["has", "clearance_closed_m"], ["has", "clearance_open_m"]],
          ["concat", "VC ",
           ["case", ["has", "clearance_closed_m"], ["concat", V("clearance_closed_m"), " closed"], ""],
           ["case", ["all", ["has", "clearance_closed_m"], ["has", "clearance_open_m"]], ", ", ""],
           ["case", ["has", "clearance_open_m"], ["concat", V("clearance_open_m"), " open"], ""]],
          ""]
    hc = ["case", ["has", "horizontal_clearance_m"], ["concat", " HC ", V("horizontal_clearance_m")], ""]
    return ["concat", vc, hc]


HAS_CLEARANCE = ["any", ["has", "clearance_m"], ["has", "clearance_closed_m"], ["has", "clearance_open_m"],
                 ["has", "clearance_safe_m"], ["has", "horizontal_clearance_m"]]

# What a regulated area is, in chart words. RESARE reads its exact
# restrictions: the `restriction` key groups prohibited with restricted.
KIND = ["match", ["get", "class"],
        "RESARE", ["case",
                   RES("entry_prohibited"), "Entry prohibited",
                   RES("area_to_be_avoided"), "Area to be avoided",
                   ["==", ["get", "restriction"], "entry"], "Entry restricted",
                   RES("anchoring_prohibited"), "No anchoring",
                   ["==", ["get", "restriction"], "anchoring"], "Anchoring restricted",
                   RES("fishing_prohibited"), "No fishing",
                   ["==", ["get", "restriction"], "fishing"], "Fishing restricted",
                   ["match", ["get", "category"], "military_area", "Military area",
                    "offshore_safety_zone", "Safety zone", "nature_reserve", "Nature reserve",
                    "ecological_reserve", "Ecological reserve", "Restricted area"]],
        "ACHARE", ["case", CAT("explosives"), "Explos Anch", CAT("quarantine"), "Quar Anch",
                   CAT("deep_water"), "DW Anch", CAT("tanker"), "Tanker Anch",
                   CAT("small_craft"), "Small craft Anch", "Anch"],
        "CTNARE", ["case", ANCHOR, "Caution area",
                   ["<=", ["length", ["coalesce", ["get", "info"], ""]], 16],
                   ["coalesce", ["get", "info"], "(!)"], "(!)"],
        "MIPARE", ["match", ["get", "category"], "firing_danger_area", "Firing area",
                   "submarine_exercise_area", "Submarine exercise area",
                   "torpedo_exercise_area", "Torpedo exercise area",
                   "mine_laying_practice_area", "Mine laying practice area",
                   "small_arms_firing_range", "Firing range", "Military practice area"],
        "DMPGRD", ["case", ["==", ["get", "disused"], 1],
                   ["match", ["get", "category"], "spoil_ground", "Disused spoil ground",
                    "explosives", "Disused explos dumping ground", "Disused dumping ground"],
                   ["match", ["get", "category"], "spoil_ground", "Spoil ground",
                    "explosives", "Explos dumping ground", "Dumping ground"]],
        "CBLARE", "Cable area", "PIPARE", "Pipeline area", "MARCUL", "Marine farm",
        "FSHGRD", "Fishing ground", "SPLARE", "Seaplane area", "OSPARE", "Offshore production",
        "CTSARE", "Cargo transhipment", "UNSARE", "Unsurveyed", ""]
AREA_AT = ["index-of", "Area ", NAME]
REGULATED_TEXT = ["case",
                  cls("ACHBRT"), NAME,
                  # "Anch E" from "… Anchorage Area E"; one- to three-letter names too.
                  cls("ACHARE"), ["concat", KIND,
                                  ["case", [">=", AREA_AT, 0], ["concat", " ", ["slice", NAME, ["+", AREA_AT, 5]]],
                                   ["all", ["has", "name"], ["<=", ["length", NAME], 3]], ["concat", " ", NAME],
                                   ""]],
                  ["!", ["has", "name"]], KIND,
                  ["<=", ["length", NAME], 4], ["concat", KIND, " ", NAME],
                  ["<=", ["length", NAME], 24], ["concat", KIND, "\n", NAME],
                  KIND]

LANDMARK_ABBR = ["match", ["get", "category"],
                 "tower", ["match", ["get", "function"], "radio", "R Tr", "television", "TV Tr",
                           "microwave", "Micro Tr", "Tr"],
                 "mast", ["match", ["get", "function"], "radio", "R Mast", "television", "TV Mast", "Mast"],
                 "chimney", "Chy", "flare_stack", "Flare", "tank", "Tk", "silo", "Silo",
                 "grain_elevator", "Elev", "water_tower", "Water Tr", "dome", "Dome",
                 "spire_minaret", "Spire", "windmill", "Windmill", "windmotor", "Wind motor",
                 "monument", "Mon", "dish_aerial", "Dish aerial", "flagstaff", "FS", "cross", "Cross",
                 "statue", "Statue", "radar_scanner", "Radar Sc",
                 ["match", ["get", "function"], "church", "Ch", "hospital", "Hosp",
                  "power_station", "Power sta", "factory", "Factory",
                  ["match", ["get", "class"], "BUISGL", "Bldg", ""]]]
# Conspicuous objects in capitals, as charts print them (TR, CHY).
LANDMARK_TEXT = ["coalesce", ["get", "name"],
                 ["case", ["==", ["get", "conspicuous"], 1], ["upcase", LANDMARK_ABBR], LANDMARK_ABBR]]
# The lighthouse structure: its light already marks it.
NOT_LIGHT_SUPPORT = ["!=", ["get", "function"], "light_support"]

# Radio stations: "R Bn" only for coded radiobeacons; most RDOSTA in NOAA's
# cells are broadcast towers (call sign and kHz).
RADIO_TEXT = ["case",
              ["has", "category"],
              ["concat", ["match", ["get", "category"], "aeronautical_radiobeacon", "Aero R Bn",
                          ["circular_radiobeacon", "directional_radiobeacon",
                           "rotating_pattern_radiobeacon"], "R Bn",
                          "differential_gps", "DGPS", "R Sta"],
               ["case", ["has", "call_sign"], ["concat", " ", ["get", "call_sign"]], ""]],
              ["has", "call_sign"],
              ["concat", ["get", "call_sign"],
               ["case", ["has", "frequency_khz"],
                ["concat", " ", ["to-string", ["get", "frequency_khz"]], " kHz"], ""]],
              "R Sta"]
HARBOUR_TEXT = ["match", ["get", "class"],
                "PILBOP", ["concat", "Pilots", ["case", ["has", "name"], ["concat", " ", NAME], ""]],
                "CGUSTA", ["concat", "CG", ["case", ["has", "name"], ["concat", " ", NAME], ""]],
                "RSCSTA", "Lifeboat", "CRANES", "Crane", "RADSTA", "Ra", "RDOSTA", RADIO_TEXT,
                "HRBFAC", ["coalesce", ["get", "name"],
                           ["match", ["get", "category"], "marina", "Marina", "ferry_terminal", "Ferry",
                            "fishing_harbour", "Fishing hbr", "naval_base", "Naval base", ""]],
                "SMCFAC", ["match", ["get", "category"], "launching_place", "Ramp", "pump_out", "Pump-out",
                           "fuel_station", "Fuel", "water_tap", "Water", NAME],
                NAME]


def groups(P):
    """The new layers in splice order, built with palette P."""
    under = [  # fills and limits, under the coastline
        layer("tss-zone", "fill", "route", cls("TSEZNE", "ISTZNE"), 9,
              {"fill-color": P["magenta"], "fill-opacity": 0.22}),
        layer("unsurveyed", "fill", "regulated_area", cls("UNSARE"), 9,
              {"fill-color": P["unsurveyed"], "fill-opacity": 0.7}),
        layer("seabed-weed", "fill", "seabed", all_(cls("WEDKLP"), POLY), 12,
              {"fill-color": P["weed"], "fill-opacity": 0.18}),
        layer("dock-area", "fill", "structure", cls("DRYDOC", "FLODOC", "DOCARE", "LOKBSN", "HULKES"), 13,
              {"fill-color": P["dock"], "fill-opacity": 0.9}),
        # Traffic separation (S-52): dashed scheme limit, wide translucent
        # separation line; lane arrows wait for sprites.
        layer("tss-boundary", "line", "route", cls("TSSBND"), 9,
              {"line-color": P["magenta"], "line-width": 1.2, "line-dasharray": [6, 3], "line-opacity": 0.8}),
        layer("tss-separation-line", "line", "route", cls("TSELNE"), 9,
              {"line-color": P["magenta"], "line-width": 5, "line-opacity": 0.25}),
        layer("precautionary", "line", "route", all_(cls("PRCARE", "TWRTPT", "DWRTPT"), POLY), 9,
              {"line-color": P["magenta"], "line-width": 1.2, "line-dasharray": [5, 3]}),
        layer("fairway", "line", "route", all_(cls("FAIRWY"), POLY), 13,
              {"line-color": P["fairway"], "line-width": 1, "line-dasharray": [6, 4], "line-opacity": 0.6}),
        layer("track", "line", "route",
              all_(cls("RECTRC", "DWRTCL", "RCRTCL", "RCTLPT", "FERYRT", "RDOCAL"), LINE), 10,
              {"line-color": P["ink"], "line-width": 1,
               "line-dasharray": ["match", ["get", "class"], "FERYRT", ["literal", [4, 4]],
                                  "RECTRC", ["match", ["get", "category"], "not_based_on_fixed_marks",
                                             ["literal", [6, 3]], ["literal", [1, 0]]],
                                  ["literal", [1, 0]]]}),
        layer("leading-line", "line", "route", all_(cls("NAVLNE"), LINE), 11,
              {"line-color": P["ink"], "line-width": 0.8, "line-dasharray": [8, 3]}),
        # Magenta dashed limits, entry restrictions heavier; explosives
        # dumping grounds magenta, spoil grounds, farms and fishing grey.
        layer("regulated-limit", "line", "regulated_area",
              all_(cls("RESARE", "CTNARE", "ACHARE", "MIPARE", "DMPGRD", "CBLARE", "PIPARE", "MARCUL",
                       "SPLARE", "CTSARE", "OSPARE", "FSHGRD", "ICNARE", "FRPARE", "CUSZNE"), POLY), 10,
              {"line-color": ["case", ["all", cls("DMPGRD"), CAT("explosives")], P["magenta"],
                              cls("DMPGRD", "MARCUL", "FSHGRD"), P["grey"], P["magenta"]],
               "line-width": ["interpolate", ["linear"], ["zoom"],
                              10, ["match", ["get", "restriction"], "entry", 1.2, 0.8],
                              14, ["match", ["get", "restriction"], "entry", 1.8, 1.1]],
               "line-opacity": ["interpolate", ["linear"], ["zoom"], 10, 0.6, 13, 0.85],
               "line-dasharray": [5, 3]}),
        layer("swept-limit", "line", "regulated_area", all_(cls("SWPARE"), POLY), 14,
              {"line-color": P["swept"], "line-width": 0.8, "line-dasharray": [2, 2]}),
        # Cables solid (the wave waits for sprites), disused broken; pipelines
        # dash-dot, outfalls, intakes and sewers grey (INT-1 L40/L41).
        layer("cable", "line", "cable_pipe", cls("CBLSUB"), 11,
              {"line-color": P["magenta"], "line-width": 0.9,
               "line-opacity": ["case", ["==", ["get", "disused"], 1], 0.35, 0.8],
               "line-dasharray": ["case", ["==", ["get", "disused"], 1], ["literal", [2, 3]],
                                  ["literal", [1, 0]]]}),
        layer("pipeline", "line", "cable_pipe", cls("PIPSOL"), 11,
              {"line-color": ["match", ["get", "category"], ["outfall", "intake", "sewer", "bubbler"],
                              P["grey"], P["magenta"]],
               "line-width": 0.9, "line-opacity": 0.8, "line-dasharray": [6, 2, 1.5, 2]}),
        layer("breakers", "line", "tide_current",
              all_(cls("WATTUR"), ["match", ["geometry-type"], ["Polygon", "LineString"], True, False]), 12,
              {"line-color": P["breakers"], "line-width": 0.8, "line-dasharray": [1, 2]}),
    ]
    over = [  # structures and bridges, over the coastline
        layer("tank-fill", "fill", "landmark", cls("SILTNK", "BUISGL"), 13,
              {"fill-color": P["tank"], "fill-outline-color": P["ink"]}),
        layer("structure-fill", "fill", "structure", cls("DAMCON", "OFSPLF", "MORFAC", "PONTON", "CAUSWY"), 13,
              {"fill-color": P["structure"], "fill-outline-color": P["ink"]}),
        layer("pontoon", "line", "structure", all_(cls("PONTON", "OILBAR", "DAMCON", "CAUSWY"), LINE), 13,
              {"line-color": P["ink"], "line-width": ["match", ["get", "class"], "OILBAR", 1, 2]}),
        layer("bridge-fill", "fill", "overhead", cls("BRIDGE"), 11,
              {"fill-color": P["bridge"], "fill-outline-color": P["bridge_edge"]}),
        layer("bridge-line", "line", "overhead", all_(cls("BRIDGE", "GATCON"), LINE), 11,
              {"line-color": P["bridge_line"], "line-width": 3}),
        layer("overhead-line", "line", "overhead", cls("CBLOHD", "PIPOHD", "CONVYR"), 11,
              {"line-color": P["overhead"], "line-width": 1, "line-dasharray": [4, 2]}),
    ]
    points = [  # under the nav-aid dots
        layer("anchor-berth", "circle", "regulated_area", all_(cls("ACHBRT"), NOT_ANCHOR), 12,
              {"circle-radius": ["case", ["has", "radius_m"], 6, 4], "circle-color": CLEAR,
               "circle-stroke-color": P["magenta"], "circle-stroke-width": 1.2}),
        layer("pile", "circle", "structure", all_(cls("PILPNT", "PYLONS"), NOT_ANCHOR), 14,
              {"circle-radius": 1.4, "circle-color": P["ink"]}),
        # Dolphins and platforms small and plain; mooring buoys white (or
        # their charted yellow), never the nav-aid yellow by default.
        layer("dolphin", "circle", "structure", all_(cls("MORFAC", "OFSPLF"), NOT_ANCHOR), 13,
              {"circle-radius": ["case", cls("OFSPLF"), 3.5, ["==", ["get", "category"], "mooring_buoy"], 3, 2],
               "circle-color": ["case", ["==", ["get", "category"], "mooring_buoy"],
                                ["match", ["get", "colour"], "yellow", P["mooring_yellow"], P["mooring"]],
                                P["ink"]],
               "circle-stroke-color": P["edge"],
               "circle-stroke-width": ["case", ["==", ["get", "category"], "mooring_buoy"], 1, 0]}),
        # Landmarks: the INT-1 position circle with its dot.
        layer("landmark", "circle", "landmark", all_(cls("LNDMRK", "SILTNK", "BUISGL"), NOT_ANCHOR,
                                                     NOT_LIGHT_SUPPORT), 13,
              {"circle-radius": 3, "circle-color": CLEAR, "circle-stroke-color": P["ink"],
               "circle-stroke-width": 1.2}),
        layer("landmark-dot", "circle", "landmark", all_(cls("LNDMRK", "SILTNK", "BUISGL"), NOT_ANCHOR,
                                                         NOT_LIGHT_SUPPORT), 13,
              {"circle-radius": 0.9, "circle-color": P["ink"]}),
        # The magenta ring is a navigational radio service: coded stations only.
        layer("radio", "circle", "harbour",
              all_(cls("RDOSTA", "RADSTA"), NOT_ANCHOR, ["any", ["has", "category"], cls("RADSTA")]), 13,
              {"circle-radius": 4, "circle-color": CLEAR, "circle-stroke-color": P["magenta"],
               "circle-stroke-width": 1}),
        # Virtual AIS aids are never drawn like a physical mark.
        layer("virtual-aid", "circle", "aid_extra", all_(["==", ["get", "virtual"], 1], NOT_ANCHOR), 12,
              {"circle-radius": 5, "circle-color": CLEAR, "circle-stroke-color": P["magenta"],
               "circle-stroke-width": 1, "circle-stroke-opacity": 0.8}),
    ]
    day = P["day"]
    daymarks = [  # over the beacon: the colour many beacons only have here
        layer("daymark", "circle", "aid_extra", all_(cls("DAYMAR"), NOT_ANCHOR), 11,
              {"circle-radius": 2.5,
               "circle-color": ["match", ["get", "colour"], "red", day["red"], "green", day["green"],
                                "yellow", day["yellow"], "white", day["white"], "black", day["black"],
                                "orange", day["orange"], day["other"]],
               "circle-stroke-color": P["edge"], "circle-stroke-width": 0.6}),
    ]
    low = [  # labels below the soundings: lowest priority first
        text(P, "seabed-label", "seabed", all_(cls("SBDARE"), POINT, ["has", "label"], ["has", "nature"]),
             ["get", "label"], 14, color=P["seabed"], size=9, italic=True),
        text(P, "weed-label", "seabed", all_(cls("WEDKLP"), POINT),
             ["match", ["get", "category"], "kelp", "Kelp", "sea_weed", "Wd", "sea_grass", "Grass",
              "sargasso", "Sargasso", "Wd"], 14, color=P["weed_text"], size=9, italic=True),
        text(P, "breakers-label", "tide_current", all_(cls("WATTUR"), POINT),
             ["match", ["get", "category"], "breakers", "Br", "eddies", "Eddies", "overfalls", "Overfalls",
              "tide_rips", "Rips", ""], 14, color=P["water_text"], size=9, italic=True),
        text(P, "current-label", "tide_current", all_(cls("CURENT", "TS_FEB"), POINT, ["has", "speed_kn"]),
             ["concat", ["to-string", ["get", "speed_kn"]], " kn"], 12, color=P["water_text"], size=9),
        text(P, "land-region", "label", cls("LNDRGN"), NAME, 12, color=P["region_text"], size=10,
             italic=True, halo=P["land_halo"]),
        text(P, "magvar", "label", all_(cls("MAGVAR"), ["has", "label"]), ["concat", "Var ", ["get", "label"]],
             10, color=P["magenta_text"], size=9),
        text(P, "swept-label", "regulated_area", all_(cls("SWPARE"), ANCHOR, ["has", "depth_m"]),
             ["concat", "Swept ", value("depth_m", "imperial")], 15, color=P["swept_text"], size=9,
             units="imperial"),
        text(P, "swept-label-m", "regulated_area", all_(cls("SWPARE"), ANCHOR, ["has", "depth_m"]),
             ["concat", "Swept ", value("depth_m", "metric")], 15, color=P["swept_text"], size=9,
             units="metric"),
        text(P, "route-label", "route", all_(["has", "name"], ["any", ANCHOR, LINE]), NAME, 12,
             color=P["fairway"], size=9, italic=True),
        text(P, "track-bearing", "route", all_(cls("NAVLNE", "RECTRC"), LINE, ["has", "orient"]),
             ["concat", ["to-string", ["get", "orient"]], "°"], 13, size=9, line=True),
        text(P, "regulated-label", "regulated_area", all_(POINT, ["!", cls("SWPARE")]), REGULATED_TEXT, 12,
             color=["match", ["get", "class"], "UNSARE", P["ink"], P["magenta_text"]], size=9, italic=True),
    ]
    mid = [  # between the soundings and the hazard, light and buoy labels
        text(P, "landmark-label", "landmark", all_(POINT, NOT_LIGHT_SUPPORT, ["any", NOT_ANCHOR, ["has", "name"]]),
             ["step", ["zoom"], NAME, 14, LANDMARK_TEXT], 13, size=9, offset=[0, 0.9], anchor="top"),
        text(P, "structure-label", "structure", all_(["has", "name"], POINT), NAME, 14, size=9,
             offset=[0, 0.9], anchor="top"),
        text(P, "harbour-label", "harbour", POINT, HARBOUR_TEXT, 13, color=P["harbour_text"], size=9,
             offset=[0, 1], anchor="top"),
        # Upper left of the aid: the light's label is at its upper right.
        text(P, "aid-extra-label", "aid_extra", all_(cls("FOGSIG", "RTPBCN"), POINT),
             ["match", ["get", "class"],
              "RTPBCN", ["concat", "Racon", ["case", ["has", "group"], ["concat", " ", ["get", "group"]], ""]],
              "FOGSIG", ["match", ["get", "category"], ["horn", "nautophone", "reed", "tyfon"], "Horn",
                         "bell", "Bell", "whistle", "Whis", "gong", "Gong", "siren", "Siren",
                         "diaphone", "Dia", "explosive", "Explos", "Fog sig"],
              ""],
             13, color=P["magenta_text"], size=9, offset=[-0.9, -0.9], anchor="bottom-right"),
    ]
    high = [  # above the buoy and light labels: what a mast or a hull hits
        text(P, "overhead-name", "overhead", all_(LINE, cls("CBLOHD", "PIPOHD", "CONVYR"), ["!", HAS_CLEARANCE]),
             ["match", ["get", "class"], "CBLOHD", ["match", ["get", "category"], "power_line",
                                                    "Ovhd power cable", "Ovhd cable"],
              "PIPOHD", "Ovhd pipe", "Conveyor"],
             14, size=9, line=True),
        text(P, "clearance", "overhead", all_(HAS_CLEARANCE, ["any", ANCHOR, LINE]), clearance_text("imperial"),
             12, units="imperial"),
        text(P, "clearance-m", "overhead", all_(HAS_CLEARANCE, ["any", ANCHOR, LINE]), clearance_text("metric"),
             12, units="metric"),
        text(P, "virtual-aid-label", "aid_extra", all_(["==", ["get", "virtual"], 1], POINT),
             ["concat", "V-AIS ", NAME], 13, color=P["magenta_text"], size=9, offset=[0, 1.1], anchor="top"),
    ]
    return under, over, points, daymarks, low, mid, high


def generated_ids():
    return {l["id"] for g in groups(LIGHT) for l in g}


def dark_paint():
    """The new layers' paint in the dark palette, for make_dark_variants.py."""
    return {l["id"]: l["paint"] for g in groups(DARK) for l in g}


def buoy_name_text():
    """Buoy and beacon names: the chart's number in quotes ("2") below z15,
    the full name from z15."""
    def tail(word):
        i = ["index-of", word, NAME]
        s = ["slice", NAME, ["+", i, len(word)]]
        return [["all", [">=", i, 0], ["<=", ["length", s], 3]], ["concat", '"', s, '"']]
    short = ["case", *tail("Buoy "), *tail("Light "), *tail("Daybeacon "), *tail("Beacon "), ""]
    return ["step", ["zoom"], short, 15, NAME]


def main(out):
    path = f"{out}/charts-light.json"
    style = json.load(open(path))
    gen = generated_ids()
    layers = [l for l in style["layers"] if l["id"] not in gen]
    ids = [l["id"] for l in layers]

    def insert(at, new):
        layers[at:at] = new
        ids[at:at] = [l["id"] for l in new]

    under, over, points, daymarks, low, mid, high = groups(LIGHT)
    insert(ids.index("coastline"), under)
    insert(ids.index("coastline") + 1, over)
    insert(ids.index("light-flare"), points)
    insert(ids.index("nav-aid") + 1, daymarks)
    insert(ids.index("depth-contour-label"), low)
    insert(ids.index("hazard-label"), mid)
    insert(ids.index("sea-name"), high)
    layers[ids.index("nav-aid-label")]["layout"]["text-field"] = buoy_name_text()
    style["layers"] = layers
    style["metadata"]["ovm:status"] = (
        "Hand-written; the layers grouped by role (charts_revision 2) come from "
        "tool/make_chart_layers.py. No sprites yet.")
    json.dump(style, open(path, "w"), indent=2, ensure_ascii=False)
    open(path, "a").write("\n")
    print("charts-light", len(layers), "layers")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/styles")
