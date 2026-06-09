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

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete key'**
  String get deleteKeyTitle;

  /// No description provided for @deleteLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete lock'**
  String get deleteLockTitle;

  /// No description provided for @confirmDeleteItem.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete {name}?'**
  String confirmDeleteItem(Object name);

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

  /// No description provided for @smartListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get smartListEmpty;

  /// No description provided for @smartListLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get smartListLoading;

  /// No description provided for @smartListNoMore.
  ///
  /// In en, this message translates to:
  /// **'No more data'**
  String get smartListNoMore;

  /// No description provided for @unnamedDevice.
  ///
  /// In en, this message translates to:
  /// **'Unnamed'**
  String get unnamedDevice;

  /// No description provided for @wizardConfirmStep.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get wizardConfirmStep;

  /// No description provided for @keyWizardCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Key (Step by step)'**
  String get keyWizardCreateTitle;

  /// No description provided for @keyWizardEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Key (Step by step)'**
  String get keyWizardEditTitle;

  /// No description provided for @keyWizardFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in name and number first'**
  String get keyWizardFillRequired;

  /// No description provided for @keyWizardSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get keyWizardSave;

  /// No description provided for @keyWizardNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get keyWizardNext;

  /// No description provided for @keyWizardPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get keyWizardPrevious;

  /// No description provided for @keyWizardStepConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect Device'**
  String get keyWizardStepConnect;

  /// No description provided for @keyWizardConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Scan key, select MAC, then connect and read key info.'**
  String get keyWizardConnectHint;

  /// No description provided for @keyWizardScanning.
  ///
  /// In en, this message translates to:
  /// **'Scanning keys...'**
  String get keyWizardScanning;

  /// No description provided for @keyWizardScanStarted.
  ///
  /// In en, this message translates to:
  /// **'Scan started, waiting for device list to refresh'**
  String get keyWizardScanStarted;

  /// No description provided for @keyWizardScanningShort.
  ///
  /// In en, this message translates to:
  /// **'Scanning'**
  String get keyWizardScanningShort;

  /// No description provided for @keyWizardScanKey.
  ///
  /// In en, this message translates to:
  /// **'Scan Key'**
  String get keyWizardScanKey;

  /// No description provided for @keyWizardReadingInfo.
  ///
  /// In en, this message translates to:
  /// **'Connecting and reading key info...'**
  String get keyWizardReadingInfo;

  /// No description provided for @keyWizardReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Key info read'**
  String get keyWizardReadSuccess;

  /// No description provided for @keyWizardReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read key info'**
  String get keyWizardReadFailed;

  /// No description provided for @keyWizardReadAction.
  ///
  /// In en, this message translates to:
  /// **'Connect and Read Key Info'**
  String get keyWizardReadAction;

  /// No description provided for @keyWizardStepInfo.
  ///
  /// In en, this message translates to:
  /// **'Fill Information'**
  String get keyWizardStepInfo;

  /// No description provided for @keyWizardKeyName.
  ///
  /// In en, this message translates to:
  /// **'Key Name'**
  String get keyWizardKeyName;

  /// No description provided for @keyWizardKeyNumber.
  ///
  /// In en, this message translates to:
  /// **'Key Number / vendorKeyId'**
  String get keyWizardKeyNumber;

  /// No description provided for @keyWizardKeyNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'Vendor number cannot be edited while editing'**
  String get keyWizardKeyNumberHelper;

  /// No description provided for @keyWizardKeyType.
  ///
  /// In en, this message translates to:
  /// **'Key Type'**
  String get keyWizardKeyType;

  /// No description provided for @keyWizardOwnerId.
  ///
  /// In en, this message translates to:
  /// **'Owner User ID'**
  String get keyWizardOwnerId;

  /// No description provided for @keyWizardOwnerIdHelper.
  ///
  /// In en, this message translates to:
  /// **'Only indicates custodian, not unlock permission'**
  String get keyWizardOwnerIdHelper;

  /// No description provided for @keyWizardStatus.
  ///
  /// In en, this message translates to:
  /// **'Key Status'**
  String get keyWizardStatus;

  /// No description provided for @keyWizardKeyNumberSummary.
  ///
  /// In en, this message translates to:
  /// **'Key Number'**
  String get keyWizardKeyNumberSummary;

  /// No description provided for @keyWizardTypeSummary.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get keyWizardTypeSummary;

  /// No description provided for @keyWizardOwnerSummary.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get keyWizardOwnerSummary;

  /// No description provided for @keyWizardStatusSummary.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get keyWizardStatusSummary;

  /// No description provided for @lockWizardCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Lock (Step by step)'**
  String get lockWizardCreateTitle;

  /// No description provided for @lockWizardEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Lock (Step by step)'**
  String get lockWizardEditTitle;

  /// No description provided for @lockWizardFillRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in name, number and location first'**
  String get lockWizardFillRequired;

  /// No description provided for @lockWizardConnectHint.
  ///
  /// In en, this message translates to:
  /// **'Scan key, select MAC, then set it as lock-id collector key.'**
  String get lockWizardConnectHint;

  /// No description provided for @lockWizardPreparingCollector.
  ///
  /// In en, this message translates to:
  /// **'Connecting and preparing collector key...'**
  String get lockWizardPreparingCollector;

  /// No description provided for @lockWizardCollectorReady.
  ///
  /// In en, this message translates to:
  /// **'Collector key is ready, continue and touch target lock with key'**
  String get lockWizardCollectorReady;

  /// No description provided for @lockWizardPrepareFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to prepare collector key'**
  String get lockWizardPrepareFailed;

  /// No description provided for @lockWizardPrepareAction.
  ///
  /// In en, this message translates to:
  /// **'Connect and Set Collector Key'**
  String get lockWizardPrepareAction;

  /// No description provided for @lockWizardStepReadId.
  ///
  /// In en, this message translates to:
  /// **'Read Lock ID'**
  String get lockWizardStepReadId;

  /// No description provided for @lockWizardReadHint.
  ///
  /// In en, this message translates to:
  /// **'Touch target lock with configured key and wait for CMD=19 in onReport.'**
  String get lockWizardReadHint;

  /// No description provided for @lockWizardWaitingReport.
  ///
  /// In en, this message translates to:
  /// **'Waiting lock-id report, please touch lock with key...'**
  String get lockWizardWaitingReport;

  /// No description provided for @lockWizardParseFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to parse lock id from callback'**
  String get lockWizardParseFailed;

  /// No description provided for @lockWizardReadSuccess.
  ///
  /// In en, this message translates to:
  /// **'Lock ID collected'**
  String get lockWizardReadSuccess;

  /// No description provided for @lockWizardReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to collect lock ID'**
  String get lockWizardReadFailed;

  /// No description provided for @lockWizardReadAction.
  ///
  /// In en, this message translates to:
  /// **'Wait and Read Lock ID'**
  String get lockWizardReadAction;

  /// No description provided for @lockWizardLockNumber.
  ///
  /// In en, this message translates to:
  /// **'Lock Number'**
  String get lockWizardLockNumber;

  /// No description provided for @lockWizardLockNumberHelper.
  ///
  /// In en, this message translates to:
  /// **'Vendor lock number cannot be edited while editing'**
  String get lockWizardLockNumberHelper;

  /// No description provided for @lockWizardStepBasic.
  ///
  /// In en, this message translates to:
  /// **'Basic Information'**
  String get lockWizardStepBasic;

  /// No description provided for @lockWizardLockName.
  ///
  /// In en, this message translates to:
  /// **'Lock Name'**
  String get lockWizardLockName;

  /// No description provided for @lockWizardStepStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get lockWizardStepStatus;

  /// No description provided for @lockWizardSwitchState.
  ///
  /// In en, this message translates to:
  /// **'Switch State'**
  String get lockWizardSwitchState;

  /// No description provided for @lockWizardStepLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get lockWizardStepLocation;

  /// No description provided for @lockWizardLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get lockWizardLocation;

  /// No description provided for @lockWizardLockNameSummary.
  ///
  /// In en, this message translates to:
  /// **'Lock Name'**
  String get lockWizardLockNameSummary;

  /// No description provided for @lockWizardLockNumberSummary.
  ///
  /// In en, this message translates to:
  /// **'Lock Number'**
  String get lockWizardLockNumberSummary;

  /// No description provided for @lockWizardLocationSummary.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get lockWizardLocationSummary;

  /// No description provided for @lockWizardSwitchStateSummary.
  ///
  /// In en, this message translates to:
  /// **'Switch State'**
  String get lockWizardSwitchStateSummary;

  /// No description provided for @keyStatusActive.
  ///
  /// In en, this message translates to:
  /// **'normal'**
  String get keyStatusActive;

  /// No description provided for @listUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Updated At'**
  String get listUpdatedAt;

  /// No description provided for @lockStateLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get lockStateLocked;

  /// No description provided for @lockStateUnlocked.
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get lockStateUnlocked;

  /// No description provided for @lockCardTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap card to open lock control'**
  String get lockCardTapHint;

  /// No description provided for @lockControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Lock Control'**
  String get lockControlTitle;

  /// No description provided for @lockControlSelectMacFirst.
  ///
  /// In en, this message translates to:
  /// **'Please scan and select key MAC first'**
  String get lockControlSelectMacFirst;

  /// No description provided for @lockControlUnlockSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Unlock command submitted'**
  String get lockControlUnlockSubmitted;

  /// No description provided for @lockControlLockSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Lock command submitted'**
  String get lockControlLockSubmitted;

  /// No description provided for @lockControlFailed.
  ///
  /// In en, this message translates to:
  /// **'Control failed'**
  String get lockControlFailed;

  /// No description provided for @lockControlCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get lockControlCurrentStatus;

  /// No description provided for @lockControlSdkConfig.
  ///
  /// In en, this message translates to:
  /// **'SDK Control Configuration'**
  String get lockControlSdkConfig;

  /// No description provided for @lockControlKeyCount.
  ///
  /// In en, this message translates to:
  /// **'{count} keys'**
  String lockControlKeyCount(Object count);

  /// No description provided for @lockControlStopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop Scan'**
  String get lockControlStopScan;

  /// No description provided for @lockControlKeyMac.
  ///
  /// In en, this message translates to:
  /// **'Key MAC'**
  String get lockControlKeyMac;

  /// No description provided for @lockControlUnlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockControlUnlockAction;

  /// No description provided for @lockControlLockAction.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get lockControlLockAction;
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
