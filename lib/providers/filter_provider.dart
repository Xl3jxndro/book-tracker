import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';
import 'database_provider.dart';

enum BookSortOption {
  recentlyAdded,
  mostProgress,
  longest,
  alphabetical
}

// Este provider guarda la opción seleccionada actualmente
final bookSortProvider = StateProvider<BookSortOption>((ref) => BookSortOption.recentlyAdded);

// Este provider toma la lista de la DB y la entrega ORDENADA
final sortedBooksProvider = Provider<AsyncValue<List<Book>>>((ref) {
  final booksAsync = ref.watch(booksStreamProvider);
  final sortOption = ref.watch(bookSortProvider);

  return booksAsync.whenData((list) {
    // Creamos una copia para no mutar la original
    List<Book> sortedList = List.from(list);

    switch (sortOption) {
      case BookSortOption.recentlyAdded:
        // Drift suele devolver por ID ascendente, lo invertimos para los más nuevos
        sortedList.sort((a, b) => b.id.compareTo(a.id));
        break;
      case BookSortOption.mostProgress:
        sortedList.sort((a, b) {
          double progressA = a.totalPages > 0 ? a.readPages / a.totalPages : 0;
          double progressB = b.totalPages > 0 ? b.readPages / b.totalPages : 0;
          return progressB.compareTo(progressA);
        });
        break;
      case BookSortOption.longest:
        sortedList.sort((a, b) => b.totalPages.compareTo(a.totalPages));
        break;
      case BookSortOption.alphabetical:
        sortedList.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
    }
    return sortedList;
  });
});