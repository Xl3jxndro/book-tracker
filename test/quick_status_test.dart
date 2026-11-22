import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/services/app_language.dart';
import 'package:book_tracker/services/quick_status.dart';
import 'package:flutter_test/flutter_test.dart';

Book _b(int status, {int read = 20, DateTime? started, DateTime? finished}) => Book(
    id: 1, title: 'L', author: 'A', totalPages: 100, readPages: read, totalReadTime: 0, status: status,
    startedAt: started, finishedAt: finished);

void main() {
  final now = DateTime(2026, 11, 20, 15);

  test('pendiente → leyendo, con fecha de inicio', () {
    final r = applyQuickStatus(_b(0, read: 0), now)!;
    expect(r.status, 1);
    expect(r.startedAt, now);
    expect(r.readPages, 0);
    expect(quickStatusAction(_b(0))!.label(AppLanguage.strings), 'Empezar a leer');
  });

  test('leyendo → terminado: completa las páginas y pone fecha de fin', () {
    final started = DateTime(2026, 11, 1);
    final r = applyQuickStatus(_b(1, started: started), now)!;
    expect(r.status, 2);
    expect(r.readPages, 100);
    expect(r.startedAt, started, reason: 'conserva la fecha de inicio');
    expect(r.finishedAt, now);
  });

  test('abandonado → leyendo, sin perder el progreso', () {
    final r = applyQuickStatus(_b(3, read: 40), now)!;
    expect(r.status, 1);
    expect(r.readPages, 40);
    expect(quickStatusAction(_b(3))!.label(AppLanguage.strings), 'Retomar');
  });

  test('un libro terminado no tiene acción rápida', () {
    expect(applyQuickStatus(_b(2, read: 100), now), isNull);
    expect(quickStatusAction(_b(2)), isNull);
  });
}
