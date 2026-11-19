import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_helper.dart';
import 'ads_gate.dart';

/// Cuándo puede salir el intersticial tras guardar una sesión.
class InterstitialPolicy {
  /// Una de cada [everySessions] sesiones guardadas.
  static const everySessions = 3;

  /// Días de gracia desde el primer uso (sin intersticiales).
  static const graceDays = 7;

  /// Mínimo entre dos intersticiales.
  static const minGap = Duration(hours: 24);

  /// [sessionsSinceLast] cuenta la sesión que se acaba de guardar.
  /// Con [relaxed] (versiones de prueba) no hay días de gracia, basta con 2
  /// sesiones y 1 minuto entre anuncios, para poder probarlo.
  static bool canShow({
    required DateTime now,
    required DateTime firstUseAt,
    required int sessionsSinceLast,
    DateTime? lastShownAt,
    bool finishedBook = false,
    bool relaxed = false,
  }) {
    if (finishedBook) return false; // no estropear la celebración ni la reseña
    final grace = relaxed ? Duration.zero : const Duration(days: graceDays);
    final every = relaxed ? 2 : everySessions;
    final gap = relaxed ? const Duration(minutes: 1) : minGap;
    if (now.difference(firstUseAt) < grace) return false;
    if (sessionsSinceLast < every) return false;
    if (lastShownAt != null && now.difference(lastShownAt) < gap) return false;
    return true;
  }
}

/// Intersticial tras guardar una sesión de lectura: se precarga al empezar
/// la sesión y solo se muestra si [InterstitialPolicy] lo permite.
class InterstitialAds {
  static const _firstUseKey = 'interstitial_first_use';
  static const _lastShownKey = 'interstitial_last_shown';
  static const _sessionsKey = 'interstitial_sessions_since_last';

  static InterstitialAd? _ready;
  static bool _loading = false;

  /// Fecha de primer uso (la guarda la primera vez).
  static Future<DateTime> _firstUse(SharedPreferences prefs, DateTime now) async {
    final ms = prefs.getInt(_firstUseKey);
    if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    await prefs.setInt(_firstUseKey, now.millisecondsSinceEpoch);
    return now;
  }

  /// Al empezar una sesión: deja el anuncio cargado si podría mostrarse.
  static Future<void> preloadIfEligible() async {
    if (_ready != null || _loading || !AdsGate.showAds.value) return;
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastMs = prefs.getInt(_lastShownKey);
    final mightShow = InterstitialPolicy.canShow(
      now: now,
      firstUseAt: await _firstUse(prefs, now),
      sessionsSinceLast: (prefs.getInt(_sessionsKey) ?? 0) + 1,
      lastShownAt: lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
      relaxed: kDebugMode,
    );
    if (!mightShow) return;

    _loading = true;
    InterstitialAd.load(
      adUnitId: AdHelper.sessionInterstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _loading = false;
          _ready = ad;
        },
        onAdFailedToLoad: (error) {
          _loading = false;
          debugPrint('Intersticial no disponible: ${error.message}');
        },
      ),
    );
  }

  /// Tras guardar una sesión. Devuelve si se mostró el anuncio.
  static Future<bool> onSessionSaved({required bool finishedBook}) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final sessions = (prefs.getInt(_sessionsKey) ?? 0) + 1;
    await prefs.setInt(_sessionsKey, sessions);

    final lastMs = prefs.getInt(_lastShownKey);
    final allowed = InterstitialPolicy.canShow(
      now: now,
      firstUseAt: await _firstUse(prefs, now),
      sessionsSinceLast: sessions,
      lastShownAt: lastMs == null ? null : DateTime.fromMillisecondsSinceEpoch(lastMs),
      finishedBook: finishedBook,
      relaxed: kDebugMode,
    );
    final ad = _ready;
    if (!allowed || ad == null || !AdsGate.showAds.value) return false;

    _ready = null;
    final closed = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!closed.isCompleted) closed.complete();
      },
    );
    await prefs.setInt(_lastShownKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_sessionsKey, 0);
    await ad.show();
    await closed.future;
    return true;
  }
}
