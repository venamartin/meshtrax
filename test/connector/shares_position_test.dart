import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/widgets/contact_tile.dart';

// The position icon means "this contact gets my position when they ask":
// base and location both allowed for them, by the radio's own setting or
// by their flags (owner, 2026-10-26).
class _Radio extends MeshCoreConnector {
  _Radio(this.base, this.loc);
  final int base, loc;
  @override
  int get telemetryModeBase => base;
  @override
  int get telemetryModeLoc => loc;
}

Contact _contact({
  int flags = 0,
  int type = advTypeChat,
  bool saved = true,
}) =>
    Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => 0x30 + i)),
      name: 'Platinum',
      type: type,
      flags: flags,
      pathLength: -1,
      path: Uint8List(0),
      pathHashSize: 1,
      lastSeen: DateTime(2026, 10, 26),
      isActive: saved,
    );

const _both = contactFlagTeleBase | contactFlagTeleLoc;

void main() {
  test('by contact flags: base and location must both be granted', () {
    final radio = _Radio(teleModeAllowFlags, teleModeAllowFlags);
    expect(radio.sharesPositionWith(_contact(flags: _both)), isTrue);
    expect(radio.sharesPositionWith(_contact(flags: contactFlagTeleLoc)),
        isFalse,
        reason: 'the radio answers nothing without base');
    expect(radio.sharesPositionWith(_contact(flags: contactFlagTeleBase)),
        isFalse);
  });

  test('Deny all wins over the flags; Allow all needs none', () {
    expect(
        _Radio(teleModeDeny, teleModeAllowFlags)
            .sharesPositionWith(_contact(flags: _both)),
        isFalse);
    expect(
        _Radio(teleModeAllowFlags, teleModeDeny)
            .sharesPositionWith(_contact(flags: _both)),
        isFalse);
    expect(
        _Radio(teleModeAllowAll, teleModeAllowAll)
            .sharesPositionWith(_contact()),
        isTrue,
        reason: 'on Allow all every contact gets it, and shows it');
    expect(
        _Radio(teleModeAllowAll, teleModeAllowFlags)
            .sharesPositionWith(_contact(flags: contactFlagTeleLoc)),
        isTrue);
  });

  test('only saved chat contacts can ask', () {
    final radio = _Radio(teleModeAllowAll, teleModeAllowAll);
    expect(radio.sharesPositionWith(_contact(type: advTypeRepeater)), isFalse);
    expect(radio.sharesPositionWith(_contact(type: advTypeRoom)), isFalse);
    expect(radio.sharesPositionWith(_contact(saved: false)), isFalse,
        reason: 'the radio cannot read a request from a contact it lacks');
  });

  testWidgets('the contact row shows the icon only when asked',
      (tester) async {
    Future<void> pump(bool shares) => tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ContactTile(
              contact: _contact(),
              lastSeen: DateTime(2026, 10, 26),
              unreadCount: 0,
              isFavorite: false,
              onTap: () {},
              onLongPress: () {},
              sharesPosition: shares,
            ),
          ),
        ));
    await pump(false);
    expect(find.byIcon(Icons.share_location), findsNothing);
    await pump(true);
    expect(find.byIcon(Icons.share_location), findsOneWidget);
    expect(find.byTooltip('Can get your position'), findsOneWidget);
  });
}
