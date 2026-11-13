import 'package:test/test.dart';
import 'package:traxpoi/src/search.dart';

void main() {
  test('the same word is 100, words with no letter in common 0', () {
    expect(similarity('diablo', 'diablo'), 100);
    expect(similarity('abc', 'xyz'), 0);
  });

  test('twice the common subsequence over the combined length', () {
    expect(similarity('kitten', 'sitting'), 62); // 2 × 4 / 13
    expect(similarity('diablo', 'diabol'), 83); // 2 × 5 / 12
    expect(similarity('canon', 'canyon'), 91); // 2 × 5 / 11
  });

  test('the order of the two words does not matter', () {
    expect(similarity('fothill', 'foothill'), 93);
    expect(similarity('foothill', 'fothill'), 93);
  });

  test('an empty word matches nothing', () {
    expect(similarity('', 'abc'), 0);
    expect(similarity('abc', ''), 0);
  });
}
