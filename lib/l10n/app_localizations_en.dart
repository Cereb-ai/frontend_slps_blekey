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
}
