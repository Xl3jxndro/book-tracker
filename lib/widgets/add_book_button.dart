import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';
import 'add_book_sheet.dart';

/// Clave del botón "+" (lo señala el tutorial de la biblioteca).
final addBookButtonKey = GlobalKey(debugLabel: 'add_book_button');

/// Abre la hoja para añadir un libro.
void showAddBookSheet(BuildContext context) {
  HapticFeedback.mediumImpact();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const AddBookSheet(),
  );
}

/// Botón "+" de la biblioteca: cuadrado redondeado con el color de acento,
/// junto a la barra de navegación.
class AddBookButton extends StatelessWidget {
  const AddBookButton({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.app;
    return Tooltip(
      message: context.l10n.addBookTooltip,
      child: Material(
        key: addBookButtonKey,
        color: app.accent,
        elevation: 3,
        shadowColor: app.accent.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
        child: InkWell(
          customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(22))),
          onTap: () => showAddBookSheet(context),
          child: SizedBox(
            width: 64,
            height: 64,
            child: Icon(Icons.add_rounded, size: 30, color: app.onAccent, semanticLabel: context.l10n.addBookTooltip),
          ),
        ),
      ),
    );
  }
}
