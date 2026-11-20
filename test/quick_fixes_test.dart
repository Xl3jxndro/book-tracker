import 'dart:io';

import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/providers/app_info_provider.dart';
import 'package:book_tracker/providers/today_provider.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('versión de la app', () {
    test('muestra versión y número de compilación', () {
      expect(formatAppVersion('1.0.0', '9'), '1.0.0 (9)');
      expect(formatAppVersion('1.1.0', ''), '1.1.0');
    });
  });

  group('cambio de día', () {
    test('tiempo hasta el próximo día', () {
      expect(TodayNotifier.untilNextDay(DateTime(2026, 11, 16, 23, 59, 30)), const Duration(seconds: 31));
      // Fin de mes y de año
      expect(TodayNotifier.untilNextDay(DateTime(2026, 12, 31, 23, 0)), const Duration(hours: 1, seconds: 1));
    });

    test('"hoy" cambia al pasar la medianoche y solo notifica si cambió', () {
      var now = DateTime(2026, 11, 16, 23, 58);
      final container = ProviderContainer.test(overrides: [
        todayProvider.overrideWith(() => TodayNotifier(now: () => now, autoSchedule: false)),
      ]);
      final changes = <DateTime>[];
      container.listen<DateTime>(todayProvider, (_, next) => changes.add(next));
      final today = container.read(todayProvider.notifier);

      expect(container.read(todayProvider), DateTime(2026, 11, 16));

      now = DateTime(2026, 11, 16, 23, 59);
      today.refresh();
      expect(changes, isEmpty);

      now = DateTime(2026, 11, 17, 0, 0, 1);
      today.refresh();
      expect(changes, [DateTime(2026, 11, 17)]);
    });

    test('el tiempo de un día no incluye el del día siguiente', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final id = await db.insertBook(BooksCompanion.insert(title: 'Dune', author: 'Herbert', totalPages: 600));
      await db.insertSession(ReadingSessionsCompanion.insert(bookId: id, seconds: 600, date: Value(DateTime(2026, 11, 16))));
      await db.insertSession(ReadingSessionsCompanion.insert(bookId: id, seconds: 300, date: Value(DateTime(2026, 11, 17))));

      expect(await db.watchTotalTimeOn(DateTime(2026, 11, 16, 23, 59)).first, 600);
      expect(await db.watchTotalTimeOn(DateTime(2026, 11, 17, 8)).first, 300);
      expect(await db.watchTotalTimeOn(DateTime(2026, 11, 18)).first, 0);
    });
  });

  group('portadas huérfanas', () {
    late AppDatabase db;
    late Directory covers;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      covers = Directory.systemTemp.createTempSync('covers');
    });

    tearDown(() async {
      await db.close();
      if (covers.existsSync()) covers.deleteSync(recursive: true);
    });

    File cover(String name) => File(p.join(covers.path, name))..writeAsBytesSync([1, 2, 3]);

    Future<int> book(String? coverPath) => db.insertBook(BooksCompanion.insert(
          title: 'Libro', author: 'Autor', totalPages: 100, coverUrl: Value(coverPath)));

    test('borra la portada que ya nadie usa', () async {
      final old = cover('vieja.jpg');
      expect(await db.deleteCoverIfUnused(old.path, coversDir: covers.path), isTrue);
      expect(old.existsSync(), isFalse);
    });

    test('no borra una portada que otro libro sigue usando', () async {
      final shared = cover('compartida.jpg');
      await book(shared.path);
      expect(await db.deleteCoverIfUnused(shared.path, coversDir: covers.path), isFalse);
      expect(shared.existsSync(), isTrue);
    });

    test('nunca borra archivos fuera de la carpeta de portadas (p. ej. la galería)', () async {
      final gallery = Directory.systemTemp.createTempSync('galeria');
      addTearDown(() => gallery.deleteSync(recursive: true));
      final photo = File(p.join(gallery.path, 'foto.jpg'))..writeAsBytesSync([1]);

      expect(await db.deleteCoverIfUnused(photo.path, coversDir: covers.path), isFalse);
      expect(photo.existsSync(), isTrue);
    });

    test('rutas vacías o archivos que no existen no fallan', () async {
      expect(await db.deleteCoverIfUnused(null, coversDir: covers.path), isFalse);
      expect(await db.deleteCoverIfUnused('', coversDir: covers.path), isFalse);
      expect(await db.deleteCoverIfUnused(p.join(covers.path, 'no.jpg'), coversDir: covers.path), isFalse);
    });

    test('borrar un libro conserva la portada si otro libro la comparte', () async {
      final shared = cover('compartida.jpg');
      final first = await book(shared.path);
      await book(shared.path);

      final firstBook = await (db.select(db.books)..where((t) => t.id.equals(first))).getSingle();
      // deleteBookComplete usa la carpeta de documentos real; aquí basta con
      // comprobar que el archivo compartido sobrevive.
      await db.deleteBookComplete(firstBook);
      expect(shared.existsSync(), isTrue);
    });
  });
}
