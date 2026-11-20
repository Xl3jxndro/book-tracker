import 'package:material_color_utilities/material_color_utilities.dart';
import 'package:material_ui/material_ui.dart';

/// Paletas de Book Tracker.
///
/// Claro, "día en papel": crema (60 %), verde abeto (30 %), terracota (10 %).
/// Oscuro, "noche con lámpara": ciruela (60 %), seda titanio (30 %), ámbar (10 %).
abstract final class AppPalette {
  // Claro
  static const cream = Color(0xFFEEE2CB);
  static const creamLight = Color(0xFFF7F0E2);
  static const creamDark = Color(0xFFE3D4B6);
  static const fir = Color(0xFF1B4532);
  static const firMuted = Color(0xFF476355);
  static const terracotta = Color(0xFFC4553A);

  /// Terracota oscuro: el acento como texto (4.5:1 sobre el crema).
  static const terracottaText = Color(0xFF9E3F28);

  // Oscuro
  static const plum = Color(0xFF2B1C33);
  static const plumLight = Color(0xFF3A2843);
  static const plumLighter = Color(0xFF47334F);
  static const titanium = Color(0xFFD9D3CC);
  static const titaniumMuted = Color(0xFFA99FB0);
  static const amber = Color(0xFFFF8C12);
}

/// Colores con significado propio de la app (estados, racha, valoraciones),
/// además de los roles de [ColorScheme]. Se leen con `AppColors.of(context)`.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Acento (10 %): progreso, botón +, detalles destacados.
  final Color accent;

  /// Contenido sobre el acento.
  final Color onAccent;

  /// El acento cuando es texto pequeño (versión con contraste suficiente).
  final Color accentText;

  /// Fondo suave del acento (chips, pastillas seleccionadas).
  final Color accentSoft;

  /// Títulos: algo más intensos que el texto normal.
  final Color heading;

  final Color statusPending;
  final Color statusReading;
  final Color statusFinished;
  final Color statusAbandoned;

  final Color streak;
  final Color rating;

  const AppColors({
    required this.accent,
    required this.onAccent,
    required this.accentText,
    required this.accentSoft,
    required this.heading,
    required this.statusPending,
    required this.statusReading,
    required this.statusFinished,
    required this.statusAbandoned,
    required this.streak,
    required this.rating,
  });

  static const light = AppColors(
    accent: AppPalette.terracotta,
    onAccent: AppPalette.creamLight,
    accentText: AppPalette.terracottaText,
    accentSoft: Color(0xFFF2D5C8),
    heading: AppPalette.fir,
    statusPending: Color(0xFF4A5F7A),
    statusReading: AppPalette.terracottaText,
    statusFinished: Color(0xFF2F6B4A),
    statusAbandoned: Color(0xFF8A3B5C),
    streak: AppPalette.terracotta,
    rating: Color(0xFFB7791F),
  );

  static const dark = AppColors(
    accent: AppPalette.amber,
    onAccent: AppPalette.plum,
    accentText: AppPalette.amber,
    accentSoft: Color(0xFF4D3428),
    heading: Color(0xFFEDE8E2),
    statusPending: Color(0xFF9DB4D6),
    statusReading: AppPalette.amber,
    statusFinished: Color(0xFF8FCB9B),
    statusAbandoned: Color(0xFFE39AA8),
    streak: AppPalette.amber,
    rating: Color(0xFFFFB347),
  );

  /// Colores propios para un esquema de Material You: el acento es el
  /// "tertiary" del sistema y los estados se armonizan con su "primary".
  static AppColors fromScheme(ColorScheme scheme, AppColors base) {
    Color h(Color c) => Color(Blend.harmonize(c.toARGB32(), scheme.primary.toARGB32()));
    return AppColors(
      accent: scheme.tertiary,
      onAccent: scheme.onTertiary,
      accentText: scheme.tertiary,
      accentSoft: scheme.tertiaryContainer,
      heading: scheme.onSurface,
      statusPending: h(base.statusPending),
      statusReading: h(base.statusReading),
      statusFinished: h(base.statusFinished),
      statusAbandoned: h(base.statusAbandoned),
      streak: scheme.tertiary,
      rating: h(base.rating),
    );
  }

  static AppColors of(BuildContext context) =>
      Theme.of(context).extension<AppColors>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// Color del estado de un libro (0 pendiente, 1 leyendo, 2 terminado, 3 abandonado).
  Color forStatus(int status) => switch (status) {
        1 => statusReading,
        2 => statusFinished,
        3 => statusAbandoned,
        _ => statusPending,
      };

  @override
  AppColors copyWith({
    Color? accent,
    Color? onAccent,
    Color? accentText,
    Color? accentSoft,
    Color? heading,
    Color? statusPending,
    Color? statusReading,
    Color? statusFinished,
    Color? statusAbandoned,
    Color? streak,
    Color? rating,
  }) =>
      AppColors(
        accent: accent ?? this.accent,
        onAccent: onAccent ?? this.onAccent,
        accentText: accentText ?? this.accentText,
        accentSoft: accentSoft ?? this.accentSoft,
        heading: heading ?? this.heading,
        statusPending: statusPending ?? this.statusPending,
        statusReading: statusReading ?? this.statusReading,
        statusFinished: statusFinished ?? this.statusFinished,
        statusAbandoned: statusAbandoned ?? this.statusAbandoned,
        streak: streak ?? this.streak,
        rating: rating ?? this.rating,
      );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      accentText: l(accentText, other.accentText),
      accentSoft: l(accentSoft, other.accentSoft),
      heading: l(heading, other.heading),
      statusPending: l(statusPending, other.statusPending),
      statusReading: l(statusReading, other.statusReading),
      statusFinished: l(statusFinished, other.statusFinished),
      statusAbandoned: l(statusAbandoned, other.statusAbandoned),
      streak: l(streak, other.streak),
      rating: l(rating, other.rating),
    );
  }
}

