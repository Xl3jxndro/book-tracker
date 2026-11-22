import 'dart:ui';

import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Idioma elegido en Ajustes.
enum LanguageSetting {
  /// El del teléfono (español si está en español; si no, inglés).
  system,
  spanish,
  english;

  String get code => switch (this) { system => 'system', spanish => 'es', english => 'en' };

  static LanguageSetting fromCode(String? code) => switch (code) {
        'es' => spanish,
        'en' => english,
        _ => system,
      };
}

/// Idioma de la app: lo que se ve en pantalla y lo que usan las
/// notificaciones y el widget (que no tienen pantalla de la que tomarlo).
class AppLanguage {
  AppLanguage._();

  static const prefsKey = 'app_language';
  static const supported = [Locale('es'), Locale('en')];

  /// Idioma en uso ahora mismo (se actualiza al dibujar la app).
  static Locale current = const Locale('es');

  /// Textos en el idioma en uso, para código sin pantalla (notificaciones,
  /// widget de inicio, archivos exportados…).
  static AppLocalizations get strings => lookupAppLocalizations(current);

  /// El idioma que corresponde a una elección y a los idiomas del teléfono:
  /// español si el teléfono está en español; inglés en cualquier otro caso.
  static Locale resolve(LanguageSetting setting, List<Locale> deviceLocales) => switch (setting) {
        LanguageSetting.spanish => const Locale('es'),
        LanguageSetting.english => const Locale('en'),
        LanguageSetting.system => (deviceLocales.isNotEmpty ? deviceLocales.first.languageCode : 'es') == 'es'
            ? const Locale('es')
            : const Locale('en'),
      };

  /// Carga la elección guardada y fija el idioma antes de dibujar la app
  /// (las notificaciones se reprograman al arrancar).
  static Future<LanguageSetting> load() async {
    final prefs = await SharedPreferences.getInstance();
    final setting = LanguageSetting.fromCode(prefs.getString(prefsKey));
    apply(resolve(setting, PlatformDispatcher.instance.locales));
    return setting;
  }

  static Future<void> save(LanguageSetting setting) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, setting.code);
  }

  /// Fija el idioma en uso (también el de fechas y números de `intl`).
  static void apply(Locale locale) {
    current = locale;
    Intl.defaultLocale = locale.languageCode;
  }
}
