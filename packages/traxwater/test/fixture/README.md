# Water routing engine fixture, build 2026112401

Cut from build 2026112401 by `experiments/water_routing/fixture.py` (traxmapmaker,
FINDINGS.md 1.11). Each set's tiles are WRM2 tiles exactly as they are in the
build's bundles; its `trips.json` has, for each trip, the test router's
command-line settings (`args`, as `experiments/water_routing/route.py` takes
them), what the trip tests, and the router's whole result. Each set's trips ran
over that set's tiles alone, so an engine given the same tiles should find
the same trips.

- `monterey/`: 2 tiles, 1,276 kB. Monterey Bay: a 1 nm trip in open water through the Monterey Bay security zone (listed, not avoided).
  - Monterey to Moss Landing, 1 nm off: 14.54 nm, 4 legs.
- `carquinez/`: 2 tiles, 2,065 kB. San Pablo Bay to Suisun Bay through Carquinez Strait: water too narrow for 1 nm, a security zone at Rodeo, and the Carquinez and Benicia bridges (one of them a lift bridge).
  - San Pablo Bay to Suisun Bay, 1 nm off, distance first only: 18.88 nm, 16 legs.
  - San Pablo Bay to Suisun Bay, 1 nm off: 18.95 nm, 15 legs.
  - San Pablo Bay to Suisun Bay, 25 m mast: 19.06 nm, 9 legs.
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
- `through.lowest_clearance.clearance_m` exactly.

Settings not in `args` are route.py's defaults: 6 ft draft, 2 ft margin,
6 kn, no distance off land, no mast height; security zones, traffic lanes
and separation zones cost 100 times a metre of open water; security zones
come first only where the distance off can't be kept; with a mast height,
uncharted clearances block and opening bridges count open.
