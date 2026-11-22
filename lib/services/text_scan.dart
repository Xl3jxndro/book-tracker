import 'dart:io';
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
    // Copia "derecha" de la foto (aplicando la rotación de la cámara): así
    // las posiciones del texto coinciden exactamente con la imagen en pantalla.
    final codec = await ui.instantiateImageCodec(await File(photoPath).readAsBytes());
    final image = (await codec.getNextFrame()).image;
    final size = Size(image.width.toDouble(), image.height.toDouble());
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    codec.dispose();
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
