// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovak (`sk`).
class AppLocalizationsSk extends AppLocalizations {
  AppLocalizationsSk([String locale = 'sk']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Chaty';

  @override
  String get chats_title => 'Chaty';

  @override
  String get newChat_title => 'Vyberte kontakt';

  @override
  String newChat_contactCount(int count) {
    return 'Kontakty: $count';
  }

  @override
  String get newChat_newContact => 'Nový kontakt';

  @override
  String get newChat_newChannel => 'Nový kanál';

  @override
  String get newChat_myContacts => 'Moje kontakty';

  @override
  String get newChat_discovered => 'Objavené';

  @override
  String get repeaters_title => 'Spravovať opakovače';

  @override
  String get nav_contacts => 'Kontakty';

  @override
  String get nav_channels => 'Kanály';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Zrušiť';

  @override
  String get common_syncing_device_info =>
      'Načítavajú sa informácie o zariadení...';

  @override
  String get common_syncing_contacts => 'Načítavajú sa kontakty...';

  @override
  String get common_syncing_channels => 'Načítavajú sa kanály...';

  @override
  String get common_syncing_messages => 'Načítavajú sa správy...';

  @override
  String get common_ok => 'OK\nDobre';

  @override
  String get common_connect => 'Pripojiť';

  @override
  String get common_unknownDevice => 'Neznáme zariadenie';

  @override
  String get common_save => 'Uložiť';

  @override
  String get common_delete => 'Odstrániť';

  @override
  String get common_deleteAll => 'Zmazať všetko';

  @override
  String get common_close => 'Zavrieť';

  @override
  String get common_edit => 'Upraviť';

  @override
  String get common_add => 'Pridať';

  @override
  String get common_settings => 'Nastavenia';

  @override
  String get common_disconnect => 'Odpojiť';

  @override
  String get common_connected => 'Pripojené';

  @override
  String get common_disconnected => 'Odpojené';

  @override
  String get common_connectionLost =>
      'Spojenie sa stratilo. Opätovné pripájanie...';

  @override
  String get common_reconnecting => 'Opätovné pripájanie...';

  @override
  String get common_create => 'Vytvoriť';

  @override
  String get common_continue => 'Pokračovať';

  @override
  String get common_share => 'Zdieľať';

  @override
  String get common_copy => 'Kopírovať';

  @override
  String get common_retry => 'Pokusť znova';

  @override
  String get common_hide => 'Skryť';

  @override
  String get common_remove => 'Odstrániť';

  @override
  String get common_enable => 'Povolit';

  @override
  String get common_disable => 'Zakázať';

  @override
  String get common_reboot => 'Restartovať';

  @override
  String get common_loading => 'Načítavanie...';

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
  String get tcpScreenTitle => 'Spojte sa pomocou protokolu TCP';

  @override
  String get tcpHostLabel => 'IP adresa';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Port';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Zadajte cieľovú adresu a pripojte sa.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Pripojenie k $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Je potrebné zadať IP adresu.';

  @override
  String get tcpErrorPortInvalid => 'Číslo portu musí byť medzi 1 a 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Prevoz prostredníctvom protokolu TCP nie je na tejto platforme podporovaný.';

  @override
  String get tcpErrorTimedOut => 'Pripojenie TCP vypršalo.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Neúspešné vytvorenie TCP spojenia: $error';
  }

  @override
  String get usbScreenTitle => 'Pripojte cez USB';

  @override
  String get usbScreenSubtitle =>
      'Vyberte detekovaný sériový zariadenie a pripojte ho priamo k vašej MeshCore uzlu.';

  @override
  String get usbScreenStatus => 'Vyberte USB zariadenie';

  @override
  String get usbScreenNote =>
      'USB sériová komunikácia je aktívna na podporovaných zariadeniach s Androidom a na desktopových platformách.';

  @override
  String get usbScreenEmptyState =>
      'Nenašli sa žiadne USB zariadenia. Pripojte jedno a obnovte.';

  @override
  String get usbErrorPermissionDenied =>
      'Žiadosť o prístup cez USB bola zamietnutá.';

  @override
  String get usbErrorDeviceMissing =>
      'Vybrané USB zariadenie už nie je dostupné.';

  @override
  String get usbErrorInvalidPort => 'Vyberte platné USB zariadenie.';

  @override
  String get usbErrorBusy =>
      'Ďalšia požiadavka na pripojenie cez USB je aktuálne v procese.';

  @override
  String get usbErrorNotConnected => 'Nie je pripojené žiadne USB zariadenie.';

  @override
  String get usbErrorOpenFailed =>
      'Nepodarilo sa otvoriť vybrané USB zariadenie.';

  @override
  String get usbErrorConnectFailed =>
      'Nepodarilo sa sa sa pripojiť k vybranému USB zariadeniu.';

  @override
  String get usbErrorUnsupported =>
      'Podpora USB sériového rozhrania nie je na tejto platforme dostupná.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Tejto zostave chýba knižnica pre sériový port USB, takže zariadenia USB nemožno otvoriť. Preinštalujte MeshTrax alebo nahláste túto zostavu ako chybnú.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Tento prehliadač nepodporuje Web Serial. Použite Chrome alebo Edge cez HTTPS (alebo localhost).';

  @override
  String get usbErrorAlreadyActive => 'Pripojenie cez USB je už aktivované.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Nebolo vybrané žiadne USB zariadenie.';

  @override
  String get usbErrorPortClosed => 'Pripojenie cez USB nie je aktivované.';

  @override
  String get usbErrorConnectTimedOut =>
      'Pripojenie nebolo úspešné. Uistite sa, že zariadenie má nainštalovaný firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Webový sériový zariadenie';

  @override
  String get usbStatus_notConnected => 'Vyberte USB zariadenie';

  @override
  String get usbStatus_connecting => 'Pripojenie k USB zariadeniu...';

  @override
  String get usbStatus_searching => 'Hľadanie USB zariadení...';

  @override
  String usbConnectionFailed(String error) {
    return 'Neúspešné pripojenie cez USB: $error';
  }

  @override
  String get scanner_scanning => 'Skrívania zariadení...';

  @override
  String get scanner_connecting => 'Pripojujem sa...';

  @override
  String get scanner_disconnecting => 'Odpojuje sa...';

  @override
  String get scanner_notConnected => 'Nezriadené';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Pripojené k $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Zobraziť všetky zariadenia Bluetooth';

  @override
  String get scanner_showMeshCoreOnly => 'Zobraziť len rádiá MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'Rádio neodpovedá. Možno ho treba spárovať: otvorte nastavenia Bluetooth, pridajte rádio a zadajte jeho PIN, potom to skúste znova.';

