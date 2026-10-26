// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => '채팅';

  @override
  String get chats_title => '채팅';

  @override
  String get newChat_title => '연락처 선택';

  @override
  String newChat_contactCount(int count) {
    return '연락처 $count개';
  }

  @override
  String get newChat_newContact => '새 연락처';

  @override
  String get newChat_newChannel => '새 채널';

  @override
  String get newChat_myContacts => '내 연락처';

  @override
  String get newChat_discovered => '발견됨';

  @override
  String get repeaters_title => '리피터 관리';

  @override
  String get nav_contacts => '연락처';

  @override
  String get nav_channels => '채널';

  @override
  String get nav_map => '지도';

  @override
  String get common_cancel => '취소';

  @override
  String get common_syncing_device_info => '장치 정보 읽는 중...';

  @override
  String get common_syncing_contacts => '연락처 읽는 중...';

  @override
  String get common_syncing_channels => '채널 읽는 중...';

  @override
  String get common_syncing_messages => '메시지 읽는 중...';

  @override
  String get common_ok => '알겠습니다';

  @override
  String get common_connect => '연결';

  @override
  String get common_unknownDevice => '알 수 없는 장치';

  @override
  String get common_save => '저장';

  @override
  String get common_delete => '삭제';

  @override
  String get common_deleteAll => '모두 삭제';

  @override
  String get common_close => '닫기';

  @override
  String get common_edit => '수정';

  @override
  String get common_add => '추가';

  @override
  String get common_settings => '설정';

  @override
  String get common_disconnect => '연결 해제';

  @override
  String get common_connected => '연결된';

  @override
  String get common_disconnected => '단절';

  @override
  String get common_connectionLost => '연결이 끊어졌습니다. 다시 연결하는 중...';

  @override
  String get common_reconnecting => '다시 연결하는 중...';

  @override
  String get common_create => '만들다';

  @override
  String get common_continue => '계속';

  @override
  String get common_share => '공유';

  @override
  String get common_copy => '복사';

  @override
  String get common_retry => '다시 시도';

  @override
  String get common_hide => '숨기다';

  @override
  String get common_remove => '제거';

  @override
  String get common_enable => '활성화';

  @override
  String get common_disable => '비활성화';

  @override
  String get common_reboot => '재부팅';

  @override
  String get common_loading => '로딩 중...';

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
  String get scanner_title => 'MeshCore 공개';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => '블루투스';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'TCP를 통해 연결';

  @override
  String get tcpHostLabel => 'IP 주소';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => '항';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => '목적지 주소 입력 후 연결';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return '$endpoint에 연결 중...';
  }

  @override
  String get tcpErrorHostRequired => 'IP 주소가 필요합니다.';

  @override
  String get tcpErrorPortInvalid => '포트 번호는 1에서 65535 사이여야 합니다.';

  @override
  String get tcpErrorUnsupported => '이 플랫폼에서는 TCP 트랜스포트를 지원하지 않습니다.';

  @override
  String get tcpErrorTimedOut => 'TCP 연결이 시간 초과되었습니다.';

  @override
  String tcpConnectionFailed(String error) {
    return 'TCP 연결 실패: $error';
  }

  @override
  String get usbScreenTitle => 'USB를 통해 연결';

  @override
  String get usbScreenSubtitle => '감지된 시리얼 장치를 선택하고 MeshCore 노드에 직접 연결하십시오.';

  @override
  String get usbScreenStatus => 'USB 장치를 선택합니다.';

  @override
  String get usbScreenNote => 'USB 직렬 통신은 지원되는 안드로이드 장치 및 데스크톱 플랫폼에서 활성화됩니다.';

  @override
  String get usbScreenEmptyState =>
      'USB 장치가 탐지되지 않았습니다. USB 장치를 연결하고 다시 시도해 보세요.';

  @override
  String get usbErrorPermissionDenied => 'USB 접근 권한이 거부되었습니다.';

  @override
  String get usbErrorDeviceMissing => '선택한 USB 장치는 더 이상 사용 불가능합니다.';

  @override
  String get usbErrorInvalidPort => '유효한 USB 장치를 선택하세요.';

  @override
  String get usbErrorBusy => '또 다른 USB 연결 요청이 이미 진행 중입니다.';

  @override
  String get usbErrorNotConnected => 'USB 장치가 연결되지 않았습니다.';

  @override
  String get usbErrorOpenFailed => '선택한 USB 장치를 열 수 없습니다.';

  @override
  String get usbErrorConnectFailed => '선택한 USB 장치에 연결에 실패했습니다.';

  @override
  String get usbErrorUnsupported => '이 플랫폼에서는 USB 직렬 통신을 지원하지 않습니다.';

  @override
  String get usbErrorNativeLibraryMissing =>
      '이 빌드에는 USB 시리얼 라이브러리가 없어 USB 장치를 열 수 없습니다. MeshTrax를 다시 설치하거나 이 빌드에 문제가 있다고 신고해 주세요.';

  @override
  String get usbErrorBrowserUnsupported =>
      '이 브라우저는 Web Serial을 지원하지 않습니다. HTTPS(또는 localhost)에서 Chrome이나 Edge를 사용하세요.';

  @override
  String get usbErrorAlreadyActive => 'USB 연결이 이미 활성화되어 있습니다.';

  @override
  String get usbErrorNoDeviceSelected => 'USB 장치가 선택되지 않았습니다.';

  @override
  String get usbErrorPortClosed => 'USB 연결이 활성화되지 않았습니다.';

  @override
  String get usbErrorConnectTimedOut =>
      '연결이 시간 초과되었습니다. 장치가 USB Companion 펌웨어를 가지고 있는지 확인해 주세요.';

  @override
  String get usbFallbackDeviceName => '웹 시리얼 장치';

  @override
  String get usbStatus_notConnected => 'USB 장치를 선택합니다.';

  @override
  String get usbStatus_connecting => 'USB 장치에 연결 중...';

  @override
  String get usbStatus_searching => 'USB 장치 검색 중...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB 연결 실패: $error';
  }

  @override
  String get scanner_scanning => '장치 검색 중...';

  @override
  String get scanner_connecting => '연결 중...';

  @override
  String get scanner_disconnecting => '연결 해제 중...';

  @override
  String get scanner_notConnected => '연결되지 않음';

  @override
  String scanner_connectedTo(String deviceName) {
    return '$deviceName에 연결됨';
  }

  @override
  String get scanner_showAllDevices => '모든 블루투스 장치 표시';

  @override
  String get scanner_showMeshCoreOnly => 'MeshCore 무전기만 표시';

  @override
  String get scanner_radioNotResponding =>
      '무전기가 응답하지 않습니다. 페어링이 필요할 수 있습니다. 블루투스 설정을 열어 무전기를 추가하고 PIN을 입력한 다음 다시 시도하세요.';

  @override
  String get scanner_pairingFailed =>
      '블루투스 페어링이 취소되었거나 실패했습니다. 다른 기기(휴대폰 등)가 무전기에 연결되어 있지 않은지 확인한 뒤 다시 시도하고 PIN을 입력하세요.';

  @override
  String scanner_connectionFailed(String error) {
    return '연결 실패: $error';
  }

  @override
  String get scanner_stop => '멈춰';

  @override
  String get scanner_scan => '스캔';

  @override
  String get scanner_scanFromImage => '이미지에서 스캔';

  @override
  String get scanner_noQrFoundInImage => '이미지에서 유효한 QR 코드를 찾지 못했습니다';

  @override
  String get scanner_bluetoothOff => '블루투스는 꺼져 있습니다.';

  @override
  String get scanner_bluetoothOffMessage => '블루투스를 켜서 장치를 검색해주세요.';

  @override
  String get scanner_chromeRequired => '크롬 브라우저 필요';

  @override
  String get scanner_chromeRequiredMessage =>
      '이 웹 애플리케이션은 블루투드 지원을 위해 Google Chrome 또는 Chromium 기반 브라우저가 필요합니다.';

  @override
  String get scanner_enableBluetooth => '블루투스 활성화';

  @override
  String get device_quickSwitch => '빠른 전환';

  @override
  String get device_meshcore => '메쉬코어';

  @override
  String get settings_title => '설정';

  @override
  String get settings_deviceInfo => '장치 정보';

  @override
  String get settings_appSettings => '앱 설정';

  @override
  String get settings_appSettingsSubtitle => '알림, 메시징, 지도 설정';

  @override
  String get settings_nodeSettings => '노드 설정';

  @override
  String get settings_nodeName => '노드 이름';

  @override
  String get settings_nodeNameNotSet => '설정되지 않음';

  @override
  String get settings_nodeNameHint => '노드 이름을 입력하세요';

  @override
  String get settings_nodeNameUpdated => '이름 변경';

  @override
  String get settings_radioSettings => '라디오 설정';

  @override
  String get settings_radioSettingsSubtitle => '주파수, 전력, 스펙트럼';

  @override
  String get settings_radioSettingsUpdated => '라디오 설정이 업데이트되었습니다.';

  @override
  String get settings_location => '위치';

  @override
  String get settings_locationSubtitle => 'GPS 좌표';

  @override
  String get settings_locationUpdated => '위치 및 GPS 설정이 업데이트되었습니다.';

  @override
  String get settings_locationBothRequired => '위도와 경도를 모두 입력하세요.';

  @override
  String get settings_locationInvalid => '유효하지 않은 위도 또는 경도.';

  @override
  String get settings_locationGPSEnable => 'GPS 활성화';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'GPS를 사용하여 위치 정보를 자동으로 업데이트할 수 있도록 합니다.';

  @override
  String get settings_latitude => '위도';

  @override
  String get settings_longitude => '경도';

  @override
  String get settings_contactSettings => '연락처 설정';

  @override
  String get settings_contactSettingsSubtitle => '연락처 추가 방식 설정';

  @override
  String get settings_privacyMode => '개인 정보 보호 모드';

  @override
  String get settings_privacyModeSubtitle => '광고에 이름/위치 정보 숨기기';

  @override
  String get settings_privacyModeToggle =>
      '광고에 자신의 이름과 위치를 숨기기 위해 개인 정보 보호 모드를 켜거나 끄십시오.';

  @override
  String get settings_privacyModeEnabled => '개인 정보 보호 모드 활성화';

  @override
  String get settings_privacyModeDisabled => '개인 정보 보호 모드 비활성화';

  @override
  String get settings_privacy => '개인 정보 설정';

  @override
  String get settings_privacySubtitle => '어떤 정보를 공유할지 통제하세요.';

  @override
  String get settings_privacySettingsDescription =>
      '어떤 정보를 기기가 다른 사람들과 공유할지 선택하세요.';

  @override
  String get settings_denyAll => '모든 것을 부정';

  @override
  String get settings_allowByContact => '연락처 표시 기능 활성화';

  @override
  String get settings_allowAll => '모든 것을 허용';

  @override
  String get settings_telemetryBaseMode => '원격 모니터링 기본 설정';

  @override
  String get settings_telemetryLocationMode => '텔레메트리 위치 모드';

  @override
  String get settings_telemetryEnvironmentMode => '텔레메트리 환경 모드';

  @override
  String get settings_advertLocation => '광고 위치';

  @override
  String get settings_advertLocationSubtitle => '광고에 위치 정보를 포함하세요.';

  @override
  String get settings_multiAck => '다중 ACK';

  @override
  String get settings_telemetryModeUpdated => '텔레메트리 모드 업데이트 완료';

  @override
  String get settings_actions => '행동';

  @override
  String get settings_sendAdvertisement => '광고 전송';

  @override
  String get settings_sendAdvertisementSubtitle => '방송 활동';

  @override
  String get settings_advertisementSent => '광고 전송';

  @override
  String get settings_syncTime => '동기화 시간';

  @override
  String get settings_syncTimeSubtitle => '장치 시계를 휴대폰 시간으로 설정';

  @override
  String get settings_timeSynchronized => '시간 동기화';

  @override
  String get settings_refreshContacts => '연락처 갱신';

  @override
  String get settings_refreshContactsSubtitle => '장치에서 연락처 목록을 다시 불러오기';

  @override
  String get settings_rebootDevice => '장치 재부팅';

  @override
  String get settings_rebootDeviceSubtitle => 'MeshCore 장치를 재부팅하세요.';

  @override
  String get settings_rebootDeviceConfirm =>
      '정말로 장치를 재부팅하시겠습니까? 이 경우 연결이 끊어집니다.';

  @override
  String get settings_debug => '디버깅';

  @override
  String get settings_bleDebugLog => 'BLE 디버그 로그';

  @override
  String get settings_bleDebugLogSubtitle => 'BLE 명령어, 응답 및 원시 데이터';

  @override
  String get settings_appDebugLog => '앱 디버깅 로그';

  @override
  String get settings_appDebugLogSubtitle => '애플리케이션 디버깅 메시지';

  @override
  String get settings_exportDatabase => '메시지 데이터베이스 내보내기';

  @override
  String get settings_exportDatabaseSubtitle =>
      '디버깅용 모든 채팅과 연락처의 사본입니다. 비공개로 보관하세요.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return '데이터베이스 저장 위치: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return '내보내기 실패: $error';
  }

  @override
  String get settings_about => '소개';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax $version 버전';
  }

  @override
  String get settings_aboutLegalese => '2026년 MeshCore 오픈 소스 프로젝트';

  @override
  String get settings_aboutDescription =>
      'MeshCore LoRa 메시 네트워크 장치를 위한 오픈 소스 Flutter 클라이언트.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS 고도 데이터: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => '이름';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => '상태';

  @override
  String get settings_infoBattery => '배터리';

  @override
  String get settings_infoPublicKey => '공개 키';

  @override
  String get settings_infoContactsCount => '연락처 수';

  @override
  String get settings_infoChannelCount => '채널 수';

  @override
  String get settings_presets => '기본 설정';

  @override
  String get settings_frequency => '주파수 (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => '유효하지 않은 주파수 (300-2500 MHz)';

  @override
  String get settings_bandwidth => '대역폭';

  @override
  String get settings_spreadingFactor => '분산 계수';

  @override
  String get settings_codingRate => '코딩 속도';

  @override
  String get settings_txPower => 'TX 전력 (dBm)';

  @override
  String get settings_txPowerInvalid => '유효하지 않은 TX 전력';

  @override
  String get settings_clientRepeat => '오프그리드 반복';

  @override
  String get settings_clientRepeatSubtitle =>
      '이 장치가 다른 사람들을 위해 메시 패킷을 반복하도록 허용합니다.';

  @override
  String get settings_clientRepeatFreqWarning =>
      '오프그리드(무전력) 시스템 재연결에는 433MHz, 869MHz, 또는 918MHz 주파수가 필요합니다.';

  @override
  String settings_error(String message) {
    return '오류: $message';
  }

  @override
  String get appSettings_title => '앱 설정';

  @override
  String get appSettings_appearance => '외관';

  @override
  String get appSettings_theme => '주제';

  @override
  String get appSettings_themeSystem => '기본 설정';

  @override
  String get appSettings_themeLight => '빛';

  @override
  String get appSettings_themeDark => '어둡다';

  @override
  String get appSettings_language => '언어';

  @override
  String get appSettings_languageSystem => '기본 설정';

  @override
  String get appSettings_languageEn => '영어';

  @override
  String get appSettings_languageFr => '프랑스어';

  @override
  String get appSettings_languageEs => '스페인어';

  @override
  String get appSettings_languageDe => '독일어';

  @override
  String get appSettings_languagePl => '폴란드';

  @override
  String get appSettings_languageSl => '슬로베니아어';

  @override
  String get appSettings_languagePt => '포르투갈어';

  @override
  String get appSettings_languageIt => '이탈리아어';

  @override
  String get appSettings_languageZh => '중국어';

  @override
  String get appSettings_languageSv => '스웨덴어';

  @override
  String get appSettings_languageNl => '네덜란드어';

  @override
  String get appSettings_languageSk => '슬로베니아어';

  @override
  String get appSettings_languageBg => '불가리';

  @override
  String get appSettings_languageRu => '러시아어';

  @override
  String get appSettings_languageUk => '우크라이나';

  @override
  String get appSettings_enableMessageTracing => '메시지 추적 기능 활성화';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      '메시지에 대한 상세한 경로 및 시간 정보를 표시';

  @override
  String get appSettings_senderNameColors => '보낸 사람 이름 색상';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      '채널에서 보낸 사람마다 이름 색을 다르게 표시합니다. 끄면 모두 테마 색상을 사용합니다.';

  @override
  String get appSettings_showTextFormatting => '텍스트 서식 표시';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      '메시지의 마크다운: **굵게**, *기울임*, ||스포일러||, 제목, 링크. 다른 MeshCore 앱에서는 기호가 그대로 보입니다.';

  @override
  String get appSettings_notifications => '알림';

  @override
  String get appSettings_enableNotifications => '알림 활성화';

  @override
  String get appSettings_enableNotificationsSubtitle => '메시지와 광고에 대한 알림을 받으세요.';

  @override
  String get appSettings_notificationPermissionDenied => '알림 권한 거부';

  @override
  String get appSettings_notificationsEnabled => '알림 기능 활성화';

  @override
  String get appSettings_notificationsDisabled => '알림 기능 끄기';

  @override
  String get appSettings_messageNotifications => '메시지 알림';

  @override
  String get appSettings_messageNotificationsSubtitle => '새로운 메시지를 받을 때 알림 표시';

  @override
  String get appSettings_channelMessageNotifications => '채널 메시지 알림';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      '채널 메시지를 수신할 때 알림 표시';

  @override
  String get appSettings_advertisementNotifications => '광고 알림';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      '새 노드가 발견되었을 때 알림 표시';

  @override
  String get appSettings_messaging => '메시징';

  @override
  String get appSettings_maxMessageRetries => '최대 메시지 재시도 횟수';

  @override
  String get appSettings_maxMessageRetriesSubtitle => '메시지를 실패로 처리하기 전 시도 횟수';

  @override
  String get appSettings_maxChannelMessageRetries => '채널 메시지 최대 재시도 횟수';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      '중계가 한 번 이상 들릴 때까지 이 횟수만큼 다시 시도합니다';

  @override
  String get appSettings_battery => '배터리';

  @override
  String get appSettings_batteryChemistry => '배터리 화학';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return '$deviceName 당분간';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst => '장치를 선택하기 위해 연결';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => '리튬 폴리머 (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => '지도 표시';

  @override
  String get appSettings_showRepeaters => '반복 기능 표시';

  @override
  String get appSettings_showRepeatersSubtitle => '지도에 반복자 노드를 표시';

  @override
  String get appSettings_showChatNodes => '채팅 노드 표시';

  @override
  String get appSettings_showChatNodesSubtitle => '지도에 채팅 노드를 표시';

  @override
  String get appSettings_showOtherNodes => '다른 노드 표시';

  @override
  String get appSettings_showOtherNodesSubtitle => '지도에서 다른 노드 유형을 표시';

  @override
  String get appSettings_timeFilter => '시간 필터';

  @override
  String get appSettings_timeFilterShowAll => '모든 노드 표시';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return '지난 $hours 시간 동안의 노드 표시';
  }

  @override
  String get appSettings_mapTimeFilter => '지도 필터';

  @override
  String get appSettings_showNodesDiscoveredWithin => '다음 내역에서 발견된 노드 표시:';

  @override
  String get appSettings_allTime => '모든 시간';

  @override
  String get appSettings_lastHour => '지난 시간';

  @override
  String get appSettings_last6Hours => '지난 6시간';

  @override
  String get appSettings_last24Hours => '지난 24시간';

  @override
  String get appSettings_lastWeek => '지난 주';

  @override
  String get appSettings_unitsTitle => '단위';

  @override
  String get appSettings_unitsMetric => '단위 (m / km)';

  @override
  String get appSettings_unitsImperial => '제국 (피트/마일)';

  @override
  String get appSettings_debugCard => '디버깅';

  @override
  String get appSettings_appDebugLogging => '앱 디버깅 로깅';

  @override
  String get appSettings_appDebugLoggingSubtitle => '로그 앱 디버깅 메시지 (문제 해결을 위한)';

  @override
  String get appSettings_appDebugLoggingEnabled => '앱 디버깅 로깅 활성화';

  @override
  String get appSettings_appDebugLoggingDisabled => '앱 디버깅 로깅 비활성화';

  @override
  String get appSettings_incrementalContactSync => '연락처 증분 동기화';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      '다시 연결할 때 지난번 이후 바뀐 연락처만 무전기에 요청합니다';

  @override
  String get contacts_title => '연락처';

  @override
  String get contacts_noContacts => '아직 연락처는 없습니다.';

  @override
  String get contacts_shareMyQrCode => '내 QR 코드 공유';

  @override
  String get contacts_shareQrCodeDesc => '다른 사람이 스캔해 나를 연락처에 추가할 수 있습니다';

  @override
  String get contacts_contactsWillAppear => '장치가 광고를 할 때, 연락처 정보가 표시됩니다.';

  @override
  String get contacts_unread => '읽지 않음';

  @override
  String get contacts_searchContactsNoNumber => '연락처 검색...';

  @override
  String contacts_searchContacts(int number, String str) {
    return '$number $str 연락처 검색...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return '$number $str 검색 결과 보기...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return '$number $str 사용자 검색...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return '$number $str 검색 결과 반복기 검색';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return '$number $str 방 서버 검색';
  }

  @override
  String get contacts_noUnreadContacts => '읽지 않은 연락처가 없습니다.';

  @override
  String get contacts_noContactsFound => '연락처 또는 그룹이 검색되지 않았습니다.';

  @override
  String get contacts_deleteContact => '연락처 삭제';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return '$contactName을(를) 삭제하시겠습니까?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return '연락처 $contactName을(를) 삭제했습니다.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return '$contactName을(를) 삭제하지 못했습니다.';
  }

  @override
  String get contacts_noMatchingContacts => '필터와 일치하는 연락처가 없습니다.';

  @override
  String contacts_removeConfirm(String contactName) {
    return '$contactName를 연락처 목록에서 제거하시겠습니까?';
  }

  @override
  String get contacts_manageRepeater => '리피터 관리';

  @override
  String get contacts_manageRoom => '방 서버 관리';

  @override
  String get contacts_roomLogin => '방 서버 로그인';

  @override
  String get contacts_openChat => '자유로운 대화';

  @override
  String get contacts_editGroup => '편집 그룹';

  @override
  String get contacts_deleteGroup => '그룹 삭제';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '$groupName 삭제?';
  }

  @override
  String get contacts_newGroup => '새로운 그룹';

  @override
  String get contacts_groupName => '그룹 이름';

  @override
  String get contacts_groupNameRequired => '그룹 이름이 필요합니다';

  @override
  String get contacts_groupNameReserved => '이 그룹 이름은 이미 사용 중입니다.';

  @override
  String contacts_groupAlreadyExists(String name) {
    return '그룹 \"$name\"은 이미 존재합니다.';
  }

  @override
  String get contacts_filterContacts => '연락처 필터링...';

  @override
  String get contacts_noContactsMatchFilter => '입력하신 검색 조건과 일치하는 연락처가 없습니다.';

  @override
  String get contacts_noMembers => '회원 없음';

  @override
  String get contacts_lastSeenNow => '최근';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '약 1시간';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours hours';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1일';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days일';
  }

  @override
  String get contact_info => '연락처';

  @override
  String get contact_settings => '연락처 설정';

  @override
  String get contact_telemetry => '텔레메트리';

  @override
  String get contact_lastSeen => '마지막으로 목격';

  @override
  String get contact_clearChat => '명확한 대화';

  @override
  String get contact_teleBase => '텔레메트리 기반';

  @override
  String get contact_teleBaseSubtitle => '배터리 잔량 및 기본적인 통신 데이터를 공유할 수 있도록 허용';

  @override
  String get contact_teleLoc => '텔레메트리 위치';

  @override
  String get contact_teleLocSubtitle => '위치 정보 공유 허용';

  @override
  String get contact_teleEnv => '텔레메트리 환경';

  @override
  String get contact_teleEnvSubtitle => '환경 센서 데이터를 공유하도록 허용';

  @override
  String get contacts_publicKey => '공개 키';

  @override
  String get channels_title => '채널';

  @override
  String get channels_noChannelsConfigured => '구성된 채널이 없습니다.';

  @override
  String get channels_addPublicChannel => '공개 채널 추가';

  @override
  String get channels_searchChannels => '검색 채널...';

  @override
  String get channels_noChannelsFound => '채널을 찾을 수 없습니다.';

  @override
  String channels_channelIndex(int index) {
    return '채널 $index';
  }

  @override
  String get channels_hashtagChannel => '해시태그 채널';

  @override
  String get channels_public => '대중의';

  @override
  String get channels_private => '사립';

  @override
  String get channels_publicChannel => '공개 채널';

  @override
  String get channels_privateChannel => '개인 채널';

  @override
  String get channels_editChannel => '채널 편집';

  @override
  String get channels_shareChannel => '채널 공유';

  @override
  String get channels_shareChannelInstructions =>
      'QR 코드를 스캔해 채널을 추가하세요.\n메뉴 → 채널 추가 → QR 코드를 스캔';

  @override
  String get channels_secretKey => '비밀 키';

  @override
  String get channels_meshcoreUri => 'MeshCore URI';

  @override
  String get channels_shareChannelQr => '채널 QR 코드 스캔';

  @override
  String get channels_shareChannelWarning =>
      '경고: 이 QR 코드를 스캔하는 사람은 누구나 이 채널에 접근할 수 있습니다.';

  @override
  String get channels_muteChannel => '음소거 채널';

  @override
  String get channels_unmuteChannel => '채널 음소거 해제';

  @override
  String get channels_deleteChannel => '채널 삭제';

  @override
  String channels_deleteChannelConfirm(String name) {
    return '$name 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return '채널 \"$name\" 삭제에 실패했습니다.';
  }

  @override
  String channels_channelDeleted(String name) {
    return '채널 \"$name\" 삭제';
  }

  @override
  String get channels_addChannel => '채널 추가';

  @override
  String get channels_channelIndexLabel => '채널 인덱스';

  @override
  String get channels_channelName => '채널 이름';

  @override
  String get channels_usePublicChannel => '공개 채널 사용';

  @override
  String get channels_standardPublicPsk => '표준 공공 PSK';

  @override
  String get channels_pskHex => 'PSK (헥스)';

  @override
  String get channels_generateRandomPsk => '임의의 PSK 생성';

  @override
  String get channels_enterChannelName => '채널 이름을 입력해 주세요.';

  @override
  String get channels_pskMustBe32Hex => 'PSK(개인식별키)는 32자리 16진수 문자여야 합니다.';

  @override
  String get channels_addChannelConfirmation => '다음 채널을 추가하시겠습니까?';

  @override
  String get channels_channelAddedSuccess => '채널을 추가했습니다.';

  @override
  String get channels_noAvailableChannelSlots => '사용 가능한 채널 슬롯이 없습니다.';

  @override
  String get appSettings_mentionNotifications => '멘션 알림';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      '누군가 나를 멘션하거나 내게 답장할 때 — 음소거된 채널에서도';

  @override
  String notification_mentionIn(String channelName) {
    return '$channelName에서 멘션됨';
  }

  @override
  String channels_channelAdded(String name) {
    return '채널 \"$name\" 추가';
  }

  @override
  String channels_editChannelTitle(int index) {
    return '채널 $index 편집';
  }

  @override
  String get channels_smazCompression => 'SMAZ 압축';

  @override
  String channels_channelUpdated(String name) {
    return '채널 \"$name\"이 업데이트되었습니다.';
  }

  @override
  String get channels_publicChannelAdded => '공개 채널 추가';

  @override
  String get channels_sortBy => '정렬 기준 선택';

  @override
  String get channels_sortManual => '사용 설명서';

  @override
  String get channels_sortAZ => 'A부터 Z까지';

  @override
  String get channels_sortLatestMessages => '최신 메시지';

  @override
  String get channels_sortUnread => '읽지 않음';

  @override
  String get channels_createPrivateChannel => '개인 채널 만들기';

  @override
  String get channels_createPrivateChannelDesc => '비밀 키로 암호화되어 있습니다.';

  @override
  String get channels_joinPrivateChannel => '개인 채널에 참여하기';

  @override
  String get channels_joinPrivateChannelDesc => '비밀 키를 수동으로 입력합니다.';

  @override
  String get channels_joinPublicChannel => '공개 채널에 참여하세요';

  @override
  String get channels_joinPublicChannelDesc => '누구나 이 채널에 참여할 수 있습니다.';

  @override
  String get channels_joinHashtagChannel => '해시태그 채널에 참여하세요';

  @override
  String get channels_joinHashtagChannelDesc => '누구나 해시태그 채널에 참여할 수 있습니다.';

  @override
  String get channels_scanQrCode => 'QR 코드를 스캔';

  @override
  String get channels_scanQrCodeComingSoon => '곧 출시';

  @override
  String get channels_enterHashtag => '해시태그 입력';

  @override
  String get channels_hashtagHint => '예: #팀';

  @override
  String get chat_noMessages => '아직 메시지가 없습니다.';

  @override
  String get chat_sendMessage => '메시지를 보내기';

  @override
  String chat_sendMessageTo(String contactName) {
    return '$contactName에게 메시지를 보내';
  }

  @override
  String get chat_sendMessageToStart => '시작하려면 메시지를 보내세요.';

  @override
  String get chat_originalMessageNotFound => '원래 메시지를 찾을 수 없음';

  @override
  String chat_replyingTo(String name) {
    return '$name에게 답변';
  }

  @override
  String chat_replyTo(String name) {
    return '$name님께 회신';
  }

  @override
  String get chat_location => '위치';

  @override
  String get common_copiedToClipboard => '클립보드에 복사했습니다';

  @override
  String get common_copyToClipboard => '클립보드에 복사';

  @override
  String get contacts_copyContactToClipboard => '내 연락처를 클립보드에 복사';

  @override
  String get chat_typeMessage => '메시지를 입력하세요...';

  @override
  String get chat_searchMessages => '메시지 검색';

  @override
  String get chat_searchNoMatches => '일치 항목 없음';

  @override
  String chat_messageTooLong(int maxBytes) {
    return '메시지가 너무 길어서 (최대 $maxBytes 바이트).';
  }

  @override
  String get chat_messageCopied => '메시지가 복사되었습니다';

  @override
  String get chat_messageDeleted => '메시지가 삭제되었습니다.';

  @override
  String get chat_sendGif => 'GIF 보내기';

  @override
  String get chat_reply => '답변';

  @override
  String get chat_newMessages => '새 메시지';

  @override
  String get chat_addReaction => '댓글 추가';

  @override
  String get chat_mention => '멘션';

  @override
  String get dmChannel_menuLabel => '다이렉트 메시지';

  @override
  String dmChannel_pickerTitle(String name) {
    return '$name에게 DM 보내기';
  }

  @override
  String get dmChannel_pickerHint => '키와 마지막 수신 시간을 확인하세요 — 같은 이름이 여럿일 수 있습니다.';

  @override
  String get dmChannel_warningTitle => '정말 그 사람인가요?';

  @override
  String get dmChannel_warningBody =>
      '채널 이름은 스스로 정하는 것이라 누구나 흉내 낼 수 있습니다. 민감한 내용이라면 먼저 다른 방법으로 이 연락처의 공개 키를 확인하세요.';

  @override
  String get dmChannel_dontShowAgain => '다시 표시 안 함';

  @override
  String get batterySleep_title => 'MeshTrax 계속 실행하기';

  @override
  String get batterySleep_bodySamsung =>
      '삼성 휴대폰은 배터리를 아끼려고 앱을 절전 상태로 만들어 무전기 연결이 끊깁니다. 설정 → 애플리케이션 → MeshTrax → 배터리를 열고 \'제한 없음\'을 선택하세요. 또한 배터리 → 백그라운드 사용 제한에서 MeshTrax가 \'절전 상태 앱\'이나 \'완전 절전 상태 앱\'에 들어 있지 않은지 확인하세요.';

  @override
  String get batterySleep_bodyGeneric =>
      '휴대폰이 배터리를 아끼려고 백그라운드에서 MeshTrax를 중지해 무전기 연결이 끊길 수 있습니다. 배터리 설정을 열어 MeshTrax를 \'제한 없음\'(또는 \'제한하지 않음\')으로 설정하세요. 일부 휴대폰에서는 MeshTrax의 \'자동 실행\'도 켜야 합니다.';

  @override
  String get batterySleep_openSettings => '설정 열기';

  @override
  String get batterySleep_notNow => '나중에';

  @override
  String get batterySleep_settingsTile => '백그라운드에서 MeshTrax 계속 실행';

  @override
  String get batterySleep_settingsTileSubtitle =>
      '휴대폰의 배터리 절약 기능이 MeshTrax를 절전 상태로 만들지 않게 합니다';

  @override
  String dmChannel_noMatchTitle(String name) {
    return '아직 $name에게 DM을 보낼 수 없습니다';
  }

  @override
  String get dmChannel_noMatchBody =>
      '아직 상대의 키가 없고, 상대가 답장하려면 내 키가 필요합니다 — 키는 광고로만 전달됩니다. \'내 광고 보내기\'는 여기서 바로 내 광고를 보냅니다. \'채널에서 요청\'은 메시지 입력란에 요청 문구를 적어 주니 직접 보내면 됩니다.';

  @override
  String get dmChannel_askInChannel => '채널에서 요청';

  @override
  String get dmChannel_sendMyAdvert => '내 광고 보내기';

  @override
  String get dmChannel_askText => 'DM을 보낼 수 있게 광고를 보내 주세요';

  @override
  String get dmChannel_watching => '상대의 광고를 기다리는 중 — 도착하면 여기서 알려 드립니다.';

  @override
  String dmChannel_advertHeard(String name) {
    return '이제 $name에게 연락할 수 있습니다';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => '확대/축소 수준';

  @override
  String get common_reset => '재설정';

  @override
  String get chat_reactionsTitle => '반응';

  @override
  String get chat_reactionUnknownSender => '알 수 없음';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender님이 이 채팅에 없는 메시지에 반응했습니다';
  }

  @override
  String get chat_me => '나';

  @override
  String get emojiCategorySmileys => '이모티콘';

  @override
  String get emojiCategoryGestures => '제스처';

  @override
  String get emojiCategoryHearts => '심장';

  @override
  String get emojiCategoryObjects => '대상';

  @override
  String get gifPicker_title => 'GIF 선택';

  @override
  String get gifPicker_searchHint => 'GIF 검색...';

  @override
  String get gifPicker_poweredBy => 'GIPHY에서 제공';

  @override
  String get gifPicker_noGifsFound => 'GIF 파일이 없습니다.';

  @override
  String get gifPicker_failedLoad => 'GIF 파일 로딩 실패';

  @override
  String get gifPicker_failedSearch => 'GIF 검색에 실패했습니다.';

  @override
  String get gifPicker_noInternet => '인터넷 연결 없음';

  @override
  String get debugLog_appTitle => '앱 디버깅 로그';

  @override
  String get debugLog_bleTitle => 'BLE 디버그 로그';

  @override
  String get debugLog_copyLog => '로그 기록';

  @override
  String get debugLog_saveLog => '로그를 파일로 저장';

  @override
  String get debugLog_saved => '로그를 저장했습니다';

  @override
  String get debugLog_saveCancelled => '저장을 취소했습니다';

  @override
  String get debugLog_filterAll => '전체';

  @override
  String get debugLog_filterWarnings => '경고';

  @override
  String get debugLog_filterErrors => '오류';

  @override
  String get debugLog_clearLog => '명확한 로그';

  @override
  String get debugLog_copied => '디버깅 로그 복사';

  @override
  String get debugLog_bleCopied => 'BLE 로그 복사';

  @override
  String get debugLog_noEntries => '현재 디버깅 로그는 생성되지 않았습니다.';

  @override
  String get debugLog_enableInSettings => '설정에서 앱 디버깅 로깅을 활성화합니다.';

  @override
  String get debugLog_frames => '프레임';

  @override
  String get debugLog_rawLogRx => '원시 로그-RX';

  @override
  String get debugLog_noBleActivity => '현재 BLE 관련 활동은 없습니다.';

  @override
  String debugFrame_length(int count) {
    return '프레임 길이: $count 바이트';
  }

  @override
  String debugFrame_command(String value) {
    return '명령: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => '텍스트 메시지 프레임:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- 목적지 공개 키: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- 시간: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- 플래그: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- 텍스트 유형: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => '명령줄 인터페이스 (CLI)';

  @override
  String get debugFrame_textTypeCliCommand => 'CLI 명령';

  @override
  String get debugFrame_textTypePlain => '단순한';

  @override
  String debugFrame_text(String text) {
    return '- 텍스트: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => '헥스 덤프:';

  @override
  String get chat_hopSingular => '점프';

  @override
  String get chat_hopPlural => '홉';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '홉',
      one: '홉',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => '사용자 지정 경로 설정';

  @override
  String get chat_fullPath => '전체 경로';

  @override
  String get chat_pathDetailsNotAvailable =>
      '경로 정보는 아직 제공되지 않습니다. 메시지를 보내어 다시 시도해 보세요.';

  @override
  String get chat_type => '종류';

  @override
  String get chat_path => '경로';

  @override
  String get chat_publicKey => '공개 키';

  @override
  String get chat_compressOutgoingMessages => '전송되는 메시지 압축';

  @override
  String get chat_floodForced => '홍수 (강제)';

  @override
  String get chat_directForced => '직접적인 (강제적인)';

  @override
  String chat_hopsForced(int count) {
    return '$count번 띄우기 (강제)';
  }

  @override
  String get chat_floodAuto => '홍수 (자동)';

  @override
  String get chat_direct => '직접';

  @override
  String get chat_poiShared => '공유된 POI';

  @override
  String chat_unread(int count) {
    return '읽지 않음: $count';
  }

  @override
  String get chat_openLink => '링크를 열기?';

  @override
  String get chat_openLinkConfirmation => '이 링크를 브라우저에서 열고 싶으신가요?';

  @override
  String get chat_open => '열기';

  @override
  String chat_couldNotOpenLink(String url) {
    return '링크를 열 수 없습니다: $url';
  }

  @override
  String get chat_invalidLink => '유효하지 않은 링크 형식';

  @override
  String get map_lineOfSight => '시야';

  @override
  String get map_losScreenTitle => '시야';

  @override
  String get map_noNodesWithLocation => '위치 정보가 있는 노드가 없습니다.';

  @override
  String get map_nodesNeedGps => '노드는 지도에 표시되려면 GPS 좌표를 공유해야 합니다.';

  @override
  String map_nodesCount(int count) {
    return '노드: $count';
  }

  @override
  String map_pinsCount(int count) {
    return '핀: $count';
  }

  @override
  String get map_chat => '채팅';

  @override
  String get map_repeater => '반복기';

  @override
  String get map_room => '방';

  @override
  String get map_sensor => '센서';

  @override
  String get map_pinDm => '핀 (DM)';

  @override
  String get map_pinPrivate => '개인 계정';

  @override
  String get map_pinPublic => '공개 (일반 공개)';

  @override
  String get map_lastSeen => '마지막으로 목격';

  @override
  String get map_disconnectConfirm => '이 장치와의 연결을 해제하시겠습니까?';

  @override
  String get map_from => '~부터';

  @override
  String get map_source => '출처';

  @override
  String get map_flags => '깃발';

  @override
  String get map_shareMarkerHere => '여기에서 마커 공유';

  @override
  String get map_setAsMyLocation => '내 위치로 설정';

  @override
  String get map_pinLabel => '핀 라벨';

  @override
  String get map_label => '레이블';

  @override
  String get map_pointOfInterest => '관심 지점';

  @override
  String get map_sendToContact => '연락처로 보내기';

  @override
  String get map_sendToChannel => '채널로 전송';

  @override
  String get map_noChannelsAvailable => '사용 가능한 채널이 없습니다.';

  @override
  String get map_publicLocationShare => '공개 장소 공유';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return '현재 $channelLabel 채널에서 위치 정보를 공유하려고 합니다. 이 채널은 공개되어 있으며, PSK를 가진 모든 사용자가 이 위치 정보를 볼 수 있습니다.';
  }

  @override
  String get map_connectToShareMarkers => '장치를 연결하여 마커를 공유';

  @override
  String get map_filterNodes => '필터 노드';

  @override
  String get map_chatNodes => '채팅 노드';

  @override
  String get map_repeaters => '다시 보내는 장치';

  @override
  String get map_otherNodes => '다른 노드';

  @override
  String get map_showOverlaps => '반복 키 중복';

  @override
  String get map_keyPrefix => '핵심 접두사';

  @override
  String get map_filterByKeyPrefix => '주요 접두사 기준으로 필터링';

  @override
  String get map_publicKeyPrefix => '공개 키 접두사';

  @override
  String get map_showDiscoveryContacts => '디스커버리 담당자 연락처 보기';

  @override
  String get map_guessedLocation => '추측된 위치';

  @override
  String get map_lastSeenTime => '마지막으로 확인된 시간';

  @override
  String get map_sharedPin => '공유 비밀번호';

  @override
  String get map_joinRoom => '방에 참여';

  @override
  String get map_manageRepeater => '리피터 관리';

  @override
  String get map_tapToAdd => '노드에 클릭하여 경로에 추가합니다.';

  @override
  String get map_runTrace => '경로 추적';

  @override
  String get map_runTraceWithReturnPath => '원래 경로로 돌아가세요.';

  @override
  String get map_removeLast => '마지막 항목 삭제';

  @override
  String get map_pathTraceCancelled => '경로 추적 기능이 취소되었습니다.';

  @override
  String get time_justNow => '방금';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes분 전';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String time_daysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get time_hour => '시간';

  @override
  String get time_hours => '시간';

  @override
  String get time_day => '하루';

  @override
  String get time_days => '일';

  @override
  String get time_week => '주';

  @override
  String get time_weeks => '몇 주';

  @override
  String get time_month => '달';

  @override
  String get time_months => '개월';

  @override
  String get time_minutes => '분';

  @override
  String get time_allTime => '모든 시간';

  @override
  String get dialog_disconnect => '연결 해제';

  @override
  String get dialog_disconnectConfirm => '이 장치와의 연결을 해제하시겠습니까?';

  @override
  String get login_repeaterLogin => '다시 로그인';

  @override
  String get login_roomLogin => '방 서버 로그인';

  @override
  String get login_password => '비밀번호';

  @override
  String get login_enterPassword => '비밀번호를 입력하세요';

  @override
  String get login_savePassword => '비밀번호 저장';

  @override
  String get login_savePasswordSubtitle => '비밀번호는 이 장치에 안전하게 저장됩니다.';

  @override
  String get login_repeaterDescription => '반복기 비밀번호를 입력하여 설정 및 상태를 확인하십시오.';

  @override
  String get login_roomDescription => '설정 및 상태에 액세스하려면 방 비밀번호를 입력하세요.';

  @override
  String get login_login => '로그인';

  @override
  String login_attempt(int current, int max) {
    return '시도 $current/$max';
  }

  @override
  String login_failed(String error) {
    return '로그인 실패: $error';
  }

  @override
  String get login_failedMessage =>
      '로그인에 실패했습니다. 비밀번호가 잘못되었거나, 연결이 되지 않는 것 같습니다.';

  @override
  String get common_reload => '다시 로드';

  @override
  String get common_clear => '명확하게';

  @override
  String get path_enterCustomPath => '사용자 지정 경로 입력';

  @override
  String get path_currentPathLabel => '현재 경로';

  @override
  String get path_hexPrefixInstructions =>
      '각 단계에 대한 2자리 헥사데진 접두사를 쉼표로 구분하여 입력하세요.';

  @override
  String get path_hexPrefixExample =>
      '예시: A1, F2, 3C (각 노드는 자신의 공개 키의 첫 번째 바이트를 사용)';

  @override
  String get path_labelHexPrefixes => '경로 (헥스 접두사)';

  @override
  String get path_helperMaxHops =>
      '최대 64개의 홉. 각 접두사는 2개의 16진수 문자(1바이트)로 구성됩니다.';

  @override
  String get path_selectFromContacts => '또 연락처 목록에서 선택:';

  @override
  String get path_noRepeatersFound => '반복 장치 또는 서버는 찾을 수 없습니다.';

  @override
  String get path_customPathsRequire =>
      '사용자 정의 경로에는 메시지를 전달할 수 있는 중간 경로가 필요합니다.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return '유효하지 않은 16진수 접두사: $prefixes';
  }

  @override
  String get path_tooLong => '경로가 너무 길어. 최대 64개의 연결만 허용됩니다.';

  @override
  String get path_setPath => '경로 설정';

  @override
  String get repeater_management => '리피터 관리';

  @override
  String get room_management => '방 서버 관리';

  @override
  String get repeater_guest => '반복 장비 정보';

  @override
  String get room_guest => '서버 정보';

  @override
  String get repeater_managementTools => '관리 도구';

  @override
  String get repeater_guestTools => '손님용 도구';

  @override
  String get repeater_status => '상태';

  @override
  String get repeater_statusSubtitle => '반복 장비의 상태, 통계, 및 이웃 장비 목록 보기';

  @override
  String get repeater_telemetry => '텔레메트리';

  @override
  String get repeater_telemetrySubtitle => '센서 및 시스템 상태에 대한 통신 데이터를 확인';

  @override
  String get repeater_cli => '명령줄 인터페이스 (CLI)';

  @override
  String get repeater_cliSubtitle => '리피터에 명령을 전송';

  @override
  String get repeater_neighbors => '이웃';

  @override
  String get repeater_neighborsSubtitle => '0홉 이웃 노드를 확인합니다.';

  @override
  String get repeater_settings => '설정';

  @override
  String get repeater_settingsSubtitle => '리피터 파라미터 설정';

  @override
  String get repeater_clockSyncAfterLogin => '로그인 후 시계 동기화';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      '성공적인 로그인 후, 자동으로 \"시간 동기화\"를 전송합니다.';

  @override
  String get repeater_statusTitle => '반복 장치 상태';

  @override
  String get repeater_refresh => '새롭게';

  @override
  String get repeater_statusRequestTimeout => '상태 확인 요청이 시간 초과되었습니다.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return '상태 로딩 오류: $error';
  }

  @override
  String get repeater_systemInformation => '시스템 정보';

  @override
  String get repeater_battery => '배터리';

  @override
  String get repeater_clockAtLogin => '로그인 시 시간 표시';

  @override
  String get repeater_uptime => '가동 시간';

  @override
  String get repeater_queueLength => '대기 줄의 길이';

  @override
  String get repeater_debugFlags => '디버깅 플래그';

  @override
  String get repeater_radioStatistics => '라디오 통계';

  @override
  String get repeater_lastRssi => '마지막 RSSI 값';

  @override
  String get repeater_lastSnr => '마지막 SNR';

  @override
  String get repeater_noiseFloor => '잡음 수준';

  @override
  String get repeater_txAirtime => 'TX 에어타임';

  @override
  String get repeater_rxAirtime => 'RX 에어타임';

  @override
  String get repeater_packetStatistics => '패킷 통계';

  @override
  String get repeater_sent => '발송';

  @override
  String get repeater_received => '수신';

  @override
  String get repeater_duplicates => '중복';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days일 $hours시간 $minutes분 $seconds초';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return '총: $total, 홍수: $flood, 직접: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return '총: $total, 홍수: $flood, 직접: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return '홍수: $flood, 직접: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return '총: $total';
  }

  @override
  String get repeater_settingsTitle => '리피터 설정';

  @override
  String get repeater_basicSettings => '기본 설정';

  @override
  String get repeater_repeaterName => '반복 장비 이름';

  @override
  String get repeater_repeaterNameHelper => '이 반복기용 표시 이름';

  @override
  String get repeater_adminPassword => '관리자 비밀번호';

  @override
  String get repeater_adminPasswordHelper => '전체 접근 권한 비밀번호';

  @override
  String get repeater_guestPassword => '게스트 비밀번호';

  @override
  String get repeater_guestPasswordHelper => '읽기 전용 접근 비밀번호';

  @override
  String get repeater_radioSettings => '라디오 설정';

  @override
  String get repeater_frequencyMhz => '주파수 (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX 파워';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => '대역폭';

  @override
  String get repeater_spreadingFactor => '분산 계수';

  @override
  String get repeater_codingRate => '코딩 속도';

  @override
  String get repeater_locationSettings => '위치 설정';

  @override
  String get repeater_latitude => '위도';

  @override
  String get repeater_latitudeHelper => '십진법 위도 (예: 37.7749)';

  @override
  String get repeater_longitude => '경도';

  @override
  String get repeater_longitudeHelper => '십진법 위도 (예: -122.4194)';

  @override
  String get repeater_features => '특징';

  @override
  String get repeater_packetForwarding => '패킷 전송';

  @override
  String get repeater_packetForwardingSubtitle => '리피터가 패킷을 전달하도록 설정';

  @override
  String get repeater_guestAccess => '게스트 접근';

  @override
  String get repeater_guestAccessSubtitle => '게스트의 읽기 전용 접근 권한 허용';

  @override
  String get repeater_privacyMode => '개인 정보 보호 모드';

  @override
  String get repeater_privacyModeSubtitle => '광고에 이름/위치 정보 숨기기';

  @override
  String get repeater_advertisementSettings => '광고 설정';

  @override
  String get repeater_localAdvertInterval => '지역 광고 시간 간격';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes 분';
  }

  @override
  String get repeater_floodAdvertInterval => '홍수 광고 간격';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours 시간';
  }

  @override
  String get repeater_encryptedAdvertInterval => '암호화된 광고 간격';

  @override
  String get repeater_dangerZone => '위험 구역';

  @override
  String get repeater_rebootRepeater => '리부트 반복';

  @override
  String get repeater_rebootRepeaterSubtitle => '리피터 장치를 재시작하세요.';

  @override
  String get repeater_rebootRepeaterConfirm => '반복기를 재부팅하시려는 것이 맞으신가요?';

  @override
  String get repeater_regenerateIdentityKey => '아이디 키 재 생성';

  @override
  String get repeater_regenerateIdentityKeySubtitle => '새로운 공개/개인 키 쌍 생성';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      '이를 통해 리피터에 새로운 식별자를 할당합니다. 계속 진행하시겠습니까?';

  @override
  String get repeater_eraseFileSystem => '파일 시스템 삭제';

  @override
  String get repeater_eraseFileSystemSubtitle => '리피터 파일 시스템을 포맷합니다.';

  @override
  String get repeater_eraseFileSystemConfirm =>
      '경고: 이 작업은 리피터에 있는 모든 데이터를 삭제합니다. 이 작업을 되돌릴 수 없습니다!';

  @override
  String get repeater_eraseSerialOnly =>
      '\'Erase\' 기능은 시리얼 콘솔을 통해서만 사용할 수 있습니다.';

  @override
  String repeater_commandSent(String command) {
    return '명령 전송: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return '명령 전송 오류: $error';
  }

  @override
  String get repeater_confirm => '확인';

  @override
  String get repeater_settingsSaved => '설정이 성공적으로 저장되었습니다.';

  @override
  String repeater_errorSavingSettings(String error) {
    return '설정 저장 오류: $error';
  }

  @override
  String get repeater_refreshBasicSettings => '기본 설정 초기화';

  @override
  String get repeater_refreshRadioSettings => '라디오 설정 초기화';

  @override
  String get repeater_refreshTxPower => 'TX 전원 재설정';

  @override
  String get repeater_refreshLocationSettings => '위치 설정 초기화';

  @override
  String get repeater_refreshPacketForwarding => '패킷 전송 재시작';

  @override
  String get repeater_refreshGuestAccess => '게스트 접근 권한 갱신';

  @override
  String get repeater_refreshPrivacyMode => '개인 정보 보호 모드 재설정';

  @override
  String get repeater_refreshAdvertisementSettings => '광고 설정 재설정';

  @override
  String repeater_refreshed(String label) {
    return '$label가 갱신됨';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return '$label를 새로 고침 중 오류 발생';
  }

  @override
  String get repeater_cliTitle => '리피터 CLI';

  @override
  String get repeater_debugNextCommand => '다음 명령 디버깅';

  @override
  String get repeater_commandHelp => '명령 도움';

  @override
  String get repeater_clearHistory => '명확한 역사';

  @override
  String get repeater_noCommandsSent => '아직 명령이 전송되지 않았습니다.';

  @override
  String get repeater_typeCommandOrUseQuick => '아래에 명령어를 입력하거나, 빠른 명령어를 사용하세요.';

  @override
  String get repeater_enterCommandHint => '명령어를 입력하세요...';

  @override
  String get repeater_previousCommand => '이전 명령어';

  @override
  String get repeater_nextCommand => '다음 명령어';

  @override
  String get repeater_enterCommandFirst => '먼저 명령어를 입력하세요';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI 명령어 프레임';

  @override
  String repeater_cliCommandError(String error) {
    return '오류: $error';
  }

  @override
  String get repeater_cliQuickGetName => '이름을 알려주세요';

  @override
  String get repeater_cliQuickGetRadio => '라디오 듣기';

  @override
  String get repeater_cliQuickGetTx => 'TX 획득';

  @override
  String get repeater_cliQuickNeighbors => '이웃';

  @override
  String get repeater_cliQuickVersion => '버전';

  @override
  String get repeater_cliQuickAdvertise => '광고';

  @override
  String get repeater_cliQuickClock => '시계';

  @override
  String get repeater_cliQuickClockSync => '시계 동기화';

  @override
  String get repeater_cliQuickDiscovery => '이웃 발견하기';

  @override
  String get repeater_cliHelpAdvert => '광고 패킷을 발송';

  @override
  String get repeater_cliHelpReboot =>
      '장치를 재부팅합니다. (참고: \'시간 초과\' 오류가 발생할 수 있으며, 이는 정상적인 현상입니다)';

  @override
  String get repeater_cliHelpClock => '각 기기의 시계에 표시되는 현재 시간';

  @override
  String get repeater_cliHelpPassword => '장치에 새로운 관리자 비밀번호를 설정합니다.';

  @override
  String get repeater_cliHelpVersion => '장치 버전 및 펌웨어 빌드 날짜를 표시합니다.';

  @override
  String get repeater_cliHelpClearStats => '다양한 통계 지표를 0으로 초기화합니다.';

  @override
  String get repeater_cliHelpSetAf => '에어 타임 요소를 설정합니다.';

  @override
  String get repeater_cliHelpSetTx =>
      'LoRa 전송 전력을 dBm 단위로 설정합니다. (설정을 적용하려면 재부팅 필요)';

  @override
  String get repeater_cliHelpSetRepeat => '이 노드에 대한 리피터 역할을 활성화하거나 비활성화합니다.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(방 서버) \'켜짐\' 상태인 경우, 빈 비밀번호로 로그인할 수 있지만, 방에 게시할 수는 없습니다 (단, 읽기만 가능).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      '들어오는 플러드 패킷의 최대 홉 수를 설정합니다 (최대 홉 수보다 크거나 같으면 패킷은 전달되지 않습니다).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      '간섭 임계값을 설정합니다 (dB 단위). 기본값은 14입니다. 0으로 설정하면 채널 간섭 감지 기능을 비활성화합니다.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      '자동 게인 제어기를 재설정하는 간격을 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      '\'더블 ACK\' 기능을 활성화하거나 비활성화할 수 있습니다.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      '로컬 (제로 홉) 광고 패킷을 전송하는 간격 (분 단위)을 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      '시간 단위로 광고 패킷을 전송하는 간격을 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      '게스트 비밀번호를 설정하거나 업데이트합니다. (반복 사용자, 게스트 로그인 시 \"통계 가져오기\" 요청을 보낼 수 있음)';

  @override
  String get repeater_cliHelpSetName => '광고 이름을 설정합니다.';

  @override
  String get repeater_cliHelpSetLat => '광고 지도의 위도를 설정합니다. (십진법 단위)';

  @override
  String get repeater_cliHelpSetLon => '광고 지도의 경도를 설정합니다. (십진도)';

  @override
  String get repeater_cliHelpSetRadio =>
      '완전히 새로운 라디오 파라미터를 설정하고, 선호 사항에 저장합니다. 적용하려면 \"재부팅\" 명령이 필요합니다.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      '(실험용) 기본 설정 (최소 1이어야 함)으로, 수신된 패킷에 약간의 지연을 적용하며, 신호 강도/점수를 기준으로 설정합니다. 0으로 설정하면 비활성화됩니다.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      '공통 패킷의 전송 지연 시간을 설정하며, 시간-공기 시간과 무작위 슬롯 시스템을 곱하여 충돌 가능성을 줄입니다.';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'txdelay와 동일하게, 하지만 직접 모드 패킷 전송 시 무작위 지연을 적용하는 경우';

  @override
  String get repeater_cliHelpSetBridgeEnabled => '브리지 활성화/비활성화';

  @override
  String get repeater_cliHelpSetBridgeDelay => '패킷 재전송 전에 지연 시간을 설정합니다.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      '브리지가 수신된 패킷을 다시 전송할지, 아니면 전송된 패킷을 다시 전송할지 선택하십시오.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'rs232 브리지에 대한 직렬 통신 속도(baud rate)를 설정합니다.';

  @override
  String get repeater_cliHelpSetBridgeSecret => 'ESPNow 브리지에 대한 비밀 설정';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      '특정 보드에서만 지원되는 방식으로, 보고되는 배터리 전압을 조정하기 위한 사용자 정의 요소를 설정할 수 있습니다.';

  @override
  String get repeater_cliHelpTempRadio =>
      '주어진 시간(분) 동안 임시 라디오 파라미터를 설정하고, 이후 원래 라디오 파라미터로 되돌립니다. (설정을 저장하지 않습니다).';

  @override
  String get repeater_cliHelpSetPerm =>
      'ACL을 수정합니다. \"permissions\" 값이 0인 경우, 일치하는 항목(pubkey 접두사)을 제거합니다. pubkey-hex 길이가 완전하고 현재 ACL에 없는 경우 새로운 항목을 추가합니다. pubkey 접두사를 기준으로 항목을 업데이트합니다. 권한 비트는 펌웨어 역할에 따라 다르지만, 하위 2비트는 다음과 같습니다: 0 (게스트), 1 (읽기 전용), 2 (읽기/쓰기), 3 (관리자)';

  @override
  String get repeater_cliHelpGetBridgeType => '브리지형, RS232, ESPNOW 지원';

  @override
  String get repeater_cliHelpLogStart => '패킷 로깅을 파일 시스템으로 시작합니다.';

  @override
  String get repeater_cliHelpLogStop => '패킷 로깅을 파일 시스템으로 저장하는 것을 중단합니다.';

  @override
  String get repeater_cliHelpLogErase => '파일 시스템에서 패킷 로그를 삭제합니다.';

  @override
  String get repeater_cliHelpNeighbors =>
      '제로 홉 광고를 통해 수신된 다른 리피터 노드 목록을 보여줍니다. 각 줄은 ID-프리픽스-16진수:타임스탬프:SNR-횟수-4 형식입니다.';

  @override
  String get repeater_cliHelpNeighborRemove =>
      '이 함수는 지정된 pubkey 접두사(16진수)와 일치하는 첫 번째 항목을 이웃 목록에서 제거합니다.';

  @override
  String get repeater_cliHelpRegion =>
      '(단일 시리즈) 정의된 모든 지역과 현재 홍수 허가 정보를 나열합니다.';

  @override
  String get repeater_cliHelpRegionLoad =>
      '참고: 이는 여러 명령을 한 번에 실행하는 특별한 방식입니다. 각 후속 명령은 영역 이름이며 (부모 계층 구조를 나타내기 위해 공백으로 들여쓰기하며, 최소 1개의 공백을 사용) 공백으로 끝나는 줄 또는 명령을 보내어 종료합니다.';

  @override
  String get repeater_cliHelpRegionGet =>
      '주어진 이름 접두사(또는 전역 검색을 위한 \"\\*\" 사용)를 사용하여 특정 지역을 검색합니다. 결과를 \"-> 지역 이름 (상위 지역 이름) \'F\'\" 형태로 반환합니다.';

  @override
  String get repeater_cliHelpRegionPut => '주어진 이름으로 지역 정의를 추가하거나 업데이트합니다.';

  @override
  String get repeater_cliHelpRegionRemove =>
      '지정된 이름으로 특정 영역 정의를 제거합니다. (정확히 일치해야 하며, 하위 영역은 존재하지 않아야 합니다)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      '지정된 영역에 대한 \'물\' 접근 권한을 설정합니다. (\'*\'는 전역/기존 범위에 해당)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      '지정된 영역에 대해 \'Flood\' 권한을 제거합니다. (참고: 현재 단계에서는 전역/기존 범위에서 이 기능을 사용하지 않는 것이 좋습니다!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      '현재 \'홈\' 지역으로 응답합니다. (아직 적용되지 않았으며, 향후 사용을 위해 예약됨)';

  @override
  String get repeater_cliHelpRegionHomeSet => '\'홈\' 지역을 설정합니다.';

  @override
  String get repeater_cliHelpRegionSave => '지역 목록/지도를 저장에 유지합니다.';

  @override
  String get repeater_cliHelpGps =>
      'GPS 상태를 표시합니다. GPS가 꺼져 있으면 \"꺼짐\"이라고 표시하고, 켜져 있으면 \"켜짐\", 상태, 위치 정보, 위성 수 등을 표시합니다.';

  @override
  String get repeater_cliHelpGpsOnOff => 'GPS 전원 상태를 켜고 끄는 기능.';

  @override
  String get repeater_cliHelpGpsSync => '노드 시간을 GPS 시계와 동기화합니다.';

  @override
  String get repeater_cliHelpGpsSetLoc => '노드의 위치를 GPS 좌표로 설정하고, 설정을 저장합니다.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      '노드의 위치 광고 설정:\n- none: 광고에 위치 정보를 포함하지 않음\n- share: GPS 위치 정보를 공유 (SensorManager에서 가져옴)\n- prefs: 설정에 저장된 위치를 광고';

  @override
  String get repeater_cliHelpGpsAdvertSet => '위치 기반 광고 설정 구성';

  @override
  String get repeater_commandsListTitle => '명령 목록';

  @override
  String get repeater_commandsListNote =>
      '참고: 다양한 \"set...\" 명령과 함께 \"get...\" 명령도 존재합니다.';

  @override
  String get repeater_general => '일반';

  @override
  String get repeater_settingsCategory => '설정';

  @override
  String get repeater_bridge => '다리';

  @override
  String get repeater_logging => '로깅';

  @override
  String get repeater_neighborsRepeaterOnly => '이웃 (단방향 통신만 지원)';

  @override
  String get repeater_regionManagementRepeaterOnly => '지역 관리 (단, 중계 기능만 사용)';

  @override
  String get repeater_regionNote =>
      '지역별 관리 기능을 도입하여 지역 정의 및 권한 관리를 수행할 수 있습니다.';

  @override
  String get repeater_gpsManagement => 'GPS 관리';

  @override
  String get repeater_gpsNote => 'GPS 명령이 위치 관련 주제를 관리하기 위해 도입되었습니다.';

  @override
  String get telemetry_receivedData => '수신된 통신 데이터';

  @override
  String get telemetry_requestTimeout => '원격 모니터링 요청이 시간 초과되었습니다.';

  @override
  String telemetry_errorLoading(String error) {
    return '$error 오류로 인해 통신 데이터를 로드하지 못했습니다.';
  }

  @override
  String get telemetry_noData => '텔레메트리 데이터는 제공되지 않습니다.';

  @override
  String telemetry_channelTitle(int channel) {
    return '채널 $channel';
  }

  @override
  String get telemetry_batteryLabel => '배터리';

  @override
  String get telemetry_voltageLabel => '전압';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU의 온도';

  @override
  String get telemetry_temperatureLabel => '온도';

  @override
  String get telemetry_currentLabel => '현재';

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
    return '$celsius°C / $fahrenheit°F';
  }

  @override
  String get neighbors_receivedData => '이웃 정보 수집';

  @override
  String get neighbors_requestTimedOut => '이웃들이 시간 제한을 요청하고 있습니다.';

  @override
  String neighbors_errorLoading(String error) {
    return '이웃 정보 로딩 중 오류: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => '반복기, 이웃';

  @override
  String get neighbors_noData => '이웃 정보는 없습니다.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '알 수 없는 $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Heard: $time ago';
  }

  @override
  String get channelPath_title => '패킷 경로';

  @override
  String get channelPath_viewMap => '지도 보기';

  @override
  String get channelPath_otherObservedPaths => '관찰된 다른 경로';

  @override
  String get channelPath_repeaterHops => '반복 홉';

  @override
  String get channelPath_noHopDetails => '이 패키지에 대한 자세한 정보는 제공되지 않습니다.';

  @override
  String get channelPath_messageDetails => '메시지 세부 정보';

  @override
  String get channelPath_senderLabel => '발신자';

  @override
  String get channelPath_timeLabel => '시간';

  @override
  String get channelPath_repeatsLabel => '반복';

  @override
  String channelPath_pathLabel(int index) {
    return '경로 $index';
  }

  @override
  String get channelPath_observedLabel => '관찰';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return '관찰된 경로 $index • $hops';
  }

  @override
  String get channelPath_noLocationData => '위치 정보 없음';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => '알 수 없음';

  @override
  String get channelPath_floodPath => '홍수';

  @override
  String get channelPath_directPath => '직접';

  @override
  String channelPath_observedZeroOf(int total) {
    return '$total 중 0개';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed of $total hops';
  }

  @override
  String get channelPath_mapTitle => '경로 지도';

  @override
  String get channelPath_noRepeaterLocations => '이 경로에 대한 중계기 설치 위치는 없습니다.';

  @override
  String channelPath_primaryPath(int index) {
    return '경로 $index (주 경로)';
  }

  @override
  String get channelPath_pathLabelTitle => '경로';

  @override
  String get channelPath_observedPathHeader => '관찰된 경로';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable => '이 패킷에 대한 이동 정보는 제공되지 않습니다.';

  @override
  String get channelPath_unknownRepeater => '알 수 없는 중계기';

  @override
  String get community_title => '지역 사회';

  @override
  String get community_create => '커뮤니티 만들기';

  @override
  String get community_createDesc => '새로운 커뮤니티를 만들고 QR 코드를 통해 공유하세요.';

  @override
  String get community_join => '참여하기';

  @override
  String get community_joinTitle => '커뮤니티에 참여하기';

  @override
  String community_joinConfirmation(String name) {
    return '$name님, 커뮤니티에 참여하고 싶으신가요?';
  }

  @override
  String get community_scanQr => '커뮤니티 QR 스캔';

  @override
  String get community_scanInstructions => '카메라를 커뮤니티 QR 코드 방향으로 향하게 하세요.';

  @override
  String get community_showQr => 'QR 코드 표시';

  @override
  String get community_publicChannel => '지역 사회 대상';

  @override
  String get community_hashtagChannel => '커뮤니티 해시태그';

  @override
  String get community_name => '지역 이름';

  @override
  String get community_enterName => '커뮤니티 이름을 입력하세요';

  @override
  String community_created(String name) {
    return '커뮤니티 \"$name\"이 생성되었습니다.';
  }

  @override
  String community_joined(String name) {
    return '\"$name\" 커뮤니티에 가입';
  }

  @override
  String get community_qrTitle => '커뮤니티 공유';

  @override
  String community_qrInstructions(String name) {
    return '이 QR 코드를 스캔하여 \"$name\"에 가입하세요.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      '커뮤니티 해시태그 채널은 커뮤니티 구성원만 가입할 수 있습니다.';

  @override
  String get community_invalidQrCode => '유효하지 않은 커뮤니티 QR 코드';

  @override
  String get community_alreadyMember => '이미 회원인 경우';

  @override
  String community_alreadyMemberMessage(String name) {
    return '이미 $name의 회원입니다.';
  }

  @override
  String get community_addPublicChannel => '커뮤니티 공개 채널 추가';

  @override
  String get community_addPublicChannelHint => '이 커뮤니티에 공개 채널을 자동으로 추가합니다.';

  @override
  String get community_noCommunities => '아직 어느 커뮤니티도 가입하지 않았습니다.';

  @override
  String get community_scanOrCreate => 'QR 코드를 스캔하거나 커뮤니티를 만들어 시작하세요.';

  @override
  String get community_manageCommunities => '커뮤니티 관리';

  @override
  String get community_delete => '커뮤니티 떠나기';

  @override
  String community_deleteConfirm(String name) {
    return '$name을 묻어두나요?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return '또한, 이 기능은 $count개의 채널과 그에 해당하는 메시지를 삭제합니다.';
  }

  @override
  String community_deleted(String name) {
    return '지역 커뮤니티 \"$name\"';
  }

  @override
  String get community_regenerateSecret => '비밀 복원';

  @override
  String community_regenerateSecretConfirm(String name) {
    return '$name의 비밀 키를 재생성하시겠습니까? 모든 회원은 계속 통신을 위해 새로운 QR 코드를 스캔해야 합니다.';
  }

  @override
  String get community_regenerate => '재생';

  @override
  String community_secretRegenerated(String name) {
    return '$name을 위한 비밀 정보가 복원되었습니다.';
  }

  @override
  String get community_updateSecret => '비밀 업데이트';

  @override
  String community_secretUpdated(String name) {
    return '$name을 위한 비밀 정보 업데이트';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return '새로운 QR 코드를 스캔하여 $name의 비밀번호를 업데이트하세요.';
  }

  @override
  String get community_addHashtagChannel => '커뮤니티 해시태그 추가';

  @override
  String get community_addHashtagChannelDesc => '이 커뮤니티를 위한 해시태그 채널을 추가하세요.';

  @override
  String get community_selectCommunity => '커뮤니티 선택';

  @override
  String get community_regularHashtag => '일반 해시태그';

  @override
  String get community_regularHashtagDesc => '공개 해시태그 (누구나 참여 가능)';

  @override
  String get community_communityHashtag => '커뮤니티 해시태그';

  @override
  String get community_communityHashtagDesc => '지역 주민을 위한';

  @override
  String community_forCommunity(String name) {
    return '$name 님께';
  }

  @override
  String get listFilter_tooltip => '필터링 및 정렬';

  @override
  String get listFilter_sortBy => '정렬 기준 선택';

  @override
  String get listFilter_latestMessages => '최신 메시지';

  @override
  String get listFilter_heardRecently => '최근에 들었습니다';

  @override
  String get listFilter_az => 'A부터 Z까지';

  @override
  String get listFilter_filters => '필터';

  @override
  String get listFilter_source => '출처';

  @override
  String get listFilter_saved => '저장됨';

  @override
  String get listFilter_discovered => '발견됨';

  @override
  String get listFilter_all => '모든';

  @override
  String get listFilter_favorites => '관심 목록';

  @override
  String get listFilter_addToFavorites => '즐겨찾으로 추가';

  @override
  String get listFilter_removeFromFavorites => '즐겨찾에서 제거';

  @override
  String get listFilter_users => '사용자';

  @override
  String get listFilter_repeaters => '다시 보내는 장치';

  @override
  String get listFilter_roomServers => '방 내 서버';

  @override
  String get listFilter_unreadOnly => '읽지 않은 항목만';

  @override
  String get listFilter_newGroup => '새로운 그룹';

  @override
  String get pathTrace_you => '당신';

  @override
  String get pathTrace_failed => '경로 추적 실패.';

  @override
  String get pathTrace_notAvailable => '경로 추적 기능은 제공되지 않습니다.';

  @override
  String get pathTrace_refreshTooltip => '경로 추적 재시작';

  @override
  String get pathTrace_someHopsNoLocation => '홉 중 하나 또는 여러 개에 위치 정보가 누락되었습니다!';

  @override
  String get pathTrace_clearTooltip => '명확한 경로.';

  @override
  String get losSelectStartEnd => 'LOS(최소 거리 경로)의 시작 및 종료 노드를 선택합니다.';

  @override
  String losRunFailed(String error) {
    return '시야 확인 실패: $error';
  }

  @override
  String get losClearAllPoints => '모든 사항을 명확히 합니다.';

  @override
  String get losRunToViewElevationProfile =>
      'LOS(Line of Sight)를 사용하여 고도 프로필을 확인합니다.';

  @override
  String get losMenuTitle => 'LOS 메뉴';

  @override
  String get losMenuSubtitle => '사용자 지정 지점을 추가하려면, 노드를 탭하거나 맵을 길게 눌러 주세요.';

  @override
  String get losShowDisplayNodes => '노드 표시';

  @override
  String get losCustomPoints => '사용자 지정 포인트';

  @override
  String losCustomPointLabel(int index) {
    return '맞춤형 $index';
  }

  @override
  String get losPointA => 'A 지점';

  @override
  String get losPointB => '점 B';

  @override
  String losAntennaA(String value, String unit) {
    return '안테나 A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenna B: $value $unit';
  }

  @override
  String get losRun => 'LOS (Loss of Signal) 상태로 전환';

  @override
  String get losNoElevationData => '고도 정보 없음';

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
  String get losStatusChecking => 'LOS: 확인 중...';

  @override
  String get losStatusNoData => 'LOS: 데이터 없음';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total 개, $blocked 개, $unknown 개';
  }

  @override
  String get losErrorElevationUnavailable => '샘플 중 하나 이상에 대한 고도 데이터가 없습니다.';

  @override
  String get losErrorInvalidInput => 'LOS 계산에 사용되는 부정확한 지점/고도 데이터.';

  @override
  String get losRenameCustomPoint => '사용자 지정된 지점의 이름을 변경';

  @override
  String get losPointName => '항목 이름';

  @override
  String get losShowPanelTooltip => 'LOS 패널 표시';

  @override
  String get losHidePanelTooltip => 'LOS 패널 숨기기';

  @override
  String get losElevationAttribution => '고도 데이터: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => '라디오 호라이즌';

  @override
  String get losLegendLosBeam => 'LOS 빔';

  @override
  String get losLegendTerrain => '지형';

  @override
  String get losFrequencyLabel => '빈도';

  @override
  String get losFrequencyInfoTooltip => '계산 내역 보기';

  @override
  String get losFrequencyDialogTitle => '라디오 수신 가능 범위 계산';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return '$baselineK에서 시작하여 $baselineFreq MHz의 주파수에서 계산을 시작하면, 현재 $frequencyMHz MHz 대역에 대한 k-값을 조정하여, 이는 곡선형 라디오 지평선 상한선을 정의합니다.';
  }

  @override
  String get contacts_pathTrace => '경로 추적';

  @override
  String get contacts_ping => '핑';

  @override
  String get contacts_repeaterPathTrace => '리피터로 가는 경로';

  @override
  String get contacts_repeaterPing => '핑 반복';

  @override
  String get contacts_roomPathTrace => '방 서버로의 경로 추적';

  @override
  String get contacts_roomPing => '피нг 룸 서버';

  @override
  String get contacts_chatTraceRoute => '경로 추적 경로';

  @override
  String contacts_pathTraceTo(String name) {
    return '$name까지의 경로 추적';
  }

  @override
  String get contacts_clipboardEmpty => '클립보드가 비어 있습니다.';

  @override
  String get contacts_invalidAdvertFormat => '유효하지 않은 연락 정보';

  @override
  String get contacts_contactImported => '연락이 수신되었습니다.';

  @override
  String get contacts_contactImportFailed => '연락처를 가져오지 못했습니다.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name은(는) 이미 연락처에 있습니다.';
  }

  @override
  String get contacts_zeroHopAdvert => '제로 홉 광고';

  @override
  String get contacts_floodAdvert => '홍수 광고';

  @override
  String get contacts_copyAdvertToClipboard => '광고 텍스트를 클립보드에 복사';

  @override
  String get contacts_addContactFromClipboard => '복사본에서 연락처 추가';

  @override
  String get contacts_ShareContact => '연락처를 복사';

  @override
  String get contacts_ShareContactZeroHop => '광고를 통해 연락처 공유';

  @override
  String get contacts_zeroHopContactAdvertSent => '광고를 통해 연락처를 받았습니다.';

  @override
  String get contacts_zeroHopContactAdvertFailed => '연락처 전송에 실패했습니다.';

  @override
  String get contacts_contactAdvertCopied => '광고 내용이 복사되었습니다.';

  @override
  String get contacts_contactAdvertCopyFailed => '광고를 클립보드에 복사하는 데 실패했습니다.';

  @override
  String get contacts_addContact => '연락처 추가';

  @override
  String get contacts_scanQrCode => '연락처 QR 스캔';

  @override
  String get contacts_scanQrCodeDesc => 'MeshCore 앱의 연락처 QR 코드를 스캔합니다';

  @override
  String get contacts_enterIdHash => '연락처 직접 입력';

  @override
  String get contacts_enterIdHashDesc => '연락처 광고 또는 meshcore:// 링크 붙여넣기';

  @override
  String get contacts_advertHint => 'meshcore://... 또는 공개 키 hex';

  @override
  String get contacts_import => '가져오기';

  @override
  String get contacts_scanContactInstructions => 'MeshCore 연락처 QR 코드를 스캔하세요';

  @override
  String get notification_activityTitle => '메쉬코어 활동';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '메시지들',
      one: '메시지',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '채널 메시지',
      one: '채널 메시지',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '새 노드들',
      one: '새 노드',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return '새로운 $contactType 발견';
  }

  @override
  String get notification_receivedNewMessage => '새로운 메시지를 받았습니다';

  @override
  String get settings_gpxExportRepeaters => 'GPX로 전송/방 관리 서버';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'GPX 파일에 위치 정보를 포함하여 반복자/룸 서버를 내보냅니다.';

  @override
  String get settings_gpxExportContacts => 'GPX 형식으로 내보내기';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'GPX 파일에 위치 정보를 포함하여 동행하는 기능을 내보냅니다.';

  @override
  String get settings_gpxExportAll => '모든 연락처를 GPX 형식으로 내보내기';

  @override
  String get settings_gpxExportAllSubtitle =>
      '위치 정보가 있는 모든 연락처를 GPX 파일로 내보냅니다.';

  @override
  String get settings_gpxExportSuccess => 'GPX 파일이 성공적으로 내보내졌습니다.';

  @override
  String get settings_gpxExportNoContacts => '수출할 연락처가 없습니다.';

  @override
  String get settings_gpxExportNotAvailable => '귀하의 장치/운영체제에서는 지원되지 않습니다.';

  @override
  String get settings_gpxExportError => '데이터 내보내기 과정에서 오류가 발생했습니다.';

  @override
  String get settings_gpxExportRepeatersRoom => '중계 장치 및 서버 위치';

  @override
  String get settings_gpxExportChat => '함께 방문할 장소';

  @override
  String get settings_gpxExportAllContacts => '모든 연락처 위치';

  @override
  String get settings_gpxExportShareText => 'MeshTrax에서 추출한 지도 데이터';

  @override
  String get settings_gpxExportShareSubject => 'MeshTrax GPX 지도 데이터 내보내기';

  @override
  String get snrIndicator_nearByRepeaters => '주변의 중계기';

  @override
  String get snrIndicator_lastSeen => '마지막으로 목격';

  @override
  String get contactsSettings_title => '연락처 설정';

  @override
  String get contactsSettings_autoAddTitle => '자동 검색';

  @override
  String get contactsSettings_otherTitle => '다른 연락 관련 설정';

  @override
  String get contactsSettings_autoAddUsersTitle => '자동으로 사용자 추가';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      '동반자가 자동으로 발견한 사용자를 추가할 수 있도록 합니다.';

  @override
  String get contactsSettings_autoAddRepeatersTitle => '자동으로 중계기 추가';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      '애완동물이 발견한 무선 라디오를 자동으로 추가할 수 있도록 설정합니다.';

  @override
  String get contactsSettings_autoAddRoomServersTitle => '자동으로 방 서버 추가';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      '애완동물이 발견한 방 서버를 자동으로 추가할 수 있도록 설정합니다.';

  @override
  String get contactsSettings_autoAddSensorsTitle => '자동으로 센서 추가';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      '애완동물이 발견한 센서를 자동으로 추가할 수 있도록 설정합니다.';

  @override
  String get contactsSettings_overwriteOldestTitle => '가장 오래된 것을 덮어쓰기';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      '연락처 목록이 가득 차면, 가장 오래된 (선호하지 않은) 연락처가 대체됩니다.';

  @override
  String get discoveredContacts_Title => '연락처 찾기';

  @override
  String get discoveredContacts_noMatching => '일치하는 연락처가 없습니다.';

  @override
  String get listFilter_searchHint => '검색...';

  @override
  String get discoveredContacts_searchHint => '발견된 연락처 검색';

  @override
  String get discoveredContacts_contactAdded => '연락처 추가';

  @override
  String get discoveredContacts_addContact => '연락처 추가';

  @override
  String get discoveredContacts_copyContact => '복사';

  @override
  String get discoveredContacts_deleteContact => '발견된 연락처 삭제';

  @override
  String get discoveredContacts_deleteContactAll => '발견된 모든 연락처 삭제';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      '정말로 모든 검색된 연락처를 삭제하시겠습니까?';

  @override
  String get chat_sendCooldown => '다시 보내기 전에 잠시 기다려 주시기 바랍니다.';

  @override
  String get chat_notConnected => '무전기에 연결되어 있지 않습니다. 메시지를 보내지 못했습니다.';

  @override
  String get appSettings_jumpToOldestUnread => '가장 오래된, 아직 읽지 않은 항목으로 이동';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      '새로운 메시지가 없는 채팅을 열 때, 최신 메시지가 아닌 첫 번째 읽지 않은 메시지로 스크롤하세요.';

  @override
  String get appSettings_languageHu => '헝가리';

  @override
  String get appSettings_languageJa => '일본어';

  @override
  String get appSettings_languageKo => '한국어';

  @override
  String get radioStats_screenTitle => '라디오 통계';

  @override
  String get radioStats_notConnected => '라디오 통계를 확인하기 위해 장치에 연결합니다.';

  @override
  String get radioStats_firmwareTooOld =>
      '무선 통계 기능을 사용하려면 v8 또는 그 이상의 호환 펌웨어가 필요합니다.';

  @override
  String get radioStats_waiting => '데이터를 기다리는 중…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return '잡음 수준: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return '마지막 RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return '마지막 SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX 방송 시간 (총): $seconds 초';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX 사용 시간 (총): $seconds 초';
  }

  @override
  String get radioStats_chartCaption => '최근 샘플의 잡음 수준 (dBm)';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return '잡음 수준: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => '라디오 통계 가져오기…';

  @override
  String get radioStats_settingsTile => '라디오 통계';

  @override
  String get radioStats_settingsSubtitle => '잡음 수준, RSSI, 신호 대 잡음비, 통신 시간';

  @override
  String get translation_title => '번역';

  @override
  String get translation_enableTitle => '번역 기능 활성화';

  @override
  String get translation_enableSubtitle => '입력 메시지를 번역하고, 미리 번역 기능을 제공합니다.';

  @override
  String get translation_composerTitle => '보내기 전에 번역';

  @override
  String get translation_composerSubtitle => '컴포저 번역 아이콘의 기본 상태를 제어합니다.';

  @override
  String get translation_targetLanguage => '목표 언어';

  @override
  String get translation_useAppLanguage => '앱 언어 사용';

  @override
  String get translation_downloadedModelLabel => '다운로드한 모델';

  @override
  String get translation_presetModelLabel => '사전에 설정된 Hugging Face 모델';

  @override
  String get translation_manualUrlLabel => '수동 모델 URL';

  @override
  String get translation_downloadModel => '모델 다운로드';

  @override
  String get translation_downloading => '다운로드 중...';

  @override
  String get translation_working => '업무 중...';

  @override
  String get translation_stop => '멈춰';

  @override
  String get translation_mergingChunks => '다운로드한 파일 조각들을 최종 파일로 병합 중...';

  @override
  String get translation_downloadedModels => '다운로드한 모델';

  @override
  String get translation_deleteModel => '모델 삭제';

  @override
  String get translation_modelDownloaded => '번역 모델이 다운로드되었습니다.';

  @override
  String get translation_downloadStopped => '다운로드 중단됨.';

  @override
  String translation_downloadFailed(String error) {
    return '다운로드 실패: $error';
  }

  @override
  String get translation_enterUrlFirst => '먼저 모델 URL을 입력하세요.';

  @override
  String get scanner_linuxPairingShowPin => 'PIN 보기';

  @override
  String get scanner_linuxPairingHidePin => 'PIN 숨기기';

  @override
  String get scanner_linuxPairingPinTitle => '블루투스 페어링 PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return '$deviceName의 PIN을 입력하세요 (해당하는 경우에만 입력).';
  }

  @override
  String get translation_messageTranslation => '메시지 번역';

  @override
  String get translation_translateBeforeSending => '보내기 전에 번역';

  @override
  String get translation_composerEnabledHint => '메시지는 전송하기 전에 번역될 것입니다.';

  @override
  String get translation_composerDisabledHint => '원래 작성된 언어로 메시지를 보내세요.';

  @override
  String translation_translateTo(String language) {
    return '$language 번역';
  }

  @override
  String get translation_translationOptions => '번역 옵션';

  @override
  String get translation_systemLanguage => '시스템 언어';

  @override
  String get routing_title => '경로 설정';

  @override
  String routing_route(String route) {
    return '저장된 경로: $route';
  }

  @override
  String get routing_noRoute => '아직 없음 — 다음 메시지가 플러드로 전송되며 경로를 학습합니다';

  @override
  String get routing_auto => '자동';

  @override
  String get routing_autoSubtitle => '무전기에 저장된 경로를 사용합니다. 권장.';

  @override
  String get routing_pathfinderOn => 'Pathfinder 켜짐: 학습한 경로를 먼저 시도합니다';

  @override
  String get routing_flood => '항상 플러드';

  @override
  String get routing_floodSubtitle => '모든 메시지가 메시 전체로 전송됩니다';

  @override
  String get routing_custom => '사용자 지정 경로';

  @override
  String get routing_customSubtitle => '리피터를 직접 선택합니다';

  @override
  String get routing_forget => '경로 초기화';

  @override
  String get routing_forgetDone =>
      '경로를 초기화했습니다. 다음 메시지가 플러드로 전송되며 새 경로를 학습합니다.';

  @override
  String get routing_pathfinder => 'Pathfinder가 아는 정보';

  @override
  String get routing_pathfinderSubtitle => '나와 상대의 신호를 듣는 리피터, 학습한 왕복 경로';

  @override
  String get path_direct => '직접 — 리피터 없음';

  @override
  String get path_directSubtitle => '상대가 이 무전기를 직접 들을 수 있을 때만';

  @override
  String get chat_kindFlood => '플러드';

  @override
  String get chat_kindDirect => '직접';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '홉',
      one: '홉',
    );
    return '경로 ($count$_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'route ($count $_temp0, $guessed guessed)';
  }

  @override
  String get chat_statusQueued => '대기 중';

  @override
  String get chat_statusNoRepeaterHeard =>
      '내 신호를 들은 리피터가 없습니다. 범위 안에 리피터가 들어오면 다시 시도합니다.';

  @override
  String chat_narrowHashNotice(String name) {
    return '$name님의 무전기는 짧은 리피터 코드(1바이트)를 보냅니다. 상대 무전기가 2바이트 코드를 사용하기 전까지 Pathfinder는 상대에게 가는 경로를 학습할 수 없습니다.';
  }

  @override
  String chat_statusSending(String kind) {
    return '보내는 중 · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return '재시도 중 · $kind · $max번 중 $attempt번째';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return '전달됨 · $kind · $secs초';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return '$attempt번째 시도에 전달됨 · $kind · $secs초';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return '늦게 전달됨 · $kind · $secs초';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return '전달됨 · $secs초';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: '번',
      one: '번',
    );
    return '$attempts$_temp0 시도 후 실패 · 탭하여 다시 보내기';
  }

  @override
  String get chat_statusFailedShort => '실패 · 탭하여 다시 보내기';

  @override
  String get chat_resendingByFlood => '플러드로 다시 보내는 중';

  @override
  String get pathfinderHelp_title => 'What Pathfinder does';

  @override
  String get pathfinderHelp_what =>
      'Your radio remembers one route to each contact and floods the whole mesh when that route fails. Pathfinder listens to everything the radio hears: repeater announcements, channel chatter, other people\'s messages. From that it builds a map of which repeaters hear each other, which ones hear you, and which ones hear each of your contacts.';

  @override
  String get pathfinderHelp_how =>
      'When you send a message, Pathfinder tries its best route first, then its next best, and floods only as a last resort. An amber path icon marks a message that went out on a Pathfinder route.';

  @override
  String get pathfinderHelp_learning =>
      'It needs time. A fresh map knows nothing, so at first your messages go out exactly as before. After some hours of listening in one place it starts to offer routes, and every delivery or failure teaches it more. Expect little from it on the first day, and less again whenever you move somewhere new.';

  @override
  String get pathfinderHelp_guessed =>
      'Sometimes it fills a gap with a guess: a link it has only heard used in the other direction. The message line then says how many hops were guessed. A delivery proves them; a failure costs one attempt and nothing is remembered.';

  @override
  String get pathfinderHelp_discover =>
      'When it isn\'t sure which repeaters can hear you here, Pathfinder sends one short Discover (at most every 10 minutes, only after a send has failed) and, with a GPS radio, remembers on this phone which repeaters heard you in each area of about 500 m, never your exact spot.';

  @override
  String get pathfinderHelp_off =>
      'Turn Pathfinder off and the radio routes exactly as it did before.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Don\'t show this again';

  @override
  String get pathfinderHelp_ok => 'OK';

  @override
  String get settings_pathGraph => 'Pathfinder (실험적)';

  @override
  String get settings_pathGraphSubtitle =>
      '무전기가 듣는 모든 것에서 경로를 학습하고, DM을 보낼 때 가장 좋은 경로부터 시도합니다. 호박색 경로 아이콘은 Pathfinder 경로로 보낸 메시지를 표시합니다.';

  @override
  String get map_routeAndTrace => '경로 및 추적';

  @override
  String get map_pathfinderTrace => '왕복 추적';

  @override
  String get map_pathfinderTraceSubtitle =>
      '갈 때는 Pathfinder의 최적 경로, 돌아올 때는 최적 복귀 경로';

  @override
  String get map_routeBackMirrored => '아직 알려진 복귀 경로 없음 — 같은 길로 돌아옵니다';

  @override
  String get map_traceHelpTitle => '경로 추적 버튼';

  @override
  String get map_traceHelpCustom => '리피터를 직접 입력하거나 선택합니다.';

  @override
  String get map_traceHelpRun => '탭한 리피터를 따라 한 방향으로 추적을 보냅니다.';

  @override
  String get map_traceHelpThereAndBack => '왕복';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      '추적을 보낸 뒤, 같은 리피터를 거꾸로 거쳐 돌아오게 합니다.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder가 마지막으로 탭한 두 리피터를 지나는 최적 경로와 나에게 돌아오는 최적 경로를 고릅니다. 그 결과로 Pathfinder는 실제로 작동하는 링크를 배웁니다. 리피터 두 개를 탭해야 합니다.';

  @override
  String get map_traceHelpRemoveLast => '마지막 리피터를 경로에서 뺍니다.';

  @override
  String get map_traceHelpCancel => '추적 만들기를 중단합니다. 리피터를 탭하기 전에 표시됩니다.';

  @override
  String get chat_resendingByRoute => '설정한 경로로 다시 전송 중';

  @override
  String get room_mute => '룸 음소거';

  @override
  String get room_unmute => '룸 음소거 해제';

  @override
  String get room_roleAdmin => '관리자';

  @override
  String get room_roleMember => '멤버';

  @override
  String get room_roleReadOnly => '읽기 전용';

  @override
  String room_clockOff(int minutes) {
    return '룸 시계가 약 $minutes분 어긋나 있습니다 — 메시지 시간이 틀릴 수 있습니다';
  }

  @override
  String get room_fixClock => '시계 맞추기';

  @override
  String get room_clockSyncSent => '룸으로 시계 동기화를 보냈습니다';

  @override
  String get room_readOnlyNotice =>
      '읽기 전용: 룸이 비밀번호를 승인하지 않아 보낸 메시지가 다른 멤버에게 전달되지 않습니다.';

  @override
  String get room_postAnnouncement => '공지 올리기';

  @override
  String get room_postAnnouncementSubtitle => '룸 자체 이름으로 모든 멤버에게 메시지 보내기';

  @override
  String get room_announcementSent => '공지를 올렸습니다';

  @override
  String get room_announcementFailed => '공지 게시에 실패했습니다';

  @override
  String get room_users => '룸 사용자';

  @override
  String get room_usersSubtitle => '관리자 확인 및 역할 설정';

  @override
  String get room_usersAdminsNote =>
      '룸은 관리자만 표시합니다. 룸 비밀번호로 참여한 멤버는 표시되지 않습니다.';

  @override
  String get room_usersLoadFailed => '관리자 목록을 불러오지 못했습니다';

  @override
  String get room_setUserRole => '역할 설정';

  @override
  String get room_removeAccess => '접근 권한 제거';

  @override
  String get room_removeOnlyUnknown => '이 사용자는 연락처에 없어 제거만 가능하고 변경할 수 없습니다.';

  @override
  String get room_roleUpdated => '역할이 변경되었습니다';

  @override
  String get room_roleUpdateFailed => '역할 변경에 실패했습니다';

  @override
  String get room_postsStored => '저장된 게시물';

  @override
  String get room_postsDelivered => '전달된 게시물';

  @override
  String get room_reloadPosts => '최근 게시물 다시 불러오기';

  @override
  String get room_reloadPostsExplain =>
      '룸에 최근 게시물(최대 32개 보관)을 다시 보내 달라고 요청합니다. 룸 비밀번호가 필요합니다. 기존 메시지는 유지됩니다.';

  @override
  String get room_reloadFailed => '무전기에서 룸을 초기화하지 못했습니다';

  @override
  String get companionCli_title => '명령줄';

  @override
  String get companionCli_settingsSubtitle => '이 무전기에 텍스트 명령 입력';

  @override
  String get companionCli_rebooting => '무전기를 다시 시작하는 중…';

  @override
  String get companionCli_cancelled => '취소됨';

  @override
  String get companionCli_poweringOff => '무전기를 끄는 중…';

  @override
  String get companionCli_noReply => '무전기에서 응답이 없습니다. 다시 시도하세요.';

  @override
  String get companionCli_powerOffTitle => '무전기를 끌까요?';

  @override
  String get companionCli_powerOffBody => '버튼을 누르거나 전원을 연결할 때까지 꺼진 상태로 유지됩니다.';

  @override
  String get companionCli_powerOff => '끄기';

  @override
  String get companionCli_quickBoard => '보드';

  @override
  String get companionCli_quickWifiStatus => 'Wi‑Fi 상태';

  @override
  String get companionCli_quickWifiAddress => 'Wi‑Fi 주소';

  @override
  String get companionCli_helpBoard => '보드 제조사와 모델을 표시합니다.';

  @override
  String get companionCli_helpReboot => '무전기를 다시 시작합니다.';

  @override
  String get companionCli_helpPowerOff => '무전기를 끕니다.';

  @override
  String get companionCli_helpSetPin => '블루투스 페어링 PIN을 설정합니다. 다시 시작한 후 적용됩니다.';

  @override
  String get companionCli_helpSetTzOffset =>
      '무전기 자체 화면의 시계에 쓰도록 UTC에 더할 시간을 설정합니다(-12~+14).';

  @override
  String get companionCli_helpSetTx => '송신 출력을 dBm 단위로 설정합니다. 바로 적용됩니다.';

  @override
  String get companionCli_helpSetIntThresh =>
      '간섭 임계값을 dB 단위로 설정합니다. 0이면 간섭 감지를 끕니다.';

  @override
  String get companionCli_helpSetCad =>
      '보내기 전에 다른 무전기의 신호가 있는지 확인합니다(채널 활동 감지).';

  @override
  String get companionCli_helpSetRxGain => 'SX126x 무전기에서 수신 게인을 높입니다.';

  @override
  String get companionCli_helpSetPathHashMode =>
      '경로에서 리피터 하나당 바이트 수: 0 = 1바이트, 1 = 2바이트, 2 = 3바이트.';

  @override
  String get companionCli_helpWifiStatus => '무전기가 Wi‑Fi 네트워크에 연결되어 있는지 표시합니다.';

  @override
  String get companionCli_helpWifiIp => 'Wi‑Fi 네트워크에서 무전기의 주소를 표시합니다.';

  @override
  String get companionCli_helpWifiSsid =>
      'Wi‑Fi 네트워크 이름을 설정합니다. 다시 시작한 후 적용됩니다.';

  @override
  String get companionCli_helpWifiPwd => 'Wi‑Fi 비밀번호를 설정합니다. 다시 시작한 후 적용됩니다.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Wi‑Fi를 켜거나(1) 끕니다(0). 다시 시작한 후 적용됩니다.';

  @override
  String get companionCli_helpWifiClear =>
      '저장된 Wi‑Fi 네트워크를 삭제합니다. 다시 시작한 후 적용됩니다.';

  @override
  String get companionCli_remoteNoReply =>
      '응답이 없습니다. 상대 무전기는 펌웨어 1.18 이상이어야 하며, 내가 명령줄을 사용하도록 허용해야 합니다.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      '보냈습니다. 무전기는 다시 시작이나 전원 끄기에는 응답하지 않습니다.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name님이 내 무전기의 명령줄을 사용하려고 했습니다: \"$command\". 허용되지 않았습니다.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return '내 무전기의 명령줄을 사용하려고 했습니다: \"$command\". 허용되지 않았습니다.';
  }

  @override
  String get contact_remoteCli => '원격 명령줄 허용';

  @override
  String get contact_remoteCliSubtitle => '이 연락처가 내 무전기에서 명령을 실행할 수 있게 합니다';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return '$name님이 내 무전기를 제어하게 할까요?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name님이 무전기 설정 변경, Wi‑Fi 비밀번호 확인, 무전기 이름 변경, 다시 시작 및 전원 끄기를 할 수 있게 됩니다. 완전히 신뢰하는 사람에게만 허용하세요.';
  }

  @override
  String get contact_remoteCliAllow => '허용';

  @override
  String get connection_secondApp =>
      '다른 앱이 이 무전기에 연결되어 있습니다. 메시지와 설정이 뒤섞일 수 있습니다. 다른 앱을 닫으세요.';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => '네트워크, 비밀번호, 연결';

  @override
  String get wifi_use => 'Wi‑Fi 사용';

  @override
  String get wifi_networkName => '네트워크 이름';

  @override
  String get wifi_password => '비밀번호';

  @override
  String get wifi_passwordUnchanged => '변경 안 함';

  @override
  String get wifi_showPassword => '비밀번호 표시';

  @override
  String get wifi_nameMissing => '네트워크 이름을 입력하세요';

  @override
  String get wifi_nameTooLong => '네트워크 이름이 너무 깁니다(최대 32바이트)';

  @override
  String get wifi_passwordTooLong => '비밀번호가 너무 깁니다(최대 63바이트)';

  @override
  String get wifi_savedRestart => '저장했습니다. Wi‑Fi 변경 사항은 무전기를 다시 시작한 후 적용됩니다.';

  @override
  String get wifi_forget => '네트워크 삭제';

  @override
  String get wifi_forgetConfirm =>
      '이 Wi‑Fi 네트워크를 삭제할까요? 무전기는 다시 시작한 후 Wi‑Fi를 사용하지 않습니다.';

  @override
  String wifi_notAccepted(String reply) {
    return '무전기가 받아들이지 않았습니다: $reply';
  }

  @override
  String get wifi_noReply => '무전기에서 응답이 없습니다. 다시 시도하세요.';

  @override
  String get wifi_restartTitle => '무전기를 다시 시작할까요?';

  @override
  String get wifi_later => '나중에';

  @override
  String get wifi_loadFailed => '무전기에서 Wi‑Fi 설정을 읽지 못했습니다.';

  @override
  String wifi_connectedTo(String address) {
    return '연결됨 · $address';
  }

  @override
  String get wifi_notConnected => 'Wi‑Fi에 연결되지 않음';

  @override
  String wifi_portNote(int port) {
    return '같은 네트워크의 앱은 포트 $port로 연결할 수 있습니다';
  }

  @override
  String get wifi_connectOverWifi => 'Wi‑Fi로 연결';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax가 이 무전기와 연결을 끊고 $address, 포트 $port가 입력된 TCP 화면을 엽니다. 그 화면에서 \'연결\'을 탭하세요.';
  }

  @override
  String get wifi_noteRestart => '변경 사항은 무전기를 다시 시작한 후 적용됩니다.';

  @override
  String get wifi_noteSecurity =>
      'Wi‑Fi 네트워크에 있는 누구나 포트 5000으로 무전기에 연결할 수 있습니다. 여기에는 비밀번호가 없습니다.';

  @override
  String get wifi_noteBattery =>
      'Wi‑Fi를 켜면 무전기가 절전 상태로 들어가지 않아 배터리가 더 빨리 닳습니다.';

  @override
  String get wifi_noteWrongPassword =>
      '비밀번호가 틀리면 무전기는 몇 초마다 계속 연결을 시도합니다. 블루투스는 계속 작동합니다.';

  @override
  String get room_selfDemoteWarning =>
      '자신의 접근 권한을 변경하려고 합니다. 관리자 역할을 잃으면 룸 자체 콘솔에서만 되돌릴 수 있습니다.';

  @override
  String get scanner_offlineMaps => '오프라인 지도';

  @override
  String get appSettings_offlineMaps => '오프라인 지도';

  @override
  String get appSettings_offlineMapsNone => '다운로드한 지도 없음';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '지역 $count개',
      one: '지역 1개',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '해도 구역 $count개',
      one: '해도 구역 1개',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '업데이트 $count개 있음',
      one: '업데이트 1개 있음',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly => 'Wi‑Fi에서만 지도 다운로드';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      '지도 다운로드는 Wi‑Fi에 연결될 때까지 기다립니다';

  @override
  String get offlineMaps_title => '오프라인 지도';

  @override
  String get offlineMaps_tabMaps => '지도';

  @override
  String get offlineMaps_tabCharts => '해도';

  @override
  String get offlineMaps_chartsNotice => '항해용 아님 · 이유는?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return '추천 · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => '해안별 해도 구역';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '구역 $count개',
      one: '구역 1개',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '$count개 다운로드됨';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '$count개 선택됨';
  }

  @override
  String get offlineMaps_selectAll => '모두 선택';

  @override
  String get offlineMaps_clearSelection => '선택 해제';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return '$coasts에도 포함';
  }

  @override
  String get offlineMaps_chartsNotAvailable => '아직 사용할 수 없음';

  @override
  String get offlineMaps_chartsHint => 'NOAA 해도는 \'해도\' 탭에서 해안별로 고릅니다.';

  @override
  String offlineMaps_chartsName(String area) {
    return '$area NOAA 해도';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '구역 $count개',
      one: '구역 1개',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => '다운로드됨';

  @override
  String get offlineMaps_refresh => '새 지도 확인';

  @override
  String get offlineMaps_loading => '사용 가능한 지도 불러오는 중…';

  @override
  String get offlineMaps_serverError => '지도 서버에 연결할 수 없습니다';

  @override
  String get offlineMaps_unavailable => '아직 사용할 수 있는 지도가 없습니다';

  @override
  String get offlineMaps_unavailableHint => '나중에 다시 확인하세요.';

  @override
  String get offlineMaps_chartsUnavailable => '아직 사용할 수 있는 NOAA 해도가 없습니다';

  @override
  String offlineMaps_cachedFrom(String date) {
    return '$date 기준 목록 표시 중';
  }

  @override
  String get offlineMaps_needsNewerApp => '최신 지도를 받으려면 MeshTrax를 업데이트하세요.';

  @override
  String get offlineMaps_world => '세계';

  @override
  String get offlineMaps_suggested => '추천';

  @override
  String get offlineMaps_regions => '지역';

  @override
  String offlineMaps_regionsIn(String name) {
    return '$name의 지역';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count개 포함';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '이 기기의 오프라인 지도: $size';
  }

  @override
  String offlineMaps_updates(int count) {
    return '업데이트 ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return '모두 업데이트 $size';
  }

  @override
  String get offlineMaps_downloading => '다운로드 중';

  @override
  String get offlineMaps_update => '업데이트';

  @override
  String offlineMaps_downloadedOn(String date) {
    return '$date에 다운로드함';
  }

  @override
  String get offlineMaps_updateAvailable => '업데이트 있음';

  @override
  String get offlineMaps_otherFiles => '기타 지도 파일';

  @override
  String get offlineMaps_emptyTitle => '아직 오프라인 지도가 없습니다';

  @override
  String get offlineMaps_emptyBody => '지역을 다운로드하면 인터넷 연결 없이도 지도를 쓸 수 있습니다.';

  @override
  String get offlineMaps_findMaps => '지도 찾기';

  @override
  String offlineMaps_deleteTitle(String name) {
    return '$name을(를) 삭제할까요?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return '$size의 공간이 확보됩니다. 나중에 다시 다운로드할 수 있습니다.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name 삭제됨';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get offlineMaps_kindMap => '지도';

  @override
  String get offlineMaps_kindMapDetail => 'OpenStreetMap 도로, 탐방로, 지명';

  @override
  String get offlineMaps_kindContours => '등고선';

  @override
  String get offlineMaps_kindContoursDetail => '고도를 나타내는 선';

  @override
  String get offlineMaps_kindUsgs => 'USGS 지형도';

  @override
  String get offlineMaps_kindUsgsDetail => '탐방로, 하천, 보호구역';

  @override
  String get offlineMaps_kindTerrain => '음영 기복';

  @override
  String get offlineMaps_kindTerrainDetail => '언덕과 산을 지도 아래에 음영으로 표시';

  @override
  String get offlineMaps_kindCharts => 'NOAA 해도';

  @override
  String get offlineMaps_usOnly => '미국만 해당';

  @override
  String offlineMaps_download(String size) {
    return '다운로드 $size';
  }

  @override
  String get offlineMaps_downloadTotal => '다운로드';

  @override
  String offlineMaps_largeDownload(String size) {
    return '용량이 큰 다운로드입니다($size). Wi‑Fi를 사용하고 기기를 충전하면서 받으세요.';
  }

  @override
  String get offlineMaps_waiting => '대기 중…';

  @override
  String get offlineMaps_checking => '다운로드 확인 중…';

  @override
  String get offlineMaps_retrying => '다시 시도하는 중…';

  @override
  String offlineMaps_failed(String error) {
    return '다운로드 실패: $error';
  }

  @override
  String get offlineMaps_pause => '일시 중지';

  @override
  String get offlineMaps_resume => '재개';

  @override
  String get offlineMaps_deleteRegion => '지역 삭제';

  @override
  String get offlineMaps_notInCatalogue => '이 지역에서는 사용할 수 없음';

  @override
  String get offlineMaps_notificationRunning => '지도 다운로드 중';

  @override
  String get offlineMaps_notificationPaused => '지도 다운로드 일시 중지됨';

  @override
  String get offlineMaps_notificationFailed => '지도 다운로드 실패';

  @override
  String get offlineMaps_clearTileCache => '온라인 지도 캐시 지우기';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      '둘러보는 동안 저장된 온라인 지도 타일을 삭제할까요? 다운로드한 지도는 그대로 남습니다.';

  @override
  String get offlineMaps_tileCacheCleared => '온라인 지도 캐시를 삭제했습니다';

  @override
  String get map_notForNavigation => '항해용 아님';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax는 NOAA 해도 데이터로 이 해도를 그려, 무전기 주변 바다를 살펴보고 계획을 세우는 데 도움을 줍니다. 공식 해도가 아닙니다. 이 해도를 보고 배를 조종하지 마세요.';

  @override
  String get map_chartsNoticeWhy => '이유:';

  @override
  String get map_chartsNoticeOutOfDate =>
      '정보가 오래됩니다. NOAA는 해도를 계속 수정하지만, 다운로드한 해도는 \'오프라인 지도\'에서 업데이트할 때까지 그대로입니다.';

  @override
  String get map_chartsNoticeLeftOut =>
      '빠진 정보가 있습니다. 많은 해도 기호, 등화 섹터, 주석이 그려지지 않으며, 일부 라벨은 확대해야 보입니다.';

  @override
  String get map_chartsNoticePositions =>
      '위치가 틀리거나 오래되었을 수 있습니다. GPS는 10 m (30 ft) 이상 어긋날 수 있고, 노드는 마지막으로 보고한 위치에 표시될 뿐입니다.';

  @override
  String get map_chartsNoticeNotPlotter => 'MeshTrax는 인증된 차트 플로터가 아닙니다.';

  @override
  String get map_chartsNoticeUse =>
      '항해할 때는 최신 항행통보와 함께 공식 최신 NOAA 해도(종이 해도 또는 인증된 차트 플로터의 NOAA ENC)를 사용하세요.';

  @override
  String get map_sourceOnline => '온라인';

  @override
  String get map_sourceOffline => '오프라인';

  @override
  String get map_downloadForDetail => '자세히 보려면 지역 다운로드';

  @override
  String get map_zoomInForOfflineMap => '확대하면 오프라인 지도가 보입니다';

  @override
  String get map_noCharts => '이곳에는 해도가 없습니다';

  @override
  String get map_myLocation => '내 위치';

  @override
  String get map_zoomIn => '확대';

  @override
  String get map_zoomOut => '축소';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS 켜짐';

  @override
  String get gps_off => 'GPS 꺼짐';

  @override
  String get gps_onHint => '무전기가 GPS로 위치를 업데이트합니다.';

  @override
  String get gps_offHint => '끄면 무전기 배터리를 아낄 수 있습니다. 켜면 위치를 찾는 데 몇 분 걸릴 수 있습니다.';

  @override
  String get gps_asking => '무전기에 묻는 중...';

  @override
  String get gps_noPosition => '아직 위치가 없습니다. 실외에서는 첫 위치를 잡는 데 몇 분 걸릴 수 있습니다.';

  @override
  String get gps_position => '위치';

  @override
  String get gps_altitude => '고도';

  @override
  String gps_readAgo(String ago) {
    return '$ago 전에 무전기에서 읽음';
  }

  @override
  String get gps_turnOnTitle => 'GPS를 켤까요?';

  @override
  String get gps_turnOnBody => '무전기의 GPS가 꺼져 있습니다. 켜면 위치를 찾는 데 몇 분 걸릴 수 있습니다.';

  @override
  String get gps_turnOn => '켜기';

  @override
  String get gps_notNow => '나중에';

  @override
  String get map_zoomInForCharts => '확대하면 해도가 보입니다';

  @override
  String map_downloadRegion(String region, String size) {
    return '$region 다운로드 · $size';
  }

  @override
  String get mapLayers_title => '지도 레이어';

  @override
  String get mapLayers_mapType => '지도 유형';

  @override
  String get mapLayers_standard => '기본';

  @override
  String get mapLayers_usgs => 'USGS 지형도';

  @override
  String get mapLayers_charts => '해도';

  @override
  String get mapLayers_notDownloaded => '다운로드 안 됨';

  @override
  String get mapLayers_offlineOnly => '오프라인 전용';

  @override
  String get mapLayers_details => '지도 세부 정보';

  @override
  String get mapLayers_contours => '등고선';

  @override
  String get mapLayers_hillShading => '음영 기복';

  @override
  String get mapLayers_dark => '어두운 지도';

  @override
  String get mapLayers_downloadedAreas => '다운로드한 지역';

  @override
  String get mapLayers_nodes => '노드';

  @override
  String get mapLayers_pins => '핀';

  @override
  String get mapLayers_guessed => '추정 위치';

  @override
  String get mapLayers_moreFilters => '추가 필터';

  @override
  String get mapLayers_moreFiltersDetail => '마지막 수신, 키 접두사, 중복';

  @override
  String get map_legend => '범례';

  @override
  String get scanner_map => '지도';

  @override
  String get structured_openMap => '지도 열기';

  @override
  String get structured_addToCalendar => '캘린더에 추가';

  @override
  String get structured_details => '세부 정보';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => '이벤트';

  @override
  String get structured_notice => '공지';

  @override
  String get structured_allDay => '종일';

  @override
  String get structured_calendarFailed => '캘린더를 열 수 없습니다';

  @override
  String get structured_today => '오늘';

  @override
  String get structured_tomorrow => '내일';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일 후',
      one: '1일 후',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => '지난 일정';

  @override
  String structured_dayOfDays(int day, int total) {
    return '$total일 중 $day일째';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count일',
      one: '1일',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => '종료일';

  @override
  String get dialog_eventSameDay => '같은 날';

  @override
  String get structured_map => '지도';

  @override
  String get structured_navigate => '길 안내';

  @override
  String get structured_channel => '채널';

  @override
  String get structured_contact => '연락처';

  @override
  String get structured_room => '룸';

  @override
  String get structured_repeater => '리피터';

  @override
  String get structured_sensor => '센서';

  @override
  String get structured_joinChannel => '채널 참여';

  @override
  String get structured_addContact => '연락처 추가';

  @override
  String get structured_addRoom => '룸 추가';

  @override
  String get structured_addRepeater => '리피터 추가';

  @override
  String get structured_addSensor => '센서 추가';

  @override
  String get structured_open => '열기';

  @override
  String get structured_added => '추가됨';

  @override
  String get tray_add => '추가';

  @override
  String get tray_myLocation => '내 위치';

  @override
  String get tray_pointOnMap => '지도상의 지점';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => '이벤트';

  @override
  String get tray_notice => '공지';

  @override
  String get tray_noRadioPosition => '무전기에 아직 위치가 없습니다. 지도에서 선택하세요.';

  @override
  String get dialog_insert => '삽입';

  @override
  String get dialog_eventTitle => '제목';

  @override
  String get dialog_eventDate => '날짜';

  @override
  String get dialog_eventStart => '시작';

  @override
  String get dialog_eventEnd => '종료';

  @override
  String get dialog_eventNoEnd => '종료 시간 없음';

  @override
  String get dialog_eventPlace => '장소(선택)';

  @override
  String get dialog_pickOnMap => '지도에서 선택';

  @override
  String get dialog_sosTitle => 'SOS 보내기';

  @override
  String get dialog_sosText => '무슨 일이 있었나요?';

  @override
  String get dialog_noticeTitle => '공지';

  @override
  String get dialog_noticeText => '모두에게 무엇을 알릴까요?';

  @override
  String get dialog_labelTitle => '지도상의 지점';

  @override
  String get dialog_note => '메모(선택)';

  @override
  String get paste_convertLocation => '지도 링크 같습니다. 위치로 변환할까요?';

  @override
  String get paste_convertEvent => '캘린더 공유 같습니다. 이벤트로 변환할까요?';

  @override
  String get paste_convert => '변환';

  @override
  String get paste_resolving => '링크 확인 중…';

  @override
  String get paste_resolveFailed => '링크를 확인할 수 없습니다';

  @override
  String get pinned_dismiss => '닫기';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return '$name 채널에 참여할까요?';
  }

  @override
  String link_alreadyJoined(String name) {
    return '이미 $name에 참여 중입니다';
  }

  @override
  String link_channelJoined(String name) {
    return '$name에 참여했습니다';
  }

  @override
  String get map_pickPositionHint => '지도를 탭해 위치를 선택하세요';

  @override
  String get map_legendMesh => '메시';

  @override
  String get chartLegend_title => '해도 기호';

  @override
  String get chartLegend_sectionBuoys => '부표와 입표';

  @override
  String get chartLegend_sectionLights => '등화';

  @override
  String get chartLegend_sectionHazards => '위험 요소';

  @override
  String get chartLegend_sectionTides => '조석과 조류';

  @override
  String get chartLegend_sectionDepths => '수심과 해저';

  @override
  String get chartLegend_sectionAreas => '구역, 항로, 선';

  @override
  String get chartLegend_sectionLandmarks => '육상 목표물';

  @override
  String get chartLegend_sectionAbbreviations => '약어';

  @override
  String get chartLegend_chartNo1 => '모든 해도 기호: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => '녹색 원통형 부표';

  @override
  String get chartLegend_portBuoyHint => '바다에서 들어올 때 왼쪽에 두고 진행';

  @override
  String get chartLegend_starboardBuoy => '적색 원뿔형 부표';

  @override
  String get chartLegend_starboardBuoyHint => '들어올 때 오른쪽에 두고 진행: 돌아올 때 빨강은 오른쪽';

  @override
  String get chartLegend_junctionBuoy => '가로띠 부표';

  @override
  String get chartLegend_junctionBuoyHint => '수로 분기점: 맨 위 띠의 색 표지로 간주';

  @override
  String get chartLegend_safeWaterBuoy => '빨강·흰색 세로줄';

  @override
  String get chartLegend_safeWaterBuoyHint => '주변이 모두 안전한 수역, 주로 수로 입구에 있음';

  @override
  String get chartLegend_isolatedDangerBuoy => '검정·빨강 가로띠';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      '주변이 안전한 수역에 있는 작은 위험물: 가까이 가지 말 것';

  @override
  String get chartLegend_specialBuoy => '노란색 부표';

  @override
  String get chartLegend_specialBuoyHint => '특수 목적, 항행 기준이 아님: 묘박지, 케이블, 조사 등';

  @override
  String get chartLegend_cardinalBuoy => '검정·노랑';

  @override
  String get chartLegend_cardinalBuoyHint =>
      '방위표지: 표지가 가리키는 방위 쪽으로 통과(미국에서는 드묾)';

  @override
  String get chartLegend_mooringBuoy => '계류 부표';

  @override
  String get chartLegend_portBeacon => '녹색 사각형 입표';

  @override
  String get chartLegend_portBeaconHint => '녹색 부표와 같음: 들어올 때 왼쪽에 두고 진행';

  @override
  String get chartLegend_starboardBeacon => '적색 삼각형 입표';

  @override
  String get chartLegend_starboardBeaconHint => '적색 부표와 같음: 들어올 때 오른쪽에 두고 진행';

  @override
  String get chartLegend_otherBeacon => '마름모꼴 입표';

  @override
  String get chartLegend_otherBeaconHint => '정보나 경고 표시, 수로의 좌우를 나타내지 않음';

  @override
  String get chartLegend_beaconTower => '등탑 또는 입표 구조물';

  @override
  String get chartLegend_topmark => '두표';

  @override
  String get chartLegend_topmarkHint => '표지 위의 형상이 의미를 더함';

  @override
  String get chartLegend_light => '등화';

  @override
  String get chartLegend_lightHint => '자홍색 불빛 모양은 등화를 나타내며, 라벨이 빛나는 방식을 알려 줌';

  @override
  String get chartLegend_lightExample => '녹색 섬광, 4초마다';

  @override
  String get chartLegend_lightExampleHint => '등화 라벨: 등질, 색, 주기 순';

  @override
  String get chartLegend_lightFixed => '부동광';

  @override
  String get chartLegend_lightFixedHint => '계속 켜져 있는 빛';

  @override
  String get chartLegend_lightFlashing => '섬광';

  @override
  String get chartLegend_lightFlashingHint => '짧은 빛, 그 사이 더 긴 어둠';

  @override
  String get chartLegend_lightGroup => '군섬광';

  @override
  String get chartLegend_lightGroupHint => '묶음으로 깜박임(여기서는 2회), 그다음 어둠';

  @override
  String get chartLegend_lightComposite => '복합군섬광';

  @override
  String get chartLegend_lightCompositeHint => '2회 깜박인 뒤 1회: 수로 분기점 표시';

  @override
  String get chartLegend_lightQuick => '급섬광';

  @override
  String get chartLegend_lightQuickHint => '1초에 약 1회 깜박임';

  @override
  String get chartLegend_lightIsophase => '등명암광';

  @override
  String get chartLegend_lightIsophaseHint => '밝음과 어둠이 같은 길이';

  @override
  String get chartLegend_lightOcculting => '명암광';

  @override
  String get chartLegend_lightOccultingHint => '켜진 시간이 꺼진 시간보다 김';

  @override
  String get chartLegend_lightMorse => '모스 부호 A';

  @override
  String get chartLegend_lightMorseHint => '짧게, 길게: 안전 수역';

  @override
  String get chartLegend_lightAlternating => '호광';

  @override
  String get chartLegend_lightAlternatingHint => '색이 바뀜';

  @override
  String get chartLegend_lightColours => '흰색, 빨강, 녹색, 노랑';

  @override
  String get chartLegend_lightPeriod => '주기';

  @override
  String get chartLegend_lightPeriodHint => '한 주기에 걸리는 시간(초)';

  @override
  String get chartLegend_rock => '암암';

  @override
  String get chartLegend_rockHint => '항상 물에 잠겨 있지만 얕을 수 있음';

  @override
  String get chartLegend_rockAwash => '세암';

  @override
  String get chartLegend_rockAwashHint => '저조 때 수면 가까이 있음';

  @override
  String get chartLegend_rockCovers => '간출암';

  @override
  String get chartLegend_rockCoversHint => '저조 때 드러나고 고조 때 잠김';

  @override
  String get chartLegend_wreckDangerous => '위험 침선';

  @override
  String get chartLegend_wreckDangerousHint => '배가 부딪힐 만큼 얕음';

  @override
  String get chartLegend_wreck => '침선';

  @override
  String get chartLegend_wreckHint => '수면의 배에는 충분히 깊음, 닻을 내리지 말 것';

  @override
  String get chartLegend_wreckShowing => '일부 노출 침선';

  @override
  String get chartLegend_wreckShowingHint => '일부가 물 위로 드러나 있음';

  @override
  String get chartLegend_obstruction => '장애물';

  @override
  String get chartLegend_obstructionHint => '해저에 있는 물체, 알려진 경우 수심 표시';

  @override
  String get chartLegend_foulGround => '험악지';

  @override
  String get chartLegend_foulGroundHint => '지나가는 것은 안전하지만 닻을 내리거나 저인망을 끌지 말 것';

  @override
  String get chartLegend_hazardArea => '위험 구역 경계';

  @override
  String get chartLegend_hazardAreaHint => '안쪽에 암초, 침선 또는 장애물이 있음';

  @override
  String get chartLegend_pile => '말뚝';

  @override
  String get chartLegend_floodStream => '창조류';

  @override
  String get chartLegend_floodStreamHint => '밀물 때의 조류';

  @override
  String get chartLegend_ebbStream => '낙조류';

  @override
  String get chartLegend_ebbStreamHint => '썰물 때의 조류';

  @override
  String get chartLegend_current => '해류';

  @override
  String get chartLegend_currentHint => '조석과 관계없이 같은 방향으로 흐름';

  @override
  String get chartLegend_rips => '급조 또는 소용돌이';

  @override
  String get chartLegend_ripsHint => '거칠게 소용돌이치는 물';

  @override
  String get chartLegend_breakers => '쇄파';

  @override
  String get chartLegend_breakersHint => '얕은 곳에서 부서지는 파도';

  @override
  String get chartLegend_sounding => '수심';

  @override
  String get chartLegend_soundingHint => '평균 저조 때의 수심';

  @override
  String get chartLegend_depthContour => '등심선';

  @override
  String get chartLegend_depthContourHint => '라벨이 수심을 나타냄';

  @override
  String get chartLegend_drying => '저조 때 드러남';

  @override
  String get chartLegend_dredged => '준설 수로';

  @override
  String get chartLegend_dredgedHint => '표시된 수심으로 유지됨';

  @override
  String get chartLegend_swept => '소해 구역';

  @override
  String get chartLegend_sweptHint => '표시된 수심까지 장애물이 없음을 확인함';

  @override
  String get chartLegend_unsurveyed => '미측량';

  @override
  String get chartLegend_unsurveyedHint => '측정된 수심 없음';

  @override
  String get chartLegend_weed => '해초';

  @override
  String get chartLegend_restricted => '제한 구역';

  @override
  String get chartLegend_restrictedHint => '진입 제한, 짧은 선이 안쪽을 가리킴';

  @override
  String get chartLegend_regulatedLimit => '규제 구역 경계';

  @override
  String get chartLegend_regulatedLimitHint => '묘박지, 케이블 구역, 사격 구역 등: 라벨 참고';

  @override
  String get chartLegend_greyLimit => '토사 투기장, 어장 또는 양식장';

  @override
  String get chartLegend_anchorage => '묘박지';

  @override
  String get chartLegend_anchorBerth => '묘박 위치';

  @override
  String get chartLegend_noAnchoring => '묘박 금지';

  @override
  String get chartLegend_caution => '주의 구역';

  @override
  String get chartLegend_cautionHint => '이곳에서는 특히 주의';

  @override
  String get chartLegend_trafficLane => '통항로';

  @override
  String get chartLegend_trafficLaneHint => '대형 선박 일방통행: 직각으로 횡단';

  @override
  String get chartLegend_separationZone => '분리대';

  @override
  String get chartLegend_separationZoneHint => '통항로 사이: 들어가지 말 것';

  @override
  String get chartLegend_precautionary => '경계 구역';

  @override
  String get chartLegend_precautionaryHint => '선박이 모이는 곳: 주의';

  @override
  String get chartLegend_fairway => '항로';

  @override
  String get chartLegend_fairwayHint => '주요 수로';

  @override
  String get chartLegend_track => '추천 항로';

  @override
  String get chartLegend_ferry => '페리 항로';

  @override
  String get chartLegend_leadingLine => '중시선';

  @override
  String get chartLegend_leadingLineHint => '두 표지를 일직선으로 맞추면 수로를 벗어나지 않음';

  @override
  String get chartLegend_cable => '해저 케이블';

  @override
  String get chartLegend_cableHint => '닻을 내리지 말 것';

  @override
  String get chartLegend_pipeline => '해저 파이프라인';

  @override
  String get chartLegend_pipelineHint => '닻을 내리지 말 것';

  @override
  String get chartLegend_overhead => '가공 케이블';

  @override
  String get chartLegend_overheadHint => '아래 통과 높이는 VC로 표시';

  @override
  String get chartLegend_tower => '탑';

  @override
  String get chartLegend_windTurbine => '풍력 발전기';

  @override
  String get chartLegend_chimney => '굴뚝';

  @override
  String get chartLegend_mast => '마스트 또는 안테나';

  @override
  String get chartLegend_church => '교회 또는 첨탑';

  @override
  String get chartLegend_flagstaff => '깃대';

  @override
  String get chartLegend_dome => '돔';

  @override
  String get chartLegend_landmark => '기타 목표물';

  @override
  String get chartLegend_abbrAnch => '묘박지';

  @override
  String get chartLegend_abbrWk => '침선';

  @override
  String get chartLegend_abbrBr => '쇄파';

  @override
  String get chartLegend_abbrWd => '해초';

  @override
  String get chartLegend_abbrVar => '자기 편차';

  @override
  String get chartLegend_abbrVc => '다리나 케이블 아래의 통과 높이';

  @override
  String get chartLegend_abbrTr => '탑';

  @override
  String get chartLegend_abbrCh => '교회';

  @override
  String get chartLegend_abbrChy => '굴뚝';

  @override
  String get chartLegend_abbrFs => '깃대';

  @override
  String get chartLegend_abbrTk => '탱크';

  @override
  String get chartLegend_abbrRBn => '무선 표지';

  @override
  String get chartLegend_abbrCg => '해안경비대 기지';

  @override
  String get chartLegend_abbrRacon => '레이더 비컨: 레이더에 표시됨';

  @override
  String get chartLegend_abbrFog => '무중 신호: 경적, 종, 징, 호각 또는 사이렌';

  @override
  String get chartLegend_abbrVAis => '가상 항로표지: AIS에서만 표시';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from~$to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return '$depth보다 깊음';
  }

  @override
  String get parkLegend_title => '공원·탐방로 기호';

  @override
  String get parkLegend_campsite => '야영장';

  @override
  String get parkLegend_picnicSite => '피크닉 장소';

  @override
  String get parkLegend_shelter => '대피소';

  @override
  String get parkLegend_toilets => '화장실';

  @override
  String get parkLegend_drinkingWater => '식수';

  @override
  String get parkLegend_parking => '주차장';

  @override
  String get parkLegend_viewpoint => '전망대';

  @override
  String get parkLegend_attraction => '명소';

  @override
  String get parkLegend_gate => '출입문';

  @override
  String get parkLegend_telephone => '전화';

  @override
  String get parkLegend_information => '안내판';

  @override
  String get parkLegend_guidepost => '이정표';

  @override
  String get dialog_noticeExpires => 'Expires';

  @override
  String get dialog_noticeNoExpiry => 'Never';

  @override
  String get dialog_noticeExpiryRequired => 'Pick a date (required in a room)';

  @override
  String get dialog_noticeExpiryTime => 'Time';

  @override
  String get dialog_noticeEndOfDay => 'End of day';

  @override
  String structured_until(String when) {
    return 'Until $when';
  }

  @override
  String get structured_expired => 'Expired';

  @override
  String get structured_announcement => 'Announcement';

  @override
  String structured_locationOf(String name) {
    return '$name\'s location';
  }

  @override
  String get reaction_searchHint => 'Search emoji';

  @override
  String get reaction_noResults => 'No emoji found';
}
