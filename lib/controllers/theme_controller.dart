import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'app_theme';

  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;

  // Track if SharedPreferences is working
  bool _useInMemoryFallback = false;

  ThemeMode get themeMode => _themeMode.value;
  bool get isDarkMode => _themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool(_themeKey) ?? false;
      _themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
      debugPrint(
        'Theme loaded successfully from SharedPreferences: ${isDark ? "Dark" : "Light"}',
      );
    } catch (e) {
      // If SharedPreferences fails, use in-memory fallback
      _useInMemoryFallback = true;
      _themeMode.value = ThemeMode.light;
      debugPrint(
        'SharedPreferences failed, using in-memory fallback (defaulting to light): $e',
      );
    }
  }

  void toggleTheme() {
    try {
      final isDark = _themeMode.value == ThemeMode.dark;
      final newTheme = isDark ? ThemeMode.light : ThemeMode.dark;

      debugPrint(
        'Toggling theme from ${isDark ? "Dark" : "Light"} to ${!isDark ? "Dark" : "Light"}',
      );

      // Update theme immediately
      _themeMode.value = newTheme;

      // Try to save to SharedPreferences, fall back to in-memory if it fails
      if (!_useInMemoryFallback) {
        _saveTheme(!isDark).catchError((error) {
          debugPrint(
            'SharedPreferences failed, switching to in-memory mode: $error',
          );
          _useInMemoryFallback = true;
        });
      } else {
        debugPrint(
          'Using in-memory theme storage (SharedPreferences unavailable)',
        );
      }
    } catch (e) {
      debugPrint('Error toggling theme: $e');
      _showError('Failed to change theme: ${e.toString()}');
    }
  }

  Future<void> _saveTheme(bool isDark) async {
    try {
      debugPrint(
        'Attempting to save theme preference: ${isDark ? "Dark" : "Light"}',
      );

      final prefs = await SharedPreferences.getInstance();
      final success = await prefs.setBool(_themeKey, isDark);

      if (success) {
        debugPrint(
          'Theme preference saved successfully: ${isDark ? "Dark" : "Light"}',
        );
      } else {
        debugPrint('SharedPreferences.setBool returned false');
      }

      // Verify the save by reading it back
      final savedValue = prefs.getBool(_themeKey);
      debugPrint('Verification: saved value is $savedValue, expected $isDark');
    } catch (e) {
      debugPrint('Failed to save theme preference: $e');
      debugPrint('Error type: ${e.runtimeType}');
      // Don't rethrow since we don't want to show error to user
      // The theme change has already been applied successfully
    }
  }

  void _showError(String message) {
    // Only show critical errors, not preference saving errors
    debugPrint('Critical error: $message');
    if (Get.context != null) {
      Get.snackbar(
        'Theme Error',
        message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.8),
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }
}
