import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/services/path_graph/place_cell.dart';

// About 500 m cells with their eight neighbours: close means the same or
// a touching cell, a couple of kilometres means neither.
void main() {
  const lat = 36.9712, lon = -121.7334; // Monterey Bay
  const metre = 1 / 111320.0; // degrees of latitude per metre

  test('a key names a cell, never a coordinate', () {
    final c = PlaceCell.of(lat, lon);
    expect(c.key, matches(r'^c-?\d+_-?\d+$'));
    expect(c.near, hasLength(8));
    expect(c.near, isNot(contains(c.key)));
  });

  test('a short walk stays in the block, a drive leaves it', () {
    final home = PlaceCell.of(lat, lon);
    final street = PlaceCell.of(lat + 300 * metre, lon);
    expect({home.key, ...home.near}, contains(street.key));

    final town = PlaceCell.of(lat + 2000 * metre, lon);
    expect({home.key, ...home.near}, isNot(contains(town.key)));
    final east = PlaceCell.of(lat, lon + 2000 * metre / 0.8);
    expect({home.key, ...home.near}, isNot(contains(east.key)));
  });

  test('cells keep their width as the latitude changes', () {
    // At 60° north a degree of longitude is half as long, so the cell
    // spans twice the degrees: 500 m east is still inside the block.
    final far = PlaceCell.of(60.0, 10.0);
    final eastOfFar = PlaceCell.of(60.0, 10.0 + 500 * metre / 0.5);
    expect({far.key, ...far.near}, contains(eastOfFar.key));
  });
}
