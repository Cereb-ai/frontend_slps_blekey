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

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @renameKeyTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Key'**
  String get renameKeyTitle;

  /// No description provided for @renameLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename Lock'**
  String get renameLockTitle;

  /// No description provided for @renameSuccess.
  ///
  /// In en, this message translates to:
  /// **'Name updated successfully'**
  String get renameSuccess;

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

  /// No description provided for @keyCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Key created successfully'**
  String get keyCreatedSuccess;

  /// No description provided for @keyCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create key'**
  String get keyCreateFailed;

  /// No description provided for @lockCreatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Lock created successfully'**
  String get lockCreatedSuccess;

  /// No description provided for @lockCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to create lock'**
  String get lockCreateFailed;

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

  /// No description provided for @keyAdvancedConnectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Advanced connection settings'**
  String get keyAdvancedConnectionSettings;

  /// No description provided for @keyAdvancedConnectionSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'Set sign, lic, and secret before connecting. sign=0 is sent as numeric 0.'**
  String get keyAdvancedConnectionSettingsHint;

  /// No description provided for @keyAdvancedUnlockSettingsHint.
  ///
  /// In en, this message translates to:
  /// **'These parameters are used for this connection and unlock operation.'**
  String get keyAdvancedUnlockSettingsHint;

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

  /// No description provided for @keyCardTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap key card to open online unlock'**
  String get keyCardTapHint;

  /// No description provided for @keyUnlockTitle.
  ///
  /// In en, this message translates to:
  /// **'Key Unlock'**
  String get keyUnlockTitle;

  /// No description provided for @keyUnlockSelectMacFirst.
  ///
  /// In en, this message translates to:
  /// **'Please scan and select key MAC first'**
  String get keyUnlockSelectMacFirst;

  /// No description provided for @keyUnlockUnlockSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Unlock command submitted'**
  String get keyUnlockUnlockSubmitted;

  /// No description provided for @keyUnlockLockSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Lock command submitted'**
  String get keyUnlockLockSubmitted;

  /// No description provided for @keyUnlockFailed.
  ///
  /// In en, this message translates to:
  /// **'Control failed'**
  String get keyUnlockFailed;

  /// No description provided for @keyUnlockTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Operation timed out. Press and hold the key button until the green light starts flashing, then scan and connect again.'**
  String get keyUnlockTimedOut;

  /// No description provided for @keyUnlockCurrentStatus.
  ///
  /// In en, this message translates to:
  /// **'Current Status'**
  String get keyUnlockCurrentStatus;

  /// No description provided for @keyUnlockSdkConfig.
  ///
  /// In en, this message translates to:
  /// **'SDK Control Configuration'**
  String get keyUnlockSdkConfig;

  /// No description provided for @keyUnlockKeyCount.
  ///
  /// In en, this message translates to:
  /// **'{count} keys'**
  String keyUnlockKeyCount(Object count);

  /// No description provided for @keyUnlockStopScan.
  ///
  /// In en, this message translates to:
  /// **'Stop Scan'**
  String get keyUnlockStopScan;

  /// No description provided for @keyUnlockKeyMac.
  ///
  /// In en, this message translates to:
  /// **'Key MAC'**
  String get keyUnlockKeyMac;

  /// No description provided for @keyUnlockUnlockAction.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get keyUnlockUnlockAction;

  /// No description provided for @keyUnlockLockAction.
  ///
  /// In en, this message translates to:
  /// **'Lock'**
  String get keyUnlockLockAction;

  /// No description provided for @keyUnlockPickLock.
  ///
  /// In en, this message translates to:
  /// **'Pick target lock'**
  String get keyUnlockPickLock;

  /// No description provided for @keyUnlockSelectedLock.
  ///
  /// In en, this message translates to:
  /// **'Target Lock'**
  String get keyUnlockSelectedLock;

  /// No description provided for @keyUnlockPickLockHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a lock below to choose the target'**
  String get keyUnlockPickLockHint;

  /// No description provided for @keyUnlockNoLockSelected.
  ///
  /// In en, this message translates to:
  /// **'Please pick a target lock first'**
  String get keyUnlockNoLockSelected;

  /// No description provided for @keyUnlockNoLockAvailable.
  ///
  /// In en, this message translates to:
  /// **'No locks available'**
  String get keyUnlockNoLockAvailable;

  /// No description provided for @keyUnlockLoadingLocks.
  ///
  /// In en, this message translates to:
  /// **'Loading locks...'**
  String get keyUnlockLoadingLocks;

  /// No description provided for @keyUnlockTargetLockSection.
  ///
  /// In en, this message translates to:
  /// **'Target Lock'**
  String get keyUnlockTargetLockSection;

  /// No description provided for @keyUnlockKeyMacReadonly.
  ///
  /// In en, this message translates to:
  /// **'Bound Key MAC'**
  String get keyUnlockKeyMacReadonly;

  /// No description provided for @keyUnlockConnectionSection.
  ///
  /// In en, this message translates to:
  /// **'Key Connection'**
  String get keyUnlockConnectionSection;

  /// No description provided for @keyUnlockScanningKey.
  ///
  /// In en, this message translates to:
  /// **'Scanning for key… Press and hold the key button until the green light starts flashing.'**
  String get keyUnlockScanningKey;

  /// No description provided for @keyUnlockConnectingKey.
  ///
  /// In en, this message translates to:
  /// **'Connecting to key…'**
  String get keyUnlockConnectingKey;

  /// No description provided for @keyUnlockKeyConnected.
  ///
  /// In en, this message translates to:
  /// **'Key connected'**
  String get keyUnlockKeyConnected;

  /// No description provided for @keyUnlockKeyConnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Bluetooth key not found or connection failed. Press and hold the key button until the green light starts flashing, then scan again. If the light has turned off, press and hold again to wake the key.'**
  String get keyUnlockKeyConnectFailed;

  /// No description provided for @keyUnlockRetryConnect.
  ///
  /// In en, this message translates to:
  /// **'Scan and connect again'**
  String get keyUnlockRetryConnect;

  /// No description provided for @keyUnlockReadyToConnect.
  ///
  /// In en, this message translates to:
  /// **'Press and hold the key button until the green light starts flashing, then scan and connect.'**
  String get keyUnlockReadyToConnect;

  /// No description provided for @keyUnlockConnectAction.
  ///
  /// In en, this message translates to:
  /// **'Scan and connect'**
  String get keyUnlockConnectAction;

  /// No description provided for @keyUnlockKeyNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Key is not connected yet. Please wait for auto-connect.'**
  String get keyUnlockKeyNotConnected;

  /// No description provided for @keyUnlockAuthDenied.
  ///
  /// In en, this message translates to:
  /// **'Authorization denied'**
  String get keyUnlockAuthDenied;

  /// No description provided for @clearanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Clearance'**
  String get clearanceTitle;

  /// No description provided for @clearanceDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Clearance'**
  String get clearanceDetailTitle;

  /// No description provided for @clearanceEmpty.
  ///
  /// In en, this message translates to:
  /// **'No group clearance tasks assigned to you'**
  String get clearanceEmpty;

  /// No description provided for @clearanceRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get clearanceRetry;

  /// No description provided for @clearanceProgress.
  ///
  /// In en, this message translates to:
  /// **'{cleared}/{required} cleared'**
  String clearanceProgress(Object cleared, Object required);

  /// No description provided for @clearanceUnlockBlocked.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK BLOCKED — {count} workers still protected'**
  String clearanceUnlockBlocked(Object count);

  /// No description provided for @clearanceReady.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get clearanceReady;

  /// No description provided for @clearanceActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get clearanceActive;

  /// No description provided for @clearancePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get clearancePending;

  /// No description provided for @clearanceWorkerList.
  ///
  /// In en, this message translates to:
  /// **'Workers'**
  String get clearanceWorkerList;

  /// No description provided for @clearanceYou.
  ///
  /// In en, this message translates to:
  /// **'You ({userId})'**
  String clearanceYou(Object userId);

  /// No description provided for @clearanceStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Still Working'**
  String get clearanceStatusPending;

  /// No description provided for @clearanceStatusCleared.
  ///
  /// In en, this message translates to:
  /// **'Cleared'**
  String get clearanceStatusCleared;

  /// No description provided for @clearanceStatusBlocked.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get clearanceStatusBlocked;

  /// No description provided for @clearanceClearAction.
  ///
  /// In en, this message translates to:
  /// **'Clear / Ready for Release'**
  String get clearanceClearAction;

  /// No description provided for @clearanceBlockAction.
  ///
  /// In en, this message translates to:
  /// **'Still Working'**
  String get clearanceBlockAction;

  /// No description provided for @clearanceClearedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Marked as cleared'**
  String get clearanceClearedSuccess;

  /// No description provided for @clearanceBlockedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Marked as still working'**
  String get clearanceBlockedSuccess;

  /// No description provided for @clearanceAllReady.
  ///
  /// In en, this message translates to:
  /// **'All workers cleared — unlock allowed'**
  String get clearanceAllReady;

  /// No description provided for @clearanceExpireAt.
  ///
  /// In en, this message translates to:
  /// **'Expires at {time}'**
  String clearanceExpireAt(Object time);

  /// No description provided for @clearanceBlockedDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock Blocked'**
  String get clearanceBlockedDialogTitle;

  /// No description provided for @clearanceBlockedDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Group clearance is not complete: {reasons}'**
  String clearanceBlockedDialogBody(Object reasons);

  /// No description provided for @clearanceGoToTasks.
  ///
  /// In en, this message translates to:
  /// **'Go to Clearance'**
  String get clearanceGoToTasks;

  /// No description provided for @tasksTitle.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasksTitle;

  /// No description provided for @tasksEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get tasksEmpty;

  /// No description provided for @taskTypeTimeWindow.
  ///
  /// In en, this message translates to:
  /// **'Time-window task'**
  String get taskTypeTimeWindow;

  /// No description provided for @taskTypeSequentialUnlock.
  ///
  /// In en, this message translates to:
  /// **'Sequential unlock task'**
  String get taskTypeSequentialUnlock;

  /// No description provided for @taskTypeJointClearance.
  ///
  /// In en, this message translates to:
  /// **'Group clearance task'**
  String get taskTypeJointClearance;

  /// No description provided for @taskOperationLock.
  ///
  /// In en, this message translates to:
  /// **'lock'**
  String get taskOperationLock;

  /// No description provided for @taskOperationUnlock.
  ///
  /// In en, this message translates to:
  /// **'unlock'**
  String get taskOperationUnlock;

  /// No description provided for @taskConfirmOperationTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm {operation} completion'**
  String taskConfirmOperationTitle(Object operation);

  /// No description provided for @taskConfirmOperationBody.
  ///
  /// In en, this message translates to:
  /// **'Confirm that you have completed the {operation} operation on “{lockName}”. The server will validate {validationScope} and the time window.'**
  String taskConfirmOperationBody(Object lockName, Object operation, Object validationScope);

  /// No description provided for @taskValidationStep.
  ///
  /// In en, this message translates to:
  /// **'this step'**
  String get taskValidationStep;

  /// No description provided for @taskValidationSequence.
  ///
  /// In en, this message translates to:
  /// **'the task sequence'**
  String get taskValidationSequence;

  /// No description provided for @taskConfirmComplete.
  ///
  /// In en, this message translates to:
  /// **'Confirm completion'**
  String get taskConfirmComplete;

  /// No description provided for @taskStepCompleted.
  ///
  /// In en, this message translates to:
  /// **'Step completed'**
  String get taskStepCompleted;

  /// No description provided for @taskWindowExpiredTitle.
  ///
  /// In en, this message translates to:
  /// **'The current {operation} time window has ended'**
  String taskWindowExpiredTitle(Object operation);

  /// No description provided for @taskWindowNotStartedTitle.
  ///
  /// In en, this message translates to:
  /// **'The current {operation} time window has not started'**
  String taskWindowNotStartedTitle(Object operation);

  /// No description provided for @taskWindowExpiredDescription.
  ///
  /// In en, this message translates to:
  /// **'This step is past its allowed operation time. Contact an administrator to adjust the schedule or recreate the task.'**
  String get taskWindowExpiredDescription;

  /// No description provided for @taskWindowNotStartedDescription.
  ///
  /// In en, this message translates to:
  /// **'Perform this step during its allowed time window.'**
  String get taskWindowNotStartedDescription;

  /// No description provided for @taskAllowedOperationTime.
  ///
  /// In en, this message translates to:
  /// **'Allowed operation time'**
  String get taskAllowedOperationTime;

  /// No description provided for @taskGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get taskGotIt;

  /// No description provided for @taskNotFound.
  ///
  /// In en, this message translates to:
  /// **'Task not found'**
  String get taskNotFound;

  /// No description provided for @taskCompleteOperation.
  ///
  /// In en, this message translates to:
  /// **'Complete {operation}'**
  String taskCompleteOperation(Object operation);

  /// No description provided for @taskStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get taskStatusCompleted;

  /// No description provided for @taskStatusExecutable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get taskStatusExecutable;

  /// No description provided for @taskStatusCurrentStep.
  ///
  /// In en, this message translates to:
  /// **'Current step'**
  String get taskStatusCurrentStep;

  /// No description provided for @taskStatusWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get taskStatusWaiting;

  /// No description provided for @taskStatus.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String taskStatus(Object status);

  /// No description provided for @taskNextStep.
  ///
  /// In en, this message translates to:
  /// **'Next: {lockName}'**
  String taskNextStep(Object lockName);

  /// No description provided for @taskStatusPendingExecution.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get taskStatusPendingExecution;

  /// No description provided for @taskStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get taskStatusInProgress;

  /// No description provided for @taskStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get taskStatusCancelled;

  /// No description provided for @taskScheduleCompleted.
  ///
  /// In en, this message translates to:
  /// **'Task completed'**
  String get taskScheduleCompleted;

  /// No description provided for @taskScheduleNoLimit.
  ///
  /// In en, this message translates to:
  /// **'Current step: no time limit'**
  String get taskScheduleNoLimit;

  /// No description provided for @taskScheduleCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current step: {time}'**
  String taskScheduleCurrent(Object time);

  /// No description provided for @taskScheduleOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue: {time}'**
  String taskScheduleOverdue(Object time);

  /// No description provided for @taskScheduleStarts.
  ///
  /// In en, this message translates to:
  /// **'Current step starts: {time}'**
  String taskScheduleStarts(Object time);
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
