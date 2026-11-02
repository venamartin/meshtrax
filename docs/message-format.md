# MeshTrax message format

> **What this is:** how MeshTrax writes replies, reactions, GIFs, cards and
> other extras into a message, so other apps can read them. You don't need
> this to use MeshTrax. It's for people building or testing apps that talk to
> MeshTrax users. Terms are explained in the [glossary](glossary.md); the
> exact text that travels over the radio is called the "wire text".

MeshCore chat carries plain text. Everything MeshTrax adds on top of it,
replies, reactions, GIFs, markdown, cards and drawings, is plain text too,
so a message is still readable on an app that understands none of it. This
page lists everything MeshTrax sends and everything it reads, including
formats from other apps that it reads but never sends.

| Feature | MeshTrax sends | MeshTrax also reads |
|---|---|---|
| Mention | `@[Name]` | |
| Reply | MeshCore One reply | meshcore-open `@[Name] re:…` |
| Reaction | MeshCore One reaction | meshcore-open `r:HASH:INDEX`, older MeshCore One emoji-first order |
| GIF | Giphy link (default) or `g:ID` | `media.giphy.com` links |
| Markdown | whatever the user types | |
| Cards | `Location:`, `SOS:`, `Event:`, `Notice:` | `m:` marker, bare coordinates and maps links, Google Calendar shares, `meshcore://` links |
| Drawings | `SVG:` and path data | |
| Compression | `s:` SMAZ, only when switched on | `s:` SMAZ, always |

A channel message arrives from the radio as `Name: body`; the firmware adds
the sender's name. Everything below is about the body. Direct messages and
room posts carry the body alone.

## Mentions

`@[Name]` names a contact or channel member. MeshTrax inserts it with a
trailing space when you tap a name or pick one from the `@` list.

- A mention is drawn as a highlighted, tappable name.
- Any `@[Your name]` in a message (case-insensitive) counts as a mention of
  you: it notifies even in a muted channel when **Mention notifications** is
  on. A reply to you always carries your mention, so replies notify too.
- Leading mentions are addressing, not content. When MeshTrax matches a
  reply quote or a reaction hash against a stored message, it also tries the
  text with leading `@[Name]` mentions removed, because other apps quote and
  hash the message as they display it.

## Replies

### What MeshTrax sends

MeshCore One's reply format, in channels, direct messages and rooms:

```
@[{name of the person replied to}]
>{first 10 characters of their message}..
{reply}
```

For example:

```
@[GWQ∆🍓]
>Heading to..
Nice!
```

- The quote is the first 10 characters of the original, whitespace
  collapsed to single spaces and trimmed. `..` follows only when the
  original was longer.
- If the original started with your own mention, it is left out of the
  quote.
- When the reply is too long to fit, the quote shrinks to 6 characters, and
  if that still doesn't fit the quote line is dropped, leaving
  `@[Name]` + newline + reply.
- MeshTrax stores only the reply text with a link to the original, and
  rebuilds the wire text from that on every retry or resend.

### What MeshTrax reads

- **MeshCore One**: the format above. A `..` at the end of the quote is
  dropped before matching.
- **meshcore-open** (and MeshTrax before it switched):
  `@[Name] re:{quote}…{reply}` on one line. The marker may be `…` or `...`,
  `re:` is case-insensitive, and the reply may start on a new line.

A plain mention, `@[Name] hello`, is not a reply.

### Finding the original

For an incoming reply MeshTrax looks through recent messages (in a channel,
those that arrived in the last 48 hours) for one from the named sender whose text starts with the
quote. The comparison ignores case, collapses whitespace and strips leading
mentions on both sides. When found, the quote bubble shows the full original
and tapping it jumps there. When not found, the quote bubble shows the
quoted characters and the name.

## Reactions

### What MeshTrax sends

MeshCore One's reaction format:

| Where | Wire text |
|---|---|
| Channel | `@[{author of the message}]{emoji}` + newline + `{hash}` |
| Room | `@[{author of the post}]{emoji}` + newline + `{hash}` |
| Direct message | `{emoji}` + newline + `{hash}` |

