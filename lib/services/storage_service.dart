import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _viewModeKey = 'view_mode';
  static const String _sortOrderKey = 'sort_order';
  static const String _themeKey = 'theme_mode';
  static const String _domainKey = 'api_domain';
  static const String _apiTokenKey = 'api_token';
  static const String _isAuthenticatedKey = 'is_authenticated';

  // Default values
  static const String defaultDomain = 'https://notes.shubham-shah.com.np';
  static const String defaultToken =
      '0a8b8ed7914bb429b1109383e5e370d77a589b9062d07da8770c5def53fb06cc';

  Future<void> setViewMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_viewModeKey, mode);
  }

  Future<String> getViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_viewModeKey) ?? 'grid';
  }

  Future<void> setSortOrder(String order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortOrderKey, order);
  }

  Future<String> getSortOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sortOrderKey) ?? 'updated_desc';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, mode);
  }

  Future<String> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'system';
  }

  // Domain management
  Future<void> setDomain(String domain) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_domainKey, domain);
  }

  Future<String> getDomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_domainKey) ?? defaultDomain;
  }

  // API Token management
  Future<void> setApiToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiTokenKey, token);
  }

  Future<String> getApiToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiTokenKey) ?? defaultToken;
  }

  // Authentication state
  Future<void> setAuthenticated(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isAuthenticatedKey, value);
  }

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isAuthenticatedKey) ?? false;
  }

  // Clear all data (logout)
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiTokenKey);
    await prefs.setBool(_isAuthenticatedKey, false);
  }
}
