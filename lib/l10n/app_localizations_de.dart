// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Chats';

  @override
  String get chats_title => 'Chats';

  @override
  String get newChat_title => 'Kontakt auswählen';

  @override
  String newChat_contactCount(int count) {
    return '$count Kontakte';
  }

  @override
  String get newChat_newContact => 'Neuer Kontakt';

  @override
  String get newChat_newChannel => 'Neuer Kanal';

  @override
  String get newChat_myContacts => 'Meine Kontakte';

  @override
  String get newChat_discovered => 'Entdeckt';

  @override
  String get repeaters_title => 'Repeater verwalten';

  @override
  String get nav_contacts => 'Kontakte';

  @override
  String get nav_channels => 'Kanäle';

  @override
  String get nav_map => 'Karte';

  @override
  String get common_cancel => 'Abbrechen';

  @override
  String get common_syncing_device_info => 'Geräteinfos werden gelesen...';

  @override
  String get common_syncing_contacts => 'Kontakte werden gelesen...';

  @override
  String get common_syncing_channels => 'Kanäle werden gelesen...';

  @override
  String get common_syncing_messages => 'Nachrichten werden gelesen...';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Verbinden';

  @override
  String get common_unknownDevice => 'Unbekanntes Gerät';

  @override
  String get common_save => 'Speichern';

  @override
  String get common_delete => 'Löschen';

  @override
  String get common_deleteAll => 'Alles löschen';

  @override
  String get common_close => 'Schließen';

  @override
  String get common_edit => 'Bearbeiten';

  @override
  String get common_add => 'Hinzufügen';

  @override
  String get common_settings => 'Einstellungen';

  @override
  String get common_disconnect => 'Trennen';

  @override
  String get common_connected => 'Verbunden';

  @override
  String get common_disconnected => 'Getrennt';

  @override
  String get common_connectionLost =>
      'Verbindung verloren. Wird neu verbunden...';

  @override
  String get common_reconnecting => 'Wird neu verbunden...';

  @override
  String get common_create => 'Erstellen';

  @override
  String get common_continue => 'Fortfahren';

  @override
  String get common_share => 'Teilen';

  @override
  String get common_copy => 'Kopieren';

  @override
  String get common_retry => 'Versuchen';

  @override
  String get common_hide => 'Ausblenden';

  @override
  String get common_remove => 'Löschen';

  @override
  String get common_enable => 'Aktivieren';

  @override
  String get common_disable => 'Deaktivieren';

  @override
  String get common_reboot => 'Neustart';

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
  String get tcpScreenTitle => 'Verbinden über TCP';

  @override
  String get tcpHostLabel => 'IP-Adresse';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Port';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected =>
      'Geben Sie den Endpunkt ein und verbinden Sie sich.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Verbindung zu $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Eine IP-Adresse ist erforderlich.';

  @override
  String get tcpErrorPortInvalid =>
      'Die Portnummer muss zwischen 1 und 65535 liegen.';

  @override
  String get tcpErrorUnsupported =>
      'Die TCP-Übertragung wird auf dieser Plattform nicht unterstützt.';

  @override
  String get tcpErrorTimedOut => 'Die TCP-Verbindung ist abgelaufen.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Fehler beim TCP-Verbindungsaufbau: $error';
  }

  @override
  String get usbScreenTitle => 'Verbinden über USB';

  @override
  String get usbScreenSubtitle =>
      'Wählen Sie ein erkannten serielles Gerät aus und verbinden Sie es direkt mit Ihrem MeshCore-Knoten.';

  @override
  String get usbScreenStatus => 'Wählen Sie ein USB-Gerät aus';

  @override
  String get usbScreenNote =>
      'Die USB-Serielle Schnittstelle ist auf unterstützten Android-Geräten und Desktop-Plattformen aktiv.';

  @override
  String get usbScreenEmptyState =>
      'Keine USB-Geräte gefunden. Schließen Sie eines an und aktualisieren Sie.';

  @override
  String get usbErrorPermissionDenied =>
      'Die USB-Berechtigung wurde abgelehnt.';

  @override
  String get usbErrorDeviceMissing =>
      'Das ausgewählte USB-Gerät ist nicht mehr verfügbar.';

  @override
  String get usbErrorInvalidPort => 'Wählen Sie ein gültiges USB-Gerät aus.';

  @override
  String get usbErrorBusy =>
      'Eine weitere Anfrage für eine USB-Verbindung ist bereits in Bearbeitung.';

  @override
  String get usbErrorNotConnected => 'Es ist kein USB-Gerät angeschlossen.';

  @override
  String get usbErrorOpenFailed =>
      'Fehlgeschlagen beim Öffnen des ausgewählten USB-Geräts.';

  @override
  String get usbErrorConnectFailed =>
      'Keine Verbindung zum ausgewählten USB-Gerät hergestellt.';

  @override
  String get usbErrorUnsupported =>
      'Die USB-Serielle Schnittstelle wird auf dieser Plattform nicht unterstützt.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Diesem Build fehlt seine USB-Seriell-Bibliothek, daher können USB-Geräte nicht geöffnet werden. Bitte installieren Sie MeshTrax neu oder melden Sie diesen Build als defekt.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Dieser Browser unterstützt Web Serial nicht. Verwenden Sie Chrome oder Edge über HTTPS (oder localhost).';

  @override
  String get usbErrorAlreadyActive =>
      'Eine USB-Verbindung ist bereits hergestellt.';

  @override
  String get usbErrorNoDeviceSelected => 'Kein USB-Gerät wurde ausgewählt.';

  @override
  String get usbErrorPortClosed => 'Die USB-Verbindung ist nicht aktiv.';

  @override
  String get usbErrorConnectTimedOut =>
      'Verbindung konnte nicht hergestellt werden. Stellen Sie sicher, dass das Gerät die entsprechende USB-Firmware enthält.';

  @override
  String get usbFallbackDeviceName => 'Web-Serielle Geräte';

  @override
  String get usbStatus_notConnected => 'Wählen Sie ein USB-Gerät aus';

  @override
  String get usbStatus_connecting => 'Verbindung zum USB-Gerät...';

  @override
  String get usbStatus_searching => 'Suche nach USB-Geräten...';

  @override
  String usbConnectionFailed(String error) {
    return 'Fehler beim USB-Verbindungsaufbau: $error';
  }

  @override
  String get scanner_scanning => 'Scannen nach Geräten...';

  @override
  String get scanner_connecting => 'Verbunden...';

  @override
  String get scanner_disconnecting => 'Trenne...';

  @override
  String get scanner_notConnected => 'Nicht verbunden';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Verbunden mit $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Alle Bluetooth-Geräte anzeigen';

  @override
  String get scanner_showMeshCoreOnly => 'Nur MeshCore-Funkgeräte anzeigen';

  @override
  String get scanner_radioNotResponding =>
      'Das Funkgerät antwortet nicht. Eventuell muss es gekoppelt werden: Öffnen Sie die Bluetooth-Einstellungen, fügen Sie das Funkgerät hinzu, geben Sie seine PIN ein und versuchen Sie es dann erneut.';

  @override
  String get scanner_pairingFailed =>
      'Die Bluetooth-Kopplung wurde abgebrochen oder ist fehlgeschlagen. Stellen Sie sicher, dass nichts anderes (z. B. Ihr Handy) mit dem Funkgerät verbunden ist, versuchen Sie es dann erneut und geben Sie seine PIN ein.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Verbindungsfehler: $error';
  }

  @override
  String get scanner_stop => 'Stopp';

  @override
  String get scanner_scan => 'Scannen';

  @override
  String get scanner_scanFromImage => 'Aus Bild scannen';

  @override
  String get scanner_noQrFoundInImage =>
      'Kein gültiger QR-Code im Bild gefunden';

  @override
  String get scanner_bluetoothOff => 'Bluetooth ist deaktiviert.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Bitte aktivieren Sie Bluetooth, um nach Geräten zu suchen.';

  @override
  String get scanner_chromeRequired => 'Chrome Browser erforderlich';

  @override
  String get scanner_chromeRequiredMessage =>
      'Diese Webanwendung erfordert Google Chrome oder einen Chromium-basierten Browser für die Bluetooth-Unterstützung.';

  @override
  String get scanner_enableBluetooth => 'Bluetooth aktivieren';

  @override
  String get device_quickSwitch => 'Schnelles Umschalten';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Einstellungen';

  @override
  String get settings_deviceInfo => 'Geräteinformationen';

  @override
  String get settings_appSettings => 'App-Einstellungen';

  @override
  String get settings_appSettingsSubtitle =>
      'Benachrichtigungen, Messaging und Kartenwahrnehmung';

  @override
  String get settings_nodeSettings => 'Knoten-Einstellungen';

  @override
  String get settings_nodeName => 'Knotenname';

  @override
  String get settings_nodeNameNotSet => 'Nicht festgelegt';

  @override
  String get settings_nodeNameHint => 'Gebe den Knotenamen ein';

  @override
  String get settings_nodeNameUpdated => 'Name aktualisiert';

  @override
  String get settings_radioSettings => 'Funk Einstellungen';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequenz, Leistung, Verbreitungsfaktor';

  @override
  String get settings_radioSettingsUpdated => 'Funkparameter aktualisiert';

  @override
  String get settings_location => 'Ort';

  @override
  String get settings_locationSubtitle => 'GPS-Koordinaten';

  @override
  String get settings_locationUpdated => 'Ort aktualisiert';

  @override
  String get settings_locationBothRequired =>
      'Bitte geben Sie sowohl Breite als auch Längengrad ein.';

  @override
  String get settings_locationInvalid => 'Ungültige Breiten- oder Längengrade.';

  @override
  String get settings_locationGPSEnable => 'GPS aktivieren';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Aktiviert GPS zur automatischen Aktualisierung des Standorts.';

  @override
  String get settings_latitude => 'Breitengrad';

  @override
  String get settings_longitude => 'Längengrad';

  @override
  String get settings_contactSettings => 'Kontakteinstellungen';

  @override
  String get settings_contactSettingsSubtitle =>
      'Einstellungen für das Hinzufügen von Kontakten';

  @override
  String get settings_privacyMode => 'Privatsphäreeinstellung';

  @override
  String get settings_privacyModeSubtitle =>
      'Verstecken Sie Name/Ort in Ankündigungen';

  @override
  String get settings_privacyModeToggle =>
      'Aktivieren Sie die Privatsphäreeinstellung, um Ihren Namen und Ihre Standortdaten in Ankündigungen zu verbergen.';

  @override
  String get settings_privacyModeEnabled => 'Datenschutzmodus aktiviert';

  @override
  String get settings_privacyModeDisabled => 'Datenschutzmodus deaktiviert';

  @override
  String get settings_privacy => 'Datenschutzeinstellungen';

  @override
  String get settings_privacySubtitle =>
      'Steuern Sie die Informationen, die freigegeben werden.';

  @override
  String get settings_privacySettingsDescription =>
      'Wählen Sie die Informationen, die Ihr Gerät mit anderen teilt.';

  @override
  String get settings_denyAll => 'Alle ablehnen';

  @override
  String get settings_allowByContact => 'Zulassen durch Kontaktflaggen';

  @override
  String get settings_allowAll => 'Alles zulassen';

  @override
  String get settings_telemetryBaseMode => 'Telemetrie-Basismodus';

  @override
  String get settings_telemetryLocationMode => 'Telemetrie-Ortsmodus';

  @override
  String get settings_telemetryEnvironmentMode => 'Telemetrie-Umgebungsmodus';

  @override
  String get settings_advertLocation => 'Anzeigenort';

  @override
  String get settings_advertLocationSubtitle =>
      'Ort in der Anzeige einbeziehen';

  @override
  String get settings_multiAck => 'Mehrere Bestätigungen';

  @override
  String get settings_telemetryModeUpdated => 'Telemetriemodus aktualisiert';

  @override
  String get settings_actions => 'Aktionen';

  @override
  String get settings_sendAdvertisement => 'Sende Ankündigung';

  @override
  String get settings_sendAdvertisementSubtitle => 'Sende eine Ankündigung';

  @override
  String get settings_advertisementSent => 'Ankündigung gesendet';

  @override
  String get settings_syncTime => 'Zeitsynchronisierung';

  @override
  String get settings_syncTimeSubtitle =>
      'Stelle die Gerätezeit auf die Uhrzeit des Telefons ein';

  @override
  String get settings_timeSynchronized => 'Zeit synchronisiert';

  @override
  String get settings_refreshContacts => 'Kontakte aktualisieren';

  @override
  String get settings_refreshContactsSubtitle =>
      'Kontakt-Liste vom Gerät neu laden';

  @override
  String get settings_rebootDevice => 'Gerät neu starten';

  @override
  String get settings_rebootDeviceSubtitle => 'MeshCore-Gerät neu starten';

  @override
  String get settings_rebootDeviceConfirm =>
      'Sind Sie sicher, dass Sie das Gerät neu starten möchten? Sie werden getrennt.';

  @override
  String get settings_debug => 'Fehlerbehebung';

  @override
  String get settings_bleDebugLog => 'BLE-Debug-Protokoll';

  @override
  String get settings_bleDebugLogSubtitle =>
      'BLE-Befehle, Antworten und Rohdaten';

  @override
  String get settings_appDebugLog => 'App-Debug-Protokoll';

  @override
  String get settings_appDebugLogSubtitle => 'Anwendung Debug-Nachrichten';

  @override
  String get settings_exportDatabase => 'Nachrichtendatenbank exportieren';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Eine Kopie aller Chats und Kontakte zur Fehlersuche. Privat aufbewahren.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Datenbank gespeichert unter: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get settings_about => 'Über';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'MeshTrax Source Projekt 2026';

  @override
  String get settings_aboutDescription =>
      'Ein Open-Source-Flutter-Client für MeshCore LoRa-Meshnetzwerkgeräte.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'LOS-Höhendaten: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Name';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Akku';

  @override
  String get settings_infoPublicKey => 'Öffentlicher Schlüssel';

  @override
  String get settings_infoContactsCount => 'Anzahl Kontakte';

  @override
  String get settings_infoChannelCount => 'Anzahl Kanäle';

  @override
  String get settings_presets => 'Voreinstellungen';

  @override
  String get settings_frequency => 'Frequenz (MHz)';

  @override
  String get settings_frequencyHelper => '300,00 - 2.500,00';

  @override
  String get settings_frequencyInvalid => 'Ungültige Frequenz (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Bandbreite';

  @override
  String get settings_spreadingFactor => 'Verteilungsfaktor';

  @override
  String get settings_codingRate => 'Kodierungsrate';

  @override
  String get settings_txPower => 'TX-Leistung (dBm)';

  @override
  String get settings_txPowerInvalid => 'Ungültige TX-Leistung';

  @override
  String get settings_clientRepeat => 'Wiederholung, ohne Stromanschluss';

  @override
  String get settings_clientRepeatSubtitle =>
      'Ermöglichen Sie diesem Gerät, Mesh-Pakete für andere zu wiederholen.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Die Kommunikation ohne Stromversorgung erfordert Frequenzen von 433, 869 oder 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Fehler: $message';
  }

  @override
  String get appSettings_title => 'App-Einstellungen';

  @override
  String get appSettings_appearance => 'Aussehen';

  @override
  String get appSettings_theme => 'Theme';

  @override
  String get appSettings_themeSystem => 'Systemstandard';

  @override
  String get appSettings_themeLight => 'Hell';

  @override
  String get appSettings_themeDark => 'Dunkel';

  @override
  String get appSettings_language => 'Sprache';

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
  String get appSettings_languageRu => 'Russisch';

  @override
  String get appSettings_languageUk => 'Ukrainisch';

  @override
  String get appSettings_enableMessageTracing =>
      'Nachrichtenverfolgung aktivieren';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Detaillierte Routing- und Timing-Metadaten für Nachrichten anzeigen';

  @override
  String get appSettings_senderNameColors => 'Farbige Absendernamen';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Gibt jedem Absender in Kanälen eine eigene Namensfarbe. Aus verwendet für alle die Designfarbe.';

  @override
  String get appSettings_showTextFormatting => 'Textformatierung anzeigen';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown in Nachrichten: **fett**, *kursiv*, ||Spoiler||, Überschriften und Links. Andere MeshCore-Apps zeigen die Rohzeichen.';

  @override
  String get appSettings_notifications => 'Benachrichtigungen';

  @override
  String get appSettings_enableNotifications => 'Benachrichtigungen aktivieren';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Erhalte Benachrichtigungen für Nachrichten und Ankündigungen';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Erlaubnis zur Benachrichtigung verweigert';

  @override
  String get appSettings_notificationsEnabled => 'Benachrichtigungen aktiviert';

  @override
  String get appSettings_notificationsDisabled =>
      'Benachrichtigungen deaktiviert';

  @override
  String get appSettings_messageNotifications =>
      'Direktnachrichten Benachrichtigungen';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Zeige Benachrichtigung beim Empfang neuer Direktnachrichten';

  @override
  String get appSettings_channelMessageNotifications =>
      'Kanalnachrichten Benachrichtigungen';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Zeige Benachrichtigung beim Empfangen von Kanalnachrichten';

  @override
  String get appSettings_advertisementNotifications =>
      'Ankündigungsbenachrichtigungen';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Zeige Benachrichtigung, wenn neue Knoten entdeckt werden.';

  @override
  String get appSettings_messaging => 'Nachrichten';

  @override
  String get appSettings_maxMessageRetries =>
      'Maximale Anzahl an Wiederholungsversuchen';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Anzahl der Versuche, eine Nachricht erneut zu senden, bevor sie als fehlgeschlagen markiert wird.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Max. Wiederholungen für Kanalnachrichten';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Sendet so oft erneut, bis mindestens eine Wiederholung zu hören ist';

  @override
  String get appSettings_battery => 'Akku';

  @override
  String get appSettings_batteryChemistry => 'Batteriechemie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Konfiguriert pro Gerät ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Verbinde ein Gerät, um zu wählen';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0–4,2 V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6–3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0–4,2V)';

  @override
  String get appSettings_mapDisplay => 'Kartendarstellung';

  @override
  String get appSettings_showRepeaters => 'Zeige Repeater';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Zeige Repeater-Knoten auf der Karte an';

  @override
  String get appSettings_showChatNodes => 'Zeige Chat-Knoten';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Chat-Knoten auf der Karte anzeigen';

  @override
  String get appSettings_showOtherNodes => 'Zeige andere Knoten';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Andere Knotentypen auf der Karte anzeigen';

  @override
  String get appSettings_timeFilter => 'Zeitfilter';

  @override
  String get appSettings_timeFilterShowAll => 'Alle Knoten anzeigen';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Zeige Knoten der letzten $hours Stunden an';
  }

  @override
  String get appSettings_mapTimeFilter => 'Karten Zeitfilter';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Zeige Knoten, die innerhalb von:';

  @override
  String get appSettings_allTime => 'Ganzer Zeitverlauf';

  @override
  String get appSettings_lastHour => 'Letzte Stunde';

  @override
  String get appSettings_last6Hours => 'Letzte 6 Stunden';

  @override
  String get appSettings_last24Hours => 'Letzte 24 Stunden';

  @override
  String get appSettings_lastWeek => 'Letzte Woche';

  @override
  String get appSettings_unitsTitle => 'Einheiten';

  @override
  String get appSettings_unitsMetric => 'Metrisch (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (ft/mi)';

  @override
  String get appSettings_debugCard => 'Fehlerbehebung';

  @override
  String get appSettings_appDebugLogging => 'App-Debug-Protokollierung';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Protokolliere App-Debug-Nachrichten zur Fehlerbehebung';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'App-Debug-Protokollierung aktiviert';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'App-Debug-Protokollierung deaktiviert';

  @override
  String get appSettings_incrementalContactSync =>
      'Inkrementeller Kontaktabgleich';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Beim Neuverbinden nur die seit dem letzten Mal geänderten Kontakte vom Funkgerät abfragen';

  @override
  String get contacts_title => 'Kontakte';

  @override
  String get contacts_noContacts => 'Noch keine Kontakte vorhanden.';

  @override
  String get contacts_shareMyQrCode => 'Meinen QR-Code teilen';

  @override
  String get contacts_shareQrCodeDesc =>
      'Andere scannen lassen, um Sie als Kontakt hinzuzufügen';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakte werden angezeigt, wenn Geräte eine Ankündigung machen.';

  @override
  String get contacts_unread => 'Ungelesen';

  @override
  String get contacts_searchContactsNoNumber => 'Kontakte suchen...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Suche Kontakte...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Suche $number$str Favoriten...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Suche $number$str Benutzer...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Suche $number$str Repeater...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Suche $number$str Raumserver...';
  }

  @override
  String get contacts_noUnreadContacts => 'Keine ungesehene Kontakte';

  @override
  String get contacts_noContactsFound =>
      'Keine Kontakte oder Gruppen gefunden.';

  @override
  String get contacts_deleteContact => 'Lösche den Kontakt';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Möchten Sie $contactName wirklich löschen?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Kontakt $contactName gelöscht.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return '$contactName konnte nicht gelöscht werden.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Keine Kontakte entsprechen dem Filter.';

  @override
  String contacts_removeConfirm(String contactName) {
    return '$contactName aus den Kontakten entfernen?';
  }

  @override
  String get contacts_manageRepeater => 'Repeater verwalten';

  @override
  String get contacts_manageRoom => 'Raum-Server verwalten';

  @override
  String get contacts_roomLogin => 'Raum-Login';

  @override
  String get contacts_openChat => 'Öffne Chat';

  @override
  String get contacts_editGroup => 'Gruppe bearbeiten';

  @override
  String get contacts_deleteGroup => 'Löschen Gruppe';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Löschen von \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Neue Gruppe';

  @override
  String get contacts_groupName => 'Gruppenname';

  @override
  String get contacts_groupNameRequired => 'Der Gruppennamen ist erforderlich.';

  @override
  String get contacts_groupNameReserved => 'Dieser Gruppenname ist reserviert';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Die Gruppe \"$name\" existiert bereits.';
  }

  @override
  String get contacts_filterContacts => 'Filtert Kontakte...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Keine Kontakte passen zu Ihrem Filter';

  @override
  String get contacts_noMembers => 'Keine Mitglieder';

  @override
  String get contacts_lastSeenNow => 'kürzlich';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes Min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 Std.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours Std.';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 Tag';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days Tage';
  }

  @override
  String get contact_info => 'Kontaktinformationen';

  @override
  String get contact_settings => 'Kontakteinstellungen';

  @override
  String get contact_telemetry => 'Telemetrie';

  @override
  String get contact_lastSeen => 'Zuletzt gesehen';

  @override
  String get contact_clearChat => 'Chat löschen';

  @override
  String get contact_teleBase => 'Telemetriebasis';

  @override
  String get contact_teleBaseSubtitle =>
      'Erlauben des Freigebens des Batteriestands und der grundlegenden Telemetrie';

  @override
  String get contact_teleLoc => 'Telemetrieort';

  @override
  String get contact_teleLocSubtitle => 'Teilen von Standortdaten zulassen';

  @override
  String get contact_teleEnv => 'Telemetrieumgebung';

  @override
  String get contact_teleEnvSubtitle =>
      'Teilen von Umgebungsensordaten zulassen';

  @override
  String get contacts_publicKey => 'Öffentlicher Schlüssel';

  @override
  String get channels_title => 'Kanäle';

  @override
  String get channels_noChannelsConfigured => 'Keine Kanäle konfiguriert';

  @override
  String get channels_addPublicChannel => 'Öffentlichen Kanal hinzufügen';

  @override
  String get channels_searchChannels => 'Suche Kanäle...';

  @override
  String get channels_noChannelsFound => 'Keine Kanäle gefunden';

  @override
  String channels_channelIndex(int index) {
    return 'Kanal $index';
  }

  @override
  String get channels_hashtagChannel => 'Hashtag-Kanal';

  @override
  String get channels_public => 'Öffentlich';

  @override
  String get channels_private => 'Privat';

  @override
  String get channels_publicChannel => 'Öffentlicher Kanal';

  @override
  String get channels_privateChannel => 'Privater Kanal';

  @override
  String get channels_editChannel => 'Kanal bearbeiten';

  @override
  String get channels_shareChannel => 'Kanal teilen';

  @override
  String get channels_shareChannelInstructions =>
      'QR-Code scannen, um den Kanal hinzuzufügen.\nMenü → Kanal hinzufügen → Scannen Sie einen QR-Code';

  @override
  String get channels_secretKey => 'Geheimer Schlüssel';

  @override
  String get channels_meshcoreUri => 'MeshCore-URI';

  @override
  String get channels_shareChannelQr => 'Kanal-QR-Code scannen';

  @override
  String get channels_shareChannelWarning =>
      'Achtung: Jeder, der diesen QR-Code scannt, erhält Zugriff auf diesen Kanal.';

  @override
  String get channels_muteChannel => 'Kanal stummschalten';

  @override
  String get channels_unmuteChannel => 'Kanal Stummschaltung aufheben';

  @override
  String get channels_deleteChannel => 'Lösche den Kanal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Löschen von \"$name\"? Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Kanal $name konnte nicht gelöscht werden';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanal \"$name\" gelöscht';
  }

  @override
  String get channels_addChannel => 'Kanal hinzufügen';

  @override
  String get channels_channelIndexLabel => 'Kanalindex';

  @override
  String get channels_channelName => 'Kanalname';

  @override
  String get channels_usePublicChannel => 'Verwende öffentlichen Kanal';

  @override
  String get channels_standardPublicPsk => 'Öffentliche Standard PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Zufällige PSK generieren';

  @override
  String get channels_enterChannelName =>
      'Bitte geben Sie einen Kanalnamen ein.';

  @override
  String get channels_pskMustBe32Hex =>
      'Die PSK muss 32 hexadezimale Zeichen haben.';

  @override
  String get channels_addChannelConfirmation =>
      'Möchten Sie den folgenden Kanal hinzufügen?';

  @override
  String get channels_channelAddedSuccess => 'Kanal erfolgreich hinzugefügt.';

  @override
  String get channels_noAvailableChannelSlots => 'Keine freien Kanalplätze.';

  @override
  String get appSettings_mentionNotifications =>
      'Benachrichtigungen bei Erwähnung';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Wenn jemand Sie erwähnt oder Ihnen antwortet — auch in stummgeschalteten Kanälen';

  @override
  String notification_mentionIn(String channelName) {
    return 'Erwähnung in $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Kanal \"$name\" hinzugefügt';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Bearbeiteter Kanal $index';
  }

  @override
  String get channels_smazCompression => 'SMAZ-Komprimierung';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanal \"$name\" aktualisiert';
  }

  @override
  String get channels_publicChannelAdded => 'Öffentlicher Kanal hinzugefügt';

  @override
  String get channels_sortBy => 'Sortiere nach';

  @override
  String get channels_sortManual => 'Manuell';

  @override
  String get channels_sortAZ => 'A bis Z';

  @override
  String get channels_sortLatestMessages => 'Letzte Nachrichten';

  @override
  String get channels_sortUnread => 'Ungelesen';

  @override
  String get channels_createPrivateChannel => 'Erstelle einen privaten Kanal';

  @override
  String get channels_createPrivateChannelDesc =>
      'Verschlüsselt mit einem geheimen Schlüssel.';

  @override
  String get channels_joinPrivateChannel =>
      'Treten Sie einem privaten Kanal bei';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Manuelle Eingabe eines geheimen Schlüssels.';

  @override
  String get channels_joinPublicChannel => 'Tritt dem öffentlichen Kanal bei';

  @override
  String get channels_joinPublicChannelDesc =>
      'Jeder kann diesem Kanal beitreten.';

  @override
  String get channels_joinHashtagChannel =>
      'Treten Sie einem Hashtag-Kanal bei';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Jeder kann sich bei Hashtag-Kanälen beteiligen.';

  @override
  String get channels_scanQrCode => 'Scannen Sie einen QR-Code';

  @override
  String get channels_scanQrCodeComingSoon => 'Bald verfügbar';

  @override
  String get channels_enterHashtag => 'Gib Hashtag ein';

  @override
  String get channels_hashtagHint => 'z.B. #team';

  @override
  String get chat_noMessages => 'Noch keine Nachrichten.';

  @override
  String get chat_sendMessage => 'Nachricht senden';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Sende eine Nachricht an $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Eine Nachricht senden, um anzufangen.';

  @override
  String get chat_originalMessageNotFound => 'Originalmeldung nicht gefunden';

  @override
  String chat_replyingTo(String name) {
    return 'Antworten an $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Antwort an $name';
  }

  @override
  String get chat_location => 'Ort';

  @override
  String get common_copiedToClipboard => 'In die Zwischenablage kopiert';

  @override
  String get common_copyToClipboard => 'In die Zwischenablage kopieren';

  @override
  String get contacts_copyContactToClipboard =>
      'Meinen Kontakt in die Zwischenablage kopieren';

  @override
  String get chat_typeMessage => 'Eine Nachricht eingeben...';

  @override
  String get chat_searchMessages => 'Nachrichten durchsuchen';

  @override
  String get chat_searchNoMatches => 'Keine Treffer';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Nachricht ist zu lang (max $maxBytes Bytes).';
  }

  @override
  String get chat_messageCopied => 'Nachricht kopiert';

  @override
  String get chat_messageDeleted => 'Nachricht gelöscht';

  @override
  String get chat_sendGif => 'GIF senden';

  @override
  String get chat_reply => 'Beantworten';

  @override
  String get chat_newMessages => 'NEUE NACHRICHTEN';

  @override
  String get chat_addReaction => 'Reaktion hinzufügen';

  @override
  String get chat_mention => 'Erwähnen';

  @override
  String get dmChannel_menuLabel => 'Direktnachricht';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'DM an $name senden';
  }

  @override
  String get dmChannel_pickerHint =>
      'Prüfen Sie den Schlüssel und wann der Kontakt zuletzt gesehen wurde — Namen sind nicht eindeutig.';

  @override
  String get dmChannel_warningTitle => 'Ist das wirklich die richtige Person?';

  @override
  String get dmChannel_warningBody =>
      'Namen in Kanälen sind selbst gewählt und können von jedem nachgeahmt werden. Prüfen Sie bei sensiblen Dingen zuerst auf anderem Weg den öffentlichen Schlüssel dieses Kontakts.';

  @override
  String get dmChannel_dontShowAgain => 'Nicht mehr anzeigen';

  @override
  String get batterySleep_title => 'MeshTrax aktiv halten';

  @override
  String get batterySleep_bodySamsung =>
      'Samsung-Handys versetzen Apps in den Ruhezustand, um Akku zu sparen – dadurch wird Ihr Funkgerät getrennt. Öffnen Sie Einstellungen → Apps → MeshTrax → Akku und wählen Sie Nicht eingeschränkt. Prüfen Sie außerdem Akku → Grenzen für Hintergrundnutzung und stellen Sie sicher, dass MeshTrax nicht unter Apps im Standby oder Apps im Tiefschlaf steht.';

  @override
  String get batterySleep_bodyGeneric =>
      'Ihr Handy kann MeshTrax im Hintergrund beenden, um Akku zu sparen – dadurch wird Ihr Funkgerät getrennt. Öffnen Sie die Akku-Einstellungen und stellen Sie MeshTrax auf Uneingeschränkt (oder Keine Einschränkungen). Auf manchen Handys müssen Sie außerdem Autostart für MeshTrax einschalten.';

  @override
  String get batterySleep_openSettings => 'Einstellungen öffnen';

  @override
  String get batterySleep_notNow => 'Nicht jetzt';

  @override
  String get batterySleep_settingsTile =>
      'MeshTrax im Hintergrund aktiv halten';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Verhindern, dass der Akkusparmodus MeshTrax in den Ruhezustand versetzt';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'DM an $name noch nicht möglich';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Sie haben den Schlüssel dieses Kontakts noch nicht, und zum Antworten braucht er Ihren — Schlüssel werden nur über Ankündigungen verteilt. „Meine Ankündigung senden“ sendet Ihre direkt von hier. „Im Kanal fragen“ schreibt eine Bitte ins Nachrichtenfeld, die Sie dann senden.';

  @override
  String get dmChannel_askInChannel => 'Im Kanal fragen';

  @override
  String get dmChannel_sendMyAdvert => 'Meine Ankündigung senden';

  @override
  String get dmChannel_askText =>
      'bitte eine Ankündigung senden, damit ich eine DM schicken kann';

  @override
  String get dmChannel_watching =>
      'Warte auf die Ankündigung — Sie werden hier gefragt, sobald sie eintrifft.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name ist jetzt erreichbar';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Zoomstufe';

  @override
  String get common_reset => 'Zurücksetzen';

  @override
  String get chat_reactionsTitle => 'Reaktionen';

  @override
  String get chat_reactionUnknownSender => 'Unbekannt';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender hat auf eine Nachricht reagiert, die nicht in diesem Chat ist';
  }

  @override
  String get chat_me => 'Ich';

  @override
  String get emojiCategorySmileys => 'Emoticons';

  @override
  String get emojiCategoryGestures => 'Gesten';

  @override
  String get emojiCategoryHearts => 'Herz';

  @override
  String get emojiCategoryObjects => 'Objekte';

  @override
  String get gifPicker_title => 'Wähle ein GIF';

  @override
  String get gifPicker_searchHint => 'Suche nach GIFs...';

  @override
  String get gifPicker_poweredBy => 'Bereitgestellt von GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Keine GIFs gefunden';

  @override
  String get gifPicker_failedLoad => 'GIF-Datei konnten nicht geladen werden.';

  @override
  String get gifPicker_failedSearch => 'Suche nach GIFs fehlgeschlagen';

  @override
  String get gifPicker_noInternet => 'Keine Internetverbindung';

  @override
  String get debugLog_appTitle => 'App-Debug-Protokoll';

  @override
  String get debugLog_bleTitle => 'BLE-Debug-Protokoll';

  @override
  String get debugLog_copyLog => 'Kopieren des Protokolls';

  @override
  String get debugLog_saveLog => 'Protokoll als Datei speichern';

  @override
  String get debugLog_saved => 'Protokoll gespeichert';

  @override
  String get debugLog_saveCancelled => 'Speichern abgebrochen';

  @override
  String get debugLog_filterAll => 'Alle';

  @override
  String get debugLog_filterWarnings => 'Warnungen';

  @override
  String get debugLog_filterErrors => 'Fehler';

  @override
  String get debugLog_clearLog => 'Protokoll löschen';

  @override
  String get debugLog_copied => 'Debug-Protokoll kopiert';

  @override
  String get debugLog_bleCopied => 'BLE-Protokoll kopiert';

  @override
  String get debugLog_noEntries => 'No Debug-Protokolle noch verfügbar';

  @override
  String get debugLog_enableInSettings =>
      'Aktivieren Sie das App-Debug-Logging in den Einstellungen';

  @override
  String get debugLog_frames => 'Rahmen';

  @override
  String get debugLog_rawLogRx => 'Roh-Log-RX';

  @override
  String get debugLog_noBleActivity => 'Bisher keine BLE-Aktivität';

  @override
  String debugFrame_length(int count) {
    return 'Rahmenlänge: $count Bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Befehl: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Textnachrichten Frame:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Ziel-Public-Schlüssel: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Zeitstempel: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flags: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Textart: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'CLI-Befehl';

  @override
  String get debugFrame_textTypePlain => 'Einfach';

  @override
  String debugFrame_text(String text) {
    return '- Text: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Hex-Dump:';

  @override
  String get chat_hopSingular => 'Sprung';

  @override
  String get chat_hopPlural => 'Sprünge';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprünge',
      one: 'Sprung',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Lege benutzerdefinierten Pfad fest';

  @override
  String get chat_fullPath => 'Vollständiger Pfad';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Die Pfaddetails sind noch nicht verfügbar. Versuchen Sie, eine Nachricht zu senden, um zu aktualisieren.';

  @override
  String get chat_type => 'Gebe ein';

  @override
  String get chat_path => 'Pfad';

  @override
  String get chat_publicKey => 'Öffentlicher Schlüssel';

  @override
  String get chat_compressOutgoingMessages =>
      'Komprimieren ausgehender Nachrichten';

  @override
  String get chat_floodForced => 'Geflutet (erzwungen)';

  @override
  String get chat_directForced => 'Direkt (erzwungen)';

  @override
  String chat_hopsForced(int count) {
    return '$count Sprünge (erzwungen)';
  }

  @override
  String get chat_floodAuto => 'Geflutet (automatisch)';

  @override
  String get chat_direct => 'Direkt';

  @override
  String get chat_poiShared => 'Geteilter POI';

  @override
  String chat_unread(int count) {
    return 'Ungelesen: $count';
  }

  @override
  String get chat_openLink => 'Link öffnen?';

  @override
  String get chat_openLinkConfirmation =>
      'Möchten Sie diesen Link in Ihrem Browser öffnen?';

  @override
  String get chat_open => 'Öffnen';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Link konnte nicht geöffnet werden: $url';
  }

  @override
  String get chat_invalidLink => 'Ungültiges Link-Format';

  @override
  String get map_lineOfSight => 'Sichtlinie';

  @override
  String get map_losScreenTitle => 'Sichtlinie';

  @override
  String get map_noNodesWithLocation => 'Keine Knoten mit Standortdaten';

  @override
  String get map_nodesNeedGps =>
      'Knoten müssen ihre GPS-Koordinaten teilen,\num auf der Karte zu erscheinen.';

  @override
  String map_nodesCount(int count) {
    return 'Knoten: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pins: $count';
  }

  @override
  String get map_chat => 'Benutzer';

  @override
  String get map_repeater => 'Repeater';

  @override
  String get map_room => 'Raum';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Pin (Kontakt)';

  @override
  String get map_pinPrivate => 'Pin (Channel)';

  @override
  String get map_pinPublic => 'Pin (Public)';

  @override
  String get map_lastSeen => 'Letzte Sichtung';

  @override
  String get map_disconnectConfirm =>
      'Sind Sie sicher, dass Sie sich von diesem Gerät trennen möchten?';

  @override
  String get map_from => 'Von';

  @override
  String get map_source => 'Quelle';

  @override
  String get map_flags => 'Flags';

  @override
  String get map_shareMarkerHere => 'Teilen Sie den Marker hier.';

  @override
  String get map_setAsMyLocation => 'Als meine aktuelle Position festlegen';

  @override
  String get map_pinLabel => 'Pin Name';

  @override
  String get map_label => 'Label';

  @override
  String get map_pointOfInterest => 'Punkt von Interesse';

  @override
  String get map_sendToContact => 'Senden an Kontakt';

  @override
  String get map_sendToChannel => 'Senden an Kanal';

  @override
  String get map_noChannelsAvailable => 'Keine Kanäle verfügbar';

  @override
  String get map_publicLocationShare => 'Öffentliche Standortfreigabe';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Sie werden kurz darauf einen Ort in $channelLabel teilen. Dieser Kanal ist öffentlich und jeder mit dem PSK kann ihn sehen.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Verbinde ein Gerät, um Marker zu teilen';

  @override
  String get map_filterNodes => 'Knotenfilter';

  @override
  String get map_chatNodes => 'Chat-Knoten';

  @override
  String get map_repeaters => 'Repeater';

  @override
  String get map_otherNodes => 'Andere Knoten';

  @override
  String get map_showOverlaps => 'Überlappungen der Repeater-Taste';

  @override
  String get map_keyPrefix => 'Schlüsselpräfix';

  @override
  String get map_filterByKeyPrefix => 'Filter nach Schlüsselpräfix';

  @override
  String get map_publicKeyPrefix => 'Schlüsselpräfix';

  @override
  String get map_showDiscoveryContacts => 'Entdeckungs-Kontakte anzeigen';

  @override
  String get map_guessedLocation => 'Geschätzter Ort';

  @override
  String get map_lastSeenTime => 'Letzte Sichtung';

  @override
  String get map_sharedPin => 'Gemeinsames Passwort';

  @override
  String get map_joinRoom => 'Beitreten Sie dem Raum';

  @override
  String get map_manageRepeater => 'Repeater verwalten';

  @override
  String get map_tapToAdd =>
      'Tippen Sie auf Knoten, um sie zum Pfad hinzuzufügen.';

  @override
  String get map_runTrace => 'Pfadverlauf ausführen';

  @override
  String get map_runTraceWithReturnPath =>
      'Auf dem gleichen Pfad zurückkehren.';

  @override
  String get map_removeLast => 'Letztes Entfernen';

  @override
  String get map_pathTraceCancelled => 'Pfadverfolgung abgebrochen.';

  @override
  String get time_justNow => 'Gerade eben';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes Minuten her';
  }

  @override
  String time_hoursAgo(int hours) {
    return '$hours Stunden her';
  }

  @override
  String time_daysAgo(int days) {
    return '$days Tage/Tage zuvor';
  }

  @override
  String get time_hour => 'Stunde';

  @override
  String get time_hours => 'Stunden';

  @override
  String get time_day => 'Tag';

  @override
  String get time_days => 'Tage';

  @override
  String get time_week => 'Woche';

  @override
  String get time_weeks => 'Wochen';

  @override
  String get time_month => 'Monat';

  @override
  String get time_months => 'Monate';

  @override
  String get time_minutes => 'Minuten';

  @override
  String get time_allTime => 'Ganzer Zeitraum';

  @override
  String get dialog_disconnect => 'Trennen';

  @override
  String get dialog_disconnectConfirm =>
      'Sind Sie sicher, dass Sie sich von diesem Gerät trennen möchten?';

  @override
  String get login_repeaterLogin => 'Beim Repeater anmelden';

  @override
  String get login_roomLogin => 'Raum-Login';

  @override
  String get login_password => 'Passwort';

  @override
  String get login_enterPassword => 'Passwort eingeben';

  @override
  String get login_savePassword => 'Passwort speichern';

  @override
  String get login_savePasswordSubtitle =>
      'Das Passwort wird auf diesem Gerät sicher gespeichert.';

  @override
  String get login_repeaterDescription =>
      'Geben Sie das Repeater-Passwort ein, um auf Einstellungen und Status zuzugreifen.';

  @override
  String get login_roomDescription =>
      'Geben Sie das Raumkennwort ein, um auf die Einstellungen und den Status zuzugreifen.';

  @override
  String get login_login => 'Anmelden';

  @override
  String login_attempt(int current, int max) {
    return 'Versuche $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Anmeldung fehlgeschlagen: $error';
  }

  @override
  String get login_failedMessage =>
      'Anmeldung fehlgeschlagen. Entweder ist das Passwort falsch oder der Repeater ist nicht erreichbar.';

  @override
  String get common_reload => 'Neu laden';

  @override
  String get common_clear => 'Löschen';

  @override
  String get path_enterCustomPath => 'Gebe Pfad ein';

  @override
  String get path_currentPathLabel => 'Aktueller Pfad';

  @override
  String get path_hexPrefixInstructions =>
      'Gebe für jeden Zwischen-Hop das 2-stellige Hex-Präfix ein, getrennt durch Kommas.';

  @override
  String get path_hexPrefixExample =>
      'Beispiel: A1,F2,3C (jeder Knoten verwendet den ersten Byte seines öffentlichen Schlüssels)';

  @override
  String get path_labelHexPrefixes => 'Pfad (Hex-Präfixe)';

  @override
  String get path_helperMaxHops =>
      'Max 64 Sprünge. Jede Präfixe ist 2 Hexadezimalzeichen (1 Byte)';

  @override
  String get path_selectFromContacts => 'Oder wähle aus Kontakten aus:';

  @override
  String get path_noRepeatersFound =>
      'Keine Repeater oder Raumserver gefunden.';

  @override
  String get path_customPathsRequire =>
      'Benutzerdefinierte Pfade erfordern Zwischen-Hops, die Nachrichten weiterleiten können.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Ungültige Hexadezimal-Präfixe: $prefixes';
  }

  @override
  String get path_tooLong => 'Pfad zu lang. Maximal 64 Hops erlaubt.';

  @override
  String get path_setPath => 'Pfad festlegen';

  @override
  String get repeater_management => 'Repeater-Verwaltung';

  @override
  String get room_management => 'Raum-Server-Verwaltung';

  @override
  String get repeater_guest => 'Informationen zu Repeatern';

  @override
  String get room_guest => 'Informationen zum Room Server';

  @override
  String get repeater_managementTools => 'Verwaltungs-Tools';

  @override
  String get repeater_guestTools => 'Gastwerkzeuge';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Status, Statistiken und Nachbarn anzeigen';

  @override
  String get repeater_telemetry => 'Telemetrie';

  @override
  String get repeater_telemetrySubtitle =>
      'Sensordaten und Systemwerte anzeigen';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Sende Befehle an den Repeater';

  @override
  String get repeater_neighbors => 'Nachbarn';

  @override
  String get repeater_neighborsSubtitle => 'Anzahl der Hop-Nachbarn anzeigen.';

  @override
  String get repeater_settings => 'Einstellungen';

  @override
  String get repeater_settingsSubtitle => 'Repeater-parameter konfigurieren';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Uhrzeit-Synchronisation nach dem Anmelden';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automatisch \"Uhrzeit-Synchronisierung\" nach erfolgreicher Anmeldung senden.';

  @override
  String get repeater_statusTitle => 'Repeaterstatus';

  @override
  String get repeater_refresh => 'Aktualisieren';

  @override
  String get repeater_statusRequestTimeout =>
      'Statusanfrage durch Timeout fehlgeschlagen.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Fehler beim Laden des Status: $error';
  }

  @override
  String get repeater_systemInformation => 'Systeminformation';

  @override
  String get repeater_battery => 'Akku';

  @override
  String get repeater_clockAtLogin => 'Uhr (bei Anmeldung)';

  @override
  String get repeater_uptime => 'Verfügbarkeit';

  @override
  String get repeater_queueLength => 'Warteschlangenlänge';

  @override
  String get repeater_debugFlags => 'Fehlerbehebungsoptionen';

  @override
  String get repeater_radioStatistics => 'Funk-Statistik';

  @override
  String get repeater_lastRssi => 'Letzter RSSI';

  @override
  String get repeater_lastSnr => 'Letzter SNR';

  @override
  String get repeater_noiseFloor => 'Rauschpegel';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Paketstatistiken';

  @override
  String get repeater_sent => 'Gesendet';

  @override
  String get repeater_received => 'Empfangen';

  @override
  String get repeater_duplicates => 'Duplikate';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days Tage ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Gesamt: $total, Flut: $flood, Direkt: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Gesamt: $total, Flut: $flood, Direkt: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Flut: $flood, Direkt: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Gesamt: $total';
  }

  @override
  String get repeater_settingsTitle => 'Repeater Einstellungen';

  @override
  String get repeater_basicSettings => 'Grundlegende Einstellungen';

  @override
  String get repeater_repeaterName => 'Repeater Name';

  @override
  String get repeater_repeaterNameHelper => 'Anzeigename für diesen Repeater';

  @override
  String get repeater_adminPassword => 'Admin-Passwort';

  @override
  String get repeater_adminPasswordHelper => 'Vollzugriffspasswort';

  @override
  String get repeater_guestPassword => 'Gast-Passwort';

  @override
  String get repeater_guestPasswordHelper =>
      'Schreibgeschütztes Zugriffspasswort';

  @override
  String get repeater_radioSettings => 'Funk Einstellungen';

  @override
  String get repeater_frequencyMhz => 'Frequenz (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Bandbreite';

  @override
  String get repeater_spreadingFactor => 'Verteilungsfaktor';

  @override
  String get repeater_codingRate => 'Kodierungsrate';

  @override
  String get repeater_locationSettings => 'Standort Einstellungen';

  @override
  String get repeater_latitude => 'Breitengrad';

  @override
  String get repeater_latitudeHelper => 'Dezimalgrad (z.B. 37,7749)';

  @override
  String get repeater_longitude => 'Längengrad';

  @override
  String get repeater_longitudeHelper => 'Dezimalgrad (z.B. -122,4194)';

  @override
  String get repeater_features => 'Funktionen';

  @override
  String get repeater_packetForwarding => 'Paketweiterleitung';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Aktivieren Sie den Repeater, um Pakete weiterzuleiten.';

  @override
  String get repeater_guestAccess => 'Gastzugriff';

  @override
  String get repeater_guestAccessSubtitle =>
      'Gast-Zugriff mit beschränkten Rechten zulassen';

  @override
  String get repeater_privacyMode => 'Privatsphäreeinstellung';

  @override
  String get repeater_privacyModeSubtitle =>
      'Verstecken Sie Name/Ort in Ankündigungen';

  @override
  String get repeater_advertisementSettings => 'Ankündigungseinstellungen';

  @override
  String get repeater_localAdvertInterval =>
      'Intervall der lokalen Ankündigungen';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes Minuten';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervall der gefluteten Ankündigungen';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours Stunden';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Intervall der verschlüsselten Ankündigung';

  @override
  String get repeater_dangerZone => 'Gefahrenzone';

  @override
  String get repeater_rebootRepeater => 'Neustart Repeater';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Repeater-Gerät neu starten.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Sind Sie sicher, dass Sie diesen Repeater neu starten möchten?';

  @override
  String get repeater_regenerateIdentityKey =>
      'Schlüssel für die Identitätswiederherstellung';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Neuen öffentlichen/privaten Schlüsselpaar generieren';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Dies generiert eine neue Identität für den Repeater. Fortfahren?';

  @override
  String get repeater_eraseFileSystem => 'Dateisystem löschen';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatiere die Repeater-Dateisystemdatei';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'WARNUNG: Dies löscht alle Daten auf dem Repeater. Dies kann nicht rückgängig gemacht werden!';

  @override
  String get repeater_eraseSerialOnly =>
      'Löschen ist nur über die serielle Konsole möglich.';

  @override
  String repeater_commandSent(String command) {
    return 'Befehl gesendet: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Fehler beim Senden des Befehls: $error';
  }

  @override
  String get repeater_confirm => 'Bestätigen';

  @override
  String get repeater_settingsSaved => 'Einstellungen erfolgreich gespeichert';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Fehler beim Speichern der Einstellungen: $error';
  }

  @override
  String get repeater_refreshBasicSettings =>
      'Grundlegende Einstellungen aktualisieren';

  @override
  String get repeater_refreshRadioSettings =>
      'Radio-Einstellungen aktualisieren';

  @override
  String get repeater_refreshTxPower => 'Sendeleistung aktualisieren';

  @override
  String get repeater_refreshLocationSettings =>
      'Aktualisieren Sie die Standort Einstellungen';

  @override
  String get repeater_refreshPacketForwarding =>
      'Aktualisieren Paketweiterleitung';

  @override
  String get repeater_refreshGuestAccess => 'Aktualisieren Sie den Gastzugriff';

  @override
  String get repeater_refreshPrivacyMode =>
      'Wiederherstellen des Datenschutzzustands';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Aktualisieren Sie die Ankündigungseinstellungen';

  @override
  String repeater_refreshed(String label) {
    return '$label wurde aktualisiert';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Fehler beim Aktualisieren von $label';
  }

  @override
  String get repeater_cliTitle => 'Repeater CLI';

  @override
  String get repeater_debugNextCommand => 'Fehlersuche des nächsten Befehls';

  @override
  String get repeater_commandHelp => 'Hilfe';

  @override
  String get repeater_clearHistory => 'Löschen der Historie';

  @override
  String get repeater_noCommandsSent => 'Noch keine Befehle gesendet.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Geben Sie unten einen Befehl ein oder verwenden Sie die Schnellbefehle';

  @override
  String get repeater_enterCommandHint => 'Geben Sie den Befehl ein...';

  @override
  String get repeater_previousCommand => 'Vorhergehende Aktion';

  @override
  String get repeater_nextCommand => 'Nächste Aktion';

  @override
  String get repeater_enterCommandFirst => 'Geben Sie zuerst einen Befehl ein';

  @override
  String get repeater_cliCommandFrameTitle => 'CLI-Befehlsfenster';

  @override
  String repeater_cliCommandError(String error) {
    return 'Fehler: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Name erhalten';

  @override
  String get repeater_cliQuickGetRadio => 'Radio empfangen';

  @override
  String get repeater_cliQuickGetTx => 'Erhalte TX';

  @override
  String get repeater_cliQuickNeighbors => 'Nachbarn';

  @override
  String get repeater_cliQuickVersion => 'Version';

  @override
  String get repeater_cliQuickAdvertise => 'Ankündigungen';

  @override
  String get repeater_cliQuickClock => 'Uhr';

  @override
  String get repeater_cliQuickClockSync => 'Uhr Synchronisieren';

  @override
  String get repeater_cliQuickDiscovery => 'Entdecke Nachbarn';

  @override
  String get repeater_cliHelpAdvert => 'Sendet eine Ankündigung';

  @override
  String get repeater_cliHelpReboot =>
      'Startet das Gerät neu. (Beachten Sie, dass es möglicherweise zu einer \'Timeout\'-Situation kommt, was normal ist.)';

  @override
  String get repeater_cliHelpClock =>
      'Zeigt die aktuelle Uhrzeit pro Gerät an.';

  @override
  String get repeater_cliHelpPassword =>
      'Legt ein neues Administrator-Passwort für das Gerät fest.';

  @override
  String get repeater_cliHelpVersion =>
      'Zeigt die Geräteversion und das Datum des Firmware-Builds an.';

  @override
  String get repeater_cliHelpClearStats =>
      'Setzt verschiedene Statistikberechnungen auf Null zurück.';

  @override
  String get repeater_cliHelpSetAf => 'Legt den Luftzeitfaktor fest.';

  @override
  String get repeater_cliHelpSetTx =>
      'Legt die LoRa-Übertragungspower in dBm (bezogen auf 1 Watt) fest. (Neustart erforderlich, um die Änderungen anzuwenden)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Aktiviert oder deaktiviert die Repeater-Rolle für diesen Knoten.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Raumspeicher) Wenn \'an\', dann wird die Anmeldung mit einem leeren Passwort erlaubt sein, aber es kann nicht in den Raum gesendet werden. (nur lesen möglich).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Legt die maximale Anzahl an Hops für Pakete der eingehenden Flut (wenn >= max, wird das Paket nicht weitergeleitet)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Legt den Interferenzeniveau (in dB) fest. Der Standardwert ist 14. Auf 0 setzen, um die Erkennung von Kanalinterferenzen zu deaktivieren.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Legt das Intervall für das Zurücksetzen des Auto Gain Controllers fest. Auf 0 setzen, um die Funktion zu deaktivieren.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Aktiviert oder deaktiviert die Funktion \'Doppel-ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Legt das Timer-Intervall in Minuten fest, um ein lokales (ohne-Weiterleitung) Ankündigungspaket zu senden. Auf 0 setzen, um die Funktion zu deaktivieren.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Legt das Timer-Intervall in Stunden für den Versand eines Flut-Ankündigungspacket fest. Auf 0 setzen, um es zu deaktivieren.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Legt/aktualisiert das Gastpasswort fest. (für Repeater können Gast-Logins die \"Get Stats\"-Anfrage senden)';

  @override
  String get repeater_cliHelpSetName => 'Legt den Anzeigenamen fest.';

  @override
  String get repeater_cliHelpSetLat =>
      'Legt die Breitengrad der Ankündigung fest. (dezimale Grad)';

  @override
  String get repeater_cliHelpSetLon =>
      'Legt die Längengrade der Ankündigung fest. (dezimale Grad)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Legt komplett neue Radio-Parameter fest und speichert diese als Präferenzen. Benötigt einen \"Reboot\"-Befehl, um sie anzuwenden.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Fügt eine leichte Verzögerung bei empfangenen Paketen hinzu, basierend auf Signalstärke/Punktzahl. Auf 0 setzen, um die Funktion zu deaktivieren.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Legt einen Faktor fest, der mit der Zeit bei voller Zuluft für ein Flood-Mode-Paket und mit einem zufälligen Slot-System multipliziert wird, um dessen Weiterleitung zu verzögern (um Kollisionen zu vermeiden).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Ähnlich wie txdelay, aber zum Anwenden einer zufälligen Verzögerung bei der Weiterleitung von Direktmodus-Paketen.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Brücke aktivieren/deaktivieren.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Setze Verzögerung vor erneuter Übertragung von Paketen.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Wählen Sie, ob über die Brücke empfangene oder gesendete Pakete erneut übertragen soll.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Setze die serielle Link-Baudrate für RS232-Brücken.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Richte das Brückenpassword ein.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Legt einen benutzerdefinierten Faktor zur Anpassung der gemeldeten Batteriewirkspannung fest (nur auf ausgewählten Boards unterstützt).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Legt vorübergehende Funkparameter für die angegebene Anzahl von Minuten fest und kehrt anschließend zu den ursprünglichen Funkparametern zurück (wird nicht in den Einstellungen gespeichert).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Ändert die ACL. Entfernt das passende Eintragen (durch Pubkey-Präfix), wenn \"permissions\" auf 0 steht. Fügt ein neues Eintragen hinzu, wenn die Pubkey-Hex-Länge vollständig ist und nicht bereits in der ACL vorhanden ist. Aktualisiert das Eintragen anhand des übereinstimmenden Pubkey-Präfix. Berechtigungsbits variieren je nach Firmware-Rolle, aber die unteren 2 Bits sind: 0 (Gast), 1 (Nur Lesen), 2 (Lesen/Schreiben), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Ruft Brückentyp: none, rs232, espnow ab.';

  @override
  String get repeater_cliHelpLogStart =>
      'Beginnt die Paketprotokollierung in das Dateisystem.';

  @override
  String get repeater_cliHelpLogStop =>
      'Stoppt das Paketprotokollieren in das Dateisystem.';

  @override
  String get repeater_cliHelpLogErase =>
      'Löscht die Paketprotokolle aus dem Dateisystem.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Zeigt eine Liste anderer Repeater-Knoten an, die über Zero-Hop-Ankündigung gehört wurden. Jede Zeile ist id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Entfernt das erste übereinstimmende Element (über Pubkey-Präfix (hex)) aus der Liste der Nachbarn.';

  @override
  String get repeater_cliHelpRegion => 'Listet alle definierten Regionen auf.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'Hinweis: Dies ist ein spezieller Mehrbefehl-Aufruf. Jeder nachfolgende Befehl ist ein Regionsname (eingerückt mit Leerzeichen zur Angabe der übergeordneten Hierarchie, mit mindestens einem Leerzeichen). Beendet durch das Senden einer Leerzeile.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Sucht die Region mit dem gegebenen Namenspräfix (oder \"\\\" für den globalen Scope) und antwortet mit \"-> region-name (parent-name) \'F\'\".';

  @override
  String get repeater_cliHelpRegionPut =>
      'Fügt eine Region-Definition mit dem angegebenen Namen hinzu oder aktualisiert diese.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Löscht eine Regiondefinition mit dem angegebenen Namen. (muss genau übereinstimmen und keine Kindregionen haben)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Legt die \'Flut\'-Berechtigung für die angegebene Region fest. (\'\' für den globalen/legacy-Bereich)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Entfernt die \"F\"lood-Berechtigung für die angegebene Region. (ANMERKUNG: in dieser Phase wird nicht empfohlen, dies auf dem globalen/legacy-Bereich zu verwenden!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Antwortet mit der aktuellen \'Home\'-Region. (Hinweis wurde bisher nirgendwo angewendet, für zukünftige Zwecke reserviert)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Legt die \'Home\'-Region fest.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Speichert die Regionenliste/Karte in den Speicher.';

  @override
  String get repeater_cliHelpGps =>
      'Zeigt GPS-Status an. Wenn GPS deaktiviert ist, antwortet es nur mit \"aus\", wenn es eingeschaltet ist, antwortet es mit \"an\", \"Status\", \"Fix\" und Satellitenanzahl.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Schaltet die GPS-Leistung ein/aus.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronisiert die Knotenzeit mit der GPS-Uhr.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Setze die Position des Knotens auf GPS-Koordinaten und speichere die Präferenzen.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Gibt Konfiguration für die Standortanzeige des Knotens:\n- none: Standort nicht in Anzeigen einbeziehen\n- share: GPS-Standort teilen (von SensorManager)\n- prefs: Standort aus Einstellungen anzeigen';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Legt die Standort-Anzeigekonfiguration fest.';

  @override
  String get repeater_commandsListTitle => 'Befehlsliste';

  @override
  String get repeater_commandsListNote =>
      'ACHTUNG: Für die verschiedenen „set ...“-Befehle gibt es auch einen „get ...“-Befehl.';

  @override
  String get repeater_general => 'Allgemein';

  @override
  String get repeater_settingsCategory => 'Einstellungen';

  @override
  String get repeater_bridge => 'Brücke';

  @override
  String get repeater_logging => 'Protokollierung';

  @override
  String get repeater_neighborsRepeaterOnly => 'Nachbarn (nur Repeater)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Regionenverwaltung (nur Repeater)';

  @override
  String get repeater_regionNote =>
      'Region-Befehle wurden eingeführt, um Region-Definitionen und Berechtigungen zu verwalten.';

  @override
  String get repeater_gpsManagement => 'GPS-Verwaltung';

  @override
  String get repeater_gpsNote =>
      'Der GPS-Befehl wurde eingeführt, um Standortbezogene Themen zu verwalten.';

  @override
  String get telemetry_receivedData => 'Empfangene Telemetriedaten';

  @override
  String get telemetry_requestTimeout =>
      'Telemetry-Anfrage hat zu lange gedauert.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Fehler beim Laden der Telemetrie: $error';
  }

  @override
  String get telemetry_noData => 'Keine Telemetriedaten verfügbar.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Akku';

  @override
  String get telemetry_voltageLabel => 'Spannung';

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
    return '$volts Volt';
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
  String get neighbors_receivedData => 'Empfangene Nachbarsdaten';

  @override
  String get neighbors_requestTimedOut =>
      'Anfrage durch Timeout fehlgeschlagen.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Fehler beim Laden der Nachbarn: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Nachbarn';

  @override
  String get neighbors_noData => 'Keine Nachbarsdaten verfügbar.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Unbekannt $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Gehört vor: $time';
  }

  @override
  String get channelPath_title => 'Paketpfad';

  @override
  String get channelPath_viewMap => 'Karte anzeigen';

  @override
  String get channelPath_otherObservedPaths => 'Sonstige beobachtete Pfade';

  @override
  String get channelPath_repeaterHops => 'Repeater-Sprünge';

  @override
  String get channelPath_noHopDetails =>
      'Die Detailangaben für dieses Paket sind nicht verfügbar.';

  @override
  String get channelPath_messageDetails => 'Nachrichtendetails';

  @override
  String get channelPath_senderLabel => 'Sender';

  @override
  String get channelPath_timeLabel => 'Zeit';

  @override
  String get channelPath_repeatsLabel => 'Wiederholungen';

  @override
  String channelPath_pathLabel(int index) {
    return 'Pfad $index';
  }

  @override
  String get channelPath_observedLabel => 'Beobachtet';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Beobachteter Pfad $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Keine Standortdaten';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Unbekannt';

  @override
  String get channelPath_floodPath => 'Geflutet';

  @override
  String get channelPath_directPath => 'Direkt';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 von $total Sprüngen';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed von $total Sprüngen';
  }

  @override
  String get channelPath_mapTitle => 'Pfadkarte';

  @override
  String get channelPath_noRepeaterLocations =>
      'Für diesen Pfad stehen keine Repeater-Positionen zur Verfügung.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Pfad $index (Primär)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Pfad';

  @override
  String get channelPath_observedPathHeader => 'Beobachteter Pfad';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Keine Informationen zu dieser Paketroute verfügbar.';

  @override
  String get channelPath_unknownRepeater => 'Unbekannter Repeater';

  @override
  String get community_title => 'Community';

  @override
  String get community_create => 'Erstelle Community';

  @override
  String get community_createDesc =>
      'Erstelle eine neue Community und teile sie über den QR-Code.';

  @override
  String get community_join => 'Beitreten';

  @override
  String get community_joinTitle => 'Tritt der Community bei';

  @override
  String community_joinConfirmation(String name) {
    return 'Möchten Sie sich der Community \"$name\" anschließen?';
  }

  @override
  String get community_scanQr => 'Scannen Sie die Community QR-Code';

  @override
  String get community_scanInstructions =>
      'Richten Sie die Kamera auf einen Community-QR-Code.';

  @override
  String get community_showQr => 'Zeige QR-Code';

  @override
  String get community_publicChannel => 'Community Öffentlich';

  @override
  String get community_hashtagChannel => 'Community Hashtag';

  @override
  String get community_name => 'Community Name';

  @override
  String get community_enterName => 'Bitte Community-Name eingeben';

  @override
  String community_created(String name) {
    return 'Community \"$name\" wurde erstellt';
  }

  @override
  String community_joined(String name) {
    return 'Community \"$name\" beigetreten';
  }

  @override
  String get community_qrTitle => 'Teile Community';

  @override
  String community_qrInstructions(String name) {
    return 'Scannen Sie diesen QR-Code, um sich \"$name\" anzuschließen.';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Community-Hashtag-Kanäle können nur von Mitgliedern der Community betreten werden';

  @override
  String get community_invalidQrCode => 'Ungültiger Community-QR-Code';

  @override
  String get community_alreadyMember => 'Bereits registriert';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Sie sind bereits Mitglied von \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Füge einen öffentlichen Community-Kanal hinzu';

  @override
  String get community_addPublicChannelHint =>
      'Automatisch den öffentlichen Kanal für diese Community hinzufügen';

  @override
  String get community_noCommunities => 'Noch keiner Community beigetreten';

  @override
  String get community_scanOrCreate =>
      'Scannen Sie einen QR-Code oder eine Community erstellen, um loszulegen.';

  @override
  String get community_manageCommunities => 'Verwalten von Communities';

  @override
  String get community_delete => 'Verlasse Community';

  @override
  String community_deleteConfirm(String name) {
    return '\"$name\" verlassen?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Dies löscht auch $count Kanal/Kanäle und deren Nachrichten.';
  }

  @override
  String community_deleted(String name) {
    return 'Community \"$name\" verlassen';
  }

  @override
  String get community_regenerateSecret => 'Neugenerierung des Schlüssels';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Nehmen Sie den geheimen Schlüssel für \"$name\" neu auf? Alle Mitglieder müssen den neuen QR-Code scannen, um die Kommunikation fortzusetzen.';
  }

  @override
  String get community_regenerate => 'Neu generieren';

  @override
  String community_secretRegenerated(String name) {
    return 'Wiederherstellung des Schlüssels für \"$name\" erfolgreich';
  }

  @override
  String get community_updateSecret => 'Aktualisieren Sie den Schlüssel';

  @override
  String community_secretUpdated(String name) {
    return 'Schlüssel für \"$name\" aktualisiert';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scannen Sie den neuen QR-Code, um das Geheimnis für \"$name\" zu aktualisieren.';
  }

  @override
  String get community_addHashtagChannel =>
      'Füge einen Community-Hashtag hinzu';

  @override
  String get community_addHashtagChannelDesc =>
      'Füge einen Hashtag-Kanal für diese Community hinzu';

  @override
  String get community_selectCommunity => 'Wählen Sie eine Community';

  @override
  String get community_regularHashtag => 'Regulärer Hashtag';

  @override
  String get community_regularHashtagDesc =>
      'Öffentlicher Hashtag (jeder kann teilnehmen)';

  @override
  String get community_communityHashtag => 'Community Hashtag';

  @override
  String get community_communityHashtagDesc =>
      'Nur für Mitglieder der Community';

  @override
  String community_forCommunity(String name) {
    return 'Für $name';
  }

  @override
  String get listFilter_tooltip => 'Filteren und sortieren';

  @override
  String get listFilter_sortBy => 'Sortiere nach';

  @override
  String get listFilter_latestMessages => 'Letzte Nachrichten';

  @override
  String get listFilter_heardRecently => 'Kürzlich gehört';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtere';

  @override
  String get listFilter_source => 'Quelle';

  @override
  String get listFilter_saved => 'Gespeichert';

  @override
  String get listFilter_discovered => 'Entdeckt';

  @override
  String get listFilter_all => 'Alle';

  @override
  String get listFilter_favorites => 'Favoriten';

  @override
  String get listFilter_addToFavorites => 'Zu Favoriten hinzufügen';

  @override
  String get listFilter_removeFromFavorites => 'Aus Favoriten entfernen';

  @override
  String get listFilter_users => 'Benutzer';

  @override
  String get listFilter_repeaters => 'Repeater';

  @override
  String get listFilter_roomServers => 'Raumserver';

  @override
  String get listFilter_unreadOnly => 'Nicht gelesen';

  @override
  String get listFilter_newGroup => 'Neue Gruppe';

  @override
  String get pathTrace_you => 'Du';

  @override
  String get pathTrace_failed => 'Pfadverfolgung fehlgeschlagen.';

  @override
  String get pathTrace_notAvailable => 'Pfadverfolgung nicht verfügbar.';

  @override
  String get pathTrace_refreshTooltip => 'Path Trace aktualisieren.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Bei einer oder mehreren Knoten fehlt der Standort!';

  @override
  String get pathTrace_clearTooltip => 'Pfad löschen';

  @override
  String get losSelectStartEnd =>
      'Wählen Sie Start- und Endknoten für LOS aus.';

  @override
  String losRunFailed(String error) {
    return 'Sichtlinienprüfung fehlgeschlagen: $error';
  }

  @override
  String get losClearAllPoints => 'Löschen Sie alle Punkte';

  @override
  String get losRunToViewElevationProfile =>
      'Führen Sie LOS aus, um das Höhenprofil anzuzeigen';

  @override
  String get losMenuTitle => 'LOS-Menü';

  @override
  String get losMenuSubtitle =>
      'Tippen Sie auf Knoten oder drücken Sie lange auf die Karte, um benutzerdefinierte Punkte anzuzeigen';

  @override
  String get losShowDisplayNodes => 'Anzeigeknoten anzeigen';

  @override
  String get losCustomPoints => 'Benutzerdefinierte Punkte';

  @override
  String losCustomPointLabel(int index) {
    return 'Benutzerdefiniert $index';
  }

  @override
  String get losPointA => 'Punkt A';

  @override
  String get losPointB => 'Punkt B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenne A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenne B: $value $unit';
  }

  @override
  String get losRun => 'Führen Sie LOS aus';

  @override
  String get losNoElevationData => 'Keine Höhendaten';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, freie Sichtlinie, Mindestabstand $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, blockiert durch $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: Überprüfen...';

  @override
  String get losStatusNoData => 'LOS: keine Daten';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'Sichtlinie: $clear/$total frei, $blocked blockiert, $unknown unbekannt';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Für eine oder mehrere Proben sind keine Höhendaten verfügbar.';

  @override
  String get losErrorInvalidInput =>
      'Ungültige Punkte/Höhendaten für die LOS-Berechnung.';

  @override
  String get losRenameCustomPoint =>
      'Benennen Sie den benutzerdefinierten Punkt um';

  @override
  String get losPointName => 'Punktname';

  @override
  String get losShowPanelTooltip => 'LOS-Panel anzeigen';

  @override
  String get losHidePanelTooltip => 'LOS-Panel ausblenden';

  @override
  String get losElevationAttribution => 'Höhendaten: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Funkhorizont';

  @override
  String get losLegendLosBeam => 'Sichtlinie';

  @override
  String get losLegendTerrain => 'Gelände';

  @override
  String get losFrequencyLabel => 'Frequenz';

  @override
  String get losFrequencyInfoTooltip => 'Details zur Berechnung anzeigen';

  @override
  String get losFrequencyDialogTitle => 'Berechnung des Funkhorizonts';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Ausgehend von k=$baselineK bei $baselineFreq MHz passt die Berechnung den k-Faktor für das aktuelle $frequencyMHz MHz-Band an, das die gekrümmte Funkhorizontobergrenze definiert.';
  }

  @override
  String get contacts_pathTrace => 'Pfadverfolgung';

  @override
  String get contacts_ping => 'Pingen';

  @override
  String get contacts_repeaterPathTrace => 'Pfadverfolgung zum Repeater';

  @override
  String get contacts_repeaterPing => 'Repeater pingen';

  @override
  String get contacts_roomPathTrace => 'Pfadverfolgung zum Raumserver';

  @override
  String get contacts_roomPing => 'Raumserver anpingen';

  @override
  String get contacts_chatTraceRoute => 'Pfadverfolgungsroute';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Route nach $name verfolgen';
  }

  @override
  String get contacts_clipboardEmpty => 'Die Zwischenablage ist leer.';

  @override
  String get contacts_invalidAdvertFormat => 'Ungültige Kontaktdaten';

  @override
  String get contacts_contactImported => 'Kontakt wurde importiert.';

  @override
  String get contacts_contactImportFailed =>
      'Kontakt konnte nicht importiert werden';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name ist bereits in Ihren Kontakten.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Zero-Hop-Ankündigung';

  @override
  String get contacts_floodAdvert => 'Flut-Ankündigung';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Ankündigung in die Zwischenablage kopieren';

  @override
  String get contacts_addContactFromClipboard =>
      'Kontakt aus Zwischenablage hinzufügen';

  @override
  String get contacts_ShareContact => 'Kontakt in die Zwischenablage kopieren';

  @override
  String get contacts_ShareContactZeroHop => 'Kontakt über Anzeige teilen';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Kontakt über Anzeige gesendet';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Kontakt konnte nicht gesendet werden.';

  @override
  String get contacts_contactAdvertCopied =>
      'Anzeige in die Zwischenablage kopiert.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopieren der Ankündigung in die Zwischenablage fehlgeschlagen.';

  @override
  String get contacts_addContact => 'Kontakt hinzufügen';

  @override
  String get contacts_scanQrCode => 'Kontakt-QR scannen';

  @override
  String get contacts_scanQrCodeDesc =>
      'Einen Kontakt-QR-Code aus der MeshCore-App scannen';

  @override
  String get contacts_enterIdHash => 'Kontakt manuell eingeben';

  @override
  String get contacts_enterIdHashDesc =>
      'Kontakt-Ankündigung oder meshcore://-Link einfügen';

  @override
  String get contacts_advertHint =>
      'meshcore://... oder öffentlicher Schlüssel als hex';

  @override
  String get contacts_import => 'Importieren';

  @override
  String get contacts_scanContactInstructions =>
      'Einen MeshCore-Kontakt-QR-Code scannen';

  @override
  String get notification_activityTitle => 'MeshCore Aktivität';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Nachrichten',
      one: 'Nachricht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kanalnachrichten',
      one: 'Kanalnachricht',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'neue Knoten',
      one: 'neuer Knoten',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Neuer $contactType entdeckt';
  }

  @override
  String get notification_receivedNewMessage => 'Neue Nachricht empfangen';

  @override
  String get settings_gpxExportRepeaters =>
      'Repeater und Raumserver als GPX exportieren';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exportiert Repeater und Raumserver mit einem Standort in eine GPX-Datei.';

  @override
  String get settings_gpxExportContacts => 'Kontakte als GPX exportieren';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exportiert Kontakte mit einem Ort in eine GPX-Datei.';

  @override
  String get settings_gpxExportAll => 'Alle Knoten als GPX exportieren';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exportiert alle Knoten mit einem Standort in eine GPX-Datei.';

  @override
  String get settings_gpxExportSuccess => 'GPX-Datei erfolgreich exportiert.';

  @override
  String get settings_gpxExportNoContacts => 'Keine Kontakte zum Exportieren.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Nicht auf Ihrem Gerät/Betriebssystem unterstützt';

  @override
  String get settings_gpxExportError =>
      'Beim Export ist ein Fehler aufgetreten.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Repeater- und Raumserver-Standorte';

  @override
  String get settings_gpxExportChat => 'Kontaktstandorte';

  @override
  String get settings_gpxExportAllContacts => 'Alle Kontaktstandorte';

  @override
  String get settings_gpxExportShareText =>
      'GPX-Kartendaten aus MeshTrax exportiert';

  @override
  String get settings_gpxExportShareSubject =>
      'GPX-Kartendaten aus MeshTrax exportieren';

  @override
  String get snrIndicator_nearByRepeaters => 'In der Nähe befindliche Repeater';

  @override
  String get snrIndicator_lastSeen => 'Zuletzt gesehen';

  @override
  String get contactsSettings_title => 'Kontakteinstellungen';

  @override
  String get contactsSettings_autoAddTitle => 'Automatische Erkennung';

  @override
  String get contactsSettings_otherTitle =>
      'Weitere Einstellungen zu Kontakten';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automatische Hinzufügung von Benutzern';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Ermöglichen Sie dem Begleiter, automatisch entdeckte Benutzer hinzuzufügen';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automatisch Repeater hinzufügen';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Ermöglichen Sie dem Begleiter, automatisch entdeckte Repeater hinzuzufügen.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automatisch Raumservers hinzufügen';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Ermöglichen Sie dem Begleiter, entdeckte Raumserver automatisch hinzuzufügen';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automatisch Sensoren hinzufügen';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Ermöglichen Sie dem Begleiter, automatisch entdeckte Sensoren hinzuzufügen';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Überschreiben des Ältesten';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Wenn die Kontaktliste voll ist, wird der älteste nicht favorisierte Kontakt ersetzt.';

  @override
  String get discoveredContacts_Title => 'Entdeckte Kontakte';

  @override
  String get discoveredContacts_noMatching => 'Keine passenden Kontakte';

  @override
  String get listFilter_searchHint => 'Suchen...';

  @override
  String get discoveredContacts_searchHint => 'Entdeckte Kontakte suchen';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt hinzugefügt';

  @override
  String get discoveredContacts_addContact => 'Kontakt hinzufügen';

  @override
  String get discoveredContacts_copyContact =>
      'Kontakt in die Zwischenablage kopieren';

  @override
  String get discoveredContacts_deleteContact => 'Kontakt löschen';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Alle entdeckten Kontakte löschen';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Sind Sie sicher, dass Sie alle gefundenen Kontakte löschen möchten?';

  @override
  String get chat_sendCooldown =>
      'Bitte warten Sie einen Moment, bevor Sie erneut senden.';

  @override
  String get chat_notConnected =>
      'Nicht mit einem Funkgerät verbunden. Nachricht nicht gesendet.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Zum ältesten, nicht gelesenen Eintrag springen';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Wenn Sie ein Chatfenster öffnen, in dem Nachrichten vorhanden sind, die noch nicht gelesen wurden, scrollen Sie zu der ersten unlesenen Nachricht, anstatt zur neuesten.';

  @override
  String get appSettings_languageHu => 'Ungarisch';

  @override
  String get appSettings_languageJa => 'Japanisch';

  @override
  String get appSettings_languageKo => 'Koreanisch';

  @override
  String get radioStats_screenTitle => 'Senderinformationen';

  @override
  String get radioStats_notConnected =>
      'Verbinden Sie ein Gerät, um Radiostatisiken anzuzeigen.';

  @override
  String get radioStats_firmwareTooOld =>
      'Für die Verwendung der Funkstatistiken ist die Firmware-Version 8 oder höher erforderlich.';

  @override
  String get radioStats_waiting => 'Warte auf Daten…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Rauschpegel: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Letzter RSSI-Wert: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Letzter SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Gesamt-TX-Zeit: $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Gesamt-RX-Zeit: $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Rauschpegel (dBm) basierend auf den letzten Messwerten.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Rauschpegel: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Abrufen von Radiostatus…';

  @override
  String get radioStats_settingsTile => 'Senderinformationen';

  @override
  String get radioStats_settingsSubtitle =>
      'Rauschpegel, RSSI, Signal-Rausch-Verhältnis (SNR) und Nutzzeit';

  @override
  String get translation_title => 'Übersetzung';

  @override
  String get translation_enableTitle => 'Aktivieren Sie die Übersetzung';

  @override
  String get translation_enableSubtitle =>
      'Nachrichten empfangen und übersetzen sowie die Möglichkeit bieten, Nachrichten vor dem Versenden zu übersetzen.';

  @override
  String get translation_composerTitle => 'Übersetzen Sie vor dem Versenden';

  @override
  String get translation_composerSubtitle =>
      'Steuert den Standardzustand des Icons für die Übersetzung des Komponisten.';

  @override
  String get translation_targetLanguage => 'Zielsprache';

  @override
  String get translation_useAppLanguage => 'Verwenden Sie die App-Sprache';

  @override
  String get translation_downloadedModelLabel => 'Heruntergeladenes Modell';

  @override
  String get translation_presetModelLabel =>
      'Vordefinierter Hugging Face-Modell';

  @override
  String get translation_manualUrlLabel => 'URL für das manuelle Modell';

  @override
  String get translation_downloadModel => 'Modell herunterladen';

  @override
  String get translation_downloading => 'Herunterladen...';

  @override
  String get translation_working => 'Arbeiten...';

  @override
  String get translation_stop => 'Stopp';

  @override
  String get translation_mergingChunks =>
      'Zusammenführen der heruntergeladenen Teile in die finale Datei...';

  @override
  String get translation_downloadedModels => 'Heruntergeladene Modelle';

  @override
  String get translation_deleteModel => 'Modell löschen';

  @override
  String get translation_modelDownloaded =>
      'Übersetzungsmotor heruntergeladen.';

  @override
  String get translation_downloadStopped => 'Herunterladen abgebrochen.';

  @override
  String translation_downloadFailed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Geben Sie zunächst die URL eines Modells ein.';

  @override
  String get scanner_linuxPairingShowPin => 'PIN anzeigen';

  @override
  String get scanner_linuxPairingHidePin => 'PIN ausblenden';

  @override
  String get scanner_linuxPairingPinTitle => 'Bluetooth-Paarungs-PIN';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Geben Sie die PIN für $deviceName ein (leer lassen, falls keine).';
  }

  @override
  String get translation_messageTranslation => 'Nachricht übersetzen';

  @override
  String get translation_translateBeforeSending =>
      'Übersetzen Sie vor dem Versenden';

  @override
  String get translation_composerEnabledHint =>
      'Die Nachrichten werden vor dem Versenden übersetzt.';

  @override
  String get translation_composerDisabledHint =>
      'Nachrichten in der ursprünglichen, getippten Sprache senden.';

  @override
  String translation_translateTo(String language) {
    return 'Übersetzen Sie auf $language';
  }

  @override
  String get translation_translationOptions => 'Übersetzungsmöglichkeiten';

  @override
  String get translation_systemLanguage => 'Sprache des Systems';

  @override
  String get routing_title => 'Routing';

  @override
  String routing_route(String route) {
    return 'Gespeicherter Pfad: $route';
  }

  @override
  String get routing_noRoute =>
      'noch keiner — die nächste Nachricht wird geflutet und lernt einen';

  @override
  String get routing_auto => 'Automatisch';

  @override
  String get routing_autoSubtitle =>
      'Den gespeicherten Pfad des Funkgeräts verwenden. Empfohlen.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder an: probiert zuerst gelernte Routen';

  @override
  String get routing_flood => 'Immer fluten';

  @override
  String get routing_floodSubtitle => 'Jede Nachricht geht an das ganze Mesh';

  @override
  String get routing_custom => 'Eigener Pfad';

  @override
  String get routing_customSubtitle => 'Die Repeater selbst wählen';

  @override
  String get routing_forget => 'Pfad zurücksetzen';

  @override
  String get routing_forgetDone =>
      'Pfad zurückgesetzt. Die nächste Nachricht wird geflutet und lernt einen neuen.';

  @override
  String get routing_pathfinder => 'Was Pathfinder weiß';

  @override
  String get routing_pathfinderSubtitle =>
      'Repeater, die Sie und den Kontakt hören, und gelernte Routen hin und zurück';

  @override
  String get path_direct => 'Direkt — keine Repeater';

  @override
  String get path_directSubtitle =>
      'Nur wenn der Kontakt dieses Funkgerät selbst hören kann';

  @override
  String get chat_kindFlood => 'geflutet';

  @override
  String get chat_kindDirect => 'direkt';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprünge',
      one: 'Sprung',
    );
    return 'Route ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sprünge',
      one: 'Sprung',
    );
    return 'Route ($count $_temp0, davon $guessed geraten)';
  }

  @override
  String get chat_statusQueued => 'In Warteschlange';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Kein Repeater hat Sie gehört. Neuer Versuch, sobald einer in Reichweite ist.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'Das Funkgerät von $name sendet kurze Repeater-Codes (1 Byte). Pathfinder kann keine Routen dorthin lernen, bis dieses Funkgerät 2-Byte-Codes verwendet.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Wird gesendet · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Neuer Versuch · $kind · Versuch $attempt von $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Zugestellt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Zugestellt bei Versuch $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Verspätet zugestellt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Zugestellt · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'Versuchen',
      one: 'Versuch',
    );
    return 'Fehlgeschlagen nach $attempts $_temp0 · zum erneuten Senden tippen';
  }

  @override
  String get chat_statusFailedShort =>
      'Fehlgeschlagen · zum erneuten Senden tippen';

  @override
  String get chat_resendingByFlood => 'Wird erneut geflutet';

  @override
  String get pathfinderHelp_title => 'Was Pathfinder macht';

  @override
  String get pathfinderHelp_what =>
      'Ihr Funkgerät merkt sich eine Route zu jedem Kontakt und flutet das ganze Mesh, wenn diese Route nicht funktioniert. Pathfinder hört alles mit, was das Funkgerät empfängt: Ankündigungen von Repeatern, Gespräche in Kanälen, Nachrichten anderer Leute. Daraus erstellt Pathfinder eine Karte, die zeigt, welche Repeater einander hören, von welchen Sie gehört werden und von welchen jeder Ihrer Kontakte gehört wird.';

  @override
  String get pathfinderHelp_how =>
      'Wenn Sie eine Nachricht senden, probiert Pathfinder zuerst seine beste Route, dann die nächstbeste, und flutet nur, wenn alles andere scheitert. Ein bernsteinfarbenes Pfadsymbol kennzeichnet eine Nachricht, die über eine Pathfinder-Route gesendet wurde.';

  @override
  String get pathfinderHelp_learning =>
      'Pathfinder braucht Zeit. Eine neue Karte ist leer, deshalb werden Ihre Nachrichten anfangs genau wie bisher gesendet. Nach einigen Stunden Zuhören an einem Ort beginnt Pathfinder, Routen anzubieten, und jede Zustellung und jeder Fehlschlag bringt ihm mehr bei. Erwarten Sie am ersten Tag nicht viel davon, und nach jedem Ortswechsel zunächst wieder weniger.';

  @override
  String get pathfinderHelp_guessed =>
      'Manchmal schließt Pathfinder eine Lücke, indem er rät: mit einer Verbindung, die er bisher nur in der Gegenrichtung gehört hat. Die Statuszeile der Nachricht zeigt dann, wie viele Sprünge geraten wurden. Eine Zustellung bestätigt sie; ein Fehlschlag kostet einen Versuch, und es wird nichts gespeichert.';

  @override
  String get pathfinderHelp_discover =>
      'Ist Pathfinder nicht sicher, von welchen Repeatern Sie hier gehört werden, sendet er eine kurze Discover-Anfrage (höchstens alle 10 Minuten und nur nach einem fehlgeschlagenen Sendeversuch). Hat Ihr Funkgerät GPS, merkt sich Pathfinder auf diesem Handy für jedes Gebiet von etwa 500 m, von welchen Repeatern Sie dort gehört wurden – aber nie Ihren genauen Standort.';

  @override
  String get pathfinderHelp_off =>
      'Schalten Sie Pathfinder aus, routet das Funkgerät wieder genau wie vorher.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Nicht mehr anzeigen';

  @override
  String get pathfinderHelp_ok => 'OK';

  @override
  String get settings_pathGraph => 'Pathfinder (experimentell)';

  @override
  String get settings_pathGraphSubtitle =>
      'Lernt Routen aus allem, was das Funkgerät hört, und probiert beim Senden einer DM zuerst die besten. Ein bernsteinfarbenes Pfadsymbol kennzeichnet eine Nachricht, die über eine Pathfinder-Route gesendet wurde.';

  @override
  String get map_routeAndTrace => 'Route & Verfolgung';

  @override
  String get map_pathfinderTrace => 'Hin und zurück verfolgen';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Hin auf der besten Route von Pathfinder, zurück auf seiner besten Rückroute';

  @override
  String get map_routeBackMirrored =>
      'Noch keine Rückroute bekannt — zurück auf demselben Weg';

  @override
  String get map_traceHelpTitle => 'Schaltflächen der Pfadverfolgung';

  @override
  String get map_traceHelpCustom => 'Repeater selbst eingeben oder auswählen.';

  @override
  String get map_traceHelpRun =>
      'Sendet eine Verfolgung entlang der angetippten Repeater, in eine Richtung.';

  @override
  String get map_traceHelpThereAndBack => 'Hin und zurück';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Sendet die Verfolgung hin und dann in umgekehrter Reihenfolge über dieselben Repeater zurück.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder wählt die beste Route über die zwei zuletzt angetippten Repeater und die beste Route zurück zu Ihnen. Das Ergebnis zeigt Pathfinder, welche Verbindungen wirklich funktionieren. Dafür müssen zwei Repeater angetippt sein.';

  @override
  String get map_traceHelpRemoveLast =>
      'Entfernt den letzten Repeater aus dem Pfad.';

  @override
  String get map_traceHelpCancel =>
      'Beendet das Erstellen der Verfolgung. Wird angezeigt, bevor ein Repeater angetippt ist.';

  @override
  String get chat_resendingByRoute =>
      'Erneutes Senden über die festgelegte Route';

  @override
  String get room_mute => 'Raum stummschalten';

  @override
  String get room_unmute => 'Stummschaltung des Raums aufheben';

  @override
  String get room_roleAdmin => 'Admin';

  @override
  String get room_roleMember => 'Mitglied';

  @override
  String get room_roleReadOnly => 'nur Lesen';

  @override
  String room_clockOff(int minutes) {
    return 'Die Uhr des Raums weicht um etwa $minutes Min. ab — Nachrichtenzeiten können falsch sein';
  }

  @override
  String get room_fixClock => 'Uhr stellen';

  @override
  String get room_clockSyncSent => 'Zeitabgleich an den Raum gesendet';

  @override
  String get room_readOnlyNotice =>
      'Nur Lesen: Der Raum hat dein Passwort nicht akzeptiert, deine Nachrichten erreichen andere Mitglieder nicht.';

  @override
  String get room_postAnnouncement => 'Ankündigung senden';

  @override
  String get room_postAnnouncementSubtitle =>
      'Eine Nachricht im Namen des Raums an alle Mitglieder senden';

  @override
  String get room_announcementSent => 'Ankündigung veröffentlicht';

  @override
  String get room_announcementFailed => 'Senden der Ankündigung fehlgeschlagen';

  @override
  String get room_users => 'Raum-Benutzer';

  @override
  String get room_usersSubtitle => 'Admins ansehen und Rollen festlegen';

  @override
  String get room_usersAdminsNote =>
      'Der Raum listet nur seine Admins. Mitglieder mit Raum-Passwort werden nicht angezeigt.';

  @override
  String get room_usersLoadFailed => 'Admin-Liste konnte nicht geladen werden';

  @override
  String get room_setUserRole => 'Benutzerrolle festlegen';

  @override
  String get room_removeAccess => 'Zugang entfernen';

  @override
  String get room_removeOnlyUnknown =>
      'Dieser Benutzer ist nicht in deinen Kontakten und kann daher nur entfernt, nicht geändert werden.';

  @override
  String get room_roleUpdated => 'Rolle aktualisiert';

  @override
  String get room_roleUpdateFailed => 'Rollenänderung fehlgeschlagen';

  @override
  String get room_postsStored => 'Gespeicherte Beiträge';

  @override
  String get room_postsDelivered => 'Zugestellte Beiträge';

  @override
  String get room_reloadPosts => 'Letzte Beiträge neu laden';

  @override
  String get room_reloadPostsExplain =>
      'Bittet den Raum, seine letzten Beiträge erneut zu senden (er speichert bis zu 32). Du wirst nach dem Raum-Passwort gefragt. Vorhandene Nachrichten bleiben erhalten.';

  @override
  String get room_reloadFailed =>
      'Raum konnte auf dem Funkgerät nicht zurückgesetzt werden';

  @override
  String get companionCli_title => 'Befehlszeile';

  @override
  String get companionCli_settingsSubtitle =>
      'Textbefehle für dieses Funkgerät eingeben';

  @override
  String get companionCli_rebooting => 'Funkgerät wird neu gestartet…';

  @override
  String get companionCli_cancelled => 'Abgebrochen';

  @override
  String get companionCli_poweringOff => 'Funkgerät wird ausgeschaltet…';

  @override
  String get companionCli_noReply =>
      'Keine Antwort vom Funkgerät. Bitte erneut versuchen.';

  @override
  String get companionCli_powerOffTitle => 'Funkgerät ausschalten?';

  @override
  String get companionCli_powerOffBody =>
      'Es bleibt aus, bis Sie seine Taste drücken oder es an den Strom anschließen.';

  @override
  String get companionCli_powerOff => 'Ausschalten';

  @override
  String get companionCli_quickBoard => 'Platine';

  @override
  String get companionCli_quickWifiStatus => 'WLAN-Status';

  @override
  String get companionCli_quickWifiAddress => 'WLAN-Adresse';

  @override
  String get companionCli_helpBoard =>
      'Zeigt Hersteller und Modell der Platine.';

  @override
  String get companionCli_helpReboot => 'Startet das Funkgerät neu.';

  @override
  String get companionCli_helpPowerOff => 'Schaltet das Funkgerät aus.';

  @override
  String get companionCli_helpSetPin =>
      'Legt die Bluetooth-Kopplungs-PIN fest. Gilt nach einem Neustart.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Legt die Stunden fest, die für die Uhr auf dem eigenen Display des Funkgeräts zu UTC addiert werden (-12 bis +14).';

  @override
  String get companionCli_helpSetTx =>
      'Legt die Sendeleistung in dBm fest. Gilt sofort.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Legt die Störschwelle in dB fest. 0 schaltet die Störungserkennung aus.';

  @override
  String get companionCli_helpSetCad =>
      'Hört vor dem Senden auf andere Funkgeräte (Kanalaktivitätserkennung).';

  @override
  String get companionCli_helpSetRxGain =>
      'Erhöhte Empfangsverstärkung, bei Funkgeräten mit SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bytes pro Repeater in einer Route: 0 = 1 Byte, 1 = 2 Bytes, 2 = 3 Bytes.';

  @override
  String get companionCli_helpWifiStatus =>
      'Zeigt, ob das Funkgerät im WLAN ist.';

  @override
  String get companionCli_helpWifiIp =>
      'Zeigt die Adresse des Funkgeräts im WLAN.';

  @override
  String get companionCli_helpWifiSsid =>
      'Legt den WLAN-Namen fest. Gilt nach einem Neustart.';

  @override
  String get companionCli_helpWifiPwd =>
      'Legt das WLAN-Passwort fest. Gilt nach einem Neustart.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Schaltet WLAN ein (1) oder aus (0). Gilt nach einem Neustart.';

  @override
  String get companionCli_helpWifiClear =>
      'Vergisst das WLAN. Gilt nach einem Neustart.';

  @override
  String get companionCli_remoteNoReply =>
      'Keine Antwort. Das andere Funkgerät braucht Firmware 1.18 oder neuer und muss Ihnen die Nutzung seiner Befehlszeile erlauben.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Gesendet. Ein Funkgerät antwortet nicht auf einen Neustart oder das Ausschalten.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name hat versucht, die Befehlszeile Ihres Funkgeräts zu nutzen: „$command“. Das wurde nicht erlaubt.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Hat versucht, die Befehlszeile Ihres Funkgeräts zu nutzen: „$command“. Das wurde nicht erlaubt.';
  }

  @override
  String get contact_remoteCli => 'Fernzugriff auf Befehlszeile erlauben';

  @override
  String get contact_remoteCliSubtitle =>
      'Lässt diesen Kontakt Befehle auf Ihrem Funkgerät ausführen';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return '$name Ihr Funkgerät steuern lassen?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name kann dann die Einstellungen Ihres Funkgeräts ändern, Ihr WLAN-Passwort lesen, Ihr Funkgerät umbenennen und es neu starten oder ausschalten. Erlauben Sie das nur jemandem, dem Sie voll vertrauen.';
  }

  @override
  String get contact_remoteCliAllow => 'Erlauben';

  @override
  String get connection_secondApp =>
      'Eine andere App ist mit diesem Funkgerät verbunden. Nachrichten und Einstellungen können durcheinandergeraten. Schließen Sie die andere App.';

  @override
  String get wifi_title => 'WLAN';

  @override
  String get wifi_settingsSubtitle => 'Netzwerk, Passwort und Verbindung';

  @override
  String get wifi_use => 'WLAN verwenden';

  @override
  String get wifi_networkName => 'Netzwerkname';

  @override
  String get wifi_password => 'Passwort';

  @override
  String get wifi_passwordUnchanged => 'Unverändert';

  @override
  String get wifi_showPassword => 'Passwort anzeigen';

  @override
  String get wifi_nameMissing => 'Netzwerknamen eingeben';

  @override
  String get wifi_nameTooLong =>
      'Der Netzwerkname ist zu lang (höchstens 32 Bytes)';

  @override
  String get wifi_passwordTooLong =>
      'Das Passwort ist zu lang (höchstens 63 Bytes)';

  @override
  String get wifi_savedRestart =>
      'Gespeichert. WLAN-Änderungen gelten nach dem Neustart des Funkgeräts.';

  @override
  String get wifi_forget => 'Netzwerk vergessen';

  @override
  String get wifi_forgetConfirm =>
      'Dieses WLAN vergessen? Nach dem Neustart nutzt das Funkgerät kein WLAN mehr.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Das Funkgerät hat das nicht akzeptiert: $reply';
  }

  @override
  String get wifi_noReply =>
      'Keine Antwort vom Funkgerät. Bitte erneut versuchen.';

  @override
  String get wifi_restartTitle => 'Funkgerät neu starten?';

  @override
  String get wifi_later => 'Später';

  @override
  String get wifi_loadFailed =>
      'Die WLAN-Einstellungen konnten nicht vom Funkgerät gelesen werden.';

  @override
  String wifi_connectedTo(String address) {
    return 'Verbunden · $address';
  }

  @override
  String get wifi_notConnected => 'Nicht mit WLAN verbunden';

  @override
  String wifi_portNote(int port) {
    return 'Apps im selben Netzwerk können sich über Port $port verbinden';
  }

  @override
  String get wifi_connectOverWifi => 'Über WLAN verbinden';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax trennt die Verbindung zu diesem Funkgerät und öffnet den TCP-Bildschirm mit $address, Port $port bereits ausgefüllt. Tippen Sie dort auf Verbinden.';
  }

  @override
  String get wifi_noteRestart =>
      'Änderungen gelten nach dem Neustart des Funkgeräts.';

  @override
  String get wifi_noteSecurity =>
      'Jeder in Ihrem WLAN kann sich über Port 5000 mit dem Funkgerät verbinden. Dafür gibt es kein Passwort.';

  @override
  String get wifi_noteBattery =>
      'WLAN hält das Funkgerät wach, daher ist der Akku schneller leer.';

  @override
  String get wifi_noteWrongPassword =>
      'Ist das Passwort falsch, versucht es das Funkgerät alle paar Sekunden erneut. Bluetooth funktioniert weiter.';

  @override
  String get room_selfDemoteWarning =>
      'Du änderst deinen eigenen Zugang. Gibst du deine Admin-Rolle ab, kann nur die Konsole des Raums sie zurückgeben.';

  @override
  String get scanner_offlineMaps => 'Offline-Karten';

  @override
  String get appSettings_offlineMaps => 'Offline-Karten';

  @override
  String get appSettings_offlineMapsNone => 'Keine heruntergeladen';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Regionen',
      one: '1 Region',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Seekartengebiete',
      one: '1 Seekartengebiet',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Updates verfügbar',
      one: '1 Update verfügbar',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Karten nur über WLAN herunterladen';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Karten-Downloads warten auf eine WLAN-Verbindung';

  @override
  String get offlineMaps_title => 'Offline-Karten';

  @override
  String get offlineMaps_tabMaps => 'Karten';

  @override
  String get offlineMaps_tabCharts => 'Seekarten';

  @override
  String get offlineMaps_chartsNotice => 'Nicht zur Navigation · Warum?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Vorgeschlagen · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Seekartengebiete nach Küste';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gebiete',
      one: '1 Gebiet',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '$count heruntergeladen';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '$count ausgewählt';
  }

  @override
  String get offlineMaps_selectAll => 'Alle auswählen';

  @override
  String get offlineMaps_clearSelection => 'Aufheben';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Auch in $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Noch nicht verfügbar';

  @override
  String get offlineMaps_chartsHint =>
      'NOAA-Seekarten werden nach Küste im Tab Seekarten ausgewählt.';

  @override
  String offlineMaps_chartsName(String area) {
    return 'NOAA-Seekarten $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Gebiete',
      one: '1 Gebiet',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Heruntergeladen';

  @override
  String get offlineMaps_refresh => 'Nach neuen Karten suchen';

  @override
  String get offlineMaps_loading => 'Verfügbare Karten werden geladen…';

  @override
  String get offlineMaps_serverError => 'Kartenserver nicht erreichbar';

  @override
  String get offlineMaps_unavailable => 'Noch keine Karten verfügbar';

  @override
  String get offlineMaps_unavailableHint => 'Später erneut prüfen.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Noch keine NOAA-Seekarten verfügbar';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Liste vom $date wird angezeigt';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Aktualisieren Sie MeshTrax, um die neuesten Karten zu erhalten.';

  @override
  String get offlineMaps_world => 'Welt';

  @override
  String get offlineMaps_suggested => 'Vorgeschlagen';

  @override
  String get offlineMaps_regions => 'Regionen';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regionen in $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count darin';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size Offline-Karten auf diesem Gerät';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Updates ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Alle aktualisieren $size';
  }

  @override
  String get offlineMaps_downloading => 'Wird heruntergeladen';

  @override
  String get offlineMaps_update => 'Aktualisieren';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Heruntergeladen am $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Update verfügbar';

  @override
  String get offlineMaps_otherFiles => 'Andere Kartendateien';

  @override
  String get offlineMaps_emptyTitle => 'Noch keine Offline-Karten';

  @override
  String get offlineMaps_emptyBody =>
      'Laden Sie eine Region herunter, um die Karte ohne Verbindung zu nutzen.';

  @override
  String get offlineMaps_findMaps => 'Karten finden';

  @override
  String offlineMaps_deleteTitle(String name) {
    return '$name löschen?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Dadurch werden $size frei. Sie können sie später erneut herunterladen.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name gelöscht';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done von $total';
  }

  @override
  String get offlineMaps_kindMap => 'Karte';

  @override
  String get offlineMaps_kindMapDetail => 'OpenStreetMap: Straßen, Wege, Orte';

  @override
  String get offlineMaps_kindContours => 'Höhenlinien';

  @override
  String get offlineMaps_kindContoursDetail => 'Linien gleicher Höhe';

  @override
  String get offlineMaps_kindUsgs => 'USGS-Topokarte';

  @override
  String get offlineMaps_kindUsgsDetail => 'Wege, Bäche, Schutzgebiete';

  @override
  String get offlineMaps_kindTerrain => 'Reliefschattierung';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Hügel und Berge, schattiert unter der Karte';

  @override
  String get offlineMaps_kindCharts => 'NOAA-Seekarten';

  @override
  String get offlineMaps_usOnly => 'Nur USA';

  @override
  String offlineMaps_download(String size) {
    return '$size herunterladen';
  }

  @override
  String get offlineMaps_downloadTotal => 'Herunterladen';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Großer Download ($size). Nutzen Sie WLAN und lassen Sie Ihr Gerät dabei laden.';
  }

  @override
  String get offlineMaps_waiting => 'Warten…';

  @override
  String get offlineMaps_checking => 'Download wird geprüft…';

  @override
  String get offlineMaps_retrying => 'Neuer Versuch…';

  @override
  String offlineMaps_failed(String error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get offlineMaps_pause => 'Pausieren';

  @override
  String get offlineMaps_resume => 'Fortsetzen';

  @override
  String get offlineMaps_deleteRegion => 'Region löschen';

  @override
  String get offlineMaps_notInCatalogue => 'Für diese Region nicht verfügbar';

  @override
  String get offlineMaps_notificationRunning => 'Karte wird heruntergeladen';

  @override
  String get offlineMaps_notificationPaused => 'Karten-Download pausiert';

  @override
  String get offlineMaps_notificationFailed => 'Karten-Download fehlgeschlagen';

  @override
  String get offlineMaps_clearTileCache =>
      'Zwischengespeicherte Online-Kartenkacheln löschen';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Die beim Ansehen der Karte gespeicherten Online-Kartenkacheln entfernen? Heruntergeladene Karten bleiben erhalten.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Zwischengespeicherte Online-Kartenkacheln entfernt';

  @override
  String get map_notForNavigation => 'Nicht zur Navigation';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax zeichnet diese Karten aus den Seekartendaten der NOAA, damit Sie das Wasser rund um Ihre Funkgeräte sehen und planen können. Es sind keine amtlichen Seekarten. Navigieren Sie nicht danach.';

  @override
  String get map_chartsNoticeWhy => 'Warum:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Sie veralten. Die NOAA berichtigt ihre Seekarten ständig; eine heruntergeladene Karte bleibt unverändert, bis Sie sie unter Offline-Karten aktualisieren.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Sie lassen Dinge weg. Viele Kartensymbole, Feuersektoren und Hinweise werden nicht gezeichnet, und manche Beschriftungen erscheinen erst beim Hineinzoomen.';

  @override
  String get map_chartsNoticePositions =>
      'Positionen können falsch oder veraltet sein. GPS kann 10 m (30 ft) oder mehr danebenliegen, und ein Knoten ist nur dort, wo er sich zuletzt gemeldet hat.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax ist kein zertifizierter Kartenplotter.';

  @override
  String get map_chartsNoticeUse =>
      'Verwenden Sie zur Navigation amtliche, aktuelle NOAA-Seekarten (auf Papier oder NOAA-ENCs in einem zertifizierten Kartenplotter) mit den neuesten Nachrichten für Seefahrer.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail => 'Region für mehr Details herunterladen';

  @override
  String get map_zoomInForOfflineMap =>
      'Hineinzoomen, um Ihre Offline-Karte zu sehen';

  @override
  String get map_noCharts => 'Hier keine Seekarten';

  @override
  String get map_myLocation => 'Mein Standort';

  @override
  String get map_zoomIn => 'Vergrößern';

  @override
  String get map_zoomOut => 'Verkleinern';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS an';

  @override
  String get gps_off => 'GPS aus';

  @override
  String get gps_onHint => 'Das Funkgerät aktualisiert seine Position per GPS.';

  @override
  String get gps_offHint =>
      'Aus schont den Akku des Funkgeräts. Nach dem Einschalten kann es einige Minuten dauern, bis Ihre Position gefunden ist.';

  @override
  String get gps_asking => 'Funkgerät wird abgefragt...';

  @override
  String get gps_noPosition =>
      'Noch keine Position. Im Freien kann die erste einige Minuten dauern.';

  @override
  String get gps_position => 'Position';

  @override
  String get gps_altitude => 'Höhe';

  @override
  String gps_readAgo(String ago) {
    return 'Vor $ago vom Funkgerät gelesen';
  }

  @override
  String get gps_turnOnTitle => 'GPS einschalten?';

  @override
  String get gps_turnOnBody =>
      'Das GPS des Funkgeräts ist aus. Nach dem Einschalten kann es einige Minuten dauern, bis Ihre Position gefunden ist.';

  @override
  String get gps_turnOn => 'Einschalten';

  @override
  String get gps_notNow => 'Nicht jetzt';

  @override
  String get map_zoomInForCharts => 'Hineinzoomen, um Ihre Seekarten zu sehen';

  @override
  String map_downloadRegion(String region, String size) {
    return '$region herunterladen · $size';
  }

  @override
  String get mapLayers_title => 'Kartenebenen';

  @override
  String get mapLayers_mapType => 'Kartentyp';

  @override
  String get mapLayers_standard => 'Standard';

  @override
  String get mapLayers_usgs => 'USGS-Topo';

  @override
  String get mapLayers_charts => 'Seekarten';

  @override
  String get mapLayers_notDownloaded => 'Nicht heruntergeladen';

  @override
  String get mapLayers_offlineOnly => 'Nur offline';

  @override
  String get mapLayers_details => 'Kartendetails';

  @override
  String get mapLayers_contours => 'Höhenlinien';

  @override
  String get mapLayers_hillShading => 'Reliefschattierung';

  @override
  String get mapLayers_places => 'Places';

  @override
  String get mapLayers_parks => 'Parks';

  @override
  String get mapLayers_dark => 'Dunkle Karte';

  @override
  String get mapLayers_downloadedAreas => 'Heruntergeladene Gebiete';

  @override
  String get mapLayers_nodes => 'Knoten';

  @override
  String get mapLayers_pins => 'Pins';

  @override
  String get mapLayers_guessed => 'Geschätzt';

  @override
  String get mapLayers_moreFilters => 'Weitere Filter';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Zuletzt gesehen, Schlüsselpräfix, Überlappungen';

  @override
  String get map_legend => 'Legende';

  @override
  String get scanner_map => 'Karte';

  @override
  String get structured_openMap => 'Karte öffnen';

  @override
  String get structured_addToCalendar => 'Zum Kalender hinzufügen';

  @override
  String get structured_details => 'Details';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Termin';

  @override
  String get structured_notice => 'Hinweis';

  @override
  String get structured_allDay => 'Ganztägig';

  @override
  String get structured_calendarFailed =>
      'Kalender konnte nicht geöffnet werden';

  @override
  String get structured_today => 'Heute';

  @override
  String get structured_tomorrow => 'Morgen';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'In $count Tagen',
      one: 'In 1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Vorbei';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Tag $day von $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage',
      one: '1 Tag',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Enddatum';

  @override
  String get dialog_eventSameDay => 'Gleicher Tag';

  @override
  String get structured_map => 'Karte';

  @override
  String get structured_navigate => 'Navigieren';

  @override
  String get structured_channel => 'Kanal';

  @override
  String get structured_contact => 'Kontakt';

  @override
  String get structured_room => 'Raum';

  @override
  String get structured_repeater => 'Repeater';

  @override
  String get structured_sensor => 'Sensor';

  @override
  String get structured_joinChannel => 'Kanal beitreten';

  @override
  String get structured_addContact => 'Kontakt hinzufügen';

  @override
  String get structured_addRoom => 'Raum hinzufügen';

  @override
  String get structured_addRepeater => 'Repeater hinzufügen';

  @override
  String get structured_addSensor => 'Sensor hinzufügen';

  @override
  String get structured_open => 'Öffnen';

  @override
  String get structured_added => 'Hinzugefügt';

  @override
  String get tray_add => 'Hinzufügen';

  @override
  String get tray_myLocation => 'Mein Standort';

  @override
  String get tray_pointOnMap => 'Punkt auf der Karte';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Termin';

  @override
  String get tray_notice => 'Hinweis';

  @override
  String get tray_noRadioPosition =>
      'Ihr Funkgerät hat noch keine Position. Wählen Sie eine auf der Karte.';

  @override
  String get dialog_insert => 'Einfügen';

  @override
  String get dialog_eventTitle => 'Titel';

  @override
  String get dialog_eventDate => 'Datum';

  @override
  String get dialog_eventStart => 'Beginn';

  @override
  String get dialog_eventEnd => 'Ende';

  @override
  String get dialog_eventNoEnd => 'Keine Endzeit';

  @override
  String get dialog_eventPlace => 'Ort (optional)';

  @override
  String get dialog_pickOnMap => 'Auf der Karte wählen';

  @override
  String get dialog_sosTitle => 'SOS senden';

  @override
  String get dialog_sosText => 'Was ist passiert?';

  @override
  String get dialog_noticeTitle => 'Hinweis';

  @override
  String get dialog_noticeText => 'Was sollen alle wissen?';

  @override
  String get dialog_labelTitle => 'Punkt auf der Karte';

  @override
  String get dialog_note => 'Notiz (optional)';

  @override
  String get paste_convertLocation =>
      'Sieht aus wie ein Kartenlink. In einen Standort umwandeln?';

  @override
  String get paste_convertEvent =>
      'Sieht aus wie ein geteilter Kalendertermin. In einen Termin umwandeln?';

  @override
  String get paste_convert => 'Umwandeln';

  @override
  String get paste_resolving => 'Link wird aufgelöst…';

  @override
  String get paste_resolveFailed => 'Link konnte nicht aufgelöst werden';

  @override
  String get pinned_dismiss => 'Ausblenden';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Kanal $name beitreten?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Sie sind bereits in $name';
  }

  @override
  String link_channelJoined(String name) {
    return '$name beigetreten';
  }

  @override
  String get map_pickPositionHint =>
      'Tippen Sie auf die Karte, um eine Position zu wählen';

  @override
  String get map_legendMesh => 'Mesh';

  @override
  String get chartLegend_title => 'Seekartensymbole';

  @override
  String get chartLegend_sectionBuoys => 'Tonnen und Baken';

  @override
  String get chartLegend_sectionLights => 'Leuchtfeuer';

  @override
  String get chartLegend_sectionHazards => 'Gefahren';

  @override
  String get chartLegend_sectionTides => 'Gezeiten und Strömungen';

  @override
  String get chartLegend_sectionDepths => 'Tiefen und Meeresgrund';

  @override
  String get chartLegend_sectionAreas => 'Gebiete, Wege und Linien';

  @override
  String get chartLegend_sectionLandmarks => 'Landmarken';

  @override
  String get chartLegend_sectionAbbreviations => 'Abkürzungen';

  @override
  String get chartLegend_chartNo1 => 'Alle Kartensymbole: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Grüne Stumpftonne';

  @override
  String get chartLegend_portBuoyHint => 'Von See kommend links liegen lassen';

  @override
  String get chartLegend_starboardBuoy => 'Rote Spitztonne';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Beim Einlaufen rechts liegen lassen: Rot liegt auf dem Rückweg rechts';

  @override
  String get chartLegend_junctionBuoy => 'Gebänderte Tonne';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Eine Fahrwassergabelung: wie die Farbe ihres obersten Bandes behandeln';

  @override
  String get chartLegend_safeWaterBuoy => 'Rot-weiße Streifen';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Ringsum sicheres Wasser, oft an einer Fahrwassereinfahrt';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Schwarz-rote Bänder';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Kleine Gefahrenstelle mit sicherem Wasser ringsum: Abstand halten';

  @override
  String get chartLegend_specialBuoy => 'Gelbe Tonne';

  @override
  String get chartLegend_specialBuoyHint =>
      'Sonderzeichen, nicht zum Navigieren: Ankerplatz, Kabel, Forschung';

  @override
  String get chartLegend_cardinalBuoy => 'Schwarz und gelb';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Kardinalzeichen: auf der Seite passieren, nach der es benannt ist (in den USA selten)';

  @override
  String get chartLegend_mooringBuoy => 'Festmachertonne';

  @override
  String get chartLegend_portBeacon => 'Grüne viereckige Bake';

  @override
  String get chartLegend_portBeaconHint =>
      'Wie eine grüne Tonne: beim Einlaufen links liegen lassen';

  @override
  String get chartLegend_starboardBeacon => 'Rote dreieckige Bake';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Wie eine rote Tonne: beim Einlaufen rechts liegen lassen';

  @override
  String get chartLegend_otherBeacon => 'Rautenförmige Bake';

  @override
  String get chartLegend_otherBeaconHint =>
      'Information oder Warnung, keine Fahrwasserseite';

  @override
  String get chartLegend_beaconTower => 'Leuchtturm oder Bakengerüst';

  @override
  String get chartLegend_topmark => 'Toppzeichen';

  @override
  String get chartLegend_topmarkHint =>
      'Die Form oben auf einem Zeichen ergänzt seine Bedeutung';

  @override
  String get chartLegend_light => 'Leuchtfeuer';

  @override
  String get chartLegend_lightHint =>
      'Das magentafarbene Lichtsymbol markiert ein Feuer; seine Beschriftung zeigt die Kennung';

  @override
  String get chartLegend_lightExample => 'Grünes Blitzfeuer, alle 4 Sekunden';

  @override
  String get chartLegend_lightExampleHint =>
      'Beschriftung eines Feuers: Kennung, Farbe, dann Wiederkehr';

  @override
  String get chartLegend_lightFixed => 'Festfeuer';

  @override
  String get chartLegend_lightFixedHint => 'Ein gleichbleibendes Licht';

  @override
  String get chartLegend_lightFlashing => 'Blitzfeuer';

  @override
  String get chartLegend_lightFlashingHint =>
      'Kurze Blitze, dazwischen längere Dunkelheit';

  @override
  String get chartLegend_lightGroup => 'Gruppenblitz';

  @override
  String get chartLegend_lightGroupHint =>
      'Blitze in Gruppen, hier 2, dann dunkel';

  @override
  String get chartLegend_lightComposite => 'Zusammengesetzte Gruppe';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 Blitze, dann 1: markiert eine Fahrwassergabelung';

  @override
  String get chartLegend_lightQuick => 'Funkelfeuer';

  @override
  String get chartLegend_lightQuickHint => 'Etwa ein Blitz pro Sekunde';

  @override
  String get chartLegend_lightIsophase => 'Gleichtaktfeuer';

  @override
  String get chartLegend_lightIsophaseHint =>
      'Licht und Dunkelheit gleich lang';

  @override
  String get chartLegend_lightOcculting => 'Unterbrochenes Feuer';

  @override
  String get chartLegend_lightOccultingHint => 'Länger an als aus';

  @override
  String get chartLegend_lightMorse => 'Morsezeichen A';

  @override
  String get chartLegend_lightMorseHint => 'Kurz, lang: sicheres Wasser';

  @override
  String get chartLegend_lightAlternating => 'Wechselfeuer';

  @override
  String get chartLegend_lightAlternatingHint => 'Wechselt die Farbe';

  @override
  String get chartLegend_lightColours => 'Weiß, rot, grün, gelb';

  @override
  String get chartLegend_lightPeriod => 'Wiederkehr';

  @override
  String get chartLegend_lightPeriodHint => 'Sekunden für einen vollen Zyklus';

  @override
  String get chartLegend_rock => 'Unterwasserfelsen';

  @override
  String get chartLegend_rockHint => 'Immer bedeckt, kann aber flach liegen';

  @override
  String get chartLegend_rockAwash => 'Fels in Wasserhöhe';

  @override
  String get chartLegend_rockAwashHint =>
      'Bei Niedrigwasser nahe der Oberfläche';

  @override
  String get chartLegend_rockCovers => 'Trockenfallender Fels';

  @override
  String get chartLegend_rockCoversHint =>
      'Bei Niedrigwasser sichtbar, bei Hochwasser bedeckt';

  @override
  String get chartLegend_wreckDangerous => 'Gefährliches Wrack';

  @override
  String get chartLegend_wreckDangerousHint => 'Flach genug, um aufzulaufen';

  @override
  String get chartLegend_wreck => 'Wrack';

  @override
  String get chartLegend_wreckHint =>
      'Tief genug für Boote an der Oberfläche; nicht ankern';

  @override
  String get chartLegend_wreckShowing => 'Sichtbares Wrack';

  @override
  String get chartLegend_wreckShowingHint => 'Ein Teil ragt aus dem Wasser';

  @override
  String get chartLegend_obstruction => 'Hindernis';

  @override
  String get chartLegend_obstructionHint =>
      'Etwas am Grund; mit Tiefe, falls bekannt';

  @override
  String get chartLegend_foulGround => 'Unreiner Grund';

  @override
  String get chartLegend_foulGroundHint =>
      'Überfahren ist sicher, aber nicht ankern oder mit Schleppnetz fischen';

  @override
  String get chartLegend_hazardArea => 'Grenze eines Gefahrengebiets';

  @override
  String get chartLegend_hazardAreaHint =>
      'Felsen, Wracks oder Hindernisse darin';

  @override
  String get chartLegend_pile => 'Pfahl oder Pfosten';

  @override
  String get chartLegend_floodStream => 'Flutstrom';

  @override
  String get chartLegend_floodStreamHint =>
      'Gezeitenstrom bei steigendem Wasser';

  @override
  String get chartLegend_ebbStream => 'Ebbstrom';

  @override
  String get chartLegend_ebbStreamHint => 'Gezeitenstrom bei fallendem Wasser';

  @override
  String get chartLegend_current => 'Strömung';

  @override
  String get chartLegend_currentHint =>
      'Fließt unabhängig von der Gezeit in dieselbe Richtung';

  @override
  String get chartLegend_rips => 'Stromkabbelung oder Wirbel';

  @override
  String get chartLegend_ripsHint => 'Unruhiges, wirbelndes Wasser';

  @override
  String get chartLegend_breakers => 'Brandung';

  @override
  String get chartLegend_breakersHint => 'Wellen, die über Untiefen brechen';

  @override
  String get chartLegend_sounding => 'Lotung';

  @override
  String get chartLegend_soundingHint =>
      'Tiefe bei durchschnittlichem Niedrigwasser';

  @override
  String get chartLegend_depthContour => 'Tiefenlinie';

  @override
  String get chartLegend_depthContourHint =>
      'Ihre Beschriftung gibt die Tiefe an';

  @override
  String get chartLegend_drying => 'Fällt bei Niedrigwasser trocken';

  @override
  String get chartLegend_dredged => 'Ausgebaggertes Fahrwasser';

  @override
  String get chartLegend_dredgedHint => 'Auf der angegebenen Tiefe gehalten';

  @override
  String get chartLegend_swept => 'Abgesuchtes Gebiet';

  @override
  String get chartLegend_sweptHint =>
      'Bis zur angegebenen Tiefe als frei geprüft';

  @override
  String get chartLegend_unsurveyed => 'Nicht vermessen';

  @override
  String get chartLegend_unsurveyedHint => 'Keine Tiefen gemessen';

  @override
  String get chartLegend_weed => 'Kelp oder Seetang';

  @override
  String get chartLegend_restricted => 'Beschränkungsgebiet';

  @override
  String get chartLegend_restrictedHint =>
      'Zugang eingeschränkt; die Striche zeigen nach innen';

  @override
  String get chartLegend_regulatedLimit => 'Grenze eines geregelten Gebiets';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Ankerplatz, Kabelgebiet, Schießgebiet und mehr: siehe Beschriftung';

  @override
  String get chartLegend_greyLimit =>
      'Verklappungsgebiet, Fischgrund oder Aquakultur';

  @override
  String get chartLegend_anchorage => 'Ankerplatz';

  @override
  String get chartLegend_anchorBerth => 'Ankerliegeplatz';

  @override
  String get chartLegend_noAnchoring => 'Ankern verboten';

  @override
  String get chartLegend_caution => 'Warngebiet';

  @override
  String get chartLegend_cautionHint => 'Hier besonders vorsichtig sein';

  @override
  String get chartLegend_trafficLane => 'Einbahnweg';

  @override
  String get chartLegend_trafficLaneHint =>
      'Große Schiffe, eine Richtung: rechtwinklig queren';

  @override
  String get chartLegend_separationZone => 'Trennzone';

  @override
  String get chartLegend_separationZoneHint =>
      'Zwischen Einbahnwegen: nicht befahren';

  @override
  String get chartLegend_precautionary => 'Vorsichtsgebiet';

  @override
  String get chartLegend_precautionaryHint =>
      'Schiffe laufen zusammen: Vorsicht';

  @override
  String get chartLegend_fairway => 'Fahrwasser';

  @override
  String get chartLegend_fairwayHint => 'Ein Hauptfahrwasser';

  @override
  String get chartLegend_track => 'Empfohlene Kurslinie';

  @override
  String get chartLegend_ferry => 'Fährlinie';

  @override
  String get chartLegend_leadingLine => 'Leitlinie';

  @override
  String get chartLegend_leadingLineHint =>
      'Die beiden Marken in Deckung halten, um im Fahrwasser zu bleiben';

  @override
  String get chartLegend_cable => 'Unterwasserkabel';

  @override
  String get chartLegend_cableHint => 'Nicht ankern';

  @override
  String get chartLegend_pipeline => 'Unterwasser-Rohrleitung';

  @override
  String get chartLegend_pipelineHint => 'Nicht ankern';

  @override
  String get chartLegend_overhead => 'Freileitung';

  @override
  String get chartLegend_overheadHint =>
      'Ihre Durchfahrtshöhe ist mit VC beschriftet';

  @override
  String get chartLegend_tower => 'Turm';

  @override
  String get chartLegend_windTurbine => 'Windkraftanlage';

  @override
  String get chartLegend_chimney => 'Schornstein';

  @override
  String get chartLegend_mast => 'Mast oder Antenne';

  @override
  String get chartLegend_church => 'Kirche oder Kirchturm';

  @override
  String get chartLegend_flagstaff => 'Flaggenmast';

  @override
  String get chartLegend_dome => 'Kuppel';

  @override
  String get chartLegend_landmark => 'Sonstige Landmarke';

  @override
  String get chartLegend_abbrAnch => 'Ankerplatz';

  @override
  String get chartLegend_abbrWk => 'Wrack';

  @override
  String get chartLegend_abbrBr => 'Brandung';

  @override
  String get chartLegend_abbrWd => 'Seetang';

  @override
  String get chartLegend_abbrVar => 'Missweisung';

  @override
  String get chartLegend_abbrVc =>
      'Durchfahrtshöhe unter einer Brücke oder Leitung';

  @override
  String get chartLegend_abbrTr => 'Turm';

  @override
  String get chartLegend_abbrCh => 'Kirche';

  @override
  String get chartLegend_abbrChy => 'Schornstein';

  @override
  String get chartLegend_abbrFs => 'Flaggenmast';

  @override
  String get chartLegend_abbrTk => 'Tank';

  @override
  String get chartLegend_abbrRBn => 'Funkfeuer';

  @override
  String get chartLegend_abbrCg => 'Station der Küstenwache';

  @override
  String get chartLegend_abbrRacon => 'Radarantwortbake: im Radar sichtbar';

  @override
  String get chartLegend_abbrFog =>
      'Nebelsignal: Horn, Glocke, Gong, Pfeife oder Sirene';

  @override
  String get chartLegend_abbrVAis =>
      'Virtuelles Seezeichen: nur per AIS sichtbar';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from bis $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Tiefer als $depth';
  }

  @override
  String get parkLegend_title => 'Park- und Wegsymbole';

  @override
  String get parkLegend_campsite => 'Campingplatz';

  @override
  String get parkLegend_picnicSite => 'Picknickplatz';

  @override
  String get parkLegend_shelter => 'Schutzhütte';

  @override
  String get parkLegend_toilets => 'Toiletten';

  @override
  String get parkLegend_drinkingWater => 'Trinkwasser';

  @override
  String get parkLegend_parking => 'Parkplatz';

  @override
  String get parkLegend_viewpoint => 'Aussichtspunkt';

  @override
  String get parkLegend_attraction => 'Sehenswürdigkeit';

  @override
  String get parkLegend_gate => 'Tor';

  @override
  String get parkLegend_telephone => 'Telefon';

  @override
  String get parkLegend_information => 'Infotafel';

  @override
  String get parkLegend_guidepost => 'Wegweiser';

  @override
  String get dialog_noticeExpires => 'Gültig bis';

  @override
  String get dialog_noticeNoExpiry => 'Unbegrenzt';

  @override
  String get dialog_noticeExpiryRequired =>
      'Datum wählen (in Räumen erforderlich)';

  @override
  String get dialog_noticeExpiryTime => 'Uhrzeit';

  @override
  String get dialog_noticeEndOfDay => 'Ende des Tages';

  @override
  String structured_until(String when) {
    return 'Bis $when';
  }

  @override
  String get structured_expired => 'Abgelaufen';

  @override
  String get structured_announcement => 'Ankündigung';

  @override
  String structured_locationOf(String name) {
    return 'Standort von $name';
  }

  @override
  String get reaction_searchHint => 'Emoji suchen';

  @override
  String get reaction_noResults => 'Keine Emojis gefunden';

  @override
  String get share_qrAndLink => 'QR-Code und Link teilen';

  @override
  String get share_roomTitle => 'Raum teilen';

  @override
  String get share_contactTitle => 'Kontakt teilen';

  @override
  String get share_roomInstructions =>
      'Scannen, um diesen Raum hinzuzufügen. Zum Anmelden wird das Raum-Passwort benötigt.';

  @override
  String get share_contactInstructions =>
      'Scannen, um diesen Kontakt hinzuzufügen.';

  @override
  String get clearChat_body =>
      'Nachrichten dieses Chats auf diesem Gerät löschen. Neue Nachrichten kommen weiterhin hier an.';

  @override
  String get clearChat_olderThanDay => 'Älter als 1 Tag';

  @override
  String get clearChat_olderThanWeek => 'Älter als 1 Woche';

  @override
  String get clearChat_olderThanMonth => 'Älter als 1 Monat';

  @override
  String get clearChat_everything => 'Alle Nachrichten';

  @override
  String get chats_markAllRead => 'Alle als gelesen markieren';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Chats als gelesen markieren?',
      one: '1 Chat als gelesen markieren?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Markieren';

  @override
  String get chats_nothingUnread => 'Keine ungelesenen Nachrichten';

  @override
  String get chats_draft => 'Entwurf';

  @override
  String get contact_teleBlockedTitle => 'Von Ihrem Funkgerät gesperrt';

  @override
  String contact_teleBlockedBody(String name) {
    return 'Die Datenschutzeinstellungen Ihres Funkgeräts teilen das mit niemandem, daher erhält $name es nicht. Ändern, damit die Kontakte, denen Sie es erlauben, es erhalten?';
  }

  @override
  String get contact_teleNotNow => 'Nicht jetzt';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'Ihr Funkgerät teilt das mit niemandem ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'Ihr Funkgerät teilt das mit allen ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Kann Ihren Standort abrufen';

  @override
  String get pathfinder_meshTitle => 'Ein anderes Mesh?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '$unknown von $heard Repeatern, die seit dem Verbinden zu hören waren, sind der Pathfinder-Karte „$graph“ neu. Eine neue Karte für diese Gegend anlegen? Die alte bleibt, und Sie können im Pathfinder-Bildschirm zurückwechseln.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'Die meisten Repeater, die seit dem Verbinden zu hören waren, stehen in der Pathfinder-Karte „$other“, nicht in „$graph“. Zu ihr wechseln?';
  }

  @override
  String get pathfinder_meshNew => 'Neue Karte';

  @override
  String get pathfinder_meshSwitch => 'Wechseln';

  @override
  String get pathfinder_meshKeep => 'Diese behalten';

  @override
  String get pathfinder_graphNameTitle => 'Name der neuen Karte';

  @override
  String get pathfinder_graphNameHint => 'Zum Beispiel Washington';

  @override
  String get pathfinder_graphCreate => 'Anlegen';

  @override
  String get route_pathPaved => 'Paved';

  @override
  String get route_pathDirt => 'Dirt';

  @override
  String get route_pathHiking => 'Hiking';

  @override
  String route_minutes(int minutes) {
    return '$minutes min';
  }

  @override
  String route_hoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String route_to(String destination) {
    return 'To $destination';
  }

  @override
  String get route_clear => 'Clear route';

  @override
  String get route_finding => 'Finding a route…';

  @override
  String get route_none => 'No route found';

  @override
  String route_endsShortPaved(String distance, String destination) {
    return 'Ends $distance before $destination, where the pavement ends.';
  }

  @override
  String route_endsShortDirt(String distance, String destination) {
    return 'Ends $distance before $destination, where the road ends.';
  }

  @override
  String route_endsShortHiking(String distance, String destination) {
    return 'Ends $distance before $destination, where the trails end.';
  }

  @override
  String get route_directions => 'Directions';

  @override
  String get route_here => 'Route here';

  @override
  String get place_nrhp => 'National Register of Historic Places';

  @override
  String get place_textCredit => 'Text: Wikipedia, CC BY-SA 4.0';

  @override
  String get place_readOnWikipedia => 'Read on Wikipedia';

  @override
  String place_photoCredit(String author, String licence) {
    return 'Photo: $author, $licence';
  }

  @override
  String get search_hint => 'Search places, addresses or coordinates';

  @override
  String get search_noPlaces =>
      'Download Points of interest for a region to search its places. Coordinates work without it.';

  @override
  String get search_noResults => 'No matches';

  @override
  String get coordFormat_decimalDegrees => 'Decimal degrees';

  @override
  String get coordFormat_degreesMinutes => 'Degrees and minutes';

  @override
  String get coordFormat_dms => 'Degrees, minutes, seconds';

  @override
  String get coordFormat_utm => 'UTM';

  @override
  String get coordFormat_mgrs => 'MGRS / USNG';

  @override
  String get coordFormat_maidenhead => 'Maidenhead grid';

  @override
  String get coordFormat_geohash => 'Geohash';

  @override
  String get poiKind_peak => 'Peak';

  @override
  String get poiKind_volcano => 'Volcano';

  @override
  String get poiKind_saddle => 'Saddle';

  @override
  String get poiKind_pass => 'Mountain pass';

  @override
  String get poiKind_spring => 'Spring';

  @override
  String get poiKind_hotSpring => 'Hot spring';

  @override
  String get poiKind_waterfall => 'Waterfall';

  @override
  String get poiKind_cave => 'Cave';

  @override
  String get poiKind_arch => 'Arch';

  @override
  String get poiKind_glacier => 'Glacier';

  @override
  String get poiKind_rock => 'Rock';

  @override
  String get poiKind_cliff => 'Cliff';

  @override
  String get poiKind_beach => 'Beach';

  @override
  String get poiKind_trailhead => 'Trailhead';

  @override
  String get poiKind_campground => 'Campground';

  @override
  String get poiKind_picnicSite => 'Picnic site';

  @override
  String get poiKind_hut => 'Hut';

  @override
  String get poiKind_shelter => 'Shelter';

  @override
  String get poiKind_drinkingWater => 'Drinking water';

  @override
  String get poiKind_toilets => 'Toilets';

  @override
  String get poiKind_viewpoint => 'Viewpoint';

  @override
  String get poiKind_attraction => 'Attraction';

  @override
  String get poiKind_observatory => 'Observatory';

  @override
  String get poiKind_zoo => 'Zoo';

  @override
  String get poiKind_themePark => 'Theme park';

  @override
  String get poiKind_mine => 'Mine';

  @override
  String get poiKind_mineShaft => 'Mine shaft';

  @override
  String get poiKind_adit => 'Adit';

  @override
  String get poiKind_ghostTown => 'Ghost town';

  @override
  String get poiKind_ruins => 'Ruins';

  @override
  String get poiKind_monument => 'Monument';

  @override
  String get poiKind_memorial => 'Memorial';

  @override
  String get poiKind_fort => 'Fort';

  @override
  String get poiKind_historic => 'Historic place';

  @override
  String get poiKind_rangerStation => 'Ranger station';

  @override
  String get poiKind_visitorCenter => 'Visitor center';

  @override
  String get poiKind_hospital => 'Hospital';

  @override
  String get poiKind_police => 'Police';

  @override
  String get poiKind_fireStation => 'Fire station';

  @override
  String get poiKind_emergencyPhone => 'Emergency phone';

  @override
  String get poiKind_fuel => 'Fuel';

  @override
  String get poiKind_restArea => 'Rest area';

  @override
  String get poiKind_travelCenter => 'Travel center';

  @override
  String get poiKind_museum => 'Museum';

  @override
  String get poiKind_city => 'City';

  @override
  String get poiKind_town => 'Town';

  @override
  String get poiKind_locality => 'Area';

  @override
  String get poiKind_lake => 'Lake';

  @override
  String get poiKind_river => 'River';

  @override
  String get poiKind_valley => 'Valley';

  @override
  String get poiKind_range => 'Mountain range';

  @override
  String get poiKind_trail => 'Trail';

  @override
  String get poiKind_dirtRoad => 'Dirt road';

  @override
  String get poiKind_road => 'Road';

  @override
  String get poiKind_address => 'Address';

  @override
  String get poiKind_place => 'Place';

  @override
  String get offlineMaps_kindRouting => 'Trail routing';

  @override
  String get offlineMaps_kindRoutingDetail =>
      'Routes on trails, dirt roads and paved roads';

  @override
  String get offlineMaps_kindPoi => 'Points of interest';

  @override
  String get offlineMaps_kindPoiDetail =>
      'Places to search for, with Wikipedia';

  @override
  String get offlineMaps_kindAddresses => 'Addresses';

  @override
  String get offlineMaps_kindAddressesDetail => 'House addresses to search for';

  @override
  String get map_search => 'Search';

  @override
  String get route_fromHere => 'Route from here';

  @override
  String get route_startSet => 'Route start set. Now choose where to go.';

  @override
  String get route_noStart =>
      'No starting position. Long-press the map and choose Route from here.';

  @override
  String get route_noData =>
      'Download Trail routing for this region in Offline maps to find routes here.';

  @override
  String get route_pin => 'Dropped pin';

  @override
  String get appSettings_coordinateFormat => 'Coordinate format';

  @override
  String get map_copyPosition => 'Copy position';

  @override
  String get poiKind_park => 'Park';

  @override
  String get poiKind_protectedArea => 'Protected area';

  @override
  String get common_more => 'More';

  @override
  String get common_less => 'Less';
}
