import '../connector/meshcore_connector.dart';
import '../connector/meshcore_protocol.dart';
import '../models/app_settings.dart';
import '../models/radio_settings.dart';
import '../services/app_settings_service.dart';
import '../services/battery_sleep_service.dart';

/// The health check's rule list. Edit this file to change what the check
/// looks for.
///
/// Each [HealthRule] has:
///   enabled   - false leaves the rule out of the check entirely
///   severity  - problem (red, listed first), suggestion (amber), tip (grey)
///   title     - short line shown on the finding
///   why       - one or two plain sentences shown under the title
///   notes     - for us, never shown; what needs doing beyond on/off
///   check     - returns true when the finding applies
///   fix       - what the Fix button does; null = report only.
///               HealthFix.apply runs [apply] after a confirm dialog.
///               HealthFix.ask needs a value from the user, so the screen
///               opens the matching settings dialog instead.

// ---------------------------------------------------------------------------
// Plumbing
// ---------------------------------------------------------------------------

enum HealthSeverity { problem, suggestion, tip }

/// How the Fix button behaves for a rule.
enum HealthFix {
  /// Applies the recommended value straight away (after the confirm dialog).
  apply,

  /// Needs a value from the user; the screen opens the matching dialog.
  ask,
}

class HealthContext {
  final MeshCoreConnector connector;
  final AppSettingsService settingsService;

  HealthContext(this.connector, this.settingsService);

  AppSettings get app => settingsService.settings;
  bool get radioConnected => connector.isConnected;
}

class HealthRule {
  final String id;
  final bool enabled;
  final HealthSeverity severity;
  final String title;
  final String why;
  final String notes;

  /// True when the rule needs a connected radio.
  final bool needsRadio;
  final Future<bool> Function(HealthContext ctx) check;
  final HealthFix? fix;
  final Future<void> Function(HealthContext ctx)? apply;

  const HealthRule({
    required this.id,
    required this.enabled,
    required this.severity,
    required this.title,
    required this.why,
    this.notes = '',
    this.needsRadio = false,
    required this.check,
    this.fix,
    this.apply,
  });
}

// Shared helpers for the radio rules.

bool _onAnyPreset(MeshCoreConnector c) {
  final freq = c.currentFreqHz;
  if (freq == null) return true; // unknown yet; don't flag
  return RadioSettings.presets.any(
    (p) =>
        p.$2.frequencyHz == freq &&
        p.$2.bandwidthHz == c.currentBwHz &&
        p.$2.sf == c.currentSf &&
        p.$2.cr == c.currentCr,
  );
}

Future<void> _setAutoAdd(
  HealthContext ctx, {
  bool? users,
  bool? repeaters,
  bool? rooms,
  bool? sensors,
  bool? overwriteOldest,
}) async {
  final c = ctx.connector;
  await c.sendFrame(
    buildSetAutoAddConfigFrame(
      autoAddChat: users ?? c.autoAddUsers ?? true,
      autoAddRepeater: repeaters ?? c.autoAddRepeaters ?? true,
      autoAddRoomServer: rooms ?? c.autoAddRoomServers ?? true,
      autoAddSensor: sensors ?? c.autoAddSensors ?? true,
      overwriteOldest: overwriteOldest ?? c.autoAddOverwriteOldest ?? true,
      maxHops: c.autoAddMaxHops,
    ),
  );
  await c.sendFrame(buildGetAutoAddFlagsFrame());
}

Future<void> _setOtherParams(
  HealthContext ctx, {
  int? advertLocationPolicy,
  int? multiAcks,
}) {
  final c = ctx.connector;
  return c.setTelemetryModeBase(
    c.telemetryModeBase,
    c.telemetryModeLoc,
    c.telemetryModeEnv,
    advertLocationPolicy ?? c.advertLocationPolicy,
    multiAcks ?? c.multiAcks,
  );
}

// ---------------------------------------------------------------------------
// The rules
// ---------------------------------------------------------------------------

