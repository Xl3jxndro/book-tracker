import 'package:book_tracker/providers/streak_save_provider.dart';
import 'package:book_tracker/services/rewarded_ads.dart';
import 'package:book_tracker/services/streak.dart';
import 'package:book_tracker/services/streak_save.dart';
import 'package:book_tracker/widgets/streak_save_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<DateTime> _nov(List<int> days) => [for (final d in days) DateTime(2026, 11, d, 21)];

void main() {
  final now = DateTime(2026, 11, 19, 9); // hoy 19; ayer 18; anteayer 17

  group('cuándo se ofrece', () {
    StreakSaveOffer? offer(List<int> days, {Set<DateTime> saved = const {}, DateTime? lastSave, DateTime? dismissed}) =>
        StreakSave.offer(readingDates: _nov(days), savedDays: saved, now: now, lastSaveAt: lastSave, dismissedOn: dismissed);

    test('ayer no se leyó y la racha hasta anteayer era de 2+ días', () {
      expect(offer([14, 15, 16, 17]), StreakSaveOffer(4, DateTime(2026, 11, 18)));
    });

    test('también si hoy ya se leyó (ayer sigue faltando)', () {
      expect(offer([15, 16, 17, 19]), StreakSaveOffer(3, DateTime(2026, 11, 18)));
    });

    test('no se ofrece: ayer sí se leyó, racha corta o perdida hace más de un día', () {
      expect(offer([16, 17, 18]), isNull);
      expect(offer([17]), isNull, reason: 'racha de 1 día');
      expect(offer([13, 14, 15, 16]), isNull, reason: 'faltan dos días');
      expect(offer([]), isNull);
    });

    test('una vez por semana y no otra vez el mismo día si se rechazó', () {
      expect(offer([14, 15, 16, 17], lastSave: DateTime(2026, 11, 14)), isNull);
      expect(offer([14, 15, 16, 17], lastSave: DateTime(2026, 11, 12)), isNotNull, reason: 'hace 7 días');
      expect(offer([14, 15, 16, 17], dismissed: DateTime(2026, 11, 19, 8)), isNull);
      expect(offer([14, 15, 16, 17], dismissed: DateTime(2026, 11, 18)), isNotNull);
    });

    test('un día salvado antes cuenta como parte de la racha', () {
      // 14, 15 (salvado), 16, 17 → racha de 4
      final o = offer([14, 16, 17], saved: {DateTime(2026, 11, 15)});
      expect(o?.lostStreak, 4);
    });
  });

  test('con el día salvado la racha sigue', () {
    final dates = _nov([14, 15, 16, 17]);
    expect(ReadingStreak.current(dates, now), 0, reason: 'sin salvar, se perdió');
    final saved = StreakSave.withSavedDays(dates, {DateTime(2026, 11, 18)});
    expect(ReadingStreak.current(saved, now), 5);
  });

  group('guardado', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('salvar guarda el día y la fecha del último uso; rechazar guarda hoy', () async {
      var s = await StreakSave.save(DateTime(2026, 11, 18), now: now);
      expect(s.savedDays, {DateTime(2026, 11, 18)});
      expect(s.lastSaveAt, DateTime(2026, 11, 19));

      s = await StreakSave.save(DateTime(2026, 11, 25), now: DateTime(2026, 11, 26));
      expect(s.savedDays, {DateTime(2026, 11, 18), DateTime(2026, 11, 25)});

      s = await StreakSave.dismiss(now: now);
      expect(s.dismissedOn, DateTime(2026, 11, 19));
      expect((await StreakSave.load()).savedDays, hasLength(2));
    });
  });

  group('hoja', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<ProviderContainer> pump(WidgetTester tester, Future<RewardedResult> Function() ad) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(builder: (context) => TextButton(
                  onPressed: () => showStreakSaveSheet(context, StreakSaveOffer(12, DateTime(2026, 11, 18)), showAd: ad),
                  child: const Text('abrir'),
                )),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('viendo el anuncio entero se salva la racha', (tester) async {
      final container = await pump(tester, () async => RewardedResult.rewarded);
      expect(find.text('Tu racha de 12 días se rompió'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.runAsync(() async {
        await tester.tap(find.text('Ver anuncio y salvar mi racha'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(find.text('Tu racha de 12 días se rompió'), findsNothing);
      expect(container.read(streakSaveProvider).savedDays, {DateTime(2026, 11, 18)});
      expect(find.textContaining('¡Racha salvada!'), findsOneWidget);
    });

    testWidgets('si se cierra antes o no hay anuncio, no se salva y se explica', (tester) async {
      var result = RewardedResult.closedEarly;
      final container = await pump(tester, () async => result);

      await tester.tap(find.text('Ver anuncio y salvar mi racha'));
      await tester.pumpAndSettle();
      expect(find.text('Hay que ver el anuncio completo para salvar la racha.'), findsOneWidget);

      result = RewardedResult.unavailable;
      await tester.tap(find.text('Ver anuncio y salvar mi racha'));
      await tester.pumpAndSettle();
      expect(find.textContaining('no hay anuncios disponibles'), findsOneWidget);
      expect(container.read(streakSaveProvider).savedDays, isEmpty);
    });
  });
}
