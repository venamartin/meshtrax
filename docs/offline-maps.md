# Offline maps

Mesh radios are often used where there's no phone signal. Offline maps let the MeshTrax map work there too. Words in **bold** are explained in the [glossary](glossary.md).

## What you can download

You download maps one region at a time. Each region can have several kinds of **map pack**:

| Kind | What it shows |
|---|---|
| Map | Streets, trails and places, from OpenStreetMap |
| Contours | Elevation lines |
| Hill shading | Hills and mountains, shaded under the map |
| USGS topo map | Trails, streams and reserves (United States only) |
| NOAA charts | Nautical charts for US coasts, picked by coast in the Charts tab |

The app also includes a simple world map, so there is always something to see.

## Downloading

1. Open the **Map** screen, tap the menu, and choose **Offline maps**.
2. Pick a region in the **Maps** tab (or a coast in the **Charts** tab), tick the kinds you want, and tap **Download**.
3. The size is shown before you start. For large downloads, use Wi-Fi and keep your device charging. You can pause and resume, and the download keeps going in the background.

The **Downloaded** tab lists what's on your device, how much space it uses, and lets you delete a region to free space. You can download it again later.

## Updates

While you have offline maps installed, MeshTrax checks for newer versions about once a day. Regions with an update show **Update available**, and **Update all** fetches them together. A downloaded map stays exactly as it is until you update it.

## Online or Offline

The map has an **Online | Offline** switch:

- **Offline** shows only what works without signal: your downloaded maps and the world map. Where you haven't downloaded a region, the map shows a card offering a download, and it won't zoom in further there.
- **Online** fills in everything you haven't downloaded with online OpenStreetMap tiles. Downloaded areas are outlined in teal so you can tell them apart.

Until you download a street or topo map, the map stays online.

Online **map tiles** you've viewed are kept for a while so they load faster. You can clear them in the **Downloaded** tab of Offline maps.

## Charts are not for navigation

NOAA charts in MeshTrax help you see the water around your radios and plan. They are not official charts, they leave out many symbols, and they go out of date. Don't steer by them. To navigate, use official, up-to-date NOAA charts.

## Privacy

Maps come from the MeshTrax map server, `maps.meshtrax.io`. Requests carry no personal data and no location; the server only sees which map files you asked for. Offline maps are left out of your phone's own backups. Details are in the [privacy policy](privacy.md).

## For developers

- [technical/offline-maps-notes.md](technical/offline-maps-notes.md): where the code and data live, decisions and pitfalls.
- [technical/offline-maps-roadmap.md](technical/offline-maps-roadmap.md): the integration plan and app architecture.
- [technical/park-maps.md](technical/park-maps.md): planned park map overlays.
- [packages/traxmap](../packages/traxmap/README.md): the map package itself.
