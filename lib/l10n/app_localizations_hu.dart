// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hungarian (`hu`).
class AppLocalizationsHu extends AppLocalizations {
  AppLocalizationsHu([String locale = 'hu']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Csevegések';

  @override
  String get chats_title => 'Csevegések';

  @override
  String get newChat_title => 'Kapcsolat kiválasztása';

  @override
  String newChat_contactCount(int count) {
    return '$count kapcsolat';
  }

  @override
  String get newChat_newContact => 'Új kapcsolat';

  @override
  String get newChat_newChannel => 'Új csatorna';

  @override
  String get newChat_myContacts => 'Saját kapcsolatok';

  @override
  String get newChat_discovered => 'Felfedezett';

  @override
  String get repeaters_title => 'Repeaterek kezelése';

  @override
  String get nav_contacts => 'Kapcsolatok';

  @override
  String get nav_channels => 'Csatornák';

  @override
  String get nav_map => 'Térkép';

  @override
  String get common_cancel => 'Mégse';

  @override
  String get common_syncing_device_info => 'Eszközadatok beolvasása...';

  @override
  String get common_syncing_contacts => 'Kapcsolatok beolvasása...';

  @override
  String get common_syncing_channels => 'Csatornák beolvasása...';

  @override
  String get common_syncing_messages => 'Üzenetek beolvasása...';

  @override
  String get common_ok => 'Rendben';

  @override
  String get common_connect => 'Kapcsolódj';

  @override
  String get common_unknownDevice => 'Tudatlan eszköz';

  @override
  String get common_save => 'Mentés';

  @override
  String get common_delete => 'Töröl';

  @override
  String get common_deleteAll => 'Minden törlés';

  @override
  String get common_close => 'Bezárás';

  @override
  String get common_edit => 'Szerkesztés';

  @override
  String get common_add => 'Hozzáad';

  @override
  String get common_settings => 'Beállítások';

  @override
  String get common_disconnect => 'Csatlakozást megszakasztani';

  @override
  String get common_connected => 'Kapcsolódó';

  @override
  String get common_disconnected => 'Elválasztva';

  @override
  String get common_connectionLost =>
      'A kapcsolat megszakadt. Újracsatlakozás...';

  @override
  String get common_reconnecting => 'Újracsatlakozás...';

  @override
  String get common_create => 'Készítsd';

  @override
  String get common_continue => 'Folytatás';

  @override
  String get common_share => 'Ossza meg';

  @override
  String get common_copy => 'Másolat';

  @override
  String get common_retry => 'Újrapróbálja';

  @override
  String get common_hide => 'Elrejt';

  @override
  String get common_remove => 'Eltávolít';

  @override
  String get common_enable => 'Engedélyezés';

  @override
  String get common_disable => 'Leteteszt';

  @override
  String get common_reboot => 'Újraindítás';

  @override
  String get common_loading => 'Betöltés...';

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
  String get scanner_title => 'MeshCore nyitott';

  @override
  String get connectionChoiceUsbLabel => 'USB';

  @override
  String get connectionChoiceBluetoothLabel => 'Bluetooth';

  @override
  String get connectionChoiceTcpLabel => 'TCP';

  @override
  String get tcpScreenTitle => 'TCP-n keresztül kapcsolódjon';

  @override
  String get tcpHostLabel => 'IP-cím';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Múzeum';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected =>
      'Adja meg a célpontot, majd kapcsolja össze.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Kapcsolat a $endpoint-hez...';
  }

  @override
  String get tcpErrorHostRequired => 'Az IP-címet meg kell adni.';

  @override
  String get tcpErrorPortInvalid => 'Az érték 1 és 65535 között kell lennie.';

  @override
  String get tcpErrorUnsupported =>
      'A TCP-protokoll nem támogatott ez a platformon.';

  @override
  String get tcpErrorTimedOut => 'A TCP-kapcsolat időtúllépett.';

  @override
  String tcpConnectionFailed(String error) {
    return 'A TCP-kapcsolat sikertelen: $error';
  }

  @override
  String get usbScreenTitle => 'USB-en keresztül csatlakoztassuk';

  @override
  String get usbScreenSubtitle =>
      'Válasszon egy azonosított soros eszközt, és közvetlenül csatlakoztassa a MeshCore-hoz.';

  @override
  String get usbScreenStatus => 'Válasszon egy USB-es eszközt';

  @override
  String get usbScreenNote =>
      'Az USB-es soros kommunikáció a támogatott Android eszközökön és asztali rendszereken is elérhető.';

  @override
  String get usbScreenEmptyState =>
      'Nincs USB eszköz megtalálva. Csatlakoztasson egyet, majd frissítse a rendszert.';

  @override
  String get usbErrorPermissionDenied => 'A USB-es hozzáférés megtagadva.';

  @override
  String get usbErrorDeviceMissing =>
      'Az kiválasztott USB eszköz már nem elérhető.';

  @override
  String get usbErrorInvalidPort => 'Válasszon egy érvényes USB-eszközt.';

  @override
  String get usbErrorBusy =>
      'Egy másik USB-csatlakozás kérése már folyamatban van.';

  @override
  String get usbErrorNotConnected => 'Nincs csatlakoztatott USB eszköz.';

  @override
  String get usbErrorOpenFailed =>
      'Nem sikerült megnyitni a kiválasztott USB-eszközöt.';

  @override
  String get usbErrorConnectFailed =>
      'Nem sikerült kapcsolatot létesíteni a kiválasztott USB-eszközhöz.';

  @override
  String get usbErrorUnsupported =>
      'Ez a platform nem támogat USB-es soros kommunikációt.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Ebből a verzióból hiányzik az USB soros könyvtár, ezért az USB-eszközök nem nyithatók meg. Telepítse újra a MeshTraxot, vagy jelezze, hogy ez a verzió hibás.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Ez a böngésző nem támogatja a Web Serialt. Használjon Chrome-ot vagy Edge-et HTTPS-en (vagy localhoston) keresztül.';

  @override
  String get usbErrorAlreadyActive => 'Az USB-kapcsolat már be van állítva.';

  @override
  String get usbErrorNoDeviceSelected => 'Nincs kiválasztva USB eszköz.';

  @override
  String get usbErrorPortClosed => 'Az USB-kapcsolat nem aktív.';

  @override
  String get usbErrorConnectTimedOut =>
      'Kapcsolódás sikertelen. Ellenőrizze, hogy a eszköz rendelkezik-e USB-hez tartozó firmware-rel.';

  @override
  String get usbFallbackDeviceName => 'Web-szériás eszköz';

  @override
  String get usbStatus_notConnected => 'Válasszon egy USB-es eszközt';

  @override
  String get usbStatus_connecting => 'USB eszközhez való csatlakozás...';

  @override
  String get usbStatus_searching => 'USB eszközök keresése...';

  @override
  String usbConnectionFailed(String error) {
    return 'USB-kapcsolat sikertelen: $error';
  }

  @override
  String get scanner_scanning => 'Készülékek keresése...';

  @override
  String get scanner_connecting => 'Kapcsolódás...';

  @override
  String get scanner_disconnecting => 'Kapcsolat megszakad...';

