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
import '../l10n/l10n.dart';
import '../providers/language_provider.dart';
import '../services/app_language.dart';
import 'package:flutter/services.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  // --- LÓGICA DE NOTIFICACIONES ---

  Future<void> _selectTime(BuildContext context, WidgetRef ref, NotificationSettings settings) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: context.l10n.settingsReminderTimeHelp,
    );
    
    if (picked != null) {
      ref.read(notificationsProvider.notifier).updateTime(picked.hour, picked.minute);
    }
  }

  Future<void> _selectStreakRiskTime(BuildContext context, WidgetRef ref, StreakRiskSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.hour, minute: settings.minute),
      helpText: context.l10n.settingsStreakRiskTimeHelp,
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
              context.l10n.settingsPermissionTitle,
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
          context.l10n.settingsPermissionBody,
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
            child: Text(context.l10n.settingsNotNow, style: const TextStyle(fontWeight: FontWeight.w600)),
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
            child: Text(context.l10n.settingsPermissionAccept, style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l = context.l10n;

    return Scaffold(
      backgroundColor: context.cs.surface,
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 16, 16, 140 + MediaQuery.of(context).padding.bottom),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
            child: Text(l.settingsTitle, style: Theme.of(context).textTheme.headlineLarge),
          ),
          _sectionHeader(l.settingsSectionAppearance, context),
          _settingsGroup([
            _settingsTile(
              context,
              title: l.settingsThemeTitle,
              subtitle: _getModeName(context, currentMode),
              leadingIcon: currentMode == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              iconColor: context.cs.primary,
              onTap: () => _showThemePicker(context, ref, isDark),
            ),
            _settingsTile(
              context,
              title: l.settingsColorsTitle,
              subtitle: _colorSourceLabel(context, ref),
              leadingIcon: Icons.palette_rounded,
              iconColor: context.cs.primary,
              onTap: () => _showColorSourcePicker(context, ref),
            ),
            _settingsTile(
              context,
              title: context.l10n.settingsLanguage,
              subtitle: _languageLabel(context, ref.watch(languageProvider)),
              leadingIcon: Icons.translate_rounded,
              iconColor: context.cs.primary,
              onTap: () => _showLanguagePicker(context, ref),
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
          
          _sectionHeader(l.settingsSectionPreferences, context),
          _settingsGroup([
            _settingsTile(
              context,
              title: l.settingsDailyNotificationsTitle,
              subtitle: notifSettings.enabled
                  ? l.settingsDailyReminderAt(notifSettings.formattedTime)
                  : l.settingsDailyNotificationsOff,
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
              title: l.settingsStreakRiskTitle,
              subtitle: !streakRisk.enabled
                  ? l.settingsOff
                  : streakRiskBlocked
                      ? l.settingsStreakRiskNoPermission
                      : l.settingsStreakRiskSubtitle(streakRisk.formattedTime),
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
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.l10n.settingsStreakRiskNeedsPermission),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              ),
            ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader(l.settingsSectionSecurity, context),
          _settingsGroup([
            _settingsTile(
              context,
              title: l.settingsAppLockTitle,
              subtitle: auth.isLockEnabled
                  ? l.settingsAppLockOn
                  : l.settingsAppLockOff,
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
                title: l.settingsChangePassphraseTitle,
                subtitle: l.settingsChangePassphraseSubtitle,
                leadingIcon: Icons.vpn_key_rounded,
                iconColor: context.cs.primary,
                onTap: () => _changePassphrase(context, ref),
              ),
            if (auth.isPassphraseSet || auth.isPinSet)
              _settingsTile(
                context,
                title: auth.isPinSet ? l.settingsChangePin : l.settingsSetUpPin,
                subtitle: l.settingsPinSubtitle,
                leadingIcon: Icons.dialpad_rounded,
                iconColor: context.cs.primary,
                onTap: () => _changePin(context, ref),
              ),
            if (auth.isLockEnabled && (auth.isPassphraseSet || auth.isPinSet))
              _settingsTile(
                context,
                title: l.settingsAutoLockTitle,
                subtitle: _autoLockLabel(context, auth.autoLockMinutes),
                leadingIcon: Icons.timer_outlined,
                iconColor: context.cs.primary,
                onTap: () => _showAutoLockPicker(context, ref, isDark),
              ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader(l.settingsSectionData, context),
          _settingsGroup([
            _settingsTile(
              context,
              title: l.settingsExportTitle,
              subtitle: l.settingsExportSubtitle,
              leadingIcon: Icons.ios_share_rounded,
              iconColor: context.cs.primary,
              onTap: () => _showExportOptions(context, ref, isDark),
            ),
            _settingsTile(
              context,
              title: l.settingsRestoreTitle,
              subtitle: l.settingsRestoreSubtitle,
              leadingIcon: Icons.settings_backup_restore_rounded,
              iconColor: context.cs.primary,
              onTap: () => restoreFromPickedFile(context, ref),
            ),
            _settingsTile(
              context,
              title: l.goodreadsImportTitle,
              subtitle: l.settingsGoodreadsSubtitle,
              leadingIcon: Icons.download_rounded,
              iconColor: context.cs.primary,
              onTap: () => importFromGoodreads(context, ref),
            ),
            if (ref.watch(autoBackupExistsProvider).value ?? false)
              _settingsTile(
                context,
                title: l.settingsUndoRestoreTitle,
                subtitle: l.settingsUndoRestoreSubtitle,
                leadingIcon: Icons.undo_rounded,
                iconColor: context.cs.primary,
                onTap: () => undoLastRestore(context, ref),
              ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader(l.settingsSectionNoAds, context),
          const RemoveAdsCard(),

          const SizedBox(height: 25),

          _sectionHeader(l.settingsSectionWhatsNew, context),
          _settingsGroup([
            // Versión nueva en Google Play (solo si se instaló desde Play)
            ValueListenableBuilder<UpdateStatus>(
              valueListenable: AppUpdate.status,
              builder: (context, status, _) {
                final (title, subtitle) = switch (status) {
                  UpdateStatus.available => (l.updateAvailableTitle, l.updateTapToUpdate),
                  UpdateStatus.downloading => (l.updateDownloadingTitle, l.updateKeepUsing),
                  UpdateStatus.downloaded => (l.updateReadyTitle, l.updateTapToRestart),
                  UpdateStatus.checking => (l.updateCheckingTitle, l.settingsVersion(appVersion)),
                  UpdateStatus.upToDate => (l.updateCheckTitle, l.updateUpToDateSubtitle(appVersion)),
                  UpdateStatus.unknown => (l.updateCheckTitle, l.settingsVersion(appVersion)),
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
              title: l.whatsNewTitle,
              subtitle: l.settingsReleaseNotesSubtitle(WhatsNew.version),
              leadingIcon: Icons.new_releases_outlined,
              iconColor: context.cs.primary,
              onTap: () => WhatsNew.showHistory(context),
            ),
            _settingsTile(
              context,
              title: l.settingsReplayWelcomeTitle,
              subtitle: l.settingsReplayWelcomeSubtitle,
              leadingIcon: Icons.waving_hand_rounded,
              iconColor: context.cs.primary,
              onTap: () => ref.read(tutorialProvider.notifier).resetTutorials(),
            ),
          ], context),

          const SizedBox(height: 25),

          _sectionHeader(l.settingsSectionSupport, context),
          // Solo donde Google lo exige (p. ej. UE): cambiar el consentimiento de anuncios
          ValueListenableBuilder<bool>(
            valueListenable: AdsConsent.privacyOptionsRequired,
            builder: (context, required, _) => _settingsGroup([
              if (required)
                _settingsTile(
                  context,
                  title: l.settingsAdPrivacyTitle,
                  subtitle: l.settingsAdPrivacySubtitle,
                  leadingIcon: Icons.privacy_tip_outlined,
                  iconColor: context.cs.primary,
                  onTap: AdsConsent.showPrivacyOptions,
                ),
              _settingsTile(
                context,
                title: l.aboutTitle,
                subtitle: l.settingsVersion(appVersion),
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
            Text(context.l10n.settingsExportTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(Icons.inventory_2_rounded, color: context.app.accent),
              title: Text(context.l10n.settingsExportFullTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(context.l10n.settingsExportFullSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                shareFullBackup(context, ref);
              },
            ),
            ListTile(
              leading: Icon(Icons.data_object_rounded, color: context.app.accent),
              title: Text(context.l10n.settingsExportJsonTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(context.l10n.settingsExportJsonSubtitle),
              onTap: () {
                Navigator.pop(sheetContext);
                _export(context, ref, ExportFormat.json);
              },
            ),
            ListTile(
              leading: Icon(Icons.table_chart_rounded, color: context.cs.primary),
              title: Text(context.l10n.settingsExportCsvTitle, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text(context.l10n.settingsExportCsvSubtitle),
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
        _showSaved(context, context.l10n.settingsExportEmpty);
      }
    } catch (e) {
      debugPrint('Error exportando: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.settingsExportError),
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
        final phrase = await showNewPassphraseDialog(context, title: context.l10n.authCreatePassphraseTitle);
        if (phrase == null) return;
        await notifier.savePassphrase(phrase);
      }
      await notifier.setLockEnabled(true);
      if (context.mounted) _showSaved(context, context.l10n.settingsLockEnabled);
      return;
    }

    // Desactivarlo es sensible: confirmar que es el dueño
    if (!await confirmIdentity(context, notifier, state: state)) return;
    await notifier.setLockEnabled(false);
    if (context.mounted) _showSaved(context, context.l10n.settingsLockDisabled);
  }

  Future<void> _changePassphrase(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(authProvider.notifier);
    if (!await confirmIdentity(context, notifier, state: ref.read(authProvider))) return;
    if (!context.mounted) return;

    final phrase = await showNewPassphraseDialog(context);
    if (phrase == null) return;
    await notifier.savePassphrase(phrase);
    if (context.mounted) _showSaved(context, context.l10n.settingsPassphraseUpdated);
  }

  static String _autoLockLabel(BuildContext context, int minutes) => minutes == AuthNotifier.autoLockNever
      ? context.l10n.settingsAutoLockNever
      : context.l10n.settingsAutoLockAfter(minutes);

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
            Text(context.l10n.settingsAutoLockTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
              child: Text(
                context.l10n.settingsAutoLockDescription,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: context.cs.onSurfaceVariant),
              ),
            ),
            for (final minutes in AuthNotifier.autoLockOptions)
              ListTile(
                title: Text(minutes == AuthNotifier.autoLockNever
                    ? context.l10n.settingsAutoLockNeverOption
                    : context.l10n.settingsAutoLockAfterOption(minutes)),
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
    if (context.mounted) _showSaved(context, context.l10n.settingsPinSaved);
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
            Text(context.l10n.aboutTagline, style: TextStyle(color: context.cs.onSurfaceVariant, fontSize: 14)),
            const Spacer(),
            Divider(color: context.cs.outlineVariant),
            _aboutRow(context, context.l10n.aboutVersion, appVersion),
            _aboutRow(context, context.l10n.aboutDeveloper, 'José Aleandro Buitrago Cárdenas'),
            _aboutRow(context, context.l10n.aboutLicense, 'MIT'),
            const Spacer(),
            Text(context.l10n.aboutFooter,
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

  String _getModeName(BuildContext context, ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system: return context.l10n.settingsThemeFollowSystem;
      case ThemeMode.light: return context.l10n.settingsThemeLight;
      case ThemeMode.dark: return context.l10n.settingsThemeDark;
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
            _themeOption(context, ref, context.l10n.settingsThemeSystem, ThemeMode.system, Icons.brightness_auto_rounded),
            _themeOption(context, ref, context.l10n.settingsThemeLight, ThemeMode.light, Icons.light_mode_rounded),
            _themeOption(context, ref, context.l10n.settingsThemeDark, ThemeMode.dark, Icons.dark_mode_rounded),
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

  String _colorSourceLabel(BuildContext context, WidgetRef ref) {
    final source = ref.watch(colorSourceProvider);
    final available = ref.watch(systemPaletteProvider).value != null;
    if (source == ColorSource.system && available) return context.l10n.settingsColorsWallpaper;
    return 'Book Tracker';
  }

  String _languageLabel(BuildContext context, LanguageSetting setting) => switch (setting) {
        LanguageSetting.system => context.l10n.languageSystem,
        LanguageSetting.spanish => context.l10n.languageSpanish,
        LanguageSetting.english => context.l10n.languageEnglish,
      };

  void _showLanguagePicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) {
        final current = ref.read(languageProvider);
        Widget option(LanguageSetting value, String title, {String? subtitle}) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              title: Text(title, style: TextStyle(fontWeight: current == value ? FontWeight.w700 : FontWeight.w500)),
              subtitle: subtitle == null ? null : Text(subtitle),
              trailing: current == value ? Icon(Icons.check_circle_rounded, color: context.app.accent) : null,
              onTap: () {
                HapticFeedback.selectionClick();
                ref.read(languageProvider.notifier).set(value);
                Navigator.pop(sheetContext);
              },
            );
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10))),
                const SizedBox(height: 16),
                option(LanguageSetting.system, context.l10n.languageSystem, subtitle: context.l10n.languageSystemSubtitle),
                // Cada idioma con su propio nombre, para encontrarlo aunque no se entienda el actual
                option(LanguageSetting.spanish, 'Español'),
                option(LanguageSetting.english, 'English'),
              ],
            ),
          ),
        );
      },
    );
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
                context.l10n.settingsColorsBrandDescription,
                const [Color(0xFFEEE2CB), Color(0xFF1B4532), Color(0xFFC4553A), Color(0xFF2B1C33), Color(0xFFD9D3CC), Color(0xFFFF8C12)],
              ),
              _colorSourceOption(
                context,
                ref,
                ColorSource.system,
                context.l10n.settingsColorsWallpaper,
                available
                    ? context.l10n.settingsColorsWallpaperDescription
                    : context.l10n.settingsColorsUnavailable,
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
