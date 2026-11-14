// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get renameProfile => 'تغییر نام پروفایل';

  @override
  String get cancel => 'لغو';

  @override
  String get save => 'ذخیره';

  @override
  String get subscriptionsUpdated => 'اشتراک‌ها به‌روز شدند';

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
    return '$used مصرف‌شده · بدون محدودیت';
  }

  @override
  String validUntil(Object date) {
    return 'تا $date';
  }

  @override
  String get timeout => 'پایان مهلت';

  @override
  String get error => 'خطا';

  @override
  String get pingAll => 'پینگ همه';

  @override
  String get refreshSubscriptions => 'به‌روزرسانی اشتراک‌ها';

  @override
  String get addSubscription => 'افزودن اشتراک';

  @override
  String get servers => 'سرورها';

  @override
  String get pickingNode => 'در حال انتخاب نود…';

  @override
  String get noSubscriptions => 'هنوز اشتراکی ندارید. اولین را اضافه کنید.';

  @override
  String get subscriptionHasNoServers => 'این اشتراک هیچ سروری ندارد';

  @override
  String get active => 'فعال';

  @override
  String get columnServer => 'سرور';

  @override
  String get columnProtocol => 'پروتکل';

  @override
  String get columnEngine => 'هسته';

  @override
  String get columnLatency => 'تأخیر';

  @override
  String ms(Object ms) {
    return '$ms میلی‌ثانیه';
  }

  @override
  String engineAuto(Object engine) {
    return 'خودکار ($engine)';
  }

  @override
  String get edit => 'ویرایش';

  @override
  String get ping => 'پینگ';

  @override
  String get refresh => 'به‌روزرسانی';

  @override
  String get subscriptionLinkCopied => 'لینک اشتراک کپی شد';

  @override
  String get subscription => 'اشتراک';

  @override
  String get accountPage => 'حساب کاربری';

  @override
  String get support => 'پشتیبانی';

  @override
  String get autoRefresh => 'به‌روزرسانی خودکار';

  @override
  String get rename => 'تغییر نام';

  @override
  String get delete => 'حذف';

  @override
  String get autoSelectOn => 'انتخاب خودکار: روشن';

  @override
  String get autoSelect => 'انتخاب خودکار';

  @override
  String refreshOwn(Object hours) {
    return 'سفارشی: $hours ساعت';
  }

  @override
  String refreshBySubscription(Object hours) {
    return 'طبق اشتراک: $hours ساعت';
  }

  @override
  String get off => 'خاموش';

  @override
  String get autoRefreshInterval => 'فاصلهٔ به‌روزرسانی خودکار';

  @override
  String get hours => 'ساعت';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return 'خالی — استفاده از فاصلهٔ اشتراک ($hours ساعت)';
  }

  @override
  String get emptyNoAutoRefresh => 'خالی — بدون به‌روزرسانی خودکار';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count سرور',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used از $total';
  }

  @override
  String remaining(Object amount) {
    return '$amount باقی‌مانده';
  }

  @override
  String get limitExhausted => 'سقف مصرف تمام شد';

  @override
  String get newProfile => 'پروفایل جدید';

  @override
  String get routing => 'مسیریابی';

  @override
  String get updateGeo => 'به‌روزرسانی Geo';

  @override
  String get profile => 'پروفایل';

  @override
  String get routingSubtitle =>
      'چه چیزی از VPN عبور کند، چه چیزی مستقیم برود و چه چیزی مسدود شود';

  @override
  String get geoNeverUpdated => 'هرگز به‌روز نشده — نسخه‌های داخلی';

  @override
  String geoUpdated(Object ago) {
    return 'به‌روز شده $ago';
  }

  @override
  String geoSets(Object status) {
    return 'مجموعه‌های Geo (.srs): $status';
  }

  @override
  String get justNow => 'همین الان';

  @override
  String minutesAgo(Object n) {
    return '$n دقیقه پیش';
  }

  @override
  String hoursAgo(Object n) {
    return '$n ساعت پیش';
  }

  @override
  String daysAgo(Object n) {
    return '$n روز پیش';
  }

  @override
  String get restDirect => 'بقیه مستقیم';

  @override
  String get restViaVpn => 'بقیه از طریق VPN';

  @override
  String get builtIn => 'داخلی';

  @override
  String get custom => 'سفارشی';

  @override
  String get allDirect => 'همه مستقیم';

  @override
  String get allViaVpn => 'همه از طریق VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count قانون',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => 'از طریق VPN';

  @override
  String get groupDirect => 'مستقیم';

  @override
  String get groupBlock => 'مسدود';

  @override
  String get groupExceptions => 'استثناها (مقدم بر مسدودسازی)';

  @override
  String get exceptionsGo => 'استثناها می‌روند';

  @override
  String get viaVpn => 'از طریق VPN';

  @override
  String get direct => 'مستقیم';

  @override
  String get duplicate => 'تکثیر';

  @override
  String get use => 'استفاده';

  @override
  String get builtInProfileReadOnly =>
      'پروفایل‌های داخلی قابل تغییر نیستند — برای تنظیم قوانین، یک نسخه از آن بسازید.';

  @override
  String get everythingElse => 'هر چیزی که با قوانین مطابقت ندارد';

  @override
  String get empty => 'خالی';

  @override
  String get chooseCategory => 'انتخاب دسته';

  @override
  String get domainOrCidr => 'دامنه یا IP/CIDR';

  @override
  String get add => 'افزودن';

  @override
  String get domainOrCidrHint => 'example.com یا 1.2.3.0/24';

  @override
  String get geoCategory => 'دستهٔ Geo';

  @override
  String get domainOrIp => 'دامنه یا IP';

  @override
  String get addRule => 'افزودن قانون';

  @override
  String get kindProxy => 'پروکسی';

  @override
  String get kindBlock => 'مسدود';

  @override
  String get otherApps => 'سایر';

  @override
  String get noActiveConnections => 'اتصال فعالی وجود ندارد';

  @override
  String get vpnDisconnected => 'VPN خاموش است';

  @override
  String get nothingFound => 'چیزی پیدا نشد';

  @override
  String get connections => 'اتصال‌ها';

  @override
  String get byApp => 'بر اساس برنامه';

  @override
  String get asList => 'فهرست';

  @override
  String get connectionsSearchHint => 'دامنه، IP یا برنامه';

  @override
  String get all => 'همه';

  @override
  String get close => 'بستن';

  @override
  String get kindProxyShort => 'پروکسی';

  @override
  String get kindBlockShort => 'مسدود';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اتصال',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => 'برنامه';

  @override
  String get fieldProcessPath => 'مسیر پردازه';

  @override
  String get fieldNetwork => 'شبکه';

  @override
  String get fieldSource => 'مبدأ';

  @override
  String get fieldDestination => 'مقصد';

  @override
  String get fieldDomain => 'دامنه';

  @override
  String get fieldChain => 'زنجیره';

  @override
  String get fieldRule => 'قانون';

  @override
  String get fieldDuration => 'مدت';

  @override
  String get fieldStart => 'شروع';

  @override
  String get connectionClosed => 'اتصال بسته شد';

  @override
  String get sent => 'ارسال‌شده';

  @override
  String get received => 'دریافت‌شده';

  @override
  String get advanced => 'پیشرفته';

  @override
  String get tunAdvancedDescription =>
      'آدرس رابط، MTU، پشتهٔ شبکه و مسیرها. برای بیشتر شبکه‌ها تنظیم شده‌اند — فقط اگر TUN مشکل دارد تغییر دهید';

  @override
  String get reset => 'بازنشانی';

  @override
  String get tunAdvancedWarning =>
      'این مقادیر را فقط در صورتی تغییر دهید که پیامدهایش را می‌دانید. MTU 9000 اتصال SSH و MySQL را قطع می‌کند، آدرسی از 172.16.0.0/12 شبکه‌های docker را خراب می‌کند و مسیر سخت‌گیرانه ترافیک شبکهٔ محلی را رهگیری می‌کند.';

  @override
  String get interfaceAddress => 'آدرس رابط';

  @override
  String rangeFromTo(Object min, Object max) {
    return 'از $min تا $max';
  }

  @override
  String get networkStack => 'پشتهٔ شبکه';

  @override
  String get networkStackDescription =>
      'gvisor — سازگاری، system — سرعت، mixed — تعادل';

  @override
  String get strictRoute => 'مسیر سخت‌گیرانه';

  @override
  String get strictRouteDescription => 'نمی‌گذارد ترافیک از کنار تونل عبور کند';

  @override
  String get autoRoute => 'مسیر پیش‌فرض';

  @override
  String get autoRouteDescription => 'همهٔ ترافیک سیستم وارد تونل می‌شود';

  @override
  String daysShort(Object n) {
    return '$n روز';
  }

  @override
  String get connected => 'متصل';

  @override
  String get connecting => 'در حال اتصال…';

  @override
  String get notConnected => 'متصل نیست';

  @override
  String get chooseServerBelow => 'یک سرور را از پایین انتخاب کنید';

  @override
  String get time => 'زمان';

  @override
  String get noInternet => 'بدون اینترنت';

  @override
  String get routingRules => 'قوانین مسیریابی';

  @override
  String get disconnect => 'قطع اتصال';

  @override
  String get connect => 'اتصال';

  @override
  String get checkingServer => 'در حال بررسی سرور';

  @override
  String get clickToConnect => 'برای اتصال کلیک کنید';

  @override
  String get quitVerge => 'خروج از Verge';

  @override
  String get noSubscriptionsTray =>
      'اشتراکی وجود ندارد — آن‌ها را در پنجرهٔ اصلی اضافه کنید';

  @override
  String get openVerge => 'باز کردن Verge';

  @override
  String get noResponse => 'بدون پاسخ';

  @override
  String get skipCertVerify => 'رد شدن از بررسی گواهی';

  @override
  String get skipCertVerifyDescription =>
      'امنیت را کاهش می‌دهد: اتصال دیگر در برابر جعل سرور محافظت نمی‌شود. فقط برای اشکال‌زدایی فعال کنید';

  @override
  String get tlsFragment => 'قطعه‌قطعه کردن TLS';

  @override
  String get tlsFragmentDescription =>
      'دست‌دهی TLS را به چند تکه تقسیم می‌کند تا از فایروال‌هایی که ClientHello را ساده تطبیق می‌دهند عبور کند. فقط با sing-box کار می‌کند';

  @override
  String get tlsFragmentUnsupported =>
      'هستهٔ فعلی از قطعه‌قطعه کردن پشتیبانی نمی‌کند';

  @override
  String get tlsRecordFragment => 'قطعه‌قطعه کردن بر اساس رکوردهای TLS';

  @override
  String get tlsRecordFragmentDescription =>
      'از نظر کارایی کم‌هزینه‌تر است — ارزش دارد اول امتحان شود';

  @override
  String get fallbackDelay => 'تأخیر حالت جایگزین';

  @override
  String get fallbackDelayDescription =>
      'مدت انتظار برای پاسخ پیش از تلاش بدون قطعه‌قطعه کردن';

  @override
  String versionAvailable(Object version) {
    return 'نسخهٔ $version در دسترس است';
  }

  @override
  String get launchingInstaller =>
      'در حال اجرای نصب‌کننده — Verge بسته و به‌روز می‌شود';

  @override
  String get downloadingUpdate => 'در حال دانلود به‌روزرسانی…';

  @override
  String get updateReady => 'نسخهٔ جدید Verge آمادهٔ نصب است';

  @override
  String downloadFailed(Object error) {
    return 'دانلود ناموفق بود: $error';
  }

  @override
  String get retry => 'تلاش دوباره';

  @override
  String get update => 'به‌روزرسانی';

  @override
  String get later => 'بعداً';

  @override
  String get whatsNew => 'تازه‌ها';

  @override
  String get skipVersion => 'رد کردن این نسخه';

  @override
  String get installing => 'در حال نصب…';

  @override
  String get downloading => 'در حال دانلود';

  @override
  String get activeConnectionPing => 'پینگ اتصال فعال';

  @override
  String get showPing => 'نمایش پینگ';

  @override
  String get showPingDescription =>
      'تأخیر تا سرور در صفحهٔ اصلی، کنار زمان‌سنج اتصال';

  @override
  String get pingIntervalSeconds => 'فاصلهٔ به‌روزرسانی، ثانیه';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return 'از $min تا $max ثانیه، پیش‌فرض $def';
  }

  @override
  String get probeUrl => 'آدرس بررسی';

  @override
  String get probeUrlDescription =>
      'در حالت TUN این آدرس دسترسی به اینترنت خارج از تونل را بررسی می‌کند؛ در حالت Proxy تأخیر را از طریق پروکسی محلی می‌سنجد';

  @override
  String get autoSelectNode => 'انتخاب خودکار نود';

  @override
  String get pickBestNode => 'انتخاب بهترین نود';

  @override
  String healthCheckInterval(Object min, Object max) {
    return 'فاصلهٔ بررسی در پس‌زمینه، ثانیه ($min…$max)';
  }

  @override
  String get profiles => 'پروفایل‌ها';

  @override
  String get checkNow => 'بررسی اکنون';

  @override
  String lastCheck(Object time, Object result) {
    return 'آخرین بررسی: $time — $result';
  }

  @override
  String get nodeResponds => 'نود پاسخ می‌دهد';

  @override
  String lastPick(Object result) {
    return 'آخرین انتخاب: $result';
  }

  @override
  String get emptyLink => 'لینک خالی است';

  @override
  String get clipboardEmpty => 'کلیپ‌بورد خالی است';

  @override
  String get addSubscriptionDescription =>
      'آدرس اشتراک، لینک اشتراک‌گذاری (vless://، ss://…) یا پیکربندی JSON';

  @override
  String get pasteFromClipboardHint =>
      'لینکی کپی کرده‌اید؟ مستقیم از کلیپ‌بورد اضافه کنید';

  @override
  String get paste => 'چسباندن';

  @override
  String get or => 'یا';

  @override
  String get subscriptionUrlHint => 'https://… یا vless://…';

  @override
  String get themeSystem => 'مطابق سیستم';

  @override
  String get themeLight => 'روشن';

  @override
  String get themeDark => 'تیره';

  @override
  String get theme => 'پوسته';

  @override
  String get startup => 'راه‌اندازی';

  @override
  String get autostart => 'اتصال خودکار';

  @override
  String get autostartDescription => 'هنگام اجرا به آخرین نود وصل شو';

  @override
  String get localProxyPort => 'پورت پروکسی محلی';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS روی 127.0.0.1';

  @override
  String get home => 'خانه';

  @override
  String get settings => 'تنظیمات';

  @override
  String get logs => 'گزارش‌ها';

  @override
  String get about => 'درباره';

  @override
  String get newBadge => 'جدید';

  @override
  String get copy => 'کپی';

  @override
  String get clear => 'پاک کردن';

  @override
  String get searchLogs => 'جستجو در گزارش‌ها';

  @override
  String get noLogsYet => 'هنوز گزارشی نیست';

  @override
  String get nothingMatchesFilter => 'چیزی با فیلتر مطابقت ندارد';

  @override
  String get editNode => 'ویرایش نود';

  @override
  String get name => 'نام';

  @override
  String schema(Object engine) {
    return 'طرح: $engine';
  }

  @override
  String get format => 'قالب‌بندی';

  @override
  String get changesOverwrittenOnRefresh =>
      'تغییرات هنگام به‌روزرسانی اشتراک بازنویسی می‌شوند';

  @override
  String get dnsHijack => 'رهگیری DNS در TUN';

  @override
  String get dnsHijackDescription =>
      'همهٔ ترافیک پورت 53 را به موتور DNS هدایت می‌کند. بدون آن، درخواست‌ها به DNS اینترنت‌دهنده می‌روند و سانسور می‌شوند';

  @override
  String get dnsProxy => 'DNS برای پروکسی';

  @override
  String get dnsProxyDescription =>
      'نشانی سایت‌هایی را که از VPN عبور می‌کنند تعیین می‌کند';

  @override
  String get dnsDirect => 'DNS برای اتصال‌های مستقیم';

  @override
  String get dnsDirectDescription => 'برای سایت‌هایی که مستقیم باز می‌شوند';

  @override
  String get aboutTagline =>
      'کلاینت پروکسی برای macOS و Windows بر پایهٔ sing-box و Xray.';

  @override
  String get appVersion => 'نسخهٔ برنامه';

  @override
  String get checking => 'در حال بررسی…';

  @override
  String get checkForUpdates => 'بررسی به‌روزرسانی';

  @override
  String get upToDate => 'آخرین نسخه را دارید';

  @override
  String get general => 'عمومی';

  @override
  String get network => 'شبکه';

  @override
  String get changesApplyAfterReconnect =>
      'تغییرات پس از اتصال مجدد اعمال می‌شوند';

  @override
  String get reconnect => 'اتصال مجدد';

  @override
  String get ipv6Description =>
      'به‌طور پیش‌فرض خاموش: بسیاری از سرورها فقط IPv4 دارند و اتصال‌های IPv6 به‌جای بازگشت، معلق می‌مانند';

  @override
  String get presetAllProxy => 'همه از طریق پروکسی';

  @override
  String get presetBypassRu => 'دور زدن روسیه';

  @override
  String get presetBlockAds => 'فقط مسدودسازی تبلیغات';

  @override
  String get geoRuSites => 'روسیه (سایت‌ها)';

  @override
  String get geoRuIp => 'روسیه (IP)';

  @override
  String get geoAds => 'تبلیغات و ردیاب‌ها';

  @override
  String get geoPrivate => 'دامنه‌های خصوصی';

  @override
  String get geoAdult => 'محتوای بزرگسالان';

  @override
  String get geoCnIp => 'چین (IP)';

  @override
  String get geoCnSites => 'چین (سایت‌ها)';

  @override
  String get singboxCrashed => 'sing-box به‌طور غیرمنتظره بسته شد';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN قطع شد: $reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count مجموعه به‌روز نشد (اتصال را بررسی کنید)';
  }

  @override
  String refreshFailed(Object names) {
    return 'به‌روزرسانی ناموفق: $names';
  }

  @override
  String copyOf(Object name) {
    return '$name (کپی)';
  }

  @override
  String healthCheckOk(Object node) {
    return 'بررسی $node — موفق';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node پاسخ نداد ($failures از $limit)';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return 'نود $node پاسخ نمی‌دهد — در حال انتخاب نود دیگر';
  }

  @override
  String get helperNotInstalled =>
      'سرویس سیستمی نصب نشده است. برنامه را با نصب‌کننده (.pkg) دوباره نصب کنید.';

  @override
  String updateCheckFailed(Object error) {
    return 'بررسی به‌روزرسانی ناموفق بود: $error';
  }

  @override
  String get updateCheckLatest => 'بررسی به‌روزرسانی: آخرین نسخه نصب است';

  @override
  String updateCheckAvailable(Object version) {
    return 'بررسی به‌روزرسانی: $version در دسترس است';
  }

  @override
  String updateDownloadFailed(Object error) {
    return 'دانلود به‌روزرسانی ناموفق بود: $error';
  }

  @override
  String get noLiveNodes => 'نود فعالی پیدا نشد، انتخاب تغییر نکرد';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms میلی‌ثانیه (HTTP برای هیچ نودی موفق نبود)';
  }

  @override
  String get xrayFailedFallback => 'Xray اجرا نشد، بازگشت به sing-box';

  @override
  String get xrayFailedManual =>
      'Xray اجرا نشد، هسته دستی انتخاب شده — بازگشتی انجام نمی‌شود';

  @override
  String get xrayFailed => 'Xray اجرا نشد';

  @override
  String get vpnNotConnectedXray => 'VPN متصل نشد: Xray اجرا نشد';

  @override
  String get xrayConfigUnsupported =>
      'برای این نود نمی‌توان پیکربندی Xray ساخت';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray شروع نشد: $error';
  }

  @override
  String get xrayUnavailable => 'Xray روی این سیستم‌عامل در دسترس نیست';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray اجرا شد، اما پورت socks $port پاسخ نمی‌دهد';
  }

  @override
  String get xrayFailedRunningSingbox =>
      'Xray اجرا نشد، با sing-box کار می‌کنیم';

  @override
  String get engineChosenManually => 'هسته به‌صورت دستی انتخاب شده';

  @override
  String get engineChosenAutomatically => 'هسته به‌صورت خودکار انتخاب شده';

  @override
  String invalidJson(Object message) {
    return 'JSON نامعتبر: $message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'JSON نامعتبر: $message (نویسهٔ $offset)';
  }

  @override
  String get tooManyRedirects => 'تغییر مسیرهای بیش از حد';

  @override
  String get subscriptionNoValidNodes => 'اشتراک هیچ نود معتبری ندارد';

  @override
  String get subscriptionStubNodes => 'اشتراک نودهای ساختگی برگرداند';

  @override
  String get invalidJsonConfig => 'پیکربندی JSON نامعتبر';

  @override
  String get expectedOutboundObject => 'یک شیء JSON از نوع outbound لازم است';

  @override
  String get port => 'پورت';

  @override
  String testProcessFailed(Object error) {
    return 'پردازهٔ آزمایشی اجرا نشد: $error';
  }

  @override
  String get language => 'زبان';

  @override
  String get interfaceLanguage => 'زبان رابط کاربری';

  @override
  String get languageSystem => 'مطابق سیستم';

  @override
  String get hotkeys => 'کلیدهای میان‌بر';

  @override
  String get toggleHotkey => 'اتصال / قطع اتصال';

  @override
  String get toggleHotkeyDescription =>
      'میان‌بر سراسری — حتی وقتی پنجرهٔ Verge پنهان است کار می‌کند';

  @override
  String get hotkeyTaken =>
      'این میان‌بر توسط برنامهٔ دیگری استفاده می‌شود — میان‌بر دیگری انتخاب کنید';

  @override
  String get hotkeyNotSet => 'تنظیم نشده';

  @override
  String get hotkeyPress => 'کلیدهای میان‌بر را فشار دهید…';

  @override
  String get hotkeyNeedsModifier => 'Ctrl، Alt یا ⌘/Win را اضافه کنید';

  @override
  String get hotkeyClear => 'حذف میان‌بر';
}
