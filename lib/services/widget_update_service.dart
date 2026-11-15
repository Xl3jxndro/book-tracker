import 'package:flutter/foundation.dart';
import 'dart:async';
import '../database/database.dart';
import '../services/timer_persistence.dart';
import './widget_service.dart';

class WidgetUpdateService {
  static final WidgetUpdateService _instance = WidgetUpdateService._internal();
  
  factory WidgetUpdateService() {
    return _instance;
  }
  
  WidgetUpdateService._internal();

  Timer? _updateTimer;
  static const Duration _updateInterval = Duration(seconds: 5);

  /// Iniciar actualización periódica del widget si hay sesión activa
  void startPeriodicUpdate() {
    if (_updateTimer != null) {
      debugPrint('⏱️ Widget update timer ya está activo');
      return;
    }

    debugPrint('⏱️ Iniciando actualización periódica del widget');
    _updateTimer = Timer.periodic(_updateInterval, (_) async {
      await _updateWidgetIfNeeded();
    });
  }

  /// Detener la actualización periódica
  void stopPeriodicUpdate() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
      _updateTimer = null;
      debugPrint('⏱️ Actualización periódica del widget detenida');
    }
  }

  /// Actualizar el widget si hay sesión activa
  Future<void> _updateWidgetIfNeeded() async {
    try {
      final session = await TimerPersistence.getActiveSession();
      
      if (session != null) {
        final bookId = session['bookId'] as int;
        final elapsedSeconds = session['elapsedSeconds'] as int;
        final isPaused = session['isPaused'] as bool;

        debugPrint('⏱️ Actualizando widget con tiempo: ${elapsedSeconds}s, pausado: $isPaused');
        
        // Aquí podrías actualizar el widget con el tiempo actual
        // await WidgetService.updateWidget(...);
      }
    } catch (e) {
      debugPrint('❌ Error en actualización periódica: $e');
    }
  }

  /// Actualizar el widget con datos del libro
  Future<void> updateWithBook(Book book, {ReadingSession? todaySession}) async {
    try {
      final session = await TimerPersistence.getActiveSession();
      
      await WidgetService.updateWidget(
        currentBook: book,
        todaySession: todaySession,
        isSessionActive: session != null && !session['isPaused'],
        elapsedSeconds: session?['elapsedSeconds'] ?? 0,
      );
    } catch (e) {
      debugPrint('Error actualizando widget con libro: $e');
    }
  }

  /// Limpiar el widget
  Future<void> clearWidget() async {
    try {
      await WidgetService.clearWidget();
    } catch (e) {
      debugPrint('Error limpiando widget: $e');
    }
  }

  void dispose() {
    stopPeriodicUpdate();
  }
}
