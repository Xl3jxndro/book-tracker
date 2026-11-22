import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../services/text_scan.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../l10n/l10n.dart';

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

  /// Selecciones anteriores, para "Deshacer".
  final List<Set<int>> _history = [];

  // Zoom y desplazamiento de la foto (s = pan + zoom · q)
  static const _maxZoom = 6.0;
  double _zoom = 1;
  Offset _pan = Offset.zero;
  Size _viewport = Size.zero;
  Offset _contentOffset = Offset.zero;
  double _fitScale = 1;

  // Dedos sobre la foto: uno subraya, dos acercan y mueven
  final Map<int, Offset> _pointers = {};
  bool _gestureIsZoom = false;

  // Subrayado en curso
  Set<int> _beforeStroke = {};
  int? _anchor;
  Offset? _strokeStart;
  bool _strokeMoved = false;

  /// Dónde está el dedo que subraya (para la lupa).
  Offset? _finger;

  // Pellizco en curso
  double _zoomAtStart = 1;
  Offset _panAtStart = Offset.zero;
  double _distanceAtStart = 1;
  Offset _focalAtStart = Offset.zero;

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

  // --- Coordenadas ---

  /// Punto de la foto (en sus píxeles) bajo un punto de la pantalla.
  Offset _toPhoto(Offset screen) => ((screen - _pan) / _zoom - _contentOffset) / _fitScale;

  int? _wordUnder(Offset screen) {
    final words = _result?.words;
    if (words == null) return null;
    // Margen del dedo: ~12 px de pantalla, en píxeles de la foto
    return wordAt(words, _toPhoto(screen), slop: 12 / (_fitScale * _zoom));
  }

  Offset _clampPan(Offset pan, double zoom) => Offset(
        pan.dx.clamp(_viewport.width * (1 - zoom), 0.0),
        pan.dy.clamp(_viewport.height * (1 - zoom), 0.0),
      );

  /// Acerca o aleja manteniendo fijo el punto [focal] de la pantalla.
  void _zoomAround(Offset focal, double zoom) {
    final next = zoom.clamp(1.0, _maxZoom);
    final content = (focal - _pan) / _zoom;
    setState(() {
      _zoom = next;
      _pan = _clampPan(focal - content * next, next);
    });
  }

  void _zoomBy(double factor) {
    HapticFeedback.selectionClick();
    _zoomAround(_viewport.center(Offset.zero), _zoom * factor);
  }

  void _resetZoom() {
    HapticFeedback.selectionClick();
    setState(() {
      _zoom = 1;
      _pan = Offset.zero;
    });
  }

  // --- Dedos ---

  void _pointerDown(PointerDownEvent e) {
    _pointers[e.pointer] = e.localPosition;
    if (_pointers.length == 1) {
      _gestureIsZoom = false;
      _startStroke(e.localPosition);
    } else if (_pointers.length == 2) {
      // Segundo dedo: era un pellizco. Si el primero apenas se movió, su
      // subrayado no era intencionado y se deshace.
      if (_anchor != null && !_strokeMoved) _cancelStroke();
      _endStroke();
      _gestureIsZoom = true;
      _startPinch();
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    if (!_pointers.containsKey(e.pointer)) return;
    _pointers[e.pointer] = e.localPosition;
    if (_gestureIsZoom) {
      if (_pointers.length >= 2) _updatePinch();
    } else {
      _updateStroke(e.localPosition);
    }
  }

  void _pointerUp(PointerEvent e) {
    _pointers.remove(e.pointer);
    if (_gestureIsZoom) {
      // Con un dedo menos se sigue con el que queda, desde donde está
      if (_pointers.length >= 2) _startPinch();
      if (_pointers.isEmpty) _gestureIsZoom = false;
      return;
    }
    if (_pointers.isEmpty) _endStroke();
  }

  (Offset, double) _pinchGeometry() {
    final points = _pointers.values.take(2).toList();
    return ((points[0] + points[1]) / 2, (points[0] - points[1]).distance);
  }

  void _startPinch() {
    final (focal, distance) = _pinchGeometry();
    _zoomAtStart = _zoom;
    _panAtStart = _pan;
    _focalAtStart = focal;
    _distanceAtStart = distance <= 0 ? 1 : distance;
  }

  void _updatePinch() {
    final (focal, distance) = _pinchGeometry();
    final zoom = (_zoomAtStart * distance / _distanceAtStart).clamp(1.0, _maxZoom);
    final content = (_focalAtStart - _panAtStart) / _zoomAtStart;
    setState(() {
      _zoom = zoom;
      _pan = _clampPan(focal - content * zoom, zoom);
    });
  }

  void _startStroke(Offset screen) {
    final word = _wordUnder(screen);
    setState(() => _finger = screen);
    if (word == null) return;
    HapticFeedback.selectionClick();
    _history.add(_selected);
    _anchor = word;
    _strokeStart = screen;
    _strokeMoved = false;
    _beforeStroke = _selected;
    setState(() => _selected = highlightRange(_beforeStroke, word, word));
  }

  void _updateStroke(Offset screen) {
    setState(() => _finger = screen);
    final anchor = _anchor;
    if (anchor == null) {
      // Empezó fuera del texto: subraya desde la primera palabra que toque
      if (_wordUnder(screen) != null) _startStroke(screen);
      return;
    }
    if (!_strokeMoved && (screen - (_strokeStart ?? screen)).distance > 8) _strokeMoved = true;
    final word = _wordUnder(screen);
    if (word == null) return;
    final next = highlightRange(_beforeStroke, anchor, word);
    if (next.length != _selected.length) HapticFeedback.selectionClick();
    setState(() => _selected = next);
  }

  void _cancelStroke() {
    if (_anchor == null) return;
    setState(() => _selected = _beforeStroke);
    if (_history.isNotEmpty) _history.removeLast();
  }

  void _endStroke() {
    _anchor = null;
    _strokeStart = null;
    if (_finger != null) setState(() => _finger = null);
  }

  // --- Acciones ---

  void _setSelection(Set<int> next) {
    _history.add(_selected);
    setState(() => _selected = next);
  }

  void _selectAll() {
    final words = _result?.words ?? const [];
    _setSelection(_selected.length == words.length ? {} : {for (var i = 0; i < words.length; i++) i});
  }

  void _undo() {
    if (_history.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = _history.removeLast());
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final hasText = result != null && result.words.isNotEmpty;
    return Scaffold(
      backgroundColor: context.cs.surface,
      appBar: AppBar(
        title: Text(context.l10n.scanTitle),
        actions: [
          if (hasText)
            TextButton(
              onPressed: _selectAll,
              child: Text(_selected.length == result.words.length ? context.l10n.scanSelectNone : context.l10n.scanSelectAll),
            ),
          const SizedBox(width: AppSpace.xs),
        ],
      ),
      body: _error != null
          ? (isModelDownloading(_error!)
              ? _message(
                  context,
                  icon: Icons.downloading_rounded,
                  title: context.l10n.scanModelDownloadingTitle,
                  text: context.l10n.scanModelDownloadingText,
                )
              : _message(
                  context,
                  icon: Icons.error_outline_rounded,
                  title: context.l10n.scanErrorTitle,
                  text: context.l10n.scanErrorText,
                ))
          : result == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: AppSpace.md),
                      Text(context.l10n.scanReading,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant)),
                    ],
                  ),
                )
              : !hasText
                  ? _message(
                      context,
                      icon: Icons.text_fields_rounded,
                      title: context.l10n.scanNoTextTitle,
                      text: context.l10n.scanNoTextText,
                    )
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.sm, 0, AppSpace.sm, AppSpace.sm),
                      child: _page(context, result),
                    ),
      bottomNavigationBar: hasText ? _bottomBar(context) : null,
    );
  }

  /// La foto con el texto detectado marcado y lo subrayado en amarillo.
  /// Un dedo subraya; dos dedos acercan y mueven la foto.
  Widget _page(BuildContext context, ScanResult result) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = constraints.biggest;
        final fitted = applyBoxFit(BoxFit.contain, result.imageSize, viewport).destination;
        _viewport = viewport;
        _fitScale = fitted.width / result.imageSize.width;
        _contentOffset = Offset((viewport.width - fitted.width) / 2, (viewport.height - fitted.height) / 2);
        if (_pan != _clampPan(_pan, _zoom)) _pan = _clampPan(_pan, _zoom);

        return Stack(
          children: [
            Positioned.fill(
              child: Listener(
                key: const ValueKey('scan_page'),
                behavior: HitTestBehavior.opaque,
                onPointerDown: _pointerDown,
                onPointerMove: _pointerMove,
                onPointerUp: _pointerUp,
                onPointerCancel: _pointerUp,
                child: ClipRRect(
                  borderRadius: AppRadius.mdAll,
                  child: Transform(
                    transform: Matrix4.diagonal3Values(_zoom, _zoom, 1)..setTranslationRaw(_pan.dx, _pan.dy, 0),
                    child: Stack(
                      children: [
                        Positioned(
                          left: _contentOffset.dx,
                          top: _contentOffset.dy,
                          width: fitted.width,
                          height: fitted.height,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(result.imagePath),
                                fit: BoxFit.fill,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, _, _) => ColoredBox(color: context.cs.surfaceContainerHigh),
                              ),
                              CustomPaint(
                                painter: _HighlightPainter(
                                  words: result.words,
                                  selected: _selected,
                                  scale: _fitScale,
                                  hint: context.app.accent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (_finger != null) _magnifier(context, _finger!, viewport),
            Positioned(right: AppSpace.xs, bottom: AppSpace.xs, child: _zoomControls(context)),
          ],
        );
      },
    );
  }

  /// Lupa sobre el dedo: muestra ampliado lo que se está subrayando (el dedo
  /// lo tapa). Va encima del dedo, o debajo si no cabe.
  Widget _magnifier(BuildContext context, Offset finger, Size viewport) {
    const size = Size(168, 72);
    const gap = 96.0;
    final above = finger.dy - gap - size.height / 2 >= 0;
    final center = Offset(
      finger.dx.clamp(size.width / 2 + 4, math.max(size.width / 2 + 4, viewport.width - size.width / 2 - 4)),
      above ? finger.dy - gap : finger.dy + gap,
    );
    return Positioned(
      left: center.dx - size.width / 2,
      top: center.dy - size.height / 2,
      width: size.width,
      height: size.height,
      child: IgnorePointer(
        child: RawMagnifier(
          size: size,
          magnificationScale: 2,
          focalPointOffset: finger - center,
          decoration: MagnifierDecoration(
            shape: RoundedRectangleBorder(
              borderRadius: const BorderRadius.all(Radius.circular(16)),
              side: BorderSide(color: context.app.accent, width: 2),
            ),
            shadows: const [BoxShadow(color: Color(0x40000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
        ),
      ),
    );
  }

  /// Acercar, alejar y ajustar (para quien no use el pellizco).
  Widget _zoomControls(BuildContext context) {
    ButtonStyle style() => IconButton.styleFrom(
          fixedSize: const Size(44, 44),
          backgroundColor: context.cs.surfaceContainerHigh.withValues(alpha: 0.92),
          foregroundColor: context.cs.onSurface,
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: context.l10n.scanZoomIn,
          style: style(),
          onPressed: _zoom < _maxZoom ? () => _zoomBy(1.6) : null,
          icon: const Icon(Icons.zoom_in_rounded),
        ),
        const SizedBox(height: 6),
        IconButton(
          tooltip: context.l10n.scanZoomOut,
          style: style(),
          onPressed: _zoom > 1 ? () => _zoomBy(1 / 1.6) : null,
          icon: const Icon(Icons.zoom_out_rounded),
        ),
        if (_zoom > 1) ...[
          const SizedBox(height: 6),
          IconButton(
            tooltip: context.l10n.scanZoomFit,
            style: style(),
            onPressed: _resetZoom,
            icon: const Icon(Icons.fit_screen_rounded),
          ),
        ],
      ],
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
                          child: Text(context.l10n.scanHint,
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
                IconButton(
                  tooltip: context.l10n.commonUndo,
                  onPressed: _history.isEmpty ? null : _undo,
                  icon: const Icon(Icons.undo_rounded),
                ),
                if (quote.isNotEmpty)
                  TextButton(
                    onPressed: () => _setSelection({}),
                    child: Text(context.l10n.scanClear),
                  ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: quote.isEmpty ? null : () => Navigator.pop(context, quote),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    icon: const Icon(Icons.format_quote_rounded),
                    label: Text(context.l10n.scanUseQuote),
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
            FilledButton.tonal(onPressed: () => Navigator.pop(context), child: Text(context.l10n.commonBack)),
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
