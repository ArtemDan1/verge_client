// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get renameProfile => 'Cambiar nombre del perfil';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get subscriptionsUpdated => 'Suscripciones actualizadas';

  @override
  String get unitB => 'B';

  @override
  String get unitKB => 'KB';

  @override
  String get unitMB => 'MB';

  @override
  String get unitGB => 'GB';

  @override
  String get unitTB => 'TB';

  @override
  String usedNoLimit(Object used) {
    return '$used usados · sin límite';
  }

  @override
  String validUntil(Object date) {
    return 'hasta $date';
  }

  @override
  String get timeout => 'tiempo agotado';

  @override
  String get error => 'error';

  @override
  String get pingAll => 'Ping a todos';

  @override
  String get refreshSubscriptions => 'Actualizar suscripciones';

  @override
  String get addSubscription => 'Añadir suscripción';

  @override
  String get servers => 'Servidores';

  @override
  String get pickingNode => 'Eligiendo nodo…';

  @override
  String get noSubscriptions => 'Aún no hay suscripciones. Añade la primera.';

  @override
  String get subscriptionHasNoServers => 'Esta suscripción no tiene servidores';

  @override
  String get active => 'activo';

  @override
  String get columnServer => 'Servidor';

  @override
  String get columnProtocol => 'Protocolo';

  @override
  String get columnEngine => 'Motor';

  @override
  String get columnLatency => 'Latencia';

  @override
  String ms(Object ms) {
    return '$ms ms';
  }

  @override
  String engineAuto(Object engine) {
    return 'Automático ($engine)';
  }

  @override
  String get edit => 'Editar';

  @override
  String get ping => 'Ping';

  @override
  String get refresh => 'Actualizar';

  @override
  String get subscriptionLinkCopied => 'Enlace de suscripción copiado';

  @override
  String get subscription => 'Suscripción';

  @override
  String get accountPage => 'Cuenta';

  @override
  String get support => 'Soporte';

  @override
  String get autoRefresh => 'Actualización automática';

  @override
  String get rename => 'Cambiar nombre';

  @override
  String get delete => 'Eliminar';

  @override
  String get autoSelectOn => 'Selección automática: activada';

  @override
  String get autoSelect => 'Selección automática';

  @override
  String refreshOwn(Object hours) {
    return 'Personalizado: $hours h';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'Según la suscripción: $hours h';
  }

  @override
  String get off => 'Desactivado';

  @override
  String get autoRefreshInterval => 'Intervalo de actualización automática';

  @override
  String get hours => 'Horas';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'Vacío — usar el intervalo de la suscripción ($hours h)';
  }

  @override
  String get emptyNoAutoRefresh => 'Vacío — no actualizar automáticamente';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servidores',
      one: '$count servidor',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used de $total';
  }

  @override
  String remaining(Object amount) {
    return 'quedan $amount';
  }

  @override
  String get limitExhausted => 'límite alcanzado';

  @override
  String get newProfile => 'Nuevo perfil';

  @override
  String get routing => 'Enrutamiento';

  @override
  String get updateGeo => 'Actualizar geo';

  @override
  String get profile => 'Perfil';

  @override
  String get routingSubtitle =>
      'Qué va por la VPN, qué va directo y qué se bloquea';

  @override
  String get geoNeverUpdated => 'nunca actualizados — versiones integradas';

  @override
  String geoUpdated(Object ago) {
    return 'actualizados $ago';
  }

  @override
  String geoSets(Object status) {
    return 'Conjuntos geo (.srs): $status';
  }

  @override
  String get justNow => 'justo ahora';

  @override
  String minutesAgo(Object n) {
    return 'hace $n min';
  }

  @override
  String hoursAgo(Object n) {
    return 'hace $n h';
  }

  @override
  String daysAgo(Object n) {
    return 'hace $n d';
  }

  @override
  String get restDirect => 'el resto directo';

  @override
  String get restViaVpn => 'el resto por VPN';

  @override
  String get builtIn => 'Integrado';

  @override
  String get custom => 'Personalizado';

  @override
  String get allDirect => 'todo directo';

  @override
  String get allViaVpn => 'todo por VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count reglas',
      one: '$count regla',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'Por VPN';

  @override
  String get groupDirect => 'Directo';

  @override
  String get groupBlock => 'Bloquear';

  @override
  String get groupExceptions => 'Excepciones (prioridad sobre el bloqueo)';

  @override
  String get exceptionsGo => 'Las excepciones van';

  @override
  String get viaVpn => 'por VPN';

  @override
  String get direct => 'directo';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get use => 'Usar';

  @override
  String get builtInProfileReadOnly =>
      'Los perfiles integrados no se pueden cambiar: duplica uno para personalizar sus reglas.';

  @override
  String get everythingElse => 'Todo lo que no coincide con las reglas';

  @override
  String get empty => 'Vacío';

  @override
  String get chooseCategory => 'Elegir categoría';

  @override
  String get domainOrCidr => 'Dominio o IP/CIDR';

  @override
  String get add => 'Añadir';

  @override
  String get domainOrCidrHint => 'example.com o 1.2.3.0/24';

  @override
  String get geoCategory => 'Categoría geo';

  @override
  String get domainOrIp => 'Dominio o IP';

  @override
  String get addRule => 'Añadir regla';

  @override
  String get kindProxy => 'Proxy';

  @override
  String get kindBlock => 'Bloqueo';

  @override
  String get otherApps => 'Otras';

  @override
  String get noActiveConnections => 'No hay conexiones activas';

  @override
  String get vpnDisconnected => 'La VPN está desactivada';

  @override
  String get nothingFound => 'No se encontró nada';

  @override
  String get connections => 'Conexiones';

  @override
  String get byApp => 'Por aplicación';

  @override
  String get asList => 'Lista';

  @override
  String get connectionsSearchHint => 'Dominio, IP o aplicación';

  @override
  String get all => 'Todas';

  @override
  String get close => 'Cerrar';

  @override
  String get kindProxyShort => 'proxy';

  @override
  String get kindBlockShort => 'bloqueo';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conexiones',
      one: '$count conexión',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'Aplicación';

  @override
  String get fieldProcessPath => 'Ruta del proceso';

  @override
  String get fieldNetwork => 'Red';

  @override
  String get fieldSource => 'Origen';

  @override
  String get fieldDestination => 'Destino';

  @override
  String get fieldDomain => 'Dominio';

  @override
  String get fieldChain => 'Cadena';

  @override
  String get fieldRule => 'Regla';

  @override
  String get fieldDuration => 'Duración';

  @override
  String get fieldStart => 'Inicio';

  @override
  String get connectionClosed => 'conexión cerrada';

  @override
  String get sent => 'Enviado';

  @override
  String get received => 'Recibido';

  @override
  String get advanced => 'Avanzado';

  @override
  String get tunAdvancedDescription =>
      'Dirección de la interfaz, MTU, pila de red y rutas. Ajustados para la mayoría de redes: cámbialos solo si TUN da problemas';

  @override
  String get reset => 'Restablecer';

  @override
  String get tunAdvancedWarning =>
      'Cambia estos valores solo si entiendes las consecuencias. MTU 9000 corta SSH y MySQL, una dirección de 172.16.0.0/12 rompe las redes de docker y la ruta estricta captura el tráfico de la red local.';

  @override
  String get interfaceAddress => 'Dirección de la interfaz';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'De $min a $max';
  }

  @override
  String get networkStack => 'Pila de red';

  @override
  String get networkStackDescription =>
      'gvisor — compatibilidad, system — velocidad, mixed — equilibrio';

  @override
  String get strictRoute => 'Ruta estricta';

  @override
  String get strictRouteDescription => 'Impide que el tráfico eluda el túnel';

  @override
  String get autoRoute => 'Ruta predeterminada';

  @override
  String get autoRouteDescription =>
      'Todo el tráfico del sistema pasa por el túnel';

  @override
  String daysShort(Object n) {
    return '$n d';
  }

  @override
  String get connected => 'Conectado';

  @override
  String get connecting => 'Conectando…';

  @override
  String get notConnected => 'No conectado';

  @override
  String get chooseServerBelow => 'Elige un servidor abajo';

  @override
  String get time => 'Tiempo';

  @override
  String get noInternet => 'sin internet';

  @override
  String get routingRules => 'Reglas de enrutamiento';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get connect => 'Conectar';

  @override
  String get checkingServer => 'Comprobando el servidor';

  @override
  String get clickToConnect => 'Haz clic para conectar';

  @override
  String get quitVerge => 'Salir de Verge';

  @override
  String get noSubscriptionsTray =>
      'No hay suscripciones: añádelas en la ventana principal';

  @override
  String get openVerge => 'Abrir Verge';

  @override
  String get noResponse => 'sin respuesta';

  @override
  String get skipCertVerify => 'Omitir la verificación del certificado';

  @override
  String get skipCertVerifyDescription =>
      'Reduce la seguridad: la conexión deja de proteger contra la suplantación del servidor. Actívalo solo para depuración';

  @override
  String get tlsFragment => 'Fragmentación TLS';

  @override
  String get tlsFragmentDescription =>
      'Divide el handshake TLS en partes para sortear cortafuegos que comparan el ClientHello de forma simple. Solo funciona con sing-box';

  @override
  String get tlsFragmentUnsupported =>
      'El motor actual no admite la fragmentación';

  @override
  String get tlsRecordFragment => 'Fragmentación por registros TLS';

  @override
  String get tlsRecordFragmentDescription =>
      'Más barata en rendimiento: conviene probarla primero';

  @override
  String get fallbackDelay => 'Retardo de la alternativa';

  @override
  String get fallbackDelayDescription =>
      'Cuánto esperar respuesta antes de reintentar sin fragmentación';

  @override
  String versionAvailable(Object version) {
    return 'Versión $version disponible';
  }

  @override
  String get launchingInstaller =>
      'Iniciando el instalador: Verge se cerrará y se actualizará';

  @override
  String get downloadingUpdate => 'Descargando la actualización…';

  @override
  String get updateReady =>
      'Una nueva versión de Verge está lista para instalarse';

  @override
  String downloadFailed(Object error) {
    return 'Error de descarga: $error';
  }

  @override
  String get retry => 'Reintentar';

  @override
  String get update => 'Actualizar';

  @override
  String get later => 'Más tarde';

  @override
  String get whatsNew => 'Novedades';

  @override
  String get skipVersion => 'Omitir esta versión';

  @override
  String get installing => 'Instalando…';

  @override
  String get downloading => 'Descargando';

  @override
  String get activeConnectionPing => 'Ping de la conexión activa';

  @override
  String get showPing => 'Mostrar ping';

  @override
  String get showPingDescription =>
      'Latencia al servidor en la pantalla principal, junto al temporizador de conexión';

  @override
  String get pingIntervalSeconds => 'Intervalo de actualización, s';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'De $min a $max s, por defecto $def';
  }

  @override
  String get probeUrl => 'URL de comprobación';

  @override
  String get probeUrlDescription =>
      'En modo TUN esta URL comprueba el acceso a internet fuera del túnel; en modo Proxy mide la latencia a través del proxy local';

  @override
  String get autoSelectNode => 'Selección automática de nodo';

  @override
  String get pickBestNode => 'Elegir el mejor nodo';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'Intervalo de comprobación en segundo plano, segundos ($min…$max)';
  }

  @override
  String get profiles => 'Perfiles';

  @override
  String get checkNow => 'Comprobar ahora';

  @override
  String lastCheck(Object time, Object result) {
    return 'Última comprobación: $time — $result';
  }

  @override
  String get nodeResponds => 'el nodo responde';

  @override
  String lastPick(Object result) {
    return 'Última selección: $result';
  }

  @override
  String get emptyLink => 'Enlace vacío';

  @override
  String get clipboardEmpty => 'El portapapeles está vacío';

  @override
  String get addSubscriptionDescription =>
      'URL de suscripción, enlace para compartir (vless://, ss://…) o configuración JSON';

  @override
  String get pasteFromClipboardHint =>
      '¿Has copiado un enlace? Añádelo directamente desde el portapapeles';

  @override
  String get paste => 'Pegar';

  @override
  String get or => 'o';

  @override
  String get subscriptionUrlHint => 'https://… o vless://…';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get theme => 'Tema';

  @override
  String get startup => 'Inicio';

  @override
  String get autostart => 'Conexión automática';

  @override
  String get autostartDescription => 'Conectar al último nodo al iniciar';

  @override
  String get localProxyPort => 'Puerto del proxy local';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS en 127.0.0.1';

  @override
  String get home => 'Inicio';

  @override
  String get settings => 'Ajustes';

  @override
  String get logs => 'Registros';

  @override
  String get about => 'Acerca de';

  @override
  String get newBadge => 'nuevo';

  @override
  String get copy => 'Copiar';

  @override
  String get clear => 'Borrar';

  @override
  String get searchLogs => 'Buscar en los registros';

  @override
  String get noLogsYet => 'Aún no hay registros';

  @override
  String get nothingMatchesFilter => 'Nada coincide con el filtro';

  @override
  String get editNode => 'Editar nodo';

  @override
  String get name => 'Nombre';

  @override
  String schema(Object engine) {
    return 'Esquema: $engine';
  }

  @override
  String get format => 'Formatear';

  @override
  String get changesOverwrittenOnRefresh =>
      'Los cambios se sobrescribirán al actualizar la suscripción';

  @override
  String get dnsHijack => 'Captura de DNS en TUN';

  @override
  String get dnsHijackDescription =>
      'Redirige todo el tráfico del puerto 53 al motor DNS. Sin esto, las consultas van al DNS del proveedor y se censuran';

  @override
  String get dnsProxy => 'DNS para el proxy';

  @override
  String get dnsProxyDescription => 'Resuelve los sitios que van por la VPN';

  @override
  String get dnsDirect => 'DNS para conexiones directas';

  @override
  String get dnsDirectDescription =>
      'Para los sitios que se abren directamente';

  @override
  String get aboutTagline =>
      'Cliente proxy para macOS y Windows basado en sing-box y Xray.';

  @override
  String get appVersion => 'Versión de la aplicación';

  @override
  String get checking => 'Comprobando…';

  @override
  String get checkForUpdates => 'Buscar actualizaciones';

  @override
  String get upToDate => 'Tienes la última versión';

  @override
  String get general => 'General';

  @override
  String get network => 'Red';

  @override
  String get changesApplyAfterReconnect =>
      'Los cambios se aplicarán tras reconectar';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get ipv6Description =>
      'Desactivado por defecto: muchos servidores solo usan IPv4 y las conexiones IPv6 se cuelgan en lugar de recurrir a IPv4';

  @override
  String get presetAllProxy => 'Todo por el proxy';

  @override
  String get presetBypassRu => 'Evitar Rusia';

  @override
  String get presetBlockAds => 'Solo bloqueo de anuncios';

  @override
  String get geoRuSites => 'Rusia (sitios)';

  @override
  String get geoRuIp => 'Rusia (IP)';

  @override
  String get geoAds => 'Anuncios y rastreadores';

  @override
  String get geoPrivate => 'Dominios privados';

  @override
  String get geoAdult => 'Contenido para adultos';

  @override
  String get geoCnIp => 'China (IP)';

  @override
  String get geoCnSites => 'China (sitios)';

  @override
  String get singboxCrashed => 'sing-box se cerró inesperadamente';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN desconectada: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count conjunto(s) sin actualizar (comprueba la conexión)';
  }

  @override
  String refreshFailed(Object names) {
    return 'No se pudo actualizar: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (copia)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'comprobación de $node — ok';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node no respondió ($failures de $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'El nodo $node no responde: eligiendo otro';
  }

  @override
  String get helperNotInstalled =>
      'El servicio del sistema no está instalado. Reinstala la aplicación con el instalador (.pkg).';

  @override
  String updateCheckFailed(Object error) {
    return 'No se pudieron buscar actualizaciones: $error';
  }

  @override
  String get updateCheckLatest =>
      'Búsqueda de actualizaciones: está instalada la última versión';

  @override
  String updateCheckAvailable(Object version) {
    return 'Búsqueda de actualizaciones: $version disponible';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'No se pudo descargar la actualización: $error';
  }

  @override
  String get noLiveNodes =>
      'no se encontraron nodos activos, la selección no cambió';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms ms (HTTP falló en todos los nodos)';
  }

  @override
  String get xrayFailedFallback => 'Xray no se inició, se vuelve a sing-box';

  @override
  String get xrayFailedManual =>
      'Xray no se inició; el motor se eligió manualmente, sin alternativa';

  @override
  String get xrayFailed => 'Xray no se inició';

  @override
  String get vpnNotConnectedXray => 'VPN no conectada: Xray no se inició';

  @override
  String get xrayConfigUnsupported =>
      'no se puede generar una configuración de Xray para este nodo';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray no arrancó: $error';
  }

  @override
  String get xrayUnavailable => 'Xray no está disponible en esta plataforma';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray se inició, pero el puerto socks $port no responde';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'Xray no se inició, funcionando con sing-box';

  @override
  String get engineChosenManually => 'Motor elegido manualmente';

  @override
  String get engineChosenAutomatically => 'Motor elegido automáticamente';

  @override
  String invalidJson(Object message) {
    return 'JSON no válido: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'JSON no válido: $message (carácter $offset)';
  }

  @override
  String get tooManyRedirects => 'demasiadas redirecciones';

  @override
  String get subscriptionNoValidNodes =>
      'la suscripción no contiene nodos válidos';

  @override
  String get subscriptionStubNodes =>
      'la suscripción devolvió nodos de relleno';

  @override
  String get invalidJsonConfig => 'configuración JSON no válida';

  @override
  String get expectedOutboundObject => 'Se esperaba un objeto JSON outbound';

  @override
  String get port => 'puerto';

  @override
  String testProcessFailed(Object error) {
    return 'no se pudo iniciar el proceso de prueba: $error';
  }

  @override
  String get language => 'Idioma';

  @override
  String get interfaceLanguage => 'Idioma de la interfaz';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get hotkeys => 'Atajos de teclado';

  @override
  String get toggleHotkey => 'Conectar / desconectar';

  @override
  String get toggleHotkeyDescription =>
      'Atajo global: funciona incluso con la ventana de Verge oculta';

  @override
  String get hotkeyTaken => 'Otra aplicación usa este atajo: elige otro';

  @override
  String get hotkeyNotSet => 'Sin asignar';

  @override
  String get hotkeyPress => 'Pulsa un atajo…';

  @override
  String get hotkeyNeedsModifier => 'Añade Ctrl, Alt o ⌘/Win';

  @override
  String get hotkeyClear => 'Quitar atajo';
}
