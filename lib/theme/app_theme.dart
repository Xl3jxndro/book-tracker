import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_tokens.dart';

/// Tema de la app a partir del sistema de diseño: Lora (con serifa) para
/// títulos, Inter para el resto, y los componentes con las mismas formas.
abstract final class AppTheme {
  static final ThemeData light = build(AppSchemes.light, AppColors.light);
  static final ThemeData dark = build(AppSchemes.dark, AppColors.dark);

  /// Escala tipográfica (sin colores: los pone [build] según el modo).
  static TextTheme textTheme() {
    TextStyle lora(double size, FontWeight weight, {double spacing = 0, double? height}) =>
        GoogleFonts.lora(fontSize: size, fontWeight: weight, letterSpacing: spacing, height: height);
    TextStyle inter(double size, FontWeight weight, {double spacing = 0, double? height}) =>
        GoogleFonts.inter(fontSize: size, fontWeight: weight, letterSpacing: spacing, height: height);

    return TextTheme(
      displayLarge: lora(48, FontWeight.w700, spacing: -1),
      displayMedium: lora(40, FontWeight.w700, spacing: -0.8),
      displaySmall: lora(34, FontWeight.w700, spacing: -0.6),
      headlineLarge: lora(32, FontWeight.w700, spacing: -0.5),
      headlineMedium: lora(28, FontWeight.w700, spacing: -0.4),
      headlineSmall: lora(24, FontWeight.w700, spacing: -0.3),
      titleLarge: lora(20, FontWeight.w700, spacing: -0.2),
      titleMedium: inter(16, FontWeight.w600),
      titleSmall: inter(14, FontWeight.w600),
      bodyLarge: inter(16, FontWeight.w400, height: 1.45),
      bodyMedium: inter(14, FontWeight.w400, height: 1.4),
      bodySmall: inter(12, FontWeight.w400, height: 1.35),
      labelLarge: inter(14, FontWeight.w600, spacing: 0.1),
      labelMedium: inter(12, FontWeight.w600, spacing: 0.3),
      labelSmall: inter(11, FontWeight.w600, spacing: 0.6),
    );
  }

  static ThemeData build(ColorScheme scheme, AppColors app) {
    final text = textTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: app.heading,
    );
    final pill = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg));

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      extensions: [app],
      textTheme: text,
      scaffoldBackgroundColor: scheme.surface,
      canvasColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),

      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: text.titleLarge,
      ),

      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: pill,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(64, 52),
          elevation: 0,
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          shape: pill,
          textStyle: text.labelLarge?.copyWith(fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: pill,
          side: BorderSide(color: scheme.outlineVariant),
          foregroundColor: scheme.onSurface,
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: pill,
          foregroundColor: app.accentText,
          textStyle: text.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: app.accent,
        foregroundColor: app.onAccent,
        elevation: 2,
        focusElevation: 2,
        hoverElevation: 3,
        highlightElevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
        extendedTextStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm + 2),
        border: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
        enabledBorder: const OutlineInputBorder(borderRadius: AppRadius.mdAll, borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: BorderSide(color: scheme.error, width: 1.5),
        ),
        hintStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
        labelStyle: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.primaryContainer,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: text.labelLarge?.copyWith(color: scheme.onSurface),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs, vertical: AppSpace.xxs),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          shape: const StadiumBorder(),
          side: BorderSide(color: scheme.outlineVariant),
          selectedBackgroundColor: scheme.primary,
          selectedForegroundColor: scheme.onPrimary,
          textStyle: text.labelLarge,
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        modalBackgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        showDragHandle: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xxl)),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xxlAll),
        titleTextStyle: text.headlineSmall,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(color: scheme.onInverseSurface),
        actionTextColor: scheme.inversePrimary,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
        textStyle: text.bodyMedium,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(color: scheme.inverseSurface, borderRadius: AppRadius.smAll),
        textStyle: text.bodySmall?.copyWith(color: scheme.onInverseSurface),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: app.accent,
        linearTrackColor: scheme.surfaceContainerHighest,
        circularTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 6,
        borderRadius: const BorderRadius.all(Radius.circular(3)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimary : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primary : scheme.surfaceContainerHighest,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? Colors.transparent : scheme.outline,
        ),
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        hourMinuteShape: const RoundedRectangleBorder(borderRadius: AppRadius.smAll),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.xxlAll),
      ),
    );
  }
}
