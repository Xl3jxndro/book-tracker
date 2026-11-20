import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/providers/continue_reading_provider.dart';
import 'package:flutter_test/flutter_test.dart';

Book _b(int id, int status) =>
    Book(id: id, title: 'L$id', author: 'A', totalPages: 100, readPages: 10, totalReadTime: 0, status: status);

void main() {
  final books = [_b(1, 1), _b(2, 0), _b(3, 2), _b(4, 1), _b(5, 3)];

  test('la sesión en curso manda', () {
    final r = pickContinueReading(books, currentId: 2, sessionBookId: 1)!;
    expect(r.book.id, 1);
    expect(r.inSession, isTrue);
  });

  test('si no, el último abierto si está pendiente o leyéndose', () {
    expect(pickContinueReading(books, currentId: 2)!.book.id, 2);
    expect(pickContinueReading(books, currentId: 2)!.inSession, isFalse);
  });

  test('un terminado o abandonado abierto no se destaca: el último que se lee', () {
    expect(pickContinueReading(books, currentId: 3)!.book.id, 4);
    expect(pickContinueReading(books, currentId: 5)!.book.id, 4);
    expect(pickContinueReading(books)!.book.id, 4);
  });

  test('sin nada pendiente ni en lectura, no hay tarjeta', () {
    expect(pickContinueReading([_b(3, 2), _b(5, 3)]), isNull);
    expect(pickContinueReading(const []), isNull);
  });
}
