import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_info_provider.dart';
import '../providers/database_provider.dart';
import '../services/library_export_service.dart';
import '../widgets/secret_dialogs.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // --- LÓGICA DE NOTIFICACIONES ---

  Future<void> _selectTime(BuildContext context, WidgetRef ref, NotificationSettings settings) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: 'SELECCIONA HORA DE LECTURA',
    );
    
    if (picked != null) {
      ref.read(notificationsProvider.notifier).updateTime(picked.hour, picked.minute);
    }
  }

  Future<bool> _showPrePermissionDialog(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orangeAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories_rounded, size: 40, color: Colors.orangeAccent),
            ),
            const SizedBox(height: 20),
            Text(
              '¡No pierdas el hilo!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        content: Text(
          'Activamos recordatorios diarios para ayudarte a mantener tu racha de lectura y alcanzar tus metas. ¡Tu refugio digital te espera!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: const Text('Ahora no', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orangeAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('¡Claro que sí!', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeProvider);
    final notifSettings = ref.watch(notificationsProvider);
    final auth = ref.watch(authProvider);
    final appVersion = ref.watch(appVersionProvider).valueOrNull ?? '…';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFFBFBFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: false,
        title: Text('Ajustes',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 28,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -1)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        children: [
          _sectionHeader("APARIENCIA", isDark),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Tema de la aplicación',
              subtitle: _getModeName(currentMode),
              leadingIcon: currentMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: Colors.indigoAccent,
              onTap: () => _showThemePicker(context, ref, isDark),
            ),
          ], isDark),
          /*
          const SizedBox(height: 25),

          _sectionHeader("TESTING (TEMPORAL)", isDark),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Lanzar notificación ahora',
              subtitle: 'Prueba el diseño y sonido del recordatorio',
              leadingIcon: Icons.bug_report_rounded,
              iconColor: Colors.redAccent,
              onTap: () async {
                await ref.read(notificationsProvider.notifier).showImmediateTestNotification();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🚀 Notificación enviada'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ], isDark),
          */
          const SizedBox(height: 25),
          
          _sectionHeader("PREFERENCIAS", isDark),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Notificaciones diarias',
              subtitle: notifSettings.enabled 
                  ? 'Recordatorio a las ${notifSettings.formattedTime}' 
                  : 'Desactivadas',
              leadingIcon: Icons.notifications_none_rounded,
              iconColor: Colors.orangeAccent,
              onTap: notifSettings.enabled 
                  ? () => _selectTime(context, ref, notifSettings)
                  : null,
              trailing: Switch.adaptive(
                value: notifSettings.enabled,
                activeThumbColor: Colors.orangeAccent,
                onChanged: (value) async {
                  if (value) {
                    final confirmed = await _showPrePermissionDialog(context, isDark);
                    if (confirmed && context.mounted) {
                      await ref.read(notificationsProvider.notifier).toggleNotifications(true);
                      
                      // Si el permiso fue concedido exitosamente, mostramos el selector de hora
                      final updatedSettings = ref.read(notificationsProvider);
                      if (updatedSettings.enabled && context.mounted) {
                        _selectTime(context, ref, updatedSettings);
                      }
                    }
                  } else {
                    await ref.read(notificationsProvider.notifier).toggleNotifications(false);
                  }
                },
              ),
            ),
          ], isDark),

          const SizedBox(height: 25),

          _sectionHeader("SEGURIDAD", isDark),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Bloqueo de la app',
              subtitle: auth.isLockEnabled
                  ? 'Pide tu palabra secreta al abrir'
                  : 'Desactivado: la app abre directamente',
              leadingIcon: auth.isLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
              iconColor: Colors.teal,
              trailing: Switch.adaptive(
                value: auth.isLockEnabled,
                activeThumbColor: Colors.teal,
                onChanged: (value) => _toggleLock(context, ref, value),
              ),
            ),
            if (auth.isPassphraseSet)
              _settingsTile(
                context,
                title: 'Cambiar palabra secreta',
                subtitle: 'Tu "Santo y Seña" para entrar',
                leadingIcon: Icons.vpn_key_rounded,
                iconColor: Colors.teal,
                onTap: () => _changePassphrase(context, ref),
              ),
            if (auth.isPassphraseSet || auth.isPinSet)
              _settingsTile(
                context,
                title: auth.isPinSet ? 'Cambiar PIN de respaldo' : 'Configurar PIN de respaldo',
                subtitle: 'Un código de 4 dígitos por si no recuerdas la palabra',
                leadingIcon: Icons.dialpad_rounded,
                iconColor: Colors.teal,
                onTap: () => _changePin(context, ref),
              ),
          ], isDark),

          const SizedBox(height: 25),

          _sectionHeader("DATOS", isDark),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Exportar biblioteca',
              subtitle: 'Guarda o comparte una copia de tus libros y notas',
              leadingIcon: Icons.ios_share_rounded,
              iconColor: Colors.deepPurpleAccent,
              onTap: () => _showExportOptions(context, ref, isDark),
            ),
          ], isDark),

          const SizedBox(height: 25),

          _sectionHeader("SOPORTE", isDark),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Acerca de la App',
              subtitle: 'Versión $appVersion',
              leadingIcon: Icons.info_outline_rounded,
              iconColor: Colors.blueGrey,
              onTap: () => _showAboutApp(context, isDark, appVersion),
            ),
          ], isDark),
        ],
      ),
    );
  }

  // --- DATOS ---

  void _showExportOptions(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('Exportar biblioteca', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.data_object_rounded, color: Colors.deepPurpleAccent),
              title: const Text('Copia completa (JSON)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Libros, notas y sesiones de lectura. Sin portadas.'),
              onTap: () {
                Navigator.pop(sheetContext);
                _export(context, ref, ExportFormat.json);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart_rounded, color: Colors.green),
              title: const Text('Hoja de cálculo (CSV)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Lista de libros para Excel o Google Sheets.'),
              onTap: () {
                Navigator.pop(sheetContext);
                _export(context, ref, ExportFormat.csv);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref, ExportFormat format) async {
    try {
      final count = await LibraryExportService.exportAndShare(ref.read(databaseProvider), format);
      if (count == 0 && context.mounted) {
        _showSaved(context, 'Tu biblioteca está vacía: el archivo no tiene libros.');
      }
    } catch (e) {
      debugPrint('Error exportando: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('No se pudo exportar. Inténtalo de nuevo.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // --- SEGURIDAD ---

  void _showSaved(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _toggleLock(BuildContext context, WidgetRef ref, bool enable) async {
    final notifier = ref.read(authProvider.notifier);
    final state = ref.read(authProvider);

    if (enable) {
      // Para activar el bloqueo hace falta una palabra secreta
      if (!state.isPassphraseSet && !state.isPinSet) {
        final phrase = await showNewPassphraseDialog(context, title: 'Crea tu Santo y Seña');
        if (phrase == null) return;
        await notifier.savePassphrase(phrase);
      }
      await notifier.setLockEnabled(true);
      if (context.mounted) _showSaved(context, '🔒 Bloqueo activado');
      return;
    }

    // Desactivarlo es sensible: confirmar que es el dueño
    if (!await confirmIdentity(context, notifier, state: state)) return;
    await notifier.setLockEnabled(false);
    if (context.mounted) _showSaved(context, 'Bloqueo desactivado');
  }

  Future<void> _changePassphrase(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(authProvider.notifier);
    if (!await confirmIdentity(context, notifier, state: ref.read(authProvider))) return;
    if (!context.mounted) return;

    final phrase = await showNewPassphraseDialog(context);
    if (phrase == null) return;
    await notifier.savePassphrase(phrase);
    if (context.mounted) _showSaved(context, '✨ Palabra secreta actualizada');
  }

  Future<void> _changePin(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(authProvider.notifier);
    if (!await confirmIdentity(context, notifier, state: ref.read(authProvider))) return;
    if (!context.mounted) return;

    final pin = await showNewPinDialog(context);
    if (pin == null) return;
    await notifier.saveNewPin(pin);
    if (context.mounted) _showSaved(context, 'PIN de respaldo guardado');
  }

  // --- COMPONENTES UI ---

  void _showAboutApp(BuildContext context, bool isDark, String appVersion) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.indigoAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_stories_rounded, size: 60, color: Colors.indigoAccent),
            ),
            const SizedBox(height: 20),
            Text('Book Tracker', 
              style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)
            ),
            const Text('Tu refugio de lectura digital', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const Spacer(),
            const Divider(color: Colors.white10),
            _aboutRow('Versión', appVersion),
            _aboutRow('Desarrollador', 'José Aleandro Buitrago Cárdenas'),
            _aboutRow('Licencia', 'MIT'),
            const Spacer(),
            Text('© 2026 - Hecho con ❤️ para lectores', 
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 10),
      child: Text(title, 
        style: TextStyle(
          fontSize: 11, 
          fontWeight: FontWeight.w900, 
          color: isDark ? Colors.white38 : Colors.black38,
          letterSpacing: 1.5
        )
      ),
    );
  }

  Widget _settingsGroup(List<Widget> children, bool isDark) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData leadingIcon, 
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(leadingIcon, color: iconColor, size: 22),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
    );
  }

  String _getModeName(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return 'Seguir sistema';
      case ThemeMode.light: return 'Modo Claro';
      case ThemeMode.dark: return 'Modo Oscuro';
    }
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            _themeOption(context, ref, 'Sistema', ThemeMode.system, Icons.brightness_auto_rounded),
            _themeOption(context, ref, 'Modo Claro', ThemeMode.light, Icons.light_mode_rounded),
            _themeOption(context, ref, 'Modo Oscuro', ThemeMode.dark, Icons.dark_mode_rounded),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, WidgetRef ref, String label, ThemeMode value, IconData icon) {
    final selected = ref.read(themeProvider) == value;
    return ListTile(
      leading: Icon(icon, color: selected ? Colors.indigoAccent : Colors.grey),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      trailing: selected ? const Icon(Icons.check_circle_rounded, color: Colors.indigoAccent) : null,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(value);
        Navigator.pop(context);
      },
    );
  }
}