import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_helper.dart';
import 'ads_consent.dart';

enum RewardedResult { rewarded, closedEarly, unavailable }

/// Anuncio recompensado: se carga, se muestra y dice si el usuario lo vio
/// entero (solo entonces se da la recompensa).
class RewardedAds {
  static Future<RewardedResult> show({required String adUnitId}) async {
    if (!AdsConsent.canRequestAds.value) return RewardedResult.unavailable;

    final loaded = Completer<RewardedAd?>();
    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: loaded.complete,
        onAdFailedToLoad: (error) {
          debugPrint('Recompensado no disponible: ${error.message}');
          loaded.complete(null);
        },
      ),
    );
    final ad = await loaded.future.timeout(const Duration(seconds: 15), onTimeout: () => null);
    if (ad == null) return RewardedResult.unavailable;

    final done = Completer<RewardedResult>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) done.complete(earned ? RewardedResult.rewarded : RewardedResult.closedEarly);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!done.isCompleted) done.complete(RewardedResult.unavailable);
      },
    );
    await ad.show(onUserEarnedReward: (_, _) => earned = true);
    return done.future;
  }

  static Future<RewardedResult> showStreakSave() => show(adUnitId: AdHelper.rewardedStreakAdUnitId);
}
