import 'package:book_tracker/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Almacenamiento que falla al leer (como una copia restaurada en otro teléfono).
class _UnreadableStorage extends FlutterSecureStorage {
  bool wiped = false;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      throw Exception('BadPaddingException');

  @override
  Future<void> deleteAll({
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      wiped = true;
}

Future<AuthNotifier> _loaded({FlutterSecureStorage? storage, DateTime Function()? now}) async {
  final container = ProviderContainer.test(overrides: [
    authProvider.overrideWith(() => AuthNotifier(storage: storage, now: now)),
  ]);
  container.listen(authProvider, (_, _) {}); // mantenerlo vivo durante el test
  final notifier = container.read(authProvider.notifier);
  for (var i = 0; i < 50 && notifier.state.isLoading; i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(notifier.state.isLoading, isFalse, reason: 'debería terminar de cargar');
  return notifier;
}

void main() {
  group('estado inicial', () {
    test('instalación nueva: bloqueo activo pero sin palabra (pantalla de creación)', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final auth = await _loaded();
      expect(auth.state.isLockEnabled, isTrue);
      expect(auth.state.isPassphraseSet, isFalse);
      expect(auth.state.isPinSet, isFalse);
      expect(auth.state.canEnterApp, isFalse);
    });

    test('usuario existente sin la clave nueva sigue con bloqueo', () async {
      FlutterSecureStorage.setMockInitialValues({
        AuthNotifier.passphraseKey: 'Macondo',
        AuthNotifier.pinKey: '1234',
      });
      final auth = await _loaded();
      expect(auth.state.isLockEnabled, isTrue);
      expect(auth.state.isPassphraseSet, isTrue);
      expect(auth.state.isPinSet, isTrue);
      expect(auth.state.canEnterApp, isFalse);
    });

    test('bloqueo desactivado: entra directamente', () async {
      FlutterSecureStorage.setMockInitialValues({AuthNotifier.lockEnabledKey: 'false'});
      final auth = await _loaded();
      expect(auth.state.canEnterApp, isTrue);
    });

    test('almacenamiento ilegible: no se queda cargando y reinicia el bloqueo', () async {
      final storage = _UnreadableStorage();
      final auth = await _loaded(storage: storage);
      expect(storage.wiped, isTrue);
      expect(auth.state.isPassphraseSet, isFalse);
      expect(auth.state.isLockEnabled, isTrue);
    });
  });

  group('verificación', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({
          AuthNotifier.passphraseKey: 'Macondo',
          AuthNotifier.pinKey: '1234',
        }));

    test('la palabra no distingue mayúsculas ni espacios en los bordes', () async {
      final auth = await _loaded();
      expect(await auth.verifyPassphrase('  MACONDO '), LoginResult.success);
      expect(auth.state.isAuthenticated, isTrue);
    });

    test('palabra o PIN incorrectos no dan acceso', () async {
      final auth = await _loaded();
      expect(await auth.verifyPassphrase('Comala'), LoginResult.wrong);
      expect(await auth.verifyPin('0000'), LoginResult.wrong);
      expect(await auth.verifyPassphrase('   '), LoginResult.wrong);
      expect(auth.state.isAuthenticated, isFalse);
    });

    test('el PIN correcto da acceso', () async {
      final auth = await _loaded();
      expect(await auth.verifyPin('1234'), LoginResult.success);
      expect(auth.state.canEnterApp, isTrue);
    });

    test('verifySecret acepta palabra o PIN sin dar acceso', () async {
      final auth = await _loaded();
      expect(await auth.verifySecret('macondo'), isTrue);
      expect(await auth.verifySecret('1234'), isTrue);
      expect(await auth.verifySecret('9999'), isFalse);
      expect(auth.state.isAuthenticated, isFalse);
    });
  });

  group('configuración', () {
    test('crear palabra no da acceso hasta completar la configuración', () async {
      FlutterSecureStorage.setMockInitialValues({});
      final auth = await _loaded();

      await auth.savePassphrase('Macondo');
      expect(auth.state.isPassphraseSet, isTrue);
      expect(auth.state.canEnterApp, isFalse);

      await auth.saveNewPin('4321');
      await auth.completeSetup();
      expect(auth.state.canEnterApp, isTrue);
      expect(await auth.verifySecret('4321'), isTrue);
    });

    test('cambiar la palabra invalida la anterior', () async {
      FlutterSecureStorage.setMockInitialValues({AuthNotifier.passphraseKey: 'Macondo'});
      final auth = await _loaded();

      await auth.savePassphrase('Comala');
      expect(await auth.verifySecret('macondo'), isFalse);
      expect(await auth.verifySecret('comala'), isTrue);
    });

    test('recuperar acceso: nueva palabra y entra', () async {
      FlutterSecureStorage.setMockInitialValues({AuthNotifier.passphraseKey: 'olvidada'});
      final auth = await _loaded();

      await auth.resetPassphrase('Nueva');
      expect(auth.state.canEnterApp, isTrue);
      expect(await auth.verifySecret('nueva'), isTrue);
    });

    test('desactivar el bloqueo se recuerda en el próximo arranque', () async {
      FlutterSecureStorage.setMockInitialValues({AuthNotifier.passphraseKey: 'Macondo'});
      final auth = await _loaded();
      await auth.setLockEnabled(false);

      final restarted = await _loaded();
      expect(restarted.state.isLockEnabled, isFalse);
      expect(restarted.state.canEnterApp, isTrue);
      // La palabra se conserva por si lo vuelve a activar
      expect(restarted.state.isPassphraseSet, isTrue);
    });
  });

