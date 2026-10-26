# traxpoi

Offline points of interest and addresses for MeshTrax. It opens a region's
downloaded SQLite files read-only and searches them, typos included. It has
no screens.

The files are built by traxmapmaker (FINDINGS §1.8, the `poi` module).
This README and the two schema files are the contract between the build
and the app.

## Files

| Download | File | Schema |
| --- | --- | --- |
| Points of interest | `points-of-interest.sqlite` | [`lib/src/db/points_schema.drift`](lib/src/db/points_schema.drift) |
| Addresses | `addresses.sqlite` | [`lib/src/db/addresses_schema.drift`](lib/src/db/addresses_schema.drift) |

The schema files are plain SQLite. The build:
1. runs the schema file;
2. fills the tables;
3. fills each search index from its table:
   `INSERT INTO name_search (name_search) VALUES ('rebuild')` and
   `INSERT INTO street_search (street_search) VALUES ('rebuild')`;
4. fills `place_area` with each place's point (min = max);
5. sets `PRAGMA user_version = 1`, the schema version.

The app refuses a file with any other version, so a new schema needs a new
app.

### meta

| name | value |
| --- | --- |
| `build` | the build id |
| `build_date` | ISO date |
| `region` | picker path, e.g. `test/san-juans` |
| `attribution` | the credit line for the sources used, e.g. `© OpenStreetMap contributors · USGS GNIS · Wikipedia` |

### place

- **`name`**: the display name, or `''` for an unnamed place (see name).
- **`kind`**: one of the kinds below, OpenStreetMap-style. The app picks the icon and the translated type label from it.
- **`detail`**: an optional English type that is more specific than the kind, e.g. "Aerial tramway". The sheet shows it next to the label.
- **`lat`/`lon`**: the routing point.
- **`ele`**: metres.
- **`heritage`**: e.g. `nrhp:74000514`.
- **Source ids:** `wikidata` (`Q109973327`), `osm` (`n123`, `w972224775` or `r5`) and `gnis`.
- **`sources`**: the merged sources, comma-separated: `osm,wikidata,gnis,nrhp`.
- **`rank`**: 0 for none, 1 when the place has a Wikipedia article, 2 when it also has a heritage listing.

| Group | Kinds |
| --- | --- |
| Nature | `natural=peak` `natural=volcano` `natural=saddle` `mountain_pass=yes` `natural=spring` `natural=hot_spring` `waterway=waterfall` `natural=cave_entrance` `natural=arch` `natural=glacier` `natural=rock` `natural=stone` `natural=cliff` `natural=beach` |
| Trails and camping | `highway=trailhead` `tourism=camp_site` `tourism=picnic_site` `tourism=wilderness_hut` `tourism=alpine_hut` `amenity=shelter` `amenity=drinking_water` `amenity=water_point` `amenity=toilets` |
| Views | `tourism=viewpoint` `tourism=attraction` |
| History | `historic=ruins` `historic=monument` `historic=memorial` `historic=fort` `historic=castle` `historic=ghost_town` `historic=mine` `man_made=mineshaft` `man_made=adit` `historic=yes` (any other named historic place, with `detail`) |
| Services | `amenity=ranger_station` `tourism=visitor_centre` `amenity=hospital` `amenity=police` `amenity=fire_station` `emergency=phone` `amenity=fuel` |
| Museums | `tourism=museum` (public and park museums only) |

### feature (search only)

| Kind | For |
| --- | --- |
| `place=city` `place=town` `place=village` `place=hamlet` `place=locality` | towns and named areas |
| `natural=water` | lakes and reservoirs |
| `waterway=river` `waterway=stream` | rivers and creeks |
| `natural=valley` `natural=ridge` `natural=mountain_range` `natural=gorge` | landforms |
| `highway=path` `highway=track` `highway=road` | trails, dirt roads and other roads, one feature per name per area. `shape` holds the line. |

### name

Every searchable name: one row per name of a place or a feature. `role` is
`main`, `alt`, `old`, `official`, `short` or `redirect` (a Wikipedia
redirect). `norm` is the name normalized as below.

A place with no name (an unnamed spring, toilet or trailhead) has
`place.name` = `''` and no rows here: it's an icon on the map with its own
sheet, but search never finds it by name. Features always have a name.

### photo

WebP, at most 320 px on the long side, quality 75. `file` is the Commons
file name. `author` and `licence` are plain text, e.g. "LCGS Russ" and
"CC BY 3.0".

## Name normalization

Both sides normalize names the same way. The build stores normalized names
in `name.norm` and `street.norm`, and the app normalizes only what you type.
[`lib/src/normalize.dart`](lib/src/normalize.dart) is the reference, and
[`test/normalize_vectors.json`](test/normalize_vectors.json) holds the cases
both sides must pass.

1. Drop apostrophes: `'` `’` `‘` `ʼ` and the backtick.
2. Write `&` as ` and `.
3. Fold accented Latin letters to ASCII with the table in `normalize.dart`.
   Don't use Unicode NFKD: it drops ø, ł and æ instead of folding them.
4. Lowercase.
5. Make every character that isn't `a–z` or `0–9` a space.
6. Split into words and expand abbreviations: place names with the place
   table, streets with the address table ("st" is saint in a place name and
   street in an address).
7. Join the words with single spaces.

## Search

1. **Candidates:** the trigram index finds every name that shares a trigram
   with a typed word. A typed name shorter than three letters is matched by
   prefix instead.
2. **Match:** each typed word must closely match a word of the name, or the
   start of one. The average of those word matches is the name's match.
3. **Order:** good matches first, then nearer ones. Notable places get a lift,
   and names much longer than what was typed get a small cost.
4. **Addresses:** the house number must match exactly. The street name, city
   or ZIP may have typos.
