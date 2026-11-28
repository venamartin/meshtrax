// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get tray_photo => '写真';

  @override
  String get photo_settingsTitle => '写真';

  @override
  String photo_enableHint(String size) {
    return '無線で写真を送ったり見たりできます。この端末に$sizeの写真用モデルが必要です。';
  }

  @override
  String photo_sendTitle(String channel) {
    return '$channelに送る写真';
  }

  @override
  String get photo_squareIntro => '写真を選んでから、送る正方形の範囲を選んでください。';

  @override
  String get photo_takePhoto => '写真を撮る';

  @override
  String get photo_choosePhoto => '写真を選ぶ';

  @override
  String get photo_chooseAnother => '別の写真を選ぶ';

  @override
  String get photo_cropHint => '大事な部分が正方形いっぱいになるまで、移動やズームをしてください。';

  @override
  String get photo_preview => 'プレビュー';

  @override
  String get photo_changeCrop => '切り抜きを変更';

  @override
  String get photo_checkingAndCoding => '写真をチェックしてエンコードしています…';

  @override
  String get photo_modelMissing =>
      'この端末には写真用モデルがありません。ダウンロードするには、「アプリ設定」の「メッセージング」で「写真」をオンにしてください。';

  @override
  String get photo_previewNoMemory =>
      'ほかの人に見える写真を表示するには、ここではメモリが足りません。それでも送信はできます。';

  @override
  String get photo_rebuildingPreview => 'ほかの人に見える写真を再構成しています… 約20秒';

  @override
  String photo_prepareFailed(String error) {
    return '写真を準備できませんでした：$error';
  }

  @override
  String get photo_flaggedNotSent => 'この写真は送信できません：安全チェックで問題ありと判定されました。';

  @override
  String get photo_tagTitle => 'タグ（任意）';

  @override
  String get photo_blurFaces => '顔をぼかす';

  @override
  String photo_facesBlurred(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人の顔をぼかしました',
    );
    return '$_temp0';
  }

  @override
  String photo_facesDarkened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count人の顔をグレーで覆いました：ぼかしでは写真が安全チェックを通過しませんでした',
    );
    return '$_temp0';
  }

  @override
  String get photo_includePosition => '位置情報を含める';

  @override
  String get photo_noPosition => '無線機に位置情報がありません';

  @override
  String get photo_distance10km => '10 km';

  @override
  String get photo_distance600m => '600 m';

  @override
  String get photo_distance40m => '40 m';

  @override
  String get photo_distance2m => '2 m';

  @override
  String photo_positionAt(String position, String distance) {
    return '$position（精度約$distance）';
  }

  @override
  String get photo_zeroHop => 'ゼロホップ';

  @override
  String get photo_subjectOnly => '被写体のみ';

  @override
  String get photo_autoCrop => '自動切り抜き';

  @override
  String get photo_tapWhatMatters => '大事なものをタップしてください。ほかのものもタップすると追加されます。';

  @override
  String get photo_outlining => '輪郭を検出中…';

  @override
  String get photo_clearTaps => 'クリア';

  @override
  String get photo_nothingThere => 'そこには輪郭を取れるものがありません。対象の中央をタップしてください。';

  @override
  String get photo_zeroHopNearbyOnly => 'このチャンネルは「近くだけ」です';

  @override
  String get photo_repairPacket => '修復用パケット';

  @override
  String photo_sendFigures(int packets, String sendTime) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: '$packetsパケット',
    );
    return '$_temp0 · 送信に約$sendTime';
  }

  @override
  String photo_seconds(String seconds) {
    return '$seconds秒';
  }

  @override
  String photo_blockedWaitRepeaters(int packets, int gap, int minutes) {
    return 'MeshCoreの周波数では、無線機がリピーター経由で送れる写真は$gap分に1枚です。リピーター経由の次の写真はあと$minutes分で送れます。ゼロホップなら今すぐ1枚送れます。';
  }

  @override
  String get photo_send => '送信';

  @override
  String get photo_sending => '送信中…';

  @override
  String photo_sendingPacket(int sent, int total) {
    return 'パケット $sent/$total';
  }

  @override
  String photo_sendingRepairPacket(int sent, int total) {
    return 'パケット $sent/$total（修復用）';
  }

  @override
  String photo_sendingPacketAgain(int sent, int total) {
    return 'パケット $sent/$total（再送）';
  }

  @override
  String photo_askingObservers(int sent, int total) {
    return 'Packet $sent of $total: asking observers';
  }

  @override
  String photo_waitTitle(int minutes) {
    return 'Next photo through repeaters in $minutes min';
  }

  @override
  String photo_waitBody(int packets, int gap) {
    return 'On MeshCore frequencies, photos share the air with everyone: after a photo of $packets packets through repeaters, the next waits $gap minutes. A zero hop photo reaches only the radios near you, and can go now.';
  }

  @override
  String get photo_zeroHopWaiting =>
      'Photos through repeaters wait after your last one';

  @override
  String photo_getPhotosHint(String size) {
    return 'To see it, this phone needs the photo model: $size.';
  }

  @override
  String get photo_photosOffHint => 'Photos are off on this phone.';

  @override
  String get photo_getPhotos => 'Turn on photos';

  @override
  String get photo_getPhotosTitle => 'Turn on photos?';

  @override
  String photo_getPhotosBody(String size) {
    return 'MeshTrax downloads the photo model, $size, so it can show the photos you receive. Keep MeshTrax open until it finishes; it also shows in App settings, Messaging, Photos.';
  }

  @override
  String get photo_getPhotosWifi => 'It waits for Wi‑Fi.';

  @override
  String photo_receiving(String id, String name, int got, int total) {
    return '📷 Photo $id from $name: $got of $total packets so far';
  }

  @override
  String photo_receivingLost(
    String id,
    String name,
    int got,
    int total,
    int lost,
  ) {
    return '📷 Photo $id from $name: $got of $total packets, $lost lost';
  }

  @override
  String get photo_askForRest => 'Ask for the rest';

  @override
  String photo_askedFor(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Asked for $count packets',
      one: 'Asked for 1 packet',
    );
    return '$_temp0';
  }

  @override
  String get photo_asking => 'Asking…';

  @override
  String get photo_othersAsked => 'Someone asked; waiting';

  @override
  String get photo_askFailed => 'Couldn\'t ask for the rest';

  @override
  String get photo_waitingToSend => 'Waiting to send';

  @override
  String photo_passedOnSome(int heard, int total) {
    return '送信済み · リピーターが$totalパケット中$heardパケットを中継';
  }

  @override
  String photo_notSent(String error) {
    return '送信できませんでした：$error';
  }

  @override
  String get photo_errorNotConnected => '無線機に接続されていません';

  @override
  String get photo_errorNoAnswer => '無線機から応答がありませんでした';

  @override
  String photo_errorRefused(int code) {
    return '無線機がパケットを拒否しました（エラー$code）';
  }

  @override
  String get photo_confirmTitle => '写真を送信';

  @override
  String photo_openChannelTitle(String channel) {
    return '$channelでの写真';
  }

  @override
  String get photo_openChannelNotEveryone =>
      'ここにいるほとんどの人には見えません：写真を表示できるのはMeshTraxだけです。';

  @override
  String photo_openChannelAirtime(String airtime, int messages) {
    return 'この写真の送信時間は$airtimeで、テキストメッセージ$messages件分です。';
  }

  @override
  String get photo_openChannelRepeaters =>
      '中継するリピーターはどれも、周囲の全員が共有している周波数で写真全体をもう一度送信します。';

  @override
  String get photo_openChannelBetter =>
      'より良い方法：相手が近くにいるならゼロホップ、または写真を見たい人とのプライベートチャンネル。余白を減らして切り抜きましょう：単純な画像ほどパケットが少なくなります。';

  @override
  String get photo_dontShowAgain => '今後は表示しない';

  @override
  String photo_confirmAirtime(int packets, String airtime, int messages) {
    return '$packetsパケット、送信時間$airtime：テキストメッセージ$messages件分です。';
  }

  @override
  String photo_confirmOpenChannel(String channel) {
    return '$channelでMeshTraxを使っている人なら誰でも見られます。ほかのアプリでは写真は表示されません。';
  }

  @override
  String get photo_confirmFlood => '受信したリピーターはどれも、もう一度送信します。';

  @override
  String get photo_confirmZeroHop => 'ゼロホップ：直接届く範囲の無線機だけが受け取ります。';

  @override
  String get photo_label => 'AIで再構成';

  @override
  String get photo_tapToView => 'タップして表示';

  @override
  String get photo_enhance => '4倍に高画質化';

  @override
  String get photo_enhancing => '高画質化中…';

  @override
  String get photo_save => '保存';

  @override
  String get photo_saved => '写真に保存しました';

  @override
  String get photo_saveFailed => '写真を保存できませんでした。';

  @override
  String get photo_details => 'この写真について';

  @override
  String photo_caption(int bytes) {
    return 'AIモデルが$bytesバイトから再構成した画像です。細部は送られたものではなく生成されたもので、標識や文字は伝わりません。実際にそこにあったものの記録ではありません。';
  }

  @override
  String get photo_enlargedNote => 'この端末で4倍に高画質化しました：細部は作られたものかもしれません。';

  @override
  String get photo_enlargeNoMemory =>
      '今は拡大するための空きメモリが足りません。ほかのアプリを閉じてから、もう一度お試しください。';

  @override
  String get photo_enlargeFlagged => '拡大した画像が安全チェックを通過しなかったため、表示されません。';

  @override
  String get photo_enlargeFailed => '写真を拡大できませんでした。';

  @override
  String get photo_enlargeAutomatically => '写真を自動で拡大';

  @override
  String get photo_enlargeAutomaticallyHint =>
      'オフ：全画面の写真をタップすると4倍に拡大します。オン：開くと同時に拡大します。';

  @override
  String get photo_ignoreTimeLimits => '写真の時間制限を無視';

  @override
  String get photo_ignoreTimeLimitsHint => 'テスト用：写真と写真の間で待たずに、リピーター経由で写真を送ります。';

  @override
  String get photo_rebuilding => '再構成中… 約20秒';

  @override
  String get photo_hiddenFlagged => '画像を非表示にしました：不適切と判定されました';

  @override
  String get photo_hiddenReported => '写真を非表示にしました：あなたが報告しました';

  @override
  String get photo_noMemory =>
      '今はこの写真を再構成するメモリが足りません。ほかのアプリを閉じるかMeshTraxを再起動してから、もう一度お試しください。';

  @override
  String get photo_rebuildFailed => 'この写真を再構成できませんでした。';

  @override
  String get photo_report => '報告';

  @override
  String photo_block(String name) {
    return '$nameをブロック';
  }

  @override
  String photo_blockedSender(String name) {
    return '$nameをブロックしました';
  }

  @override
  String get photo_reportTitle => 'この写真を報告';

  @override
  String get photo_reportBody =>
      'この端末ではすぐに写真が非表示になり、元には戻りません。報告はアプリからMeshTraxの開発者に、今すぐ、またはインターネットにつながったときに送られます。端末のそれ以外の情報は送信されません。';

  @override
  String get photo_reportInclude => '写真を含める';

  @override
  String get photo_reportIncludeHint => '写真を再構成できる、数百バイトのコードです。画像そのものではありません。';

  @override
  String get photo_reportReason => '何が問題ですか？（任意）';

  @override
  String get photo_reportedSent => '写真を非表示にし、報告を送信しました。ありがとうございます。';

  @override
  String get photo_reportedQueued => '写真を非表示にしました。報告はインターネットにつながったときに送信されます。';

  @override
  String photo_reportPending(String name) {
    return '写真の報告：$name';
  }

  @override
  String get photo_reportPendingHint => 'インターネット接続を待って送信します';

  @override
  String get photo_reportStillWaiting => 'まだインターネットにつながっていません。あとで送信されます。';

  @override
  String get photo_autoRebuild => '受信した写真を自動で再構成';

  @override
  String get photo_autoRebuildHint =>
      'オフ：写真をタップすると再構成します。オン：MeshTraxが開いていて端末のメモリが足りていれば、写真が届くたびに再構成します。';

  @override
  String get photo_modelTitle => '写真用モデル';

  @override
  String photo_modelProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get photo_modelChecking => 'ダウンロードを確認中…';

  @override
  String get photo_modelRetrying => '再試行中…';

  @override
  String get photo_modelPaused => '一時停止中';

  @override
  String get photo_modelWaitingWifi => '待機中：ダウンロードはWi‑Fi接続を待ちます';

  @override
  String get photo_modelWaiting => '待機中…';

  @override
  String photo_modelInstalled(String size) {
    return 'この端末にあります（$size）';
  }

  @override
  String photo_modelFailed(String error) {
    return 'ダウンロードに失敗しました：$error';
  }

  @override
  String get photo_modelNoReason => '理由不明';

  @override
  String photo_modelNeeded(String size) {
    return '写真の送信と再構成に必要です：$size';
  }

  @override
  String get photo_keepOpen =>
      'ダウンロードが終わるまでMeshTraxを開いたままにしてください。進行状況は「オフライン地図」にも表示されます。';

  @override
  String photo_licencesLink(String poweredBy) {
    return '$poweredBy · ライセンス';
  }

  @override
  String get photo_cancelDownload => 'ダウンロードをキャンセル';

  @override
  String get photo_downloadModel => '写真用モデルをダウンロード';

  @override
  String get photo_tryAgain => '再試行';

  @override
  String get photo_deleteModel => '写真用モデルを削除';

  @override
  String get photo_downloadLicences => 'ライセンス文をダウンロード';

  @override
  String get photo_deleteModelTitle => '写真用モデルを削除しますか？';

  @override
  String photo_deleteModelBody(String size) {
    return 'もう一度ダウンロードする（$size）まで、写真の送信も再構成もできません。';
  }

  @override
  String get photo_keep => '残す';

  @override
  String photo_notEnoughSpace(String needed, String free) {
    return '空き容量が足りません：写真用モデルには$neededの空きが必要ですが、この端末の空きは$freeです。';
  }

  @override
  String photo_downloadName(int index, int count) {
    return '写真用モデル（$index/$count）';
  }

  @override
  String photo_downloadLicenceName(int index, int count) {
    return '写真用モデルのライセンス（$index/$count）';
  }

  @override
  String get photo_licencesTitle => '写真用モデルのライセンス';

  @override
  String get photo_licencesIntro =>
      '写真を再構成するモデルは、Stability AIのSD-Turboをもとに、AEIC画像コーデックとAdcSRのデコーダーを使って作られています。安全チェックには、SwiftFormerをもとにした画像分類器を使っています。以下は、これらに付属する通知とライセンスです。';

  @override
  String get photo_licencesMissing => 'ライセンス文は写真用モデルと一緒にダウンロードされます。';

  @override
  String photo_message(String id) {
    return '📷 写真 $id';
  }

  @override
  String photo_messageWithTag(String id, String tag) {
    return '📷 写真 $id · $tag';
  }

  @override
  String photo_incomplete(String id, int got, int total) {
    return '📷 写真 $id 不完全：$got/$totalパケット';
  }

  @override
  String photo_unreadable(String id) {
    return '📷 写真 $id を読み取れませんでした';
  }

  @override
  String photo_needsNewer(String id) {
    return '📷 写真 $id には新しいMeshTraxが必要です';
  }

  @override
  String photo_unknownSender(String id) {
    return 'ノード $id';
  }

  @override
  String get photo_chatPhoto => '📷 写真';

  @override
  String get photo_cameraDenied => 'MeshTraxはカメラを使えません。端末の設定で許可できます。';

  @override
  String photo_pickFailed(String error) {
    return '写真を取得できませんでした：$error';
  }

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
  String get common_experimental => '実験的';

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
  String get healthCheck_title => 'ヘルスチェック';

  @override
  String get healthCheck_subtitle => 'アプリと無線機の設定を確認します';

  @override
  String get healthCheck_running => '設定を確認しています…';

  @override
  String get healthCheck_waitingForSync => '無線機はまだ同期中です。同期が終わると確認を開始します。';

  @override
  String get healthCheck_noRadio => '無線機が接続されていないため、無線機の設定は確認していません。';

  @override
  String get healthCheck_partial =>
      '無線機の設定の一部を読み取れなかったため、この結果は最新ではない可能性があります。少し待ってからもう一度確認してください。';

  @override
  String get healthCheck_allClear => '問題はありません。';

  @override
  String get healthCheck_problems => '問題';

  @override
  String get healthCheck_suggestions => '提案';

  @override
  String get healthCheck_tips => 'ヒント';

  @override
  String healthCheck_passed(int count) {
    return '合格したチェック: $count';
  }

  @override
  String get healthCheck_runAgain => 'もう一度確認';

  @override
  String get healthCheck_fix => '修正';

  @override
  String get healthCheck_fixFailed => '変更を適用できませんでした。無線機との接続を確認して、もう一度お試しください。';

  @override
  String get healthCheck_openFailed => 'その設定画面を開けませんでした。デバイスの設定から変更してください。';

  @override
  String get healthCheck_hide => '今後表示しない';

  @override
  String healthCheck_showHidden(int count) {
    return '非表示の項目を表示: $count';
  }

  @override
  String healthCheck_fixAll(int count) {
    return 'すべて修正 ($count)';
  }

  @override
  String get healthCheck_fixAllConfirm => 'これらの変更を行いますか？';

  @override
  String get healthCheck_promptTitle => 'ヘルスチェックを実行しますか？';

  @override
  String get healthCheck_promptBody =>
      'アプリと無線機の設定で改善できる点を確認できます。通知を減らす方法も含まれます。';

  @override
  String get healthCheck_promptBodyDesktop => 'アプリと無線機の設定で改善できる点を確認できます。';

  @override
  String get healthCheck_promptRun => 'チェックを実行';

  @override
  String get healthCheck_promptLater => '後で';

  @override
  String get settings_title => '設定';

  @override
  String get trax_title => 'TRAXモード';

  @override
  String get trax_isOn => 'TRAXモードはオンです';

  @override
  String get trax_isOff => 'TRAXモードはオフです';

  @override
  String get trax_intro => '無線機をグループの周波数に切り替えます。終了するまで通常のメッシュでは聞こえません。';

  @override
  String get trax_now => '現在';

  @override
  String get trax_inTrax => 'TRAXモード';

  @override
  String get trax_repeatOn => '「オフグリッド（電力網から孤立した状態）の繰り返し」オン';

  @override
  String get trax_savedNote => '「TRAXを終了」で設定が元に戻ります。';

  @override
  String trax_until(String time) {
    return '$timeまで';
  }

  @override
  String get trax_noEnd => 'TRAX設定で旅の終了日時を設定してください。';

  @override
  String get trax_tellsNot => 'グループには知らせません。';

  @override
  String get trax_noChannel => 'TRAX設定で旅のチャンネルを選ぶか、「グループに知らせる」をオフにしてください。';

  @override
  String get trax_trailhead => '登山口で、無線機がGPSで位置を取得してから切り替えてください。';

  @override
  String get trax_settings => 'TRAX設定';

  @override
  String get trax_switch => 'TRAXに切り替え';

  @override
  String trax_heard(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'TRAXで聞こえた人（$count）：$names',
      zero: 'TRAXでまだ誰も聞こえていません',
    );
    return '$_temp0';
  }

  @override
  String get trax_checkAgain => 'もう一度確認';

  @override
  String get trax_noSaved => 'この電話に保存された設定がありません。「TRAXを終了」で戻るプリセットを尋ねます。';

  @override
  String get trax_leave => 'TRAXを終了';

  @override
  String get trax_unsupported =>
      'この無線機のファームウェアはほかの無線機のために中継できません。TRAXモードを使うには更新してください。';

  @override
  String get trax_stepTelling => 'グループに知らせています…';

  @override
  String get trax_stepSwitching => '切り替えています…';

  @override
  String get trax_stepChecking => 'グループ確認を送信しています…';

  @override
  String get trax_stepLeaving => '終了しています…';

  @override
  String get trax_errorBusy => '無線機はまだ処理中です。少ししてからもう一度お試しください。';

  @override
  String get trax_errorRefused => '無線機が設定を受け付けませんでした。何も変わっていません。';

  @override
  String trax_errorNotAllowed(String mhz) {
    return 'この無線機は$mhz MHzで中継できません。';
  }

  @override
  String get trax_unconfirmed => 'TRAXメッセージが確認されていません。別の方法でグループに知らせてください。';

  @override
  String get trax_preset => 'プリセット';

  @override
  String get trax_presetMesh => 'メッシュと同じ';

  @override
  String get trax_presetLongRange => '長距離';

  @override
  String get trax_presetLongRangeHint => '少し遠くまで届きますが、送信に約3倍かかります。';

  @override
  String get trax_tripChannel => '旅のチャンネル';

  @override
  String get trax_tripChannelHint => 'プライベートチャンネルのみ';

  @override
  String get trax_none => 'なし';

  @override
  String get trax_tripEnds => '旅の終了';

  @override
  String get trax_notSet => '未設定';

  @override
  String get trax_tellGroup => 'グループに知らせる';

  @override
  String get trax_tellGroupHint => '旅のチャンネルに投稿します。ほかの人はワンタップで続きます。';

  @override
  String get trax_keepTrack => '自分の軌跡を保持';

  @override
  String get trax_keepTrackHint =>
      '自分と旅のメンバーの地図に、どこまでさかのぼって線を残すかです。それより古い部分はすべての電話で削除されます。';

  @override
  String trax_keepTrackHours(int hours) {
    return '$hours時間';
  }

  @override
  String get trax_keepTrackWeek => '1週間';

  @override
  String get trax_icon => '自分のアイコン';

  @override
  String get trax_iconHint => '旅のメンバーの地図に、あなたがどう表示されるかです。';

  @override
  String get trax_iconHike => '徒歩';

  @override
  String get trax_iconVehicle => '車';

  @override
  String get trax_iconBoat => '船';

  @override
  String get trax_iconMotorcycle => 'バイク';

  @override
  String get trax_iconBicycle => '自転車';

  @override
  String get trax_iconAircraft => '航空機';

  @override
  String get trax_iconCamp => 'キャンプ';

  @override
  String trax_followBody(String name, String time) {
    return '$nameさんが$timeまでTRAXモードに切り替えました。あなたも切り替えますか？';
  }

  @override
  String trax_followDetail(String settings) {
    return '無線機を$settingsに切り替えます。終了するまで通常のメッシュでは聞こえません。';
  }

  @override
  String get trax_switchToo => '切り替える';

  @override
  String get trax_notNow => '今はしない';

  @override
  String trax_leaveBody(String name) {
    return '$nameさんがTRAXモードを終了します。あなたも終了しますか？';
  }

  @override
  String get trax_leaveToo => '終了する';

  @override
  String get trax_stillOn => 'まだTRAXモードです。終了しますか？';

  @override
  String get trax_pickPreset => 'どのプリセットに戻しますか？';

  @override
  String get trax_pickPresetHint => 'この電話にはこの無線機の設定が保存されていません。別の電話で切り替えられました。';

  @override
  String trax_cardOn(String name) {
    return '$nameさんがTRAXモードに切り替えました';
  }

  @override
  String trax_cardOff(String name) {
    return '$nameさんがTRAXモードを終了します';
  }

  @override
  String get trax_cardYouOn => 'TRAXモードに切り替えました';

  @override
  String get trax_cardYouOff => 'TRAXモードを終了しました';

  @override
  String get trax_youreOn => 'TRAX中';

  @override
  String get trax_ended => '終了';

  @override
  String get trax_notificationText => '通常のメッシュでは聞こえません。終了するにはMeshTraxを開いてください。';

  @override
  String get trax_endedTitle => '旅が終了しました';

  @override
  String get trax_endedText => 'まだTRAXモードです。通常のメッシュでは聞こえません。';

  @override
  String get trip_members => '旅のメンバー';

  @override
  String get trip_pickChannel => '旅のチャンネルを選んでください。そこに投稿した人がメンバーになります。';

  @override
  String get trip_noPosts => '旅のチャンネルにはまだ誰も投稿していません。';

  @override
  String get trip_notContact => 'この無線機の連絡先にありません';

  @override
  String get trip_canAsk => 'あなたの無線機に問い合わせできます';

  @override
  String get trip_addMember => 'メンバーを追加';

  @override
  String get trip_askMyRadio => 'メンバーが私の無線機に問い合わせできる';

  @override
  String get trip_askMyRadioHint => '場所とバッテリー。GPSをオンにします。旅のあとTRAXを終了すると止まります。';

  @override
  String trip_shareOff(String setting) {
    return '「$setting」がオフです。メンバーは問い合わせできません。';
  }

  @override
  String get trip_advertsHint => 'TRAXモード中。範囲内の誰でも読めます。';

  @override
  String get trip_sosTitle => 'サイレントモードでもSOSを鳴らしますか？';

  @override
  String trip_onTrax(int on, int total) {
    return 'TRAX上 $on/$total';
  }

  @override
  String trip_notHeardYet(String name) {
    return '$name：まだ聞こえていません';
  }

  @override
  String trip_asking(String name) {
    return '$name：無線機に問い合わせ中…';
  }

  @override
  String trip_noAnswer(String name) {
    return '$name：応答なし';
  }

  @override
  String trax_sendingEvery(String minutes) {
    return 'あなたの位置は$minutes分ごとに旅のメンバーへ送られます。';
  }

  @override
  String get trax_noChannelData => 'この無線機のファームウェアは位置を旅のメンバーへ送れません。更新してください。';

  @override
  String get trax_locationsNoChannel => '位置を共有するには、TRAX設定で旅のチャンネルを選んでください。';

  @override
  String trax_memberNoLocation(String name) {
    return '$name：まだ位置情報なし';
  }

  @override
  String trax_updateToSee(String name) {
    return 'Update MeshTrax to see $name';
  }

  @override
  String get trax_updateToSeeSomeone =>
      'Update MeshTrax to see someone on this trip';

  @override
  String get trax_mayBeOld => '古い可能性あり';

  @override
  String get trax_askTrack => '軌跡を要求';

  @override
  String trax_trackAsked(String time) {
    return '$timeに軌跡を要求済み';
  }

  @override
  String get trax_group => 'TRAXグループ';

  @override
  String get trax_tripChannelLocation => 'TRAXモード中は、あなたの位置がこのチャンネルに送られます。';

  @override
  String get map_lastHeard => '最終受信';

  @override
  String get map_fromYou => 'あなたから';

  @override
  String get map_heading => '進行方向';

  @override
  String get map_speed => '速度';

  @override
  String get map_notMoving => '停止中';

  @override
  String map_notMovingSince(String time, int minutes) {
    return '$timeから（$minutes分）';
  }

  @override
  String map_stoppedFor(int minutes) {
    return '$minutes分間停止中';
  }

  @override
  String get map_elevation => '標高';

  @override
  String get map_radioBattery => '無線機のバッテリー';

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
  String get settings_traxSettingsSubtitle => 'オフグリッドのプリセット、旅のチャンネル、旅の終了';

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
  String get settings_reportBug => '不具合を報告';

  @override
  String get settings_reportBugSubtitle => 'GitHub で不具合報告を開きます';

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
      'メッセージ内のMarkdown：**太字**、*斜体*、||ネタバレ||、見出し、リスト、リンク。ほかのMeshCoreアプリでは記号がそのまま表示されます。';

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
  String get appSettings_maxDirectMessageTries => 'ダイレクトメッセージの最大試行回数';

  @override
  String get appSettings_maxDirectMessageTriesSubtitle =>
      'ダイレクトメッセージやルームへの投稿を失敗とするまでの送信回数です。最初の数回は既知のルートで送り、残りはフラッドで送ります。';

  @override
  String get appSettings_maxChannelMessageRetries => 'チャンネルメッセージの最大再試行回数';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      '中継が1つ以上聞こえるまで、この回数だけ再試行します';

  @override
  String get appSettings_heardCheck => 'オブザーバーで送信を確認';

  @override
  String get appSettings_heardCheckSubtitle =>
      'チャンネルメッセージを再送する前に、オブザーバーサーバーに届いたかを問い合わせます';

  @override
  String get appSettings_heardServer => 'オブザーバーサーバー';

  @override
  String get appSettings_heardServerNotSet => '未設定';

  @override
  String get appSettings_heardServerAbout =>
      'オブザーバーとは、受信した内容をサーバーに報告する無線機です。MeshTrax は送信した各チャンネルメッセージの指紋をそのサーバーに送ります。本文は送りません。サーバーにはあなたのインターネットアドレスと送信時刻が見えます。';

  @override
  String get appSettings_heardServerOther => 'その他のアドレス';

  @override
  String get appSettings_heardServerAddress => 'サーバーアドレス';

  @override
  String get appSettings_heardServerChecking => 'サーバーを確認中…';

  @override
  String get appSettings_heardServerNoAnswer => 'このアドレスから応答がありません';

  @override
  String get appSettings_heardServerSaveAnyway => 'それでも保存';

  @override
  String get appSettings_heardServerAnswered => 'サーバーが応答しました';

  @override
  String chat_heardBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count台のオブザーバーが受信',
    );
    return '$_temp0';
  }

  @override
  String get chat_heardDirect => '直接';

  @override
  String chat_heardVia(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'リピーター$count台経由',
    );
    return '$_temp0';
  }

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
  String radioAsk_title(String name) {
    return '$nameの無線機に問い合わせ';
  }

  @override
  String get radioAsk_menuSubtitle => '相手の電話がオフでも使えます';

  @override
  String get radioAsk_waiting => '別の問い合わせを待っています';

  @override
  String radioAsk_asking(int attempt, int count) {
    return '問い合わせ中… $attempt/$count';
  }

  @override
  String radioAsk_checkingAgain(int attempt, int count) {
    return '再確認中… $attempt/$count';
  }

  @override
  String radioAsk_checkAgainAt(String time) {
    return '$timeに再確認';
  }

  @override
  String radioAsk_where(String name, String time) {
    return '$nameの無線機 · $time';
  }

  @override
  String radioAsk_volts(String volts) {
    return '$volts V';
  }

  @override
  String get radioAsk_noPosition => 'GPS位置なし';

  @override
  String get radioAsk_noFix => '古い可能性：GPS測位なし';

  @override
  String get radioAsk_unchanged => '古い可能性：1分間変化なし';

  @override
  String get radioAsk_notChecked => '2回目の問い合わせに失敗';

  @override
  String get radioAsk_noAnswer => '応答なし';

  @override
  String get radioAsk_showOnMap => '地図に表示';

  @override
  String get radioAsk_askAgain => '再度問い合わせ';

  @override
  String get radioAsk_trackAsked => '相手の電話にも軌跡を要求しました。地図に表示されます。';

  @override
  String radioAsk_mapLabel(String name, String time) {
    return '$nameの無線機 · $time';
  }

  @override
  String get contact_nickname => 'ニックネーム';

  @override
  String get contact_fullName => 'フルネーム';

  @override
  String get contact_note => 'メモ';

  @override
  String get contact_nameAndNoteHint => 'この端末と無線機のバックアップにのみ保存され、送信されることはありません。';

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
  String get channels_shareChannelInstructions => 'QRコードをスキャンしてチャンネルを追加します。';

  @override
  String get channels_secretKey => '秘密鍵';

  @override
  String get channels_meshcoreUri => 'MeshCore URI';

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
    return '$name とそのすべてのメッセージを削除しますか？ これは取り消すことができません。';
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
  String get channels_generateRandomPsk => 'ランダムなPSK（正交符号分割変調）を生成する';

  @override
  String get channels_addChannelConfirmation => '次のチャンネルを追加しますか？';

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
  String get channels_joinPublicChannel => '公開チャンネルに参加する';

  @override
  String get channels_joinPublicChannelDesc => 'このチャンネルには、誰でも参加できます。';

  @override
  String get channels_scanQrCode => 'QRコードをスキャンする';

  @override
  String get channels_scanQrCodeComingSoon => '近日公開';

  @override
  String get channels_keepCapitals => '大文字のままにする';

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
  String get chat_selectText => 'テキストを選択';

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
  String get map_noNodesWithLocation => '位置情報データを持つノードは存在しません';

  @override
  String get map_nodesNeedGps => 'GPSを共有するノードだけが地図に表示されます';

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
  String get map_lastKnown => '最後の位置';

  @override
  String map_lastKnownAt(String time) {
    return '最後の位置 · $time';
  }

  @override
  String get route_fromLastKnown => '最後にわかった現在地から（古い可能性があります）';

  @override
  String route_fromLastKnownAt(String time) {
    return '最後にわかった現在地（$time）から（古い可能性があります）';
  }

  @override
  String route_fromWhereYouWere(String time) {
    return '$timeにいた場所から';
  }

  @override
  String route_startsOffPath(String distance) {
    return '出発地点から$distance離れた、地図にない場所から始まります';
  }

  @override
  String get route_conditionsCaveat =>
      'MeshTraxは通行止め、流失、四輪駆動が必要な道を把握していません。出発前に最新の状況を確認してください。';

  @override
  String route_dataDate(String date) {
    return '地図データ：$date';
  }

  @override
  String get gps_lastKnown => '最後にわかった位置です。古い可能性があります';

  @override
  String gps_lastKnownAt(String time) {
    return '最後にわかった位置（$time）です。古い可能性があります';
  }

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
    return '$channelLabel で位置を共有しますか？公開チャンネルなので誰でも見られます。';
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
  String get repeater_cliQuickRepeatOn => '中継オン';

  @override
  String get repeater_cliQuickRepeatOff => '中継オフ';

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
  String get repeater_cliHelpIntro =>
      'コマンドをタップすると入力欄に入ります。波かっこで囲まれた部分を置き換えてください。getボタンをタップすると、その設定を読み取ります。これはファームウェア1.18のコマンドです。古いファームウェアには、一部のコマンドがないことがあります。';

  @override
  String get repeater_cliSectionRadio => '無線機';

  @override
  String get repeater_cliSectionPower => '電源';

  @override
  String get repeater_cliSectionRegions => 'リージョン';

  @override
  String get repeater_cliSectionSensors => 'センサー';

  @override
  String get repeater_cliSectionRoom => 'ルームサーバー';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      '直接届く範囲の無線機だけが受信するアドバートを送信します。リピーターは中継しません。';

  @override
  String get repeater_cliHelpClockSync =>
      'デバイスの時計を携帯電話の時刻に合わせます。時計は進めることしかできません。';

  @override
  String get repeater_cliHelpTime => '時計をUnix時間（秒）に設定します。時計は進めることしかできません。';

  @override
  String get repeater_cliHelpBoard => 'ボードのメーカーと型番を表示します。';

  @override
  String get repeater_cliHelpGetRole => 'リピーターやルームサーバーなど、ファームウェアの役割を表示します。';

  @override
  String get repeater_cliHelpGetPublicKey => 'デバイスの公開鍵を表示します。';

  @override
  String get repeater_cliHelpClkReboot =>
      '時計を2024年5月に戻して再起動します。時計が進みすぎているときに使い、そのあとclock syncを実行してください。';

  @override
  String get repeater_cliHelpPowerOff =>
      'ボタンが押されるか電源が入れ直されるまで、デバイスの電源を切ります。shutdownも同じです。';

  @override
  String get repeater_cliHelpStartOta =>
      '対応しているボードで、無線によるファームウェア更新を開始します。接続方法は応答に表示されます。';

  @override
  String get repeater_cliHelpRoomPost => 'ルームサーバー自身の名前で、ルームにメッセージを投稿します。';

  @override
  String get repeater_cliHelpGetFreq => '無線の周波数をMHzで表示します。';

  @override
  String get repeater_cliHelpSetTxPower => 'LoRaの送信出力をdBmで設定します。すぐに反映されます。';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      '無線機が送信に使える時間の割合をパーセントで設定します。エアタイム係数を別の単位で表したものです。';

  @override
  String get repeater_cliHelpSetCad =>
      'チャネル活動検出をオンまたはオフにします：無線機は送信前に、ほかのLoRa信号がないか聞き取ります。';

  @override
  String get repeater_cliHelpSetRxGain => '受信ゲインのブーストをオンまたはオフにします（対応する無線機のみ）。';

  @override
  String get repeater_cliHelpSetExtraSf => 'LR2021の無線機のみ：さらに最大3つの拡散率でも受信します。';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      '問い合わせを受けたときに、デバイスが名前やバージョンと一緒に返す所有者情報を設定します。改行には|を使います。';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'flood.maxと同様ですが、リージョンなしで送られたフラッドパケットが対象です。';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'flood.maxと同様ですが、アドバートが対象です。既定値は8です。';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'ループして戻ってくるフラッドパケットを、リピーターがどれだけ厳しく破棄するかを設定します。既定値はminimalです。';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      '各ホップがパケットの経路に追加するバイト数を設定します：0は1バイト、1は2バイト、2は3バイトです。';

  @override
  String get repeater_cliHelpSetPrvKey =>
      'デバイスのIDをこの秘密鍵で置き換えます。適用するには再起動してください。鍵を保存していない場合、古いIDは失われます。';

  @override
  String get repeater_cliHelpPower =>
      'バッテリー電圧と、USB・太陽光・その他の外部電源が接続されているかを表示します。';

  @override
  String get repeater_cliHelpPowerSaving => '省電力がオンかどうかを表示します。';

  @override
  String get repeater_cliHelpPowerSavingSet =>
      '省電力をオンまたはオフにします。nRF52ボードはすぐに、ESP32ボードは2分後に省電力を始めます。';

  @override
  String get repeater_cliHelpGetPwrmgtSupport => 'ボードに電源管理機能があるかを表示します。';

  @override
  String get repeater_cliHelpGetPwrmgtSource =>
      'デバイスが外部電源とバッテリーのどちらで動いているかを表示します。';

  @override
  String get repeater_cliHelpGetPwrmgtBootReason =>
      'デバイスが前回起動した理由と、前回停止した理由を表示します。';

  @override
  String get repeater_cliHelpGetPwrmgtBootMv => 'デバイスが前回起動したときのバッテリー電圧を表示します。';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      'ブートローダーのバージョンを表示します（nRF52ボード）。';

  @override
  String get repeater_cliHelpDiscoverNeighbors => '近くのリピーターに応答を求め、隣接リストを埋めます。';

  @override
  String get repeater_cliHelpRegions => 'リージョンの一覧と、フラッドが許可されているリージョン（F）を表示します。';

  @override
  String get repeater_cliHelpRegionDef =>
      '1つのコマンドで複数のリージョンを追加します：各名前は直前の名前の下に入ります。name|parentと書くと、次の名前を代わりにその親の下に入れます。';

  @override
  String get repeater_cliHelpRegionList =>
      'フラッドが許可されている（allowed）、または許可されていない（denied）リージョンを一覧表示します。';

  @override
  String get repeater_cliHelpRegionDefault =>
      '既定のリージョンを表示します：このデバイス自身のフラッドパケットが送られるリージョンです。';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      '既定のリージョンを設定します。なしにするには<null>を指定します。新しい名前はリージョンとして追加されます。すぐに保存されます。';

  @override
  String get repeater_cliHelpGpsDiag => '問題を調べるためのGPSの詳細を表示します。';

  @override
  String get repeater_cliHelpSensorList =>
      'ボードのセンサー設定を一覧表示します。番号を付けると、リストの途中から表示します。';

  @override
  String get repeater_cliHelpSensorGet => 'センサー設定を1つ表示します。';

  @override
  String get repeater_cliHelpSensorSet => 'センサー設定を1つ変更します。';

  @override
  String get repeater_cliHelpSetBridgeChannel => 'ESP-NOWブリッジのWi-Fiチャネルを設定します。';

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
  String get channelPath_unknownPath => '不明';

  @override
  String get channelPath_floodPath => '洪水';

  @override
  String get channelPath_directPath => '直接';

  @override
  String chat_meshTraxBytesLeft(int count) {
    return '$count left';
  }

  @override
  String get chat_meshTraxTooLong =>
      'Too long for MeshTrax: goes as a standard message';

  @override
  String get chat_sentStandard => 'Standard message';

  @override
  String channelPath_pickedUpOnItsWay(String hops) {
    return '途中で受信、残り: $hops';
  }

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
  String get contacts_ShareContactZeroHop => '広告を通じて連絡先を共有する';

  @override
  String get contacts_shareByAdvertFailed =>
      '無線機はこの連絡先を共有できませんでした。先にこの連絡先の広告を受信する必要があります。';

  @override
  String get contacts_zeroHopContactAdvertSent => '広告を通じて連絡先を得た。';

  @override
  String get contacts_zeroHopContactAdvertFailed => '連絡を送信できませんでした。';

  @override
  String get contacts_contactAdvertCopyFailed => '広告のコピーがクリップボードにコピーできませんでした。';

  @override
  String get contacts_addContact => '連絡先を追加';

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
  String get routing_noRoutePathfinder => 'まだありません';

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
  String get routing_forgetDonePathfinder => '経路をリセットしました。';

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
  String get chat_statusQueued => '送信待ち';

  @override
  String get chat_channelNoSign => '送信済み · 誰に届いたか不明';

  @override
  String chat_sentByItsClock(String time) {
    return '送信元の時計で $time に送信';
  }

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
    return '受信済み · $kind · $secs秒';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return '$attempt回目で受信 · $kind · $secs秒';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return '遅れて受信 · $kind · $secs秒';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return '受信済み · $secs秒';
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
      '無線機は連絡先ごとにルートを1つだけ覚えています。そのルートでメッセージが届かないと、MeshTraxが代わりにメッシュ全体にフラッドします。Pathfinderは、リピーターのアドバート、チャンネルでの会話、ほかの人のメッセージなど、無線機が受信するものすべてに耳を傾けます。そこから、どのリピーター同士がつながっているか、どのリピーターにあなたの電波が届くか、そしてどのリピーターに各連絡先の電波が届くかを示す地図を作ります。';

  @override
  String get pathfinderHelp_how =>
      'メッセージを送るとき、Pathfinderはまず最良のルートを試し、届かなければ次に良いルートを試します。フラッドは最後の手段としてだけ使います。琥珀色の経路アイコンは、Pathfinderのルートで送信したメッセージを示します。';

  @override
  String get pathfinderHelp_learning =>
      '学習には時間がかかります。まっさらな地図は何も知らないので、ルートを学習するまで、最初のうちはメッセージがフラッドで送られます。1か所で数時間聞き続けるとルートを提案し始め、届いても届かなくても、そのたびにさらに学習します。初日はあまり期待しないでください。新しい場所に移るたびに、しばらくはまた効果が下がります。';

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
  String get settings_pathGraph => 'Pathfinder';

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
  String get appSettings_mapDownloadsWifiOnly => 'Wi‑Fi接続時のみダウンロード';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'ダウンロードはWi‑Fiに接続するまで待機します';

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
  String get offlineMaps_kindContoursDetail => '標高を示す線、見通しにも使います';

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
  String get offlineMaps_notificationRunning => 'ダウンロード中';

  @override
  String get offlineMaps_notificationPaused => 'ダウンロードを一時停止中';

  @override
  String get offlineMaps_notificationFailed => 'ダウンロードに失敗しました';

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
  String get map_downloadForDetail => '詳細を見るには地域をダウンロード';

  @override
  String get map_noCharts => 'ここには海図がありません';

  @override
  String get map_myLocation => '現在地';

  @override
  String get map_zoomIn => '拡大';

  @override
  String get map_zoomOut => '縮小';

  @override
  String get gps_on => 'GPSオン';

  @override
  String get gps_off => 'GPSオフ';

  @override
  String get gps_noPosition => 'まだ位置がわかりません。屋外では、最初の測位に数分かかることがあります。';

  @override
  String get gps_position => '位置';

  @override
  String get gps_altitude => '高度';

  @override
  String get gps_turnOnTitle => 'GPSをオンにしますか？';

  @override
  String get gps_turnOnBody => '無線機のGPSはオフです。位置の取得に数分かかることがあります。';

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
  String get mapLayers_details => '地図の詳細';

  @override
  String get mapLayers_contours => '等高線';

  @override
  String get mapLayers_hillShading => '陰影起伏';

  @override
  String get mapLayers_places => 'スポット';

  @override
  String get mapLayers_parks => '公園';

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
  String get structured_repeaterStatus => 'リピーターの状態';

  @override
  String get repeaterStatus_stateCritical => '危険';

  @override
  String get repeaterStatus_stateVeryLow => '非常に低い';

  @override
  String get repeaterStatus_stateLow => '低い';

  @override
  String get repeaterStatus_stateOk => '正常';

  @override
  String get repeaterStatus_waiting => '広告待ち';

  @override
  String get repeaterStatus_unreachable => '到達不能';

  @override
  String get repeaterStatus_noReading => '測定値なし';

  @override
  String repeaterStatus_tx(String value) {
    return 'TX $value';
  }

  @override
  String get repeaterStatus_repeatOn => '中継オン';

  @override
  String get repeaterStatus_repeatOff => '中継オフ';

  @override
  String repeaterStatus_minutes(int count) {
    return '$count分';
  }

  @override
  String repeaterStatus_hours(int count) {
    return '$count時間';
  }

  @override
  String repeaterStatus_days(int count) {
    return '$count日';
  }

  @override
  String repeaterStatus_ago(String time) {
    return '$time前';
  }

  @override
  String repeaterStatus_nextPoll(String time) {
    return '次の確認まで$time';
  }

  @override
  String repeaterStatus_missed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '確認失敗 $count回',
    );
    return '$_temp0';
  }

  @override
  String repeaterStatus_was(String state) {
    return '以前は$state';
  }

  @override
  String repeaterStatus_lastStage(String state) {
    return '最後の段階：$state';
  }

  @override
  String repeaterStatus_for(String name) {
    return '$nameのため';
  }

  @override
  String repeaterStatus_readingIgnored(String value) {
    return '測定値 $value を無視';
  }

  @override
  String repeaterStatus_page(int page, int pages) {
    return '$page/$pagesページ';
  }

  @override
  String get repeaterStatus_dryRun => 'シミュレーションのみ';

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
  String get route_otherApp => '別のアプリで開く';

  @override
  String get navigate_otherApp => '別のアプリ';

  @override
  String get navigate_showDownload => 'ダウンロードを表示';

  @override
  String get navigate_pickStart => '出発地を選ぶ';

  @override
  String navigate_routingMissing(String region) {
    return '$region のオフラインルートはこの端末にありません。';
  }

  @override
  String navigate_routingSize(String size) {
    return 'ダウンロードサイズは $size です。';
  }

  @override
  String get navigate_noRoutingHere => 'この地域のオフラインルートはまだありません。';

  @override
  String get navigate_noPosition => 'GPS位置がありません。地図で出発地を選ぶか、別のアプリを使ってください。';

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
  String get structured_open => 'チャットを開く';

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
  String get location_sendPositionOnly => '位置のみ';

  @override
  String get location_sendWithMotion => '位置、進行方向、速度、高度';

  @override
  String get location_motionNotKnown => '進行方向と速度はまだわかりません';

  @override
  String get add_title => '新しいチャンネルまたは連絡先';

  @override
  String get add_or => 'または';

  @override
  String get add_hashtagRow => 'ハッシュタグチャンネルに参加';

  @override
  String get add_hashtagRowHelp => '#のあとに名前を入力します';

  @override
  String get add_keyRow => '名前と鍵を入力';

  @override
  String get add_keyRowHelp => 'チャンネルの秘密鍵、または連絡先の公開鍵';

  @override
  String get add_name => '名前';

  @override
  String get add_key => '鍵';

  @override
  String get add_keyInvalid => 'チャンネルの鍵は32文字、連絡先の鍵は64文字です。';

  @override
  String get add_typePerson => '人';

  @override
  String get add_box => '貼り付けまたは入力';

  @override
  String get add_boxHint => 'meshcore://リンク、<key:type:name>、#ハッシュタグ、または鍵';

  @override
  String get add_paste => '貼り付け';

  @override
  String get add_clipboardEmpty => '貼り付けるものがありません。';

  @override
  String get add_unreadableTitle => 'まだ追加できるものがありません';

  @override
  String get add_unreadable =>
      '連絡先の場合：meshcore://リンク、<key:type:name>、連絡先カード、または64文字の鍵。チャンネルの場合：meshcore://リンク、#ハッシュタグ、または名前付きの32文字の秘密鍵。';

  @override
  String get add_contactName => '名前（任意）';

  @override
  String get add_scanInstructions => '連絡先またはチャンネルのQRコードをスキャンしてください';

  @override
  String get add_scanUnreadable => 'そのQRコードは連絡先でもチャンネルでもありません。';

  @override
  String get copy_link => 'リンクをコピー';

  @override
  String get copy_asText => 'テキストとしてコピー';

  @override
  String get share_asText => 'テキスト形式';

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
  String get sos_alsoPublic => 'Publicにも送信';

  @override
  String get sos_alsoPublicHint => '範囲内の誰でも内容と位置を読めます。送信は1回です。';

  @override
  String get sos_askingRadio => '無線機に位置を問い合わせています…';

  @override
  String sos_positionFrom(String time, String age) {
    return '無線機の位置（$time、$age）';
  }

  @override
  String sos_positionNotNew(String time, String age) {
    return '新しい位置はありません。最後にわかった位置：$time（$age）。';
  }

  @override
  String get sos_positionAgeUnknown => '最後にわかった位置です（時刻不明）。';

  @override
  String get sos_positionTyped => '自分で入力した位置：毎回の再送でこの位置を送ります。';

  @override
  String get sos_repeats => '取り消すまで2分ごとに位置付きで再送します。「了解」の後は5分ごとです。';

  @override
  String get sos_publicOnce => 'Publicでは1回だけ送信されます。';

  @override
  String get sos_traxOnly => 'TRAXモード：TRAXの無線機にだけ届きます。';

  @override
  String sos_replacesOther(String chat) {
    return '$chat のSOSは取り消されます。';
  }

  @override
  String get sos_active => 'SOSを送信中';

  @override
  String sos_lastSent(String time) {
    return '最終送信 $time';
  }

  @override
  String get sos_waitingForRadio => '送信のため無線機を待っています';

  @override
  String sos_gotItBy(int count, String names) {
    return '了解（$count）：$names';
  }

  @override
  String get sos_noGotIt => 'まだ「了解」はありません';

  @override
  String get sos_cancel => 'SOSを取り消す';

  @override
  String sos_cancelBody(String chat) {
    return '$chat の全員に「SOS cancelled」が届きます。';
  }

  @override
  String get sos_keep => 'SOSを続ける';

  @override
  String get sos_cancelPending => 'SOSを取り消しました。無線機が接続されると送信されます。';

  @override
  String sos_stopped(String time) {
    return 'MeshTraxが閉じたためSOSが止まりました。最終送信 $time。';
  }

  @override
  String get sos_sendAgain => 'もう一度送信';

  @override
  String get sos_gotIt => '了解';

  @override
  String sos_updated(String time) {
    return '更新 $time';
  }

  @override
  String sos_cancelledAt(String time) {
    return '取り消し $time';
  }

  @override
  String sos_sentAt(String time) {
    return '送信 $time';
  }

  @override
  String sos_activeLastSent(String time) {
    return 'SOSを送信中 · 最終送信 $time';
  }

  @override
  String get sos_activeWaiting => 'SOSを送信中 · 無線機を待っています';

  @override
  String get sos_stoppedSendAgain => 'SOSが止まりました · もう一度送信';

  @override
  String get sos_cancelledWaiting => 'SOSを取り消しました · 無線機を待っています';

  @override
  String get sos_dndStepsSamsung =>
      '設定の「サイレントモード」が開きます。「アプリ通知」、「アプリを追加」の順にタップし、MeshTraxを選んで「SOSアラート」だけをオンにしてください。';

  @override
  String get sos_dndStepsOther =>
      '設定の「SOSアラート」が開きます：「サイレントモードをオーバーライド」をオンにしてください。そこにこのスイッチがない場合は、「サイレントモード」を開いて割り込みを許可するアプリを探し、MeshTraxを追加して「SOSアラート」をオンにしてください。';

  @override
  String get notification_sosChannel => 'SOSアラート';

  @override
  String get notification_sosChannelDescription => 'あなた宛て、または参加中のチャットへのSOS';

  @override
  String notification_sosFrom(String name) {
    return '$name からのSOS';
  }

  @override
  String notification_sosCancelledBy(String name) {
    return '$name がSOSを取り消しました';
  }

  @override
  String get notification_mySosChannel => '自分のSOS';

  @override
  String get notification_mySosChannelDescription => '送信中の自分のSOS';

  @override
  String get appSettings_sosAlerts => 'SOSアラート';

  @override
  String get appSettings_sosAlways => 'SOSは、ミュートしたチャットやメッセージ通知がオフでも必ず通知します。';

  @override
  String get appSettings_sosThroughDnd => 'サイレントモード中も鳴ります。';

  @override
  String get appSettings_sosLetThroughDnd =>
      'サイレントモードで消音されます。タップして鳴るようにしてください。';

  @override
  String get appSettings_sosBlocked => '電話でSOSアラートがオフになっています。タップしてオンにしてください。';

  @override
  String get appSettings_sosApple => 'このデバイスでは集中モードと消音モードでまだ消音される場合があります。';

  @override
  String get appSettings_sosOff => '通知がオフのため、SOSアラートもオフです。';

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
  String get paste_resolveFailed => 'リンクを確認できませんでした';

  @override
  String get paste_shortLinkNoPosition =>
      'この短縮リンクには位置情報が含まれていません。地図アプリで開いて座標をコピーしてください。';

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
  String get roadLegend_title => '道路・トレイル・線';

  @override
  String get roadLegend_freeway => '高速道路';

  @override
  String get roadLegend_majorRoad => '幹線道路';

  @override
  String get roadLegend_road => '道路';

  @override
  String get roadLegend_track => '未舗装路・林道';

  @override
  String get roadLegend_trail => 'トレイル';

  @override
  String get roadLegend_walkway => '歩道・自転車道';

  @override
  String get roadLegend_interstate => '州間高速道路';

  @override
  String get roadLegend_usRoute => 'アメリカ国道';

  @override
  String get roadLegend_stateRoute => '州道';

  @override
  String get roadLegend_railway => '鉄道';

  @override
  String get roadLegend_stream => '川・小川';

  @override
  String get roadLegend_contour => '等高線';

  @override
  String get roadLegend_park => '公園の境界';

  @override
  String get roadLegend_wilderness => '原生地域・国有林';

  @override
  String get roadLegend_boundary => '州境・郡境';

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
  String get chats_traxLabel => 'TRAX';

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
  String get route_pathPaved => '舗装路';

  @override
  String get route_pathDirt => '未舗装';

  @override
  String get route_pathHiking => '徒歩';

  @override
  String route_minutes(int minutes) {
    return '$minutes分';
  }

  @override
  String route_hoursMinutes(int hours, int minutes) {
    return '$hours時間$minutes分';
  }

  @override
  String route_to(String destination) {
    return '$destinationまで';
  }

  @override
  String get route_clear => '道順を消去';

  @override
  String get route_finding => '道順を検索中…';

  @override
  String get route_none => '道順が見つかりません';

  @override
  String route_endsShortPaved(String distance, String destination) {
    return '$destinationの$distance手前、舗装路が途切れる地点までの道順です。';
  }

  @override
  String route_endsShortDirt(String distance, String destination) {
    return '$destinationの$distance手前、道路が途切れる地点までの道順です。';
  }

  @override
  String route_endsShortHiking(String distance, String destination) {
    return '$destinationの$distance手前、トレイルが途切れる地点までの道順です。';
  }

  @override
  String get route_directions => '道順の詳細';

  @override
  String get route_here => 'ここへの道順';

  @override
  String route_destinationNow(String destination) {
    return '設定中の目的地：$destination';
  }

  @override
  String route_startNow(String start) {
    return '設定中の出発地：$start';
  }

  @override
  String get route_startNowYou => '設定中の出発地：現在地';

  @override
  String route_from(String start) {
    return '$startから';
  }

  @override
  String get route_fromYou => '現在地から';

  @override
  String get route_useMyPosition => '現在地を使う';

  @override
  String get route_noHeights => 'この地域の標高データはありません。';

  @override
  String get route_noHeightsHiking => 'この地域の標高データがないため、所要時間に登りは含まれていません。';

  @override
  String get route_options => '道順のオプション';

  @override
  String get route_optionsReset => 'リセット';

  @override
  String get route_prefer => '優先';

  @override
  String get route_dirtFastest => '最速';

  @override
  String get route_dirtBalanced => 'バランス';

  @override
  String get route_dirtDirect => '最短';

  @override
  String get route_dirtFastestHelp => '未舗装路は、そのほうが速いときだけ使います。';

  @override
  String get route_dirtBalancedHelp => '距離が大きく縮まるときは未舗装路も使います。';

  @override
  String get route_dirtDirectHelp => '未舗装路で時間がかかっても、最短の道を選びます。';

  @override
  String get route_avoid => '避ける';

  @override
  String get route_avoidHighways => '高速道路';

  @override
  String get route_avoidTolls => '有料道路';

  @override
  String get route_avoidFerries => 'フェリー';

  @override
  String get route_hardestTrail => '難易度の上限';

  @override
  String get route_trailT1 => 'T1 ハイキング';

  @override
  String get route_trailT2 => 'T2 山岳ハイキング';

  @override
  String get route_trailT3 => 'T3 難しい山岳ハイキング';

  @override
  String get route_trailT4 => 'T4 アルパインハイキング';

  @override
  String get route_trailT5 => 'T5 難しいアルパインハイキング';

  @override
  String get route_trailT6 => 'T6 非常に難しいアルパインハイキング';

  @override
  String get route_climbs => '登り';

  @override
  String get route_climbsAvoid => '避ける';

  @override
  String get route_climbsSome => 'ほどほど';

  @override
  String get route_climbsAny => '気にしない';

  @override
  String get route_pace => 'ペース';

  @override
  String get route_paceSlow => 'ゆっくり';

  @override
  String get route_paceNormal => '普通';

  @override
  String get route_paceFast => '速め';

  @override
  String get place_nrhp => '国家歴史登録財';

  @override
  String get place_textCredit => '文章：Wikipedia、CC BY-SA 4.0';

  @override
  String get place_readOnWikipedia => 'Wikipediaで読む';

  @override
  String place_photoCredit(String author, String licence) {
    return '写真：$author、$licence';
  }

  @override
  String get search_hint => '場所・住所・座標を検索';

  @override
  String get search_noPlaces => '場所の検索には「スポット情報」をダウンロードしてください。座標はなくても使えます。';

  @override
  String get search_noResults => '一致なし';

  @override
  String search_near(String name) {
    return '$name付近';
  }

  @override
  String get coordFormat_decimalDegrees => '度（10進数）';

  @override
  String get coordFormat_degreesMinutes => '度・分';

  @override
  String get coordFormat_dms => '度・分・秒';

  @override
  String get coordFormat_utm => 'UTM';

  @override
  String get coordFormat_mgrs => 'MGRS / USNG';

  @override
  String get coordFormat_maidenhead => 'Maidenheadグリッド';

  @override
  String get coordFormat_geohash => 'Geohash';

  @override
  String get poiKind_peak => '山頂';

  @override
  String get poiKind_volcano => '火山';

  @override
  String get poiKind_saddle => '鞍部';

  @override
  String get poiKind_pass => '峠';

  @override
  String get poiKind_spring => '湧水';

  @override
  String get poiKind_hotSpring => '温泉';

  @override
  String get poiKind_waterfall => '滝';

  @override
  String get poiKind_cave => '洞窟';

  @override
  String get poiKind_arch => '天然アーチ';

  @override
  String get poiKind_glacier => '氷河';

  @override
  String get poiKind_rock => '岩';

  @override
  String get poiKind_cliff => '崖';

  @override
  String get poiKind_beach => 'ビーチ';

  @override
  String get poiKind_trailhead => '登山口';

  @override
  String get poiKind_campground => 'キャンプ場';

  @override
  String get poiKind_picnicSite => 'ピクニック場';

  @override
  String get poiKind_hut => '山小屋';

  @override
  String get poiKind_shelter => '避難小屋';

  @override
  String get poiKind_drinkingWater => '飲料水';

  @override
  String get poiCaveat_spring => '涸れているか安全でない場合があります';

  @override
  String get poiCaveat_drinkingWater => '止まっている場合があります';

  @override
  String get poiKind_toilets => 'トイレ';

  @override
  String get poiKind_viewpoint => '展望所';

  @override
  String get poiKind_attraction => '観光スポット';

  @override
  String get poiKind_observatory => '天文台';

  @override
  String get poiKind_zoo => '動物園';

  @override
  String get poiKind_themePark => 'テーマパーク';

  @override
  String get poiKind_mine => '鉱山';

  @override
  String get poiKind_mineShaft => '立坑';

  @override
  String get poiKind_adit => '横坑';

  @override
  String get poiKind_ghostTown => 'ゴーストタウン';

  @override
  String get poiKind_ruins => '廃墟';

  @override
  String get poiKind_monument => 'モニュメント';

  @override
  String get poiKind_memorial => '記念碑';

  @override
  String get poiKind_fort => '砦';

  @override
  String get poiKind_historic => '史跡';

  @override
  String get poiKind_rangerStation => 'レンジャーステーション';

  @override
  String get poiKind_visitorCenter => 'ビジターセンター';

  @override
  String get poiKind_hospital => '病院';

  @override
  String get poiKind_police => '警察';

  @override
  String get poiKind_fireStation => '消防署';

  @override
  String get poiKind_emergencyPhone => '非常電話';

  @override
  String get poiKind_fuel => 'ガソリンスタンド';

  @override
  String get poiKind_restArea => '休憩所';

  @override
  String get poiKind_travelCenter => 'サービスエリア';

  @override
  String get poiKind_museum => '博物館';

  @override
  String get poiKind_city => '都市';

  @override
  String get poiKind_town => '町';

  @override
  String get poiKind_locality => '地区';

  @override
  String get poiKind_lake => '湖';

  @override
  String get poiKind_river => '川';

  @override
  String get poiKind_valley => '谷';

  @override
  String get poiKind_range => '山脈';

  @override
  String get poiKind_trail => 'トレイル';

  @override
  String get poiKind_dirtRoad => '未舗装路';

  @override
  String get poiKind_road => '道路';

  @override
  String get poiKind_address => '住所';

  @override
  String get poiKind_place => '場所';

  @override
  String get offlineMaps_kindRouting => '道順検索';

  @override
  String get offlineMaps_kindRoutingDetail => 'トレイル・未舗装路・舗装路の道順';

  @override
  String get offlineMaps_kindPoi => 'スポット情報';

  @override
  String get offlineMaps_kindPoiDetail => '検索できる場所とWikipediaの解説';

  @override
  String get offlineMaps_kindAddresses => '住所';

  @override
  String get offlineMaps_kindAddressesDetail => '番地まで検索できる住所';

  @override
  String get offlineMaps_useDrive => 'ドライブを使う';

  @override
  String offlineMaps_onDrive(String name, String date) {
    return 'ドライブ $name の地図（$date）';
  }

  @override
  String get offlineMaps_backToInternet => 'インターネットに戻る';

  @override
  String get offlineMaps_keepOpen => 'ドライブからインストール中です。MeshTraxを開いたままにしてください。';

  @override
  String get offlineMaps_driveRemoved => 'ドライブが取り外されました。インターネットの地図を表示しています。';

  @override
  String get offlineMaps_readingDrive => 'ドライブを読み込み中…';

  @override
  String get offlineMaps_noMapsOnDrive =>
      'MeshTraxの地図がありません。ドライブの MeshTrax-maps フォルダを選んでください。';

  @override
  String offlineMaps_driveError(String error) {
    return 'ドライブを読み込めません：$error';
  }

  @override
  String get offlineMaps_stopDriveTitle => 'ドライブからのインストールを中止しますか？';

  @override
  String get offlineMaps_stopDriveBody => 'インストール済みのものはこの端末に残ります。';

  @override
  String get offlineMaps_stopDrive => '中止';

  @override
  String get offlineMaps_keepInstalling => '続ける';

  @override
  String offlineMaps_install(String size) {
    return '$size をインストール';
  }

  @override
  String get offlineMaps_installTotal => 'インストール';

  @override
  String get offlineMaps_routingDriveOlder => 'この端末にはドライブより新しいルートデータがあります。';

  @override
  String get offlineMaps_routingDriveIncomplete =>
      'ドライブのルートデータは、この端末のすべての地域をカバーしていません。';

  @override
  String get offlineMaps_kindWaterRouting => '水上の道順検索';

  @override
  String get offlineMaps_kindWaterRoutingDetail => '水上の道順';

  @override
  String get offlineMaps_waterRoutingWithChart => '水上の道順。この海図も一緒にダウンロードされます。';

  @override
  String get offlineMaps_waterRoutingUpdatesChart => '水上の道順。この海図も一緒に更新されます。';

  @override
  String get offlineMaps_waterRoutingRebuilding => '新しい海図に合わせて作り直し中';

  @override
  String get map_search => '検索';

  @override
  String get map_fullScreen => '全画面表示';

  @override
  String get map_leaveFullScreen => '全画面表示を終了';

  @override
  String get map_fullScreenHintBack => '全画面表示を終了するには、戻るを押すか、同じボタンをタップします。';

  @override
  String get map_fullScreenHintTap => '全画面表示を終了するには、同じボタンをタップします。';

  @override
  String get map_fullScreenHintKey => '全画面表示を終了するには、Esc キーを押すか、同じボタンをクリックします。';

  @override
  String get route_fromHere => 'ここからの道順';

  @override
  String get route_startSet => '出発地を設定しました。次に目的地を選んでください。';

  @override
  String get route_noStart => '出発地がわかりません。地図を長押しして「ここからの道順」を選んでください。';

  @override
  String get route_noData => '「オフライン地図」でこの地域の「道順検索」をダウンロードしてください。';

  @override
  String get route_pin => 'ドロップしたピン';

  @override
  String get water_yourBoat => '自分の船';

  @override
  String get water_yourBoatIntro => '水上の道順はすべてこの設定に従います。あとで「道順のオプション」で変更できます。';

  @override
  String water_boatDraft(String draft, String keel) {
    return '喫水$draft + $keel';
  }

  @override
  String water_boatOffLand(String distance) {
    return '陸から$distance';
  }

  @override
  String water_boatMast(String height) {
    return 'マスト$height';
  }

  @override
  String get water_classRestricted => '制限区域';

  @override
  String get water_classCaution => '注意区域';

  @override
  String get water_classMilitary => '軍事区域';

  @override
  String get water_classAnchorage => '錨地';

  @override
  String get water_classDumping => '土捨場';

  @override
  String get water_classTrafficLane => '通航路';

  @override
  String get water_classSeparation => '分離帯';

  @override
  String get water_classPrecautionary => '警戒水域';

  @override
  String get water_classInshoreTraffic => '沿岸通航帯';

  @override
  String get water_classMarineFarm => '養殖場';

  @override
  String get water_classBridge => '橋';

  @override
  String get water_classCable => '架空電線';

  @override
  String get water_classPipe => '架空パイプ';

  @override
  String get water_classConveyor => 'コンベヤー';

  @override
  String get water_classGate => '水門';

  @override
  String get water_movedLand => 'その地点は陸上か海図の範囲外です';

  @override
  String get water_movedShallow => 'そこは浅すぎます';

  @override
  String get water_movedHazard => '船には浅すぎる危険物の近くです';

  @override
  String get water_movedNoEntry => 'そこは進入禁止です';

  @override
  String get water_movedMast => 'そこにマストより低いものがあります';

  @override
  String water_startMoved(String distance, String why) {
    return '選んだ地点から$distance離れた所から始まります：$why。';
  }

  @override
  String water_endMoved(String distance, String why) {
    return '選んだ地点から$distance離れた所で終わります：$why。';
  }

  @override
  String water_endsShortDepth(
    String distance,
    String destination,
    String band,
    String draft,
  ) {
    return '$destinationの$distance手前で終わります：海図上の水深は$bandです。喫水$draftまでの船なら通れます。';
  }

  @override
  String water_endsShortTooShallow(
    String distance,
    String destination,
    String band,
  ) {
    return '$destinationの$distance手前で終わります：海図上の水深は$bandで、浅すぎて通れません。';
  }

  @override
  String water_endsShortMast(
    String distance,
    String destination,
    String objects,
  ) {
    return '$destinationの$distance手前で終わります：$objectsがマストには低すぎます。';
  }

  @override
  String water_endsShortNoWater(String distance, String destination) {
    return '$destinationの$distance手前で終わります：海図上でつながる水域がありません。';
  }

  @override
  String water_endsShortTooLong(String distance, String destination) {
    return '$destinationの$distance手前で終わります：1つの道順には長すぎます。区間に分けて計画してください。';
  }

  @override
  String water_leastDepth(String depth) {
    return '最小水深：海図上$depth';
  }

  @override
  String water_lowestClearance(String height) {
    return '下を通れる高さ：最低$height';
  }

  @override
  String water_lowestClearanceUnder(String height, String name) {
    return '下を通れる高さ：最低$height、$name';
  }

  @override
  String water_shallower(String depth) {
    return '$depthより浅い';
  }

  @override
  String get water_poorSurvey => '測量が不十分';

  @override
  String get water_needsOpening => '開橋が必要';

  @override
  String get water_magneticModelOld => '方位は2030年まで有効な磁気モデルによる';

  @override
  String water_couldntKeep(String distance) {
    return '陸から$distance未満';
  }

  @override
  String get water_onTheWay => '途中にあるもの';

  @override
  String water_stretch(String length, String from) {
    return '$length（$from地点から）';
  }

  @override
  String get water_speed => '速度';

  @override
  String get water_draft => '喫水';

  @override
  String get water_underKeel => 'キール下の余裕';

  @override
  String get water_preferDepth => '希望する水深';

  @override
  String get water_none => 'なし';

  @override
  String get water_mastHeight => 'マストの高さ';

  @override
  String get water_offLand => '陸からの距離';

  @override
  String get water_avoidLanes => '通航路';

  @override
  String get water_avoidSecurity => '保安区域';

  @override
  String get water_avoidOpening => '可動橋';

  @override
  String get water_notForNavigation => '航海用ではありません';

  @override
  String get water_noData => '「オフライン地図」で、この海図エリアの「水上の道順検索」をダウンロードしてください。';

  @override
  String water_routingMissing(String area) {
    return '$areaの水上の道順検索はこの端末にありません。';
  }

  @override
  String get route_onLand => '陸上の道順';

  @override
  String get route_onWater => '水上の道順';

  @override
  String get water_noTiles => 'ここには水上の道順検索がありません';

  @override
  String get water_mixedBuilds =>
      '「オフライン地図」で水上の道順検索を更新してください：エリアごとにバージョンが異なります。';

  @override
  String get water_noWater => 'ここには船が使える水域がありません';

  @override
  String water_unchartedSpans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '海図に高さの記載がない$countか所の下を通過',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_coordinateFormat => '座標の表示形式';

  @override
  String get map_copyPosition => '位置をコピー';

  @override
  String get poiKind_park => '公園';

  @override
  String get poiKind_protectedArea => '保護区';

  @override
  String get common_more => 'もっと見る';

  @override
  String get common_less => '折りたたむ';

  @override
  String get locationSharing_noPosition => '無線機にまだ位置情報がないため、誰にも見られません';

  @override
  String get locationSharing_adverts => 'アドバートに位置情報を含める';

  @override
  String get dialog_positionHint => '座標または地図のリンクを貼り付け';

  @override
  String get dialog_positionUnreadable => '位置を読み取れません';

  @override
  String get locationSharing_share => '位置情報を共有';

  @override
  String get chats_advertise => 'アドバート';

  @override
  String get tray_drawing => '手描き';

  @override
  String get drawing_tabDraw => '描く';

  @override
  String get drawing_tabPaste => '貼り付け';

  @override
  String get drawing_toolPen => 'ペン';

  @override
  String get drawing_toolLine => '直線';

  @override
  String get drawing_toolRect => '四角形';

  @override
  String get drawing_toolCircle => '円';

  @override
  String get drawing_toolEllipse => '楕円';

  @override
  String get drawing_toolArrow => '矢印';

  @override
  String get drawing_undo => '元に戻す';

  @override
  String get drawing_caption => 'キャプション';

  @override
  String get drawing_captionHint => '絵の下に表示されます（任意）';

  @override
  String drawing_bytes(int used, int max) {
    return '$used / $maxバイト';
  }

  @override
  String drawing_points(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count点',
    );
    return '$_temp0';
  }

  @override
  String get drawing_keptAll => '描いた点はすべてそのまま残ります。';

  @override
  String drawing_simplified(String percent) {
    return '簡略化済み：線のずれは絵の大きさの$percent%以内です。';
  }

  @override
  String get drawing_tooDetailed =>
      '簡略化しても細かすぎて、1通のメッセージに収まりません。線を1本取り消すか、データ量がずっと少ない図形を使ってください。';

  @override
  String get drawing_empty => '指で描くか、図形を選んでください。';

  @override
  String get drawing_pasteHint =>
      'SVGファイル、または M10 10h80v80H10z のようなパスデータを貼り付けてください';

  @override
  String get drawing_pasteUse => 'このSVGを使う';

  @override
  String get drawing_pasteNote => '色や塗りつぶしは送られません。線だけが送られ、見る人のペンの色で表示されます。';

  @override
  String get drawing_pasteEmpty => '先にSVGかパスデータを貼り付けてください。';

  @override
  String get drawing_pasteTooBig =>
      '大きすぎるか細かすぎるため、読み込めません。もっと小さいSVGを貼り付けてください。';

  @override
  String get drawing_pasteUnreadable => 'このアプリで読み込めるSVGではありません。';

  @override
  String get drawing_pasteNothing => 'このSVGには目に見えるものがなく、描けません。';

  @override
  String get drawing_copySvg => 'SVGをコピー';

  @override
  String get appSettings_drawings => '手描き';

  @override
  String get appSettings_drawingsSubtitle => 'SVGで送られる絵と、この端末での見え方';

  @override
  String get drawingSettings_show => '手描きを表示';

  @override
  String get drawingSettings_showSubtitle => 'オフにすると代わりにSVGコードを表示します';

  @override
  String get drawingSettings_penColor => 'ペンの色';

  @override
  String get drawingSettings_colorCode => 'カラーコード';

  @override
  String get drawingSettings_lineWidth => '線の太さ';

  @override
  String get drawingSettings_glow => 'グロー';

  @override
  String get drawingSettings_scanlines => '走査線';

  @override
  String get drawing_toolRoute => '道順';

  @override
  String get drawing_toolX => '×印';

  @override
  String get drawing_routeHint => 'タップして点を追加します。最後の点をもう一度タップすると完了します。';

  @override
  String get drawing_mapNone => '地図なし';

  @override
  String get drawing_mapUsgs => 'USGS';

  @override
  String get drawing_drawHere => 'ここに描く';

  @override
  String get drawing_moveMap => '地図を動かす';

  @override
  String get drawing_mapHint => '地図を移動・ズームして場所を合わせ、「ここに描く」をタップしてください。';

  @override
  String drawing_mapAcross(String map, String distance) {
    return '$map、幅$distance';
  }

  @override
  String get drawing_mapNotDownloaded => 'このエリアはダウンロードされていません';

  @override
  String get listFilter_hopsAway => 'ホップ数';

  @override
  String get listFilter_lastHeard => '最終受信';

  @override
  String get listFilter_heardAnyTime => 'すべての期間';

  @override
  String get listFilter_heardHour => '直前の';

  @override
  String get listFilter_heardTwoDays => '過去48時間';

  @override
  String get listFilter_heardWeek => '過去7日間';

  @override
  String settings_radioFirmware(String version) {
    return '無線機ファームウェア $version';
  }

  @override
  String get settings_locationTapMap => '地図をタップして位置を設定するか、数値を入力してください。';

  @override
  String get settings_locationGpsNote => 'GPS がオンのとき、測位でき次第、無線機はこの位置を置き換えます。';

  @override
  String contacts_hopsAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countホップ',
      zero: '直接',
    );
    return '$_temp0';
  }

  @override
  String get los_lineOfSight => '見通し';

  @override
  String get los_reachFromMe => '現在地からの電波到達範囲';

  @override
  String get los_lineFromMe => '現在地からの見通し';

  @override
  String get los_reachFromHere => 'ここからの電波到達範囲';

  @override
  String los_reachFrom(String name) {
    return '$nameからの電波到達範囲';
  }

  @override
  String get los_clear => '良好';

  @override
  String get los_marginal => 'ぎりぎり';

  @override
  String get los_blocked => '遮断';

  @override
  String get los_cantTell => '不明';

  @override
  String get los_checking => '確認中…';

  @override
  String get los_failed => 'ここでは見通しを計算できませんでした。';

  @override
  String get los_pickTarget => '地図上の人か場所をタップしてください。';

  @override
  String get los_noPosition => '現在地がまだわかりません。地図をタップすると、そこから始めます。';

  @override
  String get los_nothingInWay => '遮るものはありません。';

  @override
  String los_groundAbove(String distance, String height) {
    return '現在地から$distanceの地点で、地面が線より$height高くなっています。';
  }

  @override
  String los_groundAboveStart(String distance, String height) {
    return '始点から$distanceの地点で、地面が線より$height高くなっています。';
  }

  @override
  String los_groundWithin(String distance, String height) {
    return '現在地から$distanceの地点で、地面と線の間が$heightしかありません。';
  }

  @override
  String los_groundWithinStart(String distance, String height) {
    return '始点から$distanceの地点で、地面と線の間が$heightしかありません。';
  }

  @override
  String get los_higherHelps => 'より高い場所に移るか、アンテナを高くすると改善します。';

  @override
  String los_noContours(String length) {
    return 'この線のうち$lengthは等高線がありません。';
  }

  @override
  String los_noContoursIn(String length, String regions) {
    return 'この線のうち$lengthは等高線がありません（$regions）。';
  }

  @override
  String get los_noContoursArea => 'この範囲の一部に等高線がありません。';

  @override
  String los_noContoursAreaIn(String regions) {
    return 'この範囲の一部に等高線がありません（$regions）。';
  }

  @override
  String get los_noHeightData => 'この地域の高さデータはまだありません。';

  @override
  String los_downloadContours(String regions, String size) {
    return '$regionsの等高線をダウンロード（$size）';
  }

  @override
  String get los_downloadBeforeTrip => '出発前にここの等高線をダウンロードしてください（インターネットが必要）。';

  @override
  String get los_spotBelowLowest => '海面下のため高さが不明です。';

  @override
  String los_nameBelowLowest(String name) {
    return '$nameは海面下のため高さが不明です。';
  }

  @override
  String get los_youBelowLowest => '現在地は海面下のため高さが不明です。GPSがオンなら無線機の高度を使います。';

  @override
  String get los_noLinesNear => 'この端の近くに等高線がないため、高さが不明です。';

  @override
  String get los_from => '始点';

  @override
  String get los_to => '終点';

  @override
  String get los_thisRadio => 'この無線機';

  @override
  String get los_me => '自分';

  @override
  String los_meAgo(String age) {
    return '自分、$age';
  }

  @override
  String get los_meByHand => '自分、手動で設定した位置';

  @override
  String get los_meNotYetGps => '自分、GPSでの位置更新はまだ';

  @override
  String los_nameAgo(String name, String age) {
    return '$name、$age';
  }

  @override
  String get los_antenna => 'アンテナ';

  @override
  String get los_handHeld => '手持ち';

  @override
  String get los_vehicle => '車載';

  @override
  String get los_raised => '高所';

  @override
  String get los_raisedTitle => '高所のアンテナ';

  @override
  String get los_raisedLabel => '地面からの高さ';

  @override
  String get los_terrainOnly => '等高線による地形のみです。';

  @override
  String los_credits(String credits) {
    return '高さ：$credits';
  }

  @override
  String get los_aboutTitle => '見通しについて';

  @override
  String get los_helpBody =>
      '結果は、ダウンロードした等高線から読み取った地形だけをもとにしています。木、建物、人、電線、ほかのアンテナは考慮されません。また、山頂は描かれているより最大で等高線1本分高いことがあります。\n\n「良好」は、地形が遮っていないという意味です。メッセージが届くとは限りません。「ぎりぎり」は、地形が線に近づいているという意味です。「遮断」は、地形が遮っているという意味です。低い尾根ひとつなら越えて届くこともありますが、当てにしないでください。\n\n頼りにする前に、自分の無線機を使って現地で試してください。';

  @override
  String los_reachShaded(String distance) {
    return '色付きの範囲：手持ち無線機まで地形が遮りません（$distanceまで）。';
  }

  @override
  String get los_reachUnknownPart => '計算できない地形（海面下）は色付けされません。';

  @override
  String get los_reachTapHint => '地図か名前をタップすると、そこまでの見通しを表示します。';

  @override
  String get los_positionGuessed => '推定位置';

  @override
  String los_positionGuessedVia(String names) {
    return '推定位置（$names 経由で受信）';
  }

  @override
  String los_lookFurther(String distance) {
    return 'さらに遠くまで（$distance）';
  }

  @override
  String los_nobodyWithin(String distance) {
    return '$distance以内に位置のわかる人はいません。';
  }

  @override
  String get offlineMaps_losContours => '見通し用の等高線';

  @override
  String get contacts_deleteComesBack =>
      '無線機はこの種類の連絡先を自動で保存するため、次に受信したときに戻ってきます。';

  @override
  String get tray_contact => '連絡先';

  @override
  String get shareContact_title => '連絡先を共有';

  @override
  String get shareContact_myContact => '自分の連絡先';

  @override
  String get regions_title => 'リージョン';

  @override
  String get regions_settingsSubtitle => 'チャンネルのメッセージを1つの地域にとどめる';

  @override
  String get regions_intro =>
      'リージョンは、チャンネルのメッセージを1つの地域を受け持つリピーターにとどめます。そのリージョンを知らないリピーターはメッセージを中継しないので、地域のリピーターが使っている名前を使ってください。';

  @override
  String get regions_yourRegions => 'あなたのリージョン';

  @override
  String get regions_empty => 'まだリージョンがありません。地域のリピーターが使っている名前を追加してください。';

  @override
  String get regions_add => 'リージョンを追加';

  @override
  String get regions_nameLabel => 'リージョン名';

  @override
  String get regions_nameHelp => '大文字と小文字は区別されます。SF と sf は別のリージョンです。';

  @override
  String get regions_nameBadCharacter => 'スペース、ピリオド、カンマ、ほとんどの記号は使えません。';

  @override
  String get regions_nameTooLong => '長すぎます。最大30バイトです。';

  @override
  String get regions_nameExists => 'すでにリストにあります。';

  @override
  String regions_usedBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のチャンネルが使用中',
      zero: '使っているチャンネルはありません',
    );
    return '$_temp0';
  }

  @override
  String regions_deleteTitle(String name) {
    return '$name を削除しますか?';
  }

  @override
  String regions_deleteInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count個のチャンネルがこのリージョンを使っています。リージョンなしに戻ります。',
    );
    return '$_temp0';
  }

  @override
  String get regions_radioDefault => '無線機の既定リージョン';

  @override
  String get regions_radioDefaultHelp =>
      '無線機に保存されます。自分のリージョンがないチャンネル、ダイレクトメッセージ、アドバートが、どのアプリからでもこれを使います。';

  @override
  String get regions_none => 'なし';

  @override
  String get regions_radioNoAnswer => '無線機が変更を受け付けませんでした。もう一度お試しください。';

  @override
  String get regions_inQr => 'チャンネルQRコードにリージョンを入れる';

  @override
  String get regions_inQrSubtitle =>
      'オン:チャンネルのQRコードにリージョンが入り、読み取ったコードのリージョンが設定されます。';

  @override
  String get regions_unsupported => 'この無線機のファームウェアはリージョンには古すぎます。';

  @override
  String get channelRegion_title => 'リージョン';

  @override
  String channelRegion_noneWithDefault(String name) {
    return 'なし(無線機の既定: $name)';
  }

  @override
  String get channelRegion_everywhere => 'どこでも(リージョンなし)';

  @override
  String get channelRegion_help => 'このチャンネルのメッセージは、そのリージョンを知っているリピーターだけを通ります。';

  @override
  String get channelRegion_manage => 'リージョンを管理';

  @override
  String channelRegion_qrLine(String name) {
    return 'リージョン: $name';
  }

  @override
  String get repeaterRegions_subtitle => 'このリピーターが中継するリージョン';

  @override
  String get repeaterRegions_reading => 'リピーターのリージョンを読み込んでいます…';

  @override
  String get repeaterRegions_tooOld =>
      'このリピーターのファームウェアは古すぎて、ここでリージョンを管理できません。1.15以降が必要です。';

  @override
  String get repeaterRegions_noAnswer => 'リピーターが応答しませんでした。もう一度お試しください。';

  @override
  String get repeaterRegions_noRegion => 'リージョンなしのメッセージを中継';

  @override
  String get repeaterRegions_noRegionHelp =>
      '多くの人はリージョンなしで送信します。オフにすると、このリピーターはそれらのメッセージを中継しなくなります。';

  @override
  String get repeaterRegions_noRegionOffTitle => 'リージョンなしのメッセージの中継をやめますか?';

  @override
  String get repeaterRegions_noRegionOffBody =>
      'リージョンを使っていない近くの人は、このリピーターで中継されなくなります。';

  @override
  String get repeaterRegions_turnOff => 'オフにする';

  @override
  String get repeaterRegions_own => 'リピーター自身のリージョン';

  @override
  String get repeaterRegions_ownHelp =>
      'アドバートで使われ、要求がどのリージョンで届いたか分からないときの返信にも使われます。';

  @override
  String get repeaterRegions_onRepeater => 'このリピーターのリージョン';

  @override
  String get repeaterRegions_empty =>
      'まだリージョンがありません。リージョン付きのメッセージは、そのリージョンを追加して初めてここで中継されます。';

  @override
  String get repeaterRegions_mayBeIncomplete =>
      'リピーターのリストが長く返信が途中で切れたため、ここに表示されていないリージョンがあるかもしれません。';

  @override
  String get repeaterRegions_repeated => '中継する';

  @override
  String get repeaterRegions_notRepeated => '中継しない';

  @override
  String repeaterRegions_removeTitle(String name) {
    return '$name をリピーターから削除しますか?';
  }

  @override
  String get repeaterRegions_hasChildren =>
      'リピーターには、このリージョンの下にまだリージョンがあります。先にそれらを削除してください。';

  @override
  String repeaterRegions_refused(String reply) {
    return 'リピーターの返答: $reply';
  }

  @override
  String get repeaterRegions_fromYours => 'あなたのリージョンから';

  @override
  String get repeaterRegions_alreadyThere => 'すでにこのリピーターにあります。';

  @override
  String channelRegion_qrInclude(String name) {
    return 'リージョン $name を含める';
  }

  @override
  String get channelRegion_nearbyOption => '近くだけ(リピーターなし)';

  @override
  String get channelRegion_nearby => '近くだけ';

  @override
  String get channelRegion_nearbyHelp => '届く範囲の無線機だけが受け取ります。1回だけ送信し、再試行しません。';

  @override
  String get channelRegion_nearbyTrip => 'このチャンネルのTRAXの報告は、ほかの無線機に中継されません。';

  @override
  String nearbyRegions_withPlain(String names) {
    return 'リージョン: $names、リージョンなしのメッセージも';
  }

  @override
  String nearbyRegions_only(String names) {
    return 'リージョン: $names のみ、リージョンなしのメッセージは中継しない';
  }

  @override
  String get nearbyRegions_noneButPlain => 'リージョンなし。リージョンなしのメッセージを中継';

  @override
  String get nearbyRegions_nothing => '何も中継しない: リージョンも、リージョンなしのメッセージも';

  @override
  String channelRegion_carriers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '近くのリピーター $count 台',
    );
    return '$_temp0';
  }

  @override
  String get channelRegion_noCarrier => 'これを中継する近くのリピーターはありません';

  @override
  String get regions_heardNearby => '近くのリピーターから';

  @override
  String regions_nearbySpelling(String name) {
    return '近くのリピーターの表記は $name';
  }

  @override
  String get regions_useSpelling => 'これを使う';

  @override
  String channelPath_regionUnknown(String code) {
    return '知らないリージョン (コード $code)';
  }

  @override
  String chat_channelNoSignRegion(String region) {
    return '$region で送信 · 誰が受け取ったか分かりません。$region を知らないリピーターは破棄します。';
  }

  @override
  String get myLocation_title => '現在地';

  @override
  String get myLocation_onlyYou => '自分だけ';

  @override
  String get myLocation_people => '選んだ人が問い合わせ可能';

  @override
  String get myLocation_everyone => '無線機に保存された全員が問い合わせ可能';

  @override
  String get myLocation_adverts => 'アドバートに含まれる';

  @override
  String get myLocation_gpsNoFix => 'GPSオン、まだ測位なし';

  @override
  String get myLocation_radioGps => '無線機のGPS';

  @override
  String myLocation_fix(String ago, String position) {
    return '$ago前に測位 · $position';
  }

  @override
  String get myLocation_noFix => 'まだ測位していません。';

  @override
  String get myLocation_offSaves => 'オフでバッテリーを節約します。';

  @override
  String myLocation_lastFix(String time) {
    return '最後の測位：$time。';
  }

  @override
  String get myLocation_inAdverts => '自分のアドバートに含める';

  @override
  String get myLocation_advertsHint => 'あなたの無線機を受信した人なら誰でも';

  @override
  String get myLocation_advertsInfo =>
      'アドバートは、受信した人すべてにあなたの位置を伝えます：GPSの測位位置か、GPSがオフなら最後の測位位置または入力した位置です。アドバートが送られるのは、あなたが送信したときか、TRAXが送信したときだけです。';

  @override
  String get myLocation_peopleWho => '問い合わせできる人';

  @override
  String get myLocation_nobody => '誰もいません';

  @override
  String myLocation_allSaved(int count) {
    return '無線機に保存された全員（$count）';
  }

  @override
  String get myLocation_pickPeople => '代わりに人を選ぶ';

  @override
  String get myLocation_batterySensors => 'バッテリーとセンサー';

  @override
  String get myLocation_peopleHint => 'あなたの無線機に、場所とバッテリーを問い合わせできます。';

  @override
  String get myLocation_addSomeone => '人を追加';

  @override
  String myLocation_search(int count) {
    return '$count件の連絡先を検索';
  }

  @override
  String get myLocation_recent => '最近のメッセージ';

  @override
  String get myLocation_canAsk => '問い合わせ可能';

  @override
  String get iconHelp_title => 'アイコンの意味';

  @override
  String get iconHelp_tap => '上部のバーのアイコンをタップすると開きます。';

  @override
  String get iconHelp_radio => '無線機';

  @override
  String get iconHelp_battery => '無線機のバッテリー';

  @override
  String get iconHelp_batteryText => 'タップすると電圧を表示します。';

  @override
  String get iconHelp_signal => '電波';

  @override
  String get iconHelp_signalText =>
      '近くにある最良のリピーターを、無線機がどれだけよく受信できているかを示します。タップすると一覧を表示します。';

  @override
  String get iconHelp_repeaters => '受信したリピーター';

  @override
  String get iconHelp_repeatersText => '台数 · 最良のリピーターのコード · 経過時間';

  @override
  String get iconHelp_traxOff => 'TRAXモードオフ';

  @override
  String get iconHelp_traxOn => 'TRAXモードオン';

  @override
  String get iconHelp_traxOnText => '無線機がグループの周波数になっています。';

  @override
  String get iconHelp_who => '現在地：見られる人';

  @override
  String get iconHelp_people => '選んだ人';

  @override
  String get iconHelp_peopleText => 'あなたの無線機に場所を問い合わせできます。';

  @override
  String get iconHelp_advertsText => 'あなたの無線機を受信した人なら誰でも。';

  @override
  String get iconHelp_gps => '現在地：無線機のGPS';

  @override
  String get iconHelp_filled => '塗りつぶし：GPSオン';

  @override
  String get iconHelp_outline => '輪郭のみ：GPSオフ';

  @override
  String get iconHelp_dashed => '破線：まだGPSで測位していません';

  @override
  String get iconHelp_red => '赤：測位なし、誰かが見られる状態';

  @override
  String get locationNote_title => '位置ボタンが1つになりました';

  @override
  String get locationNote_body =>
      '「GPS」と「位置情報を見られる人」が1つのボタンになりました。形で、誰があなたの位置を見られるかがわかります。塗りつぶしはGPSがオンという意味です。';

  @override
  String get traxGuide_title => 'TRAXのしくみ';

  @override
  String get traxGuide_lead =>
      'TRAXは、携帯の電波もリピーターも使わず、無線機だけで全員の居場所を共有します。たとえば、あなたが先頭にいて、友人が後ろにいて、明日さらに仲間が加わるとしましょう。';

  @override
  String get traxGuide_beforeTitle => '出発前に';

  @override
  String get traxGuide_before =>
      '旅用のプライベートチャンネルを作ります。全員がそれに参加し、お互いを連絡先に追加して、一度投稿します。';

  @override
  String get traxGuide_trailheadTitle => '登山口で';

  @override
  String get traxGuide_trailhead =>
      '無線機がGPSで測位したら、足あとのアイコンをタップして「TRAXに切り替え」をタップします。無線機はグループの周波数に移り、ほかの人には「あなたも切り替えますか？」が届きます。';

  @override
  String get traxGuide_trailTitle => '移動中';

  @override
  String get traxGuide_trail =>
      '各自の電話は、無線機の位置を1～2分ごとに旅のチャンネルへ送り、ときどき軌跡も送ります。地図の3人のボタンで全員の一覧が出ます：距離、方向、最後に受信した時刻。';

  @override
  String get traxGuide_behindTitle => '後ろにいる友人';

  @override
  String get traxGuide_behind =>
      'どの無線機もほかの人のメッセージを中継するので、後ろの人のメッセージはあなたを経由して先頭まで届きます。後ろの人の地図にはあなたのアイコンが表示され、タップすると、あとをたどれるようにあなたの軌跡が表示されます。';

  @override
  String get traxGuide_quietTitle => '連絡がない人がいる？';

  @override
  String get traxGuide_quiet =>
      'その人のカードに、最後に受信した時刻が表示されます。その人の無線機に問い合わせてください：電話がオフでも、無線機が自動で応答します。';

  @override
  String get traxGuide_joinTitle => '翌日から参加する';

  @override
  String get traxGuide_join =>
      '旅のチャンネルを追加します。TRAX設定でそのチャンネルと旅の終了を選び、グループが使っていれば「長距離」も選びます。それから切り替えます。過去2日間の全員の軌跡が少しずつ届きます。';

  @override
  String get traxGuide_sosTitle => 'SOS';

  @override
  String get traxGuide_sos =>
      '旅のチャットで+をタップし、SOSをタップします。取り消すまで、グループには2分ごとにあなたの位置が届きます。';

  @override
  String get traxGuide_endTitle => '旅が終わったら';

  @override
  String get traxGuide_end => 'MeshTraxがTRAXの終了を促します。終了するまで、通常のメッシュでは聞こえません。';

  @override
  String get traxGuide_iconsTitle => 'アイコン';

  @override
  String get traxGuide_member => 'メンバー（本人が選んだアイコン）';

  @override
  String get traxGuide_memberText => '自分のアイコンはTRAX設定にあります。';

  @override
  String get traxGuide_old => '灰色：GPS位置が古い可能性あり';

  @override
  String get traxGuide_you => 'あなた';

  @override
  String get traxGuide_yourTrack => 'あなたの軌跡';

  @override
  String get traxGuide_theirTrack => 'その人の軌跡（カードを開いている間）';

  @override
  String get traxGuide_tripChannel => '旅のチャンネル';

  @override
  String get traxGuide_tripChannelText => 'TRAXがオンの間は「チャット」の一番上にあります。';

  @override
  String get traxGuide_dontShowAgain => '今後は表示しない';
}
