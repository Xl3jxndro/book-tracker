import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/providers/current_book_provider.dart';
import 'package:book_tracker/providers/database_provider.dart';
import 'package:book_tracker/services/home_widget_sync.dart';
import 'package:book_tracker/services/notification_service.dart';
import 'package:book_tracker/services/voice_service.dart';
import 'package:book_tracker/widgets/add_note_sheet.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
  });
  tearDown(() => db.close());

  Future<int> addBook(String title, {int status = 0}) => db.insertBook(
      BooksCompanion.insert(title: title, author: 'Autor', totalPages: 100, status: Value(status)));

  Future<List<Note>> allNotes() => db.select(db.notes).get();

  group('notas', () {
    test('editar cambia texto y página pero conserva la fecha', () async {
      final bookId = await addBook('Dune');
      await db.insertNote(NotesCompanion.insert(bookId: bookId, content: 'Original', pageNumber: const Value(10)));
      final note = (await allNotes()).single;

      await db.updateNote(note, content: 'Editada', pageNumber: null);

      final edited = (await allNotes()).single;
      expect(edited.id, note.id);
      expect(edited.content, 'Editada');
      expect(edited.pageNumber, isNull);
      expect(edited.createdAt, note.createdAt);
    });

    test('deshacer restaura la nota borrada exactamente igual', () async {
      final bookId = await addBook('Dune');
      await db.insertNote(NotesCompanion.insert(
        bookId: bookId,
        content: 'El miedo mata la mente',
        pageNumber: const Value(8),
        createdAt: Value(DateTime(2026, 1, 2, 3, 4, 5)),
      ));
      final note = (await allNotes()).single;

      await db.deleteNote(note);
      expect(await allNotes(), isEmpty);

      await db.restoreNote(note);
      final restored = (await allNotes()).single;
      expect(restored.id, note.id);
      expect(restored.content, note.content);
      expect(restored.pageNumber, 8);
      expect(restored.createdAt, note.createdAt);
    });
  });

  group('notificación diaria', () {
    test('el recordatorio (y los antiguos sin contenido) abren el libro; la de prueba no', () {
      expect(NotificationService.opensCurrentBook(NotificationService.openCurrentBookPayload), isTrue);
      expect(NotificationService.opensCurrentBook(null), isTrue);
      expect(NotificationService.opensCurrentBook('test_payload'), isFalse);
    });

    test('el libro actual es el último abierto', () async {
      await addBook('Leyendo', status: 1);
      final opened = await addBook('Abierto hace poco');
      SharedPreferences.setMockInitialValues({CurrentBookNotifier.prefsKey: opened});

      expect((await HomeWidgetSync.currentBook(db))!.id, opened);
    });

    test('con una sesión de lectura activa, manda el libro de la sesión', () async {
      final inSession = await addBook('En sesión');
      final opened = await addBook('Abierto');
      SharedPreferences.setMockInitialValues({
        CurrentBookNotifier.prefsKey: opened,
        'reading_book_id': inSession,
        'reading_is_paused': true,
        'reading_accumulated': 60,
      });

      expect((await HomeWidgetSync.currentBook(db))!.id, inSession);
    });

    test('sin libros no hay libro que abrir', () async {
      expect(await HomeWidgetSync.currentBook(db), isNull);
    });
  });

  testWidgets('el formulario edita una nota existente', (tester) async {
    final bookId = await addBook('Dune');
    await db.insertNote(NotesCompanion.insert(bookId: bookId, content: 'Original', pageNumber: const Value(10)));
    final note = (await allNotes()).single;

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        home: Scaffold(
          body: AddNoteSheet(bookId: bookId, voiceService: VoiceService(), noteToEdit: note),
        ),
      ),
    ));
    await tester.pump();

    expect(find.text('Editar anotación'), findsOneWidget);
    expect(find.text('Original'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);

    await tester.enterText(find.text('Original'), 'Corregida');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();

    final saved = (await allNotes()).single;
    expect(saved.content, 'Corregida');
    expect(saved.pageNumber, 10);
  });
}
