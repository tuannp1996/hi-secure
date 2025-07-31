import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
            Icon(Icons.security, color: Colors.indigo),
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
              maxLength: 4,
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
              maxLength: 4,
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
              maxLength: 4,
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
              backgroundColor: Colors.indigo,
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

    if (newPasscode.length != 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passcode must be 4 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // For demo purposes, check against default passcode
    // In a real app, you would check against stored passcode
    const defaultPasscode = "1234";
    if (currentPasscode != defaultPasscode) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Current passcode is incorrect'),
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
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.security, color: Colors.indigo),
                  title: Text('Security Settings'),
                  subtitle: Text('Manage your passcode and authentication'),
                ),
                Divider(),
                ListTile(
                  leading: Icon(Icons.lock, color: Colors.grey[600]),
                  title: Text('Change Passcode'),
                  subtitle: Text('Update your 4-digit passcode'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _showChangePasscodeDialog,
                ),
                ListTile(
                  leading: Icon(Icons.fingerprint, color: Colors.grey[600]),
                  title: Text('Biometric Authentication'),
                  subtitle: Text('Use fingerprint or face ID'),
                  trailing: Switch(
                    value: true, // This would be dynamic in a real app
                    onChanged: (value) {
                      // Handle biometric toggle
                    },
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
                  leading: Icon(Icons.backup, color: Colors.indigo),
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
                  leading: Icon(Icons.info, color: Colors.indigo),
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