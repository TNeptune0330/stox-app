import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../services/local_database_service.dart';

class RevenueAdMobService {
  static const String _logPrefix = '[AdMob-Revenue]';
  
  // REPLACE THESE WITH YOUR REAL ADMOB IDS
  static const String _iosAppId = 'ca-app-pub-3940256099942544~1458002511'; // TEST ID - REPLACE
  static const String _androidAppId = 'ca-app-pub-3940256099942544~3347511713'; // TEST ID - REPLACE
  
  // iOS Ad Unit IDs (REPLACE WITH YOUR REAL IDS)
  static const String _iosBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716'; // TEST ID
  static const String _iosInterstitialAdUnitId = 'ca-app-pub-3940256099942544/4411468910'; // TEST ID
  static const String _iosRewardedAdUnitId = 'ca-app-pub-3940256099942544/1712485313'; // TEST ID
  
  // Android Ad Unit IDs (REPLACE WITH YOUR REAL IDS)
  static const String _androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // TEST ID
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712'; // TEST ID
  static const String _androidRewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // TEST ID
  
  static BannerAd? _bannerAd;
  static InterstitialAd? _interstitialAd;
  static RewardedAd? _rewardedAd;
  
  static bool _isInitialized = false;
  static int _adRevenue = 0;
  
  static Future<void> initialize() async {
    try {
      print('$_logPrefix Initializing AdMob for revenue generation...');
      
      await MobileAds.instance.initialize();
      
      // Configure request configuration for better ads
      final configuration = RequestConfiguration(
        testDeviceIds: ['TEST_DEVICE_ID'], // Add your test device ID here
        tagForChildDirectedTreatment: TagForChildDirectedTreatment.no,
        tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.no,
      );
      
      await MobileAds.instance.updateRequestConfiguration(configuration);
      
      _isInitialized = true;
      print('$_logPrefix AdMob initialized successfully!');
      
      // Load initial ads
      await loadBannerAd();
      await loadInterstitialAd();
      await loadRewardedAd();
      
    } catch (e) {
      print('$_logPrefix Failed to initialize AdMob: $e');
    }
  }
  
  static Future<void> loadBannerAd() async {
    if (!_isInitialized) return;
    
    try {
      _bannerAd = BannerAd(
        adUnitId: Platform.isIOS ? _iosBannerAdUnitId : _androidBannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (Ad ad) {
            print('$_logPrefix Banner ad loaded successfully');
          },
          onAdFailedToLoad: (Ad ad, LoadAdError error) {
            print('$_logPrefix Banner ad failed to load: $error');
            ad.dispose();
          },
          onAdClicked: (Ad ad) {
            print('$_logPrefix Banner ad clicked - revenue generated!');
            _trackAdRevenue('banner');
          },
        ),
      );
      
      await _bannerAd!.load();
    } catch (e) {
      print('$_logPrefix Error loading banner ad: $e');
    }
  }
  
  static Future<void> loadInterstitialAd() async {
    if (!_isInitialized) return;
    
    try {
      await InterstitialAd.load(
        adUnitId: Platform.isIOS ? _iosInterstitialAdUnitId : _androidInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (InterstitialAd ad) {
            print('$_logPrefix Interstitial ad loaded');
            _interstitialAd = ad;
            
            _interstitialAd!.setImmersiveMode(true);
            _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (InterstitialAd ad) {
                print('$_logPrefix Interstitial ad showed');
              },
              onAdDismissedFullScreenContent: (InterstitialAd ad) {
                print('$_logPrefix Interstitial ad dismissed');
                ad.dispose();
                loadInterstitialAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
                print('$_logPrefix Interstitial ad failed to show: $error');
                ad.dispose();
                loadInterstitialAd();
              },
              onAdClicked: (InterstitialAd ad) {
                print('$_logPrefix Interstitial ad clicked - revenue generated!');
                _trackAdRevenue('interstitial');
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('$_logPrefix Interstitial ad failed to load: $error');
            _interstitialAd = null;
          },
        ),
      );
    } catch (e) {
      print('$_logPrefix Error loading interstitial ad: $e');
    }
  }
  
  static Future<void> loadRewardedAd() async {
    if (!_isInitialized) return;
    
    try {
      await RewardedAd.load(
        adUnitId: Platform.isIOS ? _iosRewardedAdUnitId : _androidRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            print('$_logPrefix Rewarded ad loaded');
            _rewardedAd = ad;
            
            _rewardedAd!.setImmersiveMode(true);
            _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
              onAdShowedFullScreenContent: (RewardedAd ad) {
                print('$_logPrefix Rewarded ad showed');
              },
              onAdDismissedFullScreenContent: (RewardedAd ad) {
                print('$_logPrefix Rewarded ad dismissed');
                ad.dispose();
                loadRewardedAd(); // Load next ad
              },
              onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
                print('$_logPrefix Rewarded ad failed to show: $error');
                ad.dispose();
                loadRewardedAd();
              },
              onAdClicked: (RewardedAd ad) {
                print('$_logPrefix Rewarded ad clicked - revenue generated!');
                _trackAdRevenue('rewarded');
              },
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            print('$_logPrefix Rewarded ad failed to load: $error');
            _rewardedAd = null;
          },
        ),
      );
    } catch (e) {
      print('$_logPrefix Error loading rewarded ad: $e');
    }
  }
  
  static void showInterstitialAd() {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd = null;
    } else {
      print('$_logPrefix Interstitial ad not ready');
      loadInterstitialAd(); // Try to load one
    }
  }
  
  static void showRewardedAd({Function(RewardItem)? onReward}) {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          print('$_logPrefix User earned reward: ${reward.amount} ${reward.type}');
          _trackAdRevenue('rewarded_earned');
          onReward?.call(reward);
        },
      );
      _rewardedAd = null;
    } else {
      print('$_logPrefix Rewarded ad not ready');
      loadRewardedAd(); // Try to load one
    }
  }
  
  static Widget createBannerAdWidget() {
    if (_bannerAd != null) {
      return Container(
        alignment: Alignment.center,
        width: _bannerAd!.size.width.toDouble(),
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      );
    }
    return const SizedBox.shrink();
  }
  
  static Map<String, dynamic> getAdStats() {
    return {
      'status': _isInitialized ? 'active' : 'inactive',
      'banner_loaded': _bannerAd != null,
      'interstitial_loaded': _interstitialAd != null,
      'rewarded_loaded': _rewardedAd != null,
      'total_revenue_events': _adRevenue,
    };
  }
  
  static void _trackAdRevenue(String adType) {
    _adRevenue++;
    print('$_logPrefix Revenue event #$_adRevenue - Type: $adType');
    
    // Save to local database for analytics
    try {
      LocalDatabaseService.saveAdRevenue({
        'ad_type': adType,
        'timestamp': DateTime.now().toIso8601String(),
        'revenue_event': _adRevenue,
      });
    } catch (e) {
      print('$_logPrefix Failed to save revenue data: $e');
    }
  }
  
  static void dispose() {
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
  
  // Additional stub methods for compatibility
  static Widget? getBannerAd() {
    return null; // Return null since ads are disabled
  }
  
  static bool get isBannerAdLoaded => false;
  static bool get isInterstitialAdLoaded => false;
  static bool get isRewardedAdLoaded => false;
  static bool get isNativeAdLoaded => false;
  
  static Future<void> onTradeCompleted() async {
    print('$_logPrefix Trade completed event - disabled');
  }
  
  static Future<void> onScreenTransition(String screenName) async {
    print('$_logPrefix Screen transition to $screenName - disabled');
  }
}