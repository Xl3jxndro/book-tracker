import 'package:book_tracker/database/database.dart';
import 'package:book_tracker/theme/app_theme.dart';
import 'package:book_tracker/widgets/book_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Book _book({int status = 1, int read = 10, int total = 88, int? rating, String title = 'Metamorphosis'}) => Book(
      id: 1,
      title: title,
      author: 'Franz Kafka',
      totalPages: total,
      readPages: read,
      totalReadTime: 0,
      status: status,
      rating: rating,
    );

Widget _app(Widget child, ThemeData theme) =>
    MaterialApp(theme: theme, home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)));

void main() {
  test('línea de estado de cada libro', () {
    expect(bookStatusLine(_book(status: 1)), 'Leyendo · 11%');
    expect(bookStatusLine(_book(status: 0, read: 0, total: 394)), 'Pendiente · 394 p.');
    expect(bookStatusLine(_book(status: 2, read: 88)), 'Terminado');
    expect(bookStatusLine(_book(status: 3, read: 40)), 'Abandonado · 40/88 p.');
    expect(bookStatusLine(_book(status: 1, total: 0)), 'Leyendo · 0%', reason: 'sin páginas no divide por cero');
  });

  testWidgets('fila de lista: título resaltado, estado y botón de editar, sin desbordes', (tester) async {
    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(_app(
        BookCard(book: _book(title: 'Un título larguísimo de un libro que no cabe en dos líneas de ninguna manera'), searchQuery: 'larg', onTap: () {}),
        theme,
      ));
      expect(tester.takeException(), isNull);
      expect(find.text('Leyendo · 11%'), findsOneWidget);
      expect(find.byTooltip('Editar'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    }
  });

  testWidgets('casilla de cuadrícula: terminado con estrellas, pendiente sin barra', (tester) async {
    await tester.pumpWidget(_app(
      Row(children: [
        Expanded(child: BookGridTile(book: _book(status: 2, read: 88, rating: 4), onTap: () {})),
        const SizedBox(width: 12),
        Expanded(child: BookGridTile(book: _book(status: 0, read: 0), onTap: () {})),
        const SizedBox(width: 12),
        const Expanded(child: SizedBox()),
      ]),
      AppTheme.light,
    ));
    expect(tester.takeException(), isNull);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });
}
