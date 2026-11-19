import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Consentimiento de anuncios (UMP de Google) e inicio de AdMob.
///
/// En el Espacio Económico Europeo, Reino Unido y otras regiones que lo exigen,
/// Google pide el consentimiento con su formulario antes de mostrar anuncios
/// (el mensaje se configura en AdMob → Privacidad y mensajería). En el resto
/// no se muestra nada. Los anuncios solo se piden cuando [canRequestAds] es true.
class AdsConsent {
  AdsConsent._();

  /// Se pueden pedir anuncios (hay consentimiento o no hace falta).
  static final ValueNotifier<bool> canRequestAds = ValueNotifier(false);

  /// Hay que ofrecer "Opciones de privacidad de anuncios" en Ajustes.
  static final ValueNotifier<bool> privacyOptionsRequired = ValueNotifier(false);

  static bool _adsStarted = false;

  /// Se llama una vez al arrancar. No bloquea el inicio de la app.
  static Future<void> initialize() async {
    // Si en una sesión anterior ya había consentimiento, se empieza ya
    try {
      if (await ConsentInformation.instance.canRequestAds()) await _startAds();
    } catch (e) {
      debugPrint('Consentimiento (caché) no disponible: $e');
    }

    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        // Muestra el formulario solo si hace falta (p. ej. en la UE)
        await ConsentForm.loadAndShowConsentFormIfRequired((FormError? error) async {
          if (error != null) debugPrint('Formulario de consentimiento: ${error.message}');
          await _refresh();
          if (!done.isCompleted) done.complete();
        });
      },
      (FormError error) async {
        // Sin conexión u otro fallo: se sigue con lo que hubiera guardado
        debugPrint('No se pudo actualizar el consentimiento: ${error.message}');
        await _refresh();
        if (!done.isCompleted) done.complete();
      },
    );
    return done.future;
  }

  /// Formulario para cambiar la elección (Ajustes → Opciones de privacidad).
  static Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((FormError? error) async {
      if (error != null) debugPrint('Opciones de privacidad: ${error.message}');
      await _refresh();
    });
  }

  static Future<void> _refresh() async {
    try {
      privacyOptionsRequired.value = await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
          PrivacyOptionsRequirementStatus.required;
      if (await ConsentInformation.instance.canRequestAds()) await _startAds();
    } catch (e) {
      debugPrint('Estado del consentimiento no disponible: $e');
    }
  }

  static Future<void> _startAds() async {
    if (_adsStarted) return;
    _adsStarted = true;
    await MobileAds.instance.updateRequestConfiguration(
      RequestConfiguration(testDeviceIds: const ['D2D801BFADE21CEF306FB5FA0E21324F']),
    );
    final status = await MobileAds.instance.initialize();
    debugPrint('AdMob inicializado: ${status.adapterStatuses.keys.join(', ')}');
    canRequestAds.value = true;
  }
}
