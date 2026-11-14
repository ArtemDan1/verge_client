// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get renameProfile => 'Profili yeniden adlandır';

  @override
  String get cancel => 'İptal';

  @override
  String get save => 'Kaydet';

  @override
  String get subscriptionsUpdated => 'Abonelikler güncellendi';

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
    return '$used kullanıldı · limitsiz';
  }

  @override
  String validUntil(Object date) {
    return '$date tarihine kadar';
  }

  @override
  String get timeout => 'zaman aşımı';

  @override
  String get error => 'hata';

  @override
  String get pingAll => 'Tümüne ping at';

  @override
  String get refreshSubscriptions => 'Abonelikleri güncelle';

  @override
  String get addSubscription => 'Abonelik ekle';

  @override
  String get servers => 'Sunucular';

  @override
  String get pickingNode => 'Düğüm seçiliyor…';

  @override
  String get noSubscriptions => 'Henüz abonelik yok. İlkini ekleyin.';

  @override
  String get subscriptionHasNoServers => 'Bu abonelikte sunucu yok';

  @override
  String get active => 'etkin';

  @override
  String get columnServer => 'Sunucu';

  @override
  String get columnProtocol => 'Protokol';

  @override
  String get columnEngine => 'Motor';

  @override
  String get columnLatency => 'Gecikme';

  @override
  String ms(Object ms) {
    return '$ms ms';
  }

  @override
  String engineAuto(Object engine) {
    return 'Otomatik ($engine)';
  }

  @override
  String get edit => 'Düzenle';

  @override
  String get ping => 'Ping';

  @override
  String get refresh => 'Güncelle';

  @override
  String get subscriptionLinkCopied => 'Abonelik bağlantısı kopyalandı';

  @override
  String get subscription => 'Abonelik';

  @override
  String get accountPage => 'Hesap';

  @override
  String get support => 'Destek';

  @override
  String get autoRefresh => 'Otomatik güncelleme';

  @override
  String get rename => 'Yeniden adlandır';

  @override
  String get delete => 'Sil';

  @override
  String get autoSelectOn => 'Otomatik seçim: açık';

  @override
  String get autoSelect => 'Otomatik seçim';

  @override
  String refreshOwn(Object hours) {
    return 'Özel: $hours sa';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'Aboneliğe göre: $hours sa';
  }

  @override
  String get off => 'Kapalı';

  @override
  String get autoRefreshInterval => 'Otomatik güncelleme aralığı';

  @override
  String get hours => 'Saat';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'Boş — aboneliğin aralığını kullan ($hours sa)';
  }

  @override
  String get emptyNoAutoRefresh => 'Boş — otomatik güncelleme yok';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sunucu',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used / $total';
  }

  @override
  String remaining(Object amount) {
    return '$amount kaldı';
  }

  @override
  String get limitExhausted => 'limit doldu';

  @override
  String get newProfile => 'Yeni profil';

  @override
  String get routing => 'Yönlendirme';

  @override
  String get updateGeo => 'Geo güncelle';

  @override
  String get profile => 'Profil';

  @override
  String get routingSubtitle =>
      'Neyin VPN\'den, neyin doğrudan geçeceği ve neyin engelleneceği';

  @override
  String get geoNeverUpdated => 'hiç güncellenmedi — yerleşik sürümler';

  @override
  String geoUpdated(Object ago) {
    return '$ago güncellendi';
  }

  @override
  String geoSets(Object status) {
    return 'Geo setleri (.srs): $status';
  }

  @override
  String get justNow => 'az önce';

  @override
  String minutesAgo(Object n) {
    return '$n dk önce';
  }

  @override
  String hoursAgo(Object n) {
    return '$n sa önce';
  }

  @override
  String daysAgo(Object n) {
    return '$n gün önce';
  }

  @override
  String get restDirect => 'geri kalanı doğrudan';

  @override
  String get restViaVpn => 'geri kalanı VPN üzerinden';

  @override
  String get builtIn => 'Yerleşik';

  @override
  String get custom => 'Özel';

  @override
  String get allDirect => 'her şey doğrudan';

  @override
  String get allViaVpn => 'her şey VPN üzerinden';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kural',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'VPN üzerinden';

  @override
  String get groupDirect => 'Doğrudan';

  @override
  String get groupBlock => 'Engelle';

  @override
  String get groupExceptions => 'İstisnalar (engellemeden öncelikli)';

  @override
  String get exceptionsGo => 'İstisnalar gider';

  @override
  String get viaVpn => 'VPN üzerinden';

  @override
  String get direct => 'doğrudan';

  @override
  String get duplicate => 'Çoğalt';

  @override
  String get use => 'Kullan';

  @override
  String get builtInProfileReadOnly =>
      'Yerleşik profiller değiştirilemez — kurallarını özelleştirmek için çoğaltın.';

  @override
  String get everythingElse => 'Kurallara uymayan her şey';

  @override
  String get empty => 'Boş';

  @override
  String get chooseCategory => 'Kategori seçin';

  @override
  String get domainOrCidr => 'Alan adı veya IP/CIDR';

  @override
  String get add => 'Ekle';

  @override
  String get domainOrCidrHint => 'example.com veya 1.2.3.0/24';

  @override
  String get geoCategory => 'Geo kategorisi';

  @override
  String get domainOrIp => 'Alan adı veya IP';

  @override
  String get addRule => 'Kural ekle';

  @override
  String get kindProxy => 'Proxy';

  @override
  String get kindBlock => 'Engel';

  @override
  String get otherApps => 'Diğer';

  @override
  String get noActiveConnections => 'Etkin bağlantı yok';

  @override
  String get vpnDisconnected => 'VPN kapalı';

  @override
  String get nothingFound => 'Hiçbir şey bulunamadı';

  @override
  String get connections => 'Bağlantılar';

  @override
  String get byApp => 'Uygulamaya göre';

  @override
  String get asList => 'Liste';

  @override
  String get connectionsSearchHint => 'Alan adı, IP veya uygulama';

  @override
  String get all => 'Tümü';

  @override
  String get close => 'Kapat';

  @override
  String get kindProxyShort => 'proxy';

  @override
  String get kindBlockShort => 'engel';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bağlantı',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'Uygulama';

  @override
  String get fieldProcessPath => 'İşlem yolu';

  @override
  String get fieldNetwork => 'Ağ';

  @override
  String get fieldSource => 'Kaynak';

  @override
  String get fieldDestination => 'Hedef';

  @override
  String get fieldDomain => 'Alan adı';

  @override
  String get fieldChain => 'Zincir';

  @override
  String get fieldRule => 'Kural';

  @override
  String get fieldDuration => 'Süre';

  @override
  String get fieldStart => 'Başlangıç';

  @override
  String get connectionClosed => 'bağlantı kapandı';

  @override
  String get sent => 'Gönderilen';

  @override
  String get received => 'Alınan';

  @override
  String get advanced => 'Gelişmiş';

  @override
  String get tunAdvancedDescription =>
      'Arayüz adresi, MTU, ağ yığını ve rotalar. Çoğu ağ için ayarlıdır — yalnızca TUN sorun çıkarırsa değiştirin';

  @override
  String get reset => 'Sıfırla';

  @override
  String get tunAdvancedWarning =>
      'Bu değerleri yalnızca sonuçlarını biliyorsanız değiştirin. MTU 9000 SSH ve MySQL\'i koparır, 172.16.0.0/12 aralığından bir adres docker ağlarını bozar, katı rota yerel ağ trafiğini yakalar.';

  @override
  String get interfaceAddress => 'Arayüz adresi';

  @override
  String rangeFromTo(Object min, Object max) {
    return '$min ile $max arası';
  }

  @override
  String get networkStack => 'Ağ yığını';

  @override
  String get networkStackDescription =>
      'gvisor — uyumluluk, system — hız, mixed — denge';

  @override
  String get strictRoute => 'Katı rota';

  @override
  String get strictRouteDescription => 'Trafiğin tüneli atlamasını önler';

  @override
  String get autoRoute => 'Varsayılan rota';

  @override
  String get autoRouteDescription => 'Sistemin tüm trafiği tünelden geçer';

  @override
  String daysShort(Object n) {
    return '${n}g';
  }

  @override
  String get connected => 'Bağlandı';

  @override
  String get connecting => 'Bağlanıyor…';

  @override
  String get notConnected => 'Bağlı değil';

  @override
  String get chooseServerBelow => 'Aşağıdan bir sunucu seçin';

  @override
  String get time => 'Süre';

  @override
  String get noInternet => 'internet yok';

  @override
  String get routingRules => 'Yönlendirme kuralları';

  @override
  String get disconnect => 'Bağlantıyı kes';

  @override
  String get connect => 'Bağlan';

  @override
  String get checkingServer => 'Sunucu kontrol ediliyor';

  @override
  String get clickToConnect => 'Bağlanmak için tıklayın';

  @override
  String get quitVerge => 'Verge\'den çık';

  @override
  String get noSubscriptionsTray => 'Abonelik yok — ana pencereden ekleyin';

  @override
  String get openVerge => 'Verge\'ü aç';

  @override
  String get noResponse => 'yanıt yok';

  @override
  String get skipCertVerify => 'Sertifika doğrulamasını atla';

  @override
  String get skipCertVerifyDescription =>
      'Güvenliği düşürür: bağlantı artık sunucu sahteciliğine karşı korumaz. Yalnızca hata ayıklama için açın';

  @override
  String get tlsFragment => 'TLS parçalama';

  @override
  String get tlsFragmentDescription =>
      'ClientHello\'yu basitçe eşleştiren güvenlik duvarlarını aşmak için TLS el sıkışmasını parçalara böler. Yalnızca sing-box ile çalışır';

  @override
  String get tlsFragmentUnsupported =>
      'Geçerli motor parçalamayı desteklemiyor';

  @override
  String get tlsRecordFragment => 'TLS kayıtlarına göre parçalama';

  @override
  String get tlsRecordFragmentDescription =>
      'Performans açısından daha ucuz — önce bunu deneyin';

  @override
  String get fallbackDelay => 'Yedek seçenek gecikmesi';

  @override
  String get fallbackDelayDescription =>
      'Parçalamasız denemeden önce yanıt için ne kadar bekleneceği';

  @override
  String versionAvailable(Object version) {
    return '$version sürümü mevcut';
  }

  @override
  String get launchingInstaller =>
      'Yükleyici başlatılıyor — Verge kapanıp güncellenecek';

  @override
  String get downloadingUpdate => 'Güncelleme indiriliyor…';

  @override
  String get updateReady => 'Verge\'ün yeni sürümü yüklenmeye hazır';

  @override
  String downloadFailed(Object error) {
    return 'İndirme başarısız: $error';
  }

  @override
  String get retry => 'Yeniden dene';

  @override
  String get update => 'Güncelle';

  @override
  String get later => 'Daha sonra';

  @override
  String get whatsNew => 'Yenilikler';

  @override
  String get skipVersion => 'Bu sürümü atla';

  @override
  String get installing => 'Yükleniyor…';

  @override
  String get downloading => 'İndiriliyor';

  @override
  String get activeConnectionPing => 'Etkin bağlantı pingi';

  @override
  String get showPing => 'Pingi göster';

  @override
  String get showPingDescription =>
      'Ana ekranda, bağlantı sayacının yanında sunucu gecikmesi';

  @override
  String get pingIntervalSeconds => 'Yenileme aralığı, sn';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return '$min ile $max sn arası, varsayılan $def';
  }

  @override
  String get probeUrl => 'Kontrol adresi';

  @override
  String get probeUrlDescription =>
      'TUN modunda bu adres tünel dışında internet erişimini kontrol eder; Proxy modunda yerel proxy üzerinden gecikmeyi ölçer';

  @override
  String get autoSelectNode => 'Düğüm otomatik seçimi';

  @override
  String get pickBestNode => 'En iyi düğümü seç';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'Arka plan kontrol aralığı, saniye ($min…$max)';
  }

  @override
  String get profiles => 'Profiller';

  @override
  String get checkNow => 'Şimdi kontrol et';

  @override
  String lastCheck(Object time, Object result) {
    return 'Son kontrol: $time — $result';
  }

  @override
  String get nodeResponds => 'düğüm yanıt veriyor';

  @override
  String lastPick(Object result) {
    return 'Son seçim: $result';
  }

  @override
  String get emptyLink => 'Boş bağlantı';

  @override
  String get clipboardEmpty => 'Pano boş';

  @override
  String get addSubscriptionDescription =>
      'Abonelik URL\'si, paylaşım bağlantısı (vless://, ss://…) veya JSON yapılandırması';

  @override
  String get pasteFromClipboardHint =>
      'Bir bağlantı mı kopyaladınız? Doğrudan panodan ekleyin';

  @override
  String get paste => 'Yapıştır';

  @override
  String get or => 'veya';

  @override
  String get subscriptionUrlHint => 'https://… veya vless://…';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Açık';

  @override
  String get themeDark => 'Koyu';

  @override
  String get theme => 'Tema';

  @override
  String get startup => 'Başlangıç';

  @override
  String get autostart => 'Otomatik bağlan';

  @override
  String get autostartDescription => 'Açılışta son düğüme bağlan';

  @override
  String get localProxyPort => 'Yerel proxy portu';

  @override
  String get localProxyPortDescription => '127.0.0.1 üzerinde HTTP + SOCKS';

  @override
  String get home => 'Ana sayfa';

  @override
  String get settings => 'Ayarlar';

  @override
  String get logs => 'Günlükler';

  @override
  String get about => 'Hakkında';

  @override
  String get newBadge => 'yeni';

  @override
  String get copy => 'Kopyala';

  @override
  String get clear => 'Temizle';

  @override
  String get searchLogs => 'Günlüklerde ara';

  @override
  String get noLogsYet => 'Henüz günlük yok';

  @override
  String get nothingMatchesFilter => 'Filtreyle eşleşen bir şey yok';

  @override
  String get editNode => 'Düğümü düzenle';

  @override
  String get name => 'Ad';

  @override
  String schema(Object engine) {
    return 'Şema: $engine';
  }

  @override
  String get format => 'Biçimlendir';

  @override
  String get changesOverwrittenOnRefresh =>
      'Abonelik güncellendiğinde değişikliklerin üzerine yazılacak';

  @override
  String get dnsHijack => 'TUN\'da DNS yakalama';

  @override
  String get dnsHijackDescription =>
      'Port 53\'teki tüm trafiği DNS motoruna yönlendirir. Bu olmadan sorgular ISS\'nin DNS\'ine gider ve sansürlenir';

  @override
  String get dnsProxy => 'Proxy için DNS';

  @override
  String get dnsProxyDescription =>
      'VPN üzerinden giden sitelerin adreslerini çözümler';

  @override
  String get dnsDirect => 'Doğrudan bağlantılar için DNS';

  @override
  String get dnsDirectDescription => 'Doğrudan açılan siteler için';

  @override
  String get aboutTagline =>
      'sing-box ve Xray tabanlı, macOS ve Windows için proxy istemcisi.';

  @override
  String get appVersion => 'Uygulama sürümü';

  @override
  String get checking => 'Kontrol ediliyor…';

  @override
  String get checkForUpdates => 'Güncellemeleri kontrol et';

  @override
  String get upToDate => 'En son sürümü kullanıyorsunuz';

  @override
  String get general => 'Genel';

  @override
  String get network => 'Ağ';

  @override
  String get changesApplyAfterReconnect =>
      'Değişiklikler yeniden bağlandıktan sonra uygulanacak';

  @override
  String get reconnect => 'Yeniden bağlan';

  @override
  String get ipv6Description =>
      'Varsayılan olarak kapalı: birçok sunucu yalnızca IPv4 kullanır ve IPv6 bağlantıları geri dönmek yerine takılır';

  @override
  String get presetAllProxy => 'Her şey proxy üzerinden';

  @override
  String get presetBypassRu => 'Rusya\'yı atla';

  @override
  String get presetBlockAds => 'Yalnızca reklam engelleme';

  @override
  String get geoRuSites => 'Rusya (siteler)';

  @override
  String get geoRuIp => 'Rusya (IP)';

  @override
  String get geoAds => 'Reklamlar ve izleyiciler';

  @override
  String get geoPrivate => 'Özel alan adları';

  @override
  String get geoAdult => 'Yetişkin içerik';

  @override
  String get geoCnIp => 'Çin (IP)';

  @override
  String get geoCnSites => 'Çin (siteler)';

  @override
  String get singboxCrashed => 'sing-box çöktü';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN bağlantısı kesildi: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count set güncellenmedi (bağlantınızı kontrol edin)';
  }

  @override
  String refreshFailed(Object names) {
    return 'Güncellenemedi: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (kopya)';
  }

  @override
  String healthCheckOk(Object node) {
    return '$node kontrolü — tamam';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node yanıt vermedi ($failures/$limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return '$node düğümü yanıt vermiyor — başka bir düğüm seçiliyor';
  }

  @override
  String get helperNotInstalled =>
      'Sistem hizmeti yüklü değil. Uygulamayı yükleyiciyle (.pkg) yeniden yükleyin.';

  @override
  String updateCheckFailed(Object error) {
    return 'Güncellemeler kontrol edilemedi: $error';
  }

  @override
  String get updateCheckLatest => 'Güncelleme kontrolü: en son sürüm yüklü';

  @override
  String updateCheckAvailable(Object version) {
    return 'Güncelleme kontrolü: $version mevcut';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'Güncelleme indirilemedi: $error';
  }

  @override
  String get noLiveNodes => 'çalışan düğüm bulunamadı, seçim değişmedi';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms ms (HTTP hiçbir düğümde başarılı olmadı)';
  }

  @override
  String get xrayFailedFallback => 'Xray başlatılamadı, sing-box\'a geçiliyor';

  @override
  String get xrayFailedManual =>
      'Xray başlatılamadı, motor elle seçildi — geri dönüş yok';

  @override
  String get xrayFailed => 'Xray başlatılamadı';

  @override
  String get vpnNotConnectedXray => 'VPN bağlanmadı: Xray başlatılamadı';

  @override
  String get xrayConfigUnsupported =>
      'bu düğüm için Xray yapılandırması oluşturulamıyor';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray başlamadı: $error';
  }

  @override
  String get xrayUnavailable => 'Xray bu platformda kullanılamıyor';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray başladı ama socks portu $port yanıt vermiyor';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'Xray başlatılamadı, sing-box ile çalışılıyor';

  @override
  String get engineChosenManually => 'Motor elle seçildi';

  @override
  String get engineChosenAutomatically => 'Motor otomatik seçildi';

  @override
  String invalidJson(Object message) {
    return 'Geçersiz JSON: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'Geçersiz JSON: $message ($offset. karakter)';
  }

  @override
  String get tooManyRedirects => 'çok fazla yönlendirme';

  @override
  String get subscriptionNoValidNodes => 'abonelikte geçerli düğüm yok';

  @override
  String get subscriptionStubNodes => 'abonelik yer tutucu düğümler döndürdü';

  @override
  String get invalidJsonConfig => 'geçersiz JSON yapılandırması';

  @override
  String get expectedOutboundObject => 'Bir outbound JSON nesnesi bekleniyor';

  @override
  String get port => 'port';

  @override
  String testProcessFailed(Object error) {
    return 'test işlemi başlatılamadı: $error';
  }

  @override
  String get language => 'Dil';

  @override
  String get interfaceLanguage => 'Arayüz dili';

  @override
  String get languageSystem => 'Sistem varsayılanı';

  @override
  String get hotkeys => 'Kısayol tuşları';

  @override
  String get toggleHotkey => 'Bağlan / bağlantıyı kes';

  @override
  String get toggleHotkeyDescription =>
      'Genel kısayol — Verge penceresi gizliyken bile çalışır';

  @override
  String get hotkeyTaken =>
      'Bu kısayol başka bir uygulama tarafından kullanılıyor — başka birini seçin';

  @override
  String get hotkeyNotSet => 'Ayarlanmadı';

  @override
  String get hotkeyPress => 'Bir kısayola basın…';

  @override
  String get hotkeyNeedsModifier => 'Ctrl, Alt veya ⌘/Win ekleyin';

  @override
  String get hotkeyClear => 'Kısayolu kaldır';
}
