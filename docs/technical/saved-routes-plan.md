# Saved routes: plan

> **What this is:** The build plan for keeping routes: saving the route the map finds, organising, editing, importing and exporting them as GPX, and sharing them over the mesh. It builds on the offline routing in #210 and on location sharing (plan in #240). Owner decisions are from Martin's route notes and his answers on 2026-11-05. App facts were checked against master `ff0df0f5` and #210's head that day. The session building #210 then rechecked everything this plan takes from #210 against its head `9ba6f98`: heights, place links, place photos, credits and the routing calls.
>
> **Who it's for:** the developer or AI session building it.
>
> **Status:** active plan, nothing built. The work happens on branch `feat/saved-routes` (draft PR).
>
> New to the terms? See the [glossary](../glossary.md).

## The feature in one paragraph

When the map finds a route, it becomes the **active route**, and **Save** keeps it. A saved route has:
- a name, notes, named stops, tags and one photo
- its line, its height profile, its path type, and its distance, time and climb

Saved routes show on the map in a **Routes** layer, and in a **Routes** list reached from the Map screen. In the list, each card shows the route on a small map, with its photo.

Any route can be edited: move, add or delete points, and make each stretch either follow paths or run straight. Routes can be imported and exported as GPX, and shared over the mesh:
- a planned route as a short, readable message that MeshTrax rebuilds with offline routing
- a recorded track as compressed packets on a private channel

Your own recorded track, and other people's trails from location sharing, can be saved as routes.

## Start here: working rules

These are the same rules as in #240's plan, shortened. A session in a new worktree doesn't see the project memory.

**Git**
- `git fetch origin`, then branch from `origin/master`. Work in a worktree.
- Never commit on master. Stage named files only, never `git add -A`.
- Commit locally. Push only when Martin has tested and says so: the repo is public.
- "Ship it" means push, PR, wait for the `analyze` check, squash-merge, clean up, sync master. It never means a store release.

**Test builds**
- Bump the version above what is on Martin's phone (1.9.9+166 or higher on 2026-11-05), commit the bump, then build with `./buildapk.sh`.
- A worktree needs `buildapk.sh`, `android/key.properties`, `giphy.key` and `pubspec.lock` copied from the main checkout. Never commit `giphy.key`.
- Ask whether the bump stays in the PR.

**Look before an APK.** Martin wants to see visual work before it is built.
- Render each new screen at phone size (1080×2340 at 2.625) with real fonts (Roboto and Material Icons from `~/flutter/bin/cache/artifacts/material_fonts/`), and show him the pictures first.
- Widget tests use a block font and hide layout problems.

**Radios**
- Firmware truth is `./MeshCore` (companion-v1.18.0), in the main repo folder.
- Heavy or repeated sends go on 920.000 MHz only; at most a couple of frames on the live mesh (910.525).
- Ask before touching repeater F857.

**Text and data**
- Plain words on screen.
- Every new string goes in all 17 language files.
- Dates go through `DateTimeHelper`, distances and heights through `GeoFormat` with the user's units, and coordinates through #210's coordinate-format setting.
- Never name other apps.

**Database**
- Migrations must survive an interrupted first launch: `createTable`, and add indexes and columns only if they're missing. `app_database.dart`'s `_createIndexIfMissing` shows how.

**Tests and repo gotchas**
- Inject clocks.
- Known Windows-only failures: `contact_advert_evidence_test`, and traxmap's `style_registry_test` (4) and `gap_fill_provider_test` (2).
- After a test run, line-ending churn appears in `lib/l10n/` and the plugin registrants: `git checkout -- lib/l10n linux macos windows`.
- `build_runner --delete-conflicting-outputs` deletes the checked-in `lib/l10n/*.dart`; restore them from git.

**Asking Martin**
- Put open decisions in the question dialog, with your recommendation first.
- Don't start review agents unless he asks.

## Owner decisions

