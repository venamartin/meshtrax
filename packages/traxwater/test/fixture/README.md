# Water routing engine fixture, build 2026112401

Cut from build 2026112401 by `experiments/water_routing/fixture.py` (traxmapmaker,
FINDINGS.md 1.11). Each set's tiles are WRM2 tiles exactly as they are in the
build's bundles; its `trips.json` has, for each trip, the test router's
command-line settings (`args`, as `experiments/water_routing/route.py` takes
them), what the trip tests, and the router's whole result. Each set's trips ran
over that set's tiles alone, so an engine given the same tiles should find
the same trips.

- `monterey/`: 2 tiles, 1,276 kB. Monterey Bay: a 1 nm trip in open water through the Monterey Bay security zone (listed, not avoided).
  - Monterey to Moss Landing, 1 nm off: 13.4 nm, 7 legs.
- `carquinez/`: 2 tiles, 2,065 kB. San Pablo Bay to Suisun Bay through Carquinez Strait: water too narrow for 1 nm, a security zone at Rodeo, and the Carquinez and Benicia bridges (one of them a lift bridge).
  - San Pablo Bay to Suisun Bay, 1 nm off, distance first only: 18.52 nm, 13 legs.
  - San Pablo Bay to Suisun Bay, 1 nm off: 18.56 nm, 12 legs.
  - San Pablo Bay to Suisun Bay, 25 m mast: 18.72 nm, 7 legs.
  - San Pablo Bay to Suisun Bay, 25 m mast, avoid bridges that open: no route.
- `antimeridian/`: 2 tiles, 210 kB. Open water across the 180 degree meridian in the Aleutians: one tile each side of it.
  - Across the 180 degree meridian: 15.0 nm, 1 leg.

What to compare (the test router samples every 25 m, so its numbers are
approximate):
- `distance_nm` within about 1%, and `legs` within a few;
- `error: "no route"` exactly;
- `through.areas`: the same area ids with at least 0.05 nm, each `nm` within
  about 0.05 nm, and `air_draft` notes ("needs opening") exactly;
- `through.security_zone_nm` and `through.off_land` (`nm_inside_elsewhere`,
  the `couldnt_keep` stretches) within about 0.05 nm;
- `through.lowest_clearance.clearance_m` exactly;
- `search.expanded` the same, for an engine that searches the same way (ties
  and float rounding can move it a little). The A* runs over edge crossings:
  from the start point, or the middle of the edge a triangle was entered by,
  to the middle of an edge it's left by, at that triangle's cost, never
  straight back into the triangle just left, then on to the end point. The
  metres inside the distance off are kept in whole centimetres (each step
  adds its own, rounded). A crossing off the queue is skipped if one into
  the same triangle already taken (or the start point, in the start's
  triangle) reaches its point for no more in both values, or if the same
  edge crossed the other way is reached for strictly less; a crossing isn't
  pushed if the other way is reached for no more. `expanded` counts the
  start, each crossing taken and the end.

The funnel narrows each portal at both ends by 50 m, or a quarter of its
width if less, before it pulls the trip taut, so turns keep off the banks.

Settings not in `args` are route.py's defaults: 6 ft draft, 2 ft margin,
6 kn, no distance off land, no mast height; security zones, traffic lanes
and separation zones cost 100 times a metre of open water; security zones
come first only where the distance off can't be kept; with a mast height,
uncharted clearances block and opening bridges count open.
