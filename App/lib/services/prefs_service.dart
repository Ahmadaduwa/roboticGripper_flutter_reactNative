import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const String _keyBaseUrl = 'base_api_url';

  // Default URL depends on environment, but we'll default to localhost for now
  // Android Emulator needs 10.0.2.2 usually
  static const String _defaultUrl = 'http://10.0.2.2:8000';

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? _defaultUrl;
  }

  static Future<void> saveBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, url);
  }
}
