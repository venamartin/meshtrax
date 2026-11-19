import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/widgets/line_of_sight_sheet.dart';
import 'package:traxlos/traxlos.dart' show Verdict;

// Who can hear you comes first in the radio reach list, so it needs no
// scrolling (owner, 2026-11-18).
void main() {
  test("Clear, Marginal, Blocked, Can't tell, then guessed positions; "
      'nearest first in each', () {
    final rows = <(String, Verdict?, double)>[
      ('blocked near', Verdict.blocked, 1000),
      ('guessed near', null, 500),
      ('clear far', Verdict.clear, 90000),
      ("can't tell", Verdict.unknown, 2000),
      ('marginal', Verdict.marginal, 3000),
      ('clear near', Verdict.clear, 4000),
      ('blocked far', Verdict.blocked, 8000),
      ('guessed far', null, 7000),
    ]..sort((a, b) => compareReachRows(a.$2, a.$3, b.$2, b.$3));
    expect(rows.map((r) => r.$1), [
      'clear near',
      'clear far',
      'marginal',
      'blocked near',
      'blocked far',
      "can't tell",
      'guessed near',
      'guessed far',
    ]);
  });
}