  @override
  String get scanner_notConnected => 'Nem csatlakozva';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Kapcsolódik a $deviceName-hez';
  }

  @override
  String get scanner_showAllDevices => 'Minden Bluetooth-eszköz megjelenítése';

  @override
  String get scanner_showMeshCoreOnly => 'Csak MeshCore rádiók megjelenítése';

  @override
  String get scanner_radioNotResponding =>
      'A rádió nem válaszol. Lehet, hogy párosítani kell: nyissa meg a Bluetooth-beállításokat, adja hozzá a rádiót, és írja be a PIN-kódját, majd próbálja újra.';

  @override
  String get scanner_pairingFailed =>
      'A Bluetooth-párosítás megszakadt vagy sikertelen volt. Ellenőrizze, hogy semmi más (például a telefonja) ne csatlakozzon a rádióhoz, majd próbálja újra, és írja be a PIN-kódját.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Kapcsolódás sikertelen: $error';
  }

  @override
  String get scanner_stop => 'Megállj';

  @override
  String get scanner_scan => 'Szkenálás';

  @override
  String get scanner_scanFromImage => 'Beolvasás képről';

  @override
  String get scanner_noQrFoundInImage =>
      'Nem található érvényes QR-kód a képen';

  @override
  String get scanner_bluetoothOff => 'A Bluetooth kikapcsolva';

  @override
  String get scanner_bluetoothOffMessage =>
      'Kérjük, kapcsolja be a Bluetooth-ot, hogy eszközök keresése lehessen.';

  @override
  String get scanner_chromeRequired => 'Chrome böngésző szükséges';

  @override
  String get scanner_chromeRequiredMessage =>
      'Ez az alkalmazás a Bluetooth funkcióhoz Google Chrome-ot vagy Chromium alapú böngészőt igényel.';

  @override
  String get scanner_enableBluetooth => 'Engedje be a Bluetooth funkciót';

  @override
  String get device_quickSwitch => 'Gyors váltás';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Beállítások';

  @override
  String get settings_deviceInfo => 'A készülék információi';

  @override
  String get settings_appSettings => 'Alkalmazási beállítások';

  @override
  String get settings_appSettingsSubtitle =>
      'Értesítések, üzenetküldés és térképi beállítások';

  @override
  String get settings_nodeSettings => 'Műközép beállítások';

  @override
  String get settings_nodeName => 'Vonal neve';

  @override
  String get settings_nodeNameNotSet => 'Nem megállapított';

  @override
  String get settings_nodeNameHint => 'Adja meg a csomópont nevét';

  @override
  String get settings_nodeNameUpdated => 'Neve frissítve';

  @override
  String get settings_radioSettings => 'Rádióbeállítások';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvencia, teljesítmény, szélesítési tényező';

  @override
  String get settings_radioSettingsUpdated => 'A rádió beállítások frissítve';

  @override
  String get settings_location => 'Helyszín';

  @override
  String get settings_locationSubtitle => 'GPS koordináták';

  @override
  String get settings_locationUpdated =>
      'A helyzet és a GPS beállítások frissítve';

  @override
  String get settings_locationBothRequired =>
      'Kérjük, adja meg a földrajzi szélességet és hosszúságot.';

  @override
  String get settings_locationInvalid =>
      'Érvénytelen szélesszög vagy hosszszög.';

  @override
  String get settings_locationGPSEnable => 'GPS engedélyezve';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Lehetővé teszi, hogy a GPS automatikusan frissítse a helyzetet.';

  @override
  String get settings_latitude => 'Nyugat-–––––––––––––––––––––––––––––––';

  @override
  String get settings_longitude => 'hosszúság';

  @override
  String get settings_contactSettings => 'Kapcsolat beállítások';

  @override
  String get settings_contactSettingsSubtitle =>
      'Beállítások, amelyek meghatározzák, hogyan lehet új kapcsolatokat hozzáadni.';

  @override
  String get settings_privacyMode => 'Adatvédelem mód';

  @override
  String get settings_privacyModeSubtitle =>
      'Elrejtsük a nevét/a helyszínt az űrianyagokban';

  @override
  String get settings_privacyModeToggle =>
      'Engedje be a privát üzemmódot, hogy elrejtse a nevét és a helyét az online hirdetésekben.';

  @override
  String get settings_privacyModeEnabled => 'Adatvédelem mód beállítva';

  @override
  String get settings_privacyModeDisabled => 'Adatvédelem mód kikapcsolva';

  @override
  String get settings_privacy => 'Adatvédelem beállítások';

  @override
  String get settings_privacySubtitle =>
      'Ellenőrizd, hogy milyen információkat osztanak meg.';

  @override
  String get settings_privacySettingsDescription =>
      'Válassza ki, hogy az eszközének melyik információkat oszt meg másokkal.';

  @override
  String get settings_denyAll => 'Elutasítom';

  @override
  String get settings_allowByContact =>
      'Lehetővé teszi a kapcsolatok kezelését';

  @override
  String get settings_allowAll => 'Engedje meg mindent';

  @override
  String get settings_telemetryBaseMode => 'Adatkapcsolati alapállapot';

  @override
  String get settings_telemetryLocationMode => 'Adatkapcsolási helyszín mód';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Adatkapcsolati környezeti mód';

  @override
  String get settings_advertLocation => 'Reklám megjelenési hely';

  @override
  String get settings_advertLocationSubtitle =>
      'A hirdetés tartalmazza a helyszínt.';

  @override
  String get settings_multiAck => 'Többszörös visszaigazolások';

  @override
  String get settings_telemetryModeUpdated => 'A telemetriamód frissítve';

  @override
  String get settings_actions => 'Tevékenységek';

  @override
  String get settings_sendAdvertisement => 'Hirdetés küldése';

  @override
  String get settings_sendAdvertisementSubtitle => 'A nyilvános megjelenés';

  @override
  String get settings_advertisementSent => 'Hirdetés elküldve';

  @override
  String get settings_syncTime => 'Szinkronizációs idő';

  @override
  String get settings_syncTimeSubtitle =>
      'Állítsa a készülék időzítését a telefon időjére';

  @override
  String get settings_timeSynchronized => 'Időben szinkronizált';

  @override
  String get settings_refreshContacts => 'Újraindítsd a kapcsolatok listát';

  @override
  String get settings_refreshContactsSubtitle =>
      'Újra töltse a kontaktlista-adatokat a készülékről';

  @override
  String get settings_rebootDevice => 'Újraindítás';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Indítsa újra a MeshCore eszközt.';

  @override
  String get settings_rebootDeviceConfirm =>
      'Biztosan szeretné újraindítani a készüléket? Ebben az esetben a kapcsolat megszűnik.';

  @override
  String get settings_debug => 'Hibakeresés';

  @override
  String get settings_bleDebugLog => 'BLE hibaelhárítási napló';

  @override
  String get settings_bleDebugLogSubtitle =>
      'BLE parancsok, válaszok és alapvető adatok';

  @override
  String get settings_appDebugLog => 'App-debug log';

  @override
  String get settings_appDebugLogSubtitle => 'Programozási hibajelzések';

  @override
  String get settings_exportDatabase => 'Üzenetadatbázis exportálása';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Az összes csevegés és kapcsolat másolata hibakereséshez. Tartsa privátként.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Adatbázis mentve ide: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Az exportálás sikertelen: $error';
  }

  @override
  String get settings_about => 'Ról';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax $version verzió';
  }

  @override
  String get settings_aboutLegalese =>
      '2026-os MeshCore nyílt forráskódú projekt';

  @override
  String get settings_aboutDescription =>
      'Egy nyílt forráskódú Flutter kliens a MeshCore LoRa hálózati eszközök számára.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS magassági adatok: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Név';

  @override
  String get settings_infoId => 'Az azonosító';

  @override
  String get settings_infoStatus => 'Állapot';

  @override
  String get settings_infoBattery => 'Akku';

  @override
  String get settings_infoPublicKey => 'Nyelvkönyv';

  @override
  String get settings_infoContactsCount => 'Kapcsolatok száma';

  @override
  String get settings_infoChannelCount => 'Csatorna száma';

  @override
  String get settings_presets => 'Előre beállított beállítások';

  @override
  String get settings_frequency => 'Frekvencia (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 – 2500,0';

  @override
  String get settings_frequencyInvalid =>
      'Érvénytelen frekvencia (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Kapacitás';

  @override
  String get settings_spreadingFactor => 'Terjesztési tényező';

  @override
  String get settings_codingRate => 'Kódolási sebesség';

  @override
  String get settings_txPower => 'TX teljesítmény (dBm)';

  @override
  String get settings_txPowerInvalid => 'Érvénytelen TX teljesítmény';

  @override
  String get settings_clientRepeat => 'Autonóm rendszer újra';

  @override
  String get settings_clientRepeatSubtitle =>
      'Engedje, hogy ez a eszköz mások számára is ismételje a hálózati csomagokat.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'A hálózat nélküli kommunikációhoz 433, 869 vagy 918 MHz frekvenciát igényel.';

  @override
  String settings_error(String message) {
    return 'Hiba: $message';
  }

  @override
  String get appSettings_title => 'Alkalmazási beállítások';

  @override
  String get appSettings_appearance => 'Megjelenés';

  @override
  String get appSettings_theme => 'Téma';

  @override
  String get appSettings_themeSystem => 'Alapértékek';

  @override
  String get appSettings_themeLight => 'Világítás';

  @override
  String get appSettings_themeDark => 'Sötét';

  @override
  String get appSettings_language => 'Nyelv';

  @override
  String get appSettings_languageSystem => 'Alapértékek';

  @override
  String get appSettings_languageEn => 'Angol';

  @override
  String get appSettings_languageFr => 'Francia';

  @override
  String get appSettings_languageEs => 'Spanyol';

  @override
  String get appSettings_languageDe => 'Német';

  @override
  String get appSettings_languagePl => 'Lengyel';

  @override
  String get appSettings_languageSl => 'szlovén nyelv';

  @override
  String get appSettings_languagePt => 'Portugál';

  @override
  String get appSettings_languageIt => 'Olasz';

  @override
  String get appSettings_languageZh => 'Kínai';

  @override
  String get appSettings_languageSv => 'Svéd';

  @override
  String get appSettings_languageNl => 'Hollandi';

  @override
  String get appSettings_languageSk => 'Szlovén nyelvre fordítás';

  @override
  String get appSettings_languageBg => 'Bulgár';

  @override
  String get appSettings_languageRu => 'Orosz';

  @override
  String get appSettings_languageUk => 'Украинский';

  @override
  String get appSettings_enableMessageTracing =>
      'Engedje meg a üzenetek nyomon követését';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Adja meg a üzenetek részletes útvonal- és időzítési adatokat.';

  @override
  String get appSettings_senderNameColors => 'Színes feladónevek';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Minden csatornán küldő saját névszínt kap. Kikapcsolva mindenki a téma színét kapja.';

  @override
  String get appSettings_showTextFormatting => 'Szövegformázás megjelenítése';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown az üzenetekben: **félkövér**, *dőlt*, ||spoiler||, címsorok és linkek. Más MeshCore alkalmazások a nyers karaktereket mutatják.';

  @override
  String get appSettings_notifications => 'Értesítések';

  @override
  String get appSettings_enableNotifications => 'Engedélyezze az értesítéseket';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Kapjon értesítéseket üzenetekről és hirdetésekről.';

  @override
  String get appSettings_notificationPermissionDenied =>
      'A értesítési engedély megtagadva';

  @override
  String get appSettings_notificationsEnabled =>
      'A figyelmeztetések engedélyezve';

  @override
  String get appSettings_notificationsDisabled =>
      'A figyelmeztetések kikapcsolva';

  @override
  String get appSettings_messageNotifications => 'Üzenet értesítések';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'A figyelmeztetést megjelenítve, amikor új üzenet érkezik';

  @override
  String get appSettings_channelMessageNotifications =>
      'Csatorna-üzenetek értesítése';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'A figyelmeztetést megjelenítve, amikor új üzenet érkezik a csatornáról';

  @override
  String get appSettings_advertisementNotifications => 'Reklám értesítések';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'A figyelmeztetést megjelenítve, amikor új csomópontok kerülnek felfedezésre.';

  @override
  String get appSettings_messaging => 'Üzenetek küldése';

  @override
  String get appSettings_maxMessageRetries =>
      'Maximális üzenetek újraküldési próbálkozások';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'A próbálkozások száma, mielőtt egy üzenetet hibásnak jelölünk.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Csatornaüzenet max. újraküldése';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Ennyiszer próbálja újra, amíg legalább egy ismétlést nem hall';

  @override
  String get appSettings_battery => 'Akku';

  @override
  String get appSettings_batteryChemistry => 'Aakkum töltés kémia';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Beállítások $deviceName-hez';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Csatlakozzon egy eszközhez, hogy kiválassza';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2 V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2 V)';

  @override
  String get appSettings_mapDisplay => 'Térkép megjelenítése';

  @override
  String get appSettings_showRepeaters => 'Megismétlés';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'A térképen megjelenítsük a repeater-eket.';

  @override
  String get appSettings_showChatNodes => 'Megjeleníts kommunikációs pontokat';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'A chat-szobákat megjelenítsük a térképen';

  @override
  String get appSettings_showOtherNodes => 'Mutasson további csomópontokat';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mutassa meg a többi hálózati elemet a térképen';

  @override
  String get appSettings_timeFilter => 'Időbeli szűrés';

  @override
  String get appSettings_timeFilterShowAll =>
      'Mutassa meg az összes csomópontot';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mutasson az utolsó $hours órából származó adatokat.';
  }

  @override
  String get appSettings_mapTimeFilter => 'Térkép időszűrő';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Megjeleníts olyan węzveket, amelyek a következő területen lettek felfedezve:';

  @override
  String get appSettings_allTime => 'Minden időpont';

  @override
  String get appSettings_lastHour => 'Az utolsó óra';

  @override
  String get appSettings_last6Hours => 'Az utóban 6 óra';

  @override
  String get appSettings_last24Hours => 'Az utóbbi 24 óra';

  @override
  String get appSettings_lastWeek => 'A múlt héten';

  @override
  String get appSettings_unitsTitle => 'Egységek';

  @override
  String get appSettings_unitsMetric => 'Méter (m / kilométer)';

  @override
  String get appSettings_unitsImperial => 'Királyi (láb / mérföld)';

  @override
  String get appSettings_debugCard => 'Hibakeresés';

  @override
  String get appSettings_appDebugLogging =>
      'App-ban történő hibakereséshez használt naplózás';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Log alkalmazás hibaelhárítási üzenetek';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Az alkalmazás hibaelhárítási naplózás engedélyezve';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Az alkalmazás hibaelhárítási naplózatának bekapcsolása kiküszöbölve';

  @override
  String get appSettings_incrementalContactSync =>
      'Növekményes kapcsolatszinkronizálás';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Újracsatlakozáskor csak a legutóbb óta megváltozott kapcsolatokat kéri le a rádiótól';

  @override
  String get contacts_title => 'Kapcsolatok';

  @override
  String get contacts_noContacts => 'Jelenleg még nincs kapcsolat.';

  @override
  String get contacts_shareMyQrCode => 'Saját QR-kód megosztása';

  @override
  String get contacts_shareQrCodeDesc =>
      'Mások beolvashatják, hogy felvegyék Önt kapcsolatként';

  @override
  String get contacts_contactsWillAppear =>
      'A kapcsolatok megjelennek, amikor a eszközök hirdetnek.';

  @override
  String get contacts_unread => 'Olvasatlan';

  @override
  String get contacts_searchContactsNoNumber => 'Kapcsolatok keresése...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Keresés $number-ban $str…';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Keresés $number$str... Kedvencek';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Search $number$str Users...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Keresés $number-on, $str típusú adóállomások között...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Keresés $number-ban $str...';
  }

  @override
  String get contacts_noUnreadContacts => 'Nincs olvasatlan üzenetek';

  @override
  String get contacts_noContactsFound =>
      'Nincs megtalálva semmilyen kapcsolat vagy csoport.';

  @override
  String get contacts_deleteContact => 'Kapcsolattól töröl';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Biztosan törölni szeretné: $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return '$contactName kapcsolat törölve.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Nem sikerült törölni: $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Egy kapcsolat sem felel meg a szűrőnek.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Hogy töröljem a $contactName nevű személyt a kontaktlistából?';
  }

  @override
  String get contacts_manageRepeater => 'Ellenőriző eszköz kezelése';

  @override
  String get contacts_manageRoom => 'A szobai szerver kezelése';

  @override
  String get contacts_roomLogin => 'Szoba szerverbe való bejelentkezés';

  @override
  String get contacts_openChat => 'Nyitott beszélgetés';

  @override
  String get contacts_editGroup => 'Edit csoport';

  @override
  String get contacts_deleteGroup => 'Csoport törlése';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Hogy töröljem a \"$groupName\"-t?';
  }

  @override
  String get contacts_newGroup => 'Új csoport';

  @override
  String get contacts_groupName => 'Csoport neve';

  @override
  String get contacts_groupNameRequired =>
      'A csoportnak meg kell adni a nevét.';

  @override
  String get contacts_groupNameReserved => 'Ez a csoportnév foglalt';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'A \"$name\" nevű csoport már létezik.';
  }

  @override
  String get contacts_filterContacts => 'Szűrj kontaktokat...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Nincs találat a megadott szűrés alapján.';

  @override
  String get contacts_noMembers => 'Nincsenek tagok';

  @override
  String get contacts_lastSeenNow => 'utóbbi időben';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes perc';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Kb. 1 óra';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours óra';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Kb. 1 nap';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days days';
  }

  @override
  String get contact_info => 'Kapcsolattartási információk';

  @override
  String get contact_settings => 'Kapcsolat beállítások';

  @override
  String get contact_telemetry => 'Adatvisszaadás';

  @override
  String get contact_lastSeen => 'Utoljára, amikor látták';

  @override
  String get contact_clearChat => 'Csevegés törlése';

  @override
  String get contact_teleBase => 'Adatgyűjtő központ';

  @override
  String get contact_teleBaseSubtitle =>
      'Engedje meg a akkumulátor töltöttségi szintjének és alapvető adatoknak megosztását.';

  @override
  String get contact_teleLoc => 'Adatkapcsolati helyszín';

  @override
  String get contact_teleLocSubtitle => 'Engedje meg a helyadatok megosztását';

  @override
  String get contact_teleEnv => 'Adatkapcsolati környezet';

  @override
  String get contact_teleEnvSubtitle =>
      'Engedje meg az érzékelő adatok megosztását';

  @override
  String get contacts_publicKey => 'Nyilvános kulcs';

  @override
  String get channels_title => 'Csatornák';

  @override
  String get channels_noChannelsConfigured => 'Nincs konfigurált csatorna.';

  @override
  String get channels_addPublicChannel => 'Hozzon létre nyilvános csatornát';

  @override
  String get channels_searchChannels => 'Keresési opciók...';

  @override
  String get channels_noChannelsFound => 'Nincs megtalálható csatorna';

  @override
  String channels_channelIndex(int index) {
    return '$index-os csatorna';
  }

  @override
  String get channels_hashtagChannel => 'Hashtag-ok közössége';

  @override
  String get channels_public => 'A nyilvánosság számára';

  @override
  String get channels_private => 'Személyes';

  @override
  String get channels_publicChannel => 'Össztávos csatorna';

  @override
  String get channels_privateChannel => 'Személyes csatorna';

  @override
  String get channels_editChannel => 'Csatorna szerkesztése';

  @override
  String get channels_shareChannel => 'Csatorna megosztása';

  @override
  String get channels_shareChannelInstructions =>
      'Olvassa be a QR-kódot a csatorna hozzáadásához.\nMenü → Csatorna hozzáadása → Scanned egy QR-kódot';

  @override
  String get channels_secretKey => 'Titkos kulcs';

  @override
  String get channels_meshcoreUri => 'MeshCore-URI';

  @override
  String get channels_shareChannelQr => 'Csatorna QR-kódjának beolvasása';

  @override
  String get channels_shareChannelWarning =>
      'Figyelem: aki beolvassa ezt a QR-kódot, hozzáfér ehhez a csatornához.';

  @override
  String get channels_muteChannel => 'Csendes csatorna';

  @override
  String get channels_unmuteChannel => 'Engedje be a hangot';

  @override
  String get channels_deleteChannel => 'Mozdony törlése';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Törlés $name? Ez nem visszafordítható.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Nem sikerült törölni a \"$name\" nevű csatornát.';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'A \"$name\" nevű csatorna törölve';
  }

  @override
  String get channels_addChannel => 'Csatorna hozzáadása';

  @override
  String get channels_channelIndexLabel => 'Csatorna index';

  @override
  String get channels_channelName => 'Csatorna neve';

  @override
  String get channels_usePublicChannel => 'Használja a nyilvános csatornát';

  @override
  String get channels_standardPublicPsk =>
      'Általános, állami által finanszírozott PSK';

  @override
  String get channels_pskHex => 'PSK (Hexadecimális kód)';

  @override
  String get channels_generateRandomPsk => 'Véletlenszerűen generáljon PSK-t';

  @override
  String get channels_enterChannelName => 'Kérjük, adja meg egy csatorna nevét';

  @override
  String get channels_pskMustBe32Hex =>
      'A PSK 32-bázisú hexadecimális karakterből áll.';

  @override
  String get channels_addChannelConfirmation =>
      'Hozzá szeretné adni a következő csatornát?';

  @override
  String get channels_channelAddedSuccess => 'A csatorna hozzáadva.';

  @override
  String get channels_noAvailableChannelSlots => 'Nincs szabad csatornahely.';

  @override
  String get appSettings_mentionNotifications => 'Említési értesítések';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Ha valaki megemlíti Önt vagy válaszol Önnek — némított csatornákon is';

  @override
  String notification_mentionIn(String channelName) {
    return 'Említés itt: $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'A \"$name\" csatorna hozzáadva';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Módosítsd a csatornát $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ kompresszió';

  @override
  String channels_channelUpdated(String name) {
    return 'A $name csatorna frissítve';
  }

  @override
  String get channels_publicChannelAdded => 'A nyilvános csatorna hozzáadva';

  @override
  String get channels_sortBy => 'Szűrés';

  @override
  String get channels_sortManual => 'Használati útmutató';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Legfrissebb üzenetek';

  @override
  String get channels_sortUnread => 'Olvasatlan';

  @override
  String get channels_createPrivateChannel => 'Létrehoz egy privát csatornát';

  @override
  String get channels_createPrivateChannelDesc =>
      'Titkos kulcs segítségével védelem.';

  @override
  String get channels_joinPrivateChannel =>
      'Csatlakozzon egy privát csatornához';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Kézzel adja meg a titkos kulcsot.';

  @override
  String get channels_joinPublicChannel =>
      'Csatlakozzon a nyilvános csatornához';

  @override
  String get channels_joinPublicChannelDesc =>
      'Bárki csatlakozhat ehhez a csatornához.';

  @override
  String get channels_joinHashtagChannel =>
      'Csatlakozzon egy hashtage-os csatornához';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Bárkinek lehet csatlakoznia a hashtagekhez tartozó csatornához.';

  @override
  String get channels_scanQrCode => 'Scanned egy QR-kódot';

  @override
  String get channels_scanQrCodeComingSoon => 'Hamarosan';

  @override
  String get channels_enterHashtag => 'Írja be a hashtaget';

  @override
  String get channels_hashtagHint => 'pl. #csapat';

  @override
  String get chat_noMessages => 'Még nincs üzenet.';

  @override
  String get chat_sendMessage => 'Üzenet küldése';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Küldj üzenetet $contactName-nek';
  }

  @override
  String get chat_sendMessageToStart => 'Küldj egy üzenetet, hogy elindulj!';

  @override
  String get chat_originalMessageNotFound => 'A eredeti üzenet nem található.';

  @override
  String chat_replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Reply to $name';
  }

  @override
  String get chat_location => 'Helyszín';

  @override
  String get common_copiedToClipboard => 'Vágólapra másolva';

  @override
  String get common_copyToClipboard => 'Másolás a vágólapra';

  @override
  String get contacts_copyContactToClipboard =>
      'Saját kapcsolat másolása a vágólapra';

  @override
  String get chat_typeMessage => 'Írjon üzenetet...';

  @override
  String get chat_searchMessages => 'Üzenetek keresése';

  @override
  String get chat_searchNoMatches => 'Nincs találat';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'A üzenet túl hosszú (a maximális $maxBytes bájt).';
  }

  @override
  String get chat_messageCopied => 'Üzenet másolva';

  @override
  String get chat_messageDeleted => 'Üzenet törölve';

  @override
  String get chat_sendGif => 'Küldj GIF-ot';

  @override
  String get chat_reply => 'Válasz';

  @override
  String get chat_newMessages => 'ÚJ ÜZENETEK';

  @override
  String get chat_addReaction => 'Hozzon létre reakciót';

  @override
  String get chat_mention => 'Említés';

  @override
  String get dmChannel_menuLabel => 'Közvetlen üzenet';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'DM küldése: $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Ellenőrizze a kulcsot és az utolsó észlelés idejét — a nevek nem egyediek.';

  @override
  String get dmChannel_warningTitle => 'Biztosan ő az?';

  @override
  String get dmChannel_warningBody =>
      'A csatornaneveket mindenki maga választja, és bárki utánozhatja őket. Bármi bizalmas előtt ellenőrizze ennek a kapcsolatnak a nyilvános kulcsát más úton.';

  @override
  String get dmChannel_dontShowAgain => 'Ne jelenjen meg újra';

  @override
  String get batterySleep_title => 'MeshTrax futásban tartása';

  @override
  String get batterySleep_bodySamsung =>
      'A Samsung telefonok az akkumulátor kímélése érdekében elaltatják az alkalmazásokat, ami megszakítja a kapcsolatot a rádióval. Nyissa meg a Beállítások → Alkalmazások → MeshTrax → Akkumulátor menüt, és válassza a Korlátlan lehetőséget. Ellenőrizze az Akkumulátor → Háttérhasználati korlátok részt is, és győződjön meg róla, hogy a MeshTrax nem szerepel az Alvó alkalmazások vagy a Mélyen alvó alkalmazások között.';

  @override
  String get batterySleep_bodyGeneric =>
      'A telefon az akkumulátor kímélése érdekében leállíthatja a MeshTraxot a háttérben, ami megszakítja a kapcsolatot a rádióval. Nyissa meg az akkumulátor-beállításokat, és állítsa a MeshTraxot Korlátlan (vagy Nincs korlátozás) módra. Egyes telefonokon az Automatikus indítást is be kell kapcsolni a MeshTraxhoz.';

  @override
  String get batterySleep_openSettings => 'Beállítások megnyitása';

  @override
  String get batterySleep_notNow => 'Most nem';

  @override
  String get batterySleep_settingsTile => 'MeshTrax futtatása a háttérben';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Ne engedje, hogy a telefon energiatakarékos módja elaltassa a MeshTraxot';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Még nem küldhet DM-et: $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Még nincs meg a kulcsa, és neki is szüksége lesz az Önére a válaszhoz — a kulcsok csak hirdetésekben utaznak. A „Hirdetésem küldése” innen sugározza az Önét. A „Kérés a csatornán” egy kérést ír az üzenetmezőbe, amelyet Ön küldhet el.';

  @override
  String get dmChannel_askInChannel => 'Kérés a csatornán';

  @override
  String get dmChannel_sendMyAdvert => 'Hirdetésem küldése';

  @override
  String get dmChannel_askText =>
      'kérlek, küldj egy hirdetést, hogy DM-et írhassak neked';

  @override
  String get dmChannel_watching =>
      'Figyeljük a hirdetését — itt kérdezzük meg, amikor megérkezik.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name most már elérhető';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Nagyítási szint';

  @override
  String get common_reset => 'Visszaállítás';

  @override
  String get chat_reactionsTitle => 'Reakciók';

  @override
  String get chat_reactionUnknownSender => 'Ismeretlen';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender egy olyan üzenetre reagált, amely nincs ebben a csevegésben';
  }

  @override
  String get chat_me => 'Én';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Testmozgások';

  @override
  String get emojiCategoryHearts => 'Szívak';

  @override
  String get emojiCategoryObjects => 'Tárgyak';

  @override
  String get gifPicker_title => 'Válasszon egy GIF-et';

  @override
  String get gifPicker_searchHint => 'GIF-ek keresése...';

  @override
  String get gifPicker_poweredBy => 'Forrás: GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nincsenek GIF-ek megtalálva.';

  @override
  String get gifPicker_failedLoad => 'Nem sikerült betölteni a GIF-fájlokat.';

  @override
  String get gifPicker_failedSearch => 'Nem sikerült a GIF-eket megtalálni.';

  @override
  String get gifPicker_noInternet => 'Nincs internetkapcsolat.';

  @override
  String get debugLog_appTitle => 'App-debug log';

  @override
  String get debugLog_bleTitle => 'BLE hibajelentő napló';

  @override
  String get debugLog_copyLog => 'Másolat napló';

  @override
  String get debugLog_saveLog => 'Napló mentése fájlba';

  @override
  String get debugLog_saved => 'Napló mentve';

  @override
  String get debugLog_saveCancelled => 'Mentés megszakítva';

  @override
  String get debugLog_filterAll => 'Mind';

  @override
  String get debugLog_filterWarnings => 'Figyelmeztetések';

  @override
  String get debugLog_filterErrors => 'Hibák';

  @override
  String get debugLog_clearLog => 'Jelzett napló';

  @override
  String get debugLog_copied => 'Hibajelentő napló másolva';

  @override
  String get debugLog_bleCopied => 'BLE-log másolva';

  @override
  String get debugLog_noEntries =>
      'Jelenleg még nem léteznek hibaelhárítási naplókat.';

  @override
  String get debugLog_enableInSettings =>
      'Engedje be az alkalmazás hibaelhárítási naplózását a beállítások menüben.';

  @override
  String get debugLog_frames => 'Keretek';

  @override
  String get debugLog_rawLogRx => 'Az eredeti Log-RX';

  @override
  String get debugLog_noBleActivity =>
      'Jelenleg nincs BLE-hez kapcsolódó tevékenység.';

  @override
  String debugFrame_length(int count) {
    return 'Keret hossza: $count bájt';
  }

  @override
  String debugFrame_command(String value) {
    return 'Parancs: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Címzett:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Célhely: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Időbélyeg: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Jelvények: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tartalom típusa: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'Parancssori felület (CLI)';

  @override
  String get debugFrame_textTypeCliCommand => 'CLI-parancs';

  @override
  String get debugFrame_textTypePlain => 'Egyszerű, alap, hagyományos';

  @override
  String debugFrame_text(String text) {
    return '- Tartalom: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex-dump:';

  @override
  String get chat_hopSingular => 'ugor';

  @override
  String get chat_hopPlural => 'babér';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ugrások',
      one: 'ugrás',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Beállítsd a saját útvonalat';

  @override
  String get chat_fullPath => 'Teljes elérési út';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Az útvonal részletei még nem elérhetők. Próbálja meg küldeni egy üzenetet, hogy frissítse az információkat.';

  @override
  String get chat_type => 'Típus';

  @override
  String get chat_path => 'Út';

  @override
  String get chat_publicKey => 'Nyelvkönyv';

  @override
  String get chat_compressOutgoingMessages => 'A küldött üzenetek tömörítése';

  @override
  String get chat_floodForced => 'Áradás (kényszerített)';

  @override
  String get chat_directForced => 'Közvetlen (erélyes)';

  @override
  String chat_hopsForced(int count) {
    return '$count ánusz (erővel)';
  }

  @override
  String get chat_floodAuto => 'Vízosztás (autó)';

  @override
  String get chat_direct => 'Közvetlen';

  @override
  String get chat_poiShared => 'Közös erőforrás';

  @override
  String chat_unread(int count) {
    return 'Olvasatlan: $count';
  }

  @override
  String get chat_openLink => 'Nyisd meg a linket?';

  @override
  String get chat_openLinkConfirmation =>
      'Szeretnéd megnyitni ezt a linket a böngésződben?';

  @override
  String get chat_open => 'Nyitott';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Nem sikerült megnyitni a hivat: $url';
  }

  @override
  String get chat_invalidLink => 'Érvénytelen hivatkozás formátum';

  @override
  String get map_lineOfSight => 'Látási vonal';

  @override
  String get map_losScreenTitle => 'Látási vonal';

  @override
  String get map_noNodesWithLocation =>
      'Nincs olyan adatpont, amelyhez helyszín-információk tartoznak.';

  @override
  String get map_nodesNeedGps =>
      'A pontoknak meg kell osztaniuk GPS koordinátáikat, hogy megjelenjenek a térképen.';

  @override
  String map_nodesCount(int count) {
    return 'Csúcsok: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Csapok: $count';
  }

  @override
  String get map_chat => 'Csevegés';

  @override
  String get map_repeater => 'Ismétlő';

  @override
  String get map_room => 'szoba';

  @override
  String get map_sensor => 'Érzékelő';

  @override
  String get map_pinDm => 'Jel (DM)';

  @override
  String get map_pinPrivate => 'Titkos (privát)';

  @override
  String get map_pinPublic => 'Jelmez (nyilvános)';

  @override
  String get map_lastSeen => 'Utoljára látva';

  @override
  String get map_disconnectConfirm =>
      'Biztosan szeretné kiírni ezt a készüléket?';

  @override
  String get map_from => 'Attól';

  @override
  String get map_source => 'Forrás';

  @override
  String get map_flags => 'Zászló';

  @override
  String get map_shareMarkerHere => 'Osztja ezt a tartalmat itt';

  @override
  String get map_setAsMyLocation => 'Állítsa be a jelenlegi helyzetemként';

  @override
  String get map_pinLabel => 'Címkét ragasztani';

  @override
  String get map_label => 'Címke';

  @override
  String get map_pointOfInterest => 'Érdekes hely';

  @override
  String get map_sendToContact => 'Kapcsolatfelvételi űrlap';

  @override
  String get map_sendToChannel => 'Küldés a csatornán';

  @override
  String get map_noChannelsAvailable => 'Nincs elérhető csatorna.';

  @override
  String get map_publicLocationShare => 'Térköz, nyilvános hely';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Most egy helyszínt megosztasz a $channelLabel csatornán. Ez a csatorna nyilvános, és bárki, aki rendelkezik a PSK-val, megtekintheti.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Kapcsolódjon egy eszközhöz, hogy megoszthassa a vonalzókat.';

  @override
  String get map_filterNodes => 'Szűrési pontok';

  @override
  String get map_chatNodes => 'Csevegési pontok';

  @override
  String get map_repeaters => 'Újraküldők';

  @override
  String get map_otherNodes => 'Egyéb csomópontok';

  @override
  String get map_showOverlaps => 'Az ismétlő kulcsok ütköznek';

  @override
  String get map_keyPrefix => 'Kulcsfontosságú előtag';

  @override
  String get map_filterByKeyPrefix => 'Szűrj a kulcsos előtér szerint';

  @override
  String get map_publicKeyPrefix => 'Névfelhasználó kulc-prefix';

  @override
  String get map_showDiscoveryContacts =>
      'Megjelenítse a Discovery-nál elérhet kontaktokat';

  @override
  String get map_guessedLocation => 'Tippolt hely';

  @override
  String get map_lastSeenTime => 'Utoljára megjelent idő';

  @override
  String get map_sharedPin => 'Gemeinsames PIN-kód';

  @override
  String get map_joinRoom => 'Csatlakozás a szobához';

  @override
  String get map_manageRepeater => 'Ellenőriző eszköz kezelése';

  @override
  String get map_tapToAdd =>
      'Nyomj meg a csomópontokhoz, hogy hozzáadd őket az útvonalhoz.';

  @override
  String get map_runTrace => 'Útvonal követés';

  @override
  String get map_runTraceWithReturnPath => 'Visszaforduljon az eredeti úton.';

  @override
  String get map_removeLast => 'Törölj utolsó';

  @override
  String get map_pathTraceCancelled => 'Az útvonal követés megszakadt.';

  @override
  String get time_justNow => 'Most';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes perckel ezelőtt';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours óva';
  }

  @override
  String time_daysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get time_hour => 'óra';

  @override
  String get time_hours => 'órák';

  @override
  String get time_day => 'nap';

  @override
  String get time_days => 'napok';

  @override
  String get time_week => 'het';

  @override
  String get time_weeks => 'het, hetek';

  @override
  String get time_month => 'hónap';

  @override
  String get time_months => 'hónapok';

  @override
  String get time_minutes => 'percek';

  @override
  String get time_allTime => 'Bármely időpont';

  @override
  String get dialog_disconnect => 'Csatlakozást megszakasztani';

  @override
  String get dialog_disconnectConfirm =>
      'Biztosan szeretné kiírni ezt a készüléket?';

  @override
  String get login_repeaterLogin => 'Ismételt bejelentkezés';

  @override
  String get login_roomLogin => 'Szoba szerverbe való bejelentkezés';

  @override
  String get login_password => 'Jelszó';

  @override
  String get login_enterPassword => 'Adja meg a jelszót';

  @override
  String get login_savePassword => 'Mentse el a jelszót';

  @override
  String get login_savePasswordSubtitle =>
      'A jelszó biztonságosan tárolódik ezen a készüléken.';

  @override
  String get login_repeaterDescription =>
      'Adja meg a repeater (ismétítő) jelszót, hogy hozzáférhessen a beállításokhoz és az állapot információkhoz.';

  @override
  String get login_roomDescription =>
      'Adja meg a belépési kódot, hogy hozzáférhessen a beállításokhoz és az állapot információkhoz.';

  @override
  String get login_login => 'Bejelentkezés';

  @override
  String login_attempt(int current, int max) {
    return 'Megpróbálás $current/$max-adik';
  }

  @override
  String login_failed(String error) {
    return 'Belépés sikertelen: $error';
  }

  @override
  String get login_failedMessage =>
      'Belépés sikertelen. Vagy a jelszó helytelen, vagy a hálózati kapcsolat nem létesül.';

  @override
  String get common_reload => 'Újra töltés';

  @override
  String get common_clear => 'Egyértelmű';

  @override
  String get path_enterCustomPath => 'Adja meg a saját elérési útvonalat';

  @override
  String get path_currentPathLabel => 'Jelenlegi útvonal';

  @override
  String get path_hexPrefixInstructions =>
      'Adja meg a 2 karakteres hexadecimális előtagokat minden lépéshez, tagolva kommával.';

  @override
  String get path_hexPrefixExample =>
      'Példa: A1, F2, 3C (minden csomó az első részét használja a nyilvános kulcsából)';

  @override
  String get path_labelHexPrefixes => 'Út (hex-prefixek)';

  @override
  String get path_helperMaxHops =>
      'A maximális hossz 64 karakter. Minden előző rész 2 hatos számjegyből áll (1 bájt).';

  @override
  String get path_selectFromContacts =>
      'Válasszon a kontaktlista elembek közül:';

  @override
  String get path_noRepeatersFound =>
      'Nincs megtalálva semmilyen ismétlődő vagy helyiség-szolgáltató szervert.';

  @override
  String get path_customPathsRequire =>
      'Az egyedi útvonalaknak szükségük van átjáró pontokra, amelyek képesek üzeneteket továbbítani.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Érvénytelen hexadecimális előtagok: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Az út túl hosszú. A maximális engedélyezett lépések száma 64.';

  @override
  String get path_setPath => 'Útvonal meghatározása';

  @override
  String get repeater_management => 'Adatkapcsolás kezelése';

  @override
  String get room_management => 'Szoba-szerver kezelés';

  @override
  String get repeater_guest => 'Adatok a repeaterről';

  @override
  String get room_guest => 'Szoba szerver információk';

  @override
  String get repeater_managementTools => 'Menedzsmentes eszközök';

  @override
  String get repeater_guestTools => 'Vendégek számára elérhető eszközök';

  @override
  String get repeater_status => 'Állapot';

  @override
  String get repeater_statusSubtitle =>
      'Megtekintheted a repeater állapotát, statisztikáit és a környező eszközök adatait.';

  @override
  String get repeater_telemetry => 'Adatvisszaadás';

  @override
  String get repeater_telemetrySubtitle =>
      'Tekintsük a szenzorok és a rendszer állapotának adatát';

  @override
  String get repeater_cli => 'Parancssori felület (CLI)';

  @override
  String get repeater_cliSubtitle => 'Küldj parancsokat a repeaternek.';

  @override
  String get repeater_neighbors => 'Szomszédok';

  @override
  String get repeater_neighborsSubtitle =>
      'Tekintsük a nullás lépésű szomszédokat.';

  @override
  String get repeater_settings => 'Beállítások';

  @override
  String get repeater_settingsSubtitle => 'Állítsa be a repeater paramétereket';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Óra szinkronizálás bejelentkezés után';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automatikusan küldje el a \"óra szinkronizálás\" üzenetet a sikeres bejelentkezés után.';

  @override
  String get repeater_statusTitle => 'Adatkapcsolódás állapot';

  @override
  String get repeater_refresh => 'Újrafriszol';

  @override
  String get repeater_statusRequestTimeout => 'Az állapotkérés időtúlt.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Hiba a státusz betöltés közben: $error';
  }

  @override
  String get repeater_systemInformation => 'Rendszerinformációk';

  @override
  String get repeater_battery => 'Akku';

  @override
  String get repeater_clockAtLogin => 'Óra (bejelentkezéskor)';

  @override
  String get repeater_uptime => 'A rendszer elérhetősége';

  @override
  String get repeater_queueLength => 'Várakozási sor hossza';

  @override
  String get repeater_debugFlags => 'Hibakeresési beállítások';

  @override
  String get repeater_radioStatistics => 'Rádió statisztika';

  @override
  String get repeater_lastRssi => 'Utolsó RSSI érték';

  @override
  String get repeater_lastSnr => 'Utolsó SNR';

  @override
  String get repeater_noiseFloor => 'Háttérzaj szint';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Csomagok statisztikája';

  @override
  String get repeater_sent => 'Elküldve';

  @override
  String get repeater_received => 'Megérkezett';

  @override
  String get repeater_duplicates => 'Duplák';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days days ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Összesen: $total, Árvíz: $flood, Közvetlen: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Összesen: $total, Árvíz: $flood, Közvetlen: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Áradás: $flood, Közvetlen: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Összesen: $total';
  }

  @override
  String get repeater_settingsTitle => 'Adatátvisszaadási beállítások';

  @override
  String get repeater_basicSettings => 'Alapbeállítások';

  @override
  String get repeater_repeaterName => 'Adóállomás neve';

  @override
  String get repeater_repeaterNameHelper => 'Ez a repeater neve';

  @override
  String get repeater_adminPassword => 'Adminisztrátori jelszó';

  @override
  String get repeater_adminPasswordHelper => 'Teljes jogosultságú jelszó';

  @override
  String get repeater_guestPassword => 'Vendég felhasználói név/jelszó';

  @override
  String get repeater_guestPasswordHelper =>
      'Csak olvasási jogosítást biztosító jelszó';

  @override
  String get repeater_radioSettings => 'Rádióbeállítások';

  @override
  String get repeater_frequencyMhz => 'Frekvencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300–2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Adatkapacitás';

  @override
  String get repeater_spreadingFactor => 'Terjesztési tényező';

  @override
  String get repeater_codingRate => 'Kódolási sebesség';

  @override
  String get repeater_locationSettings => 'Helyszínbeállítások';

  @override
  String get repeater_latitude => 'Nyugat–keleti szélesség';

  @override
  String get repeater_latitudeHelper => 'Desztes fokok (pl. 37,7749)';

  @override
  String get repeater_longitude => 'hosszúság';

  @override
  String get repeater_longitudeHelper => 'Desztes fokok (pl. -122.4194)';

  @override
  String get repeater_features => 'Jellemzők';

  @override
  String get repeater_packetForwarding => 'Csomagok továbbítás';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Engedje, hogy a repeater továbbítsa a csomagokat.';

  @override
  String get repeater_guestAccess => 'Vendégek számára elérhető';

  @override
  String get repeater_guestAccessSubtitle =>
      'Engedje meg a vendégek számára, hogy csak olvassák a tartalmat';

  @override
  String get repeater_privacyMode => 'Adatvédelem mód';

  @override
  String get repeater_privacyModeSubtitle =>
      'Elrejtse a nevét/a helyszínt az űrlapon';

  @override
  String get repeater_advertisementSettings => 'Reklámbeállítások';

  @override
  String get repeater_localAdvertInterval => 'Helyi hirdetés időtartama';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes perc';
  }

  @override
  String get repeater_floodAdvertInterval => 'Vízosztály-hirdetés időtartama';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours óra';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Kódolt hirdetés-szünet';

  @override
  String get repeater_dangerZone => 'Veszélyzóna';

  @override
  String get repeater_rebootRepeater => 'Újraindítás';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Indítsa újra a repeater-t.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Biztosan szeretné újraindítani ezt a repeatert?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Újra generálja az azonosító kulcsot';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Új nyilvános/személyes kulcs-párt generáljon';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Ez új azonosítást fog létrehozni a repeater számára. Folytatni?';

  @override
  String get repeater_eraseFileSystem => 'Törölje a fájlrendszert';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formázza a duplázó fájlrendszert.';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'FIGYELEM: Ez törli az összes adatot a repeater-en. Ez nem visszafordítható!';

  @override
  String get repeater_eraseSerialOnly =>
      'Az Erase funkció csak a soros konzolon érhető el.';

  @override
  String repeater_commandSent(String command) {
    return 'Parancs elküldve: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Hibás parancs küldés: $error';
  }

  @override
  String get repeater_confirm => 'Beküldve';

  @override
  String get repeater_settingsSaved => 'Beállítások sikeresen mentve';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Hibás beállítások mentése: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Visszaállítás az alapértékekre';

  @override
  String get repeater_refreshRadioSettings => 'Frissítse a rádió beállításait';

  @override
  String get repeater_refreshTxPower => 'Újraindítás TX-támogatással';

  @override
  String get repeater_refreshLocationSettings =>
      'Újraindítás helyszín beállításokkal';

  @override
  String get repeater_refreshPacketForwarding =>
      'Csomagok továbbításának frissítése';

  @override
  String get repeater_refreshGuestAccess => 'Újraindítás vendégHozzáférés';

  @override
  String get repeater_refreshPrivacyMode =>
      'Visszaállítás a magánéletvédő módra';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Újraindítás hirdetés beállítások';

  @override
  String repeater_refreshed(String label) {
    return '$label frissítve';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Hiba a $label frissítés közben';
  }

  @override
  String get repeater_cliTitle => 'CLI (parancssori felület)';

  @override
  String get repeater_debugNextCommand => 'Hibakeresés, következő parancs';

  @override
  String get repeater_commandHelp => 'Segítség';

  @override
  String get repeater_clearHistory => 'Egyértelmű történet';

  @override
  String get repeater_noCommandsSent => 'Még egyik parancsot sem küldtünk.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Írja be a parancsot alább, vagy használja a gyors parancsokat.';

  @override
  String get repeater_enterCommandHint => 'Írja be a parancsot...';

  @override
  String get repeater_previousCommand => 'Előző parancs';

  @override
  String get repeater_nextCommand => 'Következő parancs';

  @override
  String get repeater_enterCommandFirst => 'Add meg először egy parancsot';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI parancssor felépítése';

  @override
  String repeater_cliCommandError(String error) {
    return 'Hiba: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Kapcsold össze a nevet';

  @override
  String get repeater_cliQuickGetRadio => 'Szerezd a rádiót';

  @override
  String get repeater_cliQuickGetTx => 'Szerezd a TX-t';

  @override
  String get repeater_cliQuickNeighbors => 'Szomszédok';

  @override
  String get repeater_cliQuickVersion => 'Verzió';

  @override
  String get repeater_cliQuickAdvertise => 'Hirdetés';

  @override
  String get repeater_cliQuickClock => 'óra';

  @override
  String get repeater_cliQuickClockSync => 'Óra szinkronizálás';

  @override
  String get repeater_cliQuickDiscovery => 'Fedezd fel a szomszédokat';

  @override
  String get repeater_cliHelpAdvert => 'Elküldi egy hirdetési csomagot';

  @override
  String get repeater_cliHelpReboot =>
      'Újraindítja a készüléket. (Kérjük, vegye figyelembe, hogy valószínűleg \"Időhiba\" üzenetet fog kapni, ami normális)';

  @override
  String get repeater_cliHelpClock =>
      'A jelenlegi időt mutatja az egyes eszközök karórája alapján.';

  @override
  String get repeater_cliHelpPassword =>
      'Új adminisztrációs jelszót állít be a eszköz számára.';

  @override
  String get repeater_cliHelpVersion =>
      'Megjeleníti a készülék verzióját és a szoftver verziószámát.';

  @override
  String get repeater_cliHelpClearStats =>
      'Visszaállítja a különböző statisztikai mérőszámokat a nullára.';

  @override
  String get repeater_cliHelpSetAf => 'Beállítja az idő-szabályozási tényezőt.';

  @override
  String get repeater_cliHelpSetTx =>
      'Beállítja a LoRa átviteli teljesítményt dBm-ben (a rendszer újraindításával alkalmazható).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Engedélyezi vagy tiltja meg a repeater szerepet ezen a csomón.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Szoba szerver) Ha \"igen\", akkor üres jelszóval történő bejelentkezés engedélyezett lesz, de nem lehet üzeneteket küldeni a szobában. (Csak olvasási funkció)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Beállítja a bejövő adatcsomagok maximális számát (ha ez a érték nagyobb vagy egyenlő a maximális értékkel, a csomag nem továbbítódik).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Beállítja az interferencia határértéket (dB-ben). Az alapérték 14. Ha 0-ra állítja, kiküntheti a csatornák közötti interferencia detektálást.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Beállítja az intervallumot, amely a \"Automatikus gain\" szabályozó újraindításához szükséges. Beállítás értéke 0, ha a funkciót le kell tiltani.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Engedélyezi vagy kikapcsolja a „dupla visszaigazolás” funkciót.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Beállítja az időzítő intervallumot percenként, hogy egy helyi (nincs átjáró) hirdetési csomagot küldjen. Beállítás értéke 0, ha a funkciót le szeretné tiltani.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Beállítja az időzítő intervallumot órában, hogy egy \"áramló\" hirdetési üzenetet küldjön. Beállítás értéke 0, ha a funkciót kikapcsolni kell.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Beállítja/frissíti a vendég felhasználói fiókot. (Ez lehetővé teszi a visszatérő felhasználók számára, hogy a \"Statistika lekérdezése\" kérést elküldjék)';

  @override
  String get repeater_cliHelpSetName => 'Megadja az űrlap neve.';

  @override
  String get repeater_cliHelpSetLat =>
      'Beállítja az hirdetés térképen megjelenő pont koordinátájának (tizedes fokokban) a latitude-ját.';

  @override
  String get repeater_cliHelpSetLon =>
      'Beállítja az hirdetés térképen megjelenő hosszúság koordinátát (tizedes fokokban).';

  @override
  String get repeater_cliHelpSetRadio =>
      'Teljesen új rádióparamétereket állít be, és azokat a beállításokba menti. Az alkalmazásához \"újraindítás\" parancs szükséges.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Beállítások (kísérleti): Alapérték (legalább 1 értékre kell állítani, hogy hatás legyen), amely alapján a fogadott csomagokhoz enyhe késést alkalmazunk, a jelet ereje/pontszám alapján. 0-ra állítva a funkciót lekapcsoljuk.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Beállítja egy tényezőt, amely a légköri idővel szorozva, egy áramlás-üzem módú csomaghoz, valamint egy véletlenszerű slot-rendszerhez, hogy késleltesse a továbbítását. (az ütközések valószínűségének csökkentése érdekében)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Hasonló a txdelay-hez, de ebben az esetben egy véletlenszerű késést alkalmazunk a közvetlen módú csomagok továbbításakor.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Engedélyez/Tiltás a híd funkciójának.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Állíts be egy késleztatást a csomagok újbóli továbbításakor.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Döntse el, hogy a híd fogadott vagy elküldött csomagokat fogja-e továbbítani.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Állítsa be a soros kommunikáció sebességét az RS232 hídok számára.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Állítsa be a titkos kapcsolatot az ESPNOW hídokhoz.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Lehetővé teszi a felhasználónak, hogy egyedi tényezőt állíts be a riportolt akkumulátor feszültségének módosításához (ez csak bizonyos alkatrészeken támogatott).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Időjárás szerinti rádióparamétereket állít be a megadott időtartamra, majd visszaállítja az eredeti beállításokat. (Nem menti a beállításokat a beállítások részben).';

  @override
  String get repeater_cliHelpSetPerm =>
      'A ACL-t módosítja. Ha a \"permissions\" érték 0, akkor eltávolítja a megfelelő bejegyzést (a pubkey előtag alapján). Új bejegyzést hoz létre, ha a pubkey-hex teljes hossza, és jelenleg nem szerepel az ACL-ben. A bejegyzést frissíti a megfelelő pubkey előtag alapján. A engedélyek különbözőek a különböző firmware szerepek között, de az alsó 2 bit a következő értékeket képviseli: 0 (Vendég), 1 (Csak olvasás), 2 (Olvasás és írás), 3 (Adminisztrátor)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Kapcsolatok: hid típusú, RS232, ESPNOW';

  @override
  String get repeater_cliHelpLogStart =>
      'Elindítja a csomagok naplózását a fájlrendszerbe.';

  @override
  String get repeater_cliHelpLogStop =>
      'Megállítja a csomagok naplózását a fájlrendszerbe.';

  @override
  String get repeater_cliHelpLogErase =>
      'Törli a fájlrendszerből a csomagok log-fájljait.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Mutat egy listát, amely tartalmazza a más repeater-ek által hallott adatok listáját, amelyek 0-hop hirdetések révén érhetők el. Minden sor az alábbi formát követi: id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Törli az első, a megadott kulcs-prefix (hexadecimális formában) alapján megegyező bejegyzést a szomszédok listájából.';

  @override
  String get repeater_cliHelpRegion =>
      '(sorozat) Lista az összes meghatározott területet és a jelenlegi árvízvédelmi engedélyeket.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'FIGYELEM: ez egy speciális, több parancsot tartalmazó futtatás. Minden következő parancs egy területtel kapcsolatos, amely egyenletes szóközökkel (a szülő-gyermek kapcsolatot jelző) megkülönböztethető. A parancs végrehajtása egy üres sor/parancs küldésével történik.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Keresések egy adott név előtérrel (vagy \"*\" globális hatókörre). Válasz: \"-> region-név (szülő-név) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Hozzáad vagy frissíti egy régió definíciót megadott néven.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Eltávolítja a megadott nevet használó régió-definíciót. (pontosan meg kell egyeznie, és nem lehet gyermekrégiója)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Beállítja a megadott területre vonatkozó \"víz\" jogosultságot. (A globális/régi beállítások esetén a \"*\" jelölő)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Eltávolítja a megadott területre vonatkozó \"F\"lood (víz) engedélyt. (FIGYELEM: jelenleg nem javasolt ezt a globális/régi verzióban használni!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Visszaállítja a jelenlegi „otthoni” régiót. (Ez a beállítás még nem került alkalmazásra, csak jövőbeli használatra fenyelve)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Beállítja a \"házi\" régiót.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Megőrzi a régió listát/térképet a tárolóban.';

  @override
  String get repeater_cliHelpGps =>
      'Megadja a GPS állapotát. Ha a GPS kikapcsolva van, akkor csak \"ki\" választot ad, ha be van, akkor \"be\", \"állapot\", \"pozíció\", \"satellitok száma\" értékeket ad.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Engedi a GPS működés állapotát.';

  @override
  String get repeater_cliHelpGpsSync =>
      'A hálózati időt az GPS óra időjével szinkronizálja.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Beállítja a węsz pozícióját GPS koordináták alapján, és menti a beállításokat.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Adja meg a hirdetés konfigurációjának helyszín-információját:\n- none: ne tartalmazza a helyszínt a hirdetésekben\n- share: megosztja a GPS-helyszínt (SensorManager-ből)\n- prefs: hirdeti a beállításokban tárolt helyszínt';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Beállítja a hirdetés helyszín-specifikus beállításait.';

  @override
  String get repeater_commandsListTitle => 'Parancsok listája';

  @override
  String get repeater_commandsListNote =>
      'FIGYELEM: a különböző \"set ...\" parancsok mellett létezik egy \"get ...\" parancs is.';

  @override
  String get repeater_general => 'Általános';

  @override
  String get repeater_settingsCategory => 'Beállítások';

  @override
  String get repeater_bridge => 'Híd';

  @override
  String get repeater_logging => 'Naplózás';

  @override
  String get repeater_neighborsRepeaterOnly =>
      'Szomszédok (Csak ismétlő funkció)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Regionális menedzsment (Csak egyirányú kommunikáció)';

  @override
  String get repeater_regionNote =>
      'Region-specifikus parancsokat vezettek be a régiók definiálására és a hozzájuk tartozó engedélyek kezelésére.';

  @override
  String get repeater_gpsManagement => 'GPS-vezérlés';

  @override
  String get repeater_gpsNote =>
      'Az GPS-al kapcsolatos funkciók lehetővé teszik a helyszín-személyesítéssel kapcsolatos feladatok kezelését.';

  @override
  String get telemetry_receivedData => 'Kapott adatokat a szenzorokról';

  @override
  String get telemetry_requestTimeout => 'Az adatkapcsolati kérés sikertelen.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Hiba az adatok begyűjtésében: $error';
  }

  @override
  String get telemetry_noData => 'Nincsenek elérhető telemetriadatok.';

  @override
  String telemetry_channelTitle(int channel) {
    return '$channel csatorna';
  }

  @override
  String get telemetry_batteryLabel => 'Akku';

  @override
  String get telemetry_voltageLabel => 'Feszültség';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU hőmérséklet';

  @override
  String get telemetry_temperatureLabel => 'Hőmérséklet';

  @override
  String get telemetry_currentLabel => 'Jelenlegi';

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
    return '$celsius °C / $fahrenheit °F';
  }

  @override
  String get neighbors_receivedData => 'Kapott szomszédok adatait';

  @override
  String get neighbors_requestTimedOut =>
      'A szomszédok kérik, hogy tiltsák le a kamerát.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Hiba a szomszédok betöltésében: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ismétlő eszközök, szomszédok';

  @override
  String get neighbors_noData => 'Nincsenek elérhető szomszédokról adatok.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Tudatlan $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Értsd: $time sitten';
  }

  @override
  String get channelPath_title => 'Csomagok útvonala';

  @override
  String get channelPath_viewMap => 'Megtekinthető térkép';

  @override
  String get channelPath_otherObservedPaths => 'Egyéb megfigyelt utak';

  @override
  String get channelPath_repeaterHops => 'Adat továbbító lépések';

  @override
  String get channelPath_noHopDetails =>
      'Ez a csomag nem tartalmaz részletes információkat a \"hop\" (vagy más hasonló) szót használó kifejezésekről.';

  @override
  String get channelPath_messageDetails => 'Üzenet részletei';

  @override
  String get channelPath_senderLabel => 'Megküldő';

  @override
  String get channelPath_timeLabel => 'Idő';

  @override
  String get channelPath_repeatsLabel => 'Ismétli';

  @override
  String channelPath_pathLabel(int index) {
    return 'Útvonal $index';
  }

  @override
  String get channelPath_observedLabel => 'Megfigyelt';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Megfigyelt útvonal: $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Nincs helyszínadat.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Megfejt';

  @override
  String get channelPath_floodPath => 'Árvíz';

  @override
  String get channelPath_directPath => 'Közvetlen';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0-ból $total';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed of $total hops';
  }

  @override
  String get channelPath_mapTitle => 'Útvonal térkép';

  @override
  String get channelPath_noRepeaterLocations =>
      'Ez a útvonal nem támogat repeater-t.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Útvonal $index (Elsődleges)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Út';

  @override
  String get channelPath_observedPathHeader => 'Megfigyelt útvonal';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Ez a csomag nem tartalmaz részletes információkat a szállításhoz.';

  @override
  String get channelPath_unknownRepeater => 'Tudatlan erősítő';

  @override
  String get community_title => 'Helyi közösség';

  @override
  String get community_create => 'Teremtsd meg a közösséget';

  @override
  String get community_createDesc =>
      'Légyon létre egy új közösséget, és osszák meg QR-kód segítségével.';

  @override
  String get community_join => 'Csatlakozjon';

  @override
  String get community_joinTitle => 'Csatlakozzon a közösséghez';

  @override
  String community_joinConfirmation(String name) {
    return 'Szeretne csatlakozni a közösséghez, $name?';
  }

  @override
  String get community_scanQr => 'QR-kód olvasó a közösség számára';

  @override
  String get community_scanInstructions =>
      'Fordítsa a kamerát egy közösségi QR-kód irányába.';

  @override
  String get community_showQr => 'Megjelenítse a QR-kódot';

  @override
  String get community_publicChannel => 'Összetartó, közösségi';

  @override
  String get community_hashtagChannel => 'Helyi hashtaget';

  @override
  String get community_name => 'Helyi közösség neve';

  @override
  String get community_enterName => 'Kérjük, a közösség nevét írja be.';

  @override
  String community_created(String name) {
    return 'A \"$name\" nevű közösség létrehozva';
  }

  @override
  String community_joined(String name) {
    return 'Csatlakozott a $name közösséghez';
  }

  @override
  String get community_qrTitle => 'Osszpontosítás a közösségben';

  @override
  String community_qrInstructions(String name) {
    return 'Scanned this QR-kódot, hogy csatlakozhat a $name csoporthoz.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'A közösségi hashtagekhez tartozó csatornák csak a közösség tagjai számára érhetők el.';

  @override
  String get community_invalidQrCode => 'Érvénytelen közösségi QR-kód';

  @override
  String get community_alreadyMember => 'Már tag vagy';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Már tagja $name-nek.';
  }

  @override
  String get community_addPublicChannel =>
      'Hozzon létre egy közösségi nyilvános csatornát';

  @override
  String get community_addPublicChannelHint =>
      'Automatikusan hozzon létre ezt a csatornát a közösség számára.';

  @override
  String get community_noCommunities => 'Még egyik közösség sem csatlakozott.';

  @override
  String get community_scanOrCreate =>
      'Scelle egy QR-kódot, vagy hozzon létre egy közösséget, hogy elinduljon.';

  @override
  String get community_manageCommunities => 'Közösségek kezelése';

  @override
  String get community_delete => 'Hagyományos közösségi élet';

  @override
  String community_deleteConfirm(String name) {
    return 'Hagyom $name-et?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Ezem törli is $count csatornát és a hozzá tartozó üzeneteket.';
  }

  @override
  String community_deleted(String name) {
    return 'A közösség, amely $name';
  }

  @override
  String get community_regenerateSecret => 'Titkos visszaállítás';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Újra kell generálni a titkos kulcsot $name számára? Minden tagnak be kell szkennelnie az új QR-kódot, hogy továbbra is kommunikálhasson.';
  }

  @override
  String get community_regenerate => 'Újraalakítás';

  @override
  String community_secretRegenerated(String name) {
    return 'Titkos kulcs megújult $name számára.';
  }

  @override
  String get community_updateSecret => 'Frissítési titok';

  @override
  String community_secretUpdated(String name) {
    return 'Titkos információ frissítve $name számára';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scanned a új QR-kódot, hogy frissítsük a $name számára megőrzött titkos információt.';
  }

  @override
  String get community_addHashtagChannel => 'Adjon egy közösségi hashtaget';

  @override
  String get community_addHashtagChannelDesc =>
      'Hozz létre egy hashtage-os csatornát ennek a közösségnek';

  @override
  String get community_selectCommunity => 'Válasszon közösséget';

  @override
  String get community_regularHashtag => 'Rendszeres hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Önmagas szintű hashtaget (bárki csatlakozhat)';

  @override
  String get community_communityHashtag => 'Helyi hashtaget';

  @override
  String get community_communityHashtagDesc => 'Csak a közösség tagjai számára';

  @override
  String community_forCommunity(String name) {
    return '$name számára';
  }

  @override
  String get listFilter_tooltip => 'Szűrés és rendezés';

  @override
  String get listFilter_sortBy => 'Szűrés';

  @override
  String get listFilter_latestMessages => 'Legfrissebb üzenetek';

  @override
  String get listFilter_heardRecently => 'Úgy hallottam, hogy...';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Szűrők';

  @override
  String get listFilter_source => 'Forrás';

  @override
  String get listFilter_saved => 'Mentett';

  @override
  String get listFilter_discovered => 'Felfedezett';

  @override
  String get listFilter_all => 'Mind';

  @override
  String get listFilter_favorites => 'Kedvencek';

  @override
  String get listFilter_addToFavorites => 'Megerősítés kívánságlistára';

  @override
  String get listFilter_removeFromFavorites => 'Törölj a kedvencekből';

  @override
  String get listFilter_users => 'Felhasználók';

  @override
  String get listFilter_repeaters => 'Újraküldők';

  @override
  String get listFilter_roomServers => 'Szoba-szolgálatok';

  @override
  String get listFilter_unreadOnly => 'Csak olvasatlan';

  @override
  String get listFilter_newGroup => 'Új csoport';

  @override
  String get pathTrace_you => 'Te';

  @override
  String get pathTrace_failed => 'A útvonal követése sikertelen.';

  @override
  String get pathTrace_notAvailable =>
      'Az útvonal követési funkció nem elérhető.';

  @override
  String get pathTrace_refreshTooltip => 'Út mentesség frissítése.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Egy vagy több búzavirág hiányozik a helyszínéről!';

  @override
  String get pathTrace_clearTooltip => 'Egyértelmű út.';

  @override
  String get losSelectStartEnd =>
      'Válassza ki a kezdő és a végpontokat a LOS-hoz.';

  @override
  String losRunFailed(String error) {
    return 'A látószög ellenőrzése sikertelen: $error';
  }

  @override
  String get losClearAllPoints => 'Teljesen tisztázzuk az összes pontot';

  @override
  String get losRunToViewElevationProfile =>
      'Használja a LOS-t, hogy megtekinthesse a magasságkülönbségek diagramját.';

  @override
  String get losMenuTitle => 'LOS menü';

  @override
  String get losMenuSubtitle =>
      'A térképen található pontok kiválasztására vagy a térképen hosszúra nyomva, hogy egyedi pontokat definiálhassunk.';

  @override
  String get losShowDisplayNodes => 'Megjelenítsen a megjelenítési egységeket';

  @override
  String get losCustomPoints => 'Egyedi pontok';

  @override
  String losCustomPointLabel(int index) {
    return 'Egyedi $index';
  }

  @override
  String get losPointA => 'A pont A';

  @override
  String get losPointB => 'Pont B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenna A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenna B: $value $unit';
  }

  @override
  String get losRun => 'Futtass a LOS-on';

  @override
  String get losNoElevationData => 'Nincsenek emelkedési adatok.';

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
    return '$distance $distanceUnit, amelyet $obstruction akadályoz meg $heightUnit-ban';
  }

  @override
  String get losStatusChecking => 'LOS: ellenőrzés...';

  @override
  String get losStatusNoData => 'LOS: nincs adat';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total tisztított, $blocked blokkolt, $unknown ismeretlen';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Az alábbi minták esetében nem áll rendelkezésre magasságadat.';

  @override
  String get losErrorInvalidInput =>
      'Hibás vagy hiányos táblázatok a LOS (Loss of Signal) számításához.';

  @override
  String get losRenameCustomPoint => 'Állítsa meg a saját pont nevét';

  @override
  String get losPointName => 'Pont neve';

  @override
  String get losShowPanelTooltip => 'Megjelenítse a LOS paneelt';

  @override
  String get losHidePanelTooltip => 'Rejtse el a LOS paneelt';

  @override
  String get losElevationAttribution =>
      'Magasságadatok: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radio Horizont';

  @override
  String get losLegendLosBeam => 'LOS jelzés';

  @override
  String get losLegendTerrain => 'Terület';

  @override
  String get losFrequencyLabel => 'Hatósság';

  @override
  String get losFrequencyInfoTooltip => 'Lásd a számítás részleteit';

  @override
  String get losFrequencyDialogTitle =>
      'A rádióhullámok hatótávolságának kiszámítása';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'A $baselineK értékből kezdve, $baselineFreq MHz-os frekvencián, a számítás az aktuális $frequencyMHz MHz-os sávhoz igazítja a k-tényezőt, amely meghatározza a görbös rádióhatótávolság határát.';
  }

  @override
  String get contacts_pathTrace => 'Útvonal követése';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Az útvonal követése a repeaterig';

  @override
  String get contacts_repeaterPing => 'Ping-szinkronizáló';

  @override
  String get contacts_roomPathTrace => 'Kapcsolat a szobai szerverrel';

  @override
  String get contacts_roomPing => 'Ping-szolgáló szerver';

  @override
  String get contacts_chatTraceRoute => 'Útvonal meghatározása';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Keresse meg a $name címét.';
  }

  @override
  String get contacts_clipboardEmpty => 'A kiválasztott szöveg üres.';

  @override
  String get contacts_invalidAdvertFormat => 'Érvénytelen kontaktinformáció';

  @override
  String get contacts_contactImported => 'Kapcsolat létrejött.';

  @override
  String get contacts_contactImportFailed =>
      'Nem sikerült a kapcsolatot importálni.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name már szerepel a névjegyeid között.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Zero Hop reklám';

  @override
  String get contacts_floodAdvert => 'Árvízre vonatkozó hirdetés';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Másolja a hirdetést a kiválasztási ablakba';

  @override
  String get contacts_addContactFromClipboard =>
      'Adjon hozzá egy kapcsolatot a kiválasztott listából';

  @override
  String get contacts_ShareContact => 'Másolja a kapcsolatot a kiválasztóba';

  @override
  String get contacts_ShareContactZeroHop =>
      'Ossza meg a kapcsolatot hirdetés segítségével';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Kapcsolatot a hirdetésen keresztül.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Nem sikerült a kapcsolatot elküldeni.';

  @override
  String get contacts_contactAdvertCopied => 'A hirdetés másolva a vágólapra.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Az hirdetés másolása a vágólapra sikertelen.';

  @override
  String get contacts_addContact => 'Kapcsolat hozzáadása';

  @override
  String get contacts_scanQrCode => 'Kapcsolat QR-kódjának beolvasása';

  @override
  String get contacts_scanQrCodeDesc =>
      'Kapcsolat QR-kódjának beolvasása a MeshCore alkalmazásból';

  @override
  String get contacts_enterIdHash => 'Kapcsolat kézi megadása';

  @override
  String get contacts_enterIdHashDesc =>
      'Illesszen be egy kapcsolathirdetést vagy meshcore:// linket';

  @override
  String get contacts_advertHint =>
      'meshcore://... vagy nyilvános kulcs hexben';

  @override
  String get contacts_import => 'Importálás';

  @override
  String get contacts_scanContactInstructions =>
      'Olvasson be egy MeshCore kapcsolat-QR-kódot';

  @override
  String get notification_activityTitle => 'MeshCore tevékenységek';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'üzenetek',
      one: 'üzenet',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'csatornaüzenetek',
      one: 'csatornaüzenet',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'új csomópontok',
      one: 'új csomópont',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Új $contactType megtalálva';
  }

  @override
  String get notification_receivedNewMessage => 'Új üzenetet kaptam';

  @override
  String get settings_gpxExportRepeaters =>
      'Külső eszközök / helyi szerver a GPX formátumba';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportálható repeater/szobaterm-szerver, amely egy GPX fájlban tárolja a helyzetet.';

  @override
  String get settings_gpxExportContacts => 'GPX export funkciók';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Az export funkció lehetővé teszi, hogy a GPS fájlban megadott helyszínen is megőrizzük az útvonalat.';

  @override
  String get settings_gpxExportAll =>
      'Exportálja az összes kapcsolatot GPX formátumban.';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Az összes elérhetőséget, amelyekhez egy helyszín tartozik, egy GPX fájlba exportálja.';

  @override
  String get settings_gpxExportSuccess =>
      'A GPX fájl sikeresen exportálva lett.';

  @override
  String get settings_gpxExportNoContacts => 'Nincs exportálható kapcsolatok.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Nem támogatott a jelenlegi eszközön/rendszeren.';

  @override
  String get settings_gpxExportError => 'Hiba történt az export során.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Adatátvisszaadó eszközök és helyiségi szerverek helyei';

  @override
  String get settings_gpxExportChat => 'Kapcsolódó helyszínek';

  @override
  String get settings_gpxExportAllContacts => 'Az összes kapcsolat helyszíne';

  @override
  String get settings_gpxExportShareText =>
      'A MeshTrax-ból exportált térkéadatumok';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax GPX formátumú térképi adatok export';

  @override
  String get snrIndicator_nearByRepeaters => 'Helyszíni erősítők';

  @override
  String get snrIndicator_lastSeen => 'Utoljára, amikor látták';

  @override
  String get contactsSettings_title => 'Kapcsolatok beállításai';

  @override
  String get contactsSettings_autoAddTitle => 'Automatikus felfedezés';

  @override
  String get contactsSettings_otherTitle =>
      'Egyéb kapcsolattal kapcsolatos beállítások';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automatikus felhasználói hozzáadás';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Engedje, hogy a segítő automatikusan hozzáadja az új felhasználókat.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automatikus visszatöltés';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Engedje, hogy a segítő eszköz automatikusan hozzáadja az új, megtalált jelzőállomásokat.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automatikus szobák szerverek hozzáadása';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Engedje, hogy a segítő automatikusan hozzáadja az új, megtalált hálózati szervereket.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automatikus érzékelők hozzáadása';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Engedje, hogy a kísérő automatikusan hozzáadja az új, megtalált szenzorokat.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Felülírja a legrégebbet';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Amikor a névsor telítődik, a legidősebb, de még nem kedvencként jelölt személyt helyettesíti egy újabb.';

  @override
  String get discoveredContacts_Title => 'Megtalált kapcsolatok';

  @override
  String get discoveredContacts_noMatching => 'Nincs megegyező kapcsolat.';

  @override
  String get listFilter_searchHint => 'Keresés...';

  @override
  String get discoveredContacts_searchHint => 'Keress új kapcsolatokat';

  @override
  String get discoveredContacts_contactAdded => 'Kapcsolat hozzáadva';

  @override
  String get discoveredContacts_addContact => 'Adjon személyhez';

  @override
  String get discoveredContacts_copyContact =>
      'Másolja a kapcsolatot a vágólapra';

  @override
  String get discoveredContacts_deleteContact =>
      'Törölj a feltalált kapcsolatot';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Törölj minden megtalált kapcsolatot';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Biztos, hogy szeretné törölni az összes eddig megtalált kapcsolatot?';

  @override
  String get chat_sendCooldown =>
      'Kérjük, várjon egy pillanatot, mielőtt újra elküldené.';

  @override
  String get chat_notConnected =>
      'Nincs rádióhoz csatlakozva. Az üzenet nem lett elküldve.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Jelentkezzen az legörebb, olvasatlan üzenetre';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Amikor egy új csevet indítunk, amelyben vannak olvashatatlan üzenetek, görgessük a listát, hogy a legelső, olvashatatlan üzenet megjelenjen, nem pedig az utolsó.';

  @override
  String get appSettings_languageHu => 'Magyar';

  @override
  String get appSettings_languageJa => 'Japán';

  @override
  String get appSettings_languageKo => 'Koreai';

  @override
  String get radioStats_screenTitle => 'Rádió statisztikák';

  @override
  String get radioStats_notConnected =>
      'Csatlakozzon egy eszközhöz, hogy megtekinthesse a rádió adatok statisztikáit.';

  @override
  String get radioStats_firmwareTooOld =>
      'A rádió statisztikákhoz v8 vagy újabb verziójú szoftver szükséges.';

  @override
  String get radioStats_waiting => 'Adatokra vár…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Háttérzaj szint: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Utolsó RSSI érték: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Utolsó SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX-es idő (összesen): $seconds másodperc';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX használat időtartama (összesen): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Háttérzaj szint (dBm) a legutóbbi minták alapján.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Háttérzaj szint: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Rádió adatok begyűjtése…';

  @override
  String get radioStats_settingsTile => 'Rádió statisztikák';

  @override
  String get radioStats_settingsSubtitle =>
      'Háttérzaj, RSSI, zaj-sűrűség, és a használat időtartama';

  @override
  String get translation_title => 'Fordítás';

  @override
  String get translation_enableTitle => 'Engedje meg a fordítást';

  @override
  String get translation_enableSubtitle =>
      'Fordítsa az érkező üzeneteket, és lehetővé tegye a küldés előtti fordítást.';

  @override
  String get translation_composerTitle => 'Fordítsa el, mielőtt elküldi';

  @override
  String get translation_composerSubtitle =>
      'Ellenőrzi a zeneszerző fordítási ikon alapértékét.';

  @override
  String get translation_targetLanguage => 'Célnyelv';

  @override
  String get translation_useAppLanguage =>
      'Használja az alkalmazás nyelvének beállítását.';

  @override
  String get translation_downloadedModelLabel => 'Letöltött modell';

  @override
  String get translation_presetModelLabel =>
      'Előre definiált Hugging Face-modell';

  @override
  String get translation_manualUrlLabel => 'Manuális modell URL';

  @override
  String get translation_downloadModel => 'Letöltés';

  @override
  String get translation_downloading => 'Letöltés...';

  @override
  String get translation_working => 'Munkában vagyok...';

  @override
  String get translation_stop => 'Halt';

  @override
  String get translation_mergingChunks =>
      'A letöltött részek összeállítása a végleges fájlba...';

  @override
  String get translation_downloadedModels => 'Letöltött modelok';

  @override
  String get translation_deleteModel => 'Törölje a modellt';

  @override
  String get translation_modelDownloaded => 'Fordítási modell letöltve.';

  @override
  String get translation_downloadStopped => 'A letöltés leállt.';

  @override
  String translation_downloadFailed(String error) {
    return 'Letöltés sikertelen: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Addon először egy modell URL-t.';

  @override
  String get scanner_linuxPairingShowPin => 'Megjelenítse a PIN-kódot';

  @override
  String get scanner_linuxPairingHidePin => 'Rejtse el a PIN-kódot';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth párosítási PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Adja meg a(z) $deviceName PIN-kódját (hagyja üresen, ha nincs).';
  }

  @override
  String get translation_messageTranslation => 'Üzenet fordítása';

  @override
  String get translation_translateBeforeSending =>
      'Fordítsa el, mielőtt elküldi';

  @override
  String get translation_composerEnabledHint =>
      'A üzenetek fordítását a küldés előtt elvégezzük.';

  @override
  String get translation_composerDisabledHint =>
      'Küldj üzeneteket az eredeti, nyomtatott nyelven.';

  @override
  String translation_translateTo(String language) {
    return 'Fordítás $language-ra';
  }

  @override
  String get translation_translationOptions => 'Fordítási lehetőségek';

  @override
  String get translation_systemLanguage => 'Rendszer nyelvé';

  @override
  String get routing_title => 'Útvonalválasztás';

  @override
  String routing_route(String route) {
    return 'Tárolt útvonal: $route';
  }

  @override
  String get routing_noRoute =>
      'még nincs — a következő üzenet elárasztással megy, és tanul egyet';

  @override
  String get routing_auto => 'Automatikus';

  @override
  String get routing_autoSubtitle =>
      'A rádió tárolt útvonalát használja. Ajánlott.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder bekapcsolva: először a tanult útvonalakat próbálja';

  @override
  String get routing_flood => 'Mindig elárasztás';

  @override
  String get routing_floodSubtitle => 'Minden üzenet az egész hálózatra kimegy';

  @override
  String get routing_custom => 'Egyéni útvonal';

  @override
  String get routing_customSubtitle => 'A repeatereket Ön választja ki';

  @override
  String get routing_forget => 'Útvonal törlése';

  @override
  String get routing_forgetDone =>
      'Útvonal törölve. A következő üzenet elárasztással megy, és újat tanul.';

  @override
  String get routing_pathfinder => 'Amit a Pathfinder tud';

  @override
  String get routing_pathfinderSubtitle =>
      'Repeaterek, amelyek Önt és őt hallják, valamint tanult útvonalak oda és vissza';

  @override
  String get path_direct => 'Közvetlen — repeaterek nélkül';

  @override
  String get path_directSubtitle =>
      'Csak ha a kapcsolat közvetlenül hallja ezt a rádiót';

  @override
  String get chat_kindFlood => 'elárasztás';

  @override
  String get chat_kindDirect => 'közvetlen';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ugrás',
      one: 'ugrás',
    );
    return 'útvonal ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ugrás',
      one: 'ugrás',
    );
    return 'útvonal ($count $_temp0, ebből $guessed tippelt)';
  }

  @override
  String get chat_statusQueued => 'Sorban áll';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Egy repeater sem hallotta. Újra próbálja, amikor lesz egy hatótávon belül.';

  @override
  String chat_narrowHashNotice(String name) {
    return '$name rádiója rövid repeaterkódokat küld (1 bájt). A Pathfinder addig nem tud útvonalat tanulni hozzá, amíg a rádiója nem használ 2 bájtos kódokat.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Küldés · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Újrapróbálás · $kind · $attempt. kísérlet ($max közül)';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Kézbesítve · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Kézbesítve, $attempt. kísérlet · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Későn kézbesítve · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Kézbesítve · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'kísérlet',
      one: 'kísérlet',
    );
    return 'Sikertelen $attempts $_temp0 után · koppintson az újraküldéshez';
  }

  @override
  String get chat_statusFailedShort =>
      'Sikertelen · koppintson az újraküldéshez';

  @override
  String get chat_resendingByFlood => 'Újraküldés elárasztással';

  @override
  String get pathfinderHelp_title => 'Mit csinál a Pathfinder?';

  @override
  String get pathfinderHelp_what =>
      'A rádiója minden kapcsolatához egyetlen útvonalat jegyez meg, és ha ez az útvonal nem működik, az üzenetet az egész hálózatra kiküldi. A Pathfinder mindent figyel, amit a rádió hall: a repeaterek hirdetményeit, a csatornákon folyó csevegést, mások üzeneteit. Ebből térképet készít arról, mely repeaterek hallják egymást, melyek hallják Önt, és melyek hallják az egyes kapcsolatait.';

  @override
  String get pathfinderHelp_how =>
      'Üzenetküldéskor a Pathfinder először a legjobb útvonalát próbálja, aztán a következő legjobbat, és csak végső megoldásként küldi az üzenetet az egész hálózatra. A borostyánsárga útvonal-ikon a Pathfinder-útvonalon küldött üzenetet jelöli.';

  @override
  String get pathfinderHelp_learning =>
      'Időre van szüksége. Egy friss térkép még semmit sem tud, ezért eleinte az üzenetei pontosan úgy mennek ki, mint korábban. Miután néhány órán át egy helyen figyelt, elkezd útvonalakat ajánlani, és minden sikeres vagy sikertelen kézbesítésből tovább tanul. Az első napon ne várjon tőle sokat, és akkor sem, amikor új helyre megy.';

  @override
  String get pathfinderHelp_guessed =>
      'Néha egy hiányzó szakaszt tippeléssel pótol: olyan összeköttetéssel, amelynek eddig csak az ellenkező irányú forgalmát hallotta. Ilyenkor az üzenet alatti sor azt is mutatja, hány ugrást tippelt. A sikeres kézbesítés igazolja ezeket; a kudarc egy kísérletbe kerül, és semmit sem jegyez meg belőle.';

  @override
  String get pathfinderHelp_discover =>
      'Ha nem biztos benne, mely repeaterek hallják Önt az adott helyen, a Pathfinder egyetlen rövid Discover-kérést küld (legfeljebb 10 percenként egyszer, és csak sikertelen küldés után), és ha a rádióban van GPS, ezen a telefonon megjegyzi, mely repeaterek hallották Önt az egyes, kb. 500 m-es területeken – a pontos helyét azonban soha.';

  @override
  String get pathfinderHelp_off =>
      'Ha kikapcsolja a Pathfindert, a rádió pontosan úgy választ útvonalat, mint korábban.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Ne jelenjen meg többé';

  @override
  String get pathfinderHelp_ok => 'Rendben';

  @override
  String get settings_pathGraph => 'Pathfinder (kísérleti)';

  @override
  String get settings_pathGraphSubtitle =>
      'Útvonalakat tanul mindenből, amit a rádió hall, és DM küldésekor először a legjobbakat próbálja. A borostyánsárga útvonal-ikon a Pathfinder-útvonalon küldött üzenetet jelöli.';

  @override
  String get map_routeAndTrace => 'Útvonal és követés';

  @override
  String get map_pathfinderTrace => 'Követés oda-vissza';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Oda a Pathfinder legjobb útvonalán, vissza a legjobb visszaúton';

  @override
  String get map_routeBackMirrored =>
      'Még nincs ismert visszaút — ugyanazon az úton jön vissza';

  @override
  String get map_traceHelpTitle => 'Útvonalkövetés gombjai';

  @override
  String get map_traceHelpCustom =>
      'Írja be vagy válassza ki a repeatereket saját maga.';

  @override
  String get map_traceHelpRun =>
      'Követést küld a megérintett repeatereken át, egy irányba.';

  @override
  String get map_traceHelpThereAndBack => 'Oda-vissza';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Elküldi a követést, majd fordított sorrendben ugyanazokon a repeatereken hozza vissza.';

  @override
  String get map_traceHelpPathfinder =>
      'A Pathfinder kiválasztja a legjobb útvonalat az utoljára megérintett két repeateren át, és a legjobb visszautat Önhöz. Az eredményből a Pathfinder megtanulja, mely összeköttetések működnek valóban. Két megérintett repeater kell hozzá.';

  @override
  String get map_traceHelpRemoveLast =>
      'Leveszi az utolsó repeatert az útvonalról.';

  @override
  String get map_traceHelpCancel =>
      'Leállítja a követés összeállítását. Addig látszik, amíg nem érint meg egy repeatert sem.';

  @override
  String get chat_resendingByRoute => 'Újraküldés a beállított útvonalon';

  @override
  String get room_mute => 'Szoba némítása';

  @override
  String get room_unmute => 'Szoba némításának feloldása';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'tag';

  @override
  String get room_roleReadOnly => 'csak olvasás';

  @override
  String room_clockOff(int minutes) {
    return 'A szoba órája kb. $minutes perccel eltér — az üzenetek időpontjai hibásak lehetnek';
  }

  @override
  String get room_fixClock => 'Óra igazítása';

  @override
  String get room_clockSyncSent => 'Órajel-szinkron elküldve a szobának';

  @override
  String get room_readOnlyNotice =>
      'Csak olvasás: a szoba nem fogadta el a jelszavad, az üzeneteid nem jutnak el a többi taghoz.';

  @override
  String get room_postAnnouncement => 'Közlemény küldése';

  @override
  String get room_postAnnouncementSubtitle =>
      'Üzenet küldése a szoba nevében minden tagnak';

  @override
  String get room_announcementSent => 'Közlemény közzétéve';

  @override
  String get room_announcementFailed => 'A közlemény közzététele nem sikerült';

  @override
  String get room_users => 'Szoba felhasználói';

  @override
  String get room_usersSubtitle =>
      'Adminok megtekintése és szerepek beállítása';

  @override
  String get room_usersAdminsNote =>
      'A szoba csak az adminjait listázza. A szobajelszóval belépett tagok nem jelennek meg.';

  @override
  String get room_usersLoadFailed => 'Az adminlista betöltése nem sikerült';

  @override
  String get room_setUserRole => 'Szerep beállítása';

  @override
  String get room_removeAccess => 'Hozzáférés megvonása';

  @override
  String get room_removeOnlyUnknown =>
      'Ez a felhasználó nincs a névjegyeid között — csak eltávolítani lehet, módosítani nem.';

  @override
  String get room_roleUpdated => 'Szerep frissítve';

  @override
  String get room_roleUpdateFailed => 'A szerep módosítása nem sikerült';

  @override
  String get room_postsStored => 'Tárolt bejegyzések';

  @override
  String get room_postsDelivered => 'Kézbesített bejegyzések';

  @override
  String get room_reloadPosts => 'Friss bejegyzések újratöltése';

  @override
  String get room_reloadPostsExplain =>
      'Megkéri a szobát, hogy küldje el újra a friss bejegyzéseket (legfeljebb 32-t tárol). A szoba jelszavát kérni fogja. A meglévő üzenetek megmaradnak.';

  @override
  String get room_reloadFailed =>
      'A szobát nem sikerült visszaállítani a rádión';

  @override
  String get companionCli_title => 'Parancssor';

  @override
  String get companionCli_settingsSubtitle =>
      'Szöveges parancsok ennek a rádiónak';

  @override
  String get companionCli_rebooting => 'A rádió újraindul…';

  @override
  String get companionCli_cancelled => 'Megszakítva';

  @override
  String get companionCli_poweringOff => 'A rádió kikapcsol…';

  @override
  String get companionCli_noReply => 'Nem válaszol a rádió. Próbálja újra.';

  @override
  String get companionCli_powerOffTitle => 'Kikapcsolja a rádiót?';

  @override
  String get companionCli_powerOffBody =>
      'Kikapcsolva marad, amíg meg nem nyomja a gombját, vagy áramra nem köti.';

  @override
  String get companionCli_powerOff => 'Kikapcsolás';

  @override
  String get companionCli_quickBoard => 'Alaplap';

  @override
  String get companionCli_quickWifiStatus => 'Wi‑Fi-állapot';

  @override
  String get companionCli_quickWifiAddress => 'Wi‑Fi-cím';

  @override
  String get companionCli_helpBoard =>
      'Megmutatja az alaplap gyártóját és típusát.';

  @override
  String get companionCli_helpReboot => 'Újraindítja a rádiót.';

  @override
  String get companionCli_helpPowerOff => 'Kikapcsolja a rádiót.';

  @override
  String get companionCli_helpSetPin =>
      'Beállítja a Bluetooth-párosítás PIN-kódját. Újraindítás után lép életbe.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Beállítja, hány órát adjon az UTC-hez a rádió saját kijelzőjén lévő óra (-12 és +14 között).';

  @override
  String get companionCli_helpSetTx =>
      'Beállítja az adóteljesítményt dBm-ben. Azonnal érvényes.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Beállítja az interferenciaküszöböt dB-ben. A 0 kikapcsolja az interferenciaészlelést.';

  @override
  String get companionCli_helpSetCad =>
      'Adás előtt figyeli, adnak-e más rádiók (csatornaaktivitás-észlelés).';

  @override
  String get companionCli_helpSetRxGain =>
      'Megnövelt vételi erősítés SX126x rádiókon.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bájt repeaterenként egy útvonalban: 0 = 1 bájt, 1 = 2 bájt, 2 = 3 bájt.';

  @override
  String get companionCli_helpWifiStatus =>
      'Megmutatja, hogy a rádió csatlakozik-e a Wi‑Fi-hálózathoz.';

  @override
  String get companionCli_helpWifiIp =>
      'Megmutatja a rádió címét a Wi‑Fi-hálózaton.';

  @override
  String get companionCli_helpWifiSsid =>
      'Beállítja a Wi‑Fi-hálózat nevét. Újraindítás után lép életbe.';

  @override
  String get companionCli_helpWifiPwd =>
      'Beállítja a Wi‑Fi-jelszót. Újraindítás után lép életbe.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Be- (1) vagy kikapcsolja (0) a Wi‑Fi-t. Újraindítás után lép életbe.';

  @override
  String get companionCli_helpWifiClear =>
      'Elfelejti a Wi‑Fi-hálózatot. Újraindítás után lép életbe.';

  @override
  String get companionCli_remoteNoReply =>
      'Nincs válasz. A másik rádiónak 1.18-as vagy újabb firmware kell, és engedélyeznie kell, hogy Ön használja a parancssorát.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Elküldve. A rádió nem válaszol újraindításra vagy kikapcsolásra.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name megpróbálta használni a rádiója parancssorát: „$command”. Nem volt engedélyezve.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Megpróbálta használni a rádiója parancssorát: „$command”. Nem volt engedélyezve.';
  }

  @override
  String get contact_remoteCli => 'Távoli parancssor engedélyezése';

  @override
  String get contact_remoteCliSubtitle =>
      'Ez a kapcsolat parancsokat futtathat az Ön rádióján';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Engedi, hogy $name irányítsa a rádióját?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name módosíthatja a rádió beállításait, kiolvashatja a Wi‑Fi-jelszavát, átnevezheti a rádióját, valamint újraindíthatja vagy kikapcsolhatja. Csak olyannak engedélyezze, akiben teljesen megbízik.';
  }

  @override
  String get contact_remoteCliAllow => 'Engedélyezés';

  @override
  String get connection_secondApp =>
      'Egy másik alkalmazás is csatlakozik ehhez a rádióhoz. Az üzenetek és a beállítások összekeveredhetnek. Zárja be a másik alkalmazást.';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => 'Hálózat, jelszó és kapcsolat';

  @override
  String get wifi_use => 'Wi‑Fi használata';

  @override
  String get wifi_networkName => 'Hálózat neve';

  @override
  String get wifi_password => 'Jelszó';

  @override
  String get wifi_passwordUnchanged => 'Változatlan';

  @override
  String get wifi_showPassword => 'Jelszó megjelenítése';

  @override
  String get wifi_nameMissing => 'Adja meg a hálózat nevét';

  @override
  String get wifi_nameTooLong =>
      'A hálózat neve túl hosszú (legfeljebb 32 bájt)';

  @override
  String get wifi_passwordTooLong => 'A jelszó túl hosszú (legfeljebb 63 bájt)';

  @override
  String get wifi_savedRestart =>
      'Mentve. A Wi‑Fi-módosítások a rádió újraindítása után lépnek életbe.';

  @override
  String get wifi_forget => 'Hálózat elfelejtése';

  @override
  String get wifi_forgetConfirm =>
      'Elfelejti ezt a Wi‑Fi-hálózatot? A rádió újraindítás után nem használja tovább a Wi‑Fi-t.';

  @override
  String wifi_notAccepted(String reply) {
    return 'A rádió ezt nem fogadta el: $reply';
  }

  @override
  String get wifi_noReply => 'Nem válaszol a rádió. Próbálja újra.';

  @override
  String get wifi_restartTitle => 'Újraindítja a rádiót?';

  @override
  String get wifi_later => 'Később';

  @override
  String get wifi_loadFailed =>
      'Nem sikerült beolvasni a Wi‑Fi-beállításokat a rádióról.';

  @override
  String wifi_connectedTo(String address) {
    return 'Csatlakozva · $address';
  }

  @override
  String get wifi_notConnected => 'Nincs Wi‑Fi-kapcsolat';

  @override
  String wifi_portNote(int port) {
    return 'Az azonos hálózaton lévő alkalmazások ezen a porton csatlakozhatnak: $port';
  }

  @override
  String get wifi_connectOverWifi => 'Csatlakozás Wi‑Fi-n';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'A MeshTrax bontja a kapcsolatot ezzel a rádióval, és megnyitja a TCP képernyőt kitöltött címmel ($address) és porttal ($port). Ott koppintson a „Kapcsolódj” gombra.';
  }

  @override
  String get wifi_noteRestart =>
      'A módosítások a rádió újraindítása után lépnek életbe.';

  @override
  String get wifi_noteSecurity =>
      'A Wi‑Fi-hálózatán bárki csatlakozhat a rádióhoz az 5000-es porton. Ehhez nincs jelszó.';

  @override
  String get wifi_noteBattery =>
      'A Wi‑Fi ébren tartja a rádiót, így az akkumulátor gyorsabban lemerül.';

  @override
  String get wifi_noteWrongPassword =>
      'Ha a jelszó hibás, a rádió néhány másodpercenként újrapróbálkozik. A Bluetooth továbbra is működik.';

  @override
  String get room_selfDemoteWarning =>
      'A saját hozzáférésedet módosítod. Ha lemondasz az admin szerepről, csak a szoba saját konzolja adhatja vissza.';

  @override
  String get scanner_offlineMaps => 'Offline térképek';

  @override
  String get appSettings_offlineMaps => 'Offline térképek';

  @override
  String get appSettings_offlineMapsNone => 'Nincs letöltve';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count régió',
      one: '1 régió',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tengeri térképterület',
      one: '1 tengeri térképterület',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count frissítés érhető el',
      one: '1 frissítés érhető el',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly => 'Térképletöltés csak Wi‑Fi-n';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'A térképletöltések Wi‑Fi-kapcsolatra várnak';

  @override
  String get offlineMaps_title => 'Offline térképek';

  @override
  String get offlineMaps_tabMaps => 'Térképek';

  @override
  String get offlineMaps_tabCharts => 'Tengeri';

  @override
  String get offlineMaps_chartsNotice => 'Navigációra nem alkalmas · Miért?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Javasolt · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast =>
      'Tengeri térképterületek partszakaszonként';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terület',
      one: '1 terület',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '$count letöltve';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '$count kijelölve';
  }

  @override
  String get offlineMaps_selectAll => 'Az összes kijelölése';

  @override
  String get offlineMaps_clearSelection => 'Törlés';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Itt is: $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Még nem érhető el';

  @override
  String get offlineMaps_chartsHint =>
      'A NOAA tengeri térképei partszakasz szerint választhatók ki, a Tengeri lapon.';

  @override
  String offlineMaps_chartsName(String area) {
    return '$area – NOAA tengeri térképek';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count terület',
      one: '1 terület',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Letöltött';

  @override
  String get offlineMaps_refresh => 'Új térképek keresése';

  @override
  String get offlineMaps_loading => 'Elérhető térképek betöltése…';

  @override
  String get offlineMaps_serverError => 'A térképszerver nem érhető el';

  @override
  String get offlineMaps_unavailable => 'Még nincsenek elérhető térképek';

  @override
  String get offlineMaps_unavailableHint => 'Nézzen vissza később.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Még nincsenek elérhető NOAA tengeri térképek';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'A lista állapota: $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Frissítse a MeshTraxot a legújabb térképekhez.';

  @override
  String get offlineMaps_world => 'Világ';

  @override
  String get offlineMaps_suggested => 'Javasolt';

  @override
  String get offlineMaps_regions => 'Régiók';

  @override
  String offlineMaps_regionsIn(String name) {
    return '$name régiói';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count benne';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size offline térkép ezen az eszközön';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Frissítések ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Összes frissítése $size';
  }

  @override
  String get offlineMaps_downloading => 'Letöltés';

  @override
  String get offlineMaps_update => 'Frissítés';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Letöltve: $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Frissítés érhető el';

  @override
  String get offlineMaps_otherFiles => 'Egyéb térképfájlok';

  @override
  String get offlineMaps_emptyTitle => 'Még nincsenek offline térképek';

  @override
  String get offlineMaps_emptyBody =>
      'Töltsön le egy régiót, hogy kapcsolat nélkül is használhassa a térképet.';

  @override
  String get offlineMaps_findMaps => 'Térképek keresése';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Törli: $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Ez $size helyet szabadít fel. Később újra letöltheti.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name törölve';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done / $total';
  }

  @override
  String get offlineMaps_kindMap => 'Térkép';

  @override
  String get offlineMaps_kindMapDetail =>
      'OpenStreetMap utcák, ösvények, helyek';

  @override
  String get offlineMaps_kindContours => 'Szintvonalak';

  @override
  String get offlineMaps_kindContoursDetail => 'Magassági vonalak';

  @override
  String get offlineMaps_kindUsgs => 'USGS topográfiai térkép';

  @override
  String get offlineMaps_kindUsgsDetail =>
      'Ösvények, patakok, védett területek';

  @override
  String get offlineMaps_kindTerrain => 'Domborzatárnyékolás';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Dombok és hegyek, árnyékolva a térkép alatt';

  @override
  String get offlineMaps_kindCharts => 'NOAA tengeri térképek';

  @override
  String get offlineMaps_usOnly => 'Csak az Egyesült Államok';

  @override
  String offlineMaps_download(String size) {
    return 'Letöltés $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Letöltés';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Nagy letöltés ($size). Használjon Wi‑Fi-t, és tartsa töltőn az eszközt.';
  }

  @override
  String get offlineMaps_waiting => 'Várakozás…';

  @override
  String get offlineMaps_checking => 'Letöltés ellenőrzése…';

  @override
  String get offlineMaps_retrying => 'Újrapróbálás…';

  @override
  String offlineMaps_failed(String error) {
    return 'Sikertelen letöltés: $error';
  }

  @override
  String get offlineMaps_pause => 'Szünet';

  @override
  String get offlineMaps_resume => 'Folytatás';

  @override
  String get offlineMaps_deleteRegion => 'Régió törlése';

  @override
  String get offlineMaps_notInCatalogue => 'Ehhez a régióhoz nem érhető el';

  @override
  String get offlineMaps_notificationRunning => 'Térkép letöltése';

  @override
  String get offlineMaps_notificationPaused => 'Térképletöltés szüneteltetve';

  @override
  String get offlineMaps_notificationFailed => 'Sikertelen térképletöltés';

  @override
  String get offlineMaps_clearTileCache =>
      'Gyorsítótárazott online térképcsempék törlése';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Törli a böngészés közben mentett online térképcsempéket? A letöltött térképek megmaradnak.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Gyorsítótárazott online térképcsempék törölve';

  @override
  String get map_notForNavigation => 'Navigációra nem alkalmas';

  @override
  String get map_chartsNoticeIntro =>
      'A MeshTrax a NOAA tengeri térképadataiból rajzolja ezeket a térképeket, hogy lássa a vizet a rádiói körül, és tervezni tudjon. Ezek nem hivatalos tengeri térképek. Ne navigáljon ezek alapján.';

  @override
  String get map_chartsNoticeWhy => 'Miért:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Elavulnak. A NOAA folyamatosan javítja a térképeit; a letöltött térkép változatlan marad, amíg nem frissíti az Offline térképek alatt.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Kimaradnak dolgok. Sok térképjel, fényszektor és megjegyzés nincs megrajzolva, és egyes feliratok csak nagyításkor jelennek meg.';

  @override
  String get map_chartsNoticePositions =>
      'A pozíciók hibásak vagy elavultak lehetnek. A GPS 10 m (30 ft) vagy nagyobb hibával is mérhet, és egy csomópont csak ott van, ahonnan utoljára jelentkezett.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'A MeshTrax nem tanúsított térképplotter.';

  @override
  String get map_chartsNoticeUse =>
      'Navigációhoz hivatalos, naprakész NOAA tengeri térképeket használjon (papíron, vagy NOAA ENC-ket tanúsított térképplotteren) a legfrissebb hajózási hirdetményekkel.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail => 'Töltsön le egy régiót a részletekhez';

  @override
  String get map_zoomInForOfflineMap =>
      'Nagyítson rá az offline térkép megtekintéséhez';

  @override
  String get map_noCharts => 'Itt nincs tengeri térkép';

  @override
  String get map_myLocation => 'Saját helyzet';

  @override
  String get map_zoomIn => 'Nagyítás';

  @override
  String get map_zoomOut => 'Kicsinyítés';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS be';

  @override
  String get gps_off => 'GPS ki';

  @override
  String get gps_onHint => 'A rádió a GPS-ből frissíti a pozícióját.';

  @override
  String get gps_offHint =>
      'Kikapcsolva kíméli a rádió akkumulátorát. Bekapcsolás után néhány percig is tarthat, amíg megtalálja a pozícióját.';

  @override
  String get gps_asking => 'A rádió lekérdezése...';

  @override
  String get gps_noPosition =>
      'Még nincs pozíció. Szabad ég alatt az első néhány percig is eltarthat.';

  @override
  String get gps_position => 'Pozíció';

  @override
  String get gps_altitude => 'Magasság';

  @override
  String gps_readAgo(String ago) {
    return '$ago ezelőtt kiolvasva a rádióból';
  }

  @override
  String get gps_turnOnTitle => 'Bekapcsolja a GPS-t?';

  @override
  String get gps_turnOnBody =>
      'A rádió GPS-e ki van kapcsolva. Bekapcsolás után néhány percig is tarthat, amíg megtalálja a pozícióját.';

  @override
  String get gps_turnOn => 'Bekapcsolás';

  @override
  String get gps_notNow => 'Most nem';

  @override
  String get map_zoomInForCharts =>
      'Nagyítson rá a tengeri térképek megtekintéséhez';

  @override
  String map_downloadRegion(String region, String size) {
    return '$region letöltése · $size';
  }

  @override
  String get mapLayers_title => 'Térképrétegek';

  @override
  String get mapLayers_mapType => 'Térképtípus';

  @override
  String get mapLayers_standard => 'Normál';

  @override
  String get mapLayers_usgs => 'USGS topográfiai';

  @override
  String get mapLayers_charts => 'Tengeri térképek';

  @override
  String get mapLayers_notDownloaded => 'Nincs letöltve';

  @override
  String get mapLayers_offlineOnly => 'Csak offline';

  @override
  String get mapLayers_details => 'Térkép részletei';

  @override
  String get mapLayers_contours => 'Szintvonalak';

  @override
  String get mapLayers_hillShading => 'Domborzatárnyékolás';

  @override
  String get mapLayers_dark => 'Sötét térkép';

  @override
  String get mapLayers_downloadedAreas => 'Letöltött területek';

  @override
  String get mapLayers_nodes => 'Csomópontok';

  @override
  String get mapLayers_pins => 'Jelölők';

  @override
  String get mapLayers_guessed => 'Becsült';

  @override
  String get mapLayers_moreFilters => 'További szűrők';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Utoljára látva, kulcselőtag, átfedések';

  @override
  String get map_legend => 'Jelmagyarázat';

  @override
  String get scanner_map => 'Térkép';

  @override
  String get structured_openMap => 'Térkép megnyitása';

  @override
  String get structured_addToCalendar => 'Hozzáadás a naptárhoz';

  @override
  String get structured_details => 'Részletek';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Esemény';

  @override
  String get structured_notice => 'Közlemény';

  @override
  String get structured_allDay => 'Egész nap';

  @override
  String get structured_calendarFailed => 'Nem sikerült megnyitni a naptárt';

  @override
  String get structured_today => 'Ma';

  @override
  String get structured_tomorrow => 'Holnap';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nap múlva',
      one: '1 nap múlva',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Elmúlt';

  @override
  String structured_dayOfDays(int day, int total) {
    return '$day. nap ($total közül)';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nap',
      one: '1 nap',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Befejezés dátuma';

  @override
  String get dialog_eventSameDay => 'Ugyanaznap';

  @override
  String get structured_map => 'Térkép';

  @override
  String get structured_navigate => 'Navigálás';

  @override
  String get structured_channel => 'Csatorna';

  @override
  String get structured_contact => 'Kapcsolat';

  @override
  String get structured_room => 'Szoba';

  @override
  String get structured_repeater => 'Repeater';

  @override
  String get structured_sensor => 'Érzékelő';

  @override
  String get structured_joinChannel => 'Csatlakozás a csatornához';

  @override
  String get structured_addContact => 'Kapcsolat hozzáadása';

  @override
  String get structured_addRoom => 'Szoba hozzáadása';

  @override
  String get structured_addRepeater => 'Repeater hozzáadása';

  @override
  String get structured_addSensor => 'Érzékelő hozzáadása';

  @override
  String get structured_open => 'Megnyitás';

  @override
  String get structured_added => 'Hozzáadva';

  @override
  String get tray_add => 'Hozzáadás';

  @override
  String get tray_myLocation => 'Saját helyzet';

  @override
  String get tray_pointOnMap => 'Pont a térképen';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Esemény';

  @override
  String get tray_notice => 'Közlemény';

  @override
  String get tray_noRadioPosition =>
      'A rádiójának még nincs pozíciója. Válasszon egyet a térképen.';

  @override
  String get dialog_insert => 'Beszúrás';

  @override
  String get dialog_eventTitle => 'Cím';

  @override
  String get dialog_eventDate => 'Dátum';

  @override
  String get dialog_eventStart => 'Kezdés';

  @override
  String get dialog_eventEnd => 'Befejezés';

  @override
  String get dialog_eventNoEnd => 'Nincs befejezési idő';

  @override
  String get dialog_eventPlace => 'Helyszín (nem kötelező)';

  @override
  String get dialog_pickOnMap => 'Kiválasztás a térképen';

  @override
  String get dialog_sosTitle => 'SOS küldése';

  @override
  String get dialog_sosText => 'Mi történt?';

  @override
  String get dialog_noticeTitle => 'Közlemény';

  @override
  String get dialog_noticeText => 'Mit kell mindenkinek tudnia?';

  @override
  String get dialog_labelTitle => 'Pont a térképen';

  @override
  String get dialog_note => 'Megjegyzés (nem kötelező)';

  @override
  String get paste_convertLocation =>
      'Térképlinknek tűnik. Átalakítja Helyszínné?';

  @override
  String get paste_convertEvent =>
      'Naptármegosztásnak tűnik. Átalakítja Eseménnyé?';

  @override
  String get paste_convert => 'Átalakítás';

  @override
  String get paste_resolving => 'Link feloldása…';

  @override
  String get paste_resolveFailed => 'Nem sikerült feloldani a linket';

  @override
  String get pinned_dismiss => 'Elvetés';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Csatlakozik ehhez a csatornához: $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Már tagja ennek a csatornának: $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Csatlakozott: $name';
  }

  @override
  String get map_pickPositionHint =>
      'Koppintson a térképre egy pozíció kiválasztásához';

  @override
  String get map_legendMesh => 'Mesh-hálózat';

  @override
  String get chartLegend_title => 'Tengeri térképjelek';

  @override
  String get chartLegend_sectionBuoys => 'Bóják és fix jelek';

  @override
  String get chartLegend_sectionLights => 'Fények';

  @override
  String get chartLegend_sectionHazards => 'Veszélyek';

  @override
  String get chartLegend_sectionTides => 'Árapály és áramlások';

  @override
  String get chartLegend_sectionDepths => 'Mélységek és tengerfenék';

  @override
  String get chartLegend_sectionAreas => 'Területek, sávok és vonalak';

  @override
  String get chartLegend_sectionLandmarks => 'Tájékozódási pontok';

  @override
  String get chartLegend_sectionAbbreviations => 'Rövidítések';

  @override
  String get chartLegend_chartNo1 => 'Az összes térképjel: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Zöld hengeres bója';

  @override
  String get chartLegend_portBuoyHint =>
      'Tengerről befelé jövet tartsa a bal oldalán';

  @override
  String get chartLegend_starboardBuoy => 'Piros kúpos bója';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Befelé jövet tartsa a jobb oldalán: hazatérve a piros jobbra marad';

  @override
  String get chartLegend_junctionBuoy => 'Sávos bója';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Hajóút-elágazás: a felső sáv színe szerint kezelje';

  @override
  String get chartLegend_safeWaterBuoy => 'Piros-fehér csíkos';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Körös-körül biztonságos víz, gyakran hajóút bejáratánál';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Fekete-piros sávos';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Kis veszély, körülötte biztonságos víz: kerülje el';

  @override
  String get chartLegend_specialBuoy => 'Sárga bója';

  @override
  String get chartLegend_specialBuoyHint =>
      'Különleges célú, nem irányjelző: horgonyzóhely, kábel, kutatás';

  @override
  String get chartLegend_cardinalBuoy => 'Fekete-sárga';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Kardinális jel: azon az oldalán haladjon el, amelyről a nevét kapta (az USA-ban ritka)';

  @override
  String get chartLegend_mooringBuoy => 'Kikötőbója';

  @override
  String get chartLegend_portBeacon => 'Zöld négyzetes nappali jel';

  @override
  String get chartLegend_portBeaconHint =>
      'Mint a zöld bója: befelé jövet tartsa a bal oldalán';

  @override
  String get chartLegend_starboardBeacon => 'Piros háromszögű nappali jel';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Mint a piros bója: befelé jövet tartsa a jobb oldalán';

  @override
  String get chartLegend_otherBeacon => 'Rombusz alakú nappali jel';

  @override
  String get chartLegend_otherBeaconHint =>
      'Tájékoztatás vagy figyelmeztetés, nem a hajóút oldalát jelzi';

  @override
  String get chartLegend_beaconTower => 'Világítótorony vagy jelzőépítmény';

  @override
  String get chartLegend_topmark => 'Csúcsjel';

  @override
  String get chartLegend_topmarkHint =>
      'A jel tetején lévő forma kiegészíti a jelentését';

  @override
  String get chartLegend_light => 'Fény';

  @override
  String get chartLegend_lightHint =>
      'A magenta fényjel egy fényt jelöl; a felirata megmondja, hogyan villan';

  @override
  String get chartLegend_lightExample => 'Zöld villanó, 4 másodpercenként';

  @override
  String get chartLegend_lightExampleHint =>
      'A fény felirata: ritmus, szín, majd periódus';

  @override
  String get chartLegend_lightFixed => 'Állandó';

  @override
  String get chartLegend_lightFixedHint => 'Folyamatos fény';

  @override
  String get chartLegend_lightFlashing => 'Villanó';

  @override
  String get chartLegend_lightFlashingHint =>
      'Rövid villanások, köztük hosszabb sötét szakasz';

  @override
  String get chartLegend_lightGroup => 'Csoportos villanó';

  @override
  String get chartLegend_lightGroupHint =>
      'Csoportokban villan, itt 2-esével, utána sötét';

  @override
  String get chartLegend_lightComposite => 'Összetett csoport';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 villanás, majd 1: hajóút-elágazást jelöl';

  @override
  String get chartLegend_lightQuick => 'Gyors';

  @override
  String get chartLegend_lightQuickHint => 'Kb. másodpercenként egy villanás';

  @override
  String get chartLegend_lightIsophase => 'Izofázisos';

  @override
  String get chartLegend_lightIsophaseHint => 'Egyforma hosszú fény és sötét';

  @override
  String get chartLegend_lightOcculting => 'Elsötétülő';

  @override
  String get chartLegend_lightOccultingHint =>
      'Tovább világít, mint ameddig sötét';

  @override
  String get chartLegend_lightMorse => 'Morse-kód A';

  @override
  String get chartLegend_lightMorseHint => 'Rövid, hosszú: biztonságos víz';

  @override
  String get chartLegend_lightAlternating => 'Váltakozó';

  @override
  String get chartLegend_lightAlternatingHint => 'Színt vált';

  @override
  String get chartLegend_lightColours => 'Fehér, piros, zöld, sárga';

  @override
  String get chartLegend_lightPeriod => 'Periódus';

  @override
  String get chartLegend_lightPeriodHint => 'Egy teljes ciklus másodpercben';

  @override
  String get chartLegend_rock => 'Víz alatti szikla';

  @override
  String get chartLegend_rockHint => 'Mindig víz borítja, de sekélyen lehet';

  @override
  String get chartLegend_rockAwash => 'Vízszinten lévő szikla';

  @override
  String get chartLegend_rockAwashHint => 'Apálykor a felszín közelében van';

  @override
  String get chartLegend_rockCovers => 'Időnként szárazra kerülő szikla';

  @override
  String get chartLegend_rockCoversHint =>
      'Apálykor kilátszik, dagálykor víz borítja';

  @override
  String get chartLegend_wreckDangerous => 'Veszélyes roncs';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Elég sekélyen van ahhoz, hogy nekimenjen';

  @override
  String get chartLegend_wreck => 'Roncs';

  @override
  String get chartLegend_wreckHint =>
      'Elég mélyen van a felszíni hajóknak; ne horgonyozzon';

  @override
  String get chartLegend_wreckShowing => 'Kiálló roncs';

  @override
  String get chartLegend_wreckShowingHint => 'Egy része kilátszik a vízből';

  @override
  String get chartLegend_obstruction => 'Akadály';

  @override
  String get chartLegend_obstructionHint =>
      'Valami a fenéken; ha ismert, a mélységével';

  @override
  String get chartLegend_foulGround => 'Akadályos fenék';

  @override
  String get chartLegend_foulGroundHint =>
      'Át lehet haladni felette, de ne horgonyozzon és ne halásszon vonóhálóval';

  @override
  String get chartLegend_hazardArea => 'Veszélyes terület széle';

  @override
  String get chartLegend_hazardAreaHint =>
      'Belül sziklák, roncsok vagy akadályok';

  @override
  String get chartLegend_pile => 'Cölöp vagy oszlop';

  @override
  String get chartLegend_floodStream => 'Dagályáram';

  @override
  String get chartLegend_floodStreamHint => 'Árapályáram, amíg a víz emelkedik';

  @override
  String get chartLegend_ebbStream => 'Apályáram';

  @override
  String get chartLegend_ebbStreamHint => 'Árapályáram, amíg a víz apad';

  @override
  String get chartLegend_current => 'Áramlás';

  @override
  String get chartLegend_currentHint =>
      'Az árapálytól függetlenül mindig ugyanarra folyik';

  @override
  String get chartLegend_rips => 'Áramlási hullámzás vagy örvények';

  @override
  String get chartLegend_ripsHint => 'Háborgó, örvénylő víz';

  @override
  String get chartLegend_breakers => 'Törőhullámok';

  @override
  String get chartLegend_breakersHint => 'Sekélyes felett megtörő hullámok';

  @override
  String get chartLegend_sounding => 'Mélységadat';

  @override
  String get chartLegend_soundingHint => 'Mélység átlagos apálykor';

  @override
  String get chartLegend_depthContour => 'Mélységvonal';

  @override
  String get chartLegend_depthContourHint => 'A felirata adja meg a mélységet';

  @override
  String get chartLegend_drying => 'Apálykor szárazra kerül';

  @override
  String get chartLegend_dredged => 'Kotort hajóút';

  @override
  String get chartLegend_dredgedHint => 'A feltüntetett mélységen tartják';

  @override
  String get chartLegend_swept => 'Átvizsgált terület';

  @override
  String get chartLegend_sweptHint =>
      'A feltüntetett mélységig akadálymentesnek ellenőrizve';

  @override
  String get chartLegend_unsurveyed => 'Felméretlen';

  @override
  String get chartLegend_unsurveyedHint => 'Nincs mért mélység';

  @override
  String get chartLegend_weed => 'Moszat vagy hínár';

  @override
  String get chartLegend_restricted => 'Korlátozott terület';

  @override
  String get chartLegend_restrictedHint =>
      'Korlátozott belépés; a vonalkák befelé mutatnak';

  @override
  String get chartLegend_regulatedLimit => 'Szabályozott terület határa';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Horgonyzóhely, kábelterület, lőtér és más: lásd a feliratát';

  @override
  String get chartLegend_greyLimit =>
      'Kotrási lerakóhely, halászterület vagy haltenyészet';

  @override
  String get chartLegend_anchorage => 'Horgonyzóhely';

  @override
  String get chartLegend_anchorBerth => 'Kijelölt horgonyhely';

  @override
  String get chartLegend_noAnchoring => 'Horgonyozni tilos';

  @override
  String get chartLegend_caution => 'Figyelmeztető terület';

  @override
  String get chartLegend_cautionHint => 'Itt legyen különösen óvatos';

  @override
  String get chartLegend_trafficLane => 'Forgalmi sáv';

  @override
  String get chartLegend_trafficLaneHint =>
      'Nagy hajók, egy irányban: derékszögben keresztezze';

  @override
  String get chartLegend_separationZone => 'Elválasztó zóna';

  @override
  String get chartLegend_separationZoneHint =>
      'A forgalmi sávok között: ne hajózzon be';

  @override
  String get chartLegend_precautionary => 'Elővigyázatossági terület';

  @override
  String get chartLegend_precautionaryHint =>
      'Itt hajók futnak össze: legyen óvatos';

  @override
  String get chartLegend_fairway => 'Hajóút';

  @override
  String get chartLegend_fairwayHint => 'Fő hajózási útvonal';

  @override
  String get chartLegend_track => 'Ajánlott útirány';

  @override
  String get chartLegend_ferry => 'Kompútvonal';

  @override
  String get chartLegend_leadingLine => 'Vezetővonal';

  @override
  String get chartLegend_leadingLineHint =>
      'Hozza fedésbe a két jelét, hogy a hajóútban maradjon';

  @override
  String get chartLegend_cable => 'Tenger alatti kábel';

  @override
  String get chartLegend_cableHint => 'Ne horgonyozzon';

  @override
  String get chartLegend_pipeline => 'Tenger alatti csővezeték';

  @override
  String get chartLegend_pipelineHint => 'Ne horgonyozzon';

  @override
  String get chartLegend_overhead => 'Légkábel';

  @override
  String get chartLegend_overheadHint =>
      'Szabad magassága VC jelöléssel szerepel';

  @override
  String get chartLegend_tower => 'Torony';

  @override
  String get chartLegend_windTurbine => 'Szélturbina';

  @override
  String get chartLegend_chimney => 'Kémény';

  @override
  String get chartLegend_mast => 'Árboc vagy antenna';

  @override
  String get chartLegend_church => 'Templom vagy templomtorony';

  @override
  String get chartLegend_flagstaff => 'Zászlórúd';

  @override
  String get chartLegend_dome => 'Kupola';

  @override
  String get chartLegend_landmark => 'Egyéb tájékozódási pont';

  @override
  String get chartLegend_abbrAnch => 'Horgonyzóhely';

  @override
  String get chartLegend_abbrWk => 'Roncs';

  @override
  String get chartLegend_abbrBr => 'Törőhullámok';

  @override
  String get chartLegend_abbrWd => 'Hínár';

  @override
  String get chartLegend_abbrVar => 'Mágneses elhajlás';

  @override
  String get chartLegend_abbrVc => 'Szabad magasság híd vagy kábel alatt';

  @override
  String get chartLegend_abbrTr => 'Torony';

  @override
  String get chartLegend_abbrCh => 'Templom';

  @override
  String get chartLegend_abbrChy => 'Kémény';

  @override
  String get chartLegend_abbrFs => 'Zászlórúd';

  @override
  String get chartLegend_abbrTk => 'Tartály';

  @override
  String get chartLegend_abbrRBn => 'Rádiójeladó';

  @override
  String get chartLegend_abbrCg => 'Parti őrség állomása';

  @override
  String get chartLegend_abbrRacon => 'Radarjeladó: megjelenik a radaron';

  @override
  String get chartLegend_abbrFog =>
      'Ködjelző: kürt, harang, gong, síp vagy sziréna';

  @override
  String get chartLegend_abbrVAis => 'Virtuális jel: csak AIS-en látható';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from–$to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return '$depth felett';
  }

  @override
  String get parkLegend_title => 'Park- és túrajelek';

  @override
  String get parkLegend_campsite => 'Kemping';

  @override
  String get parkLegend_picnicSite => 'Piknikező hely';

  @override
  String get parkLegend_shelter => 'Menedékhely';

  @override
  String get parkLegend_toilets => 'Mosdó';

  @override
  String get parkLegend_drinkingWater => 'Ivóvíz';

  @override
  String get parkLegend_parking => 'Parkoló';

  @override
  String get parkLegend_viewpoint => 'Kilátópont';

  @override
  String get parkLegend_attraction => 'Látnivaló';

  @override
  String get parkLegend_gate => 'Kapu';

  @override
  String get parkLegend_telephone => 'Telefon';

  @override
  String get parkLegend_information => 'Információs tábla';

  @override
  String get parkLegend_guidepost => 'Útjelző tábla';

  @override
  String get dialog_noticeExpires => 'Lejárat';

  @override
  String get dialog_noticeNoExpiry => 'Nincs lejárati dátum';

  @override
  String get dialog_noticeExpiryRequired =>
      'Válasszon dátumot (szobában kötelező)';

  @override
  String get dialog_noticeExpiryTime => 'Időpont';

  @override
  String get dialog_noticeEndOfDay => 'A nap végén';

  @override
  String structured_until(String when) {
    return 'Lejár: $when';
  }

  @override
  String get structured_expired => 'Lejárt';

  @override
  String get structured_announcement => 'Bejelentés';

  @override
  String structured_locationOf(String name) {
    return '$name helyzete';
  }

  @override
  String get reaction_searchHint => 'Emoji keresése';

  @override
  String get reaction_noResults => 'Nincs találat';

  @override
  String get share_qrAndLink => 'QR-kód és link megosztása';

  @override
  String get share_roomTitle => 'Szoba megosztása';

  @override
  String get share_contactTitle => 'Kapcsolat megosztása';

  @override
  String get share_roomInstructions =>
      'Olvassa be a kódot a szoba hozzáadásához. A bejelentkezéshez szüksége lesz a szoba jelszavára.';

  @override
  String get share_contactInstructions =>
      'Olvassa be a kódot a kapcsolat hozzáadásához.';

  @override
  String get clearChat_body =>
      'Üzenetek törlése ebből a csevegésből ezen az eszközön. Az új üzenetek továbbra is ide érkeznek.';

  @override
  String get clearChat_olderThanDay => '1 napnál régebbiek';

  @override
  String get clearChat_olderThanWeek => '1 hétnél régebbiek';

  @override
  String get clearChat_olderThanMonth => '1 hónapnál régebbiek';

  @override
  String get clearChat_everything => 'Az összes üzenet';

  @override
  String get chats_markAllRead => 'Összes megjelölése olvasottként';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count csevegés megjelölése olvasottként?',
      one: '1 csevegés megjelölése olvasottként?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Megjelölés';

  @override
  String get chats_nothingUnread => 'Nincs olvasatlan üzenet';

  @override
  String get chats_draft => 'Piszkozat';

  @override
  String get contact_teleBlockedTitle => 'A rádiója letiltja';

  @override
  String contact_teleBlockedBody(String name) {
    return 'A rádiója adatvédelmi beállításai ezt senkivel nem osztják meg, így $name nem kapja meg. Módosítja őket, hogy az engedélyezett partnerei megkapják?';
  }

  @override
  String get contact_teleNotNow => 'Most nem';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'A rádiója ezt senkivel nem osztja meg ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'A rádiója ezt mindenkivel megosztja ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Lekérheti a helyzetét';

  @override
  String get pathfinder_meshTitle => 'Másik hálózat?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return 'A csatlakozás óta hallott $heard repeaterből $unknown új a(z) „$graph” Pathfinder-térképnek. Indít egy új térképet ehhez a területhez? A régi megmarad, és a Pathfinder képernyőn visszaválthat rá.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'A csatlakozás óta hallott repeaterek többsége a(z) „$other” Pathfinder-térképen van, nem a(z) „$graph” térképen. Átvált rá?';
  }

  @override
  String get pathfinder_meshNew => 'Új térkép';

  @override
  String get pathfinder_meshSwitch => 'Átváltás';

  @override
  String get pathfinder_meshKeep => 'Ez marad';

  @override
  String get pathfinder_graphNameTitle => 'Az új térkép neve';

  @override
  String get pathfinder_graphNameHint => 'Például Washington';

  @override
  String get pathfinder_graphCreate => 'Létrehozás';

  @override
  String get locationSharing_title => 'Ki láthatja a helyzetemet';

  @override
  String get locationSharing_someone => 'Valaki láthatja a helyzetét';

  @override
  String get locationSharing_nobody => 'Senki sem láthatja a helyzetét';

  @override
  String get locationSharing_noPosition =>
      'A rádiójának még nincs helyzete, így senki sem láthatja';

  @override
  String get locationSharing_everyone =>
      'Mindenki, aki hallja a rádióját, láthatja a helyzetét';

  @override
  String get locationSharing_allContacts =>
      'Minden partnere láthatja a helyzetét';

  @override
  String get locationSharing_someContacts =>
      'Az Ön által engedélyezett partnerek láthatják a helyzetét';

  @override
  String get locationSharing_adverts => 'Helyzet a bejelentésekben';

  @override
  String get locationSharing_advertsHint =>
      'A bejelentései tartalmazzák a helyzetét, így bárki láthatja, aki hallja a rádióját.';

  @override
  String get locationSharing_contactsHeader =>
      'Partnerek, akik lekérdezhetik a rádióját';

  @override
  String get locationSharing_noTelemetry =>
      'Senki. A rádiója nem válaszol telemetriai kérésekre.';

  @override
  String get locationSharing_noContacts => 'Egy partnernek sincs engedélye.';

  @override
  String locationSharing_allContactsRow(int count) {
    return 'Minden partnere ($count)';
  }

  @override
  String get locationSharing_partLocation => 'Helyzet';

  @override
  String get locationSharing_partBattery => 'Akku';

  @override
  String get locationSharing_partSensors => 'Érzékelők';

  @override
  String get dialog_positionHint =>
      'Illesszen be koordinátákat vagy térképlinket';

  @override
  String get dialog_positionUnreadable => 'Itt nem olvasható ki pozíció';

  @override
  String get dialog_positionLookingUp => 'A link ellenőrzése…';

  @override
  String get locationSharing_share => 'Helyzetem megosztása';

  @override
  String get locationSharing_shareOnHint =>
      'Kapcsolja ki, hogy mindenki elől elrejtse';

  @override
  String get locationSharing_shareOffHint =>
      'Kapcsolja be, hogy az engedéllyel rendelkező partnerek lássák';

  @override
  String get chats_advertise => 'Bejelentés';
}
