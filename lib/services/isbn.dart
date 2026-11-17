/// Validación de ISBN para el escáner de códigos de barras.
///
/// El código de barras de un libro es un EAN-13 que empieza por 978 o 979
/// (ISBN-13). Se acepta también el ISBN-10 antiguo, que se convierte a 13.
class Isbn {
  Isbn._();

  /// Devuelve el ISBN-13 normalizado (solo dígitos) o `null` si [raw] no es
  /// un ISBN válido (p. ej. el código de precio o un producto que no es libro).
  static String? normalize(String raw) {
    final clean = raw.toUpperCase().replaceAll(RegExp(r'[^0-9X]'), '');
    if (clean.length == 13 && isValidIsbn13(clean)) return clean;
    if (clean.length == 10 && isValidIsbn10(clean)) return isbn10To13(clean);
    return null;
  }

  static bool isValidIsbn13(String s) {
    if (!RegExp(r'^97[89]\d{10}$').hasMatch(s)) return false;
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(s[i]) * (i.isEven ? 1 : 3);
    }
    return (10 - sum % 10) % 10 == int.parse(s[12]);
  }

  static bool isValidIsbn10(String s) {
    if (!RegExp(r'^\d{9}[\dX]$').hasMatch(s)) return false;
    var sum = 0;
    for (var i = 0; i < 10; i++) {
      final digit = s[i] == 'X' ? 10 : int.parse(s[i]);
      sum += digit * (10 - i);
    }
    return sum % 11 == 0;
  }

  static String isbn10To13(String isbn10) {
    final body = '978${isbn10.substring(0, 9)}';
    var sum = 0;
    for (var i = 0; i < 12; i++) {
      sum += int.parse(body[i]) * (i.isEven ? 1 : 3);
    }
    return '$body${(10 - sum % 10) % 10}';
  }
}
