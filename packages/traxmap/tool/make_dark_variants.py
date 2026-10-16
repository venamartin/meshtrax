"""Derives the dark styles from the light ones: usgs-dark, charts-dark.

The light styles are the source of truth (layers, filters, zooms); this only
swaps colours, layer by layer, so a change to a light style carries over
when this is rerun:

    python3 tool/make_dark_variants.py assets/styles
"""
import copy
import json
import sys

OUT = sys.argv[1] if len(sys.argv) > 1 else "assets/styles"

HALO = {"text-halo-color": "#161b20"}

USGS_DARK = {
    "background": {"background-color": "#1a1e22"},
    "elev_band": {"fill-color": ["interpolate", ["linear"], ["get", "band_ft"],
                                 500, "#1d2226", 1000, "#20262a", 1500, "#242a2c",
                                 2000, "#282d2e", 3000, "#2d3130", 5000, "#333533", 8000, "#3d3f3d"]},
    "woodland": {"fill-color": "#1f2d24"},
    "hillshade": {"fill-color": ["case", ["<", ["get", "level"], 0], "#ffffff", "#000000"],
                  "fill-opacity": ["match", ["get", "level"], -1, 0.05, 1, 0.12, 2, 0.22, 3, 0.32, 4, 0.42, 0]},
    "reserve": {"line-color": "#3f6b4a"},
    "water": {"fill-color": ["match", ["get", "kind"], "marsh", "#17302c", "#13283a"]},
    "waterway": {"line-color": "#2b5578"},
    "coastline": {"line-color": "#3c6d96"},
    "contour": {"line-color": "#6b5a47"},
    "rail": {"line-color": "#555b63"},
    "road": {"line-color": ["match", ["get", "kind"], "motorway", "#9a7440", "major", "#7a6748",
                            "track", "#5e5040", "#4a4f55"]},
    "trail": {"line-color": "#d0705f"},
    "poi": {"circle-color": "#9b6fb3"},
    "contour-label": {"text-color": "#a08c72", **HALO},
    "contour-label-m": {"text-color": "#a08c72", **HALO},
    "road-label": {"text-color": "#c9d0d8", **HALO},
    "trail-label": {"text-color": "#e08a7a", **HALO},
    "poi-label": {"text-color": "#aab3bd", **HALO},
    "place-label": {"text-color": "#e6eaef", **HALO},
}

NAV = ["match", ["get", "colour"], "red", "#ff4d5e", "green", "#3ccf6e", "yellow", "#ffd23f",
       "white", "#f2f2f2", "black", "#9aa0a6", "orange", "#ff9f43", "#9aa0a6"]
CHARTS_DARK = {
    # Night chart: deep water darkest, shallows lighter, so danger stays the eye-catcher.
    "background": {"background-color": "#22201b"},
    "depth-area": {"fill-color": ["step", ["get", "drval1"], "#2f3a24", 0, "#1f4a6b", 5, "#173a57",
                                  18, "#112c44", 30, "#0c1e30"]},
    "dredged-outline": {"line-color": "#4f7fa8"},
    "land": {"fill-color": "#22201b"},
    "road": {"line-color": "#4a4438"},
    "depth-contour": {"line-color": "#3f6f99"},
    "coastline": {"line-color": "#b8a07a"},
    "islet": {"circle-color": "#22201b", "circle-stroke-color": "#b8a07a"},
    "hazard-area": {"line-color": "#d8d8d8"},
    "hazard": {"circle-color": ["match", ["get", "kind"], "wreck", "#e05aa8", "#e0e0e0"],
               "circle-stroke-color": "#0c1e30"},
    "light-flare": {"circle-color": "#ff4fb8", "circle-opacity": 0.45},
    "nav-aid": {"circle-color": NAV, "circle-stroke-color": "#0c1e30"},
    "depth-contour-label": {"text-color": "#8fbde6", **HALO},
    "depth-contour-label-m": {"text-color": "#8fbde6", **HALO},
    "sounding": {"text-color": "#9ec3e6"},
    "sounding-m": {"text-color": "#9ec3e6"},
    "hazard-label": {"text-color": "#f08cc6", **HALO},
    "light-label": {"text-color": "#ff7fc8", **HALO},
    "nav-aid-label": {"text-color": "#d8dde3", **HALO},
    "sea-name": {"text-color": "#7fb0e0", **HALO},
    "place-label": {"text-color": "#d9c9a8", "text-halo-color": "#22201b"},
}


def derive(light: str, dark: str, name: str, overrides: dict) -> None:
    style = json.load(open(f"{OUT}/{light}.json"))
    out = copy.deepcopy(style)
    out["name"] = name
    out["metadata"] = {**style.get("metadata", {}), "ovm:theme": "dark", "ovm:dark": True,
                       "ovm:status": f"Generated from {light}.json by tool/make_dark_variants.py."}
    missing = set(overrides) - {l["id"] for l in out["layers"]}
    if missing:
        raise SystemExit(f"{light}: no layers {sorted(missing)}")
    for layer in out["layers"]:
        layer.setdefault("paint", {}).update(overrides.get(layer["id"], {}))
    json.dump(out, open(f"{OUT}/{dark}.json", "w"), indent=2, ensure_ascii=False)
    open(f"{OUT}/{dark}.json", "a").write("\n")
    print(dark, len(out["layers"]), "layers")


derive("usgs-light", "usgs-dark", "USGS (dark)", USGS_DARK)
derive("charts-light", "charts-dark", "NOAA Charts (dark)", CHARTS_DARK)