  @override
  String get scanner_pairingFailed =>
      'Párovanie Bluetooth bolo zrušené alebo zlyhalo. Uistite sa, že k rádiu nie je pripojené nič iné (napríklad váš telefón), potom to skúste znova a zadajte jeho PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Pripojenie zlyhalo: $error';
  }

  @override
  String get scanner_stop => 'Zastavte';

  @override
  String get scanner_scan => 'Skončiť';

  @override
  String get scanner_scanFromImage => 'Skenovať z obrázka';

  @override
  String get scanner_noQrFoundInImage => 'Na obrázku sa nenašiel platný QR kód';

  @override
  String get scanner_bluetoothOff => 'Bluetooth je vypnutý';

  @override
  String get scanner_bluetoothOffMessage =>
      'Prosím, zapnite Bluetooth, aby ste mohli skenovať pre zariadenia.';

  @override
  String get scanner_chromeRequired => 'Vyžaduje sa prehliadač Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Táto webová aplikácia vyžaduje Google Chrome alebo prehliadač založený na Chromium pre podporu Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Povolte Bluetooth';

  @override
  String get device_quickSwitch => 'Rýchle prepínač';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Nastavenia';

  @override
  String get settings_deviceInfo => 'Informácie o zariadení';

  @override
  String get settings_appSettings => 'Nastavenia aplikácie';

  @override
  String get settings_appSettingsSubtitle =>
      'Upozornenia, správy a nastavenia mapy';

  @override
  String get settings_nodeSettings => 'Nastavenia uzla';

  @override
  String get settings_nodeName => 'Názov uzla';

  @override
  String get settings_nodeNameNotSet => 'Nezriadené';

  @override
  String get settings_nodeNameHint => 'Zadajte názov uzla';

  @override
  String get settings_nodeNameUpdated => 'Meno aktualizované';

  @override
  String get settings_radioSettings => 'Nastavenia rádia';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvencia, výkon, rozptylovací faktor';

  @override
  String get settings_radioSettingsUpdated => 'Nastavenia rádia aktualizované';

  @override
  String get settings_location => 'Lokalita';

  @override
  String get settings_locationSubtitle => 'GPS súradnice';

  @override
  String get settings_locationUpdated => 'Lokalita aktualizovaná';

  @override
  String get settings_locationBothRequired =>
      'Zadajte obidve zložky zemyslenia a zložky meracieho kruhu.';

  @override
  String get settings_locationInvalid => 'Neplatná šírka alebo dĺžka.';

  @override
  String get settings_locationGPSEnable => 'Aktivovať GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Povolí automatické aktualizovanie polohy pomocou GPS.';

  @override
  String get settings_latitude => 'Súradnica';

  @override
  String get settings_longitude => 'Dĺžka';

  @override
  String get settings_contactSettings => 'Nastavenia kontaktov';

  @override
  String get settings_contactSettingsSubtitle =>
      'Nastavenia pre pridávanie kontaktov.';

  @override
  String get settings_privacyMode => 'Režim ochrany súkromia';

  @override
  String get settings_privacyModeSubtitle => 'Skryť meno/poloha v reklamách';

  @override
  String get settings_privacyModeToggle =>
      'Prepínač súkromného režimu skryje vaše meno a polohu v reklamách.';

  @override
  String get settings_privacyModeEnabled => 'Ochranný režim je povolený.';

  @override
  String get settings_privacyModeDisabled => 'Ochranný režim je vypnutý';

  @override
  String get settings_privacy => 'Nastavenia súkromia';

  @override
  String get settings_privacySubtitle => 'Ovládni, aké informácie sa zdieľajú.';

  @override
  String get settings_privacySettingsDescription =>
      'Vyberte, ktoré informácie váš zariadenie zdieľa s ostatnými.';

  @override
  String get settings_denyAll => 'Zamietnuť všetko';

  @override
  String get settings_allowByContact => 'Povoliť podľa kontaktových vlajok';

  @override
  String get settings_allowAll => 'Povoliť všetko';

  @override
  String get settings_telemetryBaseMode => 'Základný režim telemetrie';

  @override
  String get settings_telemetryLocationMode => 'Režim umiestnenia telemetrie';

  @override
  String get settings_telemetryEnvironmentMode => 'Režim prostredia telemetrie';

  @override
  String get settings_advertLocation => 'Umiestnenie inzerátu';

  @override
  String get settings_advertLocationSubtitle => 'Zahrnúť polohu do inzerátu';

  @override
  String get settings_multiAck => 'Viaceré ACK';

  @override
  String get settings_telemetryModeUpdated =>
      'Režim telemetrie bol aktualizovaný';

  @override
  String get settings_actions => 'Možné akcie';

  @override
  String get settings_sendAdvertisement => 'Odoslať reklamu';

  @override
  String get settings_sendAdvertisementSubtitle => 'Momentálne priezornejšie.';

  @override
  String get settings_advertisementSent => 'Reklama odeslaná';

  @override
  String get settings_syncTime => 'Čas synchronizácie';

  @override
  String get settings_syncTimeSubtitle =>
      'Nastaviť hodiny zariadenia na čas telefónu';

  @override
  String get settings_timeSynchronized => 'Čas synchronizovaný';

  @override
  String get settings_refreshContacts => 'Načítať Kontakty';

  @override
  String get settings_refreshContactsSubtitle =>
      'Načítať zoznam kontaktov z zariadenia';

  @override
  String get settings_rebootDevice => 'Restartovať zariadenie';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Restartujte zariadenie MeshCore.';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ste si istý, že chcete zariadenie reštartovať? Budete odpojení.';

  @override
  String get settings_debug => 'Ladenie';

  @override
  String get settings_bleDebugLog => 'Log BLE Debug';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Príkazy BLE, odpovede a surové dáta';

  @override
  String get settings_appDebugLog => 'Záznam ladenia aplikácie';

  @override
  String get settings_appDebugLogSubtitle => 'Správy z ladenia aplikácie';

  @override
  String get settings_exportDatabase => 'Exportovať databázu správ';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Kópia všetkých chatov a kontaktov na ladenie. Uchovajte ju v súkromí.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Databáza uložená do: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Export zlyhal: $error';
  }

  @override
  String get settings_about => 'O nás';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'MeshTrax Source Projekt 2024';

  @override
  String get settings_aboutDescription =>
      'Otvorený zdrojový Flutter klient pre MeshCore LoRa sieťové zariadenia.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Údaje o nadmorskej výške LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Meno';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Batéria';

  @override
  String get settings_infoPublicKey => 'Verejný kľúč';

  @override
  String get settings_infoContactsCount => 'Počet kontaktov';

  @override
  String get settings_infoChannelCount => 'Počet kanálov';

  @override
  String get settings_presets => 'Prednastavenia';

  @override
  String get settings_frequency => 'Frekvencia (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 – 2500,0';

  @override
  String get settings_frequencyInvalid => 'Neplatná frekvencia (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Šírka pásma';

  @override
  String get settings_spreadingFactor => 'Rozptýľovací faktor';

  @override
  String get settings_codingRate => 'Cenový kurz pre programovanie';

  @override
  String get settings_txPower => 'TX Výkon (dBm)';

  @override
  String get settings_txPowerInvalid => 'Neplatná hodnota výkonu TX';

  @override
  String get settings_clientRepeat => 'Opätovné použitie bez elektrickej siete';

  @override
  String get settings_clientRepeatSubtitle =>
      'Umožnite, aby toto zariadenie opakovávalo siete pre ostatných.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Použitie off-grid systému vyžaduje frekvencie 433, 869 alebo 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Chyba: $message';
  }

  @override
  String get appSettings_title => 'Nastavenia aplikácie';

  @override
  String get appSettings_appearance => 'Vzhľad';

  @override
  String get appSettings_theme => 'Téma';

  @override
  String get appSettings_themeSystem => 'Predvolený systém';

  @override
  String get appSettings_themeLight => 'Svetlo';

  @override
  String get appSettings_themeDark => 'Tmavé';

  @override
  String get appSettings_language => 'Jazyk';

  @override
  String get appSettings_languageSystem => 'Predvolený systém';

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
  String get appSettings_languageRu => 'Ruština';

  @override
  String get appSettings_languageUk => 'Ukrajinská';

  @override
  String get appSettings_enableMessageTracing => 'Povoliť sledovanie správ';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Zobraziť podrobné metadáta o smerovaní a časovaní správ';

  @override
  String get appSettings_senderNameColors => 'Farebné mená odosielateľov';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Každý odosielateľ v kanáli dostane vlastnú farbu mena. Vypnuté znamená farbu témy pre všetkých.';

  @override
  String get appSettings_showTextFormatting => 'Zobraziť formátovanie textu';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown v správach: **tučné**, *kurzíva*, ||spoilery||, nadpisy a odkazy. Iné aplikácie MeshCore zobrazujú nespracované znaky.';

  @override
  String get appSettings_notifications => 'Upozornenia';

  @override
  String get appSettings_enableNotifications => 'Povolte Notifikácie';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Zísť o upozornenia na správy a inzeráty';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Odmietená povolenie notifikácií';

  @override
  String get appSettings_notificationsEnabled => 'Upozornenia povolené';

  @override
  String get appSettings_notificationsDisabled => 'Upozornenia sú vypnuté';

  @override
  String get appSettings_messageNotifications => 'Správy od upozornení';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Zobraziť upozornenie pri prijímaní nových správ';

  @override
  String get appSettings_channelMessageNotifications => 'Notifikácie z kanálov';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Zobraziť upozornenie pri prijímaní správ z kanálu';

  @override
  String get appSettings_advertisementNotifications => 'Upozornenia na reklamy';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Zobraziť upozornenie, keď sa objavia nové uzly.';

  @override
  String get appSettings_messaging => 'Správy';

  @override
  String get appSettings_maxMessageRetries =>
      'Maximalný počet pokusov o doručenie správ';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Počet pokusov o odošleť pred označením správy ako neúspešnej';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Max. počet opakovaní správ v kanáli';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Opakuje toľkokrát, kým nezachytí aspoň jedno zopakovanie';

  @override
  String get appSettings_battery => 'Batéria';

  @override
  String get appSettings_batteryChemistry => 'Chemická zloženie batérie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Nastavenie pre $deviceName';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Pripojte sa k zariadeniu na výber';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Zobrazenie mapy';

  @override
  String get appSettings_showRepeaters => 'Zobraziť opakovače';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Zobraziť opakujúce sa uzly na mape';

  @override
  String get appSettings_showChatNodes => 'Zobraziť uzly chatových správ';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Zobraziť chatové uzly na mape';

  @override
  String get appSettings_showOtherNodes => 'Zobraziť ďalšie uzly';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Zobraziť ostatné typy uzlov na mape';

  @override
  String get appSettings_timeFilter => 'Filtrovacie Časové Obdoby';

  @override
  String get appSettings_timeFilterShowAll => 'Zobraziť všetky uzly';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Zobraziť uzly z posledných $hours hodín';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtračný čas mapy';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Zobraziť uzly objavené v:';

  @override
  String get appSettings_allTime => 'Všetky časy';

  @override
  String get appSettings_lastHour => 'Posledná hodina';

  @override
  String get appSettings_last6Hours => 'Posledné 6 hodín';

  @override
  String get appSettings_last24Hours => 'Posledných 24 hodín';

  @override
  String get appSettings_lastWeek => 'Minul týždeň';

  @override
  String get appSettings_unitsTitle => 'Jednotky';

  @override
  String get appSettings_unitsMetric => 'Metrické (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperiálne (ft / mi)';

  @override
  String get appSettings_debugCard => 'Ladenie';

  @override
  String get appSettings_appDebugLogging => 'Záznamy ladenia aplikácie';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Logovací správy aplikácie pre ladenie';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Aplikácia povolila ladenie protokolmi';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Zabudované ladenie aplikácie je vypnuté.';

  @override
  String get appSettings_incrementalContactSync =>
      'Prírastková synchronizácia kontaktov';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Po opätovnom pripojení žiadať od rádia len kontakty zmenené od minula';

  @override
  String get contacts_title => 'Kontakty';

  @override
  String get contacts_noContacts => 'Zatiaľ žiadne kontakty.';

  @override
  String get contacts_shareMyQrCode => 'Zdieľať môj QR kód';

  @override
  String get contacts_shareQrCodeDesc =>
      'Nechajte ostatných naskenovať kód a pridať si vás ako kontakt';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakty sa zobrazia, keď zariadenia spúšťajú reklamu.';

  @override
  String get contacts_unread => 'Neprečítané';

  @override
  String get contacts_searchContactsNoNumber => 'Hľadať kontakty...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Vyhľadávajte kontakty...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Hľadať $number$str obľúbené...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Hľadať $number$str používateľov...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Hľadať $number$str opakovače...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Hľadaj $number$str serverov miestností...';
  }

  @override
  String get contacts_noUnreadContacts => 'Žiadne neprečítané kontakty';

  @override
  String get contacts_noContactsFound =>
      'Neboli nájdených žiadnych kontaktov ani skupiny.';

  @override
  String get contacts_deleteContact => 'Odstrániť kontakt';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Naozaj chcete odstrániť $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Kontakt $contactName bol odstránený.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Nepodarilo sa odstrániť $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Filtru nezodpovedajú žiadne kontakty.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Odstrániť $contactName z kontaktov?';
  }

  @override
  String get contacts_manageRepeater => 'Spravovať opakované zoznamy';

  @override
  String get contacts_manageRoom => 'Spravovať server miestnosti';

  @override
  String get contacts_roomLogin => 'Prihlásenie do miestnosti';

  @override
  String get contacts_openChat => 'Otvorené Chat';

  @override
  String get contacts_editGroup => 'Upraviť skupinu';

  @override
  String get contacts_deleteGroup => 'Vymažť skupinu';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Odstrániť \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Nová skupina';

  @override
  String get contacts_groupName => 'Názov skupiny';

  @override
  String get contacts_groupNameRequired => 'Skupina musí mať názov.';

  @override
  String get contacts_groupNameReserved => 'Tento názov skupiny je rezervovaný';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Skupina \"$name\" už existuje';
  }

  @override
  String get contacts_filterContacts => 'Filtrovať kontakty...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Žiadne kontakty neodídu vášmu filtru.';

  @override
  String get contacts_noMembers => 'Žiadni členovia';

  @override
  String get contacts_lastSeenNow => 'Posledné zreteľné zobrazenie teraz';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Posledné zobrazenie $minutes min. dozadu';
  }

  @override
  String get contacts_lastSeenHourAgo =>
      'Zobral/Zabral poslednýkrát pred hodinou.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Posledné zobrazenie $hours hodín dozadu';
  }

  @override
  String get contacts_lastSeenDayAgo =>
      'Zobral/Zabral posledný raz pred 1 dňom.';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Posledné zobrazenie $days dní dozadu';
  }

  @override
  String get contact_info => 'Kontaktné informácie';

  @override
  String get contact_settings => 'Nastavenia kontaktov';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Naposledy videný';

  @override
  String get contact_clearChat => 'Vymazať chat';

  @override
  String get contact_teleBase => 'Báza telemetrie';

  @override
  String get contact_teleBaseSubtitle =>
      'Povoliť zdieľanie úrovne batérie a základnej telemetrie';

  @override
  String get contact_teleLoc => 'Lokácia telemetrie';

  @override
  String get contact_teleLocSubtitle => 'Povoliť zdieľanie údajov o lokalite';

  @override
  String get contact_teleEnv => 'Prostredie telemetrie';

  @override
  String get contact_teleEnvSubtitle =>
      'Povoliť zdieľanie údajov senzorov prostredia';

  @override
  String get contacts_publicKey => 'Verejný kľúč';

  @override
  String get channels_title => 'Kanály';

  @override
  String get channels_noChannelsConfigured => 'Neobsiahnuté žiadne kanály';

  @override
  String get channels_addPublicChannel => 'Pridať verejný kanál';

  @override
  String get channels_searchChannels => 'Vyhľadávajte kanály...';

  @override
  String get channels_noChannelsFound => 'Neobsiahlo sa žiadnych kanálov.';

  @override
  String channels_channelIndex(int index) {
    return 'Kanál $index';
  }

  @override
  String get channels_hashtagChannel => 'Kanál s hashtagom';

  @override
  String get channels_public => 'Veľké verejné';

  @override
  String get channels_private => 'Osobné';

  @override
  String get channels_publicChannel => 'Veľké verejne kanály';

  @override
  String get channels_privateChannel => 'Osobné kanál';

  @override
  String get channels_editChannel => 'Upraviť kanál';

  @override
  String get channels_shareChannel => 'Zdieľať kanál';

  @override
  String get channels_shareChannelInstructions =>
      'Naskenujte QR kód a pridajte kanál.\nMenu → Pridať kanál → Skenujte QR kód';

  @override
  String get channels_secretKey => 'Tajný kľúč';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

  @override
  String get channels_shareChannelQr => 'Naskenujte QR kód kanála';

  @override
  String get channels_shareChannelWarning =>
      'Upozornenie: Každý, kto naskenuje tento QR kód, získa prístup k tomuto kanálu.';

  @override
  String get channels_muteChannel => 'Stlmiť kanál';

  @override
  String get channels_unmuteChannel => 'Zrušiť stlmenie kanála';

  @override
  String get channels_deleteChannel => 'Odstrániť kanál';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Odstrániť \"$name\"? To sa nedá zrušiť.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kanál \"$name\" sa nepodarilo odstrániť';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanál \"$name\" bol odstránený';
  }

  @override
  String get channels_addChannel => 'Pridať kanál';

  @override
  String get channels_channelIndexLabel => 'Index kanála';

  @override
  String get channels_channelName => 'Názov kanálu';

  @override
  String get channels_usePublicChannel => 'Použite verejný kanál';

  @override
  String get channels_standardPublicPsk => 'Štandardný verejný PSK';

  @override
  String get channels_pskHex => 'PSK (Šifrovacia kľúčik)';

  @override
  String get channels_generateRandomPsk => 'Generovať náhodný PSK';

  @override
  String get channels_enterChannelName => 'Prosím, zadajte názov kanála.';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK musí mať 32 hexadecimálových znakov.';

  @override
  String get channels_addChannelConfirmation => 'Chcete pridať tento kanál?';

  @override
  String get channels_channelAddedSuccess => 'Kanál bol úspešne pridaný.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Nie sú voľné miesta pre kanály.';

  @override
  String get appSettings_mentionNotifications => 'Upozornenia na zmienky';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Keď vás niekto spomenie alebo vám odpovie — aj v stlmených kanáloch';

  @override
  String notification_mentionIn(String channelName) {
    return 'Zmienka v $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Kanál \"$name\" pridaný';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Upraviť kanál $index';
  }

  @override
  String get channels_smazCompression => 'Odstránenie kompresie SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanál \"$name\" bol aktualizovaný';
  }

  @override
  String get channels_publicChannelAdded => 'Veľký kanál pridaný';

  @override
  String get channels_sortBy => 'Triediť podľa';

  @override
  String get channels_sortManual => 'Ručne';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Posledné správy';

  @override
  String get channels_sortUnread => 'Nezriadené';

  @override
  String get channels_createPrivateChannel => 'Vytvorte súkromný kanál';

  @override
  String get channels_createPrivateChannelDesc =>
      'Zabezpečené pomocou tajného kľúča.';

  @override
  String get channels_joinPrivateChannel => 'Pripojiť sa k súkromnému kanálu';

  @override
  String get channels_joinPrivateChannelDesc => 'Ručne zadajte tajný kľúč.';

  @override
  String get channels_joinPublicChannel => 'Pripojte sa k verejnému kanálu';

  @override
  String get channels_joinPublicChannelDesc =>
      'Któvek sátó na tutó kanalizovát.';

  @override
  String get channels_joinHashtagChannel => 'Pripojte sa k Hashtag Kanálu';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Ktoekolikoľvek sa môže pridať do hashtag kanálov.';

  @override
  String get channels_scanQrCode => 'Skenujte QR kód';

  @override
  String get channels_scanQrCodeComingSoon => 'Čoskoro';

  @override
  String get channels_enterHashtag => 'Zadajte hashtag';

  @override
  String get channels_hashtagHint => 'napr. #tím';

  @override
  String get chat_noMessages => 'Zatiaľ žiadne správy.';

  @override
  String get chat_sendMessage => 'Odoslať správu';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Pošli správu $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Pošlite správu na začiatok';

  @override
  String get chat_originalMessageNotFound => 'Neznámy pôvodný odkaz.';

  @override
  String chat_replyingTo(String name) {
    return 'Odpovedám $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Odpovedať $name';
  }

  @override
  String get chat_location => 'Lokalita';

  @override
  String get common_copiedToClipboard => 'Skopírované do schránky';

  @override
  String get common_copyToClipboard => 'Kopírovať do schránky';

  @override
  String get contacts_copyContactToClipboard =>
      'Kopírovať môj kontakt do schránky';

  @override
  String get chat_typeMessage => 'Napište správu...';

  @override
  String get chat_searchMessages => 'Hľadať správy';

  @override
  String get chat_searchNoMatches => 'Žiadne zhody';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Správa je príliš dlhá (max $maxBytes bytov).';
  }

  @override
  String get chat_messageCopied => 'Správa skopírovaná';

  @override
  String get chat_messageDeleted => 'Posolstvo odstránené';

  @override
  String get chat_sendGif => 'Odoslať GIF';

  @override
  String get chat_reply => 'Odpovedať';

  @override
  String get chat_newMessages => 'NOVÉ SPRÁVY';

  @override
  String get chat_addReaction => 'Pridať Reakciu';

  @override
  String get chat_mention => 'Spomenúť';

  @override
  String get dmChannel_menuLabel => 'Priama správa';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Poslať DM pre $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Skontrolujte kľúč a čas, kedy bol naposledy videný — mená nie sú jedinečné.';

  @override
  String get dmChannel_warningTitle => 'Je to naozaj tá osoba?';

  @override
  String get dmChannel_warningBody =>
      'Mená v kanáloch si každý volí sám a ktokoľvek ich môže napodobniť. Pri čomkoľvek citlivom najprv overte verejný kľúč tohto kontaktu iným spôsobom.';

  @override
  String get dmChannel_dontShowAgain => 'Už nezobrazovať';

  @override
  String get batterySleep_title => 'Udržať MeshTrax v chode';

  @override
  String get batterySleep_bodySamsung =>
      'Telefóny Samsung uspávajú aplikácie, aby šetrili batériu, čo odpojí vaše rádio. Otvorte Nastavenia → Aplikácie → MeshTrax → Batéria a zvoľte Neobmedzené. Skontrolujte aj Batéria → Obmedzenia používania na pozadí a uistite sa, že MeshTrax nie je v zozname Uspané aplikácie ani Aplikácie v hlbokom spánku.';

  @override
  String get batterySleep_bodyGeneric =>
      'Telefón môže MeshTrax na pozadí zastaviť, aby šetril batériu, čo odpojí vaše rádio. Otvorte nastavenia batérie a nastavte MeshTrax na Neobmedzené (alebo Bez obmedzení). Na niektorých telefónoch treba pre MeshTrax zapnúť aj Automatické spúšťanie.';

  @override
  String get batterySleep_openSettings => 'Otvoriť nastavenia';

  @override
  String get batterySleep_notNow => 'Teraz nie';

  @override
  String get batterySleep_settingsTile => 'Udržať MeshTrax v chode na pozadí';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Zabráňte šetriču batérie telefónu uspať MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'DM pre $name zatiaľ nie je možná';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Zatiaľ nemáte kľúč tejto osoby a ona potrebuje váš, aby mohla odpovedať — kľúče sa šíria len v inzerátoch. \"Poslať môj inzerát\" odošle váš priamo odtiaľto. \"Opýtať sa v kanáli\" napíše žiadosť do poľa správy, aby ste ju mohli odoslať.';

  @override
  String get dmChannel_askInChannel => 'Opýtať sa v kanáli';

  @override
  String get dmChannel_sendMyAdvert => 'Poslať môj inzerát';

  @override
  String get dmChannel_askText =>
      'pošli prosím inzerát, nech ti môžem napísať DM';

  @override
  String get dmChannel_watching =>
      'Čakám na inzerát tejto osoby — keď príde, opýtam sa vás tu.';

  @override
  String dmChannel_advertHeard(String name) {
    return 'Kontakt $name je teraz dostupný';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Úroveň priblíženia';

  @override
  String get common_reset => 'Obnoviť';

  @override
  String get chat_reactionsTitle => 'Reakcie';

  @override
  String get chat_reactionUnknownSender => 'Neznámy';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender: reakcia na správu, ktorá nie je v tomto chate';
  }

  @override
  String get chat_me => 'Mne';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Gestá';

  @override
  String get emojiCategoryHearts => 'Srdcia';

  @override
  String get emojiCategoryObjects => 'Objekty';

  @override
  String get gifPicker_title => 'Vyberte GIF';

  @override
  String get gifPicker_searchHint => 'Vyhľadávajte GIFy...';

  @override
  String get gifPicker_poweredBy => 'Napájané spoločnosťou GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Neboli nájdené žiadne GIFy.';

  @override
  String get gifPicker_failedLoad => 'Nepodarilo sa načítať GIFy';

  @override
  String get gifPicker_failedSearch => 'Nepodarilo sa vyhľadať GIFy';

  @override
  String get gifPicker_noInternet => 'Žiadna internetová konektivita';

  @override
  String get debugLog_appTitle => 'Záznam ladenia aplikácie';

  @override
  String get debugLog_bleTitle => 'Log BLE Debug';

  @override
  String get debugLog_copyLog => 'Kopírovať záznam';

  @override
  String get debugLog_saveLog => 'Uložiť záznam do súboru';

  @override
  String get debugLog_saved => 'Záznam uložený';

  @override
  String get debugLog_saveCancelled => 'Ukladanie zrušené';

  @override
  String get debugLog_filterAll => 'Všetko';

  @override
  String get debugLog_filterWarnings => 'Varovania';

  @override
  String get debugLog_filterErrors => 'Chyby';

  @override
  String get debugLog_clearLog => 'Vymažať záznam';

  @override
  String get debugLog_copied => 'Záznam ladenia skopírovaný';

  @override
  String get debugLog_bleCopied => 'Kopírovaný záznam z BLE.';

  @override
  String get debugLog_noEntries =>
      'Zatiaľ neboli zaznamenané žiadne debug logy.';

  @override
  String get debugLog_enableInSettings =>
      'Povolte ladicové logy v nastaveniach';

  @override
  String get debugLog_frames => 'Rámce';

  @override
  String get debugLog_rawLogRx => 'Raw Log-RX';

  @override
  String get debugLog_noBleActivity => 'Zatiaľ žiadna aktivita BLE.';

  @override
  String debugFrame_length(int count) {
    return 'Dĺžka rámca: $count bajtov';
  }

  @override
  String debugFrame_command(String value) {
    return 'Prikáž: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Textová zvesť:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Cieľový PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Časové označenie: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Žiadne vlajky: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Typ textu: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Príkaz CLI';

  @override
  String get debugFrame_textTypePlain => 'Jednoduché';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex Dump:';

  @override
  String get chat_hopSingular => 'Skok';

  @override
  String get chat_hopPlural => 'Skákať';

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
  String get chat_setCustomPath => 'Nastaviť vlastnú cestu';

  @override
  String get chat_fullPath => 'Celá cesta';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Podrobnosti o ceste zatiaľ dostupné nie sú. Skúste poslať správu na obnovenie.';

  @override
  String get chat_type => 'Napište';

  @override
  String get chat_path => 'Cesta';

  @override
  String get chat_publicKey => 'Verejný kľúč';

  @override
  String get chat_compressOutgoingMessages => 'Komprimovať odoslané správy';

  @override
  String get chat_floodForced => 'Povodňová (nutená)';

  @override
  String get chat_directForced => 'Priame (donútené)';

  @override
  String chat_hopsForced(int count) {
    return '$count skokov (nutené)';
  }

  @override
  String get chat_floodAuto => 'Povod (automaticky)';

  @override
  String get chat_direct => 'Priamo';

  @override
  String get chat_poiShared => 'Zdieľané body záujmu';

  @override
  String chat_unread(int count) {
    return 'Nezriadené: $count';
  }

  @override
  String get chat_openLink => 'Otvoriť odkaz?';

  @override
  String get chat_openLinkConfirmation =>
      'Chcete otvoriť tento odkaz v prehliadači?';

  @override
  String get chat_open => 'Otvoriť';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Nepodarilo sa otvoriť odkaz: $url';
  }

  @override
  String get chat_invalidLink => 'Neplatný formát odkazu';

  @override
  String get map_lineOfSight => 'Line of Sight';

  @override
  String get map_losScreenTitle => 'Line of Sight';

  @override
  String get map_noNodesWithLocation => 'Žiadne uzly s údajmi o polohe';

  @override
  String get map_nodesNeedGps =>
      'Uholníky musia zdieľať svoje GPS súradnice, aby sa zobrazili na mape.';

  @override
  String map_nodesCount(int count) {
    return 'Uzly: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Krúžky: $count';
  }

  @override
  String get map_chat => 'Rozhovor';

  @override
  String get map_repeater => 'Opakovanie';

  @override
  String get map_room => 'Izba';

  @override
  String get map_sensor => 'Senzor';

  @override
  String get map_pinDm => 'Zabudka (DM)';

  @override
  String get map_pinPrivate => 'Zabudka (Osobná)';

  @override
  String get map_pinPublic => 'Zablokovať (verejne)';

  @override
  String get map_lastSeen => 'Posledné zreteľné zobrazenie';

  @override
  String get map_disconnectConfirm =>
      'Ste si istý/á, že chcete odpojiť od tohto zariadenia?';

  @override
  String get map_from => 'Od';

  @override
  String get map_source => 'Zdroj';

  @override
  String get map_flags => 'Zástavy';

  @override
  String get map_shareMarkerHere => 'Zdieľte značku tu';

  @override
  String get map_setAsMyLocation => 'Nastavte ako moju polohu';

  @override
  String get map_pinLabel => 'Označka upozornenia';

  @override
  String get map_label => 'Značka';

  @override
  String get map_pointOfInterest => 'Bod záujmu';

  @override
  String get map_sendToContact => 'Pošleť na kontakt';

  @override
  String get map_sendToChannel => 'Poslať do kanálu';

  @override
  String get map_noChannelsAvailable => 'Неexistujú žiadne kanály.';

  @override
  String get map_publicLocationShare => 'Zdieľiť verejnú lokalitu';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Čoskoro budete zdieľať polohu v $channelLabel. Tento kanál je verejný a môže ho vidieť každý s PSK.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Pripojte sa k zariadeniu na zdieľanie značiek';

  @override
  String get map_filterNodes => 'Filtrovať uzly';

  @override
  String get map_chatNodes => 'Chatové uzly';

  @override
  String get map_repeaters => 'Opakovadlá';

  @override
  String get map_otherNodes => 'Ostatné uzly';

  @override
  String get map_showOverlaps => 'Prekrývanie opakovača kľúča';

  @override
  String get map_keyPrefix => 'Päťciferné predpona';

  @override
  String get map_filterByKeyPrefix => 'Filtrovať podľa predponového kľúča';

  @override
  String get map_publicKeyPrefix => 'Prefix verejného kľúča';

  @override
  String get map_showDiscoveryContacts => 'Zobraziť kontakty objavov';

  @override
  String get map_guessedLocation => 'Odhadnutá lokalita';

  @override
  String get map_lastSeenTime => 'Posledný čas sledovania';

  @override
  String get map_sharedPin => 'Zdieľaný PIN';

  @override
  String get map_joinRoom => 'Pripojiť miestnosť';

  @override
  String get map_manageRepeater => 'Spravovať Opakovanie';

  @override
  String get map_tapToAdd => 'Kliknite na uzly, aby ste ich pridali k ceste.';

  @override
  String get map_runTrace => 'Spustiť trasovaním cesty';

  @override
  String get map_runTraceWithReturnPath => 'Vráťte sa späť po tej istej ceste.';

  @override
  String get map_removeLast => 'Odstrániť posledný';

  @override
  String get map_pathTraceCancelled => 'Zrušenie stopáže cesty bolo zrušené.';

  @override
  String get time_justNow => 'Príbeh';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes min dozadu';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours h dozadu';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dní dozadu';
  }

  @override
  String get time_hour => 'hodina';

  @override
  String get time_hours => 'hodiny';

  @override
  String get time_day => 'deň';

  @override
  String get time_days => 'dni';

  @override
  String get time_week => 'týždeň';

  @override
  String get time_weeks => 'týždne';

  @override
  String get time_month => 'mesiac';

  @override
  String get time_months => 'mesiace';

  @override
  String get time_minutes => 'minúty';

  @override
  String get time_allTime => 'Všetko Časom';

  @override
  String get dialog_disconnect => 'Odpojiť';

  @override
  String get dialog_disconnectConfirm =>
      'Ste si istý/á, že chcete odpojiť od tohto zariadenia?';

  @override
  String get login_repeaterLogin => 'Opätovné prihlásenie';

  @override
  String get login_roomLogin => 'Prihlásenie do miestnosti';

  @override
  String get login_password => 'Heslo';

  @override
  String get login_enterPassword => 'Zadajte heslo';

  @override
  String get login_savePassword => 'Uložiť heslo';

  @override
  String get login_savePasswordSubtitle =>
      'Heslo bude bezpečne uložené na tomto zariadení.';

  @override
  String get login_repeaterDescription =>
      'Zadajte heslo opakovača, aby ste získali prístup k nastaveniam a stavu.';

  @override
  String get login_roomDescription =>
      'Zadajte heslo do miestnosti na prístup k nastaveniam a stavu.';

  @override
  String get login_login => 'Prihlásiť';

  @override
  String login_attempt(int current, int max) {
    return 'Skúšaj $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Prihlásenie zlyhalo: $error';
  }

  @override
  String get login_failedMessage =>
      'Prihlásenie zlyhalo. Heslo je nesprávne alebo je opakovač nedostupný.';

  @override
  String get common_reload => 'Načítať';

  @override
  String get common_clear => 'Zmazať';

  @override
  String get path_enterCustomPath => 'Zadajte vlastný priebeh';

  @override
  String get path_currentPathLabel => 'Aktuálny priebeh';

  @override
  String get path_hexPrefixInstructions =>
      'Zadajte 2-miestne hexové predpony pre každú fázu, oddelené čiarkami.';

  @override
  String get path_hexPrefixExample =>
      'A1,F2,3C (každý uzel používa prvý bajt svojho verejného kľúča)';

  @override
  String get path_labelHexPrefixes => 'Cesty (hexové predpony)';

  @override
  String get path_helperMaxHops =>
      'Max 64 skokov. Každý prefix je 2 hexadecimálne znaky (1 bajt).';

  @override
  String get path_selectFromContacts => 'Vyberte sa z kontaktov:';

  @override
  String get path_noRepeatersFound =>
      'Nenašli sa žiadne opakovače ani serverové miestnosti.';

  @override
  String get path_customPathsRequire =>
      'Vlastné cesty vyžadujú medziletoch, ktoré môžu prenášať správky.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Neplatné hexové predpony: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Cesta je príliš dlhá. Umožnené je maximum 64 skokov.';

  @override
  String get path_setPath => 'Nastaviť cestu';

  @override
  String get repeater_management => 'Správa opakérov';

  @override
  String get room_management => 'Správa servera miestnosti';

  @override
  String get repeater_guest => 'Informácie o opakovači';

  @override
  String get room_guest => 'Informácie o serveri';

  @override
  String get repeater_managementTools => 'Nástroje na správu';

  @override
  String get repeater_guestTools => 'Nástroje pre hostí';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Zobraziť stav, štatistiky a susedov repeatera';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Zobraziť telemetriu senzorov a systémových štatistík';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Pošlite príkazy opakovaču';

  @override
  String get repeater_neighbors => 'Súsezný';

  @override
  String get repeater_neighborsSubtitle => 'Zobraziť susedné body bez skokov.';

  @override
  String get repeater_settings => 'Nastavenia';

  @override
  String get repeater_settingsSubtitle => 'Konfigurujte parametre opakovača';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Synchronizácia hodiniek po prihlávení';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automaticky posielajte notifikáciu \"synchronizácia času\" po úspešnom prihládení.';

  @override
  String get repeater_statusTitle => 'Status opakého zboru';

  @override
  String get repeater_refresh => 'Obnoviť';

  @override
  String get repeater_statusRequestTimeout => 'Požiadavka stavu zlyhala.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Chyba pri načítaní stavu: $error';
  }

  @override
  String get repeater_systemInformation => 'Informácie o systéme';

  @override
  String get repeater_battery => 'Batéria';

  @override
  String get repeater_clockAtLogin => 'Čas (při přihlášení)';

  @override
  String get repeater_uptime => 'Dostupnosť';

  @override
  String get repeater_queueLength => 'Dĺžka fronty';

  @override
  String get repeater_debugFlags => 'Kontrolné značky';

  @override
  String get repeater_radioStatistics => 'Rádio Štatistiky';

  @override
  String get repeater_lastRssi => 'Posledná RSSI';

  @override
  String get repeater_lastSnr => 'Posledný SNR';

  @override
  String get repeater_noiseFloor => 'Hladina šumu';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Statistiky balíka';

  @override
  String get repeater_sent => 'Odoslané';

  @override
  String get repeater_received => 'Prišlo';

  @override
  String get repeater_duplicates => 'Duplikáty';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dní ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Celkem: $total, Povodňový režim: $flood, Priamy: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Celkem: $total, Povodňový režim: $flood, Priamy: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Pond: $flood, Priamy: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Celkem: $total';
  }

  @override
  String get repeater_settingsTitle => 'Nastavenia Opakovača';

  @override
  String get repeater_basicSettings => 'Základné nastavenia';

  @override
  String get repeater_repeaterName => 'Opakovacia názov';

  @override
  String get repeater_repeaterNameHelper => 'Zobrazenie názvu tohto opakovača';

  @override
  String get repeater_adminPassword => 'Heslo administrátora';

  @override
  String get repeater_adminPasswordHelper => 'Celý prístupový heslo';

  @override
  String get repeater_guestPassword => 'Heslo hosťa';

  @override
  String get repeater_guestPasswordHelper => 'Prístupový heslo iba na čítanie';

  @override
  String get repeater_radioSettings => 'Nastavenia rádia';

  @override
  String get repeater_frequencyMhz => 'Frekvencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Šírka pásma';

  @override
  String get repeater_spreadingFactor => 'Šírenie faktoru';

  @override
  String get repeater_codingRate => 'Rýchlosť kódovania';

  @override
  String get repeater_locationSettings => 'Nastavenia polohy';

  @override
  String get repeater_latitude => 'Súradnica';

  @override
  String get repeater_latitudeHelper => 'Desatinné zložky (napr. 37.7749)';

  @override
  String get repeater_longitude => 'Dĺžka';

  @override
  String get repeater_longitudeHelper => 'Desatinné zložky (napr. -122.4194)';

  @override
  String get repeater_features => 'Funkcie';

  @override
  String get repeater_packetForwarding => 'Riadenie prienikov';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Povolte opakovač na smerovanie paketov.';

  @override
  String get repeater_guestAccess => 'Prístup pre hostí';

  @override
  String get repeater_guestAccessSubtitle =>
      'Umožniť prístup hosta iba na čítanie.';

  @override
  String get repeater_privacyMode => 'Režim ochrany súkromia';

  @override
  String get repeater_privacyModeSubtitle => 'Skryť meno/poloha v reklamách';

  @override
  String get repeater_advertisementSettings => 'Nastavenia reklamy';

  @override
  String get repeater_localAdvertInterval => 'Lokálna reklamná časová obdoba';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minút';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Interval reklamnej povodňovej reklamy';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours hodín';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Šifrovaný reklamný interval';

  @override
  String get repeater_dangerZone => 'Nebezpečná zóna';

  @override
  String get repeater_rebootRepeater => 'Restart Repetér';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Resetovať vysielací prístroj';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ste si istý, že chcete tento opakovač restartovať?';

  @override
  String get repeater_regenerateIdentityKey => 'Generovať kľúč identity';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Generovať nový pár verejných/privátnych kľúčov';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Toto vytvorí nový identitu pre opakovač. Pokračovať?';

  @override
  String get repeater_eraseFileSystem => 'Vymažať Systémový Reťazec';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formátovať systém opakujúcich sa súborov';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'VAROVANIE: Toto zmaže všetky dáta na opakovači. To sa nedá zrušiť!';

  @override
  String get repeater_eraseSerialOnly =>
      'Odstránenie je dostupné len cez sériové rozhranie.';

  @override
  String repeater_commandSent(String command) {
    return 'Poforovaný príkaz: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Chyba pri odeslaní príkazu: $error';
  }

  @override
  String get repeater_confirm => 'Potvrdiť';

  @override
  String get repeater_settingsSaved => 'Nastavenia boli uložené úspešne.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Chyba pri ukladaní nastavení: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Obnoviť základné nastavenia';

  @override
  String get repeater_refreshRadioSettings => 'Obnoviť Nastavenia Rádií';

  @override
  String get repeater_refreshTxPower => 'Obnoviť TX napájanie';

  @override
  String get repeater_refreshLocationSettings => 'Obnoviť Nastavenia Miesta';

  @override
  String get repeater_refreshPacketForwarding => 'Obnoviť smerovanie paketov';

  @override
  String get repeater_refreshGuestAccess => 'Obnoviť prístup hosťa';

  @override
  String get repeater_refreshPrivacyMode => 'Obnoviť Ochranný režim';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Obnoviť nastavenia reklamy';

  @override
  String repeater_refreshed(String label) {
    return '$label sa znova načítalo';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Chyba pri obnovení $label';
  }

  @override
  String get repeater_cliTitle => 'Opakovacia CLI';

  @override
  String get repeater_debugNextCommand => 'Oprava Nasledujúceho Príkaz';

  @override
  String get repeater_commandHelp => 'Pomoc';

  @override
  String get repeater_clearHistory => 'Vymazať históriu';

  @override
  String get repeater_noCommandsSent =>
      'Zatiaľ neboli odeslané žiadne príkazy.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Zadajte príkaz nižšie alebo použite rýchle príkazy';

  @override
  String get repeater_enterCommandHint => 'Zadajte príkaz...';

  @override
  String get repeater_previousCommand => 'Predchádzajúci príkaz';

  @override
  String get repeater_nextCommand => 'Nasledujúci príkaz';

  @override
  String get repeater_enterCommandFirst => 'Zadajte najprv príkaz';

  @override
  String get repeater_cliCommandFrameTitle => 'Rámok Príkaz CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Chyba: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Zísť meno';

  @override
  String get repeater_cliQuickGetRadio => 'Zísť po rádiu';

  @override
  String get repeater_cliQuickGetTx => 'Zísť TX';

  @override
  String get repeater_cliQuickNeighbors => 'Súsezný';

  @override
  String get repeater_cliQuickVersion => 'Verzia';

  @override
  String get repeater_cliQuickAdvertise => 'Reklama';

  @override
  String get repeater_cliQuickClock => 'Hodiny';

  @override
  String get repeater_cliQuickClockSync => 'Synchronizácia hodin';

  @override
  String get repeater_cliQuickDiscovery => 'Objaviť susedov';

  @override
  String get repeater_cliHelpAdvert => 'Odosiela reklamnú balíček.';

  @override
  String get repeater_cliHelpReboot =>
      'Resetuje zariadenie. (pozor, môže dôjsť k \'Timeoutu\', čo je normálne)';

  @override
  String get repeater_cliHelpClock =>
      'Zobrazuje aktuálny čas podľa hodiniek zariadenia.';

  @override
  String get repeater_cliHelpPassword =>
      'Nastaví nový administrátorský prístupový údaj pre zariadenie.';

  @override
  String get repeater_cliHelpVersion =>
      'Zobrazuje verziu zariadenia a dátum zostavenia firmvéru.';

  @override
  String get repeater_cliHelpClearStats =>
      'Resetuje rôzne štatistické počítadlá na nulu.';

  @override
  String get repeater_cliHelpSetAf => 'Nastavuje časový faktor.';

  @override
  String get repeater_cliHelpSetTx =>
      'Nastavenie vysielacej sily LoRa v dBm. (potrebuje sa reštart na aplikáciu)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Umožňuje alebo vypína zopakovaný príspevok pre tento uzol.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Server miestnosti) Ak je \'zapnuté\', potom bude povolený prístup s prázdnym heslom, ale nebude možné posielať správu do miestnosti. (iba čítať).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Nastavuje maximálny počet skokov pre vstupný povelový paket (ak je >= max, paket nie je preposlaný)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Nastavuje hranicu ruživeho ladenia (v dB). Predvolené je 14. Nastavením na 0 sa vypne detekcia ruživeho ladenia kanálu.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Nastavuje interval na reštartovanie Auto Gain Controlleru. Nastavenie na 0 vypne funkciu.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Povolí alebo pozastaví funkciiu \"dvojité potvrdenia\".';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Nastavuje interval časovača v minútach na odošle miestny (bezprostredný) reklamný paket. Nastavenie na 0 vypne funkciu.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Nastavuje interval časovača v hodinách na odeslanie reklamnej vlne. Nastavenie na 0 vypne.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Nastavuje/aktualizuje heslo hosťa. (pre opakované pripojenia môžu hosťovské prihlásenia posielať požadanie \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Nastaví názov reklamy.';

  @override
  String get repeater_cliHelpSetLat =>
      'Nastaví geografickú šírku reklamnej mapy. (desatinné stupne)';

  @override
  String get repeater_cliHelpSetLon =>
      'Nastavuje longitudinu reklamnej mapy. (desatinné stupne)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Nastavuje úplne nové parametre rádia a uloží ich do preferencií. Požaduje príkaz \"reboot\" na aplikáciu.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Nastavenia (experimentálne) základné (musi byť > 1 pre účel) na aplikáciu mierneho onesenia prijatých paketov, na základe signálu/skóre. Nastavenie na 0 vypne.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Nastavuje faktor násobený časom na vzduchu pre paket v režime povodňovej vlny a s náhodným systémom slotov, aby sa oneskorene jeho prenosovanie (s cieľom znížiť pravdepodobnosť kolízii).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Podobne ako txdelay, ale pre aplikáciu náhodného oneskorenia pri preposlaní paketov v režime priameho prenosu.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Aktivovať/Zatvárať most.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Nastaviť odklad pred retransmisiou paketov.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Zvolte, či bude most retransmitovať prijaté alebo vysielané balíčky.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Nastavte sériový link baudrate pre rs232 mosty.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Nastaviť tajomstvo mosta pre eshnow mosty.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Nastavuje vlastný faktor na úpravu nahlásenej batériovej napätia (podporované len na vybraných doskách).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Nastaví dočasné rádiové parametre pre zadaný počet minút, po skončení sa vráti k pôvodným rádiovým parametrom. (nepočuva sa do preferencií).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Zmení ACL. Odstráni zodpovedný záznam (podľa prefixa pubkey), ak je \"permissions\" rovné 0. Pridá nový záznam, ak je pubkey-hex plnej dĺžky a momentálne sa nenachádza v ACL. Aktualizuje záznam podľa zodpovedajúceho prefixa pubkey. Bitové oprávnenia sa líšia podľa funkčnej roly, ale nízke 2 bity sú: 0 (Hostiteľ), 1 (Čítanie len), 2 (Čítanie a zápis), 3 (Správca).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Zísť typ mosta: žiadny, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Začína protokolovanie balíkov do systému súborov.';

  @override
  String get repeater_cliHelpLogStop =>
      'Zastaví protokolovanie paketov do systémového súboru.';

  @override
  String get repeater_cliHelpLogErase =>
      'Odstráni záznamy z balíkov z systému súborov.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Zobrazuje zoznam iných repeaterových uzlov zasielaných cez zero-hop reklamy. Každý riadok je id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Odstráni prvú zhodujúcu položku (podľa prefixu pubkey (hex)) z zoznamu susedov.';

  @override
  String get repeater_cliHelpRegion =>
      '(len sériál) Zobrazuje všetky definované regióny a aktuálne povolenia pre povodňové situácie.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Poznámka: toto je špeciálna multi-príkázová inštancia. Každé nasledujúce príkaza je názov oblasti (zapustený s medzerami na indikáciu hierarchického pomeru, s minimálne jednou medzerou). Ukončené odeslaním prázdnej platnej linky/príkazu.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Hľadá región s daným príponou názvu (alebo \"\\\" pre globálny rozsah). Odpovedá \"-> región-název (rodič-název) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Pridá alebo aktualizuje definíciu regiónu s daným menom.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Odstráni definíciu oblasti s daným názvom. (musí zodpovedať presne a nemala by mať podoblasti)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Nastavuje povolenie \'P\'lávu pre zadanú oblasť. (\'\' pre globálny/dedičský rozsah)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Odstráni povolenie \'F\'lood\' pre zadanú oblasť. (UPOZORNENIE: v tejto fáze nie je odporúčané ho používať na globálnom/dedskom rozsahu!!).';

  @override
  String get repeater_cliHelpRegionHome =>
      'Odpovedá s aktuálnou \'domovskou\' oblasťou. (Poznámka aplikovaná zatiaľ nikde, vyhradené na budúce)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Nastaví \'domovskú\' oblasť.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Uloží zoznam/mapu regiónov do úložiska.';

  @override
  String get repeater_cliHelpGps =>
      'Zobrazuje stav GPS. Ak je GPS vypnutý, odpovedá len \"off\", ak je zapnutý, odpovedá s \"on\", stavom, fixom a počtom satelitov.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Prepínač stavu GPS napájania.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronizuje čas uzla s GPS hodinami.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Nastaví polohu uzla na GPS súradnice a uloží preferencie.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Poskytuje konfiguráciu reklamy pre uzol:\n- žiadna: nezahrňte polohu do reklám\n- zdieľať: zdieľajte GPS polohu (z SensorManager)\n- nastavenia: zobrazujte polohu uloženú v nastaveniach';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Nastavuje konfiguráciu reklamy na zadané miesto.';

  @override
  String get repeater_commandsListTitle => 'Zoznam príkazov';

  @override
  String get repeater_commandsListNote =>
      'Poznámka: pre rôzne príkazy \"set ...\" existuje aj príkaz \"get ...\".';

  @override
  String get repeater_general => 'Obecné';

  @override
  String get repeater_settingsCategory => 'Nastavenia';

  @override
  String get repeater_bridge => 'Most';

  @override
  String get repeater_logging => 'Záznamy';

  @override
  String get repeater_neighborsRepeaterOnly => 'Súseznýci (iba opakovač)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Správa regiónov (iba opakovač)';

  @override
  String get repeater_regionNote =>
      'Regionové príkazy boli zavádzané na správu regionálnych definícií a oprávnení.';

  @override
  String get repeater_gpsManagement => 'Správa GPS';

  @override
  String get repeater_gpsNote =>
      'GPS príkaz bol zavádzaný na riadenie lokalitných tém.';

  @override
  String get telemetry_receivedData => 'Obdolené Telemetrické dáta';

  @override
  String get telemetry_requestTimeout => 'Požiadavka telemetrie zlyhala.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Chyba pri načítaní telemetrie: $error';
  }

  @override
  String get telemetry_noData => 'Nejsú dostupné žiadne údaje z telemetrie.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanál $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batéria';

  @override
  String get telemetry_voltageLabel => 'Napätie';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU teplota';

  @override
  String get telemetry_temperatureLabel => 'Teplota';

  @override
  String get telemetry_currentLabel => 'Aktuálne';

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
  String get neighbors_receivedData => 'Obdielo dáta suseda';

  @override
  String get neighbors_requestTimedOut => 'Súďia žiadajú o časové ukončenie.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Chyba pri načítaní susedov: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Opakovadlá Súsezná';

  @override
  String get neighbors_noData =>
      'Nie je dostupná žiadna informácia o susedoch.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Neznáma $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Počuli sme to: $time dozadu';
  }

  @override
  String get channelPath_title => 'Cesta balíka';

  @override
  String get channelPath_viewMap => 'Zobraziť mapu';

  @override
  String get channelPath_otherObservedPaths => 'Ostatné pozorovacie cesty';

  @override
  String get channelPath_repeaterHops => 'Skoky opakovača';

  @override
  String get channelPath_noHopDetails =>
      'Podrobnosti o balíčku zatiaľ nie sú dostupné.';

  @override
  String get channelPath_messageDetails => 'Podrobnosti o zprávach';

  @override
  String get channelPath_senderLabel => 'Posielateľ';

  @override
  String get channelPath_timeLabel => 'Čas';

  @override
  String get channelPath_repeatsLabel => 'Opakovanie';

  @override
  String channelPath_pathLabel(int index) {
    return 'Cesta $index';
  }

  @override
  String get channelPath_observedLabel => 'Pozorované';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Sledovaný postup $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Žiadne údaje o polohe';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Neznáme';

  @override
  String get channelPath_floodPath => 'Povodňová';

  @override
  String get channelPath_directPath => 'Priamo';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 z $total skokov';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed z $total skokov';
  }

  @override
  String get channelPath_mapTitle => 'Mapa Trasy';

  @override
  String get channelPath_noRepeaterLocations =>
      'Pre túto cestu nie je dostupných žiadne polohy opakovačov.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Cesta $index (Hlavná)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Cesta';

  @override
  String get channelPath_observedPathHeader => 'Sledovaná cesta';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Pre toto balíček nie sú dostupné údaje o skokoch.';

  @override
  String get channelPath_unknownRepeater => 'Neznáme opakovače';

  @override
  String get community_title => 'Komunita';

  @override
  String get community_create => 'Vytvoriť komunitu';

  @override
  String get community_createDesc =>
      'Vytvorte novú komunitu a zdieľajte cez QR kód.';

  @override
  String get community_join => 'Pripojiť';

  @override
  String get community_joinTitle => 'Pripojiť sa k spoločenstvu';

  @override
  String community_joinConfirmation(String name) {
    return 'Chceš sa pridať do komunity \"$name\"?';
  }

  @override
  String get community_scanQr => 'Skontrolujte komunitný QR kód';

  @override
  String get community_scanInstructions =>
      'Zamerte kameru na komunitný QR kód.';

  @override
  String get community_showQr => 'Zobraziť QR kód';

  @override
  String get community_publicChannel => 'Komunita verejná';

  @override
  String get community_hashtagChannel => 'Komunitný Hashtag';

  @override
  String get community_name => 'Komunita';

  @override
  String get community_enterName => 'Zadajte názov komunity';

  @override
  String community_created(String name) {
    return 'Komunita \"$name\" vytvorená';
  }

  @override
  String community_joined(String name) {
    return 'Pripojená komunita \"$name\"';
  }

  @override
  String get community_qrTitle => 'Zdieľť komunitu';

  @override
  String community_qrInstructions(String name) {
    return 'Skenejte tento QR kód, aby ste sa pripojili k $name.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Hashtagové kanály komunity sú prístupné len členom komunity';

  @override
  String get community_invalidQrCode => 'Neplatná QR kód komunity.';

  @override
  String get community_alreadyMember => 'Už ste členom.';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Vy ste už členom \"$name\".';
  }

  @override
  String get community_addPublicChannel => 'Pridať verejný komunikačný kanál';

  @override
  String get community_addPublicChannelHint =>
      'Automaticky prida verejný kanál pre túto komunitu.';

  @override
  String get community_noCommunities =>
      'Zatiaľ ste sa nepripojili k žiadnej komunite';

  @override
  String get community_scanOrCreate =>
      'Skene QR kód alebo vytvor komunitu na začiatok.';

  @override
  String get community_manageCommunities => 'Spravovať komunity';

  @override
  String get community_delete => 'Nechajte komunitu';

  @override
  String community_deleteConfirm(String name) {
    return 'Opustiť \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Tým sa tiež vymaže $count kanál/kanálov a ich správy.';
  }

  @override
  String community_deleted(String name) {
    return 'Opustená komunita \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Zobraziť nový tajný kód';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Znovu vygenerovať tajný kľúč pre \"$name\"? Všetci členovia budú musieť skanovať nový QR kód, aby mohli nadviazať komunikáciu.';
  }

  @override
  String get community_regenerate => 'Znovu vygenerovať';

  @override
  String community_secretRegenerated(String name) {
    return 'Záznam pre \"$name\" bol regenerovaný tajne';
  }

  @override
  String get community_updateSecret => 'Aktualizovať tajné heslo';

  @override
  String community_secretUpdated(String name) {
    return 'Zmena tajnej slova pre \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Skáňte nový QR kód na aktualizáciu tajného hesla pre \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Pridať komunitný hashtag';

  @override
  String get community_addHashtagChannelDesc =>
      'Pridajte hashtagový kanál pre túto komunitu.';

  @override
  String get community_selectCommunity => 'Vyberte komunitu';

  @override
  String get community_regularHashtag => 'Zvyčajný hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Veľký hashtag (ktočokoľvek sa môže pridať)';

  @override
  String get community_communityHashtag => 'Komunitný Hashtag';

  @override
  String get community_communityHashtagDesc => 'Špecifické pre členov komunity';

  @override
  String community_forCommunity(String name) {
    return 'Pre $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrovať a triediť';

  @override
  String get listFilter_sortBy => 'Triediť podľa';

  @override
  String get listFilter_latestMessages => 'Posledné správy';

  @override
  String get listFilter_heardRecently => 'Nedávno počuli.';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtre';

  @override
  String get listFilter_source => 'Zdroj';

  @override
  String get listFilter_saved => 'Uložené';

  @override
  String get listFilter_discovered => 'Objavené';

  @override
  String get listFilter_all => 'Všetko';

  @override
  String get listFilter_favorites => 'Obľúbené';

  @override
  String get listFilter_addToFavorites => 'Pridaj do obľúbených';

  @override
  String get listFilter_removeFromFavorites => 'Odstrániť z označení';

  @override
  String get listFilter_users => 'Používatelia';

  @override
  String get listFilter_repeaters => 'Opakovadlá';

  @override
  String get listFilter_roomServers => 'Servéry miestnosti';

  @override
  String get listFilter_unreadOnly => 'Nezaregistrované len';

  @override
  String get listFilter_newGroup => 'Nová skupina';

  @override
  String get pathTrace_you => 'Vy';

  @override
  String get pathTrace_failed => 'Sledovanie cesty zlyhalo.';

  @override
  String get pathTrace_notAvailable => 'Path trace nie je k dispozícii.';

  @override
  String get pathTrace_refreshTooltip => 'Obnoviť Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Jedna alebo viac chmeľov chýba lokalita!';

  @override
  String get pathTrace_clearTooltip => 'Zmazať cestu';

  @override
  String get losSelectStartEnd => 'Vyberte počiatočný a koncový uzol pre LOS.';

  @override
  String losRunFailed(String error) {
    return 'Kontrola priamej viditeľnosti zlyhala: $error';
  }

  @override
  String get losClearAllPoints => 'Vymazať všetky body';

  @override
  String get losRunToViewElevationProfile =>
      'Ak chcete zobraziť výškový profil, spustite LOS';

  @override
  String get losMenuTitle => 'Menu LOS';

  @override
  String get losMenuSubtitle =>
      'Klepnutím na uzly alebo dlhým stlačením mapy získate vlastné body';

  @override
  String get losShowDisplayNodes => 'Zobraziť uzly zobrazenia';

  @override
  String get losCustomPoints => 'Vlastné body';

  @override
  String losCustomPointLabel(int index) {
    return 'Vlastné $index';
  }

  @override
  String get losPointA => 'Bod A';

  @override
  String get losPointB => 'Bod B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Anténa A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Anténa B: $value $unit';
  }

  @override
  String get losRun => 'Spustite LOS';

  @override
  String get losNoElevationData => 'Žiadne údaje o nadmorskej výške';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, vymazať LOS, min. vôľa $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blokovaný $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: kontrolujem...';

  @override
  String get losStatusNoData => 'LOS: žiadne údaje';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total vymazané, $blocked blokované, $unknown neznáme';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Údaje o nadmorskej výške nie sú k dispozícii pre jednu alebo viacero vzoriek.';

  @override
  String get losErrorInvalidInput =>
      'Neplatné body/údaje o nadmorskej výške pre výpočet LOS.';

  @override
  String get losRenameCustomPoint => 'Premenovať vlastný bod';

  @override
  String get losPointName => 'Názov bodu';

  @override
  String get losShowPanelTooltip => 'Zobraziť panel LOS';

  @override
  String get losHidePanelTooltip => 'Skryť panel LOS';

  @override
  String get losElevationAttribution =>
      'Údaje o nadmorskej výške: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Rádiový horizont';

  @override
  String get losLegendLosBeam => 'Priama viditeľnosť';

  @override
  String get losLegendTerrain => 'Terén';

  @override
  String get losFrequencyLabel => 'Frekvencia';

  @override
  String get losFrequencyInfoTooltip => 'Zobraziť podrobnosti výpočtu';

  @override
  String get losFrequencyDialogTitle => 'Výpočet rádiového horizontu';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Počnúc od k=$baselineK pri $baselineFreq MHz výpočet upraví k-faktor pre aktuálne pásmo $frequencyMHz MHz, ktorý definuje zakrivený strop rádiového horizontu.';
  }

  @override
  String get contacts_pathTrace => 'Sledovanie lúčov';

  @override
  String get contacts_ping => 'Pingovať';

  @override
  String get contacts_repeaterPathTrace => 'Sledovanie cesty k opakovaču';

  @override
  String get contacts_repeaterPing => 'Pingovať opakovač';

  @override
  String get contacts_roomPathTrace => 'Sledovanie cesty k serveru miestnosti';

  @override
  String get contacts_roomPing => 'Ping server miestnosti';

  @override
  String get contacts_chatTraceRoute => 'Sledovať trasu lúča';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Sledovať trasu k $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Schránka je prázdna.';

  @override
  String get contacts_invalidAdvertFormat => 'Neplatné kontaktné údaje';

  @override
  String get contacts_contactImported => 'Kontakt bol importovaný.';

  @override
  String get contacts_contactImportFailed =>
      'Kontakt sa nepodarilo importovať.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name už je vo vašich kontaktoch.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Inzerát Zero Hop';

  @override
  String get contacts_floodAdvert => 'Inzerát povodní';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopírovať reklamu do schránky';

  @override
  String get contacts_addContactFromClipboard => 'Pridať kontakt z schránky';

  @override
  String get contacts_ShareContact => 'Kopírovať kontakt do schránky';

  @override
  String get contacts_ShareContactZeroHop => 'Zdieľať kontakt cez inzerát';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Poslal kontakt cez inzerát.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Zlyhalo odoslanie kontaktu.';

  @override
  String get contacts_contactAdvertCopied =>
      'Inzerát bol skopírovaný do schránky.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopírovanie inzerátu do schránky zlyhalo.';

  @override
  String get contacts_addContact => 'Pridať kontakt';

  @override
  String get contacts_scanQrCode => 'Skenovať QR kontaktu';

  @override
  String get contacts_scanQrCodeDesc =>
      'Naskenujte QR kód kontaktu z aplikácie MeshCore';

  @override
  String get contacts_enterIdHash => 'Zadať kontakt ručne';

  @override
  String get contacts_enterIdHashDesc =>
      'Vložte inzerát kontaktu alebo odkaz meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... alebo verejný kľúč v hex';

  @override
  String get contacts_import => 'Importovať';

  @override
  String get contacts_scanContactInstructions =>
      'Naskenujte QR kód kontaktu MeshCore';

  @override
  String get notification_activityTitle => 'Aktivita MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'správ',
      few: 'správy',
      one: 'správa',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'správ kanálu',
      few: 'správy kanálu',
      one: 'správa kanálu',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nových uzlov',
      few: 'nové uzly',
      one: 'nový uzol',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nový $contactType objavený';
  }

  @override
  String get notification_receivedNewMessage => 'Prijatá nová správa';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportovať repeater / server miestnosti do GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportuje repeater / roomserver s lokalitou do súboru GPX.';

  @override
  String get settings_gpxExportContacts => 'Export sprievodcov do GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exportuje sprievodcov s umiestnením do súboru GPX.';

  @override
  String get settings_gpxExportAll => 'Exportovať všetky kontakty do GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exportuje všetky kontakty s lokalitou do súboru GPX.';

  @override
  String get settings_gpxExportSuccess => 'Úspešne exportovaný súbor GPX.';

  @override
  String get settings_gpxExportNoContacts => 'Žiadne kontakty na export.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Nie je podporované na vašom zariadení/operáciomnom systéme';

  @override
  String get settings_gpxExportError => 'Vyskytol sa chyba počas exportu.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Umiestnenia opakovačov a serverov miestností';

  @override
  String get settings_gpxExportChat => 'Lokácie sprievodcov';

  @override
  String get settings_gpxExportAllContacts => 'Všetky kontaktné lokality';

  @override
  String get settings_gpxExportShareText =>
      'Mapové údaje exportované z MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax export dát GPX mapových údajov';

  @override
  String get snrIndicator_nearByRepeaters => 'Miestne opakovače';

  @override
  String get snrIndicator_lastSeen => 'Naposledy videný';

  @override
  String get contactsSettings_title => 'Nastavenia kontaktov';

  @override
  String get contactsSettings_autoAddTitle => 'Automatické zisťovanie';

  @override
  String get contactsSettings_otherTitle =>
      'Ďalšie nastavenia súvisiace s kontaktami';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automaticky pridávať užívateľov';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Povoliť spoločníkovi automaticky pridávať objavených užívateľov.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automaticky pridávať opakovače';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Povoliť spoločníkovi automaticky pridávať objavené repeater.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automaticky pridávať server miestnosti';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Povoliť spoločníkovi automaticky pridať objavené serverové miestnosti.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automaticky pridávať senzory';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Povoliť spoločníkovi automaticky pridávať objavené senzory.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Prepísať najstaršie';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Keď je zoznam kontaktov plný, bude nahradený najstarší neoznačený kontakt.';

  @override
  String get discoveredContacts_Title => 'Objavené kontakty';

  @override
  String get discoveredContacts_noMatching => 'Žiadne zhodné kontakty';

  @override
  String get listFilter_searchHint => 'Hľadať...';

  @override
  String get discoveredContacts_searchHint => 'Vyhľadať objavené kontakty';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt bol pridaný';

  @override
  String get discoveredContacts_addContact => 'Pridať kontakt';

  @override
  String get discoveredContacts_copyContact => 'Kopírovať kontakt do schránky';

  @override
  String get discoveredContacts_deleteContact => 'Zmazať kontakt';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Zmazať všetky objavené kontakty';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Ste si istí, že chcete zmazať všetky objavené kontakty?';

  @override
  String get chat_sendCooldown => 'Prosím, počkajte chvíľu, než zašlete znova.';

  @override
  String get chat_notConnected =>
      'Nie ste pripojení k rádiu. Správa nebola odoslaná.';

  @override
  String get appSettings_jumpToOldestUnread => 'Presk oceň';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Pri otvorení chatu s neprečítanými správami, prejdite do prvého neprečítaného, namiesto poslednej.';

  @override
  String get appSettings_languageHu => 'Maďarský';

  @override
  String get appSettings_languageJa => 'Japonský';

  @override
  String get appSettings_languageKo => 'Kórejský';

  @override
  String get radioStats_screenTitle => 'Štatistiky rádiových vysielaní';

  @override
  String get radioStats_notConnected =>
      'Pripojte sa k zariadeniu, aby ste mohli sledovať štatistiky rádiového vysielania.';

  @override
  String get radioStats_firmwareTooOld =>
      'Statistické údaje z rádia vyžadujú sprievodný softvér verzie v8 alebo novšej.';

  @override
  String get radioStats_waiting => 'Čakám na údaje…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Úroveň hluku: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Posledný údaj RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Posledná hodnota SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Čas vysielania na TX (celkový): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Čas RX (celkový): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Úroveň šumu (dBm) pre posledné vzorky.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Úroveň hluku: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Získavanie údajov o rádiu…';

  @override
  String get radioStats_settingsTile => 'Štatistiky rádiových vysielaní';

  @override
  String get radioStats_settingsSubtitle =>
      'Úroveň hluku, RSSI, SNR a časové rozloženie';

  @override
  String get translation_title => 'Preklad';

  @override
  String get translation_enableTitle => 'Aktivovať preklad';

  @override
  String get translation_enableSubtitle =>
      'Prekladajte prichádzajúce správy a umožnite ich preklad pred odoslaním.';

  @override
  String get translation_composerTitle => 'Preložte pred odeslaním';

  @override
  String get translation_composerSubtitle =>
      'Riadi výchoce stav ikony pre preklad, ktorú používa program.';

  @override
  String get translation_targetLanguage => 'Cieľový jazyk';

  @override
  String get translation_useAppLanguage => 'Použite jazyk aplikácie';

  @override
  String get translation_downloadedModelLabel => 'Stiahnutý model';

  @override
  String get translation_presetModelLabel =>
      'Prednastavený model od Hugging Face';

  @override
  String get translation_manualUrlLabel =>
      'Odkaz na manuál (v elektronickej forme)';

  @override
  String get translation_downloadModel => 'Stiahnuť model';

  @override
  String get translation_downloading => 'Stiahnutie...';

  @override
  String get translation_working => 'Práca...';

  @override
  String get translation_stop => 'Zastavte';

  @override
  String get translation_mergingChunks =>
      'Sliečenie stiahnutých častí do konečného súboru...';

  @override
  String get translation_downloadedModels => 'Stiahnuté modely';

  @override
  String get translation_deleteModel => 'Odstrániť model';

  @override
  String get translation_modelDownloaded => 'Model pre preklad bol stiahnutý.';

  @override
  String get translation_downloadStopped => 'Stiahnutie bolo prerušené.';

  @override
  String translation_downloadFailed(String error) {
    return 'Neúspešné stiahnutie: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Najprv zadajte URL pre konkrétny model.';

  @override
  String get scanner_linuxPairingShowPin => 'Zobraziť PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Skryť PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN pre párovanie cez Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Zadajte PIN pre $deviceName (ak neexistuje, nechajte prázdne).';
  }

  @override
  String get translation_messageTranslation => 'Preklad textu';

  @override
  String get translation_translateBeforeSending => 'Preložte pred odeslaním';

  @override
  String get translation_composerEnabledHint =>
      'Správy budú preložené, než budú odoslané.';

  @override
  String get translation_composerDisabledHint =>
      'Posielajte správy v pôvodnej písanom jazyku.';

  @override
  String translation_translateTo(String language) {
    return 'Preložte do $language';
  }

  @override
  String get translation_translationOptions => 'Možnosti prekladania';

  @override
  String get translation_systemLanguage => 'Jazyk systému';

  @override
  String get routing_title => 'Smerovanie';

  @override
  String routing_route(String route) {
    return 'Uložená cesta: $route';
  }

  @override
  String get routing_noRoute =>
      'zatiaľ žiadna — ďalšia správa pôjde záplavou a nejakú sa naučí';

  @override
  String get routing_auto => 'Automaticky';

  @override
  String get routing_autoSubtitle =>
      'Použiť cestu uloženú v rádiu. Odporúčané.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder zapnutý: najprv skúša naučené trasy';

  @override
  String get routing_flood => 'Vždy záplavou';

  @override
  String get routing_floodSubtitle => 'Každá správa ide do celej siete';

  @override
  String get routing_custom => 'Vlastná cesta';

  @override
  String get routing_customSubtitle => 'Vyberte opakovače sami';

  @override
  String get routing_forget => 'Resetovať cestu';

  @override
  String get routing_forgetDone =>
      'Cesta resetovaná. Ďalšia správa pôjde záplavou a naučí sa novú.';

  @override
  String get routing_pathfinder => 'Čo vie Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Opakovače, ktoré počujú vás aj tento kontakt, a naučené trasy tam a späť';

  @override
  String get path_direct => 'Priamo — bez opakovačov';

  @override
  String get path_directSubtitle => 'Len keď kontakt počuje toto rádio priamo';

  @override
  String get chat_kindFlood => 'záplavou';

  @override
  String get chat_kindDirect => 'priamo';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'skokov',
      many: 'skoku',
      few: 'skoky',
      one: 'skok',
    );
    return 'trasou ($count $_temp0)';
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
  String get chat_statusQueued => 'Vo fronte';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Žiadny opakovač vás nepočul. Skúsi sa to znova, keď bude niektorý v dosahu.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'Rádio $name posiela krátke kódy opakovačov (1 bajt). Pathfinder sa nemôže naučiť trasy k tomuto kontaktu, kým jeho rádio nebude používať 2-bajtové kódy.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Odosiela sa · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Opakuje sa · $kind · pokus $attempt z $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Doručené · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Doručené na $attempt. pokus · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Doručené neskoro · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Doručené · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'pokusoch',
      many: 'pokusu',
      few: 'pokusoch',
      one: 'pokuse',
    );
    return 'Zlyhalo po $attempts $_temp0 · klepnutím odošlete znova';
  }

  @override
  String get chat_statusFailedShort => 'Zlyhalo · klepnutím odošlete znova';

  @override
  String get chat_resendingByFlood => 'Opätovné odosielanie záplavou';

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
  String get settings_pathGraph => 'Pathfinder (experimentálne)';

  @override
  String get settings_pathGraphSubtitle =>
      'Učí sa trasy zo všetkého, čo rádio počuje, a pri odosielaní DM najprv skúša tie najlepšie. Jantárová ikona cesty označuje správu odoslanú trasou Pathfindera.';

  @override
  String get map_routeAndTrace => 'Trasa a sledovanie';

  @override
  String get map_pathfinderTrace => 'Sledovanie tam a späť';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Tam najlepšou trasou Pathfindera, späť jeho najlepšou spätnou trasou';

  @override
  String get map_routeBackMirrored =>
      'Spätná trasa zatiaľ nie je známa — návrat tou istou cestou';

  @override
  String get map_traceHelpTitle => 'Tlačidlá sledovania cesty';

  @override
  String get map_traceHelpCustom => 'Napíšte alebo vyberte opakovače sami.';

  @override
  String get map_traceHelpRun =>
      'Pošle sledovanie cez opakovače, na ktoré ste klepli, jedným smerom.';

  @override
  String get map_traceHelpThereAndBack => 'Tam a späť';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Pošle sledovanie tam a potom späť cez tie isté opakovače v opačnom poradí.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder vyberie najlepšiu trasu cez posledné dva opakovače, na ktoré ste klepli, a najlepšiu trasu späť k vám. Výsledok naučí Pathfinder, ktoré spojenia naozaj fungujú. Treba klepnúť na dva opakovače.';

  @override
  String get map_traceHelpRemoveLast => 'Odoberie posledný opakovač z cesty.';

  @override
  String get map_traceHelpCancel =>
      'Zastaví vytváranie sledovania. Zobrazí sa, kým neklepnete na žiadny opakovač.';

  @override
  String get chat_resendingByRoute => 'Opätovné odosielanie nastavenou trasou';

  @override
  String get room_mute => 'Stlmiť miestnosť';

  @override
  String get room_unmute => 'Zrušiť stlmenie miestnosti';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'člen';

  @override
  String get room_roleReadOnly => 'len na čítanie';

  @override
  String room_clockOff(int minutes) {
    return 'Hodiny miestnosti sa líšia asi o $minutes min — časy správ môžu byť nesprávne';
  }

  @override
  String get room_fixClock => 'Opraviť hodiny';

  @override
  String get room_clockSyncSent => 'Synchronizácia hodín odoslaná miestnosti';

  @override
  String get room_readOnlyNotice =>
      'Len na čítanie: miestnosť neprijala vaše heslo, vaše správy sa k ostatným členom nedostanú.';

  @override
  String get room_postAnnouncement => 'Uverejniť oznam';

  @override
  String get room_postAnnouncementSubtitle =>
      'Poslať správu v mene miestnosti všetkým členom';

  @override
  String get room_announcementSent => 'Oznam uverejnený';

  @override
  String get room_announcementFailed => 'Uverejnenie oznamu zlyhalo';

  @override
  String get room_users => 'Používatelia miestnosti';

  @override
  String get room_usersSubtitle => 'Zobraziť adminov a nastaviť role';

  @override
  String get room_usersAdminsNote =>
      'Miestnosť uvádza len svojich adminov. Členovia s heslom miestnosti sa nezobrazujú.';

  @override
  String get room_usersLoadFailed => 'Zoznam adminov sa nepodarilo načítať';

  @override
  String get room_setUserRole => 'Nastaviť rolu';

  @override
  String get room_removeAccess => 'Odobrať prístup';

  @override
  String get room_removeOnlyUnknown =>
      'Tento používateľ nie je vo vašich kontaktoch — možno ho len odstrániť, nie zmeniť.';

  @override
  String get room_roleUpdated => 'Rola aktualizovaná';

  @override
  String get room_roleUpdateFailed => 'Zmena roly zlyhala';

  @override
  String get room_postsStored => 'Uložené príspevky';

  @override
  String get room_postsDelivered => 'Doručené príspevky';

  @override
  String get room_reloadPosts => 'Znovu načítať nedávne príspevky';

  @override
  String get room_reloadPostsExplain =>
      'Požiada miestnosť o opätovné odoslanie nedávnych príspevkov (uchováva až 32). Budete požiadaní o heslo miestnosti. Existujúce správy zostanú.';

  @override
  String get room_reloadFailed => 'Miestnosť sa nepodarilo resetovať na rádiu';

  @override
  String get companionCli_title => 'Príkazový riadok';

  @override
  String get companionCli_settingsSubtitle =>
      'Zadávajte textové príkazy pre toto rádio';

  @override
  String get companionCli_rebooting => 'Reštartuje sa rádio…';

  @override
  String get companionCli_cancelled => 'Zrušené';

  @override
  String get companionCli_poweringOff => 'Vypína sa rádio…';

  @override
  String get companionCli_noReply => 'Rádio neodpovedá. Skúste to znova.';

  @override
  String get companionCli_powerOffTitle => 'Vypnúť rádio?';

  @override
  String get companionCli_powerOffBody =>
      'Zostane vypnuté, kým nestlačíte jeho tlačidlo alebo ho nepripojíte k napájaniu.';

  @override
  String get companionCli_powerOff => 'Vypnúť';

  @override
  String get companionCli_quickBoard => 'Doska';

  @override
  String get companionCli_quickWifiStatus => 'Stav WiFi';

  @override
  String get companionCli_quickWifiAddress => 'Adresa WiFi';

  @override
  String get companionCli_helpBoard => 'Zobrazí výrobcu a model dosky.';

  @override
  String get companionCli_helpReboot => 'Reštartuje rádio.';

  @override
  String get companionCli_helpPowerOff => 'Vypne rádio.';

  @override
  String get companionCli_helpSetPin =>
      'Nastaví PIN na párovanie Bluetooth. Platí po reštarte.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Nastaví počet hodín pripočítaných k UTC pre hodiny na vlastnom displeji rádia (-12 až +14).';

  @override
  String get companionCli_helpSetTx =>
      'Nastaví vysielací výkon v dBm. Platí okamžite.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Nastaví prah rušenia v dB. 0 vypne detekciu rušenia.';

  @override
  String get companionCli_helpSetCad =>
      'Pred vysielaním počúva iné rádiá (detekcia aktivity kanála).';

  @override
  String get companionCli_helpSetRxGain =>
      'Zosilnený príjem na rádiách SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bajty na opakovač v trase: 0 = 1 bajt, 1 = 2 bajty, 2 = 3 bajty.';

  @override
  String get companionCli_helpWifiStatus =>
      'Zobrazí, či je rádio v sieti WiFi.';

  @override
  String get companionCli_helpWifiIp => 'Zobrazí adresu rádia v sieti WiFi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Nastaví názov siete WiFi. Platí po reštarte.';

  @override
  String get companionCli_helpWifiPwd =>
      'Nastaví heslo WiFi. Platí po reštarte.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Zapne (1) alebo vypne (0) WiFi. Platí po reštarte.';

  @override
  String get companionCli_helpWifiClear =>
      'Zabudne sieť WiFi. Platí po reštarte.';

  @override
  String get companionCli_remoteNoReply =>
      'Žiadna odpoveď. Druhé rádio potrebuje firmvér 1.18 alebo novší a musí vám povoliť používať svoj príkazový riadok.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Odoslané. Rádio na reštart ani vypnutie neodpovedá.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name: pokus o použitie príkazového riadka vášho rádia: \"$command\". Nebolo to povolené.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Pokus o použitie príkazového riadka vášho rádia: \"$command\". Nebolo to povolené.';
  }

  @override
  String get contact_remoteCli => 'Povoliť vzdialený príkazový riadok';

  @override
  String get contact_remoteCliSubtitle =>
      'Umožní tomuto kontaktu spúšťať príkazy na vašom rádiu';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Dovoliť $name ovládať vaše rádio?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return 'Kontakt $name bude môcť meniť nastavenia vášho rádia, čítať vaše heslo WiFi, premenovať rádio a reštartovať ho alebo vypnúť. Povoľte to len niekomu, komu úplne dôverujete.';
  }

  @override
  String get contact_remoteCliAllow => 'Povoliť';

  @override
  String get connection_secondApp =>
      'K tomuto rádiu je pripojená iná aplikácia. Správy a nastavenia sa môžu pomiešať. Zatvorte druhú aplikáciu.';

  @override
  String get wifi_title => 'WiFi';

  @override
  String get wifi_settingsSubtitle => 'Sieť, heslo a pripojenie';

  @override
  String get wifi_use => 'Používať WiFi';

  @override
  String get wifi_networkName => 'Názov siete';

  @override
  String get wifi_password => 'Heslo';

  @override
  String get wifi_passwordUnchanged => 'Nezmenené';

  @override
  String get wifi_showPassword => 'Zobraziť heslo';

  @override
  String get wifi_nameMissing => 'Zadajte názov siete';

  @override
  String get wifi_nameTooLong =>
      'Názov siete je príliš dlhý (najviac 32 bajtov)';

  @override
  String get wifi_passwordTooLong => 'Heslo je príliš dlhé (najviac 63 bajtov)';

  @override
  String get wifi_savedRestart =>
      'Uložené. Zmeny WiFi sa prejavia po reštarte rádia.';

  @override
  String get wifi_forget => 'Zabudnúť sieť';

  @override
  String get wifi_forgetConfirm =>
      'Zabudnúť túto sieť WiFi? Rádio po reštarte prestane používať WiFi.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Rádio to neprijalo: $reply';
  }

  @override
  String get wifi_noReply => 'Rádio neodpovedá. Skúste to znova.';

  @override
  String get wifi_restartTitle => 'Reštartovať rádio?';

  @override
  String get wifi_later => 'Neskôr';

  @override
  String get wifi_loadFailed =>
      'Nepodarilo sa načítať nastavenia WiFi z rádia.';

  @override
  String wifi_connectedTo(String address) {
    return 'Pripojené · $address';
  }

  @override
  String get wifi_notConnected => 'Nepripojené k WiFi';

  @override
  String wifi_portNote(int port) {
    return 'Aplikácie v tej istej sieti sa môžu pripojiť na porte $port';
  }

  @override
  String get wifi_connectOverWifi => 'Pripojiť cez WiFi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax sa odpojí od tohto rádia a otvorí obrazovku TCP s vyplnenou adresou $address a portom $port. Tam klepnite na \"Pripojiť\".';
  }

  @override
  String get wifi_noteRestart => 'Zmeny sa prejavia po reštarte rádia.';

  @override
  String get wifi_noteSecurity =>
      'Ktokoľvek vo vašej sieti WiFi sa môže pripojiť k rádiu na porte 5000. Nie je na to žiadne heslo.';

  @override
  String get wifi_noteBattery =>
      'WiFi nenechá rádio spať, takže sa batéria vybíja rýchlejšie.';

  @override
  String get wifi_noteWrongPassword =>
      'Ak je heslo nesprávne, rádio to skúša znova každých pár sekúnd. Bluetooth funguje ďalej.';

  @override
  String get room_selfDemoteWarning =>
      'Meníte svoj vlastný prístup. Ak sa vzdáte roly admina, vrátiť vám ju môže len konzola miestnosti.';

  @override
  String get scanner_offlineMaps => 'Offline mapy';

  @override
  String get appSettings_offlineMaps => 'Offline mapy';

  @override
  String get appSettings_offlineMapsNone => 'Nič nestiahnuté';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regiónov',
      many: '$count regiónu',
      few: '$count regióny',
      one: '$count región',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oblastí námorných máp',
      many: '$count oblasti námorných máp',
      few: '$count oblasti námorných máp',
      one: '$count oblasť námorných máp',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dostupných aktualizácií',
      many: '$count dostupnej aktualizácie',
      few: '$count dostupné aktualizácie',
      one: '$count dostupná aktualizácia',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly => 'Sťahovať mapy len cez Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Sťahovanie máp čaká na pripojenie Wi‑Fi';

  @override
  String get offlineMaps_title => 'Offline mapy';

  @override
  String get offlineMaps_tabMaps => 'Mapy';

  @override
  String get offlineMaps_tabCharts => 'Námorné mapy';

  @override
  String get offlineMaps_chartsNotice => 'Nie na navigáciu · Prečo?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Navrhované · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Oblasti máp podľa pobrežia';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oblastí',
      many: '$count oblasti',
      few: '$count oblasti',
      one: '$count oblasť',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Stiahnuté: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Vybrané: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Vybrať všetko';

  @override
  String get offlineMaps_clearSelection => 'Vymazať';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Aj v: $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Zatiaľ nedostupné';

  @override
  String get offlineMaps_chartsHint =>
      'Námorné mapy NOAA sa vyberajú podľa pobrežia na karte \"Námorné mapy\".';

  @override
  String offlineMaps_chartsName(String area) {
    return 'Námorné mapy NOAA – $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count oblastí',
      many: '$count oblasti',
      few: '$count oblasti',
      one: '$count oblasť',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Stiahnuté';

  @override
  String get offlineMaps_refresh => 'Hľadať nové mapy';

  @override
  String get offlineMaps_loading => 'Načítavajú sa dostupné mapy…';

  @override
  String get offlineMaps_serverError => 'Server máp je nedostupný';

  @override
  String get offlineMaps_unavailable => 'Zatiaľ nie sú dostupné žiadne mapy';

  @override
  String get offlineMaps_unavailableHint => 'Skúste to znova neskôr.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Zatiaľ nie sú dostupné žiadne námorné mapy NOAA';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Zobrazuje sa zoznam z $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Aktualizujte MeshTrax, aby ste získali najnovšie mapy.';

  @override
  String get offlineMaps_world => 'Svet';

  @override
  String get offlineMaps_suggested => 'Navrhované';

  @override
  String get offlineMaps_regions => 'Regióny';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regióny: $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return 'Vnútri: $count';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size offline máp v tomto zariadení';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Aktualizácie ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Aktualizovať všetko ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Sťahuje sa';

  @override
  String get offlineMaps_update => 'Aktualizovať';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Stiahnuté $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Dostupná aktualizácia';

  @override
  String get offlineMaps_otherFiles => 'Iné súbory máp';

  @override
  String get offlineMaps_emptyTitle => 'Zatiaľ žiadne offline mapy';

  @override
  String get offlineMaps_emptyBody =>
      'Stiahnite si región a používajte mapu bez pripojenia.';

  @override
  String get offlineMaps_findMaps => 'Nájsť mapy';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Odstrániť $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Uvoľní sa $size. Neskôr ho môžete stiahnuť znova.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name odstránené';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done z $total';
  }

  @override
  String get offlineMaps_kindMap => 'Mapa';

  @override
  String get offlineMaps_kindMapDetail =>
      'Ulice, chodníky a miesta z OpenStreetMap';

  @override
  String get offlineMaps_kindContours => 'Vrstevnice';

  @override
  String get offlineMaps_kindContoursDetail => 'Výškové čiary';

  @override
  String get offlineMaps_kindUsgs => 'Topografická mapa USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Chodníky, potoky, rezervácie';

  @override
  String get offlineMaps_kindTerrain => 'Tieňovanie terénu';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Kopce a hory, vytieňované pod mapou';

  @override
  String get offlineMaps_kindCharts => 'Námorné mapy NOAA';

  @override
  String get offlineMaps_usOnly => 'Len Spojené štáty';

  @override
  String offlineMaps_download(String size) {
    return 'Stiahnuť $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Stiahnuť';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Veľké sťahovanie ($size). Použite Wi‑Fi a nechajte zariadenie nabíjať.';
  }

  @override
  String get offlineMaps_waiting => 'Čaká sa…';

  @override
  String get offlineMaps_checking => 'Kontroluje sa stiahnutý súbor…';

  @override
  String get offlineMaps_retrying => 'Skúša sa znova…';

  @override
  String offlineMaps_failed(String error) {
    return 'Sťahovanie zlyhalo: $error';
  }

  @override
  String get offlineMaps_pause => 'Pozastaviť';

  @override
  String get offlineMaps_resume => 'Pokračovať';

  @override
  String get offlineMaps_deleteRegion => 'Odstrániť región';

  @override
  String get offlineMaps_notInCatalogue => 'Pre tento región nedostupné';

  @override
  String get offlineMaps_notificationRunning => 'Sťahuje sa mapa';

  @override
  String get offlineMaps_notificationPaused => 'Sťahovanie mapy pozastavené';

  @override
  String get offlineMaps_notificationFailed => 'Sťahovanie mapy zlyhalo';

  @override
  String get offlineMaps_clearTileCache =>
      'Vymazať uložené dlaždice online máp';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Odstrániť dlaždice online máp uložené pri prehliadaní? Stiahnuté mapy zostanú.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Uložené dlaždice online máp boli odstránené';

  @override
  String get map_notForNavigation => 'Nie na navigáciu';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax kreslí tieto mapy z údajov NOAA, aby vám pomohol vidieť vodu okolo vašich rádií a plánovať. Nie sú to oficiálne mapy. Neriaďte sa nimi pri plavbe.';

  @override
  String get map_chartsNoticeWhy => 'Prečo:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Zastarávajú. NOAA svoje mapy neustále opravuje; stiahnutá mapa zostáva taká, aká je, kým ju neaktualizujete v \"Offline mapy\".';

  @override
  String get map_chartsNoticeLeftOut =>
      'Niečo vynechávajú. Mnohé symboly, sektory svetiel a poznámky sa nekreslia a niektoré popisy sa zobrazia až po priblížení.';

  @override
  String get map_chartsNoticePositions =>
      'Polohy môžu byť nesprávne alebo staré. GPS sa môže mýliť o 10 m (30 ft) aj viac a uzol je len tam, odkiaľ sa naposledy ozval.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax nie je certifikovaný navigačný ploter.';

  @override
  String get map_chartsNoticeUse =>
      'Na navigáciu používajte oficiálne, aktuálne mapy NOAA (papierové alebo NOAA ENC v certifikovanom plotri) s najnovšími Oznámeniami pre námorníkov.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail => 'Stiahnite región pre podrobnosti';

  @override
  String get map_zoomInForOfflineMap =>
      'Priblížte, aby ste videli offline mapu';

  @override
  String get map_noCharts => 'Tu nie sú žiadne námorné mapy';

  @override
  String get map_myLocation => 'Moja poloha';

  @override
  String get map_zoomIn => 'Priblížiť';

  @override
  String get map_zoomOut => 'Oddialiť';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS zapnuté';

  @override
  String get gps_off => 'GPS vypnuté';

  @override
  String get gps_onHint => 'Rádio aktualizuje svoju polohu z GPS.';

  @override
  String get gps_offHint =>
      'Vypnuté šetrí batériu rádia. Po zapnutí môže nájdenie polohy trvať niekoľko minút.';

  @override
  String get gps_asking => 'Pýtam sa rádia...';

  @override
  String get gps_noPosition =>
      'Zatiaľ žiadna poloha. Vonku môže prvá trvať niekoľko minút.';

  @override
  String get gps_position => 'Poloha';

  @override
  String get gps_altitude => 'Nadmorská výška';

  @override
  String gps_readAgo(String ago) {
    return 'Načítané z rádia pred $ago';
  }

  @override
  String get gps_turnOnTitle => 'Zapnúť GPS?';

  @override
  String get gps_turnOnBody =>
      'GPS rádia je vypnuté. Po zapnutí môže nájdenie polohy trvať niekoľko minút.';

  @override
  String get gps_turnOn => 'Zapnúť';

  @override
  String get gps_notNow => 'Teraz nie';

  @override
  String get map_zoomInForCharts => 'Priblížte, aby ste videli námorné mapy';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Stiahnuť $region · $size';
  }

  @override
  String get mapLayers_title => 'Vrstvy mapy';

  @override
  String get mapLayers_mapType => 'Typ mapy';

  @override
  String get mapLayers_standard => 'Štandardná';

  @override
  String get mapLayers_usgs => 'Topografická USGS';

  @override
  String get mapLayers_charts => 'Námorné mapy';

  @override
  String get mapLayers_notDownloaded => 'Nestiahnuté';

  @override
  String get mapLayers_offlineOnly => 'Len offline';

  @override
  String get mapLayers_details => 'Podrobnosti mapy';

  @override
  String get mapLayers_contours => 'Vrstevnice';

  @override
  String get mapLayers_hillShading => 'Tieňovanie terénu';

  @override
  String get mapLayers_dark => 'Tmavá mapa';

  @override
  String get mapLayers_downloadedAreas => 'Stiahnuté oblasti';

  @override
  String get mapLayers_nodes => 'Uzly';

  @override
  String get mapLayers_pins => 'Špendlíky';

  @override
  String get mapLayers_guessed => 'Odhadnuté';

  @override
  String get mapLayers_moreFilters => 'Ďalšie filtre';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Naposledy videné, predpona kľúča, prekrytia';

  @override
  String get map_legend => 'Legenda';

  @override
  String get scanner_map => 'Mapa';

  @override
  String get structured_openMap => 'Otvoriť mapu';

  @override
  String get structured_addToCalendar => 'Pridať do kalendára';

  @override
  String get structured_details => 'Podrobnosti';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Udalosť';

  @override
  String get structured_notice => 'Oznam';

  @override
  String get structured_allDay => 'Celý deň';

  @override
  String get structured_calendarFailed => 'Kalendár sa nepodarilo otvoriť';

  @override
  String get structured_today => 'Dnes';

  @override
  String get structured_tomorrow => 'Zajtra';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'O $count dní',
      many: 'O $count dňa',
      few: 'O $count dni',
      one: 'O $count deň',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Minulé';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Deň $day z $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      many: '$count dňa',
      few: '$count dni',
      one: '$count deň',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Dátum konca';

  @override
  String get dialog_eventSameDay => 'V ten istý deň';

  @override
  String get structured_map => 'Mapa';

  @override
  String get structured_navigate => 'Navigovať';

  @override
  String get structured_channel => 'Kanál';

  @override
  String get structured_contact => 'Kontakt';

  @override
  String get structured_room => 'Miestnosť';

  @override
  String get structured_repeater => 'Opakovač';

  @override
  String get structured_sensor => 'Senzor';

  @override
  String get structured_joinChannel => 'Pripojiť sa ku kanálu';

  @override
  String get structured_addContact => 'Pridať kontakt';

  @override
  String get structured_addRoom => 'Pridať miestnosť';

  @override
  String get structured_addRepeater => 'Pridať opakovač';

  @override
  String get structured_addSensor => 'Pridať senzor';

  @override
  String get structured_open => 'Otvoriť';

  @override
  String get structured_added => 'Pridané';

  @override
  String get tray_add => 'Pridať';

  @override
  String get tray_myLocation => 'Moja poloha';

  @override
  String get tray_pointOnMap => 'Bod na mape';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Udalosť';

  @override
  String get tray_notice => 'Oznam';

  @override
  String get tray_noRadioPosition =>
      'Vaše rádio zatiaľ nemá polohu. Vyberte ju na mape.';

  @override
  String get dialog_insert => 'Vložiť';

  @override
  String get dialog_eventTitle => 'Názov';

  @override
  String get dialog_eventDate => 'Dátum';

  @override
  String get dialog_eventStart => 'Začiatok';

  @override
  String get dialog_eventEnd => 'Koniec';

  @override
  String get dialog_eventNoEnd => 'Bez času konca';

  @override
  String get dialog_eventPlace => 'Miesto (voliteľné)';

  @override
  String get dialog_pickOnMap => 'Vybrať na mape';

  @override
  String get dialog_sosTitle => 'Poslať SOS';

  @override
  String get dialog_sosText => 'Čo sa stalo?';

  @override
  String get dialog_noticeTitle => 'Oznam';

  @override
  String get dialog_noticeText => 'Čo by mali všetci vedieť?';

  @override
  String get dialog_labelTitle => 'Bod na mape';

  @override
  String get dialog_note => 'Poznámka (voliteľné)';

  @override
  String get paste_convertLocation =>
      'Vyzerá to ako odkaz na mapu. Previesť na polohu?';

  @override
  String get paste_convertEvent =>
      'Vyzerá to ako zdieľaná udalosť z kalendára. Previesť na udalosť?';

  @override
  String get paste_convert => 'Previesť';

  @override
  String get paste_resolving => 'Rozbaľuje sa odkaz…';

  @override
  String get paste_resolveFailed => 'Odkaz sa nepodarilo rozbaliť';

  @override
  String get pinned_dismiss => 'Zavrieť';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Pripojiť sa ku kanálu $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Už ste v $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Pripojené k $name';
  }

  @override
  String get map_pickPositionHint => 'Klepnutím na mapu vyberte polohu';

  @override
  String get map_legendMesh => 'Sieť mesh';

  @override
  String get chartLegend_title => 'Symboly námorných máp';

  @override
  String get chartLegend_sectionBuoys => 'Bóje a pevné znaky';

  @override
  String get chartLegend_sectionLights => 'Svetlá';

  @override
  String get chartLegend_sectionHazards => 'Nebezpečenstvá';

  @override
  String get chartLegend_sectionTides => 'Slapy a prúdy';

  @override
  String get chartLegend_sectionDepths => 'Hĺbky a dno';

  @override
  String get chartLegend_sectionAreas => 'Oblasti, dráhy a čiary';

  @override
  String get chartLegend_sectionLandmarks => 'Orientačné body';

  @override
  String get chartLegend_sectionAbbreviations => 'Skratky';

  @override
  String get chartLegend_chartNo1 => 'Všetky symboly: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Zelená valcová bója';

  @override
  String get chartLegend_portBuoyHint =>
      'Pri vplávaní z mora ju nechajte vľavo';

  @override
  String get chartLegend_starboardBuoy => 'Červená kužeľová bója';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Pri vplávaní ju nechajte vpravo: pri návrate z mora je červená vpravo';

  @override
  String get chartLegend_junctionBuoy => 'Pruhovaná bója';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Rozvetvenie kanála: riaďte sa farbou jej horného pruhu';

  @override
  String get chartLegend_safeWaterBuoy => 'Červeno-biele pruhy';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Bezpečná voda všade okolo, často pri vjazde do kanála';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Čierno-červené pásy';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Malé nebezpečenstvo s bezpečnou vodou okolo: držte sa ďalej';

  @override
  String get chartLegend_specialBuoy => 'Žltá bója';

  @override
  String get chartLegend_specialBuoyHint =>
      'Zvláštny účel, nie na navigáciu: kotvisko, kábel, výskum';

  @override
  String get chartLegend_cardinalBuoy => 'Čierno-žltá';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Kardinálny znak: obíďte ho zo strany, podľa ktorej je pomenovaný (v USA zriedkavý)';

  @override
  String get chartLegend_mooringBuoy => 'Uväzovacia bója';

  @override
  String get chartLegend_portBeacon => 'Zelený štvorcový denný znak';

  @override
  String get chartLegend_portBeaconHint =>
      'Ako zelená bója: pri vplávaní ho nechajte vľavo';

  @override
  String get chartLegend_starboardBeacon => 'Červený trojuholníkový denný znak';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Ako červená bója: pri vplávaní ho nechajte vpravo';

  @override
  String get chartLegend_otherBeacon => 'Kosoštvorcový denný znak';

  @override
  String get chartLegend_otherBeaconHint =>
      'Informácia alebo varovanie, nie strana kanála';

  @override
  String get chartLegend_beaconTower => 'Svetelná veža alebo konštrukcia znaku';

  @override
  String get chartLegend_topmark => 'Vrcholový znak';

  @override
  String get chartLegend_topmarkHint =>
      'Tvar na vrchu znaku dopĺňa jeho význam';

  @override
  String get chartLegend_light => 'Svetlo';

  @override
  String get chartLegend_lightHint =>
      'Purpurový záblesk označuje svetlo; jeho popis hovorí, ako bliká';

  @override
  String get chartLegend_lightExample => 'Zábleskové zelené, každé 4 sekundy';

  @override
  String get chartLegend_lightExampleHint =>
      'Popis svetla: rytmus, farba, potom perióda';

  @override
  String get chartLegend_lightFixed => 'Stále';

  @override
  String get chartLegend_lightFixedHint => 'Nepretržité svetlo';

  @override
  String get chartLegend_lightFlashing => 'Zábleskové';

  @override
  String get chartLegend_lightFlashingHint =>
      'Krátke záblesky, medzi nimi dlhšia tma';

  @override
  String get chartLegend_lightGroup => 'Skupinové zábleskové';

  @override
  String get chartLegend_lightGroupHint =>
      'Záblesky v skupinách, tu po 2, potom tma';

  @override
  String get chartLegend_lightComposite => 'Zložené skupinové';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 záblesky, potom 1: označuje rozvetvenie kanála';

  @override
  String get chartLegend_lightQuick => 'Rýchle';

  @override
  String get chartLegend_lightQuickHint => 'Asi jeden záblesk za sekundu';

  @override
  String get chartLegend_lightIsophase => 'Izofázové';

  @override
  String get chartLegend_lightIsophaseHint => 'Rovnako dlho svetlo a tma';

  @override
  String get chartLegend_lightOcculting => 'Prerušované';

  @override
  String get chartLegend_lightOccultingHint => 'Svieti dlhšie, než je tma';

  @override
  String get chartLegend_lightMorse => 'Morseovka A';

  @override
  String get chartLegend_lightMorseHint => 'Krátky, dlhý: bezpečná voda';

  @override
  String get chartLegend_lightAlternating => 'Striedavé';

  @override
  String get chartLegend_lightAlternatingHint => 'Mení farbu';

  @override
  String get chartLegend_lightColours => 'Biela, červená, zelená, žltá';

  @override
  String get chartLegend_lightPeriod => 'Perióda';

  @override
  String get chartLegend_lightPeriodHint => 'Sekundy na jeden celý cyklus';

  @override
  String get chartLegend_rock => 'Podvodná skala';

  @override
  String get chartLegend_rockHint => 'Vždy pod vodou, ale môže byť plytko';

  @override
  String get chartLegend_rockAwash => 'Skala na úrovni hladiny';

  @override
  String get chartLegend_rockAwashHint => 'Pri odlive tesne pri hladine';

  @override
  String get chartLegend_rockCovers => 'Skala zaplavovaná a odkrývaná';

  @override
  String get chartLegend_rockCoversHint =>
      'Pri odlive viditeľná, pri prílive pod vodou';

  @override
  String get chartLegend_wreckDangerous => 'Nebezpečný vrak';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Dosť plytko na to, aby ste doň narazili';

  @override
  String get chartLegend_wreck => 'Vrak';

  @override
  String get chartLegend_wreckHint =>
      'Dosť hlboko pre lode na hladine; nekotvite';

  @override
  String get chartLegend_wreckShowing => 'Vyčnievajúci vrak';

  @override
  String get chartLegend_wreckShowingHint => 'Časť z neho trčí nad vodu';

  @override
  String get chartLegend_obstruction => 'Prekážka';

  @override
  String get chartLegend_obstructionHint =>
      'Niečo na dne; jeho hĺbka, ak je známa';

  @override
  String get chartLegend_foulGround => 'Nečisté dno';

  @override
  String get chartLegend_foulGroundHint =>
      'Dá sa nad ním preplávať, ale nekotvite ani nelovte vlečnou sieťou';

  @override
  String get chartLegend_hazardArea => 'Okraj nebezpečnej oblasti';

  @override
  String get chartLegend_hazardAreaHint => 'Vnútri skaly, vraky alebo prekážky';

  @override
  String get chartLegend_pile => 'Kôl alebo stĺpik';

  @override
  String get chartLegend_floodStream => 'Prílivový prúd';

  @override
  String get chartLegend_floodStreamHint => 'Slapový prúd, keď voda stúpa';

  @override
  String get chartLegend_ebbStream => 'Odlivový prúd';

  @override
  String get chartLegend_ebbStreamHint => 'Slapový prúd, keď voda klesá';

  @override
  String get chartLegend_current => 'Prúd';

  @override
  String get chartLegend_currentHint =>
      'Tečie rovnakým smerom bez ohľadu na slapy';

  @override
  String get chartLegend_rips => 'Prúdové vlnenie alebo víry';

  @override
  String get chartLegend_ripsHint => 'Rozbúrená, vírivá voda';

  @override
  String get chartLegend_breakers => 'Príboj';

  @override
  String get chartLegend_breakersHint => 'Vlny lámajúce sa nad plytčinou';

  @override
  String get chartLegend_sounding => 'Hĺbka';

  @override
  String get chartLegend_soundingHint => 'Hĺbka pri priemernom odlive';

  @override
  String get chartLegend_depthContour => 'Izobata';

  @override
  String get chartLegend_depthContourHint => 'Jej popis udáva hĺbku';

  @override
  String get chartLegend_drying => 'Pri odlive vysychá';

  @override
  String get chartLegend_dredged => 'Prehĺbený kanál';

  @override
  String get chartLegend_dredgedHint => 'Udržiavaný na uvedenú hĺbku';

  @override
  String get chartLegend_swept => 'Prečistená oblasť';

  @override
  String get chartLegend_sweptHint => 'Overená ako voľná do uvedenej hĺbky';

  @override
  String get chartLegend_unsurveyed => 'Nezmerané';

  @override
  String get chartLegend_unsurveyedHint => 'Hĺbky neboli merané';

  @override
  String get chartLegend_weed => 'Chaluhy alebo riasy';

  @override
  String get chartLegend_restricted => 'Obmedzená oblasť';

  @override
  String get chartLegend_restrictedHint =>
      'Vstup obmedzený; zúbky smerujú dovnútra';

  @override
  String get chartLegend_regulatedLimit => 'Hranica regulovanej oblasti';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Kotvisko, káblová oblasť, strelnica a ďalšie: pozrite popis';

  @override
  String get chartLegend_greyLimit => 'Výsypisko, lovisko alebo farma';

  @override
  String get chartLegend_anchorage => 'Kotvisko';

  @override
  String get chartLegend_anchorBerth => 'Kotviace miesto';

  @override
  String get chartLegend_noAnchoring => 'Zákaz kotvenia';

  @override
  String get chartLegend_caution => 'Výstražná oblasť';

  @override
  String get chartLegend_cautionHint => 'Tu buďte zvlášť opatrní';

  @override
  String get chartLegend_trafficLane => 'Dopravný pruh';

  @override
  String get chartLegend_trafficLaneHint =>
      'Veľké lode, jedným smerom: križujte v pravom uhle';

  @override
  String get chartLegend_separationZone => 'Deliaca zóna';

  @override
  String get chartLegend_separationZoneHint =>
      'Medzi dopravnými pruhmi: nevplávajte';

  @override
  String get chartLegend_precautionary => 'Oblasť zvýšenej opatrnosti';

  @override
  String get chartLegend_precautionaryHint =>
      'Lode sa tu zbiehajú: dávajte pozor';

  @override
  String get chartLegend_fairway => 'Plavebná dráha';

  @override
  String get chartLegend_fairwayHint => 'Hlavný kanál';

  @override
  String get chartLegend_track => 'Odporúčaná trasa';

  @override
  String get chartLegend_ferry => 'Trasa trajektu';

  @override
  String get chartLegend_leadingLine => 'Vodiaca línia';

  @override
  String get chartLegend_leadingLineHint =>
      'Zarovnajte jej dva znaky do zákrytu, aby ste zostali v kanáli';

  @override
  String get chartLegend_cable => 'Podmorský kábel';

  @override
  String get chartLegend_cableHint => 'Nekotvite';

  @override
  String get chartLegend_pipeline => 'Podmorské potrubie';

  @override
  String get chartLegend_pipelineHint => 'Nekotvite';

  @override
  String get chartLegend_overhead => 'Nadzemný kábel';

  @override
  String get chartLegend_overheadHint => 'Jeho svetlá výška je označená VC';

  @override
  String get chartLegend_tower => 'Veža';

  @override
  String get chartLegend_windTurbine => 'Veterná turbína';

  @override
  String get chartLegend_chimney => 'Komín';

  @override
  String get chartLegend_mast => 'Stožiar alebo anténa';

  @override
  String get chartLegend_church => 'Kostol alebo kostolná veža';

  @override
  String get chartLegend_flagstaff => 'Stožiar na vlajku';

  @override
  String get chartLegend_dome => 'Kupola';

  @override
  String get chartLegend_landmark => 'Iný orientačný bod';

  @override
  String get chartLegend_abbrAnch => 'Kotvisko';

  @override
  String get chartLegend_abbrWk => 'Vrak';

  @override
  String get chartLegend_abbrBr => 'Príboj';

  @override
  String get chartLegend_abbrWd => 'Chaluhy';

  @override
  String get chartLegend_abbrVar => 'Magnetická deklinácia';

  @override
  String get chartLegend_abbrVc => 'Svetlá výška pod mostom alebo káblom';

  @override
  String get chartLegend_abbrTr => 'Veža';

  @override
  String get chartLegend_abbrCh => 'Kostol';

  @override
  String get chartLegend_abbrChy => 'Komín';

  @override
  String get chartLegend_abbrFs => 'Stožiar na vlajku';

  @override
  String get chartLegend_abbrTk => 'Nádrž';

  @override
  String get chartLegend_abbrRBn => 'Rádiomaják';

  @override
  String get chartLegend_abbrCg => 'Stanica pobrežnej stráže';

  @override
  String get chartLegend_abbrRacon => 'Radarový maják: zobrazí sa na radare';

  @override
  String get chartLegend_abbrFog =>
      'Hmlový signál: húkačka, zvon, gong, píšťala alebo siréna';

  @override
  String get chartLegend_abbrVAis => 'Virtuálny znak: zobrazený len v AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from až $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Hlbšie ako $depth';
  }

  @override
  String get parkLegend_title => 'Symboly parkov a chodníkov';

  @override
  String get parkLegend_campsite => 'Kemp';

  @override
  String get parkLegend_picnicSite => 'Miesto na piknik';

  @override
  String get parkLegend_shelter => 'Prístrešok';

  @override
  String get parkLegend_toilets => 'Toalety';

  @override
  String get parkLegend_drinkingWater => 'Pitná voda';

  @override
  String get parkLegend_parking => 'Parkovisko';

  @override
  String get parkLegend_viewpoint => 'Vyhliadka';

  @override
  String get parkLegend_attraction => 'Atrakcia';

  @override
  String get parkLegend_gate => 'Brána';

  @override
  String get parkLegend_telephone => 'Telefón';

  @override
  String get parkLegend_information => 'Informačná tabuľa';

  @override
  String get parkLegend_guidepost => 'Smerovník';

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
