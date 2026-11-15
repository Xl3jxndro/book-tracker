import 'package:shared_preferences/shared_preferences.dart';

class TimerPersistence {
  static const _keyStartTime = 'reading_start_time';
  static const _keyBookId = 'reading_book_id';
  static const _keyIsPaused = 'reading_is_paused';
  static const _keyAccumulatedSeconds = 'reading_accumulated';

  // Guarda o actualiza la sesión
  static Future<void> saveSession({
    required int bookId, 
    required bool isPaused, 
    required int accumulatedSeconds
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setInt(_keyBookId, bookId);
    await prefs.setBool(_keyIsPaused, isPaused);
    await prefs.setInt(_keyAccumulatedSeconds, accumulatedSeconds);
    
    // Si la sesión está activa (corriendo), guardamos el "ahora" como referencia
    // para poder calcular cuánto tiempo pasó si la app se cierra.
    if (!isPaused) {
      await prefs.setInt(_keyStartTime, DateTime.now().millisecondsSinceEpoch);
    } else {
      // Si pausamos, eliminamos el startTime de la última vez que corrió
      await prefs.remove(_keyStartTime);
    }
  }

  static Future<Map<String, dynamic>?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final int? bookId = prefs.getInt(_keyBookId);
    
    if (bookId == null) return null;

    final bool isPaused = prefs.getBool(_keyIsPaused) ?? false;
    final int accumulated = prefs.getInt(_keyAccumulatedSeconds) ?? 0;
    final int? startTimeMillis = prefs.getInt(_keyStartTime);

    int totalSeconds = accumulated;
    
    // LÓGICA DE RECUPERACIÓN:
    // Si la app se cerró mientras el cronómetro CORRÍA (no estaba pausado),
    // calculamos la diferencia entre "ahora" y "cuando se guardó por última vez".
    if (!isPaused && startTimeMillis != null) {
      final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
      final int extraSeconds = DateTime.now().difference(startTime).inSeconds;
      totalSeconds += extraSeconds;
    }

    return {
      'bookId': bookId,
      'elapsedSeconds': totalSeconds,
      'isPaused': isPaused,
    };
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyBookId);
    await prefs.remove(_keyIsPaused);
    await prefs.remove(_keyAccumulatedSeconds);
  }
}