/// Esquemas de color completos de Material para cada modo.
abstract final class AppSchemes {
  static const light = ColorScheme(
    brightness: Brightness.light,
    primary: AppPalette.fir,
    onPrimary: AppPalette.creamLight,
    primaryContainer: Color(0xFFD3DCC7),
    onPrimaryContainer: Color(0xFF10291E),
    secondary: AppPalette.firMuted,
    onSecondary: AppPalette.creamLight,
    secondaryContainer: AppPalette.creamDark,
    onSecondaryContainer: AppPalette.fir,
    tertiary: AppPalette.terracotta,
    onTertiary: AppPalette.creamLight,
    tertiaryContainer: Color(0xFFF2D5C8),
    onTertiaryContainer: Color(0xFF5A2213),
    error: Color(0xFFB3261E),
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFF9DEDC),
    onErrorContainer: Color(0xFF410E0B),
    surface: AppPalette.cream,
    onSurface: AppPalette.fir,
    onSurfaceVariant: AppPalette.firMuted,
    surfaceContainerLowest: Color(0xFFFBF6EC),
    surfaceContainerLow: AppPalette.creamLight,
    surfaceContainer: Color(0xFFF3EAD8),
    surfaceContainerHigh: Color(0xFFE9DDC4),
    surfaceContainerHighest: AppPalette.creamDark,
    outline: Color(0xFF7D8B7F),
    outlineVariant: Color(0xFFD6C7A8),
    inverseSurface: AppPalette.fir,
    onInverseSurface: AppPalette.creamLight,
    inversePrimary: Color(0xFFA8C7B4),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );

  static const dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppPalette.amber,
    onPrimary: AppPalette.plum,
    primaryContainer: Color(0xFF4D3428),
    onPrimaryContainer: Color(0xFFFFD2A6),
    secondary: AppPalette.titanium,
    onSecondary: AppPalette.plum,
    secondaryContainer: AppPalette.plumLighter,
    onSecondaryContainer: Color(0xFFEDE8E2),
    tertiary: Color(0xFFF2A65A),
    onTertiary: AppPalette.plum,
    tertiaryContainer: Color(0xFF5A3A2A),
    onTertiaryContainer: Color(0xFFFFDDBB),
    error: Color(0xFFF2B8B5),
    onError: Color(0xFF601410),
    errorContainer: Color(0xFF8C1D18),
    onErrorContainer: Color(0xFFF9DEDC),
    surface: AppPalette.plum,
    onSurface: AppPalette.titanium,
    onSurfaceVariant: AppPalette.titaniumMuted,
    surfaceContainerLowest: Color(0xFF24172B),
    surfaceContainerLow: Color(0xFF33233B),
    surfaceContainer: AppPalette.plumLight,
    surfaceContainerHigh: Color(0xFF412E4A),
    surfaceContainerHighest: AppPalette.plumLighter,
    outline: Color(0xFF8A7F92),
    outlineVariant: Color(0xFF4F3A58),
    inverseSurface: AppPalette.titanium,
    onInverseSurface: AppPalette.plum,
    inversePrimary: Color(0xFF8F4A00),
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    surfaceTint: Color(0x00000000),
  );
}

/// Atajos: `context.cs` (roles de Material) y `context.app` (colores propios).
extension AppThemeContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  AppColors get app => AppColors.of(this);
}
