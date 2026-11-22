import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

/// Una palabra reconocida en la foto, con su posición (en píxeles de la foto).
class ScanWord {
  final String text;
  final Rect box;

  /// Línea a la que pertenece (en orden de lectura).
  final int line;

  const ScanWord(this.text, this.box, this.line);
}

/// Resultado de leer una foto: la foto ya derecha y sus palabras en orden de
/// lectura (párrafo a párrafo, línea a línea).
class ScanResult {
  final String imagePath;
  final Size imageSize;
  final List<ScanWord> words;

  const ScanResult(this.imagePath, this.imageSize, this.words);
}

/// Reconoce el texto de una foto (por ejemplo, la página de un libro) en el
/// propio teléfono: la foto no sale del dispositivo.
class TextScan {
  TextScan._();

  static Future<ScanResult> scan(String photoPath) async {
    // Copia "derecha" de la foto, como se tomó: la cámara guarda la imagen
    // "acostada" con una etiqueta de giro (EXIF) que aquí se aplica. Así la
    // foto se ve en su orientación y las posiciones del texto coinciden.
    final bytes = await File(photoPath).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final decoded = (await codec.getNextFrame()).image;
    codec.dispose();
    final orientation = jpegOrientationToApply(bytes, decoded.width, decoded.height);
    final image = orientation == 1 ? decoded : await _orient(decoded, orientation);
    if (!identical(image, decoded)) decoded.dispose();

    final size = Size(image.width.toDouble(), image.height.toDouble());
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final upright = File('${(await getTemporaryDirectory()).path}/cita_${DateTime.now().millisecondsSinceEpoch}.png');
    await upright.writeAsBytes(png!.buffer.asUint8List(), flush: true);

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(upright.path));
      final words = <ScanWord>[];
      var line = 0;
      for (final block in result.blocks) {
        for (final textLine in block.lines) {
          for (final element in textLine.elements) {
            if (element.text.trim().isNotEmpty) words.add(ScanWord(element.text.trim(), element.boundingBox, line));
          }
          line++;
        }
      }
      return ScanResult(upright.path, size, words);
    } finally {
      await recognizer.close();
    }
  }

  /// Gira o voltea la imagen según la etiqueta EXIF (1–8).
  static Future<ui.Image> _orient(ui.Image src, int orientation) async {
    final w = src.width.toDouble();
    final h = src.height.toDouble();
    final swap = orientation >= 5;
    final outW = swap ? h : w;
    final outH = swap ? w : h;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    switch (orientation) {
      case 2: // espejo horizontal
        canvas
          ..translate(outW, 0)
          ..scale(-1, 1);
      case 3: // 180°
        canvas
          ..translate(outW, outH)
          ..rotate(math.pi);
      case 4: // espejo vertical
        canvas
          ..translate(0, outH)
          ..scale(1, -1);
      case 5: // transponer
        canvas
          ..rotate(math.pi / 2)
          ..scale(1, -1);
      case 6: // 90° a la derecha (teléfono en vertical, lo más común)
        canvas
          ..translate(outW, 0)
          ..rotate(math.pi / 2);
      case 7: // transversal
        canvas
          ..translate(outW, outH)
          ..rotate(-math.pi / 2)
          ..scale(1, -1);
      case 8: // 90° a la izquierda
        canvas
          ..translate(0, outH)
          ..rotate(-math.pi / 2);
    }
    canvas.drawImage(src, Offset.zero, Paint()..filterQuality = FilterQuality.high);
    return recorder.endRecording().toImage(outW.round(), outH.round());
  }
}

/// Giro EXIF que falta aplicar a una foto JPEG ya decodificada (1 = ninguno).
///
/// Si el decodificador ya la giró (el ancho y el alto quedaron
/// intercambiados respecto a los del archivo), no se vuelve a girar.
int jpegOrientationToApply(Uint8List bytes, int decodedWidth, int decodedHeight) {
  final info = readJpegInfo(bytes);
  if (info == null || info.orientation == 1) return 1;
  final swaps = info.orientation >= 5;
  if (swaps && info.width > 0 && info.width != info.height) {
    final alreadyRotated = decodedWidth == info.height && decodedHeight == info.width;
    return alreadyRotated ? 1 : info.orientation;
  }
  return info.orientation;
}

