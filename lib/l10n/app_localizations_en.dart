// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Hi Secure';

  @override
  String get securingPasswords => 'Securing your passwords...';

  @override
  String get authenticateNow => 'Authenticate Now';

  @override
  String get pressToUnlock => 'Press the authenticate button to unlock the app';

  @override
  String get authentication => 'Authentication';

  @override
  String get preparingAuthentication => 'Preparing authentication...';

  @override
  String get systemWillChoose =>
      'The system will automatically choose the appropriate authentication method';

  @override
  String get authenticationSuccess => 'Authentication successful!';

  @override
  String get authenticationFailed => 'Authentication failed or not set up';

  @override
  String get error => 'Error';

  @override
  String get loggedOut => 'Logged out';

  @override
  String get apps => 'Apps';

  @override
  String get noAppsYet => 'No apps yet';

  @override
  String get tapToAddFirst => 'Tap the + button to add your first app';

  @override
  String get noUrlConfigured => 'No URL configured';

  @override
  String get editApp => 'Edit App';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get securitySettings => 'Security Settings';

  @override
  String get managePasscodeAuth => 'Manage your passcode and authentication';

  @override
  String get changePasscode => 'Change Passcode';

  @override
  String get updatePasscode => 'Update your 6-digit passcode';

  @override
  String get passcodeChanged => 'Passcode changed successfully!';

  @override
  String get biometricAuthentication => 'Biometric Authentication';

  @override
  String get useFingerprintFaceId => 'Use fingerprint or face ID';

  @override
  String get biometricEnabled => 'Biometric enabled successfully!';

  @override
  String get failedToEnableBiometric => 'Failed to enable biometric';

  @override
  String get biometricDisabled => 'Biometric disabled';

  @override
  String get backupRestore => 'Backup & Restore';

  @override
  String get exportImportData => 'Export and import your data';

  @override
  String get exportData => 'Export Data';

  @override
  String get backupPasswordsSecurely => 'Backup your passwords securely';

  @override
  String get importData => 'Import Data';

  @override
  String get restoreFromBackup => 'Restore from backup';

  @override
  String get about => 'About';

  @override
  String get appInformationHelp => 'App information and help';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get getHelpWithApp => 'Get help with the app';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get readPrivacyPolicy => 'Read our privacy policy';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get readTermsOfService => 'Read our terms of service';

  @override
  String get exportDataDescription =>
      'Enter a password to encrypt your backup file. This password will be required to restore your data.';

  @override
  String get importDataDescription =>
      'Select a backup file and enter the password used to encrypt it.';

  @override
  String get language => 'Language';

  @override
  String get selectLanguage => 'Select your preferred language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';
}
