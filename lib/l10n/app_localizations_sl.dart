// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Slovenian (`sl`).
class AppLocalizationsSl extends AppLocalizations {
  AppLocalizationsSl([String locale = 'sl']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Klepeti';

  @override
  String get chats_title => 'Klepeti';

  @override
  String get newChat_title => 'Izberite stik';

  @override
  String newChat_contactCount(int count) {
    return 'Stiki: $count';
  }

  @override
  String get newChat_newContact => 'Nov stik';

  @override
  String get newChat_newChannel => 'Nov kanal';

  @override
  String get newChat_myContacts => 'Moji stiki';

  @override
  String get newChat_discovered => 'Odkriti';

  @override
  String get repeaters_title => 'Upravljanje ponoviteljev';

  @override
  String get nav_contacts => 'Stiki';

  @override
  String get nav_channels => 'Kanali';

  @override
  String get nav_map => 'Karta';

  @override
  String get common_cancel => 'Prekliči';

  @override
  String get common_syncing_device_info => 'Branje podatkov o napravi...';

  @override
  String get common_syncing_contacts => 'Branje stikov...';

  @override
  String get common_syncing_channels => 'Branje kanalov...';

  @override
  String get common_syncing_messages => 'Branje sporočil...';

  @override
  String get common_ok => 'V redu';

  @override
  String get common_connect => 'Poveži se';

  @override
  String get common_unknownDevice => 'Nepoznano naprave';

  @override
  String get common_save => 'Shrani';

  @override
  String get common_delete => 'Izbrisati';

  @override
  String get common_deleteAll => 'Izbriši vse';

  @override
  String get common_close => 'Zapri';

  @override
  String get common_edit => 'Uredi';

  @override
  String get common_add => 'Dodaj';

  @override
  String get common_settings => 'Nastavitve';

  @override
  String get common_disconnect => 'Odklopiti';

  @override
  String get common_connected => 'Povezano';

  @override
  String get common_disconnected => 'Odprto';

  @override
  String get common_connectionLost =>
      'Povezava prekinjena. Ponovno povezovanje...';

  @override
  String get common_reconnecting => 'Ponovno povezovanje...';

  @override
  String get common_create => 'Ustvari';

  @override
  String get common_continue => 'Poudarki';

  @override
  String get common_share => 'Deliti';

  @override
  String get common_copy => 'Kopiraj';

  @override
  String get common_retry => 'Ponoviti';

  @override
  String get common_hide => 'Skrita';

  @override
  String get common_remove => 'Izbrisati';

  @override
  String get common_enable => 'Omogoči';

  @override
  String get common_disable => 'Izklopiti';

  @override
  String get common_reboot => 'Ponoviti';

  @override
  String get common_loading => 'Naložanje...';

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
  String get tcpScreenTitle => 'Komunicirajte preko protokola TCP';

  @override
  String get tcpHostLabel => 'IP naslov';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Vrata';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Vnesite končni naslov in se povežite';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Povezava z $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Potrebna je IP-naslov.';

  @override
  String get tcpErrorPortInvalid => 'Port mora biti med 1 in 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Transport preko protokola TCP ni podprt na tej platformi.';

  @override
  String get tcpErrorTimedOut => 'Povezava TCP je presegla časovno obdobje.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Napaka pri povezavi TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Povežite preko USB';

  @override
  String get usbScreenSubtitle =>
      'Izberite zaznano serijsko napravo in se neposredno povežite z vašo MeshCore napravo.';

  @override
  String get usbScreenStatus => 'Izberite USB naprave';

  @override
  String get usbScreenNote =>
      'USB serijska povezava je aktivna na podprtih napravah Android in na desktop platformah.';

  @override
  String get usbScreenEmptyState =>
      'Niti en USB naprave niso najdeni. Povežite eno in posodobite.';

  @override
  String get usbErrorPermissionDenied =>
      'Dovoljenje za dostop preko USB-ja je bilo zavrnjeno.';

  @override
  String get usbErrorDeviceMissing => 'Izbrani USB napravej je več ne.';

  @override
  String get usbErrorInvalidPort => 'Izberite veljavno USB naprave.';

  @override
  String get usbErrorBusy => 'Že je v teku zahteva za povezavo preko USB.';

  @override
  String get usbErrorNotConnected => 'Ni priklopljenih USB naprave.';

  @override
  String get usbErrorOpenFailed =>
      'Uspešno ni bilo mogo, da se odpre izbran naprave USB.';

  @override
  String get usbErrorConnectFailed =>
      'Niso bilo mogoče uskladiti povezave z izbranim USB napom.';

  @override
  String get usbErrorUnsupported =>
      'USB serijska komunikacija ni podprta na tej platformi.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Tej različici manjka knjižnica za serijska vrata USB, zato naprav USB ni mogoče odpreti. Znova namestite MeshTrax ali prijavite to različico kot pokvarjeno.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Ta brskalnik ne podpira Web Serial. Uporabite Chrome ali Edge prek HTTPS (ali localhost).';

  @override
  String get usbErrorAlreadyActive => 'USB povezava je že aktivirana.';

  @override
  String get usbErrorNoDeviceSelected => 'Ni bilo izbranega USB naprave.';

  @override
  String get usbErrorPortClosed => 'USB povezava ni aktivirana.';

  @override
  String get usbErrorConnectTimedOut =>
      'Vzpostavitve ni bilo mogo. Prosimo, da se prepričate, da ima naprave trenutno nameštan firmware USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Naprave za serijsko komunikacijo preko spleta';

  @override
  String get usbStatus_notConnected => 'Izberite USB naprave.';

  @override
  String get usbStatus_connecting => 'Povezava z USB napravo...';

  @override
  String get usbStatus_searching => 'Iskanje USB naprav...';

  @override
  String usbConnectionFailed(String error) {
    return 'Napaka pri povezavi preko USB: $error';
  }

  @override
  String get scanner_scanning => 'Skeniram za naprave...';

  @override
  String get scanner_connecting => 'Povezujem se...';

  @override
  String get scanner_disconnecting => 'Odklapljam se...';

  @override
  String get scanner_notConnected => 'Nezavezan';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Povezan s $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Prikaži vse naprave Bluetooth';

  @override
  String get scanner_showMeshCoreOnly => 'Prikaži samo radie MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'Radio se ne odziva. Morda ga je treba seznaniti: odprite nastavitve Bluetooth, dodajte radio in vnesite njegov PIN, nato poskusite znova.';

  @override
  String get scanner_pairingFailed =>
      'Seznanjanje Bluetooth je bilo preklicano ali ni uspelo. Prepričajte se, da z radiem ni povezano nič drugega (na primer vaš telefon), nato poskusite znova in vnesite njegov PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Pošlo je z povezavo: $error';
  }

  @override
  String get scanner_stop => 'Prekliči';

  @override
  String get scanner_scan => 'Skeniraj';

  @override
  String get scanner_scanFromImage => 'Skeniraj iz slike';

  @override
  String get scanner_noQrFoundInImage => 'Na sliki ni veljavne QR kode';

  @override
  String get scanner_bluetoothOff => 'Bluetooth je izklopljen';

  @override
  String get scanner_bluetoothOffMessage =>
      'Prosimo, vklopite Bluetooth, da lahko poiščete naprave.';

  @override
  String get scanner_chromeRequired => 'Zahtevan brskalnik Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Ta spletna aplikacija za podporo Bluetooth zahteva Google Chrome ali brskalnik na osnovi Chromiuma.';

  @override
  String get scanner_enableBluetooth => 'Omogočite Bluetooth';

  @override
  String get device_quickSwitch => 'Hitro preklop';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Nastavitve';

  @override
  String get settings_deviceInfo => 'Informacije o napravei';

  @override
  String get settings_appSettings => 'Nastavitve aplikacije';

  @override
  String get settings_appSettingsSubtitle =>
      'Obveščanja, sporoščanje in zemljevidi.';

  @override
  String get settings_nodeSettings => 'Nastavitev časa';

  @override
  String get settings_nodeName => 'Ime node-a';

  @override
  String get settings_nodeNameNotSet => 'Ni nastavljeno';

  @override
  String get settings_nodeNameHint => 'Vnesite ime node-a';

  @override
  String get settings_nodeNameUpdated => 'Ime posodobljeno';

  @override
  String get settings_radioSettings => 'Nastavitve radija';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvenca, moč, razširitveni faktor';

  @override
  String get settings_radioSettingsUpdated => 'Radio nastavitve posodobljene';

  @override
  String get settings_location => 'Lokacija';

  @override
  String get settings_locationSubtitle => 'GPS koordinate';

  @override
  String get settings_locationUpdated => 'Lokacija posodobljena';

  @override
  String get settings_locationBothRequired => 'Vnesite širino in dolžino.';

  @override
  String get settings_locationInvalid =>
      'Neveljavna zemeljska širina ali dolžina.';

  @override
  String get settings_locationGPSEnable => 'Omogoči GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Omogoči samodejno posodabljanje lokacije z GPS-jem.';

  @override
  String get settings_latitude => 'Širina';

  @override
  String get settings_longitude => 'Dolžina';

  @override
  String get settings_contactSettings => 'Nastavitve stika';

  @override
  String get settings_contactSettingsSubtitle =>
      'Nastavitve za dodajanje stikov.';

  @override
  String get settings_privacyMode => 'Zasebnost';

  @override
  String get settings_privacyModeSubtitle => 'Skrita imena/lokacije v oglasih';

  @override
  String get settings_privacyModeToggle =>
      'Omogoči način zasebnosti, da skrijemo tvoje ime in lokacijo v oglasih.';

  @override
  String get settings_privacyModeEnabled => 'Privatni način je omogočen.';

  @override
  String get settings_privacyModeDisabled => 'Privatni način je onemogočen.';

  @override
  String get settings_privacy => 'Nastavitve zasebnosti';

  @override
  String get settings_privacySubtitle =>
      'Kontrolirajte, katere informacije so deljene.';

  @override
  String get settings_privacySettingsDescription =>
      'Izberite, katere informacije vaš naprava deli z drugimi.';

  @override
  String get settings_denyAll => 'Zavrniti vse';

  @override
  String get settings_allowByContact => 'Dovoli po kontaktnih zastavah';

  @override
  String get settings_allowAll => 'Dovoli vse';

  @override
  String get settings_telemetryBaseMode => 'Osnovni način telemetrije';

  @override
  String get settings_telemetryLocationMode => 'Način delovanja telemetrije';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Način delovanja okolja telemetrije';

  @override
  String get settings_advertLocation => 'Lokacija oglasa';

  @override
  String get settings_advertLocationSubtitle => 'Vključi lokacijo v oglas.';

  @override
  String get settings_multiAck => 'Več potrdil';

  @override
  String get settings_telemetryModeUpdated => 'Način telemetrije posodobljen';

  @override
  String get settings_actions => 'Akcije';

  @override
  String get settings_sendAdvertisement => 'Pošlji Oglas';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Trenutna prisotnost v oddajah';

  @override
  String get settings_advertisementSent => 'Oglas poslan';

  @override
  String get settings_syncTime => 'Nastavi uro';

  @override
  String get settings_syncTimeSubtitle => 'Nastavi uro naprave na čas telefona';

  @override
  String get settings_timeSynchronized => 'Ura sinhronizirana';

  @override
  String get settings_refreshContacts => 'Ponovno obišči kontakte';

  @override
  String get settings_refreshContactsSubtitle =>
      'Ponovno naloži seznam stikov v napravi';

  @override
  String get settings_rebootDevice => 'Ponovni zagon naprave';

  @override
  String get settings_rebootDeviceSubtitle => 'Ponovno zaženi MeshCore napravo';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ste prepričani, da želite ponovno zagnati napravo? Povezava bo prekinjena.';

  @override
  String get settings_debug => 'Debug';

  @override
  String get settings_bleDebugLog => 'BLE debug log (razhroščevanje)';

  @override
  String get settings_bleDebugLogSubtitle =>
      'BLE ukazi, odgovori in surovi podatki';

  @override
  String get settings_appDebugLog => 'Logi aplikacije';

  @override
  String get settings_appDebugLogSubtitle => 'Debug sporočila aplikacije';