  group('límite de intentos', () {
    late DateTime now;
    DateTime clock() => now;

    setUp(() {
      now = DateTime(2026, 11, 16, 10);
      FlutterSecureStorage.setMockInitialValues({
        AuthNotifier.passphraseKey: 'Macondo',
        AuthNotifier.pinKey: '1234',
      });
    });

    Future<void> fail(AuthNotifier auth, int times) async {
      for (var i = 0; i < times; i++) {
        expect(await auth.verifyPin('0000'), LoginResult.wrong);
      }
    }

    test('esperas: 30 s al 5.º fallo, se duplican y se limitan a 15 min', () {
      expect(AuthNotifier.lockoutFor(4), Duration.zero);
      expect(AuthNotifier.lockoutFor(5), const Duration(seconds: 30));
      expect(AuthNotifier.lockoutFor(6), const Duration(minutes: 1));
      expect(AuthNotifier.lockoutFor(7), const Duration(minutes: 2));
      expect(AuthNotifier.lockoutFor(20), const Duration(minutes: 15));
    });

    test('4 fallos no bloquean; el 5.º sí, incluso con el PIN correcto', () async {
      final auth = await _loaded(now: clock);
      await fail(auth, 4);
      expect(auth.state.lockedUntil, isNull);

      await fail(auth, 1);
      expect(auth.state.lockedUntil, now.add(const Duration(seconds: 30)));
      expect(await auth.verifyPin('1234'), LoginResult.locked);
      expect(await auth.verifyPassphrase('macondo'), LoginResult.locked);
      expect(auth.state.isAuthenticated, isFalse);
    });

    test('al terminar la espera se puede entrar y el contador vuelve a cero', () async {
      final auth = await _loaded(now: clock);
      await fail(auth, 5);

      now = now.add(const Duration(seconds: 31));
      expect(await auth.verifyPin('1234'), LoginResult.success);
      expect(auth.state.lockedUntil, isNull);

      // Contador reiniciado: otros 4 fallos no bloquean
      await fail(auth, 4);
      expect(auth.state.lockedUntil, isNull);
    });

    test('un fallo tras la primera espera duplica la siguiente', () async {
      final auth = await _loaded(now: clock);
      await fail(auth, 5);
      now = now.add(const Duration(seconds: 31));

      await fail(auth, 1);
      expect(auth.state.lockedUntil, now.add(const Duration(minutes: 1)));
    });

    test('la espera sobrevive a cerrar y abrir la app', () async {
      final auth = await _loaded(now: clock);
      await fail(auth, 5);

      final restarted = await _loaded(now: clock);
      expect(restarted.state.lockedUntil, isNotNull);
      expect(await restarted.verifyPin('1234'), LoginResult.locked);
    });

    test('la huella (o el teléfono) entra durante la espera y la anula', () async {
      final auth = await _loaded(now: clock);
      await fail(auth, 5);

      await auth.markAuthenticated();
      expect(auth.state.isAuthenticated, isTrue);
      expect(auth.state.lockedUntil, isNull);

      final restarted = await _loaded(now: clock);
      expect(restarted.state.lockedUntil, isNull);
    });
  });

  group('bloquear al salir', () {
    late DateTime now;
    DateTime clock() => now;

    setUp(() {
      now = DateTime(2026, 11, 16, 10);
      FlutterSecureStorage.setMockInitialValues({AuthNotifier.passphraseKey: 'Macondo'});
    });

    Future<AuthNotifier> enteredApp({int? autoLock}) async {
      final auth = await _loaded(now: clock);
      if (autoLock != null) await auth.setAutoLockMinutes(autoLock);
      expect(await auth.verifyPassphrase('macondo'), LoginResult.success);
      return auth;
    }

    test('por defecto nunca bloquea al volver', () async {
      final auth = await enteredApp();
      expect(auth.state.autoLockMinutes, AuthNotifier.autoLockNever);

      auth.appBackgrounded();
      now = now.add(const Duration(hours: 3));
      auth.appResumed();
      expect(auth.state.isAuthenticated, isTrue);
    });

    test('con 5 min: volver antes no bloquea, volver después sí', () async {
      final auth = await enteredApp(autoLock: 5);

      auth.appBackgrounded();
      now = now.add(const Duration(minutes: 4, seconds: 59));
      auth.appResumed();
      expect(auth.state.isAuthenticated, isTrue);

      auth.appBackgrounded();
      now = now.add(const Duration(minutes: 5));
      auth.appResumed();
      expect(auth.state.isAuthenticated, isFalse);
      expect(auth.state.canEnterApp, isFalse);
    });

    test('cuenta desde la primera vez que salió (varios avisos seguidos)', () async {
      final auth = await enteredApp(autoLock: 1);

      auth.appBackgrounded(); // hidden
      now = now.add(const Duration(seconds: 50));
      auth.appBackgrounded(); // paused: no reinicia la cuenta
      now = now.add(const Duration(seconds: 15));
      auth.appResumed();
      expect(auth.state.isAuthenticated, isFalse);
    });

    test('con el bloqueo desactivado no bloquea nunca', () async {
      final auth = await enteredApp(autoLock: 1);
      await auth.setLockEnabled(false);

      auth.appBackgrounded();
      now = now.add(const Duration(minutes: 30));
      auth.appResumed();
      expect(auth.state.canEnterApp, isTrue);
    });

    test('volver sin haber salido no hace nada', () async {
      final auth = await enteredApp(autoLock: 1);
      now = now.add(const Duration(minutes: 30));
      auth.appResumed();
      expect(auth.state.isAuthenticated, isTrue);
    });

    test('la opción se recuerda y rechaza valores no permitidos', () async {
      final auth = await enteredApp(autoLock: 15);
      await auth.setAutoLockMinutes(7); // no está entre las opciones
      expect(auth.state.autoLockMinutes, 15);

      final restarted = await _loaded(now: clock);
      expect(restarted.state.autoLockMinutes, 15);
    });
  });
}