final List<HealthRule> healthRules = [
  // ------------------------------------------------------------ Radio ------
  HealthRule(
    id: 'radio_name',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Radio still has no name',
    why:
        'It is still called NONAME, so nobody on the mesh can tell who '
        'you are.',
    needsRadio: true,
    check: (ctx) async {
      final name = ctx.connector.selfName?.trim() ?? '';
      return name.isEmpty || name == 'NONAME';
    },
    fix: HealthFix.ask,
    notes: 'Opens the node name dialog.',
  ),
  HealthRule(
    id: 'radio_frequency',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Radio is not on a known preset',
    why:
        'The frequency, bandwidth, spreading factor and coding rate do not '
        'match any regional preset. You may be alone on the air while your '
        'local mesh uses another setting.',
    needsRadio: true,
    check: (ctx) async => !_onAnyPreset(ctx.connector),
    fix: HealthFix.ask,
    notes:
        'Opens the radio settings dialog so the user picks a preset. '
        'Decide: flag anything off-preset (current), or only the firmware '
        'build default (869.618 in the stock ini).',
  ),
  HealthRule(
    id: 'radio_tx_power',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: "Transmit power is below the radio's maximum",
    why: '',
    needsRadio: true,
    check: (ctx) async {
      final c = ctx.connector;
      return c.currentTxPower != null &&
          c.maxTxPower != null &&
          c.currentTxPower! < c.maxTxPower!;
    },
    fix: HealthFix.apply,
    apply: (ctx) => ctx.connector.sendFrame(
      buildSetRadioTxPowerFrame(ctx.connector.maxTxPower!),
    ),
    notes:
        'Below max can be deliberate (legal limit, battery). Decide '
        'whether to flag at all.',
  ),
  HealthRule(
    id: 'radio_position',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: 'Radio has no position',
    why: '',
    needsRadio: true,
    check: (ctx) async => !ctx.connector.hasSelfPosition,
    fix: HealthFix.ask,
    notes:
        'Opens the location dialog. If the radio has GPS, the fix could '
        'turn GPS on instead.',
  ),
  HealthRule(
    id: 'radio_gps',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'GPS is off',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.hasGps && !ctx.connector.gpsOn,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.connector.setGps(true),
    notes: 'Only runs when the radio reports a GPS.',
  ),
  HealthRule(
    id: 'radio_advert_location',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Adverts do not share your position',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.advertLocationPolicy == 0,
    fix: HealthFix.apply,
    apply: (ctx) => _setOtherParams(ctx, advertLocationPolicy: 1),
    notes: '0 = none, 1 = share. Privacy choice; maybe leave disabled.',
  ),
  HealthRule(
    id: 'radio_telemetry',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Telemetry sharing',
    why: '',
    needsRadio: true,
    check: (ctx) async => false,
    notes:
        'telemetryModeBase / Loc / Env, each deny..allow all. Write the '
        'check once we know what we recommend.',
  ),
  HealthRule(
    id: 'radio_auto_add_users',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add users is off',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddUsers == false,
    fix: HealthFix.apply,
    apply: (ctx) => _setAutoAdd(ctx, users: true),
  ),
  HealthRule(
    id: 'radio_auto_add_repeaters',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add repeaters is off',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddRepeaters == false,
    fix: HealthFix.apply,
    apply: (ctx) => _setAutoAdd(ctx, repeaters: true),
  ),
  HealthRule(
    id: 'radio_auto_add_rooms',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add room servers is off',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddRoomServers == false,
    fix: HealthFix.apply,
    apply: (ctx) => _setAutoAdd(ctx, rooms: true),
  ),
  HealthRule(
    id: 'radio_auto_add_sensors',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add sensors is off',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddSensors == false,
    fix: HealthFix.apply,
    apply: (ctx) => _setAutoAdd(ctx, sensors: true),
  ),
  HealthRule(
    id: 'radio_auto_add_overwrite_oldest',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: 'Overwrite oldest contact is off',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddOverwriteOldest == false,
    fix: HealthFix.apply,
    apply: (ctx) => _setAutoAdd(ctx, overwriteOldest: true),
  ),
  HealthRule(
    id: 'radio_auto_add_max_hops',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Auto-add max hops',
    why: '',
    needsRadio: true,
    check: (ctx) async => false,
    notes:
        'autoAddMaxHops (firmware v10+). Write the check once we know '
        'what we recommend.',
  ),
  HealthRule(
    id: 'radio_multi_acks',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: 'Multi-ACKs',
    why: '',
    needsRadio: true,
    check: (ctx) async => ctx.connector.multiAcks != 1,
    fix: HealthFix.apply,
    apply: (ctx) => _setOtherParams(ctx, multiAcks: 1),
    notes: 'Extra ACKs: 0 = 1 ACK, 1 = 2 ACKs. Interacts with Pathfinder.',
  ),
  HealthRule(
    id: 'radio_client_repeat',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: "This radio is repeating other people's traffic",
    why:
        'Client repeat is on. A phone-connected radio that repeats adds '
        'noise to the mesh and drains its battery faster.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.clientRepeat == true,
    fix: HealthFix.ask,
    notes:
        'Turning it off goes through the radio settings dialog, which '
        'knows the off-grid presets.',
  ),
  HealthRule(
    id: 'radio_path_hash_width',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Path hash width',
    why: '',
    needsRadio: true,
    check: (ctx) async => false,
    notes:
        'Width is bytes per hop (1 = 1-byte, 2 = 2-byte). setPathHashMode takes '
        'width - 1 (0 = 1-byte, 1 = 2-byte). Depends on what the local mesh uses; '
        'probably leave disabled.',
  ),
  HealthRule(
    id: 'radio_firmware',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio firmware is out of date',
    why: 'Newer firmware fixes bugs and adds features this app can use.',
    needsRadio: true,
    check: (ctx) async {
      final code = ctx.connector.firmwareVerCode;
      return code != null && code < 14;
    },
    notes: 'Report only. Raise the 14 when we need a newer one.',
  ),
  HealthRule(
    id: 'radio_clock',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Radio clock is wrong',
    why:
        "Messages carry the radio's time. When it is off, they sort "
        "wrongly on other people's screens.",
    needsRadio: true,
    check: (ctx) async {
      final c = ctx.connector;
      if (c.deviceClockStuckAhead) return true;
      final skew = c.deviceClockSkew;
      return skew != null &&
          skew.abs() > MeshCoreConnector.deviceClockTolerance;
    },
    fix: HealthFix.apply,
    apply: (ctx) => ctx.connector.syncTime(),
    notes:
        'When deviceClockStuckAhead, the firmware refuses to wind back; '
        'the screen should say so instead of offering Fix.',
  ),
  HealthRule(
    id: 'radio_contacts_full',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Contact table is nearly full',
    why:
        "When the radio's contact list is full it stops adding new "
        'people and repeaters it hears.',
    needsRadio: true,
    check: (ctx) async {
      final c = ctx.connector;
      if (c.maxContacts == 0) return false;
      return c.allContactsUnfiltered.length * 100 >= c.maxContacts * 90;
    },
    notes: 'Fix could offer the purge of old discovered contacts.',
  ),
  HealthRule(
    id: 'radio_storage_full',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio storage is nearly full',
    why:
        'The radio keeps contacts and settings in a small flash store. '
        'When it fills, saves can fail.',
    needsRadio: true,
    check: (ctx) async {
      final c = ctx.connector;
      final used = c.storageUsedKb, total = c.storageTotalKb;
      if (used == null || total == null || total == 0) return false;
      return used * 100 >= total * 90;
    },
  ),
  HealthRule(
    id: 'radio_battery_low',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Radio battery is low',
    why: '',
    needsRadio: true,
    check: (ctx) async {
      final pct = ctx.connector.batteryPercent;
      return pct != null && pct < 20;
    },
    notes: 'Probably noise; the battery already shows in the app bar.',
  ),
  HealthRule(
    id: 'radio_channels',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Channel slots need attention',
    why:
        'Two slots share a key, or a keyed slot has no name. Twins share '
        'one history and confuse delivery.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.channelHealthWarnings.isNotEmpty,
    notes:
        'The screen lists connector.channelHealthWarnings under the '
        'finding. Fix could offer to delete the extra slot.',
  ),
  HealthRule(
    id: 'radio_second_app',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Another app seems to be using this radio',
    why: 'Two apps on one radio each miss some of its messages.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.secondAppSuspected,
  ),

  // --------------------------------------------------------- App: map ------
  HealthRule(
    id: 'app_map_wifi_only',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Map downloads allowed on mobile data',
    why: '',
    check: (ctx) async => !ctx.app.mapDownloadsWifiOnly,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setMapDownloadsWifiOnly(true),
  ),
  HealthRule(
    id: 'app_map_theme',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Map theme',
    why: '',
    check: (ctx) async => ctx.app.mapTheme != 'light',
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setMapTheme('light'),
    notes: 'light reads better outdoors (owner, 2026-10-20).',
  ),
  // Other map toggles (repeaters, chat nodes, other nodes, overlaps, time
  // filter, key prefix, markers, guessed locations, discovery contacts, map
  // type, contours, hill shading, downloaded areas, map source) are view
  // preferences; add a rule here if one matters.

  // ------------------------------------------------- App: notifications ----
  HealthRule(
    id: 'app_notifications_off',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Notifications are off',
    why: 'You will not hear about new messages unless the app is open.',
    check: (ctx) async => !ctx.app.notificationsEnabled,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setNotificationsEnabled(true),
    notes:
        'OS-level permission is a separate check; the notification '
        'service only exposes requestPermissions today.',
  ),
  HealthRule(
    id: 'app_notify_dm',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Direct message notifications are off',
    why: '',
    check: (ctx) async => !ctx.app.notifyOnNewMessage,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setNotifyOnNewMessage(true),
  ),
  HealthRule(
    id: 'app_notify_channel',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Channel message notifications are off',
    why: '',
    check: (ctx) async => !ctx.app.notifyOnNewChannelMessage,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setNotifyOnNewChannelMessage(true),
  ),
  HealthRule(
    id: 'app_notify_mention',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Mention notifications are off',
    why: '',
    check: (ctx) async => !ctx.app.notifyOnMention,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setNotifyOnMention(true),
  ),
  HealthRule(
    id: 'app_notify_advert',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Advert notifications are on',
    why: '',
    check: (ctx) async => ctx.app.notifyOnNewAdvert,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setNotifyOnNewAdvert(false),
    notes: 'Default off; on is noisy in a busy mesh.',
  ),

  // ---------------------------------------------------- App: messaging -----
  HealthRule(
    id: 'app_message_tracing',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Message tracing is off',
    why: '',
    check: (ctx) async => !ctx.app.enableMessageTracing,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setEnableMessageTracing(true),
  ),
  HealthRule(
    id: 'app_dm_retries',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Direct message retries',
    why: '',
    check: (ctx) async => ctx.app.maxMessageRetries != 3,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setMaxMessageRetries(3),
  ),
  HealthRule(
    id: 'app_channel_retries',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Channel message retries',
    why: '',
    check: (ctx) async => ctx.app.maxChannelMessageRetries != 1,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setMaxChannelMessageRetries(1),
  ),
  // jumpToOldestUnread, autoFavoriteOnChat, senderNameColors,
  // showTextFormatting: taste, not health. Add a rule if one matters.

  // --------------------------------------------------- App: connection -----
  HealthRule(
    id: 'app_auto_connect',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Auto-connect to the last radio is off',
    why: '',
    check: (ctx) async => !ctx.app.autoConnectLastDevice,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setAutoConnectLastDevice(true),
  ),
  HealthRule(
    id: 'app_incremental_sync',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Incremental contact sync',
    why: '',
    check: (ctx) async => ctx.app.incrementalContactSync,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setIncrementalContactSync(false),
    notes: 'Bench toggle in the Debug card.',
  ),

  // --------------------------------------------------- App: Pathfinder -----
  HealthRule(
    id: 'app_pathfinder',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Pathfinder is off',
    why: '',
    check: (ctx) async => !ctx.app.pathGraphEnabled,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setPathGraphEnabled(true),
    notes: 'Off by default by owner decision. Tip at most, never a problem.',
  ),

  // ------------------------------------------------------ App: general -----
  HealthRule(
    id: 'app_debug_log',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'App debug log is on',
    why:
        'The debug log costs storage and battery. Turn it off unless you '
        'are chasing a problem.',
    check: (ctx) async => ctx.app.appDebugLogEnabled,
    fix: HealthFix.apply,
    apply: (ctx) => ctx.settingsService.setAppDebugLogEnabled(false),
  ),
  HealthRule(
    id: 'app_battery_sleep',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Your phone may put MeshTrax to sleep',
    why:
        'This phone restricts background apps, so messages can stop '
        'arriving when the screen is off.',
    check: (ctx) async => BatterySleepService.shouldWarn(),
    fix: HealthFix.ask,
    notes:
        'Fix opens the system battery settings '
        '(BatterySleepService.openSettings). Android only.',
  ),
  // theme, languageOverride, unitSystem, battery chemistry: taste or
  // per-device; no rule.
];
