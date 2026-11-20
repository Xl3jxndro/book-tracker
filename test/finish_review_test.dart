import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/providers/database_provider.dart';
import 'package:book_tracker/widgets/finish_review_sheet.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Book _book({DateTime? startedAt, DateTime? finishedAt, int seconds = 0, int pages = 300, int? rating}) => Book(
      id: 1,
      title: 'Satanás',
      author: 'Mario Mendoza',
      totalPages: pages,
      readPages: pages,
      totalReadTime: seconds,
      status: 2,
      rating: rating,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

void main() {
  group('resumen al terminar', () {
    test('días, tiempo y páginas', () {
      final b = _book(startedAt: DateTime(2026, 11, 1, 22), finishedAt: DateTime(2026, 11, 12, 8), seconds: 6 * 3600 + 30 * 60, pages: 285);
      expect(finishSummary(b), 'en 12 días · 6 h 30 min de lectura · 285 páginas');
    });

    test('mismo día, horas exactas o solo minutos', () {
      final day = DateTime(2026, 11, 18);
      expect(finishSummary(_book(startedAt: day, finishedAt: day, seconds: 7200, pages: 100)), 'en 1 día · 2 h de lectura · 100 páginas');
      expect(finishSummary(_book(seconds: 45 * 60, pages: 0)), '45 min de lectura');
      expect(finishSummary(_book(pages: 0)), '');
    });
  });

  group('guardar la reseña', () {
    late AppDatabase db;
    late int id;
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      id = await db.insertBook(BooksCompanion.insert(title: 'Satanás', author: 'Mario Mendoza', totalPages: 285));
    });
    tearDown(() => db.close());

    test('calificación y nota "Mi reseña"', () async {
      await db.saveReview(id, rating: 4, text: '  Oscura y adictiva.  ');
      final book = (await db.select(db.books).get()).single;
      expect(book.rating, 4);
      final note = (await db.select(db.notes).get()).single;
      expect(note.content, 'Mi reseña: Oscura y adictiva.');
      expect(note.bookId, id);
    });

    test('sin texto no crea nota; sin estrellas no cambia la calificación', () async {
      await db.updateBook((await db.select(db.books).get()).single.copyWith(rating: const Value(3)));
      await db.saveReview(id, rating: 0, text: '   ');
      expect((await db.select(db.books).get()).single.rating, 3);
      expect(await db.select(db.notes).get(), isEmpty);
    });

    test('editar en cualquier momento: no duplica, conserva la fecha; vaciarla la borra', () async {
      await db.saveReview(id, rating: 4, text: 'Primera versión');
      final first = (await db.select(db.notes).get()).single;

      await db.saveReview(id, rating: 5, text: 'Versión corregida');
      final notes = await db.select(db.notes).get();
      expect(notes, hasLength(1), reason: 'edita la reseña existente');
      expect(notes.single.id, first.id);
      expect(notes.single.createdAt, first.createdAt);
      expect(notes.single.content, 'Mi reseña: Versión corregida');
      expect((await db.select(db.books).get()).single.rating, 5);

      await db.saveReview(id, rating: 0, text: '');
      expect(await db.select(db.notes).get(), isEmpty, reason: 'texto vacío = borrar la reseña');
    });

    test('reconoce como reseña la importada de Goodreads y no toca las demás notas', () async {
      await db.insertNote(NotesCompanion.insert(bookId: id, content: 'Una cita cualquiera', createdAt: Value(DateTime(2026, 1, 1))));
      await db.insertNote(NotesCompanion.insert(bookId: id, content: 'Mi reseña: importada', createdAt: Value(DateTime(2025, 6, 1))));
      final review = await db.getReview(id);
      expect(AppDatabase.reviewText(review!), 'importada');

      await db.saveReview(id, rating: 0, text: 'editada');
      final contents = (await db.select(db.notes).get()).map((n) => n.content);
      expect(contents, unorderedEquals(['Una cita cualquiera', 'Mi reseña: editada']));
    });

    test('una reseña muy larga se recorta al límite de las notas', () async {
      await db.saveReview(id, rating: 5, text: 'a' * 2000);
      expect((await db.select(db.notes).get()).single.content.length, 1000);
    });
  });

  testWidgets('la hoja guarda estrellas y reseña', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await tester.runAsync(() => db.insertBook(BooksCompanion.insert(title: 'Satanás', author: 'Mario Mendoza', totalPages: 285)));
    final book = (await tester.runAsync(() => db.select(db.books).get()))!.single;
    expect(book.id, id);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) => TextButton(
                onPressed: () => showFinishReviewSheet(context, book),
                child: const Text('abrir'),
              )),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(find.text('¡Terminaste Satanás!'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('5 estrellas'));
    await tester.pump();
    expect(find.text('¡Me encantó!'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Imprescindible.');
    await tester.runAsync(() async {
      await tester.tap(find.text('GUARDAR'));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();

    expect(find.text('¡Terminaste Satanás!'), findsNothing, reason: 'la hoja se cierra');
    final saved = (await tester.runAsync(() => db.select(db.books).get()))!.single;
    expect(saved.rating, 5);
    final notes = (await tester.runAsync(() => db.select(db.notes).get()))!;
    expect(notes.single.content, 'Mi reseña: Imprescindible.');
  });

  Future<void> openSheet(WidgetTester tester, AppDatabase db, Book book, {bool celebrate = false}) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(
          body: Builder(builder: (context) => TextButton(
                onPressed: () => showFinishReviewSheet(context, book, celebrate: celebrate),
                child: const Text('abrir'),
              )),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
  }

  testWidgets('editar: carga la reseña existente', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() async {
      final id = await db.insertBook(BooksCompanion.insert(title: 'Dune', author: 'Herbert', totalPages: 600, status: const Value(2)));
      await db.saveReview(id, rating: 4, text: 'La especia debe fluir');
    });
    final book = (await tester.runAsync(() => db.select(db.books).get()))!.single;

    await openSheet(tester, db, book);
    expect(find.text('Tu reseña de Dune'), findsOneWidget);
    expect(find.text('La especia debe fluir'), findsOneWidget, reason: 'texto precargado');
    expect(find.text('CANCELAR'), findsOneWidget);
  });

  testWidgets('abandonado: pregunta por qué lo dejaste', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await tester.runAsync(() => db.insertBook(BooksCompanion.insert(title: 'Ulises', author: 'Joyce', totalPages: 783, status: const Value(3))));
    final book = (await tester.runAsync(() => db.select(db.books).get()))!.single;

    await openSheet(tester, db, book);
    expect(find.text('Reseña de Ulises'), findsOneWidget);
    expect(find.text('Lo dejaste sin terminar'), findsOneWidget);
    expect(find.text('¿Por qué lo dejaste? (opcional)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
