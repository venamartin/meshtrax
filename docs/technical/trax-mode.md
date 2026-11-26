# TRAX mode

> **What this is:** How TRAX works in MeshTrax today. It covers TRAX mode itself, the trip and its members, asking a member's radio, each member's location on the trip channel, and how the map shows the group. It replaces two closed plans, location sharing (#240) and saved routes (#242). What they planned that isn't built is under [Not built yet](#not-built-yet).
>
> **Who it's for:** developers working on MeshTrax.
>
> **Status:** built, not yet field-tested. Every rule here is preliminary: the desert field tests decide them. Firmware facts are from MeshCore companion-v1.18.0.
>
> New to the terms? See the [glossary](../glossary.md).

## What it does

TRAX is for a group on a remote trip: no cell service, no repeaters, radios that reach each other only directly.

- **TRAX mode** moves the group's radios to an off-grid frequency with **Off-Grid Repeat** on, so every radio relays for the others. Nobody on the regular mesh hears a radio in TRAX mode, Public included.
- **The trip** is a private channel. Its members are found from who posted there.
- **Members can ask my radio:** each member's radio answers the others' position requests by itself, so a member can be found with their phone dead, locked or in a pocket.
- **Locations:** in TRAX mode, every member's MeshTrax sends its radio's location to the trip channel on a timer, with the trail behind it now and then and older pieces of their track between. A member can ask for the rest. On the regular mesh a location goes only when asked.
- **The map** shows one pin per member, a card with their latest figures, their track and the group's list.

**Code:**
- `lib/services/trax_service.dart`: the switch, Leave and the prompts.
- `lib/services/trip_service.dart`: trip members, grants and asking silent members.
- `lib/services/radio_ask_service.dart`: Ask their radio.
- `lib/services/trax_beacon_service.dart`: sending locations.
- `lib/services/trax_track.dart`: your own track.
- `lib/services/trip_positions.dart`: the locations received.
- `packages/traxshare`: the report format, the track's pieces and the ask.
- `lib/models/trax.dart`: settings, saved radios and presets.
- `TraxMessage` in `lib/helpers/structured_message.dart`.
- Screens and widgets:
  - `lib/screens/trax_settings_screen.dart`;
  - `lib/widgets/trax_button.dart`, `trax_sheet.dart`, `trax_dialogs.dart` and `trax_guide.dart`;
  - `lib/widgets/radio_ask_sheet.dart` and `my_location_button.dart`;
  - in `lib/screens/map_screen.dart`, the member pins, the card and the group list.

## TRAX settings

One set per phone, in the preferences store under `trax_setup`:

- **Preset.**
  - The mesh's own (default): the off-grid frequency nearest the regular one, from the radio's allowed list (CMD 60), with the mesh's bandwidth, spreading factor and coding rate. In the US that is 918.000 MHz, 62.5 kHz, SF7, CR5.
  - **Long range** (picked by hand): the same frequency at 250 kHz and SF11, the firmware's off-grid preset. It has about 4 to 5 dB more link margin and 2.5 to 3 times the airtime.
- **Trip channel:** private channels only (`Channel.isPrivate`):
  - not Public, and not empty or nameless;
  - not a hashtag channel, whose key `sha256('#' + name)` anyone can work out. A `#` name cut at the radio's 31-byte limit can't be checked, so it counts as a hashtag channel.
- **Trip ends:** a date and time. Switching needs one in the future.
- **Keep my track:** 48 hours by default (`keepTrackHours`: 6, 12, 24, 48 or 72 hours, or a week). It is how far back your own line goes, what the group gets of it, and when every phone deletes each piece of it.
- **Your icon:** how the trip sees you on their maps, cards and TRAX group list (`icon`): Hike (default), Vehicle, Boat, Motorcycle, Bicycle, Aircraft or Camp. Your own position stays the blue GPS dot.
- **Tell the group:** on by default.
- **Trip members:** everyone who posted on the trip channel in the last 30 days and is the one contact of that name on this radio, matched by name as the @ list does. New posters are added as they post. Members can be added or removed by hand (`added`, `removed`). A poster who isn't a contact shows "Not a contact on this radio".
- **Members can ask my radio:** on by default (`askMyRadio`). See [Trip setup](#trip-setup-members-can-ask-my-radio).
- **Location in adverts:** off by default (`advertPosition`). TRAX mode turns it on before the group check's advert, and Leave turns it off, but only if TRAX turned it on. Anyone in range can read an advert's position.
- **SOS alerts:** the same row as in the app settings. Once per phone, after picking a trip channel, a switch or Switch too, Android offers the Do Not Disturb override if it's off.

## Trip setup: members can ask my radio

A companion radio answers a telemetry request by itself with its GPS position (`MyMesh.cpp` 639 to 683 at the tag), but only to contacts it allows, and radios ship with telemetry denied. Trip setup sets this up for the trip, with nothing to press:

- As soon as a trip channel is picked, each member is allowed base and location telemetry by contact, and is made a favourite, so a full contacts table can't drop them.
- The radio's privacy goes from deny to "by contact", and its GPS goes on. If the GPS is already on, `gps_interval:0` is written instead: a stored 900 s, left by older app versions, makes a live fix look frozen for 15 minutes. Tracker boards refuse it and refresh every second anyway.
- **Leaving TRAX mode after the trip's end** puts it all back, with no question: permissions, privacy, and the GPS if it was off. Favourites stay. Leaving earlier keeps it.
- Turning **Members can ask my radio** off, or clearing the trip channel, also puts it back. A radio that isn't connected then is put back at its next connect.
- If **Share my location** is turned off later, Trip setup doesn't turn it back on. Its row says "Share my location is off: members can't ask."
- Privacy cost: during the trip, those members can read your radio's position whenever they ask, and you aren't told.

### Ask their radio

In a DM's menu, a map pin's dialog, the member card and the group's list (for a member with no location yet):

- The asking radio keeps one telemetry request in flight (`MyMesh.cpp` 1689 to 1690), so asks queue, one at a time, with 3 tries each.
- A try floods only when no repeater has been heard lately. Otherwise it uses the request ladder, which ends in floods.
- It reads twice, a minute apart. Matching readings, or an altitude of exactly 0, say the position may be old. An answer with no position says the GPS may be off.
- The answer becomes that person's pin as a radio answer, with its time and source.
- In TRAX mode the same tap asks their MeshTrax for their track, and the sheet says so. With their phone off, only the radio's answer comes. A member who isn't a contact has **Ask for track** on their card instead; it says when it last asked. See [The ask](#the-ask).

## One tap

`TraxService.start`, in this order:

1. **Save** the radio's settings on the phone before anything moves, under `trax_radio_<radio public key>`: frequency, bandwidth, SF, CR, TX power and repeat. They survive an app restart and another radio in between. The radio settings dialog's Off-Grid Repeat switch returns to the same place (`rememberNonRepeatRadioState`).
2. **Tell the group** (when on): post the TRAX message on the trip channel, then wait until the radio has sent it. A retune with the message still queued would send it on the new frequency.
   - The app reads `CMD_GET_STATS` core (send queue length, byte 10) and packets (floods sent, bytes 10 to 13) before posting.
   - Then it reads them again every 500 ms, until the queue is empty and one more flood has been sent, for at most 20 s.
   - If the send isn't confirmed, the switch goes ahead and the sheet says to tell the group another way.
3. **One settings write:** CMD 11 with its repeat byte on.
   - The firmware applies it at once, with no reboot (`radio_driver.setParams`).
   - It saves it with `savePrefs`, which also stores the radio's current position as its fallback. So the sheet says to switch at the trailhead, after a GPS fix.
   - A frequency the radio doesn't allow for repeat is refused, and a refused frame changes nothing.
4. **Location in adverts,** when ticked, goes on.
5. **The group check:** one flood advert on the TRAX frequency, which every radio already there relays ([below](#the-group-check)).

### CMD 11 bytes

The firmware reads `[11][freq u32 LE, kHz][bw u32 LE, Hz][sf][cr][repeat]` (`MyMesh.cpp` 1424 to 1459 at the tag). Without the repeat byte, repeat goes off.

| | Bytes |
|---|---|
| Switch, US: 918.000 MHz, 62.5 kHz, SF7, CR5, repeat on | `0B F0 01 0E 00 24 F4 00 00 07 05 01` |
| Leave, back to USA/Canada: 910.525 MHz, 62.5 kHz, SF7, CR5, repeat off | `0B BD E4 0D 00 24 F4 00 00 07 05 00` |

## Tell the group: the TRAX message

Short readable text on the trip channel, MeshTrax only for now, parsed by `StructuredMessage.parse` like `Location:` and `Event:`. Its `TRAX` keyword keeps it out of SMAZ compression. It isn't in the public [message format](../message-format.md) yet.

```
TRAX: on until 2026-11-22 18:00 UTC-8
918.000 MHz 62.5 kHz SF7 CR5
```

```
TRAX: off
```

- **The end** is the sender's wall clock with its offset from UTC: `UTC`, `UTC-8` or `UTC+5:30`. Every phone knows the same instant, and a person reads the sender's local time. Phones show it in their own zone: "Ana switched to TRAX mode until Sunday 18:00. Switch too?"
- **The preset** line is frequency, bandwidth, SF and CR; Off-Grid Repeat is always on in TRAX mode. The message is about 66 bytes in all.
- **Read strictly:** the message is plain text if it has any of these:
  - a missing end, offset or preset line;
  - an impossible date;
  - a bandwidth, SF or CR the firmware wouldn't take.

  Extra lines after the preset are kept and shown.
- **Leaving** is sent before the radio moves back, so it goes out on the TRAX frequency to the members still there.

**Receiving:**
- **When a phone asks:** for a message on a private channel, heard live (not from the radio's backlog). It asks "Ana switched to TRAX mode until Sunday 18:00. Switch too?" or "Ana is leaving TRAX mode. Leave too?", the same question at most once in 10 minutes.
- **Only when it fits:** switching only when this radio is off TRAX and the end is still ahead; leaving only when it is on.
- **It never switches by itself:** one tap each, so a forged message can't take radios off the mesh.
- **Other places to answer:** the message's card in the chat offers the same button while it applies. So does its Android notification, for a phone in a pocket: **Switch too** or **Leave too** opens the app and asks the same question there; it never switches from the notification.
  - That notification has an id of its own per channel, so the chat after it doesn't take the button away.
  - A button that no longer fits opens the chat instead.
  - iOS shows the notification without a button.
- **Switching from a message** uses the message's preset and end, and posts nothing, since the group has been told. That channel and end become this phone's TRAX settings.

## Leave

`TraxService.leave`:
1. With Tell the group and a trip channel, post `TRAX: off` and wait as above. This never blocks: without a channel, it leaves untold.
2. Write the saved settings back with repeat off, then the TX power if it changed. The saved settings are then deleted.
3. Turn off location in adverts if TRAX turned it on. After the trip's end, put back what Trip setup changed.

A radio with nothing saved on this phone, because another phone switched it, asks which of the app's regular presets to return to. It picks one by itself only when exactly one preset has this TRAX preset.

## On connect

Once per connection, when the radio has reported its settings:

- **In TRAX mode:** the button shows on.
  - After the trip's end (this phone's switch, else TRAX settings), every connect asks: "Your radio is still in TRAX mode: the regular mesh can't hear you. Leave?"
  - It asks at most once in 10 minutes, so a radio that drops and reconnects doesn't stack the question.
- **Not in TRAX mode** with settings saved for it: something else took it back (another phone, the radio settings dialog), so the saved settings are deleted.

While it is on, Android's foreground notification reads "TRAX mode is on" and "The regular mesh can't hear you. Open MeshTrax to leave."

## At the trip's end

While the phone stays connected in TRAX mode, a timer waits for the trip's end.
- **At the end,** a notification says "Your trip has ended" and "Your radio is still in TRAX mode: the regular mesh can't hear you." The same question as at a connect comes over whatever screen is open.
- **The notification** has a category of its own, "TRAX mode" (`meshtrax_trax`), at default importance: it isn't the SOS alarm. Tapping it asks the question again while it still fits, and a question already open isn't put up twice.
- **A new end** in TRAX settings moves the timer, and while the radio is on it is this radio's end too. Following a member's TRAX message makes their end the timer's.
- **Leaving,** or the radio going away, cancels it. An end already past when it is set brings no notification: the next connect asks.
- **The timer** is a Dart timer. On Android the foreground service holds a wake lock while connected, so it fires on time. iOS suspends the app between radio events, and a suspended app runs no timers: there the notification can come late or not at all, and the question at the next connect remains.

## Locations on the trip channel

In TRAX mode, each member's MeshTrax sends its radio's location to the trip channel as an encrypted channel datagram. Nothing goes in public adverts, unless location in adverts is ticked.

- **How often:** 30 s × the people in the group (you plus the trip members, at least 2). That's 1 minute for two people and 2 for four.
  - A slower preset stretches it by its airtime compared with SF7 / 62.5 kHz (214 ms for a 37-byte packet).
  - Each send moves by ±20 % at random, and the first goes 10 to 30 s after TRAX mode starts.
- **The report** (`TraxReport`, `packages/traxshare`) is 29 bytes, 37 on air. It carries:
  - the position to 1e-5°, the fix age and the altitude;
  - the radio's battery, and a "may be old" flag;
  - how the person is moving. While moving, that is heading (1.4° steps) and speed (0.5 m/s steps), worked out over the last 50 m or more of the track, because the radio reports positions in 11 m steps. From 2 minutes after the last move, it is "not moving" (bit 12) and for how many minutes, held in the speed byte.
  - the sender's name every 30 minutes;
  - their icon (`TraxMapIcon`) in the low 4 bits of the last byte, in every report: 0 is Hike, as builds before test build 243 send, and one a build doesn't know shows as Hike. The high 4 bits are free.
- **The data type** is `0x0171` (`71 01` on air), in MeshTrax's block `0x0170` to `0x017F`, requested in meshcore-dev/MeshCore#3925. Channel datagrams need companion firmware 1.15 (version code 11). On older firmware the sheet says "This radio's firmware can't send your location to the trip. Update it."
- **Your track** (`TraxTrack`): while TRAX mode is on, the radio is read every 10 s, and a point is kept every 25 m. It is kept in pieces (`TrackPiece`), for your own line on the map and for the reports; there is no list of saved tracks.
  - A piece closes once its points, thinned to 15 m on an 8 m grid, would take more than 108 bytes, or at 500 points. The next starts at its last point.
  - A break closes it too: 2 minutes without a live reading, or a jump faster than 60 m/s. Nothing is drawn or sent across a break.
  - A piece is named by the minute of its first point. Two begun in one minute are named a minute apart.
  - Each piece is deleted Keep my track's hours after its last point, here and on the trip's phones: the hours go with it. Until then it stays across restarts and TRAX mode off and on.
- **What a report carries of it** (`TrackBlock`, mask bit 13, after the report's 29 bytes and the name): the grid, the hours kept, and for each piece its minute (low 16 bits), its span in minutes and its number of points. Then come all the points, newest first, each a step from the one before, the first from the report's position, as zigzag exp-Golomb (k = 3) on the grid. At most 157 bytes with the name.
  - Builds before test build 243 sent a trail with bit 10, before the name. Between them and later builds, positions still go both ways, but tracks don't, and an older build's name only comes in a report without a trail.
  - **The trail** goes in the first report, then every 5th, and never sooner than 10 minutes after the last. It carries the open piece, then as many closed ones as lie within 10 miles, whole. They are thinned alike: Douglas-Peucker from 15 m, doubled until they fit, then bisected to within 1 m, on a grid of max(8, ε/2) m.
  - **One older piece** goes halfway between trails, alone, at its finest and without the name. Each piece goes once a round, in a new random order every round, except those the latest trail carried at their finest. A piece closed during a round waits for the next. A phone that hears only some reports gets the track bit by bit.
  - Trails add about 0.25 % airtime for two people and 2.5 % for ten, and older pieces up to as much again. With two to four people a trail goes every 10 minutes, so ten older pieces take about 100 minutes; with ten people, about 250.
- **What's received** (`TripPositions`): the latest location from each member is kept for 30 days, per radio. A member's pin shows for 24 hours after their last report.
  - Their track is kept by piece. One that reaches later, or as far on a finer grid, takes the place of its minute's piece, even from an older report. Each goes when the member's hours have passed since its last point; their last place stays. At most 5,000 points a member, the oldest pieces first.
  - Their line is their pieces, then the positions reported since the newest, which a report with the newest piece starts again from its end.

### The ask

A member's MeshTrax asks another's for their track with a `TraxAsk`: version 1, subtype 3, on the trip channel, with the same data type.

- 17 bytes, and 2 for each piece held: the reports' 12-byte header, the first 4 bytes of the key of the member asked, how many pieces are held, then each one's minute (low 16 bits). It lists only pieces held at their finest (grid 8 m), up to 70.
- The member's phone, in TRAX mode and connected, answers within about 3 s with a trail. Then it sends each piece the asker lacks, newest first and alone in a report, a tenth of the interval apart (6 s for two people, 30 s for ten) and at least 3 s apart. Pieces that trail carried at their finest are left out.
- An ask heard while the app was away isn't answered: the asker asks again.
- To get a member's track the next day: open the TRAX group and tap them. Their card has Ask; a contact with no location yet is asked straight away.
- Each piece costs about 0.6 s of airtime at the mesh's own preset, before relays.

### The group check

The TRAX sheet shows the trip as one list: "3 of 4 on TRAX", with **Check again**.
- **Heard** means an advert, a post, a radio's answer or a TRAX report since the switch.
- **Each member** shows when they were heard, how long ago and how far ("1:37 PM · 7m ago · 1.2 km NE", plus "may be old"). A tap opens their card on the map, with their trail.
- **A member with no location** says why: asking, no answer, or not heard yet.
- **Asking silent members:**
  - two minutes after the switch or Check again, the radios of members not heard since the switch are asked, one at a time;
  - a member silent for 3 intervals has their radio asked, and after that at most every 10 minutes.

## On the map

- **One pin per member,** labelled with their name, at the newest place known of them: TRAX report, radio answer or advert.
  - It is grey when the reading may be old.
  - The member has no node, radio answer or guessed pin of their own, and their pin is drawn above the mesh's node pins.
  - A tap opens their card; a long-press opens their node's info.
  - In TRAX mode, trip members who are contacts get their pin before their first report. Out of it, they keep it only while their TRAX pin shows (24 h).
- **The card,** compact, over the clear map, with the member centred above it. It is about 160 dp tall for a contact and 120 for anyone else.
  - A header: the name, then when last heard, how long ago and how far ("10:40 PM · 1m ago · 0.4 mi NW", "may be old" in red), and a copy button.
  - One row of figures, each named on a long-press: heading with an arrow, speed or "Stopped N min", elevation, and the radio's battery with its bars (red below 20 %).
  - Chat and Ask their radio, for a contact.

  It keeps up as reports come in, and its "ago" counts on every 30 s. Their track shows in orange while it is open, over your own track in blue.
- **A person's info** (a node's dialog): last heard, location, distance from you, heading, speed or "not moving since", elevation, radio battery and path. Each comes from the newest of the TRAX report, the radio's answer and the advert. People get no line of sight or radio reach; repeaters, rooms and sensors keep both.
- **The TRAX group button,** at the bottom left in TRAX mode (three people), opens the group's list.
  - Rows are sorted by name and show distance, direction and when last heard. They are grey when the reading may be old, and members with no location come last.
  - A pick opens the card with the map on them. A contact with no location yet has their radio asked, and in TRAX mode their phone for their track.
  - The map's credits and offline card sit to the right of the button, or of your speed card above it.
- **Following:** My location keeps you in the middle as the radio's position moves, until the map is dragged; a zoom doesn't stop it, and the button is filled meanwhile.
  - Meanwhile your speed, heading and altitude show on a card above the group button (out of TRAX mode, at the bottom left). See the offline maps notes, 2026-11-26.
  - A tapped member, or one picked from a list, is followed the same way, with the card open or closed. Their trail stays until another member is tapped.
  - A sheet about something else pauses following while it is open. When it closes, the map goes back to whom it follows.

## In Chats

While TRAX mode is on, the trip channel is first in Chats, whatever came in since. Its row has the boot print in place of the lock, a TRAX label after the name and an orange outline. Out of TRAX mode it goes back to its place by its latest message.

## How TRAX works

A short guide in the app, told as a hike with friends behind you and more joining the next day (Martin). It shows the icons it talks about.
- **Eight steps** of a line or two: before you go, at the trailhead, on the trail, friends behind you, someone quiet, joining the next day, SOS, and the trip's end.
- **Then the icons:** the boot print off and on, a member's pin and a grey one, your blue dot, the two tracks and the trip channel's row.
- **By itself** after TRAX mode goes on, from the TRAX sheet or **Switch too**, until **Don't show this again** (`trax_guide_seen`).
- **Any time** from the info button in TRAX settings' top bar (Martin chose there only).

## My location

One button on the Chats and Map bars, after TRAX. Its icon shows two things:
- who can see your location: only you, people you picked, or your adverts;
- what the radio's GPS is doing: on, off or no fix, in red when someone can see it and there is no fix.

Its sheet has three rows:
- **Radio GPS**;
- **In my adverts**;
- **People who can ask:** people picked one by one. **Add someone** searches, with favourites and recent messages first. Trip members show "Until …".

There is no "all contacts" choice: a radio set to allow all says so in red, with **Pick people** instead. **What the icons mean** explains every top-bar icon.

## Side effects handled

- **Later settings writes keep repeat.** `setRadioParams` sends the repeat byte as on when the radio is known to repeat and the caller gave none. The radio settings dialog already sends the switch's state.
- **Health check:** `radio_frequency` and `radio_client_repeat` stay quiet in TRAX mode. `radio_trax_firmware` says when a radio can't relay (firmware before 1.13), so TRAX mode won't work there: in the field there's no internet to update it.
- **Nearby repeaters:** any retune clears them (`noteRadioSettingsSaved`); repeaters heard on the old settings can't hear the radio now.
- **Pathfinder** keeps one graph per mesh, keyed by frequency, bandwidth, SF and CR (`MeshId`).
  - The TRAX preset gets its own graph, and Leave reopens the regular one.
  - Between the retune and the reopen, frames and air events are dropped (`_onOtherMesh`), so nothing heard on TRAX lands in the regular graph.
- **Parked DMs:** unchanged. On TRAX, a flood relayed by a member (hop count over 0) wakes them as a repeater would.

## Bench simulator: `tool/trax_sim`

Pretend trip members for a bench, through a companion radio on a serial port (`--port`) or over Bluetooth (`--ble NAME`, already paired, through BlueZ).
- They walk a winding trail (`--walk NAME`), drive a road (`--drive NAME`) or follow a GPX track (`--gpx FILE=NAME`). Each sends reports by the rules above, older pieces included, and answers an ask for their track.
- `--radio 918,62.5,7,5` sets the radio first. When the simulator stops (Ctrl-C or SIGTERM), it puts the radio back as it was, Off-Grid Repeat included, and takes off a trip channel it added.
- It has no default port: on a shared machine the only serial port can be another program's radio.
- It prints distances from the start, never coordinates.
- It reads the radio's waiting messages, which are then gone from it, so it needs a radio of its own.
- It has its own CI step.

## Rules we keep

From the 2026-11-15/16 safety review of the closed plans. They are preliminary, and the field tests decide them.

- Never show a position without its age and where it came from. Call it live only when the reading changed during this connection; otherwise it is "may be old". An older report never replaces a newer one.
- Silence, a restart or a radio change never hides or deletes a last known position. Only age past 30 days, or a person, removes it.
- Tell people plainly when their own sharing has stopped or reached nobody, and why.
- There is a way to find a member that needs neither their phone nor a tap: their radio's own answer (Ask their radio), set up before the trip.
- Nothing waits forever for a repeater or an answer that may never come.
- A route never looks more certain than it is. It shows what MeshTrax can't know (closures, washouts, 4x4), the map data's date and where it really starts.
- Nothing is relied on before its field test, with real radios and both phone types. MeshCore can't call outside help, so carry a PLB or satellite messenger.

## Not built yet

These are ideas from the closed plans, kept for later. None of them is decided.

- **Field tests** on real radios and both phone types:
  - whether a retune takes effect during a receive;
  - battery life with repeat on;
  - airtime with five radios relaying;
  - range with each preset;
  - a locked iPhone;
  - a day of TRAX mode;
  - what an away radio loses.
- **For a member:**
  - Route here to a member, carrying the time of their position;
  - "Details for a search" and "Send to this channel" on their card.
- **In reports:**
  - a one-tap status (OK, need help, heading back) and an optional "back by" time. The status could take the high 4 bits of the last byte;
  - a setting to turn the trail off;
  - an early report on a sharp turn;
  - a "drawn to within N m" note on a trail.
- **Who got it:** which members' radios got a channel message.
- **The phone's GPS** as an opt-in local fallback for your own dot, Route here's start and your track. It would never be sent.
- **A recorder:** start and stop, no cap, and a list of tracks. Today the track exists only in TRAX mode, for the trail.
- **SOS:** a full-screen SOS alarm, and Beep their radio.
- **A Leave action** on the Android foreground notification. The service has no channel from its isolate to the app yet, so tapping the notification opens the app.
- **Saved routes** (the closed #242):
  - save the route the map finds as the active route;
  - a Routes list and a Routes layer;
  - GPX import and export;
  - a route editor, where each stretch follows paths or runs straight;
  - a `Route:` text message with the waypoints and path type, which the other phone rebuilds with offline routing.

  Sharing a recorded track needs a recorder first.
