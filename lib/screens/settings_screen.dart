import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:hi_secure/l10n/app_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hi_secure/service/auth_service.dart';
import 'package:hi_secure/service/language_service.dart';
import 'package:hi_secure/service/manager_service.dart';
import 'dart:io';
import 'package:file_picker/file_picker.dart';


class SettingsScreen extends StatefulWidget {
  final Function(Locale)? onLocaleChanged;

  const SettingsScreen({Key? key, this.onLocaleChanged}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final storage = FlutterSecureStorage();
  final currentPasscodeController = TextEditingController();
  final newPasscodeController = TextEditingController();
  final confirmPasscodeController = TextEditingController();
  final authService = AuthService();
  bool _biometricEnabled = false;
  Map<String, dynamic> _biometricStatus = {};
  String _currentLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await authService.isBiometricEnabled();
    final status = await authService.getBiometricStatus();
    final passcodeSet = await authService.isPasscodeSet();
    final currentLang = await LanguageService.getCurrentLanguage();

    setState(() {
      _biometricEnabled = enabled;
      _biometricStatus = status;
      // Add passcode status to the map for display
      _biometricStatus['passcodeSet'] = passcodeSet;
      _currentLanguage = currentLang;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    final l10n = AppLocalizations.of(context)!;

    if (value) {
      // Enable biometric
      final success = await authService.enableBiometricAfterPasscode(context);
      if (success) {
        setState(() {
          _biometricEnabled = true;
        });
        _showTestResult(l10n.biometricEnabled, true);
      } else {
        _showTestResult(l10n.failedToEnableBiometric, false);
      }
    } else {
      // Disable biometric
      await authService.disableBiometric();
      setState(() {
        _biometricEnabled = false;
      });
      _showTestResult(l10n.biometricDisabled, null);
    }
  }

  void _showTestResult(String message, bool? success) {
    Color backgroundColor = Colors.blue;
    if (success == true) backgroundColor = Colors.green;
    if (success == false) backgroundColor = Colors.red;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _showLanguageDialog() {
    final l10n = AppLocalizations.of(context)!;
    final availableLanguages = LanguageService.getAvailableLanguages();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableLanguages.entries.map((entry) {
            final languageCode = entry.key;
            final languageName = entry.value;
            final isSelected = languageCode == _currentLanguage;

            return ListTile(
              title: Text(languageName),
              trailing: isSelected
                  ? Icon(Icons.check, color: Colors.green)
                  : null,
              onTap: () async {
                await LanguageService.setLanguage(languageCode);
                setState(() {
                  _currentLanguage = languageCode;
                });

                // Notify parent about locale change
                if (widget.onLocaleChanged != null) {
                  widget.onLocaleChanged!(Locale(languageCode));
                }

                Navigator.of(context).pop();

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Language changed to $languageName'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    currentPasscodeController.dispose();
    newPasscodeController.dispose();
    confirmPasscodeController.dispose();
    super.dispose();
  }

    void _showChangePasscodeDialog() {
    final l10n = AppLocalizations.of(context)!;
    
    authService.showPasscodeDialog(context, isSetup: false).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.passcodeChanged),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void _showExportDialog() {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.upload, color: Colors.green),
            SizedBox(width: 8),
            Text(l10n.exportData),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.exportDataDescription ?? 'Enter a password to encrypt your backup:'),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Backup Password',
                hintText: 'Enter a strong password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a password'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _exportData(passwordController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog() {
    final l10n = AppLocalizations.of(context)!;
    final passwordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.download, color: Colors.blue),
            SizedBox(width: 8),
            Text(l10n.importData),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.importDataDescription ?? 'Select a backup file and enter the password:'),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Backup Password',
                hintText: 'Enter the backup password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (passwordController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a password'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              
              Navigator.pop(context);
              await _importData(passwordController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('Import'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(String password) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      
      String filePath;

        // Try to use file picker for custom location
        try {
          if (Platform.isAndroid || Platform.isIOS) {
            String encData = await encryptAccount(password);
            Uint8List fileBytes = Uint8List.fromList(utf8.encode(encData));

            final result = await FilePicker.platform.saveFile(
              dialogTitle: 'Save Backup File',
              fileName: 'hi_secure_backup_${DateTime.now().millisecondsSinceEpoch}.enc',
              type: FileType.custom,
              allowedExtensions: ['enc'],
              bytes: fileBytes,
            );

            if (result != null) {
              print('File saved to: $result');
            } else {
              print('User cancelled or failed');
            }
          } else {
            final saveResult = await FilePicker.platform.saveFile(
              dialogTitle: 'Save Backup File',
              fileName: 'hi_secure_backup_${DateTime.now().millisecondsSinceEpoch}.enc',
              type: FileType.any,
            );

            if (saveResult == null) {
              return; // User cancelled
            }

            filePath = await exportData(password, savePath: saveResult);
          }
        } catch (e) {
          // If file picker fails, fall back to auto save
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File picker not available, using auto save'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          }
          // filePath = await exportData(password);
        }
      
      // if (mounted) {
      //   ScaffoldMessenger.of(context).showSnackBar(
      //     SnackBar(
      //       content: Text('Backup created successfully at: $filePath'),
      //       backgroundColor: Colors.green,
      //       duration: Duration(seconds: 5),
      //     ),
      //   );
      // }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _importData(String password) async {
    final l10n = AppLocalizations.of(context)!;
    
    try {
      // Show file picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );
      
      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }
      
      final file = result.files.first;
      final filePath = file.path!;
      
      // Check if file has .enc extension
      if (file.extension?.toLowerCase() != 'enc') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please select a .enc backup file'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
      
      // Validate the backup file
      final isValid = await validateBackupFile(filePath, password);
      if (!isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invalid backup file or wrong password'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Import'),
          content: Text('This will replace all existing accounts. Are you sure?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Import'),
            ),
          ],
        ),
      );
      
      if (confirmed != true) return;
      
      // Import the data
      final success = await importData(filePath, password);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data imported successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          // Swipe from left to right to go back
          if (details.primaryVelocity! > 500) {
            Navigator.of(context).pop();
          }
        },
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.language, color: Colors.green),
                    title: Text(l10n.language),
                    subtitle: Text(l10n.selectLanguage),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(LanguageService.getLanguageName(_currentLanguage)),
                        Icon(Icons.arrow_forward_ios, size: 16),
                      ],
                    ),
                    onTap: _showLanguageDialog,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.security, color: Colors.green),
                    title: Text(l10n.securitySettings),
                    subtitle: Text(l10n.managePasscodeAuth),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.lock, color: Colors.grey[600]),
                    title: Text(l10n.changePasscode),
                    subtitle: Text(l10n.updatePasscode),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showChangePasscodeDialog,
                  ),
                  ListTile(
                    leading: Icon(Icons.fingerprint, color: Colors.grey[600]),
                    title: Text(l10n.biometricAuthentication),
                    subtitle: Text(l10n.useFingerprintFaceId),
                    trailing: Switch(
                      value: _biometricEnabled,
                      onChanged: _toggleBiometric,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.backup, color: Colors.green),
                    title: Text(l10n.backupRestore),
                    subtitle: Text(l10n.exportImportData),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.upload, color: Colors.grey[600]),
                    title: Text(l10n.exportData),
                    subtitle: Text(l10n.backupPasswordsSecurely),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: _showExportDialog,
                  ),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.grey[600]),
                  title: Text(l10n.importData),
                  subtitle: Text(l10n.restoreFromBackup),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showImportDialog,
                ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.info, color: Colors.green),
                    title: Text(l10n.about),
                    subtitle: Text(l10n.appInformationHelp),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.help, color: Colors.grey[600]),
                    title: Text(l10n.helpSupport),
                    subtitle: Text(l10n.getHelpWithApp),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Handle help
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.privacy_tip, color: Colors.grey[600]),
                    title: Text(l10n.privacyPolicy),
                    subtitle: Text(l10n.readPrivacyPolicy),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Handle privacy policy
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.description, color: Colors.grey[600]),
                    title: Text(l10n.termsOfService),
                    subtitle: Text(l10n.readTermsOfService),
                    trailing: Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Handle terms
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
