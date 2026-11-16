import 'package:book_tracker/widgets/app_lock_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Reproduce el caso real: app abierta en un libro (con portada Hero), se
/// bloquea al volver, se desbloquea, y luego hay que poder abrir un diálogo
/// ("¿En qué página quedaste?") y volver atrás.
class _Harness extends StatefulWidget {
  const _Harness();
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  bool locked = false;

  void setLocked(bool value) => setState(() => locked = value);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      builder: (context, child) => AppLockOverlay(
        isLocked: locked,
        lockScreenBuilder: (_) => const Scaffold(body: Center(child: Text('Pantalla de bloqueo'))),
        child: child!,
      ),
    );
  }
}

void main() {
  testWidgets('tras bloquear y desbloquear se puede abrir un diálogo y volver atrás', (tester) async {
    await tester.pumpWidget(const _Harness());
    final harness = tester.state<_HarnessState>(find.byType(_Harness));

    await tester.tap(find.text('Abrir libro'));
    await tester.pumpAndSettle();
    expect(find.text('Detalle del libro'), findsOneWidget);

    // Se bloquea al volver a la app...
    harness.setLocked(true);
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de bloqueo'), findsOneWidget);

    // ...y se desbloquea con la huella
    harness.setLocked(false);
    await tester.pumpAndSettle();
    expect(find.text('Pantalla de bloqueo'), findsNothing);
    expect(find.text('Detalle del libro'), findsOneWidget, reason: 'sigue en la misma pantalla');

    // 1. El diálogo de páginas debe aparecer
    await tester.tap(find.text('Finalizar lectura'));
    await tester.pumpAndSettle();
    expect(find.text('¿En qué página quedaste?'), findsOneWidget);

    // 2. Y se debe poder volver atrás (cerrar el diálogo y salir del libro)
    Navigator.of(tester.element(find.text('¿En qué página quedaste?'))).pop();
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('Detalle del libro'))).pop();
    await tester.pumpAndSettle();
    expect(find.text('Detalle del libro'), findsNothing);
    expect(find.text('Abrir libro'), findsOneWidget);
  });
}
