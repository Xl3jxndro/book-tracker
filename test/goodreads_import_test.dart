import 'dart:io';

import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/services/book_api_service.dart';
import 'package:book_tracker/services/csv_parser.dart';
import 'package:book_tracker/services/goodreads_import.dart';
import 'package:book_tracker/services/reading_challenge.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// Cabecera real de la exportación de Goodreads.
const _header =
    'Book Id,Title,Author,Author l-f,Additional Authors,ISBN,ISBN13,My Rating,Average Rating,Publisher,Binding,'
    'Number of Pages,Year Published,Original Publication Year,Date Read,Date Added,Bookshelves,'
    'Bookshelves with positions,Exclusive Shelf,My Review,Spoiler,Private Notes,Read Count,Owned Copies';

String _row({
  String title = 'Libro',
  String author = 'Autor',
  String isbn = '=""',
  String isbn13 = '=""',
  int rating = 0,
  String pages = '',
  String dateRead = '',
  String dateAdded = '2024/01/01',
  String shelf = 'to-read',
  String review = '',
  String privateNotes = '',
}) {
  String q(String s) => '"${s.replaceAll('"', '""')}"';
  return [
    '1', q(title), q(author), q(author), '', q(isbn), q(isbn13), '$rating', '4.05', 'Editorial', 'Paperback',
    pages, '2005', '1967', dateRead, dateAdded, '', '', shelf, q(review), '', q(privateNotes), '1', '0',
  ].join(',');
}

String _csv(List<String> rows) => '$_header\n${rows.join('\n')}\n';

Book _existing(int id, String title, String author) =>
    Book(id: id, title: title, author: author, totalPages: 100, readPages: 0, totalReadTime: 0, status: 0);

