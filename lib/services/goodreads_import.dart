import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import '../database/database.dart';
import 'book_api_service.dart';
import 'csv_parser.dart';
import 'isbn.dart';
import 'text_normalize.dart';

class GoodreadsImportException implements Exception {
  final String message;
  const GoodreadsImportException(this.message);
  @override
  String toString() => message;
}

/// Un libro leído del CSV de Goodreads, ya convertido al modelo de la app.
class GoodreadsBook {
  final String title;
  final String author;

  /// 0 si Goodreads no tiene el número de páginas (se puede editar después).
  final int pages;

  /// 0 por leer, 1 leyendo, 2 terminado, 3 abandonado.
  final int status;

  /// 0 = sin calificar, 1–5 estrellas.
  final int rating;
  final DateTime? finishedAt;
  final DateTime? addedAt;
  final String? isbn13;

  /// Reseña y notas privadas (se guardan como notas del libro).
  final List<String> notes;

  const GoodreadsBook({
    required this.title,
    required this.author,
    required this.pages,
    required this.status,
    required this.rating,
    this.finishedAt,
    this.addedAt,
    this.isbn13,
    this.notes = const [],
  });
}

/// Resultado de leer el archivo, antes de importar nada.
class GoodreadsPreview {
  final List<GoodreadsBook> books;

  /// Ya estaban en la biblioteca (o repetidos en el archivo): se omiten.
  final int duplicates;

  /// Filas sin título.
  final int invalid;

  const GoodreadsPreview({required this.books, required this.duplicates, required this.invalid});

  int countStatus(int status) => books.where((b) => b.status == status).length;
  int get withIsbn => books.where((b) => b.isbn13 != null).length;
  int get notes => books.fold(0, (sum, b) => sum + b.notes.length);
}

/// Libro creado por la importación (para buscar su portada o deshacer).
class ImportedBook {
  final int id;
  final String? isbn13;
  const ImportedBook(this.id, this.isbn13);
}

class GoodreadsImport {
  static const _maxText = 100; // límite de título y autor en la base de datos
  static const _maxNote = 1000;

  /// Clave para detectar duplicados: título sin la serie entre paréntesis
  /// ("Dune (Dune, #1)" = "Dune"), sin tildes ni mayúsculas, más el autor.
  static String duplicateKey(String title, String author) {
    String norm(String s) => normalizeForSearch(s).replaceAll(RegExp(r'[^a-z0-9ñ]+'), ' ').trim();
    return '${norm(BookApiService.cleanOpenLibraryTitle(title))}|${norm(author)}';
  }

  /// Lee el CSV exportado desde Goodreads (Mis libros → Importar/exportar).
  /// No toca la base de datos. Omite los libros que ya están en [existing].
  static GoodreadsPreview parse(String csv, {List<Book> existing = const []}) {
    final rows = parseCsv(csv);
    if (rows.isEmpty) throw const GoodreadsImportException('El archivo está vacío.');

    final header = [for (final h in rows.first) h.trim().toLowerCase()];
    int col(String name) => header.indexOf(name);
    final titleCol = col('title'), authorCol = col('author'), shelfCol = col('exclusive shelf');
    if (titleCol < 0 || authorCol < 0 || shelfCol < 0) {
      throw const GoodreadsImportException(
        'Este archivo no parece una exportación de Goodreads. '
        'Descárgala desde goodreads.com → Mis libros → Importar y exportar → Exportar biblioteca.',
      );
    }
    final isbnCol = col('isbn'), isbn13Col = col('isbn13'), ratingCol = col('my rating');
    final pagesCol = col('number of pages'), dateReadCol = col('date read'), dateAddedCol = col('date added');
    final reviewCol = col('my review'), privateNotesCol = col('private notes');

    String cell(List<String> row, int index) => (index >= 0 && index < row.length) ? row[index].trim() : '';

    final seen = {for (final b in existing) duplicateKey(b.title, b.author)};
    final books = <GoodreadsBook>[];
    var duplicates = 0, invalid = 0;

    for (final row in rows.skip(1)) {
      final title = _truncate(cell(row, titleCol), _maxText);
      if (title.isEmpty) {
        invalid++;
        continue;
      }
      final authorRaw = _truncate(cell(row, authorCol), _maxText);
      final author = authorRaw.isEmpty ? 'Desconocido' : authorRaw;

      if (!seen.add(duplicateKey(title, author))) {
        duplicates++;
        continue;
      }

      final status = shelfToStatus(cell(row, shelfCol));
      final rating = int.tryParse(cell(row, ratingCol)) ?? 0;
      final finishedAt = parseDate(cell(row, dateReadCol));
      final addedAt = parseDate(cell(row, dateAddedCol));

      final notes = <String>[];
      final review = cleanReview(cell(row, reviewCol));
      if (review.isNotEmpty) notes.add(_truncate('${AppDatabase.reviewPrefix}$review', _maxNote));
      final privateNotes = cleanReview(cell(row, privateNotesCol));
      if (privateNotes.isNotEmpty) notes.add(_truncate(privateNotes, _maxNote));

      books.add(GoodreadsBook(
        title: title,
        author: author,
        pages: (int.tryParse(cell(row, pagesCol)) ?? 0).clamp(0, 100000).toInt(),
        status: status,
        rating: rating.clamp(0, 5).toInt(),
        // Solo un libro terminado tiene fecha de fin (cuenta en el reto de ese año)
        finishedAt: status == 2 ? finishedAt : null,
        addedAt: addedAt,
        isbn13: Isbn.normalize(cleanIsbn(cell(row, isbn13Col))) ?? Isbn.normalize(cleanIsbn(cell(row, isbnCol))),
        notes: notes,
      ));
    }

    return GoodreadsPreview(books: books, duplicates: duplicates, invalid: invalid);
  }

