import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

/// Persists and exposes the active customer vs business experience.
class AppModeService extends ChangeNotifier {
  AppModeService._();
  static final AppModeService instance = AppModeService._();

  static const _modeKey = 'wtva_app_mode';

  AppMode? _mode;
  bool _loaded = false;

  AppMode? get mode => _mode;
  bool get isLoaded => _loaded;
  bool get hasMode => _mode != null;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _mode = AppMode.fromPrefsKey(prefs.getString(_modeKey));
    _loaded = true;
    notifyListeners();
  }

  Future<void> setMode(AppMode mode) async {
    _mode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.prefsKey);
    notifyListeners();
  }

  Future<void> clearMode() async {
    _mode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_modeKey);
    notifyListeners();
  }
}
