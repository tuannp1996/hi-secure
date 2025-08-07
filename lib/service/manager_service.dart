import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import '../model/account.dart';
import 'account_service.dart';

final storage = FlutterSecureStorage();

// Legacy functions for backward compatibility
// These functions now delegate to AccountService

// Save
Future<void> saveAccount(Account account) async {
  await AccountService.saveAccount(account);
}

// Load All
Future<List<Account>> loadAllAccounts(String? appId) async {
  return await AccountService.loadAccounts(appId: appId);
}

// Delete
Future<void> deleteAccount(String appId) async {
  await AccountService.deleteAllAccountsForApp(appId);
}

// Secure Export Data
Future<String> exportData(String password, {String? savePath}) async {
  try {
    final encryptedData = await encryptAccount(password);
    
    // Use provided save path or default to documents directory
    String filePath;
    if (savePath != null) {
      filePath = savePath;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'hi_secure_backup_$timestamp.enc';
      filePath = '${directory.path}/$fileName';
    }
    
    final file = File(filePath);

    await file.writeAsString(encryptedData);
    
    return file.path;
  } catch (e) {
    throw Exception('Failed to export data: $e');
  }
}

Future<String> encryptAccount(String password) async {
  try {
    // Get all accounts
    final accounts = await AccountService.loadAccounts();

    // Create export data structure
    final exportData = {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'accounts': accounts.map((account) => account.toJson()).toList(),
    };

    // Convert to JSON
    final jsonData = jsonEncode(exportData);

    // Encrypt the data with the provided password
    return _encryptData(jsonData, password);
  } catch (e) {
    throw Exception('Failed to encrypt account: $e');
  }
}

// Secure Import Data
Future<bool> importData(String filePath, String password) async {
  try {
    // Read encrypted file
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Backup file not found');
    }
    
    final encryptedData = await file.readAsString();
    
    if (encryptedData.isEmpty) {
      throw Exception('Backup file is empty');
    }
    
    // Decrypt the data
    final decryptedData = _decryptData(encryptedData, password);
    
    // Parse JSON
    final importData = jsonDecode(decryptedData) as Map<String, dynamic>;
    
    // Validate version
    final version = importData['version'] as String?;
    if (version == null || !version.startsWith('1.')) {
      throw Exception('Unsupported backup format');
    }
    
    // Import accounts
    final accounts = importData['accounts'] as List<dynamic>?;
    if (accounts == null || accounts.isEmpty) {
      throw Exception('No accounts found in backup file');
    }
    
    // Clear existing accounts first
    final all = await storage.readAll();
    final accountKeys = all.keys.where((key) => key.startsWith('account_'));
    for (final key in accountKeys) {
      await storage.delete(key: key);
    }
    
    // Import new accounts
    int importedCount = 0;
    for (final accountData in accounts) {
      try {
        final account = Account.fromJson(accountData as Map<String, dynamic>);
        await AccountService.addAccount(account);
        importedCount++;
      } catch (e) {
        print('Error importing account: $e');
        // Continue with other accounts
      }
    }
    
    if (importedCount == 0) {
      throw Exception('No accounts were successfully imported');
    }
    
    return true;
  } catch (e) {
    print('Import error: $e');
    throw Exception('Failed to import data: $e');
  }
}

// Simple encryption using password hash
String _encryptData(String data, String password) {
  try {
    // Create a hash of the password for consistent key generation
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    
    // Simple XOR encryption with password hash
    final keyBytes = utf8.encode(passwordHash);
    final dataBytes = utf8.encode(data);
    final encryptedBytes = <int>[];
    
    for (int i = 0; i < dataBytes.length; i++) {
      encryptedBytes.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return base64Encode(encryptedBytes);
  } catch (e) {
    print('Encryption error: $e');
    throw Exception('Failed to encrypt data: $e');
  }
}

// Simple decryption using password hash
String _decryptData(String encryptedData, String password) {
  try {
    // Create a hash of the password for consistent key generation
    final passwordHash = sha256.convert(utf8.encode(password)).toString();
    
    // Decrypt using XOR
    final keyBytes = utf8.encode(passwordHash);
    final encryptedBytes = base64Decode(encryptedData);
    final decryptedBytes = <int>[];
    
    for (int i = 0; i < encryptedBytes.length; i++) {
      decryptedBytes.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
    }
    
    return utf8.decode(decryptedBytes);
  } catch (e) {
    print('Decryption error: $e');
    throw Exception('Failed to decrypt data: $e');
  }
}

// Validate backup file
Future<bool> validateBackupFile(String filePath, String password) async {
  try {
    final file = File(filePath);
    if (!await file.exists()) {
      return false;
    }
    
    final encryptedData = await file.readAsString();
    final decryptedData = _decryptData(encryptedData, password);
    final importData = jsonDecode(decryptedData) as Map<String, dynamic>;
    
    // Check if it has required fields
    return importData.containsKey('version') && 
           importData.containsKey('accounts') &&
           importData['accounts'] is List;
  } catch (e) {
    return false;
  }
}
