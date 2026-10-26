// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'MeshTrax';

  @override
  String get nav_chats => 'Conversas';

  @override
  String get chats_title => 'Conversas';

  @override
  String get newChat_title => 'Selecionar contato';

  @override
  String newChat_contactCount(int count) {
    return '$count contatos';
  }

  @override
  String get newChat_newContact => 'Novo contato';

  @override
  String get newChat_newChannel => 'Novo canal';

  @override
  String get newChat_myContacts => 'Meus contatos';

  @override
  String get newChat_discovered => 'Descobertos';

  @override
  String get repeaters_title => 'Gerenciar repetidores';

  @override
  String get nav_contacts => 'Contactos';

  @override
  String get nav_channels => 'Canais';

  @override
  String get nav_map => 'Mapa';

  @override
  String get common_cancel => 'Cancelar';

  @override
  String get common_syncing_device_info =>
      'Lendo informações do dispositivo...';

  @override
  String get common_syncing_contacts => 'Lendo contatos...';

  @override
  String get common_syncing_channels => 'Lendo canais...';

  @override
  String get common_syncing_messages => 'Lendo mensagens...';

  @override
  String get common_ok => 'OK';

  @override
  String get common_connect => 'Conectar';

  @override
  String get common_unknownDevice => 'Dispositivo Desconhecido';

  @override
  String get common_save => 'Salvar';

  @override
  String get common_delete => 'Excluir';

  @override
  String get common_deleteAll => 'Excluir Tudo';

  @override
  String get common_close => 'Fechar';

  @override
  String get common_edit => 'Editar';

  @override
  String get common_add => 'Adicionar';

  @override
  String get common_settings => 'Configurações';

  @override
  String get common_disconnect => 'Desconectar';

  @override
  String get common_connected => 'Conectado';

  @override
  String get common_disconnected => 'Desconectado';

  @override
  String get common_connectionLost => 'Conexão perdida. Reconectando...';

  @override
  String get common_reconnecting => 'Reconectando...';

  @override
  String get common_create => 'Criar';

  @override
  String get common_continue => 'Continuar';

  @override
  String get common_share => 'Compartilhar';

  @override
  String get common_copy => 'Copiar';

  @override
  String get common_retry => 'Tentar novamente';

  @override
  String get common_hide => 'Esconder';

  @override
  String get common_remove => 'Remover';

  @override
  String get common_enable => 'Ativar';

  @override
  String get common_disable => 'Desativar';

  @override
  String get common_reboot => 'Reiniciar';

  @override
  String get common_loading => 'Carregando...';

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
  String get tcpScreenTitle => 'Estabelecer conexão via TCP';

  @override
  String get tcpHostLabel => 'Endereço IP';

  @override
  String get tcpHostHint => '192.168.40.10';

  @override
  String get tcpPortLabel => 'Porta';

  @override
  String get tcpPortHint => '5000';

  @override
  String get tcpStatus_notConnected => 'Insira o endereço final e conecte-se.';

  @override
  String tcpStatus_connectingTo(String endpoint) {
    return 'Conectando a $endpoint...';
  }

  @override
  String get tcpErrorHostRequired => 'É necessário fornecer um endereço IP.';

  @override
  String get tcpErrorPortInvalid =>
      'O valor do porto deve estar entre 1 e 65535.';

  @override
  String get tcpErrorUnsupported =>
      'O protocolo TCP não é suportado nesta plataforma.';

  @override
  String get tcpErrorTimedOut => 'A conexão TCP expirou.';

  @override
  String tcpConnectionFailed(String error) {
    return 'Falha na conexão TCP: $error';
  }

  @override
  String get usbScreenTitle => 'Conecte via USB';

  @override
  String get usbScreenSubtitle =>
      'Selecione um dispositivo serial detectado e conecte-o diretamente ao seu nó MeshCore.';

  @override
  String get usbScreenStatus => 'Selecione um dispositivo USB';

  @override
  String get usbScreenNote =>
      'A comunicação serial via USB está ativa em dispositivos Android e plataformas de desktop compatíveis.';

  @override
  String get usbScreenEmptyState =>
      'Nenhum dispositivo USB encontrado. Conecte um e atualize.';

  @override
  String get usbErrorPermissionDenied =>
      'A permissão para acesso via USB foi negada.';

  @override
  String get usbErrorDeviceMissing =>
      'O dispositivo USB selecionado não está mais disponível.';

  @override
  String get usbErrorInvalidPort => 'Selecione um dispositivo USB válido.';

  @override
  String get usbErrorBusy =>
      'Já existe uma solicitação de conexão USB em andamento.';

  @override
  String get usbErrorNotConnected => 'Não há nenhum dispositivo USB conectado.';

  @override
  String get usbErrorOpenFailed =>
      'Não foi possível abrir o dispositivo USB selecionado.';

  @override
  String get usbErrorConnectFailed =>
      'Não foi possível conectar ao dispositivo USB selecionado.';

  @override
  String get usbErrorUnsupported =>
      'A comunicação serial via USB não é suportada nesta plataforma.';

  @override
  String get usbErrorNativeLibraryMissing =>
      'Esta versão está sem a biblioteca serial USB, então os dispositivos USB não podem ser abertos. Reinstale o MeshTrax ou informe que esta versão está com defeito.';

  @override
  String get usbErrorBrowserUnsupported =>
      'Este navegador não é compatível com Web Serial. Use o Chrome ou o Edge via HTTPS (ou localhost).';

  @override
  String get usbErrorAlreadyActive => 'A conexão USB já está ativa.';

  @override
  String get usbErrorNoDeviceSelected =>
      'Nenhum dispositivo USB foi selecionado.';

  @override
  String get usbErrorPortClosed => 'A conexão USB não está ativa.';

  @override
  String get usbErrorConnectTimedOut =>
      'A conexão expirou. Verifique se o dispositivo possui o firmware USB Companion.';

  @override
  String get usbFallbackDeviceName => 'Dispositivo de Serial para a Web';

  @override
  String get usbStatus_notConnected => 'Selecione um dispositivo USB';

  @override
  String get usbStatus_connecting => 'Conectando ao dispositivo USB...';

  @override
  String get usbStatus_searching => 'Procurando por dispositivos USB...';

  @override
  String usbConnectionFailed(String error) {
    return 'Falha na conexão USB: $error';
  }

  @override
  String get scanner_scanning => 'Procurando por dispositivos...';

  @override
  String get scanner_connecting => 'Conectando...';

  @override
  String get scanner_disconnecting => 'Desconectando...';

  @override
  String get scanner_notConnected => 'Não está conectado';

  @override
  String scanner_connectedTo(String deviceName) {
    return 'Conectado a $deviceName';
  }

  @override
  String get scanner_showAllDevices =>
      'Mostrar todos os dispositivos Bluetooth';

  @override
  String get scanner_showMeshCoreOnly => 'Mostrar só rádios MeshCore';

  @override
  String get scanner_radioNotResponding =>
      'O rádio não está respondendo. Talvez seja preciso pareá-lo: abra as configurações de Bluetooth, adicione o rádio e digite o PIN dele, depois tente de novo.';

  @override
  String get scanner_pairingFailed =>
      'O pareamento Bluetooth foi cancelado ou falhou. Verifique se nada mais (como seu celular) está conectado ao rádio, depois tente de novo e digite o PIN dele.';

  @override
  String scanner_connectionFailed(String error) {
    return 'Falha na conexão: $error';
  }

  @override
  String get scanner_stop => 'Pare';

  @override
  String get scanner_scan => 'Digitalizar';

  @override
  String get scanner_scanFromImage => 'Escanear de uma imagem';

  @override
  String get scanner_noQrFoundInImage =>
      'Nenhum código QR válido encontrado na imagem';

  @override
  String get scanner_bluetoothOff => 'Bluetooth está desativado';

  @override
  String get scanner_bluetoothOffMessage =>
      'Por favor, ative o Bluetooth para escanear por dispositivos.';

  @override
  String get scanner_chromeRequired => 'Navegador Chrome necessário';

  @override
  String get scanner_chromeRequiredMessage =>
      'Esta aplicação web requer o Google Chrome ou um navegador baseado no Chromium para suporte de Bluetooth.';

  @override
  String get scanner_enableBluetooth => 'Ative o Bluetooth';

  @override
  String get device_quickSwitch => 'Mudar rapidamente';

  @override
  String get device_meshcore => 'MeshCore';

  @override
  String get settings_title => 'Configurações';

  @override
  String get settings_deviceInfo => 'Informações do Dispositivo';

  @override
  String get settings_appSettings => 'Configurações do App';

  @override
  String get settings_appSettingsSubtitle =>
      'Notificações, mensagens e preferências de mapa';

  @override
  String get settings_nodeSettings => 'Configurações do Nó';

  @override
  String get settings_nodeName => 'Nome do Nó';

  @override
  String get settings_nodeNameNotSet => 'Não definido';

  @override
  String get settings_nodeNameHint => 'Insira o nome do nó';

  @override
  String get settings_nodeNameUpdated => 'Nome atualizado';

  @override
  String get settings_radioSettings => 'Configurações de Rádio';

  @override
  String get settings_radioSettingsSubtitle =>
      'Frequência, potência, fator de espalhamento';

  @override
  String get settings_radioSettingsUpdated =>
      'Configurações de rádio atualizadas';

  @override
  String get settings_location => 'Localização';

  @override
  String get settings_locationSubtitle => 'Coordenadas GPS';

  @override
  String get settings_locationUpdated => 'Localização atualizada';

  @override
  String get settings_locationBothRequired =>
      'Insira a latitude e a longitude.';

  @override
  String get settings_locationInvalid => 'Latitude ou longitude inválidos.';

  @override
  String get settings_locationGPSEnable => 'Ativar GPS';

  @override
  String get settings_locationGPSEnableSubtitle =>
      'Habilita a atualização automática da localização via GPS.';

  @override
  String get settings_latitude => 'Latitude';

  @override
  String get settings_longitude => 'Longitude';

  @override
  String get settings_contactSettings => 'Configurações de Contato';

  @override
  String get settings_contactSettingsSubtitle =>
      'Configurações para como os contatos são adicionados';

  @override
  String get settings_privacyMode => 'Modo de Privacidade';

  @override
  String get settings_privacyModeSubtitle =>
      'Esconder nome/localização em anúncios';

  @override
  String get settings_privacyModeToggle =>
      'Ative o modo de privacidade para ocultar seu nome e localização em anúncios.';

  @override
  String get settings_privacyModeEnabled => 'Modo de privacidade ativado';

  @override
  String get settings_privacyModeDisabled => 'Modo de privacidade desativado';

  @override
  String get settings_privacy => 'Configurações de Privacidade';

  @override
  String get settings_privacySubtitle => 'Controle o que é compartilhado.';

  @override
  String get settings_privacySettingsDescription =>
      'Escolha quais informações o seu dispositivo compartilha com os outros.';

  @override
  String get settings_denyAll => 'Negar todos';

  @override
  String get settings_allowByContact => 'Permitir por bandeiras de contato';

  @override
  String get settings_allowAll => 'Permitir todos';

  @override
  String get settings_telemetryBaseMode => 'Modo Base de Telemetria';

  @override
  String get settings_telemetryLocationMode =>
      'Modo de Localização de Telemetria';

  @override
  String get settings_telemetryEnvironmentMode =>
      'Modo de Ambiente de Telemetria';

  @override
  String get settings_advertLocation => 'Localização do Anúncio';

  @override
  String get settings_advertLocationSubtitle =>
      'Incluir localização no anúncio';

  @override
  String get settings_multiAck => 'Multi-ACKs';

  @override
  String get settings_telemetryModeUpdated => 'Modo de telemetria atualizado';

  @override
  String get settings_actions => 'Ações';

  @override
  String get settings_sendAdvertisement => 'Enviar Publicidade';

  @override
  String get settings_sendAdvertisementSubtitle =>
      'Presença de transmissão agora';

  @override
  String get settings_advertisementSent => 'Anúncio enviado';

  @override
  String get settings_syncTime => 'Tempo de Sincronização';

  @override
  String get settings_syncTimeSubtitle =>
      'Definir o relógio do dispositivo para o horário do telefone';

  @override
  String get settings_timeSynchronized => 'Sincronizado com o tempo';

  @override
  String get settings_refreshContacts => 'Atualizar Contatos';

  @override
  String get settings_refreshContactsSubtitle =>
      'Recarregar a lista de contatos do dispositivo';

  @override
  String get settings_rebootDevice => 'Reiniciar Dispositivo';

  @override
  String get settings_rebootDeviceSubtitle =>
      'Reiniciar o dispositivo MeshCore';

  @override
  String get settings_rebootDeviceConfirm =>
      'Tem certeza de que deseja reiniciar o dispositivo? Você será desconectado.';

  @override
  String get settings_debug => 'Depurar';

  @override
  String get settings_bleDebugLog => 'Log de Depuração BLE';

  @override
  String get settings_bleDebugLogSubtitle =>
      'Comandos, respostas e dados brutos do BLE';

  @override
  String get settings_appDebugLog => 'Log de Depuração do Aplicativo';

  @override
  String get settings_appDebugLogSubtitle =>
      'Mensagens de depuração do aplicativo';

  @override
  String get settings_exportDatabase => 'Exportar banco de dados de mensagens';

  @override
  String get settings_exportDatabaseSubtitle =>
      'Uma cópia de todos os chats e contatos, para depuração. Mantenha-a privada.';

  @override
  String settings_exportDatabaseSaved(String path) {
    return 'Banco de dados salvo em: $path';
  }

  @override
  String settings_exportDatabaseFailed(String error) {
    return 'Falha ao exportar: $error';
  }

  @override
  String get settings_about => 'Sobre';

  @override
  String settings_aboutVersion(String version) {
    return 'MeshTrax v$version';
  }

  @override
  String get settings_aboutLegalese => 'Projeto MeshCore de Código Aberto 2024';

  @override
  String get settings_aboutDescription =>
      'Um cliente Flutter de código aberto para dispositivos de rede mesh LoRa Core da MeshCore.';

  @override
  String get settings_aboutOpenMeteoAttribution =>
      'Dados de elevação LOS: Open-Meteo (CC BY 4.0)';

  @override
  String get settings_infoName => 'Nome';

  @override
  String get settings_infoId => 'ID';

  @override
  String get settings_infoStatus => 'Status';

  @override
  String get settings_infoBattery => 'Bateria';

  @override
  String get settings_infoPublicKey => 'Chave Pública';

  @override
  String get settings_infoContactsCount => 'Número de Contatos';

  @override
  String get settings_infoChannelCount => 'Número do Canal';

  @override
  String get settings_presets => 'Presets';

  @override
  String get settings_frequency => 'Frequência (MHz)';

  @override
  String get settings_frequencyHelper => '300,0 - 2500,0';

  @override
  String get settings_frequencyInvalid => 'Frequência inválida (300-2500 MHz)';

  @override
  String get settings_bandwidth => 'Largura de banda';

  @override
  String get settings_spreadingFactor => 'Fator de Dispersão';

  @override
  String get settings_codingRate => 'Taxa de Codificação';

  @override
  String get settings_txPower => 'TX Potência (dBm)';

  @override
  String get settings_txPowerInvalid => 'Potência de TX inválida';

  @override
  String get settings_clientRepeat => 'Repetição sem rede';

  @override
  String get settings_clientRepeatSubtitle =>
      'Permita que este dispositivo repita pacotes de rede para outros dispositivos.';

  @override
  String get settings_clientRepeatFreqWarning =>
      'A repetição fora da rede requer frequências de 433, 869 ou 918 MHz.';

  @override
  String settings_error(String message) {
    return 'Erro: $message';
  }

  @override
  String get appSettings_title => 'Configurações do App';

  @override
  String get appSettings_appearance => 'Aparência';

  @override
  String get appSettings_theme => 'Tema';

  @override
  String get appSettings_themeSystem => 'Padrão do sistema';

  @override
  String get appSettings_themeLight => 'Luz';

  @override
  String get appSettings_themeDark => 'Escuro';

  @override
  String get appSettings_language => 'Idioma';

  @override
  String get appSettings_languageSystem => 'Padrão do sistema';

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
  String get appSettings_languageUk => 'Ucraniano';

  @override
  String get appSettings_enableMessageTracing =>
      'Ativar rastreamento de mensagens';

  @override
  String get appSettings_enableMessageTracingSubtitle =>
      'Mostrar metadados detalhados de roteamento e tempo para as mensagens';

  @override
  String get appSettings_senderNameColors => 'Nomes de remetentes coloridos';

  @override
  String get appSettings_senderNameColorsSubtitle =>
      'Dá a cada remetente do canal uma cor de nome própria. Desligado usa a cor do tema para todos.';

  @override
  String get appSettings_showTextFormatting => 'Mostrar formatação de texto';

  @override
  String get appSettings_showTextFormattingSubtitle =>
      'Markdown nas mensagens: **negrito**, *itálico*, ||spoilers||, títulos e links. Outros apps MeshCore mostram os caracteres brutos.';

  @override
  String get appSettings_notifications => 'Notificações';

  @override
  String get appSettings_enableNotifications => 'Ativar Notificações';

  @override
  String get appSettings_enableNotificationsSubtitle =>
      'Receber notificações para mensagens e anúncios';

  @override
  String get appSettings_notificationPermissionDenied =>
      'Permissão de notificação negada';

  @override
  String get appSettings_notificationsEnabled => 'Notificações ativadas';

  @override
  String get appSettings_notificationsDisabled => 'Notificações desativadas';

  @override
  String get appSettings_messageNotifications => 'Notificações de Mensagem';

  @override
  String get appSettings_messageNotificationsSubtitle =>
      'Mostrar notificação ao receber novas mensagens';

  @override
  String get appSettings_channelMessageNotifications =>
      'Notificações de Mensagens do Canal';

  @override
  String get appSettings_channelMessageNotificationsSubtitle =>
      'Mostrar notificação ao receber mensagens do canal';

  @override
  String get appSettings_advertisementNotifications =>
      'Notificações de Anúncios';

  @override
  String get appSettings_advertisementNotificationsSubtitle =>
      'Mostrar notificação quando novos nós forem descobertos';

  @override
  String get appSettings_messaging => 'Mensagens';

  @override
  String get appSettings_maxMessageRetries =>
      'Número máximo de tentativas de envio de mensagens';

  @override
  String get appSettings_maxMessageRetriesSubtitle =>
      'Número de tentativas de reenvio antes de classificar uma mensagem como falha.';

  @override
  String get appSettings_maxChannelMessageRetries =>
      'Máximo de reenvios no canal';

  @override
  String get appSettings_maxChannelMessageRetriesSubtitle =>
      'Tenta de novo esse número de vezes até ouvir pelo menos uma repetição';

  @override
  String get appSettings_battery => 'Bateria';

  @override
  String get appSettings_batteryChemistry => 'Química da Bateria';

  @override
  String appSettings_batteryChemistryPerDevice(String deviceName) {
    return 'Definir por dispositivo ($deviceName)';
  }

  @override
  String get appSettings_batteryChemistryConnectFirst =>
      'Conecte-se a um dispositivo para escolher';

  @override
  String get appSettings_batteryNmc => '18650 NMC (3,0-4,2V)';

  @override
  String get appSettings_batteryLifepo4 => 'LiFePO4 (2,6-3,65V)';

  @override
  String get appSettings_batteryLipo => 'LiPo (3,0-4,2V)';

  @override
  String get appSettings_mapDisplay => 'Exibição do Mapa';

  @override
  String get appSettings_showRepeaters => 'Mostrar Repetidores';

  @override
  String get appSettings_showRepeatersSubtitle =>
      'Exibir nós de repetidor no mapa';

  @override
  String get appSettings_showChatNodes => 'Mostrar Nós de Chat';

  @override
  String get appSettings_showChatNodesSubtitle => 'Exibir nós de chat no mapa';

  @override
  String get appSettings_showOtherNodes => 'Mostrar Outros Nós';

  @override
  String get appSettings_showOtherNodesSubtitle =>
      'Exibir outros tipos de nó no mapa';

  @override
  String get appSettings_timeFilter => 'Filtro de Tempo';

  @override
  String get appSettings_timeFilterShowAll => 'Mostrar todos os nós';

  @override
  String appSettings_timeFilterShowLast(int hours) {
    return 'Mostrar nós das últimas $hours horas';
  }

  @override
  String get appSettings_mapTimeFilter => 'Filtro de Tempo do Mapa';

  @override
  String get appSettings_showNodesDiscoveredWithin =>
      'Mostrar nós descobertos dentro de:';

  @override
  String get appSettings_allTime => 'Todos os tempos';

  @override
  String get appSettings_lastHour => 'Última hora';

  @override
  String get appSettings_last6Hours => 'Últimos 6 horas';

  @override
  String get appSettings_last24Hours => 'Últimas 24 horas';

  @override
  String get appSettings_lastWeek => 'Da última semana';

  @override
  String get appSettings_unitsTitle => 'Unidades';

  @override
  String get appSettings_unitsMetric => 'Métrico (m/km)';

  @override
  String get appSettings_unitsImperial => 'Imperial (ft/mi)';

  @override
  String get appSettings_debugCard => 'Depurar';

  @override
  String get appSettings_appDebugLogging =>
      'Rastreamento de Depuração do Aplicativo';

  @override
  String get appSettings_appDebugLoggingSubtitle =>
      'Registrar mensagens de depuração do aplicativo Log para solucionar problemas';

  @override
  String get appSettings_appDebugLoggingEnabled =>
      'Log de depuração do aplicativo habilitado';

  @override
  String get appSettings_appDebugLoggingDisabled =>
      'O registro de depuração do aplicativo está desativado.';

  @override
  String get appSettings_incrementalContactSync =>
      'Sincronização incremental de contatos';

  @override
  String get appSettings_incrementalContactSyncSubtitle =>
      'Ao reconectar, pede ao rádio só os contatos que mudaram desde a última vez';

  @override
  String get contacts_title => 'Contactos';

  @override
  String get contacts_noContacts => 'Ainda não existem contatos.';

  @override
  String get contacts_shareMyQrCode => 'Compartilhar meu código QR';

  @override
  String get contacts_shareQrCodeDesc =>
      'Deixe outras pessoas escanearem para adicionar você como contato';

  @override
  String get contacts_contactsWillAppear =>
      'Os contatos serão exibidos quando os dispositivos anunciarem.';

  @override
  String get contacts_unread => 'Não lido';

  @override
  String get contacts_searchContactsNoNumber => 'Pesquisar Contatos...';

  @override
  String contacts_searchContacts(int number, String str) {
    return 'Pesquisar contatos...';
  }

  @override
  String contacts_searchFavorites(int number, String str) {
    return 'Pesquisar $number$str Favoritos...';
  }

  @override
  String contacts_searchUsers(int number, String str) {
    return 'Pesquisar $number$str Usuários...';
  }

  @override
  String contacts_searchRepeaters(int number, String str) {
    return 'Pesquisar $number$str Repetidores...';
  }

  @override
  String contacts_searchRoomServers(int number, String str) {
    return 'Pesquisar $number$str servidores de sala...';
  }

  @override
  String get contacts_noUnreadContacts => 'Sem contatos não lidos.';

  @override
  String get contacts_noContactsFound =>
      'Não foram encontrados contatos ou grupos.';

  @override
  String get contacts_deleteContact => 'Excluir Contato';

  @override
  String contacts_deleteContactConfirm(String contactName) {
    return 'Tem certeza de que deseja excluir $contactName?';
  }

  @override
  String contacts_contactDeleted(String contactName) {
    return 'Contato $contactName excluído.';
  }

  @override
  String contacts_contactDeleteFailed(String contactName) {
    return 'Falha ao excluir $contactName.';
  }

  @override
  String get contacts_noMatchingContacts =>
      'Nenhum contato corresponde ao filtro.';

  @override
  String contacts_removeConfirm(String contactName) {
    return 'Remover $contactName dos contatos?';
  }

  @override
  String get contacts_manageRepeater => 'Gerenciar Repetidor';

  @override
  String get contacts_manageRoom => 'Gerenciar Servidor de Sala';

  @override
  String get contacts_roomLogin => 'Login no Quarto';

  @override
  String get contacts_openChat => 'Abrir Chat';

  @override
  String get contacts_editGroup => 'Editar Grupo';

  @override
  String get contacts_deleteGroup => 'Excluir Grupo';

  @override
  String contacts_deleteGroupConfirm(String groupName) {
    return 'Remover $groupName?';
  }

  @override
  String get contacts_newGroup => 'Novo Grupo';

  @override
  String get contacts_groupName => 'Nome do grupo';

  @override
  String get contacts_groupNameRequired => 'O nome do grupo é obrigatório.';

  @override
  String get contacts_groupNameReserved => 'Este nome de grupo está reservado';

  @override
  String contacts_groupAlreadyExists(String name) {
    return 'O grupo \"$name\" já existe';
  }

  @override
  String get contacts_filterContacts => 'Filtrar contatos...';

  @override
  String get contacts_noContactsMatchFilter =>
      'Não existem contatos que correspondam ao seu filtro';

  @override
  String get contacts_noMembers => 'Nenhum membro';

  @override
  String get contacts_lastSeenNow => 'Última vez que foi visto agora';

  @override
  String contacts_lastSeenMinsAgo(int minutes) {
    return 'Última vez que foi visto $minutes minutos atrás';
  }

  @override
  String get contacts_lastSeenHourAgo => 'Última vez que foi visto há 1 hora.';

  @override
  String contacts_lastSeenHoursAgo(int hours) {
    return 'Última vez visto $hours horas atrás';
  }

  @override
  String get contacts_lastSeenDayAgo => 'Última vez que foi visto 1 dia atrás';

  @override
  String contacts_lastSeenDaysAgo(int days) {
    return 'Última vez visto $days dias atrás';
  }

  @override
  String get contact_info => 'Informações de Contato';

  @override
  String get contact_settings => 'Configurações de Contato';

  @override
  String get contact_telemetry => 'Telemetria';

  @override
  String get contact_lastSeen => 'Visto pela última vez';

  @override
  String get contact_clearChat => 'Limpar Chat';

  @override
  String get contact_teleBase => 'Base de Telemetria';

  @override
  String get contact_teleBaseSubtitle =>
      'Permitir compartilhamento do nível da bateria e telemetria básica';

  @override
  String get contact_teleLoc => 'Localização de Telemetria';

  @override
  String get contact_teleLocSubtitle =>
      'Permitir compartilhamento de dados de localização';

  @override
  String get contact_teleEnv => 'Ambiente de Telemetria';

  @override
  String get contact_teleEnvSubtitle =>
      'Permitir compartilhamento de dados do sensor de ambiente';

  @override
  String get contacts_publicKey => 'Chave pública';

  @override
  String get channels_title => 'Canais';

  @override
  String get channels_noChannelsConfigured => 'Nenhuma canalização configurada';

  @override
  String get channels_addPublicChannel => 'Adicionar Canal Público';

  @override
  String get channels_searchChannels => 'Pesquisar canais...';

  @override
  String get channels_noChannelsFound => 'Nenhum canal encontrado';

  @override
  String channels_channelIndex(int index) {
    return 'Canal $index';
  }

  @override
  String get channels_hashtagChannel => 'Canal com hashtag';

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
  String get channels_shareChannel => 'Compartilhar canal';

  @override
  String get channels_shareChannelInstructions =>
      'Escaneie o código QR para adicionar o canal.\nMenu → Adicionar Canal → Digitalizar um Código QR';

  @override
  String get channels_secretKey => 'Chave secreta';

  @override
  String get channels_meshcoreUri => 'URI do MeshCore';

  @override
  String get channels_shareChannelQr => 'Escanear código QR do canal';

  @override
  String get channels_shareChannelWarning =>
      'Aviso: qualquer pessoa que escanear este código QR terá acesso a este canal.';

  @override
  String get channels_muteChannel => 'Silenciar canal';

  @override
  String get channels_unmuteChannel => 'Ativar canal';

  @override
  String get channels_deleteChannel => 'Excluir canal';

  @override
  String channels_deleteChannelConfirm(String name) {
    return 'Excluir \"$name\"? Não pode ser desfeito.';
  }

  @override
  String channels_channelDeleteFailed(String name) {
    return 'Falha ao excluir o canal \"$name\"';
  }

  @override
  String channels_channelDeleted(String name) {
    return 'Canal \"$name\" excluído';
  }

  @override
  String get channels_addChannel => 'Adicionar Canal';

  @override
  String get channels_channelIndexLabel => 'Índice do Canal';

  @override
  String get channels_channelName => 'Nome do Canal';

  @override
  String get channels_usePublicChannel => 'Usar Canal Público';

  @override
  String get channels_standardPublicPsk => 'PSK público padrão';

  @override
  String get channels_pskHex => 'PSK (Hex)';

  @override
  String get channels_generateRandomPsk => 'Gerar PSK aleatório';

  @override
  String get channels_enterChannelName => 'Por favor, insira um nome de canal';

  @override
  String get channels_pskMustBe32Hex =>
      'O PSK deve ter 32 caracteres hexadecimais.';

  @override
  String get channels_addChannelConfirmation =>
      'Deseja adicionar o seguinte canal?';

  @override
  String get channels_channelAddedSuccess => 'Canal adicionado com sucesso.';

  @override
  String get channels_noAvailableChannelSlots =>
      'Não há posições de canal disponíveis.';

  @override
  String get appSettings_mentionNotifications => 'Notificações de menções';

  @override
  String get appSettings_mentionNotificationsSubtitle =>
      'Quando alguém menciona ou responde a você — mesmo em canais silenciados';

  @override
  String notification_mentionIn(String channelName) {
    return 'Menção em $channelName';
  }

  @override
  String channels_channelAdded(String name) {
    return 'Canal \"$name\" adicionado';
  }

  @override
  String channels_editChannelTitle(int index) {
    return 'Editar Canal $index';
  }

  @override
  String get channels_smazCompression => 'Compressão SMAZ';

  @override
  String channels_channelUpdated(String name) {
    return 'Canal \"$name\" atualizado';
  }

  @override
  String get channels_publicChannelAdded => 'Canal público adicionado';

  @override
  String get channels_sortBy => 'Ordenar por';

  @override
  String get channels_sortManual => 'Manual';

  @override
  String get channels_sortAZ => 'A-Z';

  @override
  String get channels_sortLatestMessages => 'Últimas mensagens';

  @override
  String get channels_sortUnread => 'Não lido';

  @override
  String get channels_createPrivateChannel => 'Criar um Canal Privado';

  @override
  String get channels_createPrivateChannelDesc =>
      'Protegido com uma chave secreta.';

  @override
  String get channels_joinPrivateChannel => 'Junte-se a um Canal Privado';

  @override
  String get channels_joinPrivateChannelDesc =>
      'Inserir uma chave secreta manualmente.';

  @override
  String get channels_joinPublicChannel => 'Junte-se ao Canal Público';

  @override
  String get channels_joinPublicChannelDesc =>
      'Qualquer pessoa pode entrar neste canal.';

  @override
  String get channels_joinHashtagChannel => 'Junte-se a um Canal com Hashtag';

  @override
  String get channels_joinHashtagChannelDesc =>
      'Qualquer pessoa pode participar de canais com hashtag.';

  @override
  String get channels_scanQrCode => 'Digitalizar um Código QR';

  @override
  String get channels_scanQrCodeComingSoon => 'Em breve';

  @override
  String get channels_enterHashtag => 'Insira hashtag';

  @override
  String get channels_hashtagHint => 'ex. #equipe';

  @override
  String get chat_noMessages => 'Ainda não existem mensagens.';

  @override
  String get chat_sendMessage => 'Enviar mensagem';

  @override
  String chat_sendMessageTo(String contactName) {
    return 'Enviar uma mensagem para $contactName';
  }

  @override
  String get chat_sendMessageToStart => 'Enviar uma mensagem para começar';

  @override
  String get chat_originalMessageNotFound => 'Mensagem original não encontrada';

  @override
  String chat_replyingTo(String name) {
    return 'Responder a $name';
  }

  @override
  String chat_replyTo(String name) {
    return 'Responder a $name';
  }

  @override
  String get chat_location => 'Localização';

  @override
  String get common_copiedToClipboard => 'Copiado para a área de transferência';

  @override
  String get common_copyToClipboard => 'Copiar para a área de transferência';

  @override
  String get contacts_copyContactToClipboard =>
      'Copiar meu contato para a área de transferência';

  @override
  String get chat_typeMessage => 'Digite uma mensagem...';

  @override
  String get chat_searchMessages => 'Pesquisar mensagens';

  @override
  String get chat_searchNoMatches => 'Sem resultados';

  @override
  String chat_messageTooLong(int maxBytes) {
    return 'Mensagem muito longa (máximo $maxBytes bytes).';
  }

  @override
  String get chat_messageCopied => 'Mensagem copiada';

  @override
  String get chat_messageDeleted => 'Mensagem excluída';

  @override
  String get chat_sendGif => 'Enviar GIF';

  @override
  String get chat_reply => 'Responder';

  @override
  String get chat_newMessages => 'NOVAS MENSAGENS';

  @override
  String get chat_addReaction => 'Adicionar Reação';

  @override
  String get chat_mention => 'Mencionar';

  @override
  String get dmChannel_menuLabel => 'Mensagem direta';

  @override
  String dmChannel_pickerTitle(String name) {
    return 'Enviar DM para $name';
  }

  @override
  String get dmChannel_pickerHint =>
      'Confira a chave e a última vez em que foi visto — nomes não são únicos.';

  @override
  String get dmChannel_warningTitle => 'É mesmo essa pessoa?';

  @override
  String get dmChannel_warningBody =>
      'Os nomes no canal são escolhidos pela própria pessoa e qualquer um pode imitá-los. Para algo sensível, confirme antes a chave pública deste contato por outro meio.';

  @override
  String get dmChannel_dontShowAgain => 'Não mostrar novamente';

  @override
  String get batterySleep_title => 'Manter o MeshTrax em execução';

  @override
  String get batterySleep_bodySamsung =>
      'Os celulares Samsung colocam os apps para dormir para economizar bateria, o que desconecta o seu rádio. Abra Configurações → Aplicativos → MeshTrax → Bateria e escolha Sem restrições. Verifique também Bateria → Limites de uso em segundo plano e confira se o MeshTrax não está em Aplicativos em suspensão nem em Aplicativos em suspensão profunda.';

  @override
  String get batterySleep_bodyGeneric =>
      'Seu celular pode parar o MeshTrax em segundo plano para economizar bateria, o que desconecta o seu rádio. Abra as configurações de bateria e defina o MeshTrax como Sem restrições (ou Irrestrito). Em alguns celulares, também é preciso ativar a Inicialização automática do MeshTrax.';

  @override
  String get batterySleep_openSettings => 'Abrir configurações';

  @override
  String get batterySleep_notNow => 'Agora não';

  @override
  String get batterySleep_settingsTile =>
      'Manter o MeshTrax rodando em segundo plano';

  @override
  String get batterySleep_settingsTileSubtitle =>
      'Impede que a economia de bateria do celular coloque o MeshTrax para dormir';

  @override
  String dmChannel_noMatchTitle(String name) {
    return 'Ainda não é possível enviar DM para $name';
  }

  @override
  String get dmChannel_noMatchBody =>
      'Você ainda não tem a chave dessa pessoa, e ela vai precisar da sua para responder — as chaves só viajam em anúncios. \"Enviar meu anúncio\" transmite o seu daqui mesmo. \"Pedir no canal\" escreve um pedido na caixa de mensagem para você enviar.';

  @override
  String get dmChannel_askInChannel => 'Pedir no canal';

  @override
  String get dmChannel_sendMyAdvert => 'Enviar meu anúncio';

  @override
  String get dmChannel_askText =>
      'por favor, envie um anúncio para que eu possa te mandar uma DM';

  @override
  String get dmChannel_watching =>
      'Esperando o anúncio dessa pessoa — vamos perguntar aqui quando ele chegar.';

  @override
  String dmChannel_advertHeard(String name) {
    return '$name agora está acessível';
  }

  @override
  String get dmChannel_openDm => 'DM';

  @override
  String get appSettings_zoomLevel => 'Nível de zoom';

  @override
  String get common_reset => 'Redefinir';

  @override
  String get chat_reactionsTitle => 'Reações';

  @override
  String get chat_reactionUnknownSender => 'Desconhecido';

  @override
  String chat_reactionTargetMissing(String sender) {
    return '$sender reagiu a uma mensagem que não está nesta conversa';
  }

  @override
  String get chat_me => 'Eu';

  @override
  String get emojiCategorySmileys => 'Emojis';

  @override
  String get emojiCategoryGestures => 'Gestos';

  @override
  String get emojiCategoryHearts => 'Corações';

  @override
  String get emojiCategoryObjects => 'Objetos';

  @override
  String get gifPicker_title => 'Escolher um GIF';

  @override
  String get gifPicker_searchHint => 'Pesquisar GIFs...';

  @override
  String get gifPicker_poweredBy => 'Desenvolvido por GIPHY';

  @override
  String get gifPicker_noGifsFound => 'Nenhum GIF encontrado';

  @override
  String get gifPicker_failedLoad => 'Não foi possível carregar os GIFs';

  @override
  String get gifPicker_failedSearch => 'Falha na pesquisa de GIFs';

  @override
  String get gifPicker_noInternet => 'Sem conexão com a internet';

  @override
  String get debugLog_appTitle => 'Log de Depuração do Aplicativo';

  @override
  String get debugLog_bleTitle => 'Log de Depuração BLE';

  @override
  String get debugLog_copyLog => 'Copiar log';

  @override
  String get debugLog_saveLog => 'Salvar log em arquivo';

  @override
  String get debugLog_saved => 'Log salvo';

  @override
  String get debugLog_saveCancelled => 'Salvamento cancelado';

  @override
  String get debugLog_filterAll => 'Tudo';

  @override
  String get debugLog_filterWarnings => 'Avisos';

  @override
  String get debugLog_filterErrors => 'Erros';

  @override
  String get debugLog_clearLog => 'Limpar log';

  @override
  String get debugLog_copied => 'Log de depuração copiado';

  @override
  String get debugLog_bleCopied => 'Log BLE copiado';

  @override
  String get debugLog_noEntries => 'Ainda não existem logs de depuração.';

  @override
  String get debugLog_enableInSettings =>
      'Ativar o log de depuração do aplicativo nas configurações';

  @override
  String get debugLog_frames => 'Estruturas';

  @override
  String get debugLog_rawLogRx => 'Log Raw-RX';

  @override
  String get debugLog_noBleActivity => 'Ainda não há atividade BLE.';

  @override
  String debugFrame_length(int count) {
    return 'Comprimento do Quadro: $count bytes';
  }

  @override
  String debugFrame_command(String value) {
    return 'Comando: 0x$value';
  }

  @override
  String get debugFrame_textMessageHeader => 'Mensagem de Texto:';

  @override
  String debugFrame_destinationPubKey(String pubKey) {
    return '- Destino PubKey: $pubKey';
  }

  @override
  String debugFrame_timestamp(int timestamp) {
    return '- Timestamp: $timestamp';
  }

  @override
  String debugFrame_flags(String value) {
    return '- Bandeiras: 0x$value';
  }

  @override
  String debugFrame_textType(int type, String label) {
    return '- Tipo de Texto: $type ($label)';
  }

  @override
  String get debugFrame_textTypeCli => 'CLI';

  @override
  String get debugFrame_textTypeCliCommand => 'Comando CLI';

  @override
  String get debugFrame_textTypePlain => 'Simples';

  @override
  String debugFrame_text(String text) {
    return '- Texto: \"$text\"';
  }

  @override
  String get debugFrame_hexDump => 'Espaço Hexadecimal:';

  @override
  String get chat_hopSingular => 'pule';

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
  String get chat_setCustomPath => 'Definir Caminho Personalizado';

  @override
  String get chat_fullPath => 'Caminho Completo';

  @override
  String get chat_pathDetailsNotAvailable =>
      'Os detalhes do caminho ainda não estão disponíveis. Tente enviar uma mensagem para atualizar.';

  @override
  String get chat_type => 'Digite';

  @override
  String get chat_path => 'Caminho';

  @override
  String get chat_publicKey => 'Chave Pública';

  @override
  String get chat_compressOutgoingMessages => 'Comprimir mensagens enviadas';

  @override
  String get chat_floodForced => 'Inundação (forçada)';

  @override
  String get chat_directForced => 'Direto (forçado)';

  @override
  String chat_hopsForced(int count) {
    return '$count saltos (forçado)';
  }

  @override
  String get chat_floodAuto => 'Inundação (automática)';

  @override
  String get chat_direct => 'Salvar';

  @override
  String get chat_poiShared => 'Ponto de Interesse Compartilhado';

  @override
  String chat_unread(int count) {
    return 'Não lido: $count';
  }

  @override
  String get chat_openLink => 'Abrir link?';

  @override
  String get chat_openLinkConfirmation =>
      'Deseja abrir este link no seu navegador?';

  @override
  String get chat_open => 'Abrir';

  @override
  String chat_couldNotOpenLink(String url) {
    return 'Não foi possível abrir o link: $url';
  }

  @override
  String get chat_invalidLink => 'Formato de link inválido';

  @override
  String get map_lineOfSight => 'Linha de visão';

  @override
  String get map_losScreenTitle => 'Linha de visão';

  @override
  String get map_noNodesWithLocation =>
      'Não existem nós com dados de localização.';

  @override
  String get map_nodesNeedGps =>
      'Os nós precisam partilhar as suas coordenadas GPS\npara aparecerem no mapa';

  @override
  String map_nodesCount(int count) {
    return 'Nós: $count';
  }

  @override
  String map_pinsCount(int count) {
    return 'Pinos: $count';
  }

  @override
  String get map_chat => 'Chat';

  @override
  String get map_repeater => 'Repetidor';

  @override
  String get map_room => 'Quarto';

  @override
  String get map_sensor => 'Sensor';

  @override
  String get map_pinDm => 'Gatilho (DM)';

  @override
  String get map_pinPrivate => 'Bloquear (Privado)';

  @override
  String get map_pinPublic => 'Pin (Público)';

  @override
  String get map_lastSeen => 'Última Visão';

  @override
  String get map_disconnectConfirm =>
      'Tem certeza de que deseja desconectar deste dispositivo?';

  @override
  String get map_from => 'De';

  @override
  String get map_source => 'Fonte';

  @override
  String get map_flags => 'Bandeiras';

  @override
  String get map_shareMarkerHere => 'Compartilhar marcador aqui';

  @override
  String get map_setAsMyLocation => 'Defina minha localização';

  @override
  String get map_pinLabel => 'Rótulo de marcador';

  @override
  String get map_label => 'Rótulo';

  @override
  String get map_pointOfInterest => 'Ponto de interesse';

  @override
  String get map_sendToContact => 'Enviar para o contato';

  @override
  String get map_sendToChannel => 'Enviar para o canal';

  @override
  String get map_noChannelsAvailable => 'Não existem canais disponíveis.';

  @override
  String get map_publicLocationShare => 'Compartilhar local público';

  @override
  String map_publicLocationShareConfirm(String channelLabel) {
    return 'Você está prestes a compartilhar uma localização em $channelLabel. Este canal é público e qualquer pessoa com a PSK pode visualizá-lo.';
  }

  @override
  String get map_connectToShareMarkers =>
      'Conecte-se a um dispositivo para compartilhar marcadores';

  @override
  String get map_filterNodes => 'Filtrar Nós';

  @override
  String get map_chatNodes => 'Nós de Chat';

  @override
  String get map_repeaters => 'Repetidores';

  @override
  String get map_otherNodes => 'Outros Nós';

  @override
  String get map_showOverlaps => 'Sobreposições da Chave Repeater';

  @override
  String get map_keyPrefix => 'Prefixo Chave';

  @override
  String get map_filterByKeyPrefix => 'Filtrar por prefixo-chave';

  @override
  String get map_publicKeyPrefix => 'Prefixo de chave pública';

  @override
  String get map_showDiscoveryContacts => 'Mostrar Contatos de Descoberta';

  @override
  String get map_guessedLocation => 'Localização estimada';

  @override
  String get map_lastSeenTime => 'Último Tempo de Visualização';

  @override
  String get map_sharedPin => 'Pin compartilhado';

  @override
  String get map_joinRoom => 'Junte-se à Sala';

  @override
  String get map_manageRepeater => 'Gerenciar Repetidor';

  @override
  String get map_tapToAdd => 'Toque nos nós para adicioná-los ao caminho.';

  @override
  String get map_runTrace => 'Executar Traçado de Caminho';

  @override
  String get map_runTraceWithReturnPath => 'Retornar ao mesmo caminho.';

  @override
  String get map_removeLast => 'Remover Último';

  @override
  String get map_pathTraceCancelled => 'Rastreamento de caminho cancelado.';

  @override
  String get time_justNow => 'Agora';

  @override
  String time_minutesAgo(int minutes) {
    return '$minutes minutos atrás';
  }

  @override
  String time_hoursAgo(int hours) {
    return '${hours}h atrás';
  }

  @override
  String time_daysAgo(int days) {
    return '$days dias atrás';
  }

  @override
  String get time_hour => 'hora';

  @override
  String get time_hours => 'horas';

  @override
  String get time_day => 'dia';

  @override
  String get time_days => 'dias';

  @override
  String get time_week => 'semana';

  @override
  String get time_weeks => 'semanas';

  @override
  String get time_month => 'mês';

  @override
  String get time_months => 'meses';

  @override
  String get time_minutes => 'minutos';

  @override
  String get time_allTime => 'Todos os tempos';

  @override
  String get dialog_disconnect => 'Desconectar';

  @override
  String get dialog_disconnectConfirm =>
      'Tem certeza de que deseja desconectar deste dispositivo?';

  @override
  String get login_repeaterLogin => 'Login ao Repetidor';

  @override
  String get login_roomLogin => 'Login de Sala';

  @override
  String get login_password => 'Senha';

  @override
  String get login_enterPassword => 'Insira a senha';

  @override
  String get login_savePassword => 'Salvar senha';

  @override
  String get login_savePasswordSubtitle =>
      'A senha será armazenada com segurança neste dispositivo.';

  @override
  String get login_repeaterDescription =>
      'Insira a senha do repetidor para acessar as configurações e o status.';

  @override
  String get login_roomDescription =>
      'Insira a senha da sala para acessar as configurações e o status.';

  @override
  String get login_login => 'Login';

  @override
  String login_attempt(int current, int max) {
    return 'Tentar $current/$max';
  }

  @override
  String login_failed(String error) {
    return 'Login falhou: $error';
  }

  @override
  String get login_failedMessage =>
      'Falha no login. A senha está incorreta ou o repetidor está inacessível.';

  @override
  String get common_reload => 'Recarregar';

  @override
  String get common_clear => 'Limpar';

  @override
  String get path_enterCustomPath => 'Insira Caminho Personalizado';

  @override
  String get path_currentPathLabel => 'Caminho atual';

  @override
  String get path_hexPrefixInstructions =>
      'Insira os prefixos hexadecimais de 2 caracteres para cada salto, separados por vírgulas.';

  @override
  String get path_hexPrefixExample =>
      'A1,F2,3C (cada nó usa o primeiro byte de sua chave pública)';

  @override
  String get path_labelHexPrefixes => 'Prefixo Hexadecimal';

  @override
  String get path_helperMaxHops =>
      'Máximo de 64 saltos. Cada prefixo tem 2 caracteres hexadecimais (1 byte)';

  @override
  String get path_selectFromContacts => 'Ou selecione de contatos:';

  @override
  String get path_noRepeatersFound =>
      'Não foram encontrados repetidores ou servidores de sala.';

  @override
  String get path_customPathsRequire =>
      'Caminhos personalizados exigem saltos intermediários que podem transmitir mensagens.';

  @override
  String path_invalidHexPrefixes(String prefixes) {
    return 'Prefixos hexadecimais inválidos: $prefixes';
  }

  @override
  String get path_tooLong =>
      'Caminho muito longo. Máximo de 64 saltos permitidos.';

  @override
  String get path_setPath => 'Definir Caminho';

  @override
  String get repeater_management => 'Gerenciamento de Repetidor';

  @override
  String get room_management => 'Gerenciamento de Servidor de Sala';

  @override
  String get repeater_guest => 'Informações sobre repetidores';

  @override
  String get room_guest => 'Informações do Servidor';

  @override
  String get repeater_managementTools => 'Ferramentas de Gerenciamento';

  @override
  String get repeater_guestTools => 'Ferramentas para hóspedes';

  @override
  String get repeater_status => 'Status';

  @override
  String get repeater_statusSubtitle =>
      'Visualizar status do repetidor, estatísticas e vizinhos.';

  @override
  String get repeater_telemetry => 'Telemetria';

  @override
  String get repeater_telemetrySubtitle =>
      'Visualizar telemetria de sensores e estatísticas do sistema';

  @override
  String get repeater_cli => 'CLI';

  @override
  String get repeater_cliSubtitle => 'Enviar comandos ao repetidor';

  @override
  String get repeater_neighbors => 'Vizinhos';

  @override
  String get repeater_neighborsSubtitle => 'Visualizar vizinhos de salto zero.';

  @override
  String get repeater_settings => 'Configurações';

  @override
  String get repeater_settingsSubtitle => 'Configurar parâmetros do repetidor';

  @override
  String get repeater_clockSyncAfterLogin =>
      'Sincronização do relógio após o login';

  @override
  String get repeater_clockSyncAfterLoginSubtitle =>
      'Enviar automaticamente a sincronização do \"relógio\" após um login bem-sucedido.';

  @override
  String get repeater_statusTitle => 'Status do Repetidor';

  @override
  String get repeater_refresh => 'Atualizar';

  @override
  String get repeater_statusRequestTimeout => 'Solicitação de status expirou.';

  @override
  String repeater_errorLoadingStatus(String error) {
    return 'Erro ao carregar o status: $error';
  }

  @override
  String get repeater_systemInformation => 'Informações do Sistema';

  @override
  String get repeater_battery => 'Bateria';

  @override
  String get repeater_clockAtLogin => 'Relógio (no login)';

  @override
  String get repeater_uptime => 'Disponibilidade';

  @override
  String get repeater_queueLength => 'Comprimento da Fila';

  @override
  String get repeater_debugFlags => 'Marcar Flags de Depuração';

  @override
  String get repeater_radioStatistics => 'Estatísticas de Rádio';

  @override
  String get repeater_lastRssi => 'Último RSSI';

  @override
  String get repeater_lastSnr => 'Último SNR';

  @override
  String get repeater_noiseFloor => 'Nível de Ruído';

  @override
  String get repeater_txAirtime => 'TX Airtime';

  @override
  String get repeater_rxAirtime => 'RX Airtime';

  @override
  String get repeater_packetStatistics => 'Estatísticas de Pacote';

  @override
  String get repeater_sent => 'Enviado';

  @override
  String get repeater_received => 'Recebido';

  @override
  String get repeater_duplicates => 'Duplicatas';

  @override
  String repeater_daysHoursMinsSecs(
    int days,
    int hours,
    int minutes,
    int seconds,
  ) {
    return '$days dias ${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String repeater_packetTxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundação: $flood, Direto: $direct';
  }

  @override
  String repeater_packetRxTotal(int total, String flood, String direct) {
    return 'Total: $total, Inundação: $flood, Direto: $direct';
  }

  @override
  String repeater_duplicatesFloodDirect(String flood, String direct) {
    return 'Inundação: $flood, Direto: $direct';
  }

  @override
  String repeater_duplicatesTotal(int total) {
    return 'Total: $total';
  }

  @override
  String get repeater_settingsTitle => 'Configurações do Repetidor';

  @override
  String get repeater_basicSettings => 'Configurações Básicas';

  @override
  String get repeater_repeaterName => 'Nome do Repetidor';

  @override
  String get repeater_repeaterNameHelper => 'Exibir nome para este repetidor';

  @override
  String get repeater_adminPassword => 'Senha de Administrador';

  @override
  String get repeater_adminPasswordHelper => 'Acesso completo de senha';

  @override
  String get repeater_guestPassword => 'Senha de convidado';

  @override
  String get repeater_guestPasswordHelper =>
      'Acesso com senha de leitura somente';

  @override
  String get repeater_radioSettings => 'Configurações de Rádio';

  @override
  String get repeater_frequencyMhz => 'Frequência (MHz)';

  @override
  String get repeater_frequencyHelper => '300-2500 MHz';

  @override
  String get repeater_txPower => 'TX Power';

  @override
  String get repeater_txPowerHelper => '-9 – 30 dBm';

  @override
  String get repeater_bandwidth => 'Largura de banda';

  @override
  String get repeater_spreadingFactor => 'Fator de Dispersão';

  @override
  String get repeater_codingRate => 'Taxa de Codificação';

  @override
  String get repeater_locationSettings => 'Configurações de Localização';

  @override
  String get repeater_latitude => 'Latitude';

  @override
  String get repeater_latitudeHelper => 'Graus decimais (por exemplo, 37,7749)';

  @override
  String get repeater_longitude => 'Longitude';

  @override
  String get repeater_longitudeHelper =>
      'Graus decimais (por exemplo, -122,4194)';

  @override
  String get repeater_features => 'Recursos';

  @override
  String get repeater_packetForwarding => 'Encaminhamento de Pacotes';

  @override
  String get repeater_packetForwardingSubtitle =>
      'Habilitar o repetidor para encaminhar pacotes';

  @override
  String get repeater_guestAccess => 'Acesso de Convidado';

  @override
  String get repeater_guestAccessSubtitle =>
      'Permitir acesso de convidado somente leitura';

  @override
  String get repeater_privacyMode => 'Modo de Privacidade';

  @override
  String get repeater_privacyModeSubtitle =>
      'Esconder nome/localização em anúncios';

  @override
  String get repeater_advertisementSettings => 'Configurações de Anúncios';

  @override
  String get repeater_localAdvertInterval => 'Intervalo de Anúncio Local';

  @override
  String repeater_localAdvertIntervalMinutes(int minutes) {
    return '$minutes minutos';
  }

  @override
  String get repeater_floodAdvertInterval =>
      'Intervalo de Anúncio de Inundação';

  @override
  String repeater_floodAdvertIntervalHours(int hours) {
    return '$hours horas';
  }

  @override
  String get repeater_encryptedAdvertInterval =>
      'Intervalo de Anúncio Criptografado';

  @override
  String get repeater_dangerZone => 'Zona de Perigo';

  @override
  String get repeater_rebootRepeater => 'Reiniciar Repetidor';

  @override
  String get repeater_rebootRepeaterSubtitle =>
      'Reiniciar o dispositivo repetidor';

  @override
  String get repeater_rebootRepeaterConfirm =>
      'Tem certeza de que deseja reiniciar este repetidor?';

  @override
  String get repeater_regenerateIdentityKey => 'Gerar Chave de Identidade';

  @override
  String get repeater_regenerateIdentityKeySubtitle =>
      'Gerar nova chave pública/privada';

  @override
  String get repeater_regenerateIdentityKeyConfirm =>
      'Isso gerará uma nova identidade para o repetidor. Continuar?';

  @override
  String get repeater_eraseFileSystem => 'Excluir Sistema de Arquivos';

  @override
  String get repeater_eraseFileSystemSubtitle =>
      'Formatar o sistema de arquivos do repetidor';

  @override
  String get repeater_eraseFileSystemConfirm =>
      'AVISO: Isso apagará todos os dados no repetidor. Isso não pode ser desfeito!';

  @override
  String get repeater_eraseSerialOnly =>
      'Apagar está disponível apenas via console serial.';

  @override
  String repeater_commandSent(String command) {
    return 'Comando enviado: $command';
  }

  @override
  String repeater_errorSendingCommand(String error) {
    return 'Erro ao enviar comando: $error';
  }

  @override
  String get repeater_confirm => 'Confirmar';

  @override
  String get repeater_settingsSaved => 'Configurações salvas com sucesso';

  @override
  String repeater_errorSavingSettings(String error) {
    return 'Erro ao salvar as configurações: $error';
  }

  @override
  String get repeater_refreshBasicSettings => 'Atualizar Configurações Básicas';

  @override
  String get repeater_refreshRadioSettings =>
      'Atualizar Configurações de Rádio';

  @override
  String get repeater_refreshTxPower => 'Atualizar TX de energia';

  @override
  String get repeater_refreshLocationSettings =>
      'Atualizar Configurações de Localização';

  @override
  String get repeater_refreshPacketForwarding =>
      'Atualizar Roteamento de Pacotes';

  @override
  String get repeater_refreshGuestAccess => 'Atualizar Acesso de Convidados';

  @override
  String get repeater_refreshPrivacyMode => 'Atualizar Modo Privacidade';

  @override
  String get repeater_refreshAdvertisementSettings =>
      'Atualizar Configurações do Anúncio';

  @override
  String repeater_refreshed(String label) {
    return '$label atualizado';
  }

  @override
  String repeater_errorRefreshing(String label) {
    return 'Erro ao atualizar $label';
  }

  @override
  String get repeater_cliTitle => 'Repetidor CLI';

  @override
  String get repeater_debugNextCommand => 'Depurar Próximo Comando';

  @override
  String get repeater_commandHelp => 'Ajuda';

  @override
  String get repeater_clearHistory => 'Limpar Histórico';

  @override
  String get repeater_noCommandsSent => 'Ainda não foram enviadas comandos.';

  @override
  String get repeater_typeCommandOrUseQuick =>
      'Digite um comando abaixo ou use comandos rápidos';

  @override
  String get repeater_enterCommandHint => 'Insira o comando...';

  @override
  String get repeater_previousCommand => 'Comando anterior';

  @override
  String get repeater_nextCommand => 'Próxima ação';

  @override
  String get repeater_enterCommandFirst => 'Insira um comando primeiro';

  @override
  String get repeater_cliCommandFrameTitle => 'Frame de Comando CLI';

  @override
  String repeater_cliCommandError(String error) {
    return 'Erro: $error';
  }

  @override
  String get repeater_cliQuickGetName => 'Obter Nome';

  @override
  String get repeater_cliQuickGetRadio => 'Obter Rádio';

  @override
  String get repeater_cliQuickGetTx => 'Obter TX';

  @override
  String get repeater_cliQuickNeighbors => 'Vizinhos';

  @override
  String get repeater_cliQuickVersion => 'Versão';

  @override
  String get repeater_cliQuickAdvertise => 'Anunciar';

  @override
  String get repeater_cliQuickClock => 'Relógio';

  @override
  String get repeater_cliQuickClockSync => 'Sincronização do Relógio';

  @override
  String get repeater_cliQuickDiscovery => 'Descobrir Vizinhos';

  @override
  String get repeater_cliHelpAdvert => 'Envia um pacote de anúncios';

  @override
  String get repeater_cliHelpReboot =>
      'Reinicia o dispositivo. (note, você pode obter \'Timeout\' que é normal)';

  @override
  String get repeater_cliHelpClock =>
      'Exibe a hora atual de cada dispositivo, de acordo com o relógio do dispositivo.';

  @override
  String get repeater_cliHelpPassword =>
      'Define uma nova senha de administrador para o dispositivo.';

  @override
  String get repeater_cliHelpVersion =>
      'Mostra a versão do dispositivo e a data de construção do firmware.';

  @override
  String get repeater_cliHelpClearStats =>
      'Reseta vários contadores de estatísticas para zero.';

  @override
  String get repeater_cliHelpSetAf => 'Define o fator de tempo de ar.';

  @override
  String get repeater_cliHelpSetTx =>
      'Define a potência de transmissão LoRa em dBm (redefinir para aplicar).';

  @override
  String get repeater_cliHelpSetRepeat =>
      'Habilita ou desabilita o papel do repetidor para este nó.';

  @override
  String get repeater_cliHelpSetAllowReadOnly =>
      '(Servidor de sala) Se \'ligado\', então o login com senha em branco será permitido, mas não poderá Postar na sala. (apenas ler).';

  @override
  String get repeater_cliHelpSetFloodMax =>
      'Define o número máximo de saltos de pacotes de inundação de entrada (se for >= máximo, o pacote não é encaminhado)';

  @override
  String get repeater_cliHelpSetIntThresh =>
      'Define o Limite de Interferência (em dB). O valor padrão é 14. Defina como 0 para desativar a detecção de interferência de canal.';

  @override
  String get repeater_cliHelpSetAgcResetInterval =>
      'Define o intervalo para resetar o Controlador de Ganho Automático. Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetMultiAcks =>
      'Habilita ou desabilita a funcionalidade de \"double ACKs\".';

  @override
  String get repeater_cliHelpSetAdvertInterval =>
      'Define o intervalo do timer em minutos para enviar um pacote de anúncio local (sem salto). Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetFloodAdvertInterval =>
      'Define o intervalo do timer em horas para enviar um pacote de anúncio em massa. Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetGuestPassword =>
      'Define/atualiza a senha do convidado. (para repetidores, os logins de convidados podem enviar a solicitação \"Obter Estatísticas\")';

  @override
  String get repeater_cliHelpSetName => 'Define o nome do anúncio.';

  @override
  String get repeater_cliHelpSetLat =>
      'Define a latitude do mapa de anúncios. (graus decimais)';

  @override
  String get repeater_cliHelpSetLon =>
      'Define a longitude do mapa de anúncios. (graus decimais)';

  @override
  String get repeater_cliHelpSetRadio =>
      'Define completamente novos parâmetros de rádio e salva nas preferências. Requer um comando \"reboot\" para aplicar.';

  @override
  String get repeater_cliHelpSetRxDelay =>
      'Configurações (experimental) base (deve ser > 1 para efeito) para aplicar um pequeno atraso aos pacotes recebidos, com base na força do sinal/pontuação. Defina como 0 para desativar.';

  @override
  String get repeater_cliHelpSetTxDelay =>
      'Define um fator multiplicado com o tempo-em-ar para um pacote de modo de inundação e com um sistema de slot aleatório, para atrasar seu encaminhamento. (para diminuir a probabilidade de colisões)';

  @override
  String get repeater_cliHelpSetDirectTxDelay =>
      'Igual a txdelay, mas para aplicar um atraso aleatório à encaminhamento de pacotes em modo direto.';

  @override
  String get repeater_cliHelpSetBridgeEnabled => 'Ativar/Desativar ponte.';

  @override
  String get repeater_cliHelpSetBridgeDelay =>
      'Definir atraso antes de retransmitir pacotes.';

  @override
  String get repeater_cliHelpSetBridgeSource =>
      'Escolha se a ponte retransmitirá pacotes recebidos ou pacotes transmitidos.';

  @override
  String get repeater_cliHelpSetBridgeBaud =>
      'Definir a taxa de baud para as pontes rs232.';

  @override
  String get repeater_cliHelpSetBridgeSecret =>
      'Definir segredo de ponte para pontes espnow.';

  @override
  String get repeater_cliHelpSetAdcMultiplier =>
      'Define um fator personalizado para ajustar a voltagem de bateria relatada (apenas suportado em placas selecionadas).';

  @override
  String get repeater_cliHelpTempRadio =>
      'Define parâmetros de rádio temporários para o número especificado de minutos, revertendo para os parâmetros de rádio originais posteriormente. (não salva nas preferências).';

  @override
  String get repeater_cliHelpSetPerm =>
      'Modifica o ACL. Remove a entrada correspondente (pelo prefixo de pubkey) se \"permissions\" for zero. Adiciona uma nova entrada se o pubkey-hex for de comprimento total e não estiver atualmente no ACL. Atualiza a entrada por correspondência de prefixo de pubkey. Os bits de permissão variam conforme o papel do firmware, mas os 2 bits inferiores são: 0 (Guest), 1 (Read only), 2 (Read write), 3 (Admin)';

  @override
  String get repeater_cliHelpGetBridgeType =>
      'Obtém tipo de ponte nenhum, rs232, espnow';

  @override
  String get repeater_cliHelpLogStart =>
      'Inicia o registro de pacotes no sistema de arquivos.';

  @override
  String get repeater_cliHelpLogStop =>
      'Para interromper o registro de pacotes no sistema de arquivos.';

  @override
  String get repeater_cliHelpLogErase =>
      'Apaga os logs do pacote do sistema de arquivos.';

  @override
  String get repeater_cliHelpNeighbors =>
      'Mostra uma lista de outros nós de repetição ouvidos através de anúncios zero-hop. Cada linha é id-prefixo-hexadecimal:timestamp:snr-vezes-4';

  @override
  String get repeater_cliHelpNeighborRemove =>
      'Remove a primeira entrada correspondente (por prefixo de chave pública (hexadecimal)) da lista de vizinhos.';

  @override
  String get repeater_cliHelpRegion =>
      '(série apenas) Lista todas as regiões definidas e as permissões de inundação atuais.';

  @override
  String get repeater_cliHelpRegionLoad =>
      'NOTA: isto é uma invocação multi-comando especial. Cada comando subsequente é um nome de região (indentado com espaços para indicar a hierarquia pai, com um espaço mínimo). Terminado enviando uma linha em branco/comando.';

  @override
  String get repeater_cliHelpRegionGet =>
      'Procura região com o prefixo de nome dado (ou \"\\\" para o âmbito global). Responde com \"-> nome-região (nome-pai) \'F\'\"';

  @override
  String get repeater_cliHelpRegionPut =>
      'Adiciona ou atualiza uma definição de região com o nome fornecido.';

  @override
  String get repeater_cliHelpRegionRemove =>
      'Remove uma definição de região com o nome fornecido. (deve corresponder exatamente e não ter regiões filhas)';

  @override
  String get repeater_cliHelpRegionAllowf =>
      'Define a permissão de \'F\'luido para a região especificada. (\'\' para o escopo global/legado)';

  @override
  String get repeater_cliHelpRegionDenyf =>
      'Remove a permissão de \"F\"luido para a região especificada. (NOTA: neste momento NÃO é aconselhável usar isso no escopo global/legado!!)';

  @override
  String get repeater_cliHelpRegionHome =>
      'Responde com a região \'home\' atual. (Observação aplicada em nenhum lugar ainda, reservado para o futuro)';

  @override
  String get repeater_cliHelpRegionHomeSet => 'Define a região \'casa\'.';

  @override
  String get repeater_cliHelpRegionSave =>
      'Persiste a lista/mapa de regiões para o armazenamento.';

  @override
  String get repeater_cliHelpGps =>
      'Mostra o status do GPS. Quando o GPS estiver desligado, responde apenas com \"off\", se estiver ligado, responde com \"on\", status, fix, contagem de satélites.';

  @override
  String get repeater_cliHelpGpsOnOff => 'Alterna o estado de energia do GPS.';

  @override
  String get repeater_cliHelpGpsSync =>
      'Sincroniza o tempo do nó com o relógio GPS.';

  @override
  String get repeater_cliHelpGpsSetLoc =>
      'Define a posição do nó para coordenadas GPS e salvar preferências.';

  @override
  String get repeater_cliHelpGpsAdvert =>
      'Define a configuração de anúncio da localização do nó:\n- nenhum: não incluir a localização nos anúncios\n- compartilhar: compartilhar a localização GPS (do SensorManager)\n- preferências: anunciar a localização armazenada nas preferências';

  @override
  String get repeater_cliHelpGpsAdvertSet =>
      'Define a configuração do anúncio de localização.';

  @override
  String get repeater_commandsListTitle => 'Lista de Comandos';

  @override
  String get repeater_commandsListNote =>
      'NOTA: para os diversos comandos \"set...\", também existe um comando \"get...\".';

  @override
  String get repeater_general => 'Geral';

  @override
  String get repeater_settingsCategory => 'Configurações';

  @override
  String get repeater_bridge => 'Ponte';

  @override
  String get repeater_logging => 'Registrar';

  @override
  String get repeater_neighborsRepeaterOnly => 'Vizinhos (apenas repetidor)';

  @override
  String get repeater_regionManagementRepeaterOnly =>
      'Gerenciamento de Região (Apenas Repetidor)';

  @override
  String get repeater_regionNote =>
      'Os comandos de região foram introduzidos para gerenciar definições e permissões de região.';

  @override
  String get repeater_gpsManagement => 'Gerenciamento GPS';

  @override
  String get repeater_gpsNote =>
      'O comando GPS foi introduzido para gerenciar tópicos relacionados à localização.';

  @override
  String get telemetry_receivedData => 'Dados de Telemetria Recebidos';

  @override
  String get telemetry_requestTimeout =>
      'Solicitação de telemetria expirou o tempo.';

  @override
  String telemetry_errorLoading(String error) {
    return 'Erro ao carregar a telemetria: $error';
  }

  @override
  String get telemetry_noData => 'Não estão disponíveis dados de telemetria.';

  @override
  String telemetry_channelTitle(int channel) {
    return 'Canal $channel';
  }

  @override
  String get telemetry_batteryLabel => 'Bateria';

  @override
  String get telemetry_voltageLabel => 'Tensão';

  @override
  String get telemetry_mcuTemperatureLabel => 'Temperatura do MCU';

  @override
  String get telemetry_temperatureLabel => 'Temperatura';

  @override
  String get telemetry_currentLabel => 'Atual';

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
  String get neighbors_receivedData => 'Dados dos Vizinhos Recebidos';

  @override
  String get neighbors_requestTimedOut =>
      'Vizinhos solicitam tempo limite esgotado.';

  @override
  String neighbors_errorLoading(String error) {
    return 'Erro ao carregar vizinhos: $error';
  }

  @override
  String get neighbors_repeatersNeighbors => 'Repetidores Vizinhos';

  @override
  String get neighbors_noData => 'Não estão disponíveis dados de vizinhos.';

  @override
  String neighbors_unknownContact(String pubkey) {
    return '$pubkey Desconhecido';
  }

  @override
  String neighbors_heardAgo(String time) {
    return 'Ouvido: $time atrás';
  }

  @override
  String get channelPath_title => 'Rótulo de Caminho de Pacote';

  @override
  String get channelPath_viewMap => 'Ver mapa';

  @override
  String get channelPath_otherObservedPaths => 'Outros Caminhos Observados';

  @override
  String get channelPath_repeaterHops => 'Saltos do Repetidor';

  @override
  String get channelPath_noHopDetails =>
      'Os detalhes do pacote não estão disponíveis.';

  @override
  String get channelPath_messageDetails => 'Detalhes da Mensagem';

  @override
  String get channelPath_senderLabel => 'Remetente';

  @override
  String get channelPath_timeLabel => 'Tempo';

  @override
  String get channelPath_repeatsLabel => 'Repete';

  @override
  String channelPath_pathLabel(int index) {
    return 'Caminho $index';
  }

  @override
  String get channelPath_observedLabel => 'Observado';

  @override
  String channelPath_observedPathTitle(int index, String hops) {
    return 'Rastreamento observado $index • $hops';
  }

  @override
  String get channelPath_noLocationData => 'Não há dados de localização.';

  @override
  String channelPath_timeWithDate(int day, int month, String time) {
    return '$day/$month $time';
  }

  @override
  String channelPath_timeOnly(String time) {
    return '$time';
  }

  @override
  String get channelPath_unknownPath => 'Desconhecido';

  @override
  String get channelPath_floodPath => 'Inundação';

  @override
  String get channelPath_directPath => 'Salvar';

  @override
  String channelPath_observedZeroOf(int total) {
    return '0 de $total saltos';
  }

  @override
  String channelPath_observedSomeOf(int observed, int total) {
    return '$observed de $total saltos';
  }

  @override
  String get channelPath_mapTitle => 'Mapa de Caminhos';

  @override
  String get channelPath_noRepeaterLocations =>
      'Não estão disponíveis localizações de repetidores para este caminho.';

  @override
  String channelPath_primaryPath(int index) {
    return 'Caminho $index (Primário)';
  }

  @override
  String get channelPath_pathLabelTitle => 'Caminho';

  @override
  String get channelPath_observedPathHeader => 'Rastreamento Observado';

  @override
  String channelPath_selectedPathLabel(String label, String prefixes) {
    return '$label • $prefixes';
  }

  @override
  String get channelPath_noHopDetailsAvailable =>
      'Não estão disponíveis detalhes de voo para este pacote.';

  @override
  String get channelPath_unknownRepeater => 'Repetidor Desconhecido';

  @override
  String get community_title => 'Comunidade';

  @override
  String get community_create => 'Criar Comunidade';

  @override
  String get community_createDesc =>
      'Crie uma nova comunidade e compartilhe via código QR.';

  @override
  String get community_join => 'Junte-se';

  @override
  String get community_joinTitle => 'Junte-se à Comunidade';

  @override
  String community_joinConfirmation(String name) {
    return 'Você gostaria de se juntar à comunidade \"$name\"?';
  }

  @override
  String get community_scanQr => 'Digitalizar a QR Code da Comunidade';

  @override
  String get community_scanInstructions =>
      'Aponte a câmera para um código QR da comunidade';

  @override
  String get community_showQr => 'Mostrar Código QR';

  @override
  String get community_publicChannel => 'Comunidade Pública';

  @override
  String get community_hashtagChannel => 'Hashtag da Comunidade';

  @override
  String get community_name => 'Nome da Comunidade';

  @override
  String get community_enterName => 'Insira o nome da comunidade';

  @override
  String community_created(String name) {
    return 'Comunidade \"$name\" criada';
  }

  @override
  String community_joined(String name) {
    return 'Juntou-se à comunidade \"$name\"';
  }

  @override
  String get community_qrTitle => 'Partilhar Comunidade';

  @override
  String community_qrInstructions(String name) {
    return 'Escanear este código QR para juntar-se a $name';
  }

  @override
  String get community_hashtagPrivacyHint =>
      'Os canais de hashtag da comunidade só podem ser acessados por membros da comunidade';

  @override
  String get community_invalidQrCode => 'Código QR da comunidade inválido';

  @override
  String get community_alreadyMember => 'Já é Membro';

  @override
  String community_alreadyMemberMessage(String name) {
    return 'Você já é membro de \"$name\".';
  }

  @override
  String get community_addPublicChannel =>
      'Adicionar Canal Público da Comunidade';

  @override
  String get community_addPublicChannelHint =>
      'Adicionar automaticamente o canal público para esta comunidade';

  @override
  String get community_noCommunities =>
      'Ainda não foram adicionadas comunidades.';

  @override
  String get community_scanOrCreate =>
      'Escaneie um código QR ou crie uma comunidade para começar.';

  @override
  String get community_manageCommunities => 'Gerenciar Comunidades';

  @override
  String get community_delete => 'Deixar Comunidade';

  @override
  String community_deleteConfirm(String name) {
    return 'Sair de \"$name\"?';
  }

  @override
  String community_deleteChannelsWarning(int count) {
    return 'Isso também excluirá $count canal/canais e suas mensagens.';
  }

  @override
  String community_deleted(String name) {
    return 'Saiu da comunidade \"$name\"';
  }

  @override
  String get community_regenerateSecret => 'Regenerar Senha Segura';

  @override
  String community_regenerateSecretConfirm(String name) {
    return 'Regenerar a chave secreta para \"$name\"? Todos os membros precisarão escanear o novo código QR para continuar a comunicação.';
  }

  @override
  String get community_regenerate => 'Regenerar';

  @override
  String community_secretRegenerated(String name) {
    return 'Senha secreta regenerada para \"$name\"';
  }

  @override
  String get community_updateSecret => 'Atualizar Segredo';

  @override
  String community_secretUpdated(String name) {
    return 'Segredo atualizado para \"$name\"';
  }

  @override
  String community_scanToUpdateSecret(String name) {
    return 'Scanar o novo código QR para atualizar o segredo para \"$name\"\n\n\n+++++';
  }

  @override
  String get community_addHashtagChannel => 'Adicionar Hashtag da Comunidade';

  @override
  String get community_addHashtagChannelDesc =>
      'Adicionar um canal de hashtag para esta comunidade';

  @override
  String get community_selectCommunity => 'Selecione Comunidade';

  @override
  String get community_regularHashtag => 'Hashtag Regular';

  @override
  String get community_regularHashtagDesc =>
      'Hashtag público (qualquer pessoa pode participar)';

  @override
  String get community_communityHashtag => 'Hashtag da Comunidade';

  @override
  String get community_communityHashtagDesc =>
      'Apenas para membros da comunidade';

  @override
  String community_forCommunity(String name) {
    return 'Para $name';
  }

  @override
  String get listFilter_tooltip => 'Filtrar e ordenar';

  @override
  String get listFilter_sortBy => 'Ordenar por';

  @override
  String get listFilter_latestMessages => 'Últimas mensagens';

  @override
  String get listFilter_heardRecently => 'Ouvido recentemente';

  @override
  String get listFilter_az => 'A-Z';

  @override
  String get listFilter_filters => 'Filtros';

  @override
  String get listFilter_source => 'Origem';

  @override
  String get listFilter_saved => 'Salvos';

  @override
  String get listFilter_discovered => 'Descobertos';

  @override
  String get listFilter_all => 'Tudo';

  @override
  String get listFilter_favorites => 'Favoritos';

  @override
  String get listFilter_addToFavorites => 'Adicionar aos favoritos';

  @override
  String get listFilter_removeFromFavorites => 'Remover da lista de favoritos';

  @override
  String get listFilter_users => 'Usuários';

  @override
  String get listFilter_repeaters => 'Repetidores';

  @override
  String get listFilter_roomServers => 'Servidores de sala';

  @override
  String get listFilter_unreadOnly => 'Apenas não lido';

  @override
  String get listFilter_newGroup => 'Novo grupo';

  @override
  String get pathTrace_you => 'Você';

  @override
  String get pathTrace_failed => 'Falha no rastreamento de caminho.';

  @override
  String get pathTrace_notAvailable => 'Traçado de caminho não disponível.';

  @override
  String get pathTrace_refreshTooltip => 'Atualizar Path Trace.';

  @override
  String get pathTrace_someHopsNoLocation =>
      'Um ou mais dos lúpulos estão sem localização!';

  @override
  String get pathTrace_clearTooltip => 'Limpar caminho';

  @override
  String get losSelectStartEnd => 'Selecione nós iniciais e finais para LOS.';

  @override
  String losRunFailed(String error) {
    return 'Falha na verificação da linha de visão: $error';
  }

  @override
  String get losClearAllPoints => 'Limpe todos os pontos';

  @override
  String get losRunToViewElevationProfile =>
      'Execute o LOS para visualizar o perfil de elevação';

  @override
  String get losMenuTitle => 'Menu LOS';

  @override
  String get losMenuSubtitle =>
      'Toque nos nós ou mantenha pressionado o mapa para obter pontos personalizados';

  @override
  String get losShowDisplayNodes => 'Mostrar nós de exibição';

  @override
  String get losCustomPoints => 'Pontos personalizados';

  @override
  String losCustomPointLabel(int index) {
    return '$index personalizado';
  }

  @override
  String get losPointA => 'Ponto A';

  @override
  String get losPointB => 'Ponto B';

  @override
  String losAntennaA(String value, String unit) {
    return 'Antena A: $value $unit';
  }

  @override
  String losAntennaB(String value, String unit) {
    return 'Antena B: $value $unit';
  }

  @override
  String get losRun => 'Executar LOS';

  @override
  String get losNoElevationData => 'Sem dados de elevação';

  @override
  String losProfileClear(
    String distance,
    String distanceUnit,
    String clearance,
    String heightUnit,
  ) {
    return '$distance $distanceUnit, limpar LOS, liberação mínima $clearance $heightUnit';
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
  String get losStatusChecking => 'LOS: verificando...';

  @override
  String get losStatusNoData => 'LOS: sem dados';

  @override
  String losStatusSummary(int clear, int total, int blocked, int unknown) {
    return 'LOS: $clear/$total limpo, $blocked bloqueado, $unknown desconhecido';
  }

  @override
  String get losErrorElevationUnavailable =>
      'Dados de elevação indisponíveis para uma ou mais amostras.';

  @override
  String get losErrorInvalidInput =>
      'Dados de pontos/elevação inválidos para cálculo de LOS.';

  @override
  String get losRenameCustomPoint => 'Renomear ponto personalizado';

  @override
  String get losPointName => 'Nome do ponto';

  @override
  String get losShowPanelTooltip => 'Mostrar painel LOS';

  @override
  String get losHidePanelTooltip => 'Ocultar painel LOS';

  @override
  String get losElevationAttribution =>
      'Dados de elevação: Open-Meteo (CC BY 4.0)';

  @override
  String get losLegendRadioHorizon => 'Horizonte de rádio';

  @override
  String get losLegendLosBeam => 'Linha de visada';

  @override
  String get losLegendTerrain => 'Terreno';

  @override
  String get losFrequencyLabel => 'Frequência';

  @override
  String get losFrequencyInfoTooltip => 'Ver detalhes do cálculo';

  @override
  String get losFrequencyDialogTitle => 'Cálculo do horizonte de rádio';

  @override
  String losFrequencyDialogDescription(
    double baselineK,
    double baselineFreq,
    double frequencyMHz,
    double kFactor,
  ) {
    return 'Começando em k=$baselineK em $baselineFreq MHz, o cálculo ajusta o fator k para a banda atual de $frequencyMHz MHz, que define o limite do horizonte de rádio curvo.';
  }

  @override
  String get contacts_pathTrace => 'Traçado de Caminho';

  @override
  String get contacts_ping => 'Pingar';

  @override
  String get contacts_repeaterPathTrace => 'Traçar caminho para repetidor';

  @override
  String get contacts_repeaterPing => 'Pingar repetidor';

  @override
  String get contacts_roomPathTrace => 'Traçar caminho para o servidor da sala';

  @override
  String get contacts_roomPing => 'Pingar servidor da sala';

  @override
  String get contacts_chatTraceRoute => 'Rastrear rota do caminho';

  @override
  String contacts_pathTraceTo(String name) {
    return 'Rastrear rota para $name';
  }

  @override
  String get contacts_clipboardEmpty => 'Área de Transferência Está Vazia.';

  @override
  String get contacts_invalidAdvertFormat => 'Dados de Contato Inválidos';

  @override
  String get contacts_contactImported => 'Contato foi importado.';

  @override
  String get contacts_contactImportFailed => 'Contato falhou ao ser importado.';

  @override
  String contacts_alreadyInContacts(String name) {
    return '$name já está nos seus contatos.';
  }

  @override
  String get contacts_zeroHopAdvert => 'Anúncio Zero Hop';

  @override
  String get contacts_floodAdvert => 'Anúncio de Inundação';

  @override
  String get contacts_copyAdvertToClipboard =>
      'Copiar Anúncio para Área de Transferência';

  @override
  String get contacts_addContactFromClipboard =>
      'Adicionar Contato da Área de Transferência';

  @override
  String get contacts_ShareContact =>
      'Copiar contato para Área de Transferência';

  @override
  String get contacts_ShareContactZeroHop => 'Compartilhar contato por anúncio';

  @override
  String get contacts_zeroHopContactAdvertSent => 'Enviou contato por anúncio.';

  @override
  String get contacts_zeroHopContactAdvertFailed => 'Falha ao enviar contato.';

  @override
  String get contacts_contactAdvertCopied =>
      'Anúncio copiado para a Área de Transferência.';

  @override
  String get contacts_contactAdvertCopyFailed =>
      'Cópia do anúncio para a Área de Transferência falhou.';

  @override
  String get contacts_addContact => 'Adicionar contato';

  @override
  String get contacts_scanQrCode => 'Escanear QR do contato';

  @override
  String get contacts_scanQrCodeDesc =>
      'Escaneie o código QR de um contato no app MeshCore';

  @override
  String get contacts_enterIdHash => 'Inserir contato manualmente';

  @override
  String get contacts_enterIdHashDesc =>
      'Cole um anúncio de contato ou um link meshcore://';

  @override
  String get contacts_advertHint => 'meshcore://... ou chave pública em hex';

  @override
  String get contacts_import => 'Importar';

  @override
  String get contacts_scanContactInstructions =>
      'Escaneie o código QR de um contato MeshCore';

  @override
  String get notification_activityTitle => 'Atividade MeshCore';

  @override
  String notification_messagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensagens',
      one: 'mensagem',
    );
    return '$count $_temp0';
  }

  @override
  String notification_channelMessagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'mensagens de canal',
      one: 'mensagem de canal',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newNodesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'novos nós',
      one: 'novo nó',
    );
    return '$count $_temp0';
  }

  @override
  String notification_newTypeDiscovered(String contactType) {
    return 'Novo $contactType descoberto';
  }

  @override
  String get notification_receivedNewMessage => 'Nova mensagem recebida';

  @override
  String get settings_gpxExportRepeaters =>
      'Exportar repetidores / servidor de sala para GPX';

  @override
  String get settings_gpxExportRepeatersSubtitle =>
      'Exporta repetidores / roomserver com localização para arquivo GPX.';

  @override
  String get settings_gpxExportContacts => 'Exportar companheiros para GPX';

  @override
  String get settings_gpxExportContactsSubtitle =>
      'Exporta companheiros com uma localização para um arquivo GPX.';

  @override
  String get settings_gpxExportAll => 'Exportar todos os contatos para GPX';

  @override
  String get settings_gpxExportAllSubtitle =>
      'Exporta todos os contatos com uma localização para um arquivo GPX.';

  @override
  String get settings_gpxExportSuccess => 'Arquivo GPX exportado com sucesso.';

  @override
  String get settings_gpxExportNoContacts => 'Nenhum contato para exportar.';

  @override
  String get settings_gpxExportNotAvailable =>
      'Não suportado no seu dispositivo/SO';

  @override
  String get settings_gpxExportError => 'Ocorreu um erro ao exportar.';

  @override
  String get settings_gpxExportRepeatersRoom =>
      'Localizações do servidor de repetidor e sala';

  @override
  String get settings_gpxExportChat => 'Localizações de companheiros';

  @override
  String get settings_gpxExportAllContacts => 'Todos os locais de contatos';

  @override
  String get settings_gpxExportShareText =>
      'Dados do mapa exportados do MeshTrax';

  @override
  String get settings_gpxExportShareSubject =>
      'MeshTrax exportação de dados de mapa GPX';

  @override
  String get snrIndicator_nearByRepeaters => 'Repetidores Próximos';

  @override
  String get snrIndicator_lastSeen => 'Visto pela última vez';

  @override
  String get contactsSettings_title => 'Configurações de contatos';

  @override
  String get contactsSettings_autoAddTitle => 'Descoberta Automática';

  @override
  String get contactsSettings_otherTitle =>
      'Outras configurações relacionadas a contatos';

  @override
  String get contactsSettings_autoAddUsersTitle =>
      'Adicionar usuários automaticamente';

  @override
  String get contactsSettings_autoAddUsersSubtitle =>
      'Permitir que o companheiro adicione automaticamente os usuários descobertos.';

  @override
  String get contactsSettings_autoAddRepeatersTitle =>
      'Adicionar repetidores automaticamente';

  @override
  String get contactsSettings_autoAddRepeatersSubtitle =>
      'Permitir que o companheiro adicione automaticamente os repetidores descobertos.';

  @override
  String get contactsSettings_autoAddRoomServersTitle =>
      'Adicionar automaticamente servidores de sala';

  @override
  String get contactsSettings_autoAddRoomServersSubtitle =>
      'Permitir que o companheiro adicione automaticamente os servidores de salas descobertos.';

  @override
  String get contactsSettings_autoAddSensorsTitle =>
      'Adicionar sensores automaticamente';

  @override
  String get contactsSettings_autoAddSensorsSubtitle =>
      'Permitir que o companheiro adicione automaticamente sensores descobertos.';

  @override
  String get contactsSettings_overwriteOldestTitle =>
      'Sobrescrever o Mais Antigo';

  @override
  String get contactsSettings_overwriteOldestSubtitle =>
      'Quando a lista de contatos estiver cheia, o contato mais antigo não favoritado será substituído.';

  @override
  String get discoveredContacts_Title => 'Contatos Descobertos';

  @override
  String get discoveredContacts_noMatching => 'Nenhum contato correspondente';

  @override
  String get listFilter_searchHint => 'Pesquisar...';

  @override
  String get discoveredContacts_searchHint => 'Pesquisar contatos descobertos';

  @override
  String get discoveredContacts_contactAdded => 'Contato adicionado';

  @override
  String get discoveredContacts_addContact => 'Adicionar Contato';

  @override
  String get discoveredContacts_copyContact =>
      'Copiar Contato para a área de transferência';

  @override
  String get discoveredContacts_deleteContact => 'Excluir Contato';

  @override
  String get discoveredContacts_deleteContactAll =>
      'Excluir Todos os Contatos Descobertos';

  @override
  String get discoveredContacts_deleteContactAllContent =>
      'Tem certeza de que deseja excluir todos os contatos descobertos?';

  @override
  String get chat_sendCooldown =>
      'Por favor, aguarde um momento antes de reenviar.';

  @override
  String get chat_notConnected =>
      'Não conectado a um rádio. Mensagem não enviada.';

  @override
  String get appSettings_jumpToOldestUnread =>
      'Vá para a mensagem mais antiga não lida';

  @override
  String get appSettings_jumpToOldestUnreadSubtitle =>
      'Ao abrir uma conversa com mensagens não lidas, role para a primeira mensagem não lida, em vez da mais recente.';

  @override
  String get appSettings_languageHu => 'Húngaro';

  @override
  String get appSettings_languageJa => 'Japonês';

  @override
  String get appSettings_languageKo => 'Coreano';

  @override
  String get radioStats_screenTitle => 'Estatísticas de rádio';

  @override
  String get radioStats_notConnected =>
      'Conecte-se a um dispositivo para visualizar estatísticas de rádio.';

  @override
  String get radioStats_firmwareTooOld =>
      'As estatísticas de rádio exigem o firmware v8 ou uma versão mais recente.';

  @override
  String get radioStats_waiting => 'Aguardando dados…';

  @override
  String radioStats_noiseFloor(int noiseDbm) {
    return 'Nível de ruído: $noiseDbm dBm';
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
    return 'Tempo de transmissão da TX (total): $seconds s';
  }

  @override
  String radioStats_rxAir(int seconds) {
    return 'Tempo de uso do RX (total): $seconds s';
  }

  @override
  String get radioStats_chartCaption =>
      'Nível de ruído (dBm) em amostras recentes.';

  @override
  String radioStats_stripNoise(int noiseDbm) {
    return 'Nível de ruído: $noiseDbm dBm';
  }

  @override
  String get radioStats_stripWaiting => 'Obtendo estatísticas de rádio…';

  @override
  String get radioStats_settingsTile => 'Estatísticas de rádio';

  @override
  String get radioStats_settingsSubtitle =>
      'Nível de ruído, RSSI, SNR e tempo de transmissão';

  @override
  String get translation_title => 'Tradução';

  @override
  String get translation_enableTitle => 'Ativar a tradução';

  @override
  String get translation_enableSubtitle =>
      'Traduzir mensagens recebidas e permitir a tradução antes do envio.';

  @override
  String get translation_composerTitle => 'Traduza antes de enviar';

  @override
  String get translation_composerSubtitle =>
      'Controla o estado padrão do ícone de tradução do compositor.';

  @override
  String get translation_targetLanguage => 'Língua-alvo';

  @override
  String get translation_useAppLanguage => 'Utilize o idioma da aplicação';

  @override
  String get translation_downloadedModelLabel => 'Modelo baixado';

  @override
  String get translation_presetModelLabel =>
      'Modelo pré-definido da Hugging Face';

  @override
  String get translation_manualUrlLabel => 'URL do modelo manual';

  @override
  String get translation_downloadModel => 'Baixar modelo';

  @override
  String get translation_downloading => 'Baixando...';

  @override
  String get translation_working => 'Trabalhando...';

  @override
  String get translation_stop => 'Pare';

  @override
  String get translation_mergingChunks =>
      'Combinando os fragmentos baixados em um único arquivo...';

  @override
  String get translation_downloadedModels => 'Modelos baixados';

  @override
  String get translation_deleteModel => 'Excluir modelo';

  @override
  String get translation_modelDownloaded => 'Modelo de tradução baixado.';

  @override
  String get translation_downloadStopped => 'Download interrompido.';

  @override
  String translation_downloadFailed(String error) {
    return 'Falha na descarga: $error';
  }

  @override
  String get translation_enterUrlFirst => 'Insira primeiro a URL do modelo.';

  @override
  String get scanner_linuxPairingShowPin => 'Mostrar PIN';

  @override
  String get scanner_linuxPairingHidePin => 'Ocultar PIN';

  @override
  String get scanner_linuxPairingPinTitle => 'PIN de emparelhamento Bluetooth';

  @override
  String scanner_linuxPairingPinPrompt(String deviceName) {
    return 'Insira o PIN para $deviceName (deixe em branco se não houver).';
  }

  @override
  String get translation_messageTranslation => 'Tradução da mensagem';

  @override
  String get translation_translateBeforeSending => 'Traduzir antes de enviar';

  @override
  String get translation_composerEnabledHint =>
      'As mensagens serão traduzidas antes de serem enviadas.';

  @override
  String get translation_composerDisabledHint =>
      'Envie mensagens no idioma original, conforme digitado.';

  @override
  String translation_translateTo(String language) {
    return 'Traduzir para $language';
  }

  @override
  String get translation_translationOptions => 'Opções de tradução';

  @override
  String get translation_systemLanguage => 'Idioma do sistema';

  @override
  String get routing_title => 'Roteamento';

  @override
  String routing_route(String route) {
    return 'Caminho salvo: $route';
  }

  @override
  String get routing_noRoute =>
      'nenhum ainda — a próxima mensagem vai por inundação e aprende um';

  @override
  String get routing_auto => 'Automático';

  @override
  String get routing_autoSubtitle =>
      'Usa o caminho salvo no rádio. Recomendado.';

  @override
  String get routing_pathfinderOn =>
      'Pathfinder ligado: tenta primeiro as rotas aprendidas';

  @override
  String get routing_flood => 'Sempre por inundação';

  @override
  String get routing_floodSubtitle =>
      'Toda mensagem vai para a rede mesh inteira';

  @override
  String get routing_custom => 'Caminho personalizado';

  @override
  String get routing_customSubtitle => 'Escolha você mesmo os repetidores';

  @override
  String get routing_forget => 'Redefinir caminho';

  @override
  String get routing_forgetDone =>
      'Caminho redefinido. A próxima mensagem vai por inundação e aprende um novo.';

  @override
  String get routing_pathfinder => 'O que o Pathfinder sabe';

  @override
  String get routing_pathfinderSubtitle =>
      'Repetidores que ouvem você e o contato, e rotas aprendidas de ida e volta';

  @override
  String get path_direct => 'Direto — sem repetidores';

  @override
  String get path_directSubtitle =>
      'Só quando o contato consegue ouvir este rádio diretamente';

  @override
  String get chat_kindFlood => 'inundação';

  @override
  String get chat_kindDirect => 'direto';

  @override
  String chat_kindRoute(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'saltos',
      one: 'salto',
    );
    return 'rota ($count $_temp0)';
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
  String get chat_statusQueued => 'Na fila';

  @override
  String get chat_statusNoRepeaterHeard =>
      'Nenhum repetidor ouviu você. Vai tentar de novo quando houver um ao alcance.';

  @override
  String chat_narrowHashNotice(String name) {
    return 'O rádio de $name envia códigos de repetidor curtos (1 byte). O Pathfinder não consegue aprender rotas até esse contato enquanto o rádio dele não usar códigos de 2 bytes.';
  }

  @override
  String chat_statusSending(String kind) {
    return 'Enviando · $kind';
  }

  @override
  String chat_statusRetrying(int attempt, int max, String kind) {
    return 'Tentando de novo · $kind · tentativa $attempt de $max';
  }

  @override
  String chat_statusDelivered(String kind, String secs) {
    return 'Entregue · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredAttempt(int attempt, String kind, String secs) {
    return 'Entregue na tentativa $attempt · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredLate(String kind, String secs) {
    return 'Entregue com atraso · $kind · $secs s';
  }

  @override
  String chat_statusDeliveredShort(String secs) {
    return 'Entregue · $secs s';
  }

  @override
  String chat_statusFailed(int attempts) {
    String _temp0 = intl.Intl.pluralLogic(
      attempts,
      locale: localeName,
      other: 'tentativas',
      one: 'tentativa',
    );
    return 'Falhou após $attempts $_temp0 · toque para reenviar';
  }

  @override
  String get chat_statusFailedShort => 'Falhou · toque para reenviar';

  @override
  String get chat_resendingByFlood => 'Reenviando por inundação';

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
  String get settings_pathGraph => 'Pathfinder (experimental)';

  @override
  String get settings_pathGraphSubtitle =>
      'Aprende rotas com tudo o que o rádio ouve e tenta primeiro as melhores quando você envia uma DM. Um ícone de caminho âmbar marca uma mensagem enviada por uma rota do Pathfinder.';

  @override
  String get map_routeAndTrace => 'Rota e rastreamento';

  @override
  String get map_pathfinderTrace => 'Rastrear ida e volta';

  @override
  String get map_pathfinderTraceSubtitle =>
      'Ida pela melhor rota do Pathfinder, volta pela melhor rota de volta';

  @override
  String get map_routeBackMirrored =>
      'Nenhuma rota de volta conhecida ainda — voltando pelo mesmo caminho';

  @override
  String get map_traceHelpTitle => 'Botões de rastreamento de caminho';

  @override
  String get map_traceHelpCustom =>
      'Digite ou escolha você mesmo os repetidores.';

  @override
  String get map_traceHelpRun =>
      'Envia um rastreamento pelos repetidores que você tocou, só de ida.';

  @override
  String get map_traceHelpThereAndBack => 'Ida e volta';

  @override
  String get map_traceHelpThereAndBackSubtitle =>
      'Envia o rastreamento e depois o traz de volta pelos mesmos repetidores, na ordem inversa.';

  @override
  String get map_traceHelpPathfinder =>
      'O Pathfinder escolhe a melhor rota passando pelos dois últimos repetidores que você tocou, e a melhor rota de volta até você. O resultado ensina ao Pathfinder quais ligações funcionam de verdade. Precisa de dois repetidores tocados.';

  @override
  String get map_traceHelpRemoveLast => 'Tira o último repetidor do caminho.';

  @override
  String get map_traceHelpCancel =>
      'Para de montar o rastreamento. Aparece antes de você tocar em qualquer repetidor.';

  @override
  String get chat_resendingByRoute => 'Reenviando pela rota definida';

  @override
  String get room_mute => 'Silenciar sala';

  @override
  String get room_unmute => 'Reativar som da sala';

  @override
  String get room_roleAdmin => 'admin';

  @override
  String get room_roleMember => 'membro';

  @override
  String get room_roleReadOnly => 'somente leitura';

  @override
  String room_clockOff(int minutes) {
    return 'O relógio da sala difere cerca de $minutes min — os horários das mensagens podem estar errados';
  }

  @override
  String get room_fixClock => 'Acertar relógio';

  @override
  String get room_clockSyncSent => 'Sincronização de relógio enviada à sala';

  @override
  String get room_readOnlyNotice =>
      'Somente leitura: a sala não aceitou sua senha, suas mensagens não chegarão aos outros membros.';

  @override
  String get room_postAnnouncement => 'Publicar aviso';

  @override
  String get room_postAnnouncementSubtitle =>
      'Enviar uma mensagem da própria sala a todos os membros';

  @override
  String get room_announcementSent => 'Aviso publicado';

  @override
  String get room_announcementFailed => 'Falha ao publicar o aviso';

  @override
  String get room_users => 'Usuários da sala';

  @override
  String get room_usersSubtitle => 'Ver admins e definir funções';

  @override
  String get room_usersAdminsNote =>
      'A sala só lista seus admins. Membros com a senha da sala não aparecem.';

  @override
  String get room_usersLoadFailed =>
      'Não foi possível carregar a lista de admins';

  @override
  String get room_setUserRole => 'Definir função';

  @override
  String get room_removeAccess => 'Remover acesso';

  @override
  String get room_removeOnlyUnknown =>
      'Este usuário não está nos seus contatos; só pode ser removido, não alterado.';

  @override
  String get room_roleUpdated => 'Função atualizada';

  @override
  String get room_roleUpdateFailed => 'Falha ao alterar a função';

  @override
  String get room_postsStored => 'Mensagens guardadas';

  @override
  String get room_postsDelivered => 'Mensagens entregues';

  @override
  String get room_reloadPosts => 'Recarregar mensagens recentes';

  @override
  String get room_reloadPostsExplain =>
      'Pede à sala para reenviar as mensagens recentes (guarda até 32). A senha da sala será solicitada. As mensagens que você já tem são mantidas.';

  @override
  String get room_reloadFailed => 'Não foi possível redefinir a sala no rádio';

  @override
  String get companionCli_title => 'Linha de comando';

  @override
  String get companionCli_settingsSubtitle =>
      'Digite comandos de texto para este rádio';

  @override
  String get companionCli_rebooting => 'Reiniciando o rádio…';

  @override
  String get companionCli_cancelled => 'Cancelado';

  @override
  String get companionCli_poweringOff => 'Desligando o rádio…';

  @override
  String get companionCli_noReply => 'Sem resposta do rádio. Tente de novo.';

  @override
  String get companionCli_powerOffTitle => 'Desligar o rádio?';

  @override
  String get companionCli_powerOffBody =>
      'Ele fica desligado até você apertar o botão dele ou conectá-lo à energia.';

  @override
  String get companionCli_powerOff => 'Desligar';

  @override
  String get companionCli_quickBoard => 'Placa';

  @override
  String get companionCli_quickWifiStatus => 'Status do Wi‑Fi';

  @override
  String get companionCli_quickWifiAddress => 'Endereço do Wi‑Fi';

  @override
  String get companionCli_helpBoard =>
      'Mostra o fabricante e o modelo da placa.';

  @override
  String get companionCli_helpReboot => 'Reinicia o rádio.';

  @override
  String get companionCli_helpPowerOff => 'Desliga o rádio.';

  @override
  String get companionCli_helpSetPin =>
      'Define o PIN de pareamento Bluetooth. Vale após reiniciar.';

  @override
  String get companionCli_helpSetTzOffset =>
      'Define as horas somadas ao UTC para o relógio na tela do próprio rádio (-12 a +14).';

  @override
  String get companionCli_helpSetTx =>
      'Define a potência de transmissão em dBm. Vale na hora.';

  @override
  String get companionCli_helpSetIntThresh =>
      'Define o limite de interferência em dB. 0 desliga a detecção de interferência.';

  @override
  String get companionCli_helpSetCad =>
      'Escuta outros rádios antes de transmitir (detecção de atividade no canal).';

  @override
  String get companionCli_helpSetRxGain =>
      'Ganho de recepção reforçado, em rádios SX126x.';

  @override
  String get companionCli_helpSetPathHashMode =>
      'Bytes por repetidor numa rota: 0 = 1 byte, 1 = 2 bytes, 2 = 3 bytes.';

  @override
  String get companionCli_helpWifiStatus =>
      'Mostra se o rádio está na rede Wi‑Fi.';

  @override
  String get companionCli_helpWifiIp =>
      'Mostra o endereço do rádio na rede Wi‑Fi.';

  @override
  String get companionCli_helpWifiSsid =>
      'Define o nome da rede Wi‑Fi. Vale após reiniciar.';

  @override
  String get companionCli_helpWifiPwd =>
      'Define a senha do Wi‑Fi. Vale após reiniciar.';

  @override
  String get companionCli_helpWifiEnabled =>
      'Liga (1) ou desliga (0) o Wi‑Fi. Vale após reiniciar.';

  @override
  String get companionCli_helpWifiClear =>
      'Esquece a rede Wi‑Fi. Vale após reiniciar.';

  @override
  String get companionCli_remoteNoReply =>
      'Sem resposta. O outro rádio precisa do firmware 1.18 ou mais recente e precisa permitir que você use a linha de comando dele.';

  @override
  String get companionCli_remoteSentNoAnswer =>
      'Enviado. Um rádio não responde a uma reinicialização nem a um desligamento.';

  @override
  String companionCli_blocked(String name, String command) {
    return '$name tentou usar a linha de comando do seu rádio: \"$command\". Não foi permitido.';
  }

  @override
  String companionCli_blockedBody(String command) {
    return 'Tentou usar a linha de comando do seu rádio: \"$command\". Não foi permitido.';
  }

  @override
  String get contact_remoteCli => 'Permitir linha de comando remota';

  @override
  String get contact_remoteCliSubtitle =>
      'Deixa este contato executar comandos no seu rádio';

  @override
  String contact_remoteCliWarningTitle(String name) {
    return 'Deixar $name controlar seu rádio?';
  }

  @override
  String contact_remoteCliWarning(String name) {
    return '$name poderá mudar as configurações do seu rádio, ver sua senha do Wi‑Fi, renomear o rádio e reiniciá-lo ou desligá-lo. Só permita para alguém em quem você confia totalmente.';
  }

  @override
  String get contact_remoteCliAllow => 'Permitir';

  @override
  String get connection_secondApp =>
      'Outro app está conectado a este rádio. Mensagens e configurações podem se misturar. Feche o outro app.';

  @override
  String get wifi_title => 'Wi‑Fi';

  @override
  String get wifi_settingsSubtitle => 'Rede, senha e conexão';

  @override
  String get wifi_use => 'Usar Wi‑Fi';

  @override
  String get wifi_networkName => 'Nome da rede';

  @override
  String get wifi_password => 'Senha';

  @override
  String get wifi_passwordUnchanged => 'Sem alteração';

  @override
  String get wifi_showPassword => 'Mostrar senha';

  @override
  String get wifi_nameMissing => 'Digite o nome da rede';

  @override
  String get wifi_nameTooLong =>
      'O nome da rede é longo demais (no máximo 32 bytes)';

  @override
  String get wifi_passwordTooLong =>
      'A senha é longa demais (no máximo 63 bytes)';

  @override
  String get wifi_savedRestart =>
      'Salvo. As mudanças de Wi‑Fi valem depois que o rádio reiniciar.';

  @override
  String get wifi_forget => 'Esquecer rede';

  @override
  String get wifi_forgetConfirm =>
      'Esquecer esta rede Wi‑Fi? O rádio deixa de usar Wi‑Fi depois de reiniciar.';

  @override
  String wifi_notAccepted(String reply) {
    return 'O rádio não aceitou isso: $reply';
  }

  @override
  String get wifi_noReply => 'Sem resposta do rádio. Tente de novo.';

  @override
  String get wifi_restartTitle => 'Reiniciar o rádio?';

  @override
  String get wifi_later => 'Depois';

  @override
  String get wifi_loadFailed =>
      'Não foi possível ler as configurações de Wi‑Fi do rádio.';

  @override
  String wifi_connectedTo(String address) {
    return 'Conectado · $address';
  }

  @override
  String get wifi_notConnected => 'Não conectado ao Wi‑Fi';

  @override
  String wifi_portNote(int port) {
    return 'Apps na mesma rede podem se conectar pela porta $port';
  }

  @override
  String get wifi_connectOverWifi => 'Conectar via Wi‑Fi';

  @override
  String wifi_connectOverWifiBody(String address, int port) {
    return 'O MeshTrax vai se desconectar deste rádio e abrir a tela TCP com $address, porta $port já preenchidos. Lá, toque em Conectar.';
  }

  @override
  String get wifi_noteRestart =>
      'As mudanças valem depois que o rádio reiniciar.';

  @override
  String get wifi_noteSecurity =>
      'Qualquer pessoa na sua rede Wi‑Fi pode se conectar ao rádio pela porta 5000. Não há senha para isso.';

  @override
  String get wifi_noteBattery =>
      'O Wi‑Fi mantém o rádio acordado, então a bateria acaba mais rápido.';

  @override
  String get wifi_noteWrongPassword =>
      'Se a senha estiver errada, o rádio continua tentando a cada poucos segundos. O Bluetooth continua funcionando.';

  @override
  String get room_selfDemoteWarning =>
      'Você está alterando seu próprio acesso. Se abrir mão da função de admin, só o console da sala pode devolvê-la.';

  @override
  String get scanner_offlineMaps => 'Mapas offline';

  @override
  String get appSettings_offlineMaps => 'Mapas offline';

  @override
  String get appSettings_offlineMapsNone => 'Nenhum baixado';

  @override
  String appSettings_offlineMapsRegions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regiões',
      one: '1 região',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsChartAreas(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count áreas de cartas',
      one: '1 área de cartas',
    );
    return '$_temp0';
  }

  @override
  String appSettings_offlineMapsUpdates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count atualizações disponíveis',
      one: '1 atualização disponível',
    );
    return '$_temp0';
  }

  @override
  String get appSettings_mapDownloadsWifiOnly => 'Baixar mapas só no Wi‑Fi';

  @override
  String get appSettings_mapDownloadsWifiOnlySubtitle =>
      'Os downloads de mapas esperam uma conexão Wi‑Fi';

  @override
  String get offlineMaps_title => 'Mapas offline';

  @override
  String get offlineMaps_tabMaps => 'Mapas';

  @override
  String get offlineMaps_tabCharts => 'Cartas';

  @override
  String get offlineMaps_chartsNotice => 'Não serve para navegação · Por quê?';

  @override
  String offlineMaps_chartsSuggested(String coast) {
    return 'Sugeridas · $coast';
  }

  @override
  String get offlineMaps_chartsByCoast => 'Áreas de cartas por costa';

  @override
  String offlineMaps_chartsCoastSummary(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count áreas',
      one: '1 área',
    );
    return '$_temp0 · $size';
  }

  @override
  String offlineMaps_chartsDownloadedCount(int count) {
    return '$count baixadas';
  }

  @override
  String offlineMaps_chartsSelectedCount(int count) {
    return '$count selecionadas';
  }

  @override
  String get offlineMaps_selectAll => 'Selecionar tudo';

  @override
  String get offlineMaps_clearSelection => 'Limpar';

  @override
  String offlineMaps_chartsAlsoIn(String coasts) {
    return 'Também em $coasts';
  }

  @override
  String get offlineMaps_chartsNotAvailable => 'Ainda não disponível';

  @override
  String get offlineMaps_chartsHint =>
      'As cartas da NOAA são escolhidas por costa, na aba Cartas.';

  @override
  String offlineMaps_chartsName(String area) {
    return 'Cartas NOAA de $area';
  }

  @override
  String offlineMaps_chartsAreaCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count áreas',
      one: '1 área',
    );
    return '$_temp0';
  }

  @override
  String get offlineMaps_tabDownloaded => 'Baixados';

  @override
  String get offlineMaps_refresh => 'Procurar mapas novos';

  @override
  String get offlineMaps_loading => 'Carregando mapas disponíveis…';

  @override
  String get offlineMaps_serverError =>
      'Não foi possível acessar o servidor de mapas';

  @override
  String get offlineMaps_unavailable => 'Ainda não há mapas disponíveis';

  @override
  String get offlineMaps_unavailableHint => 'Tente de novo mais tarde.';

  @override
  String get offlineMaps_chartsUnavailable =>
      'Ainda não há cartas da NOAA disponíveis';

  @override
  String offlineMaps_cachedFrom(String date) {
    return 'Mostrando a lista de $date';
  }

  @override
  String get offlineMaps_needsNewerApp =>
      'Atualize o MeshTrax para obter os mapas mais recentes.';

  @override
  String get offlineMaps_world => 'Mundo';

  @override
  String get offlineMaps_suggested => 'Sugeridos';

  @override
  String get offlineMaps_regions => 'Regiões';

  @override
  String offlineMaps_regionsIn(String name) {
    return 'Regiões em $name';
  }

  @override
  String offlineMaps_inside(int count) {
    return '$count dentro';
  }

  @override
  String offlineMaps_storageUsed(String size) {
    return '$size de mapas offline neste dispositivo';
  }

  @override
  String offlineMaps_updates(int count) {
    return 'Atualizações ($count)';
  }

  @override
  String offlineMaps_updateAll(String size) {
    return 'Atualizar tudo $size';
  }

  @override
  String get offlineMaps_downloading => 'Baixando';

  @override
  String get offlineMaps_update => 'Atualizar';

  @override
  String offlineMaps_downloadedOn(String date) {
    return 'Baixado em $date';
  }

  @override
  String get offlineMaps_updateAvailable => 'Atualização disponível';

  @override
  String get offlineMaps_otherFiles => 'Outros arquivos de mapa';

  @override
  String get offlineMaps_emptyTitle => 'Ainda não há mapas offline';

  @override
  String get offlineMaps_emptyBody =>
      'Baixe uma região para usar o mapa sem conexão.';

  @override
  String get offlineMaps_findMaps => 'Encontrar mapas';

  @override
  String offlineMaps_deleteTitle(String name) {
    return 'Excluir $name?';
  }

  @override
  String offlineMaps_deleteBody(String size) {
    return 'Isso libera $size. Você pode baixar de novo depois.';
  }

  @override
  String offlineMaps_deleted(String name) {
    return '$name excluído';
  }

  @override
  String offlineMaps_bytesProgress(String done, String total) {
    return '$done de $total';
  }

  @override
  String get offlineMaps_kindMap => 'Mapa';

  @override
  String get offlineMaps_kindMapDetail =>
      'Ruas, trilhas e lugares do OpenStreetMap';

  @override
  String get offlineMaps_kindContours => 'Curvas de nível';

  @override
  String get offlineMaps_kindContoursDetail => 'Linhas de altitude';

  @override
  String get offlineMaps_kindUsgs => 'Mapa topográfico USGS';

  @override
  String get offlineMaps_kindUsgsDetail => 'Trilhas, rios, reservas';

  @override
  String get offlineMaps_kindTerrain => 'Sombreamento de relevo';

  @override
  String get offlineMaps_kindTerrainDetail =>
      'Morros e montanhas, sombreados sob o mapa';

  @override
  String get offlineMaps_kindCharts => 'Cartas da NOAA';

  @override
  String get offlineMaps_usOnly => 'Só Estados Unidos';

  @override
  String offlineMaps_download(String size) {
    return 'Baixar $size';
  }

  @override
  String get offlineMaps_downloadTotal => 'Baixar';

  @override
  String offlineMaps_largeDownload(String size) {
    return 'Download grande ($size). Use Wi‑Fi e deixe o dispositivo carregando.';
  }

  @override
  String get offlineMaps_waiting => 'Aguardando…';

  @override
  String get offlineMaps_checking => 'Verificando download…';

  @override
  String get offlineMaps_retrying => 'Tentando de novo…';

  @override
  String offlineMaps_failed(String error) {
    return 'Falha no download: $error';
  }

  @override
  String get offlineMaps_pause => 'Pausar';

  @override
  String get offlineMaps_resume => 'Retomar';

  @override
  String get offlineMaps_deleteRegion => 'Excluir região';

  @override
  String get offlineMaps_notInCatalogue => 'Não disponível para esta região';

  @override
  String get offlineMaps_notificationRunning => 'Baixando mapa';

  @override
  String get offlineMaps_notificationPaused => 'Download do mapa pausado';

  @override
  String get offlineMaps_notificationFailed => 'Falha no download do mapa';

  @override
  String get offlineMaps_clearTileCache =>
      'Limpar blocos de mapa online em cache';

  @override
  String get offlineMaps_clearTileCachePrompt =>
      'Remover os blocos de mapa online salvos durante a navegação? Os mapas baixados ficam.';

  @override
  String get offlineMaps_tileCacheCleared =>
      'Blocos de mapa online em cache removidos';

  @override
  String get map_notForNavigation => 'Não serve para navegação';

  @override
  String get map_chartsNoticeIntro =>
      'O MeshTrax desenha estas cartas a partir dos dados de cartas da NOAA para ajudar você a ver a água ao redor dos seus rádios e planejar. Elas não são cartas oficiais. Não navegue por elas.';

  @override
  String get map_chartsNoticeWhy => 'Por quê:';

  @override
  String get map_chartsNoticeOutOfDate =>
      'Elas ficam desatualizadas. A NOAA corrige suas cartas o tempo todo; uma carta baixada fica como está até você atualizá-la em Mapas offline.';

  @override
  String get map_chartsNoticeLeftOut =>
      'Elas omitem coisas. Muitos símbolos, setores de luz e notas das cartas não são desenhados, e alguns rótulos só aparecem com mais zoom.';

  @override
  String get map_chartsNoticePositions =>
      'As posições podem estar erradas ou desatualizadas. O GPS pode errar por 10 m (30 ft) ou mais, e um nó só está onde informou pela última vez.';

  @override
  String get map_chartsNoticeNotPlotter =>
      'O MeshTrax não é um plotter cartográfico certificado.';

  @override
  String get map_chartsNoticeUse =>
      'Para navegar, use cartas da NOAA oficiais e atualizadas (em papel, ou ENCs da NOAA num plotter cartográfico certificado) com os Avisos aos Navegantes mais recentes.';

  @override
  String get map_sourceOnline => 'Online';

  @override
  String get map_sourceOffline => 'Offline';

  @override
  String get map_downloadForDetail => 'Baixe uma região para ver detalhes';

  @override
  String get map_zoomInForOfflineMap => 'Aproxime para ver seu mapa offline';

  @override
  String get map_noCharts => 'Sem cartas aqui';

  @override
  String get map_myLocation => 'Minha localização';

  @override
  String get map_zoomIn => 'Aproximar';

  @override
  String get map_zoomOut => 'Afastar';

  @override
  String get gps_title => 'GPS';

  @override
  String get gps_on => 'GPS ligado';

  @override
  String get gps_off => 'GPS desligado';

  @override
  String get gps_onHint => 'O rádio atualiza sua posição pelo GPS.';

  @override
  String get gps_offHint =>
      'Desligado economiza a bateria do rádio. Ao ligar, pode levar alguns minutos para encontrar sua posição.';

  @override
  String get gps_asking => 'Consultando o rádio...';

  @override
  String get gps_noPosition =>
      'Ainda sem posição. Ao ar livre, a primeira pode levar alguns minutos.';

  @override
  String get gps_position => 'Posição';

  @override
  String get gps_altitude => 'Altitude';

  @override
  String gps_readAgo(String ago) {
    return 'Lido do rádio há $ago';
  }

  @override
  String get gps_turnOnTitle => 'Ligar o GPS?';

  @override
  String get gps_turnOnBody =>
      'O GPS do rádio está desligado. Ao ligar, pode levar alguns minutos para encontrar sua posição.';

  @override
  String get gps_turnOn => 'Ligar';

  @override
  String get gps_notNow => 'Agora não';

  @override
  String get map_zoomInForCharts => 'Aproxime para ver suas cartas';

  @override
  String map_downloadRegion(String region, String size) {
    return 'Baixar $region · $size';
  }

  @override
  String get mapLayers_title => 'Camadas do mapa';

  @override
  String get mapLayers_mapType => 'Tipo de mapa';

  @override
  String get mapLayers_standard => 'Padrão';

  @override
  String get mapLayers_usgs => 'Topográfico USGS';

  @override
  String get mapLayers_charts => 'Cartas náuticas';

  @override
  String get mapLayers_notDownloaded => 'Não baixado';

  @override
  String get mapLayers_offlineOnly => 'Só offline';

  @override
  String get mapLayers_details => 'Detalhes do mapa';

  @override
  String get mapLayers_contours => 'Curvas de nível';

  @override
  String get mapLayers_hillShading => 'Sombreamento de relevo';

  @override
  String get mapLayers_dark => 'Mapa escuro';

  @override
  String get mapLayers_downloadedAreas => 'Áreas baixadas';

  @override
  String get mapLayers_nodes => 'Nós';

  @override
  String get mapLayers_pins => 'Marcadores';

  @override
  String get mapLayers_guessed => 'Estimados';

  @override
  String get mapLayers_moreFilters => 'Mais filtros';

  @override
  String get mapLayers_moreFiltersDetail =>
      'Visto por último, prefixo da chave, sobreposições';

  @override
  String get map_legend => 'Legenda';

  @override
  String get scanner_map => 'Mapa';

  @override
  String get structured_openMap => 'Abrir mapa';

  @override
  String get structured_addToCalendar => 'Adicionar à agenda';

  @override
  String get structured_details => 'Detalhes';

  @override
  String get structured_sos => 'SOS';

  @override
  String get structured_event => 'Evento';

  @override
  String get structured_notice => 'Aviso';

  @override
  String get structured_allDay => 'Dia inteiro';

  @override
  String get structured_calendarFailed => 'Não foi possível abrir a agenda';

  @override
  String get structured_today => 'Hoje';

  @override
  String get structured_tomorrow => 'Amanhã';

  @override
  String structured_inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Em $count dias',
      one: 'Em 1 dia',
    );
    return '$_temp0';
  }

  @override
  String get structured_past => 'Passado';

  @override
  String structured_dayOfDays(int day, int total) {
    return 'Dia $day de $total';
  }

  @override
  String structured_days(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dias',
      one: '1 dia',
    );
    return '$_temp0';
  }

  @override
  String get dialog_eventEndDate => 'Data de término';

  @override
  String get dialog_eventSameDay => 'Mesmo dia';

  @override
  String get structured_map => 'Mapa';

  @override
  String get structured_navigate => 'Navegar';

  @override
  String get structured_channel => 'Canal';

  @override
  String get structured_contact => 'Contato';

  @override
  String get structured_room => 'Sala';

  @override
  String get structured_repeater => 'Repetidor';

  @override
  String get structured_sensor => 'Sensor';

  @override
  String get structured_joinChannel => 'Entrar no canal';

  @override
  String get structured_addContact => 'Adicionar contato';

  @override
  String get structured_addRoom => 'Adicionar sala';

  @override
  String get structured_addRepeater => 'Adicionar repetidor';

  @override
  String get structured_addSensor => 'Adicionar sensor';

  @override
  String get structured_open => 'Abrir';

  @override
  String get structured_added => 'Adicionado';

  @override
  String get tray_add => 'Adicionar';

  @override
  String get tray_myLocation => 'Minha localização';

  @override
  String get tray_pointOnMap => 'Ponto no mapa';

  @override
  String get tray_sos => 'SOS';

  @override
  String get tray_event => 'Evento';

  @override
  String get tray_notice => 'Aviso';

  @override
  String get tray_noRadioPosition =>
      'Seu rádio ainda não tem posição. Escolha uma no mapa.';

  @override
  String get dialog_insert => 'Inserir';

  @override
  String get dialog_eventTitle => 'Título';

  @override
  String get dialog_eventDate => 'Data';

  @override
  String get dialog_eventStart => 'Início';

  @override
  String get dialog_eventEnd => 'Fim';

  @override
  String get dialog_eventNoEnd => 'Sem horário de término';

  @override
  String get dialog_eventPlace => 'Local (opcional)';

  @override
  String get dialog_pickOnMap => 'Escolher no mapa';

  @override
  String get dialog_sosTitle => 'Enviar SOS';

  @override
  String get dialog_sosText => 'O que aconteceu?';

  @override
  String get dialog_noticeTitle => 'Aviso';

  @override
  String get dialog_noticeText => 'O que todos devem saber?';

  @override
  String get dialog_labelTitle => 'Ponto no mapa';

  @override
  String get dialog_note => 'Nota (opcional)';

  @override
  String get paste_convertLocation =>
      'Parece um link de mapa. Converter em Localização?';

  @override
  String get paste_convertEvent =>
      'Parece um compartilhamento de agenda. Converter em Evento?';

  @override
  String get paste_convert => 'Converter';

  @override
  String get paste_resolving => 'Resolvendo link…';

  @override
  String get paste_resolveFailed => 'Não foi possível resolver o link';

  @override
  String get pinned_dismiss => 'Dispensar';

  @override
  String get tray_gif => 'GIF';

  @override
  String link_joinChannelBody(String name) {
    return 'Entrar no canal $name?';
  }

  @override
  String link_alreadyJoined(String name) {
    return 'Você já está em $name';
  }

  @override
  String link_channelJoined(String name) {
    return 'Entrou em $name';
  }

  @override
  String get map_pickPositionHint => 'Toque no mapa para escolher uma posição';

  @override
  String get map_legendMesh => 'Rede mesh';

  @override
  String get chartLegend_title => 'Símbolos das cartas';

  @override
  String get chartLegend_sectionBuoys => 'Boias e balizas';

  @override
  String get chartLegend_sectionLights => 'Luzes';

  @override
  String get chartLegend_sectionHazards => 'Perigos';

  @override
  String get chartLegend_sectionTides => 'Marés e correntes';

  @override
  String get chartLegend_sectionDepths => 'Profundidades e fundo';

  @override
  String get chartLegend_sectionAreas => 'Áreas, vias e linhas';

  @override
  String get chartLegend_sectionLandmarks => 'Pontos de referência';

  @override
  String get chartLegend_sectionAbbreviations => 'Abreviaturas';

  @override
  String get chartLegend_chartNo1 =>
      'Todos os símbolos das cartas: U.S. Chart No. 1';

  @override
  String get chartLegend_portBuoy => 'Boia cilíndrica verde';

  @override
  String get chartLegend_portBuoyHint =>
      'Mantenha-a à sua esquerda ao entrar vindo do mar';

  @override
  String get chartLegend_starboardBuoy => 'Boia cônica vermelha';

  @override
  String get chartLegend_starboardBuoyHint =>
      'Mantenha-a à sua direita ao entrar: vermelho fica à direita na volta do mar';

  @override
  String get chartLegend_junctionBuoy => 'Boia com faixas';

  @override
  String get chartLegend_junctionBuoyHint =>
      'Bifurcação de canal: trate-a pela cor da faixa de cima';

  @override
  String get chartLegend_safeWaterBuoy => 'Listras vermelhas e brancas';

  @override
  String get chartLegend_safeWaterBuoyHint =>
      'Águas seguras ao redor, muitas vezes na entrada de um canal';

  @override
  String get chartLegend_isolatedDangerBuoy => 'Faixas pretas e vermelhas';

  @override
  String get chartLegend_isolatedDangerBuoyHint =>
      'Um pequeno perigo com águas seguras ao redor: mantenha distância';

  @override
  String get chartLegend_specialBuoy => 'Boia amarela';

  @override
  String get chartLegend_specialBuoyHint =>
      'Uso especial, não serve para orientar o rumo: fundeadouro, cabo, pesquisa';

  @override
  String get chartLegend_cardinalBuoy => 'Preta e amarela';

  @override
  String get chartLegend_cardinalBuoyHint =>
      'Marca cardinal: passe pelo lado que dá nome a ela (rara nos EUA)';

  @override
  String get chartLegend_mooringBuoy => 'Boia de amarração';

  @override
  String get chartLegend_portBeacon => 'Baliza quadrada verde';

  @override
  String get chartLegend_portBeaconHint =>
      'Como uma boia verde: mantenha-a à esquerda ao entrar';

  @override
  String get chartLegend_starboardBeacon => 'Baliza triangular vermelha';

  @override
  String get chartLegend_starboardBeaconHint =>
      'Como uma boia vermelha: mantenha-a à direita ao entrar';

  @override
  String get chartLegend_otherBeacon => 'Baliza em losango';

  @override
  String get chartLegend_otherBeaconHint =>
      'Informação ou aviso, não indica um lado do canal';

  @override
  String get chartLegend_beaconTower => 'Torre de farol ou estrutura de baliza';

  @override
  String get chartLegend_topmark => 'Marca de tope';

  @override
  String get chartLegend_topmarkHint =>
      'A forma no alto de uma marca completa o seu significado';

  @override
  String get chartLegend_light => 'Luz';

  @override
  String get chartLegend_lightHint =>
      'O sinal magenta marca uma luz; o rótulo diz como ela pisca';

  @override
  String get chartLegend_lightExample => 'Lampejos verdes, a cada 4 segundos';

  @override
  String get chartLegend_lightExampleHint =>
      'Rótulo de uma luz: ritmo, cor e depois período';

  @override
  String get chartLegend_lightFixed => 'Fixa';

  @override
  String get chartLegend_lightFixedHint => 'Uma luz contínua';

  @override
  String get chartLegend_lightFlashing => 'Lampejos';

  @override
  String get chartLegend_lightFlashingHint =>
      'Lampejos curtos, com escuro mais longo entre eles';

  @override
  String get chartLegend_lightGroup => 'Grupo de lampejos';

  @override
  String get chartLegend_lightGroupHint =>
      'Lampejos em grupos, aqui de 2, depois escuro';

  @override
  String get chartLegend_lightComposite => 'Grupo composto';

  @override
  String get chartLegend_lightCompositeHint =>
      '2 lampejos, depois 1: marca uma bifurcação de canal';

  @override
  String get chartLegend_lightQuick => 'Rápida';

  @override
  String get chartLegend_lightQuickHint => 'Cerca de um lampejo por segundo';

  @override
  String get chartLegend_lightIsophase => 'Isofásica';

  @override
  String get chartLegend_lightIsophaseHint => 'Luz e escuro de mesma duração';

  @override
  String get chartLegend_lightOcculting => 'De ocultação';

  @override
  String get chartLegend_lightOccultingHint =>
      'Acesa por mais tempo do que apagada';

  @override
  String get chartLegend_lightMorse => 'Código Morse A';

  @override
  String get chartLegend_lightMorseHint => 'Curto, longo: águas seguras';

  @override
  String get chartLegend_lightAlternating => 'Alternada';

  @override
  String get chartLegend_lightAlternatingHint => 'Muda de cor';

  @override
  String get chartLegend_lightColours => 'Branca, vermelha, verde, amarela';

  @override
  String get chartLegend_lightPeriod => 'Período';

  @override
  String get chartLegend_lightPeriodHint => 'Segundos para um ciclo completo';

  @override
  String get chartLegend_rock => 'Pedra submersa';

  @override
  String get chartLegend_rockHint => 'Sempre coberta, mas pode estar rasa';

  @override
  String get chartLegend_rockAwash => 'Pedra à flor d\'água';

  @override
  String get chartLegend_rockAwashHint => 'Perto da superfície na maré baixa';

  @override
  String get chartLegend_rockCovers => 'Pedra que cobre e descobre';

  @override
  String get chartLegend_rockCoversHint =>
      'Aparece na maré baixa, fica coberta na maré alta';

  @override
  String get chartLegend_wreckDangerous => 'Naufrágio perigoso';

  @override
  String get chartLegend_wreckDangerousHint =>
      'Raso o bastante para um barco bater nele';

  @override
  String get chartLegend_wreck => 'Naufrágio';

  @override
  String get chartLegend_wreckHint =>
      'Fundo o bastante para barcos na superfície; não fundeie';

  @override
  String get chartLegend_wreckShowing => 'Naufrágio visível';

  @override
  String get chartLegend_wreckShowingHint => 'Parte dele aparece acima da água';

  @override
  String get chartLegend_obstruction => 'Obstrução';

  @override
  String get chartLegend_obstructionHint =>
      'Algo no fundo; com a profundidade, quando conhecida';

  @override
  String get chartLegend_foulGround => 'Fundo sujo';

  @override
  String get chartLegend_foulGroundHint =>
      'Dá para passar por cima, mas não fundeie nem pesque de arrasto';

  @override
  String get chartLegend_hazardArea => 'Limite de área de perigo';

  @override
  String get chartLegend_hazardAreaHint =>
      'Pedras, naufrágios ou obstruções dentro';

  @override
  String get chartLegend_pile => 'Estaca ou poste';

  @override
  String get chartLegend_floodStream => 'Corrente de enchente';

  @override
  String get chartLegend_floodStreamHint =>
      'Corrente de maré enquanto a maré sobe';

  @override
  String get chartLegend_ebbStream => 'Corrente de vazante';

  @override
  String get chartLegend_ebbStreamHint =>
      'Corrente de maré enquanto a maré desce';

  @override
  String get chartLegend_current => 'Corrente';

  @override
  String get chartLegend_currentHint =>
      'Corre no mesmo sentido, seja qual for a maré';

  @override
  String get chartLegend_rips => 'Escarcéus ou redemoinhos';

  @override
  String get chartLegend_ripsHint => 'Água agitada e em redemoinho';

  @override
  String get chartLegend_breakers => 'Arrebentação';

  @override
  String get chartLegend_breakersHint => 'Ondas quebrando sobre baixios';

  @override
  String get chartLegend_sounding => 'Sondagem';

  @override
  String get chartLegend_soundingHint => 'Profundidade numa maré baixa média';

  @override
  String get chartLegend_depthContour => 'Isóbata';

  @override
  String get chartLegend_depthContourHint => 'O rótulo indica a profundidade';

  @override
  String get chartLegend_drying => 'Seca na maré baixa';

  @override
  String get chartLegend_dredged => 'Canal dragado';

  @override
  String get chartLegend_dredgedHint => 'Mantido na profundidade indicada';

  @override
  String get chartLegend_swept => 'Área varrida';

  @override
  String get chartLegend_sweptHint =>
      'Verificada livre até a profundidade indicada';

  @override
  String get chartLegend_unsurveyed => 'Não sondado';

  @override
  String get chartLegend_unsurveyedHint => 'Nenhuma profundidade medida';

  @override
  String get chartLegend_weed => 'Algas ou sargaço';

  @override
  String get chartLegend_restricted => 'Área restrita';

  @override
  String get chartLegend_restrictedHint =>
      'Entrada limitada; os traços apontam para dentro';

  @override
  String get chartLegend_regulatedLimit => 'Limite de área regulamentada';

  @override
  String get chartLegend_regulatedLimitHint =>
      'Fundeadouro, área de cabos, área de tiro e outras: veja o rótulo';

  @override
  String get chartLegend_greyLimit => 'Área de despejo, de pesca ou de cultivo';

  @override
  String get chartLegend_anchorage => 'Fundeadouro';

  @override
  String get chartLegend_anchorBerth => 'Posição de fundeio';

  @override
  String get chartLegend_noAnchoring => 'Proibido fundear';

  @override
  String get chartLegend_caution => 'Área de cautela';

  @override
  String get chartLegend_cautionHint => 'Tenha cuidado redobrado aqui';

  @override
  String get chartLegend_trafficLane => 'Via de tráfego';

  @override
  String get chartLegend_trafficLaneHint =>
      'Navios grandes, sentido único: cruze em ângulo reto';

  @override
  String get chartLegend_separationZone => 'Zona de separação';

  @override
  String get chartLegend_separationZoneHint =>
      'Entre vias de tráfego: não entre';

  @override
  String get chartLegend_precautionary => 'Área de precaução';

  @override
  String get chartLegend_precautionaryHint => 'Navios convergem: tenha cuidado';

  @override
  String get chartLegend_fairway => 'Via navegável';

  @override
  String get chartLegend_fairwayHint => 'Um canal principal';

  @override
  String get chartLegend_track => 'Derrota recomendada';

  @override
  String get chartLegend_ferry => 'Rota de balsa';

  @override
  String get chartLegend_leadingLine => 'Alinhamento';

  @override
  String get chartLegend_leadingLineHint =>
      'Alinhe as duas marcas para ficar no canal';

  @override
  String get chartLegend_cable => 'Cabo submarino';

  @override
  String get chartLegend_cableHint => 'Não fundeie';

  @override
  String get chartLegend_pipeline => 'Duto submarino';

  @override
  String get chartLegend_pipelineHint => 'Não fundeie';

  @override
  String get chartLegend_overhead => 'Cabo aéreo';

  @override
  String get chartLegend_overheadHint => 'Sua altura livre é indicada como VC';

  @override
  String get chartLegend_tower => 'Torre';

  @override
  String get chartLegend_windTurbine => 'Turbina eólica';

  @override
  String get chartLegend_chimney => 'Chaminé';

  @override
  String get chartLegend_mast => 'Mastro ou antena';

  @override
  String get chartLegend_church => 'Igreja ou campanário';

  @override
  String get chartLegend_flagstaff => 'Mastro de bandeira';

  @override
  String get chartLegend_dome => 'Cúpula';

  @override
  String get chartLegend_landmark => 'Outro ponto de referência';

  @override
  String get chartLegend_abbrAnch => 'Fundeadouro';

  @override
  String get chartLegend_abbrWk => 'Naufrágio';

  @override
  String get chartLegend_abbrBr => 'Arrebentação';

  @override
  String get chartLegend_abbrWd => 'Algas';

  @override
  String get chartLegend_abbrVar => 'Declinação magnética';

  @override
  String get chartLegend_abbrVc => 'Altura livre sob ponte ou cabo';

  @override
  String get chartLegend_abbrTr => 'Torre';

  @override
  String get chartLegend_abbrCh => 'Igreja';

  @override
  String get chartLegend_abbrChy => 'Chaminé';

  @override
  String get chartLegend_abbrFs => 'Mastro de bandeira';

  @override
  String get chartLegend_abbrTk => 'Tanque';

  @override
  String get chartLegend_abbrRBn => 'Radiofarol';

  @override
  String get chartLegend_abbrCg => 'Estação da Guarda Costeira';

  @override
  String get chartLegend_abbrRacon => 'Radarfarol: aparece no radar';

  @override
  String get chartLegend_abbrFog =>
      'Sinal de nevoeiro: buzina, sino, gongo, apito ou sirene';

  @override
  String get chartLegend_abbrVAis => 'Auxílio virtual: aparece só no AIS';

  @override
  String chartLegend_depthRange(String from, String to) {
    return '$from a $to';
  }

  @override
  String chartLegend_depthOver(String depth) {
    return 'Mais fundo que $depth';
  }

  @override
  String get parkLegend_title => 'Símbolos de parques e trilhas';

  @override
  String get parkLegend_campsite => 'Área de camping';

  @override
  String get parkLegend_picnicSite => 'Área de piquenique';

  @override
  String get parkLegend_shelter => 'Abrigo';

  @override
  String get parkLegend_toilets => 'Banheiros';

  @override
  String get parkLegend_drinkingWater => 'Água potável';

  @override
  String get parkLegend_parking => 'Estacionamento';

  @override
  String get parkLegend_viewpoint => 'Mirante';

  @override
  String get parkLegend_attraction => 'Atração';

  @override
  String get parkLegend_gate => 'Portão';

  @override
  String get parkLegend_telephone => 'Telefone';

  @override
  String get parkLegend_information => 'Painel de informações';

  @override
  String get parkLegend_guidepost => 'Placa de sinalização';

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
}
