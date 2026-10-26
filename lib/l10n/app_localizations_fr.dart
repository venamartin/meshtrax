// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Discussions';

  @override
  String get chats_title => 'Discussions';

  @override
  String get newChat_title => 'Choisir un contact';

  @override
  String newChat_contactCount(int count) {
    return '$count contacts';
  }

  @override
  String get newChat_newContact => 'Nouveau contact';

  @override
  String get newChat_newChannel => 'Nouveau canal';

  @override
  String get newChat_myContacts => 'Mes contacts';

  @override
  String get newChat_discovered => 'Découverts';

  @override
  String get repeaters_title => 'Gérer les répéteurs';

  @override
  String get nav_contacts => 'Contacts';

  @override
  String get nav_channels => 'Canaux';

  @override
  String get nav_map => 'Carte';

  @override
  String get common_cancel => 'Annuler';

  @override
  String get common_syncing_device_info =>
      'Lecture des infos de l\'appareil...';

  @override
  String get common_syncing_contacts => 'Lecture des contacts...';

  @override
  String get common_syncing_channels => 'Lecture des canaux...';

  @override
  String get common_syncing_messages => 'Lecture des messages...';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Connecter';

  @override
  String get common_unknownDevice => 'Appareil inconnu';

  @override
  String get common_save => 'Enregistrer';

  @override
  String get common_delete => 'Supprimer';

  @override
  String get common_deleteAll => 'Supprimer tout';

  @override
  String get common_close => 'Fermer';

  @override
  String get common_edit => 'Modifier';

  @override
  String get common_add => 'Ajouter';

  @override
  String get common_settings => 'Paramètres';

  @override
  String get common_disconnect => 'Déconnecter';

  @override
  String get common_connected => 'Connecté';

  @override
  String get common_disconnected => 'Déconnecté';

  @override
  String get common_connectionLost => 'Connexion perdue. Reconnexion...';

  @override
  String get common_reconnecting => 'Reconnexion...';

  @override
  String get common_create => 'Créer';

  @override
  String get common_continue => 'Continuer';

  @override
  String get common_share => 'Partager';

  @override
  String get common_copy => 'Copier';

  @override
  String get common_retry => 'Réessayer';

  @override
  String get common_hide => 'Masquer';

  @override
  String get common_remove => 'Supprimer';

  @override
  String get common_enable => 'Activer';

  @override
  String get common_disable => 'Désactiver';

  @override
  String get common_reboot => 'Redémarrer';

  @override
  String get common_loading => 'Chargement...';

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
  String get tcpScreenTitle => 'Établir une connexion via TCP';

  @override
  String get tcpHostLabel => 'Adresse IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Port';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected =>
      'Entrez l\'adresse de destination et connectez-vous.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Connexion à $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Une adresse IP est obligatoire.';

  @override
  String get tcpErrorPortInvalid =>
      'La taille du port doit être comprise entre 1 et 65535.';

  @override
  String get tcpErrorUnsupported =>
      'Le protocole TCP n\'est pas pris en charge sur cette plateforme.';

  @override
  String get tcpErrorTimedOut => 'La connexion TCP a expiré.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Échec de la connexion TCP : $error';
  }

  @override
  String get usbScreenTitle => 'Connectez via USB';

  @override
  String get usbScreenSubtitle =>
      'Sélectionnez un périphérique série détecté et connectez-vous directement à votre nœud MeshCore.';

  @override
  String get usbScreenStatus => 'Sélectionnez un périphérique USB';

  @override
  String get usbScreenNote =>
      'La communication série USB est active sur les appareils Android et les plateformes de bureau compatibles.';

  @override
  String get usbScreenEmptyState =>
      'Aucun périphérique USB n\'a été trouvé. Veuillez en brancher un et rafraîchir la page.';

  @override
  String get usbErrorPermissionDenied => 'L\'accès via USB a été refusé.';

  @override
  String get usbErrorDeviceMissing =>
      'Le périphérique USB sélectionné n\'est plus disponible.';

  @override
  String get usbErrorInvalidPort => 'Sélectionnez un périphérique USB valide.';

  @override
  String get usbErrorBusy =>
      'Une autre demande de connexion USB est déjà en cours.';

  @override
  String get usbErrorNotConnected => 'Aucun appareil USB n\'est connecté.';

  @override
  String get usbErrorOpenFailed =>
      'Impossible d\'ouvrir l\'appareil USB sélectionné.';

  @override
  String get usbErrorConnectFailed =>
      'Impossible de se connecter à l\'appareil USB sélectionné.';

  @override
  String get usbErrorUnsupported =>
      'La communication série USB n\'est pas prise en charge sur cette plateforme.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Il manque à cette version sa bibliothèque série USB : les appareils USB ne peuvent pas être ouverts. Réinstallez MeshTrax ou signalez cette version comme défectueuse.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Ce navigateur ne prend pas en charge Web Serial. Utilisez Chrome ou Edge en HTTPS (ou localhost).';

  @override
  String get usbErrorAlreadyActive => 'Une connexion USB est déjà établie.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Aucun appareil USB n\'a été sélectionné.';

  @override
  String get usbErrorPortClosed => 'La connexion USB n\'est pas établie.';

  @override
  String get usbErrorConnectTimedOut =>
      'La connexion a expiré. Assurez-vous que l\'appareil dispose du firmware USB Companion.';

  @override
  String get usbFallbackDeviceName =>
      'Dispositif de communication série sur le Web';

  @override
  String get usbStatus_notConnected => 'Sélectionnez un périphérique USB';

  @override
  String get usbStatus_connecting => 'Connexion au périphérique USB...';

  @override
  String get usbStatus_searching => 'Recherche de périphériques USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Échec de la connexion USB : $error';
  }

  @override
  String get scanner_scanning => 'Recherche de périphériques...';

  @override
  String get scanner_connecting => 'Connexion en cours...';

  @override
  String get scanner_disconnecting => 'Déconnexion...';

  @override
  String get scanner_notConnected => 'Non connecté';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Connecté à $deviceName';
  }

  @override
  String get scanner_showAllDevices => 'Afficher tous les appareils Bluetooth';

  @override
  String get scanner_showMeshCoreOnly =>
      'Afficher uniquement les radios MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'La radio ne répond pas. Elle doit peut-être être appairée : ouvrez les paramètres Bluetooth, ajoutez la radio et saisissez son code PIN, puis réessayez.';

  @override
  String get scanner_pairingFailed =>
      'L\'appairage Bluetooth a été annulé ou a échoué. Vérifiez que rien d\'autre (comme votre téléphone) n\'est connecté à la radio, puis réessayez et saisissez son code PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Échec de la connexion : $error';
  }

  @override
  String get scanner_stop => 'Arrêter';

  @override
  String get scanner_scan => 'Scanner';

  @override
  String get scanner_scanFromImage => 'Scanner depuis une image';

  @override
  String get scanner_noQrFoundInImage =>
      'Aucun QR code valide trouvé dans l\'image';

  @override
  String get scanner_bluetoothOff => 'Le Bluetooth est désactivé.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Veuillez activer le Bluetooth pour rechercher des appareils.';

  @override
  String get scanner_chromeRequired => 'Navigateur Chrome requis';

  @override
  String get scanner_chromeRequiredMessage =>
      'Cette application web nécessite Google Chrome ou un navigateur basé sur Chromium pour le support Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Activer le Bluetooth';

  @override
  String get device_quickSwitch => 'Basculement rapide';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Paramètres';

  @override
  String get settings_deviceInfo => 'Informations du périphérique';

  @override
  String get settings_appSettings => 'Paramètres de l\'application';

  @override
  String get settings_appSettingsSubtitle =>
      'Notifications, messagerie et préférences de carte';

  @override
  String get settings_nodeSettings => 'Paramètres du nœud';

  @override
  String get settings_nodeName => 'Nom du nœud';

  @override
  String get settings_nodeNameNotSet => 'Non défini';

  @override
  String get settings_nodeNameHint => 'Entrer le nom du nœud';

  @override
  String get settings_nodeNameUpdated => 'Nom mis à jour';

  @override
  String get settings_radioSettings => 'Paramètres Radio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Fréquence, puissance, facteur d\'espacement';

  @override
  String get settings_radioSettingsUpdated => 'Paramètres radio mis à jour';

  @override
  String get settings_location => 'Emplacement';

  @override
  String get settings_locationSubtitle => 'Coordonnées GPS';

  @override
  String get settings_locationUpdated => 'Emplacement mis à jour';

  @override
  String get settings_locationBothRequired =>
      'Entrez la latitude et la longitude.';

  @override
  String get settings_locationInvalid => 'Latitude ou longitude invalide.';

  @override
  String get settings_locationGPSEnable => 'Activer le GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Activer la mise à jour automatique de la position via GPS';

  @override
  String get settings_latitude => 'Latitude';

  @override
  String get settings_longitude => 'Longitude';

  @override
  String get settings_contactSettings => 'Paramètres de contact';

  @override
  String get settings_contactSettingsSubtitle =>
      'Paramètres pour l\'ajout de contacts';

  @override
  String get settings_privacyMode => 'Mode de confidentialité';

  @override
  String get settings_privacyModeSubtitle =>
      'Cacher le nom/l\'emplacement dans les annonces';

  @override
  String get settings_privacyModeToggle =>
      'Activer le mode confidentialité pour masquer votre nom et votre localisation dans les annonces.';

  @override
  String get settings_privacyModeEnabled => 'Mode de confidentialité activé';

  @override
  String get settings_privacyModeDisabled =>
      'Mode de confidentialité désactivé';

  @override
  String get settings_privacy => 'Paramètres de confidentialité';

  @override
  String get settings_privacySubtitle => 'Contrôlez les informations partagées';

  @override
  String get settings_privacySettingsDescription =>
      'Choisissez les informations que votre appareil partage avec les autres.';

  @override
  String get settings_denyAll => 'Refuser tout';

  @override
  String get settings_allowByContact => 'Autoriser par drapeaux de contact';

  @override
  String get settings_allowAll => 'Autoriser tout';

  @override
  String get settings_telemetryBaseMode => 'Mode de base Télémétrie';

  @override
  String get settings_telemetryLocationMode =>
      'Mode d\'emplacement de télémétrie';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Mode d\'environnement de télémétrie';

  @override
  String get settings_advertLocation => 'Emplacement de l\'annonce';

  @override
  String get settings_advertLocationSubtitle =>
      'Inclure l\'emplacement dans l\'annonce';

  @override
  String get settings_multiAck => 'Plusieurs accusés de réception';

  @override
  String get settings_telemetryModeUpdated =>
      'Le mode télémétrie a été mis à jour';

  @override
  String get settings_actions => 'Actions';

  @override
  String get settings_sendAdvertisement => 'S\'annoncer';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Présence diffusée maintenant';

  @override
  String get settings_advertisementSent => 'Annonce envoyée';

  @override
  String get settings_syncTime => 'Temps de synchronisation';

  @override
  String get settings_syncTimeSubtitle =>
      'Définir l\'heure de l\'appareil sur l\'heure du téléphone.';

  @override
  String get settings_timeSynchronized => 'Synchronisation temporelle';

  @override
  String get settings_refreshContacts => 'Rafraîchir les Contacts';

  @override
  String get settings_refreshContactsSubtitle =>
      'Recharger la liste des contacts depuis l\'appareil';

  @override
  String get settings_rebootDevice => 'Redémarrer l\'appareil';

  @override
  String get settings_rebootDeviceSubtitle => 'Redémarrer l\'appareil MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Êtes-vous sûr de vouloir redémarrer l\'appareil ? Vous serez déconnecté.';

  @override
  String get settings_debug => 'Déboguer';

  @override
  String get settings_bleDebugLog => 'Journal de débogage BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Commandes BLE, réponses et données brutes';

  @override
  String get settings_appDebugLog => 'Journal de débogage de l\'application';

  @override
  String get settings_appDebugLogSubtitle =>
      'Messages de débogage de l\'application';

  @override
  String get settings_exportDatabase => 'Exporter la base de messages';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Une copie de toutes les discussions et de tous les contacts, pour le débogage. Gardez-la privée.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Base enregistrée dans : $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Échec de l\'export : $error';
  }

  @override
  String get settings_about => 'À propos';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'Projet MeshTrax Source 2026';

  @override
  String get settings_aboutDescription =>
      'Un client Flutter open source pour les appareils de réseau mesh MeshCore LoRa.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Données d\'élévation LOS : Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nom';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'État';

  @override
  String get settings_infoBattery => 'Batterie';

  @override
  String get settings_infoPublicKey => 'Clé Publique';

  @override
  String get settings_infoContactsCount => 'Nombre de contacts';

  @override
  String get settings_infoChannelCount => 'Nombre de canaux';

  @override
  String get settings_presets => 'Préréglages';

  @override
  String get settings_frequency => 'Fréquence (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2 500,0';

  @override
  String get settings_frequencyInvalid => 'Fréquence invalide (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Bande passante';

  @override
  String get settings_spreadingFactor => 'Facteur de répartition (SF)';

  @override
  String get settings_codingRate => 'Taux de codage (CR)';

  @override
  String get settings_txPower => 'TX Puissance (dBm)';

  @override
  String get settings_txPowerInvalid => 'Puissance TX invalide';

  @override
  String get settings_clientRepeat => 'Répétition hors réseau';

  @override
  String get settings_clientRepeatSubtitle =>
      'Permettez à cet appareil de répéter les paquets de données pour les autres.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Pour les transmissions hors réseau, il est nécessaire d\'utiliser les fréquences de 433, 869 ou 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Erreur : $message';
  }

  @override
  String get appSettings_title => 'Paramètres de l\'application';

  @override
  String get appSettings_appearance => 'Apparence';

  @override
  String get appSettings_theme => 'Thème';

  @override
  String get appSettings_themeSystem => 'Défaut système';

  @override
  String get appSettings_themeLight => 'Lumière';

  @override
  String get appSettings_themeDark => 'Sombre';

  @override
  String get appSettings_language => 'Langue';

  @override
  String get appSettings_languageSystem => 'Par défaut du système';

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
  String get appSettings_languageRu => 'Russe';

  @override
  String get appSettings_languageUk => 'Ukrainien';

  @override
  String get appSettings_enableMessageTracing =>
      'Activer le traçage des messages';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Afficher les métadonnées détaillées de routage et de synchronisation des messages';

  @override
  String get appSettings_senderNameColors => 'Noms d\'expéditeurs en couleur';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Donne à chaque expéditeur d\'un canal sa propre couleur de nom. Désactivé, tout le monde a la couleur du thème.';

  @override
  String get appSettings_showTextFormatting =>
      'Afficher la mise en forme du texte';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown dans les messages : **gras**, *italique*, ||texte caché||, titres et liens. Les autres applications MeshCore affichent les caractères bruts.';

  @override
  String get appSettings_notifications => 'Notifications';

  @override
  String get appSettings_enableNotifications => 'Activer les Notifications';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Recevoir des notifications pour les messages et les annonces';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permission de notification refusée';

  @override
  String get appSettings_notificationsEnabled => 'Notifications activées';

  @override
  String get appSettings_notificationsDisabled => 'Notifications désactivées';

  @override
  String get appSettings_messageNotifications => 'Notifications de Messages';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Afficher une notification lors de la réception de nouveaux messages';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notifications des Messages de Canal';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Afficher une notification lors de la réception des messages de canal';

  @override
  String get appSettings_advertisementNotifications =>
      'Notifications d\'annonces';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Afficher une notification lors de la découverte de nouveaux nœuds';

  @override
  String get appSettings_messaging => 'Messagerie';

  @override
  String get appSettings_maxMessageRetries =>
      'Nombre maximal de tentatives de récupération de messages';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Nombre de tentatives de relance avant de marquer un message comme ayant échoué.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Nouveaux essais max. (canal)';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Renvoie jusqu\'à ce nombre de fois tant qu\'aucune répétition n\'est entendue';

  @override
  String get appSettings_battery => 'Batterie';

  @override
  String get appSettings_batteryChemistry => 'Chimie de la batterie';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Définir par appareil ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Connectez un appareil pour choisir';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Affichage de la carte';

  @override
  String get appSettings_showRepeaters => 'Afficher les répéteurs';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Afficher les nœuds répéteurs sur la carte';

  @override
  String get appSettings_showChatNodes => 'Afficher les nœuds de discussion';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Afficher les nœuds de chat sur la carte';

  @override
  String get appSettings_showOtherNodes => 'Afficher d\'autres nœuds';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Afficher d\'autres types de nœuds sur la carte';

  @override
  String get appSettings_timeFilter => 'Filtre du temps';

  @override
  String get appSettings_timeFilterShowAll => 'Afficher tous les nœuds';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Afficher les nœuds des $hours dernières heures';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtre du Temps de la Carte';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Afficher les nœuds découverts dans :';

  @override
  String get appSettings_allTime => 'Tout le temps';

  @override
  String get appSettings_lastHour => 'Dernière heure';

  @override
  String get appSettings_last6Hours => 'Dernières 6 heures';

  @override
  String get appSettings_last24Hours => 'Dernières 24 heures';

  @override
  String get appSettings_lastWeek => 'La semaine dernière';

  @override
  String get appSettings_unitsTitle => 'Unités';

  @override
  String get appSettings_unitsMetric => 'Métrique (m/km)';

  @override
  String get appSettings_unitsImperial => 'Impérial (ft / mi)';

  @override
  String get appSettings_debugCard => 'Déboguer';

  @override
  String get appSettings_appDebugLogging =>
      'Journalisation de débogage de l\'application';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Enregistrez les messages de débogage de l\'application Log pour le dépannage.';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Journalisation de débogage de l\'application activée';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'Le débogage de l\'application est désactivé.';

  @override
  String get appSettings_incrementalContactSync =>
      'Synchronisation incrémentale des contacts';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'À la reconnexion, ne demander à la radio que les contacts modifiés depuis la dernière fois';

  @override
  String get contacts_title => 'Contacts';

  @override
  String get contacts_noContacts => 'Aucun contact trouvé.';

  @override
  String get contacts_shareMyQrCode => 'Partager mon QR code';

  @override
  String get contacts_shareQrCodeDesc =>
      'Permettre aux autres de scanner pour vous ajouter comme contact';

  @override
  String get contacts_contactsWillAppear =>
      'Les contacts apparaîtront lorsque les appareils font leur annonce.';

  @override
  String get contacts_unread => 'Non lu';

  @override
  String get contacts_searchContactsNoNumber => 'Rechercher des contacts...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Rechercher des contacts...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Rechercher $number$str Favoris...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Rechercher $number$str utilisateurs...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Rechercher $number$str Répéteurs...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Rechercher $number$str room server...';
  }

  @override
  String get contacts_noUnreadContacts => 'Aucun contact non lu';

  @override
  String get contacts_noContactsFound => 'Aucun contact ou groupe trouvé.';

  @override
  String get contacts_deleteContact => 'Supprimer le contact';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Voulez-vous vraiment supprimer $contactName ?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Contact $contactName supprimé.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Échec de la suppression de $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Aucun contact ne correspond au filtre.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Supprimer $contactName des contacts ?';
  }

  @override
  String get contacts_manageRepeater => 'Gérer le répéteur';

  @override
  String get contacts_manageRoom => 'Gérer le Room Server';

  @override
  String get contacts_roomLogin => 'Connexion Room Server';

  @override
  String get contacts_openChat => 'Ouverture du Chat';

  @override
  String get contacts_editGroup => 'Modifier le groupe';

  @override
  String get contacts_deleteGroup => 'Supprimer le groupe';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Supprimer $groupName?';
  }

  @override
  String get contacts_newGroup => 'Nouveau Groupe';

  @override
  String get contacts_groupName => 'Nom du groupe';

  @override
  String get contacts_groupNameRequired => 'Le nom du groupe est obligatoire.';

  @override
  String get contacts_groupNameReserved => 'Ce nom de groupe est réservé';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'Le groupe \"$name\" existe déjà.';
  }

  @override
  String get contacts_filterContacts => 'Filtrer les contacts...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Aucun contact ne correspond à votre filtre.';

  @override
  String get contacts_noMembers => 'Aucun membre';

  @override
  String get contacts_lastSeenNow => 'Vu maintenant';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 heure';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours heures';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 jour';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days jours';
  }

  @override
  String get contact_info => 'Informations de contact';

  @override
  String get contact_settings => 'Paramètres de contact';

  @override
  String get contact_telemetry => 'Télémétrie';

  @override
  String get contact_lastSeen => 'Dernière fois vu';

  @override
  String get contact_clearChat => 'Effacer la conversation';

  @override
  String get contact_teleBase => 'Base de télémétrie';

  @override
  String get contact_teleBaseSubtitle =>
      'Autoriser le partage du niveau de batterie et de la télémétrie de base';

  @override
  String get contact_teleLoc => 'Emplacement de télémétrie';

  @override
  String get contact_teleLocSubtitle =>
      'Autoriser le partage des données de localisation';

  @override
  String get contact_teleEnv => 'Environnement Télémétrie';

  @override
  String get contact_teleEnvSubtitle =>
      'Autoriser le partage des données des capteurs d\'environnement';

  @override
  String get contacts_publicKey => 'Clé publique';

  @override
  String get channels_title => 'Canaux';

  @override
  String get channels_noChannelsConfigured => 'Aucun canal configuré';

  @override
  String get channels_addPublicChannel => 'Ajouter un canal public';

  @override
  String get channels_searchChannels => 'Rechercher des canaux...';

  @override
  String get channels_noChannelsFound => 'Aucun canal trouvé';

  @override
  String channels_channelIndex(int index) {
    return 'Canal $index';
  }

  @override
  String get channels_hashtagChannel => 'Canal avec hashtag';

  @override
  String get channels_public => 'Public';

  @override
  String get channels_private => 'Privé';

  @override
  String get channels_publicChannel => 'Canal public';

  @override
  String get channels_privateChannel => 'Canal privé';

  @override
  String get channels_editChannel => 'Modifier le canal';

  @override
  String get channels_shareChannel => 'Partager le canal';

  @override
  String get channels_shareChannelInstructions =>
      'Scannez le QR code pour ajouter le canal.\nMenu → Ajouter un Canal → Scanner un QR code';

  @override
  String get channels_secretKey => 'Clé secrète';

  @override
  String get channels_meshcoreUri => 'URI MeshCore';

  @override
  String get channels_shareChannelQr => 'Scanner le QR code du canal';

  @override
  String get channels_shareChannelWarning =>
      'Attention : toute personne qui scanne ce QR code aura accès à ce canal.';

  @override
  String get channels_muteChannel => 'Désactiver les notifications du canal';

  @override
  String get channels_unmuteChannel => 'Réactiver les notifications du canal';

  @override
  String get channels_deleteChannel => 'Supprimer le canal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Supprimer $name? Cela ne peut pas être annulé.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Échec de la suppression de la chaîne \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Le canal \"$name\" a été supprimé';
  }

  @override
  String get channels_addChannel => 'Ajouter un Canal';

  @override
  String get channels_channelIndexLabel => 'Index de canal';

  @override
  String get channels_channelName => 'Nom du canal';

  @override
  String get channels_usePublicChannel => 'Utiliser le canal public';

  @override
  String get channels_standardPublicPsk => 'PSK public standard';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk =>
      'Générer une clé de modulation PSK aléatoire';

  @override
  String get channels_enterChannelName => 'Veuillez entrer un nom de canal';

  @override
  String get channels_pskMustBe32Hex =>
      'Le PKS doit être composé de 32 caractères hexadécimaux.';

  @override
  String get channels_addChannelConfirmation =>
      'Voulez-vous ajouter le canal suivant ?';

  @override
  String get channels_channelAddedSuccess => 'Canal ajouté.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Aucun emplacement de canal disponible.';

  @override
  String get appSettings_mentionNotifications => 'Notifications de mention';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Quand quelqu\'un vous mentionne ou vous répond — même dans les canaux en sourdine';

  @override
  String notification_mentionIn(String channelName) {
    return 'Mention dans $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Le canal \"$name\" a été ajouté';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Modifier le Canal $index';
  }

  @override
  String get channels_smazCompression => 'Compression SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Le canal \"$name\" a été mis à jour';
  }

  @override
  String get channels_publicChannelAdded => 'Le canal public a été ajouté';

  @override
  String get channels_sortBy => 'Trier par';

  @override
  String get channels_sortManual => 'Manuel';

  @override
  String get channels_sortAZ => 'A à Z';

  @override
  String get channels_sortLatestMessages => 'Derniers messages';

  @override
  String get channels_sortUnread => 'Non lu';

  @override
  String get channels_createPrivateChannel => 'Créer un Canal Privé';

  @override
  String get channels_createPrivateChannelDesc =>
      'Sécurisé avec une clé secrète.';

  @override
  String get channels_joinPrivateChannel => 'Rejoindre un Canal Privé';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Entrer manuellement une clé secrète.';

  @override
  String get channels_joinPublicChannel => 'Rejoindre le canal public';

  @override
  String get channels_joinPublicChannelDesc =>
      'Tout le monde peut rejoindre ce canal.';

  @override
  String get channels_joinHashtagChannel => 'Rejoindre un Canal Hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'N\'importe qui peut rejoindre les canaux #hashtag.';

  @override
  String get channels_scanQrCode => 'Scanner un QR code';

  @override
  String get channels_scanQrCodeComingSoon => 'Bientôt disponible';

  @override
  String get channels_enterHashtag => 'Entrez le hashtag';

  @override
  String get channels_hashtagHint => 'ex. #equipe';

  @override
  String get chat_noMessages => 'Aucun message pour le moment.';

  @override
  String get chat_sendMessage => 'Envoyer un message';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Envoyer un message à $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Envoyer un message pour commencer';

  @override
  String get chat_originalMessageNotFound => 'Message d\'origine non trouvé';

  @override
  String chat_replyingTo(String name) {
    return 'Répondre à $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Répondre à $name';
  }

  @override
  String get chat_location => 'Emplacement';

  @override
  String get common_copiedToClipboard => 'Copié dans le presse-papiers';

  @override
  String get common_copyToClipboard => 'Copier dans le presse-papiers';

  @override
  String get contacts_copyContactToClipboard =>
      'Copier mon contact dans le presse-papiers';

  @override
  String get chat_typeMessage => 'Saisir un message...';

  @override
  String get chat_searchMessages => 'Rechercher des messages';

  @override
  String get chat_searchNoMatches => 'Aucun résultat';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Message trop long (max $maxBytes octets).';
  }

  @override
  String get chat_messageCopied => 'Message copié';

  @override
  String get chat_messageDeleted => 'Message supprimé';

  @override
  String get chat_sendGif => 'Envoyer GIF';

  @override
  String get chat_reply => 'Répondre';

  @override
  String get chat_newMessages => 'NOUVEAUX MESSAGES';

  @override
  String get chat_addReaction => 'Ajouter une Réaction';

  @override
  String get chat_mention => 'Mentionner';

  @override
  String get dmChannel_menuLabel => 'Message privé';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Message privé à $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Vérifiez la clé et la dernière activité — les noms ne sont pas uniques.';

  @override
  String get dmChannel_warningTitle => 'Est-ce vraiment cette personne ?';

  @override
  String get dmChannel_warningBody =>
      'Les noms dans les canaux sont choisis librement et n\'importe qui peut les imiter. Pour tout sujet sensible, vérifiez d\'abord la clé publique de ce contact par un autre moyen.';

  @override
  String get dmChannel_dontShowAgain => 'Ne plus afficher';

  @override
  String get batterySleep_title => 'Garder MeshTrax actif';

  @override
  String get batterySleep_bodySamsung =>
      'Les téléphones Samsung mettent les applications en veille pour économiser la batterie, ce qui coupe votre radio. Ouvrez Paramètres → Applications → MeshTrax → Batterie et choisissez Sans restriction. Vérifiez aussi Batterie → Limites d\'utilisation en arrière-plan et assurez-vous que MeshTrax n\'est ni dans Applications en veille ni dans Applications en veille prolongée.';

  @override
  String get batterySleep_bodyGeneric =>
      'Votre téléphone peut arrêter MeshTrax en arrière-plan pour économiser la batterie, ce qui coupe votre radio. Ouvrez les paramètres de batterie et réglez MeshTrax sur Sans restriction (ou Aucune restriction). Sur certains téléphones, il faut aussi activer le Démarrage automatique pour MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Ouvrir les paramètres';

  @override
  String get batterySleep_notNow => 'Plus tard';

  @override
  String get batterySleep_settingsTile =>
      'Garder MeshTrax actif en arrière-plan';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Empêcher l\'économiseur de batterie de mettre MeshTrax en veille';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Impossible d\'écrire en privé à $name pour l\'instant';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Vous n\'avez pas encore sa clé, et il lui faudra la vôtre pour répondre — les clés ne circulent que dans les annonces. « Envoyer mon annonce » diffuse la vôtre d\'ici même. « Demander dans le canal » écrit une demande dans la zone de message, que vous n\'aurez plus qu\'à envoyer.';

  @override
  String get dmChannel_askInChannel => 'Demander dans le canal';

  @override
  String get dmChannel_sendMyAdvert => 'Envoyer mon annonce';

  @override
  String get dmChannel_askText =>
      'merci d\'envoyer une annonce pour que je puisse vous écrire en privé';

  @override
  String get dmChannel_watching =>
      'En attente de son annonce — vous serez prévenu ici dès son arrivée.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name est maintenant joignable';
  }

  @override
  String get dmChannel_openDm => 'MP';

  @override
  String get appSettings_zoomLevel => 'Niveau de zoom';

  @override
  String get common_reset => 'Réinitialiser';

  @override
  String get chat_reactionsTitle => 'Réactions';

  @override
  String get chat_reactionUnknownSender => 'Inconnu';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender a réagi à un message absent de cette discussion';
  }

  @override
  String get chat_me => 'Moi';

  @override
  String get emojiCategorySmileys => 'Émojis';

  @override
  String get emojiCategoryGestures => 'Gestes';

  @override
  String get emojiCategoryHearts => 'Cœurs';

  @override
  String get emojiCategoryObjects => 'Objets';

  @override
  String get gifPicker_title => 'Choisir un GIF';

  @override
  String get gifPicker_searchHint => 'Rechercher des GIF...';

  @override
  String get gifPicker_poweredBy => 'Propulsé par GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Aucun GIF trouvé';

  @override
  String get gifPicker_failedLoad => 'Impossible de charger les GIFs';

  @override
  String get gifPicker_failedSearch => 'Recherche de GIFs échouée';

  @override
  String get gifPicker_noInternet => 'Aucune connexion internet';

  @override
  String get debugLog_appTitle => 'Journal de débogage de l\'application';

  @override
  String get debugLog_bleTitle => 'Journal de débogage BLE';

  @override
  String get debugLog_copyLog => 'Copier le journal';

  @override
  String get debugLog_saveLog => 'Enregistrer le journal dans un fichier';

  @override
  String get debugLog_saved => 'Journal enregistré';

  @override
  String get debugLog_saveCancelled => 'Enregistrement annulé';

  @override
  String get debugLog_filterAll => 'Tout';

  @override
  String get debugLog_filterWarnings => 'Avertissements';

  @override
  String get debugLog_filterErrors => 'Erreurs';

  @override
  String get debugLog_clearLog => 'Effacer le journal';

  @override
  String get debugLog_copied => 'Journal de débogage copié';

  @override
  String get debugLog_bleCopied => 'Journal BLE copié';

  @override
  String get debugLog_noEntries => 'Aucun journal de débogage pour le moment.';

  @override
  String get debugLog_enableInSettings =>
      'Activer le débogage de l\'application dans les paramètres';

  @override
  String get debugLog_frames => 'Cadres';

  @override
  String get debugLog_rawLogRx => 'Enregistrement brut - RX';

  @override
  String get debugLog_noBleActivity =>
      'Pas d\'activité BLE enregistrée pour le moment.';

  @override
  String debugFrame_length(int count) {
    return 'Longueur du cadre : $count octets';
  }

  @override
  String debugFrame_command(String value) {
    return 'Commande : 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Message :';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destination PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Timestamp : $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Indicateurs : 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Type de texte : $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Commande CLI';

  @override
  String get debugFrame_textTypePlain => 'Simple';

  @override
  String debugFrame_text(String text) {
    return '- Texte : \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Vidéo de Dump Hexadécimal :';

  @override
  String get chat_hopSingular => 'saut';

  @override
  String get chat_hopPlural => 'sauts';

  @override
  String chat_hopsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sauts',
      one: 'saut',
    );
    return '$count $_temp0';
  }

  @override
  String get chat_setCustomPath => 'Définir un chemin personnalisé';

  @override
  String get chat_fullPath => 'Chemin complet';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Les détails du chemin ne sont pas encore disponibles. Essayez d\'envoyer un message pour rafraîchir.';

  @override
  String get chat_type => 'Saisir';

  @override
  String get chat_path => 'Chemin';

  @override
  String get chat_publicKey => 'Clé Publique';

  @override
  String get chat_compressOutgoingMessages =>
      'Compresser les messages sortants';

  @override
  String get chat_floodForced => 'Tout le réseau  (forcée)';

  @override
  String get chat_directForced => 'Direct (forcé)';

  @override
  String chat_hopsForced(int count) {
    return '$count sauts (forcés)';
  }

  @override
  String get chat_floodAuto => 'Tout le réseau (auto)';

  @override
  String get chat_direct => 'Afficher';

  @override
  String get chat_poiShared => 'Point d\'intérêt Partagé';

  @override
  String chat_unread(int count) {
    return 'Non lu : $count';
  }

  @override
  String get chat_openLink => 'Ouvrir le lien ?';

  @override
  String get chat_openLinkConfirmation =>
      'Voulez-vous ouvrir ce lien dans votre navigateur ?';

  @override
  String get chat_open => 'Ouvrir';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Impossible d\'ouvrir le lien : $url';
  }

  @override
  String get chat_invalidLink => 'Format de lien invalide';

  @override
  String get map_lineOfSight => 'Ligne de vue';

  @override
  String get map_losScreenTitle => 'Ligne de vue';

  @override
  String get map_noNodesWithLocation =>
      'Aucun nœud avec des données de localisation';

  @override
  String get map_nodesNeedGps =>
      'Les nœuds doivent partager leurs coordonnées GPS\npour apparaître sur la carte.';

  @override
  String map_nodesCount(int count) {
    return 'Nœuds : $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Epingles: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Répéteur';

  @override
  String get map_room => 'Room Server';

  @override
  String get map_sensor => 'Capteur';

  @override
  String get map_pinDm => 'Clé (DM)';

  @override
  String get map_pinPrivate => 'Verrouiller (Privé)';

  @override
  String get map_pinPublic => 'Clé (Public)';

  @override
  String get map_lastSeen => 'Dernière fois vu';

  @override
  String get map_disconnectConfirm =>
      'Êtes-vous sûr de vouloir vous déconnecter de cet appareil ?';

  @override
  String get map_from => 'À partir de';

  @override
  String get map_source => 'Source';

  @override
  String get map_flags => 'Drapeaux';

  @override
  String get map_shareMarkerHere => 'Partager le marqueur ici';

  @override
  String get map_setAsMyLocation => 'Définir comme ma localisation';

  @override
  String get map_pinLabel => 'Étiquete de repin';

  @override
  String get map_label => 'Étiquette';

  @override
  String get map_pointOfInterest => 'Point d\'intérêt';

  @override
  String get map_sendToContact => 'Envoyer au contact';

  @override
  String get map_sendToChannel => 'Envoyer sur le canal';

  @override
  String get map_noChannelsAvailable => 'Aucun canal disponible';

  @override
  String get map_publicLocationShare => 'Partager dans un lieu public';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Vous êtes sur le point de partager un emplacement dans $channelLabel. Ce canal est public et toute personne disposant de la clé PSK peut le voir.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Connectez-vous à un appareil pour partager des marqueurs';

  @override
  String get map_filterNodes => 'Filtrer les nœuds';

  @override
  String get map_chatNodes => 'Nœuds de Chat';

  @override
  String get map_repeaters => 'Répéteurs';

  @override
  String get map_otherNodes => 'Autres nœuds';

  @override
  String get map_showOverlaps => 'Chevauchement de la touche répétitive';

  @override
  String get map_keyPrefix => 'Préfixe clé';

  @override
  String get map_filterByKeyPrefix => 'Filtrer par préfixe de clé';

  @override
  String get map_publicKeyPrefix => 'Préfixe de clé publique';

  @override
  String get map_showDiscoveryContacts => 'Afficher les contacts de découverte';

  @override
  String get map_guessedLocation => 'Lieu deviné';

  @override
  String get map_lastSeenTime => 'Dernière fois vu';

  @override
  String get map_sharedPin => 'Clé partagée';

  @override
  String get map_joinRoom => 'Rejoindre le room server';

  @override
  String get map_manageRepeater => 'Gérer le répéteur';

  @override
  String get map_tapToAdd =>
      'Appuyez sur les nœuds pour les ajouter au chemin.';

  @override
  String get map_runTrace => 'Exécuter la traçage de chemin';

  @override
  String get map_runTraceWithReturnPath => 'Revenir sur le même chemin.';

  @override
  String get map_removeLast => 'Supprimer le dernier';

  @override
  String get map_pathTraceCancelled => 'Traçage de chemin annulé';

  @override
  String get time_justNow => 'Maintenant';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minutes auparavant';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h auparavant';
  }

  @override
  String time_daysAgo(int days) {
    return '$days jours avant';
  }

  @override
  String get time_hour => 'heure';

  @override
  String get time_hours => 'heures';

  @override
  String get time_day => 'jour';

  @override
  String get time_days => 'jours';

  @override
  String get time_week => 'semaine';

  @override
  String get time_weeks => 'semaines';

  @override
  String get time_month => 'mois';

  @override
  String get time_months => 'mois';

  @override
  String get time_minutes => 'minutes';

  @override
  String get time_allTime => 'Tout le temps';

  @override
  String get dialog_disconnect => 'Déconnecter';

  @override
  String get dialog_disconnectConfirm =>
      'Êtes-vous sûr de vouloir vous déconnecter de cet appareil ?';

  @override
  String get login_repeaterLogin => 'Connexion au répéteur';

  @override
  String get login_roomLogin => 'Connexion Room Server';

  @override
  String get login_password => 'Mot de passe';

  @override
  String get login_enterPassword => 'Entrez votre mot de passe';

  @override
  String get login_savePassword => 'Sauvegarder le mot de passe';

  @override
  String get login_savePasswordSubtitle =>
      'Le mot de passe sera stocké en toute sécurité sur cet appareil.';

  @override
  String get login_repeaterDescription =>
      'Entrez le mot de passe du répéteur pour accéder aux paramètres et à l\'état.';

  @override
  String get login_roomDescription =>
      'Entrez le mot de passe de la pièce pour accéder aux paramètres et à l\'état.';

  @override
  String get login_login => 'Connexion';

  @override
  String login_attempt(int current, int max) {
    return 'Essayer $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Connexion échouée : $error';
  }

  @override
  String get login_failedMessage =>
      'Connexion échouée. Soit le mot de passe est incorrect, soit le relais est injoignable.';

  @override
  String get common_reload => 'Recharger';

  @override
  String get common_clear => 'Effacer';

  @override
  String get path_enterCustomPath => 'Entrer un chemin personnalisé';

  @override
  String get path_currentPathLabel => 'Chemin actuel';

  @override
  String get path_hexPrefixInstructions =>
      'Entrez les préfixes hexadécimaux de 2 caractères pour chaque saut, séparés par des virgules.';

  @override
  String get path_hexPrefixExample =>
      'Exemple : A1,F2,3C (chaque nœud utilise le premier octet de sa clé publique).';

  @override
  String get path_labelHexPrefixes => 'Préfixes hexadécimaux';

  @override
  String get path_helperMaxHops =>
      'Max 64 sauts. Chaque préfixe fait 2 caractères hexadécimaux (1 octet)';

  @override
  String get path_selectFromContacts => 'Sélectionner à partir des contacts :';

  @override
  String get path_noRepeatersFound =>
      'Aucun répéteur ou room server n\'a été trouvé.';

  @override
  String get path_customPathsRequire =>
      'Les chemins personnalisés nécessitent des sauts intermédiaires qui peuvent transmettre des messages.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Préfixes hexadécimaux invalides : $prefixes';
  }

  @override
  String get path_tooLong =>
      'Le chemin est trop long. Maximum 64 sauts autorisés.';

  @override
  String get path_setPath => 'Définir le chemin';

  @override
  String get repeater_management => 'Gestion des répéteurs';

  @override
  String get room_management => 'Administrattion Room Server';

  @override
  String get repeater_guest => 'Informations sur les répéteurs';

  @override
  String get room_guest => 'Informations sur le serveur';

  @override
  String get repeater_managementTools => 'Outils de Gestion';

  @override
  String get repeater_guestTools => 'Outils pour les invités';

  @override
  String get repeater_status => 'État';

  @override
  String get repeater_statusSubtitle =>
      'Afficher l\'état, les statistiques et les voisins du répéteur';

  @override
  String get repeater_telemetry => 'Télémetrie';

  @override
  String get repeater_telemetrySubtitle =>
      'Afficher la télémétrie des capteurs et les statistiques du système';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Envoyer des commandes au répéteur';

  @override
  String get repeater_neighbors => 'Voisins';

  @override
  String get repeater_neighborsSubtitle => 'Afficher les voisins de saut nuls.';

  @override
  String get repeater_settings => 'Paramètres';

  @override
  String get repeater_settingsSubtitle =>
      'Configurer les paramètres du répéteur';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Synchronisation de l\'horloge après la connexion';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Envoyer automatiquement une notification \"synchronisation de l\'heure\" après une connexion réussie.';

  @override
  String get repeater_statusTitle => 'État du répéteur';

  @override
  String get repeater_refresh => 'Rafraîchir';

  @override
  String get repeater_statusRequestTimeout =>
      'Demande de statut délai dépassé.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Erreur lors du chargement du statut : $error';
  }

  @override
  String get repeater_systemInformation => 'Informations Système';

  @override
  String get repeater_battery => 'Batterie';

  @override
  String get repeater_clockAtLogin => 'Horloge (au démarrage)';

  @override
  String get repeater_uptime => 'Disponibilité';

  @override
  String get repeater_queueLength => 'Longueur de la file d\'attente';

  @override
  String get repeater_debugFlags => 'Marqueurs de débogage';

  @override
  String get repeater_radioStatistics => 'Statistiques Radio';

  @override
  String get repeater_lastRssi => 'Dernier RSSI';

  @override
  String get repeater_lastSnr => 'Dernier SNR';

  @override
  String get repeater_noiseFloor => 'Niveau de Bruit';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Statistiques des paquets';

  @override
  String get repeater_sent => 'Envoyé';

  @override
  String get repeater_received => 'Reçu';

  @override
  String get repeater_duplicates => 'Doublons';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days jours ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total : $total, Tout le réseau : $flood, Direct : $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total : $total, Tout le réseau : $flood, Direct : $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Tout le réseau : $flood, Direct : $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Total : $total';
  }

  @override
  String get repeater_settingsTitle => 'Paramètres du répéteur';

  @override
  String get repeater_basicSettings => 'Paramètres de base';

  @override
  String get repeater_repeaterName => 'Nom du répéteur';

  @override
  String get repeater_repeaterNameHelper => 'Afficher le nom de ce répéteur';

  @override
  String get repeater_adminPassword => 'Mot de passe Administrateur';

  @override
  String get repeater_adminPasswordHelper => 'Mot de passe d\'accès complet';

  @override
  String get repeater_guestPassword => 'Mot de passe invité';

  @override
  String get repeater_guestPasswordHelper =>
      'Accès en lecture seule avec mot de passe';

  @override
  String get repeater_radioSettings => 'Paramètres Radio';

  @override
  String get repeater_frequencyMhz => 'Fréquence (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Puissance';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Bande passante';

  @override
  String get repeater_spreadingFactor => 'Facteur de répartition (SF)';

  @override
  String get repeater_codingRate => 'Taux de codage (CR)';

  @override
  String get repeater_locationSettings => 'Paramètres de localisation';

  @override
  String get repeater_latitude => 'Latitude';

  @override
  String get repeater_latitudeHelper =>
      'Degrés décimaux (par exemple, 37.7749)';

  @override
  String get repeater_longitude => 'Longitude';

  @override
  String get repeater_longitudeHelper =>
      'Degrés décimaux (par exemple, -122,4194)';

  @override
  String get repeater_features => 'Fonctionnalités';

  @override
  String get repeater_packetForwarding => 'Mode répéteur';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Activer le répéteur pour transmettre des paquets';

  @override
  String get repeater_guestAccess => 'Accès Invité';

  @override
  String get repeater_guestAccessSubtitle =>
      'Autoriser l\'accès invité en lecture seule';

  @override
  String get repeater_privacyMode => 'Mode de confidentialité';

  @override
  String get repeater_privacyModeSubtitle =>
      'Cacher le nom/l\'emplacement dans les annonces';

  @override
  String get repeater_advertisementSettings => 'Paramètres d\'annonces';

  @override
  String get repeater_localAdvertInterval =>
      'Intervalle des annonces Locale (0 saut)';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervalle des annonces à tout le réseau (flood)';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours heures';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Intervalle d\'annonces cryptées';

  @override
  String get repeater_dangerZone => 'Zone dangereuse';

  @override
  String get repeater_rebootRepeater => 'Redémarrer Répéteur';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Réinitialiser l\'appareil répéteur';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Êtes-vous sûr de vouloir redémarrer ce répéteur ?';

  @override
  String get repeater_regenerateIdentityKey => 'Ré générer la clé d\'identité';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Générer une nouvelle paire de clés publique/privée';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Cela générera une nouvelle identité pour le répéteur. Continuer ?';

  @override
  String get repeater_eraseFileSystem => 'Supprimer le système de fichiers';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formater le système de fichiers du répéteur';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'AVERTISSEMENT : Cela effacera toutes les données du répéteur. Cela ne peut pas être annulé !';

  @override
  String get repeater_eraseSerialOnly =>
      'Erase n\'est disponible que via la console série.';

  @override
  String repeater_commandSent(String command) {
    return 'Commande envoyée : $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Erreur lors de l\'envoi de la commande : $error';
  }

  @override
  String get repeater_confirm => 'Confirmer';

  @override
  String get repeater_settingsSaved =>
      'Les paramètres ont été enregistrés avec succès.';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Erreur lors de la sauvegarde des paramètres : $error';
  }

  @override
  String get repeater_refreshBasicSettings =>
      'Rafraîchir les paramètres de base';

  @override
  String get repeater_refreshRadioSettings => 'Rafraîchir les paramètres Radio';

  @override
  String get repeater_refreshTxPower => 'Rafraîchir la tension TX';

  @override
  String get repeater_refreshLocationSettings =>
      'Rafraîchir les paramètres de localisation';

  @override
  String get repeater_refreshPacketForwarding =>
      'Rafraîchir le routage des paquets';

  @override
  String get repeater_refreshGuestAccess => 'Rafraîchir l\'accès invité';

  @override
  String get repeater_refreshPrivacyMode =>
      'Rafraîchir le Mode Confidentialité';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Rafraîchir les Paramètres des annonces';

  @override
  String repeater_refreshed(String label) {
    return '$label rafraîchi';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Erreur lors du rafraîchissement de $label';
  }

  @override
  String get repeater_cliTitle => 'Répéteur CLI';

  @override
  String get repeater_debugNextCommand => 'Déboguer Prochaine Commande';

  @override
  String get repeater_commandHelp => 'Aide';

  @override
  String get repeater_clearHistory => 'Effacer l\'historique';

  @override
  String get repeater_noCommandsSent =>
      'Aucune commande n\'a encore été envoyée.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Saisissez une commande ci-dessous ou utilisez les commandes rapides';

  @override
  String get repeater_enterCommandHint => 'Entrer la commande...';

  @override
  String get repeater_previousCommand => 'Commande précédente';

  @override
  String get repeater_nextCommand => 'Prochaine commande';

  @override
  String get repeater_enterCommandFirst => 'Entrez d\'abord une commande';

  @override
  String get repeater_cliCommandFrameTitle => 'Frame de commande CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Obtenir le nom';

  @override
  String get repeater_cliQuickGetRadio => 'Obtenir la Radio';

  @override
  String get repeater_cliQuickGetTx => 'Obtenir TX';

  @override
  String get repeater_cliQuickNeighbors => 'Voisins';

  @override
  String get repeater_cliQuickVersion => 'Version';

  @override
  String get repeater_cliQuickAdvertise => 'Publier';

  @override
  String get repeater_cliQuickClock => 'Horloge';

  @override
  String get repeater_cliQuickClockSync => 'Synchronisation de l\'horloge';

  @override
  String get repeater_cliQuickDiscovery => 'Découvrir les voisins';

  @override
  String get repeater_cliHelpAdvert => 'Envoie un paquet d\'annonce';

  @override
  String get repeater_cliHelpReboot =>
      'Redémarre l\'appareil. (Note, vous risquez d\'obtenir \'Timeout\' ce qui est normal)';

  @override
  String get repeater_cliHelpClock =>
      'Affiche l\'heure actuelle par l\'horloge de chaque appareil.';

  @override
  String get repeater_cliHelpPassword =>
      'Définit un nouveau mot de passe administrateur pour l\'appareil.';

  @override
  String get repeater_cliHelpVersion =>
      'Affiche la version du périphérique et la date de construction du micrologiciel.';

  @override
  String get repeater_cliHelpClearStats =>
      'Réinitialise divers compteurs de statistiques à zéro.';

  @override
  String get repeater_cliHelpSetAf => 'Définit le facteur de temps d\'air.';

  @override
  String get repeater_cliHelpSetTx =>
      'Définit la puissance de transmission LoRa en dBm (réinitialisation requise pour appliquer).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Active ou désactive le rôle du répéteur pour ce nœud.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Room server) Si \"activé\", alors un mot de passe vide permettra la connexion, mais ne permettra pas de publier dans la pièce. (lecture seule uniquement)';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Définit le nombre maximal de sauts pour les paquets de balayage entrants (si >= max, le paquet n\'est pas acheminé).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Définit le seuil d\'interférence (en dB). La valeur par défaut est de 14. Définir sur 0 désactive la détection des interférences de canal.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Définit l\'intervalle pour réinitialiser le contrôleur de gain automatique. Mettez à 0 pour désactiver.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Active ou désactive la fonctionnalité « double ACKs ».';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Définit l\'intervalle entre chaque émission d\'une annonce locale (sans relais). Définir sur 0 pour désactiver.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Définit l\'intervalle du minuteur en heures pour envoyer un paquet d\'annonce massive. Définir sur 0 pour désactiver.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Définit/met à jour le mot de passe de l\'invité. (pour les répéteurs, les connexions d\'invités peuvent envoyer la requête \"Get Stats\")';

  @override
  String get repeater_cliHelpSetName => 'Définit le nom de l\'annonce.';

  @override
  String get repeater_cliHelpSetLat =>
      'Définit la latitude de la carte des annonces. (degrés décimaux)';

  @override
  String get repeater_cliHelpSetLon =>
      'Définit la longitude de la carte de l\'annonce. (degrés décimaux)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Définit complètement de nouveaux paramètres de radio et les enregistre dans les préférences. Nécessite une commande \"redémarrage\" pour les appliquer.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Paramètres (expérimental) de base pour appliquer un léger délai aux paquets reçus, en fonction de la force du signal/score. Définir sur 0 pour désactiver.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Définit un facteur multiplié par le temps de fonctionnement en mode vers tout le réseau (flood) pour un paquet et avec un système de slot aléatoire, afin de retarder son envoi (pour diminuer la probabilité de collisions).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Identique à txdelay, mais pour appliquer un délai aléatoire au transfert des paquets en mode direct.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Activer/Désactiver le pont.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Définir le délai avant de renvoyer les paquets.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Choisissez si le pont retransmettra les paquets reçus ou les paquets transmis.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Définir la vitesse de communication série pour les ponts Rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Définir le secret du pont pour les ponts espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Définit un facteur personnalisé pour ajuster la tension de la batterie signalée (uniquement pris en charge sur certains cartes).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Définit des paramètres radio temporaires pour le nombre de minutes donné, puis revient aux paramètres radio d\'origine. (ne sauvegarde pas dans les préférences).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifie l’ACL. Supprime l’entrée correspondante (par préfixe de clé publique) si \"permissions\" est égal à zéro. Ajoute une nouvelle entrée si la clé publique hexadécimale a une longueur complète et n’est pas actuellement dans l’ACL. Met à jour l’entrée en fonction du préfixe de clé publique. Les bits de permission varient en fonction du rôle du firmware, mais les 2 bits inférieurs sont : 0 (Invité), 1 (Lecture seule), 2 (Lecture/écriture), 3 (Administrateur).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Obtenir le type de pont : aucun, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Démarre l\'enregistrement des paquets dans le système de fichiers.';

  @override
  String get repeater_cliHelpLogStop =>
      'Arrêter de journaliser les paquets vers le système de fichiers.';

  @override
  String get repeater_cliHelpLogErase =>
      'Supprime les journaux de paquets du système de fichiers.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Affiche une liste d\'autres nœuds répéteurs entendus via des annonces sans relais. Chaque ligne est id-préfixe-hexadécimal:timestamp:snr-fois-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Supprime la première entrée correspondante (par préfixe de clé publique (hexadécimal)) de la liste des voisins.';

  @override
  String get repeater_cliHelpRegion =>
      '(série uniquement) Liste toutes les régions définies et les autorisations actuelles d\'annonces sur tout le réseau (flood).';

  @override
  String get repeater_cliHelpRegionLoad =>
      'REMARQUE : il s\'agit d\'une invocation multi-commande spéciale. Chaque commande subséquente est un nom de région (indenté avec des espaces pour indiquer la hiérarchie parent, avec un minimum d\'un espace). Terminé par l\'envoi d\'une ligne vide/commande.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Recherche la région avec le préfixe de nom donné (ou \"\" pour l\'étendue globale). Répond avec \"-> nom-de-région (nom-parent) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Ajoute ou met à jour une définition de région avec le nom donné.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Supprime une définition de région avec le nom donné.';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Définit les autorisations de \"Flot\" pour la région donnée. (\'\' pour la portée globale/héritée)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Supprime l\'autorisation \'F\'lood\' pour la région donnée. (NOTE : à ce stade, il n\'est pas conseillé de l\'utiliser sur l\'étendue globale/héritée !! )';

  @override
  String get repeater_cliHelpRegionHome =>
      'Répond avec la région \'maison\' actuelle. (Note appliquée nulle part pour l\'instant, réservée à une utilisation future)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Définit la région \'maison\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Conserve la liste/la carte des régions dans le stockage.';

  @override
  String get repeater_cliHelpGps =>
      'Affiche l’état du GPS. Lorsque le GPS est éteint, il répond uniquement « éteint », si allumé, il répond avec « allumé », l’état, la correction, le nombre de satellites.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Activer/désactiver le GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Synchronise l\'heure du nœud avec l\'horloge GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Définit la position du nœud aux coordonnées GPS et enregistre les préférences.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Donne la configuration de l\'annonce de la localisation du nœud :\n- none : ne pas inclure la localisation dans les annonces\n- share : partager la localisation GPS (du SensorManager)\n- prefs : annoncer la localisation stockée dans les préférences';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Définit la configuration de l\'annonce de localisation.';

  @override
  String get repeater_commandsListTitle => 'Liste des commandes';

  @override
  String get repeater_commandsListNote =>
      'NOTE : pour les diverses commandes « set »..., il existe également une commande « get »...';

  @override
  String get repeater_general => 'Général';

  @override
  String get repeater_settingsCategory => 'Paramètres';

  @override
  String get repeater_bridge => 'Pont';

  @override
  String get repeater_logging => 'Journalisation';

  @override
  String get repeater_neighborsRepeaterOnly => 'Voisins (Uniquement répéteur)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gestion des régions (uniquement pour le répéteur)';

  @override
  String get repeater_regionNote =>
      'Les commandes de région ont été introduites pour gérer les définitions et les autorisations des régions.';

  @override
  String get repeater_gpsManagement => 'Gestion GPS';

  @override
  String get repeater_gpsNote =>
      'La commande GPS a été introduite pour gérer les sujets liés à la localisation.';

  @override
  String get telemetry_receivedData => 'Données de télémétrie reçues';

  @override
  String get telemetry_requestTimeout => 'Demande de télémétrie expirée.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Erreur lors du chargement de la télémétrie : $error';
  }

  @override
  String get telemetry_noData => 'Aucune donnée de télémétrie disponible.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batterie';

  @override
  String get telemetry_voltageLabel => 'Tension';

  @override
  String get telemetry_mcuTemperatureLabel => 'Température du MCU';

  @override
  String get telemetry_temperatureLabel => 'Température';

  @override
  String get telemetry_currentLabel => 'Actuellement';

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
  String get neighbors_receivedData => 'Données des voisins reçues';

  @override
  String get neighbors_requestTimedOut => 'Les voisins demandent un délai.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Erreur lors du chargement des voisins : $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Répéteurs Voisins';

  @override
  String get neighbors_noData =>
      'Aucune donnée concernant les voisins disponible.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Clé publique inconnue $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Écouté : $time auparavant';
  }

  @override
  String get channelPath_title => 'Chemin de paquet';

  @override
  String get channelPath_viewMap => 'Afficher la carte';

  @override
  String get channelPath_otherObservedPaths => 'Autres chemins observés';

  @override
  String get channelPath_repeaterHops => 'Sauts du répéteur';

  @override
  String get channelPath_noHopDetails =>
      'Les détails de l\'envoi ne sont pas fournis pour ce paquet.';

  @override
  String get channelPath_messageDetails => 'Détails du message';

  @override
  String get channelPath_senderLabel => 'Expéditeur';

  @override
  String get channelPath_timeLabel => 'Temps';

  @override
  String get channelPath_repeatsLabel => 'Répétitions';

  @override
  String channelPath_pathLabel(int index) {
    return 'Chemin $index';
  }

  @override
  String get channelPath_observedLabel => 'Observé';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Chemin observé $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Aucune donnée de localisation';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Inconnu';

  @override
  String get channelPath_floodPath => 'Tout le réseau';

  @override
  String get channelPath_directPath => 'Afficher';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 de $total sauts';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed sur $total sauts';
  }

  @override
  String get channelPath_mapTitle => 'Carte du chemin';

  @override
  String get channelPath_noRepeaterLocations =>
      'Aucune position de répéteur disponible pour ce chemin.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Chemin $index (Principal)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Chemin';

  @override
  String get channelPath_observedPathHeader => 'Chemin observé';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Aucun détail de saut disponible pour ce paquet.';

  @override
  String get channelPath_unknownRepeater => 'Répéteur Inconnu';

  @override
  String get community_title => 'Communauté';

  @override
  String get community_create => 'Créer une Communauté';

  @override
  String get community_createDesc =>
      'Créer une nouvelle communauté et la partager via QR code.';

  @override
  String get community_join => 'Rejoindre';

  @override
  String get community_joinTitle => 'Rejoindre la communauté';

  @override
  String community_joinConfirmation(String name) {
    return 'Souhaitez-vous rejoindre la communauté \"$name\" ?';
  }

  @override
  String get community_scanQr => 'Scanner un QR code de communauté';

  @override
  String get community_scanInstructions =>
      'Pointez l\'appareil photo vers un QR code de communauté.';

  @override
  String get community_showQr => 'Afficher le QR Code';

  @override
  String get community_publicChannel => 'Communauté Publique';

  @override
  String get community_hashtagChannel => 'Hashtag Communauté';

  @override
  String get community_name => 'Nom de la communauté';

  @override
  String get community_enterName => 'Entrez le nom de la communauté';

  @override
  String community_created(String name) {
    return 'Communauté \"$name\" créée';
  }

  @override
  String community_joined(String name) {
    return 'Rejoint la communauté \"$name\"';
  }

  @override
  String get community_qrTitle => 'Partager Communauté';

  @override
  String community_qrInstructions(String name) {
    return 'Scanner ce QR code pour rejoindre $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Les canaux hashtag de la communauté ne sont accessibles qu\'aux membres de la communauté';

  @override
  String get community_invalidQrCode => 'QR code de communauté non valide';

  @override
  String get community_alreadyMember => 'Déjà membre';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Vous êtes déjà membre de \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Ajouter un Canal Public de la Communauté';

  @override
  String get community_addPublicChannelHint =>
      'Ajouter automatiquement le canal public pour cette communauté';

  @override
  String get community_noCommunities =>
      'Aucun groupe n\'a été rejoint pour le moment.';

  @override
  String get community_scanOrCreate =>
      'Scanner un QR code ou créer une communauté pour commencer';

  @override
  String get community_manageCommunities => 'Gérer les Communautés';

  @override
  String get community_delete => 'Quitter la communauté';

  @override
  String community_deleteConfirm(String name) {
    return 'Quitter \"$name\" ?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Cela supprimera également $count canal/canaux et leurs messages.';
  }

  @override
  String community_deleted(String name) {
    return 'Communauté \"$name\" quittée';
  }

  @override
  String get community_regenerateSecret => 'Régénérer le secret';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Régénérer la clé secrète pour \"$name\" ? Tous les membres devront scanner le nouveau QR code pour continuer à communiquer.';
  }

  @override
  String get community_regenerate => 'Régénérer';

  @override
  String community_secretRegenerated(String name) {
    return 'Mot de passe secret régénéré pour \"$name\"';
  }

  @override
  String get community_updateSecret => 'Mettre à jour le secret';

  @override
  String community_secretUpdated(String name) {
    return 'Modification secrète mise à jour pour \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scanner le nouveau QR code pour mettre à jour le mot de passe pour \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Ajouter un Hashtag Communauté';

  @override
  String get community_addHashtagChannelDesc =>
      'Ajouter un canal hashtag pour cette communauté';

  @override
  String get community_selectCommunity => 'Sélectionner Communauté';

  @override
  String get community_regularHashtag => 'Hashtag régulier';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag public (tout le monde peut rejoindre)';

  @override
  String get community_communityHashtag => 'Hashtag de la communauté';

  @override
  String get community_communityHashtagDesc =>
      'Exclusif aux membres de la communauté';

  @override
  String community_forCommunity(String name) {
    return 'Pour $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrer et trier';

  @override
  String get listFilter_sortBy => 'Trier par';

  @override
  String get listFilter_latestMessages => 'Derniers messages';

  @override
  String get listFilter_heardRecently => 'Écoute récemment';

  @override
  String get listFilter_az => 'A à Z';

  @override
  String get listFilter_filters => 'Filtres';

  @override
  String get listFilter_source => 'Source';

  @override
  String get listFilter_saved => 'Enregistrés';

  @override
  String get listFilter_discovered => 'Découverts';

  @override
  String get listFilter_all => 'Tout';

  @override
  String get listFilter_favorites => 'Préférences';

  @override
  String get listFilter_addToFavorites => 'Ajouter à mes favoris';

  @override
  String get listFilter_removeFromFavorites => 'Supprimer des favoris';

  @override
  String get listFilter_users => 'Utilisateurs';

  @override
  String get listFilter_repeaters => 'Répéteurs';

  @override
  String get listFilter_roomServers => 'Room servers';

  @override
  String get listFilter_unreadOnly => 'Messages non lus seulement';

  @override
  String get listFilter_newGroup => 'Nouveau groupe';

  @override
  String get pathTrace_you => 'Vous';

  @override
  String get pathTrace_failed => 'Traçage du chemin échoué.';

  @override
  String get pathTrace_notAvailable => 'Tracé de chemin non disponible.';

  @override
  String get pathTrace_refreshTooltip => 'Actualiser Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Un ou plusieurs des sauts manquent d\'une localisation !';

  @override
  String get pathTrace_clearTooltip => 'Effacer le chemin';

  @override
  String get losSelectStartEnd =>
      'Sélectionnez les nœuds de début et de fin pour LOS.';

  @override
  String losRunFailed(String error) {
    return 'Échec de la vérification de la ligne de vue : $error';
  }

  @override
  String get losClearAllPoints => 'Effacer tous les points';

  @override
  String get losRunToViewElevationProfile =>
      'Exécutez LOS pour afficher le profil d\'altitude';

  @override
  String get losMenuTitle => 'Menu LOS';

  @override
  String get losMenuSubtitle =>
      'Appuyez sur les nœuds ou appuyez longuement sur la carte pour des points personnalisés';

  @override
  String get losShowDisplayNodes => 'Afficher les nœuds d\'affichage';

  @override
  String get losCustomPoints => 'Points personnalisés';

  @override
  String losCustomPointLabel(int index) {
    return 'Personnalisé $index';
  }

  @override
  String get losPointA => 'Point A';

  @override
  String get losPointB => 'Point B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antenne A : $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antenne B : $value $unit';
  }

  @override
  String get losRun => 'Exécuter la LOS';

  @override
  String get losNoElevationData => 'Aucune donnée d\'altitude';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, LOS clair, clairance minimale $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, bloqué par $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS : vérification...';

  @override
  String get losStatusNoData => 'LOS : aucune donnée';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS : $clear/$total clair, $blocked bloqué, $unknown inconnu';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Données d\'altitude indisponibles pour un ou plusieurs échantillons.';

  @override
  String get losErrorInvalidInput =>
      'Données de points/d\'altitude non valides pour le calcul de la LOS.';

  @override
  String get losRenameCustomPoint => 'Renommer le point personnalisé';

  @override
  String get losPointName => 'Nom du point';

  @override
  String get losShowPanelTooltip => 'Afficher le panneau LOS';

  @override
  String get losHidePanelTooltip => 'Masquer le panneau LOS';

  @override
  String get losElevationAttribution =>
      'Données d’altitude : Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Horizon radio';

  @override
  String get losLegendLosBeam => 'Ligne de visée';

  @override
  String get losLegendTerrain => 'Terrain';

  @override
  String get losFrequencyLabel => 'Fréquence';

  @override
  String get losFrequencyInfoTooltip => 'Voir les détails du calcul';

  @override
  String get losFrequencyDialogTitle => 'Calcul de l’horizon radio';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'À partir de k=$baselineK à $baselineFreq MHz, le calcul ajuste le facteur k pour la bande actuelle de $frequencyMHz MHz, ce qui définit la limite incurvée de l\'horizon radio.';
  }

  @override
  String get contacts_pathTrace => 'Traçage de chemin';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Tracer le chemin vers le répéteur';

  @override
  String get contacts_repeaterPing => 'Pinguer le répéteur';

  @override
  String get contacts_roomPathTrace => 'Traçage du chemin vers le room server';

  @override
  String get contacts_roomPing => 'Pinguer le room server';

  @override
  String get contacts_chatTraceRoute => 'Tracer le chemin';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Tracer l\'itinéraire vers $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Le presse-papiers est vide.';

  @override
  String get contacts_invalidAdvertFormat => 'Données de contact non valides';

  @override
  String get contacts_contactImported => 'Le contact a été importé.';

  @override
  String get contacts_contactImportFailed =>
      'Échec de l\'importation du contact.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name est déjà dans vos contacts.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Annonce Zero saut';

  @override
  String get contacts_floodAdvert => 'Annonce à tout le réseau';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Copier l\'annonce dans le presse-papiers';

  @override
  String get contacts_addContactFromClipboard =>
      'Ajouter un contact depuis le presse-papiers';

  @override
  String get contacts_ShareContact =>
      'Copier le contact dans le presse-papiers';

  @override
  String get contacts_ShareContactZeroHop => 'Partager un contact par annonce';

  @override
  String get contacts_zeroHopContactAdvertSent =>
      'Envoyer un contact par annonce.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'Échec de l\'envoi du contact.';

  @override
  String get contacts_contactAdvertCopied =>
      'Annonce copiée dans le presse-papiers.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'La copie de l\'annonce vers le presse-papiers a échoué.';

  @override
  String get contacts_addContact => 'Ajouter un contact';

  @override
  String get contacts_scanQrCode => 'Scanner le QR d\'un contact';

  @override
  String get contacts_scanQrCodeDesc =>
      'Scanner le QR code d\'un contact depuis l\'application MeshCore';

  @override
  String get contacts_enterIdHash => 'Saisir un contact manuellement';

  @override
  String get contacts_enterIdHashDesc =>
      'Collez une annonce de contact ou un lien meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... ou clé publique en hex';

  @override
  String get contacts_import => 'Importer';

  @override
  String get contacts_scanContactInstructions =>
      'Scannez le QR code d\'un contact MeshCore';

  @override
  String get notification_activityTitle => 'Activité MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messages',
      one: 'message',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'messages de canal',
      one: 'message de canal',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nouveaux nœuds',
      one: 'nouveau nœud',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nouveau $contactType découvert';
  }

  @override
  String get notification_receivedNewMessage => 'Nouveau message reçu';

  @override
  String get settings_gpxExportRepeaters =>
      'Exporter les répéteurs / room servers au format GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporte les répéteurs / roomserver avec une localisation vers un fichier GPX.';

  @override
  String get settings_gpxExportContacts =>
      'Exporter les compagnons au format GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporte les compagnons avec un emplacement vers un fichier GPX.';

  @override
  String get settings_gpxExportAll =>
      'Exporter tous les contacts au format GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporte tous les contacts avec une localisation vers un fichier GPX.';

  @override
  String get settings_gpxExportSuccess => 'Fichier GPX exporté avec succès.';

  @override
  String get settings_gpxExportNoContacts => 'Aucun contact à exporter.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Non pris en charge sur votre appareil/Système d\'exploitation';

  @override
  String get settings_gpxExportError =>
      'Une erreur s\'est produite lors de l\'exportation.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Emplacements des répéteurs et room servers';

  @override
  String get settings_gpxExportChat => 'Emplacements des compagnons';

  @override
  String get settings_gpxExportAllContacts =>
      'Tous les emplacements des contacts';

  @override
  String get settings_gpxExportShareText =>
      'Données de carte exportées à partir de MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax exporter les données de carte GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Répéteurs à proximité';

  @override
  String get snrIndicator_lastSeen => 'Dernière fois vu';

  @override
  String get contactsSettings_title => 'Paramètres des contacts';

  @override
  String get contactsSettings_autoAddTitle => 'Découverte automatique';

  @override
  String get contactsSettings_otherTitle =>
      'Autres paramètres liés aux contacts';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Ajouter automatiquement les utilisateurs';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Autoriser le compagnon à ajouter automatiquement les utilisateurs découverts';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Ajouter automatiquement les répéteurs';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Autoriser le compagnon à ajouter automatiquement les répéteurs découverts';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Ajouter automatiquement les room servers';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Autoriser le compagnon à ajouter automatiquement les room servers découverts';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Ajouter automatiquement les capteurs';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Autoriser le compagnon à ajouter automatiquement les capteurs découverts.';

  @override
  String get contactsSettings_overwriteOldestTitle => 'Écraser le plus ancien';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Lorsque la liste de contacts est pleine, le contact le plus ancien non favori sera remplacé.';

  @override
  String get discoveredContacts_Title => 'Contacts découverts';

  @override
  String get discoveredContacts_noMatching => 'Aucun contact correspondant';

  @override
  String get listFilter_searchHint => 'Rechercher...';

  @override
  String get discoveredContacts_searchHint =>
      'Rechercher des contacts découverts';

  @override
  String get discoveredContacts_contactAdded => 'Contact ajouté';

  @override
  String get discoveredContacts_addContact => 'Ajouter un contact';

  @override
  String get discoveredContacts_copyContact =>
      'Copier le contact dans le presse-papiers';

  @override
  String get discoveredContacts_deleteContact => 'Supprimer le contact';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Supprimer tous les contacts découverts';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Êtes-vous sûr de vouloir supprimer tous les contacts découverts ?';

  @override
  String get chat_sendCooldown =>
      'Veuillez patienter un instant avant de réessayer.';

  @override
  String get chat_notConnected =>
      'Non connecté à une radio. Message non envoyé.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Accéder au message le plus ancien non lu';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Lorsque vous ouvrez une conversation contenant des messages non lus, faites défiler la page jusqu\'au premier message non lu, plutôt que jusqu\'au dernier.';

  @override
  String get appSettings_languageHu => 'Hongrois';

  @override
  String get appSettings_languageJa => 'Japonais';

  @override
  String get appSettings_languageKo => 'Coréen';

  @override
  String get radioStats_screenTitle => 'Statistiques de radio';

  @override
  String get radioStats_notConnected =>
      'Connectez-vous à un appareil pour visualiser les statistiques de la radio.';

  @override
  String get radioStats_firmwareTooOld =>
      'Les statistiques radio nécessitent un firmware compatible v8 ou une version ultérieure.';

  @override
  String get radioStats_waiting => 'En attente des données…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Niveau de bruit : $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Dernier RSSI : $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Dernier SNR : $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Temps d\'antenne à la télévision du Texas (total) : $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Temps d\'utilisation de l\'appareil RX (total) : $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Niveau de bruit (dBm) sur les échantillons récents.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Niveau de bruit : $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting =>
      'Récupération des statistiques de la radio…';

  @override
  String get radioStats_settingsTile => 'Statistiques de radio';

  @override
  String get radioStats_settingsSubtitle =>
      'Niveau de bruit, RSSI, rapport signal/bruit (SNR) et temps d\'antenne';

  @override
  String get translation_title => 'Traduction';

  @override
  String get translation_enableTitle => 'Activer la traduction';

  @override
  String get translation_enableSubtitle =>
      'Traduire les messages entrants et permettre la traduction avant l\'envoi.';

  @override
  String get translation_composerTitle => 'Traduire avant d\'envoyer';

  @override
  String get translation_composerSubtitle =>
      'Contrôle l\'état par défaut de l\'icône de traduction du composant.';

  @override
  String get translation_targetLanguage => 'Langue cible';

  @override
  String get translation_useAppLanguage =>
      'Utiliser la langue de l\'application';

  @override
  String get translation_downloadedModelLabel => 'Modèle téléchargé';

  @override
  String get translation_presetModelLabel => 'Modèle Hugging Face préconfiguré';

  @override
  String get translation_manualUrlLabel => 'URL du modèle manuel';

  @override
  String get translation_downloadModel => 'Télécharger le modèle';

  @override
  String get translation_downloading => 'Téléchargement...';

  @override
  String get translation_working => 'Au travail...';

  @override
  String get translation_stop => 'Arrêtez';

  @override
  String get translation_mergingChunks =>
      'Fusion des fragments téléchargés dans le fichier final...';

  @override
  String get translation_downloadedModels => 'Modèles téléchargés';

  @override
  String get translation_deleteModel => 'Supprimer le modèle';

  @override
  String get translation_modelDownloaded => 'Modèle de traduction téléchargé.';

  @override
  String get translation_downloadStopped =>
      'Le téléchargement a été interrompu.';

  @override
  String translation_downloadFailed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get translation_enterUrlFirst => 'Entrez d\'abord l\'URL du modèle.';

  @override
  String get scanner_linuxPairingShowPin => 'Afficher le code PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Masquer le code PIN';

  @override
  String get scanner_linuxPairingPinTitle =>
      'Code PIN pour la connexion Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Entrez le code PIN pour $deviceName (laissez vide si nécessaire).';
  }

  @override
  String get translation_messageTranslation => 'Traduction du message';

  @override
  String get translation_translateBeforeSending => 'Traduire avant d\'envoyer';

  @override
  String get translation_composerEnabledHint =>
      'Les messages seront traduits avant d\'être envoyés.';

  @override
  String get translation_composerDisabledHint =>
      'Envoyez des messages dans la langue originale, telle que vous l\'avez tapée.';

  @override
  String translation_translateTo(String language) {
    return 'Traduire en $language';
  }

  @override
  String get translation_translationOptions => 'Options de traduction';

  @override
  String get translation_systemLanguage => 'Langue du système';

  @override
  String get routing_title => 'Routage';

  @override
  String routing_route(String route) {
    return 'Chemin enregistré : $route';
  }

  @override
  String get routing_noRoute =>
      'aucun pour l\'instant — le prochain message part vers tout le réseau et en apprend un';

  @override
  String get routing_auto => 'Automatique';

  @override
  String get routing_autoSubtitle =>
      'Utiliser le chemin enregistré dans la radio. Recommandé.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder activé : essaie d\'abord les itinéraires appris';

  @override
  String get routing_flood => 'Toujours vers tout le réseau';

  @override
  String get routing_floodSubtitle =>
      'Chaque message est envoyé à tout le réseau';

  @override
  String get routing_custom => 'Chemin personnalisé';

  @override
  String get routing_customSubtitle => 'Choisissez vous-même les répéteurs';

  @override
  String get routing_forget => 'Réinitialiser le chemin';

  @override
  String get routing_forgetDone =>
      'Chemin réinitialisé. Le prochain message part vers tout le réseau et en apprend un nouveau.';

  @override
  String get routing_pathfinder => 'Ce que sait Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Répéteurs qui vous entendent et qui entendent ce contact, et itinéraires appris à l\'aller et au retour';

  @override
  String get path_direct => 'Direct — sans répéteur';

  @override
  String get path_directSubtitle =>
      'Seulement si le contact entend directement cette radio';

  @override
  String get chat_kindFlood => 'tout le réseau';

  @override
  String get chat_kindDirect => 'direct';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sauts',
      one: 'saut',
    );
    return 'itinéraire ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'sauts',
      one: 'saut',
    );
    String _temp1 = intl.Intl.pluralLogic(
      guessed,
      locale: localeName,
      other: 'devinés',
      one: 'deviné',
    );
    return 'itinéraire ($count $_temp0, dont $guessed $_temp1)';
  }

  @override
  String get chat_statusQueued => 'En file d\'attente';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Aucun répéteur ne vous a entendu. Nouvel essai dès qu\'un répéteur sera à portée.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'La radio de $name envoie des codes de répéteur courts (1 octet). Pathfinder ne peut pas apprendre d\'itinéraires vers ce contact tant que sa radio n\'utilise pas des codes de 2 octets.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Envoi · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Nouvel essai · $kind · tentative $attempt sur $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Remis · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Remis à la tentative $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Remis en retard · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Remis · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'tentatives',
      one: 'tentative',
    );
    return 'Échec après $attempts $_temp0 · appuyez pour renvoyer';
  }

  @override
  String get chat_statusFailedShort => 'Échec · appuyez pour renvoyer';

  @override
  String get chat_resendingByFlood => 'Renvoi vers tout le réseau';

  @override
  String get pathfinderHelp_title => 'Ce que fait Pathfinder';

  @override
  String get pathfinderHelp_what =>
      'Votre radio mémorise un seul itinéraire vers chaque contact et, quand cet itinéraire échoue, envoie le message à tout le réseau. Pathfinder écoute tout ce que la radio entend : les annonces des répéteurs, les conversations des canaux, les messages des autres. Il en tire une carte des répéteurs qui s\'entendent entre eux, de ceux qui vous entendent et de ceux qui entendent chacun de vos contacts.';

  @override
  String get pathfinderHelp_how =>
      'Quand vous envoyez un message, Pathfinder essaie d\'abord son meilleur itinéraire, puis le suivant, et n\'envoie à tout le réseau qu\'en dernier recours. Une icône de chemin ambre signale un message envoyé par un itinéraire Pathfinder.';

  @override
  String get pathfinderHelp_learning =>
      'Il lui faut du temps. Une carte toute neuve ne sait rien : au début, vos messages partent donc exactement comme avant. Après quelques heures d\'écoute au même endroit, il commence à proposer des itinéraires, et chaque remise ou échec lui en apprend davantage. N\'en attendez pas grand-chose le premier jour, ni à chaque fois que vous changez d\'endroit.';

  @override
  String get pathfinderHelp_guessed =>
      'Parfois, il comble un vide en devinant : un lien qu\'il n\'a entendu utilisé que dans l\'autre sens. La ligne sous le message indique alors combien de sauts ont été devinés. Une remise les confirme ; un échec coûte une tentative, et rien n\'est retenu.';

  @override
  String get pathfinderHelp_discover =>
      'Quand il ne sait pas bien quels répéteurs vous entendent ici, Pathfinder envoie une courte requête Discover (au plus une toutes les 10 minutes, et seulement après l\'échec d\'un envoi) et, si la radio a un GPS, retient sur ce téléphone quels répéteurs vous ont entendu dans chaque zone d\'environ 500 m, jamais votre position exacte.';

  @override
  String get pathfinderHelp_off =>
      'Si vous désactivez Pathfinder, la radio achemine les messages exactement comme avant.';

  @override
  String get pathfinderHelp_dontShowAgain => 'Ne plus afficher';

  @override
  String get pathfinderHelp_ok => 'OK';

  @override
  String get settings_pathGraph => 'Pathfinder (expérimental)';

  @override
  String get settings_pathGraphSubtitle =>
      'Apprend des itinéraires à partir de tout ce que la radio entend et essaie d\'abord les meilleurs quand vous envoyez un message privé. Une icône de chemin ambre signale un message envoyé par un itinéraire Pathfinder.';

  @override
  String get map_routeAndTrace => 'Itinéraire et traçage';

  @override
  String get map_pathfinderTrace => 'Traçage aller-retour';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Aller par le meilleur itinéraire de Pathfinder, retour par son meilleur itinéraire retour';

  @override
  String get map_routeBackMirrored =>
      'Aucun itinéraire retour connu pour l\'instant — retour par le même chemin';

  @override
  String get map_traceHelpTitle => 'Boutons du traçage de chemin';

  @override
  String get map_traceHelpCustom =>
      'Saisissez ou choisissez vous-même les répéteurs.';

  @override
  String get map_traceHelpRun =>
      'Envoie un traçage le long des répéteurs sélectionnés, en aller simple.';

  @override
  String get map_traceHelpThereAndBack => 'Aller-retour';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Envoie le traçage à l\'aller, puis au retour par les mêmes répéteurs en sens inverse.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder choisit le meilleur itinéraire passant par les deux derniers répéteurs sélectionnés, et le meilleur itinéraire de retour vers vous. Le résultat apprend à Pathfinder quels liens fonctionnent vraiment. Il faut deux répéteurs sélectionnés.';

  @override
  String get map_traceHelpRemoveLast => 'Retire le dernier répéteur du chemin.';

  @override
  String get map_traceHelpCancel =>
      'Arrête la construction du traçage. Affiché avant toute sélection de répéteur.';

  @override
  String get chat_resendingByRoute => 'Renvoi via l\'itinéraire défini';

  @override
  String get room_mute => 'Désactiver les notifications de la room';

  @override
  String get room_unmute => 'Réactiver les notifications de la room';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'membre';

  @override
  String get room_roleReadOnly => 'lecture seule';

  @override
  String room_clockOff(int minutes) {
    return 'L\'horloge de la room décale d\'environ $minutes min — les heures des messages peuvent être fausses';
  }

  @override
  String get room_fixClock => 'Régler l\'horloge';

  @override
  String get room_clockSyncSent =>
      'Synchronisation de l\'horloge envoyée à la room';

  @override
  String get room_readOnlyNotice =>
      'Lecture seule : la room n\'a pas accepté votre mot de passe, vos messages n\'atteindront pas les autres membres.';

  @override
  String get room_postAnnouncement => 'Publier une annonce';

  @override
  String get room_postAnnouncementSubtitle =>
      'Envoyer un message au nom de la room à tous les membres';

  @override
  String get room_announcementSent => 'Annonce publiée';

  @override
  String get room_announcementFailed => 'Échec de la publication de l\'annonce';

  @override
  String get room_users => 'Utilisateurs de la room';

  @override
  String get room_usersSubtitle => 'Voir les admins et définir les rôles';

  @override
  String get room_usersAdminsNote =>
      'La room ne liste que ses admins. Les membres utilisant le mot de passe de la room n\'apparaissent pas.';

  @override
  String get room_usersLoadFailed =>
      'Impossible de charger la liste des admins';

  @override
  String get room_setUserRole => 'Définir le rôle';

  @override
  String get room_removeAccess => 'Retirer l\'accès';

  @override
  String get room_removeOnlyUnknown =>
      'Cet utilisateur n\'est pas dans vos contacts : il peut seulement être retiré, pas modifié.';

  @override
  String get room_roleUpdated => 'Rôle mis à jour';

  @override
  String get room_roleUpdateFailed => 'Échec du changement de rôle';

  @override
  String get room_postsStored => 'Messages stockés';

  @override
  String get room_postsDelivered => 'Messages distribués';

  @override
  String get room_reloadPosts => 'Recharger les messages récents';

  @override
  String get room_reloadPostsExplain =>
      'Demande à la room de renvoyer ses messages récents (elle en garde jusqu\'à 32). Le mot de passe de la room sera demandé. Vos messages existants sont conservés.';

  @override
  String get room_reloadFailed =>
      'Impossible de réinitialiser la room sur la radio';

  @override
  String get companionCli_title => 'Ligne de commande';

  @override
  String get companionCli_settingsSubtitle =>
      'Saisir des commandes texte pour cette radio';

  @override
  String get companionCli_rebooting => 'Redémarrage de la radio…';

  @override
  String get companionCli_cancelled => 'Annulé';

  @override
  String get companionCli_poweringOff => 'Extinction de la radio…';

  @override
  String get companionCli_noReply => 'Pas de réponse de la radio. Réessayez.';

  @override
  String get companionCli_powerOffTitle => 'Éteindre la radio ?';

  @override
  String get companionCli_powerOffBody =>
      'Elle reste éteinte jusqu\'à ce que vous appuyiez sur son bouton ou la branchiez.';

  @override
  String get companionCli_powerOff => 'Éteindre';

  @override
  String get companionCli_quickBoard => 'Carte';

  @override
  String get companionCli_quickWifiStatus => 'État WiFi';

  @override
  String get companionCli_quickWifiAddress => 'Adresse WiFi';

  @override
  String get companionCli_helpBoard =>
      'Affiche le fabricant et le modèle de la carte.';

  @override
  String get companionCli_helpReboot => 'Redémarre la radio.';

  @override
  String get companionCli_helpPowerOff => 'Éteint la radio.';

  @override
  String get companionCli_helpSetPin =>
      'Définit le code PIN d\'appairage Bluetooth. Appliqué après un redémarrage.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Définit le nombre d\'heures ajoutées à l\'UTC pour l\'horloge de l\'écran de la radio (-12 à +14).';

  @override
  String get companionCli_helpSetTx =>
      'Définit la puissance d\'émission en dBm. Appliqué immédiatement.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Définit le seuil d\'interférence en dB. 0 désactive la détection d\'interférences.';

  @override
  String get companionCli_helpSetCad =>
      'Écoute les autres radios avant d\'émettre (détection d\'activité sur le canal).';

  @override
  String get companionCli_helpSetRxGain =>
      'Gain de réception renforcé, sur les radios SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Octets par répéteur dans un itinéraire : 0 = 1 octet, 1 = 2 octets, 2 = 3 octets.';

  @override
  String get companionCli_helpWifiStatus =>
      'Indique si la radio est connectée au réseau WiFi.';

  @override
  String get companionCli_helpWifiIp =>
      'Affiche l\'adresse de la radio sur le réseau WiFi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Définit le nom du réseau WiFi. Appliqué après un redémarrage.';

  @override
  String get companionCli_helpWifiPwd =>
      'Définit le mot de passe WiFi. Appliqué après un redémarrage.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Active (1) ou désactive (0) le WiFi. Appliqué après un redémarrage.';

  @override
  String get companionCli_helpWifiClear =>
      'Oublie le réseau WiFi. Appliqué après un redémarrage.';

  @override
  String get companionCli_remoteNoReply =>
      'Pas de réponse. L\'autre radio doit avoir le firmware 1.18 ou plus récent, et vous autoriser à utiliser sa ligne de commande.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Envoyé. Une radio ne répond pas à un redémarrage ni à une extinction.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name a tenté d\'utiliser la ligne de commande de votre radio : « $command ». Ce n\'était pas autorisé.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'A tenté d\'utiliser la ligne de commande de votre radio : « $command ». Ce n\'était pas autorisé.';
  }

  @override
  String get contact_remoteCli => 'Autoriser la ligne de commande à distance';

  @override
  String get contact_remoteCliSubtitle =>
      'Permet à ce contact d\'exécuter des commandes sur votre radio';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Laisser $name contrôler votre radio ?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name pourra modifier les paramètres de votre radio, lire votre mot de passe WiFi, renommer votre radio, la redémarrer ou l\'éteindre. N\'autorisez qu\'une personne en qui vous avez entièrement confiance.';
  }

  @override
  String get contact_remoteCliAllow => 'Autoriser';

  @override
  String get connection_secondApp =>
      'Une autre application est connectée à cette radio. Les messages et les paramètres risquent de se mélanger. Fermez l\'autre application.';

  @override
  String get wifi_title => 'WiFi';

  @override
  String get wifi_settingsSubtitle => 'Réseau, mot de passe et connexion';

  @override
  String get wifi_use => 'Utiliser le WiFi';

  @override
  String get wifi_networkName => 'Nom du réseau';

  @override
  String get wifi_password => 'Mot de passe';

  @override
  String get wifi_passwordUnchanged => 'Inchangé';

  @override
  String get wifi_showPassword => 'Afficher le mot de passe';

  @override
  String get wifi_nameMissing => 'Saisissez le nom du réseau';

  @override
  String get wifi_nameTooLong =>
      'Le nom du réseau est trop long (32 octets au maximum)';

  @override
  String get wifi_passwordTooLong =>
      'Le mot de passe est trop long (63 octets au maximum)';

  @override
  String get wifi_savedRestart =>
      'Enregistré. Les changements WiFi s\'appliquent après le redémarrage de la radio.';

  @override
  String get wifi_forget => 'Oublier le réseau';

  @override
  String get wifi_forgetConfirm =>
      'Oublier ce réseau WiFi ? La radio cessera d\'utiliser le WiFi après son redémarrage.';

  @override
  String wifi_notAccepted(String reply) {
    return 'La radio n\'a pas accepté : $reply';
  }

  @override
  String get wifi_noReply => 'Pas de réponse de la radio. Réessayez.';

  @override
  String get wifi_restartTitle => 'Redémarrer la radio ?';

  @override
  String get wifi_later => 'Plus tard';

  @override
  String get wifi_loadFailed =>
      'Impossible de lire les paramètres WiFi de la radio.';

  @override
  String wifi_connectedTo(String address) {
    return 'Connecté · $address';
  }

  @override
  String get wifi_notConnected => 'Non connecté au WiFi';

  @override
  String wifi_portNote(int port) {
    return 'Les applications du même réseau peuvent se connecter sur le port $port';
  }

  @override
  String get wifi_connectOverWifi => 'Se connecter via WiFi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax va se déconnecter de cette radio et ouvrir l\'écran TCP avec $address, port $port pré-remplis. Appuyez alors sur Connecter.';
  }

  @override
  String get wifi_noteRestart =>
      'Les changements s\'appliquent après le redémarrage de la radio.';

  @override
  String get wifi_noteSecurity =>
      'Toute personne sur votre réseau WiFi peut se connecter à la radio sur le port 5000. Aucun mot de passe n\'est demandé.';

  @override
  String get wifi_noteBattery =>
      'Le WiFi garde la radio éveillée : la batterie se vide plus vite.';

  @override
  String get wifi_noteWrongPassword =>
      'Si le mot de passe est faux, la radio réessaie toutes les quelques secondes. Le Bluetooth continue de fonctionner.';

  @override
  String get room_selfDemoteWarning =>
      'Vous modifiez votre propre accès. Si vous abandonnez votre rôle d\'admin, seule la console de la room peut le rétablir.';

  @override
  String get scanner_offlineMaps => 'Cartes hors ligne';

  @override
  String get appSettings_offlineMaps => 'Cartes hors ligne';

  @override
  String get appSettings_offlineMapsNone => 'Aucune téléchargée';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count régions',
      one: '$count région',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones de cartes marines',
      one: '$count zone de cartes marines',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mises à jour disponibles',
      one: '$count mise à jour disponible',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Télécharger les cartes en Wi‑Fi uniquement';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Les téléchargements de cartes attendent une connexion Wi‑Fi';

  @override
  String get offlineMaps_title => 'Cartes hors ligne';

  @override
  String get offlineMaps_tabMaps => 'Cartes';

  @override
  String get offlineMaps_tabCharts => 'Cartes marines';

  @override
  String get offlineMaps_chartsNotice => 'Pas pour la navigation · Pourquoi ?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Suggestion · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Zones de cartes marines par côte';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones',
      one: '$count zone',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Téléchargées : $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Sélectionnées : $count';
  }

  @override
  String get offlineMaps_selectAll => 'Tout sélectionner';

  @override
  String get offlineMaps_clearSelection => 'Effacer';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Également dans $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Pas encore disponible';

  @override
  String get offlineMaps_chartsHint =>
      'Les cartes marines NOAA se choisissent par côte, dans l\'onglet Cartes marines.';

  @override
  String offlineMaps_chartsName(String area) {
    return 'Cartes marines NOAA $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zones',
      one: '$count zone',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Téléchargées';

  @override
  String get offlineMaps_refresh => 'Rechercher de nouvelles cartes';

  @override
  String get offlineMaps_loading => 'Chargement des cartes disponibles…';

  @override
  String get offlineMaps_serverError =>
      'Impossible de joindre le serveur de cartes';

  @override
  String get offlineMaps_unavailable =>
      'Aucune carte disponible pour l\'instant';

  @override
  String get offlineMaps_unavailableHint => 'Revenez plus tard.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Aucune carte marine NOAA disponible pour l\'instant';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Affichage de la liste du $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Mettez à jour MeshTrax pour obtenir les cartes les plus récentes.';

  @override
  String get offlineMaps_world => 'Monde';

  @override
  String get offlineMaps_suggested => 'Suggestions';

  @override
  String get offlineMaps_regions => 'Régions';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Régions de $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count à l\'intérieur';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size de cartes hors ligne sur cet appareil';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Mises à jour ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Tout mettre à jour ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Téléchargement';

  @override
  String get offlineMaps_update => 'Mettre à jour';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Téléchargé le $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Mise à jour disponible';

  @override
  String get offlineMaps_otherFiles => 'Autres fichiers de carte';

  @override
  String get offlineMaps_emptyTitle => 'Pas encore de carte hors ligne';

  @override
  String get offlineMaps_emptyBody =>
      'Téléchargez une région pour utiliser la carte sans connexion.';

  @override
  String get offlineMaps_findMaps => 'Trouver des cartes';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Supprimer $name ?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Cela libère $size. Vous pourrez la télécharger à nouveau plus tard.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return 'Supprimé : $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done sur $total';
  }

  @override
  String get offlineMaps_kindMap => 'Carte';

  @override
  String get offlineMaps_kindMapDetail =>
      'Rues, sentiers et lieux OpenStreetMap';

  @override
  String get offlineMaps_kindContours => 'Courbes de niveau';

  @override
  String get offlineMaps_kindContoursDetail => 'Lignes d\'altitude';

  @override
  String get offlineMaps_kindUsgs => 'Carte topo USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Sentiers, cours d\'eau, réserves';

  @override
  String get offlineMaps_kindTerrain => 'Ombrage du relief';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Collines et montagnes, ombrées sous la carte';

  @override
  String get offlineMaps_kindCharts => 'Cartes marines NOAA';

  @override
  String get offlineMaps_usOnly => 'États-Unis uniquement';

  @override
  String offlineMaps_download(String size) {
    return 'Télécharger ($size)';
  }

  @override
  String get offlineMaps_downloadTotal => 'Télécharger';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Téléchargement volumineux ($size). Utilisez le Wi‑Fi et laissez votre appareil en charge.';
  }

  @override
  String get offlineMaps_waiting => 'En attente…';

  @override
  String get offlineMaps_checking => 'Vérification du téléchargement…';

  @override
  String get offlineMaps_retrying => 'Nouvel essai…';

  @override
  String offlineMaps_failed(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get offlineMaps_pause => 'Pause';

  @override
  String get offlineMaps_resume => 'Reprendre';

  @override
  String get offlineMaps_deleteRegion => 'Supprimer la région';

  @override
  String get offlineMaps_notInCatalogue => 'Non disponible pour cette région';

  @override
  String get offlineMaps_notificationRunning => 'Téléchargement de carte';

  @override
  String get offlineMaps_notificationPaused =>
      'Téléchargement de carte en pause';

  @override
  String get offlineMaps_notificationFailed =>
      'Échec du téléchargement de carte';

  @override
  String get offlineMaps_clearTileCache => 'Vider le cache des cartes en ligne';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Supprimer les tuiles de carte en ligne enregistrées pendant la consultation ? Les cartes téléchargées sont conservées.';

  @override
  String get offlineMaps_tileCacheCleared => 'Cache des cartes en ligne vidé';

  @override
  String get map_notForNavigation => 'Pas pour la navigation';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax dessine ces cartes à partir des données de la NOAA pour vous aider à voir l\'eau autour de vos radios et à planifier. Ce ne sont pas des cartes officielles. Ne naviguez pas avec.';

  @override
  String get map_chartsNoticeWhy => 'Pourquoi :';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Elles se périment. La NOAA corrige ses cartes en permanence ; une carte téléchargée reste telle quelle jusqu\'à ce que vous la mettiez à jour dans Cartes hors ligne.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Elles omettent des éléments. Beaucoup de symboles, de secteurs de feux et de notes ne sont pas dessinés, et certaines étiquettes n\'apparaissent qu\'en zoomant.';

  @override
  String get map_chartsNoticePositions =>
      'Les positions peuvent être fausses ou anciennes. Le GPS peut se tromper de 10 m (30 ft) ou plus, et un nœud n\'est qu\'à l\'endroit où il s\'est signalé pour la dernière fois.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax n\'est pas un traceur de cartes certifié.';

  @override
  String get map_chartsNoticeUse =>
      'Pour naviguer, utilisez des cartes NOAA officielles et à jour (papier, ou ENC NOAA dans un traceur certifié) avec les derniers Avis aux navigateurs.';

  @override
  String get map_sourceOnline => 'En ligne';

  @override
  String get map_sourceOffline => 'Hors ligne';

  @override
  String get map_downloadForDetail =>
      'Téléchargez une région pour plus de détails';

  @override
  String get map_zoomInForOfflineMap =>
      'Zoomez pour voir votre carte hors ligne';

  @override
  String get map_noCharts => 'Aucune carte marine ici';

  @override
  String get map_myLocation => 'Ma position';

  @override
  String get map_zoomIn => 'Zoom avant';

  @override
  String get map_zoomOut => 'Zoom arrière';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS activé';

  @override
  String get gps_off => 'GPS désactivé';

  @override
  String get gps_onHint => 'La radio met à jour sa position via le GPS.';

  @override
  String get gps_offHint =>
      'Le désactiver économise la batterie de la radio. Une fois activé, il peut mettre quelques minutes à trouver votre position.';

  @override
  String get gps_asking => 'Interrogation de la radio...';

  @override
  String get gps_noPosition =>
      'Pas encore de position. En extérieur, la première peut prendre quelques minutes.';

  @override
  String get gps_position => 'Position';

  @override
  String get gps_altitude => 'Altitude';

  @override
  String gps_readAgo(String ago) {
    return 'Lu depuis la radio il y a $ago';
  }

  @override
  String get gps_turnOnTitle => 'Activer le GPS ?';

  @override
  String get gps_turnOnBody =>
      'Le GPS de la radio est désactivé. Une fois activé, il peut mettre quelques minutes à trouver votre position.';

  @override
  String get gps_turnOn => 'Activer';

  @override
  String get gps_notNow => 'Plus tard';

  @override
  String get map_zoomInForCharts => 'Zoomez pour voir vos cartes marines';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Télécharger $region · $size';
  }

  @override
  String get mapLayers_title => 'Couches de la carte';

  @override
  String get mapLayers_mapType => 'Type de carte';

  @override
  String get mapLayers_standard => 'Standard';

  @override
  String get mapLayers_usgs => 'Topo USGS';

  @override
  String get mapLayers_charts => 'Cartes marines';

  @override
  String get mapLayers_notDownloaded => 'Non téléchargé';

  @override
  String get mapLayers_offlineOnly => 'Hors ligne uniquement';

  @override
  String get mapLayers_details => 'Détails de la carte';

  @override
  String get mapLayers_contours => 'Courbes de niveau';

  @override
  String get mapLayers_hillShading => 'Ombrage du relief';

  @override
  String get mapLayers_places => 'Places';

  @override
  String get mapLayers_dark => 'Carte sombre';

  @override
  String get mapLayers_downloadedAreas => 'Zones téléchargées';

  @override
  String get mapLayers_nodes => 'Nœuds';

  @override
  String get mapLayers_pins => 'Épingles';

  @override
  String get mapLayers_guessed => 'Positions estimées';

  @override
  String get mapLayers_moreFilters => 'Plus de filtres';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Dernière activité, préfixe de clé, chevauchements';

  @override
  String get map_legend => 'Légende';

  @override
  String get scanner_map => 'Carte';

  @override
  String get structured_openMap => 'Ouvrir la carte';

  @override
  String get structured_addToCalendar => 'Ajouter au calendrier';

  @override
  String get structured_details => 'Détails';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Événement';

  @override
  String get structured_notice => 'Avis';

  @override
  String get structured_allDay => 'Toute la journée';

  @override
  String get structured_calendarFailed => 'Impossible d\'ouvrir le calendrier';

  @override
  String get structured_today => 'Aujourd\'hui';

  @override
  String get structured_tomorrow => 'Demain';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dans $count jours',
      one: 'Dans $count jour',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Passé';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Jour $day sur $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '$count jour',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Date de fin';

  @override
  String get dialog_eventSameDay => 'Même jour';

  @override
  String get structured_map => 'Carte';

  @override
  String get structured_navigate => 'Y aller';

  @override
  String get structured_channel => 'Canal';

  @override
  String get structured_contact => 'Contact';

  @override
  String get structured_room => 'Room';

  @override
  String get structured_repeater => 'Répéteur';

  @override
  String get structured_sensor => 'Capteur';

  @override
  String get structured_joinChannel => 'Rejoindre le canal';

  @override
  String get structured_addContact => 'Ajouter le contact';

  @override
  String get structured_addRoom => 'Ajouter la room';

  @override
  String get structured_addRepeater => 'Ajouter le répéteur';

  @override
  String get structured_addSensor => 'Ajouter le capteur';

  @override
  String get structured_open => 'Ouvrir';

  @override
  String get structured_added => 'Ajouté';

  @override
  String get tray_add => 'Ajouter';

  @override
  String get tray_myLocation => 'Ma position';

  @override
  String get tray_pointOnMap => 'Point sur la carte';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Événement';

  @override
  String get tray_notice => 'Avis';

  @override
  String get tray_noRadioPosition =>
      'Votre radio n\'a pas encore de position. Choisissez-en une sur la carte.';

  @override
  String get dialog_insert => 'Insérer';

  @override
  String get dialog_eventTitle => 'Titre';

  @override
  String get dialog_eventDate => 'Date';

  @override
  String get dialog_eventStart => 'Début';

  @override
  String get dialog_eventEnd => 'Fin';

  @override
  String get dialog_eventNoEnd => 'Pas d\'heure de fin';

  @override
  String get dialog_eventPlace => 'Lieu (facultatif)';

  @override
  String get dialog_pickOnMap => 'Choisir sur la carte';

  @override
  String get dialog_sosTitle => 'Envoyer un SOS';

  @override
  String get dialog_sosText => 'Que s\'est-il passé ?';

  @override
  String get dialog_noticeTitle => 'Avis';

  @override
  String get dialog_noticeText => 'Que doit savoir tout le monde ?';

  @override
  String get dialog_labelTitle => 'Point sur la carte';

  @override
  String get dialog_note => 'Note (facultatif)';

  @override
  String get paste_convertLocation =>
      'On dirait un lien de carte. Le convertir en Position ?';

  @override
  String get paste_convertEvent =>
      'On dirait un partage de calendrier. Le convertir en Événement ?';

  @override
  String get paste_convert => 'Convertir';

  @override
  String get paste_resolving => 'Résolution du lien…';

  @override
  String get paste_resolveFailed => 'Impossible de résoudre le lien';

  @override
  String get pinned_dismiss => 'Ignorer';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Rejoindre le canal $name ?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Vous êtes déjà dans $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Vous avez rejoint $name';
  }

  @override
  String get map_pickPositionHint =>
      'Appuyez sur la carte pour choisir une position';

  @override
  String get map_legendMesh => 'Réseau mesh';

  @override
  String get chartLegend_title => 'Symboles des cartes marines';

  @override
  String get chartLegend_sectionBuoys => 'Bouées et balises';

  @override
  String get chartLegend_sectionLights => 'Feux';

  @override
  String get chartLegend_sectionHazards => 'Dangers';

  @override
  String get chartLegend_sectionTides => 'Marées et courants';

  @override
  String get chartLegend_sectionDepths => 'Profondeurs et fonds';

  @override
  String get chartLegend_sectionAreas => 'Zones, voies et lignes';

  @override
  String get chartLegend_sectionLandmarks => 'Amers';

  @override
  String get chartLegend_sectionAbbreviations => 'Abréviations';

  @override
  String get chartLegend_chartNo1 => 'Tous les symboles : U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Bouée cylindrique verte';

  @override
  String get chartLegend_portBuoyHint =>
      'À laisser sur votre gauche en rentrant du large';

  @override
  String get chartLegend_starboardBuoy => 'Bouée conique rouge';

  @override
  String get chartLegend_starboardBuoyHint =>
      'À laisser sur votre droite en rentrant : rouge à droite au retour';

  @override
  String get chartLegend_junctionBuoy => 'Bouée à bandes';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Bifurcation de chenal : à traiter comme la couleur de sa bande supérieure';

  @override
  String get chartLegend_safeWaterBuoy => 'Rayures rouges et blanches';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Eaux saines tout autour, souvent à l\'entrée d\'un chenal';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Bandes noires et rouges';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Petit danger entouré d\'eaux saines : à éviter';

  @override
  String get chartLegend_specialBuoy => 'Bouée jaune';

  @override
  String get chartLegend_specialBuoyHint =>
      'Usage spécial, pas pour se guider : mouillage, câble, recherche';

  @override
  String get chartLegend_cardinalBuoy => 'Noire et jaune';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Marque cardinale : passez du côté dont elle porte le nom (rare aux États-Unis)';

  @override
  String get chartLegend_mooringBuoy => 'Coffre d\'amarrage';

  @override
  String get chartLegend_portBeacon => 'Balise carrée verte';

  @override
  String get chartLegend_portBeaconHint =>
      'Comme une bouée verte : à laisser sur votre gauche en rentrant';

  @override
  String get chartLegend_starboardBeacon => 'Balise triangulaire rouge';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Comme une bouée rouge : à laisser sur votre droite en rentrant';

  @override
  String get chartLegend_otherBeacon => 'Balise en losange';

  @override
  String get chartLegend_otherBeaconHint =>
      'Information ou avertissement, pas un côté du chenal';

  @override
  String get chartLegend_beaconTower => 'Tour à feu ou tourelle';

  @override
  String get chartLegend_topmark => 'Voyant';

  @override
  String get chartLegend_topmarkHint =>
      'La forme au sommet d\'une marque précise sa signification';

  @override
  String get chartLegend_light => 'Feu';

  @override
  String get chartLegend_lightHint =>
      'La flamme magenta signale un feu ; son étiquette indique son rythme';

  @override
  String get chartLegend_lightExample => 'Éclats verts, toutes les 4 secondes';

  @override
  String get chartLegend_lightExampleHint =>
      'Étiquette d\'un feu : rythme, couleur, puis période';

  @override
  String get chartLegend_lightFixed => 'Fixe';

  @override
  String get chartLegend_lightFixedHint => 'Un feu continu';

  @override
  String get chartLegend_lightFlashing => 'À éclats';

  @override
  String get chartLegend_lightFlashingHint =>
      'Éclats brefs, obscurité plus longue entre eux';

  @override
  String get chartLegend_lightGroup => 'À éclats groupés';

  @override
  String get chartLegend_lightGroupHint =>
      'Éclats par groupes, ici 2, puis obscurité';

  @override
  String get chartLegend_lightComposite => 'Groupes composés';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 éclats, puis 1 : marque une bifurcation de chenal';

  @override
  String get chartLegend_lightQuick => 'Scintillant';

  @override
  String get chartLegend_lightQuickHint => 'Environ un éclat par seconde';

  @override
  String get chartLegend_lightIsophase => 'Isophase';

  @override
  String get chartLegend_lightIsophaseHint => 'Lumière et obscurité égales';

  @override
  String get chartLegend_lightOcculting => 'À occultations';

  @override
  String get chartLegend_lightOccultingHint =>
      'Allumé plus longtemps qu\'éteint';

  @override
  String get chartLegend_lightMorse => 'Code morse A';

  @override
  String get chartLegend_lightMorseHint => 'Court, long : eaux saines';

  @override
  String get chartLegend_lightAlternating => 'Alternatif';

  @override
  String get chartLegend_lightAlternatingHint => 'Change de couleur';

  @override
  String get chartLegend_lightColours => 'Blanc, rouge, vert, jaune';

  @override
  String get chartLegend_lightPeriod => 'Période';

  @override
  String get chartLegend_lightPeriodHint => 'Secondes pour un cycle complet';

  @override
  String get chartLegend_rock => 'Roche submergée';

  @override
  String get chartLegend_rockHint =>
      'Toujours couverte, mais parfois à faible profondeur';

  @override
  String get chartLegend_rockAwash => 'Roche à fleur d\'eau';

  @override
  String get chartLegend_rockAwashHint => 'Près de la surface à marée basse';

  @override
  String get chartLegend_rockCovers => 'Roche découvrante';

  @override
  String get chartLegend_rockCoversHint =>
      'Visible à marée basse, couverte à marée haute';

  @override
  String get chartLegend_wreckDangerous => 'Épave dangereuse';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Assez peu profonde pour être heurtée';

  @override
  String get chartLegend_wreck => 'Épave';

  @override
  String get chartLegend_wreckHint =>
      'Assez profonde pour les bateaux en surface ; ne mouillez pas';

  @override
  String get chartLegend_wreckShowing => 'Épave émergente';

  @override
  String get chartLegend_wreckShowingHint => 'Une partie dépasse de l\'eau';

  @override
  String get chartLegend_obstruction => 'Obstruction';

  @override
  String get chartLegend_obstructionHint =>
      'Un objet sur le fond ; sa profondeur si elle est connue';

  @override
  String get chartLegend_foulGround => 'Fonds malsains';

  @override
  String get chartLegend_foulGroundHint =>
      'Passage sans danger, mais ne mouillez pas et ne chalutez pas';

  @override
  String get chartLegend_hazardArea => 'Limite d\'une zone dangereuse';

  @override
  String get chartLegend_hazardAreaHint =>
      'Roches, épaves ou obstructions à l\'intérieur';

  @override
  String get chartLegend_pile => 'Pieu ou poteau';

  @override
  String get chartLegend_floodStream => 'Courant de flot';

  @override
  String get chartLegend_floodStreamHint =>
      'Courant de marée pendant la montée';

  @override
  String get chartLegend_ebbStream => 'Courant de jusant';

  @override
  String get chartLegend_ebbStreamHint =>
      'Courant de marée pendant la descente';

  @override
  String get chartLegend_current => 'Courant';

  @override
  String get chartLegend_currentHint =>
      'Porte dans le même sens quelle que soit la marée';

  @override
  String get chartLegend_rips => 'Remous de marée ou tourbillons';

  @override
  String get chartLegend_ripsHint => 'Eau agitée et tourbillonnante';

  @override
  String get chartLegend_breakers => 'Brisants';

  @override
  String get chartLegend_breakersHint =>
      'Vagues qui déferlent sur des hauts-fonds';

  @override
  String get chartLegend_sounding => 'Sonde';

  @override
  String get chartLegend_soundingHint => 'Profondeur à une basse mer moyenne';

  @override
  String get chartLegend_depthContour => 'Isobathe';

  @override
  String get chartLegend_depthContourHint =>
      'Son étiquette donne la profondeur';

  @override
  String get chartLegend_drying => 'Découvre à marée basse';

  @override
  String get chartLegend_dredged => 'Chenal dragué';

  @override
  String get chartLegend_dredgedHint => 'Entretenu à la profondeur indiquée';

  @override
  String get chartLegend_swept => 'Zone balayée';

  @override
  String get chartLegend_sweptHint =>
      'Vérifiée libre jusqu\'à la profondeur indiquée';

  @override
  String get chartLegend_unsurveyed => 'Non hydrographié';

  @override
  String get chartLegend_unsurveyedHint => 'Aucune profondeur mesurée';

  @override
  String get chartLegend_weed => 'Varech ou algues';

  @override
  String get chartLegend_restricted => 'Zone d\'accès restreint';

  @override
  String get chartLegend_restrictedHint =>
      'Accès limité ; les petits traits pointent vers l\'intérieur';

  @override
  String get chartLegend_regulatedLimit => 'Limite d\'une zone réglementée';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Mouillage, zone de câbles, zone de tir, etc. : voir son étiquette';

  @override
  String get chartLegend_greyLimit =>
      'Zone de dépôt, de pêche ou d\'aquaculture';

  @override
  String get chartLegend_anchorage => 'Mouillage';

  @override
  String get chartLegend_anchorBerth => 'Poste de mouillage';

  @override
  String get chartLegend_noAnchoring => 'Mouillage interdit';

  @override
  String get chartLegend_caution => 'Zone de vigilance';

  @override
  String get chartLegend_cautionHint => 'Redoublez de prudence ici';

  @override
  String get chartLegend_trafficLane => 'Voie de circulation';

  @override
  String get chartLegend_trafficLaneHint =>
      'Grands navires, sens unique : traversez à angle droit';

  @override
  String get chartLegend_separationZone => 'Zone de séparation';

  @override
  String get chartLegend_separationZoneHint =>
      'Entre les voies de circulation : n\'y entrez pas';

  @override
  String get chartLegend_precautionary => 'Zone de prudence';

  @override
  String get chartLegend_precautionaryHint =>
      'Les navires convergent : prudence';

  @override
  String get chartLegend_fairway => 'Chenal';

  @override
  String get chartLegend_fairwayHint => 'Un chenal principal';

  @override
  String get chartLegend_track => 'Route recommandée';

  @override
  String get chartLegend_ferry => 'Ligne de ferry';

  @override
  String get chartLegend_leadingLine => 'Alignement';

  @override
  String get chartLegend_leadingLineHint =>
      'Alignez ses deux marques pour rester dans le chenal';

  @override
  String get chartLegend_cable => 'Câble sous-marin';

  @override
  String get chartLegend_cableHint => 'Ne mouillez pas';

  @override
  String get chartLegend_pipeline => 'Conduite sous-marine';

  @override
  String get chartLegend_pipelineHint => 'Ne mouillez pas';

  @override
  String get chartLegend_overhead => 'Câble aérien';

  @override
  String get chartLegend_overheadHint => 'Sa hauteur libre est notée VC';

  @override
  String get chartLegend_tower => 'Tour';

  @override
  String get chartLegend_windTurbine => 'Éolienne';

  @override
  String get chartLegend_chimney => 'Cheminée';

  @override
  String get chartLegend_mast => 'Mât ou antenne';

  @override
  String get chartLegend_church => 'Église ou clocher';

  @override
  String get chartLegend_flagstaff => 'Mât de pavillon';

  @override
  String get chartLegend_dome => 'Dôme';

  @override
  String get chartLegend_landmark => 'Autre amer';

  @override
  String get chartLegend_abbrAnch => 'Mouillage';

  @override
  String get chartLegend_abbrWk => 'Épave';

  @override
  String get chartLegend_abbrBr => 'Brisants';

  @override
  String get chartLegend_abbrWd => 'Algues';

  @override
  String get chartLegend_abbrVar => 'Déclinaison magnétique';

  @override
  String get chartLegend_abbrVc => 'Hauteur libre sous un pont ou un câble';

  @override
  String get chartLegend_abbrTr => 'Tour';

  @override
  String get chartLegend_abbrCh => 'Église';

  @override
  String get chartLegend_abbrChy => 'Cheminée';

  @override
  String get chartLegend_abbrFs => 'Mât de pavillon';

  @override
  String get chartLegend_abbrTk => 'Réservoir';

  @override
  String get chartLegend_abbrRBn => 'Radiophare';

  @override
  String get chartLegend_abbrCg => 'Station des garde-côtes';

  @override
  String get chartLegend_abbrRacon => 'Balise radar : visible au radar';

  @override
  String get chartLegend_abbrFog =>
      'Signal de brume : corne, cloche, gong, sifflet ou sirène';

  @override
  String get chartLegend_abbrVAis =>
      'Aide virtuelle : visible uniquement sur l\'AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'De $from à $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Plus de $depth';
  }

  @override
  String get parkLegend_title => 'Symboles des parcs et sentiers';

  @override
  String get parkLegend_campsite => 'Camping';

  @override
  String get parkLegend_picnicSite => 'Aire de pique-nique';

  @override
  String get parkLegend_shelter => 'Abri';

  @override
  String get parkLegend_toilets => 'Toilettes';

  @override
  String get parkLegend_drinkingWater => 'Eau potable';

  @override
  String get parkLegend_parking => 'Parking';

  @override
  String get parkLegend_viewpoint => 'Point de vue';

  @override
  String get parkLegend_attraction => 'Site touristique';

  @override
  String get parkLegend_gate => 'Barrière';

  @override
  String get parkLegend_telephone => 'Téléphone';

  @override
  String get parkLegend_information => 'Panneau d\'information';

  @override
  String get parkLegend_guidepost => 'Poteau indicateur';

  @override
  String get dialog_noticeExpires => 'Expiration';

  @override
  String get dialog_noticeNoExpiry => 'Jamais';

  @override
  String get dialog_noticeExpiryRequired =>
      'Choisissez une date (obligatoire dans une room)';

  @override
  String get dialog_noticeExpiryTime => 'Heure';

  @override
  String get dialog_noticeEndOfDay => 'Fin de journée';

  @override
  String structured_until(String when) {
    return 'Jusqu\'au $when';
  }

  @override
  String get structured_expired => 'Expiré';

  @override
  String get structured_announcement => 'Annonce';

  @override
  String structured_locationOf(String name) {
    return 'Position de $name';
  }

  @override
  String get reaction_searchHint => 'Rechercher un émoji';

  @override
  String get reaction_noResults => 'Aucun émoji trouvé';

  @override
  String get share_qrAndLink => 'Partager le QR code et le lien';

  @override
  String get share_roomTitle => 'Partager la room';

  @override
  String get share_contactTitle => 'Partager le contact';

  @override
  String get share_roomInstructions =>
      'Scannez pour ajouter cette room. Il vous faudra son mot de passe pour vous connecter.';

  @override
  String get share_contactInstructions => 'Scannez pour ajouter ce contact.';

  @override
  String get clearChat_body =>
      'Supprimer les messages de cette conversation sur cet appareil. Les nouveaux messages continueront d\'arriver ici.';

  @override
  String get clearChat_olderThanDay => 'Datant de plus d\'un jour';

  @override
  String get clearChat_olderThanWeek => 'Datant de plus d\'une semaine';

  @override
  String get clearChat_olderThanMonth => 'Datant de plus d\'un mois';

  @override
  String get clearChat_everything => 'Tous les messages';

  @override
  String get chats_markAllRead => 'Tout marquer comme lu';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Marquer $count discussions comme lues ?',
      one: 'Marquer $count discussion comme lue ?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Marquer comme lu';

  @override
  String get chats_nothingUnread => 'Aucun message non lu';

  @override
  String get chats_draft => 'Brouillon';

  @override
  String get contact_teleBlockedTitle => 'Bloqué par votre radio';

  @override
  String contact_teleBlockedBody(String name) {
    return 'Les paramètres de confidentialité de votre radio ne le partagent avec personne, donc $name ne le recevra pas. Les modifier pour que les contacts que vous autorisez le reçoivent ?';
  }

  @override
  String get contact_teleNotNow => 'Pas maintenant';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'Votre radio ne le partage avec personne ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'Votre radio le partage avec tout le monde ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Peut obtenir votre position';

  @override
  String get pathfinder_meshTitle => 'Un autre réseau ?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '$unknown des $heard répéteurs entendus depuis la connexion sont inconnus de la carte Pathfinder « $graph ». Commencer une nouvelle carte pour cette zone ? L\'ancienne est conservée et vous pourrez y revenir depuis l\'écran Pathfinder.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'La plupart des répéteurs entendus depuis la connexion figurent sur la carte Pathfinder « $other », pas sur « $graph ». Passer à celle-ci ?';
  }

  @override
  String get pathfinder_meshNew => 'Nouvelle carte';

  @override
  String get pathfinder_meshSwitch => 'Changer';

  @override
  String get pathfinder_meshKeep => 'Garder celle-ci';

  @override
  String get pathfinder_graphNameTitle => 'Nom de la nouvelle carte';

  @override
  String get pathfinder_graphNameHint => 'Par exemple, Washington';

  @override
  String get pathfinder_graphCreate => 'Créer';

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
