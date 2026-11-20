import '../database/database.dart';

/// Progreso del reto anual de lectura ("leer N libros este año").
class ChallengeProgress {
  final int year;
  final int goal;
  final int finished;

  /// Libros que "tocaría" llevar a estas alturas del año para ir al día.
  final double expected;

  const ChallengeProgress({required this.year, required this.goal, required this.finished, required this.expected});

  bool get isCompleted => finished >= goal;

  double get fraction => goal <= 0 ? 0 : (finished / goal).clamp(0.0, 1.0);

  /// Positivo: adelantado; negativo: atrasado (en libros completos).
  int get booksAhead {
    final diff = finished - expected;
    return diff >= 0 ? diff.floor() : -((-diff).floor());
  }

  /// Mensaje para mostrar bajo el progreso.
  String get message {
    if (isCompleted) return finished > goal ? '¡Reto superado! +${finished - goal}' : '¡Reto cumplido!';
    final ahead = booksAhead;
    if (ahead >= 1) return 'Vas $ahead ${ahead == 1 ? 'libro' : 'libros'} adelantado';
    if (ahead <= -1) return 'Vas ${-ahead} ${ahead == -1 ? 'libro' : 'libros'} atrasado';
    return 'Vas al día';
  }
}

class ReadingChallenge {
  ReadingChallenge._();

  /// Libros cuya lectura terminó en [year]. Incluye los que se están
  /// releyendo (conservan la fecha de su lectura anterior).
  /// Libros leídos en total: los terminados, también los que se están
  /// releyendo ("Releer" conserva la fecha en que se terminaron). Mismo
  /// criterio que el reto anual.
  static int finishedCount(List<Book> books) => books.where((b) => b.status == 2 || b.finishedAt != null).length;

  static List<Book> finishedIn(List<Book> books, int year) =>
      books.where((b) => b.finishedAt != null && b.finishedAt!.year == year).toList()
        ..sort((a, b) => b.finishedAt!.compareTo(a.finishedAt!));

  /// Libros terminados agrupados por año, del más reciente al más antiguo.
  static Map<int, List<Book>> finishedByYear(List<Book> books) {
    final years = books.where((b) => b.finishedAt != null).map((b) => b.finishedAt!.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return {for (final y in years) y: finishedIn(books, y)};
  }

  /// Terminados sin fecha conocida (anteriores a esta función y sin sesiones).
  static int finishedWithoutDate(List<Book> books) =>
      books.where((b) => b.status == 2 && b.finishedAt == null).length;

  static ChallengeProgress progress({required int goal, required List<Book> books, required DateTime now}) {
    final startOfYear = DateTime(now.year);
    final daysInYear = DateTime(now.year + 1).difference(startOfYear).inDays;
    final dayOfYear = DateTime(now.year, now.month, now.day).difference(startOfYear).inDays + 1;
    return ChallengeProgress(
      year: now.year,
      goal: goal,
      finished: finishedIn(books, now.year).length,
      expected: goal * dayOfYear / daysInYear,
    );
  }
}
