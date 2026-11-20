import 'dart:io';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:google_fonts/google_fonts.dart';

// --- TEMA EDITORIAL (CONFIGURACIÓN DE FUENTES) ---
TextTheme _buildEditorialTextTheme(Brightness brightness) {
  final color = brightness == Brightness.dark ? Colors.white : Colors.black87;
  return TextTheme(
    displayLarge: GoogleFonts.lora(fontWeight: FontWeight.bold, color: color),
    headlineMedium: GoogleFonts.lora(fontWeight: FontWeight.w700, color: color),
    titleLarge: GoogleFonts.lora(fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.5),
    bodyLarge: GoogleFonts.inter(fontSize: 16, letterSpacing: 0.2),
    bodyMedium: GoogleFonts.inter(fontSize: 14, color: color.withValues(alpha: 0.8)),
    labelLarge: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.1, fontSize: 12),
  );
}

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
final bookColorSchemeProvider = FutureProvider.family<ColorScheme, String?>((ref, coverPath) async {
  final themeMode = ref.watch(themeProvider);
  final bool isDark = themeMode == ThemeMode.dark || 
      (themeMode == ThemeMode.system && WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
  const defaultSeed = Colors.indigo;

  if (coverPath == null || !File(coverPath).existsSync()) {
    return ColorScheme.fromSeed(seedColor: defaultSeed, brightness: isDark ? Brightness.dark : Brightness.light);
  }

  try {
    final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(FileImage(File(coverPath)), maximumColorCount: 10);
    final Color targetColor = palette.vibrantColor?.color ?? palette.dominantColor?.color ?? defaultSeed;
    return ColorScheme.fromSeed(seedColor: targetColor, brightness: isDark ? Brightness.dark : Brightness.light);
  } catch (e) {
    return ColorScheme.fromSeed(seedColor: defaultSeed, brightness: isDark ? Brightness.dark : Brightness.light);
  }
});

// --- PROVIDER DE TEMA COMPLETO ---
final appThemeProvider = Provider.family<ThemeData, ColorScheme>((ref, colorScheme) {
  final isDark = colorScheme.brightness == Brightness.dark;
  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    textTheme: _buildEditorialTextTheme(colorScheme.brightness),
    scaffoldBackgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFBFBFC),
    appBarTheme: const AppBarTheme(centerTitle: false, backgroundColor: Colors.transparent, elevation: 0),
    timePickerTheme: TimePickerThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      hourMinuteShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
});