For example `@[GWQ∆🍓]👍` + newline + `kryv4zmp`. An app that does not know
the format still shows a readable `@[GWQ∆🍓]👍`.

**Hash**: the first 5 bytes of `SHA-256(UTF-8 text + sender timestamp as a
4-byte little-endian unsigned integer)`, written as 8 characters of
lowercase Crockford Base32 (`0123456789abcdefghjkmnpqrstvwxyz`, no i, l, o
or u).

_In plain words: the hash is a short fingerprint of the original message,
so the reaction can say which message it belongs to without repeating it.
SHA-256 is a standard way to compute such a fingerprint; Crockford Base32
writes it with letters and digits that are hard to confuse._

- **Text**: in a channel, the body after `Name: ` with spaces and tabs
  trimmed from both ends (never newlines). Mentions and reply markup are
  kept: a reaction to a reply hashes the full reply as sent, `@[Name]` line
  and quote line included. In a direct message or room, the text exactly as
  received.
- **Timestamp**: the sender's timestamp in seconds as it was on the air. For
  your own message that is the timestamp of the last attempt sent, since a
  retry is stamped again and the copy that got through is the one others
  hold.

The quick-reaction row offers the twelve emoji you used last, topped up from
👍 ❤️ 😂 🎉 👏 🔥 😮 😢 🙏 👀 ✅ 💯. Any emoji can be sent from the full picker.

### What MeshTrax reads

- **MeshCore One**, the format above, in either order: mention first
  (current) or emoji first, `{emoji}@[{name}]` (older MeshCore One builds).
  The message must be exactly two lines; the first line holds at most 8
  characters of emoji after the mention, and the second exactly 8 Crockford
  characters (upper or lower case; `O` is read as `0`, `I` and `L` as `1`).
- **meshcore-open** (and MeshTrax before it switched): `r:{hash}:{index}`,
  where the hash is 4 lowercase hex characters and the index is 2 lowercase
  hex characters pointing into a fixed table of emoji. The table is frozen
  in `ReactionHelper.reactionEmojis` and must never change, or old reactions
  would decode as the wrong emoji.

### Matching

- A reaction is matched against messages that arrived in the last 48 hours.
  For a MeshCore One reaction, MeshTrax tries every stored form of each
  message's text (as received, trimmed, with leading mentions removed) with
  every timestamp the message was seen with, and prefers messages from the
  sender named in the mention.
- The same person reacting with the same emoji twice counts once.
- Two lines that merely look like a reaction are only treated as one when
  the hash matches. Until then the message is kept and shown as
  `{emoji}@[{name}]` with a reaction icon. If the original arrives later the
  reaction moves onto it and the placeholder disappears.

## GIFs

### What MeshTrax sends

Picking a GIF puts one of these in the message box:

- `https://giphy.com/gifs/{id}` when **Send GIFs as links** is on (the
  default). Other apps show a tappable link.
- `g:{id}` when it is off. This is the meshcore-open format: shorter, but
  other apps show it as raw text.

### What MeshTrax reads

The first of these found anywhere in a message, shown as the GIF:

- `g:{id}` (meshcore-open), with an id of at least 12 characters of
  `A-Z a-z 0-9 _ -`.
- `https://media.giphy.com/media/{id}/giphy.gif`
- `https://giphy.com/gifs/{id}` or `https://giphy.com/gifs/{title-words}-{id}`,
  with or without `www.` and a trailing `/`.

The scheme is optional on both links (`http://`, `https://` or none). A link
must stand alone, separated from other text by spaces or line breaks, so a
GIF still shows after a leading `@[Name]` or inside a reply. Any other text
in the message is shown under the GIF.

## Markdown

MeshTrax draws markdown when **Show text formatting** is on. It is display
only: the text sent and stored is never changed, so reply quotes and
reaction hashes always work on what was typed. Other apps show the raw
characters. With formatting off, links, mentions and the other tappable
pieces still work and every markdown character is shown as typed.

