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
      print(
        'createPasscode Fail: $e'
      );
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

      print(
        'Auth debug - canCheckBiometrics: $canCheckBiometrics, isSupported: $isSupported',
      );

      // Get available biometrics for more detailed debugging
      List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();
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
      List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();
      print(
        'Auth debug - attempting authentication with available biometrics: $availableBiometrics',
      );

      // Check if we have any biometrics available
      if (availableBiometrics.isEmpty) {
        print('Auth debug - no biometrics available');
        return false;
      }

      final didAuthenticate = await auth.authenticate(localizedReason: 'Vui lòng xác thực để truy cập Hi Secure', options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true,));

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
      List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();

      return {
        'canCheckBiometrics': canCheckBiometrics,
        'isDeviceSupported': isSupported,
        'availableBiometrics': availableBiometrics
            .map((e) => e.toString())
            .toList(),
        'hasFingerprint': availableBiometrics.contains(
          BiometricType.fingerprint,
        ),
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

      print(
        'Auth debug - biometricEnabled: $biometricEnabled, biometricAvailable: $biometricAvailable, passcodeSet: $passcodeSet',
      );

      // If no authentication is set up, return true (first time setup)
      if (!passcodeSet) {
        print('Auth debug - no passcode set, returning true');
        return true;
      }

      // If biometric is available but not enabled, offer to set it up
      if (biometricAvailable && !biometricEnabled) {
        print(
          'Auth debug - biometric available but not enabled, offering setup',
        );
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

      print(
        'Direct auth - Device supported: $isSupported, Can check biometrics: $canCheckBiometrics',
      );

      if (!isSupported || !canCheckBiometrics) {
        print('Direct auth - Device does not support biometric authentication');
        return false;
      }

      // Get available biometrics
      List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();
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
      // Check if context is still valid before showing dialog
      if (!context.mounted) {
        print('Offer biometric setup - context is no longer mounted, skipping');
        return false;
      }
      
      return await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.fingerprint, color: Colors.green),
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
                    try {
                      final success = await _setupBiometric(context);
                      if (success) {
                        Navigator.pop(context, true);
                      } else {
                        Navigator.pop(context, false);
                      }
                    } catch (e) {
                      print('Error during biometric setup: $e');
                      Navigator.pop(context, false);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Enable'),
                ),
              ],
            ),
          ) ??
          false;
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
                  Icon(Icons.lock, color: Colors.green),
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
                    final isValid = await authenticateWithPasscode(
                      enteredPasscode,
                    );
                    if (isValid) {
                      Navigator.pop(dialogContext, true);

                      // After successful passcode authentication, offer biometric
                      // Check if context is still valid before proceeding
                      if (context.mounted) {
                        try {
                          await _offerBiometricAfterPasscodeAuth(context);
                        } catch (e) {
                          print('Error offering biometric after passcode auth: $e');
                        }
                      }
                    } else {
                      // Clear the passcode field and show error text instead of SnackBar
                      passcodeController.clear();
                      enteredPasscode = '';
                      // The error will be handled by the calling code
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Verify'),
                ),
              ],
            ),
          ) ??
          false;
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
                  Icon(Icons.security, color: Colors.green),
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
                      try {
                        final success = await _setupBiometric(context);
                        if (success) {
                          Navigator.pop(context, true);
                        } else {
                          Navigator.pop(context, false);
                        }
                      } catch (e) {
                        print('Error during biometric setup in setup dialog: $e');
                        Navigator.pop(context, false);
                      }
                    },
                    icon: Icon(Icons.fingerprint),
                    label: Text('Setup Biometric'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final success = await showPasscodeDialog(
                          context,
                          isSetup: true,
                        );
                        if (success) {
                          Navigator.pop(context, true);
                        } else {
                          Navigator.pop(context, false);
                        }
                      } catch (e) {
                        print('Error during passcode setup in setup dialog: $e');
                        Navigator.pop(context, false);
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
          ) ??
          false;
    } catch (e) {
      // If context is disposed, return false
      return false;
    }
  }

  // Setup biometric authentication
  Future<bool> _setupBiometric(BuildContext context) async {
    try {
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
    } catch (e) {
      print('Error in _setupBiometric: $e');
      return false;
    }
  }

  // Removed: _setupPasscode - replaced with unified showPasscodeDialog

  // Removed: _offerBiometricAfterPasscode - no longer used

  // Offer biometric setup after successful passcode authentication
  Future<void> _offerBiometricAfterPasscodeAuth(BuildContext context) async {
    try {
      // Check if context is still valid
      if (!context.mounted) {
        print('Offer biometric - context is no longer mounted, skipping');
        return;
      }
      
      print(
        'Offer biometric - starting offer after passcode authentication...',
      );

      // Check if biometric is available
      final biometricAvailable = await isBiometricAvailable();
      print('Offer biometric - biometric available: $biometricAvailable');
      if (!biometricAvailable) {
        print('Offer biometric - biometric not available on device');
        return;
      }

      // Check if biometric is already enabled
      final biometricEnabled = await isBiometricEnabled();
      print('Offer biometric - biometric enabled: $biometricEnabled');
      if (biometricEnabled) {
        print('Offer biometric - biometric already enabled, skipping offer');
        return;
      }

      print('Offer biometric - showing biometric offer dialog...');

      // Check if context is still valid before showing dialog
      if (!context.mounted) {
        print('Offer biometric - context is no longer mounted, skipping dialog');
        return;
      }

      // Show biometric offer dialog
      final shouldEnable =
          await showDialog<bool>(
            context: context,
            barrierDismissible: true,
            builder: (context) => AlertDialog(
              title: Row(
                children: [
                  Icon(Icons.fingerprint, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text('Enable Biometric?'),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Authentication successful!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Would you like to enable biometric authentication (fingerprint/face) for faster access next time?',
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You can always enable or disable this later in Settings.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text('Skip'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('Enable'),
                ),
              ],
            ),
          ) ??
          false;

      print('Offer biometric - user choice: $shouldEnable');

      if (shouldEnable) {
        // Check if context is still valid before biometric setup
        if (!context.mounted) {
          print('Offer biometric - context is no longer mounted, skipping biometric setup');
          return;
        }
        
        // Proceed with biometric setup
        try {
          final biometricSuccess = await _setupBiometric(context);
          if (biometricSuccess) {
            print('Offer biometric - biometric enabled successfully');
          } else {
            print('Offer biometric - biometric setup failed');
          }
        } catch (e) {
          print('Offer biometric - error during biometric setup: $e');
        }
      } else {
        print('Offer biometric - user chose to skip');
      }
    } catch (e) {
      print('Offer biometric - error: $e');
    }
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
      List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();
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

      print(
        'Smart auth - biometric enabled: $biometricEnabled, available: $biometricAvailable',
      );

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

  // Platform-specific biometric authentication with passcode fallback
  Future<bool> authenticatePlatformBiometric(BuildContext context) async {
    try {
      print(
        'Platform auth - starting platform-specific biometric authentication...',
      );

      // Check if authentication is set up
      final isSetUp = await isAuthenticationSetUp();
      if (!isSetUp) {
        print(
          'Platform auth - no authentication set up, starting first-time setup',
        );
        return await handleFirstTimeSetup(context);
      }

      // Check if biometric is available and enabled
      final isAvailable = await isBiometricAvailable();
      final biometricEnabled = await isBiometricEnabled();

      if (!isAvailable || !biometricEnabled) {
        print(
          'Platform auth - biometric not available or disabled, using passcode',
        );
        return await _showPasscodeDialog(context);
      }

      // Get available biometrics
      List<BiometricType> availableBiometrics = await auth
          .getAvailableBiometrics();
      print('Platform auth - available biometrics: $availableBiometrics');

      if (availableBiometrics.isEmpty) {
        print(
          'Platform auth - no biometrics available, falling back to passcode',
        );
        return await _showPasscodeDialog(context);
      }

      // Platform-specific logic
      if (Platform.isAndroid) {
        // Android: try to use any available biometric
        if (availableBiometrics.contains(BiometricType.fingerprint)) {
          print('Platform auth - Android: using fingerprint');
          final result = await _authenticateWithFingerprint();
          if (!result) {
            print(
              'Platform auth - fingerprint failed, falling back to passcode',
            );
            return await _showPasscodeDialog(context);
          }
          return result;
        } else if (availableBiometrics.contains(BiometricType.face)) {
          print('Platform auth - Android: using face');
          final result = await _authenticateWithFace();
          if (!result) {
            print('Platform auth - face failed, falling back to passcode');
            return await _showPasscodeDialog(context);
          }
          return result;
        } else if (availableBiometrics.contains(BiometricType.strong)) {
          print('Platform auth - Android: using strong biometric');
          final result = await _authenticateWithStrong();
          if (!result) {
            print(
              'Platform auth - strong biometric failed, falling back to passcode',
            );
            return await _showPasscodeDialog(context);
          }
          return result;
        } else if (availableBiometrics.contains(BiometricType.weak)) {
          print('Platform auth - Android: using weak biometric');
          final result = await _authenticateWithWeak();
          if (!result) {
            print(
              'Platform auth - weak biometric failed, falling back to passcode',
            );
            return await _showPasscodeDialog(context);
          }
          return result;
        }
      } else if (Platform.isIOS) {
        // iOS: prefer face, fallback to fingerprint
        if (availableBiometrics.contains(BiometricType.face)) {
          print('Platform auth - iOS: using face');
          final result = await _authenticateWithFace();
          if (!result) {
            print('Platform auth - face failed, falling back to passcode');
            return await _showPasscodeDialog(context);
          }
          return result;
        } else if (availableBiometrics.contains(BiometricType.fingerprint)) {
          print('Platform auth - iOS: using fingerprint (face not available)');
          final result = await _authenticateWithFingerprint();
          if (!result) {
            print(
              'Platform auth - fingerprint failed, falling back to passcode',
            );
            return await _showPasscodeDialog(context);
          }
          return result;
        } else if (availableBiometrics.contains(BiometricType.strong)) {
          print('Platform auth - iOS: using strong biometric');
          final result = await _authenticateWithStrong();
          if (!result) {
            print(
              'Platform auth - strong biometric failed, falling back to passcode',
            );
            return await _showPasscodeDialog(context);
          }
          return result;
        }
      }

      print(
        'Platform auth - no suitable biometric found, falling back to passcode',
      );
      return await _showPasscodeDialog(context);
    } catch (e) {
      print('Platform auth - error: $e');
      print('Platform auth - error type: ${e.runtimeType}');
      return await _showPasscodeDialog(context);
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

  // Check if any authentication is set up
  Future<bool> isAuthenticationSetUp() async {
    final biometricEnabled = await isBiometricEnabled();
    final passcodeSet = await isPasscodeSet();
    return biometricEnabled || passcodeSet;
  }

  // Handle first-time setup
  Future<bool> handleFirstTimeSetup(BuildContext context) async {
    try {
      print('First time setup - starting setup process...');

      // Use unified passcode dialog for setup
      print('First time setup - showing passcode setup dialog');
      final passcodeSuccess = await showPasscodeDialog(context, isSetup: true);
      if (passcodeSuccess) {
        print('First time setup - passcode setup successful');
        return true;
      }

      print('First time setup - passcode setup failed');
      return false;
    } catch (e) {
      print('First time setup - error: $e');
      return false;
    }
  }

  // Enable biometric after passcode is set up
  Future<bool> enableBiometricAfterPasscode(BuildContext context) async {
    try {
      print('Enable biometric - checking if passcode is set up...');

      // Check if passcode is set up
      final passcodeSet = await isPasscodeSet();
      if (!passcodeSet) {
        print('Enable biometric - no passcode set up, cannot enable biometric');
        return false;
      }

      // Check if biometric is available
      final biometricAvailable = await isBiometricAvailable();
      if (!biometricAvailable) {
        print('Enable biometric - biometric not available on device');
        return false;
      }

      // Offer biometric setup
      final biometricSuccess = await _offerBiometricSetup(context);
      if (biometricSuccess) {
        print('Enable biometric - biometric enabled successfully');
        return true;
      }

      print('Enable biometric - biometric setup failed or cancelled');
      return false;
    } catch (e) {
      print('Enable biometric - error: $e');
      return false;
    }
  }

  // Disable biometric (keep passcode)
  Future<void> disableBiometric() async {
    try {
      print('Disable biometric - disabling biometric authentication...');
      await setBiometricEnabled(false);
      print('Disable biometric - biometric disabled successfully');
    } catch (e) {
      print('Disable biometric - error: $e');
    }
  }

  // Unified passcode dialog for setup and change
  Future<bool> showPasscodeDialog(
    BuildContext context, {
    bool isSetup = false,
  }) async {
    final currentPasscodeController = TextEditingController();
    final newPasscodeController = TextEditingController();
    final confirmPasscodeController = TextEditingController();

    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            child: Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          isSetup ? 'Create Passcode' : 'Change Passcode',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isSetup
                                ? 'Create a 6-digit passcode for security'
                                : 'Enter your current passcode and create a new one',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          // Show current passcode field only for change
                          if (!isSetup) ...[
                            TextField(
                              controller: currentPasscodeController,
                              decoration: InputDecoration(
                                labelText: 'Current Passcode',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.security),
                                hintText: 'Enter current passcode',
                              ),
                              obscureText: true,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                            ),
                            SizedBox(height: 14),
                          ],
                          TextField(
                            controller: newPasscodeController,
                            decoration: InputDecoration(
                              labelText: isSetup ? 'Passcode' : 'New Passcode',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.security),
                              hintText: isSetup
                                  ? 'Enter 6-digit passcode'
                                  : 'Enter new 6-digit passcode',
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                          SizedBox(height: 14),
                          TextField(
                            controller: confirmPasscodeController,
                            decoration: InputDecoration(
                              labelText: isSetup
                                  ? 'Confirm Passcode'
                                  : 'Confirm New Passcode',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.security),
                              hintText: isSetup
                                  ? 'Confirm 6-digit passcode'
                                  : 'Confirm new 6-digit passcode',
                            ),
                            obscureText: true,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Cancel'),
                        ),
                        SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final currentPasscode =
                                currentPasscodeController.text;
                            final newPasscode = newPasscodeController.text;
                            final confirmPasscode =
                                confirmPasscodeController.text;

                            if (isSetup) {
                              // Setup mode - validate new passcode only
                              if (newPasscode.length != 6) {
                                newPasscodeController.clear();
                                confirmPasscodeController.clear();
                                return;
                              }

                              if (newPasscode != confirmPasscode) {
                                newPasscodeController.clear();
                                confirmPasscodeController.clear();
                                return;
                              }

                              final success = await createPasscode(newPasscode);
                              if (success) {
                                Navigator.pop(context, true);
                                // Check if context is still valid before proceeding
                                if (context.mounted) {
                                  try {
                                    await _offerBiometricAfterPasscodeAuth(context);
                                  } catch (e) {
                                    print('Error offering biometric after passcode setup: $e');
                                  }
                                }
                              } else {
                                newPasscodeController.clear();
                                confirmPasscodeController.clear();
                              }
                            } else {
                              // Change mode - validate current and new passcode
                              final isCurrentValid = await verifyPasscode(
                                currentPasscode,
                              );
                              if (!isCurrentValid) {
                                currentPasscodeController.clear();
                                return;
                              }

                              if (newPasscode.length != 6) {
                                newPasscodeController.clear();
                                confirmPasscodeController.clear();
                                return;
                              }

                              if (newPasscode != confirmPasscode) {
                                newPasscodeController.clear();
                                confirmPasscodeController.clear();
                                return;
                              }

                              final success = await createPasscode(newPasscode);
                              if (success) {
                                Navigator.pop(context, true);
                                // Check if context is still valid before proceeding
                                if (context.mounted) {
                                  try {
                                    await _offerBiometricAfterPasscodeAuth(context);
                                  } catch (e) {
                                    print('Error offering biometric after passcode change: $e');
                                  }
                                }
                              } else {
                                currentPasscodeController.clear();
                                newPasscodeController.clear();
                                confirmPasscodeController.clear();
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(isSetup ? 'Create' : 'Change'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }
}
