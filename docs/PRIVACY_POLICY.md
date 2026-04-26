# Privacy Policy for MeshTrax

**Last Updated:** January 11, 2026

## Introduction

MeshTrax ("the App") is an open-source Flutter application for communicating with MeshCore LoRa mesh networking devices. This Privacy Policy explains how the App handles your information.

## Data Collection

### Data We Do NOT Collect

MeshTrax does **not**:
- Collect personal information
- Send data to external servers (except map tile requests)
- Track your usage or behavior
- Use analytics services
- Require account creation
- Share any data with third parties

### Data Stored Locally on Your Device

The App stores the following data **locally on your device only**:

- **Messages**: Chat messages sent and received through the mesh network
- **Contacts**: Names and identifiers of mesh network contacts
- **App Settings**: Your preferences (theme, language, notification settings)
- **Channel Settings**: Configuration for mesh network channels
- **Message History**: Path history for message routing
- **Debug Logs**: Optional BLE and app debug logs (if enabled by user)
- **Cached Map Tiles**: Offline map data for the mapping feature

All locally stored data remains on your device and is never transmitted to us or any third party.

## Permissions

The App requires certain device permissions to function:

### Bluetooth Permissions
- **BLUETOOTH, BLUETOOTH_ADMIN** (Android 11 and below)
- **BLUETOOTH_SCAN, BLUETOOTH_CONNECT, BLUETOOTH_ADVERTISE** (Android 12+)

These permissions are used solely to discover and communicate with MeshCore hardware devices via Bluetooth Low Energy (BLE).

### Location Permission
- **ACCESS_FINE_LOCATION, ACCESS_COARSE_LOCATION**

Required by Android for BLE scanning on Android 11 and below. The App does not track or store your location. Location data may be optionally shared over the mesh network if you choose to enable location sharing features.

### Internet Permission
- **INTERNET**

Used only for downloading map tiles from OpenStreetMap tile servers when using the map feature. No personal data is transmitted.

### Notification Permission
- **POST_NOTIFICATIONS** (Android 13+)

Used to display notifications for incoming messages when the app is in the background.

### Background Service Permissions
- **FOREGROUND_SERVICE, FOREGROUND_SERVICE_CONNECTED_DEVICE, WAKE_LOCK**

Used to maintain BLE connection with your MeshCore device while the app is in the background.

## Third-Party Services

### Map Tiles
The App uses OpenStreetMap tile servers to display maps. When viewing maps, your device's IP address may be visible to the tile server. No other data is shared. See [OpenStreetMap's Privacy Policy](https://wiki.osmfoundation.org/wiki/Privacy_Policy) for more information.

### GIF Search (Giphy)
The App includes a GIF picker feature powered by Giphy. When you use the GIF search feature:
- Your search queries are sent to Giphy's API servers
- Your device's IP address is visible to Giphy
- Giphy may collect usage data according to their privacy policy

GIF search is optional and only activated when you choose to use it. See [Giphy's Privacy Policy](https://support.giphy.com/hc/en-us/articles/360032872931-GIPHY-Privacy-Policy) for more information about how they handle data.

## Mesh Network Communications

Messages sent through the MeshCore mesh network are transmitted over radio frequencies to other mesh devices. The App itself does not control or monitor these communications beyond facilitating the connection between your mobile device and your MeshCore hardware.

## Data Security

All data is stored locally on your device using standard Flutter/Android storage mechanisms. The App does not implement additional encryption for locally stored data beyond what the operating system provides.

## Children's Privacy

The App does not knowingly collect any personal information from children under 13 years of age.

## Open Source

MeshTrax is open-source software. You can review the complete source code to verify these privacy practices at [the project repository].

## Changes to This Policy

We may update this Privacy Policy from time to time. Any changes will be reflected in the "Last Updated" date at the top of this policy.

## Contact

If you have questions about this Privacy Policy or the App's privacy practices, please open an issue on the project's GitHub repository.

---

**Summary**: MeshTrax is a privacy-respecting app that stores all data locally on your device. We do not collect, track, or share your personal information.
