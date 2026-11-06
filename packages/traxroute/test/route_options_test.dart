import 'package:test/test.dart';
import 'package:traxroute/traxroute.dart';

void main() {
  test('each path type is at its defaults until one of its own changes', () {
    const tolls = RouteOptions(avoidTolls: true);
    expect(tolls.isDefaultFor(PathType.paved), isFalse);
    expect(tolls.isDefaultFor(PathType.dirt), isFalse);
    expect(tolls.isDefaultFor(PathType.hiking), isTrue);
    const t5 = RouteOptions(hardestTrail: 5);
    expect(t5.isDefaultFor(PathType.hiking), isFalse);
    expect(t5.isDefaultFor(PathType.paved), isTrue);
    const direct = RouteOptions(dirt: DirtPreference.direct);
    expect(direct.isDefaultFor(PathType.dirt), isFalse);
    expect(direct.isDefaultFor(PathType.paved), isTrue);
  });

  test("reset puts back only that path type's options", () {
    const changed = RouteOptions(
      avoidTolls: true,
      dirt: DirtPreference.fastest,
      hardestTrail: 5,
    );
    final dirt = changed.resetFor(PathType.dirt);
    expect(dirt.isDefaultFor(PathType.dirt), isTrue);
    expect(dirt.hardestTrail, 5);
    final paved = changed.resetFor(PathType.paved);
    expect(paved.avoidTolls, isFalse);
    expect(paved.dirt, DirtPreference.fastest);
    final hiking = changed.resetFor(PathType.hiking);
    expect(hiking.hardestTrail, 3);
    expect(hiking.avoidTolls, isTrue);
  });

  test('options survive saving; anything odd reads as its default', () {
    const options = RouteOptions(
      avoidHighways: true,
      dirt: DirtPreference.direct,
      hardestTrail: 6,
      climbs: ClimbPreference.some,
      pace: HikingPace.fast,
    );
    final back = RouteOptions.fromJson(options.toJson());
    expect(back.toJson(), options.toJson());

    final odd = RouteOptions.fromJson({
      'dirt': 'sideways',
      'hardest_trail': 9,
      'climbs': 3,
    });
    expect(odd.toJson(), const RouteOptions().toJson());
  });
}
