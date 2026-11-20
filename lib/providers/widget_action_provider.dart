import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/home_widget_sync.dart';
import 'ui_provider.dart';

/// Acción pedida desde el widget de pantalla de inicio que abre la app.
class WidgetAction {
  final int bookId;

  /// `true`: abrir el diálogo para terminar la sesión y guardar páginas.
  final bool finishSession;

  const WidgetAction({required this.bookId, required this.finishSession});

  /// Interpreta `booktracker://open_book?bookId=3` o `booktracker://finish_session?bookId=3`.
  static WidgetAction? fromUri(Uri? uri) {
    if (uri == null || uri.scheme != WidgetUris.scheme) return null;
    final bookId = int.tryParse(uri.queryParameters['bookId'] ?? '');
    if (bookId == null) return null;

    switch (uri.host) {
      case WidgetUris.finishSession:
        return WidgetAction(bookId: bookId, finishSession: true);
      case WidgetUris.openBook:
        return WidgetAction(bookId: bookId, finishSession: false);
      default:
        return null;
    }
  }
}

/// Acción pendiente: se guarda aquí hasta que el usuario pasa el login y
/// `MainWrapper` puede navegar al libro.
final pendingWidgetActionProvider =
    NotifierProvider<SimpleState<WidgetAction?>, WidgetAction?>(() => SimpleState(null));
