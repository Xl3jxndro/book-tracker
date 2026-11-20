import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Meta diaria de lectura en minutos. Es global (se compara con el tiempo
/// leído hoy en todos los libros) y se guarda en SharedPreferences.
final dailyGoalProvider = NotifierProvider<DailyGoalNotifier, int>(DailyGoalNotifier.new);

class DailyGoalNotifier extends Notifier<int> {
  static const prefsKey = 'daily_goal_minutes';
  static const _key = prefsKey;
  static const defaultMinutes = 30;
  static const options = [15, 30, 45, 60];

  @override
  int build() {
    _load();
    return defaultMinutes;
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_key);
      if (saved != null && saved > 0 && ref.mounted) state = saved;
    } catch (e) {
      debugPrint('Error cargando meta diaria: $e');
    }
  }

  Future<void> setGoal(int minutes) async {
    if (minutes <= 0) return;
    state = minutes;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_key, minutes);
    } catch (e) {
      debugPrint('Error guardando meta diaria: $e');
    }
  }
}
