import 'package:hive_ce_flutter/hive_flutter.dart';

class LocalStorageService {
  static const String _boxName = 'game_settings';
  static const String _highScoreKey = 'high_score';
  static const String _soundEnabledKey = 'sound_enabled';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_boxName);
  }

  static Box get _box => Hive.box(_boxName);

  // High Score
  static int getHighScore() {
    return _box.get(_highScoreKey, defaultValue: 0);
  }

  static Future<void> saveHighScore(int score) async {
    await _box.put(_highScoreKey, score);
  }

  // Sound Status
  static bool getSoundEnabled() {
    return _box.get(_soundEnabledKey, defaultValue: true);
  }

  static Future<void> saveSoundEnabled(bool enabled) async {
    await _box.put(_soundEnabledKey, enabled);
  }

  // Game State Persistence
  static const String _gameStateKey = 'saved_game_state';

  static Future<void> saveGameState(Map<String, dynamic> state) async {
    await _box.put(_gameStateKey, state);
  }

  static Map<String, dynamic>? getGameState() {
    final data = _box.get(_gameStateKey);
    if (data != null) {
      // Hive returns LinkedMap, convert to Map<String, dynamic>
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  static Future<void> clearGameState() async {
    await _box.delete(_gameStateKey);
  }
}
