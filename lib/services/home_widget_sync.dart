import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database.dart';
import '../providers/current_book_provider.dart';
import '../providers/daily_goal_provider.dart';
import 'app_language.dart';
import 'session_goal_alarm.dart';
import 'timer_persistence.dart';

/// Rutas (URIs) que usa el widget de Android. Deben coincidir con
/// `BookTrackerWidgetProvider.kt`.
class WidgetUris {
  static const scheme = 'booktracker';
  static const togglePause = 'toggle_pause'; // segundo plano
  static const finishSession = 'finish_session'; // abre la app
  static const openBook = 'open_book'; // abre la app
}

/// Escribe en el widget de pantalla de inicio el estado actual de la app:
/// libro mostrado, progreso, minutos de hoy, meta diaria y cronómetro.
///
/// Las claves se leen en `BookTrackerWidgetProvider.kt`; todos los valores se
/// guardan como texto.
class HomeWidgetSync {
  static const _androidName = 'BookTrackerWidgetProvider';

  static AppDatabase? _db;
  static bool _isRefreshing = false;
  static bool _refreshPending = false;

  /// Conecta la base de datos de la app (se llama una vez al arrancar).
  static void attach(AppDatabase db) => _db = db;

  /// Actualiza todo el widget. Si llegan varias peticiones seguidas se agrupan.
  static Future<void> refresh() async {
    if (_isRefreshing) {
      _refreshPending = true;
      return;
    }
    _isRefreshing = true;
    try {
      do {
        _refreshPending = false;
        await _refreshOnce();
      } while (_refreshPending);
    } finally {
      _isRefreshing = false;
    }
  }

