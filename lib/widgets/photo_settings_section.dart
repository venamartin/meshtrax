import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:traxmap/traxmap.dart' show PackDownloadState;

import '../l10n/l10n.dart';
import '../screens/photo_licences_screen.dart';
import '../services/app_settings_service.dart';
import '../services/photo_model_downloads.dart';
import '../services/photo_mesh.dart' show photoAutoEnlargeAllowed;
import '../services/photo_reports.dart';
import '../services/photo_store.dart';
import '../utils/format_bytes.dart';
import 'experimental_title.dart';

/// Photos, in App settings' Messaging card: the switch that turns them on,
/// then the photo model (it downloads through the map downloader, so it also
/// shows in Offline maps), automatic rebuilds and enlargements, and photo
/// reports still waiting for the email app. The model stays listed while it
/// is on the phone, so it can be deleted with photos off.
class PhotoSettingsSection extends StatelessWidget {
  const PhotoSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final models = PhotoModelDownloads.instance;
    final store = PhotoStore.instance;
    final reports = PhotoReports.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([?models, store, reports]),
      builder: (context, _) {
        final enabled = store.photosEnabled;
        final onPhone =
            models != null && (models.installed || models.active.isNotEmpty);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.photo_camera_outlined),
              title: ExperimentalTitle(Text(l10n.photo_settingsTitle)),
              subtitle: Text(
                l10n.photo_enableHint(
                  formatBytes(PhotoModelDownloads.totalBytes),
                ),
              ),
              value: enabled,
              onChanged: (on) => store.photosEnabled = on,
            ),
            if (models != null && (enabled || onPhone)) _model(context, models),
            if (enabled) ...[
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.auto_fix_high_outlined),
                title: Text(l10n.photo_autoRebuild),
                subtitle: Text(l10n.photo_autoRebuildHint),
                value: store.rebuildAutomatically,
                onChanged: (on) => store.rebuildAutomatically = on,
              ),
              if (photoAutoEnlargeAllowed) ...[
                const Divider(height: 1),
                SwitchListTile(
                  secondary: const Icon(Icons.open_in_full),
                  title: Text(l10n.photo_enlargeAutomatically),
                  subtitle: Text(l10n.photo_enlargeAutomaticallyHint),
                  value: store.enlargeAutomatically,
                  onChanged: (on) => store.enlargeAutomatically = on,
                ),
              ],
              const Divider(height: 1),
              SwitchListTile(
                secondary: const Icon(Icons.timer_off_outlined),
                title: Text(l10n.photo_ignoreTimeLimits),
                subtitle: Text(l10n.photo_ignoreTimeLimitsHint),
                value: store.ignoreTimeLimits,
                onChanged: (on) => store.ignoreTimeLimits = on,
              ),
            ],
            for (final r in reports.all.where((r) => !r.sent)) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.photo_reportPending(r.sender)),
                subtitle: Text(l10n.photo_reportPendingHint),
                trailing: TextButton(
                  onPressed: () async {
                    if (!await reports.send(r) && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.photo_reportStillWaiting)),
                      );
                    }
                  },
                  child: Text(l10n.photo_send),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _model(BuildContext context, PhotoModelDownloads models) {
    final l10n = context.l10n;
    final wifiOnly = context
        .watch<AppSettingsService>()
        .settings
        .mapDownloadsWifiOnly;
    final total = PhotoModelDownloads.totalBytes;
    final active = models.active;
    final failed = models.failed;
    final states = {for (final d in active) d.state};
    final status = active.isNotEmpty
        ? switch (states) {
            _ when states.contains(PackDownloadState.running) =>
              l10n.photo_modelProgress(
                formatBytes(models.bytesDone),
                formatBytes(total),
              ),
            _
                when states.contains(PackDownloadState.verifying) ||
                    states.contains(PackDownloadState.downloaded) =>
              l10n.photo_modelChecking,
            _ when states.contains(PackDownloadState.waitingToRetry) =>
              l10n.photo_modelRetrying,
            _ when states.contains(PackDownloadState.paused) =>
              l10n.photo_modelPaused,
            _ when wifiOnly => l10n.photo_modelWaitingWifi,
            _ => l10n.photo_modelWaiting,
          }
        : models.installed
        ? l10n.photo_modelInstalled(formatBytes(total))
        : failed != null
        ? l10n.photo_modelFailed(failed.error ?? l10n.photo_modelNoReason)
        : l10n.photo_modelNeeded(formatBytes(total));

    Future<void> download() async {
      final short = await models.download(l10n);
      if (short != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.photo_notEnoughSpace(
                formatBytes(short.needed),
                formatBytes(short.free),
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.photo_modelTitle,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(status, style: const TextStyle(fontSize: 12)),
          if (active.isNotEmpty) ...[
            const SizedBox(height: 4),
            LinearProgressIndicator(value: models.bytesDone / total),
          ],
          if (!models.installed)
            Text(l10n.photo_keepOpen, style: const TextStyle(fontSize: 12)),
          // The Stability AI Community License asks for this where the
          // model is.
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => PhotoLicencesScreen(dir: models.licencesDir),
              ),
            ),
            child: Text(l10n.photo_licencesLink(kPoweredByStability)),
          ),
          const SizedBox(height: 4),
          if (active.isNotEmpty)
            OutlinedButton(
              onPressed: models.cancel,
              child: Text(l10n.photo_cancelDownload),
            )
          else if (models.installed)
            Wrap(
              spacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => _confirmDelete(context, models),
                  child: Text(l10n.photo_deleteModel),
                ),
                if (!models.licencesInstalled)
                  TextButton(
                    onPressed: download,
                    child: Text(l10n.photo_downloadLicences),
                  ),
              ],
            )
          else
            FilledButton(
              onPressed: download,
              child: Text(
                failed != null ? l10n.photo_tryAgain : l10n.photo_downloadModel,
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    PhotoModelDownloads models,
  ) async {
    final l10n = context.l10n;
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.photo_deleteModelTitle),
        content: Text(
          l10n.photo_deleteModelBody(
            formatBytes(PhotoModelDownloads.totalBytes),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.photo_keep),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (yes == true) await models.delete();
  }
}
