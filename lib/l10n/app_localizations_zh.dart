// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => '聊天';

  @override
  String get chats_title => '聊天';

  @override
  String get newChat_title => '选择联系人';

  @override
  String newChat_contactCount(int count) {
    return '$count 个联系人';
  }

  @override
  String get newChat_newContact => '新建联系人';

  @override
  String get newChat_newChannel => '新建频道';

  @override
  String get newChat_myContacts => '我的联系人';

  @override
  String get newChat_discovered => '已发现';

  @override
  String get repeaters_title => '管理转发节点';

  @override
  String get nav_contacts => '联系人';

  @override
  String get nav_channels => '频道';

  @override
  String get nav_map => '地图';

  @override
  String get common_cancel => '取消';

  @override
  String get common_syncing_device_info => '正在读取设备信息...';

  @override
  String get common_syncing_contacts => '正在读取联系人...';

  @override
  String get common_syncing_channels => '正在读取频道...';

  @override
  String get common_syncing_messages => '正在读取消息...';

  @override
  String get common_ok => '确定';

  @override
  String get common_connect => '连接';

  @override
  String get common_unknownDevice => '未知设备';

  @override
  String get common_save => '保存';

  @override
  String get common_delete => '删除';

  @override
  String get common_deleteAll => '删除全部';

  @override
  String get common_close => '关闭';

  @override
  String get common_edit => '编辑';

  @override
  String get common_add => '添加';

  @override
  String get common_settings => '设置';

  @override
  String get common_disconnect => '断开';

  @override
  String get common_connected => '已连接';

  @override
  String get common_disconnected => '已断开';

  @override
  String get common_connectionLost => '连接已断开。正在重新连接...';

  @override
  String get common_reconnecting => '正在重新连接...';

  @override
  String get common_create => '创建';

  @override
  String get common_continue => '继续';

  @override
  String get common_share => '分享';

  @override
  String get common_copy => '复制';

  @override
  String get common_retry => '重试';

  @override
  String get common_hide => '隐藏';

  @override
  String get common_remove => '移除';

  @override
  String get common_enable => '启用';

  @override
  String get common_disable => '禁用';

  @override
  String get common_reboot => '重启';

  @override
  String get common_loading => '正在加载...';

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
  String get scanner_title => '连接设备';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => '蓝牙';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => '通过 TCP 连接';

  @override
  String get tcpHostLabel => 'IP地址';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => '端口';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => '输入目标地址，然后连接';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return '连接到 $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => '需要提供IP地址。';

  @override
  String get tcpErrorPortInvalid => '端口号必须在 1 到 65535 之间。';

  @override
  String get tcpErrorUnsupported => '此平台不支持 TCP 传输。';

  @override
  String get tcpErrorTimedOut => 'TCP 连接超时。';

  @override
  String tcpConnectionFailed(String error) {
    return 'TCP 连接失败：$error';
  }

  @override
  String get usbScreenTitle => '通过USB连接';

  @override
  String get usbScreenSubtitle => '选择已检测到的串行设备，并直接连接到您的 MeshCore 节点。';

  @override
  String get usbScreenStatus => '选择一个 USB 设备';

  @override
  String get usbScreenNote => 'USB 串行接口在支持的 Android 设备和桌面平台上处于活动状态。';

  @override
  String get usbScreenEmptyState => '未找到任何 USB 设备。请插入一个，然后刷新。';

  @override
  String get usbErrorPermissionDenied => '拒绝了USB权限。';

  @override
  String get usbErrorDeviceMissing => '所选的USB设备已不再可用。';

  @override
  String get usbErrorInvalidPort => '选择一个有效的USB设备。';

  @override
  String get usbErrorBusy => '还有一个 USB 连接请求正在进行中。';

  @override
  String get usbErrorNotConnected => '没有连接任何USB设备。';

  @override
  String get usbErrorOpenFailed => '未能打开所选的USB设备。';

  @override
  String get usbErrorConnectFailed => '未能连接到所选的USB设备。';

  @override
  String get usbErrorUnsupported => '此平台不支持USB串行通信。';

  @override
  String get usbErrorNativeLibraryMissing =>
      '此版本缺少 USB 串口库，无法打开 USB 设备。请重新安装 MeshTrax，或报告此版本有问题。';

  @override
  String get usbErrorBrowserUnsupported =>
      '此浏览器不支持 Web Serial。请通过 HTTPS（或 localhost）使用 Chrome 或 Edge。';

  @override
  String get usbErrorAlreadyActive => 'USB 连接已建立。';

  @override
  String get usbErrorNoDeviceSelected => '未选择任何 USB 设备。';

  @override
  String get usbErrorPortClosed => 'USB 连接未建立。';

  @override
  String get usbErrorConnectTimedOut => '连接超时。请确保设备已安装 USB 伴侣固件。';

  @override
  String get usbFallbackDeviceName => 'Web 串流设备';

  @override
  String get usbStatus_notConnected => '选择一个 USB 设备';

  @override
  String get usbStatus_connecting => '连接USB设备...';

  @override
  String get usbStatus_searching => '正在搜索 USB 设备...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB 连接失败：$error';
  }

  @override
  String get scanner_scanning => '正在搜索设备...';

  @override
  String get scanner_connecting => '正在连接...';

  @override
  String get scanner_disconnecting => '断开连接...';

  @override
  String get scanner_notConnected => '未连接';

  @override
  String scanner_connectedTo(String deviceName) {
    return '已连接到 $deviceName';
  }

  @override
  String get scanner_showAllDevices => '显示所有蓝牙设备';

  @override
  String get scanner_showMeshCoreOnly => '仅显示 MeshCore 电台';

  @override
  String get scanner_radioNotResponding =>
      '电台没有响应。可能需要先配对：打开蓝牙设置，添加该电台并输入其 PIN，然后重试。';

  @override
  String get scanner_pairingFailed =>
      '蓝牙配对已取消或失败。请确保没有其他设备（例如您的手机）连接着该电台，然后重试并输入其 PIN。';

  @override
  String scanner_connectionFailed(String error) {
    return '连接失败：$error';
  }

  @override
  String get scanner_stop => '停止';

  @override
  String get scanner_scan => '扫描';

  @override
  String get scanner_scanFromImage => '从图片扫描';

  @override
  String get scanner_noQrFoundInImage => '图片中未找到有效的二维码';

  @override
  String get scanner_bluetoothOff => '蓝牙已关闭';

  @override
  String get scanner_bluetoothOffMessage => '请开启蓝牙以搜索设备';

  @override
  String get scanner_chromeRequired => '需要 Chrome 浏览器';

  @override
  String get scanner_chromeRequiredMessage =>
      '此 Web 应用程序需要 Google Chrome 或基于 Chromium 的浏览器以支持蓝牙。';

  @override
  String get scanner_enableBluetooth => '启用蓝牙';

  @override
  String get device_quickSwitch => '快速切换';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => '设置';

  @override
  String get settings_deviceInfo => '设备信息';

  @override
  String get settings_appSettings => '应用设置';

  @override
  String get settings_appSettingsSubtitle => '通知、消息和地图偏好';

  @override
  String get settings_nodeSettings => '节点设置';

  @override
  String get settings_nodeName => '节点名称';

  @override
  String get settings_nodeNameNotSet => '未设置';

  @override
  String get settings_nodeNameHint => '请输入节点名称';

  @override
  String get settings_nodeNameUpdated => '节点名称已更新';

  @override
  String get settings_radioSettings => '无线电设置';

  @override
  String get settings_radioSettingsSubtitle => '频率、功率、扩频因子';

  @override
  String get settings_radioSettingsUpdated => '无线电设置已更新';

  @override
  String get settings_location => '位置';

  @override
  String get settings_locationSubtitle => 'GPS 坐标';

  @override
  String get settings_locationUpdated => '位置和 GPS 设置已更新';

  @override
  String get settings_locationBothRequired => '请输入经度和纬度';

  @override
  String get settings_locationInvalid => '无效的经度和纬度';

  @override
  String get settings_locationGPSEnable => '启用 GPS';

  @override
  String get settings_locationGPSEnableSubtitle => '启用 GPS 以自动更新位置。';

  @override
  String get settings_latitude => '纬度';

  @override
  String get settings_longitude => '经度';

  @override
  String get settings_contactSettings => '联系人设置';

  @override
  String get settings_contactSettingsSubtitle => '添加联系人的设置';

  @override
  String get settings_privacyMode => '隐私模式';

  @override
  String get settings_privacyModeSubtitle => '在广告中隐藏姓名/位置';

  @override
  String get settings_privacyModeToggle => '切换隐私模式以在广告中隐藏姓名和位置，保护个人信息。';

  @override
  String get settings_privacyModeEnabled => '隐私模式已启用';

  @override
  String get settings_privacyModeDisabled => '隐私模式已关闭';

  @override
  String get settings_privacy => '隐私设置';

  @override
  String get settings_privacySubtitle => '控制要共享的信息。';

  @override
  String get settings_privacySettingsDescription => '选择您的设备与他人共享的信息。';

  @override
  String get settings_denyAll => '拒绝所有';

  @override
  String get settings_allowByContact => '按联系人标志允许';

  @override
  String get settings_allowAll => '允许全部';

  @override
  String get settings_telemetryBaseMode => '遥测基础模式';

  @override
  String get settings_telemetryLocationMode => '遥测位置模式';

  @override
  String get settings_telemetryEnvironmentMode => '遥测环境模式';

  @override
  String get settings_advertLocation => '广告位置';

  @override
  String get settings_advertLocationSubtitle => '在广告中包含位置';

  @override
  String get settings_multiAck => '多重ACK';

  @override
  String get settings_telemetryModeUpdated => '遥测模式已更新';

  @override
  String get settings_actions => '操作';

  @override
  String get settings_sendAdvertisement => '发送广播';

  @override
  String get settings_sendAdvertisementSubtitle => '立即发送广播';

  @override
  String get settings_advertisementSent => '已发送广播';

  @override
  String get settings_syncTime => '同步时间';

  @override
  String get settings_syncTimeSubtitle => '将设备时钟设置为与手机时间一致';

  @override
  String get settings_timeSynchronized => '时间已同步';

  @override
  String get settings_refreshContacts => '刷新联系人';

  @override
  String get settings_refreshContactsSubtitle => '从设备重新加载联系人列表';

  @override
  String get settings_rebootDevice => '重启设备';

  @override
  String get settings_rebootDeviceSubtitle => '重启 MeshCore 设备';

  @override
  String get settings_rebootDeviceConfirm => '确定要重启设备吗？这将断开与设备的连接。';

  @override
  String get settings_debug => '调试';

  @override
  String get settings_bleDebugLog => 'BLE 调试日志';

  @override
  String get settings_bleDebugLogSubtitle => 'BLE 命令、响应和原始数据';

  @override
  String get settings_appDebugLog => '应用调试日志';

  @override
  String get settings_appDebugLogSubtitle => '应用调试消息';

  @override
  String get settings_exportDatabase => '导出消息数据库';

  @override
  String get settings_exportDatabaseSubtitle => '所有聊天和联系人的副本，用于调试。请勿外传。';

  @override
  String settings_exportDatabaseSaved(String path) {
    return '数据库已保存到：$path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return '导出失败：$error';
  }

  @override
  String get settings_about => '关于';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshCore 开源项目';

  @override
  String get settings_aboutDescription =>
      '一个开源的 Flutter 客户端，用于 MeshCore LoRa 无线网络设备。';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS 高程数据:Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => '名称';

  @override
  String get settings_infoId => 'MAC ID';

  @override
  String get settings_infoStatus => '状态';

  @override
  String get settings_infoBattery => '电池';

  @override
  String get settings_infoPublicKey => '公钥';

  @override
  String get settings_infoContactsCount => '联系人数量';

  @override
  String get settings_infoChannelCount => '频道数量';

  @override
  String get settings_presets => '预设';

  @override
  String get settings_frequency => '频率 (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => '无效频率范围（300-2500 MHz）';

  @override
  String get settings_bandwidth => '带宽';

  @override
  String get settings_spreadingFactor => '扩频因子';

  @override
  String get settings_codingRate => '编码速率';

  @override
  String get settings_txPower => 'TX 功率 (dBm)';

  @override
  String get settings_txPowerInvalid => '无效的发射功率';

  @override
  String get settings_clientRepeat => '离网重复';

  @override
  String get settings_clientRepeatSubtitle => '允许此设备重复发送网状数据包给其他设备';

  @override
  String get settings_clientRepeatFreqWarning =>
      '离网重复通信需要使用 433、869 或 918 兆赫兹的频率。';

  @override
  String settings_error(String message) {
    return '错误：$message';
  }

  @override
  String get appSettings_title => '应用设置';

  @override
  String get appSettings_appearance => '外观';

  @override
  String get appSettings_theme => '主题';

  @override
  String get appSettings_themeSystem => '跟随系统';

  @override
  String get appSettings_themeLight => '浅色';

  @override
  String get appSettings_themeDark => '深色';

  @override
  String get appSettings_language => '语言';

  @override
  String get appSettings_languageSystem => '跟随系统';

  @override
  String get appSettings_languageEn => '英语';

  @override
  String get appSettings_languageFr => '法语';

  @override
  String get appSettings_languageEs => '西班牙语';

  @override
  String get appSettings_languageDe => '德语';

  @override
  String get appSettings_languagePl => '波兰语';

  @override
  String get appSettings_languageSl => '斯洛文尼亚语';

  @override
  String get appSettings_languagePt => '葡萄牙语';

  @override
  String get appSettings_languageIt => '意大利语';

  @override
  String get appSettings_languageZh => '中文';

  @override
  String get appSettings_languageSv => '瑞典语';

  @override
  String get appSettings_languageNl => '荷兰语';

  @override
  String get appSettings_languageSk => '斯洛伐克语';

  @override
  String get appSettings_languageBg => '保加利亚语';

  @override
  String get appSettings_languageRu => '俄语';

  @override
  String get appSettings_languageUk => '乌克兰语';

  @override
  String get appSettings_enableMessageTracing => '启用消息追踪';

  @override
  String get appSettings_enableMessageTracingSubtitle => '显示消息的详细路由和时间元数据';

  @override
  String get appSettings_senderNameColors => '彩色发送者名称';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      '为每位频道发送者分配各自的名称颜色。关闭后所有人都使用主题颜色。';

  @override
  String get appSettings_showTextFormatting => '显示文本格式';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      '消息中的 Markdown：**粗体**、*斜体*、||剧透||、标题和链接。其他 MeshCore 应用会显示原始字符。';

  @override
  String get appSettings_notifications => '通知';

  @override
  String get appSettings_enableNotifications => '启用通知';

  @override
  String get appSettings_enableNotificationsSubtitle => '接收消息和广播的通知';

  @override
  String get appSettings_notificationPermissionDenied => '权限被拒绝';

  @override
  String get appSettings_notificationsEnabled => '通知已启用';

  @override
  String get appSettings_notificationsDisabled => '通知已关闭';

  @override
  String get appSettings_messageNotifications => '消息通知';

  @override
  String get appSettings_messageNotificationsSubtitle => '收到新消息时显示通知';

  @override
  String get appSettings_channelMessageNotifications => '频道消息通知';

  @override
  String get appSettings_channelMessageNotificationsSubtitle => '收到频道消息时显示通知';

  @override
  String get appSettings_advertisementNotifications => '广播通知';

  @override
  String get appSettings_advertisementNotificationsSubtitle => '发现新节点时显示通知';

  @override
  String get appSettings_messaging => '消息';

  @override
  String get appSettings_maxMessageRetries => '最大消息重试次数';

  @override
  String get appSettings_maxMessageRetriesSubtitle => '在将消息标记为失败之前，允许尝试的次数';

  @override
  String get appSettings_maxChannelMessageRetries => '频道消息最大重试次数';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      '在听到至少一次转发之前，最多重试这么多次';

  @override
  String get appSettings_battery => '电池';

  @override
  String get appSettings_batteryChemistry => '电池类型';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return '为每个设备设置 ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst => '请先连接设备';

  @override
  String get appSettings_batteryNmc => '18650 NMC 电池 (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => '磷酸铁锂 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => '锂聚合物电池 (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => '地图显示';

  @override
  String get appSettings_showRepeaters => '显示转发节点';

  @override
  String get appSettings_showRepeatersSubtitle => '在地图上显示转发节点';

  @override
  String get appSettings_showChatNodes => '显示聊天节点';

  @override
  String get appSettings_showChatNodesSubtitle => '在地图上显示聊天节点';

  @override
  String get appSettings_showOtherNodes => '显示其他节点';

  @override
  String get appSettings_showOtherNodesSubtitle => '在地图上显示其他节点类型';

  @override
  String get appSettings_timeFilter => '时间过滤器';

  @override
  String get appSettings_timeFilterShowAll => '显示所有节点';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return '显示过去 $hours 小时内的节点';
  }

  @override
  String get appSettings_mapTimeFilter => '地图时间筛选';

  @override
  String get appSettings_showNodesDiscoveredWithin => '显示在此时间段内发现的节点：';

  @override
  String get appSettings_allTime => '所有时间';

  @override
  String get appSettings_lastHour => '过去一小时';

  @override
  String get appSettings_last6Hours => '过去6小时';

  @override
  String get appSettings_last24Hours => '过去24小时';

  @override
  String get appSettings_lastWeek => '上周';

  @override
  String get appSettings_unitsTitle => '单位';

  @override
  String get appSettings_unitsMetric => '公制（米/公里）';

  @override
  String get appSettings_unitsImperial => '英制 (ft / mi)';

  @override
  String get appSettings_debugCard => '调试';

  @override
  String get appSettings_appDebugLogging => '应用调试日志';

  @override
  String get appSettings_appDebugLoggingSubtitle => '记录应用调试消息以进行故障排除。';

  @override
  String get appSettings_appDebugLoggingEnabled => '调试日志已启用';

  @override
  String get appSettings_appDebugLoggingDisabled => '应用调试日志已禁用';

  @override
  String get appSettings_incrementalContactSync => '增量同步联系人';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      '重新连接时，只向电台请求自上次以来有变化的联系人';

  @override
  String get contacts_title => '联系人';

  @override
  String get contacts_noContacts => '暂无联系人';

  @override
  String get contacts_shareMyQrCode => '分享我的二维码';

  @override
  String get contacts_shareQrCodeDesc => '让他人扫描以将您添加为联系人';

  @override
  String get contacts_contactsWillAppear => '当设备发送广播时，联系人将显示。';

  @override
  String get contacts_unread => '未读';

  @override
  String get contacts_searchContactsNoNumber => '搜索联系人...';

  @override
  String contacts_searchContacts(int number, String str) {
    return '搜索联系人...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return '搜索 $number$str 收藏...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return '搜索 $number$str 位用户...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return '搜索 $number$str 重复器...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return '搜索 $number$str 房间服务器...';
  }

  @override
  String get contacts_noUnreadContacts => '没有未读内容';

  @override
  String get contacts_noContactsFound => '未找到任何联系人或群聊';

  @override
  String get contacts_deleteContact => '删除联系人';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return '确定要删除 $contactName 吗？';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return '已删除联系人 $contactName。';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return '删除 $contactName 失败。';
  }

  @override
  String get contacts_noMatchingContacts => '没有符合筛选条件的联系人。';

  @override
  String contacts_removeConfirm(String contactName) {
    return '从联系人中移除 $contactName？';
  }

  @override
  String get contacts_manageRepeater => '管理转发节点';

  @override
  String get contacts_manageRoom => '管理房间服务器';

  @override
  String get contacts_roomLogin => '服务器登录';

  @override
  String get contacts_openChat => '打开聊天';

  @override
  String get contacts_editGroup => '编辑群聊';

  @override
  String get contacts_deleteGroup => '删除群聊';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return '删除群聊 \"$groupName\"？';
  }

  @override
  String get contacts_newGroup => '新建群聊';

  @override
  String get contacts_groupName => '群聊名称';

  @override
  String get contacts_groupNameRequired => '请输入群聊名称';

  @override
  String get contacts_groupNameReserved => '该群组名称已被保留';

  @override
  String contacts_groupAlreadyExists(String name) {
    return '名为 \"$name\" 的群聊已存在';
  }

  @override
  String get contacts_filterContacts => '筛选联系人...';

  @override
  String get contacts_noContactsMatchFilter => '没有符合条件的联系人';

  @override
  String get contacts_noMembers => '暂无成员';

  @override
  String get contacts_lastSeenNow => '刚刚';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '最后在线 $minutes 分钟前';
  }

  @override
  String get contacts_lastSeenHourAgo => '最后在线 1小时前';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '最后在线 $hours 小时前';
  }

  @override
  String get contacts_lastSeenDayAgo => '最后在线 1天前';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '最后在线 $days 天前';
  }

  @override
  String get contact_info => '联系信息';

  @override
  String get contact_settings => '联系人设置';

  @override
  String get contact_telemetry => '遥测数据';

  @override
  String get contact_lastSeen => '最近出现';

  @override
  String get contact_clearChat => '清除聊天记录';

  @override
  String get contact_teleBase => '遥测基站';

  @override
  String get contact_teleBaseSubtitle => '允许共享电池电量和基本遥测数据';

  @override
  String get contact_teleLoc => '遥测位置';

  @override
  String get contact_teleLocSubtitle => '允许共享位置数据';

  @override
  String get contact_teleEnv => '遥测环境';

  @override
  String get contact_teleEnvSubtitle => '允许共享环境传感器数据';

  @override
  String get contacts_publicKey => '公钥';

  @override
  String get channels_title => '频道';

  @override
  String get channels_noChannelsConfigured => '未配置任何频道';

  @override
  String get channels_addPublicChannel => '添加公共频道';

  @override
  String get channels_searchChannels => '搜索频道...';

  @override
  String get channels_noChannelsFound => '未找到任何频道';

  @override
  String channels_channelIndex(int index) {
    return '频道 $index';
  }

  @override
  String get channels_hashtagChannel => '标签频道';

  @override
  String get channels_public => '公共';

  @override
  String get channels_private => '私有';

  @override
  String get channels_publicChannel => '公共频道';

  @override
  String get channels_privateChannel => '私有频道';

  @override
  String get channels_editChannel => '编辑频道';

  @override
  String get channels_shareChannel => '分享频道';

  @override
  String get channels_shareChannelInstructions =>
      '扫描二维码以添加频道。\n菜单 → 添加频道 → 扫描二维码';

  @override
  String get channels_secretKey => '密钥';

  @override
  String get channels_meshcoreUri => 'MeshCore URI';

  @override
  String get channels_shareChannelQr => '扫描频道二维码';

  @override
  String get channels_shareChannelWarning => '警告：任何扫描此二维码的人都能访问此频道。';

  @override
  String get channels_muteChannel => '静音频道';

  @override
  String get channels_unmuteChannel => '取消静音频道';

  @override
  String get channels_deleteChannel => '删除频道';

  @override
  String channels_deleteChannelConfirm(String name) {
    return '删除频道 \"$name\"？此操作不可撤销。';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return '无法删除频道 \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return '已删除频道 \"$name\"';
  }

  @override
  String get channels_addChannel => '添加频道';

  @override
  String get channels_channelIndexLabel => '频道索引';

  @override
  String get channels_channelName => '频道名称';

  @override
  String get channels_usePublicChannel => '使用公共频道';

  @override
  String get channels_standardPublicPsk => '标准公共 PSK';

  @override
  String get channels_pskHex => 'PSK (十六进制)';

  @override
  String get channels_generateRandomPsk => '生成随机 PSK';

  @override
  String get channels_enterChannelName => '请输入频道名称';

  @override
  String get channels_pskMustBe32Hex => 'PSK 必须为 32 个十六进制字符';

  @override
  String get channels_addChannelConfirmation => '是否添加以下频道？';

  @override
  String get channels_channelAddedSuccess => '频道添加成功。';

  @override
  String get channels_noAvailableChannelSlots => '没有可用的频道槽位。';

  @override
  String get appSettings_mentionNotifications => '提及通知';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      '有人提及或回复您时 — 即使在已静音的频道中';

  @override
  String notification_mentionIn(String channelName) {
    return '在 $channelName 中被提及';
  }

  @override
  String channels_channelAdded(String name) {
    return '已添加频道 \"$name\"';
  }

  @override
  String channels_editChannelTitle(int index) {
    return '编辑频道 $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ 压缩';

  @override
  String channels_channelUpdated(String name) {
    return '频道 \"$name\" 已更新';
  }

  @override
  String get channels_publicChannelAdded => '已添加公共频道';

  @override
  String get channels_sortBy => '排序方式';

  @override
  String get channels_sortManual => '手动';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => '最新消息';

  @override
  String get channels_sortUnread => '未读';

  @override
  String get channels_createPrivateChannel => '创建私有频道';

  @override
  String get channels_createPrivateChannelDesc => '使用密钥保护。';

  @override
  String get channels_joinPrivateChannel => '加入私有频道';

  @override
  String get channels_joinPrivateChannelDesc => '手动输入密钥。';

  @override
  String get channels_joinPublicChannel => '加入公共频道';

  @override
  String get channels_joinPublicChannelDesc => '任何人都可以加入。';

  @override
  String get channels_joinHashtagChannel => '加入标签频道';

  @override
  String get channels_joinHashtagChannelDesc => '任何人都可以加入标签频道。';

  @override
  String get channels_scanQrCode => '扫描二维码';

  @override
  String get channels_scanQrCodeComingSoon => '即将推出';

  @override
  String get channels_enterHashtag => '输入标签';

  @override
  String get channels_hashtagHint => '例如：#团队';

  @override
  String get chat_noMessages => '暂无消息';

  @override
  String get chat_sendMessage => '发送消息';

  @override
  String chat_sendMessageTo(String contactName) {
    return '发送消息给 $contactName';
  }

  @override
  String get chat_sendMessageToStart => '发送消息开始对话';

  @override
  String get chat_originalMessageNotFound => '找不到原始消息';

  @override
  String chat_replyingTo(String name) {
    return '正在回复 $name';
  }

  @override
  String chat_replyTo(String name) {
    return '回复 $name';
  }

  @override
  String get chat_location => '位置';

  @override
  String get common_copiedToClipboard => '已复制到剪贴板';

  @override
  String get common_copyToClipboard => '复制到剪贴板';

  @override
  String get contacts_copyContactToClipboard => '复制我的联系人到剪贴板';

  @override
  String get chat_typeMessage => '输入消息...';

  @override
  String get chat_searchMessages => '搜索消息';

  @override
  String get chat_searchNoMatches => '无匹配项';

  @override
  String chat_messageTooLong(int maxBytes) {
    return '消息过长（最多 $maxBytes 字节）';
  }

  @override
  String get chat_messageCopied => '消息已复制';

  @override
  String get chat_messageDeleted => '消息已删除';

  @override
  String get chat_sendGif => '发送 GIF';

  @override
  String get chat_reply => '回复';

  @override
  String get chat_newMessages => '新消息';

  @override
  String get chat_addReaction => '添加表情';

  @override
  String get chat_mention => '提及';

  @override
  String get dmChannel_menuLabel => '私信';

  @override
  String dmChannel_pickerTitle(String name) {
    return '给 $name 发私信';
  }

  @override
  String get dmChannel_pickerHint => '请核对公钥和最后出现时间 — 名称可能重复。';

  @override
  String get dmChannel_warningTitle => '真的是对方吗？';

  @override
  String get dmChannel_warningBody =>
      '频道中的名称是自己取的，任何人都可以冒充。涉及敏感内容时，请先通过其他方式核实此联系人的公钥。';

  @override
  String get dmChannel_dontShowAgain => '不再显示';

  @override
  String get batterySleep_title => '保持 MeshTrax 运行';

  @override
  String get batterySleep_bodySamsung =>
      '三星手机会让应用休眠以节省电量，这会切断与电台的连接。请打开 设置 → 应用程序 → MeshTrax → 电池，选择“不受限制”。另请在 电池 → 后台使用限制 中确认 MeshTrax 不在“休眠应用程序”或“深度休眠应用程序”中。';

  @override
  String get batterySleep_bodyGeneric =>
      '手机可能会为节省电量在后台停止 MeshTrax，这会切断与电台的连接。请打开电池设置，将 MeshTrax 设为“不受限制”（或“无限制”）。部分手机还需要为 MeshTrax 开启“自启动”。';

  @override
  String get batterySleep_openSettings => '打开设置';

  @override
  String get batterySleep_notNow => '以后再说';

  @override
  String get batterySleep_settingsTile => '让 MeshTrax 在后台保持运行';

  @override
  String get batterySleep_settingsTileSubtitle => '防止手机的省电功能让 MeshTrax 休眠';

  @override
  String dmChannel_noMatchTitle(String name) {
    return '暂时无法给 $name 发私信';
  }

  @override
  String get dmChannel_noMatchBody =>
      '您还没有对方的密钥，对方也需要您的密钥才能回复 — 密钥只通过广播传递。“发送我的广播”会在这里直接广播您的密钥。“在频道中请求”会在消息框中写好一条请求，由您发送。';

  @override
  String get dmChannel_askInChannel => '在频道中请求';

  @override
  String get dmChannel_sendMyAdvert => '发送我的广播';

  @override
  String get dmChannel_askText => '请发一次广播，方便我给你发私信';

  @override
  String get dmChannel_watching => '正在等待对方的广播 — 收到后会在这里提示您。';

  @override
  String dmChannel_advertHeard(String name) {
    return '现在可以联系 $name 了';
  }

  @override
  String get dmChannel_openDm => '私信';

  @override
  String get appSettings_zoomLevel => '缩放级别';

  @override
  String get common_reset => '重置';

  @override
  String get chat_reactionsTitle => '表情回应';

  @override
  String get chat_reactionUnknownSender => '未知';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender 回应了一条不在此聊天中的消息';
  }

  @override
  String get chat_me => '我';

  @override
  String get emojiCategorySmileys => '表情';

  @override
  String get emojiCategoryGestures => '手势';

  @override
  String get emojiCategoryHearts => '爱心';

  @override
  String get emojiCategoryObjects => '物品';

  @override
  String get gifPicker_title => '选择 GIF';

  @override
  String get gifPicker_searchHint => '搜索 GIF...';

  @override
  String get gifPicker_poweredBy => '由 GIPHY 提供';

  @override
  String get gifPicker_noGifsFound => '未找到 GIF';

  @override
  String get gifPicker_failedLoad => '加载 GIF 失败';

  @override
  String get gifPicker_failedSearch => '搜索 GIF 失败';

  @override
  String get gifPicker_noInternet => '无网络连接';

  @override
  String get debugLog_appTitle => '应用调试日志';

  @override
  String get debugLog_bleTitle => 'BLE 调试日志';

  @override
  String get debugLog_copyLog => '复制日志';

  @override
  String get debugLog_saveLog => '将日志保存到文件';

  @override
  String get debugLog_saved => '日志已保存';

  @override
  String get debugLog_saveCancelled => '已取消保存';

  @override
  String get debugLog_filterAll => '全部';

  @override
  String get debugLog_filterWarnings => '警告';

  @override
  String get debugLog_filterErrors => '错误';

  @override
  String get debugLog_clearLog => '清除日志';

  @override
  String get debugLog_copied => '调试日志已复制';

  @override
  String get debugLog_bleCopied => 'BLE 日志已复制';

  @override
  String get debugLog_noEntries => '暂无调试日志';

  @override
  String get debugLog_enableInSettings => '请在设置中启用应用调试日志。';

  @override
  String get debugLog_frames => '帧';

  @override
  String get debugLog_rawLogRx => '原始日志 RX';

  @override
  String get debugLog_noBleActivity => '暂无 BLE 活动';

  @override
  String debugFrame_length(int count) {
    return '帧长度：$count 字节';
  }

  @override
  String debugFrame_command(String value) {
    return '命令：0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => '文本消息：';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- 目标公钥：$pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- 时间戳：$timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- 标志：0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- 文本类型：$type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => '命令行';

  @override
  String get debugFrame_textTypeCliCommand => 'CLI 命令';

  @override
  String get debugFrame_textTypePlain => '纯文本';

  @override
  String debugFrame_text(String text) {
    return '- 文本：“$text”';
  }

  @override
  String get debugFrame_hexDump => '十六进制数据：';

  @override
  String get chat_hopSingular => '跳';

  @override
  String get chat_hopPlural => '跳';

  @override
  String chat_hopsCount(int count) {
    return '$count 跳';
  }

  @override
  String get chat_setCustomPath => '设置自定义路径';

  @override
  String get chat_fullPath => '完整路径';

  @override
  String get chat_pathDetailsNotAvailable => '路径信息暂不可用，请尝试发送消息刷新。';

  @override
  String get chat_type => '类型';

  @override
  String get chat_path => '路径';

  @override
  String get chat_publicKey => '公钥';

  @override
  String get chat_compressOutgoingMessages => '压缩发送的消息';

  @override
  String get chat_floodForced => '泛洪（强制）';

  @override
  String get chat_directForced => '直连（强制）';

  @override
  String chat_hopsForced(int count) {
    return '$count 跳（强制）';
  }

  @override
  String get chat_floodAuto => '自动泛洪';

  @override
  String get chat_direct => '直连';

  @override
  String get chat_poiShared => '共享位置';

  @override
  String chat_unread(int count) {
    return '未读：$count';
  }

  @override
  String get chat_openLink => '打开链接？';

  @override
  String get chat_openLinkConfirmation => '是否使用浏览器打开此链接？';

  @override
  String get chat_open => '打开';

  @override
  String chat_couldNotOpenLink(String url) {
    return '无法打开链接：$url';
  }

  @override
  String get chat_invalidLink => '无效的链接格式';

  @override
  String get map_lineOfSight => '视线';

  @override
  String get map_losScreenTitle => '视线';

  @override
  String get map_noNodesWithLocation => '没有包含位置信息的节点';

  @override
  String get map_nodesNeedGps => '节点需要共享 GPS 坐标才能在地图上显示';

  @override
  String map_nodesCount(int count) {
    return '节点：$count';
  }

  @override
  String map_pinsCount(int count) {
    return '标记：$count';
  }

  @override
  String get map_chat => '聊天';

  @override
  String get map_repeater => '转发节点';

  @override
  String get map_room => '房间';

  @override
  String get map_sensor => '传感器';

  @override
  String get map_pinDm => '标记（私信）';

  @override
  String get map_pinPrivate => '私有';

  @override
  String get map_pinPublic => '公共';

  @override
  String get map_lastSeen => '最后在线';

  @override
  String get map_disconnectConfirm => '确定要断开与此设备的连接吗？';

  @override
  String get map_from => '来自';

  @override
  String get map_source => '来源';

  @override
  String get map_flags => '标志';

  @override
  String get map_shareMarkerHere => '在此分享标记';

  @override
  String get map_setAsMyLocation => '设置为我的位置';

  @override
  String get map_pinLabel => '标签';

  @override
  String get map_label => '标签';

  @override
  String get map_pointOfInterest => '兴趣点';

  @override
  String get map_sendToContact => '发送给联系人';

  @override
  String get map_sendToChannel => '发送到频道';

  @override
  String get map_noChannelsAvailable => '没有可用的频道';

  @override
  String get map_publicLocationShare => '公共位置共享';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return '您即将在 $channelLabel 上分享一个位置。此频道是公开的，任何拥有 PSK 的人都可以看到。';
  }

  @override
  String get map_connectToShareMarkers => '连接设备以共享标记';

  @override
  String get map_filterNodes => '过滤节点';

  @override
  String get map_chatNodes => '聊天节点';

  @override
  String get map_repeaters => '转发节点';

  @override
  String get map_otherNodes => '其他节点';

  @override
  String get map_showOverlaps => '重复键重叠';

  @override
  String get map_keyPrefix => '关键字前缀';

  @override
  String get map_filterByKeyPrefix => '按关键字前缀筛选';

  @override
  String get map_publicKeyPrefix => '关键字前缀';

  @override
  String get map_showDiscoveryContacts => '显示发现联系人';

  @override
  String get map_guessedLocation => '猜测的位置';

  @override
  String get map_lastSeenTime => '最后在线时间';

  @override
  String get map_sharedPin => '共享标记';

  @override
  String get map_joinRoom => '加入房间';

  @override
  String get map_manageRepeater => '管理转发节点';

  @override
  String get map_tapToAdd => '点击节点以添加到路径';

  @override
  String get map_runTrace => '运行路径追踪';

  @override
  String get map_runTraceWithReturnPath => '沿着相同的路径返回';

  @override
  String get map_removeLast => '移除最后一个';

  @override
  String get map_pathTraceCancelled => '路径追踪已取消';

  @override
  String get time_justNow => '刚才';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String time_daysAgo(int days) {
    return '$days天前';
  }

  @override
  String get time_hour => '小时';

  @override
  String get time_hours => '小时';

  @override
  String get time_day => '天';

  @override
  String get time_days => '天';

  @override
  String get time_week => '周';

  @override
  String get time_weeks => '周';

  @override
  String get time_month => '月';

  @override
  String get time_months => '月';

  @override
  String get time_minutes => '分钟';

  @override
  String get time_allTime => '所有时间';

  @override
  String get dialog_disconnect => '断开';

  @override
  String get dialog_disconnectConfirm => '确定要断开与此设备的连接吗？';

  @override
  String get login_repeaterLogin => '转发节点登录';

  @override
  String get login_roomLogin => '房间服务器登录';

  @override
  String get login_password => '密码';

  @override
  String get login_enterPassword => '请输入密码';

  @override
  String get login_savePassword => '保存密码';

  @override
  String get login_savePasswordSubtitle => '密码将安全地存储在此设备上';

  @override
  String get login_repeaterDescription => '输入转发节点密码以访问设置和状态。';

  @override
  String get login_roomDescription => '输入房间服务器密码以访问设置和状态。';

  @override
  String get login_login => '登录';

  @override
  String login_attempt(int current, int max) {
    return '尝试 $current/$max';
  }

  @override
  String login_failed(String error) {
    return '登录失败：$error';
  }

  @override
  String get login_failedMessage => '登录失败。可能是密码错误或无法连接到服务器。';

  @override
  String get common_reload => '重新加载';

  @override
  String get common_clear => '清除';

  @override
  String get path_enterCustomPath => '输入自定义路径';

  @override
  String get path_currentPathLabel => '当前路径';

  @override
  String get path_hexPrefixInstructions => '请输入每个中继节点的2字符十六进制前缀，用逗号分隔。';

  @override
  String get path_hexPrefixExample => '例如：A1, F2, 3C（每个节点使用其公钥的第一字节）';

  @override
  String get path_labelHexPrefixes => '路径（十六进制前缀）';

  @override
  String get path_helperMaxHops => '最多 64 跳。每个前缀由 2 个十六进制字符（1 字节）组成。';

  @override
  String get path_selectFromContacts => '或从联系人列表中选择：';

  @override
  String get path_noRepeatersFound => '未找到任何转发节点或房间服务器。';

  @override
  String get path_customPathsRequire => '自定义路径需要中间节点转发消息。';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return '无效的十六进制前缀：$prefixes';
  }

  @override
  String get path_tooLong => '路径过长，最多允许 64 跳。';

  @override
  String get path_setPath => '设置路径';

  @override
  String get repeater_management => '转发节点管理';

  @override
  String get room_management => '房间服务器管理';

  @override
  String get repeater_guest => '重复器信息';

  @override
  String get room_guest => '服务器信息';

  @override
  String get repeater_managementTools => '管理工具';

  @override
  String get repeater_guestTools => '访客工具';

  @override
  String get repeater_status => '状态';

  @override
  String get repeater_statusSubtitle => '查看转发节点状态、统计和邻居';

  @override
  String get repeater_telemetry => '遥测';

  @override
  String get repeater_telemetrySubtitle => '查看传感器和系统状态数据';

  @override
  String get repeater_cli => '命令行';

  @override
  String get repeater_cliSubtitle => '向转发节点发送命令';

  @override
  String get repeater_neighbors => '邻居';

  @override
  String get repeater_neighborsSubtitle => '查看邻居节点（零跳）';

  @override
  String get repeater_settings => '设置';

  @override
  String get repeater_settingsSubtitle => '配置转发节点参数';

  @override
  String get repeater_clockSyncAfterLogin => '登录后，自动同步时钟';

  @override
  String get repeater_clockSyncAfterLoginSubtitle => '在成功登录后，自动发送“时钟同步”指令。';

  @override
  String get repeater_statusTitle => '转发节点状态';

  @override
  String get repeater_refresh => '刷新';

  @override
  String get repeater_statusRequestTimeout => '状态请求超时';

  @override
  String repeater_errorLoadingStatus(String error) {
    return '加载状态时出错：$error';
  }

  @override
  String get repeater_systemInformation => '系统信息';

  @override
  String get repeater_battery => '电池';

  @override
  String get repeater_clockAtLogin => '登录时的时钟';

  @override
  String get repeater_uptime => '运行时间';

  @override
  String get repeater_queueLength => '队列长度';

  @override
  String get repeater_debugFlags => '调试标志';

  @override
  String get repeater_radioStatistics => '无线电统计';

  @override
  String get repeater_lastRssi => '上次 RSSI';

  @override
  String get repeater_lastSnr => '上次 SNR';

  @override
  String get repeater_noiseFloor => '底噪';

  @override
  String get repeater_txAirtime => '发送空中时间';

  @override
  String get repeater_rxAirtime => '接收空中时间';

  @override
  String get repeater_packetStatistics => '数据包统计';

  @override
  String get repeater_sent => '发送';

  @override
  String get repeater_received => '接收';

  @override
  String get repeater_duplicates => '重复';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days天 $hours小时 $minutes分 $seconds秒';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return '总计：$total，泛洪：$flood，直连：$direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return '总计：$total，泛洪：$flood，直连：$direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return '泛洪：$flood，直连：$direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return '总计：$total';
  }

  @override
  String get repeater_settingsTitle => '转发节点设置';

  @override
  String get repeater_basicSettings => '基本设置';

  @override
  String get repeater_repeaterName => '转发节点名称';

  @override
  String get repeater_repeaterNameHelper => '此转发节点的显示名称';

  @override
  String get repeater_adminPassword => '管理员密码';

  @override
  String get repeater_adminPasswordHelper => '完整访问密码';

  @override
  String get repeater_guestPassword => '访客密码';

  @override
  String get repeater_guestPasswordHelper => '只读访问密码';

  @override
  String get repeater_radioSettings => '无线电设置';

  @override
  String get repeater_frequencyMhz => '频率 (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX 功率';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => '带宽';

  @override
  String get repeater_spreadingFactor => '扩频因子';

  @override
  String get repeater_codingRate => '编码速率';

  @override
  String get repeater_locationSettings => '位置设置';

  @override
  String get repeater_latitude => '纬度';

  @override
  String get repeater_latitudeHelper => '十进制，例如 37.7749';

  @override
  String get repeater_longitude => '经度';

  @override
  String get repeater_longitudeHelper => '十进制，例如 -122.4194';

  @override
  String get repeater_features => '功能';

  @override
  String get repeater_packetForwarding => '数据包转发';

  @override
  String get repeater_packetForwardingSubtitle => '启用转发节点转发数据包';

  @override
  String get repeater_guestAccess => '访客访问';

  @override
  String get repeater_guestAccessSubtitle => '允许访客只读权限';

  @override
  String get repeater_privacyMode => '隐私模式';

  @override
  String get repeater_privacyModeSubtitle => '在广播中隐藏姓名/位置';

  @override
  String get repeater_advertisementSettings => '广播设置';

  @override
  String get repeater_localAdvertInterval => '本地广播间隔';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes 分钟';
  }

  @override
  String get repeater_floodAdvertInterval => '泛洪广播间隔';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours 小时';
  }

  @override
  String get repeater_encryptedAdvertInterval => '加密广播间隔';

  @override
  String get repeater_dangerZone => '危险设置';

  @override
  String get repeater_rebootRepeater => '重启转发节点';

  @override
  String get repeater_rebootRepeaterSubtitle => '重启转发节点设备';

  @override
  String get repeater_rebootRepeaterConfirm => '确定要重启此转发节点吗？';

  @override
  String get repeater_regenerateIdentityKey => '重新生成身份密钥';

  @override
  String get repeater_regenerateIdentityKeySubtitle => '生成新的公钥/私钥对';

  @override
  String get repeater_regenerateIdentityKeyConfirm => '这将为转发节点生成新身份，继续吗？';

  @override
  String get repeater_eraseFileSystem => '擦除文件系统';

  @override
  String get repeater_eraseFileSystemSubtitle => '格式化转发节点文件系统';

  @override
  String get repeater_eraseFileSystemConfirm => '警告：此操作将清除转发节点上的所有数据，且无法恢复！';

  @override
  String get repeater_eraseSerialOnly => '擦除功能仅可通过串行控制台使用。';

  @override
  String repeater_commandSent(String command) {
    return '命令已发送：$command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return '发送命令时出错：$error';
  }

  @override
  String get repeater_confirm => '确认';

  @override
  String get repeater_settingsSaved => '设置保存成功';

  @override
  String repeater_errorSavingSettings(String error) {
    return '保存设置时出错：$error';
  }

  @override
  String get repeater_refreshBasicSettings => '刷新基本设置';

  @override
  String get repeater_refreshRadioSettings => '刷新无线电设置';

  @override
  String get repeater_refreshTxPower => '刷新 TX 功率';

  @override
  String get repeater_refreshLocationSettings => '刷新位置设置';

  @override
  String get repeater_refreshPacketForwarding => '刷新包转发';

  @override
  String get repeater_refreshGuestAccess => '刷新访客权限';

  @override
  String get repeater_refreshPrivacyMode => '刷新隐私模式';

  @override
  String get repeater_refreshAdvertisementSettings => '刷新广播设置';

  @override
  String repeater_refreshed(String label) {
    return '$label 已刷新';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return '刷新 $label 时出错';
  }

  @override
  String get repeater_cliTitle => '转发节点命令行';

  @override
  String get repeater_debugNextCommand => '调试下一条命令';

  @override
  String get repeater_commandHelp => '帮助';

  @override
  String get repeater_clearHistory => '清除历史';

  @override
  String get repeater_noCommandsSent => '尚未发送命令';

  @override
  String get repeater_typeCommandOrUseQuick => '输入命令或使用快捷命令';

  @override
  String get repeater_enterCommandHint => '输入命令...';

  @override
  String get repeater_previousCommand => '上一条命令';

  @override
  String get repeater_nextCommand => '下一条命令';

  @override
  String get repeater_enterCommandFirst => '请先输入命令';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI 命令帧';

  @override
  String repeater_cliCommandError(String error) {
    return '错误：$error';
  }

  @override
  String get repeater_cliQuickGetName => '获取名称';

  @override
  String get repeater_cliQuickGetRadio => '获取无线电设置';

  @override
  String get repeater_cliQuickGetTx => '获取 TX';

  @override
  String get repeater_cliQuickNeighbors => '邻居';

  @override
  String get repeater_cliQuickVersion => '版本';

  @override
  String get repeater_cliQuickAdvertise => '发送广播';

  @override
  String get repeater_cliQuickClock => '时钟';

  @override
  String get repeater_cliQuickClockSync => '同步时钟';

  @override
  String get repeater_cliQuickDiscovery => '发现邻居';

  @override
  String get repeater_cliHelpAdvert => '发送广播包';

  @override
  String get repeater_cliHelpReboot => '重启设备。（注意：可能会收到超时错误，属于正常现象）';

  @override
  String get repeater_cliHelpClock => '显示设备当前时间';

  @override
  String get repeater_cliHelpPassword => '设置新的管理员密码';

  @override
  String get repeater_cliHelpVersion => '显示设备版本和固件构建日期';

  @override
  String get repeater_cliHelpClearStats => '重置各种统计数据';

  @override
  String get repeater_cliHelpSetAf => '设置时间因子';

  @override
  String get repeater_cliHelpSetTx => '设置 LoRa 发射功率 (dBm)（重启生效）';

  @override
  String get repeater_cliHelpSetRepeat => '启用或禁用此节点的转发功能';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '（房间服务器）设为“开”则允许空密码登录，但只能读（不能发送）';

  @override
  String get repeater_cliHelpSetFloodMax => '设置最大传入数据包跳数（≥该值则不转发）';

  @override
  String get repeater_cliHelpSetIntThresh => '设置干扰阈值 (dB)，默认14，设为0禁用';

  @override
  String get repeater_cliHelpSetAgcResetInterval => '设置 AGC 重置间隔（秒），设为0禁用';

  @override
  String get repeater_cliHelpSetMultiAcks => '启用或禁用“多重确认”功能';

  @override
  String get repeater_cliHelpSetAdvertInterval => '设置本地广播间隔（分钟），设为0禁用';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval => '设置泛洪广播间隔（小时），设为0禁用';

  @override
  String get repeater_cliHelpSetGuestPassword => '设置/更新访客密码';

  @override
  String get repeater_cliHelpSetName => '设置广播名称';

  @override
  String get repeater_cliHelpSetLat => '设置广播纬度（十进制）';

  @override
  String get repeater_cliHelpSetLon => '设置广播经度（十进制）';

  @override
  String get repeater_cliHelpSetRadio => '完全重设无线电参数并保存，需重启生效';

  @override
  String get repeater_cliHelpSetRxDelay => '（实验性）设置接收延迟基数，设为0禁用';

  @override
  String get repeater_cliHelpSetTxDelay => '通过因子和随机时隙延迟泛洪数据包转发，降低冲突';

  @override
  String get repeater_cliHelpSetDirectTxDelay => '同 txdelay，用于直连模式数据包';

  @override
  String get repeater_cliHelpSetBridgeEnabled => '启用/禁用桥接';

  @override
  String get repeater_cliHelpSetBridgeDelay => '设置桥接转发延迟';

  @override
  String get repeater_cliHelpSetBridgeSource => '选择桥接器转发接收或发送的数据包';

  @override
  String get repeater_cliHelpSetBridgeBaud => '设置 RS232 桥接串口波特率';

  @override
  String get repeater_cliHelpSetBridgeSecret => '设置 ESPNOW 桥接密钥';

  @override
  String get repeater_cliHelpSetAdcMultiplier => '设置电池电压校正系数（特定板支持）';

  @override
  String get repeater_cliHelpTempRadio => '临时设置无线电参数指定分钟，之后恢复（不保存）';

  @override
  String get repeater_cliHelpSetPerm => '修改 ACL，权限位：0访客、1只读、2读写、3管理员';

  @override
  String get repeater_cliHelpGetBridgeType => '支持桥接模式：RS232、ESPNOW';

  @override
  String get repeater_cliHelpLogStart => '开始记录数据包到文件系统';

  @override
  String get repeater_cliHelpLogStop => '停止记录数据包';

  @override
  String get repeater_cliHelpLogErase => '删除所有记录的数据包';

  @override
  String get repeater_cliHelpNeighbors => '显示零跳广播收到的其他转发节点列表';

  @override
  String get repeater_cliHelpNeighborRemove => '从邻居列表删除第一个匹配项（通过公钥前缀）';

  @override
  String get repeater_cliHelpRegion => '（仅串口）列出所有定义区域及当前泛洪权限';

  @override
  String get repeater_cliHelpRegionLoad => '特殊多命令调用，以空行结束';

  @override
  String get repeater_cliHelpRegionGet => '搜索指定前缀的区域';

  @override
  String get repeater_cliHelpRegionPut => '添加或更新区域定义';

  @override
  String get repeater_cliHelpRegionRemove => '删除指定区域定义';

  @override
  String get repeater_cliHelpRegionAllowf => '为区域设置“泛洪”权限';

  @override
  String get repeater_cliHelpRegionDenyf => '移除区域的“泛洪”权限';

  @override
  String get repeater_cliHelpRegionHome => '返回当前“主区域”（预留）';

  @override
  String get repeater_cliHelpRegionHomeSet => '设置“主”区域';

  @override
  String get repeater_cliHelpRegionSave => '保存区域列表到存储';

  @override
  String get repeater_cliHelpGps => '显示 GPS 状态';

  @override
  String get repeater_cliHelpGpsOnOff => '切换 GPS 电源';

  @override
  String get repeater_cliHelpGpsSync => '将节点时间与 GPS 同步';

  @override
  String get repeater_cliHelpGpsSetLoc => '将节点坐标设为 GPS 坐标并保存';

  @override
  String get repeater_cliHelpGpsAdvert => '设置位置广播配置：none/share/prefs';

  @override
  String get repeater_cliHelpGpsAdvertSet => '设置广播位置配置';

  @override
  String get repeater_commandsListTitle => '命令列表';

  @override
  String get repeater_commandsListNote => '注意：多数 set 命令也有对应的 get 命令';

  @override
  String get repeater_general => '通用';

  @override
  String get repeater_settingsCategory => '设置';

  @override
  String get repeater_bridge => '桥接';

  @override
  String get repeater_logging => '日志';

  @override
  String get repeater_neighborsRepeaterOnly => '邻居（仅转发节点）';

  @override
  String get repeater_regionManagementRepeaterOnly => '区域管理（仅转发节点）';

  @override
  String get repeater_regionNote => '区域命令用于管理区域定义和权限';

  @override
  String get repeater_gpsManagement => 'GPS 管理';

  @override
  String get repeater_gpsNote => 'GPS 命令用于位置相关任务';

  @override
  String get telemetry_receivedData => '接收到的遥测数据';

  @override
  String get telemetry_requestTimeout => '遥测请求超时';

  @override
  String telemetry_errorLoading(String error) {
    return '加载遥测数据时出错：$error';
  }

  @override
  String get telemetry_noData => '暂无遥测数据';

  @override
  String telemetry_channelTitle(int channel) {
    return '频道 $channel';
  }

  @override
  String get telemetry_batteryLabel => '电池';

  @override
  String get telemetry_voltageLabel => '电压';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU 温度';

  @override
  String get telemetry_temperatureLabel => '温度';

  @override
  String get telemetry_currentLabel => '电流';

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
  String get neighbors_receivedData => '已接收邻居信息';

  @override
  String get neighbors_requestTimedOut => '邻居请求超时';

  @override
  String neighbors_errorLoading(String error) {
    return '加载邻居时出错：$error';
  }

  @override
  String get neighbors_repeatersNeighbors => '转发节点的邻居';

  @override
  String get neighbors_noData => '暂无邻居信息';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '未知 $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return '听到：$time前';
  }

  @override
  String get channelPath_title => '数据包路径';

  @override
  String get channelPath_viewMap => '查看地图';

  @override
  String get channelPath_otherObservedPaths => '其他观察到的路径';

  @override
  String get channelPath_repeaterHops => '转发节点跳数';

  @override
  String get channelPath_noHopDetails => '此数据包未提供详细信息';

  @override
  String get channelPath_messageDetails => '消息详情';

  @override
  String get channelPath_senderLabel => '发送者';

  @override
  String get channelPath_timeLabel => '时间';

  @override
  String get channelPath_repeatsLabel => '重复';

  @override
  String channelPath_pathLabel(int index) {
    return '路径 $index';
  }

  @override
  String get channelPath_observedLabel => '观察到的';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return '观察到的路径 $index • $hops';
  }

  @override
  String get channelPath_noLocationData => '无位置信息';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => '未知';

  @override
  String get channelPath_floodPath => '泛洪';

  @override
  String get channelPath_directPath => '直连';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 / $total 跳';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed / $total 跳';
  }

  @override
  String get channelPath_mapTitle => '路径地图';

  @override
  String get channelPath_noRepeaterLocations => '此路径上没有可用的转发节点位置信息';

  @override
  String channelPath_primaryPath(int index) {
    return '路径 $index（主要）';
  }

  @override
  String get channelPath_pathLabelTitle => '路径';

  @override
  String get channelPath_observedPathHeader => '观察到的路径';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable => '此数据包暂无详细信息';

  @override
  String get channelPath_unknownRepeater => '未知转发节点';

  @override
  String get community_title => '社区';

  @override
  String get community_create => '创建社区';

  @override
  String get community_createDesc => '创建新社区并通过二维码分享。';

  @override
  String get community_join => '加入';

  @override
  String get community_joinTitle => '加入社区';

  @override
  String community_joinConfirmation(String name) {
    return '是否加入社区 \"$name\"？';
  }

  @override
  String get community_scanQr => '扫描社区二维码';

  @override
  String get community_scanInstructions => '将摄像头对准社区的二维码';

  @override
  String get community_showQr => '显示二维码';

  @override
  String get community_publicChannel => '社区公共频道';

  @override
  String get community_hashtagChannel => '社区标签频道';

  @override
  String get community_name => '社区名称';

  @override
  String get community_enterName => '请输入社区名称';

  @override
  String community_created(String name) {
    return '社区 \"$name\" 已创建';
  }

  @override
  String community_joined(String name) {
    return '已加入社区 \"$name\"';
  }

  @override
  String get community_qrTitle => '分享社区';

  @override
  String community_qrInstructions(String name) {
    return '扫描此二维码加入 \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint => '仅社区成员可加入社区标签频道。';

  @override
  String get community_invalidQrCode => '无效的社区二维码';

  @override
  String get community_alreadyMember => '已是成员';

  @override
  String community_alreadyMemberMessage(String name) {
    return '您已是 \"$name\" 的成员。';
  }

  @override
  String get community_addPublicChannel => '添加公共频道';

  @override
  String get community_addPublicChannelHint => '自动添加此社区的公共频道';

  @override
  String get community_noCommunities => '尚未加入任何社区。';

  @override
  String get community_scanOrCreate => '扫描二维码或创建社区以开始。';

  @override
  String get community_manageCommunities => '管理社区';

  @override
  String get community_delete => '退出社区';

  @override
  String community_deleteConfirm(String name) {
    return '是否退出 \"$name\"？';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return '这将同时删除 $count 个频道及其所有消息。';
  }

  @override
  String community_deleted(String name) {
    return '已退出社区 \"$name\"';
  }

  @override
  String get community_regenerateSecret => '重新生成密钥';

  @override
  String community_regenerateSecretConfirm(String name) {
    return '是否为 \"$name\" 重新生成密钥？所有成员需扫描新的二维码才能继续通信。';
  }

  @override
  String get community_regenerate => '重新生成';

  @override
  String community_secretRegenerated(String name) {
    return '已为 \"$name\" 重新生成密钥';
  }

  @override
  String get community_updateSecret => '更新密钥';

  @override
  String community_secretUpdated(String name) {
    return '“$name”的密钥已更新';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return '扫描新二维码以更新 \"$name\" 的密钥';
  }

  @override
  String get community_addHashtagChannel => '添加标签频道';

  @override
  String get community_addHashtagChannelDesc => '为此社区创建标签频道';

  @override
  String get community_selectCommunity => '选择社区';

  @override
  String get community_regularHashtag => '普通标签';

  @override
  String get community_regularHashtagDesc => '公共标签频道（任何人都可参与）';

  @override
  String get community_communityHashtag => '社区标签';

  @override
  String get community_communityHashtagDesc => '仅限社区成员';

  @override
  String community_forCommunity(String name) {
    return '为 $name';
  }

  @override
  String get listFilter_tooltip => '筛选与排序';

  @override
  String get listFilter_sortBy => '排序方式';

  @override
  String get listFilter_latestMessages => '最新消息';

  @override
  String get listFilter_heardRecently => '最近听到';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => '筛选';

  @override
  String get listFilter_source => '来源';

  @override
  String get listFilter_saved => '已保存';

  @override
  String get listFilter_discovered => '已发现';

  @override
  String get listFilter_all => '全部';

  @override
  String get listFilter_favorites => '收藏';

  @override
  String get listFilter_addToFavorites => '添加到收藏';

  @override
  String get listFilter_removeFromFavorites => '从收藏中移除';

  @override
  String get listFilter_users => '用户';

  @override
  String get listFilter_repeaters => '转发节点';

  @override
  String get listFilter_roomServers => '房间服务器';

  @override
  String get listFilter_unreadOnly => '仅显示未读';

  @override
  String get listFilter_newGroup => '新建群聊';

  @override
  String get pathTrace_you => '我自己';

  @override
  String get pathTrace_failed => '路径追踪失败。';

  @override
  String get pathTrace_notAvailable => '无法获取路径信息。';

  @override
  String get pathTrace_refreshTooltip => '刷新路径追踪';

  @override
  String get pathTrace_someHopsNoLocation => '某些跳缺少位置信息！';

  @override
  String get pathTrace_clearTooltip => '清除路径';

  @override
  String get losSelectStartEnd => '选择 LOS 的起始节点和结束节点。';

  @override
  String losRunFailed(String error) {
    return '视线检查失败：$error';
  }

  @override
  String get losClearAllPoints => '清除所有点';

  @override
  String get losRunToViewElevationProfile => '运行 LOS 查看高程剖面';

  @override
  String get losMenuTitle => '服务水平菜单';

  @override
  String get losMenuSubtitle => '点击节点或长按地图以获取自定义点';

  @override
  String get losShowDisplayNodes => '显示显示节点';

  @override
  String get losCustomPoints => '自定义积分';

  @override
  String losCustomPointLabel(int index) {
    return '自定义 $index';
  }

  @override
  String get losPointA => 'A点';

  @override
  String get losPointB => 'B点';

  @override
  String losAntennaA(String value, String unit) {
    return '天线 A： $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return '天线 B：$value $unit';
  }

  @override
  String get losRun => '运行视距';

  @override
  String get losNoElevationData => '无海拔数据';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit，清除 LOS，最小间隙 $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit，被 $obstruction $heightUnit 阻止';
  }

  @override
  String get losStatusChecking => '洛斯：正在检查...';

  @override
  String get losStatusNoData => 'LOS：无数据';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS：$clear/$total 清除，$blocked 阻塞，$unknown 未知';
  }

  @override
  String get losErrorElevationUnavailable => '一个或多个样本的海拔数据不可用。';

  @override
  String get losErrorInvalidInput => '用于 LOS 计算的点/高程数据无效。';

  @override
  String get losRenameCustomPoint => '重命名自定义点';

  @override
  String get losPointName => '点名称';

  @override
  String get losShowPanelTooltip => '显示 LOS 面板';

  @override
  String get losHidePanelTooltip => '隐藏 LOS 面板';

  @override
  String get losElevationAttribution => '高程数据：Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => '无线电地平线';

  @override
  String get losLegendLosBeam => '视距波束';

  @override
  String get losLegendTerrain => '地形';

  @override
  String get losFrequencyLabel => '频率';

  @override
  String get losFrequencyInfoTooltip => '查看计算详情';

  @override
  String get losFrequencyDialogTitle => '无线电地平线计算';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return '从 $baselineFreq MHz 处的 k=$baselineK 开始，计算调整当前 $frequencyMHz MHz 频段的 k 因子，该因子定义了弯曲的无线电范围上限。';
  }

  @override
  String get contacts_pathTrace => '路径追踪';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Trace 转发节点';

  @override
  String get contacts_repeaterPing => 'Ping 转发节点';

  @override
  String get contacts_roomPathTrace => 'Trace 房间服务器';

  @override
  String get contacts_roomPing => 'Ping 房间服务器';

  @override
  String get contacts_chatTraceRoute => '路由追踪';

  @override
  String contacts_pathTraceTo(String name) {
    return '追踪至 $name 的路径';
  }

  @override
  String get contacts_clipboardEmpty => '剪贴板为空';

  @override
  String get contacts_invalidAdvertFormat => '无效的联系人信息格式';

  @override
  String get contacts_contactImported => '联系人已导入';

  @override
  String get contacts_contactImportFailed => '导入联系人失败。';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name 已在你的联系人中。';
  }

  @override
  String get contacts_zeroHopAdvert => '发送零跳广播';

  @override
  String get contacts_floodAdvert => '发送泛洪广播';

  @override
  String get contacts_copyAdvertToClipboard => '复制广播到剪贴板';

  @override
  String get contacts_addContactFromClipboard => '从剪贴板添加联系人';

  @override
  String get contacts_ShareContact => '复制联系人信息到剪贴板';

  @override
  String get contacts_ShareContactZeroHop => '通过广播分享联系人';

  @override
  String get contacts_zeroHopContactAdvertSent => '零跳广播已发送';

  @override
  String get contacts_zeroHopContactAdvertFailed => '发送联系人广播失败。';

  @override
  String get contacts_contactAdvertCopied => '广播已复制到剪贴板。';

  @override
  String get contacts_contactAdvertCopyFailed => '复制广播到剪贴板失败。';

  @override
  String get contacts_addContact => '添加联系人';

  @override
  String get contacts_scanQrCode => '扫描联系人二维码';

  @override
  String get contacts_scanQrCodeDesc => '扫描 MeshCore 应用中的联系人二维码';

  @override
  String get contacts_enterIdHash => '手动输入联系人';

  @override
  String get contacts_enterIdHashDesc => '粘贴联系人广播或 meshcore:// 链接';

  @override
  String get contacts_advertHint => 'meshcore://... 或公钥 hex';

  @override
  String get contacts_import => '导入';

  @override
  String get contacts_scanContactInstructions => '扫描 MeshCore 联系人二维码';

  @override
  String get notification_activityTitle => 'MeshCore 活动';

  @override
  String notification_messagesCount(int count) {
    return '$count 条消息';
  }

  @override
  String notification_channelMessagesCount(int count) {
    return '$count 条频道消息';
  }

  @override
  String notification_newNodesCount(int count) {
    return '$count 个新节点';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return '发现新 $contactType';
  }

  @override
  String get notification_receivedNewMessage => '收到新消息';

  @override
  String get settings_gpxExportRepeaters => '导出转发节点/房间服务器到 GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle => '导出带位置的转发节点/房间服务器到 GPX 文件';

  @override
  String get settings_gpxExportContacts => '导出伙伴到 GPX';

  @override
  String get settings_gpxExportContactsSubtitle => '导出带位置的伙伴到 GPX 文件';

  @override
  String get settings_gpxExportAll => '导出所有联系人到 GPX';

  @override
  String get settings_gpxExportAllSubtitle => '导出所有带位置的联系人到 GPX 文件';

  @override
  String get settings_gpxExportSuccess => 'GPX 文件导出成功';

  @override
  String get settings_gpxExportNoContacts => '没有可导出的联系人';

  @override
  String get settings_gpxExportNotAvailable => '您的设备/操作系统不支持';

  @override
  String get settings_gpxExportError => '导出时出错';

  @override
  String get settings_gpxExportRepeatersRoom => '转发节点与房间服务器位置';

  @override
  String get settings_gpxExportChat => '伙伴位置';

  @override
  String get settings_gpxExportAllContacts => '所有联系人位置';

  @override
  String get settings_gpxExportShareText => '来自 MeshTrax 的地图数据导出';

  @override
  String get settings_gpxExportShareSubject => 'MeshTrax GPX 地图数据导出';

  @override
  String get snrIndicator_nearByRepeaters => '附近的重复器';

  @override
  String get snrIndicator_lastSeen => '最近访问';

  @override
  String get contactsSettings_title => '联系人设置';

  @override
  String get contactsSettings_autoAddTitle => '自动发现';

  @override
  String get contactsSettings_otherTitle => '其他联系人相关设置';

  @override
  String get contactsSettings_autoAddUsersTitle => '自动添加用户';

  @override
  String get contactsSettings_autoAddUsersSubtitle => '允许伴侣自动添加发现的用户';

  @override
  String get contactsSettings_autoAddRepeatersTitle => '自动添加重复器';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle => '允许伴侣自动添加发现的重复器';

  @override
  String get contactsSettings_autoAddRoomServersTitle => '自动添加房间服务器';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle => '允许伴侣自动添加发现的房间服务器';

  @override
  String get contactsSettings_autoAddSensorsTitle => '自动添加传感器';

  @override
  String get contactsSettings_autoAddSensorsSubtitle => '允许伴侣自动添加发现的传感器';

  @override
  String get contactsSettings_overwriteOldestTitle => '覆盖最旧的';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      '当联系人列表已满时，将替换最老的非收藏联系人。';

  @override
  String get discoveredContacts_Title => '已发现的联系人';

  @override
  String get discoveredContacts_noMatching => '没有匹配的联系人';

  @override
  String get listFilter_searchHint => '搜索...';

  @override
  String get discoveredContacts_searchHint => '搜索已发现的联系人';

  @override
  String get discoveredContacts_contactAdded => '联系人已添加';

  @override
  String get discoveredContacts_addContact => '添加联系人';

  @override
  String get discoveredContacts_copyContact => '复制联系人到剪贴板';

  @override
  String get discoveredContacts_deleteContact => '删除联系人';

  @override
  String get discoveredContacts_deleteContactAll => '删除所有发现的联系人';

  @override
  String get discoveredContacts_deleteContactAllContent => '您确定要删除所有发现的联系人吗？';

  @override
  String get chat_sendCooldown => '请稍等片刻后再尝试发送。';

  @override
  String get chat_notConnected => '未连接电台。消息未发送。';

  @override
  String get appSettings_jumpToOldestUnread => '跳转到最旧、未读的文章';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      '在打开包含未读消息的聊天时，请滚动到第一个未读消息，而不是最新的消息。';

  @override
  String get appSettings_languageHu => '匈牙利';

  @override
  String get appSettings_languageJa => '日语';

  @override
  String get appSettings_languageKo => '韩语';

  @override
  String get radioStats_screenTitle => '广播统计数据';

  @override
  String get radioStats_notConnected => '连接到设备以查看收音机统计信息。';

  @override
  String get radioStats_firmwareTooOld => '使用无线电统计功能需要配合使用 v8 或更高版本的固件。';

  @override
  String get radioStats_waiting => '正在等待数据…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return '噪声水平：$noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return '上次 RSSI 值：$rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return '上次 SNR：$snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX 频道播出时间（总时长）：$seconds 秒';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX 使用时长（总时长）：$seconds 秒';
  }

  @override
  String get radioStats_chartCaption => '近期的噪声水平（dBm）。';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return '噪声水平：$noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => '正在获取收音机数据…';

  @override
  String get radioStats_settingsTile => '广播统计数据';

  @override
  String get radioStats_settingsSubtitle => '噪声水平、RSSI、信噪比和空中时间';

  @override
  String get translation_title => '翻译';

  @override
  String get translation_enableTitle => '启用翻译功能';

  @override
  String get translation_enableSubtitle => '翻译收到的消息，并允许在发送前进行翻译。';

  @override
  String get translation_composerTitle => '在发送之前进行翻译';

  @override
  String get translation_composerSubtitle => '控制作曲家翻译图标的默认状态。';

  @override
  String get translation_targetLanguage => '目标语言';

  @override
  String get translation_useAppLanguage => '使用应用程序语言';

  @override
  String get translation_downloadedModelLabel => '下载的模型';

  @override
  String get translation_presetModelLabel => '预设的 Hugging Face 模型';

  @override
  String get translation_manualUrlLabel => '手动模型网址';

  @override
  String get translation_downloadModel => '下载模型';

  @override
  String get translation_downloading => '正在下载...';

  @override
  String get translation_working => '工作中...';

  @override
  String get translation_stop => '停止';

  @override
  String get translation_mergingChunks => '将下载的片段合并成最终文件...';

  @override
  String get translation_downloadedModels => '下载的模型';

  @override
  String get translation_deleteModel => '删除模型';

  @override
  String get translation_modelDownloaded => '翻译模型已下载。';

  @override
  String get translation_downloadStopped => '下载已停止。';

  @override
  String translation_downloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get translation_enterUrlFirst => '首先，请输入模型的 URL。';

  @override
  String get scanner_linuxPairingShowPin => '显示PIN码';

  @override
  String get scanner_linuxPairingHidePin => '隐藏 PIN';

  @override
  String get scanner_linuxPairingPinTitle => '蓝牙配对 PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return '输入 $deviceName 的 PIN 码（如果为空，则留空）。';
  }

  @override
  String get translation_messageTranslation => '消息翻译';

  @override
  String get translation_translateBeforeSending => '在发送前进行翻译';

  @override
  String get translation_composerEnabledHint => '消息将在发送前进行翻译。';

  @override
  String get translation_composerDisabledHint => '使用原始的打字方式发送消息。';

  @override
  String translation_translateTo(String language) {
    return '翻译成 $language';
  }

  @override
  String get translation_translationOptions => '翻译选项';

  @override
  String get translation_systemLanguage => '系统语言';

  @override
  String get routing_title => '路由';

  @override
  String routing_route(String route) {
    return '已存路径：$route';
  }

  @override
  String get routing_noRoute => '暂无 — 下一条消息会泛洪发送并学习路径';

  @override
  String get routing_auto => '自动';

  @override
  String get routing_autoSubtitle => '使用电台已存的路径。推荐。';

  @override
  String get routing_pathfinderOn => 'Pathfinder 已开启：优先尝试学到的路由';

  @override
  String get routing_flood => '始终泛洪';

  @override
  String get routing_floodSubtitle => '每条消息都发往整个网络';

  @override
  String get routing_custom => '自定义路径';

  @override
  String get routing_customSubtitle => '自己选择转发节点';

  @override
  String get routing_forget => '重置路径';

  @override
  String get routing_forgetDone => '路径已重置。下一条消息会泛洪发送并学习新路径。';

  @override
  String get routing_pathfinder => 'Pathfinder 掌握的信息';

  @override
  String get routing_pathfinderSubtitle => '能听到您和对方的转发节点，以及学到的往返路由';

  @override
  String get path_direct => '直连 — 不经过转发节点';

  @override
  String get path_directSubtitle => '仅当对方能直接听到本电台时';

  @override
  String get chat_kindFlood => '泛洪';

  @override
  String get chat_kindDirect => '直连';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '跳',
      one: '跳',
    );
    return '路由（$count $_temp0）';
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
  String get chat_statusQueued => '排队中';

  @override
  String get chat_statusNoRepeaterHeard => '没有转发节点听到您。有转发节点进入范围时会再试。';

  @override
  String chat_narrowHashNotice(String name) {
    return '$name 的电台发送的是短转发节点代码（1 字节）。在对方电台改用 2 字节代码之前，Pathfinder 无法学习到对方的路由。';
  }

  @override
  String chat_statusSending(String kind) {
    return '正在发送 · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return '正在重试 · $kind · 第 $attempt/$max 次';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return '已送达 · $kind · $secs 秒';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return '第 $attempt 次尝试送达 · $kind · $secs 秒';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return '延迟送达 · $kind · $secs 秒';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return '已送达 · $secs 秒';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: '次',
      one: '次',
    );
    return '尝试 $attempts $_temp0后失败 · 点按重新发送';
  }

  @override
  String get chat_statusFailedShort => '失败 · 点按重新发送';

  @override
  String get chat_resendingByFlood => '正在通过泛洪重新发送';

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
  String get settings_pathGraph => 'Pathfinder（实验性）';

  @override
  String get settings_pathGraphSubtitle =>
      '从电台听到的所有内容中学习路由，发私信时优先尝试最佳路由。琥珀色路径图标表示该消息经 Pathfinder 路由发送。';

  @override
  String get map_routeAndTrace => '路由与追踪';

  @override
  String get map_pathfinderTrace => '往返追踪';

  @override
  String get map_pathfinderTraceSubtitle => '去程走 Pathfinder 的最佳路由，回程走最佳回程路由';

  @override
  String get map_routeBackMirrored => '尚不知道回程路由 — 原路返回';

  @override
  String get map_traceHelpTitle => '路径追踪按钮';

  @override
  String get map_traceHelpCustom => '自己输入或选择转发节点。';

  @override
  String get map_traceHelpRun => '沿您点按的转发节点单程发送追踪。';

  @override
  String get map_traceHelpThereAndBack => '往返';

  @override
  String get map_traceHelpThereAndBackSubtitle => '发出追踪，然后沿相同的转发节点反向返回。';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder 会选出经过您最后点按的两个转发节点的最佳路由，以及返回您的最佳路由。结果会让 Pathfinder 知道哪些链路真正可用。需要点按两个转发节点。';

  @override
  String get map_traceHelpRemoveLast => '从路径中移除最后一个转发节点。';

  @override
  String get map_traceHelpCancel => '停止构建追踪。在点按任何转发节点之前显示。';

  @override
  String get chat_resendingByRoute => '正在通过您设置的路由重新发送';

  @override
  String get room_mute => '静音房间';

  @override
  String get room_unmute => '取消静音房间';

  @override
  String get room_roleAdmin => '管理员';

  @override
  String get room_roleMember => '成员';

  @override
  String get room_roleReadOnly => '只读';

  @override
  String room_clockOff(int minutes) {
    return '房间时钟偏差约 $minutes 分钟 — 消息时间可能不准确';
  }

  @override
  String get room_fixClock => '校正时钟';

  @override
  String get room_clockSyncSent => '已向房间发送时钟同步';

  @override
  String get room_readOnlyNotice => '只读：房间未接受您的密码，您发送的消息无法送达其他成员。';

  @override
  String get room_postAnnouncement => '发布公告';

  @override
  String get room_postAnnouncementSubtitle => '以房间名义向所有成员发送消息';

  @override
  String get room_announcementSent => '公告已发布';

  @override
  String get room_announcementFailed => '发布公告失败';

  @override
  String get room_users => '房间用户';

  @override
  String get room_usersSubtitle => '查看管理员并设置角色';

  @override
  String get room_usersAdminsNote => '房间仅列出管理员。使用房间密码加入的成员不会显示。';

  @override
  String get room_usersLoadFailed => '无法加载管理员列表';

  @override
  String get room_setUserRole => '设置角色';

  @override
  String get room_removeAccess => '移除访问权限';

  @override
  String get room_removeOnlyUnknown => '该用户不在您的联系人中，只能移除，无法更改。';

  @override
  String get room_roleUpdated => '角色已更新';

  @override
  String get room_roleUpdateFailed => '更改角色失败';

  @override
  String get room_postsStored => '已存帖子';

  @override
  String get room_postsDelivered => '已送达帖子';

  @override
  String get room_reloadPosts => '重新加载最近帖子';

  @override
  String get room_reloadPostsExplain =>
      '请求房间重新发送最近的帖子（最多保留 32 条）。需要输入房间密码。已有的消息会保留。';

  @override
  String get room_reloadFailed => '无法在电台上重置房间';

  @override
  String get companionCli_title => '命令行';

  @override
  String get companionCli_settingsSubtitle => '向此电台输入文本命令';

  @override
  String get companionCli_rebooting => '正在重启电台…';

  @override
  String get companionCli_cancelled => '已取消';

  @override
  String get companionCli_poweringOff => '正在关闭电台…';

  @override
  String get companionCli_noReply => '电台没有回复。请重试。';

  @override
  String get companionCli_powerOffTitle => '关闭电台？';

  @override
  String get companionCli_powerOffBody => '在您按下按钮或接通电源之前，它会一直保持关闭。';

  @override
  String get companionCli_powerOff => '关闭';

  @override
  String get companionCli_quickBoard => '主板';

  @override
  String get companionCli_quickWifiStatus => 'Wi‑Fi 状态';

  @override
  String get companionCli_quickWifiAddress => 'Wi‑Fi 地址';

  @override
  String get companionCli_helpBoard => '显示主板的制造商和型号。';

  @override
  String get companionCli_helpReboot => '重启电台。';

  @override
  String get companionCli_helpPowerOff => '关闭电台。';

  @override
  String get companionCli_helpSetPin => '设置蓝牙配对 PIN。重启后生效。';

  @override
  String get companionCli_helpSetTzOffset =>
      '设置电台自身屏幕上的时钟在 UTC 基础上增加的小时数（-12 到 +14）。';

  @override
  String get companionCli_helpSetTx => '设置发射功率（dBm）。立即生效。';

  @override
  String get companionCli_helpSetIntThresh => '设置干扰阈值（dB）。设为 0 则关闭干扰检测。';

  @override
  String get companionCli_helpSetCad => '发送前先监听是否有其他电台在发射（信道活动检测）。';

  @override
  String get companionCli_helpSetRxGain => '增强接收增益，适用于 SX126x 电台。';

  @override
  String get companionCli_helpSetPathHashMode =>
      '路由中每个转发节点占用的字节数：0 = 1 字节，1 = 2 字节，2 = 3 字节。';

  @override
  String get companionCli_helpWifiStatus => '显示电台是否已连接 Wi‑Fi 网络。';

  @override
  String get companionCli_helpWifiIp => '显示电台在 Wi‑Fi 网络中的地址。';

  @override
  String get companionCli_helpWifiSsid => '设置 Wi‑Fi 网络名称。重启后生效。';

  @override
  String get companionCli_helpWifiPwd => '设置 Wi‑Fi 密码。重启后生效。';

  @override
  String get companionCli_helpWifiEnabled => '开启（1）或关闭（0）Wi‑Fi。重启后生效。';

  @override
  String get companionCli_helpWifiClear => '忘记 Wi‑Fi 网络。重启后生效。';

  @override
  String get companionCli_remoteNoReply =>
      '没有回复。对方电台需要 1.18 或更高版本的固件，并且必须允许您使用其命令行。';

  @override
  String get companionCli_remoteSentNoAnswer => '已发送。电台不会回复重启或关机命令。';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name 试图使用您电台的命令行：“$command”。已被拒绝。';
  }

  @override
  String companionCli_blockedBody(String command) {
    return '试图使用您电台的命令行：“$command”。已被拒绝。';
  }

  @override
  String get contact_remoteCli => '允许远程命令行';

  @override
  String get contact_remoteCliSubtitle => '允许此联系人在您的电台上运行命令';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return '允许 $name 控制您的电台？';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name 将能更改您电台的设置、读取您的 Wi‑Fi 密码、重命名您的电台，以及重启或关闭它。只允许您完全信任的人。';
  }

  @override
  String get contact_remoteCliAllow => '允许';

  @override
  String get connection_secondApp => '另一个应用已连接到此电台。消息和设置可能会混乱。请关闭另一个应用。';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => '网络、密码和连接';

  @override
  String get wifi_use => '使用 Wi‑Fi';

  @override
  String get wifi_networkName => '网络名称';

  @override
  String get wifi_password => '密码';

  @override
  String get wifi_passwordUnchanged => '未更改';

  @override
  String get wifi_showPassword => '显示密码';

  @override
  String get wifi_nameMissing => '请输入网络名称';

  @override
  String get wifi_nameTooLong => '网络名称过长（最多 32 字节）';

  @override
  String get wifi_passwordTooLong => '密码过长（最多 63 字节）';

  @override
  String get wifi_savedRestart => '已保存。Wi‑Fi 更改将在电台重启后生效。';

  @override
  String get wifi_forget => '忘记网络';

  @override
  String get wifi_forgetConfirm => '忘记此 Wi‑Fi 网络？电台重启后将不再使用 Wi‑Fi。';

  @override
  String wifi_notAccepted(String reply) {
    return '电台未接受：$reply';
  }

  @override
  String get wifi_noReply => '电台没有回复。请重试。';

  @override
  String get wifi_restartTitle => '重启电台？';

  @override
  String get wifi_later => '稍后';

  @override
  String get wifi_loadFailed => '无法从电台读取 Wi‑Fi 设置。';

  @override
  String wifi_connectedTo(String address) {
    return '已连接 · $address';
  }

  @override
  String get wifi_notConnected => '未连接 Wi‑Fi';

  @override
  String wifi_portNote(int port) {
    return '同一网络中的应用可以通过端口 $port 连接';
  }

  @override
  String get wifi_connectOverWifi => '通过 Wi‑Fi 连接';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax 将断开与此电台的连接，并打开已填好 $address、端口 $port 的 TCP 页面。请在那里点按“连接”。';
  }

  @override
  String get wifi_noteRestart => '更改将在电台重启后生效。';

  @override
  String get wifi_noteSecurity => '您 Wi‑Fi 网络中的任何人都能通过端口 5000 连接到电台，而且无需密码。';

  @override
  String get wifi_noteBattery => 'Wi‑Fi 会让电台保持唤醒，因此电池消耗更快。';

  @override
  String get wifi_noteWrongPassword => '如果密码错误，电台会每隔几秒不断重试。蓝牙仍可正常使用。';

  @override
  String get room_selfDemoteWarning => '您正在更改自己的访问权限。如果放弃管理员角色，只能通过房间自身的控制台恢复。';

  @override
  String get scanner_offlineMaps => '离线地图';

  @override
  String get appSettings_offlineMaps => '离线地图';

  @override
  String get appSettings_offlineMapsNone => '未下载';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个地区',
      one: '1 个地区',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个海图区域',
      one: '1 个海图区域',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个更新',
      one: '有 1 个更新',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly => '仅在 Wi‑Fi 下下载地图';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle => '地图下载会等待 Wi‑Fi 连接';

  @override
  String get offlineMaps_title => '离线地图';

  @override
  String get offlineMaps_tabMaps => '地图';

  @override
  String get offlineMaps_tabCharts => '海图';

  @override
  String get offlineMaps_chartsNotice => '不可用于导航 · 为什么？';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return '推荐 · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => '按海岸划分的海图区域';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个区域',
      one: '1 个区域',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '已下载 $count 个';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '已选 $count 个';
  }

  @override
  String get offlineMaps_selectAll => '全选';

  @override
  String get offlineMaps_clearSelection => '清除';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return '也属于 $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => '暂不可用';

  @override
  String get offlineMaps_chartsHint => 'NOAA 海图在“海图”标签页中按海岸选择。';

  @override
  String offlineMaps_chartsName(String area) {
    return '$area NOAA 海图';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个区域',
      one: '1 个区域',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => '已下载';

  @override
  String get offlineMaps_refresh => '检查新地图';

  @override
  String get offlineMaps_loading => '正在加载可用地图…';

  @override
  String get offlineMaps_serverError => '无法连接地图服务器';

  @override
  String get offlineMaps_unavailable => '暂无可用地图';

  @override
  String get offlineMaps_unavailableHint => '请稍后再查看。';

  @override
  String get offlineMaps_chartsUnavailable => '暂无可用的 NOAA 海图';

  @override
  String offlineMaps_cachedFrom(String date) {
    return '正在显示 $date 的列表';
  }

  @override
  String get offlineMaps_needsNewerApp => '请更新 MeshTrax 以获取最新地图。';

  @override
  String get offlineMaps_world => '世界';

  @override
  String get offlineMaps_suggested => '推荐';

  @override
  String get offlineMaps_regions => '地区';

  @override
  String offlineMaps_regionsIn(String name) {
    return '$name 的地区';
  }

  @override
  String offlineMaps_inside(int count) {
    return '包含 $count 个';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '本设备上的离线地图占用 $size';
  }

  @override
  String offlineMaps_updates(int count) {
    return '更新（$count）';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return '全部更新 $size';
  }

  @override
  String get offlineMaps_downloading => '正在下载';

  @override
  String get offlineMaps_update => '更新';

  @override
  String offlineMaps_downloadedOn(String date) {
    return '下载于 $date';
  }

  @override
  String get offlineMaps_updateAvailable => '有可用更新';

  @override
  String get offlineMaps_otherFiles => '其他地图文件';

  @override
  String get offlineMaps_emptyTitle => '还没有离线地图';

  @override
  String get offlineMaps_emptyBody => '下载一个地区，即可在没有网络时使用地图。';

  @override
  String get offlineMaps_findMaps => '查找地图';

  @override
  String offlineMaps_deleteTitle(String name) {
    return '删除 $name？';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return '这将释放 $size。之后可以重新下载。';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '已删除 $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get offlineMaps_kindMap => '地图';

  @override
  String get offlineMaps_kindMapDetail => 'OpenStreetMap 街道、步道、地名';

  @override
  String get offlineMaps_kindContours => '等高线';

  @override
  String get offlineMaps_kindContoursDetail => '表示海拔高度的线';

  @override
  String get offlineMaps_kindUsgs => 'USGS 地形图';

  @override
  String get offlineMaps_kindUsgsDetail => '步道、溪流、保护区';

  @override
  String get offlineMaps_kindTerrain => '山体阴影';

  @override
  String get offlineMaps_kindTerrainDetail => '在地图下方以阴影显示丘陵和山脉';

  @override
  String get offlineMaps_kindCharts => 'NOAA 海图';

  @override
  String get offlineMaps_usOnly => '仅限美国';

  @override
  String offlineMaps_download(String size) {
    return '下载 $size';
  }

  @override
  String get offlineMaps_downloadTotal => '下载';

  @override
  String offlineMaps_largeDownload(String size) {
    return '下载文件较大（$size）。请使用 Wi‑Fi 并保持设备充电。';
  }

  @override
  String get offlineMaps_waiting => '等待中…';

  @override
  String get offlineMaps_checking => '正在检查下载…';

  @override
  String get offlineMaps_retrying => '正在重试…';

  @override
  String offlineMaps_failed(String error) {
    return '下载失败：$error';
  }

  @override
  String get offlineMaps_pause => '暂停';

  @override
  String get offlineMaps_resume => '继续';

  @override
  String get offlineMaps_deleteRegion => '删除地区';

  @override
  String get offlineMaps_notInCatalogue => '此地区不可用';

  @override
  String get offlineMaps_notificationRunning => '正在下载地图';

  @override
  String get offlineMaps_notificationPaused => '地图下载已暂停';

  @override
  String get offlineMaps_notificationFailed => '地图下载失败';

  @override
  String get offlineMaps_clearTileCache => '清除在线地图缓存';

  @override
  String get offlineMaps_clearTileCachePrompt => '删除浏览时保存的在线地图图块？已下载的地图会保留。';

  @override
  String get offlineMaps_tileCacheCleared => '已清除在线地图缓存';

  @override
  String get map_notForNavigation => '不可用于导航';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax 根据 NOAA 的海图数据绘制这些海图，帮助您查看电台周围的水域并做规划。它们不是官方海图。请勿据此驾驶船只。';

  @override
  String get map_chartsNoticeWhy => '原因：';

  @override
  String get map_chartsNoticeOutOfDate =>
      '内容会过时。NOAA 一直在修正其海图；已下载的海图在您于“离线地图”中更新之前保持不变。';

  @override
  String get map_chartsNoticeLeftOut => '内容有遗漏。许多海图符号、灯光扇区和注记没有绘制，部分标签要放大后才显示。';

  @override
  String get map_chartsNoticePositions =>
      '位置可能有误或已过时。GPS 可能偏差 10 m (30 ft) 或更多，而节点的位置只是它最后一次报告的位置。';

  @override
  String get map_chartsNoticeNotPlotter => 'MeshTrax 不是经过认证的海图仪。';

  @override
  String get map_chartsNoticeUse =>
      '导航请使用官方、最新的 NOAA 海图（纸质海图，或在认证海图仪中使用 NOAA ENC），并参考最新的航海通告。';

  @override
  String get map_sourceOnline => '在线';

  @override
  String get map_sourceOffline => '离线';

  @override
  String get map_downloadForDetail => '下载地区以查看详情';

  @override
  String get map_zoomInForOfflineMap => '放大以查看离线地图';

  @override
  String get map_noCharts => '此处没有海图';

  @override
  String get map_myLocation => '我的位置';

  @override
  String get map_zoomIn => '放大';

  @override
  String get map_zoomOut => '缩小';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS 已开启';

  @override
  String get gps_off => 'GPS 已关闭';

  @override
  String get gps_onHint => '电台通过 GPS 更新其位置。';

  @override
  String get gps_offHint => '关闭可节省电台电量。开启后可能需要几分钟才能定位。';

  @override
  String get gps_asking => '正在询问电台...';

  @override
  String get gps_noPosition => '尚无位置。在户外，首次定位可能需要几分钟。';

  @override
  String get gps_position => '位置';

  @override
  String get gps_altitude => '海拔';

  @override
  String gps_readAgo(String ago) {
    return '$ago前从电台读取';
  }

  @override
  String get gps_turnOnTitle => '开启 GPS？';

  @override
  String get gps_turnOnBody => '电台的 GPS 已关闭。开启后可能需要几分钟才能定位。';

  @override
  String get gps_turnOn => '开启';

  @override
  String get gps_notNow => '以后再说';

  @override
  String get map_zoomInForCharts => '放大以查看海图';

  @override
  String map_downloadRegion(String region, String size) {
    return '下载 $region · $size';
  }

  @override
  String get mapLayers_title => '地图图层';

  @override
  String get mapLayers_mapType => '地图类型';

  @override
  String get mapLayers_standard => '标准';

  @override
  String get mapLayers_usgs => 'USGS 地形图';

  @override
  String get mapLayers_charts => '海图';

  @override
  String get mapLayers_notDownloaded => '未下载';

  @override
  String get mapLayers_offlineOnly => '仅离线';

  @override
  String get mapLayers_details => '地图详情';

  @override
  String get mapLayers_contours => '等高线';

  @override
  String get mapLayers_hillShading => '山体阴影';

  @override
  String get mapLayers_dark => '深色地图';

  @override
  String get mapLayers_downloadedAreas => '已下载区域';

  @override
  String get mapLayers_nodes => '节点';

  @override
  String get mapLayers_pins => '标记';

  @override
  String get mapLayers_guessed => '推测位置';

  @override
  String get mapLayers_moreFilters => '更多筛选';

  @override
  String get mapLayers_moreFiltersDetail => '最后出现时间、公钥前缀、重叠';

  @override
  String get map_legend => '图例';

  @override
  String get scanner_map => '地图';

  @override
  String get structured_openMap => '打开地图';

  @override
  String get structured_addToCalendar => '添加到日历';

  @override
  String get structured_details => '详情';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => '活动';

  @override
  String get structured_notice => '公告';

  @override
  String get structured_allDay => '全天';

  @override
  String get structured_calendarFailed => '无法打开日历';

  @override
  String get structured_today => '今天';

  @override
  String get structured_tomorrow => '明天';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天后',
      one: '1 天后',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => '已结束';

  @override
  String structured_dayOfDays(int day, int total) {
    return '第 $day 天，共 $total 天';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天',
      one: '1 天',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => '结束日期';

  @override
  String get dialog_eventSameDay => '同一天';

  @override
  String get structured_map => '地图';

  @override
  String get structured_navigate => '导航';

  @override
  String get structured_channel => '频道';

  @override
  String get structured_contact => '联系人';

  @override
  String get structured_room => '房间';

  @override
  String get structured_repeater => '转发节点';

  @override
  String get structured_sensor => '传感器';

  @override
  String get structured_joinChannel => '加入频道';

  @override
  String get structured_addContact => '添加联系人';

  @override
  String get structured_addRoom => '添加房间';

  @override
  String get structured_addRepeater => '添加转发节点';

  @override
  String get structured_addSensor => '添加传感器';

  @override
  String get structured_open => '打开';

  @override
  String get structured_added => '已添加';

  @override
  String get tray_add => '添加';

  @override
  String get tray_myLocation => '我的位置';

  @override
  String get tray_pointOnMap => '地图上的点';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => '活动';

  @override
  String get tray_notice => '公告';

  @override
  String get tray_noRadioPosition => '您的电台还没有位置。请在地图上选择一个。';

  @override
  String get dialog_insert => '插入';

  @override
  String get dialog_eventTitle => '标题';

  @override
  String get dialog_eventDate => '日期';

  @override
  String get dialog_eventStart => '开始';

  @override
  String get dialog_eventEnd => '结束';

  @override
  String get dialog_eventNoEnd => '无结束时间';

  @override
  String get dialog_eventPlace => '地点（可选）';

  @override
  String get dialog_pickOnMap => '在地图上选择';

  @override
  String get dialog_sosTitle => '发送 SOS';

  @override
  String get dialog_sosText => '发生了什么？';

  @override
  String get dialog_noticeTitle => '公告';

  @override
  String get dialog_noticeText => '想让大家知道什么？';

  @override
  String get dialog_labelTitle => '地图上的点';

  @override
  String get dialog_note => '备注（可选）';

  @override
  String get paste_convertLocation => '看起来是地图链接。要转换为位置吗？';

  @override
  String get paste_convertEvent => '看起来是日历分享。要转换为活动吗？';

  @override
  String get paste_convert => '转换';

  @override
  String get paste_resolving => '正在解析链接…';

  @override
  String get paste_resolveFailed => '无法解析链接';

  @override
  String get pinned_dismiss => '关闭';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return '加入频道 $name？';
  }

  @override
  String link_alreadyJoined(String name) {
    return '您已在 $name 中';
  }

  @override
  String link_channelJoined(String name) {
    return '已加入 $name';
  }

  @override
  String get map_pickPositionHint => '点按地图以选择位置';

  @override
  String get map_legendMesh => '网状网络';

  @override
  String get chartLegend_title => '海图符号';

  @override
  String get chartLegend_sectionBuoys => '浮标与立标';

  @override
  String get chartLegend_sectionLights => '灯标';

  @override
  String get chartLegend_sectionHazards => '危险物';

  @override
  String get chartLegend_sectionTides => '潮汐与潮流';

  @override
  String get chartLegend_sectionDepths => '水深与海底';

  @override
  String get chartLegend_sectionAreas => '区域、航道与线条';

  @override
  String get chartLegend_sectionLandmarks => '陆标';

  @override
  String get chartLegend_sectionAbbreviations => '缩写';

  @override
  String get chartLegend_chartNo1 => '所有海图符号：U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => '绿色罐形浮标';

  @override
  String get chartLegend_portBuoyHint => '从海上进港时，使其保持在您的左侧';

  @override
  String get chartLegend_starboardBuoy => '红色锥形浮标';

  @override
  String get chartLegend_starboardBuoyHint => '进港时使其保持在右侧：返航时红色在右';

  @override
  String get chartLegend_junctionBuoy => '横带浮标';

  @override
  String get chartLegend_junctionBuoyHint => '航道分叉处：按其最上方色带的颜色对待';

  @override
  String get chartLegend_safeWaterBuoy => '红白竖条纹';

  @override
  String get chartLegend_safeWaterBuoyHint => '四周均为安全水域，常位于航道入口';

  @override
  String get chartLegend_isolatedDangerBuoy => '黑红横带';

  @override
  String get chartLegend_isolatedDangerBuoyHint => '周围是安全水域的小型危险物：远离';

  @override
  String get chartLegend_specialBuoy => '黄色浮标';

  @override
  String get chartLegend_specialBuoyHint => '专用标志，不作航行引导：锚地、电缆、科研等';

  @override
  String get chartLegend_cardinalBuoy => '黑黄相间';

  @override
  String get chartLegend_cardinalBuoyHint => '方位标：从其所指方位一侧通过（在美国少见）';

  @override
  String get chartLegend_mooringBuoy => '系泊浮标';

  @override
  String get chartLegend_portBeacon => '绿色方形立标';

  @override
  String get chartLegend_portBeaconHint => '与绿色浮标相同：进港时保持在左侧';

  @override
  String get chartLegend_starboardBeacon => '红色三角形立标';

  @override
  String get chartLegend_starboardBeaconHint => '与红色浮标相同：进港时保持在右侧';

  @override
  String get chartLegend_otherBeacon => '菱形立标';

  @override
  String get chartLegend_otherBeaconHint => '表示信息或警告，不标示航道的某一侧';

  @override
  String get chartLegend_beaconTower => '灯桩或立标结构';

  @override
  String get chartLegend_topmark => '顶标';

  @override
  String get chartLegend_topmarkHint => '标志顶部的形状补充其含义';

  @override
  String get chartLegend_light => '灯标';

  @override
  String get chartLegend_lightHint => '品红色光芒表示灯标；其标签说明闪光方式';

  @override
  String get chartLegend_lightExample => '绿色闪光，每 4 秒一次';

  @override
  String get chartLegend_lightExampleHint => '灯标的标签：灯质、颜色、周期';

  @override
  String get chartLegend_lightFixed => '定光';

  @override
  String get chartLegend_lightFixedHint => '持续不灭的灯光';

  @override
  String get chartLegend_lightFlashing => '闪光';

  @override
  String get chartLegend_lightFlashingHint => '短暂闪光，间隔较长的暗期';

  @override
  String get chartLegend_lightGroup => '联闪光';

  @override
  String get chartLegend_lightGroupHint => '成组闪光（此处为 2 次），然后熄灭';

  @override
  String get chartLegend_lightComposite => '混合联闪光';

  @override
  String get chartLegend_lightCompositeHint => '闪 2 次再闪 1 次：标示航道分叉';

  @override
  String get chartLegend_lightQuick => '快闪光';

  @override
  String get chartLegend_lightQuickHint => '约每秒闪一次';

  @override
  String get chartLegend_lightIsophase => '等明暗光';

  @override
  String get chartLegend_lightIsophaseHint => '明暗时间相等';

  @override
  String get chartLegend_lightOcculting => '明暗光';

  @override
  String get chartLegend_lightOccultingHint => '亮的时间比暗的时间长';

  @override
  String get chartLegend_lightMorse => '莫尔斯码 A';

  @override
  String get chartLegend_lightMorseHint => '短、长：安全水域';

  @override
  String get chartLegend_lightAlternating => '互光';

  @override
  String get chartLegend_lightAlternatingHint => '颜色交替变化';

  @override
  String get chartLegend_lightColours => '白、红、绿、黄';

  @override
  String get chartLegend_lightPeriod => '周期';

  @override
  String get chartLegend_lightPeriodHint => '完成一个周期所需的秒数';

  @override
  String get chartLegend_rock => '暗礁';

  @override
  String get chartLegend_rockHint => '始终在水下，但可能很浅';

  @override
  String get chartLegend_rockAwash => '适淹礁';

  @override
  String get chartLegend_rockAwashHint => '低潮时接近水面';

  @override
  String get chartLegend_rockCovers => '干出礁';

  @override
  String get chartLegend_rockCoversHint => '低潮时露出，高潮时淹没';

  @override
  String get chartLegend_wreckDangerous => '危险沉船';

  @override
  String get chartLegend_wreckDangerousHint => '浅到船只可能撞上';

  @override
  String get chartLegend_wreck => '沉船';

  @override
  String get chartLegend_wreckHint => '水面船只可安全通过；勿抛锚';

  @override
  String get chartLegend_wreckShowing => '部分露出的沉船';

  @override
  String get chartLegend_wreckShowingHint => '部分露出水面';

  @override
  String get chartLegend_obstruction => '障碍物';

  @override
  String get chartLegend_obstructionHint => '海底的物体；如已知则标注其水深';

  @override
  String get chartLegend_foulGround => '险恶地';

  @override
  String get chartLegend_foulGroundHint => '可安全驶过，但勿抛锚或拖网';

  @override
  String get chartLegend_hazardArea => '危险区边界';

  @override
  String get chartLegend_hazardAreaHint => '内有礁石、沉船或障碍物';

  @override
  String get chartLegend_pile => '桩';

  @override
  String get chartLegend_floodStream => '涨潮流';

  @override
  String get chartLegend_floodStreamHint => '涨潮时的潮流';

  @override
  String get chartLegend_ebbStream => '落潮流';

  @override
  String get chartLegend_ebbStreamHint => '落潮时的潮流';

  @override
  String get chartLegend_current => '海流';

  @override
  String get chartLegend_currentHint => '无论潮汐如何都朝同一方向流动';

  @override
  String get chartLegend_rips => '急流或漩涡';

  @override
  String get chartLegend_ripsHint => '汹涌、打旋的水面';

  @override
  String get chartLegend_breakers => '碎浪';

  @override
  String get chartLegend_breakersHint => '在浅滩上破碎的波浪';

  @override
  String get chartLegend_sounding => '水深';

  @override
  String get chartLegend_soundingHint => '平均低潮时的水深';

  @override
  String get chartLegend_depthContour => '等深线';

  @override
  String get chartLegend_depthContourHint => '标签标出水深';

  @override
  String get chartLegend_drying => '低潮时干出';

  @override
  String get chartLegend_dredged => '疏浚航道';

  @override
  String get chartLegend_dredgedHint => '维持在所标水深';

  @override
  String get chartLegend_swept => '扫测区';

  @override
  String get chartLegend_sweptHint => '已确认至所标水深无障碍';

  @override
  String get chartLegend_unsurveyed => '未测量';

  @override
  String get chartLegend_unsurveyedHint => '未测水深';

  @override
  String get chartLegend_weed => '海藻';

  @override
  String get chartLegend_restricted => '限制区';

  @override
  String get chartLegend_restrictedHint => '限制进入；短线指向区域内侧';

  @override
  String get chartLegend_regulatedLimit => '管制区边界';

  @override
  String get chartLegend_regulatedLimitHint => '锚地、电缆区、射击区等：见其标签';

  @override
  String get chartLegend_greyLimit => '倾倒区、渔场或养殖场';

  @override
  String get chartLegend_anchorage => '锚地';

  @override
  String get chartLegend_anchorBerth => '锚位';

  @override
  String get chartLegend_noAnchoring => '禁止抛锚';

  @override
  String get chartLegend_caution => '警示区';

  @override
  String get chartLegend_cautionHint => '在此需格外小心';

  @override
  String get chartLegend_trafficLane => '通航分道';

  @override
  String get chartLegend_trafficLaneHint => '大船单向通行：以直角穿越';

  @override
  String get chartLegend_separationZone => '分隔带';

  @override
  String get chartLegend_separationZoneHint => '位于通航分道之间：勿进入';

  @override
  String get chartLegend_precautionary => '警戒区';

  @override
  String get chartLegend_precautionaryHint => '船舶汇聚：注意安全';

  @override
  String get chartLegend_fairway => '航道';

  @override
  String get chartLegend_fairwayHint => '主要航道';

  @override
  String get chartLegend_track => '推荐航线';

  @override
  String get chartLegend_ferry => '渡轮航线';

  @override
  String get chartLegend_leadingLine => '叠标线';

  @override
  String get chartLegend_leadingLineHint => '将两个标志对成一条直线，即可保持在航道内';

  @override
  String get chartLegend_cable => '海底电缆';

  @override
  String get chartLegend_cableHint => '勿抛锚';

  @override
  String get chartLegend_pipeline => '海底管道';

  @override
  String get chartLegend_pipelineHint => '勿抛锚';

  @override
  String get chartLegend_overhead => '架空电缆';

  @override
  String get chartLegend_overheadHint => '其净空高度标为 VC';

  @override
  String get chartLegend_tower => '塔';

  @override
  String get chartLegend_windTurbine => '风力发电机';

  @override
  String get chartLegend_chimney => '烟囱';

  @override
  String get chartLegend_mast => '桅杆或天线';

  @override
  String get chartLegend_church => '教堂或尖塔';

  @override
  String get chartLegend_flagstaff => '旗杆';

  @override
  String get chartLegend_dome => '圆顶';

  @override
  String get chartLegend_landmark => '其他陆标';

  @override
  String get chartLegend_abbrAnch => '锚地';

  @override
  String get chartLegend_abbrWk => '沉船';

  @override
  String get chartLegend_abbrBr => '碎浪';

  @override
  String get chartLegend_abbrWd => '海藻';

  @override
  String get chartLegend_abbrVar => '磁差';

  @override
  String get chartLegend_abbrVc => '桥梁或电缆下方的净空高度';

  @override
  String get chartLegend_abbrTr => '塔';

  @override
  String get chartLegend_abbrCh => '教堂';

  @override
  String get chartLegend_abbrChy => '烟囱';

  @override
  String get chartLegend_abbrFs => '旗杆';

  @override
  String get chartLegend_abbrTk => '储罐';

  @override
  String get chartLegend_abbrRBn => '无线电信标';

  @override
  String get chartLegend_abbrCg => '海岸警卫队站';

  @override
  String get chartLegend_abbrRacon => '雷达应答器：在雷达上显示';

  @override
  String get chartLegend_abbrFog => '雾号：号角、钟、锣、哨或警笛';

  @override
  String get chartLegend_abbrVAis => '虚拟航标：仅在 AIS 上显示';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from 至 $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return '深于 $depth';
  }

  @override
  String get parkLegend_title => '公园与步道符号';

  @override
  String get parkLegend_campsite => '露营地';

  @override
  String get parkLegend_picnicSite => '野餐区';

  @override
  String get parkLegend_shelter => '避难所';

  @override
  String get parkLegend_toilets => '厕所';

  @override
  String get parkLegend_drinkingWater => '饮用水';

  @override
  String get parkLegend_parking => '停车场';

  @override
  String get parkLegend_viewpoint => '观景点';

  @override
  String get parkLegend_attraction => '景点';

  @override
  String get parkLegend_gate => '大门';

  @override
  String get parkLegend_telephone => '电话';

  @override
  String get parkLegend_information => '信息牌';

  @override
  String get parkLegend_guidepost => '路标';

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
}
