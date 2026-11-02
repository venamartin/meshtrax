"""The base map's layers (traxmapmaker SCHEMA.md "World base map"): Natural
Earth plus GeoNames towns, bundled in assets/world/. It is drawn at every
zoom where no region pack reaches, stretched past its own data, so the map
is never empty: traxmap's GapFillProvider leaves out each tile a region pack
has. One design, each style's colours. Rerun after editing it:

    python3 tool/make_world_layers.py assets/styles
    python3 tool/make_dark_variants.py assets/styles

This writes the layers into usgs-light.json and charts-light.json (replacing
them by id); make_dark_variants.py takes their dark paint from dark_paint(),
and make_styles.py adds them to the OSM styles itself.
"""
import json
import sys

SOURCE = {"type": "vector", "url": "pmtiles://{pack:world}",
          "attribution": "Made with Natural Earth; © GeoNames (CC BY 4.0)"}

# Under charts the base map isn't masked: chart coverage is opaque where it
# draws, and the base map's towns show beside it. False stops the base map
# at zoom 6 there instead, where chart packs start.
CHARTS_UNDER = True

PALETTES = {
    "osm-light": dict(water="#a9d4f5", ice="#f7fafc", urban="#e8e2da", river="#8cc3ee", country="#9b88b8",
                      state="#c3b3d6", road="#f0c27a", label="#55595e", place="#2f3337",
                      water_label="#4a86b8", halo="#ffffff"),
    "osm-dark": dict(water="#13283a", ice="#2c3238", urban="#2a2e35", river="#2b5578", country="#7d6b96",
                     state="#5a4d6d", road="#8a6a3c", label="#9aa3ad", place="#e6eaef",
                     water_label="#6f9cc7", halo="#1c2026"),
    "usgs-light": dict(water="#a6cbea", ice="#ffffff", urban="#e6dfd2", river="#5b9bd5", country="#8a7a9a",
                       state="#b9aec4", road="#e07b39", label="#555555", place="#333333",
                       water_label="#3d7fbf", halo="#ffffff"),
    "usgs-dark": dict(water="#13283a", ice="#2c3238", urban="#262a2f", river="#2b5578", country="#7d6b96",
                      state="#5a4d6d", road="#9a7440", label="#9aa3ad", place="#e6eaef",
                      water_label="#6f9cc7", halo="#161b20"),
    # Charts: open water is deep water (white on paper, darkest at night).
    "charts-light": dict(water="#ffffff", ice="#ffffff", urban="#e8dcbc", river="#8ec4ec", country="#7a6a4a",
                         state="#b7a98a", road="#c9bea4", label="#7a6a4a", place="#5b4a2c",
                         water_label="#3a6ea5", halo="#f3ead0"),
    "charts-dark": dict(water="#0c1e30", ice="#3a3f44", urban="#2c2922", river="#1f4a6b", country="#b8a07a",
                        state="#6b5d45", road="#4a4438", label="#a39d92", place="#d9c9a8",
                        water_label="#7fb0e0", halo="#22201b"),
}
REG, ITA, MED = ["Noto Sans Regular"], ["Noto Sans Italic"], ["Noto Sans Medium"]


def cls(*names):
    return ["match", ["get", "class"], list(names), True, False]


def layer(id_, type_, source_layer, paint, filter_=None, minzoom=None, layout=None, maxzoom=None):
    out = {"id": id_, "type": type_, "source": "world", "source-layer": source_layer}
    if filter_ is not None:
        out["filter"] = filter_
    if minzoom is not None:
        out["minzoom"] = minzoom
    if maxzoom is not None:
        out["maxzoom"] = maxzoom
    if layout:
        out["layout"] = layout
    out["paint"] = paint
    return out


def label(P, color, size, font=REG, width=8, **layout):
    # The renderer breaks a word wider than text-max-width, so the width
    # fits the longest single names ("MASSACHUSETTS", "Mediterranean").
    return ({"text-field": ["get", "name"], "text-font": font, "text-size": size, "text-max-width": width,
             "symbol-sort-key": ["get", "rank"], **layout},
            {"text-color": color, "text-halo-color": P["halo"], "text-halo-width": 1.5})


