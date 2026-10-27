// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Чати';

  @override
  String get chats_title => 'Чати';

  @override
  String get newChat_title => 'Виберіть контакт';

  @override
  String newChat_contactCount(int count) {
    return 'Контактів: $count';
  }

  @override
  String get newChat_newContact => 'Новий контакт';

  @override
  String get newChat_newChannel => 'Новий канал';

  @override
  String get newChat_myContacts => 'Мої контакти';

  @override
  String get newChat_discovered => 'Виявлені';

  @override
  String get repeaters_title => 'Керування ретрансляторами';

  @override
  String get nav_contacts => 'Контакти';

  @override
  String get nav_channels => 'Канали';

  @override
  String get nav_map => 'Карта';

  @override
  String get common_cancel => 'Скасувати';

  @override
  String get common_syncing_device_info => 'Читання даних пристрою...';

  @override
  String get common_syncing_contacts => 'Читання контактів...';

  @override
  String get common_syncing_channels => 'Читання каналів...';

  @override
  String get common_syncing_messages => 'Читання повідомлень...';

  @override
  String get common_ok => 'ОК';

  @override
  String get common_connect => 'Підключити';

  @override
  String get common_unknownDevice => 'Невідомий пристрій';

  @override
  String get common_save => 'Зберегти';

  @override
  String get common_delete => 'Видалити';

  @override
  String get common_deleteAll => 'Видалити все';

  @override
  String get common_close => 'Закрити';

  @override
  String get common_edit => 'Редагувати';

  @override
  String get common_add => 'Додати';

  @override
  String get common_settings => 'Налаштування';

  @override
  String get common_disconnect => 'Відключити';

  @override
  String get common_connected => 'Підключено';

  @override
  String get common_disconnected => 'Відключено';

  @override
  String get common_connectionLost => 'З\'єднання втрачено. Перепідключення...';

  @override
  String get common_reconnecting => 'Перепідключення...';

  @override
  String get common_create => 'Створити';

  @override
  String get common_continue => 'Продовжити';

  @override
  String get common_share => 'Поділитися';

  @override
  String get common_copy => 'Копіювати';

  @override
  String get common_retry => 'Повторити';

  @override
  String get common_hide => 'Приховати';

  @override
  String get common_remove => 'Прибрати';

  @override
  String get common_enable => 'Увімкнути';

  @override
  String get common_disable => 'Вимкнути';

  @override
  String get common_reboot => 'Перезавантажити';

  @override
  String get common_loading => 'Завантаження...';

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
  String get tcpScreenTitle => 'З\'єднатися через протокол TCP';

  @override
  String get tcpHostLabel => 'IP-адреса';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Порт';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Введіть кінцеву точку та підключіться';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Підключення до $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Необхідно вказати IP-адресу.';

  @override
  String get tcpErrorPortInvalid => 'Порт повинен бути в межах від 1 до 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Транспорт TCP не підтримується на цій платформі.';

  @override
  String get tcpErrorTimedOut =>
      'З\'єднання TCP завершилося через закінчення часу очікування.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Не вдалося встановити з\'єднання TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Підключити через USB';

  @override
  String get usbScreenSubtitle =>
      'Виберіть виявлене серійне пристрій і підключіть його безпосередньо до вашого вузла MeshCore.';

  @override
  String get usbScreenStatus => 'Виберіть пристрій USB';

  @override
  String get usbScreenNote =>
      'USB-серіальний інтерфейс активний на підтримуваних пристроях на базі Android та на десктопних платформах.';

  @override
  String get usbScreenEmptyState =>
      'Не знайдено жодних пристроїв USB. Підключіть один і перезавантажте.';

  @override
  String get usbErrorPermissionDenied =>
      'Було відмовлено у наданні дозволу на використання USB.';

  @override
  String get usbErrorDeviceMissing => 'Вибране USB-пристрій більше недоступне.';

  @override
  String get usbErrorInvalidPort => 'Виберіть дійсний USB-пристрій.';

  @override
  String get usbErrorBusy =>
      'Ще один запит на підключення через USB вже обробляється.';

  @override
  String get usbErrorNotConnected => 'Немає підключених пристроїв USB.';

  @override
  String get usbErrorOpenFailed => 'Не вдалося відкрити вибране USB-пристрій.';

  @override
  String get usbErrorConnectFailed =>
      'Не вдалося підключитися до вибраного USB-пристрою.';

  @override
  String get usbErrorUnsupported =>
      'Підтримка USB-серіального інтерфейсу не реалізована на цій платформі.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'У цій збірці немає бібліотеки USB serial, тому USB-пристрої не можна відкрити. Перевстановіть MeshTrax або повідомте, що ця збірка несправна.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Цей браузер не підтримує Web Serial. Використовуйте Chrome або Edge через HTTPS (або localhost).';

  @override
  String get usbErrorAlreadyActive => 'USB-з\'єднання вже встановлено.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Не було вибрано жодного пристрою USB.';

  @override
  String get usbErrorPortClosed => 'З\'єднання USB не встановлено.';

  @override
  String get usbErrorConnectTimedOut =>
      'З\'єднання не вдалося встановити. Переконайтеся, що пристрій має встановлене програмне забезпечення USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Пристрій для передачі даних по веб-серіалах';

  @override
  String get usbStatus_notConnected => 'Виберіть пристрій USB';

  @override
  String get usbStatus_connecting => 'Підключення до USB-пристрою...';

  @override
  String get usbStatus_searching => 'Пошук пристроїв USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Не вдалося встановити з\'єднання через USB: $error';
  }

  @override
  String get scanner_scanning => 'Пошук пристроїв...';

  @override
  String get scanner_connecting => 'Підключення...';

  @override
  String get scanner_disconnecting => 'Відключення...';

  @override
  String get scanner_notConnected => 'Не підключено';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Підключено до $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Показати всі Bluetooth-пристрої';

  @override
  String get scanner_showMeshCoreOnly => 'Лише радіо MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'Радіо не відповідає. Можливо, його треба спарити: відкрийте налаштування Bluetooth, додайте радіо, введіть його PIN і спробуйте ще раз.';

  @override
  String get scanner_pairingFailed =>
      'Спарювання Bluetooth скасовано або не вдалося. Переконайтеся, що до радіо більше нічого не підключено (наприклад, ваш телефон), потім спробуйте ще раз і введіть його PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Помилка підключення: $error';
  }

  @override
  String get scanner_stop => 'Стоп';

  @override
  String get scanner_scan => 'Сканувати';

  @override
  String get scanner_scanFromImage => 'Сканувати із зображення';

  @override
  String get scanner_noQrFoundInImage => 'На зображенні немає дійсного QR-коду';

  @override
  String get scanner_bluetoothOff => 'Bluetooth вимкнено';

  @override
  String get scanner_bluetoothOffMessage =>
      'Будь ласка, увімкніть Bluetooth, щоб сканувати пристрої.';

  @override
  String get scanner_chromeRequired => 'Потрібен браузер Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Для підтримки Bluetooth у цьому веб-додатку потрібен Google Chrome або браузер на базі Chromium.';

  @override
  String get scanner_enableBluetooth => 'Увімкніть Bluetooth';

  @override
  String get device_quickSwitch => 'Швидке перемикання';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Налаштування';

  @override
  String get settings_deviceInfo => 'Інформація про пристрій';

  @override
  String get settings_appSettings => 'Налаштування програми';

  @override
  String get settings_appSettingsSubtitle =>
      'Сповіщення, повідомлення та налаштування карти';

  @override
  String get settings_nodeSettings => 'Налаштування вузла';

  @override
  String get settings_nodeName => 'Ім\'я вузла';

  @override
  String get settings_nodeNameNotSet => 'Не встановлено';

  @override
  String get settings_nodeNameHint => 'Введіть ім\'я вузла';

  @override
  String get settings_nodeNameUpdated => 'Ім\'я оновлено';

  @override
  String get settings_radioSettings => 'Налаштування радіо';

  @override
  String get settings_radioSettingsSubtitle =>
      'Частота, потужність, коефіцієнт розширення';

  @override
  String get settings_radioSettingsUpdated => 'Налаштування радіо оновлено';

  @override
  String get settings_location => 'Розташування';

  @override
  String get settings_locationSubtitle => 'GPS координати';

  @override
  String get settings_locationUpdated => 'Розташування оновлено';

  @override
  String get settings_locationBothRequired => 'Введіть широту та довготу.';

  @override
  String get settings_locationInvalid => 'Некоректна широта або довгота.';

  @override
  String get settings_locationGPSEnable => 'Увімкнути GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Вмикає автоматичне оновлення місцезнаходження через GPS.';

  @override
  String get settings_latitude => 'Широта';

  @override
  String get settings_longitude => 'Довгота';

  @override
  String get settings_contactSettings => 'Налаштування контактів';

  @override
  String get settings_contactSettingsSubtitle =>
      'Налаштування для додавання контактів';

  @override
  String get settings_privacyMode => 'Режим приватності';

  @override
  String get settings_privacyModeSubtitle =>
      'Приховати ім\'я/розташування в оголошеннях';

  @override
  String get settings_privacyModeToggle =>
      'Увімкніть режим приватності, щоб приховати своє ім\'я та місцезнаходження в оголошеннях.';

  @override
  String get settings_privacyModeEnabled => 'Режим приватності увімкнено';

  @override
  String get settings_privacyModeDisabled => 'Режим приватності вимкнено';

  @override
  String get settings_privacy => 'Налаштування приватності';

  @override
  String get settings_privacySubtitle =>
      'Керуйте інформацією, яку буде спільно використовуватися';

  @override
  String get settings_privacySettingsDescription =>
      'Виберіть, яку інформацію ваш пристрій буде передавати іншим.';

  @override
  String get settings_denyAll => 'Відхилити все';

  @override
  String get settings_allowByContact => 'Дозволити за контактними прапорцями';

  @override
  String get settings_allowAll => 'Дозволити все';

  @override
  String get settings_telemetryBaseMode => 'Режим базової телеметрії';

  @override
  String get settings_telemetryLocationMode => 'Режим місця телеметрії';

  @override
  String get settings_telemetryEnvironmentMode => 'Режим середовища телеметрії';

  @override
  String get settings_advertLocation => 'Розміщення реклами';

  @override
  String get settings_advertLocationSubtitle =>
      'Включити місце розташування в оголошення';

  @override
  String get settings_multiAck => 'Багато підтверджень';

  @override
  String get settings_telemetryModeUpdated => 'Режим телеметрії оновлено';

  @override
  String get settings_actions => 'Дії';

  @override
  String get settings_sendAdvertisement => 'Оголосити себе';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Транслювати присутність зараз';

  @override
  String get settings_advertisementSent => 'Оголошення надіслано';

  @override
  String get settings_syncTime => 'Синхронізація часу';

  @override
  String get settings_syncTimeSubtitle =>
      'Встановити час пристрою відповідно до часу телефону.';

  @override
  String get settings_timeSynchronized => 'Час синхронізовано';

  @override
  String get settings_refreshContacts => 'Оновити контакти';

  @override
  String get settings_refreshContactsSubtitle =>
      'Перезавантажити список контактів з пристрою';

  @override
  String get settings_rebootDevice => 'Перезавантажити пристрій';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Перезавантажити пристрій MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ви впевнені, що хочете перезавантажити пристрій? Вас буде відключено.';

  @override
  String get settings_debug => 'Налагодження';

  @override
  String get settings_bleDebugLog => 'Журнал налагодження BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Команди BLE, відповіді та необроблені дані';

  @override
  String get settings_appDebugLog => 'Журнал налагодження програми';

  @override
  String get settings_appDebugLogSubtitle =>
      'Повідомлення налагодження програми';

  @override
  String get settings_exportDatabase => 'Експорт бази повідомлень';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Копія всіх чатів і контактів для налагодження. Зберігайте її приватно.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Базу збережено в: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Помилка експорту: $error';
  }

  @override
  String get settings_about => 'Про програму';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'Проєкт MeshTrax Source 2026';

  @override
  String get settings_aboutDescription =>
      'Клієнт Flutter з відкритим вихідним кодом для пристроїв мережі MeshCore LoRa.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Дані про висоту LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Ім\'я';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Статус';

  @override
  String get settings_infoBattery => 'Батарея';

  @override
  String get settings_infoPublicKey => 'Відкритий ключ';

  @override
  String get settings_infoContactsCount => 'Кількість контактів';

  @override
  String get settings_infoChannelCount => 'Кількість каналів';

  @override
  String get settings_presets => 'Попередні налаштування';

  @override
  String get settings_frequency => 'Частота (МГц)';

  @override
  String get settings_frequencyHelper => '300.0 - 2500.0';

  @override
  String get settings_frequencyInvalid => 'Некоректна частота (300-2500 МГц)';

  @override
  String get settings_bandwidth => 'Смуга пропускання';

  @override
  String get settings_spreadingFactor => 'Коефіцієнт розширення';

  @override
  String get settings_codingRate => 'Швидкість кодування';

  @override
  String get settings_txPower => 'Потужність TX (дБм)';

  @override
  String get settings_txPowerInvalid => 'Некоректна потужність TX';

  @override
  String get settings_clientRepeat => 'Автономна система';

  @override
  String get settings_clientRepeatSubtitle =>
      'Дозвольте цьому пристрою повторювати пакети даних для інших пристроїв.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Повтор без підключення до мережі вимагає частоти 433, 869 або 918 МГц.';

  @override
  String settings_error(String message) {
    return 'Помилка: $message';
  }

  @override
  String get appSettings_title => 'Налаштування програми';

  @override
  String get appSettings_appearance => 'Вигляд';

  @override
  String get appSettings_theme => 'Тема';

  @override
  String get appSettings_themeSystem => 'Системна';

  @override
  String get appSettings_themeLight => 'Світла';

  @override
  String get appSettings_themeDark => 'Темна';

  @override
  String get appSettings_language => 'Мова';

  @override
  String get appSettings_languageSystem => 'Як у системі';

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
  String get appSettings_languageRu => 'Російська';

  @override
  String get appSettings_languageUk => 'Українська';

  @override
  String get appSettings_enableMessageTracing =>
      'Увімкнути відстеження повідомлень';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Показувати детальні метадані про маршрутизацію та час для повідомлень';

  @override
  String get appSettings_senderNameColors => 'Кольорові імена відправників';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Окремий колір імені для кожного відправника в каналі. Якщо вимкнено, у всіх колір теми.';

  @override
  String get appSettings_showTextFormatting => 'Показувати форматування тексту';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown у повідомленнях: **жирний**, *курсив*, ||спойлери||, заголовки й посилання. Інші програми MeshCore показують символи як є.';

  @override
  String get appSettings_notifications => 'Сповіщення';

  @override
  String get appSettings_enableNotifications => 'Увімкнути сповіщення';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Отримувати сповіщення про повідомлення та оголошення';

  @override
  String get appSettings_notificationPermissionDenied =>
      'У доступі до сповіщень відмовлено';

  @override
  String get appSettings_notificationsEnabled => 'Сповіщення увімкнено';

  @override
  String get appSettings_notificationsDisabled => 'Сповіщення вимкнено';

  @override
  String get appSettings_messageNotifications => 'Сповіщення про повідомлення';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Показувати сповіщення при отриманні нових повідомлень';

  @override
  String get appSettings_channelMessageNotifications => 'Сповіщення каналів';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Показувати сповіщення при отриманні повідомлень каналу';

  @override
  String get appSettings_advertisementNotifications =>
      'Сповіщення про оголошення';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Показувати сповіщення при виявленні нових вузлів';

  @override
  String get appSettings_messaging => 'Обмін повідомленнями';

  @override
  String get appSettings_maxMessageRetries =>
      'Максимальна кількість повторних спроб надсилання повідомлення';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Кількість спроб повторного відправлення повідомлення перед тим, як позначити його як невдале';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Макс. повторів повідомлень у каналі';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Стільки разів повторюватиме надсилання, доки не почує хоча б один повтор';

  @override
  String get appSettings_battery => 'Батарея';

  @override
  String get appSettings_batteryChemistry => 'Хімія батареї';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Встановити для пристрою ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Підключіть пристрій, щоб вибрати';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2В)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65В)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2В)';

  @override
  String get appSettings_mapDisplay => 'Відображення карти';

  @override
  String get appSettings_showRepeaters => 'Показувати ретранслятори';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Відображати вузли-ретранслятори на карті';

  @override
  String get appSettings_showChatNodes => 'Показувати вузли чату';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Відображати вузли чату на карті';

  @override
  String get appSettings_showOtherNodes => 'Показувати інші вузли';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Відображати інші типи вузлів на карті';

  @override
  String get appSettings_timeFilter => 'Фільтр часу';

  @override
  String get appSettings_timeFilterShowAll => 'Показати всі вузли';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Показати вузли за останні $hours год';
  }

  @override
  String get appSettings_mapTimeFilter => 'Фільтр часу карти';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Показувати вузли, виявлені за:';

  @override
  String get appSettings_allTime => 'Весь час';

  @override
  String get appSettings_lastHour => 'Останню годину';

  @override
  String get appSettings_last6Hours => 'Останні 6 годин';

  @override
  String get appSettings_last24Hours => 'Останні 24 години';

  @override
  String get appSettings_lastWeek => 'Минулий тиждень';

  @override
  String get appSettings_unitsTitle => 'одиниці';

  @override
  String get appSettings_unitsMetric => 'Метричний (м / км)';

  @override
  String get appSettings_unitsImperial => 'Імперська (ft / mi)';

  @override
  String get appSettings_debugCard => 'Налагодження';

  @override
  String get appSettings_appDebugLogging => 'Логування налагодження програми';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Записувати повідомлення налагодження програми в лог для усунення несправностей.';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Логування налагодження програми увімкнено';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Налагодження програми вимкнено.';

  @override
  String get appSettings_incrementalContactSync =>
      'Часткова синхронізація контактів';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Після перепідключення запитувати в радіо лише контакти, що змінилися з минулого разу';

  @override
  String get contacts_title => 'Контакти';

  @override
  String get contacts_noContacts => 'Контактів не знайдено.';

  @override
  String get contacts_shareMyQrCode => 'Поділитися моїм QR-кодом';

  @override
  String get contacts_shareQrCodeDesc =>
      'Інші зможуть відсканувати його й додати вас у контакти';

  @override
  String get contacts_contactsWillAppear =>
      'Контакти з\'являться, коли пристрої надішлють оголошення.';

  @override
  String get contacts_unread => 'Непрочитане';

  @override
  String get contacts_searchContactsNoNumber => 'Пошук контактів...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Пошук контактів...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Пошук $number$str улюблених...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Пошук $number$str користувачів...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Пошук $number$str ретрансляторів...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Пошук $number$str серверів кімнат...';
  }

  @override
  String get contacts_noUnreadContacts => 'Немає непрочитаних контактів';

  @override
  String get contacts_noContactsFound => 'Контактів або груп не знайдено.';

  @override
  String get contacts_deleteContact => 'Видалити контакт';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Ви впевнені, що хочете видалити $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Контакт $contactName видалено.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Не вдалося видалити $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Жоден контакт не відповідає фільтру.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Видалити $contactName з контактів?';
  }

  @override
  String get contacts_manageRepeater => 'Керувати ретранслятором';

  @override
  String get contacts_manageRoom => 'Керувати сервером кімнати';

  @override
  String get contacts_roomLogin => 'Вхід у кімнату';

  @override
  String get contacts_openChat => 'Відкрити чат';

  @override
  String get contacts_editGroup => 'Редагувати групу';

  @override
  String get contacts_deleteGroup => 'Видалити групу';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Видалити $groupName?';
  }

  @override
  String get contacts_newGroup => 'Нова група';

  @override
  String get contacts_groupName => 'Назва групи';

  @override
  String get contacts_groupNameRequired => 'Назва групи обов\'язкова.';

  @override
  String get contacts_groupNameReserved => 'Ця назва групи зарезервована';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Група «$name» вже існує.';
  }

  @override
  String get contacts_filterContacts => 'Фільтрувати контакти...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Жоден контакт не відповідає фільтру.';

  @override
  String get contacts_noMembers => 'Немає учасників';

  @override
  String get contacts_lastSeenNow => 'В мережі';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'В мережі $minutes хв. тому';
  }

  @override
  String get contacts_lastSeenHourAgo => 'В мережі 1 годину тому';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'В мережі $hours год. тому';
  }

  @override
  String get contacts_lastSeenDayAgo => 'В мережі 1 день тому';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'В мережі $days дн. тому';
  }

  @override
  String get contact_info => 'Контактна інформація';

  @override
  String get contact_settings => 'Налаштування контактів';

  @override
  String get contact_telemetry => 'Телеметрія';

  @override
  String get contact_lastSeen => 'Останній раз бачили';

  @override
  String get contact_clearChat => 'Очистити чат';

  @override
  String get contact_teleBase => 'Базовий телебачення';

  @override
  String get contact_teleBaseSubtitle =>
      'Дозволити спільний доступ до рівня заряду батареї та базової телеметрії';

  @override
  String get contact_teleLoc => 'Розташування телеметрії';

  @override
  String get contact_teleLocSubtitle =>
      'Дозволити спільне використання даних про місцеположення';

  @override
  String get contact_teleEnv => 'Середовище телеметрії';

  @override
  String get contact_teleEnvSubtitle =>
      'Дозволити спільний доступ до даних датчиків середовища';

  @override
  String get contacts_publicKey => 'Відкритий ключ';

  @override
  String get channels_title => 'Канали';

  @override
  String get channels_noChannelsConfigured => 'Канали не налаштовані';

  @override
  String get channels_addPublicChannel => 'Додати публічний канал';

  @override
  String get channels_searchChannels => 'Пошук каналів...';

  @override
  String get channels_noChannelsFound => 'Каналів не знайдено';

  @override
  String channels_channelIndex(int index) {
    return 'Канал $index';
  }

  @override
  String get channels_hashtagChannel => 'Канал з хештегом';

  @override
  String get channels_public => 'Публічний';

  @override
  String get channels_private => 'Приватний';

  @override
  String get channels_publicChannel => 'Публічний канал';

  @override
  String get channels_privateChannel => 'Приватний канал';

  @override
  String get channels_editChannel => 'Редагувати канал';

  @override
  String get channels_shareChannel => 'Поділитися каналом';

  @override
  String get channels_shareChannelInstructions =>
      'Відскануйте QR-код, щоб додати канал.\nМеню → Додати канал → Сканувати QR-код';

  @override
  String get channels_secretKey => 'Секретний ключ';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

  @override
  String get channels_shareChannelQr => 'Сканувати QR-код каналу';

  @override
  String get channels_shareChannelWarning =>
      'Увага: кожен, хто відсканує цей QR-код, матиме доступ до цього каналу.';

  @override
  String get channels_muteChannel => 'Вимкнути сповіщення каналу';

  @override
  String get channels_unmuteChannel => 'Увімкнути сповіщення каналу';

  @override
  String get channels_deleteChannel => 'Видалити канал';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Видалити $name? Це не можна скасувати.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Не вдалося видалити канал \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Канал «$name» видалено';
  }

  @override
  String get channels_addChannel => 'Додати канал';

  @override
  String get channels_channelIndexLabel => 'Індекс каналу';

  @override
  String get channels_channelName => 'Назва каналу';

  @override
  String get channels_usePublicChannel => 'Використовувати публічний канал';

  @override
  String get channels_standardPublicPsk => 'Стандартний публічний PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Згенерувати випадковий ключ PSK';

  @override
  String get channels_enterChannelName => 'Будь ласка, введіть назву каналу';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK має складатися з 32 шістнадцяткових символів.';

  @override
  String get channels_addChannelConfirmation => 'Додати цей канал?';

  @override
  String get channels_channelAddedSuccess => 'Канал додано.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Немає вільних слотів для каналів.';

  @override
  String get appSettings_mentionNotifications => 'Сповіщення про згадки';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Коли вас згадують або вам відповідають — навіть у каналах без сповіщень';

  @override
  String notification_mentionIn(String channelName) {
    return 'Згадка в $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Канал «$name» додано';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Редагувати канал $index';
  }

  @override
  String get channels_smazCompression => 'Стиснення SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Канал «$name» оновлено';
  }

  @override
  String get channels_publicChannelAdded => 'Публічний канал додано';

  @override
  String get channels_sortBy => 'Сортувати за';

  @override
  String get channels_sortManual => 'Вручну';

  @override
  String get channels_sortAZ => 'А-Я';

  @override
  String get channels_sortLatestMessages => 'Останні повідомлення';

  @override
  String get channels_sortUnread => 'Непрочитані';

  @override
  String get channels_createPrivateChannel => 'Створити приватний канал';

  @override
  String get channels_createPrivateChannelDesc => 'Захищено секретним ключем.';

  @override
  String get channels_joinPrivateChannel => 'Приєднатися до приватного каналу';

  @override
  String get channels_joinPrivateChannelDesc => 'Ввести секретний ключ вручну.';

  @override
  String get channels_joinPublicChannel => 'Приєднатися до публічного каналу';

  @override
  String get channels_joinPublicChannelDesc =>
      'Будь-хто може приєднатися до цього каналу.';

  @override
  String get channels_joinHashtagChannel => 'Приєднатися до каналу з хештегом';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Будь-хто може приєднатися до каналів #hashtag.';

  @override
  String get channels_scanQrCode => 'Сканувати QR-код';

  @override
  String get channels_scanQrCodeComingSoon => 'Скоро буде';

  @override
  String get channels_enterHashtag => 'Введіть хештег';

  @override
  String get channels_hashtagHint => 'напр. #команда';

  @override
  String get chat_noMessages => 'Поки немає повідомлень.';

  @override
  String get chat_sendMessage => 'Надіслати повідомлення';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Надіслати повідомлення $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Надішліть повідомлення, щоб почати';

  @override
  String get chat_originalMessageNotFound =>
      'Оригінальне повідомлення не знайдено';

  @override
  String chat_replyingTo(String name) {
    return 'Відповідь $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Відповісти $name';
  }

  @override
  String get chat_location => 'Розташування';

  @override
  String get common_copiedToClipboard => 'Скопійовано в буфер обміну';

  @override
  String get common_copyToClipboard => 'Копіювати в буфер обміну';

  @override
  String get contacts_copyContactToClipboard =>
      'Копіювати мій контакт у буфер обміну';

  @override
  String get chat_typeMessage => 'Введіть повідомлення...';

  @override
  String get chat_searchMessages => 'Пошук повідомлень';

  @override
  String get chat_searchNoMatches => 'Немає збігів';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Повідомлення занадто довге (макс. $maxBytes байт).';
  }

  @override
  String get chat_messageCopied => 'Повідомлення скопійовано';

  @override
  String get chat_messageDeleted => 'Повідомлення видалено';

  @override
  String get chat_sendGif => 'Надіслати GIF';

  @override
  String get chat_reply => 'Відповісти';

  @override
  String get chat_newMessages => 'НОВІ ПОВІДОМЛЕННЯ';

  @override
  String get chat_addReaction => 'Додати реакцію';

  @override
  String get chat_mention => 'Згадати';

  @override
  String get dmChannel_menuLabel => 'Особисте повідомлення';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Написати особисто: $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Перевірте ключ і час останньої активності — імена не унікальні.';

  @override
  String get dmChannel_warningTitle => 'Це справді та людина?';

  @override
  String get dmChannel_warningBody =>
      'Імена в каналах кожен обирає сам, і підробити їх може будь-хто. Якщо йдеться про щось важливе, спершу перевірте відкритий ключ цього контакту іншим способом.';

  @override
  String get dmChannel_dontShowAgain => 'Більше не показувати';

  @override
  String get batterySleep_title => 'Нехай MeshTrax працює';

  @override
  String get batterySleep_bodySamsung =>
      'Телефони Samsung присипляють програми, щоб заощадити заряд, і це обриває зв\'язок із радіо. Відкрийте Налаштування → Програми → MeshTrax → Акумулятор і виберіть «Без обмежень». Також перевірте Акумулятор → Обмеження використання у фоновому режимі й переконайтеся, що MeshTrax немає у списках «Сплячі програми» та «Програми в глибокому сні».';

  @override
  String get batterySleep_bodyGeneric =>
      'Телефон може зупиняти MeshTrax у фоні, щоб заощадити заряд, і це обриває зв\'язок із радіо. Відкрийте налаштування акумулятора й установіть для MeshTrax «Без обмежень» (або «Немає обмежень»). На деяких телефонах також треба увімкнути «Автозапуск» для MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Відкрити налаштування';

  @override
  String get batterySleep_notNow => 'Не зараз';

  @override
  String get batterySleep_settingsTile => 'Робота MeshTrax у фоні';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Не давати економії заряду присипляти MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Поки що не можна написати $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'У вас ще немає їхнього ключа, а їм потрібен ваш, щоб відповісти, — ключі передаються лише в оголошеннях. «Надіслати моє оголошення» розсилає ваше просто звідси. «Запитати в каналі» вписує прохання в поле повідомлення, щоб ви його надіслали.';

  @override
  String get dmChannel_askInChannel => 'Запитати в каналі';

  @override
  String get dmChannel_sendMyAdvert => 'Надіслати моє оголошення';

  @override
  String get dmChannel_askText =>
      'будь ласка, надішліть оголошення, щоб можна було написати вам особисто';

  @override
  String get dmChannel_watching =>
      'Чекаємо на їхнє оголошення — коли воно надійде, вас запитають тут.';

  @override
  String dmChannel_advertHeard(String name) {
    return 'З $name тепер можна зв\'язатися';
  }

  @override
  String get dmChannel_openDm => 'Написати';

  @override
  String get appSettings_zoomLevel => 'Рівень масштабу';

  @override
  String get common_reset => 'Скинути';

  @override
  String get chat_reactionsTitle => 'Реакції';

  @override
  String get chat_reactionUnknownSender => 'Невідомий';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender: реакція на повідомлення, якого немає в цьому чаті';
  }

  @override
  String get chat_me => 'Я';

  @override
  String get emojiCategorySmileys => 'Емодзі';

  @override
  String get emojiCategoryGestures => 'Жести';

  @override
  String get emojiCategoryHearts => 'Серця';

  @override
  String get emojiCategoryObjects => 'Об\'єкти';

  @override
  String get gifPicker_title => 'Вибрати GIF';

  @override
  String get gifPicker_searchHint => 'Пошук GIF...';

  @override
  String get gifPicker_poweredBy => 'На базі GIPHY';

  @override
  String get gifPicker_noGifsFound => 'GIF не знайдено';

  @override
  String get gifPicker_failedLoad => 'Не вдалося завантажити GIF-файли';

  @override
  String get gifPicker_failedSearch => 'Пошук GIF не вдався';

  @override
  String get gifPicker_noInternet => 'Немає інтернет-з\'єднання';

  @override
  String get debugLog_appTitle => 'Журнал налагодження програми';

  @override
  String get debugLog_bleTitle => 'Журнал налагодження BLE';

  @override
  String get debugLog_copyLog => 'Копіювати журнал';

  @override
  String get debugLog_saveLog => 'Зберегти журнал у файл';

  @override
  String get debugLog_saved => 'Журнал збережено';

  @override
  String get debugLog_saveCancelled => 'Збереження скасовано';

  @override
  String get debugLog_filterAll => 'Усі';

  @override
  String get debugLog_filterWarnings => 'Попередження';

  @override
  String get debugLog_filterErrors => 'Помилки';

  @override
  String get debugLog_clearLog => 'Очистити журнал';

  @override
  String get debugLog_copied => 'Журнал налагодження скопійовано';

  @override
  String get debugLog_bleCopied => 'Журнал BLE скопійовано';

  @override
  String get debugLog_noEntries =>
      'Поки що немає записів журналу налагодження.';

  @override
  String get debugLog_enableInSettings =>
      'Увімкніть налагодження програми в налаштуваннях';

  @override
  String get debugLog_frames => 'Кадри';

  @override
  String get debugLog_rawLogRx => 'Необроблений лог - RX';

  @override
  String get debugLog_noBleActivity => 'Поки що немає активності BLE.';

  @override
  String debugFrame_length(int count) {
    return 'Довжина кадру: $count байт';
  }

  @override
  String debugFrame_command(String value) {
    return 'Команда: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Повідомлення:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- PubKey призначення: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Мітка часу: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Прапорці: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Тип тексту: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Команда CLI';

  @override
  String get debugFrame_textTypePlain => 'Звичайний';

  @override
  String debugFrame_text(String text) {
    return '- Текст: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Дамп Hex:';

  @override
  String get chat_hopSingular => 'Стрибок';

  @override
  String get chat_hopPlural => 'стрибків';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'стрибків',
      many: 'стрибків',
      few: 'стрибки',
      one: 'стрибок',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Встановити власний шлях';

  @override
  String get chat_fullPath => 'Повний шлях';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Деталі шляху ще недоступні. Спробуйте надіслати повідомлення для оновлення.';

  @override
  String get chat_type => 'Ввід';

  @override
  String get chat_path => 'Шлях';

  @override
  String get chat_publicKey => 'Відкритий ключ';

  @override
  String get chat_compressOutgoingMessages => 'Стискати вихідні повідомлення';

  @override
  String get chat_floodForced => 'На всю мережу (примусово)';

  @override
  String get chat_directForced => 'Прямий (примусово)';

  @override
  String chat_hopsForced(int count) {
    return '$count стрибків (примусово)';
  }

  @override
  String get chat_floodAuto => 'На всю мережу (авто)';

  @override
  String get chat_direct => 'Прямий';

  @override
  String get chat_poiShared => 'Точкою інтересу поділилися';

  @override
  String chat_unread(int count) {
    return 'Непрочитано: $count';
  }

  @override
  String get chat_openLink => 'Відкрити посилання?';

  @override
  String get chat_openLinkConfirmation =>
      'Ви хочете відкрити це посилання у браузері?';

  @override
  String get chat_open => 'Відкрити';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Не вдалося відкрити посилання: $url';
  }

  @override
  String get chat_invalidLink => 'Невірний формат посилання';

  @override
  String get map_lineOfSight => 'Пряма видимість';

  @override
  String get map_losScreenTitle => 'Пряма видимість';

  @override
  String get map_noNodesWithLocation =>
      'Немає вузлів з даними про розташування';

  @override
  String get map_nodesNeedGps =>
      'Вузли повинні надавати свої GPS координати,\nщоб з\'явитися на карті.';

  @override
  String map_nodesCount(int count) {
    return 'Вузли: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Мітки: $count';
  }

  @override
  String get map_chat => 'Чат';

  @override
  String get map_repeater => 'Ретранслятор';

  @override
  String get map_room => 'Кімната';

  @override
  String get map_sensor => 'Сенсор';

  @override
  String get map_pinDm => 'Ключ (DM)';

  @override
  String get map_pinPrivate => 'Замок (Приватний)';

  @override
  String get map_pinPublic => 'Ключ (Публічний)';

  @override
  String get map_lastSeen => 'Останній раз бачили';

  @override
  String get map_disconnectConfirm =>
      'Ви впевнені, що хочете відключитися від цього пристрою?';

  @override
  String get map_from => 'Від';

  @override
  String get map_source => 'Джерело';

  @override
  String get map_flags => 'Прапорці';

  @override
  String get map_shareMarkerHere => 'Поділитися маркером тут';

  @override
  String get map_setAsMyLocation => 'Встановити моє місцезнаходження';

  @override
  String get map_pinLabel => 'Мітка піна';

  @override
  String get map_label => 'Мітка';

  @override
  String get map_pointOfInterest => 'Точка інтересу';

  @override
  String get map_sendToContact => 'Надіслати контакту';

  @override
  String get map_sendToChannel => 'Надіслати в канал';

  @override
  String get map_noChannelsAvailable => 'Немає доступних каналів';

  @override
  String get map_publicLocationShare => 'Поділитися в публічному місці';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Ви збираєтеся поділитися розташуванням у $channelLabel. Цей канал публічний, і кожен, хто має ключ PSK, може це побачити.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Підключіться до пристрою, щоб поділитися маркерами';

  @override
  String get map_filterNodes => 'Фільтрувати вузли';

  @override
  String get map_chatNodes => 'Вузли чату';

  @override
  String get map_repeaters => 'Ретранслятори';

  @override
  String get map_otherNodes => 'Інші вузли';

  @override
  String get map_showOverlaps => 'Перекриття ключа повторювача';

  @override
  String get map_keyPrefix => 'Префікс ключа';

  @override
  String get map_filterByKeyPrefix => 'Фільтрувати за префіксом ключа';

  @override
  String get map_publicKeyPrefix => 'Префікс відкритого ключа';

  @override
  String get map_showDiscoveryContacts => 'Показати контакти Відкриття';

  @override
  String get map_guessedLocation => 'Визначено місцезнаходження';

  @override
  String get map_lastSeenTime => 'Час останньої активності';

  @override
  String get map_sharedPin => 'Спільний пін';

  @override
  String get map_joinRoom => 'Приєднатися до кімнати';

  @override
  String get map_manageRepeater => 'Керувати ретранслятором';

  @override
  String get map_tapToAdd => 'Натисніть на вузли, щоб додати їх до шляху';

  @override
  String get map_runTrace => 'Виконати трасування шляху';

  @override
  String get map_runTraceWithReturnPath => 'Повернутися назад тим же шляхом';

  @override
  String get map_removeLast => 'Видалити останній';

  @override
  String get map_pathTraceCancelled => 'Відмінується трасування шляху';

  @override
  String get time_justNow => 'Тільки що';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes хв. тому';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours год. тому';
  }

  @override
  String time_daysAgo(int days) {
    return '$days дн. тому';
  }

  @override
  String get time_hour => 'година';

  @override
  String get time_hours => 'годин';

  @override
  String get time_day => 'день';

  @override
  String get time_days => 'днів';

  @override
  String get time_week => 'тиждень';

  @override
  String get time_weeks => 'тижнів';

  @override
  String get time_month => 'місяць';

  @override
  String get time_months => 'місяців';

  @override
  String get time_minutes => 'хвилин';

  @override
  String get time_allTime => 'Весь час';

  @override
  String get dialog_disconnect => 'Відключити';

  @override
  String get dialog_disconnectConfirm =>
      'Ви впевнені, що хочете відключитися від цього пристрою?';

  @override
  String get login_repeaterLogin => 'Вхід у ретранслятор';

  @override
  String get login_roomLogin => 'Вхід у кімнату';

  @override
  String get login_password => 'Пароль';

  @override
  String get login_enterPassword => 'Введіть пароль';

  @override
  String get login_savePassword => 'Зберегти пароль';

  @override
  String get login_savePasswordSubtitle =>
      'Пароль буде надійно збережено на цьому пристрої.';

  @override
  String get login_repeaterDescription =>
      'Введіть пароль ретранслятора для доступу до налаштувань та статусу.';

  @override
  String get login_roomDescription =>
      'Введіть пароль кімнати для доступу до налаштувань та статусу.';

  @override
  String get login_login => 'Вхід';

  @override
  String login_attempt(int current, int max) {
    return 'Спроба $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Вхід не вдався: $error';
  }

  @override
  String get login_failedMessage =>
      'Вхід не вдався. Або пароль неправильний, або ретранслятор недосяжний.';

  @override
  String get common_reload => 'Перезавантажити';

  @override
  String get common_clear => 'Очистити';

  @override
  String get path_enterCustomPath => 'Ввести власний шлях';

  @override
  String get path_currentPathLabel => 'Поточний шлях';

  @override
  String get path_hexPrefixInstructions =>
      'Введіть 2-символьні hex-префікси для кожного стрибка, розділені комами.';

  @override
  String get path_hexPrefixExample =>
      'Приклад: A1,F2,3C (кожен вузол використовує перший байт свого відкритого ключа).';

  @override
  String get path_labelHexPrefixes => 'Hex-префікси';

  @override
  String get path_helperMaxHops =>
      'Макс. 64 стрибки. Кожен префікс - 2 шістнадцяткові символи (1 байт)';

  @override
  String get path_selectFromContacts => 'Вибрати з контактів:';

  @override
  String get path_noRepeatersFound =>
      'Ретрансляторів або серверів кімнат не знайдено.';

  @override
  String get path_customPathsRequire =>
      'Власні шляхи вимагають проміжних вузлів, які можуть передавати повідомлення.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Некоректні hex-префікси: $prefixes';
  }

  @override
  String get path_tooLong => 'Шлях занадто довгий. Максимум 64 стрибки.';

  @override
  String get path_setPath => 'Встановити шлях';

  @override
  String get repeater_management => 'Керування ретранслятором';

  @override
  String get room_management => 'Адміністрування сервера кімнати';

  @override
  String get repeater_guest => 'Інформація про ретранслятор';

  @override
  String get room_guest => 'Інформація про сервер кімнати';

  @override
  String get repeater_managementTools => 'Інструменти керування';

  @override
  String get repeater_guestTools => 'Інструменти для гостей';

  @override
  String get repeater_status => 'Статус';

  @override
  String get repeater_statusSubtitle =>
      'Показати статус, статистику та сусідів ретранслятора';

  @override
  String get repeater_telemetry => 'Телеметрія';

  @override
  String get repeater_telemetrySubtitle =>
      'Показати телеметрію сенсорів та статистику системи';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Надіслати команди ретранслятору';

  @override
  String get repeater_neighbors => 'Сусіди';

  @override
  String get repeater_neighborsSubtitle =>
      'Показати сусідів нульового стрибка.';

  @override
  String get repeater_settings => 'Налаштування';

  @override
  String get repeater_settingsSubtitle => 'Налаштувати параметри ретранслятора';

  @override
  String get repeater_clockSyncAfterLogin => 'Синхронізація годин після входу';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Автоматично надсилати повідомлення \"синхронізація годин\" після успішного входу.';

  @override
  String get repeater_statusTitle => 'Статус ретранслятора';

  @override
  String get repeater_refresh => 'Оновити';

  @override
  String get repeater_statusRequestTimeout =>
      'Час очікування запиту статусу вичерпано.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Помилка завантаження статусу: $error';
  }

  @override
  String get repeater_systemInformation => 'Системна інформація';

  @override
  String get repeater_battery => 'Батарея';

  @override
  String get repeater_clockAtLogin => 'Годинник (при вході)';

  @override
  String get repeater_uptime => 'Час роботи';

  @override
  String get repeater_queueLength => 'Довжина черги';

  @override
  String get repeater_debugFlags => 'Прапорці налагодження';

  @override
  String get repeater_radioStatistics => 'Статистика радіо';

  @override
  String get repeater_lastRssi => 'Останній RSSI';

  @override
  String get repeater_lastSnr => 'Останній SNR';

  @override
  String get repeater_noiseFloor => 'Рівень шуму';

  @override
  String get repeater_txAirtime => 'Ефірний час TX';

  @override
  String get repeater_rxAirtime => 'Ефірний час RX';

  @override
  String get repeater_packetStatistics => 'Статистика пакетів';

  @override
  String get repeater_sent => 'Надіслано';

  @override
  String get repeater_received => 'Отримано';

  @override
  String get repeater_duplicates => 'Дублікати';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days дн. $hours год $minutes хв $seconds с';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Всього: $total, На всю мережу: $flood, Прямі: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Всього: $total, На всю мережу: $flood, Прямі: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'На всю мережу: $flood, Прямі: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Всього: $total';
  }

  @override
  String get repeater_settingsTitle => 'Налаштування ретранслятора';

  @override
  String get repeater_basicSettings => 'Основні налаштування';

  @override
  String get repeater_repeaterName => 'Ім\'я ретранслятора';

  @override
  String get repeater_repeaterNameHelper =>
      'Показати ім\'я цього ретранслятора';

  @override
  String get repeater_adminPassword => 'Пароль адміністратора';

  @override
  String get repeater_adminPasswordHelper => 'Пароль повного доступу';

  @override
  String get repeater_guestPassword => 'Гостьовий пароль';

  @override
  String get repeater_guestPasswordHelper =>
      'Доступ лише для читання з паролем';

  @override
  String get repeater_radioSettings => 'Налаштування радіо';

  @override
  String get repeater_frequencyMhz => 'Частота (МГц)';

  @override
  String get repeater_frequencyHelper => '300-2500 МГц';

  @override
  String get repeater_txPower => 'Потужність TX';

  @override
  String get repeater_txPowerHelper => '-9 – 30 дБм';

  @override
  String get repeater_bandwidth => 'Смуга пропускання';

  @override
  String get repeater_spreadingFactor => 'Коефіцієнт розширення';

  @override
  String get repeater_codingRate => 'Швидкість кодування';

  @override
  String get repeater_locationSettings => 'Налаштування розташування';

  @override
  String get repeater_latitude => 'Широта';

  @override
  String get repeater_latitudeHelper =>
      'Десяткові градуси (наприклад, 37.7749)';

  @override
  String get repeater_longitude => 'Довгота';

  @override
  String get repeater_longitudeHelper =>
      'Десяткові градуси (наприклад, -122.4194)';

  @override
  String get repeater_features => 'Функції';

  @override
  String get repeater_packetForwarding => 'Пересилання пакетів';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Дозволити ретранслятору пересилати пакети';

  @override
  String get repeater_guestAccess => 'Гостьовий доступ';

  @override
  String get repeater_guestAccessSubtitle =>
      'Дозволити гостьовий доступ лише для читання';

  @override
  String get repeater_privacyMode => 'Режим приватності';

  @override
  String get repeater_privacyModeSubtitle =>
      'Приховати ім\'я/розташування в оголошеннях';

  @override
  String get repeater_advertisementSettings => 'Налаштування оголошень';

  @override
  String get repeater_localAdvertInterval =>
      'Інтервал локальних оголошень (0 стрибків)';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes хвилин';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Інтервал оголошень на всю мережу (flood)';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours годин';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Інтервал зашифрованих оголошень';

  @override
  String get repeater_dangerZone => 'Небезпечна зона';

  @override
  String get repeater_rebootRepeater => 'Перезавантажити ретранслятор';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Скинути пристрій ретранслятора';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ви впевнені, що хочете перезавантажити цей ретранслятор?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Перегенерувати ключ ідентичності';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Згенерувати нову пару ключів (публічний/приватний)';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Це створить нову ідентичність для ретранслятора. Продовжити?';

  @override
  String get repeater_eraseFileSystem => 'Очистити файлову систему';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Відформатувати файлову систему ретранслятора';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'УВАГА: Це видалить всі дані з ретранслятора. Це не можна скасувати!';

  @override
  String get repeater_eraseSerialOnly =>
      'Очищення доступне лише через послідовну консоль.';

  @override
  String repeater_commandSent(String command) {
    return 'Команда надіслана: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Помилка надсилання команди: $error';
  }

  @override
  String get repeater_confirm => 'Підтвердити';

  @override
  String get repeater_settingsSaved => 'Налаштування успішно збережено.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Помилка збереження налаштувань: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Оновити основні налаштування';

  @override
  String get repeater_refreshRadioSettings => 'Оновити налаштування радіо';

  @override
  String get repeater_refreshTxPower => 'Оновити потужність TX';

  @override
  String get repeater_refreshLocationSettings =>
      'Оновити налаштування розташування';

  @override
  String get repeater_refreshPacketForwarding => 'Оновити пересилання пакетів';

  @override
  String get repeater_refreshGuestAccess => 'Оновити гостьовий доступ';

  @override
  String get repeater_refreshPrivacyMode => 'Оновити режим приватності';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Оновити налаштування оголошень';

  @override
  String repeater_refreshed(String label) {
    return '$label оновлено';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Помилка оновлення $label';
  }

  @override
  String get repeater_cliTitle => 'Ретранслятор CLI';

  @override
  String get repeater_debugNextCommand => 'Налагодити наступну команду';

  @override
  String get repeater_commandHelp => 'Довідка';

  @override
  String get repeater_clearHistory => 'Очистити історію';

  @override
  String get repeater_noCommandsSent => 'Команди ще не надсилалися.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Введіть команду нижче або використовуйте швидкі команди';

  @override
  String get repeater_enterCommandHint => 'Введіть команду...';

  @override
  String get repeater_previousCommand => 'Попередня команда';

  @override
  String get repeater_nextCommand => 'Наступна команда';

  @override
  String get repeater_enterCommandFirst => 'Спершу введіть команду';

  @override
  String get repeater_cliCommandFrameTitle => 'Фрейм команди CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Помилка: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Отримати ім\'я';

  @override
  String get repeater_cliQuickGetRadio => 'Отримати Радіо';

  @override
  String get repeater_cliQuickGetTx => 'Отримати TX';

  @override
  String get repeater_cliQuickNeighbors => 'Сусіди';

  @override
  String get repeater_cliQuickVersion => 'Версія';

  @override
  String get repeater_cliQuickAdvertise => 'Оголосити';

  @override
  String get repeater_cliQuickClock => 'Годинник';

  @override
  String get repeater_cliQuickClockSync => 'Синхронізація годинника';

  @override
  String get repeater_cliQuickDiscovery => 'Відкрити сусідів';

  @override
  String get repeater_cliHelpAdvert => 'Надсилає пакет оголошення';

  @override
  String get repeater_cliHelpReboot =>
      'Перезавантажує пристрій. (Зверніть увагу, ви можете отримати «Тайм-аут», що є нормальним)';

  @override
  String get repeater_cliHelpClock =>
      'Відображає поточний час за годинником кожного пристрою.';

  @override
  String get repeater_cliHelpPassword =>
      'Встановлює новий пароль адміністратора для пристрою.';

  @override
  String get repeater_cliHelpVersion =>
      'Відображає версію пристрою та дату збірки прошивки.';

  @override
  String get repeater_cliHelpClearStats =>
      'Скидає різні лічильники статистики до нуля.';

  @override
  String get repeater_cliHelpSetAf => 'Встановлює коефіцієнт ефірного часу.';

  @override
  String get repeater_cliHelpSetTx =>
      'Встановлює потужність передачі LoRa в дБм (для застосування потрібне перезавантаження).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Вмикає або вимикає роль ретранслятора для цього вузла.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Сервер кімнати) Якщо «увімкнено», порожній пароль дозволить вхід, але не дозволить публікувати в кімнаті. (тільки читання)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Встановлює максимальну кількість стрибків для вхідних пакетів flood (якщо >= max, пакет не пересилається).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Встановлює поріг інтерференції (в дБ). Значення за замовчуванням — 14. Встановлення на 0 вимикає виявлення інтерференції каналу.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Встановлює інтервал скидання автоматичного контролера посилення (AGC). Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Вмикає або вимикає функціональність подвійних ACK.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Встановлює інтервал таймера для надсилання локального пакету оголошення (без ретрансляції). Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Встановлює інтервал таймера в годинах для надсилання пакету оголошення на всю мережу. Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Встановлює/оновлює гостьовий пароль. (для ретрансляторів гостьові підключення можуть надсилати запит «Get Stats»)';

  @override
  String get repeater_cliHelpSetName => 'Встановлює ім\'я для оголошення.';

  @override
  String get repeater_cliHelpSetLat =>
      'Встановлює широту для карти оголошень. (десяткові градуси)';

  @override
  String get repeater_cliHelpSetLon =>
      'Встановлює довготу для карти оголошень. (десяткові градуси)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Повністю встановлює нові параметри радіо та зберігає їх у налаштуваннях. Потребує команди «перезавантаження» для застосування.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Базові (експериментальні) параметри для застосування невеликої затримки до отриманих пакетів залежно від сили сигналу/оцінки. Встановіть 0 для вимкнення.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Встановлює множник для часу роботи в режимі «на всю мережу» (flood) для пакету та системи випадкових слотів, щоб затримати його відправку (для зменшення ймовірності колізій).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Те саме, що й txdelay, але для застосування випадкової затримки при пересиланні пакетів у прямому режимі.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Увімкнути/Вимкнути міст.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Встановити затримку перед пересиланням пакетів.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Виберіть, чи буде міст ретранслювати отримані пакети або передані пакети.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Встановити швидкість послідовного зв\'язку для мостів Rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Встановити секрет мосту для мостів espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Встановлює власний множник для коригування повідомлюваної напруги батареї (підтримується лише на деяких платах).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Встановлює тимчасові параметри радіо на задану кількість хвилин, потім повертається до початкових налаштувань. (не зберігає в налаштуваннях).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Змінює ACL (список контролю доступу). Видаляє відповідний запис (за префіксом публічного ключа), якщо «permissions» дорівнює нулю. Додає новий запис, якщо hex публічного ключа повний і його немає в ACL. Оновлює запис на основі префікса публічного ключа. Біти дозволів залежать від ролі прошивки, але нижні 2 біти: 0 (Гість), 1 (Тільки читання), 2 (Читання/Запис), 3 (Адміністратор).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Отримати тип мосту: немає, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Починає запис пакетів у файлову систему.';

  @override
  String get repeater_cliHelpLogStop =>
      'Зупиняє запис пакетів у файлову систему.';

  @override
  String get repeater_cliHelpLogErase =>
      'Видаляє журнали пакетів з файлової системи.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Показує список інших вузлів-ретрансляторів, почутих через оголошення без ретрансляції. Кожен рядок — id-hex-префікс:timestamp:snr-помножено-на-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Видаляє перший відповідний запис (за префіксом публічного ключа (hex)) зі списку сусідів.';

  @override
  String get repeater_cliHelpRegion =>
      '(тільки серійний) Перелічує всі визначені регіони та поточні дозволи на оголошення «на всю мережу» (flood).';

  @override
  String get repeater_cliHelpRegionLoad =>
      'ПРИМІТКА: це спеціальний виклик кількох команд. Кожна наступна команда — це назва регіону (з відступом пробілами для позначення ієрархії батьків, мінімум один пробіл). Завершується надсиланням порожнього рядка/команди.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Шукає регіон із заданим префіксом назви (або «» для глобальної області). Відповідає: «-> ім\'я-регіону (ім\'я-батька) \'F\'»';

  @override
  String get repeater_cliHelpRegionPut =>
      'Додає або оновлює визначення регіону з заданою назвою.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Видаляє визначення регіону з заданою назвою.';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Встановлює дозвіл «Flood» для заданого регіону. (\'\' для глобальної/успадкованої області)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Видаляє дозвіл «Flood» для заданого регіону. (ПРИМІТКА: на даному етапі не рекомендується використовувати для глобальної/успадкованої області!! )';

  @override
  String get repeater_cliHelpRegionHome =>
      'Відповідає поточним «домашнім» регіоном. (Примітка: поки ніде не застосовується, зарезервовано для майбутнього використання)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Встановлює «домашній» регіон.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Зберігає список/карту регіонів у сховищі.';

  @override
  String get repeater_cliHelpGps =>
      'Показує статус GPS. Коли GPS вимкнено, відповідає лише «вимкнено», якщо увімкнено — відповідає «увімкнено», статус, корекція, кількість супутників.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Увімкнути/вимкнути GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Синхронізує час вузла з годинником GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Встановлює позицію вузла за координатами GPS і зберігає в налаштуваннях.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Надає конфігурацію оголошення розташування вузла:\n- none : не включати розташування в оголошення\n- share : ділитися розташуванням GPS (з SensorManager)\n- prefs : оголошувати розташування, збережене в налаштуваннях';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Встановлює конфігурацію оголошення розташування.';

  @override
  String get repeater_commandsListTitle => 'Список команд';

  @override
  String get repeater_commandsListNote =>
      'ПРИМІТКА: для різних команд «set»... також існує команда «get»...';

  @override
  String get repeater_general => 'Загальні';

  @override
  String get repeater_settingsCategory => 'Налаштування';

  @override
  String get repeater_bridge => 'Міст';

  @override
  String get repeater_logging => 'Логування';

  @override
  String get repeater_neighborsRepeaterOnly => 'Сусіди (Тільки ретранслятор)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Керування регіонами (Тільки ретранслятор)';

  @override
  String get repeater_regionNote =>
      'Команди регіонів були введені для керування визначеннями та дозволами регіонів.';

  @override
  String get repeater_gpsManagement => 'Керування GPS';

  @override
  String get repeater_gpsNote =>
      'Команда GPS була введена для керування питаннями, пов\'язаними з локацією.';

  @override
  String get telemetry_receivedData => 'Дані телеметрії отримано';

  @override
  String get telemetry_requestTimeout => 'Час запиту телеметрії вичерпано.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Помилка завантаження телеметрії: $error';
  }

  @override
  String get telemetry_noData => 'Дані телеметрії недоступні.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Канал $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Батарея';

  @override
  String get telemetry_voltageLabel => 'Напруга';

  @override
  String get telemetry_mcuTemperatureLabel => 'Температура MCU';

  @override
  String get telemetry_temperatureLabel => 'Температура';

  @override
  String get telemetry_currentLabel => 'Поточний струм';

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
  String get neighbors_receivedData => 'Дані сусідів отримано';

  @override
  String get neighbors_requestTimedOut => 'Час запиту сусідів вичерпано.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Помилка завантаження сусідів: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ретранслятори-сусіди';

  @override
  String get neighbors_noData => 'Дані про сусідів недоступні.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Невідомий відкритий ключ $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Почуто: $time тому';
  }

  @override
  String get channelPath_title => 'Шлях пакету';

  @override
  String get channelPath_viewMap => 'Показати карту';

  @override
  String get channelPath_otherObservedPaths => 'Інші спостережувані шляхи';

  @override
  String get channelPath_repeaterHops => 'Стрибки ретранслятора';

  @override
  String get channelPath_noHopDetails =>
      'Деталі відправки не надані для цього пакету.';

  @override
  String get channelPath_messageDetails => 'Деталі повідомлення';

  @override
  String get channelPath_senderLabel => 'Відправник';

  @override
  String get channelPath_timeLabel => 'Час';

  @override
  String get channelPath_repeatsLabel => 'Повторення';

  @override
  String channelPath_pathLabel(int index) {
    return 'Шлях $index';
  }

  @override
  String get channelPath_observedLabel => 'Спостережено';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Спостережуваний шлях $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Немає даних про розташування';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Невідомий';

  @override
  String get channelPath_floodPath => 'На всю мережу';

  @override
  String get channelPath_directPath => 'Прямий';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 з $total стрибків';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed з $total стрибків';
  }

  @override
  String get channelPath_mapTitle => 'Карта шляху';

  @override
  String get channelPath_noRepeaterLocations =>
      'Позиції ретрансляторів недоступні для цього шляху.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Шлях $index (Основний)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Шлях';

  @override
  String get channelPath_observedPathHeader => 'Спостережуваний шлях';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Деталі стрибків недоступні для цього пакету.';

  @override
  String get channelPath_unknownRepeater => 'Невідомий ретранслятор';

  @override
  String get community_title => 'Спільнота';

  @override
  String get community_create => 'Створити спільноту';

  @override
  String get community_createDesc =>
      'Створити нову спільноту та поділитися через QR-код.';

  @override
  String get community_join => 'Приєднатися';

  @override
  String get community_joinTitle => 'Приєднатися до спільноти';

  @override
  String community_joinConfirmation(String name) {
    return 'Ви бажаєте приєднатися до спільноти «$name»?';
  }

  @override
  String get community_scanQr => 'Сканувати QR спільноти';

  @override
  String get community_scanInstructions =>
      'Наведіть камеру на QR-код спільноти.';

  @override
  String get community_showQr => 'Показати QR-код';

  @override
  String get community_publicChannel => 'Публічна спільнота';

  @override
  String get community_hashtagChannel => 'Хештег спільноти';

  @override
  String get community_name => 'Назва спільноти';

  @override
  String get community_enterName => 'Введіть назву спільноти';

  @override
  String community_created(String name) {
    return 'Спільноту «$name» створено';
  }

  @override
  String community_joined(String name) {
    return 'Приєднався до спільноти «$name»';
  }

  @override
  String get community_qrTitle => 'Поділитися спільнотою';

  @override
  String community_qrInstructions(String name) {
    return 'Відскануйте цей QR-код, щоб приєднатися до $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Канали хештегів спільноти доступні лише членам спільноти';

  @override
  String get community_invalidQrCode => 'Недійсний QR-код спільноти';

  @override
  String get community_alreadyMember => 'Вже учасник';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Ви вже є учасником «$name».';
  }

  @override
  String get community_addPublicChannel => 'Додати публічний канал спільноти';

  @override
  String get community_addPublicChannelHint =>
      'Автоматично додати публічний канал для цієї спільноти';

  @override
  String get community_noCommunities => 'Поки не приєднано до жодної групи.';

  @override
  String get community_scanOrCreate =>
      'Відскануйте QR-код або створіть спільноту, щоб почати';

  @override
  String get community_manageCommunities => 'Керувати спільнотами';

  @override
  String get community_delete => 'Покинути спільноту';

  @override
  String community_deleteConfirm(String name) {
    return 'Покинути «$name»?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'каналів',
      many: 'каналів',
      few: 'канали',
      one: 'канал',
    );
    return 'Це також видалить $count $_temp0 та їх повідомлення.';
  }

  @override
  String community_deleted(String name) {
    return 'Спільноту «$name» покинуто';
  }

  @override
  String get community_regenerateSecret => 'Перегенерувати секрет';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Перегенерувати секретний ключ для «$name»? Всі учасники повинні будуть відсканувати новий QR-код, щоб продовжити спілкування.';
  }

  @override
  String get community_regenerate => 'Перегенерувати';

  @override
  String community_secretRegenerated(String name) {
    return 'Секретний пароль для «$name» перегенеровано';
  }

  @override
  String get community_updateSecret => 'Оновити секрет';

  @override
  String community_secretUpdated(String name) {
    return 'Зміну секрету для «$name» оновлено';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Відскануйте новий QR-код, щоб оновити пароль для «$name»';
  }

  @override
  String get community_addHashtagChannel => 'Додати хештег спільноти';

  @override
  String get community_addHashtagChannelDesc =>
      'Додати канал хештегу для цієї спільноти';

  @override
  String get community_selectCommunity => 'Вибрати спільноту';

  @override
  String get community_regularHashtag => 'Звичайний хештег';

  @override
  String get community_regularHashtagDesc =>
      'Публічний хештег (будь-хто може приєднатися)';

  @override
  String get community_communityHashtag => 'Хештег спільноти';

  @override
  String get community_communityHashtagDesc =>
      'Ексклюзивно для членів спільноти';

  @override
  String community_forCommunity(String name) {
    return 'Для $name';
  }

  @override
  String get listFilter_tooltip => 'Фільтр та сортування';

  @override
  String get listFilter_sortBy => 'Сортувати за';

  @override
  String get listFilter_latestMessages => 'Останні повідомлення';

  @override
  String get listFilter_heardRecently => 'Нещодавно чули';

  @override
  String get listFilter_az => 'А-Я';

  @override
  String get listFilter_filters => 'Фільтри';

  @override
  String get listFilter_source => 'Джерело';

  @override
  String get listFilter_saved => 'Збережені';

  @override
  String get listFilter_discovered => 'Виявлені';

  @override
  String get listFilter_all => 'Все';

  @override
  String get listFilter_favorites => 'Улюблені';

  @override
  String get listFilter_addToFavorites => 'Додати до улюблених';

  @override
  String get listFilter_removeFromFavorites => 'Видалити зі списку улюблених';

  @override
  String get listFilter_users => 'Користувачі';

  @override
  String get listFilter_repeaters => 'Ретранслятори';

  @override
  String get listFilter_roomServers => 'Сервери кімнат';

  @override
  String get listFilter_unreadOnly => 'Тільки непрочитані повідомлення';

  @override
  String get listFilter_newGroup => 'Нова група';

  @override
  String get pathTrace_you => 'Ви';

  @override
  String get pathTrace_failed => 'Відстеження шляху не вдалося.';

  @override
  String get pathTrace_notAvailable => 'Трасування шляху недоступне.';

  @override
  String get pathTrace_refreshTooltip => 'Оновити Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Одне або більше хмелів відсутнє місце розташування!';

  @override
  String get pathTrace_clearTooltip => 'Очистити шлях';

  @override
  String get losSelectStartEnd =>
      'Виберіть початковий і кінцевий вузли для LOS.';

  @override
  String losRunFailed(String error) {
    return 'Помилка перевірки прямої видимості: $error';
  }

  @override
  String get losClearAllPoints => 'Очистити всі пункти';

  @override
  String get losRunToViewElevationProfile =>
      'Запустіть LOS, щоб переглянути профіль висоти';

  @override
  String get losMenuTitle => 'Меню LOS';

  @override
  String get losMenuSubtitle =>
      'Торкніться вузлів або утримуйте карту, щоб отримати власні точки';

  @override
  String get losShowDisplayNodes => 'Показати вузли відображення';

  @override
  String get losCustomPoints => 'Користувальницькі точки';

  @override
  String losCustomPointLabel(int index) {
    return 'Спеціальний $index';
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
  String get losRun => 'Запустіть LOS';

  @override
  String get losNoElevationData => 'Немає даних про висоту';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, чистий LOS, мінімальний зазор $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, заблоковано $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: перевірка...';

  @override
  String get losStatusNoData => 'LOS: немає даних';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total очищено, $blocked заблоковано, $unknown невідомо';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Дані про висоту недоступні для одного чи кількох зразків.';

  @override
  String get losErrorInvalidInput =>
      'Недійсні дані про точки/висоту для розрахунку LOS.';

  @override
  String get losRenameCustomPoint => 'Перейменуйте спеціальну точку';

  @override
  String get losPointName => 'Назва точки';

  @override
  String get losShowPanelTooltip => 'Показати панель LOS';

  @override
  String get losHidePanelTooltip => 'Приховати панель LOS';

  @override
  String get losElevationAttribution =>
      'Дані про висоту: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Радіогоризонт';

  @override
  String get losLegendLosBeam => 'Лінія прямої видимості';

  @override
  String get losLegendTerrain => 'Рельєф';

  @override
  String get losFrequencyLabel => 'Частота';

  @override
  String get losFrequencyInfoTooltip => 'Переглянути деталі розрахунку';

  @override
  String get losFrequencyDialogTitle => 'Розрахунок радіогоризонту';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Починаючи з k=$baselineK на $baselineFreq МГц, обчислення коригує k-фактор для поточного діапазону $frequencyMHz МГц, який визначає викривлену межу радіогоризонту.';
  }

  @override
  String get contacts_pathTrace => 'Трасування шляхів';

  @override
  String get contacts_ping => 'Пінгувати';

  @override
  String get contacts_repeaterPathTrace => 'Трасування шляху до повторювача';

  @override
  String get contacts_repeaterPing => 'Пінгувати повторювач';

  @override
  String get contacts_roomPathTrace => 'Трасування шляху до серверу кімнати';

  @override
  String get contacts_roomPing => 'Пінг сервера кімнати';

  @override
  String get contacts_chatTraceRoute => 'Трасування шляху';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Відстежити маршрут до $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Буфер обміну порожній';

  @override
  String get contacts_invalidAdvertFormat => 'Недійсні контактні дані';

  @override
  String get contacts_contactImported => 'Контакт було імпортовано.';

  @override
  String get contacts_contactImportFailed => 'Контакт не вдалося імпортувати';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name вже є у ваших контактах.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Реклама без перехоплення';

  @override
  String get contacts_floodAdvert => 'Залив реклами';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Копіювати оголошення в буфер обміну';

  @override
  String get contacts_addContactFromClipboard =>
      'Додати контакт з буфера обміну';

  @override
  String get contacts_ShareContact => 'Копіювати контакт у буфер обміну';

  @override
  String get contacts_ShareContactZeroHop =>
      'Поділитися контактом за оголошенням';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Відправлено контакт за оголошенням';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Не вдалося надіслати контакт.';

  @override
  String get contacts_contactAdvertCopied =>
      'Рекламу скопійовано до буфера обміну.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Копіювання оголошення в буфер обміну завершилося невдало';

  @override
  String get contacts_addContact => 'Додати контакт';

  @override
  String get contacts_scanQrCode => 'Сканувати QR контакту';

  @override
  String get contacts_scanQrCodeDesc =>
      'Відскануйте QR-код контакту з програми MeshCore';

  @override
  String get contacts_enterIdHash => 'Ввести контакт вручну';

  @override
  String get contacts_enterIdHashDesc =>
      'Вставте оголошення контакту або посилання meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... або відкритий ключ у hex';

  @override
  String get contacts_import => 'Імпорт';

  @override
  String get contacts_scanContactInstructions =>
      'Відскануйте QR-код контакту MeshCore';

  @override
  String get notification_activityTitle => 'Активність MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'повідомлень',
      many: 'повідомлень',
      few: 'повідомлення',
      one: 'повідомлення',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'повідомлень каналу',
      many: 'повідомлень каналу',
      few: 'повідомлення каналу',
      one: 'повідомлення каналу',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'нових вузлів',
      many: 'нових вузлів',
      few: 'нових вузли',
      one: 'новий вузол',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Виявлено новий $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Отримано нове повідомлення';

  @override
  String get settings_gpxExportRepeaters =>
      'Експортувати ретранслятори / сервер кімнати до GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Експортує ретранслятори / сервер кімнати з місцезнаходженням у файл GPX.';

  @override
  String get settings_gpxExportContacts => 'Експортувати супутників до GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Експортує супутників з місцезнаходженням у файл GPX.';

  @override
  String get settings_gpxExportAll => 'Експортувати всі контакти до GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Експортує всі контакти з місцем розташування у файл GPX.';

  @override
  String get settings_gpxExportSuccess => 'Успішно експортовано файл GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Немає контактів для експорту.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Не підтримується на вашому пристрої/операційній системі';

  @override
  String get settings_gpxExportError => 'Сталася помилка під час експорту.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Місцезнаходження повторювача та сервера кімнати';

  @override
  String get settings_gpxExportChat => 'Місця супутників';

  @override
  String get settings_gpxExportAllContacts => 'Усі місця контактів';

  @override
  String get settings_gpxExportShareText =>
      'Дані карти експортовані з MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'експорт даних карти MeshTrax у форматі GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Ближні ретранслятори';

  @override
  String get snrIndicator_lastSeen => 'Останній раз бачили';

  @override
  String get contactsSettings_title => 'Налаштування контактів';

  @override
  String get contactsSettings_autoAddTitle => 'Автоматичне виявлення';

  @override
  String get contactsSettings_otherTitle =>
      'Інші налаштування, пов\'язані з контактами';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Автоматично додавати користувачів';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Дозволити супутникові автоматично додавати виявлених користувачів';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Автоматично додавати повторювачі';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Дозволити супутнику автоматично додавати виявлені ретранслятори';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Автоматично додавати сервери кімнат';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Дозволити супровіднику автоматично додавати виявлені сервери кімнат.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Автоматично додавати датчики';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Дозволити супровіднику автоматично додавати виявлені сенсори';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Перезаписати найстаріше';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Коли список контактів заповнений, найстарший контакт без позначки улюбленого буде замінений.';

  @override
  String get discoveredContacts_Title => 'Виявлені контакти';

  @override
  String get discoveredContacts_noMatching =>
      'Відповідних контактів не знайдено';

  @override
  String get listFilter_searchHint => 'Пошук...';

  @override
  String get discoveredContacts_searchHint => 'Знайти виявлені контакти';

  @override
  String get discoveredContacts_contactAdded => 'Контакт додано';

  @override
  String get discoveredContacts_addContact => 'Додати контакт';

  @override
  String get discoveredContacts_copyContact =>
      'Копіювати контакт у буфер обміну';

  @override
  String get discoveredContacts_deleteContact => 'Видалити контакт';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Видалити всі виявлені контакти';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Ви впевнені, що хочете видалити всі виявлені контакти?';

  @override
  String get chat_sendCooldown =>
      'Будь ласка, зачекайте трохи, перш ніж відправляти знову.';

  @override
  String get chat_notConnected =>
      'Немає з\'єднання з радіо. Повідомлення не надіслано.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Перейти до найстарішого непрочитаного повідомлення';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'При відкритті чату з не прочитаними повідомленнями, прокрутіть до першого не прочитаного повідомлення, а не до останнього.';

  @override
  String get appSettings_languageHu => 'Угорський';

  @override
  String get appSettings_languageJa => 'Японська';

  @override
  String get appSettings_languageKo => 'Кореєська';

  @override
  String get radioStats_screenTitle => 'Дані про радіостанції';

  @override
  String get radioStats_notConnected =>
      'Підключіться до пристрою, щоб переглядати статистику радіопередач.';

  @override
  String get radioStats_firmwareTooOld =>
      'Статистика радіо приймача вимагає супутнього програмного забезпечення версії 8 або новішої.';

  @override
  String get radioStats_waiting => 'Очікую на отримання даних…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Рівень шуму: $noiseDbm дБм';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Останній показник RSSI: $rssiDbm дБм';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Останній показник SNR: $snr дБ';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Час трансляції на телеканалі TX (загальний): $seconds секунд';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Загальний час використання RX: $seconds секунд';
  }

  @override
  String get radioStats_chartCaption =>
      'Рівень шуму (дБм) на основі останніх вимірювань.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Рівень шуму: $noiseDbm дБм';
  }

  @override
  String get radioStats_stripWaiting => 'Отримано статистику радіо…';

  @override
  String get radioStats_settingsTile => 'Дані про радіостанції';

  @override
  String get radioStats_settingsSubtitle =>
      'Рівень шуму, RSSI, SNR та час, протягом якого пристрій використовує радіоканал.';

  @override
  String get translation_title => 'Переклад';

  @override
  String get translation_enableTitle => 'Увімкнути переклад';

  @override
  String get translation_enableSubtitle =>
      'Перекладати отримані повідомлення та дозволяти попередній переклад перед відправкою.';

  @override
  String get translation_composerTitle => 'Перекладіть перед відправкою';

  @override
  String get translation_composerSubtitle =>
      'Контролює стан ікон перекладу, який використовується за замовчуванням.';

  @override
  String get translation_targetLanguage => 'Цільова мова';

  @override
  String get translation_useAppLanguage => 'Використовуйте мову додатку';

  @override
  String get translation_downloadedModelLabel => 'Завантажений шаблон';

  @override
  String get translation_presetModelLabel =>
      'Заздалегідь налаштований модель від Hugging Face';

  @override
  String get translation_manualUrlLabel =>
      'Посилання на веб-сторінку з інструкцією';

  @override
  String get translation_downloadModel => 'Завантажити модель';

  @override
  String get translation_downloading => 'Завантаження...';

  @override
  String get translation_working => 'Працюю...';

  @override
  String get translation_stop => 'Припинити';

  @override
  String get translation_mergingChunks =>
      'Об\'єднання завантажених фрагментів у кінцевий файл...';

  @override
  String get translation_downloadedModels => 'Завантажені моделі';

  @override
  String get translation_deleteModel => 'Видалити модель';

  @override
  String get translation_modelDownloaded => 'Модель перекладу завантажена.';

  @override
  String get translation_downloadStopped => 'Завантаження призупинено.';

  @override
  String translation_downloadFailed(String error) {
    return 'Не вдалося завантажити: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Спочатку введіть URL моделі.';

  @override
  String get scanner_linuxPairingShowPin => 'Показати PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Приховати PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN‑код спарювання Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Введіть PIN для $deviceName (залиште порожнім, якщо його немає).';
  }

  @override
  String get translation_messageTranslation => 'Переклад повідомлення';

  @override
  String get translation_translateBeforeSending =>
      'Перекладіть перед відправкою';

  @override
  String get translation_composerEnabledHint =>
      'Повідомлення будуть перекладені перед відправленням.';

  @override
  String get translation_composerDisabledHint =>
      'Надсилайте повідомлення, використовуючи оригінальний текстовий формат.';

  @override
  String translation_translateTo(String language) {
    return 'Перекласти на $language';
  }

  @override
  String get translation_translationOptions => 'Варіанти перекладу';

  @override
  String get translation_systemLanguage => 'Мова системи';

  @override
  String get routing_title => 'Маршрутизація';

  @override
  String routing_route(String route) {
    return 'Збережений шлях: $route';
  }

  @override
  String get routing_noRoute =>
      'поки немає — наступне повідомлення піде на всю мережу й знайде його';

  @override
  String get routing_auto => 'Автоматично';

  @override
  String get routing_autoSubtitle =>
      'Використовувати шлях, збережений у радіо. Рекомендовано.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder увімкнено: спершу пробує вивчені маршрути';

  @override
  String get routing_flood => 'Завжди на всю мережу';

  @override
  String get routing_floodSubtitle => 'Кожне повідомлення йде на всю мережу';

  @override
  String get routing_custom => 'Власний шлях';

  @override
  String get routing_customSubtitle => 'Виберіть ретранслятори самі';

  @override
  String get routing_forget => 'Скинути шлях';

  @override
  String get routing_forgetDone =>
      'Шлях скинуто. Наступне повідомлення піде на всю мережу й знайде новий.';

  @override
  String get routing_pathfinder => 'Що знає Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Ретранслятори, які чують вас і їх, і вивчені маршрути туди й назад';

  @override
  String get path_direct => 'Напряму — без ретрансляторів';

  @override
  String get path_directSubtitle => 'Лише коли контакт чує саме це радіо';

  @override
  String get chat_kindFlood => 'на всю мережу';

  @override
  String get chat_kindDirect => 'напряму';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'стрибків',
      many: 'стрибків',
      few: 'стрибки',
      one: 'стрибок',
    );
    return 'маршрут ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'стрибків',
      many: 'стрибків',
      few: 'стрибки',
      one: 'стрибок',
    );
    return 'маршрут ($count $_temp0, припущених: $guessed)';
  }

  @override
  String get chat_statusQueued => 'У черзі';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Жоден ретранслятор вас не почув. Спробуємо знову, коли якийсь буде поруч.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'Радіо $name надсилає короткі коди ретрансляторів (1 байт). Pathfinder не зможе вивчити маршрути до цього контакту, доки його радіо не перейде на 2-байтові коди.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Надсилання · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Повтор · $kind · спроба $attempt з $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Доставлено · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Доставлено зі спроби $attempt · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Доставлено із запізненням · $kind · $secs с';
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
      other: 'спроб',
      many: 'спроб',
      few: 'спроб',
      one: 'спроби',
    );
    return 'Не доставлено після $attempts $_temp0 · торкніться, щоб надіслати знову';
  }

  @override
  String get chat_statusFailedShort =>
      'Не доставлено · торкніться, щоб надіслати знову';

  @override
  String get chat_resendingByFlood => 'Повторне надсилання на всю мережу';

  @override
  String get pathfinderHelp_title => 'Що робить Pathfinder';

  @override
  String get pathfinderHelp_what =>
      'Ваше радіо пам\'ятає один маршрут до кожного контакту, а коли він не спрацьовує, надсилає повідомлення на всю мережу. Pathfinder слухає все, що чує радіо: оголошення ретрансляторів, розмови в каналах, чужі повідомлення. З цього він будує карту: які ретранслятори чують один одного, які чують вас і які — кожного з ваших контактів.';

  @override
  String get pathfinderHelp_how =>
      'Коли ви надсилаєте повідомлення, Pathfinder спершу пробує свій найкращий маршрут, потім наступний за якістю і лише в крайньому разі надсилає на всю мережу. Бурштиновий значок шляху позначає повідомлення, надіслане маршрутом Pathfinder.';

  @override
  String get pathfinderHelp_learning =>
      'Йому потрібен час. Нова карта ще нічого не знає, тож спочатку ваші повідомлення надсилаються точно так само, як раніше. Після кількох годин прослуховування в одному місці він починає пропонувати маршрути, а кожна доставка чи невдача вчить його чогось нового. У перший день не чекайте від нього багато, а в кожному новому місці — знову менше.';

  @override
  String get pathfinderHelp_guessed =>
      'Іноді він заповнює прогалину припущенням: зв\'язком, який чув лише в зворотному напрямку. Тоді в рядку стану повідомлення видно, скільки стрибків припущено. Доставка їх підтверджує, а невдача коштує одну спробу, і нічого не запам\'ятовується.';

  @override
  String get pathfinderHelp_discover =>
      'Якщо Pathfinder не впевнений, які ретранслятори чують вас тут, він надсилає один короткий запит Discover (не частіше ніж раз на 10 хвилин і лише після невдалого надсилання). З радіо, що має GPS, він також запам\'ятовує на цьому телефоні, які ретранслятори чули вас у кожній зоні розміром близько 500 м, але ваше точне розташування не зберігає.';

  @override
  String get pathfinderHelp_off =>
      'Якщо вимкнути Pathfinder, радіо прокладатиме маршрути точно так само, як раніше.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Більше не показувати';

  @override
  String get pathfinderHelp_ok => 'ОК';

  @override
  String get settings_pathGraph => 'Pathfinder (експериментально)';

  @override
  String get settings_pathGraphSubtitle =>
      'Вивчає маршрути з усього, що чує радіо, і під час надсилання особистих повідомлень спершу пробує найкращі. Бурштиновий значок шляху позначає повідомлення, надіслане маршрутом Pathfinder.';

  @override
  String get map_routeAndTrace => 'Маршрут і трасування';

  @override
  String get map_pathfinderTrace => 'Трасування туди й назад';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Туди — найкращим маршрутом Pathfinder, назад — його найкращим зворотним маршрутом';

  @override
  String get map_routeBackMirrored =>
      'Зворотний маршрут поки невідомий — повернення тим самим шляхом';

  @override
  String get map_traceHelpTitle => 'Кнопки трасування шляху';

  @override
  String get map_traceHelpCustom => 'Введіть або виберіть ретранслятори самі.';

  @override
  String get map_traceHelpRun =>
      'Надсилає трасування в один бік через вибрані ретранслятори.';

  @override
  String get map_traceHelpThereAndBack => 'Туди й назад';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Надсилає трасування туди, а потім назад через ті самі ретранслятори у зворотному порядку.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder вибирає найкращий маршрут через два останні вибрані ретранслятори і найкращий маршрут назад до вас. Результат показує Pathfinder, які зв\'язки справді працюють. Потрібно вибрати два ретранслятори.';

  @override
  String get map_traceHelpRemoveLast =>
      'Прибирає останній ретранслятор зі шляху.';

  @override
  String get map_traceHelpCancel =>
      'Припиняє побудову трасування. Показується, доки не вибрано жодного ретранслятора.';

  @override
  String get chat_resendingByRoute =>
      'Повторне надсилання за заданим маршрутом';

  @override
  String get room_mute => 'Вимкнути сповіщення кімнати';

  @override
  String get room_unmute => 'Увімкнути сповіщення кімнати';

  @override
  String get room_roleAdmin => 'адмін';

  @override
  String get room_roleMember => 'учасник';

  @override
  String get room_roleReadOnly => 'лише читання';

  @override
  String room_clockOff(int minutes) {
    return 'Годинник кімнати розходиться приблизно на $minutes хв — час повідомлень може бути хибним';
  }

  @override
  String get room_fixClock => 'Виправити годинник';

  @override
  String get room_clockSyncSent => 'Синхронізацію годинника надіслано кімнаті';

  @override
  String get room_readOnlyNotice =>
      'Лише читання: кімната не прийняла ваш пароль, ваші повідомлення не дійдуть до інших учасників.';

  @override
  String get room_postAnnouncement => 'Опублікувати оголошення';

  @override
  String get room_postAnnouncementSubtitle =>
      'Надіслати повідомлення від імені кімнати всім учасникам';

  @override
  String get room_announcementSent => 'Оголошення опубліковано';

  @override
  String get room_announcementFailed => 'Не вдалося опублікувати оголошення';

  @override
  String get room_users => 'Користувачі кімнати';

  @override
  String get room_usersSubtitle => 'Перегляд адмінів і призначення ролей';

  @override
  String get room_usersAdminsNote =>
      'Кімната показує лише адмінів. Учасники з паролем кімнати не відображаються.';

  @override
  String get room_usersLoadFailed => 'Не вдалося завантажити список адмінів';

  @override
  String get room_setUserRole => 'Призначити роль';

  @override
  String get room_removeAccess => 'Прибрати доступ';

  @override
  String get room_removeOnlyUnknown =>
      'Цього користувача немає в контактах — його можна лише видалити, а не змінити.';

  @override
  String get room_roleUpdated => 'Роль оновлено';

  @override
  String get room_roleUpdateFailed => 'Не вдалося змінити роль';

  @override
  String get room_postsStored => 'Збережені повідомлення';

  @override
  String get room_postsDelivered => 'Доставлені повідомлення';

  @override
  String get room_reloadPosts => 'Перезавантажити останні повідомлення';

  @override
  String get room_reloadPostsExplain =>
      'Просить кімнату надіслати останні повідомлення ще раз (зберігається до 32). Потрібен пароль кімнати. Наявні повідомлення збережуться.';

  @override
  String get room_reloadFailed => 'Не вдалося скинути кімнату на радіо';

  @override
  String get companionCli_title => 'Командний рядок';

  @override
  String get companionCli_settingsSubtitle =>
      'Текстові команди для цього радіо';

  @override
  String get companionCli_rebooting => 'Перезапуск радіо…';

  @override
  String get companionCli_cancelled => 'Скасовано';

  @override
  String get companionCli_poweringOff => 'Вимкнення радіо…';

  @override
  String get companionCli_noReply => 'Радіо не відповідає. Спробуйте ще раз.';

  @override
  String get companionCli_powerOffTitle => 'Вимкнути радіо?';

  @override
  String get companionCli_powerOffBody =>
      'Воно залишиться вимкненим, доки ви не натиснете його кнопку або не під\'єднаєте живлення.';

  @override
  String get companionCli_powerOff => 'Вимкнути';

  @override
  String get companionCli_quickBoard => 'Плата';

  @override
  String get companionCli_quickWifiStatus => 'Стан Wi‑Fi';

  @override
  String get companionCli_quickWifiAddress => 'Адреса Wi‑Fi';

  @override
  String get companionCli_helpBoard => 'Показує виробника й модель плати.';

  @override
  String get companionCli_helpReboot => 'Перезапускає радіо.';

  @override
  String get companionCli_helpPowerOff => 'Вимикає радіо.';

  @override
  String get companionCli_helpSetPin =>
      'Задає PIN для спарювання Bluetooth. Діє після перезапуску.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Задає кількість годин, що додаються до UTC, для годинника на екрані самого радіо (від -12 до +14).';

  @override
  String get companionCli_helpSetTx =>
      'Задає потужність передавання в дБм. Діє одразу.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Задає поріг завад у дБ. 0 вимикає виявлення завад.';

  @override
  String get companionCli_helpSetCad =>
      'Слухає інші радіо перед надсиланням (виявлення активності в каналі).';

  @override
  String get companionCli_helpSetRxGain =>
      'Підвищене підсилення приймання на радіо SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Байтів на ретранслятор у маршруті: 0 = 1 байт, 1 = 2 байти, 2 = 3 байти.';

  @override
  String get companionCli_helpWifiStatus =>
      'Показує, чи підключено радіо до мережі Wi‑Fi.';

  @override
  String get companionCli_helpWifiIp => 'Показує адресу радіо в мережі Wi‑Fi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Задає назву мережі Wi‑Fi. Діє після перезапуску.';

  @override
  String get companionCli_helpWifiPwd =>
      'Задає пароль Wi‑Fi. Діє після перезапуску.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Вмикає (1) або вимикає (0) Wi‑Fi. Діє після перезапуску.';

  @override
  String get companionCli_helpWifiClear =>
      'Забуває мережу Wi‑Fi. Діє після перезапуску.';

  @override
  String get companionCli_remoteNoReply =>
      'Немає відповіді. Іншому радіо потрібна прошивка 1.18 або новіша, і воно має дозволяти вам користуватися його командним рядком.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Надіслано. Радіо не відповідає на перезапуск чи вимкнення.';

  @override
  String companionCli_blocked(String name, String command) {
    return 'Спроба від $name скористатися командним рядком вашого радіо: «$command». Не дозволено.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Спроба скористатися командним рядком вашого радіо: «$command». Не дозволено.';
  }

  @override
  String get contact_remoteCli => 'Дозволити віддалений командний рядок';

  @override
  String get contact_remoteCliSubtitle =>
      'Цей контакт зможе виконувати команди на вашому радіо';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Дозволити $name керувати вашим радіо?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name зможе змінювати налаштування вашого радіо, читати ваш пароль Wi‑Fi, перейменовувати радіо, перезапускати й вимикати його. Дозволяйте лише тому, кому цілком довіряєте.';
  }

  @override
  String get contact_remoteCliAllow => 'Дозволити';

  @override
  String get connection_secondApp =>
      'До цього радіо підключена інша програма. Повідомлення й налаштування можуть переплутатися. Закрийте іншу програму.';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => 'Мережа, пароль і підключення';

  @override
  String get wifi_use => 'Використовувати Wi‑Fi';

  @override
  String get wifi_networkName => 'Назва мережі';

  @override
  String get wifi_password => 'Пароль';

  @override
  String get wifi_passwordUnchanged => 'Без змін';

  @override
  String get wifi_showPassword => 'Показати пароль';

  @override
  String get wifi_nameMissing => 'Введіть назву мережі';

  @override
  String get wifi_nameTooLong => 'Назва мережі задовга (не більше 32 байтів)';

  @override
  String get wifi_passwordTooLong => 'Пароль задовгий (не більше 63 байтів)';

  @override
  String get wifi_savedRestart =>
      'Збережено. Зміни Wi‑Fi діятимуть після перезапуску радіо.';

  @override
  String get wifi_forget => 'Забути мережу';

  @override
  String get wifi_forgetConfirm =>
      'Забути цю мережу Wi‑Fi? Після перезапуску радіо перестане використовувати Wi‑Fi.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Радіо цього не прийняло: $reply';
  }

  @override
  String get wifi_noReply => 'Радіо не відповідає. Спробуйте ще раз.';

  @override
  String get wifi_restartTitle => 'Перезапустити радіо?';

  @override
  String get wifi_later => 'Пізніше';

  @override
  String get wifi_loadFailed =>
      'Не вдалося прочитати налаштування Wi‑Fi з радіо.';

  @override
  String wifi_connectedTo(String address) {
    return 'Підключено · $address';
  }

  @override
  String get wifi_notConnected => 'Немає підключення до Wi‑Fi';

  @override
  String wifi_portNote(int port) {
    return 'Програми в тій самій мережі можуть підключитися через порт $port';
  }

  @override
  String get wifi_connectOverWifi => 'Підключитися через Wi‑Fi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax від\'єднається від цього радіо й відкриє екран TCP з уже заповненими адресою $address і портом $port. Там натисніть «Підключити».';
  }

  @override
  String get wifi_noteRestart => 'Зміни діятимуть після перезапуску радіо.';

  @override
  String get wifi_noteSecurity =>
      'Будь-хто у вашій мережі Wi‑Fi може підключитися до радіо через порт 5000. Пароля для цього немає.';

  @override
  String get wifi_noteBattery =>
      'Wi‑Fi не дає радіо засинати, тож акумулятор розряджається швидше.';

  @override
  String get wifi_noteWrongPassword =>
      'Якщо пароль неправильний, радіо пробує знову кожні кілька секунд. Bluetooth і далі працює.';

  @override
  String get room_selfDemoteWarning =>
      'Ви змінюєте власний доступ. Якщо ви втратите роль адміна, повернути її зможе лише консоль кімнати.';

  @override
  String get scanner_offlineMaps => 'Офлайн-карти';

  @override
  String get appSettings_offlineMaps => 'Офлайн-карти';

  @override
  String get appSettings_offlineMapsNone => 'Нічого не завантажено';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count регіонів',
      many: '$count регіонів',
      few: '$count регіони',
      one: '$count регіон',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count районів морських карт',
      many: '$count районів морських карт',
      few: '$count райони морських карт',
      one: '$count район морських карт',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Доступно $count оновлень',
      many: 'Доступно $count оновлень',
      few: 'Доступні $count оновлення',
      one: 'Доступне $count оновлення',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Завантажувати карти лише через Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Завантаження карт чекає на підключення до Wi‑Fi';

  @override
  String get offlineMaps_title => 'Офлайн-карти';

  @override
  String get offlineMaps_tabMaps => 'Карти';

  @override
  String get offlineMaps_tabCharts => 'Морські карти';

  @override
  String get offlineMaps_chartsNotice => 'Не для навігації · Чому?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Рекомендовані · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Райони карт за узбережжями';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count районів',
      many: '$count районів',
      few: '$count райони',
      one: '$count район',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Завантажено: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Вибрано: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Вибрати все';

  @override
  String get offlineMaps_clearSelection => 'Очистити';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Також у: $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Поки недоступно';

  @override
  String get offlineMaps_chartsHint =>
      'Карти NOAA вибирають за узбережжям на вкладці «Морські карти».';

  @override
  String offlineMaps_chartsName(String area) {
    return '$area — карти NOAA';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count районів',
      many: '$count районів',
      few: '$count райони',
      one: '$count район',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Завантажені';

  @override
  String get offlineMaps_refresh => 'Перевірити нові карти';

  @override
  String get offlineMaps_loading => 'Завантаження списку карт…';

  @override
  String get offlineMaps_serverError => 'Сервер карт недоступний';

  @override
  String get offlineMaps_unavailable => 'Карт поки немає';

  @override
  String get offlineMaps_unavailableHint => 'Перевірте пізніше.';

  @override
  String get offlineMaps_chartsUnavailable => 'Карт NOAA поки немає';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Показано список від $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Оновіть MeshTrax, щоб отримати найновіші карти.';

  @override
  String get offlineMaps_world => 'Світ';

  @override
  String get offlineMaps_suggested => 'Рекомендовані';

  @override
  String get offlineMaps_regions => 'Регіони';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Регіони: $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return 'Усередині: $count';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return 'Офлайн-карти на цьому пристрої: $size';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Оновлення ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Оновити все ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Завантаження';

  @override
  String get offlineMaps_update => 'Оновити';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Завантажено $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Є оновлення';

  @override
  String get offlineMaps_otherFiles => 'Інші файли карт';

  @override
  String get offlineMaps_emptyTitle => 'Офлайн-карт поки немає';

  @override
  String get offlineMaps_emptyBody =>
      'Завантажте регіон, щоб користуватися картою без з\'єднання.';

  @override
  String get offlineMaps_findMaps => 'Знайти карти';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Видалити $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Звільниться $size. Пізніше можна завантажити знову.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return 'Видалено: $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done з $total';
  }

  @override
  String get offlineMaps_kindMap => 'Карта';

  @override
  String get offlineMaps_kindMapDetail =>
      'OpenStreetMap: вулиці, стежки, місця';

  @override
  String get offlineMaps_kindContours => 'Горизонталі';

  @override
  String get offlineMaps_kindContoursDetail => 'Лінії висот';

  @override
  String get offlineMaps_kindUsgs => 'Топокарта USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Стежки, струмки, заповідники';

  @override
  String get offlineMaps_kindTerrain => 'Відмивка рельєфу';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Пагорби й гори з тінями під картою';

  @override
  String get offlineMaps_kindCharts => 'Морські карти NOAA';

  @override
  String get offlineMaps_usOnly => 'Лише США';

  @override
  String offlineMaps_download(String size) {
    return 'Завантажити $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Завантажити';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Велике завантаження ($size). Використовуйте Wi‑Fi і тримайте пристрій на заряджанні.';
  }

  @override
  String get offlineMaps_waiting => 'Очікування…';

  @override
  String get offlineMaps_checking => 'Перевірка завантаження…';

  @override
  String get offlineMaps_retrying => 'Повторна спроба…';

  @override
  String offlineMaps_failed(String error) {
    return 'Помилка завантаження: $error';
  }

  @override
  String get offlineMaps_pause => 'Пауза';

  @override
  String get offlineMaps_resume => 'Продовжити';

  @override
  String get offlineMaps_deleteRegion => 'Видалити регіон';

  @override
  String get offlineMaps_notInCatalogue => 'Недоступно для цього регіону';

  @override
  String get offlineMaps_notificationRunning => 'Завантаження карти';

  @override
  String get offlineMaps_notificationPaused => 'Завантаження карти призупинено';

  @override
  String get offlineMaps_notificationFailed => 'Не вдалося завантажити карту';

  @override
  String get offlineMaps_clearTileCache => 'Очистити кеш онлайн-карт';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Видалити фрагменти онлайн-карт, збережені під час перегляду? Завантажені карти залишаться.';

  @override
  String get offlineMaps_tileCacheCleared => 'Кеш онлайн-карт очищено';

  @override
  String get map_notForNavigation => 'Не для навігації';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax малює ці карти за даними NOAA, щоб ви бачили воду навколо своїх радіо й могли планувати. Це не офіційні карти. Не прокладайте за ними курс.';

  @override
  String get map_chartsNoticeWhy => 'Чому:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Вони застарівають. NOAA постійно виправляє свої карти, а завантажена карта не змінюється, доки ви не оновите її в розділі «Офлайн-карти».';

  @override
  String get map_chartsNoticeLeftOut =>
      'На них показано не все. Багато умовних знаків, секторів вогнів і приміток не малюються, а частину підписів видно лише при збільшенні.';

  @override
  String get map_chartsNoticePositions =>
      'Координати можуть бути неточними або застарілими. GPS може помилятися на 10 м (30 футів) і більше, а вузол перебуває там, звідки востаннє повідомив про себе.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax — не сертифікований картплотер.';

  @override
  String get map_chartsNoticeUse =>
      'Для навігації використовуйте офіційні актуальні карти NOAA (паперові або ENC від NOAA у сертифікованому картплотері) з останніми Повідомленнями мореплавцям.';

  @override
  String get map_sourceOnline => 'Онлайн';

  @override
  String get map_sourceOffline => 'Офлайн';

  @override
  String get map_downloadForDetail => 'Завантажте регіон, щоб бачити подробиці';

  @override
  String get map_zoomInForOfflineMap => 'Збільште, щоб побачити офлайн-карту';

  @override
  String get map_noCharts => 'Тут немає морських карт';

  @override
  String get map_myLocation => 'Моє розташування';

  @override
  String get map_zoomIn => 'Збільшити';

  @override
  String get map_zoomOut => 'Зменшити';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS увімк.';

  @override
  String get gps_off => 'GPS вимк.';

  @override
  String get gps_onHint => 'Радіо оновлює своє розташування за GPS.';

  @override
  String get gps_offHint =>
      'Вимкнений GPS заощаджує акумулятор радіо. Після ввімкнення пошук розташування може тривати кілька хвилин.';

  @override
  String get gps_asking => 'Запит до радіо...';

  @override
  String get gps_noPosition =>
      'Розташування ще немає. Надворі перше визначення може тривати кілька хвилин.';

  @override
  String get gps_position => 'Координати';

  @override
  String get gps_altitude => 'Висота';

  @override
  String gps_readAgo(String ago) {
    return 'Прочитано з радіо $ago тому';
  }

  @override
  String get gps_turnOnTitle => 'Увімкнути GPS?';

  @override
  String get gps_turnOnBody =>
      'GPS радіо вимкнено. Після ввімкнення пошук розташування може тривати кілька хвилин.';

  @override
  String get gps_turnOn => 'Увімкнути';

  @override
  String get gps_notNow => 'Не зараз';

  @override
  String get map_zoomInForCharts => 'Збільште, щоб побачити морські карти';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Завантажити $region · $size';
  }

  @override
  String get mapLayers_title => 'Шари карти';

  @override
  String get mapLayers_mapType => 'Тип карти';

  @override
  String get mapLayers_standard => 'Стандартна';

  @override
  String get mapLayers_usgs => 'Топокарта USGS';

  @override
  String get mapLayers_charts => 'Морські карти';

  @override
  String get mapLayers_notDownloaded => 'Не завантажено';

  @override
  String get mapLayers_offlineOnly => 'Лише офлайн';

  @override
  String get mapLayers_details => 'Деталі карти';

  @override
  String get mapLayers_contours => 'Горизонталі';

  @override
  String get mapLayers_hillShading => 'Відмивка рельєфу';

  @override
  String get mapLayers_dark => 'Темна карта';

  @override
  String get mapLayers_downloadedAreas => 'Завантажені області';

  @override
  String get mapLayers_nodes => 'Вузли';

  @override
  String get mapLayers_pins => 'Мітки';

  @override
  String get mapLayers_guessed => 'Імовірні';

  @override
  String get mapLayers_moreFilters => 'Інші фільтри';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Остання активність, префікс ключа, перетини';

  @override
  String get map_legend => 'Легенда';

  @override
  String get scanner_map => 'Карта';

  @override
  String get structured_openMap => 'Відкрити карту';

  @override
  String get structured_addToCalendar => 'Додати до календаря';

  @override
  String get structured_details => 'Подробиці';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Подія';

  @override
  String get structured_notice => 'Оповіщення';

  @override
  String get structured_allDay => 'Увесь день';

  @override
  String get structured_calendarFailed => 'Не вдалося відкрити календар';

  @override
  String get structured_today => 'Сьогодні';

  @override
  String get structured_tomorrow => 'Завтра';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Через $count днів',
      many: 'Через $count днів',
      few: 'Через $count дні',
      one: 'Через $count день',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Минуло';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'День $day з $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count днів',
      many: '$count днів',
      few: '$count дні',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Дата завершення';

  @override
  String get dialog_eventSameDay => 'Той самий день';

  @override
  String get structured_map => 'Карта';

  @override
  String get structured_navigate => 'Навігація';

  @override
  String get structured_channel => 'Канал';

  @override
  String get structured_contact => 'Контакт';

  @override
  String get structured_room => 'Кімната';

  @override
  String get structured_repeater => 'Ретранслятор';

  @override
  String get structured_sensor => 'Сенсор';

  @override
  String get structured_joinChannel => 'Приєднатися до каналу';

  @override
  String get structured_addContact => 'Додати контакт';

  @override
  String get structured_addRoom => 'Додати кімнату';

  @override
  String get structured_addRepeater => 'Додати ретранслятор';

  @override
  String get structured_addSensor => 'Додати сенсор';

  @override
  String get structured_open => 'Відкрити';

  @override
  String get structured_added => 'Додано';

  @override
  String get tray_add => 'Додати';

  @override
  String get tray_myLocation => 'Моє розташування';

  @override
  String get tray_pointOnMap => 'Точка на карті';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Подія';

  @override
  String get tray_notice => 'Оповіщення';

  @override
  String get tray_noRadioPosition =>
      'Ваше радіо ще не має розташування. Виберіть його на карті.';

  @override
  String get dialog_insert => 'Вставити';

  @override
  String get dialog_eventTitle => 'Назва';

  @override
  String get dialog_eventDate => 'Дата';

  @override
  String get dialog_eventStart => 'Початок';

  @override
  String get dialog_eventEnd => 'Кінець';

  @override
  String get dialog_eventNoEnd => 'Без часу завершення';

  @override
  String get dialog_eventPlace => 'Місце (необов\'язково)';

  @override
  String get dialog_pickOnMap => 'Вибрати на карті';

  @override
  String get dialog_sosTitle => 'Надіслати SOS';

  @override
  String get dialog_sosText => 'Що сталося?';

  @override
  String get dialog_noticeTitle => 'Оповіщення';

  @override
  String get dialog_noticeText => 'Що мають знати всі?';

  @override
  String get dialog_labelTitle => 'Точка на карті';

  @override
  String get dialog_note => 'Примітка (необов\'язково)';

  @override
  String get paste_convertLocation =>
      'Схоже на посилання на карту. Перетворити на розташування?';

  @override
  String get paste_convertEvent =>
      'Схоже на подію з календаря. Перетворити на подію?';

  @override
  String get paste_convert => 'Перетворити';

  @override
  String get paste_resolving => 'Обробка посилання…';

  @override
  String get paste_resolveFailed => 'Не вдалося обробити посилання';

  @override
  String get pinned_dismiss => 'Сховати';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Приєднатися до каналу $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Ви вже в каналі $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Ви приєдналися до $name';
  }

  @override
  String get map_pickPositionHint => 'Торкніться карти, щоб вибрати точку';

  @override
  String get map_legendMesh => 'Мережа';

  @override
  String get chartLegend_title => 'Умовні знаки карт';

  @override
  String get chartLegend_sectionBuoys => 'Буї та знаки';

  @override
  String get chartLegend_sectionLights => 'Вогні';

  @override
  String get chartLegend_sectionHazards => 'Небезпеки';

  @override
  String get chartLegend_sectionTides => 'Припливи й течії';

  @override
  String get chartLegend_sectionDepths => 'Глибини та ґрунт';

  @override
  String get chartLegend_sectionAreas => 'Райони, смуги й лінії';

  @override
  String get chartLegend_sectionLandmarks => 'Орієнтири';

  @override
  String get chartLegend_sectionAbbreviations => 'Скорочення';

  @override
  String get chartLegend_chartNo1 => 'Усі умовні знаки: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Зелений циліндричний буй';

  @override
  String get chartLegend_portBuoyHint => 'Залишайте ліворуч, заходячи з моря';

  @override
  String get chartLegend_starboardBuoy => 'Червоний конічний буй';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Залишайте праворуч, заходячи: червоний — праворуч, коли повертаєтеся з моря';

  @override
  String get chartLegend_junctionBuoy => 'Буй з горизонтальними смугами';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Розгалуження фарватеру: орієнтуйтеся за кольором верхньої смуги';

  @override
  String get chartLegend_safeWaterBuoy => 'Червоні й білі вертикальні смуги';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Довкола безпечні води; часто біля входу у фарватер';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Чорні й червоні смуги';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Невелика небезпека, довкола безпечні води: тримайтеся осторонь';

  @override
  String get chartLegend_specialBuoy => 'Жовтий буй';

  @override
  String get chartLegend_specialBuoyHint =>
      'Спеціальний знак, не для навігації: якірна стоянка, кабель, дослідження';

  @override
  String get chartLegend_cardinalBuoy => 'Чорний і жовтий';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Кардинальний знак: проходьте з того боку, за яким він названий (у США рідко)';

  @override
  String get chartLegend_mooringBuoy => 'Швартовна бочка';

  @override
  String get chartLegend_portBeacon => 'Зелений квадратний знак';

  @override
  String get chartLegend_portBeaconHint =>
      'Як зелений буй: залишайте ліворуч, заходячи';

  @override
  String get chartLegend_starboardBeacon => 'Червоний трикутний знак';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Як червоний буй: залишайте праворуч, заходячи';

  @override
  String get chartLegend_otherBeacon => 'Ромбоподібний знак';

  @override
  String get chartLegend_otherBeaconHint =>
      'Інформація чи попередження, а не сторона фарватеру';

  @override
  String get chartLegend_beaconTower => 'Вежа маяка або споруда знака';

  @override
  String get chartLegend_topmark => 'Топова фігура';

  @override
  String get chartLegend_topmarkHint =>
      'Фігура на верхівці знака доповнює його значення';

  @override
  String get chartLegend_light => 'Вогонь';

  @override
  String get chartLegend_lightHint =>
      'Пурпуровий спалах позначає вогонь; підпис показує, як він блимає';

  @override
  String get chartLegend_lightExample =>
      'Зелений проблисковий, кожні 4 секунди';

  @override
  String get chartLegend_lightExampleHint =>
      'Підпис вогню: характер, колір, потім період';

  @override
  String get chartLegend_lightFixed => 'Постійний';

  @override
  String get chartLegend_lightFixedHint => 'Світить не блимаючи';

  @override
  String get chartLegend_lightFlashing => 'Проблисковий';

  @override
  String get chartLegend_lightFlashingHint =>
      'Короткі проблиски, темрява між ними довша';

  @override
  String get chartLegend_lightGroup => 'Групово-проблисковий';

  @override
  String get chartLegend_lightGroupHint =>
      'Проблиски групами, тут по 2, потім темрява';

  @override
  String get chartLegend_lightComposite => 'Складний групово-проблисковий';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 проблиски, потім 1: розгалуження фарватеру';

  @override
  String get chartLegend_lightQuick => 'Частий проблисковий';

  @override
  String get chartLegend_lightQuickHint => 'Приблизно один проблиск на секунду';

  @override
  String get chartLegend_lightIsophase => 'Ізофазний';

  @override
  String get chartLegend_lightIsophaseHint => 'Світло й темрява порівну';

  @override
  String get chartLegend_lightOcculting => 'Затемнювальний';

  @override
  String get chartLegend_lightOccultingHint => 'Світло довше за темряву';

  @override
  String get chartLegend_lightMorse => 'Азбука Морзе A';

  @override
  String get chartLegend_lightMorseHint => 'Короткий, довгий: безпечні води';

  @override
  String get chartLegend_lightAlternating => 'Змінний';

  @override
  String get chartLegend_lightAlternatingHint => 'Змінює колір';

  @override
  String get chartLegend_lightColours => 'Білий, червоний, зелений, жовтий';

  @override
  String get chartLegend_lightPeriod => 'Період';

  @override
  String get chartLegend_lightPeriodHint => 'Секунди на повний цикл';

  @override
  String get chartLegend_rock => 'Підводний камінь';

  @override
  String get chartLegend_rockHint =>
      'Завжди під водою, але може бути близько до поверхні';

  @override
  String get chartLegend_rockAwash => 'Камінь на рівні води';

  @override
  String get chartLegend_rockAwashHint =>
      'Біля самої поверхні під час відпливу';

  @override
  String get chartLegend_rockCovers => 'Камінь, що осихає';

  @override
  String get chartLegend_rockCoversHint =>
      'Видно під час відпливу, під водою під час припливу';

  @override
  String get chartLegend_wreckDangerous => 'Небезпечне затонуле судно';

  @override
  String get chartLegend_wreckDangerousHint => 'Досить мілко, щоб зачепити';

  @override
  String get chartLegend_wreck => 'Затонуле судно';

  @override
  String get chartLegend_wreckHint =>
      'Досить глибоко для надводних суден; не ставайте на якір';

  @override
  String get chartLegend_wreckShowing => 'Затонуле судно, видиме над водою';

  @override
  String get chartLegend_wreckShowingHint =>
      'Частина корпусу виступає над водою';

  @override
  String get chartLegend_obstruction => 'Перешкода';

  @override
  String get chartLegend_obstructionHint =>
      'Щось на дні; глибина над ним, якщо відома';

  @override
  String get chartLegend_foulGround => 'Засмічений ґрунт';

  @override
  String get chartLegend_foulGroundHint =>
      'Пройти можна, але не ставайте на якір і не тральте';

  @override
  String get chartLegend_hazardArea => 'Межа небезпечного району';

  @override
  String get chartLegend_hazardAreaHint =>
      'Усередині каміння, затонулі судна чи перешкоди';

  @override
  String get chartLegend_pile => 'Паля або стовп';

  @override
  String get chartLegend_floodStream => 'Припливна течія';

  @override
  String get chartLegend_floodStreamHint => 'Течія, поки вода прибуває';

  @override
  String get chartLegend_ebbStream => 'Відпливна течія';

  @override
  String get chartLegend_ebbStreamHint => 'Течія, поки вода спадає';

  @override
  String get chartLegend_current => 'Постійна течія';

  @override
  String get chartLegend_currentHint =>
      'Тече в один бік незалежно від припливу';

  @override
  String get chartLegend_rips => 'Сулої або вири';

  @override
  String get chartLegend_ripsHint => 'Бурхлива, закручена вода';

  @override
  String get chartLegend_breakers => 'Буруни';

  @override
  String get chartLegend_breakersHint => 'Хвилі розбиваються на мілині';

  @override
  String get chartLegend_sounding => 'Позначка глибини';

  @override
  String get chartLegend_soundingHint => 'Глибина за середньої малої води';

  @override
  String get chartLegend_depthContour => 'Ізобата';

  @override
  String get chartLegend_depthContourHint => 'Підпис показує глибину';

  @override
  String get chartLegend_drying => 'Осихає під час відпливу';

  @override
  String get chartLegend_dredged => 'Поглиблений канал';

  @override
  String get chartLegend_dredgedHint => 'Підтримується вказана глибина';

  @override
  String get chartLegend_swept => 'Протралений район';

  @override
  String get chartLegend_sweptHint =>
      'Перевірено, що чисто до вказаної глибини';

  @override
  String get chartLegend_unsurveyed => 'Не обстежено';

  @override
  String get chartLegend_unsurveyedHint => 'Глибини не виміряно';

  @override
  String get chartLegend_weed => 'Ламінарія або водорості';

  @override
  String get chartLegend_restricted => 'Район з обмеженнями';

  @override
  String get chartLegend_restrictedHint =>
      'Вхід обмежено; засічки спрямовані всередину';

  @override
  String get chartLegend_regulatedLimit => 'Межа регульованого району';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Якірна стоянка, кабельний район, район стрільб тощо: див. підпис';

  @override
  String get chartLegend_greyLimit =>
      'Звалище ґрунту, район промислу або ферма';

  @override
  String get chartLegend_anchorage => 'Якірна стоянка';

  @override
  String get chartLegend_anchorBerth => 'Якірне місце';

  @override
  String get chartLegend_noAnchoring => 'Якірна стоянка заборонена';

  @override
  String get chartLegend_caution => 'Район застереження';

  @override
  String get chartLegend_cautionHint => 'Будьте тут особливо уважні';

  @override
  String get chartLegend_trafficLane => 'Смуга руху';

  @override
  String get chartLegend_trafficLaneHint =>
      'Великі судна, рух в один бік: перетинайте під прямим кутом';

  @override
  String get chartLegend_separationZone => 'Зона розділення';

  @override
  String get chartLegend_separationZoneHint => 'Між смугами руху: не заходьте';

  @override
  String get chartLegend_precautionary => 'Район, де потрібна обережність';

  @override
  String get chartLegend_precautionaryHint =>
      'Тут сходяться судна: будьте обережні';

  @override
  String get chartLegend_fairway => 'Фарватер';

  @override
  String get chartLegend_fairwayHint => 'Головний судновий хід';

  @override
  String get chartLegend_track => 'Рекомендований шлях';

  @override
  String get chartLegend_ferry => 'Поромна лінія';

  @override
  String get chartLegend_leadingLine => 'Створна лінія';

  @override
  String get chartLegend_leadingLineHint =>
      'Сумістіть два створні знаки, щоб триматися фарватеру';

  @override
  String get chartLegend_cable => 'Підводний кабель';

  @override
  String get chartLegend_cableHint => 'Не ставайте на якір';

  @override
  String get chartLegend_pipeline => 'Підводний трубопровід';

  @override
  String get chartLegend_pipelineHint => 'Не ставайте на якір';

  @override
  String get chartLegend_overhead => 'Повітряний кабель';

  @override
  String get chartLegend_overheadHint =>
      'Висоту проходу під ним підписано як VC';

  @override
  String get chartLegend_tower => 'Вежа';

  @override
  String get chartLegend_windTurbine => 'Вітрогенератор';

  @override
  String get chartLegend_chimney => 'Димова труба';

  @override
  String get chartLegend_mast => 'Щогла або антена';

  @override
  String get chartLegend_church => 'Церква або шпиль';

  @override
  String get chartLegend_flagstaff => 'Флагшток';

  @override
  String get chartLegend_dome => 'Купол';

  @override
  String get chartLegend_landmark => 'Інший орієнтир';

  @override
  String get chartLegend_abbrAnch => 'Якірна стоянка';

  @override
  String get chartLegend_abbrWk => 'Затонуле судно';

  @override
  String get chartLegend_abbrBr => 'Буруни';

  @override
  String get chartLegend_abbrWd => 'Водорості';

  @override
  String get chartLegend_abbrVar => 'Магнітне схилення';

  @override
  String get chartLegend_abbrVc => 'Висота проходу під мостом чи кабелем';

  @override
  String get chartLegend_abbrTr => 'Вежа';

  @override
  String get chartLegend_abbrCh => 'Церква';

  @override
  String get chartLegend_abbrChy => 'Димова труба';

  @override
  String get chartLegend_abbrFs => 'Флагшток';

  @override
  String get chartLegend_abbrTk => 'Резервуар';

  @override
  String get chartLegend_abbrRBn => 'Радіомаяк';

  @override
  String get chartLegend_abbrCg => 'Станція берегової охорони';

  @override
  String get chartLegend_abbrRacon =>
      'Радіолокаційний маяк-відповідач: видно на радарі';

  @override
  String get chartLegend_abbrFog =>
      'Туманний сигнал: ревун, дзвін, гонг, свисток чи сирена';

  @override
  String get chartLegend_abbrVAis => 'Віртуальний знак: видно лише в AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'від $from до $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Глибше $depth';
  }

  @override
  String get parkLegend_title => 'Позначки парків і стежок';

  @override
  String get parkLegend_campsite => 'Кемпінг';

  @override
  String get parkLegend_picnicSite => 'Місце для пікніка';

  @override
  String get parkLegend_shelter => 'Укриття';

  @override
  String get parkLegend_toilets => 'Туалет';

  @override
  String get parkLegend_drinkingWater => 'Питна вода';

  @override
  String get parkLegend_parking => 'Парковка';

  @override
  String get parkLegend_viewpoint => 'Оглядовий майданчик';

  @override
  String get parkLegend_attraction => 'Пам\'ятка';

  @override
  String get parkLegend_gate => 'Ворота';

  @override
  String get parkLegend_telephone => 'Телефон';

  @override
  String get parkLegend_information => 'Інформаційний стенд';

  @override
  String get parkLegend_guidepost => 'Вказівник';

  @override
  String get dialog_noticeExpires => 'Термін дії';

  @override
  String get dialog_noticeNoExpiry => 'Безстроково';

  @override
  String get dialog_noticeExpiryRequired =>
      'Виберіть дату (у кімнаті обов\'язково)';

  @override
  String get dialog_noticeExpiryTime => 'Час';

  @override
  String get dialog_noticeEndOfDay => 'Кінець дня';

  @override
  String structured_until(String when) {
    return 'До $when';
  }

  @override
  String get structured_expired => 'Термін минув';

  @override
  String get structured_announcement => 'Оголошення';

  @override
  String structured_locationOf(String name) {
    return 'Розташування: $name';
  }

  @override
  String get reaction_searchHint => 'Пошук емодзі';

  @override
  String get reaction_noResults => 'Емодзі не знайдено';

  @override
  String get share_qrAndLink => 'Поділитися QR-кодом і посиланням';

  @override
  String get share_roomTitle => 'Поділитися кімнатою';

  @override
  String get share_contactTitle => 'Поділитися контактом';

  @override
  String get share_roomInstructions =>
      'Відскануйте QR-код, щоб додати цю кімнату. Для входу знадобиться її пароль.';

  @override
  String get share_contactInstructions =>
      'Відскануйте QR-код, щоб додати цей контакт.';

  @override
  String get clearChat_body =>
      'Видалити повідомлення цього чату з цього пристрою. Нові повідомлення й надалі надходитимуть сюди.';

  @override
  String get clearChat_olderThanDay => 'Старіші за 1 день';

  @override
  String get clearChat_olderThanWeek => 'Старіші за 1 тиждень';

  @override
  String get clearChat_olderThanMonth => 'Старіші за 1 місяць';

  @override
  String get clearChat_everything => 'Усі повідомлення';

  @override
  String get chats_markAllRead => 'Позначити всі як прочитані';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Позначити $count чатів як прочитані?',
      many: 'Позначити $count чатів як прочитані?',
      few: 'Позначити $count чати як прочитані?',
      one: 'Позначити $count чат як прочитаний?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Позначити';

  @override
  String get chats_nothingUnread => 'Немає непрочитаних повідомлень';

  @override
  String get chats_draft => 'Чернетка';

  @override
  String get contact_teleBlockedTitle => 'Заблоковано вашим радіо';

  @override
  String contact_teleBlockedBody(String name) {
    return 'Налаштування конфіденційності вашого радіо ні з ким цим не діляться, тож $name цього не отримає. Змінити їх, щоб це отримували контакти, яким ви дозволите?';
  }

  @override
  String get contact_teleNotNow => 'Не зараз';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'Ваше радіо ні з ким цим не ділиться ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'Ваше радіо ділиться цим з усіма ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Може отримати ваше розташування';

  @override
  String get pathfinder_meshTitle => 'Інша мережа?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '$unknown із $heard ретрансляторів, почутих після підключення, нові для карти Pathfinder «$graph». Почати нову карту для цієї місцевості? Стара залишиться, і до неї можна повернутися на екрані Pathfinder.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'Більшість ретрансляторів, почутих після підключення, є на карті Pathfinder «$other», а не «$graph». Перемкнутися на неї?';
  }

  @override
  String get pathfinder_meshNew => 'Нова карта';

  @override
  String get pathfinder_meshSwitch => 'Перемкнути';

  @override
  String get pathfinder_meshKeep => 'Залишити цю';

  @override
  String get pathfinder_graphNameTitle => 'Назва нової карти';

  @override
  String get pathfinder_graphNameHint => 'Наприклад, Вашингтон';

  @override
  String get pathfinder_graphCreate => 'Створити';

  @override
  String get locationSharing_title => 'Хто бачить моє розташування';

  @override
  String get locationSharing_someone => 'Хтось може бачити ваше розташування';

  @override
  String get locationSharing_nobody => 'Ніхто не бачить ваше розташування';

  @override
  String get locationSharing_noPosition =>
      'Ваше радіо ще не має розташування, тому його ніхто не бачить';

  @override
  String get locationSharing_everyone =>
      'Кожен, хто чує ваше радіо, бачить ваше розташування';

  @override
  String get locationSharing_allContacts =>
      'Усі ваші контакти бачать ваше розташування';

  @override
  String get locationSharing_someContacts =>
      'Контакти, яким ви дозволили, бачать ваше розташування';

  @override
  String get locationSharing_adverts => 'Розташування в анонсах';

  @override
  String get locationSharing_advertsHint =>
      'Ваші анонси містять ваше розташування, тому його бачить кожен, хто чує ваше радіо.';

  @override
  String get locationSharing_contactsHeader =>
      'Контакти, які можуть запитувати ваше радіо';

  @override
  String get locationSharing_noTelemetry =>
      'Ніхто. Ваше радіо не відповідає на запити телеметрії.';

  @override
  String get locationSharing_noContacts => 'Жодному контакту не дозволено.';

  @override
  String locationSharing_allContactsRow(int count) {
    return 'Усі ваші контакти ($count)';
  }

  @override
  String get locationSharing_partLocation => 'Розташування';

  @override
  String get locationSharing_partBattery => 'Батарея';

  @override
  String get locationSharing_partSensors => 'Датчики';

  @override
  String get locationSharing_hide => 'Приховати моє розташування від усіх';
}
