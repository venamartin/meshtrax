import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/repeater_identity.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../screens/repeater_hub_screen.dart';
import '../utils/app_logger.dart';
import 'repeater_login_dialog.dart';
import 'snr_indicator.dart';

/// Repeaters this radio hears directly, and which of them answered my
/// Discover. Only an answer carrying my request's tag marks a row as
/// answered; an advert overheard during the scan refreshes the level I
/// hear it at and nothing else, so it can never pass for an answer.
class NearbyRepeatersDialog extends StatelessWidget {
  const NearbyRepeatersDialog({super.key, required this.connector});

  final MeshCoreConnector connector;

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
          for (final r in rows) _row(context, r),
        const Divider(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.verified, size: 14, color: Colors.green),
            Text(' answered your Discover · ', style: small),
            const Icon(Icons.verified, size: 14, color: Colors.grey),
            Text(' answered before · ', style: small),
            const Icon(Icons.hearing, size: 14, color: Colors.grey),
            Text(' heard only', style: small),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          '↑ how it heard you · ↓ how you heard it · SNR in dB',
          style: small,
        ),
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
    if (answered == 0) {
      return Text(
        'No repeater answered your Discover ($ago ago). Repeaters answer at '
        'most 4 times every 2 minutes, so try again shortly.',
      );
    }
    final heard = others == 0 ? '' : ' · $others didn\'t answer';
    return Text('$answered $plural answered your Discover ($ago ago)$heard');
  }

  Widget _row(BuildContext context, DirectRepeater repeater) {
    final sf = connector.currentSf;
    final identity = RepeaterIdentityHelper.resolve(
      contacts: connector.allContacts,
      publicKey: repeater.publicKey,
      hashPrefix: repeater.pubkeyPrefix,
    );
    final contact = identity.contact;
    // A name the node put on air beats a lookup, but only when the lookup
    // found nothing — a matched contact carries the name this user chose.
    final displayName = contact == null && repeater.name?.isNotEmpty == true
        ? repeater.name!
        : identity.displayName;
    final latest = _answeredLatest(repeater);
    final answeredBefore = !latest && repeater.answeredAt != null;
    final small = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Colors.grey[600]);

    final when = latest
        ? 'answered ${formatAgo(repeater.answeredAt!)} ago'
        : 'heard ${formatAgo(repeater.lastUpdated)} ago';
    final problem = _identityProblem(repeater, identity);
    final up = repeater.uplinkSnr;

    return Material(
      color: latest ? Colors.green.withValues(alpha: 0.12) : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: identity.addressableKey == null
            ? null
            : () => _login(context, repeater, identity, displayName),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                child: Icon(
                  latest || answeredBefore ? Icons.verified : Icons.hearing,
                  size: 18,
                  color: latest ? Colors.green : Colors.grey,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (contact?.hasLocation ?? false)
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Icon(Icons.location_on, size: 14),
                          ),
                      ],
                    ),
                    Text('${repeater.prefixHex} · $when', style: small),
                    if (problem != null) Text(problem, style: small),
                  ],
                ),
              ),
              // An earlier answer's level is history, shown greyed.
              _snrCell(up, sf, dim: !latest),
              _snrCell(repeater.snr, sf),
            ],
          ),
        ),
      ),
    );
  }

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
