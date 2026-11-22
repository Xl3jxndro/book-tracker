import 'dart:typed_data';

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

  group('orientación de la foto (EXIF)', () {
    /// JPEG mínimo con etiqueta de giro y tamaño guardado (ancho x alto).
    Uint8List jpeg({required int orientation, required int width, required int height}) => Uint8List.fromList([
          0xFF, 0xD8, // inicio
          // APP1 "Exif\0\0" + TIFF big endian con una entrada (0x0112 = giro)
          0xFF, 0xE1, 0x00, 0x22,
          0x45, 0x78, 0x69, 0x66, 0x00, 0x00,
          0x4D, 0x4D, 0x00, 0x2A, 0x00, 0x00, 0x00, 0x08,
          0x00, 0x01,
          0x01, 0x12, 0x00, 0x03, 0x00, 0x00, 0x00, 0x01, 0x00, orientation, 0x00, 0x00,
          0x00, 0x00, 0x00, 0x00,
          // SOF0 con alto y ancho
          0xFF, 0xC0, 0x00, 0x0B, 0x08, height >> 8, height & 0xFF, width >> 8, width & 0xFF, 0x01, 0x01, 0x11, 0x00,
          0xFF, 0xD9, // fin
        ]);

    test('lee el giro y el tamaño guardados', () {
      final info = readJpegInfo(jpeg(orientation: 6, width: 4000, height: 3000));
      expect(info, isNotNull);
      expect(info!.orientation, 6);
      expect(info.width, 4000);
      expect(info.height, 3000);
      expect(readJpegInfo(Uint8List.fromList([0x89, 0x50, 0x4E, 0x47])), isNull, reason: 'un PNG no es JPEG');
    });

    test('foto en vertical guardada "acostada": hay que girarla', () {
      final bytes = jpeg(orientation: 6, width: 4000, height: 3000);
      expect(jpegOrientationToApply(bytes, 4000, 3000), 6, reason: 'el decodificador no la giró');
      expect(jpegOrientationToApply(bytes, 3000, 4000), 1, reason: 'ya venía girada: no se gira dos veces');
    });

    test('sin etiqueta de giro no se toca', () {
      expect(jpegOrientationToApply(jpeg(orientation: 1, width: 4000, height: 3000), 4000, 3000), 1);
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
    /// (Sin zoom: la foto cuadrada va centrada en la vista.)
    Offset onPage(WidgetTester tester, Offset photoPoint) {
      final rect = tester.getRect(find.byKey(const ValueKey('scan_page')));
      final side = rect.width < rect.height ? rect.width : rect.height;
      final origin = rect.topLeft + Offset((rect.width - side) / 2, (rect.height - side) / 2);
      return origin + photoPoint * (side / 1000);
    }

    const hint = 'Desliza un dedo sobre el texto para subrayarlo. Con dos dedos, acerca la foto.';

    testWidgets('deslizar sobre el texto lo subraya y "Usar cita" lo devuelve', (tester) async {
      final result = await open(tester, _words);
      expect(find.text(hint), findsOneWidget);

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
      expect(find.text(hint), findsOneWidget);

      // Deshacer recupera lo borrado
      await tester.tap(find.byTooltip('Deshacer'));
      await tester.pump();
      expect(find.text('“había de recordar aquella tarde remota”'), findsOneWidget);
    });

    testWidgets('dos dedos acercan la foto sin subrayar nada', (tester) async {
      await open(tester, _words);
      expect(find.byTooltip('Ver la página entera'), findsNothing);

      // Pellizco que empieza sobre "recordar": no debe quedar subrayado
      final a = await tester.startGesture(onPage(tester, const Offset(450, 120)), pointer: 1);
      final b = await tester.startGesture(onPage(tester, const Offset(500, 130)), pointer: 2);
      await a.moveTo(onPage(tester, const Offset(300, 60)));
      await b.moveTo(onPage(tester, const Offset(700, 200)));
      await tester.pump();
      await a.up();
      await b.up();
      await tester.pump();

      expect(find.text(hint), findsOneWidget, reason: 'nada subrayado');
      expect(find.byTooltip('Ver la página entera'), findsOneWidget, reason: 'la foto quedó ampliada');

      await tester.tap(find.byTooltip('Ver la página entera'));
      await tester.pump();
      expect(find.byTooltip('Ver la página entera'), findsNothing);
    });

    testWidgets('con zoom, el subrayado sigue cayendo sobre las palabras', (tester) async {
      await open(tester, _words);
      await tester.tap(find.byTooltip('Acercar'));
      await tester.pump();

      // Con la foto ampliada, un toque sobre una palabra visible la subraya
      final page = find.byKey(const ValueKey('scan_page'));
      final center = tester.getCenter(page);
      await tester.tapAt(center);
      await tester.pump();
      // El centro de la vista cae en la foto (500, 500): no hay palabra ahí
      expect(find.text(hint), findsOneWidget);

      await tester.tap(find.byTooltip('Ver la página entera'));
      await tester.pump();
      await tester.tapAt(onPage(tester, const Offset(300, 120)));
      await tester.pump();
      expect(find.text('“de”'), findsOneWidget);
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
