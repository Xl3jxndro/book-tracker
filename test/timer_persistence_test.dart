import 'package:book_tracker/providers/widget_action_provider.dart';
import 'package:book_tracker/services/timer_persistence.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('TimerPersistence', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('sin sesión devuelve null', () async {
      expect(await TimerPersistence.getActiveSession(), isNull);
    });

    test('una sesión corriendo suma el tiempo transcurrido', () async {
      final tenSecondsAgo = DateTime.now().subtract(const Duration(seconds: 10));
      SharedPreferences.setMockInitialValues({
        'reading_book_id': 7,
        'reading_is_paused': false,
        'reading_accumulated': 60,
        'reading_start_time': tenSecondsAgo.millisecondsSinceEpoch,
      });

      final session = (await TimerPersistence.getActiveSession())!;
      expect(session.bookId, 7);
      expect(session.isPaused, isFalse);
      expect(session.accumulatedSeconds, 60);
      expect(session.elapsedSeconds, inInclusiveRange(70, 71));
    });

    test('togglePause congela el tiempo y luego reanuda desde ahí', () async {
      final tenSecondsAgo = DateTime.now().subtract(const Duration(seconds: 10));
      SharedPreferences.setMockInitialValues({
        'reading_book_id': 7,
        'reading_is_paused': false,
        'reading_accumulated': 60,
        'reading_start_time': tenSecondsAgo.millisecondsSinceEpoch,
      });

      final paused = (await TimerPersistence.togglePause())!;
      expect(paused.isPaused, isTrue);
      expect(paused.runningSince, isNull);
      expect(paused.accumulatedSeconds, inInclusiveRange(70, 71));

      final resumed = (await TimerPersistence.togglePause())!;
      expect(resumed.isPaused, isFalse);
      expect(resumed.runningSince, isNotNull);
      expect(resumed.accumulatedSeconds, paused.accumulatedSeconds);
    });

    test('sin hora de inicio se trata como pausa (no inventa tiempo)', () async {
      SharedPreferences.setMockInitialValues({
        'reading_book_id': 3,
        'reading_is_paused': false,
        'reading_accumulated': 42,
      });

      final session = (await TimerPersistence.getActiveSession())!;
      expect(session.isPaused, isTrue);
      expect(session.elapsedSeconds, 42);
    });

    test('clearSession borra la sesión', () async {
      await TimerPersistence.saveSession(bookId: 1, isPaused: true, accumulatedSeconds: 5);
      await TimerPersistence.clearSession();
      expect(await TimerPersistence.getActiveSession(), isNull);
    });
  });

  group('WidgetAction.fromUri', () {
    test('finish_session con libro', () {
      final action = WidgetAction.fromUri(Uri.parse('booktracker://finish_session?bookId=4'))!;
      expect(action.bookId, 4);
      expect(action.finishSession, isTrue);
    });

    test('open_book con libro', () {
      final action = WidgetAction.fromUri(Uri.parse('booktracker://open_book?bookId=9'))!;
      expect(action.bookId, 9);
      expect(action.finishSession, isFalse);
    });

    test('ignora rutas sin libro, desconocidas o de otro esquema', () {
      expect(WidgetAction.fromUri(Uri.parse('booktracker://home')), isNull);
      expect(WidgetAction.fromUri(Uri.parse('booktracker://toggle_pause?bookId=1')), isNull);
      expect(WidgetAction.fromUri(Uri.parse('https://open_book?bookId=1')), isNull);
      expect(WidgetAction.fromUri(null), isNull);
    });
  });
}
