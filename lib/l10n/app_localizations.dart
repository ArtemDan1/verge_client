import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fa.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_tr.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fa'),
    Locale('fr'),
    Locale('pt'),
    Locale('ru'),
    Locale('tr'),
    Locale('zh'),
  ];

  /// No description provided for @renameProfile.
  ///
  /// In en, this message translates to:
  /// **'Rename profile'**
  String get renameProfile;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @subscriptionsUpdated.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions updated'**
  String get subscriptionsUpdated;

  /// No description provided for @unitB.
  ///
  /// In en, this message translates to:
  /// **'B'**
  String get unitB;

  /// No description provided for @unitKB.
  ///
  /// In en, this message translates to:
  /// **'KB'**
  String get unitKB;

  /// No description provided for @unitMB.
  ///
  /// In en, this message translates to:
  /// **'MB'**
  String get unitMB;

  /// No description provided for @unitGB.
  ///
  /// In en, this message translates to:
  /// **'GB'**
  String get unitGB;

  /// No description provided for @unitTB.
  ///
  /// In en, this message translates to:
  /// **'TB'**
  String get unitTB;

  /// No description provided for @usedNoLimit.
  ///
  /// In en, this message translates to:
  /// **'{used} used · no limit'**
  String usedNoLimit(Object used);

  /// No description provided for @validUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String validUntil(Object date);

  /// No description provided for @timeout.
  ///
  /// In en, this message translates to:
  /// **'timeout'**
  String get timeout;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'error'**
  String get error;

  /// No description provided for @pingAll.
  ///
  /// In en, this message translates to:
  /// **'Ping all'**
  String get pingAll;

  /// No description provided for @refreshSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'Refresh subscriptions'**
  String get refreshSubscriptions;

  /// No description provided for @addSubscription.
  ///
  /// In en, this message translates to:
  /// **'Add subscription'**
  String get addSubscription;

  /// No description provided for @servers.
  ///
  /// In en, this message translates to:
  /// **'Servers'**
  String get servers;

  /// No description provided for @pickingNode.
  ///
  /// In en, this message translates to:
  /// **'Picking a node…'**
  String get pickingNode;

  /// No description provided for @noSubscriptions.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions yet. Add the first one.'**
  String get noSubscriptions;

  /// No description provided for @subscriptionHasNoServers.
  ///
  /// In en, this message translates to:
  /// **'This subscription has no servers'**
  String get subscriptionHasNoServers;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'active'**
  String get active;

  /// No description provided for @columnServer.
  ///
  /// In en, this message translates to:
  /// **'Server'**
  String get columnServer;

  /// No description provided for @columnProtocol.
  ///
  /// In en, this message translates to:
  /// **'Protocol'**
  String get columnProtocol;

  /// No description provided for @columnEngine.
  ///
  /// In en, this message translates to:
  /// **'Engine'**
  String get columnEngine;

  /// No description provided for @columnLatency.
  ///
  /// In en, this message translates to:
  /// **'Latency'**
  String get columnLatency;

  /// No description provided for @ms.
  ///
  /// In en, this message translates to:
  /// **'{ms} ms'**
  String ms(Object ms);

  /// No description provided for @engineAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto ({engine})'**
  String engineAuto(Object engine);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @ping.
  ///
  /// In en, this message translates to:
  /// **'Ping'**
  String get ping;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @subscriptionLinkCopied.
  ///
  /// In en, this message translates to:
  /// **'Subscription link copied'**
  String get subscriptionLinkCopied;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @accountPage.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountPage;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @autoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh'**
  String get autoRefresh;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @autoSelectOn.
  ///
  /// In en, this message translates to:
  /// **'Auto-select: on'**
  String get autoSelectOn;

  /// No description provided for @autoSelect.
  ///
  /// In en, this message translates to:
  /// **'Auto-select'**
  String get autoSelect;

  /// No description provided for @refreshOwn.
  ///
  /// In en, this message translates to:
  /// **'Custom: {hours} h'**
  String refreshOwn(Object hours);

  /// No description provided for @refreshBySubscription.
  ///
  /// In en, this message translates to:
  /// **'From subscription: {hours} h'**
  String refreshBySubscription(Object hours);

  /// No description provided for @off.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get off;

  /// No description provided for @autoRefreshInterval.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh interval'**
  String get autoRefreshInterval;

  /// No description provided for @hours.
  ///
  /// In en, this message translates to:
  /// **'Hours'**
  String get hours;

  /// No description provided for @emptyUseSubscriptionInterval.
  ///
  /// In en, this message translates to:
  /// **'Empty — use the subscription interval ({hours} h)'**
  String emptyUseSubscriptionInterval(Object hours);

  /// No description provided for @emptyNoAutoRefresh.
  ///
  /// In en, this message translates to:
  /// **'Empty — don\'t refresh automatically'**
  String get emptyNoAutoRefresh;

  /// No description provided for @serverCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} server} other{{count} servers}}'**
  String serverCount(int count);

  /// No description provided for @usedOfTotal.
  ///
  /// In en, this message translates to:
  /// **'{used} of {total}'**
  String usedOfTotal(Object used, Object total);

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String remaining(Object amount);

  /// No description provided for @limitExhausted.
  ///
  /// In en, this message translates to:
  /// **'limit reached'**
  String get limitExhausted;

  /// No description provided for @newProfile.
  ///
  /// In en, this message translates to:
  /// **'New profile'**
  String get newProfile;

  /// No description provided for @routing.
  ///
  /// In en, this message translates to:
  /// **'Routing'**
  String get routing;

  /// No description provided for @updateGeo.
  ///
  /// In en, this message translates to:
  /// **'Update geo'**
  String get updateGeo;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @routingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'What goes through the VPN, what goes direct, and what is blocked'**
  String get routingSubtitle;

  /// No description provided for @geoNeverUpdated.
  ///
  /// In en, this message translates to:
  /// **'never updated — bundled versions'**
  String get geoNeverUpdated;

  /// No description provided for @geoUpdated.
  ///
  /// In en, this message translates to:
  /// **'updated {ago}'**
  String geoUpdated(Object ago);

  /// No description provided for @geoSets.
  ///
  /// In en, this message translates to:
  /// **'Geo sets (.srs): {status}'**
  String geoSets(Object status);

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get justNow;

  /// No description provided for @minutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} min ago'**
  String minutesAgo(Object n);

  /// No description provided for @hoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} h ago'**
  String hoursAgo(Object n);

  /// No description provided for @daysAgo.
  ///
  /// In en, this message translates to:
  /// **'{n} d ago'**
  String daysAgo(Object n);

  /// No description provided for @restDirect.
  ///
  /// In en, this message translates to:
  /// **'the rest direct'**
  String get restDirect;

  /// No description provided for @restViaVpn.
  ///
  /// In en, this message translates to:
  /// **'the rest via VPN'**
  String get restViaVpn;

  /// No description provided for @builtIn.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get builtIn;

  /// No description provided for @custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get custom;

  /// No description provided for @allDirect.
  ///
  /// In en, this message translates to:
  /// **'everything direct'**
  String get allDirect;

  /// No description provided for @allViaVpn.
  ///
  /// In en, this message translates to:
  /// **'everything via VPN'**
  String get allViaVpn;

  /// No description provided for @ruleCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} rule} other{{count} rules}}'**
  String ruleCount(int count);

  /// No description provided for @groupViaVpn.
  ///
  /// In en, this message translates to:
  /// **'Via VPN'**
  String get groupViaVpn;

  /// No description provided for @groupDirect.
  ///
  /// In en, this message translates to:
  /// **'Direct'**
  String get groupDirect;

  /// No description provided for @groupBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get groupBlock;

  /// No description provided for @groupExceptions.
  ///
  /// In en, this message translates to:
  /// **'Exceptions (override block)'**
  String get groupExceptions;

  /// No description provided for @exceptionsGo.
  ///
  /// In en, this message translates to:
  /// **'Exceptions go'**
  String get exceptionsGo;

  /// No description provided for @viaVpn.
  ///
  /// In en, this message translates to:
  /// **'via VPN'**
  String get viaVpn;

  /// No description provided for @direct.
  ///
  /// In en, this message translates to:
  /// **'direct'**
  String get direct;

  /// No description provided for @duplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicate;

  /// No description provided for @use.
  ///
  /// In en, this message translates to:
  /// **'Use'**
  String get use;

  /// No description provided for @builtInProfileReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Built-in profiles can\'t be changed — duplicate one to customize its rules.'**
  String get builtInProfileReadOnly;

  /// No description provided for @everythingElse.
  ///
  /// In en, this message translates to:
  /// **'Everything not matched by rules'**
  String get everythingElse;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Empty'**
  String get empty;

  /// No description provided for @chooseCategory.
  ///
  /// In en, this message translates to:
  /// **'Choose a category'**
  String get chooseCategory;

  /// No description provided for @domainOrCidr.
  ///
  /// In en, this message translates to:
  /// **'Domain or IP/CIDR'**
  String get domainOrCidr;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @domainOrCidrHint.
  ///
  /// In en, this message translates to:
  /// **'example.com or 1.2.3.0/24'**
  String get domainOrCidrHint;

  /// No description provided for @geoCategory.
  ///
  /// In en, this message translates to:
  /// **'Geo category'**
  String get geoCategory;

  /// No description provided for @domainOrIp.
  ///
  /// In en, this message translates to:
  /// **'Domain or IP'**
  String get domainOrIp;

  /// No description provided for @addRule.
  ///
  /// In en, this message translates to:
  /// **'Add rule'**
  String get addRule;

  /// No description provided for @kindProxy.
  ///
  /// In en, this message translates to:
  /// **'Proxy'**
  String get kindProxy;

  /// No description provided for @kindBlock.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get kindBlock;

  /// No description provided for @otherApps.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get otherApps;

  /// No description provided for @noActiveConnections.
  ///
  /// In en, this message translates to:
  /// **'No active connections'**
  String get noActiveConnections;

  /// No description provided for @vpnDisconnected.
  ///
  /// In en, this message translates to:
  /// **'VPN is off'**
  String get vpnDisconnected;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @byApp.
  ///
  /// In en, this message translates to:
  /// **'By app'**
  String get byApp;

  /// No description provided for @asList.
  ///
  /// In en, this message translates to:
  /// **'List'**
  String get asList;

  /// No description provided for @connectionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Domain, IP or app'**
  String get connectionsSearchHint;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @kindProxyShort.
  ///
  /// In en, this message translates to:
  /// **'proxy'**
  String get kindProxyShort;

  /// No description provided for @kindBlockShort.
  ///
  /// In en, this message translates to:
  /// **'block'**
  String get kindBlockShort;

  /// No description provided for @connectionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} connection} other{{count} connections}}'**
  String connectionCount(int count);

  /// No description provided for @fieldApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get fieldApp;

  /// No description provided for @fieldProcessPath.
  ///
  /// In en, this message translates to:
  /// **'Process path'**
  String get fieldProcessPath;

  /// No description provided for @fieldNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get fieldNetwork;

  /// No description provided for @fieldSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get fieldSource;

  /// No description provided for @fieldDestination.
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get fieldDestination;

  /// No description provided for @fieldDomain.
  ///
  /// In en, this message translates to:
  /// **'Domain'**
  String get fieldDomain;

  /// No description provided for @fieldChain.
  ///
  /// In en, this message translates to:
  /// **'Chain'**
  String get fieldChain;

  /// No description provided for @fieldRule.
  ///
  /// In en, this message translates to:
  /// **'Rule'**
  String get fieldRule;

  /// No description provided for @fieldDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get fieldDuration;

  /// No description provided for @fieldStart.
  ///
  /// In en, this message translates to:
  /// **'Started'**
  String get fieldStart;

  /// No description provided for @connectionClosed.
  ///
  /// In en, this message translates to:
  /// **'connection closed'**
  String get connectionClosed;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @received.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get received;

  /// No description provided for @advanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get advanced;

  /// No description provided for @tunAdvancedDescription.
  ///
  /// In en, this message translates to:
  /// **'Interface address, MTU, network stack and routes. Tuned for most networks — change only if TUN misbehaves'**
  String get tunAdvancedDescription;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @tunAdvancedWarning.
  ///
  /// In en, this message translates to:
  /// **'Change these values only if you understand the consequences. MTU 9000 breaks SSH and MySQL, an address from 172.16.0.0/12 breaks docker networks, strict route captures local network traffic.'**
  String get tunAdvancedWarning;

  /// No description provided for @interfaceAddress.
  ///
  /// In en, this message translates to:
  /// **'Interface address'**
  String get interfaceAddress;

  /// No description provided for @rangeFromTo.
  ///
  /// In en, this message translates to:
  /// **'From {min} to {max}'**
  String rangeFromTo(Object min, Object max);

  /// No description provided for @networkStack.
  ///
  /// In en, this message translates to:
  /// **'Network stack'**
  String get networkStack;

  /// No description provided for @networkStackDescription.
  ///
  /// In en, this message translates to:
  /// **'gvisor — compatibility, system — speed, mixed — balance'**
  String get networkStackDescription;

  /// No description provided for @strictRoute.
  ///
  /// In en, this message translates to:
  /// **'Strict route'**
  String get strictRoute;

  /// No description provided for @strictRouteDescription.
  ///
  /// In en, this message translates to:
  /// **'Keeps traffic from bypassing the tunnel'**
  String get strictRouteDescription;

  /// No description provided for @autoRoute.
  ///
  /// In en, this message translates to:
  /// **'Default route'**
  String get autoRoute;

  /// No description provided for @autoRouteDescription.
  ///
  /// In en, this message translates to:
  /// **'All system traffic goes into the tunnel'**
  String get autoRouteDescription;

  /// No description provided for @daysShort.
  ///
  /// In en, this message translates to:
  /// **'{n}d'**
  String daysShort(Object n);

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @connecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get connecting;

  /// No description provided for @notConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get notConnected;

  /// No description provided for @chooseServerBelow.
  ///
  /// In en, this message translates to:
  /// **'Choose a server below'**
  String get chooseServerBelow;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @noInternet.
  ///
  /// In en, this message translates to:
  /// **'no internet'**
  String get noInternet;

  /// No description provided for @routingRules.
  ///
  /// In en, this message translates to:
  /// **'Routing rules'**
  String get routingRules;

  /// No description provided for @disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get disconnect;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @checkingServer.
  ///
  /// In en, this message translates to:
  /// **'Checking the server'**
  String get checkingServer;

  /// No description provided for @clickToConnect.
  ///
  /// In en, this message translates to:
  /// **'Click to connect'**
  String get clickToConnect;

  /// No description provided for @quitVerge.
  ///
  /// In en, this message translates to:
  /// **'Quit Verge'**
  String get quitVerge;

  /// No description provided for @noSubscriptionsTray.
  ///
  /// In en, this message translates to:
  /// **'No subscriptions — add them in the main window'**
  String get noSubscriptionsTray;

  /// No description provided for @openVerge.
  ///
  /// In en, this message translates to:
  /// **'Open Verge'**
  String get openVerge;

  /// No description provided for @noResponse.
  ///
  /// In en, this message translates to:
  /// **'no response'**
  String get noResponse;

  /// No description provided for @skipCertVerify.
  ///
  /// In en, this message translates to:
  /// **'Skip certificate verification'**
  String get skipCertVerify;

  /// No description provided for @skipCertVerifyDescription.
  ///
  /// In en, this message translates to:
  /// **'Lowers security: the connection no longer protects against server spoofing. Enable only for debugging'**
  String get skipCertVerifyDescription;

  /// No description provided for @tlsFragment.
  ///
  /// In en, this message translates to:
  /// **'TLS fragmentation'**
  String get tlsFragment;

  /// No description provided for @tlsFragmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Splits the TLS handshake into pieces to get past firewalls that do naive ClientHello matching. Works with sing-box only'**
  String get tlsFragmentDescription;

  /// No description provided for @tlsFragmentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'The current engine does not support fragmentation'**
  String get tlsFragmentUnsupported;

  /// No description provided for @tlsRecordFragment.
  ///
  /// In en, this message translates to:
  /// **'TLS record fragmentation'**
  String get tlsRecordFragment;

  /// No description provided for @tlsRecordFragmentDescription.
  ///
  /// In en, this message translates to:
  /// **'Cheaper on performance — worth trying first'**
  String get tlsRecordFragmentDescription;

  /// No description provided for @fallbackDelay.
  ///
  /// In en, this message translates to:
  /// **'Fallback delay'**
  String get fallbackDelay;

  /// No description provided for @fallbackDelayDescription.
  ///
  /// In en, this message translates to:
  /// **'How long to wait for a response before retrying without fragmentation'**
  String get fallbackDelayDescription;

  /// No description provided for @versionAvailable.
  ///
  /// In en, this message translates to:
  /// **'Version {version} is available'**
  String versionAvailable(Object version);

  /// No description provided for @launchingInstaller.
  ///
  /// In en, this message translates to:
  /// **'Launching the installer — Verge will close and update'**
  String get launchingInstaller;

  /// No description provided for @downloadingUpdate.
  ///
  /// In en, this message translates to:
  /// **'Downloading the update…'**
  String get downloadingUpdate;

  /// No description provided for @updateReady.
  ///
  /// In en, this message translates to:
  /// **'A new version of Verge is ready to install'**
  String get updateReady;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailed(Object error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @later.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get later;

  /// No description provided for @whatsNew.
  ///
  /// In en, this message translates to:
  /// **'What\'s new'**
  String get whatsNew;

  /// No description provided for @skipVersion.
  ///
  /// In en, this message translates to:
  /// **'Skip this version'**
  String get skipVersion;

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing…'**
  String get installing;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @activeConnectionPing.
  ///
  /// In en, this message translates to:
  /// **'Active connection ping'**
  String get activeConnectionPing;

  /// No description provided for @showPing.
  ///
  /// In en, this message translates to:
  /// **'Show ping'**
  String get showPing;

  /// No description provided for @showPingDescription.
  ///
  /// In en, this message translates to:
  /// **'Server latency on the home screen, next to the connection timer'**
  String get showPingDescription;

  /// No description provided for @pingIntervalSeconds.
  ///
  /// In en, this message translates to:
  /// **'Refresh interval, s'**
  String get pingIntervalSeconds;

  /// No description provided for @pingIntervalDescription.
  ///
  /// In en, this message translates to:
  /// **'From {min} to {max} s, default {def}'**
  String pingIntervalDescription(Object min, Object max, Object def);

  /// No description provided for @probeUrl.
  ///
  /// In en, this message translates to:
  /// **'Probe URL'**
  String get probeUrl;

  /// No description provided for @probeUrlDescription.
  ///
  /// In en, this message translates to:
  /// **'In TUN mode this URL checks internet access outside the tunnel; in Proxy mode it measures latency through the local proxy'**
  String get probeUrlDescription;

  /// No description provided for @autoSelectNode.
  ///
  /// In en, this message translates to:
  /// **'Node auto-select'**
  String get autoSelectNode;

  /// No description provided for @pickBestNode.
  ///
  /// In en, this message translates to:
  /// **'Pick the best node'**
  String get pickBestNode;

  /// No description provided for @healthCheckInterval.
  ///
  /// In en, this message translates to:
  /// **'Background check interval, seconds ({min}…{max})'**
  String healthCheckInterval(Object min, Object max);

  /// No description provided for @profiles.
  ///
  /// In en, this message translates to:
  /// **'Profiles'**
  String get profiles;

  /// No description provided for @checkNow.
  ///
  /// In en, this message translates to:
  /// **'Check now'**
  String get checkNow;

  /// No description provided for @lastCheck.
  ///
  /// In en, this message translates to:
  /// **'Last check: {time} — {result}'**
  String lastCheck(Object time, Object result);

  /// No description provided for @nodeResponds.
  ///
  /// In en, this message translates to:
  /// **'node responds'**
  String get nodeResponds;

  /// No description provided for @lastPick.
  ///
  /// In en, this message translates to:
  /// **'Last pick: {result}'**
  String lastPick(Object result);

  /// No description provided for @emptyLink.
  ///
  /// In en, this message translates to:
  /// **'Empty link'**
  String get emptyLink;

  /// No description provided for @clipboardEmpty.
  ///
  /// In en, this message translates to:
  /// **'Clipboard is empty'**
  String get clipboardEmpty;

  /// No description provided for @addSubscriptionDescription.
  ///
  /// In en, this message translates to:
  /// **'Subscription URL, share link (vless://, ss://…) or JSON config'**
  String get addSubscriptionDescription;

  /// No description provided for @pasteFromClipboardHint.
  ///
  /// In en, this message translates to:
  /// **'Copied a link? Add it straight from the clipboard'**
  String get pasteFromClipboardHint;

  /// No description provided for @paste.
  ///
  /// In en, this message translates to:
  /// **'Paste'**
  String get paste;

  /// No description provided for @or.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get or;

  /// No description provided for @subscriptionUrlHint.
  ///
  /// In en, this message translates to:
  /// **'https://… or vless://…'**
  String get subscriptionUrlHint;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @startup.
  ///
  /// In en, this message translates to:
  /// **'Startup'**
  String get startup;

  /// No description provided for @autostart.
  ///
  /// In en, this message translates to:
  /// **'Auto-connect'**
  String get autostart;

  /// No description provided for @autostartDescription.
  ///
  /// In en, this message translates to:
  /// **'Connect to the last node on launch'**
  String get autostartDescription;

  /// No description provided for @localProxyPort.
  ///
  /// In en, this message translates to:
  /// **'Local proxy port'**
  String get localProxyPort;

  /// No description provided for @localProxyPortDescription.
  ///
  /// In en, this message translates to:
  /// **'HTTP + SOCKS on 127.0.0.1'**
  String get localProxyPortDescription;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get logs;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @newBadge.
  ///
  /// In en, this message translates to:
  /// **'new'**
  String get newBadge;

  /// No description provided for @copy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @searchLogs.
  ///
  /// In en, this message translates to:
  /// **'Search logs'**
  String get searchLogs;

  /// No description provided for @noLogsYet.
  ///
  /// In en, this message translates to:
  /// **'No logs yet'**
  String get noLogsYet;

  /// No description provided for @nothingMatchesFilter.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches the filter'**
  String get nothingMatchesFilter;

  /// No description provided for @editNode.
  ///
  /// In en, this message translates to:
  /// **'Edit node'**
  String get editNode;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @schema.
  ///
  /// In en, this message translates to:
  /// **'Schema: {engine}'**
  String schema(Object engine);

  /// No description provided for @format.
  ///
  /// In en, this message translates to:
  /// **'Format'**
  String get format;

  /// No description provided for @changesOverwrittenOnRefresh.
  ///
  /// In en, this message translates to:
  /// **'Changes will be overwritten when the subscription refreshes'**
  String get changesOverwrittenOnRefresh;

  /// No description provided for @dnsHijack.
  ///
  /// In en, this message translates to:
  /// **'DNS hijack in TUN'**
  String get dnsHijack;

  /// No description provided for @dnsHijackDescription.
  ///
  /// In en, this message translates to:
  /// **'Redirects all port 53 traffic to the DNS engine. Without it, queries go to the ISP\'s DNS and get censored'**
  String get dnsHijackDescription;

  /// No description provided for @dnsProxy.
  ///
  /// In en, this message translates to:
  /// **'DNS for proxy'**
  String get dnsProxy;

  /// No description provided for @dnsProxyDescription.
  ///
  /// In en, this message translates to:
  /// **'Resolves sites that go through the VPN'**
  String get dnsProxyDescription;

  /// No description provided for @dnsDirect.
  ///
  /// In en, this message translates to:
  /// **'DNS for direct connections'**
  String get dnsDirect;

  /// No description provided for @dnsDirectDescription.
  ///
  /// In en, this message translates to:
  /// **'For sites that open directly'**
  String get dnsDirectDescription;

  /// No description provided for @aboutTagline.
  ///
  /// In en, this message translates to:
  /// **'A proxy client for macOS and Windows built on sing-box and Xray.'**
  String get aboutTagline;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @checking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get checking;

  /// No description provided for @checkForUpdates.
  ///
  /// In en, this message translates to:
  /// **'Check for updates'**
  String get checkForUpdates;

  /// No description provided for @upToDate.
  ///
  /// In en, this message translates to:
  /// **'You have the latest version'**
  String get upToDate;

  /// No description provided for @general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get general;

  /// No description provided for @network.
  ///
  /// In en, this message translates to:
  /// **'Network'**
  String get network;

  /// No description provided for @changesApplyAfterReconnect.
  ///
  /// In en, this message translates to:
  /// **'Changes will apply after reconnecting'**
  String get changesApplyAfterReconnect;

  /// No description provided for @reconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnect;

  /// No description provided for @ipv6Description.
  ///
  /// In en, this message translates to:
  /// **'Off by default: many servers are IPv4-only, and IPv6 connections hang instead of falling back'**
  String get ipv6Description;

  /// No description provided for @presetAllProxy.
  ///
  /// In en, this message translates to:
  /// **'Everything via proxy'**
  String get presetAllProxy;

  /// No description provided for @presetBypassRu.
  ///
  /// In en, this message translates to:
  /// **'Bypass Russia'**
  String get presetBypassRu;

  /// No description provided for @presetBlockAds.
  ///
  /// In en, this message translates to:
  /// **'Ad blocking only'**
  String get presetBlockAds;

  /// No description provided for @geoRuSites.
  ///
  /// In en, this message translates to:
  /// **'Russia (sites)'**
  String get geoRuSites;

  /// No description provided for @geoRuIp.
  ///
  /// In en, this message translates to:
  /// **'Russia (IP)'**
  String get geoRuIp;

  /// No description provided for @geoAds.
  ///
  /// In en, this message translates to:
  /// **'Ads and trackers'**
  String get geoAds;

  /// No description provided for @geoPrivate.
  ///
  /// In en, this message translates to:
  /// **'Private domains'**
  String get geoPrivate;

  /// No description provided for @geoAdult.
  ///
  /// In en, this message translates to:
  /// **'Adult content'**
  String get geoAdult;

  /// No description provided for @geoCnIp.
  ///
  /// In en, this message translates to:
  /// **'China (IP)'**
  String get geoCnIp;

  /// No description provided for @geoCnSites.
  ///
  /// In en, this message translates to:
  /// **'China (sites)'**
  String get geoCnSites;

  /// No description provided for @singboxCrashed.
  ///
  /// In en, this message translates to:
  /// **'sing-box crashed'**
  String get singboxCrashed;

  /// No description provided for @vpnDisconnectedWithReason.
  ///
  /// In en, this message translates to:
  /// **'VPN disconnected: {reason}'**
  String vpnDisconnectedWithReason(Object reason);

  /// No description provided for @geoSetsNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'{count} set(s) not updated (check your connection)'**
  String geoSetsNotUpdated(Object count);

  /// No description provided for @refreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to refresh: {names}'**
  String refreshFailed(Object names);

  /// No description provided for @copyOf.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String copyOf(Object name);

  /// No description provided for @healthCheckOk.
  ///
  /// In en, this message translates to:
  /// **'check {node} — ok'**
  String healthCheckOk(Object node);

  /// No description provided for @healthCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'{node} did not respond ({failures} of {limit})'**
  String healthCheckFailed(Object node, Object failures, Object limit);

  /// No description provided for @nodeNotRespondingSwitching.
  ///
  /// In en, this message translates to:
  /// **'Node {node} is not responding — picking another one'**
  String nodeNotRespondingSwitching(Object node);

  /// No description provided for @helperNotInstalled.
  ///
  /// In en, this message translates to:
  /// **'The system service is not installed. Reinstall the app using the installer (.pkg).'**
  String get helperNotInstalled;

  /// No description provided for @updateCheckFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to check for updates: {error}'**
  String updateCheckFailed(Object error);

  /// No description provided for @updateCheckLatest.
  ///
  /// In en, this message translates to:
  /// **'Update check: the latest version is installed'**
  String get updateCheckLatest;

  /// No description provided for @updateCheckAvailable.
  ///
  /// In en, this message translates to:
  /// **'Update check: {version} is available'**
  String updateCheckAvailable(Object version);

  /// No description provided for @updateDownloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to download the update: {error}'**
  String updateDownloadFailed(Object error);

  /// No description provided for @noLiveNodes.
  ///
  /// In en, this message translates to:
  /// **'no live nodes found, selection unchanged'**
  String get noLiveNodes;

  /// No description provided for @tcpOnlyResult.
  ///
  /// In en, this message translates to:
  /// **'TCP {ms} ms (HTTP failed on every node)'**
  String tcpOnlyResult(Object ms);

  /// No description provided for @xrayFailedFallback.
  ///
  /// In en, this message translates to:
  /// **'Xray failed to start, falling back to sing-box'**
  String get xrayFailedFallback;

  /// No description provided for @xrayFailedManual.
  ///
  /// In en, this message translates to:
  /// **'Xray failed to start, engine was chosen manually — no fallback'**
  String get xrayFailedManual;

  /// No description provided for @xrayFailed.
  ///
  /// In en, this message translates to:
  /// **'Xray failed to start'**
  String get xrayFailed;

  /// No description provided for @vpnNotConnectedXray.
  ///
  /// In en, this message translates to:
  /// **'VPN not connected: Xray failed to start'**
  String get vpnNotConnectedXray;

  /// No description provided for @xrayConfigUnsupported.
  ///
  /// In en, this message translates to:
  /// **'an Xray config can\'t be built for this node'**
  String get xrayConfigUnsupported;

  /// No description provided for @xrayStartFailed.
  ///
  /// In en, this message translates to:
  /// **'Xray did not start: {error}'**
  String xrayStartFailed(Object error);

  /// No description provided for @xrayUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Xray is not available on this platform'**
  String get xrayUnavailable;

  /// No description provided for @xraySocksNotResponding.
  ///
  /// In en, this message translates to:
  /// **'Xray started, but socks port {port} is not responding'**
  String xraySocksNotResponding(Object port);

  /// No description provided for @xrayFailedRunningSingbox.
  ///
  /// In en, this message translates to:
  /// **'Xray failed to start, running on sing-box'**
  String get xrayFailedRunningSingbox;

  /// No description provided for @engineChosenManually.
  ///
  /// In en, this message translates to:
  /// **'Engine chosen manually'**
  String get engineChosenManually;

  /// No description provided for @engineChosenAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Engine chosen automatically'**
  String get engineChosenAutomatically;

  /// No description provided for @invalidJson.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON: {message}'**
  String invalidJson(Object message);

  /// No description provided for @invalidJsonAt.
  ///
  /// In en, this message translates to:
  /// **'Invalid JSON: {message} (character {offset})'**
  String invalidJsonAt(Object message, Object offset);

  /// No description provided for @tooManyRedirects.
  ///
  /// In en, this message translates to:
  /// **'too many redirects'**
  String get tooManyRedirects;

  /// No description provided for @subscriptionNoValidNodes.
  ///
  /// In en, this message translates to:
  /// **'the subscription has no valid nodes'**
  String get subscriptionNoValidNodes;

  /// No description provided for @subscriptionStubNodes.
  ///
  /// In en, this message translates to:
  /// **'the subscription returned placeholder nodes'**
  String get subscriptionStubNodes;

  /// No description provided for @invalidJsonConfig.
  ///
  /// In en, this message translates to:
  /// **'invalid JSON config'**
  String get invalidJsonConfig;

  /// No description provided for @expectedOutboundObject.
  ///
  /// In en, this message translates to:
  /// **'Expected an outbound JSON object'**
  String get expectedOutboundObject;

  /// No description provided for @port.
  ///
  /// In en, this message translates to:
  /// **'port'**
  String get port;

  /// No description provided for @testProcessFailed.
  ///
  /// In en, this message translates to:
  /// **'test process failed to start: {error}'**
  String testProcessFailed(Object error);

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @interfaceLanguage.
  ///
  /// In en, this message translates to:
  /// **'Interface language'**
  String get interfaceLanguage;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @hotkeys.
  ///
  /// In en, this message translates to:
  /// **'Hotkeys'**
  String get hotkeys;

  /// No description provided for @toggleHotkey.
  ///
  /// In en, this message translates to:
  /// **'Connect / disconnect'**
  String get toggleHotkey;

  /// No description provided for @toggleHotkeyDescription.
  ///
  /// In en, this message translates to:
  /// **'Global shortcut — works even when the Verge window is hidden'**
  String get toggleHotkeyDescription;

  /// No description provided for @hotkeyTaken.
  ///
  /// In en, this message translates to:
  /// **'This shortcut is used by another app — choose a different one'**
  String get hotkeyTaken;

  /// No description provided for @hotkeyNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get hotkeyNotSet;

  /// No description provided for @hotkeyPress.
  ///
  /// In en, this message translates to:
  /// **'Press a shortcut…'**
  String get hotkeyPress;

  /// No description provided for @hotkeyNeedsModifier.
  ///
  /// In en, this message translates to:
  /// **'Add Ctrl, Alt or ⌘/Win'**
  String get hotkeyNeedsModifier;

  /// No description provided for @hotkeyClear.
  ///
  /// In en, this message translates to:
  /// **'Remove shortcut'**
  String get hotkeyClear;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fa',
    'fr',
    'pt',
    'ru',
    'tr',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fa':
      return AppLocalizationsFa();
    case 'fr':
      return AppLocalizationsFr();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'tr':
      return AppLocalizationsTr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
