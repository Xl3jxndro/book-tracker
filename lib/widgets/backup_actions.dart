import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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
  try {
    final file = await _withProgress(context, 'Preparando el respaldo…', () async {
      final tmp = await getTemporaryDirectory();
      return BackupService.writeZip(ref.read(databaseProvider), tmp, BackupService.backupFileName(DateTime.now()));
    });
    if (file == null) return;
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/zip')],
      subject: 'Respaldo de Book Tracker',
    );
  } catch (e) {
    debugPrint('Error creando respaldo: $e');
    if (context.mounted) _showError(context, 'No se pudo crear el respaldo. Inténtalo de nuevo.');
  }
}

/// Elegir un respaldo (.zip) o exportación (.json) y restaurarlo.
Future<void> restoreFromPickedFile(BuildContext context, WidgetRef ref) async {
  final picked = await FilePicker.pickFiles(dialogTitle: 'Elige tu respaldo');
  final path = picked?.files.single.path;
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
  final tmp = await getTemporaryDirectory();
  final workDir = Directory(p.join(tmp.path, 'restaurar_${DateTime.now().millisecondsSinceEpoch}'));
  if (!context.mounted) return;

  try {
    // 1. Leer y validar (no toca nada)
    final preview = await _withProgress(context, 'Leyendo el respaldo…', () => BackupService.read(file, workDir));
    if (preview == null || !context.mounted) return;

    final currentBooks = (await db.select(db.books).get()).length;
    if (!context.mounted) return;

    // 2. Confirmar con un resumen claro
    final confirmed = await _confirm(context, preview, currentBooks, isUndo: isUndo);
    if (confirmed != true || !context.mounted) return;

    // 3. Copia automática de lo actual y restauración
    final result = await _withProgress(context, 'Restaurando tu biblioteca…', () async {
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
          ? 'Biblioteca anterior recuperada: ${result.books} libros.'
          : 'Biblioteca restaurada: ${result.books} libros, ${result.notes} notas.'),
    ));
  } on BackupException catch (e) {
    if (context.mounted) _showError(context, e.message);
  } catch (e) {
    debugPrint('Error restaurando: $e');
    if (context.mounted) _showError(context, 'No se pudo restaurar el respaldo. Tu biblioteca no cambió.');
  } finally {
    try {
      if (await workDir.exists()) await workDir.delete(recursive: true);
    } catch (_) {}
  }
}

Future<bool?> _confirm(BuildContext context, BackupPreview preview, int currentBooks, {required bool isUndo}) {
  final date = preview.exportedAt == null
      ? null
      : DateFormat("d 'de' MMMM 'de' y, HH:mm", 'es').format(preview.exportedAt!);
  final covers = preview.coverFiles.length;

  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(isUndo ? '¿Deshacer la última restauración?' : '¿Restaurar este respaldo?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (date != null) Text(isUndo ? 'Biblioteca guardada el $date' : 'Respaldo del $date'),
          const SizedBox(height: 8),
          Text('• ${preview.books.length} libros\n'
              '• ${preview.notes.length} notas\n'
              '• ${preview.sessions.length} sesiones de lectura\n'
              '• ${covers == 0 ? 'Sin portadas' : '$covers portadas'}'),
          const SizedBox(height: 16),
          Text(
            'Reemplazará tu biblioteca actual ($currentBooks libros). '
            'Antes guardaremos una copia para que puedas deshacerlo.',
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(isUndo ? 'DESHACER' : 'RESTAURAR')),
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
      title: const Text('No se pudo completar'),
      content: Text(message),
      actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDIDO'))],
    ),
  );
}
