import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/services/backup_service.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tmp;
  late Directory coversA; // "teléfono A" (origen del respaldo)
  late Directory coversB; // "teléfono B" (donde se restaura)
  late AppDatabase dbA;
  late AppDatabase dbB;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('backup_test');
    coversA = Directory(p.join(tmp.path, 'A'))..createSync();
    coversB = Directory(p.join(tmp.path, 'B'))..createSync();
    dbA = AppDatabase.forTesting(NativeDatabase.memory());
    dbB = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await dbA.close();
    await dbB.close();
    tmp.deleteSync(recursive: true);
  });

  Future<int> addBook(AppDatabase db, String title, {String? cover, int status = 1, int rating = 0}) =>
      db.insertBook(BooksCompanion.insert(
        title: title,
        author: 'Autor de $title',
        totalPages: 300,
        readPages: const Value(120),
        totalReadTime: const Value(5400),
        status: Value(status),
        rating: Value(rating),
        category: const Value('Novela'),
        coverUrl: Value(cover),
      ));

  File coverFile(Directory dir, String name, List<int> bytes) =>
      File(p.join(dir.path, name))..writeAsBytesSync(bytes);

  Future<File> saveZip(AppDatabase db, String name) async {
    final file = File(p.join(tmp.path, name));
    return file.writeAsBytes(await BackupService.buildZip(db));
  }

  Future<BackupPreview> read(File f) => BackupService.read(f, Directory(p.join(tmp.path, 'work_${f.hashCode}')));

  test('las fechas de inicio y fin sobreviven al respaldo (y los respaldos sin fechas también sirven)', () async {
    final id = await addBook(dbA, 'Dune', status: 2);
    await (dbA.update(dbA.books)..where((t) => t.id.equals(id))).write(BooksCompanion(
      startedAt: Value(DateTime(2026, 3, 1, 9)),
      finishedAt: Value(DateTime(2026, 3, 9, 21, 30)),
    ));
    await addBook(dbA, 'Sin fechas', status: 0);

    await BackupService.restore(dbB, await read(await saveZip(dbA, 'fechas.zip')), coversDir: coversB.path);

    final books = {for (final b in await dbB.select(dbB.books).get()) b.title: b};
    expect(books['Dune']!.startedAt, DateTime(2026, 3, 1, 9));
    expect(books['Dune']!.finishedAt, DateTime(2026, 3, 9, 21, 30));
    expect(books['Sin fechas']!.startedAt, isNull);
    expect(books['Sin fechas']!.finishedAt, isNull);
  });

  test('ida y vuelta: se restaura todo, con portadas, y reemplaza lo anterior', () async {
    // Teléfono A: dos libros (uno con portada), una nota y una sesión
    final cover = coverFile(coversA, 'cover_1.jpg', List.generate(2000, (i) => i % 256));
    final dune = await addBook(dbA, 'Dune', cover: cover.path, status: 2, rating: 5);
    await addBook(dbA, 'Sin portada');
    await dbA.insertNote(NotesCompanion.insert(
      bookId: dune, content: 'El miedo mata la mente', pageNumber: const Value(8),
      createdAt: Value(DateTime(2026, 1, 2, 3, 4, 5)), isFavorite: const Value(true),
    ));
    await dbA.insertSession(ReadingSessionsCompanion.insert(
      bookId: dune, seconds: 1800, pagesRead: const Value(40), date: Value(DateTime(2026, 1, 2)),
    ));

    // Teléfono B ya tenía otra biblioteca, con su portada
    final oldCover = coverFile(coversB, 'vieja.jpg', [9, 9, 9]);
    await addBook(dbB, 'Libro viejo', cover: oldCover.path);

    final zip = await saveZip(dbA, 'respaldo.zip');
    final preview = await read(zip);
    expect(preview.books, hasLength(2));
    expect(preview.coverFiles.keys, ['cover_1.jpg']);

    final result = await BackupService.restore(dbB, preview, coversDir: coversB.path);
    expect(result.books, 2);
    expect(result.notes, 1);
    expect(result.sessions, 1);
    expect(result.covers, 1);

    final books = await dbB.select(dbB.books).get();
    expect(books.map((b) => b.title), unorderedEquals(['Dune', 'Sin portada']));
    final restoredDune = books.firstWhere((b) => b.title == 'Dune');
    expect(restoredDune.id, dune);
    expect(restoredDune.status, 2);
    expect(restoredDune.rating, 5);
    expect(restoredDune.readPages, 120);
    expect(restoredDune.totalReadTime, 5400);
    expect(restoredDune.category, 'Novela');

    // La portada está en el teléfono B, con su contenido
    expect(p.isWithin(coversB.path, restoredDune.coverUrl!), isTrue);
    expect(File(restoredDune.coverUrl!).readAsBytesSync(), cover.readAsBytesSync());

    final note = (await dbB.select(dbB.notes).get()).single;
    expect(note.bookId, dune);
    expect(note.content, 'El miedo mata la mente');
    expect(note.createdAt, DateTime(2026, 1, 2, 3, 4, 5));
    expect(note.isFavorite, isTrue, reason: 'la cita favorita sigue siéndolo');

    final session = (await dbB.select(dbB.readingSessions).get()).single;
    expect(session.seconds, 1800);
    expect(session.date, DateTime(2026, 1, 2));

    // Lo anterior de B desapareció, también su portada
    expect(books.any((b) => b.title == 'Libro viejo'), isFalse);
    expect(oldCover.existsSync(), isFalse);
  });

  test('una portada compartida por dos libros se guarda una vez y se restaura para ambos', () async {
    final shared = coverFile(coversA, 'compartida.jpg', List.filled(1500, 7));
    await addBook(dbA, 'Tomo 1', cover: shared.path);
    await addBook(dbA, 'Tomo 2', cover: shared.path);

    final zip = await saveZip(dbA, 'r.zip');
    final entries = ZipDecoder().decodeBytes(zip.readAsBytesSync()).files.where((f) => f.name.startsWith('covers/'));
    expect(entries, hasLength(1));

    await BackupService.restore(dbB, await read(zip), coversDir: coversB.path);
    final covers = (await dbB.select(dbB.books).get()).map((b) => b.coverUrl).toSet();
    expect(covers, hasLength(1));
    expect(File(covers.single!).existsSync(), isTrue);
  });

  test('restaura también la exportación .json (sin portadas)', () async {
    await addBook(dbA, 'Dune', cover: coverFile(coversA, 'c.jpg', [1, 2]).path);
    final json = File(p.join(tmp.path, 'export.json'));
    // El .json de la exportación es el mismo que va dentro del .zip
    final inside = ZipDecoder().decodeBytes(await BackupService.buildZip(dbA)).find('backup.json')!;
    await json.writeAsBytes(inside.content);

    final preview = await read(json);
    expect(preview.coverFiles, isEmpty);
    await BackupService.restore(dbB, preview, coversDir: coversB.path);

    final book = (await dbB.select(dbB.books).get()).single;
    expect(book.title, 'Dune');
    expect(book.coverUrl, isNull);
  });

  group('archivos no válidos', () {
    Future<void> expectRejected(List<int> bytes, String messagePart) async {
      final f = File(p.join(tmp.path, 'malo_${messagePart.hashCode}'))..writeAsBytesSync(bytes);
      await expectLater(
        read(f),
        throwsA(isA<BackupException>().having((e) => e.message, 'message', contains(messagePart))),
      );
    }

    test('texto cualquiera', () => expectRejected(utf8.encode('hola'), 'no es un respaldo'));

    test('JSON de otra app', () => expectRejected(utf8.encode(jsonEncode({'app': 'otra', 'books': []})), 'no es un respaldo'));

    test('respaldo de una versión más nueva', () => expectRejected(
          utf8.encode(jsonEncode({'app': 'book_tracker', 'format_version': 99, 'books': []})),
          'versión más nueva',
        ));

    test('.zip sin backup.json', () {
      final archive = Archive()..addFile(ArchiveFile.string('otro.txt', 'x'));
      return expectRejected(ZipEncoder().encodeBytes(archive), 'no es un respaldo de Book Tracker');
    });

    test('.zip dañado se rechaza', () async {
      final f = File(p.join(tmp.path, 'roto.zip'))..writeAsBytesSync([0x50, 0x4B, 0x03, 0x04, 1, 2, 3]);
      // Según cómo esté dañado, se informa como "dañado" o "no es un respaldo"
      await expectLater(read(f), throwsA(isA<BackupException>()));
    });
  });

  test('un libro dañado en el respaldo no cambia nada de la biblioteca actual', () async {
    final oldCover = coverFile(coversB, 'actual.jpg', [5, 5, 5]);
    await addBook(dbB, 'Mi libro', cover: oldCover.path);

    final preview = BackupPreview(
      exportedAt: null,
      books: [
        {'id': 1, 'title': 'Bien', 'author': 'A', 'total_pages': 100},
        {'id': 2, 'title': '', 'author': 'Sin título', 'total_pages': 100}, // dañado
      ],
      notes: const [],
      sessions: const [],
      coverFiles: const {},
    );

    await expectLater(
      BackupService.restore(dbB, preview, coversDir: coversB.path),
      throwsA(isA<BackupException>().having((e) => e.message, 'message', contains('No se cambió nada'))),
    );
    expect((await dbB.select(dbB.books).get()).single.title, 'Mi libro');
    expect(oldCover.existsSync(), isTrue);
  });

  test('ignora notas y sesiones de libros que no existen y recorta textos largos', () async {
    final preview = BackupPreview(
      exportedAt: null,
      books: [
        {'id': 1, 'title': 'T' * 150, 'author': 'A', 'total_pages': 100, 'read_pages': 500, 'status': 9, 'rating': 8},
      ],
      notes: [
        {'book_id': 1, 'content': 'n' * 1200},
        {'book_id': 99, 'content': 'huérfana'},
      ],
      sessions: [
        {'book_id': 1, 'date': '2026-01-02T00:00:00.000Z', 'seconds': 60},
        {'book_id': 99, 'date': '2026-01-02T00:00:00.000Z', 'seconds': 60},
      ],
      coverFiles: const {},
    );

    final result = await BackupService.restore(dbB, preview, coversDir: coversB.path);
    expect(result.notes, 1);
    expect(result.sessions, 1);

    final book = (await dbB.select(dbB.books).get()).single;
    expect(book.title.length, 100);
    expect(book.readPages, 100); // no supera el total
    expect(book.status, 0); // estado desconocido → pendiente
    expect(book.rating, 0); // calificación fuera de rango
    expect((await dbB.select(dbB.notes).get()).single.content.length, 1000);
  });

  test('un .zip con rutas tipo "../" no escribe fuera de su carpeta', () async {
    final archive = Archive()
      ..addFile(ArchiveFile.string('backup.json', jsonEncode({'app': 'book_tracker', 'format_version': 1, 'books': []})))
      ..addFile(ArchiveFile.bytes('covers/../../malicioso.jpg', [1, 2, 3]));
    final zip = File(p.join(tmp.path, 'trampa.zip'))..writeAsBytesSync(ZipEncoder().encodeBytes(archive));

    final work = Directory(p.join(tmp.path, 'work_trampa'));
    final preview = await BackupService.read(zip, work);

    expect(File(p.join(tmp.path, 'malicioso.jpg')).existsSync(), isFalse);
    expect(preview.coverFiles['malicioso.jpg']!.parent.path, work.path);
  });
}
