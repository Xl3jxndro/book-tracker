import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_provider.dart';
import '../database/database.dart';

class ReadingStats {
  final int totalSeconds;
  final int totalBooks;
  final int finishedBooks;

  ReadingStats({
    required this.totalSeconds,
    required this.totalBooks,
    required this.finishedBooks,
  });
}

// Provider de Estadísticas Generales (Ya lo tenías)
final statsProvider = StreamProvider<ReadingStats>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllBooks().map((books) {
    int totalSecs = 0;
    int finished = 0;
    for (var b in books) {
      totalSecs += b.totalReadTime;
      if (b.status == 2) finished++;
    }
    return ReadingStats(
      totalSeconds: totalSecs,
      totalBooks: books.length,
      finishedBooks: finished,
    );
  });
});

// --- NUEVO: Provider de Sesiones Recientes (ESTO SOLUCIONA EL CARGANDO) ---
final recentSessionsProvider = StreamProvider<List<ReadingSession>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchAllSessions();
});