import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';

part 'database.g.dart';

class Books extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 100)();
  TextColumn get author => text().withLength(min: 1, max: 100)();
  IntColumn get totalPages => integer()();
  IntColumn get readPages => integer().withDefault(const Constant(0))();
  IntColumn get totalReadTime => integer().withDefault(const Constant(0))();
  IntColumn get status => integer().withDefault(const Constant(0))(); 
  TextColumn get category => text().nullable().withDefault(const Constant('General'))();
  TextColumn get coverUrl => text().nullable()(); 
  // NUEVA COLUMNA: Calificación de 1 a 5 estrellas
  IntColumn get rating => integer().nullable().withDefault(const Constant(0))();
}

class Notes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id, onDelete: KeyAction.cascade)();
  TextColumn get content => text().withLength(min: 1, max: 1000)();
  IntColumn get pageNumber => integer().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class ReadingSessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get bookId => integer().references(Books, #id, onDelete: KeyAction.cascade)();
  IntColumn get seconds => integer()();
  IntColumn get pagesRead => integer().withDefault(const Constant(0))();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
}

@DriftDatabase(tables: [Books, Notes, ReadingSessions])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 7; // Incrementado de 6 a 7

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) await m.addColumn(books, books.category);
      if (from < 3) await m.createTable(notes);
      if (from < 4) await m.addColumn(books, books.coverUrl);
      if (from < 5) await m.createTable(readingSessions);
      if (from < 6) await m.addColumn(readingSessions, readingSessions.pagesRead);
      // MIGRACIÓN A VERSIÓN 7: Añadir columna rating
      if (from < 7) await m.addColumn(books, books.rating);
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  // --- MÉTODOS DE LIBROS ---
  Stream<List<Book>> watchAllBooks() => select(books).watch();
  Future<int> insertBook(BooksCompanion book) => into(books).insert(book);
  
  // Actualización: replace ahora reconoce el rating gracias al nuevo database.g.dart
  Future updateBook(Book book) => update(books).replace(book);

  Future<void> deleteBookComplete(Book book) async {
    if (book.coverUrl != null && book.coverUrl!.isNotEmpty) {
      try {
        final file = File(book.coverUrl!);
        if (await file.exists()) await file.delete();
      } catch (e) {
        debugPrint("❌ Error al borrar archivo físico: $e");
      }
    }
    await delete(books).delete(book);
  }

  // --- MÉTODOS DE NOTAS ---
  Stream<List<Note>> watchNotesForBook(int bookId) {
    return (select(notes)..where((t) => t.bookId.equals(bookId))).watch();
  }
  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);
  Future deleteNote(Note note) => delete(notes).delete(note);

  // --- MÉTODOS DE SESIONES Y MOTOR DE PROGRESO ---
  Future<int> insertSession(ReadingSessionsCompanion session) => into(readingSessions).insert(session);

  Future<void> logProgress(int bookId, int newTotalPages, int currentPages, {int additionalSeconds = 0}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = newTotalPages - currentPages;

    if (diff <= 0 && additionalSeconds <= 0) return; 

    await transaction(() async {
      final book = await (select(books)..where((t) => t.id.equals(bookId))).getSingle();
      
      int newStatus = book.status;

      if (newTotalPages >= book.totalPages) {
        newStatus = 2; // Terminado
      } else if (book.status != 3) { 
        if (newTotalPages > 0) {
          newStatus = 1; // En progreso
        }
      }

      await (update(books)..where((t) => t.id.equals(bookId))).write(
        BooksCompanion(
          readPages: Value(newTotalPages),
          totalReadTime: Value(book.totalReadTime + additionalSeconds),
          status: Value(newStatus),
          // Mantenemos el rating actual si ya existía
          rating: Value(book.rating),
        ),
      );

      final query = select(readingSessions)
        ..where((t) => t.bookId.equals(bookId))
        ..where((t) => t.date.isBiggerOrEqualValue(today));
      
      final existingSession = await query.getSingleOrNull();

      if (existingSession != null) {
        await (update(readingSessions)..where((t) => t.id.equals(existingSession.id))).write(
          ReadingSessionsCompanion(
            pagesRead: Value(existingSession.pagesRead + (diff > 0 ? diff : 0)),
            seconds: Value(existingSession.seconds + additionalSeconds),
          ),
        );
      } else {
        await into(readingSessions).insert(
          ReadingSessionsCompanion.insert(
            bookId: bookId,
            pagesRead: Value(diff > 0 ? diff : 0),
            seconds: additionalSeconds,
            date: Value(today),
          ),
        );
      }
    });
  }

  Stream<int> watchTotalTimeToday() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final sumSeconds = readingSessions.seconds.sum();
    final query = selectOnly(readingSessions)
      ..addColumns([sumSeconds])
      ..where(readingSessions.date.isBiggerOrEqualValue(todayStart));

    return query.map((row) => row.read(sumSeconds) ?? 0).watchSingle();
  }

  Stream<List<ReadingSession>> watchAllSessions() => select(readingSessions).watch();

  Stream<List<ReadingSession>> watchWeeklySessions() {
    final now = DateTime.now();
    final sevenDaysAgo = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    return (select(readingSessions)
      ..where((t) => t.date.isBiggerThanValue(sevenDaysAgo))
      ..orderBy([(t) => OrderingTerm(expression: t.date)]))
      .watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}