import 'package:book_tracker/database/database.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<int> addBook({int totalPages = 100, int readPages = 0, int status = 0}) {
    return db.insertBook(BooksCompanion.insert(
      title: 'Libro',
      author: 'Autor',
      totalPages: totalPages,
      readPages: Value(readPages),
      status: Value(status),
    ));
  }

  Future<Book> getBook(int id) =>
      (db.select(db.books)..where((t) => t.id.equals(id))).getSingle();

  Future<List<ReadingSession>> sessions() => db.select(db.readingSessions).get();

  test('avanzar páginas pasa a "Leyendo" y registra la sesión del día', () async {
    final id = await addBook();
    await db.logProgress(id, 30, additionalSeconds: 600);

    final book = await getBook(id);
    expect(book.readPages, 30);
    expect(book.status, 1);
    expect(book.totalReadTime, 600);

    final s = await sessions();
    expect(s, hasLength(1));
    expect(s.single.pagesRead, 30);
    expect(s.single.seconds, 600);
  });

  test('dos registros el mismo día se acumulan en una sola sesión', () async {
    final id = await addBook();
    await db.logProgress(id, 10, additionalSeconds: 60);
    await db.logProgress(id, 25, additionalSeconds: 120);

    final s = await sessions();
    expect(s, hasLength(1));
    expect(s.single.pagesRead, 25);
    expect(s.single.seconds, 180);
  });

  test('se pueden bajar páginas sin tiempo y no crea una sesión vacía', () async {
    final id = await addBook(readPages: 50, status: 1);
    await db.logProgress(id, 40);

    expect((await getBook(id)).readPages, 40);
    expect(await sessions(), isEmpty);
  });

  test('las páginas nunca superan el total ni bajan de 0', () async {
    final id = await addBook(totalPages: 100);
    await db.logProgress(id, 250);
    expect((await getBook(id)).readPages, 100);

    await db.logProgress(id, -5);
    expect((await getBook(id)).readPages, 0);
  });

  test('llegar al total marca "Terminado"; bajar de nuevo vuelve a "Leyendo"', () async {
    final id = await addBook(totalPages: 100);
    await db.logProgress(id, 100);
    expect((await getBook(id)).status, 2);

    await db.logProgress(id, 80);
    expect((await getBook(id)).status, 1);
  });

  test('un terminado que vuelve a 0 pasa a "Pendiente"', () async {
    final id = await addBook(totalPages: 100, readPages: 100, status: 2);
    await db.logProgress(id, 0);
    expect((await getBook(id)).status, 0);
  });

  test('un libro abandonado (DNF) conserva su estado salvo que se termine', () async {
    final id = await addBook(totalPages: 100, readPages: 20, status: 3);
    await db.logProgress(id, 40, additionalSeconds: 60);
    expect((await getBook(id)).status, 3);

    await db.logProgress(id, 100);
    expect((await getBook(id)).status, 2);
  });

  test('sin cambios de páginas ni tiempo no hace nada', () async {
    final id = await addBook(readPages: 10, status: 1);
    await db.logProgress(id, 10);

    expect((await getBook(id)).readPages, 10);
    expect(await sessions(), isEmpty);
  });
}
