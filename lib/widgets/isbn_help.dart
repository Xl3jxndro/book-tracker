import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../services/isbn.dart';
import '../theme/app_colors.dart';

/// Explica qué es el ISBN y dónde encontrarlo en el libro.
Future<void> showIsbnHelp(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.cs.outline, borderRadius: BorderRadius.circular(10)))),
            const SizedBox(height: 20),
            Text(context.l10n.isbnHelpTitle, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
            const SizedBox(height: 8),
            Text(context.l10n.isbnHelpIntro, style: TextStyle(color: context.cs.onSurfaceVariant)),
            const SizedBox(height: 20),
            const IsbnBreakdown(),
            const SizedBox(height: 24),
            _HelpItem(
              icon: Icons.qr_code_2_rounded,
              title: context.l10n.isbnHelpBackCoverTitle,
              text: context.l10n.isbnHelpBackCoverText,
            ),
            _HelpItem(
              icon: Icons.menu_book_rounded,
              title: context.l10n.isbnHelpCreditsTitle,
              text: context.l10n.isbnHelpCreditsText,
            ),
            _HelpItem(
              icon: Icons.pin_rounded,
              title: context.l10n.isbnHelpDigitsTitle,
              text: context.l10n.isbnHelpDigitsText,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Pide el ISBN escrito a mano. Devuelve el ISBN-13 normalizado o `null`.
Future<String?> showManualIsbnDialog(BuildContext context) {
  return showDialog<String>(context: context, builder: (_) => const _ManualIsbnDialog());
}

/// Esquema de las partes de un ISBN-13 (como en el reverso de un libro).
class IsbnBreakdown extends StatelessWidget {
  const IsbnBreakdown({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final parts = [
      ('978', l10n.isbnPartPrefix, const Color(0xFF29B6F6)),
      ('84', l10n.isbnPartCountry, const Color(0xFFE53935)),
      ('9916', l10n.isbnPartPublisher, const Color(0xFF7CB342)),
      ('901', l10n.isbnPartBook, const Color(0xFFFB8C00)),
      ('9', l10n.isbnPartCheck, const Color(0xFFEC407A)),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 4, right: 8),
              child: Text('ISBN', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ),
            for (var i = 0; i < parts.length; i++) ...[
              if (i > 0)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('-', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
                ),
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: parts[i].$3, borderRadius: BorderRadius.circular(6)),
                    child: Text(parts[i].$1, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, fontFamily: 'monospace')),
                  ),
                  const SizedBox(height: 4),
                  Text(parts[i].$2, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: parts[i].$3)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _HelpItem({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 13, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ManualIsbnDialog extends StatefulWidget {
  const _ManualIsbnDialog();
  @override
  State<_ManualIsbnDialog> createState() => _ManualIsbnDialogState();
}

class _ManualIsbnDialogState extends State<_ManualIsbnDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Mensaje de error mientras se escribe (null si es válido o está vacío).
  String? get _error {
    final digits = _controller.text.toUpperCase().replaceAll(RegExp(r'[^0-9X]'), '');
    if (digits.isEmpty) return null;
    if (digits.length != 10 && digits.length != 13) return context.l10n.isbnLengthError(digits.length);
    return Isbn.normalize(digits) == null ? context.l10n.isbnChecksumError : null;
  }

  String? get _isbn => Isbn.normalize(_controller.text);

  @override
  Widget build(BuildContext context) {
    final isbn = _isbn;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text(context.l10n.isbnManualTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9xX\- ]')),
              LengthLimitingTextInputFormatter(20),
            ],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (isbn != null) Navigator.pop(context, isbn);
            },
            decoration: InputDecoration(
              hintText: '978-84-9916-901-9',
              errorText: _error,
              prefixText: 'ISBN ',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          const SizedBox(height: 10),
          Text(context.l10n.isbnManualHelper, style: TextStyle(fontSize: 12, color: context.cs.onSurfaceVariant)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: () => showIsbnHelp(context),
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              label: Text(context.l10n.isbnManualWhere),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonCancel)),
        ElevatedButton(onPressed: isbn == null ? null : () => Navigator.pop(context, isbn), child: Text(context.l10n.isbnManualSearch)),
      ],
    );
  }
}
