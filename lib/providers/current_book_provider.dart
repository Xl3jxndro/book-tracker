import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Libro "actual": el último que el usuario abrió. Lo usa el widget de
/// pantalla de inicio cuando no hay una sesión de lectura activa.
final currentBookProvider = NotifierProvider<CurrentBookNotifier, int?>(CurrentBookNotifier.new);

class CurrentBookNotifier extends Notifier<int?> {
  static const prefsKey = 'current_book_id';

  @override
  int? build() {
    _loadCurrentBook();
    return null;
  }

  Future<void> _loadCurrentBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookId = prefs.getInt(prefsKey);
      if (bookId != null && ref.mounted) {
        state = bookId;
      }
    } catch (e) {
      debugPrint('Error cargando libro actual: $e');
    }
  }

  Future<void> setCurrentBook(int bookId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(prefsKey, bookId);
      state = bookId;
    } catch (e) {
      debugPrint('Error guardando libro actual: $e');
    }
  }

  Future<void> clearCurrentBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefsKey);
      state = null;
    } catch (e) {
      debugPrint('Error limpiando libro actual: $e');
    }
  }
}
