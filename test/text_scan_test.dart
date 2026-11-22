import 'package:book_tracker/screens/scan_quote_screen.dart';
import 'package:book_tracker/services/text_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// Página de prueba de 1000 x 1000 px con dos líneas:
///   línea 0: "había de recordar aque-"  (y = 100..140)
///   línea 1: "lla tarde remota"         (y = 200..240)
const _words = [
  ScanWord('había', Rect.fromLTRB(100, 100, 250, 140), 0),
  ScanWord('de', Rect.fromLTRB(270, 100, 330, 140), 0),
  ScanWord('recordar', Rect.fromLTRB(350, 100, 600, 140), 0),
  ScanWord('aque-', Rect.fromLTRB(620, 100, 800, 140), 0),
  ScanWord('lla', Rect.fromLTRB(100, 200, 200, 240), 1),
  ScanWord('tarde', Rect.fromLTRB(220, 200, 400, 240), 1),
  ScanWord('remota', Rect.fromLTRB(420, 200, 650, 240), 1),
];

void main() {
  group('unir líneas escaneadas', () {
    test('une las líneas con un espacio y limpia espacios de más', () {
      expect(joinScannedLines(['  Muchos años después,  ', 'frente al   pelotón']), 'Muchos años después, frente al pelotón');
    });

    test('pega las palabras cortadas con guion al final de línea', () {
      expect(joinScannedLines(['había de recordar aque-', 'lla tarde remota']), 'había de recordar aquella tarde remota');
    });

    test('no pega si la línea siguiente empieza en mayúscula (guion de verdad)', () {
      expect(joinScannedLines(['Gabriel García-', 'Márquez escribió']), 'Gabriel García- Márquez escribió');
    });

    test('ignora líneas vacías y una lista vacía da texto vacío', () {
      expect(joinScannedLines(['', '  ', 'Hola']), 'Hola');
      expect(joinScannedLines(const []), '');
    });
  });

  group('subrayador', () {
    test('la palabra bajo el dedo, o la más cercana en esa altura', () {
      expect(wordAt(_words, const Offset(300, 120)), 1, reason: 'sobre "de"');
      expect(wordAt(_words, const Offset(340, 120)), isIn([1, 2]), reason: 'entre "de" y "recordar"');
      expect(wordAt(_words, const Offset(900, 220)), 6, reason: 'a la derecha de la línea: la última palabra');
      expect(wordAt(_words, const Offset(500, 170)), isNull, reason: 'entre líneas, sin margen');
      expect(wordAt(_words, const Offset(500, 145), slop: 10), 2, reason: 'justo debajo, con margen del dedo');
    });

    test('deslizar subraya el tramo en orden de lectura, en cualquier dirección', () {
      expect(highlightRange({}, 2, 5), {2, 3, 4, 5});
      expect(highlightRange({}, 5, 2), {2, 3, 4, 5});
      expect(highlightRange({0}, 2, 3), {0, 2, 3}, reason: 'se suma a lo ya subrayado');
    });

    test('empezar sobre algo subrayado lo borra (goma)', () {
      expect(highlightRange({1, 2, 3, 4}, 3, 4), {1, 2});
    });

    test('la cita une las líneas y pega la palabra cortada', () {
      expect(quoteFrom(_words, {2, 3, 4, 5}), 'recordar aquella tarde');
      expect(quoteFrom(_words, {0, 6}), 'había remota');
      expect(quoteFrom(_words, {}), '');
    });
  });

  group('pantalla del subrayador', () {
    Future<String? Function()> open(WidgetTester tester, List<ScanWord> words) async {
      String? result;
      await tester.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanQuoteScreen(
                      imagePath: 'no_existe.png',
                      scan: (_) async => ScanResult('no_existe.png', const Size(1000, 1000), words),
                    ),
                  ),
                );
              },
              child: const Text('abrir'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      return () => result;
    }

    /// Punto de pantalla de una posición de la foto.
    Offset onPage(WidgetTester tester, Offset photoPoint) {
      final page = find.byKey(const ValueKey('scan_page'));
      final topLeft = tester.getTopLeft(page);
      final scale = tester.getSize(page).width / 1000;
      return topLeft + photoPoint * scale;
    }

    testWidgets('deslizar sobre el texto lo subraya y "Usar cita" lo devuelve', (tester) async {
      final result = await open(tester, _words);
      expect(find.text('Desliza el dedo sobre el texto para subrayarlo.'), findsOneWidget);

      // De "recordar" a "tarde"
      final gesture = await tester.startGesture(onPage(tester, const Offset(450, 120)));
      await gesture.moveTo(onPage(tester, const Offset(500, 120)));
      await gesture.moveTo(onPage(tester, const Offset(300, 220)));
      await gesture.up();
      await tester.pump();
      expect(find.text('“recordar aquella tarde”'), findsOneWidget);

      await tester.tap(find.text('Usar cita'));
      await tester.pumpAndSettle();
      expect(result(), 'recordar aquella tarde');
    });

    testWidgets('"Todo" subraya todo y "Borrar" lo quita', (tester) async {
      await open(tester, _words);
      await tester.tap(find.text('Todo'));
      await tester.pump();
      expect(find.text('“había de recordar aquella tarde remota”'), findsOneWidget);
      await tester.tap(find.text('Borrar'));
      await tester.pump();
      expect(find.text('Desliza el dedo sobre el texto para subrayarlo.'), findsOneWidget);
    });

    test('reconoce el error de "modelo descargándose" de ML Kit', () {
      expect(isModelDownloading(Exception('Waiting for the text optional module to be downloaded. Please wait.')), isTrue);
      expect(isModelDownloading(Exception('InputImage is invalid')), isFalse);
    });

    testWidgets('sin texto reconocido avisa cómo mejorar la foto', (tester) async {
      await open(tester, const []);
      expect(find.text('No encontré texto'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);
    });
  });
}
