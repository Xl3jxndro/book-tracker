import '../database/database.dart';

/// Lo leído en un libro durante un día.
class BookDayReading {
  final int bookId;
  final int seconds;
  final int pages;
  const BookDayReading(this.bookId, this.seconds, this.pages);
}

/// Lo leído en un día (sumando todas sus sesiones).
class DayReading {
  final DateTime day;
  final int seconds;
  final int pages;

  /// Por libro, de más a menos tiempo.
  final List<BookDayReading> books;

  const DayReading(this.day, this.seconds, this.pages, this.books);

  bool get hasReading => seconds > 0 || pages > 0;
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Sesiones agrupadas por día (y por libro dentro de cada día).
Map<DateTime, DayReading> readingByDay(Iterable<ReadingSession> sessions) {
  final perDay = <DateTime, Map<int, (int, int)>>{};
  for (final s in sessions) {
    final books = perDay.putIfAbsent(_dateOnly(s.date), () => {});
    final (seconds, pages) = books[s.bookId] ?? (0, 0);
    books[s.bookId] = (seconds + s.seconds, pages + s.pagesRead);
  }
  return {
    for (final MapEntry(key: day, value: books) in perDay.entries)
      day: () {
        final list = [for (final MapEntry(key: id, value: (sec, pag)) in books.entries) BookDayReading(id, sec, pag)]
          ..sort((a, b) => b.seconds != a.seconds ? b.seconds.compareTo(a.seconds) : b.pages.compareTo(a.pages));
        return DayReading(
          day,
          list.fold(0, (sum, b) => sum + b.seconds),
          list.fold(0, (sum, b) => sum + b.pages),
          list,
        );
      }(),
  };
}

/// Intensidad del color de un día (0 = nada, 4 = mucho), por minutos
/// leídos; si solo se anotaron páginas (sin cronómetro), por páginas.
int readingLevel(DayReading? day) {
  if (day == null || !day.hasReading) return 0;
  if (day.seconds > 0) {
    final minutes = day.seconds / 60;
    if (minutes >= 60) return 4;
    if (minutes >= 30) return 3;
    if (minutes >= 15) return 2;
    return 1;
  }
  if (day.pages >= 50) return 4;
  if (day.pages >= 25) return 3;
  if (day.pages >= 10) return 2;
  return 1;
}

/// Días del mes en una cuadrícula que empieza en lunes: `null` en los
/// huecos antes del día 1 y después del último (filas completas de 7).
List<DateTime?> monthGrid(int year, int month) {
  final first = DateTime(year, month);
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final leading = first.weekday - 1; // lunes = 0
  final cells = <DateTime?>[
    for (var i = 0; i < leading; i++) null,
    for (var d = 1; d <= daysInMonth; d++) DateTime(year, month, d),
  ];
  while (cells.length % 7 != 0) {
    cells.add(null);
  }
  return cells;
}

/// Resumen de un mes.
class MonthSummary {
  final int daysRead;
  final int seconds;
  final int pages;

  /// El día con más tiempo (o más páginas si no hubo cronómetro).
  final DayReading? bestDay;

  const MonthSummary(this.daysRead, this.seconds, this.pages, this.bestDay);
}

MonthSummary summarizeMonth(Map<DateTime, DayReading> days, int year, int month) {
  var daysRead = 0;
  var seconds = 0;
  var pages = 0;
  DayReading? best;
  for (final day in days.values) {
    if (day.day.year != year || day.day.month != month || !day.hasReading) continue;
    daysRead++;
    seconds += day.seconds;
    pages += day.pages;
    if (best == null ||
        day.seconds > best.seconds ||
        (day.seconds == best.seconds && day.pages > best.pages)) {
      best = day;
    }
  }
  return MonthSummary(daysRead, seconds, pages, best);
}

/// Tope redondo del eje de minutos de un gráfico: el primer valor de
/// 10, 20, 30, 60, 90, 120, 180, 240 que alcance [maxMinutes] (y luego de
/// hora en hora). Sin lecturas, 30. Siempre par: su mitad es entera.
int chartAxisMax(int maxMinutes) {
  if (maxMinutes <= 0) return 30;
  for (final step in const [10, 20, 30, 60, 90, 120, 180, 240]) {
    if (maxMinutes <= step) return step;
  }
  return ((maxMinutes + 59) ~/ 60) * 60;
}

/// "1 h 5 min", "45 min" o "0 min".
String formatReadingDuration(int seconds) {
  final minutes = seconds ~/ 60;
  if (minutes < 60) return '$minutes min';
  final rest = minutes % 60;
  return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
}
