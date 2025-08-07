import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'dart:io' show Platform;

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
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      
      print('Auth debug - canCheckBiometrics: $canCheckBiometrics, isSupported: $isSupported');
      
      // Get available biometrics for more detailed debugging
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      print('Auth debug - available biometrics: $availableBiometrics');
      
      return canCheckBiometrics && isSupported;
    } catch (e) {
      print('Auth debug - error checking biometric availability: $e');
      return false;
    }
  }

  // Authenticate with biometric
  Future<bool> authenticateWithBiometric() async {
    try {
      print('Auth debug - starting authenticateWithBiometric()');
      
      // First check if biometric is available
      final isAvailable = await isBiometricAvailable();
      print('Auth debug - biometric available: $isAvailable');
      
      if (!isAvailable) {
        print('Auth debug - biometric not available');
        return false;
      }

      // Get available biometrics to determine the best authentication method
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      print('Auth debug - attempting authentication with available biometrics: $availableBiometrics');

      // Check if we have any biometrics available
      if (availableBiometrics.isEmpty) {
        print('Auth debug - no biometrics available');
        return false;
      }

      print('Auth debug - starting biometric authentication...');
      print('Auth debug - calling auth.authenticate() with localizedReason: "Vui lòng xác thực để truy cập Hi Secure"');
      
      final didAuthenticate = await auth.authenticate(
        localizedReason: 'Vui lòng xác thực để truy cập Hi Secure',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      print('Auth debug - authentication result: $didAuthenticate');
      return didAuthenticate;
    } catch (e) {
      print('Auth debug - biometric authentication error: $e');
      print('Auth debug - error type: ${e.runtimeType}');
      return false;
    }
  }

  // New method to get detailed biometric status
  Future<Map<String, dynamic>> getBiometricStatus() async {
    try {
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      bool isSupported = await auth.isDeviceSupported();
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      
      return {
        'canCheckBiometrics': canCheckBiometrics,
        'isDeviceSupported': isSupported,
        'availableBiometrics': availableBiometrics.map((e) => e.toString()).toList(),
        'hasFingerprint': availableBiometrics.contains(BiometricType.fingerprint),
        'hasFace': availableBiometrics.contains(BiometricType.face),
        'hasIris': availableBiometrics.contains(BiometricType.iris),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'canCheckBiometrics': false,
        'isDeviceSupported': false,
        'availableBiometrics': [],
      };
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

       print('Auth debug - biometricEnabled: $biometricEnabled, biometricAvailable: $biometricAvailable, passcodeSet: $passcodeSet');

       // If no authentication is set up, return true (first time setup)
       if (!passcodeSet) {
         print('Auth debug - no passcode set, returning true');
         return true;
       }

       // If biometric is available but not enabled, offer to set it up
       if (biometricAvailable && !biometricEnabled) {
         print('Auth debug - biometric available but not enabled, offering setup');
         if (context.mounted) {
           final setupSuccess = await _offerBiometricSetup(context);
           if (setupSuccess) {
             return true;
           }
         }
       }

       // Try biometric if enabled and available
       if (biometricEnabled && biometricAvailable) {
         print('Auth debug - attempting biometric authentication');
         final biometricSuccess = await authenticateWithBiometric();
         print('Auth debug - biometric result: $biometricSuccess');
         if (biometricSuccess) {
           print('Auth debug - biometric successful, returning true');
           return true;
         }
       }

       // Fallback to passcode
       if (passcodeSet) {
         print('Auth debug - falling back to passcode dialog');
         // Check if context is still valid before showing dialog
         if (context.mounted) {
           return await _showPasscodeDialog(context);
         } else {
           print('Auth debug - context no longer mounted, returning false');
           return false;
         }
       }

       print('Auth debug - no authentication method available, returning false');
       return false;
     } catch (e) {
       print('Auth debug - error occurred: $e');
       // If any error occurs, return false
       return false;
     }
   }

   // New method for biometric-only authentication without context
   Future<bool> authenticateBiometricOnly() async {
     try {
       final biometricEnabled = await isBiometricEnabled();
       final biometricAvailable = await isBiometricAvailable();
       
       if (biometricEnabled && biometricAvailable) {
         print('Auth debug - attempting biometric-only authentication');
         final biometricSuccess = await authenticateWithBiometric();
         print('Auth debug - biometric-only result: $biometricSuccess');
         return biometricSuccess;
       }
       
       return false;
     } catch (e) {
       print('Auth debug - biometric-only error: $e');
       return false;
     }
   }

   // Direct biometric authentication - simplified version
  Future<bool> authenticateBiometricDirect() async {
    try {
      print('Direct auth - starting direct biometric authentication...');
      
      // Basic checks
      bool isSupported = await auth.isDeviceSupported();
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      
      print('Direct auth - Device supported: $isSupported, Can check biometrics: $canCheckBiometrics');
      
      if (!isSupported || !canCheckBiometrics) {
        print('Direct auth - Device does not support biometric authentication');
        return false;
      }
      
      // Get available biometrics
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      print('Direct auth - Available biometrics: $availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        print('Direct auth - No biometrics available');
        return false;
      }
      
      // Direct authentication call - this should trigger the system dialog
      print('Direct auth - Calling auth.authenticate()...');
      
      final result = await auth.authenticate(
        localizedReason: 'Touch fingerprint sensor to unlock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false, // Changed to false to ensure dialog appears
        ),
      );
      
      print('Direct auth - Authentication result: $result');
      return result;
      
    } catch (e) {
      print('Direct auth - Error: $e');
      return false;
    }
  }

   // Offer biometric setup to existing users
   Future<bool> _offerBiometricSetup(BuildContext context) async {
     try {
       return await showDialog<bool>(
         context: context,
         barrierDismissible: false,
         builder: (context) => AlertDialog(
           title: Row(
             children: [
               Icon(Icons.fingerprint, color: Colors.indigo),
               SizedBox(width: 8),
               Text('Enable Biometric'),
             ],
           ),
           content: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
               Text(
                 'Would you like to enable biometric authentication for faster access?',
                 style: TextStyle(fontSize: 14),
               ),
             ],
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(context, false),
               child: Text('Skip'),
             ),
             ElevatedButton(
               onPressed: () async {
                 Navigator.pop(context);
                 final success = await _setupBiometric(context);
                 if (success) {
                   Navigator.pop(context, true);
                 }
               },
               style: ElevatedButton.styleFrom(
                 backgroundColor: Colors.indigo,
                 foregroundColor: Colors.white,
               ),
               child: Text('Enable'),
             ),
           ],
         ),
       ) ?? false;
     } catch (e) {
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
                   // Clear the passcode field and show error text instead of SnackBar
                   passcodeController.clear();
                   enteredPasscode = '';
                   // The error will be handled by the calling code
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
                   Navigator.pop(context);
                   final success = await _setupBiometric(context);
                   if (success) {
                     Navigator.pop(context, true);
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
                   Navigator.pop(context);
                   final success = await _setupPasscode(context);
                   if (success) {
                     Navigator.pop(context, true);
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
      // Don't show snackbar here, just return false
      // The calling code can handle the UI feedback
      return false;
    }

    final success = await authenticateWithBiometric();
    if (success) {
      await setBiometricEnabled(true);
      return true;
    } else {
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
                // Clear fields and return without showing error
                passcodeController.clear();
                confirmPasscodeController.clear();
                return;
              }
              
              if (passcode != confirmPasscode) {
                // Clear fields and return without showing error
                passcodeController.clear();
                confirmPasscodeController.clear();
                return;
              }
              
              final success = await createPasscode(passcode);
              if (success) {
                Navigator.pop(context, true);
              } else {
                // Clear fields on failure
                passcodeController.clear();
                confirmPasscodeController.clear();
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

  // Simple test method for biometric authentication
  Future<bool> testBiometricAuthentication() async {
    try {
      print('Test - Starting simple biometric test...');
      
      // Check if device supports biometric
      bool isSupported = await auth.isDeviceSupported();
      print('Test - Device supported: $isSupported');
      
      if (!isSupported) {
        print('Test - Device does not support biometric authentication');
        return false;
      }
      
      // Check if biometric is available
      bool canCheckBiometrics = await auth.canCheckBiometrics;
      print('Test - Can check biometrics: $canCheckBiometrics');
      
      if (!canCheckBiometrics) {
        print('Test - Cannot check biometrics');
        return false;
      }
      
      // Get available biometrics
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      print('Test - Available biometrics: $availableBiometrics');
      
      if (availableBiometrics.isEmpty) {
        print('Test - No biometrics available');
        return false;
      }
      
      // Attempt authentication
      print('Test - Attempting authentication...');
      final result = await auth.authenticate(
        localizedReason: 'Test biometric authentication',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
      
      print('Test - Authentication result: $result');
      return result;
      
    } catch (e) {
      print('Test - Error during biometric test: $e');
      return false;
    }
  }

  // Smart authentication - automatically chooses biometric or passcode
  Future<bool> authenticateSmart(BuildContext context) async {
    try {
      print('Smart auth - starting smart authentication...');
      
      // Check if biometric is enabled and available
      final biometricEnabled = await isBiometricEnabled();
      final biometricAvailable = await isBiometricAvailable();
      
      print('Smart auth - biometric enabled: $biometricEnabled, available: $biometricAvailable');
      
      // If biometric is available and enabled, try it first
      if (biometricEnabled && biometricAvailable) {
        print('Smart auth - attempting biometric authentication...');
        final biometricResult = await authenticateBiometricDirect();
        
        if (biometricResult) {
          print('Smart auth - biometric successful');
          return true;
        } else {
          print('Smart auth - biometric failed, falling back to passcode');
        }
      }
      
      // Fallback to passcode if biometric fails or is not available
      final passcodeSet = await isPasscodeSet();
      if (passcodeSet) {
        print('Smart auth - attempting passcode authentication...');
        if (context.mounted) {
          return await _showPasscodeDialog(context);
        }
      }
      
      print('Smart auth - no authentication method available');
      return false;
      
    } catch (e) {
      print('Smart auth - error: $e');
      return false;
    }
  }

  // Platform-specific biometric authentication
  Future<bool> authenticatePlatformBiometric() async {
    try {
      print('Platform auth - starting platform-specific biometric authentication...');
      
      // Check if biometric is available
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('Platform auth - biometric not available');
        return false;
      }

      // Get available biometrics
      List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      print('Platform auth - available biometrics: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        print('Platform auth - no biometrics available');
        return false;
      }

      // Platform-specific logic
      if (Platform.isAndroid) {
        // Android: try to use any available biometric
        if (availableBiometrics.contains(BiometricType.fingerprint)) {
          print('Platform auth - Android: using fingerprint');
          return await _authenticateWithFingerprint();
        } else if (availableBiometrics.contains(BiometricType.face)) {
          print('Platform auth - Android: using face');
          return await _authenticateWithFace();
        } else if (availableBiometrics.contains(BiometricType.strong)) {
          print('Platform auth - Android: using strong biometric');
          return await _authenticateWithStrong();
        } else if (availableBiometrics.contains(BiometricType.weak)) {
          print('Platform auth - Android: using weak biometric');
          return await _authenticateWithWeak();
        }
      } else if (Platform.isIOS) {
        // iOS: prefer face, fallback to fingerprint
        if (availableBiometrics.contains(BiometricType.face)) {
          print('Platform auth - iOS: using face');
          return await _authenticateWithFace();
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          print('Platform auth - iOS: using fingerprint (face not available)');
          return await _authenticateWithFingerprint();
        } else if (availableBiometrics.contains(BiometricType.strong)) {
          print('Platform auth - iOS: using strong biometric');
          return await _authenticateWithStrong();
        }
      }

      print('Platform auth - no suitable biometric found');
      return false;
      
    } catch (e) {
      print('Platform auth - error: $e');
      print('Platform auth - error type: ${e.runtimeType}');
      return false;
    }
  }

  // Authenticate with fingerprint specifically
  Future<bool> _authenticateWithFingerprint() async {
    try {
      print('Fingerprint auth - starting fingerprint authentication...');
      
      final result = await auth.authenticate(
        localizedReason: 'Touch fingerprint sensor to unlock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      
      print('Fingerprint auth - result: $result');
      return result;
    } catch (e) {
      print('Fingerprint auth - error: $e');
      return false;
    }
  }

  // Authenticate with face specifically
  Future<bool> _authenticateWithFace() async {
    try {
      print('Face auth - starting face authentication...');
      
      final result = await auth.authenticate(
        localizedReason: 'Look at the camera to unlock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      
      print('Face auth - result: $result');
      return result;
    } catch (e) {
      print('Face auth - error: $e');
      return false;
    }
  }

  // Authenticate with strong biometric (high security)
  Future<bool> _authenticateWithStrong() async {
    try {
      print('Strong auth - starting strong biometric authentication...');
      
      final result = await auth.authenticate(
        localizedReason: 'Use your biometric to unlock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      
      print('Strong auth - result: $result');
      return result;
    } catch (e) {
      print('Strong auth - error: $e');
      return false;
    }
  }

  // Authenticate with weak biometric (lower security)
  Future<bool> _authenticateWithWeak() async {
    try {
      print('Weak auth - starting weak biometric authentication...');
      
      final result = await auth.authenticate(
        localizedReason: 'Use your biometric to unlock',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      
      print('Weak auth - result: $result');
      return result;
    } catch (e) {
      print('Weak auth - error: $e');
      return false;
    }
  }
} 