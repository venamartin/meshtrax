/// Weighted-graph path determination for MeshCore DMs.
///
/// Black box: everything the module knows arrives through the typed
/// inputs on [PathGraph]; it never parses wire frames and never reads
/// app storage. Design: docs/path-graph-design.md.
library;

export 'src/api.dart';
