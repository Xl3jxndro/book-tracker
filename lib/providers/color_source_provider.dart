import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart' show Color;
import 'package:shared_preferences/shared_preferences.dart';

/// De dónde salen los colores de la app.
enum ColorSource {
  /// Paletas de Book Tracker (Crema/Abeto/Terracota y Ciruela/Titanio/Ámbar).
  brand,

  /// Material You: colores del fondo de pantalla (Android 12+).
  system,
}

final colorSourceProvider = NotifierProvider<ColorSourceNotifier, ColorSource>(ColorSourceNotifier.new);

class ColorSourceNotifier extends Notifier<ColorSource> {
  static const prefsKey = 'color_source';

  @override
  ColorSource build() {
    _load();
    return ColorSource.brand;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefsKey);
    if (!ref.mounted) return;
    state = ColorSource.values.firstWhere((s) => s.name == saved, orElse: () => ColorSource.brand);
  }

  Future<void> set(ColorSource source) async {
    state = source;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, source.name);
  }
}

/// Color semilla del fondo de pantalla, o null si el teléfono no lo ofrece
/// (Android 11 o anterior).
final systemPaletteProvider = FutureProvider<Color?>((ref) async {
  try {
    // ignore: deprecated_member_use
    final palette = await DynamicColorPlugin.getCorePalette();
    return palette == null ? null : Color(palette.primary.get(40));
  } catch (e) {
    debugPrint('Sin colores del sistema: $e');
    return null;
  }
});
