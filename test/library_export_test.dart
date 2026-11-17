import 'dart:convert';

import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/services/library_export_service.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Book _book({
  int id = 1,
  String title = 'Cien años de soledad',
  String author = 'Gabriel García Márquez',
  int totalPages = 400,
  int readPages = 100,
  int status = 1,
  String? category = 'Novela',
  String? coverUrl,
  int? rating = 0,
  int totalReadTime = 3600,
  DateTime? startedAt,
  DateTime? finishedAt,
}) =>
    Book(
      id: id,
      title: title,
      author: author,
      totalPages: totalPages,
      readPages: readPages,
      totalReadTime: totalReadTime,
      status: status,
      category: category,
      coverUrl: coverUrl,
      rating: rating,
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

void main() {
  final exportedAt = DateTime.utc(2026, 11, 16, 12);

  group('JSON', () {
    test('incluye cabecera, conteos y todos los datos', () {
      final json = LibraryExportService.buildJson(
        books: [_book(coverUrl: '/data/user/0/com.jabc.booktracker/app_flutter/cover_1.jpg')],
        notes: [Note(id: 7, bookId: 1, content: 'Muchos años después…', pageNumber: 1, createdAt: DateTime.utc(2026, 1, 2))],
        sessions: [ReadingSession(id: 3, bookId: 1, seconds: 1800, pagesRead: 20, date: DateTime.utc(2026, 1, 2))],
        schemaVersion: 7,
        exportedAt: exportedAt,
      );
      final data = jsonDecode(json) as Map<String, dynamic>;

      expect(data['app'], 'book_tracker');
      expect(data['format_version'], LibraryExportService.formatVersion);
      expect(data['schema_version'], 7);
      expect(data['exported_at'], '2026-11-16T12:00:00.000Z');
      expect(data['counts'], {'books': 1, 'notes': 1, 'sessions': 1});

      final book = (data['books'] as List).single as Map<String, dynamic>;
      expect(book['title'], 'Cien años de soledad');
      expect(book['status'], 1);
      expect(book['status_label'], 'Leyendo');
      expect(book['total_read_seconds'], 3600);
      expect(book['cover_file'], 'cover_1.jpg'); // sin la ruta del teléfono

      final note = (data['notes'] as List).single as Map<String, dynamic>;
      expect(note['book_id'], 1);
      expect(note['content'], 'Muchos años después…');
      expect(note['created_at'], '2026-01-02T00:00:00.000Z');

      final session = (data['sessions'] as List).single as Map<String, dynamic>;
      expect(session['seconds'], 1800);
      expect(session['pages_read'], 20);
    });

    test('biblioteca vacía genera un JSON válido', () {
      final data = jsonDecode(LibraryExportService.buildJson(
        books: const [], notes: const [], sessions: const [], schemaVersion: 7, exportedAt: exportedAt,
      )) as Map<String, dynamic>;
      expect(data['books'], isEmpty);
      expect(data['counts'], {'books': 0, 'notes': 0, 'sessions': 0});
    });
  });

  group('CSV', () {
    List<String> lines(String csv) {
      expect(csv.startsWith('﻿'), isTrue, reason: 'BOM para que Excel lea UTF-8');
      return csv.substring(1).split('\r\n')..removeLast();
    }

    test('cabecera y una fila por libro con progreso, estado y notas', () {
      final csv = LibraryExportService.buildCsv(
        books: [
          _book(),
          _book(id: 2, title: 'El Principito', status: 2, readPages: 96, totalPages: 96, rating: 5, totalReadTime: 125, startedAt: DateTime(2026, 3, 1), finishedAt: DateTime(2026, 3, 9)),
        ],
        notes: [
          Note(id: 1, bookId: 1, content: 'a', createdAt: DateTime(2026)),
          Note(id: 2, bookId: 1, content: 'b', createdAt: DateTime(2026)),
        ],
      );
      final rows = lines(csv);

      expect(rows, hasLength(3));
      expect(rows[0], startsWith('Título,Autor,Categoría,Estado'));
      expect(rows[1], 'Cien años de soledad,Gabriel García Márquez,Novela,Leyendo,100,400,25,,60,2,,');
      expect(rows[2], 'El Principito,Gabriel García Márquez,Novela,Terminado,96,96,100,5,2,0,2026-03-01,2026-03-09');
    });

    test('escapa comas, comillas y saltos de línea', () {
      final csv = LibraryExportService.buildCsv(
        books: [_book(title: 'Hola, "mundo"\nadiós')],
        notes: const [],
      );
      expect(lines(csv)[1], startsWith('"Hola, ""mundo""\nadiós",'));
    });

    test('un título que empieza como fórmula no se ejecuta en la hoja de cálculo', () {
      final csv = LibraryExportService.buildCsv(books: [_book(title: '=HYPERLINK("x")')], notes: const []);
      expect(lines(csv)[1], startsWith('"\'=HYPERLINK(""x"")",'));
    });
  });

  test('exporta lo que hay en una base de datos real', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final id = await db.insertBook(BooksCompanion.insert(title: 'Dune', author: 'Frank Herbert', totalPages: 600));
    await db.insertNote(NotesCompanion.insert(bookId: id, content: 'El miedo mata la mente'));
    await db.logProgress(id, 50, additionalSeconds: 900);

    final data = jsonDecode(LibraryExportService.buildJson(
      books: await db.select(db.books).get(),
      notes: await db.select(db.notes).get(),
      sessions: await db.select(db.readingSessions).get(),
      schemaVersion: db.schemaVersion,
      exportedAt: exportedAt,
    )) as Map<String, dynamic>;

    expect(data['schema_version'], 8);
    expect(data['counts'], {'books': 1, 'notes': 1, 'sessions': 1});
    final book = (data['books'] as List).single as Map<String, dynamic>;
    expect(book['read_pages'], 50);
    expect(book['status_label'], 'Leyendo');
    expect(book['category'], 'General'); // valor por defecto de la tabla
    expect((data['sessions'] as List).single['pages_read'], 50);
  });

  test('nombre de archivo con la fecha', () {
    final date = DateTime(2026, 3, 7);
    expect(LibraryExportService.fileName(ExportFormat.json, date), 'book_tracker_2026-03-07.json');
    expect(LibraryExportService.fileName(ExportFormat.csv, date), 'book_tracker_2026-03-07.csv');
  });
}
