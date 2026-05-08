import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English
  
  Locale get locale => _locale;
  
  LanguageProvider() {
    _loadLanguage();
  }
  
  // Load saved language from SharedPreferences
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('language_code') ?? 'en';
    _locale = Locale(languageCode);
    notifyListeners();
  }
  
  // Change language and save to SharedPreferences
  Future<void> setLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;
    
    _locale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', languageCode);
    notifyListeners();
  }
  
  // Get current language name
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'en':
        return 'English';
      case 'sw':
        return 'Kiswahili';
      default:
        return 'English';
    }
  }
  
  // Get flag asset path
  String get currentLanguageFlag {
    switch (_locale.languageCode) {
      case 'en':
        return 'assets/images/flags/en.png';
      case 'sw':
        return 'assets/images/flags/sw.png';
      default:
        return 'assets/images/flags/en.png';
    }
  }
  
  bool get isEnglish => _locale.languageCode == 'en';
  bool get isKiswahili => _locale.languageCode == 'sw';
}
