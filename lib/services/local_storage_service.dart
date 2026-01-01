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
}
