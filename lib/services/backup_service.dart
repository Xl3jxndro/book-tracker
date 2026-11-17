import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import '../database/database.dart';
import 'library_export_service.dart';

/// Error de respaldo con un mensaje listo para mostrar al usuario.
class BackupException implements Exception {
  final String message;
  const BackupException(this.message);

  @override
  String toString() => 'BackupException: $message';
}

/// Contenido de un respaldo ya leído y validado, antes de restaurarlo.
class BackupPreview {
  final DateTime? exportedAt;
  final List<Map<String, dynamic>> books;
  final List<Map<String, dynamic>> notes;
  final List<Map<String, dynamic>> sessions;

  /// Portadas extraídas del .zip: nombre del archivo → archivo temporal.
  final Map<String, File> coverFiles;

  const BackupPreview({
    required this.exportedAt,
    required this.books,
    required this.notes,
    required this.sessions,
    required this.coverFiles,
  });
}

class RestoreResult {
  final int books;
  final int notes;
  final int sessions;
  final int covers;
  const RestoreResult({required this.books, required this.notes, required this.sessions, required this.covers});
}

/// Respaldo completo (.zip con datos y portadas) y restauración.
///
/// Formato del .zip:
/// - `backup.json`: el mismo JSON de la exportación (LibraryExportService).
/// - `covers/<archivo>`: las portadas, referenciadas por `cover_file`.
///
/// También se puede restaurar el `.json` de la exportación (sin portadas).
class BackupService {
  BackupService._();

  static const jsonEntry = 'backup.json';
  static const coversPrefix = 'covers/';

  /// Copia automática que se guarda antes de cada restauración.
  static const autoBackupFileName = 'antes_de_restaurar.zip';
  static const autoBackupFolder = 'respaldos';

  static const _maxText = 100;
  static const _maxNote = 1000;

  // --- Crear respaldo ---

  static Future<Uint8List> buildZip(AppDatabase db, {DateTime? now}) async {
    final books = await db.select(db.books).get();
    final notes = await db.select(db.notes).get();
    final sessions = await db.select(db.readingSessions).get();

    final archive = Archive();
    archive.addFile(ArchiveFile.string(
      jsonEntry,
      LibraryExportService.buildJson(
        books: books,
        notes: notes,
        sessions: sessions,
        schemaVersion: db.schemaVersion,
        exportedAt: now ?? DateTime.now(),
      ),
    ));

    final added = <String>{};
    for (final book in books) {
      final path = book.coverUrl;
      if (path == null || path.isEmpty) continue;
      final name = p.basename(path);
      if (!added.add(name)) continue; // portada compartida: una sola vez
      final file = File(path);
      if (await file.exists()) {
        archive.addFile(ArchiveFile.bytes('$coversPrefix$name', await file.readAsBytes()));
      }
    }
    return ZipEncoder().encodeBytes(archive);
  }

  static String backupFileName(DateTime date) {
    final day = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'book_tracker_respaldo_$day.zip';
  }

  /// Escribe el respaldo en [directory] y devuelve el archivo.
  static Future<File> writeZip(AppDatabase db, Directory directory, String fileName) async {
    await directory.create(recursive: true);
    final file = File(p.join(directory.path, fileName));
    return file.writeAsBytes(await buildZip(db), flush: true);
  }

  // --- Leer y validar ---

