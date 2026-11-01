import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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

  const HealthCheckScreen({super.key, required this.openDialog, this.rules});

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

  /// Asks the radio for its current values, then judges them.
  Future<void> _run() async {
    if (_running || !mounted) return;
    setState(() => _running = true);
    final ctx = _ctx;
    if (ctx.radioConnected) {
      try {
        await ctx.connector.refreshDeviceInfoAndWait();
      } catch (_) {
        // The radio dropped; the report below says it was not checked.
      }
    }
    if (!mounted) return;
    await _judge();
    if (mounted) setState(() => _running = false);
  }

  Future<void> _judge() async {
    final report = await runHealthCheck(_ctx, rules: widget.rules);
    if (mounted) setState(() => _report = report);
  }

  /// Findings Fix can change straight away, with nothing to type.
  List<HealthRule> _autoFixable(
    HealthReport report,
    MeshCoreConnector connector,
  ) {
    final ctx = _ctx;
    return [
      for (final rule in report.findings)
        if (rule.fix == HealthFix.apply &&
            (rule.canFix?.call(ctx) ?? true) &&
            (!rule.needsRadio || connector.isConnected))
          rule,
    ];
  }

  Future<bool> _confirm(String title, Widget content, String action) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(child: content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true && mounted;
  }

  /// Applies each rule in turn; one failing does not stop the others.
  Future<void> _apply(List<HealthRule> rules) async {
    final l10n = context.l10n;
    final ctx = _ctx;
    var failed = false;
    for (final rule in rules) {
      try {
        await rule.apply!(ctx);
      } catch (_) {
        failed = true;
      }
    }
    if (failed && mounted) {
      showDismissibleSnackBar(
        context,
        content: Text(l10n.healthCheck_fixFailed),
      );
    }
    await _run();
  }

  Future<void> _fix(HealthRule rule) async {
    if (rule.fix == HealthFix.ask) {
      await widget.openDialog(context, rule.dialog!);
      await _run();
      return;
    }
    final confirmed = await _confirm(
      rule.title,
      Text(rule.fixDescription),
      context.l10n.healthCheck_fix,
    );
    if (confirmed) await _apply([rule]);
  }

  Future<void> _fixAll(List<HealthRule> rules) async {
    final l10n = context.l10n;
    final confirmed = await _confirm(
      l10n.healthCheck_fixAllConfirm,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final rule in rules)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(rule.fixDescription),
            ),
        ],
      ),
      l10n.healthCheck_fixAll(rules.length),
    );
    if (confirmed) await _apply(rules);
  }

  Future<void> _hide(HealthRule rule) async {
    await context.read<AppSettingsService>().dismissHealthRule(rule.id);
    await _judge();
  }

  Future<void> _showHidden() async {
    await context.read<AppSettingsService>().restoreHealthRules();
    await _judge();
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
    final autoFixable = _autoFixable(report, connector);
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
        if (autoFixable.length >= 2)
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: () => _fixAll(autoFixable),
              child: Text(l10n.healthCheck_fixAll(autoFixable.length)),
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
        if (report.hidden > 0)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _showHidden,
              child: Text(l10n.healthCheck_showHidden(report.hidden)),
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
    final l10n = context.l10n;
    final ctx = _ctx;
    final colors = Theme.of(context).colorScheme;
    final (icon, color) = switch (rule.severity) {
      HealthSeverity.problem => (Icons.error_outline, colors.error),
      HealthSeverity.suggestion => (Icons.warning_amber, Colors.amber.shade800),
      HealthSeverity.tip => (Icons.lightbulb_outline, colors.onSurfaceVariant),
    };
    final showFix = rule.fix != null && (rule.canFix?.call(ctx) ?? true);
    final link = rule.linkUrl;
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
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => _hide(rule),
                  child: Text(l10n.healthCheck_hide),
                ),
                if (link != null)
                  TextButton(
                    onPressed: () => launchUrl(
                      Uri.parse(link),
                      mode: LaunchMode.externalApplication,
                    ),
                    child: Text(rule.linkLabel ?? link),
                  ),
                if (showFix)
                  FilledButton.tonal(
                    onPressed: rule.needsRadio && !connector.isConnected
                        ? null
                        : () => _fix(rule),
                    child: Text(l10n.healthCheck_fix),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
