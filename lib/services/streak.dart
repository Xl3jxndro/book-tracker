/// Racha de lectura: días seguidos con al menos una sesión.
class ReadingStreak {
  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Días distintos con lectura (sin hora).
  static Set<DateTime> daysOf(Iterable<DateTime> dates) => dates.map(_day).toSet();

  /// Días seguidos con lectura que terminan en [lastDay] (0 si ese día no hubo).
  static int endingOn(Set<DateTime> days, DateTime lastDay) {
    var check = _day(lastDay);
    var streak = 0;
    while (days.contains(check)) {
      streak++;
      // Restar un día de calendario (no 24 h, por los cambios de horario)
      check = DateTime(check.year, check.month, check.day - 1);
    }
    return streak;
  }

  /// Racha actual tal como se muestra en Estadísticas: cuenta hasta hoy si
  /// hoy ya se leyó; si no, hasta ayer (la racha sigue viva hasta medianoche).
  static int current(Iterable<DateTime> dates, DateTime now) {
    final days = daysOf(dates);
    final today = _day(now);
    if (days.contains(today)) return endingOn(days, today);
    return endingOn(days, DateTime(today.year, today.month, today.day - 1));
  }

  /// La racha más larga de la historia.
  static int best(Iterable<DateTime> dates) {
    final days = daysOf(dates).toList()..sort();
    var best = 0, run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && DateTime(prev.year, prev.month, prev.day + 1) == d) ? run + 1 : 1;
      if (run > best) best = run;
      prev = d;
    }
    return best;
  }
}

/// Aviso "racha en riesgo" que hay que programar.
class StreakRiskAlert {
  final DateTime at;
  final int streak;
  const StreakRiskAlert(this.at, this.streak);

  @override
  bool operator ==(Object other) => other is StreakRiskAlert && other.at == at && other.streak == streak;

  @override
  int get hashCode => Object.hash(at, streak);

  @override
  String toString() => 'StreakRiskAlert($at, $streak días)';
}

class StreakRisk {
  /// Racha mínima para avisar: una racha de 1 día aún no es un hábito.
  static const minStreak = 2;

  /// Calcula el próximo aviso a la hora [hour]:[minute]:
  /// - Si hoy aún no se leyó y la racha (hasta ayer) es de [minStreak]+ días,
  ///   el aviso es hoy (si esa hora aún no pasó).
  /// - Si hoy ya se leyó, la racha está a salvo hoy: el aviso queda para
  ///   mañana, por si mañana no se lee.
  /// Devuelve `null` si no hay nada que avisar.
  static StreakRiskAlert? next({
    required Iterable<DateTime> readingDates,
    required DateTime now,
    required int hour,
    required int minute,
  }) {
    final days = ReadingStreak.daysOf(readingDates);
    final today = DateTime(now.year, now.month, now.day);

    if (days.contains(today)) {
      final streak = ReadingStreak.endingOn(days, today);
      if (streak < minStreak) return null;
      return StreakRiskAlert(DateTime(now.year, now.month, now.day + 1, hour, minute), streak);
    }

    final streak = ReadingStreak.endingOn(days, DateTime(now.year, now.month, now.day - 1));
    if (streak < minStreak) return null;
    final at = DateTime(now.year, now.month, now.day, hour, minute);
    return at.isAfter(now) ? StreakRiskAlert(at, streak) : null;
  }

  static String title(int streak) => '🔥 Tu racha de $streak días está en riesgo';
  static const body = 'Aún no has leído hoy. Lee unos minutos antes de medianoche para no perderla.';
}