| Type | Shows |
|---|---|
| `**bold**` | bold |
| `*italic*` or `_italic_` | italic |
| `***bold italic***` | bold italic |
| `__underline__` | underline |
| `~~strike~~` | strikethrough |
| `\|\|spoiler\|\|` | hidden until tapped |
| `` `code` `` | inline code (one line) |
| ```` ```code block``` ```` | code block |
| `# `, `## `, `### ` at the start of a line | large, medium, small header |
| `-# ` at the start of a line | small subtext |
| `[text](https://…)` | `text` as a link |
| `\*` | a literal `*` |

- Emphasis works within one line. An opening marker must be followed by a
  non-space, and a closing marker preceded by one. `_` and `__` do not open
  or close inside a word, so `snake_case_name` stays as typed.
- A code block may start with a language name on its own line (`dart`,
  `python`, `json` and other common ones); it is left out of what is shown.
  Nothing inside code is formatted.
- `[text](url)` only accepts `http` and `https` links, and only when the
  text does not itself look like an address, so a link can't pretend to go
  somewhere it doesn't.
- `\` escapes any of `` \ ` * _ ~ | [ ] ( ) # - @ ``.
- A mention is kept whole even when the name holds markdown characters.
- Previews, quotes and notifications show the text without markers, with a
  spoiler as `▮▮▮`.

## Tappable pieces

Found in every message, formatting on or off, and never formatted inside:

- Web addresses and email addresses.
- `meshcore://channel/add?…` and `meshcore://contact/add?…` links: join the
  channel or add the contact.
- Coordinates (`lat, lon` with at least three decimals) and `geo:` URIs:
  open the map.
- `@[Name]` mentions.
- Hashtags (`#` followed by letters, digits, `_` or `-`).

## Emoji-only messages

A message of nothing but emoji, at most 5, is drawn large without a bubble
colour.

## SMAZ compression (`s:`)

SMAZ is a simple way to squeeze short English text into fewer bytes, so a
longer message fits. Base64 writes the squeezed bytes as plain characters.

MeshTrax decodes any message that starts with `s:` followed by Base64 SMAZ
data (the meshcore-open format). It sends one only when **SMAZ compression**
is switched on for that channel or contact, and only when the result is
shorter than the plain text. GIFs, cards and drawings are never
compressed. Apps that don't know the format show the raw `s:` text, so
only switch it on when everyone in the conversation uses an app that
reads it.

---

# Structured messages (cards)

MeshTrax uses one small, human-readable convention so a message can carry a
location, an SOS, an event or a notice that MeshTrax renders as a card while
every other app, and every person, still reads it as ordinary text. Anyone
can type one by hand from any app. Other MeshCore apps are welcome to adopt
it.

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
   unknown type word is ordinary text. `SVG:` is a keyword too, but what
   follows it is path data rather than fields; see [Drawings](#drawings).
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
   **The sender's own position.** A `Location` titled `My location` (any
   case, always English on the air) is where the sender is. Readers may
   show it as the sender's location, e.g. "GWQ's location". A `Location`
   with any other title, or none, is just a place.
5. **Compatibility.** Readers show every field they do not understand, so a
   newer sender never hides information from an older reader. Writers may
   add shapes and keys and may reorder fields. New types are added by
   registering a keyword.

## Examples

