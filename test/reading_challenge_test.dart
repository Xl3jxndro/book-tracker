import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/providers/yearly_goal_provider.dart';
import 'package:book_tracker/services/reading_challenge.dart';
import 'package:book_tracker/widgets/reading_challenge_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

int _nextId = 1;
Book _book({int status = 2, DateTime? finishedAt, String title = 'Libro'}) => Book(
      id: _nextId++,
      title: title,
      author: 'Autor',
      totalPages: 100,
      readPages: status == 2 ? 100 : 10,
      totalReadTime: 0,
      status: status,
      finishedAt: finishedAt,
    );

void main() {
  group('cálculo del reto', () {
    test('cuenta solo los libros terminados en el año (incluidas relecturas en curso)', () {
      final books = [
        _book(finishedAt: DateTime(2026, 2, 1)),
        _book(finishedAt: DateTime(2026, 10, 1)),
        _book(finishedAt: DateTime(2025, 12, 31)),
        _book(status: 1, finishedAt: DateTime(2026, 5, 5)), // releyéndolo: la lectura anterior cuenta
        _book(status: 2), // terminado sin fecha: no cuenta
        _book(status: 1),
      ];
      expect(ReadingChallenge.finishedIn(books, 2026), hasLength(3));
      expect(ReadingChallenge.finishedIn(books, 2025), hasLength(1));
      expect(ReadingChallenge.finishedWithoutDate(books), 1);
      expect(ReadingChallenge.finishedByYear(books).keys, [2026, 2025]);
    });

    test('a mitad de año con la mitad de la meta: al día', () {
      final books = List.generate(12, (i) => _book(finishedAt: DateTime(2026, 1, i + 1)));
      final p = ReadingChallenge.progress(goal: 24, books: books, now: DateTime(2026, 7, 2));
      expect(p.finished, 12);
      expect(p.message, 'Vas al día');
      expect(p.fraction, 0.5);
    });

    test('adelantado y atrasado, en singular y plural', () {
      // 1 de julio: día 182 de 365 → tocan 5,98 de 12. Solo cuenta como
      // adelantado/atrasado una diferencia de al menos un libro completo.
      final now = DateTime(2026, 7, 1);
      List<Book> n(int count) => List.generate(count, (i) => _book(finishedAt: DateTime(2026, 1, i + 1)));

      expect(ReadingChallenge.progress(goal: 12, books: n(7), now: now).message, 'Vas 1 libro adelantado');
      expect(ReadingChallenge.progress(goal: 12, books: n(9), now: now).message, 'Vas 3 libros adelantado');
      expect(ReadingChallenge.progress(goal: 12, books: n(5), now: now).message, 'Vas al día');
      expect(ReadingChallenge.progress(goal: 12, books: n(4), now: now).message, 'Vas 1 libro atrasado');
      expect(ReadingChallenge.progress(goal: 12, books: n(2), now: now).message, 'Vas 3 libros atrasado');
    });

    test('cumplido y superado', () {
      List<Book> n(int count) => List.generate(count, (i) => _book(finishedAt: DateTime(2026, 1, i + 1)));
      final done = ReadingChallenge.progress(goal: 3, books: n(3), now: DateTime(2026, 4, 1));
      expect(done.isCompleted, isTrue);
      expect(done.message, '¡Reto cumplido!');
      expect(ReadingChallenge.progress(goal: 3, books: n(5), now: DateTime(2026, 4, 1)).message, '¡Reto superado! +2');
    });

    test('año bisiesto: el 31 de diciembre toca la meta completa', () {
      final p = ReadingChallenge.progress(goal: 366, books: const [], now: DateTime(2028, 12, 31));
      expect(p.expected, 366);
    });
  });

  group('meta por año', () {
    test('se guarda por año y se puede quitar', () async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(yearlyGoalProvider(2026).notifier).setGoal(24);
      expect(container.read(yearlyGoalProvider(2026)), 24);
      expect(container.read(yearlyGoalProvider(2025)), isNull, reason: 'cada año tiene su meta');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt(YearlyGoalNotifier.prefsKey(2026)), 24);

      await container.read(yearlyGoalProvider(2026).notifier).setGoal(null);
      expect(container.read(yearlyGoalProvider(2026)), isNull);
      expect(prefs.getInt(YearlyGoalNotifier.prefsKey(2026)), isNull);
    });
  });

  testWidgets('tarjeta: crear el reto y ver el progreso', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('es', null);
    final year = DateTime.now().year;
    final books = [
      _book(finishedAt: DateTime(year, 1, 10), title: 'Dune'),
      _book(finishedAt: DateTime(year, 1, 20), title: 'Solaris'),
    ];

    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ReadingChallengeCard(books: books)))),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Reto de lectura $year'), findsOneWidget);
    expect(find.textContaining('Llevas 2 libros terminados'), findsOneWidget);

    await tester.tap(find.text('Crear reto'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, '6'));
    await tester.pump();
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(find.text('Reto $year'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('de 6'), findsOneWidget);
    expect(find.text('4 por leer para tu meta'), findsOneWidget);

    await tester.tap(find.text('Ver libros terminados'));
    await tester.pumpAndSettle();
    expect(find.text('Dune'), findsOneWidget);
    expect(find.text('Solaris'), findsOneWidget);
  });
}
