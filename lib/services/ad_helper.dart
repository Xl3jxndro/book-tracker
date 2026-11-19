import 'dart:io';

import 'package:flutter/foundation.dart';

/// IDs de las unidades de anuncios de AdMob (una por ubicación, para ver en
/// los informes cuál rinde más). En las versiones de desarrollo se usan las
/// unidades de prueba oficiales de Google: ver o tocar anuncios reales desde
/// una build de desarrollo cuenta como tráfico inválido y puede limitar la
/// cuenta.
class AdHelper {
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';
  static const _testRewarded = 'ca-app-pub-3940256099942544/5224354917';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';

  static String _pick(String release, String test) {
    if (!Platform.isAndroid) throw UnsupportedError('Plataforma no soportada');
    return kReleaseMode ? release : test;
  }

  /// Nativo en la lista de la biblioteca.
  static String get nativeAdUnitId => _pick('ca-app-pub-1355991417734091/9995189601', _testNative);

  /// Nativo en Estadísticas.
  static String get statsNativeAdUnitId => _pick('ca-app-pub-1355991417734091/9876505846', _testNative);

  /// Nativo en Mis citas.
  static String get quotesNativeAdUnitId => _pick('ca-app-pub-1355991417734091/2308559901', _testNative);

  /// Recompensado "Salvar racha".
  static String get rewardedStreakAdUnitId => _pick('ca-app-pub-1355991417734091/4819620281', _testRewarded);

  /// Intersticial tras guardar una sesión.
  static String get sessionInterstitialAdUnitId => _pick('ca-app-pub-1355991417734091/3422778136', _testInterstitial);
}
