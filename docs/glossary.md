# Glossary

Words you will meet in MeshTrax and in these docs, in plain language.

## The radio network

**LoRa**: A long-range, low-power radio technology. LoRa radios can reach several kilometres, or much further from a hilltop, but they send data very slowly, so messages are short.

**MeshCore**: The free software (firmware) that runs on LoRa radios and turns them into a messaging network. MeshTrax is an app for MeshCore radios.

**Firmware**: The software inside the radio itself. MeshTrax talks to the firmware; it doesn't replace it.

**Mesh**: A network with no central server. Every message travels from radio to radio until it reaches the person it's for.

**Companion radio**: Your own radio, the one MeshTrax connects to. The app sends and receives everything through it.

**Repeater**: A radio, usually on a roof or hill, that passes messages on. Repeaters are what let a message travel further than one radio can reach.

**Room server**: A radio that stores posts for a group, like a small bulletin board. Members log in to read and post, and it keeps recent posts for people who were away.

**Node**: Any radio on the mesh: a companion radio, a repeater or a room server.

**Hop**: One step from one radio to the next.

## Messages

**DM (direct message)**: A private message to one contact. Only that contact can read it.

**Channel**: A group chat. Everyone who has the channel's key can read it. The **Public** channel is shared by everyone on the mesh.

**Channel key (PSK)**: The secret that locks a channel. PSK stands for "pre-shared key": you get it from someone already in the channel, often by scanning a QR code.

**Advert**: A short announcement a radio sends now and then saying "I'm here", with its name and, if you allow it, its position. It's how contacts and repeaters appear in your list.

**ACK (acknowledgement)**: A delivery receipt. When a DM arrives, the other radio sends an ACK back, and MeshTrax marks the message as delivered.

**Public key and private key**: Each radio has a matching pair of keys. The public key is its identity, which anyone may know. The private key stays inside your radio and proves that messages really come from you. Anyone who has a radio's private key can pretend to be that radio.

## Routes

**Flood**: Sending a message so that every repeater that hears it passes it on. Flooding finds the other person wherever they are, but it keeps the whole area's repeaters busy.

**Route (or path)**: A list of the repeaters a message should pass through, in order. A message sent on a route keeps only those repeaters busy, so it's quieter and often more reliable than a flood.

**Repeater code (path hash)**: A route doesn't hold full repeater names. It holds a short code for each one: usually the first 1 or 2 bytes of the repeater's public key, written as letters and numbers such as `A3` or `A377`. Short codes keep messages small, but two repeaters can share one, especially 1-byte codes.

**Discover**: A short "who can hear me?" call. Nearby repeaters answer, so the app learns which repeaters can hear you right where you are.

**Trace**: A test message that follows a route and reports how strong the signal was at each hop.

**Signal strength (RSSI, SNR)**: Two numbers that say how well a radio heard a message. RSSI is how loud the signal was; SNR (signal-to-noise ratio) is how clear it was above the background noise. Higher is better for both.

**Pathfinder**: The MeshTrax feature that learns the mesh by listening and picks routes for your DMs. See [Pathfinder](pathfinder.md).

**Graph**: Pathfinder's map of one mesh. If you use your radio in more than one area, you can keep a graph for each.

## Connecting the app

**BLE (Bluetooth Low Energy)**: The low-power Bluetooth that phones use to talk to the radio.

**USB**: A cable connection to the radio, mostly from a computer.

**TCP (Wi-Fi)**: A connection to a radio over your Wi-Fi network, for radios that support it.

## Maps

**Map pack**: A downloaded map file covering one region, so the map works with no internet. See [Offline maps](offline-maps.md).

**Map tile**: A small square piece of an online map. Online maps load tiles as you scroll; MeshTrax keeps recently viewed tiles for a while so they load faster.

## In the technical docs

**Frame**: One message between the app and its companion radio, such as one command or one reply.

**Packet**: One message travelling over the air between radios.

**Byte**: The basic unit of data. LoRa packets are small: a message has room for roughly 150 characters of text.

**Hex**: A way of writing bytes using the digits 0–9 and letters A–F, two characters per byte. `A3` is one byte; `A377` is two.
