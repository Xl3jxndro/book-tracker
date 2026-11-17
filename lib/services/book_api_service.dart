import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Resultado de búsqueda de un libro.
class BookModel {
  final String title;
  final String author;

  /// 0 si la fuente no conoce el número de páginas.
  final int pageCount;
  final String? category;
  final String? thumbnail;

  const BookModel({
    required this.title,
    required this.author,
    required this.pageCount,
    this.category,
    this.thumbnail,
  });
}

enum BookSearchError { rateLimit, network, server }

class BookSearchException implements Exception {
  final BookSearchError reason;
  const BookSearchException(this.reason);

  /// Mensaje listo para mostrar al usuario.
  String get message {
    switch (reason) {
      case BookSearchError.rateLimit:
        return 'Demasiadas búsquedas seguidas. Inténtalo en un minuto.';
      case BookSearchError.network:
        return 'Sin conexión. Puedes escribir los datos a mano.';
      case BookSearchError.server:
        return 'El buscador no respondió. Inténtalo de nuevo.';
    }
  }

  @override
  String toString() => 'BookSearchException($reason)';
}

/// Busca libros para rellenar el formulario.
///
/// - **Open Library**: siempre disponible, sin clave.
/// - **Google Books**: solo si la app se compila con una clave
///   (`--dart-define=GOOGLE_BOOKS_API_KEY=...`). Se usa primero y, si falla o
///   no encuentra nada, se recurre a Open Library. Sin clave, Google rechaza
///   las búsquedas (límite diario 0 para peticiones anónimas).
class BookApiService {
  static const minQueryLength = 3;
  static const _maxResults = 8;
  // Open Library puede tardar varios segundos (≈6 s medidos en la primera
  // conexión); con datos móviles más. Un límite corto daría falsos "sin conexión".
  static const _timeout = Duration(seconds: 15);
  static const _envGoogleKey = String.fromEnvironment('GOOGLE_BOOKS_API_KEY');

  /// Open Library pide identificar la app (sin datos personales).
  static const _headers = {'User-Agent': 'BookTracker/1.0 (Android app)'};

  final http.Client _client;
  final String _googleApiKey;

  BookApiService({http.Client? client, String? googleApiKey})
      : _client = client ?? http.Client(),
        _googleApiKey = googleApiKey ?? _envGoogleKey;

  bool get usesGoogle => _googleApiKey.isNotEmpty;

  void dispose() => _client.close();

