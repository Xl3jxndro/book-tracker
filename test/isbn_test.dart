import 'dart:convert';

import 'package:book_tracker/services/book_api_service.dart';
import 'package:book_tracker/services/isbn.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('validación de ISBN', () {
    test('acepta ISBN-13 reales de libros', () {
      expect(Isbn.normalize('9780307474728'), '9780307474728'); // Cien años de soledad
      expect(Isbn.normalize('9788498382662'), '9788498382662');
      expect(Isbn.normalize('979-10-90636-07-1'), '9791090636071', reason: 'admite guiones');
    });

    test('rechaza un dígito de control incorrecto', () {
      expect(Isbn.normalize('9780307474729'), isNull);
    });

    test('rechaza códigos de barras que no son libros', () {
      expect(Isbn.normalize('7501031311309'), isNull, reason: 'EAN de un producto (no empieza por 978/979)');
      expect(Isbn.normalize('51299'), isNull, reason: 'código de precio');
      expect(Isbn.normalize(''), isNull);
    });

    test('convierte ISBN-10 (con X incluida) a ISBN-13', () {
      expect(Isbn.normalize('0-307-47472-0'), '9780307474728');
      expect(Isbn.isValidIsbn10('080442957X'), isTrue);
      expect(Isbn.normalize('080442957X'), '9780804429573');
      expect(Isbn.normalize('0307474722'), isNull, reason: 'dígito de control incorrecto');
    });
  });

  group('búsqueda por ISBN', () {
    http.Response json(Object body) =>
        http.Response.bytes(utf8.encode(jsonEncode(body)), 200, headers: {'content-type': 'application/json'});

    test('Open Library busca por el campo isbn, no por texto', () async {
      late Uri url;
      final api = BookApiService(googleApiKey: '', client: MockClient((r) async {
        url = r.url;
        return json({'docs': [{'title': 'Cien años de soledad', 'author_name': ['Gabriel García Márquez'], 'number_of_pages_median': 432}]});
      }));

      final books = await api.searchByIsbn('9780307474728');
      expect(url.host, 'openlibrary.org');
      expect(url.queryParameters['isbn'], '9780307474728');
      expect(url.queryParameters.containsKey('q'), isFalse);
      expect(books.single.title, 'Cien años de soledad');
    });

    test('con clave de Google usa "isbn:" en Google', () async {
      late Uri url;
      final api = BookApiService(googleApiKey: 'CLAVE', client: MockClient((r) async {
        url = r.url;
        return json({'items': [{'volumeInfo': {'title': 'Dune', 'authors': ['Frank Herbert']}}]});
      }));

      await api.searchByIsbn('9780441013593');
      expect(url.host, 'www.googleapis.com');
      expect(url.queryParameters['q'], 'isbn:9780441013593');
    });
  });
}