  @override
  String get settings_exportDatabase => 'Izvozi bazo sporočil';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Kopija vseh klepetov in stikov za odpravljanje napak. Hranite jo zasebno.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Baza shranjena v: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Izvoz ni uspel: $error';
  }

  @override
  String get settings_about => 'Oglejte si';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'Odprtokodni projekt MeshCore 2024';

  @override
  String get settings_aboutDescription =>
      'Odprtokodni Flutter klient za naprave za LoRa omrežje MeshCore.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Podatki o višini LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Ime';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Baterija';

  @override
  String get settings_infoPublicKey => 'Javni ključ';

  @override
  String get settings_infoContactsCount => 'Število stikov';

  @override
  String get settings_infoChannelCount => 'Število kanalov';

  @override
  String get settings_presets => 'Prednastavitve';

  @override
  String get settings_frequency => 'Frekvenca (MHz)';

  @override
  String get settings_frequencyHelper => '300,00 - 2500,00';

  @override
  String get settings_frequencyInvalid => 'Neveljavna frekvenca (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Pasovna širina';

  @override
  String get settings_spreadingFactor => 'Razširitveni faktor';

  @override
  String get settings_codingRate => 'Programska hitrost';

  @override
  String get settings_txPower => 'TX Moč (dBm)';

  @override
  String get settings_txPowerInvalid => 'Neveljavna TX moč';

  @override
  String get settings_clientRepeat => 'Neovadno ponavljanje';

  @override
  String get settings_clientRepeatSubtitle =>
      'Omogočite temu naprave, da ponavlja paketne sporočila za druge.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Za ponovni prenos na brezžični način so potrebne frekvence 433, 869 ali 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Napaka: $message';
  }

  @override
  String get appSettings_title => 'Nastavitve aplikacije';

  @override
  String get appSettings_appearance => 'Prikaži';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Sistemska tema';

  @override
  String get appSettings_themeLight => 'Svetlo';

  @override
  String get appSettings_themeDark => 'Temno';

  @override
  String get appSettings_language => 'Jezik';

  @override
  String get appSettings_languageSystem => 'Sistemska privzeta vrednost';

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
  String get appSettings_languageRu => 'Ruščina';

  @override
  String get appSettings_languageUk => 'Ukrajinsko';

  @override
  String get appSettings_enableMessageTracing => 'Omogoči sledenje sporočilom';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Prikaži podrobne metapodatke o usmerjanju in časovnem usklajevanju sporočil';

  @override
  String get appSettings_senderNameColors => 'Barvna imena pošiljateljev';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Vsak pošiljatelj v kanalu dobi svojo barvo imena. Izklopljeno pomeni barvo teme za vse.';

  @override
  String get appSettings_showTextFormatting => 'Prikaži oblikovanje besedila';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown v sporočilih: **krepko**, *ležeče*, ||spojlerji||, naslovi in povezave. Druge aplikacije MeshCore prikažejo surove znake.';

  @override
  String get appSettings_notifications => 'Obvestila';

  @override
  String get appSettings_enableNotifications => 'Omogoči obvestila';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Prejmite obvestila o sporočilih in oglasih';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Odobritev obvestila zavrnjena';

  @override
  String get appSettings_notificationsEnabled => 'Obvestila omogočena';

  @override
  String get appSettings_notificationsDisabled => 'Obvestila so izklopljena';

  @override
  String get appSettings_messageNotifications => 'Obvestila';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Pokaži obvestilo ob prejemu novih sporočil.';

  @override
  String get appSettings_channelMessageNotifications =>
      'Obvestila o sporočilih kanala';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Pokaži obvestilo ob prejemanju sporočil kanala';

  @override
  String get appSettings_advertisementNotifications => 'Opozorila o oglasih';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Pokaži obvestilo, ko so najdene nove naprave.';

  @override
  String get appSettings_messaging => 'Komuniciranje';

  @override
  String get appSettings_maxMessageRetries =>
      'Najve število poskusov pošiljanja sporočil';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Število poskusov ponovnega poslanja, preden se sporočilo označuje kot neuspešno';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Največ ponovitev sporočil v kanalu';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Ponavlja tolikokrat, dokler ne sliši vsaj ene ponovitve';

  @override
  String get appSettings_battery => 'Baterija';

  @override
  String get appSettings_batteryChemistry => 'Kemija baterije';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Nastavitev za napravo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Za izbiro se poveži z napravo';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Prikaz zemljevida';

  @override
  String get appSettings_showRepeaters => 'Prikaži repetitorje';

  @override
  String get appSettings_showRepeatersSubtitle => 'Prikaži repetitorje na mapi';

  @override
  String get appSettings_showChatNodes => 'Prikaži naprave za klepet';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Prikaži naprave na zemljevidu';

  @override
  String get appSettings_showOtherNodes => 'Pokaži druge naprave';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Pokaži druge vrste naprav na zemljevidu.';

  @override
  String get appSettings_timeFilter => 'Filter po času';

  @override
  String get appSettings_timeFilterShowAll => 'Pokaži vse naprave';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Pokaži naprave v zadnjih $hours urah';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filter časa na zemljevidu';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Pokaži naprave odkrite v:';

  @override
  String get appSettings_allTime => 'Brez omejitev';

  @override
  String get appSettings_lastHour => 'V zadnji uri';

  @override
  String get appSettings_last6Hours => 'Zadnjih 6 ur';

  @override
  String get appSettings_last24Hours => 'Zadnjih 24 ur';

  @override
  String get appSettings_lastWeek => 'Prejšnji teden';

  @override
  String get appSettings_unitsTitle => 'Enote';

  @override
  String get appSettings_unitsMetric => 'Metrična (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperialno (ft / mi)';

  @override
  String get appSettings_debugCard => 'Razhroščevanje';

  @override
  String get appSettings_appDebugLogging => 'Programski dnevnik';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Dnevnik debug sporočil za odpravljanje težav';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Beleženje napak v aplikaciji omogočeno';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Beleženje napak v aplikacije onemogočeno.';

  @override
  String get appSettings_incrementalContactSync =>
      'Postopna sinhronizacija stikov';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Ob ponovni povezavi od radia zahtevaj samo stike, spremenjene od zadnjič';

  @override
  String get contacts_title => 'Stiki';

  @override
  String get contacts_noContacts => 'Ni stikov.';

  @override
  String get contacts_shareMyQrCode => 'Deli mojo QR kodo';

  @override
  String get contacts_shareQrCodeDesc =>
      'Naj jo drugi skenirajo in vas dodajo kot stik';

  @override
  String get contacts_contactsWillAppear =>
      'Stiki se bodo prikazali, ko se naprave oglasijo.';

  @override
  String get contacts_unread => 'Neprebrano';

  @override
  String get contacts_searchContactsNoNumber => 'Iskanje stikov...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Iskanje stikov...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Iskanje $number$str priljubljenih...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Išči $number$str uporabnikov...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Išči $number$str ponavljalnike...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Išči $number$str strežnikov sob...';
  }

  @override
  String get contacts_noUnreadContacts => 'Ne prebrani stiki.';

  @override
  String get contacts_noContactsFound => 'Stiki niso najdeni.';

  @override
  String get contacts_deleteContact => 'Izbriši stik';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Ali res želite izbrisati $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Stik $contactName izbrisan.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Brisanje $contactName ni uspelo.';
  }

  @override
  String get contacts_noMatchingContacts => 'Noben stik ne ustreza filtru.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Izbrišem $contactName iz stikov?';
  }

  @override
  String get contacts_manageRepeater => 'Upravljaj Ponovitve';

  @override
  String get contacts_manageRoom => 'Upravljajte strežnik sobe';

  @override
  String get contacts_roomLogin => 'Prijava v sobo';

  @override
  String get contacts_openChat => 'Odpri klepet';

  @override
  String get contacts_editGroup => 'Uredi skupino';

  @override
  String get contacts_deleteGroup => 'Izbriši skupino';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Izbriši $groupName?';
  }

  @override
  String get contacts_newGroup => 'Nova skupina';

  @override
  String get contacts_groupName => 'Ime skupine';

  @override
  String get contacts_groupNameRequired => 'Ime skupine je obvezno.';

  @override
  String get contacts_groupNameReserved => 'To ime skupine je rezervirano';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Skupina \"$name\" že obstaja';
  }

  @override
  String get contacts_filterContacts => 'Filtriraj stik\\,...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Noben stik ne ustreza vašemu kriteriju.';

  @override
  String get contacts_noMembers => 'Ni članov.';

  @override
  String get contacts_lastSeenNow => 'Nazadnje viden zdaj';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Zadnjič viden pred $minutes minutami';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Zadnjič viden pred 1 uro.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Zadnjič viden pred $hours urami';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Zadnjič viden pred 1 dnem';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Zadnjič viden pred $days dnem';
  }

  @override
  String get contact_info => 'Kontaktni podatki';

  @override
  String get contact_settings => 'Nastavitve stika';

  @override
  String get contact_telemetry => 'Telemetrija';

  @override
  String get contact_lastSeen => 'Zadnjič videno';

  @override
  String get contact_clearChat => 'Počisti klepet';

  @override
  String get contact_teleBase => 'Baza telemetrije';

  @override
  String get contact_teleBaseSubtitle =>
      'Dovoli deljenje stanja baterije in osnovne telemetrije';

  @override
  String get contact_teleLoc => 'Lokacija telemetrije';

  @override
  String get contact_teleLocSubtitle => 'Dovoli deljenje podatkov o lokaciji';

  @override
  String get contact_teleEnv => 'Okolje telemetrije';

  @override
  String get contact_teleEnvSubtitle =>
      'Dovoli deljenje podatkov okoljskih senzorjev';

  @override
  String get contacts_publicKey => 'Javni ključ';

  @override
  String get channels_title => 'Kanali';

  @override
  String get channels_noChannelsConfigured => 'Kanali še niso konfigurirani';

  @override
  String get channels_addPublicChannel => 'Dodaj javni kanal';

  @override
  String get channels_searchChannels => 'Poišči kanale...';

  @override
  String get channels_noChannelsFound => 'Ne najdem kanalov.';

  @override
  String channels_channelIndex(int index) {
    return 'Kanal $index';
  }

  @override
  String get channels_hashtagChannel => 'Hashtag kanal';

  @override
  String get channels_public => 'Javni';

  @override
  String get channels_private => 'Zasebni';

  @override
  String get channels_publicChannel => 'Javni kanal';

  @override
  String get channels_privateChannel => 'Zasebni kanal';

  @override
  String get channels_editChannel => 'Uredi kanal';

  @override
  String get channels_shareChannel => 'Deli kanal';

  @override
  String get channels_shareChannelInstructions =>
      'Skenirajte QR kodo za dodajanje kanala.\nMeni → Dodaj Kanal → Skeniraj QR kodo';

  @override
  String get channels_secretKey => 'Skrivni ključ';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

  @override
  String get channels_shareChannelQr => 'Skenirajte QR kodo kanala';

  @override
  String get channels_shareChannelWarning =>
      'Opozorilo: Kdor skenira to QR kodo, bo imel dostop do tega kanala.';

  @override
  String get channels_muteChannel => 'Utišaj kanal';

  @override
  String get channels_unmuteChannel => 'Vklopi obvestila kanala';

  @override
  String get channels_deleteChannel => 'Pošlji kanal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Izbrišem \"$name\"? To se ne da povrniti.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kanala $name ni bilo mogoče izbrisati';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanal \"$name\" izbrisan.';
  }

  @override
  String get channels_addChannel => 'Dodaj Kanal';

  @override
  String get channels_channelIndexLabel => 'Indeks kanala';

  @override
  String get channels_channelName => 'Ime kanala';

  @override
  String get channels_usePublicChannel => 'Uporabi javni kanal';

  @override
  String get channels_standardPublicPsk => 'Standardni javni PSK';

  @override
  String get channels_pskHex => 'PSK (Šestnajstbinska)';

  @override
  String get channels_generateRandomPsk => 'Generiraj naključni PSK';

  @override
  String get channels_enterChannelName => 'Vnesi ime kanala';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK mora biti 32 heksadecimalnih znakov.';

  @override
  String get channels_addChannelConfirmation => 'Ali želite dodati ta kanal?';

  @override
  String get channels_channelAddedSuccess => 'Kanal uspešno dodan.';

  @override
  String get channels_noAvailableChannelSlots => 'Ni prostih mest za kanale.';

  @override
  String get appSettings_mentionNotifications => 'Obvestila o omembah';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Ko vas kdo omeni ali vam odgovori — tudi v utišanih kanalih';

  @override
  String notification_mentionIn(String channelName) {
    return 'Omemba v $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Kanal \"$name\" dodan';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Uredi Kanal $index';
  }

  @override
  String get channels_smazCompression => 'Kompresija SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanal $name je bil posodobljen';
  }

  @override
  String get channels_publicChannelAdded => 'javna skupnost dodana';

  @override
  String get channels_sortBy => 'Sortiraj po';

  @override
  String get channels_sortManual => 'Ročno';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Najnovejše sporočilo';

  @override
  String get channels_sortUnread => 'Nerešeno';

  @override
  String get channels_createPrivateChannel => 'Ustvari zasebno kanal.';

  @override
  String get channels_createPrivateChannelDesc =>
      'Varno zaklenjeno s skrivnim ključem.';

  @override
  String get channels_joinPrivateChannel => 'Pridružite se zasebni skupini';

  @override
  String get channels_joinPrivateChannelDesc => 'Ročno vnesite zaporni ključ.';

  @override
  String get channels_joinPublicChannel => 'Pridružite se javnemu kanalu';

  @override
  String get channels_joinPublicChannelDesc =>
      'Kdor karkoli je, lahko se pridruži tej skupini.';

  @override
  String get channels_joinHashtagChannel => 'Pridružite se Kanalu z Hashtagom';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Kdor karkoli, lahko se pridruži hashtag kanalom.';

  @override
  String get channels_scanQrCode => 'Skeniraj QR kodo';

  @override
  String get channels_scanQrCodeComingSoon => 'Prihajajoča';

  @override
  String get channels_enterHashtag => 'Vnesite hashtag';

  @override
  String get channels_hashtagHint => 'npr. #ekipa';

  @override
  String get chat_noMessages => 'Še ni sporočil.';

  @override
  String get chat_sendMessage => 'Pošlji sporočilo';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Pošlji sporočilo $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Pošlji sporočilo za začetek.';

  @override
  String get chat_originalMessageNotFound =>
      'Opozorilo: Sporočilo ni bilo najdeno';

  @override
  String chat_replyingTo(String name) {
    return 'Odgovarjanje $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Odpošlji odgovor $name';
  }

  @override
  String get chat_location => 'Lokacija';

  @override
  String get common_copiedToClipboard => 'Kopirano v odložišče';

  @override
  String get common_copyToClipboard => 'Kopiraj v odložišče';

  @override
  String get contacts_copyContactToClipboard => 'Kopiraj moj stik v odložišče';

  @override
  String get chat_typeMessage => 'Vnesi sporočilo...';

  @override
  String get chat_searchMessages => 'Iskanje sporočil';

  @override
  String get chat_searchNoMatches => 'Ni zadetkov';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Pošiljanje sporočila je onemogočeno, saj je preveliko (maksimalno $maxBytes byte-ov).';
  }

  @override
  String get chat_messageCopied => 'Sporočilo poslano';

  @override
  String get chat_messageDeleted => 'Sporočilo izbrisano';

  @override
  String get chat_sendGif => 'Pošlji GIF';

  @override
  String get chat_reply => 'Odgovori';

  @override
  String get chat_newMessages => 'NOVA SPOROČILA';

  @override
  String get chat_addReaction => 'Dodaj reakcijo';

  @override
  String get chat_mention => 'Omeni';

  @override
  String get dmChannel_menuLabel => 'Zasebno sporočilo';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Zasebno sporočilo za $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Preverite ključ in čas, ko je bil nazadnje viden — imena niso edinstvena.';

  @override
  String get dmChannel_warningTitle => 'Je to res ta oseba?';

  @override
  String get dmChannel_warningBody =>
      'Imena v kanalih si vsak izbere sam in jih lahko kdorkoli posnema. Pri čemer koli občutljivem najprej po drugi poti preverite javni ključ tega stika.';

  @override
  String get dmChannel_dontShowAgain => 'Ne prikaži več';

  @override
  String get batterySleep_title => 'Naj MeshTrax deluje';

  @override
  String get batterySleep_bodySamsung =>
      'Telefoni Samsung uspavajo aplikacije, da varčujejo z baterijo, kar prekine povezavo z vašim radiem. Odprite Nastavitve → Aplikacije → MeshTrax → Baterija in izberite Neomejeno. Preverite tudi Baterija → Omejitve uporabe v ozadju in se prepričajte, da MeshTrax ni na seznamu Aplikacije v mirovanju ali Aplikacije v globokem mirovanju.';

  @override
  String get batterySleep_bodyGeneric =>
      'Telefon lahko MeshTrax v ozadju ustavi, da varčuje z baterijo, kar prekine povezavo z vašim radiem. Odprite nastavitve baterije in za MeshTrax nastavite Neomejeno (ali Brez omejitev). Na nekaterih telefonih morate za MeshTrax vklopiti tudi Samodejni zagon.';

  @override
  String get batterySleep_openSettings => 'Odpri nastavitve';

  @override
  String get batterySleep_notNow => 'Ne zdaj';

  @override
  String get batterySleep_settingsTile => 'Naj MeshTrax deluje v ozadju';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Preprečite, da bi varčevanje z baterijo uspavalo MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Zasebnega sporočila za $name še ni mogoče poslati';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Ključa te osebe še nimate, ona pa za odgovor potrebuje vašega — ključi potujejo samo v oglasih. \"Pošlji moj oglas\" odda vašega kar od tu. \"Vprašaj v kanalu\" v polje za sporočilo napiše prošnjo, ki jo nato pošljete.';

  @override
  String get dmChannel_askInChannel => 'Vprašaj v kanalu';

  @override
  String get dmChannel_sendMyAdvert => 'Pošlji moj oglas';

  @override
  String get dmChannel_askText =>
      'prosim, pošlji oglas, da ti lahko pišem zasebno';

  @override
  String get dmChannel_watching =>
      'Čakam na oglas te osebe — ko prispe, boste tukaj dobili vprašanje.';

  @override
  String dmChannel_advertHeard(String name) {
    return 'Stik $name je zdaj dosegljiv';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Raven povečave';

  @override
  String get common_reset => 'Ponastavi';

  @override
  String get chat_reactionsTitle => 'Odzivi';

  @override
  String get chat_reactionUnknownSender => 'Neznan';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender: odziv na sporočilo, ki ga ni v tem klepetu';
  }

  @override
  String get chat_me => 'jaz';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Gestikulacije';

  @override
  String get emojiCategoryHearts => 'Srce';

  @override
  String get emojiCategoryObjects => 'Predmeti';

  @override
  String get gifPicker_title => 'Izberi GIF';

  @override
  String get gifPicker_searchHint => 'Išči GIF-e...';

  @override
  String get gifPicker_poweredBy => 'Napredno z GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Ne najdem GIF-ov.';

  @override
  String get gifPicker_failedLoad => 'Neuspešno nalaganje GIF-a';

  @override
  String get gifPicker_failedSearch => 'Iskanje neuspešno.';

  @override
  String get gifPicker_noInternet => 'Ni internetne povezave';

  @override
  String get debugLog_appTitle => 'Log zapiske aplikacije';

  @override
  String get debugLog_bleTitle => 'Log zapis BLE';

  @override
  String get debugLog_copyLog => 'Kopiraj dnevnik';

  @override
  String get debugLog_saveLog => 'Shrani dnevnik v datoteko';

  @override
  String get debugLog_saved => 'Dnevnik shranjen';

  @override
  String get debugLog_saveCancelled => 'Shranjevanje preklicano';

  @override
  String get debugLog_filterAll => 'Vse';

  @override
  String get debugLog_filterWarnings => 'Opozorila';

  @override
  String get debugLog_filterErrors => 'Napake';

  @override
  String get debugLog_clearLog => 'Briši log';

  @override
  String get debugLog_copied => 'Beležka kopirana.';

  @override
  String get debugLog_bleCopied => 'Kopirana beležka iz BLE';

  @override
  String get debugLog_noEntries => 'Ni ustvarjenih debug zapisov.';

  @override
  String get debugLog_enableInSettings =>
      'Omogoči beleženje napak v nastavitvah aplikacije';

  @override
  String get debugLog_frames => 'Okvirji';

  @override
  String get debugLog_rawLogRx => 'Svež Log-RX';

  @override
  String get debugLog_noBleActivity => 'Ni BLE aktivnosti.';

  @override
  String debugFrame_length(int count) {
    return 'Izhodni rob: $count bajtov';
  }

  @override
  String debugFrame_command(String value) {
    return 'Navodilo: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Obvestilo:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destinirano Ključno Besedilo: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Časovnik: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Ploki: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tip besedila: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Ukaz CLI';

  @override
  String get debugFrame_textTypePlain => 'Preprosto';

  @override
  String debugFrame_text(String text) {
    return '- Tekst: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex Dump:';

  @override
  String get chat_hopSingular => 'skok';

  @override
  String get chat_hopPlural => 'skokov';

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
  String get chat_setCustomPath => 'Nastavi Prilozeno Pot';

  @override
  String get chat_fullPath => 'Polna pot';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Podrobnosti poti zaenkrat niso na voljo. Poskusite poslati sporočilo za osvežitev.';

  @override
  String get chat_type => 'Vnesite';

  @override
  String get chat_path => 'Pot';

  @override
  String get chat_publicKey => 'Ključ javnega tipa';

  @override
  String get chat_compressOutgoingMessages => 'Stisnite izhodne sporočila';

  @override
  String get chat_floodForced => 'Porolni (nasilje).';

  @override
  String get chat_directForced => 'Nezglašen (nasilje)';

  @override
  String chat_hopsForced(int count) {
    return '$count skoki (nasilje)';
  }

  @override
  String get chat_floodAuto => 'Preplavljenje (avtomatizirano)';

  @override
  String get chat_direct => 'Neposredni';

  @override
  String get chat_poiShared => 'Deljeno točke MN';

  @override
  String chat_unread(int count) {
    return 'Nerešeno: $count';
  }

  @override
  String get chat_openLink => 'Odpreti povezavo?';

  @override
  String get chat_openLinkConfirmation =>
      'Ali želite odpreti to povezavo v brskalniku?';

  @override
  String get chat_open => 'Odpri';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Povezave ni bilo mogoče odpreti: $url';
  }

  @override
  String get chat_invalidLink => 'Neveljavna oblika povezave';

  @override
  String get map_lineOfSight => 'Linija vida';

  @override
  String get map_losScreenTitle => 'Linija vida';

  @override
  String get map_noNodesWithLocation =>
      'Nihče od notranjih elementov nima podatkov o lokaciji.';

  @override
  String get map_nodesNeedGps =>
      'Omrežje morajo deliti svoje GPS koordinate,\nda se prikazao na zemljeobrazniku.';

  @override
  String map_nodesCount(int count) {
    return 'Omize: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Žigovi: $count';
  }

  @override
  String get map_chat => 'Čistemar';

  @override
  String get map_repeater => 'Ponovitelj';

  @override
  String get map_room => 'Soba';

  @override
  String get map_sensor => 'Senzor';

  @override
  String get map_pinDm => 'Zavežite (DM)';

  @override
  String get map_pinPrivate => 'Zasebno označit';

  @override
  String get map_pinPublic => 'Oznaka (javna)';

  @override
  String get map_lastSeen => 'Zadnjič Zazet';

  @override
  String get map_disconnectConfirm =>
      'Ste prepričani, da želite se odklopiti s tega naprave?';

  @override
  String get map_from => 'Od';

  @override
  String get map_source => 'Vir';

  @override
  String get map_flags => 'Zapestnice';

  @override
  String get map_shareMarkerHere => 'Delite točke tukaj.';

  @override
  String get map_setAsMyLocation => 'Nastavite to kot mojo lokacijo';

  @override
  String get map_pinLabel => 'Oznaka za pritrditev';

  @override
  String get map_label => 'Oznaka';

  @override
  String get map_pointOfInterest => 'Točka zanimivosti';

  @override
  String get map_sendToContact => 'Pošlji v kontakt';

  @override
  String get map_sendToChannel => 'Pošlji v kanal';

  @override
  String get map_noChannelsAvailable => 'Nihče kanalov na voljo.';

  @override
  String get map_publicLocationShare => 'Deljenje javne lokacije';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Kljubite boste delili lokacijo v $channelLabel. Ta kanal je javno dostopen in vsak, ki ima PSK, ga lahko vidi.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Povežite se z napravo za deljenje oznak.';

  @override
  String get map_filterNodes => 'Filtirirajte člene';

  @override
  String get map_chatNodes => 'Čuti zvezde';

  @override
  String get map_repeaters => 'Ponovljalniki';

  @override
  String get map_otherNodes => 'Druge vozlišča';

  @override
  String get map_showOverlaps => 'Prekrivanje ključa ponovnega predvajanja';

  @override
  String get map_keyPrefix => 'Predpona ključa';

  @override
  String get map_filterByKeyPrefix => 'Filtri po predpomniku ključa';

  @override
  String get map_publicKeyPrefix => 'Predifika javnega ključa';

  @override
  String get map_showDiscoveryContacts => 'Prikaži odkritja kontaktov';

  @override
  String get map_guessedLocation => 'Predpostavljena lokacija';

  @override
  String get map_lastSeenTime => 'Datum zadnjega vpogleda';

  @override
  String get map_sharedPin => 'Deljeno naslovno geslo';

  @override
  String get map_joinRoom => 'Pridružiti sobo';

  @override
  String get map_manageRepeater => 'Upravljajte Ponovitve';

  @override
  String get map_tapToAdd => 'Pritisnite na vozlišča, da jih dodate poti.';

  @override
  String get map_runTrace => 'Zaženi sledenje poti';

  @override
  String get map_runTraceWithReturnPath => 'Vrni se nazaj po isti poti.';

  @override
  String get map_removeLast => 'Odstrani Zadnji';

  @override
  String get map_pathTraceCancelled => 'Spremljanje poti je prekinjeno.';

  @override
  String get time_justNow => 'Takoj';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minut nazaj';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h nazaj';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dni nazaj';
  }

  @override
  String get time_hour => 'ure';

  @override
  String get time_hours => 'ure';

  @override
  String get time_day => 'dan';

  @override
  String get time_days => 'dani';

  @override
  String get time_week => 'teden';

  @override
  String get time_weeks => 'tedne';

  @override
  String get time_month => 'mesec';

  @override
  String get time_months => 'mesi';

  @override
  String get time_minutes => 'minute';

  @override
  String get time_allTime => 'Vse časovno obdobje';

  @override
  String get dialog_disconnect => 'Odklopiti';

  @override
  String get dialog_disconnectConfirm =>
      'Ste prepričani, da želite se odklopiti s tega naprave?';

  @override
  String get login_repeaterLogin => 'Ponovni vnos';

  @override
  String get login_roomLogin => 'Vnos v sobo';

  @override
  String get login_password => 'Geslo';

  @override
  String get login_enterPassword => 'Vnesite geslo';

  @override
  String get login_savePassword => 'Shrani geslo';

  @override
  String get login_savePasswordSubtitle =>
      'Geslo bo shranjeno varno na tem pripravem.';

  @override
  String get login_repeaterDescription =>
      'Vnesite geslo za ponovljalnik, da dostopite do nastavitev in statusa.';

  @override
  String get login_roomDescription =>
      'Vnesite geslo v sobo za dostop do nastavitev in statusa.';

  @override
  String get login_login => 'Prijava';

  @override
  String login_attempt(int current, int max) {
    return 'Poskušajo $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Prijava je bila neuspešna: $error';
  }

  @override
  String get login_failedMessage =>
      'Prijava je bila neuspešna. Geslo je napačno ali pa je repetitor nedosegljiv.';

  @override
  String get common_reload => 'Ponovno naloži';

  @override
  String get common_clear => 'Ponoviti';

  @override
  String get path_enterCustomPath => 'Vnesite prilagojeno pot';

  @override
  String get path_currentPathLabel => 'Trenutna pot';

  @override
  String get path_hexPrefixInstructions =>
      'Vnesite 2-karakterne heksadecimalne prefixe za vsako skopo, ločeno z zvezekami.';

  @override
  String get path_hexPrefixExample =>
      'Primer: A1,F2,3C (vsak notranji element uporablja prvi bajt svojega javnega ključa)';

  @override
  String get path_labelHexPrefixes => 'Pot (heksafixne skrajšave)';

  @override
  String get path_helperMaxHops =>
      'Maksimalno 64 skokov. Vsak prefiks je 2 heksadecimalna znamenja (1 bajt).';

  @override
  String get path_selectFromContacts => 'Izberi iz kontaktov:';

  @override
  String get path_noRepeatersFound =>
      'Ne najdenih ponoviteljev ali strežnikov sob.';

  @override
  String get path_customPathsRequire =>
      'Prilojene poti zahtevajo medhodne prenose, ki lahko prenašajo sporočila.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Neveljačni šesteročlenski prefiksi: $prefixes';
  }

  @override
  String get path_tooLong => 'Pot je prevelika. Dovoljeno največ 64 skokov.';

  @override
  String get path_setPath => 'Nastavi Pot';

  @override
  String get repeater_management => 'Upravljanje ponovitve';

  @override
  String get room_management => 'Upravljanje stremlišča';

  @override
  String get repeater_guest => 'Informacije o ponovljalniku';

  @override
  String get room_guest => 'Informacije o strežniku';

  @override
  String get repeater_managementTools => 'Upravne orodje';

  @override
  String get repeater_guestTools => 'Naložila za goste';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Pogledati stanje, statistike in sosede repeatera';

  @override
  String get repeater_telemetry => 'Telemetrija';

  @override
  String get repeater_telemetrySubtitle =>
      'Pogledate telemetrijo senzorjev in sistemske statistike';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle =>
      'Pošlji ukazne povelje na ponovitveno enoto.';

  @override
  String get repeater_neighbors => 'Sosedi';

  @override
  String get repeater_neighborsSubtitle => 'Pogledati nič sosednjih hopjev.';

  @override
  String get repeater_settings => 'Nastavitve';

  @override
  String get repeater_settingsSubtitle =>
      'Konfigurirajte parametre ponovitelja';

  @override
  String get repeater_clockSyncAfterLogin => 'Sinhronizacija ure po prijavi';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Samodejno po uspešnem vstopu pošljite obvestilo o sinhronizaciji časa.';

  @override
  String get repeater_statusTitle => 'Status ponovitelja';

  @override
  String get repeater_refresh => 'Ponovno obnavljati';

  @override
  String get repeater_statusRequestTimeout => 'Zahtev statusa je iztekla.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Napaka pri obnašanju: $error';
  }

  @override
  String get repeater_systemInformation => 'Informacije o sistemu';

  @override
  String get repeater_battery => 'Baterija';

  @override
  String get repeater_clockAtLogin => 'Ure (pri prijavi)';

  @override
  String get repeater_uptime => 'Čas delovanja';

  @override
  String get repeater_queueLength => 'Dolžina čakalne vrste';

  @override
  String get repeater_debugFlags => 'Nastavitve odpravilnosti';

  @override
  String get repeater_radioStatistics => 'Radio Statistika';

  @override
  String get repeater_lastRssi => 'Potredno RSSI';

  @override
  String get repeater_lastSnr => 'Nazadnje zabeležena SNR';

  @override
  String get repeater_noiseFloor => 'Šumovita raven';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Statistika paketa';

  @override
  String get repeater_sent => 'Pošljeno';

  @override
  String get repeater_received => 'Prejeto';

  @override
  String get repeater_duplicates => 'Duplikati';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dni ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Skupno: $total, Poplava: $flood, Neposredno: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Skupno: $total, Poplava: $flood, Neposredno: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Prah: $flood, Neposredni: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Skupno: $total';
  }

  @override
  String get repeater_settingsTitle => 'Nastavitve ponovitelja';

  @override
  String get repeater_basicSettings => 'Osnovne nastavitve';

  @override
  String get repeater_repeaterName => 'Ime ponovitelja';

  @override
  String get repeater_repeaterNameHelper => 'Prikaz imena za ta ponovitelj.';

  @override
  String get repeater_adminPassword => 'Admin geslo';

  @override
  String get repeater_adminPasswordHelper => 'Polni dostopno geslo';

  @override
  String get repeater_guestPassword => 'Geslo gostača';

  @override
  String get repeater_guestPasswordHelper => 'Odpovedni dostopni geslo';

  @override
  String get repeater_radioSettings => 'Nastavitve Radija';

  @override
  String get repeater_frequencyMhz => 'Frekvenca (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Moč';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Pasovna širina';

  @override
  String get repeater_spreadingFactor => 'Razširitveni faktor';

  @override
  String get repeater_codingRate => 'Programska hitrost';

  @override
  String get repeater_locationSettings => 'Nastavitve lokacije';

  @override
  String get repeater_latitude => 'Širina';

  @override
  String get repeater_latitudeHelper => 'Desetbinske protiure (npr. 37.7749)';

  @override
  String get repeater_longitude => 'Dolžina';

  @override
  String get repeater_longitudeHelper =>
      'Desetbinske protiure (npr. -122,4194)';

  @override
  String get repeater_features => 'Značilnosti';

  @override
  String get repeater_packetForwarding => 'Usmerjanje paketa';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Omogoči ponovitelja za usmerjanje paketov.';

  @override
  String get repeater_guestAccess => 'Prijemnik';

  @override
  String get repeater_guestAccessSubtitle =>
      'Omogoči dostop gostom v samo bralni načinu.';

  @override
  String get repeater_privacyMode => 'Privatni način';

  @override
  String get repeater_privacyModeSubtitle => 'Skrita imena/lokacije v oglasih';

  @override
  String get repeater_advertisementSettings => 'Nastavitve oglasnika';

  @override
  String get repeater_localAdvertInterval => 'Lokalen Oglasovni Razpon';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minut';
  }

  @override
  String get repeater_floodAdvertInterval => 'Razpon Obvestil o Poplavah';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours ur';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Šifrirana Oglasovalska Trajanje';

  @override
  String get repeater_dangerZone => 'Opozorilo';

  @override
  String get repeater_rebootRepeater => 'Ponovni zagon Repeaterja';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Ponovni zagon ponovitelja.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ste prepričani, da želite ponovno zagon tega ponovitelja?';

  @override
  String get repeater_regenerateIdentityKey => 'Ponovite Ključ Identnosti';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Ustvarite novo par javnih/zasebnih ključev';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'To bo ustvaril novo identiteto za ponavljalnik. Prijavite se?';

  @override
  String get repeater_eraseFileSystem => 'Počisti Sustav Vajah';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Oblikuj datoteko ponovitve sistema';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'OPOZORILO: To bo izbrisal/a vsa dejstva na ponovilu. To ni mogoče povzvrniti!';

  @override
  String get repeater_eraseSerialOnly =>
      'Brisanje je na voljo samo preko serijske konzole.';

  @override
  String repeater_commandSent(String command) {
    return 'Navodilo poslano: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Napaka pri pošiljanju ukaznega: $error';
  }

  @override
  String get repeater_confirm => 'Potrdit';

  @override
  String get repeater_settingsSaved => 'Nastavitve so shranjene uspešno.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Napaka pri shranjevanju nastavitev: $error';
  }

  @override
  String get repeater_refreshBasicSettings =>
      'Ponovno nastavi osnovne nastavitve';

  @override
  String get repeater_refreshRadioSettings => 'Ponovno Nastavitve Radija';

  @override
  String get repeater_refreshTxPower => 'Ponovno nastavi TX moč';

  @override
  String get repeater_refreshLocationSettings =>
      'Ponovno Nastavi Nastavitve Lokacije';

  @override
  String get repeater_refreshPacketForwarding =>
      'Ponovno nastavitve usmerjevanja paketa';

  @override
  String get repeater_refreshGuestAccess => 'Ponovno nastavitve dostopa gostov';

  @override
  String get repeater_refreshPrivacyMode =>
      'Ponovno aktiviraj način zasebnosti';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Ponovno nastavi Oglede Oglasi';

  @override
  String repeater_refreshed(String label) {
    return '$label je bil/a posodobljen/a';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Napaka pri osveževanju $label';
  }

  @override
  String get repeater_cliTitle => 'Ponovitelj CLI';

  @override
  String get repeater_debugNextCommand => 'Popravi naslednje ukazne možnosti';

  @override
  String get repeater_commandHelp => 'Pomoc';

  @override
  String get repeater_clearHistory => 'Ponovi zgodovino';

  @override
  String get repeater_noCommandsSent =>
      'Niti ena ukazne povratne informacije še ni poslana.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Vnesite ukaz spodaj ali uporabite hitre ukaze';

  @override
  String get repeater_enterCommandHint => 'Vnesite ukaz...';

  @override
  String get repeater_previousCommand => 'Prejšnji ukaz';

  @override
  String get repeater_nextCommand => 'Naslednja ukazna';

  @override
  String get repeater_enterCommandFirst => 'Vnesite ukaz najprej';

  @override
  String get repeater_cliCommandFrameTitle => 'Okno ukazne vrstice';

  @override
  String repeater_cliCommandError(String error) {
    return 'Napaka: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Pridobi ime';

  @override
  String get repeater_cliQuickGetRadio => 'Dobiti Radiopravo';

  @override
  String get repeater_cliQuickGetTx => 'Pridobi TX';

  @override
  String get repeater_cliQuickNeighbors => 'Sosedi';

  @override
  String get repeater_cliQuickVersion => 'Različica';

  @override
  String get repeater_cliQuickAdvertise => 'Oglasite';

  @override
  String get repeater_cliQuickClock => 'Ura';

  @override
  String get repeater_cliQuickClockSync => 'Usklajevanje ure';

  @override
  String get repeater_cliQuickDiscovery => 'Odkrijte sosede';

  @override
  String get repeater_cliHelpAdvert => 'Pošlje paket oglasov';

  @override
  String get repeater_cliHelpReboot =>
      'Ponastavi naprave. (Opomba, lahko pride do \'Timeouta\', kar je normalno)';

  @override
  String get repeater_cliHelpClock => 'Prikaže trenutno uro po uri naprave.';

  @override
  String get repeater_cliHelpPassword =>
      'Nastavi novo administracijsko geslo za naprave.';

  @override
  String get repeater_cliHelpVersion =>
      'Prikaže različico naprave in datum izrabe strojne opreme.';

  @override
  String get repeater_cliHelpClearStats =>
      'Ponastavi različne statistične števke na nič.';

  @override
  String get repeater_cliHelpSetAf => 'Nastavi časovni koeficient.';

  @override
  String get repeater_cliHelpSetTx =>
      'Nastavi moč LoRa oddajanja v dBm. (za ponovni zagon za uporabo)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Omogoči ali onemogoči vlogo ponovitelja za tono.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Osebni strežnik) Če je \'vklopljeno\', potem bo dovoljeno prijavo z praznim geslom, vendar ne bo mogoče objaviti v sobo. (samo branje).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Nastavi največjo število skokov za vstopne poplave (če je >= maks, paket ni usmerjen)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Nastavi Prag Interferencij (v dB). Privzeto je 14. Nastavi na 0 za onemogočitev zaznavanja interferenc kanalov.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Nastavi časovno razdaljo za ponovni zagon nadzornika Avtomatske uteži. Nastavi na 0 za onemogočanje.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Omogoči ali onemogoči funkcijo \"dvojakih potrdil\".';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Nastavi časovno obmesto v minutah za pošiljanje lokalnega (brezposrednega) napovednega paketa. Nastavi na 0 za onemogočiti.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Nastavi časovno obmesto v urah za pošiljanje plovilnega oglasnega paketa. Nastavi na 0 za onemogočanje.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Nastavi/posodobi geslo gosta. (za ponovitve lahko gostov prijavi pošiljajo zahtevo \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Nastavi ime oglasnika.';

  @override
  String get repeater_cliHelpSetLat =>
      'Nastavi zemljepisno širino oglaševalskega zemljevida (desetdeljne).';

  @override
  String get repeater_cliHelpSetLon =>
      'Nastavi zemljevidno širino oglasnika. (desetdelne stopnje)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Nastavi popolnoma nove radijske parametre in jih shranjuje v nastavitve. Za uporabo je potrebna \"restart\" ukaz.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Nastavitve (eksperimentalne) osnova (mora biti > 1 za učinkovanje) za uporabo rahle zakasnitve prejetih paketov, glede na moč signala/rezultat. Nastavite na 0 za onemogočanje.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Nastavi faktor, ki se množi s časom delovanja za paket v načinu poplavnega režima in z randomiziranim sistemom slotov, da odvrne njegovo posredovanje. (da se zmanjša verjetnost kolizij)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Ima podobno vrednost kot txdelay, vendar jo lahko uporabite za dodajanje naknadnega zamika pri posredovanju paketov v režimu neposredne prevodi.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Omogoči/Preklopi most.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Nastavi zamik pred ponovnim poslanjem paketov.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Izberite, ali bodo most ponavljali prejeto ali poslan paket.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Nastavi hitrost serijske povezave za mostove rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Nastavi skrivni dostop za mostove ESPNOW.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Nastavi prilagoditev faktorja za prilagoditev poravnalnega napetosti baterije (podprt le na izbranih ploščah).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Nastavi začasne radio parametre za določeno časovno obdobje, kar po preteku časa vrne originalne radio parametre. (ne shranjuje v preferencije).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modificira ACL. Odstrani ustrezen vnos (po predponi pubkeyja), če je \"permissions\" enako nič. Dodaja nov vnos, če je pubkey-hex v celoti in trenutno ni v ACL. Posodobi vnos po ustreznem predponi pubkeyja. Bitje dovoljenj se razlikuje glede na firmware vlogo, vendar so prvi dve bitki: 0 (Gost), 1 (Lezenje samo), 2 (Lezenje in pisanje), 3 (Administrator).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Dobrodošli pri izbiri vrste mostu: brez, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Začnete beleženje paketov v datotekovni sistem.';

  @override
  String get repeater_cliHelpLogStop =>
      'Ustavite beleženje paketov v datotečno sistem.';

  @override
  String get repeater_cliHelpLogErase =>
      'Izbriše pakete zapisov iz datotek sistema.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Prikaže seznam drugih ponovnih knopov, do katerih je prišlo preko brezposrednih oglasov. Vsaka vrstica je id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Izbriše prvo ustreznu postavko (po predpomnilku pubkey (heks),) iz seznama sosedov.';

  @override
  String get repeater_cliHelpRegion =>
      '(Serija samo) Navaja vse definirane regije in trenutne poplave dovolilnosti.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Opomba: to je posebna več ukazna pozivna operacija. Vsak naslednji ukaz je ime regije (z lezijami za prikaz hierarhije, z enim ustvarjenim razmislom). Zaključena s pošiljanjem praznega reda/ukaza.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Išče regijo s podanimi imenimi prefiksom (ali \"\\\" za globalni obseg). Odgovori se s \"-> regija-ime (rodič-ime) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Dodaja ali posodobi regijsko definicijo s podanim imenom.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Izbriše definicijo regije s podanim imenom. (mora se popolnoma ujemati in ne sme imeti podregij)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Nastavi dovoljenje \'Nere\' za podano regijo. (\'\' za globalni/dedni obseg)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Odstrani dovoljenje \'F\'lood\' za podano regijo. (OPOZORILO: na tem koraku ni priporočljivo ga uporabljati na globalnem/dednem obsegu!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Odgovori z trenutnim \'domovim\' območjem. (Opomba je bila še nujno uporabljena, rezervirano za prihodnost)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Nastavi regijo \'domov\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Shrani seznam/ zemljevzemi regij v shranjevanje.';

  @override
  String get repeater_cliHelpGps =>
      'Pokaže status GPS-ja. Če je GPS izklopljen, odgovarja samo \"off\", če je vklopljen, odgovarja z \"on\", statusom, \"fix\" in štetjem satelitiv.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Omogoči/onameni GPS način delovanja.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sinhronizira čas časa ničala z gps uro.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Nastavi položaj časa na GPS koordinate in shranjevanje preferencij.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Omogoča konfiguracijo oglasi za notranjost člana:\n- none: ne vključevati lokacije v oglasih\n- share: deliti gps lokacijo (iz SensorManager)\n- prefs: oglaševati lokacijo shranjeno v preferencah';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Nastavi konfiguracijo oglasa na določenem mestu.';

  @override
  String get repeater_commandsListTitle => 'Seznam ukazov';

  @override
  String get repeater_commandsListNote =>
      'Opomba: za različne ukaze \"nastavi ...\" obstaja tudi ukaz \"dobi ...\".';

  @override
  String get repeater_general => 'Općenito';

  @override
  String get repeater_settingsCategory => 'Nastavitve';

  @override
  String get repeater_bridge => 'Most';

  @override
  String get repeater_logging => 'Logiranje';

  @override
  String get repeater_neighborsRepeaterOnly => 'Sosedi (le za repetitorje)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Upravljanje regij (zgolj za repetitorje)';

  @override
  String get repeater_regionNote =>
      'Regionske ukazi so bili uvedeni za upravljanje z regijskimi definicijami in dovolili.';

  @override
  String get repeater_gpsManagement => 'Upravljanje GPS';

  @override
  String get repeater_gpsNote =>
      'GPS ukaz je bil uveden za upravljanje z vprašanji, povezanimi z lokacijo.';

  @override
  String get telemetry_receivedData => 'Prejeto Telemetrično podatke';

  @override
  String get telemetry_requestTimeout => 'Zahtev telemetrije je iztekla.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Napaka pri obnašanju telemetrije: $error';
  }

  @override
  String get telemetry_noData => 'Niso na voljo podatki o telemetriji.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Baterija';

  @override
  String get telemetry_voltageLabel => 'Napetost';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU Temperatura';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Trenutno';

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
  String get neighbors_receivedData => 'Prejeto podatke o sosedih';

  @override
  String get neighbors_requestTimedOut =>
      'Sosedi zahtevajo izklop po dogovoru.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Napaka pri obnašanju sosedov: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ponovitve Sosedi';

  @override
  String get neighbors_noData => 'Niso na voljo podatki o sosedih.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Nepoznano $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Udeleženec je prejel sporočilo $time nazaj.';
  }

  @override
  String get channelPath_title => 'Pot do paketa';

  @override
  String get channelPath_viewMap => 'Prikaži zemljeznico';

  @override
  String get channelPath_otherObservedPaths => 'Drugi opazovani poti';

  @override
  String get channelPath_repeaterHops => 'Skoki ponovitelja';

  @override
  String get channelPath_noHopDetails =>
      'Podrobnosti o paketu za dostavo niso navedene.';

  @override
  String get channelPath_messageDetails => 'Podrobnosti sporočila';

  @override
  String get channelPath_senderLabel => 'Pošiljatelj';

  @override
  String get channelPath_timeLabel => 'Ura';

  @override
  String get channelPath_repeatsLabel => 'Ponovitve';

  @override
  String channelPath_pathLabel(int index) {
    return 'Pot $index';
  }

  @override
  String get channelPath_observedLabel => 'Opazovani';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Opazovana pot $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Nihče ni določil lokacije.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Neznano';

  @override
  String get channelPath_floodPath => 'Prebivalstvo';

  @override
  String get channelPath_directPath => 'Neposredni';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 iz $total skokov';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed iz $total skokov';
  }

  @override
  String get channelPath_mapTitle => 'Potni zemljevid';

  @override
  String get channelPath_noRepeaterLocations =>
      'Ni na voljo nobenih lokacij za ponovitelja za to pot.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Pot $index (Glavni)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Pot';

  @override
  String get channelPath_observedPathHeader => 'Opazovana pot';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Niso na voljo podrobnosti o letu.';

  @override
  String get channelPath_unknownRepeater => 'Nepoznati ponovitelj';

  @override
  String get community_title => 'Skupnost';

  @override
  String get community_create => 'Ustvari skupnost';

  @override
  String get community_createDesc =>
      'Ustvari novo skupnost in jo deli preko QR kode.';

  @override
  String get community_join => 'Pridružiti se';

  @override
  String get community_joinTitle => 'Pridružite se skupnosti';

  @override
  String community_joinConfirmation(String name) {
    return 'Želiš se pridružiti skupnosti \"$name\"?';
  }

  @override
  String get community_scanQr => 'Skeniraj QR kode skupnosti';

  @override
  String get community_scanInstructions =>
      'Nasmerite kamero s skupnostnim QR kodom.';

  @override
  String get community_showQr => 'Pokaži QR kodo';

  @override
  String get community_publicChannel => 'Skupnostna javna';

  @override
  String get community_hashtagChannel => 'Skupnostni hashtag';

  @override
  String get community_name => 'Komunitarne ime';

  @override
  String get community_enterName => 'Vnesite ime skupnosti';

  @override
  String community_created(String name) {
    return 'Skupnost \"$name\" je bila ustvarila.';
  }

  @override
  String community_joined(String name) {
    return 'Prilojen k skupnosti \"$name\"';
  }

  @override
  String get community_qrTitle => 'Delite skupnost';

  @override
  String community_qrInstructions(String name) {
    return 'Skenirajte to QR kodo za vključitev $name.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Hashtag kanali skupnosti so dostopni samo članom skupnosti';

  @override
  String get community_invalidQrCode => 'Neveljaven QR koden skupnosti';

  @override
  String get community_alreadyMember => 'Že član';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Kljub temu ste že član/ka $name.';
  }

  @override
  String get community_addPublicChannel => 'Dodaj Objavni Kanal Komunitarja';

  @override
  String get community_addPublicChannelHint =>
      'Samodejno dodaj javni kanal za to skupnost.';

  @override
  String get community_noCommunities => 'Še nobena skupnost se ni pridružila.';

  @override
  String get community_scanOrCreate =>
      'Skeniraj QR kodo ali ustvari skupnost za začetek.';

  @override
  String get community_manageCommunities => 'Upravljanje skupnosti';

  @override
  String get community_delete => 'Opusti skupnost';

  @override
  String community_deleteConfirm(String name) {
    return 'Zapusti \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'To bo izbrisalo tudi $count kanal/kanalov in njihova sporočila.';
  }

  @override
  String community_deleted(String name) {
    return 'Zapustil skupnost \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Ponovno ustvari geslo';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Preberite novo tajno geslo za \"$name\"? Vsi članici morajo prebrati novo QR kodo, da lahko nadaljujejo s komunikacijo.';
  }

  @override
  String get community_regenerate => 'Preberi znova';

  @override
  String community_secretRegenerated(String name) {
    return 'Geslo za \"$name\" ponovno ustvarjeno';
  }

  @override
  String get community_updateSecret => 'Ažuriraj ključ';

  @override
  String community_secretUpdated(String name) {
    return 'Skrivnostno spremembo za \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Skeniraj novo QR kodo za posodabljanje ključa za $name';
  }

  @override
  String get community_addHashtagChannel => 'Dodaj hashtag kanal';

  @override
  String get community_addHashtagChannelDesc =>
      'Dodajte hashtag kanal za to skupnost.';

  @override
  String get community_selectCommunity => 'Izberi skupnost';

  @override
  String get community_regularHashtag => 'Oznaka s hashtagom';

  @override
  String get community_regularHashtagDesc =>
      'javna oznaka (kdorkoli lahko sodeluje)';

  @override
  String get community_communityHashtag => 'Skupnostni hashtag';

  @override
  String get community_communityHashtagDesc =>
      'Izključeno za uporabnike skupnosti';

  @override
  String community_forCommunity(String name) {
    return 'Za $name';
  }

  @override
  String get listFilter_tooltip => 'Filtri in vrstiči';

  @override
  String get listFilter_sortBy => 'Sortiraj po';

  @override
  String get listFilter_latestMessages => 'Najnovejše sporočilo';

  @override
  String get listFilter_heardRecently => 'Nedavno slišan';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtri';

  @override
  String get listFilter_source => 'Vir';

  @override
  String get listFilter_saved => 'Shranjeni';

  @override
  String get listFilter_discovered => 'Odkriti';

  @override
  String get listFilter_all => 'Vse';

  @override
  String get listFilter_favorites => 'Priljubljene';

  @override
  String get listFilter_addToFavorites => 'Dodaj v priljubljene';

  @override
  String get listFilter_removeFromFavorites => 'Odstrani iz priljubljenih';

  @override
  String get listFilter_users => 'Uporabniki';

  @override
  String get listFilter_repeaters => 'Ponovitve';

  @override
  String get listFilter_roomServers => 'Smeti za prostore';

  @override
  String get listFilter_unreadOnly => 'Nezbrani samo';

  @override
  String get listFilter_newGroup => 'Nova skupina';

  @override
  String get pathTrace_you => 'Ti';

  @override
  String get pathTrace_failed => 'Sledenje poti ni uspelo.';

  @override
  String get pathTrace_notAvailable => 'Potni sled ni na voljo.';

  @override
  String get pathTrace_refreshTooltip => 'Osveži Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Ena ali več hmelju manjka lokacija!';

  @override
  String get pathTrace_clearTooltip => 'Počisti pot';

  @override
  String get losSelectStartEnd => 'Izberite začetno in končno vozlišče za LOS.';

  @override
  String losRunFailed(String error) {
    return 'Preverjanje vidnega polja ni uspelo: $error';
  }

  @override
  String get losClearAllPoints => 'Počisti vse točke';

  @override
  String get losRunToViewElevationProfile =>
      'Zaženite LOS za ogled višinskega profila';

  @override
  String get losMenuTitle => 'LOS meni';

  @override
  String get losMenuSubtitle =>
      'Tapnite vozlišča ali dolgo pritisnite na zemljevid za točke po meri';

  @override
  String get losShowDisplayNodes => 'Pokaži prikazna vozlišča';

  @override
  String get losCustomPoints => 'Točke po meri';

  @override
  String losCustomPointLabel(int index) {
    return 'Po meri $index';
  }

  @override
  String get losPointA => 'Točka A';

  @override
  String get losPointB => 'Točka B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antena A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antena B: $value $unit';
  }

  @override
  String get losRun => 'Zaženi LOS';

  @override
  String get losNoElevationData => 'Ni podatkov o višini';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, čisti LOS, najmanjša razdalja $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blokiral $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: preverjam ...';

  @override
  String get losStatusNoData => 'LOS: ni podatkov';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total jasno, $blocked blokirano, $unknown neznano';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Podatki o nadmorski višini niso na voljo za enega ali več vzorcev.';

  @override
  String get losErrorInvalidInput =>
      'Neveljavni podatki o točkah/višini za izračun LOS.';

  @override
  String get losRenameCustomPoint => 'Preimenujte točko po meri';

  @override
  String get losPointName => 'Ime točke';

  @override
  String get losShowPanelTooltip => 'Pokaži ploščo LOS';

  @override
  String get losHidePanelTooltip => 'Skrij ploščo LOS';

  @override
  String get losElevationAttribution =>
      'Podatki o višini: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radijski horizont';

  @override
  String get losLegendLosBeam => 'Linija vidnosti';

  @override
  String get losLegendTerrain => 'Teren';

  @override
  String get losFrequencyLabel => 'Frekvenca';

  @override
  String get losFrequencyInfoTooltip => 'Prikaži podrobnosti izračuna';

  @override
  String get losFrequencyDialogTitle => 'Izračun radijskega horizonta';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Začenši od k=$baselineK pri $baselineFreq MHz, izračun prilagodi k-faktor za trenutni pas $frequencyMHz MHz, ki določa ukrivljeno zgornjo mejo radijskega horizonta.';
  }

  @override
  String get contacts_pathTrace => 'Sledenje poti';

  @override
  String get contacts_ping => 'Pingati';

  @override
  String get contacts_repeaterPathTrace => 'Sledi poti do ponavljalnika';

  @override
  String get contacts_repeaterPing => 'Pinguj ponavljalnik';

  @override
  String get contacts_roomPathTrace => 'Sledenje poti do strežnika sobe';

  @override
  String get contacts_roomPing => 'Ping strežnik sobe';

  @override
  String get contacts_chatTraceRoute => 'Slediti poti žarkov';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Trace route to $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Odložišče je prazno.';

  @override
  String get contacts_invalidAdvertFormat => 'Neveljavni kontaktne podatke';

  @override
  String get contacts_contactImported => 'Kontakt je bil uvožen.';

  @override
  String get contacts_contactImportFailed => 'Kontakt ni bil uspešno uvožen.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name je že med vašimi stiki.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Reklama brez posrednikov';

  @override
  String get contacts_floodAdvert => 'Poplavna oglás';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopiraj oglas v odložišče';

  @override
  String get contacts_addContactFromClipboard => 'Dodaj stik iz odložišča';

  @override
  String get contacts_ShareContact => 'Kopiraj stik v Odložišče';

  @override
  String get contacts_ShareContactZeroHop => 'Deliti kontakt prek oglasa';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Poslano po oglasu.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Pošiljanje kontakta ni uspelo.';

  @override
  String get contacts_contactAdvertCopied =>
      'Oglas je bil kopiran v odložišče.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopiranje oglasa v odložišče je spodletelo.';

  @override
  String get contacts_addContact => 'Dodaj stik';

  @override
  String get contacts_scanQrCode => 'Skeniraj QR stika';

  @override
  String get contacts_scanQrCodeDesc =>
      'Skenirajte QR kodo stika iz aplikacije MeshCore';

  @override
  String get contacts_enterIdHash => 'Ročno vnesi stik';

  @override
  String get contacts_enterIdHashDesc =>
      'Prilepite oglas stika ali povezavo meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... ali javni ključ v hex';

  @override
  String get contacts_import => 'Uvozi';

  @override
  String get contacts_scanContactInstructions =>
      'Skenirajte QR kodo stika MeshCore';

  @override
  String get notification_activityTitle => 'Aktivnost MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sporočil',
      few: 'sporočila',
      two: 'sporočili',
      one: 'sporočilo',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sporočil kanala',
      few: 'sporočila kanala',
      two: 'sporočili kanala',
      one: 'sporočilo kanala',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'novih vozlišč',
      few: 'nova vozlišča',
      two: 'novi vozlišči',
      one: 'novo vozlišče',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Odkrito novo $contactType';
  }

  @override
  String get notification_receivedNewMessage => 'Prejeto novo sporočilo';

  @override
  String get settings_gpxExportRepeaters =>
      'Izvoz ponoviteljev / strežnika sobe v GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Izvozi ponovljene oddajnike / strežnik sobe z lokacijo v datoteko GPX.';

  @override
  String get settings_gpxExportContacts => 'Izvoz spremljevalcev v GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Izvozi spremljevalce z lokacijo v datoteko GPX.';

  @override
  String get settings_gpxExportAll => 'Izvozi vse kontakte v GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Izvozi vse kontakte z lokacijo v datoteko GPX.';

  @override
  String get settings_gpxExportSuccess => 'Uspešno izvoz GPX datoteke.';

  @override
  String get settings_gpxExportNoContacts => 'Ni stikov za izvoz.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Ni podprto na vašem napravi/operacijskem sistemu';

  @override
  String get settings_gpxExportError => 'Pri izvozu je prišlo do napake.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Lokacije ponovljivca in strežnika sobe';

  @override
  String get settings_gpxExportChat => 'Lokacije spremljevalcev';

  @override
  String get settings_gpxExportAllContacts => 'Lokacije vseh stikov';

  @override
  String get settings_gpxExportShareText => 'Podatki kart izvoženi iz MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax izvoz podatkov GPX karte';

  @override
  String get snrIndicator_nearByRepeaters => 'Bližnji ponovitelji';

  @override
  String get snrIndicator_lastSeen => 'Zadnjič videno';

  @override
  String get contactsSettings_title => 'Nastavitve stikov';

  @override
  String get contactsSettings_autoAddTitle => 'Avtomatsko odkrivanje';

  @override
  String get contactsSettings_otherTitle => 'Druge nastavitve v zvezi s stiki';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Avtomatsko dodaj uporabnike';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite uporabnike.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Avtomatsko dodaj ponovitelje';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite ponovitelje.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Avtomatsko dodaj strežnike sob';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite strežnike sob.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Avtomatsko dodaj senzorje';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Dovoli spremljevalcu, da samodejno doda odkrite senzorje.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Prepiši najstarejše';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Ko je seznam stikov poln, bo najstarejši nestarševski stik zamenjan.';

  @override
  String get discoveredContacts_Title => 'Odkriti stiki';

  @override
  String get discoveredContacts_noMatching => 'Ni ujemajočih stikov';

  @override
  String get listFilter_searchHint => 'Iskanje...';

  @override
  String get discoveredContacts_searchHint => 'Najdeni stiki po iskanju';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt dodan';

  @override
  String get discoveredContacts_addContact => 'Dodaj stik';

  @override
  String get discoveredContacts_copyContact => 'Kopiraj stik v odložišče';

  @override
  String get discoveredContacts_deleteContact => 'Izbriši stik';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Izbriši vse odkrite kontakte';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Ste prepričani, da želite izbrisati vse odkrite kontakte?';

  @override
  String get chat_sendCooldown =>
      'Prosimo, počakajte trenutek, preden pošljete ponovno.';

  @override
  String get chat_notConnected =>
      'Ni povezave z radiem. Sporočilo ni bilo poslano.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Pritisnite za najstarejše nepročitano sporočilo';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Ko odpirate klepet z neprebranimi sporočili, se premaknite na prvo neprebrano sporočilo, namesto najnovejšega.';

  @override
  String get appSettings_languageHu => 'Madžarski';

  @override
  String get appSettings_languageJa => 'Japonski';

  @override
  String get appSettings_languageKo => 'Korejski';

  @override
  String get radioStats_screenTitle => 'Radijske statistike';

  @override
  String get radioStats_notConnected =>
      'Povežite se z napravo, da si ogledate statistiko o radiju.';

  @override
  String get radioStats_firmwareTooOld =>
      'Statistika za radio zahteva združljivo programsko opremo v8 ali kasnejše.';

  @override
  String get radioStats_waiting => 'Čakam na podatke…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Število šuma: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Najkasnejše vrednost RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Najkasnejše vrednost SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Čas na TX (skupno): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Čas, namenjen RX-ju (skupno): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Ravnovredna raven šuma (dBm) za nedavne vzorce.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Število šuma: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Prejemanje statistike o radiju…';

  @override
  String get radioStats_settingsTile => 'Radijske statistike';

  @override
  String get radioStats_settingsSubtitle =>
      'Število šumov, RSSI, SNR in čas, ki ga je napolnila oprema';

  @override
  String get translation_title => 'Prevod';

  @override
  String get translation_enableTitle => 'Omogočite prevod';

  @override
  String get translation_enableSubtitle =>
      'Prevedite vstopne sporočila in omogočite predhodno prevajanje.';

  @override
  String get translation_composerTitle => 'Preprištejte, preden pošljete';

  @override
  String get translation_composerSubtitle =>
      'Ureja privzeto stanje ikone za prevod, ki jo uporablja avtor.';

  @override
  String get translation_targetLanguage => 'Ciljna jezika';

  @override
  String get translation_useAppLanguage => 'Uporabite jezik aplikacije';

  @override
  String get translation_downloadedModelLabel => 'Naložen model';

  @override
  String get translation_presetModelLabel =>
      'Prednastavljeni model Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL za ročni model';

  @override
  String get translation_downloadModel => 'Prenesite model';

  @override
  String get translation_downloading => 'Izvajanje...';

  @override
  String get translation_working => 'Delo...';

  @override
  String get translation_stop => 'Prekliji';

  @override
  String get translation_mergingChunks =>
      'Sklapljanje prenesenih delov v končni datoteko...';

  @override
  String get translation_downloadedModels => 'Naloženi modeli';

  @override
  String get translation_deleteModel => 'Izbrisati model';

  @override
  String get translation_modelDownloaded =>
      'Model za prevajanje je bil naložen.';

  @override
  String get translation_downloadStopped => 'Prenos je bil prekinjen.';

  @override
  String translation_downloadFailed(String error) {
    return 'Izgovoritev ni bila uspešna: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Najprej vnesite URL model.';

  @override
  String get scanner_linuxPairingShowPin => 'Prikaži PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Skrij PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth PIN za seznanjanje';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Vnesite PIN za $deviceName (pustite prazno, če ga ni).';
  }

  @override
  String get translation_messageTranslation => 'Prevod sporočila';

  @override
  String get translation_translateBeforeSending =>
      'Preprištejte, preden pošljete';

  @override
  String get translation_composerEnabledHint =>
      'Vsebina sporočil bo prevedena, preden jih pošljemo.';

  @override
  String get translation_composerDisabledHint =>
      'Pošljite sporočila v originalnem tipkanem jeziku.';

  @override
  String translation_translateTo(String language) {
    return 'Prevesti v $language';
  }

  @override
  String get translation_translationOptions => 'Možnosti prevoda';

  @override
  String get translation_systemLanguage => 'Jezik sistema';

  @override
  String get routing_title => 'Usmerjanje';

  @override
  String routing_route(String route) {
    return 'Shranjena pot: $route';
  }

  @override
  String get routing_noRoute =>
      'še nobene — naslednje sporočilo gre poplavno in se jo nauči';

  @override
  String get routing_auto => 'Samodejno';

  @override
  String get routing_autoSubtitle =>
      'Uporabi pot, shranjeno v radiu. Priporočeno.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder vklopljen: najprej poskusi naučene poti';

  @override
  String get routing_flood => 'Vedno poplavno';

  @override
  String get routing_floodSubtitle => 'Vsako sporočilo gre v celotno omrežje';

  @override
  String get routing_custom => 'Pot po meri';

  @override
  String get routing_customSubtitle => 'Ponovitelje izberite sami';

  @override
  String get routing_forget => 'Ponastavi pot';

  @override
  String get routing_forgetDone =>
      'Pot ponastavljena. Naslednje sporočilo gre poplavno in se nauči novo.';

  @override
  String get routing_pathfinder => 'Kaj ve Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Ponovitelji, ki slišijo vas in ta stik, ter naučene poti tja in nazaj';

  @override
  String get path_direct => 'Neposredno — brez ponoviteljev';

  @override
  String get path_directSubtitle => 'Samo ko stik neposredno sliši ta radio';

  @override
  String get chat_kindFlood => 'poplavno';

  @override
  String get chat_kindDirect => 'neposredno';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'skokov',
      few: 'skoki',
      two: 'skoka',
      one: 'skok',
    );
    return 'po poti ($count $_temp0)';
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
  String get chat_statusQueued => 'V čakalni vrsti';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Noben ponovitelj vas ni slišal. Ponovni poskus, ko bo kateri v dosegu.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'Radio $name pošilja kratke kode ponoviteljev (1 bajt). Pathfinder se ne more naučiti poti do tega stika, dokler njegov radio ne uporablja 2-bajtnih kod.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Pošiljanje · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Ponovni poskus · $kind · poskus $attempt od $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Dostavljeno · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Dostavljeno v $attempt. poskusu · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Dostavljeno pozno · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Dostavljeno · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'poskusih',
      few: 'poskusih',
      two: 'poskusih',
      one: 'poskusu',
    );
    return 'Ni uspelo po $attempts $_temp0 · tapnite za ponovno pošiljanje';
  }

  @override
  String get chat_statusFailedShort =>
      'Ni uspelo · tapnite za ponovno pošiljanje';

  @override
  String get chat_resendingByFlood => 'Ponovno pošiljanje poplavno';

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
  String get settings_pathGraph => 'Pathfinder (preizkusno)';

  @override
  String get settings_pathGraphSubtitle =>
      'Uči se poti iz vsega, kar radio sliši, in ko pošljete zasebno sporočilo, najprej poskusi najboljše. Jantarna ikona poti označuje sporočilo, poslano po poti Pathfinderja.';

  @override
  String get map_routeAndTrace => 'Pot in sledenje';

  @override
  String get map_pathfinderTrace => 'Sledenje tja in nazaj';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Tja po najboljši poti Pathfinderja, nazaj po njegovi najboljši povratni poti';

  @override
  String get map_routeBackMirrored =>
      'Povratna pot še ni znana — vrnitev po isti poti';

  @override
  String get map_traceHelpTitle => 'Gumbi za sledenje poti';

  @override
  String get map_traceHelpCustom => 'Ponovitelje vnesite ali izberite sami.';

  @override
  String get map_traceHelpRun =>
      'Pošlje sledenje prek ponoviteljev, ki ste jih tapnili, v eno smer.';

  @override
  String get map_traceHelpThereAndBack => 'Tja in nazaj';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Pošlje sledenje tja, nato nazaj prek istih ponoviteljev v obratnem vrstnem redu.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder izbere najboljšo pot prek zadnjih dveh tapnjenih ponoviteljev in najboljšo pot nazaj do vas. Rezultat Pathfinderja nauči, katere povezave res delujejo. Treba je tapniti dva ponovitelja.';

  @override
  String get map_traceHelpRemoveLast => 'Odstrani zadnji ponovitelj s poti.';

  @override
  String get map_traceHelpCancel =>
      'Ustavi sestavljanje sledenja. Prikazan je, preden tapnete katerikoli ponovitelj.';

  @override
  String get chat_resendingByRoute => 'Ponovno pošiljanje po nastavljeni poti';

  @override
  String get room_mute => 'Utišaj sobo';

  @override
  String get room_unmute => 'Prekliči utišanje sobe';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'član';

  @override
  String get room_roleReadOnly => 'samo za branje';

  @override
  String room_clockOff(int minutes) {
    return 'Ura sobe odstopa za približno $minutes min — časi sporočil so lahko napačni';
  }

  @override
  String get room_fixClock => 'Popravi uro';

  @override
  String get room_clockSyncSent => 'Sinhronizacija ure poslana sobi';

  @override
  String get room_readOnlyNotice =>
      'Samo za branje: soba ni sprejela vašega gesla, vaša sporočila ne bodo dosegla drugih članov.';

  @override
  String get room_postAnnouncement => 'Objavi obvestilo';

  @override
  String get room_postAnnouncementSubtitle =>
      'Pošlji sporočilo v imenu sobe vsem članom';

  @override
  String get room_announcementSent => 'Obvestilo objavljeno';

  @override
  String get room_announcementFailed => 'Objava obvestila ni uspela';

  @override
  String get room_users => 'Uporabniki sobe';

  @override
  String get room_usersSubtitle => 'Oglej si admine in nastavi vloge';

  @override
  String get room_usersAdminsNote =>
      'Soba navaja le svoje admine. Člani z geslom sobe niso prikazani.';

  @override
  String get room_usersLoadFailed => 'Seznama adminov ni bilo mogoče naložiti';

  @override
  String get room_setUserRole => 'Nastavi vlogo';

  @override
  String get room_removeAccess => 'Odstrani dostop';

  @override
  String get room_removeOnlyUnknown =>
      'Tega uporabnika ni med vašimi stiki — lahko ga le odstranite, ne spremenite.';

  @override
  String get room_roleUpdated => 'Vloga posodobljena';

  @override
  String get room_roleUpdateFailed => 'Sprememba vloge ni uspela';

  @override
  String get room_postsStored => 'Shranjene objave';

  @override
  String get room_postsDelivered => 'Dostavljene objave';

  @override
  String get room_reloadPosts => 'Znova naloži nedavne objave';

  @override
  String get room_reloadPostsExplain =>
      'Prosi sobo, naj znova pošlje nedavne objave (hrani do 32). Vprašani boste za geslo sobe. Obstoječa sporočila ostanejo.';

  @override
  String get room_reloadFailed => 'Sobe ni bilo mogoče ponastaviti na radiu';

  @override
  String get companionCli_title => 'Ukazna vrstica';

  @override
  String get companionCli_settingsSubtitle =>
      'Vnašajte besedilne ukaze za ta radio';

  @override
  String get companionCli_rebooting => 'Ponovni zagon radia…';

  @override
  String get companionCli_cancelled => 'Preklicano';

  @override
  String get companionCli_poweringOff => 'Izklapljanje radia…';

  @override
  String get companionCli_noReply => 'Radio se ne odziva. Poskusite znova.';

  @override
  String get companionCli_powerOffTitle => 'Želite izklopiti radio?';

  @override
  String get companionCli_powerOffBody =>
      'Ostane izklopljen, dokler ne pritisnete njegovega gumba ali ga ne priključite.';

  @override
  String get companionCli_powerOff => 'Izklopi';

  @override
  String get companionCli_quickBoard => 'Plošča';

  @override
  String get companionCli_quickWifiStatus => 'Stanje WiFi';

  @override
  String get companionCli_quickWifiAddress => 'Naslov WiFi';

  @override
  String get companionCli_helpBoard => 'Prikaže proizvajalca in model plošče.';

  @override
  String get companionCli_helpReboot => 'Znova zažene radio.';

  @override
  String get companionCli_helpPowerOff => 'Izklopi radio.';

  @override
  String get companionCli_helpSetPin =>
      'Nastavi PIN za seznanjanje Bluetooth. Velja po ponovnem zagonu.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Nastavi število ur, prištetih k UTC, za uro na lastnem zaslonu radia (-12 do +14).';

  @override
  String get companionCli_helpSetTx =>
      'Nastavi oddajno moč v dBm. Velja takoj.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Nastavi prag motenj v dB. 0 izklopi zaznavanje motenj.';

  @override
  String get companionCli_helpSetCad =>
      'Pred oddajanjem prisluhne drugim radiem (zaznavanje aktivnosti kanala).';

  @override
  String get companionCli_helpSetRxGain => 'Ojačan sprejem na radiih SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bajti na ponovitelja v poti: 0 = 1 bajt, 1 = 2 bajta, 2 = 3 bajti.';

  @override
  String get companionCli_helpWifiStatus =>
      'Prikaže, ali je radio v omrežju WiFi.';

  @override
  String get companionCli_helpWifiIp => 'Prikaže naslov radia v omrežju WiFi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Nastavi ime omrežja WiFi. Velja po ponovnem zagonu.';

  @override
  String get companionCli_helpWifiPwd =>
      'Nastavi geslo WiFi. Velja po ponovnem zagonu.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Vklopi (1) ali izklopi (0) WiFi. Velja po ponovnem zagonu.';

  @override
  String get companionCli_helpWifiClear =>
      'Pozabi omrežje WiFi. Velja po ponovnem zagonu.';

  @override
  String get companionCli_remoteNoReply =>
      'Ni odgovora. Drugi radio potrebuje firmware 1.18 ali novejši in vam mora dovoliti uporabo svoje ukazne vrstice.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Poslano. Radio na ponovni zagon ali izklop ne odgovori.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name: poskus uporabe ukazne vrstice vašega radia: \"$command\". Ni bilo dovoljeno.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Poskus uporabe ukazne vrstice vašega radia: \"$command\". Ni bilo dovoljeno.';
  }

  @override
  String get contact_remoteCli => 'Dovoli oddaljeno ukazno vrstico';

  @override
  String get contact_remoteCliSubtitle =>
      'Temu stiku dovoli izvajanje ukazov na vašem radiu';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Dovolite, da $name upravlja vaš radio?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return 'Stik $name bo lahko spreminjal nastavitve vašega radia, bral vaše geslo WiFi, preimenoval radio ter ga znova zagnal ali izklopil. Dovolite to samo nekomu, ki mu popolnoma zaupate.';
  }

  @override
  String get contact_remoteCliAllow => 'Dovoli';

  @override
  String get connection_secondApp =>
      'S tem radiem je povezana druga aplikacija. Sporočila in nastavitve se lahko pomešajo. Zaprite drugo aplikacijo.';

  @override
  String get wifi_title => 'WiFi';

  @override
  String get wifi_settingsSubtitle => 'Omrežje, geslo in povezava';

  @override
  String get wifi_use => 'Uporabi WiFi';

  @override
  String get wifi_networkName => 'Ime omrežja';

  @override
  String get wifi_password => 'Geslo';

  @override
  String get wifi_passwordUnchanged => 'Nespremenjeno';

  @override
  String get wifi_showPassword => 'Prikaži geslo';

  @override
  String get wifi_nameMissing => 'Vnesite ime omrežja';

  @override
  String get wifi_nameTooLong => 'Ime omrežja je predolgo (največ 32 bajtov)';

  @override
  String get wifi_passwordTooLong => 'Geslo je predolgo (največ 63 bajtov)';

  @override
  String get wifi_savedRestart =>
      'Shranjeno. Spremembe WiFi začnejo veljati po ponovnem zagonu radia.';

  @override
  String get wifi_forget => 'Pozabi omrežje';

  @override
  String get wifi_forgetConfirm =>
      'Želite pozabiti to omrežje WiFi? Radio po ponovnem zagonu preneha uporabljati WiFi.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Radio tega ni sprejel: $reply';
  }

  @override
  String get wifi_noReply => 'Radio se ne odziva. Poskusite znova.';

  @override
  String get wifi_restartTitle => 'Želite znova zagnati radio?';

  @override
  String get wifi_later => 'Pozneje';

  @override
  String get wifi_loadFailed =>
      'Nastavitev WiFi ni bilo mogoče prebrati iz radia.';

  @override
  String wifi_connectedTo(String address) {
    return 'Povezano · $address';
  }

  @override
  String get wifi_notConnected => 'Ni povezave z WiFi';

  @override
  String wifi_portNote(int port) {
    return 'Aplikacije v istem omrežju se lahko povežejo na vratih $port';
  }

  @override
  String get wifi_connectOverWifi => 'Poveži se prek WiFi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax bo prekinil povezavo s tem radiem in odprl zaslon TCP z izpolnjenim naslovom $address in vrati $port. Tam tapnite \"Poveži se\".';
  }

  @override
  String get wifi_noteRestart =>
      'Spremembe začnejo veljati po ponovnem zagonu radia.';

  @override
  String get wifi_noteSecurity =>
      'Kdorkoli v vašem omrežju WiFi se lahko poveže z radiem na vratih 5000. Za to ni gesla.';

  @override
  String get wifi_noteBattery =>
      'WiFi ne pusti radiu spati, zato se baterija hitreje prazni.';

  @override
  String get wifi_noteWrongPassword =>
      'Če je geslo napačno, radio poskuša znova vsakih nekaj sekund. Bluetooth še naprej deluje.';

  @override
  String get room_selfDemoteWarning =>
      'Spreminjate svoj lastni dostop. Če se odpoveste vlogi admina, vam jo lahko vrne le konzola sobe.';

  @override
  String get scanner_offlineMaps => 'Zemljevidi brez povezave';

  @override
  String get appSettings_offlineMaps => 'Zemljevidi brez povezave';

  @override
  String get appSettings_offlineMapsNone => 'Nič preneseno';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regij',
      few: '$count regije',
      two: '$count regiji',
      one: '$count regija',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count območij pomorskih kart',
      few: '$count območja pomorskih kart',
      two: '$count območji pomorskih kart',
      one: '$count območje pomorskih kart',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Na voljo je $count posodobitev',
      few: 'Na voljo so $count posodobitve',
      two: 'Na voljo sta $count posodobitvi',
      one: 'Na voljo je $count posodobitev',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Prenašaj zemljevide samo prek Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Prenosi zemljevidov čakajo na povezavo Wi‑Fi';

  @override
  String get offlineMaps_title => 'Zemljevidi brez povezave';

  @override
  String get offlineMaps_tabMaps => 'Zemljevidi';

  @override
  String get offlineMaps_tabCharts => 'Pomorske karte';

  @override
  String get offlineMaps_chartsNotice => 'Ni za navigacijo · Zakaj?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Predlagano · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Območja kart po obalah';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count območij',
      few: '$count območja',
      two: '$count območji',
      one: '$count območje',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Preneseno: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Izbrano: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Izberi vse';

  @override
  String get offlineMaps_clearSelection => 'Počisti';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Tudi v: $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Še ni na voljo';

  @override
  String get offlineMaps_chartsHint =>
      'Pomorske karte NOAA izberete po obalah na zavihku \"Pomorske karte\".';

  @override
  String offlineMaps_chartsName(String area) {
    return 'Pomorske karte NOAA – $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count območij',
      few: '$count območja',
      two: '$count območji',
      one: '$count območje',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Preneseno';

  @override
  String get offlineMaps_refresh => 'Preveri nove zemljevide';

  @override
  String get offlineMaps_loading => 'Nalaganje razpoložljivih zemljevidov…';

  @override
  String get offlineMaps_serverError => 'Strežnik zemljevidov ni dosegljiv';

  @override
  String get offlineMaps_unavailable => 'Zemljevidi še niso na voljo';

  @override
  String get offlineMaps_unavailableHint => 'Poskusite znova pozneje.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Pomorske karte NOAA še niso na voljo';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Prikazan je seznam z dne $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Posodobite MeshTrax za najnovejše zemljevide.';

  @override
  String get offlineMaps_world => 'Svet';

  @override
  String get offlineMaps_suggested => 'Predlagano';

  @override
  String get offlineMaps_regions => 'Regije';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regije: $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return 'Znotraj: $count';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size zemljevidov brez povezave v tej napravi';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Posodobitve ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Posodobi vse ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Prenašanje';

  @override
  String get offlineMaps_update => 'Posodobi';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Preneseno $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Na voljo je posodobitev';

  @override
  String get offlineMaps_otherFiles => 'Druge datoteke zemljevidov';

  @override
  String get offlineMaps_emptyTitle => 'Še ni zemljevidov brez povezave';

  @override
  String get offlineMaps_emptyBody =>
      'Prenesite regijo, da boste zemljevid lahko uporabljali brez povezave.';

  @override
  String get offlineMaps_findMaps => 'Poišči zemljevide';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Želite izbrisati $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'S tem sprostite $size. Pozneje jo lahko znova prenesete.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name izbrisano';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done od $total';
  }

  @override
  String get offlineMaps_kindMap => 'Zemljevid';

  @override
  String get offlineMaps_kindMapDetail =>
      'Ulice, poti in kraji iz OpenStreetMap';

  @override
  String get offlineMaps_kindContours => 'Plastnice';

  @override
  String get offlineMaps_kindContoursDetail => 'Višinske črte';

  @override
  String get offlineMaps_kindUsgs => 'Topografski zemljevid USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Poti, potoki, rezervati';

  @override
  String get offlineMaps_kindTerrain => 'Senčenje reliefa';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Hribi in gore, osenčeni pod zemljevidom';

  @override
  String get offlineMaps_kindCharts => 'Pomorske karte NOAA';

  @override
  String get offlineMaps_usOnly => 'Samo Združene države';

  @override
  String offlineMaps_download(String size) {
    return 'Prenesi $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Prenesi';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Velik prenos ($size). Uporabite Wi‑Fi in pustite napravo na polnjenju.';
  }

  @override
  String get offlineMaps_waiting => 'Čakanje…';

  @override
  String get offlineMaps_checking => 'Preverjanje prenosa…';

  @override
  String get offlineMaps_retrying => 'Ponovni poskus…';

  @override
  String offlineMaps_failed(String error) {
    return 'Prenos ni uspel: $error';
  }

  @override
  String get offlineMaps_pause => 'Začasno ustavi';

  @override
  String get offlineMaps_resume => 'Nadaljuj';

  @override
  String get offlineMaps_deleteRegion => 'Izbriši regijo';

  @override
  String get offlineMaps_notInCatalogue => 'Ni na voljo za to regijo';

  @override
  String get offlineMaps_notificationRunning => 'Prenašanje zemljevida';

  @override
  String get offlineMaps_notificationPaused =>
      'Prenos zemljevida začasno ustavljen';

  @override
  String get offlineMaps_notificationFailed => 'Prenos zemljevida ni uspel';

  @override
  String get offlineMaps_clearTileCache =>
      'Počisti predpomnjene ploščice spletnih zemljevidov';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Želite odstraniti ploščice spletnih zemljevidov, shranjene med brskanjem? Preneseni zemljevidi ostanejo.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Predpomnjene ploščice spletnih zemljevidov odstranjene';

  @override
  String get map_notForNavigation => 'Ni za navigacijo';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax te karte izriše iz podatkov NOAA, da lažje vidite vodo okoli svojih radiev in načrtujete. To niso uradne karte. Ne plujte po njih.';

  @override
  String get map_chartsNoticeWhy => 'Zakaj:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Zastarijo. NOAA svoje karte nenehno popravlja; prenesena karta ostane taka, dokler je ne posodobite v \"Zemljevidi brez povezave\".';

  @override
  String get map_chartsNoticeLeftOut =>
      'Nekaj izpustijo. Veliko simbolov, sektorjev luči in opomb ni izrisanih, nekatere oznake pa se pokažejo šele ob povečavi.';

  @override
  String get map_chartsNoticePositions =>
      'Položaji so lahko napačni ali stari. GPS se lahko zmoti za 10 m (30 ft) ali več, vozlišče pa je samo tam, kjer se je nazadnje javilo.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax ni certificiran kartni ploter.';

  @override
  String get map_chartsNoticeUse =>
      'Za navigacijo uporabljajte uradne, posodobljene karte NOAA (papirnate ali NOAA ENC v certificiranem kartnem ploterju) z najnovejšimi Obvestili pomorščakom.';

  @override
  String get map_sourceOnline => 'Na spletu';

  @override
  String get map_sourceOffline => 'Brez povezave';

  @override
  String get map_downloadForDetail => 'Prenesite regijo za podrobnosti';

  @override
  String get map_zoomInForOfflineMap =>
      'Povečajte za prikaz zemljevida brez povezave';

  @override
  String get map_noCharts => 'Tu ni pomorskih kart';

  @override
  String get map_myLocation => 'Moja lokacija';

  @override
  String get map_zoomIn => 'Povečaj';

  @override
  String get map_zoomOut => 'Pomanjšaj';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS vklopljen';

  @override
  String get gps_off => 'GPS izklopljen';

  @override
  String get gps_onHint => 'Radio posodablja svoj položaj iz GPS.';

  @override
  String get gps_offHint =>
      'Izklopljen varčuje z baterijo radia. Po vklopu lahko iskanje položaja traja nekaj minut.';

  @override
  String get gps_asking => 'Spraševanje radia...';

  @override
  String get gps_noPosition =>
      'Položaja še ni. Na prostem lahko prvi traja nekaj minut.';

  @override
  String get gps_position => 'Položaj';

  @override
  String get gps_altitude => 'Nadmorska višina';

  @override
  String gps_readAgo(String ago) {
    return 'Prebrano iz radia pred $ago';
  }

  @override
  String get gps_turnOnTitle => 'Želite vklopiti GPS?';

  @override
  String get gps_turnOnBody =>
      'GPS radia je izklopljen. Po vklopu lahko iskanje položaja traja nekaj minut.';

  @override
  String get gps_turnOn => 'Vklopi';

  @override
  String get gps_notNow => 'Ne zdaj';

  @override
  String get map_zoomInForCharts => 'Povečajte za prikaz pomorskih kart';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Prenesi $region · $size';
  }

  @override
  String get mapLayers_title => 'Plasti zemljevida';

  @override
  String get mapLayers_mapType => 'Vrsta zemljevida';

  @override
  String get mapLayers_standard => 'Standardni';

  @override
  String get mapLayers_usgs => 'Topografski USGS';

  @override
  String get mapLayers_charts => 'Pomorske karte';

  @override
  String get mapLayers_notDownloaded => 'Ni preneseno';

  @override
  String get mapLayers_offlineOnly => 'Samo brez povezave';

  @override
  String get mapLayers_details => 'Podrobnosti zemljevida';

  @override
  String get mapLayers_contours => 'Plastnice';

  @override
  String get mapLayers_hillShading => 'Senčenje reliefa';

  @override
  String get mapLayers_dark => 'Temni zemljevid';

  @override
  String get mapLayers_downloadedAreas => 'Prenesena območja';

  @override
  String get mapLayers_nodes => 'Vozlišča';

  @override
  String get mapLayers_pins => 'Žebljički';

  @override
  String get mapLayers_guessed => 'Predpostavljeni';

  @override
  String get mapLayers_moreFilters => 'Več filtrov';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Nazadnje viden, predpona ključa, prekrivanja';

  @override
  String get map_legend => 'Legenda';

  @override
  String get scanner_map => 'Zemljevid';

  @override
  String get structured_openMap => 'Odpri zemljevid';

  @override
  String get structured_addToCalendar => 'Dodaj v koledar';

  @override
  String get structured_details => 'Podrobnosti';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Dogodek';

  @override
  String get structured_notice => 'Obvestilo';

  @override
  String get structured_allDay => 'Ves dan';

  @override
  String get structured_calendarFailed => 'Koledarja ni bilo mogoče odpreti';

  @override
  String get structured_today => 'Danes';

  @override
  String get structured_tomorrow => 'Jutri';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Čez $count dni',
      few: 'Čez $count dni',
      two: 'Čez $count dneva',
      one: 'Čez $count dan',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Preteklo';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Dan $day od $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni',
      few: '$count dni',
      two: '$count dneva',
      one: '$count dan',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Datum konca';

  @override
  String get dialog_eventSameDay => 'Isti dan';

  @override
  String get structured_map => 'Zemljevid';

  @override
  String get structured_navigate => 'Navigiraj';

  @override
  String get structured_channel => 'Kanal';

  @override
  String get structured_contact => 'Stik';

  @override
  String get structured_room => 'Soba';

  @override
  String get structured_repeater => 'Ponovitelj';

  @override
  String get structured_sensor => 'Senzor';

  @override
  String get structured_joinChannel => 'Pridruži se kanalu';

  @override
  String get structured_addContact => 'Dodaj stik';

  @override
  String get structured_addRoom => 'Dodaj sobo';

  @override
  String get structured_addRepeater => 'Dodaj ponovitelja';

  @override
  String get structured_addSensor => 'Dodaj senzor';

  @override
  String get structured_open => 'Odpri';

  @override
  String get structured_added => 'Dodano';

  @override
  String get tray_add => 'Dodaj';

  @override
  String get tray_myLocation => 'Moja lokacija';

  @override
  String get tray_pointOnMap => 'Točka na zemljevidu';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Dogodek';

  @override
  String get tray_notice => 'Obvestilo';

  @override
  String get tray_noRadioPosition =>
      'Vaš radio še nima položaja. Izberite ga na zemljevidu.';

  @override
  String get dialog_insert => 'Vstavi';

  @override
  String get dialog_eventTitle => 'Naslov';

  @override
  String get dialog_eventDate => 'Datum';

  @override
  String get dialog_eventStart => 'Začetek';

  @override
  String get dialog_eventEnd => 'Konec';

  @override
  String get dialog_eventNoEnd => 'Brez časa konca';

  @override
  String get dialog_eventPlace => 'Kraj (neobvezno)';

  @override
  String get dialog_pickOnMap => 'Izberi na zemljevidu';

  @override
  String get dialog_sosTitle => 'Pošlji SOS';

  @override
  String get dialog_sosText => 'Kaj se je zgodilo?';

  @override
  String get dialog_noticeTitle => 'Obvestilo';

  @override
  String get dialog_noticeText => 'Kaj morajo vsi vedeti?';

  @override
  String get dialog_labelTitle => 'Točka na zemljevidu';

  @override
  String get dialog_note => 'Opomba (neobvezno)';

  @override
  String get paste_convertLocation =>
      'Videti je kot povezava do zemljevida. Jo želite pretvoriti v lokacijo?';

  @override
  String get paste_convertEvent =>
      'Videti je kot dogodek, deljen iz koledarja. Ga želite pretvoriti v dogodek?';

  @override
  String get paste_convert => 'Pretvori';

  @override
  String get paste_resolving => 'Razreševanje povezave…';

  @override
  String get paste_resolveFailed => 'Povezave ni bilo mogoče razrešiti';

  @override
  String get pinned_dismiss => 'Zapri';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Se želite pridružiti kanalu $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Že ste v $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Pridružili ste se $name';
  }

  @override
  String get map_pickPositionHint => 'Tapnite zemljevid, da izberete položaj';

  @override
  String get map_legendMesh => 'Omrežje mesh';

  @override
  String get chartLegend_title => 'Simboli pomorskih kart';

  @override
  String get chartLegend_sectionBuoys => 'Boje in stalne oznake';

  @override
  String get chartLegend_sectionLights => 'Luči';

  @override
  String get chartLegend_sectionHazards => 'Nevarnosti';

  @override
  String get chartLegend_sectionTides => 'Plimovanje in tokovi';

  @override
  String get chartLegend_sectionDepths => 'Globine in dno';

  @override
  String get chartLegend_sectionAreas => 'Območja, pasovi in črte';

  @override
  String get chartLegend_sectionLandmarks => 'Orientacijske točke';

  @override
  String get chartLegend_sectionAbbreviations => 'Okrajšave';

  @override
  String get chartLegend_chartNo1 => 'Vsi simboli: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Zelena valjasta boja';

  @override
  String get chartLegend_portBuoyHint =>
      'Ob vplutju z morja jo pustite na levi';

  @override
  String get chartLegend_starboardBuoy => 'Rdeča stožčasta boja';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Ob vplutju jo pustite na desni: ob vračanju z morja je rdeča desno';

  @override
  String get chartLegend_junctionBuoy => 'Boja s pasovi';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Razcep kanala: upoštevajte barvo njenega zgornjega pasu';

  @override
  String get chartLegend_safeWaterBuoy => 'Rdeče-beli pasovi';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Varna voda vse naokoli, pogosto ob vhodu v kanal';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Črno-rdeči pasovi';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Majhna nevarnost z varno vodo okoli: ostanite stran';

  @override
  String get chartLegend_specialBuoy => 'Rumena boja';

  @override
  String get chartLegend_specialBuoyHint =>
      'Posebni namen, ne za plovbo: sidrišče, kabel, raziskave';

  @override
  String get chartLegend_cardinalBuoy => 'Črno-rumena';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Kardinalna oznaka: obplujte jo na strani, po kateri je poimenovana (v ZDA redka)';

  @override
  String get chartLegend_mooringBuoy => 'Privezna boja';

  @override
  String get chartLegend_portBeacon => 'Zelena kvadratna dnevna oznaka';

  @override
  String get chartLegend_portBeaconHint =>
      'Kot zelena boja: ob vplutju jo pustite na levi';

  @override
  String get chartLegend_starboardBeacon => 'Rdeča trikotna dnevna oznaka';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Kot rdeča boja: ob vplutju jo pustite na desni';

  @override
  String get chartLegend_otherBeacon => 'Rombasta dnevna oznaka';

  @override
  String get chartLegend_otherBeaconHint =>
      'Informacija ali opozorilo, ne stran kanala';

  @override
  String get chartLegend_beaconTower =>
      'Svetilniški stolp ali konstrukcija oznake';

  @override
  String get chartLegend_topmark => 'Vršna oznaka';

  @override
  String get chartLegend_topmarkHint =>
      'Oblika na vrhu oznake dopolni njen pomen';

  @override
  String get chartLegend_light => 'Luč';

  @override
  String get chartLegend_lightHint =>
      'Škrlatni blisk označuje luč; njena oznaka pove, kako utripa';

  @override
  String get chartLegend_lightExample => 'Bliskajoča zelena, vsake 4 sekunde';

  @override
  String get chartLegend_lightExampleHint =>
      'Oznaka luči: ritem, barva, nato perioda';

  @override
  String get chartLegend_lightFixed => 'Stalna';

  @override
  String get chartLegend_lightFixedHint => 'Neprekinjena luč';

  @override
  String get chartLegend_lightFlashing => 'Bliskajoča';

  @override
  String get chartLegend_lightFlashingHint => 'Kratki bliski, vmes daljša tema';

  @override
  String get chartLegend_lightGroup => 'Skupinsko bliskajoča';

  @override
  String get chartLegend_lightGroupHint =>
      'Bliski v skupinah, tukaj po 2, nato tema';

  @override
  String get chartLegend_lightComposite => 'Sestavljena skupinska';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 bliska, nato 1: označuje razcep kanala';

  @override
  String get chartLegend_lightQuick => 'Hitra';

  @override
  String get chartLegend_lightQuickHint => 'Približno en blisk na sekundo';

  @override
  String get chartLegend_lightIsophase => 'Izofazna';

  @override
  String get chartLegend_lightIsophaseHint => 'Enako dolgo svetloba in tema';

  @override
  String get chartLegend_lightOcculting => 'Prekinjajoča';

  @override
  String get chartLegend_lightOccultingHint => 'Dlje sveti, kot je temno';

  @override
  String get chartLegend_lightMorse => 'Morsejeva koda A';

  @override
  String get chartLegend_lightMorseHint => 'Kratko, dolgo: varna voda';

  @override
  String get chartLegend_lightAlternating => 'Izmenična';

  @override
  String get chartLegend_lightAlternatingHint => 'Menja barvo';

  @override
  String get chartLegend_lightColours => 'Bela, rdeča, zelena, rumena';

  @override
  String get chartLegend_lightPeriod => 'Perioda';

  @override
  String get chartLegend_lightPeriodHint => 'Sekunde za en cel cikel';

  @override
  String get chartLegend_rock => 'Podvodna skala';

  @override
  String get chartLegend_rockHint => 'Vedno pod vodo, a je lahko plitvo';

  @override
  String get chartLegend_rockAwash => 'Skala v višini gladine';

  @override
  String get chartLegend_rockAwashHint => 'Ob oseki tik pod površjem';

  @override
  String get chartLegend_rockCovers => 'Skala, ki jo voda zaliva in odkriva';

  @override
  String get chartLegend_rockCoversHint => 'Ob oseki vidna, ob plimi pod vodo';

  @override
  String get chartLegend_wreckDangerous => 'Nevarna razbitina';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Dovolj plitvo, da vanjo zadenete';

  @override
  String get chartLegend_wreck => 'Razbitina';

  @override
  String get chartLegend_wreckHint =>
      'Dovolj globoko za plovila na površju; ne sidrajte';

  @override
  String get chartLegend_wreckShowing => 'Štrleča razbitina';

  @override
  String get chartLegend_wreckShowingHint => 'Del je nad vodo';

  @override
  String get chartLegend_obstruction => 'Ovira';

  @override
  String get chartLegend_obstructionHint =>
      'Nekaj na dnu; njena globina, če je znana';

  @override
  String get chartLegend_foulGround => 'Nečisto dno';

  @override
  String get chartLegend_foulGroundHint =>
      'Varno za prehod, a ne sidrajte in ne lovite z vlečno mrežo';

  @override
  String get chartLegend_hazardArea => 'Rob nevarnega območja';

  @override
  String get chartLegend_hazardAreaHint =>
      'V njem so skale, razbitine ali ovire';

  @override
  String get chartLegend_pile => 'Kol ali steber';

  @override
  String get chartLegend_floodStream => 'Plimni tok';

  @override
  String get chartLegend_floodStreamHint => 'Plimovalni tok, ko voda narašča';

  @override
  String get chartLegend_ebbStream => 'Osečni tok';

  @override
  String get chartLegend_ebbStreamHint => 'Plimovalni tok, ko voda upada';

  @override
  String get chartLegend_current => 'Tok';

  @override
  String get chartLegend_currentHint =>
      'Teče v isto smer ne glede na plimovanje';

  @override
  String get chartLegend_rips => 'Tokovno valovanje ali vrtinci';

  @override
  String get chartLegend_ripsHint => 'Razburkana, vrtinčasta voda';

  @override
  String get chartLegend_breakers => 'Lomeči se valovi';

  @override
  String get chartLegend_breakersHint => 'Valovi, ki se lomijo nad plitvino';

  @override
  String get chartLegend_sounding => 'Globina';

  @override
  String get chartLegend_soundingHint => 'Globina ob povprečni oseki';

  @override
  String get chartLegend_depthContour => 'Izobata';

  @override
  String get chartLegend_depthContourHint => 'Njena oznaka pove globino';

  @override
  String get chartLegend_drying => 'Ob oseki suho';

  @override
  String get chartLegend_dredged => 'Poglobljen kanal';

  @override
  String get chartLegend_dredgedHint => 'Vzdrževan na prikazani globini';

  @override
  String get chartLegend_swept => 'Preiskano območje';

  @override
  String get chartLegend_sweptHint => 'Preverjeno prosto do prikazane globine';

  @override
  String get chartLegend_unsurveyed => 'Neizmerjeno';

  @override
  String get chartLegend_unsurveyedHint => 'Globine niso izmerjene';

  @override
  String get chartLegend_weed => 'Alge ali morska trava';

  @override
  String get chartLegend_restricted => 'Omejeno območje';

  @override
  String get chartLegend_restrictedHint =>
      'Vstop omejen; zobci kažejo navznoter';

  @override
  String get chartLegend_regulatedLimit => 'Meja reguliranega območja';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Sidrišče, kabelsko območje, strelišče in drugo: glejte oznako';

  @override
  String get chartLegend_greyLimit =>
      'Odlagališče, ribolovno območje ali gojišče';

  @override
  String get chartLegend_anchorage => 'Sidrišče';

  @override
  String get chartLegend_anchorBerth => 'Sidrno mesto';

  @override
  String get chartLegend_noAnchoring => 'Prepovedano sidranje';

  @override
  String get chartLegend_caution => 'Opozorilno območje';

  @override
  String get chartLegend_cautionHint => 'Tu bodite še posebej previdni';

  @override
  String get chartLegend_trafficLane => 'Plovni pas';

  @override
  String get chartLegend_trafficLaneHint =>
      'Velike ladje, v eno smer: prečkajte pod pravim kotom';

  @override
  String get chartLegend_separationZone => 'Ločilni pas';

  @override
  String get chartLegend_separationZoneHint =>
      'Med plovnimi pasovi: ne vplujte';

  @override
  String get chartLegend_precautionary => 'Območje posebne previdnosti';

  @override
  String get chartLegend_precautionaryHint =>
      'Ladje se tu zbližujejo: bodite previdni';

  @override
  String get chartLegend_fairway => 'Plovna pot';

  @override
  String get chartLegend_fairwayHint => 'Glavni kanal';

  @override
  String get chartLegend_track => 'Priporočena smer plovbe';

  @override
  String get chartLegend_ferry => 'Trajektna linija';

  @override
  String get chartLegend_leadingLine => 'Smernica';

  @override
  String get chartLegend_leadingLineHint =>
      'Poravnajte njeni dve oznaki, da ostanete v kanalu';

  @override
  String get chartLegend_cable => 'Podmorski kabel';

  @override
  String get chartLegend_cableHint => 'Ne sidrajte';

  @override
  String get chartLegend_pipeline => 'Podmorski cevovod';

  @override
  String get chartLegend_pipelineHint => 'Ne sidrajte';

  @override
  String get chartLegend_overhead => 'Nadzemni kabel';

  @override
  String get chartLegend_overheadHint =>
      'Njegova svetla višina je označena z VC';

  @override
  String get chartLegend_tower => 'Stolp';

  @override
  String get chartLegend_windTurbine => 'Vetrna turbina';

  @override
  String get chartLegend_chimney => 'Dimnik';

  @override
  String get chartLegend_mast => 'Drog ali antena';

  @override
  String get chartLegend_church => 'Cerkev ali zvonik';

  @override
  String get chartLegend_flagstaff => 'Drog za zastavo';

  @override
  String get chartLegend_dome => 'Kupola';

  @override
  String get chartLegend_landmark => 'Druga orientacijska točka';

  @override
  String get chartLegend_abbrAnch => 'Sidrišče';

  @override
  String get chartLegend_abbrWk => 'Razbitina';

  @override
  String get chartLegend_abbrBr => 'Lomeči se valovi';

  @override
  String get chartLegend_abbrWd => 'Alge';

  @override
  String get chartLegend_abbrVar => 'Magnetna deklinacija';

  @override
  String get chartLegend_abbrVc => 'Svetla višina pod mostom ali kablom';

  @override
  String get chartLegend_abbrTr => 'Stolp';

  @override
  String get chartLegend_abbrCh => 'Cerkev';

  @override
  String get chartLegend_abbrChy => 'Dimnik';

  @override
  String get chartLegend_abbrFs => 'Drog za zastavo';

  @override
  String get chartLegend_abbrTk => 'Rezervoar';

  @override
  String get chartLegend_abbrRBn => 'Radijski svetilnik';

  @override
  String get chartLegend_abbrCg => 'Postaja obalne straže';

  @override
  String get chartLegend_abbrRacon => 'Radarski odzivnik: viden na radarju';

  @override
  String get chartLegend_abbrFog =>
      'Signal za meglo: hupa, zvon, gong, piščal ali sirena';

  @override
  String get chartLegend_abbrVAis => 'Navidezna oznaka: vidna samo v AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'od $from do $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Globlje od $depth';
  }

  @override
  String get parkLegend_title => 'Simboli parkov in poti';

  @override
  String get parkLegend_campsite => 'Kamp';

  @override
  String get parkLegend_picnicSite => 'Prostor za piknik';

  @override
  String get parkLegend_shelter => 'Zavetje';

  @override
  String get parkLegend_toilets => 'Stranišča';

  @override
  String get parkLegend_drinkingWater => 'Pitna voda';

  @override
  String get parkLegend_parking => 'Parkirišče';

  @override
  String get parkLegend_viewpoint => 'Razgledišče';

  @override
  String get parkLegend_attraction => 'Znamenitost';

  @override
  String get parkLegend_gate => 'Vrata';

  @override
  String get parkLegend_telephone => 'Telefon';

  @override
  String get parkLegend_information => 'Informacijska tabla';

  @override
  String get parkLegend_guidepost => 'Smerokaz';

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
