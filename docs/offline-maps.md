# Offline maps

Mesh radios are often used where there's no phone signal. Offline maps let the MeshTrax map work there too. Words in **bold** are explained in the [glossary](glossary.md).

## What you can download

You download maps one region at a time. Each region can have several kinds of **map pack**:

| Kind | What it shows |
|---|---|
| Map | Streets, trails and places, from OpenStreetMap |
| Contours | Elevation lines |
| Hill shading | Hills and mountains, shaded under the map |
| USGS topo map | Trails, streams and reserves (United States only). USGS is the US Geological Survey; a topo map shows the shape of the land. |
| NOAA charts | Nautical charts for US coasts, picked by coast in the Charts tab. NOAA is the US ocean and weather agency. |

The app also comes with a base map of the whole world, down to towns and major roads, so there is always something to see, even with no signal and nothing downloaded.

## Downloading

1. Open the **Map** screen, tap the menu, and choose **Offline maps**.
2. Pick a region in the **Maps** tab (or a coast in the **Charts** tab), tick the kinds you want, and tap **Download**.
3. The size is shown before you start. For large downloads, use Wi-Fi and keep your device charging; **Download maps on Wi-Fi only** in App Settings makes downloads wait for Wi-Fi. You can pause and resume. The download keeps going in the background, and on Android a notification shows its progress.

The **Downloaded** tab lists what's on your device, how much space it uses, and lets you delete a region to free space. You can download it again later.

## Updates

When you open the app with offline maps installed and a day has passed since the last check, MeshTrax looks for newer versions. **Check for new maps** in Offline maps does it any time. Regions with an update show **Update available**, and **Update all** fetches them together. A downloaded map stays exactly as it is until you update it.

## Where nothing is downloaded

The map shows the base map that comes with the app: borders, water, major roads and cities, and towns of 1,000 people or more as you zoom in. It needs no signal. You can zoom in until the map is about 25 km across a phone screen; there it stops, and a card offers to download the region for detail.

Downloaded areas are outlined in teal. A setting in App Settings turns the outline off.

## Charts are not for navigation

NOAA charts in MeshTrax help you see the water around your radios and plan. They are not official charts, they leave out many symbols, and they go out of date. Don't steer by them. To navigate, use official, up-to-date NOAA charts.

## Privacy

Maps come from the MeshTrax map server, `maps.meshtrax.io`. Requests carry no personal data and no location; the server only sees which map files you asked for. Offline maps are left out of your phone's own backups. Details are in the [privacy policy](privacy.md).

## For developers

- [technical/offline-maps-notes.md](technical/offline-maps-notes.md): where the code and data live, decisions and pitfalls.
- [technical/offline-maps-roadmap.md](technical/offline-maps-roadmap.md): the integration plan and app architecture.
- [technical/park-maps.md](technical/park-maps.md): planned park map overlays.
- [packages/traxmap](../packages/traxmap/README.md): the map package itself.