  /// Lee un respaldo (.zip) o una exportación (.json). Las portadas se
  /// extraen en [workDir]. No toca la base de datos.
  static Future<BackupPreview> read(File file, Directory workDir) async {
    final Uint8List bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (_) {
      throw const BackupException('No se pudo leer el archivo.');
    }

    final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B && bytes[2] == 0x03 && bytes[3] == 0x04;
    String jsonText;
    final covers = <String, File>{};

    if (isZip) {
      final Archive archive;
      try {
        archive = ZipDecoder().decodeBytes(bytes);
      } catch (_) {
        throw const BackupException('El archivo .zip está dañado.');
      }
      final jsonFile = archive.find(jsonEntry);
      if (jsonFile == null) {
        throw const BackupException('Este .zip no es un respaldo de Book Tracker.');
      }
      jsonText = utf8.decode(jsonFile.content, allowMalformed: true);

      await workDir.create(recursive: true);
      for (final entry in archive.files) {
        if (!entry.isFile || !entry.name.startsWith(coversPrefix)) continue;
        // Solo el nombre: evita rutas tipo "../" que escriban fuera de workDir
        final name = p.basename(entry.name);
        if (name.isEmpty || name.startsWith('.')) continue;
        final out = File(p.join(workDir.path, name));
        await out.writeAsBytes(entry.content);
        covers[name] = out;
      }
    } else {
      try {
        jsonText = utf8.decode(bytes);
      } catch (_) {
        throw const BackupException('El archivo no es un respaldo de Book Tracker.');
      }
    }

    final Object? data;
    try {
      data = jsonDecode(jsonText.startsWith('﻿') ? jsonText.substring(1) : jsonText);
    } catch (_) {
      throw const BackupException('El archivo no es un respaldo de Book Tracker.');
    }
    if (data is! Map<String, dynamic> || data['app'] != LibraryExportService.appId) {
      throw const BackupException('El archivo no es un respaldo de Book Tracker.');
    }

    final version = data['format_version'];
    if (version is! int || version < 1) {
      throw const BackupException('El respaldo tiene un formato desconocido.');
    }
    if (version > LibraryExportService.formatVersion) {
      throw const BackupException('Este respaldo es de una versión más nueva de la app. Actualízala y vuelve a intentarlo.');
    }

    final Map<String, dynamic> json = data;
    List<Map<String, dynamic>> listOf(String key) =>
        ((json[key] as List?) ?? const []).whereType<Map<String, dynamic>>().toList();

    if (json['books'] is! List) {
      throw const BackupException('El respaldo está incompleto: no contiene libros.');
    }

    return BackupPreview(
      exportedAt: DateTime.tryParse(data['exported_at']?.toString() ?? '')?.toLocal(),
      books: listOf('books'),
      notes: listOf('notes'),
      sessions: listOf('sessions'),
      coverFiles: covers,
    );
  }

  // --- Restaurar ---

