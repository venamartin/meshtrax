import '../utils/app_logger.dart';
import 'health_rules.dart';

class HealthReport {
  /// Worst first, in rule order within a severity.
  final List<HealthRule> findings;
  final int passed;

  /// Findings the user chose not to see again.
  final int hidden;

  /// No radio was connected, so the radio rules did not run.
  final bool radioSkipped;

  const HealthReport({
    required this.findings,
    required this.passed,
    required this.hidden,
    required this.radioSkipped,
  });
}

Future<HealthReport> runHealthCheck(
  HealthContext ctx, {
  List<HealthRule>? rules,
}) async {
  final findings = <HealthRule>[];
  var passed = 0;
  var hidden = 0;
  for (final rule in (rules ?? healthRules).where((r) => r.enabled)) {
    if (rule.needsRadio && !ctx.radioConnected) continue;
    try {
      if (!await rule.check(ctx)) {
        passed++;
      } else if (ctx.app.dismissedHealthRules.contains(rule.id)) {
        hidden++;
      } else {
        findings.add(rule);
      }
    } catch (e) {
      appLogger.warn('Health check ${rule.id} failed: $e', tag: 'HealthCheck');
    }
  }
  findings.sort((a, b) => a.severity.index.compareTo(b.severity.index));
  return HealthReport(
    findings: findings,
    passed: passed,
    hidden: hidden,
    radioSkipped: !ctx.radioConnected,
  );
}
