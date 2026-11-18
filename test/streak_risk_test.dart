import 'package:book_tracker/services/streak.dart';
import 'package:flutter_test/flutter_test.dart';

List<DateTime> _days(List<int> novemberDays) => [for (final d in novemberDays) DateTime(2026, 11, d, 10, 30)];

void main() {
  group('racha actual', () {
    final now = DateTime(2026, 11, 17, 15);

    test('cuenta hasta hoy si hoy ya se leyó', () {
      expect(ReadingStreak.current(_days([14, 15, 16, 17]), now), 4);
    });

    test('si hoy aún no se leyó, la racha de ayer sigue viva', () {
      expect(ReadingStreak.current(_days([14, 15, 16]), now), 3);
    });

    test('un día sin leer la rompe', () {
      expect(ReadingStreak.current(_days([13, 14, 15]), now), 0);
      expect(ReadingStreak.current(_days([12, 13, 15, 16, 17]), now), 3);
    });

    test('varias sesiones el mismo día cuentan una vez; cruza meses', () {
      final dates = [DateTime(2026, 10, 31, 8), DateTime(2026, 11, 1, 8), DateTime(2026, 11, 1, 22), DateTime(2026, 11, 2)];
      expect(ReadingStreak.current(dates, DateTime(2026, 11, 2, 12)), 3);
    });

    test('sin sesiones es 0', () {
      expect(ReadingStreak.current(const [], now), 0);
    });
  });

  group('aviso de racha en riesgo', () {
    StreakRiskAlert? next(List<int> days, DateTime now) =>
        StreakRisk.next(readingDates: _days(days), now: now, hour: 21, minute: 0);

    test('racha viva y hoy sin leer: aviso hoy a las 21:00', () {
      expect(next([14, 15, 16], DateTime(2026, 11, 17, 9)), StreakRiskAlert(DateTime(2026, 11, 17, 21), 3));
    });

    test('si ya pasó la hora, no avisa hoy', () {
      expect(next([14, 15, 16], DateTime(2026, 11, 17, 21, 30)), isNull);
    });

    test('hoy ya se leyó: el aviso queda para mañana con la racha incluyendo hoy', () {
      expect(next([15, 16, 17], DateTime(2026, 11, 17, 9)), StreakRiskAlert(DateTime(2026, 11, 18, 21), 3));
      // También después de las 21:00
      expect(next([15, 16, 17], DateTime(2026, 11, 17, 23)), StreakRiskAlert(DateTime(2026, 11, 18, 21), 3));
    });

    test('una racha de 1 día aún no avisa', () {
      expect(next([16], DateTime(2026, 11, 17, 9)), isNull);
      expect(next([17], DateTime(2026, 11, 17, 9)), isNull);
      // Con 2 días sí
      expect(next([16, 17], DateTime(2026, 11, 17, 9)), StreakRiskAlert(DateTime(2026, 11, 18, 21), 2));
    });

    test('racha ya perdida: nada que avisar', () {
      expect(next([10, 11, 12], DateTime(2026, 11, 17, 9)), isNull);
    });

    test('el último día del mes programa para el 1 del siguiente', () {
      final dates = [DateTime(2026, 11, 29), DateTime(2026, 11, 30)];
      expect(
        StreakRisk.next(readingDates: dates, now: DateTime(2026, 11, 30, 12), hour: 20, minute: 15),
        StreakRiskAlert(DateTime(2026, 12, 1, 20, 15), 2),
      );
    });

    test('textos', () {
      expect(StreakRisk.title(5), '🔥 Tu racha de 5 días está en riesgo');
    });
  });
}
