import 'package:test/test.dart';
import 'package:traxshare/traxshare.dart';

void main() {
  Duration at(int members, [int airtimeMs = referenceReportAirtimeMs]) =>
      beaconInterval(members: members, reportAirtimeMs: airtimeMs);

  test('30 seconds per member at the mesh preset', () {
    expect(at(2), const Duration(minutes: 1));
    expect(at(5), const Duration(seconds: 150));
    expect(at(10), const Duration(minutes: 5));
  });

  test('never faster than every minute', () {
    expect(at(1), const Duration(minutes: 1));
    expect(at(0), const Duration(minutes: 1));
  });

  test('a slower preset stretches it by its airtime', () {
    expect(at(2, 518).inSeconds, 145);
    expect(at(4, 428), const Duration(minutes: 4));
  });

  test('a faster preset does not shorten it', () {
    expect(at(2, 60), const Duration(minutes: 1));
  });
}
