import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Meta de libros para un año (null = sin reto). Una por año, para que el
/// historial de años anteriores conserve su propia meta.
final yearlyGoalProvider = NotifierProvider.family<YearlyGoalNotifier, int?, int>(YearlyGoalNotifier.new);

class YearlyGoalNotifier extends Notifier<int?> {
  final int year;
  static const suggestions = [6, 12, 24, 52];
  static const maxGoal = 999;

  YearlyGoalNotifier(this.year);

  @override
  int? build() {
    _load();
    return null;
  }

  static String prefsKey(int year) => 'yearly_goal_$year';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getInt(prefsKey(year));
      if (ref.mounted && saved != null && saved > 0) state = saved;
    } catch (e) {
      debugPrint('Error cargando reto anual: $e');
    }
  }

  Future<void> setGoal(int? goal) async {
    final value = (goal == null || goal <= 0) ? null : goal.clamp(1, maxGoal);
    state = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (value == null) {
        await prefs.remove(prefsKey(year));
      } else {
        await prefs.setInt(prefsKey(year), value);
      }
    } catch (e) {
      debugPrint('Error guardando reto anual: $e');
    }
  }
}
