import 'package:drift/drift.dart' show Value;
import 'package:material_ui/material_ui.dart' show IconData, Icons;

import '../database/database.dart';

/// Acción rápida al deslizar un libro hacia la derecha en la biblioteca.
class QuickStatusAction {
  final String label;
  final String done;
  final IconData icon;
  const QuickStatusAction(this.label, this.done, this.icon);
}

/// Acción disponible según el estado (ninguna para un libro terminado).
QuickStatusAction? quickStatusAction(Book book) => switch (book.status) {
      0 => const QuickStatusAction('Empezar a leer', 'Empezaste', Icons.play_arrow_rounded),
      1 => const QuickStatusAction('Terminado', 'Terminaste', Icons.check_rounded),
      3 => const QuickStatusAction('Retomar', 'Retomaste', Icons.replay_rounded),
      _ => null,
    };

/// El libro tras la acción rápida, con las mismas reglas de fechas y páginas
/// que la edición: pendiente/abandonado → leyendo; leyendo → terminado
/// (completa las páginas). No registra páginas leídas en las estadísticas.
Book? applyQuickStatus(Book book, DateTime now) {
  final newStatus = switch (book.status) {
    0 || 3 => 1,
    1 => 2,
    _ => null,
  };
  if (newStatus == null) return null;
  final readPages = newStatus == 2 ? book.totalPages : book.readPages;
  final dates = AppDatabase.readingDatesAfter(
    oldStatus: book.status,
    newStatus: newStatus,
    startedAt: book.startedAt,
    finishedAt: book.finishedAt,
    hasProgress: readPages > 0,
    now: now,
  );
  return book.copyWith(
    status: newStatus,
    readPages: readPages,
    startedAt: Value(dates.startedAt),
    finishedAt: Value(dates.finishedAt),
  );
}
