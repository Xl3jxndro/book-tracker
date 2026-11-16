import 'dart:convert';
import 'dart:io';

import 'package:book_tracker/services/book_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

final _openLibraryResponse = {
  'docs': [
    {
      'title': 'Cien años de soledad',
      'author_name': ['Gabriel García Márquez', 'Gabriel García Márquez'],
      'number_of_pages_median': 432,
      'cover_i': 12627383,
    },
    {'title': 'Sin portada ni páginas'},
    {'author_name': ['Sin título']}, // se descarta
  ],
};

final _googleResponse = {
  'items': [
    {
      'volumeInfo': {
        'title': 'Good Omens',
        'authors': ['Terry Pratchett', 'Neil Gaiman'],
        'pageCount': 400,
        'categories': ['Fiction / Fantasy'],
        'imageLinks': {'thumbnail': 'http://books.google.com/x?id=1&edge=curl&zoom=1'},
      },
    },
  ],
};

void main() {
  group('sin clave de Google (Open Library)', () {
    test('no llama a ninguna API con menos de 3 caracteres', () async {
      var calls = 0;
      final api = BookApiService(googleApiKey: '', client: MockClient((_) async {
        calls++;
        return _json({});
      }));

      expect(await api.searchBooks('  ab '), isEmpty);
      expect(calls, 0);
    });

    test('usa solo Open Library y convierte sus resultados', () async {
      final hosts = <String>[];
      final api = BookApiService(googleApiKey: '', client: MockClient((request) async {
        hosts.add(request.url.host);
        expect(request.url.queryParameters['q'], 'cien años');
        expect(request.headers['User-Agent'], startsWith('BookTracker'));
        return _json(_openLibraryResponse);
      }));

      final books = await api.searchBooks('cien años');
      expect(hosts, ['openlibrary.org']);
      expect(books, hasLength(2));

      expect(books[0].title, 'Cien años de soledad');
      expect(books[0].author, 'Gabriel García Márquez'); // deduplicado
      expect(books[0].pageCount, 432);
      expect(books[0].category, isNull);
      expect(books[0].thumbnail, 'https://covers.openlibrary.org/b/id/12627383-M.jpg');

      expect(books[1].author, 'Autor desconocido');
      expect(books[1].pageCount, 0);
      expect(books[1].thumbnail, isNull);
    });

    test('429 se informa como límite de búsquedas', () async {
      final api = BookApiService(googleApiKey: '', client: MockClient((_) async => http.Response('', 429)));
      expect(
        () => api.searchBooks('dune'),
        throwsA(isA<BookSearchException>().having((e) => e.reason, 'reason', BookSearchError.rateLimit)),
      );
    });

    test('otros códigos de error se informan como error del servidor', () async {
      final api = BookApiService(googleApiKey: '', client: MockClient((_) async => http.Response('', 503)));
      expect(
        () => api.searchBooks('dune'),
        throwsA(isA<BookSearchException>().having((e) => e.reason, 'reason', BookSearchError.server)),
      );
    });

    test('sin conexión se informa como error de red', () async {
      final api = BookApiService(googleApiKey: '', client: MockClient((_) async => throw const SocketException('offline')));
      expect(
        () => api.searchBooks('dune'),
        throwsA(isA<BookSearchException>().having((e) => e.reason, 'reason', BookSearchError.network)),
      );
    });
  });

  group('con clave de Google', () {
    test('usa Google primero y envía la clave', () async {
      final hosts = <String>[];
      final api = BookApiService(googleApiKey: 'CLAVE', client: MockClient((request) async {
        hosts.add(request.url.host);
        expect(request.url.queryParameters['key'], 'CLAVE');
        return _json(_googleResponse);
      }));

      final books = await api.searchBooks('good omens');
      expect(hosts, ['www.googleapis.com']);
      expect(books.single.author, 'Terry Pratchett, Neil Gaiman');
      expect(books.single.category, 'Fiction');
      expect(books.single.thumbnail, 'https://books.google.com/x?id=1&zoom=1');
    });

    test('si Google falla (429) recurre a Open Library', () async {
      final hosts = <String>[];
      final api = BookApiService(googleApiKey: 'CLAVE', client: MockClient((request) async {
        hosts.add(request.url.host);
        return request.url.host == 'www.googleapis.com'
            ? http.Response('', 429)
            : _json(_openLibraryResponse);
      }));

      final books = await api.searchBooks('cien años');
      expect(hosts, ['www.googleapis.com', 'openlibrary.org']);
      expect(books.first.title, 'Cien años de soledad');
    });

    test('si Google no encuentra nada recurre a Open Library', () async {
      final api = BookApiService(googleApiKey: 'CLAVE', client: MockClient((request) async =>
          request.url.host == 'www.googleapis.com' ? _json({}) : _json(_openLibraryResponse)));

      expect(await api.searchBooks('cien años'), hasLength(2));
    });

    test('sin conexión no insiste con Open Library', () async {
      var calls = 0;
      final api = BookApiService(googleApiKey: 'CLAVE', client: MockClient((_) async {
        calls++;
        throw const SocketException('offline');
      }));

      await expectLater(api.searchBooks('dune'), throwsA(isA<BookSearchException>()));
      expect(calls, 1);
    });
  });

  group('downloadCover', () {
    late Directory dir;
    setUp(() => dir = Directory.systemTemp.createTempSync('covers_test'));
    tearDown(() => dir.deleteSync(recursive: true));

    test('guarda la imagen en la carpeta indicada', () async {
      final bytes = List<int>.generate(2048, (i) => i % 256);
      final api = BookApiService(googleApiKey: '', client: MockClient((_) async =>
          http.Response.bytes(bytes, 200, headers: {'content-type': 'image/jpeg'})));

      final file = await api.downloadCover('https://covers.openlibrary.org/b/id/1-M.jpg', dir);
      expect(file, isNotNull);
      expect(file!.parent.path, dir.path);
      expect(await file.readAsBytes(), bytes);
    });

    test('devuelve null si no es una imagen, es un marcador vacío o falla', () async {
      final notImage = BookApiService(googleApiKey: '', client: MockClient((_) async =>
          http.Response('<html>', 200, headers: {'content-type': 'text/html'})));
      expect(await notImage.downloadCover('https://x', dir), isNull);

      final placeholder = BookApiService(googleApiKey: '', client: MockClient((_) async =>
          http.Response.bytes(List.filled(43, 0), 200, headers: {'content-type': 'image/gif'})));
      expect(await placeholder.downloadCover('https://x', dir), isNull);

      final failing = BookApiService(googleApiKey: '', client: MockClient((_) async =>
          throw const SocketException('offline')));
      expect(await failing.downloadCover('https://x', dir), isNull);
    });
  });
}
