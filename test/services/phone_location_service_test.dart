import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart' show LatLng;

import 'package:meshtrax/services/phone_location_service.dart';

import '../helpers/map_fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const providence = LatLng(41.82, -71.41);
  const newport = LatLng(41.49, -71.31);
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('nothing is read until My location is used, even if the OS allows '
      'it (Android 11 and below grant it for Bluetooth scans)', () async {
    final source = FakePhoneLocation(permission: PhoneLocationState.granted);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    expect(source.updates.hasListener, isFalse);
    expect(phone.position, isNull);
    phone.mapClosed();
  });

  test('My location asks once, then follows while the map is open', () async {
    final source = FakePhoneLocation(here: providence);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    expect(source.requests, 0, reason: 'a map opening never asks');

    expect(await phone.locate(), providence);
    expect(source.requests, 1);
    expect(phone.position, providence);
    source.updates.add(newport);
    await settle();
    expect(phone.position, newport, reason: 'following since the tap');

    expect(await phone.locate(), providence);
    expect(source.requests, 1, reason: 'answered already');

    phone.mapClosed();
    expect(source.updates.hasListener, isFalse);
    expect(phone.position, isNull, reason: 'no stale dot next time');
  });

  test('used before: a map opening follows straight away', () async {
    await prefs.setBool('my_location_used', true);
    final source = FakePhoneLocation(permission: PhoneLocationState.granted);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    source.updates.add(providence);
    await settle();
    expect(phone.position, providence);
    phone.mapClosed();
  });

  test('two maps open: the first closing keeps following', () async {
    await prefs.setBool('my_location_used', true);
    final source = FakePhoneLocation(permission: PhoneLocationState.granted);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    await phone.mapOpened();
    phone.mapClosed();
    expect(source.updates.hasListener, isTrue);
    phone.mapClosed();
    expect(source.updates.hasListener, isFalse);
  });

  test('in the background: not followed; back in front: again', () async {
    await prefs.setBool('my_location_used', true);
    final source = FakePhoneLocation(permission: PhoneLocationState.granted);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    expect(source.updates.hasListener, isTrue);

    phone.didChangeAppLifecycleState(AppLifecycleState.paused);
    expect(source.updates.hasListener, isFalse);
    phone.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await settle();
    expect(source.updates.hasListener, isTrue);
    phone.mapClosed();
  });

  test(
    'location turned off: not followed (Android would pop a dialog)',
    () async {
      await prefs.setBool('my_location_used', true);
      final source = FakePhoneLocation(
        permission: PhoneLocationState.granted,
        serviceOn: false,
      );
      final phone = PhoneLocationService(source, prefs);
      await phone.mapOpened();
      expect(source.updates.hasListener, isFalse);
      expect(phone.state, PhoneLocationState.serviceOff);
      phone.mapClosed();
    },
  );

  test('a failing stream stops, and the next tap starts again', () async {
    final source = FakePhoneLocation(here: providence);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    await phone.locate();
    source.updates.addError(Exception('location off'));
    await settle();
    expect(phone.position, isNull);
    expect(source.updates.hasListener, isFalse);

    await phone.locate();
    expect(source.updates.hasListener, isTrue);
    phone.mapClosed();
  });

  test('My location returns only a fresh fix', () async {
    final source = FakePhoneLocation(here: providence);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    await phone.locate();
    source.here = null;
    expect(await phone.locate(), isNull, reason: 'not the old fix');
    phone.mapClosed();
  });

  test('two quick taps share one request', () async {
    final source = FakePhoneLocation(here: providence);
    final phone = PhoneLocationService(source, prefs);
    final both = await Future.wait([phone.locate(), phone.locate()]);
    expect(both, [providence, providence]);
    expect(source.requests, 1);
  });

  test('denied: no position, and the state says why', () async {
    final source = FakePhoneLocation(
      here: providence,
      answer: PhoneLocationState.deniedForever,
    );
    final phone = PhoneLocationService(source, prefs);
    expect(await phone.locate(), isNull);
    expect(phone.state, PhoneLocationState.deniedForever);
    expect(prefs.getBool('my_location_used'), isNull);
  });

  test('no sensor (Linux): nothing asked, nothing shown', () async {
    final source = FakePhoneLocation(supported: false, here: providence);
    final phone = PhoneLocationService(source, prefs);
    await phone.mapOpened();
    expect(await phone.locate(), isNull);
    expect(phone.state, PhoneLocationState.unsupported);
    expect(source.requests, 0);
  });
}