```
Location: 47.070123, 15.440123

Location: My location
47.070123, 15.440123
at the trailhead

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
- A room server's own post (sent with the server's `room.post` command) as
  an announcement card. With a type keyword it is that card instead.

## Byte budget

A byte is roughly one plain character; an emoji or an accented letter
takes 2 to 4. LoRa messages are small, so every extra takes room from your text.

A channel message has roughly 125 to 140 bytes for text, a direct message
158, a room post 150 and a room announcement (the server's `room.post`
command) 147. The type header costs 5 to 9 bytes, a position 22 plus a
1-byte separator, a when 10 to 30, an `expires=` 19 to 25. An event with
title, time, place and position needs about 60 bytes plus the title and the
place.

---

# Drawings

A message can carry a small line drawing as SVG path data. MeshTrax draws
it. Any other app shows the text, and the path data pastes into any SVG
editor as the `d` of a `<path>`.

```
SVG:M10 50h70m-8-6 8 6-8 6
To the hut
```

A drawing is one ordinary text message, so it costs the airtime of any text
that long. There is no way to split one across messages. Other MeshCore apps
are welcome to draw these too.

## Rules

1. **Header.** The body starts with `SVG:`. MeshTrax sends no space after the
   colon. Readers accept any case and spaces or tabs around the colon, but
   the path data must start on the same line. Reply and mention markup may
   come before it.
2. **Drawing.** The rest of that line is SVG path data, exactly as in the
   `d` attribute of an SVG `<path>`: the commands `M L H V C S Q T A Z`, in
   either case. It means a path with `fill="none"`, stroked in the reader's
   pen color with round ends and joins. That convention is part of the
   format: SVG's own default would fill the path black and draw no line.
3. **Caption.** Everything after the first line is a caption, shown under
   the picture. There are two exceptions. A map line may come right after
   the path data; see [Map background](#map-background). And for path data
   that another tool wrapped onto more lines, a following line that holds a
   digit, and that still reads as path data when joined to the path with a
   space, continues the path. So a caption of numbers alone, such as
   `10 20`, is read as more path; give it a word.
4. **Path data only.** Readers never read markup from a message. `SVG:`
   followed by `<svg>` is ordinary text. That keeps what a stranger can send
   down to numbers and one-letter commands, with no loops, so the work a
   message causes grows only with its length.
5. **Not a drawing.** Path data that doesn't read, goes past a limit below,
   or draws no line (only `M` commands) makes the message ordinary text, so
   `SVG: coming soon` stays a sentence.

## Limits

These are part of the format, so that everyone accepts the same messages.
Past any of them the message is ordinary text.

| Limit | Value |
|---|---|
| Path data | 300 bytes, after joining wrapped lines |
| Lines | 2,000, counting each line a curve or arc is broken into |
| Coordinates | Finite, and within ±1,000,000, control points included |
| Caption | 200 bytes |

Curves are broken into lines this way, so that every reader counts the same
lines:

- An arc becomes one cubic curve for each quarter turn or part of one, split
  evenly. A quadratic becomes one cubic.
- A cubic becomes `ceil(40 × L / S)` lines, at least 1 and at most 64. L is
  the length of its control polygon: from the current point through both
  control points to its end. S is the longer side of the box around every
  point of the path, control points included.

## Drawing it

The path data only says what to draw. How it looks is up to the reader, and
MeshTrax users can change it under **Drawings** in the app settings, or
switch drawings off to see the code instead.

- y points down, as in SVG.
- Scale the drawing to fit, keeping its shape, with a margin. Lines keep
  their width whatever the scale. A line of zero length, such as `h0`, is a
  dot.
- MeshTrax's look is modelled on a green Apple II monitor: a screen of
  `#010A03` with faint scanlines, and a pen of `#33FF33` drawing 2 dp lines
  with a soft glow.

## Map background

A drawing can sit on a map, to mark where a boat is anchored, point at a
building or show the way to a spot. The map goes on its own line, right
after the path data and before any caption:

```
SVG:M55 33l8 8m0-8-8 8
map=16/36.9695/-121.9525/c
Anchored here
```

- **Map line.** `map=`, then the zoom, latitude and longitude separated by
  `/`, the way openstreetmap.org writes a view:
  `openstreetmap.org/#map=16/36.9695/-121.9525` shows the same place. The
  zoom is a whole number from 0 to 18, counting 256-pixel tiles. Latitude
  is within ±85.0511 and longitude within ±180, in decimal degrees. MeshTrax
  writes 4 decimals, leaving off trailing zeros.
- **Map type.** An optional last part of one letter: `u` for a USGS topo
  map, `c` for NOAA charts. No letter means the standard street map. A
  reader that doesn't know the letter shows the standard map. Readers
  accept any case.
