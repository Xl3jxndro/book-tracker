import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Huella / rostro y bloqueo de pantalla del teléfono (PIN, patrón, contraseña).
class DeviceAuthService {
  DeviceAuthService._();

  static final LocalAuthentication _auth = LocalAuthentication();

  /// Hay huella o rostro registrados.
  static Future<bool> canUseBiometrics() async {
    try {
      return await _auth.canCheckBiometrics &&
          (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (e) {
      debugPrint('Biometría no disponible: $e');
      return false;
    }
  }

  /// El teléfono puede verificar al usuario (biometría o bloqueo de pantalla).
  static Future<bool> isDeviceSecure() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (e) {
      debugPrint('Verificación del dispositivo no disponible: $e');
      return false;
    }
  }

  /// Pide verificar al usuario. Con [biometricOnly] `false` también acepta el
  /// PIN/patrón del teléfono (lo que permite recuperar el acceso).
  static Future<bool> authenticate({required String reason, bool biometricOnly = false}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(stickyAuth: true, biometricOnly: biometricOnly),
      );
    } catch (e) {
      debugPrint('Error de autenticación del dispositivo: $e');
      return false;
    }
  }
}
