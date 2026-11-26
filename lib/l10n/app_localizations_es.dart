// ignore_for_file: deprecated_member_use

// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get tray_photo => 'Foto';

  @override
  String get photo_settingsTitle => 'Fotos';

  @override
  String photo_enableHint(String size) {
    return 'Send and see photos over the radio. Needs the $size photo model on this phone.';
  }

  @override
  String photo_sendTitle(String channel) {
    return 'Foto para $channel';
  }

  @override
  String get photo_squareIntro =>
      'Pick a photo, then choose the square to send.';

  @override
  String get photo_takePhoto => 'Tomar una foto';

  @override
  String get photo_choosePhoto => 'Elegir una foto';

  @override
  String get photo_chooseAnother => 'Elegir otra foto';

  @override
  String get photo_cropHint =>
      'Mueve y haz zoom hasta que lo importante llene el cuadrado.';

  @override
  String get photo_preview => 'Vista previa';

  @override
  String get photo_changeCrop => 'Change crop';

  @override
  String get photo_checkingAndCoding => 'Comprobando y codificando la foto…';

  @override
  String get photo_modelMissing =>
      'The photo model isn\'t on this device. Turn on Photos in App settings, Messaging, to download it.';

  @override
  String get photo_previewNoMemory =>
      'No hay memoria suficiente aquí para mostrar lo que verán los demás. Aun así puedes enviarla.';

  @override
  String get photo_rebuildingPreview =>
      'Reconstruyendo lo que verán los demás… unos 20 segundos';

  @override
  String photo_prepareFailed(String error) {
    return 'No se pudo preparar la foto: $error';
  }

  @override
  String get photo_flaggedNotSent =>
      'Esta foto no se puede enviar: el control de seguridad la marcó.';

  @override
  String get photo_tagTitle => 'Etiqueta (opcional)';

  @override
  String get photo_blurFaces => 'Blur faces';

  @override
  String photo_facesBlurred(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count faces blurred',
      one: '1 face blurred',
    );
    return '$_temp0';
  }

  @override
  String photo_facesDarkened(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count faces covered in grey: blurred, the photo didn\'t pass the safety check',
      one: '1 face covered in grey: blurred, the photo didn\'t pass the safety check',
    );
    return '$_temp0';
  }

  @override
  String get photo_includePosition => 'Include location';

  @override
  String photo_positionFromRadio(String distance) {
    return 'Your radio\'s location now, to about $distance';
  }

  @override
  String get photo_noPosition => 'Your radio has no location';

  @override
  String get photo_distance10km => '10 km';

  @override
  String get photo_distance600m => '600 m';

  @override
  String get photo_distance40m => '40 m';

  @override
  String get photo_distance2m => '2 m';

  @override
  String photo_positionAt(String position, String distance) {
    return '$position, to about $distance';
  }

  @override
  String get photo_zeroHop => 'Zero hop';

  @override
  String get photo_subjectOnly => 'Subject only';

  @override
  String get photo_autoCrop => 'Auto crop';

  @override
  String get photo_tapWhatMatters =>
      'Tap what matters. Tap more things to add them.';

  @override
  String get photo_outlining => 'Outlining…';

  @override
  String get photo_clearTaps => 'Clear';

  @override
  String get photo_nothingThere =>
      'Nothing to outline there. Tap the middle of it.';

  @override
  String get photo_zeroHopNearbyOnly => 'This channel is Nearby only';

  @override
  String get photo_repairPacket => 'Repair packet';

  @override
  String photo_sendFigures(int packets, String sendTime) {
    String _temp0 = intl.Intl.pluralLogic(
      packets,
      locale: localeName,
      other: '$packets packets',
      one: '1 packet',
    );
    return '$_temp0 · about $sendTime to send';
  }

  @override
  String photo_seconds(String seconds) {
    return '$seconds s';
  }

  @override
  String photo_blockedWaitRepeaters(int packets, int gap, int minutes) {
    return 'En las frecuencias de MeshCore, una radio envía una foto a través de repetidores cada $gap minutos. Puedes enviar otra a través de repetidores en $minutes min, o una con cero saltos ahora.';
  }

  @override
  String get photo_send => 'Enviar';

  @override
  String get photo_sending => 'Enviando…';

  @override
  String photo_sendingPacket(int sent, int total) {
    return 'Paquete $sent de $total';
  }

  @override
  String photo_sendingRepairPacket(int sent, int total) {
    return 'Paquete $sent de $total (reparación)';
  }

  @override
  String photo_sendingPacketAgain(int sent, int total) {
    return 'Packet $sent of $total again';
  }

  @override
  String photo_passedOnSome(int heard, int total) {
    return 'Sent · repeaters passed on $heard of its $total packets';
  }

  @override
  String photo_notSent(String error) {
    return 'No enviada: $error';
  }

  @override
  String get photo_errorNotConnected => 'no hay conexión con una radio';

  @override
  String get photo_errorNoAnswer => 'la radio no respondió';

  @override
  String photo_errorRefused(int code) {
    return 'la radio rechazó un paquete (error $code)';
  }

  @override
  String get photo_confirmTitle => 'Send photo';

  @override
  String photo_openChannelTitle(String channel) {
    return 'Photos on $channel';
  }

  @override
  String get photo_openChannelNotEveryone =>
      'Most people here won\'t see it: only MeshTrax shows photos.';

  @override
  String photo_openChannelAirtime(String airtime, int messages) {
    return 'This photo takes $airtime on air, as much as $messages text messages.';
  }

  @override
  String get photo_openChannelRepeaters =>
      'Each repeater that passes it on sends all of it again, on a frequency everyone around you shares.';

  @override
  String get photo_openChannelBetter =>
      'Better: zero hop when the people are close, or a private channel with the people who want photos. Crop tight: a simpler picture is fewer packets.';

  @override
  String get photo_dontShowAgain => 'Don\'t show this again';

  @override
  String photo_confirmAirtime(int packets, String airtime, int messages) {
    return '$packets packets, $airtime on air: as much as $messages text messages.';
  }

  @override
  String photo_confirmOpenChannel(String channel) {
    return 'Anyone on $channel using MeshTrax can see it. Other apps don\'t show photos.';
  }

  @override
  String get photo_confirmFlood =>
      'Each repeater that hears it sends it again.';

  @override
  String get photo_confirmZeroHop =>
      'Zero hop: only radios in direct range get it.';

  @override
  String get photo_label => 'AI reconstructed';

  @override
  String get photo_tapToView => 'Tap to view';

  @override
  String get photo_enhance => 'Enhance 4×';

  @override
  String get photo_enhancing => 'Enhancing…';

  @override
  String get photo_save => 'Save';

  @override
  String get photo_saved => 'Saved to your photos';

  @override
  String get photo_saveFailed => 'Couldn\'t save the photo.';

  @override
  String get photo_details => 'About this photo';

  @override
  String photo_caption(int bytes) {
    return 'Reconstruida por un modelo de IA a partir de $bytes bytes. Los detalles finos se generan, no se envían: los letreros y el texto no llegan. No es un registro de lo que había allí.';
  }

  @override
  String get photo_enlargedNote =>
      'Enhanced 4× on this phone: fine detail may be made up.';

  @override
  String get photo_enlargeNoMemory =>
      'Not enough free memory to enlarge it now. Close other apps, then try again.';

  @override
  String get photo_enlargeFlagged =>
      'The enlarged picture didn\'t pass the safety check, so it isn\'t shown.';

  @override
  String get photo_enlargeFailed => 'Couldn\'t enlarge the photo.';

  @override
  String get photo_enlargeAutomatically => 'Enlarge photos automatically';

  @override
  String get photo_enlargeAutomaticallyHint =>
      'Off: tap a photo full screen to enlarge it 4×. On: it enlarges as it opens.';

  @override
  String get photo_ignoreTimeLimits => 'Ignore the photo time limits';

  @override
  String get photo_ignoreTimeLimitsHint =>
      'For testing: send photos through repeaters without waiting between them.';

  @override
  String get photo_rebuilding => 'Reconstruyendo… unos 20 s';

  @override
  String get photo_hiddenFlagged => 'Imagen oculta: marcada como inapropiada';

  @override
  String get photo_hiddenReported => 'Foto oculta: la denunciaste';

  @override
  String get photo_noMemory =>
      'Ahora no hay memoria suficiente para reconstruir esta foto. Cierra otras apps o reinicia MeshTrax y vuelve a intentarlo.';

  @override
  String get photo_rebuildFailed => 'No se pudo reconstruir esta foto.';

  @override
  String get photo_report => 'Denunciar';

  @override
  String photo_block(String name) {
    return 'Bloquear a $name';
  }

  @override
  String photo_blockedSender(String name) {
    return 'Bloqueaste a $name';
  }

  @override
  String get photo_reportTitle => 'Denunciar esta foto';

  @override
  String get photo_reportBody =>
      'The photo is hidden on this phone straight away, for good, and a report goes to the MeshTrax developer from the app, now or when there\'s internet. Nothing else from your phone is sent.';

  @override
  String get photo_reportInclude => 'Incluir la foto';

  @override
  String get photo_reportIncludeHint =>
      'Su código, unos cientos de bytes, a partir del cual se puede reconstruir. No la imagen en sí.';

  @override
  String get photo_reportReason => 'What\'s wrong? (optional)';

  @override
  String get photo_reportedSent =>
      'Photo hidden, and the report is sent. Thank you.';

  @override
  String get photo_reportedQueued =>
      'Photo hidden. The report will be sent when there\'s internet.';

  @override
  String photo_reportPending(String name) {
    return 'Denuncia de foto: $name';
  }

  @override
  String get photo_reportPendingHint => 'Waiting for internet to send';

  @override
  String get photo_reportStillWaiting =>
      'Still no internet. It will be sent later.';

  @override
  String get photo_autoRebuild =>
      'Reconstruir automáticamente las fotos recibidas';

  @override
  String get photo_autoRebuildHint =>
      'Desactivado: toca una foto para reconstruirla. Activado: cada foto se reconstruye al llegar, mientras MeshTrax esté abierto y el teléfono tenga memoria suficiente.';

  @override
  String get photo_modelTitle => 'Modelo de fotos';

  @override
  String photo_modelProgress(String done, String total) {
    return '$done de $total';
  }

  @override
  String get photo_modelChecking => 'Comprobando la descarga…';

  @override
  String get photo_modelRetrying => 'Reintentando…';

  @override
  String get photo_modelPaused => 'En pausa';

  @override
  String get photo_modelWaitingWifi =>
      'Esperando: las descargas esperan al Wi‑Fi';

  @override
  String get photo_modelWaiting => 'Esperando…';

  @override
  String photo_modelInstalled(String size) {
    return 'En este dispositivo ($size)';
  }

  @override
  String photo_modelFailed(String error) {
    return 'Error en la descarga: $error';
  }

  @override
  String get photo_modelNoReason => 'sin motivo indicado';

  @override
  String photo_modelNeeded(String size) {
    return 'Necesario para enviar y reconstruir fotos: $size';
  }

  @override
  String get photo_keepOpen =>
      'Mantén MeshTrax abierto hasta que termine la descarga. El progreso también se muestra en Mapas sin conexión.';

  @override
  String photo_licencesLink(String poweredBy) {
    return '$poweredBy · Licencias';
  }

  @override
  String get photo_cancelDownload => 'Cancelar la descarga';

  @override
  String get photo_downloadModel => 'Descargar el modelo de fotos';

  @override
  String get photo_tryAgain => 'Reintentar';

  @override
  String get photo_deleteModel => 'Eliminar el modelo de fotos';

  @override
  String get photo_downloadLicences => 'Descargar los textos de las licencias';

  @override
  String get photo_deleteModelTitle => '¿Eliminar el modelo de fotos?';

  @override
  String photo_deleteModelBody(String size) {
    return 'No se podrán enviar ni reconstruir fotos hasta que se vuelva a descargar ($size).';
  }

  @override
  String get photo_keep => 'Conservar';

  @override
  String photo_notEnoughSpace(String needed, String free) {
    return 'No hay espacio suficiente: el modelo de fotos necesita $needed libres y este dispositivo tiene $free.';
  }

  @override
  String photo_downloadName(int index, int count) {
    return 'Modelo de fotos ($index de $count)';
  }

  @override
  String photo_downloadLicenceName(int index, int count) {
    return 'Licencia del modelo de fotos ($index de $count)';
  }

  @override
  String get photo_licencesTitle => 'Licencias del modelo de fotos';

  @override
  String get photo_licencesIntro =>
      'El modelo que reconstruye las fotos se basa en SD-Turbo de Stability AI, con el códec de imagen AEIC y el decodificador de AdcSR; el control de seguridad usa un clasificador de imágenes basado en SwiftFormer. Estos son el aviso y las licencias que los acompañan.';

  @override
  String get photo_licencesMissing =>
      'Los textos de las licencias se descargan con el modelo de fotos.';

  @override
  String photo_message(String id) {
    return '📷 Foto $id';
  }

  @override
  String photo_messageWithTag(String id, String tag) {
    return '📷 Foto $id · $tag';
  }

  @override
  String photo_incomplete(String id, int got, int total) {
    return '📷 Foto $id incompleta: $got de $total paquetes';
  }

  @override
  String photo_unreadable(String id) {
    return '📷 Foto $id ilegible';
  }

  @override
  String photo_needsNewer(String id) {
    return '📷 Photo $id needs a newer MeshTrax';
  }

  @override
  String photo_unknownSender(String id) {
    return 'Nodo $id';
  }

  @override
  String get photo_chatPhoto => '📷 Foto';

  @override
  String get photo_cameraDenied =>
      'MeshTrax no puede usar la cámara. Puedes permitirlo en los ajustes del teléfono.';

  @override
  String photo_pickFailed(String error) {
    return 'Sin foto: $error';
  }

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
  String get common_experimental => 'EXPERIMENTAL';

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
  String get healthCheck_title => 'Revisión de estado';

  @override
  String get healthCheck_subtitle =>
      'Comprueba la configuración de la app y de la radio';

  @override
  String get healthCheck_running => 'Comprobando la configuración…';

  @override
  String get healthCheck_waitingForSync =>
      'La radio aún se está sincronizando. La comprobación empezará cuando termine.';

  @override
  String get healthCheck_noRadio =>
      'No hay ninguna radio conectada, así que no se comprobó su configuración.';

  @override
  String get healthCheck_partial =>
      'No se pudo leer parte de la configuración de la radio, así que estos resultados pueden estar desactualizados. Vuelve a comprobarlo en un momento.';

  @override
  String get healthCheck_allClear => 'Todo parece correcto.';

  @override
  String get healthCheck_problems => 'Problemas';

  @override
  String get healthCheck_suggestions => 'Sugerencias';

  @override
  String get healthCheck_tips => 'Consejos';

  @override
  String healthCheck_passed(int count) {
    return 'Comprobaciones superadas: $count';
  }

  @override
  String get healthCheck_runAgain => 'Comprobar de nuevo';

  @override
  String get healthCheck_fix => 'Corregir';

  @override
  String get healthCheck_fixFailed =>
      'El cambio no se aplicó. Comprueba la conexión con la radio e inténtalo de nuevo.';

  @override
  String get healthCheck_openFailed =>
      'No se pudo abrir esa página de configuración. Cámbialo en la configuración de tu dispositivo.';

  @override
  String get healthCheck_hide => 'No volver a mostrar';

  @override
  String healthCheck_showHidden(int count) {
    return 'Mostrar avisos ocultos: $count';
  }

  @override
  String healthCheck_fixAll(int count) {
    return 'Corregir todo ($count)';
  }

  @override
  String get healthCheck_fixAllConfirm => '¿Hacer estos cambios?';

  @override
  String get healthCheck_promptTitle => '¿Hacer una revisión de estado?';

  @override
  String get healthCheck_promptBody =>
      'Mira qué podría funcionar mejor en la configuración de la app y de la radio, incluidas formas de recibir menos notificaciones.';

  @override
  String get healthCheck_promptBodyDesktop =>
      'Mira qué podría funcionar mejor en la configuración de la app y de la radio.';

  @override
  String get healthCheck_promptRun => 'Revisar';

  @override
  String get healthCheck_promptLater => 'Ahora no';

  @override
  String get settings_title => 'Configuración';

  @override
  String get trax_title => 'Modo TRAX';

  @override
  String get trax_isOn => 'El modo TRAX está activado';

  @override
  String get trax_isOff => 'El modo TRAX está desactivado';

  @override
  String get trax_intro =>
      'Pasa tu radio a la frecuencia del grupo. La malla habitual no te oye hasta que salgas.';

  @override
  String get trax_now => 'Ahora';

  @override
  String get trax_inTrax => 'En modo TRAX';

  @override
  String get trax_repeatOn => '«Repetir sin conexión» activado';

  @override
  String get trax_savedNote => '«Salir de TRAX» restaura tus ajustes.';

  @override
  String trax_until(String time) {
    return 'Hasta $time';
  }

  @override
  String get trax_noEnd => 'Indica el fin de la salida en los ajustes de TRAX.';

  @override
  String get trax_tellsNot => 'No avisa al grupo.';

  @override
  String get trax_noChannel =>
      'Elige un canal de la salida en los ajustes de TRAX, o desactiva «Avisar al grupo».';

  @override
  String get trax_trailhead =>
      'Cambia en el punto de partida, cuando la radio tenga posición GPS.';

  @override
  String get trax_settings => 'Ajustes de TRAX';

  @override
  String get trax_switch => 'Cambiar a TRAX';

  @override
  String trax_heard(int count, String names) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Oídos en TRAX ($count): $names',
      zero: 'Aún no se ha oído a nadie en TRAX',
    );
    return '$_temp0';
  }

  @override
  String get trax_checkAgain => 'Comprobar de nuevo';

  @override
  String get trax_noSaved =>
      'No hay ajustes guardados en este teléfono: «Salir de TRAX» pregunta a qué preajuste volver.';

  @override
  String get trax_leave => 'Salir de TRAX';

  @override
  String get trax_unsupported =>
      'El firmware de esta radio no puede retransmitir para otros. Actualízalo para usar el modo TRAX.';

  @override
  String get trax_stepTelling => 'Avisando al grupo…';

  @override
  String get trax_stepSwitching => 'Cambiando…';

  @override
  String get trax_stepChecking => 'Enviando la comprobación del grupo…';

  @override
  String get trax_stepLeaving => 'Saliendo…';

  @override
  String get trax_errorBusy =>
      'La radio sigue ocupada. Inténtalo de nuevo en un momento.';

  @override
  String get trax_errorRefused =>
      'La radio no aceptó los ajustes. No ha cambiado nada.';

  @override
  String trax_errorNotAllowed(String mhz) {
    return 'Esta radio no puede retransmitir en $mhz MHz.';
  }

  @override
  String get trax_unconfirmed =>
      'Mensaje TRAX no confirmado. Avisa al grupo de otra forma.';

  @override
  String get trax_preset => 'Preajuste';

  @override
  String get trax_presetMesh => 'El de la malla';

  @override
  String get trax_presetLongRange => 'Largo alcance';

  @override
  String get trax_presetLongRangeHint =>
      'Llega un poco más lejos; los mensajes tardan ~3× más.';

  @override
  String get trax_tripChannel => 'Canal de la salida';

  @override
  String get trax_tripChannelHint => 'Solo canales privados';

  @override
  String get trax_none => 'Ninguno';

  @override
  String get trax_tripEnds => 'Fin de la salida';

  @override
  String get trax_notSet => 'Sin definir';

  @override
  String get trax_tellGroup => 'Avisar al grupo';

  @override
  String get trax_tellGroupHint =>
      'Publica en el canal de la salida; los demás siguen con un toque.';

  @override
  String get trax_keepTrack => 'Keep my track';

  @override
  String get trax_keepTrackHint =>
      'How far back your line goes, for you and the trip. Older parts are deleted on every phone.';

  @override
  String trax_keepTrackHours(int hours) {
    return '$hours hours';
  }

  @override
  String get trax_keepTrackWeek => '1 week';

  @override
  String get trax_icon => 'Your icon';

  @override
  String get trax_iconHint => 'How the trip sees you on the map.';

  @override
  String get trax_iconHike => 'Hike';

  @override
  String get trax_iconVehicle => 'Vehicle';

  @override
  String get trax_iconBoat => 'Boat';

  @override
  String get trax_iconMotorcycle => 'Motorcycle';

  @override
  String get trax_iconBicycle => 'Bicycle';

  @override
  String get trax_iconAircraft => 'Aircraft';

  @override
  String get trax_iconCamp => 'Camp';

  @override
  String trax_followBody(String name, String time) {
    return '$name ha cambiado al modo TRAX hasta el $time. ¿Cambiar tú también?';
  }

  @override
  String trax_followDetail(String settings) {
    return 'Pasa tu radio a $settings. La malla habitual no te oye hasta que salgas.';
  }

  @override
  String get trax_switchToo => 'Cambiar también';

  @override
  String get trax_notNow => 'Ahora no';

  @override
  String trax_leaveBody(String name) {
    return '$name sale del modo TRAX. ¿Salir tú también?';
  }

  @override
  String get trax_leaveToo => 'Salir también';

  @override
  String get trax_stillOn => 'Sigues en modo TRAX. ¿Salir?';

  @override
  String get trax_pickPreset => '¿A qué preajuste volver?';

  @override
  String get trax_pickPresetHint =>
      'Este teléfono no tiene ajustes guardados de esta radio: otro teléfono la cambió.';

  @override
  String trax_cardOn(String name) {
    return '$name ha cambiado al modo TRAX';
  }

  @override
  String trax_cardOff(String name) {
    return '$name sale del modo TRAX';
  }

  @override
  String get trax_cardYouOn => 'Has cambiado al modo TRAX';

  @override
  String get trax_cardYouOff => 'Has salido del modo TRAX';

  @override
  String get trax_youreOn => 'Estás en TRAX';

  @override
  String get trax_ended => 'Terminado';

  @override
  String get trax_notificationText =>
      'La malla habitual no te oye. Abre MeshTrax para salir.';

  @override
  String get trax_endedTitle => 'Tu salida ha terminado';

  @override
  String get trax_endedText =>
      'Sigues en modo TRAX: la malla habitual no te oye.';

  @override
  String get trip_members => 'Miembros de la salida';

  @override
  String get trip_pickChannel =>
      'Elige un canal de la salida: quien escriba en él es miembro.';

  @override
  String get trip_noPosts => 'Nadie ha escrito aún en el canal de la salida.';

  @override
  String get trip_notContact => 'No es un contacto en esta radio';

  @override
  String get trip_canAsk => 'Puede preguntar a tu radio';

  @override
  String get trip_addMember => 'Añadir un miembro';

  @override
  String get trip_askMyRadio => 'Los miembros pueden preguntar a mi radio';

  @override
  String get trip_askMyRadioHint =>
      'Dónde está, y su batería. Activa el GPS. Termina al salir de TRAX después de la salida.';

  @override
  String trip_shareOff(String setting) {
    return '$setting está desactivado: los miembros no pueden preguntar.';
  }

  @override
  String get trip_advertsHint =>
      'En modo TRAX. Cualquiera a su alcance puede leerla.';

  @override
  String get trip_sosTitle => '¿Que un SOS suene aunque esté No molestar?';

  @override
  String get trip_sosBody => 'Abre los ajustes y permite Ignorar No molestar.';

  @override
  String trip_onTrax(int on, int total) {
    return '$on de $total en TRAX';
  }

  @override
  String trip_notHeardYet(String name) {
    return '$name: aún no se le oye';
  }

  @override
  String trip_asking(String name) {
    return '$name: preguntando a su radio…';
  }

  @override
  String trip_noAnswer(String name) {
    return '$name: sin respuesta';
  }

  @override
  String trax_sendingEvery(String minutes) {
    return 'Tu ubicación se envía a la salida cada $minutes min.';
  }

  @override
  String get trax_noChannelData =>
      'El firmware de esta radio no puede enviar tu ubicación a la salida. Actualízalo.';

  @override
  String get trax_locationsNoChannel =>
      'Elige un canal de la salida en los ajustes de TRAX para compartir ubicaciones.';

  @override
  String trax_memberNoLocation(String name) {
    return '$name: aún sin ubicación';
  }

  @override
  String get trax_mayBeOld => 'puede ser antigua';

  @override
  String get trax_askTrack => 'Ask for track';

  @override
  String trax_trackAsked(String time) {
    return 'Track asked $time';
  }

  @override
  String get trax_group => 'TRAX group';

  @override
  String get trax_tripChannelLocation =>
      'En modo TRAX, tu ubicación se envía a este canal.';

  @override
  String get map_lastHeard => 'Última vez oído';

  @override
  String get map_fromYou => 'Desde ti';

  @override
  String get map_heading => 'Rumbo';

  @override
  String get map_speed => 'Velocidad';

  @override
  String get map_notMoving => 'Sin moverse';

  @override
  String map_notMovingSince(String time, int minutes) {
    return 'desde $time ($minutes min)';
  }

  @override
  String map_stoppedFor(int minutes) {
    return 'Sin moverse $minutes min';
  }

  @override
  String get map_elevation => 'Altitud';

  @override
  String get map_radioBattery => 'Batería de la radio';

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
  String get settings_traxSettingsSubtitle =>
      'Preajuste fuera de red, canal y fin de la salida';

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
  String get settings_reportBug => 'Informar de un error';

  @override
  String get settings_reportBugSubtitle => 'Abre un informe de error en GitHub';

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
      'Markdown en los mensajes: **negrita**, *cursiva*, ||texto oculto||, encabezados, listas y enlaces. Otras apps de MeshCore muestran los caracteres sin formato.';

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
  String get appSettings_maxDirectMessageTries => 'Max Direct Message Tries';

  @override
  String get appSettings_maxDirectMessageTriesSubtitle =>
      'Send attempts before a direct message or room post is marked failed. Known routes get the first tries; the rest flood.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Reintentos máx. de mensajes de canal';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Reintentará hasta este número de veces mientras no oiga al menos una repetición';

  @override
  String get appSettings_heardCheck => 'Comprobar envíos con observadores';

  @override
  String get appSettings_heardCheckSubtitle =>
      'Antes de reenviar un mensaje de canal, preguntar a un servidor de observadores si se escuchó';

  @override
  String get appSettings_heardServer => 'Servidor de observadores';

  @override
  String get appSettings_heardServerNotSet => 'Sin configurar';

  @override
  String get appSettings_heardServerAbout =>
      'Los observadores son radios que informan a un servidor de lo que oyen. MeshTrax envía a ese servidor una huella de cada mensaje de canal que envías, nunca su texto. El servidor ve tu dirección de internet y cuándo enviaste.';

  @override
  String get appSettings_heardServerOther => 'Otra dirección';

  @override
  String get appSettings_heardServerAddress => 'Dirección del servidor';

  @override
  String get appSettings_heardServerChecking => 'Comprobando el servidor…';

  @override
  String get appSettings_heardServerNoAnswer =>
      'Sin respuesta de esta dirección';

  @override
  String get appSettings_heardServerSaveAnyway => 'Guardar de todos modos';

  @override
  String get appSettings_heardServerAnswered => 'El servidor respondió';

  @override
  String chat_heardBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Escuchado por $count observadores',
      one: 'Escuchado por 1 observador',
    );
    return '$_temp0';
  }

  @override
  String get chat_heardDirect => 'directo';

  @override
  String chat_heardVia(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'vía $count repetidores',
      one: 'vía 1 repetidor',
    );
    return '$_temp0';
  }

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
  String radioAsk_title(String name) {
    return 'Preguntar a la radio de $name';
  }

  @override
  String get radioAsk_menuSubtitle => 'Funciona con su teléfono apagado';

  @override
  String get radioAsk_waiting => 'Esperando otra consulta';

  @override
  String radioAsk_asking(int attempt, int count) {
    return 'Preguntando… $attempt/$count';
  }

  @override
  String radioAsk_checkingAgain(int attempt, int count) {
    return 'Comprobando otra vez… $attempt/$count';
  }

  @override
  String radioAsk_checkAgainAt(String time) {
    return 'Comprobará otra vez a las $time';
  }

  @override
  String radioAsk_where(String name, String time) {
    return 'Radio de $name · $time';
  }

  @override
  String radioAsk_volts(String volts) {
    return '$volts V';
  }

  @override
  String get radioAsk_noPosition => 'Sin posición GPS';

  @override
  String get radioAsk_noFix => 'Puede ser antigua: sin señal GPS';

  @override
  String get radioAsk_unchanged => 'Puede ser antigua: sin cambios en 1 min';

  @override
  String get radioAsk_notChecked => 'Falló la segunda consulta';

  @override
  String get radioAsk_noAnswer => 'Sin respuesta';

  @override
  String get radioAsk_showOnMap => 'Ver en el mapa';

  @override
  String get radioAsk_askAgain => 'Preguntar otra vez';

  @override
  String get radioAsk_trackAsked =>
      'Also asked their phone for their track; it shows on the map.';

  @override
  String radioAsk_mapLabel(String name, String time) {
    return 'Radio de $name · $time';
  }

  @override
  String get radioAsk_rowLabel => 'Respuesta de la radio';

  @override
  String get contact_nickname => 'Apodo';

  @override
  String get contact_fullName => 'Nombre completo';

  @override
  String get contact_note => 'Nota';

  @override
  String get contact_nameAndNoteHint =>
      'Se guarda en este dispositivo y en las copias de seguridad de la radio. Nunca se envía.';

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
    return '¿Eliminar \"$name\" y todos sus mensajes? Esto no se puede deshacer.';
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
  String get channels_keepCapitals => 'Mantener mayúsculas';

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
  String get chat_selectText => 'Seleccionar texto';

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
  String get map_noNodesWithLocation => 'No hay nodos con datos de ubicación';

  @override
  String get map_nodesNeedGps =>
      'Solo aparecen en el mapa los nodos que comparten GPS';

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
  String get map_lastKnown => 'Última posición';

  @override
  String map_lastKnownAt(String time) {
    return 'Última posición · $time';
  }

  @override
  String get route_fromLastKnown =>
      'Desde tu última posición conocida, puede ser antigua';

  @override
  String route_fromLastKnownAt(String time) {
    return 'Desde tu última posición conocida ($time), puede ser antigua';
  }

  @override
  String route_fromWhereYouWere(String time) {
    return 'Desde donde estabas a las $time';
  }

  @override
  String route_startsOffPath(String distance) {
    return 'Empieza a $distance de tu punto de partida, fuera de todo camino cartografiado';
  }

  @override
  String get route_conditionsCaveat =>
      'MeshTrax no sabe de cierres, deslaves ni qué caminos necesitan 4x4. Consulta el estado actual antes de salir.';

  @override
  String route_dataDate(String date) {
    return 'Datos del mapa del $date';
  }

  @override
  String get gps_lastKnown => 'Tu última posición conocida, puede ser antigua';

  @override
  String gps_lastKnownAt(String time) {
    return 'Tu última posición conocida ($time), puede ser antigua';
  }

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
    return '¿Compartir una ubicación en $channelLabel? Es pública: cualquiera puede verla.';
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
  String get repeater_cliQuickRepeatOn => 'Repeat On';

  @override
  String get repeater_cliQuickRepeatOff => 'Repeat Off';

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
  String get repeater_cliHelpIntro =>
      'Tap a command to put it in the box, then replace the parts in curly brackets. Tap a get button to read that setting. These are the commands of firmware 1.18; older firmware may not have them all.';

  @override
  String get repeater_cliSectionRadio => 'Radio';

  @override
  String get repeater_cliSectionPower => 'Power';

  @override
  String get repeater_cliSectionRegions => 'Regions';

  @override
  String get repeater_cliSectionSensors => 'Sensors';

  @override
  String get repeater_cliSectionRoom => 'Room Server';

  @override
  String get repeater_cliHelpAdvertZeroHop =>
      'Sends an advert that only radios in direct range hear. Repeaters don\'t pass it on.';

  @override
  String get repeater_cliHelpClockSync =>
      'Sets the device\'s clock to your phone\'s time. The clock can only move forward.';

  @override
  String get repeater_cliHelpTime =>
      'Sets the clock to a Unix time in seconds. The clock can only move forward.';

  @override
  String get repeater_cliHelpBoard => 'Shows the board\'s maker and model.';

  @override
  String get repeater_cliHelpGetRole =>
      'Shows the firmware\'s role, such as repeater or room server.';

  @override
  String get repeater_cliHelpGetPublicKey => 'Shows the device\'s public key.';

  @override
  String get repeater_cliHelpClkReboot =>
      'Sets the clock back to May 2024 and reboots. Use it when the clock is ahead, then run clock sync.';

  @override
  String get repeater_cliHelpPowerOff =>
      'Turns the device off until its button is pressed or its power is cycled. shutdown does the same.';

  @override
  String get repeater_cliHelpStartOta =>
      'Starts a firmware update over the air, on boards that support it. The reply says how to connect.';

  @override
  String get repeater_cliHelpRoomPost =>
      'Posts a message in the room from the room server itself.';

  @override
  String get repeater_cliHelpGetFreq => 'Shows the radio frequency in MHz.';

  @override
  String get repeater_cliHelpSetTxPower =>
      'Sets the LoRa transmit power in dBm. It takes effect at once.';

  @override
  String get repeater_cliHelpSetDutyCycle =>
      'Sets the share of time the radio may spend sending, in percent. It\'s the air-time factor in other units.';

  @override
  String get repeater_cliHelpSetCad =>
      'Turns channel activity detection on or off: the radio listens for other LoRa signals before it sends.';

  @override
  String get repeater_cliHelpSetRxGain =>
      'Turns boosted receive gain on or off, on radios that have it.';

  @override
  String get repeater_cliHelpSetExtraSf =>
      'LR2021 radios only: also listens for up to three more spreading factors.';

  @override
  String get repeater_cliHelpSetOwnerInfo =>
      'Sets the owner details the device gives with its name and version when asked. Use | for a new line.';

  @override
  String get repeater_cliHelpSetFloodMaxUnscoped =>
      'Like flood.max, but for flood packets sent without a region.';

  @override
  String get repeater_cliHelpSetFloodMaxAdvert =>
      'Like flood.max, but for adverts. The default is 8.';

  @override
  String get repeater_cliHelpSetLoopDetect =>
      'Sets how strictly the repeater drops flood packets that go round in a loop. The default is minimal.';

  @override
  String get repeater_cliHelpSetPathHashMode =>
      'Sets how many bytes each hop adds to a packet\'s path: 0 for 1 byte, 1 for 2 bytes, 2 for 3 bytes.';

  @override
  String get repeater_cliHelpSetPrvKey =>
      'Replaces the device\'s identity with this private key. Reboot to apply. The old identity is lost unless you saved its key.';

  @override
  String get repeater_cliHelpPower =>
      'Shows the battery voltage, and whether USB, solar or other external power is connected.';

  @override
  String get repeater_cliHelpPowerSaving => 'Shows whether power saving is on.';

  @override
  String get repeater_cliHelpPowerSavingSet =>
      'Turns power saving on or off. nRF52 boards start saving at once, ESP32 boards after 2 minutes.';

  @override
  String get repeater_cliHelpGetPwrmgtSupport =>
      'Shows whether the board has power management.';

  @override
  String get repeater_cliHelpGetPwrmgtSource =>
      'Shows whether the device runs on external power or on its battery.';

  @override
  String get repeater_cliHelpGetPwrmgtBootReason =>
      'Shows why the device last started and why it last shut down.';

  @override
  String get repeater_cliHelpGetPwrmgtBootMv =>
      'Shows the battery voltage when the device last started.';

  @override
  String get repeater_cliHelpGetBootloaderVer =>
      'Shows the bootloader version, on nRF52 boards.';

  @override
  String get repeater_cliHelpDiscoverNeighbors =>
      'Asks nearby repeaters to answer, to fill the neighbors list.';

  @override
  String get repeater_cliHelpRegions =>
      'Lists the regions and which ones may flood (F).';

  @override
  String get repeater_cliHelpRegionDef =>
      'Adds regions in one command: each name goes under the one before it. Write name|parent to put the next name under that parent instead.';

  @override
  String get repeater_cliHelpRegionList =>
      'Lists the regions that may flood (allowed) or may not (denied).';

  @override
  String get repeater_cliHelpRegionDefault =>
      'Shows the default region: the one this device\'s own flood packets go out in.';

  @override
  String get repeater_cliHelpRegionDefaultSet =>
      'Sets the default region, or <null> for none. A new name is added as a region. Saved at once.';

  @override
  String get repeater_cliHelpGpsDiag =>
      'Shows GPS details for finding problems.';

  @override
  String get repeater_cliHelpSensorList =>
      'Lists the board\'s sensor settings. Add a number to start further down the list.';

  @override
  String get repeater_cliHelpSensorGet => 'Shows one sensor setting.';

  @override
  String get repeater_cliHelpSensorSet => 'Changes one sensor setting.';

  @override
  String get repeater_cliHelpSetBridgeChannel =>
      'Sets the Wi-Fi channel for ESP-NOW bridges.';

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
  String get channelPath_unknownPath => 'Desconocido';

  @override
  String get channelPath_floodPath => 'Inundación';

  @override
  String get channelPath_directPath => 'Guardar';

  @override
  String channelPath_pickedUpOnItsWay(String hops) {
    return 'Captado en camino, faltaba: $hops';
  }

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
  String get contacts_shareByAdvertFailed =>
      'La radio no pudo compartir este contacto. Primero tiene que oír su anuncio.';

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
  String get routing_noRoutePathfinder => 'ninguna aún';

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
  String get routing_forgetDonePathfinder => 'Ruta restablecida.';

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
  String get chat_channelNoSign => 'Enviado · sin señal de quién lo recibió';

  @override
  String chat_sentByItsClock(String time) {
    return 'enviado $time según el reloj del remitente';
  }

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
    return 'Recibido · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Recibido en el intento $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Recibido tarde · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Recibido · $secs s';
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
      'Tu radio recuerda una ruta hacia cada contacto. Cuando un mensaje por esa ruta falla, MeshTrax lo envía por inundación a toda la red mesh. Pathfinder escucha todo lo que oye la radio: anuncios de repetidores, conversaciones en los canales, mensajes de otras personas. Con todo eso construye un mapa de qué repetidores se oyen entre sí, cuáles te oyen a ti y cuáles oyen a cada uno de tus contactos.';

  @override
  String get pathfinderHelp_how =>
      'Cuando envías un mensaje, Pathfinder prueba primero su mejor ruta, luego la siguiente mejor, y solo usa la inundación como último recurso. Un icono de ruta ámbar marca un mensaje que salió por una ruta de Pathfinder.';

  @override
  String get pathfinderHelp_learning =>
      'Necesita tiempo. Un mapa recién creado no sabe nada, así que al principio tus mensajes usan la inundación hasta que aprende una ruta. Tras unas horas escuchando en un mismo lugar empieza a ofrecer rutas, y cada entrega o fallo le enseña algo más. El primer día no esperes mucho de él, y cada vez que te muevas a un sitio nuevo volverá a rendir menos.';

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
  String get settings_pathGraph => 'Pathfinder';

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
  String get appSettings_mapDownloadsWifiOnly => 'Descargar solo con Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Las descargas esperan al Wi‑Fi';

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
  String get offlineMaps_kindContoursDetail =>
      'Líneas de altitud, también usadas para la línea de visión';

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
  String get offlineMaps_notificationRunning => 'Descargando';

  @override
  String get offlineMaps_notificationPaused => 'Descarga en pausa';

  @override
  String get offlineMaps_notificationFailed => 'Error en la descarga';

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
  String get map_downloadForDetail =>
      'Descarga una región para ver más detalle';

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
      'Desactivado, ahorra batería. La posición GPS puede tardar unos minutos.';

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
      'El GPS de la radio está desactivado. La posición puede tardar unos minutos.';

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
  String get mapLayers_details => 'Detalles del mapa';

  @override
  String get mapLayers_contours => 'Curvas de nivel';

  @override
  String get mapLayers_hillShading => 'Sombreado del relieve';

  @override
  String get mapLayers_places => 'Lugares';

  @override
  String get mapLayers_parks => 'Parques';

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
  String get structured_repeaterStatus => 'Estado de repetidores';

  @override
  String get repeaterStatus_stateCritical => 'crítico';

  @override
  String get repeaterStatus_stateVeryLow => 'muy bajo';

  @override
  String get repeaterStatus_stateLow => 'bajo';

  @override
  String get repeaterStatus_stateOk => 'OK';

  @override
  String get repeaterStatus_waiting => 'esperando su anuncio';

  @override
  String get repeaterStatus_unreachable => 'inaccesible';

  @override
  String get repeaterStatus_noReading => 'sin lectura';

  @override
  String repeaterStatus_tx(String value) {
    return 'TX $value';
  }

  @override
  String get repeaterStatus_repeatOn => 'repetición activada';

  @override
  String get repeaterStatus_repeatOff => 'repetición desactivada';

  @override
  String repeaterStatus_minutes(int count) {
    return '$count min';
  }

  @override
  String repeaterStatus_hours(int count) {
    return '$count h';
  }

  @override
  String repeaterStatus_days(int count) {
    return '$count d';
  }

  @override
  String repeaterStatus_ago(String time) {
    return 'hace $time';
  }

  @override
  String repeaterStatus_nextPoll(String time) {
    return 'próxima consulta en $time';
  }

  @override
  String repeaterStatus_missed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count consultas perdidas',
      one: '$count consulta perdida',
    );
    return '$_temp0';
  }

  @override
  String repeaterStatus_was(String state) {
    return 'era $state';
  }

  @override
  String repeaterStatus_lastStage(String state) {
    return 'último nivel $state';
  }

  @override
  String repeaterStatus_for(String name) {
    return 'para $name';
  }

  @override
  String repeaterStatus_readingIgnored(String value) {
    return 'lectura $value descartada';
  }

  @override
  String repeaterStatus_page(int page, int pages) {
    return 'Página $page de $pages';
  }

  @override
  String get repeaterStatus_dryRun => 'Solo simulación';

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
  String get route_otherApp => 'Abrir en otra app';

  @override
  String get navigate_otherApp => 'Otra app';

  @override
  String get navigate_showDownload => 'Ver descarga';

  @override
  String get navigate_pickStart => 'Elegir inicio';

  @override
  String navigate_routingMissing(String region) {
    return 'Las rutas sin conexión de $region no están en este teléfono.';
  }

  @override
  String navigate_routingSize(String size) {
    return 'La descarga ocupa $size.';
  }

  @override
  String get navigate_noRoutingHere =>
      'Todavía no hay rutas sin conexión para esta zona.';

  @override
  String get navigate_noPosition =>
      'Sin posición GPS. Elige un inicio en el mapa o usa otra app.';

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
  String get structured_open => 'Abrir chat';

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
  String get location_sendPositionOnly => 'Only the position';

  @override
  String get location_sendWithMotion => 'Position, heading, speed and altitude';

  @override
  String get location_motionNotKnown => 'Heading and speed aren\'t known yet';

  @override
  String get add_title => 'Add contact or channel';

  @override
  String get add_box => 'Paste or type';

  @override
  String get add_boxHint =>
      'A meshcore:// link, <key:type:name>, #hashtag or a key';

  @override
  String get add_paste => 'Paste';

  @override
  String get add_clipboardEmpty => 'There\'s nothing to paste.';

  @override
  String get add_unreadableTitle => 'Nothing to add yet';

  @override
  String get add_unreadable =>
      'For a contact: a meshcore:// link, <key:type:name>, a contact card or a 64-character key. For a channel: a meshcore:// link, a #hashtag, or a 32-character secret key with its name.';

  @override
  String get add_contactName => 'Name (optional)';

  @override
  String get add_scanInstructions => 'Scan a contact or channel QR code';

  @override
  String get add_scanUnreadable =>
      'That QR code isn\'t a contact or a channel.';

  @override
  String get copy_link => 'Copy link';

  @override
  String get copy_asText => 'Copy as text';

  @override
  String get share_asText => 'As text';

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
  String get sos_alsoPublic => 'Enviar también a Public';

  @override
  String get sos_alsoPublicHint =>
      'Cualquiera al alcance puede leerlo con tu posición. Se envía una vez.';

  @override
  String get sos_askingRadio => 'Pidiendo a la radio su posición…';

  @override
  String sos_positionFrom(String time, String age) {
    return 'Posición de la radio de las $time ($age)';
  }

  @override
  String sos_positionNotNew(String time, String age) {
    return 'Sin posición nueva. Última conocida: $time ($age).';
  }

  @override
  String get sos_positionAgeUnknown =>
      'Última posición conocida, antigüedad desconocida.';

  @override
  String get sos_positionTyped =>
      'Tu propia posición: cada repetición la envía.';

  @override
  String get sos_repeats =>
      'Se repite cada 2 min con tu posición hasta que lo canceles; cada 5 min tras un «Recibido».';

  @override
  String get sos_publicOnce => 'En Public se envía una vez.';

  @override
  String get sos_traxOnly => 'Modo TRAX: solo lo oyen las radios TRAX.';

  @override
  String sos_replacesOther(String chat) {
    return 'Esto cancela tu SOS en $chat.';
  }

  @override
  String get sos_active => 'Tu SOS está activo';

  @override
  String sos_lastSent(String time) {
    return 'Último envío $time';
  }

  @override
  String get sos_waitingForRadio => 'Esperando a la radio para enviarlo';

  @override
  String sos_gotItBy(int count, String names) {
    return 'Recibido ($count): $names';
  }

  @override
  String get sos_noGotIt => 'Aún nadie dijo «Recibido»';

  @override
  String get sos_cancel => 'Cancelar SOS';

  @override
  String sos_cancelBody(String chat) {
    return 'Todos en $chat recibirán «SOS cancelled».';
  }

  @override
  String get sos_keep => 'Mantener SOS';

  @override
  String get sos_cancelPending =>
      'SOS cancelado. Se envía cuando la radio se conecte.';

  @override
  String sos_stopped(String time) {
    return 'El SOS se detuvo al cerrarse MeshTrax. Último envío $time.';
  }

  @override
  String get sos_sendAgain => 'Enviar de nuevo';

  @override
  String get sos_gotIt => 'Recibido';

  @override
  String sos_updated(String time) {
    return 'Actualizado $time';
  }

  @override
  String sos_cancelledAt(String time) {
    return 'Cancelado $time';
  }

  @override
  String sos_sentAt(String time) {
    return 'Enviado $time';
  }

  @override
  String sos_activeLastSent(String time) {
    return 'Tu SOS está activo · último envío $time';
  }

  @override
  String get sos_activeWaiting => 'Tu SOS está activo · esperando a la radio';

  @override
  String get sos_stoppedSendAgain => 'Tu SOS se detuvo · Enviar de nuevo';

  @override
  String get sos_cancelledWaiting => 'SOS cancelado · esperando a la radio';

  @override
  String get notification_sosChannel => 'Alertas SOS';

  @override
  String get notification_sosChannelDescription =>
      'Un SOS enviado a ti o a un chat en el que estás';

  @override
  String notification_sosFrom(String name) {
    return 'SOS de $name';
  }

  @override
  String notification_sosCancelledBy(String name) {
    return 'SOS cancelado por $name';
  }

  @override
  String get notification_mySosChannel => 'Tu SOS';

  @override
  String get notification_mySosChannelDescription =>
      'Tu propio SOS, mientras está activo';

  @override
  String get appSettings_sosAlerts => 'Alertas SOS';

  @override
  String get appSettings_sosAlways =>
      'Un SOS siempre avisa, incluso en un chat silenciado o con las notificaciones de mensajes desactivadas.';

  @override
  String get appSettings_sosThroughDnd =>
      'Suena aunque esté activado No molestar.';

  @override
  String get appSettings_sosSilencedByDnd =>
      'No molestar lo silencia. Toca y permite Ignorar No molestar.';

  @override
  String get appSettings_sosBlocked =>
      'El teléfono tiene las alertas SOS desactivadas. Toca para activarlas.';

  @override
  String get appSettings_sosApple =>
      'Los modos de concentración y el modo silencio aún pueden silenciarlo en este dispositivo.';

  @override
  String get appSettings_sosOff =>
      'Las notificaciones están desactivadas, así que las alertas SOS también.';

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
  String get paste_resolveFailed => 'No se pudo resolver el enlace';

  @override
  String get paste_shortLinkNoPosition =>
      'Este enlace corto no contiene ninguna posición. Ábrelo en tu app de mapas y copia las coordenadas.';

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
  String get roadLegend_title => 'Carreteras, senderos y líneas';

  @override
  String get roadLegend_freeway => 'Autopista';

  @override
  String get roadLegend_majorRoad => 'Carretera principal';

  @override
  String get roadLegend_road => 'Carretera';

  @override
  String get roadLegend_track => 'Camino de tierra o pista';

  @override
  String get roadLegend_trail => 'Sendero';

  @override
  String get roadLegend_walkway => 'Vía peatonal o ciclovía';

  @override
  String get roadLegend_interstate => 'Autopista interestatal';

  @override
  String get roadLegend_usRoute => 'Carretera federal de EE. UU.';

  @override
  String get roadLegend_stateRoute => 'Carretera estatal';

  @override
  String get roadLegend_railway => 'Ferrocarril';

  @override
  String get roadLegend_stream => 'Río o arroyo';

  @override
  String get roadLegend_contour => 'Curva de nivel';

  @override
  String get roadLegend_park => 'Límite de parque';

  @override
  String get roadLegend_wilderness => 'Área silvestre o bosque nacional';

  @override
  String get roadLegend_boundary => 'Límite estatal o de condado';

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
  String get chats_traxLabel => 'TRAX';

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
  String get route_pathPaved => 'Asfalto';

  @override
  String get route_pathDirt => 'Tierra';

  @override
  String get route_pathHiking => 'A pie';

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
    return 'Hacia $destination';
  }

  @override
  String get route_clear => 'Borrar itinerario';

  @override
  String get route_finding => 'Buscando un itinerario…';

  @override
  String get route_none => 'No se ha encontrado ningún itinerario';

  @override
  String route_endsShortPaved(String distance, String destination) {
    return 'Termina a $distance de $destination, donde se acaba el asfalto.';
  }

  @override
  String route_endsShortDirt(String distance, String destination) {
    return 'Termina a $distance de $destination, donde se acaba el camino.';
  }

  @override
  String route_endsShortHiking(String distance, String destination) {
    return 'Termina a $distance de $destination, donde se acaban los senderos.';
  }

  @override
  String get route_directions => 'Indicaciones';

  @override
  String get route_here => 'Itinerario hasta aquí';

  @override
  String route_destinationNow(String destination) {
    return 'Destino actual: $destination';
  }

  @override
  String route_startNow(String start) {
    return 'Origen actual: $start';
  }

  @override
  String get route_startNowYou => 'Origen actual: tu posición';

  @override
  String route_from(String start) {
    return 'Desde $start';
  }

  @override
  String get route_fromYou => 'Desde tu posición';

  @override
  String get route_useMyPosition => 'Usar mi posición';

  @override
  String get route_noHeights => 'No hay datos de altitud para esta zona.';

  @override
  String get route_noHeightsHiking =>
      'No hay datos de altitud para esta zona, así que el tiempo no tiene en cuenta las subidas.';

  @override
  String get route_options => 'Opciones de itinerario';

  @override
  String get route_optionsReset => 'Restablecer';

  @override
  String get route_prefer => 'Preferir';

  @override
  String get route_dirtFastest => 'Más rápido';

  @override
  String get route_dirtBalanced => 'Equilibrado';

  @override
  String get route_dirtDirect => 'Más directo';

  @override
  String get route_dirtFastestHelp =>
      'Caminos de tierra solo donde sean más rápidos.';

  @override
  String get route_dirtBalancedHelp =>
      'Un camino de tierra cuando ahorra bastante distancia.';

  @override
  String get route_dirtDirectHelp =>
      'El trayecto más corto, por lentas que sean sus pistas.';

  @override
  String get route_avoid => 'Evitar';

  @override
  String get route_avoidHighways => 'Autopistas';

  @override
  String get route_avoidTolls => 'Peajes';

  @override
  String get route_avoidFerries => 'Ferris';

  @override
  String get route_hardestTrail => 'Dificultad máxima';

  @override
  String get route_trailT1 => 'T1 Senderismo';

  @override
  String get route_trailT2 => 'T2 Senderismo de montaña';

  @override
  String get route_trailT3 => 'T3 Senderismo de montaña exigente';

  @override
  String get route_trailT4 => 'T4 Senderismo alpino';

  @override
  String get route_trailT5 => 'T5 Senderismo alpino exigente';

  @override
  String get route_trailT6 => 'T6 Senderismo alpino difícil';

  @override
  String get route_climbs => 'Subidas';

  @override
  String get route_climbsAvoid => 'Evitar';

  @override
  String get route_climbsSome => 'Algunas';

  @override
  String get route_climbsAny => 'Me da igual';

  @override
  String get route_pace => 'Ritmo';

  @override
  String get route_paceSlow => 'Lento';

  @override
  String get route_paceNormal => 'Medio';

  @override
  String get route_paceFast => 'Rápido';

  @override
  String get place_nrhp => 'Registro Nacional de Lugares Históricos';

  @override
  String get place_textCredit => 'Texto: Wikipedia, CC BY-SA 4.0';

  @override
  String get place_readOnWikipedia => 'Leer en Wikipedia';

  @override
  String place_photoCredit(String author, String licence) {
    return 'Foto: $author, $licence';
  }

  @override
  String get search_hint => 'Buscar lugares, direcciones o coordenadas';

  @override
  String get search_noPlaces =>
      'Descarga Puntos de interés para buscar lugares. Las coordenadas funcionan sin ello.';

  @override
  String get search_noResults => 'Sin resultados';

  @override
  String search_near(String name) {
    return 'cerca de $name';
  }

  @override
  String get coordFormat_decimalDegrees => 'Grados decimales';

  @override
  String get coordFormat_degreesMinutes => 'Grados y minutos';

  @override
  String get coordFormat_dms => 'Grados, minutos y segundos';

  @override
  String get coordFormat_utm => 'UTM';

  @override
  String get coordFormat_mgrs => 'MGRS / USNG';

  @override
  String get coordFormat_maidenhead => 'Cuadrícula Maidenhead';

  @override
  String get coordFormat_geohash => 'Geohash';

  @override
  String get poiKind_peak => 'Pico';

  @override
  String get poiKind_volcano => 'Volcán';

  @override
  String get poiKind_saddle => 'Collado';

  @override
  String get poiKind_pass => 'Puerto de montaña';

  @override
  String get poiKind_spring => 'Manantial';

  @override
  String get poiKind_hotSpring => 'Fuente termal';

  @override
  String get poiKind_waterfall => 'Cascada';

  @override
  String get poiKind_cave => 'Cueva';

  @override
  String get poiKind_arch => 'Arco natural';

  @override
  String get poiKind_glacier => 'Glaciar';

  @override
  String get poiKind_rock => 'Roca';

  @override
  String get poiKind_cliff => 'Acantilado';

  @override
  String get poiKind_beach => 'Playa';

  @override
  String get poiKind_trailhead => 'Inicio de sendero';

  @override
  String get poiKind_campground => 'Zona de acampada';

  @override
  String get poiKind_picnicSite => 'Zona de pícnic';

  @override
  String get poiKind_hut => 'Refugio de montaña';

  @override
  String get poiKind_shelter => 'Refugio';

  @override
  String get poiKind_drinkingWater => 'Agua potable';

  @override
  String get poiCaveat_spring => 'Puede estar seco o no ser seguro';

  @override
  String get poiCaveat_drinkingWater => 'Puede estar cerrada';

  @override
  String get poiKind_toilets => 'Aseos';

  @override
  String get poiKind_viewpoint => 'Mirador';

  @override
  String get poiKind_attraction => 'Atracción turística';

  @override
  String get poiKind_observatory => 'Observatorio';

  @override
  String get poiKind_zoo => 'Zoológico';

  @override
  String get poiKind_themePark => 'Parque temático';

  @override
  String get poiKind_mine => 'Mina';

  @override
  String get poiKind_mineShaft => 'Pozo minero';

  @override
  String get poiKind_adit => 'Bocamina';

  @override
  String get poiKind_ghostTown => 'Pueblo fantasma';

  @override
  String get poiKind_ruins => 'Ruinas';

  @override
  String get poiKind_monument => 'Monumento';

  @override
  String get poiKind_memorial => 'Monumento conmemorativo';

  @override
  String get poiKind_fort => 'Fortaleza';

  @override
  String get poiKind_historic => 'Lugar histórico';

  @override
  String get poiKind_rangerStation => 'Puesto de guardabosques';

  @override
  String get poiKind_visitorCenter => 'Centro de visitantes';

  @override
  String get poiKind_hospital => 'Hospital';

  @override
  String get poiKind_police => 'Policía';

  @override
  String get poiKind_fireStation => 'Parque de bomberos';

  @override
  String get poiKind_emergencyPhone => 'Teléfono de emergencia';

  @override
  String get poiKind_fuel => 'Gasolinera';

  @override
  String get poiKind_restArea => 'Área de descanso';

  @override
  String get poiKind_travelCenter => 'Área de servicio';

  @override
  String get poiKind_museum => 'Museo';

  @override
  String get poiKind_city => 'Ciudad';

  @override
  String get poiKind_town => 'Pueblo';

  @override
  String get poiKind_locality => 'Zona';

  @override
  String get poiKind_lake => 'Lago';

  @override
  String get poiKind_river => 'Río';

  @override
  String get poiKind_valley => 'Valle';

  @override
  String get poiKind_range => 'Sierra';

  @override
  String get poiKind_trail => 'Sendero';

  @override
  String get poiKind_dirtRoad => 'Camino de tierra';

  @override
  String get poiKind_road => 'Carretera';

  @override
  String get poiKind_address => 'Dirección';

  @override
  String get poiKind_place => 'Lugar';

  @override
  String get offlineMaps_kindRouting => 'Itinerarios por senderos';

  @override
  String get offlineMaps_kindRoutingDetail =>
      'Itinerarios por senderos, caminos de tierra y carreteras asfaltadas';

  @override
  String get offlineMaps_kindPoi => 'Puntos de interés';

  @override
  String get offlineMaps_kindPoiDetail => 'Lugares para buscar, con Wikipedia';

  @override
  String get offlineMaps_kindAddresses => 'Direcciones';

  @override
  String get offlineMaps_kindAddressesDetail =>
      'Direcciones postales para buscar';

  @override
  String get offlineMaps_useDrive => 'Usar una unidad';

  @override
  String offlineMaps_onDrive(String name, String date) {
    return 'Mapas de la unidad $name, del $date';
  }

  @override
  String get offlineMaps_backToInternet => 'Volver a internet';

  @override
  String get offlineMaps_keepOpen =>
      'Instalando desde la unidad. Mantén MeshTrax abierto.';

  @override
  String get offlineMaps_driveRemoved =>
      'Se quitó la unidad. Se muestran de nuevo los mapas de internet.';

  @override
  String get offlineMaps_readingDrive => 'Leyendo la unidad…';

  @override
  String get offlineMaps_noMapsOnDrive =>
      'Ahí no hay mapas de MeshTrax. Elige la carpeta MeshTrax-maps de la unidad.';

  @override
  String offlineMaps_driveError(String error) {
    return 'No se pudo leer la unidad: $error';
  }

  @override
  String get offlineMaps_stopDriveTitle =>
      '¿Dejar de instalar desde la unidad?';

  @override
  String get offlineMaps_stopDriveBody =>
      'Lo que ya está instalado se queda en este dispositivo.';

  @override
  String get offlineMaps_stopDrive => 'Detener';

  @override
  String get offlineMaps_keepInstalling => 'Seguir instalando';

  @override
  String offlineMaps_install(String size) {
    return 'Instalar $size';
  }

  @override
  String get offlineMaps_installTotal => 'Instalar';

  @override
  String get offlineMaps_routingDriveOlder =>
      'Este dispositivo tiene datos de itinerarios más recientes que la unidad.';

  @override
  String get offlineMaps_routingDriveIncomplete =>
      'Los datos de itinerarios de la unidad no cubren todas las regiones de este dispositivo.';

  @override
  String get offlineMaps_kindWaterRouting => 'Water routing';

  @override
  String get offlineMaps_kindWaterRoutingDetail => 'Routes on the water';

  @override
  String get offlineMaps_waterRoutingWithChart =>
      'Routes on the water. Its chart comes too.';

  @override
  String get offlineMaps_waterRoutingUpdatesChart =>
      'Routes on the water. Its chart updates too.';

  @override
  String get offlineMaps_waterRoutingRebuilding =>
      'Being rebuilt for new charts';

  @override
  String get map_search => 'Buscar';

  @override
  String get map_fullScreen => 'Pantalla completa';

  @override
  String get map_leaveFullScreen => 'Salir de pantalla completa';

  @override
  String get map_fullScreenHintBack =>
      'Para salir de pantalla completa, pulsa Atrás o toca el mismo botón.';

  @override
  String get map_fullScreenHintTap =>
      'Para salir de pantalla completa, toca el mismo botón.';

  @override
  String get map_fullScreenHintKey =>
      'Para salir de pantalla completa, pulsa Esc o haz clic en el mismo botón.';

  @override
  String get route_fromHere => 'Itinerario desde aquí';

  @override
  String get route_startSet =>
      'Origen del itinerario fijado. Ahora elige adónde ir.';

  @override
  String get route_noStart =>
      'No hay posición de origen. Mantén pulsado el mapa y elige Itinerario desde aquí.';

  @override
  String get route_noData =>
      'Descarga Itinerarios por senderos de esta región en Mapas sin conexión.';

  @override
  String get route_pin => 'Marcador colocado';

  @override
  String get water_yourBoat => 'Your boat';

  @override
  String get water_yourBoatIntro =>
      'Every trip on the water keeps to these. Change them later in Route options.';

  @override
  String water_boatDraft(String draft, String keel) {
    return '$draft draft + $keel';
  }

  @override
  String water_boatOffLand(String distance) {
    return '$distance off land';
  }

  @override
  String water_boatMast(String height) {
    return '$height mast';
  }

  @override
  String get water_classRestricted => 'Restricted area';

  @override
  String get water_classCaution => 'Caution area';

  @override
  String get water_classMilitary => 'Military area';

  @override
  String get water_classAnchorage => 'Anchorage';

  @override
  String get water_classDumping => 'Dumping ground';

  @override
  String get water_classTrafficLane => 'Traffic lane';

  @override
  String get water_classSeparation => 'Separation zone';

  @override
  String get water_classPrecautionary => 'Precautionary area';

  @override
  String get water_classInshoreTraffic => 'Inshore traffic zone';

  @override
  String get water_classMarineFarm => 'Marine farm';

  @override
  String get water_classBridge => 'Bridge';

  @override
  String get water_classCable => 'Overhead cable';

  @override
  String get water_classPipe => 'Overhead pipe';

  @override
  String get water_classConveyor => 'Conveyor';

  @override
  String get water_classGate => 'Gate';

  @override
  String get water_movedLand => 'that point is on land or off the charts';

  @override
  String get water_movedShallow => 'it\'s too shallow there';

  @override
  String get water_movedHazard =>
      'it\'s near a hazard too shallow for the boat';

  @override
  String get water_movedNoEntry => 'entry is prohibited there';

  @override
  String get water_movedMast => 'something there is lower than the mast';

  @override
  String water_startMoved(String distance, String why) {
    return 'Starts $distance from the point picked: $why.';
  }

  @override
  String water_endMoved(String distance, String why) {
    return 'Ends $distance from the point picked: $why.';
  }

  @override
  String water_endsShortDepth(
    String distance,
    String destination,
    String band,
    String draft,
  ) {
    return 'Ends $distance before $destination: charted $band. Drafts to $draft get through.';
  }

  @override
  String water_endsShortTooShallow(
    String distance,
    String destination,
    String band,
  ) {
    return 'Ends $distance before $destination: charted $band, too shallow to get through.';
  }

  @override
  String water_endsShortMast(
    String distance,
    String destination,
    String objects,
  ) {
    return 'Ends $distance before $destination: $objects too low for the mast.';
  }

  @override
  String water_endsShortNoWater(String distance, String destination) {
    return 'Ends $distance before $destination: no charted water joins them.';
  }

  @override
  String water_endsShortTooLong(String distance, String destination) {
    return 'Ends $distance before $destination: too long for one route. Plan it in parts.';
  }

  @override
  String water_leastDepth(String depth) {
    return 'Least depth: charted $depth';
  }

  @override
  String water_lowestClearance(String height) {
    return 'Lowest clearance $height';
  }

  @override
  String water_lowestClearanceUnder(String height, String name) {
    return 'Lowest clearance $height, $name';
  }

  @override
  String water_shallower(String depth) {
    return 'Shallower than $depth';
  }

  @override
  String get water_poorSurvey => 'Poorly surveyed';

  @override
  String get water_needsOpening => 'needs opening';

  @override
  String get water_magneticModelOld =>
      'Bearings from a magnetic model valid to 2030';

  @override
  String water_couldntKeep(String distance) {
    return 'Closer than $distance to land';
  }

  @override
  String get water_onTheWay => 'On the way';

  @override
  String water_stretch(String length, String from) {
    return '$length, from $from along';
  }

  @override
  String get water_speed => 'Speed';

  @override
  String get water_draft => 'Draft';

  @override
  String get water_underKeel => 'Room under the keel';

  @override
  String get water_preferDepth => 'Preferred depth';

  @override
  String get water_none => 'None';

  @override
  String get water_mastHeight => 'Mast height';

  @override
  String get water_offLand => 'Distance off land';

  @override
  String get water_avoidLanes => 'Traffic lanes';

  @override
  String get water_avoidSecurity => 'Security zones';

  @override
  String get water_avoidOpening => 'Bridges that open';

  @override
  String get water_notForNavigation => 'Not for navigation';

  @override
  String get water_noData =>
      'Download Water routing for this chart area in Offline maps.';

  @override
  String water_routingMissing(String area) {
    return 'Water routing for $area isn\'t on this phone.';
  }

  @override
  String get route_onLand => 'Route on land';

  @override
  String get route_onWater => 'Route on the water';

  @override
  String get water_noTiles => 'No water routing here';

  @override
  String get water_mixedBuilds =>
      'Update water routing in Offline maps: its areas are of different builds.';

  @override
  String get water_noWater => 'No water here the boat can use';

  @override
  String water_unchartedSpans(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Under $count spans with no charted clearance',
      one: 'Under 1 span with no charted clearance',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_coordinateFormat => 'Formato de coordenadas';

  @override
  String get map_copyPosition => 'Copiar posición';

  @override
  String get poiKind_park => 'Parque';

  @override
  String get poiKind_protectedArea => 'Área protegida';

  @override
  String get common_more => 'Más';

  @override
  String get common_less => 'Menos';

  @override
  String get locationSharing_title => 'Quién puede ver mi ubicación';

  @override
  String get locationSharing_someone => 'Alguien puede ver tu ubicación';

  @override
  String get locationSharing_nobody => 'Nadie puede ver tu ubicación';

  @override
  String get locationSharing_noPosition =>
      'Tu radio aún no tiene ubicación, así que nadie puede verla';

  @override
  String get locationSharing_everyone =>
      'Cualquiera que oiga tu radio puede ver tu ubicación';

  @override
  String get locationSharing_allContacts =>
      'Todos tus contactos pueden ver tu ubicación';

  @override
  String get locationSharing_someContacts =>
      'Los contactos que permitiste pueden ver tu ubicación';

  @override
  String get locationSharing_adverts => 'Ubicación en los anuncios';

  @override
  String get locationSharing_advertsHint =>
      'Tus anuncios llevan tu ubicación, así que cualquiera que oiga tu radio la ve.';

  @override
  String get locationSharing_contactsHeader =>
      'Contactos que pueden consultar tu radio';

  @override
  String get locationSharing_noTelemetry =>
      'Ninguno. Tu radio no responde a solicitudes de telemetría.';

  @override
  String get locationSharing_noContacts => 'Ningún contacto tiene permiso.';

  @override
  String locationSharing_allContactsRow(int count) {
    return 'Todos tus contactos ($count)';
  }

  @override
  String get locationSharing_partLocation => 'Ubicación';

  @override
  String get locationSharing_partBattery => 'Batería';

  @override
  String get locationSharing_partSensors => 'Sensores';

  @override
  String get dialog_positionHint => 'Pega coordenadas o un enlace de mapas';

  @override
  String get dialog_positionUnreadable => 'No se puede leer una posición aquí';

  @override
  String get locationSharing_share => 'Compartir mi ubicación';

  @override
  String get locationSharing_shareOnHint =>
      'Desactívalo para ocultarla a todos';

  @override
  String get locationSharing_shareOffHint =>
      'Actívalo para que la vean los contactos con permiso';

  @override
  String get chats_advertise => 'Anunciar';

  @override
  String get tray_drawing => 'Dibujo';

  @override
  String get drawing_tabDraw => 'Dibujar';

  @override
  String get drawing_tabPaste => 'Pegar';

  @override
  String get drawing_toolPen => 'Lápiz';

  @override
  String get drawing_toolLine => 'Línea';

  @override
  String get drawing_toolRect => 'Rectángulo';

  @override
  String get drawing_toolCircle => 'Círculo';

  @override
  String get drawing_toolEllipse => 'Elipse';

  @override
  String get drawing_toolArrow => 'Flecha';

  @override
  String get drawing_undo => 'Deshacer';

  @override
  String get drawing_caption => 'Pie de imagen';

  @override
  String get drawing_captionHint => 'Opcional, se muestra debajo del dibujo';

  @override
  String drawing_bytes(int used, int max) {
    return '$used de $max bytes';
  }

  @override
  String drawing_points(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count puntos',
      one: '1 punto',
    );
    return '$_temp0';
  }

  @override
  String get drawing_keptAll => 'Se conservan todos los puntos que dibujaste.';

  @override
  String drawing_simplified(String percent) {
    return 'Simplificado: las líneas se desvían como mucho un $percent% del tamaño del dibujo.';
  }

  @override
  String get drawing_tooDetailed =>
      'Demasiado detallado para un solo mensaje, incluso simplificado. Deshaz un trazo o usa formas, que ocupan mucho menos.';

  @override
  String get drawing_empty => 'Dibuja con el dedo o elige una forma.';

  @override
  String get drawing_pasteHint =>
      'Pega un archivo SVG o datos de trazado como M10 10h80v80H10z';

  @override
  String get drawing_pasteUse => 'Usar este SVG';

  @override
  String get drawing_pasteNote =>
      'Los colores y rellenos no se envían: llega como líneas, en el color de lápiz de quien lo recibe.';

  @override
  String get drawing_pasteEmpty =>
      'Primero pega código SVG o datos de trazado.';

  @override
  String get drawing_pasteTooBig =>
      'Es demasiado grande o detallado para leerlo. Pega un SVG más pequeño.';

  @override
  String get drawing_pasteUnreadable => 'No es un SVG que la app pueda leer.';

  @override
  String get drawing_pasteNothing =>
      'Ese SVG no tiene nada visible que dibujar.';

  @override
  String get drawing_copySvg => 'Copiar SVG';

  @override
  String get appSettings_drawings => 'Dibujos';

  @override
  String get appSettings_drawingsSubtitle =>
      'Imágenes enviadas como SVG y cómo se ven aquí';

  @override
  String get drawingSettings_show => 'Mostrar dibujos';

  @override
  String get drawingSettings_showSubtitle =>
      'Desactivado, se muestra el código SVG en su lugar';

  @override
  String get drawingSettings_penColor => 'Color del lápiz';

  @override
  String get drawingSettings_colorCode => 'Código de color';

  @override
  String get drawingSettings_lineWidth => 'Grosor de línea';

  @override
  String get drawingSettings_glow => 'Resplandor';

  @override
  String get drawingSettings_scanlines => 'Líneas de barrido';

  @override
  String get drawing_toolRoute => 'Itinerario';

  @override
  String get drawing_toolX => 'Marca en X';

  @override
  String get drawing_routeHint =>
      'Toca para añadir puntos. Toca otra vez el último para terminar.';

  @override
  String get drawing_mapNone => 'Sin mapa';

  @override
  String get drawing_mapUsgs => 'USGS';

  @override
  String get drawing_drawHere => 'Dibujar aquí';

  @override
  String get drawing_moveMap => 'Mover el mapa';

  @override
  String get drawing_mapHint =>
      'Mueve el mapa y usa el zoom hasta encontrar el lugar; luego toca Dibujar aquí.';

  @override
  String drawing_mapAcross(String map, String distance) {
    return '$map, $distance de ancho';
  }

  @override
  String get drawing_mapNotDownloaded => 'Esta zona no está descargada';

  @override
  String get listFilter_hopsAway => 'Saltos de distancia';

  @override
  String get listFilter_lastHeard => 'Última vez oído';

  @override
  String get listFilter_heardAnyTime => 'Cualquier momento';

  @override
  String get listFilter_heardHour => 'Última hora';

  @override
  String get listFilter_heardTwoDays => 'Últimas 48 horas';

  @override
  String get listFilter_heardWeek => 'Últimos 7 días';

  @override
  String settings_radioFirmware(String version) {
    return 'Firmware de la radio $version';
  }

  @override
  String get settings_locationTapMap =>
      'Toca el mapa para fijar la posición o escribe los números.';

  @override
  String get channels_pasteLink => 'Pegar un enlace';

  @override
  String get channels_pasteLinkDesc =>
      'Un enlace de canal meshcore:// que copiaste.';

  @override
  String get channels_pasteLinkNone =>
      'No hay ningún enlace de canal en el portapapeles.';

  @override
  String get settings_locationGpsNote =>
      'Con el GPS encendido, la radio sustituye esta posición en cuanto su GPS tiene señal.';

  @override
  String contacts_hopsAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saltos',
      one: '1 salto',
      zero: 'Directo',
    );
    return '$_temp0';
  }

  @override
  String get los_lineOfSight => 'Línea de visión';

  @override
  String get los_reachFromMe => 'Alcance de radio desde mi posición';

  @override
  String get los_lineFromMe => 'Línea de visión desde mi posición';

  @override
  String get los_reachFromHere => 'Alcance de radio desde aquí';

  @override
  String los_reachFrom(String name) {
    return 'Alcance de radio desde $name';
  }

  @override
  String get los_clear => 'Despejado';

  @override
  String get los_marginal => 'Al límite';

  @override
  String get los_blocked => 'Bloqueado';

  @override
  String get los_cantTell => 'No se sabe';

  @override
  String get los_checking => 'Comprobando…';

  @override
  String get los_failed => 'No se pudo calcular la línea de visión aquí.';

  @override
  String get los_pickTarget => 'Toca una persona o un lugar en el mapa.';

  @override
  String get los_noPosition =>
      'Aún no se conoce tu posición. Toca el mapa para empezar desde ahí.';

  @override
  String get los_nothingInWay => 'Nada en medio.';

  @override
  String los_groundAbove(String distance, String height) {
    return 'El terreno a $distance de ti queda $height por encima de la línea.';
  }

  @override
  String los_groundAboveStart(String distance, String height) {
    return 'El terreno a $distance del inicio queda $height por encima de la línea.';
  }

  @override
  String los_groundWithin(String distance, String height) {
    return 'El terreno a $distance de ti llega a $height de la línea.';
  }

  @override
  String los_groundWithinStart(String distance, String height) {
    return 'El terreno a $distance del inicio llega a $height de la línea.';
  }

  @override
  String get los_higherHelps =>
      'Un punto más alto o una antena más alta ayuda.';

  @override
  String los_noContours(String length) {
    return 'No hay curvas de nivel para $length de esta línea.';
  }

  @override
  String los_noContoursIn(String length, String regions) {
    return 'No hay curvas de nivel para $length de esta línea ($regions).';
  }

  @override
  String get los_noContoursArea =>
      'No hay curvas de nivel para parte de esta zona.';

  @override
  String los_noContoursAreaIn(String regions) {
    return 'No hay curvas de nivel para parte de esta zona ($regions).';
  }

  @override
  String get los_noHeightData => 'Aún no hay datos de altura para esta zona.';

  @override
  String los_downloadContours(String regions, String size) {
    return 'Descargar curvas de nivel de $regions ($size)';
  }

  @override
  String get los_downloadBeforeTrip =>
      'Descarga aquí las curvas de nivel antes de salir (requiere internet).';

  @override
  String get los_spotBelowLowest =>
      'Bajo el nivel del mar: altura desconocida.';

  @override
  String los_nameBelowLowest(String name) {
    return '$name está bajo el nivel del mar: altura desconocida.';
  }

  @override
  String get los_youBelowLowest =>
      'Estás bajo el nivel del mar: altura desconocida. Con el GPS encendido, se usa la altitud de la radio.';

  @override
  String get los_noLinesNear =>
      'Sin curvas de nivel cerca de este extremo: altura desconocida.';

  @override
  String get los_from => 'De';

  @override
  String get los_to => 'A';

  @override
  String get los_thisRadio => 'Esta radio';

  @override
  String get los_me => 'Yo';

  @override
  String los_meAgo(String age) {
    return 'Yo, $age';
  }

  @override
  String get los_meByHand => 'Yo, posición fijada a mano';

  @override
  String get los_meNotYetGps => 'Yo, posición aún sin actualizar por GPS';

  @override
  String los_nameAgo(String name, String age) {
    return '$name, $age';
  }

  @override
  String get los_antenna => 'Antena';

  @override
  String get los_handHeld => 'De mano';

  @override
  String get los_vehicle => 'Vehículo';

  @override
  String get los_raised => 'Elevada';

  @override
  String get los_raisedTitle => 'Antena elevada';

  @override
  String get los_raisedLabel => 'Altura sobre el suelo';

  @override
  String get los_terrainOnly => 'Solo terreno, según tus curvas de nivel.';

  @override
  String los_credits(String credits) {
    return 'Alturas: $credits';
  }

  @override
  String get los_aboutTitle => 'Acerca de la línea de visión';

  @override
  String get los_helpBody =>
      'La respuesta sale solo del terreno, leído de las curvas de nivel que descargaste. No sabe nada de árboles, edificios, personas, tendidos eléctricos ni otras antenas, y una cima puede ser hasta una curva de nivel más alta de lo dibujado.\n\n«Despejado» significa que el terreno no se interpone. No garantiza que un mensaje llegue. «Al límite» significa que el terreno se acerca a la línea. «Bloqueado» significa que el terreno se interpone: un mensaje aún puede pasar por encima de una loma baja, pero no cuentes con ello.\n\nPruébalo en el campo con tus propias radios antes de fiarte de ello.';

  @override
  String los_reachShaded(String distance) {
    return 'Sombreado: el terreno no bloquea una radio de mano, hasta $distance.';
  }

  @override
  String get los_reachUnknownPart =>
      'Parte del terreno no se puede calcular (bajo el nivel del mar), así que no se sombrea.';

  @override
  String get los_reachTapHint =>
      'Toca el mapa o un nombre para ver la línea de visión hasta allí.';

  @override
  String get los_positionGuessed => 'Ubicación estimada';

  @override
  String los_positionGuessedVia(String names) {
    return 'Ubicación estimada (vía $names)';
  }

  @override
  String los_lookFurther(String distance) {
    return 'Ver más lejos ($distance)';
  }

  @override
  String los_nobodyWithin(String distance) {
    return 'Nadie con posición a menos de $distance.';
  }

  @override
  String get offlineMaps_losContours =>
      'Curvas de nivel para la línea de visión';

  @override
  String get contacts_deleteComesBack =>
      'Tu radio guarda este tipo de contacto por sí sola, así que volverá la próxima vez que se oiga.';

  @override
  String get tray_contact => 'Contacto';

  @override
  String get shareContact_title => 'Compartir un contacto';

  @override
  String get shareContact_myContact => 'Mi contacto';

  @override
  String get regions_title => 'Regiones';

  @override
  String get regions_settingsSubtitle =>
      'Mantener los mensajes de un canal en una zona';

  @override
  String get regions_intro =>
      'Una región mantiene los mensajes de un canal en los repetidores que cubren una zona. Un repetidor que no conoce la región no pasa el mensaje, así que usa los nombres que usan los repetidores de tu zona.';

  @override
  String get regions_yourRegions => 'Tus regiones';

  @override
  String get regions_empty =>
      'Aún no hay regiones. Añade el nombre que usan los repetidores de tu zona.';

  @override
  String get regions_add => 'Añadir región';

  @override
  String get regions_nameLabel => 'Nombre de la región';

  @override
  String get regions_nameHelp =>
      'Las mayúsculas cuentan: SF y sf son dos regiones distintas.';

  @override
  String get regions_nameBadCharacter =>
      'No se permiten espacios, puntos, comas ni la mayoría de los signos.';

  @override
  String get regions_nameTooLong => 'Demasiado largo: 30 bytes como máximo.';

  @override
  String get regions_nameExists => 'Ya está en tu lista.';

  @override
  String regions_usedBy(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'La usan $count canales',
      one: 'La usa 1 canal',
      zero: 'Ningún canal la usa',
    );
    return '$_temp0';
  }

  @override
  String regions_deleteTitle(String name) {
    return '¿Eliminar $name?';
  }

  @override
  String regions_deleteInUse(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count canales usan esta región. Se quedan sin región.',
      one: '1 canal usa esta región. Se queda sin región.',
    );
    return '$_temp0';
  }

  @override
  String get regions_radioDefault => 'Región predeterminada de la radio';

  @override
  String get regions_radioDefaultHelp =>
      'Guardada en la radio. La usan los canales sin región propia, los mensajes directos y los anuncios, desde cualquier app.';

  @override
  String get regions_none => 'Ninguna';

  @override
  String get regions_radioNoAnswer =>
      'La radio no aceptó el cambio. Inténtalo de nuevo.';

  @override
  String get regions_inQr => 'Región en los códigos QR de canal';

  @override
  String get regions_inQrSubtitle =>
      'Si está activado, el código QR de un canal lleva su región, y al escanear un código se pone la región que lleva.';

  @override
  String get regions_unsupported =>
      'El firmware de esta radio es demasiado antiguo para las regiones.';

  @override
  String get channelRegion_title => 'Región';

  @override
  String channelRegion_noneWithDefault(String name) {
    return 'Ninguna (predeterminada de la radio: $name)';
  }

  @override
  String get channelRegion_everywhere => 'En todas partes (sin región)';

  @override
  String get channelRegion_help =>
      'Los mensajes de este canal solo pasan por repetidores que conocen su región.';

  @override
  String get channelRegion_manage => 'Gestionar regiones';

  @override
  String channelRegion_qrLine(String name) {
    return 'Región: $name';
  }

  @override
  String get repeaterRegions_subtitle => 'Qué regiones pasa este repetidor';

  @override
  String get repeaterRegions_reading => 'Leyendo las regiones del repetidor…';

  @override
  String get repeaterRegions_tooOld =>
      'El firmware de este repetidor es demasiado antiguo para gestionar sus regiones aquí. Necesita 1.15 o posterior.';

  @override
  String get repeaterRegions_noAnswer =>
      'El repetidor no respondió. Inténtalo de nuevo.';

  @override
  String get repeaterRegions_noRegion => 'Repetir mensajes sin región';

  @override
  String get repeaterRegions_noRegionHelp =>
      'La mayoría envía sin región. Si lo desactivas, este repetidor deja de pasar sus mensajes.';

  @override
  String get repeaterRegions_noRegionOffTitle =>
      '¿Dejar de repetir mensajes sin región?';

  @override
  String get repeaterRegions_noRegionOffBody =>
      'Nadie cercano que no use una región será repetido por este repetidor.';

  @override
  String get repeaterRegions_turnOff => 'Desactivar';

  @override
  String get repeaterRegions_own => 'Región propia del repetidor';

  @override
  String get repeaterRegions_ownHelp =>
      'La usan sus anuncios, y también sus respuestas cuando no sabe en qué región llegó una petición.';

  @override
  String get repeaterRegions_onRepeater => 'Regiones en este repetidor';

  @override
  String get repeaterRegions_empty =>
      'Aún no hay regiones. Un mensaje con región solo se repite aquí cuando se añade su región.';

  @override
  String get repeaterRegions_mayBeIncomplete =>
      'La lista del repetidor es larga y su respuesta se cortó, así que pueden faltar regiones aquí.';

  @override
  String get repeaterRegions_repeated => 'Se repite';

  @override
  String get repeaterRegions_notRepeated => 'No se repite';

  @override
  String repeaterRegions_removeTitle(String name) {
    return '¿Quitar $name del repetidor?';
  }

  @override
  String get repeaterRegions_hasChildren =>
      'The repeater still has regions under this one. Remove those first.';

  @override
  String repeaterRegions_refused(String reply) {
    return 'El repetidor dijo: $reply';
  }

  @override
  String get repeaterRegions_fromYours => 'De tus regiones';

  @override
  String get repeaterRegions_alreadyThere => 'Ya está en este repetidor.';

  @override
  String channelRegion_qrInclude(String name) {
    return 'Incluir la región $name';
  }

  @override
  String get channelRegion_nearbyOption => 'Solo cerca (sin repetidores)';

  @override
  String get channelRegion_nearby => 'Solo cerca';

  @override
  String get channelRegion_nearbyHelp =>
      'Solo lo oyen las radios al alcance. Se envía una vez, sin reintentos.';

  @override
  String get channelRegion_nearbyTrip =>
      'TRAX reports on this channel won\'t be passed on by other radios.';

  @override
  String nearbyRegions_withPlain(String names) {
    return 'Regiones: $names y mensajes sin región';
  }

  @override
  String nearbyRegions_only(String names) {
    return 'Regiones: solo $names, no mensajes sin región';
  }

  @override
  String get nearbyRegions_noneButPlain =>
      'Sin regiones; repite mensajes sin región';

  @override
  String get nearbyRegions_nothing =>
      'No repite nada: ni regiones ni mensajes sin región';

  @override
  String channelRegion_carriers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count repetidores cercanos',
      one: '1 repetidor cercano',
    );
    return '$_temp0';
  }

  @override
  String get channelRegion_noCarrier => 'Ningún repetidor cercano la lleva';

  @override
  String get regions_heardNearby => 'Oídas a repetidores cercanos';

  @override
  String regions_nearbySpelling(String name) {
    return 'Los repetidores cercanos la escriben $name';
  }

  @override
  String get regions_useSpelling => 'Usarla';

  @override
  String channelPath_regionUnknown(String code) {
    return 'Una que no conoces (código $code)';
  }

  @override
  String chat_channelNoSignRegion(String region) {
    return 'Enviado en $region · sin señal de quién lo recibió. Los repetidores que no conocen $region lo descartan.';
  }

  @override
  String get myLocation_title => 'My location';

  @override
  String get myLocation_onlyYou => 'Only you';

  @override
  String get myLocation_people => 'People you picked can ask';

  @override
  String get myLocation_everyone => 'Everyone saved on your radio can ask';

  @override
  String get myLocation_adverts => 'In your adverts';

  @override
  String get myLocation_gpsNoFix => 'GPS on, no fix yet';

  @override
  String get myLocation_radioGps => 'Radio GPS';

  @override
  String myLocation_fix(String ago, String position) {
    return 'Fix $ago ago · $position';
  }

  @override
  String get myLocation_noFix => 'No fix yet.';

  @override
  String get myLocation_offSaves => 'Off saves battery.';

  @override
  String myLocation_lastFix(String time) {
    return 'Last fix $time.';
  }

  @override
  String get myLocation_inAdverts => 'In my adverts';

  @override
  String get myLocation_advertsHint => 'Anyone who hears your radio';

  @override
  String get myLocation_advertsInfo =>
      'Your adverts carry your location to anyone who hears them: the GPS fix, or with the GPS off the last fix or a typed location. They go out only when you send one, or TRAX does.';

  @override
  String get myLocation_peopleWho => 'People who can ask';

  @override
  String get myLocation_nobody => 'Nobody';

  @override
  String myLocation_allSaved(int count) {
    return 'Everyone saved on your radio ($count)';
  }

  @override
  String get myLocation_pickPeople => 'Pick people instead';

  @override
  String get myLocation_batterySensors => 'Battery and sensors';

  @override
  String get myLocation_peopleHint =>
      'They can ask your radio where it is, and its battery.';

  @override
  String get myLocation_addSomeone => 'Add someone';

  @override
  String myLocation_search(int count) {
    return 'Search $count contacts';
  }

  @override
  String get myLocation_recent => 'Recent messages';

  @override
  String get myLocation_canAsk => 'Can ask';

  @override
  String get iconHelp_title => 'What the icons mean';

  @override
  String get iconHelp_tap => 'Tap an icon in the bar to open it.';

  @override
  String get iconHelp_radio => 'Radio';

  @override
  String get iconHelp_battery => 'Radio battery';

  @override
  String get iconHelp_batteryText => 'Tap for volts.';

  @override
  String get iconHelp_signal => 'Signal';

  @override
  String get iconHelp_signalText =>
      'How well your radio hears the best repeater near you. Tap for the list.';

  @override
  String get iconHelp_repeaters => 'Repeaters heard';

  @override
  String get iconHelp_repeatersText =>
      'How many · the best one\'s code · how long ago';

  @override
  String get iconHelp_traxOff => 'TRAX mode off';

  @override
  String get iconHelp_traxOn => 'TRAX mode on';

  @override
  String get iconHelp_traxOnText => 'Your radio is on the group\'s frequency.';

  @override
  String get iconHelp_who => 'My location: who can see it';

  @override
  String get iconHelp_people => 'People you picked';

  @override
  String get iconHelp_peopleText => 'They can ask your radio where it is.';

  @override
  String get iconHelp_advertsText => 'Anyone who hears your radio.';

  @override
  String get iconHelp_gps => 'My location: radio GPS';

  @override
  String get iconHelp_filled => 'Filled: GPS on';

  @override
  String get iconHelp_outline => 'Outline: GPS off';

  @override
  String get iconHelp_dashed => 'Dashed: no GPS fix yet';

  @override
  String get iconHelp_red => 'Red: no fix, and someone can see it';

  @override
  String get locationNote_title => 'One location button';

  @override
  String get locationNote_body =>
      'GPS and Who can see my location are now one button. Its shape shows who can see your location. Filled means GPS is on.';
}
