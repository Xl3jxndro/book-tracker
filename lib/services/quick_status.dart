import 'package:drift/drift.dart' show Value;
import 'package:material_ui/material_ui.dart' show IconData, Icons;

import '../database/database.dart';
import '../l10n/app_localizations.dart';

/// Tipo de acción rápida (los textos se eligen al mostrarla, en el idioma en uso).
enum QuickStatusKind { start, finish, resume }

/// Acción rápida al deslizar un libro hacia la derecha en la biblioteca.
class QuickStatusAction {
  final QuickStatusKind kind;
  final IconData icon;
  const QuickStatusAction(this.kind, this.icon);

  /// Texto del fondo al deslizar ("Empezar a leer").
  String label(AppLocalizations l10n) => switch (kind) {
        QuickStatusKind.start => l10n.homeQuickStart,
        QuickStatusKind.finish => l10n.homeQuickFinish,
        QuickStatusKind.resume => l10n.homeQuickResume,
      };

  /// Aviso tras la acción ('Empezaste "Título"').
  String doneMessage(AppLocalizations l10n, String title) => switch (kind) {
        QuickStatusKind.start => l10n.homeQuickStartedSnack(title),
        QuickStatusKind.finish => l10n.homeQuickFinishedSnack(title),
        QuickStatusKind.resume => l10n.homeQuickResumedSnack(title),
      };
}

/// Acción disponible según el estado (ninguna para un libro terminado).
QuickStatusAction? quickStatusAction(Book book) => switch (book.status) {
      0 => const QuickStatusAction(QuickStatusKind.start, Icons.play_arrow_rounded),
      1 => const QuickStatusAction(QuickStatusKind.finish, Icons.check_rounded),
      3 => const QuickStatusAction(QuickStatusKind.resume, Icons.replay_rounded),
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
