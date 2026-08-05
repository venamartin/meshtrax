# /// script
# requires-python = ">=3.11"
# dependencies = []
# ///
"""Generate MeshTrax path-graph seed files from Corescope instances.

For each known Corescope instance, fetches the neighbor graph and node
list, then writes one `meshtrax-graph-v1` node-link JSON file per region
(the format is the D3/NetworkX node-link convention — see
docs/path-graph-design.md, "Corescope export utility").

The file is lossless: full 64-hex pubkeys as node ids, positions and
last-heard included. The app geo-filters and collapses to 2-byte hash
buckets at import time, not here.

Usage:
  uv run tools/generate_graph.py                    # all regions
  uv run tools/generate_graph.py --region bayarea   # one region
  uv run tools/generate_graph.py --out-dir dist
"""

import argparse
import json
import sys
import urllib.request
from datetime import datetime, timezone
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8")

# ── known Corescope instances ──────────────────────────────────────────────
# Add new regions here as more Corescope deployments appear.
SOURCES = [
    {"region": "bayarea", "url": "https://corescope.stonekitty.net"},
]

GRAPH_ENDPOINT = "/api/analytics/neighbor-graph"
NODES_ENDPOINT = "/api/nodes?limit=10000"

KEEP_ROLES = {"repeater", "room"}

# Edge endpoints that arrive as a hash prefix ("prefix:XXXX") are resolved
# against known pubkeys. 1-byte prefixes (2 hex chars) are too ambiguous to
# resolve and are always dropped (matches the module's 2-byte-only rule).
MIN_PREFIX_HEX = 4


def fetch_json(url):
    print(f"  fetching {url}", file=sys.stderr)
    with urllib.request.urlopen(url) as resp:
        return json.load(resp)


def clean_position(lat, lon):
    """Return (lat, lon) or (None, None) — (0, 0) means 'not set'."""
    if lat is None or lon is None or (lat == 0 and lon == 0):
        return None, None
    if -90 <= lat <= 90 and -180 <= lon <= 180:
        return lat, lon
    return None, None


def resolve_endpoint(value, kept_pubkeys, drops):
    """Map an edge endpoint to a kept full pubkey, or None (counted)."""
    if value in kept_pubkeys:
        return value
    if value.startswith("prefix:"):
        prefix = value.removeprefix("prefix:").lower()
        if len(prefix) < MIN_PREFIX_HEX:
            drops["prefix_1byte"] += 1
            return None
        matches = [pk for pk in kept_pubkeys if pk.lower().startswith(prefix)]
        if len(matches) == 1:
            return matches[0]
        drops["prefix_unresolved"] += 1
        return None
    drops["endpoint_not_kept"] += 1  # full pubkey, but a filtered-out role
    return None


def build_region(region, base_url):
    graph_data = fetch_json(base_url + GRAPH_ENDPOINT)
    nodes_data = fetch_json(base_url + NODES_ENDPOINT)

    # Position + last-heard enrichment, keyed by pubkey.
    detail = {n["public_key"]: n for n in nodes_data.get("nodes", []) if n.get("public_key")}

    nodes = []
    for n in graph_data["nodes"]:
        if n.get("role") not in KEEP_ROLES:
            continue
        info = detail.get(n["pubkey"], {})
        lat, lon = clean_position(info.get("lat"), info.get("lon"))
        nodes.append(
            {
                "id": n["pubkey"],
                "name": n.get("name", ""),
                "role": n["role"],
                "lat": lat,
                "lon": lon,
                "last_heard": info.get("last_heard"),
            }
        )
    kept_pubkeys = {n["id"] for n in nodes}

    links = []
    drops = {"prefix_1byte": 0, "prefix_unresolved": 0, "endpoint_not_kept": 0}
    for e in graph_data["edges"]:
        source = resolve_endpoint(e["source"], kept_pubkeys, drops)
        target = resolve_endpoint(e["target"], kept_pubkeys, drops)
        if source is None or target is None:
            continue
        links.append(
            {
                "source": source,
                "target": target,
                "score": round(e.get("score") or 0, 4),
                "avg_snr": round(e["avg_snr"], 1) if e.get("avg_snr") is not None else None,
                "bidirectional": bool(e.get("bidirectional")),
                "weight": e.get("weight"),
            }
        )

    document = {
        "format": "meshtrax-graph-v1",
        "directed": True,
        "multigraph": False,
        "graph": {
            "generated_at": datetime.now(timezone.utc).isoformat(timespec="seconds"),
            "region": region,
            "source": base_url,
            "hash_width": 2,
        },
        "nodes": nodes,
        "links": links,
    }

    total_nodes = len(graph_data["nodes"])
    total_edges = len(graph_data["edges"])
    print(
        f"  {region}: kept {len(nodes)}/{total_nodes} nodes ({', '.join(sorted(KEEP_ROLES))}), "
        f"{len(links)}/{total_edges} edges "
        f"(dropped: {drops['prefix_1byte']} 1-byte prefix, "
        f"{drops['prefix_unresolved']} unresolved prefix, "
        f"{drops['endpoint_not_kept']} filtered-role endpoint)",
        file=sys.stderr,
    )
    return document


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--region", help="generate only this region (default: all)")
    parser.add_argument("--out-dir", default=".", help="output directory (default: current)")
    args = parser.parse_args()

    sources = SOURCES
    if args.region:
        sources = [s for s in SOURCES if s["region"] == args.region]
        if not sources:
            known = ", ".join(s["region"] for s in SOURCES)
            sys.exit(f"Unknown region {args.region!r} — known: {known}")

    out_dir = Path(args.out_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    for source in sources:
        print(f"{source['region']} ({source['url']})", file=sys.stderr)
        document = build_region(source["region"], source["url"])
        out_path = out_dir / f"meshtrax-graph-{source['region']}.json"
        with open(out_path, "w", encoding="utf-8") as f:
            json.dump(document, f, indent=1, ensure_ascii=False)
            f.write("\n")
        print(f"  wrote {out_path}", file=sys.stderr)


if __name__ == "__main__":
    main()
