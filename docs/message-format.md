# MeshTrax structured message format

MeshCore chat carries plain text. MeshTrax uses one small, human-readable
convention on top of it so a message can carry a location, an SOS, an event
or a notice that MeshTrax renders as a card while every other app, and every
person, still reads it as ordinary text. Anyone can type one by hand from any
app. Other MeshCore apps are welcome to adopt it.

```
TYPE: field
field
field
```

## Rules

1. **Type.** The body starts with one of `Location`, `SOS`, `Event` or
   `Notice`, then a colon. `POI` is accepted as an alias for `Location`.
   Case does not matter on receive; MeshTrax sends it capitalised. Reply and
   mention markup (`@[Name]`, a quoted `>` line) may come before it. An
   unknown type word is ordinary text.
2. **Separator.** Fields are separated by line breaks or by `|`; both are
   accepted. MeshTrax sends one field per line. Free text never contains
   `|` (it becomes `/`) or a line break (it becomes a space).
3. **Field shapes.** Every field is recognised by its shape, in any order:
   - **Position**: `lat, lon` in decimal degrees with at least three
     decimals, e.g. `47.070123, 15.440123`. A maps link that carries
     coordinates (Google Maps, Apple Maps, `geo:`) counts too.
   - **Link**: any `http(s)://` URL that is not a maps link.
   - **When**: `YYYY-MM-DD`, optionally ` HH:MM`, optionally an end as
     `-HH:MM` (same day) or ` - YYYY-MM-DD HH:MM` (another day). A date
     alone means all day. Local time, no timezone.
   - **Extension**: `key=value` with a lowercase key. Readers keep and show
     unknown keys. Defined keys:
     - `expires=` on a `Notice`: when it stops applying, in the when shape
       without an end (`YYYY-MM-DD` means the end of that day). MeshTrax
       pins a room's notice until then and greys it out afterwards.
   - **Free text**: anything else. The first free-text field is the title or
     label, the second the detail (the place of an event, a note on a
     location), the rest are extra lines.
4. **Required shapes.** `Location` and `SOS` need a position, `Event` needs a
   when, `Notice` needs text. Without them the line is ordinary text, so
   "Event: see you at 5" stays a sentence. In a `Notice` a when-shaped line
   is text; its date goes in `expires=`.
5. **Compatibility.** Readers show every field they do not understand, so a
   newer sender never hides information from an older reader. Writers may
   add shapes and keys and may reorder fields. New types are added by
   registering a keyword.

## Examples

```
Location: 47.070123, 15.440123

Location: SCCARC Picnic
47.070123, 15.440123

Location: Water tap
47.070123, 15.440123
behind the hut

SOS: Broken leg, need help
47.070123, 15.440123

Event: Mesh meetup
2026-10-18 14:00-16:00
Hauptplatz
47.070123, 15.440123

Event: Fieldday
2026-10-18 - 2026-10-19
Schöckl

Notice: Repeater F857 down for maintenance on Saturday

Notice: Road to the summit closed
expires=2026-10-19 18:00
```

The same event typed by hand on one line:

```
Event: Mesh meetup | 2026-10-18 14:00-16:00 | Hauptplatz
```

## What MeshTrax also reads without the keyword

- `m:LAT,LON|LABEL|FLAGS`, the marker line of meshcore-open, Offband and
  older MeshTrax, as a Location.
- A message that is just coordinates, a `geo:` URI or a maps link, with up
  to two lines of text around it, as a Location. This is what the stock
  companion app, MeshCore One and the Google and Apple Maps share sheets
  produce.
- The text Google Calendar produces when an event is shared (title line,
  then `Oct 15  •  5 – 6 PM  •  View details & RSVP https://calendar.app.google/...`),
  as an Event. English month names only.
- A message that is just a `meshcore://channel/add?...` or
  `meshcore://contact/add?...` link, with up to two lines of text around
  it, as a card with a join or add button (Channel, Contact, Room,
  Repeater or Sensor, from the link's `type`). Inside a longer message the
  link stays a tappable join or import action.

## Byte budget

A channel message has roughly 125 to 140 bytes for text, a direct message
158, a room post 151 and a room announcement (the server's `room.post`
command) 147. The type header costs 5 to 9 bytes, a position 22 plus a
1-byte separator, a when 10 to 30, an `expires=` 19 to 25. An event with
title, time, place and position needs about 60 bytes plus the title and the
place.
