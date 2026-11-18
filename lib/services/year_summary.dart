import '../database/database.dart';
import 'reading_challenge.dart';

/// Resumen de un año de lectura para la tarjeta que se comparte.
class YearSummary {
  final int year;
  final int booksFinished;

  /// Meta del reto anual (null si no hay reto).
  final int? goal;
  final int pagesRead;
  final int secondsRead;
  final int readingDays;
  final int longestStreak;
  final String? topCategory;

  /// Últimos libros terminados (el más reciente primero), para las portadas.
  final List<Book> recentFinished;

  const YearSummary({
    required this.year,
    required this.booksFinished,
    required this.goal,
    required this.pagesRead,
    required this.secondsRead,
    required this.readingDays,
    required this.longestStreak,
    required this.topCategory,
    required this.recentFinished,
  });

  bool get isEmpty => booksFinished == 0 && pagesRead == 0 && secondsRead == 0;

  /// "12 h 30 min", "45 min"…
  String get readingTimeLabel {
    final minutes = secondsRead ~/ 60;
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60, m = minutes % 60;
    return m == 0 ? '$h h' : '$h h $m min';
  }

  static YearSummary compute({
    required int year,
    required List<Book> books,
    required List<ReadingSession> sessions,
    int? goal,
    int maxCovers = 3,
  }) {
    final yearSessions = sessions.where((s) => s.date.year == year).toList();
    final finished = ReadingChallenge.finishedIn(books, year);

    final days = yearSessions
        .map((s) => DateTime(s.date.year, s.date.month, s.date.day))
        .toSet()
        .toList()
      ..sort();

    var longest = 0, current = 0;
    DateTime? previous;
    for (final day in days) {
      current = (previous != null && day.difference(previous).inDays == 1) ? current + 1 : 1;
      if (current > longest) longest = current;
      previous = day;
    }

    // Género más leído entre los terminados del año (o, si no hay, entre los leídos)
    final source = finished.isNotEmpty
        ? finished
        : books.where((b) => yearSessions.any((s) => s.bookId == b.id)).toList();
    final counts = <String, int>{};
    for (final b in source) {
      final category = (b.category ?? 'General').trim();
      if (category.isEmpty || category.toLowerCase() == 'general') continue;
      counts[category] = (counts[category] ?? 0) + 1;
    }
    final top = counts.entries.isEmpty
        ? null
        : (counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key;

    return YearSummary(
      year: year,
      booksFinished: finished.length,
      goal: goal,
      pagesRead: yearSessions.fold(0, (sum, s) => sum + s.pagesRead),
      secondsRead: yearSessions.fold(0, (sum, s) => sum + s.seconds),
      readingDays: days.length,
      longestStreak: longest,
      topCategory: top,
      recentFinished: finished.take(maxCovers).toList(),
    );
  }
}
