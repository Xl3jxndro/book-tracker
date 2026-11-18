import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/services/year_summary.dart';
import 'package:book_tracker/widgets/year_summary_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

int _id = 1;
Book _book({String title = 'Libro', String? category, DateTime? finishedAt, int status = 2}) => Book(
      id: _id++,
      title: title,
      author: 'Autor',
      totalPages: 300,
      readPages: status == 2 ? 300 : 50,
      totalReadTime: 0,
      status: status,
      category: category,
      finishedAt: finishedAt,
    );

ReadingSession _session(int bookId, DateTime date, {int seconds = 600, int pages = 20}) =>
    ReadingSession(id: _id++, bookId: bookId, seconds: seconds, pagesRead: pages, date: date);

void main() {
  group('resumen del año', () {
    test('cuenta solo lo del año: libros, páginas, tiempo y días', () {
      final a = _book(finishedAt: DateTime(2026, 3, 1), category: 'Fantasía');
      final b = _book(finishedAt: DateTime(2025, 12, 30), category: 'Ensayo');
      final s = YearSummary.compute(
        year: 2026,
        books: [a, b],
        sessions: [
          _session(a.id, DateTime(2026, 2, 1), seconds: 3600, pages: 100),
          _session(a.id, DateTime(2026, 2, 2), seconds: 1800, pages: 50),
          _session(b.id, DateTime(2025, 12, 30), seconds: 999, pages: 999), // otro año
        ],
      );
      expect(s.booksFinished, 1);
      expect(s.pagesRead, 150);
      expect(s.secondsRead, 5400);
      expect(s.readingTimeLabel, '1 h 30 min');
      expect(s.readingDays, 2);
      expect(s.recentFinished.single.id, a.id);
    });

    test('racha más larga del año (días seguidos con lectura)', () {
      final book = _book(status: 1);
      final days = [1, 2, 3, 10, 11, 12, 13, 14, 20].map((d) => _session(book.id, DateTime(2026, 5, d))).toList();
      // dos sesiones el mismo día no alargan la racha
      days.add(_session(book.id, DateTime(2026, 5, 12, 21)));
      final s = YearSummary.compute(year: 2026, books: [book], sessions: days);
      expect(s.longestStreak, 5);
      expect(s.readingDays, 9);
    });

    test('la racha cruza el cambio de mes', () {
      final book = _book(status: 1);
      final s = YearSummary.compute(year: 2026, books: [book], sessions: [
        _session(book.id, DateTime(2026, 1, 30)),
        _session(book.id, DateTime(2026, 1, 31)),
        _session(book.id, DateTime(2026, 2, 1)),
      ]);
      expect(s.longestStreak, 3);
    });

    test('género favorito: el más leído, sin contar "General"', () {
      final books = [
        _book(finishedAt: DateTime(2026, 1, 1), category: 'General'),
        _book(finishedAt: DateTime(2026, 1, 2), category: 'General'),
        _book(finishedAt: DateTime(2026, 1, 3), category: 'Fantasía'),
        _book(finishedAt: DateTime(2026, 1, 4), category: 'Fantasía'),
        _book(finishedAt: DateTime(2026, 1, 5), category: 'Ensayo'),
      ];
      expect(YearSummary.compute(year: 2026, books: books, sessions: const []).topCategory, 'Fantasía');
      expect(YearSummary.compute(year: 2026, books: books.take(2).toList(), sessions: const []).topCategory, isNull);
    });

    test('portadas: los 3 terminados más recientes', () {
      final books = List.generate(5, (i) => _book(title: 'L$i', finishedAt: DateTime(2026, 1, i + 1)));
      final s = YearSummary.compute(year: 2026, books: books, sessions: const []);
      expect(s.recentFinished.map((b) => b.title), ['L4', 'L3', 'L2']);
    });

    test('un año sin nada está vacío', () {
      expect(YearSummary.compute(year: 2026, books: const [], sessions: const []).isEmpty, isTrue);
    });
  });

  testWidgets('la tarjeta se dibuja sin desbordarse con datos grandes y sin portadas', (tester) async {
    final summary = YearSummary(
      year: 2026,
      booksFinished: 123,
      goal: 100,
      pagesRead: 1234567,
      secondsRead: 999 * 3600 + 59 * 60,
      readingDays: 365,
      longestStreak: 365,
      topCategory: 'Ciencia ficción y fantasía épica',
      recentFinished: [
        _book(title: 'Un título larguísimo que no cabe en una portada pequeña'),
        _book(title: 'Dune'),
        _book(title: 'Solaris'),
      ],
    );

    await tester.binding.setSurfaceSize(const Size(400, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Center(child: YearSummaryCard(summary: summary))));

    expect(tester.takeException(), isNull, reason: 'sin desbordamientos');
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('🏆 ¡Reto de 100 libros cumplido!'), findsOneWidget);
    expect(find.text('1.234.567'), findsOneWidget);
    expect(find.text('999 h 59 min'), findsOneWidget);
    expect(find.text('Género favorito: Ciencia ficción y fantasía épica'), findsOneWidget);
    expect(find.text('Book Tracker'), findsOneWidget);
  });
}