- **Frame.** The map shows 400 × 300 map pixels at that zoom, centred on the
  point. Near 37° N that is 763 m across at zoom 16 and 191 m at zoom 18.
- **Coordinates.** Over a map, path data isn't fitted to its own size. Its
  numbers are places on the frame, 0 to 100 across and 0 to 75 down, one
  unit being 4 map pixels, with y down. Lines past the frame's edge are cut.
- **Not a map line.** A line starting `map=` that doesn't read this way is
  part of the caption, and the drawing has no map.
- **Showing it.** Show the map type that was sent where the reader has it,
  otherwise the standard map. MeshTrax fills the standard map with its base
  map where nothing is downloaded. The base map has no detail at street
  zooms, so there MeshTrax says the area isn't downloaded. Over a map,
  MeshTrax draws the lines in the pen color with a thin dark edge instead of
  the glow, and shows the map's credits under the frame, never over the
  drawing.

## How MeshTrax writes them

Other apps don't need to follow this. It's how MeshTrax keeps drawings
small.

- Whole numbers on a 0–99 grid, fitted to the drawing's bounds.
- Each command absolute or relative, whichever is shorter. Commands repeat
  without their letter, and a minus sign doubles as the separator.
- A tap is `h0`.
- A circle or ellipse is one arc from its rightmost point, ending 0.1 short
  of where it started, then `z`. The `z` puts the position back on whole
  numbers.
- An X is two crossing lines. A route keeps every point that was tapped.
- A line, arrow or route point started near a route's points, or near the
  end of a line, arrow or stroke, snaps onto it. A line that starts exactly
  where the one before ended carries on from it with no move, so an arrow
  on the end of a route costs no move at all.
- Finger strokes are simplified with Ramer–Douglas–Peucker, at the finest
  tolerance whose message still fits. Shapes and routes stay exact.
- **Over a map**, the user pans and zooms, then taps **Draw here**: the map
  snaps to a whole zoom step and a centre rounded to 4 decimals, so the
  frame they draw on is exactly the one every reader gets. Moving the map
  afterwards carries the drawing along with the ground.
- **Paste** reads a whole SVG file, but only one the user pastes on their own
  phone. MeshTrax keeps the visible paths, breaks them into lines and writes
  path data. Colors, fills and text don't travel.

## Examples

Bytes include the `SVG:` header, and `↵` is a line break.

| Drawing | Wire text | Bytes |
|---|---|---|
| Dot | `SVG:M5 5h0` | 10 |
| Line | `SVG:M10 10 90 90` | 16 |
| Rectangle | `SVG:M10 10h80v80H10z` | 20 |
| Arrow | `SVG:M10 50h70m-8-6 8 6-8 6` | 26 |
| Arrow with a caption | `SVG:M10 50h70m-8-6 8 6-8 6↵To the hut` | 37 |
| Circle | `SVG:M90 50a40 40 0 1 1 0-.1z` | 28 |
| Stick figure | `SVG:M58 18a8 8 0 1 1 0-.1zM50 26v34l-14 30m14-30 14 30M26 44l12 6 12-6 12 6 12-6` | 80 |
| X on a chart | `SVG:M55 33l8 8m0-8-8 8↵map=16/36.9695/-121.9525/c↵Anchored here` | 63 |
| Arrow on the street map | `SVG:M30 64l27-21m-7 1 7-1-3 6↵map=18/36.9643/-122.0177↵Meet at the carousel` | 75 |

## Byte budget

The header costs 4 bytes. That leaves 156 for path data in a direct message,
146 in a room post, and 144 in a channel for a sender with a 10-byte name.
MeshTrax keeps a direct message with a drawing to 158 bytes in all, so 154
for path data, because a longer direct message gets fewer send attempts. A
caption costs its bytes plus 1 for the line break, and a map line about 26
plus 1. A finger stroke costs 4 to 5 bytes a point, so a channel message
holds about 30 points, or about 25 over a map.
