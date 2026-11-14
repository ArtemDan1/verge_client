// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get renameProfile => 'Renomear perfil';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Salvar';

  @override
  String get subscriptionsUpdated => 'Assinaturas atualizadas';

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
    return '$used usados · sem limite';
  }

  @override
  String validUntil(Object date) {
    return 'até $date';
  }

  @override
  String get timeout => 'tempo esgotado';

  @override
  String get error => 'erro';

  @override
  String get pingAll => 'Ping em todos';

  @override
  String get refreshSubscriptions => 'Atualizar assinaturas';

  @override
  String get addSubscription => 'Adicionar assinatura';

  @override
  String get servers => 'Servidores';

  @override
  String get pickingNode => 'Escolhendo nó…';

  @override
  String get noSubscriptions =>
      'Ainda não há assinaturas. Adicione a primeira.';

  @override
  String get subscriptionHasNoServers => 'Esta assinatura não tem servidores';

  @override
  String get active => 'ativo';

  @override
  String get columnServer => 'Servidor';

  @override
  String get columnProtocol => 'Protocolo';

  @override
  String get columnEngine => 'Motor';

  @override
  String get columnLatency => 'Latência';

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
  String get refresh => 'Atualizar';

  @override
  String get subscriptionLinkCopied => 'Link da assinatura copiado';

  @override
  String get subscription => 'Assinatura';

  @override
  String get accountPage => 'Conta';

  @override
  String get support => 'Suporte';

  @override
  String get autoRefresh => 'Atualização automática';

  @override
  String get rename => 'Renomear';

  @override
  String get delete => 'Excluir';

  @override
  String get autoSelectOn => 'Seleção automática: ligada';

  @override
  String get autoSelect => 'Seleção automática';

  @override
  String refreshOwn(Object hours) {
    return 'Personalizado: $hours h';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'Pela assinatura: $hours h';
  }

  @override
  String get off => 'Desligado';

  @override
  String get autoRefreshInterval => 'Intervalo de atualização automática';

  @override
  String get hours => 'Horas';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'Vazio — usar o intervalo da assinatura ($hours h)';
  }

  @override
  String get emptyNoAutoRefresh => 'Vazio — não atualizar automaticamente';

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
    return 'restam $amount';
  }

  @override
  String get limitExhausted => 'limite atingido';

  @override
  String get newProfile => 'Novo perfil';

  @override
  String get routing => 'Roteamento';

  @override
  String get updateGeo => 'Atualizar geo';

  @override
  String get profile => 'Perfil';

  @override
  String get routingSubtitle =>
      'O que passa pela VPN, o que vai direto e o que é bloqueado';

  @override
  String get geoNeverUpdated => 'nunca atualizados — versões embutidas';

  @override
  String geoUpdated(Object ago) {
    return 'atualizados $ago';
  }

  @override
  String geoSets(Object status) {
    return 'Conjuntos geo (.srs): $status';
  }

  @override
  String get justNow => 'agora mesmo';

  @override
  String minutesAgo(Object n) {
    return 'há $n min';
  }

  @override
  String hoursAgo(Object n) {
    return 'há $n h';
  }

  @override
  String daysAgo(Object n) {
    return 'há $n d';
  }

  @override
  String get restDirect => 'o resto direto';

  @override
  String get restViaVpn => 'o resto pela VPN';

  @override
  String get builtIn => 'Embutido';

  @override
  String get custom => 'Personalizado';

  @override
  String get allDirect => 'tudo direto';

  @override
  String get allViaVpn => 'tudo pela VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count regras',
      one: '$count regra',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'Pela VPN';

  @override
  String get groupDirect => 'Direto';

  @override
  String get groupBlock => 'Bloquear';

  @override
  String get groupExceptions => 'Exceções (prioridade sobre o bloqueio)';

  @override
  String get exceptionsGo => 'As exceções vão';

  @override
  String get viaVpn => 'pela VPN';

  @override
  String get direct => 'direto';

  @override
  String get duplicate => 'Duplicar';

  @override
  String get use => 'Usar';

  @override
  String get builtInProfileReadOnly =>
      'Perfis embutidos não podem ser alterados — duplique um para personalizar as regras.';

  @override
  String get everythingElse => 'Tudo o que não corresponde às regras';

  @override
  String get empty => 'Vazio';

  @override
  String get chooseCategory => 'Escolher categoria';

  @override
  String get domainOrCidr => 'Domínio ou IP/CIDR';

  @override
  String get add => 'Adicionar';

  @override
  String get domainOrCidrHint => 'example.com ou 1.2.3.0/24';

  @override
  String get geoCategory => 'Categoria geo';

  @override
  String get domainOrIp => 'Domínio ou IP';

  @override
  String get addRule => 'Adicionar regra';

  @override
  String get kindProxy => 'Proxy';

  @override
  String get kindBlock => 'Bloqueio';

  @override
  String get otherApps => 'Outros';

  @override
  String get noActiveConnections => 'Nenhuma conexão ativa';

  @override
  String get vpnDisconnected => 'A VPN está desligada';

  @override
  String get nothingFound => 'Nada encontrado';

  @override
  String get connections => 'Conexões';

  @override
  String get byApp => 'Por aplicativo';

  @override
  String get asList => 'Lista';

  @override
  String get connectionsSearchHint => 'Domínio, IP ou aplicativo';

  @override
  String get all => 'Todas';

  @override
  String get close => 'Fechar';

  @override
  String get kindProxyShort => 'proxy';

  @override
  String get kindBlockShort => 'bloqueio';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count conexões',
      one: '$count conexão',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'Aplicativo';

  @override
  String get fieldProcessPath => 'Caminho do processo';

  @override
  String get fieldNetwork => 'Rede';

  @override
  String get fieldSource => 'Origem';

  @override
  String get fieldDestination => 'Destino';

  @override
  String get fieldDomain => 'Domínio';

  @override
  String get fieldChain => 'Cadeia';

  @override
  String get fieldRule => 'Regra';

  @override
  String get fieldDuration => 'Duração';

  @override
  String get fieldStart => 'Início';

  @override
  String get connectionClosed => 'conexão encerrada';

  @override
  String get sent => 'Enviado';

  @override
  String get received => 'Recebido';

  @override
  String get advanced => 'Avançado';

  @override
  String get tunAdvancedDescription =>
      'Endereço da interface, MTU, pilha de rede e rotas. Ajustados para a maioria das redes — altere só se o TUN apresentar problemas';

  @override
  String get reset => 'Redefinir';

  @override
  String get tunAdvancedWarning =>
      'Altere estes valores somente se entender as consequências. MTU 9000 derruba SSH e MySQL, um endereço de 172.16.0.0/12 quebra redes docker e a rota estrita captura o tráfego da rede local.';

  @override
  String get interfaceAddress => 'Endereço da interface';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'De $min a $max';
  }

  @override
  String get networkStack => 'Pilha de rede';

  @override
  String get networkStackDescription =>
      'gvisor — compatibilidade, system — velocidade, mixed — equilíbrio';

  @override
  String get strictRoute => 'Rota estrita';

  @override
  String get strictRouteDescription => 'Impede que o tráfego contorne o túnel';

  @override
  String get autoRoute => 'Rota padrão';

  @override
  String get autoRouteDescription =>
      'Todo o tráfego do sistema vai para o túnel';

  @override
  String daysShort(Object n) {
    return '$n d';
  }

  @override
  String get connected => 'Conectado';

  @override
  String get connecting => 'Conectando…';

  @override
  String get notConnected => 'Desconectado';

  @override
  String get chooseServerBelow => 'Escolha um servidor abaixo';

  @override
  String get time => 'Tempo';

  @override
  String get noInternet => 'sem internet';

  @override
  String get routingRules => 'Regras de roteamento';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get connect => 'Conectar';

  @override
  String get checkingServer => 'Verificando o servidor';

  @override
  String get clickToConnect => 'Clique para conectar';

  @override
  String get quitVerge => 'Sair do Verge';

  @override
  String get noSubscriptionsTray =>
      'Sem assinaturas — adicione-as na janela principal';

  @override
  String get openVerge => 'Abrir Verge';

  @override
  String get noResponse => 'sem resposta';

  @override
  String get skipCertVerify => 'Ignorar verificação de certificado';

  @override
  String get skipCertVerifyDescription =>
      'Reduz a segurança: a conexão deixa de proteger contra falsificação do servidor. Ative apenas para depuração';

  @override
  String get tlsFragment => 'Fragmentação TLS';

  @override
  String get tlsFragmentDescription =>
      'Divide o handshake TLS em partes para contornar firewalls que comparam o ClientHello de forma simples. Funciona apenas com sing-box';

  @override
  String get tlsFragmentUnsupported => 'O motor atual não suporta fragmentação';

  @override
  String get tlsRecordFragment => 'Fragmentação por registros TLS';

  @override
  String get tlsRecordFragmentDescription =>
      'Mais leve no desempenho — vale tentar primeiro';

  @override
  String get fallbackDelay => 'Atraso da alternativa';

  @override
  String get fallbackDelayDescription =>
      'Quanto esperar por resposta antes de tentar sem fragmentação';

  @override
  String versionAvailable(Object version) {
    return 'Versão $version disponível';
  }

  @override
  String get launchingInstaller =>
      'Iniciando o instalador — o Verge será fechado e atualizado';

  @override
  String get downloadingUpdate => 'Baixando a atualização…';

  @override
  String get updateReady =>
      'Uma nova versão do Verge está pronta para instalar';

  @override
  String downloadFailed(Object error) {
    return 'Falha no download: $error';
  }

  @override
  String get retry => 'Tentar novamente';

  @override
  String get update => 'Atualizar';

  @override
  String get later => 'Mais tarde';

  @override
  String get whatsNew => 'Novidades';

  @override
  String get skipVersion => 'Pular esta versão';

  @override
  String get installing => 'Instalando…';

  @override
  String get downloading => 'Baixando';

  @override
  String get activeConnectionPing => 'Ping da conexão ativa';

  @override
  String get showPing => 'Mostrar ping';

  @override
  String get showPingDescription =>
      'Latência até o servidor na tela inicial, ao lado do cronômetro de conexão';

  @override
  String get pingIntervalSeconds => 'Intervalo de atualização, s';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'De $min a $max s, padrão $def';
  }

  @override
  String get probeUrl => 'URL de verificação';

  @override
  String get probeUrlDescription =>
      'No modo TUN, esta URL verifica o acesso à internet fora do túnel; no modo Proxy, mede a latência pelo proxy local';

  @override
  String get autoSelectNode => 'Seleção automática de nó';

  @override
  String get pickBestNode => 'Escolher o melhor nó';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'Intervalo da verificação em segundo plano, segundos ($min…$max)';
  }

  @override
  String get profiles => 'Perfis';

  @override
  String get checkNow => 'Verificar agora';

  @override
  String lastCheck(Object time, Object result) {
    return 'Última verificação: $time — $result';
  }

  @override
  String get nodeResponds => 'o nó responde';

  @override
  String lastPick(Object result) {
    return 'Última escolha: $result';
  }

  @override
  String get emptyLink => 'Link vazio';

  @override
  String get clipboardEmpty => 'A área de transferência está vazia';

  @override
  String get addSubscriptionDescription =>
      'URL da assinatura, link de compartilhamento (vless://, ss://…) ou configuração JSON';

  @override
  String get pasteFromClipboardHint =>
      'Copiou um link? Adicione direto da área de transferência';

  @override
  String get paste => 'Colar';

  @override
  String get or => 'ou';

  @override
  String get subscriptionUrlHint => 'https://… ou vless://…';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get theme => 'Tema';

  @override
  String get startup => 'Inicialização';

  @override
  String get autostart => 'Conexão automática';

  @override
  String get autostartDescription => 'Conectar ao último nó ao iniciar';

  @override
  String get localProxyPort => 'Porta do proxy local';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS em 127.0.0.1';

  @override
  String get home => 'Início';

  @override
  String get settings => 'Configurações';

  @override
  String get logs => 'Logs';

  @override
  String get about => 'Sobre';

  @override
  String get newBadge => 'novo';

  @override
  String get copy => 'Copiar';

  @override
  String get clear => 'Limpar';

  @override
  String get searchLogs => 'Pesquisar nos logs';

  @override
  String get noLogsYet => 'Ainda não há logs';

  @override
  String get nothingMatchesFilter => 'Nada corresponde ao filtro';

  @override
  String get editNode => 'Editar nó';

  @override
  String get name => 'Nome';

  @override
  String schema(Object engine) {
    return 'Esquema: $engine';
  }

  @override
  String get format => 'Formatar';

  @override
  String get changesOverwrittenOnRefresh =>
      'As alterações serão sobrescritas quando a assinatura for atualizada';

  @override
  String get dnsHijack => 'Interceptação de DNS no TUN';

  @override
  String get dnsHijackDescription =>
      'Redireciona todo o tráfego da porta 53 para o motor DNS. Sem isso, as consultas vão para o DNS do provedor e são censuradas';

  @override
  String get dnsProxy => 'DNS para o proxy';

  @override
  String get dnsProxyDescription => 'Resolve os sites que passam pela VPN';

  @override
  String get dnsDirect => 'DNS para conexões diretas';

  @override
  String get dnsDirectDescription => 'Para sites que abrem diretamente';

  @override
  String get aboutTagline =>
      'Cliente proxy para macOS e Windows baseado em sing-box e Xray.';

  @override
  String get appVersion => 'Versão do aplicativo';

  @override
  String get checking => 'Verificando…';

  @override
  String get checkForUpdates => 'Verificar atualizações';

  @override
  String get upToDate => 'Você tem a versão mais recente';

  @override
  String get general => 'Geral';

  @override
  String get network => 'Rede';

  @override
  String get changesApplyAfterReconnect =>
      'As alterações serão aplicadas após reconectar';

  @override
  String get reconnect => 'Reconectar';

  @override
  String get ipv6Description =>
      'Desligado por padrão: muitos servidores usam apenas IPv4 e as conexões IPv6 travam em vez de recorrer ao IPv4';

  @override
  String get presetAllProxy => 'Tudo pelo proxy';

  @override
  String get presetBypassRu => 'Contornar a Rússia';

  @override
  String get presetBlockAds => 'Somente bloqueio de anúncios';

  @override
  String get geoRuSites => 'Rússia (sites)';

  @override
  String get geoRuIp => 'Rússia (IP)';

  @override
  String get geoAds => 'Anúncios e rastreadores';

  @override
  String get geoPrivate => 'Domínios privados';

  @override
  String get geoAdult => 'Conteúdo adulto';

  @override
  String get geoCnIp => 'China (IP)';

  @override
  String get geoCnSites => 'China (sites)';

  @override
  String get singboxCrashed => 'o sing-box travou';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN desconectada: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count conjunto(s) não atualizado(s) (verifique a conexão)';
  }

  @override
  String refreshFailed(Object names) {
    return 'Falha ao atualizar: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (cópia)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'verificação de $node — ok';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node não respondeu ($failures de $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'O nó $node não responde — escolhendo outro';
  }

  @override
  String get helperNotInstalled =>
      'O serviço do sistema não está instalado. Reinstale o aplicativo com o instalador (.pkg).';

  @override
  String updateCheckFailed(Object error) {
    return 'Falha ao verificar atualizações: $error';
  }

  @override
  String get updateCheckLatest =>
      'Verificação de atualizações: a versão mais recente está instalada';

  @override
  String updateCheckAvailable(Object version) {
    return 'Verificação de atualizações: $version disponível';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'Falha ao baixar a atualização: $error';
  }

  @override
  String get noLiveNodes => 'nenhum nó ativo encontrado, seleção mantida';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms ms (HTTP falhou em todos os nós)';
  }

  @override
  String get xrayFailedFallback =>
      'O Xray não iniciou, voltando para o sing-box';

  @override
  String get xrayFailedManual =>
      'O Xray não iniciou; o motor foi escolhido manualmente — sem alternativa';

  @override
  String get xrayFailed => 'O Xray não iniciou';

  @override
  String get vpnNotConnectedXray => 'VPN não conectada: o Xray não iniciou';

  @override
  String get xrayConfigUnsupported =>
      'não é possível gerar uma configuração Xray para este nó';

  @override
  String xrayStartFailed(Object error) {
    return 'O Xray não iniciou: $error';
  }

  @override
  String get xrayUnavailable => 'O Xray não está disponível nesta plataforma';

  @override
  String xraySocksNotResponding(Object port) {
    return 'O Xray iniciou, mas a porta socks $port não responde';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'O Xray não iniciou, funcionando com sing-box';

  @override
  String get engineChosenManually => 'Motor escolhido manualmente';

  @override
  String get engineChosenAutomatically => 'Motor escolhido automaticamente';

  @override
  String invalidJson(Object message) {
    return 'JSON inválido: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'JSON inválido: $message (caractere $offset)';
  }

  @override
  String get tooManyRedirects => 'redirecionamentos demais';

  @override
  String get subscriptionNoValidNodes => 'a assinatura não contém nós válidos';

  @override
  String get subscriptionStubNodes =>
      'a assinatura retornou nós de espaço reservado';

  @override
  String get invalidJsonConfig => 'configuração JSON inválida';

  @override
  String get expectedOutboundObject => 'Esperava-se um objeto JSON outbound';

  @override
  String get port => 'porta';

  @override
  String testProcessFailed(Object error) {
    return 'o processo de teste não iniciou: $error';
  }

  @override
  String get language => 'Idioma';

  @override
  String get interfaceLanguage => 'Idioma da interface';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get hotkeys => 'Atalhos de teclado';

  @override
  String get toggleHotkey => 'Conectar / desconectar';

  @override
  String get toggleHotkeyDescription =>
      'Atalho global — funciona mesmo com a janela do Verge oculta';

  @override
  String get hotkeyTaken =>
      'Este atalho é usado por outro aplicativo — escolha outro';

  @override
  String get hotkeyNotSet => 'Não definido';

  @override
  String get hotkeyPress => 'Pressione um atalho…';

  @override
  String get hotkeyNeedsModifier => 'Adicione Ctrl, Alt ou ⌘/Win';

  @override
  String get hotkeyClear => 'Remover atalho';
}
