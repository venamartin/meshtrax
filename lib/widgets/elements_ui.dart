import 'package:material_ui/material_ui.dart';

class FeatureToggleRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool value;
  final bool hasRefreshing;
  final bool isRefreshing;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onRefresh;
  final String? refreshTooltip;

  const FeatureToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    this.hasRefreshing = false,
    this.isRefreshing = false,
    this.onChanged,
    this.onRefresh,
    this.refreshTooltip,
  });

  @override
  State<FeatureToggleRow> createState() => _FeatureToggleRow();
}

class _FeatureToggleRow extends State<FeatureToggleRow> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SwitchListTile(
            title: Text(widget.title),
            subtitle: Text(widget.subtitle),
            value: widget.value,
            onChanged: widget.onChanged,
            contentPadding: EdgeInsets.zero,
          ),
        ),
        if (widget.hasRefreshing)
          IconButton(
            icon: widget.isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh, size: 20),
            onPressed: widget.isRefreshing ? null : widget.onRefresh,
            tooltip: widget.refreshTooltip,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}
