import 'dart:io';

import 'package:book_tracker/database/database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Esquema exacto de la versión 7 (la que tienen hoy los usuarios),
/// obtenido de sqlite_master antes del cambio.
const _v7Schema = [
  'CREATE TABLE "books" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "title" TEXT NOT NULL, "author" TEXT NOT NULL, "total_pages" INTEGER NOT NULL, "read_pages" INTEGER NOT NULL DEFAULT 0, "total_read_time" INTEGER NOT NULL DEFAULT 0, "status" INTEGER NOT NULL DEFAULT 0, "category" TEXT NULL DEFAULT \'General\', "cover_url" TEXT NULL, "rating" INTEGER NULL DEFAULT 0)',
  'CREATE TABLE "notes" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "book_id" INTEGER NOT NULL REFERENCES books (id) ON DELETE CASCADE, "content" TEXT NOT NULL, "page_number" INTEGER NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)))',
  'CREATE TABLE "reading_sessions" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "book_id" INTEGER NOT NULL REFERENCES books (id) ON DELETE CASCADE, "seconds" INTEGER NOT NULL, "pages_read" INTEGER NOT NULL DEFAULT 0, "date" INTEGER NOT NULL DEFAULT (CAST(strftime(\'%s\', CURRENT_TIMESTAMP) AS INTEGER)))',
];

int _secs(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

void main() {
  group('migración 7 → 8', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('migration'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('conserva todo y estima las fechas a partir de las sesiones', () async {
      final file = File(p.join(tmp.path, 'db.sqlite'));

      // Base de datos tal como está hoy en el teléfono de un usuario (v7)
      final raw = sqlite3.open(file.path);
      for (final sql in _v7Schema) {
        raw.execute(sql);
      }
      raw.execute(
        "INSERT INTO books (id, title, author, total_pages, read_pages, status, rating, cover_url) VALUES "
        "(1, 'Terminado', 'A', 100, 100, 2, 5, '/portada.jpg'), "
        "(2, 'Leyendo', 'B', 300, 50, 1, 0, NULL), "
        "(3, 'Pendiente', 'C', 200, 0, 0, 0, NULL), "
        "(4, 'Terminado sin sesiones', 'D', 150, 150, 2, 4, NULL)",
      );
      final jan5 = DateTime(2026, 1, 5), feb20 = DateTime(2026, 2, 20), mar1 = DateTime(2026, 3, 1);
      raw.execute(
        'INSERT INTO reading_sessions (book_id, seconds, pages_read, date) VALUES '
        '(1, 600, 40, ${_secs(jan5)}), (1, 900, 60, ${_secs(feb20)}), (2, 300, 50, ${_secs(mar1)})',
      );
      raw.execute("INSERT INTO notes (book_id, content) VALUES (1, 'Una cita')");
      raw.execute('PRAGMA user_version = 7');
      raw.close();

      // La app nueva abre esa base: se ejecuta la migración
      final db = AppDatabase.forTesting(NativeDatabase(file));
      addTearDown(db.close);
      final books = {for (final b in await db.select(db.books).get()) b.id: b};

      expect(books, hasLength(4), reason: 'no se pierde ningún libro');
      expect(books[1]!.rating, 5);
      expect(books[1]!.coverUrl, '/portada.jpg');
      expect((await db.select(db.notes).get()).single.content, 'Una cita');
      expect(await db.select(db.readingSessions).get(), hasLength(3));

      // Terminado: inicio = primera sesión, fin = última
      expect(books[1]!.startedAt, jan5);
      expect(books[1]!.finishedAt, feb20);
      // Leyendo: inicio sí, fin no
      expect(books[2]!.startedAt, mar1);
      expect(books[2]!.finishedAt, isNull);
      // Pendiente: nada
      expect(books[3]!.startedAt, isNull);
      expect(books[3]!.finishedAt, isNull);
      // Terminado sin sesiones: fechas desconocidas (se pueden poner a mano)
      expect(books[4]!.finishedAt, isNull);

      final version = await db.customSelect('PRAGMA user_version').getSingle();
      expect(version.read<int>('user_version'), db.schemaVersion);
    });
  });

  group('reglas de fechas', () {
    final now = DateTime(2026, 11, 16, 10);
    final before = DateTime(2026, 1, 1);

    test('empezar fija el inicio; no lo cambia si ya existía', () {
      expect(AppDatabase.readingDatesAfter(oldStatus: 0, newStatus: 1, startedAt: null, finishedAt: null, hasProgress: true, now: now).startedAt, now);
      expect(AppDatabase.readingDatesAfter(oldStatus: 1, newStatus: 1, startedAt: before, finishedAt: null, hasProgress: true, now: now).startedAt, before);
    });

    test('terminar fija el fin (y el inicio si faltaba)', () {
      final d = AppDatabase.readingDatesAfter(oldStatus: 1, newStatus: 2, startedAt: null, finishedAt: null, hasProgress: true, now: now);
      expect(d.finishedAt, now);
      expect(d.startedAt, now);
    });

    test('dejar de estar terminado borra el fin', () {
      expect(AppDatabase.readingDatesAfter(oldStatus: 2, newStatus: 1, startedAt: before, finishedAt: before, hasProgress: true, now: now).finishedAt, isNull);
    });

    test('al terminar de nuevo (relectura) se actualiza el fin', () {
      expect(AppDatabase.readingDatesAfter(oldStatus: 1, newStatus: 2, startedAt: before, finishedAt: before, hasProgress: true, now: now).finishedAt, now);
    });

    test('un pendiente sin progreso no tiene fechas', () {
      final d = AppDatabase.readingDatesAfter(oldStatus: 0, newStatus: 0, startedAt: null, finishedAt: null, hasProgress: false, now: now);
      expect(d.startedAt, isNull);
      expect(d.finishedAt, isNull);
    });
  });

  test('registrar progreso guarda las fechas solo', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final id = await db.insertBook(BooksCompanion.insert(title: 'Dune', author: 'Herbert', totalPages: 100, status: const Value(0)));

    await db.logProgress(id, 30, additionalSeconds: 60);
    var book = await (db.select(db.books)..where((t) => t.id.equals(id))).getSingle();
    expect(book.startedAt, isNotNull);
    expect(book.finishedAt, isNull);
    final started = book.startedAt;

    await db.logProgress(id, 100);
    book = await (db.select(db.books)..where((t) => t.id.equals(id))).getSingle();
    expect(book.finishedAt, isNotNull);
    expect(book.startedAt, started, reason: 'el inicio no cambia');

    // Corrección: no estaba terminado
    await db.logProgress(id, 90);
    book = await (db.select(db.books)..where((t) => t.id.equals(id))).getSingle();
    expect(book.finishedAt, isNull);
  });
}
