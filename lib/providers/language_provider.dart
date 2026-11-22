import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_language.dart';
import '../services/home_widget_sync.dart';
import '../services/notification_service.dart';
import 'streak_risk_provider.dart';

/// Idioma elegido en Ajustes (Automático / Español / English).
class LanguageNotifier extends Notifier<LanguageSetting> {
  /// Valor leído al arrancar (main), para no parpadear en otro idioma.
  static LanguageSetting initial = LanguageSetting.system;

  @override
  LanguageSetting build() => initial;

  Future<void> set(LanguageSetting setting) async {
    state = setting;
    await AppLanguage.save(setting);
    // Lo que no está en pantalla cambia de idioma ya, sin esperar al
    // siguiente arranque: canales y avisos programados, y el widget.
    AppLanguage.apply(AppLanguage.resolve(setting, PlatformDispatcher.instance.locales));
    try {
      await NotificationService.init(); // nombres de los canales
      await NotificationService.rescheduleIfEnabled(); // recordatorio diario
      await StreakRiskSync.sync(ref.read); // aviso de racha en riesgo
      await HomeWidgetSync.refresh();
    } catch (e) {
      debugPrint('Cambio de idioma: $e');
    }
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, LanguageSetting>(LanguageNotifier.new);
