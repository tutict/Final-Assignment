import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global, reactive theme controller.
///
/// Owns the `isDarkMode` preference key shared with the dashboard controllers
/// so persistence stays consistent across the app. Wire [GetMaterialApp] to
/// [themeMode] via `Obx` so a toggle rebuilds the whole app instead of only
/// the screen the toggle lives on.
class ThemeController extends GetxController {
  ThemeController();

  static const String kPrefKey = 'isDarkMode';

  final Rx<ThemeMode> _themeMode = ThemeMode.light.obs;
  bool _loaded = false;

  Rx<ThemeMode> get themeMode => _themeMode;
  bool get isDark => _themeMode.value == ThemeMode.dark;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  /// Loads the persisted preference. Safe to call from `main()` before
  /// `runApp` to avoid a cold-start theme flash; idempotent otherwise.
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    final prefs = await SharedPreferences.getInstance();
    final dark = prefs.getBool(kPrefKey) ?? false;
    _themeMode.value = dark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    await setMode(isDark ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> setMode(ThemeMode mode) async {
    _themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kPrefKey, mode == ThemeMode.dark);
  }
}
