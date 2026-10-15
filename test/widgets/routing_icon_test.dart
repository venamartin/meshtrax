import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/services/app_settings_service.dart';
import 'package:meshtrax/storage/prefs_manager.dart';
import 'package:meshtrax/widgets/routing_dialog.dart';

// The path icon says what a send to this contact will do: Automatic (amber
// while Pathfinder chooses), always flood, direct, or a custom path. Forced
// modes were invisible on repeater screens, and an "Always flood" contact
// showed the amber Pathfinder marker.
class _Connector extends MeshCoreConnector {
  _Connector(this.contact);
  Contact contact;

  @override
  List<Contact> get contacts => [contact];
}

Contact _contact({int? override}) => Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => i + 1)),
      name: 'HILL',
      type: 2,
      pathLength: 1,
      path: Uint8List.fromList([0xA2, 0x77]),
      pathHashSize: 2,
      pathOverride: override,
      pathOverrideBytes: override == null || override <= 0
          ? null
          : Uint8List.fromList([0x33, 0x33]),
      lastSeen: DateTime(2026, 10, 14),
    );

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    PrefsManager.reset();
    await PrefsManager.initialize();
  });

  Future<Icon> pump(WidgetTester tester,
      {int? override, bool pathfinder = true}) async {
    final settings = AppSettingsService();
    await settings.loadSettings();
    await settings
        .updateSettings(settings.settings.copyWith(pathGraphEnabled: pathfinder));
    final contact = _contact(override: override);
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<MeshCoreConnector>.value(
            value: _Connector(contact)),
        ChangeNotifierProvider<AppSettingsService>.value(value: settings),
      ],
      child: MaterialApp(home: RoutingIcon(contact: contact)),
    ));
    return tester.widget<Icon>(find.byType(Icon));
  }

  testWidgets('Automatic with Pathfinder on: the amber path icon',
      (tester) async {
    final icon = await pump(tester);
    expect(icon.icon, RoutingIcon.icon);
    expect(icon.color, isNotNull);
  });

  testWidgets('Automatic with Pathfinder off: the plain path icon',
      (tester) async {
    final icon = await pump(tester, pathfinder: false);
    expect(icon.icon, RoutingIcon.icon);
    expect(icon.color, isNull);
  });

  testWidgets('forced modes show their own glyph and never amber',
      (tester) async {
    for (final (override, glyph) in [
      (-1, Icons.waves),
      (0, Icons.settings_ethernet),
      (1, Icons.route),
    ]) {
      final icon = await pump(tester, override: override);
      expect(icon.icon, glyph, reason: 'override $override');
      expect(icon.color, isNull, reason: 'override $override');
    }
  });
}
