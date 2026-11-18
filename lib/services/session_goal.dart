/// Meta de una sesión de lectura: minutos o llegar a una página.
class SessionGoal {
  /// Minutos a leer en la sesión (null si la meta es de páginas).
  final int? minutes;

  /// Página a la que llegar (null si la meta es de tiempo).
  final int? untilPage;

  const SessionGoal.time(int this.minutes) : untilPage = null;
  const SessionGoal.page(int this.untilPage) : minutes = null;

  static const timeOptions = [15, 30, 45, 60];

  bool get isTime => minutes != null;

  int get goalSeconds => (minutes ?? 0) * 60;

  /// Progreso de una meta de tiempo, de 0 a 1.
  double progress(int elapsedSeconds) =>
      isTime && goalSeconds > 0 ? (elapsedSeconds / goalSeconds).clamp(0.0, 1.0).toDouble() : 0;

  bool timeReached(int elapsedSeconds) => isTime && elapsedSeconds >= goalSeconds;

  /// Segundos que faltan para cumplir la meta de tiempo (0 si ya se cumplió).
  int remainingSeconds(int elapsedSeconds) {
    if (!isTime) return 0;
    final rest = goalSeconds - elapsedSeconds;
    return rest > 0 ? rest : 0;
  }

  bool pageReached(int page) => untilPage != null && page >= untilPage!;

  /// "30 min" o "hasta la pág. 150".
  String get label => isTime ? '$minutes min' : 'hasta la pág. $untilPage';

  /// "18 / 30 min".
  String timeProgressLabel(int elapsedSeconds) => '${elapsedSeconds ~/ 60} / $minutes min';

  /// Formato para guardarla: "t:30" o "p:150".
  String encode() => isTime ? 't:$minutes' : 'p:$untilPage';

  static SessionGoal? decode(String? raw) {
    if (raw == null || raw.length < 3 || raw[1] != ':') return null;
    final value = int.tryParse(raw.substring(2));
    if (value == null || value <= 0) return null;
    return switch (raw[0]) {
      't' => SessionGoal.time(value),
      'p' => SessionGoal.page(value),
      _ => null,
    };
  }

  @override
  bool operator ==(Object other) => other is SessionGoal && other.minutes == minutes && other.untilPage == untilPage;

  @override
  int get hashCode => Object.hash(minutes, untilPage);

  @override
  String toString() => 'SessionGoal($label)';
}
