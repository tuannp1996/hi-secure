import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app.dart';

class AppStorage {
  static const _appsKey = 'apps';

  Future<void> saveApps(List<App> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final appJsonList = apps.map((app) => jsonEncode(app.toJson())).toList();
    await prefs.setStringList(_appsKey, appJsonList);
  }

  Future<List<App>> getApps() async {
    final prefs = await SharedPreferences.getInstance();
    final appJsonList = prefs.getStringList(_appsKey) ?? [];
    return appJsonList.map((jsonStr) {
      final map = jsonDecode(jsonStr);
      return App.fromJson(map);
    }).toList();
  }

  Future<void> addApp(App app) async {
    final apps = await getApps();
    apps.add(app);
    await saveApps(apps);
  }

  Future<void> updateApp(App updatedApp) async {
    final apps = await getApps();
    final index = apps.indexWhere((app) => app.id == updatedApp.id);
    
    if (index == -1) {
      throw Exception('App not found');
    }
    
    apps[index] = updatedApp;
    await saveApps(apps);
  }

  Future<void> deleteApp(String id) async {
    final apps = await getApps();
    final updated = apps.where((a) => a.id != id).toList();
    await saveApps(updated);
  }

  Future<void> clearApps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appsKey);
  }
}
