import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../l10n/l10n.dart';
import '../providers/database_provider.dart';
import '../services/book_api_service.dart';
import '../services/goodreads_import.dart';
import '../services/home_widget_sync.dart';

/// Importar la biblioteca desde el CSV que exporta Goodreads: primero
/// explica cómo conseguir el archivo, luego muestra un resumen y añade los
/// libros sin tocar los que ya hay. Se puede deshacer.
Future<void> importFromGoodreads(BuildContext context, WidgetRef ref) async {
  final l = context.l10n;
  final ready = await _showHowTo(context);
  if (ready != true || !context.mounted) return;

  final picked = await FilePicker.pickFiles(dialogTitle: l.goodreadsPickTitle);
  final path = picked.isEmpty ? null : picked.first.path;
  if (path == null || !context.mounted) return;

  final db = ref.read(databaseProvider);
  final GoodreadsPreview preview;
  try {
    final file = File(path);
    if (await file.length() > 20 * 1024 * 1024) {
      throw GoodreadsImportException(l.goodreadsFileTooLarge);
    }
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    final existing = await db.select(db.books).get();
    preview = GoodreadsImport.parse(text, existing: existing);
  } on GoodreadsImportException catch (e) {
    if (context.mounted) _showMessage(context, l.goodreadsReadErrorTitle, e.message);
    return;
  } catch (e) {
    debugPrint('Error leyendo CSV de Goodreads: $e');
    if (context.mounted) {
      _showMessage(context, l.goodreadsReadErrorTitle, l.goodreadsReadErrorBody);
    }
    return;
  }
  if (!context.mounted) return;

  if (preview.books.isEmpty) {
    _showMessage(
      context,
      l.goodreadsNothingNewTitle,
      preview.duplicates > 0
          ? l.goodreadsAllDuplicates(preview.duplicates)
          : l.goodreadsNoBooks,
    );
    return;
  }

  final options = await _confirm(context, preview);
  if (options == null || !context.mounted) return;

  final messenger = ScaffoldMessenger.of(context);
  final List<ImportedBook> imported;
  try {
    imported = await GoodreadsImport.import(db, preview.books);
  } catch (e) {
    debugPrint('Error importando de Goodreads: $e');
    if (context.mounted) _showMessage(context, l.goodreadsImportErrorTitle, l.goodreadsImportErrorBody);
    return;
  }
  HomeWidgetSync.refresh();

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 8),
    content: Text(l.goodreadsImported(imported.length)),
    action: SnackBarAction(
      label: l.goodreadsUndo,
      onPressed: () async {
        await GoodreadsImport.undo(db, imported);
        HomeWidgetSync.refresh();
        messenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text(l.goodreadsUndone)));
      },
    ),
  ));

  if (options.fetchCovers && imported.any((b) => b.isbn13 != null)) {
    // En segundo plano: se puede seguir usando la app mientras tanto
    final docs = await getApplicationDocumentsDirectory();
    final api = BookApiService();
    final total = imported.where((b) => b.isbn13 != null).length;
    final found = await GoodreadsImport.fetchCovers(db, api, imported, docs);
    debugPrint('Portadas de Goodreads: $found de $total');
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(found == 0 ? l.goodreadsNoCovers : l.goodreadsCoversFound(found, total)),
    ));
  }
}

class _ImportOptions {
  final bool fetchCovers;
  const _ImportOptions({required this.fetchCovers});
}

Future<bool?> _showHowTo(BuildContext context) {
  final l = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(l.goodreadsImportTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.goodreadsHowToIntro),
            const SizedBox(height: 12),
            Text(l.goodreadsHowToStep1),
            const SizedBox(height: 6),
            Text(l.goodreadsHowToStep2),
            const SizedBox(height: 6),
            Text(l.goodreadsHowToStep3),
            const SizedBox(height: 12),
            Text(l.goodreadsHowToNote),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.commonCancel)),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(l.goodreadsChooseFile)),
      ],
    ),
  );
}

Future<_ImportOptions?> _confirm(BuildContext context, GoodreadsPreview preview) {
  final l = context.l10n;
  var fetchCovers = preview.withIsbn > 0;
  final lines = [
    if (preview.countStatus(2) > 0) '• ${l.goodreadsCountRead(preview.countStatus(2))}',
    if (preview.countStatus(1) > 0) '• ${l.goodreadsCountReading(preview.countStatus(1))}',
    if (preview.countStatus(0) > 0) '• ${l.goodreadsCountToRead(preview.countStatus(0))}',
    if (preview.countStatus(3) > 0) '• ${l.goodreadsCountAbandoned(preview.countStatus(3))}',
    if (preview.notes > 0) '• ${l.goodreadsCountNotes(preview.notes)}',
  ];

  return showDialog<_ImportOptions>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text(l.goodreadsConfirmTitle(preview.books.length)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lines.join('\n')),
                if (preview.duplicates > 0) ...[
                  const SizedBox(height: 10),
                  Text(l.goodreadsSkippedDuplicates(preview.duplicates), style: muted),
                ],
                if (preview.invalid > 0) ...[
                  const SizedBox(height: 4),
                  Text(l.goodreadsSkippedInvalid(preview.invalid), style: muted),
                ],
                const SizedBox(height: 10),
                Text(
                  l.goodreadsNoReadingTime,
                  style: muted.copyWith(fontSize: 12),
                ),
                if (preview.withIsbn > 0)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: fetchCovers,
                    onChanged: (v) => setState(() => fetchCovers = v),
                    title: Text(l.goodreadsFetchCovers),
                    subtitle: Text(l.goodreadsFetchCoversSubtitle(preview.withIsbn), style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _ImportOptions(fetchCovers: fetchCovers)),
              child: Text(l.goodreadsImportButton),
            ),
          ],
        );
      },
    ),
  );
}

void _showMessage(BuildContext context, String title, String message) {
  showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(title),
      content: Text(message),
      actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.settingsGotIt))],
    ),
  );
}
