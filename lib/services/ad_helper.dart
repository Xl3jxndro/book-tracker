import 'dart:io';

class AdHelper {
  static String get nativeAdUnitId {
    if (Platform.isAndroid) {
      // REEMPLAZA ESTO con tu ID de "Anuncio Nativo" de AdMob
      return 'ca-app-pub-1355991417734091/9995189601'; 
    } else if (Platform.isIOS) {
      return 'ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYY';
    } else {
      throw UnsupportedError('Plataforma no soportada');
    }
  }
}