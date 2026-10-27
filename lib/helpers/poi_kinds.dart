import 'package:flutter/material.dart';
import 'package:material_symbols_icons/material_symbols_icons.dart';

import '../l10n/app_localizations.dart';

/// The icon for a point of interest or search-only name, by its kind
/// (packages/traxpoi/README.md lists them).
IconData poiKindIcon(String kind) => switch (kind) {
  'natural=peak' || 'natural=volcano' => Icons.terrain,
  'natural=saddle' || 'mountain_pass=yes' => Icons.landscape,
  'natural=spring' || 'natural=hot_spring' => Icons.water_drop,
  'waterway=waterfall' || 'waterway=river' || 'waterway=stream' => Icons.waves,
  'natural=water' => Icons.water,
  'natural=cave_entrance' || 'natural=arch' => Icons.landscape,
  'natural=glacier' => Icons.ac_unit,
  'natural=rock' || 'natural=stone' || 'natural=cliff' => Icons.landscape,
  'natural=beach' => Icons.beach_access,
  'highway=trailhead' => Icons.signpost,
  'tourism=camp_site' => Icons.cabin,
  'tourism=picnic_site' => Icons.table_restaurant,
  'tourism=wilderness_hut' || 'tourism=alpine_hut' => Icons.cottage,
  'amenity=shelter' => Icons.roofing,
  'amenity=drinking_water' || 'amenity=water_point' => Icons.water_drop,
  'amenity=toilets' => Icons.wc,
  'tourism=viewpoint' => Icons.visibility,
  'tourism=attraction' => Icons.star_outline,
  'man_made=observatory' => Symbols.planet,
  'tourism=zoo' => Icons.pets,
  'tourism=theme_park' => Icons.attractions,
  'historic=mine' || 'man_made=mineshaft' || 'man_made=adit' => Icons.hardware,
  'historic=ghost_town' => Icons.holiday_village,
  _ when kind.startsWith('historic=') => Icons.account_balance,
  'amenity=ranger_station' || 'tourism=visitor_centre' => Icons.info_outline,
  'amenity=hospital' => Icons.local_hospital,
  'amenity=police' => Icons.local_police,
  'amenity=fire_station' => Icons.local_fire_department,
  'emergency=phone' => Icons.phone,
  'amenity=fuel' => Icons.local_gas_station,
  'highway=rest_area' => Symbols.rest_area,
  'highway=services' => Icons.emoji_transportation,
  'tourism=museum' => Icons.museum,
  _ when kind.startsWith('place=') => Icons.location_city,
  'natural=valley' ||
  'natural=ridge' ||
  'natural=mountain_range' ||
  'natural=gorge' => Icons.landscape,
  'leisure=park' => Icons.park,
  'boundary=protected_area' => Icons.forest,
  'highway=path' => Icons.hiking,
  'highway=track' => Icons.landscape,
  'highway=road' => Icons.add_road,
  'address' => Icons.home_outlined,
  _ => Icons.place_outlined,
};

/// The colour of a kind's group on the map: water, land, camping, history,
/// help, or anything else.
Color poiKindColor(String kind) => switch (kind) {
  'natural=spring' ||
  'natural=hot_spring' ||
  'waterway=waterfall' ||
  'natural=water' ||
  'amenity=drinking_water' ||
  'amenity=water_point' => const Color(0xFF1E6FD9),
  'natural=peak' ||
  'natural=volcano' ||
  'natural=saddle' ||
  'mountain_pass=yes' ||
  'natural=cave_entrance' ||
  'natural=arch' ||
  'natural=glacier' ||
  'natural=rock' ||
  'natural=stone' ||
  'natural=cliff' ||
  'natural=beach' => const Color(0xFF7A5230),
  'highway=trailhead' ||
  'tourism=camp_site' ||
  'tourism=picnic_site' ||
  'tourism=wilderness_hut' ||
  'tourism=alpine_hut' ||
  'amenity=shelter' ||
  'amenity=toilets' ||
  'leisure=park' ||
  'boundary=protected_area' => const Color(0xFF2E7D32),
  'historic=mine' ||
  'man_made=mineshaft' ||
  'man_made=adit' ||
  'tourism=museum' => const Color(0xFF7B3FA0),
  _ when kind.startsWith('historic=') => const Color(0xFF7B3FA0),
  'amenity=ranger_station' ||
  'tourism=visitor_centre' ||
  'amenity=hospital' ||
  'amenity=police' ||
  'amenity=fire_station' ||
  'emergency=phone' => const Color(0xFFC62828),
  _ => const Color(0xFF00796B),
};

