import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../helpers/structured_message.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/repeater_command_service.dart';
import '../helpers/snack_bar_builder.dart';
import 'structured_message_card.dart';
import 'structured_message_dialogs.dart';

enum _Kind { announcement, notice, event, location }

/// Admin dialog that posts an announcement through the room server's
/// `room.post` command. The post is authored by the room itself and pushed
/// to every member, including the admin who wrote it. It can be plain text,
/// or a notice (which must expire), an event or a location, built with the
/// composer's own dialogs.
class RoomAnnouncementDialog extends StatefulWidget {
  final Contact room;

  const RoomAnnouncementDialog({super.key, required this.room});

  @override
  State<RoomAnnouncementDialog> createState() => _RoomAnnouncementDialogState();
}

class _RoomAnnouncementDialogState extends State<RoomAnnouncementDialog> {
  final TextEditingController _textController = TextEditingController();
  late final MeshCoreConnector _connector;
  late final RepeaterCommandService _service;
  StreamSubscription<Uint8List>? _frameSubscription;
  bool _isSending = false;
  _Kind _kind = _Kind.announcement;

  /// Wire text of the notice, event or location built in its dialog.
  String? _composed;

  @override
  void initState() {
    super.initState();
    _connector = context.read<MeshCoreConnector>();
    _service = RepeaterCommandService(_connector);
    _frameSubscription = _connector.receivedFrames.listen((frame) {
      if (frame.isEmpty) return;
      if (frame[0] != respCodeContactMsgRecv &&
          frame[0] != respCodeContactMsgRecvV3) {
        return;
      }
      final parsed = parseContactMessageText(frame);
      if (parsed == null) return;
      if (!_matchesRoomPrefix(parsed.senderPrefix)) return;
      _service.handleResponse(widget.room, parsed.text);
    });
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _service.dispose();
    _textController.dispose();
    super.dispose();
  }

  bool _matchesRoomPrefix(Uint8List prefix) {
    final target = widget.room.publicKey;
    if (target.length < 6 || prefix.length < 6) return false;
    for (int i = 0; i < 6; i++) {
      if (prefix[i] != target[i]) return false;
    }
    return true;
  }

  String get _text => _kind == _Kind.announcement
      ? _textController.text.trim()
      : (_composed ?? '');

  Future<void> _choose(_Kind kind) async {
    // The chip already chosen: keep what was composed.
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _composed = null;
    });
    await _composeFor(kind);
  }

  /// Opens the kind's dialog, filled in with what was composed so far.
  Future<void> _composeFor(_Kind kind) async {
    final composed = _composed;
    final current = composed == null ? null : StructuredMessage.parse(composed);
    switch (kind) {
      case _Kind.notice:
        await _compose(
          () => StructuredMessageDialogs.notice(
            context,
            requireExpiry: true,
            initial: current is NoticeMessage ? current : null,
          ),
        );
      case _Kind.event:
        await _compose(
          () => StructuredMessageDialogs.event(
            context,
            initial: current is EventMessage ? current : null,
          ),
        );
      case _Kind.announcement:
      case _Kind.location:
        break;
    }
  }

  Future<void> _compose(Future<String?> Function() build) async {
    final wire = await build();
    if (!mounted || wire == null) return;
    setState(() => _composed = wire);
  }

  Future<void> _send() async {
    final text = _text;
    if (text.isEmpty || _isSending) return;
    final limit = maxRoomAnnouncementBytes();
    if (utf8.encode(text).length > limit) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_messageTooLong(limit)),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final response = await _service.sendCommand(
        widget.room,
        '$roomPostCommand$text',
      );
      if (!mounted) return;
      final failed = response.trim().toLowerCase().startsWith('err');
      showDismissibleSnackBar(
        context,
        content: Text(
          failed ? response : context.l10n.room_announcementSent,
        ),
        backgroundColor: failed ? Colors.red : null,
      );
      if (!failed) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.room_announcementFailed),
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final kinds = [
      (_Kind.announcement, Icons.campaign, l10n.structured_announcement),
      (_Kind.notice, Icons.event_busy, l10n.structured_notice),
      (_Kind.event, Icons.event, l10n.structured_event),
      (_Kind.location, Icons.location_on, l10n.chat_location),
    ];
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.room_postAnnouncement)),
        ],
      ),
      // A set width: the dialog otherwise asks its content for an intrinsic
      // width, which a preview's map cannot answer.
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.room_postAnnouncementSubtitle,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final (kind, icon, label) in kinds)
                    ChoiceChip(
                      avatar: Icon(icon, size: 18),
                      label: Text(label),
                      selected: _kind == kind,
                      showCheckmark: false,
                      onSelected: _isSending ? null : (_) => _choose(kind),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _body(context),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton.icon(
          onPressed: _isSending || _text.isEmpty ? null : _send,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.campaign, size: 18),
          label: Text(l10n.chat_sendMessage),
        ),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final l10n = context.l10n;
    if (_kind == _Kind.announcement) {
      return TextField(
        controller: _textController,
        maxLines: 3,
        minLines: 1,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          hintText: l10n.chat_typeMessage,
        ),
        onChanged: (_) => setState(() {}),
      );
    }
    final composed = _composed;
    final message = composed == null ? null : StructuredMessage.parse(composed);
    if (message != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Only a preview: its map, links and buttons stay inert, so nothing
          // opens on top of the dialog while it waits for the room.
          IgnorePointer(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration:
                  StructuredMessageCard.bubbleDecoration(context, message),
              child: StructuredMessageCard(message: message, textScale: 1),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _isSending
                  ? null
                  : () {
                      if (_kind == _Kind.location) {
                        setState(() => _composed = null);
                      } else {
                        _composeFor(_kind);
                      }
                    },
              icon: const Icon(Icons.edit, size: 18),
              label: Text(l10n.common_edit),
            ),
          ),
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: switch (_kind) {
        _Kind.location => [
            OutlinedButton.icon(
              onPressed: () => _compose(
                () => StructuredMessageDialogs.myLocation(context, _connector),
              ),
              icon: const Icon(Icons.my_location, size: 18),
              label: Text(l10n.tray_myLocation),
            ),
            OutlinedButton.icon(
              onPressed: () =>
                  _compose(() => StructuredMessageDialogs.pointOnMap(context)),
              icon: const Icon(Icons.place, size: 18),
              label: Text(l10n.tray_pointOnMap),
            ),
          ],
        _ => [
            OutlinedButton.icon(
              onPressed: () => _composeFor(_kind),
              icon: const Icon(Icons.edit, size: 18),
              label: Text(
                _kind == _Kind.notice ? l10n.tray_notice : l10n.tray_event,
              ),
            ),
          ],
      },
    );
  }
}
