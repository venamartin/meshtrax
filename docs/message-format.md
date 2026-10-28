# MeshTrax message format

MeshCore chat carries plain text. Everything MeshTrax adds on top of it,
replies, reactions, GIFs, markdown and cards, is plain text too, so a
message is still readable on an app that understands none of it. This page
lists everything MeshTrax sends and everything it reads, including formats
from other apps that it reads but never sends.

| Feature | MeshTrax sends | MeshTrax also reads |
|---|---|---|
| Mention | `@[Name]` | |
| Reply | MeshCore One reply | meshcore-open `@[Name] re:…` |
| Reaction | MeshCore One reaction | meshcore-open `r:HASH:INDEX`, older MeshCore One emoji-first order |
| GIF | Giphy link (default) or `g:ID` | `media.giphy.com` links |
| Markdown | whatever the user types | |
| Cards | `Location:`, `SOS:`, `Event:`, `Notice:` | `m:` marker, bare coordinates and maps links, Google Calendar shares, `meshcore://` links |
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

MeshTrax decodes any message that starts with `s:` followed by Base64 SMAZ
data (the meshcore-open format). It sends one only when **SMAZ compression**
is switched on for that channel or contact, and only when the result is
shorter than the plain text. GIFs and cards are never compressed. Apps that
don't know the format show the raw `s:` text, so only switch it on when
everyone in the conversation uses an app that reads it.

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

A channel message has roughly 125 to 140 bytes for text, a direct message
158, a room post 151 and a room announcement (the server's `room.post`
command) 147. The type header costs 5 to 9 bytes, a position 22 plus a
1-byte separator, a when 10 to 30, an `expires=` 19 to 25. An event with
title, time, place and position needs about 60 bytes plus the title and the
place.