/// What a kind is called, in the app's language.
String poiKindLabel(AppLocalizations l10n, String kind) => switch (kind) {
  'natural=peak' => l10n.poiKind_peak,
  'natural=volcano' => l10n.poiKind_volcano,
  'natural=saddle' => l10n.poiKind_saddle,
  'mountain_pass=yes' => l10n.poiKind_pass,
  'natural=spring' => l10n.poiKind_spring,
  'natural=hot_spring' => l10n.poiKind_hotSpring,
  'waterway=waterfall' => l10n.poiKind_waterfall,
  'natural=cave_entrance' => l10n.poiKind_cave,
  'natural=arch' => l10n.poiKind_arch,
  'natural=glacier' => l10n.poiKind_glacier,
  'natural=rock' || 'natural=stone' => l10n.poiKind_rock,
  'natural=cliff' => l10n.poiKind_cliff,
  'natural=beach' => l10n.poiKind_beach,
  'highway=trailhead' => l10n.poiKind_trailhead,
  'tourism=camp_site' => l10n.poiKind_campground,
  'tourism=picnic_site' => l10n.poiKind_picnicSite,
  'tourism=wilderness_hut' || 'tourism=alpine_hut' => l10n.poiKind_hut,
  'amenity=shelter' => l10n.poiKind_shelter,
  'amenity=drinking_water' ||
  'amenity=water_point' => l10n.poiKind_drinkingWater,
  'amenity=toilets' => l10n.poiKind_toilets,
  'tourism=viewpoint' => l10n.poiKind_viewpoint,
  'tourism=attraction' => l10n.poiKind_attraction,
  'man_made=observatory' => l10n.poiKind_observatory,
  'tourism=zoo' => l10n.poiKind_zoo,
  'tourism=theme_park' => l10n.poiKind_themePark,
  'historic=mine' => l10n.poiKind_mine,
  'man_made=mineshaft' => l10n.poiKind_mineShaft,
  'man_made=adit' => l10n.poiKind_adit,
  'historic=ghost_town' => l10n.poiKind_ghostTown,
  'historic=ruins' => l10n.poiKind_ruins,
  'historic=monument' => l10n.poiKind_monument,
  'historic=memorial' => l10n.poiKind_memorial,
  'historic=fort' || 'historic=castle' => l10n.poiKind_fort,
  _ when kind.startsWith('historic=') => l10n.poiKind_historic,
  'amenity=ranger_station' => l10n.poiKind_rangerStation,
  'tourism=visitor_centre' => l10n.poiKind_visitorCenter,
  'amenity=hospital' => l10n.poiKind_hospital,
  'amenity=police' => l10n.poiKind_police,
  'amenity=fire_station' => l10n.poiKind_fireStation,
  'emergency=phone' => l10n.poiKind_emergencyPhone,
  'amenity=fuel' => l10n.poiKind_fuel,
  'highway=rest_area' => l10n.poiKind_restArea,
  'highway=services' => l10n.poiKind_travelCenter,
  'tourism=museum' => l10n.poiKind_museum,
  'place=city' => l10n.poiKind_city,
  'place=town' || 'place=village' => l10n.poiKind_town,
  'place=hamlet' || 'place=locality' => l10n.poiKind_locality,
  'natural=water' => l10n.poiKind_lake,
  'waterway=river' || 'waterway=stream' => l10n.poiKind_river,
  'natural=valley' || 'natural=gorge' => l10n.poiKind_valley,
  'natural=ridge' || 'natural=mountain_range' => l10n.poiKind_range,
  'leisure=park' => l10n.poiKind_park,
  'boundary=protected_area' => l10n.poiKind_protectedArea,
  'highway=path' => l10n.poiKind_trail,
  'highway=track' => l10n.poiKind_dirtRoad,
  'highway=road' => l10n.poiKind_road,
  'address' => l10n.poiKind_address,
  _ => l10n.poiKind_place,
};
