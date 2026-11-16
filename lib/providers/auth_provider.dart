import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Estado del bloqueo de la app.
class AuthState {
  final bool isLoading;

  /// Si es `false`, la app abre directamente sin pedir nada.
  final bool isLockEnabled;
  final bool isPassphraseSet;
  final bool isPinSet;

  /// Ya se identificó en esta ejecución de la app.
  final bool isAuthenticated;

  const AuthState({
    this.isLoading = false,
    this.isLockEnabled = true,
    this.isPassphraseSet = false,
    this.isPinSet = false,
    this.isAuthenticated = false,
  });

  /// La app se puede usar (sin bloqueo o ya identificado).
  bool get canEnterApp => !isLoading && (!isLockEnabled || isAuthenticated);

  AuthState copyWith({
    bool? isLoading,
    bool? isLockEnabled,
    bool? isPassphraseSet,
    bool? isPinSet,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLockEnabled: isLockEnabled ?? this.isLockEnabled,
      isPassphraseSet: isPassphraseSet ?? this.isPassphraseSet,
      isPinSet: isPinSet ?? this.isPinSet,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

/// Gestiona la palabra secreta ("Santo y Seña"), el PIN de respaldo y si el
/// bloqueo está activo. Todo se guarda en el almacenamiento seguro.
class AuthNotifier extends StateNotifier<AuthState> {
  // Claves para el almacenamiento seguro (no cambiar: las usan instalaciones existentes)
  static const pinKey = 'user_pin_code';
  static const passphraseKey = 'user_passphrase';
  static const lockEnabledKey = 'app_lock_enabled';

  static const pinLength = 4;

  final FlutterSecureStorage _storage;

  AuthNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(const AuthState(isLoading: true)) {
    _checkInitialStatus();
  }

  /// Comprueba al arrancar qué métodos de acceso tiene el usuario.
  Future<void> _checkInitialStatus() async {
    try {
      final savedPin = await _storage.read(key: pinKey);
      final savedPass = await _storage.read(key: passphraseKey);
      final lockFlag = await _storage.read(key: lockEnabledKey);
      if (!mounted) return;
      state = AuthState(
        isPinSet: savedPin != null,
        isPassphraseSet: savedPass != null,
        // Sin valor guardado: activo (así quedan los usuarios que ya tenían bloqueo)
        isLockEnabled: lockFlag != 'false',
      );
    } catch (e) {
      // El almacenamiento seguro no se puede leer (p. ej. copia restaurada en
      // otro teléfono: sus claves de cifrado no viajan). Sin esto la app se
      // quedaría cargando para siempre; se reinicia el bloqueo.
      debugPrint('Almacenamiento seguro ilegible, se reinicia el bloqueo: $e');
      try {
        await _storage.deleteAll();
      } catch (_) {}
      if (mounted) state = const AuthState();
    }
  }

  static String _normalizePassphrase(String phrase) => phrase.trim().toLowerCase();

  // --- Verificación ---

  /// Verifica el PIN y, si es correcto, da acceso.
  Future<bool> verifyPin(String pin) async {
    final ok = await _matchesPin(pin);
    if (ok) state = state.copyWith(isAuthenticated: true);
    return ok;
  }

  /// Verifica el "Santo y Seña" (sin distinguir mayúsculas ni espacios en los bordes).
  Future<bool> verifyPassphrase(String phrase) async {
    final ok = await _matchesPassphrase(phrase);
    if (ok) state = state.copyWith(isAuthenticated: true);
    return ok;
  }

  /// Comprueba la palabra secreta o el PIN sin cambiar el estado
  /// (para confirmar acciones sensibles en Ajustes).
  Future<bool> verifySecret(String input) async =>
      await _matchesPassphrase(input) || await _matchesPin(input);

  Future<bool> _matchesPin(String pin) async {
    final saved = await _storage.read(key: pinKey);
    return saved != null && saved == pin.trim();
  }

  Future<bool> _matchesPassphrase(String phrase) async {
    final saved = await _storage.read(key: passphraseKey);
    return saved != null &&
        phrase.trim().isNotEmpty &&
        _normalizePassphrase(saved) == _normalizePassphrase(phrase);
  }

  /// Acceso concedido por biometría o por el bloqueo del teléfono.
  void markAuthenticated() => state = state.copyWith(isAuthenticated: true);

  // --- Configuración ---

  /// Guarda (o cambia) la palabra secreta. No da acceso por sí sola: la
  /// pantalla de login decide cuándo termina la configuración.
  Future<void> savePassphrase(String phrase) async {
    await _storage.write(key: passphraseKey, value: phrase.trim());
    state = state.copyWith(isPassphraseSet: true);
  }

  /// Guarda (o cambia) el PIN de respaldo.
  Future<void> saveNewPin(String pin) async {
    await _storage.write(key: pinKey, value: pin.trim());
    state = state.copyWith(isPinSet: true);
  }

  /// Termina la configuración inicial y entra en la app.
  Future<void> completeSetup() async {
    await setLockEnabled(true);
    state = state.copyWith(isAuthenticated: true);
  }

  /// Nueva palabra secreta tras verificar con el teléfono ("la olvidé").
  Future<void> resetPassphrase(String phrase) async {
    await savePassphrase(phrase);
    state = state.copyWith(isAuthenticated: true);
  }

  /// Activa o desactiva el bloqueo al abrir la app.
  Future<void> setLockEnabled(bool enabled) async {
    await _storage.write(key: lockEnabledKey, value: enabled.toString());
    state = state.copyWith(
      isLockEnabled: enabled,
      // Quien lo desactiva ya está dentro; al reactivarlo no se le echa
      isAuthenticated: true,
    );
  }

  /// Finaliza la sesión actual.
  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }
}

// El Provider global
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
