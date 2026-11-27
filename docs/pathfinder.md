# Pathfinder

Pathfinder helps your private messages (DMs) find their way across the mesh. It's on when you install MeshTrax fresh; if you installed before 1.8.8 it stays off until you turn it on. Words in **bold** are explained in the [glossary](glossary.md).

## The problem it solves

A LoRa radio can't reach far on its own. A message to someone across town has to pass through a chain of **repeaters**, like a bucket brigade.

To send a DM, your radio needs to know a **route**: which repeaters to use, in order. MeshCore radios remember only one route per contact, and when it stops working they keep trying it. MeshTrax then has to fall back to a **flood**: every repeater in range passes the message on. A flood usually gets there, but it's slow and keeps the whole area's repeaters busy.

## How it learns

Pathfinder listens. A flooded message collects the **repeater codes** of every repeater it passes through, and most of what the mesh carries is flooded: channel chatter, repeater **adverts**, delivery receipts, other people's messages. Each one shows which repeaters can hear each other.

From all of that, Pathfinder builds a map on your phone of:

- which repeaters hear each other, and how well;
- which repeaters can hear you;
- which repeaters can hear each of your contacts.

It's careful about what it believes. A repeater code it has never heard before only counts once it has been heard twice, at least 10 minutes apart. And a route only counts as proven when a message was delivered on it or a **trace** came back along it.

## What happens when you send

1. Pathfinder tries its best route.
2. If no receipt comes, it tries that same route once more, when it is a route Pathfinder rates as likely to work (50% or better). A missing receipt on such a route usually means two radios sent at the same moment, not that the route is broken. A route it rates lower gets one try, and the next route follows.
3. With five tries (Max Message Retries), another route follows: another way to the same repeater.
4. It floods only as a last resort: the last two tries, or only the last one when you have three tries and the best route was tried twice.

One exception to step 2: if their latest message was first heard by a different repeater than the one Pathfinder ranks first, a route ending at that repeater goes second, and the best route gets its second try after it. And a route that is likely to work and ends at a repeater not tried yet is worth more than a repeat: it goes before another way to a repeater already tried, and, once a route to a different repeater has been tried, before the best route's second try.

**Listening for your own message.** Your radio hears the first repeater pass your DM on, and MeshTrax recognises the message as yours. Then it knows the message left your side, whatever happens further along, and that repeater isn't blamed if no receipt comes. If MeshTrax doesn't hear it within a few seconds, the message most likely never reached the repeater, so your radio sends the very same packet once more. A repeater that did pass the first one on ignores the copy, so nothing travels across the mesh twice, and the other person never gets it twice. If the repeater stays silent the second time too, that try ends at once and the next begins after the usual short pause. The second copy waits for quiet air like any send, and the try's clock waits with it. MeshTrax only listens for a repeater your radio has heard in the last 10 minutes.

Which repeater hears them? The ones that were first to pass on their own messages, ranked by how often they did and how often a message through them was delivered. Their latest messages can overrule that record: a repeater that only passed their message on from another repeater, or missed their last two messages, is tried after the others until it hears them first again. Nothing is forgotten when that happens. And when a send through the top repeater fails while their latest message came in through another repeater, that other repeater goes first, until a send through it fails too.

Every delivery and every failure teaches it more. A failure counts against that link for a while, then fades: a day later it counts half as much, and after a few days hardly at all. So one bad moment doesn't block a good link for good.

**One missing receipt never drops a route.** A failed try is counted against the part that failed:

- *Your repeater* is set aside only when it twice in a row wasn't heard passing your message on. One such miss only makes MeshTrax ask which repeaters hear you (a Discover call). It comes back the moment it is heard passing something of yours on, or answers a Discover call.
- *Their repeater* is set aside only when, twice in a row, a message missed through it and then got through another way. If the message got through by that same repeater in the end, nothing is held against it.
- When MeshTrax can't listen for your repeater (it hasn't heard it lately), two failed tries in a row set it aside, as before.

**When nobody answers on any route.** Someone who has moved and hasn't sent anything since still has the old way back to you stored in their radio. Their radio takes your routed message, but its receipt goes down that old way and never reaches you, so every route looks dead and only a flood gets an answer. After three routed tries in a row to one person got no receipt (tries that never left your own repeater don't count), MeshTrax tries only its best route to them before it floods. The first routed try that gets a receipt brings the full list of routes back, and after an hour without such a try it starts afresh.

When it isn't sure which repeaters can hear you where you are, Pathfinder sends one short **Discover** call, at most once every 10 minutes. It does this:

- before your first DM from a place where it has no record of who hears you (your radio needs GPS for it to know the place). The DM waits about five seconds for the answers and then goes by the repeater that heard you best, where it would otherwise have flooded;
- after a send has failed and it has a doubt about your side, such as a repeater that wasn't heard passing your message on.