/// Tamaño guardado y etiqueta de giro EXIF de un JPEG (null si no es JPEG).
({int width, int height, int orientation})? readJpegInfo(Uint8List b) {
  if (b.length < 4 || b[0] != 0xFF || b[1] != 0xD8) return null;
  var orientation = 1;
  var width = 0;
  var height = 0;
  var i = 2;
  while (i + 4 <= b.length) {
    if (b[i] != 0xFF) break;
    final marker = b[i + 1];
    if (marker == 0xFF) {
      i++; // relleno
      continue;
    }
    if (marker == 0xD9 || marker == 0xDA) break; // fin o inicio de la imagen
    final length = (b[i + 2] << 8) | b[i + 3];
    final start = i + 4;
    // EXIF (APP1 "Exif\0\0")
    if (marker == 0xE1 &&
        start + 6 <= b.length &&
        b[start] == 0x45 && b[start + 1] == 0x78 && b[start + 2] == 0x69 && b[start + 3] == 0x66) {
      orientation = _exifOrientation(b, start + 6) ?? orientation;
    }
    // Tamaño (SOF0–SOF15, salvo DHT/JPG/DAC)
    final isSof = marker >= 0xC0 && marker <= 0xCF && marker != 0xC4 && marker != 0xC8 && marker != 0xCC;
    if (isSof && start + 5 <= b.length) {
      height = (b[start + 1] << 8) | b[start + 2];
      width = (b[start + 3] << 8) | b[start + 4];
    }
    i += 2 + length;
  }
  return (width: width, height: height, orientation: orientation);
}

int? _exifOrientation(Uint8List b, int tiff) {
  if (tiff + 8 > b.length) return null;
  final little = b[tiff] == 0x49; // "II" = little endian, "MM" = big endian
  int u16(int o) => little ? b[o] | (b[o + 1] << 8) : (b[o] << 8) | b[o + 1];
  int u32(int o) => little
      ? b[o] | (b[o + 1] << 8) | (b[o + 2] << 16) | (b[o + 3] << 24)
      : (b[o] << 24) | (b[o + 1] << 16) | (b[o + 2] << 8) | b[o + 3];
  final ifd = tiff + u32(tiff + 4);
  if (ifd + 2 > b.length) return null;
  final count = u16(ifd);
  for (var e = 0; e < count; e++) {
    final entry = ifd + 2 + e * 12;
    if (entry + 12 > b.length) return null;
    if (u16(entry) == 0x0112) {
      final value = u16(entry + 8);
      return value >= 1 && value <= 8 ? value : null;
    }
  }
  return null;
}

/// Palabra bajo el dedo: la que contiene el punto (con margen) o, si no, la
/// más cercana en esa misma altura (el dedo cae entre dos palabras).
int? wordAt(List<ScanWord> words, Offset point, {double slop = 0}) {
  for (var i = 0; i < words.length; i++) {
    if (words[i].box.inflate(slop).contains(point)) return i;
  }
  int? best;
  var bestDistance = double.infinity;
  for (var i = 0; i < words.length; i++) {
    final box = words[i].box;
    if (point.dy < box.top - slop || point.dy > box.bottom + slop) continue;
    final distance = point.dx < box.left ? box.left - point.dx : (point.dx > box.right ? point.dx - box.right : 0.0);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = i;
    }
  }
  return best;
}

/// Subrayado al deslizar desde la palabra [anchor] hasta [current]: añade
/// ese tramo (en orden de lectura) a lo ya elegido o, si se empezó sobre una
/// palabra subrayada, lo borra (como una goma).
Set<int> highlightRange(Set<int> before, int anchor, int current) {
  final from = anchor < current ? anchor : current;
  final to = anchor < current ? current : anchor;
  final range = {for (var i = from; i <= to; i++) i};
  return before.contains(anchor) ? before.difference(range) : before.union(range);
}

/// La cita a partir de las palabras subrayadas, como se lee en el libro.
String quoteFrom(List<ScanWord> words, Set<int> selected) {
  final lines = <String>[];
  int? currentLine;
  final buffer = StringBuffer();
  for (var i = 0; i < words.length; i++) {
    if (!selected.contains(i)) continue;
    final word = words[i];
    if (currentLine != word.line) {
      if (buffer.isNotEmpty) lines.add(buffer.toString());
      buffer.clear();
      currentLine = word.line;
    } else {
      buffer.write(' ');
    }
    buffer.write(word.text);
  }
  if (buffer.isNotEmpty) lines.add(buffer.toString());
  return joinScannedLines(lines);
}

/// Une las líneas en un solo texto: pega las palabras cortadas con guion al
/// final de línea ("pala-" + "bra") y quita espacios de más.
String joinScannedLines(Iterable<String> lines) {
  final buffer = StringBuffer();
  for (final raw in lines) {
    final line = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (line.isEmpty) continue;
    final text = buffer.toString();
    if (text.isEmpty) {
      buffer.write(line);
    } else if (RegExp(r'\p{L}[-‐­]$', unicode: true).hasMatch(text) &&
        RegExp(r'^\p{Ll}', unicode: true).hasMatch(line)) {
      // Palabra cortada al final de la línea: se quita el guion y se pega
      buffer
        ..clear()
        ..write(text.substring(0, text.length - 1))
        ..write(line);
    } else {
      buffer
        ..write(' ')
        ..write(line);
    }
  }
  return buffer.toString();
}
