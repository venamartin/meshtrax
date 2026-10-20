import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../models/contact.dart';
import '../services/repeater_command_service.dart';
import '../helpers/snack_bar_builder.dart';

/// Admin dialog that posts an announcement through the room server's
/// `room.post` command. The post is authored by the room itself and pushed
/// to every member, including the admin who wrote it.
class RoomAnnouncementDialog extends StatefulWidget {
  final Contact room;

  /// Prepended to the posted text, e.g. `Notice: ` so the post renders as a
  /// notice card in MeshTrax while staying plain text elsewhere.
  final String textPrefix;

  const RoomAnnouncementDialog({
    super.key,
    required this.room,
    this.textPrefix = '',
  });

  @override
  State<RoomAnnouncementDialog> createState() => _RoomAnnouncementDialogState();
}

class _RoomAnnouncementDialogState extends State<RoomAnnouncementDialog> {
  final TextEditingController _textController = TextEditingController();
  late final MeshCoreConnector _connector;
  late final RepeaterCommandService _service;
  StreamSubscription<Uint8List>? _frameSubscription;
  bool _isSending = false;

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

  Future<void> _send() async {
    final body = _textController.text.trim();
    if (body.isEmpty || _isSending) return;
    final text = '${widget.textPrefix}$body';
    if (utf8.encode(text).length > maxRoomPostTextBytes) {
      showDismissibleSnackBar(
        context,
        content: Text(context.l10n.chat_messageTooLong(maxRoomPostTextBytes)),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final response = await _service.sendCommand(
        widget.room,
        'room.post $text',
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
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.campaign, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(l10n.room_postAnnouncement)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.room_postAnnouncementSubtitle,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 3,
            minLines: 1,
            autofocus: true,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: l10n.chat_typeMessage,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.common_cancel),
        ),
        FilledButton.icon(
          onPressed: _isSending ? null : _send,
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
}
