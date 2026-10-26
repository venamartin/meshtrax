// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bulgarian (`bg`).
class AppLocalizationsBg extends AppLocalizations {
  AppLocalizationsBg([String locale = 'bg']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Чатове';

  @override
  String get chats_title => 'Чатове';

  @override
  String get newChat_title => 'Изберете контакт';

  @override
  String newChat_contactCount(int count) {
    return 'Контакти: $count';
  }

  @override
  String get newChat_newContact => 'Нов контакт';

  @override
  String get newChat_newChannel => 'Нов канал';

  @override
  String get newChat_myContacts => 'Моите контакти';

  @override
  String get newChat_discovered => 'Открити';

  @override
  String get repeaters_title => 'Управление на повторители';

  @override
  String get nav_contacts => 'Контакти';

  @override
  String get nav_channels => 'Канали';

  @override
  String get nav_map => 'Карта';

  @override
  String get common_cancel => 'Отказ';

  @override
  String get common_syncing_device_info =>
      'Четене на данните за устройството...';

  @override
  String get common_syncing_contacts => 'Четене на контактите...';

  @override
  String get common_syncing_channels => 'Четене на каналите...';

  @override
  String get common_syncing_messages => 'Четене на съобщенията...';

  @override
  String get common_ok => 'Добре';

  @override
  String get common_connect => 'Свържи се';

  @override
  String get common_unknownDevice => 'Неизвестно устройство';

  @override
  String get common_save => 'Запази';

  @override
  String get common_delete => 'Изтрий';

  @override
  String get common_deleteAll => 'Изтрий всичко';

  @override
  String get common_close => 'Затвори';

  @override
  String get common_edit => 'Редактирай';

  @override
  String get common_add => 'Добави';

  @override
  String get common_settings => 'Настройки';

  @override
  String get common_disconnect => 'Прекъсни';

  @override
  String get common_connected => 'Свързано';

  @override
  String get common_disconnected => 'Откъснато';

  @override
  String get common_connectionLost =>
      'Връзката е загубена. Свързване отново...';

  @override
  String get common_reconnecting => 'Свързване отново...';

  @override
  String get common_create => 'Създай';

  @override
  String get common_continue => 'Продължи';

  @override
  String get common_share => 'Сподели';

  @override
  String get common_copy => 'Копирай';

  @override
  String get common_retry => 'Опитай отново';

  @override
  String get common_hide => 'Скриване';

  @override
  String get common_remove => 'Изтрий';

  @override
  String get common_enable => 'Активирай';

  @override
  String get common_disable => 'Деактивирай';

  @override
  String get common_reboot => 'Рестартирай';

  @override
  String get common_loading => 'Зареждане...';

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
  String get scanner_title => 'MeshTrax';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'Свържете се чрез TCP';

  @override
  String get tcpHostLabel => 'IP адрес';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Пристанище';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Въведете крайната точка и свържете се.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Свързване към $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Необходим е IP адрес.';

  @override
  String get tcpErrorPortInvalid => 'Портът трябва да бъде между 1 и 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Транспортът чрез TCP не се поддържа на тази платформа.';

  @override
  String get tcpErrorTimedOut => 'Връзката TCP изтекла.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Неуспешно е установено TCP връзката: $error';
  }

  @override
  String get usbScreenTitle => 'Свържете се чрез USB';

  @override
  String get usbScreenSubtitle =>
      'Изберете открития сериен уред и свържете директно към вашия MeshCore възел.';

  @override
  String get usbScreenStatus => 'Изберете USB устройство';

  @override
  String get usbScreenNote =>
      'USB серийната връзка е активна на поддържаните Android устройства и настолни платформи.';

  @override
  String get usbScreenEmptyState =>
      'Няма открити USB устройства. Включете едно и опитайте отново.';

  @override
  String get usbErrorPermissionDenied => 'Не беше разрешено достъпът през USB.';

  @override
  String get usbErrorDeviceMissing =>
      'Избраното USB устройство вече не е налично.';

  @override
  String get usbErrorInvalidPort => 'Изберете валитно USB устройство.';

  @override
  String get usbErrorBusy =>
      'Друг мол за свързване през USB вече е в процес на изпълнение.';

  @override
  String get usbErrorNotConnected => 'Няма свързано USB устройство.';

  @override
  String get usbErrorOpenFailed =>
      'Не успях да отворя избраното USB устройство.';

  @override
  String get usbErrorConnectFailed =>
      'Не успях да се свържа с избраното USB устройство.';

  @override
  String get usbErrorUnsupported =>
      'USB серийната комуникация не се поддържа на тази платформа.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'В тази версия липсва библиотеката за USB serial, затова USB устройствата не могат да се отворят. Инсталирайте MeshTrax отново или съобщете, че тази версия е повредена.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Този браузър не поддържа Web Serial. Използвайте Chrome или Edge през HTTPS (или localhost).';

  @override
  String get usbErrorAlreadyActive => 'USB връзката вече е активирана.';

  @override
  String get usbErrorNoDeviceSelected => 'Няма избран USB устройство.';

  @override
  String get usbErrorPortClosed => 'USB връзката не е активна.';

  @override
  String get usbErrorConnectTimedOut =>
      'Връзката прекъсна. Уверете се, че устройството има софтуер за USB връзка.';

  @override
  String get usbFallbackDeviceName =>
      'Устройство за четене на уеб серийни данни';

  @override
  String get usbStatus_notConnected => 'Изберете USB устройство';

  @override
  String get usbStatus_connecting => 'Свързване към USB устройство...';

  @override
  String get usbStatus_searching => 'Търсене на USB устройства...';

  @override
  String usbConnectionFailed(String error) {
    return 'Неуспешно свързване през USB: $error';
  }

  @override
  String get scanner_scanning => 'Сканиране за устройства...';

  @override
  String get scanner_connecting => 'Свързвам се...';

  @override
  String get scanner_disconnecting => 'Изключване...';

  @override
  String get scanner_notConnected => 'Не е свързан';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Свързано с $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Покажи всички Bluetooth устройства';

  @override
  String get scanner_showMeshCoreOnly => 'Само радиа с MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'Радиото не отговаря. Може да трябва сдвояване: отворете настройките на Bluetooth, добавете радиото и въведете неговия PIN, после опитайте отново.';

