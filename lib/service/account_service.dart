import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../model/account.dart';

final storage = FlutterSecureStorage();

class AccountService {

  static const _accountKey = 'account_';
  /// Add a new account to secure storage
  /// 
  /// [account] - The account to add
  /// Returns the storage key used for the account
  static Future<String> addAccount(Account account) async {
    try {
      // Generate a unique key for the account
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final key = '${_accountKey}${account.app.toLowerCase()}_${account.username}';
      
      // Save the account to secure storage
      await storage.write(
        key: key, 
        value: jsonEncode(account.toJson())
      );
      
      return key;
    } catch (e) {
      throw Exception('Failed to add account: $e');
    }
  }

  /// Save/Update an existing account in secure storage
  /// 
  /// [account] - The account to save/update
  /// [key] - The storage key for the account (required for updates)
  static Future<void> saveAccount(Account account, {String? key}) async {
    try {
      // If no key provided, generate a new one (for new accounts)
      final storageKey = key ?? '${_accountKey}${account.app.toLowerCase()}_${account.username}';
      
      await storage.write(
        key: storageKey, 
        value: jsonEncode(account.toJson())
      );
    } catch (e) {
      throw Exception('Failed to save account: $e');
    }
  }

  /// Load all accounts for a specific app
  /// 
  /// [appId] - The app ID to filter accounts by (null for all accounts)
  /// Returns a list of accounts
  static Future<List<Account>> loadAccounts({String? appId}) async {
    try {
      final all = await storage.readAll();
      final filteredEntries = all.entries.where((e) => 
        e.key.startsWith('${_accountKey}${appId ?? ''}')
      );
      
      final accounts = <Account>[];
      
      for (final entry in filteredEntries) {
        try {
          // Check if value is null or empty
          if (entry.value == null || entry.value.isEmpty) {
            print('Warning: Found null or empty account data for key: ${entry.key}');
            continue;
          }
          
          // Parse the JSON string
          final jsonMap = jsonDecode(entry.value) as Map<String, dynamic>;
          final account = Account.fromJson(jsonMap);
          accounts.add(account);
        } catch (parseError) {
          print('Error parsing account data for key ${entry.key}: $parseError');
          print('Raw data: ${entry.value}');
          // Continue with other accounts
        }
      }
      
      return accounts;
    } catch (e) {
      print('Error loading accounts: $e');
      return [];
    }
  }

  /// Load a specific account by its storage key
  /// 
  /// [key] - The storage key for the account
  /// Returns the account if found, null otherwise
  static Future<Account?> loadAccountByKey(String key) async {
    try {
      final value = await storage.read(key: key);
      
      if (value == null || value.isEmpty) {
        return null;
      }
      
      final jsonMap = jsonDecode(value) as Map<String, dynamic>;
      return Account.fromJson(jsonMap);
    } catch (e) {
      print('Error loading account by key $key: $e');
      return null;
    }
  }

  /// Delete an account by its storage key
  /// 
  /// [key] - The storage key for the account to delete
  static Future<void> deleteAccount(String key) async {
    try {
      await storage.delete(key: key);
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Delete all accounts for a specific app
  /// 
  /// [appId] - The app ID to delete accounts for
  static Future<void> deleteAllAccountsForApp(String appId) async {
    try {
      final all = await storage.readAll();
      final accountKeys = all.keys.where((key) => 
        key.startsWith('${_accountKey}${appId.toLowerCase()}')
      );
      
      for (final key in accountKeys) {
        await storage.delete(key: key);
      }
    } catch (e) {
      throw Exception('Failed to delete accounts for app: $e');
    }
  }

  /// Get all account storage keys for a specific app
  /// 
  /// [appId] - The app ID to get keys for (null for all apps)
  /// Returns a list of storage keys
  static Future<List<String>> getAccountKeys({String? appId}) async {
    try {
      final all = await storage.readAll();
      return all.keys.where((key) => 
        key.startsWith('${_accountKey}${appId ?? ''}')
      ).toList();
    } catch (e) {
      print('Error getting account keys: $e');
      return [];
    }
  }

  /// Check if an account exists for a specific app and username
  /// 
  /// [appId] - The app ID
  /// [username] - The username to check
  /// Returns true if account exists, false otherwise
  static Future<bool> accountExists(String appId, String username) async {
    try {
      final accounts = await loadAccounts(appId: appId);
      return accounts.any((account) => 
        account.username.toLowerCase() == username.toLowerCase()
      );
    } catch (e) {
      print('Error checking if account exists: $e');
      return false;
    }
  }

  /// Get account count for a specific app
  /// 
  /// [appId] - The app ID to count accounts for (null for all apps)
  /// Returns the number of accounts
  static Future<int> getAccountCount({String? appId}) async {
    try {
      final accounts = await loadAccounts(appId: appId);
      return accounts.length;
    } catch (e) {
      print('Error getting account count: $e');
      return 0;
    }
  }
}
