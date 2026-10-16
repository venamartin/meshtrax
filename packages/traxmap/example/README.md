# traxmap_example

Test bench for the traxmap package. It also shows how an app draws the map's
chrome itself (`lib/map_chrome.dart`: disclaimer banner and credits from
`MapStyleState`).

**Screens:**
- `lib/main.dart`: the main screen: style picker, contours on/off, ft/m, a
  pack drawer, a debug panel, and an overlay stress test.
- `lib/meshtrax_demo.dart`: MeshTrax's main map rebuilt on traxmap (hub
  button, or `OVM_SCREEN=meshtrax`).

**Desktop testing variables:**
- `OVM_STYLE=<id>`: starting style;
- `OVM_CAMERA=lat,lon,zoom`: starting view;
- `OVM_UNITS=metric`;
- `OVM_CONTOURS=off`;
- `OVM_SCREEN=meshtrax`: open the demo directly.

**Test packs:** the bundled packs in `assets/packs/` come from traxmapmaker:
`./tmm --install-to`.
