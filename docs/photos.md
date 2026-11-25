# Photos

Send a photo to a channel over the mesh, with no phone network or internet. Unfamiliar words are explained in the [glossary](glossary.md).

## How it works

A photo is far too big for a LoRa radio. MeshTrax shrinks it on your phone with an AI model, to a code of about 400 bytes: 2 to 6 radio packets, and one more with the repair packet.

The phones that receive it rebuild a picture from that code with the same model. The picture keeps the scene: its layout and colours, vehicles, people. Its fine detail is made up by the model, though, so signs and text don't come through. Every rebuilt picture says "AI reconstructed", small in a corner, and has the MeshTrax footprint, faint, in the other. It isn't a record of what was there, so put what matters in a tag or a message.

## Before you start

- Android (64-bit), an iPhone or a Mac. Your radio needs companion firmware 1.15 or later.
- The photo model, about 1.2 GB: turn on **Photos** in App settings, Messaging, and download it there. Keep MeshTrax open until it finishes; progress also shows in Offline maps, and it follows **Download on Wi‑Fi only**.
- Rebuilding a photo needs about 1.4 GB of free memory. If there isn't enough, MeshTrax frees the map's memory and checks again, and tells you if there still isn't room. On a phone with 4 GB of memory, a photo may only rebuild before you open the map, or after restarting MeshTrax.

## Sending a photo

1. In a channel's chat, tap **+**, then **Photo**.
2. Take a photo or choose one, then move and zoom until what matters fills the square. Close up, it comes through much clearer: something small in a wide shot can come back as shapes the AI made up. **Blur faces** is on: your phone blurs any faces it finds before the photo is coded, because the AI can't rebuild faces and would make them up. If the blurred photo doesn't pass the safety check, the faces are covered in grey instead.
3. Tap **Preview**. The photo is checked and coded, then rebuilt exactly as the others will see it. Tap the picture to see it full screen: zoom in, or tap **Enhance 4×** as the others can.
4. Type a tag if it helps, up to 24 characters, such as "Spring flowing". It travels as text, exactly as you type it, so the rebuild can't change it.
5. To show where you are, turn on **Include location** and pick how exact: about 10 km, 600 m, 40 m or 2 m. It's your radio's location now, from its GPS or the one you set. The finer it is, the more of a packet it takes, and it's off again for the next photo.
6. Tap **Send**. MeshTrax pauses after each packet, so an SOS or a message sent meanwhile goes first.

A photo goes the way the channel's messages go: through the repeaters, within the channel's region if it has one. **Zero hop** sends it only to the radios in direct range; repeaters don't pass it on. On a Nearby only channel every photo goes zero hop. **Repair packet** sends one more packet, so the photo still arrives if any one packet is lost. It's off until you turn it on, and stays the way you left it for your next photo. A photo the safety check flags can't be sent.

Through repeaters, your radio listens for each packet being passed on:
- A packet no repeater was heard passing on goes once more ("Packet 2 of 4 again"), while the others can still put the photo together. It doesn't when **Max Channel Message Retries** is 0, or when no repeater has been heard for 10 minutes. After a packet sent again, no more go until a repeater is heard passing some packet of the photo on. A repeater you marked in Pathfinder as moving with you doesn't count.
- Your photo then shows the checks a message does: one grey check while your radio listens, two green checks once repeaters passed on every packet the others need, and the amber check when some weren't heard. Hold the amber check to see how many were.
- Zero hop, no repeater passes it on, so it keeps its one check.

## On MeshCore frequencies

On the frequencies of MeshCore's standard presets, photos share the air with everyone, so MeshTrax holds them back:
- Before each photo it asks you to confirm, with how much airtime the photo takes, measured in text messages (a photo is usually as much as 8), and whether repeaters pass it on.
- On Public and hashtag channels it first explains that most people there won't see the photo, since only MeshTrax shows photos, and what's better: zero hop, a private channel, a tighter crop, one photo rather than a series. **Don't show this again** skips that explanation, not the question.
- One photo every 10 minutes from each radio, and one through repeaters every 30 minutes: zero hop is the way to send another sooner.
- At least four packets' airtime between packets, so a photo takes no more than about a quarter of the air around you. Through repeaters, MeshTrax waits longer, until each packet has cleared the repeaters near you.

The Off-Grid presets, TRAX included, and custom frequencies have none of these limits.

## Receiving a photo

- A photo shows in the chat under the sender's name, with its tag and location, if any, under it. **Map** and **Navigate** work as on a shared location. Tap it to see it full screen: it's rebuilt there first, in about 20 seconds on an older phone and a few seconds on a recent one. Pinch or double-tap to zoom.
- **Enhance 4×**, at the bottom, enlarges it to 2048 × 2048. An AI model on your phone sharpens it, so fine detail may be made up. It takes about 4 seconds on an older phone, 1 on a recent one, and needs about 1 GB of free memory. MeshTrax keeps only the rebuilt photo, not the enhanced one.
- **Save**, at the top, saves what's on screen to your photos (on a Mac, where you choose), with "AI reconstructed" and the footprint in its corners. The ⋮ menu has **About this photo** and, for a photo you received, **Report** and **Block**.
- To skip the taps, turn on **Rebuild received photos automatically** in App settings, Messaging, Photos: each photo then rebuilds as it arrives, while MeshTrax is open and the phone has the memory. On phones with 8 GB of memory or more, **Enlarge photos automatically** enlarges a photo as it opens full screen.
- A photo that didn't arrive whole says so, for example "📷 Photo #3a incomplete: 3 of 5 packets". It isn't sent again.

## Safety

- Every photo is checked by an image safety classifier on your phone before it's sent, and every rebuilt or enlarged picture before it's shown. A flagged picture shows only "Image hidden".
- **Report** hides a photo for good and sends a report to the MeshTrax developer from inside the app, now or when you next have internet. Add what's wrong if you like. The photo goes with it only if you tick **Include the photo**, and then only as its code. **Block** drops that sender's photos.
- Nothing about your photos goes to a server. The [privacy policy](privacy.md) says what is kept on your phone.

## Licences

The model that rebuilds photos is built on Stability AI's SD-Turbo, with the AEIC image codec and AdcSR's decoder, and the safety check uses an image classifier built on SwiftFormer. Powered by Stability AI. App settings, Photos, **Licences** shows the notice and licences that come with them.
