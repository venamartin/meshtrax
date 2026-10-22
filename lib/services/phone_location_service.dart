import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traxmap/traxmap.dart' show LatLng;

import '../storage/prefs_manager.dart';

/// Whether the map may use this phone's own location.
enum PhoneLocationState {
  /// No location sensor to ask (Linux, web): the map uses the radio's.
  unsupported,

  /// The platform can't tell.
  unknown,

  /// Location is turned off for the whole phone.
  serviceOff,

  /// Not allowed (yet): asking again may still show the prompt.
  denied,

  /// Denied for good: only the system settings can turn it back on.
  deniedForever,
  granted,
}

/// The platform's location API: geolocator, or a fake in tests.
abstract class PhoneLocationSource {
  bool get supported;

  /// The permission as it stands, without asking.
  Future<PhoneLocationState> check();

  /// Asks for permission (while in use) unless it was answered for good.
  Future<PhoneLocationState> request();

  /// A fresh position, or null.
  Future<LatLng?> current();
  Stream<LatLng> positions();
  Future<void> openSettings();
}

/// This phone's own location, for the map's "My location" button and the
/// phone's marker.
///
/// Nothing is read until the user taps My location once: the OS permission
/// alone doesn't count, because Android 11 and below grant location for
/// Bluetooth scans and Windows asks when it's merely checked. After that the
/// phone is followed while a map is open and the app is in front.
class PhoneLocationService extends ChangeNotifier with WidgetsBindingObserver {
  static const _usedKey = 'my_location_used';

  final PhoneLocationSource source;
  final SharedPreferences? _prefs;
  PhoneLocationState _state = PhoneLocationState.unknown;
  LatLng? _position;
  StreamSubscription<LatLng>? _updates;
  Future<LatLng?>? _locating;
  int _maps = 0;
  bool _inFront = true;

  PhoneLocationService([PhoneLocationSource? source, SharedPreferences? prefs])
    : source = source ?? GeolocatorSource(),
      _prefs = prefs;

  SharedPreferences get _store => _prefs ?? PrefsManager.instance;

  /// Whether the user has ever used My location.
  bool get _used => _store.getBool(_usedKey) ?? false;

  PhoneLocationState get state =>
      source.supported ? _state : PhoneLocationState.unsupported;

  /// Where the phone is, while it's being followed.
  LatLng? get position => _updates == null ? null : _position;

  /// A map that shows the phone opened. Never asks.
  Future<void> mapOpened() async {
    if (!source.supported || _maps++ > 0) return;
    WidgetsBinding.instance.addObserver(this);
    await _recheck();
  }

  void mapClosed() {
    if (!source.supported || --_maps > 0) return;
    WidgetsBinding.instance.removeObserver(this);
    _stop();
  }

  /// For "My location": asks for permission the first time, then reads a
  /// fresh position. Null when there's none; [state] says why. A second tap
  /// while one is running shares it.
  Future<LatLng?> locate() =>
      _locating ??= _locate().whenComplete(() => _locating = null);

  Future<LatLng?> _locate() async {
    if (!source.supported) return null;
    _state = await _ask(source.request);
    LatLng? fresh;
    if (_state == PhoneLocationState.granted) {
      await _store.setBool(_usedKey, true);
      fresh = await source.current();
      if (fresh != null) _position = fresh;
      _follow();
    }
    notifyListeners();
    return fresh;
  }

  Future<void> openSettings() => source.openSettings();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _inFront =
        state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (_inFront) {
      // Location may have been turned on or off meanwhile.
      unawaited(_recheck());
    } else {
      _stop();
    }
  }

  Future<void> _recheck() async {
    if (_maps == 0 || !_used) return;
    _state = await _ask(source.check);
    if (_state == PhoneLocationState.granted) {
      _follow();
    } else {
      _stop();
    }
    notifyListeners();
  }

  void _follow() {
    if (_maps == 0 || !_inFront || _state != PhoneLocationState.granted) {
      return;
    }
    _updates ??= source.positions().listen(
      (p) {
        _position = p;
        notifyListeners();
      },
      // E.g. location turned off: stop; the next tap or resume starts again.
      onError: (Object _) {
        _stop();
        notifyListeners();
      },
    );
  }

  void _stop() {
    unawaited(_updates?.cancel());
    _updates = null;
    _position = null;
  }

  /// A platform that can't answer counts as unknown.
  Future<PhoneLocationState> _ask(
    Future<PhoneLocationState> Function() question,
  ) async {
    try {
      return await question();
    } on Object {
      return PhoneLocationState.unknown;
    }
  }

  @override
  void dispose() {
    if (_maps > 0) WidgetsBinding.instance.removeObserver(this);
    _stop();
    super.dispose();
  }
}

/// Location through geolocator. Linux has no location service the app can
/// rely on, so there the map uses the radio's position.
class GeolocatorSource implements PhoneLocationSource {
  /// The oldest last-known position My location falls back to.
  static const maxAge = Duration(minutes: 2);

  @override
  bool get supported =>
      !kIsWeb &&
      switch (defaultTargetPlatform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.macOS ||
        TargetPlatform.windows => true,
        _ => false,
      };

  @override
  Future<PhoneLocationState> check() async {
    // Following with location off makes Android pop its own dialog.
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PhoneLocationState.serviceOff;
    }
    return _state(await Geolocator.checkPermission());
  }

  @override
  Future<PhoneLocationState> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return PhoneLocationState.serviceOff;
    }
    // Never asked reads as denied too.
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return _state(permission);
  }

  PhoneLocationState _state(LocationPermission p) => switch (p) {
    LocationPermission.always ||
    LocationPermission.whileInUse => PhoneLocationState.granted,
    LocationPermission.deniedForever => PhoneLocationState.deniedForever,
    LocationPermission.denied => PhoneLocationState.denied,
    LocationPermission.unableToDetermine => PhoneLocationState.unknown,
  };

  @override
  Future<LatLng?> current() async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          timeLimit: Duration(seconds: 15),
        ),
      );
      return LatLng(p.latitude, p.longitude);
    } on Object {
      try {
        final p = await Geolocator.getLastKnownPosition();
        if (p == null || DateTime.now().difference(p.timestamp) > maxAge) {
          return null;
        }
        return LatLng(p.latitude, p.longitude);
      } on Object {
        return null;
      }
    }
  }

  @override
  Stream<LatLng> positions() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(distanceFilter: 10),
  ).map((p) => LatLng(p.latitude, p.longitude));

  @override
  Future<void> openSettings() => Geolocator.openAppSettings();
}