| Topic | Decision |
|---|---|
| Active route | A route found by the route panel becomes the active route; Save keeps it. There is one active route. It is drawn in its own colour and stays visible with the Routes layer off. No navigation for now. |
| What a route holds | Name, notes, named stops, one photo at a standard size, tags. Also the line, height profile, path type, options, distance, time and climb. |
| Routes layer | A switch in the map's layers sheet that draws the saved routes |
| Routes list | Reached from the Map screen (menu entry and the route panel's Save). No third bottom tab. Cards show a small map and the photo. |
| Editor | Its own screen. Any route can be edited, or a new one made. Points can be added, moved and deleted. Each stretch follows paths of the route's type, or runs straight for off-trail parts. One path type per route, as decided for #210 on 2026-10-25. |
| Recorded and imported tracks | After simplifying, their points become straight stretches, so they keep their exact shape and edit the same way |
| Size | Routes are simplified when saved, within reason |
| GPX | Import and export |
| Organising | Tags, with filter chips |
| Stops | Your own named points along the route. Each can link to a place from #210's points-of-interest search. |
| Backups | Saved routes are your content: they go in phone backups and in Export database. The raw recorded track from location sharing stays out, as #240 plans. |
| Sharing a planned route | A readable `Route:` text message with its waypoints and path type; MeshTrax rebuilds it. MeshTrax only for now: not added to the public [message format](../message-format.md). |
| Sharing a recorded track | Compressed line packets, private channels only. They may go through repeaters. |
| With location sharing | First version: save my track as a route, save someone's shared trail as a route, share a route to the channel. Later: members' active routes on the map during a session. |

## Order of work and dependencies

| Step | What | Can start |
|---|---|---|
| R1 | Route library: save, active route, Routes layer, Routes list and details, photo | after #210 merges |
| R2 | GPX import and export | after R1 |
| R3 | Route editor | after R1 |
| R4 | Sharing: `Route:` message, track packets | `Route:` after R1. Track packets need `packages/traxshare` (#240's Step 2) on master. |
| R5 | Links with location sharing | after #240's Step 3 is on master |

#240 is planned as one feature PR, so its package may not reach master until the end. Before R4's track packets, ask Martin whether #240's package should land on master on its own first.

Each step is one commit series on this branch, with Martin testing on a phone between steps.

## R1: route library

**Database:** `AppDatabase` schema 9, the app's own database.
- It is not tied to a radio: routes belong to the person, so there is no node scope.
- It is included in phone backups and Export database, as decided.

```
routes(
  id INTEGER PK, saved BOOL, name TEXT, notes TEXT,
  path_type TEXT NULL,          -- paved | dirt | hiking; NULL for a track
  options_json TEXT NULL,       -- traxroute RouteOptions.toJson()
  source TEXT,                  -- planned | track | gpx | shared
  km REAL, seconds REAL NULL, climb_up_m REAL NULL, climb_down_m REAL NULL,
  min_lat, min_lon, max_lat, max_lon,   -- for drawing only what is in view
  line BLOB,                    -- see "Line storage"
  heights BLOB NULL,            -- see "Heights"
  height_step_m REAL NULL,
  credits TEXT NULL,            -- see R2's export
  created_at, updated_at)
route_waypoints(route_id, seq, lat, lon, straight_after BOOL)
route_stops(route_id, seq, name, lat, lon, note TEXT NULL,
            place_region TEXT NULL, place_key TEXT NULL)
route_tags(route_id, tag)       -- compared case-insensitively
route_photos(route_id PK, image BLOB, width, height,
             author TEXT NULL, licence TEXT NULL, licence_url TEXT NULL)
```

**Fields:**
- `route_waypoints` are the points the editor moves.
  - A planned route has a few, with `straight_after` false except on off-trail stretches.
  - A track's simplified points all have `straight_after` true.
- `route_stops` keep a copy of the name and position, so a stop survives a points-of-interest pack update. `place_key` is only a link back to the place's text and photo.
  - It is the key search already builds to match one place across regions' files (`SearchResult.key` in traxpoi): the place's `osm` id, else its `wikidata` id, else its name and position.
  - Not `place.id`: that is a row number in a file rebuilt every month, so after an update it can point at another place.
  - traxpoi has no lookup by that key yet, only `placeById`. Add one to `points.drift`. The file has no index on `osm`, but a scan is fine for one stop.

**Line storage:** one blob per route. Each point is `lat` and `lon` as int32 in millionths of a degree, little-endian. It is quick to load in one read, and needs no codec. Heights are kept apart, below.

**Heights:** a second blob, the height profile. It holds int16 metres every `height_step_m` along the line, little-endian, with 0x7FFF where a height is unknown. That's about 7 KB per 100 km.
- This is the shape #210 already has. `RouteResult.elevations` holds a sample every `elevationIntervalM` (30 m) along the route, not one per point. `ElevationProfile` draws them evenly spaced, and `RouteResult.climb` counts them the same way.
- A height per point of the simplified line would lose the hills: a straight road over a ridge keeps only its two ends.
- A track, or a GPX `trk` with `ele`, is sampled every 30 m by distance along all its points, before simplifying.
- GPX export gives each point the height at its distance along the line.
- With no heights at all, `heights` is NULL. That happens in a region built without them, where #210's route has none either.

**Simplify on save:**
- 2D Douglas–Peucker at 5 m, so the shape holds at street zoom; keep the tolerance in a constants block.
- Never drop a waypoint's or a stop's position.
- Heights aren't simplified: they are already in the profile.

**Active route:**
- In #210 the route lives in the map screen's state: `_routeTo` (name and point), `_routeFrom` (null means your position), `_pathType` and `_route`, set by `_findRoute`. The options come from `settings.routeOptions`.
- When the route panel finds a route, it is written as a row with `saved` false, replacing any earlier unsaved row. It survives a restart, until it is cleared or replaced.
- The route panel (`lib/widgets/route_panel.dart`, added by #210) gets **Save**, which asks for a name, prefilled with the destination's name, and sets `saved`.
- The active route id is kept in a preference. A saved route can be made active from its card.

**Map:**
- A **Routes** switch goes in the layers sheet, next to #210's Places and Parks. It needs a picture like the other entries. Since #241 those are drawn by the app's own styles from real packs, at the tile's size.
- **Colours:** saved routes are drawn thin and neutral. The active route uses #210's `routeColor` at width 5, its current look. With the switch off, only the active route shows.
- **Performance:**
  - Draw only routes whose box meets the view, and thin each line to the zoom.
  - The map rebuilds its overlays on every connector notify. #210 adds a rebuild 300 ms after every pan at zoom 12 and above, when it loads the places in view. Map drawing is the app's main known cost (Windows profile, 2026-10-31). Keep the built overlays and reuse them until a route changes.

**Routes list:**
- Opened from the Map screen's menu.
- Search by name, tag filter chips, newest first.
- Each card: photo if any, a small map of the line, name, tags, distance, time, climb and path type.
- Draw the card's map once and keep it as an image, keyed by route id and `updated_at`. A live map on every card would be costly in a long list. Where no offline map covers the route, draw the line on a plain background.

**Route details:**
- name, notes, tags, stops and photo
- distance, time and climb, with heights in the user's units
- #210's `ElevationProfile`
- actions: **Show on map**, **Make active**, **Edit**, **Share**, **Export GPX**, **Delete**

**Photo:**
- One per route, from the gallery or the camera.
- The app already declares the camera and uses `image_picker` for QR codes, so no new permission is needed.
- Scale it to 1280 px on the long side and save it as JPEG.
- It is never sent over the mesh.
- A route to a place starts with that place's photo from the points-of-interest download, if it has one.
  - Those photos are WebP, at most 320 px, from Wikipedia or Wikimedia Commons, each with an author and a licence.
  - The place sheet credits them (`place_photoCredit`), and the route card and details must credit a copied photo the same way.
  - Keep the photo as it comes, with its `author`, `licence` and `licence_url`. Only your own photos are scaled and saved as JPEG, and their credit columns stay NULL.

## R2: GPX import and export

The app already depends on the `gpx` package (contact export in [gpx_export.dart](../../lib/utils/gpx_export.dart)) and on `file_selector` and `share_plus`.

**Export:**
- the line as a `trk` with `ele` from the height profile
- a planned route's waypoints as an `rte`
- stops as `wpt`
- the name and notes as `name` and `desc`; tags as `keywords` in `metadata`
- a found route's `credits`, also in `metadata`
  - Its line comes from OpenStreetMap data and its heights from USGS or Copernicus, and their licences ask for credit.
  - Save the credits with the route from `RoutingService.credits` and `notices` (#210), one per line, since the routing data may be removed later.
  - Your own tracks need none.

**Import:**
- An `rte` becomes a planned route: its points are waypoints, and the importer asks for a path type.
- A `trk` becomes a track. Its `ele` values are sampled into the height profile, then it is simplified at 5 m, with its points as straight stretches.
- `wpt` points become stops.
- Large files (tens of thousands of points) are simplified before saving.

## R3: route editor

Its own screen: the map with the route, its points and an action bar.
- **Points:** tap the map to add a point at the end; drag a point to move it; long-press to delete; tap a stretch to insert a point or switch it between **follow paths** and **straight**.
- **Route settings:** path type and options, one per route.
- **Other actions:** reverse, undo, stops, and save, either as a new route or over the old one.
- **Routing:**
  - Routed stretches are found one stretch at a time, then the shapes are joined. Each call is `RoutingService.route(a, b, type, options: …)`, which sends `RouteRequest([a, b], type, options: …)`; its arguments are positional. The engine takes several points at once (`packages/traxroute/lib/src/valhalla.dart`), but stretch by stretch lets straight stretches sit between routed ones, and only changed stretches are routed again.
  - Heights join the same way, since each routed stretch brings its own samples.
    - Straight stretches have none. #210's engine only routes, and there is no other offline height source yet.
    - Their part of the profile stays unknown (0x7FFF). `ElevationProfile` expects every height today, so it needs to skip such gaps.
  - Without routing data for the area, only straight stretches can be added, and the editor says so.
- **New routes:** made the same way, starting from an empty route.

## R4: sharing over the mesh

### A planned route: `Route:` text message

MeshTrax only for now. It is parsed by the one parser, `StructuredMessage.parse` ([structured_message.dart](../../lib/helpers/structured_message.dart)). Add `route` to `_header`, which also keeps it out of SMAZ compression.

```
Route: Camp Bird road
dirt
37.97123, -107.71234
37.99012, -107.73401 ~
38.00387, -107.75112
```

**Layout:**
- **Line 1:** the type and the name.
- **Line 2:** the path type (`paved`, `dirt` or `hiking`).
- **Then:** one waypoint per line, as `lat, lon` with 5 decimals (about 1 m); this is the shape `coordinatePattern` already recognises.
- **Straight stretches:** a point ending in ` ~` means the stretch after it is straight. This is a suggestion; change it if a better marker turns up, since nothing outside MeshTrax reads it yet.

**Things to check:**
- Older MeshTrax builds turn a message of up to 3 lines with a coordinate line into a Location card (`_parseLoose`). A `Route:` message always has at least 4 lines, so they show plain text. Check this against a 1.9 build's parser.
- **Size:** a DM holds 160 bytes, and a channel message 160 minus the sender name and 2. Each point costs about 20 bytes, so about 6 points fit in a DM.
  - When the waypoints don't fit, say so and offer track packets on a private channel.
  - Channel text over the limit is cut silently, so check the size before sending.
- Channel messages with the same text within 5 minutes are merged, so sending the same route twice quickly does nothing.
- Reactions and replies work as on any message.

**Receiving:**
- A Route card, styled like the Location card, with **Open** and **Save**.
- **Open** rebuilds the route with offline routing when routing data covers it. Otherwise it joins the points with straight lines and says so.

### A recorded track: compressed packets

This uses `packages/traxshare`'s codec, wire format and channel gate from #240, and the same `data_type` (0xFF54 during development).
- **Private channels only.**
- **May flood** through repeaters (Martin, 2026-11-05).
- **Two new subtypes** in traxshare's wire format: 4 ROUTE_PART and 5 PARTS_REQUEST. Keep them free while building #240.

ROUTE_PART (subtype 4) starts with the 12-byte common header. Its `session` field is a random share id.

| Offset | Size | Field |
|---|---|---|
| 12 | 1 | part_index |
| 13 | 1 | part_count, at most 16 |
| 14 | 2 | field_mask (bit 9: per-point height; bit 15: extension block) |
| 16 | 7 | anchor: the part's first point, packed like a REPORT position |
| 23 | 1 | grid_unit_m |
| 24 | 1 | point_count |
| 25 | n | points: zigzag and exp-Golomb deltas as in traxshare's trail encoding, in route order |

**Parts:**
- Each part decodes on its own, so a lost part leaves a gap, not a broken route.
- Each part's anchor is the previous part's last point, so the parts join.
- Part 0 carries the name in an extension block: a u8 length, then up to 31 bytes of UTF-8.
- Payloads stay within 157 bytes, which leaves 132 for points.

PARTS_REQUEST (subtype 5) is the common header, with the share id in `session`, plus a u16 bitmask of missing parts. The sender's app resends those parts with a new `seq`, if it still holds the share. Keep shares for 1 hour.

**Sending:**
- Simplify with traxshare's trail recipe (epsilon from 15 m, ×1.5) until the track fits in 8 parts or fewer. Keep that cap in the constants block; it is Martin's call.
- Pace the parts, one every few seconds after the radio has gone quiet, the way channel text waits today. Each part is about 0.58 s on air and is repeated by every repeater.
- Show "Sending part 3 of 6".

**Receiving:**
- The sharing strip and the route card show "Route from <name>: 5 of 6 parts", with **Save** and **Ask for missing parts**.

## R5: links with location sharing

These need #240's own-track table and its received trails on master.
- **Save my track:** pick how much of it, by distance back or between two times. It becomes a route with `source` track, simplified at 5 m, with straight stretches.
- **Save a shared trail:** from a person's pin, with `source` shared.
- **Share a route:** from its card, or from the sharing strip.
  - A planned route that fits goes as a `Route:` message to the chat you pick.
  - Anything else goes as track packets to a private channel.

## Privacy and store text

Martin edits these; the PR carries drafts.
- **docs/privacy.md:** saved routes, stops and photos are stored on the device and included in phone backups. Sharing sends a route over the mesh to the chosen chat.
- **iOS purpose strings:** `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` describe QR codes today, and need route photos added.
- **Android:** no new permission.
- **Play Data safety:** photos stay on the device; Martin confirms the answer.

## Verification

**Unit tests:**
- **Database:** the schema 8→9 migration on a fresh install and after an interrupted first launch.
- **Simplify** keeps every waypoint and stop. The line and height blobs round-trip. A straight road over a hill keeps its climb and its profile.
- **Stops** still find their place after the points-of-interest file is rebuilt with new row ids.
- **GPX:** `rte`, `trk` and `wpt` round-trip with heights. A 10,000-point track imports simplified. A found route's export carries its credits.
- **Photos:** a place's photo copied to a route keeps its credit.
- **`Route:` messages:**
  - builds and parses
  - an older parser shows plain text
  - size checks for DMs and long sender names
  - ` ~` stretches survive
- **Track packets:**
  - parts encode and decode and join
  - a lost part leaves a gap
  - a parts request resends only the missing parts
  - the 8-part cap holds
- **Tags:** filtering by tag.

**Renders shown to Martin before any APK:** the Routes list with and without photos, a card, the details screen, the editor with a straight stretch, the Save dialog, and the layers sheet entry.

**Two radios on 920.000 MHz:**
- a track shared as parts reaches the other radio
- F857 forwards them (ask Martin first)
- a missing-part request is answered

**Martin on phones:**
- save from the route panel; the active route's colour; with the layer off, only the active route shows
- drag points in the editor
- GPX import from the phone's files
- a photo from the camera
- a `Route:` message between two phones in a DM, and opening it with and without routing data

## Open questions for Martin

1. The part cap and pacing for shared tracks (8 parts suggested).
2. Whether `Route:` joins the public message format later.
3. The privacy-policy and purpose-string wording.
4. Whether #240's package lands on master before R4.
5. Do test version bumps stay in the PR?
