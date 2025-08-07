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
    
    setState(() {
      _biometricEnabled = enabled;
      _biometricStatus = status;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    await authService.setBiometricEnabled(value);
    setState(() {
      _biometricEnabled = value;
    });
  }

  Future<void> _testBiometric() async {
    // Show a loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Testing Biometric'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Checking biometric status...'),
          ],
        ),
      ),
    );

    try {
      // Step 1: Check biometric status
      final status = await authService.getBiometricStatus();
      print('Test - Biometric status: $status');

      // Step 2: Check if enabled
      final enabled = await authService.isBiometricEnabled();
      print('Test - Biometric enabled: $enabled');

      // Step 3: Check if available
      final available = await authService.isBiometricAvailable();
      print('Test - Biometric available: $available');

      // Close the loading dialog
      if (mounted) Navigator.of(context).pop();

      if (!enabled) {
        _showTestResult('Biometric not enabled in app settings', false);
        return;
      }

      if (!available) {
        _showTestResult('Biometric not available on device', false);
        return;
      }

      // Step 4: Attempt authentication
      _showTestResult('Starting biometric authentication...', null);
      
      final result = await authService.authenticateBiometricOnly();
      
      if (mounted) {
        _showTestResult(
          result ? 'Authentication successful!' : 'Authentication failed',
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        _showTestResult('Error: $e', false);
      }
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
          result ? 'Direct test successful!' : 'Direct test failed - no dialog appeared',
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        _showTestResult('Direct test error: $e', false);
      }
    }
  }

  Future<void> _testSimpleBiometric() async {
    try {
      print('Simple test - starting basic biometric test...');
      
      final result = await authService.testBiometricAuthentication();
      
      if (mounted) {
        _showTestResult(
          result ? 'Simple test successful!' : 'Simple test failed',
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        _showTestResult('Simple test error: $e', false);
      }
    }
  }

  Future<void> _testDirectFingerprint() async {
    try {
      print('Direct fingerprint test - starting...');
      
      final result = await authService.authenticateBiometricDirect();
      
      if (mounted) {
        _showTestResult(
          result ? 'Fingerprint dialog appeared and worked!' : 'Fingerprint dialog did not appear',
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        _showTestResult('Direct fingerprint error: $e', false);
      }
    }
  }

  Future<void> _testSmartAuth() async {
    try {
      print('Smart auth test - starting...');
      
      final result = await authService.authenticateSmart(context);
      
      if (mounted) {
        _showTestResult(
          result ? 'Smart authentication successful!' : 'Smart authentication failed',
          result,
        );
      }
    } catch (e) {
      if (mounted) {
        _showTestResult('Smart auth error: $e', false);
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.security, color: Colors.green),
            SizedBox(width: 8),
            Text('Change Passcode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your current passcode and set a new one',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: currentPasscodeController,
              decoration: InputDecoration(
                labelText: 'Current Passcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: 16),
            TextField(
              controller: newPasscodeController,
              decoration: InputDecoration(
                labelText: 'New Passcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasscodeController,
              decoration: InputDecoration(
                labelText: 'Confirm New Passcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock_outline),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _clearPasscodeControllers();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _changePasscode,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('Change'),
          ),
        ],
      ),
    );
  }

  void _clearPasscodeControllers() {
    currentPasscodeController.clear();
    newPasscodeController.clear();
    confirmPasscodeController.clear();
  }

  Future<void> _changePasscode() async {
    final currentPasscode = currentPasscodeController.text;
    final newPasscode = newPasscodeController.text;
    final confirmPasscode = confirmPasscodeController.text;

    // Validate inputs
    if (currentPasscode.isEmpty || newPasscode.isEmpty || confirmPasscode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPasscode != confirmPasscode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New passcodes do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newPasscode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passcode must be 6 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Save new passcode (in a real app, you'd encrypt this)
    await storage.write(key: 'user_passcode', value: newPasscode);
    
    Navigator.pop(context);
    _clearPasscodeControllers();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text('Passcode changed successfully'),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
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
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Debug Information',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('Can Check Biometrics: ${_biometricStatus['canCheckBiometrics'] ?? 'Unknown'}'),
                  Text('Device Supported: ${_biometricStatus['isDeviceSupported'] ?? 'Unknown'}'),
                  Text('Available Biometrics: ${_biometricStatus['availableBiometrics'] ?? []}'),
                  if (_biometricStatus['error'] != null)
                    Text('Error: ${_biometricStatus['error']}', style: TextStyle(color: Colors.red)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _testBiometric,
                    child: Text('Test Biometric Authentication'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testDirectBiometric,
                    child: Text('Direct Biometric Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testSimpleBiometric,
                    child: Text('Simple Biometric Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testDirectFingerprint,
                    child: Text('Direct Fingerprint Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _testSmartAuth,
                    child: Text('Smart Authentication Test'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
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