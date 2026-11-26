# MeshTrax Privacy Policy

**Last updated:** November 23, 2026
**Applies to:** MeshTrax for Android (package `com.vena.meshtrax`), version 1.5.7 and later, MeshTrax for iOS (bundle `com.vena.meshtrax`), version 1.7.20 and later, MeshTrax for macOS (Mac App Store, bundle `com.vena.meshtrax`), version 1.10.0 and later, and MeshTrax for Windows (Microsoft Store and GitHub download)

## Introduction

MeshTrax ("the App", "we", "us") is a free, open-source client application for communicating with [MeshCore](https://meshcore.co.uk/) LoRa mesh-networking devices ("companion devices"). This Privacy Policy explains what data the App accesses, stores, and shares, and why. It is written to comply with the [Google Play Developer Program Policies](https://support.google.com/googleplay/android-developer/answer/10144311) and the Google Play Data safety requirements, Apple's [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#privacy) and App Privacy disclosure requirements, and the [Microsoft Store Policies](https://learn.microsoft.com/windows/apps/publish/store-policies). The App behaves the same way on all platforms; where a detail is platform-specific it is called out below.

The App is developed by an independent, open-source developer. You can review the complete source code to verify every statement in this policy at **https://github.com/venamartin/meshtrax**.

## Summary

- The App has **no user accounts** and requires **no sign-up**.
- There is **no MeshTrax account system or cloud backend for your data**. The developer runs two servers, both on Cloudflare: a download server for offline maps (`maps.meshtrax.io`, on Cloudflare R2), which serves map files, trail routing data, points of interest (place names, Wikipedia text and photos), addresses and the photo model, and receives none of your data; and a report inbox (`reports.meshtrax.io`), which passes a photo report you choose to send on to the developer by email. We receive **none** of your data automatically. The only exception is content you explicitly choose to **report** (see "Content reporting").
- The App does **not** use analytics, advertising, crash reporting, or usage tracking of any kind. (On Android, the QR code scanner's Google library may send Google its own usage statistics; see "Camera and photos".)
- Your messages, contacts, channels, and settings are stored **only on your device** and are exchanged only with your own MeshCore companion device and, through it, the LoRa mesh network.
- Apart from the Android QR scanner's statistics noted above, the only data the App sends over the internet goes to the MeshTrax map server, to **Giphy**, which powers the optional GIF features, and, only if you turn on **Check sends with observers**, to the **observer server** you choose. What each receives is described below. The base map that comes with the App, line of sight, radio reach, trail routing and place search need no connection.

## Data the App collects and stores on your device

All of the following is stored locally in the App's private storage on your device: a local database and the operating system's preferences store (`SharedPreferences` on Android, `UserDefaults` on iOS and macOS), or the app's own local application-data folder on Windows. None of it is transmitted to the developer or to any server automatically; the only exception is content you explicitly choose to report (see "Content reporting" below).

| Category | What it includes | Purpose |
|---|---|---|
| Messages | Direct and channel/group messages you send and receive over the mesh | Show your conversation history |
| Your SOS while it lasts | Its text, the chat it went to, the last position sent and who answered | Keep sending it after the App restarts; deleted when you cancel it |
| Contacts | Contact names, public keys, and any node coordinates advertised over the mesh | Address and display messages, show nodes on the map |
| Channels & communities | Channel names and their pre-shared keys (PSKs); community secret keys | Encrypt/decrypt mesh traffic on those channels |
| Node identity | Your device's **public** key and display name | Identify your own messages |
| App settings | Theme, language, notification preferences, map preferences, unit system, auto-connect preference, last connected device identifier, blocked-users list, etc. | Remember your preferences |
| Message routing data | Path history and routing weights, kept in one graph per mesh, with the names you give the graphs and the public keys of the repeaters each graph has heard | Improve mesh message delivery, and tell one mesh from another |
| Where repeaters heard you (GPS radio only) | With a radio that has its GPS on, which repeaters heard it in each area of about 500 m over the last 30 days, with no finer position than that; carried in a Pathfinder backup only when you choose "Include" | Pick routes that work where you are |
| Offline maps | Map packs, trail routing data, points of interest and addresses you choose to download or install from a drive, and the list of what's available | Show maps, plan routes and search for places without a connection |
| Debug logs (optional) | BLE and app diagnostic logs, **only if you enable them** in Settings | Troubleshooting; can be disabled and cleared |
| Message drafts | Text you typed but have not sent yet | Keep your place in a conversation |
| Observer sightings (optional) | Only while **Check sends with observers** is on: the observer server you chose, and which observers heard your recent channel messages and photos (name, signal, how many repeaters), for the last 300 | Show the ear on a message and list the observers in its packet path |
| Photos | For each photo sent or received in a chat: its code (the few hundred bytes that crossed the radio), its tag, its location if the sender included one, for a Subject only photo where its subject is in the picture, and, once it has been rebuilt and passed the safety check, the rebuilt picture. A picture the safety check flags is never kept. Rebuilt pictures are kept in a cache of at most 100 MB, oldest dropped first | Show photos in the chat without rebuilding them each time |
| Photo reports | A photo you reported, until the report inbox has the report: who sent it, when, its size, whether the safety check hid it, what you wrote, and its code only if you chose to include it | Send the report when you have internet |
| The photo model | About 1.2 GB, downloaded only when you choose, with its licence texts | Code and rebuild photos on your device |
| Photo send times | When this radio last sent a photo of two or more packets through repeaters on a MeshCore frequency | Space photos through repeaters by their size: 5 minutes for 2 packets, 10 for 3, 20 for 4 or more |
| TRAX mode | Your companion device's radio settings from before TRAX mode (frequency, bandwidth, spreading factor, coding rate, transmit power, Off-Grid Repeat), when it switched and the trip's end; your TRAX settings (preset, trip channel, trip end, Tell the group) | Put the radio back on its regular mesh when you leave TRAX mode, and remind you after the trip |

**Sensitive data notice:** Channel pre-shared keys and community secret keys are cryptographic secrets. They are stored on your device so the App can decrypt mesh messages. Your **private** identity key is held by your MeshCore companion device/firmware, **not** by the App; it leaves the device only inside a backup file you ask for (see "Files you export").

**Files you export:** The App can write a backup file, a debug log, or a copy of the message database, but only when you ask for one. You choose where each file goes through the system share sheet or file picker. A full device backup holds your contacts, channels and their keys, the companion device's settings and position, and, where the firmware allows it, the companion device's **private** identity key, so you can restore the same identity onto a radio later. Keep backup files somewhere safe; anyone holding one can read your channels and act as your node.

**Maps from a drive:** When you choose **Use a drive** in Offline maps, the App reads the folder you pick (on a USB drive, an SD card or your device) and copies the map files you choose into its own storage. It reads nothing else there, and sends nothing anywhere.

**Device backups:** The App itself does not back up or sync your data anywhere. Your device's own backup (Android backup to your Google account, an iCloud or computer backup on iOS, or Time Machine on macOS) can include the App's data, under your account and your backup settings. Downloaded offline maps, trail routing data, points of interest, addresses, the photo model and rebuilt pictures are kept out of these backups; a photo's code is in them, like your messages.

## Data shared with third parties

The App contacts the MeshTrax map server, one third-party service, Giphy, and, only if you turn it on, an observer server you choose, and only when you use the associated feature. In each case, because the request is made directly from your device, that service can see your device's **IP address**. We receive nothing from these interactions.

### 1. MeshTrax map server (offline maps)
- **When:** You open the Offline maps screen, download or update a map, trail routing data, points of interest or addresses, download the photo model, and, while offline maps are installed, about once a day to check for updates.
- **What is sent:** Requests for the list of what's available and for the files you choose, with standard HTTP headers. No personal data and no location; the region you pick shows only as which files are requested.
- **Hosting:** The files are served by Cloudflare R2 at `maps.meshtrax.io`. Cloudflare sees your IP address and may keep standard request logs; the developer does not use them to identify you.
- **Their policy:** https://www.cloudflare.com/privacypolicy/

### 2. Giphy (optional GIFs)
- **When:** You open the GIF picker to send a GIF, or a GIF shared in a chat is displayed. GIF display can be turned off in Settings ("Inline GIFs").
- **What is sent:** When you open the picker, a request for trending GIFs. When you search in the picker, the **search words you type**. When a GIF is displayed, only the GIF **identifier** contained in the message, used to fetch that image from Giphy's media servers. No message text, contacts, or location is sent.
- **Their policy:** https://support.giphy.com/hc/en-us/articles/360032872931-GIPHY-Privacy-Policy

### 3. Observer server (optional, off by default)
Observers are radios that report what they hear on the mesh to a server. **Check sends with observers** (App settings, Messaging) asks such a server whether your channel messages and photos were heard, so the App doesn't send one again for nothing.
- **When:** Only while the setting is on, about 10, 25 and 60 seconds after you send a channel message or a photo, until an observer has heard it. Saving a server also asks it one test question.
- **What is sent:** The **fingerprint** (packet hash) of each channel message you send, and of each packet of a photo you send: 16 characters worked out from the encrypted packet. Never the message text, the channel, your name, contacts or location. Because the request comes from your device, the server sees your **IP address** and the time you sent; it can also see that the fingerprint matches a packet its observers heard, and so tell which packets came from your device.
- **Who runs it:** Not the developer. You pick the server: one from the App's list, whose question-answering service is open to anyone, or another address you type. Its operator's own policy applies.

### Earlier versions
MeshTrax 1.10.2 and earlier also contacted two other services:
- **Open-Meteo**, for line of sight: the latitude/longitude of the points being checked (not your phone's GPS position) were sent so that terrain heights could be returned. Their policy: https://open-meteo.com/en/terms
- **Google**, for Google Maps short links (`maps.app.goo.gl`) in messages: the App asked Google where the link pointed, to show its position.

Newer versions do neither: line of sight works from the contours you downloaded, and a short link shows no position.

The App also uses the operating system's share sheet (for exporting GPX track files that you explicitly choose to share), the system browser (to open a web link contained in a received message, after you confirm, or a place's full Wikipedia article when you tap **Read on Wikipedia**), your maps app (when you tap **Directions** on a shared location, the App opens Apple Maps or Google Maps with that destination), and your calendar (when you tap **Add to calendar** on an event message, the event's details are passed to the calendar app, where you choose to save it). In each case it happens only when you tap, and you choose what to do with it; the App does not upload anything on its own.

## Content reporting

The App provides tools to moderate user-generated content. If you tap **Report** on a message, the App opens **your own email app** with a pre-filled message — containing the reported message's text, the sender's display name, and the timestamp — addressed to the developer (**venahamtrack@gmail.com**). **Nothing is sent unless you choose to send that email.** This is the only circumstance in which the developer may receive your content, and it happens entirely at your initiative. When you send a report, the developer will also see the email address you send it from.

If you tap **Report** on a photo, the photo is hidden on your device straight away, for good, and the App sends a report from inside the App, over the internet, to MeshTrax's report inbox (`reports.meshtrax.io`, on Cloudflare), which passes it on to the developer by email at the same address. The report holds who sent the photo (their name as shown), when it arrived, its size, whether the safety check hid it, anything you write, the App's version and platform and, only if you tick **Include the photo**, its code (a few hundred bytes from which it can be rebuilt; not the picture). **Nothing about you is sent**: not your name, your radio's key or an email address. The inbox stores neither the report nor your internet address; it only passes the report on. Without internet, the report waits on your device and is sent when you're online, or from App settings, Messaging, Photos.

You can also **block** a sender from any message; blocked senders and their messages are then hidden from you. A blocked sender's photos are not kept at all. The list of blocked users is stored only on your device (see the table above) and is never transmitted.

## Data the App does NOT collect or do

- No personal accounts, names, emails, or phone numbers are collected by the App.
- No analytics, advertising identifiers, crash reporting, or behavioral tracking.
- No Google Sign-In, Google Drive, or other cloud-sync services (unused Google API libraries may appear as transitive build dependencies but are not invoked by the App). Your operating system's own device backup is separate; see "Device backups" above.
- The App does not read your calendar or your contacts list.
- The App does **not** read your phone's GPS/location sensor. It contains no location-provider code. **My location** on the map shows your companion device's own position, as the device reports it. When you share My location in a chat, you can choose to send that device's heading, speed and altitude with it. The App works the heading and speed out from the device's last few positions, which it keeps in memory only.
- Trail routing, place search, line of sight and radio reach run entirely on your device. The points you plan a route between, the words you search for and the places you check line of sight between are never sent anywhere. Line of sight reads the heights from the contours you downloaded.
- No data is sold or shared for advertising.

## Permissions

The App requests only the permissions needed for its stated functions.

### iOS

| Permission | Why it is needed |
|---|---|
| Bluetooth | Discover and connect to MeshCore companion devices over Bluetooth Low Energy (BLE) |
| Camera | Scan QR codes to import contacts and configuration, and take a photo you choose to send. Photos are never saved or uploaded (see "Camera and photos") |
| Photo Library | Pick an existing image to scan a QR code from it, or a photo to send, and add a photo to your library when you tap **Save** (the App asks only to add, not to read). Images are analyzed on your device and never uploaded |
| Notifications | Show notifications for incoming mesh messages |
| Calendar | Add an event from an event message to your calendar, only when you tap **Add to calendar**. On iOS 17 and later no permission is asked; on earlier versions iOS asks once. The App never reads your calendar |
| Contacts | Not used by the App. Declared because Apple's own add-event screen can suggest locations from your contacts on iOS 16 and earlier |
| Background mode: `bluetooth-central` | Keep the connection to your companion device alive while the App runs in the background |

iOS does not require location permission for BLE scanning; the App never requests it.

### macOS

| Permission | Why it is needed |
|---|---|
| App Sandbox | Required for Mac App Store apps. The App's data stays in its own container, and the App can reach only what is listed below |
| Bluetooth | Discover and connect to MeshCore companion devices over Bluetooth Low Energy (BLE) |
| Outgoing network connections | Download offline maps, points of interest and addresses (MeshTrax map server) and GIFs (Giphy) for the optional map and GIF features, ask the observer server you chose whether your channel messages were heard (only if you turn that on), and connect to a companion device over your local network (TCP) |
| USB and serial ports | Connect to a companion device over a USB serial cable, through the serial port of the radio you plug in |
| Files you choose | Read or write a file only when you pick it in an Open or Save dialog: a backup to save or restore, settings or path graphs to export or import, a debug log to save, an image to scan a QR code from, a photo to send, or a folder of offline maps on a drive to install from. The App reaches no other files outside its container |
| Camera | Scan QR codes to import contacts and configuration. No photos are captured, saved, or uploaded |
| Notifications | Show notifications for incoming mesh messages |

The macOS app does not use location and does not ask for access to your calendar, contacts, or photo library. An image to scan a QR code from is one you choose in a file dialog, and **Add to calendar** hands the event to the Calendar app as a file, where you choose to save it.

### Android

| Permission | Why it is needed |
|---|---|
| `BLUETOOTH`, `BLUETOOTH_ADMIN` (Android 11 and below) | Discover and connect to MeshCore companion devices over Bluetooth Low Energy (BLE) |
| `BLUETOOTH_SCAN` (with `neverForLocation`), `BLUETOOTH_CONNECT`, `BLUETOOTH_ADVERTISE` (Android 12+) | Scan for and communicate with your companion device. The scan is flagged so it is **not** used to derive location |
| `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION` | Required by the Android operating system to permit BLE scanning on Android 11 and below. The App does not read, store, or transmit your device location through these permissions |
| `INTERNET` | Download offline maps, trail routing data, points of interest and addresses (MeshTrax map server) and GIFs (Giphy) for the optional map and GIF features, and ask the observer server you chose whether your channel messages were heard (only if you turn that on) |
| `CAMERA` | Scan QR codes to import contacts and configuration, and take a photo you choose to send. Photos are never saved or uploaded (see "Camera and photos") |
| `POST_NOTIFICATIONS` (Android 13+) | Show notifications for incoming mesh messages |
| `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_CONNECTED_DEVICE`, `WAKE_LOCK` | Keep the connection to your companion device alive while the App runs in the background |
| `CHANGE_NETWORK_STATE` | Required by Android 14+ to keep that background connection running when your companion device is reached over the local network (TCP) only. The App does not change your network settings |
| USB host feature (optional) | Connect to a companion device over a USB serial cable, where supported |

### Windows

| Capability | Why it is needed |
|---|---|
| Bluetooth | Discover and connect to MeshCore companion devices over Bluetooth Low Energy (BLE) |
| Internet | Download offline maps, points of interest and addresses (MeshTrax map server) and GIFs (Giphy) for the optional map and GIF features, and ask the observer server you chose whether your channel messages were heard (only if you turn that on) |
| Full trust (desktop app) | Standard for Windows desktop apps; lets the App open USB serial (COM) ports to reach a companion device over a cable |

The Windows app does not use the camera, location, or notifications.

The App can also connect to a companion device over your **local network (TCP)** using an IP address that you enter manually. This traffic stays on your local network.

## Camera and photos

The camera is used to scan QR codes (for importing contacts and configuration) and, on phones, to take a photo you choose to send. You may alternatively pick an existing image from your gallery (on macOS, an image file) to scan a QR code from it or to send it. Any such image is analyzed **on your device** and is never uploaded.

**Photos in chats** (Android, iPhone and Mac):
- When you send a photo, the App crops it to the square you choose, checks it with an image safety classifier, blurs any faces it finds (unless you turn **Blur faces** off) and codes it with the photo model, all on your device. Faces are found only to blur them: nothing about them is kept or sent. With **Subject only** or **Auto crop**, what you tap is outlined on your device, only to crop to it or to make everything else black; the outline isn't kept or sent. Only the code, a few hundred bytes, goes out, over the mesh to the channel you chose (see "Mesh network communications"), with the tag you type and, only if you turn on **Include location** for that photo, your radio's location to the accuracy you pick. The App doesn't keep the original photo.
- When a photo arrives, the App rebuilds a picture from its code with the same model, on your device, and checks it before showing it. A picture the check flags is never shown or kept.
- A rebuilt picture is made by AI and labelled "AI reconstructed": its fine detail is generated, not sent, so signs and text don't come through. **Enhance 4×** enlarges it on your device with another AI model; the enlarged picture is checked too, and isn't kept.
- **Save** puts a copy of what's on screen in your photo library (on a Mac, where you choose), with "AI reconstructed" in its corner.
- The photo model, the classifier and the face and outline finders run on your device. Nothing about your photos is sent to a server, except a report you choose to send (see "Content reporting"). On Android, QR codes are read with Google's ML Kit barcode scanner, which runs on your device; when your phone is online, ML Kit may send Google usage statistics about the scanner (not the images or the codes in them), under Google's terms: https://developers.google.com/ml-kit/terms

## Mesh network communications

Messages and contact information are exchanged with your MeshCore companion device over Bluetooth LE, USB serial, or local-network TCP, and are then relayed over the LoRa radio mesh to other devices. This radio communication is a function of the MeshCore hardware and network, not of any MeshTrax server. Message contents on encrypted channels are protected by the channel/community keys described above.

With **Tell the group** on, TRAX mode posts a short TRAX message on the trip channel you picked, before it switches and before it leaves, naming the trip's end (with your time zone's offset from UTC) and the radio settings. It goes over the mesh to that channel's members like any other message. In TRAX mode your radio also relays other radios' messages on the off-grid frequency.

A **photo** goes over the mesh to the channel's members like a message: its packets are encrypted with the channel key, and every radio in the channel that hears them can rebuild it. In the Public channel, anyone in range can. Sent zero hop, only radios in direct range hear it; sent through repeaters, so can radios in the channel along the route. With **Send my position too**, a location message follows the photo.

When you send a **Location** or **SOS** message, the position in it is either your companion device's position (from its GPS or the position set on it) or a point you pick on the map, never your phone's GPS, and it goes over the mesh to the people in that conversation, like any other message. It is never sent to a server.

An SOS sent in a channel other than Public is sent again every 2 minutes (every 5 once someone answers) with your companion device's latest position, until you cancel it. With **Also send to Public** ticked, which it is unless you untick it, its first message also goes to the Public channel, where anyone in range can read it, position included; the cancel goes there too. An SOS sent in the Public channel itself goes once, as does its cancel.

## Data security

Locally stored data is protected by your device's operating-system storage sandbox and, on modern devices, by the operating system's full-disk/file-based encryption. The App does not implement an additional at-rest encryption layer beyond what the operating system provides. Because channel and community keys are sensitive, we recommend keeping a device screen lock enabled.

## Data retention and deletion

- All App data is retained on your device until you delete it.
- You can delete data at any time by using the App's in-app controls (for example, clearing contacts, channels, or debug logs), by clearing the App's storage in Android Settings, or by uninstalling the App (any platform), which removes all locally stored data. On macOS, moving the App to the Trash leaves its data in `~/Library/Containers/com.vena.meshtrax`; delete that folder as well to remove it.
- Because we hold none of your data on any server, there is nothing for you to request that we delete on our side.

## Children's privacy

The App is not directed to children and does not knowingly collect personal information from children under 13 (or the equivalent minimum age in your jurisdiction).

## Open source

MeshTrax is open-source software released for public review. You can audit the source code, including every network request and storage operation described here, at https://github.com/venamartin/meshtrax.

## Changes to this policy

We may update this Privacy Policy as the App evolves. Material changes will be reflected by updating the "Last updated" date above and, where appropriate, noted in the project's release notes.

## Contact

If you have questions about this Privacy Policy or the App's privacy practices, you can contact the developer at **venahamtrack@gmail.com** or open an issue at **https://github.com/venamartin/meshtrax/issues**.
