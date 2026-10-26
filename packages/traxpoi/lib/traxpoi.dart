/// Offline points of interest and addresses: the downloaded SQLite files,
/// typo-tolerant search and the places around a point. No screens.
library;

export 'src/catalog.dart';
export 'src/db/addresses_database.dart' show AddressesDatabase, AddressData;
export 'src/db/points_database.dart'
    show FeatureData, PhotoData, PlaceData, PointsDatabase, WikiData;
export 'src/normalize.dart';
export 'src/poi_region.dart';
export 'src/search.dart' show GeoPoint;
