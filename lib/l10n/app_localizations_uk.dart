// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Ukrainian (`uk`).
class AppLocalizationsUk extends AppLocalizations {
  AppLocalizationsUk([String locale = 'uk']) : super(locale);

  @override
  String get tray_photo => 'Фото';

  @override
  String get photo_settingsTitle => 'Фото';

  @override
  String photo_enableHint(String size) {
    return 'Надсилання й перегляд фото через радіо. Потрібна модель для фото ($size) на цьому телефоні.';
  }

  @override
  String photo_sendTitle(String channel) {
    return 'Фото в $channel';
  }

  @override
  String get photo_squareIntro =>
      'Виберіть фото, потім — квадрат для надсилання.';

  @override
  String get photo_takePhoto => 'Зробити фото';

  @override
  String get photo_choosePhoto => 'Вибрати фото';

  @override
  String get photo_chooseAnother => 'Вибрати інше фото';

  @override
  String get photo_cropHint =>
      'Пересувайте й масштабуйте, доки головне не заповнить квадрат.';

  @override
  String get photo_preview => 'Попередній перегляд';

  @override
  String get photo_changeCrop => 'Змінити обрізку';

  @override
  String get photo_checkingAndCoding => 'Перевірка й кодування фото…';

  @override
  String get photo_modelMissing =>
      'Моделі для фото немає на цьому пристрої. Щоб завантажити її, увімкніть «Фото» в розділі «Налаштування програми» → «Обмін повідомленнями».';

  @override
  String get photo_previewNoMemory =>
      'Тут не вистачає пам\'яті, щоб показати, що побачать інші. Надіслати фото все одно можна.';

  @override
  String get photo_rebuildingPreview =>
      'Відновлюємо те, що побачать інші… близько 20 секунд';

  @override
  String photo_prepareFailed(String error) {
    return 'Не вдалося підготувати фото: $error';
  }

  @override
  String get photo_flaggedNotSent =>
      'Це фото не можна надіслати: його не пропустила перевірка безпеки.';

  @override
  String get photo_tagTitle => 'Тег (необов\'язково)';

  @override
  String get photo_blurFaces => 'Розмити обличчя';

