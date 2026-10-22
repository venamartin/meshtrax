import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:traxmap/traxmap.dart' show LatLng;

import 'package:meshtrax/services/phone_location_service.dart';

/// geolocator's platform side, scripted.
class _Platform extends GeolocatorPlatform with MockPlatformInterfaceMixin {
  bool serviceOn = true;
  LocationPermission permission = LocationPermission.denied;
  LocationPermission answer = LocationPermission.whileInUse;
  Position? fix;
  Position? lastKnown;
  var requests = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => serviceOn;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    return permission = answer;
  }

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => fix ?? (throw TimeoutException('no fix'));

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => lastKnown;
}

Position _at(double lat, double lon, {Duration age = Duration.zero}) =>
    Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now().subtract(age),
      accuracy: 5,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  late _Platform platform;
  final source = GeolocatorSource();

  setUp(() => GeolocatorPlatform.instance = platform = _Platform());

  test('GPS on phones, Windows and macOS; the radio on Linux', () {
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    for (final (p, gps) in [
      (TargetPlatform.android, true),
      (TargetPlatform.iOS, true),
      (TargetPlatform.macOS, true),
      (TargetPlatform.windows, true),
      (TargetPlatform.linux, false),
    ]) {
      debugDefaultTargetPlatformOverride = p;
      expect(source.supported, gps, reason: '$p');
    }
  });

  test('never asked reads as denied, and asking shows the prompt', () async {
    expect(await source.check(), PhoneLocationState.denied);
    expect(platform.requests, 0);
    expect(await source.request(), PhoneLocationState.granted);
    expect(platform.requests, 1);
    expect(await source.request(), PhoneLocationState.granted);
    expect(platform.requests, 1, reason: 'granted already');
  });

  test('denied for good is not asked again', () async {
    platform.permission = LocationPermission.deniedForever;
    expect(await source.request(), PhoneLocationState.deniedForever);
    expect(platform.requests, 0);
  });

  test('location off: neither checked nor asked', () async {
    platform
      ..serviceOn = false
      ..permission = LocationPermission.whileInUse;
    expect(await source.check(), PhoneLocationState.serviceOff);
    expect(await source.request(), PhoneLocationState.serviceOff);
    expect(platform.requests, 0);
  });

  test('a fix, else a recent last-known one, else none', () async {
    platform.fix = _at(41.8, -71.4);
    expect(await source.current(), const LatLng(41.8, -71.4));

    platform
      ..fix = null
      ..lastKnown = _at(41.5, -71.3, age: const Duration(seconds: 30));
    expect(await source.current(), const LatLng(41.5, -71.3));

    platform.lastKnown = _at(41.5, -71.3, age: const Duration(hours: 3));
    expect(await source.current(), isNull, reason: 'too old to centre on');
  });
}
