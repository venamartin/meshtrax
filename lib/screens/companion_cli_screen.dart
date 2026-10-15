import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../l10n/l10n.dart';
import '../services/companion_cli_service.dart';
import '../widgets/cli_console.dart';

/// Text command line for the connected radio (firmware 1.18+).
class CompanionCliScreen extends StatelessWidget {
  const CompanionCliScreen({super.key});

  Future<String> _send(BuildContext context, String command) async {
    final l10n = context.l10n;
    final connector = context.read<MeshCoreConnector>();
    // CMD_REBOOT flushes pending contact writes first; the CLI reboot
    // doesn't. Neither answers.
    if (command == 'reboot') {
      await connector.rebootDevice();
      return l10n.companionCli_rebooting;
    }
    if (command == 'poweroff' || command == 'shutdown') {
      if (!await _confirmPowerOff(context)) return l10n.companionCli_cancelled;
      await connector.companionCli.sendWithoutReply(command);
      return l10n.companionCli_poweringOff;
    }
    try {
      final reply = await connector.companionCli.run(command);
      final kind = CliReply(reply).kind;
      // A CLI write changes what DEVICE_INFO / SELF_INFO report, and the
      // radio sends no push for it.
      if (command.startsWith('set ') &&
          (kind == CliReplyKind.ok || kind == CliReplyKind.value)) {
        unawaited(connector.refreshDeviceInfo());
      }
      return reply;
    } on TimeoutException {
      return l10n.companionCli_noReply;
    }
  }

  Future<bool> _confirmPowerOff(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.companionCli_powerOffTitle),
        content: Text(l10n.companionCli_powerOffBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.companionCli_powerOff),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final connector = context.watch<MeshCoreConnector>();
    final hasWifi = connector.hasWifi == true;

    return CliConsole(
      title: l10n.companionCli_title,
      subtitle: connector.selfName ?? '',
      onSend: (command) => _send(context, command),
      debugFrameFor: buildRunCliCommandFrame,
      quickCommands: [
        CliQuickCommand(l10n.repeater_cliQuickVersion, 'ver'),
        CliQuickCommand(l10n.companionCli_quickBoard, 'board'),
        CliQuickCommand(l10n.repeater_cliQuickGetName, 'get name'),
        CliQuickCommand(l10n.repeater_cliQuickGetRadio, 'get radio'),
        CliQuickCommand(l10n.repeater_cliQuickGetTx, 'get tx'),
        if (hasWifi) ...[
          CliQuickCommand(l10n.companionCli_quickWifiStatus, 'get wifi.status'),
          CliQuickCommand(l10n.companionCli_quickWifiAddress, 'get wifi.ip'),
        ],
      ],
      helpNote: l10n.repeater_commandsListNote,
      helpSections: (context) => _helpSections(context, hasWifi: hasWifi),
    );
  }

  List<CliHelpSection> _helpSections(
    BuildContext context, {
    required bool hasWifi,
  }) {
    final l10n = context.l10n;
    return [
      CliHelpSection(l10n.repeater_general, [
        CliHelpEntry(command: 'ver', description: l10n.repeater_cliHelpVersion),
        CliHelpEntry(
          command: 'board',
          description: l10n.companionCli_helpBoard,
        ),
        CliHelpEntry(
          command: 'reboot',
          description: l10n.companionCli_helpReboot,
        ),
        CliHelpEntry(
          command: 'poweroff',
          description: l10n.companionCli_helpPowerOff,
        ),
        CliHelpEntry(
          command: 'set name {name}',
          description: l10n.repeater_cliHelpSetName,
        ),
        CliHelpEntry(
          command: 'set pin {6 digits}',
          description: l10n.companionCli_helpSetPin,
        ),
        CliHelpEntry(
          command: 'set tz.offset {hours}',
          description: l10n.companionCli_helpSetTzOffset,
        ),
      ]),
      CliHelpSection(l10n.repeater_settingsCategory, [
        CliHelpEntry(
          command: 'set radio {freq},{bw},{sf},{cr}',
          description: l10n.repeater_cliHelpSetRadio,
        ),
        CliHelpEntry(
          command: 'set tx {dbm}',
          description: l10n.companionCli_helpSetTx,
        ),
        CliHelpEntry(
          command: 'set af {air-time-factor}',
          description: l10n.repeater_cliHelpSetAf,
        ),
        CliHelpEntry(
          command: 'set rxdelay {0-20}',
          description: l10n.repeater_cliHelpSetRxDelay,
        ),
        CliHelpEntry(
          command: 'set txdelay {0-2}',
          description: l10n.repeater_cliHelpSetTxDelay,
        ),
        CliHelpEntry(
          command: 'set direct.txdelay {0-2}',
          description: l10n.repeater_cliHelpSetDirectTxDelay,
        ),
        CliHelpEntry(
          command: 'set int.thresh {db}',
          description: l10n.companionCli_helpSetIntThresh,
        ),
        CliHelpEntry(
          command: 'set agc.reset.interval {seconds}',
          description: l10n.repeater_cliHelpSetAgcResetInterval,
        ),
        CliHelpEntry(
          command: 'set cad {on|off}',
          description: l10n.companionCli_helpSetCad,
        ),
        CliHelpEntry(
          command: 'set radio.rxgain {on|off}',
          description: l10n.companionCli_helpSetRxGain,
        ),
        CliHelpEntry(
          command: 'set multi.acks {0|1}',
          description: l10n.repeater_cliHelpSetMultiAcks,
        ),
        CliHelpEntry(
          command: 'set path.hash.mode {0|1|2}',
          description: l10n.companionCli_helpSetPathHashMode,
        ),
      ]),
      if (hasWifi)
        CliHelpSection(l10n.wifi_title, [
          CliHelpEntry(
            command: 'get wifi.status',
            description: l10n.companionCli_helpWifiStatus,
          ),
          CliHelpEntry(
            command: 'get wifi.ip',
            description: l10n.companionCli_helpWifiIp,
          ),
          CliHelpEntry(
            command: 'set wifi.ssid {name}',
            description: l10n.companionCli_helpWifiSsid,
          ),
          CliHelpEntry(
            command: 'set wifi.pwd {password}',
            description: l10n.companionCli_helpWifiPwd,
          ),
          CliHelpEntry(
            command: 'set wifi.enabled {0|1}',
            description: l10n.companionCli_helpWifiEnabled,
          ),
          CliHelpEntry(
            command: 'set wifi.clear',
            description: l10n.companionCli_helpWifiClear,
          ),
        ]),
    ];
  }
}
