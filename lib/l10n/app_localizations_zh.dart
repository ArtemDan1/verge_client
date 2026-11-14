// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get renameProfile => '重命名配置';

  @override
  String get cancel => '取消';

  @override
  String get save => '保存';

  @override
  String get subscriptionsUpdated => '订阅已更新';

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
    return '已用 $used · 无限制';
  }

  @override
  String validUntil(Object date) {
    return '有效期至 $date';
  }

  @override
  String get timeout => '超时';

  @override
  String get error => '错误';

  @override
  String get pingAll => '全部测速';

  @override
  String get refreshSubscriptions => '更新订阅';

  @override
  String get addSubscription => '添加订阅';

  @override
  String get servers => '服务器';

  @override
  String get pickingNode => '正在选择节点…';

  @override
  String get noSubscriptions => '还没有订阅。请添加第一个。';

  @override
  String get subscriptionHasNoServers => '此订阅中没有服务器';

  @override
  String get active => '当前';

  @override
  String get columnServer => '服务器';

  @override
  String get columnProtocol => '协议';

  @override
  String get columnEngine => '内核';

  @override
  String get columnLatency => '延迟';

  @override
  String ms(Object ms) {
    return '$ms 毫秒';
  }

  @override
  String engineAuto(Object engine) {
    return '自动（$engine）';
  }

  @override
  String get edit => '编辑';

  @override
  String get ping => '测速';

  @override
  String get refresh => '更新';

  @override
  String get subscriptionLinkCopied => '订阅链接已复制';

  @override
  String get subscription => '订阅';

  @override
  String get accountPage => '个人中心';

  @override
  String get support => '支持';

  @override
  String get autoRefresh => '自动更新';

  @override
  String get rename => '重命名';

  @override
  String get delete => '删除';

  @override
  String get autoSelectOn => '自动选择：开';

  @override
  String get autoSelect => '自动选择';

  @override
  String refreshOwn(Object hours) {
    return '自定义：$hours 小时';
  }

  @override
  String refreshBySubscription(Object hours) {
    return '按订阅：$hours 小时';
  }

  @override
  String get off => '关闭';

  @override
  String get autoRefreshInterval => '自动更新间隔';

  @override
  String get hours => '小时';

  @override
  String emptyUseSubscriptionInterval(Object hours) {
    return '留空 — 使用订阅提供的间隔（$hours 小时）';
  }

  @override
  String get emptyNoAutoRefresh => '留空 — 不自动更新';

  @override
  String serverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个服务器',
    );
    return '$_temp0';
  }

  @override
  String usedOfTotal(Object used, Object total) {
    return '$used / $total';
  }

  @override
  String remaining(Object amount) {
    return '剩余 $amount';
  }

  @override
  String get limitExhausted => '流量已用尽';

  @override
  String get newProfile => '新配置';

  @override
  String get routing => '路由';

  @override
  String get updateGeo => '更新地理数据';

  @override
  String get profile => '配置';

  @override
  String get routingSubtitle => '哪些走 VPN，哪些直连，哪些被屏蔽';

  @override
  String get geoNeverUpdated => '从未更新 — 内置版本';

  @override
  String geoUpdated(Object ago) {
    return '$ago更新';
  }

  @override
  String geoSets(Object status) {
    return '地理规则集（.srs）：$status';
  }

  @override
  String get justNow => '刚刚';

  @override
  String minutesAgo(Object n) {
    return '$n 分钟前';
  }

  @override
  String hoursAgo(Object n) {
    return '$n 小时前';
  }

  @override
  String daysAgo(Object n) {
    return '$n 天前';
  }

  @override
  String get restDirect => '其余直连';

  @override
  String get restViaVpn => '其余走 VPN';

  @override
  String get builtIn => '内置';

  @override
  String get custom => '自定义';

  @override
  String get allDirect => '全部直连';

  @override
  String get allViaVpn => '全部走 VPN';

  @override
  String ruleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条规则',
    );
    return '$_temp0';
  }

  @override
  String get groupViaVpn => '走 VPN';

  @override
  String get groupDirect => '直连';

  @override
  String get groupBlock => '屏蔽';

  @override
  String get groupExceptions => '例外（优先于屏蔽）';

  @override
  String get exceptionsGo => '例外流量';

  @override
  String get viaVpn => '走 VPN';

  @override
  String get direct => '直连';

  @override
  String get duplicate => '复制';

  @override
  String get use => '使用';

  @override
  String get builtInProfileReadOnly => '内置配置无法修改 — 复制一份即可自定义规则。';

  @override
  String get everythingElse => '未匹配任何规则的流量';

  @override
  String get empty => '空';

  @override
  String get chooseCategory => '选择类别';

  @override
  String get domainOrCidr => '域名或 IP/CIDR';

  @override
  String get add => '添加';

  @override
  String get domainOrCidrHint => 'example.com 或 1.2.3.0/24';

  @override
  String get geoCategory => '地理类别';

  @override
  String get domainOrIp => '域名或 IP';

  @override
  String get addRule => '添加规则';

  @override
  String get kindProxy => '代理';

  @override
  String get kindBlock => '屏蔽';

  @override
  String get otherApps => '其他';

  @override
  String get noActiveConnections => '没有活动连接';

  @override
  String get vpnDisconnected => 'VPN 已关闭';

  @override
  String get nothingFound => '未找到';

  @override
  String get connections => '连接';

  @override
  String get byApp => '按应用';

  @override
  String get asList => '列表';

  @override
  String get connectionsSearchHint => '域名、IP 或应用';

  @override
  String get all => '全部';

  @override
  String get close => '关闭';

  @override
  String get kindProxyShort => '代理';

  @override
  String get kindBlockShort => '屏蔽';

  @override
  String connectionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个连接',
    );
    return '$_temp0';
  }

  @override
  String get fieldApp => '应用';

  @override
  String get fieldProcessPath => '进程路径';

  @override
  String get fieldNetwork => '网络';

  @override
  String get fieldSource => '来源';

  @override
  String get fieldDestination => '目标';

  @override
  String get fieldDomain => '域名';

  @override
  String get fieldChain => '链路';

  @override
  String get fieldRule => '规则';

  @override
  String get fieldDuration => '时长';

  @override
  String get fieldStart => '开始时间';

  @override
  String get connectionClosed => '连接已关闭';

  @override
  String get sent => '上传';

  @override
  String get received => '下载';

  @override
  String get advanced => '高级';

  @override
  String get tunAdvancedDescription =>
      '接口地址、MTU、网络栈和路由。默认值适用于大多数网络 — 仅在 TUN 出现问题时修改';

  @override
  String get reset => '重置';

  @override
  String get tunAdvancedWarning =>
      '请仅在了解后果时修改这些值。MTU 9000 会中断 SSH 和 MySQL，172.16.0.0/12 范围的地址会破坏 docker 网络，严格路由会拦截局域网流量。';

  @override
  String get interfaceAddress => '接口地址';

  @override
  String rangeFromTo(Object min, Object max) {
    return '$min 到 $max';
  }

  @override
  String get networkStack => '网络栈';

  @override
  String get networkStackDescription => 'gvisor — 兼容性，system — 速度，mixed — 平衡';

  @override
  String get strictRoute => '严格路由';

  @override
  String get strictRouteDescription => '防止流量绕过隧道';

  @override
  String get autoRoute => '默认路由';

  @override
  String get autoRouteDescription => '系统所有流量进入隧道';

  @override
  String daysShort(Object n) {
    return '$n天';
  }

  @override
  String get connected => '已连接';

  @override
  String get connecting => '正在连接…';

  @override
  String get notConnected => '未连接';

  @override
  String get chooseServerBelow => '请在下方选择服务器';

  @override
  String get time => '时长';

  @override
  String get noInternet => '无网络';

  @override
  String get routingRules => '路由规则';

  @override
  String get disconnect => '断开';

  @override
  String get connect => '连接';

  @override
  String get checkingServer => '正在检查服务器';

  @override
  String get clickToConnect => '点击连接';

  @override
  String get quitVerge => '退出 Verge';

  @override
  String get noSubscriptionsTray => '没有订阅 — 请在主窗口中添加';

  @override
  String get openVerge => '打开 Verge';

  @override
  String get noResponse => '无响应';

  @override
  String get skipCertVerify => '跳过证书验证';

  @override
  String get skipCertVerifyDescription => '降低安全性：连接将无法防止服务器伪造。仅用于调试';

  @override
  String get tlsFragment => 'TLS 分片';

  @override
  String get tlsFragmentDescription =>
      '将 TLS 握手拆分成多段，以绕过对 ClientHello 进行简单匹配的防火墙。仅适用于 sing-box';

  @override
  String get tlsFragmentUnsupported => '当前内核不支持分片';

  @override
  String get tlsRecordFragment => '按 TLS 记录分片';

  @override
  String get tlsRecordFragmentDescription => '性能开销更小 — 建议优先尝试';

  @override
  String get fallbackDelay => '回退延迟';

  @override
  String get fallbackDelayDescription => '在不分片重试之前等待响应的时间';

  @override
  String versionAvailable(Object version) {
    return '新版本 $version 可用';
  }

  @override
  String get launchingInstaller => '正在启动安装程序 — Verge 将关闭并更新';

  @override
  String get downloadingUpdate => '正在下载更新…';

  @override
  String get updateReady => 'Verge 新版本已准备好安装';

  @override
  String downloadFailed(Object error) {
    return '下载失败：$error';
  }

  @override
  String get retry => '重试';

  @override
  String get update => '更新';

  @override
  String get later => '稍后';

  @override
  String get whatsNew => '更新内容';

  @override
  String get skipVersion => '跳过此版本';

  @override
  String get installing => '正在安装…';

  @override
  String get downloading => '正在下载';

  @override
  String get activeConnectionPing => '当前连接延迟';

  @override
  String get showPing => '显示延迟';

  @override
  String get showPingDescription => '在主页连接计时器旁显示到服务器的延迟';

  @override
  String get pingIntervalSeconds => '刷新间隔（秒）';

  @override
  String pingIntervalDescription(Object min, Object max, Object def) {
    return '$min 到 $max 秒，默认 $def';
  }

  @override
  String get probeUrl => '检测地址';

  @override
  String get probeUrlDescription => 'TUN 模式下通过该地址检测隧道外的网络连通性；代理模式下测量经本地代理的延迟';

  @override
  String get autoSelectNode => '节点自动选择';

  @override
  String get pickBestNode => '自动选择最佳节点';

  @override
  String healthCheckInterval(Object min, Object max) {
    return '后台检测间隔，秒（$min…$max）';
  }

  @override
  String get profiles => '配置';

  @override
  String get checkNow => '立即检测';

  @override
  String lastCheck(Object time, Object result) {
    return '上次检测：$time — $result';
  }

  @override
  String get nodeResponds => '节点有响应';

  @override
  String lastPick(Object result) {
    return '上次选择：$result';
  }

  @override
  String get emptyLink => '链接为空';

  @override
  String get clipboardEmpty => '剪贴板为空';

  @override
  String get addSubscriptionDescription =>
      '订阅 URL、分享链接（vless://、ss://…）或 JSON 配置';

  @override
  String get pasteFromClipboardHint => '已复制链接？直接从剪贴板添加';

  @override
  String get paste => '粘贴';

  @override
  String get or => '或';

  @override
  String get subscriptionUrlHint => 'https://… 或 vless://…';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get theme => '主题';

  @override
  String get startup => '启动';

  @override
  String get autostart => '自动连接';

  @override
  String get autostartDescription => '启动时连接上次使用的节点';

  @override
  String get localProxyPort => '本地代理端口';

  @override
  String get localProxyPortDescription => 'HTTP + SOCKS，监听 127.0.0.1';

  @override
  String get home => '主页';

  @override
  String get settings => '设置';

  @override
  String get logs => '日志';

  @override
  String get about => '关于';

  @override
  String get newBadge => '新';

  @override
  String get copy => '复制';

  @override
  String get clear => '清空';

  @override
  String get searchLogs => '搜索日志';

  @override
  String get noLogsYet => '暂无日志';

  @override
  String get nothingMatchesFilter => '没有符合筛选条件的内容';

  @override
  String get editNode => '编辑节点';

  @override
  String get name => '名称';

  @override
  String schema(Object engine) {
    return '格式：$engine';
  }

  @override
  String get format => '格式化';

  @override
  String get changesOverwrittenOnRefresh => '更新订阅时修改将被覆盖';

  @override
  String get dnsHijack => 'TUN 中劫持 DNS';

  @override
  String get dnsHijackDescription =>
      '将所有 53 端口流量转入 DNS 引擎。否则查询会发往运营商的 DNS 并被审查';

  @override
  String get dnsProxy => '代理 DNS';

  @override
  String get dnsProxyDescription => '解析通过 VPN 访问的网站';

  @override
  String get dnsDirect => '直连 DNS';

  @override
  String get dnsDirectDescription => '用于直连访问的网站';

  @override
  String get aboutTagline => '基于 sing-box 和 Xray 的 macOS 与 Windows 代理客户端。';

  @override
  String get appVersion => '应用版本';

  @override
  String get checking => '正在检查…';

  @override
  String get checkForUpdates => '检查更新';

  @override
  String get upToDate => '已是最新版本';

  @override
  String get general => '常规';

  @override
  String get network => '网络';

  @override
  String get changesApplyAfterReconnect => '重新连接后更改生效';

  @override
  String get reconnect => '重新连接';

  @override
  String get ipv6Description => '默认关闭：许多服务器只支持 IPv4，IPv6 连接会卡住而不是回退';

  @override
  String get presetAllProxy => '全部走代理';

  @override
  String get presetBypassRu => '绕过俄罗斯';

  @override
  String get presetBlockAds => '仅屏蔽广告';

  @override
  String get geoRuSites => '俄罗斯（网站）';

  @override
  String get geoRuIp => '俄罗斯（IP）';

  @override
  String get geoAds => '广告与跟踪器';

  @override
  String get geoPrivate => '私有域名';

  @override
  String get geoAdult => '成人内容';

  @override
  String get geoCnIp => '中国（IP）';

  @override
  String get geoCnSites => '中国（网站）';

  @override
  String get singboxCrashed => 'sing-box 异常退出';

  @override
  String vpnDisconnectedWithReason(Object reason) {
    return 'VPN 已断开：$reason';
  }

  @override
  String geoSetsNotUpdated(Object count) {
    return '$count 个规则集未更新（请检查网络连接）';
  }

  @override
  String refreshFailed(Object names) {
    return '更新失败：$names';
  }

  @override
  String copyOf(Object name) {
    return '$name（副本）';
  }

  @override
  String healthCheckOk(Object node) {
    return '检测 $node — 正常';
  }

  @override
  String healthCheckFailed(Object node, Object failures, Object limit) {
    return '$node 无响应（$failures/$limit）';
  }

  @override
  String nodeNotRespondingSwitching(Object node) {
    return '节点 $node 无响应 — 正在选择其他节点';
  }

  @override
  String get helperNotInstalled => '系统服务未安装。请使用安装程序（.pkg）重新安装应用。';

  @override
  String updateCheckFailed(Object error) {
    return '检查更新失败：$error';
  }

  @override
  String get updateCheckLatest => '检查更新：已安装最新版本';

  @override
  String updateCheckAvailable(Object version) {
    return '检查更新：$version 可用';
  }

  @override
  String updateDownloadFailed(Object error) {
    return '下载更新失败：$error';
  }

  @override
  String get noLiveNodes => '未找到可用节点，选择未改变';

  @override
  String tcpOnlyResult(Object ms) {
    return 'TCP $ms 毫秒（所有节点的 HTTP 检测均失败）';
  }

  @override
  String get xrayFailedFallback => 'Xray 启动失败，回退到 sing-box';

  @override
  String get xrayFailedManual => 'Xray 启动失败，内核为手动选择 — 不回退';

  @override
  String get xrayFailed => 'Xray 启动失败';

  @override
  String get vpnNotConnectedXray => 'VPN 未连接：Xray 启动失败';

  @override
  String get xrayConfigUnsupported => '无法为此节点生成 Xray 配置';

  @override
  String xrayStartFailed(Object error) {
    return 'Xray 未启动：$error';
  }

  @override
  String get xrayUnavailable => '此平台不支持 Xray';

  @override
  String xraySocksNotResponding(Object port) {
    return 'Xray 已启动，但 socks 端口 $port 无响应';
  }

  @override
  String get xrayFailedRunningSingbox => 'Xray 启动失败，正在使用 sing-box';

  @override
  String get engineChosenManually => '内核为手动选择';

  @override
  String get engineChosenAutomatically => '内核为自动选择';

  @override
  String invalidJson(Object message) {
    return 'JSON 无效：$message';
  }

  @override
  String invalidJsonAt(Object message, Object offset) {
    return 'JSON 无效：$message（第 $offset 个字符）';
  }

  @override
  String get tooManyRedirects => '重定向次数过多';

  @override
  String get subscriptionNoValidNodes => '订阅中没有有效节点';

  @override
  String get subscriptionStubNodes => '订阅返回了占位节点';

  @override
  String get invalidJsonConfig => 'JSON 配置无效';

  @override
  String get expectedOutboundObject => '需要 outbound JSON 对象';

  @override
  String get port => '端口';

  @override
  String testProcessFailed(Object error) {
    return '测试进程启动失败：$error';
  }

  @override
  String get language => '语言';

  @override
  String get interfaceLanguage => '界面语言';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get hotkeys => '快捷键';

  @override
  String get toggleHotkey => '连接 / 断开';

  @override
  String get toggleHotkeyDescription => '全局快捷键 — 即使 Verge 窗口隐藏也有效';

  @override
  String get hotkeyTaken => '此快捷键已被其他应用占用 — 请换一个';

  @override
  String get hotkeyNotSet => '未设置';

  @override
  String get hotkeyPress => '请按下快捷键…';

  @override
  String get hotkeyNeedsModifier => '请加上 Ctrl、Alt 或 ⌘/Win';

  @override
  String get hotkeyClear => '移除快捷键';
}
