import 'package:book_tracker/services/app_update.dart';
import 'package:book_tracker/widgets/app_update_actions.dart';
import 'package:book_tracker/widgets/whats_new_sheet.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('estado de la actualización', () {
    test('respuesta de Play → estado', () {
      expect(updateStatusFrom(UpdateAvailability.updateAvailable, InstallStatus.unknown), UpdateStatus.available);
      expect(updateStatusFrom(UpdateAvailability.updateNotAvailable, InstallStatus.unknown), UpdateStatus.upToDate);
      expect(updateStatusFrom(UpdateAvailability.unknown, InstallStatus.unknown), UpdateStatus.unknown);
      expect(updateStatusFrom(UpdateAvailability.developerTriggeredUpdateInProgress, InstallStatus.unknown),
          UpdateStatus.downloading);
    });

    test('una descarga terminada o en curso manda sobre la disponibilidad', () {
      expect(updateStatusFrom(UpdateAvailability.updateNotAvailable, InstallStatus.downloaded), UpdateStatus.downloaded);
      expect(updateStatusFrom(UpdateAvailability.updateAvailable, InstallStatus.downloading), UpdateStatus.downloading);
      expect(updateStatusFrom(UpdateAvailability.updateAvailable, InstallStatus.pending), UpdateStatus.downloading);
    });
  });

  testWidgets('el aviso de versión nueva cabe en un teléfono pequeño', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: UpdatePromptSheet()))));
    expect(tester.takeException(), isNull);
    expect(find.text('Hay una versión nueva'), findsOneWidget);
    expect(find.text('Actualizar'), findsOneWidget);
    expect(find.text('Ahora no'), findsOneWidget);
  });

  group('notas de la versión', () {
    test('la última versión va primero y coincide con las novedades', () {
      expect(WhatsNew.history.first.version, WhatsNew.version);
      expect(WhatsNew.history.map((r) => r.version).toSet().length, WhatsNew.history.length, reason: 'sin repetidas');
      expect(WhatsNew.history.every((r) => r.items.isNotEmpty), isTrue);
    });

    testWidgets('el historial muestra todas las versiones', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: WhatsNewSheet(showHistory: true))));
      expect(tester.takeException(), isNull);
      expect(find.text('Notas de la versión'), findsOneWidget);
      expect(find.text('NOVEDADES · ${WhatsNew.version}'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('VERSIÓN 1.2.0'), 300, scrollable: find.byType(Scrollable).first);
      expect(find.text('Escáner de ISBN'), findsOneWidget);
      expect(find.text('Cerrar'), findsOneWidget);
    });
  });
}
