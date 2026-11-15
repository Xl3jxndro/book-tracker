import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Estado de la autenticación enriquecido para la aventura literaria
class AuthState {
  final bool isAuthenticated;
  final bool isPinSet;
  final bool isPassphraseSet; // Nueva propiedad para el Santo y Seña
  final bool isLoading;

  AuthState({
    required this.isAuthenticated,
    required this.isPinSet,
    required this.isPassphraseSet,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isPinSet,
    bool? isPassphraseSet,
    bool? isLoading,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isPinSet: isPinSet ?? this.isPinSet,
      isPassphraseSet: isPassphraseSet ?? this.isPassphraseSet,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notificador que gestiona la seguridad y la mística de la app
class AuthNotifier extends StateNotifier<AuthState> {
  final _storage = const FlutterSecureStorage();
  
  // Claves para el almacenamiento seguro
  static const _pinKey = 'user_pin_code';
  static const _passphraseKey = 'user_passphrase';

  AuthNotifier() : super(AuthState(
    isAuthenticated: false, 
    isPinSet: false, 
    isPassphraseSet: false
  )) {
    _checkInitialStatus();
  }

  /// Comprueba al arrancar qué métodos de acceso tiene el usuario
  Future<void> _checkInitialStatus() async {
    state = state.copyWith(isLoading: true);
    
    final savedPin = await _storage.read(key: _pinKey);
    final savedPass = await _storage.read(key: _passphraseKey);

    state = state.copyWith(
      isPinSet: savedPin != null,
      isPassphraseSet: savedPass != null,
      isLoading: false,
    );
  }

  /// Verifica el PIN numérico
  Future<bool> verifyPin(String pin) async {
    final savedPin = await _storage.read(key: _pinKey);
    if (savedPin == pin) {
      state = state.copyWith(isAuthenticated: true);
      return true;
    }
    return false;
  }

  /// Verifica el "Santo y Seña" (Palabra mágica)
  /// Lo comparamos en minúsculas para que no haya errores por mayúsculas accidentales
  Future<bool> verifyPassphrase(String phrase) async {
    final savedPass = await _storage.read(key: _passphraseKey);
    if (savedPass?.toLowerCase().trim() == phrase.toLowerCase().trim()) {
      state = state.copyWith(isAuthenticated: true);
      return true;
    }
    return false;
  }

  /// Guarda el PIN inicial
  Future<void> saveNewPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
    state = state.copyWith(isPinSet: true);
    // Nota: No marcamos isAuthenticated = true aquí directamente para 
    // permitir que la pantalla de login decida si debe pedir el Santo y Seña justo después.
  }

  /// Guarda el Santo y Seña
  Future<void> savePassphrase(String phrase) async {
    await _storage.write(key: _passphraseKey, value: phrase.trim());
    state = state.copyWith(isPassphraseSet: true, isAuthenticated: true);
  }

  /// Finaliza la sesión actual
  void logout() {
    state = state.copyWith(isAuthenticated: false);
  }
}

// El Provider global
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});