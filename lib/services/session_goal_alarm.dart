import 'notification_service.dart';
import 'session_goal.dart';
import 'timer_persistence.dart';

/// Decide si hay que avisar de la meta de la sesión y cuándo.
class SessionGoalAlarm {
  /// Segundos hasta cumplir la meta, o null si no hay que avisar: sin sesión,
  /// en pausa, sin meta de tiempo o ya cumplida.
  static int? secondsUntilGoal(PersistedSession? session, SessionGoal? goal) {
    if (session == null || session.isPaused || goal == null || !goal.isTime) return null;
    final rest = goal.remainingSeconds(session.elapsedSeconds);
    return rest > 0 ? rest : null;
  }

  /// Programa (o cancela) la notificación según la sesión guardada. Se usa al
  /// salir de la app y desde el widget en segundo plano (pausar/reanudar).
  /// Con la app abierta el aviso lo da la propia pantalla.
  static Future<void> sync() async {
    await NotificationService.ensureInitialized();
    final session = await TimerPersistence.getActiveSession();
    final goal = await TimerPersistence.getGoal();
    final seconds = secondsUntilGoal(session, goal);
    if (seconds == null) {
      await NotificationService.cancelSessionGoal();
    } else {
      await NotificationService.scheduleSessionGoal(minutes: goal!.minutes!, inSeconds: seconds);
    }
  }
}
