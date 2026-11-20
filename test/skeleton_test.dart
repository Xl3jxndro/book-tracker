import 'package:book_tracker/theme/app_theme.dart';
import 'package:book_tracker/widgets/skeleton_loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {bool reduceMotion = false, ThemeData? theme}) => MaterialApp(
      theme: theme ?? AppTheme.light,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion, size: const Size(400, 900)),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  for (final (name, widget) in [
    ('biblioteca', const LibrarySkeleton()),
    ('detalles', const Padding(padding: EdgeInsets.all(24), child: BookDetailsSkeleton())),
    ('estadísticas', const StatsSkeleton()),
    ('citas', const QuotesSkeleton()),
  ]) {
    testWidgets('silueta de $name se dibuja con brillo, en claro y oscuro', (tester) async {
      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(_app(widget, theme: theme));
        await tester.pump(const Duration(milliseconds: 700));
        expect(tester.takeException(), isNull);
        expect(find.byType(ShaderMask), findsOneWidget);
      }
    });
  }

  testWidgets('con "reducir animaciones" las siluetas quedan quietas', (tester) async {
    await tester.pumpWidget(_app(const LibrarySkeleton(), reduceMotion: true));
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(ColorFiltered), findsOneWidget);
  });
}
