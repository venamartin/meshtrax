import 'legend_symbol.dart';

/// The chart legend's sections, in order.
enum ChartLegendSection {
  buoys,
  lights,
  hazards,
  tides,
  depths,
  areas,
  landmarks,
  abbreviations,
}

/// What the chart styles draw, for a legend: each item is drawn from
/// [samples], features as the styles' layers draw them. The app supplies
/// the words.
enum ChartLegendItem {
  portBuoy(ChartLegendSection.buoys, [
    LegendSample('buoy', {'kind': 'buoy', 'shape': 'can', 'colour': 'green'}),
  ]),
  starboardBuoy(ChartLegendSection.buoys, [
    LegendSample('buoy', {'kind': 'buoy', 'shape': 'conical', 'colour': 'red'}),
  ]),
  junctionBuoy(ChartLegendSection.buoys, [
    LegendSample('buoy', {
      'kind': 'buoy',
      'shape': 'can',
      'colours': 'green,red,green',
      'colour_pattern': 'horizontal_stripes',
    }),
  ]),
  safeWaterBuoy(ChartLegendSection.buoys, [
    LegendSample('buoy', {
      'kind': 'buoy',
      'shape': 'spherical',
      'colours': 'red,white',
      'colour_pattern': 'vertical_stripes',
    }),
  ]),
  isolatedDangerBuoy(ChartLegendSection.buoys, [
    LegendSample('buoy', {
      'kind': 'buoy',
      'shape': 'pillar',
      'colours': 'black,red,black',
      'colour_pattern': 'horizontal_stripes',
    }),
  ]),
  specialBuoy(ChartLegendSection.buoys, [
    LegendSample('buoy', {'kind': 'buoy', 'shape': 'can', 'colour': 'yellow'}),
  ]),
  cardinalBuoy(ChartLegendSection.buoys, [
    LegendSample('buoy', {
      'kind': 'buoy',
      'shape': 'pillar',
      'colours': 'black,yellow',
      'colour_pattern': 'horizontal_stripes',
    }),
  ]),
  mooringBuoy(ChartLegendSection.buoys, [
    LegendSample('dolphin', {'class': 'MORFAC', 'category': 'mooring_buoy'}),
  ]),
  portBeacon(ChartLegendSection.buoys, [
    LegendSample('beacon', {
      'kind': 'beacon',
      'side': 'port',
      'colour': 'green',
    }),
  ]),
  starboardBeacon(ChartLegendSection.buoys, [
    LegendSample('beacon', {
      'kind': 'beacon',
      'side': 'starboard',
      'colour': 'red',
    }),
  ]),
  otherBeacon(ChartLegendSection.buoys, [
    LegendSample('beacon', {
      'kind': 'beacon',
      'colours': 'white,orange',
      'colour_pattern': 'horizontal_stripes',
    }),
  ]),
  beaconTower(ChartLegendSection.buoys, [
    LegendSample('beacon-tower', {'kind': 'beacon', 'shape': 'tower'}),
  ]),
  topmark(ChartLegendSection.buoys, [
    LegendSample('topmark', {'class': 'TOPMAR', 'shape': 'two_cones_up'}),
  ]),

