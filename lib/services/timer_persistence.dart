import 'package:shared_preferences/shared_preferences.dart';

import 'session_goal.dart';

/// Sesión de lectura (cronómetro) guardada en disco.
///
/// Es la fuente única de verdad del cronómetro: la usan la app y el widget de
/// pantalla de inicio (que puede pausar/reanudar desde un isolate en segundo plano).
class PersistedSession {
  final int bookId;
  final bool isPaused;

  /// Segundos acumulados hasta [runningSince] (o hasta la pausa).
  final int accumulatedSeconds;

  /// Momento desde el que corre el cronómetro. `null` si está en pausa.
  final DateTime? runningSince;

  const PersistedSession({
    required this.bookId,
    required this.isPaused,
    required this.accumulatedSeconds,
    required this.runningSince,
  });

  /// Segundos totales a día de hoy (incluye el tramo que está corriendo).
  int get elapsedSeconds {
    if (isPaused || runningSince == null) return accumulatedSeconds;
    final extra = DateTime.now().difference(runningSince!).inSeconds;
    return accumulatedSeconds + (extra > 0 ? extra : 0);
  }
}

class TimerPersistence {
  static const _keyStartTime = 'reading_start_time';
  static const _keyBookId = 'reading_book_id';
  static const _keyIsPaused = 'reading_is_paused';
  static const _keyAccumulatedSeconds = 'reading_accumulated';
  static const _keyGoal = 'reading_session_goal';
  static const _keyLastTimeGoal = 'session_goal_last_minutes';

  /// Siempre recarga desde disco: otro isolate (el widget) puede haber escrito.
  static Future<SharedPreferences> _prefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    return prefs;
  }

  // Guarda o actualiza la sesión
  static Future<void> saveSession({
    required int bookId,
    required bool isPaused,
    required int accumulatedSeconds
  }) async {
    final prefs = await _prefs();

    await prefs.setInt(_keyBookId, bookId);
    await prefs.setBool(_keyIsPaused, isPaused);
    await prefs.setInt(_keyAccumulatedSeconds, accumulatedSeconds);

    // Si la sesión está activa (corriendo), guardamos el "ahora" como referencia
    // para poder calcular cuánto tiempo pasó si la app se cierra.
    if (!isPaused) {
      await prefs.setInt(_keyStartTime, DateTime.now().millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyStartTime);
    }
  }

  static Future<PersistedSession?> getActiveSession() async {
    final prefs = await _prefs();
    final int? bookId = prefs.getInt(_keyBookId);
    if (bookId == null) return null;

    final bool isPaused = prefs.getBool(_keyIsPaused) ?? false;
    final int? startTimeMillis = prefs.getInt(_keyStartTime);

    return PersistedSession(
      bookId: bookId,
      // Sin hora de inicio no se puede saber cuánto corrió: se trata como pausa.
      isPaused: isPaused || startTimeMillis == null,
      accumulatedSeconds: prefs.getInt(_keyAccumulatedSeconds) ?? 0,
      runningSince: (isPaused || startTimeMillis == null)
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startTimeMillis),
    );
  }

  /// Pausa o reanuda la sesión activa (usado por el botón del widget).
  static Future<PersistedSession?> togglePause() async {
    final session = await getActiveSession();
    if (session == null) return null;

    await saveSession(
      bookId: session.bookId,
      isPaused: !session.isPaused,
      accumulatedSeconds: session.elapsedSeconds,
    );
    return getActiveSession();
  }

  static Future<void> clearSession() async {
    final prefs = await _prefs();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyBookId);
    await prefs.remove(_keyIsPaused);
    await prefs.remove(_keyAccumulatedSeconds);
    await prefs.remove(_keyGoal);
  }

  // --- Meta de la sesión ---

  /// Guarda la meta de la sesión (null = libre). Si es de tiempo, la recuerda
  /// para proponerla la próxima vez.
  static Future<void> saveGoal(SessionGoal? goal) async {
    final prefs = await _prefs();
    if (goal == null) {
      await prefs.remove(_keyGoal);
      await prefs.setInt(_keyLastTimeGoal, 0);
      return;
    }
    await prefs.setString(_keyGoal, goal.encode());
    if (goal.isTime) await prefs.setInt(_keyLastTimeGoal, goal.minutes!);
  }

  static Future<SessionGoal?> getGoal() async => SessionGoal.decode((await _prefs()).getString(_keyGoal));

  /// La última meta de tiempo elegida (null si la última vez fue libre).
  static Future<SessionGoal?> lastTimeGoal() async {
    final minutes = (await _prefs()).getInt(_keyLastTimeGoal) ?? 0;
    return minutes > 0 ? SessionGoal.time(minutes) : null;
  }
}
