import 'dart:io';

import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/screens/quotes_screen.dart';
import 'package:book_tracker/widgets/quote_share.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Esquema de la versión 8 (la que tiene la versión publicada 1.1.x).
const _v8Schema = [
  'CREATE TABLE "books" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "title" TEXT NOT NULL, "author" TEXT NOT NULL, "total_pages" INTEGER NOT NULL, "read_pages" INTEGER NOT NULL DEFAULT 0, "total_read_time" INTEGER NOT NULL DEFAULT 0, "status" INTEGER NOT NULL DEFAULT 0, "category" TEXT NULL DEFAULT \'General\', "cover_url" TEXT NULL, "rating" INTEGER NULL DEFAULT 0, "started_at" INTEGER NULL, "finished_at" INTEGER NULL)',
  'CREATE TABLE "notes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "book_id" INTEGER NOT NULL REFERENCES books (id) ON DELETE CASCADE, "content" TEXT NOT NULL, "page_number" INTEGER NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)))',
  'CREATE TABLE "reading_sessions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "book_id" INTEGER NOT NULL REFERENCES books (id) ON DELETE CASCADE, "seconds" INTEGER NOT NULL, "pages_read" INTEGER NOT NULL DEFAULT 0, "date" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)))',
];

Book _book(int id, String title, String author) =>
    Book(id: id, title: title, author: author, totalPages: 100, readPages: 0, totalReadTime: 0, status: 0);

NoteWithBook _q(int id, String content, Book book, {bool fav = false, int? page}) => NoteWithBook(
      Note(id: id, bookId: book.id, content: content, pageNumber: page, createdAt: DateTime(2026, 1, id), isFavorite: fav),
      book,
    );

void main() {
  test('migración 8 → 9: conserva las notas y ninguna queda favorita', () async {
    final tmp = Directory.systemTemp.createTempSync('migration9');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final file = File(p.join(tmp.path, 'db.sqlite'));

    final raw = sqlite3.open(file.path);
    for (final sql in _v8Schema) {
      raw.execute(sql);
    }
    raw.execute("INSERT INTO books (id, title, author, total_pages) VALUES (1, 'Satanás', 'Mario Mendoza', 285)");
    raw.execute("INSERT INTO notes (book_id, content, page_number) VALUES (1, 'Una cita', 12), (1, 'Otra', NULL)");
    raw.execute('PRAGMA user_version = 8');
    raw.close();

    final db = AppDatabase.forTesting(NativeDatabase(file));
    addTearDown(db.close);
    final notes = await db.select(db.notes).get();
    expect(notes.map((n) => n.content), unorderedEquals(['Una cita', 'Otra']));
    expect(notes.every((n) => !n.isFavorite), isTrue);
    expect(notes.firstWhere((n) => n.content == 'Una cita').pageNumber, 12);
    expect((await db.select(db.books).get()).single.title, 'Satanás');
    expect((await db.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version'), 9);
  });

  test('todas las citas con su libro, la más reciente primero, y marcar favorita', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final a = await db.insertBook(BooksCompanion.insert(title: 'Dune', author: 'Herbert', totalPages: 600));
    final b = await db.insertBook(BooksCompanion.insert(title: 'Solaris', author: 'Lem', totalPages: 300));
    final n1 = await db.insertNote(NotesCompanion.insert(bookId: a, content: 'El miedo mata la mente', createdAt: Value(DateTime(2026, 1, 1))));
    await db.insertNote(NotesCompanion.insert(bookId: b, content: 'No buscamos otros mundos', createdAt: Value(DateTime(2026, 2, 1))));

    var all = await db.watchAllNotesWithBooks().first;
    expect(all.map((q) => q.book.title), ['Solaris', 'Dune']);

    await db.setNoteFavorite(n1, true);
    all = await db.watchAllNotesWithBooks().first;
    expect(all.firstWhere((q) => q.note.id == n1).note.isFavorite, isTrue);

    // Al borrar el libro desaparecen sus citas
    await db.deleteBookComplete((await db.select(db.books).get()).firstWhere((x) => x.id == a));
    all = await db.watchAllNotesWithBooks().first;
    expect(all.single.book.title, 'Solaris');
  });

  group('filtro de citas', () {
    final dune = _book(1, 'Dune', 'Frank Herbert');
    final sat = _book(2, 'Satanás', 'Mario Mendoza');
    final all = [
      _q(1, 'El miedo mata la mente', dune, fav: true),
      _q(2, 'Un corazón en la ciudad', sat),
      _q(3, 'La especia debe fluir', dune),
    ];

    test('sin filtro devuelve todas en el mismo orden', () {
      expect(filterQuotes(all).map((q) => q.note.id), [1, 2, 3]);
    });

    test('busca en la cita, el título y el autor, sin importar tildes ni mayúsculas', () {
      expect(filterQuotes(all, query: 'CORAZON').single.note.id, 2);
      expect(filterQuotes(all, query: 'satanas').single.note.id, 2);
      expect(filterQuotes(all, query: 'herbert').map((q) => q.note.id), [1, 3]);
      expect(filterQuotes(all, query: 'dune especia').single.note.id, 3);
      expect(filterQuotes(all, query: 'nada'), isEmpty);
    });

    test('solo favoritas', () {
      expect(filterQuotes(all, favoritesOnly: true).single.note.id, 1);
      expect(filterQuotes(all, query: 'especia', favoritesOnly: true), isEmpty);
    });
  });

  testWidgets('la tarjeta de cita no se desborda con una cita de 1000 caracteres', (tester) async {
    final book = _book(1, 'Un título bastante largo para una tarjeta de cita compartida', 'Autor con nombre largo');
    final note = Note(id: 1, bookId: 1, content: 'palabra ' * 125, pageNumber: 123, createdAt: DateTime(2026), isFavorite: true);
    await tester.binding.setSurfaceSize(const Size(500, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaterialApp(home: Center(child: QuoteShareCard(book: book, note: note, accent: Colors.indigo))));
    expect(tester.takeException(), isNull);
    expect(find.text('Página 123'), findsOneWidget);
  });
}
