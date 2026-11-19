import 'package:flutter/foundation.dart';

import 'ads_consent.dart';
import 'remove_ads.dart';

/// ¿Se muestran anuncios? Hay permiso para pedirlos (consentimiento) y el
/// usuario no compró "Quitar anuncios". Todas las ubicaciones lo consultan.
class AdsGate {
  AdsGate._();

  static final ValueNotifier<bool> showAds = ValueNotifier(false);
  static bool _listening = false;

  static void init() {
    if (!_listening) {
      _listening = true;
      AdsConsent.canRequestAds.addListener(_update);
      RemoveAds.instance.active.addListener(_update);
    }
    _update();
  }

  static void _update() =>
      showAds.value = AdsConsent.canRequestAds.value && !RemoveAds.instance.active.value;

  /// Sin anuncios por la compra (no por falta de consentimiento).
  static bool get adsRemoved => RemoveAds.instance.active.value;
}
