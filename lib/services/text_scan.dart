import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Reconoce el texto de una foto (por ejemplo, la página de un libro) en el
/// propio teléfono, sin conexión: la foto no sale del dispositivo.
class TextScan {
  TextScan._();

  /// Líneas de texto en orden de lectura (párrafo a párrafo).
  static Future<List<String>> recognizeLines(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return [
        for (final block in result.blocks)
          for (final line in block.lines)
            if (line.text.trim().isNotEmpty) line.text.trim(),
      ];
    } finally {
      await recognizer.close();
    }
  }
}

/// Une las líneas elegidas en un solo texto, como se lee en el libro: une
/// las palabras cortadas con guion al final de línea ("pala-" + "bra") y
/// quita espacios de más.
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
