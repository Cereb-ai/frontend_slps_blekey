// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Smart Lock';

  @override
  String get smartLockPlatform => 'Smart Lock Platform';

  @override
  String get smartLockPlatformSub => 'Plattform fur intelligente Schliesse';

  @override
  String get usernameOrEmail => 'Benutzername / E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get pleaseInputUsername => 'Bitte Benutzernamen eingeben';

  @override
  String get pleaseInputPassword => 'Bitte Passwort eingeben';

  @override
  String get rememberMe => 'Angemeldet bleiben';

  @override
  String get login => 'Anmelden';

  @override
  String get language => 'Sprache';

  @override
  String get my => 'Ich';

  @override
  String get keysManagement => 'Schlussel';

  @override
  String get locksManagement => 'Schlosser';

  @override
  String get account => 'Konto';

  @override
  String get version => 'Version';

  @override
  String get currentTestHome => 'Aktuelle Testseite';

  @override
  String get vendorSdkTest => 'Hersteller-SDK-Test';

  @override
  String get onlineSwitchLock => 'Online Schliessen/Offnen';

  @override
  String get keepOriginalTestFlow => 'Ursprunglichen Testablauf beibehalten';

  @override
  String get logout => 'Abmelden';

  @override
  String get confirmLogout => 'Mochten Sie sich wirklich abmelden?';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get delete => 'Loschen';

  @override
  String get deleteKeyTitle => 'Schlussel loschen';

  @override
  String get deleteLockTitle => 'Schloss loschen';

  @override
  String confirmDeleteItem(Object name) {
    return 'Mochten Sie $name wirklich loschen?';
  }

  @override
  String get logoutAction => 'Abmelden';

  @override
  String get cannotOpenCerebSite => 'Cereb.AI-Website kann nicht geoffnet werden';

  @override
  String get poweredBy => 'powered by';

  @override
  String get searchKeyHint => 'Schlusselname/-nummer suchen';

  @override
  String get searchLockHint => 'Schlossname/-nummer/Ort suchen';

  @override
  String get sessionExpired => 'Sitzung abgelaufen, bitte erneut anmelden';

  @override
  String get keyCreatedSuccess => 'Schlüssel erfolgreich erstellt';

  @override
  String get keyCreateFailed => 'Fehler beim Erstellen des Schlüssels';

  @override
  String get lockCreatedSuccess => 'Schloss erfolgreich erstellt';

  @override
  String get lockCreateFailed => 'Fehler beim Erstellen des Schlosses';
  @override
  String get smartListEmpty => 'Keine Daten';

  @override
  String get smartListLoading => 'Wird geladen...';

  @override
  String get smartListNoMore => 'Keine weiteren Daten';

  @override
  String get unnamedDevice => 'Unbenannt';

  @override
  String get wizardConfirmStep => 'Bestatigen';

  @override
  String get keyWizardCreateTitle => 'Schlussel erstellen (Schrittweise)';

  @override
  String get keyWizardEditTitle => 'Schlussel bearbeiten (Schrittweise)';

  @override
  String get keyWizardFillRequired => 'Bitte zuerst Name und Nummer eingeben';

  @override
  String get keyWizardSave => 'Speichern';

  @override
  String get keyWizardNext => 'Weiter';

  @override
  String get keyWizardPrevious => 'Zuruck';

  @override
  String get keyWizardStepConnect => 'Gerat verbinden';

  @override
  String get keyWizardConnectHint => 'Schlussel scannen, MAC auswahlen, dann verbinden und Schlusselinfo lesen.';

  @override
  String get keyWizardScanning => 'Schlussel werden gescannt...';

  @override
  String get keyWizardScanStarted => 'Scan gestartet, bitte auf Aktualisierung der Gerateliste warten';

  @override
  String get keyWizardScanningShort => 'Scan lauft';

  @override
  String get keyWizardScanKey => 'Schlussel scannen';

  @override
  String get keyWizardReadingInfo => 'Verbinden und Schlusselinfo lesen...';

  @override
  String get keyWizardReadSuccess => 'Schlusselinfo gelesen';

  @override
  String get keyWizardReadFailed => 'Schlusselinfo konnte nicht gelesen werden';

  @override
  String get keyWizardReadAction => 'Verbinden und Schlusselinfo lesen';

  @override
  String get keyWizardStepInfo => 'Informationen ausfullen';

  @override
  String get keyWizardKeyName => 'Schlusselname';

  @override
  String get keyWizardKeyNumber => 'Schlusselnummer / vendorKeyId';

  @override
  String get keyWizardKeyNumberHelper => 'Herstellernummer kann beim Bearbeiten nicht geandert werden';

  @override
  String get keyWizardKeyType => 'Schlusseltyp';

  @override
  String get keyWizardOwnerId => 'Besitzer-ID';

  @override
  String get keyWizardOwnerIdHelper => 'Nur Verwahrer, keine Entriegelungsberechtigung';

  @override
  String get keyWizardStatus => 'Schlusselstatus';

  @override
  String get keyWizardKeyNumberSummary => 'Schlusselnummer';

  @override
  String get keyWizardTypeSummary => 'Typ';

  @override
  String get keyWizardOwnerSummary => 'Besitzer';

  @override
  String get keyWizardStatusSummary => 'Status';

  @override
  String get lockWizardCreateTitle => 'Schloss erstellen (Schrittweise)';

  @override
  String get lockWizardEditTitle => 'Schloss bearbeiten (Schrittweise)';

  @override
  String get lockWizardFillRequired => 'Bitte zuerst Name, Nummer und Ort eingeben';

  @override
  String get lockWizardConnectHint => 'Schlussel scannen, MAC auswahlen, dann als Lock-ID-Sammler setzen.';

  @override
  String get lockWizardPreparingCollector => 'Verbinden und Sammlerschlussel vorbereiten...';

  @override
  String get lockWizardCollectorReady => 'Sammlerschlussel bereit, im nachsten Schritt Schloss beruhren';

  @override
  String get lockWizardPrepareFailed => 'Sammlerschlussel konnte nicht vorbereitet werden';

  @override
  String get lockWizardPrepareAction => 'Verbinden und Sammlerschlussel setzen';

  @override
  String get lockWizardStepReadId => 'Lock-ID lesen';

  @override
  String get lockWizardReadHint => 'Schloss mit konfiguriertem Schlussel beruhren und auf CMD=19 in onReport warten.';

  @override
  String get lockWizardWaitingReport => 'Warte auf Lock-ID-Report, bitte Schloss beruhren...';

  @override
  String get lockWizardParseFailed => 'Lock-ID konnte aus Callback nicht gelesen werden';

  @override
  String get lockWizardReadSuccess => 'Lock-ID erfasst';

  @override
  String get lockWizardReadFailed => 'Lock-ID konnte nicht erfasst werden';

  @override
  String get lockWizardReadAction => 'Warten und Lock-ID lesen';

  @override
  String get lockWizardLockNumber => 'Schlossnummer';

  @override
  String get lockWizardLockNumberHelper => 'Hersteller-Schlossnummer kann beim Bearbeiten nicht geandert werden';

  @override
  String get lockWizardStepBasic => 'Grundinformationen';

  @override
  String get lockWizardLockName => 'Schlossname';

  @override
  String get lockWizardStepStatus => 'Status';

  @override
  String get lockWizardSwitchState => 'Schaltzustand';

  @override
  String get lockWizardStepLocation => 'Ort';

  @override
  String get lockWizardLocation => 'Ort';

  @override
  String get lockWizardLockNameSummary => 'Schlossname';

  @override
  String get lockWizardLockNumberSummary => 'Schlossnummer';

  @override
  String get lockWizardLocationSummary => 'Ort';

  @override
  String get lockWizardSwitchStateSummary => 'Schaltzustand';

  @override
  String get keyStatusActive => 'Normal';

  @override
  String get listUpdatedAt => 'Aktualisiert am';

  @override
  String get lockStateLocked => 'Verriegelt';

  @override
  String get lockStateUnlocked => 'Entriegelt';

  @override
  String get lockCardTapHint => 'Zum Sperrsteuerungsbildschirm tippen';

  @override
  String get lockControlTitle => 'Schlosssteuerung';

  @override
  String get lockControlSelectMacFirst => 'Bitte zuerst Schlussel-MAC scannen und auswahlen';

  @override
  String get lockControlUnlockSubmitted => 'Entriegelungsbefehl gesendet';

  @override
  String get lockControlLockSubmitted => 'Verriegelungsbefehl gesendet';

  @override
  String get lockControlFailed => 'Steuerung fehlgeschlagen';

  @override
  String get lockControlCurrentStatus => 'Aktueller Status';

  @override
  String get lockControlSdkConfig => 'SDK-Steuerungskonfiguration';

  @override
  String lockControlKeyCount(Object count) {
    return '$count Schlussel';
  }

  @override
  String get lockControlStopScan => 'Scan stoppen';

  @override
  String get lockControlKeyMac => 'Schlussel-MAC';

  @override
  String get lockControlUnlockAction => 'Entriegeln';

  @override
  String get lockControlLockAction => 'Verriegeln';
}
