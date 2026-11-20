import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';
import '../providers/color_source_provider.dart';
import '../providers/notifications_provider.dart';
import '../providers/streak_risk_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/app_info_provider.dart';
import '../providers/tutorial_provider.dart';
import '../providers/database_provider.dart';
import '../services/notification_service.dart';
import '../services/ads_consent.dart';
import '../services/library_export_service.dart';
import '../widgets/backup_actions.dart';
import '../widgets/remove_ads_card.dart';
import '../widgets/goodreads_import_actions.dart';
import '../widgets/secret_dialogs.dart';
import '../theme/app_colors.dart';
import '../services/app_update.dart';
import '../widgets/app_update_actions.dart';
import '../widgets/whats_new_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // --- LÓGICA DE NOTIFICACIONES ---

  Future<void> _selectTime(BuildContext context, WidgetRef ref, NotificationSettings settings) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: 'Hora del recordatorio',
    );
    
    if (picked != null) {
      ref.read(notificationsProvider.notifier).updateTime(picked.hour, picked.minute);
    }
  }

  Future<void> _selectStreakRiskTime(BuildContext context, WidgetRef ref, StreakRiskSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: 'Hora del aviso de racha',
    );
    if (picked != null) {
      await ref.read(streakRiskProvider.notifier).updateTime(picked.hour, picked.minute);
    }
  }

  Future<bool> _showPrePermissionDialog(BuildContext context, bool isDark) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: context.cs.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.app.streak.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories_rounded, size: 40, color: context.app.streak),
            ),
            const SizedBox(height: 20),
            Text(
              '¡No pierdas el hilo!',
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: context.cs.onSurface,
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
            color: context.cs.onSurfaceVariant,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(10, 10, 10, 15),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: context.cs.onSurfaceVariant),
            child: const Text('Ahora no', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.app.streak,
              foregroundColor: context.app.onAccent,
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
    final streakRisk = ref.watch(streakRiskProvider);
    // Activado pero sin permiso: el aviso no podría sonar
    final streakRiskBlocked = streakRisk.enabled && ref.watch(notificationPermissionProvider).value == false;
    final auth = ref.watch(authProvider);
    final appVersion = ref.watch(appVersionProvider).value ?? '…';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: context.cs.surface,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 140 + MediaQuery.of(context).padding.bottom),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            child: Text('Ajustes', style: Theme.of(context).textTheme.headlineLarge),
          ),
          _sectionHeader("APARIENCIA", context),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Tema de la aplicación',
              subtitle: _getModeName(currentMode),
              leadingIcon: currentMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: context.cs.primary,
              onTap: () => _showThemePicker(context, ref, isDark),
            ),
            _settingsTile(
              context,
              title: 'Colores',
              subtitle: _colorSourceLabel(ref),
              leadingIcon: Icons.palette_rounded,
              iconColor: context.cs.primary,
              onTap: () => _showColorSourcePicker(context, ref),
            ),
          ], context),
          /*
          const SizedBox(height: 25),

          _sectionHeader("TESTING (TEMPORAL)", context),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Lanzar notificación ahora',
              subtitle: 'Prueba el diseño y sonido del recordatorio',
              leadingIcon: Icons.bug_report_rounded,
              iconColor: context.cs.error,
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
          ], context),
          */
          const SizedBox(height: 25),
          
          _sectionHeader("PREFERENCIAS", context),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Notificaciones diarias',
              subtitle: notifSettings.enabled 
                  ? 'Recordatorio a las ${notifSettings.formattedTime}' 
                  : 'Desactivadas',
              leadingIcon: Icons.notifications_none_rounded,
              iconColor: context.cs.primary,
              onTap: notifSettings.enabled 
                  ? () => _selectTime(context, ref, notifSettings)
                  : null,
              trailing: Switch.adaptive(
                value: notifSettings.enabled,
                activeThumbColor: context.app.streak,
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
            _settingsTile(
              context,
              title: 'Aviso de racha en riesgo',
              subtitle: !streakRisk.enabled
                  ? 'Desactivado'
                  : streakRiskBlocked
                      ? '⚠️ Falta el permiso de notificaciones. Toca para activarlo.'
                      : 'Si llevas racha y hoy no has leído, te aviso a las ${streakRisk.formattedTime}',
              leadingIcon: Icons.local_fire_department_rounded,
              iconColor: context.cs.primary,
              onTap: !streakRisk.enabled
                  ? null
                  : streakRiskBlocked
                      ? () async {
                          await ref.read(streakRiskProvider.notifier).setEnabled(true);
                          ref.invalidate(notificationPermissionProvider);
                        }
                      : () => _selectStreakRiskTime(context, ref, streakRisk),
              // Solo en builds de prueba: ver el aviso sin esperar a la noche
              onLongPress: kDebugMode ? () => NotificationService.showStreakRiskPreview(5) : null,
              trailing: Switch.adaptive(
                value: streakRisk.enabled,
                activeThumbColor: context.app.streak,
                onChanged: (value) async {
                  final result = await ref.read(streakRiskProvider.notifier).setEnabled(value);
                  ref.invalidate(notificationPermissionProvider);
                  if (value && !result && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Activa las notificaciones de Book Tracker para recibir el aviso.'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              ),
            ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader("SEGURIDAD", context),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Bloqueo de la app',
              subtitle: auth.isLockEnabled
                  ? 'Pide tu palabra secreta al abrir'
                  : 'Desactivado: la app abre directamente',
              leadingIcon: auth.isLockEnabled ? Icons.lock_rounded : Icons.lock_open_rounded,
              iconColor: context.cs.primary,
              trailing: Switch.adaptive(
                value: auth.isLockEnabled,
                                onChanged: (value) => _toggleLock(context, ref, value),
              ),
            ),
            if (auth.isPassphraseSet)
              _settingsTile(
                context,
                title: 'Cambiar palabra secreta',
                subtitle: 'Tu "Santo y Seña" para entrar',
                leadingIcon: Icons.vpn_key_rounded,
                iconColor: context.cs.primary,
                onTap: () => _changePassphrase(context, ref),
              ),
            if (auth.isPassphraseSet || auth.isPinSet)
              _settingsTile(
                context,
                title: auth.isPinSet ? 'Cambiar PIN de respaldo' : 'Configurar PIN de respaldo',
                subtitle: 'Un código de 4 dígitos por si no recuerdas la palabra',
                leadingIcon: Icons.dialpad_rounded,
                iconColor: context.cs.primary,
                onTap: () => _changePin(context, ref),
              ),
            if (auth.isLockEnabled && (auth.isPassphraseSet || auth.isPinSet))
              _settingsTile(
                context,
                title: 'Bloquear al salir',
                subtitle: _autoLockLabel(auth.autoLockMinutes),
                leadingIcon: Icons.timer_outlined,
                iconColor: context.cs.primary,
                onTap: () => _showAutoLockPicker(context, ref, isDark),
              ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader("DATOS", context),
          _settingsGroup([
            _settingsTile(
              context,
              title: 'Respaldar o exportar',
              subtitle: 'Guarda una copia de tus libros, notas y portadas',
              leadingIcon: Icons.ios_share_rounded,
              iconColor: context.cs.primary,
              onTap: () => _showExportOptions(context, ref, isDark),
            ),
            _settingsTile(
              context,
              title: 'Restaurar respaldo',
              subtitle: 'Desde un respaldo .zip o una exportación .json',
              leadingIcon: Icons.settings_backup_restore_rounded,
              iconColor: context.cs.primary,
              onTap: () => restoreFromPickedFile(context, ref),
            ),
            _settingsTile(
              context,
              title: 'Importar de Goodreads',
              subtitle: 'Añade tus libros desde el archivo .csv de Goodreads',
              leadingIcon: Icons.download_rounded,
              iconColor: context.cs.primary,
              onTap: () => importFromGoodreads(context, ref),
            ),
            if (ref.watch(autoBackupExistsProvider).value ?? false)
              _settingsTile(
                context,
                title: 'Deshacer la última restauración',
                subtitle: 'Vuelve a la biblioteca que tenías antes',
                leadingIcon: Icons.undo_rounded,
                iconColor: context.cs.primary,
                onTap: () => undoLastRestore(context, ref),
              ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader("SIN ANUNCIOS", context),
          const RemoveAdsCard(),

          const SizedBox(height: 25),

          _sectionHeader("NOVEDADES", context),
          _settingsGroup([
            // Versión nueva en Google Play (solo si se instaló desde Play)
            ValueListenableBuilder<UpdateStatus>(
              valueListenable: AppUpdate.status,
              builder: (context, status, _) {
                final (title, subtitle) = switch (status) {
                  UpdateStatus.available => ('Hay una versión nueva', 'Toca para actualizar'),
                  UpdateStatus.downloading => ('Descargando actualización…', 'Puedes seguir usando la app'),
                  UpdateStatus.downloaded => ('Actualización lista', 'Toca para reiniciar e instalarla'),
                  UpdateStatus.checking => ('Buscando actualizaciones…', 'Versión $appVersion'),
                  UpdateStatus.upToDate => ('Buscar actualizaciones', 'Versión $appVersion · Estás al día'),
                  UpdateStatus.unknown => ('Buscar actualizaciones', 'Versión $appVersion'),
                };
                final highlight = status == UpdateStatus.available || status == UpdateStatus.downloaded;
                return _settingsTile(
                  context,
                  title: title,
                  subtitle: subtitle,
                  leadingIcon: highlight ? Icons.system_update_rounded : Icons.update_rounded,
                  iconColor: highlight ? context.app.accent : context.cs.primary,
                  trailing: status == UpdateStatus.checking || status == UpdateStatus.downloading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : highlight
                          ? Container(width: 10, height: 10, decoration: BoxDecoration(color: context.app.accent, shape: BoxShape.circle))
                          : null,
                  onTap: status == UpdateStatus.downloaded
                      ? AppUpdate.install
                      : () => checkForUpdatesManually(context),
                );
              },
            ),
            _settingsTile(
              context,
              title: 'Notas de la versión',
              subtitle: 'Lo nuevo en la versión ${WhatsNew.version} y anteriores',
              leadingIcon: Icons.new_releases_outlined,
              iconColor: context.cs.primary,
              onTap: () => WhatsNew.showHistory(context),
            ),
            _settingsTile(
              context,
              title: 'Ver la bienvenida de nuevo',
              subtitle: 'Repasa lo que puedes hacer en Book Tracker',
              leadingIcon: Icons.waving_hand_rounded,
              iconColor: context.cs.primary,
              onTap: () => ref.read(tutorialProvider.notifier).resetTutorials(),
            ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader("SOPORTE", context),
          // Solo donde Google lo exige (p. ej. UE): cambiar el consentimiento de anuncios
          ValueListenableBuilder<bool>(
            valueListenable: AdsConsent.privacyOptionsRequired,
            builder: (context, required, _) => _settingsGroup([
              if (required)
                _settingsTile(
                  context,
                  title: 'Opciones de privacidad de anuncios',
                  subtitle: 'Cambia tu consentimiento para anuncios personalizados',
                  leadingIcon: Icons.privacy_tip_outlined,
                  iconColor: context.cs.primary,
                  onTap: AdsConsent.showPrivacyOptions,
                ),
              _settingsTile(
                context,
                title: 'Acerca de la App',
                subtitle: 'Versión $appVersion',
                leadingIcon: Icons.info_outline_rounded,
                iconColor: context.cs.primary,
                onTap: () => _showAboutApp(context, isDark, appVersion),
              ),
            ], context),
          ),
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
          color: context.cs.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('Respaldar o exportar', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.inventory_2_rounded, color: context.app.accent),
              title: const Text('Respaldo completo (.zip)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Todo, con portadas. Sirve para restaurar en otro teléfono.'),
              onTap: () {
                Navigator.pop(sheetContext);
                shareFullBackup(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.data_object_rounded, color: context.app.accent),
              title: const Text('Datos sin portadas (JSON)', style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Libros, notas y sesiones de lectura.'),
              onTap: () {
                Navigator.pop(sheetContext);
                _export(context, ref, ExportFormat.json);
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart_rounded, color: context.cs.primary),
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

  static String _autoLockLabel(int minutes) => minutes == AuthNotifier.autoLockNever
      ? 'Nunca: solo al abrir la app'
      : 'Tras $minutes min fuera de la app';

  void _showAutoLockPicker(BuildContext context, WidgetRef ref, bool isDark) {
    final current = ref.read(authProvider).autoLockMinutes;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: context.cs.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 20, 8, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 20),
            const Text('Bloquear al salir', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                'Vuelve a pedir tu palabra si sales de la app durante este tiempo. '
                'Al desbloquear sigues donde estabas.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant),
              ),
            ),
            for (final minutes in AuthNotifier.autoLockOptions)
              ListTile(
                title: Text(minutes == AuthNotifier.autoLockNever ? 'Nunca' : 'Tras $minutes min'),
                trailing: minutes == current ? Icon(Icons.check_circle_rounded, color: context.cs.primary) : null,
                onTap: () {
                  ref.read(authProvider.notifier).setAutoLockMinutes(minutes);
                  Navigator.pop(sheetContext);
                },
              ),
          ],
        ),
      ),
    );
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
          color: context.cs.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        child: Column(
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.app.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories_rounded, size: 60, color: context.app.accent),
            ),
            const SizedBox(height: 20),
            Text('Book Tracker', 
              style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold, color: context.cs.onSurface)
            ),
            Text('Tu refugio de lectura digital', style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 14)),
            const Spacer(),
            Divider(color: context.cs.outlineVariant),
            _aboutRow(context, 'Versión', appVersion),
            _aboutRow(context, 'Desarrollador', 'José Aleandro Buitrago Cárdenas'),
            _aboutRow(context, 'Licencia', 'MIT'),
            const Spacer(),
            Text('© 2026 - Hecho con ❤️ para lectores', 
              style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 12)
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _aboutRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: context.cs.onSurfaceVariant)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Text(title,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.cs.onSurfaceVariant, letterSpacing: 1.4)),
    );
  }

  Widget _settingsGroup(List<Widget> children, BuildContext context) {
    // Grupo sin borde, con separadores finos entre filas
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(Divider(height: 1, indent: 72, endIndent: 16, color: context.cs.outlineVariant.withValues(alpha: 0.6)));
      rows.add(children[i]);
    }
    return Material(
      color: context.cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: Column(children: rows),
    );
  }

  Widget _settingsTile(BuildContext context, {
    required String title, 
    required String subtitle, 
    required IconData leadingIcon, 
    required Color iconColor,
    Widget? trailing,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      shape: const RoundedRectangleBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      onLongPress: onLongPress,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(leadingIcon, color: iconColor, size: 22),
      ),
      title: Text(title, style: theme.textTheme.titleSmall?.copyWith(fontSize: 15)),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: context.cs.onSurfaceVariant)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: context.cs.onSurfaceVariant),
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
          color: context.cs.surfaceContainerLow,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
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
      leading: Icon(icon, color: selected ? context.app.accent : context.cs.onSurfaceVariant),
      title: Text(label, style: TextStyle(fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: context.app.accent) : null,
      onTap: () {
        ref.read(themeProvider.notifier).setTheme(value);
        Navigator.pop(context);
      },
    );
  }

  String _colorSourceLabel(WidgetRef ref) {
    final source = ref.watch(colorSourceProvider);
    final available = ref.watch(systemPaletteProvider).value != null;
    if (source == ColorSource.system && available) return 'Del fondo de pantalla';
    return 'Book Tracker';
  }

  void _showColorSourcePicker(BuildContext context, WidgetRef ref) {
    final available = ref.read(systemPaletteProvider).value != null;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 20, 8, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 16),
              _colorSourceOption(
                context,
                ref,
                ColorSource.brand,
                'Book Tracker',
                'Crema y verde abeto de día, ciruela y ámbar de noche.',
                const [Color(0xFFEEE2CB), Color(0xFF1B4532), Color(0xFFC4553A), Color(0xFF2B1C33), Color(0xFFD9D3CC), Color(0xFFFF8C12)],
              ),
              _colorSourceOption(
                context,
                ref,
                ColorSource.system,
                'Del fondo de pantalla',
                available
                    ? 'Material You: los colores de tu fondo de pantalla.'
                    : 'Disponible en Android 12 o superior.',
                null,
                enabled: available,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _colorSourceOption(
    BuildContext context,
    WidgetRef ref,
    ColorSource value,
    String title,
    String subtitle,
    List<Color>? swatches, {
    bool enabled = true,
  }) {
    final selected = ref.read(colorSourceProvider) == value && enabled;
    final colors = swatches ??
        [context.cs.primaryContainer, context.cs.primary, context.cs.tertiary, context.cs.primaryContainer, context.cs.primary, context.cs.tertiary];
    return ListTile(
      enabled: enabled,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: SizedBox(
        width: 56,
        height: 28,
        child: Stack(children: [
          for (var i = 0; i < 3; i++)
            Positioned(
              left: i * 14.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: enabled ? colors[i + (Theme.of(context).brightness == Brightness.dark ? 3 : 0)] : context.cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.cs.surfaceContainerLow, width: 2),
                ),
              ),
            ),
        ]),
      ),
      title: Text(title, style: TextStyle(fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: selected ? Icon(Icons.check_circle_rounded, color: context.app.accent) : null,
      onTap: () {
        ref.read(colorSourceProvider.notifier).set(value);
        Navigator.pop(context);
      },
    );
  }
}
