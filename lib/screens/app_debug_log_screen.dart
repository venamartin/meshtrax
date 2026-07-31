import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../services/app_debug_log_service.dart';
import '../utils/debug_log_export.dart';
import '../widgets/adaptive_app_bar_title.dart';
import '../helpers/snack_bar_builder.dart';

class AppDebugLogScreen extends StatefulWidget {
  const AppDebugLogScreen({super.key});

  @override
  State<AppDebugLogScreen> createState() => _AppDebugLogScreenState();
}

class _AppDebugLogScreenState extends State<AppDebugLogScreen> {
  AppDebugLogLevel _minLevel = AppDebugLogLevel.info;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppDebugLogService>(
      builder: (context, logService, _) {
        final filtered = logService.entriesAtOrAbove(_minLevel);
        final entries = filtered.reversed.toList();
        final hasEntries = entries.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: AdaptiveAppBarTitle(context.l10n.debugLog_appTitle),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: context.l10n.debugLog_saveLog,
                icon: const Icon(Icons.save_alt),
                onPressed: hasEntries
                    ? () async {
                        final path = await DebugLogExport.saveToFile(filtered);
                        if (!context.mounted) return;
                        showDismissibleSnackBar(
                          context,
                          content: Text(
                            path != null
                                ? context.l10n.debugLog_saved
                                : context.l10n.debugLog_saveCancelled,
                          ),
                        );
                      }
                    : null,
              ),
              IconButton(
                tooltip: context.l10n.debugLog_copyLog,
                icon: const Icon(Icons.copy),
                onPressed: hasEntries
                    ? () async {
                        final text =
                            AppDebugLogService.buildExportText(filtered);
                        await Clipboard.setData(ClipboardData(text: text));
                        if (!context.mounted) return;
                        showDismissibleSnackBar(
                          context,
                          content: Text(context.l10n.debugLog_copied),
                        );
                      }
                    : null,
              ),
              IconButton(
                tooltip: context.l10n.debugLog_clearLog,
                icon: const Icon(Icons.delete_outline),
                onPressed: logService.entries.isNotEmpty
                    ? () {
                        logService.clear();
                      }
                    : null,
              ),
            ],
          ),
          body: SafeArea(
            top: false,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SegmentedButton<AppDebugLogLevel>(
                    segments: [
                      ButtonSegment(
                        value: AppDebugLogLevel.info,
                        label: Text(context.l10n.debugLog_filterAll),
                      ),
                      ButtonSegment(
                        value: AppDebugLogLevel.warning,
                        label: Text(context.l10n.debugLog_filterWarnings),
                      ),
                      ButtonSegment(
                        value: AppDebugLogLevel.error,
                        label: Text(context.l10n.debugLog_filterErrors),
                      ),
                    ],
                    selected: {_minLevel},
                    showSelectedIcon: false,
                    onSelectionChanged: (selection) {
                      setState(() => _minLevel = selection.first);
                    },
                  ),
                ),
                Expanded(
                  child: hasEntries
                      ? ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return ListTile(
                              dense: true,
                              leading: _buildLevelIcon(entry.level),
                              title: Text(
                                '[${entry.tag}] ${entry.message}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              subtitle: Text(
                                entry.formattedDateTime,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.bug_report_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                context.l10n.debugLog_noEntries,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.debugLog_enableInSettings,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLevelIcon(AppDebugLogLevel level) {
    switch (level) {
      case AppDebugLogLevel.info:
        return const Icon(Icons.info_outline, size: 18, color: Colors.blue);
      case AppDebugLogLevel.warning:
        return const Icon(
          Icons.warning_amber_outlined,
          size: 18,
          color: Colors.orange,
        );
      case AppDebugLogLevel.error:
        return const Icon(Icons.error_outline, size: 18, color: Colors.red);
    }
  }
}
