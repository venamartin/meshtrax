import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/geo_format.dart';
import '../helpers/repeater_identity.dart';
import '../l10n/l10n.dart';
import '../models/app_settings.dart';
import '../models/contact.dart';
import '../services/app_settings_service.dart';
import '../screens/repeater_hub_screen.dart';
import '../utils/app_logger.dart';
import 'repeater_login_dialog.dart';
import 'snr_indicator.dart';

/// Repeaters this radio hears directly, and which of them answered my
/// Discover. Only an answer carrying my request's tag marks a row as
/// answered; an advert overheard during the scan refreshes the level I
/// hear it at and nothing else, so it can never pass for an answer.
class NearbyRepeatersDialog extends StatefulWidget {
  const NearbyRepeatersDialog({super.key, required this.connector});

  final MeshCoreConnector connector;

  @override
  State<NearbyRepeatersDialog> createState() => _NearbyRepeatersDialogState();
}

class _NearbyRepeatersDialogState extends State<NearbyRepeatersDialog> {
  /// Rows opened to list every contact their shared code could be.
  final _expanded = <DirectRepeater>{};

  MeshCoreConnector get connector => widget.connector;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      // The whole body scrolls, so a short screen (a phone on its side)
      // never overflows.
      scrollable: true,
      title: Text(context.l10n.snrIndicator_nearByRepeaters),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<void>(
            stream: Stream.periodic(const Duration(seconds: 1)),
            builder: (context, _) => ListenableBuilder(
              listenable: connector,
              builder: (context, _) {
                final sw = Stopwatch()..start();
                final body = _body(context);
                appLogger.perf('nearby repeaters dialog build', sw);
                return body;
              },
            ),
          ),
        ),
      ),
      actions: [
        ListenableBuilder(
          listenable: connector,
          builder: (context, _) => ElevatedButton.icon(
            onPressed: connector.isDiscovering
                ? null
                : () => connector.sendRepeaterDiscovery(),
            icon: connector.isDiscovering
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.radar),
            label: Text(connector.isDiscovering ? 'Listening...' : 'Discover'),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.l10n.common_close),
        ),
      ],
    );
  }

  bool _answeredLatest(DirectRepeater r) =>
      connector.discoverScan > 0 && r.answeredScan == connector.discoverScan;

  Widget _body(BuildContext context) {
    final answered = connector.directRepeaters.where(_answeredLatest).toList()
      ..sort((a, b) => b.uplinkSnr!.compareTo(a.uplinkSnr!));
    final others =
        connector.directRepeaters.where((r) => !_answeredLatest(r)).toList()
          ..sort(DirectRepeater.compare);
    final rows = [...answered, ...others];
    // Once per rebuild (every second), not once per row.
    final contacts = connector.allContacts;
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Colors.grey[600], fontWeight: FontWeight.w500);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Only rows that were there to be asked can have not answered.
        _status(context, answered.length,
            others.where(connector.wasAskedByLatestDiscover).length),
        const SizedBox(height: 12),
        Row(
          children: [
            const SizedBox(width: 28),
            Expanded(child: Text('Repeater', style: small)),
            _cell('↑ Up', style: small),
            _cell('↓ Down', style: small),
          ],
        ),
        const Divider(height: 12),
        if (rows.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              connector.isDiscovering
                  ? 'Waiting for answers...'
                  : 'No repeaters heard yet.',
              textAlign: TextAlign.center,
            ),
          )
        else
          for (final r in rows) _row(context, r, contacts),
        const Divider(height: 12),
        _legend(small),
      ],
    );
  }

  /// One key per line, each icon in the rows' icon column (owner,
  /// 2026-10-26: the wrapped legend broke a key onto a line of its own).
  Widget _legend(TextStyle? small) {
    Widget line(Widget? icon, String text) => Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 28, child: icon),
              Expanded(child: Text(text, style: small)),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line(const Icon(Icons.verified, size: 14, color: Colors.green),
            'answered your Discover'),
        line(const Icon(Icons.verified, size: 14, color: Colors.grey),
            'answered before'),
        line(const Icon(Icons.hearing, size: 14, color: Colors.grey),
            'heard only'),
        line(
          _guessIcon(14),
          'heard by a code several contacts share: the name in italics is '
          'the nearest of them; tap the row for all',
        ),
        line(null, '↑ how it heard you · ↓ how you heard it · SNR in dB'),
      ],
    );
  }

  Widget _status(BuildContext context, int answered, int others) {
    final startedAt = connector.discoverStartedAt;
    final plural = answered == 1 ? 'repeater' : 'repeaters';
    if (connector.isDiscovering && startedAt != null) {
      final elapsed = DateTime.now().difference(startedAt);
      final progress =
          (elapsed.inMilliseconds /
                  MeshCoreConnector.discoverWindow.inMilliseconds)
              .clamp(0.0, 1.0);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            answered == 0
                ? 'Asking the repeaters that can hear you...'
                : '$answered $plural answered so far...',
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
      );
    }
    if (startedAt == null) {
      return const Text(
        'Tap Discover to ask which repeaters can hear you right now.',
      );
    }
    final ago = formatAgo(startedAt);
    final whose = connector.lastDiscoverAutomatic
        ? 'the Discover Pathfinder sent'
        : 'your Discover';
    if (answered == 0) {
      return Text(
        'No repeater answered $whose ($ago ago). Repeaters answer at '
        'most 4 times every 2 minutes, so try again shortly.',
      );
    }
    final heard = others == 0 ? '' : ' · $others didn\'t answer';
    return Text('$answered $plural answered $whose ($ago ago)$heard');
  }

  Widget _row(
    BuildContext context,
    DirectRepeater repeater,
    List<Contact> contacts,
  ) {
    final sf = connector.currentSf;
    final identity = RepeaterIdentityHelper.resolve(
      contacts: contacts,
      publicKey: repeater.publicKey,
      hashPrefix: repeater.pubkeyPrefix,
    );
    final contact = identity.contact;
    final onAir = contact == null && repeater.name?.isNotEmpty == true;
    // A short code several contacts share: the nearest is the likeliest.
    final shared = !onAir && identity.isAmbiguous;
    final guess = shared ? _nearestGuess(identity) : null;
    // A name the node put on air beats a lookup, but only when the lookup
    // found nothing — a matched contact carries the name this user chose.
    final displayName =
        onAir ? repeater.name! : guess?.contact.name ?? identity.displayName;
    final latest = _answeredLatest(repeater);
    final answeredBefore = !latest && repeater.answeredAt != null;
    final expanded = shared && _expanded.contains(repeater);
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Colors.grey[600]);

    final code = repeater.prefixHex;
    final when = latest
        ? 'answered ${formatAgo(repeater.answeredAt!)} ago'
        : 'heard ${formatAgo(repeater.lastUpdated)} ago';
    final problem = shared
        ? [
            '${identity.candidates.length} share $code',
            if (guess != null)
              'nearest '
                  '${GeoFormat.distanceText(guess.meters, _units(context))}',
          ].join(' · ')
        : _identityProblem(repeater, identity);
    final up = repeater.uplinkSnr;

    return Material(
      // Keeps a press on the row pressed when the list re-sorts under it.
      key: ObjectKey(repeater),
      color: latest ? Colors.green.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        // A shared code opens to show the contacts it could be; a guess is
        // never logged into.
        onTap: shared
            ? () => setState(() => expanded
                ? _expanded.remove(repeater)
                : _expanded.add(repeater))
            : identity.addressableKey == null
                ? null
                : () => _login(context, repeater, identity, displayName),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The name has the row's whole width, the levels sit on the
              // line below (owner, 2026-10-26: names were cut off).
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 28,
                    child: latest || answeredBefore
                        ? Icon(
                            Icons.verified,
                            size: 18,
                            color: latest ? Colors.green : Colors.grey,
                          )
                        : shared
                            ? _guessIcon(18)
                            : const Icon(
                                Icons.hearing,
                                size: 18,
                                color: Colors.grey,
                              ),
                  ),
                  Flexible(
                    child: Text(
                      displayName,
                      // A name shows whole at any text size; only the list
                      // of candidates (the row opens to show them) is cut.
                      maxLines: shared && guess == null ? 2 : null,
                      overflow: shared && guess == null
                          ? TextOverflow.ellipsis
                          : null,
                      style: guess == null
                          ? null
                          : const TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                  if (contact?.hasLocation ?? false)
                    const Padding(
                      padding: EdgeInsets.only(left: 4, top: 2),
                      child: Icon(Icons.location_on, size: 14),
                    ),
                ],
              ),
              Row(
                children: [
                  const SizedBox(width: 28),
                  Expanded(child: Text('$code · $when', style: small)),
                  // An earlier answer's level is history, shown greyed.
                  _snrCell(up, sf, dim: !latest),
                  _snrCell(repeater.snr, sf),
                ],
              ),
              if (problem != null)
                Row(
                  children: [
                    const SizedBox(width: 28),
                    Expanded(child: Text(problem, style: small)),
                    if (shared)
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Colors.grey,
                      ),
                  ],
                ),
              if (expanded) _candidates(context, identity.candidates, small),
            ],
          ),
        ),
      ),
    );
  }

  /// Every contact a shared code could be, nearest first. Display only,
  /// like the guess: none of them is logged into from here.
  Widget _candidates(
    BuildContext context,
    List<Contact> candidates,
    TextStyle? small,
  ) {
    final from = _selfPosition();
    final units = _units(context);
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final c in RepeaterIdentityHelper.byDistance(candidates, from))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(c.contact.name, style: small)),
                  // Without our own position there is no distance to give.
                  if (from != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      c.meters == null
                          ? 'no position'
                          : GeoFormat.distanceText(c.meters!, units),
                      style: small,
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// The ear with a small "?": heard only, by a code several contacts
  /// share, so the name is a guess (owner, 2026-10-26).
  static Widget _guessIcon(double size) => Center(
        child: SizedBox.square(
          dimension: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(Icons.hearing, size: size, color: Colors.grey),
              Positioned(
                top: -size / 3,
                right: -size / 3,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.question_mark,
                    size: size * 0.55,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

  LatLng? _selfPosition() {
    final lat = connector.selfLatitude;
    final lon = connector.selfLongitude;
    return GeoFormat.isValidPosition(lat, lon) ? LatLng(lat!, lon!) : null;
  }

  /// Display only: a guess is never logged into, nor taught to Pathfinder.
  ({Contact contact, double meters})? _nearestGuess(RepeaterIdentity identity) {
    final from = _selfPosition();
    if (from == null) return null;
    return RepeaterIdentityHelper.nearestCandidate(identity.candidates, from);
  }

  static UnitSystem _units(BuildContext context) =>
      context.read<AppSettingsService?>()?.settings.unitSystem ??
      UnitSystem.metric;

  /// Why a row cannot be logged into, or null when it can and is known.
  String? _identityProblem(DirectRepeater repeater, RepeaterIdentity identity) {
    if (identity.addressableKey != null) {
      return identity.isUnknownContact ? 'Not in contacts' : null;
    }
    if (identity.isAmbiguous) {
      return '${identity.candidates.length} contacts share this code — '
          'cannot tell which';
    }
    return 'Only its code is known — Discover to log in';
  }

  static Widget _cell(String text, {TextStyle? style}) => SizedBox(
    width: 64,
    child: Text(text, textAlign: TextAlign.center, style: style),
  );

  static Widget _snrCell(double? snr, int? sf, {bool dim = false}) {
    if (snr == null) {
      return _cell('—', style: const TextStyle(color: Colors.grey));
    }
    final ui = snrUiFromSNR(snr, sf);
    return _cell(
      snr.toStringAsFixed(1),
      style: TextStyle(
        color: dim ? Colors.grey : ui.color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _login(
    BuildContext context,
    DirectRepeater repeater,
    RepeaterIdentity identity,
    String displayName,
  ) async {
    final navigator = Navigator.of(context);
    Contact? loginContact = identity.contact;
    if (loginContact != null) {
      // pathBytes: without it the previous override bytes survive and the
      // device is never told.
      await connector.setPathOverride(
        loginContact,
        pathLen: 0,
        pathBytes: Uint8List(0),
      );
      final idx = connector.contacts.indexWhere(
        (c) => c.publicKeyHex == loginContact!.publicKeyHex,
      );
      if (idx >= 0) loginContact = connector.contacts[idx];
    } else {
      loginContact = Contact(
        publicKey: identity.addressableKey!,
        name: displayName,
        type: advTypeRepeater,
        pathLength: -1,
        path: Uint8List(0),
        pathHashSize: connector.pathHashByteWidth,
        lastSeen: DateTime.now(),
        pathOverride: 0,
      );
    }
    if (!context.mounted) return;
    final target = loginContact;
    showDialog(
      context: context,
      builder: (_) => RepeaterLoginDialog(
        repeater: target,
        onLogin: (password, isAdmin) {
          navigator.pop(); // this dialog
          navigator.push(
            MaterialPageRoute(
              builder: (_) => RepeaterHubScreen(
                repeater: target,
                password: password,
                isAdmin: isAdmin,
              ),
            ),
          );
        },
      ),
    );
  }
}
