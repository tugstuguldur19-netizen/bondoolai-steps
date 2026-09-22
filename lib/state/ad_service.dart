import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Google's public test ad unit IDs. Swap these for your real AdMob unit
/// IDs before publishing — shipping the test IDs shows placeholder ads only.
String get rewardedAdUnitId {
  if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/5224354917';
  if (Platform.isIOS) return 'ca-app-pub-3940256099942544/1712485313';
  throw UnsupportedError('Unsupported platform for ads');
}

class AdService {
  RewardedAd? _rewardedAd;
  bool _loading = false;

  void preload() {
    if (_loading || _rewardedAd != null) return;
    if (!Platform.isAndroid && !Platform.isIOS) return;
    _loading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _loading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _loading = false;
        },
      ),
    );
  }

  bool get isReady => _rewardedAd != null;

  Future<bool> show({required void Function() onReward}) async {
    final ad = _rewardedAd;
    if (ad == null) {
      preload();
      return false;
    }
    _rewardedAd = null;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        preload();
      },
    );

    await ad.show(
      onUserEarnedReward: (ad, reward) => onReward(),
    );
    return true;
  }
}
