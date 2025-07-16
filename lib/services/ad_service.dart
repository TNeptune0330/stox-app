import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/ad_config.dart';

class AdService {
  static AdService? _instance;
  static AdService get instance => _instance ??= AdService._();
  
  AdService._();

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _tradeCounter = 0;
  static const int _interstitialTriggerCount = 10;
  bool _isInitialized = false;

  String get bannerAdUnitId => AdConfig.bannerAdId;
  String get interstitialAdUnitId => AdConfig.interstitialAdId;
  String get rewardedAdUnitId => AdConfig.rewardedAdId;
  String get nativeAdUnitId => AdConfig.nativeAdId;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      print('📱 Initializing AdMob...');
      await MobileAds.instance.initialize();
      
      // Load ads
      _loadInterstitialAd();
      _loadRewardedAd();
      
      _isInitialized = true;
      print('✅ AdMob initialized successfully');
    } catch (e) {
      print('❌ AdMob initialization failed: $e');
    }
  }

  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Interstitial ad loaded');
          _interstitialAd = ad;
          _interstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (error) {
          print('❌ Interstitial ad failed to load: $error');
          _interstitialAd = null;
        },
      ),
    );
  }

  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ Rewarded ad loaded');
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          print('❌ Rewarded ad failed to load: $error');
          _rewardedAd = null;
        },
      ),
    );
  }

  void onTradeCompleted() {
    _tradeCounter++;
    print('📊 Trade completed. Trade counter: $_tradeCounter');
    
    if (_tradeCounter >= _interstitialTriggerCount) {
      _showInterstitialAd();
      _tradeCounter = 0;
    }
  }

  void _showInterstitialAd() {
    if (_interstitialAd == null) {
      print('⚠️ No interstitial ad available, loading new one...');
      _loadInterstitialAd();
      return;
    }

    print('📺 Showing interstitial ad...');
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('✅ Interstitial ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ Interstitial ad dismissed');
        ad.dispose();
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Interstitial ad failed to show: $error');
        ad.dispose();
        _loadInterstitialAd();
      },
    );

    _interstitialAd!.show();
    _interstitialAd = null;
  }

  Future<bool> showRewardedAd({
    required Function() onRewardEarned,
    required Function() onAdClosed,
  }) async {
    if (_rewardedAd == null) {
      print('⚠️ No rewarded ad available');
      return false;
    }

    print('🎁 Showing rewarded ad...');
    
    bool rewardEarned = false;
    
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('✅ Rewarded ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ Rewarded ad dismissed');
        ad.dispose();
        _loadRewardedAd();
        onAdClosed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Rewarded ad failed to show: $error');
        ad.dispose();
        _loadRewardedAd();
        onAdClosed();
      },
    );

    await _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      print('🎉 User earned reward: ${reward.type} ${reward.amount}');
      rewardEarned = true;
      onRewardEarned();
    });

    _rewardedAd = null;
    return rewardEarned;
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          print('✅ Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('📱 Banner ad opened');
        },
        onAdClosed: (ad) {
          print('📱 Banner ad closed');
        },
      ),
    );
  }

  // Create a native ad
  NativeAd createNativeAd() {
    return NativeAd(
      adUnitId: nativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          print('✅ Native ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          print('❌ Native ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          print('📱 Native ad opened');
        },
        onAdClosed: (ad) {
          print('📱 Native ad closed');
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: const Color(0xFF1a1a2e),
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: const Color(0xFF533483),
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white70,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white60,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    );
  }

  // Check if ads are available
  bool get isInterstitialAdAvailable => _interstitialAd != null;
  bool get isRewardedAdAvailable => _rewardedAd != null;

  // Force show interstitial ad (for testing)
  void forceShowInterstitialAd() {
    _showInterstitialAd();
  }

  // Reset trade counter
  void resetTradeCounter() {
    _tradeCounter = 0;
  }

  // Get current trade counter
  int get tradeCounter => _tradeCounter;

  void dispose() {
    print('🧹 Disposing AdService...');
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _isInitialized = false;
  }
}