import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Meta diaria de lectura en minutos. Es global (se compara con el tiempo
/// leído hoy en todos los libros) y se guarda en SharedPreferences.
final dailyGoalProvider = StateNotifierProvider<DailyGoalNotifier, int>((ref) {
  return DailyGoalNotifier();
});

class DailyGoalNotifier extends StateNotifier<int> {
  static const _key = 'daily_goal_minutes';
  static const defaultMinutes = 30;
  static const options = [15, 30, 45, 60];

  DailyGoalNotifier() : super(defaultMinutes) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(_key);
      if (saved != null && saved > 0 && mounted) state = saved;
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
