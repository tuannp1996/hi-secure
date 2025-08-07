import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/app.dart';

class AppStorage {
  static const _appsKey = 'apps';
  static const _initializedKey = 'apps_initialized';

  Future<void> saveApps(List<App> apps) async {
    final prefs = await SharedPreferences.getInstance();
    final appJsonList = apps.map((app) => jsonEncode(app.toJson())).toList();
    await prefs.setStringList(_appsKey, appJsonList);
  }

  Future<List<App>> getApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final appJsonList = prefs.getStringList(_appsKey) ?? [];
      return appJsonList.map((jsonStr) {
        try {
          final map = jsonDecode(jsonStr);
          return App.fromJson(map);
        } catch (e) {
          print('Error parsing app JSON: $e');
          // Return a default app if parsing fails
          return App(
            id: 'error_${DateTime.now().millisecondsSinceEpoch}',
            name: 'Error App',
            url: '',
            packageName: null,
          );
        }
      }).toList();
    } catch (e) {
      print('Error getting apps: $e');
      return [];
    }
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

  Future<void> initializeDefaultApps() async {
    final prefs = await SharedPreferences.getInstance();
    final isInitialized = prefs.getBool(_initializedKey) ?? false;
    
    if (!isInitialized) {
      final defaultApps = [
        App(
          id: 'facebook',
          name: 'Facebook',
          url: 'https://facebook.com',
          packageName: 'com.facebook.katana',
        ),
        App(
          id: 'google',
          name: 'Google',
          url: 'https://google.com',
          packageName: 'com.google.android.googlequicksearchbox',
        ),
        App(
          id: 'tiktok',
          name: 'TikTok',
          url: 'https://tiktok.com',
          packageName: 'com.zhiliaoapp.musically',
        ),
      ];
      
      await saveApps(defaultApps);
      await prefs.setBool(_initializedKey, true);
    }
  }
}
