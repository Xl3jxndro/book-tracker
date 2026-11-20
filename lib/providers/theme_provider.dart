import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';
import '../theme/app_colors.dart';
import 'color_source_provider.dart';

// --- PROVIDER DE MODO DE TEMA ---
final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system;
  }
  static const _key = 'user_theme_mode';

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_key);
    if (themeIndex != null && ref.mounted) state = ThemeMode.values[themeIndex];
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, mode.index);
  }
}

// --- PROVIDER DE ESQUEMA DE COLOR DINÁMICO ---
/// Colores de la pantalla de un libro: los del sistema de diseño, con la
/// familia "primary" tomada de su portada (fondos y textos no cambian).
final bookColorSchemeProvider = FutureProvider.family<ColorScheme, String?>((ref, coverPath) async {
  final themeMode = ref.watch(themeProvider);
  final bool isDark = themeMode == ThemeMode.dark ||
      (themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
  final brightness = isDark ? Brightness.dark : Brightness.light;
  // Mismos fondos que el resto de la app (paleta propia o Material You)
  final palette = ref.watch(colorSourceProvider) == ColorSource.system ? await ref.watch(systemPaletteProvider.future) : null;
  final base = palette != null
      ? ColorScheme.fromSeed(seedColor: Color(palette.primary.get(40)), brightness: brightness)
      : (isDark ? AppSchemes.dark : AppSchemes.light);

  if (coverPath == null || !File(coverPath).existsSync()) return base;

  try {
    final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(FileImage(File(coverPath)), maximumColorCount: 10);
    final Color? cover = palette.vibrantColor?.color ?? palette.dominantColor?.color;
    if (cover == null) return base;
    final seeded = ColorScheme.fromSeed(seedColor: cover, brightness: brightness);
    return base.copyWith(
      primary: seeded.primary,
      onPrimary: seeded.onPrimary,
      primaryContainer: seeded.primaryContainer,
      onPrimaryContainer: seeded.onPrimaryContainer,
    );
  } catch (e) {
    return base;
  }
});