def layers(style_id):
    """(fills and lines for under the map, labels for above it)."""
    P = PALETTES[style_id]
    # Chart packs start at zoom 6, where the base map stops unless it's drawn
    # under them (CHARTS_UNDER).
    stop = 6 if style_id.startswith("charts") and not CHARTS_UNDER else None
    layer_ = lambda *args, **kwargs: layer(*args, **kwargs, maxzoom=stop)
    zoom = lambda *stops: ["interpolate", ["linear"], ["zoom"], *stops]
    land = ["==", ["get", "maritime"], 0]
    rank = ["get", "rank"]
    under = [
        layer_("world-urban", "fill", "landuse", {"fill-color": P["urban"]}, cls("residential"), 4),
        layer_("world-ice", "fill", "landcover", {"fill-color": P["ice"]}, cls("ice")),
        layer_("world-water", "fill", "water", {"fill-color": P["water"]}),
        layer_("world-river", "line", "waterway",
               {"line-color": P["river"], "line-width": zoom(3, 0.4, 6, 1, 10, 1.6)}),
        layer_("world-state", "line", "boundary",
               {"line-color": P["state"], "line-width": zoom(3, 0.5, 6, 0.9, 10, 1.3), "line-dasharray": [3, 2]},
               ["all", ["==", ["get", "admin_level"], 4], land], 3),
        layer_("world-country", "line", "boundary",
               {"line-color": P["country"], "line-width": zoom(1, 0.6, 6, 1.4, 10, 2),
                "line-dasharray": ["case", ["==", ["get", "disputed"], 1], ["literal", [3, 2]],
                                   ["literal", [1, 0]]]},
               ["all", ["==", ["get", "admin_level"], 2], land]),
        layer_("world-road", "line", "transportation",
               {"line-color": P["road"], "line-width": zoom(4, 0.5, 6, 1.2, 10, 2.2)},
               cls("motorway", "trunk", "primary"), 4),
    ]
    sea_layout, sea_paint = label(P, P["water_label"], zoom(1, 10, 6, 12), ITA, 10,
                                  **{"text-letter-spacing": 0.1})
    state_layout, state_paint = label(P, P["label"], 10, width=14, **{"text-transform": "uppercase",
                                                                       "text-letter-spacing": 0.08})
    city_layout, city_paint = label(
        P, P["place"], ["case", ["==", ["get", "capital"], 2], 12, ["<=", rank, 3], 11.5, 10.5],
        **{"text-variable-anchor": ["left", "right", "top", "bottom"], "text-radial-offset": 0.45})
    country_layout, country_paint = label(
        P, P["country"], ["step", rank, 15, 3, 13, 5, 11], MED, 12,
        **{"text-transform": "uppercase", "text-letter-spacing": 0.05})
    # GeoNames towns (rank 10-13 for 100,000, 25,000, 5,000 and 1,000 people,
    # below Natural Earth's 1-9) are names alone, centred on the town: a dot
    # can't hide with its name, and thousands of unnamed dots would crowd the
    # map. Each tier waits for its zoom however deep the data goes.
    town = lambda r: ["all", cls("town"), ["==", rank, r]]
    big_layout, big_paint = label(P, P["place"], 10.5)
    mid_layout, mid_paint = label(P, P["place"], 10)
    small_layout, small_paint = label(P, P["label"], 9.5)
    natural_earth = ["all", cls("city", "town"), ["<=", rank, 9]]
    labels = [
        layer_("world-sea-name", "symbol", "water_name", sea_paint, layout=sea_layout),
        layer_("world-state-label", "symbol", "place", state_paint, cls("state"), 4, state_layout),
        layer_("world-town-13", "symbol", "place", small_paint, town(13), 9, small_layout),
        layer_("world-town-12", "symbol", "place", mid_paint, town(12), 8, mid_layout),
        layer_("world-town-11", "symbol", "place", mid_paint, town(11), 7, mid_layout),
        layer_("world-town-10", "symbol", "place", big_paint, town(10), 6, big_layout),
        # The city's position, which its label sits beside.
        layer_("world-city-dot", "circle", "place",
               {"circle-radius": 2, "circle-color": P["place"], "circle-stroke-color": P["halo"],
                "circle-stroke-width": 0.8}, natural_earth),
        layer_("world-city", "symbol", "place", city_paint, natural_earth, layout=city_layout),
        layer_("world-country-label", "symbol", "place", country_paint, cls("country"), layout=country_layout),
    ]
    return under, labels


def add_to(style, style_id):
    """Puts the world source and layers into a style, replacing earlier ones:
    fills after the background, labels before the first symbol layer."""
    under_charts = style_id.startswith("charts") and CHARTS_UNDER
    style["sources"] = {**style["sources"], "world": {**SOURCE, "ovm:mask": False} if under_charts else SOURCE}
    under, labels = layers(style_id)
    rest = [l for l in style["layers"] if not l["id"].startswith("world-")]
    at = next(i for i, l in enumerate(rest) if l["type"] == "background") + 1
    rest[at:at] = under
    first_symbol = next(i for i, l in enumerate(rest) if l["type"] == "symbol")
    rest[first_symbol:first_symbol] = labels
    style["layers"] = rest


def dark_paint(style_id):
    """The world layers' paint in a dark style, for make_dark_variants.py."""
    return {l["id"]: l["paint"] for group in layers(style_id) for l in group}


def main(out):
    for style_id in ("usgs-light", "charts-light"):
        path = f"{out}/{style_id}.json"
        style = json.load(open(path))
        add_to(style, style_id)
        json.dump(style, open(path, "w"), indent=2, ensure_ascii=False)
        open(path, "a").write("\n")
        print(style_id, len(style["layers"]), "layers")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/styles")
