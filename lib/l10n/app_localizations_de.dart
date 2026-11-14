// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get renameProfile => 'Profil umbenennen';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get subscriptionsUpdated => 'Abonnements aktualisiert';

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
    return '$used verbraucht · ohne Limit';
  }

  @override
  String validUntil(Object date) {
    return 'bis $date';
  }

  @override
  String get timeout => 'Zeitüberschreitung';

  @override
  String get error => 'Fehler';

  @override
  String get pingAll => 'Alle anpingen';

  @override
  String get refreshSubscriptions => 'Abonnements aktualisieren';

  @override
  String get addSubscription => 'Abonnement hinzufügen';

  @override
  String get servers => 'Server';

  @override
  String get pickingNode => 'Knoten wird gewählt…';

  @override
  String get noSubscriptions => 'Noch keine Abonnements. Füge das erste hinzu.';

  @override
  String get subscriptionHasNoServers =>
      'Dieses Abonnement enthält keine Server';

  @override
  String get active => 'aktiv';

  @override
  String get columnServer => 'Server';

  @override
  String get columnProtocol => 'Protokoll';

  @override
  String get columnEngine => 'Engine';

  @override
  String get columnLatency => 'Latenz';

  @override
  String ms(Object ms) {
    return '$ms ms';
  }

  @override
  String engineAuto(Object engine) {
    return 'Automatisch ($engine)';
  }

  @override
  String get edit => 'Bearbeiten';

  @override
  String get ping => 'Ping';

  @override
  String get refresh => 'Aktualisieren';

  @override
  String get subscriptionLinkCopied => 'Abonnement-Link kopiert';

  @override
  String get subscription => 'Abonnement';

  @override
  String get accountPage => 'Konto';

  @override
  String get support => 'Support';

  @override
  String get autoRefresh => 'Automatische Aktualisierung';

  @override
  String get rename => 'Umbenennen';

  @override
  String get delete => 'Löschen';

  @override
  String get autoSelectOn => 'Automatische Auswahl: an';

  @override
  String get autoSelect => 'Automatische Auswahl';

  @override
  String refreshOwn(Object hours) {
    return 'Eigenes: $hours h';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'Laut Abonnement: $hours h';
  }

  @override
  String get off => 'Aus';

  @override
  String get autoRefreshInterval =>
      'Intervall der automatischen Aktualisierung';

  @override
  String get hours => 'Stunden';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'Leer — Intervall des Abonnements verwenden ($hours h)';
  }

  @override
  String get emptyNoAutoRefresh => 'Leer — nicht automatisch aktualisieren';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Server',
      one: '$count Server',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used von $total';
  }

  @override
  String remaining(Object amount) {
    return 'noch $amount';
  }

  @override
  String get limitExhausted => 'Limit erreicht';

  @override
  String get newProfile => 'Neues Profil';

  @override
  String get routing => 'Routing';

  @override
  String get updateGeo => 'Geo aktualisieren';

  @override
  String get profile => 'Profil';

  @override
  String get routingSubtitle =>
      'Was über das VPN läuft, was direkt geht und was blockiert wird';

  @override
  String get geoNeverUpdated => 'nie aktualisiert — mitgelieferte Versionen';

  @override
  String geoUpdated(Object ago) {
    return 'aktualisiert $ago';
  }

  @override
  String geoSets(Object status) {
    return 'Geo-Sets (.srs): $status';
  }

  @override
  String get justNow => 'gerade eben';

  @override
  String minutesAgo(Object n) {
    return 'vor $n Min.';
  }

  @override
  String hoursAgo(Object n) {
    return 'vor $n Std.';
  }

  @override
  String daysAgo(Object n) {
    return 'vor $n T.';
  }

  @override
  String get restDirect => 'der Rest direkt';

  @override
  String get restViaVpn => 'der Rest über VPN';

  @override
  String get builtIn => 'Integriert';

  @override
  String get custom => 'Eigenes';

  @override
  String get allDirect => 'alles direkt';

  @override
  String get allViaVpn => 'alles über VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Regeln',
      one: '$count Regel',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'Über VPN';

  @override
  String get groupDirect => 'Direkt';

  @override
  String get groupBlock => 'Blockieren';

  @override
  String get groupExceptions => 'Ausnahmen (vor Blockierung)';

  @override
  String get exceptionsGo => 'Ausnahmen gehen';

  @override
  String get viaVpn => 'über VPN';

  @override
  String get direct => 'direkt';

  @override
  String get duplicate => 'Duplizieren';

  @override
  String get use => 'Verwenden';

  @override
  String get builtInProfileReadOnly =>
      'Integrierte Profile lassen sich nicht ändern — dupliziere eines, um die Regeln anzupassen.';

  @override
  String get everythingElse => 'Alles, was keiner Regel entspricht';

  @override
  String get empty => 'Leer';

  @override
  String get chooseCategory => 'Kategorie wählen';

  @override
  String get domainOrCidr => 'Domain oder IP/CIDR';

  @override
  String get add => 'Hinzufügen';

  @override
  String get domainOrCidrHint => 'example.com oder 1.2.3.0/24';

  @override
  String get geoCategory => 'Geo-Kategorie';

  @override
  String get domainOrIp => 'Domain oder IP';

  @override
  String get addRule => 'Regel hinzufügen';

  @override
  String get kindProxy => 'Proxy';

  @override
  String get kindBlock => 'Block';

  @override
  String get otherApps => 'Andere';

  @override
  String get noActiveConnections => 'Keine aktiven Verbindungen';

  @override
  String get vpnDisconnected => 'VPN ist aus';

  @override
  String get nothingFound => 'Nichts gefunden';

  @override
  String get connections => 'Verbindungen';

  @override
  String get byApp => 'Nach App';

  @override
  String get asList => 'Liste';

  @override
  String get connectionsSearchHint => 'Domain, IP oder App';

  @override
  String get all => 'Alle';

  @override
  String get close => 'Schließen';

  @override
  String get kindProxyShort => 'Proxy';

  @override
  String get kindBlockShort => 'Block';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Verbindungen',
      one: '$count Verbindung',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'App';

  @override
  String get fieldProcessPath => 'Prozesspfad';

  @override
  String get fieldNetwork => 'Netzwerk';

  @override
  String get fieldSource => 'Quelle';

  @override
  String get fieldDestination => 'Ziel';

  @override
  String get fieldDomain => 'Domain';

  @override
  String get fieldChain => 'Kette';

  @override
  String get fieldRule => 'Regel';

  @override
  String get fieldDuration => 'Dauer';

  @override
  String get fieldStart => 'Beginn';

  @override
  String get connectionClosed => 'Verbindung geschlossen';

  @override
  String get sent => 'Gesendet';

  @override
  String get received => 'Empfangen';

  @override
  String get advanced => 'Erweitert';

  @override
  String get tunAdvancedDescription =>
      'Schnittstellenadresse, MTU, Netzwerk-Stack und Routen. Für die meisten Netze passend — nur ändern, wenn TUN Probleme macht';

  @override
  String get reset => 'Zurücksetzen';

  @override
  String get tunAdvancedWarning =>
      'Ändere diese Werte nur, wenn du die Folgen kennst. MTU 9000 unterbricht SSH und MySQL, eine Adresse aus 172.16.0.0/12 stört Docker-Netze, eine strikte Route fängt den Verkehr im lokalen Netz ab.';

  @override
  String get interfaceAddress => 'Schnittstellenadresse';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'Von $min bis $max';
  }

  @override
  String get networkStack => 'Netzwerk-Stack';

  @override
  String get networkStackDescription =>
      'gvisor — Kompatibilität, system — Geschwindigkeit, mixed — Ausgewogen';

  @override
  String get strictRoute => 'Strikte Route';

  @override
  String get strictRouteDescription =>
      'Verhindert, dass Verkehr den Tunnel umgeht';

  @override
  String get autoRoute => 'Standardroute';

  @override
  String get autoRouteDescription =>
      'Der gesamte Systemverkehr läuft durch den Tunnel';

  @override
  String daysShort(Object n) {
    return '$n T';
  }

  @override
  String get connected => 'Verbunden';

  @override
  String get connecting => 'Verbinde…';

  @override
  String get notConnected => 'Nicht verbunden';

  @override
  String get chooseServerBelow => 'Wähle unten einen Server';

  @override
  String get time => 'Zeit';

  @override
  String get noInternet => 'kein Internet';

  @override
  String get routingRules => 'Routing-Regeln';

  @override
  String get disconnect => 'Trennen';

  @override
  String get connect => 'Verbinden';

  @override
  String get checkingServer => 'Server wird geprüft';

  @override
  String get clickToConnect => 'Zum Verbinden klicken';

  @override
  String get quitVerge => 'Verge beenden';

  @override
  String get noSubscriptionsTray =>
      'Keine Abonnements — füge sie im Hauptfenster hinzu';

  @override
  String get openVerge => 'Verge öffnen';

  @override
  String get noResponse => 'keine Antwort';

  @override
  String get skipCertVerify => 'Zertifikatsprüfung überspringen';

  @override
  String get skipCertVerifyDescription =>
      'Senkt die Sicherheit: Die Verbindung schützt nicht mehr vor gefälschten Servern. Nur zum Debuggen aktivieren';

  @override
  String get tlsFragment => 'TLS-Fragmentierung';

  @override
  String get tlsFragmentDescription =>
      'Teilt den TLS-Handshake auf, um Firewalls mit einfachem ClientHello-Abgleich zu umgehen. Funktioniert nur mit sing-box';

  @override
  String get tlsFragmentUnsupported =>
      'Die aktuelle Engine unterstützt keine Fragmentierung';

  @override
  String get tlsRecordFragment => 'Fragmentierung nach TLS-Records';

  @override
  String get tlsRecordFragmentDescription =>
      'Schont die Leistung — lohnt sich als Erstes';

  @override
  String get fallbackDelay => 'Verzögerung der Ausweichvariante';

  @override
  String get fallbackDelayDescription =>
      'Wie lange auf eine Antwort gewartet wird, bevor es ohne Fragmentierung versucht wird';

  @override
  String versionAvailable(Object version) {
    return 'Version $version ist verfügbar';
  }

  @override
  String get launchingInstaller =>
      'Installer wird gestartet — Verge schließt sich und wird aktualisiert';

  @override
  String get downloadingUpdate => 'Update wird heruntergeladen…';

  @override
  String get updateReady =>
      'Eine neue Version von Verge ist bereit zur Installation';

  @override
  String downloadFailed(Object error) {
    return 'Download fehlgeschlagen: $error';
  }

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get update => 'Aktualisieren';

  @override
  String get later => 'Später';

  @override
  String get whatsNew => 'Neuigkeiten';

  @override
  String get skipVersion => 'Diese Version überspringen';

  @override
  String get installing => 'Wird installiert…';

  @override
  String get downloading => 'Wird heruntergeladen';

  @override
  String get activeConnectionPing => 'Ping der aktiven Verbindung';

  @override
  String get showPing => 'Ping anzeigen';

  @override
  String get showPingDescription =>
      'Latenz zum Server auf der Startseite neben dem Verbindungstimer';

  @override
  String get pingIntervalSeconds => 'Aktualisierungsintervall, s';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'Von $min bis $max s, Standard $def';
  }

  @override
  String get probeUrl => 'Prüfadresse';

  @override
  String get probeUrlDescription =>
      'Im TUN-Modus prüft diese Adresse den Internetzugang außerhalb des Tunnels; im Proxy-Modus misst sie die Latenz über den lokalen Proxy';

  @override
  String get autoSelectNode => 'Automatische Knotenauswahl';

  @override
  String get pickBestNode => 'Besten Knoten wählen';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'Intervall der Hintergrundprüfung, Sekunden ($min…$max)';
  }

  @override
  String get profiles => 'Profile';

  @override
  String get checkNow => 'Jetzt prüfen';

  @override
  String lastCheck(Object time, Object result) {
    return 'Letzte Prüfung: $time — $result';
  }

  @override
  String get nodeResponds => 'Knoten antwortet';

  @override
  String lastPick(Object result) {
    return 'Letzte Auswahl: $result';
  }

  @override
  String get emptyLink => 'Leerer Link';

  @override
  String get clipboardEmpty => 'Zwischenablage ist leer';

  @override
  String get addSubscriptionDescription =>
      'Abonnement-URL, Share-Link (vless://, ss://…) oder JSON-Konfiguration';

  @override
  String get pasteFromClipboardHint =>
      'Link kopiert? Direkt aus der Zwischenablage hinzufügen';

  @override
  String get paste => 'Einfügen';

  @override
  String get or => 'oder';

  @override
  String get subscriptionUrlHint => 'https://… oder vless://…';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get theme => 'Design';

  @override
  String get startup => 'Start';

  @override
  String get autostart => 'Automatisch verbinden';

  @override
  String get autostartDescription =>
      'Beim Start mit dem letzten Knoten verbinden';

  @override
  String get localProxyPort => 'Lokaler Proxy-Port';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS auf 127.0.0.1';

  @override
  String get home => 'Start';

  @override
  String get settings => 'Einstellungen';

  @override
  String get logs => 'Protokolle';

  @override
  String get about => 'Über';

  @override
  String get newBadge => 'neu';

  @override
  String get copy => 'Kopieren';

  @override
  String get clear => 'Leeren';

  @override
  String get searchLogs => 'Protokolle durchsuchen';

  @override
  String get noLogsYet => 'Noch keine Protokolle';

  @override
  String get nothingMatchesFilter => 'Nichts entspricht dem Filter';

  @override
  String get editNode => 'Knoten bearbeiten';

  @override
  String get name => 'Name';

  @override
  String schema(Object engine) {
    return 'Schema: $engine';
  }

  @override
  String get format => 'Formatieren';

  @override
  String get changesOverwrittenOnRefresh =>
      'Änderungen werden beim Aktualisieren des Abonnements überschrieben';

  @override
  String get dnsHijack => 'DNS-Abfang in TUN';

  @override
  String get dnsHijackDescription =>
      'Leitet den gesamten Verkehr auf Port 53 an die DNS-Engine. Ohne ihn gehen Anfragen an den DNS des Providers und werden zensiert';

  @override
  String get dnsProxy => 'DNS für Proxy';

  @override
  String get dnsProxyDescription =>
      'Löst Adressen von Seiten auf, die über das VPN laufen';

  @override
  String get dnsDirect => 'DNS für direkte Verbindungen';

  @override
  String get dnsDirectDescription => 'Für Seiten, die direkt geöffnet werden';

  @override
  String get aboutTagline =>
      'Proxy-Client für macOS und Windows auf Basis von sing-box und Xray.';

  @override
  String get appVersion => 'App-Version';

  @override
  String get checking => 'Wird geprüft…';

  @override
  String get checkForUpdates => 'Nach Updates suchen';

  @override
  String get upToDate => 'Du hast die neueste Version';

  @override
  String get general => 'Allgemein';

  @override
  String get network => 'Netzwerk';

  @override
  String get changesApplyAfterReconnect =>
      'Änderungen gelten nach erneutem Verbinden';

  @override
  String get reconnect => 'Neu verbinden';

  @override
  String get ipv6Description =>
      'Standardmäßig aus: Viele Server nutzen nur IPv4, und IPv6-Verbindungen hängen, statt zurückzufallen';

  @override
  String get presetAllProxy => 'Alles über Proxy';

  @override
  String get presetBypassRu => 'Russland umgehen';

  @override
  String get presetBlockAds => 'Nur Werbeblocker';

  @override
  String get geoRuSites => 'Russland (Seiten)';

  @override
  String get geoRuIp => 'Russland (IP)';

  @override
  String get geoAds => 'Werbung und Tracker';

  @override
  String get geoPrivate => 'Private Domains';

  @override
  String get geoAdult => 'Inhalte für Erwachsene';

  @override
  String get geoCnIp => 'China (IP)';

  @override
  String get geoCnSites => 'China (Seiten)';

  @override
  String get singboxCrashed => 'sing-box ist abgestürzt';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN getrennt: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count Set(s) nicht aktualisiert (Verbindung prüfen)';
  }

  @override
  String refreshFailed(Object names) {
    return 'Aktualisierung fehlgeschlagen: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (Kopie)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'Prüfung $node — ok';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node hat nicht geantwortet ($failures von $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'Knoten $node antwortet nicht — wähle einen anderen';
  }

  @override
  String get helperNotInstalled =>
      'Der Systemdienst ist nicht installiert. Installiere die App mit dem Installer (.pkg) neu.';

  @override
  String updateCheckFailed(Object error) {
    return 'Suche nach Updates fehlgeschlagen: $error';
  }

  @override
  String get updateCheckLatest =>
      'Update-Prüfung: Die neueste Version ist installiert';

  @override
  String updateCheckAvailable(Object version) {
    return 'Update-Prüfung: $version ist verfügbar';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'Update konnte nicht heruntergeladen werden: $error';
  }

  @override
  String get noLiveNodes =>
      'keine erreichbaren Knoten gefunden, Auswahl unverändert';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms ms (HTTP bei keinem Knoten erfolgreich)';
  }

  @override
  String get xrayFailedFallback =>
      'Xray ließ sich nicht starten, Wechsel zu sing-box';

  @override
  String get xrayFailedManual =>
      'Xray ließ sich nicht starten, Engine manuell gewählt — kein Wechsel';

  @override
  String get xrayFailed => 'Xray ließ sich nicht starten';

  @override
  String get vpnNotConnectedXray =>
      'VPN nicht verbunden: Xray ließ sich nicht starten';

  @override
  String get xrayConfigUnsupported =>
      'für diesen Knoten lässt sich keine Xray-Konfiguration erstellen';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray ist nicht gestartet: $error';
  }

  @override
  String get xrayUnavailable => 'Xray ist auf dieser Plattform nicht verfügbar';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray läuft, aber der SOCKS-Port $port antwortet nicht';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'Xray ließ sich nicht starten, läuft mit sing-box';

  @override
  String get engineChosenManually => 'Engine manuell gewählt';

  @override
  String get engineChosenAutomatically => 'Engine automatisch gewählt';

  @override
  String invalidJson(Object message) {
    return 'Ungültiges JSON: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'Ungültiges JSON: $message (Zeichen $offset)';
  }

  @override
  String get tooManyRedirects => 'zu viele Weiterleitungen';

  @override
  String get subscriptionNoValidNodes =>
      'das Abonnement enthält keine gültigen Knoten';

  @override
  String get subscriptionStubNodes =>
      'das Abonnement lieferte Platzhalter-Knoten';

  @override
  String get invalidJsonConfig => 'ungültige JSON-Konfiguration';

  @override
  String get expectedOutboundObject => 'Ein outbound-JSON-Objekt wird erwartet';

  @override
  String get port => 'Port';

  @override
  String testProcessFailed(Object error) {
    return 'Testprozess ließ sich nicht starten: $error';
  }

  @override
  String get language => 'Sprache';

  @override
  String get interfaceLanguage => 'Sprache der Oberfläche';

  @override
  String get languageSystem => 'Systemstandard';

  @override
  String get hotkeys => 'Tastenkürzel';

  @override
  String get toggleHotkey => 'Verbinden / trennen';

  @override
  String get toggleHotkeyDescription =>
      'Globales Kürzel — funktioniert auch bei ausgeblendetem Verge-Fenster';

  @override
  String get hotkeyTaken =>
      'Dieses Kürzel wird von einer anderen App verwendet — wähle ein anderes';

  @override
  String get hotkeyNotSet => 'Nicht festgelegt';

  @override
  String get hotkeyPress => 'Kürzel drücken…';

  @override
  String get hotkeyNeedsModifier => 'Ctrl, Alt oder ⌘/Win hinzufügen';

  @override
  String get hotkeyClear => 'Kürzel entfernen';
}