  /// Solo actualiza el cronómetro (no necesita base de datos). Lo usa el
  /// callback en segundo plano del widget.
  static Future<void> refreshSessionOnly() async {
    try {
      await _writeLabels();
      await _writeSession(await TimerPersistence.getActiveSession());
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (e) {
      debugPrint('❌ Error actualizando sesión del widget: $e');
    }
  }

  static Future<void> _refreshOnce() async {
    try {
      var session = await TimerPersistence.getActiveSession();
      final db = _db;
      if (db != null) {
        final shownBookId = await _writeBook(db, session);
        // Sesión de un libro que ya no existe (fue borrado): se descarta
        if (session != null && session.bookId != shownBookId) {
          await TimerPersistence.clearSession();
          session = null;
        }
      }
      await _writeLabels();
      await _writeSession(session);
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (e) {
      debugPrint('❌ Error actualizando widget: $e');
    }
  }

  static Future<void> _save(String key, Object? value) =>
      HomeWidget.saveWidgetData<String>(key, value?.toString());

  /// Textos fijos del widget en el idioma de la app (que puede no ser el del
  /// teléfono). Kotlin los lee con el texto en español como respaldo.
  /// "Hoy x/y min" se guarda como plantilla con {m} y {g}: los minutos los
  /// pone Kotlin (si los datos son de otro día, hoy son 0).
  static Future<void> _writeLabels() async {
    final s = AppLanguage.strings;
    await _save('label_empty_title', s.widgetEmptyTitle);
    await _save('label_empty_subtitle', s.widgetEmptySubtitle);
    await _save('label_reading', s.widgetSessionReading);
    await _save('label_paused', s.widgetSessionPaused);
    await _save('label_pause', s.widgetPause);
    await _save('label_resume', s.widgetResume);
    await _save('label_finish', s.widgetFinish);
    await _save('label_finish_description', s.widgetFinishDescription);
    await _save('label_cover', s.widgetCover);
    await _save('label_today', s.widgetToday('{m}'));
    await _save('label_today_goal', s.widgetTodayGoal('{m}', '{g}'));
  }

  /// Escribe los datos del libro mostrado y devuelve su id (o `null`).
  static Future<int?> _writeBook(AppDatabase db, PersistedSession? session) async {
    final book = await _pickBook(db, session);

    if (book == null) {
      await _save('bookId', null);
      await _save('bookTitle', null);
      return null;
    }

    final progress = book.totalPages > 0
        ? ((book.readPages / book.totalPages) * 100).floor().clamp(0, 100)
        : 0;

    final prefs = await SharedPreferences.getInstance();
    final goal = prefs.getInt(DailyGoalNotifier.prefsKey) ?? DailyGoalNotifier.defaultMinutes;
    final todaySeconds = await db.getTotalSecondsToday();
    final now = DateTime.now();

    await _save('bookId', book.id);
    await _save('bookTitle', book.title);
    await _save('bookAuthor', book.author);
    // Ruta de la portada (archivo de la app): el widget la usa para la
    // miniatura y el fondo con sus colores
    final cover = book.coverUrl;
    await _save('bookCover', (cover != null && cover.isNotEmpty && File(cover).existsSync()) ? cover : null);
    await _save('bookProgress', progress);
    await _save('pagesInfo', AppLanguage.strings.widgetPagesInfo(book.readPages, book.totalPages));
    await _save('bookStatus', _statusLabel(book.status));
    await _save('todayMinutes', todaySeconds ~/ 60);
    await _save('todayDate', _dateKey(now));
    await _save('dailyGoalMinutes', goal);
    return book.id;
  }

  static Future<void> _writeSession(PersistedSession? session) async {
    if (session == null) {
      await _save('sessionState', 'none');
      return;
    }
    await _save('sessionState', session.isPaused ? 'paused' : 'running');
    await _save('sessionBookId', session.bookId);
    await _save('sessionAccumulatedMs', session.accumulatedSeconds * 1000);
    await _save('sessionRunningSinceMs', session.runningSince?.millisecondsSinceEpoch ?? 0);
  }

  /// El "libro actual" (el mismo que muestra el widget). Lo usa también la
  /// notificación diaria para abrirlo.
  static Future<Book?> currentBook(AppDatabase db) async =>
      _pickBook(db, await TimerPersistence.getActiveSession());

  /// Libro a mostrar: el de la sesión activa; si no, el último abierto;
  /// si no, el último "Leyendo"; si no, el último no terminado.
  static Future<Book?> _pickBook(AppDatabase db, PersistedSession? session) async {
    Future<Book?> byId(int id) =>
        (db.select(db.books)..where((t) => t.id.equals(id))).getSingleOrNull();

    if (session != null) {
      final book = await byId(session.bookId);
      if (book != null) return book;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentId = prefs.getInt(CurrentBookNotifier.prefsKey);
    if (currentId != null) {
      final book = await byId(currentId);
      if (book != null) return book;
    }

    final reading = await (db.select(db.books)
          ..where((t) => t.status.equals(1))
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
    if (reading != null) return reading;

    return (db.select(db.books)
          ..where((t) => t.status.equals(2).not())
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .getSingleOrNull();
  }

  static String _statusLabel(int status) {
    switch (status) {
      case 0: return AppLanguage.strings.widgetStatusToRead;
      case 1: return AppLanguage.strings.widgetStatusReading;
      case 2: return AppLanguage.strings.widgetStatusFinished;
      case 3: return AppLanguage.strings.widgetStatusAbandoned;
      default: return '';
    }
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Callback que ejecuta el widget en segundo plano (sin abrir la app).
/// Debe ser una función de nivel superior marcada como entry-point.
@pragma('vm:entry-point')
Future<void> homeWidgetBackgroundCallback(Uri? uri) async {
  if (uri?.host != WidgetUris.togglePause) return;
  // Isolate aparte: el idioma de la app aún no está cargado
  try {
    await AppLanguage.load();
  } catch (e) {
    debugPrint('Idioma desde el widget: $e');
  }
  await TimerPersistence.togglePause();
  await HomeWidgetSync.refreshSessionOnly();
  // Pausar cancela el aviso de meta de la sesión; reanudar lo reprograma
  try {
    await SessionGoalAlarm.sync();
  } catch (e) {
    debugPrint('Aviso de meta desde el widget: $e');
  }
}