  /// Reemplaza toda la biblioteca por el contenido de [preview].
  ///
  /// Todo se valida antes de tocar nada y la sustitución ocurre en una sola
  /// transacción: si algo falla, la biblioteca queda como estaba. Las
  /// portadas se copian a [coversDir] con nombres nuevos y, solo si todo
  /// salió bien, se borran las antiguas que ya nadie usa.
  static Future<RestoreResult> restore(
    AppDatabase db,
    BackupPreview preview, {
    required String coversDir,
    DateTime? now,
  }) async {
    final stamp = (now ?? DateTime.now()).millisecondsSinceEpoch;

    // 1. Validar y convertir (sin tocar nada todavía)
    final parsedBooks = <({BooksCompanion row, String? cover})>[];
    final bookIds = <int>{};
    for (var i = 0; i < preview.books.length; i++) {
      final b = preview.books[i];
      final id = _int(b['id']);
      final title = _text(b['title'], _maxText);
      final author = _text(b['author'], _maxText);
      final totalPages = _int(b['total_pages']);
      if (id == null || title == null || author == null || totalPages == null || totalPages < 0 || !bookIds.add(id)) {
        throw BackupException('El respaldo tiene datos dañados (libro ${i + 1}). No se cambió nada.');
      }
      final status = _int(b['status']) ?? 0;
      final rating = _int(b['rating']) ?? 0;
      parsedBooks.add((
        row: BooksCompanion.insert(
          id: Value(id),
          title: title,
          author: author,
          totalPages: totalPages,
          readPages: Value(_atMost(_nonNeg(_int(b['read_pages'])), totalPages)),
          totalReadTime: Value(_nonNeg(_int(b['total_read_seconds']))),
          status: Value(status >= 0 && status <= 3 ? status : 0),
          category: Value(_text(b['category'], _maxText) ?? 'General'),
          rating: Value(rating >= 0 && rating <= 5 ? rating : 0),
        ),
        cover: b['cover_file'] is String ? p.basename(b['cover_file'] as String) : null,
      ));
    }

    final notes = <NotesCompanion>[];
    for (final n in preview.notes) {
      final bookId = _int(n['book_id']);
      final content = _text(n['content'], _maxNote);
      if (bookId == null || !bookIds.contains(bookId) || content == null) continue; // nota huérfana o vacía
      notes.add(NotesCompanion.insert(
        bookId: bookId,
        content: content,
        pageNumber: Value(_int(n['page_number'])),
        createdAt: Value(_date(n['created_at']) ?? DateTime.now()),
      ));
    }

    final sessions = <ReadingSessionsCompanion>[];
    for (final s in preview.sessions) {
      final bookId = _int(s['book_id']);
      final date = _date(s['date']);
      if (bookId == null || !bookIds.contains(bookId) || date == null) continue;
      sessions.add(ReadingSessionsCompanion.insert(
        bookId: bookId,
        seconds: _nonNeg(_int(s['seconds'])),
        pagesRead: Value(_nonNeg(_int(s['pages_read']))),
        date: Value(date),
      ));
    }

    // 2. Copiar portadas con nombres nuevos (no pisan las actuales)
    final copied = <File>[];
    final newCoverPath = <String, String>{};
    var index = 0;
    try {
      for (final book in parsedBooks) {
        final name = book.cover;
        if (name == null || newCoverPath.containsKey(name)) continue;
        final source = preview.coverFiles[name];
        if (source == null || !await source.exists()) continue;
        final ext = p.extension(name).isEmpty ? '.jpg' : p.extension(name);
        final dest = p.join(coversDir, 'cover_r${stamp}_${index++}$ext');
        copied.add(await source.copy(dest));
        newCoverPath[name] = dest;
      }
    } catch (e) {
      await _deleteAll(copied);
      throw const BackupException('No se pudieron copiar las portadas. No se cambió nada.');
    }

    final books = [
      for (final b in parsedBooks)
        b.row.copyWith(coverUrl: Value(b.cover == null ? null : newCoverPath[b.cover])),
    ];
    final oldCovers = (await db.select(db.books).get()).map((b) => b.coverUrl).whereType<String>().toSet();

    // 3. Sustituir todo en una sola transacción
    try {
      await db.transaction(() async {
        await db.delete(db.readingSessions).go();
        await db.delete(db.notes).go();
        await db.delete(db.books).go();
        await db.batch((batch) {
          batch.insertAll(db.books, books);
          batch.insertAll(db.notes, notes);
          batch.insertAll(db.readingSessions, sessions);
        });
      });
    } catch (e) {
      await _deleteAll(copied);
      throw const BackupException('No se pudo restaurar el respaldo. Tu biblioteca no cambió.');
    }

    // 4. Las portadas antiguas que ya nadie usa dejan de ocupar espacio
    for (final old in oldCovers) {
      await db.deleteCoverIfUnused(old, coversDir: coversDir);
    }

    return RestoreResult(
      books: books.length,
      notes: notes.length,
      sessions: sessions.length,
      covers: newCoverPath.length,
    );
  }

  static Future<void> _deleteAll(List<File> files) async {
    for (final f in files) {
      try {
        await f.delete();
      } catch (_) {}
    }
  }

  static int? _int(Object? v) => v is int ? v : (v is num ? v.toInt() : int.tryParse(v?.toString() ?? ''));

  static String? _text(Object? v, int max) {
    if (v is! String) return null;
    final t = v.trim();
    if (t.isEmpty) return null;
    return t.length <= max ? t : t.substring(0, max).trim();
  }

  static DateTime? _date(Object? v) => DateTime.tryParse(v?.toString() ?? '')?.toLocal();

  static int _nonNeg(int? v) => (v == null || v < 0) ? 0 : v;

  static int _atMost(int v, int max) => v > max ? max : v;
}
