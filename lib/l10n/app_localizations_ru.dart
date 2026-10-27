// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Чаты';

  @override
  String get chats_title => 'Чаты';

  @override
  String get newChat_title => 'Выберите контакт';

  @override
  String newChat_contactCount(int count) {
    return 'Контактов: $count';
  }

  @override
  String get newChat_newContact => 'Новый контакт';

  @override
  String get newChat_newChannel => 'Новый канал';

  @override
  String get newChat_myContacts => 'Мои контакты';

  @override
  String get newChat_discovered => 'Обнаруженные';

  @override
  String get repeaters_title => 'Управление репитерами';

  @override
  String get nav_contacts => 'Контакты';

  @override
  String get nav_channels => 'Каналы';

  @override
  String get nav_map => 'Карта';

  @override
  String get common_cancel => 'Отмена';

  @override
  String get common_syncing_device_info => 'Чтение данных устройства...';

  @override
  String get common_syncing_contacts => 'Чтение контактов...';

  @override
  String get common_syncing_channels => 'Чтение каналов...';

  @override
  String get common_syncing_messages => 'Чтение сообщений...';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Коннект';

  @override
  String get common_unknownDevice => 'Неизвестное устройство';

  @override
  String get common_save => 'Сохранить';

  @override
  String get common_delete => 'Удалить';

  @override
  String get common_deleteAll => 'Удалить все';

  @override
  String get common_close => 'Закрыть';

  @override
  String get common_edit => 'Изменить';

  @override
  String get common_add => 'Добавить';

  @override
  String get common_settings => 'Настройки';

  @override
  String get common_disconnect => 'Отключить';

  @override
  String get common_connected => 'Подключено';

  @override
  String get common_disconnected => 'Отключено';

  @override
  String get common_connectionLost => 'Соединение потеряно. Переподключение...';

  @override
  String get common_reconnecting => 'Переподключение...';

  @override
  String get common_create => 'Создать';

  @override
  String get common_continue => 'Продолжить';

  @override
  String get common_share => 'Поделиться';

  @override
  String get common_copy => 'Копировать';

  @override
  String get common_retry => 'Повторить';

  @override
  String get common_hide => 'Скрыть';

  @override
  String get common_remove => 'Убрать';

  @override
  String get common_enable => 'Включить';

  @override
  String get common_disable => 'Выключить';

  @override
  String get common_reboot => 'Перезагрузить';

  @override
  String get common_loading => 'Загрузка...';

  @override
  String get common_notAvailable => '—';

  @override
  String common_voltageValue(String volts) {
    return '$volts В';
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
  String get tcpScreenTitle => 'Установить соединение по протоколу TCP';

  @override
  String get tcpHostLabel => 'IP-адрес';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Порт';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Введите адрес и подключитесь.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Подключение к $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Необходимо указать IP-адрес.';

  @override
  String get tcpErrorPortInvalid =>
      'Порт должен находиться в диапазоне от 1 до 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Протокол TCP не поддерживается на этой платформе.';

  @override
  String get tcpErrorTimedOut => 'Соединение TCP не удалось установить.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Не удалось установить соединение TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Подключение через USB';

  @override
  String get usbScreenSubtitle =>
      'Выберите обнаруженное устройство с последовательным интерфейсом и подключите его напрямую к вашему узлу MeshCore.';

  @override
  String get usbScreenStatus => 'Выберите USB-устройство';

  @override
  String get usbScreenNote =>
      'USB-серийный порт активен на поддерживаемых устройствах Android и на настольных платформах.';

  @override
  String get usbScreenEmptyState =>
      'Не обнаружено устройств USB. Подключите одно из них и обновите список.';

  @override
  String get usbErrorPermissionDenied =>
      'Запрос на доступ через USB был отклонен.';

  @override
  String get usbErrorDeviceMissing =>
      'Выбранное USB-устройство больше недоступно.';

  @override
  String get usbErrorInvalidPort => 'Выберите действительное USB-устройство.';

  @override
  String get usbErrorBusy =>
      'Еще одно запрошенное соединение через USB уже находится в процессе.';

  @override
  String get usbErrorNotConnected => 'Ни одно USB-устройство не подключено.';

  @override
  String get usbErrorOpenFailed =>
      'Не удалось открыть выбранное USB-устройство.';

  @override
  String get usbErrorConnectFailed =>
      'Не удалось установить соединение с выбранным USB-устройством.';

  @override
  String get usbErrorUnsupported =>
      'Поддержка последовательного USB отсутствует на данной платформе.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'В этой сборке нет библиотеки USB serial, поэтому USB-устройства нельзя открыть. Переустановите MeshTrax или сообщите, что эта сборка неисправна.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Этот браузер не поддерживает Web Serial. Используйте Chrome или Edge по HTTPS (или localhost).';

  @override
  String get usbErrorAlreadyActive => 'USB-соединение уже установлено.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Не было выбрано ни одно устройство USB.';

  @override
  String get usbErrorPortClosed => 'USB-соединение не установлено.';

  @override
  String get usbErrorConnectTimedOut =>
      'Соединение не установлено. Убедитесь, что устройство имеет установленное программное обеспечение USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Устройство для последовательного подключения к сети';

  @override
  String get usbStatus_notConnected => 'Выберите USB-устройство';

  @override
  String get usbStatus_connecting => 'Подключение к USB-устройству...';

  @override
  String get usbStatus_searching => 'Поиск USB-устройств...';

  @override
  String usbConnectionFailed(String error) {
    return 'Не удалось установить соединение через USB: $error';
  }

  @override
  String get scanner_scanning => 'Поиск устройств...';

  @override
  String get scanner_connecting => 'Подключение...';

  @override
  String get scanner_disconnecting => 'Отключение...';

  @override
  String get scanner_notConnected => 'Не подключено';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Подключено к $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Показать все Bluetooth-устройства';

  @override
  String get scanner_showMeshCoreOnly => 'Только радио MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'Радио не отвечает. Возможно, нужно сопряжение: откройте настройки Bluetooth, добавьте радио и введите его PIN, затем попробуйте снова.';

  @override
  String get scanner_pairingFailed =>
      'Сопряжение Bluetooth отменено или не удалось. Убедитесь, что к радио больше ничего не подключено (например, ваш телефон), затем попробуйте снова и введите его PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Подключение не удалось: $error';
  }

  @override
  String get scanner_stop => 'Стоп';

  @override
  String get scanner_scan => 'Сканирование';

  @override
  String get scanner_scanFromImage => 'Сканировать из изображения';

  @override
  String get scanner_noQrFoundInImage =>
      'На изображении нет подходящего QR-кода';

  @override
  String get scanner_bluetoothOff => 'Bluetooth выключен';

  @override
  String get scanner_bluetoothOffMessage =>
      'Пожалуйста, включите Bluetooth, чтобы найти устройства.';

  @override
  String get scanner_chromeRequired => 'Требуется браузер Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Для поддержки Bluetooth в этом веб-приложении требуется Google Chrome или браузер на базе Chromium.';

  @override
  String get scanner_enableBluetooth => 'Включите Bluetooth';

  @override
  String get device_quickSwitch => 'Быстрое переключение';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Настройки';

  @override
  String get settings_deviceInfo => 'Информация об устройстве';

  @override
  String get settings_appSettings => 'Настройки приложения';

  @override
  String get settings_appSettingsSubtitle =>
      'Уведомления, сообщения и настройки карты';

  @override
  String get settings_nodeSettings => 'Настройки ноды';

  @override
  String get settings_nodeName => 'Имя ноды';

  @override
  String get settings_nodeNameNotSet => 'Не установлено';

  @override
  String get settings_nodeNameHint => 'Введите имя ноды';

  @override
  String get settings_nodeNameUpdated => 'Имя обновлено';

  @override
  String get settings_radioSettings => 'Настройки радио';

  @override
  String get settings_radioSettingsSubtitle =>
      'Частота, мощность и коэффициент распространения';

  @override
  String get settings_radioSettingsUpdated => 'Настройки радио обновлены';

  @override
  String get settings_location => 'Позиция';

  @override
  String get settings_locationSubtitle => 'Координаты GPS';

  @override
  String get settings_locationUpdated => 'Позиция и настройки GPS обновлены';

  @override
  String get settings_locationBothRequired => 'Введите широту и долготу.';

  @override
  String get settings_locationInvalid => 'Неверная широта или долгота.';

  @override
  String get settings_locationGPSEnable => 'Включить GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Включение GPS для автоматического обновления позиции.';

  @override
  String get settings_latitude => 'Широта';

  @override
  String get settings_longitude => 'Долгота';

  @override
  String get settings_contactSettings => 'Настройки контактов';

  @override
  String get settings_contactSettingsSubtitle =>
      'Настройки добавления контактов';

  @override
  String get settings_privacyMode => 'Режим конфиденциальности';

  @override
  String get settings_privacyModeSubtitle =>
      'Скрыть имя/позицию в анонсировании';

  @override
  String get settings_privacyModeToggle =>
      'Включите режим конфиденциальности, чтобы скрыть свое имя и местоположение в анонсировании.';

  @override
  String get settings_privacyModeEnabled => 'Режим конфиденциальности включен';

  @override
  String get settings_privacyModeDisabled =>
      'Режим конфиденциальности выключен';

  @override
  String get settings_privacy => 'Настройки конфиденциальности';

  @override
  String get settings_privacySubtitle =>
      'Контролируйте, какую информацию делиться.';

  @override
  String get settings_privacySettingsDescription =>
      'Выберите, какую информацию ваше устройство будет делиться с другими.';

  @override
  String get settings_denyAll => 'Отклонить все';

  @override
  String get settings_allowByContact => 'Разрешить по флагам контактов';

  @override
  String get settings_allowAll => 'Разрешить все';

  @override
  String get settings_telemetryBaseMode => 'Базовый режим телеметрии';

  @override
  String get settings_telemetryLocationMode =>
      'Режим местоположения телеметрии';

  @override
  String get settings_telemetryEnvironmentMode => 'Режим среды телеметрии';

  @override
  String get settings_advertLocation => 'Местоположение рекламы';

  @override
  String get settings_advertLocationSubtitle =>
      'Включить местоположение в объявление';

  @override
  String get settings_multiAck => 'Несколько подтверждений';

  @override
  String get settings_telemetryModeUpdated => 'Режим телеметрии обновлен';

  @override
  String get settings_actions => 'Действия';

  @override
  String get settings_sendAdvertisement => 'Отправить анонсирование';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Отправить анонсирование о присутствии сейчас';

  @override
  String get settings_advertisementSent => 'Анонсирование отправлено';

  @override
  String get settings_syncTime => 'Синхронизация времени';

  @override
  String get settings_syncTimeSubtitle => 'Синхронизировать время с телефоном';

  @override
  String get settings_timeSynchronized => 'Время синхронизировано';

  @override
  String get settings_refreshContacts => 'Обновить контакты';

  @override
  String get settings_refreshContactsSubtitle =>
      'Перезагрузить список контактов с устройства';

  @override
  String get settings_rebootDevice => 'Перезагрузить устройство';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Перезапустить устройство MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Вы уверены, что хотите перезагрузить устройство? Вы будете отключены.';

  @override
  String get settings_debug => 'Отладка';

  @override
  String get settings_bleDebugLog => 'Журнал отладки BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Команды BLE, ответы и сырые данные';

  @override
  String get settings_appDebugLog => 'Журнал отладки приложения';

  @override
  String get settings_appDebugLogSubtitle => 'Сообщения отладки приложения';

  @override
  String get settings_exportDatabase => 'Экспорт базы сообщений';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Копия всех чатов и контактов для отладки. Храните её в тайне.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'База сохранена в: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Ошибка экспорта: $error';
  }

  @override
  String get settings_about => 'О программе';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 MeshTrax Source Project';

  @override
  String get settings_aboutDescription =>
      'Открытое клиентское приложение на Flutter для устройств MeshCore с LoRa-сетями.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Данные о высоте LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Имя';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Статус';

  @override
  String get settings_infoBattery => 'Батарея';

  @override
  String get settings_infoPublicKey => 'Публичный ключ';

  @override
  String get settings_infoContactsCount => 'Количество контактов';

  @override
  String get settings_infoChannelCount => 'Количество каналов';

  @override
  String get settings_presets => 'Пресеты';

  @override
  String get settings_frequency => 'Частота (МГц)';

  @override
  String get settings_frequencyHelper => '300.0 – 2500.0';

  @override
  String get settings_frequencyInvalid => 'Недопустимая частота (300–2500 МГц)';

  @override
  String get settings_bandwidth => 'Полоса пропускания';

  @override
  String get settings_spreadingFactor => 'Коэффициент расширения';

  @override
  String get settings_codingRate => 'Коэффициент кодирования';

  @override
  String get settings_txPower => 'Мощность передачи (дБм)';

  @override
  String get settings_txPowerInvalid => 'Недопустимая мощность передачи';

  @override
  String get settings_clientRepeat => 'Повторение \"вне сети\"';

  @override
  String get settings_clientRepeatSubtitle =>
      'Позвольте этому устройству повторять пакеты данных для других устройств.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Для работы в режиме \"без подключения к сети\" требуется частота 433, 869 или 918 МГц.';

  @override
  String settings_error(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get appSettings_title => 'Настройки приложения';

  @override
  String get appSettings_appearance => 'Внешний вид';

  @override
  String get appSettings_theme => 'Тема';

  @override
  String get appSettings_themeSystem => 'Как в системе';

  @override
  String get appSettings_themeLight => 'Светлая';

  @override
  String get appSettings_themeDark => 'Тёмная';

  @override
  String get appSettings_language => 'Язык';

  @override
  String get appSettings_languageSystem => 'Как в системе';

  @override
  String get appSettings_languageEn => 'Английский';

  @override
  String get appSettings_languageFr => 'Французский';

  @override
  String get appSettings_languageEs => 'Испанский';

  @override
  String get appSettings_languageDe => 'Немецкий';

  @override
  String get appSettings_languagePl => 'Польский';

  @override
  String get appSettings_languageSl => 'Словенский';

  @override
  String get appSettings_languagePt => 'Португальский';

  @override
  String get appSettings_languageIt => 'Итальянский';

  @override
  String get appSettings_languageZh => 'Китайский';

  @override
  String get appSettings_languageSv => 'Шведский';

  @override
  String get appSettings_languageNl => 'Нидерландский';

  @override
  String get appSettings_languageSk => 'Словацкий';

  @override
  String get appSettings_languageBg => 'Болгарский';

  @override
  String get appSettings_languageRu => 'Русский';

  @override
  String get appSettings_languageUk => 'Українська';

  @override
  String get appSettings_enableMessageTracing =>
      'Включить трассировку сообщений';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Показывать подробные метаданные о маршрутизации и времени для сообщений';

  @override
  String get appSettings_senderNameColors => 'Цветные имена отправителей';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Свой цвет имени для каждого отправителя в канале. Если выключено, у всех цвет темы.';

  @override
  String get appSettings_showTextFormatting =>
      'Показывать форматирование текста';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown в сообщениях: **жирный**, *курсив*, ||спойлеры||, заголовки и ссылки. Другие приложения MeshCore показывают исходные символы.';

  @override
  String get appSettings_notifications => 'Уведомления';

  @override
  String get appSettings_enableNotifications => 'Включить уведомления';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Получать уведомления о сообщениях и оповещениях';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Разрешение на уведомления отклонено';

  @override
  String get appSettings_notificationsEnabled => 'Уведомления включены';

  @override
  String get appSettings_notificationsDisabled => 'Уведомления отключены';

  @override
  String get appSettings_messageNotifications => 'Уведомления о сообщениях';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Показывать уведомление при получении новых сообщений';

  @override
  String get appSettings_channelMessageNotifications =>
      'Уведомления о сообщениях в каналах';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Показывать уведомление при получении сообщений в каналах';

  @override
  String get appSettings_advertisementNotifications =>
      'Уведомления об анонсированиях';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Показывать уведомление при обнаружении новых нод';

  @override
  String get appSettings_messaging => 'Обмен сообщениями';

  @override
  String get appSettings_maxMessageRetries =>
      'Максимальное количество повторных попыток отправки сообщения';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Количество попыток повторной отправки сообщения перед тем, как пометить его как неудачное.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Макс. повторов сообщений в канале';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Столько раз будет повторять отправку, пока не услышит хотя бы один повтор';

  @override
  String get appSettings_battery => 'Батарея';

  @override
  String get appSettings_batteryChemistry => 'Химия батареи';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Установить для устройства ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Подключитесь к устройству, чтобы выбрать';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0–4.2 В)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6–3.65 В)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0–4.2 В)';

  @override
  String get appSettings_mapDisplay => 'Отображение карты';

  @override
  String get appSettings_showRepeaters => 'Показывать репитеры';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Отображать репитеры на карте';

  @override
  String get appSettings_showChatNodes => 'Показывать чат-ноды';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Отображать чат-ноды на карте';

  @override
  String get appSettings_showOtherNodes => 'Показывать другие ноды';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Отображать другие типы нод на карте';

  @override
  String get appSettings_timeFilter => 'Фильтр по времени';

  @override
  String get appSettings_timeFilterShowAll => 'Показывать все ноды';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Показывать ноды за последние $hours ч';
  }

  @override
  String get appSettings_mapTimeFilter => 'Временной фильтр карты';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Показывать ноды, обнаруженные за:';

  @override
  String get appSettings_allTime => 'Всё время';

  @override
  String get appSettings_lastHour => 'Последний час';

  @override
  String get appSettings_last6Hours => 'Последние 6 часов';

  @override
  String get appSettings_last24Hours => 'Последние 24 часа';

  @override
  String get appSettings_lastWeek => 'Последнюю неделю';

  @override
  String get appSettings_unitsTitle => 'Единицы';

  @override
  String get appSettings_unitsMetric => 'Метрическая (м/км)';

  @override
  String get appSettings_unitsImperial => 'Имперская (ft / mi)';

  @override
  String get appSettings_debugCard => 'Отладка';

  @override
  String get appSettings_appDebugLogging => 'Журнал отладки приложения';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Записывать отладочные сообщения приложения для диагностики';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Журнал отладки приложения включён';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Журнал отладки приложения отключён';

  @override
  String get appSettings_incrementalContactSync =>
      'Частичная синхронизация контактов';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'При переподключении запрашивать у радио только контакты, изменившиеся с прошлого раза';

  @override
  String get contacts_title => 'Контакты';

  @override
  String get contacts_noContacts => 'Контактов пока нет';

  @override
  String get contacts_shareMyQrCode => 'Поделиться моим QR-кодом';

  @override
  String get contacts_shareQrCodeDesc =>
      'Другие смогут отсканировать его и добавить вас в контакты';

  @override
  String get contacts_contactsWillAppear =>
      'Контакты появятся, когда устройства начнут рассылать оповещения';

  @override
  String get contacts_unread => 'Непрочитанное';

  @override
  String get contacts_searchContactsNoNumber => 'Поиск контактов...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Поиск контактов...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Поиск $number$str избранного...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Поиск $number$str пользователей...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Поиск $number$str ретрансляторов...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Поиск $number$str серверов комнат...';
  }

  @override
  String get contacts_noUnreadContacts => 'Нет непрочитанных контактов';

  @override
  String get contacts_noContactsFound => 'Контакты или группы не найдены';

  @override
  String get contacts_deleteContact => 'Удалить контакт';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Вы уверены, что хотите удалить $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Контакт $contactName удалён.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Не удалось удалить $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Нет контактов, подходящих под фильтр.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Удалить $contactName из контактов?';
  }

  @override
  String get contacts_manageRepeater => 'Управление репитером';

  @override
  String get contacts_manageRoom => 'Управление сервером комнат';

  @override
  String get contacts_roomLogin => 'Вход на сервер комнат';

  @override
  String get contacts_openChat => 'Открыть чат';

  @override
  String get contacts_editGroup => 'Изменить группу';

  @override
  String get contacts_deleteGroup => 'Удалить группу';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Удалить \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Новая группа';

  @override
  String get contacts_groupName => 'Имя группы';

  @override
  String get contacts_groupNameRequired => 'Имя группы обязательно';

  @override
  String get contacts_groupNameReserved => 'Это имя группы зарезервировано';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Группа \"$name\" уже существует';
  }

  @override
  String get contacts_filterContacts => 'Фильтр контактов...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Нет контактов, соответствующих фильтру';

  @override
  String get contacts_noMembers => 'Нет участников';

  @override
  String get contacts_lastSeenNow => 'Видели только что';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Видели $minutes мин назад';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Видели 1 час назад';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Видели $hours ч назад';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Видели 1 день назад';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Видели $days дн. назад';
  }

  @override
  String get contact_info => 'Контактная информация';

  @override
  String get contact_settings => 'Настройки контактов';

  @override
  String get contact_telemetry => 'Телеметрия';

  @override
  String get contact_lastSeen => 'Последний раз видели';

  @override
  String get contact_clearChat => 'Очистить чат';

  @override
  String get contact_teleBase => 'База телеметрии';

  @override
  String get contact_teleBaseSubtitle =>
      'Разрешить обмен уровнем заряда батареи и базовой телеметрией';

  @override
  String get contact_teleLoc => 'Местоположение телеметрии';

  @override
  String get contact_teleLocSubtitle =>
      'Разрешить обмен данными о местоположении';

  @override
  String get contact_teleEnv => 'Среда телеметрии';

  @override
  String get contact_teleEnvSubtitle =>
      'Разрешить обмен данными датчиков окружающей среды';

  @override
  String get contacts_publicKey => 'Публичный ключ';

  @override
  String get channels_title => 'Каналы';

  @override
  String get channels_noChannelsConfigured => 'Каналы не настроены';

  @override
  String get channels_addPublicChannel => 'Добавить публичный канал';

  @override
  String get channels_searchChannels => 'Поиск каналов...';

  @override
  String get channels_noChannelsFound => 'Каналы не найдены';

  @override
  String channels_channelIndex(int index) {
    return 'Канал $index';
  }

  @override
  String get channels_hashtagChannel => 'Хэштег-канал';

  @override
  String get channels_public => 'Публичный';

  @override
  String get channels_private => 'Приватный';

  @override
  String get channels_publicChannel => 'Публичный канал';

  @override
  String get channels_privateChannel => 'Приватный канал';

  @override
  String get channels_editChannel => 'Изменить канал';

  @override
  String get channels_shareChannel => 'Поделиться каналом';

  @override
  String get channels_shareChannelInstructions =>
      'Отсканируйте QR-код, чтобы добавить канал.\nМеню → Добавить канал → Сканировать QR-код';

  @override
  String get channels_secretKey => 'Секретный ключ';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

  @override
  String get channels_shareChannelQr => 'Сканировать QR-код канала';

  @override
  String get channels_shareChannelWarning =>
      'Внимание: любой, кто отсканирует этот QR-код, получит доступ к этому каналу.';

  @override
  String get channels_muteChannel => 'Отключить уведомления канала';

  @override
  String get channels_unmuteChannel => 'Включить уведомления канала';

  @override
  String get channels_deleteChannel => 'Удалить канал';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Удалить \"$name\"? Это действие нельзя отменить.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Не удалось удалить канал $name.';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Канал \"$name\" удалён';
  }

  @override
  String get channels_addChannel => 'Добавить канал';

  @override
  String get channels_channelIndexLabel => 'Индекс канала';

  @override
  String get channels_channelName => 'Имя канала';

  @override
  String get channels_usePublicChannel => 'Использовать публичный канал';

  @override
  String get channels_standardPublicPsk => 'Стандартный публичный PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Сгенерировать случайный PSK';

  @override
  String get channels_enterChannelName => 'Введите имя канала';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK должен содержать 32 шестнадцатеричных символа';

  @override
  String get channels_addChannelConfirmation => 'Добавить этот канал?';

  @override
  String get channels_channelAddedSuccess => 'Канал добавлен.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Нет свободных слотов для каналов.';

  @override
  String get appSettings_mentionNotifications => 'Уведомления об упоминаниях';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Когда вас упоминают или вам отвечают — даже в каналах без уведомлений';

  @override
  String notification_mentionIn(String channelName) {
    return 'Упоминание в $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Канал \"$name\" добавлен';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Изменить канал $index';
  }

  @override
  String get channels_smazCompression => 'Сжатие SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Канал \"$name\" обновлён';
  }

  @override
  String get channels_publicChannelAdded => 'Публичный канал добавлен';

  @override
  String get channels_sortBy => 'Сортировка';

  @override
  String get channels_sortManual => 'Вручную';

  @override
  String get channels_sortAZ => 'По алфавиту';

  @override
  String get channels_sortLatestMessages => 'По последним сообщениям';

  @override
  String get channels_sortUnread => 'По непрочитанным';

  @override
  String get channels_createPrivateChannel => 'Создать приватный канал';

  @override
  String get channels_createPrivateChannelDesc => 'Защищён секретным ключом.';

  @override
  String get channels_joinPrivateChannel =>
      'Присоединиться к приватному каналу';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Введите секретный ключ вручную.';

  @override
  String get channels_joinPublicChannel => 'Присоединиться к публичному каналу';

  @override
  String get channels_joinPublicChannelDesc =>
      'К этому каналу может присоединиться любой.';

  @override
  String get channels_joinHashtagChannel => 'Присоединиться к хэштег-каналу';

  @override
  String get channels_joinHashtagChannelDesc =>
      'К хэштег-каналам может присоединиться любой.';

  @override
  String get channels_scanQrCode => 'Сканировать QR-код';

  @override
  String get channels_scanQrCodeComingSoon => 'Скоро будет';

  @override
  String get channels_enterHashtag => 'Введите хэштег';

  @override
  String get channels_hashtagHint => 'например, #команда';

  @override
  String get chat_noMessages => 'Сообщений пока нет';

  @override
  String get chat_sendMessage => 'Отправить сообщение';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Отправить сообщение $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Отправьте сообщение, чтобы начать';

  @override
  String get chat_originalMessageNotFound => 'Исходное сообщение не найдено';

  @override
  String chat_replyingTo(String name) {
    return 'Ответ для $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Ответить $name';
  }

  @override
  String get chat_location => 'Местоположение';

  @override
  String get common_copiedToClipboard => 'Скопировано в буфер обмена';

  @override
  String get common_copyToClipboard => 'Копировать в буфер обмена';

  @override
  String get contacts_copyContactToClipboard =>
      'Копировать мой контакт в буфер обмена';

  @override
  String get chat_typeMessage => 'Напишите сообщение...';

  @override
  String get chat_searchMessages => 'Поиск сообщений';

  @override
  String get chat_searchNoMatches => 'Нет совпадений';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Сообщение слишком длинное (макс. $maxBytes байт).';
  }

  @override
  String get chat_messageCopied => 'Сообщение скопировано';

  @override
  String get chat_messageDeleted => 'Сообщение удалено';

  @override
  String get chat_sendGif => 'Отправить GIF';

  @override
  String get chat_reply => 'Ответить';

  @override
  String get chat_newMessages => 'НОВЫЕ СООБЩЕНИЯ';

  @override
  String get chat_addReaction => 'Добавить реакцию';

  @override
  String get chat_mention => 'Упомянуть';

  @override
  String get dmChannel_menuLabel => 'Личное сообщение';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Написать в ЛС: $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Проверьте ключ и время последней активности — имена не уникальны.';

  @override
  String get dmChannel_warningTitle => 'Это точно тот человек?';

  @override
  String get dmChannel_warningBody =>
      'Имена в каналах пользователи выбирают сами, и подделать их может кто угодно. Если речь о чём-то важном, сначала проверьте публичный ключ этого контакта другим способом.';

  @override
  String get dmChannel_dontShowAgain => 'Больше не показывать';

  @override
  String get batterySleep_title => 'Не давайте MeshTrax засыпать';

  @override
  String get batterySleep_bodySamsung =>
      'Телефоны Samsung усыпляют приложения ради экономии батареи, и связь с радио обрывается. Откройте Настройки → Приложения → MeshTrax → Батарея и выберите «Без ограничений». Также проверьте Батарея → Ограничения фонового использования и убедитесь, что MeshTrax нет в списках «Спящие приложения» и «Приложения в глубоком сне».';

  @override
  String get batterySleep_bodyGeneric =>
      'Телефон может останавливать MeshTrax в фоне ради экономии батареи, и связь с радио обрывается. Откройте настройки батареи и выберите для MeshTrax «Без ограничений» (или «Нет ограничений»). На некоторых телефонах также нужно включить «Автозапуск» для MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Открыть настройки';

  @override
  String get batterySleep_notNow => 'Не сейчас';

  @override
  String get batterySleep_settingsTile => 'Работа MeshTrax в фоне';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Не давать экономии батареи усыплять MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Пока нельзя написать $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'У вас пока нет их ключа, а им нужен ваш, чтобы ответить, — ключи передаются только в анонсах. «Отправить мой анонс» рассылает ваш прямо отсюда. «Спросить в канале» вписывает просьбу в поле сообщения, чтобы вы её отправили.';

  @override
  String get dmChannel_askInChannel => 'Спросить в канале';

  @override
  String get dmChannel_sendMyAdvert => 'Отправить мой анонс';

  @override
  String get dmChannel_askText =>
      'пожалуйста, отправьте анонс, чтобы можно было написать вам в ЛС';

  @override
  String get dmChannel_watching =>
      'Ждём их анонс — когда он придёт, вас спросят здесь.';

  @override
  String dmChannel_advertHeard(String name) {
    return 'С $name теперь можно связаться';
  }

  @override
  String get dmChannel_openDm => 'ЛС';

  @override
  String get appSettings_zoomLevel => 'Уровень масштаба';

  @override
  String get common_reset => 'Сбросить';

  @override
  String get chat_reactionsTitle => 'Реакции';

  @override
  String get chat_reactionUnknownSender => 'Неизвестный';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender: реакция на сообщение, которого нет в этом чате';
  }

  @override
  String get chat_me => 'Я';

  @override
  String get emojiCategorySmileys => 'Смайлы';

  @override
  String get emojiCategoryGestures => 'Жесты';

  @override
  String get emojiCategoryHearts => 'Сердечки';

  @override
  String get emojiCategoryObjects => 'Предметы';

  @override
  String get gifPicker_title => 'Выберите GIF';

  @override
  String get gifPicker_searchHint => 'Поиск GIF...';

  @override
  String get gifPicker_poweredBy => 'Работает на GIPHY';

  @override
  String get gifPicker_noGifsFound => 'GIF не найдены';

  @override
  String get gifPicker_failedLoad => 'Не удалось загрузить GIF';

  @override
  String get gifPicker_failedSearch => 'Не удалось выполнить поиск GIF';

  @override
  String get gifPicker_noInternet => 'Нет подключения к интернету';

  @override
  String get debugLog_appTitle => 'Журнал отладки приложения';

  @override
  String get debugLog_bleTitle => 'Журнал отладки BLE';

  @override
  String get debugLog_copyLog => 'Копировать журнал';

  @override
  String get debugLog_saveLog => 'Сохранить журнал в файл';

  @override
  String get debugLog_saved => 'Журнал сохранён';

  @override
  String get debugLog_saveCancelled => 'Сохранение отменено';

  @override
  String get debugLog_filterAll => 'Все';

  @override
  String get debugLog_filterWarnings => 'Предупреждения';

  @override
  String get debugLog_filterErrors => 'Ошибки';

  @override
  String get debugLog_clearLog => 'Очистить журнал';

  @override
  String get debugLog_copied => 'Журнал отладки скопирован';

  @override
  String get debugLog_bleCopied => 'Журнал BLE скопирован';

  @override
  String get debugLog_noEntries => 'Журнал отладки пока пуст';

  @override
  String get debugLog_enableInSettings =>
      'Включите запись журнала отладки в настройках';

  @override
  String get debugLog_frames => 'Фреймы';

  @override
  String get debugLog_rawLogRx => 'Сырой журнал приёма';

  @override
  String get debugLog_noBleActivity => 'Активность BLE пока отсутствует';

  @override
  String debugFrame_length(int count) {
    return 'Длина фрейма: $count байт';
  }

  @override
  String debugFrame_command(String value) {
    return 'Команда: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Фрейм текстового сообщения:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Публичный ключ получателя: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Временная метка: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Флаги: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Тип текста: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Команда CLI';

  @override
  String get debugFrame_textTypePlain => 'Обычный';

  @override
  String debugFrame_text(String text) {
    return '- Текст: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Шестнадцатеричный дамп:';

  @override
  String get chat_hopSingular => 'хоп';

  @override
  String get chat_hopPlural => 'хопов';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'хопов',
      many: 'хопов',
      few: 'хопа',
      one: 'хоп',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Указать маршрут вручную';

  @override
  String get chat_fullPath => 'Полный маршрут';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Детали маршрута ещё недоступны. Попробуйте отправить сообщение для обновления.';

  @override
  String get chat_type => 'Тип';

  @override
  String get chat_path => 'Маршрут';

  @override
  String get chat_publicKey => 'Публичный ключ';

  @override
  String get chat_compressOutgoingMessages => 'Сжимать исходящие сообщения';

  @override
  String get chat_floodForced => 'Рассылка (принудительно)';

  @override
  String get chat_directForced => 'Прямой (принудительно)';

  @override
  String chat_hopsForced(int count) {
    return '$count хоп(ов) (принудительно)';
  }

  @override
  String get chat_floodAuto => 'Рассылка (авто)';

  @override
  String get chat_direct => 'Прямой';

  @override
  String get chat_poiShared => 'Точка интереса отправлена';

  @override
  String chat_unread(int count) {
    return 'Непрочитанных: $count';
  }

  @override
  String get chat_openLink => 'Открыть ссылку?';

  @override
  String get chat_openLinkConfirmation =>
      'Хотите открыть эту ссылку в вашем браузере?';

  @override
  String get chat_open => 'Открыть';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Не удалось открыть ссылку: $url';
  }

  @override
  String get chat_invalidLink => 'Неправильный формат ссылки';

  @override
  String get map_lineOfSight => 'Линия видимости';

  @override
  String get map_losScreenTitle => 'Линия видимости';

  @override
  String get map_noNodesWithLocation => 'Нет нод с данными о местоположении';

  @override
  String get map_nodesNeedGps =>
      'Ноды должны передавать свои GPS-координаты, чтобы отображаться на карте';

  @override
  String map_nodesCount(int count) {
    return 'Нод: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Меток: $count';
  }

  @override
  String get map_chat => 'Чат';

  @override
  String get map_repeater => 'Репитер';

  @override
  String get map_room => 'Комната';

  @override
  String get map_sensor => 'Сенсор';

  @override
  String get map_pinDm => 'Метка (ЛС)';

  @override
  String get map_pinPrivate => 'Метка (Приватная)';

  @override
  String get map_pinPublic => 'Метка (Публичная)';

  @override
  String get map_lastSeen => 'Последнее появление';

  @override
  String get map_disconnectConfirm =>
      'Вы уверены, что хотите отключиться от этого устройства?';

  @override
  String get map_from => 'От';

  @override
  String get map_source => 'Источник';

  @override
  String get map_flags => 'Флаги';

  @override
  String get map_shareMarkerHere => 'Поделиться меткой здесь';

  @override
  String get map_setAsMyLocation => 'Установить мое местоположение';

  @override
  String get map_pinLabel => 'Метка';

  @override
  String get map_label => 'Подпись';

  @override
  String get map_pointOfInterest => 'Точка интереса';

  @override
  String get map_sendToContact => 'Отправить контакту';

  @override
  String get map_sendToChannel => 'Отправить в канал';

  @override
  String get map_noChannelsAvailable => 'Нет доступных каналов';

  @override
  String get map_publicLocationShare => 'Публичная передача местоположения';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Вы собираетесь поделиться местоположением в $channelLabel. Этот канал публичный, и любой, у кого есть PSK, сможет его увидеть.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Подключитесь к устройству, чтобы делиться метками';

  @override
  String get map_filterNodes => 'Фильтр нод';

  @override
  String get map_chatNodes => 'Чат-ноды';

  @override
  String get map_repeaters => 'Репитеры';

  @override
  String get map_otherNodes => 'Другие ноды';

  @override
  String get map_showOverlaps => 'Перекрытия ключа повтора';

  @override
  String get map_keyPrefix => 'Префикс ключа';

  @override
  String get map_filterByKeyPrefix => 'Фильтр по префиксу ключа';

  @override
  String get map_publicKeyPrefix => 'Префикс публичного ключа';

  @override
  String get map_showDiscoveryContacts => 'Показать контакты Discovery';

  @override
  String get map_guessedLocation => 'Угаданное место';

  @override
  String get map_lastSeenTime => 'Время последнего появления';

  @override
  String get map_sharedPin => 'Общая метка';

  @override
  String get map_joinRoom => 'Присоединиться к комнате';

  @override
  String get map_manageRepeater => 'Управление репитером';

  @override
  String get map_tapToAdd => 'Нажимайте на узлы, чтобы добавить их в путь.';

  @override
  String get map_runTrace => 'Запустить трассировку пути';

  @override
  String get map_runTraceWithReturnPath => 'Вернуться обратно по тому же пути';

  @override
  String get map_removeLast => 'Удалить последний';

  @override
  String get map_pathTraceCancelled => 'Отмена трассировки пути';

  @override
  String get time_justNow => 'Только что';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes мин назад';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours ч назад';
  }

  @override
  String time_daysAgo(int days) {
    return '$days дн. назад';
  }

  @override
  String get time_hour => 'час';

  @override
  String get time_hours => 'часов';

  @override
  String get time_day => 'день';

  @override
  String get time_days => 'дней';

  @override
  String get time_week => 'неделя';

  @override
  String get time_weeks => 'недель';

  @override
  String get time_month => 'месяц';

  @override
  String get time_months => 'месяцев';

  @override
  String get time_minutes => 'минут';

  @override
  String get time_allTime => 'Всё время';

  @override
  String get dialog_disconnect => 'Отключиться';

  @override
  String get dialog_disconnectConfirm =>
      'Вы уверены, что хотите отключиться от этого устройства?';

  @override
  String get login_repeaterLogin => 'Вход в репитер';

  @override
  String get login_roomLogin => 'Вход на сервер комнат';

  @override
  String get login_password => 'Пароль';

  @override
  String get login_enterPassword => 'Введите пароль';

  @override
  String get login_savePassword => 'Сохранить пароль';

  @override
  String get login_savePasswordSubtitle =>
      'Пароль будет надёжно сохранён на этом устройстве';

  @override
  String get login_repeaterDescription =>
      'Введите пароль репитера для доступа к настройкам и статусу.';

  @override
  String get login_roomDescription =>
      'Введите пароль комнаты для доступа к настройкам и статусу.';

  @override
  String get login_login => 'Войти';

  @override
  String login_attempt(int current, int max) {
    return 'Попытка $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get login_failedMessage =>
      'Не удалось войти. Либо пароль неверен, либо репитер недоступен.';

  @override
  String get common_reload => 'Обновить';

  @override
  String get common_clear => 'Очистить';

  @override
  String get path_enterCustomPath => 'Введите маршрут вручную';

  @override
  String get path_currentPathLabel => 'Текущий маршрут';

  @override
  String get path_hexPrefixInstructions =>
      'Введите 2-символьные шестнадцатеричные префиксы для каждого хопа, разделённые запятыми.';

  @override
  String get path_hexPrefixExample =>
      'Пример: A1,F2,3C (каждый узел использует первый байт своего публичного ключа)';

  @override
  String get path_labelHexPrefixes => 'Маршрут (шестнадцатеричные префиксы)';

  @override
  String get path_helperMaxHops =>
      'Максимум 64 хопа. Каждый префикс — 2 шестнадцатеричных символа (1 байт)';

  @override
  String get path_selectFromContacts => 'Или выберите из контактов:';

  @override
  String get path_noRepeatersFound => 'Репитеры или серверы комнат не найдены.';

  @override
  String get path_customPathsRequire =>
      'Пользовательские маршруты требуют промежуточных узлов, способных ретранслировать сообщения.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Недопустимые шестнадцатеричные префиксы: $prefixes';
  }

  @override
  String get path_tooLong => 'Маршрут слишком длинный. Максимум 64 хопа.';

  @override
  String get path_setPath => 'Установить маршрут';

  @override
  String get repeater_management => 'Управление репитером';

  @override
  String get room_management => 'Управление сервером комнат';

  @override
  String get repeater_guest => 'Информация о ретрансляторе';

  @override
  String get room_guest => 'Информация о сервере';

  @override
  String get repeater_managementTools => 'Инструменты управления';

  @override
  String get repeater_guestTools => 'Инструменты для гостей';

  @override
  String get repeater_status => 'Статус';

  @override
  String get repeater_statusSubtitle =>
      'Просмотр статуса, статистики и соседей репитера';

  @override
  String get repeater_telemetry => 'Телеметрия';

  @override
  String get repeater_telemetrySubtitle =>
      'Просмотр телеметрии датчиков и системной статистики';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Отправка команд репитеру';

  @override
  String get repeater_neighbors => 'Соседи';

  @override
  String get repeater_neighborsSubtitle => 'Просмотр соседей на нулевом хопе.';

  @override
  String get repeater_settings => 'Настройки';

  @override
  String get repeater_settingsSubtitle => 'Настройка параметров репитера';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Синхронизация часов после входа в систему';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Автоматически отправлять сообщение \"синхронизация времени\" после успешной авторизации.';

  @override
  String get repeater_statusTitle => 'Статус репитера';

  @override
  String get repeater_refresh => 'Обновить';

  @override
  String get repeater_statusRequestTimeout => 'Время ожидания статуса истекло.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Ошибка загрузки статуса: $error';
  }

  @override
  String get repeater_systemInformation => 'Системная информация';

  @override
  String get repeater_battery => 'Батарея';

  @override
  String get repeater_clockAtLogin => 'Время (при входе)';

  @override
  String get repeater_uptime => 'Время работы';

  @override
  String get repeater_queueLength => 'Длина очереди';

  @override
  String get repeater_debugFlags => 'Флаги отладки';

  @override
  String get repeater_radioStatistics => 'Радиостатистика';

  @override
  String get repeater_lastRssi => 'Последний RSSI';

  @override
  String get repeater_lastSnr => 'Последний SNR';

  @override
  String get repeater_noiseFloor => 'Уровень шума';

  @override
  String get repeater_txAirtime => 'Время эфира (передача)';

  @override
  String get repeater_rxAirtime => 'Время эфира (приём)';

  @override
  String get repeater_packetStatistics => 'Статистика пакетов';

  @override
  String get repeater_sent => 'Отправлено';

  @override
  String get repeater_received => 'Получено';

  @override
  String get repeater_duplicates => 'Дубликаты';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days дн. $hoursч $minutesм $secondsс';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Всего: $total, Рассылка: $flood, Прямые: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Всего: $total, Рассылка: $flood, Прямые: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Рассылка: $flood, Прямые: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Всего: $total';
  }

  @override
  String get repeater_settingsTitle => 'Настройки репитера';

  @override
  String get repeater_basicSettings => 'Основные настройки';

  @override
  String get repeater_repeaterName => 'Имя репитера';

  @override
  String get repeater_repeaterNameHelper => 'Отображаемое имя этого репитера';

  @override
  String get repeater_adminPassword => 'Пароль администратора';

  @override
  String get repeater_adminPasswordHelper => 'Пароль с полным доступом';

  @override
  String get repeater_guestPassword => 'Гостевой пароль';

  @override
  String get repeater_guestPasswordHelper =>
      'Пароль для доступа только для чтения';

  @override
  String get repeater_radioSettings => 'Настройки радио';

  @override
  String get repeater_frequencyMhz => 'Частота (МГц)';

  @override
  String get repeater_frequencyHelper => '300–2500 МГц';

  @override
  String get repeater_txPower => 'Мощность передачи';

  @override
  String get repeater_txPowerHelper => '-9 – 30 дБм';

  @override
  String get repeater_bandwidth => 'Полоса пропускания';

  @override
  String get repeater_spreadingFactor => 'Коэффициент расширения';

  @override
  String get repeater_codingRate => 'Коэффициент кодирования';

  @override
  String get repeater_locationSettings => 'Настройки местоположения';

  @override
  String get repeater_latitude => 'Широта';

  @override
  String get repeater_latitudeHelper =>
      'В десятичных градусах (напр., 37.7749)';

  @override
  String get repeater_longitude => 'Долгота';

  @override
  String get repeater_longitudeHelper =>
      'В десятичных градусах (напр., -122.4194)';

  @override
  String get repeater_features => 'Функции';

  @override
  String get repeater_packetForwarding => 'Пересылка пакетов';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Разрешить репитеру пересылать пакеты';

  @override
  String get repeater_guestAccess => 'Гостевой доступ';

  @override
  String get repeater_guestAccessSubtitle =>
      'Разрешить гостевой доступ только для чтения';

  @override
  String get repeater_privacyMode => 'Режим конфиденциальности';

  @override
  String get repeater_privacyModeSubtitle =>
      'Скрывать имя/местоположение в оповещениях';

  @override
  String get repeater_advertisementSettings => 'Настройки анонсирования';

  @override
  String get repeater_localAdvertInterval => 'Интервал локальных анонсирований';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes минут';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Интервал анонсирований рассылкой (flood)';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours часов';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Интервал зашифрованных анонсирований';

  @override
  String get repeater_dangerZone => 'Опасная зона';

  @override
  String get repeater_rebootRepeater => 'Перезагрузить репитер';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Перезапустить устройство репитера';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Вы уверены, что хотите перезагрузить этот репитер?';

  @override
  String get repeater_regenerateIdentityKey => 'Пересоздать ключ идентификации';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Сгенерировать новую пару публичного/приватного ключей';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Это создаст новую идентичность для репитера. Продолжить?';

  @override
  String get repeater_eraseFileSystem => 'Стереть файловую систему';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Отформатировать файловую систему репитера';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ВНИМАНИЕ: это удалит все данные на репитере. Действие нельзя отменить!';

  @override
  String get repeater_eraseSerialOnly =>
      'Очистка доступна только через последовательную консоль.';

  @override
  String repeater_commandSent(String command) {
    return 'Команда отправлена: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Ошибка отправки команды: $error';
  }

  @override
  String get repeater_confirm => 'Подтвердить';

  @override
  String get repeater_settingsSaved => 'Настройки успешно сохранены';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Ошибка сохранения настроек: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Обновить основные настройки';

  @override
  String get repeater_refreshRadioSettings => 'Обновить настройки радио';

  @override
  String get repeater_refreshTxPower => 'Обновить мощность передачи';

  @override
  String get repeater_refreshLocationSettings =>
      'Обновить настройки местоположения';

  @override
  String get repeater_refreshPacketForwarding => 'Обновить пересылку пакетов';

  @override
  String get repeater_refreshGuestAccess => 'Обновить гостевой доступ';

  @override
  String get repeater_refreshPrivacyMode => 'Обновить режим конфиденциальности';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Обновить настройки анонсирований';

  @override
  String repeater_refreshed(String label) {
    return '$label обновлён';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Ошибка обновления $label';
  }

  @override
  String get repeater_cliTitle => 'CLI репитера';

  @override
  String get repeater_debugNextCommand => 'Отладка следующей команды';

  @override
  String get repeater_commandHelp => 'Справка по командам';

  @override
  String get repeater_clearHistory => 'Очистить историю';

  @override
  String get repeater_noCommandsSent => 'Команды ещё не отправлялись';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Введите команду ниже или используйте быстрые команды';

  @override
  String get repeater_enterCommandHint => 'Введите команду...';

  @override
  String get repeater_previousCommand => 'Предыдущая команда';

  @override
  String get repeater_nextCommand => 'Следующая команда';

  @override
  String get repeater_enterCommandFirst => 'Сначала введите команду';

  @override
  String get repeater_cliCommandFrameTitle => 'Фрейм CLI-команды';

  @override
  String repeater_cliCommandError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Получить имя';

  @override
  String get repeater_cliQuickGetRadio => 'Получить радио';

  @override
  String get repeater_cliQuickGetTx => 'Получить TX';

  @override
  String get repeater_cliQuickNeighbors => 'Соседи';

  @override
  String get repeater_cliQuickVersion => 'Версия';

  @override
  String get repeater_cliQuickAdvertise => 'Анонсировать';

  @override
  String get repeater_cliQuickClock => 'Время';

  @override
  String get repeater_cliQuickClockSync => 'Синхронизация часов';

  @override
  String get repeater_cliQuickDiscovery => 'Обнаружить Соседей';

  @override
  String get repeater_cliHelpAdvert => 'Отправляет пакет анонсирования';

  @override
  String get repeater_cliHelpReboot =>
      'Перезагружает устройство. (обычно вы получите «Тайм-аут» — это нормально)';

  @override
  String get repeater_cliHelpClock =>
      'Показывает текущее время по часам устройства.';

  @override
  String get repeater_cliHelpPassword =>
      'Устанавливает новый пароль администратора для устройства.';

  @override
  String get repeater_cliHelpVersion =>
      'Показывает версию устройства и дату сборки прошивки.';

  @override
  String get repeater_cliHelpClearStats =>
      'Сбрасывает различные счётчики статистики в ноль.';

  @override
  String get repeater_cliHelpSetAf =>
      'Устанавливает коэффициент времени в эфире.';

  @override
  String get repeater_cliHelpSetTx =>
      'Устанавливает мощность передачи LoRa в дБм. (требуется перезагрузка)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Включает или отключает роль репитера для этой ноды.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Сервер комнат) Если «on», то вход без пароля разрешён, но публиковать в комнату нельзя (только чтение)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Устанавливает максимальное число хопов для входящих пакетов в режиме рассылки (если >= макс., пакет не пересылается)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Устанавливает порог интерференции (в дБ). По умолчанию 14. Установите 0, чтобы отключить обнаружение помех.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Устанавливает интервал сброса автоматической регулировки усиления. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Включает или отключает функцию «двойных ACK».';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Устанавливает интервал (в минутах) отправки локального (нулевой хоп) анонсирования. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Устанавливает интервал (в часах) отправки анонсирований рассылкой. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Устанавливает/обновляет гостевой пароль. (для репитеров гости могут отправлять запрос «Get Stats»)';

  @override
  String get repeater_cliHelpSetName => 'Устанавливает имя в оповещениях.';

  @override
  String get repeater_cliHelpSetLat =>
      'Устанавливает широту для карты в оповещениях. (десятичные градусы)';

  @override
  String get repeater_cliHelpSetLon =>
      'Устанавливает долготу для карты в оповещениях. (десятичные градусы)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Устанавливает полностью новые параметры радио и сохраняет их в настройки. Требуется команда «reboot» для применения.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Устанавливает (экспериментально) базовую задержку (>1 для эффекта) для принятых пакетов на основе качества сигнала. Установите 0, чтобы отключить.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Устанавливает множитель времени в эфире для пакета в режиме рассылки и применяет случайную задержку перед пересылкой (чтобы уменьшить коллизии).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'То же, что txdelay, но для случайной задержки пересылки пакетов в прямом режиме.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Включить/выключить мост.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Установить задержку перед ретрансляцией пакетов.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Выбрать, будет ли мост ретранслировать полученные или отправленные пакеты.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Установить скорость последовательного соединения для мостов RS232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Установить секрет моста для мостов ESP-NOW.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Устанавливает пользовательский коэффициент коррекции напряжения батареи (поддерживается только на некоторых платах).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Устанавливает временные параметры радио на заданное число минут, затем возвращает исходные. (НЕ сохраняется в настройки).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Изменяет ACL. Удаляет запись (по префиксу публичного ключа), если «permissions» равен нулю. Добавляет новую запись, если указан полный ключ и он отсутствует в ACL. Обновляет запись по совпадению префикса. Биты прав зависят от роли прошивки, но младшие 2 бита: 0 (Гость), 1 (Только чтение), 2 (Чтение/запись), 3 (Админ)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Получает тип моста: none, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Начинает запись пакетов в файловую систему.';

  @override
  String get repeater_cliHelpLogStop =>
      'Останавливает запись пакетов в файловую систему.';

  @override
  String get repeater_cliHelpLogErase =>
      'Удаляет журналы пакетов из файловой системы.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Показывает список других репитеров, услышанных через оповещения нулевого хопа. Каждая строка: префикс-id-в-hex:временная-метка:snr×4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Удаляет первую подходящую запись (по префиксу публичного ключа в hex) из списка соседей.';

  @override
  String get repeater_cliHelpRegion =>
      '(только через последовательный порт) Показывает все определённые регионы и текущие права на рассылку.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'ПРИМЕЧАНИЕ: это специальная многострочная команда. Каждая следующая строка — имя региона (с отступом пробелами для указания иерархии, минимум один пробел). Завершается пустой строкой.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Ищет регион по префиксу имени (или «*» для глобальной области). Отвечает: «-> имя-региона (родитель) \'F\'»';

  @override
  String get repeater_cliHelpRegionPut =>
      'Добавляет или обновляет определение региона с заданным именем.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Удаляет определение региона с заданным именем. (должно точно совпадать и не иметь дочерних регионов)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Разрешает рассылку («F»lood) для заданного региона. («*» для глобальной/устаревшей области)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Запрещает рассылку («F»lood) для заданного региона. (НЕ рекомендуется для глобальной области!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Показывает текущий «домашний» регион. (Пока не используется, зарезервировано на будущее)';

  @override
  String get repeater_cliHelpRegionHomeSet =>
      'Устанавливает «домашний» регион.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Сохраняет список/карту регионов в память.';

  @override
  String get repeater_cliHelpGps =>
      'Показывает статус GPS. Если GPS выключен — отвечает только «off». Если включён — показывает статус, фиксацию, количество спутников.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Переключает состояние питания GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Синхронизирует время ноды с часами GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Устанавливает позицию ноды по координатам GPS и сохраняет в настройки.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Показывает конфигурацию передачи местоположения в анонсированиях:\n- none: не включать местоположение\n- share: передавать GPS-координаты (из SensorManager)\n- prefs: передавать координаты из настроек';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Устанавливает конфигурацию передачи местоположения.';

  @override
  String get repeater_commandsListTitle => 'Список команд';

  @override
  String get repeater_commandsListNote =>
      'ПРИМЕЧАНИЕ: для большинства команд «set ...» существуют соответствующие команды «get ...».';

  @override
  String get repeater_general => 'Общие';

  @override
  String get repeater_settingsCategory => 'Настройки';

  @override
  String get repeater_bridge => 'Мост';

  @override
  String get repeater_logging => 'Журналирование';

  @override
  String get repeater_neighborsRepeaterOnly => 'Соседи (только для репитеров)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Управление регионами (только для репитеров)';

  @override
  String get repeater_regionNote =>
      'Команды регионов введены для управления определениями регионов и правами доступа.';

  @override
  String get repeater_gpsManagement => 'Управление GPS';

  @override
  String get repeater_gpsNote =>
      'Команда gps введена для управления параметрами, связанными с местоположением.';

  @override
  String get telemetry_receivedData => 'Полученные телеметрические данные';

  @override
  String get telemetry_requestTimeout => 'Время ожидания телеметрии истекло.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Ошибка загрузки телеметрии: $error';
  }

  @override
  String get telemetry_noData => 'Данные телеметрии недоступны.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Канал $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Батарея';

  @override
  String get telemetry_voltageLabel => 'Напряжение';

  @override
  String get telemetry_mcuTemperatureLabel => 'Температура МК';

  @override
  String get telemetry_temperatureLabel => 'Температура';

  @override
  String get telemetry_currentLabel => 'Ток';

  @override
  String telemetry_batteryValue(int percent, String volts) {
    return '$percent% / $voltsВ';
  }

  @override
  String telemetry_voltageValue(String volts) {
    return '$voltsВ';
  }

  @override
  String telemetry_currentValue(String amps) {
    return '$ampsА';
  }

  @override
  String telemetry_temperatureValue(String celsius, String fahrenheit) {
    return '$celsius°C / $fahrenheit°F';
  }

  @override
  String get neighbors_receivedData => 'Полученные данные о соседях';

  @override
  String get neighbors_requestTimedOut =>
      'Время ожидания данных о соседях истекло.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Ошибка загрузки соседей: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Соседи репитеров';

  @override
  String get neighbors_noData => 'Данные о соседях недоступны.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Неизвестный $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Слушал(а): $time назад';
  }

  @override
  String get channelPath_title => 'Путь пакета';

  @override
  String get channelPath_viewMap => 'Посмотреть на карте';

  @override
  String get channelPath_otherObservedPaths => 'Другие наблюдаемые пути';

  @override
  String get channelPath_repeaterHops => 'Хопы через репитеры';

  @override
  String get channelPath_noHopDetails =>
      'Детали хопов для этого пакета не предоставлены.';

  @override
  String get channelPath_messageDetails => 'Детали сообщения';

  @override
  String get channelPath_senderLabel => 'Отправитель';

  @override
  String get channelPath_timeLabel => 'Время';

  @override
  String get channelPath_repeatsLabel => 'Повторы';

  @override
  String channelPath_pathLabel(int index) {
    return 'Путь $index';
  }

  @override
  String get channelPath_observedLabel => 'Наблюдаемый';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Наблюдаемый путь $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Нет данных о местоположении';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Неизвестный';

  @override
  String get channelPath_floodPath => 'Рассылка';

  @override
  String get channelPath_directPath => 'Прямой';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 из $total хопов';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed из $total хопов';
  }

  @override
  String get channelPath_mapTitle => 'Карта пути';

  @override
  String get channelPath_noRepeaterLocations =>
      'Нет данных о местоположении репитеров для этого пути.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Путь $index (Основной)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Путь';

  @override
  String get channelPath_observedPathHeader => 'Наблюдаемый путь';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Детали хопов для этого пакета недоступны.';

  @override
  String get channelPath_unknownRepeater => 'Неизвестный репитер';

  @override
  String get community_title => 'Сообщество';

  @override
  String get community_create => 'Создать сообщество';

  @override
  String get community_createDesc =>
      'Создать новое сообщество и поделиться через QR-код.';

  @override
  String get community_join => 'Присоединиться';

  @override
  String get community_joinTitle => 'Присоединиться к сообществу';

  @override
  String community_joinConfirmation(String name) {
    return 'Вы хотите присоединиться к сообществу  \"$name\"?';
  }

  @override
  String get community_scanQr => 'Сканировать QR-код сообщества';

  @override
  String get community_scanInstructions =>
      'Наведите камеру на QR-код сообщества';

  @override
  String get community_showQr => 'Показать QR-код';

  @override
  String get community_publicChannel => 'Публичный канал сообщества';

  @override
  String get community_hashtagChannel => 'Хэштег-канал сообщества';

  @override
  String get community_name => 'Имя сообщества';

  @override
  String get community_enterName => 'Введите имя сообщества';

  @override
  String community_created(String name) {
    return 'Сообщество \"$name\" создано';
  }

  @override
  String community_joined(String name) {
    return 'Присоединились к сообществу \"$name\"';
  }

  @override
  String get community_qrTitle => 'Поделиться сообществом';

  @override
  String community_qrInstructions(String name) {
    return 'Отсканируйте этот QR-код, чтобы присоединиться к \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Хэштег-каналы сообщества доступны только его участникам';

  @override
  String get community_invalidQrCode => 'Недопустимый QR-код сообщества';

  @override
  String get community_alreadyMember => 'Уже участник';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Вы уже участник сообщества \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Добавить публичный канал сообщества';

  @override
  String get community_addPublicChannelHint =>
      'Автоматически добавить публичный канал для этого сообщества';

  @override
  String get community_noCommunities =>
      'Вы ещё не присоединились ни к одному сообществу';

  @override
  String get community_scanOrCreate =>
      'Отсканируйте QR-код или создайте сообщество, чтобы начать';

  @override
  String get community_manageCommunities => 'Управление сообществами';

  @override
  String get community_delete => 'Покинуть сообщество';

  @override
  String community_deleteConfirm(String name) {
    return 'Покинуть \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Это также удалит $count канал(ов) и их сообщения.';
  }

  @override
  String community_deleted(String name) {
    return 'Покинули сообщество \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Пересоздать секрет';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Пересоздать секретный ключ для \"$name\"? Все участники должны будут отсканировать новый QR-код для продолжения общения.';
  }

  @override
  String get community_regenerate => 'Пересоздать';

  @override
  String community_secretRegenerated(String name) {
    return 'Секрет пересоздан для \"$name\"';
  }

  @override
  String get community_updateSecret => 'Обновить секрет';

  @override
  String community_secretUpdated(String name) {
    return 'Секрет обновлён для \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Отсканируйте новый QR-код, чтобы обновить секрет для \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Добавить хэштег-канал сообщества';

  @override
  String get community_addHashtagChannelDesc =>
      'Добавить хэштег-канал для этого сообщества';

  @override
  String get community_selectCommunity => 'Выбрать сообщество';

  @override
  String get community_regularHashtag => 'Обычный хэштег';

  @override
  String get community_regularHashtagDesc =>
      'Публичный хэштег (любой может присоединиться)';

  @override
  String get community_communityHashtag => 'Хэштег сообщества';

  @override
  String get community_communityHashtagDesc =>
      'Доступен только участникам сообщества';

  @override
  String community_forCommunity(String name) {
    return 'Для $name';
  }

  @override
  String get listFilter_tooltip => 'Фильтр и сортировка';

  @override
  String get listFilter_sortBy => 'Сортировка по';

  @override
  String get listFilter_latestMessages => 'Последние сообщения';

  @override
  String get listFilter_heardRecently => 'Слышали недавно';

  @override
  String get listFilter_az => 'По алфавиту';

  @override
  String get listFilter_filters => 'Фильтры';

  @override
  String get listFilter_source => 'Источник';

  @override
  String get listFilter_saved => 'Сохранённые';

  @override
  String get listFilter_discovered => 'Обнаруженные';

  @override
  String get listFilter_all => 'Все';

  @override
  String get listFilter_favorites => 'Избранное';

  @override
  String get listFilter_addToFavorites => 'Добавить в избранное';

  @override
  String get listFilter_removeFromFavorites => 'Удалить из избранного';

  @override
  String get listFilter_users => 'Пользователи';

  @override
  String get listFilter_repeaters => 'Репитеры';

  @override
  String get listFilter_roomServers => 'Серверы комнат';

  @override
  String get listFilter_unreadOnly => 'Только непрочитанные';

  @override
  String get listFilter_newGroup => 'Новая группа';

  @override
  String get pathTrace_you => 'Вы';

  @override
  String get pathTrace_failed => 'Путь трассировки не выполнен.';

  @override
  String get pathTrace_notAvailable => 'Трассировка пути недоступна.';

  @override
  String get pathTrace_refreshTooltip => 'Обновить Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Одному или нескольким хмелям не указано местоположение!';

  @override
  String get pathTrace_clearTooltip => 'Очистить путь';

  @override
  String get losSelectStartEnd => 'Выберите начальный и конечный узлы для LOS.';

  @override
  String losRunFailed(String error) {
    return 'Проверка прямой видимости не удалась: $error';
  }

  @override
  String get losClearAllPoints => 'Очистить все точки';

  @override
  String get losRunToViewElevationProfile =>
      'Запустите LOS, чтобы просмотреть профиль высот.';

  @override
  String get losMenuTitle => 'ЛОС Меню';

  @override
  String get losMenuSubtitle =>
      'Коснитесь узлов или нажмите и удерживайте карту для выбора пользовательских точек.';

  @override
  String get losShowDisplayNodes => 'Показать узлы отображения';

  @override
  String get losCustomPoints => 'Пользовательские точки';

  @override
  String losCustomPointLabel(int index) {
    return 'Пользовательский $index';
  }

  @override
  String get losPointA => 'Точка А';

  @override
  String get losPointB => 'Точка Б';

  @override
  String losAntennaA(String value, String unit) {
    return 'Антенна А: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Антенна Б: $value $unit';
  }

  @override
  String get losRun => 'Запустить ЛОС';

  @override
  String get losNoElevationData => 'Нет данных о высоте';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, свободная зона видимости, минимальный зазор $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, заблокирован $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'ЛОС: проверяю...';

  @override
  String get losStatusNoData => 'ЛОС: нет данных';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total очищено, $blocked заблокировано, $unknown неизвестно.';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Данные о высоте недоступны для одного или нескольких образцов.';

  @override
  String get losErrorInvalidInput =>
      'Неверные данные о точках/высоте для расчета LOS.';

  @override
  String get losRenameCustomPoint => 'Переименовать пользовательскую точку';

  @override
  String get losPointName => 'Имя точки';

  @override
  String get losShowPanelTooltip => 'Показать панель LOS';

  @override
  String get losHidePanelTooltip => 'Скрыть панель LOS';

  @override
  String get losElevationAttribution =>
      'Данные о высоте: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Радиогоризонт';

  @override
  String get losLegendLosBeam => 'Линия прямой видимости';

  @override
  String get losLegendTerrain => 'Рельеф';

  @override
  String get losFrequencyLabel => 'Частота';

  @override
  String get losFrequencyInfoTooltip => 'Просмотреть детали расчёта';

  @override
  String get losFrequencyDialogTitle => 'Расчёт радиогоризонта';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Начиная с k=$baselineK на частоте $baselineFreq МГц, расчет корректирует коэффициент k для текущего диапазона $frequencyMHz МГц, который определяет изогнутую границу радиогоризонта.';
  }

  @override
  String get contacts_pathTrace => 'Трассировка пути';

  @override
  String get contacts_ping => 'Пинговать';

  @override
  String get contacts_repeaterPathTrace => 'Отследить путь к ретранслятору';

  @override
  String get contacts_repeaterPing => 'Пинговать повторитель';

  @override
  String get contacts_roomPathTrace => 'Трассировка пути к серверу комнаты';

  @override
  String get contacts_roomPing => 'Пинговать сервер комнаты';

  @override
  String get contacts_chatTraceRoute => 'Трассировка маршрута';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Показать маршрут к $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Буфер обмена пуст.';

  @override
  String get contacts_invalidAdvertFormat =>
      'Недействительные контактные данные';

  @override
  String get contacts_contactImported => 'Контакт был импортирован';

  @override
  String get contacts_contactImportFailed => 'Контакт не удалось импортировать';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name уже есть в ваших контактах.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Реклама Zero Hop';

  @override
  String get contacts_floodAdvert => 'Рекламный поток';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Копировать рекламу в буфер обмена';

  @override
  String get contacts_addContactFromClipboard =>
      'Добавить контакт из буфера обмена';

  @override
  String get contacts_ShareContact => 'Копировать контакт в буфер обмена';

  @override
  String get contacts_ShareContactZeroHop =>
      'Поделиться контактом по объявлению';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Отправлено сообщение по объявлению.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Не удалось отправить контакт.';

  @override
  String get contacts_contactAdvertCopied =>
      'Реклама скопирована в буфер обмена.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Копирование рекламы в буфер обмена не удалось.';

  @override
  String get contacts_addContact => 'Добавить контакт';

  @override
  String get contacts_scanQrCode => 'Сканировать QR контакта';

  @override
  String get contacts_scanQrCodeDesc =>
      'Отсканируйте QR-код контакта из приложения MeshCore';

  @override
  String get contacts_enterIdHash => 'Ввести контакт вручную';

  @override
  String get contacts_enterIdHashDesc =>
      'Вставьте анонс контакта или ссылку meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... или публичный ключ в hex';

  @override
  String get contacts_import => 'Импорт';

  @override
  String get contacts_scanContactInstructions =>
      'Отсканируйте QR-код контакта MeshCore';

  @override
  String get notification_activityTitle => 'Активность MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сообщений',
      many: 'сообщений',
      few: 'сообщения',
      one: 'сообщение',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'сообщений канала',
      many: 'сообщений канала',
      few: 'сообщения канала',
      one: 'сообщение канала',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'новых узлов',
      many: 'новых узлов',
      few: 'новых узла',
      one: 'новый узел',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Обнаружен новый $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Получено новое сообщение';

  @override
  String get settings_gpxExportRepeaters =>
      'Экспортировать рипитеры / сервер комнаты в GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Экспортирует ретрансляторы / сервер комнат с местоположением в файл GPX.';

  @override
  String get settings_gpxExportContacts => 'Экспортировать спутников в GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Экспортирует спутников с местоположением в файл GPX.';

  @override
  String get settings_gpxExportAll => 'Экспортировать все контакты в GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Экспортирует все контакты с местоположением в файл GPX.';

  @override
  String get settings_gpxExportSuccess => 'Успешно экспортирован файл GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Нет контактов для экспорта.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Не поддерживается на вашем устройстве/ОС';

  @override
  String get settings_gpxExportError => 'Произошла ошибка при экспорте.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Местоположения повторителей и серверов комнат';

  @override
  String get settings_gpxExportChat => 'Местоположения спутников';

  @override
  String get settings_gpxExportAllContacts => 'Все местоположения контактов';

  @override
  String get settings_gpxExportShareText =>
      'Данные карты экспортированы из MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax экспорт данных карты GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Ближайшие ретрансляторы';

  @override
  String get snrIndicator_lastSeen => 'Последний раз видели';

  @override
  String get contactsSettings_title => 'Настройки контактов';

  @override
  String get contactsSettings_autoAddTitle => 'Автоматическое обнаружение';

  @override
  String get contactsSettings_otherTitle =>
      'Другие настройки, связанные с контактами';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Автоматически добавлять пользователей';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Разрешить компаньону автоматически добавлять обнаруженных пользователей';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Автоматически добавлять ретрансляторы';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Разрешить спутнику автоматически добавлять обнаруженные ретрансляторы';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Автоматически добавлять серверы комнат';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Разрешить компаньону автоматически добавлять обнаруженные сервера комнат.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Автоматически добавлять датчики';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Разрешить компаньону автоматически добавлять обнаруженные датчики';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Перезаписать самое старое';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Когда список контактов заполнен, будет заменен самый старый контакт, который не находится в избранном.';

  @override
  String get discoveredContacts_Title => 'Обнаруженные контакты';

  @override
  String get discoveredContacts_noMatching => 'Нет совпадающих контактов';

  @override
  String get listFilter_searchHint => 'Поиск...';

  @override
  String get discoveredContacts_searchHint => 'Найденные контакты поиска';

  @override
  String get discoveredContacts_contactAdded => 'Контакт добавлен';

  @override
  String get discoveredContacts_addContact => 'Добавить контакт';

  @override
  String get discoveredContacts_copyContact =>
      'Копировать контакт в буфер обмена';

  @override
  String get discoveredContacts_deleteContact => 'Удалить контакт';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Удалить Все Обнаруженные Контакты';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Вы уверены, что хотите удалить все обнаруженные контакты?';

  @override
  String get chat_sendCooldown =>
      'Пожалуйста, подождите немного, прежде чем отправлять сообщение снова.';

  @override
  String get chat_notConnected =>
      'Нет подключения к радио. Сообщение не отправлено.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Перейти к самому старому непрочитанному сообщению';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'При открытии чата с непрочитанными сообщениями, прокрутите страницу, чтобы увидеть первое непрочитанное сообщение, а не последнее.';

  @override
  String get appSettings_languageHu => 'Венгерский';

  @override
  String get appSettings_languageJa => 'Японский';

  @override
  String get appSettings_languageKo => 'Корейский';

  @override
  String get radioStats_screenTitle => 'Статистика радиовещания';

  @override
  String get radioStats_notConnected =>
      'Подключитесь к устройству, чтобы просмотреть статистику радио.';

  @override
  String get radioStats_firmwareTooOld =>
      'Для работы радиостатистики требуется установленная версия прошивки v8 или более новая.';

  @override
  String get radioStats_waiting => 'Ожидаем данных…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Уровень шума: $noiseDbm дБм';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Последнее значение RSSI: $rssiDbm дБм';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Последнее значение SNR: $snr дБ';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Время эфира на телеканале TX (общее): $seconds секунд';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Общее время использования RX (в секундах): $seconds с';
  }

  @override
  String get radioStats_chartCaption =>
      'Уровень шума (дБм) на основе последних измерений.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Уровень шума: $noiseDbm дБм';
  }

  @override
  String get radioStats_stripWaiting => 'Получение данных о радио…';

  @override
  String get radioStats_settingsTile => 'Статистика радиовещания';

  @override
  String get radioStats_settingsSubtitle =>
      'Уровень шума, RSSI, SNR и время передачи';

  @override
  String get translation_title => 'Перевод';

  @override
  String get translation_enableTitle => 'Включить перевод';

  @override
  String get translation_enableSubtitle =>
      'Переводить входящие сообщения и позволять предварительный перевод перед отправкой.';

  @override
  String get translation_composerTitle => 'Переводить перед отправкой';

  @override
  String get translation_composerSubtitle =>
      'Управляет исходным состоянием значка перевода, предоставляемого редактором.';

  @override
  String get translation_targetLanguage => 'Целевой язык';

  @override
  String get translation_useAppLanguage => 'Используйте язык приложения';

  @override
  String get translation_downloadedModelLabel => 'Загруженная модель';

  @override
  String get translation_presetModelLabel =>
      'Предопределенная модель от Hugging Face';

  @override
  String get translation_manualUrlLabel => 'Ссылка на руководство';

  @override
  String get translation_downloadModel => 'Скачать модель';

  @override
  String get translation_downloading => 'Загрузка...';

  @override
  String get translation_working => 'Работа...';

  @override
  String get translation_stop => 'Прекратите';

  @override
  String get translation_mergingChunks =>
      'Объединение скачанных фрагментов в один финальный файл...';

  @override
  String get translation_downloadedModels => 'Загруженные модели';

  @override
  String get translation_deleteModel => 'Удалить модель';

  @override
  String get translation_modelDownloaded => 'Модель перевода загружена.';

  @override
  String get translation_downloadStopped => 'Процесс загрузки был прерван.';

  @override
  String translation_downloadFailed(String error) {
    return 'Не удалось скачать: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Сначала введите URL модели.';

  @override
  String get scanner_linuxPairingShowPin => 'Показать PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Скрыть PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN‑код сопряжения Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Введите PIN‑код для $deviceName (оставьте пустым, если нет).';
  }

  @override
  String get translation_messageTranslation => 'Перевод сообщения';

  @override
  String get translation_translateBeforeSending => 'Перевести перед отправкой';

  @override
  String get translation_composerEnabledHint =>
      'Сообщения будут переведены перед отправкой.';

  @override
  String get translation_composerDisabledHint =>
      'Отправляйте сообщения на языке, в котором они были изначально набраны.';

  @override
  String translation_translateTo(String language) {
    return 'Перевести на $language';
  }

  @override
  String get translation_translationOptions => 'Варианты перевода';

  @override
  String get translation_systemLanguage => 'Язык системы';

  @override
  String get routing_title => 'Маршрутизация';

  @override
  String routing_route(String route) {
    return 'Сохранённый маршрут: $route';
  }

  @override
  String get routing_noRoute =>
      'пока нет — следующее сообщение уйдёт рассылкой и найдёт его';

  @override
  String get routing_auto => 'Автоматически';

  @override
  String get routing_autoSubtitle =>
      'Использовать маршрут, сохранённый в радио. Рекомендуется.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder включён: сначала пробует изученные маршруты';

  @override
  String get routing_flood => 'Всегда рассылкой';

  @override
  String get routing_floodSubtitle => 'Каждое сообщение уходит во всю сеть';

  @override
  String get routing_custom => 'Свой маршрут';

  @override
  String get routing_customSubtitle => 'Выберите репитеры сами';

  @override
  String get routing_forget => 'Сбросить маршрут';

  @override
  String get routing_forgetDone =>
      'Маршрут сброшен. Следующее сообщение уйдёт рассылкой и найдёт новый.';

  @override
  String get routing_pathfinder => 'Что знает Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Репитеры, которые слышат вас и их, и изученные маршруты туда и обратно';

  @override
  String get path_direct => 'Напрямую — без репитеров';

  @override
  String get path_directSubtitle => 'Только если контакт слышит само это радио';

  @override
  String get chat_kindFlood => 'рассылка';

  @override
  String get chat_kindDirect => 'напрямую';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'хопов',
      many: 'хопов',
      few: 'хопа',
      one: 'хоп',
    );
    return 'маршрут ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'хопов',
      many: 'хопов',
      few: 'хопа',
      one: 'хоп',
    );
    return 'маршрут ($count $_temp0, предполагаемых: $guessed)';
  }

  @override
  String get chat_statusQueued => 'В очереди';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Ни один репитер вас не услышал. Попробуем снова, когда какой-нибудь окажется в зоне.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'Радио $name отправляет короткие коды репитеров (1 байт). Pathfinder не сможет изучить маршруты к этому контакту, пока его радио не перейдёт на 2-байтовые коды.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Отправка · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Повтор · $kind · попытка $attempt из $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Доставлено · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Доставлено с попытки $attempt · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Доставлено с опозданием · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Доставлено · $secs с';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'попыток',
      many: 'попыток',
      few: 'попыток',
      one: 'попытки',
    );
    return 'Не доставлено после $attempts $_temp0 · нажмите, чтобы повторить';
  }

  @override
  String get chat_statusFailedShort =>
      'Не доставлено · нажмите, чтобы повторить';

  @override
  String get chat_resendingByFlood => 'Повторная отправка рассылкой';

  @override
  String get pathfinderHelp_title => 'Что делает Pathfinder';

  @override
  String get pathfinderHelp_what =>
      'Ваше радио помнит один маршрут к каждому контакту, а если он не срабатывает, отправляет сообщение рассылкой во всю сеть. Pathfinder слушает всё, что слышит радио: анонсы репитеров, разговоры в каналах, чужие сообщения. Из этого он строит карту: какие репитеры слышат друг друга, какие слышат вас и какие — каждого из ваших контактов.';

  @override
  String get pathfinderHelp_how =>
      'Когда вы отправляете сообщение, Pathfinder сначала пробует свой лучший маршрут, затем следующий по качеству и только в крайнем случае отправляет рассылкой. Янтарный значок маршрута отмечает сообщение, отправленное по маршруту Pathfinder.';

  @override
  String get pathfinderHelp_learning =>
      'Ему нужно время. Новая карта пока ничего не знает, поэтому поначалу ваши сообщения отправляются точно так же, как раньше. Через несколько часов прослушивания на одном месте он начинает предлагать маршруты, а каждая доставка или неудача учит его чему-то новому. В первый день многого от него не ждите, а на каждом новом месте — снова меньше.';

  @override
  String get pathfinderHelp_guessed =>
      'Иногда он заполняет пробел предположением: связью, которую слышал только в обратном направлении. Тогда в строке состояния сообщения видно, сколько в маршруте предполагаемых хопов. Доставка их подтверждает, а неудача обходится в одну попытку, и ничего не запоминается.';

  @override
  String get pathfinderHelp_discover =>
      'Если Pathfinder не уверен, какие репитеры слышат вас здесь, он отправляет один короткий запрос Discover (не чаще одного раза в 10 минут и только после неудачной отправки). С радио, у которого есть GPS, он также запоминает на этом телефоне, какие репитеры слышали вас в каждой зоне размером около 500 м, но ваше точное местоположение не сохраняет.';

  @override
  String get pathfinderHelp_off =>
      'Если выключить Pathfinder, радио будет прокладывать маршруты точно так же, как раньше.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Больше не показывать';

  @override
  String get pathfinderHelp_ok => 'OK';

  @override
  String get settings_pathGraph => 'Pathfinder (экспериментально)';

  @override
  String get settings_pathGraphSubtitle =>
      'Изучает маршруты по всему, что слышит радио, и при отправке ЛС сначала пробует лучшие из них. Янтарный значок маршрута отмечает сообщение, отправленное по маршруту Pathfinder.';

  @override
  String get map_routeAndTrace => 'Маршрут и трассировка';

  @override
  String get map_pathfinderTrace => 'Трассировка туда и обратно';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Туда — по лучшему маршруту Pathfinder, обратно — по его лучшему обратному маршруту';

  @override
  String get map_routeBackMirrored =>
      'Обратный маршрут пока неизвестен — возврат тем же путём';

  @override
  String get map_traceHelpTitle => 'Кнопки трассировки пути';

  @override
  String get map_traceHelpCustom => 'Введите или выберите репитеры сами.';

  @override
  String get map_traceHelpRun =>
      'Отправляет трассировку в одну сторону через выбранные репитеры.';

  @override
  String get map_traceHelpThereAndBack => 'Туда и обратно';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Отправляет трассировку туда, а затем обратно через те же репитеры в обратном порядке.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder выбирает лучший маршрут через два последних выбранных репитера и лучший маршрут обратно к вам. Результат показывает Pathfinder, какие связи действительно работают. Нужно выбрать два репитера.';

  @override
  String get map_traceHelpRemoveLast => 'Убирает последний репитер из пути.';

  @override
  String get map_traceHelpCancel =>
      'Прекращает построение трассировки. Показывается, пока не выбран ни один репитер.';

  @override
  String get chat_resendingByRoute =>
      'Повторная отправка по заданному маршруту';

  @override
  String get room_mute => 'Отключить уведомления комнаты';

  @override
  String get room_unmute => 'Включить уведомления комнаты';

  @override
  String get room_roleAdmin => 'админ';

  @override
  String get room_roleMember => 'участник';

  @override
  String get room_roleReadOnly => 'только чтение';

  @override
  String room_clockOff(int minutes) {
    return 'Часы комнаты расходятся примерно на $minutes мин — время сообщений может быть неверным';
  }

  @override
  String get room_fixClock => 'Исправить часы';

  @override
  String get room_clockSyncSent => 'Синхронизация часов отправлена комнате';

  @override
  String get room_readOnlyNotice =>
      'Только чтение: комната не приняла ваш пароль, ваши сообщения не дойдут до других участников.';

  @override
  String get room_postAnnouncement => 'Опубликовать объявление';

  @override
  String get room_postAnnouncementSubtitle =>
      'Отправить сообщение от имени комнаты всем участникам';

  @override
  String get room_announcementSent => 'Объявление опубликовано';

  @override
  String get room_announcementFailed => 'Не удалось опубликовать объявление';

  @override
  String get room_users => 'Пользователи комнаты';

  @override
  String get room_usersSubtitle => 'Просмотр админов и назначение ролей';

  @override
  String get room_usersAdminsNote =>
      'Комната показывает только админов. Участники с паролем комнаты не отображаются.';

  @override
  String get room_usersLoadFailed => 'Не удалось загрузить список админов';

  @override
  String get room_setUserRole => 'Назначить роль';

  @override
  String get room_removeAccess => 'Убрать доступ';

  @override
  String get room_removeOnlyUnknown =>
      'Этого пользователя нет в контактах — его можно только удалить, но не изменить.';

  @override
  String get room_roleUpdated => 'Роль обновлена';

  @override
  String get room_roleUpdateFailed => 'Не удалось изменить роль';

  @override
  String get room_postsStored => 'Сохранённые сообщения';

  @override
  String get room_postsDelivered => 'Доставленные сообщения';

  @override
  String get room_reloadPosts => 'Перезагрузить последние сообщения';

  @override
  String get room_reloadPostsExplain =>
      'Просит комнату снова отправить последние сообщения (хранится до 32). Потребуется пароль комнаты. Уже полученные сообщения сохранятся.';

  @override
  String get room_reloadFailed => 'Не удалось сбросить комнату на радио';

  @override
  String get companionCli_title => 'Командная строка';

  @override
  String get companionCli_settingsSubtitle =>
      'Текстовые команды для этого радио';

  @override
  String get companionCli_rebooting => 'Перезапуск радио…';

  @override
  String get companionCli_cancelled => 'Отменено';

  @override
  String get companionCli_poweringOff => 'Выключение радио…';

  @override
  String get companionCli_noReply => 'Радио не отвечает. Попробуйте снова.';

  @override
  String get companionCli_powerOffTitle => 'Выключить радио?';

  @override
  String get companionCli_powerOffBody =>
      'Оно останется выключенным, пока вы не нажмёте его кнопку или не подключите питание.';

  @override
  String get companionCli_powerOff => 'Выключить';

  @override
  String get companionCli_quickBoard => 'Плата';

  @override
  String get companionCli_quickWifiStatus => 'Статус Wi‑Fi';

  @override
  String get companionCli_quickWifiAddress => 'Адрес Wi‑Fi';

  @override
  String get companionCli_helpBoard =>
      'Показывает производителя и модель платы.';

  @override
  String get companionCli_helpReboot => 'Перезапускает радио.';

  @override
  String get companionCli_helpPowerOff => 'Выключает радио.';

  @override
  String get companionCli_helpSetPin =>
      'Задаёт PIN для сопряжения Bluetooth. Применяется после перезапуска.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Задаёт число часов, добавляемых к UTC, для часов на экране самого радио (от -12 до +14).';

  @override
  String get companionCli_helpSetTx =>
      'Задаёт мощность передачи в дБм. Применяется сразу.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Задаёт порог помех в дБ. 0 отключает обнаружение помех.';

  @override
  String get companionCli_helpSetCad =>
      'Слушает другие радио перед отправкой (обнаружение активности в канале).';

  @override
  String get companionCli_helpSetRxGain =>
      'Повышенное усиление приёма на радио SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Байт на репитер в маршруте: 0 = 1 байт, 1 = 2 байта, 2 = 3 байта.';

  @override
  String get companionCli_helpWifiStatus =>
      'Показывает, подключено ли радио к сети Wi‑Fi.';

  @override
  String get companionCli_helpWifiIp => 'Показывает адрес радио в сети Wi‑Fi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Задаёт имя сети Wi‑Fi. Применяется после перезапуска.';

  @override
  String get companionCli_helpWifiPwd =>
      'Задаёт пароль Wi‑Fi. Применяется после перезапуска.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Включает (1) или выключает (0) Wi‑Fi. Применяется после перезапуска.';

  @override
  String get companionCli_helpWifiClear =>
      'Забывает сеть Wi‑Fi. Применяется после перезапуска.';

  @override
  String get companionCli_remoteNoReply =>
      'Нет ответа. Другому радио нужна прошивка 1.18 или новее, и оно должно разрешать вам пользоваться его командной строкой.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Отправлено. Радио не отвечает на перезапуск или выключение.';

  @override
  String companionCli_blocked(String name, String command) {
    return 'Попытка от $name использовать командную строку вашего радио: «$command». Не разрешено.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Попытка использовать командную строку вашего радио: «$command». Не разрешено.';
  }

  @override
  String get contact_remoteCli => 'Разрешить удалённую командную строку';

  @override
  String get contact_remoteCliSubtitle =>
      'Этот контакт сможет выполнять команды на вашем радио';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Дать $name управлять вашим радио?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name сможет менять настройки вашего радио, читать ваш пароль Wi‑Fi, переименовывать радио, перезапускать и выключать его. Разрешайте только тому, кому полностью доверяете.';
  }

  @override
  String get contact_remoteCliAllow => 'Разрешить';

  @override
  String get connection_secondApp =>
      'К этому радио подключено другое приложение. Сообщения и настройки могут перепутаться. Закройте другое приложение.';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => 'Сеть, пароль и подключение';

  @override
  String get wifi_use => 'Использовать Wi‑Fi';

  @override
  String get wifi_networkName => 'Имя сети';

  @override
  String get wifi_password => 'Пароль';

  @override
  String get wifi_passwordUnchanged => 'Без изменений';

  @override
  String get wifi_showPassword => 'Показать пароль';

  @override
  String get wifi_nameMissing => 'Введите имя сети';

  @override
  String get wifi_nameTooLong => 'Имя сети слишком длинное (не более 32 байт)';

  @override
  String get wifi_passwordTooLong =>
      'Пароль слишком длинный (не более 63 байт)';

  @override
  String get wifi_savedRestart =>
      'Сохранено. Изменения Wi‑Fi применятся после перезапуска радио.';

  @override
  String get wifi_forget => 'Забыть сеть';

  @override
  String get wifi_forgetConfirm =>
      'Забыть эту сеть Wi‑Fi? После перезапуска радио перестанет использовать Wi‑Fi.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Радио не приняло это: $reply';
  }

  @override
  String get wifi_noReply => 'Радио не отвечает. Попробуйте снова.';

  @override
  String get wifi_restartTitle => 'Перезапустить радио?';

  @override
  String get wifi_later => 'Позже';

  @override
  String get wifi_loadFailed =>
      'Не удалось прочитать настройки Wi‑Fi из радио.';

  @override
  String wifi_connectedTo(String address) {
    return 'Подключено · $address';
  }

  @override
  String get wifi_notConnected => 'Нет подключения к Wi‑Fi';

  @override
  String wifi_portNote(int port) {
    return 'Приложения в той же сети могут подключиться через порт $port';
  }

  @override
  String get wifi_connectOverWifi => 'Подключиться по Wi‑Fi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax отключится от этого радио и откроет экран TCP с уже заполненными адресом $address и портом $port. Там нажмите «Коннект».';
  }

  @override
  String get wifi_noteRestart =>
      'Изменения применятся после перезапуска радио.';

  @override
  String get wifi_noteSecurity =>
      'Любой в вашей сети Wi‑Fi может подключиться к радио через порт 5000. Пароля для этого нет.';

  @override
  String get wifi_noteBattery =>
      'Wi‑Fi не даёт радио засыпать, поэтому батарея садится быстрее.';

  @override
  String get wifi_noteWrongPassword =>
      'Если пароль неверный, радио продолжает пытаться каждые несколько секунд. Bluetooth продолжает работать.';

  @override
  String get room_selfDemoteWarning =>
      'Вы меняете собственный доступ. Если вы лишитесь роли админа, вернуть её сможет только консоль комнаты.';

  @override
  String get scanner_offlineMaps => 'Офлайн-карты';

  @override
  String get appSettings_offlineMaps => 'Офлайн-карты';

  @override
  String get appSettings_offlineMapsNone => 'Ничего не скачано';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count регионов',
      many: '$count регионов',
      few: '$count региона',
      one: '$count регион',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count районов морских карт',
      many: '$count районов морских карт',
      few: '$count района морских карт',
      one: '$count район морских карт',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Доступно $count обновлений',
      many: 'Доступно $count обновлений',
      few: 'Доступно $count обновления',
      one: 'Доступно $count обновление',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Скачивать карты только по Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Загрузка карт ждёт подключения к Wi‑Fi';

  @override
  String get offlineMaps_title => 'Офлайн-карты';

  @override
  String get offlineMaps_tabMaps => 'Карты';

  @override
  String get offlineMaps_tabCharts => 'Морские карты';

  @override
  String get offlineMaps_chartsNotice => 'Не для навигации · Почему?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Рекомендуемые · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Районы карт по побережьям';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count районов',
      many: '$count районов',
      few: '$count района',
      one: '$count район',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Скачано: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Выбрано: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Выбрать все';

  @override
  String get offlineMaps_clearSelection => 'Сбросить';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Также в: $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Пока недоступно';

  @override
  String get offlineMaps_chartsHint =>
      'Карты NOAA выбираются по побережьям на вкладке «Морские карты».';

  @override
  String offlineMaps_chartsName(String area) {
    return '$area — карты NOAA';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count районов',
      many: '$count районов',
      few: '$count района',
      one: '$count район',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Скачанные';

  @override
  String get offlineMaps_refresh => 'Проверить новые карты';

  @override
  String get offlineMaps_loading => 'Загрузка списка карт…';

  @override
  String get offlineMaps_serverError => 'Сервер карт недоступен';

  @override
  String get offlineMaps_unavailable => 'Карт пока нет';

  @override
  String get offlineMaps_unavailableHint => 'Проверьте позже.';

  @override
  String get offlineMaps_chartsUnavailable => 'Карт NOAA пока нет';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Показан список от $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Обновите MeshTrax, чтобы получить новейшие карты.';

  @override
  String get offlineMaps_world => 'Мир';

  @override
  String get offlineMaps_suggested => 'Рекомендуемые';

  @override
  String get offlineMaps_regions => 'Регионы';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Регионы: $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return 'Внутри: $count';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return 'Офлайн-карты на этом устройстве: $size';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Обновления ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Обновить все ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Скачивание';

  @override
  String get offlineMaps_update => 'Обновить';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Скачано $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Есть обновление';

  @override
  String get offlineMaps_otherFiles => 'Другие файлы карт';

  @override
  String get offlineMaps_emptyTitle => 'Офлайн-карт пока нет';

  @override
  String get offlineMaps_emptyBody =>
      'Скачайте регион, чтобы пользоваться картой без подключения.';

  @override
  String get offlineMaps_findMaps => 'Найти карты';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Удалить $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Освободится $size. Позже можно скачать снова.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return 'Удалено: $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done из $total';
  }

  @override
  String get offlineMaps_kindMap => 'Карта';

  @override
  String get offlineMaps_kindMapDetail => 'OpenStreetMap: улицы, тропы, места';

  @override
  String get offlineMaps_kindContours => 'Горизонтали';

  @override
  String get offlineMaps_kindContoursDetail => 'Линии высот';

  @override
  String get offlineMaps_kindUsgs => 'Топокарта USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Тропы, ручьи, заповедники';

  @override
  String get offlineMaps_kindTerrain => 'Отмывка рельефа';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Холмы и горы с тенями под картой';

  @override
  String get offlineMaps_kindCharts => 'Морские карты NOAA';

  @override
  String get offlineMaps_usOnly => 'Только США';

  @override
  String offlineMaps_download(String size) {
    return 'Скачать $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Скачать';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Большая загрузка ($size). Используйте Wi‑Fi и держите устройство на зарядке.';
  }

  @override
  String get offlineMaps_waiting => 'Ожидание…';

  @override
  String get offlineMaps_checking => 'Проверка загрузки…';

  @override
  String get offlineMaps_retrying => 'Повтор…';

  @override
  String offlineMaps_failed(String error) {
    return 'Ошибка загрузки: $error';
  }

  @override
  String get offlineMaps_pause => 'Пауза';

  @override
  String get offlineMaps_resume => 'Продолжить';

  @override
  String get offlineMaps_deleteRegion => 'Удалить регион';

  @override
  String get offlineMaps_notInCatalogue => 'Недоступно для этого региона';

  @override
  String get offlineMaps_notificationRunning => 'Скачивание карты';

  @override
  String get offlineMaps_notificationPaused => 'Загрузка карты приостановлена';

  @override
  String get offlineMaps_notificationFailed => 'Не удалось скачать карту';

  @override
  String get offlineMaps_clearTileCache => 'Очистить кэш онлайн-карт';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Удалить фрагменты онлайн-карт, сохранённые при просмотре? Скачанные карты останутся.';

  @override
  String get offlineMaps_tileCacheCleared => 'Кэш онлайн-карт очищен';

  @override
  String get map_notForNavigation => 'Не для навигации';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax рисует эти карты по данным NOAA, чтобы вы видели воду вокруг ваших радио и могли планировать. Это не официальные карты. Не прокладывайте по ним курс.';

  @override
  String get map_chartsNoticeWhy => 'Почему:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Они устаревают. NOAA постоянно исправляет свои карты, а скачанная карта не меняется, пока вы не обновите её в разделе «Офлайн-карты».';

  @override
  String get map_chartsNoticeLeftOut =>
      'На них показано не всё. Многие условные знаки, секторы огней и примечания не рисуются, а часть подписей видна только при увеличении.';

  @override
  String get map_chartsNoticePositions =>
      'Координаты могут быть неточными или устаревшими. GPS может ошибаться на 10 м (30 футов) и больше, а нода находится там, откуда сообщила о себе в последний раз.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax — не сертифицированный картплоттер.';

  @override
  String get map_chartsNoticeUse =>
      'Для навигации используйте официальные актуальные карты NOAA (бумажные или ENC от NOAA в сертифицированном картплоттере) с последними Извещениями мореплавателям.';

  @override
  String get map_sourceOnline => 'Онлайн';

  @override
  String get map_sourceOffline => 'Офлайн';

  @override
  String get map_downloadForDetail =>
      'Скачайте регион, чтобы видеть подробности';

  @override
  String get map_zoomInForOfflineMap => 'Увеличьте, чтобы увидеть офлайн-карту';

  @override
  String get map_noCharts => 'Здесь нет морских карт';

  @override
  String get map_myLocation => 'Моё местоположение';

  @override
  String get map_zoomIn => 'Увеличить';

  @override
  String get map_zoomOut => 'Уменьшить';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS вкл.';

  @override
  String get gps_off => 'GPS выкл.';

  @override
  String get gps_onHint => 'Радио обновляет своё местоположение по GPS.';

  @override
  String get gps_offHint =>
      'Выключенный GPS экономит батарею радио. После включения поиск местоположения может занять несколько минут.';

  @override
  String get gps_asking => 'Запрос к радио...';

  @override
  String get gps_noPosition =>
      'Местоположения пока нет. На открытом месте первое определение может занять несколько минут.';

  @override
  String get gps_position => 'Координаты';

  @override
  String get gps_altitude => 'Высота';

  @override
  String gps_readAgo(String ago) {
    return 'Прочитано с радио $ago назад';
  }

  @override
  String get gps_turnOnTitle => 'Включить GPS?';

  @override
  String get gps_turnOnBody =>
      'GPS радио выключен. После включения поиск местоположения может занять несколько минут.';

  @override
  String get gps_turnOn => 'Включить';

  @override
  String get gps_notNow => 'Не сейчас';

  @override
  String get map_zoomInForCharts => 'Увеличьте, чтобы увидеть морские карты';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Скачать $region · $size';
  }

  @override
  String get mapLayers_title => 'Слои карты';

  @override
  String get mapLayers_mapType => 'Тип карты';

  @override
  String get mapLayers_standard => 'Стандартная';

  @override
  String get mapLayers_usgs => 'Топокарта USGS';

  @override
  String get mapLayers_charts => 'Морские карты';

  @override
  String get mapLayers_notDownloaded => 'Не скачано';

  @override
  String get mapLayers_offlineOnly => 'Только офлайн';

  @override
  String get mapLayers_details => 'Детали карты';

  @override
  String get mapLayers_contours => 'Горизонтали';

  @override
  String get mapLayers_hillShading => 'Отмывка рельефа';

  @override
  String get mapLayers_dark => 'Тёмная карта';

  @override
  String get mapLayers_downloadedAreas => 'Скачанные области';

  @override
  String get mapLayers_nodes => 'Ноды';

  @override
  String get mapLayers_pins => 'Метки';

  @override
  String get mapLayers_guessed => 'Предполагаемые';

  @override
  String get mapLayers_moreFilters => 'Другие фильтры';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Последняя активность, префикс ключа, пересечения';

  @override
  String get map_legend => 'Легенда';

  @override
  String get scanner_map => 'Карта';

  @override
  String get structured_openMap => 'Открыть карту';

  @override
  String get structured_addToCalendar => 'Добавить в календарь';

  @override
  String get structured_details => 'Подробности';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Событие';

  @override
  String get structured_notice => 'Объявление';

  @override
  String get structured_allDay => 'Весь день';

  @override
  String get structured_calendarFailed => 'Не удалось открыть календарь';

  @override
  String get structured_today => 'Сегодня';

  @override
  String get structured_tomorrow => 'Завтра';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Через $count дней',
      many: 'Через $count дней',
      few: 'Через $count дня',
      one: 'Через $count день',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Прошло';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'День $day из $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дней',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Дата окончания';

  @override
  String get dialog_eventSameDay => 'Тот же день';

  @override
  String get structured_map => 'Карта';

  @override
  String get structured_navigate => 'Навигация';

  @override
  String get structured_channel => 'Канал';

  @override
  String get structured_contact => 'Контакт';

  @override
  String get structured_room => 'Комната';

  @override
  String get structured_repeater => 'Репитер';

  @override
  String get structured_sensor => 'Сенсор';

  @override
  String get structured_joinChannel => 'Присоединиться к каналу';

  @override
  String get structured_addContact => 'Добавить контакт';

  @override
  String get structured_addRoom => 'Добавить комнату';

  @override
  String get structured_addRepeater => 'Добавить репитер';

  @override
  String get structured_addSensor => 'Добавить сенсор';

  @override
  String get structured_open => 'Открыть';

  @override
  String get structured_added => 'Добавлено';

  @override
  String get tray_add => 'Добавить';

  @override
  String get tray_myLocation => 'Моё местоположение';

  @override
  String get tray_pointOnMap => 'Точка на карте';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Событие';

  @override
  String get tray_notice => 'Объявление';

  @override
  String get tray_noRadioPosition =>
      'У вашего радио пока нет местоположения. Выберите его на карте.';

  @override
  String get dialog_insert => 'Вставить';

  @override
  String get dialog_eventTitle => 'Название';

  @override
  String get dialog_eventDate => 'Дата';

  @override
  String get dialog_eventStart => 'Начало';

  @override
  String get dialog_eventEnd => 'Конец';

  @override
  String get dialog_eventNoEnd => 'Без времени окончания';

  @override
  String get dialog_eventPlace => 'Место (необязательно)';

  @override
  String get dialog_pickOnMap => 'Выбрать на карте';

  @override
  String get dialog_sosTitle => 'Отправить SOS';

  @override
  String get dialog_sosText => 'Что случилось?';

  @override
  String get dialog_noticeTitle => 'Объявление';

  @override
  String get dialog_noticeText => 'Что нужно знать всем?';

  @override
  String get dialog_labelTitle => 'Точка на карте';

  @override
  String get dialog_note => 'Заметка (необязательно)';

  @override
  String get paste_convertLocation =>
      'Похоже на ссылку на карту. Преобразовать в местоположение?';

  @override
  String get paste_convertEvent =>
      'Похоже на событие из календаря. Преобразовать в событие?';

  @override
  String get paste_convert => 'Преобразовать';

  @override
  String get paste_resolving => 'Обработка ссылки…';

  @override
  String get paste_resolveFailed => 'Не удалось обработать ссылку';

  @override
  String get pinned_dismiss => 'Скрыть';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Присоединиться к каналу $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Вы уже в канале $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Вы присоединились к $name';
  }

  @override
  String get map_pickPositionHint => 'Нажмите на карту, чтобы выбрать точку';

  @override
  String get map_legendMesh => 'Сеть';

  @override
  String get chartLegend_title => 'Условные знаки карт';

  @override
  String get chartLegend_sectionBuoys => 'Буи и знаки';

  @override
  String get chartLegend_sectionLights => 'Огни';

  @override
  String get chartLegend_sectionHazards => 'Опасности';

  @override
  String get chartLegend_sectionTides => 'Приливы и течения';

  @override
  String get chartLegend_sectionDepths => 'Глубины и грунт';

  @override
  String get chartLegend_sectionAreas => 'Районы, полосы и линии';

  @override
  String get chartLegend_sectionLandmarks => 'Ориентиры';

  @override
  String get chartLegend_sectionAbbreviations => 'Сокращения';

  @override
  String get chartLegend_chartNo1 => 'Все условные знаки: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Зелёный цилиндрический буй';

  @override
  String get chartLegend_portBuoyHint => 'Оставляйте слева при входе с моря';

  @override
  String get chartLegend_starboardBuoy => 'Красный конический буй';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Оставляйте справа при входе: красный — справа, когда возвращаетесь с моря';

  @override
  String get chartLegend_junctionBuoy => 'Буй с горизонтальными полосами';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Разделение фарватера: ориентируйтесь по цвету верхней полосы';

  @override
  String get chartLegend_safeWaterBuoy => 'Красные и белые вертикальные полосы';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Вокруг безопасные воды; часто у входа в фарватер';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Чёрные и красные полосы';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Небольшая опасность, вокруг безопасные воды: держитесь в стороне';

  @override
  String get chartLegend_specialBuoy => 'Жёлтый буй';

  @override
  String get chartLegend_specialBuoyHint =>
      'Специальный знак, не для навигации: якорная стоянка, кабель, исследования';

  @override
  String get chartLegend_cardinalBuoy => 'Чёрный и жёлтый';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Кардинальный знак: проходите с той стороны, по которой он назван (в США редок)';

  @override
  String get chartLegend_mooringBuoy => 'Швартовная бочка';

  @override
  String get chartLegend_portBeacon => 'Зелёный квадратный знак';

  @override
  String get chartLegend_portBeaconHint =>
      'Как зелёный буй: оставляйте слева при входе';

  @override
  String get chartLegend_starboardBeacon => 'Красный треугольный знак';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Как красный буй: оставляйте справа при входе';

  @override
  String get chartLegend_otherBeacon => 'Ромбовидный знак';

  @override
  String get chartLegend_otherBeaconHint =>
      'Информация или предупреждение, а не сторона фарватера';

  @override
  String get chartLegend_beaconTower => 'Башня маяка или сооружение знака';

  @override
  String get chartLegend_topmark => 'Топовая фигура';

  @override
  String get chartLegend_topmarkHint =>
      'Фигура на верхушке знака уточняет его значение';

  @override
  String get chartLegend_light => 'Огонь';

  @override
  String get chartLegend_lightHint =>
      'Пурпурная вспышка обозначает огонь; подпись говорит, как он мигает';

  @override
  String get chartLegend_lightExample =>
      'Зелёный проблесковый, каждые 4 секунды';

  @override
  String get chartLegend_lightExampleHint =>
      'Подпись огня: характер, цвет, затем период';

  @override
  String get chartLegend_lightFixed => 'Постоянный';

  @override
  String get chartLegend_lightFixedHint => 'Горит не мигая';

  @override
  String get chartLegend_lightFlashing => 'Проблесковый';

  @override
  String get chartLegend_lightFlashingHint =>
      'Короткие проблески, темнота между ними дольше';

  @override
  String get chartLegend_lightGroup => 'Группо-проблесковый';

  @override
  String get chartLegend_lightGroupHint =>
      'Проблески группами, здесь по 2, затем темнота';

  @override
  String get chartLegend_lightComposite => 'Сложный группо-проблесковый';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 проблеска, затем 1: разделение фарватера';

  @override
  String get chartLegend_lightQuick => 'Частый проблесковый';

  @override
  String get chartLegend_lightQuickHint => 'Около одного проблеска в секунду';

  @override
  String get chartLegend_lightIsophase => 'Изофазный';

  @override
  String get chartLegend_lightIsophaseHint => 'Свет и темнота поровну';

  @override
  String get chartLegend_lightOcculting => 'Затмевающийся';

  @override
  String get chartLegend_lightOccultingHint => 'Свет дольше темноты';

  @override
  String get chartLegend_lightMorse => 'Азбука Морзе A';

  @override
  String get chartLegend_lightMorseHint => 'Короткий, длинный: безопасные воды';

  @override
  String get chartLegend_lightAlternating => 'Переменный';

  @override
  String get chartLegend_lightAlternatingHint => 'Меняет цвет';

  @override
  String get chartLegend_lightColours => 'Белый, красный, зелёный, жёлтый';

  @override
  String get chartLegend_lightPeriod => 'Период';

  @override
  String get chartLegend_lightPeriodHint => 'Секунды на полный цикл';

  @override
  String get chartLegend_rock => 'Подводный камень';

  @override
  String get chartLegend_rockHint =>
      'Всегда под водой, но может быть близко к поверхности';

  @override
  String get chartLegend_rockAwash => 'Камень на уровне воды';

  @override
  String get chartLegend_rockAwashHint => 'У самой поверхности в малую воду';

  @override
  String get chartLegend_rockCovers => 'Осыхающий камень';

  @override
  String get chartLegend_rockCoversHint => 'Виден в малую воду, скрыт в полную';

  @override
  String get chartLegend_wreckDangerous => 'Опасное затонувшее судно';

  @override
  String get chartLegend_wreckDangerousHint => 'Достаточно мелко, чтобы задеть';

  @override
  String get chartLegend_wreck => 'Затонувшее судно';

  @override
  String get chartLegend_wreckHint =>
      'Достаточно глубоко для надводных судов; не становитесь на якорь';

  @override
  String get chartLegend_wreckShowing => 'Затонувшее судно, видное над водой';

  @override
  String get chartLegend_wreckShowingHint =>
      'Часть корпуса выступает над водой';

  @override
  String get chartLegend_obstruction => 'Препятствие';

  @override
  String get chartLegend_obstructionHint =>
      'Что-то на дне; глубина над ним, если известна';

  @override
  String get chartLegend_foulGround => 'Засорённый грунт';

  @override
  String get chartLegend_foulGroundHint =>
      'Проходить можно, но не становитесь на якорь и не тралите';

  @override
  String get chartLegend_hazardArea => 'Граница опасного района';

  @override
  String get chartLegend_hazardAreaHint =>
      'Внутри камни, затонувшие суда или препятствия';

  @override
  String get chartLegend_pile => 'Свая или столб';

  @override
  String get chartLegend_floodStream => 'Приливное течение';

  @override
  String get chartLegend_floodStreamHint => 'Течение, пока вода прибывает';

  @override
  String get chartLegend_ebbStream => 'Отливное течение';

  @override
  String get chartLegend_ebbStreamHint => 'Течение, пока вода убывает';

  @override
  String get chartLegend_current => 'Постоянное течение';

  @override
  String get chartLegend_currentHint =>
      'Течёт в одну сторону независимо от прилива';

  @override
  String get chartLegend_rips => 'Сулои или водовороты';

  @override
  String get chartLegend_ripsHint => 'Бурная, закрученная вода';

  @override
  String get chartLegend_breakers => 'Буруны';

  @override
  String get chartLegend_breakersHint => 'Волны разбиваются на мелководье';

  @override
  String get chartLegend_sounding => 'Отметка глубины';

  @override
  String get chartLegend_soundingHint => 'Глубина при средней малой воде';

  @override
  String get chartLegend_depthContour => 'Изобата';

  @override
  String get chartLegend_depthContourHint => 'Подпись показывает глубину';

  @override
  String get chartLegend_drying => 'Осыхает в малую воду';

  @override
  String get chartLegend_dredged => 'Дноуглублённый канал';

  @override
  String get chartLegend_dredgedHint => 'Поддерживается указанная глубина';

  @override
  String get chartLegend_swept => 'Протраленный район';

  @override
  String get chartLegend_sweptHint =>
      'Проверено, что чисто до указанной глубины';

  @override
  String get chartLegend_unsurveyed => 'Не обследовано';

  @override
  String get chartLegend_unsurveyedHint => 'Глубины не измерены';

  @override
  String get chartLegend_weed => 'Ламинария или водоросли';

  @override
  String get chartLegend_restricted => 'Район с ограничениями';

  @override
  String get chartLegend_restrictedHint =>
      'Вход ограничен; засечки направлены внутрь';

  @override
  String get chartLegend_regulatedLimit => 'Граница регулируемого района';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Якорная стоянка, кабельный район, район стрельб и др.: см. подпись';

  @override
  String get chartLegend_greyLimit => 'Свалка грунта, район промысла или ферма';

  @override
  String get chartLegend_anchorage => 'Якорная стоянка';

  @override
  String get chartLegend_anchorBerth => 'Якорное место';

  @override
  String get chartLegend_noAnchoring => 'Якорная стоянка запрещена';

  @override
  String get chartLegend_caution => 'Район предостережения';

  @override
  String get chartLegend_cautionHint => 'Будьте здесь особенно внимательны';

  @override
  String get chartLegend_trafficLane => 'Полоса движения';

  @override
  String get chartLegend_trafficLaneHint =>
      'Крупные суда, движение в одну сторону: пересекайте под прямым углом';

  @override
  String get chartLegend_separationZone => 'Зона разделения';

  @override
  String get chartLegend_separationZoneHint =>
      'Между полосами движения: не заходите';

  @override
  String get chartLegend_precautionary => 'Район, где нужна осторожность';

  @override
  String get chartLegend_precautionaryHint =>
      'Здесь сходятся суда: будьте осторожны';

  @override
  String get chartLegend_fairway => 'Фарватер';

  @override
  String get chartLegend_fairwayHint => 'Основной судовой ход';

  @override
  String get chartLegend_track => 'Рекомендованный путь';

  @override
  String get chartLegend_ferry => 'Паромная линия';

  @override
  String get chartLegend_leadingLine => 'Створная линия';

  @override
  String get chartLegend_leadingLineHint =>
      'Совместите два створных знака, чтобы держаться фарватера';

  @override
  String get chartLegend_cable => 'Подводный кабель';

  @override
  String get chartLegend_cableHint => 'Не становитесь на якорь';

  @override
  String get chartLegend_pipeline => 'Подводный трубопровод';

  @override
  String get chartLegend_pipelineHint => 'Не становитесь на якорь';

  @override
  String get chartLegend_overhead => 'Воздушный кабель';

  @override
  String get chartLegend_overheadHint =>
      'Высота прохода под ним подписана как VC';

  @override
  String get chartLegend_tower => 'Башня';

  @override
  String get chartLegend_windTurbine => 'Ветрогенератор';

  @override
  String get chartLegend_chimney => 'Дымовая труба';

  @override
  String get chartLegend_mast => 'Мачта или антенна';

  @override
  String get chartLegend_church => 'Церковь или шпиль';

  @override
  String get chartLegend_flagstaff => 'Флагшток';

  @override
  String get chartLegend_dome => 'Купол';

  @override
  String get chartLegend_landmark => 'Другой ориентир';

  @override
  String get chartLegend_abbrAnch => 'Якорная стоянка';

  @override
  String get chartLegend_abbrWk => 'Затонувшее судно';

  @override
  String get chartLegend_abbrBr => 'Буруны';

  @override
  String get chartLegend_abbrWd => 'Водоросли';

  @override
  String get chartLegend_abbrVar => 'Магнитное склонение';

  @override
  String get chartLegend_abbrVc => 'Высота прохода под мостом или кабелем';

  @override
  String get chartLegend_abbrTr => 'Башня';

  @override
  String get chartLegend_abbrCh => 'Церковь';

  @override
  String get chartLegend_abbrChy => 'Дымовая труба';

  @override
  String get chartLegend_abbrFs => 'Флагшток';

  @override
  String get chartLegend_abbrTk => 'Резервуар';

  @override
  String get chartLegend_abbrRBn => 'Радиомаяк';

  @override
  String get chartLegend_abbrCg => 'Станция береговой охраны';

  @override
  String get chartLegend_abbrRacon =>
      'Радиолокационный маяк-ответчик: виден на радаре';

  @override
  String get chartLegend_abbrFog =>
      'Туманный сигнал: ревун, колокол, гонг, свисток или сирена';

  @override
  String get chartLegend_abbrVAis => 'Виртуальный знак: виден только в AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'от $from до $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Глубже $depth';
  }

  @override
  String get parkLegend_title => 'Обозначения парков и троп';

  @override
  String get parkLegend_campsite => 'Кемпинг';

  @override
  String get parkLegend_picnicSite => 'Место для пикника';

  @override
  String get parkLegend_shelter => 'Укрытие';

  @override
  String get parkLegend_toilets => 'Туалет';

  @override
  String get parkLegend_drinkingWater => 'Питьевая вода';

  @override
  String get parkLegend_parking => 'Парковка';

  @override
  String get parkLegend_viewpoint => 'Смотровая площадка';

  @override
  String get parkLegend_attraction => 'Достопримечательность';

  @override
  String get parkLegend_gate => 'Ворота';

  @override
  String get parkLegend_telephone => 'Телефон';

  @override
  String get parkLegend_information => 'Информационный стенд';

  @override
  String get parkLegend_guidepost => 'Указатель';

  @override
  String get dialog_noticeExpires => 'Срок действия';

  @override
  String get dialog_noticeNoExpiry => 'Бессрочно';

  @override
  String get dialog_noticeExpiryRequired =>
      'Выберите дату (в комнате обязательно)';

  @override
  String get dialog_noticeExpiryTime => 'Время';

  @override
  String get dialog_noticeEndOfDay => 'Конец дня';

  @override
  String structured_until(String when) {
    return 'До $when';
  }

  @override
  String get structured_expired => 'Срок истёк';

  @override
  String get structured_announcement => 'Оповещение';

  @override
  String structured_locationOf(String name) {
    return 'Местоположение: $name';
  }

  @override
  String get reaction_searchHint => 'Поиск эмодзи';

  @override
  String get reaction_noResults => 'Эмодзи не найдены';

  @override
  String get share_qrAndLink => 'Поделиться QR-кодом и ссылкой';

  @override
  String get share_roomTitle => 'Поделиться комнатой';

  @override
  String get share_contactTitle => 'Поделиться контактом';

  @override
  String get share_roomInstructions =>
      'Отсканируйте QR-код, чтобы добавить эту комнату. Для входа понадобится её пароль.';

  @override
  String get share_contactInstructions =>
      'Отсканируйте QR-код, чтобы добавить этот контакт.';

  @override
  String get clearChat_body =>
      'Удалить сообщения этого чата с этого устройства. Новые сообщения продолжат приходить сюда.';

  @override
  String get clearChat_olderThanDay => 'Старше 1 дня';

  @override
  String get clearChat_olderThanWeek => 'Старше 1 недели';

  @override
  String get clearChat_olderThanMonth => 'Старше 1 месяца';

  @override
  String get clearChat_everything => 'Все сообщения';

  @override
  String get chats_markAllRead => 'Отметить все как прочитанные';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Отметить $count чатов как прочитанные?',
      many: 'Отметить $count чатов как прочитанные?',
      few: 'Отметить $count чата как прочитанные?',
      one: 'Отметить $count чат как прочитанный?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Отметить';

  @override
  String get chats_nothingUnread => 'Нет непрочитанных сообщений';

  @override
  String get chats_draft => 'Черновик';

  @override
  String get contact_teleBlockedTitle => 'Заблокировано вашим радио';

  @override
  String contact_teleBlockedBody(String name) {
    return 'Настройки конфиденциальности вашего радио ни с кем этим не делятся, поэтому $name это не получит. Изменить их, чтобы это получали контакты, которым вы разрешите?';
  }

  @override
  String get contact_teleNotNow => 'Не сейчас';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'Ваше радио ни с кем этим не делится ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'Ваше радио делится этим со всеми ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Может получить ваше местоположение';

  @override
  String get pathfinder_meshTitle => 'Другая сеть?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '$unknown из $heard репитеров, услышанных после подключения, новые для карты Pathfinder «$graph». Начать новую карту для этого района? Старая сохранится, и на неё можно вернуться на экране Pathfinder.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'Большинство репитеров, услышанных после подключения, есть на карте Pathfinder «$other», а не «$graph». Переключиться на неё?';
  }

  @override
  String get pathfinder_meshNew => 'Новая карта';

  @override
  String get pathfinder_meshSwitch => 'Переключить';

  @override
  String get pathfinder_meshKeep => 'Оставить эту';

  @override
  String get pathfinder_graphNameTitle => 'Название новой карты';

  @override
  String get pathfinder_graphNameHint => 'Например, Вашингтон';

  @override
  String get pathfinder_graphCreate => 'Создать';

  @override
  String get locationSharing_title => 'Кто видит моё местоположение';

  @override
  String get locationSharing_someone =>
      'Кто-то может видеть ваше местоположение';

  @override
  String get locationSharing_nobody => 'Никто не видит ваше местоположение';

  @override
  String get locationSharing_noPosition =>
      'У вашего радио ещё нет местоположения, поэтому его никто не видит';

  @override
  String get locationSharing_everyone =>
      'Любой, кто слышит ваше радио, видит ваше местоположение';

  @override
  String get locationSharing_allContacts =>
      'Все ваши контакты видят ваше местоположение';

  @override
  String get locationSharing_someContacts =>
      'Контакты, которым вы разрешили, видят ваше местоположение';

  @override
  String get locationSharing_adverts => 'Местоположение в анонсах';

  @override
  String get locationSharing_advertsHint =>
      'Ваши анонсы содержат ваше местоположение, поэтому его видит любой, кто слышит ваше радио.';

  @override
  String get locationSharing_contactsHeader =>
      'Контакты, которые могут запрашивать ваше радио';

  @override
  String get locationSharing_noTelemetry =>
      'Никто. Ваше радио не отвечает на запросы телеметрии.';

  @override
  String get locationSharing_noContacts => 'Ни одному контакту не разрешено.';

  @override
  String locationSharing_allContactsRow(int count) {
    return 'Все ваши контакты ($count)';
  }

  @override
  String get locationSharing_partLocation => 'Местоположение';

  @override
  String get locationSharing_partBattery => 'Батарея';

  @override
  String get locationSharing_partSensors => 'Датчики';

  @override
  String get locationSharing_hide => 'Скрыть моё местоположение от всех';
}
