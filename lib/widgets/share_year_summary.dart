import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../services/year_summary.dart';
import 'year_summary_card.dart';

/// Vista previa de la tarjeta "Mi año lector" y botón para compartirla.
Future<void> showYearSummaryShare(BuildContext context, YearSummary summary) {
  return showDialog<void>(
    context: context,
    builder: (_) => _YearSummaryShareDialog(summary: summary),
  );
}

class _YearSummaryShareDialog extends StatefulWidget {
  final YearSummary summary;
  const _YearSummaryShareDialog({required this.summary});

  @override
  State<_YearSummaryShareDialog> createState() => _YearSummaryShareDialogState();
}

class _YearSummaryShareDialogState extends State<_YearSummaryShareDialog> {
  final _screenshot = ScreenshotController();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      // Las portadas deben estar cargadas antes de capturar, o salen en blanco
      for (final book in widget.summary.recentFinished) {
        final path = book.coverUrl;
        if (path != null && path.isNotEmpty && File(path).existsSync()) {
          await precacheImage(FileImage(File(path)), context);
        }
      }
      if (!mounted) return;

      final bytes = await _screenshot.captureFromWidget(
        YearSummaryCard(summary: widget.summary),
        context: context,
        targetSize: YearSummaryCard.size,
        pixelRatio: 3, // 1080 × 1920
        delay: const Duration(milliseconds: 100),
      );

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, 'mi_anio_lector_${widget.summary.year}.png'));
      await file.writeAsBytes(bytes, flush: true);

      HapticFeedback.mediumImpact();
      await SharePlus.instance.share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: 'Mi año lector ${widget.summary.year} 📚 #BookTracker',
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error compartiendo resumen: $e');
      if (mounted) {
        setState(() => _sharing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo crear la imagen. Inténtalo de nuevo.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.62;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FittedBox(child: YearSummaryCard(summary: widget.summary)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: _sharing ? null : () => Navigator.pop(context),
                    child: const Text('CERRAR'),
                  ),
                ),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _sharing ? null : _share,
                    icon: _sharing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.ios_share_rounded),
                    label: const Text('Compartir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
