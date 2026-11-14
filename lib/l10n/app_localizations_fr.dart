// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get renameProfile => 'Renommer le profil';

  @override
  String get cancel => 'Annuler';

  @override
  String get save => 'Enregistrer';

  @override
  String get subscriptionsUpdated => 'Abonnements mis à jour';

  @override
  String get unitB => 'o';

  @override
  String get unitKB => 'Ko';

  @override
  String get unitMB => 'Mo';

  @override
  String get unitGB => 'Go';

  @override
  String get unitTB => 'To';

  @override
  String usedNoLimit(Object used) {
    return '$used utilisés · sans limite';
  }

  @override
  String validUntil(Object date) {
    return 'jusqu\'au $date';
  }

  @override
  String get timeout => 'délai dépassé';

  @override
  String get error => 'erreur';

  @override
  String get pingAll => 'Tout pinguer';

  @override
  String get refreshSubscriptions => 'Mettre à jour les abonnements';

  @override
  String get addSubscription => 'Ajouter un abonnement';

  @override
  String get servers => 'Serveurs';

  @override
  String get pickingNode => 'Choix du nœud…';

  @override
  String get noSubscriptions =>
      'Aucun abonnement pour l\'instant. Ajoutez le premier.';

  @override
  String get subscriptionHasNoServers =>
      'Cet abonnement ne contient aucun serveur';

  @override
  String get active => 'actif';

  @override
  String get columnServer => 'Serveur';

  @override
  String get columnProtocol => 'Protocole';

  @override
  String get columnEngine => 'Moteur';

  @override
  String get columnLatency => 'Latence';

  @override
  String ms(Object ms) {
    return '$ms ms';
  }

  @override
  String engineAuto(Object engine) {
    return 'Auto ($engine)';
  }

  @override
  String get edit => 'Modifier';

  @override
  String get ping => 'Ping';

  @override
  String get refresh => 'Mettre à jour';

  @override
  String get subscriptionLinkCopied => 'Lien d\'abonnement copié';

  @override
  String get subscription => 'Abonnement';

  @override
  String get accountPage => 'Compte';

  @override
  String get support => 'Assistance';

  @override
  String get autoRefresh => 'Mise à jour automatique';

  @override
  String get rename => 'Renommer';

  @override
  String get delete => 'Supprimer';

  @override
  String get autoSelectOn => 'Sélection auto : activée';

  @override
  String get autoSelect => 'Sélection auto';

  @override
  String refreshOwn(Object hours) {
    return 'Personnalisé : $hours h';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'Selon l\'abonnement : $hours h';
  }

  @override
  String get off => 'Désactivé';

  @override
  String get autoRefreshInterval => 'Intervalle de mise à jour automatique';

  @override
  String get hours => 'Heures';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'Vide — utiliser l\'intervalle de l\'abonnement ($hours h)';
  }

  @override
  String get emptyNoAutoRefresh => 'Vide — pas de mise à jour automatique';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count serveurs',
      one: '$count serveur',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used sur $total';
  }

  @override
  String remaining(Object amount) {
    return 'reste $amount';
  }

  @override
  String get limitExhausted => 'limite atteinte';

  @override
  String get newProfile => 'Nouveau profil';

  @override
  String get routing => 'Routage';

  @override
  String get updateGeo => 'Mettre à jour la géo';

  @override
  String get profile => 'Profil';

  @override
  String get routingSubtitle =>
      'Ce qui passe par le VPN, ce qui passe en direct et ce qui est bloqué';

  @override
  String get geoNeverUpdated => 'jamais mis à jour — versions intégrées';

  @override
  String geoUpdated(Object ago) {
    return 'mis à jour $ago';
  }

  @override
  String geoSets(Object status) {
    return 'Jeux géo (.srs) : $status';
  }

  @override
  String get justNow => 'à l\'instant';

  @override
  String minutesAgo(Object n) {
    return 'il y a $n min';
  }

  @override
  String hoursAgo(Object n) {
    return 'il y a $n h';
  }

  @override
  String daysAgo(Object n) {
    return 'il y a $n j';
  }

  @override
  String get restDirect => 'le reste en direct';

  @override
  String get restViaVpn => 'le reste via le VPN';

  @override
  String get builtIn => 'Intégré';

  @override
  String get custom => 'Personnalisé';

  @override
  String get allDirect => 'tout en direct';

  @override
  String get allViaVpn => 'tout via le VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count règles',
      one: '$count règle',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'Via le VPN';

  @override
  String get groupDirect => 'Direct';

  @override
  String get groupBlock => 'Bloquer';

  @override
  String get groupExceptions => 'Exceptions (prioritaires sur le blocage)';

  @override
  String get exceptionsGo => 'Les exceptions passent';

  @override
  String get viaVpn => 'via le VPN';

  @override
  String get direct => 'en direct';

  @override
  String get duplicate => 'Dupliquer';

  @override
  String get use => 'Utiliser';

  @override
  String get builtInProfileReadOnly =>
      'Les profils intégrés ne sont pas modifiables — dupliquez-en un pour adapter ses règles.';

  @override
  String get everythingElse => 'Tout ce qui ne correspond à aucune règle';

  @override
  String get empty => 'Vide';

  @override
  String get chooseCategory => 'Choisir une catégorie';

  @override
  String get domainOrCidr => 'Domaine ou IP/CIDR';

  @override
  String get add => 'Ajouter';

  @override
  String get domainOrCidrHint => 'example.com ou 1.2.3.0/24';

  @override
  String get geoCategory => 'Catégorie géo';

  @override
  String get domainOrIp => 'Domaine ou IP';

  @override
  String get addRule => 'Ajouter une règle';

  @override
  String get kindProxy => 'Proxy';

  @override
  String get kindBlock => 'Blocage';

  @override
  String get otherApps => 'Autres';

  @override
  String get noActiveConnections => 'Aucune connexion active';

  @override
  String get vpnDisconnected => 'Le VPN est désactivé';

  @override
  String get nothingFound => 'Aucun résultat';

  @override
  String get connections => 'Connexions';

  @override
  String get byApp => 'Par application';

  @override
  String get asList => 'Liste';

  @override
  String get connectionsSearchHint => 'Domaine, IP ou application';

  @override
  String get all => 'Toutes';

  @override
  String get close => 'Fermer';

  @override
  String get kindProxyShort => 'proxy';

  @override
  String get kindBlockShort => 'blocage';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count connexions',
      one: '$count connexion',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'Application';

  @override
  String get fieldProcessPath => 'Chemin du processus';

  @override
  String get fieldNetwork => 'Réseau';

  @override
  String get fieldSource => 'Source';

  @override
  String get fieldDestination => 'Destination';

  @override
  String get fieldDomain => 'Domaine';

  @override
  String get fieldChain => 'Chaîne';

  @override
  String get fieldRule => 'Règle';

  @override
  String get fieldDuration => 'Durée';

  @override
  String get fieldStart => 'Début';

  @override
  String get connectionClosed => 'connexion fermée';

  @override
  String get sent => 'Envoyé';

  @override
  String get received => 'Reçu';

  @override
  String get advanced => 'Avancé';

  @override
  String get tunAdvancedDescription =>
      'Adresse de l\'interface, MTU, pile réseau et routes. Adaptés à la plupart des réseaux — à modifier seulement si TUN pose problème';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get tunAdvancedWarning =>
      'Ne modifiez ces valeurs que si vous en comprenez les conséquences. Un MTU de 9000 coupe SSH et MySQL, une adresse en 172.16.0.0/12 casse les réseaux docker, la route stricte intercepte le trafic du réseau local.';

  @override
  String get interfaceAddress => 'Adresse de l\'interface';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'De $min à $max';
  }

  @override
  String get networkStack => 'Pile réseau';

  @override
  String get networkStackDescription =>
      'gvisor — compatibilité, system — vitesse, mixed — équilibre';

  @override
  String get strictRoute => 'Route stricte';

  @override
  String get strictRouteDescription =>
      'Empêche le trafic de contourner le tunnel';

  @override
  String get autoRoute => 'Route par défaut';

  @override
  String get autoRouteDescription =>
      'Tout le trafic du système passe par le tunnel';

  @override
  String daysShort(Object n) {
    return '$n j';
  }

  @override
  String get connected => 'Connecté';

  @override
  String get connecting => 'Connexion…';

  @override
  String get notConnected => 'Non connecté';

  @override
  String get chooseServerBelow => 'Choisissez un serveur ci-dessous';

  @override
  String get time => 'Durée';

  @override
  String get noInternet => 'pas d\'internet';

  @override
  String get routingRules => 'Règles de routage';

  @override
  String get disconnect => 'Se déconnecter';

  @override
  String get connect => 'Se connecter';

  @override
  String get checkingServer => 'Vérification du serveur';

  @override
  String get clickToConnect => 'Cliquez pour vous connecter';

  @override
  String get quitVerge => 'Quitter Verge';

  @override
  String get noSubscriptionsTray =>
      'Aucun abonnement — ajoutez-en dans la fenêtre principale';

  @override
  String get openVerge => 'Ouvrir Verge';

  @override
  String get noResponse => 'pas de réponse';

  @override
  String get skipCertVerify => 'Ignorer la vérification du certificat';

  @override
  String get skipCertVerifyDescription =>
      'Réduit la sécurité : la connexion ne protège plus contre l\'usurpation du serveur. À activer uniquement pour le débogage';

  @override
  String get tlsFragment => 'Fragmentation TLS';

  @override
  String get tlsFragmentDescription =>
      'Découpe la poignée de main TLS en morceaux pour contourner les pare-feu qui analysent le ClientHello de façon naïve. Fonctionne uniquement avec sing-box';

  @override
  String get tlsFragmentUnsupported =>
      'Le moteur actuel ne prend pas en charge la fragmentation';

  @override
  String get tlsRecordFragment => 'Fragmentation par enregistrements TLS';

  @override
  String get tlsRecordFragmentDescription =>
      'Moins coûteuse en performances — à essayer en premier';

  @override
  String get fallbackDelay => 'Délai de repli';

  @override
  String get fallbackDelayDescription =>
      'Temps d\'attente d\'une réponse avant de réessayer sans fragmentation';

  @override
  String versionAvailable(Object version) {
    return 'La version $version est disponible';
  }

  @override
  String get launchingInstaller =>
      'Lancement du programme d\'installation — Verge va se fermer et se mettre à jour';

  @override
  String get downloadingUpdate => 'Téléchargement de la mise à jour…';

  @override
  String get updateReady =>
      'Une nouvelle version de Verge est prête à être installée';

  @override
  String downloadFailed(Object error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get retry => 'Réessayer';

  @override
  String get update => 'Mettre à jour';

  @override
  String get later => 'Plus tard';

  @override
  String get whatsNew => 'Nouveautés';

  @override
  String get skipVersion => 'Ignorer cette version';

  @override
  String get installing => 'Installation…';

  @override
  String get downloading => 'Téléchargement';

  @override
  String get activeConnectionPing => 'Ping de la connexion active';

  @override
  String get showPing => 'Afficher le ping';

  @override
  String get showPingDescription =>
      'Latence vers le serveur sur l\'écran d\'accueil, à côté du minuteur de connexion';

  @override
  String get pingIntervalSeconds => 'Intervalle d\'actualisation, s';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'De $min à $max s, $def par défaut';
  }

  @override
  String get probeUrl => 'Adresse de test';

  @override
  String get probeUrlDescription =>
      'En mode TUN, cette adresse vérifie l\'accès à internet hors du tunnel ; en mode Proxy, elle mesure la latence via le proxy local';

  @override
  String get autoSelectNode => 'Sélection automatique du nœud';

  @override
  String get pickBestNode => 'Choisir le meilleur nœud';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'Intervalle de vérification en arrière-plan, secondes ($min…$max)';
  }

  @override
  String get profiles => 'Profils';

  @override
  String get checkNow => 'Vérifier maintenant';

  @override
  String lastCheck(Object time, Object result) {
    return 'Dernière vérification : $time — $result';
  }

  @override
  String get nodeResponds => 'le nœud répond';

  @override
  String lastPick(Object result) {
    return 'Dernier choix : $result';
  }

  @override
  String get emptyLink => 'Lien vide';

  @override
  String get clipboardEmpty => 'Le presse-papiers est vide';

  @override
  String get addSubscriptionDescription =>
      'URL d\'abonnement, lien de partage (vless://, ss://…) ou configuration JSON';

  @override
  String get pasteFromClipboardHint =>
      'Vous avez copié un lien ? Ajoutez-le directement depuis le presse-papiers';

  @override
  String get paste => 'Coller';

  @override
  String get or => 'ou';

  @override
  String get subscriptionUrlHint => 'https://… ou vless://…';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

  @override
  String get theme => 'Thème';

  @override
  String get startup => 'Démarrage';

  @override
  String get autostart => 'Connexion automatique';

  @override
  String get autostartDescription =>
      'Se connecter au dernier nœud au démarrage';

  @override
  String get localProxyPort => 'Port du proxy local';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS sur 127.0.0.1';

  @override
  String get home => 'Accueil';

  @override
  String get settings => 'Réglages';

  @override
  String get logs => 'Journaux';

  @override
  String get about => 'À propos';

  @override
  String get newBadge => 'nouveau';

  @override
  String get copy => 'Copier';

  @override
  String get clear => 'Effacer';

  @override
  String get searchLogs => 'Rechercher dans les journaux';

  @override
  String get noLogsYet => 'Aucun journal pour l\'instant';

  @override
  String get nothingMatchesFilter => 'Rien ne correspond au filtre';

  @override
  String get editNode => 'Modifier le nœud';

  @override
  String get name => 'Nom';

  @override
  String schema(Object engine) {
    return 'Schéma : $engine';
  }

  @override
  String get format => 'Formater';

  @override
  String get changesOverwrittenOnRefresh =>
      'Les modifications seront écrasées lors de la mise à jour de l\'abonnement';

  @override
  String get dnsHijack => 'Interception DNS en TUN';

  @override
  String get dnsHijackDescription =>
      'Redirige tout le trafic du port 53 vers le moteur DNS. Sans cela, les requêtes partent vers le DNS du fournisseur et sont censurées';

  @override
  String get dnsProxy => 'DNS pour le proxy';

  @override
  String get dnsProxyDescription => 'Résout les sites qui passent par le VPN';

  @override
  String get dnsDirect => 'DNS pour les connexions directes';

  @override
  String get dnsDirectDescription => 'Pour les sites ouverts en direct';

  @override
  String get aboutTagline =>
      'Client proxy pour macOS et Windows basé sur sing-box et Xray.';

  @override
  String get appVersion => 'Version de l\'application';

  @override
  String get checking => 'Vérification…';

  @override
  String get checkForUpdates => 'Rechercher des mises à jour';

  @override
  String get upToDate => 'Vous avez la dernière version';

  @override
  String get general => 'Général';

  @override
  String get network => 'Réseau';

  @override
  String get changesApplyAfterReconnect =>
      'Les modifications s\'appliqueront après reconnexion';

  @override
  String get reconnect => 'Se reconnecter';

  @override
  String get ipv6Description =>
      'Désactivé par défaut : beaucoup de serveurs ne gèrent que l\'IPv4, et les connexions IPv6 se bloquent au lieu de basculer';

  @override
  String get presetAllProxy => 'Tout via le proxy';

  @override
  String get presetBypassRu => 'Contourner la Russie';

  @override
  String get presetBlockAds => 'Blocage des pubs uniquement';

  @override
  String get geoRuSites => 'Russie (sites)';

  @override
  String get geoRuIp => 'Russie (IP)';

  @override
  String get geoAds => 'Publicités et traqueurs';

  @override
  String get geoPrivate => 'Domaines privés';

  @override
  String get geoAdult => 'Contenu pour adultes';

  @override
  String get geoCnIp => 'Chine (IP)';

  @override
  String get geoCnSites => 'Chine (sites)';

  @override
  String get singboxCrashed => 'sing-box s\'est arrêté de façon inattendue';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN déconnecté : $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count jeu(x) non mis à jour (vérifiez la connexion)';
  }

  @override
  String refreshFailed(Object names) {
    return 'Échec de la mise à jour : $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (copie)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'vérification de $node — ok';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node n\'a pas répondu ($failures sur $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'Le nœud $node ne répond pas — choix d\'un autre nœud';
  }

  @override
  String get helperNotInstalled =>
      'Le service système n\'est pas installé. Réinstallez l\'application avec le programme d\'installation (.pkg).';

  @override
  String updateCheckFailed(Object error) {
    return 'Impossible de rechercher les mises à jour : $error';
  }

  @override
  String get updateCheckLatest =>
      'Recherche de mises à jour : la dernière version est installée';

  @override
  String updateCheckAvailable(Object version) {
    return 'Recherche de mises à jour : $version est disponible';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'Impossible de télécharger la mise à jour : $error';
  }

  @override
  String get noLiveNodes => 'aucun nœud actif trouvé, sélection inchangée';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms ms (HTTP a échoué sur tous les nœuds)';
  }

  @override
  String get xrayFailedFallback => 'Xray n\'a pas démarré, repli sur sing-box';

  @override
  String get xrayFailedManual =>
      'Xray n\'a pas démarré, moteur choisi manuellement — pas de repli';

  @override
  String get xrayFailed => 'Xray n\'a pas démarré';

  @override
  String get vpnNotConnectedXray => 'VPN non connecté : Xray n\'a pas démarré';

  @override
  String get xrayConfigUnsupported =>
      'impossible de générer une configuration Xray pour ce nœud';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray n\'a pas démarré : $error';
  }

  @override
  String get xrayUnavailable =>
      'Xray n\'est pas disponible sur cette plateforme';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray a démarré, mais le port socks $port ne répond pas';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'Xray n\'a pas démarré, fonctionnement avec sing-box';

  @override
  String get engineChosenManually => 'Moteur choisi manuellement';

  @override
  String get engineChosenAutomatically => 'Moteur choisi automatiquement';

  @override
  String invalidJson(Object message) {
    return 'JSON invalide : $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'JSON invalide : $message (caractère $offset)';
  }

  @override
  String get tooManyRedirects => 'trop de redirections';

  @override
  String get subscriptionNoValidNodes =>
      'l\'abonnement ne contient aucun nœud valide';

  @override
  String get subscriptionStubNodes =>
      'l\'abonnement a renvoyé des nœuds factices';

  @override
  String get invalidJsonConfig => 'configuration JSON invalide';

  @override
  String get expectedOutboundObject => 'Un objet JSON outbound est attendu';

  @override
  String get port => 'port';

  @override
  String testProcessFailed(Object error) {
    return 'le processus de test n\'a pas démarré : $error';
  }

  @override
  String get language => 'Langue';

  @override
  String get interfaceLanguage => 'Langue de l\'interface';

  @override
  String get languageSystem => 'Langue du système';

  @override
  String get hotkeys => 'Raccourcis clavier';

  @override
  String get toggleHotkey => 'Connecter / déconnecter';

  @override
  String get toggleHotkeyDescription =>
      'Raccourci global — fonctionne même quand la fenêtre de Verge est masquée';

  @override
  String get hotkeyTaken =>
      'Ce raccourci est utilisé par une autre application — choisissez-en un autre';

  @override
  String get hotkeyNotSet => 'Non défini';

  @override
  String get hotkeyPress => 'Appuyez sur un raccourci…';

  @override
  String get hotkeyNeedsModifier => 'Ajoutez Ctrl, Alt ou ⌘/Win';

  @override
  String get hotkeyClear => 'Supprimer le raccourci';
}
