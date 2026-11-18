# Proposal: weather alerts and reports

> **What this is:** a plan for weather cards. Bots send short weather warnings, watches and reports as plain text. MeshTrax shows them as cards, pins a warning until it ends or is cancelled, and can notify.
>
> **Who it's for:** MeshTrax developers and people who write weather bots.
>
> **Status:** draft for review, November 2026. Future work; nothing is built. It extends the cards in [message-format.md](../message-format.md).
>
> New to the terms? See the [glossary](../glossary.md).

## Goals

- **Readable everywhere:** plain text that any person can read in any app.
- **App first, bots later:** MeshTrax ships support first, and bots start once most users have that version (see [Rollout](#rollout)).
- **Ends on its own:** nothing weather-related stays pinned forever, even when no expiry is sent.
- **Can be withdrawn:** a tornado warning cancelled at 4:12 drops off at 4:12, not at its 4:45 expiry.
- **Fits:**
  - A typical alert fits a channel message: 160 bytes, less the sender's name and 2.
  - A full alert fits a room announcement: 147 bytes, sent with the server's `room.post` command.

## Three kinds of message

| Kind | Keyword | Pins | Example |
|---|---|---|---|
| Warning (act now) | `Alert:` + `wx=` | Yes, above everything but SOS, until it expires or is cancelled | Tornado Warning, Flash Flood Warning |
| Lesser alert | `Notice:` + `wx=` | Yes, with the notices, until it expires or is cancelled | Winter Storm Watch, Small Craft Advisory |
| Report | `Weather:` | No | Current conditions, forecast, tides, Kp |

The keyword follows the level in `wx=`:
- A warning (`.W`) goes out as `Alert:`.
- A watch, advisory or statement (`.A`, `.Y`, `.S`) goes out as `Notice:`.

The keyword is there for people. MeshTrax goes by the level, so a wrong keyword still gets the right colour, pin and notification.

Reports don't pin, so hourly reports don't bury the notices.

## Alerts

```
Alert: Tornado Warning till 4:45 PM
Take shelter now. Norman, Moore
35.220, -97.440
expires=2026-11-18 16:45
wx=TO.W
id=K7Q2
```

124 bytes. The notice rules apply: a headline, detail lines, an optional position, and `expires=`.

```
Notice: Winter Storm Watch Fri-Sat
30-60cm above 1500m, gusts 80 km/h
expires=2026-11-21 18:00
wx=WS.A
id=WS31
```

110 bytes.

Keys:
- `wx=EVENT.LEVEL` (required): marks a weather alert.
- `expires=` (required): without it the alert is a card that never pins (see [Safety caps](#safety-caps)).
- `id=`: 1–8 letters and digits, unique for the sender while the alert lasts.
- `act=new|upd|can|test`: `new` when left out.
- `r=25km`: a radius around the position.
- `tz=-8`: the offset from UTC (see [Time zones](#time-zones)).
- `src=NWS`: who issued it.

Bots always send `wx=` and `id=`, so an alert has at least four lines. Older MeshTrax reads a message of up to three lines with coordinates as a Location card.

**Levels** (the NWS VTEC significance letters):

| Letter | Level | Colour |
|---|---|---|
| W | Warning | red |
| A | Watch | orange |
| Y | Advisory | yellow |
| S | Statement | — |

**Events:** two-letter codes taken from VTEC. A * marks a code added here, not in VTEC. An unknown code shows as a notice in its level's colour.

| Group | Codes |
|---|---|
| Storms | TO tornado, SV severe thunderstorm, LT* lightning, MA special marine |
| Water | FF, FA, FL, CF, LS, SS storm surge, TS tsunami |
| Tropical | HU, TR, TY |
| Winter | WS, BZ, IS, LE, WW, SQ, AV* avalanche |
| Cold | EC, CW, WC, FZ, FR, HZ |
| Heat | EH, HT |
| Wind | EW, HW, WI, LW |
| Fire and air | FW red flag, SM smoke, AQ* air quality, AF ashfall, DS, DU |
| Visibility | FG, ZF |
| Marine | SC, GL, SE, SR, HF, SU, RP, BH, UP |
| Space | GM* geomagnetic, RB* radio blackout, SP* solar radiation |
| Other | XX* |

### Updating and cancelling

An alert is known by its sender plus its `id=`.

- **`upd`:** replaces the alert. Only the newest copy stays pinned, and its `expires=` counts. Earlier cards read "Updated".
- **`can`:** withdraws the alert at once, whatever its `expires=` said. The card unpins, greys out and reads "Cancelled 4:12 PM". It is never deleted.
- **`test`:** never pins or notifies.

```
Alert: Tornado Warning cancelled
expires=2026-11-18 16:45
wx=TO.W
id=K7Q2
act=can
```

81 bytes. An update or cancel uses the same keyword as its alert.

- **The newest wins**, by the sender's timestamp rather than the order of arrival. A sender time more than 10 minutes ahead of the phone's clock is not believed.
- **A cancel that arrives first** is kept until its `expires=`, so a late original arrives already cancelled. That is why a cancel repeats the original's expiry.
- **A watch upgraded to a warning** goes out as a new `Alert:` with a new id, plus a `Notice:` cancel of the watch.
- **Ids are the bot's choice.** The VTEC event number works (`id=TO0123`).

### Who can update or cancel

A faked cancel is as dangerous as a faked warning.

- **Direct messages:** the sender is a full public key, so updates and cancels count in full.
- **Rooms:**
  - Only the room server's own posts pin today; a member's notice is just a post. So a weather bot must post as the server itself, through `room.post` or the server's own code. A bot that joins the room as a member never pins.
  - Updates and cancels count only from the server's own posts.
  - MeshTrax knows a room post's author by a 4-byte key prefix, which the server vouches for.
  - A room is the best home for a weather bot: the server's posts pin for every member and reach members who were offline.
- **Channels:**
  - The sender is only a name, which anyone can use. So updates from the same name are shown.
  - A cancel greys the card and reads "Cancel from {name}, not verified", but the card stays pinned until its `expires=`. A stale warning is safer than a real one hidden by a fake cancel.
  - An update that ends the alert sooner is handled the same way, since a fake one would unpin it just as a cancel would.
  - This differs from rooms and DMs on purpose (open question 4).
- **Not an official warning system:** `src=` names where the alert came from, and the card says it was relayed.

## Reports

```
Weather: KOKC now
t=14C|rh=82%|w=NW 18kmh g30
p=1012hPa falling|sky=overcast
id=OBS
```

83 bytes. `|` separates fields, as on every card. Values carry their units, and readers convert them to the user's units.

Keys:

| Group | Keys |
|---|---|
| Conditions | `t`, `fl` (feels like), `dp`, `rh`, `w` (direction, speed, `gNN` gust), `p` (plus rising, falling or steady), `sky`, `vis`, `cloud`, `rain` (rate, or total over a period), `snow` |
| Forecast | `hi`, `lo`, `pop` |
| Air | `uv`, `aqi`, `pm25` |
| Lightning | `ltg` (nearest strike in the last 15 min) |
| Marine | `wave` (height, period, direction), `sst`, `tide` (H/L, time, height) |
| River | `stage` (stage / flood stage) |
| Space and sun | `kp`, `sfi`, `sun` (sunrise-sunset) |
| Other | `stn`, `wx` (an alert in force), `id` (a newer report replaces an older one), `expires` |

Units read: C/F, kmh/ms/mph/kt, hPa/inHg/mb, km/m/mi, mm/in, cm/in, m/ft.

### `sky=` words

Readers draw an icon for each of these and show any other word as text. Examples: `sky=overcast`, `sky=heavy rain`, `sky=tstorm hail`.

| Group | Words |
|---|---|
| Sun and cloud | `clear` (or `sunny`), `fair`, `partly`, `cloudy`, `overcast` |
| Low visibility | `fog`, `frz-fog`, `mist`, `haze`, `smoke`, `dust`, `sand`, `ash` |
| Rain | `drizzle`, `rain`, `showers`, `tstorm` |
| Frozen | `snow`, `blsnow` (blowing snow), `sleet`, `frz-rain`, `hail` |
| Other | `wind`, `funnel` (funnel cloud or tornado) |

- **Day and night:** `clear` and `sunny` mean the same. Readers draw a sun or a moon by the time the report was sent, or by the start of a forecast's period. The same goes for the sun or moon behind `fair` and `partly`.
- **Intensity:** `light` or `heavy` may come before a word: `sky=light snow`, `sky=heavy rain`. No word means moderate. Readers show it in the label and may draw a lighter or heavier icon. These are words rather than the `-` and `+` of aviation reports, so anyone can read them.
- **Two at once:** up to two conditions, the main one first, separated by a space: `sky=tstorm hail`, `sky=rain snow`, `sky=heavy tstorm hail`. Readers draw the first and list both. `light` or `heavy` goes with the word right after it.

### Forecasts

A forecast gives its period in the when shape that events use:

```
Weather: Tonight
Rain, heavy at times. Low 7C
2026-11-18
lo=7C|pop=90%|rain=15mm
id=FC1
```

87 bytes.

**Lifetime:** a report with the same id replaces the previous one. A report goes stale at its `expires=`; without one, at the end of a forecast's period, or 3 hours after it was sent. Stale reports are greyed, never hidden.

## Time zones

Times are local, as on every card today. The optional `tz=` gives the offset from UTC:
- It may hold half hours: `tz=-3:30`, `tz=+5:30`, `tz=+9:30`.
- The bot sends the offset in force, daylight saving included.

It is a separate key rather than a `Z` or `-08:00` suffix, because the current reader's `expires=` parsing rejects a suffix. A notice with one would never expire.

## Safety caps

These apply on the reader's side:

- **No usable `expires=`:** an alert (`wx=`) shows as a card but never pins. In a channel a plain notice with no expiry pins until it is dismissed, so it must not fall back to one.
- **48 hours:** alerts count as expired 48 hours after they were sent, whatever `expires=` says. Long alerts are sent again with `act=upd`.
- **Matching:** cancels and updates are matched only against the last 48 hours, the same window as replies and reactions.
- **Sender times:** a sender time more than 10 minutes ahead of the phone's clock is not believed.

## Rollout

Older MeshTrax already does something with each kind, which is why bots wait until most users have the new version:

| Message | In a channel, older MeshTrax | A room server's post, older MeshTrax |
|---|---|---|
| `Alert:` | Plain text | An announcement card; the newest server post pins |
| `Notice:` + `wx=` | A notice that pins until `expires=`; a cancel pins next to it | The same |
| `Weather:` | Plain text | An announcement card. Each hourly report would take the room's announcement pin |

So a bot holds back all three kinds, reports included.

## What MeshTrax would do

- **Card:** the level's colour, an event icon, "until 4:45 PM", the source, and Updated, Cancelled or Test. A report shows its values as a grid in the user's units.
- **Pins:**
  - Warnings go below SOS and above events. Watches and advisories go with the notices.
  - Only the newest copy of each alert pins.
  - A `Weather:` report never takes a room's announcement pin.
  - The bar shows at most 5 rows, so with several alerts active, older notices can drop off.
- **Notifications:**
  - A warning notifies in a muted channel or room when a new "Weather warnings" setting is on (off by default).
  - An update notifies only when the level goes up. Cancels and reports never notify.
- **Map:** the alert's position with its `r=` circle, until it expires or is cancelled.
- **Wire:**
  - `Alert`, `Weather` and `Wx` join the card keywords, so MeshTrax never compresses them.
  - `Alert:` is read as a notice marked as an alert.
  - The notice card gains `wx`, `id`, `act` and `r`.
  - A new weather card reads `Weather:`.

## Open questions

The recommendation comes first in each.

1. **`Weather:` or `Wx:`?** Recommended: send `Weather:` and read both. `Wx:` saves 5 bytes, and reports don't pin, so "Wx: nice day" typed by a person is harmless.
2. **Lesser alerts:** keep `Notice:` + `wx=`, or give them their own keyword? Recommended: keep `Notice:`. Older apps then pin them until their expiry, which is the right fallback.
3. **`Alert:` without `wx=`:** should it be a general alert (evacuation, boil water, road closed), and should `id`/`act` work on every notice? Recommended: yes to both.
   - A general alert pins only with `expires=`; otherwise "Alert: battery low" typed in a channel would pin for good.
   - `id`/`act` count only from the server's own posts in a room, and as in question 4 in a channel.
4. **Channel cancels:** Recommended: a cancel greys the card, reads "not verified" and leaves it pinned until its expiry. The alternative is to unpin at once, as in rooms and DMs. That is quicker, but a fake cancel would then hide a real warning.
5. **Outside the US:** Recommended: a table that maps MeteoAlarm warnings to these codes. Words in `wx=` would cost bytes and need translating.
