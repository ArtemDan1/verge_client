// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get renameProfile => 'إعادة تسمية الملف الشخصي';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get subscriptionsUpdated => 'تم تحديث الاشتراكات';

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
    return 'المستخدم $used · بلا حد';
  }

  @override
  String validUntil(Object date) {
    return 'حتى $date';
  }

  @override
  String get timeout => 'انتهت المهلة';

  @override
  String get error => 'خطأ';

  @override
  String get pingAll => 'قياس الكل';

  @override
  String get refreshSubscriptions => 'تحديث الاشتراكات';

  @override
  String get addSubscription => 'إضافة اشتراك';

  @override
  String get servers => 'الخوادم';

  @override
  String get pickingNode => 'جارٍ اختيار عقدة…';

  @override
  String get noSubscriptions => 'لا توجد اشتراكات بعد. أضف أول اشتراك.';

  @override
  String get subscriptionHasNoServers => 'لا يحتوي هذا الاشتراك على خوادم';

  @override
  String get active => 'نشط';

  @override
  String get columnServer => 'الخادم';

  @override
  String get columnProtocol => 'البروتوكول';

  @override
  String get columnEngine => 'المحرك';

  @override
  String get columnLatency => 'زمن الاستجابة';

  @override
  String ms(Object ms) {
    return '$ms مللي ثانية';
  }

  @override
  String engineAuto(Object engine) {
    return 'تلقائي ($engine)';
  }

  @override
  String get edit => 'تعديل';

  @override
  String get ping => 'قياس';

  @override
  String get refresh => 'تحديث';

  @override
  String get subscriptionLinkCopied => 'تم نسخ رابط الاشتراك';

  @override
  String get subscription => 'الاشتراك';

  @override
  String get accountPage => 'الحساب';

  @override
  String get support => 'الدعم';

  @override
  String get autoRefresh => 'التحديث التلقائي';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get delete => 'حذف';

  @override
  String get autoSelectOn => 'الاختيار التلقائي: مفعّل';

  @override
  String get autoSelect => 'الاختيار التلقائي';

  @override
  String refreshOwn(Object hours) {
    return 'مخصص: $hours ساعة';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'حسب الاشتراك: $hours ساعة';
  }

  @override
  String get off => 'متوقف';

  @override
  String get autoRefreshInterval => 'فاصل التحديث التلقائي';

  @override
  String get hours => 'ساعات';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'فارغ — استخدام فاصل الاشتراك ($hours ساعة)';
  }

  @override
  String get emptyNoAutoRefresh => 'فارغ — بدون تحديث تلقائي';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count خادم',
      few: '$count خوادم',
      two: 'خادمان',
      one: 'خادم واحد',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used من $total';
  }

  @override
  String remaining(Object amount) {
    return 'المتبقي $amount';
  }

  @override
  String get limitExhausted => 'تم استنفاد الحد';

  @override
  String get newProfile => 'ملف شخصي جديد';

  @override
  String get routing => 'التوجيه';

  @override
  String get updateGeo => 'تحديث Geo';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get routingSubtitle => 'ما يمر عبر VPN، وما يمر مباشرة، وما يُحظر';

  @override
  String get geoNeverUpdated => 'لم تُحدَّث قط — النسخ المضمّنة';

  @override
  String geoUpdated(Object ago) {
    return 'حُدّثت $ago';
  }

  @override
  String geoSets(Object status) {
    return 'مجموعات Geo (.srs): $status';
  }

  @override
  String get justNow => 'الآن';

  @override
  String minutesAgo(Object n) {
    return 'قبل $n دقيقة';
  }

  @override
  String hoursAgo(Object n) {
    return 'قبل $n ساعة';
  }

  @override
  String daysAgo(Object n) {
    return 'قبل $n يوم';
  }

  @override
  String get restDirect => 'الباقي مباشرة';

  @override
  String get restViaVpn => 'الباقي عبر VPN';

  @override
  String get builtIn => 'مضمّن';

  @override
  String get custom => 'مخصص';

  @override
  String get allDirect => 'الكل مباشرة';

  @override
  String get allViaVpn => 'الكل عبر VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قاعدة',
      few: '$count قواعد',
      two: 'قاعدتان',
      one: 'قاعدة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'عبر VPN';

  @override
  String get groupDirect => 'مباشرة';

  @override
  String get groupBlock => 'حظر';

  @override
  String get groupExceptions => 'الاستثناءات (أولوية على الحظر)';

  @override
  String get exceptionsGo => 'تمر الاستثناءات';

  @override
  String get viaVpn => 'عبر VPN';

  @override
  String get direct => 'مباشرة';

  @override
  String get duplicate => 'تكرار';

  @override
  String get use => 'استخدام';

  @override
  String get builtInProfileReadOnly =>
      'لا يمكن تعديل الملفات المضمّنة — كرّر الملف لتخصيص قواعده.';

  @override
  String get everythingElse => 'كل ما لا يطابق القواعد';

  @override
  String get empty => 'فارغ';

  @override
  String get chooseCategory => 'اختر فئة';

  @override
  String get domainOrCidr => 'نطاق أو IP/CIDR';

  @override
  String get add => 'إضافة';

  @override
  String get domainOrCidrHint => 'example.com أو 1.2.3.0/24';

  @override
  String get geoCategory => 'فئة Geo';

  @override
  String get domainOrIp => 'نطاق أو IP';

  @override
  String get addRule => 'إضافة قاعدة';

  @override
  String get kindProxy => 'وكيل';

  @override
  String get kindBlock => 'حظر';

  @override
  String get otherApps => 'أخرى';

  @override
  String get noActiveConnections => 'لا توجد اتصالات نشطة';

  @override
  String get vpnDisconnected => 'VPN متوقف';

  @override
  String get nothingFound => 'لم يُعثر على شيء';

  @override
  String get connections => 'الاتصالات';

  @override
  String get byApp => 'حسب التطبيق';

  @override
  String get asList => 'قائمة';

  @override
  String get connectionsSearchHint => 'نطاق أو IP أو تطبيق';

  @override
  String get all => 'الكل';

  @override
  String get close => 'إغلاق';

  @override
  String get kindProxyShort => 'وكيل';

  @override
  String get kindBlockShort => 'حظر';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اتصال',
      few: '$count اتصالات',
      two: 'اتصالان',
      one: 'اتصال واحد',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'التطبيق';

  @override
  String get fieldProcessPath => 'مسار العملية';

  @override
  String get fieldNetwork => 'الشبكة';

  @override
  String get fieldSource => 'المصدر';

  @override
  String get fieldDestination => 'الوجهة';

  @override
  String get fieldDomain => 'النطاق';

  @override
  String get fieldChain => 'السلسلة';

  @override
  String get fieldRule => 'القاعدة';

  @override
  String get fieldDuration => 'المدة';

  @override
  String get fieldStart => 'البدء';

  @override
  String get connectionClosed => 'تم إغلاق الاتصال';

  @override
  String get sent => 'المُرسل';

  @override
  String get received => 'المُستلم';

  @override
  String get advanced => 'متقدم';

  @override
  String get tunAdvancedDescription =>
      'عنوان الواجهة وMTU ومكدس الشبكة والمسارات. مضبوطة لمعظم الشبكات — غيّرها فقط إذا كان TUN يعمل بشكل سيئ';

  @override
  String get reset => 'إعادة تعيين';

  @override
  String get tunAdvancedWarning =>
      'غيّر هذه القيم فقط إذا كنت تدرك العواقب. MTU 9000 يقطع SSH وMySQL، وعنوان من 172.16.0.0/12 يعطّل شبكات docker، والمسار الصارم يعترض حركة الشبكة المحلية.';

  @override
  String get interfaceAddress => 'عنوان الواجهة';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'من $min إلى $max';
  }

  @override
  String get networkStack => 'مكدس الشبكة';

  @override
  String get networkStackDescription =>
      'gvisor — التوافق، system — السرعة، mixed — التوازن';

  @override
  String get strictRoute => 'مسار صارم';

  @override
  String get strictRouteDescription => 'يمنع الحركة من تجاوز النفق';

  @override
  String get autoRoute => 'المسار الافتراضي';

  @override
  String get autoRouteDescription => 'كل حركة النظام تمر عبر النفق';

  @override
  String daysShort(Object n) {
    return '$n ي';
  }

  @override
  String get connected => 'متصل';

  @override
  String get connecting => 'جارٍ الاتصال…';

  @override
  String get notConnected => 'غير متصل';

  @override
  String get chooseServerBelow => 'اختر خادمًا أدناه';

  @override
  String get time => 'الوقت';

  @override
  String get noInternet => 'لا يوجد إنترنت';

  @override
  String get routingRules => 'قواعد التوجيه';

  @override
  String get disconnect => 'قطع الاتصال';

  @override
  String get connect => 'اتصال';

  @override
  String get checkingServer => 'جارٍ فحص الخادم';

  @override
  String get clickToConnect => 'انقر للاتصال';

  @override
  String get quitVerge => 'إنهاء Verge';

  @override
  String get noSubscriptionsTray =>
      'لا توجد اشتراكات — أضفها من النافذة الرئيسية';

  @override
  String get openVerge => 'فتح Verge';

  @override
  String get noResponse => 'لا استجابة';

  @override
  String get skipCertVerify => 'تخطي التحقق من الشهادة';

  @override
  String get skipCertVerifyDescription =>
      'يقلل الأمان: لن يحمي الاتصال من انتحال الخادم. فعّله لأغراض التصحيح فقط';

  @override
  String get tlsFragment => 'تجزئة TLS';

  @override
  String get tlsFragmentDescription =>
      'يقسم مصافحة TLS إلى أجزاء لتجاوز جدران الحماية التي تطابق ClientHello بشكل بسيط. يعمل مع sing-box فقط';

  @override
  String get tlsFragmentUnsupported => 'المحرك الحالي لا يدعم التجزئة';

  @override
  String get tlsRecordFragment => 'التجزئة حسب سجلات TLS';

  @override
  String get tlsRecordFragmentDescription =>
      'أقل تكلفة على الأداء — يستحق التجربة أولًا';

  @override
  String get fallbackDelay => 'تأخير البديل';

  @override
  String get fallbackDelayDescription =>
      'مدة انتظار الاستجابة قبل المحاولة بدون تجزئة';

  @override
  String versionAvailable(Object version) {
    return 'الإصدار $version متاح';
  }

  @override
  String get launchingInstaller => 'جارٍ تشغيل المثبّت — سيُغلق Verge ويُحدَّث';

  @override
  String get downloadingUpdate => 'جارٍ تنزيل التحديث…';

  @override
  String get updateReady => 'إصدار جديد من Verge جاهز للتثبيت';

  @override
  String downloadFailed(Object error) {
    return 'فشل التنزيل: $error';
  }

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get update => 'تحديث';

  @override
  String get later => 'لاحقًا';

  @override
  String get whatsNew => 'ما الجديد';

  @override
  String get skipVersion => 'تخطي هذا الإصدار';

  @override
  String get installing => 'جارٍ التثبيت…';

  @override
  String get downloading => 'جارٍ التنزيل';

  @override
  String get activeConnectionPing => 'زمن استجابة الاتصال النشط';

  @override
  String get showPing => 'إظهار زمن الاستجابة';

  @override
  String get showPingDescription =>
      'زمن الاستجابة إلى الخادم في الشاشة الرئيسية بجانب مؤقت الاتصال';

  @override
  String get pingIntervalSeconds => 'فاصل التحديث، ثانية';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'من $min إلى $max ث، الافتراضي $def';
  }

  @override
  String get probeUrl => 'عنوان الفحص';

  @override
  String get probeUrlDescription =>
      'في وضع TUN يفحص هذا العنوان الوصول إلى الإنترنت خارج النفق؛ وفي وضع Proxy يقيس زمن الاستجابة عبر الوكيل المحلي';

  @override
  String get autoSelectNode => 'الاختيار التلقائي للعقدة';

  @override
  String get pickBestNode => 'اختيار أفضل عقدة';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'فاصل الفحص في الخلفية، بالثواني ($min…$max)';
  }

  @override
  String get profiles => 'الملفات الشخصية';

  @override
  String get checkNow => 'افحص الآن';

  @override
  String lastCheck(Object time, Object result) {
    return 'آخر فحص: $time — $result';
  }

  @override
  String get nodeResponds => 'العقدة تستجيب';

  @override
  String lastPick(Object result) {
    return 'آخر اختيار: $result';
  }

  @override
  String get emptyLink => 'الرابط فارغ';

  @override
  String get clipboardEmpty => 'الحافظة فارغة';

  @override
  String get addSubscriptionDescription =>
      'رابط الاشتراك، أو رابط مشاركة (vless://، ss://…) أو إعدادات JSON';

  @override
  String get pasteFromClipboardHint => 'نسخت رابطًا؟ أضفه مباشرة من الحافظة';

  @override
  String get paste => 'لصق';

  @override
  String get or => 'أو';

  @override
  String get subscriptionUrlHint => 'https://… أو vless://…';

  @override
  String get themeSystem => 'حسب النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get theme => 'السمة';

  @override
  String get startup => 'بدء التشغيل';

  @override
  String get autostart => 'الاتصال التلقائي';

  @override
  String get autostartDescription => 'الاتصال بآخر عقدة عند التشغيل';

  @override
  String get localProxyPort => 'منفذ الوكيل المحلي';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS على 127.0.0.1';

  @override
  String get home => 'الرئيسية';

  @override
  String get settings => 'الإعدادات';

  @override
  String get logs => 'السجلات';

  @override
  String get about => 'حول';

  @override
  String get newBadge => 'جديد';

  @override
  String get copy => 'نسخ';

  @override
  String get clear => 'مسح';

  @override
  String get searchLogs => 'البحث في السجلات';

  @override
  String get noLogsYet => 'لا توجد سجلات بعد';

  @override
  String get nothingMatchesFilter => 'لا شيء يطابق عامل التصفية';

  @override
  String get editNode => 'تعديل العقدة';

  @override
  String get name => 'الاسم';

  @override
  String schema(Object engine) {
    return 'المخطط: $engine';
  }

  @override
  String get format => 'تنسيق';

  @override
  String get changesOverwrittenOnRefresh =>
      'ستُستبدل التغييرات عند تحديث الاشتراك';

  @override
  String get dnsHijack => 'اعتراض DNS في TUN';

  @override
  String get dnsHijackDescription =>
      'يحوّل كل حركة المنفذ 53 إلى محرك DNS. بدونه تذهب الاستعلامات إلى DNS مزود الخدمة وتخضع للرقابة';

  @override
  String get dnsProxy => 'DNS للوكيل';

  @override
  String get dnsProxyDescription => 'يحلّ عناوين المواقع التي تمر عبر VPN';

  @override
  String get dnsDirect => 'DNS للاتصالات المباشرة';

  @override
  String get dnsDirectDescription => 'للمواقع التي تُفتح مباشرة';

  @override
  String get aboutTagline =>
      'عميل وكيل لنظامي macOS وWindows مبني على sing-box وXray.';

  @override
  String get appVersion => 'إصدار التطبيق';

  @override
  String get checking => 'جارٍ الفحص…';

  @override
  String get checkForUpdates => 'التحقق من التحديثات';

  @override
  String get upToDate => 'لديك أحدث إصدار';

  @override
  String get general => 'عام';

  @override
  String get network => 'الشبكة';

  @override
  String get changesApplyAfterReconnect =>
      'ستُطبَّق التغييرات بعد إعادة الاتصال';

  @override
  String get reconnect => 'إعادة الاتصال';

  @override
  String get ipv6Description =>
      'معطّل افتراضيًا: كثير من الخوادم تدعم IPv4 فقط، واتصالات IPv6 تتعلق بدل الرجوع';

  @override
  String get presetAllProxy => 'الكل عبر الوكيل';

  @override
  String get presetBypassRu => 'تجاوز روسيا';

  @override
  String get presetBlockAds => 'حظر الإعلانات فقط';

  @override
  String get geoRuSites => 'روسيا (مواقع)';

  @override
  String get geoRuIp => 'روسيا (IP)';

  @override
  String get geoAds => 'الإعلانات والمتتبعات';

  @override
  String get geoPrivate => 'النطاقات الخاصة';

  @override
  String get geoAdult => 'محتوى للبالغين';

  @override
  String get geoCnIp => 'الصين (IP)';

  @override
  String get geoCnSites => 'الصين (مواقع)';

  @override
  String get singboxCrashed => 'توقف sing-box بشكل غير متوقع';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'انقطع VPN: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return 'لم تُحدَّث $count مجموعة (تحقق من الاتصال)';
  }

  @override
  String refreshFailed(Object names) {
    return 'فشل التحديث: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (نسخة)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'فحص $node — سليم';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return 'لم تستجب $node ($failures من $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'العقدة $node لا تستجيب — جارٍ اختيار عقدة أخرى';
  }

  @override
  String get helperNotInstalled =>
      'خدمة النظام غير مثبتة. أعد تثبيت التطبيق باستخدام المثبّت (.pkg).';

  @override
  String updateCheckFailed(Object error) {
    return 'فشل التحقق من التحديثات: $error';
  }

  @override
  String get updateCheckLatest => 'التحقق من التحديثات: أحدث إصدار مثبت';

  @override
  String updateCheckAvailable(Object version) {
    return 'التحقق من التحديثات: $version متاح';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'فشل تنزيل التحديث: $error';
  }

  @override
  String get noLiveNodes => 'لم يُعثر على عقد عاملة، لم يتغير الاختيار';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms مللي ثانية (فشل HTTP في جميع العقد)';
  }

  @override
  String get xrayFailedFallback => 'فشل تشغيل Xray، الرجوع إلى sing-box';

  @override
  String get xrayFailedManual =>
      'فشل تشغيل Xray، والمحرك مختار يدويًا — لا رجوع';

  @override
  String get xrayFailed => 'فشل تشغيل Xray';

  @override
  String get vpnNotConnectedXray => 'VPN غير متصل: فشل تشغيل Xray';

  @override
  String get xrayConfigUnsupported => 'لا يمكن إنشاء إعدادات Xray لهذه العقدة';

  @override
  String xrayStartFailed(Object error) {
    return 'لم يبدأ Xray: $error';
  }

  @override
  String get xrayUnavailable => 'Xray غير متاح على هذا النظام';

  @override
  String xraySocksNotResponding(Object port) {
    return 'بدأ Xray، لكن منفذ socks $port لا يستجيب';
  }

  @override
  String get xrayFailedRunningSingbox => 'فشل تشغيل Xray، نعمل على sing-box';

  @override
  String get engineChosenManually => 'المحرك مختار يدويًا';

  @override
  String get engineChosenAutomatically => 'المحرك مختار تلقائيًا';

  @override
  String invalidJson(Object message) {
    return 'JSON غير صالح: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'JSON غير صالح: $message (الحرف $offset)';
  }

  @override
  String get tooManyRedirects => 'عدد كبير جدًا من عمليات إعادة التوجيه';

  @override
  String get subscriptionNoValidNodes => 'لا يحتوي الاشتراك على عقد صالحة';

  @override
  String get subscriptionStubNodes => 'أعاد الاشتراك عقدًا وهمية';

  @override
  String get invalidJsonConfig => 'إعدادات JSON غير صالحة';

  @override
  String get expectedOutboundObject => 'يُتوقع كائن JSON من نوع outbound';

  @override
  String get port => 'المنفذ';

  @override
  String testProcessFailed(Object error) {
    return 'فشل تشغيل عملية الاختبار: $error';
  }

  @override
  String get language => 'اللغة';

  @override
  String get interfaceLanguage => 'لغة الواجهة';

  @override
  String get languageSystem => 'حسب النظام';

  @override
  String get hotkeys => 'اختصارات لوحة المفاتيح';

  @override
  String get toggleHotkey => 'اتصال / قطع الاتصال';

  @override
  String get toggleHotkeyDescription =>
      'اختصار عام — يعمل حتى عندما تكون نافذة Verge مخفية';

  @override
  String get hotkeyTaken =>
      'هذا الاختصار مستخدم من تطبيق آخر — اختر اختصارًا آخر';

  @override
  String get hotkeyNotSet => 'غير معيّن';

  @override
  String get hotkeyPress => 'اضغط على الاختصار…';

  @override
  String get hotkeyNeedsModifier => 'أضف Ctrl أو Alt أو ⌘/Win';

  @override
  String get hotkeyClear => 'إزالة الاختصار';
}
