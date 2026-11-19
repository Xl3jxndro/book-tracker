import 'package:shared_preferences/shared_preferences.dart';

import 'streak.dart';

/// Oferta de "salvar la racha": ayer no se leyó y se perdió una racha.
class StreakSaveOffer {
  /// Días que tenía la racha (hasta anteayer).
  final int lostStreak;

  /// El día que se salvaría (ayer).
  final DateTime day;

  const StreakSaveOffer(this.lostStreak, this.day);

  @override
  bool operator ==(Object other) => other is StreakSaveOffer && other.lostStreak == lostStreak && other.day == day;
  @override
  int get hashCode => Object.hash(lostStreak, day);
  @override
  String toString() => 'StreakSaveOffer($lostStreak días, $day)';
}

/// Salvar la racha viendo un anuncio recompensado: el día de ayer cuenta
/// como leído para la racha (no para el tiempo, las páginas ni el mapa de
/// calor). Como mucho una vez cada [cooldownDays] días.
class StreakSave {
  static const minStreak = 2;
  static const cooldownDays = 7;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _minusDays(DateTime d, int n) => DateTime(d.year, d.month, d.day - n);

  /// ¿Se puede ofrecer hoy?
  /// - Ayer no hubo lectura (ni día salvado).
  /// - La racha que terminaba anteayer era de [minStreak]+ días.
  /// - No se salvó otra racha en los últimos [cooldownDays] días.
  /// - Hoy no se rechazó ya la oferta.
  static StreakSaveOffer? offer({
    required Iterable<DateTime> readingDates,
    required Set<DateTime> savedDays,
    required DateTime now,
    DateTime? lastSaveAt,
    DateTime? dismissedOn,
  }) {
    final today = _day(now);
    if (dismissedOn != null && _day(dismissedOn) == today) return null;
    if (lastSaveAt != null && today.difference(_day(lastSaveAt)).inDays < cooldownDays) return null;

    final days = {...ReadingStreak.daysOf(readingDates), ...savedDays.map(_day)};
    final yesterday = _minusDays(today, 1);
    if (days.contains(yesterday)) return null;

    final lost = ReadingStreak.endingOn(days, _minusDays(today, 2));
    if (lost < minStreak) return null;
    return StreakSaveOffer(lost, yesterday);
  }

  /// Fechas de lectura más los días salvados (para calcular la racha).
  static List<DateTime> withSavedDays(Iterable<DateTime> readingDates, Set<DateTime> savedDays) =>
      [...readingDates, ...savedDays];

  // --- Guardado en el teléfono ---

  static const _savedKey = 'streak_saved_days';
  static const _lastSaveKey = 'streak_last_save';
  static const _dismissedKey = 'streak_save_dismissed_on';

  static String _encode(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static DateTime? _decode(String? s) {
    if (s == null) return null;
    final p = s.split('-');
    if (p.length != 3) return null;
    final y = int.tryParse(p[0]), m = int.tryParse(p[1]), d = int.tryParse(p[2]);
    return (y == null || m == null || d == null) ? null : DateTime(y, m, d);
  }

  static Future<StreakSaveState> load() async {
    final prefs = await SharedPreferences.getInstance();
    return StreakSaveState(
      savedDays: (prefs.getStringList(_savedKey) ?? const []).map(_decode).whereType<DateTime>().toSet(),
      lastSaveAt: _decode(prefs.getString(_lastSaveKey)),
      dismissedOn: _decode(prefs.getString(_dismissedKey)),
    );
  }

  /// Marca [day] como salvado (tras ver el anuncio completo).
  static Future<StreakSaveState> save(DateTime day, {required DateTime now}) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = {...(prefs.getStringList(_savedKey) ?? const <String>[]), _encode(day)}.toList()..sort();
    await prefs.setStringList(_savedKey, saved);
    await prefs.setString(_lastSaveKey, _encode(now));
    return load();
  }

  /// "Ahora no": no volver a ofrecerla hoy.
  static Future<StreakSaveState> dismiss({required DateTime now}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedKey, _encode(now));
    return load();
  }
}

class StreakSaveState {
  final Set<DateTime> savedDays;
  final DateTime? lastSaveAt;
  final DateTime? dismissedOn;
  const StreakSaveState({this.savedDays = const {}, this.lastSaveAt, this.dismissedOn});
}
