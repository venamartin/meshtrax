// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Chats';

  @override
  String get chats_title => 'Chats';

  @override
  String get newChat_title => 'Contact kiezen';

  @override
  String newChat_contactCount(int count) {
    return '$count contacten';
  }

  @override
  String get newChat_newContact => 'Nieuw contact';

  @override
  String get newChat_newChannel => 'Nieuw kanaal';

  @override
  String get newChat_myContacts => 'Mijn contacten';

  @override
  String get newChat_discovered => 'Ontdekt';

  @override
  String get repeaters_title => 'Repeaters beheren';

  @override
  String get nav_contacts => 'Contacten';

  @override
  String get nav_channels => 'Kanalen';

  @override
  String get nav_map => 'Kaart';

  @override
  String get common_cancel => 'Annuleren';

  @override
  String get common_syncing_device_info => 'Apparaatinfo lezen...';

  @override
  String get common_syncing_contacts => 'Contacten lezen...';

  @override
  String get common_syncing_channels => 'Kanalen lezen...';

  @override
  String get common_syncing_messages => 'Berichten lezen...';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Verbinden';

  @override
  String get common_unknownDevice => 'Onbekend apparaat';

  @override
  String get common_save => 'Opslaan';

  @override
  String get common_delete => 'Verwijderen';

  @override
  String get common_deleteAll => 'Alles verwijderen';

  @override
  String get common_close => 'Sluiten';

  @override
  String get common_edit => 'Bewerken';

  @override
  String get common_add => 'Toevoegen';

  @override
  String get common_settings => 'Instellingen';

  @override
  String get common_disconnect => 'Verbinding verbreken';

  @override
  String get common_connected => 'Verbonden';

  @override
  String get common_disconnected => 'Verbinding verbroken';

  @override
  String get common_connectionLost =>
      'Verbinding verbroken. Opnieuw verbinden...';

  @override
  String get common_reconnecting => 'Opnieuw verbinden...';

  @override
  String get common_create => 'Maak';

  @override
  String get common_continue => 'Doorgaan';

  @override
  String get common_share => 'Delen';

  @override
  String get common_copy => 'Kopiëren';

  @override
  String get common_retry => 'Nogmaals proberen';

  @override
  String get common_hide => 'Verbergen';

  @override
  String get common_remove => 'Verwijderen';

  @override
  String get common_enable => 'Activeren';

  @override
  String get common_disable => 'Uitschakelen';

  @override
  String get common_reboot => 'Herstarten';

  @override
  String get common_loading => 'Laden...';

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
  String get tcpScreenTitle => 'Verbind via TCP';

  @override
  String get tcpHostLabel => 'IP-adres';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Poort';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Voer het eindpunt in en verbind';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Verbinding maken met $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Een IP-adres is vereist.';

  @override
  String get tcpErrorPortInvalid =>
      'De poortwaarde moet tussen 1 en 65535 liggen.';

  @override
  String get tcpErrorUnsupported =>
      'TCP-transport wordt niet ondersteund op deze platform.';

  @override
  String get tcpErrorTimedOut => 'De TCP-verbinding is verlopen.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Verbinding met TCP mislukt: $error';
  }

  @override
  String get usbScreenTitle => 'Verbind via USB';

  @override
  String get usbScreenSubtitle =>
      'Selecteer een gedetecteerd seriële apparaat en verbind deze direct met uw MeshCore-node.';

  @override
  String get usbScreenStatus => 'Selecteer een USB-apparaat';

  @override
  String get usbScreenNote =>
      'USB-serieel is actief op ondersteunde Android-apparaten en desktop-platforms.';

  @override
  String get usbScreenEmptyState =>
      'Geen USB-apparaten gevonden. Sluit er een aan en herlaad.';

  @override
  String get usbErrorPermissionDenied => 'Toegang via USB is geweigerd.';

  @override
  String get usbErrorDeviceMissing =>
      'Het geselecteerde USB-apparaat is niet meer beschikbaar.';

  @override
  String get usbErrorInvalidPort => 'Selecteer een geldig USB-apparaat.';

  @override
  String get usbErrorBusy =>
      'Een andere verzoek om een USB-verbinding is al in behandeling.';

  @override
  String get usbErrorNotConnected => 'Er is geen USB-apparaat aangesloten.';

  @override
  String get usbErrorOpenFailed =>
      'Kon het geselecteerde USB-apparaat niet openen.';

  @override
  String get usbErrorConnectFailed =>
      'Kon niet verbinding maken met het geselecteerde USB-apparaat.';

  @override
  String get usbErrorUnsupported =>
      'USB-serieel is niet ondersteund op deze platform.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Deze build mist zijn USB-seriële bibliotheek, dus USB-apparaten kunnen niet worden geopend. Installeer MeshTrax opnieuw of meld deze build als defect.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Deze browser ondersteunt Web Serial niet. Gebruik Chrome of Edge via HTTPS (of localhost).';

  @override
  String get usbErrorAlreadyActive => 'Een USB-verbinding is al actief.';

  @override
  String get usbErrorNoDeviceSelected => 'Geen USB-apparaat is geselecteerd.';

  @override
  String get usbErrorPortClosed => 'De USB-verbinding is niet actief.';

  @override
  String get usbErrorConnectTimedOut =>
      'Verbinding is verbroken. Zorg ervoor dat het apparaat de juiste USB-firmware heeft.';

  @override
  String get usbFallbackDeviceName => 'Web-serieapparaat';

  @override
  String get usbStatus_notConnected => 'Selecteer een USB-apparaat';

  @override
  String get usbStatus_connecting => 'Verbinding maken met USB-apparaat...';

  @override
  String get usbStatus_searching => 'Zoeken naar USB-apparaten...';

  @override
  String usbConnectionFailed(String error) {
    return 'Fout bij de USB-verbinding: $error';
  }

  @override
  String get scanner_scanning => 'Scannen naar apparaten...';

  @override
  String get scanner_connecting => 'Verbinden...';

  @override
  String get scanner_disconnecting => 'Verbinding verbreken...';

  @override
  String get scanner_notConnected => 'Niet verbonden';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Verbonden met $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Alle Bluetooth-apparaten tonen';

  @override
  String get scanner_showMeshCoreOnly => 'Alleen MeshCore-radio\'s tonen';

  @override
  String get scanner_radioNotResponding =>
      'De radio reageert niet. Mogelijk moet hij gekoppeld worden: open de Bluetooth-instellingen, voeg de radio toe, voer de PIN in en probeer het opnieuw.';

  @override
  String get scanner_pairingFailed =>
      'Bluetooth-koppeling is geannuleerd of mislukt. Zorg dat niets anders (zoals je telefoon) met de radio verbonden is, probeer het dan opnieuw en voer de PIN in.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Verbinding mislukt: $error';
  }

  @override
  String get scanner_stop => 'Stoppen';

  @override
  String get scanner_scan => 'Scan';

  @override
  String get scanner_scanFromImage => 'Scannen uit afbeelding';

  @override
  String get scanner_noQrFoundInImage =>
      'Geen geldige QR-code gevonden in afbeelding';

  @override
  String get scanner_bluetoothOff => 'Bluetooth is uitgeschakeld';

  @override
  String get scanner_bluetoothOffMessage =>
      'Zorg ervoor dat Bluetooth is ingeschakeld om naar apparaten te zoeken.';

  @override
  String get scanner_chromeRequired => 'Chrome-browser vereist';

  @override
  String get scanner_chromeRequiredMessage =>
      'Deze webapplicatie vereist Google Chrome of een op Chromium gebaseerde browser voor Bluetooth-ondersteuning.';

  @override
  String get scanner_enableBluetooth => 'Activeer Bluetooth';

  @override
  String get device_quickSwitch => 'Snelle overschakeling';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Instellingen';

  @override
  String get settings_deviceInfo => 'Apparateninformatie';

  @override
  String get settings_appSettings => 'App Instellingen';

  @override
  String get settings_appSettingsSubtitle =>
      'Notificaties, berichten en kaartinstellingen';

  @override
  String get settings_nodeSettings => 'Node Instellingen';

  @override
  String get settings_nodeName => 'Nodenaam';

  @override
  String get settings_nodeNameNotSet => 'Niet ingesteld';

  @override
  String get settings_nodeNameHint => 'Voer nodenaam in';

  @override
  String get settings_nodeNameUpdated => 'Naam bijgewerkt';

  @override
  String get settings_radioSettings => 'Radio Instellingen';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequentie, vermogen, spredfactor';

  @override
  String get settings_radioSettingsUpdated => 'Radio instellingen bijgewerkt';

  @override
  String get settings_location => 'Locatie';

  @override
  String get settings_locationSubtitle => 'GPS coördinaten';

  @override
  String get settings_locationUpdated => 'Locatie bijgewerkt';

  @override
  String get settings_locationBothRequired =>
      'Voer zowel breedte- als lengtegraad in.';

  @override
  String get settings_locationInvalid =>
      'Ongeldige breedtegraad of lengtegraad.';

  @override
  String get settings_locationGPSEnable => 'GPS inschakelen';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Activeer automatisch locatieupdates via GPS.';

  @override
  String get settings_latitude => 'Breedtegraad';

  @override
  String get settings_longitude => 'Lengtegraad';

  @override
  String get settings_contactSettings => 'Contactinstellingen';

  @override
  String get settings_contactSettingsSubtitle =>
      'Instellingen voor het toevoegen van contacten';

  @override
  String get settings_privacyMode => 'Privacy Mode';

  @override
  String get settings_privacyModeSubtitle =>
      'Naam/locatie verbergen in advertenties';

  @override
  String get settings_privacyModeToggle =>
      'Schakel privacy modus in om je naam en locatie in advertenties te verbergen.';

  @override
  String get settings_privacyModeEnabled => 'Privacy modus is ingeschakeld';

  @override
  String get settings_privacyModeDisabled => 'Privacy modus is uitgeschakeld';

  @override
  String get settings_privacy => 'Privacyinstellingen';

  @override
  String get settings_privacySubtitle =>
      'Beheer welke informatie wordt gedeeld';

  @override
  String get settings_privacySettingsDescription =>
      'Kies welke informatie uw apparaat deelt met anderen';

  @override
  String get settings_denyAll => 'Weiger alles';

  @override
  String get settings_allowByContact => 'Toestaan op basis van contactvlaggen';

  @override
  String get settings_allowAll => 'Alles toestaan';

  @override
  String get settings_telemetryBaseMode => 'Telemetrie-basismodus';

  @override
  String get settings_telemetryLocationMode => 'Telemetrie-locatiemodus';

  @override
  String get settings_telemetryEnvironmentMode => 'Telemetrie-omgevingsmodus';

  @override
  String get settings_advertLocation => 'Advertentielocatie';

  @override
  String get settings_advertLocationSubtitle =>
      'Locatie opnemen in advertentie';

  @override
  String get settings_multiAck => 'Meerdere bevestigingen';

  @override
  String get settings_telemetryModeUpdated => 'Telemetrie-modus bijgewerkt';

  @override
  String get settings_actions => 'Acties';

  @override
  String get settings_sendAdvertisement => 'Verzend Advertentie';

  @override
  String get settings_sendAdvertisementSubtitle => 'Nu aanwezigheid uitzenden';

  @override
  String get settings_advertisementSent => 'Advertentie verzonden';

  @override
  String get settings_syncTime => 'Tijd Synchroniseren';

  @override
  String get settings_syncTimeSubtitle =>
      'Stel de apparaatklok in op de tijd van de telefoon.';

  @override
  String get settings_timeSynchronized => 'Tijdsynchronisatie';

  @override
  String get settings_refreshContacts => 'Contacten vernieuwen';

  @override
  String get settings_refreshContactsSubtitle =>
      'Contactlijst opnieuw laden van het apparaat';

  @override
  String get settings_rebootDevice => 'Apparaat opnieuw opstarten';

  @override
  String get settings_rebootDeviceSubtitle => 'Herstart het MeshCore-apparaat';

  @override
  String get settings_rebootDeviceConfirm =>
      'Ben je er zeker van dat je het apparaat opnieuw wilt opstarten? Je wordt losgekoppeld.';

  @override
  String get settings_debug => 'Debug';

  @override
  String get settings_bleDebugLog => 'BLE Debug Log';

  @override
  String get settings_bleDebugLogSubtitle =>
      'BLE commando\'s, antwoorden en ruwe data';

  @override
  String get settings_appDebugLog => 'App Debug Log';

  @override
  String get settings_appDebugLogSubtitle => 'Toepassingsdebugberichten';

  @override
  String get settings_exportDatabase => 'Berichtendatabase exporteren';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Een kopie van alle chats en contacten, voor foutopsporing. Houd deze privé.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Database opgeslagen in: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Exporteren mislukt: $error';
  }

  @override
  String get settings_about => 'Over';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'MeshTrax Source Project 2024';

  @override
  String get settings_aboutDescription =>
      'Een open-source Flutter client voor MeshCore LoRa mesh netwerkapparaten.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS-hoogtegegevens: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Naam';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Batterij';

  @override
  String get settings_infoPublicKey => 'Openbare Sleutel';

  @override
  String get settings_infoContactsCount => 'Aantal Contacten';

  @override
  String get settings_infoChannelCount => 'Aantal Kanalen';

  @override
  String get settings_presets => 'Presets';

  @override
  String get settings_frequency => 'Frequentie (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Ongeldige frequentie (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Bandbreedte';

  @override
  String get settings_spreadingFactor => 'Spreadsnelheid';

  @override
  String get settings_codingRate => 'Codeertarief';

  @override
  String get settings_txPower => 'TX-Vermogen (dBm)';

  @override
  String get settings_txPowerInvalid => 'Ongeldige TX-vermogen';

  @override
  String get settings_clientRepeat => 'Off-Grid Herhalen';

  @override
  String get settings_clientRepeatSubtitle =>
      'Laat dit apparaat de berichten van andere apparaten doorsturen.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Om een signaal buiten het netwerk te versturen, zijn frequenties van 433, 869 of 918 MHz vereist.';

  @override
  String settings_error(String message) {
    return 'Fout: $message';
  }

  @override
  String get appSettings_title => 'App Instellingen';

  @override
  String get appSettings_appearance => 'Uiterlijk';

  @override
  String get appSettings_theme => 'Thema';

  @override
  String get appSettings_themeSystem => 'Standaardinstelling';

  @override
  String get appSettings_themeLight => 'Licht';

  @override
  String get appSettings_themeDark => 'Donker';

  @override
  String get appSettings_language => 'Taal';

  @override
  String get appSettings_languageSystem => 'Standaardinstelling';

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
  String get appSettings_languageRu => 'Russisch';

  @override
  String get appSettings_languageUk => 'Oekraïens';

  @override
  String get appSettings_enableMessageTracing => 'Berichttracking inschakelen';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Gedetailleerde routerings- en timing-metadata voor berichten weergeven';

  @override
  String get appSettings_senderNameColors => 'Kleurrijke afzendernamen';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Geef elke afzender in een kanaal een eigen naamkleur. Uit gebruikt de themakleur voor iedereen.';

  @override
  String get appSettings_showTextFormatting => 'Tekstopmaak tonen';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown in berichten: **vet**, *cursief*, ||spoilers||, koppen en links. Andere MeshCore-apps tonen de ruwe tekens.';

  @override
  String get appSettings_notifications => 'Notificaties';

  @override
  String get appSettings_enableNotifications => 'Notificaties inschakelen';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Ontvang meldingen voor berichten en advertenties';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Toestemming tot notificaties geweigerd';

  @override
  String get appSettings_notificationsEnabled =>
      'Notificaties zijn ingeschakeld';

  @override
  String get appSettings_notificationsDisabled =>
      'Notificaties zijn uitgeschakeld';

  @override
  String get appSettings_messageNotifications => 'Berichtnotificaties';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Toon notificatie bij het ontvangen van nieuwe berichten';

  @override
  String get appSettings_channelMessageNotifications =>
      'Kanaal Bericht Meldingen';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Toon notificatie bij het ontvangen van kanaalberichten';

  @override
  String get appSettings_advertisementNotifications => 'Advertentie-meldingen';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Toon notificatie wanneer nieuwe nodes worden ontdekt';

  @override
  String get appSettings_messaging => 'Berichten';

  @override
  String get appSettings_maxMessageRetries =>
      'Aantal pogingen om berichten te versturen';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Aantal pogingen om een bericht opnieuw te versturen voordat het als mislukt wordt gemarkeerd';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Max. herhaalpogingen kanaalberichten';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Zo vaak wordt het opnieuw geprobeerd tot er minstens één herhaling gehoord wordt';

  @override
  String get appSettings_battery => 'Batterij';

  @override
  String get appSettings_batteryChemistry => 'Batterijchemie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Instellen per apparaat ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Verbind met een apparaat om te selecteren';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Kaartweergave';

  @override
  String get appSettings_showRepeaters => 'Toon Repeaters';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Toon repeaternodes op de kaart';

  @override
  String get appSettings_showChatNodes => 'Chat Nodes tonen';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Chatnodes weergeven op de kaart';

  @override
  String get appSettings_showOtherNodes => 'Toon Andere Nodes';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Toon andere nodetypes op de kaart';

  @override
  String get appSettings_timeFilter => 'Filter op tijd';

  @override
  String get appSettings_timeFilterShowAll => 'Alle nodes tonen';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Toon nodes van de laatste $hours uur';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filter tijd op kaart';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Toon nodes ontdekt binnen:';

  @override
  String get appSettings_allTime => 'Altijd';

  @override
  String get appSettings_lastHour => 'Afgelopen uur';

  @override
  String get appSettings_last6Hours => 'Afgelopen 6 uur';

  @override
  String get appSettings_last24Hours => 'Afgelopen 24 uur';

  @override
  String get appSettings_lastWeek => 'Afgelopen week';

  @override
  String get appSettings_unitsTitle => 'Eenheden';

  @override
  String get appSettings_unitsMetric => 'Metrisch (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperiaal (ft / mi)';

  @override
  String get appSettings_debugCard => 'Debug';

  @override
  String get appSettings_appDebugLogging => 'App Debuggen Loggen';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Log app debugberichten voor probleemoplossing';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'App debug logging is ingeschakeld';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'App debug logging is uitgeschakeld';

  @override
  String get appSettings_incrementalContactSync =>
      'Incrementele contactsynchronisatie';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Vraag bij opnieuw verbinden de radio alleen om contacten die sinds de vorige keer zijn gewijzigd';

  @override
  String get contacts_title => 'Contacten';

  @override
  String get contacts_noContacts => 'Nog geen contacten.';

  @override
  String get contacts_shareMyQrCode => 'Mijn QR-code delen';

  @override
  String get contacts_shareQrCodeDesc =>
      'Laat anderen scannen om je als contact toe te voegen';

  @override
  String get contacts_contactsWillAppear =>
      'Contacten verschijnen wanneer apparaten zich aanbieden.';

  @override
  String get contacts_unread => 'Ongelezen';

  @override
  String get contacts_searchContactsNoNumber => 'Zoek contacten...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Zoek contacten...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Zoek $number$str favorieten...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Zoek $number$str gebruikers...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Zoek $number$str Repeaters...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Zoek $number$str Room servers...';
  }

  @override
  String get contacts_noUnreadContacts => 'Geen ongelezen contacten';

  @override
  String get contacts_noContactsFound => 'Geen contacten of groepen gevonden.';

  @override
  String get contacts_deleteContact => 'Verwijder Contact';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Weet je zeker dat je $contactName wilt verwijderen?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Contact $contactName verwijderd.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Verwijderen van $contactName mislukt.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Geen contacten die aan het filter voldoen.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Verwijder $contactName uit de contacten?';
  }

  @override
  String get contacts_manageRepeater => 'Beheer Repeater';

  @override
  String get contacts_manageRoom => 'Beheer Ruimte Server';

  @override
  String get contacts_roomLogin => 'Ruimte Inloggen';

  @override
  String get contacts_openChat => 'Open Chat';

  @override
  String get contacts_editGroup => 'Groep bewerken';

  @override
  String get contacts_deleteGroup => 'Groep verwijderen';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Verwijder $groupName?';
  }

  @override
  String get contacts_newGroup => 'Nieuwe Groep';

  @override
  String get contacts_groupName => 'Groepnaam';

  @override
  String get contacts_groupNameRequired => 'De groepnaam is verplicht.';

  @override
  String get contacts_groupNameReserved => 'Deze groepsnaam is gereserveerd';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'De groep \"$name\" bestaat al.';
  }

  @override
  String get contacts_filterContacts => 'Filters contacten...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Geen contacten matchen met uw filter';

  @override
  String get contacts_noMembers => 'Geen leden';

  @override
  String get contacts_lastSeenNow => 'Laatste keer gezien nu';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Laatst gezien $minutes minuten geleden';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Laast gezien 1 uur geleden';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Laast gezien $hours uur geleden';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Laatste bekeken 1 dag geleden';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Laast gezien $days dagen geleden';
  }

  @override
  String get contact_info => 'Contactinformatie';

  @override
  String get contact_settings => 'Contactinstellingen';

  @override
  String get contact_telemetry => 'Telemetrie';

  @override
  String get contact_lastSeen => 'Laatst gezien';

  @override
  String get contact_clearChat => 'Chat leegmaken';

  @override
  String get contact_teleBase => 'Telemetrie_basis';

  @override
  String get contact_teleBaseSubtitle =>
      'Sta delen van batterij niveau en basis telemetrie toe';

  @override
  String get contact_teleLoc => 'Telemetrielocatie';

  @override
  String get contact_teleLocSubtitle => 'Locatiegegevens delen toestaan';

  @override
  String get contact_teleEnv => 'Telemetrieomgeving';

  @override
  String get contact_teleEnvSubtitle => 'Delen van omgevingsensordata toestaan';

  @override
  String get contacts_publicKey => 'Openbare sleutel';

  @override
  String get channels_title => 'Kanaal';

  @override
  String get channels_noChannelsConfigured => 'Geen kanalen geconfigureerd';

  @override
  String get channels_addPublicChannel => 'Maak Open Kanaal';

  @override
  String get channels_searchChannels => 'Zoek kanalen...';

  @override
  String get channels_noChannelsFound => 'Geen kanalen gevonden';

  @override
  String channels_channelIndex(int index) {
    return 'Kanaal $index';
  }

  @override
  String get channels_hashtagChannel => 'Hashtag kanaal';

  @override
  String get channels_public => 'Openbaar';

  @override
  String get channels_private => 'Privé';

  @override
  String get channels_publicChannel => 'Open kanaal';

  @override
  String get channels_privateChannel => 'Private kanaal';

  @override
  String get channels_editChannel => 'Kanaal bewerken';

  @override
  String get channels_shareChannel => 'Kanaal delen';

  @override
  String get channels_shareChannelInstructions =>
      'Scan de QR-code om het kanaal toe te voegen.\nMenu → Kanaal toevoegen → Scan een QR-code';

  @override
  String get channels_secretKey => 'Geheime sleutel';

  @override
  String get channels_meshcoreUri => 'MeshCore-URI';

  @override
  String get channels_shareChannelQr => 'Kanaal-QR-code scannen';

  @override
  String get channels_shareChannelWarning =>
      'Let op: iedereen die deze QR-code scant, krijgt toegang tot dit kanaal.';

  @override
  String get channels_muteChannel => 'Kanaal dempen';

  @override
  String get channels_unmuteChannel => 'Kanaal dempen opheffen';

  @override
  String get channels_deleteChannel => 'Kanaal verwijderen';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Verwijderen \"$name\"? Dit kan niet worden teruggedraaid.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kan kanaal $name niet verwijderen';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanaal \"$name\" verwijderd';
  }

  @override
  String get channels_addChannel => 'Kanaal toevoegen';

  @override
  String get channels_channelIndexLabel => 'Kanaalindex';

  @override
  String get channels_channelName => 'Kanaalnaam';

  @override
  String get channels_usePublicChannel => 'Gebruik Open Kanaal';

  @override
  String get channels_standardPublicPsk => 'Standaard open PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Willekeurige PSK genereren';

  @override
  String get channels_enterChannelName => 'Voer een kanaalnaam in';

  @override
  String get channels_pskMustBe32Hex =>
      'De PSK moet 32 hexadecimale tekens zijn.';

  @override
  String get channels_addChannelConfirmation =>
      'Wil je het volgende kanaal toevoegen?';

  @override
  String get channels_channelAddedSuccess => 'Kanaal toegevoegd.';

  @override
  String get channels_noAvailableChannelSlots => 'Geen vrije kanaalplaatsen.';

  @override
  String get appSettings_mentionNotifications => 'Meldingen bij vermelding';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Als iemand je vermeldt of op je reageert — ook in gedempte kanalen';

  @override
  String notification_mentionIn(String channelName) {
    return 'Vermelding in $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Kanaal \"$name\" toegevoegd';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Bewerk Kanaal $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ compressie';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanaal \"$name\" is bijgewerkt';
  }

  @override
  String get channels_publicChannelAdded => 'Open kanaal toegevoegd';

  @override
  String get channels_sortBy => 'Sorteren door';

  @override
  String get channels_sortManual => 'Handmatig';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Recent berichten';

  @override
  String get channels_sortUnread => 'Ongelezen';

  @override
  String get channels_createPrivateChannel => 'PrivéKanaal Aanmaken';

  @override
  String get channels_createPrivateChannelDesc =>
      'Beveiligd met een geheime sleutel.';

  @override
  String get channels_joinPrivateChannel => 'PrivéKanaal Toetreden';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Voer handmatig een geheime sleutel in.';

  @override
  String get channels_joinPublicChannel => 'Publiek Kanaal Toetreden';

  @override
  String get channels_joinPublicChannelDesc =>
      'Iedereen kan toetreden tot dit kanaal.';

  @override
  String get channels_joinHashtagChannel => 'Hashtag-kanaal Aanmaken';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Iedereen kan toetreden tot hashtag-kanalen.';

  @override
  String get channels_scanQrCode => 'Scan een QR-code';

  @override
  String get channels_scanQrCodeComingSoon => 'Komt later';

  @override
  String get channels_enterHashtag => 'Voer hashtag in';

  @override
  String get channels_hashtagHint => 'bijv. #team';

  @override
  String get chat_noMessages => 'Nog geen berichten.';

  @override
  String get chat_sendMessage => 'Verzend bericht';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Verstuur een bericht naar $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Een bericht sturen om te beginnen';

  @override
  String get chat_originalMessageNotFound => 'Originele bericht niet gevonden';

  @override
  String chat_replyingTo(String name) {
    return 'Reageren op $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Reageer op $name';
  }

  @override
  String get chat_location => 'Locatie';

  @override
  String get common_copiedToClipboard => 'Gekopieerd naar klembord';

  @override
  String get common_copyToClipboard => 'Kopiëren naar klembord';

  @override
  String get contacts_copyContactToClipboard =>
      'Mijn contact naar klembord kopiëren';

  @override
  String get chat_typeMessage => 'Type een bericht...';

  @override
  String get chat_searchMessages => 'Berichten zoeken';

  @override
  String get chat_searchNoMatches => 'Geen resultaten';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Bericht is te lang (max $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Bericht gekopieerd';

  @override
  String get chat_messageDeleted => 'Bericht verwijderd';

  @override
  String get chat_sendGif => 'GIF verzenden';

  @override
  String get chat_reply => 'Reageren';

  @override
  String get chat_newMessages => 'NIEUWE BERICHTEN';

  @override
  String get chat_addReaction => 'Reactie toevoegen';

  @override
  String get chat_mention => 'Vermelden';

  @override
  String get dmChannel_menuLabel => 'Direct bericht';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'DM sturen naar $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Controleer de sleutel en wanneer het contact het laatst gezien is — namen zijn niet uniek.';

  @override
  String get dmChannel_warningTitle => 'Is dit echt de juiste persoon?';

  @override
  String get dmChannel_warningBody =>
      'Namen in kanalen kiest iedereen zelf en iedereen kan ze nabootsen. Controleer bij gevoelige zaken eerst op een andere manier de openbare sleutel van dit contact.';

  @override
  String get dmChannel_dontShowAgain => 'Niet meer tonen';

  @override
  String get batterySleep_title => 'MeshTrax actief houden';

  @override
  String get batterySleep_bodySamsung =>
      'Samsung-telefoons zetten apps in slaapstand om batterij te sparen, waardoor je radio wordt losgekoppeld. Open Instellingen → Apps → MeshTrax → Batterij en kies Onbeperkt. Controleer ook Batterij → Limieten voor achtergrondgebruik en zorg dat MeshTrax niet bij Apps in slaapstand of Apps in diepe slaapstand staat.';

  @override
  String get batterySleep_bodyGeneric =>
      'Je telefoon kan MeshTrax op de achtergrond stoppen om batterij te sparen, waardoor je radio wordt losgekoppeld. Open de batterij-instellingen en zet MeshTrax op Onbeperkt (of Geen beperkingen). Op sommige telefoons moet je ook Autostart voor MeshTrax aanzetten.';

  @override
  String get batterySleep_openSettings => 'Instellingen openen';

  @override
  String get batterySleep_notNow => 'Niet nu';

  @override
  String get batterySleep_settingsTile =>
      'MeshTrax op de achtergrond actief houden';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Voorkom dat de batterijbesparing van de telefoon MeshTrax in slaapstand zet';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Nog geen DM mogelijk naar $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Je hebt hun sleutel nog niet, en zij hebben de jouwe nodig om te antwoorden — sleutels gaan alleen mee in advertenties. “Mijn advertentie sturen” zendt de jouwe direct vanaf hier uit. “Vragen in kanaal” zet een verzoek in het berichtvak dat je zelf verstuurt.';

  @override
  String get dmChannel_askInChannel => 'Vragen in kanaal';

  @override
  String get dmChannel_sendMyAdvert => 'Mijn advertentie sturen';

  @override
  String get dmChannel_askText =>
      'stuur alsjeblieft een advertentie zodat ik je een DM kan sturen';

  @override
  String get dmChannel_watching =>
      'Wachten op hun advertentie — je krijgt hier een vraag zodra die binnenkomt.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name is nu bereikbaar';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Zoomniveau';

  @override
  String get common_reset => 'Herstellen';

  @override
  String get chat_reactionsTitle => 'Reacties';

  @override
  String get chat_reactionUnknownSender => 'Onbekend';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender reageerde op een bericht dat niet in deze chat staat';
  }

  @override
  String get chat_me => 'Mijn';

  @override
  String get emojiCategorySmileys => 'Emoji\'s';

  @override
  String get emojiCategoryGestures => 'Bewegingen';

  @override
  String get emojiCategoryHearts => 'Hartens';

  @override
  String get emojiCategoryObjects => 'Objecten';

  @override
  String get gifPicker_title => 'Kies een GIF';

  @override
  String get gifPicker_searchHint => 'Zoek GIFs...';

  @override
  String get gifPicker_poweredBy => 'Aangedreven door GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Geen GIFs gevonden';

  @override
  String get gifPicker_failedLoad => 'GIF\'s konden niet worden geladen';

  @override
  String get gifPicker_failedSearch => 'Zoeken mislukt';

  @override
  String get gifPicker_noInternet => 'Geen internetverbinding';

  @override
  String get debugLog_appTitle => 'App Debug Log';

  @override
  String get debugLog_bleTitle => 'BLE Debug Log';

  @override
  String get debugLog_copyLog => 'Kopieer log';

  @override
  String get debugLog_saveLog => 'Log opslaan als bestand';

  @override
  String get debugLog_saved => 'Log opgeslagen';

  @override
  String get debugLog_saveCancelled => 'Opslaan geannuleerd';

  @override
  String get debugLog_filterAll => 'Alles';

  @override
  String get debugLog_filterWarnings => 'Waarschuwingen';

  @override
  String get debugLog_filterErrors => 'Fouten';

  @override
  String get debugLog_clearLog => 'Log wissen';

  @override
  String get debugLog_copied => 'Debuglog gekopieerd';

  @override
  String get debugLog_bleCopied => 'BLE log gekopieerd';

  @override
  String get debugLog_noEntries => 'Nog geen debug logs beschikbaar.';

  @override
  String get debugLog_enableInSettings =>
      'Schakel app debug logging in de instellingen';

  @override
  String get debugLog_frames => 'Ramen';

  @override
  String get debugLog_rawLogRx => 'Raw Log-RX';

  @override
  String get debugLog_noBleActivity => 'Geen BLE-activiteit nog.';

  @override
  String debugFrame_length(int count) {
    return 'Frame Lengte: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Boodschap: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Bericht Frame:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Bestemming PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Tijdstempel: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Vlaggen: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tekstdocumenttype: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'CLI-commando';

  @override
  String get debugFrame_textTypePlain => 'Eenvoudig';

  @override
  String debugFrame_text(String text) {
    return '- Tekst: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex Dump:';

  @override
  String get chat_hopSingular => 'Hop';

  @override
  String get chat_hopPlural => 'hoppen';

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
  String get chat_setCustomPath => 'Stel aangepaste pad in';

  @override
  String get chat_fullPath => 'Volledige Pad';

  @override
  String get chat_pathDetailsNotAvailable =>
      'De paddetails zijn nog niet beschikbaar. Probeer een bericht te sturen om te vernieuwen.';

  @override
  String get chat_type => 'Typen';

  @override
  String get chat_path => 'Pad';

  @override
  String get chat_publicKey => 'Openbare Sleutel';

  @override
  String get chat_compressOutgoingMessages =>
      'Verzenden van uitgaande berichten comprimeren';

  @override
  String get chat_floodForced => 'Flood (afgedwongen)';

  @override
  String get chat_directForced => 'Direct (afgedwongen)';

  @override
  String chat_hopsForced(int count) {
    return '$count hops (afgedwongen)';
  }

  @override
  String get chat_floodAuto => 'Flood (auto)';

  @override
  String get chat_direct => 'Direct';

  @override
  String get chat_poiShared => 'Gedeelde POI';

  @override
  String chat_unread(int count) {
    return 'Nieuw: $count';
  }

  @override
  String get chat_openLink => 'Link openen?';

  @override
  String get chat_openLinkConfirmation =>
      'Wilt u deze link in uw browser openen?';

  @override
  String get chat_open => 'Openen';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Kan link niet openen: $url';
  }

  @override
  String get chat_invalidLink => 'Ongeldig linkformaat';

  @override
  String get map_lineOfSight => 'Zichtlijn';

  @override
  String get map_losScreenTitle => 'Zichtlijn';

  @override
  String get map_noNodesWithLocation => 'Geen nodes met locatiegegevens';

  @override
  String get map_nodesNeedGps =>
      'Nodes moeten hun GPS-coördinaten delen\nom op de kaart te verschijnen';

  @override
  String map_nodesCount(int count) {
    return 'Nodes: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Spelden: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repeater';

  @override
  String get map_room => 'Ruimte';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Verzenden als bericht (DM)';

  @override
  String get map_pinPrivate => 'Beveiligd (Privé)';

  @override
  String get map_pinPublic => 'Openbaar spikken';

  @override
  String get map_lastSeen => 'Laaste keer gezien';

  @override
  String get map_disconnectConfirm =>
      'Ben je er zeker van dat je verbinding met dit apparaat wilt verbreken?';

  @override
  String get map_from => 'Van';

  @override
  String get map_source => 'Bron';

  @override
  String get map_flags => 'Vlaggen';

  @override
  String get map_shareMarkerHere => 'Deel marker hier';

  @override
  String get map_setAsMyLocation => 'Stel dit in als mijn locatie';

  @override
  String get map_pinLabel => 'Label vastzetten';

  @override
  String get map_label => 'Label';

  @override
  String get map_pointOfInterest => 'Interessepunt';

  @override
  String get map_sendToContact => 'Verzenden naar contact';

  @override
  String get map_sendToChannel => 'Verzenden naar kanaal';

  @override
  String get map_noChannelsAvailable => 'Geen kanalen beschikbaar';

  @override
  String get map_publicLocationShare => 'Openbare locatie delen';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'U gaat een locatie delen in $channelLabel. Deze kanaal is openbaar en iedereen met de PSK kan het zien.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Verbind met een apparaat om markers te delen';

  @override
  String get map_filterNodes => 'Filter Nodes';

  @override
  String get map_chatNodes => 'Chatnodes';

  @override
  String get map_repeaters => 'Repeaters';

  @override
  String get map_otherNodes => 'Andere Nodes';

  @override
  String get map_showOverlaps => 'Herhalingssleutel overlapt';

  @override
  String get map_keyPrefix => 'Prefix sleutel';

  @override
  String get map_filterByKeyPrefix => 'Filteren op sleutelvoorgemeld';

  @override
  String get map_publicKeyPrefix => 'Openbare sleutelvoorgemeld';

  @override
  String get map_showDiscoveryContacts => 'Ontdek contacten weergeven';

  @override
  String get map_guessedLocation => 'Geroerde locatie';

  @override
  String get map_lastSeenTime => 'Laatste Bekeken Tijd';

  @override
  String get map_sharedPin => 'Gedeelde pin';

  @override
  String get map_joinRoom => 'Kamer Toetreden';

  @override
  String get map_manageRepeater => 'Beheer Repeater';

  @override
  String get map_tapToAdd =>
      'Tik op knooppunten om ze toe te voegen aan het pad';

  @override
  String get map_runTrace => 'Padeshulp traceren';

  @override
  String get map_runTraceWithReturnPath => 'Terugkeren op hetzelfde pad.';

  @override
  String get map_removeLast => 'Verwijder Laatste';

  @override
  String get map_pathTraceCancelled => 'Pad traceren geannuleerd';

  @override
  String get time_justNow => 'Net nu';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minuten geleden';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours uur geleden';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dagen geleden';
  }

  @override
  String get time_hour => 'uur';

  @override
  String get time_hours => 'uren';

  @override
  String get time_day => 'dag';

  @override
  String get time_days => 'dagen';

  @override
  String get time_week => 'week';

  @override
  String get time_weeks => 'weken';

  @override
  String get time_month => 'maand';

  @override
  String get time_months => 'maanden';

  @override
  String get time_minutes => 'minuten';

  @override
  String get time_allTime => 'Alle tijd';

  @override
  String get dialog_disconnect => 'Verbinden verbreken';

  @override
  String get dialog_disconnectConfirm =>
      'Ben je er zeker van dat je verbinding met dit apparaat wilt verbreken?';

  @override
  String get login_repeaterLogin => 'Inloggen Repeater';

  @override
  String get login_roomLogin => 'Ruimte Inloggen';

  @override
  String get login_password => 'Wachtwoord';

  @override
  String get login_enterPassword => 'Wachtwoord invoeren';

  @override
  String get login_savePassword => 'Wachtwoord opslaan';

  @override
  String get login_savePasswordSubtitle =>
      'Het wachtwoord wordt veilig op dit apparaat opgeslagen.';

  @override
  String get login_repeaterDescription =>
      'Voer het wachtwoord van de repeater in om instellingen en status te openen.';

  @override
  String get login_roomDescription =>
      'Voer het wachtwoord van de kamer in om toegang te krijgen tot instellingen en status.';

  @override
  String get login_login => 'Inloggen';

  @override
  String login_attempt(int current, int max) {
    return 'Poging $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Inloggen mislukt: $error';
  }

  @override
  String get login_failedMessage =>
      'Inloggen mislukt. Het wachtwoord is onjuist of de repeater is niet bereikbaar.';

  @override
  String get common_reload => 'Opnieuw laden';

  @override
  String get common_clear => 'Schoonmaken';

  @override
  String get path_enterCustomPath => 'Voer aangepaste pad in';

  @override
  String get path_currentPathLabel => 'Huidige pad';

  @override
  String get path_hexPrefixInstructions =>
      'Voer 2-letter hex-voorgiffen voor elke hop in, gescheiden door komma\'s.';

  @override
  String get path_hexPrefixExample =>
      'Voorbeeld: A1,F2,3C (elke node gebruikt het eerste byte van zijn openbare sleutel)';

  @override
  String get path_labelHexPrefixes => 'Pad (hex-voorkeursletters)';

  @override
  String get path_helperMaxHops =>
      'Maximaal 64 sprongen. Elke prefix is 2 hexadecimale tekens (1 byte)';

  @override
  String get path_selectFromContacts => 'Of select contacten:';

  @override
  String get path_noRepeatersFound => 'Geen repeaters of roomservers gevonden.';

  @override
  String get path_customPathsRequire =>
      'Aangepaste paden vereisen tussentse overstappen die berichten kunnen doorgeven.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Ongeldige hex-voorkeursletters: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Pad is te lang. Maximaal 64 sprongen zijn toegestaan.';

  @override
  String get path_setPath => 'Stel Pad in';

  @override
  String get repeater_management => 'Beheer Repeaters';

  @override
  String get room_management => 'Beheer Server Kamer';

  @override
  String get repeater_guest => 'Informatie over herhalingsapparatuur';

  @override
  String get room_guest => 'Informatie over de server';

  @override
  String get repeater_managementTools => 'Beheerfuncties';

  @override
  String get repeater_guestTools => 'Gastenfuncties';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Status, statistieken en buren bekijken';

  @override
  String get repeater_telemetry => 'Telemetry';

  @override
  String get repeater_telemetrySubtitle =>
      'Bekijk telemetrie van sensoren en systeemgegevens';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Verzend commando\'s naar de repeater';

  @override
  String get repeater_neighbors => 'Buren';

  @override
  String get repeater_neighborsSubtitle => 'Bekijk nul-hopsburen.';

  @override
  String get repeater_settings => 'Instellingen';

  @override
  String get repeater_settingsSubtitle => 'Configureer repeaterparameters';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Na het inloggen, klok synchroniseren';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automatisch een \"klok synchroniseren\" bericht versturen na een succesvolle inlog.';

  @override
  String get repeater_statusTitle => 'Status repeater';

  @override
  String get repeater_refresh => 'Vernieuwen';

  @override
  String get repeater_statusRequestTimeout => 'Statusverzoek is uitgevallen.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Fout bij het laden van de status: $error';
  }

  @override
  String get repeater_systemInformation => 'Systeeminformatie';

  @override
  String get repeater_battery => 'Batterij';

  @override
  String get repeater_clockAtLogin => 'Tijd (bij aanmelden)';

  @override
  String get repeater_uptime => 'Beschikbaarheid';

  @override
  String get repeater_queueLength => 'Wachttijd';

  @override
  String get repeater_debugFlags => 'Debugvlaggen';

  @override
  String get repeater_radioStatistics => 'Radiostatistieken';

  @override
  String get repeater_lastRssi => 'Laatste RSSI';

  @override
  String get repeater_lastSnr => 'Laatste SNR';

  @override
  String get repeater_noiseFloor => 'Ruisvloer';

  @override
  String get repeater_txAirtime => 'TX-zendtijd';

  @override
  String get repeater_rxAirtime => 'RX-zendtijd';

  @override
  String get repeater_packetStatistics => 'Pakketstatistieken';

  @override
  String get repeater_sent => 'Verzonden';

  @override
  String get repeater_received => 'Ontvangen';

  @override
  String get repeater_duplicates => 'Duplicaat';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dagen $hours uur $minutes minuten $seconds seconden';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Totaal: $total, Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Totaal: $total, Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flood: $flood, Direct: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Totaal: $total';
  }

  @override
  String get repeater_settingsTitle => 'Repeaterinstellingen';

  @override
  String get repeater_basicSettings => 'Basisinstellingen';

  @override
  String get repeater_repeaterName => 'Repeaternaam';

  @override
  String get repeater_repeaterNameHelper => 'Weergavenaam voor deze repeater';

  @override
  String get repeater_adminPassword => 'Admin wachtwoord';

  @override
  String get repeater_adminPasswordHelper => 'Wachtwoord administratortoegang';

  @override
  String get repeater_guestPassword => 'Gast wachtwoord';

  @override
  String get repeater_guestPasswordHelper => 'Wachtwoord gasttoegen';

  @override
  String get repeater_radioSettings => 'Radio Instellingen';

  @override
  String get repeater_frequencyMhz => 'Frequentie (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Bandbreedte';

  @override
  String get repeater_spreadingFactor => 'Spreidingsfactor';

  @override
  String get repeater_codingRate => 'Codeertarief';

  @override
  String get repeater_locationSettings => 'Locatie-instellingen';

  @override
  String get repeater_latitude => 'Breedtegraad';

  @override
  String get repeater_latitudeHelper => 'Graadseconden (bijv. 37.7749)';

  @override
  String get repeater_longitude => 'Lengtegraad';

  @override
  String get repeater_longitudeHelper => 'Graadseconden (bijv. -122.4194)';

  @override
  String get repeater_features => 'Kenmerken';

  @override
  String get repeater_packetForwarding => 'Pakketdoorvoering';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Repeater instellen om pakketten door te sturen';

  @override
  String get repeater_guestAccess => 'Toegang voor Gasten';

  @override
  String get repeater_guestAccessSubtitle =>
      'Toegestane leesbeheer toegang voor gasten.';

  @override
  String get repeater_privacyMode => 'Privacymodus';

  @override
  String get repeater_privacyModeSubtitle =>
      'Naam/locatie verbergen in advertenties';

  @override
  String get repeater_advertisementSettings => 'Advertentie-instellingen';

  @override
  String get repeater_localAdvertInterval => 'Lokale Advertentie Interval';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minuten';
  }

  @override
  String get repeater_floodAdvertInterval => 'Flood Advertentie Interval';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours uur';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Versleutelde Advertentie Interval';

  @override
  String get repeater_dangerZone => 'Gevaarzone';

  @override
  String get repeater_rebootRepeater => 'Herstart Repeater';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Herstart het Repeaterapparaat';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Ben je er zeker van dat je deze repeater opnieuw wilt opstarten?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Identiteit sleutel opnieuw genereren';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Nieuwe publieke/private sleutelpaar genereren';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Dit genereert een nieuwe identiteit voor de repeater. Doorgaan?';

  @override
  String get repeater_eraseFileSystem => 'Verwijder Besturingssysteem';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formateer het bestandsysteem van de repeater';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'WAARSCHUWING: Dit zal alle gegevens op de repeater wissen. Dit kan niet worden teruggedraaid!';

  @override
  String get repeater_eraseSerialOnly =>
      'Verwijderen is alleen beschikbaar via de seriële console.';

  @override
  String repeater_commandSent(String command) {
    return 'Commando verzonden: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Fout bij het verzenden van de opdracht: $error';
  }

  @override
  String get repeater_confirm => 'Bevestigen';

  @override
  String get repeater_settingsSaved => 'Instellingen succesvol opgeslagen';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Fout bij het opslaan van de instellingen: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Basisinstellingen vernieuwen';

  @override
  String get repeater_refreshRadioSettings =>
      'Radiozender Instellingen Verversen';

  @override
  String get repeater_refreshTxPower => 'Nieuw laden TX-vermogen';

  @override
  String get repeater_refreshLocationSettings =>
      'Instellingen Locatie Vernieuwen';

  @override
  String get repeater_refreshPacketForwarding =>
      'Vernieuwen Pakket Doorversturing';

  @override
  String get repeater_refreshGuestAccess => 'Toegang Gast Vernieuwen';

  @override
  String get repeater_refreshPrivacyMode => 'Privacymode vernieuwen';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Instellingen Advertentie Bijwerken';

  @override
  String repeater_refreshed(String label) {
    return '$label is vernieuwd';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Fout bij het vernieuwen van $label';
  }

  @override
  String get repeater_cliTitle => 'Repeater CLI';

  @override
  String get repeater_debugNextCommand => 'Debug Volgende Commando';

  @override
  String get repeater_commandHelp => 'Help';

  @override
  String get repeater_clearHistory => 'Geschiedenis Verwijderen';

  @override
  String get repeater_noCommandsSent => 'Nog geen commando\'s verzonden.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Typ een opdracht hieronder of gebruik snelle commando\'s';

  @override
  String get repeater_enterCommandHint => 'Voer bevel in...';

  @override
  String get repeater_previousCommand => 'Vorige opdracht';

  @override
  String get repeater_nextCommand => 'Volgende opdracht';

  @override
  String get repeater_enterCommandFirst => 'Voer eerst een commando in';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI Commando Frame';

  @override
  String repeater_cliCommandError(String error) {
    return 'Fout: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Naam opvragen';

  @override
  String get repeater_cliQuickGetRadio => 'Radio-instellingen opvragen';

  @override
  String get repeater_cliQuickGetTx => 'TX opvragen';

  @override
  String get repeater_cliQuickNeighbors => 'Buren opvragen';

  @override
  String get repeater_cliQuickVersion => 'Versie opvragen';

  @override
  String get repeater_cliQuickAdvertise => 'Advertenties opvragen';

  @override
  String get repeater_cliQuickClock => 'Tijd opvragen';

  @override
  String get repeater_cliQuickClockSync => 'Kloksynchronisatie';

  @override
  String get repeater_cliQuickDiscovery => 'Ontdek Buren';

  @override
  String get repeater_cliHelpAdvert => 'Advertentie uitzenden';

  @override
  String get repeater_cliHelpReboot =>
      'Herstart het apparaat. (let op, je krijgt mogelijk een \'Timeout\', wat normaal is)';

  @override
  String get repeater_cliHelpClock =>
      'Toont de huidige tijd per apparaat\'s klok.';

  @override
  String get repeater_cliHelpPassword =>
      'Stelt een nieuw beheerderswachtwoord in voor het apparaat.';

  @override
  String get repeater_cliHelpVersion =>
      'Toont de apparaatversie en firmware-bouwdatum.';

  @override
  String get repeater_cliHelpClearStats =>
      'Reset verschillende statistiek-tellers naar nul.';

  @override
  String get repeater_cliHelpSetAf => 'Stelt de luchtvaartfactor in.';

  @override
  String get repeater_cliHelpSetTx =>
      'Stelt LoRa zendvermogen in dBm. (om te wijzigen)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Activeert of deactiveert de repeater rol van deze node.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Kamervisie) Als \'aan\', dan wordt inloggen met een blanco wachtwoord toegestaan, maar kan niet naar de kamervisie Posten. (alleen lezen mogelijk).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Stelt het maximale aantal hops van een inkomend floodpakket in (indien >= max, wordt het pakket niet doorgestuurd)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Stelt de Interferentiewaarde (in dB) in. Standaardwaarde is 14. Stel in op 0 om het detecteren van kanaalinterferentie uit te schakelen.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Stelt het interval in om de Auto Gain Controller te resetten. Stel in op 0 om dit uit te schakelen.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Activeert of deactiveert de functie \'duplicate ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Stelt het timerinterval in minuten in om een lokale (zero-hop) advertentiepakket te versturen. Stel in op 0 om uit te schakelen.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Stelt het timerinterval in uren in om een floodadvertentiepakket te versturen. Stel in op 0 om dit uit te schakelen.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Stelt/past de gastenwacht aan of wijzigt deze. (voor herstelcontacten kunnen gastelogins de \"Get Stats\" verzoek verzenden)';

  @override
  String get repeater_cliHelpSetName => 'Stelt de advertentietitel in.';

  @override
  String get repeater_cliHelpSetLat =>
      'Stelt de breedtegraad van de advertentiekaart in. (graadrijssysteem)';

  @override
  String get repeater_cliHelpSetLon =>
      'Stelt de lengtegraad van de advertentiekaart in. (graadrijtjes)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Stelt volledig nieuwe radio parameters in en slaat deze op in de instellingen. Vereist een \"reboot\" commando om toe te passen.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Sets (experimenteel) basis (moet > 1 zijn voor effect) om een lichte vertraging toe te passen op ontvangen pakketten, gebaseerd op signaalsterkte/score. Stel op 0 om uit te schakelen.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Stelt een factor in werking die wordt vermenigvuldigd met de tijd op lucht voor een flood-mode pakket en met een willekeurig slot systeem, om de verzending ervan te vertragen (om de kans op botsingen te verminderen).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Vergelijkbaar met txdelay, maar voor het toepassen van een willekeurige vertraging bij het doorsturen van pakketten in directe modus.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Poort inschakelen/uitschakelen.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Verzend vertraging instellen voor pakketten.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Kies of de brug ontvangen pakketten of verzonden pakketten opnieuw moet versturen.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Stel de seriële link baudrate in voor rs232 bruggen.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Stel bridge-geheim in voor espnow bridges.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Stelt een aangepaste factor in om de gerapporteerde batterijspanning aan te passen (alleen ondersteund op selecte borden).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Stelt tijdelijke radio parameters in voor het opgegeven aantal minuten, en keert daarna terug naar de originele radio parameters. (wordt niet opgeslagen in de voorkeuren).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Wijzigt de ACL. Verwijder de overeenkomstige entry (door pubkey prefix) als \"permissions\" 0 is. Voeg een nieuwe entry toe als pubkey-hex volledig is en niet momenteel in de ACL staat. Update de entry door matching pubkey prefix. Toestemming bits variëren per firmware rol, maar de onderste 2 bits zijn: 0 (Gast), 1 (Alleen lezen), 2 (Lezen/schrijven), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Ontvang brugtype: geen, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Start pakketlogging naar het bestandssysteem.';

  @override
  String get repeater_cliHelpLogStop =>
      'Stoppen met het loggen van pakketten naar het bestandssysteem.';

  @override
  String get repeater_cliHelpLogErase =>
      'Verwijdert de pakketlogs uit het bestandssysteem.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Toont een lijst met andere repeater nodes die via nul-hop advertenties zijn gehoord. Elke regel is id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Verwijdert de eerste overeenkomende vermelding (via pubkey prefix (hex)) uit de lijst van buren.';

  @override
  String get repeater_cliHelpRegion =>
      '(Alleen Serieel) Lijst alle gedefinieerde regio\'s en huidige floodrechten.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'LET OP: dit is een speciale multi-command aanroep. Elke volgende opdracht is een regiortaak (uitgelijnd met spaties om de ouderhiërarchie aan te duiden, met minimaal één spatie). Beëindigd door een lege regel/opdracht te sturen.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Zoekt naar regio met gegeven naam voorvoegsel (of \"\" voor de globale scope). Antwoordt met \"-> regio-naam (ouder-naam) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Voegt of wijzigt een regio-definitie met de gegeven naam.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Verwijdert een regio-definitie met de gegeven naam. (moet exact overeenkomen en geen kindregio\'s hebben)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Stelt de \'F\'lood-toestemming in voor de opgegeven regio. (\'\' voor de globale/oude scope)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Verwijdert de \'F\'lood-toestemming voor de gegeven regio. (LET OP: op dit moment niet aanbevolen om dit op de globale/oude scope te gebruiken!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Antwoorden met de huidige \'thuis\'-regio. (Op dit moment nergens toegepast, gereserveerd voor toekomstig gebruik)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Stelt de \'thuis\'-regio in.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Bewaar de lijst/kaart van de regio\'s naar de opslag.';

  @override
  String get repeater_cliHelpGps =>
      'Geeft de status van de GPS. Wanneer de GPS uit staat, antwoordt het alleen met \"uit\", als het aan staat, antwoordt het met \"aan\", status, fix, sat count.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Schakel de GPS-standby aan/uit.';

  @override
  String get repeater_cliHelpGpsSync => 'Synchroniseer node met GPS-klok.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Stel de positie van de node vast als GPS-coördinaten en sla de voorkeuren op.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Geeft de locatie advertentieconfiguratie van de node:\n- none: locatie niet in advertenties opnemen\n- share: gps locatie delen (van SensorManager)\n- prefs: locatie adverteren die in de voorkeuren is opgeslagen';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Stelt advertentie locatie configuratie in.';

  @override
  String get repeater_commandsListTitle => 'Commandenlijst';

  @override
  String get repeater_commandsListNote =>
      'LET OP: voor de verschillende \"set ...\" commando\'s is er ook een \"get ...\" commando.';

  @override
  String get repeater_general => 'Algemeen';

  @override
  String get repeater_settingsCategory => 'Instellingen';

  @override
  String get repeater_bridge => 'Bruggen';

  @override
  String get repeater_logging => 'Logging';

  @override
  String get repeater_neighborsRepeaterOnly => 'Buren (Alleen repeaters)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Regiobeheer (Alleen Repeater)';

  @override
  String get repeater_regionNote =>
      'Regio-commando\'s zijn geïntroduceerd om regio-definities en permissies te beheren.';

  @override
  String get repeater_gpsManagement => 'Beheer GPS';

  @override
  String get repeater_gpsNote =>
      'De GPS-commando is geïntroduceerd om locatiegerelateerde onderwerpen te beheren.';

  @override
  String get telemetry_receivedData => 'Ontvangen Telemetriedata';

  @override
  String get telemetry_requestTimeout => 'Telemetryverzoek is uitgevallen.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Fout bij het laden van de telemetrie: $error';
  }

  @override
  String get telemetry_noData => 'Geen telemetriedata beschikbaar.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanaal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batterij';

  @override
  String get telemetry_voltageLabel => 'Spanning';

  @override
  String get telemetry_mcuTemperatureLabel => 'MCU-temperatuur';

  @override
  String get telemetry_temperatureLabel => 'Temperatuur';

  @override
  String get telemetry_currentLabel => 'Huidig';

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
  String get neighbors_receivedData => 'Ontvangen Buurdata';

  @override
  String get neighbors_requestTimedOut =>
      'Buren vragen om tijdelijk uitgeschakeld.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Fout bij het laden van buren: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Repeatbburen';

  @override
  String get neighbors_noData => 'Geen gegevens van buren beschikbaar.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Onbekende $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Horen: $time geleden';
  }

  @override
  String get channelPath_title => 'Pakketpad';

  @override
  String get channelPath_viewMap => 'Kaart bekijken';

  @override
  String get channelPath_otherObservedPaths => 'Overige Waargenomen Paden';

  @override
  String get channelPath_repeaterHops => 'Repeater Hops';

  @override
  String get channelPath_noHopDetails =>
      'De details van de pakket zijn niet verstrekt.';

  @override
  String get channelPath_messageDetails => 'Details Bericht';

  @override
  String get channelPath_senderLabel => 'Afzender';

  @override
  String get channelPath_timeLabel => 'Tijd';

  @override
  String get channelPath_repeatsLabel => 'Repeats';

  @override
  String channelPath_pathLabel(int index) {
    return 'Pad $index';
  }

  @override
  String get channelPath_observedLabel => 'Waargenomen';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Waargenomen pad $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Geen locatiegegevens';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Onbekend';

  @override
  String get channelPath_floodPath => 'Flood';

  @override
  String get channelPath_directPath => 'Direct';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 van $total sprongen';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed van $total sprongen';
  }

  @override
  String get channelPath_mapTitle => 'Padkaart';

  @override
  String get channelPath_noRepeaterLocations =>
      'Geen repeaters beschikbaar voor deze route.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Pad $index (Hoofdtype)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Pad';

  @override
  String get channelPath_observedPathHeader => 'Waargenomen Pad';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Geen details beschikbaar voor dit pakket.';

  @override
  String get channelPath_unknownRepeater => 'Onbekend Repeater';

  @override
  String get community_title => 'Gemeenschap';

  @override
  String get community_create => 'Maak Gemeenschap';

  @override
  String get community_createDesc =>
      'Maak een nieuwe community en deel deze via QR-code.';

  @override
  String get community_join => 'Sluit aan';

  @override
  String get community_joinTitle => 'Worden lid van de community';

  @override
  String community_joinConfirmation(String name) {
    return 'Wil je je aansluiten bij de community \"$name\"?';
  }

  @override
  String get community_scanQr => 'Scan Gemeenschap QR';

  @override
  String get community_scanInstructions =>
      'Richt de camera op een gemeenschappelijke QR-code';

  @override
  String get community_showQr => 'Toon QR-code';

  @override
  String get community_publicChannel => 'Gemeenschap Openbaar';

  @override
  String get community_hashtagChannel => 'Gemeenschappelijk Hashtag';

  @override
  String get community_name => 'Gemeenschapnaam';

  @override
  String get community_enterName => 'Voer de gemeenschapsnaam in';

  @override
  String community_created(String name) {
    return 'Gemeenschap \"$name\" is aangemaakt';
  }

  @override
  String community_joined(String name) {
    return 'Gevonden in de community \"$name\"';
  }

  @override
  String get community_qrTitle => 'Deel Gemeenschap';

  @override
  String community_qrInstructions(String name) {
    return 'Scan deze QR-code om je aan te sluiten bij $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Community hashtag-kanalen zijn alleen toegankelijk voor leden van de community';

  @override
  String get community_invalidQrCode => 'Ongeldige community QR-code';

  @override
  String get community_alreadyMember => 'Alleen al lid';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'U bent al lid van \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Voeg een Openbaar Gemeenschapskanaal toe';

  @override
  String get community_addPublicChannelHint =>
      'Automatisch de publieke kanaal toevoegen voor deze community';

  @override
  String get community_noCommunities =>
      'Nog geen gemeenschappen zijn bijgesloten.';

  @override
  String get community_scanOrCreate =>
      'Scan een QR-code of een community aanmaken om te beginnen';

  @override
  String get community_manageCommunities => 'Beheer Gemeenschappen';

  @override
  String get community_delete => 'Laat Gemeenschap';

  @override
  String community_deleteConfirm(String name) {
    return '\"$name\" verlaten?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Dit verwijdert ook $count kanaal/kanalen en hun berichten.';
  }

  @override
  String community_deleted(String name) {
    return 'Community \"$name\" verlaten';
  }

  @override
  String get community_regenerateSecret => 'Regeneer Geheimwoord';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regeneere de geheime sleutel voor \"$name\"? Alle leden moeten de nieuwe QR-code scannen om verder te communiceren.';
  }

  @override
  String get community_regenerate => 'Regeneer';

  @override
  String community_secretRegenerated(String name) {
    return 'Geheim hersteld voor \"$name\"';
  }

  @override
  String get community_updateSecret => 'Bijwerken Geheime';

  @override
  String community_secretUpdated(String name) {
    return 'Geheim gewijzigd voor \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scan de nieuwe QR-code om het geheim voor \"$name\" bij te werken';
  }

  @override
  String get community_addHashtagChannel => 'Voeg Community Hashtag toe';

  @override
  String get community_addHashtagChannelDesc =>
      'Voeg een hashtag-kanaal toe aan deze community';

  @override
  String get community_selectCommunity => 'Selecteer Gemeenschap';

  @override
  String get community_regularHashtag => 'Gewone Hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Open hashtag (iedereen kan deelnemen)';

  @override
  String get community_communityHashtag => 'Gemeenschappelijk Hashtag';

  @override
  String get community_communityHashtagDesc =>
      'Alleen zichtbaar voor leden van de community';

  @override
  String community_forCommunity(String name) {
    return 'Voor $name';
  }

  @override
  String get listFilter_tooltip => 'Filteren en sorteren';

  @override
  String get listFilter_sortBy => 'Sorteren door';

  @override
  String get listFilter_latestMessages => 'Recente berichten';

  @override
  String get listFilter_heardRecently => 'Recent gezien';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filters';

  @override
  String get listFilter_source => 'Bron';

  @override
  String get listFilter_saved => 'Opgeslagen';

  @override
  String get listFilter_discovered => 'Ontdekt';

  @override
  String get listFilter_all => 'Alles';

  @override
  String get listFilter_favorites => 'Favorieten';

  @override
  String get listFilter_addToFavorites => 'Toevoegen aan favorieten';

  @override
  String get listFilter_removeFromFavorites => 'Verwijderen uit favorieten';

  @override
  String get listFilter_users => 'Gebruikers';

  @override
  String get listFilter_repeaters => 'Repeaters';

  @override
  String get listFilter_roomServers => 'Roomservers';

  @override
  String get listFilter_unreadOnly => 'Alleen ongelezen';

  @override
  String get listFilter_newGroup => 'Nieuwe groep';

  @override
  String get pathTrace_you => 'Jij';

  @override
  String get pathTrace_failed => 'Padtrace mislukt.';

  @override
  String get pathTrace_notAvailable => 'Padtrace niet beschikbaar.';

  @override
  String get pathTrace_refreshTooltip => 'Path Trace vernieuwen.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Een of meer van de hops ontbreken een locatie!';

  @override
  String get pathTrace_clearTooltip => 'Weg wissen';

  @override
  String get losSelectStartEnd =>
      'Selecteer begin- en eindknooppunten voor LOS.';

  @override
  String losRunFailed(String error) {
    return 'Zichtlijncontrole mislukt: $error';
  }

  @override
  String get losClearAllPoints => 'Wis alle punten';

  @override
  String get losRunToViewElevationProfile =>
      'Voer LOS uit om het hoogteprofiel te bekijken';

  @override
  String get losMenuTitle => 'LOS-menu';

  @override
  String get losMenuSubtitle =>
      'Tik op knooppunten of druk lang op de kaart voor aangepaste punten';

  @override
  String get losShowDisplayNodes => 'Toon weergaveknooppunten';

  @override
  String get losCustomPoints => 'Aangepaste punten';

  @override
  String losCustomPointLabel(int index) {
    return 'Aangepast $index';
  }

  @override
  String get losPointA => 'Punt A';

  @override
  String get losPointB => 'Punt B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenne A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenne B: $value $unit';
  }

  @override
  String get losRun => 'Voer LOS uit';

  @override
  String get losNoElevationData => 'Geen hoogtegegevens';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, vrije LOS, min. vrije ruimte $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, geblokkeerd door $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: controleren...';

  @override
  String get losStatusNoData => 'LOS: geen gegevens';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total gewist, $blocked geblokkeerd, $unknown onbekend';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Hoogtegegevens niet beschikbaar voor een of meer monsters.';

  @override
  String get losErrorInvalidInput =>
      'Ongeldige punten/hoogtegegevens voor LOS-berekening.';

  @override
  String get losRenameCustomPoint => 'Hernoem aangepast punt';

  @override
  String get losPointName => 'Puntnaam';

  @override
  String get losShowPanelTooltip => 'Toon LOS-paneel';

  @override
  String get losHidePanelTooltip => 'LOS-paneel verbergen';

  @override
  String get losElevationAttribution =>
      'Hoogtegegevens: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Radiohorizon';

  @override
  String get losLegendLosBeam => 'Zichtlijn';

  @override
  String get losLegendTerrain => 'Terrein';

  @override
  String get losFrequencyLabel => 'Frequentie';

  @override
  String get losFrequencyInfoTooltip => 'Bekijk details van de berekening';

  @override
  String get losFrequencyDialogTitle => 'Berekening van de radiohorizon';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Beginnend met k=$baselineK bij $baselineFreq MHz, wordt bij de berekening de k-factor aangepast voor de huidige $frequencyMHz MHz-band, die de gebogen radiohorizonkap definieert.';
  }

  @override
  String get contacts_pathTrace => 'Pad Traceren';

  @override
  String get contacts_ping => 'Pingen';

  @override
  String get contacts_repeaterPathTrace => 'Pad traceren naar repeater';

  @override
  String get contacts_repeaterPing => 'Ping repeater';

  @override
  String get contacts_roomPathTrace => 'Padtrace naar room server';

  @override
  String get contacts_roomPing => 'Ping kamer server';

  @override
  String get contacts_chatTraceRoute => 'Route traceren';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Trace route to $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Knipbord is leeg.';

  @override
  String get contacts_invalidAdvertFormat => 'Ongeldige contactgegevens';

  @override
  String get contacts_contactImported => 'Contact is geïmporteerd.';

  @override
  String get contacts_contactImportFailed =>
      'Contact kon niet geïmporteerd worden.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name staat al in je contacten.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Zero Hop Reclame';

  @override
  String get contacts_floodAdvert => 'Overstromingsadvertentie';

  @override
  String get contacts_copyAdvertToClipboard => 'Advert naar klembord kopiëren';

  @override
  String get contacts_addContactFromClipboard =>
      'Contact uit klembord toevoegen';

  @override
  String get contacts_ShareContact => 'Contact naar Klembord kopiëren';

  @override
  String get contacts_ShareContactZeroHop => 'Contact delen via advertentie';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Contact verzonden via advertentie';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Mislukt om contact te verzenden';

  @override
  String get contacts_contactAdvertCopied =>
      'Reclame gekopieerd naar Klembord.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopiëren van advertentie naar Clipboard is mislukt.';

  @override
  String get contacts_addContact => 'Contact toevoegen';

  @override
  String get contacts_scanQrCode => 'Contact-QR scannen';

  @override
  String get contacts_scanQrCodeDesc =>
      'Scan een contact-QR-code uit de MeshCore-app';

  @override
  String get contacts_enterIdHash => 'Contact handmatig invoeren';

  @override
  String get contacts_enterIdHashDesc =>
      'Plak een contactadvertentie of meshcore://-link';

  @override
  String get contacts_advertHint => 'meshcore://... of openbare sleutel in hex';

  @override
  String get contacts_import => 'Importeren';

  @override
  String get contacts_scanContactInstructions =>
      'Scan een MeshCore-contact-QR-code';

  @override
  String get notification_activityTitle => 'MeshCore Activiteit';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'berichten',
      one: 'bericht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kanaalberichten',
      one: 'kanaalbericht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nieuwe knooppunten',
      one: 'nieuw knooppunt',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nieuw $contactType ontdekt';
  }

  @override
  String get notification_receivedNewMessage => 'Nieuw bericht ontvangen';

  @override
  String get settings_gpxExportRepeaters =>
      'Exporteer repeaters / roomserver naar GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporteert repeaters / roomserver met een locatie naar GPX-bestand.';

  @override
  String get settings_gpxExportContacts => 'Companions exporteren naar GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporteert metgezellen met een locatie naar een GPX-bestand.';

  @override
  String get settings_gpxExportAll => 'Alle contacten exporteren naar GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporteert alle contacten met een locatie naar een GPX-bestand.';

  @override
  String get settings_gpxExportSuccess => 'Succesvol GPX-bestand geëxporteerd.';

  @override
  String get settings_gpxExportNoContacts => 'Geen contacten om te exporteren.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Niet ondersteund op uw apparaat/besturingssysteem';

  @override
  String get settings_gpxExportError => 'Er was een fout bij het exporteren.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Repeater- en kamer servers locaties';

  @override
  String get settings_gpxExportChat => 'Locaties van metgezellen';

  @override
  String get settings_gpxExportAllContacts => 'Alle contactlocaties';

  @override
  String get settings_gpxExportShareText =>
      'Kaartgegevens geëxporteerd uit MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax GPX kaartgegevens exporteren';

  @override
  String get snrIndicator_nearByRepeaters => 'Nabije herhalingseenheden';

  @override
  String get snrIndicator_lastSeen => 'Laatst gezien';

  @override
  String get contactsSettings_title => 'Instellingen voor contacten';

  @override
  String get contactsSettings_autoAddTitle => 'Automatische detectie';

  @override
  String get contactsSettings_otherTitle =>
      'Andere instellingen voor contactgerelateerde zaken';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Gebruikers automatisch toevoegen';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Sta toe dat de companion automatisch ontdekte gebruikers toevoegt';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automatisch herhalingstoestellen toevoegen';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Sta toe dat de companion automatisch ontdekte repeaters toevoegt';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automatisch kamerservers toevoegen';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Sta toe dat de companion automatisch ontdekte kamer servers toevoegt.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automatisch sensoren toevoegen';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Sta toe dat de companion automatisch ontdekte sensoren toevoegt';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Overschrijf Oudste';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Wanneer de contactenlijst vol is, wordt de oudste niet-favoriete contactpersoon vervangen.';

  @override
  String get discoveredContacts_Title => 'Ontdekte contacten';

  @override
  String get discoveredContacts_noMatching => 'Geen overeenkomende contacten';

  @override
  String get listFilter_searchHint => 'Zoeken...';

  @override
  String get discoveredContacts_searchHint => 'Ontdekte contacten zoeken';

  @override
  String get discoveredContacts_contactAdded => 'Contact toegevoegd';

  @override
  String get discoveredContacts_addContact => 'Contact toevoegen';

  @override
  String get discoveredContacts_copyContact => 'Kopieer contact naar klembord';

  @override
  String get discoveredContacts_deleteContact => 'Contact verwijderen';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Verwijder alle ontdekte contacten';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Weet u zeker dat u alle ontdekte contacten wilt verwijderen?';

  @override
  String get chat_sendCooldown =>
      'Gelieve even te wachten voordat u opnieuw verzendt.';

  @override
  String get chat_notConnected =>
      'Niet verbonden met een radio. Bericht niet verzonden.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Ga naar het oudste ongelezen bericht';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Bij het openen van een chat met ongelezen berichten, scroll dan naar het eerste ongelezen bericht, in plaats van naar het meest recente.';

  @override
  String get appSettings_languageHu => 'Hongaars';

  @override
  String get appSettings_languageJa => 'Japanisch';

  @override
  String get appSettings_languageKo => 'Koreaans';

  @override
  String get radioStats_screenTitle => 'Statistieken over radio';

  @override
  String get radioStats_notConnected =>
      'Verbind met een apparaat om radio-statistieken te bekijken.';

  @override
  String get radioStats_firmwareTooOld =>
      'Om de statistieken via radio te kunnen gebruiken, is firmware versie 8 of een nieuwere vereist.';

  @override
  String get radioStats_waiting => 'Wacht op gegevens…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Ruisfrequentie: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Laatste RSSI-waarde: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Laatste SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'TX-tijd (totaal): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Tijd besteed met RX (totaal): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Ruisfrequentie (dBm) over recente metingen.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Ruisfrequentie: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Radio-statistieken ophalen…';

  @override
  String get radioStats_settingsTile => 'Statistieken over radio';

  @override
  String get radioStats_settingsSubtitle =>
      'Ruimtelijke ruis, RSSI, SNR en beschikbare tijd';

  @override
  String get translation_title => 'Vertaling';

  @override
  String get translation_enableTitle => 'Activeer vertaling';

  @override
  String get translation_enableSubtitle =>
      'Vertaal inkomende berichten en maak het mogelijk om berichten vooraf te vertalen.';

  @override
  String get translation_composerTitle => 'Vertaal voor verzending';

  @override
  String get translation_composerSubtitle =>
      'Stelt de standaardstatus van het pictogram voor de vertaling van de componist in.';

  @override
  String get translation_targetLanguage => 'Doeltaal';

  @override
  String get translation_useAppLanguage => 'Gebruik de taal van de app';

  @override
  String get translation_downloadedModelLabel => 'Gedownloade model';

  @override
  String get translation_presetModelLabel =>
      'Voorgeprogrammeerd Hugging Face-model';

  @override
  String get translation_manualUrlLabel => 'URL van de handleiding';

  @override
  String get translation_downloadModel => 'Download het model';

  @override
  String get translation_downloading => 'Downloaden...';

  @override
  String get translation_working => 'Werken...';

  @override
  String get translation_stop => 'Stoppen';

  @override
  String get translation_mergingChunks =>
      'Het samenvoegen van de gedownloade stukken tot één eindbestand...';

  @override
  String get translation_downloadedModels => 'Gedownloade modellen';

  @override
  String get translation_deleteModel => 'Model verwijderen';

  @override
  String get translation_modelDownloaded => 'Vertalingmodel gedownload.';

  @override
  String get translation_downloadStopped => 'Download is afgebroken.';

  @override
  String translation_downloadFailed(String error) {
    return 'Download mislukt: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Voer eerst een URL van een model in.';

  @override
  String get scanner_linuxPairingShowPin => 'Toon PIN';

  @override
  String get scanner_linuxPairingHidePin => 'PIN verbergen';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth‑koppelings‑PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Voer PIN in voor $deviceName (laat leeg als er geen is).';
  }

  @override
  String get translation_messageTranslation => 'Berichtvertaling';

  @override
  String get translation_translateBeforeSending => 'Vertaal voor verzending';

  @override
  String get translation_composerEnabledHint =>
      'De berichten worden vertaald voordat ze verzonden worden.';

  @override
  String get translation_composerDisabledHint =>
      'Stuur berichten in de oorspronkelijke, getypte taal.';

  @override
  String translation_translateTo(String language) {
    return 'Vertalen naar $language';
  }

  @override
  String get translation_translationOptions => 'Opties voor vertaling';

  @override
  String get translation_systemLanguage => 'Taal van het systeem';

  @override
  String get routing_title => 'Routering';

  @override
  String routing_route(String route) {
    return 'Opgeslagen pad: $route';
  }

  @override
  String get routing_noRoute =>
      'nog geen — het volgende bericht gaat als flood en leert er een';

  @override
  String get routing_auto => 'Automatisch';

  @override
  String get routing_autoSubtitle =>
      'Gebruik het opgeslagen pad van de radio. Aanbevolen.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder aan: probeert eerst geleerde routes';

  @override
  String get routing_flood => 'Altijd flood';

  @override
  String get routing_floodSubtitle => 'Elk bericht gaat naar de hele mesh';

  @override
  String get routing_custom => 'Eigen pad';

  @override
  String get routing_customSubtitle => 'Kies zelf de repeaters';

  @override
  String get routing_forget => 'Pad resetten';

  @override
  String get routing_forgetDone =>
      'Pad gereset. Het volgende bericht gaat als flood en leert een nieuw pad.';

  @override
  String get routing_pathfinder => 'Wat Pathfinder weet';

  @override
  String get routing_pathfinderSubtitle =>
      'Repeaters die jou en hen horen, en geleerde routes heen en terug';

  @override
  String get path_direct => 'Direct — geen repeaters';

  @override
  String get path_directSubtitle =>
      'Alleen als het contact deze radio zelf kan horen';

  @override
  String get chat_kindFlood => 'flood';

  @override
  String get chat_kindDirect => 'direct';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'route ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hops',
      one: 'hop',
    );
    return 'route ($count $_temp0, waarvan $guessed gegokt)';
  }

  @override
  String get chat_statusQueued => 'In wachtrij';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Geen repeater heeft je gehoord. Er wordt opnieuw geprobeerd zodra er een binnen bereik is.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'De radio van $name stuurt korte repeatercodes (1 byte). Pathfinder kan geen routes naar hen leren tot hun radio 2-byte-codes gebruikt.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Verzenden · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Opnieuw proberen · $kind · poging $attempt van $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Afgeleverd · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Afgeleverd bij poging $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Laat afgeleverd · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Afgeleverd · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'pogingen',
      one: 'poging',
    );
    return 'Mislukt na $attempts $_temp0 · tik om opnieuw te sturen';
  }

  @override
  String get chat_statusFailedShort => 'Mislukt · tik om opnieuw te sturen';

  @override
  String get chat_resendingByFlood => 'Opnieuw verzenden via flood';

  @override
  String get pathfinderHelp_title => 'Wat Pathfinder doet';

  @override
  String get pathfinderHelp_what =>
      'Je radio onthoudt één route naar elk contact. Werkt die route niet, dan gaat je bericht als flood naar de hele mesh. Pathfinder luistert naar alles wat de radio hoort: aankondigingen van repeaters, gesprekken in kanalen, berichten van anderen. Daarmee bouwt Pathfinder een kaart: welke repeaters elkaar horen, welke jou horen en welke elk van je contacten horen.';

  @override
  String get pathfinderHelp_how =>
      'Als je een bericht stuurt, probeert Pathfinder eerst de beste route, daarna de op één na beste, en valt pas als laatste redmiddel terug op flood. Een amberkleurig padpictogram markeert een bericht dat via een Pathfinder-route is verzonden.';

  @override
  String get pathfinderHelp_learning =>
      'Het kost tijd. Een nieuwe kaart is nog leeg, dus in het begin worden je berichten precies zoals voorheen verstuurd. Na een paar uur luisteren op één plek begint Pathfinder routes aan te bieden, en elk bericht dat aankomt of mislukt, maakt de kaart beter. Verwacht er de eerste dag weinig van, en telkens als je op een nieuwe plek bent, eerst weer minder.';

  @override
  String get pathfinderHelp_guessed =>
      'Soms vult Pathfinder een gat op met een gok: een verbinding die tot nu toe alleen in de andere richting is gehoord. De statusregel onder het bericht toont dan hoeveel hops gegokt zijn. Komt het bericht aan, dan zijn ze bevestigd; mislukt het, dan kost dat één poging en wordt er niets onthouden.';

  @override
  String get pathfinderHelp_discover =>
      'Is het niet duidelijk welke repeaters je hier kunnen horen, dan stuurt Pathfinder één kort Discover-verzoek (hooguit eens per 10 minuten, en alleen nadat een bericht is mislukt). Heeft je radio GPS, dan onthoudt Pathfinder op deze telefoon per gebied van ongeveer 500 m welke repeaters je daar hebben gehoord, maar nooit je precieze locatie.';

  @override
  String get pathfinderHelp_off =>
      'Zet je Pathfinder uit, dan routeert de radio weer precies zoals voorheen.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Niet meer tonen';

  @override
  String get pathfinderHelp_ok => 'OK';

  @override
  String get settings_pathGraph => 'Pathfinder (experimenteel)';

  @override
  String get settings_pathGraphSubtitle =>
      'Leert routes uit alles wat de radio hoort en probeert de beste eerst als je een DM stuurt. Een amberkleurig padpictogram markeert een bericht dat via een Pathfinder-route is verzonden.';

  @override
  String get map_routeAndTrace => 'Route & traceren';

  @override
  String get map_pathfinderTrace => 'Heen en terug traceren';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Heen via de beste route van Pathfinder, terug via de beste terugroute';

  @override
  String get map_routeBackMirrored =>
      'Nog geen terugroute bekend — terug via dezelfde weg';

  @override
  String get map_traceHelpTitle => 'Knoppen voor padtrace';

  @override
  String get map_traceHelpCustom => 'Typ of kies zelf de repeaters.';

  @override
  String get map_traceHelpRun =>
      'Stuurt een trace langs de repeaters die je hebt aangetikt, in één richting.';

  @override
  String get map_traceHelpThereAndBack => 'Heen en terug';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Stuurt de trace heen en daarna in omgekeerde volgorde terug over dezelfde repeaters.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder kiest de beste route via de laatste twee repeaters die je hebt aangetikt, en de beste route terug naar jou. Het resultaat leert Pathfinder welke verbindingen echt werken. Er moeten twee repeaters aangetikt zijn.';

  @override
  String get map_traceHelpRemoveLast =>
      'Haalt de laatste repeater van het pad.';

  @override
  String get map_traceHelpCancel =>
      'Stopt met het opbouwen van de trace. Zichtbaar voordat er een repeater is aangetikt.';

  @override
  String get chat_resendingByRoute =>
      'Opnieuw verzenden via de ingestelde route';

  @override
  String get room_mute => 'Ruimte dempen';

  @override
  String get room_unmute => 'Dempen van ruimte opheffen';

  @override
  String get room_roleAdmin => 'beheerder';

  @override
  String get room_roleMember => 'lid';

  @override
  String get room_roleReadOnly => 'alleen-lezen';

  @override
  String room_clockOff(int minutes) {
    return 'De klok van de ruimte wijkt ongeveer $minutes min af — berichttijden kunnen fout zijn';
  }

  @override
  String get room_fixClock => 'Klok corrigeren';

  @override
  String get room_clockSyncSent => 'Kloksynchronisatie naar de ruimte gestuurd';

  @override
  String get room_readOnlyNotice =>
      'Alleen-lezen: de ruimte heeft je wachtwoord niet geaccepteerd, je berichten bereiken andere leden niet.';

  @override
  String get room_postAnnouncement => 'Aankondiging plaatsen';

  @override
  String get room_postAnnouncementSubtitle =>
      'Stuur een bericht namens de ruimte zelf naar alle leden';

  @override
  String get room_announcementSent => 'Aankondiging geplaatst';

  @override
  String get room_announcementFailed => 'Plaatsen van aankondiging mislukt';

  @override
  String get room_users => 'Gebruikers van de ruimte';

  @override
  String get room_usersSubtitle => 'Bekijk beheerders en stel rollen in';

  @override
  String get room_usersAdminsNote =>
      'De ruimte toont alleen beheerders. Leden met het ruimtewachtwoord staan er niet bij.';

  @override
  String get room_usersLoadFailed => 'Beheerderslijst kon niet worden geladen';

  @override
  String get room_setUserRole => 'Rol instellen';

  @override
  String get room_removeAccess => 'Toegang verwijderen';

  @override
  String get room_removeOnlyUnknown =>
      'Deze gebruiker staat niet in je contacten en kan alleen worden verwijderd, niet gewijzigd.';

  @override
  String get room_roleUpdated => 'Rol bijgewerkt';

  @override
  String get room_roleUpdateFailed => 'Rol wijzigen mislukt';

  @override
  String get room_postsStored => 'Opgeslagen berichten';

  @override
  String get room_postsDelivered => 'Bezorgde berichten';

  @override
  String get room_reloadPosts => 'Recente berichten opnieuw laden';

  @override
  String get room_reloadPostsExplain =>
      'Vraagt de ruimte om recente berichten opnieuw te sturen (maximaal 32). Je wordt om het ruimtewachtwoord gevraagd. Bestaande berichten blijven bewaard.';

  @override
  String get room_reloadFailed => 'Kon de ruimte niet resetten op de radio';

  @override
  String get companionCli_title => 'Opdrachtregel';

  @override
  String get companionCli_settingsSubtitle =>
      'Typ tekstopdrachten voor deze radio';

  @override
  String get companionCli_rebooting => 'Radio wordt herstart…';

  @override
  String get companionCli_cancelled => 'Geannuleerd';

  @override
  String get companionCli_poweringOff => 'Radio wordt uitgeschakeld…';

  @override
  String get companionCli_noReply =>
      'Geen antwoord van de radio. Probeer het opnieuw.';

  @override
  String get companionCli_powerOffTitle => 'Radio uitschakelen?';

  @override
  String get companionCli_powerOffBody =>
      'Hij blijft uit tot je op de knop drukt of hem aansluit.';

  @override
  String get companionCli_powerOff => 'Uitschakelen';

  @override
  String get companionCli_quickBoard => 'Bord';

  @override
  String get companionCli_quickWifiStatus => 'Wifistatus';

  @override
  String get companionCli_quickWifiAddress => 'Wifiadres';

  @override
  String get companionCli_helpBoard => 'Toont fabrikant en model van het bord.';

  @override
  String get companionCli_helpReboot => 'Herstart de radio.';

  @override
  String get companionCli_helpPowerOff => 'Schakelt de radio uit.';

  @override
  String get companionCli_helpSetPin =>
      'Stelt de Bluetooth-koppelings-PIN in. Werkt na een herstart.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Stelt in hoeveel uur bij UTC wordt opgeteld voor de klok op het eigen scherm van de radio (-12 tot +14).';

  @override
  String get companionCli_helpSetTx =>
      'Stelt het zendvermogen in dBm in. Werkt meteen.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Stelt de storingsdrempel in dB in. 0 schakelt storingsdetectie uit.';

  @override
  String get companionCli_helpSetCad =>
      'Luistert naar andere radio\'s voordat hij zendt (kanaalactiviteitsdetectie).';

  @override
  String get companionCli_helpSetRxGain =>
      'Verhoogde ontvangstversterking, op SX126x-radio\'s.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bytes per repeater in een route: 0 = 1 byte, 1 = 2 bytes, 2 = 3 bytes.';

  @override
  String get companionCli_helpWifiStatus =>
      'Toont of de radio op het wifinetwerk zit.';

  @override
  String get companionCli_helpWifiIp =>
      'Toont het adres van de radio op het wifinetwerk.';

  @override
  String get companionCli_helpWifiSsid =>
      'Stelt de naam van het wifinetwerk in. Werkt na een herstart.';

  @override
  String get companionCli_helpWifiPwd =>
      'Stelt het wifiwachtwoord in. Werkt na een herstart.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Zet wifi aan (1) of uit (0). Werkt na een herstart.';

  @override
  String get companionCli_helpWifiClear =>
      'Vergeet het wifinetwerk. Werkt na een herstart.';

  @override
  String get companionCli_remoteNoReply =>
      'Geen antwoord. De andere radio heeft firmware 1.18 of nieuwer nodig en moet je toestaan zijn opdrachtregel te gebruiken.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Verzonden. Een radio antwoordt niet op herstarten of uitschakelen.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name probeerde de opdrachtregel van je radio te gebruiken: “$command”. Dat werd niet toegestaan.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Probeerde de opdrachtregel van je radio te gebruiken: “$command”. Dat werd niet toegestaan.';
  }

  @override
  String get contact_remoteCli => 'Opdrachtregel op afstand toestaan';

  @override
  String get contact_remoteCliSubtitle =>
      'Laat dit contact opdrachten uitvoeren op je radio';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return '$name je radio laten bedienen?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name kan dan de instellingen van je radio wijzigen, je wifiwachtwoord lezen, je radio hernoemen en hem herstarten of uitschakelen. Sta dit alleen toe voor iemand die je volledig vertrouwt.';
  }

  @override
  String get contact_remoteCliAllow => 'Toestaan';

  @override
  String get connection_secondApp =>
      'Een andere app is met deze radio verbonden. Berichten en instellingen kunnen door elkaar raken. Sluit de andere app.';

  @override
  String get wifi_title => 'Wifi';

  @override
  String get wifi_settingsSubtitle => 'Netwerk, wachtwoord en verbinding';

  @override
  String get wifi_use => 'Wifi gebruiken';

  @override
  String get wifi_networkName => 'Netwerknaam';

  @override
  String get wifi_password => 'Wachtwoord';

  @override
  String get wifi_passwordUnchanged => 'Ongewijzigd';

  @override
  String get wifi_showPassword => 'Wachtwoord tonen';

  @override
  String get wifi_nameMissing => 'Voer de netwerknaam in';

  @override
  String get wifi_nameTooLong =>
      'De netwerknaam is te lang (maximaal 32 bytes)';

  @override
  String get wifi_passwordTooLong =>
      'Het wachtwoord is te lang (maximaal 63 bytes)';

  @override
  String get wifi_savedRestart =>
      'Opgeslagen. Wifi-wijzigingen werken na een herstart van de radio.';

  @override
  String get wifi_forget => 'Netwerk vergeten';

  @override
  String get wifi_forgetConfirm =>
      'Dit wifinetwerk vergeten? Na de herstart gebruikt de radio geen wifi meer.';

  @override
  String wifi_notAccepted(String reply) {
    return 'De radio accepteerde dat niet: $reply';
  }

  @override
  String get wifi_noReply => 'Geen antwoord van de radio. Probeer het opnieuw.';

  @override
  String get wifi_restartTitle => 'Radio herstarten?';

  @override
  String get wifi_later => 'Later';

  @override
  String get wifi_loadFailed =>
      'Kon de wifi-instellingen niet van de radio lezen.';

  @override
  String wifi_connectedTo(String address) {
    return 'Verbonden · $address';
  }

  @override
  String get wifi_notConnected => 'Niet verbonden met wifi';

  @override
  String wifi_portNote(int port) {
    return 'Apps op hetzelfde netwerk kunnen verbinden via poort $port';
  }

  @override
  String get wifi_connectOverWifi => 'Verbinden via wifi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax verbreekt de verbinding met deze radio en opent het TCP-scherm met $address, poort $port al ingevuld. Tik daar op Verbinden.';
  }

  @override
  String get wifi_noteRestart =>
      'Wijzigingen werken na een herstart van de radio.';

  @override
  String get wifi_noteSecurity =>
      'Iedereen op je wifinetwerk kan via poort 5000 met de radio verbinden. Daar is geen wachtwoord voor.';

  @override
  String get wifi_noteBattery =>
      'Wifi houdt de radio wakker, dus de batterij raakt sneller leeg.';

  @override
  String get wifi_noteWrongPassword =>
      'Als het wachtwoord fout is, blijft de radio het om de paar seconden proberen. Bluetooth blijft werken.';

  @override
  String get room_selfDemoteWarning =>
      'Je wijzigt je eigen toegang. Als je je beheerdersrol opgeeft, kan alleen de console van de ruimte die teruggeven.';

  @override
  String get scanner_offlineMaps => 'Offline kaarten';

  @override
  String get appSettings_offlineMaps => 'Offline kaarten';

  @override
  String get appSettings_offlineMapsNone => 'Niets gedownload';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regio\'s',
      one: '1 regio',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zeekaartgebieden',
      one: '1 zeekaartgebied',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count updates beschikbaar',
      one: '1 update beschikbaar',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Kaarten alleen via wifi downloaden';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Kaartdownloads wachten op een wifiverbinding';

  @override
  String get offlineMaps_title => 'Offline kaarten';

  @override
  String get offlineMaps_tabMaps => 'Kaarten';

  @override
  String get offlineMaps_tabCharts => 'Zeekaarten';

  @override
  String get offlineMaps_chartsNotice => 'Niet voor navigatie · Waarom?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Voorgesteld · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Zeekaartgebieden per kust';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gebieden',
      one: '1 gebied',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '$count gedownload';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '$count geselecteerd';
  }

  @override
  String get offlineMaps_selectAll => 'Alles selecteren';

  @override
  String get offlineMaps_clearSelection => 'Wissen';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Ook in $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Nog niet beschikbaar';

  @override
  String get offlineMaps_chartsHint =>
      'NOAA-zeekaarten kies je per kust, op het tabblad Zeekaarten.';

  @override
  String offlineMaps_chartsName(String area) {
    return 'NOAA-zeekaarten $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gebieden',
      one: '1 gebied',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Gedownload';

  @override
  String get offlineMaps_refresh => 'Zoeken naar nieuwe kaarten';

  @override
  String get offlineMaps_loading => 'Beschikbare kaarten laden…';

  @override
  String get offlineMaps_serverError => 'Kaartserver niet bereikbaar';

  @override
  String get offlineMaps_unavailable => 'Nog geen kaarten beschikbaar';

  @override
  String get offlineMaps_unavailableHint => 'Kijk later nog eens.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Nog geen NOAA-zeekaarten beschikbaar';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Lijst van $date wordt getoond';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Werk MeshTrax bij om de nieuwste kaarten te krijgen.';

  @override
  String get offlineMaps_world => 'Wereld';

  @override
  String get offlineMaps_suggested => 'Voorgesteld';

  @override
  String get offlineMaps_regions => 'Regio\'s';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regio\'s in $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count binnenin';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size aan offline kaarten op dit apparaat';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Updates ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Alles bijwerken $size';
  }

  @override
  String get offlineMaps_downloading => 'Downloaden';

  @override
  String get offlineMaps_update => 'Bijwerken';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Gedownload op $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Update beschikbaar';

  @override
  String get offlineMaps_otherFiles => 'Andere kaartbestanden';

  @override
  String get offlineMaps_emptyTitle => 'Nog geen offline kaarten';

  @override
  String get offlineMaps_emptyBody =>
      'Download een regio om de kaart zonder verbinding te gebruiken.';

  @override
  String get offlineMaps_findMaps => 'Kaarten zoeken';

  @override
  String offlineMaps_deleteTitle(String name) {
    return '$name verwijderen?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Dit maakt $size vrij. Je kunt het later opnieuw downloaden.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name verwijderd';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done van $total';
  }

  @override
  String get offlineMaps_kindMap => 'Kaart';

  @override
  String get offlineMaps_kindMapDetail =>
      'OpenStreetMap: straten, paden, plaatsen';

  @override
  String get offlineMaps_kindContours => 'Hoogtelijnen';

  @override
  String get offlineMaps_kindContoursDetail => 'Lijnen van gelijke hoogte';

  @override
  String get offlineMaps_kindUsgs => 'USGS-topokaart';

  @override
  String get offlineMaps_kindUsgsDetail => 'Paden, beken, reservaten';

  @override
  String get offlineMaps_kindTerrain => 'Reliëfschaduw';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Heuvels en bergen, met schaduw onder de kaart';

  @override
  String get offlineMaps_kindCharts => 'NOAA-zeekaarten';

  @override
  String get offlineMaps_usOnly => 'Alleen Verenigde Staten';

  @override
  String offlineMaps_download(String size) {
    return '$size downloaden';
  }

  @override
  String get offlineMaps_downloadTotal => 'Downloaden';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Grote download ($size). Gebruik wifi en laat je apparaat opladen.';
  }

  @override
  String get offlineMaps_waiting => 'Wachten…';

  @override
  String get offlineMaps_checking => 'Download controleren…';

  @override
  String get offlineMaps_retrying => 'Opnieuw proberen…';

  @override
  String offlineMaps_failed(String error) {
    return 'Download mislukt: $error';
  }

  @override
  String get offlineMaps_pause => 'Pauzeren';

  @override
  String get offlineMaps_resume => 'Hervatten';

  @override
  String get offlineMaps_deleteRegion => 'Regio verwijderen';

  @override
  String get offlineMaps_notInCatalogue => 'Niet beschikbaar voor deze regio';

  @override
  String get offlineMaps_notificationRunning => 'Kaart downloaden';

  @override
  String get offlineMaps_notificationPaused => 'Kaartdownload gepauzeerd';

  @override
  String get offlineMaps_notificationFailed => 'Kaartdownload mislukt';

  @override
  String get offlineMaps_clearTileCache => 'Gecachte online kaarttegels wissen';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'De online kaarttegels verwijderen die tijdens het bekijken zijn opgeslagen? Gedownloade kaarten blijven staan.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Gecachte online kaarttegels verwijderd';

  @override
  String get map_notForNavigation => 'Niet voor navigatie';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax tekent deze kaarten uit de zeekaartgegevens van NOAA, zodat je het water rond je radio\'s kunt zien en plannen. Het zijn geen officiële zeekaarten. Navigeer er niet op.';

  @override
  String get map_chartsNoticeWhy => 'Waarom:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Ze raken verouderd. NOAA corrigeert zijn zeekaarten voortdurend; een gedownloade kaart blijft zoals hij is tot je hem bijwerkt in Offline kaarten.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Ze laten dingen weg. Veel kaartsymbolen, lichtsectoren en aantekeningen worden niet getekend, en sommige labels verschijnen pas als je inzoomt.';

  @override
  String get map_chartsNoticePositions =>
      'Posities kunnen fout of oud zijn. GPS kan 10 m (30 ft) of meer afwijken, en een node is alleen waar hij zich het laatst meldde.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax is geen gecertificeerde kaartplotter.';

  @override
  String get map_chartsNoticeUse =>
      'Gebruik voor navigatie officiële, actuele NOAA-zeekaarten (op papier, of NOAA-ENC\'s in een gecertificeerde kaartplotter) met de nieuwste Berichten aan Zeevarenden.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail => 'Download een regio voor meer detail';

  @override
  String get map_zoomInForOfflineMap => 'Zoom in om je offline kaart te zien';

  @override
  String get map_noCharts => 'Hier geen zeekaarten';

  @override
  String get map_myLocation => 'Mijn locatie';

  @override
  String get map_zoomIn => 'Inzoomen';

  @override
  String get map_zoomOut => 'Uitzoomen';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS aan';

  @override
  String get gps_off => 'GPS uit';

  @override
  String get gps_onHint => 'De radio werkt zijn positie bij via de GPS.';

  @override
  String get gps_offHint =>
      'Uit spaart de batterij van de radio. Na het aanzetten kan het een paar minuten duren voordat je positie gevonden is.';

  @override
  String get gps_asking => 'Radio wordt gevraagd...';

  @override
  String get gps_noPosition =>
      'Nog geen positie. Buiten kan de eerste een paar minuten duren.';

  @override
  String get gps_position => 'Positie';

  @override
  String get gps_altitude => 'Hoogte';

  @override
  String gps_readAgo(String ago) {
    return '$ago geleden van de radio gelezen';
  }

  @override
  String get gps_turnOnTitle => 'GPS aanzetten?';

  @override
  String get gps_turnOnBody =>
      'De GPS van de radio staat uit. Na het aanzetten kan het een paar minuten duren voordat je positie gevonden is.';

  @override
  String get gps_turnOn => 'Aanzetten';

  @override
  String get gps_notNow => 'Niet nu';

  @override
  String get map_zoomInForCharts => 'Zoom in om je zeekaarten te zien';

  @override
  String map_downloadRegion(String region, String size) {
    return '$region downloaden · $size';
  }

  @override
  String get mapLayers_title => 'Kaartlagen';

  @override
  String get mapLayers_mapType => 'Kaarttype';

  @override
  String get mapLayers_standard => 'Standaard';

  @override
  String get mapLayers_usgs => 'USGS-topo';

  @override
  String get mapLayers_charts => 'Zeekaarten';

  @override
  String get mapLayers_notDownloaded => 'Niet gedownload';

  @override
  String get mapLayers_offlineOnly => 'Alleen offline';

  @override
  String get mapLayers_details => 'Kaartdetails';

  @override
  String get mapLayers_contours => 'Hoogtelijnen';

  @override
  String get mapLayers_hillShading => 'Reliëfschaduw';

  @override
  String get mapLayers_dark => 'Donkere kaart';

  @override
  String get mapLayers_downloadedAreas => 'Gedownloade gebieden';

  @override
  String get mapLayers_nodes => 'Nodes';

  @override
  String get mapLayers_pins => 'Spelden';

  @override
  String get mapLayers_guessed => 'Geschat';

  @override
  String get mapLayers_moreFilters => 'Meer filters';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Laatst gezien, sleutelprefix, overlappingen';

  @override
  String get map_legend => 'Legenda';

  @override
  String get scanner_map => 'Kaart';

  @override
  String get structured_openMap => 'Kaart openen';

  @override
  String get structured_addToCalendar => 'Aan agenda toevoegen';

  @override
  String get structured_details => 'Details';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Evenement';

  @override
  String get structured_notice => 'Mededeling';

  @override
  String get structured_allDay => 'Hele dag';

  @override
  String get structured_calendarFailed => 'Kon de agenda niet openen';

  @override
  String get structured_today => 'Vandaag';

  @override
  String get structured_tomorrow => 'Morgen';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Over $count dagen',
      one: 'Over 1 dag',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Voorbij';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Dag $day van $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dagen',
      one: '1 dag',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Einddatum';

  @override
  String get dialog_eventSameDay => 'Zelfde dag';

  @override
  String get structured_map => 'Kaart';

  @override
  String get structured_navigate => 'Navigeren';

  @override
  String get structured_channel => 'Kanaal';

  @override
  String get structured_contact => 'Contact';

  @override
  String get structured_room => 'Ruimte';

  @override
  String get structured_repeater => 'Repeater';

  @override
  String get structured_sensor => 'Sensor';

  @override
  String get structured_joinChannel => 'Toetreden tot kanaal';

  @override
  String get structured_addContact => 'Contact toevoegen';

  @override
  String get structured_addRoom => 'Ruimte toevoegen';

  @override
  String get structured_addRepeater => 'Repeater toevoegen';

  @override
  String get structured_addSensor => 'Sensor toevoegen';

  @override
  String get structured_open => 'Openen';

  @override
  String get structured_added => 'Toegevoegd';

  @override
  String get tray_add => 'Toevoegen';

  @override
  String get tray_myLocation => 'Mijn locatie';

  @override
  String get tray_pointOnMap => 'Punt op kaart';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Evenement';

  @override
  String get tray_notice => 'Mededeling';

  @override
  String get tray_noRadioPosition =>
      'Je radio heeft nog geen positie. Kies er een op de kaart.';

  @override
  String get dialog_insert => 'Invoegen';

  @override
  String get dialog_eventTitle => 'Titel';

  @override
  String get dialog_eventDate => 'Datum';

  @override
  String get dialog_eventStart => 'Begin';

  @override
  String get dialog_eventEnd => 'Einde';

  @override
  String get dialog_eventNoEnd => 'Geen eindtijd';

  @override
  String get dialog_eventPlace => 'Plaats (optioneel)';

  @override
  String get dialog_pickOnMap => 'Kies op kaart';

  @override
  String get dialog_sosTitle => 'SOS sturen';

  @override
  String get dialog_sosText => 'Wat is er gebeurd?';

  @override
  String get dialog_noticeTitle => 'Mededeling';

  @override
  String get dialog_noticeText => 'Wat moet iedereen weten?';

  @override
  String get dialog_labelTitle => 'Punt op kaart';

  @override
  String get dialog_note => 'Notitie (optioneel)';

  @override
  String get paste_convertLocation =>
      'Lijkt op een kaartlink. Omzetten naar een locatie?';

  @override
  String get paste_convertEvent =>
      'Lijkt op een gedeelde agenda-afspraak. Omzetten naar een evenement?';

  @override
  String get paste_convert => 'Omzetten';

  @override
  String get paste_resolving => 'Link opzoeken…';

  @override
  String get paste_resolveFailed => 'Kon de link niet opzoeken';

  @override
  String get pinned_dismiss => 'Sluiten';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Toetreden tot kanaal $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Je zit al in $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Toegetreden tot $name';
  }

  @override
  String get map_pickPositionHint => 'Tik op de kaart om een positie te kiezen';

  @override
  String get map_legendMesh => 'Mesh';

  @override
  String get chartLegend_title => 'Kaartsymbolen';

  @override
  String get chartLegend_sectionBuoys => 'Boeien en bakens';

  @override
  String get chartLegend_sectionLights => 'Lichten';

  @override
  String get chartLegend_sectionHazards => 'Gevaren';

  @override
  String get chartLegend_sectionTides => 'Getijden en stromingen';

  @override
  String get chartLegend_sectionDepths => 'Diepten en zeebodem';

  @override
  String get chartLegend_sectionAreas => 'Gebieden, vaarbanen en lijnen';

  @override
  String get chartLegend_sectionLandmarks => 'Herkenningspunten';

  @override
  String get chartLegend_sectionAbbreviations => 'Afkortingen';

  @override
  String get chartLegend_chartNo1 => 'Alle kaartsymbolen: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Groene stompe ton';

  @override
  String get chartLegend_portBuoyHint =>
      'Houd hem links als je van zee binnenvaart';

  @override
  String get chartLegend_starboardBuoy => 'Rode spitse ton';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Houd hem rechts bij het binnenvaren: op de terugweg hoort rood rechts';

  @override
  String get chartLegend_junctionBuoy => 'Ton met banden';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Een splitsing van vaargeulen: behandel hem als de kleur van de bovenste band';

  @override
  String get chartLegend_safeWaterBuoy => 'Rood-witte strepen';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Rondom veilig water, vaak bij de ingang van een vaargeul';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Zwart-rode banden';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Een klein gevaar met veilig water eromheen: afstand houden';

  @override
  String get chartLegend_specialBuoy => 'Gele ton';

  @override
  String get chartLegend_specialBuoyHint =>
      'Bijzondere markering, niet om op te sturen: ankerplaats, kabel, onderzoek';

  @override
  String get chartLegend_cardinalBuoy => 'Zwart en geel';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Kardinale markering: passeer aan de kant waarnaar hij genoemd is (zeldzaam in de VS)';

  @override
  String get chartLegend_mooringBuoy => 'Meerboei';

  @override
  String get chartLegend_portBeacon => 'Groen vierkant baken';

  @override
  String get chartLegend_portBeaconHint =>
      'Zoals een groene ton: links houden bij het binnenvaren';

  @override
  String get chartLegend_starboardBeacon => 'Rood driehoekig baken';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Zoals een rode ton: rechts houden bij het binnenvaren';

  @override
  String get chartLegend_otherBeacon => 'Ruitvormig baken';

  @override
  String get chartLegend_otherBeaconHint =>
      'Informatie of een waarschuwing, geen kant van de vaargeul';

  @override
  String get chartLegend_beaconTower => 'Lichttoren of bakenconstructie';

  @override
  String get chartLegend_topmark => 'Topteken';

  @override
  String get chartLegend_topmarkHint =>
      'De vorm boven op een markering vult de betekenis aan';

  @override
  String get chartLegend_light => 'Licht';

  @override
  String get chartLegend_lightHint =>
      'De magenta lichtvlek markeert een licht; het label vertelt hoe het knippert';

  @override
  String get chartLegend_lightExample => 'Groen schitterlicht, elke 4 seconden';

  @override
  String get chartLegend_lightExampleHint =>
      'Label van een licht: karakter, kleur, dan periode';

  @override
  String get chartLegend_lightFixed => 'Vast licht';

  @override
  String get chartLegend_lightFixedHint => 'Een continu brandend licht';

  @override
  String get chartLegend_lightFlashing => 'Schitterlicht';

  @override
  String get chartLegend_lightFlashingHint =>
      'Korte schitteringen, met langere duisternis ertussen';

  @override
  String get chartLegend_lightGroup => 'Groepschitterlicht';

  @override
  String get chartLegend_lightGroupHint =>
      'Schitteringen in groepen, hier 2, dan donker';

  @override
  String get chartLegend_lightComposite => 'Samengestelde groep';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 schitteringen, dan 1: markeert een splitsing van vaargeulen';

  @override
  String get chartLegend_lightQuick => 'Flikkerlicht';

  @override
  String get chartLegend_lightQuickHint => 'Ongeveer één flits per seconde';

  @override
  String get chartLegend_lightIsophase => 'Isofase';

  @override
  String get chartLegend_lightIsophaseHint => 'Even lang licht als donker';

  @override
  String get chartLegend_lightOcculting => 'Onderbroken licht';

  @override
  String get chartLegend_lightOccultingHint => 'Langer aan dan uit';

  @override
  String get chartLegend_lightMorse => 'Morsecode A';

  @override
  String get chartLegend_lightMorseHint => 'Kort, lang: veilig water';

  @override
  String get chartLegend_lightAlternating => 'Alternerend licht';

  @override
  String get chartLegend_lightAlternatingHint => 'Wisselt van kleur';

  @override
  String get chartLegend_lightColours => 'Wit, rood, groen, geel';

  @override
  String get chartLegend_lightPeriod => 'Periode';

  @override
  String get chartLegend_lightPeriodHint =>
      'Seconden voor één volledige cyclus';

  @override
  String get chartLegend_rock => 'Rots onder water';

  @override
  String get chartLegend_rockHint => 'Altijd bedekt, maar kan ondiep liggen';

  @override
  String get chartLegend_rockAwash => 'Rots op waterhoogte';

  @override
  String get chartLegend_rockAwashHint =>
      'Bij laagwater vlak bij het oppervlak';

  @override
  String get chartLegend_rockCovers => 'Droogvallende rots';

  @override
  String get chartLegend_rockCoversHint =>
      'Zichtbaar bij laagwater, bedekt bij hoogwater';

  @override
  String get chartLegend_wreckDangerous => 'Gevaarlijk wrak';

  @override
  String get chartLegend_wreckDangerousHint => 'Ondiep genoeg om te raken';

  @override
  String get chartLegend_wreck => 'Wrak';

  @override
  String get chartLegend_wreckHint =>
      'Diep genoeg voor boten aan het oppervlak; niet ankeren';

  @override
  String get chartLegend_wreckShowing => 'Zichtbaar wrak';

  @override
  String get chartLegend_wreckShowingHint => 'Een deel steekt boven water uit';

  @override
  String get chartLegend_obstruction => 'Obstakel';

  @override
  String get chartLegend_obstructionHint =>
      'Iets op de bodem; met diepte als die bekend is';

  @override
  String get chartLegend_foulGround => 'Onreine grond';

  @override
  String get chartLegend_foulGroundHint =>
      'Veilig om over te varen, maar niet ankeren of met een sleepnet vissen';

  @override
  String get chartLegend_hazardArea => 'Rand van een gevarengebied';

  @override
  String get chartLegend_hazardAreaHint =>
      'Rotsen, wrakken of obstakels binnenin';

  @override
  String get chartLegend_pile => 'Paal of staak';

  @override
  String get chartLegend_floodStream => 'Vloedstroom';

  @override
  String get chartLegend_floodStreamHint =>
      'Getijstroom terwijl het water stijgt';

  @override
  String get chartLegend_ebbStream => 'Ebstroom';

  @override
  String get chartLegend_ebbStreamHint => 'Getijstroom terwijl het water zakt';

  @override
  String get chartLegend_current => 'Stroming';

  @override
  String get chartLegend_currentHint =>
      'Stroomt dezelfde kant op, ongeacht het getij';

  @override
  String get chartLegend_rips => 'Stroomrafelingen of draaikolken';

  @override
  String get chartLegend_ripsHint => 'Woelig, kolkend water';

  @override
  String get chartLegend_breakers => 'Brekers';

  @override
  String get chartLegend_breakersHint => 'Golven die breken boven ondiepten';

  @override
  String get chartLegend_sounding => 'Dieptecijfer';

  @override
  String get chartLegend_soundingHint => 'Diepte bij gemiddeld laagwater';

  @override
  String get chartLegend_depthContour => 'Dieptelijn';

  @override
  String get chartLegend_depthContourHint => 'Het label geeft de diepte';

  @override
  String get chartLegend_drying => 'Valt droog bij laagwater';

  @override
  String get chartLegend_dredged => 'Gebaggerde vaargeul';

  @override
  String get chartLegend_dredgedHint => 'Op de aangegeven diepte gehouden';

  @override
  String get chartLegend_swept => 'Geveegd gebied';

  @override
  String get chartLegend_sweptHint => 'Vrij bevonden tot de aangegeven diepte';

  @override
  String get chartLegend_unsurveyed => 'Niet opgemeten';

  @override
  String get chartLegend_unsurveyedHint => 'Geen diepten gemeten';

  @override
  String get chartLegend_weed => 'Kelp of zeewier';

  @override
  String get chartLegend_restricted => 'Beperkt gebied';

  @override
  String get chartLegend_restrictedHint =>
      'Toegang beperkt; de streepjes wijzen naar binnen';

  @override
  String get chartLegend_regulatedLimit => 'Grens van een gereguleerd gebied';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Ankergebied, kabelgebied, schietgebied en meer: zie het label';

  @override
  String get chartLegend_greyLimit => 'Stortgebied, visgebied of kwekerij';

  @override
  String get chartLegend_anchorage => 'Ankerplaats';

  @override
  String get chartLegend_anchorBerth => 'Ankerligplaats';

  @override
  String get chartLegend_noAnchoring => 'Ankeren verboden';

  @override
  String get chartLegend_caution => 'Waarschuwingsgebied';

  @override
  String get chartLegend_cautionHint => 'Wees hier extra voorzichtig';

  @override
  String get chartLegend_trafficLane => 'Verkeersbaan';

  @override
  String get chartLegend_trafficLaneHint =>
      'Grote schepen, één richting: haaks oversteken';

  @override
  String get chartLegend_separationZone => 'Scheidingszone';

  @override
  String get chartLegend_separationZoneHint =>
      'Tussen verkeersbanen: niet binnenvaren';

  @override
  String get chartLegend_precautionary => 'Voorzorgsgebied';

  @override
  String get chartLegend_precautionaryHint => 'Schepen komen samen: let op';

  @override
  String get chartLegend_fairway => 'Vaargeul';

  @override
  String get chartLegend_fairwayHint => 'Een hoofdvaargeul';

  @override
  String get chartLegend_track => 'Aanbevolen koerslijn';

  @override
  String get chartLegend_ferry => 'Veerroute';

  @override
  String get chartLegend_leadingLine => 'Geleidelijn';

  @override
  String get chartLegend_leadingLineHint =>
      'Breng de twee merktekens in lijn om in de vaargeul te blijven';

  @override
  String get chartLegend_cable => 'Onderzeese kabel';

  @override
  String get chartLegend_cableHint => 'Niet ankeren';

  @override
  String get chartLegend_pipeline => 'Onderzeese pijpleiding';

  @override
  String get chartLegend_pipelineHint => 'Niet ankeren';

  @override
  String get chartLegend_overhead => 'Bovengrondse kabel';

  @override
  String get chartLegend_overheadHint =>
      'De doorvaarthoogte staat erbij als VC';

  @override
  String get chartLegend_tower => 'Toren';

  @override
  String get chartLegend_windTurbine => 'Windturbine';

  @override
  String get chartLegend_chimney => 'Schoorsteen';

  @override
  String get chartLegend_mast => 'Mast of antenne';

  @override
  String get chartLegend_church => 'Kerk of torenspits';

  @override
  String get chartLegend_flagstaff => 'Vlaggenmast';

  @override
  String get chartLegend_dome => 'Koepel';

  @override
  String get chartLegend_landmark => 'Ander herkenningspunt';

  @override
  String get chartLegend_abbrAnch => 'Ankerplaats';

  @override
  String get chartLegend_abbrWk => 'Wrak';

  @override
  String get chartLegend_abbrBr => 'Brekers';

  @override
  String get chartLegend_abbrWd => 'Zeewier';

  @override
  String get chartLegend_abbrVar => 'Magnetische variatie';

  @override
  String get chartLegend_abbrVc => 'Doorvaarthoogte onder een brug of kabel';

  @override
  String get chartLegend_abbrTr => 'Toren';

  @override
  String get chartLegend_abbrCh => 'Kerk';

  @override
  String get chartLegend_abbrChy => 'Schoorsteen';

  @override
  String get chartLegend_abbrFs => 'Vlaggenmast';

  @override
  String get chartLegend_abbrTk => 'Tank';

  @override
  String get chartLegend_abbrRBn => 'Radiobaken';

  @override
  String get chartLegend_abbrCg => 'Kustwachtpost';

  @override
  String get chartLegend_abbrRacon => 'Radarbaken: zichtbaar op de radar';

  @override
  String get chartLegend_abbrFog =>
      'Mistsein: hoorn, bel, gong, fluit of sirene';

  @override
  String get chartLegend_abbrVAis =>
      'Virtuele markering: alleen zichtbaar via AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from tot $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Dieper dan $depth';
  }

  @override
  String get parkLegend_title => 'Park- en wandelsymbolen';

  @override
  String get parkLegend_campsite => 'Camping';

  @override
  String get parkLegend_picnicSite => 'Picknickplaats';

  @override
  String get parkLegend_shelter => 'Schuilhut';

  @override
  String get parkLegend_toilets => 'Toiletten';

  @override
  String get parkLegend_drinkingWater => 'Drinkwater';

  @override
  String get parkLegend_parking => 'Parkeerplaats';

  @override
  String get parkLegend_viewpoint => 'Uitzichtpunt';

  @override
  String get parkLegend_attraction => 'Bezienswaardigheid';

  @override
  String get parkLegend_gate => 'Hek';

  @override
  String get parkLegend_telephone => 'Telefoon';

  @override
  String get parkLegend_information => 'Informatiebord';

  @override
  String get parkLegend_guidepost => 'Wegwijzer';

  @override
  String get dialog_noticeExpires => 'Verloopt';

  @override
  String get dialog_noticeNoExpiry => 'Nooit';

  @override
  String get dialog_noticeExpiryRequired =>
      'Kies een datum (verplicht in een ruimte)';

  @override
  String get dialog_noticeExpiryTime => 'Tijd';

  @override
  String get dialog_noticeEndOfDay => 'Einde van de dag';

  @override
  String structured_until(String when) {
    return 'Tot $when';
  }

  @override
  String get structured_expired => 'Verlopen';

  @override
  String get structured_announcement => 'Aankondiging';

  @override
  String structured_locationOf(String name) {
    return 'Locatie van $name';
  }

  @override
  String get reaction_searchHint => 'Emoji zoeken';

  @override
  String get reaction_noResults => 'Geen emoji\'s gevonden';

  @override
  String get share_qrAndLink => 'QR-code en link delen';

  @override
  String get share_roomTitle => 'Ruimte delen';

  @override
  String get share_contactTitle => 'Contact delen';

  @override
  String get share_roomInstructions =>
      'Scan om deze ruimte toe te voegen. Om in te loggen heb je het ruimtewachtwoord nodig.';

  @override
  String get share_contactInstructions => 'Scan om dit contact toe te voegen.';

  @override
  String get clearChat_body =>
      'Verwijder berichten uit deze chat op dit apparaat. Nieuwe berichten blijven hier gewoon binnenkomen.';

  @override
  String get clearChat_olderThanDay => 'Ouder dan 1 dag';

  @override
  String get clearChat_olderThanWeek => 'Ouder dan 1 week';

  @override
  String get clearChat_olderThanMonth => 'Ouder dan 1 maand';

  @override
  String get clearChat_everything => 'Alle berichten';

  @override
  String get chats_markAllRead => 'Alles als gelezen markeren';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats als gelezen markeren?',
      one: '1 chat als gelezen markeren?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Markeren';

  @override
  String get chats_nothingUnread => 'Geen ongelezen berichten';

  @override
  String get chats_draft => 'Concept';

  @override
  String get contact_teleBlockedTitle => 'Geblokkeerd door je radio';

  @override
  String contact_teleBlockedBody(String name) {
    return 'De privacy-instellingen van je radio delen dit met niemand, dus $name krijgt het niet. Wijzigen zodat de contacten die je toestaat het krijgen?';
  }

  @override
  String get contact_teleNotNow => 'Niet nu';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'Je radio deelt dit met niemand ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'Je radio deelt dit met iedereen ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Kan je locatie opvragen';

  @override
  String get pathfinder_meshTitle => 'Een andere mesh?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '$unknown van de $heard repeaters die sinds het verbinden gehoord zijn, zijn nieuw voor de Pathfinder-kaart ‘$graph’. Een nieuwe kaart voor dit gebied beginnen? De oude blijft, en je kunt terugschakelen op het Pathfinder-scherm.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'De meeste repeaters die sinds het verbinden gehoord zijn, staan in de Pathfinder-kaart ‘$other’, niet in ‘$graph’. Daarnaar overschakelen?';
  }

  @override
  String get pathfinder_meshNew => 'Nieuwe kaart';

  @override
  String get pathfinder_meshSwitch => 'Overschakelen';

  @override
  String get pathfinder_meshKeep => 'Deze houden';

  @override
  String get pathfinder_graphNameTitle => 'Naam van de nieuwe kaart';

  @override
  String get pathfinder_graphNameHint => 'Bijvoorbeeld Washington';

  @override
  String get pathfinder_graphCreate => 'Aanmaken';

  @override
  String get locationSharing_title => 'Wie mijn locatie kan zien';

  @override
  String get locationSharing_someone => 'Iemand kan je locatie zien';

  @override
  String get locationSharing_nobody => 'Niemand kan je locatie zien';

  @override
  String get locationSharing_noPosition =>
      'Je radio heeft nog geen locatie, dus niemand kan die zien';

  @override
  String get locationSharing_everyone =>
      'Iedereen die je radio hoort, kan je locatie zien';

  @override
  String get locationSharing_allContacts =>
      'Al je contacten kunnen je locatie zien';

  @override
  String get locationSharing_someContacts =>
      'Contacten die je toestemming gaf, kunnen je locatie zien';

  @override
  String get locationSharing_adverts => 'Locatie in aankondigingen';

  @override
  String get locationSharing_advertsHint =>
      'Je aankondigingen bevatten je locatie, dus iedereen die je radio hoort, ziet die.';

  @override
  String get locationSharing_contactsHeader =>
      'Contacten die je radio mogen bevragen';

  @override
  String get locationSharing_noTelemetry =>
      'Geen. Je radio beantwoordt geen telemetrieverzoeken.';

  @override
  String get locationSharing_noContacts =>
      'Geen enkel contact heeft toestemming.';

  @override
  String locationSharing_allContactsRow(int count) {
    return 'Al je contacten ($count)';
  }

  @override
  String get locationSharing_partLocation => 'Locatie';

  @override
  String get locationSharing_partBattery => 'Batterij';

  @override
  String get locationSharing_partSensors => 'Sensoren';

  @override
  String get dialog_positionHint => 'Plak coördinaten of een kaartlink';

  @override
  String get dialog_positionUnreadable => 'Hier is geen positie te lezen';

  @override
  String get dialog_positionLookingUp => 'Link opzoeken…';

  @override
  String get locationSharing_share => 'Mijn locatie delen';

  @override
  String get locationSharing_shareOnHint =>
      'Zet uit om hem voor iedereen te verbergen';

  @override
  String get locationSharing_shareOffHint =>
      'Zet aan zodat contacten met toestemming hem zien';

  @override
  String get chats_advertise => 'Aankondigen';
}
