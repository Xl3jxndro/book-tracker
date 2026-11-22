import 'dart:io';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/text_scan.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// ¿El error es porque Google Play aún no descargó el modelo de texto?
/// (ML Kit: "Waiting for the text optional module to be downloaded").
bool isModelDownloading(Object error) {
  final message = error.toString().toLowerCase();
  return message.contains('download') || message.contains('optional module');
}

/// Color del subrayado (rotulador amarillo), igual en modo claro y oscuro:
/// va sobre la foto.
const _highlighter = Color(0xFFFFD54F);

/// Subrayador sobre la foto de una página: se desliza el dedo sobre el texto
/// para elegir la cita (palabra a palabra). Devuelve el texto elegido.
class ScanQuoteScreen extends StatefulWidget {
  final String imagePath;

  /// Para pruebas: resultado ya reconocido (sin ML Kit).
  final Future<ScanResult> Function(String path)? scan;

  const ScanQuoteScreen({super.key, required this.imagePath, this.scan});

  @override
  State<ScanQuoteScreen> createState() => _ScanQuoteScreenState();
}

class _ScanQuoteScreenState extends State<ScanQuoteScreen> {
  ScanResult? _result;
  Object? _error;
  Set<int> _selected = {};

  // Subrayado en curso
  Set<int> _beforeDrag = {};
  int? _anchor;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    try {
      final result = await (widget.scan ?? TextScan.scan)(widget.imagePath);
      if (mounted) setState(() => _result = result);
    } catch (e) {
      debugPrint('Reconocer texto: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  String get _quote => _result == null ? '' : quoteFrom(_result!.words, _selected);

  void _dragStart(int? word) {
    if (word == null) return;
    HapticFeedback.selectionClick();
    _anchor = word;
    _beforeDrag = _selected;
    setState(() => _selected = highlightRange(_beforeDrag, word, word));
  }

  void _dragUpdate(int? word) {
    final anchor = _anchor;
    if (anchor == null || word == null) return;
    final next = highlightRange(_beforeDrag, anchor, word);
    if (next.length != _selected.length) HapticFeedback.selectionClick();
    setState(() => _selected = next);
  }

  void _dragEnd() => _anchor = null;

  void _selectAll() {
    final words = _result?.words ?? const [];
    setState(() => _selected = _selected.length == words.length ? {} : {for (var i = 0; i < words.length; i++) i});
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final hasText = result != null && result.words.isNotEmpty;
    return Scaffold(
      backgroundColor: context.cs.surface,
      appBar: AppBar(
        title: const Text('Subraya la cita'),
        actions: [
          if (hasText)
            TextButton(
              onPressed: _selectAll,
              child: Text(_selected.length == result.words.length ? 'Ninguna' : 'Todo'),
            ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: _error != null
          ? (isModelDownloading(_error!)
              ? _message(
                  context,
                  icon: Icons.downloading_rounded,
                  title: 'Preparando el lector de texto',
                  text: 'Google Play lo está descargando (unos 4 MB). Conéctate a internet e inténtalo en unos minutos.',
                )
              : _message(
                  context,
                  icon: Icons.error_outline_rounded,
                  title: 'No se pudo leer la foto',
                  text: 'Inténtalo de nuevo con otra foto.',
                ))
          : result == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpace.md),
                      Text('Leyendo la página…',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : !hasText
                  ? _message(
                      context,
                      icon: Icons.text_fields_rounded,
                      title: 'No encontré texto',
                      text: 'Prueba con más luz, la página recta y el texto enfocado.',
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.sm),
                      child: _page(context, result),
                    ),
      bottomNavigationBar: hasText ? _bottomBar(context) : null,
    );
  }

  /// La foto con el texto detectado marcado y lo subrayado en amarillo.
  Widget _page(BuildContext context, ScanResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fitted = applyBoxFit(BoxFit.contain, result.imageSize, constraints.biggest).destination;
        final scale = fitted.width / result.imageSize.width;
        // Margen del dedo: ~12 px de pantalla, en píxeles de la foto
        final slop = 12 / scale;
        int? wordUnder(Offset local) => wordAt(result.words, local / scale, slop: slop);

        return Center(
          child: SizedBox(
            width: fitted.width,
            height: fitted.height,
            child: GestureDetector(
              key: const ValueKey('scan_page'),
              behavior: HitTestBehavior.opaque,
              onPanStart: (d) => _dragStart(wordUnder(d.localPosition)),
              onPanUpdate: (d) => _dragUpdate(wordUnder(d.localPosition)),
              onPanEnd: (_) => _dragEnd(),
              onTapUp: (d) {
                _dragStart(wordUnder(d.localPosition));
                _dragEnd();
              },
              child: ClipRRect(
                borderRadius: AppRadius.mdAll,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(result.imagePath),
                      fit: BoxFit.fill,
                      errorBuilder: (_, _, _) => ColoredBox(color: context.cs.surfaceContainerHigh),
                    ),
                    CustomPaint(
                      painter: _HighlightPainter(
                        words: result.words,
                        selected: _selected,
                        scale: scale,
                        hint: context.app.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _bottomBar(BuildContext context) {
    final theme = Theme.of(context);
    final quote = _quote;
    return Container(
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpace.sm),
              child: quote.isEmpty
                  ? Row(
                      children: [
                        Icon(Icons.gesture_rounded, size: 20, color: context.cs.onSurfaceVariant),
                        const SizedBox(width: AppSpace.xs),
                        Expanded(
                          child: Text('Desliza el dedo sobre el texto para subrayarlo.',
                              style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                        ),
                      ],
                    )
                  : Text(
                      '“$quote”',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic, color: context.cs.onSurface),
                    ),
            ),
            Row(
              children: [
                if (quote.isNotEmpty) ...[
                  TextButton(
                    onPressed: () => setState(() => _selected = {}),
                    child: const Text('Borrar'),
                  ),
                  const SizedBox(width: AppSpace.xs),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: quote.isEmpty ? null : () => Navigator.pop(context, quote),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    icon: const Icon(Icons.format_quote_rounded),
                    label: const Text('Usar cita'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _message(BuildContext context, {required IconData icon, required String title, required String text}) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: context.cs.onSurfaceVariant),
            const SizedBox(height: AppSpace.md),
            Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.xs),
            Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant), textAlign: TextAlign.center),
            const SizedBox(height: AppSpace.lg),
            FilledButton.tonal(onPressed: () => Navigator.pop(context), child: const Text('Volver')),
          ],
        ),
      ),
    );
  }
}

/// Marca suave donde hay texto y, encima, el subrayado: las palabras
/// seguidas de una misma línea se pintan como una sola franja.
class _HighlightPainter extends CustomPainter {
  final List<ScanWord> words;
  final Set<int> selected;
  final double scale;
  final Color hint;

  _HighlightPainter({required this.words, required this.selected, required this.scale, required this.hint});

  @override
  void paint(Canvas canvas, Size size) {
    final hintPaint = Paint()..color = hint.withValues(alpha: 0.12);
    final markPaint = Paint()
      ..color = _highlighter.withValues(alpha: 0.45)
      ..blendMode = BlendMode.multiply;

    Rect scaled(Rect r) => Rect.fromLTRB(r.left * scale, r.top * scale, r.right * scale, r.bottom * scale);

    for (var i = 0; i < words.length; i++) {
      if (!selected.contains(i)) {
        canvas.drawRRect(RRect.fromRectAndRadius(scaled(words[i].box).inflate(1), const Radius.circular(3)), hintPaint);
      }
    }

    // Franjas: palabras subrayadas seguidas en la misma línea
    Rect? band;
    int? bandLine;
    void flush() {
      if (band != null) {
        canvas.drawRRect(RRect.fromRectAndRadius(band!.inflate(2), const Radius.circular(4)), markPaint);
      }
      band = null;
      bandLine = null;
    }

    for (var i = 0; i < words.length; i++) {
      if (!selected.contains(i)) {
        flush();
        continue;
      }
      final box = scaled(words[i].box);
      if (band != null && bandLine == words[i].line) {
        band = band!.expandToInclude(box);
      } else {
        flush();
        band = box;
        bandLine = words[i].line;
      }
    }
    flush();
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.selected != selected || old.scale != scale || old.words != words || old.hint != hint;
}
