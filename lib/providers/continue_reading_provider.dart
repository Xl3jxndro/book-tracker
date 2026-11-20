import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database.dart';
import '../services/timer_persistence.dart';
import 'current_book_provider.dart';
import 'database_provider.dart';

/// Libro de la tarjeta "Continuar leyendo".
class ContinueReading {
  final Book book;

  /// Hay una sesión de este libro en curso (corriendo o en pausa).
  final bool inSession;

  const ContinueReading(this.book, {this.inSession = false});
}

/// Qué libro destacar: el de la sesión en curso; si no, el último abierto si
/// está pendiente o leyéndose; si no, el último que se está leyendo.
/// Nada si solo hay libros terminados o abandonados.
ContinueReading? pickContinueReading(List<Book> books, {int? currentId, int? sessionBookId}) {
  Book? byId(int? id) => id == null ? null : books.where((b) => b.id == id).firstOrNull;

  final inSession = byId(sessionBookId);
  if (inSession != null) return ContinueReading(inSession, inSession: true);

  final current = byId(currentId);
  if (current != null && (current.status == 0 || current.status == 1)) return ContinueReading(current);

  final reading = books.where((b) => b.status == 1).toList()..sort((a, b) => b.id.compareTo(a.id));
  return reading.isEmpty ? null : ContinueReading(reading.first);
}

final continueReadingProvider = FutureProvider<ContinueReading?>((ref) async {
  final books = ref.watch(booksStreamProvider).value;
  if (books == null || books.isEmpty) return null;
  final currentId = ref.watch(currentBookProvider);
  final session = await TimerPersistence.getActiveSession();
  return pickContinueReading(books, currentId: currentId, sessionBookId: session?.bookId);
});
