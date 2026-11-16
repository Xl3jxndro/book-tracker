import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Resultado de intentar entrar con la palabra secreta o el PIN.
enum LoginResult { success, wrong, locked }

/// Estado del bloqueo de la app.
class AuthState {
  final bool isLoading;

  /// Si es `false`, la app abre directamente sin pedir nada.
  final bool isLockEnabled;
  final bool isPassphraseSet;
  final bool isPinSet;

  /// Ya se identificó en esta ejecución de la app.
  final bool isAuthenticated;

  /// Tras demasiados intentos fallidos, no se aceptan palabra ni PIN hasta
  /// esta hora (la huella y la recuperación con el teléfono sí funcionan).
  final DateTime? lockedUntil;

  /// Minutos fuera de la app tras los que se vuelve a pedir la palabra
  /// (`AuthNotifier.autoLockNever` = nunca).
  final int autoLockMinutes;

  const AuthState({
    this.isLoading = false,
    this.isLockEnabled = true,
    this.isPassphraseSet = false,
    this.isPinSet = false,
    this.isAuthenticated = false,
    this.lockedUntil,
    this.autoLockMinutes = AuthNotifier.autoLockNever,
  });

  /// La app se puede usar (sin bloqueo o ya identificado).
  bool get canEnterApp => !isLoading && (!isLockEnabled || isAuthenticated);

