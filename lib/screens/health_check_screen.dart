import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../connector/meshcore_connector.dart';
import '../health/health_check.dart';
import '../health/health_rules.dart';
import '../helpers/snack_bar_builder.dart';
import '../l10n/l10n.dart';
import '../services/app_settings_service.dart';
import '../widgets/app_bar.dart';

class HealthCheckScreen extends StatefulWidget {
  /// Opens the existing screen a [HealthFix.ask] rule points at.
  final Future<void> Function(BuildContext context, HealthDialog dialog)
  openDialog;

  /// Null runs the real rule list.
  final List<HealthRule>? rules;

  /// Time for the radio's replies to arrive after asking for fresh values.
  final Duration radioReplyWait;

  const HealthCheckScreen({
    super.key,
    required this.openDialog,
    this.rules,
    this.radioReplyWait = const Duration(seconds: 1),
  });

  @override
  State<HealthCheckScreen> createState() => _HealthCheckScreenState();
}

class _HealthCheckScreenState extends State<HealthCheckScreen> {
  HealthReport? _report;
  bool _running = false;

  HealthContext get _ctx => HealthContext(
    context.read<MeshCoreConnector>(),
    context.read<AppSettingsService>(),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (_running || !mounted) return;
    setState(() => _running = true);
    final ctx = _ctx;
    if (ctx.radioConnected) {
      try {
        await ctx.connector.refreshDeviceInfo();
        await Future<void>.delayed(widget.radioReplyWait);
      } catch (_) {
        // The radio dropped; the report below says it was not checked.
      }
    }
    final report = await runHealthCheck(ctx, rules: widget.rules);
    if (!mounted) return;
    setState(() {
      _report = report;
      _running = false;
    });
  }

  Future<void> _fix(HealthRule rule) async {
    if (rule.fix == HealthFix.ask) {
      await widget.openDialog(context, rule.dialog!);
      await _run();
      return;
    }
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(rule.title),
        content: Text(rule.fixDescription),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.healthCheck_fix),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await rule.apply!(_ctx);
    } catch (_) {
      if (mounted) {
        showDismissibleSnackBar(
          context,
          content: Text(l10n.healthCheck_fixFailed),
        );
      }
    }
    await _run();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final report = _report;
    return Scaffold(
      appBar: AppBar(
        title: AppBarTitle(
          l10n.healthCheck_title,
          indicators: false,
          subtitle: false,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: l10n.healthCheck_runAgain,
            onPressed: _running ? null : _run,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _running || report == null
            ? _buildRunning(context)
            : Consumer<MeshCoreConnector>(
                builder: (context, connector, _) =>
                    _buildReport(context, report, connector),
              ),
      ),
    );
  }

  Widget _buildRunning(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(context.l10n.healthCheck_running),
        ],
      ),
    );
  }

  Widget _buildReport(
    BuildContext context,
    HealthReport report,
    MeshCoreConnector connector,
  ) {
    final l10n = context.l10n;
    final textTheme = Theme.of(context).textTheme;
    final sections = {
      HealthSeverity.problem: l10n.healthCheck_problems,
      HealthSeverity.suggestion: l10n.healthCheck_suggestions,
      HealthSeverity.tip: l10n.healthCheck_tips,
    };
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (report.radioSkipped) ...[
          Card(
            child: ListTile(
              leading: const Icon(Icons.bluetooth_disabled),
              title: Text(l10n.healthCheck_noRadio),
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (report.findings.isEmpty)
          Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(l10n.healthCheck_allClear),
            ),
          ),
        for (final section in sections.entries) ...[
          if (report.findings.any((r) => r.severity == section.key))
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
              child: Text(section.value, style: textTheme.titleMedium),
            ),
          for (final rule in report.findings.where(
            (r) => r.severity == section.key,
          ))
            _buildFinding(context, rule, connector),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 0),
          child: Text(
            l10n.healthCheck_passed(report.passed),
            style: textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildFinding(
    BuildContext context,
    HealthRule rule,
    MeshCoreConnector connector,
  ) {
    final ctx = _ctx;
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (rule.severity) {
      HealthSeverity.problem => (Icons.error_outline, colors.error),
      HealthSeverity.suggestion => (Icons.warning_amber, Colors.amber.shade800),
      HealthSeverity.tip => (Icons.lightbulb_outline, colors.onSurfaceVariant),
    };
    final showFix = rule.fix != null && (rule.canFix?.call(ctx) ?? true);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(rule.why),
            for (final line in rule.details?.call(ctx) ?? const <String>[])
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(line),
              ),
            if (showFix)
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: FilledButton.tonal(
                    onPressed: rule.needsRadio && !connector.isConnected
                        ? null
                        : () => _fix(rule),
                    child: Text(context.l10n.healthCheck_fix),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
