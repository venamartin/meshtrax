# What's new in MeshTrax

Newest first. Unfamiliar words are explained in the [glossary](glossary.md).

## 1.11.0

- Line of sight and radio reach, offline: see whether two points can hear each other, or how far your radio reaches and who is in range, from the downloaded contours. It works below sea level too, from Death Valley to the Salton Sea.
- Navigate a route inside MeshTrax, or hand it to another app from the route sheet.
- Check sends with observers (optional, off by default): MeshTrax asks an observer server you pick whether your channel messages were heard, and doesn't send them again for nothing.
- Contacts get a nickname, a full name and a note. Share a contact from the + tray; a contact posted in a chat shows as a card. A deleted contact stays deleted, and adverts with a bad signature are ignored.
- A direct message is never stuck: with no repeater near, it fails within minutes so your next messages go, and "No repeater heard you" shows while it waits for one.
- A message your radio held for hours says when it was sent ("sent 2:00 PM by its clock").
- With the radio's GPS on, your dot turns grey ("Last known · 2:02 PM") once the GPS stops giving new positions.
- The Chats tab counts unread messages. A chat you are reading further up stays put when messages arrive. Day headings and the NEW MESSAGES line are drawn as a wave.
- The @ list offers the people in the chat first, with their nicknames, and typing @ no longer closes the keyboard. Replies and reactions to posts from days ago land on them.
- The map: search is a map button, full screen fades the buttons, a layers sheet, and the map keeps its view and opens on your GPS position. Search lists the nearest places of a kind and which way each one is.
- Install maps from a drive. Offline maps opens on Maps; Manage repeaters gets a Heard window and sorts by hops.
- Settings show the radio's firmware, and About shows the build number. Short map links no longer go online to find their position.
- On Linux the app no longer crashes on close; on the Mac it has its own icon.

## 1.10.2

- QR scanning works again on Android, with the camera and from a photo.
- The route panel on the map is a sheet: pull it down to a bar, up for the height profile and options, or all the way for the directions. Wide screens get a side panel.
- A chat opens showing its messages, and on your oldest unread message even when it is far back.
- Logging in to a repeater or room no longer waits a minute per try: each try waits one round trip over the distance to it.
- A GIF, your position or any other card can follow a mention: the "+" stays while the box holds only the mention.
- Manage repeaters keeps the filter or sort you chose and shows it as a chip under the search field; the chip's cross clears it.
- On Linux, Windows and Mac, the app reconnects to your USB radio at startup and after it is unplugged or restarts. Linux shows the radio's name in the port list.
- On iPhone, Back up this radio, Restore this radio, Export database and the Pathfinder backup and restore open the file dialogs again.
- Google Play no longer requires USB host support, so the app reaches phones and tablets without it.
- On Linux the app runs on XWayland where there is one. Flutter 3.50's Wayland support can freeze the window on a resize; `GDK_BACKEND=wayland` still forces Wayland.

## 1.10.1

- Channels opened from Chats show the NEW MESSAGES line again and start at your first unread message. The Chats list previews the newest unread message, and repeats of your own messages no longer count as unread.
- Places search finds parks such as Yosemite, Redwood and Mojave by name.

## 1.10.0

- Trail routing on Android and iOS: plan routes offline on paved roads, dirt roads and trails, with time, climb and a height profile. North America to start.
- Points of interest: search places, addresses and coordinates offline, with Wikipedia text and photos. California to start.
- Parks on the map, route shields and a roads legend.
- Positions in seven formats, including UTM, MGRS and Maidenhead.
- Every screen in all 17 languages.

## 1.9.8

- Map downloads work again on Windows: a region failed with "Download failed" and a page of text instead of installing.
- If a region still shows as failed, cancel it and download it again.
- A failed download now shows a short error code instead of a web page.

## 1.9.5

- Drawings in messages: sketch, or use shapes, routes and X marks, even over a map.
- A built-in base map down to towns. Online tiles are gone: download a region for detail.
- Health check in Settings fixes settings that could work better.
- Missed messages stay unread with a divider; tap a reply's quote to open the original.
- Sends no longer stick on the clock; a failed send no longer shuts out a route for good.
- Paste or scan contact cards, Select text on phones, and dates that follow your system.

## 1.8.1

- Fixes a problem where messages could disappear after updating to 1.8.0 if the app was closed during its first start. Your messages were never deleted: this update brings them back automatically.

## 1.8.0

- Offline maps: download areas, with hill shading, trails and charts.
- Pathfinder: smarter DM routing that learns your mesh.
- New message types: Location, SOS, Event and Notice, plus markdown and link cards.
- Rooms: announcements, sharing and a better post order.
- See and control who can see your location.
- MeshCore firmware 1.18 support, all strings translated into 17 languages, and smoother scrolling.

## 1.7.50

- Room chat overhaul: replies, mentions, roles, announcements and admin tools.
- Rooms learn their route again by logging in; room passwords remembered.
- Reply quotes show the full original post and jump to it.
- Backup and restore: works with older firmware, choose radio-only or full restore.
- Routes keep their repeater-code size (1 or 2 bytes); new "Forget all routes" action.
- Repeater routing dialog fixes and realistic command timeouts.
- Wi-Fi (TCP) connection stays alive in the background and reconnects when you return to the app.

## 1.7.40

- Full radio backup and restore.
- Bluetooth: connection status shown in chats, more reliable auto-reconnect.
- Warns when your phone may put MeshTrax to sleep in the background.
- Faster contact sync on reconnect (optional).
- Send GIFs as Giphy links (optional).
- Smarter route display when two repeaters share the same short code.
- Transmit power can be set as low as -9 dBm (dBm measures radio power: lower saves battery but reaches less far).
