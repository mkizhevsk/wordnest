import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static const String _keySelectedDeckId = "selectedDeckId";
  static const String _keyIsFirstLaunch = "isFirstLaunch";

  // Singleton pattern to ensure only one instance of SharedPreferences is used
  static final PreferencesService _instance = PreferencesService._internal();

  factory PreferencesService() {
    return _instance;
  }

  PreferencesService._internal();

  Future<SharedPreferences> _getPreferences() async {
    return await SharedPreferences.getInstance();
  }

  // Save selected deckId
  Future<void> saveSelectedDeckId(int deckId) async {
    final prefs = await _getPreferences();
    await prefs.setInt(_keySelectedDeckId, deckId);
  }

  // Get selected deckId
  Future<int?> getSelectedDeckId() async {
    final prefs = await _getPreferences();
    return prefs.getInt(_keySelectedDeckId);
  }

  // Check if it's the first launch
  Future<bool> isFirstLaunch() async {
    final prefs = await _getPreferences();
    final isFirstLaunch = prefs.getBool(_keyIsFirstLaunch) ?? true;

    if (isFirstLaunch) {
      await prefs.setBool(_keyIsFirstLaunch, false);
    }
    return isFirstLaunch;
  }

  // Clear all preferences (optional)
  Future<void> clearPreferences() async {
    final prefs = await _getPreferences();
    await prefs.clear();
  }
}
