import 'package:book_tracker/screens/main_wrapper.dart';
import 'package:book_tracker/widgets/app_lock_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// App mínima con el mismo esquema que la real: biblioteca → detalle del
/// libro (portada Hero) → diálogo de páginas, y el bloqueo al volver.
class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final navigatorKey = GlobalKey<NavigatorState>();
  final lock = AppLockRouteController();

  void setLocked(bool locked) => lock.sync(
        navigator: navigatorKey.currentState,
        locked: locked,
        lockScreenBuilder: (_) => const Scaffold(body: Center(child: Text('Pantalla de bloqueo'))),
      );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              const Hero(tag: 'cover_1', child: SizedBox(width: 50, height: 50)),
              TextButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => Scaffold(
                    body: Column(
                      children: [
                        const Hero(tag: 'cover_1', child: SizedBox(width: 100, height: 100)),
                        const Text('Detalle del libro'),
                        TextButton(
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => const AlertDialog(title: Text('¿En qué página quedaste?')),
                          ),
                          child: const Text('Finalizar lectura'),
                        ),
                      ],
                    ),
                  ),
                )),
                child: const Text('Abrir libro'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  group('"atrás" en la pantalla principal', () {
    test('cierra el buscador, luego vuelve a Libros y solo entonces sale', () {
      expect(mainBackAction(tabIndex: 0, isSearching: true), MainBackAction.closeSearch);
      expect(mainBackAction(tabIndex: 2, isSearching: true), MainBackAction.closeSearch);
      expect(mainBackAction(tabIndex: 1, isSearching: false), MainBackAction.goToLibrary);
      expect(mainBackAction(tabIndex: 2, isSearching: false), MainBackAction.goToLibrary);
      expect(mainBackAction(tabIndex: 0, isSearching: false), MainBackAction.leaveApp);
    });
  });

  group('pantalla de bloqueo al volver a la app', () {
    late List<String> nativeCalls;

    setUp(() {
      nativeCalls = [];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('com.jabc.booktracker/app'),
        (call) async {
          nativeCalls.add(call.method);
          return true;
        },
      );
    });

    testWidgets('"atrás" no cierra nada a escondidas: minimiza la app', (tester) async {
      await tester.pumpWidget(const _Harness());
      final harness = tester.state<_HarnessState>(find.byType(_Harness));

      await tester.tap(find.text('Abrir libro'));
      await tester.pumpAndSettle();

      harness.setLocked(true);
      await tester.pumpAndSettle();
      expect(find.text('Pantalla de bloqueo'), findsOneWidget);

      // Gesto o botón "atrás" de Android
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('Pantalla de bloqueo'), findsOneWidget, reason: 'sigue bloqueada');
      expect(nativeCalls, ['moveToBackground']);

      // Al desbloquear sigue en el libro: no se cerró a escondidas
      harness.setLocked(false);
      await tester.pumpAndSettle();
      expect(find.text('Pantalla de bloqueo'), findsNothing);
      expect(find.text('Detalle del libro'), findsOneWidget);
    });

    testWidgets('tras desbloquear funcionan el diálogo y "atrás" paso a paso', (tester) async {
      await tester.pumpWidget(const _Harness());
      final harness = tester.state<_HarnessState>(find.byType(_Harness));

      await tester.tap(find.text('Abrir libro'));
      await tester.pumpAndSettle();
      harness.setLocked(true);
      await tester.pumpAndSettle();
      harness.setLocked(false);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Finalizar lectura'));
      await tester.pumpAndSettle();
      expect(find.text('¿En qué página quedaste?'), findsOneWidget);

      // "Atrás" cierra el diálogo...
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('¿En qué página quedaste?'), findsNothing);
      expect(find.text('Detalle del libro'), findsOneWidget);

      // ...y luego vuelve a la biblioteca
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Detalle del libro'), findsNothing);
      expect(find.text('Abrir libro'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('bloquear dos veces no apila dos pantallas de bloqueo', (tester) async {
      await tester.pumpWidget(const _Harness());
      final harness = tester.state<_HarnessState>(find.byType(_Harness));

      harness.setLocked(true);
      harness.setLocked(true);
      await tester.pumpAndSettle();
      expect(find.text('Pantalla de bloqueo'), findsOneWidget);

      harness.setLocked(false);
      await tester.pumpAndSettle();
      expect(find.text('Pantalla de bloqueo'), findsNothing);
      expect(find.text('Abrir libro'), findsOneWidget);
    });
  });
}
