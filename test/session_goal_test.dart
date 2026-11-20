import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/providers/database_provider.dart';
import 'package:book_tracker/services/session_goal.dart';
import 'package:book_tracker/services/session_goal_alarm.dart';
import 'package:book_tracker/services/timer_persistence.dart';
import 'package:book_tracker/widgets/timer_widget.dart';
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('meta de la sesión', () {
    test('tiempo: progreso, cumplida y lo que falta', () {
      const goal = SessionGoal.time(30);
      expect(goal.progress(0), 0);
      expect(goal.progress(15 * 60), 0.5);
      expect(goal.progress(40 * 60), 1, reason: 'no pasa de 1');
      expect(goal.timeReached(29 * 60 + 59), isFalse);
      expect(goal.timeReached(30 * 60), isTrue);
      expect(goal.remainingSeconds(20 * 60), 600);
      expect(goal.remainingSeconds(31 * 60), 0);
      expect(goal.timeProgressLabel(18 * 60 + 40), '18 / 30 min');
      expect(goal.label, '30 min');
    });

    test('páginas', () {
      const goal = SessionGoal.page(150);
      expect(goal.isTime, isFalse);
      expect(goal.pageReached(149), isFalse);
      expect(goal.pageReached(150), isTrue);
      expect(goal.timeReached(99999), isFalse);
      expect(goal.label, 'hasta la pág. 150');
    });

    test('se guarda y se lee', () {
      expect(SessionGoal.decode(const SessionGoal.time(45).encode()), const SessionGoal.time(45));
      expect(SessionGoal.decode(const SessionGoal.page(12).encode()), const SessionGoal.page(12));
      for (final bad in [null, '', 't:', 'x:10', 't:0', 't:-5', 'p:abc']) {
        expect(SessionGoal.decode(bad), isNull, reason: '$bad');
      }
    });
  });

  group('guardado con la sesión', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('la meta vive con la sesión y se borra al terminarla; la de tiempo se recuerda', () async {
      await TimerPersistence.saveSession(bookId: 1, isPaused: false, accumulatedSeconds: 0);
      await TimerPersistence.saveGoal(const SessionGoal.time(30));
      expect(await TimerPersistence.getGoal(), const SessionGoal.time(30));

      await TimerPersistence.clearSession();
      expect(await TimerPersistence.getGoal(), isNull);
      expect(await TimerPersistence.lastTimeGoal(), const SessionGoal.time(30));
    });

    test('la meta de páginas no se recuerda; elegir "libre" tampoco propone nada', () async {
      await TimerPersistence.saveGoal(const SessionGoal.time(15));
      await TimerPersistence.saveGoal(const SessionGoal.page(80));
      expect(await TimerPersistence.lastTimeGoal(), const SessionGoal.time(15));

      await TimerPersistence.saveGoal(null);
      expect(await TimerPersistence.getGoal(), isNull);
      expect(await TimerPersistence.lastTimeGoal(), isNull);
    });
  });

  group('cuándo avisar (notificación fuera de la app)', () {
    PersistedSession running(int seconds) => PersistedSession(
          bookId: 1,
          isPaused: false,
          accumulatedSeconds: seconds,
          runningSince: DateTime.now(),
        );

    test('corriendo con meta de tiempo pendiente: avisa en lo que falta', () {
      expect(SessionGoalAlarm.secondsUntilGoal(running(20 * 60), const SessionGoal.time(30)), closeTo(600, 2));
    });

    test('no avisa: en pausa, sin sesión, sin meta, meta de páginas o ya cumplida', () {
      const paused = PersistedSession(bookId: 1, isPaused: true, accumulatedSeconds: 60, runningSince: null);
      expect(SessionGoalAlarm.secondsUntilGoal(paused, const SessionGoal.time(30)), isNull);
      expect(SessionGoalAlarm.secondsUntilGoal(null, const SessionGoal.time(30)), isNull);
      expect(SessionGoalAlarm.secondsUntilGoal(running(60), null), isNull);
      expect(SessionGoalAlarm.secondsUntilGoal(running(60), const SessionGoal.page(100)), isNull);
      expect(SessionGoalAlarm.secondsUntilGoal(running(31 * 60), const SessionGoal.time(30)), isNull);
    });
  });

  testWidgets('el cronómetro propone la última meta y deja cambiarla', (tester) async {
    SharedPreferences.setMockInitialValues({'session_goal_last_minutes': 30});
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const book = Book(id: 1, title: 'Satanás', author: 'Mario Mendoza', totalPages: 285, readPages: 40, totalReadTime: 0, status: 1);

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: TimerWidget(book: book)))),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Meta: 30 min'), findsOneWidget);

    await tester.tap(find.byKey(const Key('session_goal_row')));
    await tester.pumpAndSettle();
    expect(find.text('🎯 Meta de esta sesión'), findsOneWidget);

    await tester.tap(find.text('45 min'));
    await tester.pumpAndSettle();
    expect(find.text('Meta: 45 min'), findsOneWidget);
    expect(await TimerPersistence.getGoal(), const SessionGoal.time(45));

    // Meta de páginas: no deja elegir una página ya leída
    await tester.tap(find.byKey(const Key('session_goal_row')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hasta la página…'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '30');
    await tester.pump();
    expect(find.text('Ya vas en la pág. 40'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '120');
    await tester.pump();
    await tester.tap(find.text('LISTO'));
    await tester.pumpAndSettle();
    expect(find.text('Meta: hasta la pág. 120'), findsOneWidget);
  });
}
