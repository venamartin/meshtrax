// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Chattar';

  @override
  String get chats_title => 'Chattar';

  @override
  String get newChat_title => 'Välj kontakt';

  @override
  String newChat_contactCount(int count) {
    return '$count kontakter';
  }

  @override
  String get newChat_newContact => 'Ny kontakt';

  @override
  String get newChat_newChannel => 'Ny kanal';

  @override
  String get newChat_myContacts => 'Mina kontakter';

  @override
  String get newChat_discovered => 'Upptäckta';

  @override
  String get repeaters_title => 'Hantera repeatrar';

  @override
  String get nav_contacts => 'Kontakter';

  @override
  String get nav_channels => 'Kanaler';

  @override
  String get nav_map => 'Karta';

  @override
  String get common_cancel => 'Avbryt';

  @override
  String get common_syncing_device_info => 'Läser enhetsinfo...';

  @override
  String get common_syncing_contacts => 'Läser kontakter...';

  @override
  String get common_syncing_channels => 'Läser kanaler...';

  @override
  String get common_syncing_messages => 'Läser meddelanden...';

  @override
  String get common_ok => 'Okej';

  @override
  String get common_connect => 'Anslut';

  @override
  String get common_unknownDevice => 'Okänd enhet';

  @override
  String get common_save => 'Spara';

  @override
  String get common_delete => 'Radera';

  @override
  String get common_deleteAll => 'Ta bort alla';

  @override
  String get common_close => 'Stänga';

  @override
  String get common_edit => 'Redigera';

  @override
  String get common_add => 'Lägg till';

  @override
  String get common_settings => 'Inställningar';

  @override
  String get common_disconnect => 'Koppla från';

  @override
  String get common_connected => 'Ansluten';

  @override
  String get common_disconnected => 'Ansluten';

  @override
  String get common_connectionLost => 'Anslutningen bröts. Ansluter igen...';

  @override
  String get common_reconnecting => 'Ansluter igen...';

  @override
  String get common_create => 'Skapa';

  @override
  String get common_continue => 'Fortsätt';

  @override
  String get common_share => 'Dela';

  @override
  String get common_copy => 'Kopiera';

  @override
  String get common_retry => 'Försök igen';

  @override
  String get common_hide => 'Dölj';

  @override
  String get common_remove => 'Ta bort';

  @override
  String get common_enable => 'Aktivera';

  @override
  String get common_disable => 'Inaktivera';

  @override
  String get common_reboot => 'Start om';

  @override
  String get common_loading => 'Laddar...';

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
  String get tcpScreenTitle => 'Anslut via TCP';

  @override
  String get tcpHostLabel => 'IP-adress';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Port';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Ange slutpunkt och anslut';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Anslutning till $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'IP-adress krävs.';

  @override
  String get tcpErrorPortInvalid => 'Porten måste vara mellan 1 och 65535.';

  @override
  String get tcpErrorUnsupported =>
      'TCP-transport fungerar inte på denna plattform.';

  @override
  String get tcpErrorTimedOut => 'TCP-anslutningen har tidsut gått.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Fel vid TCP-anslutning: $error';
  }

  @override
  String get usbScreenTitle => 'Anslut via USB';

  @override
  String get usbScreenSubtitle =>
      'Välj en detekterad seriell enhet och anslut direkt till din MeshCore-nod.';

  @override
  String get usbScreenStatus => 'Välj en USB-enhet';

  @override
  String get usbScreenNote =>
      'USB-seriell kommunikation är aktiv på stödda Android-enheter och på skrivbordsplattformar.';

  @override
  String get usbScreenEmptyState =>
      'Inga USB-enheter hittades. Anslut en och uppdatera.';

  @override
  String get usbErrorPermissionDenied => 'Tillgången via USB nekas.';

  @override
  String get usbErrorDeviceMissing =>
      'Den valda USB-enheten är inte längre tillgänglig.';

  @override
  String get usbErrorInvalidPort => 'Välj en giltig USB-enhet.';

  @override
  String get usbErrorBusy =>
      'En annan förfrågan om USB-anslutning är redan pågående.';

  @override
  String get usbErrorNotConnected => 'Ingen USB-enhet är ansluten.';

  @override
  String get usbErrorOpenFailed =>
      'Misslyckades med att öppna det valda USB-enheten.';

  @override
  String get usbErrorConnectFailed =>
      'Kunde inte ansluta till det valda USB-enheten.';

  @override
  String get usbErrorUnsupported =>
      'USB-seriell kommunikation stöds inte på denna plattform.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Den här versionen saknar sitt USB-seriebibliotek, så USB-enheter kan inte öppnas. Installera om MeshTrax eller rapportera den här versionen som trasig.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Den här webbläsaren stöder inte Web Serial. Använd Chrome eller Edge via HTTPS (eller localhost).';

  @override
  String get usbErrorAlreadyActive => 'En USB-anslutning är redan aktiv.';

  @override
  String get usbErrorNoDeviceSelected => 'Ingen USB-enhet valdes.';

  @override
  String get usbErrorPortClosed => 'USB-anslutningen är inte aktiv.';

  @override
  String get usbErrorConnectTimedOut =>
      'Anslutningen har tidsutgått. Se till att enheten har rätt USB-firmware.';

  @override
  String get usbFallbackDeviceName => 'Web-serieenhet';

  @override
  String get usbStatus_notConnected => 'Välj en USB-enhet';

  @override
  String get usbStatus_connecting => 'Anslutning till USB-enhet...';

  @override
  String get usbStatus_searching => 'Söker efter USB-enheter...';

  @override
  String usbConnectionFailed(String error) {
    return 'Fel vid USB-anslutning: $error';
  }

  @override
  String get scanner_scanning => 'Söker efter enheter...';

  @override
  String get scanner_connecting => 'Anslutning...';

  @override
  String get scanner_disconnecting => 'Anslutning bryts...';

  @override
  String get scanner_notConnected => 'Inte ansluten';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Ansluten till $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Visa alla Bluetooth-enheter';

  @override
  String get scanner_showMeshCoreOnly => 'Visa bara MeshCore-radioapparater';

  @override
  String get scanner_radioNotResponding =>
      'Radion svarar inte. Den kan behöva parkopplas: öppna Bluetooth-inställningarna, lägg till radion och ange dess PIN, och försök sedan igen.';

  @override
  String get scanner_pairingFailed =>
      'Bluetooth-parkopplingen avbröts eller misslyckades. Se till att inget annat (som din telefon) är anslutet till radion, försök sedan igen och ange dess PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Anslutning misslyckades: $error';
  }

  @override
  String get scanner_stop => 'Stoppa';

  @override
  String get scanner_scan => 'Skanna';

  @override
  String get scanner_scanFromImage => 'Skanna från bild';

  @override
  String get scanner_noQrFoundInImage =>
      'Ingen giltig QR-kod hittades i bilden';

  @override
  String get scanner_bluetoothOff => 'Bluetooth är avstängt';

  @override
  String get scanner_bluetoothOffMessage =>
      'Vänligen aktivera Bluetooth för att söka efter enheter.';

  @override
  String get scanner_chromeRequired => 'Chrome-webbläsare krävs';

  @override
  String get scanner_chromeRequiredMessage =>
      'Denna webbapplikation kräver Google Chrome oder en Chromium-baserader webbläsare för Bluetooth-stöd.';

  @override
  String get scanner_enableBluetooth => 'Aktivera Bluetooth';

  @override
  String get device_quickSwitch => 'Snabb växling';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Inställningar';

  @override
  String get settings_deviceInfo => 'Enhetens information';

  @override
  String get settings_appSettings => 'Appinställningar';

  @override
  String get settings_appSettingsSubtitle =>
      'Meddelanden, notiser och kartinställningar';

  @override
  String get settings_nodeSettings => 'Nodinställningar';

  @override
  String get settings_nodeName => 'Nodnamn';

  @override
  String get settings_nodeNameNotSet => 'Inte angivet';

  @override
  String get settings_nodeNameHint => 'Ange nodnamn';

  @override
  String get settings_nodeNameUpdated => 'Namn uppdaterat';

  @override
  String get settings_radioSettings => 'Radioinställningar';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frekvens, effekt, spridningsfaktor';

  @override
  String get settings_radioSettingsUpdated =>
      'Radioinställningarna har uppdaterats';

  @override
  String get settings_location => 'Plats';

  @override
  String get settings_locationSubtitle => 'GPS koordinater';

  @override
  String get settings_locationUpdated => 'Plats uppdaterad';

  @override
  String get settings_locationBothRequired => 'Ange både latitud och longitud.';

  @override
  String get settings_locationInvalid => 'Ogiltig latitud eller longitud.';

  @override
  String get settings_locationGPSEnable => 'Aktivera GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Aktivera automatiska uppdateringar av platsen med hjälp av GPS.';

  @override
  String get settings_latitude => 'Latitud';

  @override
  String get settings_longitude => 'Längdgrad';

  @override
  String get settings_contactSettings => 'Kontaktinställningar';

  @override
  String get settings_contactSettingsSubtitle =>
      'Inställningar för hur kontakter läggs till.';

  @override
  String get settings_privacyMode => 'Privatläge';

  @override
  String get settings_privacyModeSubtitle => 'Dölj namn/plats i annonser';

  @override
  String get settings_privacyModeToggle =>
      'Aktivera privatläge för att dölja ditt namn och din plats i annonser.';

  @override
  String get settings_privacyModeEnabled => 'Privatläget är aktiverat';

  @override
  String get settings_privacyModeDisabled => 'Privatläge är avstängt';

  @override
  String get settings_privacy => 'Inställningar för sekretess';

  @override
  String get settings_privacySubtitle =>
      'Kontrollera vilken information som delas.';

  @override
  String get settings_privacySettingsDescription =>
      'Välj vilken information din enhet delar med andra.';

  @override
  String get settings_denyAll => 'Neka alla';

  @override
  String get settings_allowByContact => 'Tillåt via kontaktflaggor';

  @override
  String get settings_allowAll => 'Tillåt alla';

  @override
  String get settings_telemetryBaseMode => 'Telemetribasläge';

  @override
  String get settings_telemetryLocationMode => 'Telemetritillstånd för plats';

  @override
  String get settings_telemetryEnvironmentMode => 'Telemetri miljöläge';

  @override
  String get settings_advertLocation => 'Annonsplacering';

  @override
  String get settings_advertLocationSubtitle => 'Inkludera plats i annonsen';

  @override
  String get settings_multiAck => 'Flera bekräftelser';

  @override
  String get settings_telemetryModeUpdated => 'Telemetri-läge uppdaterat';

  @override
  String get settings_actions => 'Åtgärder';

  @override
  String get settings_sendAdvertisement => 'Skicka Annons';

  @override
  String get settings_sendAdvertisementSubtitle => 'Sändning finns nu';

  @override
  String get settings_advertisementSent => 'Annons skickad';

  @override
  String get settings_syncTime => 'Synkroniseringstid';

  @override
  String get settings_syncTimeSubtitle => 'Ställ enheten till telefonens tid';

  @override
  String get settings_timeSynchronized => 'Tidssynkroniserat';

  @override
  String get settings_refreshContacts => 'Uppdatera Kontakter';

  @override
  String get settings_refreshContactsSubtitle =>
      'Ladda om kontaktlistan från enheten';

  @override
  String get settings_rebootDevice => 'Starta om enheten';

  @override
  String get settings_rebootDeviceSubtitle => 'Starta MeshCore-enheten';

  @override
  String get settings_rebootDeviceConfirm =>
      'Är du säker på att du vill starta om enheten? Du kommer att bli avkopplad.';

  @override
  String get settings_debug => 'Felsök';

  @override
  String get settings_bleDebugLog => 'BLE-felsökning';

  @override
  String get settings_bleDebugLogSubtitle => 'BLE-kommandon, svar och rådata';

  @override
  String get settings_appDebugLog => 'Appfelsökning';

  @override
  String get settings_appDebugLogSubtitle =>
      'Applikations felsökningsmeddelanden';

  @override
  String get settings_exportDatabase => 'Exportera meddelandedatabas';

  @override
  String get settings_exportDatabaseSubtitle =>
      'En kopia av alla chattar och kontakter, för felsökning. Håll den privat.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Databasen sparad i: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Exporten misslyckades: $error';
  }

  @override
  String get settings_about => 'Om';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => '2024 MeshCore Öppen Källkodsprojekt';

  @override
  String get settings_aboutDescription =>
      'En öppen källkods Flutter-klient för MeshCore LoRa meshnätverksenheter.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS-höjddata: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Namn';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Batteri';

  @override
  String get settings_infoPublicKey => 'Allmänt nyckel';

  @override
  String get settings_infoContactsCount => 'Kontakterantal';

  @override
  String get settings_infoChannelCount => 'Kanalantal';

  @override
  String get settings_presets => 'Fördefinierade inställningar';

  @override
  String get settings_frequency => 'Frekvens (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Ogiltig frekvens (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Bandbredd';

  @override
  String get settings_spreadingFactor => 'Spreadingfaktor';

  @override
  String get settings_codingRate => 'Kodningsgrad';

  @override
  String get settings_txPower => 'TX-effekt (dBm)';

  @override
  String get settings_txPowerInvalid => 'Ogiltig TX-effekt';

  @override
  String get settings_clientRepeat => 'Upprepa utan elnät';

  @override
  String get settings_clientRepeatSubtitle =>
      'Låt enheten repetera nätpaket för andra användare.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'För att kunna kommunicera utanför elnätet krävs frekvenserna 433, 869 eller 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Fel: $message';
  }

  @override
  String get appSettings_title => 'Appinställningar';

  @override
  String get appSettings_appearance => 'Utseende';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Systemstandard';

  @override
  String get appSettings_themeLight => 'Ljus';

  @override
  String get appSettings_themeDark => 'Mörk';

  @override
  String get appSettings_language => 'Språk';

  @override
  String get appSettings_languageSystem => 'Systemstandard';

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
  String get appSettings_languageRu => 'Ryska';

  @override
  String get appSettings_languageUk => 'Ukrainska';

  @override
  String get appSettings_enableMessageTracing => 'Aktivera meddelandespårning';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Visa detaljerade metadata om dirigering och tidsinställningar för meddelanden';

  @override
  String get appSettings_senderNameColors => 'Färgglada avsändarnamn';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Ge varje avsändare i kanaler en egen namnfärg. Av använder temafärgen för alla.';

  @override
  String get appSettings_showTextFormatting => 'Visa textformatering';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown i meddelanden: **fet**, *kursiv*, ||spoilers||, rubriker och länkar. Andra MeshCore-appar visar råtecknen.';

  @override
  String get appSettings_notifications => 'Meddelanden';

  @override
  String get appSettings_enableNotifications => 'Aktivera Notifikationer';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Ta emot notiser för meddelanden och reklam';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Tillåtelse för notifikationer nekad';

  @override
  String get appSettings_notificationsEnabled => 'Notifikationer aktiverade';

  @override
  String get appSettings_notificationsDisabled => 'Meddelanden är avstängda';

  @override
  String get appSettings_messageNotifications => 'Meddelandekrav';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Visa notis när nya meddelanden tas emot';

  @override
  String get appSettings_channelMessageNotifications => 'Kanalmeddelandena';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Visa notis när meddelanden i kanal mottas';

  @override
  String get appSettings_advertisementNotifications => 'Annonsmeddelanden';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Visa notis när nya noder upptäcks';

  @override
  String get appSettings_messaging => 'Meddelanden';

  @override
  String get appSettings_maxMessageRetries => 'Maximalt antal försök';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Antal försök att skicka om ett meddelande innan det markeras som misslyckat.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Max antal nya försök för kanalmeddelanden';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Försöker igen så här många gånger tills minst en upprepning hörs';

  @override
  String get appSettings_battery => 'Batteri';

  @override
  String get appSettings_batteryChemistry => 'Batterikemi';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Ställ in per enhet ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Anslut till en enhet för att välja';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => 'Kartvisning';

  @override
  String get appSettings_showRepeaters => 'Visa återuppslag';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Visa återspelsnoder på kartan';

  @override
  String get appSettings_showChatNodes => 'Visa Chattnoder';

  @override
  String get appSettings_showChatNodesSubtitle => 'Visa chattnoder på kartan';

  @override
  String get appSettings_showOtherNodes => 'Visa andra noder';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Visa andra nodtyper på kartan';

  @override
  String get appSettings_timeFilter => 'Tidsfilter';

  @override
  String get appSettings_timeFilterShowAll => 'Visa alla noder';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Visa noder från de senaste $hours timmarna';
  }

  @override
  String get appSettings_mapTimeFilter => 'Karttid Filter';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Visa noder som upptäckts inom:';

  @override
  String get appSettings_allTime => 'Totalen';

  @override
  String get appSettings_lastHour => 'Sista timmen';

  @override
  String get appSettings_last6Hours => 'De senaste 6 timmarna';

  @override
  String get appSettings_last24Hours => 'De senaste 24 timmarna';

  @override
  String get appSettings_lastWeek => 'Förra veckan';

  @override
  String get appSettings_unitsTitle => 'Enheter';

  @override
  String get appSettings_unitsMetric => 'Metriskt (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperialt (ft / mi)';

  @override
  String get appSettings_debugCard => 'Felsök';

  @override
  String get appSettings_appDebugLogging => 'App-felsökning och loggning';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Logga appens felsökningsmeddelanden för felsökning';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'App felsökning loggning aktiverad';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'App felsökning är avstängd';

  @override
  String get appSettings_incrementalContactSync => 'Inkrementell kontaktsynk';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Vid återanslutning, be radion bara om kontakter som ändrats sedan senast';

  @override
  String get contacts_title => 'Kontakter';

  @override
  String get contacts_noContacts => 'Inga kontakter ännu';

  @override
  String get contacts_shareMyQrCode => 'Dela min QR-kod';

  @override
  String get contacts_shareQrCodeDesc =>
      'Låt andra skanna för att lägga till dig som kontakt';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakter kommer att visas när enheter annonserar.';

  @override
  String get contacts_unread => 'Oläst';

  @override
  String get contacts_searchContactsNoNumber => 'Sök kontakter...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Sök kontakter...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Sök $number$str Favoriter...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Sök $number$str användare...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Sök $number$str upprepningsenheter...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Sök $number$str Room-servrar...';
  }

  @override
  String get contacts_noUnreadContacts => 'Inga oinlästa kontakter';

  @override
  String get contacts_noContactsFound =>
      'Inga kontakter eller grupper hittades.';

  @override
  String get contacts_deleteContact => 'Ta bort Kontakt';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Vill du verkligen ta bort $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Kontakten $contactName togs bort.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Det gick inte att ta bort $contactName.';
  }

  @override
  String get contacts_noMatchingContacts => 'Inga kontakter matchar filtret.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Ta bort $contactName från kontakter?';
  }

  @override
  String get contacts_manageRepeater => 'Hantera Upprepare';

  @override
  String get contacts_manageRoom => 'Hantera Rumserver';

  @override
  String get contacts_roomLogin => 'Rum Inloggning';

  @override
  String get contacts_openChat => 'Öppna Chatt';

  @override
  String get contacts_editGroup => 'Redigera Grupp';

  @override
  String get contacts_deleteGroup => 'Ta bort Grupp';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Ta bort $groupName?';
  }

  @override
  String get contacts_newGroup => 'Ny grupp';

  @override
  String get contacts_groupName => 'Gruppnamn';

  @override
  String get contacts_groupNameRequired => 'Gruppnamnet är obligatoriskt';

  @override
  String get contacts_groupNameReserved => 'Detta gruppnamn är reserverat';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Gruppen \"$name\" finns redan.';
  }

  @override
  String get contacts_filterContacts => 'Filtrera kontakter...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Inga kontakter matchar ditt filter';

  @override
  String get contacts_noMembers => 'Inga medlemmar';

  @override
  String get contacts_lastSeenNow => 'Senast synlig nu';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Senast sedd $minutes min sedan';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Senast sedd för 1 timme sedan';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Senast sedd $hours timmar sedan';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Senast sedd för 1 dag sedan';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Senast synlig $days dagar sedan';
  }

  @override
  String get contact_info => 'Kontaktinformation';

  @override
  String get contact_settings => 'Kontaktinställningar';

  @override
  String get contact_telemetry => 'Telemetri';

  @override
  String get contact_lastSeen => 'Senast sedd';

  @override
  String get contact_clearChat => 'Rensa Chatt';

  @override
  String get contact_teleBase => 'Telemetribas';

  @override
  String get contact_teleBaseSubtitle =>
      'Tillåt delning av batterinivå och grundläggande telemetri';

  @override
  String get contact_teleLoc => 'Telemetridata plats';

  @override
  String get contact_teleLocSubtitle => 'Tillåt delning av platsdata';

  @override
  String get contact_teleEnv => 'Telemetri Miljö';

  @override
  String get contact_teleEnvSubtitle => 'Tillåt delning av miljösensordata';

  @override
  String get contacts_publicKey => 'Publik nyckel';

  @override
  String get channels_title => 'Kanaler';

  @override
  String get channels_noChannelsConfigured => 'Inga kanaler konfigurerade';

  @override
  String get channels_addPublicChannel => 'Lägg till publik kanal';

  @override
  String get channels_searchChannels => 'Sök kanaler...';

  @override
  String get channels_noChannelsFound => 'Inga kanaler hittades';

  @override
  String channels_channelIndex(int index) {
    return 'Kanal $index';
  }

  @override
  String get channels_hashtagChannel => 'Hashtagkanal';

  @override
  String get channels_public => 'Offentligt';

  @override
  String get channels_private => 'Privat';

  @override
  String get channels_publicChannel => 'Allmänt kanal';

  @override
  String get channels_privateChannel => 'Privat kanal';

  @override
  String get channels_editChannel => 'Redigera kanal';

  @override
  String get channels_shareChannel => 'Dela kanal';

  @override
  String get channels_shareChannelInstructions =>
      'Skanna QR-koden för att lägga till kanalen.\nMeny → Lägg till kanal → Skanna en QR-kod';

  @override
  String get channels_secretKey => 'Hemlig nyckel';

  @override
  String get channels_meshcoreUri => 'MeshCore-URI';

  @override
  String get channels_shareChannelQr => 'Skanna kanalens QR-kod';

  @override
  String get channels_shareChannelWarning =>
      'Varning: Alla som skannar den här QR-koden får tillgång till kanalen.';

  @override
  String get channels_muteChannel => 'Tysta kanal';

  @override
  String get channels_unmuteChannel => 'Slå på ljud för kanal';

  @override
  String get channels_deleteChannel => 'Ta bort kanal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Radera \"$name\"? Detta kan inte ångras.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Det gick inte att ta bort kanalen \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanalen \"$name\" raderad';
  }

  @override
  String get channels_addChannel => 'Lägg till kanal';

  @override
  String get channels_channelIndexLabel => 'Kanalindex';

  @override
  String get channels_channelName => 'Kanalnamn';

  @override
  String get channels_usePublicChannel => 'Använd Publikkanal';

  @override
  String get channels_standardPublicPsk => 'Standard allmän PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Generera slumpmässig PSK';

  @override
  String get channels_enterChannelName => 'Ange en kanalnamn';

  @override
  String get channels_pskMustBe32Hex => 'PSK måste vara 32 hexadecimala tecken';

  @override
  String get channels_addChannelConfirmation =>
      'Vill du lägga till följande kanal?';

  @override
  String get channels_channelAddedSuccess => 'Kanalen har lagts till.';

  @override
  String get channels_noAvailableChannelSlots => 'Inga lediga kanalplatser.';

  @override
  String get appSettings_mentionNotifications => 'Aviseringar vid omnämnanden';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'När någon nämner eller svarar dig — även i tystade kanaler';

  @override
  String notification_mentionIn(String channelName) {
    return 'Omnämnd i $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Kanalen \"$name\" har lagts till';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Redigera Kanal $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ-komprimering';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanalen \"$name\" har uppdaterats';
  }

  @override
  String get channels_publicChannelAdded => 'Allmänt kanal tillagd';

  @override
  String get channels_sortBy => 'Sortera efter';

  @override
  String get channels_sortManual => 'Manuell';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Senaste meddelanden';

  @override
  String get channels_sortUnread => 'Oläst';

  @override
  String get channels_createPrivateChannel => 'Skapa en privat kanal';

  @override
  String get channels_createPrivateChannelDesc =>
      'Skyddat med en hemlig nyckel.';

  @override
  String get channels_joinPrivateChannel => 'Gå med i en Privat Kanal';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Ange en hemlig nyckel manuellt.';

  @override
  String get channels_joinPublicChannel => 'Gå med i den Offentliga Kanalen';

  @override
  String get channels_joinPublicChannelDesc =>
      'Vem som helst kan gå med i denna kanal.';

  @override
  String get channels_joinHashtagChannel => 'Gå med i en Hashtagkanal';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Väldigt enkelt att gå med i hashtag-kanaler.';

  @override
  String get channels_scanQrCode => 'Skanna en QR-kod';

  @override
  String get channels_scanQrCodeComingSoon => 'Kommer snart';

  @override
  String get channels_enterHashtag => 'Ange hashtag';

  @override
  String get channels_hashtagHint => 't.ex. #team';

  @override
  String get chat_noMessages => 'Inga meddelanden ännu';

  @override
  String get chat_sendMessage => 'Skicka meddelande';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Skicka ett meddelande till $contactName';
  }

  @override
  String get chat_sendMessageToStart =>
      'Skicka ett meddelande för att komma igång';

  @override
  String get chat_originalMessageNotFound =>
      'Originalt meddelande hittades inte';

  @override
  String chat_replyingTo(String name) {
    return 'Svara till $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Svara till $name';
  }

  @override
  String get chat_location => 'Plats';

  @override
  String get common_copiedToClipboard => 'Kopierat till urklipp';

  @override
  String get common_copyToClipboard => 'Kopiera till urklipp';

  @override
  String get contacts_copyContactToClipboard =>
      'Kopiera min kontakt till urklipp';

  @override
  String get chat_typeMessage => 'Skriv ett meddelande...';

  @override
  String get chat_searchMessages => 'Sök meddelanden';

  @override
  String get chat_searchNoMatches => 'Inga träffar';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Meddelandet är för långt (max $maxBytes byte).';
  }

  @override
  String get chat_messageCopied => 'Meddelandet kopierades';

  @override
  String get chat_messageDeleted => 'Meddelandet raderat';

  @override
  String get chat_sendGif => 'Skicka GIF';

  @override
  String get chat_reply => 'Svara';

  @override
  String get chat_newMessages => 'NYA MEDDELANDEN';

  @override
  String get chat_addReaction => 'Lägg till reaktion';

  @override
  String get chat_mention => 'Nämn';

  @override
  String get dmChannel_menuLabel => 'Direktmeddelande';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Skicka DM till $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Kontrollera nyckeln och när kontakten senast sågs — namn är inte unika.';

  @override
  String get dmChannel_warningTitle => 'Är det verkligen rätt person?';

  @override
  String get dmChannel_warningBody =>
      'Namn i kanaler väljer man själv och vem som helst kan efterlikna dem. För något känsligt, kontrollera först kontaktens publika nyckel på annat sätt.';

  @override
  String get dmChannel_dontShowAgain => 'Visa inte igen';

  @override
  String get batterySleep_title => 'Håll MeshTrax igång';

  @override
  String get batterySleep_bodySamsung =>
      'Samsung-telefoner försätter appar i viloläge för att spara batteri, vilket kopplar bort din radio. Öppna Inställningar → Appar → MeshTrax → Batteri och välj Obegränsad. Kontrollera även Batteri → Gränser för bakgrundsanvändning och se till att MeshTrax inte finns under Appar i viloläge eller Appar i djupt viloläge.';

  @override
  String get batterySleep_bodyGeneric =>
      'Din telefon kan stoppa MeshTrax i bakgrunden för att spara batteri, vilket kopplar bort din radio. Öppna batteriinställningarna och ställ in MeshTrax på Obegränsad (eller Inga begränsningar). På vissa telefoner behöver du också slå på Autostart för MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Öppna inställningar';

  @override
  String get batterySleep_notNow => 'Inte nu';

  @override
  String get batterySleep_settingsTile => 'Håll MeshTrax igång i bakgrunden';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Hindra telefonens batterisparläge från att söva MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Kan inte skicka DM till $name än';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Du har inte deras nyckel än, och de behöver din för att svara — nycklar skickas bara i annonser. ”Skicka min annons” sänder ut din direkt härifrån. ”Fråga i kanalen” skriver en förfrågan i meddelandefältet som du sedan skickar.';

  @override
  String get dmChannel_askInChannel => 'Fråga i kanalen';

  @override
  String get dmChannel_sendMyAdvert => 'Skicka min annons';

  @override
  String get dmChannel_askText =>
      'skicka gärna en annons så att jag kan skicka DM till dig';

  @override
  String get dmChannel_watching =>
      'Väntar på deras annons — du får en fråga här när den kommer.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name går nu att nå';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Zoomnivå';

  @override
  String get common_reset => 'Återställ';

  @override
  String get chat_reactionsTitle => 'Reaktioner';

  @override
  String get chat_reactionUnknownSender => 'Okänd';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender reagerade på ett meddelande som inte finns i den här chatten';
  }

  @override
  String get chat_me => 'Mig';

  @override
  String get emojiCategorySmileys => 'Emojis';

  @override
  String get emojiCategoryGestures => 'Gestikuleringar';

  @override
  String get emojiCategoryHearts => 'Hjärtan';

  @override
  String get emojiCategoryObjects => 'Objekt';

  @override
  String get gifPicker_title => 'Välj en GIF';

  @override
  String get gifPicker_searchHint => 'Sök GIF:ar...';

  @override
  String get gifPicker_poweredBy => 'Drivet av GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Inga GIF-filer hittades';

  @override
  String get gifPicker_failedLoad => 'Kunde inte ladda GIF-filer';

  @override
  String get gifPicker_failedSearch => 'Sökningen misslyckades.';

  @override
  String get gifPicker_noInternet => 'Ingen internetanslutning';

  @override
  String get debugLog_appTitle => 'Appfelsökning';

  @override
  String get debugLog_bleTitle => 'BLE-felsökning';

  @override
  String get debugLog_copyLog => 'Kopiera logg';

  @override
  String get debugLog_saveLog => 'Spara logg till fil';

  @override
  String get debugLog_saved => 'Loggen sparad';

  @override
  String get debugLog_saveCancelled => 'Sparandet avbröts';

  @override
  String get debugLog_filterAll => 'Alla';

  @override
  String get debugLog_filterWarnings => 'Varningar';

  @override
  String get debugLog_filterErrors => 'Fel';

  @override
  String get debugLog_clearLog => 'Rensa logg';

  @override
  String get debugLog_copied => 'Felsökningslogg kopierad';

  @override
  String get debugLog_bleCopied => 'BLE-logg kopierad';

  @override
  String get debugLog_noEntries => 'Inga felsökningsloggar ännu';

  @override
  String get debugLog_enableInSettings =>
      'Aktivera appens felsökningsloggning i inställningarna';

  @override
  String get debugLog_frames => 'Rammar';

  @override
  String get debugLog_rawLogRx => 'Rå Log-RX';

  @override
  String get debugLog_noBleActivity => 'Ingen BLE-aktivitet ännu';

  @override
  String debugFrame_length(int count) {
    return 'Ramstorlek: $count byte';
  }

  @override
  String debugFrame_command(String value) {
    return 'Kommando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Textmeddelandefält:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '– Destination PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Tidsstämpel: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flaggor: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Texttyp: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'CLI-kommando';

  @override
  String get debugFrame_textTypePlain => 'Enkel';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hexdump:';

  @override
  String get chat_hopSingular => 'hoppa';

  @override
  String get chat_hopPlural => 'hoppar';

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
  String get chat_setCustomPath => 'Ange anpassad sökväg';

  @override
  String get chat_fullPath => 'Fullständig sökväg';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Stigaruppgifterna är ännu inte tillgängliga. Försök att skicka ett meddelande för att uppdatera.';

  @override
  String get chat_type => 'Skriv';

  @override
  String get chat_path => 'Sökväg';

  @override
  String get chat_publicKey => 'Allmänt nyckel';

  @override
  String get chat_compressOutgoingMessages => 'Kryptera utgående meddelanden';

  @override
  String get chat_floodForced => 'Översvämning (tvingad)';

  @override
  String get chat_directForced => 'Direkt (tvingad)';

  @override
  String chat_hopsForced(int count) {
    return '$count hopp (tvingat)';
  }

  @override
  String get chat_floodAuto => 'Översvämning (auto)';

  @override
  String get chat_direct => 'Direkt';

  @override
  String get chat_poiShared => 'Delad POI';

  @override
  String chat_unread(int count) {
    return 'Olästa: $count';
  }

  @override
  String get chat_openLink => 'Öppna länk?';

  @override
  String get chat_openLinkConfirmation =>
      'Vill du öppna den här länken i din webbläsare?';

  @override
  String get chat_open => 'Öppna';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Kunde inte öppna länken: $url';
  }

  @override
  String get chat_invalidLink => 'Ogiltigt länkformat';

  @override
  String get map_lineOfSight => 'Synlinje';

  @override
  String get map_losScreenTitle => 'Synlinje';

  @override
  String get map_noNodesWithLocation => 'Inga noder med platsinformation';

  @override
  String get map_nodesNeedGps =>
      'Noder måste dela sina GPS-koordinater\nför att visas på kartan';

  @override
  String map_nodesCount(int count) {
    return 'Noder: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pinnar: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Återuppspelare';

  @override
  String get map_room => 'Rum';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Lås (DM)';

  @override
  String get map_pinPrivate => 'Lås (Privat)';

  @override
  String get map_pinPublic => 'Anslå (Offentligt)';

  @override
  String get map_lastSeen => 'Senast sedd';

  @override
  String get map_disconnectConfirm =>
      'Är du säker på att du vill koppla från enheten?';

  @override
  String get map_from => 'Från';

  @override
  String get map_source => 'Källa';

  @override
  String get map_flags => 'Flaggor';

  @override
  String get map_shareMarkerHere => 'Dela markeringen här';

  @override
  String get map_setAsMyLocation => 'Ange som min plats';

  @override
  String get map_pinLabel => 'Fästetikett';

  @override
  String get map_label => 'Etikett';

  @override
  String get map_pointOfInterest => 'Plats av intresse';

  @override
  String get map_sendToContact => 'Skicka till kontakt';

  @override
  String get map_sendToChannel => 'Skicka till kanal';

  @override
  String get map_noChannelsAvailable => 'Inga kanaler tillgängliga';

  @override
  String get map_publicLocationShare => 'Dela offentlig plats';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Du håller på att dela en plats i $channelLabel. Denna kanal är offentlig och alla med PSK kan se den.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Anslut till en enhet för att dela markörer';

  @override
  String get map_filterNodes => 'Filtrera noder';

  @override
  String get map_chatNodes => 'Chatnoder';

  @override
  String get map_repeaters => 'Upprepare';

  @override
  String get map_otherNodes => 'Andra noder';

  @override
  String get map_showOverlaps => 'Repeater-nyckelöverlappningar';

  @override
  String get map_keyPrefix => 'Nyckelprefix';

  @override
  String get map_filterByKeyPrefix => 'Filtrera efter nyckelprefix';

  @override
  String get map_publicKeyPrefix => 'Allmänt nyckelprästegenskap';

  @override
  String get map_showDiscoveryContacts => 'Visa Discovery-kontakter';

  @override
  String get map_guessedLocation => 'Gissad plats';

  @override
  String get map_lastSeenTime => 'Senaste Visats Tid';

  @override
  String get map_sharedPin => 'Delad PIN';

  @override
  String get map_joinRoom => 'Gå med i rum';

  @override
  String get map_manageRepeater => 'Hantera Upprepare';

  @override
  String get map_tapToAdd => 'Tryck på noder för att lägga till dem i banan.';

  @override
  String get map_runTrace => 'Kör spårsökning';

  @override
  String get map_runTraceWithReturnPath => 'Gå tillbaka på samma väg';

  @override
  String get map_removeLast => 'Ta bort sista';

  @override
  String get map_pathTraceCancelled => 'Sökvägsspårning avbruten.';

  @override
  String get time_justNow => 'Precis nu';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes min sedan';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours timmar sedan';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dagar sedan';
  }

  @override
  String get time_hour => 'timme';

  @override
  String get time_hours => 'timmar';

  @override
  String get time_day => 'dag';

  @override
  String get time_days => 'dagar';

  @override
  String get time_week => 'vecka';

  @override
  String get time_weeks => 'veckor';

  @override
  String get time_month => 'månad';

  @override
  String get time_months => 'månader';

  @override
  String get time_minutes => 'minuter';

  @override
  String get time_allTime => 'Alla tider';

  @override
  String get dialog_disconnect => 'Koppla från';

  @override
  String get dialog_disconnectConfirm =>
      'Är du säker på att du vill koppla från enheten?';

  @override
  String get login_repeaterLogin => 'Återuppta Inloggning';

  @override
  String get login_roomLogin => 'Rum Inloggning';

  @override
  String get login_password => 'Lösenord';

  @override
  String get login_enterPassword => 'Ange lösenord';

  @override
  String get login_savePassword => 'Spara lösenord';

  @override
  String get login_savePasswordSubtitle =>
      'Lösenord kommer att lagras säkert på enheten.';

  @override
  String get login_repeaterDescription =>
      'Ange återuppspelarens lösenord för att komma åt inställningar och status.';

  @override
  String get login_roomDescription =>
      'Ange rummets lösenord för att komma åt inställningar och status.';

  @override
  String get login_login => 'Logga in';

  @override
  String login_attempt(int current, int max) {
    return 'Försök $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Inloggning misslyckades: $error';
  }

  @override
  String get login_failedMessage =>
      'Inloggning misslyckades. Antingen är lösenordet fel eller så går det inte att nå repeatern.';

  @override
  String get common_reload => 'Ladda om';

  @override
  String get common_clear => 'Rensa';

  @override
  String get path_enterCustomPath => 'Ange anpassad sökväg';

  @override
  String get path_currentPathLabel => 'Nuvarande sökväg';

  @override
  String get path_hexPrefixInstructions =>
      'Ange 2-tecknets hex-prefett för varje hopp, åtskilda med komma.';

  @override
  String get path_hexPrefixExample =>
      'Exempel: A1,F2,3C (varje nod använder det första bytet av sitt publika nyckel)';

  @override
  String get path_labelHexPrefixes => 'Hexprefixer';

  @override
  String get path_helperMaxHops =>
      'Max 64 hopp. Varje prefix är 2 hex-tecken (1 byte)';

  @override
  String get path_selectFromContacts => 'Välj istället från kontakter:';

  @override
  String get path_noRepeatersFound =>
      'Inga återuppspelare eller rumsservrar hittades.';

  @override
  String get path_customPathsRequire =>
      'Anpassade sökvägar kräver mellansteg som kan vidarebefordra meddelanden.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Ogiltiga hex-prefikser: $prefixes';
  }

  @override
  String get path_tooLong => 'Sökvägen är för lång. Max 64 hopp tillåtna.';

  @override
  String get path_setPath => 'Ange Sökväg';

  @override
  String get repeater_management => 'Återuppspelarens Hantering';

  @override
  String get room_management => 'Rumserverhantering';

  @override
  String get repeater_guest => 'Information om repetorer';

  @override
  String get room_guest => 'Information om servern';

  @override
  String get repeater_managementTools => 'Administrationsverktyg';

  @override
  String get repeater_guestTools => 'Gästverktyg';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Visa återspolningsstatus, statistik och grannar';

  @override
  String get repeater_telemetry => 'Telemetry';

  @override
  String get repeater_telemetrySubtitle =>
      'Visa telemetri för sensorer och systemstatistik';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Skicka kommandon till repetitorn';

  @override
  String get repeater_neighbors => 'Grannar';

  @override
  String get repeater_neighborsSubtitle => 'Visa noll hoppgrannar.';

  @override
  String get repeater_settings => 'Inställningar';

  @override
  String get repeater_settingsSubtitle => 'Konfigurera återspolarparametrar';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Synkronisera klockan efter inloggning';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automatiskt skicka \"klocksynkronisering\" efter en lyckad inloggning.';

  @override
  String get repeater_statusTitle => 'Återspelsstatus';

  @override
  String get repeater_refresh => 'Uppdatera';

  @override
  String get repeater_statusRequestTimeout =>
      'Statusförfrågan gick inte att hämta.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Fel vid inläsning av status: $error';
  }

  @override
  String get repeater_systemInformation => 'Systeminformation';

  @override
  String get repeater_battery => 'Batteri';

  @override
  String get repeater_clockAtLogin => 'Klocka (vid inloggning)';

  @override
  String get repeater_uptime => 'Tillgänglighet';

  @override
  String get repeater_queueLength => 'Köans längd';

  @override
  String get repeater_debugFlags => 'Felsökningsflaggor';

  @override
  String get repeater_radioStatistics => 'Radiostatistik';

  @override
  String get repeater_lastRssi => 'Senaste RSSI';

  @override
  String get repeater_lastSnr => 'Sista SNR';

  @override
  String get repeater_noiseFloor => 'Ljudnivå';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Paketstatistik';

  @override
  String get repeater_sent => 'Skickat';

  @override
  String get repeater_received => 'Mottaget';

  @override
  String get repeater_duplicates => 'Dubbletter';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dagar $hours timmar $minutes minuter $seconds sekunder';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Totalt: $total, Översvämning: $flood, Direkt: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Totalt: $total, Översvämning: $flood, Direkt: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Översvämning: $flood, Direkt: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Totalt: $total';
  }

  @override
  String get repeater_settingsTitle => 'Återuppspelarens Inställningar';

  @override
  String get repeater_basicSettings => 'Grundinställningar';

  @override
  String get repeater_repeaterName => 'Upprepare Namn';

  @override
  String get repeater_repeaterNameHelper => 'Visa namn för denna återupprepare';

  @override
  String get repeater_adminPassword => 'Adminlösenord';

  @override
  String get repeater_adminPasswordHelper => 'Fullständig åtkomstlösenord';

  @override
  String get repeater_guestPassword => 'Gästlösenhet';

  @override
  String get repeater_guestPasswordHelper => 'Läs-skyddspassord';

  @override
  String get repeater_radioSettings => 'Radioinställningar';

  @override
  String get repeater_frequencyMhz => 'Frekvens (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Effekt';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Bandbredd';

  @override
  String get repeater_spreadingFactor => 'Spreadingfaktor';

  @override
  String get repeater_codingRate => 'Kodningsgrad';

  @override
  String get repeater_locationSettings => 'Platsinställningar';

  @override
  String get repeater_latitude => 'Latitud';

  @override
  String get repeater_latitudeHelper => 'Decimalgrader (t.ex. 37.7749)';

  @override
  String get repeater_longitude => 'Längdgrad';

  @override
  String get repeater_longitudeHelper => 'Decimalgrader (t.ex. -122.4194)';

  @override
  String get repeater_features => 'Funktioner';

  @override
  String get repeater_packetForwarding => 'Paketväxling';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Aktivera återuppspelaren för att vidarebefordra paket';

  @override
  String get repeater_guestAccess => 'Gäståtkomst';

  @override
  String get repeater_guestAccessSubtitle =>
      'Tillåt läsbehörigheter för gäster.';

  @override
  String get repeater_privacyMode => 'Privatläge';

  @override
  String get repeater_privacyModeSubtitle => 'Dölj namn/plats i annonser';

  @override
  String get repeater_advertisementSettings => 'Annonsinställningar';

  @override
  String get repeater_localAdvertInterval => 'Lokalt Annonsintervall';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minuter';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Översvämnadsannonsens tidsintervall';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours timmar';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Krypterad Annonsintervall';

  @override
  String get repeater_dangerZone => 'Faraområde';

  @override
  String get repeater_rebootRepeater => 'Starta Återuppspelaren';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Starta om repeternheten';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Är du säker på att du vill starta om denna repeater?';

  @override
  String get repeater_regenerateIdentityKey => 'Generera Identitetsknyckel';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Generera ny publik/privat nyckelpar';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Detta kommer att generera en ny identitet för återspelaren. Fortsätta?';

  @override
  String get repeater_eraseFileSystem => 'Radera Filsystem';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatera återspelsfilsystemet';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'VARNING: Detta kommer att radera all data på repeatern. Detta kan inte ångras!';

  @override
  String get repeater_eraseSerialOnly =>
      'Rensa är endast tillgängligt via seriell konsol.';

  @override
  String repeater_commandSent(String command) {
    return 'Kommandot skickades: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Fel vid skickande av kommando: $error';
  }

  @override
  String get repeater_confirm => 'Bekräfta';

  @override
  String get repeater_settingsSaved =>
      'Inställningarna sparades framgångsrikt.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Fel vid sparande av inställningar: $error';
  }

  @override
  String get repeater_refreshBasicSettings =>
      'Återställ Grundläggande Inställningar';

  @override
  String get repeater_refreshRadioSettings => 'Återställ Radiosinställningar';

  @override
  String get repeater_refreshTxPower => 'Återställ TX-effekt';

  @override
  String get repeater_refreshLocationSettings =>
      'Uppdatera Lokationsinställningar';

  @override
  String get repeater_refreshPacketForwarding => 'Återställ Paketväxling';

  @override
  String get repeater_refreshGuestAccess => 'Återställ Gäståtkomst';

  @override
  String get repeater_refreshPrivacyMode => 'Återställ Sekretessläge';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Återställ Annonsinställningar';

  @override
  String repeater_refreshed(String label) {
    return '$label har uppdaterats';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Fel vid uppdatering av $label';
  }

  @override
  String get repeater_cliTitle => 'Återuppspelaren CLI';

  @override
  String get repeater_debugNextCommand => 'Felsök Nästa Kommando';

  @override
  String get repeater_commandHelp => 'Hjälp';

  @override
  String get repeater_clearHistory => 'Rensa Historik';

  @override
  String get repeater_noCommandsSent => 'Inga kommandon skickats ännu';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Skriv en kommando nedan eller använd snabba kommandon';

  @override
  String get repeater_enterCommandHint => 'Ange kommando...';

  @override
  String get repeater_previousCommand => 'Tidigare kommando';

  @override
  String get repeater_nextCommand => 'Nästa kommando';

  @override
  String get repeater_enterCommandFirst => 'Ange en kommando först';

  @override
  String get repeater_cliCommandFrameTitle => 'Kommandofönster';

  @override
  String repeater_cliCommandError(String error) {
    return 'Fel: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Hämta namn';

  @override
  String get repeater_cliQuickGetRadio => 'Få Radio';

  @override
  String get repeater_cliQuickGetTx => 'Hämta TX';

  @override
  String get repeater_cliQuickNeighbors => 'Grannar';

  @override
  String get repeater_cliQuickVersion => 'Version';

  @override
  String get repeater_cliQuickAdvertise => 'Annonsera';

  @override
  String get repeater_cliQuickClock => 'Klocka';

  @override
  String get repeater_cliQuickClockSync => 'Synkronisera klocka';

  @override
  String get repeater_cliQuickDiscovery => 'Upptäck grannar';

  @override
  String get repeater_cliHelpAdvert => 'Skickar ett annonspaket';

  @override
  String get repeater_cliHelpReboot =>
      'Startar om enheten. (notera, du får kanske \'Timeout\' vilket är normalt)';

  @override
  String get repeater_cliHelpClock => 'Visar aktuell tid per enhetens klocka.';

  @override
  String get repeater_cliHelpPassword =>
      'Ställer in ett nytt administratörslösenord för enheten.';

  @override
  String get repeater_cliHelpVersion =>
      'Visar enhetsversion och firmwarebyggnadsdatum.';

  @override
  String get repeater_cliHelpClearStats =>
      'Återställer olika statistikräknare till noll.';

  @override
  String get repeater_cliHelpSetAf => 'Ställer in lufttidsfaktor.';

  @override
  String get repeater_cliHelpSetTx =>
      'Ställer LoRa-sändningseffekten i dBm. (starta om för att tillämpa)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Aktiverar eller inaktiverar återuppspelarens roll för denna nod.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Rumserver) Om \'på\', så tillåts login med tomt lösenord, men kan inte Posta till rummet. (bara läsa).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Ställer in det maximala antalet hopp för inkommande översvämning (om >= max, skickas inte paketet).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Ställer Interferensgränsen (i dB). Standardvärdet är 14. Ställ in den på 0 för att inaktivera detektion av kanalinterferens.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Ställer in intervallet för att återställa Auto Gain-kontrollen. Ställ in till 0 för att inaktivera.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Aktiverar eller inaktiverar funktionen \'dubbla ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Ställer in tidsintervallen i minuter för att skicka ett lokalt (utan-hopp) annonseringspaket. Ställs till 0 för att inaktivera.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Ställer in tidsintervallen i timmar för att skicka ett flödesannonspaket. Ställ in på 0 för att inaktivera.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Ställer in/uppdaterar gästlösenordet. (för återvändare kan gästloggar skicka \"Get Stats\"-förfrågan)';

  @override
  String get repeater_cliHelpSetName => 'Ställer in annonstexterna namn.';

  @override
  String get repeater_cliHelpSetLat =>
      'Ställer in annonskartans latitud. (decimalgrader)';

  @override
  String get repeater_cliHelpSetLon =>
      'Ställer in annonskartans longitud (decimalgrader).';

  @override
  String get repeater_cliHelpSetRadio =>
      'Ställer helt nya radioparametrar och sparar dem i inställningar. Kräver en \"omstart\" för att tillämpa.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Ställer (experimentell) basvärde (måste vara > 1 för effekt) för att applicera en liten fördröjning på mottagna paket, baserat på signalstyrka/poäng. Ställ in på 0 för att inaktivera.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Ställer in en faktor som multipliceras med tid på luft för en översvämningsläge-paket och med ett slumpmässigt slot-system för att fördröja dess vidarebefordran (för att minska risken för kollisioner).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Samma som txdelay, men för att applicera en slumpmässig fördröjning vid vidarebefordran av direktlägespaket.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Aktivera/Inaktivera brygga.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Ställ in fördröjning innan paket åter sänder.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Välj om bron ska återända mottagna paket eller sända paket.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Ställ baudgränsen för rs232-bryggarna.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Ställ bro-hemlighet för espnow-broar.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Ställer in anpassad faktor för att justera rapporterad batterispänning (endast stödd på utvalda kort).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Ställer temporära radioparametrar för det angivna antalet minuter, vilket återgår till de ursprungliga radioparametrarna efteråt. (sparar inte i inställningar).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifierar ACL. Tar bort matchande post (genom pubkey-prefiks) om \"permissions\" är noll. Lägger till ny post om pubkey-hex är full längd och inte redan finns i ACL. Uppdaterar posten genom matchande pubkey-prefiks. Tillståndsbiten varierar per firmware-roll, men de låga 2 bitarna är: 0 (Gäst), 1 (endast läsa), 2 (läs- och skrivskydd), 3 (administratör).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Får brotyperna ingen, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart => 'Starta paketloggning till filsystem.';

  @override
  String get repeater_cliHelpLogStop => 'Stoppar paketloggning till filsystem.';

  @override
  String get repeater_cliHelpLogErase =>
      'Raderar pakets loggar från filsystemet.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Visar en lista över andra repeaternoder som hörts via noll-hop-annonser. Varje rad är id-prefix-hex:tidsstämpel:snr-g撮-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Tar bort det första matchande inlägget (genom pubkey-prefiks (hex)) från grannlistan.';

  @override
  String get repeater_cliHelpRegion =>
      '(Serien endast) Listar alla definierade regioner och aktuella översvämningsbehörigheter.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'MEDDELANDE: detta är ett specialkommando med flera kommandon. Varje efterföljande kommando är ett regionsnamn (indenterat med blanksteg för att indikera en hierarkisk relation, med minst ett blanksteg). Avslutas genom att skicka en tom rad/kommando.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Söker efter region med given namnprefiks (eller \"\" för det globala scopet). Svarar med \"-> regionnamn (föräldernamn) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Lägger till eller uppdaterar en regionsdefinition med det angivna namnet.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Tar bort en regionsdefinition med det angivna namnet. (måste matcha exakt och inte ha några barnregioner)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Ställer \'Flöde\'-behörighet för det angivna området. (\'\' för det globala/gamla scopet)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Tar bort \'F\'lood-behörigheten för det angivna området. (OBS: rekommenderas inte att använda detta i detta skede på den globala/gamla omfattningen!!).';

  @override
  String get repeater_cliHelpRegionHome =>
      'Svarar med den aktuella \'hem\'-regionen. (Notera att detta ännu inte har tillämpats, reserverat för framtida användning).';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Ställer in \'hemregionen\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Sparar regionlistan/kartan till lagring.';

  @override
  String get repeater_cliHelpGps =>
      'Visar GPS-status. Om GPS är avstängd svarar den endast med \"av\", annars svarar den med \"på\", status, fix, antal satelliter.';

  @override
  String get repeater_cliHelpGpsOnOff =>
      'Aktiverar/inaktiverar GPS-strömsättningen.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synkroniserar nätverks tid med GPS-klockan.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Ställer nodens position till GPS-koordinater och sparar inställningar.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Ger platsannonskonfigurationen för noden:\n- ingen: inkludera inte plats i annonser\n- dela: dela gps-plats (från SensorManager)\n- inställningar: annonsera platsen som sparats i inställningar';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Ställer in annonsplatskonfiguration.';

  @override
  String get repeater_commandsListTitle => 'Inställningslista';

  @override
  String get repeater_commandsListNote =>
      'OBS: för de olika \"set ...\" -kommandon finns det även ett \"get ...\" -kommando.';

  @override
  String get repeater_general => 'Allmänt';

  @override
  String get repeater_settingsCategory => 'Inställningar';

  @override
  String get repeater_bridge => 'Bro';

  @override
  String get repeater_logging => 'Logga';

  @override
  String get repeater_neighborsRepeaterOnly => 'Grannar (Endast återspelare)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Regionhantering (endast återuppspelare)';

  @override
  String get repeater_regionNote =>
      'Regionkommandon har införts för att hantera regiondefinitioner och behörigheter.';

  @override
  String get repeater_gpsManagement => 'GPS Hantering';

  @override
  String get repeater_gpsNote =>
      'GPS-kommando har introducerats för att hantera platsrelaterade ämnen.';

  @override
  String get telemetry_receivedData => 'Mottagen Telemetridata';

  @override
  String get telemetry_requestTimeout => 'Telemetryförfrågan gick ut.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Fel vid laddning av telemetri: $error';
  }

  @override
  String get telemetry_noData => 'Inga telemetridata tillgängliga.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batteri';

  @override
  String get telemetry_voltageLabel => 'Spänning';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU Temperatur';

  @override
  String get telemetry_temperatureLabel => 'Temperatur';

  @override
  String get telemetry_currentLabel => 'Aktuell';

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
  String get neighbors_receivedData => 'Mottagna grannars data';

  @override
  String get neighbors_requestTimedOut => 'Grannar begär tidsinställd utskick.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Fel vid inläsning av grannar: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Upprepar grannar';

  @override
  String get neighbors_noData => 'Inga grannuppgifter finns tillgängliga.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Okänd $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Hördes: $time sedan';
  }

  @override
  String get channelPath_title => 'Paketväg';

  @override
  String get channelPath_viewMap => 'Visa karta';

  @override
  String get channelPath_otherObservedPaths => 'Övriga observerade stigar';

  @override
  String get channelPath_repeaterHops => 'Återupptagningssteg';

  @override
  String get channelPath_noHopDetails =>
      'Detaljer för denna paket är inte angivna.';

  @override
  String get channelPath_messageDetails => 'Meddelandets detaljer';

  @override
  String get channelPath_senderLabel => 'Avsändare';

  @override
  String get channelPath_timeLabel => 'Tid';

  @override
  String get channelPath_repeatsLabel => 'Upprepa';

  @override
  String channelPath_pathLabel(int index) {
    return 'Sökväg $index';
  }

  @override
  String get channelPath_observedLabel => 'Observerat';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Observerad bana $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Ingen platsdata';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month kl. $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Okänt';

  @override
  String get channelPath_floodPath => 'Översvämning';

  @override
  String get channelPath_directPath => 'Direkt';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 av $total hopp';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed av $total hopp';
  }

  @override
  String get channelPath_mapTitle => 'Sökvägskarta';

  @override
  String get channelPath_noRepeaterLocations =>
      'Inga återupprepningsplatser finns tillgängliga för denna väg.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Sökväg $index (Primär)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Sökväg';

  @override
  String get channelPath_observedPathHeader => 'Observerad Sökväg';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Inga hoppdetaljer finns tillgängliga för detta paket.';

  @override
  String get channelPath_unknownRepeater => 'Okänt Upprepare';

  @override
  String get community_title => 'Gemenskap';

  @override
  String get community_create => 'Skapa Gemenskap';

  @override
  String get community_createDesc =>
      'Skapa en ny gemenskap och dela via QR-kod.';

  @override
  String get community_join => 'Gå med';

  @override
  String get community_joinTitle => 'Gå med i gemenskapen';

  @override
  String community_joinConfirmation(String name) {
    return 'Vill du gå med i communityn \"$name\"?';
  }

  @override
  String get community_scanQr => 'Skanna Gemenskapens QR';

  @override
  String get community_scanInstructions =>
      'Rikta kameran mot en QR-kod i communityn';

  @override
  String get community_showQr => 'Visa QR-kod';

  @override
  String get community_publicChannel => 'Föreningens Offentliga';

  @override
  String get community_hashtagChannel => 'Community Hashtag';

  @override
  String get community_name => 'Gemenskapens namn';

  @override
  String get community_enterName => 'Ange communities namn';

  @override
  String community_created(String name) {
    return 'Community \"$name\" har skapats';
  }

  @override
  String community_joined(String name) {
    return 'Medlem i communityn \"$name\"';
  }

  @override
  String get community_qrTitle => 'Dela Gemenskap';

  @override
  String community_qrInstructions(String name) {
    return 'Skanna denna QR-kod för att gå med i \"$name\"';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Community-hashtagkanaler kan endast nås av medlemmar i communityn';

  @override
  String get community_invalidQrCode => 'Ogiltig community QR-kod';

  @override
  String get community_alreadyMember => 'Är redan medlem';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Du är redan medlem av \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Lägg till Gemenskapskanal (Offentlig)';

  @override
  String get community_addPublicChannelHint =>
      'Lägg automatiskt till den offentliga kanalen för denna community';

  @override
  String get community_noCommunities => 'Inga gemenskaper har anslutats ännu';

  @override
  String get community_scanOrCreate =>
      'Skanna en QR-kod eller skapa en community för att komma igång';

  @override
  String get community_manageCommunities => 'Hantera Gemenskaper';

  @override
  String get community_delete => 'Lämna Gemenskap';

  @override
  String community_deleteConfirm(String name) {
    return 'Lämna \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Detta kommer också att radera $count kanal/kanaler och deras meddelanden.';
  }

  @override
  String community_deleted(String name) {
    return 'Lämnade community \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Regenerera hemlig kod';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenerera den hemliga nyckeln för \"$name\"? Alla medlemmar måste scanna den nya QR-koden för att fortsätta kommunicera.';
  }

  @override
  String get community_regenerate => 'Regenerera';

  @override
  String community_secretRegenerated(String name) {
    return 'Lösenord återskapad för \"$name\"';
  }

  @override
  String get community_updateSecret => 'Uppdatera hemlighet';

  @override
  String community_secretUpdated(String name) {
    return 'Hemlighet uppdaterad för \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Skanna den nya QR-koden för att uppdatera hemligheten för \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Lägg till Gemenskapens Hashtag';

  @override
  String get community_addHashtagChannelDesc =>
      'Lägg till en hashtag-kanal för denna community';

  @override
  String get community_selectCommunity => 'Välj Gemenskap';

  @override
  String get community_regularHashtag => 'Vanlig Hash Tag';

  @override
  String get community_regularHashtagDesc =>
      'Offentlig hashtag (alla kan gå med)';

  @override
  String get community_communityHashtag => 'Community Hashtag';

  @override
  String get community_communityHashtagDesc => 'Endast för medlemmar';

  @override
  String community_forCommunity(String name) {
    return 'För $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrera och sortera';

  @override
  String get listFilter_sortBy => 'Sortera efter';

  @override
  String get listFilter_latestMessages => 'Senaste meddelanden';

  @override
  String get listFilter_heardRecently => 'Hörts nyligen';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filteralternativ';

  @override
  String get listFilter_source => 'Källa';

  @override
  String get listFilter_saved => 'Sparade';

  @override
  String get listFilter_discovered => 'Upptäckta';

  @override
  String get listFilter_all => 'Alla';

  @override
  String get listFilter_favorites => 'Favoriter';

  @override
  String get listFilter_addToFavorites => 'Lägg till i favoriter';

  @override
  String get listFilter_removeFromFavorites => 'Ta bort från favoriter';

  @override
  String get listFilter_users => 'Användare';

  @override
  String get listFilter_repeaters => 'Upprepare';

  @override
  String get listFilter_roomServers => 'Rumservrar';

  @override
  String get listFilter_unreadOnly => 'Endast oinlästa';

  @override
  String get listFilter_newGroup => 'Ny grupp';

  @override
  String get pathTrace_you => 'Du';

  @override
  String get pathTrace_failed => 'Sökvägsföljning misslyckades.';

  @override
  String get pathTrace_notAvailable => 'Path trace ej tillgänglig.';

  @override
  String get pathTrace_refreshTooltip => 'Uppdatera Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'En eller flera av humlen saknar en plats!';

  @override
  String get pathTrace_clearTooltip => 'Rensa väg';

  @override
  String get losSelectStartEnd => 'Välj start- och slutnoder för LOS.';

  @override
  String losRunFailed(String error) {
    return 'Synlinjekontroll misslyckades: $error';
  }

  @override
  String get losClearAllPoints => 'Rensa alla punkter';

  @override
  String get losRunToViewElevationProfile => 'Kör LOS för att se höjdprofil';

  @override
  String get losMenuTitle => 'LOS-menyn';

  @override
  String get losMenuSubtitle =>
      'Tryck på noder eller tryck länge på kartan för anpassade punkter';

  @override
  String get losShowDisplayNodes => 'Visa displaynoder';

  @override
  String get losCustomPoints => 'Anpassade poäng';

  @override
  String losCustomPointLabel(int index) {
    return 'Anpassad $index';
  }

  @override
  String get losPointA => 'Punkt A';

  @override
  String get losPointB => 'Punkt B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenn A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenn B: $value $unit';
  }

  @override
  String get losRun => 'Kör LOS';

  @override
  String get losNoElevationData => 'Inga höjddata';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, rensa LOS, min clearance $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blockerad av $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: kollar...';

  @override
  String get losStatusNoData => 'LOS: inga data';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total rensa, $blocked blockerad, $unknown okänd';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Höjddata är inte tillgänglig för ett eller flera prover.';

  @override
  String get losErrorInvalidInput =>
      'Ogiltiga poäng/höjddata för LOS-beräkning.';

  @override
  String get losRenameCustomPoint => 'Byt namn på anpassad punkt';

  @override
  String get losPointName => 'Punktnamn';

  @override
  String get losShowPanelTooltip => 'Visa LOS-panelen';

  @override
  String get losHidePanelTooltip => 'Dölj LOS-panelen';

  @override
  String get losElevationAttribution => 'Höjddata: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radiohorisont';

  @override
  String get losLegendLosBeam => 'Siktlinje';

  @override
  String get losLegendTerrain => 'Terräng';

  @override
  String get losFrequencyLabel => 'Frekvens';

  @override
  String get losFrequencyInfoTooltip => 'Visa detaljer om beräkningen';

  @override
  String get losFrequencyDialogTitle => 'Beräkning av radiohorisonten';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Med start från k=$baselineK vid $baselineFreq MHz, justerar beräkningen k-faktorn för det aktuella $frequencyMHz MHz-bandet, som definierar den böjda radiohorisonten.';
  }

  @override
  String get contacts_pathTrace => 'Path Trace';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Vägspårning till repeater';

  @override
  String get contacts_repeaterPing => 'Ping-repeater';

  @override
  String get contacts_roomPathTrace => 'Vägspårning till rumserver';

  @override
  String get contacts_roomPing => 'Ping rumsserver';

  @override
  String get contacts_chatTraceRoute => 'Spåra rutt';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Spåra rutt till $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Urklipp är tomt.';

  @override
  String get contacts_invalidAdvertFormat => 'Ogiltiga kontaktuppgifter';

  @override
  String get contacts_contactImported => 'Kontakt har importerats.';

  @override
  String get contacts_contactImportFailed => 'Kontakt kunde inte importeras.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name finns redan bland dina kontakter.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Reklam med nollhopp';

  @override
  String get contacts_floodAdvert => 'Översvämningsannons';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopiera annons till urklipp';

  @override
  String get contacts_addContactFromClipboard =>
      'Lägg till kontakt från urklipp';

  @override
  String get contacts_ShareContact => 'Kopiera kontakt till Urklipp';

  @override
  String get contacts_ShareContactZeroHop => 'Dela kontakt via annons';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Skickat kontakt via annons.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Misslyckades med att skicka kontakt.';

  @override
  String get contacts_contactAdvertCopied => 'Annons kopierad till Urklipp.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopiering av annons till Urklipp misslyckades.';

  @override
  String get contacts_addContact => 'Lägg till kontakt';

  @override
  String get contacts_scanQrCode => 'Skanna kontakt-QR';

  @override
  String get contacts_scanQrCodeDesc =>
      'Skanna en kontakt-QR-kod från MeshCore-appen';

  @override
  String get contacts_enterIdHash => 'Ange kontakt manuellt';

  @override
  String get contacts_enterIdHashDesc =>
      'Klistra in en kontaktannons eller meshcore://-länk';

  @override
  String get contacts_advertHint => 'meshcore://... eller publik nyckel i hex';

  @override
  String get contacts_import => 'Importera';

  @override
  String get contacts_scanContactInstructions =>
      'Skanna en MeshCore-kontakt-QR-kod';

  @override
  String get notification_activityTitle => 'MeshCore Aktivitet';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'meddelanden',
      one: 'meddelande',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kanalmeddelanden',
      one: 'kanalmeddelande',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nya noder',
      one: 'ny nod',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Ny $contactType upptäckt';
  }

  @override
  String get notification_receivedNewMessage => 'Nytt meddelande mottaget';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportera repeater / rumsservrar till GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporterar repeater / roomserver med plats till GPX-fil.';

  @override
  String get settings_gpxExportContacts => 'Exportera följeslagare till GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporterar följeslagare med en plats till GPX-fil.';

  @override
  String get settings_gpxExportAll => 'Exportera alla kontakter till GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporterar alla kontakter med en plats till GPX-fil.';

  @override
  String get settings_gpxExportSuccess => 'Har exporterat GPX-fil med framgång';

  @override
  String get settings_gpxExportNoContacts => 'Inga kontakter att exportera.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Stöds inte på din enhet/operativsystem';

  @override
  String get settings_gpxExportError =>
      'Det uppstod ett fel när data exporterades.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Repeater- och rumsserverplatser';

  @override
  String get settings_gpxExportChat => 'Medhjälparplatser';

  @override
  String get settings_gpxExportAllContacts => 'Alla kontakters platser';

  @override
  String get settings_gpxExportShareText => 'Kartdata exporterad från MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax export av GPX-kartdata';

  @override
  String get snrIndicator_nearByRepeaters => 'Närliggande uppreparstationer';

  @override
  String get snrIndicator_lastSeen => 'Senast sedd';

  @override
  String get contactsSettings_title => 'Kontaktinställningar';

  @override
  String get contactsSettings_autoAddTitle => 'Automatisk upptäckt';

  @override
  String get contactsSettings_otherTitle =>
      'Andra inställningar relaterade till kontakt';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Lägg till användare automatiskt';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Tillåt kompanjonen att automatiskt lägga till upptäckta användare';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Lägg till upprepande enheter automatiskt';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Tillåt kompanjonen att automatiskt lägga till upptäckta repeater.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Lägg automatiskt till rumsservrar';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Tillåt kompanjonen att automatiskt lägga till upptäckta rumsservrar.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Lägg till sensorer automatiskt';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Tillåt kompanjonen att automatiskt lägga till upptäckta sensorer.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Skriv över äldst';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'När kontaktlistan är full ersätts den äldsta icke-favoriterade kontakten.';

  @override
  String get discoveredContacts_Title => 'Upptäckta kontakter';

  @override
  String get discoveredContacts_noMatching => 'Inga matchande kontakter';

  @override
  String get listFilter_searchHint => 'Sök...';

  @override
  String get discoveredContacts_searchHint => 'Sök uppfunna kontakter';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt tillagd';

  @override
  String get discoveredContacts_addContact => 'Lägg till kontakt';

  @override
  String get discoveredContacts_copyContact => 'Kopiera kontakt till urklipp';

  @override
  String get discoveredContacts_deleteContact => 'Ta bort kontakt';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Ta bort alla upptäckta kontakter';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Är du säker på att du vill ta bort alla upptäckta kontakter?';

  @override
  String get chat_sendCooldown =>
      'Vänligen vänta en stund innan du skickar igen.';

  @override
  String get chat_notConnected =>
      'Inte ansluten till en radio. Meddelandet skickades inte.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Gå direkt till det äldsta, obesvarade meddelandet';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'När du öppnar en chatt med oinlästa meddelanden, scrolla till det första oinlästa meddelandet istället för det senaste.';

  @override
  String get appSettings_languageHu => 'Ungerskt';

  @override
  String get appSettings_languageJa => 'Japanska';

  @override
  String get appSettings_languageKo => 'Koreanska';

  @override
  String get radioStats_screenTitle => 'Radiostation';

  @override
  String get radioStats_notConnected =>
      'Anslut till en enhet för att visa radiostatistik.';

  @override
  String get radioStats_firmwareTooOld =>
      'Radio statistik kräver kompatibel firmware version 8 eller senare.';

  @override
  String get radioStats_waiting => 'Väntar på data…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Bakgrundsnivå: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Senaste RSSI-värde: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Senaste SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX-tid (total): $seconds sekunder';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'RX-tid (total): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Ljudnivå (dBm) baserat på de senaste mätningarna.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Bakgrundsnivå: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Hämtar radiostatistik…';

  @override
  String get radioStats_settingsTile => 'Radiostation';

  @override
  String get radioStats_settingsSubtitle =>
      'Bakgrundsnivå, RSSI, SNR och tillgänglig tid';

  @override
  String get translation_title => 'Översättning';

  @override
  String get translation_enableTitle => 'Aktivera översättning';

  @override
  String get translation_enableSubtitle =>
      'Översätt inkommande meddelanden och möjliggör översättning före avsändning.';

  @override
  String get translation_composerTitle => 'Översätt innan du skickar';

  @override
  String get translation_composerSubtitle =>
      'Styr standardtillståndet för kompositorns översättningsikon.';

  @override
  String get translation_targetLanguage => 'Målmedvetet språk';

  @override
  String get translation_useAppLanguage => 'Använd appens språk';

  @override
  String get translation_downloadedModelLabel => 'Nedladdad modell';

  @override
  String get translation_presetModelLabel =>
      'Fördefinierat Hugging Face-modell';

  @override
  String get translation_manualUrlLabel => 'Manualens URL';

  @override
  String get translation_downloadModel => 'Ladda ner modellen';

  @override
  String get translation_downloading => 'Nedladdning...';

  @override
  String get translation_working => 'Arbeta...';

  @override
  String get translation_stop => 'Stopp';

  @override
  String get translation_mergingChunks =>
      'Slå samman de nedladdade delarna till en slutlig fil...';

  @override
  String get translation_downloadedModels => 'Nedladdade modeller';

  @override
  String get translation_deleteModel => 'Ta bort modell';

  @override
  String get translation_modelDownloaded =>
      'Översättningsmodellen har laddats ner.';

  @override
  String get translation_downloadStopped => 'Nedladdningen avbruten.';

  @override
  String translation_downloadFailed(String error) {
    return 'Nedladdning misslyckades: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Ange först en URL för en specifik modell.';

  @override
  String get scanner_linuxPairingShowPin => 'Visa PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Dölj PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth‑parnings‑PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Ange PIN för $deviceName (lämna tomt om ingen).';
  }

  @override
  String get translation_messageTranslation => 'Meddelandets översättning';

  @override
  String get translation_translateBeforeSending => 'Översätt innan du skickar';

  @override
  String get translation_composerEnabledHint =>
      'Meddelandena kommer att översättas innan de skickas.';

  @override
  String get translation_composerDisabledHint =>
      'Skicka meddelanden på det ursprungliga, stavade språket.';

  @override
  String translation_translateTo(String language) {
    return 'Översätt till $language';
  }

  @override
  String get translation_translationOptions => 'Översättningsalternativ';

  @override
  String get translation_systemLanguage => 'Språk för systemet';

  @override
  String get routing_title => 'Routning';

  @override
  String routing_route(String route) {
    return 'Sparad sökväg: $route';
  }

  @override
  String get routing_noRoute =>
      'ingen än — nästa meddelande skickas som översvämning och lär sig en';

  @override
  String get routing_auto => 'Automatisk';

  @override
  String get routing_autoSubtitle =>
      'Använd radions sparade sökväg. Rekommenderas.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder på: provar inlärda rutter först';

  @override
  String get routing_flood => 'Alltid översvämning';

  @override
  String get routing_floodSubtitle => 'Varje meddelande går till hela nätet';

  @override
  String get routing_custom => 'Anpassad sökväg';

  @override
  String get routing_customSubtitle => 'Välj repeatrarna själv';

  @override
  String get routing_forget => 'Återställ sökväg';

  @override
  String get routing_forgetDone =>
      'Sökvägen återställd. Nästa meddelande skickas som översvämning och lär sig en ny.';

  @override
  String get routing_pathfinder => 'Vad Pathfinder vet';

  @override
  String get routing_pathfinderSubtitle =>
      'Repeatrar som hör dig och dem, och inlärda rutter dit och tillbaka';

  @override
  String get path_direct => 'Direkt — inga repeatrar';

  @override
  String get path_directSubtitle =>
      'Bara när kontakten själv kan höra den här radion';

  @override
  String get chat_kindFlood => 'översvämning';

  @override
  String get chat_kindDirect => 'direkt';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hopp',
      one: 'hopp',
    );
    return 'rutt ($count $_temp0)';
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
  String get chat_statusQueued => 'I kö';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Ingen repeater hörde dig. Försöker igen när en är inom räckhåll.';

  @override
  String chat_narrowHashNotice(String name) {
    return '${name}s radio skickar korta repeaterkoder (1 byte). Pathfinder kan inte lära sig rutter till dem förrän deras radio använder 2-byte-koder.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Skickar · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Försöker igen · $kind · försök $attempt av $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Levererat · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Levererat vid försök $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Levererat sent · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Levererat · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'försök',
      one: 'försök',
    );
    return 'Misslyckades efter $attempts $_temp0 · tryck för att skicka igen';
  }

  @override
  String get chat_statusFailedShort =>
      'Misslyckades · tryck för att skicka igen';

  @override
  String get chat_resendingByFlood => 'Skickar igen som översvämning';

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
  String get settings_pathGraph => 'Pathfinder (experimentell)';

  @override
  String get settings_pathGraphSubtitle =>
      'Lär sig rutter från allt radion hör och provar de bästa först när du skickar ett DM. En bärnstensfärgad sökvägsikon markerar ett meddelande som skickats via en Pathfinder-rutt.';

  @override
  String get map_routeAndTrace => 'Rutt och spårning';

  @override
  String get map_pathfinderTrace => 'Spåra dit och tillbaka';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Dit via Pathfinders bästa rutt, tillbaka via dess bästa returrutt';

  @override
  String get map_routeBackMirrored =>
      'Ingen returrutt känd än — tillbaka samma väg';

  @override
  String get map_traceHelpTitle => 'Knappar för spårning';

  @override
  String get map_traceHelpCustom => 'Skriv eller välj repeatrarna själv.';

  @override
  String get map_traceHelpRun =>
      'Skickar en spårning längs repeatrarna du tryckt på, åt ett håll.';

  @override
  String get map_traceHelpThereAndBack => 'Dit och tillbaka';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Skickar spårningen dit och sedan tillbaka över samma repeatrar i omvänd ordning.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder väljer den bästa rutten genom de två senaste repeatrarna du tryckt på, och den bästa rutten tillbaka till dig. Resultatet lär Pathfinder vilka länkar som verkligen fungerar. Kräver att du tryckt på två repeatrar.';

  @override
  String get map_traceHelpRemoveLast =>
      'Tar bort den sista repeatern från sökvägen.';

  @override
  String get map_traceHelpCancel =>
      'Slutar bygga spårningen. Visas innan du tryckt på någon repeater.';

  @override
  String get chat_resendingByRoute => 'Skickar igen via din angivna rutt';

  @override
  String get room_mute => 'Tysta rummet';

  @override
  String get room_unmute => 'Slå på ljud för rummet';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'medlem';

  @override
  String get room_roleReadOnly => 'skrivskyddad';

  @override
  String room_clockOff(int minutes) {
    return 'Rummets klocka avviker cirka $minutes min — meddelandetider kan vara fel';
  }

  @override
  String get room_fixClock => 'Ställ klockan';

  @override
  String get room_clockSyncSent => 'Klocksynk skickad till rummet';

  @override
  String get room_readOnlyNotice =>
      'Skrivskyddat: rummet accepterade inte ditt lösenord, dina meddelanden når inte övriga medlemmar.';

  @override
  String get room_postAnnouncement => 'Publicera meddelande';

  @override
  String get room_postAnnouncementSubtitle =>
      'Skicka ett meddelande från själva rummet till alla medlemmar';

  @override
  String get room_announcementSent => 'Meddelandet publicerat';

  @override
  String get room_announcementFailed =>
      'Det gick inte att publicera meddelandet';

  @override
  String get room_users => 'Rummets användare';

  @override
  String get room_usersSubtitle => 'Se admins och ange roller';

  @override
  String get room_usersAdminsNote =>
      'Rummet listar bara sina admins. Medlemmar med rumslösenordet visas inte.';

  @override
  String get room_usersLoadFailed => 'Kunde inte läsa in adminlistan';

  @override
  String get room_setUserRole => 'Ange roll';

  @override
  String get room_removeAccess => 'Ta bort åtkomst';

  @override
  String get room_removeOnlyUnknown =>
      'Den här användaren finns inte bland dina kontakter — den kan bara tas bort, inte ändras.';

  @override
  String get room_roleUpdated => 'Roll uppdaterad';

  @override
  String get room_roleUpdateFailed => 'Det gick inte att ändra rollen';

  @override
  String get room_postsStored => 'Lagrade inlägg';

  @override
  String get room_postsDelivered => 'Levererade inlägg';

  @override
  String get room_reloadPosts => 'Läs in senaste inläggen igen';

  @override
  String get room_reloadPostsExplain =>
      'Ber rummet skicka sina senaste inlägg igen (det sparar upp till 32). Du ombeds ange rummets lösenord. Befintliga meddelanden behålls.';

  @override
  String get room_reloadFailed => 'Kunde inte återställa rummet på radion';

  @override
  String get companionCli_title => 'Kommandorad';

  @override
  String get companionCli_settingsSubtitle =>
      'Skriv textkommandon till den här radion';

  @override
  String get companionCli_rebooting => 'Startar om radion…';

  @override
  String get companionCli_cancelled => 'Avbrutet';

  @override
  String get companionCli_poweringOff => 'Stänger av radion…';

  @override
  String get companionCli_noReply => 'Inget svar från radion. Försök igen.';

  @override
  String get companionCli_powerOffTitle => 'Stänga av radion?';

  @override
  String get companionCli_powerOffBody =>
      'Den förblir avstängd tills du trycker på dess knapp eller ansluter den till ström.';

  @override
  String get companionCli_powerOff => 'Stäng av';

  @override
  String get companionCli_quickBoard => 'Kort';

  @override
  String get companionCli_quickWifiStatus => 'Wifi-status';

  @override
  String get companionCli_quickWifiAddress => 'Wifi-adress';

  @override
  String get companionCli_helpBoard => 'Visar kortets tillverkare och modell.';

  @override
  String get companionCli_helpReboot => 'Startar om radion.';

  @override
  String get companionCli_helpPowerOff => 'Stänger av radion.';

  @override
  String get companionCli_helpSetPin =>
      'Ställer in PIN för Bluetooth-parkoppling. Gäller efter en omstart.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Ställer in hur många timmar som läggs till UTC för klockan på radions egen skärm (-12 till +14).';

  @override
  String get companionCli_helpSetTx =>
      'Ställer in sändeffekten i dBm. Gäller direkt.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Ställer in störningströskeln i dB. 0 stänger av störningsdetektering.';

  @override
  String get companionCli_helpSetCad =>
      'Lyssnar efter andra radioapparater innan den sänder (kanalaktivitetsdetektering).';

  @override
  String get companionCli_helpSetRxGain =>
      'Högre mottagarförstärkning, på radioapparater med SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Byte per repeater i en rutt: 0 = 1 byte, 1 = 2 byte, 2 = 3 byte.';

  @override
  String get companionCli_helpWifiStatus =>
      'Visar om radion är ansluten till wifinätet.';

  @override
  String get companionCli_helpWifiIp => 'Visar radions adress på wifinätet.';

  @override
  String get companionCli_helpWifiSsid =>
      'Ställer in wifinätets namn. Gäller efter en omstart.';

  @override
  String get companionCli_helpWifiPwd =>
      'Ställer in wifilösenordet. Gäller efter en omstart.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Slår på wifi (1) eller av (0). Gäller efter en omstart.';

  @override
  String get companionCli_helpWifiClear =>
      'Glömmer wifinätet. Gäller efter en omstart.';

  @override
  String get companionCli_remoteNoReply =>
      'Inget svar. Den andra radion behöver firmware 1.18 eller nyare och måste tillåta dig att använda dess kommandorad.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Skickat. En radio svarar inte på omstart eller avstängning.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name försökte använda din radios kommandorad: ”$command”. Det tilläts inte.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Försökte använda din radios kommandorad: ”$command”. Det tilläts inte.';
  }

  @override
  String get contact_remoteCli => 'Tillåt fjärrkommandorad';

  @override
  String get contact_remoteCliSubtitle =>
      'Låter den här kontakten köra kommandon på din radio';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Låta $name styra din radio?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name kommer att kunna ändra din radios inställningar, läsa ditt wifilösenord, byta namn på din radio och starta om eller stänga av den. Tillåt bara någon du litar helt på.';
  }

  @override
  String get contact_remoteCliAllow => 'Tillåt';

  @override
  String get connection_secondApp =>
      'En annan app är ansluten till den här radion. Meddelanden och inställningar kan blandas ihop. Stäng den andra appen.';

  @override
  String get wifi_title => 'Wifi';

  @override
  String get wifi_settingsSubtitle => 'Nätverk, lösenord och anslutning';

  @override
  String get wifi_use => 'Använd wifi';

  @override
  String get wifi_networkName => 'Nätverksnamn';

  @override
  String get wifi_password => 'Lösenord';

  @override
  String get wifi_passwordUnchanged => 'Oförändrat';

  @override
  String get wifi_showPassword => 'Visa lösenord';

  @override
  String get wifi_nameMissing => 'Ange nätverksnamnet';

  @override
  String get wifi_nameTooLong => 'Nätverksnamnet är för långt (högst 32 byte)';

  @override
  String get wifi_passwordTooLong => 'Lösenordet är för långt (högst 63 byte)';

  @override
  String get wifi_savedRestart =>
      'Sparat. Wifi-ändringar gäller efter att radion startats om.';

  @override
  String get wifi_forget => 'Glöm nätverk';

  @override
  String get wifi_forgetConfirm =>
      'Glömma det här wifinätet? Radion slutar använda wifi efter omstarten.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Radion godtog inte det: $reply';
  }

  @override
  String get wifi_noReply => 'Inget svar från radion. Försök igen.';

  @override
  String get wifi_restartTitle => 'Starta om radion?';

  @override
  String get wifi_later => 'Senare';

  @override
  String get wifi_loadFailed =>
      'Kunde inte läsa wifi-inställningarna från radion.';

  @override
  String wifi_connectedTo(String address) {
    return 'Ansluten · $address';
  }

  @override
  String get wifi_notConnected => 'Inte ansluten till wifi';

  @override
  String wifi_portNote(int port) {
    return 'Appar i samma nätverk kan ansluta på port $port';
  }

  @override
  String get wifi_connectOverWifi => 'Anslut via wifi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax kopplar från den här radion och öppnar TCP-skärmen med $address, port $port ifyllt. Tryck på Anslut där.';
  }

  @override
  String get wifi_noteRestart =>
      'Ändringar gäller efter att radion startats om.';

  @override
  String get wifi_noteSecurity =>
      'Alla i ditt wifinätverk kan ansluta till radion på port 5000. Det finns inget lösenord för det.';

  @override
  String get wifi_noteBattery =>
      'Wifi håller radion vaken, så batteriet tar slut fortare.';

  @override
  String get wifi_noteWrongPassword =>
      'Om lösenordet är fel fortsätter radion att försöka med några sekunders mellanrum. Bluetooth fungerar fortfarande.';

  @override
  String get room_selfDemoteWarning =>
      'Du ändrar din egen åtkomst. Om du släpper din adminroll kan bara rummets egen konsol ge tillbaka den.';

  @override
  String get scanner_offlineMaps => 'Offlinekartor';

  @override
  String get appSettings_offlineMaps => 'Offlinekartor';

  @override
  String get appSettings_offlineMapsNone => 'Inga nedladdade';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regioner',
      one: '1 region',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sjökortsområden',
      one: '1 sjökortsområde',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count uppdateringar tillgängliga',
      one: '1 uppdatering tillgänglig',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Ladda bara ner kartor via wifi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Kartnedladdningar väntar på en wifi-anslutning';

  @override
  String get offlineMaps_title => 'Offlinekartor';

  @override
  String get offlineMaps_tabMaps => 'Kartor';

  @override
  String get offlineMaps_tabCharts => 'Sjökort';

  @override
  String get offlineMaps_chartsNotice => 'Inte för navigering · Varför?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Förslag · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Sjökortsområden per kust';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count områden',
      one: '1 område',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '$count nedladdade';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '$count valda';
  }

  @override
  String get offlineMaps_selectAll => 'Välj alla';

  @override
  String get offlineMaps_clearSelection => 'Rensa';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Även i $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Inte tillgängligt än';

  @override
  String get offlineMaps_chartsHint =>
      'NOAA-sjökort väljs per kust, på fliken Sjökort.';

  @override
  String offlineMaps_chartsName(String area) {
    return 'NOAA-sjökort $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count områden',
      one: '1 område',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Nedladdade';

  @override
  String get offlineMaps_refresh => 'Sök efter nya kartor';

  @override
  String get offlineMaps_loading => 'Läser in tillgängliga kartor…';

  @override
  String get offlineMaps_serverError => 'Kan inte nå kartservern';

  @override
  String get offlineMaps_unavailable => 'Inga kartor tillgängliga än';

  @override
  String get offlineMaps_unavailableHint => 'Kolla igen senare.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Inga NOAA-sjökort tillgängliga än';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Visar listan från $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Uppdatera MeshTrax för att få de senaste kartorna.';

  @override
  String get offlineMaps_world => 'Världen';

  @override
  String get offlineMaps_suggested => 'Förslag';

  @override
  String get offlineMaps_regions => 'Regioner';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regioner i $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count inuti';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size offlinekartor på den här enheten';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Uppdateringar ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Uppdatera alla $size';
  }

  @override
  String get offlineMaps_downloading => 'Laddar ner';

  @override
  String get offlineMaps_update => 'Uppdatera';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Nedladdad $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Uppdatering tillgänglig';

  @override
  String get offlineMaps_otherFiles => 'Andra kartfiler';

  @override
  String get offlineMaps_emptyTitle => 'Inga offlinekartor än';

  @override
  String get offlineMaps_emptyBody =>
      'Ladda ner en region för att använda kartan utan anslutning.';

  @override
  String get offlineMaps_findMaps => 'Hitta kartor';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Ta bort $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Det frigör $size. Du kan ladda ner den igen senare.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name borttagen';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done av $total';
  }

  @override
  String get offlineMaps_kindMap => 'Karta';

  @override
  String get offlineMaps_kindMapDetail =>
      'OpenStreetMap: gator, leder, platser';

  @override
  String get offlineMaps_kindContours => 'Höjdkurvor';

  @override
  String get offlineMaps_kindContoursDetail => 'Linjer som visar höjd';

  @override
  String get offlineMaps_kindUsgs => 'USGS-topokarta';

  @override
  String get offlineMaps_kindUsgsDetail => 'Leder, bäckar, reservat';

  @override
  String get offlineMaps_kindTerrain => 'Terrängskuggning';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Kullar och berg, skuggade under kartan';

  @override
  String get offlineMaps_kindCharts => 'NOAA-sjökort';

  @override
  String get offlineMaps_usOnly => 'Endast USA';

  @override
  String offlineMaps_download(String size) {
    return 'Ladda ner $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Ladda ner';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Stor nedladdning ($size). Använd wifi och låt enheten laddas under tiden.';
  }

  @override
  String get offlineMaps_waiting => 'Väntar…';

  @override
  String get offlineMaps_checking => 'Kontrollerar nedladdningen…';

  @override
  String get offlineMaps_retrying => 'Försöker igen…';

  @override
  String offlineMaps_failed(String error) {
    return 'Nedladdningen misslyckades: $error';
  }

  @override
  String get offlineMaps_pause => 'Pausa';

  @override
  String get offlineMaps_resume => 'Återuppta';

  @override
  String get offlineMaps_deleteRegion => 'Ta bort region';

  @override
  String get offlineMaps_notInCatalogue =>
      'Inte tillgängligt för den här regionen';

  @override
  String get offlineMaps_notificationRunning => 'Laddar ner karta';

  @override
  String get offlineMaps_notificationPaused => 'Kartnedladdning pausad';

  @override
  String get offlineMaps_notificationFailed => 'Kartnedladdning misslyckades';

  @override
  String get offlineMaps_clearTileCache => 'Rensa cachade onlinekartrutor';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Ta bort onlinekartrutorna som sparats medan du tittat på kartan? Nedladdade kartor finns kvar.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Cachade onlinekartrutor borttagna';

  @override
  String get map_notForNavigation => 'Inte för navigering';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax ritar de här sjökorten från NOAA:s sjökortsdata för att hjälpa dig se vattnet runt dina radioapparater och planera. De är inte officiella sjökort. Navigera inte efter dem.';

  @override
  String get map_chartsNoticeWhy => 'Varför:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'De blir inaktuella. NOAA rättar sina sjökort hela tiden; ett nedladdat sjökort förblir som det är tills du uppdaterar det i Offlinekartor.';

  @override
  String get map_chartsNoticeLeftOut =>
      'De utelämnar saker. Många sjökortssymboler, fyrsektorer och anteckningar ritas inte, och vissa etiketter syns först när du zoomar in.';

  @override
  String get map_chartsNoticePositions =>
      'Positioner kan vara fel eller gamla. GPS kan visa fel med 10 m (30 ft) eller mer, och en nod finns bara där den senast rapporterade.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax är ingen certifierad sjökortsplotter.';

  @override
  String get map_chartsNoticeUse =>
      'Använd för navigering officiella, aktuella NOAA-sjökort (på papper, eller NOAA-ENC i en certifierad sjökortsplotter) med de senaste Underrättelserna för sjöfarande.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail => 'Ladda ner en region för fler detaljer';

  @override
  String get map_zoomInForOfflineMap => 'Zooma in för att se din offlinekarta';

  @override
  String get map_noCharts => 'Inga sjökort här';

  @override
  String get map_myLocation => 'Min plats';

  @override
  String get map_zoomIn => 'Zooma in';

  @override
  String get map_zoomOut => 'Zooma ut';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS på';

  @override
  String get gps_off => 'GPS av';

  @override
  String get gps_onHint => 'Radion uppdaterar sin position från GPS:en.';

  @override
  String get gps_offHint =>
      'Av sparar radions batteri. När den slås på kan det ta några minuter att hitta din position.';

  @override
  String get gps_asking => 'Frågar radion...';

  @override
  String get gps_noPosition =>
      'Ingen position än. Utomhus kan den första ta några minuter.';

  @override
  String get gps_position => 'Position';

  @override
  String get gps_altitude => 'Höjd';

  @override
  String gps_readAgo(String ago) {
    return 'Läst från radion för $ago sedan';
  }

  @override
  String get gps_turnOnTitle => 'Slå på GPS?';

  @override
  String get gps_turnOnBody =>
      'Radions GPS är avstängd. När den slås på kan det ta några minuter att hitta din position.';

  @override
  String get gps_turnOn => 'Slå på';

  @override
  String get gps_notNow => 'Inte nu';

  @override
  String get map_zoomInForCharts => 'Zooma in för att se dina sjökort';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Ladda ner $region · $size';
  }

  @override
  String get mapLayers_title => 'Kartlager';

  @override
  String get mapLayers_mapType => 'Karttyp';

  @override
  String get mapLayers_standard => 'Standard';

  @override
  String get mapLayers_usgs => 'USGS-topo';

  @override
  String get mapLayers_charts => 'Sjökort';

  @override
  String get mapLayers_notDownloaded => 'Inte nedladdad';

  @override
  String get mapLayers_offlineOnly => 'Endast offline';

  @override
  String get mapLayers_details => 'Kartdetaljer';

  @override
  String get mapLayers_contours => 'Höjdkurvor';

  @override
  String get mapLayers_hillShading => 'Terrängskuggning';

  @override
  String get mapLayers_dark => 'Mörk karta';

  @override
  String get mapLayers_downloadedAreas => 'Nedladdade områden';

  @override
  String get mapLayers_nodes => 'Noder';

  @override
  String get mapLayers_pins => 'Nålar';

  @override
  String get mapLayers_guessed => 'Gissade';

  @override
  String get mapLayers_moreFilters => 'Fler filter';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Senast sedd, nyckelprefix, överlapp';

  @override
  String get map_legend => 'Teckenförklaring';

  @override
  String get scanner_map => 'Karta';

  @override
  String get structured_openMap => 'Öppna karta';

  @override
  String get structured_addToCalendar => 'Lägg till i kalendern';

  @override
  String get structured_details => 'Detaljer';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Evenemang';

  @override
  String get structured_notice => 'Notis';

  @override
  String get structured_allDay => 'Heldag';

  @override
  String get structured_calendarFailed => 'Kunde inte öppna kalendern';

  @override
  String get structured_today => 'I dag';

  @override
  String get structured_tomorrow => 'I morgon';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Om $count dagar',
      one: 'Om 1 dag',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Passerat';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Dag $day av $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagar',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Slutdatum';

  @override
  String get dialog_eventSameDay => 'Samma dag';

  @override
  String get structured_map => 'Karta';

  @override
  String get structured_navigate => 'Navigera';

  @override
  String get structured_channel => 'Kanal';

  @override
  String get structured_contact => 'Kontakt';

  @override
  String get structured_room => 'Rum';

  @override
  String get structured_repeater => 'Repeater';

  @override
  String get structured_sensor => 'Sensor';

  @override
  String get structured_joinChannel => 'Gå med i kanalen';

  @override
  String get structured_addContact => 'Lägg till kontakt';

  @override
  String get structured_addRoom => 'Lägg till rum';

  @override
  String get structured_addRepeater => 'Lägg till repeater';

  @override
  String get structured_addSensor => 'Lägg till sensor';

  @override
  String get structured_open => 'Öppna';

  @override
  String get structured_added => 'Tillagd';

  @override
  String get tray_add => 'Lägg till';

  @override
  String get tray_myLocation => 'Min plats';

  @override
  String get tray_pointOnMap => 'Punkt på kartan';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Evenemang';

  @override
  String get tray_notice => 'Notis';

  @override
  String get tray_noRadioPosition =>
      'Din radio har ingen position än. Välj en på kartan.';

  @override
  String get dialog_insert => 'Infoga';

  @override
  String get dialog_eventTitle => 'Titel';

  @override
  String get dialog_eventDate => 'Datum';

  @override
  String get dialog_eventStart => 'Början';

  @override
  String get dialog_eventEnd => 'Slut';

  @override
  String get dialog_eventNoEnd => 'Ingen sluttid';

  @override
  String get dialog_eventPlace => 'Plats (valfritt)';

  @override
  String get dialog_pickOnMap => 'Välj på kartan';

  @override
  String get dialog_sosTitle => 'Skicka SOS';

  @override
  String get dialog_sosText => 'Vad har hänt?';

  @override
  String get dialog_noticeTitle => 'Notis';

  @override
  String get dialog_noticeText => 'Vad ska alla veta?';

  @override
  String get dialog_labelTitle => 'Punkt på kartan';

  @override
  String get dialog_note => 'Anteckning (valfritt)';

  @override
  String get paste_convertLocation =>
      'Ser ut som en kartlänk. Konvertera till en plats?';

  @override
  String get paste_convertEvent =>
      'Ser ut som en delad kalenderhändelse. Konvertera till ett evenemang?';

  @override
  String get paste_convert => 'Konvertera';

  @override
  String get paste_resolving => 'Slår upp länken…';

  @override
  String get paste_resolveFailed => 'Kunde inte slå upp länken';

  @override
  String get pinned_dismiss => 'Stäng';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Gå med i kanalen $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Du är redan med i $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Gick med i $name';
  }

  @override
  String get map_pickPositionHint =>
      'Tryck på kartan för att välja en position';

  @override
  String get map_legendMesh => 'Mesh';

  @override
  String get chartLegend_title => 'Sjökortssymboler';

  @override
  String get chartLegend_sectionBuoys => 'Bojar och båkar';

  @override
  String get chartLegend_sectionLights => 'Fyrar';

  @override
  String get chartLegend_sectionHazards => 'Faror';

  @override
  String get chartLegend_sectionTides => 'Tidvatten och strömmar';

  @override
  String get chartLegend_sectionDepths => 'Djup och botten';

  @override
  String get chartLegend_sectionAreas => 'Områden, leder och linjer';

  @override
  String get chartLegend_sectionLandmarks => 'Landmärken';

  @override
  String get chartLegend_sectionAbbreviations => 'Förkortningar';

  @override
  String get chartLegend_chartNo1 => 'Alla sjökortssymboler: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Grön cylindrisk boj';

  @override
  String get chartLegend_portBuoyHint =>
      'Håll den till vänster när du kommer in från havet';

  @override
  String get chartLegend_starboardBuoy => 'Röd konisk boj';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Håll den till höger på väg in: rött ska vara till höger när du återvänder';

  @override
  String get chartLegend_junctionBuoy => 'Boj med band';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Där farleden delar sig: behandla den som färgen på det översta bandet';

  @override
  String get chartLegend_safeWaterBuoy => 'Rödvita ränder';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Säkert vatten runt om, ofta vid en farledsinfart';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Svarta och röda band';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'En liten fara med säkert vatten runt om: håll avstånd';

  @override
  String get chartLegend_specialBuoy => 'Gul boj';

  @override
  String get chartLegend_specialBuoyHint =>
      'Specialmärke, inte för navigering: ankarplats, kabel, forskning';

  @override
  String get chartLegend_cardinalBuoy => 'Svart och gul';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Kardinalmärke: passera på den sida det är uppkallat efter (ovanligt i USA)';

  @override
  String get chartLegend_mooringBuoy => 'Förtöjningsboj';

  @override
  String get chartLegend_portBeacon => 'Grön fyrkantig båk';

  @override
  String get chartLegend_portBeaconHint =>
      'Som en grön boj: håll den till vänster på väg in';

  @override
  String get chartLegend_starboardBeacon => 'Röd trekantig båk';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Som en röd boj: håll den till höger på väg in';

  @override
  String get chartLegend_otherBeacon => 'Rombformad båk';

  @override
  String get chartLegend_otherBeaconHint =>
      'Information eller varning, inte en sida av farleden';

  @override
  String get chartLegend_beaconTower => 'Fyrtorn eller båkkonstruktion';

  @override
  String get chartLegend_topmark => 'Toppmärke';

  @override
  String get chartLegend_topmarkHint =>
      'Formen överst på ett märke kompletterar dess betydelse';

  @override
  String get chartLegend_light => 'Fyr';

  @override
  String get chartLegend_lightHint =>
      'Den magentafärgade flamman markerar en fyr; etiketten visar hur den blinkar';

  @override
  String get chartLegend_lightExample => 'Grönt blixtljus, var 4:e sekund';

  @override
  String get chartLegend_lightExampleHint =>
      'En fyrs etikett: karaktär, färg, sedan period';

  @override
  String get chartLegend_lightFixed => 'Fast fyr';

  @override
  String get chartLegend_lightFixedHint => 'Ett stadigt ljus';

  @override
  String get chartLegend_lightFlashing => 'Blixt';

  @override
  String get chartLegend_lightFlashingHint =>
      'Korta blixtar, längre mörker emellan';

  @override
  String get chartLegend_lightGroup => 'Gruppblixt';

  @override
  String get chartLegend_lightGroupHint =>
      'Blixtar i grupper, här 2, sedan mörkt';

  @override
  String get chartLegend_lightComposite => 'Sammansatt grupp';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 blixtar, sedan 1: markerar att farleden delar sig';

  @override
  String get chartLegend_lightQuick => 'Snabblixt';

  @override
  String get chartLegend_lightQuickHint => 'Ungefär en blixt per sekund';

  @override
  String get chartLegend_lightIsophase => 'Isofas';

  @override
  String get chartLegend_lightIsophaseHint => 'Lika långt ljus som mörker';

  @override
  String get chartLegend_lightOcculting => 'Intermittent';

  @override
  String get chartLegend_lightOccultingHint => 'Tänd längre än släckt';

  @override
  String get chartLegend_lightMorse => 'Morsekod A';

  @override
  String get chartLegend_lightMorseHint => 'Kort, lång: säkert vatten';

  @override
  String get chartLegend_lightAlternating => 'Alternerande';

  @override
  String get chartLegend_lightAlternatingHint => 'Byter färg';

  @override
  String get chartLegend_lightColours => 'Vit, röd, grön, gul';

  @override
  String get chartLegend_lightPeriod => 'Period';

  @override
  String get chartLegend_lightPeriodHint => 'Sekunder för en hel cykel';

  @override
  String get chartLegend_rock => 'Sten under vatten';

  @override
  String get chartLegend_rockHint => 'Alltid täckt, men kan ligga grunt';

  @override
  String get chartLegend_rockAwash => 'Sten i vattenytan';

  @override
  String get chartLegend_rockAwashHint => 'Nära ytan vid lågvatten';

  @override
  String get chartLegend_rockCovers => 'Torrfallande sten';

  @override
  String get chartLegend_rockCoversHint =>
      'Syns vid lågvatten, täckt vid högvatten';

  @override
  String get chartLegend_wreckDangerous => 'Farligt vrak';

  @override
  String get chartLegend_wreckDangerousHint => 'Så grunt att man kan gå på det';

  @override
  String get chartLegend_wreck => 'Vrak';

  @override
  String get chartLegend_wreckHint =>
      'Tillräckligt djupt för båtar på ytan; ankra inte';

  @override
  String get chartLegend_wreckShowing => 'Synligt vrak';

  @override
  String get chartLegend_wreckShowingHint => 'En del syns ovanför vattnet';

  @override
  String get chartLegend_obstruction => 'Hinder';

  @override
  String get chartLegend_obstructionHint =>
      'Något på botten; djupet anges när det är känt';

  @override
  String get chartLegend_foulGround => 'Oren botten';

  @override
  String get chartLegend_foulGroundHint =>
      'Säkert att passera över, men ankra eller tråla inte';

  @override
  String get chartLegend_hazardArea => 'Gräns för ett farligt område';

  @override
  String get chartLegend_hazardAreaHint => 'Stenar, vrak eller hinder innanför';

  @override
  String get chartLegend_pile => 'Påle eller stolpe';

  @override
  String get chartLegend_floodStream => 'Flodström';

  @override
  String get chartLegend_floodStreamHint => 'Tidvattenström när vattnet stiger';

  @override
  String get chartLegend_ebbStream => 'Ebbström';

  @override
  String get chartLegend_ebbStreamHint => 'Tidvattenström när vattnet sjunker';

  @override
  String get chartLegend_current => 'Ström';

  @override
  String get chartLegend_currentHint =>
      'Flyter åt samma håll oavsett tidvatten';

  @override
  String get chartLegend_rips => 'Strömbrytningar eller virvlar';

  @override
  String get chartLegend_ripsHint => 'Oroligt, virvlande vatten';

  @override
  String get chartLegend_breakers => 'Bränningar';

  @override
  String get chartLegend_breakersHint => 'Vågor som bryts över grund';

  @override
  String get chartLegend_sounding => 'Djupsiffra';

  @override
  String get chartLegend_soundingHint =>
      'Djup vid ett genomsnittligt lågvatten';

  @override
  String get chartLegend_depthContour => 'Djupkurva';

  @override
  String get chartLegend_depthContourHint => 'Etiketten anger djupet';

  @override
  String get chartLegend_drying => 'Torrfaller vid lågvatten';

  @override
  String get chartLegend_dredged => 'Muddrad ränna';

  @override
  String get chartLegend_dredgedHint => 'Hålls på angivet djup';

  @override
  String get chartLegend_swept => 'Ramat område';

  @override
  String get chartLegend_sweptHint =>
      'Kontrollerat fritt ned till angivet djup';

  @override
  String get chartLegend_unsurveyed => 'Ej sjömätt';

  @override
  String get chartLegend_unsurveyedHint => 'Inga djup uppmätta';

  @override
  String get chartLegend_weed => 'Kelp eller tång';

  @override
  String get chartLegend_restricted => 'Begränsat område';

  @override
  String get chartLegend_restrictedHint =>
      'Begränsat tillträde; strecken pekar inåt';

  @override
  String get chartLegend_regulatedLimit => 'Gräns för reglerat område';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Ankarplats, kabelområde, skjutområde med mera: se etiketten';

  @override
  String get chartLegend_greyLimit =>
      'Dumpningsområde, fiskeområde eller odling';

  @override
  String get chartLegend_anchorage => 'Ankarplats';

  @override
  String get chartLegend_anchorBerth => 'Enskild ankarplats';

  @override
  String get chartLegend_noAnchoring => 'Ankringsförbud';

  @override
  String get chartLegend_caution => 'Varningsområde';

  @override
  String get chartLegend_cautionHint => 'Var extra försiktig här';

  @override
  String get chartLegend_trafficLane => 'Trafikfil';

  @override
  String get chartLegend_trafficLaneHint =>
      'Stora fartyg, en riktning: korsa i rät vinkel';

  @override
  String get chartLegend_separationZone => 'Separationszon';

  @override
  String get chartLegend_separationZoneHint =>
      'Mellan trafikfiler: håll dig utanför';

  @override
  String get chartLegend_precautionary => 'Försiktighetsområde';

  @override
  String get chartLegend_precautionaryHint => 'Fartyg möts: var försiktig';

  @override
  String get chartLegend_fairway => 'Farled';

  @override
  String get chartLegend_fairwayHint => 'En huvudfarled';

  @override
  String get chartLegend_track => 'Rekommenderad kurslinje';

  @override
  String get chartLegend_ferry => 'Färjeled';

  @override
  String get chartLegend_leadingLine => 'Enslinje';

  @override
  String get chartLegend_leadingLineHint =>
      'Håll de två märkena i linje för att stanna i farleden';

  @override
  String get chartLegend_cable => 'Sjökabel';

  @override
  String get chartLegend_cableHint => 'Ankra inte';

  @override
  String get chartLegend_pipeline => 'Undervattensledning';

  @override
  String get chartLegend_pipelineHint => 'Ankra inte';

  @override
  String get chartLegend_overhead => 'Luftledning';

  @override
  String get chartLegend_overheadHint => 'Den fria höjden anges som VC';

  @override
  String get chartLegend_tower => 'Torn';

  @override
  String get chartLegend_windTurbine => 'Vindkraftverk';

  @override
  String get chartLegend_chimney => 'Skorsten';

  @override
  String get chartLegend_mast => 'Mast eller antenn';

  @override
  String get chartLegend_church => 'Kyrka eller tornspira';

  @override
  String get chartLegend_flagstaff => 'Flaggstång';

  @override
  String get chartLegend_dome => 'Kupol';

  @override
  String get chartLegend_landmark => 'Annat landmärke';

  @override
  String get chartLegend_abbrAnch => 'Ankarplats';

  @override
  String get chartLegend_abbrWk => 'Vrak';

  @override
  String get chartLegend_abbrBr => 'Bränningar';

  @override
  String get chartLegend_abbrWd => 'Tång';

  @override
  String get chartLegend_abbrVar => 'Missvisning';

  @override
  String get chartLegend_abbrVc => 'Fri höjd under en bro eller ledning';

  @override
  String get chartLegend_abbrTr => 'Torn';

  @override
  String get chartLegend_abbrCh => 'Kyrka';

  @override
  String get chartLegend_abbrChy => 'Skorsten';

  @override
  String get chartLegend_abbrFs => 'Flaggstång';

  @override
  String get chartLegend_abbrTk => 'Tank';

  @override
  String get chartLegend_abbrRBn => 'Radiofyr';

  @override
  String get chartLegend_abbrCg => 'Kustbevakningsstation';

  @override
  String get chartLegend_abbrRacon => 'Radarfyr: syns på radarn';

  @override
  String get chartLegend_abbrFog =>
      'Mistsignal: mistlur, klocka, gong, vissla eller siren';

  @override
  String get chartLegend_abbrVAis => 'Virtuellt märke: visas bara via AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from till $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Djupare än $depth';
  }

  @override
  String get parkLegend_title => 'Park- och ledsymboler';

  @override
  String get parkLegend_campsite => 'Campingplats';

  @override
  String get parkLegend_picnicSite => 'Picknickplats';

  @override
  String get parkLegend_shelter => 'Vindskydd';

  @override
  String get parkLegend_toilets => 'Toaletter';

  @override
  String get parkLegend_drinkingWater => 'Dricksvatten';

  @override
  String get parkLegend_parking => 'Parkering';

  @override
  String get parkLegend_viewpoint => 'Utsiktsplats';

  @override
  String get parkLegend_attraction => 'Sevärdhet';

  @override
  String get parkLegend_gate => 'Grind';

  @override
  String get parkLegend_telephone => 'Telefon';

  @override
  String get parkLegend_information => 'Informationstavla';

  @override
  String get parkLegend_guidepost => 'Vägvisare';

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
}
