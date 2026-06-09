import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('de'),
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart Lock'**
  String get appTitle;

  /// No description provided for @smartLockPlatform.
  ///
  /// In en, this message translates to:
  /// **'Smart Lock Platform'**
  String get smartLockPlatform;

  /// No description provided for @smartLockPlatformSub.
  ///
  /// In en, this message translates to:
  /// **'Smart Lock Management'**
  String get smartLockPlatformSub;

  /// No description provided for @usernameOrEmail.
  ///
  /// In en, this message translates to:
  /// **'Username / Email'**
  String get usernameOrEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @pleaseInputUsername.
  ///
  /// In en, this message translates to:
  /// **'Please enter username'**
  String get pleaseInputUsername;

  /// No description provided for @pleaseInputPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter password'**
  String get pleaseInputPassword;

  /// No description provided for @rememberMe.
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get login;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @my.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get my;

  /// No description provided for @keysManagement.
  ///
  /// In en, this message translates to:
  /// **'Keys'**
  String get keysManagement;

  /// No description provided for @locksManagement.
  ///
  /// In en, this message translates to:
  /// **'Locks'**
  String get locksManagement;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @currentTestHome.
  ///
  /// In en, this message translates to:
  /// **'Current Test Home'**
  String get currentTestHome;

  /// No description provided for @vendorSdkTest.
  ///
  /// In en, this message translates to:
  /// **'Vendor SDK Test'**
  String get vendorSdkTest;

  /// No description provided for @onlineSwitchLock.
  ///
  /// In en, this message translates to:
  /// **'Online Switch-Lock'**
  String get onlineSwitchLock;

  /// No description provided for @keepOriginalTestFlow.
  ///
  /// In en, this message translates to:
  /// **'Keep original test flow'**
  String get keepOriginalTestFlow;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logout;

  /// No description provided for @confirmLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get confirmLogout;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logoutAction.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logoutAction;

  /// No description provided for @cannotOpenCerebSite.
  ///
  /// In en, this message translates to:
  /// **'Unable to open Cereb.AI website'**
  String get cannotOpenCerebSite;

  /// No description provided for @poweredBy.
  ///
  /// In en, this message translates to:
  /// **'powered by'**
  String get poweredBy;

  /// No description provided for @searchKeyHint.
  ///
  /// In en, this message translates to:
  /// **'Search key name/number'**
  String get searchKeyHint;

  /// No description provided for @searchLockHint.
  ///
  /// In en, this message translates to:
  /// **'Search lock name/number/location'**
  String get searchLockHint;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired, please log in again'**
  String get sessionExpired;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['de', 'en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.scriptCode) {
    case 'Hans': return AppLocalizationsZhHans();
case 'Hant': return AppLocalizationsZhHant();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'de': return AppLocalizationsDe();
    case 'en': return AppLocalizationsEn();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
