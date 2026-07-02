// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Smart Lock';

  @override
  String get smartLockPlatform => 'Smart Lock Platform';

  @override
  String get smartLockPlatformSub => 'Smart Lock Management';

  @override
  String get usernameOrEmail => 'Username / Email';

  @override
  String get password => 'Password';

  @override
  String get pleaseInputUsername => 'Please enter username';

  @override
  String get pleaseInputPassword => 'Please enter password';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get login => 'Log in';

  @override
  String get language => 'Language';

  @override
  String get my => 'Me';

  @override
  String get keysManagement => 'Keys';

  @override
  String get locksManagement => 'Locks';

  @override
  String get account => 'Account';

  @override
  String get version => 'Version';

  @override
  String get currentTestHome => 'Current Test Home';

  @override
  String get vendorSdkTest => 'Vendor SDK Test';

  @override
  String get onlineSwitchLock => 'Online Switch-Lock';

  @override
  String get keepOriginalTestFlow => 'Keep original test flow';

  @override
  String get logout => 'Log out';

  @override
  String get confirmLogout => 'Are you sure you want to log out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get deleteKeyTitle => 'Delete key';

  @override
  String get deleteLockTitle => 'Delete lock';

  @override
  String confirmDeleteItem(Object name) {
    return 'Are you sure you want to delete $name?';
  }

  @override
  String get logoutAction => 'Log out';

  @override
  String get cannotOpenCerebSite => 'Unable to open Cereb.AI website';

  @override
  String get poweredBy => 'powered by';

  @override
  String get searchKeyHint => 'Search key name/number';

  @override
  String get searchLockHint => 'Search lock name/number/location';

  @override
  String get sessionExpired => 'Session expired, please log in again';

  @override
  String get keyCreatedSuccess => 'Key created successfully';

  @override
  String get keyCreateFailed => 'Failed to create key';

  @override
  String get lockCreatedSuccess => 'Lock created successfully';

  @override
  String get lockCreateFailed => 'Failed to create lock';

  @override
  String get smartListEmpty => 'No data';

  @override
  String get smartListLoading => 'Loading...';

  @override
  String get smartListNoMore => 'No more data';

  @override
  String get unnamedDevice => 'Unnamed';

  @override
  String get wizardConfirmStep => 'Confirm';

  @override
  String get keyWizardCreateTitle => 'Create Key (Step by step)';

  @override
  String get keyWizardEditTitle => 'Edit Key (Step by step)';

  @override
  String get keyWizardFillRequired => 'Please fill in name and number first';

  @override
  String get keyWizardSave => 'Save';

  @override
  String get keyWizardNext => 'Next';

  @override
  String get keyWizardPrevious => 'Previous';

  @override
  String get keyWizardStepConnect => 'Connect Device';

  @override
  String get keyWizardConnectHint =>
      'Scan key, select MAC, then connect and read key info.';

  @override
  String get keyWizardScanning => 'Scanning keys...';

  @override
  String get keyWizardScanStarted =>
      'Scan started, waiting for device list to refresh';

  @override
  String get keyWizardScanningShort => 'Scanning';

  @override
  String get keyWizardScanKey => 'Scan Key';

  @override
  String get keyWizardReadingInfo => 'Connecting and reading key info...';

  @override
  String get keyWizardReadSuccess => 'Key info read';

  @override
  String get keyWizardReadFailed => 'Failed to read key info';

  @override
  String get keyWizardReadAction => 'Connect and Read Key Info';

  @override
  String get keyWizardStepInfo => 'Fill Information';

  @override
  String get keyWizardKeyName => 'Key Name';

  @override
  String get keyWizardKeyNumber => 'Key Number / vendorKeyId';

  @override
  String get keyWizardKeyNumberHelper =>
      'Vendor number cannot be edited while editing';

  @override
  String get keyWizardKeyType => 'Key Type';

  @override
  String get keyWizardOwnerId => 'Owner User ID';

  @override
  String get keyWizardOwnerIdHelper =>
      'Only indicates custodian, not unlock permission';

  @override
  String get keyWizardStatus => 'Key Status';

  @override
  String get keyWizardKeyNumberSummary => 'Key Number';

  @override
  String get keyWizardTypeSummary => 'Type';

  @override
  String get keyWizardOwnerSummary => 'Owner';

  @override
  String get keyWizardStatusSummary => 'Status';

  @override
  String get lockWizardCreateTitle => 'Create Lock (Step by step)';

  @override
  String get lockWizardEditTitle => 'Edit Lock (Step by step)';

  @override
  String get lockWizardFillRequired =>
      'Please fill in name, number and location first';

  @override
  String get lockWizardConnectHint =>
      'Scan key, select MAC, then set it as lock-id collector key.';

  @override
  String get lockWizardPreparingCollector =>
      'Connecting and preparing collector key...';

  @override
  String get lockWizardCollectorReady =>
      'Collector key is ready, continue and touch target lock with key';

  @override
  String get lockWizardPrepareFailed => 'Failed to prepare collector key';

  @override
  String get lockWizardPrepareAction => 'Connect and Set Collector Key';

  @override
  String get lockWizardStepReadId => 'Read Lock ID';

  @override
  String get lockWizardReadHint =>
      'Touch target lock with configured key and wait for CMD=19 in onReport.';

  @override
  String get lockWizardWaitingReport =>
      'Waiting lock-id report, please touch lock with key...';

  @override
  String get lockWizardParseFailed => 'Failed to parse lock id from callback';

  @override
  String get lockWizardReadSuccess => 'Lock ID collected';

  @override
  String get lockWizardReadFailed => 'Failed to collect lock ID';

  @override
  String get lockWizardReadAction => 'Wait and Read Lock ID';

  @override
  String get lockWizardLockNumber => 'Lock Number';

  @override
  String get lockWizardLockNumberHelper =>
      'Vendor lock number cannot be edited while editing';

  @override
  String get lockWizardStepBasic => 'Basic Information';

  @override
  String get lockWizardLockName => 'Lock Name';

  @override
  String get lockWizardStepStatus => 'Status';

  @override
  String get lockWizardSwitchState => 'Switch State';

  @override
  String get lockWizardStepLocation => 'Location';

  @override
  String get lockWizardLocation => 'Location';

  @override
  String get lockWizardLockNameSummary => 'Lock Name';

  @override
  String get lockWizardLockNumberSummary => 'Lock Number';

  @override
  String get lockWizardLocationSummary => 'Location';

  @override
  String get lockWizardSwitchStateSummary => 'Switch State';

  @override
  String get keyStatusActive => 'normal';

  @override
  String get listUpdatedAt => 'Updated At';

  @override
  String get lockStateLocked => 'Locked';

  @override
  String get lockStateUnlocked => 'Unlocked';

  @override
  String get keyCardTapHint => 'Tap key card to open online unlock';

  @override
  String get keyUnlockTitle => 'Key Unlock';

  @override
  String get keyUnlockSelectMacFirst => 'Please scan and select key MAC first';

  @override
  String get keyUnlockUnlockSubmitted => 'Unlock command submitted';

  @override
  String get keyUnlockLockSubmitted => 'Lock command submitted';

  @override
  String get keyUnlockFailed => 'Control failed';

  @override
  String get keyUnlockCurrentStatus => 'Current Status';

  @override
  String get keyUnlockSdkConfig => 'SDK Control Configuration';

  @override
  String keyUnlockKeyCount(Object count) {
    return '$count keys';
  }

  @override
  String get keyUnlockStopScan => 'Stop Scan';

  @override
  String get keyUnlockKeyMac => 'Key MAC';

  @override
  String get keyUnlockUnlockAction => 'Unlock';

  @override
  String get keyUnlockLockAction => 'Lock';

  @override
  String get keyUnlockPickLock => 'Pick target lock';

  @override
  String get keyUnlockSelectedLock => 'Target Lock';

  @override
  String get keyUnlockPickLockHint => 'Tap a lock below to choose the target';

  @override
  String get keyUnlockNoLockSelected => 'Please pick a target lock first';

  @override
  String get keyUnlockNoLockAvailable => 'No locks available';

  @override
  String get keyUnlockLoadingLocks => 'Loading locks...';

  @override
  String get keyUnlockTargetLockSection => 'Target Lock';

  @override
  String get keyUnlockKeyMacReadonly => 'Bound Key MAC';

  @override
  String get keyUnlockConnectionSection => 'Key Connection';

  @override
  String get keyUnlockScanningKey => 'Scanning for key…';

  @override
  String get keyUnlockConnectingKey => 'Connecting to key…';

  @override
  String get keyUnlockKeyConnected => 'Key connected';

  @override
  String get keyUnlockKeyConnectFailed =>
      'Key not found or connection failed. Keep the key nearby and retry.';

  @override
  String get keyUnlockRetryConnect => 'Scan and connect again';

  @override
  String get keyUnlockKeyNotConnected =>
      'Key is not connected yet. Please wait for auto-connect.';

  @override
  String get keyUnlockAuthDenied => 'Authorization denied';

  @override
  String get clearanceTitle => 'Clearance';

  @override
  String get clearanceDetailTitle => 'Group Clearance';

  @override
  String get clearanceEmpty => 'No group clearance tasks assigned to you';

  @override
  String get clearanceRetry => 'Retry';

  @override
  String clearanceProgress(Object cleared, Object required) {
    return '$cleared/$required cleared';
  }

  @override
  String clearanceUnlockBlocked(Object count) {
    return 'UNLOCK BLOCKED — $count workers still protected';
  }

  @override
  String get clearanceReady => 'Ready';

  @override
  String get clearanceActive => 'Active';

  @override
  String get clearancePending => 'Pending';

  @override
  String get clearanceWorkerList => 'Workers';

  @override
  String clearanceYou(Object userId) {
    return 'You ($userId)';
  }

  @override
  String get clearanceStatusPending => 'Still Working';

  @override
  String get clearanceStatusCleared => 'Cleared';

  @override
  String get clearanceStatusBlocked => 'Blocked';

  @override
  String get clearanceClearAction => 'Clear / Ready for Release';

  @override
  String get clearanceBlockAction => 'Still Working';

  @override
  String get clearanceClearedSuccess => 'Marked as cleared';

  @override
  String get clearanceBlockedSuccess => 'Marked as still working';

  @override
  String get clearanceAllReady => 'All workers cleared — unlock allowed';

  @override
  String clearanceExpireAt(Object time) {
    return 'Expires at $time';
  }

  @override
  String get clearanceBlockedDialogTitle => 'Unlock Blocked';

  @override
  String clearanceBlockedDialogBody(Object reasons) {
    return 'Group clearance is not complete: $reasons';
  }

  @override
  String get clearanceGoToTasks => 'Go to Clearance';
}
