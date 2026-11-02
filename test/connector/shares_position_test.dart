import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshtrax/connector/meshcore_connector.dart';
import 'package:meshtrax/connector/meshcore_protocol.dart';
import 'package:meshtrax/l10n/app_localizations.dart';
import 'package:meshtrax/models/contact.dart';
import 'package:meshtrax/widgets/contact_tile.dart';
import 'package:meshtrax/widgets/unread_badge.dart';

// The position icon means "this contact gets my position when they ask":
// base and location both allowed for them, by the radio's own setting or
// by their flags (owner, 2026-10-26), and the radio has a position to give
// (owner, 2026-10-27: what actually goes out).
class _Radio extends MeshCoreConnector {
  _Radio(
    this.base,
    this.loc, {
    this.env = teleModeDeny,
    this.advert = 0,
    this.lat,
    this.lon,
    this.saved = const [],
  });
  final int base, loc, env, advert;
  final double? lat, lon;
  final List<Contact> saved;
  @override
  int get telemetryModeBase => base;
  @override
  int get telemetryModeLoc => loc;
  @override
  int get telemetryModeEnv => env;
  @override
  int get advertLocationPolicy => advert;
  @override
  double? get selfLatitude => lat;
  @override
  double? get selfLongitude => lon;
  @override
  List<Contact> get contacts => saved;
}

Contact _contact({
  int flags = 0,
  int type = advTypeChat,
  bool saved = true,
  String name = 'Platinum',
  int seed = 0x30,
}) =>
    Contact(
      publicKey: Uint8List.fromList(List.generate(32, (i) => seed + i)),
      name: name,
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

  test('location and environment ride on base', () {
    final radio = _Radio(teleModeAllowFlags, teleModeAllowAll,
        env: teleModeAllowAll);
    expect(radio.telemetryGrantedTo(_contact()),
        (base: false, location: false, environment: false));
    expect(radio.telemetryGrantedTo(_contact(flags: contactFlagTeleBase)),
        (base: true, location: true, environment: true));
    expect(
        radio.telemetryGrantedTo(_contact(type: advTypeRepeater)),
        (base: false, location: false, environment: false));
  });

  group('who sees my position now', () {
    test('nothing goes out while the radio has no position', () {
      final radio = _Radio(teleModeAllowAll, teleModeAllowAll,
          advert: 1, saved: [_contact()]);
      expect(radio.hasSelfPosition, isFalse);
      expect(radio.advertsSharePosition, isFalse);
      expect(radio.positionVisibleTo(_contact()), isFalse);
      expect(radio.positionVisible, isFalse);
      expect(radio.sharesPositionWith(_contact()), isTrue,
          reason: 'still allowed: it goes out once the radio has one');
    });

    test('adverts show it to everyone', () {
      final radio = _Radio(teleModeDeny, teleModeDeny,
          advert: 1, lat: 36.6, lon: -121.9);
      expect(radio.advertsSharePosition, isTrue);
      expect(radio.positionVisible, isTrue);
    });

    test('a contact allowed by flags sees it, with the GPS off', () {
      final flagged = _contact(name: 'Flagged', seed: 0x10, flags: _both);
      final other =
          _contact(name: 'Other', seed: 0x50, flags: contactFlagTeleBase);
      _Radio radio(int loc, List<Contact> saved) => _Radio(
          teleModeAllowFlags, loc,
          lat: 36.6, lon: -121.9, saved: saved);

      final both = radio(teleModeAllowFlags, [other, flagged]);
      expect(both.gpsOn, isFalse);
      expect(both.positionVisibleTo(flagged), isTrue,
          reason: 'boards with their own GPS code answer with it off');
      expect(both.positionVisibleTo(other), isFalse);
      expect(both.positionVisible, isTrue);
      expect(radio(teleModeAllowFlags, [other]).positionVisible, isFalse);
      expect(radio(teleModeDeny, [flagged]).positionVisible, isFalse);
    });
  });

  testWidgets('the contact row shows the icon only when asked, left of '
      'the unread count', (tester) async {
    Future<void> pump(bool shares) => tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: ContactTile(
              contact: _contact(),
              lastSeen: DateTime(2026, 10, 26),
              unreadCount: 3,
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
    final icon = tester.getCenter(find.byIcon(Icons.share_location));
    final badge = tester.getCenter(find.byType(UnreadBadge));
    expect(icon.dx, lessThan(badge.dx));
    expect(icon.dy, greaterThan(tester.getCenter(find.text('Platinum')).dy),
        reason: 'on the line under the name');
  });
}
