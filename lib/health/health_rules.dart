import '../connector/meshcore_connector.dart';
import '../models/app_settings.dart';
import '../models/channel.dart';
import '../models/device_backup.dart';
import '../models/radio_settings.dart';
import '../services/app_settings_service.dart';
import '../services/battery_sleep_service.dart';
import '../services/notification_service.dart';
import '../utils/platform_info.dart';

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
///               HealthFix.apply runs [apply] after a confirm dialog, which
///               shows [fixDescription].
///               HealthFix.ask needs a value from the user, so the screen
///               opens [dialog] instead.
///   details   - optional extra lines shown under the why
///   linkLabel, linkUrl - optional button that opens a web page
///   canFix    - optional; false hides the Fix button for this finding

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

/// The existing screens a [HealthFix.ask] rule can send the user to.
enum HealthDialog {
  name,
  radioSettings,
  location,
  batterySettings,
  notificationSettings,
}

class HealthContext {
  final MeshCoreConnector connector;
  final AppSettingsService settingsService;

  /// False when the phone blocks notifications; null when it can't be known.
  final Future<bool?> Function() notificationsAllowed;

  /// False on Windows and Linux, where the app never shows a notification.
  final bool canShowNotifications;

  HealthContext(
    this.connector,
    this.settingsService, {
    Future<bool?> Function()? notificationsAllowed,
    bool? canShowNotifications,
  }) : notificationsAllowed =
           notificationsAllowed ?? NotificationService().notificationsAllowed,
       canShowNotifications =
           canShowNotifications ??
           !(PlatformInfo.isWindows || PlatformInfo.isLinux);

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

  /// What Fix will do, shown in the confirm dialog.
  final String fixDescription;

  /// Where a [HealthFix.ask] rule sends the user.
  final HealthDialog? dialog;
  final List<String> Function(HealthContext ctx)? details;
  final String? linkLabel;
  final String? linkUrl;
  final bool Function(HealthContext ctx)? canFix;

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
    this.fixDescription = '',
    this.dialog,
    this.details,
    this.linkLabel,
    this.linkUrl,
    this.canFix,
  });
}

// Shared helpers for the radio rules.

/// The settings a radio ships with. They are also the app's EU/UK (Narrow) and
/// Switzerland presets, so only the user can say whether they are right.
bool _onFactoryRadioSettings(MeshCoreConnector c) =>
    c.currentFreqHz == 869618 &&
    c.currentBwHz == 62500 &&
    c.currentSf == 8 &&
    c.currentCr == 5;

/// Compares the version text, because the version code can't tell these
/// apart: 1.16.0, 1.17.0 and 1.17.1 all report code 13.
bool _firmwareOlderThan(MeshCoreConnector c, List<int> wanted) {
  final match = RegExp(r'(\d+)\.(\d+)\.(\d+)')
      .firstMatch(c.firmwareVersion ?? '');
  if (match == null) {
    final code = c.firmwareVerCode;
    return code != null && code < 13;
  }
  for (var i = 0; i < wanted.length; i++) {
    final part = int.parse(match.group(i + 1)!);
    if (part != wanted[i]) return part < wanted[i];
  }
  return false;
}

/// True when the radio has the Public channel and its messages would notify.
/// Muted follows the notification code: older versions saved mutes by name.
bool _publicChannelNotifies(HealthContext ctx) {
  final settings = ctx.settingsService;
  if (!ctx.app.notificationsEnabled || !ctx.app.notifyOnNewChannelMessage) {
    return false;
  }
  for (final channel in ctx.connector.channels) {
    if (!channel.isPublicChannel) continue;
    return !settings.isChannelMuted(channel.idKey) &&
        !settings.isChannelMuted(channel.name) &&
        !settings.isChannelMuted(channel.displayName);
  }
  return false;
}

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

Future<void> _setMultiAcks(HealthContext ctx, int multiAcks) {
  final c = ctx.connector;
  return c.setTelemetryModeBase(
    c.telemetryModeBase,
    c.telemetryModeLoc,
    c.telemetryModeEnv,
    c.advertLocationPolicy,
    multiAcks,
  );
}

