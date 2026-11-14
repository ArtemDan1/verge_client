// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get renameProfile => 'Rename profile';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get subscriptionsUpdated => 'Subscriptions updated';

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
    return '$used used · no limit';
  }

  @override
  String validUntil(Object date) {
    return 'until $date';
  }

  @override
  String get timeout => 'timeout';

  @override
  String get error => 'error';

  @override
  String get pingAll => 'Ping all';

  @override
  String get refreshSubscriptions => 'Refresh subscriptions';

  @override
  String get addSubscription => 'Add subscription';

  @override
  String get servers => 'Servers';

  @override
  String get pickingNode => 'Picking a node…';

  @override
  String get noSubscriptions => 'No subscriptions yet. Add the first one.';

  @override
  String get subscriptionHasNoServers => 'This subscription has no servers';

  @override
  String get active => 'active';

  @override
  String get columnServer => 'Server';

  @override
  String get columnProtocol => 'Protocol';

  @override
  String get columnEngine => 'Engine';

  @override
  String get columnLatency => 'Latency';

  @override
  String ms(Object ms) {
    return '$ms ms';
  }

  @override
  String engineAuto(Object engine) {
    return 'Auto ($engine)';
  }

  @override
  String get edit => 'Edit';

  @override
  String get ping => 'Ping';

  @override
  String get refresh => 'Refresh';

  @override
  String get subscriptionLinkCopied => 'Subscription link copied';

  @override
  String get subscription => 'Subscription';

  @override
  String get accountPage => 'Account';

  @override
  String get support => 'Support';

  @override
  String get autoRefresh => 'Auto-refresh';

  @override
  String get rename => 'Rename';

  @override
  String get delete => 'Delete';

  @override
  String get autoSelectOn => 'Auto-select: on';

  @override
  String get autoSelect => 'Auto-select';

  @override
  String refreshOwn(Object hours) {
    return 'Custom: $hours h';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'From subscription: $hours h';
  }

  @override
  String get off => 'Off';

  @override
  String get autoRefreshInterval => 'Auto-refresh interval';

  @override
  String get hours => 'Hours';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'Empty — use the subscription interval ($hours h)';
  }

  @override
  String get emptyNoAutoRefresh => 'Empty — don\'t refresh automatically';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count servers',
      one: '$count server',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used of $total';
  }

  @override
  String remaining(Object amount) {
    return '$amount left';
  }

  @override
  String get limitExhausted => 'limit reached';

  @override
  String get newProfile => 'New profile';

  @override
  String get routing => 'Routing';

  @override
  String get updateGeo => 'Update geo';

  @override
  String get profile => 'Profile';

  @override
  String get routingSubtitle =>
      'What goes through the VPN, what goes direct, and what is blocked';

  @override
  String get geoNeverUpdated => 'never updated — bundled versions';

  @override
  String geoUpdated(Object ago) {
    return 'updated $ago';
  }

  @override
  String geoSets(Object status) {
    return 'Geo sets (.srs): $status';
  }

  @override
  String get justNow => 'just now';

  @override
  String minutesAgo(Object n) {
    return '$n min ago';
  }

  @override
  String hoursAgo(Object n) {
    return '$n h ago';
  }

  @override
  String daysAgo(Object n) {
    return '$n d ago';
  }

  @override
  String get restDirect => 'the rest direct';

  @override
  String get restViaVpn => 'the rest via VPN';

  @override
  String get builtIn => 'Built-in';

  @override
  String get custom => 'Custom';

  @override
  String get allDirect => 'everything direct';

  @override
  String get allViaVpn => 'everything via VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rules',
      one: '$count rule',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'Via VPN';

  @override
  String get groupDirect => 'Direct';

  @override
  String get groupBlock => 'Block';

  @override
  String get groupExceptions => 'Exceptions (override block)';

  @override
  String get exceptionsGo => 'Exceptions go';

  @override
  String get viaVpn => 'via VPN';

  @override
  String get direct => 'direct';

  @override
  String get duplicate => 'Duplicate';

  @override
  String get use => 'Use';

  @override
  String get builtInProfileReadOnly =>
      'Built-in profiles can\'t be changed — duplicate one to customize its rules.';

  @override
  String get everythingElse => 'Everything not matched by rules';

  @override
  String get empty => 'Empty';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get domainOrCidr => 'Domain or IP/CIDR';

  @override
  String get add => 'Add';

  @override
  String get domainOrCidrHint => 'example.com or 1.2.3.0/24';

  @override
  String get geoCategory => 'Geo category';

  @override
  String get domainOrIp => 'Domain or IP';

  @override
  String get addRule => 'Add rule';

  @override
  String get kindProxy => 'Proxy';

  @override
  String get kindBlock => 'Block';

  @override
  String get otherApps => 'Other';

  @override
  String get noActiveConnections => 'No active connections';

  @override
  String get vpnDisconnected => 'VPN is off';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String get connections => 'Connections';

  @override
  String get byApp => 'By app';

  @override
  String get asList => 'List';

  @override
  String get connectionsSearchHint => 'Domain, IP or app';

  @override
  String get all => 'All';

  @override
  String get close => 'Close';

  @override
  String get kindProxyShort => 'proxy';

  @override
  String get kindBlockShort => 'block';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connections',
      one: '$count connection',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'App';

  @override
  String get fieldProcessPath => 'Process path';

  @override
  String get fieldNetwork => 'Network';

  @override
  String get fieldSource => 'Source';

  @override
  String get fieldDestination => 'Destination';

  @override
  String get fieldDomain => 'Domain';

  @override
  String get fieldChain => 'Chain';

  @override
  String get fieldRule => 'Rule';

  @override
  String get fieldDuration => 'Duration';

  @override
  String get fieldStart => 'Started';

  @override
  String get connectionClosed => 'connection closed';

  @override
  String get sent => 'Sent';

  @override
  String get received => 'Received';

  @override
  String get advanced => 'Advanced';

  @override
  String get tunAdvancedDescription =>
      'Interface address, MTU, network stack and routes. Tuned for most networks — change only if TUN misbehaves';

  @override
  String get reset => 'Reset';

  @override
  String get tunAdvancedWarning =>
      'Change these values only if you understand the consequences. MTU 9000 breaks SSH and MySQL, an address from 172.16.0.0/12 breaks docker networks, strict route captures local network traffic.';

  @override
  String get interfaceAddress => 'Interface address';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'From $min to $max';
  }

  @override
  String get networkStack => 'Network stack';

  @override
  String get networkStackDescription =>
      'gvisor — compatibility, system — speed, mixed — balance';

  @override
  String get strictRoute => 'Strict route';

  @override
  String get strictRouteDescription =>
      'Keeps traffic from bypassing the tunnel';

  @override
  String get autoRoute => 'Default route';

  @override
  String get autoRouteDescription => 'All system traffic goes into the tunnel';

  @override
  String daysShort(Object n) {
    return '${n}d';
  }

  @override
  String get connected => 'Connected';

  @override
  String get connecting => 'Connecting…';

  @override
  String get notConnected => 'Not connected';

  @override
  String get chooseServerBelow => 'Choose a server below';

  @override
  String get time => 'Time';

  @override
  String get noInternet => 'no internet';

  @override
  String get routingRules => 'Routing rules';

  @override
  String get disconnect => 'Disconnect';

  @override
  String get connect => 'Connect';

  @override
  String get checkingServer => 'Checking the server';

  @override
  String get clickToConnect => 'Click to connect';

  @override
  String get quitVerge => 'Quit Verge';

  @override
  String get noSubscriptionsTray =>
      'No subscriptions — add them in the main window';

  @override
  String get openVerge => 'Open Verge';

  @override
  String get noResponse => 'no response';

  @override
  String get skipCertVerify => 'Skip certificate verification';

  @override
  String get skipCertVerifyDescription =>
      'Lowers security: the connection no longer protects against server spoofing. Enable only for debugging';

  @override
  String get tlsFragment => 'TLS fragmentation';

  @override
  String get tlsFragmentDescription =>
      'Splits the TLS handshake into pieces to get past firewalls that do naive ClientHello matching. Works with sing-box only';

  @override
  String get tlsFragmentUnsupported =>
      'The current engine does not support fragmentation';

  @override
  String get tlsRecordFragment => 'TLS record fragmentation';

  @override
  String get tlsRecordFragmentDescription =>
      'Cheaper on performance — worth trying first';

  @override
  String get fallbackDelay => 'Fallback delay';

  @override
  String get fallbackDelayDescription =>
      'How long to wait for a response before retrying without fragmentation';

  @override
  String versionAvailable(Object version) {
    return 'Version $version is available';
  }

  @override
  String get launchingInstaller =>
      'Launching the installer — Verge will close and update';

  @override
  String get downloadingUpdate => 'Downloading the update…';

  @override
  String get updateReady => 'A new version of Verge is ready to install';

  @override
  String downloadFailed(Object error) {
    return 'Download failed: $error';
  }

  @override
  String get retry => 'Retry';

  @override
  String get update => 'Update';

  @override
  String get later => 'Later';

  @override
  String get whatsNew => 'What\'s new';

  @override
  String get skipVersion => 'Skip this version';

  @override
  String get installing => 'Installing…';

  @override
  String get downloading => 'Downloading';

  @override
  String get activeConnectionPing => 'Active connection ping';

  @override
  String get showPing => 'Show ping';

  @override
  String get showPingDescription =>
      'Server latency on the home screen, next to the connection timer';

  @override
  String get pingIntervalSeconds => 'Refresh interval, s';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'From $min to $max s, default $def';
  }

  @override
  String get probeUrl => 'Probe URL';

  @override
  String get probeUrlDescription =>
      'In TUN mode this URL checks internet access outside the tunnel; in Proxy mode it measures latency through the local proxy';

  @override
  String get autoSelectNode => 'Node auto-select';

  @override
  String get pickBestNode => 'Pick the best node';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'Background check interval, seconds ($min…$max)';
  }

  @override
  String get profiles => 'Profiles';

  @override
  String get checkNow => 'Check now';

  @override
  String lastCheck(Object time, Object result) {
    return 'Last check: $time — $result';
  }

  @override
  String get nodeResponds => 'node responds';

  @override
  String lastPick(Object result) {
    return 'Last pick: $result';
  }

  @override
  String get emptyLink => 'Empty link';

  @override
  String get clipboardEmpty => 'Clipboard is empty';

  @override
  String get addSubscriptionDescription =>
      'Subscription URL, share link (vless://, ss://…) or JSON config';

  @override
  String get pasteFromClipboardHint =>
      'Copied a link? Add it straight from the clipboard';

  @override
  String get paste => 'Paste';

  @override
  String get or => 'or';

  @override
  String get subscriptionUrlHint => 'https://… or vless://…';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get theme => 'Theme';

  @override
  String get startup => 'Startup';

  @override
  String get autostart => 'Auto-connect';

  @override
  String get autostartDescription => 'Connect to the last node on launch';

  @override
  String get localProxyPort => 'Local proxy port';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS on 127.0.0.1';

  @override
  String get home => 'Home';

  @override
  String get settings => 'Settings';

  @override
  String get logs => 'Logs';

  @override
  String get about => 'About';

  @override
  String get newBadge => 'new';

  @override
  String get copy => 'Copy';

  @override
  String get clear => 'Clear';

  @override
  String get searchLogs => 'Search logs';

  @override
  String get noLogsYet => 'No logs yet';

  @override
  String get nothingMatchesFilter => 'Nothing matches the filter';

  @override
  String get editNode => 'Edit node';

  @override
  String get name => 'Name';

  @override
  String schema(Object engine) {
    return 'Schema: $engine';
  }

  @override
  String get format => 'Format';

  @override
  String get changesOverwrittenOnRefresh =>
      'Changes will be overwritten when the subscription refreshes';

  @override
  String get dnsHijack => 'DNS hijack in TUN';

  @override
  String get dnsHijackDescription =>
      'Redirects all port 53 traffic to the DNS engine. Without it, queries go to the ISP\'s DNS and get censored';

  @override
  String get dnsProxy => 'DNS for proxy';

  @override
  String get dnsProxyDescription => 'Resolves sites that go through the VPN';

  @override
  String get dnsDirect => 'DNS for direct connections';

  @override
  String get dnsDirectDescription => 'For sites that open directly';

  @override
  String get aboutTagline =>
      'A proxy client for macOS and Windows built on sing-box and Xray.';

  @override
  String get appVersion => 'App version';

  @override
  String get checking => 'Checking…';

  @override
  String get checkForUpdates => 'Check for updates';

  @override
  String get upToDate => 'You have the latest version';

  @override
  String get general => 'General';

  @override
  String get network => 'Network';

  @override
  String get changesApplyAfterReconnect =>
      'Changes will apply after reconnecting';

  @override
  String get reconnect => 'Reconnect';

  @override
  String get ipv6Description =>
      'Off by default: many servers are IPv4-only, and IPv6 connections hang instead of falling back';

  @override
  String get presetAllProxy => 'Everything via proxy';

  @override
  String get presetBypassRu => 'Bypass Russia';

  @override
  String get presetBlockAds => 'Ad blocking only';

  @override
  String get geoRuSites => 'Russia (sites)';

  @override
  String get geoRuIp => 'Russia (IP)';

  @override
  String get geoAds => 'Ads and trackers';

  @override
  String get geoPrivate => 'Private domains';

  @override
  String get geoAdult => 'Adult content';

  @override
  String get geoCnIp => 'China (IP)';

  @override
  String get geoCnSites => 'China (sites)';

  @override
  String get singboxCrashed => 'sing-box crashed';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN disconnected: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count set(s) not updated (check your connection)';
  }

  @override
  String refreshFailed(Object names) {
    return 'Failed to refresh: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (copy)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'check $node — ok';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node did not respond ($failures of $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'Node $node is not responding — picking another one';
  }

  @override
  String get helperNotInstalled =>
      'The system service is not installed. Reinstall the app using the installer (.pkg).';

  @override
  String updateCheckFailed(Object error) {
    return 'Failed to check for updates: $error';
  }

  @override
  String get updateCheckLatest =>
      'Update check: the latest version is installed';

  @override
  String updateCheckAvailable(Object version) {
    return 'Update check: $version is available';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'Failed to download the update: $error';
  }

  @override
  String get noLiveNodes => 'no live nodes found, selection unchanged';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms ms (HTTP failed on every node)';
  }

  @override
  String get xrayFailedFallback =>
      'Xray failed to start, falling back to sing-box';

  @override
  String get xrayFailedManual =>
      'Xray failed to start, engine was chosen manually — no fallback';

  @override
  String get xrayFailed => 'Xray failed to start';

  @override
  String get vpnNotConnectedXray => 'VPN not connected: Xray failed to start';

  @override
  String get xrayConfigUnsupported =>
      'an Xray config can\'t be built for this node';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray did not start: $error';
  }

  @override
  String get xrayUnavailable => 'Xray is not available on this platform';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray started, but socks port $port is not responding';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'Xray failed to start, running on sing-box';

  @override
  String get engineChosenManually => 'Engine chosen manually';

  @override
  String get engineChosenAutomatically => 'Engine chosen automatically';

  @override
  String invalidJson(Object message) {
    return 'Invalid JSON: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'Invalid JSON: $message (character $offset)';
  }

  @override
  String get tooManyRedirects => 'too many redirects';

  @override
  String get subscriptionNoValidNodes => 'the subscription has no valid nodes';

  @override
  String get subscriptionStubNodes =>
      'the subscription returned placeholder nodes';

  @override
  String get invalidJsonConfig => 'invalid JSON config';

  @override
  String get expectedOutboundObject => 'Expected an outbound JSON object';

  @override
  String get port => 'port';

  @override
  String testProcessFailed(Object error) {
    return 'test process failed to start: $error';
  }

  @override
  String get language => 'Language';

  @override
  String get interfaceLanguage => 'Interface language';

  @override
  String get languageSystem => 'System default';

  @override
  String get hotkeys => 'Hotkeys';

  @override
  String get toggleHotkey => 'Connect / disconnect';

  @override
  String get toggleHotkeyDescription =>
      'Global shortcut — works even when the Verge window is hidden';

  @override
  String get hotkeyTaken =>
      'This shortcut is used by another app — choose a different one';

  @override
  String get hotkeyNotSet => 'Not set';

  @override
  String get hotkeyPress => 'Press a shortcut…';

  @override
  String get hotkeyNeedsModifier => 'Add Ctrl, Alt or ⌘/Win';

  @override
  String get hotkeyClear => 'Remove shortcut';
}
