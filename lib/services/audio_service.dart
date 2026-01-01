import 'package:flame_audio/flame_audio.dart';
import 'package:block_master_game/services/local_storage_service.dart';
import 'package:flutter/material.dart';

class GameAudioService {
  static const String _placeSound = 'place.wav';
  static const String _clearSound = 'clear.wav';
  static const String _gameOverSound = 'game-over.wav';

  // AudioPool obyektlari
  static late AudioPool _placePool;
  static late AudioPool _clearPool;
  // Game over kamroq bo'lgani uchun unga oddiy play ishlataveramiz

  static Future<void> init() async {
    // 1. Keshga yuklash (Game Over va boshqa uzunroq ovozlar uchun)
    await FlameAudio.audioCache.loadAll([
      _placeSound,
      _clearSound,
      _gameOverSound,
    ]);

    // 2. AudioPool yaratish (Qisqa va tez effektlar uchun)
    // Bu yerda 'await' juda muhim, u ovoz "READY" bo'lishini kutadi.
    try {
      _placePool = await FlameAudio.createPool(
        _placeSound,
        maxPlayers: 4, // Bir vaqtda 4 tagacha 'place' ovozi chiqishi mumkin
        minPlayers: 1,
      );

      _clearPool = await FlameAudio.createPool(
        _clearSound,
        maxPlayers: 2,
        minPlayers: 1,
      );
    } catch (e) {
      debugPrint("Audio init error: $e");
    }
  }

  static void playPlace() {
    if (LocalStorageService.getSoundEnabled()) {
      // start() metodi ID tayyor bo'lishini kutadi
      _placePool.start(volume: 1.0);
    }
  }

  static void playClear() {
    if (LocalStorageService.getSoundEnabled()) {
      _clearPool.start(volume: 1.0);
    }
  }

  static void playGameOver() {
    if (LocalStorageService.getSoundEnabled()) {
      FlameAudio.play(_gameOverSound);
    }
  }
}