void main() {
  group('lector de CSV', () {
    test('comillas, comillas escapadas, comas y saltos de línea dentro de un campo', () {
      final rows = parseCsv('﻿a,b,c\r\n"x, y","dijo ""hola""","línea 1\nlínea 2"\r\n\r\n1,,3');
      expect(rows, [
        ['a', 'b', 'c'],
        ['x, y', 'dijo "hola"', 'línea 1\nlínea 2'],
        ['1', '', '3'],
      ]);
    });

    test('última línea sin salto final', () {
      expect(parseCsv('a,b\n1,2'), [['a', 'b'], ['1', '2']]);
    });
  });

  group('leer la exportación de Goodreads', () {
    test('convierte estado, calificación, páginas, fecha, ISBN y reseña', () {
      final preview = GoodreadsImport.parse(_csv([
        _row(
          title: 'Cien años de soledad',
          author: 'Gabriel García Márquez',
          isbn: '="0307474720"',
          isbn13: '="9780307474728"',
          rating: 5,
          pages: '417',
          dateRead: '2024/03/15',
          shelf: 'read',
          review: 'Una obra maestra.<br/><br/>La releería &amp; la <b>recomiendo</b>.',
        ),
        _row(title: 'Dune', author: 'Frank Herbert', isbn13: '="9780441172719"', shelf: 'currently-reading', pages: '688'),
        _row(title: 'Solaris', author: 'Stanisław Lem', shelf: 'to-read'),
        _row(title: 'Ulises', author: 'James Joyce', shelf: 'did-not-finish', privateNotes: 'Lo dejé en la página 200'),
      ]));

      expect(preview.books, hasLength(4));
      expect(preview.duplicates, 0);

      final cien = preview.books[0];
      expect(cien.status, 2);
      expect(cien.rating, 5);
      expect(cien.pages, 417);
      expect(cien.finishedAt, DateTime(2024, 3, 15));
      expect(cien.isbn13, '9780307474728');
      expect(cien.notes.single, 'Mi reseña: Una obra maestra.\n\nLa releería & la recomiendo.');

      expect(preview.books[1].status, 1);
      expect(preview.books[1].finishedAt, isNull);
      expect(preview.books[2].status, 0);
      expect(preview.books[2].pages, 0, reason: 'sin páginas: 0, se puede editar después');
      expect(preview.books[2].isbn13, isNull);
      expect(preview.books[3].status, 3, reason: 'estantería de abandonados');
      expect(preview.books[3].notes.single, 'Lo dejé en la página 200');

      expect(preview.countStatus(2), 1);
      expect(preview.withIsbn, 2);
      expect(preview.notes, 2);
    });

    test('si solo hay ISBN-10, lo convierte a ISBN-13', () {
      final preview = GoodreadsImport.parse(_csv([_row(isbn: '="0307474720"', isbn13: '=""')]));
      expect(preview.books.single.isbn13, '9780307474728');
    });

    test('la fecha de lectura solo cuenta si el libro está terminado', () {
      final preview = GoodreadsImport.parse(_csv([_row(shelf: 'currently-reading', dateRead: '2024/02/02')]));
      expect(preview.books.single.finishedAt, isNull);
    });

    test('omite los que ya están en la biblioteca (sin importar la serie, tildes o mayúsculas)', () {
      final preview = GoodreadsImport.parse(
        _csv([
          _row(title: 'Dune (Dune, #1)', author: 'Frank Herbert'),
          _row(title: 'Satanás', author: 'Mario Mendoza'),
          _row(title: 'Nuevo', author: 'Alguien'),
          _row(title: 'Nuevo', author: 'Alguien'), // repetido en el archivo
          _row(title: '', author: 'Sin título'),
        ]),
        existing: [_existing(1, 'DUNE', 'frank herbert'), _existing(2, 'Satanas', 'Mario Mendoza')],
      );
      expect(preview.books.map((b) => b.title), ['Nuevo']);
      expect(preview.duplicates, 3);
      expect(preview.invalid, 1);
    });

    test('recorta títulos y autores a 100 caracteres (límite de la base de datos)', () {
      final preview = GoodreadsImport.parse(_csv([_row(title: 'T' * 150, author: 'A' * 150)]));
      expect(preview.books.single.title.length, 100);
      expect(preview.books.single.author.length, 100);
    });

    test('un archivo que no es de Goodreads da un mensaje claro', () {
      expect(
        () => GoodreadsImport.parse('nombre,precio\nmanzana,1'),
        throwsA(isA<GoodreadsImportException>().having((e) => e.message, 'message', contains('Goodreads'))),
      );
      expect(() => GoodreadsImport.parse(''), throwsA(isA<GoodreadsImportException>()));
    });
  });

  group('importar en la base de datos', () {
    late AppDatabase db;
    setUp(() => db = AppDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    test('añade sin tocar lo que había; los leídos cuentan en el reto; se puede deshacer', () async {
      final mine = await db.insertBook(BooksCompanion.insert(title: 'Satanás', author: 'Mario Mendoza', totalPages: 285));

      final preview = GoodreadsImport.parse(
        _csv([
          _row(title: 'Satanás', author: 'Mario Mendoza', shelf: 'read'), // duplicado: se omite
          _row(title: 'Cien años de soledad', author: 'GGM', pages: '417', rating: 4, dateRead: '2025/06/01', shelf: 'read', review: 'Genial'),
          _row(title: 'Dune', author: 'Frank Herbert', pages: '688', shelf: 'currently-reading'),
        ]),
        existing: await db.select(db.books).get(),
      );
      final imported = await GoodreadsImport.import(db, preview.books);
      expect(imported, hasLength(2));

      final books = await db.select(db.books).get();
      expect(books, hasLength(3));
      final cien = books.firstWhere((b) => b.title == 'Cien años de soledad');
      expect(cien.status, 2);
      expect(cien.readPages, 417, reason: 'terminado = todas las páginas leídas');
      expect(cien.rating, 4);
      expect(cien.finishedAt, DateTime(2025, 6, 1));
      expect(ReadingChallenge.finishedIn(books, 2025).single.id, cien.id);

      final dune = books.firstWhere((b) => b.title == 'Dune');
      expect(dune.status, 1);
      expect(dune.readPages, 0);

      final notes = await db.select(db.notes).get();
      expect(notes.single.bookId, cien.id);
      expect(notes.single.content, 'Mi reseña: Genial');

      await GoodreadsImport.undo(db, imported);
      final after = await db.select(db.books).get();
      expect(after.single.id, mine, reason: 'deshacer solo borra lo importado');
      expect(await db.select(db.notes).get(), isEmpty);
    });

    test('portadas por ISBN: guarda las que existen y no toca libros borrados', () async {
      final tmp = Directory.systemTemp.createTempSync('covers');
      addTearDown(() => tmp.deleteSync(recursive: true));

      final preview = GoodreadsImport.parse(_csv([
        _row(title: 'Con portada', isbn13: '="9780307474728"'),
        _row(title: 'Sin portada en Open Library', isbn13: '="9780441172719"'),
        _row(title: 'Sin ISBN'),
      ]));
      final imported = await GoodreadsImport.import(db, preview.books);

      final requested = <String>[];
      final api = BookApiService(
        googleApiKey: '',
        client: MockClient((request) async {
          requested.add(request.url.toString());
          if (request.url.path.contains('9780307474728')) {
            return http.Response.bytes(List.filled(5000, 7), 200, headers: {'content-type': 'image/jpeg'});
          }
          return http.Response('', 404);
        }),
      );

      final progress = <int>[];
      final found = await GoodreadsImport.fetchCovers(db, api, imported, tmp, onProgress: (done, _) => progress.add(done));
      expect(found, 1);
      expect(requested, hasLength(2), reason: 'solo se piden las de libros con ISBN');
      expect(requested.first, 'https://covers.openlibrary.org/b/isbn/9780307474728-M.jpg?default=false');
      expect(progress, [1, 2]);

      final books = {for (final b in await db.select(db.books).get()) b.title: b};
      expect(File(books['Con portada']!.coverUrl!).lengthSync(), 5000);
      expect(books['Sin portada en Open Library']!.coverUrl, isNull);

      // Si el libro se borró mientras se buscaba (deshacer), la portada no se queda huérfana
      await GoodreadsImport.undo(db, imported);
      final again = await GoodreadsImport.import(db, preview.books);
      await (db.delete(db.books)..where((t) => t.id.equals(again.first.id))).go();
      final before = tmp.listSync().length;
      expect(await GoodreadsImport.fetchCovers(db, api, again, tmp), 0);
      expect(tmp.listSync().length, before);
    });
  });
}
