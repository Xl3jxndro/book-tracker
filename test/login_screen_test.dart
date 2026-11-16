import 'package:book_tracker/providers/auth_provider.dart';
import 'package:book_tracker/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ProviderContainer> _pumpLogin(WidgetTester tester) async {
  final container = ProviderContainer();
  addTearDown(container.dispose);
  container.read(authProvider); // arranca la carga
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: LoginScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('instalación nueva: crear palabra secreta y entrar sin PIN', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = await _pumpLogin(tester);

    expect(find.text('CREAR PALABRA SECRETA'), findsOneWidget);
    expect(find.text('Usar sin bloqueo'), findsOneWidget);

    await tester.tap(find.text('CREAR PALABRA SECRETA'));
    await tester.pumpAndSettle();

    // Las dos entradas no coinciden: muestra el error y no guarda
    await tester.enterText(find.widgetWithText(TextField, 'Palabra secreta'), 'Macondo');
    await tester.enterText(find.widgetWithText(TextField, 'Repite la palabra'), 'Comala');
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();
    expect(find.text('No coinciden'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextField, 'Repite la palabra'), 'macondo');
    await tester.tap(find.text('GUARDAR'));
    await tester.pumpAndSettle();

    expect(find.text('✨ Palabra Guardada'), findsOneWidget);
    await tester.tap(find.text('AHORA NO'));
    await tester.pumpAndSettle();

    final state = container.read(authProvider);
    expect(state.isPassphraseSet, isTrue);
    expect(state.isPinSet, isFalse);
    expect(state.canEnterApp, isTrue);
  });

  testWidgets('instalación nueva: usar sin bloqueo', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final container = await _pumpLogin(tester);

    await tester.tap(find.text('Usar sin bloqueo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USAR SIN BLOQUEO'));
    await tester.pumpAndSettle();

    expect(container.read(authProvider).isLockEnabled, isFalse);
    expect(container.read(authProvider).canEnterApp, isTrue);
  });

  testWidgets('entrar con la palabra secreta (error y luego acierto)', (tester) async {
    FlutterSecureStorage.setMockInitialValues({AuthNotifier.passphraseKey: 'Macondo'});
    final container = await _pumpLogin(tester);

    expect(find.text('Di la palabra mágica para entrar'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Comala');
    await tester.pump();
    await tester.tap(find.text('REVELAR BIBLIOTECA'));
    await tester.pumpAndSettle();
    expect(find.text('Esa no es la palabra mágica...'), findsOneWidget);
    expect(container.read(authProvider).isAuthenticated, isFalse);

    await tester.enterText(find.byType(TextField), 'macondo');
    await tester.pump();
    await tester.tap(find.text('REVELAR BIBLIOTECA'));
    await tester.pumpAndSettle();
    expect(container.read(authProvider).isAuthenticated, isTrue);
  });

  testWidgets('entrar con el PIN de respaldo', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      AuthNotifier.passphraseKey: 'Macondo',
      AuthNotifier.pinKey: '1234',
    });
    final container = await _pumpLogin(tester);

    await tester.tap(find.text('Usar PIN de respaldo'));
    await tester.pumpAndSettle();
    for (final digit in ['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(container.read(authProvider).isAuthenticated, isTrue);
  });

  testWidgets('5 PIN incorrectos muestran la espera y bloquean el teclado', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      AuthNotifier.passphraseKey: 'Macondo',
      AuthNotifier.pinKey: '1234',
    });
    final container = await _pumpLogin(tester);

    await tester.tap(find.text('Usar PIN de respaldo'));
    await tester.pumpAndSettle();

    Future<void> typePin(String pin) async {
      for (final digit in pin.split('')) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }
      await tester.pump(const Duration(milliseconds: 600)); // animación de error
    }

    for (var i = 0; i < 5; i++) {
      await typePin('0000');
    }
    expect(find.textContaining('Demasiados intentos. Podrás volver a probar'), findsOneWidget);

    // Con la espera activa, ni el PIN correcto entra
    await typePin('1234');
    expect(container.read(authProvider).isAuthenticated, isFalse);

    // Cerrar la pantalla cancela la cuenta atrás
    await tester.pumpWidget(const SizedBox());
  });
}
