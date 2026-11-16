import 'package:book_tracker/providers/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

/// Almacenamiento que falla al leer (como una copia restaurada en otro teléfono).
class _UnreadableStorage extends FlutterSecureStorage {
  bool wiped = false;

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      throw Exception('BadPaddingException');

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      wiped = true;
}

Future<AuthNotifier> _loaded({FlutterSecureStorage? storage}) async {
  final notifier = AuthNotifier(storage: storage);
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
      expect(await auth.verifyPassphrase('  MACONDO '), isTrue);
      expect(auth.state.isAuthenticated, isTrue);
    });

    test('palabra o PIN incorrectos no dan acceso', () async {
      final auth = await _loaded();
      expect(await auth.verifyPassphrase('Comala'), isFalse);
      expect(await auth.verifyPin('0000'), isFalse);
      expect(await auth.verifyPassphrase('   '), isFalse);
      expect(auth.state.isAuthenticated, isFalse);
    });

    test('el PIN correcto da acceso', () async {
      final auth = await _loaded();
      expect(await auth.verifyPin('1234'), isTrue);
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
}
