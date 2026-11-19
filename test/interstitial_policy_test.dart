import 'package:book_tracker/services/interstitial_ads.dart';
import 'package:book_tracker/services/library_ad_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = DateTime(2026, 11, 1, 10);
  final later = DateTime(2026, 11, 20, 10); // pasados los 7 días de gracia

  bool can({DateTime? now, int sessions = 3, DateTime? last, bool finished = false, bool relaxed = false}) =>
      InterstitialPolicy.canShow(
        now: now ?? later,
        firstUseAt: first,
        sessionsSinceLast: sessions,
        lastShownAt: last,
        finishedBook: finished,
        relaxed: relaxed,
      );

  group('intersticial tras guardar una sesión', () {
    test('cada 3 sesiones, pasada la primera semana', () {
      expect(can(sessions: 3), isTrue);
      expect(can(sessions: 2), isFalse);
    });

    test('nunca en la primera semana de uso', () {
      expect(can(now: DateTime(2026, 11, 7, 9)), isFalse);
      expect(can(now: DateTime(2026, 11, 8, 10)), isTrue);
    });

    test('como mucho uno cada 24 horas', () {
      expect(can(last: later.subtract(const Duration(hours: 23))), isFalse);
      expect(can(last: later.subtract(const Duration(hours: 25))), isTrue);
    });

    test('nunca justo al terminar un libro', () {
      expect(can(finished: true), isFalse);
      expect(can(finished: true, relaxed: true), isFalse);
    });

    test('en versiones de prueba: sin gracia, cada 2 sesiones y 1 minuto', () {
      expect(can(now: DateTime(2026, 11, 1, 11), sessions: 2, relaxed: true), isTrue);
      expect(can(sessions: 1, relaxed: true), isFalse);
      expect(can(sessions: 2, last: later.subtract(const Duration(seconds: 30)), relaxed: true), isFalse);
    });
  });

  test('Mis citas: anuncio tras 3 citas y luego cada 8, máximo 2', () {
    final entries = libraryLayout(books: 30, adsReady: 2, firstAfter: 3, every: 8, maxAds: 2);
    final adPositions = [for (var i = 0; i < entries.length; i++) if (entries[i] is AdEntry) i];
    expect(adPositions, [3, 12]);
    expect(entries.whereType<BookEntry>(), hasLength(30));
  });
}
