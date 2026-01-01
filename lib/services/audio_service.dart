import 'package:flame_audio/flame_audio.dart';
import 'package:block_master_game/services/local_storage_service.dart';

class GameAudioService {
  // MUHIM: FlameAudio avtomatik ravishda 'assets/audio/' papkasiga qaraydi.
  // Shuning uchun yo'lni to'liq yozish shart emas, faqat fayl nomi yetarli.
  static const String _placeSound = 'place.wav';
  static const String _clearSound = 'clear.wav';
  static const String _gameOverSound = 'game-over.wav';

  /// Ilova boshlanishida chaqirilishi kerak (masalan, main.dart yoki splash screenda)
  static Future<void> init() async {
    // 1. Keshga yuklash (Caching)
    // O'yin davomida qotishlar (lag) bo'lmasligi uchun ovozlarni oldindan xotiraga yuklaymiz.
    await FlameAudio.audioCache.loadAll([
      _placeSound,
      _clearSound,
      _gameOverSound,
    ]);
  }

  /// Umumiy o'ynatish funksiyasi
  static void _play(String fileName) {
    // Ovoz yoqilganligini tekshiramiz
    if (LocalStorageService.getSoundEnabled()) {
      // FlameAudio.play metodi "fire-and-forget" prinsipida ishlaydi.
      // U avtomatik ravishda bo'sh turgan playerni topadi yoki yangisini yaratadi.
      FlameAudio.play(fileName);
    }
  }

  static void playPlace() {
    _play(_placeSound);
  }

  static void playClear() {
    _play(_clearSound);
  }

  static void playGameOver() {
    _play(_gameOverSound);
  }
}
