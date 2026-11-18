import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'today_provider.dart';

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

// La búsqueda, los filtros y el orden de la biblioteca viven en home_screen.dart
// (searchQueryProvider, selectedFilterProvider, sortOptionProvider, filteredBooksProvider).

// Provider que expone el tiempo total leído HOY. Al cambiar el día
// (todayProvider) se vuelve a suscribir con la fecha nueva.
final totalTimeTodayProvider = StreamProvider<int>((ref) {
  final db = ref.watch(databaseProvider);
  final today = ref.watch(todayProvider);
  return db.watchTotalTimeOn(today);
});
// Todas las notas con su libro ("Mis citas"), la más reciente primero.
final notesWithBooksProvider = StreamProvider<List<NoteWithBook>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllNotesWithBooks();
});
