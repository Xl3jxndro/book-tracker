import 'package:book_tracker/screens/scan_quote_screen.dart';
import 'package:book_tracker/services/text_scan.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

  group('pantalla para elegir el texto', () {
    Future<String?> pump(WidgetTester tester, List<String> lines) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanQuoteScreen(imagePath: 'no_existe.jpg', recognize: (_) async => lines),
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
      return result;
    }

    testWidgets('se eligen líneas y se devuelve el texto unido', (tester) async {
      String? result;
      await tester.pumpWidget(MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScanQuoteScreen(
                      imagePath: 'no_existe.jpg',
                      recognize: (_) async => ['Capítulo 1', 'No hay que temer', 'a la verdad.'],
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

      expect(find.text('Elige al menos una línea'), findsOneWidget);
      await tester.tap(find.text('No hay que temer'));
      await tester.tap(find.text('a la verdad.'));
      await tester.pump();
      expect(find.text('Usar 2 líneas'), findsOneWidget);
      expect(find.text('“No hay que temer a la verdad.”'), findsOneWidget);

      await tester.tap(find.text('Usar 2 líneas'));
      await tester.pumpAndSettle();
      expect(result, 'No hay que temer a la verdad.');
    });

    testWidgets('"Todas" elige todas las líneas', (tester) async {
      await pump(tester, ['Uno', 'dos']);
      await tester.tap(find.text('Todas'));
      await tester.pump();
      expect(find.text('Usar 2 líneas'), findsOneWidget);
      expect(find.text('Ninguna'), findsOneWidget);
    });

    test('reconoce el error de "modelo descargándose" de ML Kit', () {
      expect(isModelDownloading(Exception('Waiting for the text optional module to be downloaded. Please wait.')), isTrue);
      expect(isModelDownloading(Exception('InputImage is invalid')), isFalse);
    });

    testWidgets('sin texto reconocido avisa cómo mejorar la foto', (tester) async {
      await pump(tester, const []);
      expect(find.text('No encontré texto'), findsOneWidget);
      expect(find.text('Volver'), findsOneWidget);
    });
  });
}
