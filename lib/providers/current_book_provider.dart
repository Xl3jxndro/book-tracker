import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../providers/database_provider.dart';
import 'package:drift/drift.dart';

// Provider que mantiene el libro actual seleccionado
final currentBookProvider = StateNotifierProvider<CurrentBookNotifier, int?>((ref) {
  return CurrentBookNotifier(ref);
});

class CurrentBookNotifier extends StateNotifier<int?> {
  final Ref ref;
  
  CurrentBookNotifier(this.ref) : super(null) {
    _loadCurrentBook();
  }

  Future<void> _loadCurrentBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookId = prefs.getInt('current_book_id');
      if (bookId != null) {
        state = bookId;
      }
    } catch (e) {
      debugPrint('Error cargando libro actual: $e');
    }
  }

  Future<void> setCurrentBook(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('current_book_id', bookId);
      state = bookId;
    } catch (e) {
      debugPrint('Error guardando libro actual: $e');
    }
  }

  Future<void> clearCurrentBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('current_book_id');
      state = null;
    } catch (e) {
      debugPrint('Error limpiando libro actual: $e');
    }
  }
}

// Provider que obtiene el libro actual junto con su sesión de hoy
final currentBookWithSessionProvider = FutureProvider<({Book book, ReadingSession? session})?>((ref) async {
  final bookId = ref.watch(currentBookProvider);
  
  if (bookId == null) return null;

  final db = ref.watch(databaseProvider);
  
  try {
    final book = await (db.select(db.books)
      ..where((t) => t.id.equals(bookId)))
      .getSingleOrNull();
    
    if (book == null) return null;

    // Obtener la sesión de hoy
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final session = await (db.select(db.readingSessions)
      ..where((t) => t.bookId.equals(bookId))
      ..where((t) => t.date.isBiggerOrEqualValue(today)))
      .getSingleOrNull();

    return (book: book, session: session);
  } catch (e) {
    debugPrint('Error obteniendo libro actual con sesión: $e');
    return null;
  }
});

// Provider que obtiene todos los libros "En progreso" (status == 1)
final inProgressBooksProvider = StreamProvider<List<Book>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.books)
    ..where((t) => t.status.equals(1)))
    .watch();
});

// Provider que obtiene el primer libro "En progreso" como libro actual
final autoSelectCurrentBookProvider = FutureProvider<Book?>((ref) async {
  final inProgressBooks = await ref.watch(inProgressBooksProvider.future);
  
  if (inProgressBooks.isEmpty) {
    // Si no hay libros en progreso, obtener el primero sin terminar
    final db = ref.watch(databaseProvider);
    return await (db.select(db.books)
      ..where((t) => t.status.equals(2).not())
      ..orderBy([(t) => OrderingTerm(expression: t.id, mode: OrderingMode.desc)])
      ..limit(1))
      .getSingleOrNull();
  }
  
  return inProgressBooks.first;
});
