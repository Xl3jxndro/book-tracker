import 'package:material_ui/material_ui.dart';

import '../services/app_language.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Atajo: `context.l10n.algunTexto`.
extension L10nContext on BuildContext {
  /// Textos en el idioma de la app. Fuera de la app (p. ej. en pruebas con
  /// un MaterialApp sin traducciones) usa el idioma en uso, español por defecto.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ?? AppLanguage.strings;

  /// Código del idioma en pantalla ("es" o "en"), para fechas y números.
  String get languageCode => l10n.localeName;
}
