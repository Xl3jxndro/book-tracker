import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

import '../database/database.dart';

/// Crea la imagen de una cita (con la portada difuminada de fondo) y abre el
/// menú de compartir. Se usa desde el detalle del libro y desde "Mis citas".
Future<void> shareQuoteAsImage(BuildContext context, Book book, Note note) async {
  final accent = Theme.of(context).colorScheme.primary;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(const SnackBar(
    content: Text('Generando tarjeta...'),
    behavior: SnackBarBehavior.floating,
    duration: Duration(seconds: 1),
  ));

  try {
    final cover = book.coverUrl;
    if (cover != null && cover.isNotEmpty && File(cover).existsSync()) {
      await precacheImage(FileImage(File(cover)), context);
    }
    if (!context.mounted) return;

    final bytes = await ScreenshotController().captureFromWidget(
      QuoteShareCard(book: book, note: note, accent: accent),
      delay: const Duration(milliseconds: 200),
      context: context,
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/quote_${note.id}.png');
    await file.writeAsBytes(bytes, flush: true);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path, mimeType: 'image/png')],
      text: '📖 ${book.title}\n✨ Compartido desde Book Tracker',
    ));
    HapticFeedback.heavyImpact();
  } catch (e) {
    debugPrint('Error compartiendo cita: $e');
    messenger.showSnackBar(const SnackBar(
      content: Text('No se pudo crear la imagen. Inténtalo de nuevo.'),
      behavior: SnackBarBehavior.floating,
    ));
  }
}

/// Tarjeta 400×500 con la cita, el libro y la página.
class QuoteShareCard extends StatelessWidget {
  final Book book;
  final Note note;
  final Color accent;
  const QuoteShareCard({super.key, required this.book, required this.note, required this.accent});

  @override
  Widget build(BuildContext context) {
    final cover = book.coverUrl;
    final hasCover = cover != null && cover.isNotEmpty && File(cover).existsSync();
    return Container(
      width: 400,
      height: 500,
      color: Colors.black,
      child: Stack(
        children: [
          if (hasCover)
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Image.file(
                  File(cover),
                  fit: BoxFit.cover,
                  color: Colors.black.withValues(alpha: 0.4),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black12, Colors.black.withValues(alpha: 0.7)],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 320,
              padding: const EdgeInsets.all(30),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white10, width: 1),
                boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, 10))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Icon(Icons.format_quote_rounded, color: Colors.white30, size: 40),
                  ),
                  const SizedBox(height: 10),
                  // Las citas largas se reducen para caber en la tarjeta
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: 260,
                        child: Text(
                          note.content,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'Georgia',
                            height: 1.3,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Icon(Icons.format_quote_rounded, color: Colors.white30, size: 40),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 14),
                  Text(
                    book.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800, decoration: TextDecoration.none),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, decoration: TextDecoration.none),
                  ),
                  if (note.pageNumber != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Página ${note.pageNumber}',
                        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.bold, decoration: TextDecoration.none),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text(
                    'Leído en Book Tracker',
                    style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
