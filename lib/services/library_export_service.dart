import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';
import 'app_language.dart';

enum ExportFormat { json, csv }

/// Exporta la biblioteca a un archivo para guardarlo o compartirlo.
///
/// - **JSON**: copia completa (libros, notas y sesiones) con versión de formato;
///   es la base para restaurar.
/// - **CSV**: lista de libros para hojas de cálculo.
///
/// Las portadas no se incluyen (irán en el respaldo .zip).
class LibraryExportService {
  LibraryExportService._();

  /// Sube si cambia la estructura del JSON (para que la restauración sepa leerlo).
  static const formatVersion = 1;
  static const appId = 'book_tracker';

  static const statusLabels = {0: 'Por leer', 1: 'Leyendo', 2: 'Terminado', 3: 'Abandonado'};

  // --- JSON ---

  static String buildJson({
    required List<Book> books,
    required List<Note> notes,
    required List<ReadingSession> sessions,
    required int schemaVersion,
    required DateTime exportedAt,
  }) {
    String iso(DateTime d) => d.toUtc().toIso8601String();

    final data = {
      'app': appId,
      'format_version': formatVersion,
      'schema_version': schemaVersion,
      'exported_at': iso(exportedAt),
      'counts': {'books': books.length, 'notes': notes.length, 'sessions': sessions.length},
      'books': [
        for (final b in books)
          {
            'id': b.id,
            'title': b.title,
            'author': b.author,
            'category': b.category,
            'total_pages': b.totalPages,
            'read_pages': b.readPages,
            'status': b.status,
            'status_label': statusLabels[b.status],
            'rating': b.rating,
            'total_read_seconds': b.totalReadTime,
            // Opcionales (desde la versión 8 de la base de datos)
            'started_at': b.startedAt == null ? null : iso(b.startedAt!),
            'finished_at': b.finishedAt == null ? null : iso(b.finishedAt!),
            // Solo el nombre: la ruta completa es de este teléfono
            'cover_file': (b.coverUrl == null || b.coverUrl!.isEmpty) ? null : p.basename(b.coverUrl!),
          },
      ],
      'notes': [
        for (final n in notes)
          {
            'id': n.id,
            'book_id': n.bookId,
            'content': n.content,
            'page_number': n.pageNumber,
            'created_at': iso(n.createdAt),
            // Opcional (desde la versión 9 de la base de datos)
            'is_favorite': n.isFavorite,
          },
      ],
      'sessions': [
        for (final s in sessions)
          {
            'id': s.id,
            'book_id': s.bookId,
            'date': iso(s.date),
            'seconds': s.seconds,
            'pages_read': s.pagesRead,
          },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // --- CSV ---

  static const _csvHeaders = [
    'Título', 'Autor', 'Categoría', 'Estado', 'Páginas leídas', 'Páginas totales',
    'Progreso (%)', 'Calificación', 'Tiempo de lectura (min)', 'Notas', 'Empezado', 'Terminado',
  ];

  /// Fecha AAAA-MM-DD: las hojas de cálculo la reconocen como fecha.
  static String _csvDate(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String buildCsv({required List<Book> books, required List<Note> notes}) {
    final notesPerBook = <int, int>{};
    for (final n in notes) {
      notesPerBook[n.bookId] = (notesPerBook[n.bookId] ?? 0) + 1;
    }

    final rows = <List<Object?>>[
      _csvHeaders,
      for (final b in books)
        [
          b.title,
          b.author,
          b.category ?? 'General',
          statusLabels[b.status] ?? '',
          b.readPages,
          b.totalPages,
          b.totalPages > 0 ? ((b.readPages / b.totalPages) * 100).floor() : 0,
          (b.rating ?? 0) > 0 ? b.rating : '',
          b.totalReadTime ~/ 60,
          notesPerBook[b.id] ?? 0,
          _csvDate(b.startedAt),
          b.status == 2 ? _csvDate(b.finishedAt) : '',
        ],
    ];

    // BOM: Excel abre el archivo como UTF-8 (acentos y ñ correctos).
    // CRLF: separador de filas del estándar CSV (RFC 4180).
    return '﻿${rows.map((r) => r.map(_csvCell).join(',')).join('\r\n')}\r\n';
  }

  static String _csvCell(Object? value) {
    if (value == null) return '';
    if (value is num) return value.toString();
    var text = value.toString();
    // Evita que una hoja de cálculo interprete el texto como fórmula
    if (text.isNotEmpty && '=+-@'.contains(text[0])) text = "'$text";
    final needsQuotes = text.contains(RegExp(r'[",\r\n]'));
    return needsQuotes ? '"${text.replaceAll('"', '""')}"' : text;
  }

  // --- Archivo y compartir ---

  static String fileName(ExportFormat format, DateTime date) {
    final day = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'book_tracker_$day.${format == ExportFormat.json ? 'json' : 'csv'}';
  }

  /// Genera el archivo en la carpeta temporal y abre el menú de compartir.
  /// Devuelve el número de libros exportados.
  static Future<int> exportAndShare(AppDatabase db, ExportFormat format) async {
    final books = await db.select(db.books).get();
    final notes = await db.select(db.notes).get();
    final now = DateTime.now();

    final String content;
    final String mimeType;
    if (format == ExportFormat.json) {
      final sessions = await db.select(db.readingSessions).get();
      content = buildJson(
        books: books,
        notes: notes,
        sessions: sessions,
        schemaVersion: db.schemaVersion,
        exportedAt: now,
      );
      mimeType = 'application/json';
    } else {
      content = buildCsv(books: books, notes: notes);
      mimeType = 'text/csv';
    }

    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName(format, now)));
    await file.writeAsString(content, encoding: utf8, flush: true);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: mimeType)],
      subject: AppLanguage.strings.exportShareSubject,
    ));
    return books.length;
  }
}
