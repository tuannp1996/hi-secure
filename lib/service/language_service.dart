import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'selected_language';
  static const String _localeKey = 'selected_locale';
  
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'vi': 'Vietnamese',
  };
  
  static const Map<String, String> supportedLocales = {
    'en': 'en_US',
    'vi': 'vi_VN',
  };

  // Get current language code
  static Future<String> getCurrentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'en';
  }

  // Get current locale
  static Future<Locale> getCurrentLocale() async {
    final languageCode = await getCurrentLanguage();
    return Locale(languageCode);
  }

  // Set language
  static Future<void> setLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // Get supported locales for the app
  static List<Locale> getSupportedLocales() {
    return supportedLanguages.keys.map((code) => Locale(code)).toList();
  }

  // Get language name by code
  static String getLanguageName(String languageCode) {
    return supportedLanguages[languageCode] ?? 'English';
  }

  // Get all available languages
  static Map<String, String> getAvailableLanguages() {
    return Map.from(supportedLanguages);
  }
}
