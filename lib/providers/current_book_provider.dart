import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Libro "actual": el último que el usuario abrió. Lo usa el widget de
/// pantalla de inicio cuando no hay una sesión de lectura activa.
final currentBookProvider = StateNotifierProvider<CurrentBookNotifier, int?>((ref) {
  return CurrentBookNotifier();
});

class CurrentBookNotifier extends StateNotifier<int?> {
  static const prefsKey = 'current_book_id';

  CurrentBookNotifier() : super(null) {
    _loadCurrentBook();
  }

  Future<void> _loadCurrentBook() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final bookId = prefs.getInt(prefsKey);
      if (bookId != null && mounted) {
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
