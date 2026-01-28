import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _viewModeKey = 'view_mode';
  static const String _sortOrderKey = 'sort_order';
  static const String _themeKey = 'theme_mode';

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
}
