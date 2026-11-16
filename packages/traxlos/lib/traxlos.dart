/// Radio line of sight and radio reach, worked out offline from the
/// installed contours packs (z13 tiles, layer `contour`).
///
/// The ground along a line comes from where it crosses contour lines:
/// straight slopes between lines of different heights, hills and valleys
/// between two crossings of the same line, and points every 50 m so the
/// earth's curve (k = 4/3) shows on flat ground. Answers allow for the
/// data's error of about one contour interval, and say "can't tell"
/// ([Verdict.unknown]) where the data runs out. Terrain only: no trees,
/// buildings, bodies or link budget.
library;

export 'src/geo.dart' show Geo, distanceM, destination;
export 'src/line_of_sight.dart'
    show
        EndHeight,
        HeightIssue,
        HeightSource,
        LineOfSight,
        LinkEnd,
        NearRadio,
        Obstacle,
        Peak,
        Stretch,
        TerrainProfile,
        UnknownReason,
        Verdict,
        defaultFrequencyMHz,
        earthBulgeM,
        fresnelRadiusM,
        kFactor,
        lineOfSightOver;
export 'src/profile.dart' show PointKind;
export 'src/reach.dart' show Reach, ReachRun;
export 'src/terrain.dart' show ContourPack, ContourTerrain;
