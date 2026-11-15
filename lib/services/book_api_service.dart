import 'dart:convert';
import 'package:http/http.dart' as http;

class BookModel {
  final String title;
  final String author;
  final int pageCount;
  final String? thumbnail;

  BookModel({
    required this.title, 
    required this.author, 
    required this.pageCount, 
    this.thumbnail
  });
}

class BookApiService {
  static Future<List<BookModel>> searchBooks(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.length < 3) return [];
    
    // Quitamos "intitle:" para una búsqueda más genérica y ligera
    final encodedQuery = Uri.encodeComponent(cleanQuery);
    final url = Uri.parse(
      'https://www.googleapis.com/books/v1/volumes?q=$encodedQuery&maxResults=5&printType=books'
    );
    
    try {
      print('🔍 Intentando petición: $url');
      final response = await http.get(url).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List items = data['items'] ?? [];
        return items.map((item) {
          final info = item['volumeInfo'];
          final images = info['imageLinks'];
          
          String? thumb = images?['thumbnail'] ?? images?['smallThumbnail'];
          if (thumb != null && thumb.startsWith('http:')) {
            thumb = thumb.replaceFirst('http:', 'https:');
          }

          return BookModel(
            title: info['title'] ?? 'Sin título',
            author: (info['authors'] as List?)?.first ?? 'Autor desconocido',
            pageCount: info['pageCount'] ?? 0,
            thumbnail: thumb,
          );
        }).toList();
      } else if (response.statusCode == 429) {
        print('❌ Límite de Google alcanzado (429).');
        throw Exception('rate-limit');
      }
    } catch (e) {
      print('⚠️ Error en servicio: $e');
      rethrow;
    }
    return [];
  }
}