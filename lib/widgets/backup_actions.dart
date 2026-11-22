import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/l10n.dart';
import '../providers/current_book_provider.dart';
import '../providers/database_provider.dart';
import '../services/backup_service.dart';
import '../services/home_widget_sync.dart';
import '../services/timer_persistence.dart';

/// Copia automática guardada antes de la última restauración (para deshacerla).
Future<File> _autoBackupFile() async {
  final docs = await getApplicationDocumentsDirectory();
  return File(p.join(docs.path, BackupService.autoBackupFolder, BackupService.autoBackupFileName));
}

/// ¿Hay una restauración que se pueda deshacer?
final autoBackupExistsProvider = FutureProvider<bool>((ref) async => (await _autoBackupFile()).exists());

/// Crea el respaldo completo (.zip con portadas) y abre el menú de compartir.
Future<void> shareFullBackup(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  try {
    final file = await _withProgress(context, l.backupPreparing, () async {
      final tmp = await getTemporaryDirectory();
      return BackupService.writeZip(ref.read(databaseProvider), tmp, BackupService.backupFileName(DateTime.now()));
    });
    if (file == null) return;
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'application/zip')],
      subject: l.backupShareSubject,
    ));
  } catch (e) {
    debugPrint('Error creando respaldo: $e');
    if (context.mounted) _showError(context, l.backupCreateError);
  }
}

/// Elegir un respaldo (.zip) o exportación (.json) y restaurarlo.
Future<void> restoreFromPickedFile(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFiles(dialogTitle: context.l10n.backupPickTitle);
  final path = picked.isEmpty ? null : picked.first.path;
  if (path == null || !context.mounted) return;
  await _restore(context, ref, File(path), isUndo: false);
}

/// Vuelve a la biblioteca que había antes de la última restauración.
Future<void> undoLastRestore(BuildContext context, WidgetRef ref) async {
  final file = await _autoBackupFile();
  if (!await file.exists() || !context.mounted) return;
  await _restore(context, ref, file, isUndo: true);
}

Future<void> _restore(BuildContext context, WidgetRef ref, File file, {required bool isUndo}) async {
  final db = ref.read(databaseProvider);
  final l = context.l10n;
  final tmp = await getTemporaryDirectory();
  final workDir = Directory(p.join(tmp.path, 'restaurar_${DateTime.now().millisecondsSinceEpoch}'));
  if (!context.mounted) return;

  try {
    // 1. Leer y validar (no toca nada)
    final preview = await _withProgress(context, l.backupReading, () => BackupService.read(file, workDir));
    if (preview == null || !context.mounted) return;

    final currentBooks = (await db.select(db.books).get()).length;
    if (!context.mounted) return;

    // 2. Confirmar con un resumen claro
    final confirmed = await _confirm(context, preview, currentBooks, isUndo: isUndo);
    if (confirmed != true || !context.mounted) return;

    // 3. Copia automática de lo actual y restauración
    final result = await _withProgress(context, l.backupRestoring, () async {
      final docs = await getApplicationDocumentsDirectory();
      await BackupService.writeZip(
        db,
        Directory(p.join(docs.path, BackupService.autoBackupFolder)),
        BackupService.autoBackupFileName,
      );
      final r = await BackupService.restore(db, preview, coversDir: docs.path);

      // La sesión del cronómetro y el "libro actual" eran de la biblioteca anterior
      await TimerPersistence.clearSession();
      await ref.read(currentBookProvider.notifier).clearCurrentBook();
      HomeWidgetSync.refresh();
      return r;
    });
    ref.invalidate(autoBackupExistsProvider);
    if (result == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(isUndo
          ? l.backupUndoDone(l.backupBooksCount(result.books))
          : l.backupRestoreDone(l.backupBooksCount(result.books), l.backupNotesCount(result.notes))),
    ));
  } on BackupException catch (e) {
    if (context.mounted) _showError(context, e.message);
  } catch (e) {
    debugPrint('Error restaurando: $e');
    if (context.mounted) _showError(context, l.backupRestoreError);
  } finally {
    try {
      if (await workDir.exists()) await workDir.delete(recursive: true);
    } catch (_) {}
  }
}

Future<bool?> _confirm(BuildContext context, BackupPreview preview, int currentBooks, {required bool isUndo}) {
  final l = context.l10n;
  final date = preview.exportedAt == null
      ? null
      : DateFormat.yMMMMd(context.languageCode).add_Hm().format(preview.exportedAt!);
  final covers = preview.coverFiles.length;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(isUndo ? l.backupUndoConfirmTitle : l.backupRestoreConfirmTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null) Text(isUndo ? l.backupSavedOn(date) : l.backupFrom(date)),
          const SizedBox(height: 8),
          Text('• ${l.backupBooksCount(preview.books.length)}\n'
              '• ${l.backupNotesCount(preview.notes.length)}\n'
              '• ${l.backupSessionsCount(preview.sessions.length)}\n'
              '• ${l.backupCoversCount(covers)}'),
          const SizedBox(height: 16),
          Text(
            l.backupReplaceWarning(l.backupBooksCount(currentBooks)),
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(isUndo ? l.backupUndoButton : l.backupRestoreButton)),
      ],
    ),
  );
}

/// Muestra un diálogo de espera mientras corre [task]. Devuelve su resultado
/// (o `null` si la pantalla ya no existe). Los errores se propagan.
Future<T?> _withProgress<T>(BuildContext context, String message, Future<T> Function() task) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  try {
    return await task();
  } finally {
    navigator.pop();
  }
}

void _showError(BuildContext context, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(context.l10n.backupErrorTitle),
      content: Text(message),
      actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.settingsGotIt))],
    ),
  );
}
