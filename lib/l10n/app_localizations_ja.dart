// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'チャット';

  @override
  String get chats_title => 'チャット';

  @override
  String get newChat_title => '連絡先を選択';

  @override
  String newChat_contactCount(int count) {
    return '連絡先$count件';
  }

  @override
  String get newChat_newContact => '新しい連絡先';

  @override
  String get newChat_newChannel => '新しいチャンネル';

  @override
  String get newChat_myContacts => '自分の連絡先';

  @override
  String get newChat_discovered => '発見済み';

  @override
  String get repeaters_title => 'リピーターの管理';

  @override
  String get nav_contacts => '連絡先';

  @override
  String get nav_channels => 'チャンネル';

  @override
  String get nav_map => '地図';

  @override
  String get common_cancel => 'キャンセル';

  @override
  String get common_syncing_device_info => 'デバイス情報を読み込み中...';

  @override
  String get common_syncing_contacts => '連絡先を読み込み中...';

  @override
  String get common_syncing_channels => 'チャンネルを読み込み中...';

  @override
  String get common_syncing_messages => 'メッセージを読み込み中...';

  @override
  String get common_ok => '了解';

  @override
  String get common_connect => '接続する';

  @override
  String get common_unknownDevice => '不明なデバイス';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '削除';

  @override
  String get common_deleteAll => 'すべて削除';

  @override
  String get common_close => '閉じる';

  @override
  String get common_edit => '編集';

  @override
  String get common_add => '追加';

  @override
  String get common_settings => '設定';

  @override
  String get common_disconnect => '切断する';

  @override
  String get common_connected => '接続されている';

  @override
  String get common_disconnected => '切断';

  @override
  String get common_connectionLost => '接続が切れました。再接続中...';

  @override
  String get common_reconnecting => '再接続中...';

  @override
  String get common_create => '作成する';

  @override
  String get common_continue => '続き';

  @override
  String get common_share => '共有する';

  @override
  String get common_copy => 'コピー';

  @override
  String get common_retry => '再試';

  @override
  String get common_hide => '隠す';

  @override
  String get common_remove => '削除';

  @override
  String get common_enable => '有効化する';

  @override
  String get common_disable => '無効化する';

  @override
  String get common_reboot => '再起動';

  @override
  String get common_loading => '読み込み中...';

  @override
  String get common_notAvailable => '—';

  @override
  String common_voltageValue(String volts) {
    return '$volts V';
  }

  @override
  String common_percentValue(int percent) {
    return '$percent%';
  }

  @override
  String get scanner_title => 'MeshCore オープン';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'ブルートゥース';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'TCP を使用して接続';

  @override
  String get tcpHostLabel => 'IPアドレス';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => '港';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'エンドポイントを入力し、接続する';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return '$endpoint への接続中...';
  }

  @override
  String get tcpErrorHostRequired => 'IPアドレスが必要です。';

  @override
  String get tcpErrorPortInvalid => 'ポート番号は1から65535の範囲で指定してください。';

  @override
  String get tcpErrorUnsupported => 'このプラットフォームでは、TCP 転送はサポートされていません。';

  @override
  String get tcpErrorTimedOut => 'TCP 接続がタイムアウトしました。';

  @override
  String tcpConnectionFailed(String error) {
    return 'TCP接続に失敗しました：$error';
  }

  @override
  String get usbScreenTitle => 'USB経由で接続';

  @override
  String get usbScreenSubtitle => '検出されたシリアルデバイスを選択し、MeshCoreノードに直接接続してください。';

  @override
  String get usbScreenStatus => 'USBデバイスを選択する';

  @override
  String get usbScreenNote =>
      'USBシリアルポートは、サポートされているAndroidデバイスおよびデスクトッププラットフォームで利用可能です。';

  @override
  String get usbScreenEmptyState =>
      'USBデバイスが見つかりませんでした。「別のUSBデバイスを接続して、再度確認してください。」';

  @override
  String get usbErrorPermissionDenied => 'USBへのアクセス許可が拒否されました。';

  @override
  String get usbErrorDeviceMissing => '選択されたUSBデバイスは、もう利用できません。';

  @override
  String get usbErrorInvalidPort => '有効なUSBデバイスを選択してください。';

  @override
  String get usbErrorBusy => '別のUSB接続の要求がすでに処理中です。';

  @override
  String get usbErrorNotConnected => 'USBデバイスは接続されていません。';

  @override
  String get usbErrorOpenFailed => '選択したUSBデバイスを開くことができません。';

  @override
  String get usbErrorConnectFailed => '選択したUSBデバイスへの接続に失敗しました。';

  @override
  String get usbErrorUnsupported => 'このプラットフォームでは、USBシリアル通信はサポートされていません。';

  @override
  String get usbErrorNativeLibraryMissing =>
      'このビルドにはUSBシリアルライブラリが含まれていないため、USBデバイスを開けません。MeshTraxを再インストールするか、このビルドの不具合を報告してください。';

  @override
  String get usbErrorBrowserUnsupported =>
      'このブラウザはWeb Serialに対応していません。HTTPS（またはlocalhost）でChromeかEdgeを使ってください。';

  @override
  String get usbErrorAlreadyActive => 'USB接続はすでに確立されています。';

  @override
  String get usbErrorNoDeviceSelected => 'USBデバイスは選択されていません。';

  @override
  String get usbErrorPortClosed => 'USB接続は確立されていません。';

  @override
  String get usbErrorConnectTimedOut =>
      '接続がタイムアウトしました。デバイスにUSBコンパニオンファームウェアがインストールされていることを確認してください。';

  @override
  String get usbFallbackDeviceName => 'ウェブシリアルデバイス';

  @override
  String get usbStatus_notConnected => 'USBデバイスを選択する';

  @override
  String get usbStatus_connecting => 'USBデバイスへの接続中...';

  @override
  String get usbStatus_searching => 'USBデバイスを検索中...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB接続に失敗しました：$error';
  }

  @override
  String get scanner_scanning => 'デバイスをスキャン中...';

  @override
  String get scanner_connecting => '接続中...';

  @override
  String get scanner_disconnecting => '切断...';

  @override
  String get scanner_notConnected => '接続されていない';

  @override
  String scanner_connectedTo(String deviceName) {
    return '$deviceName に接続';
  }

  @override
  String get scanner_showAllDevices => 'すべてのBluetoothデバイスを表示';

  @override
  String get scanner_showMeshCoreOnly => 'MeshCore無線機のみ表示';

  @override
  String get scanner_radioNotResponding =>
      '無線機が応答しません。ペアリングが必要な場合があります。Bluetooth設定を開いて無線機を追加し、PINを入力してから、もう一度お試しください。';

  @override
  String get scanner_pairingFailed =>
      'Bluetoothのペアリングがキャンセルされたか、失敗しました。ほかの機器（スマートフォンなど）が無線機に接続していないことを確認し、もう一度試してPINを入力してください。';

  @override
  String scanner_connectionFailed(String error) {
    return '接続に失敗しました：$error';
  }

  @override
  String get scanner_stop => '停止';

  @override
  String get scanner_scan => 'スキャン';

  @override
  String get scanner_scanFromImage => '画像からスキャン';

  @override
  String get scanner_noQrFoundInImage => '画像に有効なQRコードが見つかりません';

  @override
  String get scanner_bluetoothOff => 'Bluetooth はオフになっています';

  @override
  String get scanner_bluetoothOffMessage => 'Bluetoothを有効にして、デバイスを検索してください。';

  @override
  String get scanner_chromeRequired => 'Chrome ブラウザが必須です';

  @override
  String get scanner_chromeRequiredMessage =>
      'このWebアプリケーションは、Bluetooth機能を利用するために、Google ChromeまたはChromiumベースのブラウザが必要です。';

  @override
  String get scanner_enableBluetooth => 'Bluetoothを有効にする';

  @override
  String get device_quickSwitch => '素早い切り替え';

  @override
  String get device_meshcore => 'メッシュコア';

  @override
  String get settings_title => '設定';

  @override
  String get settings_deviceInfo => 'デバイス情報';

  @override
  String get settings_appSettings => 'アプリ設定';

  @override
  String get settings_appSettingsSubtitle => '通知、メッセージング、および地図の表示設定';

  @override
  String get settings_nodeSettings => 'ノード設定';

  @override
  String get settings_nodeName => 'ノード名';

  @override
  String get settings_nodeNameNotSet => '設定されていない';

  @override
  String get settings_nodeNameHint => 'ノード名を入力してください';

  @override
  String get settings_nodeNameUpdated => '氏名変更';

  @override
  String get settings_radioSettings => 'ラジオ設定';

  @override
  String get settings_radioSettingsSubtitle => '周波数、電力、スプレッドファクター';

  @override
  String get settings_radioSettingsUpdated => 'ラジオの設定が更新されました';

  @override
  String get settings_location => '場所';

  @override
  String get settings_locationSubtitle => 'GPS 座標';

  @override
  String get settings_locationUpdated => '場所とGPS設定が更新されました';

  @override
  String get settings_locationBothRequired => '緯度と経度をそれぞれ入力してください。';

  @override
  String get settings_locationInvalid => '無効な緯度または経度。';

  @override
  String get settings_locationGPSEnable => 'GPS機能有効';

  @override
  String get settings_locationGPSEnableSubtitle => 'GPSが自動的に位置情報を更新できるようにする。';

  @override
  String get settings_latitude => '緯度';

  @override
  String get settings_longitude => '経度';

  @override
  String get settings_contactSettings => '連絡設定';

  @override
  String get settings_contactSettingsSubtitle => '連絡先を追加する設定';

  @override
  String get settings_privacyMode => 'プライバシーモード';

  @override
  String get settings_privacyModeSubtitle => '広告に名前/場所を記載しない';

  @override
  String get settings_privacyModeToggle =>
      'プライバシーモードをオンにして、広告に表示される名前や場所を非表示にします。';

  @override
  String get settings_privacyModeEnabled => 'プライバシーモードが有効になっています';

  @override
  String get settings_privacyModeDisabled => 'プライバシーモードは無効化されています';

  @override
  String get settings_privacy => 'プライバシー設定';

  @override
  String get settings_privacySubtitle => '共有する情報の内容を管理する。';

  @override
  String get settings_privacySettingsDescription =>
      '自分のデバイスが他の人に共有する情報を選択してください。';

  @override
  String get settings_denyAll => 'すべてを否定';

  @override
  String get settings_allowByContact => '連絡先を明示するオプション';

  @override
  String get settings_allowAll => 'すべて許可';

  @override
  String get settings_telemetryBaseMode => 'テレメトリ基本モード';

  @override
  String get settings_telemetryLocationMode => 'テレメトリ位置特定モード';

  @override
  String get settings_telemetryEnvironmentMode => 'テレメトリ環境モード';

  @override
  String get settings_advertLocation => '広告掲載場所';

  @override
  String get settings_advertLocationSubtitle => '広告に場所を記載してください。';

  @override
  String get settings_multiAck => '複数のACK（応答）';

  @override
  String get settings_telemetryModeUpdated => 'テレメトリモードが更新されました';

  @override
  String get settings_actions => '行動';

  @override
  String get settings_sendAdvertisement => '広告を送信する';

  @override
  String get settings_sendAdvertisementSubtitle => '現在、放送での活動';

  @override
  String get settings_advertisementSent => '広告が送信されました';

  @override
  String get settings_syncTime => '同期時間';

  @override
  String get settings_syncTimeSubtitle => 'デバイスの時刻を、携帯電話の時刻に合わせる';

  @override
  String get settings_timeSynchronized => '時間同期';

  @override
  String get settings_refreshContacts => '連絡先を更新する';

  @override
  String get settings_refreshContactsSubtitle => 'デバイスから連絡先リストを再読み込みする';

  @override
  String get settings_rebootDevice => 'デバイスを再起動する';

  @override
  String get settings_rebootDeviceSubtitle => 'MeshCore デバイスを再起動する';

  @override
  String get settings_rebootDeviceConfirm =>
      '本当にデバイスを再起動したいですか？ その場合、接続が切断されます。';

  @override
  String get settings_debug => 'デバッグ';

  @override
  String get settings_bleDebugLog => 'BLE デバッグログ';

  @override
  String get settings_bleDebugLogSubtitle => 'BLEコマンド、応答、および生のデータ';

  @override
  String get settings_appDebugLog => 'アプリケーションのデバッグログ';

  @override
  String get settings_appDebugLogSubtitle => 'アプリケーションのデバッグメッセージ';

  @override
  String get settings_exportDatabase => 'メッセージデータベースをエクスポート';

  @override
  String get settings_exportDatabaseSubtitle =>
      'デバッグ用の全チャットと連絡先のコピー。他人と共有しないでください。';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'データベースの保存先: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'エクスポートに失敗しました: $error';
  }

  @override
  String get settings_about => '概要';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax $version版';
  }

  @override
  String get settings_aboutLegalese => '2026年のMeshCoreオープンソースプロジェクト';

  @override
  String get settings_aboutDescription =>
      'MeshCore LoRaメッシュネットワークデバイス用の、オープンソースのFlutterクライアント。';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS 標高データ：Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => '名前';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'ステータス';

  @override
  String get settings_infoBattery => 'バッテリー';

  @override
  String get settings_infoPublicKey => '公開鍵';

  @override
  String get settings_infoContactsCount => '連絡先数';

  @override
  String get settings_infoChannelCount => 'チャンネル数';

  @override
  String get settings_presets => 'プリセット';

  @override
  String get settings_frequency => '周波数 (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => '無効な周波数 (300-2500 MHz)';

  @override
  String get settings_bandwidth => '帯域幅';

  @override
  String get settings_spreadingFactor => '伝播係数';

  @override
  String get settings_codingRate => 'コーディング速度';

  @override
  String get settings_txPower => 'TX 信号電力 (dBm)';

  @override
  String get settings_txPowerInvalid => '無効な送信電力';

  @override
  String get settings_clientRepeat => 'オフグリッド（電力網から孤立した状態）の繰り返し';

  @override
  String get settings_clientRepeatSubtitle =>
      'このデバイスが、他のデバイスに対してメッシュパケットを繰り返し送信できるようにする。';

  @override
  String get settings_clientRepeatFreqWarning =>
      'オフグリッドでの再送には、433MHz、869MHz、または918MHzの周波数が必要です。';

  @override
  String settings_error(String message) {
    return 'エラー：$message';
  }

  @override
  String get appSettings_title => 'アプリ設定';

  @override
  String get appSettings_appearance => '外観';

  @override
  String get appSettings_theme => 'テーマ';

  @override
  String get appSettings_themeSystem => 'システムデフォルト';

  @override
  String get appSettings_themeLight => '光';

  @override
  String get appSettings_themeDark => '暗い';

  @override
  String get appSettings_language => '言語';

  @override
  String get appSettings_languageSystem => 'システムデフォルト';

  @override
  String get appSettings_languageEn => '英語';

  @override
  String get appSettings_languageFr => 'フランス語';

  @override
  String get appSettings_languageEs => 'スペイン語';

  @override
  String get appSettings_languageDe => 'ドイツ語';

  @override
  String get appSettings_languagePl => 'ポーランド語';

  @override
  String get appSettings_languageSl => 'スロベニア語';

  @override
  String get appSettings_languagePt => 'ポルトガル語';

  @override
  String get appSettings_languageIt => 'イタリア語';

  @override
  String get appSettings_languageZh => '中国語';

  @override
  String get appSettings_languageSv => 'スウェーデン語';

  @override
  String get appSettings_languageNl => 'オランダ語';

  @override
  String get appSettings_languageSk => 'スロベニア語';

  @override
  String get appSettings_languageBg => 'ブルガリア語';

  @override
  String get appSettings_languageRu => 'ロシア語';

  @override
  String get appSettings_languageUk => 'ウクライナ語';

  @override
  String get appSettings_enableMessageTracing => 'メッセージ追跡機能を有効にする';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'メッセージに関する詳細な経路およびタイミングに関するメタデータを表示する';

  @override
  String get appSettings_senderNameColors => '送信者名を色分け';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'チャンネルの送信者ごとに名前の色を変えます。オフにすると全員がテーマの色になります。';

  @override
  String get appSettings_showTextFormatting => '文字の書式を表示';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'メッセージ内のMarkdown：**太字**、*斜体*、||ネタバレ||、見出し、リンク。ほかのMeshCoreアプリでは記号がそのまま表示されます。';

  @override
  String get appSettings_notifications => '通知';

  @override
  String get appSettings_enableNotifications => '通知を有効にする';

  @override
  String get appSettings_enableNotificationsSubtitle => 'メッセージや広告に関する通知を受け取る';

  @override
  String get appSettings_notificationPermissionDenied => '通知の許可が拒否されました';

  @override
  String get appSettings_notificationsEnabled => '通知機能が有効になっています';

  @override
  String get appSettings_notificationsDisabled => '通知が無効化されています';

  @override
  String get appSettings_messageNotifications => 'メッセージ通知';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      '新しいメッセージを受信した際に、通知を表示する';

  @override
  String get appSettings_channelMessageNotifications => 'チャネルメッセージの通知';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'チャンネルからのメッセージを受信した際に、通知を表示する';

  @override
  String get appSettings_advertisementNotifications => '広告通知';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      '新しいノードが発見された場合に通知を表示する';

  @override
  String get appSettings_messaging => 'メッセージング';

  @override
  String get appSettings_maxMessageRetries => '最大メッセージ再試行回数';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'メッセージを「失敗」とマークするまでの、再試行回数';

  @override
  String get appSettings_maxChannelMessageRetries => 'チャンネルメッセージの最大再試行回数';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      '中継が1つ以上聞こえるまで、この回数だけ再試行します';

  @override
  String get appSettings_battery => 'バッテリー';

  @override
  String get appSettings_batteryChemistry => '電池の化学';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return '$deviceName 単位';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst => 'デバイスを選択するために接続する';

  @override
  String get appSettings_batteryNmc => '18650型 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => '地図の表示';

  @override
  String get appSettings_showRepeaters => '繰り返し再生機能';

  @override
  String get appSettings_showRepeatersSubtitle => '地図上にリピーターノードを表示する';

  @override
  String get appSettings_showChatNodes => 'チャットノードの表示';

  @override
  String get appSettings_showChatNodesSubtitle => '地図上にチャットノードを表示する';

  @override
  String get appSettings_showOtherNodes => '他のノードを表示する';

  @override
  String get appSettings_showOtherNodesSubtitle => '地図上に、他のノードの種類を表示する';

  @override
  String get appSettings_timeFilter => '時間フィルター';

  @override
  String get appSettings_timeFilterShowAll => 'すべてのノードを表示する';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return '過去 $hours 時間のノードを表示する';
  }

  @override
  String get appSettings_mapTimeFilter => '地図の表示期間を絞り込む';

  @override
  String get appSettings_showNodesDiscoveredWithin => '以下の範囲内で発見されたノードを表示する：';

  @override
  String get appSettings_allTime => 'すべての期間';

  @override
  String get appSettings_lastHour => '直前の';

  @override
  String get appSettings_last6Hours => '過去6時間';

  @override
  String get appSettings_last24Hours => '過去24時間';

  @override
  String get appSettings_lastWeek => '先週';

  @override
  String get appSettings_unitsTitle => '単位';

  @override
  String get appSettings_unitsMetric => 'メートル (m) / キロメートル (km)';

  @override
  String get appSettings_unitsImperial => '帝国 (フィート / マイル)';

  @override
  String get appSettings_debugCard => 'デバッグ';

  @override
  String get appSettings_appDebugLogging => 'アプリケーションのデバッグ用ログ';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'ログアプリのデバッグメッセージ（トラブルシューティング用）';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'アプリケーションのデバッグ用ログ機能が有効になっています。';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'アプリケーションのデバッグログが無効化されています。';

  @override
  String get appSettings_incrementalContactSync => '連絡先の差分同期';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      '再接続時に、前回から変わった連絡先だけを無線機に問い合わせます';

  @override
  String get contacts_title => '連絡先';

  @override
  String get contacts_noContacts => '現時点では、連絡先はまだありません。';

  @override
  String get contacts_shareMyQrCode => '自分のQRコードを共有';

  @override
  String get contacts_shareQrCodeDesc => 'ほかの人がスキャンして、あなたを連絡先に追加できます';

  @override
  String get contacts_contactsWillAppear => 'デバイスが広告を行う際に、連絡先が表示されます。';

  @override
  String get contacts_unread => '未読';

  @override
  String get contacts_searchContactsNoNumber => '連絡先を検索...';

  @override
  String contacts_searchContacts(int number, String str) {
    return '$number件の$strに関する連絡先を検索...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return '$number件の$strを検索...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return '$number件の$strに関するユーザーを検索する...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return '$number $str までの検索...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return '$number $str 部屋のサーバーを検索する...';
  }

  @override
  String get contacts_noUnreadContacts => '未読の連絡先はありません';

  @override
  String get contacts_noContactsFound => '連絡先またはグループは見つかりませんでした。';

  @override
  String get contacts_deleteContact => '連絡先を削除';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return '$contactNameを削除してもよろしいですか？';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return '連絡先$contactNameを削除しました。';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return '$contactNameを削除できませんでした。';
  }

  @override
  String get contacts_noMatchingContacts => 'フィルターに一致する連絡先はありません。';

  @override
  String contacts_removeConfirm(String contactName) {
    return '$contactName を連絡先から削除しますか？';
  }

  @override
  String get contacts_manageRepeater => 'リピーターの管理';

  @override
  String get contacts_manageRoom => 'ルームサーバーの管理';

  @override
  String get contacts_roomLogin => 'ルームサーバーへのログイン';

  @override
  String get contacts_openChat => '自由な会話';

  @override
  String get contacts_editGroup => '編集グループ';

  @override
  String get contacts_deleteGroup => 'グループを削除';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '$groupName を削除しますか？';
  }

  @override
  String get contacts_newGroup => '新しいグループ';

  @override
  String get contacts_groupName => 'グループ名';

  @override
  String get contacts_groupNameRequired => 'グループ名が必須です';

  @override
  String get contacts_groupNameReserved => 'このグループ名はすでに使用されています。';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'グループ「$name」はすでに存在しています';
  }

  @override
  String get contacts_filterContacts => '連絡先をフィルタリングする…';

  @override
  String get contacts_noContactsMatchFilter => '指定された条件に合致する連絡先は見つかりませんでした。';

  @override
  String get contacts_noMembers => 'メンバーはいない';

  @override
  String get contacts_lastSeenNow => '最近';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '～$minutes 分';
  }

  @override
  String get contacts_lastSeenHourAgo => '約1時間';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '～ $hours 時間';
  }

  @override
  String get contacts_lastSeenDayAgo => '～1日';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '～$days日間';
  }

  @override
  String get contact_info => '連絡先';

  @override
  String get contact_settings => '連絡設定';

  @override
  String get contact_telemetry => 'テレメトリー';

  @override
  String get contact_lastSeen => '最後に確認された場所';

  @override
  String get contact_clearChat => 'チャットのクリア';

  @override
  String get contact_teleBase => 'テレメトリ基地';

  @override
  String get contact_teleBaseSubtitle => 'バッテリー残量と基本的なテレメトリーの共有を許可する';

  @override
  String get contact_teleLoc => 'テレメトリの場所';

  @override
  String get contact_teleLocSubtitle => '位置情報共有を許可する';

  @override
  String get contact_teleEnv => 'テレメトリ環境';

  @override
  String get contact_teleEnvSubtitle => '環境センサーのデータを共有することを許可する';

  @override
  String get contacts_publicKey => '公開鍵';

  @override
  String get channels_title => 'チャンネル';

  @override
  String get channels_noChannelsConfigured => '設定されたチャンネルがありません';

  @override
  String get channels_addPublicChannel => 'パブリックチャンネルを追加する';

  @override
  String get channels_searchChannels => '検索オプション...';

  @override
  String get channels_noChannelsFound => 'チャンネルが見つかりませんでした';

  @override
  String channels_channelIndex(int index) {
    return 'チャンネル $index';
  }

  @override
  String get channels_hashtagChannel => 'ハッシュタグチャンネル';

  @override
  String get channels_public => '一般の人々';

  @override
  String get channels_private => '個人の';

  @override
  String get channels_publicChannel => '一般チャンネル';

  @override
  String get channels_privateChannel => 'プライベートチャンネル';

  @override
  String get channels_editChannel => 'チャンネルを編集する';

  @override
  String get channels_shareChannel => 'チャンネルを共有';

  @override
  String get channels_shareChannelInstructions =>
      'QRコードをスキャンしてチャンネルを追加します。\nメニュー → チャンネルを追加 → QRコードをスキャンする';

  @override
  String get channels_secretKey => '秘密鍵';

  @override
  String get channels_meshcoreUri => 'MeshCore URI';

  @override
  String get channels_shareChannelQr => 'チャンネルのQRコードをスキャン';

  @override
  String get channels_shareChannelWarning =>
      '警告：このQRコードをスキャンした人は誰でも、このチャンネルにアクセスできます。';

  @override
  String get channels_muteChannel => 'ミュート機能';

  @override
  String get channels_unmuteChannel => 'ミュートを解除する';

  @override
  String get channels_deleteChannel => 'チャンネルを削除する';

  @override
  String channels_deleteChannelConfirm(String name) {
    return '$name を削除しますか？ これは取り消すことができません。';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'チャンネル「$name」の削除に失敗しました。';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'チャンネル「$name」が削除されました';
  }

  @override
  String get channels_addChannel => 'チャンネルを追加';

  @override
  String get channels_channelIndexLabel => 'チャンネルインデックス';

  @override
  String get channels_channelName => 'チャンネル名';

  @override
  String get channels_usePublicChannel => 'パブリックチャンネルを使用する';

  @override
  String get channels_standardPublicPsk => '標準的な公用 PSK';

  @override
  String get channels_pskHex => 'PSK (ヘックス)';

  @override
  String get channels_generateRandomPsk => 'ランダムなPSK（正交符号分割変調）を生成する';

  @override
  String get channels_enterChannelName => 'チャンネル名を入力してください';

  @override
  String get channels_pskMustBe32Hex => 'PSKは32桁の16進数で構成されている必要があります。';

  @override
  String get channels_addChannelConfirmation => '次のチャンネルを追加しますか？';

  @override
  String get channels_channelAddedSuccess => 'チャンネルを追加しました。';

  @override
  String get channels_noAvailableChannelSlots => '空いているチャンネル枠がありません。';

  @override
  String get appSettings_mentionNotifications => 'メンション通知';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      '誰かがあなたにメンションまたは返信したとき — ミュート中のチャンネルでも';

  @override
  String notification_mentionIn(String channelName) {
    return '$channelNameでメンションされました';
  }

  @override
  String channels_channelAdded(String name) {
    return 'チャンネル「$name」を追加';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'チャンネル $index の編集';
  }

  @override
  String get channels_smazCompression => 'SMAZ 圧縮';

  @override
  String channels_channelUpdated(String name) {
    return 'チャンネル「$name」が更新されました';
  }

  @override
  String get channels_publicChannelAdded => 'パブリックチャンネルが追加されました';

  @override
  String get channels_sortBy => '並び替え';

  @override
  String get channels_sortManual => 'マニュアル';

  @override
  String get channels_sortAZ => 'AからZ';

  @override
  String get channels_sortLatestMessages => '最新のメッセージ';

  @override
  String get channels_sortUnread => '未読';

  @override
  String get channels_createPrivateChannel => 'プライベートチャンネルを作成する';

  @override
  String get channels_createPrivateChannelDesc => '秘密鍵を使用して保護されています。';

  @override
  String get channels_joinPrivateChannel => 'プライベートチャンネルに参加する';

  @override
  String get channels_joinPrivateChannelDesc => '手動で秘密のキーを入力する。';

  @override
  String get channels_joinPublicChannel => '公開チャンネルに参加する';

  @override
  String get channels_joinPublicChannelDesc => 'このチャンネルには、誰でも参加できます。';

  @override
  String get channels_joinHashtagChannel => 'ハッシュタグチャンネルに参加する';

  @override
  String get channels_joinHashtagChannelDesc => '誰でもハッシュタグチャンネルに参加できます。';

  @override
  String get channels_scanQrCode => 'QRコードをスキャンする';

  @override
  String get channels_scanQrCodeComingSoon => '近日公開';

  @override
  String get channels_enterHashtag => 'ハッシュタグを入力してください';

  @override
  String get channels_hashtagHint => '例：#チーム';

  @override
  String get chat_noMessages => 'まだメッセージは届いていません';

  @override
  String get chat_sendMessage => 'メッセージを送信する';

  @override
  String chat_sendMessageTo(String contactName) {
    return '$contactName へのメッセージを送信する';
  }

  @override
  String get chat_sendMessageToStart => '開始するためにメッセージを送信してください';

  @override
  String get chat_originalMessageNotFound => '元のメッセージが見つかりませんでした';

  @override
  String chat_replyingTo(String name) {
    return '$name への返信';
  }

  @override
  String chat_replyTo(String name) {
    return '$nameへの返信';
  }

  @override
  String get chat_location => '場所';

  @override
  String get common_copiedToClipboard => 'クリップボードにコピーしました';

  @override
  String get common_copyToClipboard => 'クリップボードにコピー';

  @override
  String get contacts_copyContactToClipboard => '自分の連絡先をクリップボードにコピー';

  @override
  String get chat_typeMessage => 'メッセージを入力してください…';

  @override
  String get chat_searchMessages => 'メッセージを検索';

  @override
  String get chat_searchNoMatches => '一致なし';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'メッセージが長すぎる（$maxBytes バイトを超える）。';
  }

  @override
  String get chat_messageCopied => 'メッセージがコピーされました';

  @override
  String get chat_messageDeleted => 'メッセージは削除されました';

  @override
  String get chat_sendGif => 'GIFを送信する';

  @override
  String get chat_reply => '返信';

  @override
  String get chat_newMessages => '新着メッセージ';

  @override
  String get chat_addReaction => '反応を追加';

  @override
  String get chat_mention => 'メンション';

  @override
  String get dmChannel_menuLabel => 'ダイレクトメッセージ';

  @override
  String dmChannel_pickerTitle(String name) {
    return '$nameにDMを送信';
  }

  @override
  String get dmChannel_pickerHint => '鍵と最終確認時刻を確かめてください — 同じ名前が複数あることがあります。';

  @override
  String get dmChannel_warningTitle => '本当にこの人ですか？';

  @override
  String get dmChannel_warningBody =>
      'チャンネルでの名前は本人が自由に決めるもので、誰でもまねできます。大事な用件なら、まず別の方法でこの連絡先の公開鍵を確認してください。';

  @override
  String get dmChannel_dontShowAgain => '今後表示しない';

  @override
  String get batterySleep_title => 'MeshTraxを動かし続ける';

  @override
  String get batterySleep_bodySamsung =>
      'Samsungのスマートフォンはバッテリー節約のためにアプリをスリープさせ、無線機との接続が切れてしまいます。設定 → アプリ → MeshTrax → バッテリーを開き、「制限なし」を選んでください。また、バッテリー → バックグラウンドでの使用制限で、MeshTraxが「スリープ中のアプリ」や「ディープスリープ中のアプリ」に入っていないことも確認してください。';

  @override
  String get batterySleep_bodyGeneric =>
      'スマートフォンがバッテリー節約のためにMeshTraxをバックグラウンドで停止し、無線機との接続が切れることがあります。バッテリー設定を開き、MeshTraxを「制限なし」（または「無制限」）に設定してください。機種によっては、MeshTraxの「自動起動」もオンにする必要があります。';

  @override
  String get batterySleep_openSettings => '設定を開く';

  @override
  String get batterySleep_notNow => '今はしない';

  @override
  String get batterySleep_settingsTile => 'MeshTraxをバックグラウンドで動かし続ける';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'スマートフォンの省電力機能がMeshTraxをスリープさせないようにします';

  @override
  String dmChannel_noMatchTitle(String name) {
    return '$nameにはまだDMを送れません';
  }

  @override
  String get dmChannel_noMatchBody =>
      '相手の鍵がまだありません。また、相手が返信するにはあなたの鍵が必要です — 鍵は広告でしか伝わりません。「自分の広告を送信」を押すと、ここからあなたの広告を送信します。「チャンネルで依頼」を押すと、依頼文がメッセージ欄に入るので、それを送信してください。';

  @override
  String get dmChannel_askInChannel => 'チャンネルで依頼';

  @override
  String get dmChannel_sendMyAdvert => '自分の広告を送信';

  @override
  String get dmChannel_askText => 'DMを送りたいので、広告を送信してください';

  @override
  String get dmChannel_watching => '相手の広告を待っています — 届いたらここでお知らせします。';

  @override
  String dmChannel_advertHeard(String name) {
    return '$nameに連絡できるようになりました';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'ズームレベル';

  @override
  String get common_reset => 'リセット';

  @override
  String get chat_reactionsTitle => 'リアクション';

  @override
  String get chat_reactionUnknownSender => '不明';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$senderさんが、このチャットにないメッセージにリアクションしました';
  }

  @override
  String get chat_me => '私';

  @override
  String get emojiCategorySmileys => '笑顔の絵文字';

  @override
  String get emojiCategoryGestures => '身振り、動作';

  @override
  String get emojiCategoryHearts => '心';

  @override
  String get emojiCategoryObjects => '対象物';

  @override
  String get gifPicker_title => 'GIF を選択してください';

  @override
  String get gifPicker_searchHint => 'GIFの検索...';

  @override
  String get gifPicker_poweredBy => 'GIPHYによる提供';

  @override
  String get gifPicker_noGifsFound => 'GIF形式のファイルは見つかりませんでした';

  @override
  String get gifPicker_failedLoad => 'GIFファイルの読み込みに失敗しました';

  @override
  String get gifPicker_failedSearch => 'GIFファイルの検索に失敗しました';

  @override
  String get gifPicker_noInternet => 'インターネット接続なし';

  @override
  String get debugLog_appTitle => 'アプリケーションのデバッグログ';

  @override
  String get debugLog_bleTitle => 'BLE デバッグログ';

  @override
  String get debugLog_copyLog => '記録';

  @override
  String get debugLog_saveLog => 'ログをファイルに保存';

  @override
  String get debugLog_saved => 'ログを保存しました';

  @override
  String get debugLog_saveCancelled => '保存をキャンセルしました';

  @override
  String get debugLog_filterAll => 'すべて';

  @override
  String get debugLog_filterWarnings => '警告';

  @override
  String get debugLog_filterErrors => 'エラー';

  @override
  String get debugLog_clearLog => '詳細なログ';

  @override
  String get debugLog_copied => 'デバッグログをコピー';

  @override
  String get debugLog_bleCopied => 'BLEログのコピー';

  @override
  String get debugLog_noEntries => 'デバッグログはまだ生成されていません';

  @override
  String get debugLog_enableInSettings => 'アプリのデバッグログを有効にするには、設定から操作してください。';

  @override
  String get debugLog_frames => 'フレーム';

  @override
  String get debugLog_rawLogRx => '生のログ-RX';

  @override
  String get debugLog_noBleActivity => '現時点では、BLE関連の活動は行われていません。';

  @override
  String debugFrame_length(int count) {
    return 'フレーム長: $count バイト';
  }

  @override
  String debugFrame_command(String value) {
    return 'コマンド: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'テキストメッセージ用フレーム：';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- 宛先公開鍵: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- タイムスタンプ: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- フラグ: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- テキストの種類: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI（コマンドラインインターフェース）';

  @override
  String get debugFrame_textTypeCliCommand => 'CLIコマンド';

  @override
  String get debugFrame_textTypePlain => 'シンプルな';

  @override
  String debugFrame_text(String text) {
    return '- テキスト：「$text」';
  }

  @override
  String get debugFrame_hexDump => 'ヘックスダンプ：';

  @override
  String get chat_hopSingular => 'ジャンプ';

  @override
  String get chat_hopPlural => 'ホップ';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ホップ',
      one: 'ホップ',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'カスタムパスを設定';

  @override
  String get chat_fullPath => 'フルパス';

  @override
  String get chat_pathDetailsNotAvailable =>
      '経路の詳細については、まだ情報がありません。「リフレッシュ」ボタンを押して、再度お試しください。';

  @override
  String get chat_type => '種類';

  @override
  String get chat_path => '道';

  @override
  String get chat_publicKey => '公開鍵';

  @override
  String get chat_compressOutgoingMessages => '送信されるメッセージを圧縮する';

  @override
  String get chat_floodForced => '洪水（強制的な）';

  @override
  String get chat_directForced => '直接的な（強制的な）';

  @override
  String chat_hopsForced(int count) {
    return '$count 本のホップ（強制的に採取）';
  }

  @override
  String get chat_floodAuto => '洪水 (自動)';

  @override
  String get chat_direct => '直接';

  @override
  String get chat_poiShared => '共有されたPOI';

  @override
  String chat_unread(int count) {
    return '未読: $count';
  }

  @override
  String get chat_openLink => 'リンクを開く？';

  @override
  String get chat_openLinkConfirmation => 'このリンクをブラウザで開くことはご希望ですか？';

  @override
  String get chat_open => '開く';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'リンクを開けられませんでした: $url';
  }

  @override
  String get chat_invalidLink => '無効なリンク形式';

  @override
  String get map_lineOfSight => '視界';

  @override
  String get map_losScreenTitle => '視界';

  @override
  String get map_noNodesWithLocation => '位置情報データを持つノードは存在しません';

  @override
  String get map_nodesNeedGps => 'ノードは、地図上に表示されるために、GPS座標を共有する必要があります。';

  @override
  String map_nodesCount(int count) {
    return 'ノード：$count';
  }

  @override
  String map_pinsCount(int count) {
    return 'ピン：$count個';
  }

  @override
  String get map_chat => 'チャット';

  @override
  String get map_repeater => '繰り返し送信装置';

  @override
  String get map_room => '部屋';

  @override
  String get map_sensor => 'センサー';

  @override
  String get map_pinDm => 'ピン（DM）';

  @override
  String get map_pinPrivate => 'プライベート（非公開）';

  @override
  String get map_pinPublic => '公開 (一般公開)';

  @override
  String get map_lastSeen => '最後に確認された場所';

  @override
  String get map_disconnectConfirm => '本当にこのデバイスとの接続を解除したいですか？';

  @override
  String get map_from => '～から';

  @override
  String get map_source => '出典';

  @override
  String get map_flags => '旗';

  @override
  String get map_shareMarkerHere => 'この場所でシェア';

  @override
  String get map_setAsMyLocation => '現在地として設定';

  @override
  String get map_pinLabel => 'ピンラベル';

  @override
  String get map_label => 'ラベル';

  @override
  String get map_pointOfInterest => '注目すべき点';

  @override
  String get map_sendToContact => '連絡先へ送信';

  @override
  String get map_sendToChannel => '特定のチャンネルに送信する';

  @override
  String get map_noChannelsAvailable => '利用可能なチャンネルはありません';

  @override
  String get map_publicLocationShare => '公共スペースの共有';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return '現在、$channelLabel で位置情報を共有する準備をしています。このチャンネルは公開されており、PSK を持つ誰でも閲覧できます。';
  }

  @override
  String get map_connectToShareMarkers => '他のデバイスと接続して、マーカーを共有する';

  @override
  String get map_filterNodes => 'フィルタノード';

  @override
  String get map_chatNodes => 'チャットノード';

  @override
  String get map_repeaters => '繰り返し送信装置';

  @override
  String get map_otherNodes => 'その他のノード';

  @override
  String get map_showOverlaps => 'リピーターキーの重複';

  @override
  String get map_keyPrefix => '主要なプレフィックス';

  @override
  String get map_filterByKeyPrefix => '主要なプレフィックスでフィルタリングする';

  @override
  String get map_publicKeyPrefix => '公開鍵のプレフィックス';

  @override
  String get map_showDiscoveryContacts => 'Discovery社の連絡先を表示する';

  @override
  String get map_guessedLocation => '推測された場所';

  @override
  String get map_lastSeenTime => '最後に確認された時間';

  @override
  String get map_sharedPin => '共有パスワード';

  @override
  String get map_joinRoom => '部屋に参加する';

  @override
  String get map_manageRepeater => 'リピーターの管理';

  @override
  String get map_tapToAdd => 'ノードをクリックして、パスに追加します。';

  @override
  String get map_runTrace => 'パスの追跡を実行';

  @override
  String get map_runTraceWithReturnPath => '元の経路に戻る。';

  @override
  String get map_removeLast => '最後のものを削除';

  @override
  String get map_pathTraceCancelled => 'パスの追跡は中止。';

  @override
  String get time_justNow => 'まさに今';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes分前';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours時間前';
  }

  @override
  String time_daysAgo(int days) {
    return '$days日前';
  }

  @override
  String get time_hour => '1時間';

  @override
  String get time_hours => '時間';

  @override
  String get time_day => '一日';

  @override
  String get time_days => '日';

  @override
  String get time_week => '1週間';

  @override
  String get time_weeks => '週';

  @override
  String get time_month => '月';

  @override
  String get time_months => '月';

  @override
  String get time_minutes => '分';

  @override
  String get time_allTime => '全期間';

  @override
  String get dialog_disconnect => '切断する';

  @override
  String get dialog_disconnectConfirm => '本当にこのデバイスとの接続を解除したいですか？';

  @override
  String get login_repeaterLogin => '再ログイン';

  @override
  String get login_roomLogin => 'ルームサーバーへのログイン';

  @override
  String get login_password => 'パスワード';

  @override
  String get login_enterPassword => 'パスワードを入力してください';

  @override
  String get login_savePassword => 'パスワードを保存する';

  @override
  String get login_savePasswordSubtitle => 'パスワードは、このデバイスに安全に保存されます。';

  @override
  String get login_repeaterDescription =>
      '設定やステータスにアクセスするために、リピーターのパスワードを入力してください。';

  @override
  String get login_roomDescription => '設定やステータスへのアクセスには、部屋のパスワードを入力してください。';

  @override
  String get login_login => 'ログイン';

  @override
  String login_attempt(int current, int max) {
    return '試行回数：$current/$max';
  }

  @override
  String login_failed(String error) {
    return 'ログインに失敗しました：$error';
  }

  @override
  String get login_failedMessage =>
      'ログインに失敗しました。パスワードが間違っているか、または接続が確立されていません。';

  @override
  String get common_reload => '再読み込み';

  @override
  String get common_clear => '明確';

  @override
  String get path_enterCustomPath => 'カスタムパスを入力';

  @override
  String get path_currentPathLabel => '現在の経路';

  @override
  String get path_hexPrefixInstructions =>
      '各ホップに対して、2文字の16進数プレフィックスをカンマで区切って入力してください。';

  @override
  String get path_hexPrefixExample => '例：A1, F2, 3C (各ノードは、自身の公開鍵の最初のバイトを使用)';

  @override
  String get path_labelHexPrefixes => 'パス (ヘックスプレフィックス)';

  @override
  String get path_helperMaxHops =>
      '最大64個のホップ。各プレフィックスは2つの16進数文字（1バイト）で構成されています。';

  @override
  String get path_selectFromContacts => 'または、連絡先リストから選択してください：';

  @override
  String get path_noRepeatersFound => '繰り返し機能やルームサーバーは見つかりませんでした。';

  @override
  String get path_customPathsRequire => 'カスタムパスには、メッセージを中継できる中間地点が必要です。';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return '無効な16進数プレフィックス: $prefixes';
  }

  @override
  String get path_tooLong => '経路が長すぎる。最大64回のジャンプのみ許可。';

  @override
  String get path_setPath => 'パスを設定';

  @override
  String get repeater_management => 'リピーター管理';

  @override
  String get room_management => 'ルームサーバーの管理';

  @override
  String get repeater_guest => '繰り返し送信に関する情報';

  @override
  String get room_guest => 'ルームサーバーに関する情報';

  @override
  String get repeater_managementTools => '管理ツール';

  @override
  String get repeater_guestTools => 'ゲスト向けツール';

  @override
  String get repeater_status => 'ステータス';

  @override
  String get repeater_statusSubtitle => 'リピーターの状態、統計情報、および隣接するネットワークの情報を表示する';

  @override
  String get repeater_telemetry => 'テレメトリー';

  @override
  String get repeater_telemetrySubtitle => 'センサーおよびシステムの状態に関するテレメトリの表示';

  @override
  String get repeater_cli => 'CLI（コマンドラインインターフェース）';

  @override
  String get repeater_cliSubtitle => 'リピーターへのコマンドを送信する';

  @override
  String get repeater_neighbors => '近隣住民';

  @override
  String get repeater_neighborsSubtitle => 'ゼロホップの隣接ノードを表示する。';

  @override
  String get repeater_settings => '設定';

  @override
  String get repeater_settingsSubtitle => 'リピーターのパラメータを設定する';

  @override
  String get repeater_clockSyncAfterLogin => 'ログイン後、時計の時刻を同期する';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'ログインが成功した場合、自動的に「時刻同期」を送信する。';

  @override
  String get repeater_statusTitle => '再送ステータス';

  @override
  String get repeater_refresh => 'リフレッシュ';

  @override
  String get repeater_statusRequestTimeout => 'ステータス情報の取得に失敗しました。';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'ステータス読み込みエラー: $error';
  }

  @override
  String get repeater_systemInformation => 'システム情報';

  @override
  String get repeater_battery => 'バッテリー';

  @override
  String get repeater_clockAtLogin => 'ログイン時の時刻表示';

  @override
  String get repeater_uptime => '稼働率';

  @override
  String get repeater_queueLength => '待ち行列の長さ';

  @override
  String get repeater_debugFlags => 'デバッグフラグ';

  @override
  String get repeater_radioStatistics => 'ラジオに関する統計';

  @override
  String get repeater_lastRssi => '最後のRSSI';

  @override
  String get repeater_lastSnr => '最後のSNR';

  @override
  String get repeater_noiseFloor => 'ノイズレベル';

  @override
  String get repeater_txAirtime => 'TXの放送時間';

  @override
  String get repeater_rxAirtime => 'RX 空き時間';

  @override
  String get repeater_packetStatistics => 'パケット統計';

  @override
  String get repeater_sent => '送信';

  @override
  String get repeater_received => '受領';

  @override
  String get repeater_duplicates => '重複';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days日 $hours時間 $minutes分 $seconds秒';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return '合計: $total, 洪水: $flood, 直接: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return '合計: $total, 洪水: $flood, 直接: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return '$flood: $flood, 直接: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return '合計: $total';
  }

  @override
  String get repeater_settingsTitle => 'リピーター設定';

  @override
  String get repeater_basicSettings => '基本設定';

  @override
  String get repeater_repeaterName => '送信装置名';

  @override
  String get repeater_repeaterNameHelper => 'このリピーターの名前';

  @override
  String get repeater_adminPassword => '管理者パスワード';

  @override
  String get repeater_adminPasswordHelper => '完全アクセス権のパスワード';

  @override
  String get repeater_guestPassword => 'ゲスト用のパスワード';

  @override
  String get repeater_guestPasswordHelper => '読み取り専用アクセス用のパスワード';

  @override
  String get repeater_radioSettings => 'ラジオ設定';

  @override
  String get repeater_frequencyMhz => '周波数 (MHz)';

  @override
  String get repeater_frequencyHelper => '300～2500 MHz';

  @override
  String get repeater_txPower => 'TXパワー';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => '帯域幅';

  @override
  String get repeater_spreadingFactor => '伝播係数';

  @override
  String get repeater_codingRate => 'コーディング速度';

  @override
  String get repeater_locationSettings => '場所設定';

  @override
  String get repeater_latitude => '緯度';

  @override
  String get repeater_latitudeHelper => '度分表記（例：37.7749）';

  @override
  String get repeater_longitude => '経度';

  @override
  String get repeater_longitudeHelper => '度分表記（例：-122.4194）';

  @override
  String get repeater_features => '特徴';

  @override
  String get repeater_packetForwarding => 'パケット転送';

  @override
  String get repeater_packetForwardingSubtitle => 'リピーターがパケットを転送できるように設定する';

  @override
  String get repeater_guestAccess => 'ゲストへのアクセス';

  @override
  String get repeater_guestAccessSubtitle => 'ゲストへの読み取り専用アクセスを許可する';

  @override
  String get repeater_privacyMode => 'プライバシーモード';

  @override
  String get repeater_privacyModeSubtitle => '広告に名前/場所を記載しない';

  @override
  String get repeater_advertisementSettings => '広告設定';

  @override
  String get repeater_localAdvertInterval => '地域広告掲載期間';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes 分';
  }

  @override
  String get repeater_floodAdvertInterval => '洪水に関する広告の表示間隔';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours 時間';
  }

  @override
  String get repeater_encryptedAdvertInterval => '暗号化された広告表示間';

  @override
  String get repeater_dangerZone => '危険区域';

  @override
  String get repeater_rebootRepeater => 'リピーターを再起動する';

  @override
  String get repeater_rebootRepeaterSubtitle => 'リピーターデバイスを再起動する';

  @override
  String get repeater_rebootRepeaterConfirm => '本当にこのリピーターを再起動したいですか？';

  @override
  String get repeater_regenerateIdentityKey => 'IDキーの再生成';

  @override
  String get repeater_regenerateIdentityKeySubtitle => '新しい公開鍵/秘密鍵のペアを生成する';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'これにより、リピーターには新しい識別情報が割り当てられます。続行しますか？';

  @override
  String get repeater_eraseFileSystem => 'ファイルシステムを削除する';

  @override
  String get repeater_eraseFileSystemSubtitle => 'リピーターファイルシステムをフォーマットする';

  @override
  String get repeater_eraseFileSystemConfirm =>
      '警告：この操作により、リピーター内のすべてのデータが消去されます。この操作は元に戻すことができません！';

  @override
  String get repeater_eraseSerialOnly => 'Erase機能は、シリアルコンソール経由でのみ利用可能です。';

  @override
  String repeater_commandSent(String command) {
    return '送信されたコマンド: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'コマンド送信エラー：$error';
  }

  @override
  String get repeater_confirm => '確認';

  @override
  String get repeater_settingsSaved => '設定が正常に保存されました';

  @override
  String repeater_errorSavingSettings(String error) {
    return '設定の保存に失敗しました：$error';
  }

  @override
  String get repeater_refreshBasicSettings => '基本設定をリセットする';

  @override
  String get repeater_refreshRadioSettings => 'ラジオ設定をリセットする';

  @override
  String get repeater_refreshTxPower => 'TX の電力レベルをリセットする';

  @override
  String get repeater_refreshLocationSettings => '場所設定をリセットする';

  @override
  String get repeater_refreshPacketForwarding => 'パケット転送の刷新';

  @override
  String get repeater_refreshGuestAccess => 'ゲストへのアクセスをリフレッシュする';

  @override
  String get repeater_refreshPrivacyMode => 'プライバシーモードをリセットする';

  @override
  String get repeater_refreshAdvertisementSettings => '広告設定のリセット';

  @override
  String repeater_refreshed(String label) {
    return '$label が更新されました';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return '$label の更新に失敗しました';
  }

  @override
  String get repeater_cliTitle => 'リピーターのコマンドラインインターフェース';

  @override
  String get repeater_debugNextCommand => '次のコマンドのデバッグ';

  @override
  String get repeater_commandHelp => 'コマンドヘルプ';

  @override
  String get repeater_clearHistory => '明確な歴史';

  @override
  String get repeater_noCommandsSent => 'まだコマンドは送信されていません';

  @override
  String get repeater_typeCommandOrUseQuick =>
      '以下のコマンドを入力するか、クイックコマンドを使用してください。';

  @override
  String get repeater_enterCommandHint => 'コマンドを入力してください...';

  @override
  String get repeater_previousCommand => '直前の指示';

  @override
  String get repeater_nextCommand => '次の指示';

  @override
  String get repeater_enterCommandFirst => 'まず、コマンドを入力してください。';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI コマンドフレーム';

  @override
  String repeater_cliCommandError(String error) {
    return 'エラー：$error';
  }

  @override
  String get repeater_cliQuickGetName => '名前を取得する';

  @override
  String get repeater_cliQuickGetRadio => 'ラジオを聴く';

  @override
  String get repeater_cliQuickGetTx => 'TXを入手する';

  @override
  String get repeater_cliQuickNeighbors => '近隣住民';

  @override
  String get repeater_cliQuickVersion => 'バージョン';

  @override
  String get repeater_cliQuickAdvertise => '広告';

  @override
  String get repeater_cliQuickClock => '時計';

  @override
  String get repeater_cliQuickClockSync => 'クロック同期';

  @override
  String get repeater_cliQuickDiscovery => '近隣を発見する';

  @override
  String get repeater_cliHelpAdvert => '広告用資料を送る';

  @override
  String get repeater_cliHelpReboot =>
      'デバイスを再起動します。(注：通常は「タイムアウト」が表示されますが、これは正常です)';

  @override
  String get repeater_cliHelpClock => '各デバイスの時計で現在の時刻を表示します。';

  @override
  String get repeater_cliHelpPassword => 'デバイス用の新しい管理者パスワードを設定します。';

  @override
  String get repeater_cliHelpVersion => 'デバイスのバージョンとファームウェアのビルド日を表示します。';

  @override
  String get repeater_cliHelpClearStats => 'さまざまな統計カウンターをゼロにリセットする。';

  @override
  String get repeater_cliHelpSetAf => '空き時間係数を設定します。';

  @override
  String get repeater_cliHelpSetTx => 'LoRaの送信電力をdBmで設定します。（設定変更後、再起動が必要です）';

  @override
  String get repeater_cliHelpSetRepeat => 'このノードに対するリピーターの役割を有効化または無効化します。';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '（ルームサーバー設定）「オン」に設定した場合、空白のパスワードでのログインは可能ですが、ルームへの投稿はできません。（閲覧のみ）';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'インバウンドフラッパケットの最大ホップ数を設定します（最大値を超えた場合、パケットは転送されません）。';

  @override
  String get repeater_cliHelpSetIntThresh =>
      '干渉閾値を設定します（dB単位）。デフォルト値は14です。0に設定すると、チャンネル間の干渉を検出する機能を無効にします。';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'オートゲインコントローラーのリセット間隔を設定します。 0 に設定すると無効化されます。';

  @override
  String get repeater_cliHelpSetMultiAcks => '「ダブルACK」機能の有効化または無効化を可能にします。';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'ローカル（ホップなし）の広告パケットを送信する間隔を分単位で設定します。 0 に設定すると、機能を無効にします。';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      '洪水広告の送信間隔を時間単位で設定します。0に設定すると、送信を停止します。';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'ゲストのパスワードを設定/更新します。（繰り返し利用の場合、ゲストのログインは「統計情報を取得」のリクエストを送信できます）';

  @override
  String get repeater_cliHelpSetName => '広告の名前を設定します。';

  @override
  String get repeater_cliHelpSetLat => '広告表示の地図の緯度を設定します。（度分秒表記）';

  @override
  String get repeater_cliHelpSetLon => '広告表示の地図の経度を設定します。（度数、分）';

  @override
  String get repeater_cliHelpSetRadio =>
      '完全に新しいラジオパラメータを設定し、設定として保存します。適用するには、「再起動」コマンドが必要です。';

  @override
  String get repeater_cliHelpSetRxDelay =>
      '（実験用）遅延時間を設定するためのベース（1以上の値に設定する必要）\n受信パケットに対して、信号強度/スコアに基づいてわずかな遅延を適用します。 0に設定すると無効化されます。';

  @override
  String get repeater_cliHelpSetTxDelay =>
      '時間経過に応じた「フラッシュモード」パケットの送信遅延を設定します。この遅延は、ランダムなスロットシステムと組み合わせて使用され、パケットの衝突を減らすことを目的としています。';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'txdelayと同様ですが、ダイレクトモードのパケット転送にランダムな遅延を適用する場合に使用します。';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'ブリッジを有効化/無効化';

  @override
  String get repeater_cliHelpSetBridgeDelay => 'パケットを再送信する前に、遅延を設定する。';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      '橋が受信したパケットを再送信するか、送信したパケットを再送信するかどうかを選択してください。';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'RS232 橋渡しに使用するシリアルリンクのボーレートを設定する。';

  @override
  String get repeater_cliHelpSetBridgeSecret => 'ESPNow 橋の秘密設定';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      '特定のボードでのみサポートされている、報告されるバッテリー電圧を調整するためのカスタムファクタを設定できます。';

  @override
  String get repeater_cliHelpTempRadio =>
      '指定された時間（分単位）に対して、一時的にラジオパラメータを設定し、その後元のラジオパラメータに戻します。（設定を保存しません）。';

  @override
  String get repeater_cliHelpSetPerm =>
      'ACL を変更します。「permissions」が 0 の場合、対応するエントリ（pubkey のプレフィックスで識別）を削除します。pubkey-hex が有効な長さで、かつ ACL に現在存在しない場合に、新しいエントリを追加します。pubkey のプレフィックスと一致するエントリを更新します。権限ビットはファームウェアの役割によって異なり、下位 2 ビットは以下のとおりです：0 (ゲスト)、1 (読み取り専用)、2 (読み書き)、3 (管理者)';

  @override
  String get repeater_cliHelpGetBridgeType => 'ブリッジ機能なし、RS232、ESPNow';

  @override
  String get repeater_cliHelpLogStart => 'パケットのログ記録を開始し、ファイルシステムに保存する。';

  @override
  String get repeater_cliHelpLogStop => 'ファイルシステムへのパケットログの記録を停止する。';

  @override
  String get repeater_cliHelpLogErase => 'ファイルシステムからパケットログを削除する。';

  @override
  String get repeater_cliHelpNeighbors =>
      'ゼロホップ広告を通じて受信した他のリピーターノードの一覧を表示します。各行は、IDプレフィックス（16進数）、タイムスタンプ、SNR（シグナル強度）の情報を4つ含みます。';

  @override
  String get repeater_cliHelpNeighborRemove =>
      '隣接リストから、最初に一致するエントリ（pubkeyプレフィックス（16進数）で特定）を削除します。';

  @override
  String get repeater_cliHelpRegion =>
      '（特定のシリーズのみ）定義されたすべての地域と、現在の洪水許可状況を一覧表示します。';

  @override
  String get repeater_cliHelpRegionLoad =>
      '注：これは特殊な複数コマンドの呼び出しです。その後の各コマンドは、地域名であり（スペースを使用して親階層を示し、少なくとも1つのスペースが必要です）、空行/コマンドで終了します。';

  @override
  String get repeater_cliHelpRegionGet =>
      '指定された名前のプレフィックスを持つ地域を検索します（または、グローバルな範囲の場合は「*」）。結果として、「region-name (parent-name) \'F\'」と返答します。';

  @override
  String get repeater_cliHelpRegionPut => '指定された名前で、領域の定義を追加または更新します。';

  @override
  String get repeater_cliHelpRegionRemove =>
      '指定された名前を持つ領域の定義を削除します。(正確に一致している必要があり、子領域は存在してはなりません)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      '指定された領域に対して、「洪水」アクセス許可を設定します。 (グローバル/従来のスコープには「*」を使用)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      '指定された領域における「FLOOD」権限を削除します。（注：現時点では、グローバル/従来の範囲での使用は推奨されません！）';

  @override
  String get repeater_cliHelpRegionHome =>
      '現在の「ホーム」地域に返信します。（まだ適用されていない、将来利用を予定）';

  @override
  String get repeater_cliHelpRegionHomeSet => '「ホーム」地域を設定します。';

  @override
  String get repeater_cliHelpRegionSave => '領域リスト/マップをストレージに保存する。';

  @override
  String get repeater_cliHelpGps =>
      'GPSの状態を表示します。GPSがオフの場合、「オフ」と表示します。オンの場合、「オン」、「ステータス」、「位置情報」、「衛星数」と表示します。';

  @override
  String get repeater_cliHelpGpsOnOff => 'GPS の電源状態を切り替えます。';

  @override
  String get repeater_cliHelpGpsSync => 'ノードの時刻をGPSクロックと同期する。';

  @override
  String get repeater_cliHelpGpsSetLoc => 'ノードの位置をGPS座標に設定し、設定を保存する。';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'ノードの広告設定における場所情報の指定:\n- none: 広告に場所情報を含まない\n- share: GPS位置情報を共有 (SensorManagerから取得)\n- prefs: プリファレンスに保存された場所情報を広告';

  @override
  String get repeater_cliHelpGpsAdvertSet => '場所に関する広告設定を行います。';

  @override
  String get repeater_commandsListTitle => 'コマンド一覧';

  @override
  String get repeater_commandsListNote =>
      '注：さまざまな「set ...」コマンドには、「get ...」コマンドも存在します。';

  @override
  String get repeater_general => '一般的な';

  @override
  String get repeater_settingsCategory => '設定';

  @override
  String get repeater_bridge => '橋';

  @override
  String get repeater_logging => 'ログ記録';

  @override
  String get repeater_neighborsRepeaterOnly => '近隣住民（リピーターのみ）';

  @override
  String get repeater_regionManagementRepeaterOnly => '地域管理（ブロードキャスト用のみ）';

  @override
  String get repeater_regionNote => '地域レベルでの管理のため、地域定義と権限の管理を行うための機能が導入されました。';

  @override
  String get repeater_gpsManagement => 'GPS管理';

  @override
  String get repeater_gpsNote => 'GPSコマンドは、位置情報に関連するタスクを管理するために導入されました。';

  @override
  String get telemetry_receivedData => '受信したテレメトリーデータ';

  @override
  String get telemetry_requestTimeout => 'テレメトリの要求タイムアウトしました。';

  @override
  String telemetry_errorLoading(String error) {
    return 'テレメトリの読み込みに失敗しました: $error';
  }

  @override
  String get telemetry_noData => 'テレメトリデータは利用できません。';

  @override
  String telemetry_channelTitle(int channel) {
    return 'チャンネル $channel';
  }

  @override
  String get telemetry_batteryLabel => 'バッテリー';

  @override
  String get telemetry_voltageLabel => '電圧';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU の温度';

  @override
  String get telemetry_temperatureLabel => '温度';

  @override
  String get telemetry_currentLabel => '現在';

  @override
  String telemetry_batteryValue(int percent, String volts) {
    return '$percent% / ${volts}V';
  }

  @override
  String telemetry_voltageValue(String volts) {
    return '${volts}V';
  }

  @override
  String telemetry_currentValue(String amps) {
    return '${amps}A';
  }

  @override
  String telemetry_temperatureValue(String celsius, String fahrenheit) {
    return '$celsius℃ / $fahrenheit°F';
  }

  @override
  String get neighbors_receivedData => '近隣住民のデータを受信';

  @override
  String get neighbors_requestTimedOut => '近隣住民からの要望：時間制限を設けてください。';

  @override
  String neighbors_errorLoading(String error) {
    return '近隣情報の読み込みに失敗: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => '繰り返し送信する、近隣';

  @override
  String get neighbors_noData => '近隣のデータは利用できません。';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '不明な $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return '聞いたのは、$time くらい前です';
  }

  @override
  String get channelPath_title => 'パケットパス';

  @override
  String get channelPath_viewMap => '地図を表示する';

  @override
  String get channelPath_otherObservedPaths => '観察されたその他の経路';

  @override
  String get channelPath_repeaterHops => 'ホップの繰り返し';

  @override
  String get channelPath_noHopDetails => 'このパッケージに関する詳細な情報は提供されていません。';

  @override
  String get channelPath_messageDetails => 'メッセージの詳細';

  @override
  String get channelPath_senderLabel => '送信者';

  @override
  String get channelPath_timeLabel => '時間';

  @override
  String get channelPath_repeatsLabel => '繰り返し';

  @override
  String channelPath_pathLabel(int index) {
    return '$index 番目の経路';
  }

  @override
  String get channelPath_observedLabel => '観察';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return '観察された経路 $index • $hops';
  }

  @override
  String get channelPath_noLocationData => '場所に関するデータはありません';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => '不明';

  @override
  String get channelPath_floodPath => '洪水';

  @override
  String get channelPath_directPath => '直接';

  @override
  String channelPath_observedZeroOf(int total) {
    return '$total個のホップ';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed of $total hops';
  }

  @override
  String get channelPath_mapTitle => '経路図';

  @override
  String get channelPath_noRepeaterLocations => 'この経路には、中継装置の設置場所がありません。';

  @override
  String channelPath_primaryPath(int index) {
    return '$index番目の経路（主要経路）';
  }

  @override
  String get channelPath_pathLabelTitle => '道';

  @override
  String get channelPath_observedPathHeader => '観察された経路';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable => 'このパッケージに関する詳細な配送情報は利用できません。';

  @override
  String get channelPath_unknownRepeater => '不明な増幅機';

  @override
  String get community_title => '地域';

  @override
  String get community_create => 'コミュニティを構築する';

  @override
  String get community_createDesc => '新しいコミュニティを作成し、QRコードで共有する。';

  @override
  String get community_join => '参加する';

  @override
  String get community_joinTitle => 'コミュニティに参加する';

  @override
  String community_joinConfirmation(String name) {
    return '$nameさんのようなコミュニティに参加したいですか？';
  }

  @override
  String get community_scanQr => 'コミュニティのQRコードをスキャン';

  @override
  String get community_scanInstructions => 'カメラを、地域のQRコードを向けて';

  @override
  String get community_showQr => 'QRコードを表示する';

  @override
  String get community_publicChannel => '地域住民向け';

  @override
  String get community_hashtagChannel => 'コミュニティ用ハッシュタグ';

  @override
  String get community_name => 'コミュニティ名';

  @override
  String get community_enterName => 'コミュニティ名を入力してください';

  @override
  String community_created(String name) {
    return 'コミュニティ「$name」が作成されました';
  }

  @override
  String community_joined(String name) {
    return '$name のコミュニティに参加';
  }

  @override
  String get community_qrTitle => 'コミュニティ共有';

  @override
  String community_qrInstructions(String name) {
    return 'このQRコードをスキャンして、$nameに参加してください。';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'コミュニティハッシュタグのチャンネルは、コミュニティのメンバーのみが参加できます。';

  @override
  String get community_invalidQrCode => '無効なコミュニティQRコード';

  @override
  String get community_alreadyMember => 'すでに会員である';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'あなたはすでに $name の会員です。';
  }

  @override
  String get community_addPublicChannel => 'コミュニティ用の公開チャンネルを追加';

  @override
  String get community_addPublicChannelHint => 'このコミュニティの公開チャンネルを自動的に追加する';

  @override
  String get community_noCommunities => 'まだコミュニティは形成されていません。';

  @override
  String get community_scanOrCreate => 'QRコードをスキャンするか、コミュニティを作成して開始してください。';

  @override
  String get community_manageCommunities => 'コミュニティの管理';

  @override
  String get community_delete => 'コミュニティからの離脱';

  @override
  String community_deleteConfirm(String name) {
    return '$nameを辞める？';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'これにより、$count のチャンネルとそのメッセージも削除されます。';
  }

  @override
  String community_deleted(String name) {
    return 'コミュニティ「$name」を離れる';
  }

  @override
  String get community_regenerateSecret => '秘密の復元';

  @override
  String community_regenerateSecretConfirm(String name) {
    return '$name の秘密鍵を再生成しますか？ 継続的に通信するため、すべてのメンバーは新しいQRコードをスキャンする必要があります。';
  }

  @override
  String get community_regenerate => '再生';

  @override
  String community_secretRegenerated(String name) {
    return '$name への秘密が再設定されました';
  }

  @override
  String get community_updateSecret => '秘密情報の更新';

  @override
  String community_secretUpdated(String name) {
    return '$name 向けの秘密設定を更新';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return '新しいQRコードをスキャンして、$nameの秘密情報を更新してください。';
  }

  @override
  String get community_addHashtagChannel => 'コミュニティのハッシュタグを追加';

  @override
  String get community_addHashtagChannelDesc => 'このコミュニティ用のハッシュタグチャンネルを追加する';

  @override
  String get community_selectCommunity => 'コミュニティを選択';

  @override
  String get community_regularHashtag => '定期的なハッシュタグ';

  @override
  String get community_regularHashtagDesc => '一般のハッシュタグ（誰でも参加可能）';

  @override
  String get community_communityHashtag => 'コミュニティ用ハッシュタグ';

  @override
  String get community_communityHashtagDesc => 'コミュニティメンバーのみへの限定';

  @override
  String community_forCommunity(String name) {
    return '$name 様';
  }

  @override
  String get listFilter_tooltip => 'フィルタリングと並べ替え';

  @override
  String get listFilter_sortBy => '並び替え';

  @override
  String get listFilter_latestMessages => '最新のメッセージ';

  @override
  String get listFilter_heardRecently => '最近、聞いた';

  @override
  String get listFilter_az => 'AからZ';

  @override
  String get listFilter_filters => 'フィルター';

  @override
  String get listFilter_source => '取得元';

  @override
  String get listFilter_saved => '保存済み';

  @override
  String get listFilter_discovered => '発見済み';

  @override
  String get listFilter_all => 'すべて';

  @override
  String get listFilter_favorites => 'お気に入り';

  @override
  String get listFilter_addToFavorites => 'お気に入りに追加';

  @override
  String get listFilter_removeFromFavorites => 'お気に入りから削除';

  @override
  String get listFilter_users => '利用者';

  @override
  String get listFilter_repeaters => '繰り返し送信装置';

  @override
  String get listFilter_roomServers => 'ルーム用サーバー';

  @override
  String get listFilter_unreadOnly => '未読のみ';

  @override
  String get listFilter_newGroup => '新しいグループ';

  @override
  String get pathTrace_you => 'あなた';

  @override
  String get pathTrace_failed => 'パスの追跡に失敗しました。';

  @override
  String get pathTrace_notAvailable => 'パスの追跡機能は利用できません。';

  @override
  String get pathTrace_refreshTooltip => 'パスの追跡をリフレッシュする。';

  @override
  String get pathTrace_someHopsNoLocation => 'ホップの1つまたは複数について、場所が特定されていません。';

  @override
  String get pathTrace_clearTooltip => '明確な道筋。';

  @override
  String get losSelectStartEnd => 'LOS の開始ノードと終了ノードを選択してください。';

  @override
  String losRunFailed(String error) {
    return '視界確認に失敗: $error';
  }

  @override
  String get losClearAllPoints => 'すべての項目をクリア';

  @override
  String get losRunToViewElevationProfile => 'LOS（レーザー測距）を使用して、標高プロファイルを表示する';

  @override
  String get losMenuTitle => 'LOS メニュー';

  @override
  String get losMenuSubtitle => '特定の場所をタップするか、地図を長押ししてカスタムポイントを作成する。';

  @override
  String get losShowDisplayNodes => '表示ノードを表示する';

  @override
  String get losCustomPoints => 'カスタマイズ可能なポイント';

  @override
  String losCustomPointLabel(int index) {
    return 'カスタマイズ $index';
  }

  @override
  String get losPointA => 'ポイントA';

  @override
  String get losPointB => 'ポイントB';

  @override
  String losAntennaA(String value, String unit) {
    return 'アンテナ A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'アンテナ B: $value $unit';
  }

  @override
  String get losRun => 'LOS（レーティングシステム）を使用する';

  @override
  String get losNoElevationData => '標高データは含まれていません';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, clear LOS, min clearance $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blocked by $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS：確認中…';

  @override
  String get losStatusNoData => 'LOS: データの欠如';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total clear, $blocked blocked, $unknown unknown';
  }

  @override
  String get losErrorElevationUnavailable =>
      'あるサンプルまたは複数のサンプルについて、標高データが利用できません。';

  @override
  String get losErrorInvalidInput => 'LOS（レーダー）計算に必要な、無効な点/標高データ。';

  @override
  String get losRenameCustomPoint => 'カスタムポイントの名前を変更する';

  @override
  String get losPointName => '項目名';

  @override
  String get losShowPanelTooltip => 'LOSパネルを表示する';

  @override
  String get losHidePanelTooltip => 'LOSパネルを隠す';

  @override
  String get losElevationAttribution => '標高データ：Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'ラジオ・ホライゾン';

  @override
  String get losLegendLosBeam => 'LOS ビーミング';

  @override
  String get losLegendTerrain => '地形';

  @override
  String get losFrequencyLabel => '周波数';

  @override
  String get losFrequencyInfoTooltip => '計算の詳細を見る';

  @override
  String get losFrequencyDialogTitle => 'ラジオによる水平線計算';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'k=$baselineK ( $baselineFreq MHz) から開始し、現在の $frequencyMHz MHz の帯域に対して k の値を調整します。これにより、曲面状の無線通信範囲の限界が定義されます。';
  }

  @override
  String get contacts_pathTrace => '経路追跡';

  @override
  String get contacts_ping => 'パング';

  @override
  String get contacts_repeaterPathTrace => 'リピーターまでの経路を追跡する';

  @override
  String get contacts_repeaterPing => 'PING 繰り返し';

  @override
  String get contacts_roomPathTrace => '部屋のサーバーへの経路を追跡する';

  @override
  String get contacts_roomPing => 'ピンルーム用サーバー';

  @override
  String get contacts_chatTraceRoute => '経路の追跡ルート';

  @override
  String contacts_pathTraceTo(String name) {
    return '$name への経路を追跡する';
  }

  @override
  String get contacts_clipboardEmpty => 'クリップボードは空です。';

  @override
  String get contacts_invalidAdvertFormat => '無効な連絡先情報';

  @override
  String get contacts_contactImported => '連絡先が登録されました。';

  @override
  String get contacts_contactImportFailed => '連絡先のインポートに失敗しました。';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name はすでに連絡先にあります。';
  }

  @override
  String get contacts_zeroHopAdvert => 'ゼロホップ広告';

  @override
  String get contacts_floodAdvert => '洪水に関する広告';

  @override
  String get contacts_copyAdvertToClipboard => '広告をクリップボードにコピー';

  @override
  String get contacts_addContactFromClipboard => 'クリップボードから連絡先を追加する';

  @override
  String get contacts_ShareContact => '連絡先をクリップボードにコピー';

  @override
  String get contacts_ShareContactZeroHop => '広告を通じて連絡先を共有する';

  @override
  String get contacts_zeroHopContactAdvertSent => '広告を通じて連絡先を得た。';

  @override
  String get contacts_zeroHopContactAdvertFailed => '連絡を送信できませんでした。';

  @override
  String get contacts_contactAdvertCopied => '広告がクリップボードにコピーされました。';

  @override
  String get contacts_contactAdvertCopyFailed => '広告のコピーがクリップボードにコピーできませんでした。';

  @override
  String get contacts_addContact => '連絡先を追加';

  @override
  String get contacts_scanQrCode => '連絡先のQRをスキャン';

  @override
  String get contacts_scanQrCodeDesc => 'MeshCoreアプリの連絡先QRコードをスキャン';

  @override
  String get contacts_enterIdHash => '連絡先を手動で入力';

  @override
  String get contacts_enterIdHashDesc => '連絡先の広告またはmeshcore://リンクを貼り付け';

  @override
  String get contacts_advertHint => 'meshcore://... または公開鍵（hex）';

  @override
  String get contacts_import => 'インポート';

  @override
  String get contacts_scanContactInstructions => 'MeshCoreの連絡先QRコードをスキャンしてください';

  @override
  String get notification_activityTitle => 'メッシュコアの活動';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messages',
      one: 'message',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'チャンネルメッセージ',
      one: 'チャンネルメッセージ',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '新しいノード',
      one: '新しいノード',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return '新たに $contactType が発見されました';
  }

  @override
  String get notification_receivedNewMessage => '新しいメッセージを受信';

  @override
  String get settings_gpxExportRepeaters => 'GPX へのエクスポート用リピーター/ルームサーバー';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'GPXファイルに場所情報を付加した、レピーター/ルームサーバーのエクスポート';

  @override
  String get settings_gpxExportContacts => 'GPX 形式へのエクスポート';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'GPXファイルに位置情報を保存して、他の人と共有する。';

  @override
  String get settings_gpxExportAll => 'すべての連絡先をGPX形式でエクスポートする';

  @override
  String get settings_gpxExportAllSubtitle =>
      'すべての連絡先を、場所情報付きのGPXファイルにエクスポートする。';

  @override
  String get settings_gpxExportSuccess => 'GPXファイルの正常なエクスポートが完了しました。';

  @override
  String get settings_gpxExportNoContacts => 'エクスポートする連絡先は存在しません。';

  @override
  String get settings_gpxExportNotAvailable => 'このデバイス/OSではサポートされていません';

  @override
  String get settings_gpxExportError => 'エクスポート時にエラーが発生しました。';

  @override
  String get settings_gpxExportRepeatersRoom => '中継装置およびルームサーバーの設置場所';

  @override
  String get settings_gpxExportChat => '関連施設';

  @override
  String get settings_gpxExportAllContacts => 'すべての連絡先場所';

  @override
  String get settings_gpxExportShareText => 'MeshTraxからエクスポートされた地図データ';

  @override
  String get settings_gpxExportShareSubject => 'MeshTrax GPX形式の地図データのエクスポート';

  @override
  String get snrIndicator_nearByRepeaters => '近くの電波中継局';

  @override
  String get snrIndicator_lastSeen => '最後に確認された場所';

  @override
  String get contactsSettings_title => '連絡先設定';

  @override
  String get contactsSettings_autoAddTitle => '自動検出';

  @override
  String get contactsSettings_otherTitle => 'その他の連絡に関する設定';

  @override
  String get contactsSettings_autoAddUsersTitle => '自動でユーザーを追加する';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      '利用者が自動的に発見したユーザーを追加できるようにする。';

  @override
  String get contactsSettings_autoAddRepeatersTitle => '自動で繰り返し設定';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      '発見した中継局を、自動的に追加できるようにする。';

  @override
  String get contactsSettings_autoAddRoomServersTitle => '自動でルームサーバーを追加';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      '利用者が、発見した部屋のサーバーを自動的に追加できるようにする。';

  @override
  String get contactsSettings_autoAddSensorsTitle => '自動でセンサーを追加';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      '利用者が、発見したセンサーを自動的に追加できるようにする。';

  @override
  String get contactsSettings_overwriteOldestTitle => '最も古いものを上書きする';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      '連絡先リストが満杯になった場合、最も古いかつ「お気に入り」ではない連絡先が削除されます。';

  @override
  String get discoveredContacts_Title => '連絡先が見つかった';

  @override
  String get discoveredContacts_noMatching => '一致する連絡先が見つかりませんでした';

  @override
  String get listFilter_searchHint => '検索...';

  @override
  String get discoveredContacts_searchHint => '発見された連絡先を検索する';

  @override
  String get discoveredContacts_contactAdded => '連絡先を追加';

  @override
  String get discoveredContacts_addContact => '連絡先を追加';

  @override
  String get discoveredContacts_copyContact => '連絡先をクリップボードにコピー';

  @override
  String get discoveredContacts_deleteContact => '発見された連絡先を削除';

  @override
  String get discoveredContacts_deleteContactAll => '発見されたすべての連絡先を削除';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      '本当に、見つけたすべての連絡先を削除してもよろしいですか？';

  @override
  String get chat_sendCooldown => '再度送信する前に、しばらくお待ちください。';

  @override
  String get chat_notConnected => '無線機に接続されていません。メッセージは送信されませんでした。';

  @override
  String get appSettings_jumpToOldestUnread => '最も古い未読のメッセージへ移動';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      '未読メッセージがあるチャットを開く際、「最新のメッセージ」ではなく、最初に未読のメッセージまでスクロールしてください。';

  @override
  String get appSettings_languageHu => 'ハンガリー語';

  @override
  String get appSettings_languageJa => '日本語';

  @override
  String get appSettings_languageKo => '韓国語';

  @override
  String get radioStats_screenTitle => 'ラジオの統計';

  @override
  String get radioStats_notConnected => 'ラジオの統計情報を表示するために、デバイスに接続してください。';

  @override
  String get radioStats_firmwareTooOld =>
      'ラジオの統計機能を使用するには、v8またはそれ以降のファームウェアが必要です。';

  @override
  String get radioStats_waiting => 'データ待ち…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'ノイズレベル: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return '最後のRSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return '最終SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX 放送時間（合計）：$seconds 秒';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX 放送時間（合計）：$seconds 秒';
  }

  @override
  String get radioStats_chartCaption => '最近のサンプルのノイズレベル（dBm）。';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'ノイズレベル: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'ラジオの統計情報を取得中…';

  @override
  String get radioStats_settingsTile => 'ラジオの統計';

  @override
  String get radioStats_settingsSubtitle => 'ノイズレベル、RSSI、SNR、および通信時間';

  @override
  String get translation_title => '翻訳';

  @override
  String get translation_enableTitle => '翻訳機能を有効にする';

  @override
  String get translation_enableSubtitle => '受信メッセージを翻訳し、送信前に翻訳を適用できるようにする。';

  @override
  String get translation_composerTitle => '送信する前に翻訳する';

  @override
  String get translation_composerSubtitle => '作曲家翻訳アイコンのデフォルト状態を制御する。';

  @override
  String get translation_targetLanguage => '翻訳対象言語';

  @override
  String get translation_useAppLanguage => 'アプリの言語設定';

  @override
  String get translation_downloadedModelLabel => 'ダウンロードしたモデル';

  @override
  String get translation_presetModelLabel => 'あらかじめ設定されたHugging Faceモデル';

  @override
  String get translation_manualUrlLabel => 'マニュアルモデルのURL';

  @override
  String get translation_downloadModel => 'モデルのダウンロード';

  @override
  String get translation_downloading => 'ダウンロード中...';

  @override
  String get translation_working => '業務中…';

  @override
  String get translation_stop => '停止';

  @override
  String get translation_mergingChunks => 'ダウンロードしたファイルを最終ファイルに結合中...';

  @override
  String get translation_downloadedModels => 'ダウンロードされたモデル';

  @override
  String get translation_deleteModel => 'モデルを削除';

  @override
  String get translation_modelDownloaded => '翻訳モデルのダウンロードが完了しました。';

  @override
  String get translation_downloadStopped => 'ダウンロードが中断されました。';

  @override
  String translation_downloadFailed(String error) {
    return 'ダウンロードに失敗しました：$error';
  }

  @override
  String get translation_enterUrlFirst => 'まず、モデルのURLを入力してください。';

  @override
  String get scanner_linuxPairingShowPin => 'PINを表示';

  @override
  String get scanner_linuxPairingHidePin => 'PINを非表示';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth ペアリング PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return '$deviceNameのPINを入力してください（なしの場合は空欄のまま）。';
  }

  @override
  String get translation_messageTranslation => 'メッセージの翻訳';

  @override
  String get translation_translateBeforeSending => '送信する前に翻訳する';

  @override
  String get translation_composerEnabledHint => 'メッセージは送信前に翻訳されます。';

  @override
  String get translation_composerDisabledHint => '元のタイプされた言語でメッセージを送信してください。';

  @override
  String translation_translateTo(String language) {
    return '$language への翻訳';
  }

  @override
  String get translation_translationOptions => '翻訳の選択肢';

  @override
  String get translation_systemLanguage => 'システム言語';

  @override
  String get routing_title => '経路設定';

  @override
  String routing_route(String route) {
    return '保存済みの経路：$route';
  }

  @override
  String get routing_noRoute => 'まだありません — 次のメッセージはフラッドで送られ、経路を学習します';

  @override
  String get routing_auto => '自動';

  @override
  String get routing_autoSubtitle => '無線機に保存された経路を使います。おすすめ。';

  @override
  String get routing_pathfinderOn => 'Pathfinderオン：学習したルートを先に試します';

  @override
  String get routing_flood => '常にフラッド';

  @override
  String get routing_floodSubtitle => 'すべてのメッセージがメッシュ全体に送られます';

  @override
  String get routing_custom => 'カスタム経路';

  @override
  String get routing_customSubtitle => 'リピーターを自分で選びます';

  @override
  String get routing_forget => '経路をリセット';

  @override
  String get routing_forgetDone => '経路をリセットしました。次のメッセージはフラッドで送られ、新しい経路を学習します。';

  @override
  String get routing_pathfinder => 'Pathfinderが知っていること';

  @override
  String get routing_pathfinderSubtitle => 'あなたと相手の電波が届くリピーターと、学習した行き帰りのルート';

  @override
  String get path_direct => '直接 — リピーターなし';

  @override
  String get path_directSubtitle => '相手がこの無線機を直接受信できるときだけ';

  @override
  String get chat_kindFlood => 'フラッド';

  @override
  String get chat_kindDirect => '直接';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ホップ',
      one: 'ホップ',
    );
    return 'ルート（$count$_temp0）';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ホップ',
      one: 'ホップ',
    );
    return 'ルート（$count$_temp0、うち$guessedホップは推測）';
  }

  @override
  String get chat_statusQueued => '送信待ち';

  @override
  String get chat_statusNoRepeaterHeard =>
      'どのリピーターにも届きませんでした。範囲内にリピーターが入ったら再試行します。';

  @override
  String chat_narrowHashNotice(String name) {
    return '$nameの無線機は短いリピーターコード（1バイト）を送っています。相手の無線機が2バイトのコードを使うまで、Pathfinderは相手へのルートを学習できません。';
  }

  @override
  String chat_statusSending(String kind) {
    return '送信中 · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return '再試行中 · $kind · $max回中$attempt回目';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return '配信済み · $kind · $secs秒';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return '$attempt回目で配信 · $kind · $secs秒';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return '遅れて配信 · $kind · $secs秒';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return '配信済み · $secs秒';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: '回',
      one: '回',
    );
    return '$attempts$_temp0試して失敗 · タップで再送信';
  }

  @override
  String get chat_statusFailedShort => '失敗 · タップで再送信';

  @override
  String get chat_resendingByFlood => 'フラッドで再送信中';

  @override
  String get pathfinderHelp_title => 'Pathfinderのしくみ';

  @override
  String get pathfinderHelp_what =>
      '無線機は連絡先ごとにルートを1つだけ覚えていて、そのルートで届かないとメッシュ全体にフラッドします。Pathfinderは、リピーターのアドバート、チャンネルでの会話、ほかの人のメッセージなど、無線機が受信するものすべてに耳を傾けます。そこから、どのリピーター同士がつながっているか、どのリピーターにあなたの電波が届くか、そしてどのリピーターに各連絡先の電波が届くかを示す地図を作ります。';

  @override
  String get pathfinderHelp_how =>
      'メッセージを送るとき、Pathfinderはまず最良のルートを試し、届かなければ次に良いルートを試します。フラッドは最後の手段としてだけ使います。琥珀色の経路アイコンは、Pathfinderのルートで送信したメッセージを示します。';

  @override
  String get pathfinderHelp_learning =>
      '学習には時間がかかります。まっさらな地図は何も知らないので、最初のうちはメッセージがこれまでとまったく同じように送られます。1か所で数時間聞き続けるとルートを提案し始め、届いても届かなくても、そのたびにさらに学習します。初日はあまり期待しないでください。新しい場所に移るたびに、しばらくはまた効果が下がります。';

  @override
  String get pathfinderHelp_guessed =>
      'ルートに足りない部分があると、推測で補うこともあります。推測とは、逆方向で使われるのを聞いただけのリンクのことです。その場合、メッセージの状態表示に推測したホップ数が示されます。届けば推測が正しかったことが確かめられ、届かなくても、むだになるのは1回の試行だけで、何も記録されません。';

  @override
  String get pathfinderHelp_discover =>
      'この場所であなたの電波が届くリピーターがはっきりしないときは、Pathfinderが短いDiscoverを1回送信します（送信に失敗したあとだけで、多くても10分に1回）。GPS付きの無線機なら、約500m四方の区画ごとに、あなたの電波を受信したリピーターをこの端末に記録します。正確な位置は記録しません。';

  @override
  String get pathfinderHelp_off => 'Pathfinderをオフにすれば、無線機は以前とまったく同じように経路を選びます。';

  @override
  String get pathfinderHelp_dontShowAgain => '今後は表示しない';

  @override
  String get pathfinderHelp_ok => '了解';

  @override
  String get settings_pathGraph => 'Pathfinder（試験的）';

  @override
  String get settings_pathGraphSubtitle =>
      '無線機が受信したすべての情報からルートを学習し、DMを送るときに最良のルートから試します。琥珀色の経路アイコンは、Pathfinderのルートで送信したメッセージを示します。';

  @override
  String get map_routeAndTrace => 'ルートと追跡';

  @override
  String get map_pathfinderTrace => '往復で追跡';

  @override
  String get map_pathfinderTraceSubtitle => '行きはPathfinderの最良ルート、帰りは最良の帰りルート';

  @override
  String get map_routeBackMirrored => '帰りのルートはまだ不明 — 同じ道を戻ります';

  @override
  String get map_traceHelpTitle => '経路追跡のボタン';

  @override
  String get map_traceHelpCustom => 'リピーターを入力するか、自分で選びます。';

  @override
  String get map_traceHelpRun => 'タップしたリピーターに沿って、片道で追跡を送信します。';

  @override
  String get map_traceHelpThereAndBack => '往復';

  @override
  String get map_traceHelpThereAndBackSubtitle => '追跡を送信し、同じリピーターを逆順にたどって戻します。';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinderが、最後にタップした2つのリピーターを通る最良のルートと、あなたへ戻る最良のルートを選びます。その結果から、実際に使えるリンクをPathfinderが学びます。リピーターを2つタップする必要があります。';

  @override
  String get map_traceHelpRemoveLast => '最後のリピーターを経路から外します。';

  @override
  String get map_traceHelpCancel => '追跡の作成をやめます。リピーターをタップする前に表示されます。';

  @override
  String get chat_resendingByRoute => '設定したルートで再送信中';

  @override
  String get room_mute => 'ルームをミュート';

  @override
  String get room_unmute => 'ルームのミュートを解除';

  @override
  String get room_roleAdmin => '管理者';

  @override
  String get room_roleMember => 'メンバー';

  @override
  String get room_roleReadOnly => '閲覧のみ';

  @override
  String room_clockOff(int minutes) {
    return 'ルームの時計が約$minutes分ずれています — メッセージの時刻が正しくない可能性があります';
  }

  @override
  String get room_fixClock => '時計を合わせる';

  @override
  String get room_clockSyncSent => 'ルームへ時刻同期を送信しました';

  @override
  String get room_readOnlyNotice =>
      '閲覧のみ: ルームがパスワードを受け付けていないため、送信したメッセージは他のメンバーに届きません。';

  @override
  String get room_postAnnouncement => 'お知らせを投稿';

  @override
  String get room_postAnnouncementSubtitle => 'ルーム自身の名前で全メンバーにメッセージを送信';

  @override
  String get room_announcementSent => 'お知らせを投稿しました';

  @override
  String get room_announcementFailed => 'お知らせの投稿に失敗しました';

  @override
  String get room_users => 'ルームのユーザー';

  @override
  String get room_usersSubtitle => '管理者の確認とロールの設定';

  @override
  String get room_usersAdminsNote =>
      'ルームは管理者のみを一覧表示します。ルームパスワードで参加したメンバーは表示されません。';

  @override
  String get room_usersLoadFailed => '管理者リストを読み込めませんでした';

  @override
  String get room_setUserRole => 'ロールを設定';

  @override
  String get room_removeAccess => 'アクセスを削除';

  @override
  String get room_removeOnlyUnknown => 'このユーザーは連絡先にないため、削除のみ可能で変更はできません。';

  @override
  String get room_roleUpdated => 'ロールを更新しました';

  @override
  String get room_roleUpdateFailed => 'ロールの変更に失敗しました';

  @override
  String get room_postsStored => '保存された投稿';

  @override
  String get room_postsDelivered => '配信された投稿';

  @override
  String get room_reloadPosts => '最近の投稿を再読み込み';

  @override
  String get room_reloadPostsExplain =>
      'ルームに最近の投稿の再送信を依頼します（最大32件保持）。ルームパスワードの入力が必要です。既存のメッセージは保持されます。';

  @override
  String get room_reloadFailed => '無線機でルームをリセットできませんでした';

  @override
  String get companionCli_title => 'コマンドライン';

  @override
  String get companionCli_settingsSubtitle => 'この無線機にテキストコマンドを入力';

  @override
  String get companionCli_rebooting => '無線機を再起動しています…';

  @override
  String get companionCli_cancelled => 'キャンセルしました';

  @override
  String get companionCli_poweringOff => '無線機の電源を切っています…';

  @override
  String get companionCli_noReply => '無線機から応答がありません。もう一度お試しください。';

  @override
  String get companionCli_powerOffTitle => '無線機の電源を切りますか？';

  @override
  String get companionCli_powerOffBody => 'ボタンを押すか電源につなぐまで、電源は切れたままです。';

  @override
  String get companionCli_powerOff => '電源を切る';

  @override
  String get companionCli_quickBoard => 'ボード';

  @override
  String get companionCli_quickWifiStatus => 'Wi‑Fiの状態';

  @override
  String get companionCli_quickWifiAddress => 'Wi‑Fiのアドレス';

  @override
  String get companionCli_helpBoard => 'ボードのメーカーとモデルを表示します。';

  @override
  String get companionCli_helpReboot => '無線機を再起動します。';

  @override
  String get companionCli_helpPowerOff => '無線機の電源を切ります。';

  @override
  String get companionCli_helpSetPin => 'BluetoothのペアリングPINを設定します。再起動後に反映されます。';

  @override
  String get companionCli_helpSetTzOffset =>
      '無線機本体の画面に表示する時計用に、UTCに加える時間数を設定します（-12～+14）。';

  @override
  String get companionCli_helpSetTx => '送信出力をdBmで設定します。すぐに反映されます。';

  @override
  String get companionCli_helpSetIntThresh =>
      '干渉のしきい値をdBで設定します。0にすると干渉検出がオフになります。';

  @override
  String get companionCli_helpSetCad => '送信前に、ほかの無線機が送信していないか確認します（チャンネル活動検出）。';

  @override
  String get companionCli_helpSetRxGain => 'SX126x搭載の無線機で、受信ゲインを強化します。';

  @override
  String get companionCli_helpSetPathHashMode =>
      'ルート内のリピーター1台あたりのバイト数：0 = 1バイト、1 = 2バイト、2 = 3バイト。';

  @override
  String get companionCli_helpWifiStatus => '無線機がWi‑Fiネットワークにつながっているかを表示します。';

  @override
  String get companionCli_helpWifiIp => 'Wi‑Fiネットワーク上の無線機のアドレスを表示します。';

  @override
  String get companionCli_helpWifiSsid => 'Wi‑Fiのネットワーク名を設定します。再起動後に反映されます。';

  @override
  String get companionCli_helpWifiPwd => 'Wi‑Fiのパスワードを設定します。再起動後に反映されます。';

  @override
  String get companionCli_helpWifiEnabled =>
      'Wi‑Fiをオン（1）またはオフ（0）にします。再起動後に反映されます。';

  @override
  String get companionCli_helpWifiClear =>
      '保存されたWi‑Fiネットワークを削除します。再起動後に反映されます。';

  @override
  String get companionCli_remoteNoReply =>
      '応答がありません。相手の無線機にはファームウェア1.18以降が必要で、あなたにコマンドラインの使用を許可している必要があります。';

  @override
  String get companionCli_remoteSentNoAnswer => '送信しました。無線機は再起動や電源オフには応答しません。';

  @override
  String companionCli_blocked(String name, String command) {
    return '$nameがあなたの無線機のコマンドラインを使おうとしました：「$command」。許可されませんでした。';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'あなたの無線機のコマンドラインを使おうとしました：「$command」。許可されませんでした。';
  }

  @override
  String get contact_remoteCli => 'リモートコマンドラインを許可';

  @override
  String get contact_remoteCliSubtitle => 'この連絡先があなたの無線機でコマンドを実行できるようにします';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return '$nameにあなたの無線機の操作を許可しますか？';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$nameは、無線機の設定変更、Wi‑Fiパスワードの読み取り、無線機の名前変更、再起動や電源オフができるようになります。完全に信頼できる相手にだけ許可してください。';
  }

  @override
  String get contact_remoteCliAllow => '許可';

  @override
  String get connection_secondApp =>
      '別のアプリがこの無線機に接続しています。メッセージや設定が混ざることがあります。もう一方のアプリを閉じてください。';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => 'ネットワーク、パスワード、接続';

  @override
  String get wifi_use => 'Wi‑Fiを使う';

  @override
  String get wifi_networkName => 'ネットワーク名';

  @override
  String get wifi_password => 'パスワード';

  @override
  String get wifi_passwordUnchanged => '変更なし';

  @override
  String get wifi_showPassword => 'パスワードを表示';

  @override
  String get wifi_nameMissing => 'ネットワーク名を入力してください';

  @override
  String get wifi_nameTooLong => 'ネットワーク名が長すぎます（最大32バイト）';

  @override
  String get wifi_passwordTooLong => 'パスワードが長すぎます（最大63バイト）';

  @override
  String get wifi_savedRestart => '保存しました。Wi‑Fiの変更は無線機の再起動後に反映されます。';

  @override
  String get wifi_forget => 'ネットワークを削除';

  @override
  String get wifi_forgetConfirm =>
      'このWi‑Fiネットワークを削除しますか？無線機は再起動後にWi‑Fiを使わなくなります。';

  @override
  String wifi_notAccepted(String reply) {
    return '無線機が受け付けませんでした：$reply';
  }

  @override
  String get wifi_noReply => '無線機から応答がありません。もう一度お試しください。';

  @override
  String get wifi_restartTitle => '無線機を再起動しますか？';

  @override
  String get wifi_later => '後で';

  @override
  String get wifi_loadFailed => '無線機からWi‑Fi設定を読み込めませんでした。';

  @override
  String wifi_connectedTo(String address) {
    return '接続済み · $address';
  }

  @override
  String get wifi_notConnected => 'Wi‑Fiに接続されていません';

  @override
  String wifi_portNote(int port) {
    return '同じネットワーク上のアプリは、ポート$portで接続できます';
  }

  @override
  String get wifi_connectOverWifi => 'Wi‑Fiで接続';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTraxはこの無線機との接続を切り、$address、ポート$portが入力されたTCP画面を開きます。そこで「接続する」をタップしてください。';
  }

  @override
  String get wifi_noteRestart => '変更は無線機の再起動後に反映されます。';

  @override
  String get wifi_noteSecurity =>
      'Wi‑Fiネットワーク上の誰でも、ポート5000で無線機に接続できます。これにはパスワードがありません。';

  @override
  String get wifi_noteBattery => 'Wi‑Fiを使うと無線機がスリープしなくなるため、バッテリーの減りが早くなります。';

  @override
  String get wifi_noteWrongPassword =>
      'パスワードが間違っていると、無線機は数秒ごとに接続を試み続けます。Bluetoothは引き続き使えます。';

  @override
  String get room_selfDemoteWarning =>
      '自分自身のアクセス権を変更しようとしています。管理者ロールを失うと、ルーム本体のコンソールからしか戻せません。';

  @override
  String get scanner_offlineMaps => 'オフライン地図';

  @override
  String get appSettings_offlineMaps => 'オフライン地図';

  @override
  String get appSettings_offlineMapsNone => '未ダウンロード';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count地域',
      one: '1地域',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '海図エリア$count件',
      one: '海図エリア1件',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '更新$count件あり',
      one: '更新1件あり',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly => 'Wi‑Fi接続時のみ地図をダウンロード';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      '地図のダウンロードはWi‑Fiに接続するまで待機します';

  @override
  String get offlineMaps_title => 'オフライン地図';

  @override
  String get offlineMaps_tabMaps => '地図';

  @override
  String get offlineMaps_tabCharts => '海図';

  @override
  String get offlineMaps_chartsNotice => '航海用ではありません · 理由は？';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'おすすめ · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => '沿岸別の海図エリア';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countエリア',
      one: '1エリア',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '$count件ダウンロード済み';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '$count件選択中';
  }

  @override
  String get offlineMaps_selectAll => 'すべて選択';

  @override
  String get offlineMaps_clearSelection => '選択解除';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return '$coastsにも含まれます';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'まだ利用できません';

  @override
  String get offlineMaps_chartsHint => 'NOAA海図は「海図」タブで沿岸ごとに選びます。';

  @override
  String offlineMaps_chartsName(String area) {
    return '$areaのNOAA海図';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countエリア',
      one: '1エリア',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'ダウンロード済み';

  @override
  String get offlineMaps_refresh => '新しい地図を確認';

  @override
  String get offlineMaps_loading => '利用できる地図を読み込み中…';

  @override
  String get offlineMaps_serverError => '地図サーバーに接続できません';

  @override
  String get offlineMaps_unavailable => '利用できる地図はまだありません';

  @override
  String get offlineMaps_unavailableHint => '後でもう一度確認してください。';

  @override
  String get offlineMaps_chartsUnavailable => '利用できるNOAA海図はまだありません';

  @override
  String offlineMaps_cachedFrom(String date) {
    return '$date時点のリストを表示中';
  }

  @override
  String get offlineMaps_needsNewerApp => '最新の地図を入手するには、MeshTraxを更新してください。';

  @override
  String get offlineMaps_world => '世界';

  @override
  String get offlineMaps_suggested => 'おすすめ';

  @override
  String get offlineMaps_regions => '地域';

  @override
  String offlineMaps_regionsIn(String name) {
    return '$nameの地域';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count件を含む';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return 'この端末のオフライン地図：$size';
  }

  @override
  String offlineMaps_updates(int count) {
    return '更新（$count）';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'すべて更新 $size';
  }

  @override
  String get offlineMaps_downloading => 'ダウンロード中';

  @override
  String get offlineMaps_update => '更新';

  @override
  String offlineMaps_downloadedOn(String date) {
    return '$dateにダウンロード';
  }

  @override
  String get offlineMaps_updateAvailable => '更新あり';

  @override
  String get offlineMaps_otherFiles => 'その他の地図ファイル';

  @override
  String get offlineMaps_emptyTitle => 'オフライン地図はまだありません';

  @override
  String get offlineMaps_emptyBody => '地域をダウンロードすると、通信なしで地図を使えます。';

  @override
  String get offlineMaps_findMaps => '地図を探す';

  @override
  String offlineMaps_deleteTitle(String name) {
    return '$nameを削除しますか？';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return '$sizeの空きができます。後でもう一度ダウンロードできます。';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$nameを削除しました';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get offlineMaps_kindMap => '地図';

  @override
  String get offlineMaps_kindMapDetail => 'OpenStreetMapの道路、トレイル、地名';

  @override
  String get offlineMaps_kindContours => '等高線';

  @override
  String get offlineMaps_kindContoursDetail => '標高を示す線';

  @override
  String get offlineMaps_kindUsgs => 'USGS地形図';

  @override
  String get offlineMaps_kindUsgsDetail => 'トレイル、川、保護区';

  @override
  String get offlineMaps_kindTerrain => '陰影起伏';

  @override
  String get offlineMaps_kindTerrainDetail => '山や丘を地図の下に陰影で表示';

  @override
  String get offlineMaps_kindCharts => 'NOAA海図';

  @override
  String get offlineMaps_usOnly => '米国のみ';

  @override
  String offlineMaps_download(String size) {
    return 'ダウンロード $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'ダウンロード';

  @override
  String offlineMaps_largeDownload(String size) {
    return '大きなダウンロードです（$size）。Wi‑Fiを使い、端末を充電しながら行ってください。';
  }

  @override
  String get offlineMaps_waiting => '待機中…';

  @override
  String get offlineMaps_checking => 'ダウンロードを確認中…';

  @override
  String get offlineMaps_retrying => '再試行中…';

  @override
  String offlineMaps_failed(String error) {
    return 'ダウンロードに失敗しました：$error';
  }

  @override
  String get offlineMaps_pause => '一時停止';

  @override
  String get offlineMaps_resume => '再開';

  @override
  String get offlineMaps_deleteRegion => '地域を削除';

  @override
  String get offlineMaps_notInCatalogue => 'この地域では利用できません';

  @override
  String get offlineMaps_notificationRunning => '地図をダウンロード中';

  @override
  String get offlineMaps_notificationPaused => '地図のダウンロードを一時停止中';

  @override
  String get offlineMaps_notificationFailed => '地図のダウンロードに失敗しました';

  @override
  String get offlineMaps_clearTileCache => 'オンライン地図のキャッシュを消去';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      '閲覧中に保存されたオンライン地図のタイルを削除しますか？ダウンロードした地図は残ります。';

  @override
  String get offlineMaps_tileCacheCleared => 'オンライン地図のキャッシュを削除しました';

  @override
  String get map_notForNavigation => '航海用ではありません';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTraxはNOAAの海図データからこれらの海図を描画し、無線機の周りの水域を確認して計画を立てる助けにしています。公式の海図ではありません。これを頼りに操船しないでください。';

  @override
  String get map_chartsNoticeWhy => '理由：';

  @override
  String get map_chartsNoticeOutOfDate =>
      '内容が古くなります。NOAAは海図を常に修正していますが、ダウンロードした海図は「オフライン地図」で更新するまでそのままです。';

  @override
  String get map_chartsNoticeLeftOut =>
      '省略された情報があります。多くの海図記号、灯火の分弧、注記は描画されず、一部のラベルは拡大するまで表示されません。';

  @override
  String get map_chartsNoticePositions =>
      '位置が誤っていたり古かったりします。GPSは10 m (30 ft)以上ずれることがあり、ノードの位置は最後に報告された場所にすぎません。';

  @override
  String get map_chartsNoticeNotPlotter => 'MeshTraxは認定されたチャートプロッターではありません。';

  @override
  String get map_chartsNoticeUse =>
      '航海には、公式で最新のNOAA海図（紙の海図、または認定チャートプロッターでのNOAA ENC）と、最新の水路通報を使ってください。';

  @override
  String get map_sourceOnline => 'オンライン';

  @override
  String get map_sourceOffline => 'オフライン';

  @override
  String get map_downloadForDetail => '詳細を見るには地域をダウンロード';

  @override
  String get map_zoomInForOfflineMap => '拡大するとオフライン地図が表示されます';

  @override
  String get map_noCharts => 'ここには海図がありません';

  @override
  String get map_myLocation => '現在地';

  @override
  String get map_zoomIn => '拡大';

  @override
  String get map_zoomOut => '縮小';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPSオン';

  @override
  String get gps_off => 'GPSオフ';

  @override
  String get gps_onHint => '無線機はGPSで位置を更新します。';

  @override
  String get gps_offHint =>
      'オフにすると無線機のバッテリーを節約できます。オンにすると、位置がわかるまで数分かかることがあります。';

  @override
  String get gps_asking => '無線機に問い合わせ中...';

  @override
  String get gps_noPosition => 'まだ位置がわかりません。屋外では、最初の測位に数分かかることがあります。';

  @override
  String get gps_position => '位置';

  @override
  String get gps_altitude => '高度';

  @override
  String gps_readAgo(String ago) {
    return '$ago前に無線機から取得';
  }

  @override
  String get gps_turnOnTitle => 'GPSをオンにしますか？';

  @override
  String get gps_turnOnBody => '無線機のGPSはオフです。オンにすると、位置がわかるまで数分かかることがあります。';

  @override
  String get gps_turnOn => 'オンにする';

  @override
  String get gps_notNow => '今はしない';

  @override
  String get map_zoomInForCharts => '拡大すると海図が表示されます';

  @override
  String map_downloadRegion(String region, String size) {
    return '$regionをダウンロード · $size';
  }

  @override
  String get mapLayers_title => '地図レイヤー';

  @override
  String get mapLayers_mapType => '地図の種類';

  @override
  String get mapLayers_standard => '標準';

  @override
  String get mapLayers_usgs => 'USGS地形図';

  @override
  String get mapLayers_charts => '海図';

  @override
  String get mapLayers_notDownloaded => '未ダウンロード';

  @override
  String get mapLayers_offlineOnly => 'オフラインのみ';

  @override
  String get mapLayers_details => '地図の詳細';

  @override
  String get mapLayers_contours => '等高線';

  @override
  String get mapLayers_hillShading => '陰影起伏';

  @override
  String get mapLayers_dark => 'ダーク地図';

  @override
  String get mapLayers_downloadedAreas => 'ダウンロード済みのエリア';

  @override
  String get mapLayers_nodes => 'ノード';

  @override
  String get mapLayers_pins => 'ピン';

  @override
  String get mapLayers_guessed => '推定位置';

  @override
  String get mapLayers_moreFilters => 'その他のフィルター';

  @override
  String get mapLayers_moreFiltersDetail => '最終確認、鍵のプレフィックス、重複';

  @override
  String get map_legend => '凡例';

  @override
  String get scanner_map => '地図';

  @override
  String get structured_openMap => '地図を開く';

  @override
  String get structured_addToCalendar => 'カレンダーに追加';

  @override
  String get structured_details => '詳細';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'イベント';

  @override
  String get structured_notice => 'お知らせ';

  @override
  String get structured_allDay => '終日';

  @override
  String get structured_calendarFailed => 'カレンダーを開けませんでした';

  @override
  String get structured_today => '今日';

  @override
  String get structured_tomorrow => '明日';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日後',
      one: '1日後',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => '終了';

  @override
  String structured_dayOfDays(int day, int total) {
    return '$day日目（全$total日）';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count日間',
      one: '1日間',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => '終了日';

  @override
  String get dialog_eventSameDay => '同じ日';

  @override
  String get structured_map => '地図';

  @override
  String get structured_navigate => 'ナビ';

  @override
  String get structured_channel => 'チャンネル';

  @override
  String get structured_contact => '連絡先';

  @override
  String get structured_room => 'ルーム';

  @override
  String get structured_repeater => 'リピーター';

  @override
  String get structured_sensor => 'センサー';

  @override
  String get structured_joinChannel => 'チャンネルに参加';

  @override
  String get structured_addContact => '連絡先を追加';

  @override
  String get structured_addRoom => 'ルームを追加';

  @override
  String get structured_addRepeater => 'リピーターを追加';

  @override
  String get structured_addSensor => 'センサーを追加';

  @override
  String get structured_open => '開く';

  @override
  String get structured_added => '追加済み';

  @override
  String get tray_add => '追加';

  @override
  String get tray_myLocation => '現在地';

  @override
  String get tray_pointOnMap => '地図上の地点';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'イベント';

  @override
  String get tray_notice => 'お知らせ';

  @override
  String get tray_noRadioPosition => '無線機の位置がまだわかりません。地図上で選んでください。';

  @override
  String get dialog_insert => '挿入';

  @override
  String get dialog_eventTitle => 'タイトル';

  @override
  String get dialog_eventDate => '日付';

  @override
  String get dialog_eventStart => '開始';

  @override
  String get dialog_eventEnd => '終了';

  @override
  String get dialog_eventNoEnd => '終了時刻なし';

  @override
  String get dialog_eventPlace => '場所（任意）';

  @override
  String get dialog_pickOnMap => '地図上で選ぶ';

  @override
  String get dialog_sosTitle => 'SOSを送信';

  @override
  String get dialog_sosText => '何がありましたか？';

  @override
  String get dialog_noticeTitle => 'お知らせ';

  @override
  String get dialog_noticeText => 'みんなに知らせたいことは？';

  @override
  String get dialog_labelTitle => '地図上の地点';

  @override
  String get dialog_note => 'メモ（任意）';

  @override
  String get paste_convertLocation => '地図のリンクのようです。位置情報に変換しますか？';

  @override
  String get paste_convertEvent => 'カレンダーの共有のようです。イベントに変換しますか？';

  @override
  String get paste_convert => '変換';

  @override
  String get paste_resolving => 'リンクを確認中…';

  @override
  String get paste_resolveFailed => 'リンクを確認できませんでした';

  @override
  String get pinned_dismiss => '閉じる';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'チャンネル$nameに参加しますか？';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'すでに$nameに参加しています';
  }

  @override
  String link_channelJoined(String name) {
    return '$nameに参加しました';
  }

  @override
  String get map_pickPositionHint => '地図をタップして位置を選んでください';

  @override
  String get map_legendMesh => 'メッシュ';

  @override
  String get chartLegend_title => '海図記号';

  @override
  String get chartLegend_sectionBuoys => '浮標と立標';

  @override
  String get chartLegend_sectionLights => '灯火';

  @override
  String get chartLegend_sectionHazards => '危険箇所';

  @override
  String get chartLegend_sectionTides => '潮汐と潮流';

  @override
  String get chartLegend_sectionDepths => '水深と底質';

  @override
  String get chartLegend_sectionAreas => '区域・航路・線';

  @override
  String get chartLegend_sectionLandmarks => '目標物';

  @override
  String get chartLegend_sectionAbbreviations => '略語';

  @override
  String get chartLegend_chartNo1 => 'すべての海図記号：U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => '緑色の円筒形浮標';

  @override
  String get chartLegend_portBuoyHint => '海から入るとき、左手に見て進む';

  @override
  String get chartLegend_starboardBuoy => '赤色の円錐形浮標';

  @override
  String get chartLegend_starboardBuoyHint => '入るときは右手に見て進む：戻るときは赤を右に';

  @override
  String get chartLegend_junctionBuoy => '横帯のある浮標';

  @override
  String get chartLegend_junctionBuoyHint => '航路の分岐点：一番上の帯の色の標識として扱う';

  @override
  String get chartLegend_safeWaterBuoy => '赤白の縦じま';

  @override
  String get chartLegend_safeWaterBuoyHint => '周囲すべてが安全な水域。航路の入口に多い';

  @override
  String get chartLegend_isolatedDangerBuoy => '黒と赤の横帯';

  @override
  String get chartLegend_isolatedDangerBuoyHint => '周りが安全な水域にある小さな危険物：近づかない';

  @override
  String get chartLegend_specialBuoy => '黄色の浮標';

  @override
  String get chartLegend_specialBuoyHint => '特殊標識で、操船の目印ではない：錨地、ケーブル、調査など';

  @override
  String get chartLegend_cardinalBuoy => '黒と黄';

  @override
  String get chartLegend_cardinalBuoyHint => '方位標識：示す方位の側を通る（米国ではまれ）';

  @override
  String get chartLegend_mooringBuoy => '係船浮標';

  @override
  String get chartLegend_portBeacon => '緑色の四角形立標';

  @override
  String get chartLegend_portBeaconHint => '緑の浮標と同じ：入るときは左手に見て進む';

  @override
  String get chartLegend_starboardBeacon => '赤色の三角形立標';

  @override
  String get chartLegend_starboardBeaconHint => '赤の浮標と同じ：入るときは右手に見て進む';

  @override
  String get chartLegend_otherBeacon => 'ひし形の立標';

  @override
  String get chartLegend_otherBeaconHint => '情報や警告を示す。航路の左右を示すものではない';

  @override
  String get chartLegend_beaconTower => '灯標・立標の構造物';

  @override
  String get chartLegend_topmark => '頭標';

  @override
  String get chartLegend_topmarkHint => '標識の上の形が意味を補う';

  @override
  String get chartLegend_light => '灯火';

  @override
  String get chartLegend_lightHint => 'マゼンタの光芒は灯火を示し、ラベルで光り方がわかる';

  @override
  String get chartLegend_lightExample => '緑の閃光、4秒ごと';

  @override
  String get chartLegend_lightExampleHint => '灯火のラベル：灯質、色、周期の順';

  @override
  String get chartLegend_lightFixed => '不動光';

  @override
  String get chartLegend_lightFixedHint => '一定の明るさで光り続ける';

  @override
  String get chartLegend_lightFlashing => '閃光';

  @override
  String get chartLegend_lightFlashingHint => '短く光り、その間の暗い時間が長い';

  @override
  String get chartLegend_lightGroup => '群閃光';

  @override
  String get chartLegend_lightGroupHint => 'まとまって光り（ここでは2回）、その後暗くなる';

  @override
  String get chartLegend_lightComposite => '複合群閃光';

  @override
  String get chartLegend_lightCompositeHint => '2回光って次に1回：航路の分岐点を示す';

  @override
  String get chartLegend_lightQuick => '急閃光';

  @override
  String get chartLegend_lightQuickHint => '1秒に約1回光る';

  @override
  String get chartLegend_lightIsophase => '等明暗光';

  @override
  String get chartLegend_lightIsophaseHint => '明るい時間と暗い時間が同じ';

  @override
  String get chartLegend_lightOcculting => '明暗光';

  @override
  String get chartLegend_lightOccultingHint => '点灯している時間が消えている時間より長い';

  @override
  String get chartLegend_lightMorse => 'モールス符号A';

  @override
  String get chartLegend_lightMorseHint => '短・長：安全水域';

  @override
  String get chartLegend_lightAlternating => '互光';

  @override
  String get chartLegend_lightAlternatingHint => '色が変わる';

  @override
  String get chartLegend_lightColours => '白、赤、緑、黄';

  @override
  String get chartLegend_lightPeriod => '周期';

  @override
  String get chartLegend_lightPeriodHint => '1回のサイクルにかかる秒数';

  @override
  String get chartLegend_rock => '暗岩';

  @override
  String get chartLegend_rockHint => '常に水面下にあるが、浅いことがある';

  @override
  String get chartLegend_rockAwash => '洗岩';

  @override
  String get chartLegend_rockAwashHint => '低潮時に水面近くにある';

  @override
  String get chartLegend_rockCovers => '干出岩';

  @override
  String get chartLegend_rockCoversHint => '低潮時に現れ、高潮時に隠れる';

  @override
  String get chartLegend_wreckDangerous => '危険な沈船';

  @override
  String get chartLegend_wreckDangerousHint => '船がぶつかるほど浅い';

  @override
  String get chartLegend_wreck => '沈船';

  @override
  String get chartLegend_wreckHint => '水上の船が通れる深さ。錨を下ろさない';

  @override
  String get chartLegend_wreckShowing => '一部露出した沈船';

  @override
  String get chartLegend_wreckShowingHint => '一部が水面上に出ている';

  @override
  String get chartLegend_obstruction => '障害物';

  @override
  String get chartLegend_obstructionHint => '海底にある何か。わかっていれば水深を表示';

  @override
  String get chartLegend_foulGround => '険悪地';

  @override
  String get chartLegend_foulGroundHint => '上を通るのは安全だが、錨泊やトロール漁はしない';

  @override
  String get chartLegend_hazardArea => '危険区域の境界';

  @override
  String get chartLegend_hazardAreaHint => '内側に岩、沈船、障害物がある';

  @override
  String get chartLegend_pile => '杭';

  @override
  String get chartLegend_floodStream => '上げ潮流';

  @override
  String get chartLegend_floodStreamHint => '潮が満ちるときの潮流';

  @override
  String get chartLegend_ebbStream => '下げ潮流';

  @override
  String get chartLegend_ebbStreamHint => '潮が引くときの潮流';

  @override
  String get chartLegend_current => '海流';

  @override
  String get chartLegend_currentHint => '潮の満ち引きに関係なく同じ向きに流れる';

  @override
  String get chartLegend_rips => '激潮・渦';

  @override
  String get chartLegend_ripsHint => '荒れて渦巻く水面';

  @override
  String get chartLegend_breakers => '砕け波';

  @override
  String get chartLegend_breakersHint => '浅瀬で砕ける波';

  @override
  String get chartLegend_sounding => '水深';

  @override
  String get chartLegend_soundingHint => '平均的な低潮時の水深';

  @override
  String get chartLegend_depthContour => '等深線';

  @override
  String get chartLegend_depthContourHint => 'ラベルが水深を示す';

  @override
  String get chartLegend_drying => '低潮時に干出';

  @override
  String get chartLegend_dredged => '浚渫水路';

  @override
  String get chartLegend_dredgedHint => '表示の水深に保たれている';

  @override
  String get chartLegend_swept => '掃海区域';

  @override
  String get chartLegend_sweptHint => '表示の水深まで障害物がないことを確認済み';

  @override
  String get chartLegend_unsurveyed => '未測量';

  @override
  String get chartLegend_unsurveyedHint => '水深が測られていない';

  @override
  String get chartLegend_weed => '海藻';

  @override
  String get chartLegend_restricted => '制限区域';

  @override
  String get chartLegend_restrictedHint => '立ち入りが制限される。短い線は内側を向く';

  @override
  String get chartLegend_regulatedLimit => '規制区域の境界';

  @override
  String get chartLegend_regulatedLimitHint => '錨地、ケーブル区域、射撃区域など：ラベルを参照';

  @override
  String get chartLegend_greyLimit => '土捨場、漁場、養殖場';

  @override
  String get chartLegend_anchorage => '錨地';

  @override
  String get chartLegend_anchorBerth => '錨泊位置';

  @override
  String get chartLegend_noAnchoring => '錨泊禁止';

  @override
  String get chartLegend_caution => '注意区域';

  @override
  String get chartLegend_cautionHint => 'ここでは特に注意する';

  @override
  String get chartLegend_trafficLane => '通航路';

  @override
  String get chartLegend_trafficLaneHint => '大型船の一方通行：横切るときは直角に';

  @override
  String get chartLegend_separationZone => '分離帯';

  @override
  String get chartLegend_separationZoneHint => '通航路の間：入らない';

  @override
  String get chartLegend_precautionary => '警戒水域';

  @override
  String get chartLegend_precautionaryHint => '船が集まる：注意する';

  @override
  String get chartLegend_fairway => '航路';

  @override
  String get chartLegend_fairwayHint => '主要な水路';

  @override
  String get chartLegend_track => '推薦航路';

  @override
  String get chartLegend_ferry => 'フェリー航路';

  @override
  String get chartLegend_leadingLine => '導線';

  @override
  String get chartLegend_leadingLineHint => '2つの標識を一直線に重ねて進むと、航路から外れない';

  @override
  String get chartLegend_cable => '海底電線';

  @override
  String get chartLegend_cableHint => '錨を下ろさない';

  @override
  String get chartLegend_pipeline => '海底パイプライン';

  @override
  String get chartLegend_pipelineHint => '錨を下ろさない';

  @override
  String get chartLegend_overhead => '架空電線';

  @override
  String get chartLegend_overheadHint => '下を通れる高さはVCと表示';

  @override
  String get chartLegend_tower => '塔';

  @override
  String get chartLegend_windTurbine => '風力発電機';

  @override
  String get chartLegend_chimney => '煙突';

  @override
  String get chartLegend_mast => 'マスト・アンテナ';

  @override
  String get chartLegend_church => '教会・尖塔';

  @override
  String get chartLegend_flagstaff => '旗ざお';

  @override
  String get chartLegend_dome => 'ドーム';

  @override
  String get chartLegend_landmark => 'その他の目標物';

  @override
  String get chartLegend_abbrAnch => '錨地';

  @override
  String get chartLegend_abbrWk => '沈船';

  @override
  String get chartLegend_abbrBr => '砕け波';

  @override
  String get chartLegend_abbrWd => '海藻';

  @override
  String get chartLegend_abbrVar => '磁気偏差';

  @override
  String get chartLegend_abbrVc => '橋や電線の下を通れる高さ';

  @override
  String get chartLegend_abbrTr => '塔';

  @override
  String get chartLegend_abbrCh => '教会';

  @override
  String get chartLegend_abbrChy => '煙突';

  @override
  String get chartLegend_abbrFs => '旗ざお';

  @override
  String get chartLegend_abbrTk => 'タンク';

  @override
  String get chartLegend_abbrRBn => '無線標識';

  @override
  String get chartLegend_abbrCg => '沿岸警備隊の施設';

  @override
  String get chartLegend_abbrRacon => 'レーダービーコン：レーダーに映る';

  @override
  String get chartLegend_abbrFog => '霧信号：ホーン、鐘、ゴング、汽笛、サイレン';

  @override
  String get chartLegend_abbrVAis => '仮想航路標識：AISにのみ表示';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from～$to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return '$depthより深い';
  }

  @override
  String get parkLegend_title => '公園・トレイルの記号';

  @override
  String get parkLegend_campsite => 'キャンプ場';

  @override
  String get parkLegend_picnicSite => 'ピクニック場';

  @override
  String get parkLegend_shelter => '避難小屋';

  @override
  String get parkLegend_toilets => 'トイレ';

  @override
  String get parkLegend_drinkingWater => '飲料水';

  @override
  String get parkLegend_parking => '駐車場';

  @override
  String get parkLegend_viewpoint => '展望所';

  @override
  String get parkLegend_attraction => '観光スポット';

  @override
  String get parkLegend_gate => 'ゲート';

  @override
  String get parkLegend_telephone => '電話';

  @override
  String get parkLegend_information => '案内板';

  @override
  String get parkLegend_guidepost => '道標';

  @override
  String get dialog_noticeExpires => '有効期限';

  @override
  String get dialog_noticeNoExpiry => '無期限';

  @override
  String get dialog_noticeExpiryRequired => '日付を選択（ルームでは必須）';

  @override
  String get dialog_noticeExpiryTime => '時刻';

  @override
  String get dialog_noticeEndOfDay => 'その日の終わり';

  @override
  String structured_until(String when) {
    return '$whenまで';
  }

  @override
  String get structured_expired => '期限切れ';

  @override
  String get structured_announcement => 'アナウンス';

  @override
  String structured_locationOf(String name) {
    return '$nameの位置情報';
  }

  @override
  String get reaction_searchHint => '絵文字を検索';

  @override
  String get reaction_noResults => '絵文字が見つかりません';

  @override
  String get share_qrAndLink => 'QRコードとリンクを共有';

  @override
  String get share_roomTitle => 'ルームを共有';

  @override
  String get share_contactTitle => '連絡先を共有';

  @override
  String get share_roomInstructions =>
      'QRコードをスキャンして、このルームを追加します。ログインにはルームのパスワードが必要です。';

  @override
  String get share_contactInstructions => 'QRコードをスキャンして、この連絡先を追加します。';

  @override
  String get clearChat_body =>
      'このチャットのメッセージを、この端末から削除します。新しいメッセージは引き続きここに届きます。';

  @override
  String get clearChat_olderThanDay => '1日以上前のメッセージ';

  @override
  String get clearChat_olderThanWeek => '1週間以上前のメッセージ';

  @override
  String get clearChat_olderThanMonth => '1か月以上前のメッセージ';

  @override
  String get clearChat_everything => 'すべてのメッセージ';

  @override
  String get chats_markAllRead => 'すべて既読にする';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count件のチャットを既読にしますか？',
      one: '1件のチャットを既読にしますか？',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => '既読にする';

  @override
  String get chats_nothingUnread => '未読メッセージはありません';

  @override
  String get chats_draft => '下書き';

  @override
  String get contact_teleBlockedTitle => '無線機の設定でブロックされています';

  @override
  String contact_teleBlockedBody(String name) {
    return '無線機のプライバシー設定では誰とも共有されないため、$nameには届きません。許可した連絡先に届くよう変更しますか？';
  }

  @override
  String get contact_teleNotNow => '今はしない';

  @override
  String contact_teleRadioDenies(String mode) {
    return '無線機はこれを誰とも共有しません（$mode）';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return '無線機はこれを全員と共有します（$mode）';
  }

  @override
  String get contact_sharesPosition => 'あなたの位置情報を取得できます';

  @override
  String get pathfinder_meshTitle => '別のメッシュですか？';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '接続後に聞こえた$heard台のリピーターのうち$unknown台は、Pathfinderの地図「$graph」にないものです。この地域用に新しい地図を始めますか？元の地図は残り、Pathfinderの画面で戻せます。';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return '接続後に聞こえたリピーターの大半は、Pathfinderの地図「$graph」ではなく「$other」にあります。そちらに切り替えますか？';
  }

  @override
  String get pathfinder_meshNew => '新しい地図';

  @override
  String get pathfinder_meshSwitch => '切り替える';

  @override
  String get pathfinder_meshKeep => 'このままにする';

  @override
  String get pathfinder_graphNameTitle => '新しい地図の名前';

  @override
  String get pathfinder_graphNameHint => '例：ワシントン';

  @override
  String get pathfinder_graphCreate => '作成';

  @override
  String get route_pathPaved => 'Paved';

  @override
  String get route_pathDirt => 'Dirt';

  @override
  String get route_pathHiking => 'Hiking';

  @override
  String route_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String route_hoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String route_to(String destination) {
    return 'To $destination';
  }

  @override
  String get route_clear => 'Clear route';

  @override
  String get route_finding => 'Finding a route…';

  @override
  String get route_none => 'No route found';

  @override
  String route_endsShortPaved(String distance, String destination) {
    return 'Ends $distance before $destination, where the pavement ends.';
  }

  @override
  String route_endsShortDirt(String distance, String destination) {
    return 'Ends $distance before $destination, where the road ends.';
  }

  @override
  String route_endsShortHiking(String distance, String destination) {
    return 'Ends $distance before $destination, where the trails end.';
  }

  @override
  String get route_directions => 'Directions';

  @override
  String get route_here => 'Route here';

  @override
  String get place_nrhp => 'National Register of Historic Places';

  @override
  String get place_textCredit => 'Text: Wikipedia, CC BY-SA 4.0';

  @override
  String place_photoCredit(String author, String licence) {
    return 'Photo: $author, $licence';
  }

  @override
  String get search_hint => 'Search places, addresses or coordinates';

  @override
  String get search_noPlaces =>
      'Download Points of interest for a region to search its places. Coordinates work without it.';

  @override
  String get search_noResults => 'No matches';

  @override
  String get coordFormat_decimalDegrees => 'Decimal degrees';

  @override
  String get coordFormat_degreesMinutes => 'Degrees and minutes';

  @override
  String get coordFormat_dms => 'Degrees, minutes, seconds';

  @override
  String get coordFormat_utm => 'UTM';

  @override
  String get coordFormat_mgrs => 'MGRS / USNG';

  @override
  String get coordFormat_maidenhead => 'Maidenhead grid';

  @override
  String get coordFormat_geohash => 'Geohash';

  @override
  String get poiKind_peak => 'Peak';

  @override
  String get poiKind_volcano => 'Volcano';

  @override
  String get poiKind_saddle => 'Saddle';

  @override
  String get poiKind_pass => 'Mountain pass';

  @override
  String get poiKind_spring => 'Spring';

  @override
  String get poiKind_hotSpring => 'Hot spring';

  @override
  String get poiKind_waterfall => 'Waterfall';

  @override
  String get poiKind_cave => 'Cave';

  @override
  String get poiKind_arch => 'Arch';

  @override
  String get poiKind_glacier => 'Glacier';

  @override
  String get poiKind_rock => 'Rock';

  @override
  String get poiKind_cliff => 'Cliff';

  @override
  String get poiKind_beach => 'Beach';

  @override
  String get poiKind_trailhead => 'Trailhead';

  @override
  String get poiKind_campground => 'Campground';

  @override
  String get poiKind_picnicSite => 'Picnic site';

  @override
  String get poiKind_hut => 'Hut';

  @override
  String get poiKind_shelter => 'Shelter';

  @override
  String get poiKind_drinkingWater => 'Drinking water';

  @override
  String get poiKind_toilets => 'Toilets';

  @override
  String get poiKind_viewpoint => 'Viewpoint';

  @override
  String get poiKind_attraction => 'Attraction';

  @override
  String get poiKind_mine => 'Mine';

  @override
  String get poiKind_mineShaft => 'Mine shaft';

  @override
  String get poiKind_adit => 'Adit';

  @override
  String get poiKind_ghostTown => 'Ghost town';

  @override
  String get poiKind_ruins => 'Ruins';

  @override
  String get poiKind_monument => 'Monument';

  @override
  String get poiKind_memorial => 'Memorial';

  @override
  String get poiKind_fort => 'Fort';

  @override
  String get poiKind_historic => 'Historic place';

  @override
  String get poiKind_rangerStation => 'Ranger station';

  @override
  String get poiKind_visitorCenter => 'Visitor center';

  @override
  String get poiKind_hospital => 'Hospital';

  @override
  String get poiKind_police => 'Police';

  @override
  String get poiKind_fireStation => 'Fire station';

  @override
  String get poiKind_emergencyPhone => 'Emergency phone';

  @override
  String get poiKind_fuel => 'Fuel';

  @override
  String get poiKind_museum => 'Museum';

  @override
  String get poiKind_city => 'City';

  @override
  String get poiKind_town => 'Town';

  @override
  String get poiKind_locality => 'Area';

  @override
  String get poiKind_lake => 'Lake';

  @override
  String get poiKind_river => 'River';

  @override
  String get poiKind_valley => 'Valley';

  @override
  String get poiKind_range => 'Mountain range';

  @override
  String get poiKind_trail => 'Trail';

  @override
  String get poiKind_dirtRoad => 'Dirt road';

  @override
  String get poiKind_road => 'Road';

  @override
  String get poiKind_address => 'Address';

  @override
  String get poiKind_place => 'Place';

  @override
  String get offlineMaps_kindRouting => 'Trail routing';

  @override
  String get offlineMaps_kindRoutingDetail =>
      'Routes on trails, dirt roads and paved roads';

  @override
  String get offlineMaps_kindPoi => 'Points of interest';

  @override
  String get offlineMaps_kindPoiDetail =>
      'Places to search for, with Wikipedia';

  @override
  String get offlineMaps_kindAddresses => 'Addresses';

  @override
  String get offlineMaps_kindAddressesDetail => 'House addresses to search for';

  @override
  String get map_search => 'Search';

  @override
  String get route_fromHere => 'Route from here';

  @override
  String get route_startSet => 'Route start set. Now choose where to go.';

  @override
  String get route_noStart =>
      'No starting position. Long-press the map and choose Route from here.';

  @override
  String get route_noData =>
      'Download Trail routing for this region in Offline maps to find routes here.';

  @override
  String get route_pin => 'Dropped pin';

  @override
  String get appSettings_coordinateFormat => 'Coordinate format';

  @override
  String get map_copyPosition => 'Copy position';

  @override
  String get poiKind_park => 'Park';

  @override
  String get poiKind_protectedArea => 'Protected area';

  @override
  String get common_more => 'More';

  @override
  String get common_less => 'Less';
}