  /// Estantería exclusiva de Goodreads → estado de la app.
  static int shelfToStatus(String shelf) {
    final s = shelf.trim().toLowerCase();
    if (s == 'read') return 2;
    if (s == 'currently-reading') return 1;
    if (s == 'to-read') return 0;
    if (s.contains('dnf') || s.contains('not-finish') || s.contains('abandon') || s.contains('unfinished')) return 3;
    return 0; // estanterías propias: por leer
  }

  /// Goodreads escribe el ISBN como ="0307474720" (y ="" si no hay).
  static String cleanIsbn(String raw) => raw.replaceAll(RegExp(r'[="\s]'), '');

  /// "2024/03/15" (Goodreads) o "2024-03-15".
  static DateTime? parseDate(String raw) {
    final m = RegExp(r'^(\d{4})[/-](\d{1,2})[/-](\d{1,2})').firstMatch(raw.trim());
    if (m == null) return null;
    final y = int.parse(m.group(1)!), mo = int.parse(m.group(2)!), d = int.parse(m.group(3)!);
    if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
    return DateTime(y, mo, d);
  }

  /// Las reseñas vienen con HTML (<br/>, <b>…) y entidades (&amp;).
  static String cleanReview(String raw) {
    var text = raw.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&amp;', '&');
    return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  }

  static String _truncate(String s, int max) => s.length <= max ? s : s.substring(0, max).trimRight();

  /// Añade los libros (y sus notas) a la biblioteca, sin tocar lo que ya hay.
  /// Todo o nada: si algo falla, no se añade ningún libro.
  static Future<List<ImportedBook>> import(AppDatabase db, List<GoodreadsBook> books) {
    return db.transaction(() async {
      final imported = <ImportedBook>[];
      for (final b in books) {
        final id = await db.into(db.books).insert(BooksCompanion.insert(
              title: b.title,
              author: b.author,
              totalPages: b.pages,
              readPages: Value(b.status == 2 ? b.pages : 0),
              status: Value(b.status),
              rating: Value(b.rating),
              finishedAt: Value(b.finishedAt),
            ));
        for (final note in b.notes) {
          await db.into(db.notes).insert(NotesCompanion.insert(
                bookId: id,
                content: note,
                createdAt: Value(b.finishedAt ?? b.addedAt ?? DateTime.now()),
              ));
        }
        imported.add(ImportedBook(id, b.isbn13));
      }
      return imported;
    });
  }

  /// Deshace la importación: borra esos libros (con sus notas y portadas).
  static Future<void> undo(AppDatabase db, List<ImportedBook> imported) async {
    final ids = imported.map((b) => b.id).toList();
    final books = await (db.select(db.books)..where((t) => t.id.isIn(ids))).get();
    for (final book in books) {
      await db.deleteBookComplete(book);
    }
  }

  static String coverUrlForIsbn(String isbn13) => 'https://covers.openlibrary.org/b/isbn/$isbn13-M.jpg?default=false';

  /// Busca en Open Library la portada de cada libro con ISBN, de uno en uno.
  /// Devuelve cuántas encontró. Si el libro ya no existe (se deshizo la
  /// importación) o ya tiene portada, no la guarda.
  static Future<int> fetchCovers(
    AppDatabase db,
    BookApiService api,
    List<ImportedBook> imported,
    Directory coversDir, {
    void Function(int done, int total)? onProgress,
  }) async {
    final withIsbn = imported.where((b) => b.isbn13 != null).toList();
    var found = 0;
    for (var i = 0; i < withIsbn.length; i++) {
      final book = withIsbn[i];
      try {
        final file = await api.downloadCover(
          coverUrlForIsbn(book.isbn13!),
          coversDir,
          fileName: 'cover_goodreads_${book.id}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (file != null) {
          final updated = await (db.update(db.books)..where((t) => t.id.equals(book.id) & t.coverUrl.isNull()))
              .write(BooksCompanion(coverUrl: Value(file.path)));
          if (updated == 0) {
            await file.delete(); // el libro se borró o ya tenía portada
          } else {
            found++;
          }
        }
      } catch (e) {
        debugPrint('Portada de ${book.isbn13} no disponible: $e');
      }
      onProgress?.call(i + 1, withIsbn.length);
    }
    return found;
  }
}
