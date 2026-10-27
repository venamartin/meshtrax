// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Czaty';

  @override
  String get chats_title => 'Czaty';

  @override
  String get newChat_title => 'Wybierz kontakt';

  @override
  String newChat_contactCount(int count) {
    return 'Kontakty: $count';
  }

  @override
  String get newChat_newContact => 'Nowy kontakt';

  @override
  String get newChat_newChannel => 'Nowy kanał';

  @override
  String get newChat_myContacts => 'Moje kontakty';

  @override
  String get newChat_discovered => 'Odkryte';

  @override
  String get repeaters_title => 'Zarządzaj przekaźnikami';

  @override
  String get nav_contacts => 'Kontakty';

  @override
  String get nav_channels => 'Kanały';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Anuluj';

  @override
  String get common_syncing_device_info => 'Odczyt informacji o urządzeniu...';

  @override
  String get common_syncing_contacts => 'Odczyt kontaktów...';

  @override
  String get common_syncing_channels => 'Odczyt kanałów...';

  @override
  String get common_syncing_messages => 'Odczyt wiadomości...';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Połącz';

  @override
  String get common_unknownDevice => 'Nieznane urządzenie';

  @override
  String get common_save => 'Zapisz';

  @override
  String get common_delete => 'Usuń';

  @override
  String get common_deleteAll => 'Usuń wszystko';

  @override
  String get common_close => 'Zamknij';

  @override
  String get common_edit => 'Edytuj';

  @override
  String get common_add => 'Dodaj';

  @override
  String get common_settings => 'Ustawienia';

  @override
  String get common_disconnect => 'Odłącz';

  @override
  String get common_connected => 'Połączono';

  @override
  String get common_disconnected => 'Odłączony';

  @override
  String get common_connectionLost =>
      'Utracono połączenie. Ponowne łączenie...';

  @override
  String get common_reconnecting => 'Ponowne łączenie...';

  @override
  String get common_create => 'Utwórz';

  @override
  String get common_continue => 'Kontynuuj';

  @override
  String get common_share => 'Udostępnij';

  @override
  String get common_copy => 'Kopiuj';

  @override
  String get common_retry => 'Ponów';

  @override
  String get common_hide => 'Ukryj';

  @override
  String get common_remove => 'Usuń';

  @override
  String get common_enable => 'Włącz';

  @override
  String get common_disable => 'Wyłącz';

  @override
  String get common_reboot => 'Uruchom ponownie';

  @override
  String get common_loading => 'Ładowanie...';

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
  String get tcpScreenTitle => 'Połącz się za pomocą protokołu TCP';

  @override
  String get tcpHostLabel => 'Adres IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Port';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Wprowadź adres URL i połącz';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Połączenie z $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Wymagana jest adresa IP.';

  @override
  String get tcpErrorPortInvalid =>
      'Numer portu musi mieścić się w zakresie od 1 do 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Transport TCP nie jest obsługiwany na tej platformie.';

  @override
  String get tcpErrorTimedOut =>
      'Połączenie TCP zakończyło się bez powodzenia.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Błąd połączenia TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Połącz przez USB';

  @override
  String get usbScreenSubtitle =>
      'Wybierz wykryte urządzenie szeregowe i połącz się bezpośrednio ze swoim węzłem MeshCore.';

  @override
  String get usbScreenStatus => 'Wybierz urządzenie USB';

  @override
  String get usbScreenNote =>
      'Port szeregowy USB jest aktywny na urządzeniach z systemem Android i platformach stacjonarnych, które go obsługują.';

  @override
  String get usbScreenEmptyState =>
      'Nie znaleziono żadnych urządzeń USB. Podłącz jedno i zaktualizuj.';

  @override
  String get usbErrorPermissionDenied =>
      'Zostało odrzucone żądanie dostępu przez USB.';

  @override
  String get usbErrorDeviceMissing =>
      'Wybór urządzenia USB już nie jest dostępny.';

  @override
  String get usbErrorInvalidPort => 'Wybierz prawidłowe urządzenie USB.';

  @override
  String get usbErrorBusy =>
      'Kolejne żądanie połączenia przez USB jest już w trakcie realizacji.';

  @override
  String get usbErrorNotConnected => 'Brak podłączonego urządzenia USB.';

  @override
  String get usbErrorOpenFailed =>
      'Nie udało się otworzyć wybranego urządzenia USB.';

  @override
  String get usbErrorConnectFailed =>
      'Nie udało się połączyć z wybranym urządzeniem USB.';

  @override
  String get usbErrorUnsupported =>
      'Port szeregowy USB nie jest obsługiwany na tym urządzeniu.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'W tej wersji brakuje biblioteki portu szeregowego USB, więc nie można otworzyć urządzeń USB. Zainstaluj MeshTrax ponownie lub zgłoś tę wersję jako uszkodzoną.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Ta przeglądarka nie obsługuje Web Serial. Użyj Chrome lub Edge przez HTTPS (lub localhost).';

  @override
  String get usbErrorAlreadyActive => 'Połączenie USB jest już aktywne.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Nie został wybrany żaden urządzenie USB.';

  @override
  String get usbErrorPortClosed => 'Połączenie USB nie jest aktywne.';

  @override
  String get usbErrorConnectTimedOut =>
      'Połączenie nie zostało nawiązane. Upewnij się, że urządzenie posiada oprogramowanie \"USB Companion\".';

  @override
  String get usbFallbackDeviceName =>
      'Urządzenie do komunikacji przez sieć (seria)';

  @override
  String get usbStatus_notConnected => 'Wybierz urządzenie USB';

  @override
  String get usbStatus_connecting => 'Połączenie z urządzeniem USB...';

  @override
  String get usbStatus_searching => 'Wyszukiwanie urządzeń USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Błąd połączenia USB: $error';
  }

  @override
  String get scanner_scanning => 'Skanowanie urządzeń...';

  @override
  String get scanner_connecting => 'Łączenie...';

  @override
  String get scanner_disconnecting => 'Odłączanie...';

  @override
  String get scanner_notConnected => 'Nie połączono';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Połączono z $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Pokaż wszystkie urządzenia Bluetooth';

  @override
  String get scanner_showMeshCoreOnly => 'Pokaż tylko radia MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'Radio nie odpowiada. Może wymagać sparowania: otwórz ustawienia Bluetooth, dodaj radio i wpisz jego PIN, a potem spróbuj ponownie.';

  @override
  String get scanner_pairingFailed =>
      'Parowanie Bluetooth zostało anulowane lub się nie powiodło. Upewnij się, że nic innego (np. Twój telefon) nie jest połączone z radiem, a potem spróbuj ponownie i wpisz jego PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Połączenie nieudane: $error';
  }

  @override
  String get scanner_stop => 'Zatrzymaj';

  @override
  String get scanner_scan => 'Przeskanuj';

  @override
  String get scanner_scanFromImage => 'Skanuj z obrazu';

  @override
  String get scanner_noQrFoundInImage =>
      'Nie znaleziono prawidłowego kodu QR na obrazie';

  @override
  String get scanner_bluetoothOff => 'Bluetooth jest wyłączony';

  @override
  String get scanner_bluetoothOffMessage =>
      'Prosimy włączyć Bluetooth, aby przeskanować urządzenia.';

  @override
  String get scanner_chromeRequired => 'Wymagana przeglądarka Chrome';

  @override
  String get scanner_chromeRequiredMessage =>
      'Ta aplikacja internetowa wymaga przeglądarki Google Chrome lub opartej na Chromium do obsługi Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Włącz Bluetooth';

  @override
  String get device_quickSwitch => 'Szybka zmiana';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Ustawienia';

  @override
  String get settings_deviceInfo => 'Informacje o urządzeniu';

  @override
  String get settings_appSettings => 'Ustawienia aplikacji';

  @override
  String get settings_appSettingsSubtitle =>
      'Powiadomienia, wiadomości i preferencje mapy';

  @override
  String get settings_nodeSettings => 'Ustawienia węzła';

  @override
  String get settings_nodeName => 'Nazwa węzła';

  @override
  String get settings_nodeNameNotSet => 'Nie ustawione';

  @override
  String get settings_nodeNameHint => 'Wprowadź nazwę węzła';

  @override
  String get settings_nodeNameUpdated => 'Nazwa zaktualizowana';

  @override
  String get settings_radioSettings => 'Ustawienia radia';

  @override
  String get settings_radioSettingsSubtitle =>
      'Częstotliwość, moc, współczynnik rozpraszania';

  @override
  String get settings_radioSettingsUpdated =>
      'Ustawienia radia zostały zaktualizowane';

  @override
  String get settings_location => 'Lokalizacja';

  @override
  String get settings_locationSubtitle => 'Koordynaty GPS';

  @override
  String get settings_locationUpdated => 'Lokalizacja zaktualizowana';

  @override
  String get settings_locationBothRequired =>
      'Wprowadź zarówno szerokość, jak i długość geograficzną.';

  @override
  String get settings_locationInvalid =>
      'Nieprawidłowa szerokość geograficzna lub długość geograficzna.';

  @override
  String get settings_locationGPSEnable => 'Włącz GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Włącza automatyczne aktualizowanie pozycji za pomocą GPS.';

  @override
  String get settings_latitude => 'Szerokość';

  @override
  String get settings_longitude => 'Długość';

  @override
  String get settings_contactSettings => 'Ustawienia kontaktów';

  @override
  String get settings_contactSettingsSubtitle =>
      'Ustawienia dotyczące sposobu dodawania kontaktów';

  @override
  String get settings_privacyMode => 'Tryb prywatności';

  @override
  String get settings_privacyModeSubtitle =>
      'Ukryj imię/lokalizację w rozgłoszeniach';

  @override
  String get settings_privacyModeToggle =>
      'Włącz tryb prywatności, aby ukryć swoje imię i lokalizację w rozgłoszeniach.';

  @override
  String get settings_privacyModeEnabled => 'Tryb prywatności włączony';

  @override
  String get settings_privacyModeDisabled => 'Tryb prywatności wyłączony';

  @override
  String get settings_privacy => 'Ustawienia prywatności';

  @override
  String get settings_privacySubtitle =>
      'Kontroluj jakie informacje są udostępniane.';

  @override
  String get settings_privacySettingsDescription =>
      'Wybierz jakie informacje urządzenie udostępni innym.';

  @override
  String get settings_denyAll => 'Odmów wszystkim';

  @override
  String get settings_allowByContact => 'Zezwalaj według flag kontaktowych';

  @override
  String get settings_allowAll => 'Zezwalaj na wszystko';

  @override
  String get settings_telemetryBaseMode => 'Tryb podstawowy telemetrii';

  @override
  String get settings_telemetryLocationMode => 'Tryb położenia telemetrycznego';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Tryb środowiska telemetrycznego';

  @override
  String get settings_advertLocation => 'Lokalizacja reklamowa';

  @override
  String get settings_advertLocationSubtitle =>
      'Uwzględnij lokalizację w ogłoszeniu';

  @override
  String get settings_multiAck => 'Wielokrotne potwierdzenia odbioru';

  @override
  String get settings_telemetryModeUpdated =>
      'Tryb telemetryczny zaktualizowany';

  @override
  String get settings_actions => 'Działania';

  @override
  String get settings_sendAdvertisement => 'Wyślij rozgłoszenie';

  @override
  String get settings_sendAdvertisementSubtitle => 'Nadaj obecność teraz';

  @override
  String get settings_advertisementSent => 'Rozgłoszenie wysłane';

  @override
  String get settings_syncTime => 'Synchronizacja czasu';

  @override
  String get settings_syncTimeSubtitle =>
      'Ustaw zegar urządzenia na czas telefonu.';

  @override
  String get settings_timeSynchronized => 'Czas zsynchronizowany';

  @override
  String get settings_refreshContacts => 'Odśwież Kontakty';

  @override
  String get settings_refreshContactsSubtitle =>
      'Odśwież listę kontaktów z urządzenia';

  @override
  String get settings_rebootDevice => 'Zrestartuj Urządzenie';

  @override
  String get settings_rebootDeviceSubtitle => 'Zrestartuj urządzenie MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Czy na pewno chcesz zrestartować urządzenie? Będziesz odłączony.';

  @override
  String get settings_debug => 'Debug';

  @override
  String get settings_bleDebugLog => 'Dziennik debugowania BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Polecenia BLE, odpowiedzi i surowe dane';

  @override
  String get settings_appDebugLog => 'Dziennik debugowania aplikacji';

  @override
  String get settings_appDebugLogSubtitle => 'Komunikaty debugowania aplikacji';

  @override
  String get settings_exportDatabase => 'Eksportuj bazę wiadomości';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Kopia wszystkich czatów i kontaktów do debugowania. Zachowaj ją prywatnie.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Baza zapisana w: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Eksport nie powiódł się: $error';
  }

  @override
  String get settings_about => 'O aplikacji';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'Projekt MeshTrax Source 2026';

  @override
  String get settings_aboutDescription =>
      'Otwartoźródłowy klient Flutter dla urządzeń MeshCore LoRa do sieci mesh.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Dane wysokościowe LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nazwa';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Bateria';

  @override
  String get settings_infoPublicKey => 'Klucz Publiczny';

  @override
  String get settings_infoContactsCount => 'Liczba kontaktów';

  @override
  String get settings_infoChannelCount => 'Liczba kanałów';

  @override
  String get settings_presets => 'Presety';

  @override
  String get settings_frequency => 'Częstotliwość (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid =>
      'Nieprawidłowa częstotliwość (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Przepustowość';

  @override
  String get settings_spreadingFactor => 'Współczynnik rozpraszania';

  @override
  String get settings_codingRate => 'Współczynnik kodowania';

  @override
  String get settings_txPower => 'Moc TX (dBm)';

  @override
  String get settings_txPowerInvalid => 'Nieprawidłowa moc TX';

  @override
  String get settings_clientRepeat => 'Powtórzenie: Niezależne od sieci';

  @override
  String get settings_clientRepeatSubtitle =>
      'Pozwól temu urządzeniu powtarzać pakiety danych dla innych urządzeń.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Powtórka poza siecią wymaga częstotliwości 433, 869 lub 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Błąd: $message';
  }

  @override
  String get appSettings_title => 'Ustawienia aplikacji';

  @override
  String get appSettings_appearance => 'Wygląd';

  @override
  String get appSettings_theme => 'Motyw';

  @override
  String get appSettings_themeSystem => 'Domyślne ustawienia systemu';

  @override
  String get appSettings_themeLight => 'Jasne';

  @override
  String get appSettings_themeDark => 'Ciemny';

  @override
  String get appSettings_language => 'Język';

  @override
  String get appSettings_languageSystem => 'Domyślny systemowy';

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
  String get appSettings_languageRu => 'Rosyjski';

  @override
  String get appSettings_languageUk => 'Ukraińska';

  @override
  String get appSettings_enableMessageTracing => 'Włącz śledzenie wiadomości';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Pokaż szczegółowe metadane trasowania i czasu dla wiadomości';

  @override
  String get appSettings_senderNameColors => 'Kolorowe nazwy nadawców';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Każdy nadawca na kanale dostaje własny kolor nazwy. Po wyłączeniu wszyscy mają kolor motywu.';

  @override
  String get appSettings_showTextFormatting => 'Pokaż formatowanie tekstu';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown w wiadomościach: **pogrubienie**, *kursywa*, ||spoilery||, nagłówki i linki. Inne aplikacje MeshCore pokazują surowe znaki.';

  @override
  String get appSettings_notifications => 'Powiadomienia';

  @override
  String get appSettings_enableNotifications => 'Włącz Powiadomienia';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Otrzymuj powiadomienia o wiadomościach i rozgłoszeniach.';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Odmowa zezwolenia na powiadomienia';

  @override
  String get appSettings_notificationsEnabled => 'Powiadomienia włączone';

  @override
  String get appSettings_notificationsDisabled => 'Powiadomienia wyłączone';

  @override
  String get appSettings_messageNotifications =>
      'Powiadomienia o wiadomościach';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Pokaż powiadomienie przy otrzymywaniu nowych wiadomości';

  @override
  String get appSettings_channelMessageNotifications =>
      'Powiadomienia o Wiadomościach na Kanałach';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Pokaż powiadomienie przy odbieraniu wiadomości z kanału';

  @override
  String get appSettings_advertisementNotifications =>
      'Powiadomienia o rozgłoszeniach';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Wyświetl powiadomienie, gdy zostaną wykryte nowe węzły.';

  @override
  String get appSettings_messaging => 'Wiadomości';

  @override
  String get appSettings_maxMessageRetries =>
      'Maksymalna liczba prób wysłania wiadomości';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Liczba prób ponownego wysłania wiadomości przed oznaczaniem jej jako nieudanej';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Maks. ponowień wiadomości na kanale';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Ponawia tyle razy, aż usłyszy co najmniej jedno powtórzenie';

  @override
  String get appSettings_battery => 'Bateria';

  @override
  String get appSettings_batteryChemistry => 'Chemia Baterii';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Ustaw dla urządzenia ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Połącz się z urządzeniem, aby wybrać';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65 V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Wyświetlanie mapy';

  @override
  String get appSettings_showRepeaters => 'Pokaż przekaźniki';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Wyświetl węzły przekaźników na mapie';

  @override
  String get appSettings_showChatNodes => 'Pokaż Węzły Rozmowy';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Wyświetl węzły czatu na mapie';

  @override
  String get appSettings_showOtherNodes => 'Pokaż inne węzły';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Wyświetl inne typy węzłów na mapie';

  @override
  String get appSettings_timeFilter => 'Filtrowanie Czasu';

  @override
  String get appSettings_timeFilterShowAll => 'Pokaż wszystkie węzły';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Pokaż węzły z ostatnich $hours godzin';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtr czasu mapy';

  @override
  String get appSettings_showNodesDiscoveredWithin => 'Pokaż węzły odkryte w:';

  @override
  String get appSettings_allTime => 'Cały czas';

  @override
  String get appSettings_lastHour => 'Ostatnia godzina';

  @override
  String get appSettings_last6Hours => 'Ostatnie 6 godzin';

  @override
  String get appSettings_last24Hours => 'Ostatnie 24 godziny';

  @override
  String get appSettings_lastWeek => 'Ostatni tydzień';

  @override
  String get appSettings_unitsTitle => 'Jednostki';

  @override
  String get appSettings_unitsMetric => 'Metryczne (m / km)';

  @override
  String get appSettings_unitsImperial => 'Imperialne (ft / mi)';

  @override
  String get appSettings_debugCard => 'Debug';

  @override
  String get appSettings_appDebugLogging => 'Logowanie Debugowania Aplikacji';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Rejestruj komunikaty debugowania aplikacji w celu diagnozowania problemów.';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Logowanie debugowania aplikacji włączone';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Logowanie debugowania aplikacji wyłączone.';

  @override
  String get appSettings_incrementalContactSync =>
      'Przyrostowa synchronizacja kontaktów';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Po ponownym połączeniu pobieraj z radia tylko kontakty zmienione od ostatniego razu';

  @override
  String get contacts_title => 'Kontakty';

  @override
  String get contacts_noContacts => 'Brak jeszcze kontaktów.';

  @override
  String get contacts_shareMyQrCode => 'Udostępnij mój kod QR';

  @override
  String get contacts_shareQrCodeDesc =>
      'Pozwól innym go zeskanować, by dodali Cię jako kontakt';

  @override
  String get contacts_contactsWillAppear =>
      'Kontakty będą wyświetlane, gdy urządzenia nadają rozgłoszenia.';

  @override
  String get contacts_unread => 'Nieprzeczytane';

  @override
  String get contacts_searchContactsNoNumber => 'Wyszukaj kontakty...';

  @override
  String contacts_searchContacts(int number, String str) {
    String _temp0 = intl.Intl.pluralLogic(
      number,
      locale: localeName,
      other: 'kontaktu',
      many: 'kontaktów',
      few: 'kontakty',
      one: 'kontakt',
    );
    return 'Wyszukaj $number$str $_temp0...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Wyszukaj $number$str ulubione...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Wyszukaj $number$str Użytkowników...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Wyszukaj $number$str przekaźników...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Wyszukaj $number$str serwerów Room...';
  }

  @override
  String get contacts_noUnreadContacts => 'Brak nieprzeczytanych kontaktów';

  @override
  String get contacts_noContactsFound =>
      'Brak znalezionych kontaktów ani grup.';

  @override
  String get contacts_deleteContact => 'Usuń Kontakt';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Czy na pewno chcesz usunąć $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Usunięto kontakt $contactName.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Nie udało się usunąć $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Żaden kontakt nie pasuje do filtra.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Usunąć $contactName z kontaktów?';
  }

  @override
  String get contacts_manageRepeater => 'Zarządzaj przekaźnikiem';

  @override
  String get contacts_manageRoom => 'Zarządzaj Serwerem Pokoju';

  @override
  String get contacts_roomLogin => 'Logowanie do pokoju';

  @override
  String get contacts_openChat => 'Otwórz czat';

  @override
  String get contacts_editGroup => 'Edytuj Grupę';

  @override
  String get contacts_deleteGroup => 'Usuń Grupę';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Usuń \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Nowa Grupa';

  @override
  String get contacts_groupName => 'Nazwa grupy';

  @override
  String get contacts_groupNameRequired => 'Nazwa grupy jest wymagana';

  @override
  String get contacts_groupNameReserved => 'Ta nazwa grupy jest zastrzeżona';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Grupa \"$name\" już istnieje';
  }

  @override
  String get contacts_filterContacts => 'Filtruj kontakty...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Brak pasujących kontaktów do Twojego filtra';

  @override
  String get contacts_noMembers => 'Brak członków';

  @override
  String get contacts_lastSeenNow => 'niedawno';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 godz.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours godz.';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 dzień';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days dni';
  }

  @override
  String get contact_info => 'Informacje kontaktowe';

  @override
  String get contact_settings => 'Ustawienia kontaktowe';

  @override
  String get contact_telemetry => 'Telemetryka';

  @override
  String get contact_lastSeen => 'Ostatnio widziany';

  @override
  String get contact_clearChat => 'Wyczyść czat';

  @override
  String get contact_teleBase => 'Baza telemetryczna';

  @override
  String get contact_teleBaseSubtitle =>
      'Pozwól na udostępnianie poziomu naładowania baterii i podstawowych danych telemetrycznych';

  @override
  String get contact_teleLoc => 'Lokalizacja telemetryczna';

  @override
  String get contact_teleLocSubtitle =>
      'Zezwalaj na udostępnianie danych lokalizacji';

  @override
  String get contact_teleEnv => 'Środowisko telemetryczne';

  @override
  String get contact_teleEnvSubtitle =>
      'Zezwalaj na udostępnianie danych czujników środowiskowych';

  @override
  String get contacts_publicKey => 'Klucz publiczny';

  @override
  String get channels_title => 'Kanały';

  @override
  String get channels_noChannelsConfigured => 'Brak skonfigurowanych kanałów';

  @override
  String get channels_addPublicChannel => 'Dodaj kanał publiczny';

  @override
  String get channels_searchChannels => 'Wyszukaj kanały...';

  @override
  String get channels_noChannelsFound => 'Brak znalezionych kanałów';

  @override
  String channels_channelIndex(int index) {
    return 'Kanał $index';
  }

  @override
  String get channels_hashtagChannel => 'Kanał hashtagów';

  @override
  String get channels_public => 'Publiczny';

  @override
  String get channels_private => 'Prywatny';

  @override
  String get channels_publicChannel => 'Kanał publiczny';

  @override
  String get channels_privateChannel => 'Prywatny kanał';

  @override
  String get channels_editChannel => 'Edytuj kanał';

  @override
  String get channels_shareChannel => 'Udostępnij kanał';

  @override
  String get channels_shareChannelInstructions =>
      'Zeskanuj kod QR, aby dodać kanał.\nMenu → Dodaj Kanał → Skanuj kod QR';

  @override
  String get channels_secretKey => 'Tajny klucz';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

  @override
  String get channels_shareChannelQr => 'Zeskanuj kod QR kanału';

  @override
  String get channels_shareChannelWarning =>
      'Uwaga: każdy, kto zeskanuje ten kod QR, uzyska dostęp do tego kanału.';

  @override
  String get channels_muteChannel => 'Wycisz kanał';

  @override
  String get channels_unmuteChannel => 'Wyłącz wyciszenie kanału';

  @override
  String get channels_deleteChannel => 'Usuń kanał';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Usuń \"$name\"? Nie można tego cofnąć.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Nie udało się usunąć kanału \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Kanał \"$name\" usunięto';
  }

  @override
  String get channels_addChannel => 'Dodaj Kanał';

  @override
  String get channels_channelIndexLabel => 'Indeks kanału';

  @override
  String get channels_channelName => 'Nazwa kanału';

  @override
  String get channels_usePublicChannel => 'Użyj kanału publicznego';

  @override
  String get channels_standardPublicPsk => 'Standardowy publiczny PSK';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Wygeneruj losowy klucz PSK';

  @override
  String get channels_enterChannelName => 'Proszę podać nazwę kanału.';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK musi składać się z 32 znaków szesnastkowych.';

  @override
  String get channels_addChannelConfirmation => 'Czy chcesz dodać ten kanał?';

  @override
  String get channels_channelAddedSuccess => 'Kanał został dodany.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Brak wolnych miejsc na kanały.';

  @override
  String get appSettings_mentionNotifications => 'Powiadomienia o wzmiankach';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Gdy ktoś Cię wspomni lub Ci odpowie — nawet na wyciszonych kanałach';

  @override
  String notification_mentionIn(String channelName) {
    return 'Wzmianka w $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Kanał \"$name\" dodany';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Edytuj Kanał $index';
  }

  @override
  String get channels_smazCompression => 'Kompresja SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Kanał \"$name\" został zaktualizowany';
  }

  @override
  String get channels_publicChannelAdded => 'Kanał publiczny dodany';

  @override
  String get channels_sortBy => 'Sortuj po';

  @override
  String get channels_sortManual => 'Ręczna';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Najnowsze wiadomości';

  @override
  String get channels_sortUnread => 'Nieprzeczytane';

  @override
  String get channels_createPrivateChannel => 'Utwórz Prywatny Kanał';

  @override
  String get channels_createPrivateChannelDesc =>
      'Zabezpieczone kluczem szyfrowym.';

  @override
  String get channels_joinPrivateChannel => 'Dołącz do Prywatnego Kanału';

  @override
  String get channels_joinPrivateChannelDesc => 'Ręcznie wprowadź klucz tajny.';

  @override
  String get channels_joinPublicChannel => 'Dołącz do kanału publicznego.';

  @override
  String get channels_joinPublicChannelDesc =>
      'Każdy może dołączyć do tego kanału.';

  @override
  String get channels_joinHashtagChannel =>
      'Dołącz do kanału oznaczanego hashtagiem';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Każdy może dołączyć do kanałów z hashtagami.';

  @override
  String get channels_scanQrCode => 'Skanuj kod QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Wkrótce';

  @override
  String get channels_enterHashtag => 'Wprowadź hashtag';

  @override
  String get channels_hashtagHint => 'np. #zespół';

  @override
  String get chat_noMessages => 'Brak jeszcze wiadomości';

  @override
  String get chat_sendMessage => 'Wyślij wiadomość';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Wyślij wiadomość do $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Wyślij wiadomość, aby rozpocząć.';

  @override
  String get chat_originalMessageNotFound =>
      'Błąd: Nie znaleziono oryginalnego komunikatu';

  @override
  String chat_replyingTo(String name) {
    return 'Odpowiadanie na $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Odpowiedz do $name';
  }

  @override
  String get chat_location => 'Lokalizacja';

  @override
  String get common_copiedToClipboard => 'Skopiowano do schowka';

  @override
  String get common_copyToClipboard => 'Kopiuj do schowka';

  @override
  String get contacts_copyContactToClipboard => 'Kopiuj mój kontakt do schowka';

  @override
  String get chat_typeMessage => 'Wpisz wiadomość...';

  @override
  String get chat_searchMessages => 'Szukaj wiadomości';

  @override
  String get chat_searchNoMatches => 'Brak wyników';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Wiadomość jest za długa (maksymalnie $maxBytes bajtów).';
  }

  @override
  String get chat_messageCopied => 'Wiadomość skopiowana';

  @override
  String get chat_messageDeleted => 'Wiadomość usunięta';

  @override
  String get chat_sendGif => 'Wyślij GIF';

  @override
  String get chat_reply => 'Odpowiedz';

  @override
  String get chat_newMessages => 'NOWE WIADOMOŚCI';

  @override
  String get chat_addReaction => 'Dodaj Reakcję';

  @override
  String get chat_mention => 'Wspomnij';

  @override
  String get dmChannel_menuLabel => 'Wiadomość prywatna';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Wyślij DM do $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Sprawdź klucz i kiedy ostatnio był widziany — nazwy nie są unikalne.';

  @override
  String get dmChannel_warningTitle => 'Czy to na pewno ta osoba?';

  @override
  String get dmChannel_warningBody =>
      'Nazwy na kanałach każdy wybiera sam i każdy może je podrobić. Przy czymkolwiek poufnym najpierw sprawdź klucz publiczny tego kontaktu w inny sposób.';

  @override
  String get dmChannel_dontShowAgain => 'Nie pokazuj ponownie';

  @override
  String get batterySleep_title => 'Utrzymaj działanie MeshTrax';

  @override
  String get batterySleep_bodySamsung =>
      'Telefony Samsung usypiają aplikacje, by oszczędzać baterię, co odcina Twoje radio. Otwórz Ustawienia → Aplikacje → MeshTrax → Bateria i wybierz Bez ograniczeń. Sprawdź też Bateria → Limity użycia w tle i upewnij się, że MeshTrax nie ma na liście Uśpione aplikacje ani Aplikacje w głębokim uśpieniu.';

  @override
  String get batterySleep_bodyGeneric =>
      'Telefon może zatrzymywać MeshTrax w tle, by oszczędzać baterię, co odcina Twoje radio. Otwórz ustawienia baterii i ustaw dla MeshTrax Bez ograniczeń (lub Brak ograniczeń). Na niektórych telefonach trzeba też włączyć Autostart dla MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Otwórz ustawienia';

  @override
  String get batterySleep_notNow => 'Nie teraz';

  @override
  String get batterySleep_settingsTile => 'Utrzymuj MeshTrax w działaniu w tle';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Nie pozwól oszczędzaniu baterii usypiać MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Nie można jeszcze wysłać DM do $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Nie masz jeszcze klucza tej osoby, a ona potrzebuje Twojego, by odpowiedzieć — klucze krążą tylko w rozgłoszeniach. \"Wyślij moje rozgłoszenie\" nadaje Twoje stąd. \"Zapytaj na kanale\" wpisuje prośbę do pola wiadomości, a Ty ją wysyłasz.';

  @override
  String get dmChannel_askInChannel => 'Zapytaj na kanale';

  @override
  String get dmChannel_sendMyAdvert => 'Wyślij moje rozgłoszenie';

  @override
  String get dmChannel_askText =>
      'proszę o rozgłoszenie, chcę napisać do Ciebie DM';

  @override
  String get dmChannel_watching =>
      'Czekam na rozgłoszenie tej osoby — gdy dotrze, zapytam Cię tutaj.';

  @override
  String dmChannel_advertHeard(String name) {
    return 'Kontakt $name jest już osiągalny';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Poziom powiększenia';

  @override
  String get common_reset => 'Resetuj';

  @override
  String get chat_reactionsTitle => 'Reakcje';

  @override
  String get chat_reactionUnknownSender => 'Nieznany';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender: reakcja na wiadomość, której nie ma w tym czacie';
  }

  @override
  String get chat_me => 'Ja';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Gesty';

  @override
  String get emojiCategoryHearts => 'Serca';

  @override
  String get emojiCategoryObjects => 'Obiekty';

  @override
  String get gifPicker_title => 'Wybierz GIF';

  @override
  String get gifPicker_searchHint => 'Wyszukaj GIF-y...';

  @override
  String get gifPicker_poweredBy => 'Zasilane przez GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nie znaleziono GIF-ów';

  @override
  String get gifPicker_failedLoad => 'Nie udało się załadować GIF-ów';

  @override
  String get gifPicker_failedSearch => 'Nie udało się znaleźć GIF-ów';

  @override
  String get gifPicker_noInternet => 'Brak połączenia internetowego';

  @override
  String get debugLog_appTitle => 'Log Wykonywania Aplikacji';

  @override
  String get debugLog_bleTitle => 'Log błędów BLE';

  @override
  String get debugLog_copyLog => 'Kopiuj log';

  @override
  String get debugLog_saveLog => 'Zapisz log do pliku';

  @override
  String get debugLog_saved => 'Log zapisany';

  @override
  String get debugLog_saveCancelled => 'Zapisywanie anulowane';

  @override
  String get debugLog_filterAll => 'Wszystko';

  @override
  String get debugLog_filterWarnings => 'Ostrzeżenia';

  @override
  String get debugLog_filterErrors => 'Błędy';

  @override
  String get debugLog_clearLog => 'Wyczyść dziennik';

  @override
  String get debugLog_copied => 'Skopiowano dziennik debugowania';

  @override
  String get debugLog_bleCopied => 'Skopiowany log BLE';

  @override
  String get debugLog_noEntries => 'Nie ma jeszcze żadnych logów debugowania.';

  @override
  String get debugLog_enableInSettings =>
      'Włącz logowanie debugowania aplikacji w ustawieniach';

  @override
  String get debugLog_frames => 'Ramki';

  @override
  String get debugLog_rawLogRx => 'Surowy log RX';

  @override
  String get debugLog_noBleActivity => 'Brak aktywności BLE.';

  @override
  String debugFrame_length(int count) {
    return 'Długość ramy: $count bajtów';
  }

  @override
  String debugFrame_command(String value) {
    return 'Polecenie: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Wiadomość tekstowa:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Docelowy klucz publiczny: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Znacznik czasu: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flagi: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Typ tekstu: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Polecenie CLI';

  @override
  String get debugFrame_textTypePlain => 'Zwykły';

  @override
  String debugFrame_text(String text) {
    return '- Tekst: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Zrzut hex:';

  @override
  String get chat_hopSingular => 'skok';

  @override
  String get chat_hopPlural => 'skoki';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'skoków',
      many: 'skoków',
      few: 'skoki',
      one: 'skok',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Ustaw ścieżkę niestandardową';

  @override
  String get chat_fullPath => 'Pełna ścieżka';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Szczegóły ścieżki jeszcze niedostępne. Spróbuj wysłać wiadomość, aby odświeżyć.';

  @override
  String get chat_type => 'Typ';

  @override
  String get chat_path => 'Ścieżka';

  @override
  String get chat_publicKey => 'Klucz Publiczny';

  @override
  String get chat_compressOutgoingMessages => 'Kompresuj wychodzące wiadomości';

  @override
  String get chat_floodForced => 'Zalew (wymuszony)';

  @override
  String get chat_directForced => 'Bezpośrednio (wymuszono)';

  @override
  String chat_hopsForced(int count) {
    return '$count skoków (wymuszonych)';
  }

  @override
  String get chat_floodAuto => 'Zalew (automatyczny)';

  @override
  String get chat_direct => 'Bezpośrednio';

  @override
  String get chat_poiShared => 'Wspólny POI';

  @override
  String chat_unread(int count) {
    return 'Nieprzeczytane: $count';
  }

  @override
  String get chat_openLink => 'Otworzyć link?';

  @override
  String get chat_openLinkConfirmation =>
      'Czy chcesz otworzyć ten link w przeglądarce?';

  @override
  String get chat_open => 'Otwórz';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Nie można otworzyć linku: $url';
  }

  @override
  String get chat_invalidLink => 'Nieprawidłowy format linku';

  @override
  String get map_lineOfSight => 'Linia wzroku';

  @override
  String get map_losScreenTitle => 'Linia wzroku';

  @override
  String get map_noNodesWithLocation => 'Brak węzłów z danymi lokalizacyjnymi';

  @override
  String get map_nodesNeedGps =>
      'Węzły muszą udostępniać swoje współrzędne GPS,\naby pojawić się na mapie.';

  @override
  String map_nodesCount(int count) {
    return 'Węzły: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pinezki: $count';
  }

  @override
  String get map_chat => 'Rozmowa';

  @override
  String get map_repeater => 'Przekaźnik';

  @override
  String get map_room => 'Pokój';

  @override
  String get map_sensor => 'Czujnik';

  @override
  String get map_pinDm => 'Pinezka (DM)';

  @override
  String get map_pinPrivate => 'Pinezka (prywatna)';

  @override
  String get map_pinPublic => 'Pinezka (publiczna)';

  @override
  String get map_lastSeen => 'Ostatni raz widziany';

  @override
  String get map_disconnectConfirm =>
      'Czy na pewno chcesz się odłączyć od tego urządzenia?';

  @override
  String get map_from => 'Od';

  @override
  String get map_source => 'Źródło';

  @override
  String get map_flags => 'Flagi';

  @override
  String get map_shareMarkerHere => 'Udostępnij znacznik tutaj';

  @override
  String get map_setAsMyLocation => 'Ustaw jako moją lokalizację';

  @override
  String get map_pinLabel => 'Etykieta pinezki';

  @override
  String get map_label => 'Etykieta';

  @override
  String get map_pointOfInterest => 'Punkt zainteresowań';

  @override
  String get map_sendToContact => 'Wyślij do kontaktu';

  @override
  String get map_sendToChannel => 'Wyślij do kanału';

  @override
  String get map_noChannelsAvailable => 'Brak dostępnych kanałów';

  @override
  String get map_publicLocationShare => 'Udostępnij lokalizację publicznie';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Zamierzasz udostępnić lokalizację w $channelLabel. Ten kanał jest publiczny i każdy z PSK może go zobaczyć.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Połącz się z urządzeniem, aby udostępniać znaczniki.';

  @override
  String get map_filterNodes => 'Filtruj Węzły';

  @override
  String get map_chatNodes => 'Węzły czatu';

  @override
  String get map_repeaters => 'Przekaźniki';

  @override
  String get map_otherNodes => 'Inne węzły';

  @override
  String get map_showOverlaps => 'Nakładające się klucze przekaźników';

  @override
  String get map_keyPrefix => 'Prefiks klucza';

  @override
  String get map_filterByKeyPrefix => 'Filtruj po prefiksie klucza';

  @override
  String get map_publicKeyPrefix => 'Prefiks klucza publicznego';

  @override
  String get map_showDiscoveryContacts => 'Pokaż odkryte kontakty';

  @override
  String get map_guessedLocation => 'Przypuszczalna lokalizacja';

  @override
  String get map_lastSeenTime => 'Ostatni raz widziany';

  @override
  String get map_sharedPin => 'Udostępniona pinezka';

  @override
  String get map_joinRoom => 'Dołącz do pokoju';

  @override
  String get map_manageRepeater => 'Zarządzaj przekaźnikiem';

  @override
  String get map_tapToAdd => 'Kliknij na węzły, aby dodać je do ścieżki.';

  @override
  String get map_runTrace => 'Uruchom ślad ścieżki';

  @override
  String get map_runTraceWithReturnPath => 'Wróć tą samą ścieżką';

  @override
  String get map_removeLast => 'Usuń ostatni';

  @override
  String get map_pathTraceCancelled => 'Śledzenie ścieżki anulowano.';

  @override
  String get time_justNow => 'Właśnie teraz';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minut temu';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h temu';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dni temu';
  }

  @override
  String get time_hour => 'godzina';

  @override
  String get time_hours => 'godziny';

  @override
  String get time_day => 'dzień';

  @override
  String get time_days => 'dni';

  @override
  String get time_week => 'tydzień';

  @override
  String get time_weeks => 'tygodnie';

  @override
  String get time_month => 'miesiąc';

  @override
  String get time_months => 'miesiące';

  @override
  String get time_minutes => 'minuty';

  @override
  String get time_allTime => 'Cały czas';

  @override
  String get dialog_disconnect => 'Odłącz';

  @override
  String get dialog_disconnectConfirm =>
      'Czy na pewno chcesz się odłączyć od tego urządzenia?';

  @override
  String get login_repeaterLogin => 'Logowanie do przekaźnika';

  @override
  String get login_roomLogin => 'Logowanie do pokoju';

  @override
  String get login_password => 'Hasło';

  @override
  String get login_enterPassword => 'Wprowadź hasło';

  @override
  String get login_savePassword => 'Zapisz hasło';

  @override
  String get login_savePasswordSubtitle =>
      'Hasło będzie bezpiecznie przechowywane na tym urządzeniu.';

  @override
  String get login_repeaterDescription =>
      'Wprowadź hasło do przekaźnika, aby uzyskać dostęp do ustawień i stanu.';

  @override
  String get login_roomDescription =>
      'Wprowadź hasło do pokoju, aby uzyskać dostęp do ustawień i statusu.';

  @override
  String get login_login => 'Zaloguj się';

  @override
  String login_attempt(int current, int max) {
    return 'Próba $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Zalogowanie się nie powiodło: $error';
  }

  @override
  String get login_failedMessage =>
      'Logowanie nie powiodło się. Hasło jest nieprawidłowe albo przekaźnik jest nieosiągalny.';

  @override
  String get common_reload => 'Odśwież';

  @override
  String get common_clear => 'Wyczyść';

  @override
  String get path_enterCustomPath => 'Wprowadź własną ścieżkę';

  @override
  String get path_currentPathLabel => 'Aktualna ścieżka';

  @override
  String get path_hexPrefixInstructions =>
      'Wprowadź 2-znakowe prefiksy szesnastkowe dla każdego skoku, oddzielone przecinkami.';

  @override
  String get path_hexPrefixExample =>
      'A1,F2,3C (każdy węzeł używa pierwszego bajtu swojego klucza publicznego)';

  @override
  String get path_labelHexPrefixes => 'Ścieżka (prefiksy hex)';

  @override
  String get path_helperMaxHops =>
      'Maksymalnie 64 skoki. Każdy prefiks ma 2 znaki szesnastkowe (1 bajt).';

  @override
  String get path_selectFromContacts => 'Albo wybierz z kontaktów:';

  @override
  String get path_noRepeatersFound =>
      'Nie znaleziono przekaźników ani serwerów pokoi.';

  @override
  String get path_customPathsRequire =>
      'Dostosowane ścieżki wymagają pośrednich skoków, które mogą przekazywać wiadomości.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Nieprawidłowe prefiksy szesnastkowe: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Ścieżka jest zbyt długa. Dozwolonych skoków wynosi 64.';

  @override
  String get path_setPath => 'Ustaw Ścieżkę';

  @override
  String get repeater_management => 'Zarządzanie przekaźnikami';

  @override
  String get room_management => 'Zarządzanie Serwerem Pokoju';

  @override
  String get repeater_guest => 'Informacje dotyczące urządzenia powtarzającego';

  @override
  String get room_guest => 'Informacje o serwerze';

  @override
  String get repeater_managementTools => 'Narzędzia Zarządzania';

  @override
  String get repeater_guestTools => 'Narzędzia dla gości';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Wyświetl status przekaźnika, statystyki i sąsiadów.';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Wyświetl dane telemetryczne z czujników i statystyki systemu';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Wyślij polecenia do przekaźnika';

  @override
  String get repeater_neighbors => 'Sąsiedzi';

  @override
  String get repeater_neighborsSubtitle => 'Wyświetl sąsiadów zero-hop.';

  @override
  String get repeater_settings => 'Ustawienia';

  @override
  String get repeater_settingsSubtitle => 'Skonfiguruj parametry przekaźnika';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Synchronizacja zegara po zalogowaniu';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Automatycznie wysyłaj powiadomienie \"synchronizacja zegara\" po pomyślnym zalogowaniu.';

  @override
  String get repeater_statusTitle => 'Status przekaźnika';

  @override
  String get repeater_refresh => 'Odśwież';

  @override
  String get repeater_statusRequestTimeout =>
      'Przekroczono czas oczekiwania na status.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Błąd podczas ładowania statusu: $error';
  }

  @override
  String get repeater_systemInformation => 'Informacje o systemie';

  @override
  String get repeater_battery => 'Bateria';

  @override
  String get repeater_clockAtLogin => 'Godzina (przy logowaniu)';

  @override
  String get repeater_uptime => 'Czas pracy';

  @override
  String get repeater_queueLength => 'Długość kolejki';

  @override
  String get repeater_debugFlags => 'Opcje debugowania';

  @override
  String get repeater_radioStatistics => 'Statystyki Radia';

  @override
  String get repeater_lastRssi => 'Ostatni RSSI';

  @override
  String get repeater_lastSnr => 'Ostatnie SNR';

  @override
  String get repeater_noiseFloor => 'Poziom Szumów';

  @override
  String get repeater_txAirtime => 'Czas nadawania TX';

  @override
  String get repeater_rxAirtime => 'Czas odbioru RX';

  @override
  String get repeater_packetStatistics => 'Statystyki pakietów';

  @override
  String get repeater_sent => 'Wysłane';

  @override
  String get repeater_received => 'Otrzymano';

  @override
  String get repeater_duplicates => 'Powtórzenia';

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
    return 'Razem: $total, Zalew: $flood, Bezpośrednio: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Razem: $total, Zalew: $flood, Bezpośrednio: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Zalew: $flood, Bezpośrednie: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Razem: $total';
  }

  @override
  String get repeater_settingsTitle => 'Ustawienia przekaźnika';

  @override
  String get repeater_basicSettings => 'Podstawowe Ustawienia';

  @override
  String get repeater_repeaterName => 'Nazwa przekaźnika';

  @override
  String get repeater_repeaterNameHelper => 'Wyświetl nazwę tego przekaźnika';

  @override
  String get repeater_adminPassword => 'Hasło Administracyjne';

  @override
  String get repeater_adminPasswordHelper => 'Hasło z pełnym dostępem';

  @override
  String get repeater_guestPassword => 'Hasło gościa';

  @override
  String get repeater_guestPasswordHelper => 'Hasło tylko do odczytu';

  @override
  String get repeater_radioSettings => 'Ustawienia radia';

  @override
  String get repeater_frequencyMhz => 'Częstotliwość (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'Moc TX';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Przepustowość';

  @override
  String get repeater_spreadingFactor => 'Współczynnik rozpraszania';

  @override
  String get repeater_codingRate => 'Współczynnik kodowania';

  @override
  String get repeater_locationSettings => 'Ustawienia Lokalizacji';

  @override
  String get repeater_latitude => 'Szerokość';

  @override
  String get repeater_latitudeHelper => 'Stopnie dziesiętne (np. 37.7749)';

  @override
  String get repeater_longitude => 'Długość';

  @override
  String get repeater_longitudeHelper => 'Stopnie dziesiętne (np. -122,4194)';

  @override
  String get repeater_features => 'Funkcje';

  @override
  String get repeater_packetForwarding => 'Przekierowanie pakietów';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Włącz przekaźnik, aby przekazywać pakiety.';

  @override
  String get repeater_guestAccess => 'Dostęp dla gości';

  @override
  String get repeater_guestAccessSubtitle =>
      'Umożliw dostęp tylko do odczytu dla gości.';

  @override
  String get repeater_privacyMode => 'Tryb prywatności';

  @override
  String get repeater_privacyModeSubtitle =>
      'Ukryj imię/lokalizację w rozgłoszeniach';

  @override
  String get repeater_advertisementSettings => 'Ustawienia rozgłoszeń';

  @override
  String get repeater_localAdvertInterval => 'Interwał rozgłoszenia lokalnego';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minut';
  }

  @override
  String get repeater_floodAdvertInterval => 'Interwał rozgłoszenia zalewowego';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours godzin';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Interwał Zaszyfrowanego Rozgłoszenia';

  @override
  String get repeater_dangerZone => 'Strefa Zagrożeń';

  @override
  String get repeater_rebootRepeater => 'Zrestartuj Przekaźnik';

  @override
  String get repeater_rebootRepeaterSubtitle => 'Zrestartuj przekaźnik.';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Czy na pewno chcesz zrestartować ten przekaźnik?';

  @override
  String get repeater_regenerateIdentityKey => 'Wygeneruj klucz tożsamości';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Wygeneruj nową parę kluczy publicznych/prywatnych';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Zostanie wygenerowana nowa tożsamość dla przekaźnika. Kontynuować?';

  @override
  String get repeater_eraseFileSystem => 'Wyczyść System Plików';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Sformatuj system plików przekaźnika';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'OSTRZEŻENIE: To spowoduje usunięcie wszystkich danych z przekaźnika. Nie da się tego cofnąć!';

  @override
  String get repeater_eraseSerialOnly =>
      'Usunięcie jest dostępne tylko przez konsolę szeregową.';

  @override
  String repeater_commandSent(String command) {
    return 'Polecenie wysłane: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Błąd podczas wysyłania polecenia: $error';
  }

  @override
  String get repeater_confirm => 'Potwierdź';

  @override
  String get repeater_settingsSaved => 'Ustawienia zostały pomyślnie zapisane.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Błąd zapisu ustawień: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Odśwież Podstawowe Ustawienia';

  @override
  String get repeater_refreshRadioSettings => 'Odśwież ustawienia radia';

  @override
  String get repeater_refreshTxPower => 'Odśwież moc TX';

  @override
  String get repeater_refreshLocationSettings =>
      'Odśwież Ustawienia Lokalizacji';

  @override
  String get repeater_refreshPacketForwarding => 'Odśwież trasowanie pakietów';

  @override
  String get repeater_refreshGuestAccess => 'Odśwież dostęp gościa';

  @override
  String get repeater_refreshPrivacyMode => 'Odśwież Tryb Prywatności';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Odśwież ustawienia rozgłoszeń';

  @override
  String repeater_refreshed(String label) {
    return '$label odświeżone';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Błąd podczas odświeżania $label';
  }

  @override
  String get repeater_cliTitle => 'Przekaźnik CLI';

  @override
  String get repeater_debugNextCommand => 'Debug Następną Komendę';

  @override
  String get repeater_commandHelp => 'Pomoc';

  @override
  String get repeater_clearHistory => 'Wyczyść historię';

  @override
  String get repeater_noCommandsSent => 'Nie wysłano jeszcze żadnych poleceń';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Wprowadź polecenie poniżej lub użyj szybkich poleceń';

  @override
  String get repeater_enterCommandHint => 'Wprowadź polecenie...';

  @override
  String get repeater_previousCommand => 'Poprzednia komenda';

  @override
  String get repeater_nextCommand => 'Następna komenda';

  @override
  String get repeater_enterCommandFirst => 'Wprowadź najpierw polecenie';

  @override
  String get repeater_cliCommandFrameTitle => 'Ramka polecenia CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Błąd: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Pobierz nazwę';

  @override
  String get repeater_cliQuickGetRadio => 'Pobierz radio';

  @override
  String get repeater_cliQuickGetTx => 'Pobierz TX';

  @override
  String get repeater_cliQuickNeighbors => 'Sąsiedzi';

  @override
  String get repeater_cliQuickVersion => 'Wersja';

  @override
  String get repeater_cliQuickAdvertise => 'Rozgłoś';

  @override
  String get repeater_cliQuickClock => 'Godzina';

  @override
  String get repeater_cliQuickClockSync => 'Synchronizacja zegara';

  @override
  String get repeater_cliQuickDiscovery => 'Odkryj Sąsiadów';

  @override
  String get repeater_cliHelpAdvert => 'Wysyła pakiet rozgłoszeniowy';

  @override
  String get repeater_cliHelpReboot =>
      'Zresetuj urządzenie. (Uwaga, może pojawić się \'Timeout\', co jest normalne)';

  @override
  String get repeater_cliHelpClock =>
      'Wyświetla aktualny czas zgodnie z zegarem urządzenia.';

  @override
  String get repeater_cliHelpPassword =>
      'Ustawia nowe hasło administratora dla urządzenia.';

  @override
  String get repeater_cliHelpVersion =>
      'Wyświetla wersję urządzenia i datę budowy oprogramowania.';

  @override
  String get repeater_cliHelpClearStats =>
      'Resetuje różne wskaźniki statystyk do zera.';

  @override
  String get repeater_cliHelpSetAf => 'Ustawia czynnik czasu powietrznego.';

  @override
  String get repeater_cliHelpSetTx =>
      'Ustawia moc transmisji LoRa w dBm. (zrestartuj, aby zastosować)';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Włącza lub wyłącza rolę przekaźnika dla tego węzła.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Serwer pokoju) Jeśli \'włączone\', to logowanie z pustym hasłem będzie dozwolone, ale nie można publikować w pokoju (tylko czytać).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Ustawia maksymalną liczbę skoków pakietu zalewowego (jeśli >= max, pakiet nie jest przekierowywany)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Ustawia Próg Interferencji (w dB). Domyślnie wynosi 14. Ustaw na 0, aby wyłączyć wykrywanie zakłóceń kanału.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Ustawia interwał do zresetowania automatycznego wzmocnienia (AGC). Ustaw na 0, aby wyłączyć.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Włącza lub wyłącza funkcję \'podwójnych potwierdzeń\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Ustawia interwał timera w minutach do wysyłania pakietu rozgłoszenia lokalnego (bezpośredniego). Ustaw na 0, aby wyłączyć.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Ustawia interwał timera w godzinach do wysłania pakietu rozgłoszeniowego typu \"flood\". Ustaw na 0, aby wyłączyć.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Ustawia/aktualizuje hasło gościa. (dla przekaźników loginy gości mogą wysyłać żądanie \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Ustawia nazwę rozgłoszenia.';

  @override
  String get repeater_cliHelpSetLat =>
      'Ustawia współrzędną geograficzną (w stopniach dziesiętnych) mapy rozgłoszeń.';

  @override
  String get repeater_cliHelpSetLon =>
      'Ustawia współrzędną długościową mapy rozgłoszeń. (stopnie dziesiętne)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Ustawia nowe parametry radia i zapisuje je w preferencjach. Wymaga polecenia \"reboot\" do zastosowania.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Ustawienia (eksperymentalne) bazowe (muszą być > 1, aby działać) do stosowania lekkiego opóźnienia dla odebranych pakietów, w oparciu o siłę sygnału/wynik. Ustaw na 0, aby wyłączyć.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Ustawia czynnik mnożony przez czas utrzymania w trybie zalewowym dla pakietu oraz z wykorzystaniem losowego systemu slotów, aby opóźnić jego przesyłanie (zmniejszając prawdopodobieństwo kolizji).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Taki sam jak txdelay, ale dla stosowania losowej opóźnienia przy przekazywaniu pakietów w trybie bezpośrednim.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Włącz/Wyłącz mostek.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Ustaw czas opóźnienia przed ponownym wysyłaniem pakietów.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Wybierz, czy most będzie ponownie transmitował otrzymywane pakiety, czy też wysyłane.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Ustaw prędkość transmisji magistrali szeregowej dla mostów rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Ustaw sekret dla mostów ESPNOW.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Ustawia niestandardowy współczynnik do korekty zgłaszanego napięcia baterii (obsługa tylko na wybranych płytach).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Ustawia tymczasowe parametry radia na podany czas trwania w minutach, a następnie powraca do oryginalnych parametrów radia. (nie zapisuje zmian w preferencjach).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modyfikuje ACL. Usuwa dopasowaną wpis (z prefiksem pubkey), jeśli \"permissions\" wynosi zero. Dodaje nowy wpis, jeśli pubkey-hex ma pełną długość i nie znajduje się obecnie w ACL. Aktualizuje wpis, dopasowując prefiks pubkey. Bit uprawnień zależy od roli firmware, ale dolne 2 bity to: 0 (Gość), 1 (tylko odczyt), 2 (odczyt i zapis), 3 (administrator).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Pobiera typ mostka: brak, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Rozpoczyna się logowanie pakietów do systemu plików.';

  @override
  String get repeater_cliHelpLogStop =>
      'Zatrzymuje logowanie pakietów do systemu plików.';

  @override
  String get repeater_cliHelpLogErase =>
      'Usuwa logi pakietów z systemu plików.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Wyświetla listę innych węzłów przekaźnikowych usłyszanych przez rozgłoszenia zero-hop. Każda linia to: id-prefix-hex:timestamp:snr-times-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Usuwa pierwszy pasujący wpis (z prefiksem pubkey (hex)) z listy sąsiadów.';

  @override
  String get repeater_cliHelpRegion =>
      '(tylko port szeregowy) Wyświetla wszystkie zdefiniowane regiony i aktualne uprawnienia do zalewu.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'UWAGA: to jest specjalne wywołanie wielokomendowe. Każda następna komenda jest nazwą regionu (wcięta spacjami, aby wskazywać hierarchię nadrzędną, z minimum jedną spacją). Zakończona wysłaniem pustej linii/komendy.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Wyszukuje region o podanej nazwie prefiksu (lub \"\" dla zakresu globalnego). Odpowiada \"-> region-name (parent-name) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Dodaje lub aktualizuje definicję regionu z podaną nazwą.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Usuwa definicję regionu o podanej nazwie. (musi się dokładnie zgadzać i nie może mieć podregionów).';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Ustawia uprawnienia \'F\' (zalewowe) dla podanego regionu. (\'\' dla zakresu globalnego/starszego)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Usuwa uprawnienie \'F\' (zalewowe) dla podanej strefy. (ZALECANE: na tym etapie NIE zaleca się używania tego na globalnym/starszym zakresie!!).';

  @override
  String get repeater_cliHelpRegionHome =>
      'Odpowiada z aktualnej \'home\' region. (Uwaga: nie zostało jeszcze zastosowane, zarezerwowane na przyszłość).';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Ustawia region \'domowe\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Zapisuje listę/mapę regionów do pamięci.';

  @override
  String get repeater_cliHelpGps =>
      'Wyświetla status GPS. Jeśli GPS jest wyłączony, odpowiada tylko \"off\", jeśli jest włączony, odpowiada z \"on\", \"status\", \"fix\", liczbą satelitów.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Włącza/wyłącza nawigację GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronizuje czas węzła z zegarem GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Ustawia pozycję węzła na współrzędne GPS i zapisuje preferencje.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Udostępnia konfigurację rozgłoszeń lokalizacji węzła:\n- brak: nie uwzględniaj lokalizacji w rozgłoszeniach\n- udostępnia: udostępnia lokalizację GPS (z SensorManager)\n- ustawienia: rozgłaszaj lokalizację przechowywaną w ustawieniach';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Ustawia konfigurację rozgłoszeń lokalizacji.';

  @override
  String get repeater_commandsListTitle => 'Lista poleceń';

  @override
  String get repeater_commandsListNote =>
      'UWAGA: dla różnych poleceń \"set ...\" istnieje również polecenie \"get ...\".';

  @override
  String get repeater_general => 'Ogólne';

  @override
  String get repeater_settingsCategory => 'Ustawienia';

  @override
  String get repeater_bridge => 'Most';

  @override
  String get repeater_logging => 'Rejestrowanie';

  @override
  String get repeater_neighborsRepeaterOnly => 'Sąsiedzi (tylko przekaźnik)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Zarządzanie Regionem (tylko Przekaźnik)';

  @override
  String get repeater_regionNote =>
      'Wprowadzono komendy regionalne w celu zarządzania definicjami i uprawnieniami regionów.';

  @override
  String get repeater_gpsManagement => 'Zarządzanie GPS';

  @override
  String get repeater_gpsNote =>
      'Polecenie GPS zostało wprowadzone w celu zarządzania tematami związanymi z lokalizacją.';

  @override
  String get telemetry_receivedData => 'Odebrane dane telemetrii';

  @override
  String get telemetry_requestTimeout =>
      'Przekroczono czas oczekiwania na telemetrię.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Błąd podczas ładowania telemetrii: $error';
  }

  @override
  String get telemetry_noData => 'Brak dostępnych danych telemetrycznych.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Kanał $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Bateria';

  @override
  String get telemetry_voltageLabel => 'Napięcie';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Prąd';

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
  String get neighbors_receivedData => 'Otrzymano dane sąsiedztwa';

  @override
  String get neighbors_requestTimedOut =>
      'Sąsiedzi proszą o wyłączenie timingu.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Błąd podczas ładowania sąsiadów: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Sąsiedzi przekaźników';

  @override
  String get neighbors_noData => 'Brak danych dotyczących sąsiadów.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Nieznana $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Usłyszano: $time temu';
  }

  @override
  String get channelPath_title => 'Ścieżka pakietu';

  @override
  String get channelPath_viewMap => 'Wyświetl mapę';

  @override
  String get channelPath_otherObservedPaths => 'Inne zaobserwowane ścieżki';

  @override
  String get channelPath_repeaterHops => 'Skoki przekaźników';

  @override
  String get channelPath_noHopDetails =>
      'Szczegóły dotyczące tego pakietu nie zostały podane.';

  @override
  String get channelPath_messageDetails => 'Szczegóły wiadomości';

  @override
  String get channelPath_senderLabel => 'Nadawca';

  @override
  String get channelPath_timeLabel => 'Czas';

  @override
  String get channelPath_repeatsLabel => 'Powtórzenia';

  @override
  String channelPath_pathLabel(int index) {
    return 'Ścieżka $index';
  }

  @override
  String get channelPath_observedLabel => 'Obserwowane';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Obserwowana ścieżka $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Brak danych lokalizacyjnych';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Nieznane';

  @override
  String get channelPath_floodPath => 'Zalew';

  @override
  String get channelPath_directPath => 'Bezpośrednio';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 z $total skoków';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed z $total skoków';
  }

  @override
  String get channelPath_mapTitle => 'Mapa ścieżek';

  @override
  String get channelPath_noRepeaterLocations =>
      'Brak dostępnych lokalizacji przekaźników dla tej ścieżki.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Ścieżka $index (Główna)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Ścieżka';

  @override
  String get channelPath_observedPathHeader => 'Obserwowana ścieżka';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Brak dostępnych szczegółów hopa dla tego pakietu.';

  @override
  String get channelPath_unknownRepeater => 'Nieznany Przekaźnik';

  @override
  String get community_title => 'Społeczność';

  @override
  String get community_create => 'Utwórz Społeczność';

  @override
  String get community_createDesc =>
      'Utwórz nową społeczność i udostępnij za pomocą kodu QR.';

  @override
  String get community_join => 'Dołącz';

  @override
  String get community_joinTitle => 'Dołącz do społeczności';

  @override
  String community_joinConfirmation(String name) {
    return 'Czy chcesz dołączyć do społeczności \"$name\"?';
  }

  @override
  String get community_scanQr => 'Skanuj QR kod społeczności';

  @override
  String get community_scanInstructions =>
      'Skieruj kamerę w kierunku kodu QR społeczności.';

  @override
  String get community_showQr => 'Pokaż kod QR';

  @override
  String get community_publicChannel => 'Społeczność Publiczna';

  @override
  String get community_hashtagChannel => 'Hashtag Społeczności';

  @override
  String get community_name => 'Nazwa Społeczności';

  @override
  String get community_enterName => 'Wprowadź nazwę społeczności';

  @override
  String community_created(String name) {
    return 'Społeczność \"$name\" została utworzona';
  }

  @override
  String community_joined(String name) {
    return 'Dołączył do społeczności \"$name\"';
  }

  @override
  String get community_qrTitle => 'Dziel się Społecznością';

  @override
  String community_qrInstructions(String name) {
    return 'Skanuj ten kod QR, aby dołączyć $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Kanały hashtagowe społeczności są dostępne tylko dla członków społeczności';

  @override
  String get community_invalidQrCode => 'Nieprawidłowy kod QR społeczności.';

  @override
  String get community_alreadyMember => 'Już jesteś członkiem.';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Jesteś już członkiem \"$name\".';
  }

  @override
  String get community_addPublicChannel => 'Dodaj Kanał Publiczny Społeczności';

  @override
  String get community_addPublicChannelHint =>
      'Automatycznie dodaj kanał publiczny dla tej społeczności.';

  @override
  String get community_noCommunities =>
      'Nie dołączono jeszcze żadnych społeczności.';

  @override
  String get community_scanOrCreate =>
      'Skanuj kod QR lub utwórz społeczność, aby zacząć.';

  @override
  String get community_manageCommunities => 'Zarządzaj Grupami';

  @override
  String get community_delete => 'Opuszczenie Społeczności';

  @override
  String community_deleteConfirm(String name) {
    return 'Opuścić \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Spowoduje to również usunięcie $count kanału/kanałów i ich wiadomości.';
  }

  @override
  String community_deleted(String name) {
    return 'Opuszczono społeczność \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Zregeneruj sekret';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regeneruj tajny klucz dla \"$name\"? Wszyscy członkowie będą musieli zeskanować nowy kod QR, aby kontynuować komunikację.';
  }

  @override
  String get community_regenerate => 'Zregeneruj';

  @override
  String community_secretRegenerated(String name) {
    return 'Hasło ponownie wygenerowane dla \"$name\"';
  }

  @override
  String get community_updateSecret => 'Zaktualizuj tajny klucz';

  @override
  String community_secretUpdated(String name) {
    return 'Hasło zaktualizowane dla \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Skanuj nowy kod QR, aby zaktualizować sekret dla \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Dodaj hashtag społeczności';

  @override
  String get community_addHashtagChannelDesc =>
      'Dodaj kanał z hashtagiem dla tej społeczności';

  @override
  String get community_selectCommunity => 'Wybierz społeczność';

  @override
  String get community_regularHashtag => 'Hashtag regular';

  @override
  String get community_regularHashtagDesc =>
      'Publiczny hashtag (każdy może dołączyć)';

  @override
  String get community_communityHashtag => 'Hashtag Społeczności';

  @override
  String get community_communityHashtagDesc =>
      'Dostępne tylko dla członków społeczności';

  @override
  String community_forCommunity(String name) {
    return 'Dla $name';
  }

  @override
  String get listFilter_tooltip => 'Filtruj i sortuj';

  @override
  String get listFilter_sortBy => 'Sortuj po';

  @override
  String get listFilter_latestMessages => 'Najnowsze wiadomości';

  @override
  String get listFilter_heardRecently => 'Słyszano niedawno';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtry';

  @override
  String get listFilter_source => 'Źródło';

  @override
  String get listFilter_saved => 'Zapisane';

  @override
  String get listFilter_discovered => 'Odkryte';

  @override
  String get listFilter_all => 'Wszystko';

  @override
  String get listFilter_favorites => 'Ulubione';

  @override
  String get listFilter_addToFavorites => 'Dodaj do ulubionych';

  @override
  String get listFilter_removeFromFavorites => 'Usuń z ulubionych';

  @override
  String get listFilter_users => 'Użytkownicy';

  @override
  String get listFilter_repeaters => 'Przekaźniki';

  @override
  String get listFilter_roomServers => 'Serwery pokoju';

  @override
  String get listFilter_unreadOnly => 'Tylko nieprzeczytane';

  @override
  String get listFilter_newGroup => 'Nowa grupa';

  @override
  String get pathTrace_you => 'Ty';

  @override
  String get pathTrace_failed => 'Śledzenie ścieżki nie powiodło się.';

  @override
  String get pathTrace_notAvailable => 'Ścieżka śledzenia niedostępna.';

  @override
  String get pathTrace_refreshTooltip => 'Odśwież ścieżkę.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Jeden lub więcej z chmieli nie ma określonej lokalizacji!';

  @override
  String get pathTrace_clearTooltip => 'Wyczyść ścieżkę';

  @override
  String get losSelectStartEnd => 'Wybierz węzły początkowe i końcowe dla LOS.';

  @override
  String losRunFailed(String error) {
    return 'Sprawdzenie pola widzenia nie powiodło się: $error';
  }

  @override
  String get losClearAllPoints => 'Wyczyść wszystkie punkty';

  @override
  String get losRunToViewElevationProfile =>
      'Uruchom LOS, aby wyświetlić profil wysokości';

  @override
  String get losMenuTitle => 'Menu LOS';

  @override
  String get losMenuSubtitle =>
      'Stuknij węzły lub naciśnij i przytrzymaj mapę, aby uzyskać niestandardowe punkty';

  @override
  String get losShowDisplayNodes => 'Pokaż węzły wyświetlające';

  @override
  String get losCustomPoints => 'Punkty niestandardowe';

  @override
  String losCustomPointLabel(int index) {
    return 'Niestandardowe $index';
  }

  @override
  String get losPointA => 'Punkt A';

  @override
  String get losPointB => 'Punkt B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antena A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antena B: $value $unit';
  }

  @override
  String get losRun => 'Uruchom LOS-a';

  @override
  String get losNoElevationData => 'Brak danych o wysokości';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, czysty LOS, minimalny prześwit $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, zablokowane przez $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: sprawdzam...';

  @override
  String get losStatusNoData => 'LOS: brak danych';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total jasne, $blocked zablokowane, $unknown nieznane';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Dane dotyczące wysokości są niedostępne dla jednej lub większej liczby próbek.';

  @override
  String get losErrorInvalidInput =>
      'Nieprawidłowe dane punktów/wysokości do obliczenia LOS.';

  @override
  String get losRenameCustomPoint => 'Zmień nazwę punktu niestandardowego';

  @override
  String get losPointName => 'Nazwa punktu';

  @override
  String get losShowPanelTooltip => 'Pokaż panel LOS';

  @override
  String get losHidePanelTooltip => 'Ukryj panel LOS';

  @override
  String get losElevationAttribution =>
      'Dane dotyczące wysokości: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Horyzont radiowy';

  @override
  String get losLegendLosBeam => 'Linia widoczności';

  @override
  String get losLegendTerrain => 'Teren';

  @override
  String get losFrequencyLabel => 'Częstotliwość';

  @override
  String get losFrequencyInfoTooltip => 'Zobacz szczegóły obliczenia';

  @override
  String get losFrequencyDialogTitle => 'Obliczanie horyzontu radiowego';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Zaczynając od k=$baselineK przy $baselineFreq MHz, obliczenia korygują współczynnik k dla bieżącego pasma $frequencyMHz MHz, które definiuje zakrzywiony limit horyzontu radiowego.';
  }

  @override
  String get contacts_pathTrace => 'Śledzenie Ścieżek';

  @override
  String get contacts_ping => 'Pingować';

  @override
  String get contacts_repeaterPathTrace => 'Śledzenie ścieżki do przekaźnika';

  @override
  String get contacts_repeaterPing => 'Ping przekaźnika';

  @override
  String get contacts_roomPathTrace =>
      'Śledzenie ścieżki do serwera pokojowego';

  @override
  String get contacts_roomPing => 'Pinguj serwer pokoju';

  @override
  String get contacts_chatTraceRoute => 'Śledź trasę promienia';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Śledź trasę do $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Schowek jest pusty.';

  @override
  String get contacts_invalidAdvertFormat => 'Nieprawidłowe dane kontaktowe';

  @override
  String get contacts_contactImported => 'Kontakt został zaimportowany.';

  @override
  String get contacts_contactImportFailed =>
      'Kontakt nie został zaimportowany.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name jest już w Twoich kontaktach.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Rozgłoszenie zero-hop';

  @override
  String get contacts_floodAdvert => 'Rozgłoszenie zalewowe';

  @override
  String get contacts_copyAdvertToClipboard => 'Kopiuj rozgłoszenie do schowka';

  @override
  String get contacts_addContactFromClipboard => 'Dodaj kontakt z schowka';

  @override
  String get contacts_ShareContact => 'Kopiuj kontakt do schowka';

  @override
  String get contacts_ShareContactZeroHop =>
      'Udostępnij kontakt przez rozgłoszenie';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Wysłano kontakt przez rozgłoszenie.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Nie udało się wysłać kontaktu.';

  @override
  String get contacts_contactAdvertCopied =>
      'Rozgłoszenie skopiowano do schowka.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Kopiowanie rozgłoszenia do schowka nie powiodło się.';

  @override
  String get contacts_addContact => 'Dodaj kontakt';

  @override
  String get contacts_scanQrCode => 'Zeskanuj QR kontaktu';

  @override
  String get contacts_scanQrCodeDesc =>
      'Zeskanuj kod QR kontaktu z aplikacji MeshCore';

  @override
  String get contacts_enterIdHash => 'Wprowadź kontakt ręcznie';

  @override
  String get contacts_enterIdHashDesc =>
      'Wklej rozgłoszenie kontaktu lub link meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... lub klucz publiczny hex';

  @override
  String get contacts_import => 'Importuj';

  @override
  String get contacts_scanContactInstructions =>
      'Zeskanuj kod QR kontaktu MeshCore';

  @override
  String get notification_activityTitle => 'Aktywność MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wiadomości',
      many: 'wiadomości',
      few: 'wiadomości',
      one: 'wiadomość',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'wiadomości kanału',
      many: 'wiadomości kanału',
      few: 'wiadomości kanału',
      one: 'wiadomość kanału',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nowych węzłów',
      many: 'nowych węzłów',
      few: 'nowe węzły',
      one: 'nowy węzeł',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nowy $contactType wykryty';
  }

  @override
  String get notification_receivedNewMessage => 'Otrzymano nową wiadomość';

  @override
  String get settings_gpxExportRepeaters =>
      'Eksportuj przekaźniki / roomservery do GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Eksportuje przekaźniki / roomservery z lokalizacją do pliku GPX.';

  @override
  String get settings_gpxExportContacts => 'Eksportuj towarzyszy do GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Eksportuje towarzyszy z lokalizacją do pliku GPX.';

  @override
  String get settings_gpxExportAll => 'Eksportuj wszystkie kontakty do GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Eksportuje wszystkie kontakty z lokalizacją do pliku GPX.';

  @override
  String get settings_gpxExportSuccess => 'Pomyślnie wyeksportowano plik GPX.';

  @override
  String get settings_gpxExportNoContacts =>
      'Brak kontaktów do wyeksportowania.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Nie obsługiwane na Twoim urządzeniu/systemie operacyjnym';

  @override
  String get settings_gpxExportError => 'Wystąpił błąd podczas eksportowania.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Lokalizacje przekaźników i roomserverów';

  @override
  String get settings_gpxExportChat => 'Lokalizacje towarzyszy';

  @override
  String get settings_gpxExportAllContacts => 'Wszystkie lokalizacje kontaktów';

  @override
  String get settings_gpxExportShareText =>
      'Dane mapy wyeksportowane z MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'Eksport danych mapy GPX MeshTrax';

  @override
  String get snrIndicator_nearByRepeaters => 'Pobliskie przekaźniki';

  @override
  String get snrIndicator_lastSeen => 'Ostatnio widziany';

  @override
  String get contactsSettings_title => 'Ustawienia kontaktów';

  @override
  String get contactsSettings_autoAddTitle => 'Automatyczne odnajdywanie';

  @override
  String get contactsSettings_otherTitle =>
      'Inne ustawienia związane z kontaktami';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Automatycznie dodaj użytkowników';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Pozwól towarzyszowi automatycznie dodawać znalezione użytkowników.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Automatyczne dodawanie przekaźników';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Zezwól towarzyszowi na automatyczne dodawanie odkrytych przekaźników.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Automatycznie dodaj roomservery';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Zezwól towarzyszowi na automatyczne dodawanie znalezionych roomserverów.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Automatycznie dodaj czujniki';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Zezwól towarzyszowi na automatyczne dodawanie wykrytych czujników.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Nadpisz najstarszy';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Gdy lista kontaktów jest pełna, najstarszy nieulubiony kontakt zostanie zastąpiony.';

  @override
  String get discoveredContacts_Title => 'Odkryte Kontakty';

  @override
  String get discoveredContacts_noMatching => 'Brak pasujących kontaktów';

  @override
  String get listFilter_searchHint => 'Szukaj...';

  @override
  String get discoveredContacts_searchHint => 'Wyszukaj odkryte kontakty';

  @override
  String get discoveredContacts_contactAdded => 'Kontakt dodany';

  @override
  String get discoveredContacts_addContact => 'Dodaj kontakt';

  @override
  String get discoveredContacts_copyContact => 'Kopiuj kontakt do schowka';

  @override
  String get discoveredContacts_deleteContact => 'Usuń kontakt';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Usuń wszystkie odkryte kontakty';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Czy na pewno chcesz usunąć wszystkie znalezione kontakty?';

  @override
  String get chat_sendCooldown =>
      'Prosimy o chwilowe oczekiwanie przed ponownym wysłaniem.';

  @override
  String get chat_notConnected =>
      'Brak połączenia z radiem. Wiadomość nie została wysłana.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Przejdź do najstarszego nieodczytanej wiadomości';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Przy otwieraniu czatu z nieodczytanymi wiadomościami, przewijaj, aby przejść do pierwszej nieodczytanej wiadomości, zamiast do najnowszej.';

  @override
  String get appSettings_languageHu => 'Węgierski';

  @override
  String get appSettings_languageJa => 'Japoński';

  @override
  String get appSettings_languageKo => 'Koreański';

  @override
  String get radioStats_screenTitle => 'Statystyki radiowe';

  @override
  String get radioStats_notConnected =>
      'Połącz się z urządzeniem, aby wyświetlić statystyki radiowe.';

  @override
  String get radioStats_firmwareTooOld =>
      'Statystyki radiowe wymagają towarzyszącej oprogramowania w wersji 8 lub nowszej.';

  @override
  String get radioStats_waiting => 'Czekam na dane…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Poziom szumów: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Ostatni poziom RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Ostatni poziom SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Czas emisji w stacji TX (całkowity): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Czas wykorzystania kanału RX (całkowity): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Poziom szumów (dBm) w ostatnich próbkach.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Poziom szumów: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Pobieranie danych dotyczących radia…';

  @override
  String get radioStats_settingsTile => 'Statystyki radiowe';

  @override
  String get radioStats_settingsSubtitle =>
      'Szum tła, RSSI, SNR oraz czas dostępny';

  @override
  String get translation_title => 'Tłumaczenie';

  @override
  String get translation_enableTitle => 'Włącz tłumaczenie';

  @override
  String get translation_enableSubtitle =>
      'Tłumaczenie otrzymywanych wiadomości oraz umożliwienie tłumaczenia przed wysłaniem.';

  @override
  String get translation_composerTitle => 'Przekład przed wysłaniem';

  @override
  String get translation_composerSubtitle =>
      'Kontroluje domyślny stan ikony tłumaczenia w edytorze.';

  @override
  String get translation_targetLanguage => 'Język docelowy';

  @override
  String get translation_useAppLanguage => 'Użyj języka aplikacji';

  @override
  String get translation_downloadedModelLabel => 'Pobudowany model';

  @override
  String get translation_presetModelLabel => 'Wspólny model Hugging Face';

  @override
  String get translation_manualUrlLabel => 'Adres URL do wersji manualnej';

  @override
  String get translation_downloadModel => 'Pobierz model';

  @override
  String get translation_downloading => 'Pobieranie...';

  @override
  String get translation_working => 'Praca...';

  @override
  String get translation_stop => 'Zatrzymaj się';

  @override
  String get translation_mergingChunks =>
      'Scalanie pobranych fragmentów w jeden plik końcowy...';

  @override
  String get translation_downloadedModels => 'Pobrane modele';

  @override
  String get translation_deleteModel => 'Usuń model';

  @override
  String get translation_modelDownloaded => 'Model tłumaczenia został pobrany.';

  @override
  String get translation_downloadStopped => 'Pobieranie zakończone.';

  @override
  String translation_downloadFailed(String error) {
    return 'Nie udało się pobrać: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Najpierw wprowadź adres URL modelu.';

  @override
  String get scanner_linuxPairingShowPin => 'Pokaż PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Ukryj PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'Kod PIN parowania Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Wprowadź kod PIN dla $deviceName (pozostaw puste, jeśli brak).';
  }

  @override
  String get translation_messageTranslation => 'Tłumaczenie wiadomości';

  @override
  String get translation_translateBeforeSending => 'Przekład przed wysłaniem';

  @override
  String get translation_composerEnabledHint =>
      'Komunikaty zostaną przetłumaczone przed wysłaniem.';

  @override
  String get translation_composerDisabledHint =>
      'Wysyłaj wiadomości w oryginalnym, wpisanym formacie.';

  @override
  String translation_translateTo(String language) {
    return 'Tłumacz na $language';
  }

  @override
  String get translation_translationOptions => 'Opcje tłumaczenia';

  @override
  String get translation_systemLanguage => 'Język systemu';

  @override
  String get routing_title => 'Trasowanie';

  @override
  String routing_route(String route) {
    return 'Zapisana ścieżka: $route';
  }

  @override
  String get routing_noRoute =>
      'jeszcze brak — następna wiadomość pójdzie zalewem i ją pozna';

  @override
  String get routing_auto => 'Automatycznie';

  @override
  String get routing_autoSubtitle =>
      'Używa ścieżki zapisanej w radiu. Zalecane.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder włączony: najpierw próbuje poznanych tras';

  @override
  String get routing_flood => 'Zawsze zalewem';

  @override
  String get routing_floodSubtitle => 'Każda wiadomość trafia do całej sieci';

  @override
  String get routing_custom => 'Własna ścieżka';

  @override
  String get routing_customSubtitle => 'Wybierz przekaźniki samodzielnie';

  @override
  String get routing_forget => 'Resetuj ścieżkę';

  @override
  String get routing_forgetDone =>
      'Ścieżka zresetowana. Następna wiadomość pójdzie zalewem i pozna nową.';

  @override
  String get routing_pathfinder => 'Co wie Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Przekaźniki, które słyszą Ciebie i ten kontakt, oraz poznane trasy tam i z powrotem';

  @override
  String get path_direct => 'Bezpośrednio — bez przekaźników';

  @override
  String get path_directSubtitle =>
      'Tylko gdy kontakt słyszy to radio bezpośrednio';

  @override
  String get chat_kindFlood => 'zalewem';

  @override
  String get chat_kindDirect => 'bezpośrednio';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'skoków',
      many: 'skoków',
      few: 'skoki',
      one: 'skok',
    );
    return 'trasą ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'skoków',
      many: 'skoków',
      few: 'skoki',
      one: 'skok',
    );
    return 'trasą ($count $_temp0, przypuszczalnych: $guessed)';
  }

  @override
  String get chat_statusQueued => 'W kolejce';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Żaden przekaźnik Cię nie usłyszał. Ponowna próba, gdy któryś będzie w zasięgu.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'Radio $name wysyła krótkie kody przekaźników (1 bajt). Pathfinder nie pozna tras do tego kontaktu, dopóki jego radio nie przejdzie na kody 2-bajtowe.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Wysyłanie · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Ponawianie · $kind · próba $attempt z $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Dostarczono · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Dostarczono w próbie $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Dostarczono z opóźnieniem · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Dostarczono · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'próbach',
      many: 'próbach',
      few: 'próbach',
      one: 'próbie',
    );
    return 'Niepowodzenie po $attempts $_temp0 · stuknij, by wysłać ponownie';
  }

  @override
  String get chat_statusFailedShort =>
      'Niepowodzenie · stuknij, by wysłać ponownie';

  @override
  String get chat_resendingByFlood => 'Ponowne wysyłanie zalewem';

  @override
  String get pathfinderHelp_title => 'Co robi Pathfinder';

  @override
  String get pathfinderHelp_what =>
      'Twoje radio pamięta jedną trasę do każdego kontaktu, a gdy ta trasa zawiedzie, wysyła wiadomość zalewem do całej sieci. Pathfinder słucha wszystkiego, co słyszy radio: rozgłoszeń przekaźników, rozmów na kanałach, wiadomości innych osób. Na tej podstawie buduje mapę: które przekaźniki słyszą się nawzajem, które słyszą Ciebie, a które każdego z Twoich kontaktów.';

  @override
  String get pathfinderHelp_how =>
      'Gdy wysyłasz wiadomość, Pathfinder najpierw próbuje swojej najlepszej trasy, potem następnej w kolejności, a po zalew sięga dopiero w ostateczności. Bursztynowa ikona ścieżki oznacza wiadomość wysłaną trasą Pathfindera.';

  @override
  String get pathfinderHelp_learning =>
      'Potrzebuje czasu. Nowa mapa nic jeszcze nie wie, więc na początku Twoje wiadomości są wysyłane dokładnie tak samo jak wcześniej. Po kilku godzinach nasłuchu w jednym miejscu zaczyna proponować trasy, a każde dostarczenie lub niepowodzenie uczy go czegoś nowego. Pierwszego dnia nie spodziewaj się po nim zbyt wiele, a w każdym nowym miejscu — znowu mniej.';

  @override
  String get pathfinderHelp_guessed =>
      'Czasem wypełnia lukę przypuszczeniem: połączeniem, które słyszał tylko w przeciwnym kierunku. Wtedy w wierszu stanu wiadomości widać, ile skoków jest przypuszczalnych. Dostarczenie je potwierdza, a niepowodzenie kosztuje jedną próbę i nic nie zostaje zapamiętane.';

  @override
  String get pathfinderHelp_discover =>
      'Gdy Pathfinder nie jest pewien, które przekaźniki słyszą Cię tutaj, wysyła jedno krótkie zapytanie Discover (nie częściej niż co 10 minut i tylko po nieudanej wysyłce). Jeśli radio ma GPS, zapamiętuje też na tym telefonie, które przekaźniki słyszały Cię w każdym obszarze o rozmiarze około 500 m, ale nigdy nie zapisuje Twojej dokładnej lokalizacji.';

  @override
  String get pathfinderHelp_off =>
      'Po wyłączeniu Pathfindera radio wyznacza trasy dokładnie tak samo jak wcześniej.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Nie pokazuj ponownie';

  @override
  String get pathfinderHelp_ok => 'OK';

  @override
  String get settings_pathGraph => 'Pathfinder (eksperymentalny)';

  @override
  String get settings_pathGraphSubtitle =>
      'Uczy się tras ze wszystkiego, co słyszy radio, i przy wysyłaniu DM najpierw próbuje najlepszych. Bursztynowa ikona ścieżki oznacza wiadomość wysłaną trasą Pathfindera.';

  @override
  String get map_routeAndTrace => 'Trasa i śledzenie';

  @override
  String get map_pathfinderTrace => 'Śledzenie tam i z powrotem';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Tam najlepszą trasą Pathfindera, z powrotem jego najlepszą trasą powrotną';

  @override
  String get map_routeBackMirrored =>
      'Trasa powrotna jeszcze nieznana — powrót tą samą drogą';

  @override
  String get map_traceHelpTitle => 'Przyciski śledzenia ścieżki';

  @override
  String get map_traceHelpCustom =>
      'Wpisz lub wybierz przekaźniki samodzielnie.';

  @override
  String get map_traceHelpRun =>
      'Wysyła śledzenie przez stuknięte przekaźniki, w jedną stronę.';

  @override
  String get map_traceHelpThereAndBack => 'Tam i z powrotem';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Wysyła śledzenie tam, a potem z powrotem przez te same przekaźniki w odwrotnej kolejności.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder wybiera najlepszą trasę przez dwa ostatnio stuknięte przekaźniki i najlepszą trasę z powrotem do Ciebie. Wynik uczy Pathfindera, które połączenia naprawdę działają. Wymaga stuknięcia dwóch przekaźników.';

  @override
  String get map_traceHelpRemoveLast => 'Usuwa ostatni przekaźnik ze ścieżki.';

  @override
  String get map_traceHelpCancel =>
      'Przerywa budowanie śledzenia. Widoczny, zanim stukniesz jakikolwiek przekaźnik.';

  @override
  String get chat_resendingByRoute => 'Ponowne wysyłanie ustawioną trasą';

  @override
  String get room_mute => 'Wycisz pokój';

  @override
  String get room_unmute => 'Wyłącz wyciszenie pokoju';

  @override
  String get room_roleAdmin => 'administrator';

  @override
  String get room_roleMember => 'członek';

  @override
  String get room_roleReadOnly => 'tylko odczyt';

  @override
  String room_clockOff(int minutes) {
    return 'Zegar pokoju różni się o około $minutes min — czasy wiadomości mogą być błędne';
  }

  @override
  String get room_fixClock => 'Ustaw zegar';

  @override
  String get room_clockSyncSent => 'Wysłano synchronizację zegara do pokoju';

  @override
  String get room_readOnlyNotice =>
      'Tylko odczyt: pokój nie przyjął Twojego hasła, Twoje wiadomości nie dotrą do innych członków.';

  @override
  String get room_postAnnouncement => 'Opublikuj ogłoszenie';

  @override
  String get room_postAnnouncementSubtitle =>
      'Wyślij wiadomość w imieniu pokoju do wszystkich członków';

  @override
  String get room_announcementSent => 'Ogłoszenie opublikowane';

  @override
  String get room_announcementFailed =>
      'Publikacja ogłoszenia nie powiodła się';

  @override
  String get room_users => 'Użytkownicy pokoju';

  @override
  String get room_usersSubtitle => 'Zobacz administratorów i ustaw role';

  @override
  String get room_usersAdminsNote =>
      'Pokój pokazuje tylko administratorów. Członkowie z hasłem pokoju nie są wyświetlani.';

  @override
  String get room_usersLoadFailed =>
      'Nie udało się wczytać listy administratorów';

  @override
  String get room_setUserRole => 'Ustaw rolę';

  @override
  String get room_removeAccess => 'Usuń dostęp';

  @override
  String get room_removeOnlyUnknown =>
      'Tego użytkownika nie ma w kontaktach — można go tylko usunąć, nie zmienić.';

  @override
  String get room_roleUpdated => 'Rola zaktualizowana';

  @override
  String get room_roleUpdateFailed => 'Zmiana roli nie powiodła się';

  @override
  String get room_postsStored => 'Zapisane wpisy';

  @override
  String get room_postsDelivered => 'Dostarczone wpisy';

  @override
  String get room_reloadPosts => 'Wczytaj ponownie ostatnie wpisy';

  @override
  String get room_reloadPostsExplain =>
      'Prosi pokój o ponowne wysłanie ostatnich wpisów (przechowuje do 32). Zostaniesz poproszony o hasło pokoju. Posiadane wiadomości zostaną zachowane.';

  @override
  String get room_reloadFailed => 'Nie udało się zresetować pokoju w radiu';

  @override
  String get companionCli_title => 'Wiersz poleceń';

  @override
  String get companionCli_settingsSubtitle =>
      'Wpisuj polecenia tekstowe dla tego radia';

  @override
  String get companionCli_rebooting => 'Ponowne uruchamianie radia…';

  @override
  String get companionCli_cancelled => 'Anulowano';

  @override
  String get companionCli_poweringOff => 'Wyłączanie radia…';

  @override
  String get companionCli_noReply =>
      'Brak odpowiedzi z radia. Spróbuj ponownie.';

  @override
  String get companionCli_powerOffTitle => 'Wyłączyć radio?';

  @override
  String get companionCli_powerOffBody =>
      'Pozostanie wyłączone, dopóki nie naciśniesz jego przycisku lub go nie podłączysz.';

  @override
  String get companionCli_powerOff => 'Wyłącz';

  @override
  String get companionCli_quickBoard => 'Płytka';

  @override
  String get companionCli_quickWifiStatus => 'Stan WiFi';

  @override
  String get companionCli_quickWifiAddress => 'Adres WiFi';

  @override
  String get companionCli_helpBoard => 'Pokazuje producenta i model płytki.';

  @override
  String get companionCli_helpReboot => 'Uruchamia radio ponownie.';

  @override
  String get companionCli_helpPowerOff => 'Wyłącza radio.';

  @override
  String get companionCli_helpSetPin =>
      'Ustawia PIN parowania Bluetooth. Działa po ponownym uruchomieniu.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Ustawia liczbę godzin dodawaną do UTC dla zegara na ekranie radia (-12 do +14).';

  @override
  String get companionCli_helpSetTx =>
      'Ustawia moc nadawania w dBm. Działa od razu.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Ustawia próg zakłóceń w dB. 0 wyłącza wykrywanie zakłóceń.';

  @override
  String get companionCli_helpSetCad =>
      'Nasłuchuje innych radiów przed nadawaniem (wykrywanie aktywności kanału).';

  @override
  String get companionCli_helpSetRxGain =>
      'Zwiększone wzmocnienie odbioru w radiach SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bajty na przekaźnik w trasie: 0 = 1 bajt, 1 = 2 bajty, 2 = 3 bajty.';

  @override
  String get companionCli_helpWifiStatus =>
      'Pokazuje, czy radio jest w sieci WiFi.';

  @override
  String get companionCli_helpWifiIp => 'Pokazuje adres radia w sieci WiFi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Ustawia nazwę sieci WiFi. Działa po ponownym uruchomieniu.';

  @override
  String get companionCli_helpWifiPwd =>
      'Ustawia hasło WiFi. Działa po ponownym uruchomieniu.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Włącza (1) lub wyłącza (0) WiFi. Działa po ponownym uruchomieniu.';

  @override
  String get companionCli_helpWifiClear =>
      'Zapomina sieć WiFi. Działa po ponownym uruchomieniu.';

  @override
  String get companionCli_remoteNoReply =>
      'Brak odpowiedzi. Drugie radio potrzebuje oprogramowania 1.18 lub nowszego i musi pozwalać Ci korzystać ze swojego wiersza poleceń.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Wysłano. Radio nie odpowiada na ponowne uruchomienie ani wyłączenie.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name: próba użycia wiersza poleceń Twojego radia: \"$command\". Odmówiono.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Próba użycia wiersza poleceń Twojego radia: \"$command\". Odmówiono.';
  }

  @override
  String get contact_remoteCli => 'Zezwól na zdalny wiersz poleceń';

  @override
  String get contact_remoteCliSubtitle =>
      'Pozwala temu kontaktowi wykonywać polecenia na Twoim radiu';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Pozwolić $name sterować Twoim radiem?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return 'Kontakt $name będzie mógł zmieniać ustawienia Twojego radia, odczytać hasło WiFi, zmienić nazwę radia oraz je zrestartować lub wyłączyć. Zezwalaj tylko komuś, komu ufasz całkowicie.';
  }

  @override
  String get contact_remoteCliAllow => 'Zezwól';

  @override
  String get connection_secondApp =>
      'Inna aplikacja jest połączona z tym radiem. Wiadomości i ustawienia mogą się pomieszać. Zamknij tę drugą aplikację.';

  @override
  String get wifi_title => 'WiFi';

  @override
  String get wifi_settingsSubtitle => 'Sieć, hasło i połączenie';

  @override
  String get wifi_use => 'Używaj WiFi';

  @override
  String get wifi_networkName => 'Nazwa sieci';

  @override
  String get wifi_password => 'Hasło';

  @override
  String get wifi_passwordUnchanged => 'Bez zmian';

  @override
  String get wifi_showPassword => 'Pokaż hasło';

  @override
  String get wifi_nameMissing => 'Wpisz nazwę sieci';

  @override
  String get wifi_nameTooLong =>
      'Nazwa sieci jest za długa (maksymalnie 32 bajty)';

  @override
  String get wifi_passwordTooLong =>
      'Hasło jest za długie (maksymalnie 63 bajty)';

  @override
  String get wifi_savedRestart =>
      'Zapisano. Zmiany WiFi zadziałają po ponownym uruchomieniu radia.';

  @override
  String get wifi_forget => 'Zapomnij sieć';

  @override
  String get wifi_forgetConfirm =>
      'Zapomnieć tę sieć WiFi? Radio przestanie używać WiFi po ponownym uruchomieniu.';

  @override
  String wifi_notAccepted(String reply) {
    return 'Radio nie przyjęło tego: $reply';
  }

  @override
  String get wifi_noReply => 'Brak odpowiedzi z radia. Spróbuj ponownie.';

  @override
  String get wifi_restartTitle => 'Uruchomić radio ponownie?';

  @override
  String get wifi_later => 'Później';

  @override
  String get wifi_loadFailed => 'Nie udało się odczytać ustawień WiFi z radia.';

  @override
  String wifi_connectedTo(String address) {
    return 'Połączono · $address';
  }

  @override
  String get wifi_notConnected => 'Brak połączenia z WiFi';

  @override
  String wifi_portNote(int port) {
    return 'Aplikacje w tej samej sieci mogą łączyć się na porcie $port';
  }

  @override
  String get wifi_connectOverWifi => 'Połącz przez WiFi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax odłączy się od tego radia i otworzy ekran TCP z wypełnionym adresem $address i portem $port. Stuknij tam \"Połącz\".';
  }

  @override
  String get wifi_noteRestart =>
      'Zmiany zadziałają po ponownym uruchomieniu radia.';

  @override
  String get wifi_noteSecurity =>
      'Każdy w Twojej sieci WiFi może połączyć się z radiem na porcie 5000. Nie ma do tego hasła.';

  @override
  String get wifi_noteBattery =>
      'WiFi nie pozwala radiu zasnąć, więc bateria rozładowuje się szybciej.';

  @override
  String get wifi_noteWrongPassword =>
      'Jeśli hasło jest błędne, radio próbuje ponownie co kilka sekund. Bluetooth nadal działa.';

  @override
  String get room_selfDemoteWarning =>
      'Zmieniasz własny dostęp. Jeśli utracisz rolę administratora, przywrócić ją może tylko konsola pokoju.';

  @override
  String get scanner_offlineMaps => 'Mapy offline';

  @override
  String get appSettings_offlineMaps => 'Mapy offline';

  @override
  String get appSettings_offlineMapsNone => 'Nic nie pobrano';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regionów',
      many: '$count regionów',
      few: '$count regiony',
      one: '$count region',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obszarów map morskich',
      many: '$count obszarów map morskich',
      few: '$count obszary map morskich',
      one: '$count obszar map morskich',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dostępnych $count aktualizacji',
      many: 'Dostępnych $count aktualizacji',
      few: 'Dostępne $count aktualizacje',
      one: 'Dostępna $count aktualizacja',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Pobieraj mapy tylko przez Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Pobieranie map czeka na połączenie Wi‑Fi';

  @override
  String get offlineMaps_title => 'Mapy offline';

  @override
  String get offlineMaps_tabMaps => 'Mapy';

  @override
  String get offlineMaps_tabCharts => 'Mapy morskie';

  @override
  String get offlineMaps_chartsNotice => 'Nie do nawigacji · Dlaczego?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Sugerowane · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Obszary map według wybrzeża';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obszarów',
      many: '$count obszarów',
      few: '$count obszary',
      one: '$count obszar',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Pobrano: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Wybrano: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Zaznacz wszystko';

  @override
  String get offlineMaps_clearSelection => 'Wyczyść';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Także w: $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Jeszcze niedostępne';

  @override
  String get offlineMaps_chartsHint =>
      'Mapy morskie NOAA wybiera się według wybrzeża, na karcie \"Mapy morskie\".';

  @override
  String offlineMaps_chartsName(String area) {
    return 'Mapy morskie NOAA – $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obszarów',
      many: '$count obszarów',
      few: '$count obszary',
      one: '$count obszar',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Pobrane';

  @override
  String get offlineMaps_refresh => 'Sprawdź nowe mapy';

  @override
  String get offlineMaps_loading => 'Wczytywanie dostępnych map…';

  @override
  String get offlineMaps_serverError => 'Brak połączenia z serwerem map';

  @override
  String get offlineMaps_unavailable => 'Brak dostępnych map';

  @override
  String get offlineMaps_unavailableHint => 'Sprawdź ponownie później.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Brak dostępnych map morskich NOAA';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Lista z dnia $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Zaktualizuj MeshTrax, aby pobrać najnowsze mapy.';

  @override
  String get offlineMaps_world => 'Świat';

  @override
  String get offlineMaps_suggested => 'Sugerowane';

  @override
  String get offlineMaps_regions => 'Regiony';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regiony: $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return 'W środku: $count';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size map offline na tym urządzeniu';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Aktualizacje ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Aktualizuj wszystko ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Pobieranie';

  @override
  String get offlineMaps_update => 'Aktualizuj';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Pobrano $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Dostępna aktualizacja';

  @override
  String get offlineMaps_otherFiles => 'Inne pliki map';

  @override
  String get offlineMaps_emptyTitle => 'Brak map offline';

  @override
  String get offlineMaps_emptyBody =>
      'Pobierz region, aby korzystać z mapy bez połączenia.';

  @override
  String get offlineMaps_findMaps => 'Znajdź mapy';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Usunąć $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Zwolni to $size. Możesz go później pobrać ponownie.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return 'Usunięto $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done z $total';
  }

  @override
  String get offlineMaps_kindMap => 'Mapa';

  @override
  String get offlineMaps_kindMapDetail =>
      'Ulice, szlaki i miejsca z OpenStreetMap';

  @override
  String get offlineMaps_kindContours => 'Poziomice';

  @override
  String get offlineMaps_kindContoursDetail => 'Linie wysokości';

  @override
  String get offlineMaps_kindUsgs => 'Mapa topograficzna USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Szlaki, cieki, rezerwaty';

  @override
  String get offlineMaps_kindTerrain => 'Cieniowanie rzeźby';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Wzgórza i góry, cieniowane pod mapą';

  @override
  String get offlineMaps_kindCharts => 'Mapy morskie NOAA';

  @override
  String get offlineMaps_usOnly => 'Tylko Stany Zjednoczone';

  @override
  String offlineMaps_download(String size) {
    return 'Pobierz $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Pobierz';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Duże pobieranie ($size). Użyj Wi‑Fi i podłącz urządzenie do ładowania.';
  }

  @override
  String get offlineMaps_waiting => 'Oczekiwanie…';

  @override
  String get offlineMaps_checking => 'Sprawdzanie pobranego pliku…';

  @override
  String get offlineMaps_retrying => 'Ponawianie…';

  @override
  String offlineMaps_failed(String error) {
    return 'Pobieranie nie powiodło się: $error';
  }

  @override
  String get offlineMaps_pause => 'Wstrzymaj';

  @override
  String get offlineMaps_resume => 'Wznów';

  @override
  String get offlineMaps_deleteRegion => 'Usuń region';

  @override
  String get offlineMaps_notInCatalogue => 'Niedostępne dla tego regionu';

  @override
  String get offlineMaps_notificationRunning => 'Pobieranie mapy';

  @override
  String get offlineMaps_notificationPaused => 'Pobieranie mapy wstrzymane';

  @override
  String get offlineMaps_notificationFailed =>
      'Pobieranie mapy nie powiodło się';

  @override
  String get offlineMaps_clearTileCache =>
      'Wyczyść zapisane kafelki map online';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Usunąć kafelki map online zapisane podczas przeglądania? Pobrane mapy pozostaną.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Usunięto zapisane kafelki map online';

  @override
  String get map_notForNavigation => 'Nie do nawigacji';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax rysuje te mapy z danych NOAA, aby pomóc Ci zobaczyć wodę wokół Twoich radiów i planować. To nie są oficjalne mapy. Nie nawiguj według nich.';

  @override
  String get map_chartsNoticeWhy => 'Dlaczego:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Dezaktualizują się. NOAA stale poprawia swoje mapy; pobrana mapa pozostaje bez zmian, dopóki nie zaktualizujesz jej w \"Mapy offline\".';

  @override
  String get map_chartsNoticeLeftOut =>
      'Pomijają szczegóły. Wiele symboli, sektorów świateł i uwag nie jest rysowanych, a niektóre opisy pojawiają się dopiero po przybliżeniu.';

  @override
  String get map_chartsNoticePositions =>
      'Pozycje mogą być błędne lub nieaktualne. GPS może się mylić o 10 m (30 ft) lub więcej, a węzeł jest tylko tam, gdzie ostatnio się zgłosił.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax nie jest certyfikowanym ploterem nawigacyjnym.';

  @override
  String get map_chartsNoticeUse =>
      'Do nawigacji używaj oficjalnych, aktualnych map NOAA (papierowych lub NOAA ENC w certyfikowanym ploterze) z najnowszymi Wiadomościami Żeglarskimi.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail => 'Pobierz region, by zobaczyć szczegóły';

  @override
  String get map_zoomInForOfflineMap => 'Przybliż, aby zobaczyć mapę offline';

  @override
  String get map_noCharts => 'Brak map morskich w tym miejscu';

  @override
  String get map_myLocation => 'Moja lokalizacja';

  @override
  String get map_zoomIn => 'Przybliż';

  @override
  String get map_zoomOut => 'Oddal';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS włączony';

  @override
  String get gps_off => 'GPS wyłączony';

  @override
  String get gps_onHint => 'Radio aktualizuje swoją pozycję z GPS.';

  @override
  String get gps_offHint =>
      'Wyłączenie oszczędza baterię radia. Po włączeniu ustalenie pozycji może potrwać kilka minut.';

  @override
  String get gps_asking => 'Pytanie radia...';

  @override
  String get gps_noPosition =>
      'Brak pozycji. Na zewnątrz pierwsza może zająć kilka minut.';

  @override
  String get gps_position => 'Pozycja';

  @override
  String get gps_altitude => 'Wysokość';

  @override
  String gps_readAgo(String ago) {
    return 'Odczytano z radia $ago temu';
  }

  @override
  String get gps_turnOnTitle => 'Włączyć GPS?';

  @override
  String get gps_turnOnBody =>
      'GPS radia jest wyłączony. Po włączeniu ustalenie pozycji może potrwać kilka minut.';

  @override
  String get gps_turnOn => 'Włącz';

  @override
  String get gps_notNow => 'Nie teraz';

  @override
  String get map_zoomInForCharts => 'Przybliż, aby zobaczyć mapy morskie';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Pobierz $region · $size';
  }

  @override
  String get mapLayers_title => 'Warstwy mapy';

  @override
  String get mapLayers_mapType => 'Typ mapy';

  @override
  String get mapLayers_standard => 'Standardowa';

  @override
  String get mapLayers_usgs => 'Topograficzna USGS';

  @override
  String get mapLayers_charts => 'Mapy morskie';

  @override
  String get mapLayers_notDownloaded => 'Nie pobrano';

  @override
  String get mapLayers_offlineOnly => 'Tylko offline';

  @override
  String get mapLayers_details => 'Szczegóły mapy';

  @override
  String get mapLayers_contours => 'Poziomice';

  @override
  String get mapLayers_hillShading => 'Cieniowanie rzeźby';

  @override
  String get mapLayers_dark => 'Ciemna mapa';

  @override
  String get mapLayers_downloadedAreas => 'Pobrane obszary';

  @override
  String get mapLayers_nodes => 'Węzły';

  @override
  String get mapLayers_pins => 'Pinezki';

  @override
  String get mapLayers_guessed => 'Przypuszczalne';

  @override
  String get mapLayers_moreFilters => 'Więcej filtrów';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Ostatnio widziane, prefiks klucza, nakładanie się';

  @override
  String get map_legend => 'Legenda';

  @override
  String get scanner_map => 'Mapa';

  @override
  String get structured_openMap => 'Otwórz mapę';

  @override
  String get structured_addToCalendar => 'Dodaj do kalendarza';

  @override
  String get structured_details => 'Szczegóły';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Wydarzenie';

  @override
  String get structured_notice => 'Ogłoszenie';

  @override
  String get structured_allDay => 'Cały dzień';

  @override
  String get structured_calendarFailed => 'Nie udało się otworzyć kalendarza';

  @override
  String get structured_today => 'Dziś';

  @override
  String get structured_tomorrow => 'Jutro';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Za $count dni',
      many: 'Za $count dni',
      few: 'Za $count dni',
      one: 'Za $count dzień',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Minione';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Dzień $day z $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dni',
      many: '$count dni',
      few: '$count dni',
      one: '$count dzień',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Data zakończenia';

  @override
  String get dialog_eventSameDay => 'Ten sam dzień';

  @override
  String get structured_map => 'Mapa';

  @override
  String get structured_navigate => 'Nawiguj';

  @override
  String get structured_channel => 'Kanał';

  @override
  String get structured_contact => 'Kontakt';

  @override
  String get structured_room => 'Pokój';

  @override
  String get structured_repeater => 'Przekaźnik';

  @override
  String get structured_sensor => 'Czujnik';

  @override
  String get structured_joinChannel => 'Dołącz do kanału';

  @override
  String get structured_addContact => 'Dodaj kontakt';

  @override
  String get structured_addRoom => 'Dodaj pokój';

  @override
  String get structured_addRepeater => 'Dodaj przekaźnik';

  @override
  String get structured_addSensor => 'Dodaj czujnik';

  @override
  String get structured_open => 'Otwórz';

  @override
  String get structured_added => 'Dodano';

  @override
  String get tray_add => 'Dodaj';

  @override
  String get tray_myLocation => 'Moja lokalizacja';

  @override
  String get tray_pointOnMap => 'Punkt na mapie';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Wydarzenie';

  @override
  String get tray_notice => 'Ogłoszenie';

  @override
  String get tray_noRadioPosition =>
      'Twoje radio nie ma jeszcze pozycji. Wybierz ją na mapie.';

  @override
  String get dialog_insert => 'Wstaw';

  @override
  String get dialog_eventTitle => 'Tytuł';

  @override
  String get dialog_eventDate => 'Data';

  @override
  String get dialog_eventStart => 'Początek';

  @override
  String get dialog_eventEnd => 'Koniec';

  @override
  String get dialog_eventNoEnd => 'Bez godziny zakończenia';

  @override
  String get dialog_eventPlace => 'Miejsce (opcjonalnie)';

  @override
  String get dialog_pickOnMap => 'Wybierz na mapie';

  @override
  String get dialog_sosTitle => 'Wyślij SOS';

  @override
  String get dialog_sosText => 'Co się stało?';

  @override
  String get dialog_noticeTitle => 'Ogłoszenie';

  @override
  String get dialog_noticeText => 'Co wszyscy powinni wiedzieć?';

  @override
  String get dialog_labelTitle => 'Punkt na mapie';

  @override
  String get dialog_note => 'Notatka (opcjonalnie)';

  @override
  String get paste_convertLocation =>
      'To wygląda na link do map. Zamienić na lokalizację?';

  @override
  String get paste_convertEvent =>
      'To wygląda na wydarzenie udostępnione z kalendarza. Zamienić na wydarzenie?';

  @override
  String get paste_convert => 'Zamień';

  @override
  String get paste_resolving => 'Rozwijanie linku…';

  @override
  String get paste_resolveFailed => 'Nie udało się rozwinąć linku';

  @override
  String get pinned_dismiss => 'Zamknij';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Dołączyć do kanału $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Jesteś już w $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Dołączono do $name';
  }

  @override
  String get map_pickPositionHint => 'Stuknij mapę, aby wybrać pozycję';

  @override
  String get map_legendMesh => 'Sieć mesh';

  @override
  String get chartLegend_title => 'Symbole map morskich';

  @override
  String get chartLegend_sectionBuoys => 'Pławy i stawy';

  @override
  String get chartLegend_sectionLights => 'Światła';

  @override
  String get chartLegend_sectionHazards => 'Niebezpieczeństwa';

  @override
  String get chartLegend_sectionTides => 'Pływy i prądy';

  @override
  String get chartLegend_sectionDepths => 'Głębokości i dno';

  @override
  String get chartLegend_sectionAreas => 'Obszary, tory i linie';

  @override
  String get chartLegend_sectionLandmarks => 'Obiekty orientacyjne';

  @override
  String get chartLegend_sectionAbbreviations => 'Skróty';

  @override
  String get chartLegend_chartNo1 => 'Wszystkie symbole: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Zielona pława walcowa';

  @override
  String get chartLegend_portBuoyHint =>
      'Zostaw ją po lewej, wchodząc od morza';

  @override
  String get chartLegend_starboardBuoy => 'Czerwona pława stożkowa';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Zostaw ją po prawej, wchodząc: czerwona po prawej, gdy wracasz z morza';

  @override
  String get chartLegend_junctionBuoy => 'Pława w poziome pasy';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Rozwidlenie toru: traktuj ją jak kolor jej górnego pasa';

  @override
  String get chartLegend_safeWaterBuoy => 'Pasy czerwono-białe';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Bezpieczna woda dookoła, często u wejścia do toru';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Pasy czarno-czerwone';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Małe niebezpieczeństwo z bezpieczną wodą wokół: trzymaj się z dala';

  @override
  String get chartLegend_specialBuoy => 'Żółta pława';

  @override
  String get chartLegend_specialBuoyHint =>
      'Znak specjalny, nie do prowadzenia nawigacji: kotwicowisko, kabel, badania';

  @override
  String get chartLegend_cardinalBuoy => 'Czarno-żółta';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Znak kardynalny: mijaj go od strony, którą wskazuje jego nazwa (rzadki w USA)';

  @override
  String get chartLegend_mooringBuoy => 'Pława cumownicza';

  @override
  String get chartLegend_portBeacon => 'Zielona stawa kwadratowa';

  @override
  String get chartLegend_portBeaconHint =>
      'Jak zielona pława: zostaw ją po lewej, wchodząc';

  @override
  String get chartLegend_starboardBeacon => 'Czerwona stawa trójkątna';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Jak czerwona pława: zostaw ją po prawej, wchodząc';

  @override
  String get chartLegend_otherBeacon => 'Stawa rombowa';

  @override
  String get chartLegend_otherBeaconHint =>
      'Informacja lub ostrzeżenie, nie strona toru';

  @override
  String get chartLegend_beaconTower => 'Wieża świetlna lub konstrukcja stawy';

  @override
  String get chartLegend_topmark => 'Znak szczytowy';

  @override
  String get chartLegend_topmarkHint =>
      'Kształt na szczycie znaku uzupełnia jego znaczenie';

  @override
  String get chartLegend_light => 'Światło';

  @override
  String get chartLegend_lightHint =>
      'Purpurowy rozbłysk oznacza światło; jego opis mówi, jak błyska';

  @override
  String get chartLegend_lightExample => 'Błyskowe zielone, co 4 sekundy';

  @override
  String get chartLegend_lightExampleHint =>
      'Opis światła: rytm, kolor, potem okres';

  @override
  String get chartLegend_lightFixed => 'Stałe';

  @override
  String get chartLegend_lightFixedHint => 'Światło ciągłe';

  @override
  String get chartLegend_lightFlashing => 'Błyskowe';

  @override
  String get chartLegend_lightFlashingHint =>
      'Krótkie błyski, dłuższa ciemność pomiędzy';

  @override
  String get chartLegend_lightGroup => 'Grupowe błyskowe';

  @override
  String get chartLegend_lightGroupHint =>
      'Błyski w grupach, tu po 2, potem ciemność';

  @override
  String get chartLegend_lightComposite => 'Złożone grupowe';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 błyski, potem 1: oznacza rozwidlenie toru';

  @override
  String get chartLegend_lightQuick => 'Szybkobłyskowe';

  @override
  String get chartLegend_lightQuickHint => 'Około jednego błysku na sekundę';

  @override
  String get chartLegend_lightIsophase => 'Izofazowe';

  @override
  String get chartLegend_lightIsophaseHint => 'Tyle samo światła co ciemności';

  @override
  String get chartLegend_lightOcculting => 'Przerywane';

  @override
  String get chartLegend_lightOccultingHint => 'Świeci dłużej, niż jest ciemne';

  @override
  String get chartLegend_lightMorse => 'Alfabet Morse\'a A';

  @override
  String get chartLegend_lightMorseHint => 'Krótki, długi: bezpieczna woda';

  @override
  String get chartLegend_lightAlternating => 'Zmienne';

  @override
  String get chartLegend_lightAlternatingHint => 'Zmienia kolor';

  @override
  String get chartLegend_lightColours => 'Białe, czerwone, zielone, żółte';

  @override
  String get chartLegend_lightPeriod => 'Okres';

  @override
  String get chartLegend_lightPeriodHint => 'Sekundy na jeden pełny cykl';

  @override
  String get chartLegend_rock => 'Skała podwodna';

  @override
  String get chartLegend_rockHint => 'Zawsze pod wodą, ale może być płytko';

  @override
  String get chartLegend_rockAwash => 'Skała na poziomie wody';

  @override
  String get chartLegend_rockAwashHint =>
      'Tuż przy powierzchni przy niskiej wodzie';

  @override
  String get chartLegend_rockCovers => 'Skała odsłaniająca się';

  @override
  String get chartLegend_rockCoversHint =>
      'Widoczna przy odpływie, zakryta przy przypływie';

  @override
  String get chartLegend_wreckDangerous => 'Niebezpieczny wrak';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Na tyle płytko, że można w niego uderzyć';

  @override
  String get chartLegend_wreck => 'Wrak';

  @override
  String get chartLegend_wreckHint =>
      'Na tyle głęboko, że łodzie przepłyną nad nim; nie kotwicz';

  @override
  String get chartLegend_wreckShowing => 'Wrak wystający';

  @override
  String get chartLegend_wreckShowingHint => 'Część wystaje nad wodę';

  @override
  String get chartLegend_obstruction => 'Przeszkoda';

  @override
  String get chartLegend_obstructionHint =>
      'Coś na dnie; głębokość, jeśli jest znana';

  @override
  String get chartLegend_foulGround => 'Nieczyste dno';

  @override
  String get chartLegend_foulGroundHint =>
      'Można nad nim przepłynąć, ale nie kotwicz ani nie trałuj';

  @override
  String get chartLegend_hazardArea => 'Granica obszaru niebezpiecznego';

  @override
  String get chartLegend_hazardAreaHint =>
      'W środku skały, wraki lub przeszkody';

  @override
  String get chartLegend_pile => 'Pal lub słupek';

  @override
  String get chartLegend_floodStream => 'Prąd przypływu';

  @override
  String get chartLegend_floodStreamHint => 'Prąd pływowy, gdy woda przybiera';

  @override
  String get chartLegend_ebbStream => 'Prąd odpływu';

  @override
  String get chartLegend_ebbStreamHint => 'Prąd pływowy, gdy woda opada';

  @override
  String get chartLegend_current => 'Prąd';

  @override
  String get chartLegend_currentHint =>
      'Płynie w tę samą stronę niezależnie od pływu';

  @override
  String get chartLegend_rips => 'Sulój lub wiry';

  @override
  String get chartLegend_ripsHint => 'Wzburzona, wirująca woda';

  @override
  String get chartLegend_breakers => 'Przybój';

  @override
  String get chartLegend_breakersHint => 'Fale łamiące się na płyciznach';

  @override
  String get chartLegend_sounding => 'Głębokość';

  @override
  String get chartLegend_soundingHint =>
      'Głębokość przy średniej niskiej wodzie';

  @override
  String get chartLegend_depthContour => 'Izobata';

  @override
  String get chartLegend_depthContourHint => 'Jej opis podaje głębokość';

  @override
  String get chartLegend_drying => 'Osycha przy odpływie';

  @override
  String get chartLegend_dredged => 'Tor pogłębiany';

  @override
  String get chartLegend_dredgedHint => 'Utrzymywany na podanej głębokości';

  @override
  String get chartLegend_swept => 'Obszar wytrałowany';

  @override
  String get chartLegend_sweptHint =>
      'Sprawdzony jako wolny do podanej głębokości';

  @override
  String get chartLegend_unsurveyed => 'Niezbadane';

  @override
  String get chartLegend_unsurveyedHint => 'Głębokości nie zmierzono';

  @override
  String get chartLegend_weed => 'Wodorosty';

  @override
  String get chartLegend_restricted => 'Obszar zastrzeżony';

  @override
  String get chartLegend_restrictedHint =>
      'Wejście ograniczone; ząbki wskazują do środka';

  @override
  String get chartLegend_regulatedLimit => 'Granica obszaru regulowanego';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Kotwicowisko, obszar kablowy, strzelnica i inne: zobacz opis';

  @override
  String get chartLegend_greyLimit => 'Klapowisko, łowisko lub hodowla';

  @override
  String get chartLegend_anchorage => 'Kotwicowisko';

  @override
  String get chartLegend_anchorBerth => 'Stanowisko kotwiczne';

  @override
  String get chartLegend_noAnchoring => 'Zakaz kotwiczenia';

  @override
  String get chartLegend_caution => 'Obszar ostrzegawczy';

  @override
  String get chartLegend_cautionHint => 'Zachowaj tu szczególną ostrożność';

  @override
  String get chartLegend_trafficLane => 'Tor ruchu';

  @override
  String get chartLegend_trafficLaneHint =>
      'Duże statki, w jedną stronę: przecinaj pod kątem prostym';

  @override
  String get chartLegend_separationZone => 'Strefa rozgraniczenia';

  @override
  String get chartLegend_separationZoneHint =>
      'Między torami ruchu: nie wpływaj';

  @override
  String get chartLegend_precautionary => 'Rejon szczególnej ostrożności';

  @override
  String get chartLegend_precautionaryHint => 'Statki się zbiegają: uważaj';

  @override
  String get chartLegend_fairway => 'Tor wodny';

  @override
  String get chartLegend_fairwayHint => 'Główny tor';

  @override
  String get chartLegend_track => 'Zalecana trasa';

  @override
  String get chartLegend_ferry => 'Trasa promu';

  @override
  String get chartLegend_leadingLine => 'Nabieżnik';

  @override
  String get chartLegend_leadingLineHint =>
      'Ustaw jego dwa znaki w jednej linii, aby pozostać w torze';

  @override
  String get chartLegend_cable => 'Kabel podmorski';

  @override
  String get chartLegend_cableHint => 'Nie kotwicz';

  @override
  String get chartLegend_pipeline => 'Rurociąg podmorski';

  @override
  String get chartLegend_pipelineHint => 'Nie kotwicz';

  @override
  String get chartLegend_overhead => 'Kabel napowietrzny';

  @override
  String get chartLegend_overheadHint => 'Jego prześwit jest oznaczony VC';

  @override
  String get chartLegend_tower => 'Wieża';

  @override
  String get chartLegend_windTurbine => 'Turbina wiatrowa';

  @override
  String get chartLegend_chimney => 'Komin';

  @override
  String get chartLegend_mast => 'Maszt lub antena';

  @override
  String get chartLegend_church => 'Kościół lub iglica';

  @override
  String get chartLegend_flagstaff => 'Maszt flagowy';

  @override
  String get chartLegend_dome => 'Kopuła';

  @override
  String get chartLegend_landmark => 'Inny obiekt orientacyjny';

  @override
  String get chartLegend_abbrAnch => 'Kotwicowisko';

  @override
  String get chartLegend_abbrWk => 'Wrak';

  @override
  String get chartLegend_abbrBr => 'Przybój';

  @override
  String get chartLegend_abbrWd => 'Wodorosty';

  @override
  String get chartLegend_abbrVar => 'Deklinacja magnetyczna';

  @override
  String get chartLegend_abbrVc => 'Prześwit pionowy pod mostem lub kablem';

  @override
  String get chartLegend_abbrTr => 'Wieża';

  @override
  String get chartLegend_abbrCh => 'Kościół';

  @override
  String get chartLegend_abbrChy => 'Komin';

  @override
  String get chartLegend_abbrFs => 'Maszt flagowy';

  @override
  String get chartLegend_abbrTk => 'Zbiornik';

  @override
  String get chartLegend_abbrRBn => 'Radiolatarnia';

  @override
  String get chartLegend_abbrCg => 'Stacja Straży Przybrzeżnej';

  @override
  String get chartLegend_abbrRacon =>
      'Radarowy znak odzewowy: widoczny na radarze';

  @override
  String get chartLegend_abbrFog =>
      'Sygnał mgłowy: tyfon, dzwon, gong, gwizd lub syrena';

  @override
  String get chartLegend_abbrVAis => 'Znak wirtualny: widoczny tylko w AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'od $from do $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Głębiej niż $depth';
  }

  @override
  String get parkLegend_title => 'Symbole parków i szlaków';

  @override
  String get parkLegend_campsite => 'Pole namiotowe';

  @override
  String get parkLegend_picnicSite => 'Miejsce na piknik';

  @override
  String get parkLegend_shelter => 'Wiata';

  @override
  String get parkLegend_toilets => 'Toalety';

  @override
  String get parkLegend_drinkingWater => 'Woda pitna';

  @override
  String get parkLegend_parking => 'Parking';

  @override
  String get parkLegend_viewpoint => 'Punkt widokowy';

  @override
  String get parkLegend_attraction => 'Atrakcja';

  @override
  String get parkLegend_gate => 'Brama';

  @override
  String get parkLegend_telephone => 'Telefon';

  @override
  String get parkLegend_information => 'Tablica informacyjna';

  @override
  String get parkLegend_guidepost => 'Drogowskaz';

  @override
  String get dialog_noticeExpires => 'Wygasa';

  @override
  String get dialog_noticeNoExpiry => 'Nigdy';

  @override
  String get dialog_noticeExpiryRequired => 'Wybierz datę (wymagane w pokoju)';

  @override
  String get dialog_noticeExpiryTime => 'Godzina';

  @override
  String get dialog_noticeEndOfDay => 'Koniec dnia';

  @override
  String structured_until(String when) {
    return 'Do $when';
  }

  @override
  String get structured_expired => 'Wygasło';

  @override
  String get structured_announcement => 'Komunikat';

  @override
  String structured_locationOf(String name) {
    return 'Lokalizacja: $name';
  }

  @override
  String get reaction_searchHint => 'Szukaj emoji';

  @override
  String get reaction_noResults => 'Nie znaleziono emoji';

  @override
  String get share_qrAndLink => 'Udostępnij kod QR i link';

  @override
  String get share_roomTitle => 'Udostępnij pokój';

  @override
  String get share_contactTitle => 'Udostępnij kontakt';

  @override
  String get share_roomInstructions =>
      'Zeskanuj kod QR, aby dodać ten pokój. Do zalogowania potrzebne będzie jego hasło.';

  @override
  String get share_contactInstructions =>
      'Zeskanuj kod QR, aby dodać ten kontakt.';

  @override
  String get clearChat_body =>
      'Usuń wiadomości tego czatu z tego urządzenia. Nowe wiadomości nadal będą tu przychodzić.';

  @override
  String get clearChat_olderThanDay => 'Starsze niż 1 dzień';

  @override
  String get clearChat_olderThanWeek => 'Starsze niż 1 tydzień';

  @override
  String get clearChat_olderThanMonth => 'Starsze niż 1 miesiąc';

  @override
  String get clearChat_everything => 'Wszystkie wiadomości';

  @override
  String get chats_markAllRead => 'Oznacz wszystkie jako przeczytane';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Oznaczyć $count czatów jako przeczytane?',
      many: 'Oznaczyć $count czatów jako przeczytane?',
      few: 'Oznaczyć $count czaty jako przeczytane?',
      one: 'Oznaczyć $count czat jako przeczytany?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Oznacz';

  @override
  String get chats_nothingUnread => 'Brak nieprzeczytanych wiadomości';

  @override
  String get chats_draft => 'Szkic';

  @override
  String get contact_teleBlockedTitle => 'Zablokowane przez Twoje radio';

  @override
  String contact_teleBlockedBody(String name) {
    return 'Ustawienia prywatności Twojego radia nie udostępniają tego nikomu, więc $name tego nie otrzyma. Zmienić je, aby otrzymywały to kontakty, którym pozwolisz?';
  }

  @override
  String get contact_teleNotNow => 'Nie teraz';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'Twoje radio nie udostępnia tego nikomu ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'Twoje radio udostępnia to wszystkim ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Może pobrać Twoją lokalizację';

  @override
  String get pathfinder_meshTitle => 'Inna sieć?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '$unknown z $heard przekaźników usłyszanych od połączenia jest nowych dla mapy Pathfindera „$graph”. Zacząć nową mapę dla tego obszaru? Stara zostaje i możesz do niej wrócić na ekranie Pathfindera.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'Większość przekaźników usłyszanych od połączenia jest na mapie Pathfindera „$other”, a nie „$graph”. Przełączyć na nią?';
  }

  @override
  String get pathfinder_meshNew => 'Nowa mapa';

  @override
  String get pathfinder_meshSwitch => 'Przełącz';

  @override
  String get pathfinder_meshKeep => 'Zostaw tę';

  @override
  String get pathfinder_graphNameTitle => 'Nazwa nowej mapy';

  @override
  String get pathfinder_graphNameHint => 'Na przykład Waszyngton';

  @override
  String get pathfinder_graphCreate => 'Utwórz';

  @override
  String get locationSharing_title => 'Kto widzi moją lokalizację';

  @override
  String get locationSharing_someone => 'Ktoś może zobaczyć Twoją lokalizację';

  @override
  String get locationSharing_nobody => 'Nikt nie widzi Twojej lokalizacji';

  @override
  String get locationSharing_noPosition =>
      'Twoje radio nie ma jeszcze lokalizacji, więc nikt jej nie widzi';

  @override
  String get locationSharing_everyone =>
      'Każdy, kto słyszy Twoje radio, widzi Twoją lokalizację';

  @override
  String get locationSharing_allContacts =>
      'Wszystkie Twoje kontakty widzą Twoją lokalizację';

  @override
  String get locationSharing_someContacts =>
      'Dozwolone kontakty widzą Twoją lokalizację';

  @override
  String get locationSharing_adverts => 'Lokalizacja w ogłoszeniach';

  @override
  String get locationSharing_advertsHint =>
      'Twoje ogłoszenia zawierają Twoją lokalizację, więc widzi ją każdy, kto słyszy Twoje radio.';

  @override
  String get locationSharing_contactsHeader =>
      'Kontakty, które mogą odpytywać Twoje radio';

  @override
  String get locationSharing_noTelemetry =>
      'Brak. Twoje radio nie odpowiada na żądania telemetrii.';

  @override
  String get locationSharing_noContacts => 'Żaden kontakt nie ma pozwolenia.';

  @override
  String locationSharing_allContactsRow(int count) {
    return 'Wszystkie Twoje kontakty ($count)';
  }

  @override
  String get locationSharing_partLocation => 'Lokalizacja';

  @override
  String get locationSharing_partBattery => 'Bateria';

  @override
  String get locationSharing_partSensors => 'Czujniki';

  @override
  String get dialog_positionHint => 'Wklej współrzędne lub link do mapy';

  @override
  String get dialog_positionUnreadable => 'Nie można tu odczytać pozycji';

  @override
  String get dialog_positionLookingUp => 'Sprawdzanie linku…';

  @override
  String get locationSharing_share => 'Udostępniaj moją lokalizację';

  @override
  String get locationSharing_shareOnHint =>
      'Wyłącz, aby ukryć ją przed wszystkimi';

  @override
  String get locationSharing_shareOffHint =>
      'Włącz, aby widziały ją kontakty z pozwoleniem';

  @override
  String get chats_advertise => 'Ogłoszenie';
}
