// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Chats';

  @override
  String get chats_title => 'Chats';

  @override
  String get newChat_title => 'Elegir contacto';

  @override
  String newChat_contactCount(int count) {
    return '$count contactos';
  }

  @override
  String get newChat_newContact => 'Nuevo contacto';

  @override
  String get newChat_newChannel => 'Nuevo canal';

  @override
  String get newChat_myContacts => 'Mis contactos';

  @override
  String get newChat_discovered => 'Descubiertos';

  @override
  String get repeaters_title => 'Gestionar repetidores';

  @override
  String get nav_contacts => 'Contactos';

  @override
  String get nav_channels => 'Canales';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_syncing_device_info =>
      'Leyendo información del dispositivo...';

  @override
  String get common_syncing_contacts => 'Leyendo contactos...';

  @override
  String get common_syncing_channels => 'Leyendo canales...';

  @override
  String get common_syncing_messages => 'Leyendo mensajes...';

  @override
  String get common_ok => 'De acuerdo';

  @override
  String get common_connect => 'Conectar';

  @override
  String get common_unknownDevice => 'Dispositivo Desconocido';

  @override
  String get common_save => 'Guardar';

  @override
  String get common_delete => 'Eliminar';

  @override
  String get common_deleteAll => 'Eliminar todo';

  @override
  String get common_close => 'Cerrar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_add => 'Añadir';

  @override
  String get common_settings => 'Configuración';

  @override
  String get common_disconnect => 'Desconectar';

  @override
  String get common_connected => 'Conectado';

  @override
  String get common_disconnected => 'Desconectado';

  @override
  String get common_connectionLost => 'Conexión perdida. Reconectando...';

  @override
  String get common_reconnecting => 'Reconectando...';

  @override
  String get common_create => 'Crear';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_share => 'Compartir';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_retry => 'Intentar';

  @override
  String get common_hide => 'Ocultar';

  @override
  String get common_remove => 'Eliminar';

  @override
  String get common_enable => 'Activar';

  @override
  String get common_disable => 'Desactivar';

  @override
  String get common_reboot => 'Reiniciar';

  @override
  String get common_loading => 'Cargando...';

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
  String get tcpScreenTitle => 'Establecer conexión a través de TCP';

  @override
  String get tcpHostLabel => 'Dirección IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Puerto';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Ingrese la dirección final y conecte.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Conectándose a $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'Se requiere la dirección IP.';

  @override
  String get tcpErrorPortInvalid => 'El puerto debe estar entre 1 y 65535.';

  @override
  String get tcpErrorUnsupported =>
      'El protocolo de transporte TCP no está soportado en esta plataforma.';

  @override
  String get tcpErrorTimedOut => 'La conexión TCP ha caducado.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Error en la conexión TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Conecte mediante USB';

  @override
  String get usbScreenSubtitle =>
      'Seleccione el dispositivo de serie detectado y conéctelo directamente a su nodo MeshCore.';

  @override
  String get usbScreenStatus => 'Seleccione un dispositivo USB';

  @override
  String get usbScreenNote =>
      'La comunicación serial a través de USB está activa en dispositivos Android compatibles y en plataformas de escritorio.';

  @override
  String get usbScreenEmptyState =>
      'No se encontraron dispositivos USB. Conecte uno y vuelva a intentar.';

  @override
  String get usbErrorPermissionDenied =>
      'Se denegó el permiso de acceso a través de USB.';

  @override
  String get usbErrorDeviceMissing =>
      'El dispositivo USB seleccionado ya no está disponible.';

  @override
  String get usbErrorInvalidPort => 'Seleccione un dispositivo USB válido.';

  @override
  String get usbErrorBusy =>
      'Ya se ha iniciado una solicitud de conexión USB adicional.';

  @override
  String get usbErrorNotConnected => 'No hay ningún dispositivo USB conectado.';

  @override
  String get usbErrorOpenFailed =>
      'No se pudo abrir el dispositivo USB seleccionado.';

  @override
  String get usbErrorConnectFailed =>
      'No se pudo conectar con el dispositivo USB seleccionado.';

  @override
  String get usbErrorUnsupported =>
      'La comunicación serial a través de USB no está soportada en esta plataforma.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'A esta versión le falta su biblioteca serie USB, así que no se pueden abrir dispositivos USB. Reinstala MeshTrax o informa de que esta versión está defectuosa.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Este navegador no admite Web Serial. Usa Chrome o Edge con HTTPS (o localhost).';

  @override
  String get usbErrorAlreadyActive => 'La conexión USB ya está activa.';

  @override
  String get usbErrorNoDeviceSelected =>
      'No se ha seleccionado ningún dispositivo USB.';

  @override
  String get usbErrorPortClosed => 'La conexión USB no está activa.';

  @override
  String get usbErrorConnectTimedOut =>
      'La conexión ha caducado. Asegúrese de que el dispositivo tenga el firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Dispositivo de serie web';

  @override
  String get usbStatus_notConnected => 'Seleccione un dispositivo USB';

  @override
  String get usbStatus_connecting => 'Conectándose al dispositivo USB...';

  @override
  String get usbStatus_searching => 'Buscando dispositivos USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Error al conectar mediante USB: $error';
  }

  @override
  String get scanner_scanning => 'Escaneando dispositivos...';

  @override
  String get scanner_connecting => 'Conectando...';

  @override
  String get scanner_disconnecting => 'Desconectando...';

  @override
  String get scanner_notConnected => 'No está conectado';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Conectado a $deviceName';
  }

  @override
  String get scanner_showAllDevices =>
      'Mostrar todos los dispositivos Bluetooth';

  @override
  String get scanner_showMeshCoreOnly => 'Mostrar solo radios MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'La radio no responde. Puede que haya que emparejarla: abre los ajustes de Bluetooth, añade la radio e introduce su PIN, y vuelve a intentarlo.';

  @override
  String get scanner_pairingFailed =>
      'El emparejamiento Bluetooth se canceló o falló. Asegúrate de que nada más (como tu teléfono) esté conectado a la radio, vuelve a intentarlo e introduce su PIN.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Error de conexión: $error';
  }

  @override
  String get scanner_stop => 'Detener';

  @override
  String get scanner_scan => 'Escanea';

  @override
  String get scanner_scanFromImage => 'Escanear desde imagen';

  @override
  String get scanner_noQrFoundInImage =>
      'No se encontró ningún código QR válido en la imagen';

  @override
  String get scanner_bluetoothOff => 'Bluetooth está desactivado.';

  @override
  String get scanner_bluetoothOffMessage =>
      'Por favor, active el Bluetooth para escanear dispositivos.';

  @override
  String get scanner_chromeRequired => 'Navegador Chrome requerido';

  @override
  String get scanner_chromeRequiredMessage =>
      'Esta aplicación web requiere Google Chrome o un navegador basado en Chromium para el soporte de Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Habilitar Bluetooth';

  @override
  String get device_quickSwitch => 'Cambiar rápidamente';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Configuración';

  @override
  String get settings_deviceInfo => 'Información del dispositivo';

  @override
  String get settings_appSettings => 'Configuración de la App';

  @override
  String get settings_appSettingsSubtitle =>
      'Notificaciones, mensajes y preferencias de mapa';

  @override
  String get settings_nodeSettings => 'Configuración del Nodo';

  @override
  String get settings_nodeName => 'Nombre del nodo';

  @override
  String get settings_nodeNameNotSet => 'No está configurado';

  @override
  String get settings_nodeNameHint => 'Introducir nombre de nodo';

  @override
  String get settings_nodeNameUpdated => 'Nombre actualizado';

  @override
  String get settings_radioSettings => 'Configuración de Radio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frecuencia, potencia, factor de dispersión';

  @override
  String get settings_radioSettingsUpdated => 'Ajustes de radio actualizados';

  @override
  String get settings_location => 'Ubicación';

  @override
  String get settings_locationSubtitle => 'Coordenadas GPS';

  @override
  String get settings_locationUpdated => 'Ubicación actualizada';

  @override
  String get settings_locationBothRequired =>
      'Introduzca tanto la latitud como la longitud.';

  @override
  String get settings_locationInvalid => 'Latitud o longitud inválidos.';

  @override
  String get settings_locationGPSEnable => 'Habilitar GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Habilita la actualización automática de la ubicación mediante GPS.';

  @override
  String get settings_latitude => 'Latitud';

  @override
  String get settings_longitude => 'Longitud';

  @override
  String get settings_contactSettings => 'Configuración de contacto';

  @override
  String get settings_contactSettingsSubtitle =>
      'Configuración de cómo se agregan los contactos.';

  @override
  String get settings_privacyMode => 'Modo Privacidad';

  @override
  String get settings_privacyModeSubtitle =>
      'Ocultar nombre/ubicación en anuncios';

  @override
  String get settings_privacyModeToggle =>
      'Activar el modo de privacidad para ocultar tu nombre y ubicación en los anuncios.';

  @override
  String get settings_privacyModeEnabled => 'Modo de privacidad activado';

  @override
  String get settings_privacyModeDisabled => 'Modo de privacidad desactivado';

  @override
  String get settings_privacy => 'Configuración de privacidad';

  @override
  String get settings_privacySubtitle =>
      'Controlar qué información se comparte.';

  @override
  String get settings_privacySettingsDescription =>
      'Elige qué información comparte tu dispositivo con otros.';

  @override
  String get settings_denyAll => 'Denegar todo';

  @override
  String get settings_allowByContact => 'Permitir por banderas de contacto';

  @override
  String get settings_allowAll => 'Permitir todo';

  @override
  String get settings_telemetryBaseMode => 'Modo base de telemetría';

  @override
  String get settings_telemetryLocationMode =>
      'Modo de ubicación de telemetría';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Modo de entorno de telemetría';

  @override
  String get settings_advertLocation => 'Ubicación de anuncio';

  @override
  String get settings_advertLocationSubtitle => 'Incluir ubicación en anuncio';

  @override
  String get settings_multiAck => 'Múltiples respuestas de confirmación';

  @override
  String get settings_telemetryModeUpdated => 'Modo de telemetría actualizado';

  @override
  String get settings_actions => 'Acciones';

  @override
  String get settings_sendAdvertisement => 'Enviar Anuncio';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Presencia de transmisión ahora';

  @override
  String get settings_advertisementSent => 'Anuncio enviado';

  @override
  String get settings_syncTime => 'Tiempo de Sincronización';

  @override
  String get settings_syncTimeSubtitle =>
      'Establecer la hora del dispositivo al tiempo del teléfono';

  @override
  String get settings_timeSynchronized => 'Sincronizado en el tiempo';

  @override
  String get settings_refreshContacts => 'Actualizar Contactos';

  @override
  String get settings_refreshContactsSubtitle =>
      'Recargar lista de contactos del dispositivo';

  @override
  String get settings_rebootDevice => 'Reiniciar Dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Reiniciar el dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      '¿Está seguro de que desea reiniciar el dispositivo? Se desconectará.';

  @override
  String get settings_debug => 'Depurar';

  @override
  String get settings_bleDebugLog => 'Registro de Depuración BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Comandos, respuestas y datos brutos de BLE';

  @override
  String get settings_appDebugLog => 'Registro de Depuración de la App';

  @override
  String get settings_appDebugLogSubtitle =>
      'Mensajes de depuración de la aplicación';

  @override
  String get settings_exportDatabase => 'Exportar base de datos de mensajes';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Una copia de todos los chats y contactos, para depuración. Manténgala privada.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Base de datos guardada en: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Error al exportar: $error';
  }

  @override
  String get settings_about => 'Acerca de';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => '2026 Proyecto Open Source MeshCore';

  @override
  String get settings_aboutDescription =>
      'Un cliente de código abierto de Flutter para dispositivos de red mesh LoRa de MeshCore.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Datos de elevación LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nombre';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Estado';

  @override
  String get settings_infoBattery => 'Batería';

  @override
  String get settings_infoPublicKey => 'Clave Pública';

  @override
  String get settings_infoContactsCount => 'Número de contactos';

  @override
  String get settings_infoChannelCount => 'Número de canales';

  @override
  String get settings_presets => 'Preajustes';

  @override
  String get settings_frequency => 'Frecuencia (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Frecuencia inválida (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Ancho de banda';

  @override
  String get settings_spreadingFactor => 'Factor de propagación';

  @override
  String get settings_codingRate => 'Tasa de Programación';

  @override
  String get settings_txPower => 'TX Potencia (dBm)';

  @override
  String get settings_txPowerInvalid => 'Potencia de TX inválida';

  @override
  String get settings_clientRepeat => 'Repetir sin conexión';

  @override
  String get settings_clientRepeatSubtitle =>
      'Permita que este dispositivo repita los paquetes de red para otros usuarios.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'Para la comunicación fuera de la red, se requiere una frecuencia de 433, 869 o 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Error: $message';
  }

  @override
  String get appSettings_title => 'Configuración de la App';

  @override
  String get appSettings_appearance => 'Apariencia';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Valor predeterminado del sistema';

  @override
  String get appSettings_themeLight => 'Luz';

  @override
  String get appSettings_themeDark => 'Oscuro';

  @override
  String get appSettings_language => 'Idioma';

  @override
  String get appSettings_languageSystem => 'Predeterminado del sistema';

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
  String get appSettings_languageRu => 'Ruso';

  @override
  String get appSettings_languageUk => 'Ucraniano';

  @override
  String get appSettings_enableMessageTracing =>
      'Habilitar seguimiento de mensajes';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostrar metadatos detallados de enrutamiento y tiempo para los mensajes';

  @override
  String get appSettings_senderNameColors => 'Nombres de remitente en color';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Da a cada remitente del canal su propio color de nombre. Desactivado, todos usan el color del tema.';

  @override
  String get appSettings_showTextFormatting => 'Mostrar formato de texto';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown en los mensajes: **negrita**, *cursiva*, ||texto oculto||, encabezados y enlaces. Otras apps de MeshCore muestran los caracteres sin formato.';

  @override
  String get appSettings_notifications => 'Notificaciones';

  @override
  String get appSettings_enableNotifications => 'Habilitar Notificaciones';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Recibir notificaciones para mensajes y anuncios';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permiso de notificación denegado';

  @override
  String get appSettings_notificationsEnabled => 'Notificaciones activadas';

  @override
  String get appSettings_notificationsDisabled => 'Notificaciones desactivadas';

  @override
  String get appSettings_messageNotifications => 'Notificaciones de Mensaje';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostrar notificación al recibir nuevos mensajes';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notificaciones de Mensajes del Canal';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostrar notificación al recibir mensajes del canal';

  @override
  String get appSettings_advertisementNotifications =>
      'Notificaciones de Anuncios';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostrar notificación cuando se descubren nuevos nodos';

  @override
  String get appSettings_messaging => 'Mensajería';

  @override
  String get appSettings_maxMessageRetries =>
      'Número máximo de reintentos de envío de mensajes';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Número de intentos de reintento antes de marcar un mensaje como fallido.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Reintentos máx. de mensajes de canal';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Reintentará hasta este número de veces mientras no oiga al menos una repetición';

  @override
  String get appSettings_battery => 'Batería';

  @override
  String get appSettings_batteryChemistry => 'Química de la batería';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Configuración por dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Conéctate a un dispositivo para elegir';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3.0-4.2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2.6-3.65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3.0-4.2V)';

  @override
  String get appSettings_mapDisplay => 'Visualización del Mapa';

  @override
  String get appSettings_showRepeaters => 'Mostrar Repetidores';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Mostrar nodos de repetidor en el mapa';

  @override
  String get appSettings_showChatNodes => 'Mostrar Nodos de Chat';

  @override
  String get appSettings_showChatNodesSubtitle =>
      'Mostrar nodos de chat en el mapa';

  @override
  String get appSettings_showOtherNodes => 'Mostrar otros nodos';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Mostrar otros tipos de nodo en el mapa';

  @override
  String get appSettings_timeFilter => 'Filtro de Tiempo';

  @override
  String get appSettings_timeFilterShowAll => 'Mostrar todos los nodos';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostrar nodos de las últimas $hours horas';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro de Tiempo del Mapa';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Mostrar nodos descubiertos dentro de:';

  @override
  String get appSettings_allTime => 'Todo el tiempo';

  @override
  String get appSettings_lastHour => 'Última hora';

  @override
  String get appSettings_last6Hours => 'Últimas 6 horas';

  @override
  String get appSettings_last24Hours => 'Últimas 24 horas';

  @override
  String get appSettings_lastWeek => 'La semana pasada';

  @override
  String get appSettings_unitsTitle => 'Unidades';

  @override
  String get appSettings_unitsMetric => 'Métrico (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (pies/millas)';

  @override
  String get appSettings_debugCard => 'Depurar';

  @override
  String get appSettings_appDebugLogging => 'Registro de Depuración de la App';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Registrar mensajes de depuración de la app de registro para solucionar problemas';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Registro de depuración de la aplicación habilitado';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'El registro de depuración de la aplicación está desactivado';

  @override
  String get appSettings_incrementalContactSync =>
      'Sincronización incremental de contactos';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Al reconectar, pedir a la radio solo los contactos que cambiaron desde la última vez';

  @override
  String get contacts_title => 'Contactos';

  @override
  String get contacts_noContacts => 'Aún no hay contactos.';

  @override
  String get contacts_shareMyQrCode => 'Compartir mi código QR';

  @override
  String get contacts_shareQrCodeDesc =>
      'Deja que otros escaneen para añadirte como contacto';

  @override
  String get contacts_contactsWillAppear =>
      'Los contactos aparecerán cuando los dispositivos anuncien.';

  @override
  String get contacts_unread => 'No leído';

  @override
  String get contacts_searchContactsNoNumber => 'Buscar contactos...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Buscar contactos...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Buscar $number$str Favoritos...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Buscar $number$str Usuarios...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Buscar $number$str Repetidores...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Buscar $number$str servidores de sala...';
  }

  @override
  String get contacts_noUnreadContacts => 'No contactos sin leer';

  @override
  String get contacts_noContactsFound =>
      'No se encontraron contactos ni grupos.';

  @override
  String get contacts_deleteContact => 'Eliminar Contacto';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return '¿Seguro que quieres eliminar a $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Contacto $contactName eliminado.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'No se pudo eliminar a $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Ningún contacto coincide con el filtro.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Eliminar $contactName de los contactos?';
  }

  @override
  String get contacts_manageRepeater => 'Gestionar Repetidor';

  @override
  String get contacts_manageRoom => 'Gestionar Servidor de Habitación';

  @override
  String get contacts_roomLogin => 'Inicio de Sala';

  @override
  String get contacts_openChat => 'Abrir Chat';

  @override
  String get contacts_editGroup => 'Editar Grupo';

  @override
  String get contacts_deleteGroup => 'Eliminar Grupo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Eliminar $groupName?';
  }

  @override
  String get contacts_newGroup => 'Nuevo Grupo';

  @override
  String get contacts_groupName => 'Nombre del grupo';

  @override
  String get contacts_groupNameRequired => 'El nombre del grupo es obligatorio';

  @override
  String get contacts_groupNameReserved =>
      'Este nombre de grupo está reservado';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'El grupo \"$name\" ya existe';
  }

  @override
  String get contacts_filterContacts => 'Filtrar contactos...';

  @override
  String get contacts_noContactsMatchFilter =>
      'No hay contactos que coincidan con tu filtro';

  @override
  String get contacts_noMembers => 'No miembros';

  @override
  String get contacts_lastSeenNow => 'Última vez que se vio ahora';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return '~ $minutes min.';
  }

  @override
  String get contacts_lastSeenHourAgo => '~ 1 hora';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return '~ $hours horas';
  }

  @override
  String get contacts_lastSeenDayAgo => '~ 1 día';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return '~ $days días';
  }

  @override
  String get contact_info => 'Información de contacto';

  @override
  String get contact_settings => 'Configuración de contacto';

  @override
  String get contact_telemetry => 'Telemetría';

  @override
  String get contact_lastSeen => 'Visto por última vez';

  @override
  String get contact_clearChat => 'Borrar chat';

  @override
  String get contact_teleBase => 'Base de Telemetría';

  @override
  String get contact_teleBaseSubtitle =>
      'Permitir el intercambio de nivel de batería y telemetría básica';

  @override
  String get contact_teleLoc => 'Ubicación de telemetría';

  @override
  String get contact_teleLocSubtitle =>
      'Permitir el intercambio de datos de ubicación';

  @override
  String get contact_teleEnv => 'Entorno de Telemetría';

  @override
  String get contact_teleEnvSubtitle =>
      'Permitir el intercambio de datos de sensores de entorno';

  @override
  String get contacts_publicKey => 'Clave pública';

  @override
  String get channels_title => 'Canales';

  @override
  String get channels_noChannelsConfigured => 'No se han configurado canales';

  @override
  String get channels_addPublicChannel => 'Añadir Canal Público';

  @override
  String get channels_searchChannels => 'Buscar canales...';

  @override
  String get channels_noChannelsFound => 'No se encontraron canales';

  @override
  String channels_channelIndex(int index) {
    return 'Canal $index';
  }

  @override
  String get channels_hashtagChannel => 'Canal con hashtag';

  @override
  String get channels_public => 'Público';

  @override
  String get channels_private => 'Privado';

  @override
  String get channels_publicChannel => 'Canal público';

  @override
  String get channels_privateChannel => 'Canal privado';

  @override
  String get channels_editChannel => 'Editar canal';

  @override
  String get channels_shareChannel => 'Compartir canal';

  @override
  String get channels_shareChannelInstructions =>
      'Escanea el código QR para añadir el canal.\nMenú → Añadir Canal → Escanear un Código QR';

  @override
  String get channels_secretKey => 'Clave secreta';

  @override
  String get channels_meshcoreUri => 'URI de MeshCore';

  @override
  String get channels_shareChannelQr => 'Escanear código QR del canal';

  @override
  String get channels_shareChannelWarning =>
      'Aviso: cualquiera que escanee este código QR tendrá acceso a este canal.';

  @override
  String get channels_muteChannel => 'Silenciar canal';

  @override
  String get channels_unmuteChannel => 'Activar canal';

  @override
  String get channels_deleteChannel => 'Eliminar canal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Eliminar \"$name\"? Esto no se puede deshacer.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'No se pudo eliminar el canal \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Canal \"$name\" eliminado';
  }

  @override
  String get channels_addChannel => 'Añadir Canal';

  @override
  String get channels_channelIndexLabel => 'Índice de Canal';

  @override
  String get channels_channelName => 'Nombre del canal';

  @override
  String get channels_usePublicChannel => 'Usar Canal Público';

  @override
  String get channels_standardPublicPsk => 'PSK estándar público';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Generar PSK aleatorio';

  @override
  String get channels_enterChannelName =>
      'Por favor, introduce un nombre de canal';

  @override
  String get channels_pskMustBe32Hex =>
      'PSK debe ser de 32 caracteres hexadecimales.';

  @override
  String get channels_addChannelConfirmation =>
      '¿Quieres añadir el siguiente canal?';

  @override
  String get channels_channelAddedSuccess => 'Canal añadido correctamente.';

  @override
  String get channels_noAvailableChannelSlots =>
      'No quedan huecos libres para canales.';

  @override
  String get appSettings_mentionNotifications => 'Notificaciones de menciones';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Cuando alguien te menciona o te responde — incluso en canales silenciados';

  @override
  String notification_mentionIn(String channelName) {
    return 'Mención en $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Canal \"$name\" añadido';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Editar Canal $index';
  }

  @override
  String get channels_smazCompression => 'Compresión SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Canal \"$name\" actualizado';
  }

  @override
  String get channels_publicChannelAdded => 'Canal público añadido';

  @override
  String get channels_sortBy => 'Ordenar por';

  @override
  String get channels_sortManual => 'Manual';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Últimos mensajes';

  @override
  String get channels_sortUnread => 'Sin leer';

  @override
  String get channels_createPrivateChannel => 'Crear un Canal Privado';

  @override
  String get channels_createPrivateChannelDesc =>
      'Cifrado con una clave secreta.';

  @override
  String get channels_joinPrivateChannel => 'Únete a un Canal Privado';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Introducir manualmente una clave secreta.';

  @override
  String get channels_joinPublicChannel => 'Únete al Canal Público';

  @override
  String get channels_joinPublicChannelDesc =>
      'Cualquiera puede unirse a este canal.';

  @override
  String get channels_joinHashtagChannel => 'Únete a un Canal con Hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Cualquiera puede unirse a los canales de hashtag.';

  @override
  String get channels_scanQrCode => 'Escanear un Código QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Próximamente';

  @override
  String get channels_enterHashtag => 'Introducir hashtag';

  @override
  String get channels_hashtagHint => 'ej. #equipo';

  @override
  String get chat_noMessages => 'Aún no hay mensajes';

  @override
  String get chat_sendMessage => 'Enviar mensaje';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Enviar un mensaje a $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Enviar un mensaje para comenzar';

  @override
  String get chat_originalMessageNotFound => 'Mensaje original no encontrado';

  @override
  String chat_replyingTo(String name) {
    return 'Responder a $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Responder a $name';
  }

  @override
  String get chat_location => 'Ubicación';

  @override
  String get common_copiedToClipboard => 'Copiado al portapapeles';

  @override
  String get common_copyToClipboard => 'Copiar al portapapeles';

  @override
  String get contacts_copyContactToClipboard =>
      'Copiar mi contacto al portapapeles';

  @override
  String get chat_typeMessage => 'Escribe un mensaje...';

  @override
  String get chat_searchMessages => 'Buscar mensajes';

  @override
  String get chat_searchNoMatches => 'Sin coincidencias';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Mensaje demasiado largo (máximo $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Mensaje copiado';

  @override
  String get chat_messageDeleted => 'Mensaje borrado';

  @override
  String get chat_sendGif => 'Enviar GIF';

  @override
  String get chat_reply => 'Responder';

  @override
  String get chat_newMessages => 'MENSAJES NUEVOS';

  @override
  String get chat_addReaction => 'Añadir Reacción';

  @override
  String get chat_mention => 'Mencionar';

  @override
  String get dmChannel_menuLabel => 'Mensaje directo';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Mensaje directo a $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Comprueba la clave y la última vez visto — los nombres no son únicos.';

  @override
  String get dmChannel_warningTitle => '¿De verdad es esa persona?';

  @override
  String get dmChannel_warningBody =>
      'Los nombres en los canales los elige cada uno y cualquiera puede imitarlos. Para algo delicado, verifica antes la clave pública de este contacto por otro medio.';

  @override
  String get dmChannel_dontShowAgain => 'No volver a mostrar';

  @override
  String get batterySleep_title => 'Mantener MeshTrax activo';

  @override
  String get batterySleep_bodySamsung =>
      'Los teléfonos Samsung suspenden las apps para ahorrar batería, lo que corta tu radio. Abre Ajustes → Aplicaciones → MeshTrax → Batería y elige Sin restricciones. Revisa también Batería → Límites de uso en segundo plano y asegúrate de que MeshTrax no esté en Aplicaciones en suspensión ni en Aplicaciones en suspensión profunda.';

  @override
  String get batterySleep_bodyGeneric =>
      'Tu teléfono puede detener MeshTrax en segundo plano para ahorrar batería, lo que corta tu radio. Abre los ajustes de batería y pon MeshTrax en Sin restricciones (o Sin limitaciones). En algunos teléfonos también tienes que activar el Inicio automático para MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Abrir ajustes';

  @override
  String get batterySleep_notNow => 'Ahora no';

  @override
  String get batterySleep_settingsTile =>
      'Mantener MeshTrax activo en segundo plano';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Evita que el ahorro de batería del teléfono suspenda MeshTrax';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Aún no puedes enviar un mensaje directo a $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Aún no tienes su clave, y necesitará la tuya para responder — las claves solo viajan en los anuncios. «Enviar mi anuncio» difunde el tuyo desde aquí mismo. «Preguntar en el canal» escribe una petición en el cuadro de mensaje para que la envíes.';

  @override
  String get dmChannel_askInChannel => 'Preguntar en el canal';

  @override
  String get dmChannel_sendMyAdvert => 'Enviar mi anuncio';

  @override
  String get dmChannel_askText =>
      'por favor, envía un anuncio para que pueda mandarte un mensaje directo';

  @override
  String get dmChannel_watching =>
      'Esperando su anuncio — te avisaremos aquí cuando llegue.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name ya es accesible';
  }

  @override
  String get dmChannel_openDm => 'MD';

  @override
  String get appSettings_zoomLevel => 'Nivel de zoom';

  @override
  String get common_reset => 'Restablecer';

  @override
  String get chat_reactionsTitle => 'Reacciones';

  @override
  String get chat_reactionUnknownSender => 'Desconocido';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender reaccionó a un mensaje que no está en este chat';
  }

  @override
  String get chat_me => 'Yo';

  @override
  String get emojiCategorySmileys => 'Emoticones';

  @override
  String get emojiCategoryGestures => 'Gestos';

  @override
  String get emojiCategoryHearts => 'Corazones';

  @override
  String get emojiCategoryObjects => 'Objetos';

  @override
  String get gifPicker_title => 'Elegir un GIF';

  @override
  String get gifPicker_searchHint => 'Buscar GIFs...';

  @override
  String get gifPicker_poweredBy => 'Powered by GIPHY';

  @override
  String get gifPicker_noGifsFound => 'No se encontraron GIFs';

  @override
  String get gifPicker_failedLoad => 'No se pudo cargar los GIFs';

  @override
  String get gifPicker_failedSearch => 'No se encontraron GIFs';

  @override
  String get gifPicker_noInternet => 'No hay conexión a internet';

  @override
  String get debugLog_appTitle => 'Registro de Depuración de la App';

  @override
  String get debugLog_bleTitle => 'Registro de Depuración BLE';

  @override
  String get debugLog_copyLog => 'Copiar registro';

  @override
  String get debugLog_saveLog => 'Guardar registro en archivo';

  @override
  String get debugLog_saved => 'Registro guardado';

  @override
  String get debugLog_saveCancelled => 'Guardado cancelado';

  @override
  String get debugLog_filterAll => 'Todo';

  @override
  String get debugLog_filterWarnings => 'Advertencias';

  @override
  String get debugLog_filterErrors => 'Errores';

  @override
  String get debugLog_clearLog => 'Borrar registro';

  @override
  String get debugLog_copied => 'Registro de depuración copiado';

  @override
  String get debugLog_bleCopied => 'Registro BLE copiado';

  @override
  String get debugLog_noEntries => 'Aún no hay registros de depuración.';

  @override
  String get debugLog_enableInSettings =>
      'Habilitar el registro de depuración de la aplicación en la configuración';

  @override
  String get debugLog_frames => 'Marcos';

  @override
  String get debugLog_rawLogRx => 'Registro Crudo-RX';

  @override
  String get debugLog_noBleActivity => 'Aún no hay actividad BLE';

  @override
  String debugFrame_length(int count) {
    return 'Longitud del Marco: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Comando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Mensaje de Texto:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destino PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Marca de tiempo: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Banderas: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tipo de texto: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Comando CLI';

  @override
  String get debugFrame_textTypePlain => 'Sencillo';

  @override
  String debugFrame_text(String text) {
    return '- Texto: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Mapeo Hexadecimal:';

  @override
  String get chat_hopSingular => 'salta';

  @override
  String get chat_hopPlural => 'salta';

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
  String get chat_setCustomPath => 'Establecer Ruta Personalizada';

  @override
  String get chat_fullPath => 'Ruta completa';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Los detalles de la ruta aún no están disponibles. Intenta enviar un mensaje para refrescar.';

  @override
  String get chat_type => 'Escribe';

  @override
  String get chat_path => 'Ruta';

  @override
  String get chat_publicKey => 'Clave Pública';

  @override
  String get chat_compressOutgoingMessages => 'Comprimir mensajes salientes';

  @override
  String get chat_floodForced => 'Inundación (forzada)';

  @override
  String get chat_directForced => 'Directo (forzado)';

  @override
  String chat_hopsForced(int count) {
    return '$count saltos (forzados)';
  }

  @override
  String get chat_floodAuto => 'Inundación (automática)';

  @override
  String get chat_direct => 'Guardar';

  @override
  String get chat_poiShared => 'Punto de Interés Compartido';

  @override
  String chat_unread(int count) {
    return 'Sin leer: $count';
  }

  @override
  String get chat_openLink => '¿Abrir enlace?';

  @override
  String get chat_openLinkConfirmation =>
      '¿Quiere abrir este enlace en su navegador?';

  @override
  String get chat_open => 'Abrir';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'No se pudo abrir el enlace: $url';
  }

  @override
  String get chat_invalidLink => 'Formato de enlace no válido';

  @override
  String get map_lineOfSight => 'Línea de visión';

  @override
  String get map_losScreenTitle => 'Línea de visión';

  @override
  String get map_noNodesWithLocation => 'No hay nodos con datos de ubicación';

  @override
  String get map_nodesNeedGps =>
      'Los nodos necesitan compartir sus coordenadas GPS\npara aparecer en el mapa';

  @override
  String map_nodesCount(int count) {
    return 'Nodos: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Ganchos: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repetidor';

  @override
  String get map_room => 'Habitación';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Pin (DM)';

  @override
  String get map_pinPrivate => 'Bloqueo (Privado)';

  @override
  String get map_pinPublic => 'Clave (Pública)';

  @override
  String get map_lastSeen => 'Última vez que se vio';

  @override
  String get map_disconnectConfirm =>
      '¿Está seguro de que desea desconectarse de este dispositivo?';

  @override
  String get map_from => 'De';

  @override
  String get map_source => 'Fuente';

  @override
  String get map_flags => 'Banderas';

  @override
  String get map_shareMarkerHere => 'Compartir marcador aquí';

  @override
  String get map_setAsMyLocation => 'Establecer mi ubicación';

  @override
  String get map_pinLabel => 'Etiqueta de marcador';

  @override
  String get map_label => 'Etiqueta';

  @override
  String get map_pointOfInterest => 'Punto de interés';

  @override
  String get map_sendToContact => 'Enviar a contacto';

  @override
  String get map_sendToChannel => 'Enviar a canal';

  @override
  String get map_noChannelsAvailable => 'No hay canales disponibles';

  @override
  String get map_publicLocationShare => 'Compartir ubicación pública';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Estás a punto de compartir una ubicación en $channelLabel. Este canal es público y cualquiera con la PSK puede verlo.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Conéctate a un dispositivo para compartir marcadores';

  @override
  String get map_filterNodes => 'Filtrar Nodos';

  @override
  String get map_chatNodes => 'Nodos de Chat';

  @override
  String get map_repeaters => 'Repetidores';

  @override
  String get map_otherNodes => 'Otros Nodos';

  @override
  String get map_showOverlaps => 'Superposiciones de tecla repetidora';

  @override
  String get map_keyPrefix => 'Prefijo de clave';

  @override
  String get map_filterByKeyPrefix => 'Filtrar por prefijo clave';

  @override
  String get map_publicKeyPrefix => 'Prefijo de clave pública';

  @override
  String get map_showDiscoveryContacts => 'Mostrar Contactos de Descubrimiento';

  @override
  String get map_guessedLocation => 'Ubicación estimada';

  @override
  String get map_lastSeenTime => 'Última vez que se vio';

  @override
  String get map_sharedPin => 'Pin compartido';

  @override
  String get map_joinRoom => 'Únete a la sala';

  @override
  String get map_manageRepeater => 'Gestionar Repetidor';

  @override
  String get map_tapToAdd => 'Pulse en los nodos para agregarlos al camino.';

  @override
  String get map_runTrace => 'Ejecutar Rastreo de Ruta';

  @override
  String get map_runTraceWithReturnPath => 'Volver atrás por el mismo camino.';

  @override
  String get map_removeLast => 'Eliminar último';

  @override
  String get map_pathTraceCancelled => 'Rastreo de ruta cancelado.';

  @override
  String get time_justNow => 'Hace un momento';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minutos hace.';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h hace';
  }

  @override
  String time_daysAgo(int days) {
    return '$days días hace';
  }

  @override
  String get time_hour => 'hora';

  @override
  String get time_hours => 'horas';

  @override
  String get time_day => 'día';

  @override
  String get time_days => 'días';

  @override
  String get time_week => 'semana';

  @override
  String get time_weeks => 'semanas';

  @override
  String get time_month => 'mes';

  @override
  String get time_months => 'meses';

  @override
  String get time_minutes => 'minutos';

  @override
  String get time_allTime => 'Todas las veces';

  @override
  String get dialog_disconnect => 'Desconectar';

  @override
  String get dialog_disconnectConfirm =>
      '¿Está seguro de que desea desconectarse de este dispositivo?';

  @override
  String get login_repeaterLogin => 'Iniciar sesión en el Repetidor';

  @override
  String get login_roomLogin => 'Inicio de Sala';

  @override
  String get login_password => 'Contraseña';

  @override
  String get login_enterPassword => 'Introducir contraseña';

  @override
  String get login_savePassword => 'Guardar contraseña';

  @override
  String get login_savePasswordSubtitle =>
      'La contraseña se almacenará de forma segura en este dispositivo.';

  @override
  String get login_repeaterDescription =>
      'Ingrese la contraseña del repetidor para acceder a la configuración y el estado.';

  @override
  String get login_roomDescription =>
      'Ingrese la contraseña de la sala para acceder a la configuración y el estado.';

  @override
  String get login_login => 'Iniciar sesión';

  @override
  String login_attempt(int current, int max) {
    return 'Intentar $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Inicio fallido: $error';
  }

  @override
  String get login_failedMessage =>
      'Inicio fallido. La contraseña es incorrecta o el repetidor no está disponible.';

  @override
  String get common_reload => 'Recargar';

  @override
  String get common_clear => 'Borrar';

  @override
  String get path_enterCustomPath => 'Introducir Ruta Personalizada';

  @override
  String get path_currentPathLabel => 'Ruta actual';

  @override
  String get path_hexPrefixInstructions =>
      'Introduzca los prefijos hexadecimales de 2 caracteres para cada salto, separados por comas.';

  @override
  String get path_hexPrefixExample =>
      'Ejemplo: A1,F2,3C (cada nodo utiliza el primer byte de su clave pública).';

  @override
  String get path_labelHexPrefixes => 'Prefijos hexadecimales';

  @override
  String get path_helperMaxHops =>
      'Máximo 64 saltos. Cada prefijo tiene 2 caracteres hexadecimales (1 byte).';

  @override
  String get path_selectFromContacts => 'O seleccionar de contactos:';

  @override
  String get path_noRepeatersFound =>
      'No se encontraron repetidores ni servidores de sala.';

  @override
  String get path_customPathsRequire =>
      'Las rutas personalizadas requieren saltos intermedios que pueden transmitir mensajes.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Prefijos hexadecimales inválidos: $prefixes';
  }

  @override
  String get path_tooLong =>
      'La ruta es demasiado larga. Se permiten un máximo de 64 saltos.';

  @override
  String get path_setPath => 'Establecer Ruta';

  @override
  String get repeater_management => 'Gestión de Repetidores';

  @override
  String get room_management => 'Administración del Servidor de Habitación';

  @override
  String get repeater_guest => 'Información sobre repetidores';

  @override
  String get room_guest => 'Información del servidor';

  @override
  String get repeater_managementTools => 'Herramientas de Gestión';

  @override
  String get repeater_guestTools => 'Herramientas para invitados';

  @override
  String get repeater_status => 'Estado';

  @override
  String get repeater_statusSubtitle =>
      'Ver el estado, las estadísticas y los vecinos del repetidor';

  @override
  String get repeater_telemetry => 'Telemetry';

  @override
  String get repeater_telemetrySubtitle =>
      'Ver la telemetría de los sensores y las estadísticas del sistema';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Enviar comandos al repetidor';

  @override
  String get repeater_neighbors => 'Vecinos';

  @override
  String get repeater_neighborsSubtitle => 'Ver vecinos de salto cero.';

  @override
  String get repeater_settings => 'Configuración';

  @override
  String get repeater_settingsSubtitle => 'Configurar parámetros del repetidor';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Sincronización del reloj después de iniciar sesión';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Enviar automáticamente la función de \"sincronización de reloj\" después de un inicio de sesión exitoso.';

  @override
  String get repeater_statusTitle => 'Estado del Repetidor';

  @override
  String get repeater_refresh => 'Actualizar';

  @override
  String get repeater_statusRequestTimeout => 'Solicitud de estado caducó.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Error al cargar el estado: $error';
  }

  @override
  String get repeater_systemInformation => 'Información del sistema';

  @override
  String get repeater_battery => 'Batería';

  @override
  String get repeater_clockAtLogin => 'Reloj (al inicio de sesión)';

  @override
  String get repeater_uptime => 'Tiempo de actividad';

  @override
  String get repeater_queueLength => 'Longitud de la cola';

  @override
  String get repeater_debugFlags => 'Marcadores de Depuración';

  @override
  String get repeater_radioStatistics => 'Estadísticas de Radio';

  @override
  String get repeater_lastRssi => 'Último RSSI';

  @override
  String get repeater_lastSnr => 'Último SNR';

  @override
  String get repeater_noiseFloor => 'Nivel de Ruido';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Estadísticas del Paquete';

  @override
  String get repeater_sent => 'Enviado';

  @override
  String get repeater_received => 'Recibido';

  @override
  String get repeater_duplicates => 'Duplicados';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days días ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundación: $flood, Directo: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundación: $flood, Directo: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Inundación: $flood, Directo: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get repeater_settingsTitle => 'Configuración del Repetidor';

  @override
  String get repeater_basicSettings => 'Configuración Básica';

  @override
  String get repeater_repeaterName => 'Nombre del Repetidor';

  @override
  String get repeater_repeaterNameHelper =>
      'Mostrar nombre para este repetidor';

  @override
  String get repeater_adminPassword => 'Contraseña de Administrador';

  @override
  String get repeater_adminPasswordHelper => 'Contraseña de acceso completo';

  @override
  String get repeater_guestPassword => 'Contraseña de invitado';

  @override
  String get repeater_guestPasswordHelper =>
      'Acceso de solo lectura con contraseña';

  @override
  String get repeater_radioSettings => 'Configuración de Radio';

  @override
  String get repeater_frequencyMhz => 'Frecuencia (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Potencia';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Ancho de banda';

  @override
  String get repeater_spreadingFactor => 'Factor de propagación';

  @override
  String get repeater_codingRate => 'Tasa de Programación';

  @override
  String get repeater_locationSettings => 'Configuración de Ubicación';

  @override
  String get repeater_latitude => 'Latitud';

  @override
  String get repeater_latitudeHelper =>
      'Grados decimales (por ejemplo, 37.7749)';

  @override
  String get repeater_longitude => 'Longitud';

  @override
  String get repeater_longitudeHelper =>
      'Grados decimales (por ejemplo, -122.4194)';

  @override
  String get repeater_features => 'Características';

  @override
  String get repeater_packetForwarding => 'Enrutamiento de Paquetes';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Habilitar el repetidor para reenviar paquetes';

  @override
  String get repeater_guestAccess => 'Acceso de Invitados';

  @override
  String get repeater_guestAccessSubtitle =>
      'Permitir acceso de invitado en solo lectura';

  @override
  String get repeater_privacyMode => 'Modo Privacidad';

  @override
  String get repeater_privacyModeSubtitle =>
      'Ocultar nombre/ubicación en anuncios';

  @override
  String get repeater_advertisementSettings => 'Configuración de Anuncios';

  @override
  String get repeater_localAdvertInterval => 'Intervalo de Anuncio Local';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervalo de Anuncio de Inundación';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours horas';
  }

  @override
  String get repeater_encryptedAdvertInterval => 'Intervalo de Anuncio Cifrado';

  @override
  String get repeater_dangerZone => 'Zona de Peligro';

  @override
  String get repeater_rebootRepeater => 'Reiniciar Repetidor';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Reiniciar el dispositivo repetidor';

  @override
  String get repeater_rebootRepeaterConfirm =>
      '¿Está seguro de que desea reiniciar este repetidor?';

  @override
  String get repeater_regenerateIdentityKey => 'Regenerar Clave de Identidad';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Generar nueva pareja de clave pública/privada';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Esto generará una nueva identidad para el repetidor. Continuar?';

  @override
  String get repeater_eraseFileSystem => 'Borrar Sistema de Archivos';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatear el sistema de archivos del repetidor';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'ADVERTENCIA: Esto borrará todos los datos del repetidor. ¡Esto no se puede deshacer!';

  @override
  String get repeater_eraseSerialOnly =>
      'Borrar solo está disponible a través de la consola serial.';

  @override
  String repeater_commandSent(String command) {
    return 'Comando enviado: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Error al enviar el comando: $error';
  }

  @override
  String get repeater_confirm => 'Confirmar';

  @override
  String get repeater_settingsSaved => 'Guardado de ajustes exitoso';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Error al guardar la configuración: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Actualizar Configuración Básica';

  @override
  String get repeater_refreshRadioSettings => 'Actualizar Ajustes de Radio';

  @override
  String get repeater_refreshTxPower => 'Actualizar TX de energía';

  @override
  String get repeater_refreshLocationSettings =>
      'Actualizar Configuración de Ubicación';

  @override
  String get repeater_refreshPacketForwarding =>
      'Actualizar Enrutamiento de Paquetes';

  @override
  String get repeater_refreshGuestAccess => 'Actualizar Acceso Invitados';

  @override
  String get repeater_refreshPrivacyMode => 'Actualizar Modo Privacidad';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Actualizar Configuración de Anuncios';

  @override
  String repeater_refreshed(String label) {
    return '$label actualizado';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Error al refrescar $label';
  }

  @override
  String get repeater_cliTitle => 'Repetidor CLI';

  @override
  String get repeater_debugNextCommand => 'Siguiente Comando de Depuración';

  @override
  String get repeater_commandHelp => 'Ayuda';

  @override
  String get repeater_clearHistory => 'Borrar historial';

  @override
  String get repeater_noCommandsSent => 'Aún no se han enviado comandos.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Escriba un comando a continuación o use comandos rápidos';

  @override
  String get repeater_enterCommandHint => 'Escribir comando...';

  @override
  String get repeater_previousCommand => 'Comando anterior';

  @override
  String get repeater_nextCommand => 'Siguiente comando';

  @override
  String get repeater_enterCommandFirst => 'Escriba un comando primero';

  @override
  String get repeater_cliCommandFrameTitle => 'Marco de Comando CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Error: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Obtener Nombre';

  @override
  String get repeater_cliQuickGetRadio => 'Obtener Radio';

  @override
  String get repeater_cliQuickGetTx => 'Obtener TX';

  @override
  String get repeater_cliQuickNeighbors => 'Vecinos';

  @override
  String get repeater_cliQuickVersion => 'Versión';

  @override
  String get repeater_cliQuickAdvertise => 'Anunciar';

  @override
  String get repeater_cliQuickClock => 'Reloj';

  @override
  String get repeater_cliQuickClockSync => 'Sincronización del reloj';

  @override
  String get repeater_cliQuickDiscovery => 'Descubrir Vecinos';

  @override
  String get repeater_cliHelpAdvert => 'Envía un paquete de publicidad';

  @override
  String get repeater_cliHelpReboot =>
      'Reinicia el dispositivo. (ten en cuenta, es normal que aparezca \'Timeout\')';

  @override
  String get repeater_cliHelpClock =>
      'Muestra la hora actual según el reloj del dispositivo.';

  @override
  String get repeater_cliHelpPassword =>
      'Establece una nueva contraseña de administrador para el dispositivo.';

  @override
  String get repeater_cliHelpVersion =>
      'Muestra la versión del dispositivo y la fecha de compilación del firmware.';

  @override
  String get repeater_cliHelpClearStats =>
      'Reinicia varios contadores de estadísticas a cero.';

  @override
  String get repeater_cliHelpSetAf => 'Establece el factor de tiempo de aire.';

  @override
  String get repeater_cliHelpSetTx =>
      'Establece la potencia de transmisión LoRa en dBm (reboot para aplicar).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Habilita o deshabilita el rol del repetidor para este nodo.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Servidor de la sala) Si está \"activado\", entonces el inicio de sesión con una contraseña en blanco estará permitido, pero no se podrá publicar en la sala. (solo lectura).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Establece el número máximo de saltos de paquetes de inundación entrantes (si es >= máximo, el paquete no se enruta).';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Establece el Umbral de Interferencia (en dB). El valor predeterminado es 14. Establecerlo en 0 desactiva la detección de interferencias del canal.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Establece el intervalo para restablecer el Control Automático de Ganancia. Establecer en 0 para desactivarlo.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Habilita o deshabilita la función de \'ACKs dobles\'.';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Establece el intervalo del temporizador en minutos para enviar un paquete de anuncio local (sin salto). Establecer en 0 para desactivarlo.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Establece el intervalo del temporizador en horas para enviar un paquete de anuncio masivo. Establecer en 0 para desactivarlo.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Establece/actualiza la contraseña del invitado. (para repetidores, los inicios de sesión de invitado pueden enviar la solicitud \"Obtener Estadísticas\")';

  @override
  String get repeater_cliHelpSetName => 'Establece el nombre del anuncio.';

  @override
  String get repeater_cliHelpSetLat =>
      'Establece la latitud del mapa de publicidad. (grados decimales)';

  @override
  String get repeater_cliHelpSetLon =>
      'Establece la longitud del mapa de la publicidad. (grados decimales)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Establece parámetros de radio completamente nuevos y los guarda en las preferencias. Requiere un comando \"reboot\" para aplicarlos.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Configura (experimental) la base para aplicar un ligero retraso a los paquetes recibidos, según la fuerza de la señal/puntuación. Establece en 0 para desactivar.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Establece un factor multiplicado con el tiempo de aire para un paquete de modo de inundación y con un sistema de ranura aleatorio, para retrasar su reenvío (para disminuir la probabilidad de colisiones).';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Igual que txdelay, pero para aplicar un retraso aleatorio a la transferencia de paquetes en modo directo.';

  @override
  String get repeater_cliHelpSetBridgeEnabled =>
      'Habilitar/Deshabilitar puente.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Establecer retraso antes de retransmitir paquetes.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Elige si el puente retransmitirá paquetes recibidos o paquetes transmitidos.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Establecer la velocidad de baudios del enlace serial para los puentes rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Establecer secreto de puente para puentes espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Establece un factor personalizado para ajustar el voltaje de la batería reportado (solo soportado en selectas placas).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Establece parámetros de radio temporales para el número dado de minutos, volviendo a los parámetros de radio originales posteriormente. (no guarda en preferencias).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifica el ACL. Elimina la entrada coincidente (por prefijo de pubkey) si \"permissions\" es cero. Añade una nueva entrada si el pubkey-hex tiene longitud completa y no está actualmente en el ACL. Actualiza la entrada mediante el prefijo de pubkey coincidente. Los bits de permiso varían según el rol del firmware, pero los dos bits inferiores son: 0 (Invitado), 1 (Solo lectura), 2 (Lectura/escritura), 3 (Administrador).';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Obtiene tipo de puente ninguno, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Inicia el registro de paquetes en el sistema de archivos.';

  @override
  String get repeater_cliHelpLogStop =>
      'Detener el registro de paquetes al sistema de archivos.';

  @override
  String get repeater_cliHelpLogErase =>
      'Elimina los registros del paquete del sistema de archivos.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Muestra una lista de otros nodos repetidores escuchados a través de anuncios de un solo salto. Cada línea es id-prefijo-hex:marca de tiempo:times-snr-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Elimina la primera entrada coincidente (por prefijo de pubkey (hex)) de la lista de vecinos.';

  @override
  String get repeater_cliHelpRegion =>
      '(solo serie) Lista todas las regiones definidas y los permisos de inundación actuales.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTA: este es un invocación multi-comando especial. Cada comando subsiguiente es un nombre de región (indentado con espacios para indicar la jerarquía padre, con un espacio mínimo). Terminado enviando una línea en blanco/comando.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Busca la región con el prefijo de nombre dado (o \"\" para el ámbito global). Responde con \"-> nombre-región (nombre-padre) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Agrega o actualiza una definición de región con el nombre dado.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Elimina una definición de región con el nombre dado. (debe coincidir exactamente y no tener regiones hijas)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Establece el permiso de \'F\'lujo para la región dada. (\'\' para el ámbito global/legado)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Elimina el permiso de \'F\'lood para la región especificada. (NOTA: en esta etapa NO se recomienda utilizarlo en el ámbito global/legado!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Responde con la región \'home\' actual. (Aún no se ha aplicado en ninguna parte, reservado para el futuro).';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Establece la región \'hogar\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Persiste la lista/mapa de regiones al almacenamiento.';

  @override
  String get repeater_cliHelpGps =>
      'Muestra el estado del GPS. Cuando el GPS está apagado, responde solo con \"apagado\", si está encendido, responde con \"encendido\", estado, fijación, número de satélites.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Activa o desactiva el modo GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sincroniza la hora del nodo con el reloj GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Establece la posición del nodo a las coordenadas GPS y guarda las preferencias.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Da la configuración de la publicidad del nodo de ubicación:\n- ninguno: no incluir la ubicación en las publicidad\n- compartir: compartir la ubicación GPS (del SensorManager)\n- preferencias: publicidad la ubicación almacenada en preferencias';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Configura la configuración de la publicidad de la ubicación.';

  @override
  String get repeater_commandsListTitle => 'Lista de comandos';

  @override
  String get repeater_commandsListNote =>
      'NOTA: para los diversos comandos \"set...\", también existe un comando \"get...\".';

  @override
  String get repeater_general => 'General';

  @override
  String get repeater_settingsCategory => 'Configuración';

  @override
  String get repeater_bridge => 'Puente';

  @override
  String get repeater_logging => 'Registrando';

  @override
  String get repeater_neighborsRepeaterOnly => 'Vecinos (solo repetidor)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gestión de Regiones (solo Repetidor)';

  @override
  String get repeater_regionNote =>
      'Se han introducido los comandos de región para gestionar las definiciones y permisos de la región.';

  @override
  String get repeater_gpsManagement => 'Gestión de GPS';

  @override
  String get repeater_gpsNote =>
      'Se ha introducido un comando GPS para gestionar temas relacionados con la ubicación.';

  @override
  String get telemetry_receivedData => 'Datos de Telemetría Recibidos';

  @override
  String get telemetry_requestTimeout => 'Solicitud de telemetría ha expirado.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Error al cargar la telemetría: $error';
  }

  @override
  String get telemetry_noData => 'No hay datos de telemetría disponibles.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Batería';

  @override
  String get telemetry_voltageLabel => 'Voltaje';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura del MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Actual';

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
  String get neighbors_receivedData => 'Recibidas Datos de Vecinos';

  @override
  String get neighbors_requestTimedOut =>
      'Los vecinos solicitan que se desconecte.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Error al cargar vecinos: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Repetidores Vecinos';

  @override
  String get neighbors_noData => 'No hay datos de vecinos disponibles.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return 'Clave pública desconocida $pubkey';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Escuchado: $time hace atrás';
  }

  @override
  String get channelPath_title => 'Ruta del Paquete';

  @override
  String get channelPath_viewMap => 'Ver mapa';

  @override
  String get channelPath_otherObservedPaths => 'Otros caminos observados';

  @override
  String get channelPath_repeaterHops => 'Saltos del Repetidor';

  @override
  String get channelPath_noHopDetails =>
      'Los detalles del paquete no están disponibles.';

  @override
  String get channelPath_messageDetails => 'Detalles del mensaje';

  @override
  String get channelPath_senderLabel => 'Remitente';

  @override
  String get channelPath_timeLabel => 'Tiempo';

  @override
  String get channelPath_repeatsLabel => 'Repetir';

  @override
  String channelPath_pathLabel(int index) {
    return 'Ruta $index';
  }

  @override
  String get channelPath_observedLabel => 'Observado';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Ruta observada $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'No datos de ubicación';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month a las $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Desconocido';

  @override
  String get channelPath_floodPath => 'Inundación';

  @override
  String get channelPath_directPath => 'Guardar';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 de $total saltos';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed de $total saltos';
  }

  @override
  String get channelPath_mapTitle => 'Mapa de Rutas';

  @override
  String get channelPath_noRepeaterLocations =>
      'No hay ubicaciones disponibles para el repetidor en esta ruta.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Ruta $index (Principal)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Ruta';

  @override
  String get channelPath_observedPathHeader => 'Ruta Observada';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'No hay detalles de salto disponibles para este paquete.';

  @override
  String get channelPath_unknownRepeater => 'Repetidor Desconocido';

  @override
  String get community_title => 'Comunidad';

  @override
  String get community_create => 'Crear Comunidad';

  @override
  String get community_createDesc =>
      'Crear una nueva comunidad y compartir a través de código QR.';

  @override
  String get community_join => 'Únete';

  @override
  String get community_joinTitle => 'Únete a la comunidad';

  @override
  String community_joinConfirmation(String name) {
    return '¿Quieres unirte a la comunidad \"$name\"?';
  }

  @override
  String get community_scanQr => 'Escanear Código QR de la Comunidad';

  @override
  String get community_scanInstructions =>
      'Apunte la cámara a un código QR de la comunidad';

  @override
  String get community_showQr => 'Mostrar Código QR';

  @override
  String get community_publicChannel => 'Comunidad Pública';

  @override
  String get community_hashtagChannel => 'Hashtag de la Comunidad';

  @override
  String get community_name => 'Nombre de la comunidad';

  @override
  String get community_enterName => 'Introducir nombre de comunidad';

  @override
  String community_created(String name) {
    return 'Comunidad \"$name\" creada';
  }

  @override
  String community_joined(String name) {
    return 'Se unió a la comunidad \"$name\"';
  }

  @override
  String get community_qrTitle => 'Compartir Comunidad';

  @override
  String community_qrInstructions(String name) {
    return 'Escanear este código QR para unirte a $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Los canales de hashtag de la comunidad solo son accesibles para los miembros de la comunidad';

  @override
  String get community_invalidQrCode => 'Código QR de comunidad no válido';

  @override
  String get community_alreadyMember => 'Ya eres Miembro';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Ya eres miembro de \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Añadir Canal Público de la Comunidad';

  @override
  String get community_addPublicChannelHint =>
      'Añade automáticamente el canal público para esta comunidad.';

  @override
  String get community_noCommunities => 'Aún no se han unido comunidades.';

  @override
  String get community_scanOrCreate =>
      'Escanear un código QR o crear una comunidad para comenzar';

  @override
  String get community_manageCommunities => 'Gestionar Comunidades';

  @override
  String get community_delete => 'Salir de la Comunidad';

  @override
  String community_deleteConfirm(String name) {
    return '¿Salir de \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Esto también eliminará $count canal(es) y sus mensajes.';
  }

  @override
  String community_deleted(String name) {
    return 'Has salido de la comunidad \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Regenerar Contraseña Secreta';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenerar la clave secreta para \"$name\"? Todos los miembros deberán escanear el nuevo código QR para seguir comunicándose.';
  }

  @override
  String get community_regenerate => 'Regenerar';

  @override
  String community_secretRegenerated(String name) {
    return 'Código secreto regenerado para \"$name\"';
  }

  @override
  String get community_updateSecret => 'Actualizar Contraseña';

  @override
  String community_secretUpdated(String name) {
    return 'Confidencialidad actualizada para \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Escanear el nuevo código QR para actualizar el secreto de \"$name\"';
  }

  @override
  String get community_addHashtagChannel => 'Añadir Hashtag de la Comunidad';

  @override
  String get community_addHashtagChannelDesc =>
      'Añadir un canal con hashtag para esta comunidad';

  @override
  String get community_selectCommunity => 'Seleccionar Comunidad';

  @override
  String get community_regularHashtag => 'Etiqueta de Hashtag Regular';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag público (cualquiera puede unirse)';

  @override
  String get community_communityHashtag => 'Hashtag de la Comunidad';

  @override
  String get community_communityHashtagDesc =>
      'Exclusivo para miembros de la comunidad';

  @override
  String community_forCommunity(String name) {
    return 'Para $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrar y ordenar';

  @override
  String get listFilter_sortBy => 'Ordenar por';

  @override
  String get listFilter_latestMessages => 'Últimos mensajes';

  @override
  String get listFilter_heardRecently => 'Escuchado recientemente';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtros';

  @override
  String get listFilter_source => 'Origen';

  @override
  String get listFilter_saved => 'Guardados';

  @override
  String get listFilter_discovered => 'Descubiertos';

  @override
  String get listFilter_all => 'Todas';

  @override
  String get listFilter_favorites => 'Favoritos';

  @override
  String get listFilter_addToFavorites => 'Añadir a favoritos';

  @override
  String get listFilter_removeFromFavorites => 'Eliminar de las favoritas';

  @override
  String get listFilter_users => 'Usuarios';

  @override
  String get listFilter_repeaters => 'Repetidores';

  @override
  String get listFilter_roomServers => 'Servidores de la sala';

  @override
  String get listFilter_unreadOnly => 'Solo sin leer';

  @override
  String get listFilter_newGroup => 'Nuevo grupo';

  @override
  String get pathTrace_you => 'Tú';

  @override
  String get pathTrace_failed => 'El trazado de ruta falló.';

  @override
  String get pathTrace_notAvailable => 'El trazado de ruta no está disponible.';

  @override
  String get pathTrace_refreshTooltip => 'Actualizar Path Trace';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Uno o más de los lúpulos carecen de una ubicación';

  @override
  String get pathTrace_clearTooltip => 'Borrar ruta';

  @override
  String get losSelectStartEnd =>
      'Seleccione los nodos de inicio y fin para LOS.';

  @override
  String losRunFailed(String error) {
    return 'Error en la comprobación de la línea de visión: $error';
  }

  @override
  String get losClearAllPoints => 'Borrar todos los puntos';

  @override
  String get losRunToViewElevationProfile =>
      'Ejecute LOS para ver el perfil de elevación';

  @override
  String get losMenuTitle => 'Menú LOS';

  @override
  String get losMenuSubtitle =>
      'Toque nodos o mantenga presionado el mapa para puntos personalizados';

  @override
  String get losShowDisplayNodes => 'Mostrar nodos de visualización';

  @override
  String get losCustomPoints => 'Puntos personalizados';

  @override
  String losCustomPointLabel(int index) {
    return 'Personalizado $index';
  }

  @override
  String get losPointA => 'Punto A';

  @override
  String get losPointB => 'Punto B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antena A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antena B: $value $unit';
  }

  @override
  String get losRun => 'Ejecutar LOS';

  @override
  String get losNoElevationData => 'Sin datos de elevación';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, despejar LOS, autorización mínima $clearance $heightUnit';
  }

  @override
  String losProfileBlocked(
    String distance,
    String distanceUnit,
    String obstruction,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, bloqueado por $obstruction $heightUnit';
  }

  @override
  String get losStatusChecking => 'LOS: comprobando...';

  @override
  String get losStatusNoData => 'LOS: sin datos';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total claro, $blocked bloqueado, $unknown desconocido';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Datos de elevación no disponibles para una o más muestras.';

  @override
  String get losErrorInvalidInput =>
      'Datos de puntos/elevación no válidos para el cálculo de LOS.';

  @override
  String get losRenameCustomPoint =>
      'Cambiar el nombre del punto personalizado';

  @override
  String get losPointName => 'Nombre del punto';

  @override
  String get losShowPanelTooltip => 'Mostrar panel LOS';

  @override
  String get losHidePanelTooltip => 'Ocultar panel LOS';

  @override
  String get losElevationAttribution =>
      'Datos de elevación: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Horizonte radioeléctrico';

  @override
  String get losLegendLosBeam => 'Línea de visión';

  @override
  String get losLegendTerrain => 'Terreno';

  @override
  String get losFrequencyLabel => 'Frecuencia';

  @override
  String get losFrequencyInfoTooltip => 'Ver detalles del cálculo';

  @override
  String get losFrequencyDialogTitle => 'Cálculo del horizonte radioeléctrico';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'A partir de k=$baselineK en $baselineFreq MHz, el cálculo ajusta el factor k para la banda actual de $frequencyMHz MHz, que define el límite curvo del horizonte de radio.';
  }

  @override
  String get contacts_pathTrace => 'Rastreo de caminos';

  @override
  String get contacts_ping => 'Ping';

  @override
  String get contacts_repeaterPathTrace => 'Rastrear ruta al repetidor';

  @override
  String get contacts_repeaterPing => 'Pingar repetidor';

  @override
  String get contacts_roomPathTrace =>
      'Rastreo de ruta al servidor de la habitación';

  @override
  String get contacts_roomPing => 'Pingar servidor de sala';

  @override
  String get contacts_chatTraceRoute => 'Ruta de trazado';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Rastrear ruta a $name';
  }

  @override
  String get contacts_clipboardEmpty => 'El portapapeles está vacío.';

  @override
  String get contacts_invalidAdvertFormat => 'Datos de contacto no válidos';

  @override
  String get contacts_contactImported => 'El contacto ha sido importado.';

  @override
  String get contacts_contactImportFailed =>
      'Contacto no se importó correctamente.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name ya está en tus contactos.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Anuncio de Zero Hop';

  @override
  String get contacts_floodAdvert => 'Anuncio de inundación';

  @override
  String get contacts_copyAdvertToClipboard => 'Copiar anuncio al portapapeles';

  @override
  String get contacts_addContactFromClipboard =>
      'Agregar contacto desde el portapapeles';

  @override
  String get contacts_ShareContact => 'Copiar contacto al Portapapeles';

  @override
  String get contacts_ShareContactZeroHop => 'Compartir contacto por anuncio';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Envió contacto por anuncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed =>
      'No se pudo enviar el contacto.';

  @override
  String get contacts_contactAdvertCopied => 'Anuncio copiado al Portapapeles.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Copiar anuncio al Portapapeles ha fallado.';

  @override
  String get contacts_addContact => 'Añadir contacto';

  @override
  String get contacts_scanQrCode => 'Escanear QR de contacto';

  @override
  String get contacts_scanQrCodeDesc =>
      'Escanea el código QR de un contacto desde la app MeshCore';

  @override
  String get contacts_enterIdHash => 'Introducir contacto manualmente';

  @override
  String get contacts_enterIdHashDesc =>
      'Pega un anuncio de contacto o un enlace meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... o clave pública en hex';

  @override
  String get contacts_import => 'Importar';

  @override
  String get contacts_scanContactInstructions =>
      'Escanea el código QR de un contacto MeshCore';

  @override
  String get notification_activityTitle => 'Actividad de MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensajes',
      one: 'mensaje',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensajes de canal',
      one: 'mensaje de canal',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'nuevos nodos',
      one: 'nuevo nodo',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Nuevo $contactType descubierto';
  }

  @override
  String get notification_receivedNewMessage => 'Nuevo mensaje recibido';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportar repetidores / servidor de sala a GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporta repetidores o roomserver con una ubicación a un archivo GPX.';

  @override
  String get settings_gpxExportContacts => 'Exportar compañeros a GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporta compañeros con una ubicación a archivo GPX.';

  @override
  String get settings_gpxExportAll => 'Exportar todos los contactos a GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporta todos los contactos con una ubicación a un archivo GPX.';

  @override
  String get settings_gpxExportSuccess => 'Archivo GPX exportado con éxito.';

  @override
  String get settings_gpxExportNoContacts => 'No hay contactos para exportar.';

  @override
  String get settings_gpxExportNotAvailable =>
      'No compatible con tu dispositivo/SO';

  @override
  String get settings_gpxExportError => 'Hubo un error al exportar.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Ubicaciones del servidor de repetidor y sala';

  @override
  String get settings_gpxExportChat => 'Ubicaciones de compañero';

  @override
  String get settings_gpxExportAllContacts =>
      'Todas las ubicaciones de contactos';

  @override
  String get settings_gpxExportShareText =>
      'Datos del mapa exportados desde MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax exportación de datos de mapa GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Repetidores cercanos';

  @override
  String get snrIndicator_lastSeen => 'Visto por última vez';

  @override
  String get contactsSettings_title => 'Configuración de contactos';

  @override
  String get contactsSettings_autoAddTitle => 'Detección automática';

  @override
  String get contactsSettings_otherTitle =>
      'Otras configuraciones relacionadas con el contacto';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Agregar usuarios automáticamente';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Permitir que el compañero agregue automáticamente a los usuarios descubiertos.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Agregar repetidores automáticamente';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Permitir que el compañero agregue automáticamente los repetidores descubiertos.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Agregar automáticamente servidores de sala';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Permitir que el compañero agregue automáticamente los servidores de salas descubiertos.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Agregar sensores automáticamente';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Permitir que el compañero agregue automáticamente los sensores descubiertos.';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Sobreescribir el más antiguo';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Cuando la lista de contactos esté llena, se reemplazará el contacto no favorito más antiguo.';

  @override
  String get discoveredContacts_Title => 'Contactos descubiertos';

  @override
  String get discoveredContacts_noMatching =>
      'No se encontraron contactos coincidentes';

  @override
  String get listFilter_searchHint => 'Buscar...';

  @override
  String get discoveredContacts_searchHint => 'Buscar contactos descubiertos';

  @override
  String get discoveredContacts_contactAdded => 'Contacto agregado';

  @override
  String get discoveredContacts_addContact => 'Agregar contacto';

  @override
  String get discoveredContacts_copyContact =>
      'Copiar contacto al portapapeles';

  @override
  String get discoveredContacts_deleteContact => 'Eliminar contacto';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Eliminar Todos los Contactos Descubiertos';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      '¿Está seguro de que desea eliminar todos los contactos descubiertos!';

  @override
  String get chat_sendCooldown =>
      'Por favor, espere un momento antes de reenviar.';

  @override
  String get chat_notConnected =>
      'No hay conexión con una radio. Mensaje no enviado.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Salta a los mensajes más antiguos sin leer';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Cuando abras una conversación con mensajes sin leer, desplázate hacia el primer mensaje sin leer en lugar del más reciente.';

  @override
  String get appSettings_languageHu => 'Húngaro';

  @override
  String get appSettings_languageJa => 'Japonés';

  @override
  String get appSettings_languageKo => 'Coreano';

  @override
  String get radioStats_screenTitle => 'Estadísticas de radio';

  @override
  String get radioStats_notConnected =>
      'Conéctese a un dispositivo para visualizar estadísticas de radio.';

  @override
  String get radioStats_firmwareTooOld =>
      'Las estadísticas de radio requieren un firmware compatible v8 o posterior.';

  @override
  String get radioStats_waiting => 'Esperando datos…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Nivel de ruido: $noiseDbm dBm';
  }

  @override
  String radioStats_lastRssi(int rssiDbm) {
    return 'Último RSSI: $rssiDbm dBm';
  }

  @override
  String radioStats_lastSnr(String snr) {
    return 'Último SNR: $snr dB';
  }

  @override
  String radioStats_txAir(int seconds) {
    return 'Tiempo de emisión en Texas (total): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Tiempo de transmisión de RX (total): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Nivel de ruido (dBm) en muestras recientes.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Nivel de ruido: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Obteniendo estadísticas de la radio…';

  @override
  String get radioStats_settingsTile => 'Estadísticas de radio';

  @override
  String get radioStats_settingsSubtitle =>
      'Nivel de ruido, RSSI, SNR y tiempo de transmisión';

  @override
  String get translation_title => 'Traducción';

  @override
  String get translation_enableTitle => 'Habilitar la traducción';

  @override
  String get translation_enableSubtitle =>
      'Traducir los mensajes entrantes y permitir la traducción previa al envío.';

  @override
  String get translation_composerTitle => 'Traducir antes de enviar';

  @override
  String get translation_composerSubtitle =>
      'Controla el estado predeterminado del icono de traducción del compositor.';

  @override
  String get translation_targetLanguage => 'Idioma de destino';

  @override
  String get translation_useAppLanguage =>
      'Utilizar el idioma de la aplicación';

  @override
  String get translation_downloadedModelLabel => 'Modelo descargado';

  @override
  String get translation_presetModelLabel =>
      'Modelo predefinido de Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL del modelo manual';

  @override
  String get translation_downloadModel => 'Descargar el modelo';

  @override
  String get translation_downloading => 'Descargando...';

  @override
  String get translation_working => 'Trabajando...';

  @override
  String get translation_stop => '¡Detente!';

  @override
  String get translation_mergingChunks =>
      'Combinando los fragmentos descargados en el archivo final...';

  @override
  String get translation_downloadedModels => 'Modelos descargados';

  @override
  String get translation_deleteModel => 'Eliminar modelo';

  @override
  String get translation_modelDownloaded => 'Modelo de traducción descargado.';

  @override
  String get translation_downloadStopped => 'La descarga se ha detenido.';

  @override
  String translation_downloadFailed(String error) {
    return 'No se pudo descargar: $error';
  }

  @override
  String get translation_enterUrlFirst =>
      'Primero, introduzca la URL del modelo.';

  @override
  String get scanner_linuxPairingShowPin => 'Mostrar código PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Ocultar PIN';

  @override
  String get scanner_linuxPairingPinTitle =>
      'PIN para emparejar dispositivos Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Introduzca el código PIN para $deviceName (deje en blanco si no hay ninguno).';
  }

  @override
  String get translation_messageTranslation => 'Traducción del mensaje';

  @override
  String get translation_translateBeforeSending => 'Traducir antes de enviar';

  @override
  String get translation_composerEnabledHint =>
      'Los mensajes serán traducidos antes de ser enviados.';

  @override
  String get translation_composerDisabledHint =>
      'Envía mensajes utilizando el lenguaje escrito original.';

  @override
  String translation_translateTo(String language) {
    return 'Traducir a $language';
  }

  @override
  String get translation_translationOptions => 'Opciones de traducción';

  @override
  String get translation_systemLanguage => 'Idioma del sistema';

  @override
  String get routing_title => 'Enrutamiento';

  @override
  String routing_route(String route) {
    return 'Ruta guardada: $route';
  }

  @override
  String get routing_noRoute =>
      'ninguna aún — el próximo mensaje irá por inundación y aprenderá una';

  @override
  String get routing_auto => 'Automático';

  @override
  String get routing_autoSubtitle =>
      'Usa la ruta guardada en la radio. Recomendado.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder activado: prueba primero las rutas aprendidas';

  @override
  String get routing_flood => 'Siempre por inundación';

  @override
  String get routing_floodSubtitle => 'Cada mensaje llega a toda la red mesh';

  @override
  String get routing_custom => 'Ruta personalizada';

  @override
  String get routing_customSubtitle => 'Elige tú los repetidores';

  @override
  String get routing_forget => 'Restablecer ruta';

  @override
  String get routing_forgetDone =>
      'Ruta restablecida. El próximo mensaje irá por inundación y aprenderá una nueva.';

  @override
  String get routing_pathfinder => 'Lo que sabe Pathfinder';

  @override
  String get routing_pathfinderSubtitle =>
      'Repetidores que te oyen a ti y a ese contacto, y rutas aprendidas de ida y vuelta';

  @override
  String get path_direct => 'Directo — sin repetidores';

  @override
  String get path_directSubtitle =>
      'Solo si el contacto oye directamente esta radio';

  @override
  String get chat_kindFlood => 'inundación';

  @override
  String get chat_kindDirect => 'directo';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'saltos',
      one: 'salto',
    );
    return 'ruta ($count $_temp0)';
  }

  @override
  String chat_kindRouteGuessed(int count, int guessed) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'saltos',
      one: 'salto',
    );
    String _temp1 = intl.Intl.pluralLogic(
      guessed,
      locale: localeName,
      other: 'supuestos',
      one: 'supuesto',
    );
    return 'ruta ($count $_temp0, $guessed $_temp1)';
  }

  @override
  String get chat_statusQueued => 'En cola';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Ningún repetidor te oyó. Se volverá a intentar cuando haya uno al alcance.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'La radio de $name envía códigos de repetidor cortos (1 byte). Pathfinder no puede aprender rutas hacia este contacto hasta que su radio use códigos de 2 bytes.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Enviando · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Reintentando · $kind · intento $attempt de $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Entregado · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Entregado en el intento $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Entregado tarde · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Entregado · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'intentos',
      one: 'intento',
    );
    return 'Falló tras $attempts $_temp0 · toca para reenviar';
  }

  @override
  String get chat_statusFailedShort => 'Falló · toca para reenviar';

  @override
  String get chat_resendingByFlood => 'Reenviando por inundación';

  @override
  String get pathfinderHelp_title => 'Qué hace Pathfinder';

  @override
  String get pathfinderHelp_what =>
      'Tu radio recuerda una ruta hacia cada contacto y, cuando esa ruta falla, envía el mensaje por inundación a toda la red mesh. Pathfinder escucha todo lo que oye la radio: anuncios de repetidores, conversaciones en los canales, mensajes de otras personas. Con todo eso construye un mapa de qué repetidores se oyen entre sí, cuáles te oyen a ti y cuáles oyen a cada uno de tus contactos.';

  @override
  String get pathfinderHelp_how =>
      'Cuando envías un mensaje, Pathfinder prueba primero su mejor ruta, luego la siguiente mejor, y solo usa la inundación como último recurso. Un icono de ruta ámbar marca un mensaje que salió por una ruta de Pathfinder.';

  @override
  String get pathfinderHelp_learning =>
      'Necesita tiempo. Un mapa recién creado no sabe nada, así que al principio tus mensajes salen exactamente igual que antes. Tras unas horas escuchando en un mismo lugar empieza a ofrecer rutas, y cada entrega o fallo le enseña algo más. El primer día no esperes mucho de él, y cada vez que te muevas a un sitio nuevo volverá a rendir menos.';

  @override
  String get pathfinderHelp_guessed =>
      'A veces rellena un hueco con una suposición: un enlace que solo ha oído funcionar en el sentido contrario. La línea del mensaje indica entonces cuántos saltos son supuestos. Una entrega los confirma; un fallo cuesta un intento y no se guarda nada.';

  @override
  String get pathfinderHelp_discover =>
      'Cuando no está seguro de qué repetidores te oyen aquí, Pathfinder envía un breve Discover (como mucho uno cada 10 minutos, y solo después de un envío fallido) y, si tu radio tiene GPS, guarda en este teléfono qué repetidores te oyeron en cada zona de unos 500 m, nunca tu ubicación exacta.';

  @override
  String get pathfinderHelp_off =>
      'Si desactivas Pathfinder, la radio enruta exactamente como lo hacía antes.';

  @override
  String get pathfinderHelp_dontShowAgain => 'No volver a mostrar';

  @override
  String get pathfinderHelp_ok => 'De acuerdo';

  @override
  String get settings_pathGraph => 'Pathfinder (experimental)';

  @override
  String get settings_pathGraphSubtitle =>
      'Aprende rutas de todo lo que oye la radio y prueba primero las mejores cuando envías un mensaje directo. Un icono de ruta ámbar marca un mensaje enviado por una ruta de Pathfinder.';

  @override
  String get map_routeAndTrace => 'Ruta y rastreo';

  @override
  String get map_pathfinderTrace => 'Rastreo de ida y vuelta';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Ida por la mejor ruta de Pathfinder, vuelta por su mejor ruta de regreso';

  @override
  String get map_routeBackMirrored =>
      'Aún no se conoce una ruta de regreso — vuelve por el mismo camino';

  @override
  String get map_traceHelpTitle => 'Botones de rastreo de ruta';

  @override
  String get map_traceHelpCustom => 'Escribe o elige tú los repetidores.';

  @override
  String get map_traceHelpRun =>
      'Envía un rastreo por los repetidores que tocaste, solo de ida.';

  @override
  String get map_traceHelpThereAndBack => 'Ida y vuelta';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Envía el rastreo de ida y luego de vuelta por los mismos repetidores en orden inverso.';

  @override
  String get map_traceHelpPathfinder =>
      'Pathfinder elige la mejor ruta que pasa por los dos últimos repetidores que tocaste, y la mejor ruta de regreso a ti. El resultado enseña a Pathfinder qué enlaces funcionan de verdad. Hay que tocar dos repetidores.';

  @override
  String get map_traceHelpRemoveLast => 'Quita el último repetidor de la ruta.';

  @override
  String get map_traceHelpCancel =>
      'Deja de construir el rastreo. Se muestra antes de tocar ningún repetidor.';

  @override
  String get chat_resendingByRoute => 'Reenviando por la ruta establecida';

  @override
  String get room_mute => 'Silenciar sala';

  @override
  String get room_unmute => 'Dejar de silenciar sala';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'miembro';

  @override
  String get room_roleReadOnly => 'solo lectura';

  @override
  String room_clockOff(int minutes) {
    return 'El reloj de la sala difiere unos $minutes min — las horas de los mensajes pueden ser erróneas';
  }

  @override
  String get room_fixClock => 'Ajustar reloj';

  @override
  String get room_clockSyncSent => 'Sincronización de reloj enviada a la sala';

  @override
  String get room_readOnlyNotice =>
      'Solo lectura: la sala no aceptó tu contraseña, tus mensajes no llegarán a los demás miembros.';

  @override
  String get room_postAnnouncement => 'Publicar anuncio';

  @override
  String get room_postAnnouncementSubtitle =>
      'Enviar un mensaje de la propia sala a todos los miembros';

  @override
  String get room_announcementSent => 'Anuncio publicado';

  @override
  String get room_announcementFailed => 'No se pudo publicar el anuncio';

  @override
  String get room_users => 'Usuarios de la sala';

  @override
  String get room_usersSubtitle => 'Ver admins y asignar roles';

  @override
  String get room_usersAdminsNote =>
      'La sala solo lista sus admins. Los miembros con la contraseña de la sala no aparecen.';

  @override
  String get room_usersLoadFailed => 'No se pudo cargar la lista de admins';

  @override
  String get room_setUserRole => 'Asignar rol';

  @override
  String get room_removeAccess => 'Quitar acceso';

  @override
  String get room_removeOnlyUnknown =>
      'Este usuario no está en tus contactos, solo se puede quitar, no cambiar.';

  @override
  String get room_roleUpdated => 'Rol actualizado';

  @override
  String get room_roleUpdateFailed => 'No se pudo cambiar el rol';

  @override
  String get room_postsStored => 'Mensajes guardados';

  @override
  String get room_postsDelivered => 'Mensajes entregados';

  @override
  String get room_reloadPosts => 'Recargar mensajes recientes';

  @override
  String get room_reloadPostsExplain =>
      'Pide a la sala reenviar sus mensajes recientes (guarda hasta 32). Se te pedirá la contraseña de la sala. Los mensajes que ya tienes se conservan.';

  @override
  String get room_reloadFailed => 'No se pudo restablecer la sala en la radio';

  @override
  String get companionCli_title => 'Línea de comandos';

  @override
  String get companionCli_settingsSubtitle =>
      'Escribe comandos de texto para esta radio';

  @override
  String get companionCli_rebooting => 'Reiniciando la radio…';

  @override
  String get companionCli_cancelled => 'Cancelado';

  @override
  String get companionCli_poweringOff => 'Apagando la radio…';

  @override
  String get companionCli_noReply =>
      'La radio no responde. Inténtalo de nuevo.';

  @override
  String get companionCli_powerOffTitle => '¿Apagar la radio?';

  @override
  String get companionCli_powerOffBody =>
      'Seguirá apagada hasta que pulses su botón o la enchufes.';

  @override
  String get companionCli_powerOff => 'Apagar';

  @override
  String get companionCli_quickBoard => 'Placa';

  @override
  String get companionCli_quickWifiStatus => 'Estado WiFi';

  @override
  String get companionCli_quickWifiAddress => 'Dirección WiFi';

  @override
  String get companionCli_helpBoard =>
      'Muestra el fabricante y el modelo de la placa.';

  @override
  String get companionCli_helpReboot => 'Reinicia la radio.';

  @override
  String get companionCli_helpPowerOff => 'Apaga la radio.';

  @override
  String get companionCli_helpSetPin =>
      'Define el PIN de emparejamiento Bluetooth. Se aplica tras reiniciar.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Define las horas que se suman a UTC para el reloj de la pantalla de la radio (-12 a +14).';

  @override
  String get companionCli_helpSetTx =>
      'Define la potencia de transmisión en dBm. Se aplica al momento.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Define el umbral de interferencia en dB. 0 desactiva la detección de interferencias.';

  @override
  String get companionCli_helpSetCad =>
      'Escucha si hay otras radios antes de transmitir (detección de actividad en el canal).';

  @override
  String get companionCli_helpSetRxGain =>
      'Ganancia de recepción aumentada, en radios SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bytes por repetidor en una ruta: 0 = 1 byte, 1 = 2 bytes, 2 = 3 bytes.';

  @override
  String get companionCli_helpWifiStatus =>
      'Indica si la radio está conectada a la red WiFi.';

  @override
  String get companionCli_helpWifiIp =>
      'Muestra la dirección de la radio en la red WiFi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Define el nombre de la red WiFi. Se aplica tras reiniciar.';

  @override
  String get companionCli_helpWifiPwd =>
      'Define la contraseña WiFi. Se aplica tras reiniciar.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Activa (1) o desactiva (0) el WiFi. Se aplica tras reiniciar.';

  @override
  String get companionCli_helpWifiClear =>
      'Olvida la red WiFi. Se aplica tras reiniciar.';

  @override
  String get companionCli_remoteNoReply =>
      'Sin respuesta. La otra radio necesita firmware 1.18 o posterior y debe permitirte usar su línea de comandos.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Enviado. Una radio no responde a un reinicio ni a un apagado.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name intentó usar la línea de comandos de tu radio: «$command». No se permitió.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Intentó usar la línea de comandos de tu radio: «$command». No se permitió.';
  }

  @override
  String get contact_remoteCli => 'Permitir línea de comandos remota';

  @override
  String get contact_remoteCliSubtitle =>
      'Permite a este contacto ejecutar comandos en tu radio';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return '¿Dejar que $name controle tu radio?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name podrá cambiar los ajustes de tu radio, leer tu contraseña WiFi, renombrar tu radio y reiniciarla o apagarla. Permítelo solo a alguien de total confianza.';
  }

  @override
  String get contact_remoteCliAllow => 'Permitir';

  @override
  String get connection_secondApp =>
      'Otra app está conectada a esta radio. Los mensajes y ajustes pueden mezclarse. Cierra la otra app.';

  @override
  String get wifi_title => 'WiFi';

  @override
  String get wifi_settingsSubtitle => 'Red, contraseña y conexión';

  @override
  String get wifi_use => 'Usar WiFi';

  @override
  String get wifi_networkName => 'Nombre de la red';

  @override
  String get wifi_password => 'Contraseña';

  @override
  String get wifi_passwordUnchanged => 'Sin cambios';

  @override
  String get wifi_showPassword => 'Mostrar contraseña';

  @override
  String get wifi_nameMissing => 'Introduce el nombre de la red';

  @override
  String get wifi_nameTooLong =>
      'El nombre de la red es demasiado largo (32 bytes como máximo)';

  @override
  String get wifi_passwordTooLong =>
      'La contraseña es demasiado larga (63 bytes como máximo)';

  @override
  String get wifi_savedRestart =>
      'Guardado. Los cambios de WiFi se aplican cuando la radio se reinicia.';

  @override
  String get wifi_forget => 'Olvidar red';

  @override
  String get wifi_forgetConfirm =>
      '¿Olvidar esta red WiFi? La radio dejará de usar WiFi cuando se reinicie.';

  @override
  String wifi_notAccepted(String reply) {
    return 'La radio no lo aceptó: $reply';
  }

  @override
  String get wifi_noReply => 'La radio no responde. Inténtalo de nuevo.';

  @override
  String get wifi_restartTitle => '¿Reiniciar la radio?';

  @override
  String get wifi_later => 'Más tarde';

  @override
  String get wifi_loadFailed =>
      'No se pudieron leer los ajustes WiFi de la radio.';

  @override
  String wifi_connectedTo(String address) {
    return 'Conectado · $address';
  }

  @override
  String get wifi_notConnected => 'Sin conexión WiFi';

  @override
  String wifi_portNote(int port) {
    return 'Las apps de la misma red pueden conectarse por el puerto $port';
  }

  @override
  String get wifi_connectOverWifi => 'Conectar por WiFi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'MeshTrax se desconectará de esta radio y abrirá la pantalla TCP con $address, puerto $port ya rellenados. Toca Conectar allí.';
  }

  @override
  String get wifi_noteRestart =>
      'Los cambios se aplican cuando la radio se reinicia.';

  @override
  String get wifi_noteSecurity =>
      'Cualquiera en tu red WiFi puede conectarse a la radio por el puerto 5000. No hay contraseña para eso.';

  @override
  String get wifi_noteBattery =>
      'El WiFi mantiene despierta la radio, así que la batería se agota antes.';

  @override
  String get wifi_noteWrongPassword =>
      'Si la contraseña es incorrecta, la radio lo reintenta cada pocos segundos. El Bluetooth sigue funcionando.';

  @override
  String get room_selfDemoteWarning =>
      'Estás cambiando tu propio acceso. Si pierdes tu rol de admin, solo la consola de la sala puede devolvértelo.';

  @override
  String get scanner_offlineMaps => 'Mapas sin conexión';

  @override
  String get appSettings_offlineMaps => 'Mapas sin conexión';

  @override
  String get appSettings_offlineMapsNone => 'Ninguno descargado';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regiones',
      one: '1 región',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zonas de cartas náuticas',
      one: '1 zona de cartas náuticas',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count actualizaciones disponibles',
      one: '1 actualización disponible',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly =>
      'Descargar mapas solo con Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Las descargas de mapas esperan a una conexión Wi‑Fi';

  @override
  String get offlineMaps_title => 'Mapas sin conexión';

  @override
  String get offlineMaps_tabMaps => 'Mapas';

  @override
  String get offlineMaps_tabCharts => 'Cartas náuticas';

  @override
  String get offlineMaps_chartsNotice => 'No apto para navegar · ¿Por qué?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Sugerencia · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Zonas de cartas por costa';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zonas',
      one: '1 zona',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return 'Descargadas: $count';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return 'Seleccionadas: $count';
  }

  @override
  String get offlineMaps_selectAll => 'Seleccionar todo';

  @override
  String get offlineMaps_clearSelection => 'Borrar';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'También en $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Aún no disponible';

  @override
  String get offlineMaps_chartsHint =>
      'Las cartas náuticas de NOAA se eligen por costa, en la pestaña Cartas náuticas.';

  @override
  String offlineMaps_chartsName(String area) {
    return 'Cartas náuticas NOAA de $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count zonas',
      one: '1 zona',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Descargados';

  @override
  String get offlineMaps_refresh => 'Buscar mapas nuevos';

  @override
  String get offlineMaps_loading => 'Cargando mapas disponibles…';

  @override
  String get offlineMaps_serverError =>
      'No se puede contactar con el servidor de mapas';

  @override
  String get offlineMaps_unavailable => 'Aún no hay mapas disponibles';

  @override
  String get offlineMaps_unavailableHint => 'Vuelve a mirar más tarde.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Aún no hay cartas náuticas de NOAA disponibles';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Mostrando la lista del $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Actualiza MeshTrax para obtener los mapas más recientes.';

  @override
  String get offlineMaps_world => 'Mundo';

  @override
  String get offlineMaps_suggested => 'Sugerencias';

  @override
  String get offlineMaps_regions => 'Regiones';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regiones de $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count dentro';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size de mapas sin conexión en este dispositivo';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Actualizaciones ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Actualizar todo ($size)';
  }

  @override
  String get offlineMaps_downloading => 'Descargando';

  @override
  String get offlineMaps_update => 'Actualizar';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Descargado el $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Actualización disponible';

  @override
  String get offlineMaps_otherFiles => 'Otros archivos de mapa';

  @override
  String get offlineMaps_emptyTitle => 'Aún no hay mapas sin conexión';

  @override
  String get offlineMaps_emptyBody =>
      'Descarga una región para usar el mapa sin conexión.';

  @override
  String get offlineMaps_findMaps => 'Buscar mapas';

  @override
  String offlineMaps_deleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Esto libera $size. Puedes volver a descargarlo más tarde.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return 'Eliminado: $name';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done de $total';
  }

  @override
  String get offlineMaps_kindMap => 'Mapa';

  @override
  String get offlineMaps_kindMapDetail =>
      'Calles, senderos y lugares de OpenStreetMap';

  @override
  String get offlineMaps_kindContours => 'Curvas de nivel';

  @override
  String get offlineMaps_kindContoursDetail => 'Líneas de altitud';

  @override
  String get offlineMaps_kindUsgs => 'Mapa topográfico USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Senderos, arroyos, reservas';

  @override
  String get offlineMaps_kindTerrain => 'Sombreado del relieve';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Colinas y montañas, sombreadas bajo el mapa';

  @override
  String get offlineMaps_kindCharts => 'Cartas náuticas NOAA';

  @override
  String get offlineMaps_usOnly => 'Solo Estados Unidos';

  @override
  String offlineMaps_download(String size) {
    return 'Descargar ($size)';
  }

  @override
  String get offlineMaps_downloadTotal => 'Descargar';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Descarga grande ($size). Usa Wi‑Fi y mantén el dispositivo cargando.';
  }

  @override
  String get offlineMaps_waiting => 'Esperando…';

  @override
  String get offlineMaps_checking => 'Comprobando la descarga…';

  @override
  String get offlineMaps_retrying => 'Reintentando…';

  @override
  String offlineMaps_failed(String error) {
    return 'Error en la descarga: $error';
  }

  @override
  String get offlineMaps_pause => 'Pausar';

  @override
  String get offlineMaps_resume => 'Reanudar';

  @override
  String get offlineMaps_deleteRegion => 'Eliminar región';

  @override
  String get offlineMaps_notInCatalogue => 'No disponible para esta región';

  @override
  String get offlineMaps_notificationRunning => 'Descargando mapa';

  @override
  String get offlineMaps_notificationPaused => 'Descarga de mapa en pausa';

  @override
  String get offlineMaps_notificationFailed => 'Error en la descarga del mapa';

  @override
  String get offlineMaps_clearTileCache => 'Vaciar la caché de mapas en línea';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      '¿Quitar las teselas de mapas en línea guardadas al explorar el mapa? Los mapas descargados se conservan.';

  @override
  String get offlineMaps_tileCacheCleared => 'Caché de mapas en línea vaciada';

  @override
  String get map_notForNavigation => 'No apto para navegar';

  @override
  String get map_chartsNoticeIntro =>
      'MeshTrax dibuja estas cartas a partir de los datos de NOAA para ayudarte a ver el agua alrededor de tus radios y planificar. No son cartas oficiales. No navegues con ellas.';

  @override
  String get map_chartsNoticeWhy => 'Por qué:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Se quedan desactualizadas. NOAA corrige sus cartas constantemente; una carta descargada se queda igual hasta que la actualizas en Mapas sin conexión.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Omiten cosas. Muchos símbolos, sectores de luz y notas no se dibujan, y algunas etiquetas no aparecen hasta que acercas el zoom.';

  @override
  String get map_chartsNoticePositions =>
      'Las posiciones pueden ser erróneas o antiguas. El GPS puede desviarse 10 m (30 ft) o más, y un nodo solo está donde informó por última vez.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'MeshTrax no es un plóter de cartas certificado.';

  @override
  String get map_chartsNoticeUse =>
      'Para navegar, usa cartas oficiales y actualizadas de NOAA (en papel, o ENC de NOAA en un plóter certificado) con los últimos Avisos a los Navegantes.';

  @override
  String get map_sourceOnline => 'En línea';

  @override
  String get map_sourceOffline => 'Sin conexión';

  @override
  String get map_downloadForDetail =>
      'Descarga una región para ver más detalle';

  @override
  String get map_zoomInForOfflineMap =>
      'Acerca el zoom para ver tu mapa sin conexión';

  @override
  String get map_noCharts => 'No hay cartas aquí';

  @override
  String get map_myLocation => 'Mi ubicación';

  @override
  String get map_zoomIn => 'Acercar';

  @override
  String get map_zoomOut => 'Alejar';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS activado';

  @override
  String get gps_off => 'GPS desactivado';

  @override
  String get gps_onHint => 'La radio actualiza su posición con el GPS.';

  @override
  String get gps_offHint =>
      'Desactivado, ahorra batería de la radio. Al activarlo, puede tardar unos minutos en encontrar tu posición.';

  @override
  String get gps_asking => 'Consultando a la radio...';

  @override
  String get gps_noPosition =>
      'Aún no hay posición. Al aire libre, la primera puede tardar unos minutos.';

  @override
  String get gps_position => 'Posición';

  @override
  String get gps_altitude => 'Altitud';

  @override
  String gps_readAgo(String ago) {
    return 'Leído de la radio hace $ago';
  }

  @override
  String get gps_turnOnTitle => '¿Activar el GPS?';

  @override
  String get gps_turnOnBody =>
      'El GPS de la radio está desactivado. Al activarlo, puede tardar unos minutos en encontrar tu posición.';

  @override
  String get gps_turnOn => 'Activar';

  @override
  String get gps_notNow => 'Ahora no';

  @override
  String get map_zoomInForCharts => 'Acerca el zoom para ver tus cartas';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Descargar $region · $size';
  }

  @override
  String get mapLayers_title => 'Capas del mapa';

  @override
  String get mapLayers_mapType => 'Tipo de mapa';

  @override
  String get mapLayers_standard => 'Estándar';

  @override
  String get mapLayers_usgs => 'Topográfico USGS';

  @override
  String get mapLayers_charts => 'Cartas náuticas';

  @override
  String get mapLayers_notDownloaded => 'No descargado';

  @override
  String get mapLayers_offlineOnly => 'Solo sin conexión';

  @override
  String get mapLayers_details => 'Detalles del mapa';

  @override
  String get mapLayers_contours => 'Curvas de nivel';

  @override
  String get mapLayers_hillShading => 'Sombreado del relieve';

  @override
  String get mapLayers_dark => 'Mapa oscuro';

  @override
  String get mapLayers_downloadedAreas => 'Zonas descargadas';

  @override
  String get mapLayers_nodes => 'Nodos';

  @override
  String get mapLayers_pins => 'Marcadores';

  @override
  String get mapLayers_guessed => 'Ubicaciones estimadas';

  @override
  String get mapLayers_moreFilters => 'Más filtros';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Visto por última vez, prefijo de clave, solapamientos';

  @override
  String get map_legend => 'Leyenda';

  @override
  String get scanner_map => 'Mapa';

  @override
  String get structured_openMap => 'Abrir mapa';

  @override
  String get structured_addToCalendar => 'Añadir al calendario';

  @override
  String get structured_details => 'Detalles';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Evento';

  @override
  String get structured_notice => 'Aviso';

  @override
  String get structured_allDay => 'Todo el día';

  @override
  String get structured_calendarFailed => 'No se pudo abrir el calendario';

  @override
  String get structured_today => 'Hoy';

  @override
  String get structured_tomorrow => 'Mañana';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'En $count días',
      one: 'En 1 día',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Pasado';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Día $day de $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count días',
      one: '1 día',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Fecha de fin';

  @override
  String get dialog_eventSameDay => 'El mismo día';

  @override
  String get structured_map => 'Mapa';

  @override
  String get structured_navigate => 'Cómo llegar';

  @override
  String get structured_channel => 'Canal';

  @override
  String get structured_contact => 'Contacto';

  @override
  String get structured_room => 'Sala';

  @override
  String get structured_repeater => 'Repetidor';

  @override
  String get structured_sensor => 'Sensor';

  @override
  String get structured_joinChannel => 'Unirse al canal';

  @override
  String get structured_addContact => 'Añadir contacto';

  @override
  String get structured_addRoom => 'Añadir sala';

  @override
  String get structured_addRepeater => 'Añadir repetidor';

  @override
  String get structured_addSensor => 'Añadir sensor';

  @override
  String get structured_open => 'Abrir';

  @override
  String get structured_added => 'Añadido';

  @override
  String get tray_add => 'Añadir';

  @override
  String get tray_myLocation => 'Mi ubicación';

  @override
  String get tray_pointOnMap => 'Punto en el mapa';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Evento';

  @override
  String get tray_notice => 'Aviso';

  @override
  String get tray_noRadioPosition =>
      'Tu radio aún no tiene posición. Elige una en el mapa.';

  @override
  String get dialog_insert => 'Insertar';

  @override
  String get dialog_eventTitle => 'Título';

  @override
  String get dialog_eventDate => 'Fecha';

  @override
  String get dialog_eventStart => 'Inicio';

  @override
  String get dialog_eventEnd => 'Fin';

  @override
  String get dialog_eventNoEnd => 'Sin hora de fin';

  @override
  String get dialog_eventPlace => 'Lugar (opcional)';

  @override
  String get dialog_pickOnMap => 'Elegir en el mapa';

  @override
  String get dialog_sosTitle => 'Enviar SOS';

  @override
  String get dialog_sosText => '¿Qué ha pasado?';

  @override
  String get dialog_noticeTitle => 'Aviso';

  @override
  String get dialog_noticeText => '¿Qué debería saber todo el mundo?';

  @override
  String get dialog_labelTitle => 'Punto en el mapa';

  @override
  String get dialog_note => 'Nota (opcional)';

  @override
  String get paste_convertLocation =>
      'Parece un enlace de mapas. ¿Convertirlo en una Ubicación?';

  @override
  String get paste_convertEvent =>
      'Parece un evento de calendario compartido. ¿Convertirlo en un Evento?';

  @override
  String get paste_convert => 'Convertir';

  @override
  String get paste_resolving => 'Resolviendo el enlace…';

  @override
  String get paste_resolveFailed => 'No se pudo resolver el enlace';

  @override
  String get pinned_dismiss => 'Descartar';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return '¿Unirse al canal $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Ya estás en $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Te uniste a $name';
  }

  @override
  String get map_pickPositionHint => 'Toca el mapa para elegir una posición';

  @override
  String get map_legendMesh => 'Red mesh';

  @override
  String get chartLegend_title => 'Símbolos de las cartas náuticas';

  @override
  String get chartLegend_sectionBuoys => 'Boyas y balizas';

  @override
  String get chartLegend_sectionLights => 'Luces';

  @override
  String get chartLegend_sectionHazards => 'Peligros';

  @override
  String get chartLegend_sectionTides => 'Mareas y corrientes';

  @override
  String get chartLegend_sectionDepths => 'Profundidades y fondo';

  @override
  String get chartLegend_sectionAreas => 'Zonas, vías y líneas';

  @override
  String get chartLegend_sectionLandmarks => 'Puntos notables';

  @override
  String get chartLegend_sectionAbbreviations => 'Abreviaturas';

  @override
  String get chartLegend_chartNo1 => 'Todos los símbolos: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Boya cilíndrica verde';

  @override
  String get chartLegend_portBuoyHint =>
      'Déjala a tu izquierda al entrar desde el mar';

  @override
  String get chartLegend_starboardBuoy => 'Boya cónica roja';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Déjala a tu derecha al entrar: rojo a la derecha al volver';

  @override
  String get chartLegend_junctionBuoy => 'Boya con franjas';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Bifurcación de canal: tómala por el color de su franja superior';

  @override
  String get chartLegend_safeWaterBuoy => 'Franjas rojas y blancas';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Aguas navegables alrededor, a menudo en la entrada de un canal';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Franjas negras y rojas';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Un peligro pequeño con aguas navegables alrededor: mantente alejado';

  @override
  String get chartLegend_specialBuoy => 'Boya amarilla';

  @override
  String get chartLegend_specialBuoyHint =>
      'Uso especial, no sirve para orientarse: fondeadero, cable, investigación';

  @override
  String get chartLegend_cardinalBuoy => 'Negra y amarilla';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Marca cardinal: pasa por el lado que indica su nombre (rara en EE. UU.)';

  @override
  String get chartLegend_mooringBuoy => 'Boya de amarre';

  @override
  String get chartLegend_portBeacon => 'Baliza cuadrada verde';

  @override
  String get chartLegend_portBeaconHint =>
      'Como una boya verde: déjala a tu izquierda al entrar';

  @override
  String get chartLegend_starboardBeacon => 'Baliza triangular roja';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Como una boya roja: déjala a tu derecha al entrar';

  @override
  String get chartLegend_otherBeacon => 'Baliza en rombo';

  @override
  String get chartLegend_otherBeaconHint =>
      'Información o aviso, no un lado del canal';

  @override
  String get chartLegend_beaconTower => 'Torre de luz o estructura de baliza';

  @override
  String get chartLegend_topmark => 'Marca de tope';

  @override
  String get chartLegend_topmarkHint =>
      'La forma en lo alto de una marca completa su significado';

  @override
  String get chartLegend_light => 'Luz';

  @override
  String get chartLegend_lightHint =>
      'El destello magenta marca una luz; su etiqueta indica cómo destella';

  @override
  String get chartLegend_lightExample => 'Destellos verdes, cada 4 segundos';

  @override
  String get chartLegend_lightExampleHint =>
      'Etiqueta de una luz: ritmo, color y luego período';

  @override
  String get chartLegend_lightFixed => 'Fija';

  @override
  String get chartLegend_lightFixedHint => 'Una luz continua';

  @override
  String get chartLegend_lightFlashing => 'De destellos';

  @override
  String get chartLegend_lightFlashingHint =>
      'Destellos cortos, oscuridad más larga entre ellos';

  @override
  String get chartLegend_lightGroup => 'Grupos de destellos';

  @override
  String get chartLegend_lightGroupHint =>
      'Destellos en grupos, aquí de 2, y luego oscuridad';

  @override
  String get chartLegend_lightComposite => 'Grupos compuestos';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 destellos, luego 1: marca una bifurcación de canal';

  @override
  String get chartLegend_lightQuick => 'Centelleante';

  @override
  String get chartLegend_lightQuickHint =>
      'Alrededor de un destello por segundo';

  @override
  String get chartLegend_lightIsophase => 'Isofase';

  @override
  String get chartLegend_lightIsophaseHint => 'Luz y oscuridad iguales';

  @override
  String get chartLegend_lightOcculting => 'De ocultaciones';

  @override
  String get chartLegend_lightOccultingHint =>
      'Encendida más tiempo que apagada';

  @override
  String get chartLegend_lightMorse => 'Código Morse A';

  @override
  String get chartLegend_lightMorseHint => 'Corto, largo: aguas navegables';

  @override
  String get chartLegend_lightAlternating => 'Alternativa';

  @override
  String get chartLegend_lightAlternatingHint => 'Cambia de color';

  @override
  String get chartLegend_lightColours => 'Blanca, roja, verde, amarilla';

  @override
  String get chartLegend_lightPeriod => 'Período';

  @override
  String get chartLegend_lightPeriodHint => 'Segundos de un ciclo completo';

  @override
  String get chartLegend_rock => 'Roca sumergida';

  @override
  String get chartLegend_rockHint =>
      'Siempre cubierta, pero puede estar a poca profundidad';

  @override
  String get chartLegend_rockAwash => 'Roca a flor de agua';

  @override
  String get chartLegend_rockAwashHint => 'Cerca de la superficie en bajamar';

  @override
  String get chartLegend_rockCovers => 'Roca que cubre y descubre';

  @override
  String get chartLegend_rockCoversHint =>
      'Se ve en bajamar, cubierta en pleamar';

  @override
  String get chartLegend_wreckDangerous => 'Naufragio peligroso';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Lo bastante somero para chocar con él';

  @override
  String get chartLegend_wreck => 'Naufragio';

  @override
  String get chartLegend_wreckHint =>
      'Lo bastante profundo para barcos en superficie; no fondees';

  @override
  String get chartLegend_wreckShowing => 'Naufragio que vela';

  @override
  String get chartLegend_wreckShowingHint => 'Una parte asoma sobre el agua';

  @override
  String get chartLegend_obstruction => 'Obstrucción';

  @override
  String get chartLegend_obstructionHint =>
      'Algo en el fondo; su profundidad si se conoce';

  @override
  String get chartLegend_foulGround => 'Fondo sucio';

  @override
  String get chartLegend_foulGroundHint =>
      'Se puede pasar por encima, pero no fondees ni arrastres';

  @override
  String get chartLegend_hazardArea => 'Límite de una zona peligrosa';

  @override
  String get chartLegend_hazardAreaHint =>
      'Rocas, naufragios u obstrucciones en su interior';

  @override
  String get chartLegend_pile => 'Pilote o poste';

  @override
  String get chartLegend_floodStream => 'Corriente de flujo';

  @override
  String get chartLegend_floodStreamHint => 'Corriente de marea mientras sube';

  @override
  String get chartLegend_ebbStream => 'Corriente de reflujo';

  @override
  String get chartLegend_ebbStreamHint => 'Corriente de marea mientras baja';

  @override
  String get chartLegend_current => 'Corriente';

  @override
  String get chartLegend_currentHint =>
      'Fluye en el mismo sentido sea cual sea la marea';

  @override
  String get chartLegend_rips => 'Escarceos o remolinos';

  @override
  String get chartLegend_ripsHint => 'Agua agitada y arremolinada';

  @override
  String get chartLegend_breakers => 'Rompientes';

  @override
  String get chartLegend_breakersHint => 'Olas que rompen sobre bajos';

  @override
  String get chartLegend_sounding => 'Sonda';

  @override
  String get chartLegend_soundingHint => 'Profundidad en una bajamar media';

  @override
  String get chartLegend_depthContour => 'Isóbata';

  @override
  String get chartLegend_depthContourHint =>
      'Su etiqueta indica la profundidad';

  @override
  String get chartLegend_drying => 'Descubre en bajamar';

  @override
  String get chartLegend_dredged => 'Canal dragado';

  @override
  String get chartLegend_dredgedHint => 'Se mantiene a la profundidad indicada';

  @override
  String get chartLegend_swept => 'Zona rastreada';

  @override
  String get chartLegend_sweptHint =>
      'Comprobada libre hasta la profundidad indicada';

  @override
  String get chartLegend_unsurveyed => 'Sin sondar';

  @override
  String get chartLegend_unsurveyedHint => 'Sin profundidades medidas';

  @override
  String get chartLegend_weed => 'Algas o kelp';

  @override
  String get chartLegend_restricted => 'Zona restringida';

  @override
  String get chartLegend_restrictedHint =>
      'Acceso limitado; las marcas apuntan hacia dentro';

  @override
  String get chartLegend_regulatedLimit => 'Límite de una zona reglamentada';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Fondeadero, zona de cables, zona de tiro y más: mira su etiqueta';

  @override
  String get chartLegend_greyLimit =>
      'Zona de vertidos, caladero o acuicultura';

  @override
  String get chartLegend_anchorage => 'Fondeadero';

  @override
  String get chartLegend_anchorBerth => 'Puesto de fondeo';

  @override
  String get chartLegend_noAnchoring => 'Prohibido fondear';

  @override
  String get chartLegend_caution => 'Zona de advertencia';

  @override
  String get chartLegend_cautionHint => 'Extrema la precaución aquí';

  @override
  String get chartLegend_trafficLane => 'Vía de circulación';

  @override
  String get chartLegend_trafficLaneHint =>
      'Buques grandes, sentido único: crúzala en ángulo recto';

  @override
  String get chartLegend_separationZone => 'Zona de separación';

  @override
  String get chartLegend_separationZoneHint =>
      'Entre vías de circulación: no entres';

  @override
  String get chartLegend_precautionary => 'Zona de precaución';

  @override
  String get chartLegend_precautionaryHint =>
      'Los buques convergen: precaución';

  @override
  String get chartLegend_fairway => 'Canal navegable';

  @override
  String get chartLegend_fairwayHint => 'Un canal principal';

  @override
  String get chartLegend_track => 'Derrota recomendada';

  @override
  String get chartLegend_ferry => 'Ruta de ferri';

  @override
  String get chartLegend_leadingLine => 'Enfilación';

  @override
  String get chartLegend_leadingLineHint =>
      'Alinea sus dos marcas para seguir en el canal';

  @override
  String get chartLegend_cable => 'Cable submarino';

  @override
  String get chartLegend_cableHint => 'No fondees';

  @override
  String get chartLegend_pipeline => 'Tubería submarina';

  @override
  String get chartLegend_pipelineHint => 'No fondees';

  @override
  String get chartLegend_overhead => 'Cable aéreo';

  @override
  String get chartLegend_overheadHint => 'Su altura libre se indica con VC';

  @override
  String get chartLegend_tower => 'Torre';

  @override
  String get chartLegend_windTurbine => 'Aerogenerador';

  @override
  String get chartLegend_chimney => 'Chimenea';

  @override
  String get chartLegend_mast => 'Mástil o antena';

  @override
  String get chartLegend_church => 'Iglesia o campanario';

  @override
  String get chartLegend_flagstaff => 'Asta de bandera';

  @override
  String get chartLegend_dome => 'Cúpula';

  @override
  String get chartLegend_landmark => 'Otro punto notable';

  @override
  String get chartLegend_abbrAnch => 'Fondeadero';

  @override
  String get chartLegend_abbrWk => 'Naufragio';

  @override
  String get chartLegend_abbrBr => 'Rompientes';

  @override
  String get chartLegend_abbrWd => 'Algas';

  @override
  String get chartLegend_abbrVar => 'Declinación magnética';

  @override
  String get chartLegend_abbrVc => 'Altura libre bajo un puente o cable';

  @override
  String get chartLegend_abbrTr => 'Torre';

  @override
  String get chartLegend_abbrCh => 'Iglesia';

  @override
  String get chartLegend_abbrChy => 'Chimenea';

  @override
  String get chartLegend_abbrFs => 'Asta de bandera';

  @override
  String get chartLegend_abbrTk => 'Depósito';

  @override
  String get chartLegend_abbrRBn => 'Radiofaro';

  @override
  String get chartLegend_abbrCg => 'Estación de guardacostas';

  @override
  String get chartLegend_abbrRacon => 'Baliza radar: aparece en el radar';

  @override
  String get chartLegend_abbrFog =>
      'Señal de niebla: bocina, campana, gong, silbato o sirena';

  @override
  String get chartLegend_abbrVAis => 'Ayuda virtual: solo aparece en AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return 'De $from a $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Más de $depth';
  }

  @override
  String get parkLegend_title => 'Símbolos de parques y senderos';

  @override
  String get parkLegend_campsite => 'Zona de acampada';

  @override
  String get parkLegend_picnicSite => 'Zona de pícnic';

  @override
  String get parkLegend_shelter => 'Refugio';

  @override
  String get parkLegend_toilets => 'Aseos';

  @override
  String get parkLegend_drinkingWater => 'Agua potable';

  @override
  String get parkLegend_parking => 'Aparcamiento';

  @override
  String get parkLegend_viewpoint => 'Mirador';

  @override
  String get parkLegend_attraction => 'Atracción turística';

  @override
  String get parkLegend_gate => 'Puerta';

  @override
  String get parkLegend_telephone => 'Teléfono';

  @override
  String get parkLegend_information => 'Panel informativo';

  @override
  String get parkLegend_guidepost => 'Poste indicador';

  @override
  String get dialog_noticeExpires => 'Caduca';

  @override
  String get dialog_noticeNoExpiry => 'Nunca';

  @override
  String get dialog_noticeExpiryRequired =>
      'Elige una fecha (obligatoria en una sala)';

  @override
  String get dialog_noticeExpiryTime => 'Hora';

  @override
  String get dialog_noticeEndOfDay => 'Al final del día';

  @override
  String structured_until(String when) {
    return 'Hasta $when';
  }

  @override
  String get structured_expired => 'Caducado';

  @override
  String get structured_announcement => 'Anuncio';

  @override
  String structured_locationOf(String name) {
    return 'Ubicación de $name';
  }

  @override
  String get reaction_searchHint => 'Buscar emojis';

  @override
  String get reaction_noResults => 'No se encontraron emojis';

  @override
  String get share_qrAndLink => 'Compartir código QR y enlace';

  @override
  String get share_roomTitle => 'Compartir sala';

  @override
  String get share_contactTitle => 'Compartir contacto';

  @override
  String get share_roomInstructions =>
      'Escanea para añadir esta sala. Necesitarás su contraseña para iniciar sesión.';

  @override
  String get share_contactInstructions => 'Escanea para añadir este contacto.';

  @override
  String get clearChat_body =>
      'Borra mensajes de este chat solo en este dispositivo. Los mensajes nuevos seguirán llegando aquí.';

  @override
  String get clearChat_olderThanDay => 'De hace más de 1 día';

  @override
  String get clearChat_olderThanWeek => 'De hace más de 1 semana';

  @override
  String get clearChat_olderThanMonth => 'De hace más de 1 mes';

  @override
  String get clearChat_everything => 'Todos los mensajes';

  @override
  String get chats_markAllRead => 'Marcar todo como leído';

  @override
  String chats_markAllReadBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '¿Marcar $count chats como leídos?',
      one: '¿Marcar 1 chat como leído?',
    );
    return '$_temp0';
  }

  @override
  String get chats_markRead => 'Marcar como leído';

  @override
  String get chats_nothingUnread => 'No hay mensajes sin leer';

  @override
  String get chats_draft => 'Borrador';

  @override
  String get contact_teleBlockedTitle => 'Bloqueado por tu radio';

  @override
  String contact_teleBlockedBody(String name) {
    return 'La configuración de privacidad de tu radio no lo comparte con nadie, así que $name no lo recibirá. ¿Cambiarla para que lo reciban los contactos que permitas?';
  }

  @override
  String get contact_teleNotNow => 'Ahora no';

  @override
  String contact_teleRadioDenies(String mode) {
    return 'Tu radio no lo comparte con nadie ($mode)';
  }

  @override
  String contact_teleRadioAllowsAll(String mode) {
    return 'Tu radio lo comparte con todos ($mode)';
  }

  @override
  String get contact_sharesPosition => 'Puede obtener tu ubicación';

  @override
  String get pathfinder_meshTitle => '¿Otra red mesh?';

  @override
  String pathfinder_meshNewBody(int unknown, int heard, String graph) {
    return '$unknown de $heard repetidores oídos desde la conexión son nuevos para el mapa de Pathfinder «$graph». ¿Empezar un mapa nuevo para esta zona? El anterior se conserva y puedes volver a él en la pantalla de Pathfinder.';
  }

  @override
  String pathfinder_meshSwitchBody(String other, String graph) {
    return 'La mayoría de los repetidores oídos desde la conexión están en el mapa de Pathfinder «$other», no en «$graph». ¿Cambiar a ese mapa?';
  }

  @override
  String get pathfinder_meshNew => 'Mapa nuevo';

  @override
  String get pathfinder_meshSwitch => 'Cambiar';

  @override
  String get pathfinder_meshKeep => 'Mantener este';

  @override
  String get pathfinder_graphNameTitle => 'Nombre del mapa nuevo';

  @override
  String get pathfinder_graphNameHint => 'Por ejemplo, Washington';

  @override
  String get pathfinder_graphCreate => 'Crear';

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
}