  Future<List<BookModel>> searchBooks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < minQueryLength) return [];
    return _searchWithFallback(googleQuery: cleanQuery, openLibraryCriteria: {'q': cleanQuery});
  }

  /// Búsqueda exacta por ISBN-13 (del escáner de códigos de barras).
  Future<List<BookModel>> searchByIsbn(String isbn13) =>
      _searchWithFallback(googleQuery: 'isbn:$isbn13', openLibraryCriteria: {'isbn': isbn13});

  /// Google primero (si hay clave) y, si falla o no encuentra nada, Open Library.
  Future<List<BookModel>> _searchWithFallback({
    required String googleQuery,
    required Map<String, String> openLibraryCriteria,
  }) async {
    if (usesGoogle) {
      try {
        final results = await _searchGoogle(googleQuery);
        if (results.isNotEmpty) return results;
      } on BookSearchException catch (e) {
        // Sin conexión, Open Library tampoco va a responder
        if (e.reason == BookSearchError.network) rethrow;
        debugPrint('Google Books falló ($e); se usa Open Library');
      }
    }
    return _searchOpenLibrary(openLibraryCriteria);
  }

  // --- Google Books ---

  Future<List<BookModel>> _searchGoogle(String query) async {
    final data = await _getJson(Uri.https('www.googleapis.com', '/books/v1/volumes', {
      'q': query,
      'maxResults': '$_maxResults',
      'printType': 'books',
      'fields': 'items(volumeInfo(title,authors,pageCount,categories,imageLinks))',
      'key': _googleApiKey,
    }));
    final items = (data['items'] as List?) ?? const [];
    return items
        .map((item) => item is Map<String, dynamic> ? _parseGoogle(item['volumeInfo']) : null)
        .whereType<BookModel>()
        .toList();
  }

  static BookModel? _parseGoogle(dynamic info) {
    if (info is! Map<String, dynamic>) return null;
    final title = (info['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return null;

    final authors = (info['authors'] as List?)?.whereType<String>().toList() ?? const [];
    final categories = (info['categories'] as List?)?.whereType<String>().toList() ?? const [];
    final images = info['imageLinks'] as Map<String, dynamic>?;

    String? thumb = (images?['thumbnail'] ?? images?['smallThumbnail']) as String?;
    if (thumb != null) {
      thumb = thumb
          .replaceFirst('http:', 'https:')
          .replaceAll('&edge=curl', ''); // sin el efecto de "página doblada"
    }

    return BookModel(
      title: title,
      author: authors.isEmpty ? 'Autor desconocido' : authors.join(', '),
      pageCount: (info['pageCount'] as num?)?.toInt() ?? 0,
      // Google usa "Fiction / Fantasy": nos quedamos con la parte general
      category: categories.isEmpty ? null : categories.first.split('/').first.trim(),
      thumbnail: thumb,
    );
  }

  // --- Open Library ---

  /// [criteria]: `{'q': texto}` para búsqueda libre o `{'isbn': ...}` exacta.
  Future<List<BookModel>> _searchOpenLibrary(Map<String, String> criteria) async {
    final data = await _getJson(Uri.https('openlibrary.org', '/search.json', {
      ...criteria,
      'limit': '$_maxResults',
      'fields': 'title,author_name,number_of_pages_median,cover_i',
    }));
    final docs = (data['docs'] as List?) ?? const [];
    return docs.map(_parseOpenLibrary).whereType<BookModel>().toList();
  }

  static BookModel? _parseOpenLibrary(dynamic doc) {
    if (doc is! Map<String, dynamic>) return null;
    final title = (doc['title'] as String?)?.trim();
    if (title == null || title.isEmpty) return null;

    final authors = (doc['author_name'] as List?)?.whereType<String>().toList() ?? const [];
    final coverId = (doc['cover_i'] as num?)?.toInt();

    return BookModel(
      title: title,
      // Open Library repite autores entre ediciones: los deduplicamos
      author: authors.isEmpty ? 'Autor desconocido' : authors.toSet().join(', '),
      pageCount: (doc['number_of_pages_median'] as num?)?.toInt() ?? 0,
      // Sus "subjects" son etiquetas muy variadas; mejor no adivinar la categoría
      category: null,
      thumbnail: coverId == null ? null : 'https://covers.openlibrary.org/b/id/$coverId-M.jpg',
    );
  }

  // --- HTTP común ---

  Future<Map<String, dynamic>> _getJson(Uri url) async {
    final http.Response response;
    try {
      response = await _client.get(url, headers: _headers).timeout(_timeout);
    } on SocketException {
      throw const BookSearchException(BookSearchError.network);
    } on TimeoutException {
      throw const BookSearchException(BookSearchError.network);
    } on http.ClientException {
      throw const BookSearchException(BookSearchError.network);
    }

    if (response.statusCode == 429) {
      throw const BookSearchException(BookSearchError.rateLimit);
    }
    if (response.statusCode != 200) {
      debugPrint('${url.host} respondió ${response.statusCode}');
      throw const BookSearchException(BookSearchError.server);
    }

    try {
      final data = json.decode(utf8.decode(response.bodyBytes));
      if (data is Map<String, dynamic>) return data;
      throw const FormatException('Respuesta inesperada');
    } on FormatException {
      throw const BookSearchException(BookSearchError.server);
    }
  }

  /// Descarga la portada a [directory]. Devuelve `null` si no se pudo
  /// (la portada es opcional: nunca debe impedir añadir el libro).
  Future<File?> downloadCover(String url, Directory directory) async {
    try {
      final response = await _client.get(Uri.parse(url), headers: _headers).timeout(_timeout);
      final isImage = response.headers['content-type']?.startsWith('image/') ?? false;
      // Las imágenes de 1x1 (o casi) son marcadores de "sin portada"
      if (response.statusCode != 200 || !isImage || response.bodyBytes.length < 1000) return null;

      final file = File(p.join(
        directory.path,
        'cover_${DateTime.now().millisecondsSinceEpoch}.jpg',
      ));
      return file.writeAsBytes(response.bodyBytes);
    } catch (e) {
      debugPrint('No se pudo descargar la portada: $e');
      return null;
    }
  }
}
