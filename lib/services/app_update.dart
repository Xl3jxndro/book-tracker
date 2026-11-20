import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Estado de la actualización de la app según Google Play.
enum UpdateStatus {
  /// Aún no se sabe (o no se puede saber: instalada fuera de Play, sin red…).
  unknown,
  checking,
  upToDate,
  available,
  downloading,

  /// Descargada en segundo plano: falta reiniciar para instalarla.
  downloaded,
}

/// Traduce la respuesta de Play a nuestro estado.
UpdateStatus updateStatusFrom(UpdateAvailability availability, InstallStatus install) {
  if (install == InstallStatus.downloaded) return UpdateStatus.downloaded;
  if (install == InstallStatus.downloading || install == InstallStatus.pending) return UpdateStatus.downloading;
  return switch (availability) {
    UpdateAvailability.updateAvailable => UpdateStatus.available,
    UpdateAvailability.developerTriggeredUpdateInProgress => UpdateStatus.downloading,
    UpdateAvailability.updateNotAvailable => UpdateStatus.upToDate,
    UpdateAvailability.unknown => UpdateStatus.unknown,
  };
}

/// Avisa si hay una versión nueva en Google Play y la instala sin salir de
/// la app (actualizaciones "in-app" de Play). Solo funciona si la app se
/// instaló desde Play; si no, se queda en [UpdateStatus.unknown] sin molestar.
class AppUpdate {
  AppUpdate._();

  static const _promptedKey = 'update_prompted_version_code';

  static final status = ValueNotifier<UpdateStatus>(UpdateStatus.unknown);
  static AppUpdateInfo? _info;

  /// Versión nueva disponible (versionCode de Play), si se conoce.
  static int? get availableVersionCode => _info?.availableVersionCode;

  /// Pregunta a Play si hay una versión nueva.
  static Future<UpdateStatus> check() async {
    if (kIsWeb || !Platform.isAndroid) return status.value;
    if (status.value == UpdateStatus.downloading) return status.value;
    final previous = status.value;
    status.value = UpdateStatus.checking;
    try {
      final info = await InAppUpdate.checkForUpdate();
      _info = info;
      status.value = updateStatusFrom(info.updateAvailability, info.installStatus);
    } catch (e) {
      // Instalada fuera de Play, sin red o sin cuenta de Google
      debugPrint('Buscar actualización: $e');
      status.value = previous;
    }
    return status.value;
  }

  /// ¿Mostrar el aviso al abrir la app? Solo una vez por versión nueva.
  static Future<bool> shouldPrompt() async {
    final code = availableVersionCode;
    if (status.value != UpdateStatus.available || code == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_promptedKey) != code;
  }

  static Future<void> markPrompted() async {
    final code = availableVersionCode;
    if (code == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_promptedKey, code);
  }

  /// Empieza la actualización: se descarga en segundo plano mientras se
  /// sigue usando la app (o, si Play no lo permite, en pantalla completa).
  /// Devuelve false si el usuario la canceló o falló.
  static Future<bool> start() async {
    final info = _info;
    if (info == null || status.value != UpdateStatus.available) return false;
    try {
      if (info.flexibleUpdateAllowed) {
        status.value = UpdateStatus.downloading;
        final result = await InAppUpdate.startFlexibleUpdate();
        if (result == AppUpdateResult.success) {
          status.value = UpdateStatus.downloaded;
          return true;
        }
        status.value = UpdateStatus.available;
        return false;
      }
      if (info.immediateUpdateAllowed) {
        final result = await InAppUpdate.performImmediateUpdate();
        return result == AppUpdateResult.success;
      }
    } catch (e) {
      debugPrint('Actualizar: $e');
      status.value = UpdateStatus.available;
    }
    return false;
  }

  /// Instala la versión ya descargada (la app se reinicia).
  static Future<void> install() async {
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('Instalar actualización: $e');
    }
  }
}
