import 'package:book_tracker/services/library_ad_layout.dart';
import 'package:flutter_test/flutter_test.dart';

String _render(List<LibraryEntry> entries) =>
    entries.map((e) => switch (e) { BookEntry(:final index) => 'L$index', AdEntry(:final slot) => 'A$slot' }).join(' ');

void main() {
  test('sin libros no hay anuncios', () {
    expect(libraryLayout(books: 0, adsReady: 3), isEmpty);
  });

  test('con 1 o 2 libros el anuncio va al final (antes nunca se veía)', () {
    expect(_render(libraryLayout(books: 1, adsReady: 3)), 'L0 A0');
    expect(_render(libraryLayout(books: 2, adsReady: 3)), 'L0 L1 A0');
  });

  test('el primero tras 3 libros y luego cada 6', () {
    expect(_render(libraryLayout(books: 3, adsReady: 3)), 'L0 L1 L2 A0');
    expect(
      _render(libraryLayout(books: 10, adsReady: 3)),
      'L0 L1 L2 A0 L3 L4 L5 L6 L7 L8 A1 L9',
    );
  });

  test('cada hueco usa un anuncio distinto y como máximo 3', () {
    final entries = libraryLayout(books: 40, adsReady: 10);
    final slots = entries.whereType<AdEntry>().map((e) => e.slot).toList();
    expect(slots, [0, 1, 2]);
  });

  test('solo se usan los anuncios ya cargados', () {
    expect(libraryLayout(books: 20, adsReady: 0).whereType<AdEntry>(), isEmpty);
    expect(libraryLayout(books: 20, adsReady: 1).whereType<AdEntry>().map((e) => e.slot), [0]);
  });

  test('nunca se pierde ni se repite un libro', () {
    for (final books in [1, 2, 3, 4, 7, 9, 15, 16, 50]) {
      for (final ready in [0, 1, 2, 3]) {
        final indices = libraryLayout(books: books, adsReady: ready).whereType<BookEntry>().map((e) => e.index).toList();
        expect(indices, List.generate(books, (i) => i), reason: '$books libros, $ready anuncios');
      }
    }
  });
}
