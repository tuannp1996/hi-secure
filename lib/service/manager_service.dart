import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../model/account.dart';

final storage = FlutterSecureStorage();

// Save
Future<void> saveAccount(Account account) async {
  final key = 'account_${account.app.toLowerCase()}';
  await storage.write(key: key, value: account.toJson().toString());
}

// Load All
Future<List<Account>> loadAllAccounts() async {
  final all = await storage.readAll();
  return all.entries
      .where((e) => e.key.startsWith('account_'))
      .map((e) {
    final map = Map<String, dynamic>.from(Uri.splitQueryString(
      e.value.replaceAll(RegExp(r'[{}]'), '').replaceAll(', ', '&'),
    ));
    return Account.fromJson(map);
  })
      .toList();
}

// Delete
Future<void> deleteAccount(String appName) async {
  await storage.delete(key: 'account_${appName.toLowerCase()}');
}
