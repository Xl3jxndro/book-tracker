import 'package:book_tracker/providers/color_source_provider.dart';
import 'package:book_tracker/theme/app_colors.dart';
import 'package:book_tracker/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('por defecto, paletas de Book Tracker; la elección se guarda', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer.test();
    container.listen(colorSourceProvider, (_, _) {});
    expect(container.read(colorSourceProvider), ColorSource.brand);

    await container.read(colorSourceProvider.notifier).set(ColorSource.system);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ColorSourceNotifier.prefsKey), 'system');

    final again = ProviderContainer.test();
    again.listen(colorSourceProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    expect(again.read(colorSourceProvider), ColorSource.system);
  });

  test('tema de Material You: acento del sistema y estados armonizados', () {
    const palette = Color(0xFF3366CC);
    for (final b in Brightness.values) {
      final theme = AppTheme.fromSystem(palette, b);
      final app = theme.extension<AppColors>()!;
      expect(theme.colorScheme.brightness, b);
      expect(app.accent, theme.colorScheme.tertiary);
      expect(app.statusFinished, isNot(b == Brightness.dark ? AppColors.dark.statusFinished : AppColors.light.statusFinished));
    }
  });

  test('las paletas propias tienen los colores elegidos', () {
    expect(AppTheme.light.colorScheme.surface, const Color(0xFFEEE2CB));
    expect(AppTheme.light.colorScheme.primary, const Color(0xFF1B4532));
    expect(AppTheme.dark.colorScheme.surface, const Color(0xFF2B1C33));
    expect(AppTheme.dark.extension<AppColors>()!.accent, const Color(0xFFFF8C12));
  });
}