  @override
  String photo_facesBlurred(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count обличчя розмито',
      many: '$count облич розмито',
      few: '$count обличчя розмито',
      one: '$count обличчя розмито',
    );
    return '$_temp0';
  }

  @override
  String photo_facesDarkened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count обличчя закрито сірим: з розмиттям фото не пройшло перевірку безпеки',
      many:
          '$count облич закрито сірим: з розмиттям фото не пройшло перевірку безпеки',
      few:
          '$count обличчя закрито сірим: з розмиттям фото не пройшло перевірку безпеки',
      one:
          '$count обличчя закрито сірим: з розмиттям фото не пройшло перевірку безпеки',
    );
    return '$_temp0';
  }

  @override
  String get photo_includePosition => 'Додати розташування';

  @override
  String get photo_noPosition => 'Ваше радіо не має розташування';

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
    return '$position, точність близько $distance';
  }

  @override
  String get photo_zeroHop => 'Без ретрансляції';

  @override
  String get photo_subjectOnly => 'Лише об\'єкт';

  @override
  String get photo_autoCrop => 'Автообрізка';

  @override
  String get photo_tapWhatMatters =>
      'Торкніться головного. Торкайтеся інших предметів, щоб додати їх.';

  @override
  String get photo_outlining => 'Виділення контуру…';

  @override
  String get photo_clearTaps => 'Очистити';

  @override
  String get photo_nothingThere =>
      'Там нічого виділити. Торкніться середини предмета.';

  @override
  String get photo_zeroHopNearbyOnly =>
      'Для цього каналу вибрано «Лише поблизу»';

  @override
  String get photo_repairPacket => 'Пакет для відновлення';

  @override
  String photo_sendFigures(int packets, String sendTime) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: '$packets пакета',
      many: '$packets пакетів',
      few: '$packets пакети',
      one: '$packets пакет',
    );
    return '$_temp0 · надсилання триватиме близько $sendTime';
  }

  @override
  String photo_seconds(String seconds) {
    return '$seconds с';
  }

  @override
  String photo_blockedWaitRepeaters(int packets, int gap, int minutes) {
    return 'На частотах MeshCore радіо надсилає через ретранслятори одне фото раз на $gap хв. Наступне через ретранслятори можна надіслати через $minutes хв, а без ретрансляції — вже зараз.';
  }

  @override
  String get photo_send => 'Надіслати';

  @override
  String get photo_sending => 'Надсилання…';

  @override
  String photo_sendingPacket(int sent, int total) {
    return 'Пакет $sent з $total';
  }

  @override
  String photo_sendingRepairPacket(int sent, int total) {
    return 'Пакет $sent з $total (для відновлення)';
  }

  @override
  String photo_sendingPacketAgain(int sent, int total) {
    return 'Пакет $sent з $total повторно';
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
  String get photo_waitingToSend => 'Waiting to send';

  @override
  String photo_passedOnSome(int heard, int total) {
    return 'Надіслано · ретранслятори передали далі пакетів: $heard з $total';
  }

  @override
  String photo_notSent(String error) {
    return 'Не надіслано: $error';
  }

  @override
  String get photo_errorNotConnected => 'немає з\'єднання з радіо';

  @override
  String get photo_errorNoAnswer => 'радіо не відповіло';

  @override
  String photo_errorRefused(int code) {
    return 'радіо відхилило пакет (помилка $code)';
  }

  @override
  String get photo_confirmTitle => 'Надіслати фото';

  @override
  String photo_openChannelTitle(String channel) {
    return 'Фото в $channel';
  }

  @override
  String get photo_openChannelNotEveryone =>
      'Більшість тут його не побачить: фото показує лише MeshTrax.';

  @override
  String photo_openChannelAirtime(String airtime, int messages) {
    String _temp0 = intl.Intl.pluralLogic(
      messages,
      locale: localeName,
      other: '$messages текстового повідомлення',
      many: '$messages текстових повідомлень',
      few: '$messages текстові повідомлення',
      one: '$messages текстове повідомлення',
    );
    return 'Це фото займає в ефірі $airtime — стільки ж, скільки $_temp0.';
  }

  @override
  String get photo_openChannelRepeaters =>
      'Кожен ретранслятор, що передає його далі, знову надсилає його повністю — на частоті, спільній для всіх навколо вас.';

  @override
  String get photo_openChannelBetter =>
      'Краще: без ретрансляції, коли люди поруч, або приватний канал із тими, хто хоче отримувати фото. Обрізайте щільніше: що простіше зображення, то менше пакетів.';

  @override
  String get photo_dontShowAgain => 'Більше не показувати';

  @override
  String photo_confirmAirtime(int packets, String airtime, int messages) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: '$packets пакета',
      many: '$packets пакетів',
      few: '$packets пакети',
      one: '$packets пакет',
    );
    String _temp1 = intl.Intl.pluralLogic(
      messages,
      locale: localeName,
      other: '$messages текстового повідомлення',
      many: '$messages текстових повідомлень',
      few: '$messages текстові повідомлення',
      one: '$messages текстове повідомлення',
    );
    return '$_temp0, $airtime в ефірі: стільки ж, скільки $_temp1.';
  }

  @override
  String photo_confirmOpenChannel(String channel) {
    return 'Його побачить будь-хто в $channel, хто користується MeshTrax. Інші застосунки фото не показують.';
  }

  @override
  String get photo_confirmFlood =>
      'Кожен ретранслятор, який його почує, надішле його знову.';

  @override
  String get photo_confirmZeroHop =>
      'Без ретрансляції: його отримають лише радіо в прямій досяжності.';

  @override
  String get photo_label => 'Відновлено ШІ';

  @override
  String get photo_tapToView => 'Торкніться, щоб переглянути';

  @override
  String get photo_enhance => 'Покращити 4×';

  @override
  String get photo_enhancing => 'Покращення…';

  @override
  String get photo_save => 'Зберегти';

  @override
  String get photo_saved => 'Збережено у ваших фото';

  @override
  String get photo_saveFailed => 'Не вдалося зберегти фото.';

  @override
  String get photo_details => 'Про це фото';

  @override
  String photo_caption(int bytes) {
    return 'Відновлено ШІ-моделлю з $bytes байт. Дрібні деталі згенеровано, а не передано: знаки й написи не доходять. Це не свідчення того, що там було.';
  }

  @override
  String get photo_enlargedNote =>
      'Покращено 4× на цьому телефоні: дрібні деталі можуть бути вигадані.';

  @override
  String get photo_enlargeNoMemory =>
      'Зараз не вистачає вільної пам\'яті, щоб збільшити фото. Закрийте інші програми й спробуйте ще раз.';

  @override
  String get photo_enlargeFlagged =>
      'Збільшене зображення не пройшло перевірку безпеки, тому його не показано.';

  @override
  String get photo_enlargeFailed => 'Не вдалося збільшити фото.';

  @override
  String get photo_enlargeAutomatically => 'Автоматично збільшувати фото';

  @override
  String get photo_enlargeAutomaticallyHint =>
      'Вимк.: щоб збільшити фото 4×, торкніться його на весь екран. Увімк.: воно збільшується під час відкриття.';

  @override
  String get photo_ignoreTimeLimits => 'Ігнорувати часові обмеження для фото';

  @override
  String get photo_ignoreTimeLimitsHint =>
      'Для тестування: надсилати фото через ретранслятори без очікування між ними.';

  @override
  String get photo_rebuilding => 'Відновлення… близько 20 с';

  @override
  String get photo_hiddenFlagged =>
      'Зображення приховано: позначено як неприйнятне';

  @override
  String get photo_hiddenReported => 'Фото приховано: ви поскаржилися на нього';

  @override
  String get photo_noMemory =>
      'Зараз не вистачає пам\'яті, щоб відновити це фото. Закрийте інші програми або перезапустіть MeshTrax, потім спробуйте ще раз.';

  @override
  String get photo_rebuildFailed => 'Не вдалося відновити це фото.';

  @override
  String get photo_report => 'Поскаржитися';

  @override
  String photo_block(String name) {
    return 'Заблокувати $name';
  }

  @override
  String photo_blockedSender(String name) {
    return 'Заблоковано: $name';
  }

  @override
  String get photo_reportTitle => 'Поскаржитися на це фото';

  @override
  String get photo_reportBody =>
      'Фото одразу й назавжди приховується на цьому телефоні, а скарга надходить розробнику MeshTrax із застосунку — зараз або коли з\'явиться інтернет. Більше нічого з вашого телефону не надсилається.';

  @override
  String get photo_reportInclude => 'Додати фото';

  @override
  String get photo_reportIncludeHint =>
      'Його код — кілька сотень байт, з яких фото можна відновити. Не саме зображення.';

  @override
  String get photo_reportReason => 'Що не так? (необов\'язково)';

  @override
  String get photo_reportedSent => 'Фото приховано, скаргу надіслано. Дякуємо.';

  @override
  String get photo_reportedQueued =>
      'Фото приховано. Скаргу буде надіслано, коли з\'явиться інтернет.';

  @override
  String photo_reportPending(String name) {
    return 'Скарга на фото: $name';
  }

  @override
  String get photo_reportPendingHint => 'Чекає на інтернет, щоб надіслати';

  @override
  String get photo_reportStillWaiting =>
      'Інтернету досі немає. Скаргу буде надіслано пізніше.';

  @override
  String get photo_autoRebuild => 'Автоматично відновлювати отримані фото';

  @override
  String get photo_autoRebuildHint =>
      'Вимк.: торкніться фото, щоб відновити його. Увімк.: кожне фото відновлюється, щойно надходить, поки MeshTrax відкритий і телефону вистачає пам\'яті.';

  @override
  String get photo_modelTitle => 'Модель для фото';

  @override
  String photo_modelProgress(String done, String total) {
    return '$done з $total';
  }

  @override
  String get photo_modelChecking => 'Перевірка завантаження…';

  @override
  String get photo_modelRetrying => 'Повторна спроба…';

  @override
  String get photo_modelPaused => 'Призупинено';

  @override
  String get photo_modelWaitingWifi =>
      'Очікування: завантаження чекають на Wi‑Fi';

  @override
  String get photo_modelWaiting => 'Очікування…';

  @override
  String photo_modelInstalled(String size) {
    return 'На цьому пристрої ($size)';
  }

  @override
  String photo_modelFailed(String error) {
    return 'Помилка завантаження: $error';
  }

  @override
  String get photo_modelNoReason => 'причину не вказано';

  @override
  String photo_modelNeeded(String size) {
    return 'Потрібна, щоб надсилати й відновлювати фото: $size';
  }

  @override
  String get photo_keepOpen =>
      'Не закривайте MeshTrax, доки завантаження не завершиться. Прогрес також видно в розділі «Офлайн-карти».';

  @override
  String photo_licencesLink(String poweredBy) {
    return '$poweredBy · Ліцензії';
  }

  @override
  String get photo_cancelDownload => 'Скасувати завантаження';

  @override
  String get photo_downloadModel => 'Завантажити модель для фото';

  @override
  String get photo_tryAgain => 'Спробувати ще раз';

  @override
  String get photo_deleteModel => 'Видалити модель для фото';

  @override
  String get photo_downloadLicences => 'Завантажити тексти ліцензій';

  @override
  String get photo_deleteModelTitle => 'Видалити модель для фото?';

  @override
  String photo_deleteModelBody(String size) {
    return 'Доки модель не буде завантажено знову ($size), фото не можна буде надсилати й відновлювати.';
  }

  @override
  String get photo_keep => 'Залишити';

  @override
  String photo_notEnoughSpace(String needed, String free) {
    return 'Не вистачає місця: моделі для фото потрібно $needed вільного місця, а на цьому пристрої вільно $free.';
  }

  @override
  String photo_downloadName(int index, int count) {
    return 'Модель для фото ($index з $count)';
  }

  @override
  String photo_downloadLicenceName(int index, int count) {
    return 'Ліцензія моделі для фото ($index з $count)';
  }

  @override
  String get photo_licencesTitle => 'Ліцензії моделі для фото';

  @override
  String get photo_licencesIntro =>
      'Модель, що відновлює фото, побудована на SD-Turbo від Stability AI, з кодеком зображень AEIC і декодером AdcSR; перевірка безпеки використовує класифікатор зображень на основі SwiftFormer. Тут — повідомлення й ліцензії, що до них додаються.';

  @override
  String get photo_licencesMissing =>
      'Тексти ліцензій завантажуються разом із моделлю для фото.';

  @override
  String photo_message(String id) {
    return '📷 Фото $id';
  }

  @override
  String photo_messageWithTag(String id, String tag) {
    return '📷 Фото $id · $tag';
  }

  @override
  String photo_incomplete(String id, int got, int total) {
    return '📷 Фото $id неповне: $got з $total пакетів';
  }

  @override
  String photo_unreadable(String id) {
    return '📷 Фото $id не вдалося прочитати';
  }

  @override
  String photo_needsNewer(String id) {
    return '📷 Для фото $id потрібна новіша версія MeshTrax';
  }

  @override
  String photo_unknownSender(String id) {
    return 'Вузол $id';
  }

  @override
  String get photo_chatPhoto => '📷 Фото';

  @override
  String get photo_cameraDenied =>
      'MeshTrax не може використовувати камеру. Дозволити доступ можна в налаштуваннях телефону.';

  @override
  String photo_pickFailed(String error) {
    return 'Немає фото: $error';
  }

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
  String get common_experimental => 'ЕКСПЕРИМЕНТ';

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
  String get healthCheck_title => 'Перевірка стану';

  @override
  String get healthCheck_subtitle =>
      'Перевірити налаштування програми та радіо';

  @override
  String get healthCheck_running => 'Перевірка налаштувань…';

  @override
  String get healthCheck_waitingForSync =>
      'Радіо ще синхронізується. Перевірка почнеться, коли синхронізація завершиться.';

  @override
  String get healthCheck_noRadio =>
      'Радіо не підключено, тому його налаштування не перевірялися.';

  @override
  String get healthCheck_partial =>
      'Не вдалося прочитати деякі налаштування радіо, тому результати можуть бути неактуальними. Перевірте ще раз трохи згодом.';

  @override
  String get healthCheck_allClear => 'Усе добре.';

  @override
  String get healthCheck_problems => 'Проблеми';

  @override
  String get healthCheck_suggestions => 'Рекомендації';

  @override
  String get healthCheck_tips => 'Поради';

  @override
  String healthCheck_passed(int count) {
    return 'Пройдено перевірок: $count';
  }

  @override
  String get healthCheck_runAgain => 'Перевірити знову';

  @override
  String get healthCheck_fix => 'Виправити';

  @override
  String get healthCheck_fixFailed =>
      'Зміну не застосовано. Перевірте підключення до радіо та спробуйте ще раз.';

  @override
  String get healthCheck_openFailed =>
      'Не вдалося відкрити цю сторінку налаштувань. Змініть це в налаштуваннях пристрою.';

  @override
  String get healthCheck_hide => 'Більше не показувати';

  @override
  String healthCheck_showHidden(int count) {
    return 'Показати приховані результати: $count';
  }

  @override
  String healthCheck_fixAll(int count) {
    return 'Виправити все ($count)';
  }

  @override
  String get healthCheck_fixAllConfirm => 'Внести ці зміни?';

  @override
  String get healthCheck_promptTitle => 'Запустити перевірку стану?';

  @override
  String get healthCheck_promptBody =>
      'Дізнайтеся, що можна покращити в налаштуваннях програми та радіо, зокрема як отримувати менше сповіщень.';

  @override
  String get healthCheck_promptBodyDesktop =>
      'Дізнайтеся, що можна покращити в налаштуваннях програми та радіо.';

  @override
  String get healthCheck_promptRun => 'Запустити';

  @override
  String get healthCheck_promptLater => 'Не зараз';

  @override
  String get settings_title => 'Налаштування';

  @override
  String get trax_title => 'Режим TRAX';

  @override
  String get trax_isOn => 'Режим TRAX увімкнено';

  @override
  String get trax_isOff => 'Режим TRAX вимкнено';

  @override
  String get trax_intro =>
      'Переводить радіо на частоту групи. Звичайна мережа mesh вас не чує, доки не вийдете з TRAX.';

  @override
  String get trax_now => 'Зараз';

  @override
  String get trax_inTrax => 'У режимі TRAX';

  @override
  String get trax_repeatOn => '«Автономна система» увімкнено';

  @override
  String get trax_savedNote => '«Вийти з TRAX» повертає налаштування.';

  @override
  String trax_until(String time) {
    return 'До $time';
  }

  @override
  String get trax_noEnd => 'Вкажіть кінець поїздки в налаштуваннях TRAX.';

  @override
  String get trax_tellsNot => 'Не повідомляє групу.';

  @override
  String get trax_noChannel =>
      'Виберіть канал поїздки в налаштуваннях TRAX або вимкніть «Повідомити групу».';

  @override
  String get trax_trailhead =>
      'Перемикайтеся на початку маршруту, коли радіо має GPS-позицію.';

  @override
  String get trax_settings => 'Налаштування TRAX';

  @override
  String get trax_switch => 'Перейти на TRAX';

  @override
  String trax_heard(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Чути на TRAX ($count): $names',
      zero: 'На TRAX поки нікого не чути',
    );
    return '$_temp0';
  }

  @override
  String get trax_checkAgain => 'Перевірити знову';

  @override
  String get trax_noSaved =>
      'На цьому телефоні немає збережених налаштувань: «Вийти з TRAX» спитає, до якого пресету повернутися.';

  @override
  String get trax_leave => 'Вийти з TRAX';

  @override
  String get trax_unsupported =>
      'Прошивка цього радіо не вміє ретранслювати для інших. Оновіть її, щоб користуватися режимом TRAX.';

  @override
  String get trax_stepTelling => 'Повідомляємо групу…';

  @override
  String get trax_stepSwitching => 'Перемикаємо…';

  @override
  String get trax_stepChecking => 'Надсилаємо перевірку групи…';

  @override
  String get trax_stepLeaving => 'Виходимо…';

  @override
  String get trax_errorBusy => 'Радіо ще зайняте. Спробуйте трохи згодом.';

  @override
  String get trax_errorRefused =>
      'Радіо не прийняло налаштування. Нічого не змінилося.';

  @override
  String trax_errorNotAllowed(String mhz) {
    return 'Це радіо не може ретранслювати на $mhz МГц.';
  }

  @override
  String get trax_unconfirmed =>
      'Повідомлення TRAX не підтверджено. Повідомте групу інакше.';

  @override
  String get trax_preset => 'Пресет';

  @override
  String get trax_presetMesh => 'Як у мережі mesh';

  @override
  String get trax_presetLongRange => 'Далекий';

  @override
  String get trax_presetLongRangeHint =>
      'Сягає трохи далі; повідомлення йдуть ~3× довше.';

  @override
  String get trax_tripChannel => 'Канал поїздки';

  @override
  String get trax_tripChannelHint => 'Лише приватні канали';

  @override
  String get trax_none => 'Немає';

  @override
  String get trax_tripEnds => 'Кінець поїздки';

  @override
  String get trax_notSet => 'Не задано';

  @override
  String get trax_tellGroup => 'Повідомити групу';

  @override
  String get trax_tellGroupHint =>
      'Публікує повідомлення в каналі поїздки; інші приєднуються одним дотиком.';

  @override
  String get trax_keepTrack => 'Зберігати мій трек';

  @override
  String get trax_keepTrackHint =>
      'Наскільки далеко в минуле сягає ваша лінія — для вас і учасників поїздки. Старіші частини видаляються на всіх телефонах.';

  @override
  String trax_keepTrackHours(int hours) {
    return '$hours год';
  }

  @override
  String get trax_keepTrackWeek => '1 тиждень';

  @override
  String get trax_icon => 'Ваш значок';

  @override
  String get trax_iconHint => 'Як вас бачать на карті учасники поїздки.';

  @override
  String get trax_iconHike => 'Пішки';

  @override
  String get trax_iconVehicle => 'Автомобіль';

  @override
  String get trax_iconBoat => 'Човен';

  @override
  String get trax_iconMotorcycle => 'Мотоцикл';

  @override
  String get trax_iconBicycle => 'Велосипед';

  @override
  String get trax_iconAircraft => 'Літак';

  @override
  String get trax_iconCamp => 'Табір';

  @override
  String trax_followBody(String name, String time) {
    return '$name перейшов у режим TRAX до $time. Теж перейти?';
  }

  @override
  String trax_followDetail(String settings) {
    return 'Переводить радіо на $settings. Звичайна мережа mesh вас не чує, доки не вийдете з TRAX.';
  }

  @override
  String get trax_switchToo => 'Теж перейти';

  @override
  String get trax_notNow => 'Не зараз';

  @override
  String trax_leaveBody(String name) {
    return '$name виходить з режиму TRAX. Теж вийти?';
  }

  @override
  String get trax_leaveToo => 'Теж вийти';

  @override
  String get trax_stillOn => 'Досі в режимі TRAX. Вийти?';

  @override
  String get trax_pickPreset => 'До якого пресету повернутися?';

  @override
  String get trax_pickPresetHint =>
      'На цьому телефоні немає збережених налаштувань цього радіо: його перемкнув інший телефон.';

  @override
  String trax_cardOn(String name) {
    return '$name перейшов у режим TRAX';
  }

  @override
  String trax_cardOff(String name) {
    return '$name виходить з режиму TRAX';
  }

  @override
  String get trax_cardYouOn => 'Ви перейшли в режим TRAX';

  @override
  String get trax_cardYouOff => 'Ви вийшли з режиму TRAX';

  @override
  String get trax_youreOn => 'Ви на TRAX';

  @override
  String get trax_ended => 'Завершено';

  @override
  String get trax_notificationText =>
      'Звичайна мережа mesh вас не чує. Відкрийте MeshTrax, щоб вийти.';

  @override
  String get trax_endedTitle => 'Ваша поїздка закінчилася';

  @override
  String get trax_endedText =>
      'Досі в режимі TRAX: звичайна мережа mesh вас не чує.';

  @override
  String get trip_members => 'Учасники поїздки';

  @override
  String get trip_pickChannel =>
      'Виберіть канал поїздки: кожен, хто пише в ньому, — учасник.';

  @override
  String get trip_noPosts => 'У каналі поїздки ще ніхто не писав.';

  @override
  String get trip_notContact => 'Немає в контактах цього радіо';

  @override
  String get trip_canAsk => 'Може запитати ваше радіо';

  @override
  String get trip_addMember => 'Додати учасника';

  @override
  String get trip_askMyRadio => 'Учасники можуть запитувати моє радіо';

  @override
  String get trip_askMyRadioHint =>
      'Де воно і його батарея. Вмикає GPS. Припиняється, коли ви виходите з TRAX після поїздки.';

  @override
  String trip_shareOff(String setting) {
    return '«$setting» вимкнено: учасники не можуть запитувати.';
  }

  @override
  String get trip_advertsHint =>
      'У режимі TRAX. Його може прочитати будь-хто в зоні приймання.';

  @override
  String get trip_sosTitle => 'Щоб SOS звучав навіть у режимі «Не турбувати»?';

  @override
  String trip_onTrax(int on, int total) {
    return '$on з $total на TRAX';
  }

  @override
  String trip_notHeardYet(String name) {
    return '$name: ще не чути';
  }

  @override
  String trip_asking(String name) {
    return '$name: запит до радіо…';
  }

  @override
  String trip_noAnswer(String name) {
    return '$name: немає відповіді';
  }

  @override
  String trax_sendingEvery(String minutes) {
    return 'Ваше розташування надсилається учасникам поїздки кожні $minutes хв.';
  }

  @override
  String get trax_noChannelData =>
      'Прошивка цього радіо не може надсилати ваше розташування учасникам поїздки. Оновіть її.';

  @override
  String get trax_locationsNoChannel =>
      'Виберіть канал поїздки в налаштуваннях TRAX, щоб ділитися розташуванням.';

  @override
  String trax_memberNoLocation(String name) {
    return '$name: розташування ще немає';
  }

  @override
  String trax_updateToSee(String name) {
    return 'Update MeshTrax to see $name';
  }

  @override
  String get trax_updateToSeeSomeone =>
      'Update MeshTrax to see someone on this trip';

  @override
  String get trax_mayBeOld => 'може бути застарілим';

  @override
  String get trax_askTrack => 'Запитати трек';

  @override
  String trax_trackAsked(String time) {
    return 'Трек запитано о $time';
  }

  @override
  String get trax_group => 'Група TRAX';

  @override
  String get trax_tripChannelLocation =>
      'У режимі TRAX ваше розташування надсилається в цей канал.';

  @override
  String get map_lastHeard => 'Востаннє чутно';

  @override
  String get map_fromYou => 'Від вас';

  @override
  String get map_heading => 'Курс';

  @override
  String get map_speed => 'Швидкість';

  @override
  String get map_notMoving => 'Не рухається';

  @override
  String map_notMovingSince(String time, int minutes) {
    return 'з $time ($minutes хв)';
  }

  @override
  String map_stoppedFor(int minutes) {
    return 'Не рухається $minutes хв';
  }

  @override
  String get map_elevation => 'Висота';

  @override
  String get map_radioBattery => 'Батарея радіо';

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
  String get settings_traxSettingsSubtitle =>
      'Автономний пресет, канал і кінець поїздки';

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
  String get settings_reportBug => 'Повідомити про помилку';

  @override
  String get settings_reportBugSubtitle =>
      'Відкриває звіт про помилку на GitHub';

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
      'Markdown у повідомленнях: **жирний**, *курсив*, ||спойлери||, заголовки, списки й посилання. Інші програми MeshCore показують символи як є.';

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
  String get appSettings_maxDirectMessageTries =>
      'Макс. спроб для особистих повідомлень';

  @override
  String get appSettings_maxDirectMessageTriesSubtitle =>
      'Кількість спроб надсилання, після яких особисте повідомлення чи допис у кімнаті вважається недоставленим. Перші спроби йдуть відомими маршрутами, решта — на всю мережу.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Макс. повторів повідомлень у каналі';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Стільки разів повторюватиме надсилання, доки не почує хоча б один повтор';

  @override
  String get appSettings_heardCheck => 'Перевіряти надсилання у спостерігачів';

  @override
  String get appSettings_heardCheckSubtitle =>
      'Перед повторним надсиланням повідомлення в канал запитати сервер спостерігачів, чи його почули';

  @override
  String get appSettings_heardServer => 'Сервер спостерігачів';

  @override
  String get appSettings_heardServerNotSet => 'Не задано';

  @override
  String get appSettings_heardServerAbout =>
      'Спостерігачі — це радіостанції, які повідомляють серверу, що вони чують. MeshTrax надсилає цьому серверу відбиток кожного вашого повідомлення в каналі, але ніколи не його текст. Сервер бачить вашу інтернет-адресу та час надсилання.';

  @override
  String get appSettings_heardServerOther => 'Інша адреса';

  @override
  String get appSettings_heardServerAddress => 'Адреса сервера';

  @override
  String get appSettings_heardServerChecking => 'Перевірка сервера…';

  @override
  String get appSettings_heardServerNoAnswer => 'Немає відповіді з цієї адреси';

  @override
  String get appSettings_heardServerSaveAnyway => 'Усе одно зберегти';

  @override
  String get appSettings_heardServerAnswered => 'Сервер відповів';

  @override
  String chat_heardBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Почули $count спостерігача',
      many: 'Почули $count спостерігачів',
      few: 'Почули $count спостерігачі',
      one: 'Почув $count спостерігач',
    );
    return '$_temp0';
  }

  @override
  String get chat_heardDirect => 'напряму';

  @override
  String chat_heardVia(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'через $count ретранслятора',
      many: 'через $count ретрансляторів',
      few: 'через $count ретранслятори',
      one: 'через $count ретранслятор',
    );
    return '$_temp0';
  }

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
  String radioAsk_title(String name) {
    return 'Запитати радіо $name';
  }

  @override
  String get radioAsk_menuSubtitle => 'Працює й з вимкненим телефоном';

  @override
  String get radioAsk_waiting => 'Очікування іншого запиту';

  @override
  String radioAsk_asking(int attempt, int count) {
    return 'Запит… $attempt/$count';
  }

  @override
  String radioAsk_checkingAgain(int attempt, int count) {
    return 'Повторна перевірка… $attempt/$count';
  }

  @override
  String radioAsk_checkAgainAt(String time) {
    return 'Повторна перевірка о $time';
  }

  @override
  String radioAsk_where(String name, String time) {
    return 'Радіо $name · $time';
  }

  @override
  String radioAsk_volts(String volts) {
    return '$volts В';
  }

  @override
  String get radioAsk_noPosition => 'Немає GPS-позиції';

  @override
  String get radioAsk_noFix => 'Може бути застарілою: немає GPS-фіксації';

  @override
  String get radioAsk_unchanged => 'Може бути застарілою: без змін за 1 хв';

  @override
  String get radioAsk_notChecked => 'Другий запит не вдався';

  @override
  String get radioAsk_noAnswer => 'Немає відповіді';

  @override
  String get radioAsk_showOnMap => 'Показати на мапі';

  @override
  String get radioAsk_askAgain => 'Запитати знову';

  @override
  String get radioAsk_trackAsked =>
      'Також запитано трек з їхнього телефону; він з\'явиться на карті.';

  @override
  String radioAsk_mapLabel(String name, String time) {
    return 'Радіо $name · $time';
  }

  @override
  String get contact_nickname => 'Прізвисько';

  @override
  String get contact_fullName => 'Повне ім’я';

  @override
  String get contact_note => 'Нотатка';

  @override
  String get contact_nameAndNoteHint =>
      'Зберігається на цьому пристрої та в резервних копіях радіо. Ніколи не надсилається.';

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
      'Відскануйте QR-код, щоб додати канал.';

  @override
  String get channels_secretKey => 'Секретний ключ';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

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
    return 'Видалити $name і всі його повідомлення? Це не можна скасувати.';
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
  String get channels_generateRandomPsk => 'Згенерувати випадковий ключ PSK';

  @override
  String get channels_addChannelConfirmation => 'Додати цей канал?';

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
  String get channels_joinPublicChannel => 'Приєднатися до публічного каналу';

  @override
  String get channels_joinPublicChannelDesc =>
      'Будь-хто може приєднатися до цього каналу.';

  @override
  String get channels_scanQrCode => 'Сканувати QR-код';

  @override
  String get channels_scanQrCodeComingSoon => 'Скоро буде';

  @override
  String get channels_keepCapitals => 'Зберегти великі літери';

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
  String get chat_selectText => 'Виділити текст';

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
  String get map_noNodesWithLocation =>
      'Немає вузлів з даними про розташування';

  @override
  String get map_nodesNeedGps => 'На карті видно лише вузли, що діляться GPS';

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
  String get map_lastKnown => 'Останнє відоме';

  @override
  String map_lastKnownAt(String time) {
    return 'Останнє відоме · $time';
  }

  @override
  String get route_fromLastKnown =>
      'Від вашого останнього відомого місцезнаходження, може бути застарілим';

  @override
  String route_fromLastKnownAt(String time) {
    return 'Від вашого останнього відомого місцезнаходження ($time), може бути застарілим';
  }

  @override
  String route_fromWhereYouWere(String time) {
    return 'Від місця, де ви були о $time';
  }

  @override
  String route_startsOffPath(String distance) {
    return 'Починається за $distance від точки старту, поза нанесеними на мапу шляхами';
  }

  @override
  String get route_conditionsCaveat =>
      'MeshTrax не знає про перекриття, розмиви чи дороги, де потрібен повний привід. Перед виїздом перевірте поточну ситуацію.';

  @override
  String route_dataDate(String date) {
    return 'Дані мапи від $date';
  }

  @override
  String get gps_lastKnown =>
      'Ваше останнє відоме місцезнаходження, може бути застарілим';

  @override
  String gps_lastKnownAt(String time) {
    return 'Ваше останнє відоме місцезнаходження ($time), може бути застарілим';
  }

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
    return 'Поділитися розташуванням у $channelLabel? Канал публічний: його може побачити будь-хто.';
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
  String get repeater_cliQuickRepeatOn => 'Увімкнути повтор';

  @override
  String get repeater_cliQuickRepeatOff => 'Вимкнути повтор';

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
  String get repeater_cliHelpIntro =>
      'Торкніться команди, щоб вставити її в поле, потім замініть частини у фігурних дужках. Торкніться кнопки get, щоб прочитати це налаштування. Це команди прошивки 1.18; у старішій прошивці деяких із них може не бути.';

  @override
  String get repeater_cliSectionRadio => 'Радіо';

  @override
  String get repeater_cliSectionPower => 'Живлення';

  @override
  String get repeater_cliSectionRegions => 'Регіони';

  @override
  String get repeater_cliSectionSensors => 'Датчики';

  @override
  String get repeater_cliSectionRoom => 'Сервер кімнат';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Надсилає оголошення, яке чують лише радіо в прямій досяжності. Ретранслятори його далі не передають.';

  @override
  String get repeater_cliHelpClockSync =>
      'Ставить годинник пристрою за часом вашого телефону. Годинник можна перевести лише вперед.';

  @override
  String get repeater_cliHelpTime =>
      'Ставить годинник на час Unix у секундах. Годинник можна перевести лише вперед.';

  @override
  String get repeater_cliHelpBoard => 'Показує виробника й модель плати.';

  @override
  String get repeater_cliHelpGetRole =>
      'Показує роль прошивки, наприклад ретранслятор чи сервер кімнат.';

  @override
  String get repeater_cliHelpGetPublicKey => 'Показує відкритий ключ пристрою.';

  @override
  String get repeater_cliHelpClkReboot =>
      'Переводить годинник назад на травень 2024 року й перезавантажує пристрій. Використовуйте, коли годинник поспішає, а потім виконайте clock sync.';

  @override
  String get repeater_cliHelpPowerOff =>
      'Вимикає пристрій, доки не натиснуть його кнопку або не перепідключать живлення. shutdown робить те саме.';

  @override
  String get repeater_cliHelpStartOta =>
      'Запускає оновлення прошивки по повітрю на платах, які це підтримують. У відповіді сказано, як під\'єднатися.';

  @override
  String get repeater_cliHelpRoomPost =>
      'Публікує повідомлення в кімнаті від імені самого сервера кімнат.';

  @override
  String get repeater_cliHelpGetFreq => 'Показує частоту радіо в МГц.';

  @override
  String get repeater_cliHelpSetTxPower =>
      'Задає потужність передавання LoRa в дБм. Діє одразу.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Задає частку часу, яку радіо може витрачати на передавання, у відсотках. Це той самий коефіцієнт ефірного часу, лише в інших одиницях.';

  @override
  String get repeater_cliHelpSetCad =>
      'Вмикає або вимикає виявлення активності в каналі: перед передаванням радіо слухає інші сигнали LoRa.';

  @override
  String get repeater_cliHelpSetRxGain =>
      'Вмикає або вимикає підвищене підсилення приймання на радіо, які його мають.';

  @override
  String get repeater_cliHelpSetExtraSf =>
      'Лише для радіо LR2021: додатково слухає ще до трьох коефіцієнтів розширення.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Задає відомості про власника, які пристрій на запит повідомляє разом з ім\'ям і версією. Використовуйте | для нового рядка.';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'Як flood.max, але для пакетів на всю мережу, надісланих без регіону.';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'Як flood.max, але для оголошень. За замовчуванням 8.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Задає, наскільки суворо ретранслятор відкидає пакети на всю мережу, що ходять по колу. За замовчуванням minimal.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Задає, скільки байтів кожен стрибок додає до шляху пакета: 0 — 1 байт, 1 — 2 байти, 2 — 3 байти.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      'Замінює ідентичність пристрою цим приватним ключем. Щоб застосувати, перезавантажте. Стара ідентичність буде втрачена, якщо ви не зберегли її ключ.';

  @override
  String get repeater_cliHelpPower =>
      'Показує напругу батареї та чи підключено живлення від USB, сонячної панелі чи іншого зовнішнього джерела.';

  @override
  String get repeater_cliHelpPowerSaving =>
      'Показує, чи ввімкнено енергозбереження.';

  @override
  String get repeater_cliHelpPowerSavingSet =>
      'Вмикає або вимикає енергозбереження. Плати nRF52 починають заощаджувати одразу, плати ESP32 — через 2 хвилини.';

  @override
  String get repeater_cliHelpGetPwrmgtSupport =>
      'Показує, чи має плата керування живленням.';

  @override
  String get repeater_cliHelpGetPwrmgtSource =>
      'Показує, чи працює пристрій від зовнішнього живлення чи від своєї батареї.';

  @override
  String get repeater_cliHelpGetPwrmgtBootReason =>
      'Показує, чому пристрій востаннє запустився і чому востаннє вимкнувся.';

  @override
  String get repeater_cliHelpGetPwrmgtBootMv =>
      'Показує напругу батареї під час останнього запуску пристрою.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      'Показує версію завантажувача на платах nRF52.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Просить ретранслятори поблизу відповісти, щоб заповнити список сусідів.';

  @override
  String get repeater_cliHelpRegions =>
      'Показує список регіонів і в яких із них дозволено надсилання на всю мережу (F).';

  @override
  String get repeater_cliHelpRegionDef =>
      'Додає регіони однією командою: кожна назва стає під попередню. Напишіть name|parent, щоб поставити наступну назву під цього батька.';

  @override
  String get repeater_cliHelpRegionList =>
      'Показує регіони, у яких надсилання на всю мережу дозволено (allowed) або заборонено (denied).';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Показує регіон за замовчуванням — той, у якому виходять власні пакети на всю мережу цього пристрою.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Задає регіон за замовчуванням або <null>, щоб його не було. Нова назва додається як регіон. Зберігається одразу.';

  @override
  String get repeater_cliHelpGpsDiag =>
      'Показує подробиці GPS для пошуку проблем.';

  @override
  String get repeater_cliHelpSensorList =>
      'Показує налаштування датчиків плати. Додайте число, щоб почати далі за списком.';

  @override
  String get repeater_cliHelpSensorGet => 'Показує одне налаштування датчика.';

  @override
  String get repeater_cliHelpSensorSet => 'Змінює одне налаштування датчика.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      'Задає канал Wi-Fi для мостів ESP-NOW.';

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
  String get channelPath_unknownPath => 'Невідомий';

  @override
  String get channelPath_floodPath => 'На всю мережу';

  @override
  String get channelPath_directPath => 'Прямий';

  @override
  String channelPath_pickedUpOnItsWay(String hops) {
    return 'Отримано дорогою, лишалося: $hops';
  }

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
  String get contacts_ShareContactZeroHop =>
      'Поділитися контактом за оголошенням';

  @override
  String get contacts_shareByAdvertFailed =>
      'Радіо не змогло поділитися цим контактом. Спочатку воно має почути його оголошення.';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Відправлено контакт за оголошенням';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Не вдалося надіслати контакт.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Копіювання оголошення в буфер обміну завершилося невдало';

  @override
  String get contacts_addContact => 'Додати контакт';

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
  String get routing_noRoutePathfinder => 'поки немає';

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
  String get routing_forgetDonePathfinder => 'Шлях скинуто.';

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
  String get chat_channelNoSign => 'Надіслано · не видно, хто отримав';

  @override
  String chat_sentByItsClock(String time) {
    return 'надіслано $time за годинником відправника';
  }

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
    return 'Отримано · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Отримано зі спроби $attempt · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Отримано із запізненням · $kind · $secs с';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Отримано · $secs с';
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
      'Ваше радіо пам\'ятає один маршрут до кожного контакту. Якщо повідомлення цим маршрутом не доходить, MeshTrax натомість надсилає його на всю мережу. Pathfinder слухає все, що чує радіо: оголошення ретрансляторів, розмови в каналах, чужі повідомлення. З цього він будує карту: які ретранслятори чують один одного, які чують вас і які — кожного з ваших контактів.';

  @override
  String get pathfinderHelp_how =>
      'Коли ви надсилаєте повідомлення, Pathfinder спершу пробує свій найкращий маршрут, потім наступний за якістю і лише в крайньому разі надсилає на всю мережу. Бурштиновий значок шляху позначає повідомлення, надіслане маршрутом Pathfinder.';

  @override
  String get pathfinderHelp_learning =>
      'Йому потрібен час. Нова карта ще нічого не знає, тож спочатку ваші повідомлення надсилаються на всю мережу, доки він не вивчить маршрут. Після кількох годин прослуховування в одному місці він починає пропонувати маршрути, а кожна доставка чи невдача вчить його чогось нового. У перший день не чекайте від нього багато, а в кожному новому місці — знову менше.';

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
  String get settings_pathGraph => 'Pathfinder';

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
      'Завантажувати лише через Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Завантаження чекають на Wi‑Fi';

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
  String get offlineMaps_kindContoursDetail =>
      'Лінії висот, також використовуються для прямої видимості';

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
  String get offlineMaps_notificationRunning => 'Завантаження';

  @override
  String get offlineMaps_notificationPaused => 'Завантаження призупинено';

  @override
  String get offlineMaps_notificationFailed => 'Не вдалося завантажити';

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
  String get map_downloadForDetail => 'Завантажте регіон, щоб бачити подробиці';

  @override
  String get map_noCharts => 'Тут немає морських карт';

  @override
  String get map_myLocation => 'Моє розташування';

  @override
  String get map_zoomIn => 'Збільшити';

  @override
  String get map_zoomOut => 'Зменшити';

  @override
  String get gps_on => 'GPS увімк.';

  @override
  String get gps_off => 'GPS вимк.';

  @override
  String get gps_noPosition =>
      'Розташування ще немає. Надворі перше визначення може тривати кілька хвилин.';

  @override
  String get gps_position => 'Координати';

  @override
  String get gps_altitude => 'Висота';

  @override
  String get gps_turnOnTitle => 'Увімкнути GPS?';

  @override
  String get gps_turnOnBody =>
      'GPS радіо вимкнено. Пошук розташування може тривати кілька хвилин.';

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
  String get mapLayers_details => 'Деталі карти';

  @override
  String get mapLayers_contours => 'Горизонталі';

  @override
  String get mapLayers_hillShading => 'Відмивка рельєфу';

  @override
  String get mapLayers_places => 'Місця';

  @override
  String get mapLayers_parks => 'Парки';

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
  String get structured_repeaterStatus => 'Стан ретрансляторів';

  @override
  String get repeaterStatus_stateCritical => 'критичний';

  @override
  String get repeaterStatus_stateVeryLow => 'дуже низький';

  @override
  String get repeaterStatus_stateLow => 'низький';

  @override
  String get repeaterStatus_stateOk => 'OK';

  @override
  String get repeaterStatus_waiting => 'чекає на своє оголошення';

  @override
  String get repeaterStatus_unreachable => 'недоступний';

  @override
  String get repeaterStatus_noReading => 'немає показів';

  @override
  String repeaterStatus_tx(String value) {
    return 'TX $value';
  }

  @override
  String get repeaterStatus_repeatOn => 'ретрансляція увімк.';

  @override
  String get repeaterStatus_repeatOff => 'ретрансляція вимк.';

  @override
  String repeaterStatus_minutes(int count) {
    return '$count хв';
  }

  @override
  String repeaterStatus_hours(int count) {
    return '$count год';
  }

  @override
  String repeaterStatus_days(int count) {
    return '$count д';
  }

  @override
  String repeaterStatus_ago(String time) {
    return '$time тому';
  }

  @override
  String repeaterStatus_nextPoll(String time) {
    return 'наступне опитування через $time';
  }

  @override
  String repeaterStatus_missed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count пропущеного опитування',
      many: '$count пропущених опитувань',
      few: '$count пропущені опитування',
      one: '$count пропущене опитування',
    );
    return '$_temp0';
  }

  @override
  String repeaterStatus_was(String state) {
    return 'був $state';
  }

  @override
  String repeaterStatus_lastStage(String state) {
    return 'останній рівень $state';
  }

  @override
  String repeaterStatus_for(String name) {
    return 'для $name';
  }

  @override
  String repeaterStatus_readingIgnored(String value) {
    return 'показ $value відкинуто';
  }

  @override
  String repeaterStatus_page(int page, int pages) {
    return 'Сторінка $page з $pages';
  }

  @override
  String get repeaterStatus_dryRun => 'Лише симуляція';

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
  String get route_otherApp => 'Відкрити в іншому застосунку';

  @override
  String get navigate_otherApp => 'Інший застосунок';

  @override
  String get navigate_showDownload => 'Показати завантаження';

  @override
  String get navigate_pickStart => 'Вибрати старт';

  @override
  String navigate_routingMissing(String region) {
    return 'Офлайн-маршрутів для $region немає на цьому телефоні.';
  }

  @override
  String navigate_routingSize(String size) {
    return 'Розмір завантаження — $size.';
  }

  @override
  String get navigate_noRoutingHere =>
      'Для цієї області ще немає офлайн-маршрутів.';

  @override
  String get navigate_noPosition =>
      'Немає GPS-позиції. Виберіть старт на карті або скористайтеся іншим застосунком.';

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
  String get structured_open => 'Відкрити чат';

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
  String get location_sendPositionOnly => 'Лише позиція';

  @override
  String get location_sendWithMotion => 'Позиція, курс, швидкість і висота';

  @override
  String get location_motionNotKnown => 'Курс і швидкість поки невідомі';

  @override
  String get add_title => 'Новий канал або контакт';

  @override
  String get add_or => 'Або';

  @override
  String get add_hashtagRow => 'Приєднатися до каналу з хештегом';

  @override
  String get add_hashtagRowHelp => 'Введіть його назву після #';

  @override
  String get add_keyRow => 'Ввести ім\'я та ключ';

  @override
  String get add_keyRowHelp =>
      'Секретний ключ каналу або відкритий ключ контакту';

  @override
  String get add_name => 'Ім\'я';

  @override
  String get add_key => 'Ключ';

  @override
  String get add_keyInvalid => 'Ключ каналу — 32 символи, контакту — 64.';

  @override
  String get add_typePerson => 'Людина';

  @override
  String get add_box => 'Вставте або введіть';

  @override
  String get add_boxHint =>
      'Посилання meshcore://, <key:type:name>, #хештег або ключ';

  @override
  String get add_paste => 'Вставити';

  @override
  String get add_clipboardEmpty => 'Нічого вставити.';

  @override
  String get add_unreadableTitle => 'Поки нічого додати';

  @override
  String get add_unreadable =>
      'Для контакту: посилання meshcore://, <key:type:name>, картка контакту або ключ із 64 символів. Для каналу: посилання meshcore://, #хештег або секретний ключ із 32 символів з його назвою.';

  @override
  String get add_contactName => 'Ім\'я (необов\'язково)';

  @override
  String get add_scanInstructions => 'Відскануйте QR-код контакту або каналу';

  @override
  String get add_scanUnreadable => 'Цей QR-код — не контакт і не канал.';

  @override
  String get copy_link => 'Копіювати посилання';

  @override
  String get copy_asText => 'Копіювати як текст';

  @override
  String get share_asText => 'У вигляді тексту';

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
  String get sos_alsoPublic => 'Надіслати також у Public';

  @override
  String get sos_alsoPublicHint =>
      'Будь-хто в зоні досяжності може прочитати його й вашу позицію. Надсилається один раз.';

  @override
  String get sos_askingRadio => 'Запитуємо позицію в рації…';

  @override
  String sos_positionFrom(String time, String age) {
    return 'Позиція рації від $time ($age)';
  }

  @override
  String sos_positionNotNew(String time, String age) {
    return 'Немає нової позиції. Остання відома $time ($age).';
  }

  @override
  String get sos_positionAgeUnknown =>
      'Остання відома позиція, давність невідома.';

  @override
  String get sos_positionTyped =>
      'Ваша власна позиція: кожен повтор надсилає її.';

  @override
  String get sos_repeats =>
      'Повторюється кожні 2 хв з вашою позицією, доки не скасуєте; після «Прийнято» — кожні 5 хв.';

  @override
  String get sos_publicOnce => 'У Public надсилається один раз.';

  @override
  String get sos_traxOnly => 'Режим TRAX: його чують лише радіо TRAX.';

  @override
  String sos_replacesOther(String chat) {
    return 'Це скасує ваш SOS у $chat.';
  }

  @override
  String get sos_active => 'Ваш SOS активний';

  @override
  String sos_lastSent(String time) {
    return 'Останнє надсилання $time';
  }

  @override
  String get sos_waitingForRadio => 'Чекаємо на рацію, щоб надіслати';

  @override
  String sos_gotItBy(int count, String names) {
    return 'Прийнято ($count): $names';
  }

  @override
  String get sos_noGotIt => 'Ще ніхто не відповів «Прийнято»';

  @override
  String get sos_cancel => 'Скасувати SOS';

  @override
  String sos_cancelBody(String chat) {
    return 'Усі в $chat отримають «SOS cancelled».';
  }

  @override
  String get sos_keep => 'Залишити SOS';

  @override
  String get sos_cancelPending =>
      'SOS скасовано. Надішлеться, коли рація під’єднається.';

  @override
  String sos_stopped(String time) {
    return 'SOS зупинився, коли MeshTrax закрився. Востаннє надіслано $time.';
  }

  @override
  String get sos_sendAgain => 'Надіслати знову';

  @override
  String get sos_gotIt => 'Прийнято';

  @override
  String sos_updated(String time) {
    return 'Оновлено $time';
  }

  @override
  String sos_cancelledAt(String time) {
    return 'Скасовано $time';
  }

  @override
  String sos_sentAt(String time) {
    return 'Надіслано $time';
  }

  @override
  String sos_activeLastSent(String time) {
    return 'Ваш SOS активний · останнє надсилання $time';
  }

  @override
  String get sos_activeWaiting => 'Ваш SOS активний · чекаємо на рацію';

  @override
  String get sos_stoppedSendAgain => 'Ваш SOS зупинився · Надіслати знову';

  @override
  String get sos_cancelledWaiting => 'SOS скасовано · чекаємо на рацію';

  @override
  String get sos_dndStepsSamsung =>
      'Відкриються налаштування на сторінці «Не турбувати». Торкніться «Сповіщення програм», потім «Додати програми», виберіть MeshTrax і ввімкніть лише «SOS-сповіщення».';

  @override
  String get sos_dndStepsOther =>
      'Відкриються налаштування на сторінці «SOS-сповіщення»: увімкніть «Ігнорувати режим „Не турбувати“». Якщо на вашому телефоні там немає такого перемикача, відкрийте «Не турбувати», знайдіть програми, яким дозволено переривати, додайте MeshTrax і ввімкніть «SOS-сповіщення».';

  @override
  String get notification_sosChannel => 'SOS-сповіщення';

  @override
  String get notification_sosChannelDescription =>
      'SOS, надісланий вам або в чат, де ви є';

  @override
  String notification_sosFrom(String name) {
    return 'SOS від $name';
  }

  @override
  String notification_sosCancelledBy(String name) {
    return '$name скасував(ла) SOS';
  }

  @override
  String get notification_mySosChannel => 'Ваш SOS';

  @override
  String get notification_mySosChannelDescription =>
      'Ваш власний SOS, поки він активний';

  @override
  String get appSettings_sosAlerts => 'SOS-сповіщення';

  @override
  String get appSettings_sosAlways =>
      'SOS завжди сповіщає, навіть у чаті без звуку або з вимкненими сповіщеннями про повідомлення.';

  @override
  String get appSettings_sosThroughDnd =>
      'Звучить навіть у режимі «Не турбувати».';

  @override
  String get appSettings_sosLetThroughDnd =>
      'Режим «Не турбувати» глушить його. Натисніть, щоб він звучав.';

  @override
  String get appSettings_sosBlocked =>
      'На телефоні SOS-сповіщення вимкнено. Натисніть, щоб увімкнути.';

  @override
  String get appSettings_sosApple =>
      'Режими фокусування й безшумний режим усе ще можуть заглушити його на цьому пристрої.';

  @override
  String get appSettings_sosOff =>
      'Сповіщення вимкнено, тож SOS-сповіщення теж.';

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
  String get paste_resolveFailed => 'Не вдалося обробити посилання';

  @override
  String get paste_shortLinkNoPosition =>
      'Це коротке посилання не містить позиції. Відкрийте його в застосунку карт і скопіюйте координати.';

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
  String get roadLegend_title => 'Дороги, стежки та лінії';

  @override
  String get roadLegend_freeway => 'Автомагістраль';

  @override
  String get roadLegend_majorRoad => 'Шосе або головна дорога';

  @override
  String get roadLegend_road => 'Дорога';

  @override
  String get roadLegend_track => 'Ґрунтова або польова дорога';

  @override
  String get roadLegend_trail => 'Стежка';

  @override
  String get roadLegend_walkway => 'Пішохідна або велосипедна доріжка';

  @override
  String get roadLegend_interstate => 'Міжштатна автомагістраль';

  @override
  String get roadLegend_usRoute => 'Шосе США';

  @override
  String get roadLegend_stateRoute => 'Шосе штату';

  @override
  String get roadLegend_railway => 'Залізниця';

  @override
  String get roadLegend_stream => 'Річка або струмок';

  @override
  String get roadLegend_contour => 'Горизонталь';

  @override
  String get roadLegend_park => 'Межа парку';

  @override
  String get roadLegend_wilderness => 'Зона дикої природи або національний ліс';

  @override
  String get roadLegend_boundary => 'Межа штату або округу';

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
  String get chats_traxLabel => 'TRAX';

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
  String get route_pathPaved => 'Шосе';

  @override
  String get route_pathDirt => 'Ґрунт';

  @override
  String get route_pathHiking => 'Пішки';

  @override
  String route_minutes(int minutes) {
    return '$minutes хв';
  }

  @override
  String route_hoursMinutes(int hours, int minutes) {
    return '$hours год $minutes хв';
  }

  @override
  String route_to(String destination) {
    return 'До $destination';
  }

  @override
  String get route_clear => 'Прибрати маршрут';

  @override
  String get route_finding => 'Пошук маршруту…';

  @override
  String get route_none => 'Маршрут не знайдено';

  @override
  String route_endsShortPaved(String distance, String destination) {
    return 'Маршрут уривається за $distance до $destination — там закінчується асфальт.';
  }

  @override
  String route_endsShortDirt(String distance, String destination) {
    return 'Маршрут уривається за $distance до $destination — там закінчується дорога.';
  }

  @override
  String route_endsShortHiking(String distance, String destination) {
    return 'Маршрут уривається за $distance до $destination — там закінчуються стежки.';
  }

  @override
  String get route_directions => 'Покрокові вказівки';

  @override
  String get route_here => 'Маршрут сюди';

  @override
  String route_destinationNow(String destination) {
    return 'Зараз пункт призначення: $destination';
  }

  @override
  String route_startNow(String start) {
    return 'Зараз точка старту: $start';
  }

  @override
  String get route_startNowYou => 'Зараз точка старту: ваше місцезнаходження';

  @override
  String route_from(String start) {
    return 'Від $start';
  }

  @override
  String get route_fromYou => 'Від вашого місцезнаходження';

  @override
  String get route_useMyPosition => 'Використати моє місцезнаходження';

  @override
  String get route_noHeights => 'Для цієї місцевості немає даних про висоти.';

  @override
  String get route_noHeightsHiking =>
      'Для цієї місцевості немає даних про висоти, тож час не враховує підйомів.';

  @override
  String get route_options => 'Параметри маршруту';

  @override
  String get route_optionsReset => 'Скинути';

  @override
  String get route_prefer => 'Пріоритет';

  @override
  String get route_dirtFastest => 'Швидкість';

  @override
  String get route_dirtBalanced => 'Баланс';

  @override
  String get route_dirtDirect => 'Відстань';

  @override
  String get route_dirtFastestHelp =>
      'Ґрунтові дороги — лише там, де так швидше.';

  @override
  String get route_dirtBalancedHelp =>
      'Ґрунтова дорога — коли вона суттєво скорочує відстань.';

  @override
  String get route_dirtDirectHelp =>
      'Найкоротший маршрут, хоч би якими повільними були його дороги.';

  @override
  String get route_avoid => 'Уникати';

  @override
  String get route_avoidHighways => 'Автомагістралі';

  @override
  String get route_avoidTolls => 'Платні дороги';

  @override
  String get route_avoidFerries => 'Пороми';

  @override
  String get route_hardestTrail => 'Найскладніша стежка';

  @override
  String get route_trailT1 => 'T1 Піший туризм';

  @override
  String get route_trailT2 => 'T2 Гірський туризм';

  @override
  String get route_trailT3 => 'T3 Складний гірський туризм';

  @override
  String get route_trailT4 => 'T4 Альпійський туризм';

  @override
  String get route_trailT5 => 'T5 Складний альпійський туризм';

  @override
  String get route_trailT6 => 'T6 Дуже складний альпійський туризм';

  @override
  String get route_climbs => 'Підйоми';

  @override
  String get route_climbsAvoid => 'Уникати';

  @override
  String get route_climbsSome => 'Помірно';

  @override
  String get route_climbsAny => 'Неважливо';

  @override
  String get route_pace => 'Темп';

  @override
  String get route_paceSlow => 'Повільний';

  @override
  String get route_paceNormal => 'Звичайний';

  @override
  String get route_paceFast => 'Швидкий';

  @override
  String get place_nrhp => 'Національний реєстр історичних місць';

  @override
  String get place_textCredit => 'Текст: Wikipedia, CC BY-SA 4.0';

  @override
  String get place_readOnWikipedia => 'Читати у Wikipedia';

  @override
  String place_photoCredit(String author, String licence) {
    return 'Фото: $author, $licence';
  }

  @override
  String get search_hint => 'Пошук місць, адрес або координат';

  @override
  String get search_noPlaces =>
      'Щоб шукати місця, завантажте «Точки інтересу». Координати працюють і без них.';

  @override
  String get search_noResults => 'Нічого не знайдено';

  @override
  String search_near(String name) {
    return 'поблизу $name';
  }

  @override
  String get coordFormat_decimalDegrees => 'Десяткові градуси';

  @override
  String get coordFormat_degreesMinutes => 'Градуси та мінути';

  @override
  String get coordFormat_dms => 'Градуси, мінути, секунди';

  @override
  String get coordFormat_utm => 'UTM';

  @override
  String get coordFormat_mgrs => 'MGRS / USNG';

  @override
  String get coordFormat_maidenhead => 'Сітка Maidenhead';

  @override
  String get coordFormat_geohash => 'Geohash';

  @override
  String get poiKind_peak => 'Вершина';

  @override
  String get poiKind_volcano => 'Вулкан';

  @override
  String get poiKind_saddle => 'Сідловина';

  @override
  String get poiKind_pass => 'Перевал';

  @override
  String get poiKind_spring => 'Джерело';

  @override
  String get poiKind_hotSpring => 'Гаряче джерело';

  @override
  String get poiKind_waterfall => 'Водоспад';

  @override
  String get poiKind_cave => 'Печера';

  @override
  String get poiKind_arch => 'Природна арка';

  @override
  String get poiKind_glacier => 'Льодовик';

  @override
  String get poiKind_rock => 'Скеля';

  @override
  String get poiKind_cliff => 'Обрив';

  @override
  String get poiKind_beach => 'Пляж';

  @override
  String get poiKind_trailhead => 'Початок стежки';

  @override
  String get poiKind_campground => 'Кемпінг';

  @override
  String get poiKind_picnicSite => 'Місце для пікніка';

  @override
  String get poiKind_hut => 'Притулок';

  @override
  String get poiKind_shelter => 'Укриття';

  @override
  String get poiKind_drinkingWater => 'Питна вода';

  @override
  String get poiCaveat_spring => 'Може пересохнути або бути небезпечним';

  @override
  String get poiCaveat_drinkingWater => 'Може бути перекрита';

  @override
  String get poiKind_toilets => 'Туалет';

  @override
  String get poiKind_viewpoint => 'Оглядовий майданчик';

  @override
  String get poiKind_attraction => 'Пам\'ятка';

  @override
  String get poiKind_observatory => 'Обсерваторія';

  @override
  String get poiKind_zoo => 'Зоопарк';

  @override
  String get poiKind_themePark => 'Парк розваг';

  @override
  String get poiKind_mine => 'Копальня';

  @override
  String get poiKind_mineShaft => 'Шахтний ствол';

  @override
  String get poiKind_adit => 'Штольня';

  @override
  String get poiKind_ghostTown => 'Місто-привид';

  @override
  String get poiKind_ruins => 'Руїни';

  @override
  String get poiKind_monument => 'Пам\'ятник';

  @override
  String get poiKind_memorial => 'Меморіал';

  @override
  String get poiKind_fort => 'Форт';

  @override
  String get poiKind_historic => 'Історичне місце';

  @override
  String get poiKind_rangerStation => 'Пост рейнджерів';

  @override
  String get poiKind_visitorCenter => 'Візит-центр';

  @override
  String get poiKind_hospital => 'Лікарня';

  @override
  String get poiKind_police => 'Поліція';

  @override
  String get poiKind_fireStation => 'Пожежна частина';

  @override
  String get poiKind_emergencyPhone => 'Аварійний телефон';

  @override
  String get poiKind_fuel => 'АЗС';

  @override
  String get poiKind_restArea => 'Майданчик відпочинку';

  @override
  String get poiKind_travelCenter => 'Придорожній комплекс';

  @override
  String get poiKind_museum => 'Музей';

  @override
  String get poiKind_city => 'Місто';

  @override
  String get poiKind_town => 'Містечко';

  @override
  String get poiKind_locality => 'Місцевість';

  @override
  String get poiKind_lake => 'Озеро';

  @override
  String get poiKind_river => 'Річка';

  @override
  String get poiKind_valley => 'Долина';

  @override
  String get poiKind_range => 'Гірський хребет';

  @override
  String get poiKind_trail => 'Стежка';

  @override
  String get poiKind_dirtRoad => 'Ґрунтова дорога';

  @override
  String get poiKind_road => 'Дорога';

  @override
  String get poiKind_address => 'Адреса';

  @override
  String get poiKind_place => 'Місце';

  @override
  String get offlineMaps_kindRouting => 'Прокладання маршрутів';

  @override
  String get offlineMaps_kindRoutingDetail =>
      'Маршрути стежками, ґрунтовими й асфальтованими дорогами';

  @override
  String get offlineMaps_kindPoi => 'Точки інтересу';

  @override
  String get offlineMaps_kindPoiDetail =>
      'Місця для пошуку й тексти з Wikipedia';

  @override
  String get offlineMaps_kindAddresses => 'Адреси';

  @override
  String get offlineMaps_kindAddressesDetail => 'Адреси будинків для пошуку';

  @override
  String get offlineMaps_useDrive => 'Використати накопичувач';

  @override
  String offlineMaps_onDrive(String name, String date) {
    return 'Карти з накопичувача $name, від $date';
  }

  @override
  String get offlineMaps_backToInternet => 'Повернутися до інтернету';

  @override
  String get offlineMaps_keepOpen =>
      'Встановлення з накопичувача. Не закривайте MeshTrax.';

  @override
  String get offlineMaps_driveRemoved =>
      'Накопичувач від’єднано. Знову показано карти з інтернету.';

  @override
  String get offlineMaps_readingDrive => 'Читання накопичувача…';

  @override
  String get offlineMaps_noMapsOnDrive =>
      'Там немає карт MeshTrax. Виберіть папку MeshTrax-maps на накопичувачі.';

  @override
  String offlineMaps_driveError(String error) {
    return 'Не вдалося прочитати накопичувач: $error';
  }

  @override
  String get offlineMaps_stopDriveTitle =>
      'Зупинити встановлення з накопичувача?';

  @override
  String get offlineMaps_stopDriveBody =>
      'Уже встановлене залишиться на цьому пристрої.';

  @override
  String get offlineMaps_stopDrive => 'Зупинити';

  @override
  String get offlineMaps_keepInstalling => 'Продовжити';

  @override
  String offlineMaps_install(String size) {
    return 'Встановити $size';
  }

  @override
  String get offlineMaps_installTotal => 'Встановити';

  @override
  String get offlineMaps_routingDriveOlder =>
      'На цьому пристрої дані маршрутів новіші, ніж на накопичувачі.';

  @override
  String get offlineMaps_routingDriveIncomplete =>
      'Дані маршрутів на накопичувачі охоплюють не всі регіони цього пристрою.';

  @override
  String get offlineMaps_kindWaterRouting => 'Прокладання маршрутів по воді';

  @override
  String get offlineMaps_kindWaterRoutingDetail => 'Маршрути по воді';

  @override
  String get offlineMaps_waterRoutingWithChart =>
      'Маршрути по воді. Морська карта завантажиться разом із ними.';

  @override
  String get offlineMaps_waterRoutingUpdatesChart =>
      'Маршрути по воді. Морська карта теж оновиться.';

  @override
  String get offlineMaps_waterRoutingRebuilding =>
      'Перебудовується під нові карти';

  @override
  String get map_search => 'Пошук';

  @override
  String get map_fullScreen => 'Повноекранний режим';

  @override
  String get map_leaveFullScreen => 'Вийти з повноекранного режиму';

  @override
  String get map_fullScreenHintBack =>
      'Щоб вийти з повноекранного режиму, натисніть «Назад» або ту саму кнопку.';

  @override
  String get map_fullScreenHintTap =>
      'Щоб вийти з повноекранного режиму, натисніть ту саму кнопку.';

  @override
  String get map_fullScreenHintKey =>
      'Щоб вийти з повноекранного режиму, натисніть Esc або ту саму кнопку.';

  @override
  String get route_fromHere => 'Маршрут звідси';

  @override
  String get route_startSet =>
      'Точку старту встановлено. Тепер виберіть, куди прямувати.';

  @override
  String get route_noStart =>
      'Немає точки старту. Натисніть і утримуйте точку на карті, а потім виберіть «Маршрут звідси».';

  @override
  String get route_noData =>
      'Завантажте «Прокладання маршрутів» для цього регіону в розділі «Офлайн-карти».';

  @override
  String get route_pin => 'Мітка на карті';

  @override
  String get water_yourBoat => 'Ваш човен';

  @override
  String get water_yourBoatIntro =>
      'Кожен маршрут по воді враховує ці параметри. Пізніше їх можна змінити в розділі «Параметри маршруту».';

  @override
  String water_boatDraft(String draft, String keel) {
    return 'осадка $draft + $keel';
  }

  @override
  String water_boatOffLand(String distance) {
    return '$distance від берега';
  }

  @override
  String water_boatMast(String height) {
    return 'щогла $height';
  }

  @override
  String get water_classRestricted => 'Район з обмеженнями';

  @override
  String get water_classCaution => 'Район застереження';

  @override
  String get water_classMilitary => 'Військовий район';

  @override
  String get water_classAnchorage => 'Якірна стоянка';

  @override
  String get water_classDumping => 'Район звалища ґрунту';

  @override
  String get water_classTrafficLane => 'Смуга руху';

  @override
  String get water_classSeparation => 'Зона розділення';

  @override
  String get water_classPrecautionary => 'Район, де потрібна обережність';

  @override
  String get water_classInshoreTraffic => 'Зона прибережного плавання';

  @override
  String get water_classMarineFarm => 'Морська ферма';

  @override
  String get water_classBridge => 'Міст';

  @override
  String get water_classCable => 'Повітряний кабель';

  @override
  String get water_classPipe => 'Повітряний трубопровід';

  @override
  String get water_classConveyor => 'Конвеєр';

  @override
  String get water_classGate => 'Ворота';

  @override
  String get water_movedLand => 'ця точка на суші або за межами карт';

  @override
  String get water_movedShallow => 'там занадто мілко';

  @override
  String get water_movedHazard =>
      'поруч небезпека на глибині, замалій для човна';

  @override
  String get water_movedNoEntry => 'туди вхід заборонено';

  @override
  String get water_movedMast => 'там щось нижче за щоглу';

  @override
  String water_startMoved(String distance, String why) {
    return 'Починається за $distance від вибраної точки: $why.';
  }

  @override
  String water_endMoved(String distance, String why) {
    return 'Закінчується за $distance від вибраної точки: $why.';
  }

  @override
  String water_endsShortDepth(
    String distance,
    String destination,
    String band,
    String draft,
  ) {
    return 'Маршрут уривається за $distance до $destination: за картою глибина $band. Пройдуть судна з осадкою до $draft.';
  }

  @override
  String water_endsShortTooShallow(
    String distance,
    String destination,
    String band,
  ) {
    return 'Маршрут уривається за $distance до $destination: за картою глибина $band, занадто мілко, щоб пройти.';
  }

  @override
  String water_endsShortMast(
    String distance,
    String destination,
    String objects,
  ) {
    return 'Маршрут уривається за $distance до $destination: $objects — занизько для щогли.';
  }

  @override
  String water_endsShortNoWater(String distance, String destination) {
    return 'Маршрут уривається за $distance до $destination: на картах немає води, що їх з\'єднує.';
  }

  @override
  String water_endsShortTooLong(String distance, String destination) {
    return 'Маршрут уривається за $distance до $destination: задовгий для одного маршруту. Прокладіть його частинами.';
  }

  @override
  String water_leastDepth(String depth) {
    return 'Найменша глибина: за картою $depth';
  }

  @override
  String water_lowestClearance(String height) {
    return 'Найменша висота проходу $height';
  }

  @override
  String water_lowestClearanceUnder(String height, String name) {
    return 'Найменша висота проходу $height, $name';
  }

  @override
  String water_shallower(String depth) {
    return 'Мілкіше за $depth';
  }

  @override
  String get water_poorSurvey => 'Погано обстежено';

  @override
  String get water_needsOpening => 'потрібно розвести';

  @override
  String get water_magneticModelOld =>
      'Пеленги за магнітною моделлю, чинною до 2030 року';

  @override
  String water_couldntKeep(String distance) {
    return 'Ближче ніж $distance до берега';
  }

  @override
  String get water_onTheWay => 'Дорогою';

  @override
  String water_stretch(String length, String from) {
    return '$length, починаючи з $from шляху';
  }

  @override
  String get water_speed => 'Швидкість';

  @override
  String get water_draft => 'Осадка';

  @override
  String get water_underKeel => 'Запас під кілем';

  @override
  String get water_preferDepth => 'Бажана глибина';

  @override
  String get water_none => 'Немає';

  @override
  String get water_mastHeight => 'Висота щогли';

  @override
  String get water_offLand => 'Відстань від берега';

  @override
  String get water_avoidLanes => 'Смуги руху';

  @override
  String get water_avoidSecurity => 'Зони безпеки';

  @override
  String get water_avoidOpening => 'Розвідні мости';

  @override
  String get water_notForNavigation => 'Не для навігації';

  @override
  String get water_noData =>
      'Завантажте «Прокладання маршрутів по воді» для цього району морських карт у розділі «Офлайн-карти».';

  @override
  String water_routingMissing(String area) {
    return 'Маршрутів по воді для $area немає на цьому телефоні.';
  }

  @override
  String get route_onLand => 'Маршрут суходолом';

  @override
  String get route_onWater => 'Маршрут по воді';

  @override
  String get water_noTiles => 'Тут немає маршрутів по воді';

  @override
  String get water_mixedBuilds =>
      'Оновіть маршрути по воді в розділі «Офлайн-карти»: їхні райони з різних збірок.';

  @override
  String get water_noWater => 'Тут немає води, якою може пройти човен';

  @override
  String water_unchartedSpans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Під $count прольотами без висоти проходу на карті',
      many: 'Під $count прольотами без висоти проходу на карті',
      few: 'Під $count прольотами без висоти проходу на карті',
      one: 'Під $count прольотом без висоти проходу на карті',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_coordinateFormat => 'Формат координат';

  @override
  String get map_copyPosition => 'Копіювати координати';

  @override
  String get poiKind_park => 'Парк';

  @override
  String get poiKind_protectedArea => 'Природоохоронна територія';

  @override
  String get common_more => 'Більше';

  @override
  String get common_less => 'Менше';

  @override
  String get locationSharing_noPosition =>
      'Ваше радіо ще не має розташування, тому його ніхто не бачить';

  @override
  String get locationSharing_adverts => 'Розташування в анонсах';

  @override
  String get dialog_positionHint => 'Вставте координати або посилання на карту';

  @override
  String get dialog_positionUnreadable => 'Тут не вдається прочитати позицію';

  @override
  String get locationSharing_share => 'Ділитися моїм розташуванням';

  @override
  String get chats_advertise => 'Анонсувати';

  @override
  String get tray_drawing => 'Малюнок';

  @override
  String get drawing_tabDraw => 'Малювання';

  @override
  String get drawing_tabPaste => 'Вставлення';

  @override
  String get drawing_toolPen => 'Перо';

  @override
  String get drawing_toolLine => 'Лінія';

  @override
  String get drawing_toolRect => 'Прямокутник';

  @override
  String get drawing_toolCircle => 'Коло';

  @override
  String get drawing_toolEllipse => 'Еліпс';

  @override
  String get drawing_toolArrow => 'Стрілка';

  @override
  String get drawing_undo => 'Скасувати';

  @override
  String get drawing_caption => 'Підпис';

  @override
  String get drawing_captionHint => 'Необов\'язково, показується під малюнком';

  @override
  String drawing_bytes(int used, int max) {
    return '$used / $max байт';
  }

  @override
  String drawing_points(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count точок',
      many: '$count точок',
      few: '$count точки',
      one: '$count точка',
    );
    return '$_temp0';
  }

  @override
  String get drawing_keptAll => 'Усі намальовані точки збережено.';

  @override
  String drawing_simplified(String percent) {
    return 'Спрощено: лінії відхиляються не більше ніж на $percent% розміру малюнка.';
  }

  @override
  String get drawing_tooDetailed =>
      'Малюнок надто детальний для одного повідомлення, навіть спрощений. Скасуйте штрих або скористайтеся фігурами — вони займають значно менше місця.';

  @override
  String get drawing_empty => 'Малюйте пальцем або виберіть фігуру.';

  @override
  String get drawing_pasteHint =>
      'Вставте файл SVG або дані контуру, наприклад M10 10h80v80H10z';

  @override
  String get drawing_pasteUse => 'Використати SVG';

  @override
  String get drawing_pasteNote =>
      'Кольори й заливки не передаються: надсилаються лише лінії, які одержувач бачить у кольорі свого пера.';

  @override
  String get drawing_pasteEmpty => 'Спершу вставте SVG або дані контуру.';

  @override
  String get drawing_pasteTooBig =>
      'Цей SVG завеликий або надто детальний, щоб його прочитати. Вставте менший.';

  @override
  String get drawing_pasteUnreadable => 'Програма не може прочитати це як SVG.';

  @override
  String get drawing_pasteNothing =>
      'У цьому SVG немає нічого видимого для малювання.';

  @override
  String get drawing_copySvg => 'Копіювати SVG';

  @override
  String get appSettings_drawings => 'Малюнки';

  @override
  String get appSettings_drawingsSubtitle =>
      'Зображення, надіслані як SVG, і як вони тут виглядають';

  @override
  String get drawingSettings_show => 'Показувати малюнки';

  @override
  String get drawingSettings_showSubtitle =>
      'Якщо вимкнено, замість них показується код SVG';

  @override
  String get drawingSettings_penColor => 'Колір пера';

  @override
  String get drawingSettings_colorCode => 'Код кольору';

  @override
  String get drawingSettings_lineWidth => 'Товщина лінії';

  @override
  String get drawingSettings_glow => 'Світіння';

  @override
  String get drawingSettings_scanlines => 'Лінії розгортки';

  @override
  String get drawing_toolRoute => 'Маршрут';

  @override
  String get drawing_toolX => 'Хрестик';

  @override
  String get drawing_routeHint =>
      'Торкайтеся, щоб додавати точки. Щоб завершити, торкніться останньої ще раз.';

  @override
  String get drawing_mapNone => 'Без карти';

  @override
  String get drawing_mapUsgs => 'USGS';

  @override
  String get drawing_drawHere => 'Малювати тут';

  @override
  String get drawing_moveMap => 'Перемістити карту';

  @override
  String get drawing_mapHint =>
      'Наведіть карту на потрібне місце й налаштуйте масштаб, а потім натисніть «Малювати тут».';

  @override
  String drawing_mapAcross(String map, String distance) {
    return '$map, ширина $distance';
  }

  @override
  String get drawing_mapNotDownloaded => 'Цю область не завантажено';

  @override
  String get listFilter_hopsAway => 'Кількість переходів';

  @override
  String get listFilter_lastHeard => 'Востаннє чутно';

  @override
  String get listFilter_heardAnyTime => 'Будь-коли';

  @override
  String get listFilter_heardHour => 'Останню годину';

  @override
  String get listFilter_heardTwoDays => 'Останні 48 годин';

  @override
  String get listFilter_heardWeek => 'Останні 7 днів';

  @override
  String settings_radioFirmware(String version) {
    return 'Прошивка радіо $version';
  }

  @override
  String get settings_locationTapMap =>
      'Торкніться карти, щоб задати позицію, або введіть числа.';

  @override
  String get settings_locationGpsNote =>
      'Коли GPS увімкнено, радіо замінює цю позицію, щойно GPS визначить місцезнаходження.';

  @override
  String contacts_hopsAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count переходу',
      many: '$count переходів',
      few: '$count переходи',
      one: '1 перехід',
      zero: 'Напряму',
    );
    return '$_temp0';
  }

  @override
  String get los_lineOfSight => 'Пряма видимість';

  @override
  String get los_reachFromMe => 'Радіопокриття від мене';

  @override
  String get los_lineFromMe => 'Пряма видимість від мене';

  @override
  String get los_reachFromHere => 'Радіопокриття звідси';

  @override
  String los_reachFrom(String name) {
    return 'Радіопокриття: $name';
  }

  @override
  String get los_clear => 'Вільно';

  @override
  String get los_marginal => 'На межі';

  @override
  String get los_blocked => 'Закрито';

  @override
  String get los_cantTell => 'Невідомо';

  @override
  String get los_checking => 'Перевірка…';

  @override
  String get los_failed => 'Тут не вдалося розрахувати пряму видимість.';

  @override
  String get los_pickTarget => 'Торкніться людини або місця на карті.';

  @override
  String get los_noPosition =>
      'Ваше розташування ще невідоме. Торкніться карти, щоб почати звідти.';

  @override
  String get los_nothingInWay => 'Перешкод немає.';

  @override
  String los_groundAbove(String distance, String height) {
    return 'Рельєф за $distance від вас на $height вище лінії.';
  }

  @override
  String los_groundAboveStart(String distance, String height) {
    return 'Рельєф за $distance від початку на $height вище лінії.';
  }

  @override
  String los_groundWithin(String distance, String height) {
    return 'Рельєф за $distance від вас підходить до лінії на $height.';
  }

  @override
  String los_groundWithinStart(String distance, String height) {
    return 'Рельєф за $distance від початку підходить до лінії на $height.';
  }

  @override
  String get los_higherHelps => 'Допоможе вище місце або вища антена.';

  @override
  String los_noContours(String length) {
    return 'На $length цієї лінії немає горизонталей.';
  }

  @override
  String los_noContoursIn(String length, String regions) {
    return 'На $length цієї лінії немає горизонталей ($regions).';
  }

  @override
  String get los_noContoursArea =>
      'Для частини цієї області немає горизонталей.';

  @override
  String los_noContoursAreaIn(String regions) {
    return 'Для частини цієї області немає горизонталей ($regions).';
  }

  @override
  String get los_noHeightData => 'Для цієї області ще немає даних про висоту.';

  @override
  String los_downloadContours(String regions, String size) {
    return 'Завантажити горизонталі: $regions ($size)';
  }

  @override
  String get los_downloadBeforeTrip =>
      'Завантажте горизонталі тут до поїздки (потрібен інтернет).';

  @override
  String get los_spotBelowLowest => 'Нижче рівня моря: висота невідома.';

  @override
  String los_nameBelowLowest(String name) {
    return '$name нижче рівня моря: висота невідома.';
  }

  @override
  String get los_youBelowLowest =>
      'Ви нижче рівня моря: висота невідома. З увімкненим GPS використовується висота рації.';

  @override
  String get los_noLinesNear =>
      'Біля цього кінця немає горизонталей: висота невідома.';

  @override
  String get los_from => 'Від';

  @override
  String get los_to => 'До';

  @override
  String get los_thisRadio => 'Ця рація';

  @override
  String get los_me => 'Я';

  @override
  String los_meAgo(String age) {
    return 'Я, $age';
  }

  @override
  String get los_meByHand => 'Я, розташування задано вручну';

  @override
  String get los_meNotYetGps => 'Я, розташування ще не оновлено за GPS';

  @override
  String los_nameAgo(String name, String age) {
    return '$name, $age';
  }

  @override
  String get los_antenna => 'Антена';

  @override
  String get los_handHeld => 'У руці';

  @override
  String get los_vehicle => 'На машині';

  @override
  String get los_raised => 'Піднята';

  @override
  String get los_raisedTitle => 'Піднята антена';

  @override
  String get los_raisedLabel => 'Висота над землею';

  @override
  String get los_terrainOnly => 'Лише рельєф, за вашими горизонталями.';

  @override
  String los_credits(String credits) {
    return 'Висоти: $credits';
  }

  @override
  String get los_aboutTitle => 'Про пряму видимість';

  @override
  String get los_helpBody =>
      'Відповідь ґрунтується лише на рельєфі, взятому із завантажених горизонталей. Вона нічого не знає про дерева, будівлі, людей, лінії електропередачі чи інші антени, а вершина пагорба може бути до однієї горизонталі вищою, ніж намальовано.\n\n«Вільно» означає, що рельєф не заважає. Це не гарантує, що повідомлення дійде. «На межі» означає, що рельєф підходить близько до лінії. «Закрито» означає, що рельєф заважає: повідомлення ще може пройти через один невисокий хребет, але не розраховуйте на це.\n\nПеревірте це на місцевості зі своїми раціями, перш ніж покладатися на результат.';

  @override
  String los_reachShaded(String distance) {
    return 'Зафарбовано: рельєф не заважає зв\'язку з рацією в руці, до $distance.';
  }

  @override
  String get los_reachUnknownPart =>
      'Частину рельєфу не вдається розрахувати (нижче рівня моря), тому її не зафарбовано.';

  @override
  String get los_reachTapHint =>
      'Торкніться карти або імені, щоб побачити пряму видимість до цієї точки.';

  @override
  String get los_positionGuessed => 'Імовірна позиція';

  @override
  String los_positionGuessedVia(String names) {
    return 'Імовірна позиція (через $names)';
  }

  @override
  String los_lookFurther(String distance) {
    return 'Дивитися далі ($distance)';
  }

  @override
  String los_nobodyWithin(String distance) {
    return 'Нікого з розташуванням у межах $distance.';
  }

  @override
  String get offlineMaps_losContours => 'Горизонталі для прямої видимості';

  @override
  String get contacts_deleteComesBack =>
      'Радіо саме зберігає такі контакти, тому він повернеться, коли його почують наступного разу.';

  @override
  String get tray_contact => 'Контакт';

  @override
  String get shareContact_title => 'Поділитися контактом';

  @override
  String get shareContact_myContact => 'Мій контакт';

  @override
  String get regions_title => 'Регіони';

  @override
  String get regions_settingsSubtitle =>
      'Повідомлення каналу лише в одній місцевості';

  @override
  String get regions_intro =>
      'Регіон тримає повідомлення каналу на ретрансляторах, що обслуговують одну місцевість. Ретранслятор, який не знає регіону, не передасть повідомлення далі, тож використовуйте назви, які використовують ретранслятори у вашій місцевості.';

  @override
  String get regions_yourRegions => 'Ваші регіони';

  @override
  String get regions_empty =>
      'Регіонів поки немає. Додайте назву, яку використовують ретранслятори у вашій місцевості.';

  @override
  String get regions_add => 'Додати регіон';

  @override
  String get regions_nameLabel => 'Назва регіону';

  @override
  String get regions_nameHelp =>
      'Регістр важливий: SF і sf — два різні регіони.';

  @override
  String get regions_nameBadCharacter =>
      'Пробіли, крапки, коми та більшість розділових знаків не дозволені.';

  @override
  String get regions_nameTooLong => 'Задовга: не більше 30 байтів.';

  @override
  String get regions_nameExists => 'Вже є у вашому списку.';

  @override
  String regions_usedBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Використовують $count каналу',
      many: 'Використовують $count каналів',
      few: 'Використовують $count канали',
      one: 'Використовує $count канал',
      zero: 'Не використовується жодним каналом',
    );
    return '$_temp0';
  }

  @override
  String regions_deleteTitle(String name) {
    return 'Видалити $name?';
  }

  @override
  String regions_deleteInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count каналу використовують цей регіон. Вони залишаться без регіону.',
      many:
          '$count каналів використовують цей регіон. Вони залишаться без регіону.',
      few:
          '$count канали використовують цей регіон. Вони залишаться без регіону.',
      one: '$count канал використовує цей регіон. Він залишиться без регіону.',
    );
    return '$_temp0';
  }

  @override
  String get regions_radioDefault => 'Регіон радіо за замовчуванням';

  @override
  String get regions_radioDefaultHelp =>
      'Зберігається в радіо. Його використовують канали без власного регіону, особисті повідомлення та адверти, з будь-якого застосунку.';

  @override
  String get regions_none => 'Немає';

  @override
  String get regions_radioNoAnswer =>
      'Радіо не прийняло зміну. Спробуйте ще раз.';

  @override
  String get regions_inQr => 'Регіон у QR-кодах каналів';

  @override
  String get regions_inQrSubtitle =>
      'Увімкнено: QR-код каналу містить його регіон, а сканування коду встановлює регіон із нього.';

  @override
  String get regions_unsupported =>
      'Прошивка цього радіо застара для регіонів.';

  @override
  String get channelRegion_title => 'Регіон';

  @override
  String channelRegion_noneWithDefault(String name) {
    return 'Немає (за замовчуванням у радіо: $name)';
  }

  @override
  String get channelRegion_everywhere => 'Скрізь (без регіону)';

  @override
  String get channelRegion_help =>
      'Повідомлення цього каналу йдуть лише через ретранслятори, які знають його регіон.';

  @override
  String get channelRegion_manage => 'Керувати регіонами';

  @override
  String channelRegion_qrLine(String name) {
    return 'Регіон: $name';
  }

  @override
  String get repeaterRegions_subtitle => 'Які регіони передає цей ретранслятор';

  @override
  String get repeaterRegions_reading => 'Читання регіонів ретранслятора…';

  @override
  String get repeaterRegions_tooOld =>
      'Прошивка цього ретранслятора застара, щоб керувати його регіонами тут. Потрібна 1.15 або новіша.';

  @override
  String get repeaterRegions_noAnswer =>
      'Ретранслятор не відповів. Спробуйте ще раз.';

  @override
  String get repeaterRegions_noRegion => 'Повторювати повідомлення без регіону';

  @override
  String get repeaterRegions_noRegionHelp =>
      'Більшість надсилає без регіону. Якщо вимкнути, цей ретранслятор перестане передавати їхні повідомлення.';

  @override
  String get repeaterRegions_noRegionOffTitle =>
      'Перестати повторювати повідомлення без регіону?';

  @override
  String get repeaterRegions_noRegionOffBody =>
      'Усі поблизу, хто не використовує регіон, більше не повторюватимуться цим ретранслятором.';

  @override
  String get repeaterRegions_turnOff => 'Вимкнути';

  @override
  String get repeaterRegions_own => 'Власний регіон ретранслятора';

  @override
  String get repeaterRegions_ownHelp =>
      'Його використовують адверти ретранслятора, а також його відповіді, коли він не знає, у якому регіоні надійшов запит.';

  @override
  String get repeaterRegions_onRepeater => 'Регіони на цьому ретрансляторі';

  @override
  String get repeaterRegions_empty =>
      'Регіонів поки немає. Повідомлення з регіоном повторюється тут, лише коли його регіон додано.';

  @override
  String get repeaterRegions_mayBeIncomplete =>
      'Список ретранслятора довгий, і його відповідь обрізано, тож тут можуть бути не всі регіони.';

  @override
  String get repeaterRegions_repeated => 'Повторюється';

  @override
  String get repeaterRegions_notRepeated => 'Не повторюється';

  @override
  String repeaterRegions_removeTitle(String name) {
    return 'Видалити $name з ретранслятора?';
  }

  @override
  String get repeaterRegions_hasChildren =>
      'У ретранслятора ще є регіони під цим. Спочатку видаліть їх.';

  @override
  String repeaterRegions_refused(String reply) {
    return 'Ретранслятор відповів: $reply';
  }

  @override
  String get repeaterRegions_fromYours => 'З ваших регіонів';

  @override
  String get repeaterRegions_alreadyThere => 'Вже є на цьому ретрансляторі.';

  @override
  String channelRegion_qrInclude(String name) {
    return 'Додати регіон $name';
  }

  @override
  String get channelRegion_nearbyOption => 'Лише поблизу (без ретрансляторів)';

  @override
  String get channelRegion_nearby => 'Лише поблизу';

  @override
  String get channelRegion_nearbyHelp =>
      'Чують лише радіо в зоні досяжності. Надсилається один раз, без повторів.';

  @override
  String get channelRegion_nearbyTrip =>
      'Звіти TRAX у цьому каналі інші радіо далі не передаватимуть.';

  @override
  String nearbyRegions_withPlain(String names) {
    return 'Регіони: $names і повідомлення без регіону';
  }

  @override
  String nearbyRegions_only(String names) {
    return 'Регіони: лише $names, без повідомлень без регіону';
  }

  @override
  String get nearbyRegions_noneButPlain =>
      'Регіонів немає; повторює повідомлення без регіону';

  @override
  String get nearbyRegions_nothing =>
      'Нічого не повторює: ні регіонів, ні повідомлень без регіону';

  @override
  String channelRegion_carriers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ретранслятора поблизу',
      many: '$count ретрансляторів поблизу',
      few: '$count ретранслятори поблизу',
      one: '$count ретранслятор поблизу',
    );
    return '$_temp0';
  }

  @override
  String get channelRegion_noCarrier =>
      'Жоден ретранслятор поблизу його не передає';

  @override
  String get regions_heardNearby => 'Почуті від ретрансляторів поблизу';

  @override
  String regions_nearbySpelling(String name) {
    return 'Ретранслятори поблизу пишуть його як $name';
  }

  @override
  String get regions_useSpelling => 'Використати';

  @override
  String channelPath_regionUnknown(String code) {
    return 'Невідомий вам (код $code)';
  }

  @override
  String chat_channelNoSignRegion(String region) {
    return 'Надіслано в $region · немає ознак, хто отримав. Ретранслятори, які не знають $region, його відкидають.';
  }

  @override
  String get myLocation_title => 'Моє розташування';

  @override
  String get myLocation_onlyYou => 'Лише ви';

  @override
  String get myLocation_people => 'Вибрані вами люди можуть запитувати';

  @override
  String get myLocation_everyone =>
      'Усі збережені у вашому радіо можуть запитувати';

  @override
  String get myLocation_adverts => 'У ваших оголошеннях';

  @override
  String get myLocation_gpsNoFix => 'GPS увімк., позиції ще немає';

  @override
  String get myLocation_radioGps => 'GPS радіо';

  @override
  String myLocation_fix(String ago, String position) {
    return 'Позиція $ago тому · $position';
  }

  @override
  String get myLocation_noFix => 'Позиції ще немає.';

  @override
  String get myLocation_offSaves => 'Вимкнення заощаджує акумулятор.';

  @override
  String myLocation_lastFix(String time) {
    return 'Остання позиція о $time.';
  }

  @override
  String get myLocation_inAdverts => 'У моїх оголошеннях';

  @override
  String get myLocation_advertsHint => 'Будь-хто, хто чує ваше радіо';

  @override
  String get myLocation_advertsInfo =>
      'Ваші оголошення передають ваше розташування всім, хто їх чує: позицію GPS, а з вимкненим GPS — останню позицію або введене вручну розташування. Вони надсилаються, лише коли ви надсилаєте оголошення самі або це робить TRAX.';

  @override
  String get myLocation_peopleWho => 'Хто може запитувати';

  @override
  String get myLocation_nobody => 'Ніхто';

  @override
  String myLocation_allSaved(int count) {
    return 'Усі збережені у вашому радіо ($count)';
  }

  @override
  String get myLocation_pickPeople => 'Вибрати окремих людей';

  @override
  String get myLocation_batterySensors => 'Батарея й датчики';

  @override
  String get myLocation_peopleHint =>
      'Вони можуть запитати ваше радіо, де воно і який заряд його батареї.';

  @override
  String get myLocation_addSomeone => 'Додати людину';

  @override
  String myLocation_search(int count) {
    return 'Пошук серед контактів ($count)';
  }

  @override
  String get myLocation_recent => 'Останні повідомлення';

  @override
  String get myLocation_canAsk => 'Може запитувати';

  @override
  String get iconHelp_title => 'Що означають значки';

  @override
  String get iconHelp_tap => 'Торкніться значка на панелі, щоб відкрити його.';

  @override
  String get iconHelp_radio => 'Радіо';

  @override
  String get iconHelp_battery => 'Батарея радіо';

  @override
  String get iconHelp_batteryText => 'Торкніться, щоб побачити напругу.';

  @override
  String get iconHelp_signal => 'Сигнал';

  @override
  String get iconHelp_signalText =>
      'Наскільки добре ваше радіо чує найкращий ретранслятор поблизу. Торкніться, щоб відкрити список.';

  @override
  String get iconHelp_repeaters => 'Почуті ретранслятори';

  @override
  String get iconHelp_repeatersText => 'Скільки · код найкращого · як давно';

  @override
  String get iconHelp_traxOff => 'Режим TRAX вимкнено';

  @override
  String get iconHelp_traxOn => 'Режим TRAX увімкнено';

  @override
  String get iconHelp_traxOnText => 'Ваше радіо на частоті групи.';

  @override
  String get iconHelp_who => 'Моє розташування: хто його бачить';

  @override
  String get iconHelp_people => 'Вибрані вами люди';

  @override
  String get iconHelp_peopleText => 'Вони можуть запитати ваше радіо, де воно.';

  @override
  String get iconHelp_advertsText => 'Будь-хто, хто чує ваше радіо.';

  @override
  String get iconHelp_gps => 'Моє розташування: GPS радіо';

  @override
  String get iconHelp_filled => 'Зафарбований: GPS увімк.';

  @override
  String get iconHelp_outline => 'Контур: GPS вимк.';

  @override
  String get iconHelp_dashed => 'Пунктир: GPS-позиції ще немає';

  @override
  String get iconHelp_red =>
      'Червоний: позиції немає, а хтось може його бачити';

  @override
  String get locationNote_title => 'Одна кнопка розташування';

  @override
  String get locationNote_body =>
      '«GPS» і «Хто бачить моє розташування» тепер одна кнопка. Її форма показує, хто бачить ваше розташування. Зафарбована — GPS увімкнено.';

  @override
  String get traxGuide_title => 'Як працює TRAX';

  @override
  String get traxGuide_lead =>
      'TRAX показує, де всі перебувають, лише через ваші радіо: без мобільного зв\'язку, без ретрансляторів. Скажімо, ви йдете попереду, друзі — позаду, а завтра приєднаються ще люди.';

  @override
  String get traxGuide_beforeTitle => 'Перед виходом';

  @override
  String get traxGuide_before =>
      'Створіть приватний канал для поїздки. Усі приєднуються до нього, додають одне одного в контакти й один раз пишуть у ньому.';

  @override
  String get traxGuide_trailheadTitle => 'На початку маршруту';

  @override
  String get traxGuide_trailhead =>
      'Коли радіо матиме GPS-позицію, торкніться сліду черевика, а потім «Перейти на TRAX». Радіо перейде на частоту групи, а інші отримають «Теж перейти?».';

  @override
  String get traxGuide_trailTitle => 'На маршруті';

  @override
  String get traxGuide_trail =>
      'Кожен телефон раз на хвилину-дві надсилає розташування свого радіо в канал поїздки, а час від часу — і свій трек. Кнопка з трьома людьми на карті показує всіх: як далеко, у якому напрямку, коли їх чули.';

  @override
  String get traxGuide_behindTitle => 'Друзі позаду';

  @override
  String get traxGuide_behind =>
      'Кожне радіо передає повідомлення інших далі, тож їхні доходять до тих, хто попереду, через вас. Вони бачать вас на карті як ваш значок; торкання показує ваш трек, яким можна йти.';

  @override
  String get traxGuide_quietTitle => 'Хтось мовчить?';

  @override
  String get traxGuide_quiet =>
      'У їхній картці видно, коли їх востаннє чули. Запитайте їхнє радіо: воно відповідає саме, навіть із вимкненим телефоном.';

  @override
  String get traxGuide_joinTitle => 'Приєднатися наступного дня';

  @override
  String get traxGuide_join =>
      'Додайте канал поїздки. У налаштуваннях TRAX виберіть його та кінець поїздки, а також «Далекий», якщо група його використовує. Потім перемкніться. Треки всіх за останні 2 дні надходитимуть поступово.';

  @override
  String get traxGuide_sosTitle => 'SOS';

  @override
  String get traxGuide_sos =>
      'У чаті поїздки торкніться +, потім SOS. Група отримуватиме ваше розташування кожні 2 хвилини, доки ви не скасуєте.';

  @override
  String get traxGuide_endTitle => 'Коли поїздка закінчиться';

  @override
  String get traxGuide_end =>
      'MeshTrax запропонує вийти. Доки ви не вийдете, звичайна мережа mesh вас не чує.';

  @override
  String get traxGuide_iconsTitle => 'Значки';

  @override
  String get traxGuide_member => 'Учасник — у вигляді обраного ним значка';

  @override
  String get traxGuide_memberText => 'Ваш — у налаштуваннях TRAX.';

  @override
  String get traxGuide_old => 'Сірий: їхня GPS-позиція може бути застарілою';

  @override
  String get traxGuide_you => 'Ви';

  @override
  String get traxGuide_yourTrack => 'Ваш трек';

  @override
  String get traxGuide_theirTrack => 'Їхній трек, поки відкрита їхня картка';

  @override
  String get traxGuide_tripChannel => 'Канал поїздки';

  @override
  String get traxGuide_tripChannelText =>
      'Перший у списку «Чати», поки TRAX увімкнено.';

  @override
  String get traxGuide_dontShowAgain => 'Більше не показувати';
}
