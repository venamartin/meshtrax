import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../connector/meshcore_protocol.dart';

/// Debug widget to show the hex dump of a frame
class DebugFrameViewer {
  static void showFrameDebug(
    BuildContext context,
    Uint8List frame,
    String title,
  ) {
    final hexString = frame
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join(' ');

    final details = StringBuffer();
    details.writeln(context.l10n.debugFrame_length(frame.length));
    details.writeln('');
    details.writeln(
      context.l10n.debugFrame_command(
        frame[0].toRadixString(16).padLeft(2, '0'),
      ),
    );

    // CMD_SEND_TXT_MSG: [cmd][txt_type][attempt][timestamp x4][prefix x6][text]
    if (frame[0] == cmdSendTxtMsg && frame.length >= 13) {
      details.writeln('');
      details.writeln(context.l10n.debugFrame_textMessageHeader);
      details.writeln(
        context.l10n.debugFrame_destinationPubKey(
          pubKeyToHex(frame.sublist(7, 13)),
        ),
      );
      details.writeln(
        context.l10n.debugFrame_timestamp(readUint32LE(frame, 3)),
      );
      final txtType = frame[1];
      final typeLabel = switch (txtType) {
        txtTypeCliData => context.l10n.debugFrame_textTypeCli,
        txtTypeCliCommand => context.l10n.debugFrame_textTypeCliCommand,
        _ => context.l10n.debugFrame_textTypePlain,
      };
      details.writeln(context.l10n.debugFrame_textType(txtType, typeLabel));
      final textBytes = frame.sublist(13);
      final nullIdx = textBytes.indexOf(0);
      final text = utf8.decode(
        nullIdx >= 0 ? textBytes.sublist(0, nullIdx) : textBytes,
        allowMalformed: true,
      );
      details.writeln(context.l10n.debugFrame_text(text));
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                details.toString(),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
              const Divider(),
              Text(
                context.l10n.debugFrame_hexDump,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                hexString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.common_close),
          ),
        ],
      ),
    );
  }
}
