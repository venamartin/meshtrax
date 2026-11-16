# Saved routes: plan

> **What this is:** The build plan for keeping routes: saving the route the map finds, organising, editing, importing and exporting them as GPX, and sharing them over the mesh. Code name `traxbook`. It builds on the offline routing in #210 (merged, in v1.10.0) and on location sharing (`traxshare`, plan in #240). Owner decisions are from Martin's route notes, his answers on 2026-11-05 and his question-dialog answers of 2026-11-15 and 2026-11-16. App facts were checked against master `ff0df0f5` and #210's head that day. The session building #210 then rechecked everything this plan takes from #210 against its head `9ba6f98`: heights, place links, place photos, credits and the routing calls. The [audit and safety review](#audit-and-safety-review-2026-11-1516) of 2026-11-15/16 checked the plan again against master `d774d052`.
>
> **Who it's for:** the developer or AI session building it.
>
> **Status:** active plan, nothing built. The work happens on branch `feat/saved-routes` (draft PR). It is built after location sharing (#240), which keeps it in mind meanwhile (decision 35, preliminary). Decisions dated 2026-11-15 and later are preliminary; Martin wants them kept fluid until real-world tests. The same goes for the safety rules and for every change tagged with a safety-review ID (SR, CH) or an audit ID (A, B, C, D, R, TSX): they are proposed, and field tests can change them.
>
> New to the terms? See the [glossary](../glossary.md).

## The feature in one paragraph

When the map finds a route, it becomes the **active route**, and **Save** keeps it. A saved route has:
- a name, notes, named stops, tags and one photo
- its line, its height profile, its path type, and its distance, time and climb
- its turn list, and the date of the map data it was found with

Saved routes show on the map in a **Routes** layer, and in a **Routes** list reached from the Map screen. In the list, each card shows the route on a small map, with its photo.

Any route can be edited: move, add or delete points, and make each stretch either follow paths or run straight. Routes can be imported and exported as GPX, and shared over the mesh:
- a planned route as a short, readable message that MeshTrax rebuilds with offline routing
- a recorded track as compressed packets on a private channel

Your own track from the recorder can be saved as a route; other people's shared trails can't (decision 6b). A route never looks more certain than it is: it says what MeshTrax can't know, and shows the date of its map data and its off-path parts ([Safety first](#safety-first-proposed-2026-11-16-preliminary)).

## Safety first (proposed 2026-11-16, preliminary)

The design setting is remote desert trips, for example Death Valley: no cell service, no repeaters (radios reach each other directly only), extreme heat, long dirt roads and canyons, and rescue that may be much delayed. People plan water and turnaround times from a route's distance, climb and time. These rules come from the 2026-11-15 safety review. The full set, SR-01 to SR-10, is in #240's plan (its "Safety first" section; `docs/technical/traxshare-plan.md` on branch `feat/traxshare`); these are the ones routes touch.

- **SR-09: a route never looks more certain than it is.**
  - It says MeshTrax doesn't know closures, washouts or which roads need 4x4, and it shows the date of its map data (CH-17).
  - It draws and counts off-path parts separately: the start gap, straight stretches and recorded stretches (CH-18, CH-19).
  - It shows unknown climb as "at least" (CH-19).
  - It never draws a line where nobody was recorded: a break in a track stays a gap (CH-13, CH-20).
  - Hiking times read "walking time on paths at <pace>; heat, sand and off-trail take longer", and a straight stretch's time is marked as an estimate. The engine walks at a flat 4.0, 5.1 or 6.0 km/h (`valhalla.dart`), while NPS gives Death Valley's Telescope Peak as 19.6 km and 7 hours round trip ([NPS hiking](https://www.nps.gov/deva/planyourvisit/hiking.htm)).
- **SR-01: never show a position without its age and where it came from.** A route to a person says how old that position is (CH-33, in #240's plan). A start from your position that wasn't live reads "From your last known position (14:02), may be old" (CH-07), and any start from your position reads "From where you were at 14:02" once you are more than 100 m from it (CH-18). Recorded points keep their source, radio or phone (decision 21).
- **SR-08: nothing waits forever for a repeater.** `Route:` DMs go out only once the master DM fix (decision 20, CH-04) has shipped, and the Share sheet says "reaches people in direct range" when no repeater has been heard (CH-39).
- **SR-10: nothing is relied on before its field test,** with real radios and both phone types ([field tests](#field-tests-proposed-preliminary)). The help text says to carry a PLB or satellite messenger, because MeshCore can't call outside help (decision 7).

## Start here: working rules

These are the same rules as in #240's plan, shortened. A session in a new worktree doesn't see the project memory.

**Git**
- `git fetch origin`, then branch from `origin/master`. Work in a worktree.
- Never commit on master. Stage named files only, never `git add -A`.
- Commit locally. Push only when Martin has tested and says so: the repo is public.
- "Ship it" means push, PR, wait for the `analyze` check, squash-merge, clean up, sync master. It counts only when Martin types it in that session, and it never means a store release.

**Test builds**
- Bump the version above what is on Martin's phone (build number 205 or higher on 2026-11-16), commit the bump, then build with `./buildapk.sh`.
- A worktree needs three untracked files copied from the main checkout: `buildapk.sh`, `android/key.properties` and `giphy.key`. Never commit `giphy.key`. `pubspec.lock` is tracked since #276, so don't copy it over: that would change versions inside a feature PR.
- Ask whether the bump stays in the PR.

**Look before an APK.** Martin wants to see visual work before it is built.
- Render each new screen at phone size (1080×2340 at 2.625) with real fonts (Roboto and Material Icons from `~/flutter/bin/cache/artifacts/material_fonts/`), and show him the pictures first.
- Widget tests use a block font and hide layout problems.

**Radios**
- Firmware truth is MeshCore's `companion-v1.18.0` tag. On the Pi the checkout is at `~/code/MeshCore`; read the tag with `git show companion-v1.18.0:<path>`, since the working tree has local changes.
- Heavy or repeated sends go on 920.000 MHz only; at most a couple of frames on the live mesh (910.525).
- Ask before touching repeater F857.

**Text and data**
- Plain words on screen.
- Every new string goes in all 18 language files (`lib/l10n/app_*.arb`).
- Dates go through `DateTimeHelper`, distances and heights through `GeoFormat` with the user's units, and coordinates through #210's coordinate-format setting.
- Never name other apps.

**Code**
- Import Material from `package:material_ui/material_ui.dart`, never `package:flutter/material.dart`.
- A test with a non-English locale uses `appLocalizationsDelegates` from `lib/l10n/l10n.dart`.

**Database**
- Migrations must survive an interrupted first launch: `createTable`, and add indexes and columns only if they're missing. `app_database.dart`'s `_createIndexIfMissing` shows how.

**Tests and repo gotchas**
- Inject clocks.
- Run analyze as CI does: `flutter analyze --fatal-infos --fatal-warnings`.
- Known Windows-only failures: `contact_advert_evidence_test`, and traxmap's `style_registry_test` (4) and `gap_fill_provider_test` (2).
- After a test run, line-ending churn appears in `lib/l10n/` and the plugin registrants: `git checkout -- lib/l10n linux macos windows`.
- `build_runner --delete-conflicting-outputs` deletes the checked-in `lib/l10n/*.dart`; restore them from git.

**Asking Martin**
- Put open decisions in the question dialog, with your recommendation first.
- Don't start review agents unless he asks.

## Owner decisions

Decisions dated 2026-11-15 and later are preliminary: each is the current choice, kept fluid until real-world tests. A number in a topic is Martin's dialog number; [below](#preliminary-decisions-alternatives-and-what-decides-them) are the alternatives and what decides each.

| Topic | Decision |
|---|---|
| Active route | A route found by the route sheet (`route_sheet.dart`, since #271) becomes the active route; Save keeps it. There is one active route. It is drawn in its own colour and stays visible with the Routes layer off. No navigation for now. |
| What a route holds | Name, notes, named stops, one photo at a standard size, tags. Also the line, height profile, path type, options, distance, time and climb. |
| Routes layer | A switch in the map's layers sheet that draws the saved routes |
| Routes list | Reached from the Map screen (menu entry and the route sheet's Save). No third bottom tab. Cards show a small map and the photo. |
| Editor | Its own screen. Any route can be edited, or a new one made. Points can be added, moved and deleted. Each stretch follows paths of the route's type, or runs straight for off-trail parts. One path type per route, as decided for #210 on 2026-10-25. |
| Recorded and imported tracks | After simplifying, their points become straight stretches, so they keep their exact shape and edit the same way. Proposed (CH-19, R-03): they become recorded stretches, drawn in a track style, and the editor shows a thinned set of their points. |
| Size | Routes are simplified when saved, within reason |
| GPX | Import and export |
| Organising | Tags, with filter chips |
| Stops | Your own named points along the route. Each can link to a place from #210's points-of-interest search. |
| Backups | Saved routes are your content: they go in phone backups and in Export database. The recorder's raw track stays out, kept with the sharing data as #240 plans. Export database is the debug export ("Export message database"); GPX is how routes leave the phone (audit B8). |
| Sharing a planned route | A readable `Route:` text message with its waypoints and path type; MeshTrax rebuilds it. MeshTrax only for now: not added to the public [message format](../message-format.md). |
| Sharing a recorded track | Compressed line packets, private channels only. They may go through repeaters. |
| Route name and fitting | Part 0 carries the route's name as a tagged extension item, and tracks are fitted by bisection, both as in #240's plan (2026-11-15). Tag 1 was chosen; R-04 proposes the route name's own tag from one list for the whole format, since tag 1 is the sender's name in traxshare. |
| Recorder (1) | 2026-11-16, preliminary: its own feature, with start and stop, no cap, times kept and a list of tracks. traxshare's own trail and Save my track read from it. Built in #240's work, after its Step 2 package; traxbook comes after #240 (35). Its rules (CH-13) are in #240's plan. |
| Order (35) | 2026-11-16, preliminary: location sharing (#240) first, through its Step 4 and field tests, then traxbook. Meanwhile #240 keeps traxbook in mind: subtypes 4 and 5 stay reserved, the extension tags are one list, the recorder keeps times, gaps and each point's source, and other people's positions never go into routes. (Was: interleaved with #240's steps.) |
| Times (3) | 2026-11-16, preliminary: a route saved from a track keeps each point's time, in a times column stored with the line. |
| Directions (5) | 2026-11-16, preliminary: the turn list is stored with the route and stays in the language it was made in. It is rebuilt for changed stretches, or shows "Directions out of date. Find again" (CH-34). |
| Other people's positions (6a, 6b) | 2026-11-16, preliminary, one rule in both plans (R-01). 6a: a route to a person (traxshare's Route here) is kept with the sharing data, never in `routes`. It survives closing the app, is never in phone backups or Export database, and is removed with that person's data (after 30 days, decision 11, or by Delete all sharing data). 6b: no Save a shared trail; someone who wants their trail kept shares it as a route themselves. |
| Phone GPS (21) | 2026-11-16, preliminary (was: radio only, decision 2): the phone's GPS is an opt-in local fallback for the dot, Route here's start and the recorder whenever the radio has no live position. It is never sent. The recorder marks each point's source, and a route saved from it keeps the marks. |
| `Route:` length (25) | 2026-11-16, preliminary: line 2 carries the route's length, the card warns above a 3 % difference, and **Send the exact line** is offered for plans shared before splitting up (CH-20). |
| Route caveats (26) | 2026-11-16, preliminary: every Dirt and Hiking route shows the closures and 4x4 caveat and the map data's date, and R1 stores the routing build and its date with each found route. The default Dirt option waits for a test of Fastest against Balanced on desert park data (CH-17). |
| With location sharing | First version: save my track as a route (from the recorder), and share a route to the channel. Not taken: save someone's shared trail (6b, 2026-11-16, preliminary; was: save it as a route). Later: members' active routes on the map during a session. |

### Preliminary decisions: alternatives and what decides them

Each entry gives the dialog number, the current choice, the alternatives Martin was offered, and the test or measurement that would confirm or change it ("Checked by"). Field test numbers are those of #240's field tests (its Verification section), 1 to 20; test 14 is also [below](#field-tests-proposed-preliminary).

- **1, recorder:** its own feature, built in #240's work after its Step 2 (timing per 35). Alternative: keep recording inside location sharing. Checked by field tests 5 (a locked iPhone's recorder points), 8 (kill and restart: two marked gaps) and 17 (a day's battery with the recorder on).
- **3, times:** a times column with the line. Alternative: drop times. Checked by measuring its size on the longest recorded track (4 bytes a point, beside the line's 8) and by the GPX round trip keeping times.
- **5, directions:** stored with the route. Alternative: find the route again on open. Checked by field test 14: whether stored directions on a saved desert route still match the roads, and whether "Found with map data from <date>. Find again" shows once newer data is installed.
- **6a, a route to a person:** kept with the sharing data, out of backups. Alternative: in the routes table. Checked by field test 15 (retention and a spare radio: the route to a person is still there after connecting a second radio).
- **6b, no Save a shared trail:** Alternative: save it as a route. Checked by field test 16 (the search details drill): whether Details for a search and Send to this channel (decision 23) give the group what a saved trail would.
- **7, moving to MeshCore:** a PLB or satellite messenger covers outside help, and each feature is relied on only after its field test. Alternatives offered: "keep APRS for good" and "switch only after a park field test". Checked by the field tests themselves, on both phone types (CH-24).
- **20, the DM fix (master):** park a flood DM only if a repeater was heard in the last 10 minutes. Alternatives: give up after 2 minutes; keep as is. Checked by field test 2 (a DM with no repeater on the air). `Route:` DMs wait for it (CH-39).
- **21, phone GPS:** an opt-in local fallback (was: radio only, decision 2). Alternatives: only if the iPhone test fails; radio only. Checked by a walk with the radio switched off midway (the dot stays, marked as the phone's, and the recorder goes on with phone points), field test 17 (battery and heat) and field test 5 (a locked iPhone).
- **25, `Route:` length:** the length, a 3 % warning and Send the exact line. Alternatives: the length only; as planned. Checked by field test 14's last step (open a `Route:` on a phone with other route options), which also tunes the 3 %.
- **26, route caveats:** the caveat and data date on every Dirt and Hiking route, and a test before choosing the default. Alternatives: caveat and date only; also close very rough tracks in the routing data. Checked by field test 14, which compares Fastest and Balanced Dirt routes on desert park data. With high-clearance 4x4s, rough tracks are less of a risk, so Balanced may stay the default; the test decides.
- **29, master PRs:** the route caveat, data date and start gap (CH-17, CH-18) and your dot after a lost fix (CH-07's master part), each its own small master PR, merged only on Martin's "ship it". No alternatives were offered. Checked by field test 14 for the route parts, and field test 1 (a bench test of whether a parked radio's reading keeps changing) before the dot change.
- **35, order:** location sharing first, through its Step 4 and field tests, then traxbook, kept in mind meanwhile. Alternatives: interleave as planned; traxbook alongside in another session; traxbook first. Revisit once #240's field tests are done.

## Order of work and dependencies

**First, on master** (own small PRs, merged only on Martin's "ship it"; preliminary 2026-11-16): the DM fix (20), then the minimal SOS (16), then decision 29's items: the springs and drinking-water caveat and line of sight's "needs an internet connection" (CH-35, CH-36), the route caveat, data date and start gap (CH-17, CH-18), and your dot after a lost fix (CH-07's master part, after the bench test). The old-texts fix (TSX-03, CH-10 part 1) waits for a review of the earlier message-time fixes, which Martin asked for. TRAX mode's radio part follows, also on master (#240, decisions 31–34). R1 builds on the route items, and R4's `Route:` DMs wait for the DM fix.

| Step | What | Can start |
|---|---|---|
| R1 | Route library: save, active route, Routes layer, Routes list and details, photo | After #240's Step 4 and its field tests (decision 35). #210 has merged (v1.10.0). The cross-plan rule (R-01, decision 6a) and the saved-route mode (R-02) are written first. |
| R2 | GPX import and export | after R1 |
| R3 | Route editor | after R1 |
| R4 | Sharing: `Route:` message, track packets | `Route:` after R1, and `Route:` DMs after the DM fix (20). Track packets need `packages/traxshare` (#240's Step 2) on master. |
| R5 | Links with the recorder and location sharing | Save my track and Back the way I came after the recorder; Share from the sharing strip after #240's Step 3 is on master |

The order across both plans (decision 35, preliminary 2026-11-16):
1. The master fixes above, each its own PR, then TRAX mode's radio part (#240).
2. Settle the v1 wire rules in #240's plan: one tag list (R-04), unknown subtypes (R-05), ordering and replay (A1, A2), the channel gate (TSX-01) and the safety review's mask bits (CH-23). Then build traxshare's Step 2 package as its own PR. That freezes v1, which R4 needs.
3. The recorder (#240).
4. traxshare's Step 3 (3a, then 3b), then Step 4.
5. The field tests (CH-24).
6. Then traxbook: R1, R2, R3, R4 and R5.

Each step is one commit series on this branch, with Martin testing on a phone between steps.

## R1: route library

**Database:** `AppDatabase`, the app's own database. Take the next free schema version when R1 is built: master is at 9, from #279, and 10 is taken by other work in progress (audit B6).
- It is not tied to a radio: routes belong to the person, so there is no node scope.
- It is included in phone backups and Export database, as decided.
- It never holds another person's position (R-01, decision 6a): a route whose destination came from traxshare stays with traxshare's sharing data.

```
routes(
  id INTEGER PK, saved BOOL, active BOOL, name TEXT, notes TEXT,
  path_type TEXT NULL,          -- paved | dirt | hiking; NULL for a track
  options_json TEXT NULL,       -- traxroute RouteOptions.toJson()
  source TEXT,                  -- planned | track | gpx | shared (a route received over the mesh)
  km REAL, seconds REAL NULL, climb_up_m REAL NULL, climb_down_m REAL NULL,
  min_lat, min_lon, max_lat, max_lon,   -- for drawing only what is in view
  line BLOB,                    -- see "Line storage"
  times BLOB NULL,              -- a time per line point (decision 3)
  breaks BLOB NULL,             -- where the line has gaps
  heights BLOB NULL,            -- see "Heights"
  height_step_m REAL NULL,
  directions TEXT NULL,         -- the turn list (decision 5)
  routing_build TEXT NULL, routing_date TEXT NULL,   -- CH-17
  credits TEXT NULL,            -- see R2's export
  created_at, updated_at)
route_waypoints(route_id, seq, lat, lon, kind_after TEXT, line_index INTEGER,
                PRIMARY KEY (route_id, seq))
route_stops(route_id, seq, name, lat, lon, note TEXT NULL,
            place_region TEXT NULL, place_key TEXT NULL,
            PRIMARY KEY (route_id, seq))
route_tags(route_id, tag, tag_key, PRIMARY KEY (route_id, tag_key))
route_photos(route_id PK, file_name TEXT, width, height,
             author TEXT NULL, licence TEXT NULL, licence_url TEXT NULL,
             commons_file TEXT NULL)
```

**Fields:**
- `route_waypoints` are the points the editor moves. `kind_after` replaces `straight_after` (CH-19): the stretch after the point is `path` (follows paths), `straight` (drawn by hand) or `recorded`. `line_index` is where the point sits in the line, so each stretch can be drawn in its own style and routed again on its own.
  - A planned route has a few, `path` except on off-trail stretches.
  - A track's points live only in the line blob (R-03). A row costs about 31 bytes plus 15 for an index, against 8 in the blob, and every kept point as a handle would give the editor 611 points on a 39.5 km loop. Its waypoint rows are a thinned set, with `recorded` stretches between them.
- The child tables reference `routes` with `ON DELETE CASCADE`, and `beforeOpen` sets `PRAGMA foreign_keys = ON`: SQLite leaves foreign keys off, and no other table uses them. Or delete the children in the same transaction. Either way, deleting a route, or replacing the unsaved row, leaves no orphans (R-03).
- `tag_key` is the tag folded in Dart, which the filter chips compare: SQLite's NOCASE and `lower()` fold ASCII only (R-03).
- The list query leaves out the line, times and heights blobs; drift's default select loads every column (R-03).
- `route_stops` keep a copy of the name and position, so a stop survives a points-of-interest pack update. `place_key` is only a link back to the place's text and photo.
  - It is the key search already builds to match one place across regions' files (`SearchResult.key` in traxpoi): the place's `osm` id, else its `wikidata` id, else its name and position.
  - Not `place.id`: that is a row number in a file rebuilt every month, so after an update it can point at another place.
  - traxpoi has no lookup by that key yet, only `placeById`. Add one to `points.drift`. The file has no index on `osm`, but a scan is fine for one stop.

**Line storage:** one blob per route. Each point is `lat` and `lon` as int32 in millionths of a degree, little-endian. It is quick to load in one read, and needs no codec. Heights are kept apart, below.
- **Times** (decision 3): a route saved from a track keeps one u32 Unix time per line point in `times`, little-endian. Planned routes have none.
- **Breaks:** `breaks` holds the u32 line indexes where a new segment starts: a recorder gap (CH-13), a GPX `trkseg` (R-06) or a missing shared part (CH-20). Nothing is drawn, counted or exported across a break.

**Heights:** a second blob, the height profile. It holds int16 metres every `height_step_m` along the line, little-endian, with 0x7FFF where a height is unknown. That's about 7 KB per 100 km.
- This is the shape #210 already has. `RouteResult.elevations` holds a sample every `elevationIntervalM` (30 m) along the route, not one per point, and `ElevationProfile` draws them evenly spaced. `RouteResult.climb` ignores the spacing: it walks the heights in order and adds changes of 5 m or more (audit C3).
- The spacing is close to even, not exact: a route's last step is its length mod 30 m, and each join of appended stretches makes the profile 30–60 m too long (C3, C4). So whatever maps samples to distance (this blob, GPX `ele` and a profile axis) resamples them by distance along the line.
- A height per point of the simplified line would lose the hills: a straight road over a ridge keeps only its two ends.
- A track, or a GPX `trk` with `ele`, is sampled every 30 m by distance along all its points, before simplifying. Own tracks drop altitude-0 readings and readings from before the first fix (CH-19): a restarted radio reports altitude 0 until it has one.
- GPX export gives each point the height at its distance along the line, and leaves out `ele` where the height is unknown (R-11).
- With no heights at all, `heights` is NULL. That happens in a region built without them, where #210's route has none either.
- **Unknown heights** (R-11) arrive with R2's GPX import, before R3, so R1 handles them. Pick one in-memory form (nullable or NaN) for `ElevationProfile` and `climb`. Today `climb` would count a 32767 as about 30 km of climb and descent, a NaN first sample makes the whole climb 0, and `ElevationProfile`'s min and max turn a NaN into NaN labels. Never count climb across unknown samples, and show "climb at least 310 m; heights unknown for 2.1 km" (CH-19).

**Simplify on save:**
- 2D Douglas–Peucker at 5 m, so the shape holds at street zoom; keep the tolerance in a constants block.
- Never drop a waypoint's or a stop's position.
- Heights aren't simplified: they are already in the profile.

**Active route:**
- On master the route lives in the map screen's state: `_routeTo` (name and point), `_routeFrom` (null means your position) and `_route`, set by `_findRoute`. The path type and options are global settings (`settings.routePathType`, `settings.routeOptions`), and #271's `UiViewStateService.mapRoute` keeps the route for the run only ("Not saved, so it goes with the app").
- That model can't hold a saved route with several waypoints, straight stretches or a track (R-02): a change of path type, options or Use my position finds a fresh two-point route from `_routeFrom ?? selfPosition`. So R1 adds a **saved-route mode**, replacing or extending `mapRoute`:
  - The active route is a `routes` row, and the map draws its stored line and profile.
  - The sheet shows the row's own path type and options. Changing them goes through the editor, or routes all of the route's waypoints again.
  - A saved route keeps a fixed start. A start that was your position reads "From where you were at 14:02" once you are more than 100 m from it (CH-18).
  - The active marker is in the database (`active`, on at most one row, by a partial unique index), not in a preference, and goes when the route is deleted.
- When the route sheet finds a route, it is written as a row with `saved` false, replacing any earlier unsaved row. It survives a restart, until it is cleared or replaced.
- A route to a person is the exception (decision 6a, R-01): traxshare keeps it with the sharing data, and it is never written to `routes`; while it is shown, no `routes` row is active. It has no Save, so it never gets a card or Share, which would copy that person's position out of the sharing data.
- The route sheet (`lib/widgets/route_sheet.dart`, added by #271 in place of #210's route panel) gets **Save**, which asks for a name, prefilled with the destination's name, and sets `saved`.
- A saved route can be made active from its card.
- **The start:** "From your position" follows the same live test as your dot: otherwise the sheet says "From your last known position (14:02), may be old" (CH-07; the dot's fix is one of decision 29's master PRs). With the phone's GPS fallback on, the phone's position can be the start, marked as the phone's (decision 21).

**Turn list** (decision 5):
- Store `RouteResult.maneuvers` (instruction, km, seconds and `startIndex`) with the route, in the language it was made in, and remap each `startIndex` onto the simplified line; nothing in lib/ reads `startIndex` today (audit B5).
- The turn list belongs to its line (CH-34). R3 rebuilds it for every changed stretch, and a straight stretch gets one line ("Straight, not on a path, 1.2 km north-east"). When the line has changed without new directions, the list says "Directions out of date. Find again".
- Store the routing build and its date with each found route and its turn list (CH-17): `RoutingStore.build`, and `RoutingCatalog.buildDate`, which nothing in lib/ reads yet. When newer data is installed, or the route is a few months old, the details say "Found with map data from <date>. Find again". Find again says when the length changed by more than a few percent.

**Map:**
- A **Routes** switch goes in the layers sheet. Its Details section already has 6 tiles (contours, hill shading, parks, places, dark, downloaded areas), and tiles are sized five to a row on a phone, so Routes goes in a new **Trax** section with #240's People sharing switch (audit D1). It needs a picture like the other entries. Since #241 those are drawn by the app's own styles from real packs, at the tile's size.
- The map's filter button (#298) filters nodes, and shows only while a node layer is on (`_nodesShown`). Routes aren't nodes, so they stay out of it, and the layers sheet is their only switch (proposed, D2).
- Since #298 the legend's entries are written into the code (`map_legend_sheet.dart`), so add entries for the active route, saved routes, straight and recorded stretches, and the dotted start and end gaps (D3).
- **Colours:** saved routes are drawn thin and neutral. The active route uses #210's `routeColor` at width 5, its current look. With the switch off, only the active route shows. Straight stretches are dashed and recorded ones drawn in a track style; breaks aren't drawn (CH-19).
- **Performance:**
  - Draw only routes whose box meets the view, and thin each line to the zoom.
  - The map rebuilds its overlays on every connector notify. #210 adds a rebuild 300 ms after every pan at zoom 12 and above, when it loads the places in view. Map drawing is the app's main known cost (Windows profile, 2026-10-31). Keep the built overlays and reuse them until a route changes.

**Routes list:**
- Opened from the Map screen's menu. In full screen (#297) the menu is hidden, and leaving full screen takes one tap (audit B11).
- Search by name, tag filter chips, newest first.
- Each card: photo if any, a small map of the line, name, tags, distance, time, climb and path type.
- Draw the card's map once and keep it as an image, keyed by route id and `updated_at`. A live map on every card would be costly in a long list. Where no offline map covers the route, draw the line on a plain background.

**Route details:**
- name, notes, tags, stops and photo
- distance, time and climb, with heights in the user's units: "climb at least" when part of the profile is unknown, and "of which 2.1 km straight: not on a path" when there are straight stretches (CH-19)
- hiking times as "walking time on paths at <pace>; heat, sand and off-trail take longer", and a straight stretch's time, from the path type's speed, marked as an estimate (SR-09, CH-19)
- on Dirt and Hiking routes, the fixed line "MeshTrax doesn't know closures, washouts or which roads need 4x4. Check current conditions before you go." and "Map data from <date>" (CH-17)
- the start gap, when the route starts more than 100 m from where it was asked for: "Starts 1.5 km from your position, off any mapped path", and "+1.5 km not on the route" in the totals (CH-18)
- the turn list, or "Directions out of date. Find again" (CH-34)
- #210's `ElevationProfile`
- actions: **Show on map**, **Make active**, **Edit**, **Share**, **Export GPX**, **Find again**, **Delete**

**Photo:**
- One per route, from the gallery, or from the camera where the platform has one: offer it only where `ImagePicker().supportsImageSource(ImageSource.camera)` is true. On Linux, macOS and Windows image_picker has no camera source and ignores `maxWidth` and `imageQuality` (audit R-08).
- The app already declares the camera (for the QR scanner, which uses `mobile_scanner`), and on iOS the photo library; it calls `image_picker` only for the gallery. So no new permission is needed.
- Scale it to 1280 px on the long side and save it as JPEG at quality 80: about 170 KB at the median in the audit's test (61–294 KB, about ±30 % for real phone photos). Without `imageQuality`, image_picker saves at full quality, about 870 KB (B3).
- Re-encode it without EXIF. On Android the resizer copies the EXIF GPS tags into the result, and on iOS the picker writes the original image's metadata, so a photo would carry where it was taken into backups (R-08).
- On desktop, resize and encode in an isolate with `package:image` made a direct dependency, in a PR of its own (it is transitive today), or keep the file as picked: dart:ui encodes PNG only (R-08).
- Keep photos as files (`file_name`), not blobs, so they aren't in Export database, the debug copy (B1–B3, R-03):
  - The app database is in Android Auto Backup, whose quota is 25 MB per app. Over it, Android backs up nothing for the app, messages included, and the message database and the path-graph files already share it (about 10 MB of messages on one test install).
  - auto_vacuum is off, so deleting a photo blob would never shrink the database file.
  - Whether the photo folder goes in backups, with a size budget, or stays out of them is [open question 9](#open-questions-for-martin).
- It is never sent over the mesh.
- A route to a place starts with that place's photo from the points-of-interest download, if it has one.
  - Those photos are WebP, at most 320 px, from Wikipedia or Wikimedia Commons, each with an author and a licence.
  - The place sheet credits them (`place_photoCredit`), and the route card and details must credit a copied photo the same way.
  - Keep the photo as it comes, with its `author`, `licence` and `licence_url`. Only your own photos are scaled and saved as JPEG, and their credit columns stay NULL.
  - Keeping the place's `file`, its Commons file name, as `commons_file` is optional (R-08): the place sheet credits only author and licence.

## R2: GPX import and export

The app already depends on the `gpx` package (contact export in [gpx_export.dart](../../lib/utils/gpx_export.dart)) and on `file_selector` and `share_plus`. The lock file pins gpx 2.3.0.

**Export:**
- the line as a `trk`, with `ele` from the height profile and `time` from the times column; one `trkseg` per segment, so nothing joins across a break
- a planned route's waypoints as an `rte`
- stops as `wpt`
- the name and notes as `name` and `desc`; tags as `keywords` in `metadata`
- the path type in `<type>` on the `rte` and `trk`, and the stretch kinds and options in a MeshTrax extension on the `rte` or `trk`, with its own namespace URI: GPX 1.1 extensions take elements from other namespaces only (R-06)
- a found route's `credits`, in `metadata`, as lines in `desc` or as `link` elements with text: GPX 1.1 has a single `copyright`, with one author and one licence URI (R-09)
  - Its line comes from OpenStreetMap data and its heights from USGS or Copernicus, and their licences ask for credit.
  - Save the credits with the route from `RoutingService.credits` and `notices` (#210), one per line, since the routing data may be removed later.
  - Your own tracks need none.
- **Valid GPX 1.1** (R-09): gpx 2.3.0 writes no GPX 1.1 namespace, writes `keywords` right after `desc` (the schema wants it after author, copyright, link and time), and writes `time` before `ele`. Version 2.5.0, in a PR of its own, adds the namespace (`GpxCompatibilityMode.gpx11`) and puts `ele` first. But it still writes `keywords` early, the root `extensions` before `wpt`, and the `link` of an `rte` or `trk` after its points. So leave out the keywords or place them yourself, and test the export against the schema's element order and namespace.

**Import:**
- An `rte` becomes a planned route: its points are waypoints, and the importer asks for a path type.
- A `trk` becomes a track. Its `ele` values are sampled into the height profile and its `time` values kept, then it is simplified at 5 m, with recorded stretches. Several `trkseg` in one `trk` become breaks in one route, or one route each, as the user picks (R-06).
- A file whose `rte` and `trk` carry MeshTrax's extension reads back as one route, with its path type and stretch kinds (R-06).
- A dense `rte`, or one with a GPS unit's routed shape points (`gpxx:rpt`, which gpx 2.3.0 drops), comes in as a track (R-06).
- `wpt` points become stops.
- **Robust reading** (R-06): gpx 2.3.0 fails the whole file on one empty `<ele>` or `<time>`, throws on a file that isn't GPX, and reads a time with no zone as local time. Catch every error, skip bad values rather than failing the file, and parse in an isolate with a size cap: 50,000 points took about 0.6 s on a Pi 5.
- Large files (tens of thousands of points) are simplified before saving.
- A `trk` where only some points have `ele` brings unknown heights, which R1 already handles (R-11).

## R3: route editor

Its own screen: the map with the route, its points and an action bar.
- **Points:** tap the map to add a point at the end; drag a point to move it; long-press to delete; tap a stretch to insert a point or switch it between **follow paths** and **straight**.
- **Snapped points** (audit C2): show each waypoint's snapped point, where the routing engine put it on a path. Where a waypoint snaps matters more than its type: measured with Valhalla 3.9.1, the app's version, waypoints 40–90 m off a street snapped onto the next street and added 0.3–0.6 km.
- **Route settings:** path type and options, one per route.
- **Other actions:** reverse, undo, stops, and save, either as a new route or over the old one.
- **Routing:**
  - Routed stretches are found one stretch at a time, then the shapes are joined. Each call is `RoutingService.route(a, b, type, options: …)`, which sends `RouteRequest([a, b], type, options: …)`; its arguments are positional. The engine takes several points at once (`packages/traxroute/lib/src/valhalla.dart`), but stretch by stretch lets straight stretches sit between routed ones, and only changed stretches are routed again.
  - Keep it stretch by stretch (C1, C2). One request per run, with `through` or `break_through` waypoints, swaps the out-and-back spur at a waypoint for a loop (measured: a 1.5 km loop in place of a 66 m spur). A dead end still goes out and back, one unreachable waypoint fails the whole run, and every edit routes the whole run again.
  - **Heights** join stretch by stretch, since each routed stretch brings its own samples. Each answer includes heights at both its ends, so drop each stretch's first height (it repeats the one before) and resample by distance. Appended as they come, each join stretches the profile by 30–60 m (C3, C4).
    - `parseValhallaRoute` joins legs the same way: it drops each leg's first shape point but keeps its first height. No test covers that, since the only fixture has one leg, so add a two-leg fixture.
    - Straight stretches have none. #210's engine only routes, and there is no other offline height source yet.
    - Their part of the profile stays unknown (0x7FFF), and the climb shows as "at least" (CH-19, R-11).
    - A stretch whose answer misses one sample comes back with no heights at all: `valhalla.dart` drops every height when any is below -490 m. Stretch by stretch keeps that loss to one stretch. The guard is safe below sea level, where Death Valley's lowest point is about -86 m.
  - **Both ends of every routed stretch** are checked, as CH-18 does for a route's start: a stretch that starts or ends more than 100 m from its waypoint draws that gap dotted and counts it as off-path.
  - **Coverage** (R-12): `RoutingService.offeredAt` and `hasRoutingData` are true once any routing data is installed, so they can't tell whether a stretch is covered. Build a check from the routing manifest's tiles (`InstalledRouting.tiles`), which is exact to the tile; `installedRegions` with `regionAt` is coarser.
  - `route()` goes through `routeOrNearest` (R-12). Paved and dirt retry with looser types, then return a route that stops short (`kmShortOfDestination`). Hiking, or a stretch no looser type reaches, throws `RouteError`. And a point outside the tiles can snap to a covered road up to 35 km away (`search_cutoff`). So handle both a thrown error and a short route: a stretch that stops more than 100 m short becomes straight, and the editor says so.
  - Without routing data for the area, only straight stretches can be added, and the editor says so.
  - **Directions:** rebuild the turn list for each changed stretch, and give each straight stretch one line (CH-34).
- **New routes:** made the same way, starting from an empty route.

## R4: sharing over the mesh

### A planned route: `Route:` text message

MeshTrax only for now. It is parsed by the one parser, `StructuredMessage.parse` ([structured_message.dart](../../lib/helpers/structured_message.dart)). Add `route` to `_header`, which also keeps it out of SMAZ compression.

```
Route: Camp Bird road
dirt 12.4 km
37.97123, -107.71234
37.99012, -107.73401 ~
38.00387, -107.75112
```

**Layout:**
- **Line 1:** the type and the name. Read the name from the header's own line, as `SvgMessage` does, since `_header`'s `\s*` after the colon also takes a line break (audit R-10). Refuse an empty or coordinate-shaped name and fall back to "Route": a point picked on the map is named with its coordinate text, which would read as a waypoint.
- **Line 2:** the path type (`paved`, `dirt` or `hiking`) and the route's length (decision 25, CH-20). The length costs about 8 bytes, roughly one waypoint in a DM.
- **Then:** one waypoint per line, as `lat, lon` with 5 decimals (about 1 m); this is the shape `coordinatePattern` already recognises. Use a 5-decimal formatter: `StructuredMessage.formatCoordinates` writes 6 (R-10).
- **Straight stretches:** a point ending in ` ~` means the stretch after it is straight. This is a suggestion; change it if a better marker turns up, since nothing outside MeshTrax reads it yet.

**Things to check:**
- Older MeshTrax builds turn a message of up to 3 lines with a coordinate line into a Location card (`_parseLoose`; the same `lines.length > 3` check in 1.8.1, 1.9.5 and 1.10.2). A `Route:` message with two or more waypoints has at least 4 lines, so they show plain text. One waypoint, for example with the start left out, makes 3 lines and a Location card, so keep the message at 4 lines or more (R-07, R-10).
- **Size:** a DM holds 160 bytes, but budget 158, as drawings do: a longer DM loses the firmware's 5th and later attempts (audit B9). A channel message holds 160 minus the sender name and 2. Each point costs about 20 bytes, and the length about 8, so about 5 points fit in a DM.
  - When the waypoints don't fit, say so and offer track packets on a private channel.
  - Channel text over the limit is cut silently, so check the size before sending.
- Messages with the same text within 5 minutes are merged, on channels and in DMs (R-10), so sending the same route twice quickly does nothing.
- Reactions and replies work as on any message.
- **DMs and reach** (CH-39): `Route:` DMs are sent only once the master DM fix (decision 20) has shipped. Until then, a DM that misses once where no repeater is heard is parked and never resent. When no repeater has been heard lately, the Share sheet says "reaches people in direct range".
- **Your start** (R-07): a route found from your position starts where you were. The Share sheet shows the start and offers to leave it out.

**Receiving:**
- A Route card, styled like the Location card, with **Open** and **Save**.
- **Open** rebuilds the route with offline routing when routing data covers it (R3's coverage check). Otherwise it joins the points with straight lines and says so; saved, those stay straight stretches.
- When the rebuilt route's length differs from line 2's by more than 3 %, the card says "Rebuilt on your phone: 14.1 km; the sender's: 12.4 km. It may follow other roads." (CH-20)
- Dirt and Hiking routes show the closures and 4x4 caveat (CH-17).
- For a plan shared before splitting up, the sender can also **Send the exact line**: the same route as track packets on the private channel (CH-20).

### A recorded track: compressed packets

This uses `packages/traxshare`'s codec, wire format and channel gate from #240, and the same `data_type` (0xFF54 during development; one allocation, requested once #240's Step 3 works on air, covers both features).
- **Private channels only.**
- **May flood** through repeaters (Martin, 2026-11-05). Where there are none, as on desert trips, the parts reach direct range only (CH-39).
- **Two new subtypes** in traxshare's wire format: 4 ROUTE_PART and 5 PARTS_REQUEST. Keep them free while building #240. A v1 receiver without R4 drops them quietly after the header, with no strip notice and no session or people change: a rule to settle in #240's v1 before Step 2 freezes it (audit R-05).

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
- Part 0 carries the route's name as an extension item (bit 15), UTF-8, cut at a character boundary to 31 bytes. Its tag comes from one tag list for the whole format in #240's plan, to settle before Step 2 freezes v1 (R-04). Tag 1 is the sender's name there, so a ROUTE_PART never changes `people.name_cached`. The items are those of #240's wire format: `[tag u8][len u8][value]`, and unknown tags are skipped. So a later field, such as the route's length, is a new tag rather than a format change.
- **Heights** (R-11): bit 9's per-point heights lose the hills on a simplified line, so a received track's climb comes out too low. Send a coarse profile as an extension item (a height every N metres), or drop bit 9 ([open question 7](#open-questions-for-martin)).
- Payloads stay within 157 bytes, which leaves 132 for points. In part 0, the name item takes 3 bytes plus the name out of that.

PARTS_REQUEST (subtype 5) is the common header, with the share id in `session`, plus a u16 bitmask of missing parts. The sender's app resends those parts with a new `seq`, if it still holds the share. Keep shares for 1 hour.

**Sending:**
- Find the finest tolerance that fits with traxshare's trail recipe. From epsilon 15 m, double until the track fits in 8 parts or fewer, then bisect, as #240's recipe does for one report. Keep that cap in the constants block; it is Martin's call.
- Pace the parts, one every few seconds after the radio has gone quiet, the way channel text waits today. Each part is about 0.58 s on air, and is repeated by every repeater where there are any.
- Show "Sending part 3 of 6".
- Measured part counts are in the [track compression review](#track-compression-review-2026-11-12).

**Receiving:**
- The sharing strip and the route card show "Route from <name>: 5 of 6 parts", with **Save** and **Ask for missing parts**. The name follows #240's name rules for the sender's prefix. "N of M parts" adds "ask while <name> is in range": the sender holds the share for 1 hour, and with no repeaters both must be in range (CH-39).
- A route saved from incomplete parts keeps each missing part as a gap, drawn as a gap and listed ("part 3 of 6 missing"), for as long as it is kept (CH-20).

## R5: links with the recorder and location sharing

These need the recorder (decision 1) and, for the sharing strip, #240's Step 3 on master.
- **Save my track:** it reads the recorder. Pick how much of it, by distance back or between two times. It becomes a route with `source` track, simplified at 5 m, with recorded stretches.
  - It keeps each point's time (decision 3) and source, radio or phone (decision 21).
  - It keeps the recorder's breaks (CH-13): more than 2 minutes with no reading from the radio or the phone, or a jump faster than 60 m/s, stays a gap. The recorder records nothing before the first live fix.
  - The recorder's tracks belong to the phone, not the radio, so a spare radio doesn't hide them (decision 14, CH-12).
  - On iPhone the recorder may stop while the phone is locked, until the locked-iPhone test passes (CH-08). Its gaps show as breaks, never as straight lines.
  - The recorder's other rules are in #240's plan: each point is written as it is kept, recording resumes after a restart, and a member is reminded that a recorder started by a session or trip mode is still on.
- **No Save a shared trail** (decision 6b, 2026-11-16, preliminary). Someone who wants their trail kept shares it as a route themselves. For a missing member, #240's Details for a search and Send to this channel cover it (decision 23).
- **Share a route:** from its card, or from the sharing strip.
  - A planned route that fits goes as a `Route:` message to the chat you pick.
  - Anything else goes as track packets to a private channel.
  - Points from the phone's GPS stay on the phone (decision 21). Until [open question 10](#open-questions-for-martin) is answered, Share and Export GPX leave them out, as a break.
- **Back the way I came** (an idea, CH-37, not decided): one tap makes the recorder's current track, reversed, the active route, with no save needed. It keeps the track's breaks.

## Privacy and store text

Martin edits these; the PR carries drafts.
- **docs/privacy.md:** saved routes, stops and photos are stored on the device and included in phone backups. Sharing sends a route over the mesh to the chosen chat, and a shared route can include your position, since a route found from your position starts there (R-07). These lines on master `d774d052` become false and need new text (R-07):
  - :80 "The points you plan a route between and the words you search for are never sent anywhere."
  - :92–93 and :123, the iOS and Android camera and photo rows: "No photos are captured, saved, or uploaded", and images "never uploaded".
  - :141–143, "Camera and photos": "The camera is used **only** to scan QR codes".
  - macOS: "Files you choose" (:109) and the paragraph at :113 need route photos added. The macOS camera row (:110) stays true, since image_picker has no camera source there.
- **docs/app-review-notes.md:23:** "Camera and photo library permissions are used only to scan QR codes" needs route photos added.
- **iOS purpose strings:** `NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` describe QR codes today, and need route photos added.
- **Android:** no new permission for routes. The phone's GPS fallback (decision 21) brings its own location permission, in #240's plan.
- **Play Data safety:** photos stay on the device, re-encoded without EXIF, so they carry no position (R-08); Martin confirms the answer.

## Verification

**Unit tests:**
- **Database:**
  - the migration to R1's schema version on a fresh install and after an interrupted first launch
  - deleting a route, and replacing the unsaved row, leave no orphan waypoints, stops, tags or photos (R-03)
  - a multi-stop saved route made active, its path type changed, the app restarted, then the route deleted: the active marker goes with it (R-02)
  - after Route here to a person and then Delete all sharing data, no person's position is left in the app database or in a `snapshotTo` copy (R-01)
- **Simplify** keeps every waypoint and stop. The line, times and height blobs round-trip. A straight road over a hill keeps its climb and its profile.
- **Heights:** profile and climb with a gap at the start and one in the middle; an unknown height never counts as climb; joined stretches keep the profile's spacing (C3, C4, R-11).
- **Stops** still find their place after the points-of-interest file is rebuilt with new row ids.
- **GPX:**
  - each element type round-trips: `rte`, `trk` with heights and times, and `wpt` (R-06)
  - a MeshTrax export reads back as one route, with its path type, stretch kinds and breaks (R-06)
  - an export passes a check of the GPX 1.1 schema's element order and namespace (R-09); the round trips use the same library, so they can't catch this
  - an empty `<ele>` or `<time>`, a file that isn't GPX, a time with no zone, and a `gpxx:rpt` route (R-06)
  - a 10,000-point track imports simplified, off the UI thread
  - a found route's export carries its credits, and leaves out `ele` where the height is unknown (R-09, R-11)
- **Photos:** a place's photo copied to a route keeps its credit; a desktop pick gets resized; a saved photo has no GPS tags (R-08).
- **Routing (R3):**
  - a two-leg fixture for the multi-leg parse, which would catch the duplicate join height; today's only fixture has one leg
  - a stretch into an uncovered region, and an unreachable waypoint (R-12)
  - a stretch that starts or ends more than 100 m from its waypoint (CH-18)
  - a stretch with one missing height sample leaves the other stretches' heights
- **`Route:` messages:**
  - builds and parses, with the length on line 2
  - an older parser shows plain text, and a message with the start left out keeps 4 lines
  - an empty name, a coordinate-shaped name, and a name equal to a path type (R-10)
  - size checks for DMs (158 bytes) and long sender names
  - ` ~` stretches survive
  - the 3 % length warning (CH-20)
- **Track packets:**
  - parts encode and decode and join
  - part 0's name item is cut at a character boundary at 31 bytes; unknown tags are skipped; a ROUTE_PART with a name leaves `people.name_cached` unchanged (R-04)
  - a v1 decoder without R4 ignores subtypes 4 and 5 (R-05)
  - a lost part leaves a gap, and a route saved from incomplete parts keeps and lists it (CH-20)
  - a parts request resends only the missing parts
  - the 8-part cap holds
- **Tags:** filtering by tag, and "öl" finds "Öl" (R-03).

**Renders shown to Martin before any APK,** light and dark: the Routes list with and without photos, a card, the details screen with the caveat, the data date and "climb at least", the editor with a straight and a recorded stretch, the Save dialog, the layers sheet's Trax section, and the legend entries.

**Two radios on 920.000 MHz:**
- a track shared as parts reaches the other radio
- F857 forwards them (ask Martin first)
- a missing-part request is answered

**Martin on phones:**
- save from the route sheet; the active route's colour; with the layer off, only the active route shows
- drag points in the editor
- GPX import from the phone's files
- a photo from the camera
- a `Route:` message between two phones in a DM, and opening it with and without routing data

### Field tests (proposed, preliminary)

Nothing here is relied on before its field test (SR-10). The full list, numbered 1 to 20 as in the safety review, is in #240's plan (Verification, "Field tests"), with the gate before anyone relies on these features (CH-24): a field test in desert terrain with real radios and both phone types, the locked iPhone, an Android phone lying still, and an 8-hour battery run with the recorder on.

- **14. Routes on desert park data.** On a phone with routing data for a desert park:
  - Ask for Dirt routes along a road the park lists as closed after flood damage, and to the end of one it lists as washed out ([NPS road conditions](https://www.nps.gov/deva/planyourvisit/conditions.htm)). Note whether they are routed.
  - Compare Balanced and Fastest Dirt routes on the same data, to choose the default (decision 26).
  - Check that the caveat and the data date show on the sheet and on a saved route.
  - Route from a point 1 km off any road: the sheet says "Starts 1.0 km from your position" and draws the gap.
  - A route with a straight stretch shows "at least" climb.
  - Open a `Route:` message on a phone with other route options: the card shows the length warning.
- The recorder tests in #240's list feed Save my track: 5 (a locked iPhone), 8 (kill and restart: the track shows two marked gaps), 15 (a spare radio: your own track is still there) and 17 (battery with the recorder on).

## Track compression review (2026-11-12)

A quick look at how tracks and routes can be made small enough for MeshCore's packets. Martin asked for it, and drafted a text encoding for tracks: a Google Encoded Polyline at precision 4, one message per track. The codec, the comparison and the measurements are in the location-sharing plan (#240, "Track compression review"), because the trail codec lives there. This section holds what it means for routes. **Nothing here is decided:** it is input for the later review.

### What makes a track small

In order of effect:
1. **Send the line only.** A GPX track point with a height and a time is about 100 bytes of XML. Even compressed ten to one that is 10 bytes a point, so GPX stays a file format for import and export.
2. **Simplify.** Douglas–Peucker at 15 m kept 181 of 1,604 points on a 37.8 km mountain highway.
3. **Round to a grid** sized to the tolerance, and send the differences between neighbouring points.
4. **Code the differences in bits,** not in bytes or characters.
5. **Or send no line:** waypoints, with the receiver's router rebuilding the line. That is the `Route:` message.

| Form | Cost per point | Step |
|---|---|---|
| GPX file | about 100 bytes, with a height and a time | as recorded |
| `Route:` text, waypoints only | about 20 bytes | 1 m |
| `SVG:` drawing over a map ([drawings](../message-format.md#drawings)) | 4–5 bytes | 1/100 of the map frame |
| Encoded polyline as text, precision 4 | 2.4–3.9 bytes | 11 m |
| Byte varints in 10 m units | about 2 bytes | 10 m |
| traxshare's code | 11–15 bits | 8 m and up |

The last three rows were measured on two road lines; the others come from this plan and the message format.

### R4: a recorded track in parts

Measured on two road lines from OpenStreetMap with traxshare's code (#240 has the lines and the method). A part holds 132 bytes of points, and the name takes up to 32 bytes of part 0 (34 since 2026-11-15, with the item's tag and length).

| Line | At 15 m, the recipe's start | At 10 m |
|---|---|---|
| 37.8 km mountain highway with switchbacks | 180 points, 313 bytes: 3 parts | 238 points, 380 bytes: 4 parts |
| 76 km mountain road | 300 points, 560 bytes: 5 parts | 368 points, 646 bytes: 6 parts |

- **The 8-part cap** leaves about 1,024 bytes for points, about 600 points at 13–14 bits each.
- **A recorded trail needs more.** The draft's test track, a GPS-recorded 39.5 km loop with switchbacks, kept 398 points at 10 m and 247 at 20 m. At 13–14 bits a point that is about 670 bytes (6 parts) and 420 bytes (4 parts). These are estimates: that track was not run through this code.
- **As polyline text,** the two road lines at 10 m would take about 4 and 7 messages of 148 characters.
- **The recipe:** #240's review proposes finding the finest tolerance that fits by bisection in place of the ×1.5 loop. The same applies to "fits in 8 parts". Adopted on 2026-11-15.

### R4: the `Route:` message

- **It stays the smallest form of a planned route,** because the receiver's router fills in the line: about 20 bytes a point, 6 points in a DM (about 5 since line 2 carries the length, decision 25).
- **More points per message** are possible, at a price:
  - 4 decimals in place of 5 (11 m in place of 1 m) saves 2 bytes a point. That is one more point at best.
  - The waypoints as an encoded polyline at precision 5 would cost 4–6 bytes a point, so about 25 points would fit (worked out, not built). Nobody can read or type that, which the [message format](../message-format.md) is built on, and the ` ~` marker would need another home.
  - The plan's answer is simpler: when the waypoints don't fit, offer track packets.
- **A check on the rebuilt route.** The message carries the path type, but not the routing options or the version of the routing data. The receiver's route can differ from the sender's with no sign of it. Adding the length to line 2 (`dirt 12.4 km`, about 8 bytes) would let the receiver say when its route is more than a few percent off. Taken up as decision 25 (2026-11-16, preliminary), with a warning above 3 %.

### R2: GPX import

- **5 m keeps noise.** The draft's recorded loop kept 611 of its 1,245 points at 5 m and 398 at 10 m. That is fine on the phone, where room isn't short. Sharing simplifies again from 15 m, so the import tolerance never reaches the air.
- **Smoothing before simplifying** (the draft's 5-point moving average) would take GPS noise out of an imported track. Not measured. It also moves real corners, so it needs a test on recorded tracks first.

## Audit and safety review (2026-11-15/16)

- On 2026-11-15 both plans were audited, and eight agents checked that audit's claims and swept each plan. A life-safety review for remote desert trips followed the same day: five lenses, a synthesis and two checkers. Martin answered the decisions in question dialogs on 2026-11-15 and 2026-11-16, and all of them are preliminary.
- Everything was read-only, against master `d774d052` and MeshCore's `companion-v1.18.0` tag. Routing claims were measured with Valhalla 3.9.1, the app's version.
- The notes, with their evidence and scripts, are kept locally in the gitignored `build/trax-audit/`.
- IDs: decisions 1 to 35 are Martin's dialog numbers (30 to 34 are #240's: the regular mesh and TRAX mode). SR (rules), CH (changes) and D-01 to D-20 (its decision drafts, which became most of dialogs 7 to 29) come from the safety review. A, B, C, D1 to D11 (no dash), R and TSX come from the audit. Where the checkers corrected an item, the corrected version is the one used.

**Index**
- **Decision 1** (recorder): Owner decisions; R5. Its rules are in #240's plan.
- **Decision 2** (radio-only GPS): replaced by 21.
- **Decision 3** (times): Owner decisions; R1 line storage; R2.
- **Decisions 4 and 11** (retention): #240's plan. A route to a person goes with that person's data at 30 days.
- **Decision 5** (directions): Owner decisions; R1 turn list; R3.
- **Decision 6a** (a route to a person): Owner decisions; R1 database and active route; Verification.
- **Decision 6b** (no Save a shared trail): Owner decisions; R5.
- **Decision 7** (MeshCore, PLB, field tests): Safety first (SR-10).
- **Decisions 8 to 19, 22 to 24, 27 and 28:** #240's plan, or master for the SOS (16, 17). 14 (per phone) and 23 (search details) are pointed to from R5.
- **Decision 20** (DM fix, master): order of work; R4.
- **Decision 21** (phone GPS fallback): Owner decisions; R1 start; R5; open question 10.
- **Decision 25** (`Route:` length): Owner decisions; R4; answers open question 8.
- **Decision 26** (route caveats): Owner decisions; R1 route details; field test 14.
- **Decision 29** (master PRs): order of work; R1 start and route details.
- **Decision 35** (order across the plans): header; Owner decisions; order of work.
- **SR-01, SR-08, SR-09, SR-10:** Safety first. **SR-02 to SR-07:** #240's plan; SR-02's live test reaches R1's start through CH-07.
- **CH-07:** R1 start; its master part is under 29.
- **CH-08:** R5 (iPhone gaps).
- **CH-12:** R5 (tracks per phone).
- **CH-13:** R1 breaks; R5. The recorder's rules are in #240's plan.
- **CH-14:** decision 21.
- **CH-16:** #240's plan; it keeps 6b (R5).
- **CH-17:** R1 turn list and route details; R4 Route card; master part under 29.
- **CH-18:** R1 start and route details; R3 (both ends of a stretch); master part under 29.
- **CH-19:** R1 schema, heights, map colours and route details; R3.
- **CH-20:** R4 (length, Send the exact line, missing parts as gaps); R1 breaks.
- **CH-24:** field tests.
- **CH-33:** #240's plan (the label of a route to a person); Safety first (SR-01).
- **CH-34:** R1 turn list; R3.
- **CH-37:** R5, as an idea.
- **CH-39:** Safety first (SR-08); R4.
- **CH-04:** Safety first (SR-08), as decision 20. **CH-10 part 1:** order of work, waiting for its review. **CH-23:** the suggested order; its tag list is R-04's. **CH-35, CH-36:** order of work (decision 29).
- **Other CH items** (01 to 03, 05, 06, 09, 11, 15, 21, 22, 25 to 32, 38): #240's plan or master.
- **D-01, D-10, D-11, D-13, D-16, D-19:** answered as decisions 7, 20, 21, 23, 25 and 26. The other D drafts are #240's.
- **The checkers' missing items:** hiking times are in Safety first (SR-09) and R1 route details. The rest (button traps, fallback positions, gps_interval, GPS off, contacts table, telemetry in flight, SOS sound, radio heat, GPS interference tests, a radio left behind, phones' satellite SOS, mixed app versions, Beep their radio, sharing past its end time) are #240's.
- **A1 to A10, TSX-01 to TSX-12:** #240's plan. A1, A2, TSX-01 and TSX-03 appear here only in the order of work.
- **B1 to B3:** R1 photo; open question 9. **B4:** decision 3. **B5:** decision 5; R1 turn list. **B6:** R1 database. **B7:** R1 (`route_sheet.dart`, `settings.routePathType`). **B8:** Owner decisions (Backups). **B9:** R4 (158-byte DM budget). **B10:** the header's code name. **B11:** R1 Routes list.
- **C1, C2:** R3 (stretch by stretch, snapped points). **C3, C4:** R1 heights; R3; Verification. **C5:** #240's plan (Route here's gate); R3 uses the same `offeredAt` facts.
- **D1, D2, D3:** R1 map (Trax section, filter button, legend). **D4:** #240's plan (a person's pin sheet); routes add no sheet over a marker. **D5:** working rules (18 language files). **D6:** working rules (Code). **D7:** header; order of work. **D8 to D11:** #240's plan.
- **R-01:** R1 database and active route; Owner decisions; Verification. **R-02:** R1 active route; Verification. **R-03:** R1 schema, fields and photo; Verification. **R-04:** R4 parts; Owner decisions. **R-05:** R4; Verification. **R-06:** R2; R1 breaks; Verification. **R-07:** R4; privacy. **R-08:** R1 photo; privacy; Verification. **R-09:** R2 export; Verification. **R-10:** R4; Verification. **R-11:** R1 heights; R2; R4 parts; open question 7. **R-12:** R3 coverage; R4 Open; Verification.
- **Editor items** (snapped points, the multi-leg parse test, the -490 m guard): R3; Verification.
- **Stale references fixed:** #210 merged; 18 language files; test builds from 205; Material from `material_ui`; `appLocalizationsDelegates`; analyze with `--fatal-infos --fatal-warnings`; "ship it" typed in that session; MeshCore at `~/code/MeshCore`; `pubspec.lock` tracked; `route_panel.dart` is now `route_sheet.dart`; `_pathType` is now `settings.routePathType`; the code name `traxbook`.

## Open questions for Martin

1. The part cap and pacing for shared tracks (8 parts suggested).
2. Whether `Route:` joins the public message format later.
3. The privacy-policy and purpose-string wording.
4. Whether #240's package lands on master before R4. The suggested order builds it as its own PR first.
5. Do test version bumps stay in the PR?
6. From the [track compression review](#track-compression-review-2026-11-12): the draft aims at one message per track. For a track someone chooses to share, are up to 8 parts still right? Two mountain roads of 38 and 76 km took 3 to 6.
7. Should heights travel with a shared track? Mask bit 9's per-point heights lose the hills on a simplified line (R-11), so the choice is a coarse profile as an extension item, or none. They take room from the points. Not measured.
8. Answered by decision 25 (2026-11-16, preliminary): the `Route:` message carries the route's length, with a warning above 3 % and Send the exact line.
9. Route photos and the 25 MB backup quota (B1–B3): keep the photo files in backups with a size budget, or keep them out of backups? Over the quota Android backs up nothing for the app, messages included.
10. Points from the phone's GPS in your own saved routes (decision 21): may a saved route keep them in phone backups, and may Share and Export GPX send them? Until this is answered, Save my track keeps them, marked as the phone's, and Share and Export GPX leave them out.
