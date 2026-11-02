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
2. If that fails, it tries its next best one.
3. It floods only as a last resort.

Every delivery and every failure teaches it more. A failure counts against that link for a while, then fades: a day later it counts half as much, and after a few days hardly at all. So one bad moment doesn't block a good link for good.

When it isn't sure which repeaters can hear you where you are, Pathfinder sends one short **Discover** call. It does this only after a send has failed, and at most once every 10 minutes.

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

The design, the decisions behind it and the rules for what counts as proof are in [technical/path-graph-design.md](technical/path-graph-design.md).
