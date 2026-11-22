import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/services/reading_calendar.dart';
import 'package:book_tracker/widgets/reading_calendar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:material_ui/material_ui.dart';

var _id = 1;
ReadingSession _s(DateTime date, {int bookId = 1, int minutes = 0, int pages = 0}) =>
    ReadingSession(id: _id++, bookId: bookId, seconds: minutes * 60, pagesRead: pages, date: date);

Book _book(int id, String title) => Book(
      id: id,
      title: title,
      author: 'Autor',
      totalPages: 300,
      readPages: 0,
      totalReadTime: 0,
      status: 1,
    );

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  group('lecturas por día', () {
    test('suma las sesiones del mismo día y separa por libro, de más a menos tiempo', () {
      final days = readingByDay([
        _s(DateTime(2026, 11, 3, 8), bookId: 1, minutes: 10, pages: 5),
        _s(DateTime(2026, 11, 3, 21), bookId: 2, minutes: 40, pages: 20),
        _s(DateTime(2026, 11, 3, 22), bookId: 1, minutes: 5, pages: 3),
        _s(DateTime(2026, 11, 4), bookId: 1, minutes: 15),
      ]);
      final day = days[DateTime(2026, 11, 3)]!;
      expect(day.seconds, 55 * 60);
      expect(day.pages, 28);
      expect(day.books.map((b) => b.bookId), [2, 1]);
      expect(day.books.last.seconds, 15 * 60);
      expect(days.keys, hasLength(2));
    });

    test('intensidad por minutos o, sin cronómetro, por páginas', () {
      DayReading d(int minutes, int pages) => DayReading(DateTime(2026), minutes * 60, pages, const []);
      expect(readingLevel(null), 0);
      expect(readingLevel(d(0, 0)), 0);
      expect(readingLevel(d(5, 0)), 1);
      expect(readingLevel(d(15, 0)), 2);
      expect(readingLevel(d(30, 0)), 3);
      expect(readingLevel(d(90, 0)), 4);
      expect(readingLevel(d(0, 8)), 1);
      expect(readingLevel(d(0, 60)), 4);
    });
  });

  group('cuadrícula del mes', () {
    test('empieza en lunes con huecos y filas completas', () {
      // Noviembre de 2026 empieza en domingo: 6 huecos antes del día 1
      final cells = monthGrid(2026, 11);
      expect(cells.take(6), everyElement(isNull));
      expect(cells[6], DateTime(2026, 11, 1));
      expect(cells.whereType<DateTime>(), hasLength(30));
      expect(cells.length % 7, 0);
    });

    test('febrero bisiesto', () {
      expect(monthGrid(2028, 2).whereType<DateTime>(), hasLength(29));
    });
  });

  group('resumen del mes', () {
    test('cuenta días, tiempo y páginas solo de ese mes, y el mejor día', () {
      final days = readingByDay([
        _s(DateTime(2026, 11, 1), minutes: 20, pages: 10),
        _s(DateTime(2026, 11, 2), minutes: 65, pages: 30),
        _s(DateTime(2026, 10, 31), minutes: 300),
      ]);
      final summary = summarizeMonth(days, 2026, 11);
      expect(summary.daysRead, 2);
      expect(summary.seconds, 85 * 60);
      expect(summary.pages, 40);
      expect(summary.bestDay!.day, DateTime(2026, 11, 2));
      expect(summarizeMonth(days, 2026, 9).daysRead, 0);
    });

    test('formato del tiempo', () {
      expect(formatReadingDuration(0), '0 min');
      expect(formatReadingDuration(45 * 60), '45 min');
      expect(formatReadingDuration(60 * 60), '1 h');
      expect(formatReadingDuration(65 * 60), '1 h 5 min');
    });
  });

  group('calendario', () {
    Future<void> pump(WidgetTester tester, List<ReadingSession> sessions, {Set<DateTime> saved = const {}}) async {
      await tester.binding.setSurfaceSize(const Size(400, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ReadingCalendar(
                sessions: sessions,
                books: [_book(1, 'Cien años de soledad'), _book(2, 'Metamorphosis')],
                savedDays: saved,
                today: DateTime(2026, 11, 22),
              ),
            ),
          ),
        ),
      ));
    }

    testWidgets('muestra el mes, el resumen y el detalle del día al tocarlo', (tester) async {
      await pump(tester, [
        _s(DateTime(2026, 11, 10), bookId: 1, minutes: 45, pages: 20),
        _s(DateTime(2026, 11, 10), bookId: 2, minutes: 10, pages: 4),
        _s(DateTime(2026, 11, 12), bookId: 1, minutes: 20, pages: 8),
      ]);
      expect(tester.takeException(), isNull);
      expect(find.text('Noviembre 2026'), findsOneWidget);
      expect(find.text('2'), findsWidgets); // 2 días leídos
      expect(find.text('días leídos'), findsOneWidget);
      expect(find.text('1 h 15 min'), findsOneWidget);
      expect(find.textContaining('Tu mejor día: 10 de noviembre'), findsOneWidget);

      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      expect(find.text('Martes 10 de noviembre'), findsOneWidget);
      expect(find.text('Cien años de soledad'), findsOneWidget);
      expect(find.text('45 min · 20 págs.'), findsOneWidget);
      expect(find.text('Metamorphosis'), findsOneWidget);

      // Tocar de nuevo vuelve al resumen
      await tester.tap(find.text('10'));
      await tester.pumpAndSettle();
      expect(find.text('días leídos'), findsOneWidget);
    });

    testWidgets('un día sin lectura y un día con la racha salvada', (tester) async {
      await pump(tester, [_s(DateTime(2026, 11, 10), minutes: 30)], saved: {DateTime(2026, 11, 11)});
      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();
      expect(find.text('No leíste, pero salvaste tu racha este día.'), findsOneWidget);
      await tester.tap(find.text('9'));
      await tester.pumpAndSettle();
      expect(find.text('Este día no leíste.'), findsOneWidget);
    });

    testWidgets('se navega entre meses solo dentro de lo que hay', (tester) async {
      await pump(tester, [_s(DateTime(2026, 10, 5), minutes: 30), _s(DateTime(2026, 11, 3), minutes: 10)]);
      final next = find.byTooltip('Mes siguiente');
      final prev = find.byTooltip('Mes anterior');
      expect(tester.widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_right_rounded), matching: find.byType(IconButton))).onPressed, isNull,
          reason: 'no hay meses futuros');
      expect(next, findsOneWidget);

      await tester.tap(prev);
      await tester.pumpAndSettle();
      expect(find.text('Octubre 2026'), findsOneWidget);
      expect(find.text('día leído'), findsOneWidget);
      expect(tester.widget<IconButton>(find.ancestor(of: find.byIcon(Icons.chevron_left_rounded), matching: find.byType(IconButton))).onPressed, isNull,
          reason: 'no hay lecturas antes de octubre');
    });

    testWidgets('sin lecturas este mes lo dice', (tester) async {
      await pump(tester, const []);
      expect(find.text('Aún no has leído este mes. Toca un día para ver su detalle.'), findsOneWidget);
    });
  });
}