  AuthState copyWith({
    bool? isLoading,
    bool? isLockEnabled,
    bool? isPassphraseSet,
    bool? isPinSet,
    bool? isAuthenticated,
    DateTime? lockedUntil,
    bool clearLockout = false,
    int? autoLockMinutes,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLockEnabled: isLockEnabled ?? this.isLockEnabled,
      isPassphraseSet: isPassphraseSet ?? this.isPassphraseSet,
      isPinSet: isPinSet ?? this.isPinSet,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lockedUntil: clearLockout ? null : (lockedUntil ?? this.lockedUntil),
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
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
  static const failedAttemptsKey = 'auth_failed_attempts';
  static const lockedUntilKey = 'auth_locked_until';
  static const autoLockKey = 'auto_lock_minutes';

  static const pinLength = 4;

  /// "Bloquear al salir": nunca, o tras estos minutos fuera de la app. No hay
  /// opción inmediata: elegir una foto, compartir o verificar con el teléfono
  /// también mandan la app a segundo plano y bloquearía a mitad de la acción.
  static const autoLockNever = -1;
  static const autoLockOptions = [autoLockNever, 1, 5, 15];

  /// Momento en que la app pasó a segundo plano (null si está en primer plano).
  DateTime? _backgroundedAt;

  /// Fallos seguidos permitidos antes de empezar a hacer esperar.
  static const maxAttempts = 5;
  static const baseLockout = Duration(seconds: 30);
  static const maxLockout = Duration(minutes: 15);

  final FlutterSecureStorage _storage;
  final DateTime Function() _now;
  int _failedAttempts = 0;

  AuthNotifier({FlutterSecureStorage? storage, DateTime Function()? now})
      : _storage = storage ?? const FlutterSecureStorage(),
        _now = now ?? DateTime.now,
        super(const AuthState(isLoading: true)) {
    _checkInitialStatus();
  }

  /// Espera tras el fallo número [failures]: 30 s al 5.º, y se duplica con
  /// cada fallo siguiente hasta 15 min.
  static Duration lockoutFor(int failures) {
    if (failures < maxAttempts) return Duration.zero;
    final exponent = math.min(failures - maxAttempts, 10);
    final seconds = baseLockout.inSeconds * (1 << exponent);
    return Duration(seconds: math.min(seconds, maxLockout.inSeconds));
  }

  /// Comprueba al arrancar qué métodos de acceso tiene el usuario.
  Future<void> _checkInitialStatus() async {
    try {
      final savedPin = await _storage.read(key: pinKey);
      final savedPass = await _storage.read(key: passphraseKey);
      final lockFlag = await _storage.read(key: lockEnabledKey);
      _failedAttempts = int.tryParse(await _storage.read(key: failedAttemptsKey) ?? '') ?? 0;
      final lockedUntilMs = int.tryParse(await _storage.read(key: lockedUntilKey) ?? '');
      final lockedUntil = lockedUntilMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);
      final autoLock = int.tryParse(await _storage.read(key: autoLockKey) ?? '');
      if (!mounted) return;
      state = AuthState(
        isPinSet: savedPin != null,
        isPassphraseSet: savedPass != null,
        // Sin valor guardado: activo (así quedan los usuarios que ya tenían bloqueo)
        isLockEnabled: lockFlag != 'false',
        lockedUntil: (lockedUntil != null && lockedUntil.isAfter(_now())) ? lockedUntil : null,
        autoLockMinutes: autoLockOptions.contains(autoLock) ? autoLock! : autoLockNever,
      );
    } catch (e) {
      // El almacenamiento seguro no se puede leer (p. ej. copia restaurada en
      // otro teléfono: sus claves de cifrado no viajan). Sin esto la app se
      // quedaría cargando para siempre; se reinicia el bloqueo.
      debugPrint('Almacenamiento seguro ilegible, se reinicia el bloqueo: $e');
      try {
        await _storage.deleteAll();
      } catch (_) {}
      _failedAttempts = 0;
      if (mounted) state = const AuthState();
    }
  }

  static String _normalizePassphrase(String phrase) => phrase.trim().toLowerCase();

  // --- Verificación (login) ---

  bool get _isLockedOut {
    final until = state.lockedUntil;
    return until != null && until.isAfter(_now());
  }

  /// Verifica el PIN y, si es correcto, da acceso.
  Future<LoginResult> verifyPin(String pin) => _attempt(() => _matchesPin(pin));

  /// Verifica el "Santo y Seña" (sin distinguir mayúsculas ni espacios en los bordes).
  Future<LoginResult> verifyPassphrase(String phrase) => _attempt(() => _matchesPassphrase(phrase));

  Future<LoginResult> _attempt(Future<bool> Function() check) async {
    if (_isLockedOut) return LoginResult.locked;

    if (await check()) {
      await _resetFailures();
      state = state.copyWith(isAuthenticated: true);
      return LoginResult.success;
    }

    _failedAttempts++;
    final wait = lockoutFor(_failedAttempts);
    final lockedUntil = wait == Duration.zero ? null : _now().add(wait);
    await _storage.write(key: failedAttemptsKey, value: '$_failedAttempts');
    if (lockedUntil != null) {
      await _storage.write(key: lockedUntilKey, value: '${lockedUntil.millisecondsSinceEpoch}');
      state = state.copyWith(lockedUntil: lockedUntil);
    }
    return LoginResult.wrong;
  }

  Future<void> _resetFailures() async {
    if (_failedAttempts == 0 && state.lockedUntil == null) return;
    _failedAttempts = 0;
    await _storage.delete(key: failedAttemptsKey);
    await _storage.delete(key: lockedUntilKey);
    state = state.copyWith(clearLockout: true);
  }

  /// Comprueba la palabra secreta o el PIN sin cambiar el estado
  /// (para confirmar acciones sensibles en Ajustes, ya dentro de la app).
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
  Future<void> markAuthenticated() async {
    await _resetFailures();
    state = state.copyWith(isAuthenticated: true);
  }

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
    await markAuthenticated();
  }

  // --- Bloquear al salir de la app ---

  Future<void> setAutoLockMinutes(int minutes) async {
    if (!autoLockOptions.contains(minutes)) return;
    await _storage.write(key: autoLockKey, value: '$minutes');
    state = state.copyWith(autoLockMinutes: minutes);
  }

  /// La app pasó a segundo plano (se guarda el primer momento).
  void appBackgrounded() => _backgroundedAt ??= _now();

  /// La app volvió: si estuvo fuera el tiempo configurado, vuelve a bloquear.
  void appResumed() {
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null) return;

    final s = state;
    final hasSecret = s.isPassphraseSet || s.isPinSet;
    if (!s.isLockEnabled || !s.isAuthenticated || !hasSecret) return;
    if (s.autoLockMinutes == autoLockNever) return;

    if (_now().difference(since) >= Duration(minutes: s.autoLockMinutes)) {
      state = s.copyWith(isAuthenticated: false);
    }
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