bool _radioHasAutoAdd(MeshCoreConnector c) => firmwareSupports(
  RadioSetting.autoAdd,
  c.firmwareVerCode,
  c.firmwareVersion,
);

bool _radioHasMultiAcks(MeshCoreConnector c) => firmwareSupports(
  RadioSetting.multiAcks,
  c.firmwareVerCode,
  c.firmwareVersion,
);

// ---------------------------------------------------------------------------
// The rules
// ---------------------------------------------------------------------------

final List<HealthRule> healthRules = [
  // ------------------------------------------------------------ Radio ------
  HealthRule(
    id: 'radio_name',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Radio still has its default name',
    why:
        'Your radio is still using its default name, a string of letters and '
        "numbers, so people can't tell who you are.",
    needsRadio: true,
    check: (ctx) async => ctx.connector.hasFactoryName,
    fix: HealthFix.ask,
    dialog: HealthDialog.name,
    notes:
        'Opens the node name dialog. Other builds may set their own fixed '
        'names; add them to MeshCoreConnector.hasFactoryName as we find them.',
  ),
  HealthRule(
    id: 'radio_frequency',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio is not on a regional preset',
    why:
        "The radio's settings do not match any regional preset in the app. If "
        'your local mesh uses a preset, you may not hear it or be heard by it.',
    needsRadio: true,
    check: (ctx) async => !_onAnyPreset(ctx.connector),
    fix: HealthFix.ask,
    dialog: HealthDialog.radioSettings,
    notes:
        'Opens the radio settings dialog so the user picks a preset. '
        'The factory settings match a preset, so radio_factory_settings '
        'covers those.',
  ),
  HealthRule(
    id: 'radio_factory_settings',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio is still on its factory frequency',
    why:
        "Outside the EU, the UK and Switzerland, choose your region's preset so "
        'you can hear your local mesh and be heard by it. If this already '
        "matches your local mesh, tap Don't show again.",
    needsRadio: true,
    check: (ctx) async => _onFactoryRadioSettings(ctx.connector),
    fix: HealthFix.ask,
    dialog: HealthDialog.radioSettings,
    notes: 'Opens the radio settings dialog so the user picks a preset.',
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
    dialog: HealthDialog.location,
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
    fixDescription: 'Turn GPS on.',
    apply: (ctx) => ctx.connector.setGps(true),
    notes: 'Only runs when the radio reports a GPS.',
  ),
  HealthRule(
    id: 'radio_auto_add_users',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add users is off',
    why:
        'People you hear are not saved to your radio, and it can only read '
        'direct messages from saved contacts. Someone new cannot reach you '
        'until you add them.',
    needsRadio: true,
    check: (ctx) async =>
        _radioHasAutoAdd(ctx.connector) && ctx.connector.autoAddUsers == false,
    fix: HealthFix.apply,
    fixDescription: 'Turn on auto-add for users.',
    apply: (ctx) => ctx.connector.setAutoAddConfig(users: true),
  ),
  HealthRule(
    id: 'radio_auto_add_repeaters',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add repeaters is on',
    why:
        "Every repeater you hear takes a place in the radio's limited contact "
        'list, leaving less room for people. The app still lists the ones it '
        'hears, so you can add one when you need it.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddRepeaters == true,
    fix: HealthFix.apply,
    fixDescription: 'Turn off auto-add for repeaters.',
    apply: (ctx) => ctx.connector.setAutoAddConfig(repeaters: false),
  ),
  HealthRule(
    id: 'radio_auto_add_rooms',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add room servers is on',
    why:
        "Every room server you hear takes a place in the radio's limited "
        'contact list, leaving less room for people. The app still lists the '
        'ones it hears, so you can add the ones you use.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddRoomServers == true,
    fix: HealthFix.apply,
    fixDescription: 'Turn off auto-add for room servers.',
    apply: (ctx) => ctx.connector.setAutoAddConfig(rooms: false),
  ),
  HealthRule(
    id: 'radio_auto_add_sensors',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Auto-add sensors is on',
    why:
        "Every sensor you hear takes a place in the radio's limited contact "
        'list, leaving less room for people. The app still lists the ones it '
        'hears, so you can add the ones you use.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.autoAddSensors == true,
    fix: HealthFix.apply,
    fixDescription: 'Turn off auto-add for sensors.',
    apply: (ctx) => ctx.connector.setAutoAddConfig(sensors: false),
  ),
  HealthRule(
    id: 'radio_auto_add_overwrite_oldest',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Overwrite oldest contact is off',
    why:
        'When the contact list is full, new contacts are not saved. This '
        'setting makes room by replacing the oldest contact that is not a '
        'favorite. A replaced contact leaves your chats once its messages are '
        'read, and they are kept. Replying adds it back.',
    needsRadio: true,
    check: (ctx) async =>
        _radioHasAutoAdd(ctx.connector) &&
        ctx.connector.autoAddOverwriteOldest == false,
    fix: HealthFix.apply,
    fixDescription: 'Turn on overwrite oldest contact.',
    apply: (ctx) => ctx.connector.setAutoAddConfig(overwriteOldest: true),
  ),
  HealthRule(
    id: 'radio_multi_acks',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio sends only one ACK for direct messages',
    why:
        'If the only ACK is lost, the sender thinks the message failed even '
        'though you received it. A second ACK gives the sender another chance '
        'to hear it, for one more short transmission.',
    needsRadio: true,
    check: (ctx) async =>
        _radioHasMultiAcks(ctx.connector) && ctx.connector.multiAcks == 0,
    fix: HealthFix.apply,
    fixDescription:
        'Send a second ACK when a direct message arrives on a route.',
    apply: (ctx) => _setMultiAcks(ctx, 1),
    notes:
        'Extra ACKs: 0 = 1 ACK, 1 = 2 ACKs. Interacts with Pathfinder. A message '
        'that arrives by flood gets one reply whatever this says '
        '(BaseChatMesh.cpp).',
  ),
  HealthRule(
    id: 'radio_client_repeat',
    enabled: false,
    severity: HealthSeverity.suggestion,
    title: "This radio is repeating other people's traffic",
    why:
        'Client repeat is on. A phone-connected radio that repeats adds '
        'noise to the mesh and drains its battery faster.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.clientRepeat == true,
    fix: HealthFix.ask,
    dialog: HealthDialog.radioSettings,
    notes:
        'Turning it off goes through the radio settings dialog, which '
        'knows the off-grid presets.',
  ),
  HealthRule(
    id: 'radio_path_hash_width',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio uses 1-byte repeater codes',
    why:
        'Pathfinder cannot learn from 1-byte codes because too many repeaters '
        'share the same one, so it will not work properly. Switch to 2-byte '
        'codes. Repeaters on firmware older than 1.14 do not forward them.',
    needsRadio: true,
    check: (ctx) async =>
        ctx.connector.pathHashByteWidth == 1 &&
        (ctx.connector.firmwareVerCode ?? 0) >= 10,
    fix: HealthFix.apply,
    fixDescription: 'Switch this radio to 2-byte repeater codes.',
    apply: (ctx) => ctx.connector.setPathHashMode(1),
    notes:
        'Width is bytes per hop (1 = 1-byte, 2 = 2-byte). setPathHashMode takes '
        'width - 1 (0 = 1-byte, 1 = 2-byte). Firmware below code 10 has no '
        'setting for this.',
  ),
  HealthRule(
    id: 'radio_firmware',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio firmware is older than 1.17.1',
    why:
        'Newer firmware fixes bugs and adds features this app can use. Updating '
        'needs a computer with Chrome or Edge.',
    needsRadio: true,
    check: (ctx) async => _firmwareOlderThan(ctx.connector, [1, 17, 1]),
    linkLabel: 'Open the firmware flasher',
    linkUrl: 'https://flasher.meshcore.io',
    notes:
        'Report only. Change the version here and in the title when we need a '
        'newer one.',
  ),
  HealthRule(
    id: 'radio_clock',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Radio clock is far off',
    why:
        'The radio puts its own time on its adverts and on when it last heard '
        'each contact. When the clock is far off, other radios can show the '
        'wrong time for you and may ignore your adverts.',
    needsRadio: true,
    check: (ctx) async {
      final skew = ctx.connector.deviceClockSkew;
      return skew != null && skew.abs() > const Duration(minutes: 5);
    },
    fix: HealthFix.apply,
    fixDescription: "Set the radio's clock from this device.",
    apply: (ctx) => ctx.connector.syncTime(),
    canFix: (ctx) => !ctx.connector.deviceClockStuckAhead,
    details: (ctx) => [
      if (ctx.connector.deviceClockStuckAhead)
        "The radio's clock is ahead of this device. The firmware will not wind "
            'a clock back, so the app cannot fix this.',
    ],
    notes:
        'Messages from this app carry the phone time, not the radio time. A '
        'clock a few seconds fast is normal and cannot be wound back, so small '
        'differences are not flagged.',
  ),
  HealthRule(
    id: 'radio_contacts_full',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Contact table is nearly full',
    why:
        "When the radio's contact list is full, it cannot add anyone new "
        'unless it overwrites the oldest contact that is not a favorite.',
    needsRadio: true,
    check: (ctx) async {
      final c = ctx.connector;
      if (c.autoAddOverwriteOldest != false || c.maxContacts == 0) return false;
      return c.contacts.length * 100 >= c.maxContacts * 90;
    },
    notes:
        'Only when overwrite oldest is off: with it on, a full list is normal. '
        'Fix could offer the purge of old discovered contacts.',
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
        'Two slots share a key, a keyed slot has no name, or two channels look '
        'the same on the air. The details are listed below.',
    needsRadio: true,
    check: (ctx) async => ctx.connector.channelHealthWarnings.isNotEmpty,
    details: (ctx) => ctx.connector.channelHealthWarnings,
    notes: 'Fix could offer to delete the extra slot.',
  ),
  HealthRule(
    id: 'radio_second_app',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Another app seems to be using this radio',
    why:
        'Messages and settings can get mixed up. Close the other app. This '
        'warning stays until you reconnect.',
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
    fixDescription: 'Download maps on Wi-Fi only.',
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
    fixDescription: 'Use the light map theme.',
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
    check: (ctx) async =>
        ctx.canShowNotifications && !ctx.app.notificationsEnabled,
    fix: HealthFix.apply,
    fixDescription: 'Turn notifications on.',
    apply: (ctx) => ctx.settingsService.setNotificationsEnabled(true),
    notes: 'OS-level permission is app_notifications_blocked.',
  ),
  HealthRule(
    id: 'app_notifications_blocked',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'This device is blocking notifications',
    why:
        'Notifications are on in MeshTrax, but this device is not allowing all '
        'of them, so some or all will not appear.',
    check: (ctx) async =>
        ctx.app.notificationsEnabled &&
        await ctx.notificationsAllowed() == false,
    fix: HealthFix.ask,
    dialog: HealthDialog.notificationSettings,
    notes:
        'Asks the device; if it will not ask again, opens its settings. Also '
        'covers a blocked message or channel category on Android and alerts '
        'turned off on iOS and macOS. Unknown on Windows and Linux, so those '
        'pass.',
  ),
  HealthRule(
    id: 'app_notify_dm',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Direct message notifications are off',
    why:
        'You will not know someone sent you a direct message unless the app is '
        'open.',
    check: (ctx) async =>
        ctx.canShowNotifications &&
        ctx.app.notificationsEnabled &&
        !ctx.app.notifyOnNewMessage,
    fix: HealthFix.apply,
    fixDescription: 'Turn on direct message notifications.',
    apply: (ctx) => ctx.settingsService.setNotifyOnNewMessage(true),
  ),
  HealthRule(
    id: 'app_notify_channel',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Channel message notifications are off',
    why:
        'You will not know about new messages in your channels unless the app '
        'is open. If a channel is too busy, mute that channel instead.',
    check: (ctx) async =>
        ctx.canShowNotifications &&
        ctx.app.notificationsEnabled &&
        !ctx.app.notifyOnNewChannelMessage,
    fix: HealthFix.apply,
    fixDescription: 'Turn on channel message notifications.',
    apply: (ctx) => ctx.settingsService.setNotifyOnNewChannelMessage(true),
  ),
  HealthRule(
    id: 'app_notify_mention',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Mention notifications are off',
    why:
        'You will not know when someone mentions you or replies to you. With '
        'these on, you hear about it even in channels you have muted.',
    check: (ctx) async =>
        ctx.canShowNotifications &&
        ctx.app.notificationsEnabled &&
        !ctx.app.notifyOnMention,
    fix: HealthFix.apply,
    fixDescription: 'Turn on mention notifications.',
    apply: (ctx) => ctx.settingsService.setNotifyOnMention(true),
  ),
  HealthRule(
    id: 'app_notify_advert',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Advert notifications are on',
    why:
        'You get a notification each time a new radio or repeater is heard, '
        'which adds up quickly on a busy mesh.',
    check: (ctx) async =>
        ctx.canShowNotifications &&
        ctx.app.notificationsEnabled &&
        ctx.app.notifyOnNewAdvert,
    fix: HealthFix.apply,
    fixDescription: 'Turn off advert notifications.',
    apply: (ctx) => ctx.settingsService.setNotifyOnNewAdvert(false),
    notes: 'Default off; on is noisy in a busy mesh.',
  ),
  HealthRule(
    id: 'app_notify_public_channel',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'The Public channel sends you notifications',
    why:
        'Everyone on the mesh can post in Public, so it can notify you often. '
        'Mute it, and leave mention notifications on: you will still know when '
        'someone is talking to you or about you.',
    check: (ctx) async =>
        ctx.canShowNotifications && _publicChannelNotifies(ctx),
    fix: HealthFix.apply,
    fixDescription: 'Mute the Public channel.',
    apply: (ctx) => ctx.settingsService.muteChannel(Channel.publicChannelPsk),
    notes:
        'Muted by default for new installs (owner rule: defaults match the '
        'rules). The other notification rules stay quiet with the master '
        'switch off, because app_notifications_off already covers that.',
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
    fixDescription: 'Turn message tracing on.',
    apply: (ctx) => ctx.settingsService.setEnableMessageTracing(true),
  ),
  HealthRule(
    id: 'app_dm_retries',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Direct messages get too few tries',
    why:
        'With fewer than 4 tries, a direct message gets one try on a route '
        'before the app floods the whole mesh. With 4 or 5, it can get a second '
        'try on a route first, if the app has one to try, so more messages can '
        'arrive without flooding. If not, the extra try floods.',
    check: (ctx) async => ctx.app.maxMessageRetries < 4,
    fix: HealthFix.apply,
    fixDescription: 'Set direct message tries to 4.',
    apply: (ctx) => ctx.settingsService.setMaxMessageRetries(4),
    notes:
        '4 and 5 both pass. Attempts at each setting: path_selection.dart, '
        'planAttempts (the last 2 are floods from 3 tries up, and with '
        'Pathfinder on a route slot it cannot fill floods too).',
  ),
  HealthRule(
    id: 'app_channel_retries',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Channel message retries',
    why: '',
    check: (ctx) async => ctx.app.maxChannelMessageRetries != 1,
    fix: HealthFix.apply,
    fixDescription: 'Set channel message retries to 1.',
    apply: (ctx) => ctx.settingsService.setMaxChannelMessageRetries(1),
  ),
  HealthRule(
    id: 'app_auto_favorite',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'New chats are not set as favorites',
    why:
        'When the contact list is full, the radio can overwrite a contact that '
        'is not a favorite. Marking people as favorites when you start a chat '
        'keeps them on the radio.',
    check: (ctx) async => !ctx.app.autoFavoriteOnChat,
    fix: HealthFix.apply,
    fixDescription: 'Set new chats as favorites automatically.',
    apply: (ctx) => ctx.settingsService.setAutoFavoriteOnChat(true),
  ),
  HealthRule(
    id: 'app_jump_to_oldest_unread',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Chats open at the latest message',
    why:
        'A chat with unread messages opens at the newest one, so you can miss '
        'the ones before it. Jump to oldest unread starts you at the first one '
        'you have not read.',
    check: (ctx) async => !ctx.app.jumpToOldestUnread,
    fix: HealthFix.apply,
    fixDescription: 'Turn on jump to oldest unread.',
    apply: (ctx) => ctx.settingsService.setJumpToOldestUnread(true),
  ),
  HealthRule(
    id: 'app_sender_name_colors',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Channel senders all share one name color',
    why:
        'Giving each sender their own color makes it easier to see who said '
        'what in a busy channel.',
    check: (ctx) async => !ctx.app.senderNameColors,
    fix: HealthFix.apply,
    fixDescription: 'Turn on colorful sender names.',
    apply: (ctx) => ctx.settingsService.setSenderNameColors(true),
  ),
  HealthRule(
    id: 'app_text_formatting',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Text formatting is off',
    why:
        'Messages show the raw characters, such as **bold**, instead of the '
        'formatting they stand for.',
    check: (ctx) async => !ctx.app.showTextFormatting,
    fix: HealthFix.apply,
    fixDescription: 'Turn text formatting on.',
    apply: (ctx) => ctx.settingsService.setShowTextFormatting(true),
  ),

  // --------------------------------------------------- App: connection -----
  HealthRule(
    id: 'app_auto_connect',
    enabled: false,
    severity: HealthSeverity.tip,
    title: 'Auto-connect to the last radio is off',
    why: '',
    check: (ctx) async => !ctx.app.autoConnectLastDevice,
    fix: HealthFix.apply,
    fixDescription: 'Turn on auto-connect to the last radio.',
    apply: (ctx) => ctx.settingsService.setAutoConnectLastDevice(true),
  ),
  HealthRule(
    id: 'app_incremental_sync',
    enabled: true,
    severity: HealthSeverity.tip,
    title: 'Contacts download in full on every connect',
    why:
        'Each time the app connects it downloads your whole contact list, which '
        'can take 25 seconds with a few hundred contacts. Incremental sync asks '
        'only for what changed, so reconnecting is much faster.',
    check: (ctx) async => !ctx.app.incrementalContactSync,
    fix: HealthFix.apply,
    fixDescription: 'Turn on incremental contact sync.',
    apply: (ctx) => ctx.settingsService.setIncrementalContactSync(true),
    notes:
        'On by default for new installs (owner, 2026-10-31). Existing users '
        'keep their saved value, so this tip reaches the ones who have it off.',
  ),

  // --------------------------------------------------- App: Pathfinder -----
  HealthRule(
    id: 'app_pathfinder',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'Pathfinder is off',
    why:
        'Your radio remembers one route to each contact and floods the whole '
        'mesh when that route fails. Pathfinder learns routes from everything '
        'the radio hears, tries its best ones first, and floods only as a last '
        'resort. It needs some hours of listening before it helps, and until it '
        'has learned a route, messages to that contact flood.',
    check: (ctx) async => !ctx.app.pathGraphEnabled,
    fix: HealthFix.apply,
    fixDescription: 'Turn Pathfinder on.',
    apply: (ctx) => ctx.settingsService.setPathGraphEnabled(true),
    notes:
        'On by default for new installs (owner, 2026-10-31). Existing users '
        'keep their saved value, so this reaches the ones who have it off.',
  ),

  // ------------------------------------------------------ App: general -----
  HealthRule(
    id: 'app_debug_log',
    enabled: true,
    severity: HealthSeverity.suggestion,
    title: 'App debug log is on',
    why:
        'The debug log keeps up to 20,000 lines in memory. Turn it off unless '
        'you are chasing a problem.',
    check: (ctx) async => ctx.app.appDebugLogEnabled,
    fix: HealthFix.apply,
    fixDescription: 'Turn the debug log off.',
    apply: (ctx) => ctx.settingsService.setAppDebugLogEnabled(false),
  ),
  HealthRule(
    id: 'app_battery_sleep',
    enabled: true,
    severity: HealthSeverity.problem,
    title: 'Your phone may put MeshTrax to sleep',
    why:
        'This phone can stop apps in the background to save battery, which '
        'cuts off your radio. Messages can stop arriving when the screen is '
        'off.',
    check: (ctx) async => BatterySleepService.shouldWarn(),
    fix: HealthFix.ask,
    dialog: HealthDialog.batterySettings,
    notes: 'Android only.',
  ),
  // theme, languageOverride, unitSystem, battery chemistry: taste or
  // per-device; no rule.
];
