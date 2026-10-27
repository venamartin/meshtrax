# Parks on the map

This file covers the app side of parks: national parks, monuments, preserves and state parks shown on the offline map with an outline, a light tint and their name, and a tap that opens the park's sheet. Built so far: the style, the desert parks from the map hints and the Parks switch (2026-10-26). Parks as places, for the tap, are still to come.

**Data side:** traxmapmaker's [`FINDINGS.md`](https://github.com/venamartin/traxmapmaker/blob/main/FINDINGS.md): §1.9 (map hints) for the desert parks and §1.8 (Points of interest) for parks as places.

## Direction (Martin, 2026-10-26)

Parks come from data users already download. There's no separate parks download.

| Part | Where it comes from |
| --- | --- |
| Outline and tint | The `park` layer already in the `osm` map packs: every protected area's outline and protection type (`class`), with a center point carrying its name and rank. |
| Green or desert tan | The desert parks list in the map hints (`hints.json`, see [`offline-maps.md`](offline-maps.md)): traxmapmaker picks the parks whose land is mostly sand, rock or scrub. The style fills in `{list:desert-parks}`; every other park is green. No pack is rebuilt. |
| Name and tap | Parks as places in the Points of interest download, at the park's center, with their Wikipedia text and photo. A tap opens the place sheet. |

**Which areas:**

| Class | Shown as |
| --- | --- |
| `national_park`, `national_monument`, `national_preserve`, `state_park` | Tint, outline and centered name |
| `wilderness_area`, `national_forest` | A thin outline only |
| Everything else (BLM land, `protected_area`, study areas, refuges and so on) | Nothing. Today's style tints all of these, which colors much of the West. |

**Offline mode only** (Martin, 2026-10-26). In Online mode the map is raster tiles and parks aren't drawn.

**Switch:** a Parks tile in the layers sheet (Map details), on by default, beside Places. It drops the park layers from the style, as the contours switch does. In Online mode it reads "Offline only" and is greyed out, like Contours.

**Names:** where the Points of interest download covers the view, the app draws park names as tappable labels, and the style's own park names step aside (the `appPlaces` mechanism the place icons already use). Elsewhere the style draws the names from the map packs.

## Replaces the NPS overlay design

The design of 2026-10-18 planned an `nps` overlay pack per region: official NPS trails and visitor points, NPS symbols and road shields, a Park style family and a font change (traxmap tasks T8–T12). Martin dropped it on 2026-10-26:
- Points of interest now covers the visitor points, with Wikipedia text.
- OpenStreetMap trails cover the trails and are routable.
- The park boundaries are already in the map packs.

What the NPS print look would have added (palette, shields, font) isn't planned. NPS's public visitor points may still come in later as a source for Points of interest positions.

## Open

- **A park split across regions:** its center point is in only one region's pack. Death Valley's outline is in the Southern California pack, but its center isn't. traxmapmaker to propose a fix (for example, a center point per region part).
- **Zooms** for the tint, outline and names, and the name style: settled with a preview, light and dark.
- **Wording:** "Parks", never "NPS style", so nothing implies NPS endorsement.
