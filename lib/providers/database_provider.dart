import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

// Este provider mantiene una única instancia de la base de datos en toda la app
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  // Nos aseguramos de cerrar la base de datos cuando el provider ya no se use
  ref.onDispose(() => db.close());
  return db;
});

// Este StreamProvider nos permite "escuchar" la lista de libros en tiempo real
final booksStreamProvider = StreamProvider<List<Book>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBooks();
});

// Provider para observar TODAS las sesiones de lectura.
// Las estadísticas (racha, mapa de calor, gráfico mensual, tiempo total y logros)
// necesitan el historial completo; antes solo veían los últimos 7 días.
final sessionsStreamProvider = StreamProvider<List<ReadingSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSessions();
});

// Provider para el estado de la búsqueda
final searchQueryProvider = StateProvider<String>((ref) => '');

// NUEVO: Provider que combina los libros con la búsqueda (Optimización para la UI)
final filteredBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(booksStreamProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();

  return booksAsync.whenData((books) {
    if (query.isEmpty) return books;
    return books.where((book) {
      return book.title.toLowerCase().contains(query) || 
             book.author.toLowerCase().contains(query);
    }).toList();
  });
});

// Provider que expone el tiempo total leído HOY
final totalTimeTodayProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchTotalTimeToday();
});