import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/app_language.dart';

/// Idioma elegido en Ajustes (Automático / Español / English).
class LanguageNotifier extends Notifier<LanguageSetting> {
  /// Valor leído al arrancar (main), para no parpadear en otro idioma.
  static LanguageSetting initial = LanguageSetting.system;

  @override
  LanguageSetting build() => initial;

  Future<void> set(LanguageSetting setting) async {
    state = setting;
    await AppLanguage.save(setting);
  }
}

final languageProvider = NotifierProvider<LanguageNotifier, LanguageSetting>(LanguageNotifier.new);