  light(ChartLegendSection.lights, [
    LegendSample('buoy', {
      'kind': 'buoy',
      'shape': 'pillar',
      'colour': 'green',
    }),
    LegendSample('light-flare'),
  ]),
  lightExample(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Fl G 4s'),
  ]),
  lightFixed(ChartLegendSection.lights, [LegendSample('light-label', {}, 'F')]),
  lightFlashing(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Fl'),
  ]),
  lightGroup(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Fl(2)'),
  ]),
  lightComposite(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Fl(2+1)'),
  ]),
  lightQuick(ChartLegendSection.lights, [LegendSample('light-label', {}, 'Q')]),
  lightIsophase(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Iso'),
  ]),
  lightOcculting(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Oc'),
  ]),
  lightMorse(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Mo(A)'),
  ]),
  lightAlternating(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'Al'),
  ]),
  lightColours(ChartLegendSection.lights, [
    LegendSample('light-label', {}, 'W R G Y'),
  ]),
  lightPeriod(ChartLegendSection.lights, [
    LegendSample('light-label', {}, '4s'),
  ]),

  rock(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {'kind': 'rock'}),
  ]),
  rockAwash(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {'kind': 'rock', 'water_level': 'awash'}),
  ]),
  rockCovers(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {
      'kind': 'rock',
      'water_level': 'covers_uncovers',
    }),
  ]),
  wreckDangerous(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {'kind': 'wreck', 'dangerous': 1}),
  ]),
  wreck(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {'kind': 'wreck'}),
  ]),
  wreckShowing(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {
      'kind': 'wreck',
      'category': 'hull_showing',
    }),
  ]),
  obstruction(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {'kind': 'obstruction'}),
  ]),
  foulGround(ChartLegendSection.hazards, [
    LegendSample('hazard-symbol', {
      'kind': 'obstruction',
      'category': 'foul_ground',
    }),
  ]),
  hazardArea(ChartLegendSection.hazards, [LegendSample('hazard-area')]),
  pile(ChartLegendSection.hazards, [
    LegendSample('pile', {'class': 'PILPNT'}),
  ]),

  floodStream(ChartLegendSection.tides, [
    LegendSample('stream-arrow', {
      'class': 'TS_FEB',
      'category': 'flood',
      'orient': 90,
    }),
  ]),
  ebbStream(ChartLegendSection.tides, [
    LegendSample('stream-arrow', {
      'class': 'TS_FEB',
      'category': 'ebb',
      'orient': 90,
    }),
  ]),
  current(ChartLegendSection.tides, [
    LegendSample('stream-arrow', {'class': 'CURENT', 'orient': 90}),
  ]),
  rips(ChartLegendSection.tides, [
    LegendSample('turbulence', {'class': 'WATTUR'}),
  ]),
  breakers(ChartLegendSection.tides, [
    LegendSample('breakers', {'class': 'WATTUR'}),
  ]),

  sounding(ChartLegendSection.depths, [LegendSample('sounding', {}, '12')]),
  depthContour(ChartLegendSection.depths, [LegendSample('depth-contour')]),
  drying(ChartLegendSection.depths, [
    LegendSample('depth-area', {'drval1': -1}),
  ]),
  depthShallow(
    ChartLegendSection.depths,
    [
      LegendSample('depth-area', {'drval1': 0}),
    ],
    depth: (0, 5),
  ),
  depthMedium(
    ChartLegendSection.depths,
    [
      LegendSample('depth-area', {'drval1': 5}),
    ],
    depth: (5, 18),
  ),
  depthDeep(
    ChartLegendSection.depths,
    [
      LegendSample('depth-area', {'drval1': 18}),
    ],
    depth: (18, 30),
  ),
  depthDeepest(
    ChartLegendSection.depths,
    [
      LegendSample('depth-area', {'drval1': 30}),
    ],
    depth: (30, null),
  ),
  dredged(ChartLegendSection.depths, [
    LegendSample('depth-area', {'drval1': 5}),
    LegendSample('dredged-outline', {'kind': 'dredged'}),
  ]),
  swept(ChartLegendSection.depths, [
    LegendSample('swept-limit', {'class': 'SWPARE'}),
  ]),
  unsurveyed(ChartLegendSection.depths, [
    LegendSample('unsurveyed', {'class': 'UNSARE'}),
  ]),
  weed(ChartLegendSection.depths, [
    LegendSample('seabed-weed', {'class': 'WEDKLP'}),
  ]),

  restricted(ChartLegendSection.areas, [
    LegendSample('restricted-limit', {
      'class': 'RESARE',
      'restriction': 'entry',
    }),
  ]),
  regulatedLimit(ChartLegendSection.areas, [
    LegendSample('regulated-limit', {'class': 'CTNARE'}),
  ]),
  greyLimit(ChartLegendSection.areas, [
    LegendSample('regulated-limit', {'class': 'DMPGRD'}),
  ]),
  anchorage(ChartLegendSection.areas, [
    LegendSample('regulated-symbol', {'class': 'ACHARE'}),
  ]),
  anchorBerth(ChartLegendSection.areas, [
    LegendSample('regulated-symbol', {'class': 'ACHBRT'}),
  ]),
  noAnchoring(ChartLegendSection.areas, [
    LegendSample('regulated-symbol', {
      'class': 'RESARE',
      'restriction': 'anchoring',
    }),
  ]),
  caution(ChartLegendSection.areas, [
    LegendSample('regulated-symbol', {'class': 'CTNARE'}),
  ]),
  trafficLane(ChartLegendSection.areas, [
    LegendSample('lane-arrow', {'class': 'TSSLPT', 'anchor': 1, 'orient': 90}),
  ]),
  separationZone(ChartLegendSection.areas, [
    LegendSample('tss-zone', {'class': 'TSEZNE'}),
  ]),
  precautionary(ChartLegendSection.areas, [
    LegendSample('precautionary', {'class': 'PRCARE'}),
  ]),
  fairway(ChartLegendSection.areas, [
    LegendSample('fairway', {'class': 'FAIRWY'}),
  ]),
  track(ChartLegendSection.areas, [
    LegendSample('track', {'class': 'RECTRC'}),
  ]),
  ferry(ChartLegendSection.areas, [
    LegendSample('track', {'class': 'FERYRT'}),
  ]),
  leadingLine(ChartLegendSection.areas, [
    LegendSample('leading-line', {'class': 'NAVLNE'}),
  ]),
  cable(ChartLegendSection.areas, [
    LegendSample('cable', {'class': 'CBLSUB'}),
  ]),
  pipeline(ChartLegendSection.areas, [
    LegendSample('pipeline', {'class': 'PIPSOL'}),
  ]),
  overhead(ChartLegendSection.areas, [
    LegendSample('overhead-line', {'class': 'CBLOHD'}),
  ]),

  tower(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {'class': 'LNDMRK', 'category': 'tower'}),
  ]),
  windTurbine(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {
      'class': 'LNDMRK',
      'category': 'windmotor',
    }),
  ]),
  chimney(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {'class': 'LNDMRK', 'category': 'chimney'}),
  ]),
  mast(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {'class': 'LNDMRK', 'category': 'mast'}),
  ]),
  church(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {
      'class': 'LNDMRK',
      'category': 'spire_minaret',
    }),
  ]),
  flagstaff(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {
      'class': 'LNDMRK',
      'category': 'flagstaff',
    }),
  ]),
  dome(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {'class': 'LNDMRK', 'category': 'dome'}),
  ]),
  landmark(ChartLegendSection.landmarks, [
    LegendSample('landmark-symbol', {'class': 'LNDMRK'}),
  ]),

  abbrAnch(ChartLegendSection.abbreviations, [
    LegendSample('regulated-label', {'class': 'ACHARE'}, 'Anch'),
  ]),
  abbrWk(ChartLegendSection.abbreviations, [
    LegendSample('hazard-label', {'kind': 'wreck'}, 'Wk'),
  ]),
  abbrBr(ChartLegendSection.abbreviations, [
    LegendSample('breakers-label', {'class': 'WATTUR'}, 'Br'),
  ]),
  abbrWd(ChartLegendSection.abbreviations, [
    LegendSample('weed-label', {'class': 'WEDKLP'}, 'Wd'),
  ]),
  abbrVar(ChartLegendSection.abbreviations, [
    LegendSample('magvar', {'class': 'MAGVAR', 'label': ''}, 'Var'),
  ]),
  abbrVc(ChartLegendSection.abbreviations, [
    LegendSample('clearance', {'clearance_m': 10, 'anchor': 1}, 'VC'),
  ]),
  abbrTr(ChartLegendSection.abbreviations, [
    LegendSample('landmark-label', {'class': 'LNDMRK'}, 'Tr'),
  ]),
  abbrCh(ChartLegendSection.abbreviations, [
    LegendSample('landmark-label', {'class': 'LNDMRK'}, 'Ch'),
  ]),
  abbrChy(ChartLegendSection.abbreviations, [
    LegendSample('landmark-label', {'class': 'LNDMRK'}, 'Chy'),
  ]),
  abbrFs(ChartLegendSection.abbreviations, [
    LegendSample('landmark-label', {'class': 'LNDMRK'}, 'FS'),
  ]),
  abbrTk(ChartLegendSection.abbreviations, [
    LegendSample('landmark-label', {'class': 'LNDMRK'}, 'Tk'),
  ]),
  abbrRBn(ChartLegendSection.abbreviations, [
    LegendSample('harbour-label', {}, 'R Bn'),
  ]),
  abbrCg(ChartLegendSection.abbreviations, [
    LegendSample('harbour-label', {}, 'CG'),
  ]),
  abbrRacon(ChartLegendSection.abbreviations, [
    LegendSample('aid-extra-label', {'class': 'RTPBCN'}, 'Racon'),
  ]),
  abbrFog(ChartLegendSection.abbreviations, [
    LegendSample('aid-extra-label', {'class': 'FOGSIG'}, 'Horn'),
  ]),
  abbrVAis(ChartLegendSection.abbreviations, [
    LegendSample('virtual-aid-label', {'virtual': 1}, 'V-AIS'),
  ]);

  final ChartLegendSection section;
  final List<LegendSample> samples;

  /// For a depth area: the depths it spans, in metres (`to` null for
  /// everything deeper).
  final (double from, double? to)? depth;

  const ChartLegendItem(this.section, this.samples, {this.depth});

  /// The items of [section], in order.
  static List<ChartLegendItem> of(ChartLegendSection section) => [
    for (final item in values)
      if (item.section == section) item,
  ];
}

/// What chart legend samples are drawn on: open water.
const chartLegendGround = LegendSample('depth-area', {'drval1': 100});
