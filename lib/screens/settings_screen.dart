import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hi_secure/service/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final storage = FlutterSecureStorage();
  final currentPasscodeController = TextEditingController();
  final newPasscodeController = TextEditingController();
  final confirmPasscodeController = TextEditingController();
  bool _isLoading = false;
  final authService = AuthService();
  bool _biometricEnabled = false;
  Map<String, dynamic> _biometricStatus = {};

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final enabled = await authService.isBiometricEnabled();
    final status = await authService.getBiometricStatus();
    final passcodeSet = await authService.isPasscodeSet();

    setState(() {
      _biometricEnabled = enabled;
      _biometricStatus = status;
      // Add passcode status to the map for display
      _biometricStatus['passcodeSet'] = passcodeSet;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // Enable biometric
      final success = await authService.enableBiometricAfterPasscode(context);
      if (success) {
        setState(() {
          _biometricEnabled = true;
        });
        _showTestResult('Biometric enabled successfully!', true);
      } else {
        _showTestResult('Failed to enable biometric', false);
      }
    } else {
      // Disable biometric
      await authService.disableBiometric();
      setState(() {
        _biometricEnabled = false;
      });
      _showTestResult('Biometric disabled', null);
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

  Future<void> _testDirectBiometric() async {
    try {
      // Direct test without any app dialogs
      print('Direct test - starting biometric authentication...');

      final result = await authService.authenticateBiometricOnly();

      if (mounted) {
        _showTestResult(
          result
              ? 'Direct test successful!'
              : 'Direct test failed - no dialog appeared',
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        _showTestResult('Direct test error: $e', false);
      }
    }
  }

  @override
  void dispose() {
    currentPasscodeController.dispose();
    newPasscodeController.dispose();
    confirmPasscodeController.dispose();
    super.dispose();
  }

  void _showChangePasscodeDialog() {
    authService.showPasscodeDialog(context, isSetup: false).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Passcode changed successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.security, color: Colors.green),
                  title: Text('Security Settings'),
                  subtitle: Text('Manage your passcode and authentication'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.lock, color: Colors.grey[600]),
                  title: Text('Change Passcode'),
                  subtitle: Text('Update your 6-digit passcode'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasscodeDialog,
                ),
                ListTile(
                  leading: Icon(Icons.fingerprint, color: Colors.grey[600]),
                  title: Text('Biometric Authentication'),
                  subtitle: Text('Use fingerprint or face ID'),
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
                  title: Text('Backup & Restore'),
                  subtitle: Text('Export and import your data'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.upload, color: Colors.grey[600]),
                  title: Text('Export Data'),
                  subtitle: Text('Backup your passwords securely'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Handle export
                  },
                ),
                ListTile(
                  leading: Icon(Icons.download, color: Colors.grey[600]),
                  title: Text('Import Data'),
                  subtitle: Text('Restore from backup'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Handle import
                  },
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
                  title: Text('About'),
                  subtitle: Text('App information and help'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.help, color: Colors.grey[600]),
                  title: Text('Help & Support'),
                  subtitle: Text('Get help with the app'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Handle help
                  },
                ),
                ListTile(
                  leading: Icon(Icons.privacy_tip, color: Colors.grey[600]),
                  title: Text('Privacy Policy'),
                  subtitle: Text('Read our privacy policy'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // Handle privacy policy
                  },
                ),
                ListTile(
                  leading: Icon(Icons.description, color: Colors.grey[600]),
                  title: Text('Terms of Service'),
                  subtitle: Text('Read our terms of service'),
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
    );
  }
}
