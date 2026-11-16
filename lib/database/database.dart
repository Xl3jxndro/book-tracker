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

  /// Para tests: permite usar una base en memoria (`NativeDatabase.memory()`).
  AppDatabase.forTesting(super.executor);

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
    await delete(books).delete(book);
    // Después de borrar el libro: así no cuenta como "uso" de su portada
    await deleteCoverIfUnused(book.coverUrl);
  }

  /// Borra el archivo de portada [path] si ningún libro lo usa.
  ///
  /// Solo borra archivos dentro de [coversDir] (por defecto, la carpeta de
  /// documentos de la app, donde se copian las portadas): nunca toca fotos de
  /// la galería u otras carpetas. Devuelve `true` si borró el archivo.
  Future<bool> deleteCoverIfUnused(String? path, {String? coversDir}) async {
    if (path == null || path.isEmpty) return false;
    try {
      final stillUsed = await (select(books)..where((t) => t.coverUrl.equals(path))).get();
      if (stillUsed.isNotEmpty) return false;

      final allowedDir = coversDir ?? (await getApplicationDocumentsDirectory()).path;
      if (!p.isWithin(allowedDir, path)) return false;

      final file = File(path);
      if (!await file.exists()) return false;
      await file.delete();
      return true;
    } catch (e) {
      debugPrint("❌ Error al borrar portada: $e");
      return false;
    }
  }

  // --- MÉTODOS DE NOTAS ---
  Stream<List<Note>> watchNotesForBook(int bookId) {
    return (select(notes)..where((t) => t.bookId.equals(bookId))).watch();
  }
  Future<int> insertNote(NotesCompanion note) => into(notes).insert(note);
  Future deleteNote(Note note) => delete(notes).delete(note);

  // --- MÉTODOS DE SESIONES Y MOTOR DE PROGRESO ---
  Future<int> insertSession(ReadingSessionsCompanion session) => into(readingSessions).insert(session);

  /// Registra el progreso de un libro: actualiza páginas, tiempo y estado, y
  /// acumula la sesión del día (usada por la racha, el mapa de calor y gráficas).
  ///
  /// [newReadPages] es la página en la que quedó el usuario. Puede ser menor que
  /// la actual (corrección): el libro se actualiza pero no se restan páginas de
  /// las sesiones, que son historial.
  Future<void> logProgress(int bookId, int newReadPages, {int additionalSeconds = 0}) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final seconds = additionalSeconds > 0 ? additionalSeconds : 0;

    await transaction(() async {
      final book = await (select(books)..where((t) => t.id.equals(bookId))).getSingle();

      final pages = newReadPages.clamp(0, book.totalPages);
      final diff = pages - book.readPages;

      if (diff == 0 && seconds == 0) return;

      int newStatus;
      if (book.totalPages > 0 && pages >= book.totalPages) {
        newStatus = 2; // Terminado
      } else if (book.status == 3) {
        newStatus = 3; // Abandonado (DNF): se respeta hasta terminarlo
      } else if (pages > 0) {
        newStatus = 1; // En progreso
      } else {
        // Volvió a 0 páginas: un libro "terminado" pasa a pendiente
        newStatus = book.status == 2 ? 0 : book.status;
      }

      await (update(books)..where((t) => t.id.equals(bookId))).write(
        BooksCompanion(
          readPages: Value(pages),
          totalReadTime: Value(book.totalReadTime + seconds),
          status: Value(newStatus),
        ),
      );

      // Una corrección hacia atrás sin tiempo no es lectura: no crea sesión
      // (si no, inflaría la racha con días sin actividad real).
      if (diff <= 0 && seconds == 0) return;

      final query = select(readingSessions)
        ..where((t) => t.bookId.equals(bookId))
        ..where((t) => t.date.isBiggerOrEqualValue(today));
      
      final existingSession = await query.getSingleOrNull();

      if (existingSession != null) {
        await (update(readingSessions)..where((t) => t.id.equals(existingSession.id))).write(
          ReadingSessionsCompanion(
            pagesRead: Value(existingSession.pagesRead + (diff > 0 ? diff : 0)),
            seconds: Value(existingSession.seconds + seconds),
          ),
        );
      } else {
        await into(readingSessions).insert(
          ReadingSessionsCompanion.insert(
            bookId: bookId,
            pagesRead: Value(diff > 0 ? diff : 0),
            seconds: seconds,
            date: Value(today),
          ),
        );
      }
    });
  }

  /// Segundos leídos en todos los libros durante el día de [day].
  Selectable<int> _totalTimeOnQuery(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final nextDay = DateTime(day.year, day.month, day.day + 1);
    final sumSeconds = readingSessions.seconds.sum();
    final query = selectOnly(readingSessions)
      ..addColumns([sumSeconds])
      ..where(readingSessions.date.isBiggerOrEqualValue(dayStart) &
          readingSessions.date.isSmallerThanValue(nextDay));

    return query.map((row) => row.read(sumSeconds) ?? 0);
  }

  /// Observa el tiempo leído en [day]. Quien lo use debe pasar el día actual
  /// y volver a suscribirse cuando cambie (ver `todayProvider`).
  Stream<int> watchTotalTimeOn(DateTime day) => _totalTimeOnQuery(day).watchSingle();

  /// Segundos leídos hoy en todos los libros (consulta puntual).
  Future<int> getTotalSecondsToday() => _totalTimeOnQuery(DateTime.now()).getSingle();

  Stream<List<ReadingSession>> watchAllSessions() => select(readingSessions).watch();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase(file);
  });
}