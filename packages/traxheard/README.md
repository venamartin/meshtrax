# traxheard

Was my channel message heard? traxheard works out the packet hash of a
channel text this radio sends. It then asks an observer server whether any
listening radio heard it. An observer server gathers what listening radios
hear. The package is pure Dart and has no screens.

## What MeshTrax does with it

"Check sends with observers" is a switch under App settings, Messaging. It
is off until the user turns it on and picks a server. While it is on:
- **Every channel message MeshTrax sends** is asked about. The server gets
  the packet's hash, never the text.
- **The hash is known before the message goes out.** A channel text is
  sealed without anything random: the radio sends `name: text` under the
  app's timestamp, sealed with the channel key.
- **A copy our own radio hears back** checks the worked-out hash. If they
  differ, the log says so, and the server is asked about the heard hash too.
- **A message an observer heard** gets a grey ear after its checkmark, and
  Packet Path lists the observers. Each observer shows its name, whether it
  heard the message direct or via N repeaters, and the signal of its closest
  copy, with the closest observers first. The message isn't sent again, and
  a Failed one goes back to Sent.
- **Reactions** aren't asked about.

`HeardService` (lib/services/heard_service.dart) is the app's glue. It
holds the switch and the server, and keeps who heard the last 300
messages. It and the connector meet only here:
- `onChannelSendStamped`: a send, first or again, is handed to the radio.
- `onOwnChannelEcho`: our radio heard a copy back.
- `confirmChannelSendHeard`: an observer heard it.

## Asking

`HeardChecker` asks about each send 10, 25 and 60 seconds after it goes out.
A resend is a new packet, with its own hash and its own three asks. Asks
due within 1 second of each other share one request. Once any hash of a
message is heard, every observer that heard it is reported, and the
message is not asked about again. At most 32 messages are tracked at once;
beyond that the oldest is dropped. A failed request is retried at the
message's next ask.

Servers: CoreScope's read API (`CoreScopeServer`). `knownServers` lists 16
in North America whose read API is open to anyone, each with the area its
observers listen in. A server only knows what its observers hear, on their
own frequency.

## How a channel send ends today

Once the radio has taken a channel message, it shows Sent. MeshTrax then
waits 30 seconds for our radio to hear a repeater pass it on:
- **No repeat heard:** it is sent again, up to the channel retry setting
  (0 to 3, 1 by default). When the last try isn't repeated either, it
  stays Sent.
- **Any repeat heard:** it shows Delivered and isn't sent again.
- **An observer heard it:** it isn't sent again either.

The radio's report of a heard packet holds at most 173 bytes, so a
message whose repeat is longer can't be heard back and isn't waited on.
A message the radio never takes is tried the same way, then shows Failed.

## Planned: a resend when only one repeater was heard

Owner's decisions, 2026-11-19. Not built yet.

**The problem.** One heard repeat ends the send, even when it is only the
user's home repeater, or a car repeater ("carpeater") riding along. The
message may never have gone further. Observers never hear it, so no ear
appears, and a second try would most likely have reached them.

**The rule.** It applies only when traxheard has proven that it works for
this radio: an observer heard one of this radio's own channel messages in
the last 2 hours. "The server answers" is not proof, because it says
nothing about coverage where the radio is now.
- **A send is out there** when an observer heard it, or when the copies our
  radio heard came through 2 or more different repeaters.
  - **Repeaters are counted by their codes**, over all the copies. A277 and
    BEEF heard separately count as two, and so does one copy that came
    through A277 and then BEEF.
  - **Two repeaters that share a code** count as one.
  - **Car repeaters don't count:** a repeater marked "Moves" or "Moves with
    me" in Pathfinder's "Does it move?" dialog.
- **Only one repeater heard and no ear:** the message still shows Delivered,
  and MeshTrax waits for the 25-second observer check. If nothing has
  changed by the 30-second mark, it sends the message once more. That is
  one extra resend at most per message, with its own echoes and its own
  three asks. A channel retry setting of 0, no resends, turns it off too.
- **Back-off.** A miss is a message that needed that resend, where neither
  the message nor its resend got an ear by the resend's last ask. After 3
  misses in a row, MeshTrax makes no more of these resends until any
  message gets an ear again. That covers a radio out of the observers'
  coverage (another state), a radio out of range, and a server that isn't
  working.
- **Everything else stays as today:** the switch off, no internet, the
  server down, or no ear in the last 2 hours all mean one repeat, stop.

**What it costs:**
- **Airtime:** a resend is a full flood. The one-resend cap and the back-off
  keep it bounded.
- **Duplicates in other apps:** a resend must go out under a new timestamp,
  or every repeater that carried the first copy drops it as already seen.
  Other apps may show the message twice. MeshTrax shows it once.

**Who owns what:**
- **HeardService** tells the connector, through a hook, whether these
  resends are allowed now: an ear in the last 2 hours, and fewer than 3
  misses in a row.
- **Pathfinder** tells it through `isCarRepeater(hop, width)`, which is
  true for a repeater code marked "Moves" or "Moves with me". The hook is
  null while Pathfinder is off, and then every repeater counts.
- **The connector** counts the repeaters it heard and makes the resend. It
  imports neither package.
