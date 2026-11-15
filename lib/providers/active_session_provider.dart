import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import '../services/timer_persistence.dart';

// Provider para la sesión de lectura activa
final activeSessionProvider = StateNotifierProvider<ActiveSessionNotifier, AsyncValue<ActiveSession?>>((ref) {
  return ActiveSessionNotifier();
});

class ActiveSession {
  final int bookId;
  final int elapsedSeconds;
  final bool isPaused;
  final DateTime lastUpdated;

  ActiveSession({
    required this.bookId,
    required this.elapsedSeconds,
    required this.isPaused,
    required this.lastUpdated,
  });

  ActiveSession copyWith({
    int? bookId,
    int? elapsedSeconds,
    bool? isPaused,
    DateTime? lastUpdated,
  }) {
    return ActiveSession(
      bookId: bookId ?? this.bookId,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isPaused: isPaused ?? this.isPaused,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class ActiveSessionNotifier extends StateNotifier<AsyncValue<ActiveSession?>> {
  ActiveSessionNotifier() : super(const AsyncValue.loading()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final session = await TimerPersistence.getActiveSession();
      if (session != null) {
        state = AsyncValue.data(
          ActiveSession(
            bookId: session['bookId'] as int,
            elapsedSeconds: session['elapsedSeconds'] as int,
            isPaused: session['isPaused'] as bool,
            lastUpdated: DateTime.now(),
          ),
        );
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateSession({
    required int bookId,
    required int elapsedSeconds,
    required bool isPaused,
  }) async {
    try {
      await TimerPersistence.saveSession(
        bookId: bookId,
        isPaused: isPaused,
        accumulatedSeconds: elapsedSeconds,
      );
      state = AsyncValue.data(
        ActiveSession(
          bookId: bookId,
          elapsedSeconds: elapsedSeconds,
          isPaused: isPaused,
          lastUpdated: DateTime.now(),
        ),
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> clearSession() async {
    try {
      await TimerPersistence.clearSession();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> pauseSession() async {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current != null) {
      await updateSession(
        bookId: current.bookId,
        elapsedSeconds: current.elapsedSeconds,
        isPaused: true,
      );
    }
  }

  Future<void> resumeSession() async {
    final current = state.maybeWhen(data: (data) => data, orElse: () => null);
    if (current != null) {
      await updateSession(
        bookId: current.bookId,
        elapsedSeconds: current.elapsedSeconds,
        isPaused: false,
      );
    }
  }
}

// Provider que combina el libro activo con su sesión de hoy
final currentBookWithSessionProvider = Provider<AsyncValue<({Book book, ReadingSession? session})>>((ref) {
  // Esta será una implementación simplificada
  // En la práctica, necesitarás buscar el último libro no finalizado
  throw UnimplementedError('Implementar según la lógica de selección del libro actual');
});