**When no repeater hears you.** After a flood, MeshTrax listens for a repeater passing your message on. If none does, but your radio heard a repeater within the last minute, the same packet goes out again straight away, up to twice, and nothing is shown: two radios most likely sent at once. If still none does, or the last repeater was heard longer ago but within the last 10 minutes, the message waits, showing only its wait icon, and goes again when a repeater is next heard, up to three times. If no repeater is heard for 10 minutes while it waits, it shows Failed, so your later messages to the same person can go. With no repeater heard in the last 10 minutes it doesn't wait at all: it uses its remaining tries and shows Failed if no receipt comes. A receipt that arrives up to 5 minutes after Failed still marks it delivered. This works the same with Pathfinder on or off.

## Delivery receipts

When your DM arrives, the other radio sends back a short receipt, the **ACK**, and MeshTrax marks your message delivered. The way home for that receipt is chosen by the *receiving* radio, not by you. If your message came in on a route, the radio answers along the route it has stored for you, or floods the receipt if it has none. It does this a fifth of a second after the message arrives, before any app on that side has seen it. A message that arrived by flood is answered by flood, whatever is stored.

So a stale stored route loses receipts: your message got there, but you never learn that, and you resend for nothing. Nothing you do on your side can steer the receipt. What Pathfinder can do is make sure *your* radio answers well, for the people who write to you.

**Keeping your radio's stored routes good.** For every contact you've chatted with in the last week, and every favourite, Pathfinder keeps the route stored on your radio set to its best proven route to that contact. It does this quietly in the background, so when their message reaches you, your receipt leaves on a route Pathfinder trusts. When Pathfinder knows no route to someone, it clears the stored one, so your receipt floods rather than follow a route nobody has proven. A route the mesh itself has just handed your radio, in a path reply after a flooded message, leads for 10 minutes before Pathfinder's own choice takes over.

**Stepping down.** If the same message reaches you a second time, the sender didn't get your receipt. Pathfinder takes the hint and moves your stored route one step down its list for that contact, and after a few repeats clears it, so the last receipts flood. A repeat is never held against the route, though: the sender's timer may simply have been short.

**Staying out of the way.** A contact's stored route is rewritten at most once every 10 minutes, except that a route Pathfinder has stopped listing is replaced at once. A contact is left alone while a message of yours to them is still being tried, and for 6 minutes after one of yours failed every attempt. A guessed route is stored only as the first choice, with one guessed hop at most. And if you picked a route for a contact yourself in the routing dialog, Pathfinder never touches it.

One thing this doesn't change: Pathfinder never uses the stored route for its own sends; those always go on its list and then flood.

**When a flood teaches the wrong way back.** A radio answers the first copy of a flooded message it hears, and that answer tells the sender which way to reach it. If your radio happens to hear a far repeater directly, that copy always arrives first, and the sender is taught a way back that ends at that repeater, heard well or not. MeshTrax does not correct this yet. Version 1.12.0 sent the sender the route of a later copy of the same message as a correction, but that route could be a long detour (up to 14 repeaters in the field), so the correction was taken out again until it can send the best way back Pathfinder knows.

**Two receipts for every message.** A direct message that reaches you on a route is always answered with two receipts (ACKs), so the sender has two chances to hear one. There is no setting for it. Your radio sends the first on its stored route. With Pathfinder on, MeshTrax sends the second on another route, and your radio is set to send only its one. With Pathfinder off, your radio sends both on the same route. If the Bluetooth link to your radio drops, the radio sends one receipt on its own until MeshTrax is connected again.

## What you see

- An **amber path icon** on a message means it went out on a Pathfinder route.
- Sometimes Pathfinder fills a gap with a guess: a link it has only heard used in the other direction. The message line then says how many hops were guessed. If the message is delivered, the guess is proven. If it fails, it costs one attempt and Pathfinder doesn't keep the guess.
- Pathfinder has its own screen. Pick a contact there to see how Pathfinder would reach them and how likely delivery is; send a Discover or a trace yourself; mark a repeater that moves (one in a car, say); and save what Pathfinder has learned to a file, restore it, or clear it. Once Pathfinder is on, the Chats screen menu opens it too.

## Give it time

A new map knows nothing, so at first your messages flood until Pathfinder learns a route. After some hours of listening in one place it starts to offer routes. Expect little on the first day, and again whenever you move somewhere new.

## More than one mesh

If you take your radio to another area, the repeaters there are different. Once your map is well established and most of the repeaters you hear after connecting are new to it, MeshTrax asks whether to start a new map (a **graph**) for this area and give it a name. Your old map stays, and you can switch back on the Pathfinder screen.

## Turning it on and off

**Settings → App Settings → Pathfinder** opens the Pathfinder screen; the switch is at the top. Turn it off and your radio routes exactly as it did before.

## Privacy

Pathfinder's map stays on your phone. With a radio that has GPS turned on, it also remembers which repeaters heard you in each area of about 500 m, never your exact spot. That information goes into a backup only when you choose to include it. See the [privacy policy](privacy.md).

## For developers

The design, the decisions behind it and the rules for what counts as proof are in [technical/path-graph-design.md](technical/path-graph-design.md). The receipt steering is [radio_route_keeper.dart](../lib/services/path_graph/radio_route_keeper.dart); its opening comment is the spec.
