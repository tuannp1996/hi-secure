import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class AuthService {
  static const _passcodeKey = 'user_passcode';
  static const _biometricEnabledKey = 'biometric_enabled';
  final storage = FlutterSecureStorage();
  final auth = LocalAuthentication();

  // Check if passcode is set
  Future<bool> isPasscodeSet() async {
    final passcode = await storage.read(key: _passcodeKey);
    return passcode != null && passcode.isNotEmpty;
  }

  // Check if biometric is enabled
  Future<bool> isBiometricEnabled() async {
    final enabled = await storage.read(key: _biometricEnabledKey);
    return enabled == 'true';
  }

  // Set biometric enabled/disabled
  Future<void> setBiometricEnabled(bool enabled) async {
    await storage.write(key: _biometricEnabledKey, value: enabled.toString());
  }

  // Create and store passcode
  Future<bool> createPasscode(String passcode) async {
    try {
      await storage.write(key: _passcodeKey, value: passcode);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Verify passcode
  Future<bool> verifyPasscode(String passcode) async {
    final storedPasscode = await storage.read(key: _passcodeKey);
    return storedPasscode == passcode;
  }

  // Check if biometric is available
  Future<bool> isBiometricAvailable() async {
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    bool isSupported = await auth.isDeviceSupported();
    return canCheckBiometrics && isSupported;
  }

  // Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Please authenticate to access Hi Secure',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Authenticate with passcode
  Future<bool> authenticateWithPasscode(String passcode) async {
    return await verifyPasscode(passcode);
  }

     // Main authentication method - tries biometric first, then passcode
   Future<bool> authenticate(BuildContext context) async {
     try {
       final biometricEnabled = await isBiometricEnabled();
       final biometricAvailable = await isBiometricAvailable();
       final passcodeSet = await isPasscodeSet();

       // If no authentication is set up, return true (first time setup)
       if (!passcodeSet) {
         return true;
       }

       // Try biometric if enabled and available
       if (biometricEnabled && biometricAvailable) {
         final biometricSuccess = await authenticateWithBiometric();
         if (biometricSuccess) {
           return true;
         }
       }

       // Fallback to passcode
       if (passcodeSet) {
         return await _showPasscodeDialog(context);
       }

       return false;
     } catch (e) {
       // If any error occurs, return false
       return false;
     }
   }

     // Show passcode dialog
   Future<bool> _showPasscodeDialog(BuildContext context) async {
     final passcodeController = TextEditingController();
     String enteredPasscode = '';
     
     try {
       return await showDialog<bool>(
         context: context,
         barrierDismissible: false,
         builder: (dialogContext) => AlertDialog(
           title: Row(
             children: [
               Icon(Icons.lock, color: Colors.indigo),
               SizedBox(width: 8),
               Text('Enter Passcode'),
             ],
           ),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 'Please enter your passcode to access Hi Secure',
                 style: TextStyle(fontSize: 14),
               ),
               SizedBox(height: 16),
               TextField(
                 controller: passcodeController,
                 decoration: InputDecoration(
                   labelText: 'Passcode',
                   border: OutlineInputBorder(),
                   prefixIcon: Icon(Icons.security),
                   hintText: 'Enter your passcode',
                 ),
                 obscureText: true,
                 keyboardType: TextInputType.number,
                 maxLength: 6,
                 onChanged: (value) {
                   enteredPasscode = value;
                 },
               ),
             ],
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(dialogContext, false),
               child: Text('Cancel'),
             ),
             ElevatedButton(
               onPressed: () async {
                 final isValid = await authenticateWithPasscode(enteredPasscode);
                 if (isValid) {
                   Navigator.pop(dialogContext, true);
                 } else {
                   // Show error in the dialog context
                   ScaffoldMessenger.of(dialogContext).showSnackBar(
                     SnackBar(
                       content: Row(
                         children: [
                           Icon(Icons.error, color: Colors.white),
                           SizedBox(width: 8),
                           Text('Incorrect passcode'),
                         ],
                       ),
                       backgroundColor: Colors.red,
                     ),
                   );
                 }
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.indigo,
                 foregroundColor: Colors.white,
               ),
               child: Text('Verify'),
             ),
           ],
         ),
       ) ?? false;
     } catch (e) {
       return false;
     }
   }

        // Show setup dialog for first time users
   Future<bool> showSetupDialog(BuildContext context) async {
     try {
       return await showDialog<bool>(
         context: context,
         barrierDismissible: false,
         builder: (context) => AlertDialog(
           title: Row(
             children: [
               Icon(Icons.security, color: Colors.indigo),
               SizedBox(width: 8),
               Text('Setup Security'),
             ],
           ),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 'Welcome to Hi Secure! Let\'s set up your security.',
                 style: TextStyle(fontSize: 14),
               ),
               SizedBox(height: 16),
               ElevatedButton.icon(
                 onPressed: () async {
                   if (context.mounted) {
                     Navigator.pop(context);
                     final success = await _setupBiometric(context);
                     if (success && context.mounted) {
                       Navigator.pop(context, true);
                     }
                   }
                 },
                 icon: Icon(Icons.fingerprint),
                 label: Text('Setup Biometric'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.indigo,
                   foregroundColor: Colors.white,
                 ),
               ),
               SizedBox(height: 8),
               ElevatedButton.icon(
                 onPressed: () async {
                   if (context.mounted) {
                     Navigator.pop(context);
                     final success = await _setupPasscode(context);
                     if (success && context.mounted) {
                       Navigator.pop(context, true);
                     }
                   }
                 },
                 icon: Icon(Icons.lock),
                 label: Text('Setup Passcode'),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.green,
                   foregroundColor: Colors.white,
                 ),
               ),
             ],
           ),
         ),
       ) ?? false;
     } catch (e) {
       // If context is disposed, return false
       return false;
     }
  }

  // Setup biometric authentication
  Future<bool> _setupBiometric(BuildContext context) async {
    final biometricAvailable = await isBiometricAvailable();
    
         if (!biometricAvailable) {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Biometric authentication is not available on this device'),
             backgroundColor: Colors.orange,
           ),
         );
       }
       return false;
     }

         final success = await authenticateWithBiometric();
     if (success) {
       await setBiometricEnabled(true);
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Biometric authentication enabled'),
             backgroundColor: Colors.green,
           ),
         );
       }
       return true;
     } else {
       if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('Biometric authentication failed'),
             backgroundColor: Colors.red,
           ),
         );
       }
       return false;
     }
  }

  // Setup passcode
  Future<bool> _setupPasscode(BuildContext context) async {
    final passcodeController = TextEditingController();
    final confirmPasscodeController = TextEditingController();
    
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.indigo),
            SizedBox(width: 8),
            Text('Create Passcode'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Create a 6-digit passcode for security',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            TextField(
              controller: passcodeController,
              decoration: InputDecoration(
                labelText: 'Passcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
                hintText: 'Enter 6-digit passcode',
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            SizedBox(height: 16),
            TextField(
              controller: confirmPasscodeController,
              decoration: InputDecoration(
                labelText: 'Confirm Passcode',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.security),
                hintText: 'Confirm 6-digit passcode',
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final passcode = passcodeController.text;
              final confirmPasscode = confirmPasscodeController.text;
              
                             if (passcode.length != 6) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text('Passcode must be 6 digits'),
                       backgroundColor: Colors.red,
                     ),
                   );
                 }
                 return;
               }
               
               if (passcode != confirmPasscode) {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text('Passcodes do not match'),
                       backgroundColor: Colors.red,
                     ),
                   );
                 }
                 return;
               }
               
               final success = await createPasscode(passcode);
               if (success) {
                 if (context.mounted) {
                   Navigator.pop(context, true);
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text('Passcode created successfully'),
                       backgroundColor: Colors.green,
                     ),
                   );
                 }
               } else {
                 if (context.mounted) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                       content: Text('Failed to create passcode'),
                       backgroundColor: Colors.red,
                     ),
                   );
                 }
               }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
            ),
            child: Text('Create'),
          ),
        ],
      ),
    ) ?? false;
  }
} 