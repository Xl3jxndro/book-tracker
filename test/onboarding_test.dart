import 'package:book_tracker/providers/tutorial_provider.dart';
import 'package:book_tracker/screens/onboarding_screen.dart';
import 'package:book_tracker/widgets/whats_new_sheet.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<TutorialNotifier> _notifier(Map<String, Object> prefs) async {
  SharedPreferences.setMockInitialValues(prefs);
  final container = ProviderContainer.test();
  container.listen(tutorialProvider, (_, _) {});
  final n = container.read(tutorialProvider.notifier);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return n;
}

void main() {
  group('quién ve la bienvenida', () {
    test('instalación nueva: primero la bienvenida, después los tooltips', () async {
      final n = await _notifier({});
      expect(n.state.stage, TutorialStage.onboarding);
      await n.completeOnboarding();
      expect(n.state.stage, TutorialStage.home);
    });

    test('quien actualiza (ya vio los tooltips) no ve la bienvenida', () async {
      final n = await _notifier({'hasSeenHomeScreenTutorial': true, 'hasSeenNavTutorial': true});
      expect(n.state.stage, TutorialStage.bookDetails);
    });

    test('"Ver la bienvenida de nuevo" la vuelve a mostrar', () async {
      final n = await _notifier({
        'hasSeenOnboarding': true,
        'hasSeenHomeScreenTutorial': true,
        'hasSeenNavTutorial': true,
        'hasSeenDetailsTutorial': true,
      });
      expect(n.state.stage, TutorialStage.completed);
      await n.resetTutorials();
      expect(n.state.stage, TutorialStage.onboarding);
    });
  });

  group('novedades', () {
    test('una sola vez por versión', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await WhatsNew.shouldShow(), isTrue);
      await WhatsNew.markSeen();
      expect(await WhatsNew.shouldShow(), isFalse);

      SharedPreferences.setMockInitialValues({WhatsNew.prefsKey: '1.1.0'});
      expect(await WhatsNew.shouldShow(), isTrue, reason: 'vio las de otra versión');
    });

    testWidgets('la hoja se dibuja sin desbordarse en un teléfono pequeño', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: WhatsNewSheet())));
      expect(tester.takeException(), isNull);
      expect(find.text('Lo nuevo en Book Tracker'), findsOneWidget);
      expect(find.text('Mis citas'), findsOneWidget);
    });
  });

  group('pantalla de bienvenida', () {
    Future<List<OnboardingChoice>> pump(WidgetTester tester, {Size size = const Size(360, 640)}) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final choices = <OnboardingChoice>[];
      await tester.pumpWidget(MaterialApp(home: OnboardingScreen(onFinish: choices.add)));
      return choices;
    }

    testWidgets('4 páginas con "Siguiente" y, al final, las opciones para empezar', (tester) async {
      final choices = await pump(tester);
      expect(find.text('Tu biblioteca, en un toque'), findsOneWidget);
      expect(tester.takeException(), isNull);

      for (final title in ['Lee con foco', 'Guarda lo que te marca', 'Hazlo hábito']) {
        await tester.tap(find.text('Siguiente'));
        await tester.pumpAndSettle();
        expect(find.text(title), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'sin desbordes en $title');
      }

      expect(find.text('Siguiente'), findsNothing);
      await tester.tap(find.text('Importar de Goodreads'));
      expect(choices, [OnboardingChoice.importGoodreads]);
      await tester.tap(find.text('Añadir mi primer libro'));
      expect(choices.last, OnboardingChoice.addBook);
    });

    testWidgets('"Saltar" equivale a explorar', (tester) async {
      final choices = await pump(tester);
      await tester.tap(find.text('Saltar'));
      expect(choices, [OnboardingChoice.explore]);
    });

    testWidgets('también cabe en pantallas muy bajas', (tester) async {
      await pump(tester, size: const Size(320, 520));
      expect(tester.takeException(), isNull);
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
