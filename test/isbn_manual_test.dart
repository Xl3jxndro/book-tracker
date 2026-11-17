import 'dart:convert';

import 'package:book_tracker/services/book_api_service.dart';
import 'package:book_tracker/widgets/book_search_field.dart';
import 'package:book_tracker/widgets/isbn_help.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), 200, headers: {'content-type': 'application/json'});

void main() {
  group('limpieza de títulos de Open Library', () {
    test('quita la traducción y la colección entre paréntesis', () {
      expect(BookApiService.cleanOpenLibraryTitle('Satanas / Satan (Biblioteca Breve (Barcelona, Spain).)'), 'Satanas');
      expect(
        BookApiService.cleanOpenLibraryTitle(
            'Mensajero de Agartha 1. Zombis (Novela de Ciencia Ficción) / the Messenger of Agartha 1. Zombies ( a Sci- Fi Novel)'),
        'Mensajero de Agartha 1. Zombis',
      );
      expect(BookApiService.cleanOpenLibraryTitle('Hora de Los Lobos / the Hour of the Wolves'), 'Hora de Los Lobos');
    });

    test('no toca títulos normales ni los que son solo paréntesis', () {
      expect(BookApiService.cleanOpenLibraryTitle('Cien años de soledad'), 'Cien años de soledad');
      expect(BookApiService.cleanOpenLibraryTitle('1984'), '1984');
      expect(BookApiService.cleanOpenLibraryTitle('(Sin título)'), '(Sin título)');
    });
  });

  testWidgets('el buscador detecta un ISBN escrito (10 dígitos con guiones) y busca por ISBN', (tester) async {
    final urls = <Uri>[];
    final api = BookApiService(googleApiKey: '', client: MockClient((r) async {
      urls.add(r.url);
      return _json({
        'docs': [
          {'title': 'Satanas / Satan (Biblioteca Breve (Barcelona, Spain).)', 'author_name': ['Mendoza'], 'number_of_pages_median': 285},
        ],
      });
    }));
    BookModel? selected;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: BookSearchField(service: api, onSelected: (b) => selected = b)),
    ));
    await tester.enterText(find.byType(TextField), '84-322-1122-2');
    await tester.pump(const Duration(milliseconds: 700)); // espera tras escribir
    await tester.pumpAndSettle();

    expect(urls.single.queryParameters['isbn'], '9788432211225', reason: 'búsqueda exacta, convertido a ISBN-13');
    expect(urls.single.queryParameters.containsKey('q'), isFalse);
    expect(find.text('Resultado por ISBN 9788432211225'), findsOneWidget);

    await tester.tap(find.text('Satanas'));
    await tester.pumpAndSettle();
    expect(selected?.title, 'Satanas');
    expect(selected?.pageCount, 285);
  });

  testWidgets('escribir el ISBN a mano: avisa mientras escribes y devuelve el ISBN-13', (tester) async {
    String? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async => result = await showManualIsbnDialog(context),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '978-84');
    await tester.pump();
    expect(find.text('Debe tener 10 o 13 dígitos (llevas 5)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '978-84-322-1122-6'); // dígito de control mal
    await tester.pump();
    expect(find.text('Revisa los números: el último dígito no coincide'), findsOneWidget);
    expect(tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'BUSCAR')).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '958-42-7354-x'); // ISBN-10 con X minúscula
    await tester.pump();
    await tester.tap(find.text('BUSCAR'));
    await tester.pumpAndSettle();
    expect(result, '9789584273543');
  });

  testWidgets('la ayuda muestra las partes del ISBN y dónde encontrarlo', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(body: TextButton(onPressed: () => showIsbnHelp(context), child: const Text('ayuda'))),
      ),
    ));
    await tester.tap(find.text('ayuda'));
    await tester.pumpAndSettle();

    expect(find.text('¿Dónde encuentro el ISBN?'), findsOneWidget);
    for (final part in ['978', '84', '9916', '901', '9']) {
      expect(find.text(part), findsOneWidget);
    }
    expect(find.text('En la contraportada'), findsOneWidget);
    expect(find.text('En la página de créditos'), findsOneWidget);
    expect(find.text('13 o 10 dígitos'), findsOneWidget);
  });
}