  @override
  String get scanner_pairingFailed =>
      'Сдвояването чрез Bluetooth е отказано или неуспешно. Уверете се, че нищо друго (например телефонът ви) не е свързано с радиото, после опитайте отново и въведете неговия PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Връзката не успя: $error';
  }

  @override
  String get scanner_stop => 'Спрете';

  @override
  String get scanner_scan => 'Сканирай';

  @override
  String get scanner_scanFromImage => 'Сканирай от изображение';

  @override
  String get scanner_noQrFoundInImage => 'В изображението няма валиден QR код';

  @override
  String get scanner_bluetoothOff => 'Bluetooth е изключен.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Моля, активирайте Bluetooth, за да сканирате за устройства.';

  @override
  String get scanner_chromeRequired => 'Изисква се браузър Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Това уеб приложение изисква Google Chrome или браузър, базиран на Chromium, за поддръжка на Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Активирайте Bluetooth';

  @override
  String get device_quickSwitch => 'Бързо превключване';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Настройки';

  @override
  String get settings_deviceInfo => 'Информация за устройството';

  @override
  String get settings_appSettings => 'Настройки на приложението';

  @override
  String get settings_appSettingsSubtitle =>
      'Уведомления, съобщения и предпочитания за карта';

  @override
  String get settings_nodeSettings => 'Настройки на възела';

  @override
  String get settings_nodeName => 'Име на възела';

  @override
  String get settings_nodeNameNotSet => 'Не е зададено';

  @override
  String get settings_nodeNameHint => 'Въведете име на възел';

  @override
  String get settings_nodeNameUpdated => 'Името е актуализирано';

  @override
  String get settings_radioSettings => 'Настройки на радиопредавателя';

  @override
  String get settings_radioSettingsSubtitle =>
      'Честота, мощност, разпространяващ фактор';

  @override
  String get settings_radioSettingsUpdated =>
      'Радио настройките са актуализирани';

  @override
  String get settings_location => 'Местоположение';

  @override
  String get settings_locationSubtitle => 'Координати на GPS';

  @override
  String get settings_locationUpdated => 'Местоположението е актуализирано';

  @override
  String get settings_locationBothRequired =>
      'Въведете както географска ширина, така и географска дължина.';

  @override
  String get settings_locationInvalid => 'Невалидна ширина или дължина.';

  @override
  String get settings_locationGPSEnable => 'Активиране на GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Активирайте автоматичното актуализиране на местоположението чрез GPS.';

  @override
  String get settings_latitude => 'Широчина';

  @override
  String get settings_longitude => 'Дължина';

  @override
  String get settings_contactSettings => 'Настройки за контакти';

  @override
  String get settings_contactSettingsSubtitle =>
      'Настройки за добавяне на контакти.';

  @override
  String get settings_privacyMode => 'Режим на поверителност';

  @override
  String get settings_privacyModeSubtitle =>
      'Скриване на име/местоположение в рекламите';

  @override
  String get settings_privacyModeToggle =>
      'Активирайте режим на поверителност, за да скриете името и местоположението си в рекламите.';

  @override
  String get settings_privacyModeEnabled =>
      'Режим на поверителност е активиран';

  @override
  String get settings_privacyModeDisabled =>
      'Режим на поверителност е деактивиран';

  @override
  String get settings_privacy => 'Настройки на поверителността';

  @override
  String get settings_privacySubtitle =>
      'Контролирайте каква информация се споделя.';

  @override
  String get settings_privacySettingsDescription =>
      'Изберете каква информация устройството ви споделя с другите.';

  @override
  String get settings_denyAll => 'Откажи всичко';

  @override
  String get settings_allowByContact => 'Позволи по флагове за контакт';

  @override
  String get settings_allowAll => 'Позволи всичко';

  @override
  String get settings_telemetryBaseMode => 'Базов режим на телеметрия';

  @override
  String get settings_telemetryLocationMode =>
      'Режим на местоположение на телеметрията';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Режим на средата на телеметрията';

  @override
  String get settings_advertLocation => 'Място на обявата';

  @override
  String get settings_advertLocationSubtitle =>
      'Включи местоположение в обявата';

  @override
  String get settings_multiAck => 'Множество потвърждения';

  @override
  String get settings_telemetryModeUpdated => 'Режим на телеметрията е обновен';

  @override
  String get settings_actions => 'Действия';

  @override
  String get settings_sendAdvertisement => 'Изпрати Реклама';

  @override
  String get settings_sendAdvertisementSubtitle => 'Сега присъствие в ефир';

  @override
  String get settings_advertisementSent => 'Реклама изпратена';

  @override
  String get settings_syncTime => 'Време за синхронизация';

  @override
  String get settings_syncTimeSubtitle =>
      'Задайте часовника на устройството да отговаря на времето на телефона.';

  @override
  String get settings_timeSynchronized => 'Синхронизирано във времето';

  @override
  String get settings_refreshContacts => 'Презареди контакти';

  @override
  String get settings_refreshContactsSubtitle =>
      'Презареди списъка с контакти от устройството';

  @override
  String get settings_rebootDevice => 'Рестартирайте устройството';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Рестартирайте устройството MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Сигурни ли сте, че искате да рестартирате устройството? Ще бъдете откъснати.';

  @override
  String get settings_debug => 'Отстрани';

  @override
  String get settings_bleDebugLog => 'Лог за отстраняване на грешки на BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Команди, отговори и сурови данни BLE';

  @override
  String get settings_appDebugLog =>
      'Лог на отстраняване на грешки на приложението';

  @override
  String get settings_appDebugLogSubtitle =>
      'Съобщения за отстраняване на грешки на приложението';

  @override
  String get settings_exportDatabase => 'Експортиране на базата със съобщения';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Копие на всички чатове и контакти за отстраняване на грешки. Пазете го лично.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Базата е запазена в: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Експортирането не бе успешно: $error';
  }

  @override
  String get settings_about => 'За нас';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'Проект MeshCore с отворен код 2024 г.';

  @override
  String get settings_aboutDescription =>
      'Отворен софтуер за Flutter клиент за MeshCore LoRa мрежови устройства.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Данни за надморска височина на LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Име';

  @override
  String get settings_infoId => 'ИД';

  @override
  String get settings_infoStatus => 'Статус';

  @override
  String get settings_infoBattery => 'Батерия';

  @override
  String get settings_infoPublicKey => 'Общ публичен ключ';

  @override
  String get settings_infoContactsCount => 'Брой контакти';

  @override
  String get settings_infoChannelCount => 'Брой канали';

  @override
  String get settings_presets => 'Предварителни настройки';

  @override
  String get settings_frequency => 'Честота (MHz)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Невалидна честота (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Ширина на честотния спектър';

  @override
  String get settings_spreadingFactor => 'Фактор на разпространение';

  @override
  String get settings_codingRate => 'Такса за кодиране';

  @override
  String get settings_txPower => 'TX Мощност (dBm)';

  @override
  String get settings_txPowerInvalid => 'Невалидна мощност на TX';

  @override
  String get settings_clientRepeat => 'Без електричество – повторение';

  @override
  String get settings_clientRepeatSubtitle =>
      'Позволете на това устройство да предава пакети към мрежата за други устройства.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'За повторение извън мрежата са необходими честоти от 433, 869 или 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Грешка: $message';
  }

  @override
  String get appSettings_title => 'Настройки на приложението';

  @override
  String get appSettings_appearance => 'Външен вид';

  @override
  String get appSettings_theme => 'Тема';

  @override
  String get appSettings_themeSystem => 'Система по подразбиране';

  @override
  String get appSettings_themeLight => 'Ярка';

  @override
  String get appSettings_themeDark => 'Тъмно';

  @override
  String get appSettings_language => 'Език';

  @override
  String get appSettings_languageSystem => 'Система по подразбиране';

  @override
  String get appSettings_languageEn => 'English';

  @override
  String get appSettings_languageFr => 'Français';

  @override
  String get appSettings_languageEs => 'Español';

  @override
  String get appSettings_languageDe => 'Deutsch';

  @override
  String get appSettings_languagePl => 'Polski';

  @override
  String get appSettings_languageSl => 'Slovenščina';

  @override
  String get appSettings_languagePt => 'Português';

  @override
  String get appSettings_languageIt => 'Italiano';

  @override
  String get appSettings_languageZh => '中文';

  @override
  String get appSettings_languageSv => 'Svenska';

  @override
  String get appSettings_languageNl => 'Nederlands';

  @override
  String get appSettings_languageSk => 'Slovenčina';

  @override
  String get appSettings_languageBg => 'Български';

  @override
  String get appSettings_languageRu => 'Руски';

  @override
  String get appSettings_languageUk => 'Украински';

  @override
  String get appSettings_enableMessageTracing =>
      'Разрешаване на проследяване на съобщения';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Показване на подробни метаданни за маршрутизация и синхронизация за съобщения';

  @override
  String get appSettings_senderNameColors => 'Цветни имена на подателите';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Всеки подател в канал получава свой цвят на името. Когато е изключено, всички са в цвета на темата.';

  @override
  String get appSettings_showTextFormatting =>
      'Показвай форматирането на текста';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown в съобщенията: **удебелен**, *курсив*, ||спойлери||, заглавия и връзки. Другите приложения за MeshCore показват символите както са.';

  @override
  String get appSettings_notifications => 'Уведомления';

  @override
  String get appSettings_enableNotifications => 'Активирай Известия';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Получете известия за съобщения и реклами';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Отказвано е разрешение за известия';

  @override
  String get appSettings_notificationsEnabled => 'Уведомителни са активирани';

  @override
  String get appSettings_notificationsDisabled => 'Известия са изключени';

  @override
  String get appSettings_messageNotifications => 'Уведомления';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Покажи известие при получаване на нови съобщения';

  @override
  String get appSettings_channelMessageNotifications =>
      'Уведомления за съобщения от канал';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Покажи известие при получаване на съобщения от канали';

  @override
  String get appSettings_advertisementNotifications => 'Уведомления за реклами';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Покажи известие, когато бъдат открити нови възли.';

  @override
  String get appSettings_messaging => 'Съобщения';

  @override
  String get appSettings_maxMessageRetries =>
      'Максимален брой опити за изпращане на съобщение';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Брой опити за повторно изпращане, преди съобщението да бъде маркирано като неуспешно.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Макс. повторни опити за съобщения в канал';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Толкова пъти ще опитва отново, докато не чуе поне едно повторение';

  @override
  String get appSettings_battery => 'Батерия';

  @override
  String get appSettings_batteryChemistry => 'Химия на батерията';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Зададено за устройство ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Свържете се с устройство, за да изберете.';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'Литиево желязо фосфат (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'Литиев полимер (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => 'Карта за показване';

  @override
  String get appSettings_showRepeaters => 'Показване на повторители';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Показване на възпроизвеждащи се възли на картата';

  @override
  String get appSettings_showChatNodes => 'Покажи Възли на Чат';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Показване на чат възли на картата';

  @override
  String get appSettings_showOtherNodes => 'Покажи други възли';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Покажи други типове възли на картата';

  @override
  String get appSettings_timeFilter => 'Филтриране по време';

  @override
  String get appSettings_timeFilterShowAll => 'Покажи всички възли';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Покажи възли от последните $hours часа';
  }

  @override
  String get appSettings_mapTimeFilter => 'Филтри за време на картата';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Покажи възлите, открити в:';

  @override
  String get appSettings_allTime => 'Всичко време';

  @override
  String get appSettings_lastHour => 'Последната минута';

  @override
  String get appSettings_last6Hours => 'Последни 6 часа';

  @override
  String get appSettings_last24Hours => 'Последно 24 часа';

  @override
  String get appSettings_lastWeek => 'Миналата седмица';

  @override
  String get appSettings_unitsTitle => 'единици';

  @override
  String get appSettings_unitsMetric => 'Метрика (m / km)';

  @override
  String get appSettings_unitsImperial => 'Имперска (ft / mi)';

  @override
  String get appSettings_debugCard => 'Отстрани';

  @override
  String get appSettings_appDebugLogging =>
      'Логване за отстраняване на грешки на приложението';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Записване на съобщения за отстраняване на грешки от приложението за отстраняване на грешки.';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Режимът за отстраняване на грешки в приложението е активиран.';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Логването за отстраняване на грешки в приложението е изключено.';

  @override
  String get appSettings_incrementalContactSync =>
      'Частична синхронизация на контактите';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'При повторно свързване иска от радиото само контактите, променени от последния път';

  @override
  String get contacts_title => 'Контакти';

  @override
  String get contacts_noContacts => 'Няма контакти към момента.';

  @override
  String get contacts_shareMyQrCode => 'Сподели моя QR код';

  @override
  String get contacts_shareQrCodeDesc =>
      'Другите могат да го сканират, за да ви добавят като контакт';

  @override
  String get contacts_contactsWillAppear =>
      'Контактите ще се появят, когато устройствата рекламират.';

  @override
  String get contacts_unread => 'Непрочетено';

  @override
  String get contacts_searchContactsNoNumber => 'Търси контакти...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Търсене на контакти...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Търсене на $number$str любими...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Търсене на $number$str потребители...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Търсене на $number$str повтарящи се...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Търсене на $number$str сървъри в стаята...';
  }

  @override
  String get contacts_noUnreadContacts => 'Няма непрочетени контакти';

  @override
  String get contacts_noContactsFound => 'Няма намерени контакти или групи.';

  @override
  String get contacts_deleteContact => 'Изтрий Контакт';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Сигурни ли сте, че искате да изтриете $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Контактът $contactName е изтрит.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Неуспешно изтриване на $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Няма контакти, отговарящи на филтъра.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Изтрий $contactName от контактите?';
  }

  @override
  String get contacts_manageRepeater => 'Управление на Повтарящ се Елемент';

  @override
  String get contacts_manageRoom => 'Управление на сървър за стая';

  @override
  String get contacts_roomLogin => 'Вход в стаята';

  @override
  String get contacts_openChat => 'Отвори чат';

  @override
  String get contacts_editGroup => 'Редактирай Група';

  @override
  String get contacts_deleteGroup => 'Изтрий група';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Премахнете \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Нова група';

  @override
  String get contacts_groupName => 'Група';

  @override
  String get contacts_groupNameRequired => 'Името на групата е задължително.';

  @override
  String get contacts_groupNameReserved => 'Това име на група е запазено';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Групата \"$name\" вече съществува.';
  }

  @override
  String get contacts_filterContacts => 'Филтрирайте контактите...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Няма съвпадения с вашия филтър.';

  @override
  String get contacts_noMembers => 'Няма членове';

  @override
  String get contacts_lastSeenNow => 'Последно видяно сега';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Последна активност $minutes минути преди';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Последно видяно преди час';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Последно видян $hours часа преди.';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Последно видяно преди 1 ден';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Последно видян $days дни преди.';
  }

  @override
  String get contact_info => 'Контактна информация';

  @override
  String get contact_settings => 'Настройки за контакти';

  @override
  String get contact_telemetry => 'Телеметрия';

  @override
  String get contact_lastSeen => 'Последно видян';

  @override
  String get contact_clearChat => 'Изчисти чата';

  @override
  String get contact_teleBase => 'Базата данни за телеметрия';

  @override
  String get contact_teleBaseSubtitle =>
      'Позволи споделяне на ниво на батерията и основна телеметрия';

  @override
  String get contact_teleLoc => 'Местоположение на телеметрията';

  @override
  String get contact_teleLocSubtitle =>
      'Позволи споделяне на данни за местоположение';

  @override
  String get contact_teleEnv => 'Среда на телеметрия';

  @override
  String get contact_teleEnvSubtitle =>
      'Позволи споделяне на данни от средносферните датчици';

  @override
  String get contacts_publicKey => 'Публичен ключ';

  @override
  String get channels_title => 'Канали';

  @override
  String get channels_noChannelsConfigured => 'Няма конфигурирани канали';

  @override
  String get channels_addPublicChannel => 'Добави публичен канал';

  @override
  String get channels_searchChannels => 'Търсене на канали...';

  @override
  String get channels_noChannelsFound => 'Няма намерени канали';

  @override
  String channels_channelIndex(int index) {
    return 'Канал $index';
  }

  @override
  String get channels_hashtagChannel => 'Канал с хаштаг';

  @override
  String get channels_public => 'Публично';

  @override
  String get channels_private => 'Личен';

  @override
  String get channels_publicChannel => 'Публичен канал';

  @override
  String get channels_privateChannel => 'Частен канал';

  @override
  String get channels_editChannel => 'Редактирай канал';

  @override
  String get channels_shareChannel => 'Сподели канала';

  @override
  String get channels_shareChannelInstructions =>
      'Сканирайте QR кода, за да добавите канала.\nМеню → Добави Канал → Сканирайте QR код';

  @override
  String get channels_secretKey => 'Таен ключ';

  @override
  String get channels_meshcoreUri => 'URI на MeshCore';

  @override
  String get channels_shareChannelQr => 'Сканирай QR кода на канал';

  @override
  String get channels_shareChannelWarning =>
      'Внимание: всеки, който сканира този QR код, ще има достъп до този канал.';

  @override
  String get channels_muteChannel => 'Заглуши канала';

  @override
  String get channels_unmuteChannel => 'Включи известията на канала';

  @override
  String get channels_deleteChannel => 'Изтрий канала';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Изтрий \"$name\"? Това не може да бъде отменено.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Неуспешно изтриване на канала \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Каналът \"$name\" е изтрит';
  }

  @override
  String get channels_addChannel => 'Добави Канал';

  @override
  String get channels_channelIndexLabel => 'Индекс на канал';

  @override
  String get channels_channelName => 'Име на канала';

  @override
  String get channels_usePublicChannel => 'Използвайте публичен канал';

  @override
  String get channels_standardPublicPsk => 'Стандартен публичен PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Генерирай случайна PSK';

  @override
  String get channels_enterChannelName => 'Моля, въведете име на канал.';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK трябва да бъде 32 шестнаредни знака.';

  @override
  String get channels_addChannelConfirmation =>
      'Искате ли да добавите следния канал?';

  @override
  String get channels_channelAddedSuccess => 'Каналът е добавен успешно.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Няма свободни места за канали.';

  @override
  String get appSettings_mentionNotifications => 'Известия за споменавания';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Когато някой ви спомене или ви отговори — дори в заглушени канали';

  @override
  String notification_mentionIn(String channelName) {
    return 'Споменаване в $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Каналът \"$name\" е добавен';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Редактирай Канал $index';
  }

  @override
  String get channels_smazCompression => 'Компресия SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Каналът \"$name\" е актуализиран';
  }

  @override
  String get channels_publicChannelAdded => 'Публичен канал добавен';

  @override
  String get channels_sortBy => 'Сортирай по';

  @override
  String get channels_sortManual => 'Ръчно';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Последни съобщения';

  @override
  String get channels_sortUnread => 'Непрочетено';

  @override
  String get channels_createPrivateChannel => 'Създай Частен Канал';

  @override
  String get channels_createPrivateChannelDesc => 'Защитено с таен ключ.';

  @override
  String get channels_joinPrivateChannel => 'Присъедини се към Частен Канал';

  @override
  String get channels_joinPrivateChannelDesc => 'Ръчно въведете таен ключ.';

  @override
  String get channels_joinPublicChannel =>
      'Присъединете се към Публичния канал';

  @override
  String get channels_joinPublicChannelDesc =>
      'Всеки може да се присъедини към този канал.';

  @override
  String get channels_joinHashtagChannel => 'Присъедини се към Хаштаг Канал';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Всеки може да се присъедини към хаштаговите канали.';

  @override
  String get channels_scanQrCode => 'Сканирайте QR код';

  @override
  String get channels_scanQrCodeComingSoon => 'Ще излезе скоро';

  @override
  String get channels_enterHashtag => 'Въведете хаштаг';

  @override
  String get channels_hashtagHint => 'напр. #отбор';

  @override
  String get chat_noMessages => 'Няма съобщения.';

  @override
  String get chat_sendMessage => 'Изпратете съобщение';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Изпрати съобщение на $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Изпрати съобщение, за да започнеш.';

  @override
  String get chat_originalMessageNotFound => 'Съобщението не е намерено';

  @override
  String chat_replyingTo(String name) {
    return 'Отговарям на $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Отговори на $name';
  }

  @override
  String get chat_location => 'Местоположение';

  @override
  String get common_copiedToClipboard => 'Копирано в клипборда';

  @override
  String get common_copyToClipboard => 'Копирай в клипборда';

  @override
  String get contacts_copyContactToClipboard =>
      'Копирай моя контакт в клипборда';

  @override
  String get chat_typeMessage => 'Въведете съобщение...';

  @override
  String get chat_searchMessages => 'Търсене на съобщения';

  @override
  String get chat_searchNoMatches => 'Няма съвпадения';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Съобщението е твърде дълго (макс $maxBytes байта).';
  }

  @override
  String get chat_messageCopied => 'Съобщението е копирано';

  @override
  String get chat_messageDeleted => 'Съобщението е изтрито';

  @override
  String get chat_sendGif => 'Изпрати GIF';

  @override
  String get chat_reply => 'Отговори';

  @override
  String get chat_newMessages => 'НОВИ СЪОБЩЕНИЯ';

  @override
  String get chat_addReaction => 'Добави Реакция';

  @override
  String get chat_mention => 'Споменаване';

  @override
  String get dmChannel_menuLabel => 'Лично съобщение';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Лично съобщение до $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Проверете ключа и кога е видян последно — имената не са уникални.';

  @override
  String get dmChannel_warningTitle => 'Наистина ли е този човек?';

  @override
  String get dmChannel_warningBody =>
      'Имената в каналите се избират свободно и всеки може да ги имитира. За нещо поверително първо проверете публичния ключ на този контакт по друг начин.';

  @override
  String get dmChannel_dontShowAgain => 'Не показвай отново';

  @override
  String get batterySleep_title => 'Нека MeshTrax работи';

  @override
  String get batterySleep_bodySamsung =>
      'Телефоните Samsung приспиват приложенията, за да пестят батерия, и това прекъсва връзката с радиото. Отворете Настройки → Приложения → MeshTrax → Батерия и изберете „Неограничено“. Проверете и Батерия → Ограничения за използване във фонов режим и се уверете, че MeshTrax не е в „Спящи приложения“ или „Приложения в дълбок сън“.';

  @override
  String get batterySleep_bodyGeneric =>
      'Телефонът може да спира MeshTrax във фонов режим, за да пести батерия, и това прекъсва връзката с радиото. Отворете настройките на батерията и задайте за MeshTrax „Неограничено“ (или „Без ограничения“). На някои телефони трябва да включите и „Автоматично стартиране“ за MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Отвори настройките';

  @override
  String get batterySleep_notNow => 'Не сега';

  @override
  String get batterySleep_settingsTile => 'MeshTrax да работи във фонов режим';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Пестенето на батерия да не приспива MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Още не можете да пишете на $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Още нямате ключа им, а на тях им трябва вашият, за да отговорят — ключовете се пренасят само в обяви. „Изпрати моята обява“ разпраща вашата оттук. „Попитай в канала“ написва молба в полето за съобщение, за да я изпратите.';

  @override
  String get dmChannel_askInChannel => 'Попитай в канала';

  @override
  String get dmChannel_sendMyAdvert => 'Изпрати моята обява';

  @override
  String get dmChannel_askText =>
      'моля, изпратете обява, за да мога да ви пиша лично';

  @override
  String get dmChannel_watching =>
      'Чакаме обявата им — ще бъдете попитани тук, когато пристигне.';

  @override
  String dmChannel_advertHeard(String name) {
    return 'Вече можете да се свържете с $name';
  }

  @override
  String get dmChannel_openDm => 'Пиши';

  @override
  String get appSettings_zoomLevel => 'Ниво на мащабиране';

  @override
  String get common_reset => 'Нулиране';

  @override
  String get chat_reactionsTitle => 'Реакции';

  @override
  String get chat_reactionUnknownSender => 'Неизвестен';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender: реакция на съобщение, което не е в този чат';
  }

  @override
  String get chat_me => 'Аз';

  @override
  String get emojiCategorySmileys => 'Емотикони';

  @override
  String get emojiCategoryGestures => 'Жестове';

  @override
  String get emojiCategoryHearts => 'Сърца';

  @override
  String get emojiCategoryObjects => 'Обекти';

  @override
  String get gifPicker_title => 'Изберете GIF';

  @override
  String get gifPicker_searchHint => 'Търсене на GIF-ове...';

  @override
  String get gifPicker_poweredBy => 'Задвижвано от GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Няма намерени GIF файлове.';

  @override
  String get gifPicker_failedLoad => 'Не можа да се заредят GIF файловете';

  @override
  String get gifPicker_failedSearch => 'Неуспешно търсене на GIF-ове';

  @override
  String get gifPicker_noInternet => 'Няма интернет връзка';

  @override
  String get debugLog_appTitle =>
      'Лог на отстраняване на грешки на приложението';

  @override
  String get debugLog_bleTitle => 'Лог за отстраняване на грешки на BLE';

  @override
  String get debugLog_copyLog => 'Копирай лог';

  @override
  String get debugLog_saveLog => 'Запази лога във файл';

  @override
  String get debugLog_saved => 'Логът е запазен';

  @override
  String get debugLog_saveCancelled => 'Запазването е отказано';

  @override
  String get debugLog_filterAll => 'Всички';

  @override
  String get debugLog_filterWarnings => 'Предупреждения';

  @override
  String get debugLog_filterErrors => 'Грешки';

  @override
  String get debugLog_clearLog => 'Изчисти логовете';

  @override
  String get debugLog_copied => 'Копирано лого за отстраняване на грешки';

  @override
  String get debugLog_bleCopied => 'Копиран лог от BLE';

  @override
  String get debugLog_noEntries => 'Все още няма дебъг логове.';

  @override
  String get debugLog_enableInSettings =>
      'Активирайте отстраняване на грешки в настройките на приложението';

  @override
  String get debugLog_frames => 'Рамки';

  @override
  String get debugLog_rawLogRx => 'Raw Log-RX';

  @override
  String get debugLog_noBleActivity => 'Няма BLE активност към момента.';

  @override
  String debugFrame_length(int count) {
    return 'Дължина на кадъра: $count байта';
  }

  @override
  String debugFrame_command(String value) {
    return 'Команда: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Съобщение:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Дестинация Публичен Ключ: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Време: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Флагове: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Тип текст: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'CLI команда';

  @override
  String get debugFrame_textTypePlain => 'Просто';

  @override
  String debugFrame_text(String text) {
    return '- Текст: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Хексадесетичен Dump:';

  @override
  String get chat_hopSingular => 'скочи';

  @override
  String get chat_hopPlural => 'скоци';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Задайте персонализиран път';

  @override
  String get chat_fullPath => 'Пълен път';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Детайлите за пътя все още не са налични. Опитайте да изпратите съобщение, за да освежите.';

  @override
  String get chat_type => 'Въведете';

  @override
  String get chat_path => 'Пътекино';

  @override
  String get chat_publicKey => 'Публичен ключ';

  @override
  String get chat_compressOutgoingMessages =>
      'Компресиране на изходящи съобщения';

  @override
  String get chat_floodForced => 'Потоп (принуден)';

  @override
  String get chat_directForced => 'Директно (принудително)';

  @override
  String chat_hopsForced(int count) {
    return '$count скока (принудително)';
  }

  @override
  String get chat_floodAuto => 'Потоп (автоматично)';

  @override
  String get chat_direct => 'Директно';

  @override
  String get chat_poiShared => 'Споделено място от интерес';

  @override
  String chat_unread(int count) {
    return 'Непрочетени: $count';
  }

  @override
  String get chat_openLink => 'Отваряне на връзката?';

  @override
  String get chat_openLinkConfirmation =>
      'Искате ли да отворите тази връзка в браузъра си?';

  @override
  String get chat_open => 'Отвори';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Не можа да се отвори връзката: $url';
  }

  @override
  String get chat_invalidLink => 'Невалиден формат на връзката';

  @override
  String get map_lineOfSight => 'Линия на видимост';

  @override
  String get map_losScreenTitle => 'Линия на видимост';

  @override
  String get map_noNodesWithLocation => 'Няма възли с данни за местоположение.';

  @override
  String get map_nodesNeedGps =>
      'Възлагат се възлозите да споделят техните GPS координати,\nза да се появят на картата.';

  @override
  String map_nodesCount(int count) {
    return 'Нодове: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Ключове: $count';
  }

  @override
  String get map_chat => 'Чат';

  @override
  String get map_repeater => 'Повтарящ се';

  @override
  String get map_room => 'Стая';

  @override
  String get map_sensor => 'Датчик';

  @override
  String get map_pinDm => 'Задържане (DM)';

  @override
  String get map_pinPrivate => 'Задържане (Приватно)';

  @override
  String get map_pinPublic => 'Публичен ключ';

  @override
  String get map_lastSeen => 'Последна видяна';

  @override
  String get map_disconnectConfirm =>
      'Сигурни ли сте, че искате да се откъснете от това устройство?';

  @override
  String get map_from => 'От';

  @override
  String get map_source => 'Източник';

  @override
  String get map_flags => 'Флаг';

  @override
  String get map_shareMarkerHere => 'Споделете маркер тук';

  @override
  String get map_setAsMyLocation => 'Задайте като моя местоположение';

  @override
  String get map_pinLabel => 'Етикетиране на пин';

  @override
  String get map_label => 'Етикет';

  @override
  String get map_pointOfInterest => 'Точка на интерес';

  @override
  String get map_sendToContact => 'Изпрати на контакт';

  @override
  String get map_sendToChannel => 'Изпрати в канала';

  @override
  String get map_noChannelsAvailable => 'Няма налични канали';

  @override
  String get map_publicLocationShare => 'Споделяне на публично място';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Ще споделите местоположение в $channelLabel. Този канал е публичен и всеки с PSK може да го види.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Свържете се с устройство, за да споделите маркери.';

  @override
  String get map_filterNodes => 'Филтрирайте възли';

  @override
  String get map_chatNodes => 'Възли на чата';

  @override
  String get map_repeaters => 'Повторители';

  @override
  String get map_otherNodes => 'Други възли';

  @override
  String get map_showOverlaps => 'Покриване на ключа на повтаряча';

  @override
  String get map_keyPrefix => 'Префикс на ключа';

  @override
  String get map_filterByKeyPrefix => 'Филтрирайте по префикс на ключ';

  @override
  String get map_publicKeyPrefix => 'Префикс на публичен ключ';

  @override
  String get map_showDiscoveryContacts => 'Покажи контакти за откриване';

  @override
  String get map_guessedLocation => 'Предполагано местоположение';

  @override
  String get map_lastSeenTime => 'Последна видяна дата';

  @override
  String get map_sharedPin => 'Споделено копие';

  @override
  String get map_joinRoom => 'Присъедини се към стаята';

  @override
  String get map_manageRepeater => 'Управление на Повтарящ се Елемент';

  @override
  String get map_tapToAdd =>
      'Натиснете върху възлите, за да ги добавите към пътя.';

  @override
  String get map_runTrace => 'Изпълни Път на Следване';

  @override
  String get map_runTraceWithReturnPath => 'Върни се по същия път.';

  @override
  String get map_removeLast => 'Премахни Последно';

  @override
  String get map_pathTraceCancelled => 'Отменен е следването на пътя.';

  @override
  String get time_justNow => 'Сега';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes минути преди';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours часа преди';
  }

  @override
  String time_daysAgo(int days) {
    return '$days дни преди';
  }

  @override
  String get time_hour => 'час';

  @override
  String get time_hours => 'часове';

  @override
  String get time_day => 'ден';

  @override
  String get time_days => 'дни';

  @override
  String get time_week => 'седмица';

  @override
  String get time_weeks => 'секти';

  @override
  String get time_month => 'месец';

  @override
  String get time_months => 'месеци';

  @override
  String get time_minutes => 'минути';

  @override
  String get time_allTime => 'Всичко време';

  @override
  String get dialog_disconnect => 'Прекъсни';

  @override
  String get dialog_disconnectConfirm =>
      'Сигурни ли сте, че искате да се откъснете от това устройство?';

  @override
  String get login_repeaterLogin => 'Повторител Вход';

  @override
  String get login_roomLogin => 'Вход в стаята';

  @override
  String get login_password => 'Парола';

  @override
  String get login_enterPassword => 'Въведете парола';

  @override
  String get login_savePassword => 'Запази парола';

  @override
  String get login_savePasswordSubtitle =>
      'Паролата ще бъде съхранена сигурно на това устройство.';

  @override
  String get login_repeaterDescription =>
      'Въведете паролата на репитера, за да получите достъп до настройките и статуса.';

  @override
  String get login_roomDescription =>
      'Въведете паролата на стаята, за да получите достъп до настройките и статуса.';

  @override
  String get login_login => 'Вход';

  @override
  String login_attempt(int current, int max) {
    return 'Опитвате $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Входът не беше успешен: $error';
  }

  @override
  String get login_failedMessage =>
      'Входът не беше успешен. Или паролата е грешна, или повторителят е недостъпен.';

  @override
  String get common_reload => 'Презареди';

  @override
  String get common_clear => 'Изчисти';

  @override
  String get path_enterCustomPath => 'Въведете персонализиран път';

  @override
  String get path_currentPathLabel => 'Текущ път';

  @override
  String get path_hexPrefixInstructions =>
      'Въведете 2-символни шестнадесетични префикси за всеки хоп, разделени с кама.';

  @override
  String get path_hexPrefixExample =>
      'A1,F2,3C (всяка нода използва първия байт от публичния си ключ)';

  @override
  String get path_labelHexPrefixes => 'Пътеки (шестнадесетични префикси)';

  @override
  String get path_helperMaxHops =>
      'Максимум 64 скока. Всеки префикс е 2 шестнадесетични знака (1 байт).';

  @override
  String get path_selectFromContacts => 'Изберете от контакти:';

  @override
  String get path_noRepeatersFound =>
      'Няма намерени репетитори или сървъри на стаи.';

  @override
  String get path_customPathsRequire =>
      'Персонализираните пътища изискват междинни скокове, които могат да препращат съобщения.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Невалидни шестнадесетични префикси: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Пътят е твърде дълъг. Максимум 64 скока са разрешени.';

  @override
  String get path_setPath => 'Задайте път';

  @override
  String get repeater_management => 'Управление на повторители';

  @override
  String get room_management => 'Управление на сървъра за стая';

  @override
  String get repeater_guest => 'Информация за ретранслаторите';

  @override
  String get room_guest => 'Информация за сървъра на стаята';

  @override
  String get repeater_managementTools => 'Инструменти за управление';

  @override
  String get repeater_guestTools => 'Инструменти за гости';

  @override
  String get repeater_status => 'Статус';

  @override
  String get repeater_statusSubtitle =>
      'Прегледайте статуса, статистиката и съседните устройства.';

  @override
  String get repeater_telemetry => 'Телеметрия';

  @override
  String get repeater_telemetrySubtitle =>
      'Прегледайте телеметрията на сензорите и системните статистики';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Изпрати команди към ретранслатора';

  @override
  String get repeater_neighbors => 'Съседи';

  @override
  String get repeater_neighborsSubtitle =>
      'Преглед на съседни възли с нулев скок.';

  @override
  String get repeater_settings => 'Настройки';

  @override
  String get repeater_settingsSubtitle =>
      'Конфигурирайте параметрите на репитера';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Синхронизиране на часовника след влизане';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Автоматично изпращайте съобщение \"синхронизиране на часовника\" след успешно влизане.';

  @override
  String get repeater_statusTitle => 'Статус на повтарянето';

  @override
  String get repeater_refresh => 'Презареди';

  @override
  String get repeater_statusRequestTimeout =>
      'Заявката за статус премина прекалено дълго.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Грешка при зареждане на статуса: $error';
  }

  @override
  String get repeater_systemInformation => 'Информация за системата';

  @override
  String get repeater_battery => 'Батерия';

  @override
  String get repeater_clockAtLogin => 'Часовник (при влизане)';

  @override
  String get repeater_uptime => 'Наличност';

  @override
  String get repeater_queueLength => 'Дължина на опашката';

  @override
  String get repeater_debugFlags => 'Контролни точки за отстраняване на грешки';

  @override
  String get repeater_radioStatistics => 'Статистика на радиостанциите';

  @override
  String get repeater_lastRssi => 'Последна RSSI';

  @override
  String get repeater_lastSnr => 'Последна SNR';

  @override
  String get repeater_noiseFloor => 'Ниво на шум';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Статистика на пакетите';

  @override
  String get repeater_sent => 'Изпратено';

  @override
  String get repeater_received => 'Получено';

  @override
  String get repeater_duplicates => 'Дубликати';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days дни $hoursч $minutesм $secondsс';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Общо: $total, Наводнение: $flood, Директно: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Общо: $total, Наводнение: $flood, Директно: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Поливане: $flood, Директен: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Общо: $total';
  }

  @override
  String get repeater_settingsTitle => 'Настройки на повтарящия се елемент';

  @override
  String get repeater_basicSettings => 'Основни настройки';

  @override
  String get repeater_repeaterName => 'Име на повтарящ се елемент';

  @override
  String get repeater_repeaterNameHelper =>
      'Показване на името на този репитер';

  @override
  String get repeater_adminPassword => 'Парола на администратора';

  @override
  String get repeater_adminPasswordHelper => 'Пълен достъпен парола';

  @override
  String get repeater_guestPassword => 'Парола на гост';

  @override
  String get repeater_guestPasswordHelper => 'Достъп с ограничен достъп';

  @override
  String get repeater_radioSettings => 'Настройки на радиостанцията';

  @override
  String get repeater_frequencyMhz => 'Честота (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Ширина на честотния спектър';

  @override
  String get repeater_spreadingFactor => 'Фактор на разпространение';

  @override
  String get repeater_codingRate => 'Такса за кодиране';

  @override
  String get repeater_locationSettings => 'Настройки на местоположението';

  @override
  String get repeater_latitude => 'Широчина';

  @override
  String get repeater_latitudeHelper => 'Десетични градуси (напр. 37.7749)';

  @override
  String get repeater_longitude => 'Дължина';

  @override
  String get repeater_longitudeHelper =>
      'Градуси с десетични знаци (напр. -122.4194)';

  @override
  String get repeater_features => 'Характеристики';

  @override
  String get repeater_packetForwarding => 'Пренасочване на пакети';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Активирайте репитера, за да препращате пакети.';

  @override
  String get repeater_guestAccess => 'Достъп за Гост';

  @override
  String get repeater_guestAccessSubtitle => 'Разрешете самочетене за гости';

  @override
  String get repeater_privacyMode => 'Режим на поверителност';

  @override
  String get repeater_privacyModeSubtitle =>
      'Скриване на име/местоположение в рекламите';

  @override
  String get repeater_advertisementSettings => 'Настройки на рекламите';

  @override
  String get repeater_localAdvertInterval => 'Местен Рекламен Интервал';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes минути';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Интервал на рекламата за наводнения';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours часа';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Криптиран Рекламен Интервал';

  @override
  String get repeater_dangerZone =>
      'Опасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно Безопасно';

  @override
  String get repeater_rebootRepeater => 'БеРестартирай Репитер';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Рестартирайте ретранслатора.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Сигурни ли сте, че искате да рестартирате този репитер?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Генериране на Ключ за Идентичност';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Генериране на нова двойка публичен/частен ключ';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'БеТова ще генерира нова идентичност за репитера. Продължете?';

  @override
  String get repeater_eraseFileSystem => 'Изтрий Файлова Система';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Форматирайте файла на репитера';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ВНИМАНИЕ: Това ще изтрие всички данни от репетитора. Това не може да бъде отменено!';

  @override
  String get repeater_eraseSerialOnly =>
      'Изтриването е достъпно само през серийния терминал.';

  @override
  String repeater_commandSent(String command) {
    return 'Командата е изпратена: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Грешка при изпращане на командата: $error';
  }

  @override
  String get repeater_confirm => 'БеПотвърди';

  @override
  String get repeater_settingsSaved => 'Настройките са запазени успешно.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Грешка при запазване на настройките: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Обнови Основни Настройки';

  @override
  String get repeater_refreshRadioSettings =>
      'Обнови настройките на радиопредавателите';

  @override
  String get repeater_refreshTxPower => 'Обнови TX захранване';

  @override
  String get repeater_refreshLocationSettings =>
      'Обнови настройките на местоположението';

  @override
  String get repeater_refreshPacketForwarding => 'Обнови пакетно пренасочване';

  @override
  String get repeater_refreshGuestAccess => 'Обнови достъп за гости';

  @override
  String get repeater_refreshPrivacyMode => 'Обнови Режим на поверителност';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Обнови Настройки на Рекламата';

  @override
  String repeater_refreshed(String label) {
    return '$label е обновено';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Грешка при обновяване на $label';
  }

  @override
  String get repeater_cliTitle => 'Повторител CLI';

  @override
  String get repeater_debugNextCommand => 'Поправи Следваща Команда';

  @override
  String get repeater_commandHelp => 'Помощ';

  @override
  String get repeater_clearHistory => 'Изчисти История';

  @override
  String get repeater_noCommandsSent => 'Няма изпратени команди засега.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Въведете команда по-долу или използвайте бързи команди';

  @override
  String get repeater_enterCommandHint => 'Въведете команда...';

  @override
  String get repeater_previousCommand => 'Предходна команда';

  @override
  String get repeater_nextCommand => 'Следваща команда';

  @override
  String get repeater_enterCommandFirst => 'Въведете първо команда.';

  @override
  String get repeater_cliCommandFrameTitle => 'Рамка за команда CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Грешка: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Получи име';

  @override
  String get repeater_cliQuickGetRadio => 'Получи радио';

  @override
  String get repeater_cliQuickGetTx => 'Получи TX';

  @override
  String get repeater_cliQuickNeighbors => 'Съседи';

  @override
  String get repeater_cliQuickVersion => 'Версия';

  @override
  String get repeater_cliQuickAdvertise => 'Рекламирай';

  @override
  String get repeater_cliQuickClock => 'Часовник';

  @override
  String get repeater_cliQuickClockSync => 'Синхронизация на часовника';

  @override
  String get repeater_cliQuickDiscovery => 'Открий Съседи';

  @override
  String get repeater_cliHelpAdvert => 'Изпраща рекламен пакет';

  @override
  String get repeater_cliHelpReboot =>
      'Рестартира устройството. (Забележка, може да получите \'Timeout\', което е нормално)';

  @override
  String get repeater_cliHelpClock =>
      'Показва текущото време според часовника на всяко устройство.';

  @override
  String get repeater_cliHelpPassword =>
      'Задава се нова администраторска парола за устройството.';

  @override
  String get repeater_cliHelpVersion =>
      'Показва версията на устройството и датата на компилация на фърмуера.';

  @override
  String get repeater_cliHelpClearStats =>
      'Рестартира различни статистики броячи до нула.';

  @override
  String get repeater_cliHelpSetAf => 'Задава времето на фактора.';

  @override
  String get repeater_cliHelpSetTx =>
      'Задава се мощността на предаване на LoRa в dBm (отчитане спрямо референтно ниво).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Активира или деактивира ролята на репитера за този възел.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Сървър на стаята) Ако е \"включено\", тогава влизането с празен парола ще бъде разрешено, но не може да публикува в стаята (само четене).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Задава максималния брой хопове на входящ пакет за заливване (ако >= max, пакетът не се предава).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Задава праг на интерференцията (в dB). По подразбиране е 14. Задайте на 0, за да деактивирате откриването на интерференция на каналите.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Задава интервала за рестартиране на Автоматичния контролер за усилване. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Активира или деактивира функцията \'двойни ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Задава интервала на таймера в минути за изпращане на локален (безпроблемен) рекламен пакет. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Задава интервала на таймера в часове за изпращане на пакет с реклама за наводнение. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Задава/обновява паролата на гост. (за повторители, гостите могат да изпращат заявката \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Задава име на обявата.';

  @override
  String get repeater_cliHelpSetLat =>
      'Задава географска ширина на картата с реклами (в десетими градуси).';

  @override
  String get repeater_cliHelpSetLon =>
      'Задава обхвата на дължина на картата на рекламата. (десетими градуса)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Задава напълно нови радио параметри и ги запазва в предпочитанията. Изисква команда \"рестарт\", за да бъдат приложени.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Зададени (експериментални) основи (трябва да е > 1 за ефект) за прилагане на леко забавяне на получените пакети, базирано на силата на сигнала/резултата. Задайте на 0, за да го деактивирате.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Задава фактор, умножен по времето на въздух за пакет в режим на наводнение и с рандомизирана система за слотове, за да забави предаването му (за да намали вероятността от сблъсъци).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Същото като txdelay, но за прилагане на случайна забавяне при препращането на пакети в директен режим.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Активиране/Деактивиране на мост.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Задайте забавяне преди преизпращане на пакети.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Изберете дали мостът ще предава препратени пакети или получени пакети.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Задайте скоростта на предаване за RS232 мостовете.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Задайте тайна за мостовете на EspNow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Задава персонализиран коефициент за коригиране на отчетеното напрежение на батерията (поддържа се само на избрани дъски).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Задава временни радио параметри за посочения брой минути, връщайки се към оригиналните радио параметри след това. (не се запазва в предпочитанията).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Променя ACL. Премахва съответстващия запис (по префикс на pubkey), ако \"permissions\" е нула. Добавя нов запис, ако pubkey-hex е с пълна дължина и не е в ACL. Актуализира запис, съответстващ на префикса на pubkey. Битовете за разрешения варират според ролята на firmware, но долните 2 бита са: 0 (Гост), 1 (Само четене), 2 (Четене и писане), 3 (Администратор).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Получава тип мост none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Започва записване на пакети във файловата система.';

  @override
  String get repeater_cliHelpLogStop =>
      'Спира записването на пакети във файловата система.';

  @override
  String get repeater_cliHelpLogErase =>
      'Изтрива логовете от пакета от файловата система.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Показва списък с други възли на репитер, чути чрез нулев хоп реклами. Всяка линия е id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Премахва първия съвпадащ запис (по префикси на pubkey (hex)) от списъка с съседи.';

  @override
  String get repeater_cliHelpRegion =>
      '(сериен режим) Изброява всички дефинирани региони и текущите разрешения за наводнения.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Забележка: това е специално многокомандно извикване. Всяка следваща команда е име на регион (отстъпен с интервали, за да се покаже йерархията, с минимум един интервал). Завършва се чрез изпращане на празен ред/команда.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Търси регион с даден префикс на име (или \"\" за глобалния обхват). Отговаря с \"-> region-name (parent-name) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Добавя или актуализира дефиниция на регион с дадено име.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Премахва дефиниция на регион с дадено име. (трябва да съвпада точно и да няма подрегиони)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Задава \'Потоп\' разрешение за посочената област. (\'\' за глобалния/стария обхват)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Премахва разрешението \"F\"лоуд за посочената област. (ЗАБЕЛЕЖКА: в момента не се препоръчва да се използва на глобалното/старото ниво!! )';

  @override
  String get repeater_cliHelpRegionHome =>
      'Отговаря с текущия \'home\' регион. (Забележка: не е приложена никъде, запазена за бъдещи нужди).';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Задава \'домашно\' региона.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Запазва списъка/картата с региони в съхранение.';

  @override
  String get repeater_cliHelpGps =>
      'Показва статуса на GPS. Когато GPS е изключен, отговаря само с \"off\", ако е включен отговаря с \"on\", статус, fix, брой на сателити.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Включва/Изключва GPS захранването.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Синхронизира времето на възела с GPS часовника.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Задава координатите на нодата по GPS и запазва предпочитанията.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Предоставя конфигурацията на рекламата за местоположението на възела:\n- none: не включвайте местоположението в рекламите\n- share: споделяйте gps местоположението (от SensorManager)\n- prefs: рекламирайте местоположението, съхранено в предпочитанията';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Задава конфигурация на обявите за местоположение.';

  @override
  String get repeater_commandsListTitle => 'Списък с команди';

  @override
  String get repeater_commandsListNote =>
      'ЗАБЕЛЕЖКА: за различните команди \"set ...\", също така съществува команда \"get ...\".';

  @override
  String get repeater_general => 'Общо';

  @override
  String get repeater_settingsCategory => 'Настройки';

  @override
  String get repeater_bridge => 'Мост';

  @override
  String get repeater_logging => 'Логване';

  @override
  String get repeater_neighborsRepeaterOnly => 'Съседи (Само за повтаряне)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Управление на региони (Само за повтарящ се канал)';

  @override
  String get repeater_regionNote =>
      'Регионните команди са въведени, за да управляват дефинициите и разрешенията на регионите.';

  @override
  String get repeater_gpsManagement => 'Управление на GPS';

  @override
  String get repeater_gpsNote =>
      'GPS командата е въведена, за да управлява теми, свързани с местоположението.';

  @override
  String get telemetry_receivedData => 'Получени телеметрични данни';

  @override
  String get telemetry_requestTimeout => 'Заявката за телеметрия е прекъсната.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Грешка при зареждане на телеметрията: $error';
  }

  @override
  String get telemetry_noData => 'Няма налични данни за телеметрията.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Канал $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Батерия';

  @override
  String get telemetry_voltageLabel => 'Напрежение';

  @override
  String get telemetry_mcuTemperatureLabel => 'Температура на MCU';

  @override
  String get telemetry_temperatureLabel => 'Температура';

  @override
  String get telemetry_currentLabel => 'Текущо';

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
  String get neighbors_receivedData => 'Получени данни за съседи';

  @override
  String get neighbors_requestTimedOut => 'Съседите поискат изтичане на време.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Грешка при зареждане на съседи: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Повторители Съседи';

  @override
  String get neighbors_noData => 'Няма налични данни за съседи.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Неизвестна $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Слушано преди $time.';
  }

  @override
  String get channelPath_title => 'Пътеки пъзел';

  @override
  String get channelPath_viewMap => 'Преглед на картата';

  @override
  String get channelPath_otherObservedPaths => 'Други Наблюдавани Пътища';

  @override
  String get channelPath_repeaterHops => 'Повтарящи се скокове';

  @override
  String get channelPath_noHopDetails =>
      'Детайлите за пакета не са предоставени.';

  @override
  String get channelPath_messageDetails => 'Подробности на съобщението';

  @override
  String get channelPath_senderLabel => 'Изпращач';

  @override
  String get channelPath_timeLabel => 'Време';

  @override
  String get channelPath_repeatsLabel => 'Повтаря';

  @override
  String channelPath_pathLabel(int index) {
    return 'Път $index';
  }

  @override
  String get channelPath_observedLabel => 'Наблюдавано';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Наблюдаван път $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Няма данни за местоположение.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Неизвестно';

  @override
  String get channelPath_floodPath => 'Поливане';

  @override
  String get channelPath_directPath => 'Директно';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 от $total скокове';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed от $total скокове';
  }

  @override
  String get channelPath_mapTitle => 'Карта на пътя';

  @override
  String get channelPath_noRepeaterLocations =>
      'Няма налични местоположения на повторителите за този път.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Път $index (Основен)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Пътекино';

  @override
  String get channelPath_observedPathHeader => 'Наблюдаван път';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Няма налични детайли за този пакет.';

  @override
  String get channelPath_unknownRepeater => 'Неизвестен повторител';

  @override
  String get community_title => 'Общност';

  @override
  String get community_create => 'Създай общност';

  @override
  String get community_createDesc =>
      'Създайте нова общност и я споделете чрез QR код.';

  @override
  String get community_join => 'Присъедини се';

  @override
  String get community_joinTitle => 'Присъедини се към общността';

  @override
  String community_joinConfirmation(String name) {
    return 'Искате ли да се присъедините към общността \"$name\"?';
  }

  @override
  String get community_scanQr => 'Сканирайте QR кода на общността';

  @override
  String get community_scanInstructions =>
      'Насочете камерата към QR код на общността';

  @override
  String get community_showQr => 'Покажи QR код';

  @override
  String get community_publicChannel => 'Обществено общност';

  @override
  String get community_hashtagChannel => 'Хаштаг на общността';

  @override
  String get community_name => 'Име на общността';

  @override
  String get community_enterName => 'Въведете име на общността';

  @override
  String community_created(String name) {
    return 'Общността \"$name\" е създадена';
  }

  @override
  String community_joined(String name) {
    return 'Присъединено общност \"$name\"';
  }

  @override
  String get community_qrTitle => 'Споделяне в общността';

  @override
  String community_qrInstructions(String name) {
    return 'Сканирайте този QR код, за да се присъедините към $name.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Хаштаг каналите на общността са достъпни само за членове на общността';

  @override
  String get community_invalidQrCode => 'Невалиден QR код на общността';

  @override
  String get community_alreadyMember => 'Вече съм член';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Вие вече сте член на \"$name\".';
  }

  @override
  String get community_addPublicChannel => 'Добави публичен общностен канал';

  @override
  String get community_addPublicChannelHint =>
      'Автоматично добавете публичния канал за тази общност.';

  @override
  String get community_noCommunities => 'Няма присъединени общности още.';

  @override
  String get community_scanOrCreate =>
      'Сканирайте QR код или създайте общност, за да започнете.';

  @override
  String get community_manageCommunities => 'Управление на общности';

  @override
  String get community_delete => 'Напусни общността';

  @override
  String community_deleteConfirm(String name) {
    return 'Напускате \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Това ще изтрие също $count канал(а) и техните съобщения.';
  }

  @override
  String community_deleted(String name) {
    return 'Остави общността \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Регенерейрай секрет';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Регенерация на секретния ключ за \"$name\"? Всички членове ще трябва да сканират новия QR код, за да продължат комуникацията.';
  }

  @override
  String get community_regenerate => 'Регенерация';

  @override
  String community_secretRegenerated(String name) {
    return 'Секретно презареждане за \"$name\"';
  }

  @override
  String get community_updateSecret => 'Актуализирай тайна';

  @override
  String community_secretUpdated(String name) {
    return 'Секретно обновено за \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Сканьорвайте новия QR код, за да актуализирате секрета за \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Добави общностен хаштаг';

  @override
  String get community_addHashtagChannelDesc =>
      'Добавете хаштаг канал за тази общност';

  @override
  String get community_selectCommunity => 'Изберете общност';

  @override
  String get community_regularHashtag => 'Обикновен хаштаг';

  @override
  String get community_regularHashtagDesc =>
      'Общ хаштаг (всеки може да се присъедини)';

  @override
  String get community_communityHashtag => 'Общностен хаштаг';

  @override
  String get community_communityHashtagDesc => 'Само за членове на общността';

  @override
  String community_forCommunity(String name) {
    return 'За $name';
  }

  @override
  String get listFilter_tooltip => 'Филтрирайте и сортирайте';

  @override
  String get listFilter_sortBy => 'Сортирай по';

  @override
  String get listFilter_latestMessages => 'Последни съобщения';

  @override
  String get listFilter_heardRecently => 'Слушано е наскоро';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Филтри';

  @override
  String get listFilter_source => 'Източник';

  @override
  String get listFilter_saved => 'Запазени';

  @override
  String get listFilter_discovered => 'Открити';

  @override
  String get listFilter_all => 'Всички';

  @override
  String get listFilter_favorites => 'Любими';

  @override
  String get listFilter_addToFavorites => 'Добави към любими';

  @override
  String get listFilter_removeFromFavorites => 'Премахване от списъка с любими';

  @override
  String get listFilter_users => 'Потребители';

  @override
  String get listFilter_repeaters => 'Повторители';

  @override
  String get listFilter_roomServers => 'Сървъри на стая';

  @override
  String get listFilter_unreadOnly => 'Само непрочетените';

  @override
  String get listFilter_newGroup => 'Нова група';

  @override
  String get pathTrace_you => 'Вие';

  @override
  String get pathTrace_failed => 'Пътят за проследяване не успя.';

  @override
  String get pathTrace_notAvailable => 'Пътека за проследяване не е достъпна.';

  @override
  String get pathTrace_refreshTooltip => 'Обнови Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Един или повече от хмелите липсва местоположение!';

  @override
  String get pathTrace_clearTooltip => 'Изчисти пътя';

  @override
  String get losSelectStartEnd => 'Изберете начални и крайни възли за LOS.';

  @override
  String losRunFailed(String error) {
    return 'Проверката на пряката видимост е неуспешна: $error';
  }

  @override
  String get losClearAllPoints => 'Изчистете всички точки';

  @override
  String get losRunToViewElevationProfile =>
      'Стартирайте LOS, за да видите профила на надморската височина';

  @override
  String get losMenuTitle => 'LOS меню';

  @override
  String get losMenuSubtitle =>
      'Докоснете възли или натиснете продължително карта за персонализирани точки';

  @override
  String get losShowDisplayNodes => 'Показване на възли на дисплея';

  @override
  String get losCustomPoints => 'Персонализирани точки';

  @override
  String losCustomPointLabel(int index) {
    return 'Персонализирано $index';
  }

  @override
  String get losPointA => 'Точка А';

  @override
  String get losPointB => 'Точка Б';

  @override
  String losAntennaA(String value, String unit) {
    return 'Антена A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Антена B: $value $unit';
  }

  @override
  String get losRun => 'Стартирайте LOS';

  @override
  String get losNoElevationData => 'Няма данни за надморска височина';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, чист LOS, минимално разстояние $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, блокиран от $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: проверка...';

  @override
  String get losStatusNoData => 'LOS: няма данни';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total ясно, $blocked блокирано, $unknown неизвестно';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Няма налични данни за надморска височина за една или повече проби.';

  @override
  String get losErrorInvalidInput =>
      'Невалидни данни за точки/надморска височина за изчисляване на LOS.';

  @override
  String get losRenameCustomPoint => 'Преименувайте персонализирана точка';

  @override
  String get losPointName => 'Име на точката';

  @override
  String get losShowPanelTooltip => 'Показване на LOS панел';

  @override
  String get losHidePanelTooltip => 'Скриване на LOS панела';

  @override
  String get losElevationAttribution =>
      'Данни за надморска височина: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Радиохоризонт';

  @override
  String get losLegendLosBeam => 'Линия на видимост';

  @override
  String get losLegendTerrain => 'Терен';

  @override
  String get losFrequencyLabel => 'Честота';

  @override
  String get losFrequencyInfoTooltip => 'Преглед на детайли за изчислението';

  @override
  String get losFrequencyDialogTitle => 'Изчисляване на радиохоризонта';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Започвайки от k=$baselineK при $baselineFreq MHz, изчислението коригира k-фактора за текущата $frequencyMHz MHz лента, която определя границата на извития радиохоризонт.';
  }

  @override
  String get contacts_pathTrace => 'Пътен проследяване';

  @override
  String get contacts_ping => 'Пинг';

  @override
  String get contacts_repeaterPathTrace => 'Трасировка до повторител';

  @override
  String get contacts_repeaterPing => 'Пингване на повторителя';

  @override
  String get contacts_roomPathTrace => 'Трасиране на път до съ';

  @override
  String get contacts_roomPing => 'Ping на сървъра на стаята';

  @override
  String get contacts_chatTraceRoute => 'Трасиране на път';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Проследи маршрут към $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Клипборда е празна.';

  @override
  String get contacts_invalidAdvertFormat => 'Невалидни данни за контакт';

  @override
  String get contacts_contactImported => 'Контактът е импортиран.';

  @override
  String get contacts_contactImportFailed =>
      'Контактът не е успешно импортиран.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name вече е в контактите ви.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Реклама без скок';

  @override
  String get contacts_floodAdvert => 'Потопна реклама';

  @override
  String get contacts_copyAdvertToClipboard => 'Копирай обявата в клипборда';

  @override
  String get contacts_addContactFromClipboard => 'Добави контакт от клипборда';

  @override
  String get contacts_ShareContact => 'Копирай контакт в клипборда';

  @override
  String get contacts_ShareContactZeroHop => 'Сподели контакт чрез обява';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Изпратен контакт по обява.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Неуспешно изпращане на контакт.';

  @override
  String get contacts_contactAdvertCopied =>
      'Рекламата е копирана в клипборда.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Копирането на обявата в клипборда не успя.';

  @override
  String get contacts_addContact => 'Добави контакт';

  @override
  String get contacts_scanQrCode => 'Сканирай QR на контакт';

  @override
  String get contacts_scanQrCodeDesc =>
      'Сканирайте QR кода на контакт от приложението MeshCore';

  @override
  String get contacts_enterIdHash => 'Въведи контакт ръчно';

  @override
  String get contacts_enterIdHashDesc =>
      'Поставете обява на контакт или връзка meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... или публичен ключ в hex';

  @override
  String get contacts_import => 'Импортирай';

  @override
  String get contacts_scanContactInstructions =>
      'Сканирайте QR кода на контакт от MeshCore';

  @override
  String get notification_activityTitle => 'Активност на MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'съобщения',
      one: 'съобщение',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'съобщения в канали',
      one: 'съобщение в канал',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'нови възли',
      one: 'нов възел',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Открит нов $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Получено ново съобщение';

  @override
  String get settings_gpxExportRepeaters =>
      'Експортиране на повтарящи се устройства / сървър на стаята до GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Изпраща повторители / roomserver с местоположение в GPX файл.';

  @override
  String get settings_gpxExportContacts => 'Експортирай спътници към GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Експортира спътници с местоположение в GPX файл.';

  @override
  String get settings_gpxExportAll => 'Експортирай всички контакти в GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Експортира всички контакти с местоположение в файл GPX.';

  @override
  String get settings_gpxExportSuccess => 'Успешно изlexport на файл GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Няма контакти за изlexport.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Не е поддържан на вашето устройство/ОС';

  @override
  String get settings_gpxExportError => 'Възникна грешка при изнасяне.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Местоположения на повторител и сървър на стаята';

  @override
  String get settings_gpxExportChat => 'Местоположения на спътници';

  @override
  String get settings_gpxExportAllContacts =>
      'Местоположения на всички контакти';

  @override
  String get settings_gpxExportShareText =>
      'Картинни данни изнесени от MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax износ на данни за карта в формат GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Близки повтарящи се устройства';

  @override
  String get snrIndicator_lastSeen => 'Последно видян';

  @override
  String get contactsSettings_title => 'Настройки на контактите';

  @override
  String get contactsSettings_autoAddTitle => 'Автоматично откриване';

  @override
  String get contactsSettings_otherTitle =>
      'Други настройки свързани с контакти';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Автоматично добавяне на потребители';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Позволи на спътника да добавя автоматично откритите потребители.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Автоматично добавяне на повтарящи се елементи';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Позволи на спътника да добавя автоматично откритите повтарящи се устройства.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Автоматично добавяне на сървъри на стаите';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Позволи на спътника да добавя автоматично откритите сървъри на стаите.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Автоматично добавяне на датчици';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Позволи на спътника да добавя автоматично откритите датчици.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Премахни най-старото';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Когато списъкът с контакти е пълен, най-старият неключов контакт ще бъде заменен.';

  @override
  String get discoveredContacts_Title => 'Открити контакти';

  @override
  String get discoveredContacts_noMatching => 'Няма съвпадащи контакти';

  @override
  String get listFilter_searchHint => 'Търсене...';

  @override
  String get discoveredContacts_searchHint => 'Търсене на открити контакти';

  @override
  String get discoveredContacts_contactAdded => 'Контакт добавен';

  @override
  String get discoveredContacts_addContact => 'Добави контакт';

  @override
  String get discoveredContacts_copyContact => 'Копирай контакт в клипборда';

  @override
  String get discoveredContacts_deleteContact => 'Изтрий контакт';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Изтриване на Всички Открити Контакти';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Сигурни ли сте, че искате да изтриете всички открити контакти?';

  @override
  String get chat_sendCooldown =>
      'Моля, изчакайте малко, преди да изпратите отново.';

  @override
  String get chat_notConnected =>
      'Няма връзка с радио. Съобщението не е изпратено.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Преминете към най-старата непочетена статия';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Когато отворите чат с непрочетени съобщения, плъзнете надолу, за да видите първото непрочетено съобщение, вместо най-новото.';

  @override
  String get appSettings_languageHu => 'Унгарски';

  @override
  String get appSettings_languageJa => 'Японски';

  @override
  String get appSettings_languageKo => 'Корейски';

  @override
  String get radioStats_screenTitle =>
      'Статистически данни за радиопредаванията';

  @override
  String get radioStats_notConnected =>
      'Свържете се с устройство, за да видите статистически данни за радиопредаване.';

  @override
  String get radioStats_firmwareTooOld =>
      'Статистиката на радиостанцията изисква съвместимо софтуерно решение версия 8 или по-нова.';

  @override
  String get radioStats_waiting => 'Изчакване на данни…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Ниво на шума: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Последен RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Последна стойност на SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Време на въздух (общо): $seconds секунди';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Общо време на използване на RX (в секунди): $seconds с';
  }

  @override
  String get radioStats_chartCaption =>
      'Ниво на шума (dBm) за последните измервания.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Ниво на шума: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Извличане на данни за радиото…';

  @override
  String get radioStats_settingsTile => 'Статистически данни за радиостанции';

  @override
  String get radioStats_settingsSubtitle =>
      'Ниво на шума, RSSI, SNR и време на пренос';

  @override
  String get translation_title => 'Превод';

  @override
  String get translation_enableTitle => 'Активирайте превода';

  @override
  String get translation_enableSubtitle =>
      'Превеждайте входящите съобщения и позволявайте предварително превеждане преди изпращане.';

  @override
  String get translation_composerTitle => 'Преведете преди да изпратите';

  @override
  String get translation_composerSubtitle =>
      'Контролира началния статус на иконата за превод, създадена от композитора.';

  @override
  String get translation_targetLanguage => 'Целеви език';

  @override
  String get translation_useAppLanguage => 'Използвайте езика на приложението';

  @override
  String get translation_downloadedModelLabel => 'Изтегнат модел';

  @override
  String get translation_presetModelLabel =>
      'Предварително конфигуриран модел от Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL на ръководството';

  @override
  String get translation_downloadModel => 'Изтеглете модела';

  @override
  String get translation_downloading => 'Изтегляне...';

  @override
  String get translation_working => 'Работа...';

  @override
  String get translation_stop => 'Спрете';

  @override
  String get translation_mergingChunks =>
      'Съединяване на изтеглените части в един файл...';

  @override
  String get translation_downloadedModels => 'Изтеглени модели';

  @override
  String get translation_deleteModel => 'Изтриване на модела';

  @override
  String get translation_modelDownloaded => 'Моделът за превод е изтеглен.';

  @override
  String get translation_downloadStopped => 'Изтеглянето беше прекъснато.';

  @override
  String translation_downloadFailed(String error) {
    return 'Не успях да изтегля: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Въведете първо URL адрес на модела.';

  @override
  String get scanner_linuxPairingShowPin => 'Покажи PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Скриване на PIN кода';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN за съвпадение чрез Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Въведете PIN кода за $deviceName (оставете празно, ако няма такъв).';
  }

  @override
  String get translation_messageTranslation => 'Превод на съобщението';

  @override
  String get translation_translateBeforeSending =>
      'Преведете преди да изпратите';

  @override
  String get translation_composerEnabledHint =>
      'Съобщенията ще бъдат преведени, преди да бъдат изпратени.';

  @override
  String get translation_composerDisabledHint =>
      'Изпращайте съобщения на оригиналния въведен език.';

  @override
  String translation_translateTo(String language) {
    return 'Превеждане на $language';
  }

  @override
  String get translation_translationOptions => 'Опции за превод';

  @override
  String get translation_systemLanguage => 'Език на системата';

  @override
  String get routing_title => 'Маршрутизация';

  @override
  String routing_route(String route) {
    return 'Запазен път: $route';
  }

  @override
  String get routing_noRoute =>
      'още няма — следващото съобщение ще отиде до цялата мрежа и ще намери път';

  @override
  String get routing_auto => 'Автоматично';

  @override
  String get routing_autoSubtitle =>
      'Използва пътя, запазен в радиото. Препоръчително.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder е включен: първо опитва научените маршрути';

  @override
  String get routing_flood => 'Винаги до цялата мрежа';

  @override
  String get routing_floodSubtitle => 'Всяко съобщение отива до цялата мрежа';

  @override
  String get routing_custom => 'Собствен път';

  @override
  String get routing_customSubtitle => 'Изберете повторителите сами';

  @override
  String get routing_forget => 'Нулирай пътя';

  @override
  String get routing_forgetDone =>
      'Пътят е нулиран. Следващото съобщение ще отиде до цялата мрежа и ще намери нов.';

  @override
  String get routing_pathfinder => 'Какво знае Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Повторители, които чуват вас и тях, и научени маршрути натам и обратно';

  @override
  String get path_direct => 'Директно — без повторители';

  @override
  String get path_directSubtitle => 'Само ако контактът чува самото това радио';

  @override
  String get chat_kindFlood => 'до цялата мрежа';

  @override
  String get chat_kindDirect => 'директно';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'скока',
      one: 'скок',
    );
    return 'маршрут ($count $_temp0)';
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
  String get chat_statusQueued => 'На опашка';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Никой повторител не ви чу. Ще опита отново, когато има повторител в обхват.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'Радиото на $name изпраща кратки кодове на повторители (1 байт). Pathfinder не може да научи маршрути до този контакт, докато радиото му не започне да използва 2-байтови кодове.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Изпращане · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Нов опит · $kind · опит $attempt от $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Доставено · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Доставено при опит $attempt · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Доставено със закъснение · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Доставено · $secs с';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'опита',
      one: 'опит',
    );
    return 'Неуспешно след $attempts $_temp0 · докоснете, за да изпратите отново';
  }

  @override
  String get chat_statusFailedShort =>
      'Неуспешно · докоснете, за да изпратите отново';

  @override
  String get chat_resendingByFlood => 'Повторно изпращане до цялата мрежа';

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
  String get settings_pathGraph => 'Pathfinder (експериментално)';

  @override
  String get settings_pathGraphSubtitle =>
      'Научава маршрути от всичко, което радиото чува, и при изпращане на лично съобщение първо опитва най-добрите. Кехлибарена икона на път отбелязва съобщение, изпратено по маршрут на Pathfinder.';

  @override
  String get map_routeAndTrace => 'Маршрут и трасиране';

  @override
  String get map_pathfinderTrace => 'Трасиране натам и обратно';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Натам по най-добрия маршрут на Pathfinder, обратно по най-добрия му обратен маршрут';

  @override
  String get map_routeBackMirrored =>
      'Още няма известен обратен маршрут — връщане по същия път';

  @override
  String get map_traceHelpTitle => 'Бутони за трасиране на път';

  @override
  String get map_traceHelpCustom => 'Въведете или изберете повторителите сами.';

  @override
  String get map_traceHelpRun =>
      'Изпраща трасиране в една посока през докоснатите повторители.';

  @override
  String get map_traceHelpThereAndBack => 'Натам и обратно';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Изпраща трасирането натам, после обратно през същите повторители в обратен ред.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder избира най-добрия маршрут през последните два докоснати повторителя и най-добрия маршрут обратно до вас. Резултатът показва на Pathfinder кои връзки наистина работят. Трябва да докоснете два повторителя.';

  @override
  String get map_traceHelpRemoveLast =>
      'Премахва последния повторител от пътя.';

  @override
  String get map_traceHelpCancel =>
      'Спира изграждането на трасирането. Показва се, преди да е докоснат повторител.';

  @override
  String get chat_resendingByRoute =>
      'Повторно изпращане по зададения от вас маршрут';

  @override
  String get room_mute => 'Заглушаване на стаята';

  @override
  String get room_unmute => 'Включване на звука за стаята';

  @override
  String get room_roleAdmin => 'админ';

  @override
  String get room_roleMember => 'член';

  @override
  String get room_roleReadOnly => 'само четене';

  @override
  String room_clockOff(int minutes) {
    return 'Часовникът на стаята се разминава с около $minutes мин — часовете на съобщенията може да са грешни';
  }

  @override
  String get room_fixClock => 'Поправи часовника';

  @override
  String get room_clockSyncSent =>
      'Синхронизацията на часовника е изпратена към стаята';

  @override
  String get room_readOnlyNotice =>
      'Само четене: стаята не прие паролата ви, съобщенията ви няма да стигнат до другите членове.';

  @override
  String get room_postAnnouncement => 'Публикуване на обявление';

  @override
  String get room_postAnnouncementSubtitle =>
      'Изпрати съобщение от името на стаята до всички членове';

  @override
  String get room_announcementSent => 'Обявлението е публикувано';

  @override
  String get room_announcementFailed =>
      'Публикуването на обявлението се провали';

  @override
  String get room_users => 'Потребители на стаята';

  @override
  String get room_usersSubtitle => 'Преглед на админите и задаване на роли';

  @override
  String get room_usersAdminsNote =>
      'Стаята показва само своите админи. Членовете с паролата на стаята не се показват.';

  @override
  String get room_usersLoadFailed => 'Списъкът с админи не можа да се зареди';

  @override
  String get room_setUserRole => 'Задай роля';

  @override
  String get room_removeAccess => 'Премахни достъпа';

  @override
  String get room_removeOnlyUnknown =>
      'Този потребител не е в контактите ви — може само да бъде премахнат, не променен.';

  @override
  String get room_roleUpdated => 'Ролята е обновена';

  @override
  String get room_roleUpdateFailed => 'Смяната на ролята се провали';

  @override
  String get room_postsStored => 'Съхранени съобщения';

  @override
  String get room_postsDelivered => 'Доставени съобщения';

  @override
  String get room_reloadPosts => 'Презареди последните съобщения';

  @override
  String get room_reloadPostsExplain =>
      'Иска от стаята да изпрати отново последните съобщения (пази до 32). Ще бъдете помолени за паролата на стаята. Наличните съобщения се запазват.';

  @override
  String get room_reloadFailed => 'Стаята не можа да бъде нулирана на радиото';

  @override
  String get companionCli_title => 'Команден ред';

  @override
  String get companionCli_settingsSubtitle => 'Текстови команди за това радио';

  @override
  String get companionCli_rebooting => 'Рестартиране на радиото…';

  @override
  String get companionCli_cancelled => 'Отказано';

  @override
  String get companionCli_poweringOff => 'Изключване на радиото…';

  @override
  String get companionCli_noReply =>
      'Няма отговор от радиото. Опитайте отново.';

  @override
  String get companionCli_powerOffTitle => 'Да се изключи ли радиото?';

  @override
  String get companionCli_powerOffBody =>
      'Ще остане изключено, докато не натиснете бутона му или не го включите към захранване.';

  @override
  String get companionCli_powerOff => 'Изключи';

  @override
  String get companionCli_quickBoard => 'Платка';

  @override
  String get companionCli_quickWifiStatus => 'Състояние на Wi‑Fi';

  @override
  String get companionCli_quickWifiAddress => 'Адрес в Wi‑Fi';

  @override
  String get companionCli_helpBoard =>
      'Показва производителя и модела на платката.';

  @override
  String get companionCli_helpReboot => 'Рестартира радиото.';

  @override
  String get companionCli_helpPowerOff => 'Изключва радиото.';

  @override
  String get companionCli_helpSetPin =>
      'Задава PIN за сдвояване чрез Bluetooth. Влиза в сила след рестарт.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Задава часовете, добавяни към UTC, за часовника на собствения екран на радиото (от -12 до +14).';

  @override
  String get companionCli_helpSetTx =>
      'Задава мощността на предаване в dBm. Влиза в сила веднага.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Задава прага на смущенията в dB. 0 изключва откриването на смущения.';

  @override
  String get companionCli_helpSetCad =>
      'Слуша за други радиа преди изпращане (откриване на активност в канала).';

  @override
  String get companionCli_helpSetRxGain => 'Усилено приемане при радиа SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Байтове на повторител в маршрута: 0 = 1 байт, 1 = 2 байта, 2 = 3 байта.';

  @override
  String get companionCli_helpWifiStatus =>
      'Показва дали радиото е свързано към Wi‑Fi мрежата.';

  @override
  String get companionCli_helpWifiIp =>
      'Показва адреса на радиото в Wi‑Fi мрежата.';

  @override
  String get companionCli_helpWifiSsid =>
      'Задава името на Wi‑Fi мрежата. Влиза в сила след рестарт.';

  @override
  String get companionCli_helpWifiPwd =>
      'Задава паролата за Wi‑Fi. Влиза в сила след рестарт.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Включва (1) или изключва (0) Wi‑Fi. Влиза в сила след рестарт.';

  @override
  String get companionCli_helpWifiClear =>
      'Забравя Wi‑Fi мрежата. Влиза в сила след рестарт.';

  @override
  String get companionCli_remoteNoReply =>
      'Няма отговор. Другото радио трябва да има фърмуер 1.18 или по-нов и да ви позволява да използвате командния му ред.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Изпратено. Радиото не отговаря на рестарт или изключване.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name опита да използва командния ред на радиото ви: „$command“. Не беше разрешено.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Опит за използване на командния ред на радиото ви: „$command“. Не беше разрешено.';
  }

  @override
  String get contact_remoteCli => 'Разреши отдалечен команден ред';

  @override
  String get contact_remoteCliSubtitle =>
      'Позволява на този контакт да изпълнява команди на радиото ви';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Да позволите ли на $name да управлява радиото ви?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name ще може да променя настройките на радиото ви, да чете паролата ви за Wi‑Fi, да преименува радиото и да го рестартира или изключва. Разрешавайте само на човек, на когото имате пълно доверие.';
  }

  @override
  String get contact_remoteCliAllow => 'Разреши';

  @override
  String get connection_secondApp =>
      'Друго приложение е свързано с това радио. Съобщенията и настройките може да се объркат. Затворете другото приложение.';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => 'Мрежа, парола и връзка';

  @override
  String get wifi_use => 'Използвай Wi‑Fi';

  @override
  String get wifi_networkName => 'Име на мрежата';

  @override
  String get wifi_password => 'Парола';

  @override
  String get wifi_passwordUnchanged => 'Без промяна';

  @override
  String get wifi_showPassword => 'Покажи паролата';

  @override
  String get wifi_nameMissing => 'Въведете името на мрежата';

  @override
  String get wifi_nameTooLong =>
      'Името на мрежата е твърде дълго (най-много 32 байта)';

  @override
  String get wifi_passwordTooLong =>
      'Паролата е твърде дълга (най-много 63 байта)';

  @override
  String get wifi_savedRestart =>
      'Запазено. Промените в Wi‑Fi влизат в сила след рестарт на радиото.';

  @override
  String get wifi_forget => 'Забрави мрежата';

  @override
  String get wifi_forgetConfirm =>
      'Да се забрави ли тази Wi‑Fi мрежа? След рестарт радиото спира да използва Wi‑Fi.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Радиото не прие това: $reply';
  }

  @override
  String get wifi_noReply => 'Няма отговор от радиото. Опитайте отново.';

  @override
  String get wifi_restartTitle => 'Да се рестартира ли радиото?';

  @override
  String get wifi_later => 'По-късно';

  @override
  String get wifi_loadFailed =>
      'Настройките за Wi‑Fi не можаха да се прочетат от радиото.';

  @override
  String wifi_connectedTo(String address) {
    return 'Свързано · $address';
  }

  @override
  String get wifi_notConnected => 'Няма връзка с Wi‑Fi';

  @override
  String wifi_portNote(int port) {
    return 'Приложения в същата мрежа могат да се свържат на порт $port';
  }

  @override
  String get wifi_connectOverWifi => 'Свързване през Wi‑Fi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax ще прекъсне връзката с това радио и ще отвори екрана за TCP с попълнени адрес $address и порт $port. Там докоснете „Свържи се“.';
  }

  @override
  String get wifi_noteRestart =>
      'Промените влизат в сила след рестарт на радиото.';

  @override
  String get wifi_noteSecurity =>
      'Всеки във вашата Wi‑Fi мрежа може да се свърже с радиото на порт 5000. За това няма парола.';

  @override
  String get wifi_noteBattery =>
      'Wi‑Fi държи радиото будно, затова батерията се изтощава по-бързо.';

  @override
  String get wifi_noteWrongPassword =>
      'Ако паролата е грешна, радиото продължава да опитва на всеки няколко секунди. Bluetooth продължава да работи.';

  @override
  String get room_selfDemoteWarning =>
      'Променяте собствения си достъп. Ако се откажете от ролята на админ, само конзолата на стаята може да я върне.';

  @override
  String get scanner_offlineMaps => 'Офлайн карти';

  @override
  String get appSettings_offlineMaps => 'Офлайн карти';

  @override
  String get appSettings_offlineMapsNone => 'Няма изтеглени';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count региона',
      one: '$count регион',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count района с морски карти',
      one: '$count район с морски карти',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count налични актуализации',
      one: '$count налична актуализация',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Изтегляй карти само през Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Изтеглянето на карти чака Wi‑Fi връзка';

  @override
  String get offlineMaps_title => 'Офлайн карти';

  @override
  String get offlineMaps_tabMaps => 'Карти';

  @override
  String get offlineMaps_tabCharts => 'Морски карти';

  @override
  String get offlineMaps_chartsNotice => 'Не е за навигация · Защо?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Предложени · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Райони с карти по крайбрежие';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count района',
      one: '$count район',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Изтеглени: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Избрани: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Избери всички';

  @override
  String get offlineMaps_clearSelection => 'Изчисти';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Също в: $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Още не е налично';

  @override
  String get offlineMaps_chartsHint =>
      'Картите на NOAA се избират по крайбрежие в раздела „Морски карти“.';

  @override
  String offlineMaps_chartsName(String area) {
    return '$area — карти на NOAA';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count района',
      one: '$count район',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Изтеглени';

  @override
  String get offlineMaps_refresh => 'Провери за нови карти';

  @override
  String get offlineMaps_loading => 'Зареждане на наличните карти…';

  @override
  String get offlineMaps_serverError => 'Няма връзка със сървъра за карти';

  @override
  String get offlineMaps_unavailable => 'Още няма налични карти';

  @override
  String get offlineMaps_unavailableHint => 'Проверете отново по-късно.';

  @override
  String get offlineMaps_chartsUnavailable => 'Още няма налични карти на NOAA';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Показан е списъкът от $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Обновете MeshTrax, за да получите най-новите карти.';

  @override
  String get offlineMaps_world => 'Свят';

  @override
  String get offlineMaps_suggested => 'Предложени';

  @override
  String get offlineMaps_regions => 'Региони';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Региони в $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return 'Вътре: $count';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return 'Офлайн карти на това устройство: $size';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Актуализации ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Актуализирай всички ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Изтегляне';

  @override
  String get offlineMaps_update => 'Актуализирай';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Изтеглено на $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Има актуализация';

  @override
  String get offlineMaps_otherFiles => 'Други файлове с карти';

  @override
  String get offlineMaps_emptyTitle => 'Още няма офлайн карти';

  @override
  String get offlineMaps_emptyBody =>
      'Изтеглете регион, за да използвате картата без връзка.';

  @override
  String get offlineMaps_findMaps => 'Намери карти';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Да се изтрие ли $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Ще се освободят $size. Можете да го изтеглите отново по-късно.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return 'Изтрито: $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done от $total';
  }

  @override
  String get offlineMaps_kindMap => 'Карта';

  @override
  String get offlineMaps_kindMapDetail => 'OpenStreetMap: улици, пътеки, места';

  @override
  String get offlineMaps_kindContours => 'Хоризонтали';

  @override
  String get offlineMaps_kindContoursDetail => 'Линии на надморската височина';

  @override
  String get offlineMaps_kindUsgs => 'Топографска карта USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Пътеки, потоци, резервати';

  @override
  String get offlineMaps_kindTerrain => 'Засенчване на релефа';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Хълмове и планини, засенчени под картата';

  @override
  String get offlineMaps_kindCharts => 'Морски карти на NOAA';

  @override
  String get offlineMaps_usOnly => 'Само за САЩ';

  @override
  String offlineMaps_download(String size) {
    return 'Изтегли $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Изтегли';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Голямо изтегляне ($size). Използвайте Wi‑Fi и дръжте устройството на зарядно.';
  }

  @override
  String get offlineMaps_waiting => 'Изчакване…';

  @override
  String get offlineMaps_checking => 'Проверка на изтеглянето…';

  @override
  String get offlineMaps_retrying => 'Нов опит…';

  @override
  String offlineMaps_failed(String error) {
    return 'Неуспешно изтегляне: $error';
  }

  @override
  String get offlineMaps_pause => 'Пауза';

  @override
  String get offlineMaps_resume => 'Продължи';

  @override
  String get offlineMaps_deleteRegion => 'Изтрий региона';

  @override
  String get offlineMaps_notInCatalogue => 'Не е налично за този регион';

  @override
  String get offlineMaps_notificationRunning => 'Изтегляне на карта';

  @override
  String get offlineMaps_notificationPaused =>
      'Изтеглянето на картата е на пауза';

  @override
  String get offlineMaps_notificationFailed => 'Неуспешно изтегляне на картата';

  @override
  String get offlineMaps_clearTileCache => 'Изчисти кеша на онлайн картите';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Да се премахнат ли плочките от онлайн картите, запазени при разглеждане? Изтеглените карти остават.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Кешът на онлайн картите е изчистен';

  @override
  String get map_notForNavigation => 'Не е за навигация';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax рисува тези карти по данни на NOAA, за да виждате водата около радиата си и да планирате. Те не са официални карти. Не се ориентирайте по тях при плаване.';

  @override
  String get map_chartsNoticeWhy => 'Защо:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Остаряват. NOAA постоянно коригира картите си, а изтеглената карта остава същата, докато не я обновите в „Офлайн карти“.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Не показват всичко. Много символи, сектори на светлините и бележки не се изобразяват, а някои надписи се появяват само при увеличение.';

  @override
  String get map_chartsNoticePositions =>
      'Местоположенията може да са неточни или стари. GPS може да греши с 10 м (30 фута) или повече, а възелът е там, откъдето се е обадил последно.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax не е сертифициран картплотер.';

  @override
  String get map_chartsNoticeUse =>
      'За навигация използвайте официални, актуални карти на NOAA (хартиени или ENC на NOAA в сертифициран картплотер) с последните Известия до мореплавателите.';

  @override
  String get map_sourceOnline => 'Онлайн';

  @override
  String get map_sourceOffline => 'Офлайн';

  @override
  String get map_downloadForDetail => 'Изтеглете регион за повече подробности';

  @override
  String get map_zoomInForOfflineMap =>
      'Увеличете, за да видите офлайн картата';

  @override
  String get map_noCharts => 'Тук няма морски карти';

  @override
  String get map_myLocation => 'Моето местоположение';

  @override
  String get map_zoomIn => 'Увеличи';

  @override
  String get map_zoomOut => 'Намали';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS вкл.';

  @override
  String get gps_off => 'GPS изкл.';

  @override
  String get gps_onHint => 'Радиото обновява местоположението си от GPS.';

  @override
  String get gps_offHint =>
      'Изключеният GPS пести батерията на радиото. След включване намирането на местоположението може да отнеме няколко минути.';

  @override
  String get gps_asking => 'Запитване към радиото...';

  @override
  String get gps_noPosition =>
      'Още няма местоположение. На открито първото може да отнеме няколко минути.';

  @override
  String get gps_position => 'Координати';

  @override
  String get gps_altitude => 'Надморска височина';

  @override
  String gps_readAgo(String ago) {
    return 'Прочетено от радиото преди $ago';
  }

  @override
  String get gps_turnOnTitle => 'Да се включи ли GPS?';

  @override
  String get gps_turnOnBody =>
      'GPS на радиото е изключен. След включване намирането на местоположението може да отнеме няколко минути.';

  @override
  String get gps_turnOn => 'Включи';

  @override
  String get gps_notNow => 'Не сега';

  @override
  String get map_zoomInForCharts => 'Увеличете, за да видите морските карти';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Изтегли $region · $size';
  }

  @override
  String get mapLayers_title => 'Слоеве на картата';

  @override
  String get mapLayers_mapType => 'Тип карта';

  @override
  String get mapLayers_standard => 'Стандартна';

  @override
  String get mapLayers_usgs => 'Топографска USGS';

  @override
  String get mapLayers_charts => 'Морски карти';

  @override
  String get mapLayers_notDownloaded => 'Не е изтеглено';

  @override
  String get mapLayers_offlineOnly => 'Само офлайн';

  @override
  String get mapLayers_details => 'Детайли на картата';

  @override
  String get mapLayers_contours => 'Хоризонтали';

  @override
  String get mapLayers_hillShading => 'Засенчване на релефа';

  @override
  String get mapLayers_dark => 'Тъмна карта';

  @override
  String get mapLayers_downloadedAreas => 'Изтеглени области';

  @override
  String get mapLayers_nodes => 'Възли';

  @override
  String get mapLayers_pins => 'Маркери';

  @override
  String get mapLayers_guessed => 'Предполагаеми';

  @override
  String get mapLayers_moreFilters => 'Още филтри';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Последно видени, префикс на ключа, припокривания';

  @override
  String get map_legend => 'Легенда';

  @override
  String get scanner_map => 'Карта';

  @override
  String get structured_openMap => 'Отвори картата';

  @override
  String get structured_addToCalendar => 'Добави в календара';

  @override
  String get structured_details => 'Подробности';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Събитие';

  @override
  String get structured_notice => 'Обявление';

  @override
  String get structured_allDay => 'Цял ден';

  @override
  String get structured_calendarFailed => 'Календарът не можа да се отвори';

  @override
  String get structured_today => 'Днес';

  @override
  String get structured_tomorrow => 'Утре';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'След $count дни',
      one: 'След $count ден',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Минало';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Ден $day от $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дни',
      one: '$count ден',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Крайна дата';

  @override
  String get dialog_eventSameDay => 'Същия ден';

  @override
  String get structured_map => 'Карта';

  @override
  String get structured_navigate => 'Навигация';

  @override
  String get structured_channel => 'Канал';

  @override
  String get structured_contact => 'Контакт';

  @override
  String get structured_room => 'Стая';

  @override
  String get structured_repeater => 'Повторител';

  @override
  String get structured_sensor => 'Датчик';

  @override
  String get structured_joinChannel => 'Присъедини се към канала';

  @override
  String get structured_addContact => 'Добави контакт';

  @override
  String get structured_addRoom => 'Добави стая';

  @override
  String get structured_addRepeater => 'Добави повторител';

  @override
  String get structured_addSensor => 'Добави датчик';

  @override
  String get structured_open => 'Отвори';

  @override
  String get structured_added => 'Добавено';

  @override
  String get tray_add => 'Добави';

  @override
  String get tray_myLocation => 'Моето местоположение';

  @override
  String get tray_pointOnMap => 'Точка на картата';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Събитие';

  @override
  String get tray_notice => 'Обявление';

  @override
  String get tray_noRadioPosition =>
      'Радиото ви още няма местоположение. Изберете го на картата.';

  @override
  String get dialog_insert => 'Вмъкни';

  @override
  String get dialog_eventTitle => 'Заглавие';

  @override
  String get dialog_eventDate => 'Дата';

  @override
  String get dialog_eventStart => 'Начало';

  @override
  String get dialog_eventEnd => 'Край';

  @override
  String get dialog_eventNoEnd => 'Без краен час';

  @override
  String get dialog_eventPlace => 'Място (по избор)';

  @override
  String get dialog_pickOnMap => 'Избери на картата';

  @override
  String get dialog_sosTitle => 'Изпрати SOS';

  @override
  String get dialog_sosText => 'Какво се случи?';

  @override
  String get dialog_noticeTitle => 'Обявление';

  @override
  String get dialog_noticeText => 'Какво трябва да знаят всички?';

  @override
  String get dialog_labelTitle => 'Точка на картата';

  @override
  String get dialog_note => 'Бележка (по избор)';

  @override
  String get paste_convertLocation =>
      'Изглежда като връзка към карта. Да се превърне ли в местоположение?';

  @override
  String get paste_convertEvent =>
      'Изглежда като споделено събитие от календар. Да се превърне ли в събитие?';

  @override
  String get paste_convert => 'Превърни';

  @override
  String get paste_resolving => 'Обработка на връзката…';

  @override
  String get paste_resolveFailed => 'Връзката не можа да се обработи';

  @override
  String get pinned_dismiss => 'Скрий';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Да се присъедините ли към канала $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Вече сте в $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Присъединихте се към $name';
  }

  @override
  String get map_pickPositionHint => 'Докоснете картата, за да изберете място';

  @override
  String get map_legendMesh => 'Мрежа';

  @override
  String get chartLegend_title => 'Условни знаци на картата';

  @override
  String get chartLegend_sectionBuoys => 'Шамандури и знаци';

  @override
  String get chartLegend_sectionLights => 'Светлини';

  @override
  String get chartLegend_sectionHazards => 'Опасности';

  @override
  String get chartLegend_sectionTides => 'Приливи и течения';

  @override
  String get chartLegend_sectionDepths => 'Дълбочини и дъно';

  @override
  String get chartLegend_sectionAreas => 'Райони, платна и линии';

  @override
  String get chartLegend_sectionLandmarks => 'Ориентири';

  @override
  String get chartLegend_sectionAbbreviations => 'Съкращения';

  @override
  String get chartLegend_chartNo1 => 'Всички условни знаци: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Зелена цилиндрична шамандура';

  @override
  String get chartLegend_portBuoyHint =>
      'Оставете я вляво, когато влизате от морето';

  @override
  String get chartLegend_starboardBuoy => 'Червена конична шамандура';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Оставете я вдясно при влизане: червено — вдясно, когато се връщате от морето';

  @override
  String get chartLegend_junctionBuoy => 'Шамандура с хоризонтални ивици';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Разклонение на фарватера: приемете я за цвета на горната ивица';

  @override
  String get chartLegend_safeWaterBuoy => 'Червени и бели вертикални ивици';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Безопасни води наоколо, често при входа на фарватер';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Черни и червени ивици';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Малка опасност с безопасни води около нея: стойте настрана';

  @override
  String get chartLegend_specialBuoy => 'Жълта шамандура';

  @override
  String get chartLegend_specialBuoyHint =>
      'Специален знак, не за навигация: котвена стоянка, кабел, изследвания';

  @override
  String get chartLegend_cardinalBuoy => 'Черно и жълто';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Кардинален знак: минете от страната, на която е наречен (рядко в САЩ)';

  @override
  String get chartLegend_mooringBuoy => 'Швартова шамандура';

  @override
  String get chartLegend_portBeacon => 'Зелен квадратен знак';

  @override
  String get chartLegend_portBeaconHint =>
      'Като зелена шамандура: оставете го вляво при влизане';

  @override
  String get chartLegend_starboardBeacon => 'Червен триъгълен знак';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Като червена шамандура: оставете го вдясно при влизане';

  @override
  String get chartLegend_otherBeacon => 'Ромбовиден знак';

  @override
  String get chartLegend_otherBeaconHint =>
      'Информация или предупреждение, а не страна на фарватера';

  @override
  String get chartLegend_beaconTower => 'Фарова кула или конструкция на знак';

  @override
  String get chartLegend_topmark => 'Топова фигура';

  @override
  String get chartLegend_topmarkHint =>
      'Фигурата върху знака допълва значението му';

  @override
  String get chartLegend_light => 'Светлина';

  @override
  String get chartLegend_lightHint =>
      'Пурпурният пламък обозначава светлина; надписът казва как мига';

  @override
  String get chartLegend_lightExample =>
      'Зелена проблясваща, на всеки 4 секунди';

  @override
  String get chartLegend_lightExampleHint =>
      'Надписът на светлината: ритъм, цвят, после период';

  @override
  String get chartLegend_lightFixed => 'Постоянна';

  @override
  String get chartLegend_lightFixedHint => 'Свети без прекъсване';

  @override
  String get chartLegend_lightFlashing => 'Проблясваща';

  @override
  String get chartLegend_lightFlashingHint =>
      'Кратки проблясъци, по-дълга тъмнина между тях';

  @override
  String get chartLegend_lightGroup => 'Групово проблясваща';

  @override
  String get chartLegend_lightGroupHint =>
      'Проблясъци на групи, тук по 2, после тъмно';

  @override
  String get chartLegend_lightComposite => 'Съставна групово проблясваща';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 проблясъка, после 1: разклонение на фарватера';

  @override
  String get chartLegend_lightQuick => 'Бързо проблясваща';

  @override
  String get chartLegend_lightQuickHint => 'Около един проблясък в секунда';

  @override
  String get chartLegend_lightIsophase => 'Изофазна';

  @override
  String get chartLegend_lightIsophaseHint =>
      'Еднакво време светлина и тъмнина';

  @override
  String get chartLegend_lightOcculting => 'Затъмняваща се';

  @override
  String get chartLegend_lightOccultingHint =>
      'Свети по-дълго, отколкото е тъмно';

  @override
  String get chartLegend_lightMorse => 'Морзов код A';

  @override
  String get chartLegend_lightMorseHint => 'Кратко, дълго: безопасни води';

  @override
  String get chartLegend_lightAlternating => 'Редуваща се';

  @override
  String get chartLegend_lightAlternatingHint => 'Сменя цвета си';

  @override
  String get chartLegend_lightColours => 'Бяла, червена, зелена, жълта';

  @override
  String get chartLegend_lightPeriod => 'Период';

  @override
  String get chartLegend_lightPeriodHint => 'Секунди за един пълен цикъл';

  @override
  String get chartLegend_rock => 'Подводна скала';

  @override
  String get chartLegend_rockHint =>
      'Винаги под водата, но може да е близо до повърхността';

  @override
  String get chartLegend_rockAwash => 'Скала на нивото на водата';

  @override
  String get chartLegend_rockAwashHint => 'Близо до повърхността при отлив';

  @override
  String get chartLegend_rockCovers => 'Скала, която се показва и скрива';

  @override
  String get chartLegend_rockCoversHint =>
      'Показва се при отлив, скрита е при прилив';

  @override
  String get chartLegend_wreckDangerous => 'Опасен потънал кораб';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Достатъчно плитко, за да го ударите';

  @override
  String get chartLegend_wreck => 'Потънал кораб';

  @override
  String get chartLegend_wreckHint =>
      'Достатъчно дълбоко за плавателни съдове; не пускайте котва';

  @override
  String get chartLegend_wreckShowing => 'Потънал кораб, видим над водата';

  @override
  String get chartLegend_wreckShowingHint => 'Част от него се вижда над водата';

  @override
  String get chartLegend_obstruction => 'Препятствие';

  @override
  String get chartLegend_obstructionHint =>
      'Нещо на дъното; дълбочината над него, ако е известна';

  @override
  String get chartLegend_foulGround => 'Замърсено дъно';

  @override
  String get chartLegend_foulGroundHint =>
      'Може да се минава отгоре, но не пускайте котва и не тралете';

  @override
  String get chartLegend_hazardArea => 'Граница на опасен район';

  @override
  String get chartLegend_hazardAreaHint =>
      'Вътре има скали, потънали кораби или препятствия';

  @override
  String get chartLegend_pile => 'Пилон или стълб';

  @override
  String get chartLegend_floodStream => 'Приливно течение';

  @override
  String get chartLegend_floodStreamHint => 'Течение, докато водата се покачва';

  @override
  String get chartLegend_ebbStream => 'Отливно течение';

  @override
  String get chartLegend_ebbStreamHint => 'Течение, докато водата спада';

  @override
  String get chartLegend_current => 'Постоянно течение';

  @override
  String get chartLegend_currentHint =>
      'Тече в една посока независимо от прилива';

  @override
  String get chartLegend_rips => 'Вълнения или водовъртежи';

  @override
  String get chartLegend_ripsHint => 'Бурна, завихрена вода';

  @override
  String get chartLegend_breakers => 'Разбиващи се вълни';

  @override
  String get chartLegend_breakersHint => 'Вълни се разбиват над плитчини';

  @override
  String get chartLegend_sounding => 'Измерена дълбочина';

  @override
  String get chartLegend_soundingHint => 'Дълбочина при среден отлив';

  @override
  String get chartLegend_depthContour => 'Изобата';

  @override
  String get chartLegend_depthContourHint => 'Надписът ѝ показва дълбочината';

  @override
  String get chartLegend_drying => 'Пресъхва при отлив';

  @override
  String get chartLegend_dredged => 'Драгиран канал';

  @override
  String get chartLegend_dredgedHint => 'Поддържа се показаната дълбочина';

  @override
  String get chartLegend_swept => 'Протрален район';

  @override
  String get chartLegend_sweptHint =>
      'Проверен като чист до показаната дълбочина';

  @override
  String get chartLegend_unsurveyed => 'Непроучено';

  @override
  String get chartLegend_unsurveyedHint => 'Няма измерени дълбочини';

  @override
  String get chartLegend_weed => 'Ламинария или водорасли';

  @override
  String get chartLegend_restricted => 'Район с ограничения';

  @override
  String get chartLegend_restrictedHint =>
      'Достъпът е ограничен; чертичките сочат навътре';

  @override
  String get chartLegend_regulatedLimit => 'Граница на регулиран район';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Котвена стоянка, кабелен район, район за стрелби и др.: вижте надписа';

  @override
  String get chartLegend_greyLimit =>
      'Депо за изкопан грунт, риболовен район или ферма';

  @override
  String get chartLegend_anchorage => 'Котвена стоянка';

  @override
  String get chartLegend_anchorBerth => 'Котвено място';

  @override
  String get chartLegend_noAnchoring => 'Забранено пускане на котва';

  @override
  String get chartLegend_caution => 'Предупредителен район';

  @override
  String get chartLegend_cautionHint => 'Бъдете особено внимателни тук';

  @override
  String get chartLegend_trafficLane => 'Платно за движение';

  @override
  String get chartLegend_trafficLaneHint =>
      'Големи кораби, еднопосочно: пресичайте под прав ъгъл';

  @override
  String get chartLegend_separationZone => 'Разделителна зона';

  @override
  String get chartLegend_separationZoneHint =>
      'Между платната за движение: не влизайте';

  @override
  String get chartLegend_precautionary => 'Район за повишено внимание';

  @override
  String get chartLegend_precautionaryHint =>
      'Тук корабите се събират: внимавайте';

  @override
  String get chartLegend_fairway => 'Фарватер';

  @override
  String get chartLegend_fairwayHint => 'Основен плавателен път';

  @override
  String get chartLegend_track => 'Препоръчителен курс';

  @override
  String get chartLegend_ferry => 'Фериботна линия';

  @override
  String get chartLegend_leadingLine => 'Створна линия';

  @override
  String get chartLegend_leadingLineHint =>
      'Подравнете двата ѝ знака, за да останете във фарватера';

  @override
  String get chartLegend_cable => 'Подводен кабел';

  @override
  String get chartLegend_cableHint => 'Не пускайте котва';

  @override
  String get chartLegend_pipeline => 'Подводен тръбопровод';

  @override
  String get chartLegend_pipelineHint => 'Не пускайте котва';

  @override
  String get chartLegend_overhead => 'Въздушен кабел';

  @override
  String get chartLegend_overheadHint => 'Височината под него е означена с VC';

  @override
  String get chartLegend_tower => 'Кула';

  @override
  String get chartLegend_windTurbine => 'Вятърна турбина';

  @override
  String get chartLegend_chimney => 'Комин';

  @override
  String get chartLegend_mast => 'Мачта или антена';

  @override
  String get chartLegend_church => 'Църква или шпил';

  @override
  String get chartLegend_flagstaff => 'Флагщок';

  @override
  String get chartLegend_dome => 'Купол';

  @override
  String get chartLegend_landmark => 'Друг ориентир';

  @override
  String get chartLegend_abbrAnch => 'Котвена стоянка';

  @override
  String get chartLegend_abbrWk => 'Потънал кораб';

  @override
  String get chartLegend_abbrBr => 'Разбиващи се вълни';

  @override
  String get chartLegend_abbrWd => 'Водорасли';

  @override
  String get chartLegend_abbrVar => 'Магнитна деклинация';

  @override
  String get chartLegend_abbrVc => 'Височина под мост или кабел';

  @override
  String get chartLegend_abbrTr => 'Кула';

  @override
  String get chartLegend_abbrCh => 'Църква';

  @override
  String get chartLegend_abbrChy => 'Комин';

  @override
  String get chartLegend_abbrFs => 'Флагщок';

  @override
  String get chartLegend_abbrTk => 'Резервоар';

  @override
  String get chartLegend_abbrRBn => 'Радиофар';

  @override
  String get chartLegend_abbrCg => 'Станция на бреговата охрана';

  @override
  String get chartLegend_abbrRacon =>
      'Радарен маяк-отговарящ: вижда се на радара';

  @override
  String get chartLegend_abbrFog =>
      'Мъглов сигнал: тифон, камбана, гонг, свирка или сирена';

  @override
  String get chartLegend_abbrVAis => 'Виртуален знак: показва се само в AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'от $from до $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'По-дълбоко от $depth';
  }

  @override
  String get parkLegend_title => 'Символи за паркове и пътеки';

  @override
  String get parkLegend_campsite => 'Къмпинг';

  @override
  String get parkLegend_picnicSite => 'Място за пикник';

  @override
  String get parkLegend_shelter => 'Заслон';

  @override
  String get parkLegend_toilets => 'Тоалетна';

  @override
  String get parkLegend_drinkingWater => 'Питейна вода';

  @override
  String get parkLegend_parking => 'Паркинг';

  @override
  String get parkLegend_viewpoint => 'Панорамна площадка';

  @override
  String get parkLegend_attraction => 'Забележителност';

  @override
  String get parkLegend_gate => 'Порта';

  @override
  String get parkLegend_telephone => 'Телефон';

  @override
  String get parkLegend_information => 'Информационно табло';

  @override
  String get parkLegend_guidepost => 'Указателна табела';

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

  @override
  String get share_qrAndLink => 'Share QR code and link';

  @override
  String get share_roomTitle => 'Share Room';

  @override
  String get share_contactTitle => 'Share Contact';

  @override
  String get share_roomInstructions =>
      'Scan to add this room. You\'ll need its password to log in.';

  @override
  String get share_contactInstructions => 'Scan to add this contact.';

  @override
  String get clearChat_body =>
      'Delete messages from this chat on this device. New messages still arrive here.';

  @override
  String get clearChat_olderThanDay => 'Older than 1 day';

  @override
  String get clearChat_olderThanWeek => 'Older than 1 week';

  @override
  String get clearChat_olderThanMonth => 'Older than 1 month';

  @override
  String get clearChat_everything => 'All messages';

  @override
  String get chats_markAllRead => 'Mark all as read';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mark $count chats as read?',
      one: 'Mark 1 chat as read?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Mark read';

  @override
  String get chats_nothingUnread => 'No unread messages';
}
