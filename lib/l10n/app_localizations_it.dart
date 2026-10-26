// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Chat';

  @override
  String get chats_title => 'Chat';

  @override
  String get newChat_title => 'Seleziona contatto';

  @override
  String newChat_contactCount(int count) {
    return '$count contatti';
  }

  @override
  String get newChat_newContact => 'Nuovo contatto';

  @override
  String get newChat_newChannel => 'Nuovo canale';

  @override
  String get newChat_myContacts => 'I miei contatti';

  @override
  String get newChat_discovered => 'Scoperti';

  @override
  String get repeaters_title => 'Gestisci ripetitori';

  @override
  String get nav_contacts => 'Contatti';

  @override
  String get nav_channels => 'Canali';

  @override
  String get nav_map => 'Mappa';

  @override
  String get common_cancel => 'Annulla';

  @override
  String get common_syncing_device_info => 'Lettura info dispositivo...';

  @override
  String get common_syncing_contacts => 'Lettura contatti...';

  @override
  String get common_syncing_channels => 'Lettura canali...';

  @override
  String get common_syncing_messages => 'Lettura messaggi...';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Connetti';

  @override
  String get common_unknownDevice => 'Dispositivo sconosciuto';

  @override
  String get common_save => 'Salva';

  @override
  String get common_delete => 'Elimina';

  @override
  String get common_deleteAll => 'Elimina tutto';

  @override
  String get common_close => 'Chiudi';

  @override
  String get common_edit => 'Modifica';

  @override
  String get common_add => 'Aggiungi';

  @override
  String get common_settings => 'Impostazioni';

  @override
  String get common_disconnect => 'Disconnetti';

  @override
  String get common_connected => 'Connesso';

  @override
  String get common_disconnected => 'Disconnesso';

  @override
  String get common_connectionLost => 'Connessione persa. Riconnessione...';

  @override
  String get common_reconnecting => 'Riconnessione...';

  @override
  String get common_create => 'Crea';

  @override
  String get common_continue => 'Continua';

  @override
  String get common_share => 'Condividi';

  @override
  String get common_copy => 'Copia';

  @override
  String get common_retry => 'Riprova';

  @override
  String get common_hide => 'Nascondi';

  @override
  String get common_remove => 'Elimina';

  @override
  String get common_enable => 'Abilita';

  @override
  String get common_disable => 'Disattivare';

  @override
  String get common_reboot => 'Riavvia';

  @override
  String get common_loading => 'Caricamento...';

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
  String get tcpScreenTitle => 'Stabilire una connessione tramite TCP';

  @override
  String get tcpHostLabel => 'Indirizzo IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Porta';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Inserisci l\'endpoint e connettiti.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Connessione a $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'È necessario fornire un indirizzo IP.';

  @override
  String get tcpErrorPortInvalid =>
      'La dimensione della porta deve essere compresa tra 1 e 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Il protocollo TCP non è supportato su questa piattaforma.';

  @override
  String get tcpErrorTimedOut => 'La connessione TCP è scaduta.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Impossibile stabilire la connessione TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Connessione tramite USB';

  @override
  String get usbScreenSubtitle =>
      'Seleziona il dispositivo seriale rilevato e connettilo direttamente al tuo nodo MeshCore.';

  @override
  String get usbScreenStatus => 'Seleziona un dispositivo USB';

  @override
  String get usbScreenNote =>
      'La comunicazione seriale USB è attiva sui dispositivi Android supportati e sulle piattaforme desktop.';

  @override
  String get usbScreenEmptyState =>
      'Nessun dispositivo USB rilevato. Collegare uno e aggiornare.';

  @override
  String get usbErrorPermissionDenied =>
      'È stato negato l\'accesso tramite USB.';

  @override
  String get usbErrorDeviceMissing =>
      'Il dispositivo USB selezionato non è più disponibile.';

  @override
  String get usbErrorInvalidPort => 'Seleziona un dispositivo USB valido.';

  @override
  String get usbErrorBusy =>
      'Un\'altra richiesta di connessione tramite USB è già in corso.';

  @override
  String get usbErrorNotConnected => 'Non è collegato alcun dispositivo USB.';

  @override
  String get usbErrorOpenFailed =>
      'Impossibile aprire il dispositivo USB selezionato.';

  @override
  String get usbErrorConnectFailed =>
      'Impossibile connettersi al dispositivo USB selezionato.';

  @override
  String get usbErrorUnsupported =>
      'La comunicazione seriale tramite USB non è supportata su questa piattaforma.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'In questa versione manca la libreria seriale USB, quindi i dispositivi USB non possono essere aperti. Reinstalla MeshTrax o segnala questa versione come difettosa.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Questo browser non supporta Web Serial. Usa Chrome o Edge su HTTPS (o localhost).';

  @override
  String get usbErrorAlreadyActive => 'La connessione USB è già attiva.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Non è stato selezionato alcun dispositivo USB.';

  @override
  String get usbErrorPortClosed => 'La connessione USB non è attiva.';

  @override
  String get usbErrorConnectTimedOut =>
      'La connessione è scaduta. Assicurarsi che il dispositivo abbia il firmware USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Dispositivo per comunicazione seriale su rete';

  @override
  String get usbStatus_notConnected => 'Seleziona un dispositivo USB';

  @override
  String get usbStatus_connecting => 'Connessione al dispositivo USB...';

  @override
  String get usbStatus_searching => 'Ricerca di dispositivi USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Errore nella connessione USB: $error';
  }

  @override
  String get scanner_scanning => 'Scansione in corso per i dispositivi...';

  @override
  String get scanner_connecting => 'Connessione...';

  @override
  String get scanner_disconnecting => 'Disconnessione...';

  @override
  String get scanner_notConnected => 'Non connesso';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Connesso a $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Mostra tutti i dispositivi Bluetooth';

  @override
  String get scanner_showMeshCoreOnly => 'Mostra solo radio MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'La radio non risponde. Potrebbe essere necessario associarla: apri le impostazioni Bluetooth, aggiungi la radio e inserisci il suo PIN, poi riprova.';

  @override
  String get scanner_pairingFailed =>
      'L\'associazione Bluetooth è stata annullata o non è riuscita. Assicurati che nient\'altro (come il tuo telefono) sia connesso alla radio, poi riprova e inserisci il suo PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Connessione fallita: $error';
  }

  @override
  String get scanner_stop => 'Interrompere';

  @override
  String get scanner_scan => 'Scansiona';

  @override
  String get scanner_scanFromImage => 'Scansiona da immagine';

  @override
  String get scanner_noQrFoundInImage =>
      'Nessun codice QR valido trovato nell\'immagine';

  @override
  String get scanner_bluetoothOff => 'Il Bluetooth è disattivato.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Si prega di attivare il Bluetooth per effettuare la scansione dei dispositivi.';

  @override
  String get scanner_chromeRequired => 'Browser Chrome richiesto';

  @override
  String get scanner_chromeRequiredMessage =>
      'Questa applicazione web richiede Google Chrome o un browser basato su Chromium per il supporto Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Abilita il Bluetooth';

  @override
  String get device_quickSwitch => 'Passa velocemente';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Impostazioni';

  @override
  String get settings_deviceInfo => 'Informazioni Dispositivo';

  @override
  String get settings_appSettings => 'Impostazioni App';

  @override
  String get settings_appSettingsSubtitle =>
      'Notifiche, messaggi e preferenze della mappa';

  @override
  String get settings_nodeSettings => 'Impostazioni Nodo';

  @override
  String get settings_nodeName => 'Nome Nodo';

  @override
  String get settings_nodeNameNotSet => 'Non impostato';

  @override
  String get settings_nodeNameHint => 'Inserisci nome nodo';

  @override
  String get settings_nodeNameUpdated => 'Nome aggiornato';

  @override
  String get settings_radioSettings => 'Impostazioni Radio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequenza, potenza, fattore di dispersione';

  @override
  String get settings_radioSettingsUpdated => 'Impostazioni radio aggiornate';

  @override
  String get settings_location => 'Posizione';

  @override
  String get settings_locationSubtitle => 'coordinate GPS';

  @override
  String get settings_locationUpdated => 'Posizione aggiornata';

  @override
  String get settings_locationBothRequired =>
      'Inserire sia la latitudine che la longitudine.';

  @override
  String get settings_locationInvalid => 'Latitudine o longitudine non valida.';

  @override
  String get settings_locationGPSEnable => 'Abilita GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Abilita l\'aggiornamento automatico della posizione tramite GPS.';

  @override
  String get settings_latitude => 'Latitudine';

  @override
  String get settings_longitude => 'Longitudine';

  @override
  String get settings_contactSettings => 'Impostazioni di contatto';

  @override
  String get settings_contactSettingsSubtitle =>
      'Impostazioni per l\'aggiunta dei contatti';

  @override
  String get settings_privacyMode => 'Modalità Privacy';

  @override
  String get settings_privacyModeSubtitle =>
      'Nascondere nome/luogo negli annunci';

  @override
  String get settings_privacyModeToggle =>
      'Attiva la modalità privacy per nascondere il tuo nome e la tua posizione negli annunci.';

  @override
  String get settings_privacyModeEnabled => 'Modalità privacy abilitata';

  @override
  String get settings_privacyModeDisabled => 'Modalità privacy disabilitata';

  @override
  String get settings_privacy => 'Impostazioni sulla privacy';

  @override
  String get settings_privacySubtitle =>
      'Controlla le informazioni che vengono condivise.';

  @override
  String get settings_privacySettingsDescription =>
      'Scegli le informazioni che il tuo dispositivo condivide con gli altri.';

  @override
  String get settings_denyAll => 'Negare tutto';

  @override
  String get settings_allowByContact => 'Consenti in base ai flag di contatto';

  @override
  String get settings_allowAll => 'Consenti tutto';

  @override
  String get settings_telemetryBaseMode => 'Modalità di base di telemetria';

  @override
  String get settings_telemetryLocationMode =>
      'Modalità di posizionamento telemetrico';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Modalità di ambiente di telemetria';

  @override
  String get settings_advertLocation => 'Posizione dell\'annuncio';

  @override
  String get settings_advertLocationSubtitle =>
      'Includi la posizione nell\'annuncio';

  @override
  String get settings_multiAck => 'ACK multipli';

  @override
  String get settings_telemetryModeUpdated => 'Modalità telemetria aggiornata';

  @override
  String get settings_actions => 'Azioni';

  @override
  String get settings_sendAdvertisement => 'Invia Annuncio';

  @override
  String get settings_sendAdvertisementSubtitle => 'Presenza trasmessa ora';

  @override
  String get settings_advertisementSent => 'Annuncio inviato';

  @override
  String get settings_syncTime => 'Tempo di sincronizzazione';

  @override
  String get settings_syncTimeSubtitle =>
      'Imposta l\'orologio del dispositivo sull\'ora del telefono';

  @override
  String get settings_timeSynchronized => 'Sincronizzato nel tempo';

  @override
  String get settings_refreshContacts => 'Aggiorna Contatti';

  @override
  String get settings_refreshContactsSubtitle =>
      'Ricaricare l\'elenco dei contatti dal dispositivo';

  @override
  String get settings_rebootDevice => 'Riavvia Dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Riavviare il dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Sei sicuro di voler riavviare il dispositivo? Sarai disconnesso.';

  @override
  String get settings_debug => 'Risoluzione dei problemi';

  @override
  String get settings_bleDebugLog => 'Log di Debug BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Comandi, risposte e dati grezzi BLE';

  @override
  String get settings_appDebugLog => 'Log di Debug dell\'App';

  @override
  String get settings_appDebugLogSubtitle =>
      'Messaggi di debug dell\'applicazione';

  @override
  String get settings_exportDatabase => 'Esporta database dei messaggi';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Una copia di tutte le chat e i contatti, per il debug. Tienila privata.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Database salvato in: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Esportazione non riuscita: $error';
  }

  @override
  String get settings_about => 'Informazioni';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'Progetto Open Source MeshCore 2024';

  @override
  String get settings_aboutDescription =>
      'Un client Flutter open-source per i dispositivi di rete mesh LoRa Core di MeshCore.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Dati di elevazione LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nome';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Stato';

  @override
  String get settings_infoBattery => 'Batteria';

  @override
  String get settings_infoPublicKey => 'Chiave Pubblica';

  @override
  String get settings_infoContactsCount => 'Numero contatti';

  @override
  String get settings_infoChannelCount => 'Numero Canale';

  @override
  String get settings_presets => 'Preset';

  @override
  String get settings_frequency => 'Frequenza (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Frequenza non valida (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Larghezza di banda';

  @override
  String get settings_spreadingFactor => 'Fattore di Spettro';

  @override
  String get settings_codingRate => 'Tasso di Codifica';

  @override
  String get settings_txPower => 'TX Potenza (dBm)';

  @override
  String get settings_txPowerInvalid => 'Potere TX non valido';

  @override
  String get settings_clientRepeat => 'Ripetizione \"fuori dalla rete\"';

  @override
  String get settings_clientRepeatSubtitle =>
      'Permetti a questo dispositivo di ripetere i pacchetti di rete per gli altri.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Per la comunicazione fuori rete, è necessario utilizzare frequenze di 433, 869 o 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Errore: $message';
  }

  @override
  String get appSettings_title => 'Impostazioni App';

  @override
  String get appSettings_appearance => 'Aspetto';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Impostazione predefinita del sistema';

  @override
  String get appSettings_themeLight => 'Luce';

  @override
  String get appSettings_themeDark => 'Scuro';

  @override
  String get appSettings_language => 'Lingua';

  @override
  String get appSettings_languageSystem => 'Predefinito di sistema';

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
  String get appSettings_languageRu => 'Russo';

  @override
  String get appSettings_languageUk => 'Ucraino';

  @override
  String get appSettings_enableMessageTracing =>
      'Abilita tracciamento messaggi';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostra metadati dettagliati su instradamento e tempi per i messaggi';

  @override
  String get appSettings_senderNameColors => 'Nomi mittente colorati';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Dà a ogni mittente del canale un colore del nome tutto suo. Se disattivato, tutti usano il colore del tema.';

  @override
  String get appSettings_showTextFormatting => 'Mostra formattazione del testo';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown nei messaggi: **grassetto**, *corsivo*, ||testo nascosto||, titoli e link. Le altre app MeshCore mostrano i caratteri grezzi.';

  @override
  String get appSettings_notifications => 'Notifiche';

  @override
  String get appSettings_enableNotifications => 'Abilita Notifiche';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Ricevi notifiche per messaggi e annunci';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permesso di notifica negato';

  @override
  String get appSettings_notificationsEnabled => 'Notifiche abilitate';

  @override
  String get appSettings_notificationsDisabled => 'Notifiche disattivate';

  @override
  String get appSettings_messageNotifications => 'Notifiche Messaggi';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostra notifica all\'arrivo di nuovi messaggi';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notifiche Messaggi Canale';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostra notifica all\'arrivo di messaggi nel canale';

  @override
  String get appSettings_advertisementNotifications =>
      'Notifiche Pubblicitarie';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostra notifica quando vengono scoperti nuovi nodi';

  @override
  String get appSettings_messaging => 'Messaggi';

  @override
  String get appSettings_maxMessageRetries =>
      'Numero massimo di tentativi di invio del messaggio';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Numero di tentativi di riprova prima di considerare un messaggio come fallito.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Tentativi massimi messaggi canale';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Riproverà fino a questo numero di volte finché non sente almeno una ripetizione';

  @override
  String get appSettings_battery => 'Batteria';

  @override
  String get appSettings_batteryChemistry => 'Chimica della batteria';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Impostazione per dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Connetti a un dispositivo per scegliere';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Visualizzazione Mappa';

  @override
  String get appSettings_showRepeaters => 'Mostra Ripetitori';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Mostra i nodi ripetitori sulla mappa';

  @override
  String get appSettings_showChatNodes => 'Mostra Nodi Chat';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Mostra i nodi di chat sulla mappa';

  @override
  String get appSettings_showOtherNodes => 'Mostra altri nodi';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mostra altri tipi di nodo sulla mappa';

  @override
  String get appSettings_timeFilter => 'Filtro Temporale';

  @override
  String get appSettings_timeFilterShowAll => 'Mostra tutti i nodi';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostra i nodi delle ultime $hours ore';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro Tempo Mappa';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Mostra i nodi scoperti all\'interno di:';

  @override
  String get appSettings_allTime => 'Tutto il tempo';

  @override
  String get appSettings_lastHour => 'Ultima ora';

  @override
  String get appSettings_last6Hours => 'Ultimi 6 ore';

  @override
  String get appSettings_last24Hours => 'Ultime 24 ore';

  @override
  String get appSettings_lastWeek => 'La settimana scorsa';

  @override
  String get appSettings_unitsTitle => 'Unità';

  @override
  String get appSettings_unitsMetric => 'Metrico (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperiale (ft / mi)';

  @override
  String get appSettings_debugCard => 'Risoluzione dei problemi';

  @override
  String get appSettings_appDebugLogging => 'Registrazione Debug App';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Messaggi di debug dell\'app Log per la risoluzione dei problemi';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Logging di debug dell\'app abilitato';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Logging del debug dell\'app disabilitato';

  @override
  String get appSettings_incrementalContactSync =>
      'Sincronizzazione incrementale dei contatti';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Alla riconnessione, chiedi alla radio solo i contatti cambiati dall\'ultima volta';

  @override
  String get contacts_title => 'Contatti';

  @override
  String get contacts_noContacts => 'Nessun contatto ancora';

  @override
  String get contacts_shareMyQrCode => 'Condividi il mio codice QR';

  @override
  String get contacts_shareQrCodeDesc =>
      'Fai scansionare agli altri per aggiungerti come contatto';

  @override
  String get contacts_contactsWillAppear =>
      'I contatti appariranno quando i dispositivi pubblicizzano.';

  @override
  String get contacts_unread => 'Non letti';

  @override
  String get contacts_searchContactsNoNumber => 'Cerca Contatti...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Cerca contatti...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Cerca $number$str Preferiti...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Cerca $number$str Utenti...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Cerca $number$str Ripetitori...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Cerca $number$str server Room...';
  }

  @override
  String get contacts_noUnreadContacts => 'Nessun contatto non letto';

  @override
  String get contacts_noContactsFound => 'Nessun contatto o gruppo trovato.';

  @override
  String get contacts_deleteContact => 'Elimina Contatto';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Vuoi davvero eliminare $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Contatto $contactName eliminato.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Impossibile eliminare $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Nessun contatto corrisponde al filtro.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Eliminare $contactName dai contatti?';
  }

  @override
  String get contacts_manageRepeater => 'Gestisci Ripetitore';

  @override
  String get contacts_manageRoom => 'Gestisci Server Camera';

  @override
  String get contacts_roomLogin => 'Login Camera';

  @override
  String get contacts_openChat => 'Apri Chat';

  @override
  String get contacts_editGroup => 'Modifica Gruppo';

  @override
  String get contacts_deleteGroup => 'Elimina Gruppo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Eliminare \"$groupName\"?';
  }

  @override
  String get contacts_newGroup => 'Nuovo Gruppo';

  @override
  String get contacts_groupName => 'Nome gruppo';

  @override
  String get contacts_groupNameRequired => 'Il nome del gruppo è obbligatorio.';

  @override
  String get contacts_groupNameReserved => 'Questo nome del gruppo è riservato';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Il gruppo \"$name\" esiste già.';
  }

  @override
  String get contacts_filterContacts => 'Filtra i contatti...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Nessun contatto corrisponde al tuo filtro';

  @override
  String get contacts_noMembers => 'Nessun membro';

  @override
  String get contacts_lastSeenNow => 'Ultimo avvistamento ora';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Ultimo visto $minutes minuti fa';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Ultimo visto 1 ora fa';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Ultimo visto $hours ore fa';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Ultimo visto 1 giorno fa';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Ultimo visto $days giorni fa';
  }

  @override
  String get contact_info => 'Informazioni di Contatto';

  @override
  String get contact_settings => 'Impostazioni di contatto';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Ultimo accesso';

  @override
  String get contact_clearChat => 'Cancella chat';

  @override
  String get contact_teleBase => 'Base di telemetria';

  @override
  String get contact_teleBaseSubtitle =>
      'Consenti la condivisione del livello della batteria e della telemetria di base';

  @override
  String get contact_teleLoc => 'Posizione telemetria';

  @override
  String get contact_teleLocSubtitle =>
      'Consenti la condivisione dei dati di posizione';

  @override
  String get contact_teleEnv => 'Ambiente di telemetria';

  @override
  String get contact_teleEnvSubtitle =>
      'Consenti la condivisione dei dati del sensore ambientale';

  @override
  String get contacts_publicKey => 'Chiave pubblica';

  @override
  String get channels_title => 'Canali';

  @override
  String get channels_noChannelsConfigured => 'Nessun canale configurato';

  @override
  String get channels_addPublicChannel => 'Aggiungi Canale Pubblico';

  @override
  String get channels_searchChannels => 'Cerca canali...';

  @override
  String get channels_noChannelsFound => 'Nessun canale trovato';

  @override
  String channels_channelIndex(int index) {
    return 'Canale $index';
  }

  @override
  String get channels_hashtagChannel => 'Canale hashtag';

  @override
  String get channels_public => 'Pubblico';

  @override
  String get channels_private => 'Privato';

  @override
  String get channels_publicChannel => 'Canale pubblico';

  @override
  String get channels_privateChannel => 'Canale privato';

  @override
  String get channels_editChannel => 'Modifica canale';

  @override
  String get channels_shareChannel => 'Condividi canale';

  @override
  String get channels_shareChannelInstructions =>
      'Scansiona il codice QR per aggiungere il canale.\nMenu → Aggiungi Canale → Scansiona un codice QR';

  @override
  String get channels_secretKey => 'Chiave segreta';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

  @override
  String get channels_shareChannelQr => 'Scansiona codice QR del canale';

  @override
  String get channels_shareChannelWarning =>
      'Attenzione: chiunque scansioni questo codice QR avrà accesso a questo canale.';

  @override
  String get channels_muteChannel => 'Silenzia canale';

  @override
  String get channels_unmuteChannel => 'Attiva notifiche canale';

  @override
  String get channels_deleteChannel => 'Elimina canale';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Eliminare \"$name\"? Non può essere annullato.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Impossibile eliminare il canale \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Canale \"$name\" eliminato';
  }

  @override
  String get channels_addChannel => 'Aggiungi Canale';

  @override
  String get channels_channelIndexLabel => 'Indice Canale';

  @override
  String get channels_channelName => 'Nome canale';

  @override
  String get channels_usePublicChannel => 'Utilizza il canale pubblico';

  @override
  String get channels_standardPublicPsk => 'PSK pubblico standard';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk =>
      'Genera una chiave di permutazione casuale';

  @override
  String get channels_enterChannelName => 'Inserisci un nome per il canale';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK deve essere composto da 32 caratteri esadecimali.';

  @override
  String get channels_addChannelConfirmation =>
      'Vuoi aggiungere il seguente canale?';

  @override
  String get channels_channelAddedSuccess => 'Canale aggiunto.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Nessuno spazio libero per i canali.';

  @override
  String get appSettings_mentionNotifications => 'Notifiche delle menzioni';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Quando qualcuno ti menziona o ti risponde — anche nei canali silenziati';

  @override
  String notification_mentionIn(String channelName) {
    return 'Menzione in $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Canale \"$name\" aggiunto';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Modifica Canale $index';
  }

  @override
  String get channels_smazCompression => 'Compressione SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Canale \"$name\" aggiornato';
  }

  @override
  String get channels_publicChannelAdded => 'Canale pubblico aggiunto';

  @override
  String get channels_sortBy => 'Ordina per';

  @override
  String get channels_sortManual => 'Manuale';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Ultimi messaggi';

  @override
  String get channels_sortUnread => 'Non letto';

  @override
  String get channels_createPrivateChannel => 'Crea un Canale Privato';

  @override
  String get channels_createPrivateChannelDesc =>
      'Protetta con una chiave segreta.';

  @override
  String get channels_joinPrivateChannel => 'Unisciti a un Canale Privato';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Inserire manualmente una chiave segreta.';

  @override
  String get channels_joinPublicChannel => 'Unisciti al Canale Pubblico';

  @override
  String get channels_joinPublicChannelDesc =>
      'Chiunque può unirsi a questo canale.';

  @override
  String get channels_joinHashtagChannel => 'Unisciti a un Canale con Hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Chiunque può unirsi ai canali hashtag.';

  @override
  String get channels_scanQrCode => 'Scansiona un codice QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Arriverà presto';

  @override
  String get channels_enterHashtag => 'Inserisci hashtag';

  @override
  String get channels_hashtagHint => 'es. #team';

  @override
  String get chat_noMessages => 'Nessun messaggio ancora';

  @override
  String get chat_sendMessage => 'Invia messaggio';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Invia un messaggio a $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Invia un messaggio per iniziare';

  @override
  String get chat_originalMessageNotFound => 'Messaggio originale non trovato';

  @override
  String chat_replyingTo(String name) {
    return 'Rispondere a $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Rispondi a $name';
  }

  @override
  String get chat_location => 'Posizione';

  @override
  String get common_copiedToClipboard => 'Copiato negli appunti';

  @override
  String get common_copyToClipboard => 'Copia negli appunti';

  @override
  String get contacts_copyContactToClipboard =>
      'Copia il mio contatto negli appunti';

  @override
  String get chat_typeMessage => 'Digita un messaggio...';

  @override
  String get chat_searchMessages => 'Cerca messaggi';

  @override
  String get chat_searchNoMatches => 'Nessun risultato';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Messaggio troppo lungo (massimo $maxBytes byte).';
  }

  @override
  String get chat_messageCopied => 'Messaggio copiato';

  @override
  String get chat_messageDeleted => 'Messaggio eliminato';

  @override
  String get chat_sendGif => 'Invia GIF';

  @override
  String get chat_reply => 'Rispondi';

  @override
  String get chat_newMessages => 'NUOVI MESSAGGI';

  @override
  String get chat_addReaction => 'Aggiungi Reazione';

  @override
  String get chat_mention => 'Menziona';

  @override
  String get dmChannel_menuLabel => 'Messaggio diretto';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Messaggio diretto a $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Controlla la chiave e l\'ultimo accesso — i nomi non sono univoci.';

  @override
  String get dmChannel_warningTitle => 'È davvero questa persona?';

  @override
  String get dmChannel_warningBody =>
      'I nomi nei canali sono scelti liberamente e chiunque può imitarli. Per qualsiasi cosa delicata, verifica prima la chiave pubblica di questo contatto in un altro modo.';

  @override
  String get dmChannel_dontShowAgain => 'Non mostrare più';

  @override
  String get batterySleep_title => 'Mantieni attivo MeshTrax';

  @override
  String get batterySleep_bodySamsung =>
      'I telefoni Samsung sospendono le app per risparmiare batteria, e così la tua radio viene scollegata. Apri Impostazioni → Applicazioni → MeshTrax → Batteria e scegli Senza restrizioni. Controlla anche Batteria → Limiti utilizzo in background e assicurati che MeshTrax non sia tra le Applicazioni in sospensione o le Applicazioni in sospensione profonda.';

  @override
  String get batterySleep_bodyGeneric =>
      'Il telefono potrebbe fermare MeshTrax in background per risparmiare batteria, e così la tua radio viene scollegata. Apri le impostazioni della batteria e imposta MeshTrax su Senza restrizioni (o Nessuna restrizione). Su alcuni telefoni devi anche attivare l\'Avvio automatico per MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Apri impostazioni';

  @override
  String get batterySleep_notNow => 'Non ora';

  @override
  String get batterySleep_settingsTile =>
      'Mantieni MeshTrax attivo in background';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Impedisci al risparmio batteria del telefono di sospendere MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Non puoi ancora inviare un DM a $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Non hai ancora la sua chiave, e gli servirà la tua per rispondere — le chiavi viaggiano solo negli annunci. «Invia il mio annuncio» trasmette il tuo da qui. «Chiedi nel canale» scrive una richiesta nella casella del messaggio, che poi invii tu.';

  @override
  String get dmChannel_askInChannel => 'Chiedi nel canale';

  @override
  String get dmChannel_sendMyAdvert => 'Invia il mio annuncio';

  @override
  String get dmChannel_askText =>
      'per favore invia un annuncio così posso scriverti in privato';

  @override
  String get dmChannel_watching =>
      'In attesa del suo annuncio — riceverai un avviso qui quando arriva.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name ora è raggiungibile';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Livello di zoom';

  @override
  String get common_reset => 'Ripristina';

  @override
  String get chat_reactionsTitle => 'Reazioni';

  @override
  String get chat_reactionUnknownSender => 'Sconosciuto';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender ha reagito a un messaggio che non è in questa chat';
  }

  @override
  String get chat_me => 'Me';

  @override
  String get emojiCategorySmileys => 'Emoji';

  @override
  String get emojiCategoryGestures => 'Gesti';

  @override
  String get emojiCategoryHearts => 'Cuori';

  @override
  String get emojiCategoryObjects => 'Oggetti';

  @override
  String get gifPicker_title => 'Scegli un GIF';

  @override
  String get gifPicker_searchHint => 'Cerca GIF...';

  @override
  String get gifPicker_poweredBy => 'Potenziato da GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nessun GIF trovato';

  @override
  String get gifPicker_failedLoad => 'Impossibile caricare i GIF';

  @override
  String get gifPicker_failedSearch => 'Impossibile trovare GIF';

  @override
  String get gifPicker_noInternet => 'Nessuna connessione internet';

  @override
  String get debugLog_appTitle => 'Log di Debug dell\'App';

  @override
  String get debugLog_bleTitle => 'Log di Debug BLE';

  @override
  String get debugLog_copyLog => 'Copia log';

  @override
  String get debugLog_saveLog => 'Salva log su file';

  @override
  String get debugLog_saved => 'Log salvato';

  @override
  String get debugLog_saveCancelled => 'Salvataggio annullato';

  @override
  String get debugLog_filterAll => 'Tutti';

  @override
  String get debugLog_filterWarnings => 'Avvisi';

  @override
  String get debugLog_filterErrors => 'Errori';

  @override
  String get debugLog_clearLog => 'Cancella log';

  @override
  String get debugLog_copied => 'Log di debug copiato';

  @override
  String get debugLog_bleCopied => 'Log BLE copiato';

  @override
  String get debugLog_noEntries => 'Non ci sono ancora log di debug.';

  @override
  String get debugLog_enableInSettings =>
      'Abilita il logging di debug dell\'app nelle impostazioni';

  @override
  String get debugLog_frames => 'Frame';

  @override
  String get debugLog_rawLogRx => 'Log Raw-RX';

  @override
  String get debugLog_noBleActivity => 'Nessuna attività BLE rilevata ancora.';

  @override
  String debugFrame_length(int count) {
    return 'Lunghezza del Frame: $count byte';
  }

  @override
  String debugFrame_command(String value) {
    return 'Comando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Messaggio di testo:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destinazione PubChiave: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Timestamp: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Flag: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return 'Tipo di testo: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Comando CLI';

  @override
  String get debugFrame_textTypePlain => 'Semplice';

  @override
  String debugFrame_text(String text) {
    return '- Testo: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Dumpa Esadecimale:';

  @override
  String get chat_hopSingular => 'salta';

  @override
  String get chat_hopPlural => 'salta';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'salti',
      one: 'salto',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Imposta Percorso Personalizzato';

  @override
  String get chat_fullPath => 'Percorso Completo';

  @override
  String get chat_pathDetailsNotAvailable =>
      'I dettagli del percorso non sono ancora disponibili. Prova a inviare un messaggio per ricaricare.';

  @override
  String get chat_type => 'Digita';

  @override
  String get chat_path => 'Percorso';

  @override
  String get chat_publicKey => 'Chiave Pubblica';

  @override
  String get chat_compressOutgoingMessages => 'Comprimi messaggi in uscita';

  @override
  String get chat_floodForced => 'Inondazione (forzata)';

  @override
  String get chat_directForced => 'Riavvia (forzato)';

  @override
  String chat_hopsForced(int count) {
    return '$count salti (forzati)';
  }

  @override
  String get chat_floodAuto => 'Inondazione (auto)';

  @override
  String get chat_direct => 'Salva';

  @override
  String get chat_poiShared => 'Punti di Interesse Condivisi';

  @override
  String chat_unread(int count) {
    return 'Non letti: $count';
  }

  @override
  String get chat_openLink => 'Aprire il link?';

  @override
  String get chat_openLinkConfirmation =>
      'Vuoi aprire questo link nel tuo browser?';

  @override
  String get chat_open => 'Apri';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Impossibile aprire il link: $url';
  }

  @override
  String get chat_invalidLink => 'Formato di link non valido';

  @override
  String get map_lineOfSight => 'Linea di vista';

  @override
  String get map_losScreenTitle => 'Linea di vista';

  @override
  String get map_noNodesWithLocation => 'Nessun nodo con dati di posizione';

  @override
  String get map_nodesNeedGps =>
      'I nodi devono condividere le loro coordinate GPS\nper apparire sulla mappa';

  @override
  String map_nodesCount(int count) {
    return 'Nodi: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Puntatori: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Ripetitore';

  @override
  String get map_room => 'Stanza';

  @override
  String get map_sensor => 'Sensore';

  @override
  String get map_pinDm => 'Codice PIN (DM)';

  @override
  String get map_pinPrivate => 'Blocco (Privato)';

  @override
  String get map_pinPublic => 'Pin (Pubblico)';

  @override
  String get map_lastSeen => 'Ultimo visto';

  @override
  String get map_disconnectConfirm =>
      'Sei sicuro di voler disconnetterti da questo dispositivo?';

  @override
  String get map_from => 'Da';

  @override
  String get map_source => 'Fonte';

  @override
  String get map_flags => 'Bandiere';

  @override
  String get map_shareMarkerHere => 'Condividi marcatore qui';

  @override
  String get map_setAsMyLocation => 'Imposta come la mia posizione';

  @override
  String get map_pinLabel => 'Etichetta PIN';

  @override
  String get map_label => 'Etichetta';

  @override
  String get map_pointOfInterest => 'Punto di interesse';

  @override
  String get map_sendToContact => 'Invia a contatto';

  @override
  String get map_sendToChannel => 'Invia al canale';

  @override
  String get map_noChannelsAvailable => 'Nessun canale disponibile';

  @override
  String get map_publicLocationShare => 'Condividi in una posizione pubblica';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Stai per condividere una posizione in $channelLabel. Questo canale è pubblico e chiunque abbia la PSK può vederlo.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Connetti a un dispositivo per condividere i segnaposti';

  @override
  String get map_filterNodes => 'Filtra Nodi';

  @override
  String get map_chatNodes => 'Nodi di Chat';

  @override
  String get map_repeaters => 'Ripetitori';

  @override
  String get map_otherNodes => 'Altri Nodi';

  @override
  String get map_showOverlaps => 'Sovrapposizioni della chiave ripetitore';

  @override
  String get map_keyPrefix => 'Prefisso Chiave';

  @override
  String get map_filterByKeyPrefix => 'Filtra per prefisso chiave';

  @override
  String get map_publicKeyPrefix => 'Prefisso chiave pubblica';

  @override
  String get map_showDiscoveryContacts => 'Mostra Contatti di Discovery';

  @override
  String get map_guessedLocation => 'Località indovinata';

  @override
  String get map_lastSeenTime => 'Ultimo Tempo di Visualizzazione';

  @override
  String get map_sharedPin => 'Condividi PIN';

  @override
  String get map_joinRoom => 'Unisciti alla stanza';

  @override
  String get map_manageRepeater => 'Gestisci Ripetitore';

  @override
  String get map_tapToAdd => 'Tocca i nodi per aggiungerli al percorso.';

  @override
  String get map_runTrace => 'Esegui Path Trace';

  @override
  String get map_runTraceWithReturnPath =>
      'Tornare indietro sullo stesso percorso';

  @override
  String get map_removeLast => 'Rimuovi ultimo';

  @override
  String get map_pathTraceCancelled => 'Tracciamento del percorso annullato.';

  @override
  String get time_justNow => 'Proprio ora';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minuti fa';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h fa';
  }

  @override
  String time_daysAgo(int days) {
    return '$days giorni fa';
  }

  @override
  String get time_hour => 'ora';

  @override
  String get time_hours => 'ore';

  @override
  String get time_day => 'giorno';

  @override
  String get time_days => 'giorni';

  @override
  String get time_week => 'settimana';

  @override
  String get time_weeks => 'settimane';

  @override
  String get time_month => 'mese';

  @override
  String get time_months => 'mesi';

  @override
  String get time_minutes => 'minuti';

  @override
  String get time_allTime => 'Tutto il Tempo';

  @override
  String get dialog_disconnect => 'Disconnetti';

  @override
  String get dialog_disconnectConfirm =>
      'Sei sicuro di voler disconnetterti da questo dispositivo?';

  @override
  String get login_repeaterLogin => 'Login Ripetitore';

  @override
  String get login_roomLogin => 'Login Camera';

  @override
  String get login_password => 'Password';

  @override
  String get login_enterPassword => 'Inserisci password';

  @override
  String get login_savePassword => 'Salva password';

  @override
  String get login_savePasswordSubtitle =>
      'La password verrà memorizzata in modo sicuro su questo dispositivo.';

  @override
  String get login_repeaterDescription =>
      'Inserisci la password del ripetitore per accedere alle impostazioni e allo stato.';

  @override
  String get login_roomDescription =>
      'Inserisci la password della stanza per accedere alle impostazioni e allo stato.';

  @override
  String get login_login => 'Accedi';

  @override
  String login_attempt(int current, int max) {
    return 'Prova $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Accesso fallito: $error';
  }

  @override
  String get login_failedMessage =>
      'Accesso fallito. La password non è corretta oppure il ripetitore non è raggiungibile.';

  @override
  String get common_reload => 'Ricaricare';

  @override
  String get common_clear => 'Cancella';

  @override
  String get path_enterCustomPath => 'Inserisci percorso personalizzato';

  @override
  String get path_currentPathLabel => 'Percorso corrente';

  @override
  String get path_hexPrefixInstructions =>
      'Inserire i prefissi esadecimali a 2 caratteri per ogni salto, separati da virgole.';

  @override
  String get path_hexPrefixExample =>
      'Esempio: A1,F2,3C (ogni nodo utilizza il primo byte della sua chiave pubblica)';

  @override
  String get path_labelHexPrefixes => 'Prefisso esadecimale (percorso)';

  @override
  String get path_helperMaxHops =>
      'Massimo 64 salti. Ogni prefisso è composto da 2 caratteri esadecimali (1 byte)';

  @override
  String get path_selectFromContacts => 'Seleziona da contatti:';

  @override
  String get path_noRepeatersFound =>
      'Non sono stati trovati ripetitori o server di stanza.';

  @override
  String get path_customPathsRequire =>
      'I percorsi personalizzati richiedono salti intermedi che possono inoltrare messaggi.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Prefissi esadecimali non validi: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Il percorso è troppo lungo. Massimo 64 salti consentiti.';

  @override
  String get path_setPath => 'Imposta Percorso';

  @override
  String get repeater_management => 'Gestione Ripetitori';

  @override
  String get room_management => 'Gestione del Server di Camera';

  @override
  String get repeater_guest => 'Informazioni sul ripetitore';

  @override
  String get room_guest => 'Informazioni sul server';

  @override
  String get repeater_managementTools => 'Strumenti di Gestione';

  @override
  String get repeater_guestTools => 'Strumenti per gli ospiti';

  @override
  String get repeater_status => 'Stato';

  @override
  String get repeater_statusSubtitle =>
      'Visualizza lo stato, le statistiche e i vicini del ripetitore';

  @override
  String get repeater_telemetry => 'Telemetry';

  @override
  String get repeater_telemetrySubtitle =>
      'Visualizza i dati di telemetria dei sensori e le statistiche di sistema';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Invia comandi al ripetitore';

  @override
  String get repeater_neighbors => 'Vicini';

  @override
  String get repeater_neighborsSubtitle =>
      'Visualizza vicini di salto pari a zero.';

  @override
  String get repeater_settings => 'Impostazioni';

  @override
  String get repeater_settingsSubtitle =>
      'Configura i parametri del ripetitore';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Sincronizzazione dell\'orologio dopo il login';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Invia automaticamente il comando \"sincronizzazione dell\'orologio\" dopo un login riuscito.';

  @override
  String get repeater_statusTitle => 'Stato del Ripetitore';

  @override
  String get repeater_refresh => 'Aggiorna';

  @override
  String get repeater_statusRequestTimeout => 'Richiesta stato scaduta.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Errore nel caricamento dello stato: $error';
  }

  @override
  String get repeater_systemInformation => 'Informazioni di sistema';

  @override
  String get repeater_battery => 'Batteria';

  @override
  String get repeater_clockAtLogin => 'Orologio (all\'accesso)';

  @override
  String get repeater_uptime => 'Disponibilità';

  @override
  String get repeater_queueLength => 'Lunghezza della coda';

  @override
  String get repeater_debugFlags => 'Impostazioni Debug';

  @override
  String get repeater_radioStatistics => 'Statistiche Radio';

  @override
  String get repeater_lastRssi => 'Ultimo RSSI';

  @override
  String get repeater_lastSnr => 'Ultimo SNR';

  @override
  String get repeater_noiseFloor => 'Livello del Rumore';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Statistiche del Pacchetto';

  @override
  String get repeater_sent => 'Inviato';

  @override
  String get repeater_received => 'Ricevuto';

  @override
  String get repeater_duplicates => 'Duplicati';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days giorni ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Totale: $total, Inondazione: $flood, Diretto: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Totale: $total, Inondazione: $flood, Diretto: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Inondazione: $flood, Diretto: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Totale: $total';
  }

  @override
  String get repeater_settingsTitle => 'Impostazioni Ripetitore';

  @override
  String get repeater_basicSettings => 'Impostazioni di Base';

  @override
  String get repeater_repeaterName => 'Nome Ripetitore';

  @override
  String get repeater_repeaterNameHelper =>
      'Visualizza il nome di questo ripetitore';

  @override
  String get repeater_adminPassword => 'Password Amministratore';

  @override
  String get repeater_adminPasswordHelper => 'Accesso completo password';

  @override
  String get repeater_guestPassword => 'Password Ospite';

  @override
  String get repeater_guestPasswordHelper =>
      'Accesso in sola lettura con password';

  @override
  String get repeater_radioSettings => 'Impostazioni Radio';

  @override
  String get repeater_frequencyMhz => 'Frequenza (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Potenza';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Larghezza di banda';

  @override
  String get repeater_spreadingFactor => 'Spreading Factor';

  @override
  String get repeater_codingRate => 'Tasso di Codifica';

  @override
  String get repeater_locationSettings => 'Impostazioni Luogo';

  @override
  String get repeater_latitude => 'Latitudine';

  @override
  String get repeater_latitudeHelper => 'Grado decimale (ad esempio, 37.7749)';

  @override
  String get repeater_longitude => 'Longitudine';

  @override
  String get repeater_longitudeHelper =>
      'Grado decimale (ad esempio, -122,4194)';

  @override
  String get repeater_features => 'Caratteristiche';

  @override
  String get repeater_packetForwarding => 'Instradamento Pacchetti';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Abilita il ripetitore per inoltrare i pacchetti';

  @override
  String get repeater_guestAccess => 'Accesso Ospite';

  @override
  String get repeater_guestAccessSubtitle =>
      'Consenti l\'accesso ospite in sola lettura';

  @override
  String get repeater_privacyMode => 'Modalità Privacy';

  @override
  String get repeater_privacyModeSubtitle =>
      'Nascondere nome/luogo negli annunci';

  @override
  String get repeater_advertisementSettings => 'Impostazioni Annuncio';

  @override
  String get repeater_localAdvertInterval => 'Intervallo Pubblicità Locale';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minuti';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervallo Pubblicità Inondazione';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours ore';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Intervallo Pubblicitario Crittografato';

  @override
  String get repeater_dangerZone => 'Zona Pericolosa';

  @override
  String get repeater_rebootRepeater => 'Riavvia Ripetitore';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Riavvia il dispositivo ripetitore';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Sei sicuro di voler riavviare questo ripetitore?';

  @override
  String get repeater_regenerateIdentityKey => 'Rigenera Chiave Identità';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Genera una nuova coppia di chiavi pubblica/privata';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Questo genererà una nuova identità per il ripetitore. Procedere?';

  @override
  String get repeater_eraseFileSystem => 'Elimina File System';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatta il file system del ripetitore';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ATTENZIONE: Ciò cancellerà tutti i dati sul ripetitore. Non può essere annullato!';

  @override
  String get repeater_eraseSerialOnly =>
      'Elimina è disponibile solo tramite console seriale.';

  @override
  String repeater_commandSent(String command) {
    return 'Comando inviato: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Errore nell\'invio del comando: $error';
  }

  @override
  String get repeater_confirm => 'Conferma';

  @override
  String get repeater_settingsSaved => 'Impostazioni salvate con successo';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Errore durante il salvataggio delle impostazioni: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Aggiorna Impostazioni Base';

  @override
  String get repeater_refreshRadioSettings => 'Aggiorna le Impostazioni Radio';

  @override
  String get repeater_refreshTxPower => 'Aggiorna TX potenza';

  @override
  String get repeater_refreshLocationSettings =>
      'Aggiorna le Impostazioni della Posizione';

  @override
  String get repeater_refreshPacketForwarding =>
      'Aggiorna il inoltro pacchetti';

  @override
  String get repeater_refreshGuestAccess => 'Aggiorna Accesso Ospite';

  @override
  String get repeater_refreshPrivacyMode => 'Aggiorna Modalità Privacy';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Aggiorna le Impostazioni dell\'Annuncio';

  @override
  String repeater_refreshed(String label) {
    return '$label aggiornato';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Errore durante il ricaricamento di $label';
  }

  @override
  String get repeater_cliTitle => 'Riprova CLI';

  @override
  String get repeater_debugNextCommand => 'Riavvia Comando Prossimo';

  @override
  String get repeater_commandHelp => 'Aiuto';

  @override
  String get repeater_clearHistory => 'Cancella Cronologia';

  @override
  String get repeater_noCommandsSent => 'Nessun comando inviato ancora';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Digita un comando qui sotto o usa comandi rapidi';

  @override
  String get repeater_enterCommandHint => 'Inserisci comando...';

  @override
  String get repeater_previousCommand => 'Comando precedente';

  @override
  String get repeater_nextCommand => 'Prossimo comando';

  @override
  String get repeater_enterCommandFirst => 'Inserisci un comando prima';

  @override
  String get repeater_cliCommandFrameTitle => 'Finestra Comando CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Errore: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Ottieni Nome';

  @override
  String get repeater_cliQuickGetRadio => 'Ottieni Radio';

  @override
  String get repeater_cliQuickGetTx => 'Ottieni TX';

  @override
  String get repeater_cliQuickNeighbors => 'Vicini';

  @override
  String get repeater_cliQuickVersion => 'Versione';

  @override
  String get repeater_cliQuickAdvertise => 'Pubblicare';

  @override
  String get repeater_cliQuickClock => 'Orologio';

  @override
  String get repeater_cliQuickClockSync => 'Sincronizzazione dell\'orologio';

  @override
  String get repeater_cliQuickDiscovery => 'Scopri i Vicini';

  @override
  String get repeater_cliHelpAdvert => 'Invia un pacchetto pubblicitario';

  @override
  String get repeater_cliHelpReboot =>
      'Riavvia il dispositivo. (nota, potresti ottenere \'Timeout\' che è normale)';

  @override
  String get repeater_cliHelpClock =>
      'Mostra l\'ora corrente per l\'orologio di ciascun dispositivo.';

  @override
  String get repeater_cliHelpPassword =>
      'Imposta una nuova password di amministratore per il dispositivo.';

  @override
  String get repeater_cliHelpVersion =>
      'Mostra la versione del dispositivo e la data di costruzione del firmware.';

  @override
  String get repeater_cliHelpClearStats =>
      'Resetta vari numerosi contatori di statistiche a zero.';

  @override
  String get repeater_cliHelpSetAf =>
      'Imposta il fattore di tempo di trasmissione.';

  @override
  String get repeater_cliHelpSetTx =>
      'Imposta la potenza di trasmissione LoRa in dBm (riavvia per applicare).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Abilita o disabilita il ruolo del ripetitore per questo nodo.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Server della stanza) Se \'on\', allora l\'accesso con una password vuota sarà consentito, ma non sarà possibile pubblicare nella stanza. (solo lettura).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Imposta il numero massimo di salti per i pacchetti di inondazione in entrata (se >= max, il pacchetto non viene inoltrato)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Imposta il Limite di Interferenza (in dB). Il valore predefinito è 14. Imposta su 0 per disabilitare il rilevamento delle interferenze del canale.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Imposta l\'intervallo per resettare il controllore Automatico del Guadagno. Imposta su 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Abilita o disabilita la funzione \'double ACKs\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Imposta l\'intervallo del timer in minuti per inviare un pacchetto di pubblicità locale (senza salto). Imposta su 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Imposta l\'intervallo del timer in ore per inviare un pacchetto pubblicitario di massa. Imposta su 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Imposta/aggiorna la password dell\'ospite. (per ripetitori, gli accessi degli ospiti possono inviare la richiesta \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Imposta il nome dell\'annuncio.';

  @override
  String get repeater_cliHelpSetLat =>
      'Imposta la latitudine della mappa pubblicitaria. (gradi decimali)';

  @override
  String get repeater_cliHelpSetLon =>
      'Imposta la longitudine della mappa pubblicitaria. (gradi decimali)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Imposta completamente nuovi parametri radio e li salva nelle preferenze. Richiede un comando \"reboot\" per l\'applicazione.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Impostazioni (experimental) base (deve essere > 1 per l\'effetto) per applicare un leggero ritardo ai pacchetti ricevuti, in base alla forza del segnale/punteggio. Imposta a 0 per disabilitare.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Imposta un fattore moltiplicato con il tempo di mantenimento per un pacchetto di modalità allagamento e con un sistema di slot casuale, per ritardarne la trasmissione (per diminuire la probabilità di collisioni).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Uguale a txdelay, ma per applicare un ritardo casuale alla inoltrata di pacchetti in modalità diretta.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Abilita/Disabilita ponte.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Imposta il ritardo prima di ritrasmettere i pacchetti.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Scegliere se il ponte dovrà ritrasmettere i pacchetti ricevuti o i pacchetti trasmessi.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Imposta la velocità di trasmissione per i ponti rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Imposta il segreto per i ponti espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Imposta un fattore personalizzato per regolare la tensione della batteria riportata (supportato solo su schede selezionate).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Imposta parametri radio temporanei per il numero specificato di minuti, per poi tornare ai parametri radio originali. (non salva nelle preferenze).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifica l\'ACL. Rimuove l\'entrata corrispondente (per prefisso di pubkey) se \"permissions\" è zero. Aggiunge una nuova entrata se il pubkey-hex ha lunghezza completa e non è attualmente nell\'ACL. Aggiorna l\'entrata per corrispondenza del prefisso di pubkey. I bit di permesso variano per ogni ruolo di firmware, ma i primi 2 bit sono: 0 (Guest), 1 (solo lettura), 2 (lettura/scrittura), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Ottiene tipo ponte nessuno, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Avvia registrazione pacchetti nel file system.';

  @override
  String get repeater_cliHelpLogStop =>
      'Interrompi la registrazione dei pacchetti al file system.';

  @override
  String get repeater_cliHelpLogErase =>
      'Elimina i log del pacchetto dal file system.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Mostra un elenco di altri nodi repeater ricevuti tramite annunci zero-hop. Ogni riga è id-prefisso-esadecimale:timestamp:snr-volte-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Rimuove la prima corrispondenza in base al prefisso (esadecimale) della pubkey, dalla lista dei vicini.';

  @override
  String get repeater_cliHelpRegion =>
      '(solo serie) Elenca tutte le regioni definite e le autorizzazioni di allagamento correnti.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTA: questo è un\'invocazione multi-comando speciale. Ogni comando successivo è un nome di regione (indentato con spazi per indicare la gerarchia parentale, con almeno uno spazio). Terminata inviando una riga vuota/comando.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Cerca la regione con il prefisso del nome dato (o \"\" per l\'ambito globale). Risponde con \"-> nome-regione (nome-genitore) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Aggiunge o aggiorna una definizione di regione con il nome specificato.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Rimuove una definizione di regione con il dato nome. (deve corrispondere esattamente e non avere regioni figlio)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Imposta il permesso di \'F\'lood per la regione specificata. (\'\' per lo scope globale/legacy)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Rimuove il permesso \'F\'lood per la regione specificata. (NOTA: a questo stadio non è consigliato utilizzarlo sullo scope globale/legacy!!).';

  @override
  String get repeater_cliHelpRegionHome =>
      'Risposte con la regione \'home\' corrente. (Nota applicata finora, riservata per il futuro)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Imposta la regione \'home\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Persiste l\'elenco/mappa delle regioni all\'archiviazione.';

  @override
  String get repeater_cliHelpGps =>
      'Mostra lo stato del GPS. Quando il GPS è spento, risponde solo \"spento\", se è acceso risponde con \"acceso\", \"stato\", \"fix\" e numero di satelliti.';

  @override
  String get repeater_cliHelpGpsOnOff =>
      'Attiva/disattiva l\'alimentazione del GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sincronizza l\'orario del nodo con l\'orologio GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Imposta la posizione del nodo alle coordinate GPS e salva le preferenze.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Fornisce la configurazione dell\'annuncio per il nodo:\n- nessuno: non includere la posizione negli annunci\n- condividi: condividi la posizione GPS (dal SensorManager)\n- preferenze: annuncia la posizione memorizzata nelle preferenze';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Imposta la configurazione dell\'annuncio sulla posizione.';

  @override
  String get repeater_commandsListTitle => 'Elenco Comandi';

  @override
  String get repeater_commandsListNote =>
      'NOTA: per i vari comandi \"set...\", esiste anche un comando \"get...\".';

  @override
  String get repeater_general => 'Generale';

  @override
  String get repeater_settingsCategory => 'Impostazioni';

  @override
  String get repeater_bridge => 'Ponte';

  @override
  String get repeater_logging => 'Registrazione';

  @override
  String get repeater_neighborsRepeaterOnly => 'Vicini (solo ripetitore)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gestione Regione (solo Ripetitore)';

  @override
  String get repeater_regionNote =>
      'Sono state introdotte le comandi di regione per gestire le definizioni e le autorizzazioni delle regioni.';

  @override
  String get repeater_gpsManagement => 'Gestione GPS';

  @override
  String get repeater_gpsNote =>
      'è stata introdotta una funzione gps per gestire le tematiche relative alla posizione.';

  @override
  String get telemetry_receivedData => 'Dati Telemetria Ricevuti';

  @override
  String get telemetry_requestTimeout => 'Richiesta di telemetria scaduta.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Errore nel caricamento della telemetria: $error';
  }

  @override
  String get telemetry_noData => 'Nessun dato di telemetria disponibile.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canale $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batteria';

  @override
  String get telemetry_voltageLabel => 'Tensione';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Attuale';

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
  String get neighbors_receivedData => 'Ricevute dati vicini';

  @override
  String get neighbors_requestTimedOut => 'I vicini richiedono un timeout.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Errore nel caricamento dei vicini: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Ripetitori Vicini';

  @override
  String get neighbors_noData => 'Nessun dato sugli vicini disponibile.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Chiave pubblica sconosciuta $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Sentito: $time fa';
  }

  @override
  String get channelPath_title => 'Percorso Pacchetto';

  @override
  String get channelPath_viewMap => 'Visualizza la mappa';

  @override
  String get channelPath_otherObservedPaths => 'Altri Percorsi Osservati';

  @override
  String get channelPath_repeaterHops => 'Passaggi Ripetitore';

  @override
  String get channelPath_noHopDetails =>
      'I dettagli relativi a questo pacchetto non sono forniti.';

  @override
  String get channelPath_messageDetails => 'Dettagli Messaggio';

  @override
  String get channelPath_senderLabel => 'Mittente';

  @override
  String get channelPath_timeLabel => 'Tempo';

  @override
  String get channelPath_repeatsLabel => 'Ripeti';

  @override
  String channelPath_pathLabel(int index) {
    return 'Percorso $index';
  }

  @override
  String get channelPath_observedLabel => 'Osservato';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Percorso osservato $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Nessun dato di posizione';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Sconosciuto';

  @override
  String get channelPath_floodPath => 'Inondazione';

  @override
  String get channelPath_directPath => 'Salva';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 di $total salti';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed di $total salti';
  }

  @override
  String get channelPath_mapTitle => 'Mappa del Percorso';

  @override
  String get channelPath_noRepeaterLocations =>
      'Non sono disponibili posizioni per i ripetitori per questo percorso.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Percorso $index (Primario)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Percorso';

  @override
  String get channelPath_observedPathHeader => 'Percorso Osservato';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Non sono disponibili i dettagli del salto per questo pacchetto.';

  @override
  String get channelPath_unknownRepeater => 'Ripetitore sconosciuto';

  @override
  String get community_title => 'Comunità';

  @override
  String get community_create => 'Crea Comunità';

  @override
  String get community_createDesc =>
      'Crea una nuova comunità e condividila tramite codice QR.';

  @override
  String get community_join => 'Unisciti';

  @override
  String get community_joinTitle => 'Unisciti alla Community';

  @override
  String community_joinConfirmation(String name) {
    return 'Vuoi unirti alla community \"$name\"?';
  }

  @override
  String get community_scanQr => 'Scansiona il QR Code della Community';

  @override
  String get community_scanInstructions =>
      'Punta la fotocamera su un codice QR della comunità';

  @override
  String get community_showQr => 'Mostra il codice QR';

  @override
  String get community_publicChannel => 'Comunità Pubblica';

  @override
  String get community_hashtagChannel => 'Hashtag della Comunità';

  @override
  String get community_name => 'Nome della Comunità';

  @override
  String get community_enterName => 'Inserisci il nome della comunità';

  @override
  String community_created(String name) {
    return 'Comunità \"$name\" creata';
  }

  @override
  String community_joined(String name) {
    return 'Unito alla comunità \"$name\"';
  }

  @override
  String get community_qrTitle => 'Condividi Comunità';

  @override
  String community_qrInstructions(String name) {
    return 'Scansiona questo codice QR per unirti a $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'I canali hashtag della community sono accessibili solo ai membri della community';

  @override
  String get community_invalidQrCode => 'Codice QR della community non valido';

  @override
  String get community_alreadyMember => 'Già membro';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Sei già un membro di \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Aggiungi Canale Pubblico della Comunità';

  @override
  String get community_addPublicChannelHint =>
      'Aggiungi automaticamente il canale pubblico per questa community';

  @override
  String get community_noCommunities => 'Nessun gruppo aggiunto finora';

  @override
  String get community_scanOrCreate =>
      'Scansiona un codice QR o crea una community per iniziare.';

  @override
  String get community_manageCommunities => 'Gestisci Comunità';

  @override
  String get community_delete => 'Lascia la Comunità';

  @override
  String community_deleteConfirm(String name) {
    return 'Uscire da \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Questo eliminerà anche $count canale/i e i loro messaggi.';
  }

  @override
  String community_deleted(String name) {
    return 'Hai lasciato la comunità \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Ri genera la chiave segreta';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenera la chiave segreta per \"$name\"? Tutti i membri dovranno scansionare il nuovo codice QR per continuare a comunicare.';
  }

  @override
  String get community_regenerate => 'Rigenera';

  @override
  String community_secretRegenerated(String name) {
    return 'Codice segreto rigenerato per \"$name\"';
  }

  @override
  String get community_updateSecret => 'Aggiorna Segreto';

  @override
  String community_secretUpdated(String name) {
    return 'Segreto aggiornato per \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scansiona il nuovo codice QR per aggiornare il segreto di \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Aggiungi Hashtag della Community';

  @override
  String get community_addHashtagChannelDesc =>
      'Aggiungi un canale con hashtag per questa community';

  @override
  String get community_selectCommunity => 'Seleziona Comunità';

  @override
  String get community_regularHashtag => 'Hashtag regolare';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag pubblico (chiunque può unirsi)';

  @override
  String get community_communityHashtag => 'Hashtag della Comunità';

  @override
  String get community_communityHashtagDesc =>
      'Visibile solo ai membri della comunità';

  @override
  String community_forCommunity(String name) {
    return 'Per $name';
  }

  @override
  String get listFilter_tooltip => 'Filtra e ordina';

  @override
  String get listFilter_sortBy => 'Ordina per';

  @override
  String get listFilter_latestMessages => 'Ultimi messaggi';

  @override
  String get listFilter_heardRecently => 'Sentito di recente';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtri';

  @override
  String get listFilter_source => 'Origine';

  @override
  String get listFilter_saved => 'Salvati';

  @override
  String get listFilter_discovered => 'Scoperti';

  @override
  String get listFilter_all => 'Tutti';

  @override
  String get listFilter_favorites => 'Preferiti';

  @override
  String get listFilter_addToFavorites => 'Aggiungi ai preferiti';

  @override
  String get listFilter_removeFromFavorites => 'Rimuovi dai preferiti';

  @override
  String get listFilter_users => 'Utenti';

  @override
  String get listFilter_repeaters => 'Ripetitori';

  @override
  String get listFilter_roomServers => 'Server della stanza';

  @override
  String get listFilter_unreadOnly => 'Solo non letto';

  @override
  String get listFilter_newGroup => 'Nuovo gruppo';

  @override
  String get pathTrace_you => 'Tu';

  @override
  String get pathTrace_failed => 'Tracciamento del percorso fallito.';

  @override
  String get pathTrace_notAvailable =>
      'Tracciamento del percorso non disponibile.';

  @override
  String get pathTrace_refreshTooltip => 'Aggiorna Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Uno o più dei luppoli mancano di una posizione!';

  @override
  String get pathTrace_clearTooltip => 'Pulisci percorso';

  @override
  String get losSelectStartEnd =>
      'Seleziona i nodi iniziali e finali per la LOS.';

  @override
  String losRunFailed(String error) {
    return 'Controllo della linea di vista fallito: $error';
  }

  @override
  String get losClearAllPoints => 'Cancella tutti i punti';

  @override
  String get losRunToViewElevationProfile =>
      'Eseguire LOS per visualizzare il profilo altimetrico';

  @override
  String get losMenuTitle => 'Menù LOS';

  @override
  String get losMenuSubtitle =>
      'Tocca i nodi o premi a lungo la mappa per punti personalizzati';

  @override
  String get losShowDisplayNodes => 'Mostra i nodi di visualizzazione';

  @override
  String get losCustomPoints => 'Punti personalizzati';

  @override
  String losCustomPointLabel(int index) {
    return 'Personalizzato $index';
  }

  @override
  String get losPointA => 'Punto A';

  @override
  String get losPointB => 'Punto B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenna A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenna B: $value $unit';
  }

  @override
  String get losRun => 'Esegui LOS';

  @override
  String get losNoElevationData => 'Nessun dato di elevazione';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, libera LOS, distanza minima $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, bloccato da $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: controllo...';

  @override
  String get losStatusNoData => 'LOS: nessun dato';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total libera, $blocked bloccato, $unknown sconosciuto';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Dati di elevazione non disponibili per uno o più campioni.';

  @override
  String get losErrorInvalidInput =>
      'Dati punti/elevazione non validi per il calcolo della LOS.';

  @override
  String get losRenameCustomPoint => 'Rinomina punto personalizzato';

  @override
  String get losPointName => 'Nome del punto';

  @override
  String get losShowPanelTooltip => 'Mostra il pannello LOS';

  @override
  String get losHidePanelTooltip => 'Nascondi il pannello LOS';

  @override
  String get losElevationAttribution =>
      'Dati di elevazione: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Orizzonte radio';

  @override
  String get losLegendLosBeam => 'Linea di vista';

  @override
  String get losLegendTerrain => 'Terreno';

  @override
  String get losFrequencyLabel => 'Frequenza';

  @override
  String get losFrequencyInfoTooltip => 'Visualizza i dettagli del calcolo';

  @override
  String get losFrequencyDialogTitle => 'Calcolo dell’orizzonte radio';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Partendo da k=$baselineK a $baselineFreq MHz, il calcolo regola il fattore k per l\'attuale banda $frequencyMHz MHz, che definisce il limite curvo dell\'orizzonte radio.';
  }

  @override
  String get contacts_pathTrace => 'Traccia Percorso';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Traccia percorso al ripetitore';

  @override
  String get contacts_repeaterPing => 'Ripetitore ping';

  @override
  String get contacts_roomPathTrace =>
      'Traccia del percorso al server della stanza';

  @override
  String get contacts_roomPing => 'Ping al server della stanza';

  @override
  String get contacts_chatTraceRoute => 'Traccia percorso path';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Traccia percorso verso $name';
  }

  @override
  String get contacts_clipboardEmpty => 'La clipboard è vuota.';

  @override
  String get contacts_invalidAdvertFormat => 'Dati di contatto non validi';

  @override
  String get contacts_contactImported => 'Il contatto è stato importato.';

  @override
  String get contacts_contactImportFailed =>
      'Contatto non importato con successo.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name è già nei tuoi contatti.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Annuncio Zero Hop';

  @override
  String get contacts_floodAdvert => 'Annuncio alluvionale';

  @override
  String get contacts_copyAdvertToClipboard => 'Copia Annuncio negli Appunti';

  @override
  String get contacts_addContactFromClipboard =>
      'Aggiungere contatto dalla clipboard';

  @override
  String get contacts_ShareContact => 'Copia contatto negli Appunti';

  @override
  String get contacts_ShareContactZeroHop =>
      'Condividi contatto tramite annuncio';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Inviato contatto tramite annuncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Invio del contatto non riuscito.';

  @override
  String get contacts_contactAdvertCopied => 'Annuncio copiato negli Appunti.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Copia dell\'annuncio nella Clipboard non riuscita.';

  @override
  String get contacts_addContact => 'Aggiungi contatto';

  @override
  String get contacts_scanQrCode => 'Scansiona QR contatto';

  @override
  String get contacts_scanQrCodeDesc =>
      'Scansiona il codice QR di un contatto dall\'app MeshCore';

  @override
  String get contacts_enterIdHash => 'Inserisci contatto manualmente';

  @override
  String get contacts_enterIdHashDesc =>
      'Incolla un annuncio di contatto o un link meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... o chiave pubblica hex';

  @override
  String get contacts_import => 'Importa';

  @override
  String get contacts_scanContactInstructions =>
      'Scansiona il codice QR di un contatto MeshCore';

  @override
  String get notification_activityTitle => 'Attività MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messaggi',
      one: 'messaggio',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messaggi del canale',
      one: 'messaggio del canale',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nuovi nodi',
      one: 'nuovo nodo',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nuovo $contactType scoperto';
  }

  @override
  String get notification_receivedNewMessage => 'Nuovo messaggio ricevuto';

  @override
  String get settings_gpxExportRepeaters =>
      'Esporta ripetitori / server di stanza in GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Esporta ripetitori / roomserver con una posizione in un file GPX.';

  @override
  String get settings_gpxExportContacts => 'Esporta compagni in GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Esporta i compagni con una posizione in un file GPX.';

  @override
  String get settings_gpxExportAll => 'Esporta tutti i contatti in GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Esporta tutti i contatti con una posizione in un file GPX.';

  @override
  String get settings_gpxExportSuccess =>
      'Esportazione del file GPX completata con successo.';

  @override
  String get settings_gpxExportNoContacts => 'Nessun contatto da esportare.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Non supportato sul tuo dispositivo/Sistema Operativo';

  @override
  String get settings_gpxExportError =>
      'Si è verificato un errore durante l\'esportazione.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Posizioni del server ripetitore e della stanza';

  @override
  String get settings_gpxExportChat => 'Posizioni dei compagni';

  @override
  String get settings_gpxExportAllContacts => 'Tutte le posizioni dei contatti';

  @override
  String get settings_gpxExportShareText => 'Dati mappa esportati da MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax esportazione dati mappa GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Ripetitori vicini';

  @override
  String get snrIndicator_lastSeen => 'Ultimo accesso';

  @override
  String get contactsSettings_title => 'Impostazioni dei contatti';

  @override
  String get contactsSettings_autoAddTitle => 'Scoperta automatica';

  @override
  String get contactsSettings_otherTitle =>
      'Altre impostazioni relative ai contatti';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Aggiungere utenti automaticamente';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Consenti al compagno di aggiungere automaticamente gli utenti scoperti.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Aggiungere ripetitori automaticamente';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Consenti al compagno di aggiungere automaticamente i ripetitori scoperti.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Aggiungere automaticamente i server delle stanze';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Consenti al compagno di aggiungere automaticamente i server delle stanze scoperte.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Aggiungere automaticamente i sensori';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Consenti al compagno di aggiungere automaticamente i sensori scoperti';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Sostituisci il più vecchio';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Quando l\'elenco dei contatti è pieno, il contatto più vecchio non tra i preferiti verrà sostituito.';

  @override
  String get discoveredContacts_Title => 'Contatti scoperti';

  @override
  String get discoveredContacts_noMatching => 'Nessun contatto corrispondente';

  @override
  String get listFilter_searchHint => 'Cerca...';

  @override
  String get discoveredContacts_searchHint => 'Cerca contatti scoperti';

  @override
  String get discoveredContacts_contactAdded => 'Contatto aggiunto';

  @override
  String get discoveredContacts_addContact => 'Aggiungi contatto';

  @override
  String get discoveredContacts_copyContact => 'Copia contatto negli appunti';

  @override
  String get discoveredContacts_deleteContact => 'Elimina Contatto';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Eliminare tutti i contatti scoperti';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Sei sicuro di voler eliminare tutti i contatti scoperti?';

  @override
  String get chat_sendCooldown =>
      'Si prega di attendere un momento prima di inviare nuovamente.';

  @override
  String get chat_notConnected =>
      'Non connesso a una radio. Messaggio non inviato.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Vai al messaggio più vecchio non letto';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Quando si apre una chat con messaggi non letti, scorrete verso l\'alto fino al primo messaggio non letto, invece che al più recente.';

  @override
  String get appSettings_languageHu => 'Ungherese';

  @override
  String get appSettings_languageJa => 'Giapponese';

  @override
  String get appSettings_languageKo => 'Coreano';

  @override
  String get radioStats_screenTitle => 'Statistiche radio';

  @override
  String get radioStats_notConnected =>
      'Connettiti a un dispositivo per visualizzare le statistiche radio.';

  @override
  String get radioStats_firmwareTooOld =>
      'Le statistiche radio richiedono il firmware versione 8 o successiva.';

  @override
  String get radioStats_waiting => 'In attesa dei dati…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Livello di rumore: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Ultimo valore RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Ultimo SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Tempo di trasmissione in diretta (totale): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Tempo di trasmissione RX (totale): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Livello di rumore (dBm) misurato su campioni recenti.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Livello di rumore: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Recupero delle statistiche radio…';

  @override
  String get radioStats_settingsTile => 'Statistiche radio';

  @override
  String get radioStats_settingsSubtitle =>
      'Livello di rumore, RSSI, rapporto segnale/rumore (SNR) e tempo di trasmissione';

  @override
  String get translation_title => 'Traduzione';

  @override
  String get translation_enableTitle => 'Abilitare la traduzione';

  @override
  String get translation_enableSubtitle =>
      'Tradurre i messaggi in arrivo e consentire la traduzione preventiva prima dell\'invio.';

  @override
  String get translation_composerTitle => 'Tradurre prima di inviare';

  @override
  String get translation_composerSubtitle =>
      'Controlla lo stato predefinito dell\'icona di traduzione del compositore.';

  @override
  String get translation_targetLanguage => 'Lingua di destinazione';

  @override
  String get translation_useAppLanguage => 'Utilizza la lingua dell\'app';

  @override
  String get translation_downloadedModelLabel => 'Modello scaricato';

  @override
  String get translation_presetModelLabel =>
      'Modello predefinito di Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL del modello manuale';

  @override
  String get translation_downloadModel => 'Scarica il modello';

  @override
  String get translation_downloading => 'Inizio download...';

  @override
  String get translation_working => 'Lavoro...';

  @override
  String get translation_stop => 'Smetta';

  @override
  String get translation_mergingChunks =>
      'Unione dei frammenti scaricati in un unico file...';

  @override
  String get translation_downloadedModels => 'Modelli scaricati';

  @override
  String get translation_deleteModel => 'Elimina modello';

  @override
  String get translation_modelDownloaded => 'Modello di traduzione scaricato.';

  @override
  String get translation_downloadStopped => 'Il download è stato interrotto.';

  @override
  String translation_downloadFailed(String error) {
    return 'Download fallito: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Inserite innanzitutto l\'URL del modello.';

  @override
  String get scanner_linuxPairingShowPin => 'Mostra PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Nascondi il PIN';

  @override
  String get scanner_linuxPairingPinTitle =>
      'PIN per l\'accoppiamento Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Inserire il codice PIN per $deviceName (lasciare vuoto se non presente).';
  }

  @override
  String get translation_messageTranslation => 'Traduzione del messaggio';

  @override
  String get translation_translateBeforeSending => 'Tradurre prima di inviare';

  @override
  String get translation_composerEnabledHint =>
      'I messaggi verranno tradotti prima di essere inviati.';

  @override
  String get translation_composerDisabledHint =>
      'Invia messaggi utilizzando la lingua originale, scritta.';

  @override
  String translation_translateTo(String language) {
    return 'Tradurre in $language';
  }

  @override
  String get translation_translationOptions => 'Opzioni di traduzione';

  @override
  String get translation_systemLanguage => 'Lingua del sistema';

  @override
  String get routing_title => 'Instradamento';

  @override
  String routing_route(String route) {
    return 'Percorso salvato: $route';
  }

  @override
  String get routing_noRoute =>
      'nessuno per ora — il prossimo messaggio va in inondazione e ne impara uno';

  @override
  String get routing_auto => 'Automatico';

  @override
  String get routing_autoSubtitle =>
      'Usa il percorso salvato nella radio. Consigliato.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder attivo: prova prima i percorsi appresi';

  @override
  String get routing_flood => 'Sempre in inondazione';

  @override
  String get routing_floodSubtitle => 'Ogni messaggio va a tutta la rete mesh';

  @override
  String get routing_custom => 'Percorso personalizzato';

  @override
  String get routing_customSubtitle => 'Scegli tu i ripetitori';

  @override
  String get routing_forget => 'Azzera percorso';

  @override
  String get routing_forgetDone =>
      'Percorso azzerato. Il prossimo messaggio va in inondazione e ne impara uno nuovo.';

  @override
  String get routing_pathfinder => 'Cosa sa Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Ripetitori che sentono te e questo contatto, e percorsi appresi di andata e ritorno';

  @override
  String get path_direct => 'Diretto — nessun ripetitore';

  @override
  String get path_directSubtitle =>
      'Solo se il contatto sente direttamente questa radio';

  @override
  String get chat_kindFlood => 'inondazione';

  @override
  String get chat_kindDirect => 'diretto';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'salti',
      one: 'salto',
    );
    return 'percorso ($count $_temp0)';
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
  String get chat_statusQueued => 'In coda';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Nessun ripetitore ti ha sentito. Riproverà quando uno sarà in portata.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'La radio di $name invia codici ripetitore corti (1 byte). Pathfinder non può apprendere percorsi verso questo contatto finché la sua radio non usa codici da 2 byte.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Invio · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Nuovo tentativo · $kind · tentativo $attempt di $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Consegnato · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Consegnato al tentativo $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Consegnato in ritardo · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Consegnato · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'tentativi',
      one: 'tentativo',
    );
    return 'Fallito dopo $attempts $_temp0 · tocca per reinviare';
  }

  @override
  String get chat_statusFailedShort => 'Fallito · tocca per reinviare';

  @override
  String get chat_resendingByFlood => 'Reinvio in inondazione';

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
  String get settings_pathGraph => 'Pathfinder (sperimentale)';

  @override
  String get settings_pathGraphSubtitle =>
      'Apprende percorsi da tutto ciò che la radio sente e prova prima i migliori quando invii un DM. Un\'icona percorso ambra indica un messaggio inviato su un percorso di Pathfinder.';

  @override
  String get map_routeAndTrace => 'Percorso e traccia';

  @override
  String get map_pathfinderTrace => 'Traccia andata e ritorno';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Andata sul miglior percorso di Pathfinder, ritorno sul suo miglior percorso di ritorno';

  @override
  String get map_routeBackMirrored =>
      'Nessun percorso di ritorno ancora noto — si torna per la stessa strada';

  @override
  String get map_traceHelpTitle => 'Pulsanti della traccia percorso';

  @override
  String get map_traceHelpCustom => 'Scrivi o scegli tu i ripetitori.';

  @override
  String get map_traceHelpRun =>
      'Invia una traccia lungo i ripetitori toccati, solo andata.';

  @override
  String get map_traceHelpThereAndBack => 'Andata e ritorno';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Invia la traccia all\'andata, poi al ritorno sugli stessi ripetitori in ordine inverso.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder sceglie il percorso migliore attraverso gli ultimi due ripetitori toccati, e il percorso migliore per tornare da te. Il risultato insegna a Pathfinder quali collegamenti funzionano davvero. Servono due ripetitori toccati.';

  @override
  String get map_traceHelpRemoveLast =>
      'Toglie l\'ultimo ripetitore dal percorso.';

  @override
  String get map_traceHelpCancel =>
      'Interrompe la costruzione della traccia. Mostrato prima di toccare qualsiasi ripetitore.';

  @override
  String get chat_resendingByRoute => 'Reinvio tramite il percorso impostato';

  @override
  String get room_mute => 'Silenzia stanza';

  @override
  String get room_unmute => 'Riattiva stanza';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'membro';

  @override
  String get room_roleReadOnly => 'sola lettura';

  @override
  String room_clockOff(int minutes) {
    return 'L\'orologio della stanza è sfasato di circa $minutes min — gli orari dei messaggi possono essere errati';
  }

  @override
  String get room_fixClock => 'Correggi orologio';

  @override
  String get room_clockSyncSent =>
      'Sincronizzazione orologio inviata alla stanza';

  @override
  String get room_readOnlyNotice =>
      'Sola lettura: la stanza non ha accettato la tua password, i tuoi messaggi non raggiungeranno gli altri membri.';

  @override
  String get room_postAnnouncement => 'Pubblica annuncio';

  @override
  String get room_postAnnouncementSubtitle =>
      'Invia un messaggio della stanza stessa a tutti i membri';

  @override
  String get room_announcementSent => 'Annuncio pubblicato';

  @override
  String get room_announcementFailed =>
      'Pubblicazione dell\'annuncio non riuscita';

  @override
  String get room_users => 'Utenti della stanza';

  @override
  String get room_usersSubtitle => 'Vedi gli admin e assegna i ruoli';

  @override
  String get room_usersAdminsNote =>
      'La stanza elenca solo i suoi admin. I membri con la password della stanza non compaiono.';

  @override
  String get room_usersLoadFailed =>
      'Impossibile caricare l\'elenco degli admin';

  @override
  String get room_setUserRole => 'Assegna ruolo';

  @override
  String get room_removeAccess => 'Rimuovi accesso';

  @override
  String get room_removeOnlyUnknown =>
      'Questo utente non è nei tuoi contatti: può solo essere rimosso, non modificato.';

  @override
  String get room_roleUpdated => 'Ruolo aggiornato';

  @override
  String get room_roleUpdateFailed => 'Cambio ruolo non riuscito';

  @override
  String get room_postsStored => 'Messaggi memorizzati';

  @override
  String get room_postsDelivered => 'Messaggi consegnati';

  @override
  String get room_reloadPosts => 'Ricarica messaggi recenti';

  @override
  String get room_reloadPostsExplain =>
      'Chiede alla stanza di inviare di nuovo i messaggi recenti (ne conserva fino a 32). Ti verrà chiesta la password della stanza. I messaggi già presenti restano.';

  @override
  String get room_reloadFailed =>
      'Impossibile ripristinare la stanza sulla radio';

  @override
  String get companionCli_title => 'Riga di comando';

  @override
  String get companionCli_settingsSubtitle =>
      'Digita comandi di testo per questa radio';

  @override
  String get companionCli_rebooting => 'Riavvio della radio…';

  @override
  String get companionCli_cancelled => 'Annullato';

  @override
  String get companionCli_poweringOff => 'Spegnimento della radio…';

  @override
  String get companionCli_noReply => 'Nessuna risposta dalla radio. Riprova.';

  @override
  String get companionCli_powerOffTitle => 'Spegnere la radio?';

  @override
  String get companionCli_powerOffBody =>
      'Resta spenta finché non premi il suo pulsante o la colleghi all\'alimentazione.';

  @override
  String get companionCli_powerOff => 'Spegni';

  @override
  String get companionCli_quickBoard => 'Scheda';

  @override
  String get companionCli_quickWifiStatus => 'Stato WiFi';

  @override
  String get companionCli_quickWifiAddress => 'Indirizzo WiFi';

  @override
  String get companionCli_helpBoard =>
      'Mostra produttore e modello della scheda.';

  @override
  String get companionCli_helpReboot => 'Riavvia la radio.';

  @override
  String get companionCli_helpPowerOff => 'Spegne la radio.';

  @override
  String get companionCli_helpSetPin =>
      'Imposta il PIN di associazione Bluetooth. Si applica dopo un riavvio.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Imposta le ore da aggiungere a UTC per l\'orologio sullo schermo della radio (da -12 a +14).';

  @override
  String get companionCli_helpSetTx =>
      'Imposta la potenza di trasmissione in dBm. Si applica subito.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Imposta la soglia di interferenza in dB. 0 disattiva il rilevamento delle interferenze.';

  @override
  String get companionCli_helpSetCad =>
      'Ascolta se ci sono altre radio prima di trasmettere (rilevamento di attività sul canale).';

  @override
  String get companionCli_helpSetRxGain =>
      'Guadagno di ricezione potenziato, sulle radio SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Byte per ripetitore in un percorso: 0 = 1 byte, 1 = 2 byte, 2 = 3 byte.';

  @override
  String get companionCli_helpWifiStatus =>
      'Mostra se la radio è connessa alla rete WiFi.';

  @override
  String get companionCli_helpWifiIp =>
      'Mostra l\'indirizzo della radio sulla rete WiFi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Imposta il nome della rete WiFi. Si applica dopo un riavvio.';

  @override
  String get companionCli_helpWifiPwd =>
      'Imposta la password WiFi. Si applica dopo un riavvio.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Attiva (1) o disattiva (0) il WiFi. Si applica dopo un riavvio.';

  @override
  String get companionCli_helpWifiClear =>
      'Dimentica la rete WiFi. Si applica dopo un riavvio.';

  @override
  String get companionCli_remoteNoReply =>
      'Nessuna risposta. L\'altra radio richiede il firmware 1.18 o successivo e deve permetterti di usare la sua riga di comando.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Inviato. Una radio non risponde a un riavvio o a uno spegnimento.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name ha provato a usare la riga di comando della tua radio: «$command». Non è stato consentito.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Ha provato a usare la riga di comando della tua radio: «$command». Non è stato consentito.';
  }

  @override
  String get contact_remoteCli => 'Consenti riga di comando remota';

  @override
  String get contact_remoteCliSubtitle =>
      'Permette a questo contatto di eseguire comandi sulla tua radio';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Lasciare che $name controlli la tua radio?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name potrà cambiare le impostazioni della tua radio, leggere la tua password WiFi, rinominare la radio e riavviarla o spegnerla. Consentilo solo a qualcuno di cui ti fidi completamente.';
  }

  @override
  String get contact_remoteCliAllow => 'Consenti';

  @override
  String get connection_secondApp =>
      'Un\'altra app è connessa a questa radio. Messaggi e impostazioni possono confondersi. Chiudi l\'altra app.';

  @override
  String get wifi_title => 'WiFi';

  @override
  String get wifi_settingsSubtitle => 'Rete, password e connessione';

  @override
  String get wifi_use => 'Usa WiFi';

  @override
  String get wifi_networkName => 'Nome rete';

  @override
  String get wifi_password => 'Password';

  @override
  String get wifi_passwordUnchanged => 'Invariata';

  @override
  String get wifi_showPassword => 'Mostra password';

  @override
  String get wifi_nameMissing => 'Inserisci il nome della rete';

  @override
  String get wifi_nameTooLong =>
      'Il nome della rete è troppo lungo (massimo 32 byte)';

  @override
  String get wifi_passwordTooLong =>
      'La password è troppo lunga (massimo 63 byte)';

  @override
  String get wifi_savedRestart =>
      'Salvato. Le modifiche al WiFi si applicano dopo il riavvio della radio.';

  @override
  String get wifi_forget => 'Dimentica rete';

  @override
  String get wifi_forgetConfirm =>
      'Dimenticare questa rete WiFi? La radio smetterà di usare il WiFi dopo il riavvio.';

  @override
  String wifi_notAccepted(String reply) {
    return 'La radio non l\'ha accettato: $reply';
  }

  @override
  String get wifi_noReply => 'Nessuna risposta dalla radio. Riprova.';

  @override
  String get wifi_restartTitle => 'Riavviare la radio?';

  @override
  String get wifi_later => 'Più tardi';

  @override
  String get wifi_loadFailed =>
      'Impossibile leggere le impostazioni WiFi dalla radio.';

  @override
  String wifi_connectedTo(String address) {
    return 'Connesso · $address';
  }

  @override
  String get wifi_notConnected => 'Non connesso al WiFi';

  @override
  String wifi_portNote(int port) {
    return 'Le app sulla stessa rete possono connettersi sulla porta $port';
  }

  @override
  String get wifi_connectOverWifi => 'Connetti tramite WiFi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax si disconnetterà da questa radio e aprirà la schermata TCP con $address, porta $port già compilati. Lì tocca Connetti.';
  }

  @override
  String get wifi_noteRestart =>
      'Le modifiche si applicano dopo il riavvio della radio.';

  @override
  String get wifi_noteSecurity =>
      'Chiunque sulla tua rete WiFi può connettersi alla radio sulla porta 5000. Non serve alcuna password.';

  @override
  String get wifi_noteBattery =>
      'Il WiFi tiene sveglia la radio, quindi la batteria si scarica più in fretta.';

  @override
  String get wifi_noteWrongPassword =>
      'Se la password è sbagliata, la radio riprova ogni pochi secondi. Il Bluetooth continua a funzionare.';

  @override
  String get room_selfDemoteWarning =>
      'Stai cambiando il tuo stesso accesso. Se rinunci al ruolo di admin, solo la console della stanza può restituirtelo.';

  @override
  String get scanner_offlineMaps => 'Mappe offline';

  @override
  String get appSettings_offlineMaps => 'Mappe offline';

  @override
  String get appSettings_offlineMapsNone => 'Nessuna scaricata';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regioni',
      one: '1 regione',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aree di carte nautiche',
      one: '1 area di carte nautiche',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aggiornamenti disponibili',
      one: '1 aggiornamento disponibile',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Scarica le mappe solo con Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'I download delle mappe attendono una connessione Wi‑Fi';

  @override
  String get offlineMaps_title => 'Mappe offline';

  @override
  String get offlineMaps_tabMaps => 'Mappe';

  @override
  String get offlineMaps_tabCharts => 'Carte nautiche';

  @override
  String get offlineMaps_chartsNotice => 'Non per la navigazione · Perché?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Suggerimento · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Aree di carte per costa';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aree',
      one: '1 area',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Scaricate: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Selezionate: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Seleziona tutto';

  @override
  String get offlineMaps_clearSelection => 'Cancella';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Anche in $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Non ancora disponibile';

  @override
  String get offlineMaps_chartsHint =>
      'Le carte nautiche NOAA si scelgono per costa, nella scheda Carte nautiche.';

  @override
  String offlineMaps_chartsName(String area) {
    return 'Carte nautiche NOAA $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count aree',
      one: '1 area',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Scaricate';

  @override
  String get offlineMaps_refresh => 'Cerca nuove mappe';

  @override
  String get offlineMaps_loading => 'Caricamento delle mappe disponibili…';

  @override
  String get offlineMaps_serverError =>
      'Impossibile raggiungere il server delle mappe';

  @override
  String get offlineMaps_unavailable => 'Nessuna mappa ancora disponibile';

  @override
  String get offlineMaps_unavailableHint => 'Riprova più tardi.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Nessuna carta nautica NOAA ancora disponibile';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Elenco del $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Aggiorna MeshTrax per avere le mappe più recenti.';

  @override
  String get offlineMaps_world => 'Mondo';

  @override
  String get offlineMaps_suggested => 'Suggerimenti';

  @override
  String get offlineMaps_regions => 'Regioni';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regioni in $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count all\'interno';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size di mappe offline su questo dispositivo';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Aggiornamenti ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Aggiorna tutto ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Download in corso';

  @override
  String get offlineMaps_update => 'Aggiorna';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Scaricato il $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Aggiornamento disponibile';

  @override
  String get offlineMaps_otherFiles => 'Altri file di mappa';

  @override
  String get offlineMaps_emptyTitle => 'Ancora nessuna mappa offline';

  @override
  String get offlineMaps_emptyBody =>
      'Scarica una regione per usare la mappa senza connessione.';

  @override
  String get offlineMaps_findMaps => 'Trova mappe';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Eliminare $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Libera $size. Potrai scaricarlo di nuovo più tardi.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return 'Eliminato: $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done di $total';
  }

  @override
  String get offlineMaps_kindMap => 'Mappa';

  @override
  String get offlineMaps_kindMapDetail =>
      'Strade, sentieri e luoghi OpenStreetMap';

  @override
  String get offlineMaps_kindContours => 'Curve di livello';

  @override
  String get offlineMaps_kindContoursDetail => 'Linee di quota';

  @override
  String get offlineMaps_kindUsgs => 'Mappa topografica USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Sentieri, corsi d\'acqua, riserve';

  @override
  String get offlineMaps_kindTerrain => 'Ombreggiatura del rilievo';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Colline e montagne, ombreggiate sotto la mappa';

  @override
  String get offlineMaps_kindCharts => 'Carte nautiche NOAA';

  @override
  String get offlineMaps_usOnly => 'Solo Stati Uniti';

  @override
  String offlineMaps_download(String size) {
    return 'Scarica ($size)';
  }

  @override
  String get offlineMaps_downloadTotal => 'Scarica';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Download pesante ($size). Usa il Wi‑Fi e tieni il dispositivo in carica.';
  }

  @override
  String get offlineMaps_waiting => 'In attesa…';

  @override
  String get offlineMaps_checking => 'Verifica del download…';

  @override
  String get offlineMaps_retrying => 'Nuovo tentativo…';

  @override
  String offlineMaps_failed(String error) {
    return 'Download non riuscito: $error';
  }

  @override
  String get offlineMaps_pause => 'Pausa';

  @override
  String get offlineMaps_resume => 'Riprendi';

  @override
  String get offlineMaps_deleteRegion => 'Elimina regione';

  @override
  String get offlineMaps_notInCatalogue => 'Non disponibile per questa regione';

  @override
  String get offlineMaps_notificationRunning => 'Download della mappa';

  @override
  String get offlineMaps_notificationPaused => 'Download della mappa in pausa';

  @override
  String get offlineMaps_notificationFailed =>
      'Download della mappa non riuscito';

  @override
  String get offlineMaps_clearTileCache => 'Svuota la cache delle mappe online';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Rimuovere i riquadri di mappa online salvati durante la consultazione? Le mappe scaricate restano.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Cache delle mappe online svuotata';

  @override
  String get map_notForNavigation => 'Non per la navigazione';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax disegna queste carte dai dati NOAA per aiutarti a vedere l\'acqua intorno alle tue radio e a pianificare. Non sono carte ufficiali. Non usarle per navigare.';

  @override
  String get map_chartsNoticeWhy => 'Perché:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Diventano obsolete. NOAA corregge continuamente le sue carte; una carta scaricata resta com\'è finché non la aggiorni in Mappe offline.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Omettono delle cose. Molti simboli, settori dei fari e note non vengono disegnati, e alcune etichette compaiono solo ingrandendo.';

  @override
  String get map_chartsNoticePositions =>
      'Le posizioni possono essere sbagliate o vecchie. Il GPS può sbagliare di 10 m (30 ft) o più, e un nodo si trova solo dove ha comunicato l\'ultima volta.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax non è un plotter cartografico certificato.';

  @override
  String get map_chartsNoticeUse =>
      'Per navigare, usa carte NOAA ufficiali e aggiornate (cartacee, o ENC NOAA in un plotter cartografico certificato) con gli ultimi Avvisi ai naviganti.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail =>
      'Scarica una regione per vedere i dettagli';

  @override
  String get map_zoomInForOfflineMap =>
      'Ingrandisci per vedere la tua mappa offline';

  @override
  String get map_noCharts => 'Nessuna carta qui';

  @override
  String get map_myLocation => 'La mia posizione';

  @override
  String get map_zoomIn => 'Ingrandisci';

  @override
  String get map_zoomOut => 'Riduci';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS attivo';

  @override
  String get gps_off => 'GPS spento';

  @override
  String get gps_onHint => 'La radio aggiorna la sua posizione dal GPS.';

  @override
  String get gps_offHint =>
      'Spento fa risparmiare batteria alla radio. All\'accensione può impiegare qualche minuto a trovare la tua posizione.';

  @override
  String get gps_asking => 'Richiesta alla radio...';

  @override
  String get gps_noPosition =>
      'Ancora nessuna posizione. All\'aperto, la prima può richiedere qualche minuto.';

  @override
  String get gps_position => 'Posizione';

  @override
  String get gps_altitude => 'Altitudine';

  @override
  String gps_readAgo(String ago) {
    return 'Letta dalla radio $ago fa';
  }

  @override
  String get gps_turnOnTitle => 'Attivare il GPS?';

  @override
  String get gps_turnOnBody =>
      'Il GPS della radio è spento. All\'accensione può impiegare qualche minuto a trovare la tua posizione.';

  @override
  String get gps_turnOn => 'Attiva';

  @override
  String get gps_notNow => 'Non ora';

  @override
  String get map_zoomInForCharts => 'Ingrandisci per vedere le tue carte';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Scarica $region · $size';
  }

  @override
  String get mapLayers_title => 'Livelli mappa';

  @override
  String get mapLayers_mapType => 'Tipo di mappa';

  @override
  String get mapLayers_standard => 'Standard';

  @override
  String get mapLayers_usgs => 'Topografica USGS';

  @override
  String get mapLayers_charts => 'Carte nautiche';

  @override
  String get mapLayers_notDownloaded => 'Non scaricata';

  @override
  String get mapLayers_offlineOnly => 'Solo offline';

  @override
  String get mapLayers_details => 'Dettagli mappa';

  @override
  String get mapLayers_contours => 'Curve di livello';

  @override
  String get mapLayers_hillShading => 'Ombreggiatura del rilievo';

  @override
  String get mapLayers_dark => 'Mappa scura';

  @override
  String get mapLayers_downloadedAreas => 'Aree scaricate';

  @override
  String get mapLayers_nodes => 'Nodi';

  @override
  String get mapLayers_pins => 'Segnaposti';

  @override
  String get mapLayers_guessed => 'Posizioni stimate';

  @override
  String get mapLayers_moreFilters => 'Altri filtri';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Ultimo accesso, prefisso chiave, sovrapposizioni';

  @override
  String get map_legend => 'Legenda';

  @override
  String get scanner_map => 'Mappa';

  @override
  String get structured_openMap => 'Apri mappa';

  @override
  String get structured_addToCalendar => 'Aggiungi al calendario';

  @override
  String get structured_details => 'Dettagli';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Evento';

  @override
  String get structured_notice => 'Avviso';

  @override
  String get structured_allDay => 'Tutto il giorno';

  @override
  String get structured_calendarFailed => 'Impossibile aprire il calendario';

  @override
  String get structured_today => 'Oggi';

  @override
  String get structured_tomorrow => 'Domani';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Tra $count giorni',
      one: 'Tra 1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Passato';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Giorno $day di $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giorni',
      one: '1 giorno',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Data di fine';

  @override
  String get dialog_eventSameDay => 'Stesso giorno';

  @override
  String get structured_map => 'Mappa';

  @override
  String get structured_navigate => 'Indicazioni';

  @override
  String get structured_channel => 'Canale';

  @override
  String get structured_contact => 'Contatto';

  @override
  String get structured_room => 'Stanza';

  @override
  String get structured_repeater => 'Ripetitore';

  @override
  String get structured_sensor => 'Sensore';

  @override
  String get structured_joinChannel => 'Unisciti al canale';

  @override
  String get structured_addContact => 'Aggiungi contatto';

  @override
  String get structured_addRoom => 'Aggiungi stanza';

  @override
  String get structured_addRepeater => 'Aggiungi ripetitore';

  @override
  String get structured_addSensor => 'Aggiungi sensore';

  @override
  String get structured_open => 'Apri';

  @override
  String get structured_added => 'Aggiunto';

  @override
  String get tray_add => 'Aggiungi';

  @override
  String get tray_myLocation => 'La mia posizione';

  @override
  String get tray_pointOnMap => 'Punto sulla mappa';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Evento';

  @override
  String get tray_notice => 'Avviso';

  @override
  String get tray_noRadioPosition =>
      'La tua radio non ha ancora una posizione. Scegline una sulla mappa.';

  @override
  String get dialog_insert => 'Inserisci';

  @override
  String get dialog_eventTitle => 'Titolo';

  @override
  String get dialog_eventDate => 'Data';

  @override
  String get dialog_eventStart => 'Inizio';

  @override
  String get dialog_eventEnd => 'Fine';

  @override
  String get dialog_eventNoEnd => 'Nessun orario di fine';

  @override
  String get dialog_eventPlace => 'Luogo (facoltativo)';

  @override
  String get dialog_pickOnMap => 'Scegli sulla mappa';

  @override
  String get dialog_sosTitle => 'Invia SOS';

  @override
  String get dialog_sosText => 'Cosa è successo?';

  @override
  String get dialog_noticeTitle => 'Avviso';

  @override
  String get dialog_noticeText => 'Cosa dovrebbero sapere tutti?';

  @override
  String get dialog_labelTitle => 'Punto sulla mappa';

  @override
  String get dialog_note => 'Nota (facoltativa)';

  @override
  String get paste_convertLocation =>
      'Sembra un link di mappe. Convertirlo in una Posizione?';

  @override
  String get paste_convertEvent =>
      'Sembra un evento di calendario condiviso. Convertirlo in un Evento?';

  @override
  String get paste_convert => 'Converti';

  @override
  String get paste_resolving => 'Risoluzione del link…';

  @override
  String get paste_resolveFailed => 'Impossibile risolvere il link';

  @override
  String get pinned_dismiss => 'Ignora';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Unirsi al canale $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Sei già in $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Ti sei unito a $name';
  }

  @override
  String get map_pickPositionHint =>
      'Tocca la mappa per scegliere una posizione';

  @override
  String get map_legendMesh => 'Rete mesh';

  @override
  String get chartLegend_title => 'Simboli delle carte nautiche';

  @override
  String get chartLegend_sectionBuoys => 'Boe e mede';

  @override
  String get chartLegend_sectionLights => 'Luci';

  @override
  String get chartLegend_sectionHazards => 'Pericoli';

  @override
  String get chartLegend_sectionTides => 'Maree e correnti';

  @override
  String get chartLegend_sectionDepths => 'Profondità e fondale';

  @override
  String get chartLegend_sectionAreas => 'Zone, corsie e linee';

  @override
  String get chartLegend_sectionLandmarks => 'Punti cospicui';

  @override
  String get chartLegend_sectionAbbreviations => 'Abbreviazioni';

  @override
  String get chartLegend_chartNo1 => 'Tutti i simboli: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Boa cilindrica verde';

  @override
  String get chartLegend_portBuoyHint =>
      'Lasciala alla tua sinistra entrando dal mare';

  @override
  String get chartLegend_starboardBuoy => 'Boa conica rossa';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Lasciala alla tua destra entrando: rosso a destra al rientro';

  @override
  String get chartLegend_junctionBuoy => 'Boa a fasce';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Biforcazione del canale: considerala del colore della fascia superiore';

  @override
  String get chartLegend_safeWaterBuoy => 'Strisce rosse e bianche';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Acque sicure tutt\'intorno, spesso all\'ingresso di un canale';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Fasce nere e rosse';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Piccolo pericolo con acque sicure intorno: stanne lontano';

  @override
  String get chartLegend_specialBuoy => 'Boa gialla';

  @override
  String get chartLegend_specialBuoyHint =>
      'Uso speciale, non per orientarsi: ancoraggio, cavo, ricerca';

  @override
  String get chartLegend_cardinalBuoy => 'Nera e gialla';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Segnale cardinale: passa dal lato da cui prende il nome (raro negli USA)';

  @override
  String get chartLegend_mooringBuoy => 'Boa d\'ormeggio';

  @override
  String get chartLegend_portBeacon => 'Meda quadrata verde';

  @override
  String get chartLegend_portBeaconHint =>
      'Come una boa verde: lasciala a sinistra entrando';

  @override
  String get chartLegend_starboardBeacon => 'Meda triangolare rossa';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Come una boa rossa: lasciala a destra entrando';

  @override
  String get chartLegend_otherBeacon => 'Meda a rombo';

  @override
  String get chartLegend_otherBeaconHint =>
      'Informazione o avvertimento, non un lato del canale';

  @override
  String get chartLegend_beaconTower => 'Torre luminosa o struttura di meda';

  @override
  String get chartLegend_topmark => 'Miraglio';

  @override
  String get chartLegend_topmarkHint =>
      'La forma in cima a un segnale ne precisa il significato';

  @override
  String get chartLegend_light => 'Luce';

  @override
  String get chartLegend_lightHint =>
      'Il bagliore magenta indica una luce; l\'etichetta dice come lampeggia';

  @override
  String get chartLegend_lightExample => 'Lampi verdi, ogni 4 secondi';

  @override
  String get chartLegend_lightExampleHint =>
      'Etichetta di una luce: ritmo, colore, poi periodo';

  @override
  String get chartLegend_lightFixed => 'Fissa';

  @override
  String get chartLegend_lightFixedHint => 'Una luce costante';

  @override
  String get chartLegend_lightFlashing => 'A lampi';

  @override
  String get chartLegend_lightFlashingHint =>
      'Lampi brevi, pause di buio più lunghe';

  @override
  String get chartLegend_lightGroup => 'A gruppi di lampi';

  @override
  String get chartLegend_lightGroupHint => 'Lampi a gruppi, qui da 2, poi buio';

  @override
  String get chartLegend_lightComposite => 'Gruppi composti';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 lampi, poi 1: indica una biforcazione del canale';

  @override
  String get chartLegend_lightQuick => 'Scintillante';

  @override
  String get chartLegend_lightQuickHint => 'Circa un lampo al secondo';

  @override
  String get chartLegend_lightIsophase => 'Isofase';

  @override
  String get chartLegend_lightIsophaseHint => 'Luce e buio di uguale durata';

  @override
  String get chartLegend_lightOcculting => 'Intermittente';

  @override
  String get chartLegend_lightOccultingHint => 'Accesa più a lungo che spenta';

  @override
  String get chartLegend_lightMorse => 'Codice Morse A';

  @override
  String get chartLegend_lightMorseHint => 'Breve, lungo: acque sicure';

  @override
  String get chartLegend_lightAlternating => 'Alternata';

  @override
  String get chartLegend_lightAlternatingHint => 'Cambia colore';

  @override
  String get chartLegend_lightColours => 'Bianca, rossa, verde, gialla';

  @override
  String get chartLegend_lightPeriod => 'Periodo';

  @override
  String get chartLegend_lightPeriodHint => 'Secondi per un ciclo completo';

  @override
  String get chartLegend_rock => 'Scoglio sommerso';

  @override
  String get chartLegend_rockHint =>
      'Sempre coperto, ma può essere poco profondo';

  @override
  String get chartLegend_rockAwash => 'Scoglio a fior d\'acqua';

  @override
  String get chartLegend_rockAwashHint =>
      'Vicino alla superficie con la bassa marea';

  @override
  String get chartLegend_rockCovers => 'Scoglio che copre e scopre';

  @override
  String get chartLegend_rockCoversHint =>
      'Emerge con la bassa marea, coperto con l\'alta marea';

  @override
  String get chartLegend_wreckDangerous => 'Relitto pericoloso';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Abbastanza poco profondo da urtarlo';

  @override
  String get chartLegend_wreck => 'Relitto';

  @override
  String get chartLegend_wreckHint =>
      'Abbastanza profondo per le barche in superficie; non ancorare';

  @override
  String get chartLegend_wreckShowing => 'Relitto emergente';

  @override
  String get chartLegend_wreckShowingHint => 'Una parte sporge dall\'acqua';

  @override
  String get chartLegend_obstruction => 'Ostruzione';

  @override
  String get chartLegend_obstructionHint =>
      'Qualcosa sul fondo; la sua profondità, se nota';

  @override
  String get chartLegend_foulGround => 'Fondale sporco';

  @override
  String get chartLegend_foulGroundHint =>
      'Si può passare sopra, ma non ancorare né pescare a strascico';

  @override
  String get chartLegend_hazardArea => 'Limite di una zona pericolosa';

  @override
  String get chartLegend_hazardAreaHint =>
      'Scogli, relitti od ostruzioni all\'interno';

  @override
  String get chartLegend_pile => 'Palo o pilone';

  @override
  String get chartLegend_floodStream => 'Corrente di flusso';

  @override
  String get chartLegend_floodStreamHint =>
      'Corrente di marea mentre la marea sale';

  @override
  String get chartLegend_ebbStream => 'Corrente di riflusso';

  @override
  String get chartLegend_ebbStreamHint =>
      'Corrente di marea mentre la marea scende';

  @override
  String get chartLegend_current => 'Corrente';

  @override
  String get chartLegend_currentHint =>
      'Scorre nello stesso verso qualunque sia la marea';

  @override
  String get chartLegend_rips => 'Ribollimenti o vortici';

  @override
  String get chartLegend_ripsHint => 'Acqua agitata e vorticosa';

  @override
  String get chartLegend_breakers => 'Frangenti';

  @override
  String get chartLegend_breakersHint => 'Onde che si rompono sui bassifondi';

  @override
  String get chartLegend_sounding => 'Scandaglio';

  @override
  String get chartLegend_soundingHint => 'Profondità con una bassa marea media';

  @override
  String get chartLegend_depthContour => 'Isobata';

  @override
  String get chartLegend_depthContourHint =>
      'L\'etichetta indica la profondità';

  @override
  String get chartLegend_drying => 'Scopre con la bassa marea';

  @override
  String get chartLegend_dredged => 'Canale dragato';

  @override
  String get chartLegend_dredgedHint => 'Mantenuto alla profondità indicata';

  @override
  String get chartLegend_swept => 'Zona rastrellata';

  @override
  String get chartLegend_sweptHint =>
      'Verificata sgombra fino alla profondità indicata';

  @override
  String get chartLegend_unsurveyed => 'Non rilevato';

  @override
  String get chartLegend_unsurveyedHint => 'Nessuna profondità misurata';

  @override
  String get chartLegend_weed => 'Alghe o laminarie';

  @override
  String get chartLegend_restricted => 'Zona ad accesso limitato';

  @override
  String get chartLegend_restrictedHint =>
      'Accesso limitato; i trattini puntano verso l\'interno';

  @override
  String get chartLegend_regulatedLimit => 'Limite di zona regolamentata';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Ancoraggio, zona cavi, zona di tiro e altro: vedi l\'etichetta';

  @override
  String get chartLegend_greyLimit =>
      'Zona di scarico, zona di pesca o allevamento';

  @override
  String get chartLegend_anchorage => 'Ancoraggio';

  @override
  String get chartLegend_anchorBerth => 'Posto di fonda';

  @override
  String get chartLegend_noAnchoring => 'Divieto di ancoraggio';

  @override
  String get chartLegend_caution => 'Zona di attenzione';

  @override
  String get chartLegend_cautionHint => 'Presta particolare attenzione qui';

  @override
  String get chartLegend_trafficLane => 'Corsia di traffico';

  @override
  String get chartLegend_trafficLaneHint =>
      'Grandi navi, senso unico: attraversa ad angolo retto';

  @override
  String get chartLegend_separationZone => 'Zona di separazione';

  @override
  String get chartLegend_separationZoneHint =>
      'Tra le corsie di traffico: non entrare';

  @override
  String get chartLegend_precautionary => 'Zona di precauzione';

  @override
  String get chartLegend_precautionaryHint => 'Le navi convergono: attenzione';

  @override
  String get chartLegend_fairway => 'Canale navigabile';

  @override
  String get chartLegend_fairwayHint => 'Un canale principale';

  @override
  String get chartLegend_track => 'Rotta raccomandata';

  @override
  String get chartLegend_ferry => 'Rotta dei traghetti';

  @override
  String get chartLegend_leadingLine => 'Allineamento';

  @override
  String get chartLegend_leadingLineHint =>
      'Allinea i suoi due segnali per restare nel canale';

  @override
  String get chartLegend_cable => 'Cavo sottomarino';

  @override
  String get chartLegend_cableHint => 'Non ancorare';

  @override
  String get chartLegend_pipeline => 'Condotta sottomarina';

  @override
  String get chartLegend_pipelineHint => 'Non ancorare';

  @override
  String get chartLegend_overhead => 'Cavo aereo';

  @override
  String get chartLegend_overheadHint =>
      'La sua altezza libera è indicata con VC';

  @override
  String get chartLegend_tower => 'Torre';

  @override
  String get chartLegend_windTurbine => 'Turbina eolica';

  @override
  String get chartLegend_chimney => 'Ciminiera';

  @override
  String get chartLegend_mast => 'Traliccio o antenna';

  @override
  String get chartLegend_church => 'Chiesa o campanile';

  @override
  String get chartLegend_flagstaff => 'Asta della bandiera';

  @override
  String get chartLegend_dome => 'Cupola';

  @override
  String get chartLegend_landmark => 'Altro punto cospicuo';

  @override
  String get chartLegend_abbrAnch => 'Ancoraggio';

  @override
  String get chartLegend_abbrWk => 'Relitto';

  @override
  String get chartLegend_abbrBr => 'Frangenti';

  @override
  String get chartLegend_abbrWd => 'Alghe';

  @override
  String get chartLegend_abbrVar => 'Declinazione magnetica';

  @override
  String get chartLegend_abbrVc => 'Altezza libera sotto un ponte o un cavo';

  @override
  String get chartLegend_abbrTr => 'Torre';

  @override
  String get chartLegend_abbrCh => 'Chiesa';

  @override
  String get chartLegend_abbrChy => 'Ciminiera';

  @override
  String get chartLegend_abbrFs => 'Asta della bandiera';

  @override
  String get chartLegend_abbrTk => 'Serbatoio';

  @override
  String get chartLegend_abbrRBn => 'Radiofaro';

  @override
  String get chartLegend_abbrCg => 'Stazione della Guardia Costiera';

  @override
  String get chartLegend_abbrRacon => 'Radarfaro: compare sul radar';

  @override
  String get chartLegend_abbrFog =>
      'Segnale da nebbia: tromba, campana, gong, fischio o sirena';

  @override
  String get chartLegend_abbrVAis => 'Segnale virtuale: visibile solo su AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'Da $from a $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Oltre $depth';
  }

  @override
  String get parkLegend_title => 'Simboli di parchi e sentieri';

  @override
  String get parkLegend_campsite => 'Campeggio';

  @override
  String get parkLegend_picnicSite => 'Area picnic';

  @override
  String get parkLegend_shelter => 'Riparo';

  @override
  String get parkLegend_toilets => 'Bagni';

  @override
  String get parkLegend_drinkingWater => 'Acqua potabile';

  @override
  String get parkLegend_parking => 'Parcheggio';

  @override
  String get parkLegend_viewpoint => 'Punto panoramico';

  @override
  String get parkLegend_attraction => 'Attrazione';

  @override
  String get parkLegend_gate => 'Cancello';

  @override
  String get parkLegend_telephone => 'Telefono';

  @override
  String get parkLegend_information => 'Pannello informativo';

  @override
  String get parkLegend_guidepost => 'Palo segnaletico';

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
}
