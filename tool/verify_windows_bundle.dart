// Fails the build when a Windows release bundle is missing a native library.
//
// Nothing in `flutter build windows` complains when a native library does not
// make it into the bundle: the .exe links fine and starts fine, and the gap
// only surfaces when a user clicks the feature that needs it. Version 1.7.7
// shipped without flserial.dll and every Windows user who pressed Connect was
// told "USB serial is not supported on this platform".
//
// Run after building:
//   dart run tool/verify_windows_bundle.dart
//   dart run tool/verify_windows_bundle.dart --bundle <path-to-Release-dir>

import 'dart:io';

/// Native libraries whose absence is invisible until a user hits the feature.
const _requiredFiles = <String, String>{
  'meshtrax.exe': 'the application itself',
  'flutter_windows.dll': 'the Flutter engine',
  'flserial.dll': 'USB serial — built by flserial\'s native-assets hook',
  'sqlite3.dll': 'the message database (Drift/sqlite3)',
  'flutter_blue_plus_winrt_plugin.dll': 'Bluetooth LE',
};

const _defaultBundle = 'build/windows/x64/runner/Release';

void main(List<String> args) {
  final bundlePath = _bundleArg(args) ?? _defaultBundle;
  final bundle = Directory(bundlePath);

  if (!bundle.existsSync()) {
    _fail('No Windows bundle at $bundlePath — run "flutter build windows '
        '--release" first.');
  }

  final missing = <String>[];
  for (final entry in _requiredFiles.entries) {
    final file = File('${bundle.path}/${entry.key}');
    if (!file.existsSync() || file.lengthSync() == 0) {
      missing.add('  ${entry.key.padRight(38)} ${entry.value}');
    }
  }

  // The engine reads assets from data/; an empty one boots to a blank window.
  final assets = Directory('${bundle.path}/data/flutter_assets');
  if (!assets.existsSync()) {
    missing.add('  ${'data/flutter_assets/'.padRight(38)} bundled assets');
  }

  if (missing.isNotEmpty) {
    _fail(
      'Windows bundle at $bundlePath is incomplete — do NOT ship it.\n\n'
      'Missing:\n${missing.join('\n')}\n\n'
      'A missing native library does not fail the build; it fails in the '
      'user\'s hands. Try "flutter clean" then rebuild, and re-run this check.',
    );
  }

  stdout.writeln('Windows bundle OK: ${_requiredFiles.length} native '
      'libraries and assets present in $bundlePath');
}

String? _bundleArg(List<String> args) {
  final i = args.indexOf('--bundle');
  if (i >= 0 && i + 1 < args.length) return args[i + 1];
  return null;
}

Never _fail(String message) {
  stderr.writeln('\n$message\n');
  exit(1);
}
