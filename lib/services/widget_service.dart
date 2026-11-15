import 'package:home_widget/home_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/database.dart';
import '../services/timer_persistence.dart';

class WidgetService {
  static const String _groupId = 'bookTrackerWidget';
  static const String channelAndroid = 'com.jabc.booktracker/widget';
  static const String updateWidgetAction = 'updateWidget';

  // Inicializar el servicio (llamar desde main)
  static Future<void> initialize() async {
    try {
      // Registrar listener para cambios en el widget
      await HomeWidget.setAppGroupId(_groupId);
      HomeWidget.widgetClicked.listen(_handleWidgetClick);
      debugPrint('✓ Widget Service inicializado');
    } catch (e) {
      debugPrint('❌ Error inicializando Widget Service: $e');
    }
  }

  // Actualizar el widget con datos del libro actual
  static Future<void> updateWidget({
    required Book currentBook,
    ReadingSession? todaySession,
    bool isSessionActive = false,
    int elapsedSeconds = 0,
  }) async {
    try {
      final progress = currentBook.totalPages > 0
          ? ((currentBook.readPages / currentBook.totalPages) * 100).toStringAsFixed(1)
          : '0.0';

      final pagesInfo = '${currentBook.readPages}/${currentBook.totalPages}';

      await HomeWidget.saveWidgetData('bookTitle', currentBook.title);
      await HomeWidget.saveWidgetData('bookAuthor', currentBook.author);
      await HomeWidget.saveWidgetData('bookProgress', progress);
      await HomeWidget.saveWidgetData('pagesInfo', pagesInfo);
      await HomeWidget.saveWidgetData('bookId', currentBook.id.toString());
      
      if (todaySession != null) {
        await HomeWidget.saveWidgetData('todaySessionMinutes', 
          (todaySession.seconds ~/ 60).toString());
        await HomeWidget.saveWidgetData('todaySessionPages', 
          todaySession.pagesRead.toString());
      } else {
        await HomeWidget.saveWidgetData('todaySessionMinutes', '0');
        await HomeWidget.saveWidgetData('todaySessionPages', '0');
      }

      await HomeWidget.saveWidgetData('isSessionActive', isSessionActive.toString());
      await HomeWidget.saveWidgetData('elapsedSeconds', elapsedSeconds.toString());

      // Determinar el estado del libro
      String status;
      if (currentBook.status == 0) status = 'Por leer';
      else if (currentBook.status == 1) status = 'En progreso';
      else if (currentBook.status == 2) status = 'Finalizado';
      else if (currentBook.status == 3) status = 'Pausado';
      else status = 'Desconocido';
      await HomeWidget.saveWidgetData('bookStatus', status);

      // Forzar actualización del widget
      await HomeWidget.updateWidget(
        name: 'BookTrackerWidgetProvider',
        androidName: 'BookTrackerWidgetProvider',
      );

      debugPrint('✓ Widget actualizado correctamente');
    } catch (e) {
      debugPrint('❌ Error actualizando widget: $e');
    }
  }

  // Limpiar widget (cuando no hay libro activo)
  static Future<void> clearWidget() async {
    try {
      await HomeWidget.saveWidgetData('bookTitle', 'Sin libro');
      await HomeWidget.saveWidgetData('bookAuthor', '');
      await HomeWidget.saveWidgetData('bookProgress', '0.0');
      await HomeWidget.saveWidgetData('pagesInfo', '0/0');
      await HomeWidget.saveWidgetData('isSessionActive', 'false');
      await HomeWidget.saveWidgetData('elapsedSeconds', '0');
      await HomeWidget.updateWidget(
        name: 'BookTrackerWidgetProvider',
        androidName: 'BookTrackerWidgetProvider',
      );
      debugPrint('✓ Widget limpiado');
    } catch (e) {
      debugPrint('❌ Error limpiando widget: $e');
    }
  }

  // Manejar clics en el widget
  static void _handleWidgetClick(Uri? uri) {
    if (uri == null) return;
    
    debugPrint('📱 Widget clic recibido: ${uri.toString()}');
    
    // La navegación será manejada por deep linking en main.dart
    // Este callback solo informa que el widget fue presionado
  }

  // Pausar sesión desde el widget
  static Future<void> pauseSessionFromWidget() async {
    try {
      final session = await TimerPersistence.getActiveSession();
      if (session != null) {
        await TimerPersistence.saveSession(
          bookId: session['bookId'],
          isPaused: true,
          accumulatedSeconds: session['elapsedSeconds'],
        );
        debugPrint('✓ Sesión pausada desde widget');
      }
    } catch (e) {
      debugPrint('❌ Error pausando sesión: $e');
    }
  }

  // Finalizar sesión desde el widget
  static Future<void> finishSessionFromWidget() async {
    try {
      // Solo limpiamos la sesión activa, pero guardamos un flag para indicar
      // que debe mostrarse la pantalla de resumen al abrir la app
      final session = await TimerPersistence.getActiveSession();
      if (session != null) {
        final prefs = await _getSharedPrefs();
        await prefs.setBool('show_session_summary', true);
        await prefs.setInt('session_summary_book_id', session['bookId']);
        
        await TimerPersistence.clearSession();
        debugPrint('✓ Sesión finalizada desde widget');
      }
    } catch (e) {
      debugPrint('❌ Error finalizando sesión: $e');
    }
  }

  // Helper para acceder a SharedPreferences
  static Future<SharedPreferences> _getSharedPrefs() async {
    return await SharedPreferences.getInstance();
  }
}
