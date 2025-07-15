import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  InterstitialAd? _interstitialAd;
  int _tradeCounter = 0;
  static const int _interstitialTriggerCount = 10;

  String get bannerAdUnitId {
    if (Platform.isAndroid) {
      return AdConfig.androidBannerId;
    } else if (Platform.isIOS) {
      return AdConfig.iosBannerId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      return AdConfig.androidInterstitialId;
    } else if (Platform.isIOS) {
      return AdConfig.iosInterstitialId;
    }
    throw UnsupportedError('Unsupported platform');
  }

  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    _loadInterstitialAd();
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void onTradeCompleted() {
    _tradeCounter++;
    if (_tradeCounter >= _interstitialTriggerCount) {
      _showInterstitialAd();
      _tradeCounter = 0;
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      _loadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  void dispose() {
    _interstitialAd?.dispose();
  }
}