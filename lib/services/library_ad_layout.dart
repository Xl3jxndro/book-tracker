/// Elemento de la lista de la biblioteca: un libro o un hueco de anuncio.
sealed class LibraryEntry {
  const LibraryEntry();
}

class BookEntry extends LibraryEntry {
  /// Posición del libro en la lista filtrada.
  final int index;
  const BookEntry(this.index);

  @override
  bool operator ==(Object other) => other is BookEntry && other.index == index;
  @override
  int get hashCode => index.hashCode;
  @override
  String toString() => 'Libro($index)';
}

class AdEntry extends LibraryEntry {
  /// Qué anuncio cargado va aquí (cada hueco usa uno distinto: un mismo
  /// anuncio no puede estar en dos sitios a la vez).
  final int slot;
  const AdEntry(this.slot);

  @override
  bool operator ==(Object other) => other is AdEntry && other.slot == slot;
  @override
  int get hashCode => slot.hashCode + 1000;
  @override
  String toString() => 'Anuncio($slot)';
}

/// Dónde van los anuncios entre los libros:
/// - el primero tras [firstAfter] libros (o al final si hay menos), para que
///   también lo vean quienes tienen pocos libros;
/// - después, uno cada [every] libros;
/// - como máximo [adsReady] (los que ya cargaron) y nunca más de [maxAds].
List<LibraryEntry> libraryLayout({
  required int books,
  required int adsReady,
  int firstAfter = 3,
  int every = 6,
  int maxAds = 3,
}) {
  final entries = <LibraryEntry>[];
  if (books <= 0) return entries;

  final available = adsReady < maxAds ? adsReady : maxAds;
  var nextAdAfter = books < firstAfter ? books : firstAfter;
  var slot = 0;

  for (var i = 0; i < books; i++) {
    entries.add(BookEntry(i));
    if (slot < available && i + 1 == nextAdAfter) {
      entries.add(AdEntry(slot));
      slot++;
      nextAdAfter += every;
    }
  }
  return entries;
}

/// Para la vista de cuadrícula: agrupa los libros seguidos en filas de
/// [columns]; cada anuncio ocupa una fila entera.
List<List<LibraryEntry>> gridRows(List<LibraryEntry> entries, {int columns = 3}) {
  final rows = <List<LibraryEntry>>[];
  var current = <LibraryEntry>[];
  for (final e in entries) {
    if (e is AdEntry) {
      if (current.isNotEmpty) rows.add(current);
      current = [];
      rows.add([e]);
    } else {
      current.add(e);
      if (current.length == columns) {
        rows.add(current);
        current = [];
      }
    }
  }
  if (current.isNotEmpty) rows.add(current);
  return rows;
}
