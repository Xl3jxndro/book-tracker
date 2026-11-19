import 'dart:io';

import 'package:flutter/foundation.dart';

class AdHelper {
  /// Anuncio nativo de prueba oficial de Google. Se usa en las versiones de
  /// desarrollo para no ver ni tocar anuncios reales (AdMob lo trata como
  /// tráfico inválido y puede limitar la cuenta).
  static const _testNativeAndroid = 'ca-app-pub-3940256099942544/2247696110';

  static const _testRewardedAndroid = 'ca-app-pub-3940256099942544/5224354917';

  /// Unidad "Salvar racha" (recompensado) de AdMob.
  static const _rewardedStreakRelease = 'ca-app-pub-1355991417734091/4819620281';

  static String get rewardedStreakAdUnitId {
    if (!Platform.isAndroid) throw UnsupportedError('Plataforma no soportada');
    return (kReleaseMode && _rewardedStreakRelease.isNotEmpty) ? _rewardedStreakRelease : _testRewardedAndroid;
  }

  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      return kReleaseMode ? 'ca-app-pub-1355991417734091/9995189601' : _testNativeAndroid;
    } else if (Platform.isIOS) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }
  }
}
