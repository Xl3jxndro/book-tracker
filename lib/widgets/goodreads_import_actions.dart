import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../providers/database_provider.dart';
import '../services/book_api_service.dart';
import '../services/goodreads_import.dart';
import '../services/home_widget_sync.dart';

/// Importar la biblioteca desde el CSV que exporta Goodreads: primero
/// explica cómo conseguir el archivo, luego muestra un resumen y añade los
/// libros sin tocar los que ya hay. Se puede deshacer.
Future<void> importFromGoodreads(BuildContext context, WidgetRef ref) async {
  final ready = await _showHowTo(context);
  if (ready != true || !context.mounted) return;

  final picked = await FilePicker.pickFiles(dialogTitle: 'Elige el CSV de Goodreads');
  final path = picked?.files.single.path;
  if (path == null || !context.mounted) return;

  final db = ref.read(databaseProvider);
  final GoodreadsPreview preview;
  try {
    final file = File(path);
    if (await file.length() > 20 * 1024 * 1024) {
      throw const GoodreadsImportException('El archivo es demasiado grande para ser una exportación de Goodreads.');
    }
    final text = utf8.decode(await file.readAsBytes(), allowMalformed: true);
    final existing = await db.select(db.books).get();
    preview = GoodreadsImport.parse(text, existing: existing);
  } on GoodreadsImportException catch (e) {
    if (context.mounted) _showMessage(context, 'No se pudo leer el archivo', e.message);
    return;
  } catch (e) {
    debugPrint('Error leyendo CSV de Goodreads: $e');
    if (context.mounted) {
      _showMessage(context, 'No se pudo leer el archivo', 'Asegúrate de elegir el archivo .csv que descargaste de Goodreads.');
    }
    return;
  }
  if (!context.mounted) return;

  if (preview.books.isEmpty) {
    _showMessage(
      context,
      'Nada nuevo que importar',
      preview.duplicates > 0
          ? 'Los ${preview.duplicates} libros del archivo ya están en tu biblioteca.'
          : 'El archivo no tiene libros.',
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
    if (context.mounted) _showMessage(context, 'No se pudo importar', 'No se añadió ningún libro. Inténtalo de nuevo.');
    return;
  }
  HomeWidgetSync.refresh();

  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 8),
    content: Text('${imported.length} libros importados de Goodreads 📚'),
    action: SnackBarAction(
      label: 'DESHACER',
      onPressed: () async {
        await GoodreadsImport.undo(db, imported);
        HomeWidgetSync.refresh();
        messenger.showSnackBar(const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Importación deshecha')));
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
      content: Text(found == 0
          ? 'No se encontraron portadas en Open Library. Puedes añadirlas editando cada libro.'
          : 'Portadas encontradas: $found de $total.'),
    ));
  }
}

class _ImportOptions {
  final bool fetchCovers;
  const _ImportOptions({required this.fetchCovers});
}

Future<bool?> _showHowTo(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Importar de Goodreads'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Primero descarga tu biblioteca desde Goodreads:'),
            SizedBox(height: 12),
            Text('1. Entra a goodreads.com en el navegador (la app de Goodreads no permite exportar).'),
            SizedBox(height: 6),
            Text('2. Ve a Mis libros → Importar y exportar (Import and export).'),
            SizedBox(height: 6),
            Text('3. Toca "Exportar biblioteca" (Export Library) y descarga el archivo .csv cuando esté listo.'),
            SizedBox(height: 12),
            Text('Tus libros actuales no se borran: solo se añaden los que faltan.'),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('ELEGIR ARCHIVO')),
      ],
    ),
  );
}

Future<_ImportOptions?> _confirm(BuildContext context, GoodreadsPreview preview) {
  var fetchCovers = preview.withIsbn > 0;
  final lines = [
    if (preview.countStatus(2) > 0) '• ${preview.countStatus(2)} leídos',
    if (preview.countStatus(1) > 0) '• ${preview.countStatus(1)} leyendo',
    if (preview.countStatus(0) > 0) '• ${preview.countStatus(0)} por leer',
    if (preview.countStatus(3) > 0) '• ${preview.countStatus(3)} abandonados',
    if (preview.notes > 0) '• ${preview.notes} reseñas y notas (se guardan como notas)',
  ];

  return showDialog<_ImportOptions>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Text('¿Importar ${preview.books.length} libros?'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lines.join('\n')),
                if (preview.duplicates > 0) ...[
                  const SizedBox(height: 10),
                  Text('Se omiten ${preview.duplicates} que ya están en tu biblioteca.', style: muted),
                ],
                if (preview.invalid > 0) ...[
                  const SizedBox(height: 4),
                  Text('Se omiten ${preview.invalid} filas sin título.', style: muted),
                ],
                const SizedBox(height: 10),
                Text(
                  'Goodreads no guarda el tiempo de lectura, así que la racha y el mapa de calor '
                  'no cambian. Los leídos con fecha cuentan en el reto de su año.',
                  style: muted.copyWith(fontSize: 12),
                ),
                if (preview.withIsbn > 0)
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: fetchCovers,
                    onChanged: (v) => setState(() => fetchCovers = v),
                    title: const Text('Buscar portadas'),
                    subtitle: Text('${preview.withIsbn} libros con ISBN · usa internet', style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _ImportOptions(fetchCovers: fetchCovers)),
              child: const Text('IMPORTAR'),
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
      actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('ENTENDIDO'))],
    ),
  );
}
